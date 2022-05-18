#!/bin/bash

if [ "$USE_CERTBUND" = true ] ; then
  cp /opt/intelmq-config/* "$1"
  crontab /etc/cron.d/mailgen
fi
