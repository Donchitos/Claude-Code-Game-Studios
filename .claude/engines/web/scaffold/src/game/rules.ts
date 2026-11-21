// The game's rules: plain TypeScript with no browser in it, so Vitest can run
// them in Node (tests/unit/). Everything that touches the page is in main.ts.

/** The values the rules read, from data/config.json. */
export interface Tuning {
  /** Speed of the player's square, in logical pixels a second. */
  speed: number;
}

/** The game's own state; window.game.state reports it to the checks. */
export interface State {
  /** Seconds of play. */
  t: number;
  score: number;
  x: number;
  y: number;
}

/** The size of the play field, in logical pixels. */
export const FIELD = { w: 320, h: 180, size: 8 } as const;

/** Simulation step in seconds: motion is per second, never per frame. */
export const STEP = 1 / 60;

/**
 * A seeded random number generator (mulberry32). Every gameplay random call
 * reads one of these, never Math.random, so a replay repeats exactly.
 */
export function makeRng(seed: number): () => number {
  let s = seed | 0;
  return () => {
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), s | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** A new session's state. */
export function newState(): State {
  return { t: 0, score: 0, x: (FIELD.w - FIELD.size) / 2, y: (FIELD.h - FIELD.size) / 2 };
}

/** Which way the player is pushing, each -1, 0 or 1. */
export interface Move {
  dx: number;
  dy: number;
}

/** One step of play: moves the square, kept inside the field. */
export function update(state: State, move: Move, tuning: Tuning, dt: number): void {
  state.t += dt;
  state.x = clamp(state.x + move.dx * tuning.speed * dt, 0, FIELD.w - FIELD.size);
  state.y = clamp(state.y + move.dy * tuning.speed * dt, 0, FIELD.h - FIELD.size);
}

function clamp(v: number, lo: number, hi: number): number {
  return Math.min(hi, Math.max(lo, v));
}
