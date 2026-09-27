import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { asRecord, cap, readStdinJson, toolCommandOrPath } from "./stdin";

describe("readStdinJson", () => {
  it("parses JSON", () => {
    assert.deepEqual(readStdinJson('{"tool_name":"exec"}'), { tool_name: "exec" });
  });

  it("throws on empty input", () => {
    assert.throws(() => readStdinJson("  "));
  });

  it("throws on invalid JSON", () => {
    assert.throws(() => readStdinJson("{"));
  });
});

describe("asRecord", () => {
  it("returns records and rejects arrays", () => {
    assert.deepEqual(asRecord({ value: true }), { value: true });
    assert.deepEqual(asRecord([]), {});
  });
});

describe("cap", () => {
  it("truncates only past the maximum", () => {
    assert.equal(cap("abc", 3), "abc");
    assert.equal(cap("abcd", 3), "abc");
  });
});

describe("toolCommandOrPath", () => {
  it("joins exec argv", () => {
    assert.equal(toolCommandOrPath("exec", { argv: ["echo", "hi"] }, "/ws"), "echo hi");
  });

  it("resolves a write path against cwd", () => {
    assert.equal(
      toolCommandOrPath("write_file", { path: ".env" }, "/ws"),
      "/ws/.env",
    );
  });
});
