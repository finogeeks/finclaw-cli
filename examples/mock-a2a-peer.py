#!/usr/bin/env python3
"""Minimal A2A test peer for finclaw CLI local experiments.

Serves:
  GET  /.well-known/agent-card.json
  POST /a2a/v1  (SendMessage and legacy message/send)

Prints `LISTENING http://127.0.0.1:<port>` when ready. Requires Python 3.9+ (stdlib only).

Usage:
  python3 examples/mock-a2a-peer.py
  python3 examples/mock-a2a-peer.py --port 28765
"""

from __future__ import annotations

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SENTINEL = "A2A-REMOTE-REPLY"


def _make_handler(base_url: str):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_args):
            pass

        def _json(self, code: int, payload: dict):
            body = json.dumps(payload).encode("utf-8")
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path == "/.well-known/agent-card.json":
                self._json(
                    200,
                    {
                        "name": "mock-peer",
                        "description": "local A2A test peer for finclaw CLI",
                        "version": "1.0.0",
                        "supportedInterfaces": [
                            {
                                "url": f"{base_url}/a2a/v1",
                                "protocolBinding": "JSONRPC",
                                "protocolVersion": "1.0",
                            }
                        ],
                        "capabilities": {"streaming": False},
                        "skills": [
                            {
                                "id": "echo",
                                "name": "Echo",
                                "description": "echoes the prompt with a sentinel prefix",
                            }
                        ],
                    },
                )
                return
            self._json(404, {"error": "not found"})

        def do_POST(self):
            length = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(length) if length else b"{}"
            try:
                req = json.loads(raw)
            except json.JSONDecodeError:
                self._json(400, {"error": "bad json"})
                return
            rpc_id = req.get("id")
            method = req.get("method", "")
            if method in ("SendMessage", "message/send"):
                prompt = ""
                try:
                    prompt = req["params"]["message"]["parts"][0]["text"]
                except (KeyError, IndexError, TypeError):
                    prompt = ""
                self._json(
                    200,
                    {
                        "jsonrpc": "2.0",
                        "id": rpc_id,
                        "result": {
                            "role": "agent",
                            "messageId": "fixture-reply-1",
                            "kind": "message",
                            "parts": [
                                {"kind": "text", "text": f"{SENTINEL}: {prompt}"}
                            ],
                        },
                    },
                )
                return
            self._json(
                200,
                {
                    "jsonrpc": "2.0",
                    "id": rpc_id,
                    "error": {"code": -32601, "message": "method not found"},
                },
            )

    return Handler


def main() -> int:
    parser = argparse.ArgumentParser(description="Mock A2A peer for finclaw CLI testing")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=0, help="0 = pick a free port")
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), lambda *a: None)
    host, port = server.server_address
    base_url = f"http://{host}:{port}"
    server.RequestHandlerClass = _make_handler(base_url)

    print(f"LISTENING {base_url}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
