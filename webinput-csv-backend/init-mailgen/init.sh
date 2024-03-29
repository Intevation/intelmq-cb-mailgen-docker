#!/bin/bash

set -eu -o pipefail

# intelmq/manager
/opt/startup.sh &

# mailgen
# ./mailgen/init is mapped as volume in docker-compose.yml
/opt/mailgen-init/run.sh &

# webinput backend
# Start the backend using hug.
hug -f /opt/intelmq-webinput-csv/intelmq_webinput_csv/serve.py -p 8002 2>&1 | tee -a /var/log/webinput_csv_backend.log &

# webinput client
cd /opt/intelmq-webinput-csv/client/
/opt/webinput-csv-init/startup-dev.sh | tee -a /var/log/webinput_csv.log
