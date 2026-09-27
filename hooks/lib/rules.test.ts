import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { decideGateRules } from "./rules";

describe("decideGateRules", () => {
  it("denies rm -rf", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "rm -rf /tmp/x",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("denies write to .env", () => {
    assert.equal(
      decideGateRules({
        toolName: "write_file",
        commandOrPath: "/ws/.env",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("denies an exec command that references .env", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "cat .env",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("denies an exec command that references an SSH key", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "cat ~/.ssh/id_rsa",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("denies a background exec command that references .env", () => {
    assert.equal(
      decideGateRules({
        toolName: "start_exec_job",
        commandOrPath: "cat .env.production",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("denies a quoted sensitive exec path", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "cat '.env'",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("denies a sensitive exec path before a command separator", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "cat .env;",
        cwd: "/ws",
      }),
      "deny",
    );
  });

  it("does not apply command deny words to write paths", () => {
    assert.equal(
      decideGateRules({
        toolName: "write_file",
        commandOrPath: "/ws/reboot-notes.md",
        cwd: "/ws",
      }),
      "ask",
    );
  });

  it("asks on plain echo", () => {
    assert.equal(
      decideGateRules({
        toolName: "exec",
        commandOrPath: "echo hi",
        cwd: "/ws",
      }),
      "ask",
    );
  });
});
