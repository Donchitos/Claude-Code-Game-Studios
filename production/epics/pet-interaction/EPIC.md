# Epic: Pet Interaction

> **Layer**: Feature
> **GDD**: design/gdd/pet-interaction.md
> **Architecture Module**: Pet Interaction (#14)
> **Status**: Complete (5/5 stories) — 2026-07-23
> **Stories**: 5 stories

## Overview

Pet Interaction is the direct-touch emotional bridge between bé and Mochi inside
Pet Room Screen — no task, no xu, just a tap or a swipe. Flame `DragCallbacks`
(only — not combined with `TapCallbacks`, per ADR-0016) on the Mochi sprite map
raw touch input to an `InteractionType` (`tap`/`swipe`) and emit
`GameEvent(petInteracted, InteractionType)` onto the
`GameEventBus` (the sanctioned Flame-to-Bus-to-Flame reverse case from ADR-0004
§3b), which Pet State Machine (#6) consumes to trigger its 2s `PLEASED` triggered
state before returning to the prior base mood. The system owns no persistent
data — `energyLevel`, `xuBalance`, and all other saved fields are untouched by
any interaction; these are pure visual/audio joy moments. MVP scope is 2
interaction types only (tap, swipe), each independently cooled down (tap 1.0s,
swipe 2.0s) to prevent spam, with swipe distinguished from tap by a distance
(≥40dp) and duration (≤300ms) threshold on the drag gesture. A hit-area floor
(≥80×80dp) is this system's own requirement, independent of Mochi's actual
sprite size at any evolution stage — Pet Room Screen UI (#18) owns the layout
math that must satisfy it.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0004: Flutter-Flame Event Bridge Architecture | Covers only the Flame-emit contract (§3b): `TapCallbacks`/`DragCallbacks` on a Flame component emitting directly onto `GameEventBus` is a sanctioned reverse-direction case | MEDIUM |
| ADR-0016: Pet Interaction Input Handling | Covers gesture classification (DragCallbacks-only capture, classify tap-vs-swipe in `onDragEnd`), per-type cooldown (stored `DateTime` timestamps + lazy wall-clock comparison, no scheduled `Timer`), and the hit-area contract (`size`-based hit test decoupled from rendered sprite size) | MEDIUM |

**Epic Engine Risk: MEDIUM** — Flame `TapCallbacks`/`DragCallbacks` themselves are not deprecated, but `TapDetector` (the pre-1.21 mixin) is deprecated in this project's pinned Flame 1.37.0; the GDD already correctly specifies `TapCallbacks`. ADR-0016 (Accepted 2026-07-23) now covers cooldown timer implementation, swipe threshold detection, and the hit-area/no-persistent-mutation constraint — see Governing ADRs above.

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-petinteraction-001 | TapCallbacks/DragCallbacks on the Mochi sprite emit petInteracted directly (Flame to Bus to Flame, sanctioned reverse-direction case) | ADR-0004 §3b ✅ |
| TR-petinteraction-002 | Per-interaction-type cooldown: tap 1.0s, swipe 2.0s | ADR-0016 §Decision 2 ✅ |
| TR-petinteraction-003 | Swipe detection thresholds: ≥40dp distance, ≤300ms duration | ADR-0016 §Decision 1 ✅ |
| TR-petinteraction-004 | No persistent-data mutation from interaction; minimum 80×80dp hit area regardless of visual sprite size | ADR-0016 §Decision 3 ✅ |

**Coverage: 4 / 4 by ADR.**

## Untraced Requirements — Stories Will Be Blocked

**Resolved 2026-07-23.** `/architecture-decision "Pet Interaction Input Handling"`
has been run — see ADR-0016 (`docs/architecture/adr-0016-pet-interaction-input-handling.md`,
Accepted). All 4 TR-IDs are now ADR-covered; no requirement in this epic remains
untraced. Story 005's separate gate on the Pet Room Screen UI (#18) epic also
resolved the same day — see Epic Completion Notes below.

## Definition of Done

This epic is complete when:
- [x] All stories are implemented, reviewed, and closed via `/story-done`
- [x] All acceptance criteria from `design/gdd/pet-interaction.md` are verified (12/12 ACs across all 5 stories)
- [x] All Logic and Integration stories have passing test files in `tests/`
- [x] All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/` — N/A, this epic has no Visual/Feel or UI-type stories (all 5 are Logic/Integration)
- [x] ~~The "Pet Interaction Input Handling" ADR is Accepted before any story touching TR-petinteraction-002/-003/-004 is implemented~~ — satisfied: ADR-0016 Accepted 2026-07-23

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Gesture Classification & Event Emission | Logic | Complete | ADR-0004 (emit contract) + ADR-0016 (classification mechanism) |
| 002 | SLEEPING Peek & PLEASED-Animation Input Guards | Logic | Complete | ADR-0004 |
| 003 | Per-Type Cooldown Enforcement | Logic | Complete | ADR-0016 §Decision 2 |
| 004 | No-Mutation & Background/Foreground Resilience | Integration | Complete | ADR-0004 (secondary, AC-11) + ADR-0016 (no-mutation-by-construction, AC-10) |
| 005 | Hit-Area Minimum Enforcement | Logic | Complete | ADR-0016 §Decision 3 |

## Epic Completion Notes

**Closed**: 2026-07-23

All 5 stories implemented, reviewed, and closed. ADR-0016 ("Pet Interaction Input
Handling") was written mid-epic to close the 3 TR-IDs that had no ADR at epic
creation time; Story 005 additionally required the Pet Room Screen UI (#18) epic
and its own new ADR-0017 ("Pet Room Screen Rendering & Interaction Contract") to
exist, since Formula 2 (the hit-area padding formula) is owned by that epic, not
this one — both were created and closed the same day to unblock Story 005.

**Test coverage**: 5 test files, 55 tests total (13 gesture classification + 13
SLEEPING/PLEASED guards + 12 cooldown enforcement + 13 hit-area contract + 4
no-mutation/resilience), all independently re-verified. Full project suite: 563
passed / 1 pre-existing unrelated skip / 0 failures, `flutter analyze` clean (13
pre-existing unrelated info-lints elsewhere, none in any file this epic touched).

**Code review**: Stories 001, 002, 005 got real flame-specialist + qa-tester
verdicts (APPROVED / APPROVE WITH SUGGESTIONS / ADEQUATE WITH GAPS, all
non-blocking suggestions actioned before close). Story 003 got a real
flame-specialist APPROVED verdict; its qa-tester pass flagged a genuine
cross-story design question (see below) rather than a code defect. Story 004
used a documented self-review in place of nested specialist agents, per explicit
process instruction after repeated background-agent stalls earlier in this
pipeline (see below).

**Real bug found and fixed** (Story 004, AC-11): `GameEventBus`'s per-type replay
cache (ADR-0004 §5) has no exception for `petInteracted`, so a genuinely fresh
`MochiComponent` instance mounted after any prior interaction that session would
replay-trigger a spurious PLEASED animation on mount. Fixed additively —
`GameEventBus.peekLastEvent(type)` (new, read-only, no change to existing
`emit`/`stream`/`dispose` semantics) lets `MochiComponent` snapshot the cached
event at `onMount()` and ignore a delivery that `identical()`-matches it,
without touching the bus's cache/replay behavior for any other `GameEventType`
(verified against the Bridge epic's own test suite — no regression).

**Cross-epic work absorbed along the way** (not this epic's original scope, but
required to unblock it):
- ADR-0016 itself, plus new `docs/registry/architecture.yaml` entries (state
  ownership, interfaces, forbidden patterns for gesture classification,
  cooldown, and hit-area contracts).
- Pet Room Screen UI (#18) epic created from scratch, its own ADR-0017 written,
  and its Formula 2 story (`computeHitArea`, `src/lib/gameplay/hit_area_formula.dart`)
  implemented and closed — the other 6 stories of that epic remain Ready,
  unimplemented, out of this epic's scope.
- `MochiComponent` migrated from a generic component to a `SpriteComponent`
  with `size` wired to the padded hit-area output (Pet Room Screen UI's work,
  landed concurrently with this epic's own stories on the same file).

**Known follow-up (non-blocking, tracked separately)**: Story 003's qa-tester
review surfaced a genuine cross-story design tension — Story 002's PLEASED
reaction blocks all further interaction attempts for 2.0s, which is longer than
Story 003's 1.0s tap cooldown, making the tap cooldown practically unreachable
as the binding constraint in normal play. This does not make either story
incorrect against its own acceptance criteria (both are independently correct
per their own specs), but it means the *effective* minimum gap between two taps
in real gameplay is governed by PLEASED's duration, not the tap cooldown value.
Flagged via a spawned background task (not fixed here — would require a design
decision on whether this is intended behavior or whether one of the two
durations should change) rather than silently resolved by either story.

## Next Step

No further work identified within Pet Interaction (#14) itself. Project-wide,
open items not blocking this epic: the PLEASED-vs-cooldown design question
above, Pet Room Screen UI (#18)'s remaining 6 stories (draw-call budget, screen
composition/z-order, modal defer, FlameGame lifecycle, persistent chrome,
context menu/Wardrobe sheet), and the pre-existing GameEventBus replay-risk /
Push Notification TestFlight / Task Library emulator-gap items already tracked
elsewhere. None of these are urgent — surface as "epic done, here's what's
adjacent" rather than auto-continuing into unrelated work.
