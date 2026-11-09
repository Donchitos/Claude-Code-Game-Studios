import { MAIN_AGENT, type StudioEvent } from "../../shared/protocol.ts";
import { displayName, toolIcon, truncate } from "../../shared/tool-summary.ts";
import { element } from "./dom.ts";

const VISIBLE_LINES = 4;
const LINE_LIFETIME_MS = 9000;
const LINE_LENGTH = 90;

function describe(event: StudioEvent): string | null {
  switch (event.kind) {
    case "agent_assigned":
      return `📋 ${displayName(event.parentAgent)} → ${displayName(event.agentType)}: ${event.description}`;
    case "agent_tool":
      return `${toolIcon(event.toolName)} ${displayName(event.agentType)}: ${event.summary}`;
    case "agent_finished":
      return `${event.outcome === "completed" ? "✅" : "⚠️"} ${displayName(event.agentType)} ${event.outcome}`;
    case "agent_message":
      return `💬 ${displayName(event.fromAgent)} → ${displayName(event.toAgent)}`;
    case "main_tool":
      return `${toolIcon(event.toolName)} ${displayName(MAIN_AGENT)}: ${event.summary}`;
    default:
      return null;
  }
}

export class ActivityTicker {
  constructor(private readonly root: HTMLElement) {}

  push(event: StudioEvent): void {
    const text = describe(event);
    if (!text) return;
    const line = element("div", "ticker-line", truncate(text, LINE_LENGTH));
    this.root.append(line);
    while (this.root.childElementCount > VISIBLE_LINES) this.root.firstElementChild?.remove();
    window.setTimeout(() => {
      line.classList.add("ticker-line-fading");
      window.setTimeout(() => line.remove(), 600);
    }, LINE_LIFETIME_MS);
  }
}
