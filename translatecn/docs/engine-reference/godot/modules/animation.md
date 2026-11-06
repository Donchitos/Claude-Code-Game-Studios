# Godot Animation — Quick Reference
# Godot 动画 — 快速参考

Last verified: 2026-10-17 (4.7 changes); 2026-02-12 (rest) | Engine: Godot 4.7
最后验证：2026-10-17（4.7 变更）；2026-02-12（其余部分） | 引擎：Godot 4.7

## What Changed Since ~4.3 (LLM Cutoff)
## 自约 4.3（LLM 截止）以来的变更

### 4.7 Changes
### 4.7 变更
- **`Tween.tween_await()`**: pauses a tween until a signal is emitted (4.7 release notes: https://godotengine.org/releases/4.7/)
- **`Tween.tween_await()`**：暂停补间，直到发出某个信号（4.7 发行说明：https://godotengine.org/releases/4.7/）
- **`LookAtModifier3D.relative`** defaults to `false` (was `true`)
- **`LookAtModifier3D.relative`** 默认值为 `false`（原为 `true`）
- **`AnimationNodeBlendSpace1D/2D.add_blend_point()`**: optional `name` parameter
- **`AnimationNodeBlendSpace1D/2D.add_blend_point()`**：可选 `name` 参数
- **`Animation.length`** is `double` in C# (was `float`); GDScript unaffected (4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- **`Animation.length`** 在 C# 中为 `double`（原为 `float`）；GDScript 不受影响（4.7 迁移指南：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html）

### 4.6 Changes
### 4.6 变更
- **IK system fully restored**: Complete inverse kinematics for 3D skeletons
- **IK 系统完全恢复**：为 3D 骨架提供完整的逆向运动学
  - CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK
  - CCDIK、FABRIK、Jacobian IK、Spline IK、TwoBoneIK
  - Applied via `SkeletonModifier3D` nodes (not the old IK approach)
  - 通过 `SkeletonModifier3D` 节点应用（而非旧的 IK 方式）
- **Animation editor QoL**: Solo/hide/lock/delete for Bezier node groups; draggable timeline
- **动画编辑器易用性改进**：对贝塞尔节点组支持独奏/隐藏/锁定/删除；可拖动的时间轴

### 4.5 Changes
### 4.5 变更
- **BoneConstraint3D**: Bind bones to other bones with modifiers
- **BoneConstraint3D**：使用修饰器将骨骼绑定到其他骨骼
  - `AimModifier3D`, `CopyTransformModifier3D`, `ConvertTransformModifier3D`
  - `AimModifier3D`、`CopyTransformModifier3D`、`ConvertTransformModifier3D`

### 4.3 Changes (in training data)
### 4.3 变更（在训练数据中）
- **AnimationMixer**: Base class for both AnimationPlayer and AnimationTree
- **AnimationMixer**：AnimationPlayer 和 AnimationTree 的基类
  - `method_call_mode` → `callback_mode_method`
  - `method_call_mode` → `callback_mode_method`
  - `playback_active` → `active`
  - `playback_active` → `active`
  - `bone_pose_updated` signal → `skeleton_updated`
  - `bone_pose_updated` 信号 → `skeleton_updated`
- **`Skeleton3D.add_bone()`**: Now returns `int32` (was `void`)
- **`Skeleton3D.add_bone()`**：现在返回 `int32`（原为 `void`）

## Current API Patterns
## 当前 API 模式

### AnimationPlayer (unchanged API, new base class)
### AnimationPlayer（API 未变，新增基类）
```gdscript
@onready var anim_player: AnimationPlayer = %AnimationPlayer

func play_attack() -> void:
    anim_player.play(&"attack")
    await anim_player.animation_finished
```

### IK Setup (4.6 — NEW)
### IK 设置（4.6 — 新增）
```gdscript
# Add SkeletonModifier3D-based IK nodes as children of Skeleton3D
# Available types:
# - SkeletonModifier3D (base)
# - TwoBoneIK (arms, legs)
# - FABRIK (chains, tentacles)
# - CCDIK (tails, spines)
# - Jacobian IK (complex multi-joint)
# - Spline IK (along curves)

# Configure in editor or code:
# 1. Add IK modifier node as child of Skeleton3D
# 2. Set target bone and tip bone
# 3. Add a Marker3D as the IK target
# 4. IK solver runs automatically each frame
```

### BoneConstraint3D (4.5 — NEW)
### BoneConstraint3D（4.5 — 新增）
```gdscript
# Add as child of Skeleton3D
# Types:
# - AimModifier3D: Point bone at target
# - CopyTransformModifier3D: Mirror another bone's transform
# - ConvertTransformModifier3D: Remap transform values
```

### AnimationTree (base class changed in 4.3)
### AnimationTree（基类在 4.3 中变更）
```gdscript
# AnimationTree now extends AnimationMixer (not Node directly)
# Use AnimationMixer properties:
@onready var anim_tree: AnimationTree = %AnimationTree

func _ready() -> void:
    anim_tree.active = true  # NOT playback_active (deprecated 4.3)
```

## Common Mistakes
## 常见错误
- Using `playback_active` instead of `active` (deprecated since 4.3)
- 使用 `playback_active` 而非 `active`（自 4.3 起已弃用）
- Using `bone_pose_updated` signal instead of `skeleton_updated` (renamed in 4.3)
- 使用 `bone_pose_updated` 信号而非 `skeleton_updated`（4.3 中重命名）
- Using old IK approach instead of SkeletonModifier3D system (restored in 4.6)
- 使用旧的 IK 方式而非 SkeletonModifier3D 系统（4.6 中恢复）
- Not checking `is AnimationMixer` when type-checking animation nodes
- 在对动画节点做类型检查时未检查 `is AnimationMixer`
