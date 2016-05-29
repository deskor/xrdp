#!/usr/bin/env docker build -t xrdp
#
# A common Xrdp image that the window-manager images build on
#
# docker build -t xrdp .

FROM debian:jessie

RUN apt-get update

RUN apt-get install -yq xterm apt-utils sudo
#RUN apt-get install -yq xterm xrdp apt-utils sudo


# for RDP
EXPOSE 3389

# Build from source


RUN apt-get update \
	&& apt-get install -yq vim-tiny git make

# packages installed by X11RDP-o-Matic
RUN apt-get install -yq \
	dialog \
	lsb-release \
	build-essential checkinstall automake automake git \
	git-core libssl-dev libpam0g-dev zlib1g-dev libtool libtool-bin libx11-dev libxfixes-dev \
	pkg-config flex bison libxml2-dev intltool xsltproc xutils-dev python-libxml2 \
	g++ xutils libfuse-dev wget libxrandr-dev x11proto-* libdrm-dev libpixman-1-dev \
	libgl1-mesa-dev libxkbfile-dev libxfont-dev libpciaccess-dev dh-make gettext \
	xfonts-utils \
	libjpeg-dev nasm curl libturbojpeg1 libturbojpeg1-dev \
	libpulse-dev \
	libavcodec-dev libavformat-dev

WORKDIR /usr/src
#RUN git clone https://github.com/scarygliders/X11RDP-o-Matic
#RUN cd X11RDP-o-Matic \
#	&& ./X11rdp-o-matic.sh --justdoit --nocleanup --withsound --withfreerdp --withxrdpvr --withneutrino

RUN git clone https://github.com/neutrinolabs/xrdp
WORKDIR /usr/src/xrdp
RUN git submodule init && git submodule update
RUN ./bootstrap
RUN ./configure --enable-xrdpdebug --enable-tjpeg --enable-fuse
#RUN ./configure --enable-xrdpdebug --enable-neutrinordp --enable-tjpeg --enable-fuse --enable-xrdpvr --enable-rfxcodec --enable-opus
RUN make
RUN make install

# and now xorgxrdp
RUN apt-get install -yq xserver-xorg-dev
WORKDIR /usr/src/xrdp/xorgxrdp
RUN ./bootstrap
RUN ./configure
RUN make
RUN make install

# it asks user to select keyboard
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq xserver-xorg-core

#hard code the root pwd
#RUN echo "root:docker" | chpasswd
#ADD xsession /root/.xsession

# add our user
RUN adduser --disabled-password --gecos "" dockerx 
RUN adduser dockerx sudo
RUN adduser dockerx users
RUN echo "dockerx:docker" | chpasswd

ADD run.sh /usr/local/bin/run

ADD xrdp.ini /etc/xrdp/
ADD start.sh /

# This needs to match the port in the xrdp.ini
ENV DISPLAY=:10

ENTRYPOINT ["/start.sh"]
CMD ["xterm"]
