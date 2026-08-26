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
- 禁定义 `func _physics_process` / `func _process`(集中 run_phase 驱动;
  AC-E13)

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
