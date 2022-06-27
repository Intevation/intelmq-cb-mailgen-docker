#!/bin/bash

set -eu -o pipefail

while /bin/true ;
    do intelmqcbmail -a
    sleep 300
done
