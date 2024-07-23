#!/bin/bash

set -xeu -o pipefail

# for dev scenario (../intelmq/ is mounted to /opt/intelmq_src) this needs to be done at runtime
# with editable installations, installing a second intelmq package (for the intelmq/bots/experts/certbund* structure) does not work. So we can work around by symlinking the files
# if destination already exists, -f prevents an error
bash -c "cp -frs /opt/intelmq-certbund-contact/intelmq/bots/experts/certbund_rules /opt/intelmq_src/intelmq/bots/experts/ && cp -frs /opt/intelmq-certbund-contact/intelmq/bots/experts/certbund_contact /opt/intelmq_src/intelmq/bots/experts/"
# create necessary directories
bash -c "mkdir -p /opt/intelmq/var/{log/,lib/} && chown -R intelmq:intelmq /opt/intelmq/var /opt/intelmq/etc"

cd /opt/intelmq-api

# required for dev scenario
./scripts/intelmq-api-adduser --user admin --password secret

uvicorn intelmq_api.main:app --reload --port 81 &
apachectl -D FOREGROUND

