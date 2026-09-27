import path from "node:path";

export function readStdinJson(raw: string): unknown {
  if (raw.trim() === "") {
    throw new Error("stdin is empty");
  }
  return JSON.parse(raw);
}

export function asRecord(value: unknown): Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as Record<string, unknown>;
}

export function cap(value: string, max: number): string {
  return value.slice(0, max);
}

export function toolCommandOrPath(
  toolName: string,
  toolInput: unknown,
  cwd: string,
): string {
  const input = asRecord(toolInput);

  if (toolName === "exec" || toolName === "start_exec_job") {
    const command = input.command ?? input.argv;
    if (typeof command === "string") {
      return command;
    }
    if (Array.isArray(command) && command.every((part) => typeof part === "string")) {
      return command.join(" ");
    }
    return "";
  }

  const target = input.path ?? input.file_path ?? input.target_path;
  return typeof target === "string" && target !== "" ? path.resolve(cwd, target) : "";
}
