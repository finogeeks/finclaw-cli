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

export function decideGateRules(input: {
  toolName: string;
  commandOrPath: string;
  cwd: string;
}): "deny" | "ask" {
  const pathCandidates =
    input.toolName === "exec" || input.toolName === "start_exec_job"
      ? input.commandOrPath.split(/\s+/).filter(Boolean)
      : [input.commandOrPath];

  if (
    DENY_SUBSTRINGS.some((substring) => input.commandOrPath.includes(substring)) ||
    pathCandidates.some((candidate) => isSensitivePath(candidate, input.cwd))
  ) {
    return "deny";
  }
  return "ask";
}
