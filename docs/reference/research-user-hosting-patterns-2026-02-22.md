# Research Note: How Most OpenClaw Users Likely Host (as of February 22, 2026)

## Question
Are most users running OpenClaw with production-style container rigor, or in a simpler user-account install?

## Scope and method
- Reviewed official OpenClaw docs and repo guidance first.
- Reviewed community deployment artifacts that indicate stronger ops posture.
- Reviewed recent public tutorials/gists for observed setup patterns.
- This is an inference note, not telemetry from maintainers.

## What the primary sources say

## 1) Official "default" path is local CLI onboarding
Official getting-started guidance uses install script + onboarding wizard:
- `curl -fsSL https://openclaw.ai/install.sh | bash`
- `openclaw onboard --install-daemon`

This points to a user-level service model (launchd/systemd user service) as the normal path for personal installs.

Sources:
- https://docs.openclaw.ai/start/getting-started
- https://raw.githubusercontent.com/openclaw/openclaw/main/README.md

## 2) Docker is explicitly optional
Official Docker docs describe Docker as optional and suggest normal install flow for fastest local dev/use on your own machine.

Source:
- https://docs.openclaw.ai/install/docker

## 3) Remote access guidance centers on loopback + Tailscale Serve/Funnel
Official docs emphasize loopback binding with Tailscale Serve/Funnel for remote access, which is compatible with non-container installs and indicates many users can operate safely without full container orchestration.

Sources:
- https://docs.openclaw.ai/gateway/tailscale
- https://raw.githubusercontent.com/openclaw/openclaw/main/README.md

## 4) There is an active "uplevel" ecosystem
Community projects like RunClawd package Caddy + Cloudflare Tunnel + backups and other production-minded defaults. This signals meaningful demand for hardened/containerized setups, but as an add-on layer rather than the default entry path.

Source:
- https://runclawd.sh/

## 5) Public tutorial signal skews toward quick local installs
Recent public gists/tutorials frequently mirror the install-script + onboarding flow, often with local paths and user-home configs.

Examples:
- https://gist.github.com/80x-djh/1ed38f4073925899e50fc4847ba4db53
- https://gist.github.com/iam-veeramalla/9d10f968038ee76d5bc374b44f0cf8bb

## Inference (explicit)
Most users are likely in the "pragmatic local" camp:
- install in user space,
- run onboarding wizard,
- keep gateway as a user service,
- add remote access via Tailscale or simple tunnels.

A smaller but growing segment runs containerized/hardened stacks (Docker Compose, reverse proxy, Cloudflare/Tailscale access controls, backups).

## Confidence
- High confidence on official guidance positioning (local wizard first, Docker optional).
- Medium confidence on "most users" distribution because no public maintainer telemetry was found.

## What this means for this repo
Your approach (documented migration to containerized, access-controlled, backup-aware hosting) is above the likely median maturity and is a strong "grow-up" narrative.
