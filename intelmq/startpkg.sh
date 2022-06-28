#! /bin/bash

set -eu -o pipefail

chown -R intelmq:intelmq /var/log/intelmq/ /var/lib/intelmq
chown intelmq:intelmq /etc/intelmq/*

intelmqctl upgrade-config
intelmqctl check

apachectl -D FOREGROUND
