# Story 002: Riverpod Session Provider Contract (sessionStateProvider)

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 2h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: `sessionStateProvider` is a Riverpod `Provider<SessionState>` deriving a 4-state enum (`unauthenticated`, `parentAuthed`, `childSelected`, `parentView`) from three upstream providers. It is the single routing source of truth — no other system re-derives session state.

**Engine**: Flutter 3.44.4 / `flutter_riverpod` | **Risk**: MEDIUM
**Engine Notes**: ⚠️ **Version-sensitive** — ADR-0002's Correction note (2026-07-13) found `riverpod` 3.x removed `AsyncValue.valueOrNull`; `.value` is now the safe non-throwing nullable accessor on that version. The epic's own exit-criteria note repeats this: **before writing this provider, confirm the actual pinned `riverpod` version in this project's `pubspec.yaml` and verify which accessor (`.value` vs `.valueOrNull`) is safe for that exact version** — do not assume 3.x is still current by the time this story is implemented.

**Control Manifest Rules (this layer)**:
- Required: `sessionStateProvider` is the single derived routing source of truth; no other system re-derives session state
- Required: Use the safe nullable accessor on `authStateProvider` — on `riverpod` 3.x this is `.value` (verify against the pinned production version)
- Forbidden: none specific to this story beyond the general accessor-correctness rule above

---

## Acceptance Criteria

*Derived from GDD Core Rule 2 (App Session States) and the Riverpod Provider Contract — no GIVEN/WHEN/THEN block in the GDD maps 1:1 to this provider alone, so these are drawn directly from the contract's own required behavior and ADR-0002's Validation Criteria:*

- [x] `SessionState` enum has exactly 4 values: `unauthenticated`, `parentAuthed`, `childSelected`, `parentView`.
- [x] `sessionStateProvider` returns `unauthenticated` when `authStateProvider`'s safe-accessed value is `null`.
- [x] `sessionStateProvider` returns `parentAuthed` when the user is non-null and `activeChildProvider` is `null`.
- [x] `sessionStateProvider` returns `childSelected` when a child is active and `parentOverrideProvider` is `false`.
- [x] `sessionStateProvider` returns `parentView` when a child is active and `parentOverrideProvider` is `true`.
- [x] An `authStateProvider` `AsyncError` degrades to `unauthenticated` rather than throwing (ADR-0002 Validation Criteria).

---

## Implementation Notes

*Derived from ADR-0002 Decision §5 and Key Interfaces:*

```dart
enum SessionState { unauthenticated, parentAuthed, childSelected, parentView }

final activeChildProvider    = StateProvider<ChildProfile?>((ref) => null);
final parentOverrideProvider = StateProvider<bool>((ref) => false);

final sessionStateProvider = Provider<SessionState>((ref) {
  final user = ref.watch(authStateProvider).value; // verify accessor per Engine Notes above
  if (user == null) return SessionState.unauthenticated;
  final activeChild = ref.watch(activeChildProvider);
  if (activeChild == null) return SessionState.parentAuthed;
  return ref.watch(parentOverrideProvider)
      ? SessionState.parentView
      : SessionState.childSelected;
});
```

- `activeChildProvider` and `parentOverrideProvider` are declared here as the provider contract, but this story does not write meaningful values into them — Story 004 sets `activeChildProvider` on successful PIN verify, Story 006 sets `parentOverrideProvider` on reauthentication. This story only needs the derivation logic to be correct for all combinations.
- All 4 providers live in `lib/providers/auth_providers.dart`, matching the GDD's single-file contract.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: `authStateProvider` itself (this story only consumes it)
- Story 003: go_router reading this provider and the `GoRouterRefreshStream` bridge — a plain `Provider` is not `Listenable`, so routing integration is a separate story by design (see ADR-0002 Decision §5's own framing of this as "a binding contract item")
- Story 004: writing real values into `activeChildProvider`
- Story 006: writing real values into `parentOverrideProvider`

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0002's Validation Criteria already specifies the required coverage directly — implement against it verbatim rather than inventing new cases:*

> "Unit test: `sessionStateProvider` returns the correct state for all combinations of (user null/non-null) × (activeChild null/non-null) × (override true/false), including that an `authStateProvider` error degrades to `unauthenticated` rather than throwing."

That is 5 required cases (the 3×2×2 combination space collapses to fewer meaningful states since `activeChild == null` short-circuits before `override` matters) plus the error-degradation case. Enumerate all reachable combinations explicitly in the test file.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/auth_account/session_state_provider_test.dart` — must exist and pass

**Status**: [x] Created — 7/7 tests passing (6 AC + 1 bonus `AsyncLoading` case added during code review)

---

## Dependencies

- Depends on: Story 001 (needs `authStateProvider` to exist)
- Unlocks: Story 003, Story 004, Story 006

---

## Completion Notes

**Completed**: 2026-07-15
**Criteria**: 6/6 passing, +1 bonus test added during code review
**Deviations**: None. Real API-location fact (not a design deviation): `StateProvider` lives at `package:flutter_riverpod/legacy.dart` in riverpod 3.3.2, not the main barrel — documented in-code, verified against actual installed package source (confirmed not deprecated, safe to use).
**Test Evidence**: Logic: `tests/unit/auth_account/session_state_provider_test.dart` — 7/7 passing
**Code Review**: Complete — `/code-review` verdict APPROVED (flame-specialist + qa-tester, parallel). 2 findings fixed before closing: (1) `ChildProfile`'s "extend" doc comment clarified to prevent a likely Dart-subclassing misread by whoever picks up Story 005; (2) added a test for the `AsyncLoading` → `unauthenticated` case, previously verified only by reading riverpod source, not by an executable test — closes the same category of risk that produced the `.valueOrNull` correction earlier in this project.
**Real defects found and fixed during implementation** (verified firsthand): `StateProvider` export relocation in riverpod 3.3.2 (fixed via `legacy.dart` import); `authStateProvider.overrideWith((ref) => stream)` compiled but hung at runtime in tests — switched to `overrideWithValue(AsyncValue...)`, later explained by flame-specialist as likely caused by riverpod 3.x's `StreamProvider` pausing its subscription when not actively listened.
