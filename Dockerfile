FROM debian:stretch
MAINTAINER Sylvain Desbureaux <sylvain@desbureaux.fr>

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

## OpenZwave installation
# grep git version of openzwave
RUN git clone --depth 2 https://github.com/OpenZWave/open-zwave.git /src/open-zwave

# untar the files
WORKDIR /src/open-zwave

# compile
RUN make

# "install" in order to be found by domoticz
RUN ln -s /src/open-zwave /src/open-zwave-read-only

## Domoticz installation

# Grab source of release
RUN mkdir -p /src/domoticz \
	&& wget -qO- https://github.com/domoticz/domoticz/archive/$DOMOTICZ_VERSION.tar.gz | tar xz --strip-components=1 -C /src/domoticz

WORKDIR /src/domoticz

# prepare makefile
RUN cmake -DCMAKE_BUILD_TYPE=Release .

# compile
RUN make

# update to latest config from open-zwave
RUN rm -r /src/domoticz/Config && ln -s /src/open-zwave/config /src/domoticz/Config

# remove git and tmp dirs
#RUN apt-get remove -y git cmake linux-headers-amd64 build-essential libssl-dev libboost-dev libboost-thread-dev libboost-system-dev libsqlite3-dev libcurl4-openssl-dev #libusb-dev zlib1g-dev libudev-dev && \
#   apt-get autoremove -y && \
#   apt-get clean

VOLUME /config

EXPOSE 8080

ENTRYPOINT ["/src/domoticz/domoticz", "-dbase", "/config/domoticz.db", "-log", "/config/domoticz.log"]
CMD ["-www", "8080"]