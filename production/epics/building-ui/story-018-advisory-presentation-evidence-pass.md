# Story 018: Advisory presentation evidence pass & door-gap affordance

> **Epic**: Building UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-ui.md` (**Advisory** AC block: AC23–29)
**UX Spec**: `design/ux/hud.md` (Visual Budget, Accessibility A1–A7) · `design/ux/projects-panel.md` (AC-UX7/AC-UX8) · `design/art/art-bible.md` §4.6/§7.1/§7.3/§7.6
**Requirement**: `TR-building-ui-071`, `TR-building-ui-074`, `TR-building-ui-087`, `TR-building-ui-069`, `TR-building-ui-072`, `TR-building-ui-086`, `TR-building-ui-075`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: — (no decision-owning ADR; this story produces evidence against already-implemented behavior)
**ADR Decision Summary**: n/a — the governing authorities here are the UX specs' accessibility requirements and the Art Bible's shape/hue rules.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: The grayscale (A1) pass is a screenshot post-process, not an engine feature — capture at native color and desaturate offline so the evidence is reproducible.

**Control Manifest Rules (this layer)**:
- Required (Presentation): every stateful element pairs **icon shape + label** with its color; the HUD must be fully usable **muted** (A6) and, apart from the tracked mouse-only exemptions, fully operable **without the mouse** (A2).
- Forbidden: closing an advisory AC with an assertion instead of an artifact — advisory evidence is a walkthrough doc or screenshot, by definition.
- Guardrail: the Visual Budget's ceilings are **checkable in QA**, not aspirational — ≤ 8 simultaneous HUD elements (plus Z7), ≤ ~25 % screen coverage at 1280×720, center third always HUD-free.

---

## Acceptance Criteria

*From GDD `design/gdd/building-ui.md`'s Advisory AC block + the UX specs' accessibility sections, scoped to this story:*

- [ ] **AC25**: Given a **1280×720** window, Then the three committed zones' bounding rects (plus Z4 and Z7) lie fully in-viewport and do **not** intersect — screenshot + rect assertion (Edge Case 8, `TR-building-ui-071`).
- [ ] **Visual Budget**: at the worst case (toolbar + context panel + time controls + 3 toasts + issues anchor + villager panel + projects panel), total HUD screen coverage is ≤ ~25 % at 1280×720 and the **center third is HUD-free** — measured, not estimated (hud.md Visual Budget).
- [ ] **A1 grayscale pass**: with saturation removed, every state of E1–E11 plus every Projects Panel card state (Draft / Building / Paused / Done / Done+pending / Demolishing), both toast tiers, and both marker kinds remain distinguishable by **shape + label alone** (`TR-building-ui-074`, AC-UX7).
- [ ] **A3/A4**: text `#EDE6DA` on chrome `#262220` measured ≥ 4.5:1; **State Orange and State Blue on `#262220` verified ≥ 3:1** against the final theme (hud.md's named OPEN item); body ≥ 16 px and why-string/activity labels ≥ 18 px at 1080p; all text **wraps, never truncates** (AC-UX8).
- [ ] **A5**: only three animated moments exist across the whole HUD — toast retire fade ≤ 0.2 s, invalid-cue fade ~1 s, transition-overlay fade. No shake, no flashing above 3 Hz, no parallax; instant swap everywhere else.
- [ ] **A6**: the HUD is fully usable muted — every sound (invalid cue, toast alert, select sound) has a visible counterpart.
- [ ] **A2**: every interactive control is reachable and operable without the mouse **except** the two tracked, stated MVP exemptions — villager selection (villager-info-ui Rule 1) and Projects Panel card clicks/buttons (projects-panel.md A2). Both exemptions are recorded in the evidence doc as exemptions, not as failures.
- [ ] **AC23**: Given a drag begun in the world, When the cursor enters HUD space, Then the drag is NOT canceled; When released over the HUD, Then the commit uses the last valid world preview (`TR-building-ui-069`).
- [ ] **AC24**: Given a toast dismissal click in a live viewport, Then the click is consumed — nothing beneath receives it (`TR-building-ui-072`).
- [ ] **AC26**: Given a first-time playtester, Then tool + material are found unaided in **under a minute**.
- [ ] **AC27**: Given a first-time player in WorldNav, Then the **"Bauen" toggle is discovered and Build Mode entered unaided** within that same one-minute criterion (`TR-building-ui-075`).
- [ ] **AC29**: Given the Projects Panel at 1280×720, Then a walkthrough confirms cards remain legible and usable (`TR-building-ui-086`).
- [ ] **AC28 (door-gap)**: Given a completed house with its door gap, Then a first-time player **without prior explanation identifies the gap as a functional doorway** — the confirmed 2026-07-23 playtest failure this AC exists to catch (`TR-building-ui-087`).
- [ ] **Rule 22 requirement recorded, not designed**: a dedicated visual affordance class marking "this gap is a functional doorway" exists, distinct from an unfinished/accidental gap, obeying shape+label-never-hue. Its exact treatment is **undesigned pending the Art Bible §7.6 handoff**, and the rule is explicitly **superseded, not duplicated**, the moment door/window ITEMS ship (GDD Open Question 11) (`TR-building-ui-087`).

