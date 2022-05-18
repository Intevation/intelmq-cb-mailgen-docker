#! /bin/bash

cd /opt/intelmq-api || exit
hug -p 81 -m intelmq_api.serve &
apachectl -D FOREGROUND

