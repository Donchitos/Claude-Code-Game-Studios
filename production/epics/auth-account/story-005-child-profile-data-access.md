# Story 005: Child Profile Data Access (Firestore reads)

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 2.5h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-001`, `TR-auth-account-002` (partial)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: `pinHash`/`pinSalt` should live in a `children/{childId}/private/credentials` sub-document, fetched only at PIN-entry, NOT on the `children/{childId}` document used to render the profile-selection list (avatar + name). This is defense-in-depth — a smaller memory-exposure window for credential data.

**Engine**: Flutter 3.44.4 / `cloud_firestore ^5.x` | **Risk**: LOW
**Engine Notes**: The exact schema path for the credential sub-document is formally owned by the Firestore Schema & Persistence Strategy ADR (ADR-0003) — this story implements against ADR-0002's recommended path, cross-check against ADR-0003 if its concrete schema differs before writing the query.

**Control Manifest Rules (this layer)**:
- Required: `pinHash`/`pinSalt` live in `children/{childId}/private/credentials`, fetched only at PIN-entry, never on the profile-list document
- (Core layer, cross-reference) Credentials sub-doc: `get()` only at PIN-entry, never streamed — source: ADR-0003

---

## Acceptance Criteria

*Derived from GDD Core Rule 1 (Data Model) and Tuning Knobs (max 4 profiles) — this story has no standalone GIVEN/WHEN/THEN block of its own in the GDD; it's the read-side plumbing several ACs depend on:*

- [x] The profile-selection list query reads only `name`, `avatarId`, `mochiName` from `children/{childId}` — it never fetches the `private/credentials` sub-document as part of listing.
- [x] The credentials sub-document (`pinHash`, `pinSalt`) is fetched via a separate, explicit `get()` call, only invoked at the moment of PIN entry (called by Story 004, not by this story's list query).
- [x] The profile list surfaces the max-4-profiles tuning knob (resolved list length). Enforcement/blocking a 5th profile is not implemented by this story — no "add child" story currently owns it; tracked as a gap (see Completion Notes).
- [x] Credentials are fetched with `get()`, never a `snapshots()` listener (matches the Core-layer cross-reference rule — no reason to stream data read once per PIN attempt).

---

## Implementation Notes

*Derived from ADR-0002 Decision §7:*

- Two distinct read paths, kept structurally separate (different functions/providers, not just different field selections on one query) so the "never on the profile-list document" rule can't be silently violated by a future refactor:
  1. `childProfilesProvider` (or similar) — lists `children/{parentId}` subcollection docs, selecting only the profile-display fields.
  2. A `getChildCredentials(childId)` function — one-shot `get()` on `children/{childId}/private/credentials`, called only from Story 004's `verifyChildPin`.
- Max 4 profiles (Tuning Knob, default 4, safe range 1–8) — this story's job is to make that count available/checkable (e.g. `childProfilesProvider`'s resolved list length); the UI-level creation-blocking behavior belongs to whichever "add child" flow exists (not explicitly covered by a GDD acceptance criterion in this epic — flag as a gap if no "add child" story exists elsewhere).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: the PBKDF2 compute/compare logic itself (this story only fetches the raw hash/salt)
- Story 007: writing new `pinHash`/`pinSalt` on reset (this story is read-only)
- Story 011: the Child Profile Selection Screen UI (blocked pending `/ux-design`)

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. No pre-existing qa-plan spec for this story; test against the acceptance criteria above directly:*

- **AC**: profile-list query never includes credential fields
  - Given: a `children/{childId}` doc with a `private/credentials` sub-document present
  - When: the profile-list provider resolves
  - Then: the resolved model has no `pinHash`/`pinSalt` field, and the underlying query never touched the `private` subcollection
- **AC**: credentials fetch is a one-shot `get()`, not a stream
  - Given: `getChildCredentials(childId)` is called
  - When: inspecting the Firestore call type
  - Then: it is a `DocumentReference.get()`, not `.snapshots()`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/auth_account/child_profile_data_test.dart` — must exist and pass

**Status**: [x] Created and passing (10 tests, all passing)

---

## Dependencies

- Depends on: Story 001 (needs `parentId` scope from an authenticated session)
- Unlocks: Story 004, Story 007, Story 009, Story 011 (blocked UI)

---

## Completion Notes
**Completed**: 2026-07-15
**Criteria**: 4/4 passing (AC-3 partial by design — surfaces the count, does not enforce the cap; see deviations)
**Deviations**:
- ADVISORY: `data-persistence-layer.md`'s `snapshots()` rule for child profile data scoped to the *active* child only — profile-selection list documented as a one-shot `get()` exception (user-approved via `AskUserQuestion`; documented in ADR-0003, `control-manifest.md`, and the GDD, all dated 2026-07-15).
- ADVISORY: max-4-profile *enforcement* (blocking a 5th profile) has no owning story anywhere in the auth-account epic — flagged for the producer, not actioned here (out of this story's stated scope).
**Test Evidence**: Integration — `tests/integration/auth_account/child_profile_data_test.dart` (10 tests, all passing; full suite 23/23)
**Code Review**: Complete — `/code-review` run this session, verdict APPROVED after fixing malformed-doc blast-radius issue and adding provider-layer test coverage
