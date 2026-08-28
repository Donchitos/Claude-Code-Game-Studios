# Godot — Current Best Practices

Last verified: 2026-08-14 | Engine: Godot 4.7.1

Practices that are **new or changed** since the model's training data (~4.3).
This supplements (not replaces) the agent's built-in knowledge.

## 2D / 移动端 (4.7) — 本项目重点

- **内置 `VirtualJoystick` 节点**：Fixed / Dynamic / Following 三模式。本项目"虚拟摇杆移动"直接用此节点，无需自造或第三方插件。
- **`DrawableTexture2D`**：简化在纹理上绘制的 API，替代基于 Viewport 的 hack。可用于技能范围预警贴图、动态伤害数字纹理等。
- **`CollisionShape2D.one_way_collision_direction`**：单向碰撞方向可自定义（不再假定局部向上）。用于平台跳跃类单向平台。
- **`GradientTexture2D` 新增 `FILL_CONIC`**：锥形渐变，可用于自定义 2D 着色器的真实感着色。
- **`TextureRect` 支持 `AtlasTexture` tiling**：可将 AtlasTexture 的一部分作为九宫格重复纹理绘制。
- **`AnimatedSprite2D` ping-pong 播放**：`SpriteFrames` / `AnimatedSprite2D` / `AnimatedSprite3D` 新增来回播放支持（GH-114556）。
- **Android 独立导出（GABE）**：Godot Android Build Environment，改善移动端构建/发布链。自定义启动画面不再需要手动装 Gradle 文件，可在导出选项编辑。
- **Android PiP（画中画）**：支持在小窗口渲染游戏。
- **iOS SDL3 手柄驱动 + 陀螺仪瞄准**：加速计/陀螺仪输入可读。
- **移动端 HDR 输出**：iOS 等。
- **新项目默认 stretch**：mode `canvas_items`、aspect `expand`（仅新项目，适配竖屏多分辨率有用）。

## GDScript (4.7)

- **`Tween.tween_await()`**：暂停 tween 直到特定信号触发——适合对话/演出。
- **覆盖带类型返回的父类方法**：现在继承返回类型，必须显式 `return`（否则报错，加 `return null` 修复）。
- **packed array 元素 setter**：设置 packed array 元素不再触发整个 packed array 属性的 setter——若依赖 setter 副作用需改逻辑。

## Input (4.7)

- **鼠标/键盘 device ID**：用 `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` 判断，不要用 `device == 0`（某些手柄可能用 0 作 ID）。
- **"失焦忽略手柄"新项目设置**：默认关，可开启让窗口失焦时不接收手柄输入。
- **键盘/鼠标带设备 ID**：为未来多设备区分铺路。

## Audio (4.7)

- **`AudioStreamPlayer.area_mask` 默认 `0`（禁用）**：若用 `Area2D` 的 `audio_bus_override` 且依赖默认 mask，需手动重置为 layer 1。

## Rendering (4.7)

- **`CanvasItem` 画线不加抗锯齿羽化**：线变细，需手动加粗线宽。
- **`LinearToSRGB` 视觉着色器**：不再 clamp 到 `[0,1]`（Mobile / Forward+）。
- **`AreaLight3D`**：新矩形光源节点（3D，软阴影）。
- **Control 偏移变换**：Control 节点可平移/旋转/缩放而不影响容器布局（类似 CSS `transform`）。

## GDScript (4.5+)


## GDScript (4.5+)

- **Variadic arguments**: Functions can accept arbitrary parameter counts
  ```gdscript
  func log_values(prefix: String, values: Variant...) -> void:
      for v in values:
          print(prefix, ": ", v)
  ```

- **Abstract classes and methods**: Use `@abstract` to enforce inheritance
  ```gdscript
  @abstract
  class_name BaseEnemy extends CharacterBody3D

  @abstract
  func get_attack_pattern() -> Array[Attack]:
      pass  # Subclasses MUST override
  ```

- **Script backtracing**: Detailed call stacks available even in Release builds

## Physics (4.6)

- **Jolt Physics is the default 3D engine** for new projects
  - Better determinism and stability than GodotPhysics3D
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics
  - Switch: Project Settings → Physics → 3D → Physics Engine
  - 2D physics unchanged (still Godot Physics 2D)

## Rendering (4.6)

- **D3D12 is the default backend on Windows** (was Vulkan) — for better driver compatibility
- **Glow now processes before tonemapping** with screen blending mode — existing glow setups may look different
- **SSR overhauled** — significant improvement in realism, stability, and performance
- **AgX tonemapper** — new white point and contrast controls

## Rendering (4.5)

- **Shader Baker**: Pre-compile shaders to eliminate startup hitching
- **SMAA 1x**: New AA option — sharper than FXAA, cheaper than TAA
- **Stencil buffer**: Available for advanced masking/portal effects
- **Bent normal maps**: Directional occlusion in normal map textures
- **Specular occlusion**: Ambient occlusion now affects reflections

## Accessibility (4.5+)

- **Screen reader support**: Control nodes integrate with accessibility tools via AccessKit
- **Live translation preview**: Test GUI layouts in different languages directly in-editor
- **FoldableContainer**: New accordion-style UI node for collapsible sections
- **Recursive Control disable**: Disable mouse/focus interactions for entire node hierarchies with a single property

## Animation (4.5+)

- **BoneConstraint3D**: Bind bones to other bones with modifiers
  - AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D

## Animation (4.6)

- **IK system fully restored**: Complete inverse kinematics reintroduced for 3D
  - Available modifiers: CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK
  - Applied via `SkeletonModifier3D` nodes

## Resources (4.5+)

- **`duplicate_deep()`**: Explicit deep duplication for nested resource trees
  - Old `duplicate()` behavior retained for backward compatibility
  - Use `duplicate_deep()` when you need per-instance copies of nested resources

## Navigation (4.5+)

- **Dedicated 2D navigation server**: No longer proxied through 3D NavigationServer
  - Reduces export binary size for 2D-only games

## UI (4.6)

- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
  - Visual feedback differs depending on input method
  - Consider this when designing custom focus behavior

## Editor Workflow (4.6)

- Flexible dock drag-and-drop with blue outline preview (including bottom panel)
- Most panels support floating windows (except Debugger)
- New keyboard shortcuts: Alt+O (Output), Alt+S (Shader)
- Export variable auto-generation: drag resource from FileSystem into script editor
- Live preview in Quick Open dialog when "Live Preview" enabled
- New "Select Mode" (v key) prevents accidental transforms; old mode renamed "Transform Mode" (q key)

## Tooling

- **ripgrep has no `gdscript` type**: `*.gd` is registered under `gap` (GAP programming language).
  `rg --type gdscript` is a hard error — the search never executes.
  Always use `rg --glob "*.gd"` (shell) or `glob: "*.gd"` (Grep tool) to filter GDScript files.

## Platform (4.5+)

- **visionOS export**: First new platform since open-sourcing (windowed app mode)
- **SDL3 gamepad driver**: Better cross-platform gamepad support
- **Android**: Edge-to-edge display, camera feed access, 16KB page support (Android 15+)
- **Linux**: Wayland subwindow support for multi-window capability
