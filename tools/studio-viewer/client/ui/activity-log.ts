import { MAIN_AGENT, USER_AGENT, type StudioEvent } from "../../shared/protocol.ts";
import { displayName, toolIcon, truncate } from "../../shared/tool-summary.ts";

export interface ActivityEntry {
  at: number;
  icon: string;
  text: string;
}

const ENTRY_LIMIT = 80;
const TEXT_LENGTH = 220;
const OUTCOME_ICONS = { completed: "✅", failed: "⚠️", stopped: "⏹" } as const;

export class ActivityLog {
  private readonly entries = new Map<string, ActivityEntry[]>();

  clear(): void {
    this.entries.clear();
  }

  entriesFor(agentName: string): ActivityEntry[] {
    return this.entries.get(agentName) ?? [];
  }

  record(at: number, event: StudioEvent): void {
    switch (event.kind) {
      case "agent_assigned":
        this.add(event.agentType, at, "📋", `Assigned by ${displayName(event.parentAgent)}: ${event.description}`);
        this.add(event.parentAgent, at, "👥", `Delegated to ${displayName(event.agentType)}: ${event.description}`);
        return;
      case "agent_tool":
        this.add(event.agentType, at, toolIcon(event.toolName), `${event.toolName} · ${event.summary}`);
        return;
      case "agent_text":
        this.add(event.agentType, at, "💬", event.text);
        return;
      case "agent_finished":
        this.add(event.agentType, at, OUTCOME_ICONS[event.outcome], event.summary || event.outcome);
        return;
      case "agent_message":
        this.add(event.fromAgent, at, "💬", `To ${displayName(event.toAgent)}: ${event.text}`);
        this.add(event.toAgent, at, "📨", `From ${displayName(event.fromAgent)}: ${event.text}`);
        return;
      case "main_tool":
        this.add(MAIN_AGENT, at, toolIcon(event.toolName), `${event.toolName} · ${event.summary}`);
        return;
      case "main_text":
        this.add(MAIN_AGENT, at, "💬", event.text);
        return;
      case "user_text":
        this.add(USER_AGENT, at, "🗨️", event.text);
        return;
      default:
        return;
    }
  }

  private add(agentName: string, at: number, icon: string, text: string): void {
    const list = this.entries.get(agentName) ?? [];
    list.push({ at, icon, text: truncate(text, TEXT_LENGTH) });
    if (list.length > ENTRY_LIMIT) list.splice(0, list.length - ENTRY_LIMIT);
    this.entries.set(agentName, list);
  }
}
