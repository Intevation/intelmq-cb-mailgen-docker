echo 'deb https://deb.nodesource.com/node_14.x focal main' \
     >/etc/apt/sources.list.d/nodesource.list
apt-key add /tmp/nodesource.gpg.key
echo 'deb https://dl.yarnpkg.com/debian/ stable main' \
     >/etc/apt/sources.list.d/yarn.list
apt-key add /tmp/yarnpkg.gpg.key
