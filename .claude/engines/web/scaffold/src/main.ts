// The page: screen, input, sound, scenes and the loop. The rules are in
// game/rules.ts; what the checks drive is in hook.ts. Plain Canvas 2D and Web
// Audio, no library.

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

// ---- Screen ---------------------------------------------------------------------------
const canvas = document.querySelector<HTMLCanvasElement>('#game')!;
const ctx = canvas.getContext('2d')!;
function fit(): void { // fills the window at any size and pixel ratio
  const k = Math.min(innerWidth / W, innerHeight / H);
  const s = PIXEL ? Math.max(1, Math.floor(k)) : k;
  const r = PIXEL ? 1 : s * (devicePixelRatio || 1);
  canvas.width = Math.round(W * r); canvas.height = Math.round(H * r);
  canvas.style.width = `${Math.round(W * s)}px`; canvas.style.height = `${Math.round(H * s)}px`;
  canvas.style.marginTop = `${Math.max(0, Math.floor((innerHeight - H * s) / 2))}px`;
  canvas.style.imageRendering = PIXEL ? 'pixelated' : 'auto';
  ctx.setTransform(r, 0, 0, r, 0, 0); ctx.imageSmoothingEnabled = !PIXEL;
  if (scene) scenes[scene].draw(); // a page that draws only on change must draw again here
}
function clear(c: string): void { ctx.fillStyle = c; ctx.fillRect(0, 0, W, H); }
function text(s: string, x: number, y: number, size: number, c: string, align: CanvasTextAlign = 'center'): void {
  ctx.fillStyle = c; ctx.font = `${size}px ${FONT}`; ctx.textAlign = align;
  ctx.textBaseline = 'middle'; ctx.fillText(s, x, y);
}

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
type Scene = { update(dt: number): void; draw(): void };
let scene = '', state: State = newState(), rng = makeRng(seedFrom(config.seed));
function reset(): void {
  rng = makeRng(seedFrom(config.seed)); // every gameplay random call reads rng(), never Math.random
  state = newState();
}
const scenes: Record<string, Scene> = {
  title: {
    update() { if (pressed('Enter') || pressed('Space')) { reset(); tone(440, 0.1); scene = 'play'; } },
    draw() {
      clear('#111'); text(TITLE, W / 2, H / 3, 16, '#fff');
      CONTROLS.forEach((c, i) => text(c, W / 2, H / 2 + i * 11, 8, '#ccc'));
      text('Enter to start', W / 2, H - 16, 8, '#fff');
    },
  },
  play: {
    update(dt) {
      if (pressed('KeyP') || pressed('Escape')) { scene = 'pause'; return; }
      const dx = (down.has('ArrowRight') ? 1 : 0) - (down.has('ArrowLeft') ? 1 : 0);
      const dy = (down.has('ArrowDown') ? 1 : 0) - (down.has('ArrowUp') ? 1 : 0);
      update(state, { dx, dy }, tuning, dt);
    },
    draw() {
      clear('#000');
      ctx.fillStyle = '#4cf'; ctx.fillRect(Math.round(state.x), Math.round(state.y), FIELD.size, FIELD.size);
      text(`${state.score}`, 8, 8, 8, '#fff', 'left');
    },
  },
  pause: {
    update() { if (pressed('KeyP') || pressed('Escape')) scene = 'play'; },
    draw() { scenes.play.draw(); text('Paused', W / 2, H / 2, 12, '#fff'); },
  },
};

// ---- Loop: fixed step, frame time clamped ---------------------------------------------
function step(): void {
  if (pressed('KeyM')) setMuted(!muted);
  scenes[scene].update(STEP);
  hit.clear();
}
let last = clock.now(), acc = 0;
function tick(): void {
  const now = clock.now();
  acc += Math.min(now - last, 0.25); last = now; // a stall never fast-forwards the game
  while (acc >= STEP) { step(); acc -= STEP; }
  scenes[scene].draw();
}
function frame(): void { tick(); requestAnimationFrame(frame); }
// A headless browser on a time budget runs timers but almost no animation frames, so a
// screenshot after its wait would show the first frame. A timer ticks when no frame has come
// for 100 ms on a visible page; a hidden tab stays paused.
function timer(): void { if (document.visibilityState === 'visible' && clock.now() - last > 0.1) tick(); }

install({
  get scene() { return scene; },
  get state() { return state; },
  press(code) { hit.add(code); },
  hold(code, on) { if (on) down.add(code); else down.delete(code); },
  step(n = 1, draw = true) { for (let i = 0; i < n; i++) step(); if (draw) scenes[scene].draw(); },
});

reset();
const asked = params.get('scene');
scene = asked && asked in scenes ? asked : 'title';
addEventListener('resize', fit); fit();
last = clock.now();
if (manual) scenes[scene].draw();
else { requestAnimationFrame(frame); setInterval(timer, 50); }
