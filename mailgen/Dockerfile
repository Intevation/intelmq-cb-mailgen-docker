FROM ubuntu:20.04

ARG INTELMQ_MAILGEN_REVISION

ENV INTELMQ_MAILGEN_REVISION ${INTELMQ_MAILGEN_REVISION}

# Install git to be able to clone the mailgen repo
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git python3-pip python3-psycopg2 python3-gpg

WORKDIR /opt

# Clone the Mailgen repo
RUN git clone https://github.com/intevation/intelmq-mailgen.git

WORKDIR /opt/intelmq-mailgen

RUN git checkout $INTELMQ_MAILGEN_REVISION && pip3 install -e .

# Install configuration
RUN mkdir /etc/intelmq
COPY mailgen/intelmq-mailgen.conf /etc/intelmq/intelmq-mailgen.conf
RUN mkdir -p /etc/intelmq/mailgen/templates
RUN mkdir -p /etc/intelmq/mailgen/formats
RUN cp /opt/intelmq-mailgen/templates/* /etc/intelmq/mailgen/templates
RUN cp /opt/intelmq-mailgen/example_scripts/* /etc/intelmq/mailgen/formats

# Generate gpg key
COPY generate-pgp-key.sh /opt/
RUN /opt/generate-pgp-key.sh

# Add wait-for-it.
# Used in compose environments to give the database time to start.
RUN git clone https://github.com/vishnubob/wait-for-it.git

RUN cp wait-for-it/wait-for-it.sh /usr/bin

CMD ["bash", "/opt/init/run.sh"]
