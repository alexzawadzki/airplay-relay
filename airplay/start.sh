#!/bin/bash
set -e

# ===============================
# Environment defaults
# ===============================
AIRPLAY_NAME="${AIRPLAY_NAME:-AirPlay Relay}"
AIRPLAY_PASSWORD="${AIRPLAY_PASSWORD:-}"
AUDIO_BACKEND="${AUDIO_BACKEND:-alsa}"
AUDIO_DEVICE="${AUDIO_DEVICE:-default}"
VOLUME_RANGE="${VOLUME_RANGE:-60}"
INTERPOLATION="${INTERPOLATION:-soxr}"
METADATA_PIPE="${METADATA_PIPE:-/tmp/shairport-sync-metadata}"
ENABLE_VOLUME_CONTROL="${ENABLE_VOLUME_CONTROL:-yes}"

echo "========================================="
echo "AirPlay Relay Configuration"
echo "========================================="
echo "Device Name:    $AIRPLAY_NAME"
echo "Audio Backend:  $AUDIO_BACKEND"
echo "Audio Device:   $AUDIO_DEVICE"
echo "Volume Control: $ENABLE_VOLUME_CONTROL"
echo "Volume Range:   ${VOLUME_RANGE}dB"
echo "Interpolation:  $INTERPOLATION"
echo "Metadata Pipe:  $METADATA_PIPE"
echo "========================================="

# ===============================
# Generate shairport-sync config
# ===============================
cat > /etc/shairport-sync.conf <<EOF
general = {
  name = "$AIRPLAY_NAME";
  interpolation = "$INTERPOLATION";
  output_backend = "$AUDIO_BACKEND";
EOF

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

if [ "$ENABLE_VOLUME_CONTROL" = "yes" ]; then
cat >> /etc/shairport-sync.conf <<EOF

alsa = {
  output_device = "$AUDIO_DEVICE";
  mixer_control_name = "PCM";
  mixer_device = "default";
  volume_range_db = $VOLUME_RANGE;
};
EOF
  echo "Volume control: ENABLED"
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

# ===============================
# Fix runtime directories
# ===============================
rm -f /run/dbus/pid
rm -f /run/avahi-daemon/pid

mkdir -p /run/dbus
mkdir -p /run/avahi-daemon

# Ensure dbus UUID exists
dbus-uuidgen --ensure

# ===============================
# Start system services
# ===============================
echo "Starting dbus..."
dbus-daemon --system --fork

sleep 2

echo "Starting avahi..."
avahi-daemon --daemonize --no-chroot

sleep 2

# ===============================
# Start GPIO monitor in background
# ===============================
/app/gpio_relay_airplay.sh &

# ===============================
# Start shairport in foreground
# ===============================
echo "Starting shairport-sync..."
exec shairport-sync -c /etc/shairport-sync.conf -v