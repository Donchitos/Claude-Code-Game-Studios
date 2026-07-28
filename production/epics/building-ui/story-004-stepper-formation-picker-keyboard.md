# Story 004: Wall-height stepper, roof-formation picker & keyboard parity

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/hud.md` (E4 variants, Default Key Bindings — `height_step_up/down` = R/F, `formation_next/prev` = B/V)
**Requirement**: `TR-building-ui-047`, `TR-building-ui-059`, `TR-building-ui-065`, `TR-building-ui-045`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (Tuning/Config Data Strategy)
**ADR Decision Summary**: Config `Resource` fields are read-only at runtime — the ONE sanctioned write lives inside `validate()` itself, and `load()` caching means any other write is visible to every holder project-wide. A **player-facing runtime value is therefore not a config field**; it must live on the owning module as runtime state, seeded from the config default and clamped to the config's declared range.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: `height_step_up`/`height_step_down`/`formation_next`/`formation_prev` are **already registered** in `project.godot` and listed in `CameraInput.OWNED_ACTIONS` (verified 2026-07-26). Their default keys (R/F, B/V per hud.md) are `[assumption]` pending the first playtest — the ACTIONS are the commitment. `+`/`−` are time-owned and unavailable to the stepper (GDD Rule 9b).

**Control Manifest Rules (this layer)**:
- Required (Presentation): the stepper is the **only player-facing tuning knob** in the Building System's Tuning Knobs table; the HUD mirrors its value and clamps the *display* to 1–8, it does not own the value.
- Forbidden: writing `WallToolConfig.wall_height` (or any config field) at runtime — `neues-spiel/CONTRACTS.md` §2 Forbidden, grep-verified zero today; a UI-local height latch that can diverge from the source.
- Guardrail: no persistent HUD element is mouse-only — every stepper/picker interaction has an equivalent registered action (Rule 9b).

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md` Rules 6/9b, scoped to this story:*

- [ ] **AC7**: Given the stepper at 8, When `+` fires, Then it stays 8; same at 1 with `−` — a clamped display of Building's declared range (`TR-building-ui-047`).
- [ ] **AC19**: Given mousewheel over the stepper, Then it steps identically to the +/− buttons within 1–8 (`TR-building-ui-047`).
- [ ] **AC39 (height half)**: Given Wall armed, When `height_step_up`/`height_step_down` fire, Then the stepper changes **identically** to a +/− button click within 1–8 (`TR-building-ui-059`).
- [ ] **AC39 (formation half)**: Given Roof armed, When `formation_next`/`formation_prev` fire, Then the formation selection cycles **identically** to clicking the icons (`TR-building-ui-059`).
- [ ] The roof-formation picker renders exactly **4** icons mapping one-to-one onto the landed `RoofTool.Formation` enum (`FLAT`, `GABLE`, `HIP`, `SHED`) and routes a selection through `RoofTool.set_formation()`, mirroring `get_formation()` — never a UI-local latch (`TR-building-ui-045`).
- [ ] **MVP scope note asserted, not assumed**: only `FLAT` is implemented in `RoofTool.resolve_cell_set` (milestone Out of Scope — "Roof formations beyond Flat are VS-tier reserve"). The picker must render all four but make the three unimplemented formations visibly and tooltip-explained unavailable, **never silently selectable into a no-op**.
- [ ] The stepper's value is read from a **runtime** wall-height holder on the Wall tool (seeded from `WallToolConfig.wall_height`, clamped to that config's range) — the HUD emits a set-intent and mirrors the resulting value; **no config field is written** (Known Conflict 2).
- [ ] **AC36 (partial)**: Given the InputMap at boot, Then `height_step_up`, `height_step_down`, `formation_next`, `formation_prev` exist as registered actions (`TR-building-ui-065`).
- [ ] The stepper appears only while **Wall** is armed and the formation picker only while **Roof** is armed; neither renders in Idle or WorldNav (Rule 4).
- [ ] A grep over the UI module returns zero matches for `config\.\w* *=`.

---

## Implementation Notes

*Derived from ADR-0002 and the landed `WallTool`/`RoofTool`:*

- **Known Conflict 2 is this story's gate.** Landed `wall_height` is `@export var wall_height: int = 3` on `WallToolConfig extends ConfigResource`, and `WallTool` exposes no runtime setter — only the static `wall_cell_set(press, release, wall_height)` and `extrude_column(base, wall_height)`. The required change (a runtime holder on `WallTool`, config-seeded, range-clamped, with a `get_wall_height()`/`set_wall_height()` pair) is **building-system's**, not this story's. Do not work around it by writing the config; that would silently mutate the cached `.tres` for every holder in the project.
- The 1–8 range is the *display* clamp; the authoritative bound is `WallToolConfig`'s own validated range. Read the bound, do not hardcode 8 in the UI.
- `RoofTool.set_formation()`/`get_formation()` already exist and are runtime-safe — the formation picker is the easy half; only the height stepper is blocked.
- Mousewheel-over-stepper and the +/− buttons must funnel into **one** step function so AC19 and AC39 are the same code path with three entry points; test the function, then assert each entry point calls it.
- The three unavailable formations: prefer a disabled control state + tooltip ("Vertical Slice") over hiding them — the GDD commits to "4 icons" and hiding them would silently change the specified panel.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: the palette itself and the panel's show/hide per armed tool.
- Story 005: undo/redo keyboard bindings.
- Story 015: `toast_focus_cycle`/`toast_dismiss`/`toggle_issues` — the notification half of Rule 9b.
- The wall-height runtime holder itself — that is a **building-system** change (Known Conflict 2).

---

## QA Test Cases

- **AC7**: Given height 8, When step-up fires, Then the mirrored value is 8 and exactly one set-intent was emitted (or none — assert the chosen convention explicitly); Given height 1 and step-down, Then 1.
- **AC19/AC39 parity**: Given the same starting height, When (a) a +/− click, (b) a mousewheel notch, (c) `height_step_up` each fire in separate runs, Then all three produce the identical resulting value and the identical emitted intent.
- **AC39 (formation)**: Given Roof armed at `FLAT`, When `formation_next` fires 4 times, Then the selection returns to `FLAT` and `set_formation` was called 4 times with the enum in order.
- **Unavailable formations**: Given `GABLE` clicked, Then no `set_formation(GABLE)` intent is emitted and the disabled state + tooltip are present.
- **Visibility**: Given Roof armed, Then the stepper is absent; Given Wall armed, Then the formation picker is absent; Given Idle, Then both absent.
- **Config guard**: Given the UI module source, When grepped for `config\.\w* *=`, Then zero matches.

---

## Test Evidence

**Story Type**: Logic (clamped stepper + cycling state) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/stepper_and_formation_picker_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003 (the panel these two controls live in); **Known Conflict 2** (runtime `wall_height` holder — building-system) and **Known Conflict 3** (tool hosting) must both be resolved first.
- Unlocks: —
