# Story 011: Child Profile Selection Screen UI

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: UI
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Unblocked

**UX spec complete**: `design/ux/child-profile-selection-screen.md` (2026-07-16). Full layout, component inventory, states, interaction map, transitions, accessibility, and 6 acceptance criteria specified. **Ownership question resolved (user decision, 2026-07-16)**: the delete-profile confirmation dialog (P2 pattern, flagged in Story 009's Out of Scope and this story's AC below) belongs to Parent Dashboard epic #21, NOT this screen — this screen has no delete affordance. Not yet run through `/ux-review` — implement against the spec as written.

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: covers the UI portion of `TR-auth-account-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture (backend contract only)

**Control Manifest Rules (this layer)**: none UI-specific yet — will come from the UX spec; underlying data access already governed by Story 005's manifest rules.

---

## Acceptance Criteria

*From `design/ux/child-profile-selection-screen.md`'s Acceptance Criteria section (supersedes the GDD-only draft list):*

- [x] Danh sách profile hiển thị đúng avatar + tên cho tất cả child profiles của gia đình (tối đa 4).
- [x] Bé tap vào 1 profile → navigate đến PIN Entry Screen với đúng `childId` đã chọn.
- [x] Khi 0 profile tồn tại, hiển thị empty state thân thiện thay vì màn hình trắng/lỗi.
- [x] Khi đã đủ 4 profile, nút "Thêm bé" không hiển thị.
- [x] Mỗi profile card đạt tối thiểu 48×48dp tap target.
- [x] Nếu 1 profile doc bị lỗi dữ liệu, các profile hợp lệ khác vẫn hiển thị bình thường (Story 005's skip-and-log).

**RESOLVED**: delete-profile confirmation dialog does NOT belong to this story/screen — see Unblocked note above.

---

## Implementation Notes

*From `design/ux/child-profile-selection-screen.md`:*

- Layout: 2×2 grid, căn giữa màn hình. Full component inventory + ASCII wireframe in the spec.
- Wire to Story 005's `childProfilesProvider` for the list data — handle Loading (P5 skeleton), Default, Full (4/4, hide "Thêm bé"), Empty (P6), and Error states per the spec's States & Variants table.
- "Thêm bé" button: render it (per GDD UI Requirement), but its tap destination is **TBD/out of scope** (spec's Open Questions) — wire to a no-op or placeholder for this story.
- On profile card tap: navigate to PIN Entry Screen (Story 012) carrying the selected `childId`.
- Card tap feedback: scale-down 95%/100ms press, bounce back on release; reduced-motion falls back to opacity-only.
- Avatar illustration set/selection mechanism is an Art/asset-pipeline concern, not this story's scope.

---

## Out of Scope

- Story 005: the underlying Firestore read (this story only renders it)
- Story 004/012: PIN entry itself, triggered by tapping a card

---

## QA Test Cases

*UI story — manual verification against the UX spec's States & Variants:*

```
Manual check: Profile selection navigates correctly
  Setup: family with 2-3 child profiles
  Verify: tap each profile card
  Pass condition: navigates to PIN Entry Screen carrying the correct childId each time

Manual check: Empty state
  Setup: family with 0 child profiles (new family)
  Verify: open Child Profile Selection screen
  Pass condition: friendly empty-state message shown, not a blank/error screen; "Thêm bé" still visible

Manual check: Full grid (4/4)
  Setup: family with 4 child profiles
  Verify: open Child Profile Selection screen
  Pass condition: no "Thêm bé" button/card shown, 4 profile cards fill the grid
```

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/child-profile-selection-ui-evidence.md` — ADVISORY gate level

**Status**: Substituted with an automated widget test (established project pattern since Story 010 — see its Completion Notes): `tests/integration/auth_account/child_profile_selection_screen_test.dart` (11 tests) + 2 new pure-logic tests in `tests/integration/auth_account/router_redirect_test.dart`.

---

## Dependencies

- Depends on: Story 005 (Complete), `design/ux/child-profile-selection-screen.md` (Complete)
- Unlocks: Story 012 (navigation entry point)

---

## Completion Notes

**Completed**: 2026-07-16

