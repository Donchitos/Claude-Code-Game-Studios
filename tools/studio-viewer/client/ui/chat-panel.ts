import DOMPurify from "dompurify";
import { marked } from "marked";
import {
  MAIN_AGENT,
  PERMISSION_MODES,
  isPermissionMode,
  type ClientMessage,
  type PermissionMode,
  type SessionInfo,
  type StudioEvent,
  type TimedEvent,
} from "../../shared/protocol.ts";
import { displayName, toolIcon, truncate } from "../../shared/tool-summary.ts";
import { element, formatCost, formatTime } from "./dom.ts";

export interface ChatPanelDeps {
  send(message: ClientMessage): boolean;
  onAgentClick(agentName: string): void;
}

const MODE_LABELS: Record<PermissionMode, string> = {
  auto: "auto — classifier approves",
  acceptEdits: "acceptEdits — edits allowed",
  plan: "plan — read-only planning",
  manual: "manual — unlisted tools refused",
  dontAsk: "dontAsk — refuse anything unlisted",
  bypassPermissions: "bypassPermissions — allow everything",
};
const NEAR_BOTTOM_PX = 120;
const OUTCOME_LABELS = { completed: "✅ Done", failed: "⚠️ Failed", stopped: "⏹ Stopped" } as const;

DOMPurify.addHook("afterSanitizeAttributes", (node) => {
  if (node instanceof HTMLAnchorElement) {
    node.setAttribute("target", "_blank");
    node.setAttribute("rel", "noopener noreferrer");
  }
});

function renderMarkdown(text: string): string {
  return DOMPurify.sanitize(marked.parse(text, { async: false, gfm: true, breaks: true }));
}

export class ChatPanel {
  private readonly log: HTMLDivElement;
  private readonly draft: HTMLDivElement;
  private readonly input: HTMLTextAreaElement;
  private readonly sendButton: HTMLButtonElement;
  private readonly stopButton: HTMLButtonElement;
  private readonly modeSelect: HTMLSelectElement;
  private readonly statusPill: HTMLSpanElement;
  private readonly hint: HTMLSpanElement;
  private readonly agentCards = new Map<string, HTMLElement>();
  private session: SessionInfo | null = null;
  private connected = false;

