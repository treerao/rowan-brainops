# Incident: mino IPv4 ephemeral-port exhaustion → Rowan unresponsive in Slack

**Date investigated:** 2026-05-25 · **Onset:** 2026-05-17 09:00 PST · **Host:** mino (Mac mini, macOS, 69-day uptime)
**Companion script:** [`scripts/diagnose-mino-net.sh`](../../scripts/diagnose-mino-net.sh)

---

## 1. Summary

Rowan (the OpenClaw agent in the `rowan-openclaw` container on mino) stopped responding in Slack.
Root cause was **not** Rowan, the network link, or iCloud: the macOS **host had exhausted its IPv4
ephemeral port pool** with ~16,600 stuck `TIME_WAIT`/`LAST_ACK` sockets. With no free ephemeral
port, every new outbound `connect()` returned **`EADDRNOTAVAIL` ("Can't assign requested address")**
— so the container's LLM/Slack API calls *and* the host pipelines all failed, while ICMP, DNS, and
existing SSH sessions kept working (which is why the host and container both still looked "healthy").

It had been broken silently for **8 days** (175,038 `network connection error` lines in the
container log, starting the instant the container last booted on 2026-05-17 09:00).

## 2. Impact

- Rowan: no Slack replies for ~8 days; agent stuck in an LLM model-failover retry loop.
- Pipelines: `x-man` ("2 accounts failed") and `tickerwatch` ("fetch failed") — same root cause.
- Container healthcheck reported `healthy` throughout — it does **not** test outbound egress.

## 3. Root cause

| Fact | Value |
|---|---|
| Ephemeral port range | `49152–65535` (16,384 ports) — macOS default |
| tcp4 sockets | **16,602** ≈ the entire range → pool full |
| State | `TIME_WAIT` **15,278** + `LAST_ACK` 1,267 (not `FIN_WAIT_1`, not `CLOSE_WAIT`) |
| Symptom | `connect()` → `EADDRNOTAVAIL`; ICMP/DNS/established TCP unaffected |

`TIME_WAIT` dominance = **connection churn** (sockets opened, used briefly, closed cleanly). The pool
filled faster than ports recycled. The stuck sockets are **kernel-held (no owning process)**, so
`lsof` can't attribute them.

**Churn sources (by destination):**
- **~5k Continuity/AirPlay** — port 7000 + LAN `192.168.68.x` + link-local `fe80::` (AWDL). Owned by
  `rapportd`, which `nettop` showed thrashing (**40,978 duplicate received packets**).
- **~12k cloud:443** — Comcast (`75.75.77.x`), Cloudflare (the ranges that front
  `api.openai.com`/`api.anthropic.com`), Google. By end of incident these were **frozen** (identical
  per-IP counts across many minutes) = wedged residue, not live churn.

**Why it wouldn't self-heal:** the sockets were genuinely wedged — they did **not** drain even after
lowering `net.inet.tcp.msl`, and `rapportd`'s own counters were static at the end. The kernel's
`TIME_WAIT` reaper appears stuck under the socket count. **Only a reboot (or an interface down/up)
flushes them.**

## 4. Diagnosis path (including dead ends, for honesty)

1. Container `Up (healthy)` but every LLM call failing across *all* providers → not model/key, it's egress.
2. Host `ping 8.8.8.8` OK, DNS OK, but TCP:443 fails *instantly* → not the link.
3. `nc` → `EADDRNOTAVAIL` → local source-port allocation failing.
4. tcp4 socket count ≈ ephemeral range size → **port exhaustion** (the real cause).
5. Dead ends corrected along the way:
   - *rapportd-by-count* — early misread of a broken histogram.
   - *iCloud* — wrong: iCloud uses S3 but **Apple isn't a Cloudflare customer**; the Cloudflare IPs
     front the OpenAI/Anthropic APIs.
   - *PMTU black hole* — ruled out: a 1500-byte DF ping to `8.8.8.8` succeeded.
   - *"8,000/s live churn"* — ruled out: destination counts were frozen → wedged residue, not active.

## 5. What we did (in order)

```bash
# (run on mino; sysctl/kill/restart shown — all reversible, sysctl -w reverts on reboot)

# A. Relief: widen the pool + shrink TIME_WAIT lifetime  (needs sudo)
sudo sysctl -w net.inet.tcp.msl=1000                 # TIME_WAIT 30s -> 2s (for NEW sockets)
sudo sysctl -w net.inet.ip.portrange.first=16384     # ~49k ephemeral ports => ~32k free

# B. Verify egress restored
curl -sS -m8 -o /dev/null -w '%{http_code}\n' https://api.openai.com/v1/models    # 401 = OK
/opt/homebrew/bin/docker exec rowan-openclaw sh -c 'curl -sS -m8 https://slack.com/api/api.test'  # {"ok":true}

# C. (Tried) kill the OpenClaw okrasf browser — NOT the culprit, count unchanged
pkill -f "openclaw/browser/okrasf"

# D. Restart the agent so it drops its poisoned connection pool  <-- this is what brought Rowan back
/opt/homebrew/bin/docker restart rowan-openclaw
#   -> logs: "[slack] socket mode connected" + "[delivery-recovery] Recovered delivery ..."
```

