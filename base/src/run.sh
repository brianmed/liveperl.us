#!/bin/bash

groupadd -g 99 www
useradd -u 99 -s /sbin/nologin -g www www

echo "www hard nproc 10" >> /etc/security/limits.conf
echo "nobody hard nproc 10" >> /etc/security/limits.conf
echo "session required pam_limits.so" >> /etc/pam.d/common-session
echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive
echo "ulimit -u 30" >> /etc/profile

cd /src/Mojolicious-6.22; /usr/local/bin/perl Makefile.PL
cd /src/Mojolicious-6.22; make
cd /src/Mojolicious-6.22; make install
