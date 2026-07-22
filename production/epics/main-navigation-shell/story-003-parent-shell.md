# Story 003: Parent Shell — 2-Tab StatefulShellRoute

> **Epic**: Main Navigation Shell
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-21

## Context

**GDD**: `design/gdd/main-navigation-shell.md`
**Requirement**: `TR-navshell-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: Navigation Shell & Route Guard Architecture (Accepted), Decision §3
**ADR Decision Summary**: A separate `StatefulShellRoute.indexedStack` with 2 branches (`/parent/dashboard`, `/parent/family`) — architecturally simpler than the Child Shell (no Flame concerns), but uses the same state-preservation convention for consistency (pattern P13, "branches never disposed").

**Engine**: Flutter 3.44.4 / `go_router 17.3.0` | **Risk**: LOW (no Flame lifecycle concerns — this is the simpler of the two shells)
**Engine Notes**: None beyond what Story 002 already established for the same `StatefulShellRoute.indexedStack` API — this story is structurally identical, just 2 branches instead of 3, no Flame widget involved.

**Control Manifest Rules (this layer)**:
- Required: same `activeChildBranchIndexProvider` convention as Story 002, but scoped to this shell's own 0-1 index space (index space is per-shell, not global — per ADR-0014 Decision §4's explicit note)
- Required: no floating chips on Parent Shell — GDD specifies none (Core Rule 5); the top zone is reserved for the FCM banner only (owned by Parent Dashboard UI, not this story)

**Performance Budget**: Same 200ms tab-switch fade-through as Child Shell — no separate budget.

---

## Acceptance Criteria

*From GDD — Parent Shell's structural requirements are implied by AC-9/13/14's context (exercised fully in Story 004) rather than having a dedicated standalone AC number; this story covers the underlying branch structure those criteria depend on:*

- [ ] **Parent Shell renders 2 tabs**: GIVEN `sessionState == parentView`, THEN Parent bottom nav (2 tabs: Nhiệm vụ/Gia đình) hiển thị, route mặc định `/parent/dashboard`.
- [ ] **Tab switch works**: GIVEN ở `/parent/dashboard`, WHEN tap tab "Gia đình", THEN navigate sang `/parent/family` trong 200ms.
- [ ] **No floating chips**: GIVEN Parent Shell đang hiển thị (bất kỳ tab nào), THEN không có Profile/Xu/Contextual badge chip nào render — top zone hoàn toàn trống (dành cho FCM banner, ngoài phạm vi story này).
- [ ] **State preservation across tabs**: GIVEN scroll position hoặc form state trên `/parent/dashboard`, WHEN chuyển sang `/parent/family` rồi quay lại, THEN state được giữ nguyên (không rebuild) — cùng convention với Child Shell.
- [ ] **`activeChildBranchIndexProvider` correctness (Parent scope)**: GIVEN tap chuyển tab trong Parent Shell, THEN provider's value cập nhật đúng trong index space 0-1 của Parent Shell — không nhầm lẫn với Child Shell's 0-2 index space (2 shell dùng chung 1 provider nhưng index chỉ có ý nghĩa trong ngữ cảnh shell đang active).
- [ ] **Touch target**: mọi nav-tab đạt tối thiểu 48×48dp; re-tap tab đang active là no-op.

---

## Implementation Notes

*Derived from ADR-0014 Decision §3 — structurally mirrors Story 002's Child Shell, simpler:*

1. `StatefulShellRoute.indexedStack(builder: ..., branches: [...])` — 2 branches: `/parent/dashboard`, `/parent/family`.
2. `ParentShellScaffold` hosts `navigationShell` as `Scaffold.body` — **no `Stack` overlay for chips** (unlike Child Shell), since Parent Shell has none. Top zone stays reserved/empty for the FCM banner Parent Dashboard UI will render (not this story's concern).
3. Bottom-nav `onTap`: same `goBranch(index)` + `activeChildBranchIndexProvider` write pattern as Story 002 — same provider, but this shell's index values (0-1) are only meaningful while this shell is active. Do not create a second provider.
4. Visual tone: Navy-toned, more subdued nav bar per GDD Visual/Audio Requirements (icon 24dp, label 12sp) — distinct from Child Shell's Peach Glow accent/28dp icons. This is a styling detail, not a structural one, but note it so the two shells don't accidentally share a single styled `NavigationBar` widget config.

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 001**: root redirect (this story's `StatefulShellRoute` wires into that story's route tree).
- **Story 004**: the actual Parent Override transition (long-press trigger, password confirm, navigating INTO this shell) — this story only builds the shell structure itself, assuming `sessionState == parentView` is already true.
- Parent Dashboard UI's own content (`/parent/dashboard`, `/parent/family` screens) — that epic is Blocked pending this epic, and will fill in real content once this story provides the route slots. This story can use placeholder screens for its own testing.
- FCM banner rendering — Parent Dashboard UI's scope (Story 004 of that epic, currently Blocked pending an ADR).

---

## QA Test Cases

*Transcribed from GDD's own context — QL-STORY-READY gate skipped (Solo mode).*

- **AC-1 (2-tab render)**
  - Given: `sessionState == parentView`
  - When: shell renders
  - Then: 2 tabs visible, default route `/parent/dashboard`

- **AC-2 (tab switch)**
  - Given: on `/parent/dashboard`
  - When: tap "Gia đình"
  - Then: route becomes `/parent/family` within 200ms

- **AC-3 (no floating chips)**
  - Given: Parent Shell active, either tab
  - When: inspecting the top zone
  - Then: no Profile/Xu/Contextual badge widgets present in the widget tree

- **AC-4 (state preservation)**
  - Given: some local widget state set on `/parent/dashboard` (e.g. a scroll offset)
  - When: switch to `/parent/family` and back
  - Then: the state value is unchanged — no rebuild occurred

- **AC-5 (index space correctness)**
  - Given: Parent Shell active
  - When: switching between its 2 tabs
  - Then: `activeChildBranchIndexProvider` only ever takes values 0 or 1 while this shell is active — never 2 (which would be a Child-Shell-only index)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/main-navigation-shell/parent_shell_test.dart` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (Root Redirect) must be Complete.
