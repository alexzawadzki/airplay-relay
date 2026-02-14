FROM balenalib/raspberrypi3-debian:bullseye-run

ENV INITSYSTEM on

# Install build dependencies and runtime packages
RUN install_packages \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    libpopt-dev \
    libconfig-dev \
    libasound2-dev \
    avahi-daemon \
    libavahi-client-dev \
    libssl-dev \
    libsoxr-dev \
    libglib2.0-dev \
    raspi-gpio \
    dbus

# Pin shairport-sync to a specific release for reproducible builds.
# v4.x dropped --with-libdaemon and --with-systemd; do not add them back.
ARG SPS_VERSION=4.3.2
RUN git clone --depth 1 --branch ${SPS_VERSION} \
        https://github.com/mikebrady/shairport-sync.git && \
    cd shairport-sync && \
    autoreconf -i -f && \
    ./configure \
        --sysconfdir=/etc \
        --with-alsa \
        --with-avahi \
        --with-ssl=openssl \
        --with-metadata \
        --with-soxr \
        --with-pipe && \
    make -j$(nproc) && \
    make install && \
    cd .. && rm -rf shairport-sync

COPY start.sh /app/
COPY gpio_relay_airplay.sh /app/
RUN chmod +x /app/start.sh /app/gpio_relay_airplay.sh

RUN mkdir -p /var/run/dbus

CMD ["/app/start.sh"]
