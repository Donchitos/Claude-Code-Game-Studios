# Story 006: Floating Chip Cluster — Profile, Xu, Contextual Badge Wiring

> **Epic**: Main Navigation Shell
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-21

## Context

**GDD**: `design/gdd/main-navigation-shell.md`
**Requirement**: `TR-navshell-001` (supports the GDD's UI Requirements for the floating chip cluster; no independently-tagged TR-ID exists for the chips specifically — the GDD's own ACs AC-6/7 are the direct source)
**ADR Governing Implementation**: ADR-0014: Navigation Shell & Route Guard Architecture (Accepted) — N/A directly for chip rendering (no new architectural pattern; pure UI wiring to already-defined providers), but this story renders inside the Scaffold structure ADR-0014/Story 002 establishes.
**ADR Decision Summary**: N/A — this story's implementation is governed by `design/ux/hud.md` (visual/animation spec, APPROVED) for the chips' own look-and-feel, and by Currency System (#7)'s already-built `xuBalanceProvider` for data.

**Engine**: Flutter 3.44.4 | **Risk**: LOW — pure Flutter widget composition, no post-cutoff API surface
**Engine Notes**: None.

**Control Manifest Rules (this layer)**:
- Required: `xuBalanceProvider`'s safe nullable accessor (`.value`, not `.valueOrNull` — riverpod 3.x) for graceful `"— xu"` degradation on error
- Required: touch targets ≥48×48dp even though chips are display-only at MVP (per `hud.md`'s explicit future-proofing note — "in case a future 'tap xu chip' affordance is added")
- Forbidden: chips must never render inside Story 002/003's `IndexedStack`-managed branch content — they belong in the `Stack` overlay above `navigationShell`, per ADR-0014 Decision §2

**Performance Budget**: Xu chip count-up tween ~400ms ease-out on increase (per `hud.md` HUD Elements §2) — no performance impact beyond standard widget rebuild cost, scoped via `Consumer`/`select` per the control manifest's general Riverpod rebuild-scoping rule.

---

## Acceptance Criteria

*From GDD Acceptance Criteria AC-6, 7, plus `hud.md`'s HUD Elements specifications for Profile chip and Contextual badge (cross-referenced, not duplicated from scratch):*

- [x] **AC-6**: GIVEN `xuBalanceProvider` có giá trị 75, THEN Xu chip (floating, top-left) hiển thị "75 xu" (hoặc icon + "75").
- [x] **AC-7**: GIVEN `xuBalanceProvider` throw error, THEN Xu chip hiển thị "— xu" — không crash.
- [x] **Profile chip renders correctly** (per `hud.md` HUD Elements §1): avatar circle 32dp + child's name 16sp bold, adjacent to Xu chip in the top-left cluster (small visible gap, never fused into one shape).
- [x] **Contextual badge — hidden at zero**: GIVEN `seedCount == 0` AND `chestCount == 0`, THEN Contextual badge chip hoàn toàn không render (removed from layout, không phải faded/greyed).
- [x] **Contextual badge — seed variant**: GIVEN `seedCount > 0` trên screen thuộc task-submission flow, THEN badge hiện 🌱 + count.
- [x] **Contextual badge — mutual exclusivity**: badge chỉ bind 1 trong 2 (seed HOẶC chest) tại 1 thời điểm trên 1 screen — never cả hai cùng lúc.
- [x] **Xu count-up animation on increase**: GIVEN `xuBalanceProvider`'s value tăng (ví dụ do task reward), THEN digits count up over ~400ms thay vì snap ngay — kèm scale-pulse (1.0→1.15→1.0, ~200ms) nếu tăng do task reward cụ thể; purchases (decrease) không có pulse.
- [x] **Touch target**: Profile chip và Xu chip đều đạt ≥48×48dp dù không tương tác (Xu chip) hoặc chỉ tương tác qua long-press (Profile chip — long-press logic là Story 004's, chip rendering + hit-area là story này's).
- [x] **Safe area**: chips tôn trọng device safe-area inset (notch/Dynamic Island iOS, cutout Android) — không bao giờ render dưới status bar/camera cutout.

---

## Implementation Notes

*Derived from `design/ux/hud.md`'s HUD Elements §1-§3 — this is the primary reference document for this story, not ADR-0014 (which has no chip-rendering-specific decision):*

1. Profile chip (`hud.md` §1): avatar + name, Round-Over-Sharp shape (Art Bible §3), static per session (re-renders only if active child changes). Long-press gesture *detection* lives here (the widget must expose a `GestureDetector`/`InkWell` with `onLongPress`), but the *handler logic* (opening the bottom sheet, password flow) is Story 004's — wire this chip's `onLongPress` callback to call into Story 004's exposed action, don't duplicate logic.
2. Xu chip (`hud.md` §2): `Consumer`/`Selector` scoped to `xuBalanceProvider` only (per the control manifest's rebuild-scoping rule) — do not rebuild the whole chip cluster on every xu change. Count-up tween per the animation spec; distinguish "increase caused by task reward" (pulse) from "purchase decrease" (no pulse) — this likely requires observing the delta's sign and possibly its cause via whatever signal Currency System exposes for reward-vs-purchase context (check `xu_balance_provider.dart`'s actual shape — if no cause signal exists, treat ALL increases as reward-pulsed and note this as a known simplification in Completion Notes rather than inventing a cause-tracking mechanism not already provided).
3. Contextual badge chip (`hud.md` §3): bound to `seedCount` (Seed Buffer, ADR-0012) or `chestCount` (Gacha/Loot, no ADR yet — read the value per the GDD's explicit note that the read contract isn't fully locked down, but the field name is stable enough to bind to). Exactly one binding active per screen — determined by which screen is currently showing (the screen's own future UX spec decides which; this story just implements the chip that responds to whichever count is relevant, screen-by-screen wiring may need placeholder logic if Task Management UI/Shop screens don't exist yet).
4. All three chips render in a `Stack` positioned above `navigationShell` inside Story 002's `ChildShellScaffold` — coordinate with that story's Scaffold structure (if Story 002 is done first, this story adds to its existing insertion point; if this story is done first, leave a clean `Stack`-ready structure for Story 002 to build around).
5. Error handling for `xuBalanceProvider`: use `.value` (safe nullable accessor, riverpod 3.x) — never `.valueOrNull` (removed) or an accessor that rethrows on `AsyncError`.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 002**: Child Shell's own Scaffold/`IndexedStack` structure (this story renders INTO it).
- **Story 004**: Profile chip's long-press HANDLER logic (bottom sheet, password confirm) — this story only wires the gesture detector to call into it.
- **Parent Shell**: no chips at all on Parent side (GDD Core Rule 5) — this story is Child-Shell-only.
- `seedCount`/`chestCount`'s own derivation — Seed Buffer (#10, Complete) and Gacha/Loot (#12, no epic/ADR yet) own those respectively; this story only reads and displays.
- Screen-by-screen decision of WHICH contextual badge is relevant on which screen — that's each hosted screen's own future UX spec's job (Pet Room, Task Management, Shop — none have epics yet).

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria and `hud.md`'s HUD Elements specs — QL-STORY-READY gate skipped (Solo mode).*

- **AC-1 (Xu chip normal)**
  - Given: `xuBalanceProvider` value 75
  - When: chip renders
  - Then: displays "75 xu" (or icon + "75")

- **AC-2 (Xu chip error)**
  - Given: `xuBalanceProvider` throws
  - When: chip renders
  - Then: displays "— xu", no crash, no exception propagates to the widget tree

- **AC-3 (Profile chip)**
  - Given: active child has avatar + name set
  - When: chip renders
  - Then: 32dp avatar circle + 16sp bold name, positioned adjacent to Xu chip with visible gap (not fused)

- **AC-4 (Contextual badge — hidden)**
  - Given: `seedCount == 0` AND `chestCount == 0`
  - When: badge widget evaluates
  - Then: not present in the widget tree at all (not opacity:0, not a zero-size box — genuinely absent)

- **AC-5 (Contextual badge — seed)**
  - Given: `seedCount == 2` on a task-flow-relevant screen
  - When: badge renders
  - Then: shows 🌱 + "2"

- **AC-6 (Count-up animation)**
  - Given: `xuBalanceProvider` transitions from 50 to 75
  - When: the change is observed
  - Then: displayed value animates from 50 to 75 over ~400ms, not an instant jump
  - Edge cases: a decrease (purchase) — no pulse animation, still no instant-jump requirement one way or the other per spec (pulse is reward-specific, count direction itself isn't specified as animated-or-not for decreases — verify against `hud.md`'s exact wording before asserting a decrease behavior beyond "no pulse")

- **AC-7 (Touch target)**
  - Given: Profile chip and Xu chip rendered
  - When: measuring hit-test area
  - Then: both ≥48×48dp

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/main-navigation-shell/chip_cluster_test.dart` — must exist and pass

**Status**: [x] Created — 18/18 tests passing (`chip_cluster_test.dart`)

---

## Dependencies

- Depends on: Story 002 (Child Shell) should be Complete or in-progress alongside this story (they share the same Scaffold structure) — Currency System (#7) and Seed Buffer (#10) epics already Complete.
- Unlocks: None further within this epic. Long-press gesture wiring unlocks Story 004's testability (Story 004 can be tested independently with a stub gesture trigger if this story isn't done first, but full end-to-end testing needs both).

---

## Completion Notes
**Completed**: 2026-07-22
**Criteria**: 9/9 passing (all auto-verified via tests; no manual/deferred criteria)
**Deviations**:
- ADVISORY: `src/lib/providers/currency_providers.dart` and `seed_buffer_providers.dart` (Currency System #7 / Seed Buffer #10, outside this story's own layer) were touched to add `retry: (retryCount, error) => null` — closing the 3rd instance of an already-documented control-manifest gap, found via this story's own AC-7 test.
- ADVISORY (documented gap, not an oversight): Contextual badge binds only to `seedCountProvider` — `chestCount` has no dedicated provider yet (Gacha/Loot #12, no epic/ADR), explicitly permitted by this story's Out of Scope note.
- ADVISORY (documented, not a defect): `xuBalanceProvider` exposes no reward-vs-purchase cause signal — every increase treated as reward-pulsed, per this story's own anticipated simplification.
**Test Evidence**: Integration — `tests/integration/main-navigation-shell/chip_cluster_test.dart` (18/18 passing, well beyond the story's own 9 stated ACs — bonus coverage plus 3 gaps added during code review: strengthened mutual-exclusivity, reduced-motion, and chip-persistence-across-tab-switch tests)
**Code Review**: Complete — `/code-review`, flame-specialist + qa-tester, verdict APPROVED WITH SUGGESTIONS, all findings applied and re-verified same session (420/420 full suite, `flutter analyze` clean)
