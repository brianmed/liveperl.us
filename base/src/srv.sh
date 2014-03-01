#!/bin/bash

ulimit -u 50
ulimit -f 2500
ulimit -n 30
ulimit -t 120

/usr/local/bin/morbo -v /playground/lite.pl
