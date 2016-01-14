#!/bin/bash

ulimit -u 50
ulimit -f 2500
ulimit -n 30
ulimit -t 120

grep -q 'Mojolicious::Lite' /playground/lite.pl
if [ 0 -eq $? ]; then 
    /usr/local/bin/morbo -v /playground/lite.pl
else
    /usr/local/bin/perl /src/ipc.pl
fi
