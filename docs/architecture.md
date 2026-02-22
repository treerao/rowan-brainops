# Architecture Options (Mac mini)

## Option A (recommended): Linux VM + Docker Compose
- Isolation: strong
- Reliability: high
- Complexity: medium

Use when the Mac mini is both personal machine and service host.

## Option B: Native macOS Docker Desktop only
- Isolation: medium
- Reliability: medium
- Complexity: low

Use only if you accept tighter coupling to your daily workstation account.

## Baseline controls (both options)
- Dedicated service identity (`openclawsvc`) and least-privilege filesystem paths.
- Reverse proxy terminating TLS.
- Restricted inbound ports.
- Encrypted off-host backups.
- Health checks + restart policies + logs.
