# Godot Physics — Quick Reference

Last verified: 2026-08-14 | Engine: Godot 4.7.1

## What Changed Since ~4.3 (LLM Cutoff)

### 4.7 Changes
- **`CollisionShape2D` 新增 `one_way_collision_direction` 属性**：单向碰撞方向可自定义（不再假定局部向上）。用于平台/单向碰撞。
- **`PhysicsServer2D.body_set_shape_as_one_way_collision()` 新增 `direction` 可选参数**：兼容（GH-104736）。
- **`PhysicsServer2DExtension._body_set_shape_as_one_way_collision()` 新增 `direction`（必填）**：GDScript/源码级破坏（GH-104736）——仅影响自定义 2D 物理扩展。
- **Jolt Physics 3D 变更**（本项目 2D 不受影响，仅记录）：
  - `WorldBoundaryShape3D.plane.d` 符号反转，需手动翻转符号
  - `SoftBody3D` 质量默认值不再为 `0`，默认 1 kg 整体
  - `SoftBody3D.linear_stiffness` 应用方式改变，需重新调参
  - `Area3D` 现在会报告与 `SoftBody3D` 的重叠

### 4.6 Changes
- **Jolt Physics is the DEFAULT 3D engine** for new projects
  - Existing projects keep their current physics engine setting
  - Better determinism, stability, and performance than GodotPhysics3D
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics3D
  - 2D physics UNCHANGED (still Godot Physics 2D)

### 4.5 Changes
- **3D physics interpolation rearchitected**: Moved from RenderingServer to SceneTree
  - User-facing API unchanged, but internal behavior may differ in edge cases

## Physics Engine Selection (4.6)

```
Project Settings → Physics → 3D → Physics Engine:
- Jolt Physics (DEFAULT for new projects)
- GodotPhysics3D (legacy, still available)
```

### Jolt vs GodotPhysics3D

| Feature | Jolt (default) | GodotPhysics3D |
|---------|---------------|----------------|
| Determinism | Better | Inconsistent |
| Stability | Better | Adequate |
| Performance | Better for complex scenes | Adequate |
| HingeJoint3D `damp` | NOT supported | Supported |
| Runtime warnings | Yes, for unsupported properties | No |
| Collision margins | May behave differently | Original behavior |

## Current API Patterns

### Basic Physics Setup (unchanged)
```gdscript
# CharacterBody3D movement — API unchanged across engines
extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 4.5

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity += get_gravity() * delta

    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

    var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "back")
    var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    move_and_slide()
```

### Raycasting (unchanged)
```gdscript
var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
var query := PhysicsRayQueryParameters3D.create(from, to)
query.collision_mask = collision_mask
var result: Dictionary = space_state.intersect_ray(query)
if result:
    var hit_point: Vector3 = result.position
    var hit_normal: Vector3 = result.normal
```

## Common Mistakes
- Assuming GodotPhysics3D is the default (Jolt since 4.6)
- Using HingeJoint3D `damp` property without checking physics engine (Jolt ignores it)
- Not testing collision edge cases when switching between physics engines
