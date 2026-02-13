#!/bin/bash
set -e

# Environment variable defaults
AIRPLAY_NAME="${AIRPLAY_NAME:-AirPlay Relay}"
AIRPLAY_PASSWORD="${AIRPLAY_PASSWORD:-}"
AUDIO_BACKEND="${AUDIO_BACKEND:-alsa}"
AUDIO_DEVICE="${AUDIO_DEVICE:-default}"
VOLUME_RANGE="${VOLUME_RANGE:-60}"
INTERPOLATION="${INTERPOLATION:-soxr}"
BUFFER_LENGTH="${BUFFER_LENGTH:-default}"
METADATA_PIPE="${METADATA_PIPE:-/tmp/shairport-sync-metadata}"
ENABLE_VOLUME_CONTROL="${ENABLE_VOLUME_CONTROL:-yes}"

echo "========================================="
echo "AirPlay Relay Configuration"
echo "========================================="
echo "Device Name: $AIRPLAY_NAME"
echo "Audio Backend: $AUDIO_BACKEND"
echo "Audio Device: $AUDIO_DEVICE"
echo "Volume Control: $ENABLE_VOLUME_CONTROL"
echo "Volume Range: ${VOLUME_RANGE}dB"
echo "Interpolation: $INTERPOLATION"
echo "Metadata Pipe: $METADATA_PIPE"
echo "========================================="

# Generate shairport-sync configuration
cat > /etc/shairport-sync.conf <<EOF
general = {
  name = "$AIRPLAY_NAME";
  interpolation = "$INTERPOLATION";
  output_backend = "$AUDIO_BACKEND";
EOF

# Add password if set
if [ -n "$AIRPLAY_PASSWORD" ]; then
  cat >> /etc/shairport-sync.conf <<EOF
  password = "$AIRPLAY_PASSWORD";
EOF
  echo "Password protection: ENABLED"
fi

cat >> /etc/shairport-sync.conf <<EOF
};

sessioncontrol = {
  session_timeout = 20;
};

metadata = {
  enabled = "yes";
  include_cover_art = "no";
  pipe_name = "$METADATA_PIPE";
  pipe_timeout = 5000;
};
EOF

# Write alsa block once, with or without mixer/volume control lines
if [ "$ENABLE_VOLUME_CONTROL" = "yes" ]; then
  cat >> /etc/shairport-sync.conf <<EOF

alsa = {
  output_device = "$AUDIO_DEVICE";
  mixer_control_name = "PCM";
  mixer_device = "default";
  volume_range_db = $VOLUME_RANGE;
};
EOF
  echo "Volume control: ENABLED (range: ${VOLUME_RANGE}dB)"
else
  cat >> /etc/shairport-sync.conf <<EOF

alsa = {
  output_device = "$AUDIO_DEVICE";
};
EOF
  echo "Volume control: DISABLED"
fi

echo ""
echo "Starting services..."
echo "========================================="

# Start Avahi daemon for mDNS
avahi-daemon --daemonize --no-chroot

# Start shairport-sync in background
shairport-sync -c /etc/shairport-sync.conf &

# Wait for shairport-sync to create the metadata pipe rather than using a fixed sleep
echo "Waiting for metadata pipe to be ready..."
PIPE_WAIT=0
while [ ! -p "$METADATA_PIPE" ]; do
  sleep 1
  PIPE_WAIT=$((PIPE_WAIT + 1))
  if [ $PIPE_WAIT -ge 30 ]; then
    echo "ERROR: Metadata pipe $METADATA_PIPE did not appear after 30 seconds. Check shairport-sync config."
    exit 1
  fi
done
echo "Metadata pipe ready."

# Start GPIO relay script
exec /app/gpio_relay_airplay.sh
