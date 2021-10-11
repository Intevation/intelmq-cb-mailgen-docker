FROM ubuntu:20.04

RUN apt-get update && apt-get install -y git python3-pip

RUN apt-get update && apt-get install -y vim less

WORKDIR /opt

RUN git clone https://github.com/matrixise/dsmtpd.git

WORKDIR /opt/dsmtpd

RUN pip3 install .

CMD ["dsmtpd", "-p", "1025", "-i", "0.0.0.0", "-d", "../mails/incoming"]