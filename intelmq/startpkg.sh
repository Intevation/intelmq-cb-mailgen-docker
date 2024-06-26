#! /bin/bash

set -eu -o pipefail

chown -R intelmq:intelmq /var/log/intelmq/ /var/lib/intelmq
chown intelmq:intelmq /etc/intelmq/*

intelmqctl upgrade-config
intelmqctl check

# extracted from /lib/systemd/system/intelmq-api.service and using a local port instead of a socket, as we cannot create a proper socket in this environment
export ROOT_PATH=/intelmq
/usr/bin/gunicorn intelmq_api.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind localhost:81 &

apachectl -D FOREGROUND
