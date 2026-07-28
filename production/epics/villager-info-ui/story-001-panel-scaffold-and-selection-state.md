# Story 001: Panel scaffold, Z4 host, selection state & the live-mirror loop

> **Epic**: Villager Info UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-info-ui.md`
**UX Spec**: `design/ux/villager-panel.md` (Layout Specification, States & Variants, Data Requirements) · `design/ux/hud.md` (zone Z4, element E7)
**Requirement**: `TR-villager-info-ui-023`, `TR-villager-info-ui-033`, `TR-villager-info-ui-010`, `TR-villager-info-ui-038`, `TR-villager-info-ui-040`, `TR-villager-info-ui-041`, `TR-villager-info-ui-037`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern) — primary; ADR-0012 (Save/Load Serialization) — the "never serialized" clause
**ADR Decision Summary**: Injected-tier module — typed `@export` refs wired via the owning scene's Inspector, all wiring/validation in an explicitly-callable `setup()`, headless-instantiable via `Node.new()` + mocks with zero scene tree. A leaf consumer owns only its own selection state and **never re-derives another module's data**. Selection is never serialized; save/load never sees this system.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: The panel runs on **raw** delta and stays fully interactive during game pause (values freeze because the simulation halted, not because the panel did). Hiding a `Control` does not pause anything — the Suspended hide is an explicit call on the same signal that hides the rest of the HUD. Cross-check `docs/engine-reference/godot/` before any Control/anchor API (4.5–4.7 post-cutoff, M02 risk R13).

**Control Manifest Rules (this layer)**:
- Required (Presentation): **state over events** — while selected, the panel re-reads upstream state directly **each update frame**; upstream signals (band-change, despawn, distress) are wake/dirty hints and event triggers, **never the source of displayed values**. No cached copies.
- Forbidden: any cached copy of an upstream value; serializing the Selection; a stale panel after despawn or an unresolvable handle; treating the GDD's "right side" parenthetical as authoritative (**Known Conflict 5** — the panel is LEFT, zone Z4).
- Guardrail: **Selection is the ONLY state this system owns.**

---

## Acceptance Criteria

*From GDD `design/gdd/villager-info-ui.md` Rules 3/6 + Edge Cases 1/4/6 and `design/ux/villager-panel.md`, scoped to this story:*

- [ ] A `VillagerInfoUi` injected-tier `Node` exists with typed `@export` dependencies and a `func setup() -> void` that asserts them; it instantiates headlessly via `Node.new()` + mocks with zero scene tree (`TR-villager-info-ui-023`).
- [ ] The panel occupies **HUD zone Z4 — left edge, lower half, grows upward** from a baseline one `ZONE_GAP` above Z7's top edge (`villager-panel.md` Layout Zones; **not** the GDD's parenthetical "right side").
- [ ] Panel layout reads as **minimal-by-design with room to grow** — reserved space and generous whitespace for the MVP's single need bar; never as an incomplete stat sheet (the villager-info-ui UX flag's explicit instruction).
- [ ] Selection is a single value on this module — a stable villager id/handle — and is the **only** state this system owns (`TR-villager-info-ui-010`).
- [ ] **AC17**: Given 20+ mocked villagers, When selecting #1 then #17, Then **exactly one** villager is ever selected and every panel value reflects live upstream state — **mutating the upstream mock directly (bypassing signals) never leaves a stale local copy on reselect** (`TR-villager-info-ui-033`, `TR-villager-info-ui-037`).
- [ ] The panel re-reads upstream state each update frame on **raw delta**; signals are wake/dirty hints only, never value sources (`TR-villager-info-ui-033`).
- [ ] **AC12**: Given pause (mocked), Then click-to-select, panel value updates, and Esc-deselect all still fire on the paused frame — raw delta (Edge Case 4, `TR-villager-info-ui-041`).
- [ ] **AC13**: Given Suspended active with a selection, Then the panel **and** overhead icons are hidden while the selection value **persists unchanged**; When reactivated (complete **or** abort), Then the same villager is selected and the panel restores (Edge Case 6 + state table, `TR-villager-info-ui-038`).
- [ ] **AC14**: Given a selected villager despawn event, Then selection clears gracefully — **no stale panel, no error** (Edge Case 1, `TR-villager-info-ui-040`).
- [ ] **Stale-handle state**: Given a retained selection id that cannot be resolved on reactivation (the `TR-villager-info-ui-010` `[assumption]` failing), Then it is treated **exactly like a despawn** — graceful deselect, panel stays closed, **no error surface** (`villager-panel.md` States & Variants).
- [ ] Panel enter/exit is **instant, same frame** as the triggering event — no slide, no fade (`villager-panel.md` Transitions; GDD Game Feel).
- [ ] Selection is **never serialized** — grep proves it appears in no save path (ADR-0012, `villager-panel.md` Events Fired).
- [ ] The panel container **consumes clicks** — no world-pick through the panel (P2).
- [ ] `villager_selected(id)` / `villager_deselected(previous_id)` UI-internal signals exist (switch = deselect + select); no other events fire, and there are **no analytics events at MVP** (`villager-panel.md` Events Fired).

---

## Implementation Notes

*Derived from ADR-0001's module shape and `villager-panel.md`'s Data Requirements:*

- Mirror the landed injected-tier shape exactly (`CameraInput`, `CommitPipeline`): typed `@export` deps, all wiring in `setup()`, `_ready()` doing nothing beyond optionally calling it. Register in the hosting scene's injected-tier list so `GameWorld._setup_injected_tier()` gates it (ADR-0005).
- Reuse the established Suspended wiring shape verbatim — an OPTIONAL injected `game_world` dependency connected to `transition_begun`/`transition_ended` inside this class's own `setup()`. **Both** `transition_ended(true)` and `(false)` restore; an abort is not a different path.
- **AC17 is the architecture test.** Write the mirror as: on each update frame while selected, call each upstream getter and write the result into the view. If any value is stored between frames, AC17's direct-mutation case fails. That failure mode is the entire reason the AC exists.
- Selection identity: hold the villager id (`VillagerAi.get_villager_id() -> int`), not a node reference — the handle must survive a Suspended round-trip, and a freed node reference cannot.
- **Known Conflict 6**: implement the **four-step** Esc chain (Building UI Rule 14), not the GDD's stale two-step. This story contributes only the "is a villager selected" predicate the chain's step 3 reads; Building UI story 002 owns the chain.
- **Known Conflict 5**: the panel is LEFT. Do not "fix" the GDD's parenthetical in code by placing it right.
- Values freeze during pause because the *simulation* halted — the panel keeps re-reading and keeps rendering the same numbers. Do not add a pause branch.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the villager hit query, the selection rules, and the Idle-only/tool-arm gating.
- Story 003/004: the panel's actual content.
- Story 005: overhead distress icons (this story only asserts they hide with the panel on Suspended).
- Story 006: hover affordance and selection outline.

---

## QA Test Cases

- **AC17**: Given 20 mocked villagers, select #1, mutate #1's upstream mock **without emitting**, re-read on the next frame, Then the panel shows the mutated value; select #17, re-select #1, Then still the mutated value — no stale copy.
- **Single selection**: Given a randomized sequence of 100 select calls, Then exactly one id is ever held after each.
- **AC12**: Given a mocked paused Time & Tick, When a select and then an Esc-deselect fire on the same paused frame, Then both resolve.
- **AC13**: Given a selection and Suspended entered, Then the panel is hidden and `get_selection()` is unchanged across N frames; on `transition_ended(true)`, Then the panel is visible with the same id; repeat with `(false)` — identical result.
- **AC14**: Given a despawn event for the selected id, Then `get_selection()` is empty, the panel is hidden, and zero errors/warnings were pushed.
- **Stale handle**: Given reactivation with an unresolvable id, Then identical behavior to despawn — assert no error surface was rendered.
- **Serialization grep**: Given the module source and any save path, When grepped, Then the selection field appears in no serializer.
- **Click consumption**: Given a click inside the panel rect, Then the world-pick query was not invoked.

---

## Test Evidence

**Story Type**: Integration (DI + mirror loop + Suspended lifecycle) — **BLOCKING** (state-machine logic per `.claude/docs/coding-standards.md`).
**Required evidence**: `neues-spiel/tests/unit/ui/villager_panel_scaffold_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: `building-ui` story 001 (the HUD host and Z4/Z7 zone system this panel docks into).
- Unlocks: 002, 003, 004, 005.
