# DOCKER-VERSION 0.3.4
FROM    scaldwell/perl-5.16.3:latest

# Install Mojolicious into the image
ADD src /src
RUN cd /src; ./run.sh

EXPOSE  3000

CMD ["/src/srv.sh"]

USER www
