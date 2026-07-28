# Accessibility Requirements

> **Status**: Committed (autonomous draft 2026-07-11 — user delegated decisions; review on next session)
> **Author**: ux-designer (Claude) — user-delegated autonomous run
> **Last Updated**: 2026-07-11
> **Applies to**: All player-facing UI and input (MVP scope: Building UI, Villager Info UI, Time HUD, transition overlays)

---

## Tier Commitment

**Committed tier: "Indie Baseline" — Game Accessibility Guidelines *Basic* level,
plus selected *Intermediate* items that our GDDs already commit to anyway.**
(In `/ux-review`'s tier vocabulary this maps to **Basic+**: all Basic checks
apply; of the Standard checks, focus-order documentation and text-contrast
ratios apply; screen-reader checks do not until the Alpha decision.)

Rationale: single-player PC colony builder, mouse-driven core interaction,
small team. Full WCAG-AA / screen-reader support is not achievable for MVP
without derailing scope, but the GDDs have already committed to the highest-value
items (color-independence, keyboard access). This document makes the remaining
gaps explicit instead of silent, and stages them by milestone.

| Milestone | Commitment |
|---|---|
| **MVP** | Everything in "MVP Requirements" below — blocking for `/gate-check` |
| **Vertical Slice** | + keyboard villager-selection path (closes the stated Rule 9b exemption) |
| **Alpha** | + input rebinding UI, camera sensitivity settings, UI scale option; AccessKit/screen-reader feasibility decision |

---

## MVP Requirements (blocking)

### A1. Color-independence (already committed — enforced here)

No information may be conveyed by hue alone. Every state signal pairs
**icon shape + label/tooltip** with its color.

- Sources: villager-info-ui.md Visual/Audio Requirements (mood-band icons,
  distress icon), building-ui.md Visual/Audio Requirements (Warning vs Info
  toasts), resource-item-database.md AC29 (tier-0 materials identifiable
  without tooltip), visual-direction-note.md §4 (day-one pairing rule;
  blue–orange state axis, never red–green).
- QA check: grayscale screenshot pass — every distinct UI state must remain
  distinguishable with saturation removed.

### A2. Keyboard access for persistent HUD (already committed — enforced here)

No persistent HUD element is mouse-only (building-ui.md Rule 9b). Named
InputMap actions exist for: toast focus/dismiss, issues anchor toggle,
palette cycling, roof-formation cycling, wall-height stepping. Esc releases
HUD focus before falling through to world (two-step Esc routing).

- **Stated exemption**: villager selection is mouse-only at MVP
  (villager-info-ui.md Rule 1, user decision 2026-07-11). A keyboard
  selection path is committed for the Vertical Slice revision. This exemption
  is tracked, not silent.
- QA check: complete one full build action (arm tool → select material →
  set height → commit is mouse-bound by design, but every palette/stepper/
  toast interaction reachable by keyboard) and dismiss a toast without
  touching the mouse.

### A3. Text contrast — NEW commitment

All UI text meets **4.5:1 contrast ratio** against its rendered background;
large text (≥ 24 px) and non-text state icons meet **3:1**. `[assumption:
WCAG 1.4.3/1.4.11 values adopted as-is; verify against final art palette
when the UI theme exists]`

- QA check: contrast-checker pass on the final theme's text/background pairs.

### A4. Minimum text size — NEW commitment

No player-facing text below **16 px at 1080p** (tooltips included); the
why-string and activity labels target **18 px+**. Text wraps, never
truncates (villager-info-ui.md Edge Case 8 generalized to all UI text).
`[assumption: 16/18 px baseline pending font choice from art direction]`

- No UI-scale slider at MVP (Alpha item); the baseline must therefore be
  comfortable unscaled at 1080p and 1440p.

### A5. Motion restraint — NEW commitment (codifies existing feel rules)

MVP UI already commits to minimal motion ("no slide animations — speed over
ornament", building-ui.md Game Feel; instant camera start/stop,
camera-input.md). New rule: **no screen shake, no flashing above 3 Hz, no
parallax/vestibular effects** in MVP UI or camera. If any post-MVP feature
wants these, it ships with a reduced-motion toggle in the same milestone.

- QA check: celebration VFX (grouped room celebration) reviewed against the
  3 Hz flash limit.

### A6. Audio pairing — NEW commitment

Every audio-only cue has a visible counterpart (invalid-commit cue already
pairs orange marker + sound, building-ui.md). Game is fully playable muted.
No VO at MVP → no subtitle system required yet; if VO ever ships, subtitles
ship in the same milestone.

### A7. Input model stability (already committed — enforced here)

All input goes through named InputMap actions registered at project scope
(camera-input.md Core Rule 11) — this is the technical precondition for the
Alpha rebinding UI. No hardcoded scancodes in gameplay/UI code, ever.

---

## Explicit MVP Non-Goals (tracked gaps, not oversights)

| Gap | Why deferred | Revisit |
|---|---|---|
| Screen reader / AccessKit integration | Godot 4.5+ AccessKit APIs unverified against pinned 4.7 (building-ui.md OQ7 flags this); voxel world content largely non-textual | Alpha feasibility decision |
| Input rebinding UI | Needs Main Menu & Settings screen (Alpha tier per camera-input.md) | Alpha |
| UI scale / font scale slider | Needs settings screen; baseline sizes chosen to be comfortable unscaled | Alpha |
| Colorblind simulation testing beyond grayscale | Grayscale pass is the MVP gate; simulator pass (deuteranopia/protanopia/tritanopia) | Vertical Slice QA |
| Difficulty/assist options | Wave-defense combat not in MVP scope | With combat GDDs |

---

## Verification Hooks

- `/ux-review` of any UX spec MUST check sections A1–A7 apply to that screen.
- `/gate-check` Technical Setup → Pre-Production: this document existing with
  a committed tier satisfies the accessibility checklist item; the A1–A7
  checks become acceptance criteria in each screen's UX spec.
- QA evidence for A1/A3 (grayscale + contrast passes) lands in
  `tests/evidence/` per the testing standards.

## Open Questions

1. Final font family + rendered sizes — blocks A3/A4 verification (owner:
   art-director, when UI theme exists).
2. Godot 4.7 AccessKit API surface — verify `docs/engine-reference/godot/`
   before the Alpha screen-reader decision (building-ui.md OQ7).
3. Default keys for the Rule 9b keyboard actions — deferred to the first
   screen-level UX pass (building-ui.md OQ1); must avoid the Tab /
   `ui_focus_next` collision (OQ7, Godot 4.6 dual-focus system).
