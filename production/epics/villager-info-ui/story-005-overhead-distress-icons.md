# Story 005: Overhead distress icons — one manager, N billboards

> **Epic**: Villager Info UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-info-ui.md`
**UX Spec**: `design/ux/villager-panel.md` (World-space companions — **full billboard** decision) · `design/ux/hud.md` (element E10, P13)
**Requirement**: `TR-villager-info-ui-034`, `TR-villager-info-ui-035`, `TR-villager-info-ui-042`, `TR-villager-info-ui-045`, `TR-villager-info-ui-038`, `TR-villager-info-ui-027`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern)
**ADR Decision Summary**: One injected-tier manager owns all N icons — the same "one manager, one iteration, never N independent subscriptions" pattern Building UI's Edge Case 6 established. Distress flags are **state-derived conditions, not pulses**, so the manager derives visibility each update rather than reacting to events.

**Engine**: Godot 4.7-stable | **Risk**: **HIGH — substrate missing**
**Engine Notes**: **⚑ Known Conflict 1** — villagers have no `Node3D` body to parent an icon to and no public interpolated world position (`_visual_position` is private; only `get_current_cell() -> Vector3i` is public, and it is deliberately the discrete cell). **Icon mode is decided**: **full billboard** (user decision 2026-07-11 — always camera-facing, equally readable at every orbit pitch 0.15–1.5 rad; readability outranks physicality for a distress signal). This **resolves `TR-villager-info-ui-027` / GDD Open Question 5**. Verify billboard-mode flags against `docs/engine-reference/godot/` — 4.7 changed HDR output and material handling.

**Control Manifest Rules (this layer)**:
- Required (Presentation): **ONE manager drives all N icons** — one Suspended signal hides all, one iteration, never N independent subscriptions.
- Forbidden: **permanent mood icons over heads** (the panel is where mood lives, Pillar 4 calm); a third "no-bed" icon state; per-villager signal subscriptions; hue-only differentiation.
- Guardrail: **only genuine distress earns an icon** — trapped and ground-sleeping, nothing else.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-info-ui.md` Rule 4 + Edge Cases 5/6/9/10, scoped to this story:*

- [ ] **AC10**: Given a mocked distress flag set on **any** villager (selected **or not**), Then its overhead icon activates; When cleared, Then it deactivates (Rule 4, `TR-villager-info-ui-034`).
- [ ] Icons show for exactly two conditions — **trapped** and **ground-sleeping** (Villager AI Edge Case 2 / Rule 12) — and disappear when the cause resolves.
- [ ] **AC25 (the no-bed fold, negative half)**: Given a mocked **bedless villager who is AWAKE and not distress-flagged**, When rendered, Then **no overhead icon shows**; When their sleep turns urgent and they ground-sleep, Then the ground-sleeping icon activates (`TR-villager-info-ui-034`).
- [ ] **"No-bed" is deliberately NOT a third icon state** (user decision 2026-07-11): chronic bedlessness has no awake-limbo state — Villager AI Rule 12 transitions urgent-sleep → ground-sleep **same-tick** — so bedlessness becomes visible as ground-sleeping exactly when it matters, and the panel's why-string still names the precise cause verbatim.
- [ ] **AC11 (shared source)**: Given a distressed villager selected, Then the overhead icon and the panel's C5 flag derive from the **same** signal — they can never disagree (Edge Case 5, `TR-villager-info-ui-042`).
- [ ] **ONE manager drives all N icons**: a single Suspended signal hides all of them in one iteration; there are **zero** per-villager signal subscriptions (`TR-villager-info-ui-035`).
- [ ] **AC13 (icon half)**: Given Suspended, Then all overhead icons hide with the panel; on reactivation (complete **or** abort), Then they restore per current state (`TR-villager-info-ui-038`).
- [ ] Icons are **full billboards** — always camera-facing, verified readable at orbit pitch **0.15 rad and 1.5 rad** (`AC-UX9`, `TR-villager-info-ui-027`).
- [ ] Icons are differentiated by **shape + tooltip label**, never hue alone, and are **gentle, cozy-not-alarming** per Pillar 3 (`TR-villager-info-ui-045`).
- [ ] Icons are **static — no pulse** at MVP (A5 motion restraint).
- [ ] **Edge Case 9 accepted**: overhead icons may overlap at distance for many distressed villagers — accepted in MVP; clustering is VS+. Record the acceptance, do not build clustering.
- [ ] **Edge Case 10 accepted**: an icon may be occluded by the bottom toolbar — accepted in MVP; the panel and warnings still surface the problem. Record the acceptance.
- [ ] **Flicker**: distress flags are **state-derived conditions, not pulses**, so flicker is not expected. If playtest shows boundary flicker, a **hold-time knob** is the remedy (GDD Open Question 7) — do **not** add one preemptively.
- [ ] Icons remain visible while **Unselected** — the panel's absence never hides them (state table).

