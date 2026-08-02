# Apple Container LAN / WAN-ish lab

Local mimic of FinClaw peer share across machines using [Apple Container](https://github.com/apple/container) on macOS 26+.

Design: Geeksfino/finclaw `docs/superpowers/specs/2026-08-02-a2a-share-lan-wan-test-design.md`.

## Why

Same-host `scripts/03`/`04` with `--relay disabled` is L0. These scripts put **caller** and **callee** in **separate Linux VMs** (each with its own IP).

| Script | Tier | Networks | Relay |
|--------|------|----------|-------|
| `20-l1-lan.sh` | L1 LAN-ish | one (`finclaw-share-lan`) | `disabled` |
| `30-l2-wan-relay.sh` | L2 WAN-ish | two (`…-wan-a`, `…-wan-b`) | `default` |

Binary: Linux from [finogeeks/finclaw-cli Releases](https://github.com/finogeeks/finclaw-cli/releases). On Apple Silicon, defaults to **`aarch64-unknown-linux-gnu`** (native guest). Fallback: `FINCLAW_LINUX_TRIPLE=x86_64-unknown-linux-gnu` with amd64 + Rosetta (needed for releases before linux/aarch64 shipped).

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
