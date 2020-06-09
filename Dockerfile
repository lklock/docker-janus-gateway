FROM debian:buster

LABEL maintainer="Laurent Klock <klockla@hotmail.com>"
LABEL description="Janus WebRTC server"

# Prerequisites installation

RUN apt-get update && apt-get install -y \
	autoconf \
	automake \
	autotools-dev \
	build-essential \
	cmake \
	dh-make \
	debhelper \
	devscripts \
	doxygen \
	fakeroot \
	gengetopt \
	git \
	graphviz \
	gtk-doc-tools \
	libtool \
	lintian \
	nginx \
	pbuilder \
	pkg-config \
	xutils

RUN apt-get install -y \
	libavcodec-dev \
	libavformat-dev \
	libavutil-dev \
	libconfig-dev \
	libcurl4-openssl-dev \
	libglib2.0-dev \
	libjansson-dev \
	liblua5.3-dev \
	libmicrohttpd-dev \
	libnanomsg-dev \
	libogg-dev \
	libopus-dev \
	libsofia-sip-ua-dev \ 
	libssl-dev \
	libwebsockets-dev \
	zlib1g-dev

RUN git clone https://github.com/sctplab/usrsctp && cd usrsctp && ./bootstrap \
        && ./configure CFLAGS="-Wno-error=cpp" --prefix=/usr && make && sudo make install && rm -fr /usrsctp

RUN wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz \
        && tar xfv v2.3.0.tar.gz  && cd libsrtp-2.3.0 \
        && ./configure --prefix=/usr --enable-openssl \
        && make shared_library && sudo make install && rm -fr /libsrtp-2.3.0 && rm -f /v2.3.0.tar.gz

RUN git clone https://gitlab.freedesktop.org/libnice/libnice.git/ && cd libnice && git checkout 0.1.16 \
        && ./autogen.sh && ./configure --prefix=/usr CFLAGS="-Wno-error=format -Wno-error=cast-align" \
        && make && sudo make install && rm -fr /libnice

# Janus WebRTC Installation

RUN mkdir -p /usr/src/janus /var/janus/log /var/janus/data /var/janus/html \
        && cd /usr/src/janus && wget https://github.com/meetecho/janus-gateway/archive/v0.10.0.tar.gz \
        && tar -xzf v0.10.0.tar.gz && cd janus-gateway-0.10.0 \
        && cp -r /usr/src/janus/janus-gateway-0.10.0/html/* /var/janus/html \
        && sh autogen.sh \
        && ./configure --prefix=/var/janus --disable-rabbitmq --disable-mqtt \
        && make && make install && make configs \
        && rm -rf /usr/src/janus


EXPOSE 8880
EXPOSE 8088/tcp 8188/tcp
EXPOSE 8188/udp 10000-10200/udp

COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY conf/janus.plugin.videoroom.jcfg /var/janus/etc/janus/janus.plugin.videoroom.jcfg

CMD service nginx restart && /var/janus/bin/janus --nat-1-1=${DOCKER_IP} -r 10000-10200
