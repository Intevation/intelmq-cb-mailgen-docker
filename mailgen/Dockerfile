FROM ubuntu:20.04

ARG INTELMQ_MAILGEN_REVISION

ENV INTELMQ_MAILGEN_REVISION ${INTELMQ_MAILGEN_REVISION}

# Install git to be able to clone the mailgen repo
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git python3-pip python3-psycopg2

WORKDIR /opt

# Clone the Mailgen repo
RUN git clone https://github.com/intevation/intelmq-mailgen.git

WORKDIR /opt/intelmq-mailgen

RUN git checkout $INTELMQ_MAILGEN_REVISION && pip3 install -e .
