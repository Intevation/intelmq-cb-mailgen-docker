FROM ubuntu:20.04

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

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y apache2 libapache2-mod-wsgi-py3 cron

# Install dependencies and stuff
RUN apt-get update && apt-get install -y git \
    python3-pip python3-psycopg2 \
    python3-bs4 sudo libgpgme-dev swig sqlite3

# pip installs some packages (intelmq-api, intelmq-manager) into /usr/lib/python3.8/site-packages
# instead of /usr/local/lib/python3.10/dist-packages (which is the default location, also in python's sitepath)
# https://github.com/Intevation/intelmq-cb-mailgen-docker/issues/9
# https://github.com/pypa/pip/issues/10805
RUN ln -s /usr/local/lib/python3.8/dist-packages/ /usr/lib/python3.8/site-packages

WORKDIR /opt

# Clone intelmq
RUN git clone https://github.com/certtools/intelmq.git

WORKDIR /opt/intelmq

# add all relevant users and set access rules.
RUN useradd -d /opt/intelmq -U -s /bin/bash intelmq \
    && usermod -aG intelmq www-data \
    && sudo chown -R intelmq:intelmq /opt/intelmq

# Checkout the correct revision and install.
RUN git config --global --add safe.directory /opt/intelmq
RUN git checkout $INTELMQ_REVISION && pip3 install -e .

WORKDIR /opt

RUN git clone https://github.com/certtools/intelmq-api.git

WORKDIR /opt/intelmq-api

RUN git checkout $INTELMQ_API_REVISION

RUN pip3 install -e .

# intelmqsetup expects the files there (not compatible to editable pip installations yet)
RUN mkdir -p /opt/intelmq-api/etc/intelmq/ && cp /opt/intelmq-api/contrib/api-sudoers.conf /opt/intelmq-api/etc/intelmq/api-sudoers.conf
COPY intelmq/api-config/api-config.json /opt/intelmq-api/etc/intelmq/api-config.json

RUN python3 contrib/initesqlite.py

WORKDIR /opt

# Clone intelmq manager
RUN git clone https://github.com/certtools/intelmq-manager.git

WORKDIR /opt/intelmq-manager

RUN git checkout $INTELMQ_MANAGER_REVISION && pip3 install -e .

RUN cp -R html/* /var/www/html
RUN cp /opt/intelmq-api/contrib/api-apache.conf /etc/apache2/conf-available/api-apache.conf \
    && cp /opt/intelmq-manager/contrib/manager-apache.conf /etc/apache2/conf-available/manager-apache.conf
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
# with editable installations, installing a second intelmq package (for the intelmq/bots/experts/cerbund* structure) does not work. So we can work around by symlinking the files
RUN bash -c "cp -rs /opt/intelmq-certbund-contact/intelmq/bots/experts/certbund_rules /opt/intelmq/intelmq/bots/experts/ && cp -rs /opt/intelmq-certbund-contact/intelmq/bots/experts/certbund_contact /opt/intelmq/intelmq/bots/experts/"

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

EXPOSE 80 81

COPY intelmq/startup.sh /opt/startup.sh

RUN chmod +x /opt/startup.sh

CMD ["/opt/startup.sh"]
