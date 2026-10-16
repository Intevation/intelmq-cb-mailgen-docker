#!/bin/sh
exec /usr/local/bin/docker-entrypoint.sh postgres -c logging_collector=on -c log_destination=stderr -c log_directory=/var/log/postgresql/ -c log_statement=all
