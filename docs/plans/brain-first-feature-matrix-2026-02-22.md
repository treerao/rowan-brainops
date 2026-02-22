# Brain-First Feature Matrix (from export ingest)

Date: 2026-02-22
Source archive: `/Users/rrao/Downloads/rowan-migration-2026-02-21.tgz`

## Classification

| Legacy feature | Classification | Target tier | Migration approach | Verification |
|---|---|---|---|---|
| Workspace path `/Users/rrao/clawd` | Preserve as-is | Tier 1 | Mount/import workspace content into container runtime path | Open core workflows in new host and compare behavior/output |
| OpenClaw agent defaults/models config | Preserve as-is | Tier 1 | Carry forward model aliases and primary/fallback order | Run model-selection smoke tests |
| Memory search enabled with remote provider | Preserve as-is | Tier 1 | Re-provision provider key and endpoint config in env/secret store | Run memory retrieval/addition test |
| Gateway runtime (port 18789, loopback bind) | Rebuild differently | Tier 2 | Keep internal-only bind in Docker network; no host exposure by default | Confirm service unreachable from host WAN and reachable through ingress path |
| Cloudflare tunnel ingress | Rebuild differently | Tier 2 | Add `cloudflared` service and managed credentials in secret mount | End-to-end access via Access policy passes |
| Slack socket channel plugin | Rebuild differently | Tier 2 | Reconfigure bot/app token injection via env; keep plugin enabled | Slack round-trip test (receive + reply) |
| Browser automation/headless enabled | Rebuild differently | Tier 3 (or 2.5) | Add dedicated stateful browser-worker profile volume | Authenticated replay task succeeds after restart |
| Gateway auth token | Preserve intent, rotate value | Tier 2 | Generate new token and inject via secret env | Unauthorized request denied; authorized request succeeds |
| Skills entries requiring API keys | Preserve intent, rotate values | Tier 2 | Map to env-based secret injection per skill | Skill invocation smoke tests pass |
| Legacy cron hooks | Retire (current export: none) | Tier 3 | Keep disabled unless required by new design | N/A |
| launchd/systemd hooks | Rebuild differently | Tier 3 | Use container restart policy and optional supervisor | Reboot test confirms auto-recovery |

## Notes from ingest
- `crontab.txt` reports no crontab entries.
- `launchd-or-systemd.txt` appears empty in export.
- Runtime inventory indicates local process model with `cloudflared tunnel run rowan`.
