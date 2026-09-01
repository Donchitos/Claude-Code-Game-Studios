# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Forward+ (Godot 4 default)
- **Physics**: Jolt (Godot 4.6 default)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC, Console
- **Input Methods**: Keyboard/Mouse (primario), Gamepad (consola)
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: El esquema de control está diseñado mouse-first (selección de unidades, cámara RTS). El soporte de gamepad para consola necesitará un sistema de selección/cursor alternativo diseñado explícitamente, no solo un remapeo directo.

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case, tiempo pasado (e.g., `health_changed`)
- **Files**: snake_case coincidiendo con la clase (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase coincidiendo con el nodo raíz (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6ms
- **Draw Calls**: <1000 (2D con sprite batching)
- **Memory Ceiling**: [TO BE CONFIGURED — definir cuando se conozca el hardware objetivo]

## Testing

- **Framework**: GdUnit4 (Godot 4 test framework) — runner `tests/gdunit4_runner.gd`, CI `.github/workflows/tests.yml` (gdUnit4-action). Instalar vía AssetLib → `res://addons/gdunit4/`. *(Corregido 2026-08-21: antes decía "GUT" por error; el comando de CI de coding-standards y `/test-setup` siempre usaron GdUnit4.)*
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

- **GdUnit4** (test framework, dev-only) — aprobado 2026-08-21 vía `/test-setup`. No se envía en el build de release.

## Architecture Decisions Log

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
