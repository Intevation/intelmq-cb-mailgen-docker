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

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    apache2 libapache2-mod-wsgi-py3 cron git \
    python3-pip python3-psycopg2 \
    python3-bs4 sudo libgpgme-dev sqlite3 python3-gpg

WORKDIR /opt

# Clone intelmq
RUN git clone https://github.com/certtools/intelmq.git /opt/intelmq_src
# workaround https://github.com/certtools/intelmq/issues/2559
RUN sed -i 's/"module": mod.__name__,/"module": bot.name,/' /opt/intelmq_src/intelmq/lib/utils.py

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
RUN mkdir -p /opt/intelmq-api/etc/intelmq/ && cp /opt/intelmq-api/contrib/api-sudoers.conf /opt/intelmq-api/etc/intelmq/api-sudoers.conf
COPY intelmq/api-config/api-config.json /opt/intelmq-api/etc/intelmq/api-config.json
COPY intelmq/api-config/apache.conf /opt/intelmq-api/etc/intelmq/api-apache.conf

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

CMD ["/opt/startup.sh"]
