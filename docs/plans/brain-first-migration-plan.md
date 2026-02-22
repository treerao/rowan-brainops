# Brain-First Migration Plan

Date: 2026-02-22
Owner: Rao

## Strategy statement
Migrate the core "brain" first (workspace repository, behavior-defining config, essential state), then re-implement host/runtime/integration capabilities intentionally for a containerized home.

Old-host inventory is treated as requirements signal, not as a one-to-one implementation blueprint.

## Goals
- Preserve core behavior and knowledge continuity.
- Reduce accidental coupling to user-session host mechanics.
- Improve reliability and security through container-native design.

## Non-goals (phase 1)
- No broad feature upgrades during initial parity.
- No forced reproduction of legacy operational quirks.
- No direct public exposure of internal app ports.

## Three-tier execution model

## Tier 1: Core brain migration (must preserve)
Scope:
- Workspace repo/content.
- Core persistent state required for behavior continuity.
- Prompt/system configuration and key behavioral contracts.

Exit criteria:
- Core workflows execute with parity in new environment.
- No missing essential state for main use cases.

## Tier 2: Compatibility bridge (minimum viable integrations)
Scope:
- Minimal secrets/env mapping for required providers.
- Slack/TG baseline connectivity and smoke tests.
- Basic ingress path through Cloudflare Access/Tunnel.

Exit criteria:
- Critical channels operational.
- Authentication and callback flows pass verification checks.

## Tier 3: Intentional re-architecture (improvements)
Scope:
- Browser replay with dedicated persisted automation profile.
- Compose-native scheduling/ops controls replacing ad-hoc host jobs.
- Backup/restore rehearsal and monitoring hardening.

Exit criteria:
- Reduced operational ambiguity versus legacy host.
- Documented recovery and rollback confidence.

## Decision matrix template (apply per legacy feature)
For each item from old-host inventory, classify:
- `Preserve as-is` (must keep behavior exactly)
- `Rebuild differently` (same outcome, better implementation)
- `Defer` (not required for phase 1 cutover)
- `Retire` (no longer needed)

Per-item fields:
- Legacy feature
- Current value to workflows
- Risk if omitted at cutover
- New implementation choice
- Owner
- Target tier
- Verification test

## Initial classification from current signals
- Core OpenClaw behavior/state: `Preserve as-is` -> Tier 1
- Slack/TG channels: `Rebuild differently` (containerized env + explicit callbacks) -> Tier 2
- Cloudflare access path: `Rebuild differently` (tunnel-first, no host port exposure) -> Tier 2
- Browser replay extension workflow: `Rebuild differently` (dedicated browser-worker profile) -> Tier 3 (or Tier 2.5 if mission-critical)
- Legacy cron/launch hooks: `Retire or Rebuild differently` (compose/job runner) -> Tier 3

## Risks and controls
- Risk: Hidden dependency in legacy shell/dotfiles.
  - Control: strict inventory + explicit env contract.
- Risk: Secret gaps during bootstrap.
  - Control: secrets matrix and pre-cutover completeness check.
- Risk: Browser-auth fragility.
  - Control: dedicated profile persistence + re-auth runbook.

## Cutover readiness gate
Proceed only when all are true:
- Tier 1 parity tests pass.
- Tier 2 integration smoke tests pass.
- Rollback triggers and path are explicitly documented.

## Next actions
1. Parse old-host export into per-feature decision matrix.
2. Produce concrete `compose/.env` contract and integration map.
3. Define Tier 1 parity test script/checklist.
