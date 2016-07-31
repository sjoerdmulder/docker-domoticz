FROM debian:stretch

ENV DOMOTICZ_VERSION 3.4834

# install packages
RUN apt-get update \
	&& apt-get install -y \
		git \
		wget \
		libssl1.0.2 libssl-dev \
		build-essential cmake \
		libboost-dev \
		libboost-thread1.58.0 libboost-thread-dev \
		libboost-system1.58.0 libboost-system-dev \
		libboost-date-time1.58.0 libboost-date-time-dev \
		libsqlite3-0 libsqlite3-dev \
		curl libcurl3 libcurl4-openssl-dev \
		libusb-0.1-4 libusb-dev \
		zlib1g-dev \
		libudev-dev \
		linux-headers-amd64 \
	&& rm -rf /var/lib/apt/lists/*

# OpenZwave installation
# "install" in order to be found by domoticz
RUN git clone --depth 1 https://github.com/OpenZWave/open-zwave.git /src/open-zwave \
	&& ln -s /src/open-zwave /src/open-zwave-read-only

# compile
WORKDIR /src/open-zwave
RUN make

## Domoticz installation

# Grab source of release and use Config from OpenZWave
RUN mkdir -p /src/domoticz \
	&& wget -qO- https://github.com/domoticz/domoticz/archive/$DOMOTICZ_VERSION.tar.gz | tar xz --strip-components=1 -C /src/domoticz \
	&& rm -r /src/domoticz/Config && ln -s /src/open-zwave/config /src/domoticz/Config

WORKDIR /src/domoticz

# prepare makefile && compile
RUN cmake -DCMAKE_BUILD_TYPE=Release . \
	&& make

VOLUME /config

EXPOSE 8080

ENTRYPOINT ["/src/domoticz/domoticz", "-dbase", "/config/domoticz.db", "-log", "/config/domoticz.log"]
CMD ["-www", "8080"]