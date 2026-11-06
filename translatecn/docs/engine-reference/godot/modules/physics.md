# Godot Physics — Quick Reference
# Godot 物理 — 快速参考

Last verified: 2026-10-17 (4.7 changes); 2026-02-12 (rest) | Engine: Godot 4.7
最后验证：2026-10-17（4.7 变更）；2026-02-12（其余部分） | 引擎：Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)
## 自约 4.3（LLM 截止）以来的变更

### 4.7 Changes
### 4.7 变更
- **Jolt `WorldBoundaryShape3D`**: `plane.d` sign now matches Godot Physics,
  flipped from 4.6; negate it to keep 4.6 behavior
- **Jolt `WorldBoundaryShape3D`**：`plane.d` 的符号现在与 Godot Physics 一致，且与 4.6 相比是翻转的；取负即可保持 4.6 的行为
- **Jolt `SoftBody3D`**: mass defaults to 1 kg for the whole body (was 1 kg per
  point) and `linear_stiffness` is applied differently; re-tune
  `linear_stiffness` and `damping_coefficient`
- **Jolt `SoftBody3D`**：质量默认按整个物体 1 kg（原为每个点 1 kg），且 `linear_stiffness` 的应用方式不同；请重新调整 `linear_stiffness` 和 `damping_coefficient`
- **Jolt `Area3D`** reports overlaps with `SoftBody3D`; filter with layers/masks
- **Jolt `Area3D`** 会报告与 `SoftBody3D` 的重叠；请用层/掩码进行过滤
- **`PhysicsServer2D.body_set_shape_as_one_way_collision()`**: optional
  `direction` parameter (required in `PhysicsServer2DExtension`) (4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- **`PhysicsServer2D.body_set_shape_as_one_way_collision()`**：可选 `direction` 参数（在 `PhysicsServer2DExtension` 中为必需）（4.7 迁移指南：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html）

### 4.6 Changes
### 4.6 变更
- **Jolt Physics is the DEFAULT 3D engine** for new projects
- **Jolt Physics 是新项目的默认 3D 引擎**
  - Existing projects keep their current physics engine setting
  - 现有项目保留其当前的物理引擎设置
  - Better determinism, stability, and performance than GodotPhysics3D
  - 比 GodotPhysics3D 具有更好的确定性、稳定性和性能
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics3D
  - 某些 HingeJoint3D 属性（`damp`）仅适用于 GodotPhysics3D
  - 2D physics UNCHANGED (still Godot Physics 2D)
  - 2D 物理未变（仍为 Godot Physics 2D）

### 4.5 Changes
### 4.5 变更
- **3D physics interpolation rearchitected**: Moved from RenderingServer to SceneTree
- **3D 物理插值已重构**：从 RenderingServer 移至 SceneTree
  - User-facing API unchanged, but internal behavior may differ in edge cases
  - 面向用户的 API 未变，但内部行为在边界情况下可能不同

## Physics Engine Selection (4.6)
## 物理引擎选择（4.6）

```
Project Settings → Physics → 3D → Physics Engine:
- Jolt Physics (DEFAULT for new projects)
- GodotPhysics3D (legacy, still available)
```

### Jolt vs GodotPhysics3D
### Jolt 与 GodotPhysics3D 对比

| Feature | Jolt (default) | GodotPhysics3D |
|---------|---------------|----------------|
| Determinism | Better | Inconsistent |
| Stability | Better | Adequate |
| Performance | Better for complex scenes | Adequate |
| HingeJoint3D `damp` | NOT supported | Supported |
| Runtime warnings | Yes, for unsupported properties | No |
| Collision margins | May behave differently | Original behavior |

| 特性 | Jolt（默认） | GodotPhysics3D |
|---------|---------------|----------------|
| 确定性 | 更好 | 不一致 |
| 稳定性 | 更好 | 尚可 |
| 性能 | 复杂场景下更好 | 尚可 |
| HingeJoint3D 的 `damp` | 不支持 | 支持 |
| 运行时警告 | 有，针对不支持的属性 | 无 |
| 碰撞边距 | 行为可能不同 | 原始行为 |

## Current API Patterns
## 当前 API 模式

### Basic Physics Setup (unchanged)
### 基础物理设置（未变）
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
### 射线检测（未变）
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
## 常见错误
- Assuming GodotPhysics3D is the default (Jolt since 4.6)
- 误以为 GodotPhysics3D 是默认引擎（自 4.6 起为 Jolt）
- Using HingeJoint3D `damp` property without checking physics engine (Jolt ignores it)
- 使用 HingeJoint3D 的 `damp` 属性时未检查物理引擎（Jolt 会忽略它）
- Not testing collision edge cases when switching between physics engines
- 在物理引擎之间切换时未测试碰撞的边界情况
