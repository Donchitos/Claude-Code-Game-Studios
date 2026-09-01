# Cocos Creator — Box2D Plugin Reference

Last verified: 2026-07-06 | Engine: Cocos Creator 3.8.6

## Why This File Exists

In Cocos Creator 3.8.6, the 2D physics engine Box2D ships in **three
runtime variants**. The choice is per-project, not per-platform. This
file documents the trade-offs and the correct way to switch.

For general 2D physics API patterns (RigidBody2D, BoxCollider2D, contact
callbacks), see `../modules/physics.md`. For 3D physics (Bullet / PhysX),
also see `../modules/physics.md` — Box2D is 2D-only.

## Variants

| Variant | Tech | Best For | Native Perf | Web / Mini-game |
|---------|------|----------|-------------|------------------|
| **Box2D TS** | Pure TypeScript (Box2D.js) | Cross-platform consistency, simple games, no native build | Slowest on iOS (no JIT) | ✓ |
| **Box2D WASM** | Box2D compiled to WebAssembly | Cross-platform with better perf, requires WASM runtime | Faster than TS | ✓ |
| **Box2D JSB** (3.8.6+) | C++ native binding | Native iOS / Android 2D physics games | Best iOS perf (no JIT penalty) | ✗ — falls back to TS |

## Selection

`Project Settings → Physics → 2D Physics → Implementation`

- **JSB** only works for **native builds** (iOS / Android / macOS / Windows).
  Web and mini-game platforms silently fall back to TS.
- **WASM** requires the platform to support WebAssembly. All modern web
  browsers and most mini-game runtimes (WeChat, ByteDance) do.

## Decision Matrix

| Target | Recommended | Reason |
|--------|-------------|--------|
| iOS / Android native, performance-critical 2D | **JSB** | iOS has no JS JIT; JSB avoids the TS penalty |
| Web only | **WASM** | Fastest in browsers; TS only if you need smallest binary |
| WeChat / ByteDance mini-game | **TS** | WASM is supported but bundle size grows; TS is safer for size budget |
| Cross-platform (web + native) | **WASM** | Consistent perf; JSB won't activate on web anyway |
| Project still in early prototype | **TS** | Fastest to iterate; switch to JSB/WASM for release builds |

## Switching Variants Mid-Project

1. Switch the variant in `Project Settings → Physics`
2. Re-import the project (engine recompiles the Box2D binding)
3. Re-test all physics scenes — particularly:
   - Continuous collision detection (Box2D JSB may report slightly
     different contact manifolds than TS)
   - Joint constraints (revolute, prismatic, weld)
   - Sensor/trigger volumes
4. Check the new bundle size — JSB is native so it has no JS cost; WASM
   adds ~80–150KB depending on build

## API Surface (Stable Across Variants)

```typescript
import { RigidBody2D, BoxCollider2D, Contact2DType } from 'cc';

const body = this.getComponent(RigidBody2D)!;
body.type = RigidBody2D.Type.Dynamic;

const collider = this.getComponent(BoxCollider2D)!;
collider.on(Contact2DType.BEGIN_CONTACT, this._onBegin, this);
```

`PhysicsSystem2D.instance` provides:

| API | Purpose |
|-----|---------|
| `raycast(point1, point2, typeMask, results)` | Single ray |
| `raycastAll(point1, point2, typeMask, results)` | All hits |
| `getColliderByUUID(uuid)` | Lookup by serialized UUID |
| `enableAccumulate(true)` | Sub-stepping (slower but more accurate) |

## Common Mistakes
- Assuming JSB works on web — falls back silently to TS; you won't
  see an error, just degraded perf
- Mixing `RigidBody2D` from one variant with colliders imported from
  another — variants are interchangeable at the API level, but asset
  import metadata may differ after a switch
- Enabling `enableAccumulate(true)` for production — costs 2–4× CPU
- Using `PolygonCollider2D` with > 8 vertices — Box2D itself is limited;
  decompose into convex pieces first
- Forgetting to dispose `RigidBody2D` on `onDestroy()` — JSB holds a
  native handle that needs explicit release on native builds
