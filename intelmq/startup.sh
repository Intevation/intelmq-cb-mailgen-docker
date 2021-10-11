#! /bin/bash

cd /opt/intelmq-api
hug -p 81 -m intelmq_api.serve &
apachectl -D FOREGROUND

