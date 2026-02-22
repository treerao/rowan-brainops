#!/usr/bin/env bash
set -euo pipefail

echo "Checking docker + compose availability..."
docker --version
if docker compose version >/dev/null 2>&1; then
  docker compose version
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose --version
else
  echo "Neither 'docker compose' nor 'docker-compose' is available" >&2
  exit 1
fi

echo "Preflight OK"
