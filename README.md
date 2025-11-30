# AirPlay Relay Controller

Turn your Raspberry Pi into an AirPlay receiver with automatic GPIO relay control for amplifiers and audio equipment.

## Overview

This project combines Shairport Sync (AirPlay audio receiver) with intelligent GPIO relay control. When you start streaming audio via AirPlay, it automatically turns on your amplifier or audio equipment. When playback stops, it waits a configurable delay before powering off, preventing rapid on/off cycling.

## Features

- **AirPlay Audio Receiver**: Stream music from iPhone, iPad, Mac, or iTunes
- **Automatic Relay Control**: Powers devices on/off based on playback state
- **Smart Turn-off Delay**: Configurable delay (default 10s) prevents rapid cycling when pausing/resuming
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

### Environment Variables

Configure the turn-off delay via environment variables:

| Variable          | Default | Description                                    |
|-------------------|---------|------------------------------------------------|
| `TURN_OFF_DELAY`  | 10      | Seconds to wait before turning off relay       |

#### Change via Balena Dashboard

1. Go to your application in Balena dashboard
2. Select your device
3. Navigate to "Device Variables" or "Service Variables"
4. Add/Edit: `TURN_OFF_DELAY = 15` (for 15 seconds)
5. Device will restart automatically with new settings

#### Change via docker-compose.yml (Manual Deployment)

Edit `docker-compose.yml`:

```yaml
environment:
  - TURN_OFF_DELAY=15  # Change to desired seconds
```

Then restart:
```bash
docker-compose down && docker-compose up -d
```

### Change GPIO Pin

To use a different GPIO pin, edit `airplay/gpio_relay_airplay.sh`:

```bash
GPIO=17  # Change to your desired GPIO number (BCM)
```

## Usage

### Connecting from iOS/macOS

1. Ensure your device and Raspberry Pi are on the same network
2. Open Control Center (iOS) or Music/iTunes (macOS)
3. Tap the AirPlay icon
4. Select "Shairport Sync" (your Raspberry Pi)
5. Play music - your amplifier will turn on automatically
6. Stop playback - amplifier turns off after configured delay

### Monitoring (Balena Cloud)

View real-time logs from the Balena dashboard:

```
AirPlay GPIO Relay started (GPIO 17, Turn-off delay: 10s)
AirPlay STARTED
AirPlay playback ended, scheduling turn-off in 10s...
AirPlay STOPPED (after 10s delay)
```

If music resumes during the delay:
```
Turn-off cancelled (music resumed)
AirPlay STARTED
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
gpio -g mode 17 out
gpio -g read 17  # Should show 0 or 1
```

**Verify WiringPi installation:**
```bash
gpio -v
```

**Check logs for errors:**
```bash
# Balena Cloud
View logs in dashboard

# Manual deployment
docker-compose logs airplay
```

### Audio quality issues

**Check ALSA configuration:**
```bash
aplay -l  # List audio devices
```

Edit `airplay/shairport-sync.conf` to specify audio device if needed.

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
│   ├── gpio_relay_airplay.sh   # GPIO control script
│   └── shairport-sync.conf     # AirPlay configuration
├── docker-compose.yml          # Service orchestration
├── balena.yml                  # Balena Cloud configuration
├── .balenaignore               # Files to exclude from builds
└── README.md                   # This file
```

### Local Development

```bash
# Build locally
docker-compose build

# Test the container
docker-compose up

# View logs
docker-compose logs -f
```

### Customization Ideas

- **Add multiple GPIO outputs** for different devices
- **Implement web interface** for remote control
- **Add motion sensor integration** for auto-power management
- **Create custom AirPlay device name** in `shairport-sync.conf`
- **Add LCD/OLED display** to show currently playing track

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
- **WiringPi**: [LGPL v3](http://wiringpi.com/)

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
