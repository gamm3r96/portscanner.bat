#!/bin/bash

# Author: Gamm3r96
# Description: Simple Port Scanner using bash and netcat

# Function to print usage
print_usage() {
    echo "Usage: $0 -h <host> -p <start_port-end_port>"
    echo "Example: $0 -h 192.168.1.1 -p 20-80"
}

# Initialize variables
HOST=""
START_PORT=1
END_PORT=1024

# Parse command line arguments
while getopts ":h:p:" opt; do
    case ${opt} in
        h )
            HOST=$OPTARG
            ;;
        p )
            IFS='-' read -r START_PORT END_PORT <<< "$OPTARG"
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            print_usage
            exit 1
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            print_usage
            exit 1
            ;;
    esac
done

# Check if host is set
if [ -z "$HOST" ]; then
    echo "Error: Host is required."
    print_usage
    exit 1
fi

# Validate ports
if ! [[ "$START_PORT" =~ ^[0-9]+$ && "$END_PORT" =~ ^[0-9]+$ && $START_PORT -le $END_PORT && $START_PORT -gt 0 && $END_PORT -le 65535 ]]; then
    echo "Error: Invalid port range."
    print_usage
    exit 1
fi

echo "Scanning ports from $START_PORT to $END_PORT on host $HOST..."

# Scan ports
for (( port=$START_PORT; port<=$END_PORT; port++ )); do
    nc -z -v -w 1 $HOST $port &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Port $port is open on $HOST"
    else
        echo "Port $port is closed on $HOST"
    fi
done

echo "Port scan complete."
