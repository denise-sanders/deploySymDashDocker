# The Dockerization of Symdash
# build using sudo docker build -t symdash_img .


# Set base image as Trusty Ubuntu
FROM ubuntu:14.04

# File Author / Maintainer
MAINTAINER Team Symetric (Denise) 

# Install general things
RUN apt-get update && apt-get install -y \
        gcc \
        git \
        libpq-dev \ 
        npm \
        python \ 
        python-dev \ 
        python-pip \
        python-setuptools \        
        wget

# RUN pip install supervisor
# Push all that is symdash
# RUN mkdir /etc/symdash
# ADD https://github.rackspace.com/symetric/symdash.git /etc/symdash
# ADD git@github.rackspace.com:symetric/symdash.git /etc/symdash
# RUN git clone git@github.rackspace.com:symetric/symdash.git

COPY symdash /symdash
RUN ls /symdash
RUN pip install -r symdash/requirements.txt

# COPY configure.py symdash/config.py


# Connect to redis server?

ADD run.sh /run.sh

# Figure out if this is right
ENTRYPOINT ["python"]
CMD ["/symdash/run.py","web"]
EXPOSE 6379
