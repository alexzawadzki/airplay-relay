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

# Setup GPIO
gpio -g mode $GPIO_PIN out
gpio -g write $GPIO_PIN $GPIO_INACTIVE_STATE

# Variable to track shutdown timer PID
SHUTDOWN_PID=""

# Function to turn off GPIO after delay
schedule_turn_off() {
    (
        sleep $TURN_OFF_DELAY
        echo "AirPlay STOPPED (after ${TURN_OFF_DELAY}s delay)"
        gpio -g write $GPIO_PIN $GPIO_INACTIVE_STATE
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

echo "Monitoring AirPlay events..."
echo ""

# Monitor metadata
tail -F "$METADATA_PIPE" | while read -r line; do
    if echo "$line" | grep -q "pbeg"; then
        cancel_turn_off
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] AirPlay STARTED - Relay ON"
        gpio -g write $GPIO_PIN $GPIO_ACTIVE_STATE
    elif echo "$line" | grep -q "pend"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] AirPlay playback ended, scheduling turn-off in ${TURN_OFF_DELAY}s..."
        cancel_turn_off  # Cancel any existing timer
        schedule_turn_off
    fi
done
