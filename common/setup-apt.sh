#!/bin/bash

which wget > /dev/null 2>&1
dependencies_installed=$?

set -xeu -o pipefail

if [ "$dependencies_installed" -ne 0 ]; then
    # install requirements for downloading and adding the APT key
    apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y wget apt-transport-https gnupg
fi

if [ "$1" == "intelmq" ]; then
    # Add sebix repo to sources
    echo "deb http://download.opensuse.org/repositories/home:/sebix:/intelmq/xUbuntu_20.04/ /" >> /etc/apt/sources.list.d/intelmq.list
    wget -O - https://download.opensuse.org/repositories/home:sebix:intelmq/xUbuntu_20.04/Release.key | apt-key add -
elif [ "$1" == "intevation" ]; then
    # Add Intevation apt repo
    echo "deb https://apt.intevation.de focal intelmq-testing" > /etc/apt/sources.list.d/intevation.list
    wget -O - https://ssl.intevation.de/Intevation-Distribution-Key-2021.asc | apt-key add -
elif [ "$1" == "node" ]; then
    echo "deb https://deb.nodesource.com/node_14.x focal main" >/etc/apt/sources.list.d/nodesource.list
    wget -O -  https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
elif [ "$1" == "local" ]; then
    DEBIAN_FRONTEND="noninteractive" apt-get install -y dpkg-dev
    # Add local file system repository and favor it over other sources
    echo deb [trusted=yes] file:/opt/packages ./ > /etc/apt/sources.list.d/local.list
    echo "Package: *\nPin: origin \"\"\nPin-Priority: 999" > /etc/apt/preferences.d/local-repository
    # Create a Packages file
    cd /opt/packages
    dpkg-scanpackages -m . > Packages
fi
