import { spawn, type ChildProcess } from "node:child_process";
import { EventEmitter } from "node:events";
import { existsSync } from "node:fs";
import path from "node:path";
import { createInterface } from "node:readline";
import type { PermissionMode } from "../shared/protocol.ts";

export interface ClaudeCommand {
  executable: string;
  useShell: boolean;
}

export interface ClaudeLaunchOptions {
  projectRoot: string;
  permissionMode: PermissionMode;
  resumeSessionId: string | null;
  model: string | null;
}

const SESSION_ID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MODEL_PATTERN = /^[\w.[\]-]+$/;
const DISALLOWED_TOOLS = "AskUserQuestion";

export function isValidSessionId(value: unknown): value is string {
  return typeof value === "string" && SESSION_ID_PATTERN.test(value);
}

export function isValidModelName(value: unknown): value is string {
  return typeof value === "string" && MODEL_PATTERN.test(value);
}

export function resolveClaudeCommand(
  environment: NodeJS.ProcessEnv = process.env,
  platform: NodeJS.Platform = process.platform,
): ClaudeCommand {
  const override = environment["CLAUDE_BIN"];
  if (override) return { executable: override, useShell: /\.(cmd|bat)$/i.test(override) };
  if (platform !== "win32") return { executable: "claude", useShell: false };
  const searchPath = (environment["PATH"] ?? environment["Path"] ?? "").split(path.delimiter).filter(Boolean);
  for (const extension of [".exe", ".cmd"]) {
    for (const directory of searchPath) {
      const candidate = path.join(directory, `claude${extension}`);
      if (existsSync(candidate)) return { executable: candidate, useShell: extension === ".cmd" };
    }
  }
  return { executable: "claude", useShell: true };
}

export function buildClaudeArguments(options: ClaudeLaunchOptions): string[] {
  const commandArguments = [
    "-p",
    "--input-format",
    "stream-json",
    "--output-format",
    "stream-json",
    "--verbose",
    "--include-hook-events",
    "--include-partial-messages",
    `--disallowed-tools=${DISALLOWED_TOOLS}`,
    "--permission-mode",
    options.permissionMode,
  ];
  if (options.permissionMode === "bypassPermissions") commandArguments.push("--allow-dangerously-skip-permissions");
  if (isValidSessionId(options.resumeSessionId)) commandArguments.push("--resume", options.resumeSessionId);
  if (isValidModelName(options.model)) commandArguments.push("--model", options.model);
  return commandArguments;
}

interface SessionEvents {
  line: [string];
  stderr: [string];
  exit: [exitCode: number | null, stoppedByRequest: boolean];
}

export class ClaudeSession extends EventEmitter<SessionEvents> {
  private child: ChildProcess | null = null;
  private readonly stoppedChildren = new WeakSet<ChildProcess>();

  constructor(private readonly command: ClaudeCommand) {
    super();
  }

  get running(): boolean {
    return this.child !== null;
  }

  start(options: ClaudeLaunchOptions): void {
    if (this.child) return;
    const executable = this.command.useShell ? `"${this.command.executable}"` : this.command.executable;
    const child = spawn(executable, buildClaudeArguments(options), {
      cwd: options.projectRoot,
      shell: this.command.useShell,
      stdio: ["pipe", "pipe", "pipe"],
      windowsHide: true,
    });
    this.child = child;
    const isCurrent = () => !this.stoppedChildren.has(child);
    if (child.stdout) {
      createInterface({ input: child.stdout }).on("line", (line) => isCurrent() && this.emit("line", line));
    }
    if (child.stderr) {
      createInterface({ input: child.stderr }).on("line", (line) => isCurrent() && this.emit("stderr", line));
    }
    child.on("error", (error) => this.emit("stderr", `Could not start claude: ${error.message}`));
    child.on("exit", (exitCode) => {
      if (this.child === child) this.child = null;
      this.emit("exit", exitCode, this.stoppedChildren.has(child));
    });
  }

  sendUserMessage(text: string): void {
    const payload = { type: "user", message: { role: "user", content: [{ type: "text", text }] } };
    this.child?.stdin?.write(`${JSON.stringify(payload)}\n`);
  }

  stop(): void {
    const child = this.child;
    if (!child) return;
    this.child = null;
    this.stoppedChildren.add(child);
    if (process.platform === "win32" && child.pid) {
      spawn("taskkill", ["/pid", String(child.pid), "/T", "/F"], { windowsHide: true });
      return;
    }
    child.kill("SIGTERM");
  }
}
