import { MAIN_AGENT, USER_AGENT, type AgentTier, type DepartmentConfig, type RosterAgent, type StudioConfig } from "../../shared/protocol.ts";
import { displayName } from "../../shared/tool-summary.ts";
import type { ActorTask } from "../studio/agent-actor.ts";
import type { ActivityLog } from "./activity-log.ts";
import { element, formatTime } from "./dom.ts";

export interface ActorSnapshot {
  label: string;
  status: string;
  tasks: ActorTask[];
}

export interface InspectorDeps {
  roster: RosterAgent[];
  config: StudioConfig;
  activity: ActivityLog;
  actorSnapshot(agentName: string): ActorSnapshot | null;
  onAsk(agentName: string): void;
  onFocus(agentName: string): void;
  onClose(): void;
}

const TIER_LABELS: Record<AgentTier, string> = {
  director: "Director",
  lead: "Department Lead",
  specialist: "Specialist",
  "engine-lead": "Engine Lead",
  "engine-specialist": "Engine Specialist",
  guest: "Contractor",
};
const VISIBLE_ACTIVITY = 30;

export class Inspector {
  private readonly rosterByName: Map<string, RosterAgent>;
  private readonly departments: Map<string, DepartmentConfig>;
  private agentName: string | null = null;
  private renderedSignature = "";

  constructor(
    private readonly root: HTMLElement,
    private readonly deps: InspectorDeps,
  ) {
    this.rosterByName = new Map(deps.roster.map((agent) => [agent.name, agent]));
    this.departments = new Map(deps.config.departments.map((department) => [department.id, department]));
  }

  get current(): string | null {
    return this.agentName;
  }

  show(agentName: string | null): void {
    this.agentName = agentName;
    this.renderedSignature = "";
    this.root.hidden = agentName === null;
    this.refresh();
  }

  refresh(): void {
    const agentName = this.agentName;
    if (!agentName) return;
    const snapshot = this.deps.actorSnapshot(agentName);
    if (!snapshot) {
      this.show(null);
      return;
    }
    const signature = [
      snapshot.status,
      ...snapshot.tasks.map((task) => task.taskId),
      this.deps.activity.entriesFor(agentName).length,
      this.deps.activity.entriesFor(agentName).at(-1)?.at ?? 0,
    ].join("|");
    if (signature === this.renderedSignature) return;
    this.renderedSignature = signature;
    const roster = this.rosterByName.get(agentName);
    const department = roster ? this.departments.get(roster.department) : undefined;
    const color = this.colorFor(agentName, department);
    const closeButton = element("button", "icon-button", "✕");
    closeButton.type = "button";
    closeButton.title = "Close";
    closeButton.addEventListener("click", () => this.deps.onClose());

    const header = element(
      "header",
      "inspector-header",
      element("span", "inspector-swatch"),
      element("div", "inspector-title", element("strong", "", snapshot.label), element("span", "inspector-status", snapshot.status)),
      closeButton,
    );
    header.style.setProperty("--swatch", color);

    const chips = element("div", "inspector-chips");
    for (const chip of this.chipsFor(agentName, roster, department)) chips.append(element("span", "chip", chip));

    const description = roster?.description ? element("p", "inspector-description", roster.description) : null;
    const tasks = element("section", "inspector-section", element("h4", "", `Current tasks (${snapshot.tasks.length})`));
    if (snapshot.tasks.length === 0) tasks.append(element("p", "muted", "No active tasks."));
    for (const task of snapshot.tasks) {
      tasks.append(
        element(
          "div",
          "inspector-task",
          element("div", "", task.description),
          element("div", "muted", `from ${displayName(task.parentAgent)} · since ${formatTime(task.startedAt)}`),
          task.prompt ? element("details", "", element("summary", "", "Brief"), element("pre", "", task.prompt)) : null,
        ),
      );
    }

    const activityList = element("ol", "inspector-activity");
    const entries = this.deps.activity.entriesFor(agentName).slice(-VISIBLE_ACTIVITY).reverse();
    if (entries.length === 0) activityList.append(element("li", "muted", "Nothing yet this session."));
    for (const entry of entries) {
      activityList.append(
        element("li", "", element("span", "activity-time", formatTime(entry.at)), element("span", "activity-icon", entry.icon), element("span", "activity-text", entry.text)),
      );
    }

    const actions = element("div", "inspector-actions");
    const focusButton = element("button", "ghost-button", "Focus");
    focusButton.type = "button";
    focusButton.addEventListener("click", () => this.deps.onFocus(agentName));
    actions.append(focusButton);
    if (agentName !== USER_AGENT && agentName !== MAIN_AGENT) {
      const askButton = element("button", "primary-button", "Ask in chat");
      askButton.type = "button";
      askButton.addEventListener("click", () => this.deps.onAsk(agentName));
      actions.append(askButton);
    }

    this.root.replaceChildren(
      header,
      chips,
      description ?? "",
      tasks,
      element("section", "inspector-section", element("h4", "", "Recent activity"), activityList),
      actions,
    );
  }

  private colorFor(agentName: string, department: DepartmentConfig | undefined): string {
    if (agentName === MAIN_AGENT) return this.deps.config.studioHeadColor;
    if (agentName === USER_AGENT) return this.deps.config.userColor;
    return department?.color ?? "#8d939c";
  }

  private chipsFor(agentName: string, roster: RosterAgent | undefined, department: DepartmentConfig | undefined): string[] {
    if (agentName === MAIN_AGENT) return ["Main session", "Studio Head"];
    if (agentName === USER_AGENT) return ["You"];
    if (!roster) return ["Contractor", "Built-in agent"];
    return [TIER_LABELS[roster.tier], department?.label ?? "Contractors", `model: ${roster.model}`];
  }
}
