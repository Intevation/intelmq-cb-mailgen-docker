#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

function end_test {
    read line file <<<$(caller)
    echo "Webinput test failed at $file:$line. Run with DEBUG=1 to get more details of the failure."
}
trap end_test ERR

password=$(uuidgen)

# check if the current setup has a separate backend container (dev).
# The packaged webinput-csv serves the software under /intelmq-webinput, whereas the dev version serves it under /
# Disable the shell error trapping for the calls to grep
set +e
trap - ERR
docker ps | grep intelmq-webinput-csv-backend
if [ $? -eq 1 ]; then
    # has no backend
    webinput_csv_backend_container=intelmq-webinput-csv
    API="http://localhost:1383/intelmq-webinput"
else
    webinput_csv_backend_container=intelmq-webinput-csv-backend
    API="http://localhost:1383"
fi
trap end_test ERR
set -e

# Tests adduser script
docker exec $webinput_csv_backend_container webinput-adduser --user second --password "$password"

# Check Webinput CSV Frontend
wget --no-verbose -O - $API/ > /dev/null

# Test Backend reachable via the /api path on the frontend port

# Test Login
token=$(wget --no-verbose -O - --post-data '{"username": "admin", "password": "secret"}' --header "Content-Type: application/json" $API/api/login/ 2>/dev/null | jq .login_token | tr -d '"')

# Query some data
wget --no-verbose -O - --header "Authorization: $token" $API/api/classification/types | grep -o ids-alert

wget --no-verbose -O - --header "Authorization: $token" $API/api/harmonization/event/fields | grep -o source.ip

wget --no-verbose -O - --header "Authorization: $token" $API/api/custom/fields | grep -o '"feed.code": "oneshot"'

# Test injecting data
docker exec intelmq intelmqctl stop taxonomy-expert-oneshot
docker exec intelmq intelmqctl clear taxonomy-expert-oneshot-queue
docker exec intelmq intelmqctl clear taxonomy-expert-oneshot-queue-internal

# Use a non ISO-formatted date to test datetime parsing
yesterday=$(date --rfc-email --date='yesterday')
wget --no-verbose -O - --header "Authorization: $token" --header "Content-Type: application/json;charset=utf-8" --post-data "{\"timezone\":\"+00:00\",\"data\":[{\"time.source\":\" $yesterday \",\"source.ip\":\"192.168.56.7\",\"source.asn\":\"65537\",\"source.as_name\":\"Example AS\"}],\"custom\":{\"custom_classification.type\":\"blacklist\",\"custom_classification.identifier\":\"test\",\"custom_feed.code\":\"oneshot\",\"custom_feed.name\":\"oneshot-csv\"},\"dryrun\":true, \"username\": \"second\", \"password\": \"$password\"}" $API/api/upload | grep -F 'lines_invalid": 0, "errors": {}'

# test if the data was correctly passed on to IntelMQ
result=$(docker exec intelmq intelmqctl run taxonomy-expert-oneshot message get | grep -Ev 'taxonomy-expert-oneshot|Waiting for a message|time.observation')
expected_date=$(TZ=UTC date --iso-8601=seconds --date="$yesterday")
expected="{
 \"classification.identifier\": \"test\",
 \"classification.type\": \"test\",
 \"feed.code\": \"oneshot\",
 \"feed.name\": \"oneshot-csv\",
 \"feed.provider\": \"my-organization\",
 \"source.as_name\": \"Example AS\",
 \"source.asn\": 65537,
 \"source.ip\": \"192.168.56.7\",
 \"time.source\": \"$expected_date\"
 }"
result=$(echo $result | tr '\r' '\n')
test "$result" = "$expected"

echo "Webinput CSV tests completed successfully!"
