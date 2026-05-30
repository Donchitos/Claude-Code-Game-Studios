/**
 * MatchStateBuffer — client-side interpolation ring buffer (ADR-0006).
 *
 * Holds the last 2 received authoritative match state ticks.
 * Renders interpolated position between them at 60fps via requestAnimationFrame.
 * This is a pure TypeScript module; React Native's rAF is injected via the
 * `scheduleFrame` option.
 */

export interface MatchPlayerState {
  playerId: string;
  x: number;
  y: number;
  hp: number;
  maxHp: number;
  statusEffects: string[];
}

export interface MatchSnapshot {
  tick: number;
  timestamp: number; // server time ms
  players: MatchPlayerState[];
}

export interface InterpolatedPlayerState extends MatchPlayerState {
  interpolatedX: number;
  interpolatedY: number;
}

/** Linear interpolation. */
function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/**
 * Ring buffer holding the two most recent match snapshots.
 * Provides `getInterpolated(renderTime)` for smooth 60fps rendering.
 *
 * Usage (per ADR-0006):
 * ```ts
 * const buffer = new MatchStateBuffer();
 * socket.on('match_state', s => buffer.push(s));
 * // In requestAnimationFrame:
 * const states = buffer.getInterpolated(Date.now() - INTERPOLATION_BUFFER_DELAY_MS);
 * ```
 */
export class MatchStateBuffer {
  private tickA: MatchSnapshot | null = null;
  private tickB: MatchSnapshot | null = null;

  /** Add a new snapshot; oldest is evicted to make room. */
  push(snapshot: MatchSnapshot): void {
    this.tickA = this.tickB;
    this.tickB = snapshot;
  }

  /**
   * Returns interpolated states at `renderTime`.
   * Alpha is clamped to [0, 1] — never extrapolates.
   */
  getInterpolated(renderTime: number): InterpolatedPlayerState[] {
    if (!this.tickB) return [];
    if (!this.tickA) {
      // Only one tick — snap to latest
      return this.tickB.players.map((p) => ({
        ...p, interpolatedX: p.x, interpolatedY: p.y,
      }));
    }

    const span = this.tickB.timestamp - this.tickA.timestamp;
    const alpha = span === 0 ? 1 :
      Math.max(0, Math.min(1, (renderTime - this.tickA.timestamp) / span));

    return this.tickB.players.map((playerB) => {
      const playerA = this.tickA!.players.find((p) => p.playerId === playerB.playerId);
      if (!playerA) return { ...playerB, interpolatedX: playerB.x, interpolatedY: playerB.y };
      return {
        ...playerB,
        interpolatedX: lerp(playerA.x, playerB.x, alpha),
        interpolatedY: lerp(playerA.y, playerB.y, alpha),
      };
    });
  }

  get latestTick(): number {
    return this.tickB?.tick ?? 0;
  }

  clear(): void {
    this.tickA = null;
    this.tickB = null;
  }
}

// ---------------------------------------------------------------------------
// Profile Store logic (framework-agnostic, per ADR-0006)
// ---------------------------------------------------------------------------

export interface PlayerProfile {
  userId: string;
  displayName: string;
  coins: number;
  diamonds: number;
  level: number;
  mmr: number;
  hasPlayPass: boolean;
}

export interface ProfileStoreState {
  profile: PlayerProfile | null;
  isLoading: boolean;
}

export type ProfileStoreListener = (state: ProfileStoreState) => void;

/**
 * Framework-agnostic Profile Store.
 * In production, this is wrapped in a Zustand store.
 * Exported for unit testing without React Native.
 */
export class ProfileStore {
  private state: ProfileStoreState = { profile: null, isLoading: false };
  private listeners: ProfileStoreListener[] = [];

  setProfile(profile: PlayerProfile): void {
    this.state = { profile, isLoading: false };
    this.notify();
  }

  invalidate(): void {
    this.state = { ...this.state, profile: null };
    this.notify();
  }

  setLoading(loading: boolean): void {
    this.state = { ...this.state, isLoading: loading };
    this.notify();
  }

  getState(): ProfileStoreState {
    return this.state;
  }

  subscribe(listener: ProfileStoreListener): () => void {
    this.listeners.push(listener);
    return () => { this.listeners = this.listeners.filter((l) => l !== listener); };
  }

  private notify(): void {
    for (const listener of this.listeners) listener(this.state);
  }
}
