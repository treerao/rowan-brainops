#!/usr/bin/env bash
# diagnose-mino-net.sh — fast triage for "Rowan unresponsive / no outbound network" on mino.
#
# Pattern (incident 2026-05-17..25): IPv4 ephemeral-port exhaustion from a flood of stuck
# TIME_WAIT/LAST_ACK sockets. connect() then returns EADDRNOTAVAIL ("Can't assign requested
# address") for ALL new outbound TCP, so the OpenClaw container and the host pipelines lose
# every API call — while ICMP, DNS, and existing SSH keep working (so the host looks "up").
#
# Run ON mino:      bash diagnose-mino-net.sh
# Run from laptop:  ssh rrao@mino 'bash -s' < scripts/diagnose-mino-net.sh
#
# Read-only: it measures and prints a verdict + suggested fixes. It changes nothing.

set -u
export PATH="/opt/homebrew/bin:$PATH"   # docker (Lima) + brew tools are NOT on the non-login PATH

line(){ printf '\n=== %s ===\n' "$1"; }

# Single snapshot of the TCP table — reused everywhere so counts are consistent and cheap.
NS=$(netstat -an -p tcp)
ns(){ printf '%s\n' "$NS"; }

line "host / uptime"
uptime

line "ephemeral port pool"
first=$(sysctl -n net.inet.ip.portrange.first)
last=$(sysctl -n net.inet.ip.portrange.last)
msl=$(sysctl -n net.inet.tcp.msl)
range=$((last - first + 1))
tcp4=$(ns | grep -c 'tcp4')
pct=$(( tcp4 * 100 / range ))
echo "range: $first-$last ($range ports) | net.inet.tcp.msl=$msl"
echo "tcp4 sockets: $tcp4  (pool usage: ${pct}%)"
[ "$pct" -ge 85 ] && echo "!! POOL NEAR/AT EXHAUSTION — new outbound connect() will return EADDRNOTAVAIL"

line "tcp4 state histogram"
for s in ESTABLISHED TIME_WAIT FIN_WAIT_1 FIN_WAIT_2 CLOSE_WAIT LAST_ACK SYN_SENT CLOSING LISTEN; do
  printf '%-12s %s\n' "$s" "$(ns | grep tcp4 | grep -c "$s")"
done
echo "(TIME_WAIT dominant => connection CHURN; CLOSE_WAIT dominant => an app leaking sockets)"

line "outbound TCP test (host)"
hc=$(curl -sS -m 8 -o /dev/null -w '%{http_code}' https://api.openai.com/v1/models 2>/dev/null || true)
if [ -z "$hc" ] || [ "$hc" = "000" ]; then
  echo "host -> api.openai.com : FAILED to connect — suspect EADDRNOTAVAIL / port exhaustion"
  echo "  (sanity: ICMP/DNS likely still fine — that's the tell-tale of port, not link, failure)"
  ping -c 2 -t 5 8.8.8.8 2>&1 | tail -1
else
  echo "host -> api.openai.com : HTTP $hc  (401/200 => egress OK)"
fi

line "top TIME_WAIT destination IPs"
ns | grep TIME_WAIT | awk '{print $5}' | sed 's/\.[0-9]*$//' | sort | uniq -c | sort -rn | head -12

line "top TIME_WAIT destination ports"
ns | grep TIME_WAIT | awk '{print $5}' | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -8
echo "(port 7000 + LAN 192.168.x + link-local fe80 => Continuity/AirPlay = rapportd;"
echo " port 443 spread over many IPs => browser/API client churn)"

line "frozen vs live? (same dest count, 4s apart — identical => wedged residue, a reboot is needed)"
top=$(ns | grep TIME_WAIT | awk '{print $5}' | sed 's/\.[0-9]*$//' | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
if [ -n "${top:-}" ]; then
  a=$(netstat -an -p tcp | grep -c "$top"); sleep 4; b=$(netstat -an -p tcp | grep -c "$top")
  echo "$top : $a then $b"
fi

line "per-process talkers (nettop) — look for high rx_dupe / bytes"
nettop -P -x -l 1 2>/dev/null | head -12

line "live churner catch (5s lsof sample of non-local :443)"
for i in $(seq 1 14); do
  lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | grep ':443' | grep -vE '127.0.0.1|->100\.'
  sleep 0.3
done | awk '{print $1}' | sort | uniq -c | sort -rn | head -6
echo "(empty is common: churn too short-lived to sample, or sockets are frozen residue)"

line "OpenClaw browsers on host (CDP scrapers; run as the user, NOT in the container)"
pgrep -fl 'openclaw/browser' 2>/dev/null | grep -oE 'openclaw/browser/[a-z]+|remote-debugging-port=[0-9]+' | sort | uniq -c

line "OpenClaw container egress + recent errors"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q rowan-openclaw; then
  echo "container -> OpenAI : $(docker exec rowan-openclaw sh -c 'curl -sS -m 8 -o /dev/null -w %{http_code} https://api.openai.com/v1/models' 2>&1)"
  echo "container -> Slack  : $(docker exec rowan-openclaw sh -c 'curl -sS -m 8 https://slack.com/api/api.test' 2>&1)"
  echo "network-connection-error log lines (last 2m): $(docker logs rowan-openclaw --since 2m 2>&1 | grep -ic 'network connection error')"
else
  echo "rowan-openclaw not running"
fi

line "VERDICT"
if [ "$pct" -ge 85 ]; then
cat <<'EOF'
PORT POOL EXHAUSTED — outbound TCP is dead host-wide (container + pipelines).

Immediate relief (needs sudo; runtime-only, reverts on reboot):
  sudo sysctl -w net.inet.ip.portrange.first=16384   # ~49k ephemeral ports of headroom
  sudo sysctl -w net.inet.tcp.msl=1000               # new TIME_WAIT 30s -> 2s
Restart the agent so it drops its poisoned connection pool:
  docker restart rowan-openclaw                       # /opt/homebrew/bin/docker

IMPORTANT:
  * sysctl does NOT drain already-wedged TIME_WAIT sockets. Only a reboot (or 'sudo
    ifconfig en0 down && sudo ifconfig en0 up') flushes them. A reboot also reverts the
    sysctl -w changes automatically.
  * Do NOT set portrange.first back to 49152 until the stuck sockets are flushed, or you
    re-exhaust the (narrower) pool.
  * If port-7000 / LAN / link-local dominate TIME_WAIT, rapportd (Continuity/AirPlay) is a
    source. A headless host doesn't need it — disable AirPlay Receiver + Handoff.
EOF
else
  echo "Port pool OK (${pct}%). If Rowan is still mute, focus on the container:"
  echo "  docker logs rowan-openclaw --tail 30   then   docker restart rowan-openclaw"
fi
