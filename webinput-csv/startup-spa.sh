#! /bin/bash

set -xeu -o pipefail

echo "$PWD"

yarn 2>&1
yarn run dev 2>&1
