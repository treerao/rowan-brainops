#!/usr/bin/env bash
set -euo pipefail

# Host-only: launch Chrome CDP for treerao profile
# Port: 18801

ROOT="$HOME/.openclaw/browser/treerao/user-data"
PROFILE_DIR="Default"
PORT="18801"
START_URL="https://x.com/i/bookmarks"

exec "$(dirname "$0")/browser-open-profile.sh" "$ROOT" "$PROFILE_DIR" "$PORT" "$START_URL"
