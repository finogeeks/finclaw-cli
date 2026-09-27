import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { handle } from "./main";

describe("tool-gate", () => {
  it("asks on echo without token", async () => {
    const { stdout } = await handle(
      { tool_name: "exec", tool_input: { command: "echo hi" }, cwd: "/ws" },
      {},
    );
    const j = JSON.parse(stdout);
    assert.equal(j.hookSpecificOutput.permissionDecision, "ask");
  });

  it("denies rm -rf without token", async () => {
    const { stdout } = await handle(
      { tool_name: "exec", tool_input: { command: "rm -rf /" }, cwd: "/ws" },
      {},
    );
    assert.equal(JSON.parse(stdout).hookSpecificOutput.permissionDecision, "deny");
  });

  it("falls back to rules when judge returns 500", async () => {
    const { stdout } = await handle(
      { tool_name: "exec", tool_input: { command: "echo hi" }, cwd: "/ws" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () => new Response("no", { status: 500 }),
    );
    assert.equal(JSON.parse(stdout).hookSpecificOutput.permissionDecision, "ask");
  });

  it("asks when tool_input is empty", async () => {
    const { stdout } = await handle({ tool_name: "exec", tool_input: {}, cwd: "/ws" }, {});
    assert.equal(JSON.parse(stdout).hookSpecificOutput.permissionDecision, "ask");
  });
});
