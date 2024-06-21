FROM ubuntu:22.04

ARG REVISION
ARG INTELMQ_PYPI_VERSION

ENV REVISION ${REVISION}
ENV INTELMQ_PYPI_VERSION ${INTELMQ_PYPI_VERSION}

# Install dependencies
COPY common/setup-apt.sh /opt/
RUN /opt/setup-apt.sh intelmq
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git python3-pip python3-psycopg2 sqlite3 python3-hug
RUN pip3 install intelmq==$INTELMQ_PYPI_VERSION

WORKDIR /opt

RUN git clone https://github.com/Intevation/intelmq-webinput-csv.git

RUN cd intelmq-webinput-csv && git checkout $REVISION

ENV WEBINPUT_CSV_SESSION_CONFIG /etc/intelmq/webinput-session.conf

COPY webinput-csv-backend/webinput-session.conf /etc/intelmq/webinput-session.conf

ENV WEBINPUT_CSV_CONFIG /etc/intelmq/webinput_csv.conf

COPY webinput-csv-backend/webinput_csv.conf /etc/intelmq/webinput_csv.conf

RUN mkdir -p /opt/intelmq/etc

COPY intelmq/intelmq-config/harmonization.conf /opt/intelmq/etc/harmonization.conf

WORKDIR /opt/intelmq-webinput-csv

# Install webinput
RUN pip3 install .

WORKDIR /opt

RUN /opt/intelmq-webinput-csv/webinput-adduser --user admin --password secret

WORKDIR /opt/intelmq-webinput-csv

# Install coreutils for development purposes.
RUN apt-get install -y coreutils

# Start the backend using hug. 
CMD ["hug", "-f", "./intelmq_webinput_csv/serve.py", "-p", "8002"]
