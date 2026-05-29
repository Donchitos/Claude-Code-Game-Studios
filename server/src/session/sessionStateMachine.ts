import { randomUUID } from 'crypto';

export type SessionState = 'forming' | 'character_select' | 'active' | 'ended' | 'destroyed';
export type GameMode = 'duel_1v1' | 'squad_3v3' | 'ffa_8';

export interface SessionPlayer {
  userId: string;
  characterId?: string;
  deckSlots?: [string, string];
  isBot: boolean;
  isConnected: boolean;
}

export interface GameSession {
  matchId: string;
  mode: GameMode;
  state: SessionState;
  players: Map<string, SessionPlayer>;
  charSelectDeadline: number;    // ms timestamp
  disconnectTimers: Map<string, ReturnType<typeof setTimeout>>;
  createdAtMs: number;
}

const CHAR_SELECT_TIMEOUT_MS = 30_000;
export const RECONNECT_GRACE_PERIOD_S = 30;

/**
 * Session State Machine (per ADR-0012).
 * Manages the lifecycle: forming → character_select → active → ended → destroyed
 *
 * The Session Manager creates GameSession objects and drives them through
 * the state machine. The Match Server (GameRoom) is instantiated when
 * transitioning to 'active'.
 */
export class SessionStateMachine {
  private sessions = new Map<string, GameSession>();
  private readonly now: () => number;

  constructor(now?: () => number) {
    this.now = now ?? (() => Date.now());
  }

  /** Creates a new session and starts the character-select window. */
  createSession(playerIds: string[], mode: GameMode): GameSession {
    const matchId = randomUUID();
    const players = new Map<string, SessionPlayer>(
      playerIds.map((id) => [id, {
        userId: id,
        isBot: id.startsWith('bot-'),
        isConnected: true,
      }])
    );

    const session: GameSession = {
      matchId,
      mode,
      state: 'forming',
      players,
      charSelectDeadline: this.now() + CHAR_SELECT_TIMEOUT_MS,
      disconnectTimers: new Map(),
      createdAtMs: this.now(),
    };

    this.sessions.set(matchId, session);
    session.state = 'character_select';
    return session;
  }

  /** Records a character confirmation from a player. */
  confirmCharacter(
    matchId: string,
    userId: string,
    characterId: string,
    deckSlots: [string, string],
  ): { allConfirmed: boolean } {
    const session = this.sessions.get(matchId);
    if (!session || session.state !== 'character_select') return { allConfirmed: false };

    const player = session.players.get(userId);
    if (player) {
      player.characterId = characterId;
      player.deckSlots = deckSlots;
    }

    const allConfirmed = [...session.players.values()].every(
      (p) => p.characterId !== undefined || p.isBot,
    );

    if (allConfirmed) {
      session.state = 'active';
    }

    return { allConfirmed };
  }

  /** Assigns a default character to all unconfirmed players (timeout handler). */
  applyCharSelectTimeout(matchId: string, defaultCharacterId = 'character:vex'): void {
    const session = this.sessions.get(matchId);
    if (!session || session.state !== 'character_select') return;

    for (const player of session.players.values()) {
      if (!player.characterId && !player.isBot) {
        player.characterId = defaultCharacterId;
        player.deckSlots = ['ability:fireball', 'ability:frost_bolt'];
      }
    }
    session.state = 'active';
  }

  /** Marks a player as disconnected and starts the reconnect grace timer. */
  onPlayerDisconnect(
    matchId: string,
    userId: string,
    onGraceExpired: (matchId: string, userId: string) => void,
  ): void {
    const session = this.sessions.get(matchId);
    if (!session) return;

    const player = session.players.get(userId);
    if (player) player.isConnected = false;

    const timer = setTimeout(() => {
      onGraceExpired(matchId, userId);
      session.disconnectTimers.delete(userId);
    }, RECONNECT_GRACE_PERIOD_S * 1000);

    session.disconnectTimers.set(userId, timer);
  }

  /** Cancels the grace timer when a player reconnects. */
  onPlayerReconnect(matchId: string, userId: string): boolean {
    const session = this.sessions.get(matchId);
    if (!session) return false;

    const timer = session.disconnectTimers.get(userId);
    if (timer) {
      clearTimeout(timer);
      session.disconnectTimers.delete(userId);
    }

    const player = session.players.get(userId);
    if (player) {
      player.isConnected = true;
      return true;
    }
    return false;
  }

  endSession(matchId: string): void {
    const session = this.sessions.get(matchId);
    if (!session) return;
    for (const timer of session.disconnectTimers.values()) clearTimeout(timer);
    session.disconnectTimers.clear();
    session.state = 'ended';
  }

  destroySession(matchId: string): void {
    const session = this.sessions.get(matchId);
    if (session) {
      this.endSession(matchId);
      session.state = 'destroyed';
      this.sessions.delete(matchId);
    }
  }

  getSession(matchId: string): GameSession | undefined {
    return this.sessions.get(matchId);
  }

  get activeCount(): number {
    return this.sessions.size;
  }
}
