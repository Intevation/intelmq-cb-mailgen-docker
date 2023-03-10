FROM ubuntu:20.04

ARG REVISION

ENV REVISION ${REVISION}

COPY common/setup-apt.sh /opt/
RUN /opt/setup-apt.sh node

RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y nodejs git

RUN npm install --global yarn

COPY webinput-csv/init /opt/init

WORKDIR /opt/src/

RUN git clone https://github.com/Intevation/intelmq-webinput-csv.git

WORKDIR /opt/src/intelmq-webinput-csv/client

RUN git checkout $REVISION

EXPOSE 8080

CMD ["/opt/init/startup-spa.sh"]

