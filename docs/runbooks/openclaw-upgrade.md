# OpenClaw Upgrade Runbook

## Overview

OpenClaw runs as a container on mino (`ghcr.io/openclaw/openclaw:<tag>`). Upgrades are: bump image tag, pull, recreate. All state lives in mounted volumes — the container is stateless.

## SSH from Windows/Cygwin to mino

All commands run remotely via SSH. There are two gotchas:

1. **Use `bash -lc`** — non-login SSH shells on mino don't have `docker` in PATH
2. **Git on mino uses container SSH keys** — repos cloned by OpenClaw have `core.sshCommand` pointing to `/home/node/.ssh/...` which doesn't exist on the host. Fix per-repo:
   ```bash
   ssh rrao@mino "bash -lc 'cd ~/rowan-brainops && git config core.sshCommand \"ssh -i ~/.ssh/id_ed25519_github -o IdentitiesOnly=yes\"'"
   ```

## Pre-flight checks

Run from this machine (Windows/Cygwin) via SSH. All commands use `bash -lc` to get correct PATH on mino.

### 1. Record current state

```bash
# Running version and health
ssh rrao@mino "bash -lc 'docker inspect rowan-openclaw --format={{.Config.Image}}'"
ssh rrao@mino "bash -lc 'docker ps --format \"table {{.Names}}\t{{.Image}}\t{{.Status}}\"'"

# Container version confirmation
ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"node openclaw.mjs --version\"'"
```

### 2. Check for breaking changes

Before upgrading across a major point release, review the changelog:
- https://github.com/openclaw/openclaw/releases
- https://github.com/openclaw/openclaw/blob/main/CHANGELOG.md

Key things to check:
- **Removed env vars** (e.g. `CLAWDBOT_*` / `MOLTBOT_*` were removed in 2026.3.22)
- **Default model changes** (e.g. 2026.3.22 changed default to `gpt-5.4`)
- **Config schema changes** in `openclaw.json`
- **Plugin/skill breaking changes**

### 3. Check env vars against breaking changes

```bash
# Dump env var names (not values) to check for deprecated prefixes
ssh rrao@mino "bash -lc 'grep -v \"^#\" ~/rowan-brainops/compose/.env | cut -d= -f1 | sort'"

# Check container env for legacy vars
ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"env\"'" | grep -iE "CLAWDBOT|MOLTBOT"
```

### 4. Check OpenClaw config for compatibility

```bash
ssh rrao@mino "bash -lc 'cat /Users/rrao/rowan-runtime/openclaw-config/openclaw.json'"
```

Review `agents.defaults.model.primary` and `fallbacks` — if the upgrade changes default models, decide whether to pin your current model or adopt the new default.

### 5. Backup config

```bash
ssh rrao@mino "bash -lc 'cp /Users/rrao/rowan-runtime/openclaw-config/openclaw.json /Users/rrao/rowan-runtime/openclaw-config/openclaw.json.bak-\$(date +%Y%m%d-%H%M%S)'"
```

## Upgrade procedure

### 1. If docker-compose.yml changed

Edit locally, commit, push, then pull on mino:
```bash
# From this machine — commit and push brainops
cd ~/gh/rowan-brainops && git add compose/docker-compose.yml && git commit -m "..." && git push origin main

# Pull on mino (may need GIT_SSH_COMMAND override if core.sshCommand not fixed)
ssh rrao@mino "bash -lc 'cd ~/rowan-brainops && git pull --rebase'"
```

### 2. Update image tag

```bash
# On mino, edit the .env file
ssh rrao@mino "bash -lc 'sed -i \"\" \"s|OPENCLAW_IMAGE=.*|OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:<NEW_TAG>|\" ~/rowan-brainops/compose/.env'"

# Verify
ssh rrao@mino "bash -lc 'grep OPENCLAW_IMAGE ~/rowan-brainops/compose/.env'"
```

### 3. Update OpenClaw config (if changing models)

```bash
# Edit openclaw.json on mino (e.g. change primary model)
ssh rrao@mino "bash -lc 'python3 -c \"
import json
with open(\\\"/Users/rrao/rowan-runtime/openclaw-config/openclaw.json\\\") as f:
    c = json.load(f)
c[\\\"agents\\\"][\\\"defaults\\\"][\\\"model\\\"][\\\"primary\\\"] = \\\"openai/gpt-5.4-mini\\\"
with open(\\\"/Users/rrao/rowan-runtime/openclaw-config/openclaw.json\\\", \\\"w\\\") as f:
    json.dump(c, f, indent=2)
\"'"
```

Or SSH in interactively and edit with `vim`/`nano`.

### 4. Pull the new image

```bash
ssh rrao@mino "bash -lc 'cd ~/rowan-brainops/compose && docker compose pull openclaw'"
```

### 5. Recreate the container

