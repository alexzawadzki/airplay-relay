#!/bin/bash
PIPE="/tmp/shairport-sync-metadata"
GPIO=17
TURN_OFF_DELAY=${TURN_OFF_DELAY:-10}  # Default 10 seconds, can be set via environment variable

# Setup GPIO
gpio -g mode $GPIO out
gpio -g write $GPIO 0

# Variable to track shutdown timer PID
SHUTDOWN_PID=""

# Function to turn off GPIO after delay
schedule_turn_off() {
    (
        sleep $TURN_OFF_DELAY
        echo "AirPlay STOPPED (after ${TURN_OFF_DELAY}s delay)"
        gpio -g write $GPIO 0
    ) &
    SHUTDOWN_PID=$!
}

# Function to cancel scheduled turn off
cancel_turn_off() {
    if [ -n "$SHUTDOWN_PID" ] && kill -0 $SHUTDOWN_PID 2>/dev/null; then
        kill $SHUTDOWN_PID 2>/dev/null
        SHUTDOWN_PID=""
        echo "Turn-off cancelled (music resumed)"
    fi
}

echo "AirPlay GPIO Relay started (GPIO $GPIO, Turn-off delay: ${TURN_OFF_DELAY}s)"

# Monitor metadata
tail -F "$PIPE" | while read -r line; do
    if echo "$line" | grep -q "pbeg"; then
        cancel_turn_off
        echo "AirPlay STARTED"
        gpio -g write $GPIO 1
    elif echo "$line" | grep -q "pend"; then
        echo "AirPlay playback ended, scheduling turn-off in ${TURN_OFF_DELAY}s..."
        cancel_turn_off  # Cancel any existing timer
        schedule_turn_off
    fi
done
