# Story 003: go_router Session-Based Redirect

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: Because a plain Riverpod `Provider` is not `Listenable`, `go_router` requires an explicit refresh bridge (`GoRouterRefreshStream` over the session stream, or `ref.listen(sessionStateProvider, (_, __) => router.refresh())`) — without it the value updates but the redirect never re-runs. The ADR calls this "a binding contract item, not an implementation detail."

**Engine**: Flutter 3.44.4 / `go_router` + `flutter_riverpod` | **Risk**: MEDIUM
**Engine Notes**: The specific failure mode this story exists to prevent — `sessionStateProvider` updating correctly while the router silently never redirects — is easy to miss in manual testing (state looks right in DevTools) and only shows up as "app doesn't navigate after login," so the required Integration-level test evidence is not optional here.

**Control Manifest Rules (this layer)**:
- Required: `sessionStateProvider` is the single derived routing source of truth; no other system re-derives session state
- Required: go_router redirect MUST use an explicit refresh bridge (`GoRouterRefreshStream` or `ref.listen(sessionStateProvider, ...)`) since a plain Riverpod `Provider` is not `Listenable`

---

## Acceptance Criteria

*Derived from ADR-0002 Decision §5 and Validation Criteria (no direct GIVEN/WHEN/THEN block in the GDD covers routing plumbing specifically — this story's criteria come from the ADR's explicit contract):*

- [x] The router's `redirect` callback reads `sessionStateProvider` and only `sessionStateProvider` — it does not re-implement any part of the state derivation itself.
- [x] A refresh bridge (`GoRouterRefreshStream` or an equivalent `ref.listen` call) is wired so that a `sessionStateProvider` value change triggers `router.refresh()`. (`GoRouterRefreshStream` does not exist in `go_router ^17.3.0` — removed in v5.0.0, verified against installed package source — implemented via `ref.listen`; ADR-0002 corrected.)
- [x] Integration test: changing the upstream providers (e.g. simulating login) causes an actual redirect — not just a provider-value change with no navigation.

---

## Implementation Notes

*Derived from ADR-0002 Decision §5 and Architecture Diagram:*

- Do not skip the bridge because "the provider value looks correct in tests" — the ADR is explicit that this exact gap (value updates, redirect doesn't re-run) is the failure mode being guarded against.
- Two acceptable implementations per the ADR: `GoRouterRefreshStream` wrapping a stream derived from `sessionStateProvider`, or a direct `ref.listen(sessionStateProvider, (_, __) => router.refresh())` inside the router's construction scope. Pick one — do not implement both.
- The 4 `SessionState` values map to route groups as implied by GDD Core Rule 2 / States and Transitions diagram: `unauthenticated` → login route, `parentAuthed` → child profile selection route, `childSelected` → Pet Room route, `parentView` → Parent Dashboard route (overlaying, not replacing, the child route per Core Rule 5 — do not literally navigate away from Pet Room on override, since the GDD requires the child session to remain intact underneath).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: the `sessionStateProvider` derivation logic itself
- Story 010/011/012: the actual destination screens (blocked pending `/ux-design`) — this story only wires the redirect target routes, which can exist as placeholder route definitions until those UI stories land

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0002's Validation Criteria specifies the required coverage:*

> "Integration: go_router redirects on session-state change (proves the refresh bridge works)."

Concretely: simulate each of the 4 `sessionStateProvider` transitions in sequence (unauthenticated → parentAuthed → childSelected → parentView → childSelected) and assert the router's current location is correct at each step (via rendered screen content, not just the provider value) — for `unauthenticated`/`parentAuthed`/`childSelected` this means the location actually changes; for `parentView` this means it correctly stays on (or lands back on) `/pet-room`, per GDD Core Rule 5 (overlay, not replace).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/auth_account/router_redirect_test.dart` — must exist and pass

**Status**: [x] Created and passing (10 tests, all passing)

---

## Dependencies

- Depends on: Story 002 (needs `sessionStateProvider`)
- Unlocks: Story 010, Story 011, Story 012 (their navigation entry points depend on this routing being wired, even though their own UI is blocked)

---

## Completion Notes
**Completed**: 2026-07-15
**Criteria**: 3/3 passing
**Deviations**:
- ADVISORY: ADR-0002 §5 named `GoRouterRefreshStream` as an available refresh-bridge option; verified against the installed `go_router ^17.3.0` package source that it was removed from the package in v5.0.0 and is not re-exported. Implemented the other ADR-named option (`ref.listen(sessionStateProvider, ...)`) instead. Corrected in ADR-0002 and `control-manifest.md` (both dated 2026-07-15).
**Test Evidence**: Integration — `tests/integration/auth_account/router_redirect_test.dart` (10 tests, all passing; full suite 30/30)
**Code Review**: Complete — `/code-review` run this session, verdict APPROVED after fixing a real gap found by qa-tester (`parentView` reached from a non-`/pet-room` location now correctly forces the child route back underneath, per GDD Core Rule 5) and adding a regression test
**Follow-up suggestion (not blocking)**: qa-tester suggested a future smoke test that pumps the real `PetQuestApp` widget (not a hand-built `MaterialApp.router`) to directly exercise `main.dart`'s `ref.watch(routerProvider)` wiring — noted for whoever next touches routing, not actioned in this story.
