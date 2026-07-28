# Story 011: Projects Panel — cards, per-state actions, progress & workers

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md`
**UX Spec**: `design/ux/projects-panel.md` (**the production decision** — Layout, Per-State Actions, Status Communication, Empty & Edge States, AC-UX1–12)
**Requirement**: `TR-building-ui-086`, `TR-building-ui-088`, `TR-building-ui-077`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle)
**ADR Decision Summary**: A project is a **persistent entity** with a real lifecycle (Draft → Building ⇄ Paused → Done, plus demolition). This panel is a **pure renderer/router**: it reads project state, progress and `worker_ids` and routes release/pause/resume/cancel intents into Building System's public surface, owning no project state itself. `worker_ids` is **read/display + save-state only, NEVER a control channel** — no scheduling, claiming or lifecycle transition may branch on it.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Progress `X/Y` uses **tabular (fixed-width) numerals** (Art Bible §7.2) because it is re-read every refresh and must not jitter width. Panel show/hide is an **instant swap** — Art Bible §7.4's *Never animates* table lists panels explicitly, so this panel does **not** inherit the toast's ≤0.2 s retire fade. Cross-check `docs/engine-reference/godot/` before any `ScrollContainer`/theme API.

**Control Manifest Rules (this layer)**:
- Required (Presentation): every card value is re-queried from Building System's project entities each refresh — signals are wake/dirty hints, never cached truth. Clicking a card selects that project **identically** to clicking one of its world cells.
- Forbidden: this UI owning project state; branching any behavior on `worker_ids`; a confirmation modal on any destructive action (see the spec's Confirmation Policy — the pattern library has no confirmation-dialog pattern, P6 is explicit that feedback is "never modal"); listing a demolition step in undo.
- Guardrail: the world outline and the card highlight are two renders of **one** Selection, never two independent states.

---

## Acceptance Criteria

*From GDD Rule 21 + `design/ux/projects-panel.md`, scoped to this story:*

- [ ] **AC-UX1**: Z7 is **fully hidden** when zero project entities exist — no chrome, no empty-state placeholder — and appears the same frame the first Draft project is created (mirrors the "zero issues → Z2/Z3 fully hidden" rule).
- [ ] **AC66**: Given a project transitions between lifecycle states (Draft / Building / Paused / Done / Done+pending / **Demolishing**), Then its card's status text and available action buttons update to match exactly that state, **same frame** (`TR-building-ui-086`).
- [ ] Card content follows the spec's hierarchy in reading order: **kind icon + name → status (icon + label, + pending-changes badge) → progress `X/Y` + bar → workers → action buttons** (bottom-anchored, primary left / secondary right).
- [ ] **AC67**: Given a project with 0 of Y cells built, Then the progress readout renders `0/Y`; given Y of Y, Then `Y/Y` and the status reflects completion — **no easing on the bar**, raw value every frame (`TR-building-ui-086`, Art Bible §7.2/§7.4).
- [ ] Per-state buttons match the spec's table exactly: **DRAFT** → *Bau starten* / *Verwerfen*; **BUILDING** → *Pause* / *Abbrechen* (+ *Bau starten* if a pending change-order batch exists); **PAUSED** → *Fortsetzen* / *Abbrechen* (+ *Bau starten* if pending); **DONE settled** → *Abriss*; **DONE + pending** → *Bau starten* / *Abriss*; **Demolishing** → **no buttons at all**.
- [ ] **Demolishing** hides — does not freeze — the progress bar, count and workers row; a stale `12/12` during teardown would misreport reality (spec's explicit call).
- [ ] Workers row is visible **only** in BUILDING; names wrap to a second line, **never truncated, never an ellipsis**; **AC-UX12**: a BUILDING project with zero current claims shows the *"Wartet auf Arbeiter"* placeholder rather than a blank row.
- [ ] **AC-UX9**: Clicking any of *Bau starten* / *Verwerfen* / *Pause* / *Abbrechen* / *Fortsetzen* / *Abriss* resolves with **NO confirmation dialog**, and the card's status updates the same frame the click resolves.
- [ ] **AC48/AC49 render half**: a world click on a project cell highlights its card (Hearth Gold, 2 px border) **and scrolls it into view** the same frame; a card click renders the identical world outline (`TR-building-ui-086`).
- [ ] **AC-UX10**: A project demolished or fully canceled **while selected** clears the Selection gracefully — card and outline disappear instantly, no error surface, no toast (the documented way a project's lifetime ends, not a bug state).
- [ ] **AC-UX11**: With the game **paused**, select / release / pause / resume / cancel all work normally (P7/P14 parity — the HUD is raw-delta).
- [ ] **AC-UX7**: Every card state remains distinguishable in a **grayscale** pass — shape + label carry the state; the "Im Bau" gold and "Wird abgerissen" orange text are secondary reinforcement only (A1).
- [ ] **AC-UX8**: All card text (name, status, workers) wraps fully visible at **1280×720** with no truncation and no overflow outside the card bounds.
- [ ] **AC69 (render half)**: no card, button, or tooltip in this panel ever offers an "undo this demolition" affordance (`TR-building-ui-088`).
- [ ] A click inside the panel's non-interactive area is consumed — no world-pick through the panel (P2).

---

## Implementation Notes

*Derived from `design/ux/projects-panel.md` and the landed `BuildProject`/`BuildProjectRegistry`:*

- **⚑ Known Conflict 4 is this story's gate, and it is a cut-lever hazard — escalate before scheduling.** Landed `BuildProject.ProjectState` is exactly `{DRAFT, BUILDING, PAUSED, DONE}`: **no Demolishing state, no demolishing flag, no pending-change-order concept**. `BuildProjectRegistry` exposes only `release_project()` — **`pause_project()` and `queue_demolition()` do not exist**. Those calls live in `building-006` (pause/resume, **Cluster C tier C3**) and `building-010` (Abriss, **Cluster C tier C4**), both on the cut lever, both trimmed **before** Cluster D. If the lever is pulled as written, this panel's *Pause* / *Fortsetzen* / *Abriss* buttons have no backing call. Producer/user decision required — do not resolve inside this story.
- **Progress must be derived.** There are no `built_cells`/`total_cells` accessors. Compute from `get_cells()`'s `BlueprintCell.MicroState` distribution and cache per refresh, not per card-child.
- **Names must be generated.** `BuildProject` has no `name` field. Generate from `kind` + `id` per the spec (`"Haus %d"` / `"Abbau %d"` / `"Projekt %d"`) as UI-owned chrome text, and commit to the **wrap-not-ellipsis** rule now so player renaming can land later without a layout redesign.
- Refresh on `projects_changed` (the spec's named trigger) and re-query — never incrementally patch a cached card model. `worker_ids` names resolve through a Villager AI lookup, the same pattern the villager panel uses for identity.
- Status **shape** proposals (dashed square / filled triangle / pause bars / filled circle / circle+`+` / orange square with diagonal strike) are **NOT final** — Art Bible §7.3 owns the shared assignment table and the first icon pass must reconcile them against toast, mood, tool-state, distress and dig-marker icons so no two unrelated states share a silhouette (spec OQ8).
- Z7's provisional envelope is 260×320 px; exact dimensions lock at implementation against the final font (the same deferral both sibling specs use). Z7 must never grow into the center third.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 012: the bounded visible count, priority sort, overflow summary row, and the Selection Pin exception. **This story ships a flat list** — story 012 makes it scale.
- Story 010: what a Selection *is* (this story renders it).
- `building-006` / `building-010`: the lifecycle calls themselves (Cluster C).
- Story 018: final icon art, the grayscale evidence pass, and the `hud.md` Z7 follow-up edit (projects-panel.md OQ1).

---

## QA Test Cases

- **AC-UX1**: Given zero projects, Then Z7 has no visible children and occupies no layout space; Given one Draft created, Then the panel is visible in the same frame.
- **AC66**: Given a mocked project stepped through DRAFT → BUILDING → PAUSED → BUILDING → DONE, Then after each step the status label and the exact button set match the spec's table.
- **AC67**: Given 0/12 then 12/12, Then the rendered count strings are `0/12` and `12/12` and the bar's fill ratio equals the raw quotient with no interpolation across frames.
- **Demolishing**: Given the demolishing flag set, Then the progress bar, count and workers row are absent (not zeroed) and the button row is empty.
- **AC-UX12**: Given BUILDING with `worker_ids == []`, Then the workers row renders "Wartet auf Arbeiter".
- **Workers wrap**: Given 5 worker names totalling > one line, Then the row occupies two lines and the full text is present — assert no ellipsis character anywhere.
- **AC-UX10**: Given the selected project deleted, Then Selection kind is NONE, no card remains, and no error/warning was pushed.
- **AC-UX11**: Given a mocked paused Time & Tick, Then a *Bau starten* click still routes `release_project()` and the status updates.
- **Attribution guard**: Given the UI module source, When grepped, Then `worker_ids` appears only in display code — zero branches on it.

---

## Test Evidence

**Story Type**: Integration — the state→content/button mapping, progress derivation and Selection reciprocity are **BLOCKING**; layout, grayscale and wrap checks are **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/projects_panel_cards_test.gd` — must exist and pass.
**Required evidence (advisory)**: `production/qa/evidence/building-ui-011-projects-panel-walkthrough.md` — one screenshot per card state at 1280×720 + a grayscale pass (AC-UX7/AC-UX8, GDD advisory AC29).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (Z7 zone), 010 (Selection); `building-003`/`004`/`005` (project registry, lifecycle, worker attribution); **Known Conflict 3** (registry hosting) and **Known Conflict 4** (missing lifecycle states/calls — **producer escalation**).
- Unlocks: 012.
