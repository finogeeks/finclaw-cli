import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { handle } from "./main";

describe("turn-review", () => {
  it("emits nothing without token", async () => {
    const { stdout } = await handle(
      { turn: { user_text: "q", assistant_text: "a", tools: [] }, model: "m" },
      {},
    );
    assert.equal(stdout, "");
  });

  it("rejects with template reason", async () => {
    const { stdout } = await handle(
      { turn: { user_text: "q", assistant_text: "42", tools: [] }, model: "m" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () =>
        new Response(
          JSON.stringify({
            answers: {
              cites_missing_evidence: { noul: 0.9 },
              contradicts_tools: { noul: 0.1 },
              empty_or_placeholder: { noul: 0.1 },
              severity: { score: 3 },
              verdict: { choice: "reject", confidence: 0.9 },
            },
          }),
          { status: 200 },
        ),
    );
    const j = JSON.parse(stdout);
    assert.equal(j.hookSpecificOutput.decision, "reject");
    assert.equal(
      j.hookSpecificOutput.reason,
      "The answer is not supported by this turn's tool results.",
    );
    assert.ok(!String(j.hookSpecificOutput.reason).includes("42"));
  });

  it("keeps on low confidence", async () => {
    const { stdout } = await handle(
      { turn: { user_text: "q", assistant_text: "a", tools: [] }, model: "m" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () =>
        new Response(
          JSON.stringify({
            answers: {
              cites_missing_evidence: { noul: 0.1 },
              contradicts_tools: { noul: 0.1 },
              empty_or_placeholder: { noul: 0.1 },
              severity: { score: 1 },
              verdict: { choice: "reject", confidence: 0.2 },
            },
          }),
          { status: 200 },
        ),
    );
    assert.equal(stdout, "");
  });

  it("emits nothing when turn is missing", async () => {
    const { stdout } = await handle(
      { model: "m" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
    );
    assert.equal(stdout, "");
  });

  it("emits nothing when the judge fails", async () => {
    let judgeCalled = false;
    const { stdout } = await handle(
      { turn: { user_text: "q", assistant_text: "a", tools: [] }, model: "m" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () => {
        judgeCalled = true;
        return new Response("no", { status: 500 });
      },
    );
    assert.equal(stdout, "");
    assert.equal(judgeCalled, true);
  });
});
