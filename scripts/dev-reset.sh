#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

echo "Stopping and removing all volumes..."
docker compose -f docker/docker-compose.yml down -v

echo "Starting fresh..."
docker compose -f docker/docker-compose.yml up -d

echo "Waiting for postgres..."
until docker compose -f docker/docker-compose.yml exec -T postgres pg_isready -U memorial -d memorial > /dev/null 2>&1; do
  sleep 1
done

echo ""
echo "Stack reset. Fresh DB, empty MinIO bucket."
echo "  Postgres  → localhost:5432"
echo "  MinIO     → localhost:9000  (console: localhost:9001)"
echo "  Mailhog   → localhost:1025  (UI: localhost:8025)"
