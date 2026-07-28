# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Flutter + Flame 1.37.0 (Flutter SDK 3.44.4 / Dart 3.12.2)
- **Language**: Dart
- **Rendering**: Flutter CanvasKit / Skia (2D only)
- **Physics**: Forge2D (optional) or custom collision via Flame

## Input & Platform

- **Target Platforms**: Mobile (iOS + Android)
- **Input Methods**: Touch
- **Primary Input**: Touch
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: All UI must be touch-friendly. Minimum tap target 48×48dp per Material guidelines. No hover-only interactions. iOS audio session must be configured for background/foreground transitions.

## Naming Conventions

- **Classes / Components**: PascalCase (e.g., `PlayerComponent`, `PetCareSystem`)
- **Variables / functions**: camelCase (e.g., `moveSpeed`, `takeDamage()`)
- **Signals/Events**: camelCase stream names (e.g., `onPetMoodChanged`)
- **Files**: snake_case matching primary class (e.g., `pet_care_system.dart`)
- **Scenes/Prefabs**: N/A — Flame uses Dart component trees, not scene files
- **Constants**: camelCase preferred per Dart style (e.g., `maxHealth`); `SCREAMING_SNAKE_CASE` acceptable for compile-time constants

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: ≤200 per frame (use SpriteBatch for batching repeated sprites)
- **Memory Ceiling**: ≤150MB RAM on mid-range Android devices (2019+)

## Testing

- **Framework**: flutter_test (unit + widget tests), flame_test (component tests)
- **Minimum Coverage**: 70% for game logic and economy systems
- **Required Tests**: Balance formulas, task reward calculations, economy system, pet state machine

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

- **Primary**: flame-specialist
- **Language/Code Specialist**: flame-specialist (Dart — primary covers all game code review)
- **Shader Specialist**: flame-shader-specialist (.frag GLSL files, FragmentProgram, SpriteBatch, particles)
- **UI Specialist**: flame-widget-specialist (Flutter widget layer, GameWidget overlays, HUD, state management)
- **Additional Specialists**: flame-audio-specialist (flame_audio, BGM/SFX systems, audio lifecycle, platform quirks)
- **Routing Notes**: Invoke primary for Flame architecture decisions, component hierarchy, game loop, camera, and collision systems. Invoke widget specialist for Flutter overlay UI, HUD, menus, and state management (Riverpod/Bloc). Invoke shader specialist for fragment shaders, SpriteBatch, and custom Canvas rendering. Invoke audio specialist for all sound and music implementation.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.dart files — Flame components, FlameGame) | flame-specialist |
| Flutter UI / overlay files (.dart — widgets, screens) | flame-widget-specialist |
| Fragment shader files (.frag) | flame-shader-specialist |
| Asset config / pubspec.yaml (assets, shaders) | flame-specialist |
| Audio implementation (.dart — flame_audio, audioplayers) | flame-audio-specialist |
| General architecture review | flame-specialist |
