# Story 006: Hover affordance & selection outline

> **Epic**: Villager Info UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-info-ui.md`
**UX Spec**: `design/ux/villager-panel.md` (World-space companions, Interaction Map, AC-UX8) · `design/ux/hud.md` (item 10 — hover affordance + selection outline; 10b cursor states)
**Requirement**: `TR-villager-info-ui-046`, `TR-villager-info-ui-047`, `TR-villager-info-ui-048`, `TR-villager-info-ui-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0004 (Physics Backend & Picking Strategy) — the hover query is the same dedicated villager query the click uses
**ADR Decision Summary**: Villager hit-testing is a dedicated query on a dedicated villager collision layer, never consulted by the block pick. Hover and click therefore share **one** query — hover is that query run on cursor movement, not a second mechanism.

**Engine**: Godot 4.7-stable | **Risk**: **HIGH — substrate missing**
**Engine Notes**: **⚑ Known Conflict 1** — there is no villager body to outline. The outline **mechanism** is explicitly delegated to `godot-shader-specialist` at implementation (`TR-villager-info-ui-047`); the hover pre-glow is a **reduced-intensity reuse of the selection shader**, not a second effect. Selection outline color is Hearth Gold `#F5A83C`. Cross-reference `docs/engine-reference/godot/` before any outline/stencil/inverted-hull approach — 4.7 changed HDR output.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the pre-click hover affordance is a **required deliverable, not optional polish** — without it the "curiosity test" bets on blind discovery (the UX flag's explicit instruction).
- Forbidden: a second outline mechanism for hover (it is the selection shader at reduced intensity); the hover query running while the shared hover-suppression flag is active; a hover **sound** (MVP convention: no hover sounds).
- Guardrail: hover and selection share **one** villager query — never two.

---

## Acceptance Criteria

*From GDD Visual/Audio Requirements and `design/ux/villager-panel.md`'s World-space companions, scoped to this story:*

- [ ] **AC-UX8**: Hovering a selectable villager shows the **"inspect" cursor AND the outline pre-glow on the same frame**; **both clear** when the cursor leaves (`TR-villager-info-ui-046`).
- [ ] The hover affordance is the **reduced-intensity reuse of the selection shader** (a faint outline pre-glow), not a separate effect (`villager-panel.md` World-space companions).
- [ ] A selected villager shows a **full-intensity outline in Hearth Gold `#F5A83C`** (`TR-villager-info-ui-047`).
- [ ] Hover and selection outlines are mutually consistent: hovering the already-selected villager does not stack or dim the selection outline.
- [ ] The hover query honors the **shared hover-suppression flag** — while the cursor is over any HUD element, no hover affordance appears on a villager rendered behind it (`TR-villager-info-ui-002`, story 002's gate).
- [ ] Hover affordance appears **only in Idle** (no build tool armed) — the same niche selection occupies; while a tool is armed the ghost preview owns the cursor's meaning (Rule 1).
- [ ] **A soft select sound plays on selection** and nothing else — a **distress-onset audio cue is deferred** to the audio spec (GDD Open Questions) (`TR-villager-info-ui-048`).
- [ ] The select sound's visible counterpart is the panel opening itself — the panel is fully usable **muted** (A6).
- [ ] **No hover sound** (MVP Sound Standards convention).
- [ ] The outline is an **overlay** — it never writes into any committed world-geometry material.
- [ ] Both affordances hide with the rest of the HUD on **Suspended**.
- [ ] The mechanism choice (stencil / inverted hull / post-process) is recorded in the story at implementation, with `godot-shader-specialist` sign-off against the pinned 4.7 docs.

---

## Implementation Notes

*Derived from `villager-panel.md`'s World-space companions and the shared query rule:*

- **⚑ Known Conflict 1 blocks the visual half entirely.** `VillagerAi extends Node` with no mesh, no collider, and no public interpolated world position — there is nothing to outline and nothing to hover. Resolve the villager-body decision (technical-director + godot-specialist) before this story starts. The *logic* half (when should hover show, gate honoring, one-query sharing, sound triggering) is testable headlessly against a mocked hit provider today.
- **One query, two triggers.** Run the same villager hit query on cursor-move (hover) and on click (select). A second query path is how AC-UX8's "same frame" and story 002's tie rules silently diverge.
- Reduced-intensity pre-glow means **one shader with an intensity parameter**, not two shaders. Record the two intensity values as presentation constants.
- The "inspect" cursor is a `DisplayServer`/`Input.set_custom_mouse_cursor` change; make sure it is reverted on every exit path (cursor leaves, tool arms, Suspended, HUD hover) — a stuck cursor is the classic failure here.
- Hearth Gold `#F5A83C` is the shared highlight color across the HUD (art-bible §4.5) and is the **same** color the Projects Panel's selection border uses — one selection language, two subjects.
- Reuse `building-ui` story 007's `is_hover_suppressing_world_pick()`; do not re-derive HUD hover from cursor coordinates.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the hit query itself and the click/selection rules.
- Story 005: overhead distress icons (a different world-space overlay with a different trigger).
- Story 007: the readability/grayscale evidence captures and the curiosity-test playtest.
- Creating the villager body/collider — technical-director + villager-ai (Known Conflict 1).
- A distress-onset audio cue (deferred to the audio spec).

---

## QA Test Cases

- **AC-UX8**: Given a mocked hover hit on villager 3, Then within the same frame the cursor state is "inspect" and villager 3's pre-glow intensity is the reduced value; move off, Then both revert in the same frame.
- **Gate**: Given the shared hover-suppression flag true and a hover hit behind the HUD, Then no cursor change and no pre-glow.
- **Idle-only**: Given a tool armed and a hover hit, Then no cursor change and no pre-glow.
- **Selection intensity**: Given villager 3 selected, Then its outline intensity is the full value; hover it, Then the intensity is unchanged (no stacking).
- **One query**: Given the module source, When grepped, Then exactly one villager-hit query call site feeds both hover and click.
- **Sound**: Given a selection, Then exactly one select sound played; given a hover, Then zero sounds.
- **Cursor revert**: exercise each exit path (cursor leaves, tool arms, HUD hover, Suspended) and assert the cursor returned to default in every one.
- **Overlay guard**: Given the module source, When grepped, Then zero writes to a chunk mesh's `material_override`.

---

## Test Evidence

**Story Type**: Integration — the trigger/gating/one-query logic and the sound-count rules are **BLOCKING**; the rendered outline and cursor appearance are **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/villager_hover_and_outline_test.gd` — must exist and pass.
**Required evidence (advisory)**: folded into `production/qa/evidence/villager-info-ui-007-presentation-evidence.md` (story 007) — hover/selected/unselected capture triptych.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002 (the shared query), 005 (world-space overlay host); `building-ui` story 007 (the shared gate); **Known Conflict 1** — the villager body decision; `godot-shader-specialist` for the outline mechanism.
- Unlocks: 007.
