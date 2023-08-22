#!/bin/bash

echo 'deb https://deb.nodesource.com/node_14.x focal main' \
     >/etc/apt/sources.list.d/nodesource.list
apt-key add /tmp/nodesource.gpg.key
echo "deb http://download.opensuse.org/repositories/home:/sebix:/intelmq/xUbuntu_20.04/ /" > /etc/apt/sources.list.d/intelmq.list
curl -sSL https://download.opensuse.org/repositories/home:sebix:intelmq/xUbuntu_20.04/Release.key | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
