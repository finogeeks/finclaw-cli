---
name: finclaw-share-callee
description: >-
  Set up a FinClaw peer-share callee (inbound serve + share offer) and produce a
  ticket for a remote caller. Use when the user wants to act as callee, offer a
  share ticket, run examples/two-agent-a2a offer scripts, configure a2a-inbound
  for share, or help a colleague redeem against their agent.
---

# FinClaw share callee setup

Help the user run as a **callee**: local inbound A2A + `finclaw share offer`, then
hand a **ticket** to a caller. Do not invent transport details; follow
[docs/a2a.md](../../../docs/a2a.md) (Share section) and this skill.

**Working directory:** `finclaw-cli` repo root (or a checkout that contains
`examples/two-agent-a2a/`).

## Mental model (tell the user if confused)

| Process | Must stay running | Role |
|---------|-------------------|------|
| `finclaw serve` | Yes | Real inbound A2A |
| `finclaw share offer` | Yes | Publishes ticket; dials local serve with **inbound** bearer |
| Caller `share redeem` | On **their** machine | Opens **their** `127.0.0.1` proxy; uses **grant** `a2a_bearer` |

Caller does **not** need the callee’s LAN/container IP for the share path.
`--bearer` on offer = inbound token from `a2a-inbound.yaml`, **not** the grant.

## Path A — example scripts (preferred for a quick test)

From `examples/two-agent-a2a/`:

```bash
bash scripts/00-prepare-homes.sh
bash scripts/01-start-callee.sh
# Same machine / L0:
bash scripts/03-p2p-offer.sh
# Different network / real remote caller:
SHARE_RELAY=default bash scripts/03-p2p-offer.sh
```

Then:

1. Confirm offer is alive (pid under `.demo-homes/pids/share-offer.pid`, or logs).
2. Read `.demo-homes/ticket.txt` (or `$TWO_AGENT_DEMO_ROOT/ticket.txt`).
3. Tell the user to send that ticket **privately** to the caller.
4. Leave serve + offer running until the test ends.

Caller side (for the user’s instructions to their peer):

```bash
finclaw share redeem --ticket '<paste>' --relay default --json
# keep running; use local_a2a_base + a2a_bearer (or --write-agents-yaml)
```

Or, if they have the example tree: paste ticket into `.demo-homes/ticket.txt` and
`SHARE_RELAY=default bash scripts/04-p2p-redeem-smoke.sh`.

Inbound demo token for Path A is `DEMO_TOKEN` from `.demo-homes/env.sh` (set by
`00-prepare-homes.sh`). Offer already uses it; do not send `DEMO_TOKEN` to the
caller — only the ticket.

## Path B — bare host (production-shaped)

1. Ensure `finclaw share status` works (share-enabled binary, v0.11+ releases).
2. Create/edit inbound config:

   `~/.finclaw/profiles/default/runtime_home/config/a2a-inbound.yaml`

   Set `enabled: true`, card fields, and a peer with `auth_token` or
   `auth_token_env` (user-chosen secret). See docs/a2a.md inbound example.
3. Start serve (note `PORT`):

```bash
finclaw serve --port PORT
```

4. In a **separate long-lived terminal** (not a short-lived agent shell):

```bash
finclaw share offer \
  --upstream "http://127.0.0.1:PORT" \
  --bearer "$INBOUND_TOKEN" \
  --relay default \
  --json
```

5. Copy the JSON `ticket` field; send privately.
6. Keep both processes up. On stop, tell callers their localhost peer URLs are stale.

Use `--relay disabled` only on trusted LAN/VPN when both sides agree.

## Agent checklist

- [ ] `finclaw share status` (or example scripts) confirms share is available
- [ ] Inbound configured; serve reachable at upstream card URL
- [ ] Offer running; ticket written / shown
- [ ] User knows to keep offer+serve up and to send **ticket only**
- [ ] User has caller redeem one-liner + grant-bearer reminder
- [ ] Cross-network: both sides `--relay default` (or same custom relay)

## Verification (optional, same machine)

With offer still up, in another terminal:

```bash
finclaw share redeem --ticket "$(cat examples/two-agent-a2a/.demo-homes/ticket.txt)" --relay disabled --json
# curl local_a2a_base/.well-known/agent-card.json with Authorization: Bearer <a2a_bearer>
```

For Apple Container L2 host redeem against a lab callee, see
`examples/two-agent-a2a/scripts/apple-container/README.md`.

## Cleanup

- Ctrl-C offer and serve, or stop example pidfiles under `.demo-homes/pids/`.
- Apple Container lab: see apple-container README cleanup.
- Do not commit `.demo-homes/` / tickets / grant bearers.

## See also

- [docs/a2a.md](../../../docs/a2a.md) — Share mental model, colleague checklist, troubleshooting
- [docs/a2a.zh.md](../../../docs/a2a.zh.md) — Chinese
- [examples/two-agent-a2a/README.md](../../../examples/two-agent-a2a/README.md)
- Companion caller flow is redeem-only; no separate skill required for MVP
