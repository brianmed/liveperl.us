# DOCKER-VERSION 0.3.4
FROM    perl:5.20.3

# Install Mojolicious into the image
ADD src /src
RUN cd /src; ./run.sh

EXPOSE  3000

CMD ["/src/srv.sh"]

USER www
