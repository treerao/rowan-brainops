# Cutover Checklist from Old-Host Export (2026-02-22)

Based on export summary from legacy host archive:
- `/Users/rrao/claw-migration-export/rowan-migration-2026-02-21.tgz`

## Objective
Execute migration to new containerized host with minimal downtime and a clear rollback path.

## Hard blockers (must clear before cutover)
- [ ] Cloudflare tunnel credentials available on new host.
- [ ] OpenClaw/provider secrets re-provisioned securely.
- [ ] Browser replay path connected on new host (interactive attach done).
- [ ] Required runtime dependencies verified (if any non-container sidecars remain).

## Pre-cutover: ingest and verify export artifacts
- [ ] Extract archive into working folder.
- [ ] Read:
  - `reports/runtime-inventory.md`
  - `reports/config-contract.md`
  - `reports/state-inventory.md`
- [ ] Confirm startup method and restart behavior from `launchd-or-systemd.txt`.
- [ ] Confirm any cron-dependent jobs from `crontab.txt`.
- [ ] Review `manifests/openclaw.json` for key names and integration endpoints (no plaintext secret handling in git).

## Secrets migration matrix
Create `compose/.env` values from secure source (not from git-tracked docs):
- [ ] LLM/provider API keys
- [ ] Cloudflare tunnel credential/token
- [ ] Cloudflare Access/client credentials (if used)
- [ ] Webhook signing secrets
- [ ] Slack/TG channel tokens and signing secrets
- [ ] Browser automation account credentials

Validation rules:
- [ ] Every required key name in `config-contract.md` has a mapped destination variable in `compose/.env`.
- [ ] No secret values committed to repository.
- [ ] Secret rotation plan noted for post-cutover.

## Runtime parity checks
- [ ] Match OpenClaw version first; defer upgrades.
- [ ] Port and ingress mapping consistent with Cloudflare tunnel route.
- [ ] Persistent volume paths mapped and writable by container user.
- [ ] Health endpoint reachable internally.
- [ ] Log path persistent and readable for troubleshooting.

## Browser replay readiness
- [ ] Dedicated automation browser profile volume created.
- [ ] One-time interactive login performed for required sites.
- [ ] Headless replay task tested against authenticated target site.
- [ ] MFA/session refresh procedure documented.

## Channel and integration validation (before traffic flip)
- [ ] Slack event/webhook round-trip test passes.
- [ ] Telegram channel/bot interaction test passes.
- [ ] Any additional callback/webhook targets tested.
- [ ] Verify signature/timestamp validation if enabled.

## Cutover sequence
1. [ ] Lower DNS TTL ahead of window.
2. [ ] Freeze writes on old host.
3. [ ] Final incremental sync of persistent state.
4. [ ] Start new stack and run smoke tests.
5. [ ] Flip Cloudflare tunnel route / DNS target.
6. [ ] Validate user-facing flows and channel integrations.

## Post-cutover 60-minute watch
- [ ] Error rate stable.
- [ ] Auth success stable.
- [ ] No secret/config resolution errors.
- [ ] Browser replay tasks executing.
- [ ] Slack/TG flows stable.

## Rollback triggers
Rollback immediately if any persist beyond agreed threshold:
- Auth failures for critical paths.
- Slack/TG channel failures.
- Browser replay failure on required workflows.
- Elevated 5xx/timeout rates.
- Data/state inconsistency.

## Rollback action
- [ ] Route traffic back to old host.
- [ ] Unfreeze old host writes.
- [ ] Preserve new-host logs and failure snapshot for remediation.
