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

if [ "$USE_CERTBUND" == "true" ]; then
    # clean the database for mailgen tests
    # TRUNCATE would try to acquire an exclusive lock, which is blocked by fody, so delete all entries from the tables
    docker exec --env-file=.env -e DEBUG=${DEBUG-} intelmq-database psql eventdb -c "DELETE FROM directives; DELETE FROM events;"

    # The database takes several minutes after its first start to complete initialization. Check it's availability in the beginning to avoid errors later
    set +e
    echo | nc -vw 0 localhost 1338
    if [ $? -ne 0 ]; then
        echo "Database is not yet ready. Exiting."
        exit 1
    fi
    set -e

    # Suspend mailgen. Lock will be removed after successful run of mailgen tests
    docker exec intelmq-mailgen touch /tmp/intelmqcbmail_disabled
fi

# clear deduplicator cache
docker exec intelmq-redis redis-cli -n 6 flushdb
# Run IntelMQ tests inside the container
docker exec --env-file=.env -e DEBUG=${DEBUG-} intelmq /opt/test.sh

# Prerequisites
sudo apt-get install -y wget uuid-runtime jq

# Run fody tests
./fody/test.sh

# Run webinput csv tests
./webinput-csv/test.sh

if [ "$USE_CERTBUND" == "true" ]; then
    # Run mailgen tests
    ./mailgen/test.sh
fi

echo "All tests completed successfully!"