- Unlocks: Story 004 (Parent Override needs this shell to exist as the transition's destination).

---

## Completion Notes
**Completed**: 2026-07-21
**Criteria**: 6/6 passing (all auto-verified via tests; no manual/deferred criteria)
**Deviations**:
- ADVISORY: open accessibility question found while fixing a code-review finding — GDD's 2026-07-13/14 WCAG audit says text-on-Navy must use Primary text (`#3D2B1F`), but that audit never tested Navy as a full-fill background; Primary-on-Navy (dark-on-dark) would likely fail contrast in the opposite direction. `ParentShellScaffold` uses `Colors.white70` instead, flagged via doc comment rather than silently applying the literal rule. Not yet ruled on — recommend a dedicated audit before Parent Dashboard UI locks in real content.
- ADVISORY (documented, not a defect): `childShellRoute`/`parentShellRoute` are independent top-level routes, not branches of one shared shell — a Parent Override round-trip fully disposes/reconstructs Pet Room's `FlameGame`, unlike intra-Child-Shell tab switching. Narrows a loose reading of ADR-0014 §5's "child branch never disposed" wording (accurate for Riverpod session state, not the Flame widget tree). Flagged explicitly for Story 004 to verify rather than inherit at face value.
- Real gaps found and fixed during code review (not deviations, fixes): forbidden `Color(0xFFRRGGBB)` int constructor replaced with `Color.fromARGB()`; invented navy hex (`#23324A`) corrected to the GDD's actual specified `#2C3E50` and centralized into `AppColors.parentNavy`; rapid-double-tap test added (AC-2); cross-shell provider-contamination test added (AC-5).
**Test Evidence**: Integration — `tests/integration/main-navigation-shell/parent_shell_test.dart` (8/8 passing, 2 beyond the story's own 6 stated ACs, added during code review)
**Code Review**: Complete — `/code-review`, flame-specialist + qa-tester, verdict APPROVED WITH SUGGESTIONS, all required changes fixed and re-verified same session (384/384 full suite, `flutter analyze` clean)
