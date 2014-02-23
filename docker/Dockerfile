# DOCKER-VERSION 0.3.4
FROM    scaldwell/perl-5.16.3:latest

# Install Mojolicious into the image
ADD src /src
RUN cd /src/Mojolicious-4.84; /usr/local/bin/perl Makefile.PL
RUN cd /src/Mojolicious-4.84; make
RUN cd /src/Mojolicious-4.84; make install

EXPOSE  3000
CMD ["/usr/local/bin/morbo", "-v", "/playground/lite.pl"]
