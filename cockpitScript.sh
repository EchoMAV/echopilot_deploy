#!/bin/bash

# Only used by cockpit to get some information from the filesystem

function ApnChange
{
    echo "Removing existing network manager profile for Cellular..."
    nmcli con delete 'Cellular'
    echo "Adding network manager profile for Cellular..."
    nmcli connection add type gsm ifname cdc-wdm0 con-name "Cellular" apn "$1" connection.autoconnect yes	
}

while [[ $# -gt 0 ]]; do 
    key="$1"
    shift
    shift

    case $key in
        -a)
            ApnChange $1
            exit 0
            ;;
        -d)
            ls /dev/ | grep video
            exit 0
            ;;
        -s)
            ls /dev/ | grep ttyTH | head -c -1 | sed -e "s/.*/\/dev\/&/"
            exit 0
            ;;
        -i)
            basename -a /sys/class/net/*
            exit 0
            ;;
        -c)
            nmcli con show Cellular | grep gsm.apn | cut -d ":" -f2 | xargs
            exit 0
            ;;
        -v)
            cat /usr/local/echopilot/version.txt
            exit 0
            ;;
        -u)
            hostname -I | awk '{print $1}' | cut -d'.' -f1,2
            exit 0
            ;;
    esac
    exit 0
done