**Outcome:** egress restored by (A); Rowan came back online after (D). The ~16k wedged sockets
remain (inert, harmless given the widened pool) pending a reboot.

## 6. Remaining / follow-ups

- [ ] **Reboot mino** — flushes the wedged sockets *and* auto-reverts the runtime `sysctl -w` changes. Clean slate.
- [ ] **Do NOT** set `net.inet.ip.portrange.first` back to `49152` before the reboot, or the (narrower) pool re-exhausts.
- [ ] **Disable Continuity/AirPlay** (not needed on a headless server) to remove the `rapportd` churn source:
  - GUI (via Screen Sharing over Tailscale): System Settings → General → AirDrop & Handoff → **AirPlay Receiver Off**, **Handoff Off**; set **AirDrop = No One**.
  - Immediate CLI (sudo): `sudo killall rapportd` (respawns, but stays quiet once the features above are off). `rapportd` is SIP-protected, so `launchctl bootout/disable` may be refused — use the feature toggles for the durable fix.
- [ ] **Relaunch the `okrasf` OpenClaw browser** (killed during triage) when Rowan next needs that profile.
- [ ] **Add monitoring**: alert when `tcp4` socket count exceeds ~80% of the ephemeral range, or when `rowan-openclaw` logs repeated `network connection error`. (The healthcheck missed 8 days of outage because it doesn't test egress.)

## 7. Investigation command reference

Run from the laptop. **Single-quote the remote command** so the local shell doesn't expand `$5`
etc.; use `bash -lc` or the full `/opt/homebrew/bin/docker` path because `docker` (Lima) is not on
mino's non-login `PATH`.

```bash
# Fastest path: pipe the triage script in
ssh rrao@mino 'bash -s' < scripts/diagnose-mino-net.sh

# The one number that diagnoses it — sockets vs ephemeral range:
ssh rrao@mino 'netstat -an -p tcp | grep -c tcp4; sysctl net.inet.ip.portrange.first net.inet.ip.portrange.last'

# State histogram (TIME_WAIT vs CLOSE_WAIT vs ... ):
ssh rrao@mino 'for s in ESTABLISHED TIME_WAIT FIN_WAIT_1 CLOSE_WAIT LAST_ACK SYN_SENT; do printf "%-12s " "$s"; netstat -an -p tcp | grep tcp4 | grep -c "$s"; done'

# Is outbound actually dead? (EADDRNOTAVAIL on connect):
ssh rrao@mino 'nc -vz -G 4 1.1.1.1 443; curl -sS -m8 -o /dev/null -w "%{http_code}\n" https://api.openai.com/v1/models'

# Where is the churn going (IPs + ports):
ssh rrao@mino 'netstat -an -p tcp | grep TIME_WAIT | awk "{print \$5}" | sed "s/\.[0-9]*$//" | sort | uniq -c | sort -rn | head'
ssh rrao@mino 'netstat -an -p tcp | grep TIME_WAIT | awk "{print \$5}" | sed "s/.*\.//"  | sort | uniq -c | sort -rn | head'

# Per-process talkers + rapportd thrash:
ssh rrao@mino 'nettop -P -x -l 1 2>/dev/null | head -15'

# Container egress + agent state:
ssh rrao@mino '/opt/homebrew/bin/docker exec rowan-openclaw sh -c "curl -sS -m8 -o /dev/null -w %{http_code} https://api.openai.com/v1/models"'
ssh rrao@mino '/opt/homebrew/bin/docker logs rowan-openclaw --tail 20'
```

## 8. Key facts / gotchas (mino)

- **Docker runs via Lima** (`limactl`); binary at `/opt/homebrew/bin/docker`, **not** on the
  non-login SSH `PATH`. Use the full path or `ssh rrao@mino "bash -lc '...'"`.
- **OpenClaw's browsers run on the HOST** as user `rrao`, at `~/.openclaw/browser/{okrasf,treerao}/`
  with CDP on `18800`/`18801` — separate from the `rowan-openclaw` container. (So "10 sockets in the
  container" did not exonerate Rowan's browser tooling; that lives on the host.)
- **Container healthcheck ≠ egress check.** `Up (healthy)` told us nothing about the outage.
- **`sysctl -w` is runtime-only** (reverts on reboot) and does **not** drain already-wedged
  `TIME_WAIT` sockets — a reboot or `ifconfig en0 down/up` does.
- The container recovers only after a **restart** once host egress returns — it caches a poisoned
  connection pool through the outage.
