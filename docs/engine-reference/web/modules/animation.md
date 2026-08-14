# Web — Animation Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** none major — the recurring hazard is animation driven by render delta instead of the fixed timestep

---

## Overview

| Animation type | PixiJS | Three.js |
|----------------|--------|----------|
| Sprite / frame | `AnimatedSprite` | — |
| Skeletal | Spine / DragonBones runtime | `AnimationMixer` (GLTF clips) |
| Tweens | Manual or a tween library | Manual or a tween library |
| Morph targets | — | Morph target influences |
| Procedural | Custom, in the update loop | Custom, in the update loop |

Neither library ships a tween system. This is a small dependency decision or
~100 lines of your own code.

---

## The Timestep Rule

Animation state advances in the **fixed update**, not the render pass. Driving it
off render delta makes animation speed frame-rate dependent, so a 144Hz monitor
plays different animations than a 60Hz one.

```ts
// ✅ In fixed update
function update(dt: number): void {
  mixer.update(dt);           // Three.js
  animState.advance(dt);      // your own sprite animation
}
```

The exception is purely cosmetic interpolation with no gameplay meaning, which
can be done at render time using the interpolation alpha.

---

## PixiJS — Sprite Animation

```ts
import { AnimatedSprite, Assets } from 'pixi.js';

const sheet = await Assets.load('hero.json');   // atlas + frame data
const run = new AnimatedSprite(sheet.animations.run);
run.animationSpeed = 0.2;
run.play();
```

- Pack all animation frames into **one atlas** — frames spread across textures break batching
- For gameplay-relevant timing (attack active frames, i-frames), drive the frame index from your own state machine rather than `animationSpeed`, so timing is deterministic and testable
- `AnimatedSprite` uses the shared ticker; if the game is paused, stop it explicitly

---

## Three.js — Skeletal Animation

```ts
import { AnimationMixer } from 'three';

const gltf = await loader.loadAsync('character.glb');
const mixer = new AnimationMixer(gltf.scene);
const clip = gltf.animations.find((c) => c.name === 'Run');
const action = mixer.clipAction(clip!);
action.play();

// in fixed update
mixer.update(dt);
```

### Blending between clips
```ts
current.crossFadeTo(next, 0.25, false);
next.play();
```
Crossfade duration is a feel parameter — expose it as a tuning knob rather than
hardcoding it.

### Cost
- Skinned meshes are more expensive than static ones; skinning cost scales with bone count and vertex count
- Share one `AnimationMixer` per character, not per clip
- `mixer.stopAllAction()` and dispose on scene teardown, or animation state leaks

---

## Tweens

A minimal tween is often better than a dependency:

```ts
interface Tween {
  elapsed: number; duration: number;
  from: number; to: number;
  ease: (t: number) => number;
  apply: (v: number) => void;
}

function stepTween(tw: Tween, dt: number): boolean {
  tw.elapsed += dt;
  const t = Math.min(tw.elapsed / tw.duration, 1);
  tw.apply(tw.from + (tw.to - tw.from) * tw.ease(t));
  return t >= 1;   // done
}
```

Common easings — `easeOutCubic` for UI entrances, `easeInOutQuad` for camera
moves, `easeOutBack` for satisfying pops.

**Allocation warning:** creating tween objects per frame is a GC source. Pool
them, or use a fixed-size array of tween slots.

---

## CSS Animation for DOM UI

For DOM UI, prefer CSS over JS animation:

```css
.panel { transition: transform 200ms ease, opacity 200ms ease; }
@media (prefers-reduced-motion: reduce) {
  .panel { transition-duration: 1ms; }
}
```

- Only animate `transform` and `opacity` — everything else forces reflow
- Never `transition: all`
- Always provide a `prefers-reduced-motion` variant

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| Animations run faster on a high-refresh monitor | Driven by render delta, not fixed timestep |
| Animation continues while paused | `AnimatedSprite`/mixer not stopped on pause |
| Sprite animation breaks batching | Frames spread across multiple textures |
| Memory grows across character spawns | `AnimationMixer` not disposed |
| GC spikes during heavy tweening | Tween objects allocated per frame |
| Motion sickness complaints | No `prefers-reduced-motion` handling |

---

## Sources

- https://threejs.org/docs/#manual/en/introduction/Animation-system
- https://pixijs.com/
- https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion
