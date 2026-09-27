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

  it("emits nothing when assistant text is missing", async () => {
    let judgeCalled = false;
    const { stdout } = await handle(
      { turn: { user_text: "q", tools: [] }, model: "m" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () => {
        judgeCalled = true;
        return new Response("unexpected", { status: 500 });
      },
    );
    assert.equal(stdout, "");
    assert.equal(judgeCalled, false);
  });

  it("passes all wire-capped tools and ordered score criteria", async () => {
    const tools = Array.from({ length: 32 }, (_, index) => ({
      name: `tool-${index}`,
      input_summary: `input-${index}`,
      result_summary: `result-${index}`,
    }));
    let requestBody: Record<string, unknown> = {};

    await handle(
      { turn: { user_text: "q", assistant_text: "a", tools }, model: "m" },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async (_url, init) => {
        requestBody = JSON.parse(String(init?.body)) as Record<string, unknown>;
        return new Response(
          JSON.stringify({
            answers: {
              cites_missing_evidence: { noul: 0.1 },
              contradicts_tools: { noul: 0.1 },
              empty_or_placeholder: { noul: 0.1 },
              severity: { score: 0 },
              verdict: { choice: "keep", confidence: 0.9 },
            },
          }),
          { status: 200 },
        );
      },
    );

    const state = requestBody.state as { tools: unknown[] };
    assert.deepEqual(state.tools, tools);
    const questions = requestBody.questions as Record<
      string,
      { type: string; criteria?: string[] }
    >;
    assert.deepEqual(questions.severity.criteria, [
      "0 keep",
      "1 glance",
      "2 reject-likely",
      "3 reject",
    ]);
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
