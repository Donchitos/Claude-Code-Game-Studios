# Godot — Deprecated APIs
# Godot — 已弃用 API

Last verified: 2026-10-17 (4.7 rows); 2026-02-12 (rest)
最后验证：2026-10-17（4.7 各行）；2026-02-12（其余部分）

The 4.7 migration guide lists no formal deprecations; the 4.7 rows below are
renames and removals from it
(https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html).
4.7 迁移指南未列出任何正式的弃用项；下表中 4.7 的各行均为该指南中的重命名和移除项
（https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html）。

If an agent suggests any API in the "Deprecated" column, it MUST be replaced
with the "Use Instead" column.
如果智能体建议使用"Deprecated"（已弃用）列中的任何 API，则必须替换为"Use Instead"（改用）列中的对应项。

## Nodes & Classes
## 节点与类

| Deprecated | Use Instead | Since | Notes |
|------------|-------------|-------|-------|
| `TileMap` | `TileMapLayer` | 4.3 | One node per layer instead of multi-layer node |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` | 4.0 | Renamed for clarity |
| `VisibilityNotifier3D` | `VisibleOnScreenNotifier3D` | 4.0 | Renamed for clarity |
| `YSort` | `Node2D.y_sort_enabled` | 4.0 | Property on Node2D, not a separate node |
| `Navigation2D` / `Navigation3D` | `NavigationServer2D` / `NavigationServer3D` | 4.0 | Server-based API |
| `EditorSceneFormatImporterFBX` | `EditorSceneFormatImporterFBX2GLTF` | 4.3 | Renamed |

| 已弃用 | 改用 | 起始版本 | 备注 |
|------------|-------------|-------|-------|
| `TileMap` | `TileMapLayer` | 4.3 | 每层一个节点，而非多层节点 |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` | 4.0 | 为清晰起见重命名 |
| `VisibilityNotifier3D` | `VisibleOnScreenNotifier3D` | 4.0 | 为清晰起见重命名 |
| `YSort` | `Node2D.y_sort_enabled` | 4.0 | Node2D 上的属性，而非单独节点 |
| `Navigation2D` / `Navigation3D` | `NavigationServer2D` / `NavigationServer3D` | 4.0 | 基于服务器的 API |
| `EditorSceneFormatImporterFBX` | `EditorSceneFormatImporterFBX2GLTF` | 4.3 | 重命名 |

## Methods & Properties
## 方法与属性

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
| `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` | `ImageUpdateMask.UPDATE_WIDTH_UNIT` | 4.7 | Renamed; GDScript using the old name breaks |
| `add_image()` / `update_image()` `width_in_percent`, `height_in_percent` (`bool`) | `width_unit`, `height_unit` (`RichTextLabel.ImageUnit`) | 4.7 | Renamed and retyped |
| `DisplayServer.AccessibilityLiveMode` for `Control.accessibility_live` | `AccessibilityServer.AccessibilityLiveMode` | 4.7 | Enum moved to `AccessibilityServer` |
| `AudioEffectSpectrumAnalyzer.tap_back_pos` | — | 4.7 | Removed |
| `EditorSceneFormatImporter.IMPORT_*` constants | `EditorSceneFormatImporter.ImportFlags` enum | 4.7 | Same names, now in an enum |

