# Bootstrap Checklist (Destination Mac mini)

## Host prep
- [ ] Create dedicated service user (or isolate in Linux VM user).
- [ ] Install Docker + Compose runtime.
- [ ] Create persistent directories and set ownership.

## Config prep
- [ ] Copy `compose/.env.example` to `compose/.env` and set values.
- [ ] Copy `proxy/Caddyfile.example` to `proxy/Caddyfile` and set hostname.
- [ ] Add provider secrets to `compose/.env`.

## Dry run
- [ ] Run `./scripts/preflight.sh`.
- [ ] Run config render check (`docker compose -f compose/docker-compose.yml config` or equivalent).
- [ ] Start stack and verify health endpoint.

## Cutover prep
- [ ] Lower DNS TTL ahead of change window.
- [ ] Define final incremental sync command.
- [ ] Write rollback trigger criteria.
