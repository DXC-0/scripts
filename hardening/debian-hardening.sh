#!/bin/bash
set -e

echo "Check"
if [ "$(id -u)" -ne 0 ]; then
  echo "Run the script with sudo !"
  exit 1
fi

echo "SSH Hardening"

RANDOM_PORT=$(shuf -i 2000-65000 -n 1)

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s) 2>/dev/null || true

cat << EOF > /etc/ssh/sshd_config
Port $RANDOM_PORT
Protocol 2

PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no

ClientAliveInterval 120
ClientAliveCountMax 2
LoginGraceTime 15
MaxAuthTries 3
MaxSessions 2

KexAlgorithms curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
EOF

systemctl restart ssh || systemctl restart sshd || true

echo "disable root"

usermod -s /usr/sbin/nologin root || true
passwd -l root || true
chage -E0 root || true

echo "fail2ban configuration"

apt-get update -y
apt-get install -y fail2ban

cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 24h
findtime = 10m
maxretry = 3
backend  = systemd

[sshd]
enabled  = true
port     = $RANDOM_PORT
filter   = sshd
logpath  = /var/log/auth.log
EOF

systemctl enable --now fail2ban

echo "Firewall configuration"

apt-get install -y ufw

ufw default deny incoming
ufw default deny routed
ufw default allow outgoing

ufw allow $RANDOM_PORT/tcp

ufw --force enable

echo "Kernel configuration"

cat << 'EOF' > /etc/sysctl.d/99-hardened.conf
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.yama.ptrace_scope = 2
fs.suid_dumpable = 0
kernel.core_uses_pid = 1

net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

kernel.randomize_va_space = 2
kernel.kexec_load_disabled = 1

fs.protected_symlinks = 1
fs.protected_hardlinks = 1
kernel.perf_event_paranoid = 3

kernel.unprivileged_userns_clone = 0
vm.mmap_min_addr = 262144
kernel.sysrq = 0
kernel.unprivileged_bpf_disabled = 1
kernel.perf_event_max_sample_rate = 1
kernel.perf_cpu_time_max_percent = 1
kernel.core_pattern = |/bin/false
EOF

sysctl --system

sysctl -w fs.suid_dumpable=0
sysctl -w kernel.core_pattern="|/bin/false"

echo "MAC module configuration"

apt-get install -y apparmor apparmor-utils 2>/dev/null || true

echo "Simple perm check"

chmod 700 /root 2>/dev/null || true
chmod 600 /etc/ssh/sshd_config 2>/dev/null || true
chmod 600 /etc/shadow 2>/dev/null || true
chmod 600 /etc/gshadow 2>/dev/null || true

echo
echo "Hardening OK"

echo
echo "HARDENING CHECKLIST"

check() {
    if eval "$1" >/dev/null 2>&1; then
        echo "[OK] $2"
    else
        echo "[ERROR] $2"
    fi
}

check "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config" "SSH: password authentication disabled"
check "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config" "SSH: root login disabled"
check "systemctl is-active ssh | grep -q active" "SSH: service active"

check "passwd -S root | grep -q 'L'" "Root account: locked"
check "grep -q '/usr/sbin/nologin' /etc/passwd" "Root account: shell disabled"

check "systemctl is-active fail2ban | grep -q active" "Fail2ban: service active"
check "fail2ban-client status sshd >/dev/null 2>&1" "Fail2ban: SSH jail active"

check "ufw status | head -n1 | grep -Ei 'active|actif'" "UFW: firewall active"
check "ufw status verbose | grep -Ei 'deny \(incoming\)|refuser \(entrant\)'" "UFW: incoming policy deny"
check "ufw status | grep -q '$RANDOM_PORT/tcp'" "UFW: SSH port allowed"

check "sysctl kernel.kptr_restrict | grep -q 2" "Kernel: kptr_restrict"
check "sysctl kernel.dmesg_restrict | grep -q 1" "Kernel: dmesg_restrict"
check "sysctl kernel.yama.ptrace_scope | grep -q 2" "Kernel: ptrace_scope"
check "sysctl fs.suid_dumpable | grep -q 0" "Kernel: suid_dumpable"
check "sysctl net.ipv4.conf.all.rp_filter | grep -q 1" "Kernel: rp_filter"
check "sysctl kernel.randomize_va_space | grep -q 2" "Kernel: ASLR"
check "sysctl kernel.kexec_load_disabled | grep -q 1" "Kernel: kexec disabled"
check "sysctl fs.protected_symlinks | grep -q 1" "Kernel: protected symlinks"
check "sysctl fs.protected_hardlinks | grep -q 1" "Kernel: protected hardlinks"
check "sysctl kernel.unprivileged_userns_clone | grep -q 0" "Kernel: unprivileged userns disabled"
check "sysctl vm.mmap_min_addr | grep -q 262144" "Kernel: mmap_min_addr"
check "sysctl kernel.sysrq | grep -q 0" "Kernel: sysrq disabled"
check "sysctl kernel.unprivileged_bpf_disabled | grep -q 1" "Kernel: unprivileged BPF disabled"
check "sysctl kernel.core_pattern | grep -q '/bin/false'" "Kernel: core dumps disabled"

check "aa-status --enabled" "AppArmor: enabled"
check "aa-status | grep -q 'docker-default'" "AppArmor: Docker profile loaded"

echo
echo "Connection SSH port : $RANDOM_PORT"
echo "Hardening complete : please reboot the server !!!"
