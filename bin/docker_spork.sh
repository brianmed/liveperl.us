#!/bin/bash

sudo /usr/bin/docker ps | grep 0.0.0.0 | perl -anE '@o=`sudo /usr/bin/docker top $F[0]`; system("sudo /usr/bin/docker stop $F[0]") if 10 < @o'
