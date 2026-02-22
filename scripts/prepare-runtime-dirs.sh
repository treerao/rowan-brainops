#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/compose/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Copy compose/.env.example first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

for dir_var in OPENCLAW_CONFIG_DIR OPENCLAW_STATE_DIR WORKSPACE_DIR; do
  dir_val="${!dir_var:-}"
  if [ -z "$dir_val" ]; then
    echo "$dir_var is unset in compose/.env" >&2
    exit 1
  fi
  mkdir -p "$dir_val"
  echo "Prepared: $dir_val"
done
