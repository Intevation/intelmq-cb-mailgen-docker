FROM postgres:14

ARG INTELMQ_CERTBUND_CONTACT_REVISION
ARG INTELMQ_REVISION

ENV INTELMQ_CERTBUND_CONTACT_REVISION ${INTELMQ_CERTBUND_CONTACT_REVISION}
ENV INTELMQ_REVISION ${INTELMQ_REVISION}

# Install python3 deps and stuff
RUN apt-get update && apt-get install -y git curl python3-pip python3-psycopg2

WORKDIR /opt

# we only need a minimal IntelMQ installation here, i.e. just the library. We can skip the setup
RUN git clone https://github.com/certtools/intelmq.git
WORKDIR /opt/intelmq
RUN git config --global --add safe.directory /opt/intelmq
RUN git checkout $INTELMQ_REVISION && pip3 install -e .

WORKDIR /opt

# Clone the certbund-contact repo to have the tools for filling the database.
RUN git clone https://github.com/Intevation/intelmq-certbund-contact.git

# Install on the repo
RUN cd intelmq-certbund-contact && git checkout $INTELMQ_CERTBUND_CONTACT_REVISION && pip3 install -e .

# Use ripe_download to get the data
RUN intelmq-certbund-contact/bin/ripe_download

# Get additional data
RUN curl -O -L http://ftp.ripe.net/ripe/stats/delegated-ripencc-latest

# Importing the schema and data is done in the the contactdb/init.sh script.
# This script is added to the container on startup and will be processed
# automatically ONCE! (see postgres image docs for details)