---

## Implementation Notes

*Derived from Rule 4's implementation note and the landed distress surface:*

- **⚑ Known Conflict 3 is this story's functional gate.** Landed `VillagerAi.is_distressed() -> bool` is **one boolean**, set by the unstuck-watchdog path (`villager-ai-015`) — the *trapped* half only. **Ground-sleeping does not exist**: it depends on `villager-ai-018` (sleep & home / bed claim), which is Cluster A and not landed. Therefore AC25's positive half and the two-cause differentiation are **not implementable today**. Build against an injected two-flag distress provider and mark those ACs blocked; do not collapse the two causes into one icon to make the story pass — that would silently delete the design decision.
- **⚑ Known Conflict 1 is the anchoring gate.** There is no `Node3D` villager body and no public interpolated world position. The manager needs both. Until they land, drive the manager's *logic* (which villagers should have an icon, the one-iteration Suspended hide, the shared-source guarantee) against a mocked renderable-position provider — that logic is the story's blocking evidence anyway.
- **The manager is a pooled iteration, not N nodes with N subscriptions.** Keep a pool of billboard `Sprite3D`/`MeshInstance3D` overlays sized to the active-distress count; each update, iterate the villager set once, derive `should_show`, and reposition/toggle from the pool. This is the same shape Building UI's Edge Case 6 established, and it is what `TR-villager-info-ui-035` is asking for.
- **One source, two renders** (AC11): the panel's C5 and the overhead icon must read the *same* accessor. The cleanest proof is a single query method both call — assert the call site count, not just matching output.
- Full billboard means camera-facing on **both** axes, not Y-locked — the decision explicitly chose readability over physicality. Record the flag/mode used so story 007's pitch check has something to verify.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the panel's C5 flag and the why-slot (this story only asserts the shared source).
- Story 006: hover affordance and selection outline (different world-space overlays, different trigger).
- Story 007: the 0.15/1.5 rad readability capture and the grayscale pass.
- Distress-icon **clustering** (VS+), a flicker **hold-time knob** (only if playtest shows it), and **proactive distress alerting** at population scale (GDD OQ6, VS revision).
- Creating the ground-sleeping flag — `villager-ai-018` (Cluster A).

---

## QA Test Cases

- **AC10**: Given a mocked flag set on an **unselected** villager, Then its icon is active; clear it, Then inactive — assert with no selection at any point.
- **AC25 (negative)**: Given awake + bedless + no distress flag, Then zero icons active.
- **AC25 (positive, blocked)**: Given ground-sleeping true, Then the ground-sleeping icon is active — mark blocked on `villager-ai-018`.
- **Two causes**: Given trapped=true/ground=false and then the inverse, Then the active icon's shape id differs between the two runs.
- **AC11**: Given one mocked distress source, Then the panel flag and the overhead icon both resolve from it; mutate it once, Then both change in the same frame.
- **One manager**: Given 30 mocked villagers with 12 distressed, When Suspended fires **once**, Then all 12 icons hide; assert the villager set was iterated once and zero per-villager connections exist.
- **AC13**: Given Suspended then `transition_ended(false)`, Then icons restore per current state — an abort is not a different path.
- **No mood icons**: Given the module source, When grepped, Then no mood-band icon is instantiated in world space.

---

## Test Evidence

**Story Type**: Integration — the visibility derivation, single-source guarantee and one-manager iteration are **BLOCKING**; billboard readability and appearance are **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/distress_icon_manager_test.gd` — must exist and pass.
**Required evidence (advisory)**: folded into `production/qa/evidence/villager-info-ui-007-presentation-evidence.md` (story 007) — pitch 0.15/1.5 rad captures and the grayscale pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 002, 004; **Known Conflict 1** (villager body + public world position — technical-director) and **Known Conflict 3** (two distinct distress flags; ground-sleeping needs `villager-ai-018`, Cluster A).
- Unlocks: 006.
