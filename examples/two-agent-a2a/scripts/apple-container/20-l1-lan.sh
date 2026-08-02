#!/usr/bin/env bash
# L1 LAN-ish: two Apple Containers on one vmnet, SHARE_RELAY=disabled.
# Downloads linux/x86_64 finclaw from finogeeks/finclaw-cli; runs under Rosetta.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEMO_ROOT="${TWO_AGENT_DEMO_ROOT:-$EXAMPLE_ROOT/.demo-homes}"
NET_NAME="${APPLE_CONTAINER_LAN_NET:-finclaw-share-lan}"
IMAGE="${APPLE_CONTAINER_IMAGE:-ubuntu:24.04}"
CALLEE_NAME="${APPLE_CONTAINER_CALLEE:-finclaw-callee-l1}"
CALLER_NAME="${APPLE_CONTAINER_CALLER:-finclaw-caller-l1}"
CALLEE_PORT="${CALLEE_PORT:-28701}"
DEMO_TOKEN="${DEMO_TOKEN:-two-agent-a2a-demo-token}"

bash "$SCRIPT_DIR/10-system-start.sh"
BIN="$(bash "$SCRIPT_DIR/00-fetch-linux-finclaw.sh" | tail -1)"
[[ -x "$BIN" ]] || {
  echo "error: linux finclaw missing at $BIN" >&2
  exit 1
}

rm -rf "$DEMO_ROOT/callee" "$DEMO_ROOT/caller" "$DEMO_ROOT/pids" "$DEMO_ROOT/logs" "$DEMO_ROOT/ticket.txt" "$DEMO_ROOT/l1-ok" "$DEMO_ROOT/env.sh"
mkdir -p "$DEMO_ROOT/pids" "$DEMO_ROOT/logs"

if ! container network list 2>/dev/null | grep -qw "$NET_NAME"; then
  echo "==> container network create $NET_NAME"
  container network create "$NET_NAME"
fi

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

guest_base=(
  container run --rm
  --arch amd64
  --rosetta
  --cpus 2
  --memory 2G
  "${COMMON_MOUNTS[@]}"
  -e FINCLAW_BIN=/usr/local/bin/finclaw
  -e TWO_AGENT_DEMO_ROOT=/work/demo
  -e CALLEE_PORT="$CALLEE_PORT"
  -e DEMO_TOKEN="$DEMO_TOKEN"
  -e SHARE_RELAY=disabled
  -e DEBIAN_FRONTEND=noninteractive
)

apt_bootstrap='apt-get update -qq && apt-get install -y -qq curl python3 ca-certificates >/dev/null'

echo "==> prepare homes (one-shot)"
"${guest_base[@]}" --network "$NET_NAME" "$IMAGE" \
  bash -lc "$apt_bootstrap && cd /work/example && bash scripts/00-prepare-homes.sh"

echo "==> start callee container ($CALLEE_NAME)"
container run -d --rm \
  --name "$CALLEE_NAME" \
  --network "$NET_NAME" \
  --arch amd64 \
  --rosetta \
  --cpus 2 \
  --memory 2G \
  "${COMMON_MOUNTS[@]}" \
  -e FINCLAW_BIN=/usr/local/bin/finclaw \
  -e TWO_AGENT_DEMO_ROOT=/work/demo \
  -e CALLEE_PORT="$CALLEE_PORT" \
  -e DEMO_TOKEN="$DEMO_TOKEN" \
  -e SHARE_RELAY=disabled \
  -e DEBIAN_FRONTEND=noninteractive \
  "$IMAGE" \
  bash -lc "$apt_bootstrap && cd /work/example && bash scripts/01-start-callee.sh && bash scripts/03-p2p-offer.sh && sleep infinity"

echo "==> wait for ticket"
ticket="$DEMO_ROOT/ticket.txt"
for _ in $(seq 1 180); do
  if [[ -s "$ticket" ]]; then
    break
  fi
  sleep 1
done
[[ -s "$ticket" ]] || {
  echo "error: no ticket after callee offer" >&2
  container logs "$CALLEE_NAME" 2>&1 | tail -80 >&2 || true
  exit 1
}
echo "OK ticket ready ($(wc -c <"$ticket") bytes)"

echo "==> start caller container ($CALLER_NAME)"
container run -d --rm \
  --name "$CALLER_NAME" \
  --network "$NET_NAME" \
  --arch amd64 \
  --rosetta \
  --cpus 2 \
  --memory 2G \
  "${COMMON_MOUNTS[@]}" \
  -e FINCLAW_BIN=/usr/local/bin/finclaw \
  -e TWO_AGENT_DEMO_ROOT=/work/demo \
  -e CALLEE_PORT="$CALLEE_PORT" \
  -e DEMO_TOKEN="$DEMO_TOKEN" \
  -e SHARE_RELAY=disabled \
  -e DEBIAN_FRONTEND=noninteractive \
  "$IMAGE" \
  bash -lc "$apt_bootstrap && cd /work/example && bash scripts/04-p2p-redeem-smoke.sh && touch /work/demo/l1-ok && sleep infinity"

echo "==> wait for L1 success marker"
for _ in $(seq 1 180); do
  if [[ -f "$DEMO_ROOT/l1-ok" ]]; then
    echo "OK L1 Apple Container LAN-ish smoke"
    echo "  network:  $NET_NAME"
    echo "  callee:   $CALLEE_NAME"
    echo "  caller:   $CALLER_NAME"
    echo "  finclaw:  $(cat "$(dirname "$BIN")/VERSION" 2>/dev/null || echo linux)"
    echo "  (leave containers running to inspect; stop with: container stop $CALLEE_NAME $CALLER_NAME)"
    exit 0
  fi
  if ! container list 2>/dev/null | grep -qw "$CALLER_NAME"; then
    break
  fi
  sleep 1
done

echo "error: L1 smoke did not complete" >&2
echo "--- callee logs ---" >&2
container logs "$CALLEE_NAME" 2>&1 | tail -100 >&2 || true
echo "--- caller logs ---" >&2
container logs "$CALLER_NAME" 2>&1 | tail -100 >&2 || true
exit 1
