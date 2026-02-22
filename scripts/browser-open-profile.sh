#!/usr/bin/env bash
set -euo pipefail

# Launch Google Chrome with an isolated Rowan profile for OpenClaw browser tasks.

PROFILE_ROOT_DEFAULT="${HOME}/rowan-runtime/chrome-profile"
PROFILE_NAME_DEFAULT="Rowan"
EXTENSION_DIR_DEFAULT="${HOME}/.openclaw/browser/chrome-extension"

PROFILE_ROOT="${1:-${PROFILE_ROOT_DEFAULT}}"
PROFILE_NAME="${2:-${PROFILE_NAME_DEFAULT}}"
EXTENSION_DIR="${OPENCLAW_EXTENSION_DIR:-${EXTENSION_DIR_DEFAULT}}"

CHROME_APP="${CHROME_APP:-/Applications/Google Chrome.app}"
CHROME_BIN_DEFAULT="${CHROME_APP}/Contents/MacOS/Google Chrome"
CHROME_BIN="${CHROME_BIN:-${CHROME_BIN_DEFAULT}}"

if [[ ! -x "${CHROME_BIN}" ]]; then
  echo "error: Google Chrome binary not found/executable at ${CHROME_BIN}" >&2
  echo "hint: install Chrome or set CHROME_BIN to a valid executable path" >&2
  exit 1
fi

mkdir -p "${PROFILE_ROOT}"

OPEN_ARGS=(
  --user-data-dir="${PROFILE_ROOT}"
  --profile-directory="${PROFILE_NAME}"
  --no-first-run
  --no-default-browser-check
  --new-window
  "about:blank"
)

if [[ -d "${EXTENSION_DIR}" ]]; then
  OPEN_ARGS=(
    --disable-extensions-except="${EXTENSION_DIR}"
    --load-extension="${EXTENSION_DIR}"
    "${OPEN_ARGS[@]}"
  )
  echo "  extension-dir: ${EXTENSION_DIR}"
else
  echo "  extension-dir: not found (${EXTENSION_DIR})"
  echo "  hint: run 'openclaw browser extension install' on host"
fi

echo "Launching isolated Chrome profile..."
echo "  chrome-bin: ${CHROME_BIN}"
echo "  user-data-dir: ${PROFILE_ROOT}"
echo "  profile-directory: ${PROFILE_NAME}"

"${CHROME_BIN}" "${OPEN_ARGS[@]}" >/tmp/rowan-chrome.log 2>&1 &
