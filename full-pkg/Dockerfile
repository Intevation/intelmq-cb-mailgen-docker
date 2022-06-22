FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND="noninteractive"  apt-get install -y wget gnupg apache2 locales

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


# Get intevations apt key
RUN wget -O - https://ssl.intevation.de/Intevation-Distribution-Key-2021.asc | apt-key add -

RUN echo "deb https://apt.intevation.de focal intelmq-testing" >> /etc/apt/sources.list

# Get sebixs  apt-key
RUN wget -nv \
    https://download.opensuse.org/repositories/home:sebix:intelmq/xUbuntu_20.04/Release.key \
    -O - | apt-key add -

# Add sebix repo to sources
RUN echo "deb http://download.opensuse.org/repositories/home:/sebix:/intelmq/xUbuntu_20.04/ /" >> /etc/apt/sources.list

# Install intelmq and intelmq-certbund-contact
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y intelmq-manager=2.3.1-2 intelmq=2.3.3-1 intelmq-api=2.3.1-1 intelmq-certbund-contact intelmq-fody intelmq-fody-backend intelmq-mailgen intelmq-webinput-csv-client intelmq-webinput-csv-backend python3-bs4

# Add a new api user
RUN intelmq-api-adduser --user admin --password secret
RUN fody-adduser --user admin --password secret
RUN webinput-adduser --user admin --password secret

# Adjust config to use the intelmq-redis host.
RUN jq '.destination_pipeline_host="intelmq-redis" | .source_pipeline_host="intelmq-redis" | .statistics_host="intelmq-redis"' /etc/intelmq/defaults.conf > /etc/intelmq/defaults.redis.conf

RUN jq '(..|objects|select(has("redis_cache_host"))).redis_cache_host |= "intelmq-redis"' /etc/intelmq/runtime.conf > /etc/intelmq/runtime.redis.conf

# Keep the original configs but use the edited ones.
RUN mv /etc/intelmq/defaults.conf /etc/intelmq/defaults.conf.orig

RUN mv /etc/intelmq/defaults.redis.conf /etc/intelmq/defaults.conf
RUN chown intelmq:intelmq /etc/intelmq/defaults.conf
RUN chmod g+w /etc/intelmq/defaults.conf

RUN mv /etc/intelmq/runtime.conf /etc/intelmq/runtime.conf.orig

RUN mv /etc/intelmq/runtime.redis.conf /etc/intelmq/runtime.conf
RUN chown intelmq:intelmq /etc/intelmq/runtime.conf
RUN chmod g+w /etc/intelmq/runtime.conf

COPY fody-backend/conf/contactdb.pkg.conf /etc/intelmq/contactdb-serve.conf
COPY fody-backend/conf/eventdb.pkg.conf /etc/intelmq/eventdb-serve.conf
COPY fody-backend/conf/ticketdb.pkg.conf /etc/intelmq/tickets-serve.conf
COPY fody-backend/intelmq-mailgen.conf /etc/intelmq/intelmq-mailgen.conf
COPY webinput-csv-backend/webinput_csv.conf /etc/intelmq/webinput_csv.conf

# Use the build argument as switch to configure the cert-bund bots and mailgen
# Override the var in the .env file.
ARG USE_CERTBUND=false

WORKDIR /opt

# Add the configs
ADD intelmq/intelmq-config /opt/intelmq-config
ADD intelmq/rules /opt/rules
ADD intelmq/templates /opt/templates
COPY intelmq/intelmq-config/cron /etc/cron.d/mailgen

# Execute the setup script using the switch from above.
COPY intelmq/setup-certbund.sh /opt/setup-certbund.sh
RUN chmod +x setup-certbund.sh
RUN ./setup-certbund.sh /etc/intelmq

RUN sed -i -e "/Listen/s/localhost:8666/127.0.0.1:8666/g" /etc/apache2/sites-available/001-fody.conf
# Expose the ports used.

# Use the start script to run cron and apache.
COPY intelmq/startpkg.sh /opt/startpkg.sh
RUN chmod +x startpkg.sh

EXPOSE 80 8000

#Start the apache
CMD ["./startpkg.sh"]
