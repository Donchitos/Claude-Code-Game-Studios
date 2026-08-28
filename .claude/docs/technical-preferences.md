# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.7.1
- **Language**: GDScript
- **Rendering**: Godot Forward+ (2D 项目下实际走 2D 渲染器)
- **Physics**: Godot Physics 2D (内置 — Jolt 是 3D 选项，本项目 2D 不适用)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Mobile (Android, iOS) — 优先竖屏
- **Input Methods**: Touch
- **Primary Input**: Touch (虚拟摇杆移动，攻击自动释放)
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: 竖屏单手操作；所有交互必须单手可达；移动端无 hover，不得设计悬停态交互；升级 / 机缘选择时暂停战斗。

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 FPS (中端 Android 设备平均 50 FPS+)
- **Frame Budget**: 16.6 ms
- **Draw Calls**: [待定 — 依赖后续渲染批处理 ADR]
- **Memory Ceiling**: [待定 — 依赖目标设备基准确定]

## Testing

- **Framework**: GDUnit4
- **Minimum Coverage**: 平衡公式、伤害计算、升级经验、敌人阶段倍率 (BLOCKING)
- **Required Tests**: Balance formulas, gameplay systems

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- 稳态(借出/归还/每帧)路径禁 `emit_signal(带参)` / `set_deferred` /
  `call(method_string,…)` / `get_children()`(EnemySystem §3.4 零分配禁令;
  AC-E4-code 静态守卫)
- gameplay phase participant 禁定义 `func _physics_process` / `func _process`（集中
  `run_phase` 驱动；AC-E13）。唯一例外为场景中的单一 GameRoot 集中编排节点：它精确
  使用 `PROCESS_MODE_ALWAYS`，并精确实现 `_physics_process(delta: float) -> void`，仅在
  SceneTree 未暂停且状态允许技术 tick 时驱动七个 physics phase；精确实现
  `_process(delta: float) -> void`，仅在 `BATTLE_PAUSED/RESUME_PREPARING`
  驱动 control pump；两者必须先检查权威 state/pause predicate，禁止在 Paused 跑
  gameplay phase、未暂停时跑 paused pump、双跑或由其他节点复制该例外（InputSystem
  AC-IS2 / GameRoot AC-B1）。
