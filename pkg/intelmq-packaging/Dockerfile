FROM intelmq-base:focal

LABEL authors="Gernot Schulz <gernot@intevation.de>,Sascha Wilde <wilde@intevation.de>"

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Focal Docker Image" \
    EMAIL=dockerfile \
    apt-install -y --purge \
      apt-transport-https
COPY nodesource.gpg.key /tmp/
COPY yarnpkg.gpg.key /tmp/
COPY update-sources.sh /tmp/
RUN /bin/bash /tmp/update-sources.sh
RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Focal Docker Image" \
    EMAIL=dockerfile \
    apt-dist-upgrade -y --purge || /bin/true
RUN DEBIAN_FRONTEND=noninteractive \
    DEBIAN_PRIORITY=critical \
    LOGBUCH_BATCHMODE=yes \
    LOGBUCH_HOST="IntelMQ Packaging Focal Docker Image" \
    EMAIL=dockerfile \
    apt-install -y --purge \
      autodep8 \
      autopkgtest \
      build-essential \
      cython \
      cython3 \
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
#      python-all \
#      python-all-dev \
#      python-nose \
#      python-setuptools \
      python-six \
      python-yaml \
      python3-all \
      python3-all-dev \
      python3-coverage \
      python3-ddt \
      python3-gpg \
      python3-jsonschema \
      python3-mimeparse \
      python3-nose \
      python3-psycopg2 \
      python3-py \
      python3-pytest \
      python3-setuptools \
      python3-stdeb \
      python3-testtools \
      python3-yaml \
      quilt \
      rsync \
 #     screen \
 #     tmux \
      tree \
      vim \
      yarn \
      xdelta

ADD adduser.sh /usr/local/bin/add-host-user
ADD make-testdeb.sh /usr/local/bin/make-testdeb
ADD Dockerfile /Dockerfile

CMD add-host-user

# vim :set et sw=4 ts=4:
