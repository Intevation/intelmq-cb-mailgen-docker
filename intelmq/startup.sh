#!/bin/bash

set -xeu -o pipefail

cd /opt/intelmq-api

# required for dev scenario
./scripts/intelmq-api-adduser --user admin --password secret

uvicorn intelmq_api.main:app --reload --port 81 &
apachectl -D FOREGROUND