**Files changed**:
- `src/lib/ui/child_profile_selection_screen.dart` — new widget: `.when()`-driven Loading (P5 skeleton)/Error (retry)/Data (2×2 grid) states, `_ProfileCard` (Material+InkWell for ripple + accessibility semantics, `AnimatedScale`/`AnimatedOpacity` press feedback with reduced-motion fallback, P1 single-flight tap guard), `_AddChildCard` (no-op — destination TBD, per Unblocked note), `_ErrorState`, `_LoadingGrid`/`_ShimmerCard`, `_GridLayout`.
- `src/lib/providers/router_provider.dart` — added `AppRoutes.pinEntry` route + `pinEntryFor(childId)` helper; wired the real `ChildProfileSelectionScreen` in place of the placeholder; extended `redirectForSessionState`'s `parentAuthed` case to allow both `selectChild` and `pinEntry` (proactively found during implementation — without this fix, `context.push()` to PIN entry would have been redirected straight back to `selectChild`).
- `src/lib/providers/auth_providers.dart` — `childProfilesProvider` now passes `retry: (retryCount, error) => null` (see finding below).
- `docs/architecture/control-manifest.md` — new dated Required Pattern (2026-07-16) documenting the riverpod 3.3.2 default-retry finding; bumped `Manifest Version` to 2026-07-16.
- `tests/integration/auth_account/child_profile_selection_screen_test.dart` — new, 11 tests.
- `tests/integration/auth_account/router_redirect_test.dart` — 2 new pure-logic tests for the `parentAuthed`/`pinEntry` redirect change; existing widget-integration test updated (`find.byType(ChildProfileSelectionScreen)` replacing a stale placeholder-text assertion, plus a `firebaseFirestoreProvider` override the real screen now needs).

**Criteria**: 6/6 passing, all covered by automated tests (no deferred/manual-only criteria).

**Deviations**: None from scope. "Thêm bé" tap destination remains an intentional no-op (TBD, per the Unblocked note and UX spec's Open Questions) — not a deviation, a stated boundary.

**Real finding (code review, not a deviation — a production correctness bug caught before release)**: Riverpod 3.3.2's `ProviderContainer.defaultRetry` (verified against installed source) silently retries any `FutureProvider` build that throws a plain `Exception` (this includes `FirebaseException`) up to 10 times with exponential backoff (200ms→6.4s, ~38s total) before ever exposing a terminal `AsyncError` — during those retries `.when()` still reports `isLoading: true`. This meant `childProfilesProvider`'s failure path would leave the screen stuck on the loading skeleton for up to ~38s on a real Firestore error, silently pre-empting the UX-designed manual "Thử lại" button. Caught by this story's own error-state test never observing the error UI (not by a specialist review). Fixed by adding `retry: (retryCount, error) => null` to `childProfilesProvider`. Documented in `control-manifest.md` as a new Required Pattern. **Not yet audited**: other existing `FutureProvider`/`StreamProvider` declarations in this codebase (e.g. `parentProfileProvider`, `itemCatalogProvider`) may have the same latent gap — flagged for a follow-up pass, not fixed here (out of this story's scope).

**Code Review**: Complete — `flame-widget-specialist` (layout/interaction/accessibility/router correctness) + `qa-tester` (test coverage) run in parallel. All 3 Required Changes from flame-widget-specialist fixed: reduced-motion press feedback (`AnimatedOpacity` fallback), `Material`+`InkWell` for ripple + button semantics (previously a bare `GestureDetector`), P1 single-flight double-tap guard. All qa-tester ADVISORY gaps closed with new regression tests: error state + retry-refetch, 48×48dp tap target, long-name overflow, malformed-doc skip at this layer, second-profile navigation (guards against a hardcoded-first-childId bug), double-tap guard.

**Test Evidence**: `tests/integration/auth_account/child_profile_selection_screen_test.dart` (11/11 passing) + `tests/integration/auth_account/router_redirect_test.dart` (9/9 passing). Full suite: 99/99 passing (+1 pre-existing skip). `flutter analyze`: clean (9 pre-accepted cosmetic lints, unchanged).