---

## Implementation Notes

*Derived from the GDD's Advisory block and the UX specs' accessibility sections:*

- **This story is mostly evidence, and one small implementation.** The implementation is the minimum door-gap affordance (Rule 22) — ship *something* shape-based and legible rather than nothing, and mark it explicitly provisional against §7.6. Everything else is capture + measurement against already-shipped behavior.
- **AC28 is a confirmed prior failure, not a hypothetical.** `prototypes/last-seal-vertical-slice/REPORT.md` records that the door gap was NOT discoverable without explanation. If the walkthrough reproduces the failure, that is a **finding to escalate**, not a reason to weaken the AC.
- Run AC26/AC27/AC28 as part of M02 risk **R8**'s external silent walkthroughs (1–2, scheduled after criterion #5 lands — the first moment the loop pays off). Do not run them as a self-test; the whole value is a naive observer.
- Contrast and text-size checks are **blocked on the final font/theme** (hud.md OQ2 — art-director owns it). If the font is still open when this story runs, record the measurements against the interim theme and flag the re-measure, rather than passing on an interim value.
- Capture every screenshot at 1280×720 (the tightest supported layout) — a check that passes at 1440p and fails at 720p is not evidence.
- Reconcile the story-009 marker shapes and story-011 status shapes against Art Bible §7.3's shared shape-budget table in this pass; report any two unrelated states sharing a silhouette as a finding for the first production icon pass (GDD Open Question 12, projects-panel.md OQ8).
- Note for the ux-designer at close (not this story's edit): `hud.md`'s Layout Zones table and 8-element Visual Budget still need a **Z7 row and E-number** added — projects-panel.md OQ1.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Every blocking AC — owned by stories 001–017.
- Final icon art and the Art Bible §7.3 assignment table (art-director's first production icon pass).
- Door/window **items** (VS-tier) which supersede Rule 22 entirely.
- Editing `design/ux/hud.md` (the Z7 follow-up is the ux-designer's).

---

## QA Test Cases

- **AC25 / Visual Budget**: Given a 1280×720 capture at worst-case density, Then a rect-assertion script reports zero intersections, coverage ≤ 25 %, and zero HUD pixels in the center third.
- **A1**: Given the grayscale set, Then an observer unfamiliar with the color coding correctly names every state from shape + label alone.
- **A3**: Given the final (or interim, flagged) theme, Then measured contrast ratios for text and for State Orange / State Blue on `#262220` are recorded with pass/fail against 4.5:1 and 3:1.
- **A5**: Given a 60 s capture of ordinary play, Then exactly the three sanctioned animated moments occur and nothing flashes above 3 Hz.
- **A2**: Given a keyboard-only session, Then every control except the two stated exemptions was reached and operated; the exemptions are listed by name.
- **AC23/AC24**: live-viewport walkthroughs, recorded with the resulting cell/commit and the non-activated control beneath.
- **AC26/27/28**: per playtester, record time-to-tool, time-to-Build-Mode, and the verbatim answer to "what is that gap in the wall?".

---

## Test Evidence

**Story Type**: UI / Visual-Feel — **ADVISORY** per `.claude/docs/coding-standards.md`.
**Required evidence**: `production/qa/evidence/building-ui-018-presentation-evidence.md` — one document consolidating: the 1280×720 zone/budget capture + rect assertions, the grayscale set, the contrast/text-size measurements, the keyboard-only pass, the AC23/AC24 walkthroughs, and the playtest results for AC26/AC27/AC28. Screenshots alongside as `building-ui-018-*.png`.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **every other story in this epic** (it measures their combined result); M02 risk **R8**'s external playtest scheduling for AC26/27/28; the final font/theme (hud.md OQ2, art-director) for A3/A4.
- Unlocks: the epic's Definition of Done.
