import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  callSystemOne,
  mapGateAnswers,
  mapReviewAnswers,
  mapRouterAnswers,
} from "./judge";

describe("mapGateAnswers", () => {
  it("denies on destructive noul", () => {
    assert.equal(
      mapGateAnswers({
        is_destructive: { noul: 0.8 },
        touches_credentials: { noul: 0.1 },
        scope_matches: { noul: 0.9 },
        severity: { score: 1 },
        action: { choice: "allow", confidence: 0.9 },
      }),
      "deny",
    );
  });

  it("asks on low action confidence", () => {
    assert.equal(
      mapGateAnswers({
        is_destructive: { noul: 0.1 },
        touches_credentials: { noul: 0.1 },
        scope_matches: { noul: 0.9 },
        severity: { score: 0 },
        action: { choice: "allow", confidence: 0.2 },
      }),
      "ask",
    );
  });

  it("denies destructive work despite low action confidence", () => {
    assert.equal(
      mapGateAnswers({
        is_destructive: { noul: 0.8 },
        touches_credentials: { noul: 0.1 },
        scope_matches: { noul: 0.9 },
        severity: { score: 0 },
        action: { choice: "allow", confidence: 0.2 },
      }),
      "deny",
    );
  });
});

describe("mapRouterAnswers", () => {
  const routes = { cheap: ["gpt-4.1-mini"], strong: ["gpt-4.1"] };

  it("emits nothing on keep", () => {
    assert.equal(
      mapRouterAnswers(
        {
          lane: { choice: "keep", confidence: 0.9 },
          simple_lookup: { noul: 0.1 },
          unsafe_or_irreversible: { noul: 0.1 },
          difficulty: { score: 2 },
        },
        routes,
        "gpt-4.1",
      ),
      null,
    );
  });

  it("emits first cheap id", () => {
    assert.equal(
      mapRouterAnswers(
        {
          lane: { choice: "cheap", confidence: 0.8 },
          simple_lookup: { noul: 0.2 },
          unsafe_or_irreversible: { noul: 0.1 },
          difficulty: { score: 1 },
        },
        routes,
        "gpt-4.1",
      ),
      "gpt-4.1-mini",
    );
  });

  it("emits nothing when cheap is empty", () => {
    assert.equal(
      mapRouterAnswers(
        {
          lane: { choice: "cheap", confidence: 0.8 },
          simple_lookup: { noul: 0.2 },
          unsafe_or_irreversible: { noul: 0.1 },
          difficulty: { score: 1 },
        },
        { cheap: [], strong: [] },
        "gpt-4.1",
      ),
      null,
    );
  });
});

describe("mapReviewAnswers", () => {
  it("rejects on missing evidence", () => {
    assert.equal(
      mapReviewAnswers({
        cites_missing_evidence: { noul: 0.8 },
        contradicts_tools: { noul: 0.1 },
        empty_or_placeholder: { noul: 0.1 },
        severity: { score: 1 },
        verdict: { choice: "keep", confidence: 0.9 },
      }),
      "reject",
    );
  });

  it("keeps on low verdict confidence", () => {
    assert.equal(
      mapReviewAnswers({
        cites_missing_evidence: { noul: 0.1 },
        contradicts_tools: { noul: 0.1 },
        empty_or_placeholder: { noul: 0.1 },
        severity: { score: 1 },
        verdict: { choice: "reject", confidence: 0.2 },
      }),
      "keep",
    );
  });
});

describe("callSystemOne", () => {
  it("posts the expected request and returns answers", async () => {
    let requestedUrl = "";
    let requestedAuthorization = "";
    const answers = { action: { choice: "allow", confidence: 0.9 } };

    const result = await callSystemOne({
      token: "t",
      baseUrl: "https://api.typesafe.ai",
      model: "test-model",
      state: { test: true },
      questions: {
        action: {
          type: "choice",
          instructions: "Choose.",
          criteria: { allow: "Allow." },
        },
      },
      fetchFn: (async (url, init) => {
        requestedUrl = String(url);
        requestedAuthorization = new Headers(init?.headers).get("Authorization") ?? "";
        return new Response(JSON.stringify({ answers }), { status: 200 });
      }) as typeof fetch,
      timeoutMs: 8000,
    });

    assert.equal(requestedUrl, "https://api.typesafe.ai/v1/systemone");
    assert.equal(requestedAuthorization, "Bearer t");
    assert.deepEqual(result, answers);
  });

  it("throws on a non-success response", async () => {
    await assert.rejects(
      callSystemOne({
        token: "t",
        baseUrl: "https://api.typesafe.ai",
        model: "test-model",
        state: {},
        questions: {},
        fetchFn: (async () => new Response("nope", { status: 500 })) as unknown as typeof fetch,
        timeoutMs: 8000,
      }),
    );
  });
});
