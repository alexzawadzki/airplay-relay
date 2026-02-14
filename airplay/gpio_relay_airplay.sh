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
echo "GPIO Pin:        $GPIO_PIN (BCM)"
echo "Active State:    $GPIO_ACTIVE_STATE ($([ "$GPIO_ACTIVE_STATE" = "1" ] && echo "HIGH" || echo "LOW"))"
echo "Turn-off Delay:  ${TURN_OFF_DELAY}s"
echo "Metadata Pipe:   $METADATA_PIPE"
echo "========================================="
echo ""

# GPIO helper functions using raspi-gpio (replaces deprecated wiringpi)
gpio_setup() {
    raspi-gpio set "$GPIO_PIN" op
}

gpio_write() {
    local pin=$1
    local value=$2
    if [ "$value" = "1" ]; then
        raspi-gpio set "$pin" dh
    else
        raspi-gpio set "$pin" dl
    fi
}

# Setup GPIO pin as output and set to inactive state
gpio_setup
gpio_write "$GPIO_PIN" "$GPIO_INACTIVE_STATE"

# PID of any pending turn-off timer
SHUTDOWN_PID=""

# Schedule relay turn-off after TURN_OFF_DELAY seconds
schedule_turn_off() {
    (
        sleep "$TURN_OFF_DELAY"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] AirPlay STOPPED (after ${TURN_OFF_DELAY}s delay)"
        gpio_write "$GPIO_PIN" "$GPIO_INACTIVE_STATE"
    ) &
    SHUTDOWN_PID=$!
}

# Cancel any pending turn-off timer
cancel_turn_off() {
    if [ -n "$SHUTDOWN_PID" ] && kill -0 "$SHUTDOWN_PID" 2>/dev/null; then
        kill "$SHUTDOWN_PID" 2>/dev/null
        wait "$SHUTDOWN_PID" 2>/dev/null
        SHUTDOWN_PID=""
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Turn-off cancelled (music resumed)"
    fi
}

echo "Monitoring AirPlay events..."
echo ""

# Read from the FIFO in the current shell so SHUTDOWN_PID is visible across
# iterations.  A named pipe (FIFO) returns EOF when the writer closes it, so
# we wrap the inner read loop in an outer 'while true' that simply reopens the
# FIFO.  This is more reliable than 'tail -F' which is designed for regular
# files, not FIFOs.
while true; do
    while IFS= read -r line; do
        if echo "$line" | grep -q "pbeg"; then
            cancel_turn_off
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] AirPlay STARTED - Relay ON"
            gpio_write "$GPIO_PIN" "$GPIO_ACTIVE_STATE"
        elif echo "$line" | grep -q "pend"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] AirPlay playback ended, scheduling turn-off in ${TURN_OFF_DELAY}s..."
            cancel_turn_off
            schedule_turn_off
        fi
    done < "$METADATA_PIPE"
    # FIFO writer closed; pause briefly before reopening
    sleep 0.2
done
