# Godot — Current Best Practices
# Godot — 当前最佳实践

Last verified: 2026-10-17 (4.7 sections); 2026-02-12 (rest) | Engine: Godot 4.7
最后验证：2026-10-17（4.7 各节）；2026-02-12（其余部分） | 引擎：Godot 4.7

Practices that are **new or changed** since the model's training data (~4.3).
This supplements (not replaces) the agent's built-in knowledge.
自模型训练数据（约 4.3）以来**新增或变更**的实践。本文件是对智能体内置知识的补充（而非替代）。

## GDScript (4.5+)
## GDScript（4.5+）

- **Variadic arguments**: Functions can accept arbitrary parameter counts. The
  rest parameter is written `...name`, comes last, and is typed `Array` or left
  untyped — `values: Variant...` and `...values: Array[int]` do not parse
- **可变参数**：函数可以接受任意数量的参数。其余参数写作 `...name`，放在最后，类型为 `Array` 或保持无类型 — `values: Variant...` 和 `...values: Array[int]` 都无法解析
  ```gdscript
  func log_values(prefix: String, ...values: Array) -> void:
      for v in values:
          print(prefix, ": ", v)
  ```

- **Lambdas capture local variables by value** (every Godot 4 version): a local
  is captured once, when the lambda is created, and a lambda cannot reassign an
  outer local — `var hit := false` / `func(): hit = true` leaves the caller's
  `hit` false. Share state through a reference type (a Dictionary, an Array or
  an object) and mutate its contents. A rest parameter works in a lambda too, so
  `func(...args)` connects to a signal with any number of arguments (observed on
  4.6.1; a one-argument lambda on a zero-argument signal errors "Method expected
  1 argument(s), but called with 0")
- **Lambda 按值捕获局部变量**（所有 Godot 4 版本）：局部变量只在 lambda 创建时被捕获一次，且 lambda 不能重新赋值外层局部变量 — `var hit := false` / `func(): hit = true` 会使调用方的 `hit` 仍为 false。请通过引用类型（Dictionary、Array 或对象）共享状态，并修改其内容。lambda 中也可以使用其余参数，因此 `func(...args)` 可连接到任意数量参数的信号（在 4.6.1 上观察到；在零参数信号上使用单参数 lambda 会报错 "Method expected 1 argument(s), but called with 0"）
  ```gdscript
  var state := {"emitted": false}
  some_signal.connect(func(...args): state.emitted = true)
  ```

- **Abstract classes and methods**: Use `@abstract` to enforce inheritance
- **抽象类和方法**：使用 `@abstract` 强制继承
  ```gdscript
  @abstract
  class_name BaseEnemy extends CharacterBody3D

  # No body: "a newline or a semicolon is expected after the function header".
  # Subclasses MUST override it.
  @abstract func get_attack_pattern() -> Array[Attack]
  ```

- **Script backtracing**: Detailed call stacks available even in Release builds
- **脚本回溯**：即使在 Release 构建中也可获得详细的调用栈

## GDScript (4.7)
## GDScript（4.7）

- **An override of a typed method inherits its return type**, so it needs an
  explicit `return` statement; the migration guide's fix is `return null`
- **对类型化方法的覆写会继承其返回类型**，因此需要显式的 `return` 语句；迁移指南给出的修复方式是 `return null`
- **Writing one element of a packed array no longer calls the property's
  setter.** A setter on a `PackedInt32Array` (etc.) property no longer runs on
  `arr[i] = v`; assign the whole array where the setter has to run
- **写入紧凑数组的单个元素不再调用该属性的 setter。** `PackedInt32Array`（等）属性上的 setter 不再因 `arr[i] = v` 而运行；在必须运行 setter 的地方，请整体赋值该数组

## Physics (4.7)
## 物理（4.7）

- **Jolt `WorldBoundaryShape3D`**: the sign of `plane.d` now matches Godot
  Physics, flipped from 4.6. Negate it in scenes authored on 4.6
- **Jolt `WorldBoundaryShape3D`**：`plane.d` 的符号现在与 Godot Physics 一致，且与 4.6 相比是翻转的。在 4.6 上制作的场景中请对其取负
- **Jolt `SoftBody3D`**: mass is 1 kg for the whole body (was 1 kg per point)
  and `linear_stiffness` is applied differently; re-tune `linear_stiffness`
  and `damping_coefficient`. `Area3D` now reports `SoftBody3D` overlaps
- **Jolt `SoftBody3D`**：质量按整个物体 1 kg（原为每个点 1 kg），且 `linear_stiffness` 的应用方式不同；请重新调整 `linear_stiffness` 和 `damping_coefficient`。`Area3D` 现在会报告 `SoftBody3D` 的重叠
- **Audio areas**: `area_mask` on `AudioStreamPlayer2D`/`3D` defaults to `0`
  (was layer `1`); set it to layer `1` where `audio_bus_override` areas are used
- **音频区域**：`AudioStreamPlayer2D`/`3D` 上的 `area_mask` 默认值为 `0`（原为层 `1`）；在使用 `audio_bus_override` 区域的地方，请将其设为层 `1`

## Physics (4.6)
## 物理（4.6）

- **Jolt Physics is the default 3D engine** for new projects
- **Jolt Physics 是新项目的默认 3D 引擎**
  - Better determinism and stability than GodotPhysics3D
  - 比 GodotPhysics3D 具有更好的确定性和稳定性
  - Some HingeJoint3D properties (`damp`) only work with GodotPhysics
  - 某些 HingeJoint3D 属性（`damp`）仅适用于 GodotPhysics
  - Switch: Project Settings → Physics → 3D → Physics Engine
  - 切换方式：Project Settings → Physics → 3D → Physics Engine
  - 2D physics unchanged (still Godot Physics 2D)
  - 2D 物理未变（仍为 Godot Physics 2D）

## Rendering (4.7)
## 渲染（4.7）

- **`AreaLight3D`**: real-time rectangular area lights, instead of an emissive
  material plus global illumination
- **`AreaLight3D`**：实时矩形区域光，可替代自发光材质加全局光照的方案
- **HDR output** on Windows, macOS, iOS, visionOS and Linux (Wayland)
- **HDR 输出**：支持 Windows、macOS、iOS、visionOS 和 Linux（Wayland）
- **`DrawableTexture2D`**: a simpler API for drawing onto textures
- **`DrawableTexture2D`**：一个更简单的、在纹理上绘制的 API
- **`CanvasItem` lines are drawn without an antialiasing feather**, so they look
  thinner than in 4.6; widen lines that relied on the old look
- **`CanvasItem` 线条绘制时不使用抗锯齿羽化**，因此看起来比 4.6 中更细；请加宽那些依赖旧外观的线条
- The `LinearToSRGB` visual shader node no longer clamps to `[0.0, 1.0]` under
  Forward+ and Mobile
- `LinearToSRGB` 视觉着色器节点在 Forward+ 和 Mobile 下不再钳制到 `[0.0, 1.0]`

## Rendering (4.6)
## 渲染（4.6）

- **D3D12 is the default backend on Windows** (was Vulkan) — for better driver compatibility
- **Windows 上 D3D12 是默认后端**（原为 Vulkan）— 以获得更好的驱动兼容性
- **Glow now processes before tonemapping** with screen blending mode — existing glow setups may look different
- **glow 现在在色调映射之前处理**，使用屏幕混合模式 — 现有的 glow 设置外观可能不同
- **SSR overhauled** — significant improvement in realism, stability, and performance
- **SSR 已重构** — 在真实感、稳定性和性能方面均有显著提升
- **AgX tonemapper** — new white point and contrast controls
- **AgX 色调映射器** — 新增白点和对比度控件

## Rendering (4.5)
## 渲染（4.5）

- **Shader Baker**: Pre-compile shaders to eliminate startup hitching
- **着色器烘焙器**：预编译着色器，以消除启动时的卡顿
- **SMAA 1x**: New AA option — sharper than FXAA, cheaper than TAA
- **SMAA 1x**：新的抗锯齿选项 — 比 FXAA 更锐利，比 TAA 开销更低
- **Stencil buffer**: Available for advanced masking/portal effects
- **模板缓冲区**：可用于高级遮罩/传送门效果
- **Bent normal maps**: Directional occlusion in normal map textures
- **弯曲法线贴图**：在法线贴图纹理中编码方向性遮蔽
- **Specular occlusion**: Ambient occlusion now affects reflections
- **镜面反射遮蔽**：环境光遮蔽现在会影响反射

## Accessibility (4.5+)
## 无障碍（4.5+）

- **Screen reader support**: Control nodes integrate with accessibility tools via AccessKit
- **屏幕阅读器支持**：Control 节点通过 AccessKit 与无障碍工具集成
- **Live translation preview**: Test GUI layouts in different languages directly in-editor
- **实时翻译预览**：直接在编辑器中测试不同语言的 GUI 布局
- **FoldableContainer**: New accordion-style UI node for collapsible sections
- **FoldableContainer**：用于可折叠区段的新手风琴式 UI 节点
- **Recursive Control disable**: Disable mouse/focus interactions for entire node hierarchies with a single property
- **递归禁用 Control**：通过单个属性禁用整个节点层级的鼠标/焦点交互

## Animation (4.5+)
## 动画（4.5+）

- **BoneConstraint3D**: Bind bones to other bones with modifiers
- **BoneConstraint3D**：使用修饰器将骨骼绑定到其他骨骼
  - AimModifier3D, CopyTransformModifier3D, ConvertTransformModifier3D
  - AimModifier3D、CopyTransformModifier3D、ConvertTransformModifier3D

## Animation (4.7)
## 动画（4.7）

- **`Tween.tween_await()`** pauses a tween until a signal is emitted
- **`Tween.tween_await()`** 会暂停补间，直到发出某个信号
- **`LookAtModifier3D.relative`** defaults to `false` (was `true`)
- **`LookAtModifier3D.relative`** 默认值为 `false`（原为 `true`）

## Animation (4.6)
## 动画（4.6）

- **IK system fully restored**: Complete inverse kinematics reintroduced for 3D
- **IK 系统完全恢复**：为 3D 重新引入完整的逆向运动学
  - Available modifiers: CCDIK, FABRIK, Jacobian IK, Spline IK, TwoBoneIK
  - 可用的修饰器：CCDIK、FABRIK、Jacobian IK、Spline IK、TwoBoneIK
  - Applied via `SkeletonModifier3D` nodes
  - 通过 `SkeletonModifier3D` 节点应用

## Resources (4.5+)
## 资源（4.5+）

- **`duplicate_deep()`**: Explicit deep duplication for nested resource trees
- **`duplicate_deep()`**：用于嵌套资源树的显式深复制
  - Old `duplicate()` behavior retained for backward compatibility
  - 为向后兼容保留了旧的 `duplicate()` 行为
  - Use `duplicate_deep()` when you need per-instance copies of nested resources
  - 当你需要嵌套资源的按实例副本时，请使用 `duplicate_deep()`

## Navigation (4.5+)
## 导航（4.5+）

- **Dedicated 2D navigation server**: No longer proxied through 3D NavigationServer
- **专用 2D 导航服务器**：不再通过 3D NavigationServer 代理
  - Reduces export binary size for 2D-only games
  - 减小纯 2D 游戏的导出二进制体积

## UI (4.6)
## UI（4.6）

- **Dual-focus system**: Mouse/touch focus is now separate from keyboard/gamepad focus
- **双焦点系统**：鼠标/触摸焦点现在与键盘/手柄焦点分离
  - Visual feedback differs depending on input method
  - 视觉反馈因输入方式而异
  - Consider this when designing custom focus behavior
  - 在设计自定义焦点行为时请考虑这一点

## UI and Input (4.7)
## UI 与输入（4.7）

- **`Control.offset_transform_*`** (`offset_transform_enabled`,
  `offset_transform_position`, `offset_transform_rotation`,
  `offset_transform_scale`, …): a visual transform that containers do not
  reset, for hover and press animations inside containers
- **`Control.offset_transform_*`**（`offset_transform_enabled`、`offset_transform_position`、`offset_transform_rotation`、`offset_transform_scale`……）：一种容器不会重置的视觉变换，用于容器内部的悬停和按下动画
- **`RichTextLabel` images can size relative to the font**
  (`[img height=1em]…[/img]`); `add_image()` / `update_image()` take
  `width_unit` / `height_unit` (`RichTextLabel.ImageUnit`) in place of the
  `*_in_percent` booleans
- **`RichTextLabel` 图像可以相对于字体设置尺寸**（`[img height=1em]…[/img]`）；`add_image()` / `update_image()` 使用 `width_unit` / `height_unit`（`RichTextLabel.ImageUnit`）取代了 `*_in_percent` 布尔值
- **`VirtualJoystick` node** for touch controls, with Fixed, Dynamic and
  Following modes
- **`VirtualJoystick` 节点**用于触摸控制，具有 Fixed、Dynamic 和 Following 模式
- **Mouse and keyboard events report `InputEvent.DEVICE_ID_MOUSE` /
  `DEVICE_ID_KEYBOARD`**, not device `0`; check the event type rather than
  `device == 0`
- **鼠标和键盘事件报告 `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`**，而非设备 `0`；请检查事件类型，而不是 `device == 0`
- **New projects stretch by default**: `display/window/stretch/mode` is
  `canvas_items` and `aspect` is `expand`. Projects created before 4.7 keep
  their settings
- **新项目默认拉伸**：`display/window/stretch/mode` 为 `canvas_items`，`aspect` 为 `expand`。在 4.7 之前创建的项目保留其设置

## Editor Workflow (4.7)
## 编辑器工作流（4.7）

- **The Asset Store replaces the Asset Library**: the editor workspace is
  "Asset Store" (it was "AssetLib"), and addons such as gdUnit4 are installed
  from there
- **Asset Store 取代 Asset Library**：编辑器工作区为 "Asset Store"（原为 "AssetLib"），gdUnit4 等插件即从该处安装
- Method, signal and property names show in a monospace font by default
  ("Use Monospace Font for Editor Symbols" turns it off)
- 方法、信号和属性名称默认以等宽字体显示（"Use Monospace Font for Editor Symbols" 可将其关闭）

## Editor Workflow (4.6)
## 编辑器工作流（4.6）

- Flexible dock drag-and-drop with blue outline preview (including bottom panel)
- 灵活的停靠面板拖放，带蓝色轮廓预览（包括底部面板）
- Most panels support floating windows (except Debugger)
- 大多数面板支持浮动窗口（Debugger 除外）
- New keyboard shortcuts: Alt+O (Output), Alt+S (Shader)
- 新增键盘快捷键：Alt+O（Output）、Alt+S（Shader）
- Export variable auto-generation: drag resource from FileSystem into script editor
- 导出变量自动生成：将资源从 FileSystem 拖入脚本编辑器
- Live preview in Quick Open dialog when "Live Preview" enabled
- 启用 "Live Preview" 时，Quick Open 对话框中有实时预览
- New "Select Mode" (v key) prevents accidental transforms; old mode renamed "Transform Mode" (q key)
- 新的 "Select Mode"（v 键）可防止意外变换；旧模式更名为 "Transform Mode"（q 键）

## Tooling
## 工具

- **ripgrep has no `gdscript` type**: `*.gd` is registered under `gap` (GAP programming language).
  `rg --type gdscript` is a hard error — the search never executes.
  Always use `rg --glob "*.gd"` (shell) or `glob: "*.gd"` (Grep tool) to filter GDScript files.
- **ripgrep 没有 `gdscript` 类型**：`*.gd` 注册在 `gap`（GAP 编程语言）之下。`rg --type gdscript` 是硬错误 — 搜索永远不会执行。筛选 GDScript 文件时，请始终使用 `rg --glob "*.gd"`（shell）或 `glob: "*.gd"`（Grep 工具）。

## Command Line — Tests and Parse Check
## 命令行 — 测试与解析检查

Flags, from Godot's command-line tutorial: `--headless` (headless display and a
dummy audio driver, "useful for servers and with `--script`"), `--path <dir>`
(a directory holding `project.godot`), `-s`/`--script <script>`, `-d`/`--debug`
(the local stdout debugger), `--remote-debug <protocol>://<host>[:<port>]`,
`--import` (starts the editor, waits for the import, and quits),
`--quit-after <n>` (iterations), `--export-debug <preset>` (implies `--import`)
and `--check-only` (parse for errors and quit, with `--script`). The editor is
not on `PATH` by default: on Windows and Linux run the binary by its relative or
absolute path; on macOS run `Godot.app/Contents/MacOS/Godot` inside the bundle.
以下标志来自 Godot 命令行教程：`--headless`（无头显示和虚拟音频驱动，"对服务器以及配合 `--script` 很有用"）、`--path <dir>`（包含 `project.godot` 的目录）、`-s`/`--script <script>`、`-d`/`--debug`（本地 stdout 调试器）、`--remote-debug <protocol>://<host>[:<port>]`、`--import`（启动编辑器，等待导入完成后退出）、`--quit-after <n>`（迭代次数）、`--export-debug <preset>`（隐含 `--import`）以及 `--check-only`（解析检查错误后退出，需配合 `--script`）。编辑器默认不在 `PATH` 中：在 Windows 和 Linux 上，以相对或绝对路径运行该二进制文件；在 macOS 上，运行包内的 `Godot.app/Contents/MacOS/Godot`。

