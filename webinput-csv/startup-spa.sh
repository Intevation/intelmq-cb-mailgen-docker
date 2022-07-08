#! /bin/bash

set -xeu -o pipefail

echo "$PWD"

yarn
yarn serve
