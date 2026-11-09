import type { SessionInfo } from "../../shared/protocol.ts";
import type { ConnectionState } from "../socket.ts";
import { element, formatCost } from "./dom.ts";

export interface TopBarActions {
  fit(): void;
  setTilt(enabled: boolean): void;
  setFollow(enabled: boolean): void;
  setAmbient(enabled: boolean): void;
  setLabels(enabled: boolean): void;
  setNight(enabled: boolean): void;
}

function toggleButton(label: string, title: string, initial: boolean, onChange: (enabled: boolean) => void): HTMLButtonElement {
  const button = element("button", "toggle-button", label);
  button.type = "button";
  button.title = title;
  button.setAttribute("aria-pressed", String(initial));
  button.addEventListener("click", () => {
    const enabled = button.getAttribute("aria-pressed") !== "true";
    button.setAttribute("aria-pressed", String(enabled));
    onChange(enabled);
  });
  return button;
}

export class TopBar {
  private readonly connection: HTMLSpanElement;
  private readonly model: HTMLSpanElement;
  private readonly mode: HTMLSpanElement;
  private readonly agents: HTMLSpanElement;
  private readonly cost: HTMLSpanElement;

  constructor(root: HTMLElement, actions: TopBarActions, initialNight: boolean) {
    this.connection = element("span", "connection-dot");
    this.model = element("span", "stat", "model —");
    this.mode = element("span", "stat", "mode —");
    this.agents = element("span", "stat", "0 agents busy");
    this.cost = element("span", "stat", "$0.000");
    const fitButton = element("button", "toggle-button", "Fit");
    fitButton.type = "button";
    fitButton.title = "Show the whole studio";
    fitButton.addEventListener("click", () => actions.fit());
    root.append(
      element("div", "brand", this.connection, element("strong", "", "CCGS Studio")),
      element("div", "stats", this.agents, this.model, this.mode, this.cost),
      element(
        "div",
        "view-controls",
        fitButton,
        toggleButton("🌙 Night", "Switch the studio and the interface to night", initialNight, actions.setNight),
        toggleButton("2.5D", "Diorama tilt with tilt-shift blur", true, actions.setTilt),
        toggleButton("Follow", "Move the camera to whoever is active", false, actions.setFollow),
        toggleButton("Ambient", "Idle agents wander, grab coffee and chat", true, actions.setAmbient),
        toggleButton("Labels", "Room and team labels", true, actions.setLabels),
      ),
    );
  }

  setConnection(state: ConnectionState): void {
    this.connection.dataset["state"] = state;
    this.connection.title = state === "open" ? "Connected to the studio server" : state === "connecting" ? "Connecting…" : "Disconnected, retrying";
  }

  updateSession(session: SessionInfo): void {
    this.model.textContent = `model ${session.model ?? "—"}`;
    const reported = session.reportedPermissionMode;
    const mismatch = reported !== null && reported !== session.requestedPermissionMode;
    this.mode.textContent = `mode ${reported ?? session.requestedPermissionMode}${mismatch ? " ⚠" : ""}`;
    this.mode.title = mismatch
      ? `Requested ${session.requestedPermissionMode}, Claude reports ${reported}`
      : reported
        ? "Mode reported by the running session"
        : "Mode used when the session next starts";
    this.mode.classList.toggle("stat-warning", mismatch);
    this.cost.textContent = formatCost(session.totalCostUsd);
    this.cost.title = "Total cost reported by Claude Code for this conversation";
  }

  setBusyAgents(count: number): void {
    this.agents.textContent = `${count} agent${count === 1 ? "" : "s"} busy`;
  }
}
