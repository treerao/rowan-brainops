# Old Host Handoff Prompt

Use this prompt with the previous ClawDBot host to produce a migration inventory and export package.

```text
You are helping migrate this host to a new containerized OpenClaw host.

Goal:
Produce a complete migration inventory + export package from THIS machine, where the service currently runs in a user account (non-Docker).

Rules:
- Do not stop or change running services unless explicitly asked.
- Do not print secret values in chat.
- Redact secrets in any report (show key names only).
- Prefer creating files under ~/claw-migration-export.

Tasks:

1) Create export workspace
- mkdir -p ~/claw-migration-export/{reports,manifests,logs,scripts}

2) Runtime inventory report
Create ~/claw-migration-export/reports/runtime-inventory.md containing:
- Host OS version, hostname, IPs
- OpenClaw/ClawDBot version currently running
- Exact startup method (manual shell, launchd, cron, etc.)
- Exact startup command and working directory
- Process owner and restart behavior
- Listening ports and TLS termination point
- DNS names and current TTLs (if discoverable)

3) Configuration contract (no secret values)
Create ~/claw-migration-export/reports/config-contract.md containing:
- Required env var names
- Config files read at startup (paths)
- External dependencies (LLM provider, webhook endpoints, auth integrations)
- Secret sources (Keychain/file/env), but redact values

4) Data/state inventory
Create ~/claw-migration-export/reports/state-inventory.md containing:
- Data paths, logs, caches, embeddings, model/artifact paths
- File ownership/permissions
- Per-path size and file counts
- Last modified timestamps for key state dirs

5) Startup and scheduler artifacts
Export:
- launchd plists related to claw/openclaw (if present)
- crontab entries for current user
- shell wrappers/scripts used to run service

Store outputs in ~/claw-migration-export/manifests and ~/claw-migration-export/scripts.

6) Migration-safe backup package
Create a timestamped archive of non-secret operational artifacts + state snapshot metadata:
- reports/
- manifests/
- scripts/
- checksums (sha256)
Do NOT include raw secret files unless separately encrypted.
Place archive in ~/claw-migration-export.

7) Final summary in chat
Return:
- Absolute path of export directory
- Absolute path of archive
- Top 10 migration risks discovered
- “Cutover blockers” list (if any)
```
