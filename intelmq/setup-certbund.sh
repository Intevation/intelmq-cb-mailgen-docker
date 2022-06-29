#!/bin/bash

set -eu -o pipefail

if [ "$USE_CERTBUND" = true ] ; then
  # install IntelMQ configuration files
  cp /opt/intelmq-config/* "$1"
  if [ "$1" == "/etc/intelmq" ]; then
      sed -i 's@/opt/intelmq/var/lib/bots/file-output/@/var/lib/intelmq/bots/file-output/@' $1/runtime.yaml
  fi
else
    # use default configuration, but set
    # pipeline, cache and statistics hostname to "redis"
    python3 << EOPY
from ruamel.yaml import YAML
yaml = YAML(typ="unsafe", pure=True)
with open('$1/runtime.yaml', 'r+') as fpruntime:
    runtime = yaml.load(fpruntime)
    if 'global' not in runtime:
        runtime['global'] = {}
    runtime['global']['source_pipeline_host'] = runtime['global']['destination_pipeline_host'] = runtime['global']['redis_cache_host'] = runtime['global']['statistics_host'] = "redis"
    fpruntime.seek(0)
    for botid in runtime.keys():
        if 'parameters' in runtime[botid].keys() and 'redis_cache_host' in runtime[botid]['parameters']:
            del runtime[botid]['parameters']['redis_cache_host']
    yaml.dump(runtime, fpruntime)
EOPY
    if [ "$1" == "/opt/intelmq/etc" ]; then
        chown -R intelmq:intelmq /opt/intelmq
    fi
fi

chown -R intelmq:intelmq $1/*
chmod -R 664 $1/*{.conf,.yaml}

sudo -u intelmq intelmqctl upgrade-config
sudo -u intelmq intelmqctl -q check --no-connections

# make configuration upgrades if necessary
sudo -u intelmq intelmqctl upgrade-config
