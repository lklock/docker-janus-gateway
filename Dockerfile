FROM debian:buster

LABEL maintainer="Laurent Klock <klockla@hotmail.com>"
LABEL description="Janus WebRTC server"

# Prerequisites installation

RUN apt-get update

RUN apt-get install -y \
	build-essential \
	autoconf \
	automake \
	autotools-dev \
	cmake \
	dh-make \
	debhelper \
	devscripts \
	doxygen \
	fakeroot \
	git \
	gengetopt \
	graphviz \
	gtk-doc-tools \
	libtool \
	lintian \
	nginx \
	pbuilder \
	pkg-config \
	xutils

RUN apt-get install -y \
	libconfig-dev \
	zlib1g-dev \
	libmicrohttpd-dev \
	libjansson-dev \
	libssl-dev \
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

RUN wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz \
        && tar xfv v2.3.0.tar.gz  && cd libsrtp-2.3.0 \
        && ./configure --prefix=/usr --enable-openssl \
        && make shared_library && sudo make install

RUN git clone https://gitlab.freedesktop.org/libnice/libnice.git/ && cd libnice \
	&& ./autogen.sh && ./configure --prefix=/usr CFLAGS="-Wno-error=format -Wno-error=cast-align" \
        && make && sudo make install

# Janus WebRTC Installation

RUN mkdir -p /usr/src/janus /var/janus/log /var/janus/data /var/janus/html

RUN cd /usr/src/janus && wget https://github.com/meetecho/janus-gateway/archive/v0.9.4.tar.gz

RUN cd /usr/src/janus && tar -xzf v0.9.4.tar.gz && cd janus-gateway-0.9.4 && \
	cp -r /usr/src/janus/janus-gateway-0.9.4/html/* /var/janus/html
	
RUN cd /usr/src/janus/janus-gateway-0.9.4 && sh autogen.sh && \
	./configure --prefix=/var/janus --disable-rabbitmq --disable-mqtt && \
	make && make install && make configs && \
	rm -rf /usr/src/janus

EXPOSE 8880
EXPOSE 8088/tcp 8188/tcp
EXPOSE 8188/udp 10000-10200/udp

COPY nginx/nginx.conf /etc/nginx/nginx.conf

COPY conf/janus.plugin.videoroom.jcfg /var/janus/etc/janus/janus.plugin.videoroom.jcfg

CMD service nginx restart && /var/janus/bin/janus --nat-1-1=${DOCKER_IP} -r 10000-10200
