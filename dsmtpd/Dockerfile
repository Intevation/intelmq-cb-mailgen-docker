FROM ubuntu:20.04

RUN apt-get update && apt-get install -y git python3-pip

# Install mutt to have a mail viewer on board.
RUN apt-get update && apt-get install -y mutt

# A "welcome message" lets the user know which command is used to see the mails.
RUN echo "Run 'mutt -f /opt/mails/incoming' to see the mails sent by intelmq-mailgen. View the logs at /var/log/dsmtpd.log." > /etc/motd

RUN echo "cat /etc/motd" >> /root/.bashrc

WORKDIR /opt

RUN git clone https://github.com/matrixise/dsmtpd.git

WORKDIR /opt/dsmtpd

RUN pip3 install .

COPY dsmtpd/run.sh /opt/

CMD ["/opt/run.sh"]
