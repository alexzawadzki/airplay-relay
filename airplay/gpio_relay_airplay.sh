#!/bin/bash
PIPE="/tmp/shairport-sync-metadata"
GPIO=17

# Setup GPIO
gpio -g mode $GPIO out
gpio -g write $GPIO 0

# Monitor metadata
tail -F "$PIPE" | while read -r line; do
    if echo "$line" | grep -q "pbeg"; then
        echo "AirPlay STARTED"
        gpio -g write $GPIO 1
    elif echo "$line" | grep -q "pend"; then
        echo "AirPlay STOPPED"
        gpio -g write $GPIO 0
    fi
done
