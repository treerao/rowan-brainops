# Env Contract from Export (Key Names Only)

Date: 2026-02-22
Source: parsed from export manifests and reports.

## Critical security note
The exported `openclaw.json` currently contains plaintext secret values. Treat archive as sensitive material and rotate exposed credentials before/at cutover.

## Required secret variables (proposed)
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `OPENCLAW_MEMORY_REMOTE_API_KEY`
- `OPENCLAW_WEB_SEARCH_API_KEY`
- `SLACK_BOT_TOKEN`
- `SLACK_APP_TOKEN`
- `OPENCLAW_GATEWAY_TOKEN`
- `NANO_BANANA_PRO_API_KEY`
- `OPENAI_IMAGE_GEN_API_KEY`
- `OPENAI_WHISPER_API_KEY`
- `CLOUDFLARE_TUNNEL_TOKEN` or mounted tunnel credentials file

## Required non-secret variables (proposed)
- `OPENCLAW_WORKSPACE=/Users/rrao/clawd`
- `OPENCLAW_GATEWAY_PORT=18789`
- `OPENCLAW_GATEWAY_BIND=loopback` (or internal-only equivalent in container network)
- `OPENCLAW_BROWSER_ENABLED=true`
- `OPENCLAW_BROWSER_HEADLESS=true`
- `OPENCLAW_SLACK_MODE=socket`
- `OPENCLAW_SLACK_WEBHOOK_PATH=/slack/events`

## Mapping intent
- Keep behavior parity first.
- Move credentials from JSON file into env/secret-injection mechanism.
- Keep git-tracked docs key-names only, never values.

## Validation checklist
- [ ] Every required key above is provisioned in destination secret store.
- [ ] No plaintext keys remain in tracked config.
- [ ] Slack socket auth succeeds.
- [ ] Cloudflare tunnel establishes and Access policy enforces auth.
