#!/bin/sh
# restart-agent handler — invoked per-connection by socat.
# Only accepts POST /restart; force-recreates the openclaw container.

set -eu

COMPOSE_FILE="/compose/docker-compose.yml"
COMPOSE_ENV_FILE="/compose/.env"
COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-compose}"
TARGET_SERVICE="openclaw"

# Read request line
read -r method path _proto
path=$(printf '%s' "$path" | tr -d '\r\n')
method=$(printf '%s' "$method" | tr -d '\r\n')

# Drain headers
while read -r header; do
  header=$(printf '%s' "$header" | tr -d '\r\n')
  [ -z "$header" ] && break
done

respond() {
  code="$1"; status="$2"; body="$3"
  printf 'HTTP/1.1 %s %s\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n%s\n' \
    "$code" "$status" "$body"
}

if [ "$method" = "POST" ] && [ "$path" = "/restart" ]; then
  if output=$(docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_ENV_FILE" -p "$COMPOSE_PROJECT" up -d --force-recreate "$TARGET_SERVICE" 2>&1); then
    respond 200 OK "{\"ok\":true,\"service\":\"$TARGET_SERVICE\"}"
  else
    respond 500 "Internal Server Error" "{\"ok\":false,\"error\":\"compose failed\",\"detail\":\"$output\"}"
  fi
elif [ "$method" = "GET" ] && [ "$path" = "/healthz" ]; then
  respond 200 OK '{"ok":true}'
else
  respond 404 "Not Found" '{"error":"POST /restart or GET /healthz only"}'
fi
