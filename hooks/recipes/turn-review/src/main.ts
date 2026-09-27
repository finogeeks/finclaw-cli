import { rejectStop } from "../../../lib/honour";
import {
  callSystemOne,
  DEFAULT_JUDGE_BASE_URL,
  mapReviewAnswers,
} from "../../../lib/judge";
import { asRecord, cap, readStdinJson } from "../../../lib/stdin";

const DEFAULT_JUDGE_MODEL = "jev-latest";

export const REJECT_REASON_EVIDENCE =
  "The answer is not supported by this turn's tool results.";
export const REJECT_REASON_EMPTY = "The answer is empty or a placeholder.";

const REVIEW_QUESTIONS = {
  cites_missing_evidence: {
    type: "noul",
    instructions: "Does the answer cite facts not supported by the tool results?",
  },
  contradicts_tools: {
    type: "noul",
    instructions: "Does the answer contradict the tool results?",
  },
  empty_or_placeholder: {
    type: "noul",
    instructions: "Is the answer empty or only a placeholder?",
  },
  severity: {
    type: "score",
    instructions: "Rate the severity of any answer quality problem.",
  },
  verdict: {
    type: "choice",
    instructions: "Choose whether to keep or reject this answer.",
    criteria: {
      keep: "The answer is supported by the turn's tool results.",
      reject: "The answer must not be delivered.",
    },
  },
};

type HandleResult = { stdout: string };
type FetchFn = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;

function reviewState(input: Record<string, unknown>): object | null {
  const turn = asRecord(input.turn);
  if (Object.keys(turn).length === 0) {
    return null;
  }

  return {
    model: typeof input.model === "string" ? input.model : "",
    user_text: cap(typeof turn.user_text === "string" ? turn.user_text : "", 2048),
    assistant_text: cap(typeof turn.assistant_text === "string" ? turn.assistant_text : "", 8192),
    tools: Array.isArray(turn.tools) ? turn.tools.slice(0, 16) : [],
  };
}

function rejectReason(answers: Parameters<typeof mapReviewAnswers>[0]): string {
  const emptyOrPlaceholder = answers.empty_or_placeholder;
  if (
    emptyOrPlaceholder &&
    "noul" in emptyOrPlaceholder &&
    Number.isFinite(emptyOrPlaceholder.noul) &&
    emptyOrPlaceholder.noul >= 0.75
  ) {
    return REJECT_REASON_EMPTY;
  }
  return REJECT_REASON_EVIDENCE;
}

export async function handle(
  stdin: object,
  env: NodeJS.ProcessEnv,
  fetchFn: FetchFn = fetch,
): Promise<HandleResult> {
  const token = env.FINCLAW_HOOK_JUDGE_TOKEN;
  if (!token) {
    return { stdout: "" };
  }

  const input = asRecord(stdin);
  const state = reviewState(input);
  if (!state) {
    return { stdout: "" };
  }

  try {
    const answers = await callSystemOne({
      token,
      baseUrl: env.FINCLAW_HOOK_JUDGE_BASE_URL ?? DEFAULT_JUDGE_BASE_URL,
      model: env.FINCLAW_HOOK_JUDGE_MODEL ?? DEFAULT_JUDGE_MODEL,
      state,
      questions: REVIEW_QUESTIONS,
      fetchFn: fetchFn as typeof fetch,
      timeoutMs: 8000,
    });
    return mapReviewAnswers(answers) === "reject"
      ? { stdout: `${JSON.stringify(rejectStop(rejectReason(answers)))}\n` }
      : { stdout: "" };
  } catch {
    return { stdout: "" };
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
    process.stdout.write("");
  }
}

if (require.main === module) {
  void main();
}
