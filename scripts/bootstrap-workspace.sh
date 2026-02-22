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

if [ -z "${WORKSPACE_GIT_URL:-}" ] || [ -z "${WORKSPACE_DIR:-}" ]; then
  echo "WORKSPACE_GIT_URL and WORKSPACE_DIR must be set in compose/.env" >&2
  exit 1
fi

mkdir -p "$(dirname "$WORKSPACE_DIR")"

if [ -d "$WORKSPACE_DIR/.git" ]; then
  echo "Updating existing workspace at $WORKSPACE_DIR"
  git -C "$WORKSPACE_DIR" fetch --all --prune
  git -C "$WORKSPACE_DIR" checkout "${WORKSPACE_BRANCH:-main}"
  git -C "$WORKSPACE_DIR" pull --ff-only origin "${WORKSPACE_BRANCH:-main}"
else
  echo "Cloning workspace into $WORKSPACE_DIR"
  git clone "$WORKSPACE_GIT_URL" "$WORKSPACE_DIR"
  git -C "$WORKSPACE_DIR" checkout "${WORKSPACE_BRANCH:-main}"
fi
