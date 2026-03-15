# Browser profiles via CDP (recommended)

_Updated: 2026-03-14_

We do **not** mount Chrome profile directories into the OpenClaw container.

Instead, we run **host Chrome instances** with dedicated `--user-data-dir` directories and unique CDP ports. OpenClaw (running in a container) connects **outbound** to those CDP endpoints over the LAN.

## Why this approach

- Copying/mounting Chrome profiles is brittle (locks, encryption, corruption risk).
- CDP is robust for extraction and automation.
- Keeps sensitive browser state on the host.

## Standard profiles

We standardize on exactly two host profiles:

- `okrasf`  → CDP port **18800**
- `treerao` → CDP port **18801**

Each profile uses its own user-data-dir on the host, e.g.:

- `~/.openclaw/browser/okrasf/user-data`
- `~/.openclaw/browser/treerao/user-data`

## Host launch (headed for login)

Launch Chrome on the host with:

- `--remote-debugging-port=<port>`
- `--user-data-dir=<dir>`

After login, you can close the window; cookies persist in the user-data-dir.

## Container access

The container does **not** expose port 18800/18801. It connects outbound to the host IP:

- `http://<host-ip>:18800/json/version`
- `http://<host-ip>:18801/json/version`

Note: using `host.docker.internal` may fail due to Chrome CDP Host-header restrictions; raw IP is most reliable.

## Scripts

For Node scripts that talk to CDP, prefer parameterization:

- `CDP_HTTP=http://<host-ip>:18800` (okrasf)
- `CDP_HTTP=http://<host-ip>:18801` (treerao)

Notes:
- Avoid `host.docker.internal` for CDP in this setup. Chrome CDP can return `500` with: "Host header is specified and is not an IP address or localhost." Raw IP works.
- Rewrite `webSocketDebuggerUrl` host from `127.0.0.1` → `<host-ip>` when connecting from a container.

## Bookmark extraction lessons (2026-03-14)

We hit several reliability problems when extracting X bookmarks via CDP. The fixes are now considered best practice:

- **Reuse an existing bookmarks tab** in the target browser profile when possible.
  - Repeated `PUT /json/new?...bookmarks` creates many identical targets and can cause nondeterministic selection.
- **Hard bounds** on automation loops:
  - `maxScrolls` (e.g. 20)
  - `stableIters` (e.g. 4 consecutive scrolls with 0 new URLs)
  - `maxSeconds` wall-clock (e.g. 60s)
- **Progress logging** every ~10 scrolls so “looks stuck” is distinguishable from “actually stuck”.
- **Close CDP WebSocket** at end of extraction so the Node process exits.
- Prefer extracting tweet permalinks via `main article` + `time` anchor and canonicalize:
  - strip `/analytics`, `/photo/*`, and query params.

## Relationship to OpenClaw "browser" tool

There are two browser-control methods:

1) OpenClaw browser tool / CLI (`openclaw browser ...`): more layers, historically worked but can be sensitive to gateway timeouts and tab lifecycles.
2) Direct CDP to host Chrome (`CDP_HTTP=http://<host-ip>:<port>`): fewer layers and more diagnosable in a containerized deployment.
