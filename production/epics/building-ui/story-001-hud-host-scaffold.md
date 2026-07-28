# Story 001: HUD host scaffold, zone layout, Suspended & the UI timer manager

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (Layout Zones, Visual Budget, Dynamic Behaviors)
**Requirement**: `TR-building-ui-041`, `TR-building-ui-042`, `TR-building-ui-005`, `TR-building-ui-066`, `TR-building-ui-015`, `TR-building-ui-040`, `TR-building-ui-053`, `TR-building-ui-071`, `TR-building-ui-037`, `TR-building-ui-038`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0011 (UI Timer & Expiry Management) — primary; ADR-0001 (DI) and ADR-0002 (config) — the module shape
**ADR Decision Summary**: A centralized `UITimerManager` — a `Dictionary[key, TimerRecord]` plus one shared `_process(delta)` loop — never N Godot `Timer` nodes. It runs on raw delta and is pause-immune; a single guard flag freezes it on Suspended and resuming is automatic because remaining time was never touched. The HUD itself is an injected-tier module (ADR-0001): typed `@export` deps, all wiring in an explicitly-callable `setup()`, headless-instantiable via `Node.new()` + mocks — the shape every "blocking headless" AC in this epic rests on.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Godot's `Timer.paused` DOES natively preserve and auto-resume `time_left` (confirmed in ADR-0011's engine validation — the GDD's original "fragile time_left reconstruction" rationale was wrong). The centralized manager is chosen for Node-overhead and project-precedent-consistency, not pause fidelity; do not re-litigate. Hiding a `Control` does **not** pause a `Timer`/`Tween` — the Suspended freeze is an explicit call driven by the same Camera & Input Suspended signal that hides the HUD, one trigger, no drift. Cross-check `docs/engine-reference/godot/` before any Control/anchor API (4.5–4.7 is a flagged post-cutoff domain, M02 risk R13).

**Control Manifest Rules (this layer)**:
- Required (Presentation): the HUD is a pure mirror. UI-local presentation memory is owned here **by design and is exhaustively scoped** — per-tool last-selected material, toast/anchor presentation state, the Selection, and nothing else; none of it serialized, none consumed by another system.
- Forbidden: any simulation-authoritative state on the HUD; any `VoxelWorldGrid` write API; any config-Resource field write at runtime (`neues-spiel/CONTRACTS.md` §2); per-consumer `Timer` nodes.
- Guardrail: the HUD runs on **raw** delta and stays fully usable during game pause; it hides and ignores input only in **Suspended**. Suspended ≠ Pause.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 1/2 + Edge Cases 6/8 and `design/ux/hud.md` Layout Zones, scoped to this story:*

