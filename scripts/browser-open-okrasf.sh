#!/usr/bin/env bash
set -euo pipefail

# Host-only: launch Chrome CDP for OkraSF profile
# Port: 18800

ROOT="$HOME/.openclaw/browser/okrasf/user-data"
PROFILE_DIR="Default"
PORT="18800"

exec "$(dirname "$0")/browser-open-profile.sh" "$ROOT" "$PROFILE_DIR" "$PORT"