  constructor(
    root: HTMLElement,
    private readonly deps: ChatPanelDeps,
  ) {
    this.statusPill = element("span", "status-pill", "offline");
    this.modeSelect = element("select", "mode-select");
    this.modeSelect.title = "Permission mode for the headless session";
    for (const mode of PERMISSION_MODES) {
      const option = element("option", "", MODE_LABELS[mode]);
      option.value = mode;
      this.modeSelect.append(option);
    }
    this.modeSelect.addEventListener("change", () => this.changeMode());
    const newButton = element("button", "ghost-button", "New chat");
    newButton.type = "button";
    newButton.addEventListener("click", () => this.startNewSession());

    this.log = element("div", "chat-log");
    this.log.setAttribute("aria-live", "polite");
    this.draft = element("div", "chat-message chat-assistant chat-draft");
    this.draft.hidden = true;

    this.input = element("textarea", "chat-input");
    this.input.rows = 3;
    this.input.placeholder = "Message the studio… (Enter to send, Shift+Enter for a new line, /help works)";
    this.input.addEventListener("keydown", (event) => {
      if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
        event.preventDefault();
        this.submit();
      }
    });
    this.input.addEventListener("input", () => this.updateComposer());
    this.sendButton = element("button", "primary-button", "Send");
    this.sendButton.type = "submit";
    this.stopButton = element("button", "danger-button", "Stop");
    this.stopButton.type = "button";
    this.stopButton.addEventListener("click", () => this.deps.send({ type: "stop" }));
    this.hint = element("span", "composer-hint");
    const form = element(
      "form",
      "chat-composer",
      this.input,
      element("div", "composer-actions", this.hint, this.stopButton, this.sendButton),
    );
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      this.submit();
    });

    root.append(
      element(
        "header",
        "chat-header",
        element("div", "chat-title", element("strong", "", "Main session"), this.statusPill),
        element("div", "chat-controls", this.modeSelect, newButton),
      ),
      element("div", "chat-scroll", this.log, this.draft),
      form,
    );
    this.updateComposer();
  }

  setConnected(connected: boolean): void {
    this.connected = connected;
    this.updateComposer();
  }

  prefill(text: string): void {
    this.input.value = text;
    this.input.focus();
    this.input.setSelectionRange(text.length, text.length);
    this.updateComposer();
  }

  reset(history: TimedEvent[], session: SessionInfo): void {
    this.log.replaceChildren();
    this.agentCards.clear();
    this.clearDraft();
    for (const entry of history) this.render(entry.at, entry.event);
    if (history.length === 0) this.appendWelcome();
    this.updateSession(session);
    this.scrollToBottom(true);
  }

  updateSession(session: SessionInfo): void {
    this.session = session;
    this.modeSelect.value = session.requestedPermissionMode;
    const state = session.busy ? "working" : session.running ? "ready" : session.sessionId ? "paused" : "not started";
    this.statusPill.textContent = state;
    this.statusPill.dataset["state"] = state;
    this.updateComposer();
  }

  handle(at: number, event: StudioEvent): void {
    const stick = this.isNearBottom();
    this.render(at, event);
    this.scrollToBottom(stick);
  }

  private render(at: number, event: StudioEvent): void {
    switch (event.kind) {
      case "user_text":
        this.append(element("div", "chat-message chat-user", element("div", "message-body", event.text)), at);
        return;
      case "main_text_delta":
        this.draft.hidden = false;
        this.draft.textContent = (this.draft.textContent ?? "") + event.text;
        return;
      case "main_text": {
        this.clearDraft();
        const body = element("div", "message-body markdown");
        body.innerHTML = renderMarkdown(event.text);
        this.append(element("div", "chat-message chat-assistant", body), at);
        return;
      }
      case "main_tool":
        this.append(
          element("div", "chat-tool", element("span", "tool-icon", toolIcon(event.toolName)), element("span", "tool-name", event.toolName), element("span", "tool-summary", event.summary)),
          at,
        );
        return;
      case "agent_assigned":
        this.renderAgentCard(at, event);
        return;
      case "agent_tool": {
        const activity = this.agentCards.get(event.taskId)?.querySelector(".agent-card-activity");
        if (activity) activity.textContent = `${toolIcon(event.toolName)} ${event.summary}`;
        return;
      }
      case "agent_text": {
        const activity = this.agentCards.get(event.taskId)?.querySelector(".agent-card-activity");
        if (activity) activity.textContent = `💬 ${truncate(event.text, 120)}`;
        return;
      }
      case "agent_finished":
        this.finishAgentCard(event.taskId, event.outcome, event.summary);
        return;
      case "agent_message":
        this.append(
          element("div", "chat-system", `💬 ${displayName(event.fromAgent)} → ${displayName(event.toAgent)}: ${truncate(event.text, 200)}`),
          at,
        );
        return;
      case "turn_finished":
        this.clearDraft();
        this.append(
          element(
            "div",
            event.isError ? "chat-turn chat-turn-error" : "chat-turn",
            event.isError ? `⚠️ ${truncate(event.resultText || "Turn ended with an error", 300)}` : `Turn finished · ${(event.durationMs / 1000).toFixed(1)}s`,
          ),
          at,
        );
        return;
      case "notice":
        this.renderNotice(at, event.level, event.text);
        return;
      case "session_ready":
        this.renderSessionReady(at, event.model, event.permissionMode);
        return;
      case "session_exited":
        this.clearDraft();
        this.append(element("div", "chat-system", `Session process exited (code ${String(event.exitCode)}).`), at);
        return;
      default:
        return;
    }
  }

  private renderAgentCard(at: number, event: Extract<StudioEvent, { kind: "agent_assigned" }>): void {
    const nameButton = element("button", "agent-link", displayName(event.agentType));
    nameButton.type = "button";
    nameButton.addEventListener("click", () => this.deps.onAgentClick(event.agentType));
    const from = event.parentAgent === MAIN_AGENT ? "" : ` · from ${displayName(event.parentAgent)}`;
    const prompt = element("details", "agent-card-prompt", element("summary", "", "Brief"), element("pre", "", event.prompt));
    const card = element(
      "div",
      "agent-card",
      element("div", "agent-card-head", element("span", "", "👥"), nameButton, element("span", "agent-card-status", "working…")),
      element("div", "agent-card-description", `${event.description}${from}`),
      element("div", "agent-card-activity", "Receiving the task…"),
      event.prompt ? prompt : null,
    );
    this.agentCards.set(event.taskId, card);
    this.append(card, at);
  }

  private finishAgentCard(taskId: string, outcome: keyof typeof OUTCOME_LABELS, summary: string): void {
    const card = this.agentCards.get(taskId);
    if (!card) return;
    card.classList.add(`agent-card-${outcome}`);
    const status = card.querySelector(".agent-card-status");
    if (status) status.textContent = OUTCOME_LABELS[outcome];
    const activity = card.querySelector(".agent-card-activity");
    if (!activity) return;
    if (!summary) {
      activity.remove();
      return;
    }
    const body = element("div", "markdown agent-card-summary");
    body.innerHTML = renderMarkdown(summary);
    activity.replaceWith(element("details", "agent-card-result", element("summary", "", truncate(summary, 110)), body));
  }

  private renderNotice(at: number, level: "info" | "warning" | "error", text: string): void {
    const lines = text.split(/\r?\n/).filter((line) => line.trim());
    const firstLine = lines[0] ?? text;
    if (lines.length <= 1) {
      this.append(element("div", `chat-notice chat-notice-${level}`, text), at);
      return;
    }
    this.append(
      element("details", `chat-notice chat-notice-${level}`, element("summary", "", firstLine), element("pre", "", lines.slice(1).join("\n"))),
      at,
    );
  }

  private renderSessionReady(at: number, model: string, permissionMode: string): void {
    const requested = this.session?.requestedPermissionMode;
    const mismatch = requested && permissionMode && requested !== permissionMode;
    this.append(element("div", "chat-system", `Session ready · ${model || "default model"} · mode ${permissionMode || "unknown"}`), at);
    if (mismatch) {
      this.renderNotice(
        at,
        "warning",
        `Asked for permission mode "${requested}" but Claude reports "${permissionMode}". The requested mode may be unavailable for this model or account, or the workspace is not trusted yet (run claude once interactively in the project root and accept the trust prompt).`,
      );
    }
  }

  private appendWelcome(): void {
    this.log.append(
      element(
        "div",
        "chat-welcome",
        element("strong", "", "Welcome to the studio."),
        element(
          "p",
          "",
          "Messages here go to a headless Claude Code session running in the project root. When it delegates, the giver walks the task over to the agent's desk; agents tasked together meet in the Meeting Room; results are carried back when done.",
        ),
        element("p", "", "Try /help or /start."),
      ),
    );
  }

  private append(node: HTMLElement, at: number): void {
    node.title = formatTime(at);
    this.log.append(node);
  }

  private clearDraft(): void {
    this.draft.textContent = "";
    this.draft.hidden = true;
  }

  private isNearBottom(): boolean {
    const scroller = this.log.parentElement;
    if (!scroller) return true;
    return scroller.scrollHeight - scroller.scrollTop - scroller.clientHeight < NEAR_BOTTOM_PX;
  }

  private scrollToBottom(force: boolean): void {
    const scroller = this.log.parentElement;
    if (scroller && force) scroller.scrollTop = scroller.scrollHeight;
  }

  private submit(): void {
    const text = this.input.value;
    if (!text.trim() || !this.connected) return;
    if (this.deps.send({ type: "send", text })) {
      this.input.value = "";
      this.updateComposer();
    }
  }

  private changeMode(): void {
    const mode = this.modeSelect.value;
    const previous = this.session?.requestedPermissionMode ?? "auto";
    if (!isPermissionMode(mode)) return;
    const confirmations: string[] = [];
    if (mode === "bypassPermissions") confirmations.push("bypassPermissions lets Claude run any tool without checks.");
    if (this.session?.busy) confirmations.push("Changing mode stops the current turn.");
    if (confirmations.length > 0 && !window.confirm(`${confirmations.join(" ")} Continue?`)) {
      this.modeSelect.value = previous;
      return;
    }
    if (!this.deps.send({ type: "set_permission_mode", mode })) this.modeSelect.value = previous;
  }

  private startNewSession(): void {
    const message =
      "Start a new conversation? This panel's history is cleared. The old conversation stays in Claude Code's own history.";
    if (window.confirm(message)) this.deps.send({ type: "new_session" });
  }

  private updateComposer(): void {
    const busy = this.session?.busy ?? false;
    this.input.disabled = !this.connected;
    this.sendButton.disabled = !this.connected || !this.input.value.trim();
    this.stopButton.hidden = !busy;
    const cost = this.session ? formatCost(this.session.totalCostUsd) : "";
    this.hint.textContent = !this.connected ? "Reconnecting…" : busy ? `Working… · ${cost}` : cost ? `Session cost ${cost}` : "";
  }
}
