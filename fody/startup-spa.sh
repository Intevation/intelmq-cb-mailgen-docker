#! /bin/bash

set -xeu -o pipefail

echo "$PWD"

# in scenarios source and dev the backend can be reached in the docker network via this address-port-combination
# in source scenario this could be done at build time, but not in dev scenario
# as the volume overlay is mapped at runtime
# this file is not executed in the pkg and full-pkg scenarios
sed -i "s#target: .*#target: 'http://intelmq-fody-backend:8002',#" config/index.js

yarn 2>&1
yarn run dev 2>&1
