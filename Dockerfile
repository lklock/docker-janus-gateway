FROM debian:buster

LABEL maintainer="Laurent Klock <klockla@hotmail.com>"
LABEL description="Janus WebRTC server"

# Prerequisites installation

RUN apt-get update

RUN apt-get install -y \
	git \
	build-essential \
	autoconf \
	automake \
	autotools-dev \
	dh-make \
	debhelper \
	devscripts \
	fakeroot \
	xutils \
	lintian \
	pbuilder \
	gengetopt \
	libtool \
	automake \
	cmake \
	pkg-config \
	doxygen \
	graphviz

RUN apt-get install -y \
	libconfig-dev \
	zlib1g-dev \
	libmicrohttpd-dev \
	libjansson-dev \
	libssl-dev \
	libsrtp2-dev \
	libsofia-sip-ua-dev \ 
	libglib2.0-dev \
	libopus-dev \
	libogg-dev \
	libwebsockets-dev \
	libavutil-dev \
	libavcodec-dev \
	libavformat-dev \
	liblua5.3-dev \
	libcurl4-openssl-dev \
	libnanomsg-dev

RUN git clone https://github.com/sctplab/usrsctp && cd usrsctp && ./bootstrap \
	&& ./configure --prefix=/usr && make && sudo make install

RUN apt-get install -y gtk-doc-tools
RUN git clone https://gitlab.freedesktop.org/libnice/libnice.git/ && cd libnice \
	&& ./autogen.sh && ./configure --prefix=/usr CFLAGS="-Wno-error=format -Wno-error=cast-align" \
        && make && sudo make install

# Janus WebRTC Installation

RUN mkdir -p /usr/src/janus /var/janus/log /var/janus/data /var/janus/html

RUN cd /usr/src/janus && wget https://github.com/meetecho/janus-gateway/archive/v0.9.2.tar.gz

RUN cd /usr/src/janus && tar -xzf v0.9.2.tar.gz && cd janus-gateway-0.9.2 && \
	cp -r /usr/src/janus/janus-gateway-0.9.2/html/* /var/janus/html
	
RUN cd /usr/src/janus/janus-gateway-0.9.2 && sh autogen.sh && \
#	./configure --prefix=/var/janus --disable-rabbitmq --disable-mqtt --enable-docs && \
	./configure --prefix=/var/janus --disable-rabbitmq --disable-mqtt && \
	make && make install && make configs && \
	rm -rf /usr/src/janus

EXPOSE 8880
EXPOSE 8088/tcp 8188/tcp
EXPOSE 8188/udp 10000-10200/udp

RUN apt-get install nginx -y
COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY conf/janus.plugin.videoroom.jcfg /var/janus/etc/janus/janus.plugin.videoroom.jcfg

CMD service nginx restart && /var/janus/bin/janus --nat-1-1=${DOCKER_IP} -r 10000-10200
