import fs from "node:fs";
import path from "node:path";
import { routeUpdatedModel } from "../../../lib/honour";
import {
  callSystemOne,
  DEFAULT_JUDGE_BASE_URL,
  mapRouterAnswers,
} from "../../../lib/judge";
import { asRecord, cap, readStdinJson } from "../../../lib/stdin";

const DEFAULT_JUDGE_MODEL = "jev-latest";

const ROUTER_QUESTIONS = {
  lane: {
    type: "choice",
    instructions: "Choose the model lane for this turn.",
    criteria: {
      cheap: "Use the inexpensive lane for simple, safe work.",
      strong: "Use the strong lane for complex work.",
      keep: "Keep the current model when no routing change is appropriate.",
    },
  },
  simple_lookup: {
    type: "noul",
    instructions: "Does this turn only need a simple lookup or straightforward answer?",
  },
  unsafe_or_irreversible: {
    type: "noul",
    instructions: "Is this turn unsafe or irreversible?",
  },
  difficulty: {
    type: "score",
    instructions: "Rate the turn difficulty from simple to complex.",
    criteria: ["trivial", "moderate", "hard", "extreme"],
  },
};

type HandleResult = { stdout: string };
type FetchFn = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>;
type Routes = { cheap: string[]; strong: string[] };

function routes(): Routes {
  const parsed = asRecord(
    JSON.parse(fs.readFileSync(path.join(__dirname, "..", "routes.json"), "utf8")),
  );
  const lane = (name: "cheap" | "strong") => {
    const ids = parsed[name];
    return Array.isArray(ids)
      ? ids.filter((id): id is string => typeof id === "string" && id !== "").slice(0, 8)
      : [];
  };
  return { cheap: lane("cheap"), strong: lane("strong") };
}

function routerState(
  input: Record<string, unknown>,
  configuredRoutes: Routes,
): object | null {
  const prompt = typeof input.prompt === "string" ? input.prompt : "";
  const model = typeof input.model === "string" ? input.model : "";
  const turn = asRecord(input.turn);
  const userText = typeof turn.user_text === "string" ? turn.user_text : "";
  const userAsk = prompt || userText;

  if (userAsk === "" || model === "") {
    return null;
  }

  return {
    user_ask: cap(userAsk, 2048),
    current_model: model,
    cheap: configuredRoutes.cheap,
    strong: configuredRoutes.strong,
  };
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
  const configuredRoutes = routes();
  const state = routerState(input, configuredRoutes);
  if (!state) {
    return { stdout: "" };
  }

  try {
    const model = mapRouterAnswers(
      await callSystemOne({
        token,
        baseUrl: env.FINCLAW_HOOK_JUDGE_BASE_URL ?? DEFAULT_JUDGE_BASE_URL,
        model: env.FINCLAW_HOOK_JUDGE_MODEL ?? DEFAULT_JUDGE_MODEL,
        state,
        questions: ROUTER_QUESTIONS,
        fetchFn: fetchFn as typeof fetch,
        timeoutMs: 8000,
      }),
      configuredRoutes,
      input.model as string,
    );
    return model ? { stdout: `${JSON.stringify(routeUpdatedModel(model))}\n` } : { stdout: "" };
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
