#!/bin/bash

for i in $(/bin/seq 1 10); do
	ping -W 10 -c 2 45.55.49.245 && break
	sleep 1
done

/usr/sbin/wondershaper docker0 256 256

cd /opt/liveperl.us/docroot/live_perl

/opt/perl /opt/perl-5.20.3/bin/hypnotoad -f script/live_perl
