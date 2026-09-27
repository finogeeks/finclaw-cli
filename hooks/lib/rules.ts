import path from "node:path";

const DENY_SUBSTRINGS = [
  "rm -rf",
  "rm -fr",
  "mkfs",
  "diskpart",
  "format ",
  "shutdown",
  "reboot",
];

function isSensitivePath(commandOrPath: string, cwd: string): boolean {
  const resolved = path.resolve(cwd, commandOrPath);
  const segments = resolved.split(path.sep);
  const basename = path.basename(resolved);

  return (
    segments.includes(".ssh") ||
    basename === ".env" ||
    basename.startsWith(".env.") ||
    basename === "hooks-trust.json"
  );
}

function normalizeExecToken(token: string): string {
  let normalized = token.endsWith(";") ? token.slice(0, -1) : token;
  const quote = normalized[0];
  if (
    normalized.length >= 2 &&
    (quote === "'" || quote === '"') &&
    normalized.endsWith(quote)
  ) {
    normalized = normalized.slice(1, -1);
  }
  return normalized;
}

export function decideGateRules(input: {
  toolName: string;
  commandOrPath: string;
  cwd: string;
}): "deny" | "ask" {
  const isExec =
    input.toolName === "exec" || input.toolName === "start_exec_job";
  const pathCandidates = isExec
    ? input.commandOrPath
        .split(/\s+/)
        .filter(Boolean)
        .map(normalizeExecToken)
    : [input.commandOrPath];

  if (
    (isExec &&
      DENY_SUBSTRINGS.some((substring) =>
        input.commandOrPath.includes(substring),
      )) ||
    pathCandidates.some((candidate) => isSensitivePath(candidate, input.cwd))
  ) {
    return "deny";
  }
  return "ask";
}