- Godot 4.7.1 VirtualJoystick callback ABI 固定为引擎signal `pressed()`与
  `released(input_vector: Vector2)`；项目adapter用direct `Callable.bind(epoch)`形成
  `_on_vj_pressed(callback_epoch: int) -> void`与
  `_on_vj_released(input_vector: Vector2, callback_epoch: int) -> void`，保存同一Callable
  身份用于精确disconnect。不存在独立VJ `canceled` signal；shield使用
  `_gui_input(event: InputEvent) -> void`，Host lifecycle使用
  `_notification(what: int) -> void`。`callbacks_armed`、`runtime_ingress_armed`与
  `shield_bank_service_enabled`必须分离：callbacks只表示initialize成功至teardown的adapter生命周期；
  runtime ingress只允许ACTIVE的新VJ press/generation/movement路径；shield bank service只允许
  LOCK_PENDING/FROZEN/RESUME_LOCKED的consumer-closed bank/FSM。状态组合固定为IDLE=`true/false/false`、
  ACTIVE=`true/true/false`、三种locked state=`true/false/true`、TERMINATED=`false/false/false`。
  ACTIVE进入普通pause、fatal cleanup或async safe-close时，必须先由InputSystem唯一私有
  `commit_consumer_closed()`以Godot主线程callback-observable atomicity提交完整
  `state=LOCK_PENDING、callbacks/runtime/service=true/false/true`，再调用shield STOP property setter，
  最后执行action/carrier clear。这里“原子”只允许连续写预分配typed primitive backing fields，区间内
  禁止函数调用、Godot property setter、signal、Callable与`await`；`ACTION_CLEAR_FAILED`保持LOCK_PENDING
  tuple并进入fault，不得回滚ACTIVE。IDLE load/fault/async cleanup始终保持`true/false/false`与
  PREACTIVE_DISCARD，绝不临时开启bank service；既有locked state保持`true/false/true`。
  teardown在任何filter setter、disconnect、remove_child或queue_free前先单一局部提交
  `TERMINATED + false/false/false`、清bank并撤销bank/choice/pending latch写权；随后同步callback
  只能追加suppressed diagnostic，不得重填latch或bank。
  UNARMED及callbacks已arm但Input仍为IDLE时，VJ保持不可命中，shield touch只执行
  `accept_event()`并走`PREACTIVE_DISCARD`，项目owned gesture/bank/action/carrier/
  pending-status零写；允许引擎Viewport handled/touch-focus变化。Host lifecycle虚回调
  在preactive期间只可写预分配、无需trusted tick的invalidation latch，确保
  APP_BACKGROUND/geometry事件不会静默丢失。任何battle input节点入树前，唯一GameRoot bootstrap
  恰调用一次`Input.set_use_accumulated_input(false)`并readback false；`project.godot`冻结
  `input_devices/buffering/agile_event_flushing=false`，GameRoot通过ProjectSettings只读验证。
  随后在BOOT的Home/Battle input target、consumer、callback、Input polling与`window_input` consumer
  均未激活时恰调用一次`Input.flush_buffered_events()`；flush中的项目Control callback、scene transition、
  choice/movement/gameplay effect为0，四movement action随后`pressed=false/raw=0`，但不宣称Godot
  InputMap/cache/pressed状态零修改。本局后续Input setter、flush与ProjectSettings runtime mutation均为0；
  initialize与每个ACTIVE `PRE_ACQUIRE`分别验证Input accumulated实时readback与ProjectSettings agile冻结值，
  任一漂移都以`INVALID_CONFIG`失败且不写Viewport。
  `IDLE→ACTIVE`与resume ACTIVE尾段按`PRE_ACQUIRE→SET_TRUE_IN_FLIGHT→GATE_HELD→release`
  阶段矩阵执行。true setter在bool置true前同步drop focus/leave/tooltip及可能的focused-Control
  `_gui_input`，所以setter-in-flight不宣称Viewport delivery=0。生产callback只可写typed invalidation
  latch/diagnostic且禁止直接注入InputEvent；hostile harness或引擎入口仍交付合法ScreenTouch时，loading
  由shield `accept_event()`后PREACTIVE_DISCARD且bank保持0，resume由STOP shield在既有
  `shield_bank_service_enabled=true`下按current-epoch FSM `accept_event()`并更新held bank，但callback不得写
  runtime/service两个enable字段，VJ/action/carrier/choice/movement generation/gameplay consumer/top-state
  effect仍为0。true返回/readback后的first observer发现held时以`HELD_ONLY_RETURN_TO_DRAIN`回drain，
  不继续ACTIVE或升级technical fault；press与terminal均在setter返回前完成、bank回空且其他条件clean时
  可继续。true返回/readback后到false调用前才由Viewport gate保证零投递。Input在
  `GATE_HELD`中执行filter activation guard并以单一局部提交原子置ACTIVE/runtime=true/shield-service=false，GameRoot再提交
  BATTLE_ACTIVE/consumer/foreground block。唯一私有release helper持有false setter call-site，
  reason只允许`ACTIVATION_SUCCESS`、`HELD_ONLY_RETURN_TO_DRAIN`、
  `LOAD_ABORT_OR_FAULT_CLEANUP`；pre-acquire failure release=0。其他节点禁止写gate；activation
  生产callback禁止调用`Input.parse_input_event`、`Input.flush_buffered_events`、
  `Viewport.push_input/push_unhandled_input`或等价直接注入入口；hostile runtime harness仅证明containment。
  GameRoot的APP_BACKGROUND resume gate必须以latest required/acked revision配对，每个新
  background revision都使旧Continue失效，duplicate同revision不重复确认。

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **gdtoolkit**(gdlint + gdformat)—GDScript 静态 linter/formatter。用于代码
  审计 AC 的静态守卫(注释免疫、空体判定、typed-return override 检测)。**R4 修正
  (2026-08-25,qa-lead 实测 gdtoolkit 4.5.0 确认)**:gdlint 本身**无自定义规则/插件 API**
  (`never-returning-function` 等规则在 DEFAULT_CONFIG 为注释行未实现),故 grep 不可靠处
  **不**由"gdlint/AST 规则"守卫——改由 `tools/ci/static_guard_check.py` 自定义 CI AST 脚本
  守卫(用 `gdtoolkit.parser` 库:`from gdtoolkit.parser import parser` → Lark Tree 遍历)。
  受影响 AC:AC-E19(3)/AC-E37/AC-E4-code(AC-E13 的 `func` 定义归 rg 正则、
  `callback_mode_process` 归场景审计)。非运行时依赖,仅 CI/本地工具链。安装:`pip install gdtoolkit`

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
