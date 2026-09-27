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

  it("emits nothing when stdin fields are missing", async () => {
    const { stdout } = await handle({}, { FINCLAW_HOOK_JUDGE_TOKEN: "t" });
    assert.equal(stdout, "");
  });
});
