FROM ubuntu:20.04

ARG INTELMQ_REVISION
ARG INTELMQ_API_REVISION
ARG INTELMQ_MANAGER_REVISION

ENV INTELMQ_REVISION ${INTELMQ_REVISION}
ENV INTELMQ_API_REVISION ${INTELMQ_API_REVISION}
ENV INTELMQ_MANAGER_REVISION ${INTELMQ_MANAGER_REVISION}

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y apache2 libapache2-mod-wsgi-py3 cron

# Install dependencies and stuff
RUN apt-get update && apt-get install -y jq git \
    python3-pip python3-psycopg2 \
    python3-bs4 sudo libgpgme-dev swig sqlite3

WORKDIR /opt

# Clone intelmq
RUN git clone https://github.com/certtools/intelmq.git

WORKDIR /opt/intelmq

# add all relevant users and set access rules.
RUN useradd -d /opt/intelmq -U -s /bin/bash intelmq \
    && adduser intelmq sudo \
    && adduser www-data sudo \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && sudo chown -R intelmq:intelmq /opt/intelmq

# Checkout the intelmq master as the stable branch
# and install.
RUN git checkout $INTELMQ_REVISION && pip3 install -e .

# Run intelmqsetup to get a complete enviroment
RUN intelmqsetup

WORKDIR /opt

RUN git clone https://github.com/certtools/intelmq-api.git

WORKDIR /opt/intelmq-api

RUN git checkout $INTELMQ_API_REVISION

RUN pip3 install -e .

RUN python3 contrib/initesqlite.py

COPY intelmq/api-config/api-config.json /usr/local/lib/python3.8/dist-packages/etc/intelmq/api-config.json
ENV INTELMQ_API_CONFIG /usr/local/lib/python3.8/dist-packages/etc/intelmq/api-config.json

WORKDIR /opt

# Clone intelmq manager
RUN git clone https://github.com/certtools/intelmq-manager.git

WORKDIR /opt/intelmq-manager

# Checkout the intelmq master as the stable branch
RUN git checkout $INTELMQ_MANAGER_REVISION

RUN pip3 install -e .

RUN cp -R html/* /var/www/html

COPY intelmq/apache-config/intelmq.conf /etc/apache2/sites-available/000-default.conf

RUN a2enmod proxy proxy_http

WORKDIR /opt

# Copy to webserver location

WORKDIR /opt/intelmq/etc

# Add manager configs to make the UI work
RUN mkdir manager

RUN touch /opt/intelmq/etc/manager/positions.conf

WORKDIR /opt

# Clone mailgen and install as a dependency for certbund-contact
RUN git clone https://github.com/Intevation/intelmq-mailgen.git

WORKDIR /opt/intelmq-mailgen

RUN pip3 install -e .

WORKDIR /opt

# Clone and Install certbund-contact to add the BOTS to intelmq
RUN git clone https://github.com/Intevation/intelmq-certbund-contact.git

WORKDIR /opt/intelmq-certbund-contact

# Patch example rules to fix imports.
COPY intelmq/import.patch .

RUN patch -p 1 -i import.patch

RUN pip3 install -e .

# Adjust ownership for configs
#RUN chgrp www-data /opt/intelmq/etc/*.conf /opt/intelmq/etc/manager/positions.conf

#RUN chmod g+w /opt/intelmq/etc/*.conf /opt/intelmq/etc/manager/positions.conf

RUN sqlite3 /var/lib/dbconfig-common/sqlite3/intelmq-api/intelmqapi

RUN intelmq-api-adduser --user admin --password secret

# Use the build argument as switch to configure the cert-bund bots and mailgen
# Override the var in the .env file.
ARG USE_CERTBUND=false

WORKDIR /opt

# Add the configs
ADD intelmq/intelmq-config /opt/intelmq-config
RUN sed -i '/logging_path/s/var\/log\/intelmq/opt\/intelmq\/var\/log/g' /opt/intelmq-config/defaults.conf
RUN sed -i '/"file":/s/var\/lib\/intelmq/opt\/intelmq\/var\/lib/g' /opt/intelmq-config/runtime.conf
RUN sed -i 's/127.0.0.1/intelmq-redis/g' /opt/intelmq/etc/defaults.conf
ADD intelmq/rules /opt/rules
ADD intelmq/templates /opt/templates
COPY intelmq/intelmq-config/cron /etc/cron.d/mailgen

# Execute the setup script using the switch from above.
COPY intelmq/setup-certbund.sh /opt/setup-certbund.sh
RUN chmod +x setup-certbund.sh
RUN ./setup-certbund.sh /opt/intelmq/etc

EXPOSE 80 81

COPY intelmq/startup.sh /opt/startup.sh

RUN chmod +x /opt/startup.sh

CMD ["/opt/startup.sh"]
