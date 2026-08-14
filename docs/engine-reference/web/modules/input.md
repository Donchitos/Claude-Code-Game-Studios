# Web — Input Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** Pointer Events supersede separate mouse/touch handling; gamepad has no event API

---

## Overview

| Input | API | Model |
|-------|-----|-------|
| Mouse / touch / pen | **Pointer Events** | Event-driven |
| Keyboard | `keydown` / `keyup` | Event-driven |
| Gamepad | `navigator.getGamepads()` | **Polled** |
| Touch gestures | Pointer Events + manual tracking | Event-driven |

---

## Pointer Events — One Path for Everything

Do not write separate `mousedown` and `touchstart` handlers. Pointer Events cover
mouse, touch, and pen in a single code path.

```ts
canvas.addEventListener('pointerdown', (e: PointerEvent) => {
  canvas.setPointerCapture(e.pointerId);   // keep receiving events outside the canvas
  input.press(e.pointerId, e.offsetX, e.offsetY);
});

canvas.addEventListener('pointermove', (e: PointerEvent) => {
  input.move(e.pointerId, e.offsetX, e.offsetY);
});

canvas.addEventListener('pointerup', (e: PointerEvent) => {
  canvas.releasePointerCapture(e.pointerId);
  input.release(e.pointerId);
});
```

`e.pointerType` is `'mouse' | 'touch' | 'pen'` when behavior must differ.
`setPointerCapture` is what makes drags work when the pointer leaves the canvas.

### Required CSS
```css
canvas {
  touch-action: manipulation;  /* kills the 300ms double-tap zoom delay */
  user-select: none;
}
```

---

## Keyboard

### Buffer state, read it in the fixed update
Events arrive at arbitrary times. The simulation runs at a fixed timestep. Buffer
into a state object and read it during `update()`.

```ts
const keys = new Set<string>();
addEventListener('keydown', (e) => { keys.add(e.code); });
addEventListener('keyup',   (e) => { keys.delete(e.code); });
```

Use `e.code` (physical key, layout-independent) for movement — `e.key` gives the
wrong result on AZERTY and Dvorak. Use `e.key` for text entry.

### Clear held state on focus loss
```ts
addEventListener('blur', () => keys.clear());
document.addEventListener('visibilitychange', () => {
  if (document.hidden) keys.clear();
});
```
Without this, the player alt-tabs away mid-move and returns to a character
running into a wall forever. This is one of the most common web game bugs.

### Scope `preventDefault`
Only prevent defaults for keys the game actually uses, and only when the canvas
has focus. Blanket `preventDefault` on the document breaks browser shortcuts,
scrolling, and accessibility tooling.

---

## Gamepad — Polled, Not Event-Driven

There is no gamepad event API for button state. Poll inside the game loop.

```ts
function pollGamepads(): void {
  const pads = navigator.getGamepads();
  for (const pad of pads) {
    if (!pad) continue;
    const x = applyDeadzone(pad.axes[0] ?? 0);
    const jump = pad.buttons[0]?.pressed ?? false;
    // ...
  }
}

function applyDeadzone(v: number, dz = 0.15): number {
  return Math.abs(v) < dz ? 0 : (v - Math.sign(v) * dz) / (1 - dz);
}
```

- `getGamepads()` returns a **snapshot** — call it every frame, do not cache the array
- A gamepad appears only after the user presses a button on it (a privacy measure). Listen for `gamepadconnected` to detect it
- Always apply a deadzone; raw sticks drift
- Rescale after the deadzone (as above) so the full 0–1 range remains reachable

---

## Input Abstraction

Map raw devices to game actions in one place. Rebinding, replays, and gamepad
support all depend on the game never reading a device directly.

```ts
type Action = 'moveLeft' | 'moveRight' | 'jump' | 'interact';

interface InputState {
  isDown(action: Action): boolean;
  justPressed(action: Action): boolean;   // edge-detected in the fixed update
  axis(action: Action): number;
}
```

Edge detection (`justPressed`) must be computed in the fixed update, not the
event handler — otherwise a press can be missed or double-counted depending on
frame timing.

---

## Mobile Specifics

- Minimum touch target 44×44 px; expand the hit area, not the visual
- `env(safe-area-inset-*)` for notches and home indicators
- Inputs need ≥16px font or iOS auto-zooms on focus
- On-screen controls must be repositionable — thumb reach varies
- Handle `orientationchange` and `resize` together, debounced

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| Movement key stuck after alt-tab | Not clearing state on `blur` |
| Drag breaks when leaving canvas | Missing `setPointerCapture` |
| 300ms tap delay on mobile | Missing `touch-action: manipulation` |
| Gamepad never detected | Not polling, or user hasn't pressed a button yet |
| Stick drifts when idle | No deadzone |
| WASD wrong on AZERTY | Using `e.key` instead of `e.code` |

---

## Sources

- https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events
- https://developer.mozilla.org/en-US/docs/Web/API/Gamepad_API
