export function denyPreToolUse(reason: string): object {
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: `Refused: ${reason}`,
    },
  };
}

export function askPreToolUse(): object {
  return {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
    },
  };
}

export function routeUpdatedModel(modelId: string): object {
  return {
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      updatedModel: modelId,
    },
  };
}

export function rejectStop(reason: string): object {
  return {
    hookSpecificOutput: {
      hookEventName: "Stop",
      decision: "reject",
      reason,
    },
  };
}
