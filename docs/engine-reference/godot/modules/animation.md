# Godot Animation — Quick Reference

Last verified: 2026-02-12 | Engine: Godot 4.6

> **Version note:** this project is pinned to **Godot 4.7**. This file was last verified
> against 4.6 — see `../VERSION.md` and the 4.6 → 4.7 section of `../breaking-changes.md`
> before relying on anything version-sensitive.

## What Changed Since ~4.3 (LLM Cutoff)

### 4.6 Changes
- **IK system fully restored**: Complete inverse kinematics for 3D skeletons
  - CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK
  - Applied via `SkeletonModifier3D` nodes (not the old IK approach)
- **Animation editor QoL**: Solo/hide/lock/delete for Bezier node groups; draggable timeline

### 4.5 Changes
- **BoneConstraint3D**: Bind bones to other bones with modifiers
  - `AimModifier3D`, `CopyTransformModifier3D`, `ConvertTransformModifier3D`

### 4.3 Changes (in training data)
- **AnimationMixer**: Base class for both AnimationPlayer and AnimationTree
  - `method_call_mode` → `callback_mode_method`
  - `playback_active` → `active`
  - `bone_pose_updated` signal → `skeleton_updated`
- **`Skeleton3D.add_bone()`**: Now returns `int32` (was `void`)

## Current API Patterns

### AnimationPlayer (unchanged API, new base class)
```gdscript
@onready var anim_player: AnimationPlayer = %AnimationPlayer

func play_attack() -> void:
    anim_player.play(&"attack")
    await anim_player.animation_finished
```

### IK Setup (4.6 — NEW)
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
```gdscript
# Add as child of Skeleton3D
# Types:
# - AimModifier3D: Point bone at target
# - CopyTransformModifier3D: Mirror another bone's transform
# - ConvertTransformModifier3D: Remap transform values
```

### AnimationTree (base class changed in 4.3)
```gdscript
# AnimationTree now extends AnimationMixer (not Node directly)
# Use AnimationMixer properties:
@onready var anim_tree: AnimationTree = %AnimationTree

func _ready() -> void:
    anim_tree.active = true  # NOT playback_active (deprecated 4.3)
```

## Common Mistakes
- Using `playback_active` instead of `active` (deprecated since 4.3)
- Using `bone_pose_updated` signal instead of `skeleton_updated` (renamed in 4.3)
- Using old IK approach instead of SkeletonModifier3D system (restored in 4.6)
- Not checking `is AnimationMixer` when type-checking animation nodes
