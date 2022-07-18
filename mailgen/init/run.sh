#!/bin/bash

set -eu -o pipefail

wait-for-it.sh database:5432 -t 0 -s

apt install python3-pkg-resources

while /bin/true ; do
    if [[ -f /tmp/intelmqcbmail_disabled ]]; then
        echo "intelmqcbmail run disabled by '/tmp/intelmqcbmail_disabled'."
    else
        intelmqcbmail -a
    fi
    sleep 300
done
