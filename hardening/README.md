# hardening-scripts

> This repository contains an automated Linux hardening script for Debian/Ubuntu systems.  
It applies a broad set of security measures to strengthen the system quickly and consistently.  

## Pre‑Script Requirements

Before running the hardening script, make sure to complete the following steps:

Create a user and add it to the sudo group.

```bash
usermod -aG sudo <user>
```

Generate or add your SSH keys.
Ensure your public key is added to:

```
~/.ssh/authorized_keys
```

This key will be required to connect once password authentication is disabled.

Connect via SSH using your new user.
Log in with your non‑root account to confirm that SSH key authentication works correctly.

Once connected with your user, execute the hardening script to apply all security configurations.

```bash
sudo bash ubuntu-hardening.sh
```

The hardening script will automatically generate a **new random SSH port**

## Features

- Disables insecure authentication methods
- Enforces key‑based authentication  
- Restricts SSH features and access
- Generates a random SSH port between 2000 and 65000
- Disables root login
- Locks the root password 
- Prevents interactive root shell access  
- Installs and configures Fail2ban  
- Enables SSH protection with strict ban rules  
- Denies all incoming traffic by default  
- Allows only the randomized SSH port  
- Enables the firewall automatically  
- Applies strict sysctl rules  
- Enforces memory protections  
- Hardens network behavior  
- Restricts kernel debugging and tracing  
- Installs and enables AppArmor/SElinux
- Ensures docker security profiles are active  
- Secures sensitive system files  
- Restricts access to critical directories  
- Verifies all applied protections  
- Confirms service status and kernel parameters  
- Displays the final SSH port

### Intended usage
> This script is designed for **freshly installed servers** that require a **high level of security** and are considered **sensitive**.
