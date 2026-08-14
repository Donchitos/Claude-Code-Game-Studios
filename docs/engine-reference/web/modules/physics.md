# Web — Physics Module Reference

**Last verified:** 2026-08-06
**Knowledge Gap:** neither PixiJS nor Three.js ships a physics engine — this is always a dependency decision

---

## Overview

**Neither library includes physics.** Unlike Godot, Unity, and Unreal, there is
no built-in rigid-body system, no character controller, and no collision layers.
Physics is a deliberate dependency choice with a real payload cost.

| Need | Recommendation |
|------|----------------|
| Arcade collision (AABB, circle) | **Write it yourself** — a few hundred lines, zero payload |
| Real 2D rigid bodies | Rapier 2D |
| Real 3D rigid bodies | Rapier 3D |
| Light 3D, payload-sensitive | Cannon-es |
| Approachable 2D | Matter.js |

Most 2D games — platformers, top-down, puzzle, shmups — need **no physics engine
at all**. AABB overlap plus swept collision handles them, runs faster, is fully
deterministic, and adds nothing to the bundle. Reach for an engine only when you
genuinely need stacking, joints, or continuous dynamics.

---

## Rapier (Rust/WASM)

The default recommendation when real physics is needed.

- **Deterministic** across platforms — critical for replays, netcode, and reproducible tests
- Substantially faster than JS-native engines
- WASM binary is a meaningful payload cost — **load it async**, never in the boot bundle

```ts
import RAPIER from '@dimforge/rapier2d';

await RAPIER.init();                       // async WASM load
const world = new RAPIER.World({ x: 0, y: -9.81 });

const body = world.createRigidBody(
  RAPIER.RigidBodyDesc.dynamic().setTranslation(0, 10)
);
world.createCollider(RAPIER.ColliderDesc.cuboid(0.5, 0.5), body);
```

### Step it from the fixed update
```ts
function update(dt: number): void {
  world.timestep = dt;      // match the fixed timestep exactly
  world.step();
  syncTransformsToRenderer();
}
```

Physics must step at the fixed rate, not the render rate. Stepping in `render()`
makes simulation frame-rate dependent and destroys determinism.

---

## Physics-to-Renderer Sync

Physics owns position; the renderer displays it. Never let the two write to each
other.

```ts
// One direction only: physics → renderer
const t = body.translation();
sprite.position.set(t.x * PIXELS_PER_METER, -t.y * PIXELS_PER_METER);
```

**Unit scale matters.** Physics engines are tuned for meters. Feeding pixel-scale
values (a 32-unit-wide box) makes the solver behave as if simulating a 32-metre
crate — everything moves in slow motion and jitters. Pick a `PIXELS_PER_METER`
constant (32 or 100 are common) and convert at the boundary.

Note the Y-axis flip: screen Y grows downward, physics Y grows upward.

### Interpolation
With a fixed timestep, render between physics states or motion looks stuttery at
refresh rates that don't divide evenly into the step rate:

```ts
const x = prev.x + (curr.x - prev.x) * alpha;   // alpha = accumulator / STEP
```

---

## Writing Your Own (2D Arcade)

For most 2D games this is the right answer.

```ts
function aabbOverlap(a: Rect, b: Rect): boolean {
  return a.x < b.x + b.w && a.x + a.w > b.x &&
         a.y < b.y + b.h && a.y + a.h > b.y;
}
```

- **Sweep fast movers.** A projectile moving 40px/frame will tunnel straight through a 16px wall if you only test the destination position. Test the swept path
- **Resolve axes separately** (X then Y) for platformer feel — it makes wall-sliding and ledge behavior predictable
- **Broad-phase before narrow-phase** once entity counts pass ~100: spatial hash or uniform grid, then precise tests only on candidates

---

## Performance

- Physics is CPU-bound and runs on the main thread, competing with the game loop
- Sleep bodies at rest — most engines do this automatically; verify it is enabled
- Cap the number of solver iterations; more is rarely visibly better
- A Web Worker can host physics, but the transform sync cost across the boundary often cancels the gain. Measure before committing to it

---

## Common Errors

| Symptom | Cause |
|---------|-------|
| Everything moves in slow motion | Pixel units fed to a metre-scale solver |
| Fast objects pass through walls | No swept collision / CCD |
| Physics speed varies with framerate | Stepping in `render()` instead of fixed `update()` |
| Jittery motion at 144Hz | No interpolation between physics states |
| Objects sink into the floor | Sync writing back into the body each frame |
| Long initial load | WASM physics in the boot bundle |

---

## Sources

- https://rapier.rs/docs/
- https://github.com/pmndrs/cannon-es
- https://brm.io/matter-js/
