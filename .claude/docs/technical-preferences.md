# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.7-stable
- **Language**: GDScript
- **Rendering**: Chunked face-culled voxel mesher + packed chunk storage + streamed view window (ADR-0014, prototype-validated at 2000×2000×32); ghost previews via pooled MeshInstance3D; picking via DDA on the data layer
- **Physics**: Jolt Physics 3D (4.6+ default, no override; ADR-0004) — villagers are Area3D-only, blocks have no physics colliders

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows first)
- **Input Methods**: Keyboard/Mouse
- **Primary Input**: Keyboard/Mouse
- **Gamepad Support**: Partial
- **Touch Support**: None
- **Platform Notes**: Mouse-driven building/placement (room drawing, furniture placement) is the core interaction. No touch or primary-gamepad design constraints; partial gamepad support may be added later for menu/camera navigation only.

## Naming Conventions

- **Classes**: PascalCase (e.g., `PlayerController`)
- **Variables**: snake_case (e.g., `move_speed`)
- **Signals/Events**: snake_case past tense (e.g., `health_changed`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g., `PlayerController.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6ms
- **Draw Calls**: ≤ 2000 (PC mid-range target; voxel geometry uses MultiMesh/GPU instancing to stay well under this)
- **Memory Ceiling**: 4 GB (PC baseline; revisit after the voxel entity-count/building prototype)

## Testing

- **Framework**: GUT (Godot Unit Testing)
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- **`SceneTree.paused`** — never use for game pause. Pause is owned by the
  Time & Tick System (`game_delta = 0`); the engine-global pause would also
  freeze the camera, UI, and transition overlays, which must keep running
  on raw delta. (Source: time-tick-system.md Formulas + 2026-07-10 review.)
- **`Engine.time_scale`** — never use for time-warp. Warp is owned by the
  Time & Tick System (`game_delta` multiplier); the engine-global scale
  would also speed up camera feel and UI animation. (Same source.)

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- **GdUnit4 v6.1.3** (`neues-spiel/addons/gdUnit4/`) — test framework, approved 2026-07-11

## Bundled Fonts

All SIL Open Font License, free for commercial use, licence files stored
alongside the fonts in `neues-spiel/assets/fonts/`. Source:
`github.com/google/fonts`. Downloaded and glyph-verified 2026-07-27
(extended Latin incl. ä/ö/ü/ß, French accents, typographic quotes).

| Font | Role | Files |
|---|---|---|
| Cinzel | UI display — names, labels, menu items | `Cinzel[wght].ttf` |
| Cinzel Decorative | Title only | `CinzelDecorative-Regular/Bold.ttf` |
| EB Garamond | UI body text | `EBGaramond[wght].ttf`, `-Italic[wght].ttf` |
| MedievalSharp | Rubrics | `MedievalSharp.ttf` |
| Caveat | Villager diary hand | `Caveat[wght].ttf` |
| Uncial Antiqua | Held in reserve, unused | `UncialAntiqua-Regular.ttf` |

## UI Quality Gates

- **`tools/ui-contrast-check.py`** — must pass (exit 0) after ANY change to
  the UI palette. Enforces `accessibility-requirements.md` A3 (4.5:1 for
  text, 3:1 for non-text separation). This check had never been run before
  2026-07-27 and immediately found three failures.
- **Greyscale pass** — `?gray=1` on the mockups, plus
  `design/art/state-shape-table.md`. Enforces A1: no state may be carried by
  hue alone.

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- ADR-0001 Inter-System Reference & DI Pattern — **Accepted**
- ADR-0002 Tuning/Config Data Strategy — **Accepted**
- ADR-0003 Voxel World Rendering Approach — Superseded by ADR-0014 (large-world decision)
- ADR-0004 Physics Backend & Picking Strategy — **Accepted**
- ADR-0005 Boot Sequencing & Initialization Gate — **Accepted**
- ADR-0006 Data Definition Immutability & Reference Format — **Accepted**
- ADR-0007 AI Pathfinding, Navigation & Room Analysis — **Accepted** (spike QQ3 PASS; amended 2026-07-27 v1.1 — scaffolding §1a/§1b/§2a/§2b: scaffold cells are self-supporting and passable, occupancy is an injected non-voxel source, exactly one new edge class (scaffold-to-scaffold vertical). Not general climbing.)
- ADR-0008 Villager AI Execution & Threading — **Accepted** (spike QQ3 PASS; `max_deciding_per_tick = 1`)
- ADR-0009 Deterministic Movement & Occupancy Ordering — **Accepted**
- ADR-0010 Cross-System UI/World Input Arbitration — **Accepted**
- ADR-0011 UI Timer & Expiry Management — **Accepted**
- ADR-0012 Save/Load Serialization Strategy — **Accepted**
- ADR-0013 Multi-Scene Concurrency Model — **Accepted**
- ADR-0014 Chunked Voxel Rendering & Large-World Storage — **Accepted** (prototype-validated; supersedes ADR-0003; amended 2026-07-23 slice propagation — CW winding/culling, ghost-picking predicate; full-world-at-boot clause **superseded by ADR-0015** for the 16k target)
- ADR-0015 Large-World Storage & Residency (16k target) — **Accepted** (spike-validated 2026-07-23, 5/5 at 144 & 120 c/s, caps 32/64; paged region-file residency, time-based budget, no synchronous per-frame I/O/gen; supersedes ADR-0014's full-world-at-boot clause)
- ADR-0016 Build-Project Entity Lifecycle — **Accepted** (prototype-validated 2026-07-22/23; persistent draft→released→paused→done projects, plan-only undo, job-based demolition incl. furniture)

Status source of truth: each ADR's `## Status` section in `docs/architecture/`.

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
