#!/bin/bash

set -eu -o pipefail

wait-for-it.sh database:5432 -t 0 -s

# only in non-pkg scenarios
if [ -d /opt/intelmq-mailgen/ ]; then
    cd /opt/intelmq-mailgen/
    # for dev scenario:
    # ensure /opt/intelmq-mailgen/intelmqmail.egg-info/ exists, so that the package can be loaded
    pip3 install -e .
else
    apt install python3-pkg-resources
fi

while /bin/true ; do
    if [[ -f /tmp/intelmqcbmail_disabled ]]; then
        echo "intelmqcbmail run disabled by '/tmp/intelmqcbmail_disabled'."
    else
        intelmqcbmail -a
    fi
    sleep 300
done
