# Cocos Creator Physics — Quick Reference

Last verified: 2026-06-27 | Engine: Cocos Creator 3.8.6

## What Changed Since v3.0

### v3.0 — Major physics system restructure
- **3D physics**: Bullet (default), Cannon.js (deprecated), PhysX (added v3.4)
- **2D physics**: Built-in (simple AABB), Box2D (full feature)
- Component-based: `RigidBody`, `BoxCollider`, `SphereCollider`, etc.

### v3.8 — New Character Controller
- **`CharacterController`** component — kinematic controller for player characters
- Replaces community patterns (raycast + manual move)
- Built on the underlying physics engine's character controller

### v3.8.6 — Box2D Variants
- **Box2D TS** — pure TypeScript (cross-platform, slowest on native iOS without JIT)
- **Box2D WASM** — Box2D-wasm (faster than TS, requires WASM support)
- **Box2D JSB (NEW)** — C++ native binding (best native perf, especially iOS)

## Current API Patterns

### 2D Physics (Box2D)
```typescript
import { _decorator, Component, RigidBody2D, BoxCollider2D, Contact2DType } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('Enemy2D')
export class Enemy2D extends Component {
    onLoad() {
        const body = this.getComponent(RigidBody2D)!;
        body.type = RigidBody2D.Type.Dynamic;

        const collider = this.getComponent(BoxCollider2D)!;
        collider.on(Contact2DType.BEGIN_CONTACT, this._onBeginContact, this);
        collider.on(Contact2DType.END_CONTACT, this._onEndContact, this);
    }

    private _onBeginContact(self: Collider2D, other: Collider2D) {
        if (other.node.name === 'Player') {
            // handle hit
        }
    }
}
```

### 3D Physics (Bullet / PhysX)
```typescript
import { RigidBody, BoxCollider, ICollisionEvent } from 'cc';

const body = this.getComponent(RigidBody)!;
body.type = RigidBody.BodyType.Dynamic;
body.mass = 1.0;
body.linearDamping = 0.1;

const collider = this.getComponent(BoxCollider)!;
collider.on('onCollisionEnter', (event: ICollisionEvent) => {
    console.log('hit', event.otherCollider.node.name);
});
```

### Character Controller (3D, v3.8+)
```typescript
import { CharacterController, Vec3 } from 'cc';

const controller = this.getComponent(CharacterController)!;

const moveDir = new Vec3(0, -1, 0);  // gravity
controller.move(moveDir);             // kinematic move with collision
```

> **Why prefer CharacterController over RigidBody for players?**
> - RigidBody applies forces → bouncy / floaty player control
> - CharacterController.move() is kinematic → exact position control
> - Built-in slope/stair handling via `stepOffset` / `slopeLimit`

### Trigger vs. Collision
- **Collider** with `isTrigger = false` → solid collision (physics response)
- **Collider** with `isTrigger = true` → trigger (no response, only events)
- Use triggers for pickups, area entries; use collisions for walls, floors

## Box2D Variant Selection (3.8.6+)

Choose in **Project Settings → Physics → 2D Physics**:

| Variant | Best For |
|---------|---------|
| **TS** (Box2D.js) | Pure cross-platform, simple games, no native builds |
| **WASM** (Box2D-wasm) | Better perf, requires WASM support |
| **JSB (C++)** | Native iOS / Android 2D physics — best iOS perf |

> **Note**: JSB is native-only. Web and mini-game builds fall back to TS automatically.

## Performance Notes
- **Sleeping bodies**: idle `RigidBody` (3D) and `RigidBody2D` enter sleep state automatically — no cost
- **Broadphase**: keep colliders simple (Box / Sphere); complex mesh colliders are expensive
- **Sub-step count**: lower `physics.world.defaultSolverIterations` (default: 4) for perf, raise for stability
- **Fixed timestep**: physics runs at fixed 60Hz by default; don't tie gameplay logic to physics step

## Common Mistakes
- Using `RigidBody` for player movement — use `CharacterController.move()` instead (3.8+)
- Forgetting to enable physics in project settings → colliders do nothing
- Mixing `RigidBody2D.Type` types — `Dynamic`, `Kinematic`, `Static` have different rules
- Subscribing to collision events in `update()` — causes leak
- Expecting 3D physics on mini-game without checking — WebGL 1 has no 3D physics on some platforms
- Not setting `body.linearDamping` — objects slide forever on flat ground
- Multiple `BoxCollider` on one node (3D) — use compound colliders via child nodes
- Forgetting `RigidBody.useGravity` for floating enemies — they fall

## 2D Raycasting

```typescript
import { PhysicsSystem2D, Vec2 } from 'cc';

// Single hit
const hit = PhysicsSystem2D.instance.raycast(
    new Vec2(0, 0),      // from
    new Vec2(100, 100),  // to
    PhysicsSystem2D.PhysicsGroup.DEFAULT,
);
if (hit) {
    console.log('hit collider', hit.collider.node.name, 'at', hit.point);
}

// All hits (sorted by distance)
const results: any[] = [];
const count = PhysicsSystem2D.instance.raycastAll(
    new Vec2(0, 0), new Vec2(100, 100),
    PhysicsSystem2D.PhysicsGroup.DEFAULT,
    results,
);
```

## Joints (2D & 3D)

For rope chains, ragdolls, swinging doors, vehicle suspensions:

```typescript
import { DistanceJoint2D, Joint2D } from 'cc';

const joint = this.node.addComponent(DistanceJoint2D)!;
joint.connectedBody = otherBody;     // target RigidBody
joint.distance = 2.0;
joint.frequency = 4.0;              // spring stiffness
joint.damping = 0.5;
```

Available 2D joints: `DistanceJoint2D`, `RevoluteJoint2D`, `PrismaticJoint2D`,
`WeldJoint2D`, `WheelJoint2D`, `RopeJoint2D`, `MotorJoint2D`.
Available 3D joints: `HingeConstraint`, `PointToPointConstraint`, `FixedConstraint`.

## Contact Filtering (2D)

For layer-mask based collision filtering (player bullets hit enemies but
not other players):

```typescript
// Define groups in `Project Settings → Physics → 2D Physics → Groups`
enum CollisionGroup {
    PLAYER     = 1 << 0,
    ENEMY      = 1 << 1,
    PLAYER_BULLET = 1 << 2,
    GROUND     = 1 << 3,
}

collider.group = CollisionGroup.PLAYER_BULLET;
collider.categoryBits = CollisionGroup.PLAYER_BULLET;  // what we ARE
collider.maskBits = CollisionGroup.ENEMY | CollisionGroup.GROUND;  // what we HIT
```

## 3D Physics: Bullet vs PhysX

| Aspect | **Bullet** | **PhysX** (3.4+) |
|--------|-----------|------------------|
| Default in 3.8.6 | ✓ | opt-in |
| Vehicle / character controllers | Better (built-in `btRaycastVehicle`) | Better (PhysX PxVehicle) |
| Continuous collision detection (CCD) | ✓ | ✓ (more accurate) |
| Native perf | C++ | C++ (often faster on mobile) |
| Editor tooling | Less polished | More polished |
| Recommended for | Generic 3D, simulation | Production mobile 3D, vehicle games |

Switch in `Project Settings → Physics → 3D Physics → Physics Engine`.
**Don't switch mid-project** — collider / joint assets are not
portable; re-author them after a switch.

## CharacterController (3.8+)

Use **`CharacterController`** for player avatars instead of `RigidBody`:
kinematic, exact position control, built-in slope / stair handling.
See the `CharacterController.move()` example earlier in this file.
