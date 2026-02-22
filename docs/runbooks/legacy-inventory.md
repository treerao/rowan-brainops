# Legacy Host Inventory (Non-Docker Source)

Goal: capture current runtime behavior before migration.

## Record runtime details
- Binary/app version in use.
- Startup command and working directory.
- launchd/crontab/system hooks that restart it.

## Record configuration
- Environment variables consumed by process.
- Secret source locations (keychain/files/env).
- External dependencies (model providers, webhooks, auth).

## Record persistent state
- Paths for app data, logs, caches, embeddings, and model artifacts.
- Data growth estimate and current disk usage.

## Record network and trust
- Ports currently exposed.
- TLS termination location and cert ownership.
- DNS entries and TTL values.

## Exit criteria
Migration can begin only when all items above are documented and validated by a local restart test on source host.
