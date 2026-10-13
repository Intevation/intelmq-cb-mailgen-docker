#!/bin/sh
{
docker compose -f docker-compose.external.yml -f docker-compose.common.yml -f docker-compose.dev.yml "$@"
exit
}
