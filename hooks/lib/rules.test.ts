import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { decideGateRules } from "./rules";

describe("decideGateRules", () => {
  it("denies rm -rf", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "rm -rf /tmp/x",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("denies write to .env", () => {
    assert.equal(
      decideGateRules({
        toolName: "write_file",
        commandOrPath: "/ws/.env",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("asks on plain echo", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "echo hi",
        cwd: "/ws",
      }),
      "ask",
    );
  });
});
