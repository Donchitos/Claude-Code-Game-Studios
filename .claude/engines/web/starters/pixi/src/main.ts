// The page: screen, input, sound, scenes and the loop, drawn with PixiJS. The rules are in
// game/rules.ts; what the checks drive is in hook.ts. PixiJS runs its own loop and time (its
// ticker); with ?manual=1 the ticker stays stopped, and window.game.step() moves it one step
// at a time.

import { Application, Container, Graphics, Text } from 'pixi.js';
import config from '../data/config.json';
import { FIELD, STEP, makeRng, newState, update, type State, type Tuning } from './game/rules';
import { audioContext, clock, install, manual, params, seedFrom } from './hook';

// ---- Values: data/config.json holds every tuning value ----------------------------------
const tuning: Tuning = { speed: config.speed.value };
const W = FIELD.w, H = FIELD.h;
const PIXEL = true; // pixel looks: whole-number scale, no smoothing; set false otherwise
const FONT = 'sans-serif';
const TITLE = document.title;
const CONTROLS = ['Arrows: move', 'P: pause', 'M: mute'];

// ---- Input: keys by position (event.code), OS key repeat ignored ------------------------
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

// ---- Scenes ---------------------------------------------------------------------------
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

async function start(): Promise<void> {
  // ---- Screen: PixiJS draws at the field's size; the page scales the canvas ------------------
  const canvas = document.querySelector<HTMLCanvasElement>('#game')!;
  const app = new Application();
  await app.init({ canvas, width: W, height: H, background: '#000000', resolution: 1, antialias: !PIXEL, autoStart: false });
  const label = (x: number, y: number, s: string, size: number, c = '#ffffff'): Text => {
    const t = new Text({ text: s, style: { fontFamily: FONT, fontSize: size, fill: c } });
    t.anchor.set(0.5); t.position.set(x, y); return t;
  };
  const square = new Graphics().rect(0, 0, FIELD.size, FIELD.size).fill('#44ccff');
  const score = new Text({ text: '', style: { fontFamily: FONT, fontSize: 8, fill: '#ffffff' } });
  score.position.set(8, 4);
  const menu = new Container();
  menu.addChild(label(W / 2, H / 3, TITLE, 16), ...CONTROLS.map((c, i) => label(W / 2, H / 2 + i * 11, c, 8, '#cccccc')),
    label(W / 2, H - 16, 'Enter to start', 8));
  const paused = label(W / 2, H / 2, 'Paused', 12);
  app.stage.addChild(square, score, menu, paused);
  function draw(): void {
    square.position.set(Math.round(state.x), Math.round(state.y)); square.visible = scene !== 'title';
    score.text = `${state.score}`; score.visible = scene !== 'title';
    menu.visible = scene === 'title'; paused.visible = scene === 'pause';
  }
  function fit(): void { // fills the window at any size and pixel ratio
    const k = Math.min(innerWidth / W, innerHeight / H);
    const s = PIXEL ? Math.max(1, Math.floor(k)) : k;
    canvas.style.width = `${Math.round(W * s)}px`; canvas.style.height = `${Math.round(H * s)}px`;
    canvas.style.marginTop = `${Math.max(0, Math.floor((innerHeight - H * s) / 2))}px`;
    canvas.style.imageRendering = PIXEL ? 'pixelated' : 'auto';
  }

  // ---- Loop: PixiJS's ticker, fixed step, frame time clamped --------------------------------
  // The ticker runs the game, then PixiJS draws the stage (it adds that to the same ticker).
  let acc = 0, lastFrame = clock.now(), stepping = false; // stepping: a frame window.game.step() asked for
  app.ticker.add(t => {
    lastFrame = clock.now();
    if (manual) { if (stepping) step(); } // each window.game.step() is one ticker frame of exactly STEP
    else {
      acc += Math.min(t.deltaMS / 1000, 0.25); // a stall never fast-forwards the game
      while (acc >= STEP) { step(); acc -= STEP; }
    }
    draw();
  });
  let tickerTime = 0;
  install({
    get scene() { return scene; },
    get state() { return state; },
    press(code) { hit.add(code); },
    hold(code, on) { if (on) down.add(code); else down.delete(code); },
    // The ticker's own frame, with its time moved on by exactly one STEP; PixiJS draws on
    // every frame it runs, so draw=false is not separate here.
    step(n = 1) {
      stepping = true;
      try { for (let i = 0; i < n; i++) { tickerTime += STEP * 1000; app.ticker.update(tickerTime); } }
      finally { stepping = false; }
    },
  });

  addEventListener('resize', fit); fit();
  draw(); app.render();
  if (manual) return; // ?manual=1: the ticker stays stopped; only window.game.step() moves the game
  app.ticker.start();
  // A headless browser on a time budget runs timers but almost no animation frames, so a
  // screenshot after its wait would show the first frame. A timer runs one ticker frame when
  // none has come for 100 ms on a visible page; a hidden tab stays paused.
  setInterval(() => {
    if (document.visibilityState === 'visible' && clock.now() - lastFrame > 0.1) app.ticker.update();
  }, 50);
}

reset();
const asked = params.get('scene');
scene = asked && asked in scenes ? asked : 'title';
void start();
