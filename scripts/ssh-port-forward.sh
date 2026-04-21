#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: <USER> <IP> <PORT>"
    exit 1
fi

USER=$1
IP=$2
PORT=$3

if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "IP-Error: $IP not valid."
    exit 1
fi

if ! [[ $PORT =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "Port-Error: $PORT must be a number between 1 and 65535."
    exit 1
fi

ssh -f -N -L $PORT:localhost:$PORT $USER@$IP