gdUnit4's runner is `res://addons/gdUnit4/bin/GdUnitCmdTool.gd`; `-a <dir|suite>`
adds suites, reports go to `res://reports/` by default (`-rd` changes it), and
the documented exit codes are 0 (all passed), 100 (failures) and 101 (warnings).
The command the framework uses:
`godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`.
gdUnit4 的运行器是 `res://addons/gdUnit4/bin/GdUnitCmdTool.gd`；`-a <dir|suite>` 用于添加测试套件，报告默认输出到 `res://reports/`（`-rd` 可更改该路径），文档中记载的退出码为 0（全部通过）、100（失败）和 101（警告）。框架使用的命令为：
`godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode`。

gdUnit4 6.2.x lists Godot 4.5 to 4.7.1 as compatible in its README
(https://github.com/godot-gdunit-labs/gdUnit4#compatibility-overview, checked
2026-10-17); 4.7.2 is not listed there yet, but gdUnit4 6.2.2 runs on it. On
Windows, 2026-10-17, Godot 4.7.2 and 4.7.1 gave the same exits on the command
above: 0 pass, 100 fail, 101 orphans, 105 parse error, 0 with `No test cases
found` over none, and 1 before the first import.
gdUnit4 6.2.x 在其 README 中将 Godot 4.5 至 4.7.1 列为兼容（https://github.com/godot-gdunit-labs/gdUnit4#compatibility-overview，核查于 2026-10-17）；4.7.2 尚未列入其中，但 gdUnit4 6.2.2 可在其上运行。在 Windows 上，2026-10-17，Godot 4.7.2 和 4.7.1 对上述命令给出了相同的退出码：0 表示通过，100 表示失败，101 表示孤立节点，105 表示解析错误，无测试用例时为 0 并输出 `No test cases found`，首次导入之前为 1。

