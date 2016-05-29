#!/bin/bash

#/etc/init.d/xrdp start

#tail -f /var/log/xrdp-sesman.log

# Start the xrdp xserver
Xorg -config xrdp/xorg.conf -logfile /tmp/Xjay.log -noreset -ac $DISPLAY &

# Start the RDP server
xrdp -ns & > /tmp/xrdp.log 2>&1

# Start the X app specified by the CMD / docker run command
exec env DISPLAY=$DISPLAY "$@"
