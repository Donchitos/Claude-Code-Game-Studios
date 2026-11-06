# Godot — Breaking Changes
# Godot — 破坏性变更

Last verified: 2026-10-17 (4.6 → 4.7 and the section dates); 2026-02-12 (older sections)
最后验证：2026-10-17（4.6 → 4.7 及各节日期）；2026-02-12（较早的各节）

Changes between Godot versions, focused on post-LLM-cutoff changes (4.4+).
各 Godot 版本之间的变更，重点关注 LLM 截止之后的变更（4.4+）。

## 4.6 → 4.7 (Jun 2026 — POST-CUTOFF, HIGH RISK)
## 4.6 → 4.7（2026 年 6 月 — 截止后，高风险）

From the official migration guide
(https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html,
checked 2026-10-17). Rows marked **GDScript breaks** stop existing GDScript from
working; the rest add optional parameters, change C# compatibility only, or
change behaviour or defaults. The guide lists no deprecations.
摘自官方迁移指南
（https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html，
核查于 2026-10-17）。标有 **GDScript 失效** 的行会使现有 GDScript 停止工作；其余各行为增加可选参数、仅改变 C# 兼容性，或改变行为或默认值。该指南未列出任何弃用项。

| Subsystem | Change | Details |
|-----------|--------|---------|
| GDScript | Overrides inherit a typed return | An override of a method with a typed return now inherits that type, so it needs an explicit `return` (add `return null` to fix the error). **GDScript breaks** |
| GDScript | Packed array element writes | Setting one element of a packed array no longer calls the setter of the whole packed-array property |
| GUI | `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` renamed | Now `UPDATE_WIDTH_UNIT`. **GDScript breaks** |
| GUI | `RichTextLabel.add_image()` / `update_image()` | `width` / `height` are `float` (were `int`); `width_in_percent` / `height_in_percent` renamed `width_unit` / `height_unit`, typed `RichTextLabel.ImageUnit` (were `bool`, default `false` → `0`). C# source breaks |
| GUI | `Control.accessibility_live` type | `AccessibilityServer.AccessibilityLiveMode` (was `DisplayServer.AccessibilityLiveMode`). C# breaks |
| Core | `Object.is_class()` | Parameter is `StringName` (was `String`) |
| Core | `OptimizedTranslation.generate()` | Returns `bool` (was `void`). C# binary breaks |
| Input | Mouse and keyboard device IDs | Were `0`; now `InputEvent.DEVICE_ID_MOUSE` and `InputEvent.DEVICE_ID_KEYBOARD`, because some joypads use `0`. Identify events by type or compare `InputEvent.device` to those constants |
| Physics | Jolt: `WorldBoundaryShape3D` plane sign | The sign of `plane.d` is read the way Godot Physics reads it, so it is flipped compared to 4.6: negate it to keep 4.6 behaviour |
| Physics | Jolt: `SoftBody3D` mass and stiffness | Mass defaults to 1 kg for the whole body (was 1 kg per point); `linear_stiffness` is applied differently. Re-tune `linear_stiffness` and `damping_coefficient` on every `SoftBody3D` |
| Physics | Jolt: `Area3D` and `SoftBody3D` | `Area3D` now reports overlaps with `SoftBody3D`; use collision layers and masks to ignore them |
| Physics | `PhysicsServer2D.body_set_shape_as_one_way_collision()` | Optional `direction` added; `PhysicsServer2DExtension._body_set_shape_as_one_way_collision()` requires it (extensions break) |
| Audio | `AudioStreamPlayer2D` / `AudioStreamPlayer3D` `area_mask` default | Changed from layer `1` to `0` (disabled). An `Area2D`/`Area3D` `audio_bus_override` that relied on the default mask stops working until the mask is set back to layer `1` |
| Audio | `AudioEffectSpectrumAnalyzer.tap_back_pos` | Removed. **GDScript breaks** where it is used |
| Rendering | `CanvasItem` line drawing | No antialiasing feather is added, so lines look thinner; widen lines that relied on the old thickness |
| Rendering | `LinearToSRGB` visual shader node | No longer clamps to `[0.0, 1.0]` under Forward+ and Mobile |
| Rendering | `get_format()` moved | From `ImageTexture` / `PortableCompressedTexture2D` to base class `Texture2D` |
| Rendering | `RenderingServer.particles_request_process_time()` | `time` renamed `process_time`; optional `process_time_residual` added (also on `request_particles_process()` of the four particle nodes) |
| Rendering | Sky reflection roughness layers | `rendering/reflections/sky_reflections/roughness_layers` default `7` → `8` |
| Animation | `Animation.length` | Type metadata `double` (was `float`). C# breaks |
| Animation | `LookAtModifier3D.relative` | Default `false` (was `true`) |
| Animation | `AnimationNodeBlendSpace1D/2D.add_blend_point()` | Optional `name` added |
| Project | Stretch defaults for NEW projects | `display/window/stretch/mode` `canvas_items` (was `disabled`), `display/window/stretch/aspect` `expand` (was `keep`). Existing projects keep their settings |
| Text | `ResourceImporterDynamicFont.hinting` | Default `3` (was `1`) |
| Editor | `EditorSceneFormatImporter` import constants | Moved into the `ImportFlags` enum (`IMPORT_SCENE`, `IMPORT_ANIMATION`, …). C# source breaks |
| Editor | `EditorVCSInterface._commit()` | New `amend` parameter; VCS plugins break |
| Editor | Asset Library replaced by the Asset Store | The editor workspace is now "Asset Store" (release notes: https://godotengine.org/releases/4.7/) |
| XR | `OpenXRExtensionWrapper._on_register_metadata()` | New `interaction_profile_metadata` parameter; extensions break |

| 子系统 | 变更 | 详情 |
|-----------|--------|---------|
| GDScript | 覆写继承类型化返回值 | 对带类型化返回值的方法进行覆写时，现在会继承该类型，因此需要显式的 `return`（添加 `return null` 可修复该错误）。**GDScript 失效** |
| GDScript | 紧凑数组元素写入 | 设置紧凑数组的单个元素，不再调用整个紧凑数组属性的 setter |
| GUI | `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` 重命名 | 现为 `UPDATE_WIDTH_UNIT`。**GDScript 失效** |
| GUI | `RichTextLabel.add_image()` / `update_image()` | `width` / `height` 为 `float`（原为 `int`）；`width_in_percent` / `height_in_percent` 重命名为 `width_unit` / `height_unit`，类型为 `RichTextLabel.ImageUnit`（原为 `bool`，默认 `false` → `0`）。C# 源码失效 |
| GUI | `Control.accessibility_live` 类型 | 为 `AccessibilityServer.AccessibilityLiveMode`（原为 `DisplayServer.AccessibilityLiveMode`）。C# 失效 |
| 核心 | `Object.is_class()` | 参数为 `StringName`（原为 `String`） |
| 核心 | `OptimizedTranslation.generate()` | 返回 `bool`（原为 `void`）。C# 二进制失效 |
| 输入 | 鼠标和键盘设备 ID | 原为 `0`；现在为 `InputEvent.DEVICE_ID_MOUSE` 和 `InputEvent.DEVICE_ID_KEYBOARD`，因为某些手柄也使用 `0`。请按事件类型识别，或将 `InputEvent.device` 与这些常量比较 |
| 物理 | Jolt：`WorldBoundaryShape3D` 平面符号 | `plane.d` 的符号按 Godot Physics 的读取方式解读，因此与 4.6 相比是翻转的：取负即可保持 4.6 的行为 |
| 物理 | Jolt：`SoftBody3D` 质量与刚度 | 质量默认按整个物体 1 kg（原为每个点 1 kg）；`linear_stiffness` 的应用方式不同。请为每个 `SoftBody3D` 重新调整 `linear_stiffness` 和 `damping_coefficient` |
| 物理 | Jolt：`Area3D` 与 `SoftBody3D` | `Area3D` 现在会报告与 `SoftBody3D` 的重叠；使用碰撞层和掩码来忽略它们 |
| 物理 | `PhysicsServer2D.body_set_shape_as_one_way_collision()` | 增加可选 `direction`；`PhysicsServer2DExtension._body_set_shape_as_one_way_collision()` 则需要它（扩展失效） |
| 音频 | `AudioStreamPlayer2D` / `AudioStreamPlayer3D` 的 `area_mask` 默认值 | 从层 `1` 改为 `0`（禁用）。依赖默认掩码的 `Area2D`/`Area3D` `audio_bus_override` 会停止工作，直到将掩码重新设为层 `1` |
| 音频 | `AudioEffectSpectrumAnalyzer.tap_back_pos` | 已移除。在用到它的地方 **GDScript 失效** |
| 渲染 | `CanvasItem` 线条绘制 | 不再添加抗锯齿羽化，因此线条看起来更细；请加宽那些依赖旧粗细的线条 |
| 渲染 | `LinearToSRGB` 视觉着色器节点 | 在 Forward+ 和 Mobile 下不再钳制到 `[0.0, 1.0]` |
| 渲染 | `get_format()` 迁移 | 从 `ImageTexture` / `PortableCompressedTexture2D` 移至基类 `Texture2D` |
| 渲染 | `RenderingServer.particles_request_process_time()` | `time` 重命名为 `process_time`；增加可选 `process_time_residual`（四个粒子节点的 `request_particles_process()` 也同样如此） |
| 渲染 | 天空反射粗糙度层数 | `rendering/reflections/sky_reflections/roughness_layers` 默认 `7` → `8` |
| 动画 | `Animation.length` | 类型元数据为 `double`（原为 `float`）。C# 失效 |
| 动画 | `LookAtModifier3D.relative` | 默认 `false`（原为 `true`） |
| 动画 | `AnimationNodeBlendSpace1D/2D.add_blend_point()` | 增加可选 `name` |
| 项目 | 新项目的拉伸默认值 | `display/window/stretch/mode` 为 `canvas_items`（原为 `disabled`），`display/window/stretch/aspect` 为 `expand`（原为 `keep`）。现有项目保留其设置 |
| 文本 | `ResourceImporterDynamicFont.hinting` | 默认 `3`（原为 `1`） |
| 编辑器 | `EditorSceneFormatImporter` 导入常量 | 移入 `ImportFlags` 枚举（`IMPORT_SCENE`、`IMPORT_ANIMATION`、…）。C# 源码失效 |
| 编辑器 | `EditorVCSInterface._commit()` | 新增 `amend` 参数；VCS 插件失效 |
| 编辑器 | Asset Library 被 Asset Store 取代 | 编辑器工作区现在为 "Asset Store"（发行说明：https://godotengine.org/releases/4.7/） |
| XR | `OpenXRExtensionWrapper._on_register_metadata()` | 新增 `interaction_profile_metadata` 参数；扩展失效 |

## 4.5 → 4.6 (Jan 2026 — POST-CUTOFF, HIGH RISK)
## 4.5 → 4.6（2026 年 1 月 — 截止后，高风险）

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

| 子系统 | 变更 | 详情 |
|-----------|--------|---------|
| 物理 | Jolt 现在是默认的 3D 物理引擎 | 新项目自动使用 Jolt。现有项目保留其设置。某些 HingeJoint3D 属性（如 `damp`）仅适用于 GodotPhysics。 |
| 渲染 | glow 在色调映射之前处理 | 原本在色调映射之后。带 glow 的场景外观会不同。请在 WorldEnvironment 中调整强度/混合。 |
| 渲染 | Windows 上 D3D12 设为默认 | 原为 Vulkan。旨在获得更好的驱动兼容性。 |
| 渲染 | AgX 色调映射器新增控件 | 增加了白点和对比度参数。 |
| 核心 | Quaternion 初始化为单位值 | 原为零。不太可能影响大多数代码，但技术上属于破坏性变更。 |
| UI | 双焦点系统 | 鼠标/触摸焦点现在与键盘/手柄焦点分离。视觉反馈因输入方式而异。 |
| 动画 | IK 系统完全恢复 | 通过 SkeletonModifier3D 节点提供 CCDIK、FABRIK、Jacobian IK、Spline IK、TwoBoneIK。 |
| 编辑器 | 新的 "Modern" 主题设为默认 | 灰度取代蓝色调。恢复方法：Editor Settings → Interface → Theme → Style: Classic |
| 编辑器 | "Select Mode" 快捷键变更 | 新的 "Select Mode"（v 键）可防止意外变换。旧模式更名为 "Transform Mode"（q 键）。 |
| 2D | TileMapLayer 场景瓦片旋转 | 场景瓦片现在可以像图集瓦片一样旋转。 |
| 本地化 | CSV 复数形式支持 | 不再需要 Gettext 来处理复数。增加了上下文列。 |
| C# | 自动字符串提取 | 翻译字符串会自动从 C# 代码中提取。 |
| 插件 | 新增 EditorDock 类 | 用于插件停靠面板的专用容器，带有布局控制功能。 |

## 4.4 → 4.5 (Sep 2025 — POST-CUTOFF, HIGH RISK)
## 4.4 → 4.5（2025 年 9 月 — 截止后，高风险）

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

| 子系统 | 变更 | 详情 |
|-----------|--------|---------|
| GDScript | 增加可变参数 | 函数可接受 `...` 任意参数 — 新的语言特性 |
| GDScript | `@abstract` 装饰器 | 抽象类和方法现在可强制执行 |
| GDScript | 脚本回溯 | 即使在 Release 构建中也可获得详细的调用栈 |
| 渲染 | 模板缓冲区支持 | 用于高级视觉效果的新功能 |
| 渲染 | SMAA 1x 抗锯齿 | 新的后处理抗锯齿选项 |
| 渲染 | 着色器烘焙器 | 预编译着色器 — 据称在某些示例中启动速度提升 20 倍 |
| 渲染 | 弯曲法线贴图、镜面反射遮蔽 | 新的材质特性 |
| 无障碍 | 屏幕阅读器支持 | Control 节点通过 AccessKit 与无障碍工具协同工作 |
| 编辑器 | 实时翻译预览 | 在编辑器中测试不同语言的 GUI 布局 |
| 物理 | 3D 插值重构 | 从 RenderingServer 移至 SceneTree。API 未变但内部实现不同。 |
| 动画 | BoneConstraint3D | 新增：AimModifier3D、CopyTransformModifier3D、ConvertTransformModifier3D |
| 资源 | 新增 `duplicate_deep()` | 用于嵌套资源深度复制的新显式方法 |
| 导航 | 专用 2D 导航服务器 | 不再是 3D 导航的代理；2D 游戏的导出体积更小 |
| UI | FoldableContainer 节点 | 用于可折叠 UI 区段的新手风琴式容器 |
| UI | 递归 Control 行为 | 可禁用整个节点层级的鼠标/焦点交互 |
| 平台 | visionOS 导出支持 | 新的平台目标 |
| 平台 | SDL3 手柄驱动 | 将手柄处理委托给 SDL 库 |
| 平台 | Android 16KB 页支持 | 面向 Android 15+ 的 Google Play 发布所需 |

## 4.3 → 4.4 (Mar 2025 — BEFORE CUTOFF, VERIFY)
## 4.3 → 4.4（2025 年 3 月 — 截止前，需核实）

| Subsystem | Change | Details |
|-----------|--------|---------|
| Core | `FileAccess.store_*` return `bool` | Was `void`. Methods: `store_8`, `store_16`, `store_32`, `store_64`, `store_buffer`, `store_csv_line`, `store_double`, `store_float`, `store_half`, `store_line`, `store_pascal_string`, `store_real`, `store_string`, `store_var` |
| Core | `OS.execute_with_pipe` | Added optional `blocking` parameter |
| Core | `RegEx.compile/create_from_string` | Added optional `show_error` parameter |
| Rendering | `RenderingDevice.draw_list_begin` | Many parameters removed; `breadcrumb` parameter added |
| Rendering | `Shader.set_default_texture_parameter()` / `get_default_texture_parameter()` | Parameter/return type changed from `Texture2D` to `Texture`; the shading language did not change |
| Particles | `.restart()` method | Added optional `keep_seed` parameter (CPU/GPU 2D/3D) |
| GUI | `RichTextLabel.push_meta` | Added optional `tooltip` parameter |
| GUI | `GraphEdit.connect_node` | Added optional `keep_alive` parameter |

| 子系统 | 变更 | 详情 |
|-----------|--------|---------|
| 核心 | `FileAccess.store_*` 返回 `bool` | 原为 `void`。方法包括：`store_8`、`store_16`、`store_32`、`store_64`、`store_buffer`、`store_csv_line`、`store_double`、`store_float`、`store_half`、`store_line`、`store_pascal_string`、`store_real`、`store_string`、`store_var` |
| 核心 | `OS.execute_with_pipe` | 增加可选 `blocking` 参数 |
| 核心 | `RegEx.compile/create_from_string` | 增加可选 `show_error` 参数 |
| 渲染 | `RenderingDevice.draw_list_begin` | 移除了许多参数；增加了 `breadcrumb` 参数 |
| 渲染 | `Shader.set_default_texture_parameter()` / `get_default_texture_parameter()` | 参数/返回类型从 `Texture2D` 改为 `Texture`；着色语言未变 |
| 粒子 | `.restart()` 方法 | 增加可选 `keep_seed` 参数（CPU/GPU 2D/3D） |
| GUI | `RichTextLabel.push_meta` | 增加可选 `tooltip` 参数 |
| GUI | `GraphEdit.connect_node` | 增加可选 `keep_alive` 参数 |

## 4.2 → 4.3 (In Training Data — LOW RISK)
## 4.2 → 4.3（在训练数据中 — 低风险）

| Subsystem | Change | Details |
|-----------|--------|---------|
| Animation | `Skeleton3D.add_bone` returns `int32` | Was `void` |
| Animation | `bone_pose_updated` signal | Replaced by `skeleton_updated` |
| TileMap | `TileMapLayer` replaces `TileMap` | One node per layer instead of multi-layer single node |
| Navigation | `NavigationRegion2D` | Removed `avoidance_layers`, `constrain_avoidance` properties |
| Editor | `EditorSceneFormatImporterFBX` | Renamed to `EditorSceneFormatImporterFBX2GLTF` |
| Animation | AnimationMixer base class | AnimationPlayer and AnimationTree now extend AnimationMixer |

| 子系统 | 变更 | 详情 |
|-----------|--------|---------|
| 动画 | `Skeleton3D.add_bone` 返回 `int32` | 原为 `void` |
| 动画 | `bone_pose_updated` 信号 | 被 `skeleton_updated` 取代 |
| TileMap | `TileMapLayer` 取代 `TileMap` | 每层一个节点，而非多层单节点 |
| 导航 | `NavigationRegion2D` | 移除了 `avoidance_layers`、`constrain_avoidance` 属性 |
| 编辑器 | `EditorSceneFormatImporterFBX` | 重命名为 `EditorSceneFormatImporterFBX2GLTF` |
| 动画 | AnimationMixer 基类 | AnimationPlayer 和 AnimationTree 现在继承自 AnimationMixer |

## Sources
## 来源

- Official docs: https://docs.godotengine.org/en/stable/
- 官方文档：https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.6→4.7 迁移：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.5→4.6 迁移：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- 4.4→4.5 迁移：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- 更新日志：https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- Release notes: https://godotengine.org/releases/4.7/ (4.6: https://godotengine.org/releases/4.6/)
- 发行说明：https://godotengine.org/releases/4.7/（4.6：https://godotengine.org/releases/4.6/）
- Releases and dates: https://github.com/godotengine/godot/releases
- 版本发布与日期：https://github.com/godotengine/godot/releases
