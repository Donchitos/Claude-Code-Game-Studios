# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7.1 |
| **Release Date** | July 14, 2026 (4.7 feature: June 18, 2026) |
| **Project Pinned** | 2026-08-14 |
| **Last Docs Verified** | 2026-08-14 |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | HIGH — version is well beyond LLM training data |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4, 4.5,
4.6, and 4.7 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Godot API calls.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | Jun 2026 | HIGH | AreaLight3D, DrawableTexture2D, 内置 VirtualJoystick 节点, Android GABE 导出, Control 偏移变换, AnimatedSprite2D ping-pong, 移动端 SDL3/HDR |

## Verified Sources

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration: https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.5→4.6 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html
- 4.4→4.5 migration: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html
- Changelog: https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- 4.7 release notes: https://godotengine.org/releases/4.7/

## Migration Notes — 4.6 → 4.7.1

### 4.7 (2026-06-18, feature release)

对本项目（GDScript, 2D 俯视角割草, 移动端）相关的变更：

**对本项目重要的新能力：**
- 内置 `VirtualJoystick` 节点（Fixed / Dynamic / Following 三模式）——本项目"虚拟摇杆移动"可直接用内置节点，无需自造或第三方插件
- `DrawableTexture2D`——简化在纹理上绘制的 API，替代 Viewport hack（可用于技能范围预警贴图等）
- Android 独立导出/发布（GABE，Godot Android Build Environment）——改善移动端构建链
- `CollisionShape2D` 新增 `one_way_collision_direction` 属性——单向碰撞方向可自定义（不再假定局部向上）
- iOS SDL3 手柄驱动 + 陀螺仪瞄准输入
- 移动端 HDR 输出（Windows/macOS/iOS/visionOS/Linux Wayland）

**对本项目重要的破坏性变更（会影响代码）：**
- `Animation.length` 类型元数据 `float` → `double`（源码级破坏，GDScript 项目需重测动画时长逻辑）
- `AnimationNodeBlendSpace1D/2D` 的 `sync` 布尔属性 → 新 `SyncMode` 枚举——升级后动画过渡可能不正确，需手动设置 `sync_mode`
- `CanvasItem` 画线不再加抗锯齿羽化——线会变细，若依赖需手动加粗线宽
- `AudioStreamPlayer.area_mask` 默认值 `1` → `0`（禁用）——若用 `Area2D` 的 `audio_bus_override` 且依赖默认 mask，需重置为 layer 1
- 鼠标/键盘 device ID：从 `0` 改为 `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`——若代码用 `device == 0` 判断鼠标键盘会失效
- GDScript：覆盖带类型返回的父类方法现在继承返回类型，必须显式 `return`（否则报错，需加 `return null`）
- GDScript：设置 packed array 元素不再触发整个 packed array 属性的 setter
- 新项目默认 stretch mode `disabled` → `canvas_items`，stretch aspect `keep` → `expand`（仅新项目）

**对本项目基本无关的变更（3D/XR/编辑器为主）：**
- Jolt Physics 3D 的 `WorldBoundaryShape3D.plane.d` 符号反转、`SoftBody3D` 质量默认值与刚度行为变化——本项目 2D 不用 Jolt 3D
- `OpenXRExtensionWrapper` 等 XR 接口破坏性变更——本项目无 XR
- 3D 编辑器/CSG/GridMap/Skeleton3D 编辑器大量改进——不影响运行时
- `EditorSceneFormatImporter` 常量移入 `ImportFlags` 枚举——编辑器扩展专用

### 4.7.1 (2026-07-14, maintenance release)

维护版，主要修复。对本项目相关的修复：
- 修复 `Polygon2D` 编辑顶点后用陈旧 AABB 剔除的问题
- 修复 Android 软键盘退格键无法删除已有文本
- 修复触屏上场景树拖放回归
- 修复 Android `GodotActivity.updatePiPParams` 崩溃
- 修复 Android EditorSettings 未实例化导致游戏运行报错
- 修复触屏上 Tree 节点鼠标拖拽回归

完整修复列表见 https://github.com/godotengine/godot/releases/tag/4.7.1-stable
