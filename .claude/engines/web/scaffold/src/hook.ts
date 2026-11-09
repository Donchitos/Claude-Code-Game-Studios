// What a check can read and drive: the one-shot's game-state hook, so a
// one-shot's scripted runs carry over when it grows into this layout. A canvas
// shows nothing to page snapshots, so Playwright drives the game through here.
//
//   window.game         scene, state, press(code), hold(code, on), step(n, draw); with the
//                       core loop marked (loop()), events too
//   window.GAME_CLOCK   a clock a check may inject before the game starts
//   window.GAME_AUDIO   an AudioContext a check may inject
//   ?manual=1           the loop does not run; only step() moves the game
//   ?scene=<name>       start in that scene
//   ?seed=<n>           the seed, instead of data/config.json's
//
// Players never see any of it. window.game is set once the game can be driven; a library that
// starts after the page loads (Phaser, PixiJS) sets it then, and until then window.game is the
// canvas (an element's id is a window property), so a check waits for window.game.step.

/** The hook the checks call, as window.game. */
export interface GameHook {
  readonly scene: string;
  readonly state: unknown;
  /** The key (a KeyboardEvent.code) goes down for one step. */
  press(code: string): void;
  /** The key is held down, or let go. */
  hold(code: string, on: boolean): void;
  /** Runs n steps of the game, then draws unless draw is false. */
  step(n?: number, draw?: boolean): void;
  /** The core loop's log: the loop() steps (act, result, reward). A check empties it after each step. */
  readonly events?: unknown[];
}

/** A clock in seconds. */
export interface Clock {
  now(): number;
}

declare global {
  interface Window {
    game?: GameHook;
    GAME_CLOCK?: Clock;
    GAME_AUDIO?: AudioContext;
  }
}

/** The address options. */
export const params = new URLSearchParams(location.search);

/** True when ?manual=1 is in the address: the loop does not run. */
export const manual = params.get('manual') === '1';

/** The clock a check injected, else the page's own. */
export const clock: Clock = window.GAME_CLOCK ?? { now: () => performance.now() / 1000 };

/** The seed from ?seed=, else the fallback. */
export function seedFrom(fallback: number): number {
  return Number(params.get('seed')) || fallback;
}

/** An AudioContext a check injected, else a new one. */
export function audioContext(): AudioContext {
  return window.GAME_AUDIO ?? new AudioContext();
}

/** Puts the hook on window.game. */
export function install(hook: GameHook): void {
  window.game = hook;
}