Observed on Godot 4.6.1 with gdUnit4 6.1.3, and the exits again on 4.7.2 with
6.2.2 — not in the docs:
在 Godot 4.6.1 配合 gdUnit4 6.1.3 上观察到，并在 4.7.2 配合 6.2.2 上再次观察到退出码 — 文档中未记载：

- 101 is also the exit when every test passed but a test leaked orphan nodes;
  105 means a test script does not parse; 103 means gdUnit4 refused to run
  headless (`--ignoreHeadlessMode` missing). 104 is gdUnit4 refusing a Godot
  older than 4.3 — not reproducible on the pin.
- 当所有测试都通过但某个测试泄漏了孤立节点时，退出码也是 101；105 表示某个测试脚本无法解析；103 表示 gdUnit4 拒绝以无头模式运行（缺少 `--ignoreHeadlessMode`）。104 表示 gdUnit4 拒绝低于 4.3 的 Godot — 在当前固定版本上无法复现。
- Over zero tests the runner prints `No test cases found` and exits 0.
- 在零个测试的情况下，运行器会输出 `No test cases found` 并以 0 退出。
- Without `--remote-debug tcp://127.0.0.1:0`, a script error opens the `-d`
  debugger and the run waits at a `debug>` prompt; with it, every run prints two
  `ERROR:` lines about the remote port, which are expected.
