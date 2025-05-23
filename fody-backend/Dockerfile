FROM ubuntu:22.04

ARG REVISION
ARG INTELMQ_MAILGEN_REVISION

ENV REVISION ${REVISION}
ENV INTELMQ_MAILGEN_REVISION ${INTELMQ_MAILGEN_REVISION}

# Install dependencies and stuff
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git python3-pip python3-psycopg2 python3-dateutil libgpgme-dev sqlite3 python3-gpg

WORKDIR /opt

# Add wait-for-it.
# Used in compose environments to give the database time to start.
RUN git clone https://github.com/vishnubob/wait-for-it.git

RUN cp wait-for-it/wait-for-it.sh /usr/bin

# Clone Mailgen (used as dependency and can be executed inside the container)
RUN git clone https://github.com/Intevation/intelmq-mailgen.git
RUN cd intelmq-mailgen && git checkout $INTELMQ_MAILGEN_REVISION && pip3 install -e .

WORKDIR /opt
# Clone the fody backend
RUN git clone https://github.com/Intevation/intelmq-fody-backend.git

RUN cd intelmq-fody-backend && git checkout $REVISION

ENV FODY_SESSION_CONFIG /etc/intelmq/fody-session.conf

COPY fody-backend/conf/fody-session.conf /etc/intelmq/fody-session.conf

WORKDIR /opt

# Install dependencies
RUN pip3 install hug pyxarf

# Create config inside the container
RUN mkdir /etc/intelmq-mailgen

COPY mailgen/intelmq-mailgen.conf /etc/intelmq/intelmq-mailgen.conf

RUN mkdir -p /etc/intelmq/mailgen/templates

RUN mkdir -p /etc/intelmq/mailgen/formats

RUN cp /opt/intelmq-mailgen/templates/* /etc/intelmq/mailgen/templates

RUN cp /opt/intelmq-mailgen/example_scripts/* /etc/intelmq/mailgen/formats

RUN mkdir /opt/conf

RUN /opt/intelmq-fody-backend/fody-adduser --user admin --password secret

WORKDIR /opt/intelmq-fody-backend

# Install coreutils for development purposes.
RUN apt-get install -y coreutils

# Start the backend using hug.
# the dev compose file overwrites this CMD
CMD ["hug", "-f", "./intelmq_fody_backend/serve.py", "-p", "8002"]
