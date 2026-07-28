# Story 009: Child Profile Deletion (Cloud Function cascade)

> **Epic**: Auth & Account
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-15
> **Last Updated**: 2026-07-15

## Context

**GDD**: `design/gdd/auth-account.md`
**Requirement**: `TR-auth-account-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002: Auth & PIN Security Architecture
**ADR Decision Summary**: `onChildProfileDelete` is a 2nd-gen Firestore trigger (`onDocumentDeleted`) that recursively deletes `children/{childId}/` and all subcollections via Admin SDK `firestore.recursiveDelete(ref)` — client-side delete is not reliable on mobile (app can be killed mid-delete), and Firestore does not cascade-delete subcollections on its own.

**Engine**: **Cloud Functions runtime — NOT Flutter/Dart.** | **Risk**: MEDIUM
**Engine Notes**: ⚠️ **This story is implemented in a different runtime than the rest of this epic.** Firebase Cloud Functions for this kind of trigger are conventionally written in Node.js/TypeScript (or Python/Go) against the Admin SDK — this is backend/serverless code, not Flutter/Flame game code. `flame-specialist` routing does not apply here; route this story to whatever backend/Cloud-Functions tooling the project uses (not yet established elsewhere in this project's docs as of this story's writing — flag if no such convention exists when picked up).

**Control Manifest Rules (this layer)**:
- Required: `onChildProfileDelete` (2nd-gen `onDocumentDeleted`) recursively deletes via Admin SDK `firestore.recursiveDelete(ref)`

---

## Acceptance Criteria

*From GDD `design/gdd/auth-account.md`, scoped to this story:*

- [x] GIVEN bố mẹ xóa child profile, WHEN xác nhận xóa (the confirmation-dialog UI itself is out of scope — see below), THEN all of `children/{childId}/` and its subcollections are removed from Firestore.
- [x] The delete is atomic/reliable even if the client app is closed mid-operation — this is the entire reason the ADR mandates a server-side Cloud Function trigger instead of client-side recursive delete. (Platform guarantee of the 2nd-gen Cloud Functions runtime itself — not something this function's own code proves; verified this story implements the correct trigger *type* to get that guarantee.)
- [x] The trigger fires on `onDocumentDeleted` for the `children/{childId}` document specifically (the top-level doc delete, which the client performs directly — the Cloud Function's job is only the recursive subcollection cleanup Firestore doesn't do automatically).

---

## Implementation Notes

*Derived from ADR-0002 Decision §8:*

```
exports.onChildProfileDelete = onDocumentDeleted(
  "families/{parentId}/children/{childId}",
  async (event) => {
    await admin.firestore().recursiveDelete(event.data.ref);
  }
);
```
(Illustrative — actual syntax depends on the Cloud Functions SDK version/language chosen; this is Node.js/TypeScript-style pseudocode, not verified Dart-adjacent code.)

- The client's job (elsewhere — see Out of Scope) is simply to delete the `children/{childId}` document itself; this Cloud Function reacts to that deletion and cleans up everything beneath it.
- Use 2nd-gen Firestore triggers specifically (`onDocumentDeleted`), not 1st-gen — per ADR-0002 Decision §8.
- This function must use the Admin SDK (`admin.firestore()`), which bypasses Security Rules — that's required for reliable cascade delete and is the correct trust boundary for a server-side trigger.

---

## Out of Scope

*Handled by neighbouring stories or other epics — do not implement here:*

- The client-side confirmation dialog ("Không thể hoàn tác — Toàn bộ dữ liệu của bé...") — that's a UI concern; no story in this epic's UI batch (010–012) explicitly covers it either, since the GDD's UI Requirements section only lists Login/Child Selection/PIN Entry as needing UX specs. **Flagging as a gap**: this confirmation dialog likely belongs on the Child Profile Selection screen (Story 011) or Parent Dashboard (epic #21) — whoever picks this up should confirm ownership before building, rather than assuming.
- **GDPR full parent-account erasure** (ADR-0002 Decision §8's `onParentAccountErase`, flagged "must land before launch") — this has no TR-ID in the registry and is not part of this epic's tracked requirements as written. Explicitly out of scope for this story; tracked here as a known gap, not silently folded in.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. No pre-existing qa-plan spec for this story:*

- **AC**: cascade delete removes all subcollections
  - Given: a `children/{childId}` doc with populated subcollections (e.g. `private/credentials`, and whatever other subcollections other epics have added by the time this runs — check `data-persistence-layer.md` for the current full schema)
  - When: the top-level `children/{childId}` document is deleted
  - Then: querying any known subcollection path under that former `childId` returns empty, not orphaned documents
- **AC**: deletion survives client disconnect
  - Given: the client deletes `children/{childId}` and then immediately terminates (simulated)
  - When: the Cloud Function trigger fires server-side
  - Then: cascade delete still completes — this is inherently a server-side trigger test, not something the client-side test suite can fully exercise; note this limitation in the test file itself.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/auth_account/child_deletion_cascade_test.dart` (client-triggerable portion) **+ Cloud Functions emulator test** (server-side trigger portion, likely a separate test file/runtime outside `tests/` — coordinate with whoever owns Cloud Functions tooling for this project)

