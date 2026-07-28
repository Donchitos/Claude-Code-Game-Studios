# Story 001: Root Redirect & Session Guard

> **Epic**: Main Navigation Shell
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-20

## Context

**GDD**: `design/gdd/main-navigation-shell.md`
**Requirement**: `TR-navshell-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: Navigation Shell & Route Guard Architecture (Accepted)
**ADR Decision Summary**: Single root `GoRouter` with one top-level `redirect` implementing the 4-state guard (`unauthenticated`/`parentAuthed`/`childSelected`/`parentView`), refreshed via `ref.listen(sessionStateProvider, ...)` bridged to a `ValueNotifier` — never `ref.watch` (would tear down both shell trees) and never `GoRouterRefreshStream` (doesn't exist in the pinned `go_router` version).

**Engine**: Flutter 3.44.4 / `go_router 17.3.0` | **Risk**: HIGH (post-cutoff; every API shape used here was verified directly against installed package source during ADR-0014's authoring, not assumed)
**Engine Notes**: `sessionStateProvider` is read-only here — owned exclusively by `auth-account` (ADR-0002). This story must never re-derive session state from `authStateProvider`/`activeChildProvider`/`parentOverrideProvider` directly (registry-locked constraint, `docs/registry/architecture.yaml`).

**Control Manifest Rules (this layer)**:
- Required: `ref.listen` (never `ref.watch`) on `sessionStateProvider` inside `routerProvider` — registered forbidden-pattern violation otherwise (`ref_watch_on_session_state_inside_router_provider`, `docs/registry/architecture.yaml`)
- Forbidden: `GoRouterRefreshStream` usage — does not exist in `go_router ^17.3.0` (registered forbidden pattern `go_router_refresh_stream_usage`)
- Required: route path `/select-child` (not `/child-selector`) — corrected across GDD/ADR/UX specs during this epic's authoring, matching already-shipped Auth & Account code

**Performance Budget**: `redirect` is a pure synchronous switch over an already-computed enum — negligible CPU, no new async work per navigation (ADR-0014 Performance Implications).

---

## Acceptance Criteria

*From GDD `design/gdd/main-navigation-shell.md`, Acceptance Criteria AC-1, 2, 3 (initial-route portion only — tab bar rendering is Story 002/003's scope), 11:*

- [x] **AC-1**: GIVEN app khởi động với session `unauthenticated`, THEN GoRouter redirect về `/login` — không flash bất kỳ screen nào khác.
- [x] **AC-2**: GIVEN bố mẹ login thành công, WHEN chưa chọn bé, THEN redirect về `/select-child` tự động.
- [x] **AC-3 (initial route only)**: GIVEN bé gõ PIN đúng trên Child Selector, THEN redirect về `/child/pet-room` (nav bar rendering verified in Story 002).
- [x] **AC-11**: GIVEN session expire khi bé ở `/child/shop`, THEN GoRouter redirect về `/login` — không stuck ở `/child/shop`.
- [x] **Cold-start loading state** (added at `/ux-review`): GIVEN app vừa launch, `sessionStateProvider`'s first value chưa emit, THEN blank `Scaffold` (base background color, không nav bar, không chip, không spinner) hiển thị — không flash, resolve nhanh về 1 trong 4 state chính.
- [x] **`parentView` redirect**: GIVEN `sessionState == parentView`, THEN redirect cho phép `/parent/*`, mặc định `/parent/dashboard` — verify riêng khỏi `childSelected`'s `/child/*` allowance (2 nhánh độc lập của cùng switch).

---

## Implementation Notes

**CORRECTION (found during `/dev-story`, 2026-07-18 — read this before the ADR-0014 code samples below):** `src/lib/providers/router_provider.dart` already exists and is substantially built out from the Auth & Account epic (Complete) — it is NOT a bare placeholder file. It already has: a correctly-implemented `_RouterRefreshNotifier` (`ChangeNotifier`-based, wired via `ref.listen`, already avoiding the `GoRouterRefreshStream` pitfall ADR-0014 warns about), a real tested `redirectForSessionState(SessionState, String) → String?` pure function handling all 4 states, correct `AppRoutes.selectChild = '/select-child'` naming, and working routes for `/login`, `/register`, `/select-child`, `/select-child/pin-entry`. **This story is a targeted extension of that file, not a rewrite.** Do not replace `_RouterRefreshNotifier` or the overall structure — only the `childSelected`/`parentView` cases need to change, and one route needs to move.

*Derived from ADR-0014 Decision §1, adapted to the actual existing file:*

1. In `redirectForSessionState()`: change the `childSelected`/`parentView` combined case (currently both collapse to `matchedLocation == AppRoutes.petRoom ? null : AppRoutes.petRoom`) into two separate cases — `childSelected` allows any `matchedLocation.startsWith('/child/')`, defaulting to `AppRoutes.childPetRoom`; `parentView` allows any `matchedLocation.startsWith('/parent/')`, defaulting to `AppRoutes.parentDashboard`. This is the actual core change this story makes.
2. `_RouterRefreshNotifier`/`ref.listen` bridge: **already correct, do not touch.**
3. `AppRoutes` constants: add `parentFamily = '/parent/family'`, `childPetRoom = '/child/pet-room'`, `childTasks = '/child/tasks'`, `childTasksNew = '/child/tasks/new'`, `childShop = '/child/shop'`. Change `parentDashboard`'s value from `/parent-dashboard` (flat) to `/parent/dashboard`, per ADR-0014's Migration Plan. Remove the now-superseded `petRoom = '/pet-room'` constant (replaced by `childPetRoom`) — check for any other reference to the old constant first (`grep -rn "AppRoutes.petRoom"`) and update it too if found.
4. This story only touches the `redirect` logic and route constants — it does NOT build the `StatefulShellRoute` trees themselves (Stories 002/003). For this story's own testing, replace the existing flat `GoRoute(path: AppRoutes.petRoom, ...)` and `GoRoute(path: AppRoutes.parentDashboard, ...)` placeholder routes with equivalent placeholder `GoRoute`s at the NEW paths (`/child/pet-room`, `/parent/dashboard`) — just enough for the redirect to resolve against something real. Stories 002/003 replace these placeholder `GoRoute`s with the real `StatefulShellRoute` trees.
5. Cold-start state: check whether `sessionStateProvider` (and its upstream `authStateProvider`) has a genuine async-resolution gap on `ProviderContainer` creation, or whether it's synchronously available — read `auth_providers.dart` in full to confirm before assuming either way. If a real gap exists, add a blank-`Scaffold` handling path; if not, document in Completion Notes that this criterion is satisfied trivially and no code change was needed.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **Story 002**: Child Shell's `StatefulShellRoute` (3 branches), Pet Room Flame preservation.
- **Story 003**: Parent Shell's `StatefulShellRoute` (2 branches).
- **Story 004**: Parent Override transition logic (this story's redirect passively supports `parentView`, but the override *trigger* — long-press, password confirm — is Story 004's).
- **Story 005**: Back-button handling, root-navigator push contract.
- **Story 006**: Floating chip cluster.
- Actual screen content for any hosted route (Login, Child Selector, Pet Room, etc.) — those already exist (Auth & Account, Complete) or belong to future epics.

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria — QL-STORY-READY gate skipped (Solo mode).*

- **AC-1**
  - Given: `sessionStateProvider` overridden to `unauthenticated`
  - When: router resolves initial location
  - Then: final route is `/login`, no intermediate route observed
  - Edge cases: app cold-started directly at a deep-linked non-login URL while unauthenticated — must still redirect to `/login`

- **AC-2**
  - Given: `sessionStateProvider` overridden to `parentAuthed`
  - When: router resolves
  - Then: final route is `/select-child`

- **AC-3 (initial route)**
  - Given: `sessionStateProvider` overridden to `childSelected`
  - When: router resolves
  - Then: final route is `/child/pet-room` (default branch)

- **AC-11**
  - Given: router at `/child/shop`, `sessionStateProvider` transitions to `unauthenticated` mid-session
  - When: `ref.listen` fires the refresh bridge
  - Then: router redirects to `/login`, does not remain at `/child/shop`

- **Cold-start**
  - Given: fresh `ProviderContainer`, before first read
  - When: root widget builds
  - Then: no exception, blank scaffold or resolved route — never a crash or infinite loading

- **`parentView` redirect**
  - Given: `sessionStateProvider` overridden to `parentView`
  - When: router resolves
  - Then: final route is `/parent/dashboard`, distinct code path from `childSelected`'s branch

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/main-navigation-shell/root_redirect_test.dart` — 14 tests, all passing (11 original + 3 boundary tests added during code review)
- `tests/integration/auth_account/router_redirect_test.dart` — 10 tests, all passing (pre-existing file, updated for the removed `petRoom` constant and the new independent-branch `parentView` behavior)

**Status**: [x] Created — 24/24 tests passing across both files, independently re-verified. Full suite: 368 passed / 1 pre-existing skip / 0 failures. `flutter analyze` clean.

## Completion Notes

**Completed**: 2026-07-19
**Criteria**: 6/6 passing (0 deferred)
**Deviations**: None from the ADR — but a real scoping correction was made mid-implementation: `router_provider.dart` was already substantially built by the Auth & Account epic (working `_RouterRefreshNotifier`/`ref.listen` bridge, tested `redirectForSessionState()`, correct `/select-child` naming) — this story became a targeted extension (splitting the `childSelected`/`parentView` redirect cases, adding new route constants) rather than the from-scratch rewrite the story's original Implementation Notes assumed. Corrected before implementation began, not discovered after the fact.

**Cold-start finding** (Implementation Notes §5, required to document here): no code change was needed. `sessionStateProvider` is a plain (non-async) `Provider<SessionState>` — `ref.watch(authStateProvider).value` on a still-`AsyncLoading` upstream `StreamProvider` resolves to `null` (not a thrown error, not a blocked read), so `sessionStateProvider` always has an immediate, synchronous value the instant it's first read. There is no "hasn't emitted yet" state at this layer for a blank `Scaffold` to occupy. The genuine async gap lives one layer up, in `authStateProvider` (Auth & Account's, ADR-0002's domain) — this story's `redirectForSessionState()` only ever receives an already-resolved `SessionState` enum value, and per the registry-locked constraint must not watch `authStateProvider` directly to work around that. Confirmed empirically during implementation (a fake auth stream's pending emission timer proved the upstream gap is real) and by direct source reading of the provider chain.

**Test Evidence**: Integration — 24 tests across both files (14 + 10), all independently re-verified
**Code Review**: Complete — `flame-specialist` + `qa-tester`, APPROVED WITH SUGGESTIONS. All 3 suggestions closed: fixed a stale `/pet-room` string literal in the pre-existing test file (both reviewers found this independently — real corroboration), added 3 boundary tests for exact `/child`/`/parent` and prefix-collision (`/child-foo`) cases, and annotated 2 intentional AC-traceability duplicate tests between the two files with cross-references to their canonical counterparts rather than silently leaving the duplication unexplained.

---

## Dependencies

- Depends on: None (Auth & Account epic Complete, `sessionStateProvider` already built).
- Unlocks: Stories 002, 003 (both need `routerProvider` to exist before their `StatefulShellRoute` trees can be wired in), and transitively Story 004.
