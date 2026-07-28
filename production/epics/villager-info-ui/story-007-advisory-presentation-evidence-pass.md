# Story 007: Advisory presentation evidence pass

> **Epic**: Villager Info UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~0.5 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-info-ui.md` (**Advisory** AC block: AC18–20; Game Feel)
**UX Spec**: `design/ux/villager-panel.md` (Acceptance Criteria AC-UX1–AC-UX10, Accessibility, Localization Considerations)
**Requirement**: `TR-villager-info-ui-044`, `TR-villager-info-ui-045`, `TR-villager-info-ui-046`, `TR-villager-info-ui-041`, `TR-villager-info-ui-027`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: — (no decision-owning ADR; this story produces evidence against already-implemented behavior)
**ADR Decision Summary**: n/a — the governing authorities are `design/ux/villager-panel.md`'s AC-UX block and `design/ux/accessibility-requirements.md` A1–A7.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: The grayscale (A1) pass is a screenshot post-process, not an engine feature — capture at native color and desaturate offline so the evidence is reproducible. Pitch captures must be taken at the camera's actual clamp bounds (0.15 and 1.5 rad).

**Control Manifest Rules (this layer)**:
- Required (Presentation): mood-band icons and the distress icon are differentiated by **shape + label/tooltip, never hue alone**; the panel is fully usable **muted** (A6).
- Forbidden: closing an advisory AC with an assertion instead of an artifact; passing A3/A4 against an interim font without flagging the re-measure.
- Guardrail: **the curiosity test is the panel's reason to exist** — a first-time player clicks a villager unprompted and can afterwards say how it is doing and why.

---

## Acceptance Criteria

*From GDD's Advisory AC block + `design/ux/villager-panel.md`'s AC-UX block, scoped to this story:*

- [ ] **AC-UX1**: The panel opens on the **SAME frame** as the selecting click (frame-capture check) and closes instantly on deselect.
- [ ] **AC-UX2**: The need bar renders correctly at value **0** and value **100** — fill, raw number, no easing.
- [ ] **AC-UX3**: Esc with a focused HUD element releases that focus **WITHOUT** closing the panel; a second Esc (no HUD focus) deselects — two-step routing, captured as a sequence.
- [ ] **AC-UX4**: The why-slot is hidden when mood is Happy and no need is urgent; otherwise it shows the upstream string verbatim.
- [ ] **AC19 / AC-UX5**: A 3+-line why-string **wraps fully visible at 1280×720** — no truncation, no overflow outside the panel (`TR-villager-info-ui-044`).
- [ ] **AC-UX6 / A1 grayscale pass**: all mood-band states **and** the distress state remain distinguishable with saturation removed (`TR-villager-info-ui-045`).
- [ ] **AC-UX7 / A3–A4**: all panel text ≥ **16 px** (name/why/labels ≥ **18 px**) at 1080p and meets **4.5:1** contrast on the final theme. If the font/theme is still open (`hud.md` OQ2, art-director), record against the interim theme and **flag the re-measure** rather than passing.
- [ ] **AC-UX8**: Hovering a selectable villager shows the inspect cursor **AND** the outline pre-glow on the same frame; both clear when the cursor leaves (`TR-villager-info-ui-046`).
- [ ] **AC-UX9**: The overhead distress icon is readable at **minimum and maximum camera pitch** — full-billboard check at **0.15 and 1.5 rad** (`TR-villager-info-ui-027`).
- [ ] **AC-UX10 / AC12**: With the game **paused**: select, switch, value display, and Esc-deselect all work normally (`TR-villager-info-ui-041`).
- [ ] **AC18**: Given a live viewport, When a villager walks behind the toolbar, Then the **accepted occlusion** is documented (Edge Case 10) — recorded as accepted, not filed as a bug.
- [ ] **Edge Case 9 recorded**: overlapping icons at distance for many distressed villagers — accepted in MVP, clustering VS+.
- [ ] **AC20 (the curiosity test)**: Given a **first-time playtester**, Then they click a villager **unprompted within their first minutes** and can afterwards state how the villager is doing and why (GDD Game Feel).
- [ ] **Localization budget**: the activity-label column verified to fit **≥ 20 characters** against the final font; any translation exceeding it is flagged for editorial shortening, never auto-truncation.
- [ ] **A2 exemption recorded**: mouse-only villager selection is a **stated, tracked MVP exemption**, listed as such in the evidence doc — not as a failure. The panel itself contains no focusable elements at MVP, so no focus-order requirement applies; Esc-deselect works without the mouse.
- [ ] **A5**: zero panel animation and a static (no-pulse) overhead icon — verified over a 60 s capture.

---

## Implementation Notes

*Derived from the GDD's Advisory block and `villager-panel.md`'s AC-UX block:*

- **This story is pure evidence — it implements nothing.** Its output is one consolidated document plus its screenshots.
- **AC20 is the epic's real acceptance criterion.** Run it as part of M02 risk **R8**'s external silent walkthroughs (1–2, scheduled *after* milestone criterion #5 lands — the first moment the loop pays off). Do **not** self-test it; the whole value is a naive observer who was never told the panel exists.
- Capture everything at **1280×720**, the tightest supported layout. A check that passes at 1440p and fails at 720p is not evidence.
- **AC-UX9's pitch bounds are the camera's actual clamps** — read them from `CameraInputConfig` rather than assuming 0.15/1.5, and record the values used.
- AC-UX1's "same frame" is best captured with a two-frame capture pair (pre-click, post-click) rather than a stopwatch.
- The two accepted edge cases (9 and 10) need an explicit "accepted, not a defect" line each — otherwise a later QA pass re-files them as bugs. That has happened on this project before with silently-deferred items.
- Note for the ux-designer at close (not this story's edit): `hud.md` still needs the Z7 row + E-number follow-up (projects-panel.md OQ1), and `villager-info-ui.md` Rule 2's "(right side, compact)" parenthetical is flagged for cleanup (Known Conflict 5), as is its stale two-step Esc wording (Known Conflict 6).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Every blocking AC — owned by stories 001–006.
- Final icon art and the Art Bible §7.3 shape-budget reconciliation (art-director's first production icon pass).
- Editing `design/ux/hud.md` or `design/gdd/villager-info-ui.md` (ux-designer / game-designer).
- The roster view, keyboard selection, camera focus, clustering, portraits, and proactive distress alerting — all VS+.

---

## QA Test Cases

- **AC-UX1**: two-frame capture pair around a selecting click; assert the panel is absent in frame N and present in frame N+1.
- **AC-UX2**: captures at need = 0 and need = 100 with the raw number legible in both.
- **AC-UX3**: a three-capture sequence — focused HUD element + panel open → Esc (focus gone, panel open) → Esc (panel closed).
- **AC19/AC-UX5**: a 3-line why-string capture at 1280×720 with the panel bounds outlined; assert no ellipsis character present.
- **AC-UX6**: the grayscale set (3 mood bands × {distress on, off}); an observer unfamiliar with the color coding names each correctly.
- **AC-UX7**: measured contrast ratios and rendered px sizes for name, why-string, activity label, band label, need value.
- **AC-UX9**: two captures at the camera's min and max pitch, icon legible in both.
- **AC-UX10**: paused-frame captures of select / switch / value / Esc-deselect.
- **AC18**: a capture of a villager walking behind the toolbar, annotated "accepted occlusion, Edge Case 10".
- **AC20**: per playtester — time-to-first-unprompted-click and the verbatim answer to "how is this villager doing, and why?".

---

## Test Evidence

**Story Type**: UI / Visual-Feel — **ADVISORY** per `.claude/docs/coding-standards.md`.
**Required evidence**: `production/qa/evidence/villager-info-ui-007-presentation-evidence.md` — one document consolidating the frame-capture pairs, the wrap/overflow capture, the grayscale set, the contrast/text-size measurements, the pitch captures, the paused-frame set, the two accepted-edge-case records, the A2 exemption record, and the playtest results for AC20. Screenshots alongside as `villager-info-ui-007-*.png`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **every other story in this epic**; M02 risk **R8**'s external playtest scheduling for AC20; the final font/theme (`hud.md` OQ2, art-director) for AC-UX7.
- Unlocks: the epic's Definition of Done.
