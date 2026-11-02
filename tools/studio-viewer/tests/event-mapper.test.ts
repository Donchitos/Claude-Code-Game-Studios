import { describe, expect, it } from "vitest";
import { StudioEventMapper } from "../server/event-mapper.ts";
import { MAIN_AGENT, type StudioEvent } from "../shared/protocol.ts";
import {
  MAIN_AGENT_TOOL_USE,
  NESTED_AGENT_TOOL_USE,
  SESSION_ID,
  agentToolUseLine,
  asyncLaunchResultLine,
  initLine,
  resultLine,
  streamLine,
  subagentWorkLine,
  syncToolResultLine,
  taskNotificationLine,
  taskStartedLine,
  taskUpdatedLine,
} from "./fixtures.ts";

function kinds(events: StudioEvent[]): string[] {
  return events.map((event) => event.kind);
}

function mapAll(mapper: StudioEventMapper, lines: string[]): StudioEvent[] {
  return lines.flatMap((line) => mapper.mapLine(line));
}

describe("StudioEventMapper", () => {
  it("reports the session from the init line", () => {
    const [event] = new StudioEventMapper().mapLine(initLine);
    expect(event).toEqual({
      kind: "session_ready",
      sessionId: SESSION_ID,
      model: "claude-haiku-4-5",
      permissionMode: "default",
      cwd: "D:\\projects\\studio",
    });
  });

  it("assigns a task when the main session calls the Agent tool, once", () => {
    const mapper = new StudioEventMapper();
    const events = mapAll(mapper, [agentToolUseLine(MAIN_AGENT_TOOL_USE, "Explore", null), taskStartedLine]);
    expect(events).toEqual([
      {
        kind: "agent_assigned",
        taskId: MAIN_AGENT_TOOL_USE,
        agentType: "Explore",
        description: "Count design files",
        prompt: "Count all files in design/.",
        parentAgent: MAIN_AGENT,
      },
    ]);
    expect(mapper.activeTasks()).toHaveLength(1);
  });

  it("does not finish an async agent when its launch result arrives", () => {
    const mapper = new StudioEventMapper();
    const events = mapAll(mapper, [agentToolUseLine(MAIN_AGENT_TOOL_USE, "Explore", null), asyncLaunchResultLine]);
    expect(kinds(events)).toEqual(["agent_assigned"]);
    expect(mapper.activeTasks()).toHaveLength(1);
  });

  it("attributes subagent thinking, tools and text to the subagent", () => {
    const mapper = new StudioEventMapper();
    const events = mapAll(mapper, [agentToolUseLine(MAIN_AGENT_TOOL_USE, "Explore", null), subagentWorkLine]).slice(1);
    expect(events).toEqual([
      { kind: "agent_thinking", taskId: MAIN_AGENT_TOOL_USE, agentType: "Explore" },
      { kind: "agent_tool", taskId: MAIN_AGENT_TOOL_USE, agentType: "Explore", toolName: "Glob", summary: "design/**/*" },
      { kind: "agent_text", taskId: MAIN_AGENT_TOOL_USE, agentType: "Explore", text: "Total files: 2" },
    ]);
  });

  it("finishes an async agent from its notification with the summary, ignoring the earlier status patch", () => {
    const mapper = new StudioEventMapper();
    const events = mapAll(mapper, [
      agentToolUseLine(MAIN_AGENT_TOOL_USE, "Explore", null),
      taskStartedLine,
      asyncLaunchResultLine,
      taskUpdatedLine,
      taskNotificationLine,
      taskNotificationLine,
    ]);
    expect(events.filter((event) => event.kind === "agent_finished")).toEqual([
      { kind: "agent_finished", taskId: MAIN_AGENT_TOOL_USE, agentType: "Explore", outcome: "completed", summary: "Total Files: 2" },
    ]);
    expect(mapper.activeTasks()).toHaveLength(0);
  });

  it("finishes a synchronous agent from its tool result, failed when the result is an error", () => {
    const mapper = new StudioEventMapper();
    const events = mapAll(mapper, [agentToolUseLine(MAIN_AGENT_TOOL_USE, "producer", null), syncToolResultLine(MAIN_AGENT_TOOL_USE, true)]);
    expect(events.at(-1)).toEqual({
      kind: "agent_finished",
      taskId: MAIN_AGENT_TOOL_USE,
      agentType: "producer",
      outcome: "failed",
      summary: "Report body",
    });
  });

  it("finishes a synchronous agent with its real output even when the notification arrives first", () => {
    const mapper = new StudioEventMapper();
    const descriptionOnlyNotification = streamLine({
      type: "system",
      subtype: "task_notification",
      tool_use_id: MAIN_AGENT_TOOL_USE,
      status: "completed",
      summary: "Count design files",
    });
    const events = mapAll(mapper, [
      agentToolUseLine(MAIN_AGENT_TOOL_USE, "writer", null),
      descriptionOnlyNotification,
      syncToolResultLine(MAIN_AGENT_TOOL_USE, false),
    ]);
    expect(events.filter((event) => event.kind === "agent_finished")).toEqual([
      { kind: "agent_finished", taskId: MAIN_AGENT_TOOL_USE, agentType: "writer", outcome: "completed", summary: "Report body" },
    ]);
  });

  it("replaces a generic completion summary with the agent's last message", () => {
    const mapper = new StudioEventMapper();
    const genericNotification = streamLine({
      type: "system",
      subtype: "task_notification",
      tool_use_id: MAIN_AGENT_TOOL_USE,
      status: "completed",
      summary: 'Agent "Count design files" completed',
    });
    const events = mapAll(mapper, [
      agentToolUseLine(MAIN_AGENT_TOOL_USE, "Explore", null),
      asyncLaunchResultLine,
      subagentWorkLine,
      genericNotification,
    ]);
    expect(events.at(-1)).toMatchObject({ kind: "agent_finished", summary: "Total files: 2" });
  });

  it("reports progress from task_progress when the agent's own messages are not streamed", () => {
    const mapper = new StudioEventMapper();
    const progress = streamLine({
      type: "system",
      subtype: "task_progress",
      task_id: "background",
      tool_use_id: MAIN_AGENT_TOOL_USE,
      description: "Reading design\\game-brief.md",
      subagent_type: "writer",
      last_tool_name: "Read",
    });
    const events = mapAll(mapper, [agentToolUseLine(MAIN_AGENT_TOOL_USE, "writer", null), progress]);
    expect(events.at(-1)).toEqual({
      kind: "agent_tool",
      taskId: MAIN_AGENT_TOOL_USE,
      agentType: "writer",
      toolName: "Read",
      summary: "Reading design\\game-brief.md",
    });
    const streamed = new StudioEventMapper();
    const streamedEvents = mapAll(streamed, [agentToolUseLine(MAIN_AGENT_TOOL_USE, "writer", null), subagentWorkLine, progress]);
    expect(streamedEvents.filter((event) => event.kind === "agent_tool")).toHaveLength(1);
  });

  it("names the spawning agent as parent when a subagent delegates", () => {
    const mapper = new StudioEventMapper();
    const events = mapAll(mapper, [
      agentToolUseLine(MAIN_AGENT_TOOL_USE, "godot-specialist", null),
      agentToolUseLine(NESTED_AGENT_TOOL_USE, "godot-shader-specialist", MAIN_AGENT_TOOL_USE),
    ]);
    expect(events.at(-1)).toMatchObject({
      kind: "agent_assigned",
      agentType: "godot-shader-specialist",
      parentAgent: "godot-specialist",
    });
  });

  it("streams main text deltas and reports a status change only when it changes", () => {
    const mapper = new StudioEventMapper();
    const start = streamLine({ type: "stream_event", parent_tool_use_id: null, event: { type: "message_start", message: {} } });
    const delta = streamLine({
      type: "stream_event",
      parent_tool_use_id: null,
      event: { type: "content_block_delta", index: 0, delta: { type: "text_delta", text: "Hel" } },
    });
    const events = mapAll(mapper, [start, start, delta]);
    expect(events).toEqual([
      { kind: "main_status", status: "thinking" },
      { kind: "main_text_delta", text: "Hel" },
    ]);
  });

  it("ignores stream events from subagents", () => {
    const subagentDelta = streamLine({
      type: "stream_event",
      parent_tool_use_id: MAIN_AGENT_TOOL_USE,
      event: { type: "content_block_delta", delta: { type: "text_delta", text: "x" } },
    });
    expect(new StudioEventMapper().mapLine(subagentDelta)).toEqual([]);
  });

  it("finishes the turn with cost and returns the main session to idle", () => {
    const mapper = new StudioEventMapper();
    mapper.mapLine(streamLine({ type: "stream_event", parent_tool_use_id: null, event: { type: "message_start" } }));
    expect(mapper.mapLine(resultLine)).toEqual([
      { kind: "turn_finished", costUsd: 0.0959, durationMs: 3933, isError: false, resultText: "Design folder holds 2 files." },
      { kind: "main_status", status: "idle" },
    ]);
  });

  it("reports a main session tool call with a summary", () => {
    const line = streamLine({
      type: "assistant",
      parent_tool_use_id: null,
      message: { id: "msg_1", content: [{ type: "tool_use", id: "toolu_read", name: "Read", input: { file_path: "D:\\repo\\design\\gdd\\combat.md" } }] },
    });
    expect(new StudioEventMapper().mapLine(line)).toEqual([
      { kind: "main_status", status: "working" },
      { kind: "main_tool", toolUseId: "toolu_read", toolName: "Read", summary: "gdd/combat.md" },
    ]);
  });

  it("turns a line that is not JSON into a warning notice", () => {
    expect(new StudioEventMapper().mapLine("Ignoring 3 permissions.allow entries")).toEqual([
      { kind: "notice", level: "warning", text: "Ignoring 3 permissions.allow entries" },
    ]);
  });

  it("shows SessionStart hook output and hides cancelled hooks", () => {
    const mapper = new StudioEventMapper();
    const hook = (outcome: string) =>
      streamLine({ type: "system", subtype: "hook_response", hook_name: "SessionStart:startup", hook_event: "SessionStart", output: "Run /start", exit_code: 0, outcome });
    expect(mapper.mapLine(hook("success"))).toEqual([{ kind: "notice", level: "info", text: "Run /start" }]);
    expect(mapper.mapLine(hook("cancelled"))).toEqual([]);
  });

  it("stops every unfinished task when the session stops", () => {
    const mapper = new StudioEventMapper();
    mapAll(mapper, [agentToolUseLine(MAIN_AGENT_TOOL_USE, "Explore", null), agentToolUseLine(NESTED_AGENT_TOOL_USE, "Plan", null)]);
    const events = mapper.stopAllTasks();
    expect(events.filter((event) => event.kind === "agent_finished").map((event) => event.kind === "agent_finished" && event.outcome)).toEqual([
      "stopped",
      "stopped",
    ]);
    expect(mapper.activeTasks()).toEqual([]);
  });
});
