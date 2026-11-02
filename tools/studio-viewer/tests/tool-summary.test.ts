import { describe, expect, it } from "vitest";
import { displayName, summarizeToolInput, truncate } from "../shared/tool-summary.ts";
import { buildClaudeArguments, resolveClaudeCommand } from "../server/claude-session.ts";

describe("summarizeToolInput", () => {
  it("shortens file paths to the last two segments", () => {
    expect(summarizeToolInput("Edit", { file_path: "D:\\repo\\src\\gameplay\\combat.gd" })).toBe("gameplay/combat.gd");
  });

  it("prefers the Bash description over the raw command", () => {
    expect(summarizeToolInput("Bash", { command: "npm test", description: "Run the tests" })).toBe("Run the tests");
  });

  it("shows grep pattern and folder", () => {
    expect(summarizeToolInput("Grep", { pattern: "TODO", path: "/repo/src" })).toBe('"TODO" in repo/src');
  });

  it("shows only the host for web fetches", () => {
    expect(summarizeToolInput("WebFetch", { url: "https://docs.godotengine.org/en/stable/" })).toBe("docs.godotengine.org");
  });

  it("names the skill with a slash", () => {
    expect(summarizeToolInput("Skill", { skill: "design-review" })).toBe("/design-review");
  });
});

describe("truncate", () => {
  it("collapses whitespace and adds an ellipsis past the limit", () => {
    expect(truncate("one   two\nthree", 9)).toBe("one two …");
    expect(truncate("short", 9)).toBe("short");
  });
});

describe("displayName", () => {
  it("capitalises words and upper-cases short acronyms", () => {
    expect(displayName("ai-programmer")).toBe("AI Programmer");
    expect(displayName("ue-gas-specialist")).toBe("UE GAS Specialist");
  });
});

describe("buildClaudeArguments", () => {
  const base = { projectRoot: "/repo", permissionMode: "auto" as const, resumeSessionId: null, model: null };

  it("runs headless with streaming JSON in both directions and the chosen mode", () => {
    const commandArguments = buildClaudeArguments(base);
    expect(commandArguments).toContain("--include-partial-messages");
    expect(commandArguments.join(" ")).toContain("--input-format stream-json");
    expect(commandArguments.join(" ")).toContain("--permission-mode auto");
    expect(commandArguments).not.toContain("--resume");
  });

  it("resumes only a well-formed session id", () => {
    const valid = "a931244a-81f6-4c69-a72f-b910e5c4cf87";
    expect(buildClaudeArguments({ ...base, resumeSessionId: valid })).toContain(valid);
    expect(buildClaudeArguments({ ...base, resumeSessionId: "x & del *" })).not.toContain("--resume");
  });

  it("adds the explicit opt-in flag for bypassPermissions", () => {
    expect(buildClaudeArguments({ ...base, permissionMode: "bypassPermissions" })).toContain("--allow-dangerously-skip-permissions");
  });
});

describe("resolveClaudeCommand", () => {
  it("uses CLAUDE_BIN and a shell only for .cmd files", () => {
    expect(resolveClaudeCommand({ CLAUDE_BIN: "C:\\tools\\claude.cmd" }, "win32")).toEqual({ executable: "C:\\tools\\claude.cmd", useShell: true });
    expect(resolveClaudeCommand({}, "linux")).toEqual({ executable: "claude", useShell: false });
  });
});
