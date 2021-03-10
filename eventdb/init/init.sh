#!/bin/bash

set -e

createdb --encoding=UTF8 --template=template0 eventdb

psql -f /opt/initdb.sql eventdb

psql -c "CREATE ROLE intelmq WITH login PASSWORD 'secret';"
psql -c "CREATE ROLE fody WITH login PASSWORD 'secret';"

psql -f /opt/intelmq-mailgen/sql/notifications.sql eventdb

psql -c "GRANT eventdb_send_notifications TO intelmq" eventdb
psql -c "GRANT eventdb_insert TO intelmq" eventdb
psql -c "GRANT INSERT,SELECT ON ALL TABLES IN SCHEMA public TO intelmq;" eventdb
psql -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO fody;" eventdb
psql -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO intelmq;" eventdb
psql -c "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO fody;" eventdb
