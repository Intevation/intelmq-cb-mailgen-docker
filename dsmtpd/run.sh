#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

echo "Starting dsmtpd: Using /opt/mails/incoming as Maildir and logging to /var/log/dsmtpd.log"

dsmtpd -p 1025 -i 0.0.0.0 -d /opt/mails/incoming 2>&1 | tee -a /var/log/dsmtpd.log
