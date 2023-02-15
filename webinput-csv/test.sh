#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

function end_test {
    read line file <<<$(caller)
    echo "Webinput test failed at $file:$line."
}
trap end_test ERR

password=$(uuidgen)

# check if the current setup has a separate backend container (dev). Disable the shell error trapping for the calls to grep
set +e
trap - ERR
docker ps | grep intelmq-webinput-csv-backend
if [ $? -eq 1 ]; then
    # has no backend
    webinput_csv_backend_container=intelmq-webinput-csv
else
    webinput_csv_backend_container=intelmq-webinput-csv-backend
fi
trap end_test ERR
set -e

# Tests adduser script
docker exec -ti $webinput_csv_backend_container webinput-adduser --user second --password "$password"

# Check Webinput CSV Frontend
wget --no-verbose -O - http://localhost:1383/ > /dev/null

# Test Backend reachable via the /api path on the frontend port

# Test Login
token=$(wget --no-verbose -O - --post-data '{"username": "admin", "password": "secret"}' --header "Content-Type: application/json" http://localhost:1383/api/login/ 2>/dev/null | jq .login_token | tr -d '"')

# Query some data
wget --no-verbose -O - --header "Authorization: $token" http://localhost:1383/api/classification/types | grep -o ids-alert

wget --no-verbose -O - --header "Authorization: $token" http://localhost:1383/api/harmonization/event/fields | grep -o source.ip

wget --no-verbose -O - --header "Authorization: $token" http://localhost:1383/api/custom/fields | grep -o '"feed.code": "oneshot"'

# Test injecting data
docker exec -ti intelmq intelmqctl stop deduplicator-expert
docker exec -ti intelmq intelmqctl clear deduplicator-expert-queue

# Use a non ISO-formatted date to test datetime parsing
yesterday=$(date --rfc-email --date='yesterday')
wget --no-verbose -O - --header "Authorization: $token" --header "Content-Type: application/json;charset=utf-8" --post-data "{\"timezone\":\"+00:00\",\"data\":[{\"time.source\":\" $yesterday \",\"source.ip\":\"192.168.56.7\",\"source.asn\":\"65537\"}],\"custom\":{\"custom_classification.type\":\"blacklist\",\"custom_classification.identifier\":\"test\",\"custom_feed.code\":\"oneshot\",\"custom_feed.name\":\"oneshot-csv\"},\"dryrun\":true}" http://localhost:1383/api/upload | grep 'lines_invalid": 0'

# test if the data was correctly passed on to IntelMQ
result=$(docker exec -ti intelmq intelmqctl run deduplicator-expert message get | grep -Ev 'deduplicator-expert|Waiting for a message|time.observation')
expected_date=$(TZ=UTC date --iso-8601=seconds --date="$yesterday")
expected="{
 \"classification.identifier\": \"test\",
 \"classification.type\": \"test\",
 \"feed.code\": \"oneshot\",
 \"feed.name\": \"oneshot-csv\",
 \"feed.provider\": \"my-organization\",
 \"source.asn\": 65537,
 \"source.ip\": \"192.168.56.7\",
 \"time.source\": \"$expected_date\"
 }"
result=$(echo $result | tr '\r' '\n')
test "$result" = "$expected"

echo "Webinput CSV tests completed successfully!"
