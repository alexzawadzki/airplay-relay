#!/bin/bash

# Configuration from environment variables
METADATA_PIPE="${METADATA_PIPE:-/tmp/shairport-sync-metadata}"
GPIO_PIN="${GPIO_PIN:-17}"
GPIO_ACTIVE_STATE="${GPIO_ACTIVE_STATE:-1}"  # 1=HIGH to turn on, 0=LOW to turn on
TURN_OFF_DELAY="${TURN_OFF_DELAY:-10}"

# Calculate inactive state (opposite of active)
if [ "$GPIO_ACTIVE_STATE" = "1" ]; then
    GPIO_INACTIVE_STATE=0
else
    GPIO_INACTIVE_STATE=1
fi

echo "========================================="
echo "GPIO Relay Configuration"
echo "========================================="
echo "GPIO Pin: $GPIO_PIN (BCM)"
echo "Active State: $GPIO_ACTIVE_STATE ($([ "$GPIO_ACTIVE_STATE" = "1" ] && echo "HIGH" || echo "LOW"))"
echo "Turn-off Delay: ${TURN_OFF_DELAY}s"
echo "Metadata Pipe: $METADATA_PIPE"
echo "========================================="
echo ""

# GPIO helper functions using raspi-gpio (replaces deprecated wiringpi)
gpio_setup() {
    raspi-gpio set $GPIO_PIN op
}

gpio_write() {
    local pin=$1
    local value=$2
    if [ "$value" = "1" ]; then
        raspi-gpio set $pin dh
    else
        raspi-gpio set $pin dl
    fi
}

# Setup GPIO pin as output and set to inactive state
gpio_setup
gpio_write $GPIO_PIN $GPIO_INACTIVE_STATE

# Variable to track shutdown timer PID
SHUTDOWN_PID=""

# Function to turn off GPIO after delay
schedule_turn_off() {
    (
        sleep $TURN_OFF_DELAY
        echo "AirPlay STOPPED (after ${TURN_OFF_DELAY}s delay)"
        raspi-gpio set $GPIO_PIN dl
        if [ "$GPIO_INACTIVE_STATE" = "1" ]; then
            raspi-gpio set $GPIO_PIN dh
        else
            raspi-gpio set $GPIO_PIN dl
        fi
    ) &
    SHUTDOWN_PID=$!
}

# Function to cancel scheduled turn off
cancel_turn_off() {
    if [ -n "$SHUTDOWN_PID" ] && kill -0 $SHUTDOWN_PID 2>/dev/null; then
        kill $SHUTDOWN_PID 2>/dev/null
        wait $SHUTDOWN_PID 2>/dev/null
        SHUTDOWN_PID=""
        echo "Turn-off cancelled (music resumed)"
    fi
}

echo "Monitoring AirPlay events..."
echo ""

# IMPORTANT: Use process substitution instead of a pipe so that the while loop
# runs in the current shell. A pipeline like `tail -F ... | while read` runs
# the loop body in a subshell, which means SHUTDOWN_PID is never visible
# between iterations and cancel_turn_off can never work.
while read -r line; do
    if echo "$line" | grep -q "pbeg"; then
        cancel_turn_off
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] AirPlay STARTED - Relay ON"
        gpio_write $GPIO_PIN $GPIO_ACTIVE_STATE
    elif echo "$line" | grep -q "pend"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] AirPlay playback ended, scheduling turn-off in ${TURN_OFF_DELAY}s..."
        cancel_turn_off  # Cancel any existing timer before scheduling a new one
        schedule_turn_off
    fi
done < <(tail -F "$METADATA_PIPE")
