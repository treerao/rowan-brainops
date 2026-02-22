# Brain Boundary and Backup Model

Date: 2026-02-22

## Purpose
Define what counts as the "brain" for recovery and what belongs to runtime operations.

## Layer 1: GitHub-backed brain (versioned content)
Primary source:
- Workspace repository (legacy path signal: `/Users/rrao/clawd`).

Typically includes:
- prompts, instructions, notes, docs, workflows,
- task artifacts and domain knowledge content,
- code and scripts that encode behavior.

Recovery method:
- `git clone` / `git pull` to restore exact content history.

## Layer 2: Runtime brain extension (stateful behavior)
Not fully represented in workspace git repo.

Includes:
- OpenClaw runtime config/state (`~/.openclaw/...`),
- memory/search runtime settings,
- channel wiring and plugin toggles,
- browser automation profile state (cookies/session).

Recovery method:
- restore from secure backup snapshots,
- re-apply env contract and non-secret config,
- run parity checks.

## Layer 3: Secrets and trust material
Never store in git.

Includes:
- provider API keys/tokens,
- Cloudflare tunnel and Access credentials,
- Slack/TG tokens,
- gateway auth tokens,
- browser automation account credentials.

Recovery method:
- re-provision from secret manager/secure store,
- rotate as needed,
- verify with integration smoke tests.

## Practical rule
GitHub backup alone protects core content, but full service recovery requires all 3 layers.

## Minimum viable recovery checklist
- [ ] Restore workspace repo content (Layer 1).
- [ ] Restore runtime state/config needed for behavior parity (Layer 2).
- [ ] Re-provision and validate secrets (Layer 3).
- [ ] Run Tier 1/Tier 2 parity tests before declaring recovery complete.

## Recommended backup cadence
- Layer 1: continuous via git commits + remote push.
- Layer 2: scheduled encrypted snapshots.
- Layer 3: managed secret store with versioning/rotation policy.
