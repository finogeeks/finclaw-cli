# Two-agent A2A demo (HTTP + optional peer share)

**Chinese:** [README.zh.md](README.zh.md)

Run **two** local FinClaw profiles — **Callee** (inbound) and **Caller** (outbound) —
and exercise real **HTTP A2A**, then optionally **peer share** (P2P tunnel to the
same A2A HTTP surface). Default path uses a **mock LLM** and `curl` / small
scripts (no API key).

```text
Caller                         Callee
a2a-agents.yaml  ── HTTP ──►  finclaw serve + a2a-inbound.yaml
                 ── or ──►    share offer ← ticket → share redeem → localhost URL
```

## Prerequisites

- `finclaw` on `PATH` ([installation](../../docs/installation.md))
- `curl`, `python3` (3.9+)
- Peer share scripts need a build that supports `finclaw share` (see
  [docs/a2a.md](../../docs/a2a.md#share-your-agent-with-a-peer-finclaw-share));
  otherwise those steps **skip** cleanly and HTTP still works

## Quick start (same machine)

From this directory:

```bash
bash scripts/00-prepare-homes.sh   # two FINCLAW_HOME trees under .demo-homes/
bash scripts/01-start-callee.sh    # inbound serve (mock LLM)
bash scripts/02-http-smoke.sh      # Agent Card + SendMessage over HTTP
```

Optional P2P (same machine uses `--relay disabled`):

```bash
bash scripts/03-p2p-offer.sh
bash scripts/04-p2p-redeem-smoke.sh
```

Homes default to `examples/two-agent-a2a/.demo-homes/` (gitignored). Override with
`TWO_AGENT_DEMO_ROOT`, `CALLEE_PORT`, `DEMO_TOKEN`, or `FINCLAW_BIN`.

### Two machines

1. On the callee host: prepare + start serve, then
   `SHARE_RELAY=default bash scripts/03-p2p-offer.sh` and send `ticket.txt`
   privately.
2. On the caller host: prepare (caller only is enough if you copy markdown), paste
   the ticket into `.demo-homes/ticket.txt`, then
   `SHARE_RELAY=default bash scripts/04-p2p-redeem-smoke.sh`.

Both sides must stay online while the share runs.

**Agent skill:** [`.cursor/skills/finclaw-share-callee`](../../.cursor/skills/finclaw-share-callee/SKILL.md)
walks through callee setup (example scripts or bare `serve` + `share offer`).

### Apple Container LAN / WAN-ish (one Mac)

Mimic two hosts with Apple Container (Linux guests; prefer published
`aarch64-unknown-linux-gnu`, with amd64+Rosetta fallback for older releases):

```bash
bash scripts/apple-container/20-l1-lan.sh      # one network, --relay disabled
bash scripts/apple-container/30-l2-wan-relay.sh # two nets, --relay default
```

Guests talk via **share offer/redeem** (caller localhost), not host→guest IP HTTP.
After L2 is up you can redeem `.demo-homes-l2/ticket.txt` with host `finclaw` — see
[scripts/apple-container/README.md](scripts/apple-container/README.md). Product
mental model: [docs/a2a.md](../../docs/a2a.md#share-your-agent-with-a-peer-finclaw-share).

## Personas (markdown)

| Role | Files | Intent |
| --- | --- | --- |
| Callee | `callee/IDENTITY.md`, `SOUL.md`, `AGENT.md`, `TOOLS.md` | Answers inbound A2A |
| Caller | `caller/IDENTITY.md`, … | Delegates to peer id `callee` |

`00-prepare-homes.sh` copies these into each profile’s `workspace/`.

## Config templates

| File | Role |
| --- | --- |
| `callee/a2a-inbound.yaml` | Inbound enable + bearer for Caller |
| `caller/a2a-agents.http.yaml` | Outbound peer → `http://127.0.0.1:PORT/a2a/v1` |
| `caller/a2a-agents.p2p.yaml.tmpl` | Filled after redeem with `local_a2a_base` |

## Appendix: real LLM + `/ask`

Published `finclaw` always reads the profile’s `a2a-agents.yaml` (HTTP by
default after `00-prepare-homes.sh`). Peer share is not a separate CLI mode for
chat — after `share redeem`, put the tunnel peer in that same file
(`--write-agents-yaml` or edit), then `/ask` works as usual.

HTTP path (default agents file):

```bash
LLM_PROVIDER=openai LLM_API_KEY=… LLM_MODEL=gpt-4o-mini \
  bash scripts/05-chat-ask-optional.sh
```

Share tunnel (after `03`/`04`; installs `a2a-agents.p2p.yaml` into the default
agents file, same idea as `finclaw share redeem --write-agents-yaml`):

```bash
LLM_PROVIDER=openai LLM_API_KEY=… LLM_MODEL=gpt-4o-mini \
  bash scripts/05-chat-ask-optional.sh --via-share
```

Without a real provider, this script exits with `SKIP`.

## Cleanup

```bash
# stop background serve / offer / redeem if still running
for n in serve-callee share-offer share-redeem; do
  f=.demo-homes/pids/$n.pid
  [[ -f $f ]] && kill "$(cat "$f")" 2>/dev/null || true
done
rm -rf .demo-homes
```

## See also

- [docs/a2a.md](../../docs/a2a.md) — A2A + peer share user guide
- `examples/mock-a2a-peer.py` — outbound-only mock peer (no second finclaw)
