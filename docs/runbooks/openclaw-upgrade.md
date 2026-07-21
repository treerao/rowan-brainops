# OpenClaw Upgrade Runbook

## Overview

OpenClaw runs as a container on mino (`ghcr.io/openclaw/openclaw:<tag>`). Upgrades are: bump image tag, pull, recreate. All state lives in mounted volumes — the container is stateless.

**Channels are plugins.** As of ~2026.7, Slack is no longer bundled — it ships as
`@openclaw/slack`. A configured-but-missing plugin is auto-installed on gateway
start (into `~/.openclaw/npm/projects/`, which is inside the mounted config dir,
so it persists). Expect a startup warning on the first boot after upgrading, then
`[slack] socket mode connected`. If it does not self-install:
`openclaw plugins install @openclaw/slack`.

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

### 5. Backup config — the WHOLE dir, not just the JSON

Backing up only `openclaw.json` is **not sufficient**. Upgrades run one-way state
migrations over the rest of the config dir — credentials, cron store, and the
Memory Core index all live there. The 2026.7.1 upgrade migrated the cron store and
Rowan's memory index to SQLite on first start.

```bash
ssh rrao@mino "bash -lc 'cp -R /Users/rrao/rowan-runtime/openclaw-config \
  /Users/rrao/rowan-runtime/backups/openclaw-config-\$(date +%Y%m%d-%H%M%S)'"
```

Migrations archive their legacy sources as `*.migrated` sidecars, so they are not
destructive — but a full-dir copy is the only real rollback.

### 5b. Dry-run the new image against a COPY of the config

Cheapest way to catch breaking changes the release notes miss. Costs ~2 minutes and
touches nothing live. This is how the Slack-plugin change above was caught.

```bash
ssh rrao@mino "bash -lc '
  rm -rf /Users/rrao/oc-cfg-test
  cp -R /Users/rrao/rowan-runtime/openclaw-config /Users/rrao/oc-cfg-test
  docker run --rm -e HOME=/home/node \
    -v /Users/rrao/oc-cfg-test:/home/node/.openclaw \
    ghcr.io/openclaw/openclaw:<NEW_TAG> \
    sh -lc \"node /app/openclaw.mjs config validate\"'"
```

Two gotchas, both cost real debugging time if you hit them cold:
- Bind-mount the copy under `/Users/rrao`, **not** `/tmp` — `/tmp` is not in the
  VM's shared paths and mounts silently empty.
- Pass `-e HOME=/home/node`, or an SSH-forwarded `HOME` leaks in and the CLI looks
  for config in the wrong place.

**Delete the copy when done** — it contains a full copy of `credentials/`.

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

Also confirm the migration and channel plugins actually came up:

```bash
# State migrations that ran on first start
ssh rrao@mino "bash -lc 'docker logs rowan-openclaw 2>&1 | grep -iE \"migrat|state-migrations\"'"

# Channel plugin loaded and connected — NOT implied by a healthy container
ssh rrao@mino "bash -lc 'docker logs --since 5m rowan-openclaw 2>&1 | grep -i \"socket mode\"'"
```

### 5. Smoke test

- Check Slack — send a test message to Rowan
- Verify cron jobs: `ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"openclaw cron list\"'"`
  (the cron store migrated to SQLite in 2026.7.1 — confirm jobs survived)
- Verify workspace mount: `ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"ls /home/node/.openclaw/workspace/CLAUDE.md\"'"`

### 6. Run the security audit

Not optional, and not only an upgrade check — a new version may surface
pre-existing problems, and config-dir restores can silently re-open the
credentials-perms CRITICAL (see the 2026.7.1 log).

```bash
ssh rrao@mino "bash -lc 'docker exec rowan-openclaw sh -lc \"node /app/openclaw.mjs security audit\"'"
```

## Rollback

If the upgrade fails, revert the image tag and recreate:

```bash
ssh rrao@mino "bash -lc 'sed -i \"\" \"s|OPENCLAW_IMAGE=.*|OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:<OLD_TAG>|\" ~/rowan-brainops/compose/.env'"
ssh rrao@mino "bash -lc 'cd ~/rowan-brainops/compose && docker compose up -d openclaw'"
```

Restore the config backup if needed. Restore the **whole dir** — rolling back to an
older image with a config dir whose state has already been migrated forward is not
a supported combination:

```bash
ssh rrao@mino "bash -lc '
  mv /Users/rrao/rowan-runtime/openclaw-config /Users/rrao/rowan-runtime/openclaw-config.failed
  cp -R /Users/rrao/rowan-runtime/backups/openclaw-config-<TIMESTAMP> \
        /Users/rrao/rowan-runtime/openclaw-config'"
```

Then re-apply the credentials perms fix (`chmod 700`/`600` — see the 2026.7.1 log);
a restored copy brings back whatever perms the backup had.

## Current state (as of 2026-07-20)

