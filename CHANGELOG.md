# Changelog

Notable changes to this personal operations playbook.

## [Unreleased]
### Added
- Baseline runbooks and runtime templates for migrating OpenClaw from user-session execution to containerized hosting on Mac mini.
- Upgrade runbook: dry-run `config validate` against the new image before touching prod, and a `security audit` step.

### Changed
- OpenClaw upgraded 2026.3.28 → 2026.7.1; Slack now an external `@openclaw/slack` plugin; primary model → `openai/gpt-5.6-luna`.
- Upgrade backups widened from `openclaw.json` to the whole config dir — upgrades migrate cron and Memory Core state.

### Fixed
- OpenClaw credentials dir was world-writable (777) since 2026-02-22; hardened to 700/600. Must be fixed host-side — the container cannot `chmod` across a macOS bind mount, so it never self-heals.
