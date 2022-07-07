#!/bin/bash

set -xeu -o pipefail

### ContactDB
createdb --encoding=UTF8 --template=template0 contactdb

if [ -f /opt/intelmq-certbund-contact/sql/initdb.sql ]; then
    psql -f /opt/intelmq-certbund-contact/sql/initdb.sql contactdb
else
    psql -f /usr/share/intelmq-certbund-contact/sql/initdb.sql contactdb
fi

psql -c "CREATE ROLE intelmq WITH login PASSWORD 'secret';"
psql -c "CREATE ROLE fody WITH login PASSWORD 'secret';"
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO intelmq;" contactdb
psql -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO fody;" contactdb
psql -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO fody;" contactdb

# use the directory created by ripe_download at the build stage. If ripe_download was called multiple times on different days, select the latest directory.
latest_ripe_download="$(ls -t1 /opt/ripe_download | head -n 1)"
pushd "/opt/ripe_download/$latest_ripe_download"
# At this stage, the server is only reachable with the socket. https://hub.docker.com/_/postgres section "Initialization scripts"
ripe_import --conninfo 'host=/var/run/postgresql/ dbname=contactdb user=fody' --ripe-delegated-file=/opt/delegated-ripencc-latest --restrict-to-country DE --verbose
popd

## EventDB
createdb --encoding=UTF8 --template=template0 eventdb

# It is save to use the initdb.sql shipped for testing as long as we do not modify the harmonization locally
if [ -f /opt/intelmq/intelmq/tests/bin/initdb.sql ]; then
    psql -f /opt/intelmq/intelmq/tests/bin/initdb.sql eventdb
else
    psql -f /usr/lib/python3/dist-packages/intelmq/tests/bin/initdb.sql eventdb
fi

if [ -f /opt/intelmq-mailgen/sql/notifications.sql ]; then
    psql -f /opt/intelmq-mailgen/sql/notifications.sql eventdb
else
    psql -f /usr/share/intelmq-mailgen/sql/notifications.sql eventdb
fi

psql -c "GRANT eventdb_send_notifications TO intelmq" eventdb
psql -c "GRANT eventdb_insert TO intelmq" eventdb
psql -c "GRANT INSERT,SELECT ON ALL TABLES IN SCHEMA public TO intelmq;" eventdb
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO fody;" eventdb
psql -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO intelmq;" eventdb
psql -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO fody;" eventdb
