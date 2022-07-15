#!/bin/bash

set -eu -o pipefail

wait-for-it.sh database:5432 -t 0 -s

apt install python3-pkg-resources

while /bin/true ;
    do intelmqcbmail -a
    sleep 300
done
