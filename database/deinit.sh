#!/bin/bash

set -xeu

psql -U postgres -c 'DROP DATABASE IF EXISTS contactdb WITH (FORCE);'
psql -U postgres -c 'DROP DATABASE IF EXISTS eventdb WITH (FORCE);'

psql -U postgres -c 'DROP ROLE IF EXISTS intelmq;'
psql -U postgres -c 'DROP ROLE IF EXISTS fody;'
psql -U postgres -c 'DROP ROLE IF EXISTS root;'
