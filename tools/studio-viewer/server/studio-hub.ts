import type { WebSocket } from "ws";
import {
  isPermissionMode,
  type ClientMessage,
  type RosterAgent,
  type ServerMessage,
  type SessionInfo,
  type StudioConfig,
  type StudioEvent,
} from "../shared/protocol.ts";
import { isRecord } from "../shared/tool-summary.ts";
import type { ClaudeSession } from "./claude-session.ts";
import { StudioEventMapper } from "./event-mapper.ts";
import { emptySession, type PersistedSession, type SessionStore } from "./session-store.ts";
import type { StreamLog } from "./stream-log.ts";

const TRANSIENT_EVENT_KINDS = new Set<StudioEvent["kind"]>(["main_text_delta", "main_status", "agent_thinking"]);
const MAX_MESSAGE_LENGTH = 100_000;

export interface StudioHubOptions {
  session: ClaudeSession;
  store: SessionStore;
  roster: RosterAgent[];
  readConfig(): StudioConfig;
  projectRoot: string;
  modelOverride: string | null;
  streamLog: StreamLog;
}

function parseClientMessage(raw: string): ClientMessage | null {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!isRecord(parsed)) return null;
  switch (parsed["type"]) {
    case "send":
      return typeof parsed["text"] === "string" ? { type: "send", text: parsed["text"] } : null;
    case "stop":
      return { type: "stop" };
    case "new_session":
      return { type: "new_session" };
    case "set_permission_mode":
      return isPermissionMode(parsed["mode"]) ? { type: "set_permission_mode", mode: parsed["mode"] } : null;
    default:
      return null;
  }
}

export class StudioHub {
  private readonly clients = new Set<WebSocket>();
  private readonly mapper = new StudioEventMapper();
  private state: PersistedSession;
  private reportedPermissionMode: string | null = null;
  private model: string | null = null;
  private busy = false;
  private processCostUsd = 0;

  constructor(private readonly options: StudioHubOptions) {
    this.state = options.store.load();
    options.session.on("line", (line) => {
      options.streamLog.write("stdout", line);
      this.publish(this.mapper.mapLine(line));
    });
    options.session.on("stderr", (line) => {
      options.streamLog.write("stderr", line);
      if (line.trim()) this.publish([{ kind: "notice", level: "warning", text: line.trim() }]);
    });
    options.session.on("exit", (exitCode, stoppedByRequest) => this.handleExit(exitCode, stoppedByRequest));
  }

  attach(socket: WebSocket): void {
    this.clients.add(socket);
    socket.on("close", () => this.clients.delete(socket));
    socket.on("message", (data) => {
      const message = parseClientMessage(data.toString());
      if (message) this.handleClientMessage(message);
    });
    this.sendTo(socket, this.helloMessage());
  }

  shutdown(): void {
    this.options.session.stop();
    this.options.streamLog.close();
    void this.options.store.flush();
  }

  private handleClientMessage(message: ClientMessage): void {
    switch (message.type) {
      case "send":
        this.sendUserText(message.text);
        return;
      case "stop":
        this.stopProcess("Stopped. The next message resumes the same conversation.");
        return;
      case "set_permission_mode":
        this.state.permissionMode = message.mode;
        this.stopProcess(`Permission mode set to ${message.mode}. It applies from the next message.`);
        this.persist();
        this.broadcastSession();
        return;
      case "new_session":
        this.stopProcess(null);
        this.mapper.reset();
        this.state = emptySession(this.state.permissionMode);
        this.processCostUsd = 0;
        this.model = null;
        this.persist();
        for (const client of this.clients) this.sendTo(client, this.helloMessage());
        return;
    }
  }

  private sendUserText(rawText: string): void {
    const text = rawText.slice(0, MAX_MESSAGE_LENGTH);
    if (!text.trim()) return;
    if (!this.options.session.running) {
      this.options.session.start({
        projectRoot: this.options.projectRoot,
        permissionMode: this.state.permissionMode,
        resumeSessionId: this.state.sessionId,
        model: this.options.modelOverride,
      });
    }
    this.publish([{ kind: "user_text", text }]);
    this.options.streamLog.write("stdin", JSON.stringify({ type: "user", text }));
    this.options.session.sendUserMessage(text);
    this.busy = true;
    this.broadcastSession();
  }

  private stopProcess(notice: string | null): void {
    if (!this.options.session.running) {
      if (notice) this.publish([{ kind: "notice", level: "info", text: notice }]);
      return;
    }
    this.options.session.stop();
    this.settleProcessCost();
    const events: StudioEvent[] = [...this.mapper.stopAllTasks()];
    if (notice) events.push({ kind: "notice", level: "info", text: notice });
    this.publish(events);
  }

  private handleExit(exitCode: number | null, stoppedByRequest: boolean): void {
    if (stoppedByRequest) {
      this.broadcastSession();
      return;
    }
    this.settleProcessCost();
    const events: StudioEvent[] = [...this.mapper.stopAllTasks(), { kind: "session_exited", exitCode }];
    if (exitCode !== 0) {
      events.push({
        kind: "notice",
        level: "error",
        text: `Claude exited with code ${String(exitCode)}. The next message starts it again and resumes the conversation.`,
      });
    }
    this.publish(events);
  }

  private settleProcessCost(): void {
    this.state.costOffsetUsd += this.processCostUsd;
    this.processCostUsd = 0;
    this.reportedPermissionMode = null;
    this.busy = false;
    this.persist();
    this.broadcastSession();
  }

  private publish(events: StudioEvent[]): void {
    if (events.length === 0) return;
    let sessionChanged = false;
    for (const event of events) {
      sessionChanged = this.applyToSession(event) || sessionChanged;
      const at = Date.now();
      if (!TRANSIENT_EVENT_KINDS.has(event.kind)) this.state.history.push({ at, event });
      this.broadcast({ type: "event", at, event });
    }
    this.state.history = this.options.store.trim(this.state.history);
    this.persist();
    if (sessionChanged) this.broadcastSession();
  }

  private applyToSession(event: StudioEvent): boolean {
    switch (event.kind) {
      case "session_ready":
        this.state.sessionId = event.sessionId || this.state.sessionId;
        this.model = event.model || null;
        this.reportedPermissionMode = event.permissionMode || null;
        return true;
      case "turn_finished":
        this.processCostUsd = event.costUsd;
        this.busy = false;
        return true;
      case "main_status":
        if (event.status === "idle" || this.busy) return false;
        this.busy = true;
        return true;
      default:
        return false;
    }
  }

  private sessionInfo(): SessionInfo {
    return {
      sessionId: this.state.sessionId,
      requestedPermissionMode: this.state.permissionMode,
      reportedPermissionMode: this.reportedPermissionMode,
      model: this.model,
      running: this.options.session.running,
      busy: this.busy,
      totalCostUsd: this.state.costOffsetUsd + this.processCostUsd,
    };
  }

  private helloMessage(): ServerMessage {
    return {
      type: "hello",
      roster: this.options.roster,
      config: this.options.readConfig(),
      history: this.state.history,
      activeTasks: this.mapper.activeTasks(),
      session: this.sessionInfo(),
    };
  }

  private persist(): void {
    this.options.store.save(this.state);
  }

  private broadcastSession(): void {
    this.broadcast({ type: "session", session: this.sessionInfo() });
  }

  private broadcast(message: ServerMessage): void {
    for (const client of this.clients) this.sendTo(client, message);
  }

  private sendTo(socket: WebSocket, message: ServerMessage): void {
    if (socket.readyState === socket.OPEN) socket.send(JSON.stringify(message));
  }
}
