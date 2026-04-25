#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
docker compose -f docker/docker-compose.yml up -d
echo "Services up:"
echo "  Postgres  → localhost:5432"
echo "  MinIO     → localhost:9000  (console: localhost:9001)"
echo "  Mailhog   → localhost:1025  (UI: localhost:8025)"
