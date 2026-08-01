#!/usr/bin/env python3
"""Loose smoke assert for an inbound A2A SendMessage JSON-RPC reply.

Accepts current finclaw v1.0 wrapped results and older flat message shapes so
the example stays useful across nearby CLI releases.
"""

from __future__ import annotations

import json
import sys
from typing import Any


def _has_text(obj: Any) -> bool:
    if isinstance(obj, str) and obj.strip():
        return True
    if isinstance(obj, dict):
        return any(_has_text(v) for v in obj.values())
    if isinstance(obj, list):
        return any(_has_text(v) for v in obj)
    return False


def assert_reply(payload: dict[str, Any]) -> None:
    if "error" in payload:
        raise AssertionError(f"expected result, got error: {json.dumps(payload)[:500]}")
    result = payload.get("result")
    if result is None:
        raise AssertionError(f"missing result: {payload!r}")
    if not _has_text(result):
        raise AssertionError(f"result has no text payload: {json.dumps(result)[:500]}")


def main() -> int:
    payload = json.load(sys.stdin)
    assert_reply(payload)
    print("OK A2A SendMessage reply")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"FAIL {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
