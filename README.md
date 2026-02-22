# rowan-brainops

Operational playbook and deployment baseline for running Rowan on a containerized OpenClaw host.

## What is implemented now
- Single-instance stack: `openclaw` + `rowan-web` + `cloudflared`.
- Workspace bootstrap for private repo clone (`treerao/rowan`).
- GUI-first secrets workflow and rotation runbooks.
- Migration journal and decision artifacts.

## Deploy path
1. Copy `/Users/rrao/rowan-brainops/compose/.env.example` to `compose/.env` and fill keys.
2. Run `/Users/rrao/rowan-brainops/scripts/prepare-runtime-dirs.sh`.
3. Run `/Users/rrao/rowan-brainops/scripts/bootstrap-workspace.sh`.
4. Complete Cloudflare and Slack portal setup (tokens/routes/policies).
5. Run `/Users/rrao/rowan-brainops/scripts/deploy-up.sh`.
6. Check `/Users/rrao/rowan-brainops/scripts/deploy-status.sh`.

## Core docs
- `/Users/rrao/rowan-brainops/docs/runbooks/single-instance-deploy.md`
- `/Users/rrao/rowan-brainops/docs/runbooks/secrets-workflow-gui-first.md`
- `/Users/rrao/rowan-brainops/docs/runbooks/secret-rotation-checklist-2026-02-22.md`
- `/Users/rrao/rowan-brainops/docs/journal/migration-journal.md`
