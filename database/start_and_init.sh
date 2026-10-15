#!/bin/bash

set -eu

marker="/var/lib/postgresql/data/intelmq_init_complete"
where="$(dirname "$0")"

if [ -e "$marker" ]; then
    echo 'Database is already populated. Starting Postgres...'
    exec "$where/start.sh"
fi

echo 'Database will need to be populated. Starting Postgres...'

"$where/start.sh" &
pid="$!"

echo 'Waiting for Postgres to start...'
until timeout 4s pg_isready -qU postgres; do
    if ! kill -0 "$pid" > /dev/null 2>&1; then
        echo 'Postgres process died!'
        exit 1
    fi
    sleep 1
done
echo 'Postgres is ready. Populating database...'

# First delete state from any potential incomplete runs
"$where/deinit.sh"
"$where/init.sh"

echo 'Database population complete.'

touch "$marker"

wait -f "$pid"
