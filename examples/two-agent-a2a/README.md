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

After HTTP (or P2P) is up:

```bash
LLM_PROVIDER=openai LLM_API_KEY=… LLM_MODEL=gpt-4o-mini \
  bash scripts/05-chat-ask-optional.sh
```

For the tunnel path, set `USE_P2P_AGENTS=1` so Caller reads `a2a-agents.p2p.yaml`.

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
