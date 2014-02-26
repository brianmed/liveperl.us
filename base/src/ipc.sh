#!/bin/bash

ulimit -u 10
ulimit -f 2500
ulimit -n 30
ulimit -t 3
ulimit -m 40960

/usr/local/bin/perl /src/ipc.pl
