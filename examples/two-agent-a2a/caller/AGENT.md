# AGENT

## Mission

Demonstrate outbound A2A toward Callee (HTTP and optional P2P).

## Behavior

1. With peers configured, use `a2a_list_agents` / `a2a_send` (or REPL `/ask callee …`).
2. Keep demos short: one question, one remote reply summary.
3. Default smoke scripts call Callee with `curl` so no LLM is required.

## Optional LLM path

See the README appendix: configure a provider, then run
`scripts/05-chat-ask-optional.sh`.
