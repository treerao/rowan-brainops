# Secrets Workflow (GUI-First, No Terminal)

Date: 2026-02-22

## Goal
Manage OpenClaw secrets without entering secret values in terminal commands or shell history.

## Recommended tools
- Primary: 1Password (or Bitwarden Secrets Manager) as source of truth.
- Runtime: Docker Desktop for service lifecycle controls.
- Local injection: `compose/.env` (untracked, local only).

## Setup pattern
1. Create a vault for this stack (example: `openclaw-prod`).
2. Create one secret per env key in `/Users/rrao/openclaw-macmini-ops/docs/runbooks/env-contract-from-export-2026-02-22.md`.
3. Keep names identical to env keys to reduce mapping errors.
4. Copy values from vault UI into local `compose/.env`.
5. Use Docker Desktop UI to restart services after updates.

## Required safeguards
- `compose/.env` must remain gitignored.
- Do not store secrets in repo docs or JSON manifests.
- Do not paste secrets into chat transcripts.
- Restrict vault access to required identities only.

## Rotation workflow
1. Rotate secret in vault UI.
2. Update local `compose/.env` from vault UI.
3. Restart affected container(s) in Docker Desktop.
4. Run integration checks (Cloudflare, providers, Slack/TG, browser tasks).
5. Revoke old credential once validation passes.
6. Record completion in migration journal.

## Validation checklist
- [ ] All required keys present in vault.
- [ ] `compose/.env` contains current values.
- [ ] Container restart completed.
- [ ] No auth failures in logs after restart.
- [ ] Old credentials revoked.

## Incident handling
If secrets are suspected exposed:
- Rotate impacted credentials immediately in vault.
- Update `compose/.env`.
- Restart affected services.
- Revoke prior credentials.
- Log incident and remediation in journal.
