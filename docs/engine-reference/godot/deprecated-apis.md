# Godot — Deprecated APIs

Last verified: 2026-08-18

If an agent suggests any API in the "Deprecated" column, it MUST be replaced
with the "Use Instead" column.

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
| `AudioEffectSpectrumAnalyzer.tap_back_pos` | *(removed — no replacement)* | 4.7 | Property deleted; read the analyzer instance directly |
| `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` | `UPDATE_WIDTH_UNIT` | 4.7 | Enum field renamed |
| `RichTextLabel.add_image(..., width_in_percent)` | `add_image(..., width_unit: RichTextLabel.ImageUnit)` | 4.7 | Renamed and retyped; width/height also `int` → `float` |
| `EditorSceneFormatImporter.IMPORT_*` constants | `EditorSceneFormatImporter.ImportFlags.*` | 4.7 | Seven loose constants folded into an enum |
| `ImageTexture.get_format()` (on the subclass) | `Texture2D.get_format()` | 4.7 | Moved to the base class |

## Patterns (Not Just APIs)

| Deprecated Pattern | Use Instead | Why |
|--------------------|-------------|-----|
| String-based `connect()` | Typed signal connections | Type-safe, refactor-friendly |
| `$NodePath` in `_process()` | `@onready var` cached reference | Performance: path lookup every frame |
| Untyped `Array` / `Dictionary` | `Array[Type]`, typed variables | GDScript compiler optimizations |
| `Texture2D` in shader parameters | `Texture` base type | Changed in 4.4 |
| Manual post-process viewport chains | `Compositor` + `CompositorEffect` | Structured post-processing (4.3+) |
| GodotPhysics3D for new projects | Jolt Physics 3D | Default since 4.6; better stability |
| `event.device == 0` to detect mouse/keyboard | `InputEvent.DEVICE_ID_MOUSE` / `InputEvent.DEVICE_ID_KEYBOARD` | Device IDs stopped being `0` in 4.7 |
| Omitting the return type when overriding an inherited method | Declare the return type explicitly on every override | Required in 4.7 — untyped overrides no longer parse |
| Relying on a property setter firing from `packed_array[i] = x` | Assign the whole array, or call the setter directly | Packed array element assignment stopped invoking setters in 4.7 |
