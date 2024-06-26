#!/bin/bash

echo 'deb [signed-by=/etc/apt/trusted.gpg.d/nodesource.gpg] https://deb.nodesource.com/node_14.x jammy main' \
     >/etc/apt/sources.list.d/nodesource.list
wget -O /etc/apt/trusted.gpg.d/nodesource.gpg  https://deb.nodesource.com/gpgkey/nodesource.gpg.key

echo "deb [signed-by=/etc/apt/trusted.gpg.d/sebix.asc] http://download.opensuse.org/repositories/home:/sebix:/intelmq/xUbuntu_22.04/ /" > /etc/apt/sources.list.d/intelmq.list
wget -O /etc/apt/trusted.gpg.d/sebix.asc https://download.opensuse.org/repositories/home:sebix:intelmq/xUbuntu_22.04/Release.key

echo "deb [signed-by=/etc/apt/trusted.gpg.d/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
wget -O /etc/apt/trusted.gpg.d/yarn.gpg https://dl.yarnpkg.com/debian/pubkey.gpg
