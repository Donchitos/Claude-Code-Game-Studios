export type AgentTier = "director" | "lead" | "specialist" | "engine-lead" | "engine-specialist" | "guest";

export type DepartmentZone = "open-floor" | "engine-lab" | "hot-desks";

export interface RosterAgent {
  name: string;
  description: string;
  model: string;
  tier: AgentTier;
  department: string;
}

export interface DepartmentConfig {
  id: string;
  label: string;
  color: string;
  zone: DepartmentZone;
  agents: string[];
}

export interface TimingConfig {
  walkTilesPerSecond: number;
  dispatchQuietMs: number;
  speechBubbleMs: number;
  toolBubbleMs: number;
  meetingTurnMs: number;
  meetingArrivalTimeoutMs: number;
  ambientMinDelayMs: number;
  ambientMaxDelayMs: number;
  maxAmbientWalkers: number;
}

export interface TiltShiftConfig {
  radiusPx: number;
  band: number;
}

export interface VisualConfig {
  tiltDegrees: number;
  perspectiveFactor: number;
  tiltShift: TiltShiftConfig;
  vignetteStrength: number;
  saturation: number;
  sunbeamAlpha: number;
  sunbeamTint: string;
  sunbeamLengthTiles: number;
  lampGlowAlpha: number;
  rain: boolean;
  dayWarmthColor: string;
  dayWarmthAlpha: number;
  nightShadeColor: string;
  nightShadeAlpha: number;
  nightGlowBoost: number;
}

export const DEFAULT_VISUALS: VisualConfig = {
  tiltDegrees: 22,
  perspectiveFactor: 1.8,
  tiltShift: { radiusPx: 4, band: 0.22 },
  vignetteStrength: 0.28,
  saturation: 0.12,
  sunbeamAlpha: 0.24,
  sunbeamTint: "#ffe2a0",
  sunbeamLengthTiles: 6,
  lampGlowAlpha: 0.22,
  rain: true,
  dayWarmthColor: "#ffd9b0",
  dayWarmthAlpha: 0.18,
  nightShadeColor: "#2a3166",
  nightShadeAlpha: 0.62,
  nightGlowBoost: 2.4,
};

export function withVisualDefaults(config: StudioConfig): StudioConfig {
  const visuals: Partial<VisualConfig> = config.visuals ?? {};
  return {
    ...config,
    visuals: {
      ...DEFAULT_VISUALS,
      ...visuals,
      tiltShift: { ...DEFAULT_VISUALS.tiltShift, ...(visuals.tiltShift ?? {}) },
    },
  };
}

export interface StudioConfig {
  studioHeadLabel: string;
  studioHeadColor: string;
  userLabel: string;
  userColor: string;
  departments: DepartmentConfig[];
  timing: TimingConfig;
  visuals: VisualConfig;
}

export const PERMISSION_MODES = ["auto", "acceptEdits", "plan", "manual", "dontAsk", "bypassPermissions"] as const;
export type PermissionMode = (typeof PERMISSION_MODES)[number];

export function isPermissionMode(value: unknown): value is PermissionMode {
  return typeof value === "string" && (PERMISSION_MODES as readonly string[]).includes(value);
}

export const MAIN_AGENT = "studio-head";
export const USER_AGENT = "you";
export const GUEST_DEPARTMENT = "guests";

export type MainStatus = "thinking" | "responding" | "working" | "idle";
export type TaskOutcome = "completed" | "failed" | "stopped";
export type NoticeLevel = "info" | "warning" | "error";

export type StudioEvent =
  | { kind: "session_ready"; sessionId: string; model: string; permissionMode: string; cwd: string }
  | { kind: "main_status"; status: MainStatus }
  | { kind: "main_tool"; toolUseId: string; toolName: string; summary: string }
  | { kind: "main_text_delta"; text: string }
  | { kind: "main_text"; messageId: string; text: string }
  | { kind: "user_text"; text: string }
  | {
      kind: "agent_assigned";
      taskId: string;
      agentType: string;
      description: string;
      prompt: string;
      parentAgent: string;
    }
  | { kind: "agent_tool"; taskId: string; agentType: string; toolName: string; summary: string }
  | { kind: "agent_text"; taskId: string; agentType: string; text: string }
  | { kind: "agent_thinking"; taskId: string; agentType: string }
  | { kind: "agent_finished"; taskId: string; agentType: string; outcome: TaskOutcome; summary: string }
  | { kind: "agent_message"; fromAgent: string; toAgent: string; text: string }
  | { kind: "turn_finished"; costUsd: number; durationMs: number; isError: boolean; resultText: string }
  | { kind: "notice"; level: NoticeLevel; text: string }
  | { kind: "session_exited"; exitCode: number | null };

export interface TimedEvent {
  at: number;
  event: StudioEvent;
}

export interface ActiveTask {
  taskId: string;
  agentType: string;
  description: string;
  parentAgent: string;
}

export interface SessionInfo {
  sessionId: string | null;
  requestedPermissionMode: PermissionMode;
  reportedPermissionMode: string | null;
  model: string | null;
  running: boolean;
  busy: boolean;
  totalCostUsd: number;
}

export type ServerMessage =
  | {
      type: "hello";
      roster: RosterAgent[];
      config: StudioConfig;
      history: TimedEvent[];
      activeTasks: ActiveTask[];
      session: SessionInfo;
    }
  | { type: "event"; at: number; event: StudioEvent }
  | { type: "session"; session: SessionInfo };

export type ClientMessage =
  | { type: "send"; text: string }
  | { type: "stop" }
  | { type: "set_permission_mode"; mode: PermissionMode }
  | { type: "new_session" };
