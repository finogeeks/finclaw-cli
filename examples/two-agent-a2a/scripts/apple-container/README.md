# Apple Container LAN / WAN-ish lab

Local mimic of FinClaw peer share across machines using [Apple Container](https://github.com/apple/container) on macOS 26+.

For the product mental model (why redeem opens **caller** localhost, grant bearer vs inbound token, colleague checklist), see [docs/a2a.md](../../../../docs/a2a.md#share-your-agent-with-a-peer-finclaw-share).

## Why

Same-host `scripts/03`/`04` with `--relay disabled` is L0. These scripts put **caller** and **callee** in **separate Linux VMs** (each with its own IP).

| Script | Tier | Networks | Relay |
|--------|------|----------|-------|
| `20-l1-lan.sh` | L1 LAN-ish | one (`finclaw-share-lan`) | `disabled` |
| `30-l2-wan-relay.sh` | L2 WAN-ish | two (`…-wan-a`, `…-wan-b`) | `default` |

Binary: Linux from [finogeeks/finclaw-cli Releases](https://github.com/finogeeks/finclaw-cli/releases). On Apple Silicon, defaults to **`aarch64-unknown-linux-gnu`** (native guest). Fallback: `FINCLAW_LINUX_TRIPLE=x86_64-unknown-linux-gnu` with amd64 + Rosetta (needed for releases before linux/aarch64 shipped).

## How L1/L2 talk (not guest IP HTTP)

Inside the lab, caller and callee do **not** call each other via container IP HTTP.
Callee runs `serve` + `share offer`; caller runs `share redeem` and smokes
**caller-local** `http://127.0.0.1:<ephemeral>` — the same pattern as two real PCs.

This lab intentionally does **not** publish guest ports to the Mac. The host usually
**cannot** `curl http://192.168.x.y:PORT` on Apple Container vmnet IPs. That is not a
failed share; use ticket + redeem instead.

| Want | Do |
|------|-----|
| Automated L1/L2 | Run `20-l1-lan.sh` / `30-l2-wan-relay.sh` |
| Manual host CLI against a live L2 callee | Redeem the lab ticket **on the Mac** (below) |
| Plain HTTP from Mac → guest | Not covered here; would need `-p` / publish (different from P2P share) |

### OrbStack / Docker Desktop note

Runtimes that publish ports (e.g. OrbStack with `-p 28702:28702`) often let the Mac
reach `http://127.0.0.1:28702` with the **inbound** bearer. That exercises **HTTP A2A**,
not peer share. To test share, still use `offer` / `redeem` and the grant bearer on
`local_a2a_base`.

## Prerequisites

- macOS 26+, Apple Silicon, `container` on `PATH` (Homebrew)
- `curl`, `python3`, `shasum`; optional `gh`
- Network access to GitHub Releases + container image registry

## Quick start (L1)

From `examples/two-agent-a2a`:

```bash
bash scripts/apple-container/20-l1-lan.sh
```

This will:

1. `container system start` if needed  
2. Download/verify Linux `finclaw` into `.demo-homes/linux-bin/`  
3. Create network `finclaw-share-lan`  
4. Run callee offer + caller redeem smokes  

## L2 (relay)

```bash
bash scripts/apple-container/30-l2-wan-relay.sh
```

If Apple vmnet still routes between the two nets, L2 may succeed **without** truly forcing relay — then treat L3 (phone hotspot / second PC) as the real WAN proof.

## Host redeem against a live L2 callee

After L2 is up, the offer keeps running in `finclaw-callee-l2` and the ticket is on the
host bind-mount. You can act as a third caller from the Mac:

```bash
# Leave this process running (use a normal Terminal window — agent/CI shells may reap it)
TICKET="$(cat .demo-homes-l2/ticket.txt)"
finclaw share redeem --ticket "$TICKET" --relay default --json
```

Use the printed `local_a2a_base` + `a2a_bearer` (not `DEMO_TOKEN`) with `curl` or
`a2a-agents.yaml`. When redeem exits, the localhost port is gone; redeem again for a
new port. The in-container caller redeem (if still up) is independent.

## L3 checklist (real WAN)

1. Machine A: `00`/`01`, then `SHARE_RELAY=default bash scripts/03-p2p-offer.sh`  
2. Copy `ticket.txt` privately to machine B  
3. Machine B: paste ticket, `SHARE_RELAY=default bash scripts/04-p2p-redeem-smoke.sh`  
4. Record OS, network type (home / hotspot / corporate), and whether it worked  

## Cleanup

```bash
container stop finclaw-callee-l1 finclaw-caller-l1 finclaw-callee-l2 finclaw-caller-l2 2>/dev/null || true
rm -rf .demo-homes .demo-homes-l2
```

## Env overrides

| Var | Default |
|-----|---------|
| `FINCLAW_VERSION` | latest release tag |
| `FINCLAW_LINUX_TRIPLE` | `aarch64-unknown-linux-gnu` on arm64 hosts; else `x86_64-unknown-linux-gnu` |
| `FINCLAW_LINUX_CACHE` | `.demo-homes/linux-bin` |
| `APPLE_CONTAINER_IMAGE` | `ubuntu:24.04` |
| `TWO_AGENT_DEMO_ROOT` | `.demo-homes` (L1) / `.demo-homes-l2` (L2) |
