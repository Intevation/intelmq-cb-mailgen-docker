FROM ubuntu:jammy

LABEL authors="Gernot Schulz <gernot@intevation.de>,Sascha Wilde <wilde@intevation.de>"

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && apt-get install -y vim-tiny

ADD https://hg.intevation.de/adminton/raw-file/tip/logbuch-tools/logbuch-installer /root/
RUN LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Jammy Docker Image" \
    EMAIL=dockerfile \
    bash /root/logbuch-installer

RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Jammy Docker Image" \
    EMAIL=dockerfile \
    apt-install -y --purge \
    wget \
    git \
    locales \
    python3 \
    sudo \
    apt-transport-https \
    gnupg

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update

COPY update-sources.sh /tmp/
RUN /bin/bash /tmp/update-sources.sh
RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Jammy Docker Image" \
    EMAIL=dockerfile \
    apt-get update
RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Jammy Docker Image" \
    EMAIL=dockerfile \
    apt-dist-upgrade -y --purge || /bin/true
RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Jammy Docker Image" \
    EMAIL=dockerfile \
    apt-install -y --purge \
      autodep8 \
      autopkgtest \
      build-essential \
      debhelper \
      devscripts \
      dh-exec \
      dh-python \
      equivs \
      libxdelta2 \
      libxml-parser-perl \
      libxml-xpath-perl \
      madison-lite \
      nodejs \
      pbzip2 \
      pristine-tar \
      python-six \
      python3-all-dev \
      python3-coverage \
      python3-ddt \
      python3-gpg \
      python3-jsonschema \
      python3-mimeparse \
      python3-psycopg2 \
      python3-py \
      python3-pytest \
      python3-setuptools \
      python3-stdeb \
      python3-testtools \
      quilt \
      vim \
      yarn \
      xdelta

ADD adduser.sh /usr/local/bin/add-host-user
ADD make-testdeb.sh /usr/local/bin/make-testdeb
ADD Dockerfile /Dockerfile

CMD add-host-user

# vim :set et sw=4 ts=4:
