# abuseip-reporter
> A simple, silly Bash script to report malicious IPs to AbuseIPDB. Usable manually or via a cron job / systemd task.

### Requirement

- API_KEY ([API documentation](https://docs.abuseipdb.com/#introduction))

> Edit the script and replace the API KEY field with your AbuseIPDB key. You should also adjust the codes/tags and the message according to your needs.

### Usage

Clone the repository
```
git clone https://github.com/DXC-0/abuseip-reporter.git
cd abuseip-reporter
chmod +x report-script.sh
```
Report
```
report-script.sh <ip_address> | <report_file>

```

<br/>
The IP list should be a plain‑text file (or raw log output) containing only the IP addresses (no extra characters or noise). If the file isn’t already clean, you’ll need to parse it first to extract just the IPs.