- [ ] A `BuildingUi` injected-tier `Node` exists with typed `@export` dependencies and a `func setup() -> void` that asserts them; it instantiates headlessly via `Node.new()` + mocks with zero scene tree (`TR-building-ui-038`).
- [ ] A `BuildingUiConfig extends ConfigResource` exists with one typed `@export` per GDD Tuning Knob (`toast_max_visible`, `min_reshow_interval`, `warning_grace_delay`, `invalid_cue_fade`, `ghost_alpha_draft`, `ghost_alpha_released`, `build_grid_opacity`, `projects_panel_max_visible_cards`), defaulted to the GDD/UX values, authored as `.tres` text, with `validate()` called exactly once from `setup()` (`TR-building-ui-037`).
- [ ] `validate()` clamps `ghost_alpha_released` up to `ghost_alpha_draft` when it would fall below it, appending a plain warning — the draft→released ordering invariant can never collapse. Warn-and-clamp tier, **not** BLOCKING; boot proceeds.
- [ ] The zone skeleton exists and is relatively anchored — no fixed pixel positions: **Z1** time controls (top-right), **Z2** toast stack (below Z1), **Z3** issues anchor (below Z2), **Z4** villager panel host (left edge, lower half, grows upward from one `ZONE_GAP` above Z7), **Z5** context panel (docked above Z6), **Z6** toolbar (bottom-center), **Z7** Projects Panel (bottom-left corner) (`TR-building-ui-041`, hud.md + projects-panel.md Layout Zones).
- [ ] Every zone keeps a minimum inset of **16 px at 720p** (scaling proportionally) from its screen edge — nothing sits flush against the border (hud.md edge-margin rule).
- [ ] At 1280×720 the zones' bounding rects lie fully in-viewport and do not intersect, and the **center third of the screen is HUD-free** (`TR-building-ui-071`, hud.md Visual Budget).
- [ ] The HUD updates on **raw delta** and stays fully responsive while the game is paused — every control operable on a paused frame (`TR-building-ui-005`).
- [ ] **GIVEN** Suspended entered (Camera & Input / `GameWorld.transition_begun`), **THEN** the entire HUD hides, ignores input, and every UI timer freezes; **WHEN** reactivated (transition complete OR abort), **THEN** the HUD restores and timers resume with **remaining** time — never restart (AC16, Edge Case 6, `TR-building-ui-066`, `TR-building-ui-015`).
- [ ] A `UITimerManager` exists as a plain class the HUD instantiates (not an Autoload, not an architecture-level module): `start(key, duration, callback)`, `cancel(key)`, `remaining(key)`, one shared `_process`-driven loop, a `set_suspended(bool)` guard flag, and **zero** `Timer`/`Tween` node instantiation anywhere (`TR-building-ui-040`, `TR-building-ui-053`).
- [ ] **GIVEN** a timer with 2 s remaining and the game PAUSED past that duration, **THEN** the timer still expires — timers are wall-clock and pause-immune (`TR-building-ui-053`, AC40's precondition).
- [ ] A grep over the UI module returns **zero** matches for `set_cell(`/`bulk_write(`/`clear_cell(` and zero config-field writes (`config\.\w* *=`).

---

## Implementation Notes

*Derived from ADR-0011's Decision and ADR-0001/ADR-0002's established module shape:*

- Mirror the landed injected-tier shape exactly (`CameraInput`, `CommitPipeline`): typed `@export` deps + config, all wiring/validation in `setup()`, `_ready()` doing nothing beyond optionally calling it. Add the module to the hosting scene's injected-tier list so `GameWorld._setup_injected_tier()` gates it behind the boot gate (ADR-0005).
- Reuse `ToolStateMachine`/`CameraInput`'s established Suspended wiring shape verbatim: an OPTIONAL injected `game_world` dependency connected to `transition_begun`/`transition_ended` inside this class's own `setup()`. `GameWorld` never calls into a consumer directly.
- **One trigger drives both effects**: the same Suspended-entry signal hides the HUD and calls `UITimerManager.set_suspended(true)`. Do not tie the timer freeze to Control visibility — it is not a visibility side effect.
- `TimerRecord` carries `remaining: float` + `callback: Callable`; the shared loop decrements on **raw** delta (`_process`'s own delta, never `TimeTickSystem.get_game_delta()`), skipping entirely while `_suspended`.
- Zones are `Control` containers with relative anchors only. Store the 16 px-at-720p inset as a named constant scaled by the viewport, not as a per-zone literal.
- The Visual Budget's worst case is **8 elements** (toolbar + context panel + time controls + 3 toasts + issues anchor + villager panel) — plus Z7, which projects-panel.md OQ1 flags as a pending `hud.md` follow-up. Record the count as an assertable constant so story 018's budget check has something to test against.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the Build Mode gate, tool buttons and the Esc chain.
- Story 003/004: any context-panel content.
- Story 006: the time controls' behavior (this story only reserves Z1).
- Stories 013–015: what actually *uses* the timer manager (grace, debounce, invalid-cue fade). This story ships the mechanism and its own tests only.
- Story 011: the Projects Panel's content (this story only reserves Z7).
- Story 018: the advisory screenshot/grayscale evidence pass.

---

## QA Test Cases

- **AC16**: Given Suspended entered, When the transition signal fires, Then the HUD is hidden, input is ignored, and every active timer's `remaining` is unchanged across N frames; When `transition_ended(true)` fires, Then the HUD is visible and the timers resume from that exact remaining value.
- **Suspended abort**: Given `transition_ended(false)`, Then the HUD restores identically — an aborted transition is not a different path.
- **Pause immunity**: Given a 2 s timer and a mocked paused Time & Tick, When 3 s of raw delta elapse, Then the callback fired exactly once.
- **AC (config)**: Given `ghost_alpha_released` authored below `ghost_alpha_draft`, When `validate()` runs, Then the value is clamped up, a warning string is appended, and boot proceeds (no BLOCKING prefix).
- **AC (zones)**: Given a 1280×720 viewport, Then all seven zone rects are in-viewport, pairwise non-intersecting, and none overlaps the center third.
- **Grep guards**: Given the UI module source, When grepped, Then zero Voxel World write calls, zero runtime config writes, and zero `Timer.new()`/`Tween` instantiations.

---

## Test Evidence

**Story Type**: Integration + UI. The DI/config/timer/Suspended half is **BLOCKING** (state-machine logic per `.claude/docs/coding-standards.md`); the zone-layout half is **ADVISORY** (UI).
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/building_ui_scaffold_test.gd` and `neues-spiel/tests/unit/ui/ui_timer_manager_test.gd` — must exist and pass.
**Required evidence (advisory)**: `production/qa/evidence/building-ui-001-zone-layout-walkthrough.md` — 1280×720 screenshot + zone-rect assertions.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `building-001` (build editor mode — the mode this HUD lives inside, Cluster 0); the hosting decision in **Known Conflict 1/3** (which scene owns the HUD node).
- Unlocks: every other story in this epic.
