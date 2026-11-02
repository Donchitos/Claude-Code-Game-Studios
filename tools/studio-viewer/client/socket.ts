import type { ClientMessage, ServerMessage } from "../shared/protocol.ts";

export type ConnectionState = "connecting" | "open" | "closed";

const INITIAL_RETRY_MS = 500;
const MAX_RETRY_MS = 8000;

export class StudioSocket {
  private socket: WebSocket | null = null;
  private retryMs = INITIAL_RETRY_MS;
  private readonly messageListeners = new Set<(message: ServerMessage) => void>();
  private readonly stateListeners = new Set<(state: ConnectionState) => void>();

  constructor(private readonly url: string) {}

  connect(): void {
    this.emitState("connecting");
    const socket = new WebSocket(this.url);
    this.socket = socket;
    socket.addEventListener("open", () => {
      this.retryMs = INITIAL_RETRY_MS;
      this.emitState("open");
    });
    socket.addEventListener("message", (event) => {
      let message: ServerMessage;
      try {
        message = JSON.parse(String(event.data)) as ServerMessage;
      } catch {
        return;
      }
      for (const listener of this.messageListeners) listener(message);
    });
    socket.addEventListener("close", () => {
      if (this.socket !== socket) return;
      this.socket = null;
      this.emitState("closed");
      window.setTimeout(() => this.connect(), this.retryMs);
      this.retryMs = Math.min(this.retryMs * 2, MAX_RETRY_MS);
    });
  }

  send(message: ClientMessage): boolean {
    if (this.socket?.readyState !== WebSocket.OPEN) return false;
    this.socket.send(JSON.stringify(message));
    return true;
  }

  onMessage(listener: (message: ServerMessage) => void): void {
    this.messageListeners.add(listener);
  }

  onState(listener: (state: ConnectionState) => void): void {
    this.stateListeners.add(listener);
  }

  private emitState(state: ConnectionState): void {
    for (const listener of this.stateListeners) listener(state);
  }
}
