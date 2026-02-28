# AirPlay Relay Controller

Turn your Raspberry Pi into an AirPlay receiver with automatic GPIO relay control for amplifiers and audio equipment.

## Overview

This project combines Shairport Sync (AirPlay audio receiver) with intelligent GPIO relay control. When you start streaming audio via AirPlay, it automatically turns on your amplifier or audio equipment. When playback stops, it waits a configurable delay before powering off, preventing rapid on/off cycling.

## Features

- **AirPlay Audio Receiver**: Stream music from iPhone, iPad, Mac, or iTunes
- **Automatic Relay Control**: Powers devices on/off based on playback state
- **Smart Turn-off Delay**: Configurable delay (default 10s) prevents rapid cycling when pausing/resuming
- **Software Volume Control**: Adjust volume directly from iOS/macOS with configurable range
- **Fully Configurable**: Change GPIO pins, device name, audio settings via environment variables
- **Password Protection**: Optional password to restrict AirPlay access
- **Balena Cloud Ready**: Easy deployment, monitoring, and OTA updates
- **Remote Management**: Configure and monitor from anywhere via Balena dashboard
- **Multi-Device Support**: Manage fleets of devices from one interface

## Hardware Requirements

### Required Components

- **Raspberry Pi** (3, 3+, 4, or 400)
- **microSD Card** (8GB minimum, 16GB+ recommended)
- **5V Relay Module** (compatible with 3.3V GPIO trigger)
- **Power Supply** (official Raspberry Pi power supply recommended)
- **Audio Output** (3.5mm jack, HDMI, or USB audio device)

### Recommended Relay Modules

- Single channel 5V relay with optocoupler isolation
- Trigger voltage: 3.3V compatible
- Examples:
  - SainSmart 2-Channel 5V Relay Module
  - Elegoo 5V Relay Module
  - Any relay module marked "3.3V trigger compatible"

## Wiring Diagram

### GPIO Connection

```
Raspberry Pi GPIO          Relay Module
─────────────────          ────────────
GPIO 17 (Pin 11)    ─────> IN/Signal
Ground (Pin 6)      ─────> GND
5V (Pin 2)          ─────> VCC
```

### GPIO Pin Reference (BCM Numbering)

| Physical Pin | BCM GPIO | Function      |
|--------------|----------|---------------|
| Pin 2        | 5V       | Relay Power   |
| Pin 6        | GND      | Ground        |
| Pin 11       | GPIO 17  | Relay Control |

**Note**: The script uses BCM (Broadcom) GPIO numbering, not physical pin numbers.

### Relay to Amplifier Connection

Connect your amplifier's remote trigger or power switch to the relay's normally open (NO) contacts:

```
Relay                      Amplifier
─────                      ─────────
COM  ────────────────────> Remote Trigger +
NO   ────────────────────> Remote Trigger -
```

Or for power switching (ensure relay is rated for the load):

```
Relay                      Power
─────                      ─────
COM  ─────< AC Hot In
NO   ─────> AC Hot Out to Amplifier
```

**Warning**: Only switch AC power if you're qualified and your relay is properly rated. For most users, using the amplifier's remote trigger (12V trigger) is safer and recommended.

## Deployment Options

### Option 1: Balena Cloud Deployment (Recommended)

#### Prerequisites

