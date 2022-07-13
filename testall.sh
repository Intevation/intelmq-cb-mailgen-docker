#!/bin/bash

set -eu -o pipefail
test -n "${DEBUG-}" && set -x

set -o allexport
source .env
set +o allexport

function end_test {
    read line file <<<$(caller)
    echo "Test failed at $file:$line."
}
trap end_test ERR

# clear deduplicator cache
docker exec -ti intelmq-redis redis-cli -n 6 flushdb
# Run IntelMQ tests
docker exec --env-file=.env -e DEBUG=${DEBUG-} -ti intelmq /opt/test.sh

# Prerequisites
sudo apt install -y wget uuid-runtime jq

# Run fody tests
./fody/test.sh

# Run webinput csv tests
./webinput-csv/test.sh

echo "All tests completed successfully!"
