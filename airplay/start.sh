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

alsa = {
  output_device = "$AUDIO_DEVICE";
  mixer_control_name = "PCM";
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

# Add volume control if enabled
if [ "$ENABLE_VOLUME_CONTROL" = "yes" ]; then
  cat >> /etc/shairport-sync.conf <<EOF

alsa = {
  output_device = "$AUDIO_DEVICE";
  mixer_control_name = "PCM";
  mixer_device = "default";
};
EOF
  echo "Volume control: ENABLED (range: ${VOLUME_RANGE}dB)"
fi

echo ""
echo "Starting services..."
echo "========================================="

# Start Avahi daemon for mDNS
avahi-daemon --daemonize --no-chroot

# Start shairport-sync in background
shairport-sync -c /etc/shairport-sync.conf &

# Give shairport-sync time to create the metadata pipe
sleep 3

# Start GPIO relay script
exec /app/gpio_relay_airplay.sh
