#!/bin/bash

ulimit -u 150
ulimit -f 2500
ulimit -n 30
ulimit -t 3

/usr/local/bin/morbo -v /playground/lite.pl
