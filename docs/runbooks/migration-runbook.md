# Migration Runbook (Old Mac mini to New Mac mini)

## 1. Inventory source host
- Record app version, startup behavior, and env contract.
- Snapshot config map (without plaintext secrets in docs).
- Record all persistent storage paths.

## 2. Prepare destination host
- Assign stable host identity (IP/DNS).
- Pre-create storage paths.
- Stage secrets and TLS artifacts with restrictive permissions.

## 3. Stage runtime
- Match app and runtime versions first; defer upgrades.
- Pre-pull required container images.
- Restore latest backup to destination volumes.

## 4. Validate in isolation
- Bring up on test endpoint (not production DNS).
- Verify auth, session persistence, health endpoints, and integrations.
- Inspect logs for schema or permission issues.

## 5. Cutover
- Freeze writes on source.
- Perform final incremental sync.
- Switch DNS/proxy upstream to destination.

## 6. Post-cutover
- Watch error rate, auth success, and latency for 30-60 minutes.
- Keep old host intact during rollback window.

## 7. Rollback
Trigger rollback on sustained auth failure, data inconsistency, or elevated 5xx rate against critical flows.
