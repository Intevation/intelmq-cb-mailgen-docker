#!/bin/bash

set -eu

marker="/var/lib/postgresql/data/intelmq_init_complete"
where="$(dirname "$0")"

if [ -e "$marker" ]; then
    echo 'Database already initialized. Starting Postgres...'
    exec "$where/start.sh"
fi

echo 'Database will need to be initialized. Starting Postgres...'

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
echo 'Postgres is ready. Initializing database...'

# First delete state from any potential incomplete runs
"$where/deinit.sh"
"$where/init.sh"

echo 'Initialization complete.'

touch "$marker"

wait -f "$pid"