- 不加 `--remote-debug tcp://127.0.0.1:0` 时，脚本错误会打开 `-d` 调试器，运行会在 `debug>` 提示符处等待；加上它后，每次运行都会输出两行关于远程端口的 `ERROR:`，这是预期行为。
- A fresh clone has no `.godot/` class cache: run
  `godot --headless --path . --import` first, or `GdUnitCmdTool.gd` does not
  load and the run exits 1 having run nothing.
- 新克隆的仓库没有 `.godot/` 类缓存：请先运行 `godot --headless --path . --import`，否则 `GdUnitCmdTool.gd` 无法加载，运行会以 1 退出且什么都没运行。
- On 4.7.1 and 4.7.2 (Windows, 2026-10-17), that first `--import` of a fresh
  project crashed on exit (139, segmentation fault) in 3 of 17 runs, after
  writing the same `.godot/` files as a clean run; running it again exited 0.
  4.6.1 did not crash in 4 runs.
- 在 4.7.1 和 4.7.2（Windows，2026-10-17）上，新项目的首次 `--import` 在 17 次运行中有 3 次在退出时崩溃（139，段错误），崩溃前写入的 `.godot/` 文件与正常运行时相同；再次运行则以 0 退出。4.6.1 在 4 次运行中均未崩溃。
- `--check-only` with `-s <file>` exits 1 on valid code that names an autoload
  (`Identifier not found`), and `--import` / `--quit-after` exit 0 on a parse
  error — neither is a parse check. The framework's parse check is
  `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<file>.gd …`
  (exit 1 when a script does not load).
