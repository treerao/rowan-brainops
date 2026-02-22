# Secret Rotation Checklist (2026-02-22)

Use this checklist because exported legacy artifacts included plaintext credential material.

## Objective
Replace legacy-exposed credentials with new values before or during cutover, then verify all critical flows.

## Rotation principles
- Rotate in a controlled order: ingress -> app auth -> providers -> channels -> browser accounts.
- Keep old host available for rollback until new host validation passes.
- Never store secret values in git-tracked files.

## Pre-rotation preparation
- [ ] Create a secure temporary working note outside git for rotation tracking.
- [ ] Enumerate all secret key names from `/Users/rrao/rowan-brainops/docs/runbooks/env-contract-from-export-2026-02-22.md`.
- [ ] Confirm destination secret injection mechanism (`compose/.env` local only, encrypted vault, or secret files).
- [ ] Define cutover window and rollback owner.

## Ordered rotation sequence

## 1) Ingress and edge credentials
- [ ] Rotate Cloudflare tunnel credential/token.
- [ ] Rotate any Cloudflare Access service tokens/client secrets used by this stack.
- [ ] Update destination runtime with new values.
- [ ] Validation: tunnel connects; Access policy still enforces expected identities.

## 2) Internal gateway auth
- [ ] Rotate OpenClaw gateway token.
- [ ] Apply token only on destination runtime first.
- [ ] Validation: unauthorized request rejected; authorized request accepted.

## 3) Provider API credentials
- [ ] Rotate `OPENAI_API_KEY` and related OpenAI skill keys.
- [ ] Rotate `ANTHROPIC_API_KEY`.
- [ ] Rotate memory-search/provider-specific keys (if distinct).
- [ ] Rotate web search API key(s).
- [ ] Validation: model calls, memory search, and web tool calls pass smoke tests.

## 4) Channel credentials
- [ ] Rotate Slack bot token.
- [ ] Rotate Slack app token.
- [ ] Rotate Telegram or other channel tokens/secrets if present.
- [ ] Validation: receive + reply round trip per channel.

## 5) Browser automation credentials
- [ ] Rotate automation account passwords/tokens for logged-in target sites.
- [ ] Re-authenticate dedicated browser profile on new host.
- [ ] Validation: authenticated replay workflow succeeds after container restart.

## 6) Post-rotation cleanup
- [ ] Revoke any superseded tokens/keys still active.
- [ ] Confirm no plaintext secrets in tracked config files.
- [ ] Confirm backups do not include plaintext secret files.

## Verification gates (must pass)
- [ ] Cloudflare ingress healthy.
- [ ] OpenClaw core workflows healthy.
- [ ] Slack/TG integrations healthy.
- [ ] Browser replay workflows healthy.
- [ ] No auth errors in logs for rotated secrets.

## Rollback guidance
- If critical validation fails and quick fix is not possible:
  - [ ] Route traffic back to old host.
  - [ ] Restore previous secret set on old host only if still required.
  - [ ] Continue rotation remediation on new host offline.

## Evidence to record in journal
For each rotated secret class, log:
- timestamp,
- owner,
- systems updated,
- validation result,
- revocation status of old credential.
