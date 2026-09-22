# Godot — Breaking Changes

Last verified: 2026-08-14

Changes between Godot versions, focused on post-LLM-cutoff changes (4.4+).

## 4.6 → 4.7 (Jun 2026 — POST-CUTOFF, HIGH RISK)

官方迁移指南：https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html

### API 破坏性变更

| Subsystem | Change | Details |
|-----------|--------|---------|
| Animation | `Animation.length` 类型元数据 `float` → `double` | 源码级破坏（C#/GDScript Source ❌）。GDScript 项目需重测动画时长逻辑。 |
| Animation | `AnimationNodeBlendSpace1D/2D.add_blend_point()` 新增 `name` 可选参数 | 兼容（Compatible） |
| Animation | `AnimationNodeBlendSpace1D/2D` 的 `sync` 布尔属性 → `SyncMode` 枚举 | 升级后动画过渡可能不正确，需手动设置 `sync_mode` |
| Core | `Object.is_class()` 的 `class` 参数 `String` → `StringName` | GH-118582 |
| Core | `ZIPPacker.start_file()` 新增 `permissions`、`modified_time` 可选参数 | GH-115946 |
| Core | `OptimizedTranslation.generate()` 返回 `void` → `bool` | GH-119563 |
| GDScript | 覆盖带类型返回的父类方法继承返回类型 | 必须显式 `return`，否则报错——加 `return null` 修复（GH-115763） |
| GDScript | packed array 元素 setter 不再触发整个 packed array 属性 setter | GH-113228 |
| Rendering | `CanvasItem` 画线不再加抗锯齿羽化 | 线变细；依赖此行为需手动加粗线宽（GH-105122） |
| Rendering | `ImageTexture.get_format()` 移至基类 `Texture2D` | 兼容（GH-109004） |
| Rendering | `PortableCompressedTexture2D.get_format()` 移至基类 `Texture2D` | 兼容（GH-109004） |
| Rendering | `RenderingServer.particles_request_process_time()` 参数 `time` → `process_time`，新增 `process_time_residual` | 源码级破坏（GH-109142） |
| Rendering | `RenderingServer.viewport_set_size()` 新增 `view_count` 可选参数 | 兼容（GH-115799） |
| Rendering | `LinearToSRGB` 视觉着色器不再 clamp 到 `[0,1]`（Mobile / Forward+） | GH-113956 |
| 2D | `CPUParticles2D` / `GPUParticles2D.request_particles_process()` 新增 `process_time_residual` 可选参数 | 兼容（GH-109142） |
| Physics 2D | `PhysicsServer2D.body_set_shape_as_one_way_collision()` 新增 `direction` 可选参数 | 兼容（GH-104736） |
| Physics 2D | `PhysicsServer2DExtension._body_set_shape_as_one_way_collision()` 新增 `direction`（必填） | GDScript/源码级破坏（GH-104736） |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` 属性 | **完全移除**（GH-114355） |
| Audio | `AudioStreamPlayer.area_mask` 默认值 `1` → `0`（禁用） | 若用 `Area2D` 的 `audio_bus_override` 且依赖默认 mask，需重置为 layer 1（GH-107679） |
| Input | 鼠标/键盘 device ID 从 `0` 改为 `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` | 若代码用 `device == 0` 判断鼠标键盘会失效（GH-116274） |
| GUI | `Control.accessibility_live` 类型 `DisplayServer.AccessibilityLiveMode` → `AccessibilityServer.AccessibilityLiveMode` | 源码级破坏（GH-116839） |
| GUI | `RichTextLabel` 的 `add_image`/`update_image` 参数大改 | `width_in_percent`/`height_in_percent` 布尔参数 → `width_unit`/`height_unit`（`ImageUnit` 类型）；width/height `int` → `float`。源码级破坏（GH-112617） |
| GUI | `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` 重命名为 `UPDATE_WIDTH_UNIT` | GDScript/源码级破坏（GH-112617） |
| Font | `Font.find_variation()` 新增 `palette_index`、`custom_colors` 可选参数 | 兼容（GH-117149） |
| Tree | `TreeItem.select()` 新增 `set_as_cursor` 可选参数 | 兼容（GH-119367） |
| Image | `Image.save_exr()` / `save_exr_to_buffer()` 新增 `color_image`、`max_linear_value` 可选参数 | 兼容（GH-117800） |
| XR | `OpenXRExtensionWrapper._on_register_metadata()` 新增 `interaction_profile_metadata`（必填） | 全部破坏（本项目无 XR，GH-117399） |
| Editor | `EditorSceneFormatImporter` 的 `IMPORT_*` 常量移入 `ImportFlags` 枚举 | 源码级破坏（编辑器扩展专用，GH-115788） |
| Editor | `EditorVCSInterface._commit()` 新增 `amend`（必填） | 全部破坏（GH-117968） |
| Platform | macOS 最低版本从 10.13 提升至 11（Big Sur） | 影响编辑器/导出最低运行系统 |

### 默认值变更（仅新项目）

| 项目 | 旧默认 | 新默认 |
|------|--------|--------|
| Stretch mode | `disabled` | `canvas_items` |
| Stretch aspect | `keep` | `expand` |
| `LookAtModifier3D.relative` | `true` | `false` |
| 动态字体 hinting | `1` | `3` |

## 4.5 → 4.6 (Jan 2026 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Physics | Jolt is now the DEFAULT 3D physics engine | New projects use Jolt automatically. Existing projects keep their setting. Some HingeJoint3D properties (like `damp`) only work with GodotPhysics. |
| Rendering | Glow processes BEFORE tonemapping | Was after tonemapping. Scenes with glow will look different. Adjust intensity/blend in WorldEnvironment. |
| Rendering | D3D12 default on Windows | Was Vulkan. For better driver compatibility. |
| Rendering | AgX tonemapper new controls | White point and contrast parameters added. |
| Core | Quaternion initializes to identity | Was zero. Unlikely to affect most code but technically breaking. |
| UI | Dual-focus system | Mouse/touch focus now separate from keyboard/gamepad focus. Visual feedback differs by input method. |
| Animation | IK system fully restored | CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK via SkeletonModifier3D nodes. |
| Editor | New "Modern" theme default | Grayscale replaces blue-tint. Restore: Editor Settings → Interface → Theme → Style: Classic |
| Editor | "Select Mode" keybind changed | New "Select Mode" (v key) prevents accidental transforms. Old mode renamed "Transform Mode" (q key). |
| 2D | TileMapLayer scene tile rotation | Scene tiles can now be rotated like atlas tiles. |
| Localization | CSV plural form support | No longer requires Gettext for plurals. Context columns added. |
| C# | Automatic string extraction | Translation strings auto-extracted from C# code. |
| Plugins | New EditorDock class | Specialized container for plugin docks with layout control. |

## 4.4 → 4.5 (Late 2025 — POST-CUTOFF, HIGH RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Variadic arguments added | Functions can accept `...` arbitrary params — new language feature |
| GDScript | `@abstract` decorator | Abstract classes and methods now enforceable |
| GDScript | Script backtracing | Detailed call stacks available even in Release builds |
| Rendering | Stencil buffer support | New capability for advanced visual effects |
| Rendering | SMAA 1x antialiasing | New post-processing AA option |
| Rendering | Shader Baker | Pre-compiles shaders — reportedly 20x faster startup on some demos |
| Rendering | Bent normal maps, specular occlusion | New material features |
| Accessibility | Screen reader support | Control nodes work with accessibility tools via AccessKit |
| Editor | Live translation preview | Test GUI layouts in different languages in-editor |
| Physics | 3D interpolation rearchitected | Moved from RenderingServer to SceneTree. API unchanged but internals differ. |
| Animation | BoneConstraint3D | New: AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D |
| Resources | `duplicate_deep()` added | New explicit method for deep duplication of nested resources |
| Navigation | Dedicated 2D navigation server | No longer a proxy to 3D navigation; smaller export for 2D games |
| UI | FoldableContainer node | New accordion-style container for collapsible UI sections |
| UI | Recursive Control behavior | Disable mouse/focus interactions across entire node hierarchies |
| Platform | visionOS export support | New platform target |
| Platform | SDL3 gamepad driver | Delegated gamepad handling to SDL library |
| Platform | Android 16KB page support | Required for Google Play targeting Android 15+ |

## 4.3 → 4.4 (Mid 2025 — NEAR CUTOFF, VERIFY)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `FileAccess.store_*` return `bool` | Was `void`. Methods: `store_8`, `store_16`, `store_32`, `store_64`, `store_buffer`, `store_csv_line`, `store_double`, `store_float`, `store_half`, `store_line`, `store_pascal_string`, `store_real`, `store_string`, `store_var` |
| Core | `OS.execute_with_pipe` | Added optional `blocking` parameter |
| Core | `RegEx.compile/create_from_string` | Added optional `show_error` parameter |
| Rendering | `RenderingDevice.draw_list_begin` | Many parameters removed; `breadcrumb` parameter added |
| Rendering | Shader texture types | Parameter/return types changed from `Texture2D` to `Texture` |
| Particles | `.restart()` method | Added optional `keep_seed` parameter (CPU/GPU 2D/3D) |
| GUI | `RichTextLabel.push_meta` | Added optional `tooltip` parameter |
| GUI | `GraphEdit.connect_node` | Added optional `keep_alive` parameter |

## 4.2 → 4.3 (In Training Data — LOW RISK)

| Subsystem | Change | Details |
|-----------|--------|---------|
| Animation | `Skeleton3D.add_bone` returns `int32` | Was `void` |
| Animation | `bone_pose_updated` signal | Replaced by `skeleton_updated` |
| TileMap | `TileMapLayer` replaces `TileMap` | One node per layer instead of multi-layer single node |
| Navigation | `NavigationRegion2D` | Removed `avoidance_layers`, `constrain_avoidance` properties |
| Editor | `EditorSceneFormatImporterFBX` | Renamed to `EditorSceneFormatImporterFBX2GLTF` |
| Animation | AnimationMixer base class | AnimationPlayer and AnimationTree now extend AnimationMixer |