- `--check-only` 配合 `-s <file>` 在代码有效但引用了 autoload 时会以 1 退出（`Identifier not found`），而 `--import` / `--quit-after` 在存在解析错误时仍以 0 退出 — 两者都不是解析检查。框架的解析检查命令为 `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<file>.gd …`（脚本无法加载时退出 1）。
- On Windows, a quoted full path to the editor (`"C:/Program Files/Godot/…exe"`)
  runs from Git Bash with its stdout and exit code intact.
- 在 Windows 上，从 Git Bash 运行带引号的编辑器完整路径（`"C:/Program Files/Godot/…exe"`）时，其 stdout 和退出码保持不变。

Sources:
- Command line tutorial: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- gdUnit4 command line tool: https://godot-gdunit-labs.github.io/gdUnit4/latest/advanced_testing/cmd/
- gdUnit4 releases: https://github.com/godot-gdunit-labs/gdUnit4/releases
- Godot 4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- Godot 4.7 release notes: https://godotengine.org/releases/4.7/
- GDScript reference, lambda functions and rest parameters: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
来源：
- 命令行教程：https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- gdUnit4 命令行工具：https://godot-gdunit-labs.github.io/gdUnit4/latest/advanced_testing/cmd/
- gdUnit4 版本发布：https://github.com/godot-gdunit-labs/gdUnit4/releases
- Godot 4.7 迁移指南：https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- Godot 4.7 发行说明：https://godotengine.org/releases/4.7/
- GDScript 参考，lambda 函数与其余参数：https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html

## Platform (4.5+)
## 平台（4.5+）

- **visionOS export**: First new platform since open-sourcing (windowed app mode)
- **visionOS 导出**：自开源以来新增的首个平台（窗口化应用模式）
- **SDL3 gamepad driver**: Better cross-platform gamepad support
- **SDL3 手柄驱动**：更好的跨平台手柄支持
- **Android**: Edge-to-edge display, camera feed access, 16KB page support (Android 15+)
- **Android**：边到边显示、摄像头画面访问、16KB 页支持（Android 15+）
- **Linux**: Wayland subwindow support for multi-window capability
- **Linux**：支持 Wayland 子窗口，以实现多窗口能力
