# Story 004: The why-slot — precedence, verbatim pass-through & the distress companion

> **Epic**: Villager Info UI
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: ~1 agent-day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/villager-info-ui.md`
**UX Spec**: `design/ux/villager-panel.md` (C4 why-slot, C5 distress flag, States & Variants "Why-slot empty" / "Distress")
**Requirement**: `TR-villager-info-ui-032`, `TR-villager-info-ui-036`, `TR-villager-info-ui-042`, `TR-villager-info-ui-044`, `TR-villager-info-ui-033`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0001 (Inter-System Reference & DI Pattern)
**ADR Decision Summary**: Needs & Mood is the **single owner** of the why-string; the UI is a leaf that consumes it **verbatim** through the query API. The UI never assembles its own reason from need values. `get_why_string()` is an O(active needs) pure query, safe to call per UI refresh.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: The why-slot is multi-line by design and must tolerate **+40 %** German/French expansion — wraps, never truncates. Why-strings are the longest text in the panel; the template set is owned by Needs & Mood.

**Control Manifest Rules (this layer)**:
- Required (Presentation): the why-slot is **ONE slot**. It shows text whenever a need is urgent **or** mood is not Happy, and its CONTENT is governed by Needs Core Rule 11's precedence, **consumed whole**.
- Forbidden: the UI composing or re-deriving any explanation; a second competing text beside the distress icon; a why-string that names a fix the player cannot take (a trapped villager must never be told "no bed") — that guarantee is upstream's, and the UI must not break it by substituting.
- Guardrail: precedence is **distress/trapped cue > need-why > Build Validation's structural string**; among multiple urgent needs, **strongest drain wins with schema-order tie-break**.

---

## Acceptance Criteria

*From GDD `design/gdd/villager-info-ui.md` Rules 2b/5 + Edge Cases 5/8, scoped to this story:*

- [ ] **AC9**: Given mood **not Happy** or a need **urgent**, Then the why-string renders **verbatim** from the Needs payload; Given mood Happy **AND** no urgent need, Then the why-slot area is **empty/hidden** (both directions, `TR-villager-info-ui-032`, `TR-villager-info-ui-036`).
- [ ] **AC-UX4**: The why-slot is hidden when mood is Happy and no need is urgent; otherwise it shows the upstream string verbatim.
- [ ] The empty case is precisely **"nothing urgent AND mood Happy"** — a Content-mood villager with nothing urgent still yields a string. Do **not** widen the empty case to "nothing urgent" (the needs-mood story's explicit warning).
- [ ] **Why-slot empty ⇒ no layout jump**: C4/C5 collapse but the panel height stays stable (`villager-panel.md` States & Variants).
- [ ] **AC23**: Given a mocked **trapped** flag **AND** an urgent sleep need simultaneously, When the panel renders, Then the why-slot shows the **distress-derived template** ("trapped"), **never** the need-why — Rule 2b precedence, Needs Core Rule 11's "never directs to the wrong fix" guarantee (`TR-villager-info-ui-032`).
- [ ] **AC24 (forward-looking — multi-need arrives VS+)**: Given **two** mocked urgent needs, When the panel renders, Then the why-slot shows the **strongest-drain** need's string (the active need with the **lowest value**); given equal drains, Then **schema order** (`sleep` > `food` > `company`) breaks the tie (`TR-villager-info-ui-032`).
- [ ] **AC11**: Given a distressed villager selected, Then the panel flag and the overhead icon reflect **the same source state** — single source, no divergence (Edge Case 5, `TR-villager-info-ui-042`).
- [ ] **C5 is the ICON companion to the slot, never a second competing text**: when a distress flag is active, the why-slot text **IS** the distress-derived template (Rule 2b).
- [ ] **AC19 (advisory)**: Given a long why-string, Then it **wraps** with no silent truncation (Edge Case 8, `TR-villager-info-ui-044`).
- [ ] **AC-UX5 (advisory)**: A 3+-line why-string wraps fully visible at **1280×720** — no truncation, no overflow outside the panel.
- [ ] The distress icon (C5) is differentiated by **shape + tooltip label**, never hue alone (A1).
- [ ] The why-string is read each update frame via the query — never cached, never re-derived (`TR-villager-info-ui-033`).
- [ ] A grep over the module returns **zero** string-composition of reason text (no concatenation of need names, values, or source enums into player-facing text).

---

## Implementation Notes

*Derived from Rule 2b's precedence and needs-mood story 007's published contract:*

- **⚑ Known Conflict 4 gates this story.** `get_why_string(id)` is `needs-mood-system` story 007 — `Status: Ready`, **not landed**. Its committed templates (per source enum, with an urgent sleep need) are: `ground_no_bed_owned` → "tired — no bed"; `ground_bed_unreachable` → "tired — bed unreachable"; `ground_trapped` → "tired — trapped!"; `bed_unsheltered` → "sleeping rough — no shelter"; `bed_sheltered` / not sleeping → base string with **no** source suffix. Mock exactly those.
- **Precedence is arbitrated here, but ranks are published upstream.** Needs & Mood publishes its own string *plus its precedence rank* and explicitly **does not arbitrate the other two** (`TR-needs-mood-system-047`). This UI therefore performs the three-way comparison — Villager AI's distress cue > the need-why > Build Validation's structural string — using published ranks, not hardcoded knowledge of what each string says.
- Build Validation's structural string "appears only in the building/bed context and **never competes** in the villager panel" (needs-mood story 007). So in practice the panel arbitrates two, with the third slot present for completeness. Implement all three ranks anyway; do not special-case it away.
- **⚑ Known Conflict 3 affects AC23.** The landed distress surface is a single `VillagerAi.is_distressed() -> bool` from the watchdog path — the *trapped* half only. Ground-sleeping requires `villager-ai-018` (Cluster A). AC23 is testable against a mocked two-flag provider today; the real wiring waits.
- AC24 is explicitly forward-looking — MVP has one need. Test the comparator (lowest value wins; schema order on ties) directly as a pure function; that is the whole AC.
- **Never substitute.** If the query returns an empty string in a state where the panel expected text, render nothing and let it be a visible bug — a UI-composed fallback would silently defeat the "never directs to the wrong fix" guarantee.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: name, activity label, need bar, mood band icon.
- Story 005: the **overhead** distress icon (this story owns only the in-panel C5 companion and asserts they share one source).
- Story 007: the wrap/overflow evidence capture at 1280×720 and the grayscale pass.
- The why-string templates themselves — `needs-mood-system` story 007.

---

## QA Test Cases

- **AC9 (both directions)**: Given (mood=Content, no urgent need), Then the slot shows the query's string; given (mood=Happy, no urgent need), Then the slot is hidden and the panel height is unchanged from the shown case.
- **Verbatim**: Given a why-string containing an em-dash and a quote, Then the rendered text is byte-identical to the payload.
- **AC23**: Given trapped=true and urgent sleep=true, Then the rendered text equals the distress template and does **not** equal the need-why template — assert both.
- **AC24**: Given needs at values 20 and 35 both urgent, Then the value-20 need's string renders; given both at 20, Then `sleep` wins over `food` by schema order.
- **AC11**: Given the distress source mutated once, Then the panel flag and the overhead icon's queried state are read from the same accessor — assert a single call site, or assert both render from one mocked value.
- **AC19/AC-UX5 (advisory)**: Given a 3-line why-string at 1280×720, Then a capture shows the full text inside the panel bounds with no ellipsis.
- **No-composition grep**: Given the module source, When grepped for string concatenation into player-facing text, Then zero matches.

---

## Test Evidence

**Story Type**: Logic (precedence comparator + render rules) — **BLOCKING**. AC19/AC-UX5 are **ADVISORY**.
**Required evidence (blocking)**: `neues-spiel/tests/unit/ui/why_slot_precedence_test.gd` — must exist and pass.
**Required evidence (advisory)**: folded into `production/qa/evidence/villager-info-ui-007-presentation-evidence.md` (story 007).

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 003; **Known Conflict 4** — `needs-mood-system` story 007 (`get_why_string`) and its published precedence rank; **Known Conflict 3** — the two-flag distress surface for AC23's real wiring.
- Unlocks: 005.
