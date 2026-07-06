# Example Session: Bullet Object Pool (Cocos Creator 3.8.6)

**Context:** Solo indie dev, week 6 of project, ship a top-down 2D
shooter built in Cocos Creator 3.8.6. The player fires 10 bullets
per second; a naive `instantiate` per shot is causing visible frame
hitches and GC pressure on mid-tier Android.

**Starting State:**
- `design/gdd/combat-system.md` exists and reviewed
- Cocos Creator 3.8.6 project set up, `assets/scenes/Game.scene` exists
- Player controller already implemented
- Sprint goal: "Implement bullet firing that holds 60 FPS on Android"

**Session Duration:** ~35 minutes
**Turns:** 9
**Outcome:** Bullet pool integrated, no per-shot `instantiate`,
60 FPS confirmed on target hardware.

---

## Turn 1: User Requests Implementation

**User:**
> Implement the bullet firing system. Player fires by holding space.
> I see frame drops in the profiler — looks like GC pauses from
> instantiating bullets per shot. Please add a pool.

## Turn 2: Agent Reads Design and Asks Clarifying Questions

**Agent (cocos-ts-specialist):**
> I've read `design/gdd/combat-system.md` and the player controller at
> `assets/scripts/player/PlayerController.ts`. The spec for firing is
> brief — I need to clarify some details:
>
> **Architecture Questions:**
> 1. Where should the pool live? Options: a `BulletPool` singleton
>    `Node` in the scene, a static utility class, or a `NodePool` from
>    `cc.NodePool`? I recommend `cc.NodePool` — it's the engine's
>    built-in pool and supports `get()` / `put()` with prefab management.
> 2. Should bullets despawn on hit, off-screen, or after a fixed
>    lifetime (e.g., 3 seconds)? The design doc doesn't say.
> 3. Multiple bullet types later? If yes, the pool needs to be a
>    `Map<BulletType, NodePool>` from the start. If no, a single pool
>    is fine.
>
> **Spec Ambiguities:**
> 4. Firing rate — the design says "auto-fire" but doesn't specify
>    the rate. 10/s? 5/s? Configurable via `PlayerController.fireRate`?
> 5. Bullet speed — single value or per-bullet? For now I'll assume
>    single value on a `BulletConfig` constant.
> 6. Hit detection — circle collider on the bullet + collision callback,
>    or screen-space distance check? I recommend collider for accuracy.
>
> **Cocos-Specific:**
> 7. The game targets Android and iOS. Should the pool size be capped
>    (e.g., 50) or unbounded? I recommend capped — Android can OOM
>    from sprite texture allocations.
> 8. Where should the bullet prefab be loaded? `@property` reference
>    on the `PlayerController`, or `resources.load()` at boot? The
>    `@property` approach is editor-friendly and faster.
>
> Please confirm so I can implement this correctly the first time.

## Turn 3: User Resolves Ambiguities

**User:**
> 1. Use `cc.NodePool`
> 2. Despawn on off-screen — listen for `OUT_OF_VIEWPORT` event
> 3. Single bullet type for now; design for extension later (use a
>    single pool today, but write it so adding a second is easy)
> 4. 10/s, configurable via `@property` with default 10
> 5. Single value, `BulletConfig.SPEED = 800` px/s
> 6. Use a `CircleCollider2D` + `RigidBody2D` (Kinematic) on the bullet
> 7. Capped at 50
> 8. `@property` reference on the `PlayerController`

## Turn 4: Agent Proposes Architecture

**Agent (cocos-ts-specialist):**
> Here's my proposed architecture. **Before I write any code, let me
> confirm this matches your intent.**
>
> **Files to add:**
> - `assets/scripts/bullets/Bullet.ts` — bullet component (velocity,
>   lifetime, collision response)
> - `assets/scripts/bullets/BulletConfig.ts` — constants (SPEED, MAX_POOL_SIZE)
>
> **Files to modify:**
> - `assets/scripts/player/PlayerController.ts` — add firing logic +
>   pool initialization
>
> **Data flow:**
> 1. `PlayerController.onLoad()` — pre-instantiate 10 bullets into the
>    pool (warm pool). Register the `OUT_OF_VIEWPORT` callback.
> 2. Space pressed (or held with auto-fire) → `pool.get()` → position
>    the bullet at the player's muzzle, set velocity, `node.active = true`.
> 3. Bullet's `update(dt)` moves by `velocity * dt`. Its
>    `CircleCollider2D` fires `BEGIN_CONTACT` on the enemy layer.
> 4. On contact, or on `OUT_OF_VIEWPORT`, call `pool.put(bullet)` and
>    reset its state.
> 5. If `pool.size() < MAX_POOL_SIZE` when firing, instantiate a new
>    bullet (pool grows on demand up to the cap).
>
> **Trade-offs:**
> - Pre-instantiating 10 vs. lazy: lazy is more memory-efficient at
>    boot but causes 1-frame hitches on the first 10 shots. I'll
>    pre-instantiate to avoid the hitch.
> - `cc.NodePool` vs hand-rolled: `cc.NodePool` is the right choice —
>    it handles `active` toggling and prefab cloning.
> - Putting `BulletConfig` in a separate file vs as static on
>    `PlayerController`: separate file is cleaner and reusable.
>
> **One concern:** I'm not sure if your enemy layer mask is set up
> in `Project Settings → Physics → 2D Physics → Groups`. I checked
> `ProjectSettings/assets/physics-groups.json` and don't see an
> `ENEMY` group. I'll need you to add it before I can wire the
> collision callback correctly.
>
> **May I write these files?** I will not touch `PlayerController`
> until you confirm the architecture.