| 已弃用 | 改用 | 起始版本 | 备注 |
|------------|-------------|-------|-------|
| `yield()` | `await signal` | 4.0 | GDScript 2.0 协程语法 |
| `connect("signal", obj, "method")` | `signal.connect(callable)` | 4.0 | 基于 Callable 的连接 |
| `instance()` | `instantiate()` | 4.0 | 重命名 |
| `PackedScene.instance()` | `PackedScene.instantiate()` | 4.0 | 重命名 |
| `get_world()` | `get_world_3d()` | 4.0 | 明确的 2D/3D 拆分 |
| `OS.get_ticks_msec()` | `Time.get_ticks_msec()` | 4.0 | 首选 Time 单例 |
| 用于嵌套资源的 `duplicate()` | `duplicate_deep()` | 4.5 | 显式的深复制控制 |
| `Skeleton3D` 信号 `bone_pose_updated` | `skeleton_updated` | 4.3 | 重命名 |
| `AnimationPlayer.method_call_mode` | `AnimationMixer.callback_mode_method` | 4.3 | 移至基类 |
| `AnimationPlayer.playback_active` | `AnimationMixer.active` | 4.3 | 移至基类 |
| `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` | `ImageUpdateMask.UPDATE_WIDTH_UNIT` | 4.7 | 重命名；使用旧名称的 GDScript 会失效 |
| `add_image()` / `update_image()` 的 `width_in_percent`、`height_in_percent`（`bool`） | `width_unit`、`height_unit`（`RichTextLabel.ImageUnit`） | 4.7 | 重命名并更换类型 |
| 用于 `Control.accessibility_live` 的 `DisplayServer.AccessibilityLiveMode` | `AccessibilityServer.AccessibilityLiveMode` | 4.7 | 枚举移至 `AccessibilityServer` |
| `AudioEffectSpectrumAnalyzer.tap_back_pos` | — | 4.7 | 已移除 |
| `EditorSceneFormatImporter.IMPORT_*` 常量 | `EditorSceneFormatImporter.ImportFlags` 枚举 | 4.7 | 名称相同，现在位于枚举中 |

## Patterns (Not Just APIs)
## 模式（不仅是 API）

| Deprecated Pattern | Use Instead | Why |
|--------------------|-------------|-----|
| String-based `connect()` | Typed signal connections | Type-safe, refactor-friendly |
| `$NodePath` in `_process()` | `@onready var` cached reference | Performance: path lookup every frame |
| Untyped `Array` / `Dictionary` | `Array[Type]`, typed variables | GDScript compiler optimizations |
| `Texture2D` in `Shader.set_default_texture_parameter()` / `get_default_texture_parameter()` | `Texture` base type | Changed in 4.4; the shading language's `sampler2D` / `texture()` did not change |
| Manual post-process viewport chains | `Compositor` + `CompositorEffect` | Structured post-processing (4.3+) |
| GodotPhysics3D for new projects | Jolt Physics 3D | Default since 4.6; better stability |
| `event.device == 0` to detect mouse or keyboard | `event is InputEventMouse` / `InputEventKey`, or `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` | Since 4.7 mouse and keyboard no longer report device `0`, which some joypads use |
| Installing addons from the editor's AssetLib tab | The editor's Asset Store workspace (4.7+) | 4.7 replaced the Asset Library with the Asset Store |

| 已弃用模式 | 改用 | 原因 |
|--------------------|-------------|-----|
| 基于字符串的 `connect()` | 类型化信号连接 | 类型安全，便于重构 |
| 在 `_process()` 中使用 `$NodePath` | 用 `@onready var` 缓存引用 | 性能：每帧都要查找路径 |
| 无类型的 `Array` / `Dictionary` | `Array[Type]`、类型化变量 | GDScript 编译器优化 |
| 在 `Shader.set_default_texture_parameter()` / `get_default_texture_parameter()` 中使用 `Texture2D` | `Texture` 基类型 | 4.4 中变更；着色语言的 `sampler2D` / `texture()` 未变 |
| 手动搭建后处理视口链 | `Compositor` + `CompositorEffect` | 结构化后处理（4.3+） |
| 新项目使用 GodotPhysics3D | Jolt Physics 3D | 自 4.6 起为默认；稳定性更好 |
| 用 `event.device == 0` 检测鼠标或键盘 | `event is InputEventMouse` / `InputEventKey`，或 `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` | 自 4.7 起，鼠标和键盘不再报告设备 `0`，而某些手柄会使用 `0` |
| 从编辑器的 AssetLib 标签页安装插件 | 编辑器的 Asset Store 工作区（4.7+） | 4.7 用 Asset Store 取代了 Asset Library |
