// The page: screen, input, sound, scenes and the loop, drawn with Phaser. The rules are in
// game/rules.ts; what the checks drive is in hook.ts. Phaser runs its own loop and time; with
// ?manual=1 its loop sleeps, and window.game.step() moves it one step at a time.

import * as Phaser from 'phaser';
import config from '../data/config.json';
import { FIELD, STEP, makeRng, newState, update, type State, type Tuning } from './game/rules';
import { audioContext, clock, install, manual, params, seedFrom } from './hook';

// ---- Values: data/config.json holds every tuning value ----------------------------------
const tuning: Tuning = { speed: config.speed.value };
const W = FIELD.w, H = FIELD.h;
const FONT = 'sans-serif';
const TITLE = document.title;
const CONTROLS = ['Arrows: move', 'P: pause', 'M: mute'];

// ---- Input: keys by position (event.code), OS key repeat ignored ------------------------
// The page's own key events, not Phaser's keyboard plugin, so window.game.press() and a
// player's key reach the game the same way.
const down = new Set<string>(), hit = new Set<string>();
const pressed = (code: string): boolean => hit.has(code); // true for one step after the key goes down
addEventListener('keydown', e => {
  startAudio();
  if (!e.repeat) { down.add(e.code); hit.add(e.code); }
  if (e.code === 'Space' || e.code.startsWith('Arrow')) e.preventDefault();
});
addEventListener('keyup', e => down.delete(e.code));
addEventListener('pointerup', () => startAudio()); // a touch's pointerdown does not count as a gesture
addEventListener('blur', () => down.clear());

// ---- Sound: started on the first gesture, scheduled on the audio clock, mute on M --------
// Plain Web Audio, so a check can inject window.GAME_AUDIO; Phaser's own sound is off.
let audio: { ac: AudioContext; out: GainNode } | null = null, muted = false;
function startAudio(): void {
  if (!audio) {
    const ac = audioContext();
    const out = ac.createGain(); out.gain.value = muted ? 0 : config.volume.value;
    out.connect(ac.destination); audio = { ac, out };
  }
  if (audio.ac.state === 'suspended') void audio.ac.resume();
}
function setMuted(m: boolean): void { muted = m; if (audio) audio.out.gain.value = m ? 0 : config.volume.value; }
function tone(freq: number, dur: number, type: OscillatorType = 'square', vol = 0.3): void {
  if (!audio || muted) return;
  const t = audio.ac.currentTime, o = audio.ac.createOscillator(), g = audio.ac.createGain();
  o.type = type; o.frequency.value = freq;
  g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  o.connect(g).connect(audio.out); o.start(t); o.stop(t + dur);
}

// ---- Scenes: the game's own (title, play, pause), drawn by one Phaser scene ------------------
let scene = '', state: State = newState(), rng = makeRng(seedFrom(config.seed));
function reset(): void {
  rng = makeRng(seedFrom(config.seed)); // every gameplay random call reads rng(), never Math.random
  state = newState();
}
const scenes: Record<string, { update(dt: number): void }> = {
  title: { update() { if (pressed('Enter') || pressed('Space')) { reset(); tone(440, 0.1); scene = 'play'; } } },
  play: {
    update(dt) {
      if (pressed('KeyP') || pressed('Escape')) { scene = 'pause'; return; }
      const dx = (down.has('ArrowRight') ? 1 : 0) - (down.has('ArrowLeft') ? 1 : 0);
      const dy = (down.has('ArrowDown') ? 1 : 0) - (down.has('ArrowUp') ? 1 : 0);
      update(state, { dx, dy }, tuning, dt);
    },
  },
  pause: { update() { if (pressed('KeyP') || pressed('Escape')) scene = 'play'; } },
};
function step(): void {
  if (pressed('KeyM')) setMuted(!muted);
  scenes[scene].update(STEP);
  hit.clear();
}

