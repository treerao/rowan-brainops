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

compose_cmd() {
  # Prefer Compose v2 (docker compose). Fall back to v1 (docker-compose) if needed.
  if docker compose version >/dev/null 2>&1; then
    echo "docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
  else
    echo ""
  fi
}

do_compose() {
  cmd="$(compose_cmd)"
  [ -n "$cmd" ] || return 127

  if [ "$cmd" = "docker compose" ]; then
    docker compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_ENV_FILE" -p "$COMPOSE_PROJECT" "$@"
  else
    docker-compose -f "$COMPOSE_FILE" --env-file "$COMPOSE_ENV_FILE" -p "$COMPOSE_PROJECT" "$@"
  fi
}

if [ "$method" = "POST" ] && [ "$path" = "/restart" ]; then
  if output=$(do_compose up -d --force-recreate "$TARGET_SERVICE" 2>&1); then
    respond 200 OK "{\"ok\":true,\"action\":\"restart\",\"service\":\"$TARGET_SERVICE\"}"
  else
    respond 500 "Internal Server Error" "{\"ok\":false,\"action\":\"restart\",\"error\":\"compose failed\",\"detail\":\"$output\"}"
  fi
elif [ "$method" = "POST" ] && [ "$path" = "/pull" ]; then
  if output=$(do_compose pull "$TARGET_SERVICE" 2>&1); then
    respond 200 OK "{\"ok\":true,\"action\":\"pull\",\"service\":\"$TARGET_SERVICE\"}"
  else
    respond 500 "Internal Server Error" "{\"ok\":false,\"action\":\"pull\",\"error\":\"compose failed\",\"detail\":\"$output\"}"
  fi
elif [ "$method" = "GET" ] && [ "$path" = "/healthz" ]; then
  respond 200 OK '{"ok":true}'
else
  respond 404 "Not Found" '{"error":"POST /restart, POST /pull, or GET /healthz only"}'
fi
