import type { RosterAgent, StudioConfig } from "../shared/protocol.ts";

export const SESSION_ID = "a931244a-81f6-4c69-a72f-b910e5c4cf87";
export const MAIN_AGENT_TOOL_USE = "toolu_main_agent_01";
export const NESTED_AGENT_TOOL_USE = "toolu_nested_agent_01";
export const BACKGROUND_TASK_ID = "a22c26760d0f05731";

export function streamLine(payload: Record<string, unknown>): string {
  return JSON.stringify({ session_id: SESSION_ID, uuid: "fixture", ...payload });
}

export const initLine = streamLine({
  type: "system",
  subtype: "init",
  cwd: "D:\\projects\\studio",
  model: "claude-haiku-4-5",
  permissionMode: "default",
});

export function agentToolUseLine(toolUseId: string, subagentType: string, parentToolUseId: string | null): string {
  return streamLine({
    type: "assistant",
    parent_tool_use_id: parentToolUseId,
    message: {
      id: `msg_${toolUseId}`,
      content: [
        {
          type: "tool_use",
          id: toolUseId,
          name: "Agent",
          input: { description: "Count design files", subagent_type: subagentType, prompt: "Count all files in design/." },
        },
      ],
    },
  });
}

export const taskStartedLine = streamLine({
  type: "system",
  subtype: "task_started",
  task_id: BACKGROUND_TASK_ID,
  tool_use_id: MAIN_AGENT_TOOL_USE,
  description: "Count design files",
  subagent_type: "Explore",
  task_type: "local_agent",
  prompt: "Count all files in design/.",
});

export const asyncLaunchResultLine = streamLine({
  type: "user",
  parent_tool_use_id: null,
  message: {
    content: [{ type: "tool_result", tool_use_id: MAIN_AGENT_TOOL_USE, content: [{ type: "text", text: "Async agent launched successfully." }] }],
  },
  tool_use_result: { isAsync: true, status: "async_launched" },
});

export const subagentWorkLine = streamLine({
  type: "assistant",
  parent_tool_use_id: MAIN_AGENT_TOOL_USE,
  message: {
    id: "msg_sub_01",
    content: [
      { type: "thinking", thinking: "Use Glob." },
      { type: "tool_use", id: "toolu_glob_01", name: "Glob", input: { pattern: "design/**/*" } },
      { type: "text", text: "Total files: 2" },
    ],
  },
});

export const taskUpdatedLine = streamLine({
  type: "system",
  subtype: "task_updated",
  task_id: BACKGROUND_TASK_ID,
  patch: { status: "completed", end_time: 1 },
});

export const taskNotificationLine = streamLine({
  type: "system",
  subtype: "task_notification",
  task_id: BACKGROUND_TASK_ID,
  tool_use_id: MAIN_AGENT_TOOL_USE,
  status: "completed",
  summary: "Total Files: 2",
});

export function syncToolResultLine(toolUseId: string, isError: boolean): string {
  return streamLine({
    type: "user",
    parent_tool_use_id: null,
    message: { content: [{ type: "tool_result", tool_use_id: toolUseId, is_error: isError, content: "Report body" }] },
    tool_use_result: { status: "completed" },
  });
}

export const resultLine = streamLine({
  type: "result",
  subtype: "success",
  is_error: false,
  duration_ms: 3933,
  result: "Design folder holds 2 files.",
  total_cost_usd: 0.0959,
});

export const STUDIO_CONFIG: StudioConfig = {
  studioHeadLabel: "Head",
  studioHeadColor: "#d97757",
  userLabel: "You",
  userColor: "#4f7cac",
  departments: [
    { id: "leadership", label: "Leadership", color: "#e0a93b", zone: "open-floor", agents: ["creative-director", "technical-director", "producer"] },
    { id: "programming", label: "Programming", color: "#5b8def", zone: "open-floor", agents: ["lead-programmer", "gameplay-programmer", "engine-programmer", "ai-programmer", "network-programmer", "tools-programmer", "ui-programmer"] },
    { id: "design", label: "Design", color: "#3fb59a", zone: "open-floor", agents: ["game-designer", "systems-designer", "level-designer", "economy-designer", "ux-designer", "live-ops-designer"] },
    { id: "quality", label: "QA", color: "#6fbf5a", zone: "open-floor", agents: ["qa-lead", "qa-tester", "performance-analyst", "devops-engineer", "analytics-engineer", "security-engineer"] },
    { id: "godot", label: "Godot", color: "#478cbf", zone: "engine-lab", agents: ["godot-specialist", "godot-gdscript-specialist", "godot-shader-specialist"] },
    { id: "unreal", label: "Unreal", color: "#4a4f7a", zone: "engine-lab", agents: ["unreal-specialist", "ue-gas-specialist"] },
    { id: "guests", label: "Contractors", color: "#8d939c", zone: "hot-desks", agents: [] },
  ],
  timing: {
    walkTilesPerSecond: 10,
    dispatchQuietMs: 12000,
    speechBubbleMs: 5000,
    toolBubbleMs: 2600,
    meetingTurnMs: 1800,
    meetingArrivalTimeoutMs: 25000,
    ambientMinDelayMs: 25000,
    ambientMaxDelayMs: 70000,
    maxAmbientWalkers: 5,
  },
  visuals: {
    tiltDegrees: 22,
    perspectiveFactor: 1.8,
    tiltShift: { radiusPx: 4, band: 0.22 },
    vignetteStrength: 0.32,
    saturation: 0.22,
    sunbeamAlpha: 0.2,
    sunbeamTint: "#ffd98a",
    sunbeamLengthTiles: 6,
    lampGlowAlpha: 0.32,
    rain: true,
    dayWarmthColor: "#ffd9b0",
    dayWarmthAlpha: 0.18,
    nightShadeColor: "#2a3166",
    nightShadeAlpha: 0.62,
    nightGlowBoost: 2.4,
  },
};

function agent(name: string, tier: RosterAgent["tier"], department: string): RosterAgent {
  return { name, tier, department, description: `${name} description`, model: "inherit" };
}

export const ROSTER: RosterAgent[] = [
  agent("creative-director", "director", "leadership"),
  agent("technical-director", "director", "leadership"),
  agent("producer", "director", "leadership"),
  agent("lead-programmer", "lead", "programming"),
  agent("game-designer", "lead", "design"),
  agent("qa-lead", "lead", "quality"),
  agent("gameplay-programmer", "specialist", "programming"),
  agent("engine-programmer", "specialist", "programming"),
  agent("ai-programmer", "specialist", "programming"),
  agent("network-programmer", "specialist", "programming"),
  agent("tools-programmer", "specialist", "programming"),
  agent("ui-programmer", "specialist", "programming"),
  agent("systems-designer", "specialist", "design"),
  agent("level-designer", "specialist", "design"),
  agent("economy-designer", "specialist", "design"),
  agent("ux-designer", "specialist", "design"),
  agent("live-ops-designer", "specialist", "design"),
  agent("qa-tester", "specialist", "quality"),
  agent("performance-analyst", "specialist", "quality"),
  agent("devops-engineer", "specialist", "quality"),
  agent("godot-specialist", "engine-lead", "godot"),
  agent("godot-gdscript-specialist", "engine-specialist", "godot"),
  agent("godot-shader-specialist", "engine-specialist", "godot"),
  agent("unreal-specialist", "engine-lead", "unreal"),
  agent("ue-gas-specialist", "engine-specialist", "unreal"),
  agent("mystery-agent", "guest", "guests"),
];
