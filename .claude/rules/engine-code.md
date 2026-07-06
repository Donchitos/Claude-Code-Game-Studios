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

**Correct** (Cocos Creator 3.8.6 TypeScript, zero-alloc update loop):

```typescript
import { _decorator, Component, Node, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

// Module-scope scratch value — reused every frame, not reallocated
const _scratch: Vec3 = new Vec3();

@ccclass('EnemyProximity')
export class EnemyProximity extends Component {
    @property(Node) private spatialGrid: Node | null = null;

    update(deltaTime: number) {
        if (!this.spatialGrid) return;
        // Reuse the same Vec3; pass-by-reference, no GC pressure
        this.spatialGrid.getComponent('SpatialGrid')!.queryRadius(this.node.position, 50, _scratch);
    }
}
```

**Incorrect** (Cocos Creator 3.x anti-pattern):

```typescript
update(deltaTime: number) {
    // VIOLATION: `new Vec3()` every frame → GC pressure spikes
    const center = new Vec3();
    this.spatialGrid.queryRadius(this.node.position, 50, center);

    // VIOLATION: Object literal allocated every frame
    const result = this.aStar.findPath({ from: this.node.position, to: target }); // signature accepts a config object — but pass it as a pre-allocated field instead
}
```

Cocos-specific notes:
- The engine is shipped as a JavaScript bundle — every `new`, every `{}` literal, every array spread in a hot path produces GC-eligible garbage. Use class fields for scratch `Vec3` / `Quat` / `Color` / arrays.
- For event systems, prefer `EventTarget`-style subscriptions via `Node.on('event-name', handler)` paired with `Node.off(...)` in `onDestroy` — do not allocate a new `CustomEvent` per dispatch.
- For component property binding, declare `@property(type)` decorators at class scope; do not dynamically attach component references inside `update()`.
