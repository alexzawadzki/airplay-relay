FROM balenalib/raspberrypi3-debian:bullseye-run

# Enable systemd init system for Balena
ENV INITSYSTEM on

# Install dependencies
RUN install_packages \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    libdaemon-dev \
    libpopt-dev \
    libconfig-dev \
    libasound2-dev \
    libpulse-dev \
    avahi-daemon \
    libavahi-client-dev \
    libssl-dev \
    libsoxr-dev \
    libglib2.0-dev \
    raspi-gpio \
    dbus

# Build and install shairport-sync
RUN git clone https://github.com/mikebrady/shairport-sync.git && \
    cd shairport-sync && \
    autoreconf -i -f && \
    ./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-metadata --with-soxr --with-pipe --with-systemd --with-libdaemon && \
    make && make install && \
    cd .. && rm -rf shairport-sync

# Copy application files
COPY start.sh /app/
COPY gpio_relay_airplay.sh /app/

RUN chmod +x /app/start.sh /app/gpio_relay_airplay.sh

# Start avahi-daemon for mDNS/Bonjour discovery
RUN mkdir -p /var/run/dbus

CMD ["/app/start.sh"]
