FROM ubuntu:focal

LABEL authors="Gernot Schulz <gernot@intevation.de>,Sascha Wilde <wilde@intevation.de>"

RUN apt-get update && apt-get install -y vim-tiny

ADD https://hg.intevation.de/adminton/raw-file/tip/logbuch-tools/logbuch-installer /root/
RUN LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Base Docker Image" \
    EMAIL=dockerfile \
    bash /root/logbuch-installer

RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Base Docker Image" \
    EMAIL=dockerfile \
    apt-install -y --purge \
#	apache2 \
	build-essential \
	curl \
	git \
#	libapache2-mod-php \
	man \
	php \
	python3 \
	python3-pip \
#	redis-server \
	sudo \
#	tmux \
	vim
