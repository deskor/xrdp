#!/bin/bash

#/etc/init.d/xrdp start

#tail -f /var/log/xrdp-sesman.log

# Start the xrdp xserver
Xorg -config xrdp/xorg.conf -logfile /tmp/Xjay.log -noreset -ac $DISPLAY &

# Start dbus
dbus-launch

# Start pulseaudio
pulseaudio --system > /tmp/pulseaudio.log 2>&1 &
pactl load-module module-augment-properties
pactl load-module module-xrdp-source
pactl load-module module-xrdp-sink

paplay "/host/c/Windows/Media/Windows Startup.wav" 

# Start the RDP server
#xrdp -ns > /tmp/xrdp.log 2>&1 &
/etc/xrdp/xrdp.sh start

# Start the X app specified by the CMD / docker run command
echo "Running: env DISPLAY=$DISPLAY $@"
exec env DISPLAY=$DISPLAY "$@"
