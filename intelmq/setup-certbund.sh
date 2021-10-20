if [ "$USE_CERTBUND" = true ] ; then
  cp /opt/intelmq-config/* /etc/intelmq/
  crontab /etc/cron.d/mailgen
fi