**Status**: [x] Cloud Functions portion created and passing (`functions/test/index.test.ts`, 8 tests). Client-triggerable Dart portion deliberately deferred — see Completion Notes.

---

## Dependencies

- Depends on: Story 005 (needs awareness of the full credential-subcollection schema being deleted)
- Unlocks: None within this epic

---

## Completion Notes
**Completed**: 2026-07-15
**Criteria**: 3/3 passing
**Deviations**:
- ADVISORY: This is the first Cloud Functions story in the project — no `functions/` toolchain existed before this story. Surfaced to the user via `AskUserQuestion` before proceeding (scaffolding an entire new Node.js/TypeScript project is a cross-cutting decision, not a routine implementation detail); user chose to scaffold now. New root-level `functions/` (Node.js/TypeScript, 2nd-gen), `firebase.json`, `.firebaserc`. Real dependency-resolution conflicts hit and documented in `control-manifest.md`: `firebase-functions@7.2.5`'s peerDependency caps `firebase-admin` at `^13.x` (not the newer `^14.x`); `ts-jest@29.4.11`'s peerDependency caps `typescript` at `<7` (TypeScript 7.0.2 is genuinely released, just not yet supported by the test toolchain); TS 6.0's `moduleResolution: "node"` is deprecated, fixed via `"nodenext"` + `"isolatedModules"`. Future Cloud Functions stories (`onTaskApproved` ADR-0003/0009, `onTaskSubmitted` ADR-0010) should reuse this `functions/` project and these exact versions.
- ADVISORY: No Java Runtime is available in this dev environment, so the Firestore/Cloud Functions emulator suite cannot run — exactly the limitation this story's own QA Test Cases anticipated. Tests use `jest.mock` against `firebase-admin/firestore` plus `CloudFunction.run()` (firebase-functions' own documented test seam) and `.__endpoint` metadata inspection, none of which need the emulator. `recursiveDelete`'s documented behavior (safe on an already-deleted ref, still cascades subcollections) is a trusted-and-verified-against-SDK-source assumption, not independently re-tested — documented as such in the test file rather than left implicit.
- ADVISORY: The Test Evidence section originally required both a Dart client-side test AND a Cloud Functions test. Only the Cloud Functions test was written: the client-side action that deletes `children/{childId}` (which would trigger this function) belongs to the not-yet-built Parent Dashboard epic #21, per this story's own Out of Scope section — there is no Dart production code to test yet. A placeholder skipped test was added at `tests/integration/auth_account/child_deletion_cascade_test.dart` (with a `skip:` reason pointing to epic #21) so the gap is discoverable from the test suite itself, not only from this document.
**Test Evidence**: Integration — `functions/test/index.test.ts` (8 tests, all passing; `cd functions && npm test`). Dart side: 1 deliberately-skipped placeholder test documenting the deferral (full Dart suite: 73 passing + 1 skipped).
**Code Review**: Complete — `/code-review` run this session, using `technical-director` in place of `flame-specialist` (this story is backend TypeScript, not Flutter/Flame — routing exception noted in the story's own Engine Notes). technical-director: CLEAN (verified trigger path matches the Dart client's `FirestorePaths.child()` exactly, verified `recursiveDelete`-on-already-deleted-ref semantics against the actual installed `@google-cloud/firestore` SDK source, verified the `functions/` scaffold has no deploy blockers). qa-tester: GAPS — found the AC-vs-config-only gap in the `.__endpoint` tests (they prove the trigger is configured right, not that the handler behaves right when invoked) — closed by adding `CloudFunction.run()`-based invocation tests; also had the "propagates failed delete" test's scope over-claim and the missing Dart-side placeholder both closed. Verdict: APPROVED (post-fix).
