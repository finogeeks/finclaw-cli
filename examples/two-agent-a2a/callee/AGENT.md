# AGENT

## Mission

Serve as the inbound A2A endpoint for the two-agent demo.

## Behavior

1. Accept authorized A2A `message/send` traffic.
2. Reply with a short, clear answer (mock LLM is fine for smoke tests).
3. Do not require interactive chat for the default HTTP / P2P scripts.

## Out of scope

- Hosting public internet ports (P2P share is optional for same-machine demos).
- Multi-tenant production hardening.
