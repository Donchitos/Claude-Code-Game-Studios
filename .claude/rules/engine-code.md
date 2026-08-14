---
paths:
  - "src/core/**"
---

# Engine Code Rules

- ZERO allocations in hot paths (update loops, rendering, physics) — pre-allocate, pool, reuse
- All engine APIs must be thread-safe OR explicitly documented as single-thread-only
- Profile before AND after every optimization — document the measured numbers
- Engine code must NEVER depend on gameplay code (strict dependency direction: engine <- gameplay)
- Every public API must have usage examples in its doc comment
- Changes to public interfaces require a deprecation period and migration guide
- Use RAII / deterministic cleanup for all resources
- All engine systems must support graceful degradation
- Before writing engine API code, consult `docs/engine-reference/` for the current engine version and verify APIs against the reference docs

## Web projects (PixiJS / Three.js)

On the web, "zero allocations in hot paths" means **avoiding GC pressure**, which
is the platform's dominant source of frame stutter — a garbage collection pause
is visible where an extra draw call is not.

- No object/array literals, `.map()`/`.filter()`/spread, per-frame closures, or
  template literals inside the update or render loop — all of them allocate
- Pool vectors, matrices, particles, and projectiles; reuse scratch objects
- **GPU resources are never freed automatically.** Three.js needs explicit
  `.dispose()` on geometries, materials, and textures; PixiJS needs `.destroy()`.
  Removing an object from the scene graph does not free its memory
- Simulation must be renderer-independent and headlessly testable — isolate
  rendering behind an interface so `update()` runs under Vitest with no canvas
- Use a fixed timestep with an accumulator; clamp the delta to survive tab refocus
- Consult `docs/engine-reference/web/` — the knowledge gap there is
  **permanently HIGH** because Three.js ships monthly and removes deprecated code
  in most releases

## Examples

**Correct** (zero-alloc hot path):

```gdscript
# Pre-allocated array reused each frame
var _nearby_cache: Array[Node3D] = []

func _physics_process(delta: float) -> void:
    _nearby_cache.clear()  # Reuse, don't reallocate
    _spatial_grid.query_radius(position, radius, _nearby_cache)
```

**Incorrect** (allocating in hot path):

```gdscript
func _physics_process(delta: float) -> void:
    var nearby: Array[Node3D] = []  # VIOLATION: allocates every frame
    nearby = get_tree().get_nodes_in_group("enemies")  # VIOLATION: tree query every frame
```
