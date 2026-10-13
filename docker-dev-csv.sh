#!/bin/sh
{
docker compose -f docker-compose.external.yml -f docker-compose.dev-csv.yml "$@"
exit
}
