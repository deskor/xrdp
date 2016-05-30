#!/bin/bash

#/etc/init.d/xrdp start

#tail -f /var/log/xrdp-sesman.log

# Start the xrdp xserver
Xorg -config xrdp/xorg.conf -logfile /tmp/Xjay.log -noreset -ac $DISPLAY &

# Start dbus
dbus-launch

echo "------------ start pulseaudio"

# Start pulseaudio
pulseaudio --system > /tmp/pulseaudio.log 2>&1 &

sleep 1

echo "------------ load pulseaudio1"

pactl load-module module-augment-properties
echo "------------ load pulseaudio2"
pactl load-module module-xrdp-source
echo "------------ load pulseaudio3"
pactl load-module module-xrdp-sink

echo "------------ xrdp.sh start"

# Start the RDP server
#xrdp -ns > /tmp/xrdp.log 2>&1 &
/etc/xrdp/xrdp.sh start

echo "------------ start $@"

# Start the X app specified by the CMD / docker run command
echo "Running: env DISPLAY=$DISPLAY $@"
exec env DISPLAY=$DISPLAY "$@"
