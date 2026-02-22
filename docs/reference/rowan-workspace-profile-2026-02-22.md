# Rowan Workspace Profile (from treerao/rowan)

Date: 2026-02-22
Source repo: `git@github.com:treerao/rowan.git` (private)
Reference clone path: `/Users/rrao/rowan-reference`

## What this tells us for deployment
- Workspace is content-heavy and markdown-centric.
- Root includes operational instruction files (`AGENTS.md`, `MEMORY.md`, `TOOLS.md`, etc.).
- There is an existing Node/Express-ish serving footprint under `infra/serve/`.
- Workspace includes app/static content directories (`apps/`, `docs/`, `notes/`, `projects/`, `reports/`).

## Implications for container plan
- Mount workspace read-write for OpenClaw core behavior continuity.
- Preserve `.openclaw/workspace-state.json` semantics where relevant.
- Add a dedicated `rowan-web` service to expose selected workspace content safely.
- Keep OpenClaw runtime/config separate from workspace repo state.

## Risks discovered in workspace content
- Repository appears to include sensitive artifacts (example: `projects/linkedin/server-key.pem`, `projects/linkedin/server-cert.pem`).
- Treat workspace clone as sensitive and avoid broad public serving of entire repo tree.

## Recommended serving boundary
- Serve only an allowlisted subpath (for example `apps/`, selected `docs/`), not full workspace root.
- Keep private notes/memory and key-bearing paths excluded from HTTP exposure.
