FROM balenalib/raspberrypi3-debian:bullseye-run

RUN apt-get update && \
    apt-get install -y git build-essential autoconf automake libtool libdaemon-dev libpopt-dev \
    libconfig-dev libasound2-dev libpulse-dev avahi-daemon libavahi-client-dev libssl-dev \
    libsoxr-dev libglib2.0-dev wget curl wiringpi && \
    git clone https://github.com/mikebrady/shairport-sync.git && \
    cd shairport-sync && \
    autoreconf -i -f && \
    ./configure --sysconfdir=/etc --with-alsa --with-avahi --with-metadata --with-soxr --with-pipe --with-systemd --with-libdaemon && \
    make && make install && \
    cd .. && rm -rf shairport-sync && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY gpio_relay_airplay.sh /app/
COPY shairport-sync.conf /app/

RUN chmod +x /app/gpio_relay_airplay.sh

CMD ["shairport-sync"]
