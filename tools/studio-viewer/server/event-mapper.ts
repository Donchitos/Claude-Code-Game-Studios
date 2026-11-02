import { MAIN_AGENT, type ActiveTask, type MainStatus, type StudioEvent, type TaskOutcome } from "../shared/protocol.ts";
import { isRecord, summarizeToolInput, truncate } from "../shared/tool-summary.ts";

const AGENT_TOOL_NAMES = new Set(["Agent", "Task"]);
const MESSAGE_TOOL_NAMES = new Set(["SendMessage"]);
const FALLBACK_AGENT_TYPE = "general-purpose";
const ASYNC_LAUNCH_MARKER = "Async agent launched";
const STATUSES_WITHOUT_NOTIFICATION = new Set(["failed", "killed", "stopped", "cancelled"]);
const NOTICE_LENGTH = 600;

interface TaskRecord {
  taskId: string;
  agentType: string;
  description: string;
  parentAgent: string;
  finished: boolean;
  launchedAsync: boolean;
  streamed: boolean;
  lastText: string;
}

const GENERIC_SUMMARY = /^Agent ".*" (completed|failed|stopped|was stopped|was killed)\.?$/i;

type Fields = Record<string, unknown>;

function stringField(fields: Fields, key: string): string {
  const value = fields[key];
  return typeof value === "string" ? value : "";
}

