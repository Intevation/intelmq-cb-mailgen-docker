#!/bin/bash

# Parameters:
# repository: one of "intelmq", "intevation", "node", "local"
# codename, optional: Use the given version codename instead of the detected one. Useful to use packages from another distro version, if packages for the actual version are not available

which wget > /dev/null 2>&1
dependencies_installed=$?

# defines $ID, $VERSION_ID, $VERSION_CODENAME
. /etc/os-release
if [ -n "$2" ]; then
    VERSION_CODENAME=$2
fi

set -xeu -o pipefail

if [ "$dependencies_installed" -ne 0 ]; then
    # install requirements for downloading and adding the APT key
    apt-get update && DEBIAN_FRONTEND="noninteractive" apt-get install -y wget apt-transport-https gnupg
fi

if [ "$ID" == "debian" ]; then
    os_repo_name="Debian"
elif [ "$ID" == "ubuntu" ]; then
    os_repo_name="xUbuntu"
fi

if [ "$1" == "intelmq" ]; then
    # Add sebix repo to sources
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/sebix.asc] http://download.opensuse.org/repositories/home:/sebix:/intelmq/${os_repo_name}_${VERSION_ID}/ /" > /etc/apt/sources.list.d/intelmq.list
    wget -O /etc/apt/trusted.gpg.d/sebix.asc https://download.opensuse.org/repositories/home:sebix:intelmq/${os_repo_name}_${VERSION_ID}/Release.key
    if [ "${INTELMQ_UNSTABLE_REPOSITORY:-false}" == "true" ]; then
        echo "deb [signed-by=/etc/apt/trusted.gpg.d/sebix_unstable.asc] http://download.opensuse.org/repositories/home:/sebix:/intelmq:/unstable/${os_repo_name}_${VERSION_ID}/ /" >> /etc/apt/sources.list.d/intelmq.list
        wget -O /etc/apt/trusted.gpg.d/sebix_unstable.asc https://download.opensuse.org/repositories/home:sebix:intelmq:unstable/${os_repo_name}_${VERSION_ID}/Release.key
    fi
elif [ "$1" == "intevation" ]; then
    # Add Intevation apt repo
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/intevation.asc] https://apt.intevation.de ${VERSION_CODENAME} intelmq-testing" > /etc/apt/sources.list.d/intevation.list
    wget -O /etc/apt/trusted.gpg.d/intevation.asc https://ssl.intevation.de/Intevation-Distribution-Key-2021.asc
elif [ "$1" == "node" ]; then
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://deb.nodesource.com/node_14.x ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/nodesource.list
    wget -O /etc/apt/trusted.gpg.d/nodesource.gpg  https://deb.nodesource.com/gpgkey/nodesource.gpg.key
elif [ "$1" == "local" ]; then
    DEBIAN_FRONTEND="noninteractive" apt-get install -y dpkg-dev
    # Add local file system repository and favor it over other sources
    echo deb [trusted=yes] file:/opt/packages ./ > /etc/apt/sources.list.d/local.list
    echo -e "Package: *\nPin: origin \"\"\nPin-Priority: 999" > /etc/apt/preferences.d/local-repository
    # Create a Packages file
    cd /opt/packages
    dpkg-scanpackages -m . > Packages
fi
