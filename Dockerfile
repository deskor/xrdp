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
# --disable-pam as it seems it uses systemd!
RUN ./configure --enable-xrdpdebug --enable-tjpeg --enable-fuse --enable-simplesound --enable-load_pulse_modules --disable-pam
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

# add our user
RUN adduser --disabled-password --gecos "" dockerx 
RUN adduser dockerx sudo
RUN adduser dockerx users
RUN echo "dockerx:docker" | chpasswd

ENTRYPOINT ["/start.sh"]

RUN apt-get install -yq rxvt-unicode
CMD ["rxvt-unicode", "-geometry", "164x58", "-e", "bash"]

# Audio?
# https://github.com/neutrinolabs/xrdp/issues/321
# http://w.vmeta.jp/tdiary/20140918.html
RUN apt-get install -yq dpkg-dev dbus-x11
WORKDIR /usr/src
RUN \
	cat /etc/apt/sources.list | sed 's/^deb /deb-src /g' >> /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get source pulseaudio \
	&& apt-get build-dep -yq pulseaudio \
	&& apt-get source --compile pulseaudio

RUN apt-get install -yq pulseaudio \
	&& adduser root audio \
	&& adduser root pulse \
	&& adduser root pulse-access \
	&& adduser dockerx audio \
	&& adduser dockerx pulse \
	&& adduser dockerx pulse-access

RUN cd /usr/src/xrdp/sesman/chansrv/pulse \
	&& sed -i~ 's|^PULSE_DIR.*|PULSE_DIR = /usr/src/pulseaudio-5.0|' Makefile \
	&& make \
	&& cp module-xrdp-sink.so module-xrdp-source.so /usr/lib/pulse-5.0/modules/

# The scripts that make it work (keep last)
ADD run.sh /usr/local/bin/run
ADD xrdp.ini /etc/xrdp/
ADD start.sh /