function numberField(fields: Fields, key: string): number {
  const value = fields[key];
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function recordField(fields: Fields, key: string): Fields {
  const value = fields[key];
  return isRecord(value) ? value : {};
}

function listField(fields: Fields, key: string): unknown[] {
  const value = fields[key];
  return Array.isArray(value) ? value : [];
}

function outcomeFromStatus(status: string): TaskOutcome {
  if (status === "completed") return "completed";
  if (status === "killed" || status === "stopped" || status === "cancelled") return "stopped";
  return "failed";
}

function toolResultText(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";
  return content
    .filter(isRecord)
    .map((block) => stringField(block, "text"))
    .filter(Boolean)
    .join("\n");
}

export class StudioEventMapper {
  private readonly tasks = new Map<string, TaskRecord>();
  private readonly toolUseIdsByBackgroundId = new Map<string, string>();
  private lastMainStatus: MainStatus = "idle";

  reset(): void {
    this.tasks.clear();
    this.toolUseIdsByBackgroundId.clear();
    this.lastMainStatus = "idle";
  }

  activeTasks(): ActiveTask[] {
    return [...this.tasks.values()]
      .filter((task) => !task.finished)
      .map(({ taskId, agentType, description, parentAgent }) => ({ taskId, agentType, description, parentAgent }));
  }

  stopAllTasks(): StudioEvent[] {
    const events = [...this.tasks.values()]
      .filter((task) => !task.finished)
      .flatMap((task) => this.finishTask(task.taskId, "stopped", "Session stopped"));
    return [...events, ...this.mainStatus("idle")];
  }

  mapLine(line: string): StudioEvent[] {
    const trimmed = line.trim();
    if (!trimmed) return [];
    let parsed: unknown;
    try {
      parsed = JSON.parse(trimmed);
    } catch {
      return [{ kind: "notice", level: "warning", text: truncate(trimmed, NOTICE_LENGTH) }];
    }
    return this.map(parsed);
  }

  map(raw: unknown): StudioEvent[] {
    if (!isRecord(raw)) return [];
    switch (raw["type"]) {
      case "system":
        return this.mapSystem(raw);
      case "assistant":
        return this.mapAssistant(raw);
      case "user":
        return this.mapUser(raw);
      case "stream_event":
        return this.mapStreamEvent(raw);
      case "result":
        return this.mapResult(raw);
      default:
        return [];
    }
  }

  private mapSystem(raw: Fields): StudioEvent[] {
    switch (raw["subtype"]) {
      case "init":
        return [
          {
            kind: "session_ready",
            sessionId: stringField(raw, "session_id"),
            model: stringField(raw, "model"),
            permissionMode: stringField(raw, "permissionMode"),
            cwd: stringField(raw, "cwd"),
          },
        ];
      case "task_started": {
        const toolUseId = stringField(raw, "tool_use_id");
        const backgroundId = stringField(raw, "task_id");
        if (backgroundId && toolUseId) this.toolUseIdsByBackgroundId.set(backgroundId, toolUseId);
        if (!toolUseId) return [];
        return this.registerTask(
          toolUseId,
          stringField(raw, "subagent_type") || FALLBACK_AGENT_TYPE,
          stringField(raw, "description"),
          stringField(raw, "prompt"),
          MAIN_AGENT,
        );
      }
      case "task_notification": {
        const toolUseId =
          stringField(raw, "tool_use_id") || this.toolUseIdsByBackgroundId.get(stringField(raw, "task_id")) || "";
        if (!this.tasks.get(toolUseId)?.launchedAsync) return [];
        return this.finishTask(toolUseId, outcomeFromStatus(stringField(raw, "status")), stringField(raw, "summary"));
      }
      case "task_progress": {
        const task = this.tasks.get(stringField(raw, "tool_use_id"));
        if (!task || task.streamed || task.finished) return [];
        return [
          {
            kind: "agent_tool",
            taskId: task.taskId,
            agentType: task.agentType,
            toolName: stringField(raw, "last_tool_name") || "Agent",
            summary: truncate(stringField(raw, "description") || "Working", 60),
          },
        ];
      }
      case "task_updated": {
        const status = stringField(recordField(raw, "patch"), "status");
        if (!STATUSES_WITHOUT_NOTIFICATION.has(status)) return [];
        const toolUseId = this.toolUseIdsByBackgroundId.get(stringField(raw, "task_id"));
        return toolUseId ? this.finishTask(toolUseId, outcomeFromStatus(status), "") : [];
      }
      case "hook_response":
        return this.mapHookResponse(raw);
      default:
        return [];
    }
  }

  private mapHookResponse(raw: Fields): StudioEvent[] {
    if (stringField(raw, "outcome") === "cancelled") return [];
    const output = (stringField(raw, "output") || stringField(raw, "stderr")).trim();
    if (!output) return [];
    if (numberField(raw, "exit_code") !== 0) {
      return [{ kind: "notice", level: "warning", text: `${stringField(raw, "hook_name")}: ${truncate(output, NOTICE_LENGTH)}` }];
    }
    if (stringField(raw, "hook_event") === "SessionStart") return [{ kind: "notice", level: "info", text: output }];
    return [];
  }

  private mapAssistant(raw: Fields): StudioEvent[] {
    const message = recordField(raw, "message");
    const parentToolUseId = stringField(raw, "parent_tool_use_id");
    const events: StudioEvent[] = [];
    let speaker: TaskRecord | null = null;
    if (parentToolUseId) {
      if (!this.tasks.has(parentToolUseId)) {
        events.push(...this.registerTask(parentToolUseId, FALLBACK_AGENT_TYPE, "", "", MAIN_AGENT));
      }
      speaker = this.tasks.get(parentToolUseId) ?? null;
      if (speaker) speaker.streamed = true;
    }
    for (const block of listField(message, "content")) {
      if (isRecord(block)) events.push(...this.mapAssistantBlock(block, speaker, stringField(message, "id")));
    }
    return events;
  }

  private mapAssistantBlock(block: Fields, speaker: TaskRecord | null, messageId: string): StudioEvent[] {
    const blockType = block["type"];
    if (blockType === "text") {
      const text = stringField(block, "text");
      if (!text.trim()) return [];
      if (speaker) {
        speaker.lastText = text;
        return [{ kind: "agent_text", taskId: speaker.taskId, agentType: speaker.agentType, text }];
      }
      return [{ kind: "main_text", messageId, text }];
    }
    if (blockType === "thinking") {
      if (speaker) return [{ kind: "agent_thinking", taskId: speaker.taskId, agentType: speaker.agentType }];
      return this.mainStatus("thinking");
    }
    if (blockType !== "tool_use") return [];
    return this.mapToolUse(block, speaker);
  }

  private mapToolUse(block: Fields, speaker: TaskRecord | null): StudioEvent[] {
    const toolName = stringField(block, "name");
    const toolUseId = stringField(block, "id");
    const input = recordField(block, "input");
    const speakerName = speaker?.agentType ?? MAIN_AGENT;
    if (AGENT_TOOL_NAMES.has(toolName)) {
      return this.registerTask(
        toolUseId,
        stringField(input, "subagent_type") || FALLBACK_AGENT_TYPE,
        stringField(input, "description"),
        stringField(input, "prompt"),
        speakerName,
      );
    }
    if (MESSAGE_TOOL_NAMES.has(toolName)) {
      const recipient = stringField(input, "to") || stringField(input, "recipient");
      if (recipient) {
        const text = stringField(input, "message") || stringField(input, "content") || summarizeToolInput(toolName, input);
        return [{ kind: "agent_message", fromAgent: speakerName, toAgent: recipient, text }];
      }
    }
    const summary = summarizeToolInput(toolName, input);
    if (speaker) return [{ kind: "agent_tool", taskId: speaker.taskId, agentType: speaker.agentType, toolName, summary }];
    return [...this.mainStatus("working"), { kind: "main_tool", toolUseId, toolName, summary }];
  }

  private mapUser(raw: Fields): StudioEvent[] {
    const toolUseResult = recordField(raw, "tool_use_result");
    const launchedAsync = toolUseResult["isAsync"] === true || toolUseResult["status"] === "async_launched";
    const events: StudioEvent[] = [];
    for (const block of listField(recordField(raw, "message"), "content")) {
      if (!isRecord(block) || block["type"] !== "tool_result") continue;
      const task = this.tasks.get(stringField(block, "tool_use_id"));
      if (!task) continue;
      const toolUseId = task.taskId;
      const text = toolResultText(block["content"]);
      if (launchedAsync || text.startsWith(ASYNC_LAUNCH_MARKER)) {
        task.launchedAsync = true;
        continue;
      }
      events.push(...this.finishTask(toolUseId, block["is_error"] === true ? "failed" : "completed", text));
    }
    return events;
  }

  private mapStreamEvent(raw: Fields): StudioEvent[] {
    if (stringField(raw, "parent_tool_use_id")) return [];
    const event = recordField(raw, "event");
    switch (event["type"]) {
      case "message_start":
        return this.mainStatus("thinking");
      case "content_block_start": {
        const blockType = recordField(event, "content_block")["type"];
        if (blockType === "text") return this.mainStatus("responding");
        if (blockType === "tool_use") return this.mainStatus("working");
        return [];
      }
      case "content_block_delta": {
        const delta = recordField(event, "delta");
        if (delta["type"] !== "text_delta") return [];
        const text = stringField(delta, "text");
        return text ? [{ kind: "main_text_delta", text }] : [];
      }
      default:
        return [];
    }
  }

  private mapResult(raw: Fields): StudioEvent[] {
    return [
      {
        kind: "turn_finished",
        costUsd: numberField(raw, "total_cost_usd"),
        durationMs: numberField(raw, "duration_ms"),
        isError: raw["is_error"] === true,
        resultText: stringField(raw, "result"),
      },
      ...this.mainStatus("idle"),
    ];
  }

  private mainStatus(status: MainStatus): StudioEvent[] {
    if (status === this.lastMainStatus) return [];
    this.lastMainStatus = status;
    return [{ kind: "main_status", status }];
  }

  private registerTask(
    taskId: string,
    agentType: string,
    description: string,
    prompt: string,
    parentAgent: string,
  ): StudioEvent[] {
    if (!taskId || this.tasks.has(taskId)) return [];
    const summary = description || truncate(prompt, 80) || "Assigned task";
    this.tasks.set(taskId, {
      taskId,
      agentType,
      description: summary,
      parentAgent,
      finished: false,
      launchedAsync: false,
      streamed: false,
      lastText: "",
    });
    return [{ kind: "agent_assigned", taskId, agentType, description: summary, prompt, parentAgent }];
  }

  private finishTask(taskId: string, outcome: TaskOutcome, summary: string): StudioEvent[] {
    const task = this.tasks.get(taskId);
    if (!task || task.finished) return [];
    task.finished = true;
    const useLastText = (!summary.trim() || GENERIC_SUMMARY.test(summary.trim())) && task.lastText;
    return [{ kind: "agent_finished", taskId, agentType: task.agentType, outcome, summary: useLastText ? task.lastText : summary }];
  }
}
