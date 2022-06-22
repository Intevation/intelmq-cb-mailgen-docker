#!/bin/bash

set -eu -o pipefail

if [ "$USE_CERTBUND" = true ] ; then
  cp /opt/intelmq-config/* "$1"
  crontab /etc/cron.d/mailgen
fi

if [ "$USE_CERTBUND" = true ] ; then
  # install IntelMQ configuration files
  cp /opt/intelmq-config/* $1
  chown intelmq:intelmq /opt/intelmq/etc/*
  chmod 664 /opt/intelmq/etc/*
  crontab /etc/cron.d/mailgen
fi

# make configuration upgrades if necessary
sudo -u intelmq intelmqctl upgrade-config
