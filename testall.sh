#!/bin/bash

source .env

# clear deduplicator cache
docker exec -ti intelmq-redis redis-cli -n 6 flushdb
# Run IntelMQ tests
docker exec --env-file=.env -ti intelmq /opt/test.sh

# Run fody tests
./fody/test.sh

echo "All tests completed successfully!"
