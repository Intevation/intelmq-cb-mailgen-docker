#!/bin/bash

set -xeu -o pipefail

apt install -y wget python3-pytest-cov python3-cerberus python3-requests-mock postgresql-client uuid-runtime

su - intelmq << SHT
set -xeu -o pipefail
intelmq_tests_path=\$(python3 -c 'import intelmq.tests; print(intelmq.tests.__file__[:-11])')
# ignore errors because of https://github.com/certtools/intelmq/issues/2206
# make the tests a bit shorter for now
INTELMQ_PIPELINE_HOST=redis pytest-3 "\$intelmq_tests_path"/bots/experts/abusix/ ||:
SHT


## Check IntelMQ commandline
intelmqctl check
# Check the experts and outputs
uuid=$(uuidgen)
intelmqctl run deduplicator-expert process -m "{\"extra.data\": \"$uuid\"}"
intelmqctl start --group experts
intelmqctl start --group outputs
# wait a bit
sleep 2
file_output=$(python3 -c "from ruamel.yaml import YAML; import intelmq; yaml = YAML(); runtime = yaml.load(open(intelmq.RUNTIME_CONF_FILE, 'r')); print(runtime['file-output']['parameters']['file'])")
grep "$uuid" "$file_output"

# check for errors
log_dir=$(python3 -c "import intelmq; print(intelmq.DEFAULT_LOGGING_PATH)")
set +e
grep ERROR $log_dir/*.log
if [ $? -eq 0 ]; then
    echo "ERRORs found in logs, see above" > /dev/stderr
    exit 1
fi
dumps=$(find $log_dir -name '*.dump' | wc -l)
if [ "$dumps" -ne 0 ]; then
    echo "$dumps dump files found:" > /dev/stderr
    find $log_dir -name '*.dump' > /dev/stderr
    exit 1
fi
set -e

if [ "$USE_CERTBUND" == "true" ]; then
    ## check data imported from RIPE
    now=$(date --rfc-3339=seconds | tr ' ' T)
    # 80.245.144.218 == bsi.bund.de
    intelmqctl run CERT-bund-Contact-Database-Expert process -m "{\"time.observation\": \"$now\", \"source.asn\": 35704, \"source.ip\": \"80.245.144.218\", \"feed.name\": \"Open-Portmapper\"}"
    result=$(psql postgresql://intelmq:secret@database/eventdb -c "select extra -> 'certbund' from events where \"source.ip\" = '80.245.144.218' and \"time.observation\" =  '$now';" --csv --tuples-only)
    test "\"{\"\"source_directives\"\": [{\"\"aggregate_identifier\"\": {\"\"source.asn\"\": 35704, \"\"time.observation\"\": \"\"$now\"\"}, \"\"event_data_format\"\": \"\"csv_Open-Portmapper\"\", \"\"medium\"\": \"\"email\"\", \"\"notification_format\"\": \"\"shadowserver\"\", \"\"notification_interval\"\": 86400, \"\"recipient_address\"\": \"\"lir@list.bfinv.de\"\", \"\"template_name\"\": \"\"test-template\"\"}]}\"" = "$result"
fi

# Check IntelMQ Manager with status code
wget -O - http://localhost/intelmq-manager/ > /dev/null
# Test API Login
token=$(wget -O - --post-data '{"username": "admin", "password": "secret"}' --header "Content-Type: application/json" http://localhost/intelmq/v1/api/login/ 2>/dev/null | jq .login_token | tr -d '"')
wget -O - --header "Authorization: $token" http://localhost/intelmq/v1/api/queues > /dev/null

echo "IntelMQ tests completed successfully!"
