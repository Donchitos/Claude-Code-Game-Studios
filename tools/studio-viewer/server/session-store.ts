import { existsSync, readFileSync } from "node:fs";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { isPermissionMode, type PermissionMode, type TimedEvent } from "../shared/protocol.ts";
import { isValidSessionId } from "./claude-session.ts";

export interface PersistedSession {
  sessionId: string | null;
  permissionMode: PermissionMode;
  costOffsetUsd: number;
  history: TimedEvent[];
}

const SAVE_DELAY_MS = 500;

export function emptySession(permissionMode: PermissionMode): PersistedSession {
  return { sessionId: null, permissionMode, costOffsetUsd: 0, history: [] };
}

export class SessionStore {
  private saveTimer: NodeJS.Timeout | null = null;
  private pending: PersistedSession | null = null;

  constructor(
    private readonly filePath: string,
    private readonly historyLimit: number,
    private readonly defaultPermissionMode: PermissionMode,
  ) {}

  load(): PersistedSession {
    if (!existsSync(this.filePath)) return emptySession(this.defaultPermissionMode);
    try {
      const parsed = JSON.parse(readFileSync(this.filePath, "utf8")) as Partial<PersistedSession>;
      return {
        sessionId: isValidSessionId(parsed.sessionId) ? parsed.sessionId : null,
        permissionMode: isPermissionMode(parsed.permissionMode) ? parsed.permissionMode : this.defaultPermissionMode,
        costOffsetUsd: typeof parsed.costOffsetUsd === "number" ? parsed.costOffsetUsd : 0,
        history: Array.isArray(parsed.history) ? parsed.history.slice(-this.historyLimit) : [],
      };
    } catch {
      return emptySession(this.defaultPermissionMode);
    }
  }

  trim(history: TimedEvent[]): TimedEvent[] {
    return history.length > this.historyLimit ? history.slice(-this.historyLimit) : history;
  }

  save(state: PersistedSession): void {
    this.pending = state;
    if (this.saveTimer) return;
    this.saveTimer = setTimeout(() => {
      this.saveTimer = null;
      void this.flush();
    }, SAVE_DELAY_MS);
  }

  async flush(): Promise<void> {
    const state = this.pending;
    if (!state) return;
    this.pending = null;
    await mkdir(path.dirname(this.filePath), { recursive: true });
    await writeFile(this.filePath, JSON.stringify(state), "utf8");
  }
}
