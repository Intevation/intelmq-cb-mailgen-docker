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

# remove pre-installed runtime.yaml and migrate our old 2.x-style configuration to the new format
intelmq_major_version=$(sudo -u intelmq intelmqctl --version | cut -c 1)
if [[ "$intelmq_major_version" -ge 3 ]]; then
    # upgrade configuration to 3.x style
    rm /opt/intelmq/etc/BOTS
    rm /opt/intelmq/etc/runtime.yaml
    sudo -u intelmq intelmqctl upgrade-config -f -u v300_defaults_file_removal
    sudo -u intelmq intelmqctl upgrade-config -f -u v300_pipeline_file_removal
    sed -i 's/intelmq_certbund_contact\.expert/intelmq.bots.experts.certbund_contact.expert/' /opt/intelmq/etc/runtime.yaml
    sed -i 's/intelmq_certbund_contact\.ruleexpert/intelmq.bots.experts.certbund_rules.expert/' /opt/intelmq/etc/runtime.yaml
fi

# make any other necessary upgrades (harmonization)
sudo -u intelmq intelmqctl upgrade-config
