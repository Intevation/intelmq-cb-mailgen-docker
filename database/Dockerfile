FROM postgres:14
# As of 2023-08-22, this is Debian 11 Bullseye

ARG INTELMQ_CERTBUND_CONTACT_REVISION
ARG INTELMQ_REVISION
ARG INTELMQ_MAILGEN_REVISION

ENV INTELMQ_CERTBUND_CONTACT_REVISION ${INTELMQ_CERTBUND_CONTACT_REVISION}
ENV INTELMQ_REVISION ${INTELMQ_REVISION}
ENV INTELMQ_MAILGEN_REVISION ${INTELMQ_MAILGEN_REVISION}

# Install python3 deps and stuff
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git curl python3-pip python3-psycopg2

# pip installs some packages (intelmq-api, intelmq-manager) into /usr/lib/python3.8/site-packages
# instead of /usr/local/lib/python3.10/dist-packages (which is the default location, also in python's sitepath)
# https://github.com/Intevation/intelmq-cb-mailgen-docker/issues/9
# https://github.com/pypa/pip/issues/10805
#RUN ln -s /usr/local/lib/python3.9/dist-packages/ /usr/lib/python3.9/site-packages

WORKDIR /opt

# we only need a minimal IntelMQ installation here, i.e. just the library. We can skip the setup
RUN git clone https://github.com/certtools/intelmq.git
WORKDIR /opt/intelmq
RUN git config --global --add safe.directory /opt/intelmq
RUN git checkout $INTELMQ_REVISION && pip3 install -e .

WORKDIR /opt

# Clone the certbund-contact repo to have the tools for filling the database.
RUN git clone https://github.com/Intevation/intelmq-certbund-contact.git

# install mailgen to get the notifications.sql file, and dependency for certbund-contact
WORKDIR /opt
# Clone the Mailgen repo
RUN git clone https://github.com/intevation/intelmq-mailgen.git
RUN cd /opt/intelmq-mailgen && git checkout $INTELMQ_MAILGEN_REVISION && pip3 install -e .

# Install on the repo
RUN cd intelmq-certbund-contact && git checkout $INTELMQ_CERTBUND_CONTACT_REVISION && pip3 install -e .

# Use ripe_download to get the data
RUN mkdir ripe_download && cd ripe_download && ripe_download
# Get additional data
RUN curl -O -L http://ftp.ripe.net/ripe/stats/delegated-ripencc-latest

# Importing the schema and data is done in the the database/init/init.sh script.
# This script is added to the container on startup and will be processed
# automatically ONCE! (see postgres image docs for details)
