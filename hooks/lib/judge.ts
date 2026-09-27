export const DEFAULT_JUDGE_BASE_URL = "https://api.typesafe.ai";
export const DEFAULT_JUDGE_PATH = "/v1/systemone";
export const JUDGE_TIMEOUT_MS = 8000;

type NoulAnswer = { noul: number };
type ScoreAnswer = { score: number };
type ChoiceAnswer = { choice: string; confidence: number };

export type JudgeAnswers = Record<string, NoulAnswer | ScoreAnswer | ChoiceAnswer>;

function noul(answers: JudgeAnswers, id: string): number | null {
  const answer = answers[id];
  return answer && "noul" in answer && Number.isFinite(answer.noul) ? answer.noul : null;
}

function score(answers: JudgeAnswers, id: string): number | null {
  const answer = answers[id];
  return answer && "score" in answer && Number.isFinite(answer.score) ? answer.score : null;
}

function choice(answers: JudgeAnswers, id: string): ChoiceAnswer | null {
  const answer = answers[id];
  return (
    answer &&
    "choice" in answer &&
    typeof answer.choice === "string" &&
    "confidence" in answer &&
    Number.isFinite(answer.confidence)
  )
    ? answer
    : null;
}

export function mapGateAnswers(answers: JudgeAnswers): "deny" | "ask" | "allow" {
  const action = choice(answers, "action");
  const isDestructive = noul(answers, "is_destructive");
  const touchesCredentials = noul(answers, "touches_credentials");
  const scopeMatches = noul(answers, "scope_matches");
  const severity = score(answers, "severity");

  if (
    !action ||
    isDestructive === null ||
    touchesCredentials === null ||
    scopeMatches === null ||
    severity === null
  ) {
    return "ask";
  }
  if (
    action.choice === "deny" ||
    isDestructive >= 0.7 ||
    touchesCredentials >= 0.7 ||
    scopeMatches < 0.5 ||
    severity >= 2.8
  ) {
    return "deny";
  }
  if (action.confidence < 0.45) {
    return "ask";
  }
  if (action.choice === "ask" || severity >= 2) {
    return "ask";
  }
  return "allow";
}

export function mapRouterAnswers(
  answers: JudgeAnswers,
  routes: { cheap: string[]; strong: string[] },
  currentModel: string,
): string | null {
  const lane = choice(answers, "lane");
  const simpleLookup = noul(answers, "simple_lookup");
  const unsafeOrIrreversible = noul(answers, "unsafe_or_irreversible");
  const difficulty = score(answers, "difficulty");

  if (
    !lane ||
    simpleLookup === null ||
    unsafeOrIrreversible === null ||
    difficulty === null ||
    lane.confidence < 0.45 ||
    lane.choice === "keep" ||
    unsafeOrIrreversible >= 0.7
  ) {
    return null;
  }

  if (lane.choice === "cheap" || (simpleLookup >= 0.75 && difficulty < 1.5)) {
    const cheap = routes.cheap.filter((id) => typeof id === "string" && id !== "");
    return cheap.find((id) => id !== currentModel) ?? cheap[0] ?? null;
  }
  if (lane.choice === "strong") {
    return routes.strong.find((id) => typeof id === "string" && id !== "") ?? null;
  }
  return null;
}

export function mapReviewAnswers(answers: JudgeAnswers): "reject" | "keep" {
  const verdict = choice(answers, "verdict");
  const citesMissingEvidence = noul(answers, "cites_missing_evidence");
  const contradictsTools = noul(answers, "contradicts_tools");
  const emptyOrPlaceholder = noul(answers, "empty_or_placeholder");
  const severity = score(answers, "severity");

  if (
    !verdict ||
    citesMissingEvidence === null ||
    contradictsTools === null ||
    emptyOrPlaceholder === null ||
    severity === null ||
    verdict.confidence < 0.45
  ) {
    return "keep";
  }
  if (
    verdict.choice === "reject" ||
    emptyOrPlaceholder >= 0.75 ||
    citesMissingEvidence >= 0.7 ||
    contradictsTools >= 0.7 ||
    severity >= 2.8
  ) {
    return "reject";
  }
  return "keep";
}

export async function callSystemOne(args: {
  token: string;
  baseUrl: string;
  model: string;
  state: object;
  questions: object;
  fetchFn: typeof fetch;
  timeoutMs: number;
}): Promise<JudgeAnswers> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), args.timeoutMs);
  const baseUrl = args.baseUrl.replace(/\/$/, "");

  try {
    const response = await args.fetchFn(`${baseUrl}${DEFAULT_JUDGE_PATH}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${args.token}`,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        model: args.model,
        state: args.state,
        questions: args.questions,
      }),
      signal: controller.signal,
    });
    const text = await response.text();
    if (!response.ok) {
      throw new Error(`judge_http_${response.status}`);
    }

    const result: unknown = JSON.parse(text);
    if (
      result === null ||
      typeof result !== "object" ||
      Array.isArray(result) ||
      !("answers" in result) ||
      result.answers === null ||
      typeof result.answers !== "object" ||
      Array.isArray(result.answers)
    ) {
      throw new Error("judge_invalid_answers");
    }
    return result.answers as JudgeAnswers;
  } finally {
    clearTimeout(timer);
  }
}
