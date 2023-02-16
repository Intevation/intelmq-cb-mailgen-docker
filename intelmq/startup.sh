#!/bin/bash

set -xeu -o pipefail

# for dev scenario (../intelmq/ is mounted to /opt/intelmq) this needs to be done at runtime
# with editable installations, installing a second intelmq package (for the intelmq/bots/experts/certbund* structure) does not work. So we can work around by symlinking the files
# if destination already exists, -u prevents an error
bash -c "cp -urs /opt/intelmq-certbund-contact/intelmq/bots/experts/certbund_rules /opt/intelmq_src/intelmq/bots/experts/ && cp -urs /opt/intelmq-certbund-contact/intelmq/bots/experts/certbund_contact /opt/intelmq_src/intelmq/bots/experts/"
# create necessary directories
bash -c "mkdir -p /opt/intelmq/var/{log/,lib/} && chown -R intelmq:intelmq /opt/intelmq/var /opt/intelmq/etc"

cd /opt/intelmq-api

# required for dev scenario
./scripts/intelmq-api-adduser --user admin --password secret

hug -p 81 -m intelmq_api.serve &
apachectl -D FOREGROUND

