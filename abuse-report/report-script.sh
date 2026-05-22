#!/bin/bash

### --> Define here API and file parameters :)

ABUSE_IP_DB_API_KEY="ENTER API KEY"
REPORTED_FILE="FILE TO REPORT PATH" 

report_ip() {
    local ip=$1

    ip=$(echo "$ip" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\r//')

    if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid IP address format: $ip"
        return 1
    fi

### --> Report code selection + comment

    response=$(curl -s -w "%{http_code}" -o /tmp/response_body.txt "https://api.abuseipdb.com/api/v2/report" \
        -H "Key: $ABUSE_IP_DB_API_KEY" \
        -d "ip=$ip" \
        -d "categories[]=10" \
        -d "categories[]=18" \
        -d "categories[]=21" \
        -d "categories[]=15" \
        -d "comment=Malicious activity detected")

    response_code=$(tail -n1 <<< "$response")
    response_body=$(cat /tmp/response_body.txt)


    if [[ "$response_code" == "200" ]]; then
        echo "Successfully reported IP: $ip"
    else
        echo "Failed to report IP: $ip"
        echo "HTTP Status Code: $response_code"
        echo "Response Body: $response_body"
    fi
}

read_report_file() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        exit 1
    fi

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        report_ip "$line"
    done < "$file"
}


if [ $# -eq 0 ]; then
    echo "Usage: $0 <ip_address> | <report_file>"
    exit 1
fi


if [ $# -eq 2 ] && [ -f "$2" ]; then
    read_report_file "$2"
elif [ $# -eq 1 ] && [ -f "$1" ]; then
    read_report_file "$1"
else
    report_ip "$1"
fi