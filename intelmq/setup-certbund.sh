if [ "$USE_CERTBUND" = true ] ; then
  cp /opt/intelmq-config/* $1
  crontab /etc/cron.d/mailgen
else
  sed -i 's/127.0.0.1/intelmq-redis/g' /opt/intelmq/etc/defaults.conf
fi