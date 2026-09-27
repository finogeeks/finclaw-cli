import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { handle } from "./main";

describe("turn-router", () => {
  it("emits nothing without token", async () => {
    const { stdout } = await handle({ prompt: "hi", model: "gpt-4.1" }, {});
    assert.equal(stdout, "");
  });

  it("emits nothing when judge fails", async () => {
    let judgeCalled = false;
    const { stdout } = await handle(
      {
        prompt: "what is 2+2",
        model: "gpt-4.1",
        turn: { user_text: "what is 2+2" },
      },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () => {
        judgeCalled = true;
        return new Response("no", { status: 500 });
      },
    );
    assert.equal(stdout, "");
    assert.equal(judgeCalled, true);
  });

  it("emits cheap id from mapper when judge ok", async () => {
    const { stdout } = await handle(
      {
        prompt: "what is 2+2",
        model: "gpt-4.1",
        turn: { user_text: "what is 2+2" },
      },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () =>
        new Response(
          JSON.stringify({
            answers: {
              lane: { choice: "cheap", confidence: 0.9 },
              simple_lookup: { noul: 0.8 },
              unsafe_or_irreversible: { noul: 0.1 },
              difficulty: { score: 0 },
            },
          }),
          { status: 200 },
        ),
    );
    assert.equal(
      JSON.parse(stdout).hookSpecificOutput.updatedModel,
      "gpt-4.1-mini",
    );
  });

  it("sends the exact router state and ordered score criteria", async () => {
    let requestBody: Record<string, unknown> = {};
    await handle(
      {
        prompt: "what is 2+2",
        model: "gpt-4.1",
        turn: { user_text: "fallback text" },
      },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async (_url, init) => {
        requestBody = JSON.parse(String(init?.body)) as Record<string, unknown>;
        return new Response(
          JSON.stringify({
            answers: {
              lane: { choice: "keep", confidence: 0.9 },
              simple_lookup: { noul: 0.8 },
              unsafe_or_irreversible: { noul: 0.1 },
              difficulty: { score: 0 },
            },
          }),
          { status: 200 },
        );
      },
    );

    assert.deepEqual(requestBody.state, {
      user_ask: "what is 2+2",
      current_model: "gpt-4.1",
      cheap: ["gpt-4.1-mini", "gpt-4o-mini", "gpt-5-mini", "o4-mini"],
      strong: ["gpt-4.1", "gpt-4o", "gpt-5.1", "gpt-5"],
    });
    const questions = requestBody.questions as Record<
      string,
      { type: string; criteria?: string[] }
    >;
    assert.deepEqual(questions.difficulty.criteria, [
      "trivial",
      "moderate",
      "hard",
      "extreme",
    ]);
  });

  it("uses turn user text when prompt is missing", async () => {
    let userAsk = "";
    await handle(
      {
        model: "gpt-4.1",
        turn: { user_text: "fallback text" },
      },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async (_url, init) => {
        const body = JSON.parse(String(init?.body)) as {
          state: { user_ask: string };
        };
        userAsk = body.state.user_ask;
        return new Response(
          JSON.stringify({
            answers: {
              lane: { choice: "keep", confidence: 0.9 },
              simple_lookup: { noul: 0.8 },
              unsafe_or_irreversible: { noul: 0.1 },
              difficulty: { score: 0 },
            },
          }),
          { status: 200 },
        );
      },
    );
    assert.equal(userAsk, "fallback text");
  });

  it("emits nothing when stdin fields are missing", async () => {
    const { stdout } = await handle({}, { FINCLAW_HOOK_JUDGE_TOKEN: "t" });
    assert.equal(stdout, "");
  });

  it("emits a same-provider cheap id for a DeepSeek current model", async () => {
    const { stdout } = await handle(
      {
        prompt: "what is 2+2",
        model: "deepseek-v4-pro",
        turn: { user_text: "what is 2+2" },
      },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () =>
        new Response(
          JSON.stringify({
            answers: {
              lane: { choice: "cheap", confidence: 0.9 },
              simple_lookup: { noul: 0.8 },
              unsafe_or_irreversible: { noul: 0.1 },
              difficulty: { score: 0 },
            },
          }),
          { status: 200 },
        ),
    );
    assert.equal(
      JSON.parse(stdout).hookSpecificOutput.updatedModel,
      "deepseek-v4-flash",
    );
  });

  it("sends only the matching provider lanes to the judge", async () => {
    let requestBody: Record<string, unknown> = {};
    await handle(
      {
        prompt: "what is 2+2",
        model: "deepseek-v4-pro",
        turn: { user_text: "what is 2+2" },
      },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async (_url, init) => {
        requestBody = JSON.parse(String(init?.body)) as Record<string, unknown>;
        return new Response(
          JSON.stringify({
            answers: {
              lane: { choice: "keep", confidence: 0.9 },
              simple_lookup: { noul: 0.8 },
              unsafe_or_irreversible: { noul: 0.1 },
              difficulty: { score: 0 },
            },
          }),
          { status: 200 },
        );
      },
    );
    assert.deepEqual(requestBody.state, {
      user_ask: "what is 2+2",
      current_model: "deepseek-v4-pro",
      cheap: ["deepseek-v4-flash", "deepseek-chat"],
      strong: ["deepseek-v4-pro", "deepseek-reasoner"],
    });
  });

  it("emits nothing when the current model is not in any lane group", async () => {
    const { stdout } = await handle(
      {
        prompt: "what is 2+2",
        model: "unknown-model",
        turn: { user_text: "what is 2+2" },
      },
      { FINCLAW_HOOK_JUDGE_TOKEN: "t" },
      async () =>
        new Response(
          JSON.stringify({
            answers: {
              lane: { choice: "cheap", confidence: 0.9 },
              simple_lookup: { noul: 0.8 },
              unsafe_or_irreversible: { noul: 0.1 },
              difficulty: { score: 0 },
            },
          }),
          { status: 200 },
        ),
    );
    assert.equal(stdout, "");
  });
});
