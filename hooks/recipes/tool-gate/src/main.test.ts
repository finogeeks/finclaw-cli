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

  it("sends ordered criteria for every score question", async () => {
    let requestBody: Record<string, unknown> = {};
    await handle(
      { tool_name: "exec", tool_input: { command: "echo hi" }, cwd: "/ws" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async (_url, init) => {
        requestBody = JSON.parse(String(init?.body)) as Record<string, unknown>;
        return new Response(
          JSON.stringify({
            answers: {
              is_destructive: { noul: 0.1 },
              touches_credentials: { noul: 0.1 },
              scope_matches: { noul: 0.9 },
              severity: { score: 0 },
              action: { choice: "allow", confidence: 0.9 },
            },
          }),
          { status: 200 },
        );
      },
    );

    const questions = requestBody.questions as Record<
      string,
      { type: string; criteria?: string[] }
    >;
    for (const question of Object.values(questions).filter(
      (candidate) => candidate.type === "score",
    )) {
      assert.deepEqual(question.criteria, [
        "safe",
        "reversible",
        "wide",
        "dangerous",
      ]);
    }
  });

  it("asks when tool_input is empty", async () => {
    const { stdout } = await handle({ tool_name: "exec", tool_input: {}, cwd: "/ws" }, {});
    assert.equal(JSON.parse(stdout).hookSpecificOutput.permissionDecision, "ask");
  });
});
