FROM ubuntu:20.04

# Install git to be able to clone the mailgen repo
RUN apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y git

WORKDIR /opt

# Clone the Mailgen repo
RUN git clone https://github.com/intevation/intelmq-mailgen.git

WORKDIR /opt/intelmq-mailgen

# Checkout a version before pg_trgm was introduced since this creates errors
# while setting up the database.
RUN git checkout 546ef367b43e5f6479c28d99efc6d8cf2827cc25
