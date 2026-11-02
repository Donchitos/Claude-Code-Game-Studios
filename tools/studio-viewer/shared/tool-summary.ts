const TOOL_ICONS: Record<string, string> = {
  Read: "📖",
  Write: "📝",
  Edit: "✏️",
  MultiEdit: "✏️",
  NotebookEdit: "📓",
  Bash: "⌨️",
  PowerShell: "⌨️",
  Grep: "🔎",
  Glob: "🗂️",
  WebSearch: "🌐",
  WebFetch: "🌐",
  Agent: "👥",
  Task: "👥",
  SendMessage: "💬",
  Skill: "🧰",
  TodoWrite: "✅",
};

const SUMMARY_LENGTH = 60;

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function toolIcon(toolName: string): string {
  return TOOL_ICONS[toolName] ?? "🔧";
}

export function truncate(text: string, maxLength: number): string {
  const singleLine = text.replace(/\s+/g, " ").trim();
  return singleLine.length <= maxLength ? singleLine : `${singleLine.slice(0, maxLength - 1)}…`;
}

function shortPath(filePath: string): string {
  return filePath.split(/[\\/]/).filter(Boolean).slice(-2).join("/");
}

function readString(fields: Record<string, unknown>, key: string): string | undefined {
  const value = fields[key];
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function hostOf(url: string | undefined): string {
  if (!url) return "web page";
  try {
    return new URL(url).host;
  } catch {
    return truncate(url, SUMMARY_LENGTH);
  }
}

export function summarizeToolInput(toolName: string, input: unknown): string {
  const fields = isRecord(input) ? input : {};
  switch (toolName) {
    case "Read":
    case "Write":
    case "Edit":
    case "MultiEdit":
    case "NotebookEdit": {
      const filePath = readString(fields, "file_path") ?? readString(fields, "notebook_path");
      return filePath ? shortPath(filePath) : toolName;
    }
    case "Bash":
    case "PowerShell":
      return truncate(readString(fields, "description") ?? readString(fields, "command") ?? toolName, SUMMARY_LENGTH);
    case "Grep": {
      const pattern = readString(fields, "pattern") ?? "";
      const searchPath = readString(fields, "path");
      return truncate(searchPath ? `"${pattern}" in ${shortPath(searchPath)}` : `"${pattern}"`, SUMMARY_LENGTH);
    }
    case "Glob":
      return truncate(readString(fields, "pattern") ?? toolName, SUMMARY_LENGTH);
    case "WebSearch":
      return truncate(readString(fields, "query") ?? toolName, SUMMARY_LENGTH);
    case "WebFetch":
      return hostOf(readString(fields, "url"));
    case "Skill":
      return `/${readString(fields, "skill") ?? "skill"}`;
    case "Agent":
    case "Task":
      return truncate(
        `${readString(fields, "subagent_type") ?? "agent"}: ${readString(fields, "description") ?? ""}`,
        SUMMARY_LENGTH,
      );
    case "TodoWrite": {
      const todos = fields["todos"];
      return Array.isArray(todos) ? `${todos.length} todos` : "todos";
    }
    default: {
      const firstString = Object.values(fields).find((value): value is string => typeof value === "string");
      return truncate(firstString ?? toolName, SUMMARY_LENGTH);
    }
  }
}

const ACRONYMS = new Set(["ai", "ui", "ux", "qa", "ue", "gas", "umg", "dots", "vfx", "sfx", "gdd", "adr"]);

export function displayName(agentName: string): string {
  return agentName
    .split(/[-_]/)
    .filter(Boolean)
    .map((word) => (ACRONYMS.has(word.toLowerCase()) ? word.toUpperCase() : word[0]!.toUpperCase() + word.slice(1)))
    .join(" ");
}
