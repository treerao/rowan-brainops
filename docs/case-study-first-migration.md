# Case Study: First Migration (User-Session to Containerized Service)

## Starting point
- OpenClaw ran from a personal user account on a Mac mini.
- Runtime behavior depended on local shell/session context.
- Operational state (paths, secrets, restart assumptions) was not fully explicit.

## Problem statement
The setup worked, but was fragile for handoff, migration, or recovery. A host issue or account drift could cause avoidable downtime.

## Approach
1. Document exact legacy behavior before changing anything.
2. Rebuild runtime as explicit Docker Compose services.
3. Isolate through a dedicated runtime boundary (prefer Linux VM on macOS).
4. Add reverse proxy, health checks, and rollback criteria.

## Key decisions
- Do version-matched migration first; postpone upgrades.
- Make storage and secret paths explicit.
- Keep old host warm during rollback window.

## What changed
- Startup became declarative (`compose/docker-compose.yml`).
- Baseline operations became repeatable (runbooks + preflight).
- Cutover became a controlled event, not an ad-hoc switch.

## Immediate benefits
- Lower operational ambiguity.
- Faster recovery and easier host replacement.
- Cleaner path to future sharing or collaboration.

## Next refinements
- Add tested backup/restore scripts.
- Add simple SLO checks (health, auth success, error rate).
- Add one rehearsal migration log with timings.