| Item | Value |
|------|-------|
| Running version | `2026.7.1` |
| Image | `ghcr.io/openclaw/openclaw:2026.7.1` |
| Primary model | `openai/gpt-5.6-luna` |
| Fallbacks | `openai/gpt-5.6-terra`, `anthropic/claude-sonnet-5` |
| Channel plugins | `slack` (external `@openclaw/slack`, in `plugins.allow`) |
| Config path (host) | `/Users/rrao/rowan-runtime/openclaw-config/openclaw.json` |
| Env file | `~/rowan-brainops/compose/.env` |
| Security audit | 0 critical · 4 warn (all Control-UI-via-tunnel) |
| All containers | healthy |

Note on model ids: the bare `gpt-5.6` alias routes to **Sol**. Name the variant
explicitly (`gpt-5.6-luna`) or you will silently get a different tier.

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
  - **Correction (2026-07-20):** this was wrong. `lastTouchedVersion` stayed at
    `2026.2.21` after this upgrade, i.e. the config was *not* rewritten and no
    migration ran. Normally OpenClaw does maintain this field (2026.7.1 stamped it
    correctly). Treat a stale stamp as a signal that migrations have not run yet.
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

## Upgrade log: 2026.3.28 → 2026.7.1 (2026-07-20)

Four-month, multi-minor jump. Run from krill over SSH.

### What we did
1. Full-dir backup of the config dir (89M) — not just `openclaw.json`
2. Dry-ran `config validate` with the 2026.7.1 image against a **copy** of the config
3. Bumped `OPENCLAW_IMAGE` to `2026.7.1`; `docker compose up -d openclaw`
4. Primary model → `openai/gpt-5.6-luna`; restarted gateway to clear session model cache
5. Rebuilt the fallback chain; set `plugins.allow`; set `skills.workshop.approvalPolicy`
6. Hardened `credentials/` perms (see below)

### The dry-run earned its keep
`config validate` against the new image, before touching anything live, reported:

```
! plugins.entries.slack: plugin not installed: slack
```

Slack had been externalized to `@openclaw/slack`. **Neither the 2026.7.1 release
notes nor CHANGELOG.md mentioned it.** In the event 7.1 auto-installed the plugin on
start and there was no outage — but that was luck, not knowledge. Always dry-run.

### Migrations that ran on first start
- Cron store → SQLite (the one existing job survived; verify with `cron list`)
- update-check + config-health state → shared SQLite
- **Memory Core memory index for agent `main` → per-agent SQLite** (30 sources,
  106 chunks, 107 cache rows)

All archived legacy sources as `*.migrated` sidecars. This is the reason to back up
the whole config dir.

### Security audit found a CRITICAL unrelated to the upgrade
`openclaw security audit` (worth running every upgrade — it is not just an upgrade
check) reported `fs.credentials_dir.perms_writable`: the credentials dir was
`drwxrwxrwx` with `-rw-rw-rw-` files, **world-writable since 2026-02-22**.

This is *not* a bind-mount artifact — the host perms were genuinely 777. It is the
consequence of the `EPERM ... skipped permission hardening` log lines: OpenClaw
tries to harden these perms on start and cannot, because macOS bind mounts reject
`chmod` from inside the container. **So it must be fixed host-side, and it will
never self-heal.** Re-check it after any config-dir restore.

```bash
chmod 700 /Users/rrao/rowan-runtime/openclaw-config/credentials
chmod 600 /Users/rrao/rowan-runtime/openclaw-config/credentials/*.json
```

Safe for the container: Docker Desktop maps host `rrao` (uid 501) to the container's
`node` (uid 1000), which sees itself as owner. Audit went 1 critical → 0.

The audit also flagged the old fallback chain as `models.weak_tier`
(`claude-sonnet-4-20250514`, `gpt-4o-mini` — "more susceptible to prompt injection
and tool misuse"); replacing it cleared that warning too.

### Still open
4 warnings, all one root cause: Control UI exposed via cloudflared —
`dangerouslyAllowHostHeaderOriginFallback=true` plus empty `gateway.trustedProxies`.
Proper fix is to disable the flag *and* set explicit `gateway.controlUi.allowedOrigins`
to the tunnel hostname. Not a blind flip — get it wrong and you lose dashboard access.

Also: `@openclaw/slack` is installed as an unpinned npm spec
(`plugins.installs_unpinned_npm_specs`). `plugins.allow` now gates *which* plugins
load; pinning the version is the outstanding complement.

### Verification
- `--version` → `OpenClaw 2026.7.1`
- `[gateway] agent model: openai/gpt-5.6-luna (thinking=medium, fast=off)`
- `[slack] socket mode connected`; 12 plugins loaded
- `cron list` → job intact; gateway HTTP 200; both mounts present
- All 4 containers healthy

## Version history

| Date | From | To | Notes |
|------|------|----|-------|
| 2026-02-22 | fresh | 2026.2.21 | Initial deployment |
| ~2026-03-09 | 2026.2.21 | 2026.3.8 | — |
| ~2026-03-12 | 2026.3.8 | 2026.3.12 | Security patches (CVE-2026-32922) |
| 2026-03-31 | 2026.3.12 | 2026.3.28 | Model → gpt-5.4-mini, web search key, 16 point releases |
| 2026-07-20 | 2026.3.28 | 2026.7.1 | Slack → plugin, model → gpt-5.6-luna, fallbacks rebuilt, credentials perms CRITICAL fixed |