class Game extends Phaser.Scene {
  private square!: Phaser.GameObjects.Rectangle;
  private score!: Phaser.GameObjects.Text;
  private menu!: Phaser.GameObjects.Container;
  private paused!: Phaser.GameObjects.Text;
  private acc = 0;
  constructor() { super('game'); }

  create(): void {
    const label = (x: number, y: number, s: string, size: number, c = '#fff') =>
      this.add.text(x, y, s, { fontFamily: FONT, fontSize: `${size}px`, color: c }).setOrigin(0.5);
    this.square = this.add.rectangle(0, 0, FIELD.size, FIELD.size, 0x44ccff).setOrigin(0);
    this.score = this.add.text(8, 4, '', { fontFamily: FONT, fontSize: '8px', color: '#fff' });
    this.menu = this.add.container(0, 0, [
      label(W / 2, H / 3, TITLE, 16),
      ...CONTROLS.map((c, i) => label(W / 2, H / 2 + i * 11, c, 8, '#ccc')),
      label(W / 2, H - 16, 'Enter to start', 8),
    ]);
    this.paused = label(W / 2, H / 2, 'Paused', 12);
    this.draw();
    if (manual) this.game.loop.sleep(); // ?manual=1: only window.game.step() moves the game
    install(hook);
  }

  // Phaser calls this every frame with its own time; delta is in milliseconds.
  update(_time: number, delta: number): void {
    lastFrame = clock.now();
    if (manual) { if (stepping) step(); } // each window.game.step() is one Phaser frame of exactly STEP
    else {
      this.acc += Math.min(delta / 1000, 0.25); // a stall never fast-forwards the game
      while (this.acc >= STEP) { step(); this.acc -= STEP; }
    }
    this.draw();
  }

  draw(): void {
    this.square.setPosition(Math.round(state.x), Math.round(state.y)).setVisible(scene !== 'title');
    this.score.setText(`${state.score}`).setVisible(scene !== 'title');
    this.menu.setVisible(scene === 'title');
    this.paused.setVisible(scene === 'pause');
  }
}

function hasWebGL(): boolean {
  const c = document.createElement('canvas');
  return !!(c.getContext('webgl2') ?? c.getContext('webgl'));
}

reset();
const asked = params.get('scene');
scene = asked && asked in scenes ? asked : 'title';
const game = new Phaser.Game({
  // Given the page's canvas, Phaser needs its renderer named: WebGL where the browser has it.
  type: hasWebGL() ? Phaser.WEBGL : Phaser.CANVAS,
  canvas: document.querySelector<HTMLCanvasElement>('#game')!,
  width: W,
  height: H,
  backgroundColor: '#000000',
  pixelArt: true, // pixel looks: no smoothing; set false otherwise
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  input: { keyboard: false },
  audio: { noAudio: true },
  banner: false,
  scene: [Game],
});

// window.game.step(): Phaser's own frame, with Phaser's time moved on by exactly one STEP.
let phaserTime = 0, lastFrame = clock.now(), stepping = false; // stepping: a frame window.game.step() asked for
const hook = {
  get scene() { return scene; },
  get state() { return state; },
  press(code: string) { hit.add(code); },
  hold(code: string, on: boolean) { if (on) down.add(code); else down.delete(code); },
  // Phaser draws on every frame it runs, so draw=false is not separate here.
  step(n = 1) {
    stepping = true;
    try { for (let i = 0; i < n; i++) { phaserTime += STEP * 1000; game.step(phaserTime, STEP * 1000); } }
    finally { stepping = false; }
  },
};

// A headless browser on a time budget runs timers but almost no animation frames, so a
// screenshot after its wait would show the first frame. A timer runs one of Phaser's frames
// when none has come for 100 ms on a visible page; a hidden tab stays paused.
if (!manual) setInterval(() => {
  const now = clock.now();
  if (game.isBooted && document.visibilityState === 'visible' && now - lastFrame > 0.1) {
    game.step(now * 1000, (now - lastFrame) * 1000);
  }
}, 50);
