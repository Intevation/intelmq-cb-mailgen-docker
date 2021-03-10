#!/bin/bash

set -e

createdb --encoding=UTF8 --template=template0 contactdb

psql -f /opt/intelmq-certbund-contact/sql/initdb.sql contactdb

psql -c "CREATE ROLE intelmq WITH login PASSWORD 'secret';"
psql -c "CREATE ROLE fody WITH login PASSWORD 'secret';"
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO intelmq;" contactdb
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO fody;" contactdb

d=`date +%F`
cd $d

python3 ../intelmq-certbund-contact/intelmq_certbund_contact/ripe/ripe_import.py --conninfo dbname=contactdb --ripe-delegated-file=../delegated-ripencc-latest --restrict-to-country DE --verbose
