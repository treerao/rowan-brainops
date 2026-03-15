# restart-agent sidecar

_Added: 2026-03-13_

## Problem

When OpenClaw edits its own compose config (e.g. new env vars, volume mounts) via the brainops workspace, the container needs to be force-recreated to pick up the changes. A process-level restart (`restart: true` in openclaw.json) only restarts the Node process — it doesn't re-read compose-level config.

The options considered:

1. **Mount the Docker socket directly into the openclaw container.** Simple, but gives OpenClaw (and anything it executes, including prompt-injected commands) full root-equivalent access to the host via the Docker API. It could start/stop/delete any container, mount arbitrary host paths, or escalate privileges.

2. **Sidecar with scoped access.** A minimal container that holds the Docker socket and exposes a single HTTP endpoint. OpenClaw can only trigger a restart — it never touches the socket directly.

3. **Host-side webhook / systemd service.** More isolated but requires host-level setup outside of compose, making the stack less self-contained.

## Decision

Option 2 — sidecar. The risk of full socket access (option 1) is too high for an LLM-driven agent susceptible to prompt injection. A sidecar limits the blast radius to a single, auditable action: force-recreating the openclaw service.

## Architecture

```
┌─────────────┐   POST /restart   ┌─────────────────┐
│  openclaw   │ ───────────────── │  restart-agent   │
│  container  │   (port 9111)     │  (sidecar)       │
└─────────────┘                   │                  │
                                  │  docker.sock ──────── Docker daemon
                                  │  compose.yml (ro) │
                                  └─────────────────┘
```

## How it works

- `restart-agent` is a `docker:cli` + `socat` image.
- `socat` listens on port 9111 and forks `handler.sh` per connection.
- `handler.sh` accepts only these routes:
  - `POST /restart` — runs `docker compose up -d --force-recreate openclaw` (v2 preferred; v1 fallback)
  - `POST /pull` — runs `docker compose pull openclaw` (v2 preferred; v1 fallback)
  - `GET /healthz` — returns `{"ok":true}`
  - Everything else returns 404.
- The compose file is mounted read-only at `/compose/docker-compose.yml`.
- The Docker socket is mounted only into this sidecar, never into openclaw.

## Usage from OpenClaw

From within the openclaw container (e.g. via a shell tool or skill):

```sh
curl -X POST http://restart-agent:9111/restart
```

Response on success:
```json
{"ok":true,"service":"openclaw"}
```

**Note:** This will kill the openclaw container and recreate it. The curl request will be interrupted mid-response since the caller's container is the one being restarted. OpenClaw should treat a connection reset after this call as success.

## Security considerations

- The Docker socket is only accessible to the restart-agent sidecar, not to openclaw.
- The handler is a static shell script — no user input is interpolated into commands.
- The compose file is mounted read-only; the sidecar cannot modify it.
- The sidecar can only force-recreate the `openclaw` service (hardcoded in handler.sh).
- The endpoint is only exposed on the internal compose network (no host port binding).
- Risk: if an attacker gains shell access to the openclaw container, they can trigger restarts (denial of service) but cannot escalate to arbitrary Docker commands.

## Files

- `services/restart-agent/Dockerfile` — image definition
- `services/restart-agent/handler.sh` — HTTP handler script
- `compose/docker-compose.yml` — service definition under `restart-agent`
