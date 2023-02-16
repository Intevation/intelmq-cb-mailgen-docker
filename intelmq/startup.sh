#!/bin/bash

set -xeu -o pipefail

cd /opt/intelmq-api

# required for dev scenario
./scripts/intelmq-api-adduser --user admin --password secret

hug -p 81 -m intelmq_api.serve &
apachectl -D FOREGROUND