1. Create a free account at [Balena Cloud](https://balena.io/cloud)
2. Install [Balena CLI](https://github.com/balena-io/balena-cli/blob/master/INSTALL.md):
   ```bash
   npm install -g balena-cli
   ```

#### Deploy Steps

1. **Clone this repository**
   ```bash
   git clone https://github.com/alexzawadzki/airplay-relay.git
   cd airplay-relay
   ```

2. **Login to Balena**
   ```bash
   balena login
   ```

3. **Create a new application**
   ```bash
   balena app create airplay-relay --type raspberrypi3
   ```

   For Raspberry Pi 4, use `--type raspberrypi4-64`

4. **Add your device**
   - Go to [Balena Dashboard](https://dashboard.balena-cloud.com/)
   - Click your application
   - Click "Add Device"
   - Download the BalenaOS image
   - Flash it to your SD card using [balenaEtcher](https://www.balena.io/etcher/)

5. **Deploy the code**
   ```bash
   balena push airplay-relay
   ```

6. **Insert SD card into Raspberry Pi and power on**

   Your device will appear online in the Balena dashboard within a few minutes.

#### Balena Dashboard Features

Once deployed, you can:
- **View logs** in real-time (see when AirPlay starts/stops)
- **Configure variables** (change turn-off delay without SSH)
- **Remote SSH access** from anywhere
- **Monitor device health** (CPU, memory, temperature)
- **Push updates** over-the-air to all devices

### Option 2: Manual Docker Deployment

If you prefer to deploy without Balena Cloud:

1. **Flash Raspberry Pi OS to SD card**

2. **SSH into your Pi**
   ```bash
   ssh pi@raspberrypi.local
   ```

3. **Clone repository**
   ```bash
   git clone https://github.com/alexzawadzki/airplay-relay.git
   cd airplay-relay
   ```

4. **Install Docker and Docker Compose** (if not already installed)
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo apt-get install -y docker-compose
   ```

5. **Start the application**
   ```bash
   docker-compose up -d
   ```

## Configuration

All settings can be configured via environment variables in the Balena dashboard or `docker-compose.yml`.

### Environment Variables

#### GPIO Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GPIO_PIN` | 17 | GPIO pin number using BCM numbering (not physical pin) |
| `GPIO_ACTIVE_STATE` | 1 | Signal to activate relay: `1` = HIGH, `0` = LOW |
| `TURN_OFF_DELAY` | 10 | Seconds to wait before turning off relay after playback stops |

#### AirPlay Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `AIRPLAY_NAME` | AirPlay Relay | Device name shown in AirPlay device list |
| `AIRPLAY_PASSWORD` | _(empty)_ | Optional password for AirPlay access (leave empty for no password) |

#### Audio Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `AUDIO_BACKEND` | alsa | Audio backend: `alsa`, `pulse`, or `pipe` |
| `AUDIO_DEVICE` | default | ALSA device name (use `aplay -L` on Pi to list available devices) |
| `ENABLE_VOLUME_CONTROL` | yes | Enable software volume control: `yes` or `no` |
| `VOLUME_RANGE` | 60 | Software volume control range in dB (30-60 recommended) |

**Common Audio Devices:**
- `default` - System default audio output
- `sysdefault:CARD=Headphones` - 3.5mm headphone jack
- `sysdefault:CARD=vc4hdmi` - HDMI audio output
- `hw:0,0` - First hardware device

#### Advanced Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `INTERPOLATION` | soxr | Audio interpolation quality: `basic` or `soxr` (higher quality) |
| `METADATA_PIPE` | /tmp/shairport-sync-metadata | Path to metadata pipe for event monitoring |

### Configuring via Balena Dashboard

1. Log in to [Balena Dashboard](https://dashboard.balena-cloud.com/)
2. Select your application
3. Click on your device
4. Navigate to "Device Variables" tab
5. Click "Add Variable"
6. Enter variable name and value (e.g., `AIRPLAY_NAME` = `Living Room Speakers`)
7. Device will restart automatically with new settings

**Examples:**

- **Change device name**: `AIRPLAY_NAME = Kitchen Speakers`
- **Increase turn-off delay**: `TURN_OFF_DELAY = 30`
- **Use different GPIO**: `GPIO_PIN = 27`
- **Add password**: `AIRPLAY_PASSWORD = mysecretpass`
- **Adjust volume range**: `VOLUME_RANGE = 40`

### Configuring via docker-compose.yml (Manual Deployment)

Edit `docker-compose.yml` and modify the environment section:

```yaml
environment:
  - GPIO_PIN=27                      # Use GPIO 27 instead of 17
  - TURN_OFF_DELAY=30                # 30 second delay
  - AIRPLAY_NAME=Garage Speakers     # Custom name
  - AIRPLAY_PASSWORD=mypassword      # Add password protection
  - VOLUME_RANGE=40                  # Quieter max volume
```

Then restart:
```bash
docker-compose down && docker-compose up -d
```

## Usage

### Connecting from iOS/macOS

1. Ensure your device and Raspberry Pi are on the same network
2. Open Control Center (iOS) or Music/iTunes (macOS)
3. Tap the AirPlay icon
4. Select your device name (default: "AirPlay Relay")
5. Enter password if you configured one
6. Play music - your amplifier will turn on automatically
7. Use the volume controls on your device to adjust playback volume
8. Stop playback - amplifier turns off after configured delay

### Volume Control

When `ENABLE_VOLUME_CONTROL=yes` (default), you can control the Raspberry Pi's audio output volume directly from your iOS/macOS device:

- **iOS**: Use volume buttons or Control Center slider
- **macOS**: Use volume slider in AirPlay menu
- **Range**: Controlled by `VOLUME_RANGE` setting (default 60dB)

The volume control affects the Pi's audio output, perfect for controlling amplifier input levels.

### Monitoring (Balena Cloud)

View real-time logs from the Balena dashboard:

```
=========================================
AirPlay Relay Configuration
=========================================
Device Name: AirPlay Relay
Audio Backend: alsa
Audio Device: default
Volume Control: yes
Volume Range: 60dB
Interpolation: soxr
Metadata Pipe: /tmp/shairport-sync-metadata
=========================================

=========================================
GPIO Relay Configuration
=========================================
GPIO Pin: 17 (BCM)
Active State: 1 (HIGH)
Turn-off Delay: 10s
Metadata Pipe: /tmp/shairport-sync-metadata
=========================================

Monitoring AirPlay events...

[2025-11-30 20:15:32] AirPlay STARTED - Relay ON
[2025-11-30 20:18:45] AirPlay playback ended, scheduling turn-off in 10s...
AirPlay STOPPED (after 10s delay)
```

If music resumes during the delay:
```
Turn-off cancelled (music resumed)
[2025-11-30 20:18:50] AirPlay STARTED - Relay ON
```

### Monitoring (Manual Deployment)

```bash
docker-compose logs -f airplay
```

## How It Works

1. **Shairport Sync** creates an AirPlay receiver on your network
2. When playback starts (`pbeg` event):
   - Script sets GPIO 17 HIGH
   - Relay activates
   - Amplifier powers on
3. When playback stops (`pend` event):
   - Script starts countdown timer
   - If playback resumes before timer expires, countdown cancels
   - If timer expires, GPIO 17 goes LOW
   - Relay deactivates
   - Amplifier powers off

This prevents the amplifier from rapidly cycling on/off when you pause/resume or skip between songs.

## Supported Devices

Tested and supported Raspberry Pi models:
- Raspberry Pi 3 Model B/B+
- Raspberry Pi 4 Model B (1GB, 2GB, 4GB, 8GB)
- Raspberry Pi 400
- Raspberry Pi 3 Model A+

## Troubleshooting

### AirPlay device not showing up

**Check Avahi/mDNS is running:**
```bash
balena ssh <device-uuid>
ps aux | grep avahi
```

**Ensure host network mode is enabled** in `docker-compose.yml`:
```yaml
network_mode: host
```

### Relay not switching

**Check GPIO permissions:**
```bash
raspi-gpio get 17
```

**Verify raspi-gpio installation:**
```bash
raspi-gpio help
```

**Check logs for errors:**
```bash
# Balena Cloud
View logs in dashboard

# Manual deployment
docker-compose logs airplay
```

### Audio quality issues

**Check available audio devices:**
```bash
aplay -L  # List all audio devices
aplay -l  # List hardware devices
```

**Change audio device via environment variable:**
Set `AUDIO_DEVICE` to match a device from `aplay -L`. For example:
- `AUDIO_DEVICE=sysdefault:CARD=Headphones` for 3.5mm jack
- `AUDIO_DEVICE=sysdefault:CARD=vc4hdmi` for HDMI audio

**Improve audio quality:**
- Set `INTERPOLATION=soxr` for better quality (default)
- Increase `VOLUME_RANGE` for more dynamic range

### Volume control not working

**Check volume control is enabled:**
```bash
# In Balena dashboard or docker-compose.yml
ENABLE_VOLUME_CONTROL=yes
```

**Test ALSA mixer:**
```bash
alsamixer  # Should show PCM control
amixer scontrols  # List available mixer controls
```

### Relay stays on after music stops

**Check delay timer:**
- Verify `TURN_OFF_DELAY` environment variable is set correctly
- Check logs to see if turn-off is being scheduled
- Ensure the script isn't crashing during the delay period

## Development

### Project Structure

```
airplay-relay/
├── airplay/
│   ├── Dockerfile              # Container image definition
│   ├── start.sh                # Startup script that generates config and starts services
│   └── gpio_relay_airplay.sh   # GPIO control script with event monitoring
├── docker-compose.yml          # Service orchestration with environment variables
├── balena.yml                  # Balena Cloud configuration
├── .balenaignore               # Files to exclude from builds
└── README.md                   # This file
```

### How It Works

1. **start.sh** reads environment variables and generates `/etc/shairport-sync.conf` dynamically
2. **Avahi daemon** starts for mDNS/Bonjour service discovery
3. **shairport-sync** starts as AirPlay receiver with generated config
4. **gpio_relay_airplay.sh** monitors the metadata pipe for playback events
5. When `pbeg` (playback begin) event detected → GPIO goes HIGH → Relay activates
6. When `pend` (playback end) event detected → Starts countdown timer
7. If countdown completes → GPIO goes LOW → Relay deactivates
8. If playback resumes during countdown → Timer cancels, relay stays active

### Local Development

```bash
# Build locally
docker-compose build

# Test the container
docker-compose up

# View logs in real-time
docker-compose logs -f airplay

# Test with different settings
AIRPLAY_NAME="Test Speaker" TURN_OFF_DELAY=5 docker-compose up
```

### Customization Ideas

- **Add multiple GPIO outputs** for different devices (zone control)
- **Implement web interface** for remote control via Balena dashboard
- **Add motion sensor integration** for auto-power management
- **Add LCD/OLED display** to show currently playing track and volume
- **Integrate with Home Assistant** via MQTT
- **Add LED status indicators** for relay state

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project uses:
- **Shairport Sync**: [MIT License](https://github.com/mikebrady/shairport-sync/blob/master/LICENSES)
- **raspi-gpio**: Part of the Raspberry Pi OS toolchain

## Credits

- [Shairport Sync](https://github.com/mikebrady/shairport-sync) by Mike Brady
- [Balena](https://www.balena.io/) for IoT platform and tools

## Support

- **Issues**: [GitHub Issues](https://github.com/alexzawadzki/airplay-relay/issues)
- **Balena Forums**: [forums.balena.io](https://forums.balena.io/)
- **Shairport Sync**: [GitHub Discussions](https://github.com/mikebrady/shairport-sync/discussions)

## Safety Warning

When working with AC power and relays:
- **Never work on live circuits**
- **Use properly rated relays** for your load
- **Consider using low-voltage remote triggers** instead of switching AC power
- **Consult a qualified electrician** if unsure
- **Use fuses and proper enclosures**

The safest approach is connecting to your amplifier's 12V remote trigger input, not switching AC power directly.

---

Made with ❤️ for the DIY audio community