## Turn 5: User Confirms + Adds Missing Config

**User:**
> Approved. Add the `ENEMY` group to `ProjectSettings/assets/physics-groups.json`.
> Bullet `maskBits` = `ENEMY | WALL`, `categoryBits` = `PLAYER_BULLET`.

## Turn 6: Agent Implements

**Agent (cocos-ts-specialist):**
> Writing the files now. Per the spec, I'm not using `resources.load()`
> since you confirmed the `@property` reference. The pool is on
> `PlayerController` as a `private _pool: NodePool`.
>
> [Code written — see `assets/scripts/bullets/Bullet.ts` and the
> updated `PlayerController.ts`.]

## Turn 7: Agent Self-Reviews

**Agent (cocos-ts-specialist):**
> Before asking you to test, I ran a self-review:
>
> 1. ✓ `@ccclass` decorators on both classes
> 2. ✓ `getComponent()` cached in `onLoad`, not in `update`
> 3. ✓ Pool caps at `MAX_POOL_SIZE` (50) — no unbounded growth
> 4. ✓ Pre-instantiate 10 bullets at `onLoad` — no first-shot hitch
> 5. ✓ `OUT_OF_VIEWPORT` listener paired with `off()` in `onDestroy`
> 6. ✓ `pool.put()` resets `position` and `velocity` — no stale state
> 7. ✓ Used `BEFORE_PHYSICS` schedule for the contact callback — fires
>    before the next physics step, avoiding duplicate hits
> 8. ✗ I forgot to `releaseAsset()` on `onDestroy` for the prefab
>    reference. Adding it now.
>
> One more question: I noticed `PlayerController._pool.size()` could
> grow up to 50, but we only pre-instantiate 10. Is 10 the right warm
> pool size, or should it match `MAX_POOL_SIZE`?

## Turn 8: User Adjusts + Asks for Verification

**User:**
> 10 is fine, the rest grow on demand. Run a quick test — is the
> 60 FPS target met?

## Turn 9: Agent Verifies and Closes

**Agent (cocos-ts-specialist):**
> Built for Android (`platform=android;debug=true`). Loaded
> `Game.scene` with a stress test spawning 100 enemies and
> auto-firing at 10/s. Profile results (Cocos Profiler):
>
> - Frame time: 16.4ms avg (60.9 FPS) ✓
> - GC pauses: 0 over 60s (was 12/s with naive instantiate) ✓
> - Pool steady-state size: 32 / 50 (some despawned, some in flight)
> - Pool growth: 10 → 32 in the first 3s, then stable
>
> The implementation meets the spec. Ready for `/code-review` if you
> want a second pass, or move on to the next sprint story.
>
> **Files added:**
> - [`assets/scripts/bullets/Bullet.ts`](file:///workspace/assets/scripts/bullets/Bullet.ts)
> - [`assets/scripts/bullets/BulletConfig.ts`](file:///workspace/assets/scripts/bullets/BulletConfig.ts)
>
> **Files modified:**
> - [`assets/scripts/player/PlayerController.ts`](file:///workspace/assets/scripts/player/PlayerController.ts) (added pool, firing logic)
> - `ProjectSettings/assets/physics-groups.json` (added `ENEMY` group per your instruction)
>
> This is a working example for the bullet-pool story. The
> cocos-shader-specialist is not needed (no shaders), the
> cocos-ui-specialist is not needed (no UI changes).

---

## What This Example Demonstrates

- **Cocos 3.x patterns** — `@ccclass` / `@property`, `cc.NodePool`,
  `EventTarget` lifecycle pairing, `OUT_OF_VIEWPORT` event
- **Spec-ambiguity handling** — 8 questions before writing code; 7 of
  them answered, 1 not in the design doc (`OUT_OF_VIEWPORT` despawn)
- **Architecture-first workflow** — file list, data flow, trade-offs
  before any code
- **Self-review before completion** — caught the missing
  `releaseAsset()` on prefab
- **Cocos-specific gotchas** — pre-warming the pool to avoid first-shot
  hitch; `BEFORE_PHYSICS` schedule for contact callbacks
- **Engine version awareness** — `OUT_OF_VIEWPORT` was added in 3.4
  and the agent correctly used it instead of polling
  `node.position` against the camera bounds
