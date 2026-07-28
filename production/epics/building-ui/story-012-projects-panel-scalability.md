# Story 012: Projects Panel scalability — priority sort, overflow row, selection pin

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/projects-panel.md` (**Scalability: Bounded Visible Count + Overflow**, AC-UX4/AC-UX5)
**Requirement**: `TR-building-ui-086`, `TR-building-ui-037`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — the states being ranked; ADR-0002 — the cap knob
**ADR Decision Summary**: Project state is Building System's; this panel ranks and bounds its *presentation* only. The cap is a typed `@export` on `BuildingUiConfig` (`projects_panel_max_visible_cards`, proposed default **6**), never a literal.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Card-list reflow (cards reordering as tier/recency changes, overflow promotion/demotion) is an **instant re-layout — no slide, no reorder animation** (Art Bible §7.4, "speed over ornament"). The within-cap scroll inherits the slice's `ScrollContainer` + `ensure_control_visible` behavior.

**Control Manifest Rules (this layer)**:
- Required (Presentation): cap by **priority**, never by an arbitrary category rule — the same structural idea as the toast stack's `toast_max_visible` + issues-anchor overflow.
- Forbidden: unbounded panel growth; Z7 entering the center third; silent truncation of the *list* (only individual long names wrap); violating priority order when draining into overflow.
- Guardrail: **the game never hides the thing the player is currently looking at** — the selected project is always a full card.

---

## Acceptance Criteria

*From `design/ux/projects-panel.md` Scalability, scoped to this story:*

- [ ] Sort order is **tier first, then recency within tier**: (1) BUILDING, (2) PAUSED, (3) DRAFT, (4) DONE + pending change order, (5) DONE settled. Within a tier, **most-recent state-transition first** — not creation order.
- [ ] **AC-UX4 (no-pressure half)**: With the project count **at or below** `projects_panel_max_visible_cards`, **no overflow row renders at all** — mirroring "zero issues → anchor fully hidden".
- [ ] **AC-UX4 (overflow half)**: Once the count exceeds the cap, the panel renders the top `(max_visible_cards − 1)` cards by the sort order and bundles the remainder into exactly **one** *"+N weitere · Fertig ▸"* summary row at the list's bottom.
- [ ] The remainder always drains from the **lowest-priority tier first** (settled DONE), then upward through the tiers only if settled DONE alone cannot fill the overflow — priority order is never violated.
- [ ] The overflow row expands (B3 List pattern, same mechanism as the issues anchor) into a compact secondary list: **name + kind icon + status only** — no progress bar, no workers row.
- [ ] **AC-UX5 (Selection Pin)**: The currently-selected project **always** renders as a full card, even if its tier/recency rank would place it in the overflow bundle. Selecting an overflowed project (by clicking one of its world cells) promotes it to a pinned full card, **scrolls it into view**, and bumps the next-lowest-priority visible card into the overflow bundle instead.
- [ ] **DONE + pending change order never collapses into overflow** — pending changes make it actionable (spec's Per-State table).
- [ ] Within-cap scrolling still works for the visible, non-overflowed cards — scrolling and the overflow bundle are **complementary, not competing** mechanisms.
- [ ] `projects_panel_max_visible_cards` comes from `BuildingUiConfig`, default 6 — never a literal (`TR-building-ui-037`).
- [ ] Z7's height stays hard-bounded and never grows into the center third of the screen at any project count (hud.md Visual Budget invariant).
- [ ] Expanding/collapsing the overflow row causes **no Selection change**.
- [ ] Esc collapses an **expanded, focused** overflow row as chain step 1 (joining the issues anchor's routing, P11) and does **not** clear the Selection in that press.

---

## Implementation Notes

*Derived from `design/ux/projects-panel.md`'s Scalability section:*

- Implement ranking as a **pure comparator** over `(tier, last_transition_tick, id)` so AC-UX4/AC-UX5 are testable without any Control. `last_transition_tick` is not a landed field — track it in this UI as presentation state derived from `projects_changed` refreshes (it is ordering, not simulation truth), or request it from building-system if a save-stable ordering is ever needed. Record which choice was made.
- The Selection Pin is applied **after** ranking and capping: rank → take top `(cap − 1)` → if the selected project is not in that set, swap it in for the lowest-ranked visible card. One pass, not a special case scattered through the layout code.
- `+N weitere` counts the bundled remainder, not the total. The label's "· Fertig" suffix is accurate only while the bundle is all-settled-DONE; if the bundle has drained upward into higher tiers, the suffix must reflect that rather than lie. Decide the alternate string and record it — the spec does not specify this case.
- **Candidate pattern-library entry** (flagged in the spec, not this story's job to add): "cap by priority, pin the selected item, drain the lowest tier into an expandable overflow row" is generic enough to outlive this panel. Note it for `interaction-patterns.md` at close; do **not** edit that library here.
- This whole story is on the **polish tail**. Under Cut-Lever step 5 the panel falls back to story 011's flat list — make sure 011 stands alone without this story's code.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 011: card content, per-state buttons, progress, workers.
- Story 015: the issues anchor's own expand/collapse (this story only mirrors its List pattern).
- Editing `design/ux/interaction-patterns.md` or `design/ux/hud.md` (the Z7 Visual-Budget follow-up is projects-panel.md OQ1, owned by the ux-designer).

---

## QA Test Cases

- **Sort**: Given one project per tier plus two BUILDING with different last-transition times, When ranked, Then the order is BUILDING(newest), BUILDING(older), PAUSED, DRAFT, DONE+pending, DONE.
- **AC-UX4**: Given cap 6 and 6 projects, Then 6 full cards and zero overflow rows; Given 7, Then 5 full cards + one overflow row reading "+2 weitere".
- **Drain order**: Given cap 6, 4 settled-DONE and 5 BUILDING, When capped, Then all 4 settled-DONE plus the lowest-ranked BUILDING are bundled — never a BUILDING bundled while a settled DONE is visible.
- **AC-UX5**: Given a settled-DONE project ranked last and 10 projects total, When it is selected, Then it renders as a full card, the previously-lowest visible card moved to the bundle, and the total visible card count is unchanged.
- **Pending never collapses**: Given 10 projects including one DONE+pending ranked below the cap, Then it is still a full card.
- **Expand**: Given the overflow row expanded, Then each secondary entry has name + kind icon + status and **no** progress bar or workers row; Selection is unchanged.
- **Esc**: Given the overflow row expanded and focused **and** an active Selection, When Esc fires, Then the row collapses and the Selection is unchanged.
- **Bounds**: Given 50 projects, Then Z7's rect height is unchanged and does not intersect the center third.

---

## Test Evidence

**Story Type**: Logic (pure ranking/capping/pinning rules) — **BLOCKING**.
**Required evidence**: `neues-spiel/tests/unit/ui/projects_panel_scalability_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 010 (Selection), 011 (cards).
- Unlocks: —
