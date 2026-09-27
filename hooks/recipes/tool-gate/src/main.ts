import { askPreToolUse, denyPreToolUse } from "../../../lib/honour";
import {
  callSystemOne,
  DEFAULT_JUDGE_BASE_URL,
  mapGateAnswers,
} from "../../../lib/judge";
import { decideGateRules } from "../../../lib/rules";
import { asRecord, cap, readStdinJson, toolCommandOrPath } from "../../../lib/stdin";

const DEFAULT_JUDGE_MODEL = "jev-latest";

const GATE_QUESTIONS = {
  is_destructive: {
    type: "noul",
    instructions: "Does this action destroy data, system state, or availability?",
  },
  touches_credentials: {
    type: "noul",
    instructions: "Does this action read, write, expose, or alter credentials or secrets?",
  },
  scope_matches: {
    type: "noul",
    instructions: "Does this action stay within the allowed workspace roots?",
  },
  severity: {
    type: "score",
    instructions: "Rate the action severity: safe, reversible, wide, or dangerous.",
  },
  action: {
    type: "choice",
    instructions: "Choose the safest gate action.",
    criteria: {
      allow: "The action is safe, reversible, and in scope.",
      ask: "The action needs human approval.",
      deny: "The action is unsafe or out of scope.",
    },
  },
};

type HandleResult = { stdout: string };
type FetchFn = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

function honour(decision: "deny" | "ask" | "allow"): HandleResult {
  if (decision === "deny") {
    return { stdout: `${JSON.stringify(denyPreToolUse("the tool request is unsafe."))}\n` };
  }
  if (decision === "ask") {
    return { stdout: `${JSON.stringify(askPreToolUse())}\n` };
  }
  return { stdout: "" };
}

function gateState(stdin: Record<string, unknown>, commandOrPath: string, cwd: string): object {
  const turn = asRecord(stdin.turn);
  return {
    tool_name: typeof stdin.tool_name === "string" ? stdin.tool_name : "",
    command_or_path: cap(commandOrPath, 2048),
    cwd,
    user_text: cap(typeof turn.user_text === "string" ? turn.user_text : "", 512),
    allowed_roots: [cwd],
  };
}

export async function handle(
  stdin: object,
  env: NodeJS.ProcessEnv,
  fetchFn: FetchFn = fetch,
): Promise<HandleResult> {
  const input = asRecord(stdin);
  const toolName = typeof input.tool_name === "string" ? input.tool_name : "";
  const cwd = typeof input.cwd === "string" ? input.cwd : "";
  const commandOrPath = toolCommandOrPath(toolName, input.tool_input, cwd);
  const fallback = () =>
    honour(decideGateRules({ toolName, commandOrPath, cwd }));
  const token = env.FINCLAW_HOOK_JUDGE_TOKEN;

  if (!token) {
    return fallback();
  }

  try {
    const decision = mapGateAnswers(
      await callSystemOne({
        token,
        baseUrl: env.FINCLAW_HOOK_JUDGE_BASE_URL ?? DEFAULT_JUDGE_BASE_URL,
        model: env.FINCLAW_HOOK_JUDGE_MODEL ?? DEFAULT_JUDGE_MODEL,
        state: gateState(input, commandOrPath, cwd),
        questions: GATE_QUESTIONS,
        fetchFn: fetchFn as typeof fetch,
        timeoutMs: 8000,
      }),
    );
    return honour(decision);
  } catch {
    return fallback();
  }
}

async function main(): Promise<void> {
  let raw = "";
  process.stdin.setEncoding("utf8");
  for await (const chunk of process.stdin) {
    raw += chunk;
  }

  try {
    process.stdout.write((await handle(asRecord(readStdinJson(raw)), process.env)).stdout);
  } catch {
    process.stdout.write((await handle({}, process.env)).stdout);
  }
}

if (require.main === module) {
  void main();
}
