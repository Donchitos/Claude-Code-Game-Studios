# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Unity 6.3 LTS
- **Language**: C#
- **Rendering**: Universal Render Pipeline (URP)
- **Physics**: Unity Physics (3D)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Steam / Epic)
- **Input Methods**: Keyboard/Mouse, Gamepad
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial (recommended — controller players exist on PC)
- **Touch Support**: None
- **Platform Notes**: All UI must support both mouse and gamepad navigation. No hover-only interactions. Steam Input API integration recommended for broad controller compatibility.

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`, `HiveMindManager`)
- **Public fields/properties**: PascalCase (e.g., `MoveSpeed`, `CorruptionLevel`)
- **Private fields**: _camelCase (e.g., `_currentCorruption`, `_isGrounded`)
- **Methods**: PascalCase (e.g., `TakeDamage()`, `ActivateTrap()`)
- **Interfaces**: `I` prefix PascalCase (e.g., `IDamageable`, `ICorruptible`)
- **Files**: PascalCase matching class (e.g., `PlayerController.cs`)
- **Scenes/Prefabs**: PascalCase matching root concept (e.g., `ReclaimeOperative.prefab`, `SectorOne.unity`)
- **Constants**: PascalCase or UPPER_SNAKE_CASE (e.g., `MaxCorruption`, `MAX_CORRUPTION`)

## Performance Budgets

- **Target Framerate**: 60 fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: 500 (URP batched)
- **Memory Ceiling**: 2 GB RAM
- **Notes**: Asymmetric session — Hive Mind godview may have higher scene object counts than Reclaimer FPS view. Profile both camera modes independently.

## Testing

- **Framework**: NUnit via Unity Test Framework (UTF)
- **Minimum Coverage**: Core gameplay systems (Corruption meter, class abilities, Hive Mind unit AI)
- **Required Tests**: Corruption meter math, win/loss condition triggers, network session authority (Reclaimer vs Hive Mind roles)
- **CI Command**: `game-ci/unity-test-runner@v4` (GitHub Actions)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: unity-specialist
- **Language/Code Specialist**: unity-specialist (C# review — primary covers it)
- **Shader Specialist**: unity-shader-specialist (Shader Graph, HLSL, URP materials)
- **UI Specialist**: unity-ui-specialist (UI Toolkit UXML/USS, UGUI Canvas, runtime UI)
- **Additional Specialists**: unity-dots-specialist (ECS, Jobs system, Burst compiler), unity-addressables-specialist (asset loading, memory management, content catalogs)
- **Routing Notes**: Invoke primary for architecture and general C# code review. Invoke DOTS specialist for any ECS/Jobs/Burst code. Invoke shader specialist for rendering and visual effects. Invoke UI specialist for all interface implementation. Invoke Addressables specialist for asset management systems.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.cs files) | unity-specialist |
| Shader / material files (.shader, .shadergraph, .mat) | unity-shader-specialist |
| UI / screen files (.uxml, .uss, Canvas prefabs) | unity-ui-specialist |
| Scene / prefab / level files (.unity, .prefab) | unity-specialist |
| Native extension / plugin files (.dll, native plugins) | unity-specialist |
| General architecture review | unity-specialist |