```bash
ssh rrao@mino "bash -lc 'cd ~/rowan-brainops/compose && docker compose up -d openclaw'"
```

This stops the old container and starts the new one. Mounted volumes persist.

### 4. Verify

```bash
# Version
ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"node openclaw.mjs --version\"'"

# Health (may take 30s to become healthy)
ssh rrao@mino "bash -lc 'docker ps --format \"table {{.Names}}\t{{.Image}}\t{{.Status}}\" | grep openclaw'"

# Logs — check for startup errors
ssh rrao@mino "bash -lc 'docker logs --since 2m rowan-openclaw 2>&1 | tail -30'"

# Gateway responding
ssh rrao@mino "bash -lc 'curl -fsS http://localhost:18789/ | head -3'"
```

### 5. Smoke test

- Check Slack — send a test message to Rowan
- Verify cron jobs: `ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"openclaw cron list\"'"`
- Verify workspace mount: `ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"ls /home/node/.openclaw/workspace/CLAUDE.md\"'"`

## Rollback

If the upgrade fails, revert the image tag and recreate:

```bash
ssh rrao@mino "bash -lc 'sed -i \"\" \"s|OPENCLAW_IMAGE=.*|OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:<OLD_TAG>|\" ~/rowan-brainops/compose/.env'"
ssh rrao@mino "bash -lc 'cd ~/rowan-brainops/compose && docker compose up -d openclaw'"
```

Restore config backup if needed:
```bash
ssh rrao@mino "bash -lc 'cp /Users/rrao/rowan-runtime/openclaw-config/openclaw.json.bak-<TIMESTAMP> /Users/rrao/rowan-runtime/openclaw-config/openclaw.json'"
```

## Current state (as of 2026-03-31)

| Item | Value |
|------|-------|
| Running version | `2026.3.28` |
| Image | `ghcr.io/openclaw/openclaw:2026.3.28` |
| Primary model | `openai/gpt-5.4-mini` |
| Fallbacks | `gpt-5-mini`, `claude-sonnet-4`, `gpt-4o-mini` |
| Config path (host) | `/Users/rrao/rowan-runtime/openclaw-config/openclaw.json` |
| Env file | `~/rowan-brainops/compose/.env` |
| All containers | healthy |

## Upgrade log: 2026.3.12 → 2026.3.28 (2026-03-31)

### What we did
1. Backed up `openclaw.json`
2. Updated `OPENCLAW_IMAGE` in `.env` to `2026.3.28`
3. Changed primary model from `gpt-5-mini` to `gpt-5.4-mini` in `openclaw.json`
4. Added `OPENCLAW_WEB_SEARCH_API_KEY` passthrough to `docker-compose.yml`
5. Committed + pushed brainops, pulled on mino
6. `docker compose pull openclaw && docker compose up -d openclaw`

### Issues encountered
- **Git pull on mino failed** — `core.sshCommand` in `~/rowan-brainops/.git/config` pointed to container key path (`/home/node/.ssh/...`). Fixed by setting it to `ssh -i ~/.ssh/id_ed25519_github -o IdentitiesOnly=yes`.
- **SSH from Cygwin to mino** — `ssh mino` failed because no `Host mino` entry in SSH config. Need to use `ssh rrao@mino`. Also, non-login shells don't have `docker` in PATH — always use `bash -lc`.
- **Known hosts mismatch** — old mino host key in `known_hosts` didn't match. Had to `ssh-keygen -R mino` and re-accept.

### Pre-flight findings
- No breaking env vars — all already `OPENCLAW_*`
- `OPENCLAW_WEB_SEARCH_API_KEY` was in `.env` but not passed through compose — fixed
- Config `lastTouchedVersion` was `2026.2.21` — OpenClaw auto-migrated on start (no issues)
- Image size: 2.89GB → 3.45GB

### Gotcha: model config vs runtime
- Startup logs showed `agent model: openai/gpt-5.4-mini` (config was read)
- But Rowan continued using the previous model until explicitly told to switch via chat
- Likely cause: existing agent sessions cache their model selection
- **After a model change, tell Rowan to use the new model** or restart sessions

### Verification
- `node openclaw.mjs --version` → `OpenClaw 2026.3.28`
- Logs confirmed: `agent model: openai/gpt-5.4-mini`
- Slack socket mode connected
- Container healthy after ~30s

## Version history

| Date | From | To | Notes |
|------|------|----|-------|
| 2026-02-22 | fresh | 2026.2.21 | Initial deployment |
| ~2026-03-09 | 2026.2.21 | 2026.3.8 | — |
| ~2026-03-12 | 2026.3.8 | 2026.3.12 | Security patches (CVE-2026-32922) |
| 2026-03-31 | 2026.3.12 | 2026.3.28 | Model → gpt-5.4-mini, web search key, 16 point releases |
