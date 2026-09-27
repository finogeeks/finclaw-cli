import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  askPreToolUse,
  denyPreToolUse,
  rejectStop,
  routeUpdatedModel,
} from "./honour";

describe("honour output builders", () => {
  it("creates a PreToolUse deny", () => {
    assert.deepEqual(denyPreToolUse("command looks destructive."), {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Refused: command looks destructive.",
      },
    });
  });

  it("creates a PreToolUse ask", () => {
    assert.deepEqual(askPreToolUse(), {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
      },
    });
  });

  it("creates a routed model", () => {
    assert.deepEqual(routeUpdatedModel("gpt-4.1-mini"), {
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        updatedModel: "gpt-4.1-mini",
      },
    });
  });

  it("creates a Stop rejection", () => {
    assert.deepEqual(rejectStop("The answer is unsupported."), {
      hookSpecificOutput: {
        hookEventName: "Stop",
        decision: "reject",
        reason: "The answer is unsupported.",
      },
    });
  });
});
