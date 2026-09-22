# Godot — Deprecated APIs

Last verified: 2026-08-14

If an agent suggests any API in the "Deprecated" column, it MUST be replaced
with the "Use Instead" column.

## Removed in 4.7 (no replacement)

| Removed | Since | Notes |
|---------|-------|-------|
| `AudioEffectSpectrumAnalyzer.tap_back_pos` | 4.7 | 属性完全移除，无替代（GH-114355） |

## 4.7 重命名/重构（非弃用但 API 签名变了，见 breaking-changes.md）

| Old | New | Since |
|-----|-----|-------|
| `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` | `UPDATE_WIDTH_UNIT` | 4.7 |
| `RichTextLabel.add_image/update_image` 的 `width_in_percent`/`height_in_percent`（bool） | `width_unit`/`height_unit`（`ImageUnit`） | 4.7 |
| `RenderingServer.particles_request_process_time(time)` | `particles_request_process_time(process_time, process_time_residual)` | 4.7 |
| `Object.is_class(class: String)` | `is_class(class: StringName)` | 4.7 |
| `AnimationNodeBlendSpace1D/2D` 的 `sync`（bool） | `sync_mode`（`SyncMode` 枚举） | 4.7 |
| `InputEvent.device == 0`（鼠标/键盘判断） | `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` | 4.7 |
| `Animation.length`（float 元数据） | `Animation.length`（double 元数据） | 4.7 |



## Nodes & Classes

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `TileMap` | `TileMapLayer` | 4.3 | One node per layer instead of multi-layer node |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` | 4.0 | Renamed for clarity |
| `VisibilityNotifier3D` | `VisibleOnScreenNotifier3D` | 4.0 | Renamed for clarity |
| `YSort` | `Node2D.y_sort_enabled` | 4.0 | Property on Node2D, not a separate node |
| `Navigation2D` / `Navigation3D` | `NavigationServer2D` / `NavigationServer3D` | 4.0 | Server-based API |
| `EditorSceneFormatImporterFBX` | `EditorSceneFormatImporterFBX2GLTF` | 4.3 | Renamed |

## Methods & Properties

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `yield()` | `await signal` | 4.0 | GDScript 2.0 coroutine syntax |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | 4.0 | Callable-based connections |
| `instance()` | `instantiate()` | 4.0 | Renamed |
| `PackedScene.instance()` | `PackedScene.instantiate()` | 4.0 | Renamed |
| `get_world()` | `get_world_3d()` | 4.0 | Explicit 2D/3D split |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | 4.0 | Time singleton preferred |
| `duplicate()` for nested resources | `duplicate_deep()` | 4.5 | Explicit deep copy control |
| `Skeleton3D` signal `bone_pose_updated` | `skeleton_updated` | 4.3 | Renamed |
| `AnimationPlayer.method_call_mode` | `AnimationMixer.callback_mode_method` | 4.3 | Moved to base class |
| `AnimationPlayer.playback_active` | `AnimationMixer.active` | 4.3 | Moved to base class |

## Patterns (Not Just APIs)

| Deprecated Pattern | Use Instead | Why |
|--------------------|-------------|-----|
| String-based `connect()` | Typed signal connections | Type-safe, refactor-friendly |
| `$NodePath` in `_process()` | `@onready var` cached reference | Performance: path lookup every frame |
| Untyped `Array` / `Dictionary` | `Array[Type]`, typed variables | GDScript compiler optimizations |
| `Texture2D` in shader parameters | `Texture` base type | Changed in 4.4 |
| Manual post-process viewport chains | `Compositor` + `CompositorEffect` | Structured post-processing (4.3+) |
| GodotPhysics3D for new projects | Jolt Physics 3D | Default since 4.6; better stability |
