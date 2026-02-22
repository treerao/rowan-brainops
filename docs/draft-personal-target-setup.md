# Draft: Personal Target Setup (Rao Mac mini)

Working draft for this specific environment:
- Dual-use Mac mini (personal workstation + OpenClaw host).
- OpenClaw currently originates from legacy non-Docker ClawDBot host.
- Access model target: Cloudflare Tunnel + Cloudflare Access.
- Browser automation requirement: Claw browser replay extension and authenticated browsing sessions.

## Target architecture

## Services
- `openclaw` service on internal Docker network.
- `cloudflared` service as outbound tunnel connector.
- Optional `browser-worker` service for stateful automated browsing.

## Network model
- Do not publish OpenClaw app port (`3000`) to host by default.
- Route traffic: user -> Cloudflare Access -> Cloudflare Tunnel -> internal OpenClaw service.
- Keep direct host access disabled except temporary debug windows.

## Identity and access
- Cloudflare Access policies enforce who can reach the app.
- Prefer dedicated automation identities for site logins used by browser tasks.
- Maintain an emergency break-glass admin path documented locally.

## Data and persistence
- OpenClaw data volume: app state, caches, embeddings, local artifacts.
- OpenClaw log volume: runtime and audit-relevant logs.
- Browser profile volume (if browser-worker enabled): session cookies/tokens and profile state.
- Backups must include all persistent volumes, excluding plaintext secret files.

## Browser replay and authenticated web access

## Requirement
Some tasks require logged-in browsing contexts and replayable interaction state.

## Approach
- Run browser automation in a dedicated container profile, not personal macOS Chrome profile.
- Persist browser profile to volume so sessions survive container restarts.
- Support one-time interactive login mode (VNC/noVNC or remote debugging) followed by headless execution.
- Expect periodic re-authentication for MFA/session expiry; track this in runbook.

## Security notes
- Treat browser profile storage as sensitive credential material.
- Restrict file permissions and backup access.
- Use least privilege for automation accounts.

## Required inputs from old host (pending)

## Runtime parity
- Exact OpenClaw image/app version in use.
- Startup command and flags.
- Environment variable names currently required.

## Integrations
- Model/provider endpoints and account dependencies.
- Webhooks, callbacks, and auth integrations.
- Cloudflare tunnel details (tunnel ID/name, ingress mapping, Access policy expectations).

## State paths
- Current data, logs, cache, embeddings/model artifact paths.
- Expected retention and current disk footprint.

## Browser-specific state
- Which sites require authenticated access.
- Whether existing replay extension workflows depend on specific Chrome profile state.
- Re-auth cadence and MFA constraints per site.

## Secrets to re-provision
- Provider API keys/tokens.
- Cloudflare tunnel credentials and Access-related secrets.
- Any webhook signing secrets.
- Any browser automation account credentials (managed outside git).

## Non-goals for first cutover
- No feature upgrades during migration.
- No schema changes unless required for parity.
- No direct public exposure of app container port.

## Acceptance criteria
- OpenClaw reachable only through Cloudflare Access-protected tunnel.
- Core chat/agent workflows match old host behavior.
- Browser replay-dependent tasks run using dedicated persisted browser profile.
- Backup + restore rehearsal succeeds for app and browser state.
- Rollback path to old host validated during cutover window.

## Immediate next steps
1. Run old-host handoff prompt and collect export package.
2. Translate export into concrete `compose/.env` contract and volume mapping.
3. Add `cloudflared` and optional `browser-worker` service definitions to compose.
4. Rehearse cutover with production-like data snapshot.
