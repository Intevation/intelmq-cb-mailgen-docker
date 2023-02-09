#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

function end_test {
    read line file <<<$(caller)
    echo "IntelMQ test failed at $file:$line."
}
trap end_test ERR

apt install -y wget python3-pytest-cov python3-cerberus python3-requests-mock postgresql-client uuid-runtime jq netcat

# Clear IntelMQ logs
log_dir=$(python3 -c "import intelmq; print(intelmq.DEFAULT_LOGGING_PATH)")
rm $log_dir/*

su - intelmq << SHT
set -xeu -o pipefail
intelmq_tests_path=\$(python3 -c 'import intelmq.tests; print(intelmq.tests.__file__[:-11])')
# pytest.ini from the repo is only available in dev-setups. So let's add the relevant options (cov, warnings) to pytest as parameters here.
test -n "${INTELMQ_SKIP_UNITTESTS-}" && INTELMQ_PIPELINE_HOST=redis pytest-3 --no-cov -p no:warnings "\$intelmq_tests_path"/
# run 'intelmqctl' once to create the log file with correct permissions, see https://github.com/certtools/intelmq/issues/2176
# debug should always return an exit code 0
intelmqctl debug
SHT


## Check IntelMQ commandline
intelmqctl check
# Check the experts and outputs
uuid=$(uuidgen)
echo "The generated UUID is $uuid"
intelmqctl run deduplicator-expert process -m "{\"extra.data\": \"$uuid\"}"
intelmqctl start --group experts
intelmqctl start --group outputs
# wait a bit
sleep 2
file_output=$(python3 -c "from ruamel.yaml import YAML; import intelmq; yaml = YAML(); runtime = yaml.load(open(intelmq.RUNTIME_CONF_FILE, 'r')); print(runtime['file-output']['parameters']['file'])")
grep "$uuid" "$file_output"

# check for errors in logs. Disable the shell error trapping for the calls to grep
set +e
trap - ERR
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
trap end_test ERR
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
wget --no-verbose -O - http://localhost/intelmq-manager/ > /dev/null
# Test API Login
token=$(wget --no-verbose -O - --post-data '{"username": "admin", "password": "secret"}' --header "Content-Type: application/json" http://localhost/intelmq/v1/api/login/ 2>/dev/null | jq .login_token | tr -d '"')
wget --no-verbose -O - --header "Authorization: $token" http://localhost/intelmq/v1/api/queues > /dev/null

echo "IntelMQ tests completed successfully!"
