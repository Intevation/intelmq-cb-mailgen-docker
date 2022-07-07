#!/bin/bash

set -eu -o pipefail

set -o allexport
source .env
set +o allexport

set -x

# clear deduplicator cache
docker exec -ti intelmq-redis redis-cli -n 6 flushdb
# Run IntelMQ tests
docker exec --env-file=.env -ti intelmq /opt/test.sh

# Run fody tests
./fody/test.sh

echo "All tests completed successfully!"
