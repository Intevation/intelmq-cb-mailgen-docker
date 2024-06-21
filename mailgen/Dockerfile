FROM ubuntu:22.04

ARG INTELMQ_MAILGEN_REVISION

ENV INTELMQ_MAILGEN_REVISION ${INTELMQ_MAILGEN_REVISION}

# Install git to be able to clone the mailgen repo
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git \
    python3-pip python3-psycopg2 python3-gpg \
    python3-pkg-resources

WORKDIR /opt

# Clone the Mailgen repo
RUN git clone https://github.com/intevation/intelmq-mailgen.git

WORKDIR /opt/intelmq-mailgen

RUN git checkout $INTELMQ_MAILGEN_REVISION && pip3 install -e .

# Install configuration
RUN mkdir /etc/intelmq
COPY mailgen/intelmq-mailgen.conf /etc/intelmq/intelmq-mailgen.conf
COPY mailgen/intelmq-mailgen-oneshot.conf /etc/intelmq/intelmq-mailgen-oneshot.conf
# /opt/templates and /opt/formats are provided by a docker volume mount

# Generate gpg key
COPY mailgen/generate-pgp-key.sh /opt/
RUN mkdir -p /etc/intelmq/mailgen/
RUN /opt/generate-pgp-key.sh

# Add wait-for-it.
# Used in compose environments to give the database time to start.
RUN git clone https://github.com/vishnubob/wait-for-it.git /opt/wait-for-it/
RUN cp /opt/wait-for-it/wait-for-it.sh /usr/bin

# ./mailgen/init is mapped as volume in docker-compose.yml
CMD ["bash", "/opt/init/run.sh"]
