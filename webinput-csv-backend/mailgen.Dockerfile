## intelmq

FROM ubuntu:22.04

ARG INTELMQ_REVISION
ARG INTELMQ_API_REVISION
ARG INTELMQ_MANAGER_REVISION
ARG INTELMQ_CERTBUND_CONTACT_REVISION
ARG INTELMQ_MAILGEN_REVISION

ENV INTELMQ_REVISION ${INTELMQ_REVISION}
ENV INTELMQ_API_REVISION ${INTELMQ_API_REVISION}
ENV INTELMQ_MANAGER_REVISION ${INTELMQ_MANAGER_REVISION}
ENV INTELMQ_CERTBUND_CONTACT_REVISION ${INTELMQ_CERTBUND_CONTACT_REVISION}
ENV INTELMQ_MAILGEN_REVISION ${INTELMQ_MAILGEN_REVISION}

COPY common/setup-apt.sh /opt/
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    apache2 libapache2-mod-wsgi-py3 cron git \
    python3-pip python3-psycopg2 \
    python3-bs4 sudo libgpgme-dev sqlite3

WORKDIR /opt

# Clone intelmq
RUN git clone https://github.com/certtools/intelmq.git /opt/intelmq_src

WORKDIR /opt/intelmq_src

# add all relevant users and set access rules.
RUN mkdir /opt/intelmq
RUN useradd -d /opt/intelmq -U -s /bin/bash intelmq \
    && usermod -aG intelmq www-data \
    && sudo chown -R intelmq:intelmq /opt/intelmq

# Checkout the correct revision and install.
RUN git config --global --add safe.directory /opt/intelmq_src
RUN git checkout $INTELMQ_REVISION && pip3 install -e .

WORKDIR /opt

RUN git clone https://github.com/certtools/intelmq-api.git

WORKDIR /opt/intelmq-api

RUN git checkout $INTELMQ_API_REVISION

RUN pip3 install -e .

# intelmqsetup expects the files there (not compatible to editable pip installations yet)
RUN mkdir -p /opt/intelmq-api/etc/intelmq/ && cp /opt/intelmq-api/contrib/api-sudoers.conf /opt/intelmq-api/etc/intelmq/api-sudoers.conf && cp /opt/intelmq-api/contrib/api-apache.conf /opt/intelmq-api/etc/intelmq/api-apache.conf
COPY intelmq/api-config/api-config.json /opt/intelmq-api/etc/intelmq/api-config.json

RUN python3 contrib/initesqlite.py

WORKDIR /opt

# Clone intelmq manager
RUN git clone https://github.com/certtools/intelmq-manager.git
# intelmqsetup expects the files there (not compatible to editable pip installations yet)
RUN mkdir -p /opt/intelmq-manager/etc/intelmq/ && cp /opt/intelmq-manager/contrib/manager-apache.conf /opt/intelmq-manager/etc/intelmq/manager-apache.conf

WORKDIR /opt/intelmq-manager

RUN git checkout $INTELMQ_MANAGER_REVISION && pip3 install -e .
# HTML is built and placed at expected destination by intelmqsetup with IntelMQ > 3.0.2.

COPY intelmq/apache-config/intelmq.conf /etc/apache2/sites-available/000-default.conf

# Run intelmqsetup to get a complete environment
RUN intelmqsetup

RUN a2enmod proxy proxy_http

WORKDIR /opt

# Clone mailgen and install as a dependency for certbund-contact
RUN git clone https://github.com/Intevation/intelmq-mailgen.git

WORKDIR /opt/intelmq-mailgen

RUN git checkout $INTELMQ_MAILGEN_REVISION && pip3 install -e .

WORKDIR /opt

# Clone and Install certbund-contact
RUN git clone https://github.com/Intevation/intelmq-certbund-contact.git

WORKDIR /opt/intelmq-certbund-contact

RUN git checkout $INTELMQ_CERTBUND_CONTACT_REVISION
RUN pip3 install -e .

RUN intelmq-api-adduser --user admin --password secret

# Use the build argument as switch to configure the cert-bund bots and mailgen
# Override the var in the .env file.
ARG USE_CERTBUND=false

WORKDIR /opt

# Add the configs
ADD intelmq/intelmq-config /opt/intelmq-config
ADD intelmq/rules /opt/rules

# Execute the setup script using the switch from above.
COPY intelmq/setup-certbund.sh /opt/setup-certbund.sh
RUN chmod +x setup-certbund.sh
RUN ./setup-certbund.sh /opt/intelmq/etc

# Add test script
COPY intelmq/test.sh /opt/

EXPOSE 80 81

COPY intelmq/startup.sh /opt/startup.sh

RUN chmod +x /opt/startup.sh

## mailgen

ARG INTELMQ_MAILGEN_REVISION

ENV INTELMQ_MAILGEN_REVISION ${INTELMQ_MAILGEN_REVISION}

# Install git to be able to clone the mailgen repo
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git \
    python3-pip python3-psycopg2 python3-gpg \
    python3-pkg-resources

WORKDIR /opt

# Clone the Mailgen repo
# already exists
#RUN git clone https://github.com/intevation/intelmq-mailgen.git

WORKDIR /opt/intelmq-mailgen

RUN git checkout $INTELMQ_MAILGEN_REVISION && pip3 install -e .

# Install configuration
RUN mkdir -p /etc/intelmq
COPY mailgen/intelmq-mailgen.conf /etc/intelmq/intelmq-mailgen.conf
COPY mailgen/intelmq-mailgen-webinput.conf /etc/intelmq/intelmq-mailgen-webinput.conf
# /opt/templates and /opt/formats are provided by a docker volume mount

# Generate gpg key
COPY mailgen/generate-pgp-key.sh /opt/
RUN mkdir -p /etc/intelmq/mailgen/
RUN /opt/generate-pgp-key.sh

# Add wait-for-it.
# Used in compose environments to give the database time to start.
RUN git clone https://github.com/vishnubob/wait-for-it.git /opt/wait-for-it/
RUN cp /opt/wait-for-it/wait-for-it.sh /usr/bin

RUN touch /tmp/intelmqcbmail_disabled

## intelmq-webinput-csv-backend


WORKDIR /opt

RUN git clone https://github.com/Intevation/intelmq-webinput-csv.git

RUN cd intelmq-webinput-csv && git checkout $SOURCE_WEBINPUT_CSV_REVISION

ENV WEBINPUT_CSV_SESSION_CONFIG /etc/intelmq/webinput-session.conf

COPY webinput-csv-backend/webinput-session.conf /etc/intelmq/webinput-session.conf

ENV WEBINPUT_CSV_CONFIG /etc/intelmq/webinput_csv.conf

COPY webinput-csv-backend/webinput_csv.conf /etc/intelmq/webinput_csv.conf

RUN mkdir -p /opt/intelmq/etc

COPY intelmq/intelmq-config/harmonization.conf /opt/intelmq/etc/harmonization.conf

WORKDIR /opt/intelmq-webinput-csv

# Install webinput
RUN /opt/setup-apt.sh intelmq
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y python3-hug
RUN pip3 install -e .

WORKDIR /opt

RUN /opt/intelmq-webinput-csv/webinput-adduser --user admin --password secret

WORKDIR /opt/intelmq-webinput-csv

# Install coreutils for development purposes.
RUN apt-get install -y coreutils

## webinput csv

RUN /opt/setup-apt.sh node

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y nodejs git

RUN npm install --global yarn

COPY webinput-csv/init /opt/webinput-csv-init

EXPOSE 8080

CMD ["/opt/init/init.sh"]
