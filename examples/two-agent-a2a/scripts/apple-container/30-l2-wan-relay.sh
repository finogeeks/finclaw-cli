#!/usr/bin/env bash
# L2 WAN-ish: two Apple Containers on disjoint nets, SHARE_RELAY=default.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_ROOT="${TWO_AGENT_DEMO_ROOT:-$EXAMPLE_ROOT/.demo-homes-l2}"
NET_A="${APPLE_CONTAINER_WAN_NET_A:-finclaw-share-wan-a}"
NET_B="${APPLE_CONTAINER_WAN_NET_B:-finclaw-share-wan-b}"
IMAGE="${APPLE_CONTAINER_IMAGE:-ubuntu:24.04}"
CALLEE_NAME="${APPLE_CONTAINER_CALLEE:-finclaw-callee-l2}"
CALLER_NAME="${APPLE_CONTAINER_CALLER:-finclaw-caller-l2}"
CALLEE_PORT="${CALLEE_PORT:-28702}"
DEMO_TOKEN="${DEMO_TOKEN:-two-agent-a2a-demo-token-l2}"

bash "$SCRIPT_DIR/10-system-start.sh"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
BIN="$(bash "$SCRIPT_DIR/00-fetch-linux-finclaw.sh" | tail -1)"
[[ -x "$BIN" ]] || {
  echo "error: linux finclaw missing at $BIN" >&2
  exit 1
}

# Match guest arch to the Linux binary (aarch64 native or amd64+Rosetta).
# Word-split is intentional; apple_guest_arch_args emits safe flag tokens only.
# shellcheck disable=SC2206
ARCH_ARGS=($(apple_guest_arch_args "$BIN"))
echo "==> guest arch: ${ARCH_ARGS[*]}"

rm -rf "$DEMO_ROOT"
mkdir -p "$DEMO_ROOT/pids" "$DEMO_ROOT/logs"

for net in "$NET_A" "$NET_B"; do
  if ! container network list 2>/dev/null | grep -qw "$net"; then
    echo "==> container network create $net"
    container network create "$net"
  fi
done

cleanup_containers() {
  for n in "$CALLEE_NAME" "$CALLER_NAME"; do
    container stop "$n" >/dev/null 2>&1 || true
    container delete "$n" >/dev/null 2>&1 || true
  done
}
cleanup_containers

COMMON_MOUNTS=(
  --volume "$EXAMPLE_ROOT:/work/example"
  --volume "$BIN:/usr/local/bin/finclaw:ro"
  --volume "$DEMO_ROOT:/work/demo"
)

apt_bootstrap='apt-get update -qq && apt-get install -y -qq curl python3 ca-certificates >/dev/null'

echo "==> prepare homes (one-shot on net A)"
container run --rm \
  --network "$NET_A" \
  "${ARCH_ARGS[@]}" \
  --cpus 2 \
  --memory 2G \
  "${COMMON_MOUNTS[@]}" \
  -e FINCLAW_BIN=/usr/local/bin/finclaw \
  -e TWO_AGENT_DEMO_ROOT=/work/demo \
  -e CALLEE_PORT="$CALLEE_PORT" \
  -e DEMO_TOKEN="$DEMO_TOKEN" \
  -e DEBIAN_FRONTEND=noninteractive \
  "$IMAGE" \
  bash -lc "$apt_bootstrap && cd /work/example && bash scripts/00-prepare-homes.sh"

echo "==> start callee on $NET_A"
container run -d --rm \
  --name "$CALLEE_NAME" \
  --network "$NET_A" \
  "${ARCH_ARGS[@]}" \
  --cpus 2 \
  --memory 2G \
  "${COMMON_MOUNTS[@]}" \
  -e FINCLAW_BIN=/usr/local/bin/finclaw \
  -e TWO_AGENT_DEMO_ROOT=/work/demo \
  -e CALLEE_PORT="$CALLEE_PORT" \
  -e DEMO_TOKEN="$DEMO_TOKEN" \
  -e SHARE_RELAY=default \
  -e DEBIAN_FRONTEND=noninteractive \
  "$IMAGE" \
  bash -lc "$apt_bootstrap && cd /work/example && bash scripts/01-start-callee.sh && SHARE_RELAY=default bash scripts/03-p2p-offer.sh && sleep infinity"

echo "==> wait for ticket"
ticket="$DEMO_ROOT/ticket.txt"
for _ in $(seq 1 180); do
  [[ -s "$ticket" ]] && break
  sleep 1
done
[[ -s "$ticket" ]] || {
  echo "error: no ticket after callee offer" >&2
  container logs "$CALLEE_NAME" 2>&1 | tail -80 >&2 || true
  exit 1
}

echo "==> start caller on $NET_B (relay default)"
container run -d --rm \
  --name "$CALLER_NAME" \
  --network "$NET_B" \
  "${ARCH_ARGS[@]}" \
  --cpus 2 \
  --memory 2G \
  "${COMMON_MOUNTS[@]}" \
  -e FINCLAW_BIN=/usr/local/bin/finclaw \
  -e TWO_AGENT_DEMO_ROOT=/work/demo \
  -e CALLEE_PORT="$CALLEE_PORT" \
  -e DEMO_TOKEN="$DEMO_TOKEN" \
  -e SHARE_RELAY=default \
  -e DEBIAN_FRONTEND=noninteractive \
  "$IMAGE" \
  bash -lc "$apt_bootstrap && cd /work/example && SHARE_RELAY=default bash scripts/04-p2p-redeem-smoke.sh && touch /work/demo/l2-ok && sleep infinity"

echo "==> wait for L2 success marker"
for _ in $(seq 1 240); do
  if [[ -f "$DEMO_ROOT/l2-ok" ]]; then
    echo "OK L2 Apple Container WAN-ish (relay) smoke"
    echo "  nets:    $NET_A / $NET_B (expect relay)"
    echo "  callee:  $CALLEE_NAME"
    echo "  caller:  $CALLER_NAME"
    echo "  NOTE: if vmnet still routes A↔B, this did not force relay — check share logs / try L3"
    exit 0
  fi
  if ! container list 2>/dev/null | grep -qw "$CALLER_NAME"; then
    break
  fi
  sleep 1
done

echo "error: L2 smoke did not complete" >&2
echo "If isolation failed, record blocker and run L3 (phone hotspot / second LAN)." >&2
container logs "$CALLEE_NAME" 2>&1 | tail -80 >&2 || true
container logs "$CALLER_NAME" 2>&1 | tail -80 >&2 || true
exit 1
