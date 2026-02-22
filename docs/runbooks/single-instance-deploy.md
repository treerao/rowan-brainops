# Single-Instance Deploy (OpenClaw + Rowan Web + Cloudflare Tunnel)

## What this deploys
- `openclaw` gateway service for agent/chat/channel operations.
- `rowan-web` Express static server for allowlisted workspace content.
- `cloudflared` tunnel connector for Cloudflare Access-protected ingress.

## 1) Prepare local config
1. Copy `compose/.env.example` to `compose/.env`.
2. Fill all `REPLACE_ME` keys.
3. Set `WORKSPACE_GIT_URL=git@github.com:treerao/rowan.git`.
4. Confirm `WORKSPACE_DIR`, `OPENCLAW_CONFIG_DIR`, `OPENCLAW_STATE_DIR` paths.

## 2) Prepare local directories and workspace
1. Run `./scripts/prepare-runtime-dirs.sh`.
2. Run `./scripts/bootstrap-workspace.sh`.

## 3) Cloudflare admin setup
1. Create tunnel in Cloudflare Zero Trust and copy tunnel token into `CLOUDFLARE_TUNNEL_TOKEN`.
2. Create two public hostnames in tunnel ingress:
   - `rowan-agent.<your-domain>` -> `http://openclaw:${OPENCLAW_GATEWAY_PORT}`
   - `rowan-web.<your-domain>` -> `http://rowan-web:3333`
3. Apply Cloudflare Access policies to both hostnames.

## 4) Slack admin setup
1. Ensure Slack app has Socket Mode enabled.
2. Set bot/app tokens into `.env`.
3. Confirm scopes/events in Slack app config.

## 5) Start stack
1. Run `./scripts/deploy-up.sh`.
2. Run `./scripts/deploy-status.sh`.
3. Validate local health endpoints (via container network):
   - `rowan-web`: `/healthz`
   - `openclaw`: `/health` on gateway port

## 6) Validate end-to-end
- Cloudflare Access login works.
- OpenClaw reachable through `rowan-agent` hostname.
- Allowlisted content reachable through `rowan-web` hostname.
- Slack events and replies function.

## Notes
- This stack does not publish host ports by default.
- Keep `compose/.env` local-only and untracked.
- Rotate any previously exposed secrets before cutover.
