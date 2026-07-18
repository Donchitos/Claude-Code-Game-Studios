# Story 003: onTaskApproved Cloud Function (storedEnergy Cap)

> **Epic**: Data Persistence Layer
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 2h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/data-persistence-layer.md`
**Requirement**: `TR-data-persistence-005`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Firestore Schema & Persistence Strategy, Decision §6

**Engine**: Firebase Cloud Functions 2nd-gen (`firebase-functions ^7.2.5`, `firebase-admin ^13.10.0` — pinned during auth-account Story 009, same `functions/` toolchain this story reuses) | **Risk**: LOW — `onDocumentUpdated` trigger and `FieldValue`-free plain field read/write are stable APIs, already proven working in this exact toolchain by Story 009's `onChildProfileDelete`.

**Control Manifest Rules (this layer)**:
- Required: "`onTaskApproved` Cloud Function (2nd-gen `onDocumentUpdated`) caps `storedEnergy` at 100 post-commit" — source: ADR-0003
- Forbidden: "Never route core-loop mutations (submit/approve/buy) through a Cloud Function as the primary path — breaks offline-first" — source: ADR-0003 (this function is a post-commit correction, not the primary approve path — the client's own `runTransaction` approve is still what actually grants the reward; this function only clamps an already-committed value)

## Already Established (do not re-derive)

- The `functions/` Node.js/TypeScript toolchain, `firebase.json`, `.firebaserc`, and the dependency-version pins (`firebase-admin ^13.10.0`, `typescript ^6.0.3`, `nodenext` module resolution) were all set up during auth-account Story 009. This story adds a new export to the existing `functions/src/index.ts`, it does not scaffold a new toolchain.
- Story 009's testing approach — `jest.mock` against `firebase-admin/firestore`, invoking the extracted handler logic directly (not via `CloudFunction.run()` unless needed for trigger-config verification), no Firestore/Functions emulator (Java runtime not available in this environment) — is the established, working pattern for this story to reuse.

---

## Acceptance Criteria

*From ADR-0003 Decision §6 and Validation Criteria ("Deploy check: `onTaskApproved` caps `storedEnergy` at 100"):*

- [x] `onTaskApproved` is a 2nd-gen `onDocumentUpdated` trigger on `families/{parentId}/children/{childId}`.
- [x] After any update to that document, if the resulting `storedEnergy > 100`, the function corrects it to exactly `100` via a plain field write (not `FieldValue.increment()` — this is a clamp, not a delta).
- [x] If `storedEnergy <= 100` after the update, the function does nothing (no write) — it must not fire on every single child-doc update indiscriminately when no correction is needed (the manifest's Risks note this function "triggers on ANY update to the child doc... not only on task approval," and self-limits by being a no-op when the cap isn't exceeded — implement that no-op check explicitly, don't rely on it being accidentally true).
- [x] The correction logic is extracted into a plain, directly unit-testable function (mirroring `cascadeDeleteChildSubcollections`'s extraction pattern from Story 009) — the thin `onDocumentUpdated` wrapper is the only part that needs trigger-config verification via `.__endpoint` inspection.
- [x] A unit test asserts: `storedEnergy = 150` → corrected to `100`; `storedEnergy = 100` exactly → no write issued; `storedEnergy = 80` → no write issued (boundary and no-op cases both covered, not just the "obviously over" case).

---

## Implementation Notes

*From ADR-0003 Decision §6 and the Risks section of ADR-0003's Consequences:*

- Read the `before`/`after` document data from the `onDocumentUpdated` event — the function needs the *new* value of `storedEnergy` (post-update), not the previous one.
- Use `getFirestore().doc(path).update({ storedEnergy: 100 })` (a plain field write) for the correction, never `FieldValue.increment()` — an increment here would be semantically wrong (this is "clamp to exactly 100," not "add/subtract a delta").
- This function does NOT reconcile the granted reward against `categoryId` — that's ADR-0009's "defense-in-depth" addition, to be implemented as a LATER extension of this same function when the Task Library epic lands (see Out of Scope). Do not attempt to build that piece now; there's no `categoryId`/task-reward data flowing through this trigger's scope yet (it fires on the `children/{childId}` document, not `tasks/{taskId}`).
- Match Story 009's precedent exactly for the trigger wrapper vs. extracted-logic split, and for how `.__endpoint` metadata inspection proves trigger configuration (event type, document path pattern) without invoking the handler — this keeps the two concerns (trigger wiring vs. correction logic) independently testable, as Story 009 established.

---

## Out of Scope

- Story 001 (this epic): schema/path constants.
- Story 002 (this epic): Security Rules.
- The reward-reconciliation "defense-in-depth" extension to this same function (ADR-0009 §3) — Task Library epic's future story will extend `onTaskApproved` with that logic; this story builds only the baseline cap-enforcement version ADR-0003 specifies.
- The client-side approve transaction itself (the actual reward grant) — Parent Approval epic's responsibility; this function only runs *after* that transaction has already committed.
- Firestore/Functions emulator end-to-end trigger-fire testing — same Java-runtime gap as Story 009; this story's tests target the extracted logic function directly (see Test Evidence), not a live emulator trigger fire.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0003's Validation Criteria specifies the required coverage:*

> "Deploy check: `onTaskApproved` caps `storedEnergy` at 100; `onChildProfileDelete` leaves no orphaned subcollection docs." (the `onChildProfileDelete` half is already covered by Story 009 — not re-tested here.)

```
Test: caps storedEnergy to exactly 100 when it exceeds the cap
  Given: a child document update resulting in storedEnergy = 150
  When: the extracted correction function runs against that document reference
  Then: a Firestore update is issued setting storedEnergy to exactly 100

Test: does not write when storedEnergy is exactly at the cap
  Given: a child document update resulting in storedEnergy = 100
  When: the extracted correction function runs
  Then: no Firestore write is issued (boundary case — must not loop/re-trigger itself unnecessarily)

Test: does not write when storedEnergy is under the cap
  Given: a child document update resulting in storedEnergy = 80 (e.g. an unrelated update like
    an item purchase, which also touches the child document per the manifest's noted risk)
  When: the extracted correction function runs
  Then: no Firestore write is issued

Test: trigger is correctly configured as onDocumentUpdated on the children/{childId} path
  Given: the deployed onTaskApproved function's .__endpoint metadata
  When: inspected (not invoked)
  Then: eventType is the 2nd-gen document-updated type, document path pattern matches
    families/{parentId}/children/{childId}
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `functions/test/index.test.ts` (extends the existing Story 009 test file) — must exist and pass. Same Java-runtime/emulator limitation as Story 002 applies to true end-to-end trigger-fire verification — the tests above target the extracted correction function and `.__endpoint` config directly, matching Story 009's established, working substitute for emulator testing.

**Status**: Created, 10/10 new tests passing (18/18 in the full `functions/test/index.test.ts` file, including Story 009's original 8)

---

## Dependencies

- Depends on: Story 001 (this epic) — not a hard blocker (this function operates on the `children/{childId}` document, which already has a path constant), but should land after Story 001 for consistency.
- Depends on: auth-account Story 009 (Complete) — the `functions/` toolchain this story extends.
- Unlocks: Task Library epic's later reward-reconciliation extension to this same function (ADR-0009 §3).

---

## Completion Notes

**Completed**: 2026-07-16

**Files changed**:
- `functions/src/index.ts` — added `STORED_ENERGY_CAP` constant, `enforceStoredEnergyCap()` (extracted, unit-testable), `onTaskApproved` (thin `onDocumentUpdated` trigger wrapper).
- `functions/test/index.test.ts` — 10 new tests across 3 describe blocks (`enforceStoredEnergyCap`, `onTaskApproved.run`, `onTaskApproved trigger wiring`); a `buildAfterSnapshot` test helper was promoted to module scope during code review so both new describe blocks share it, matching the file's existing helper-reuse style.

**Criteria**: 5/5 passing, all covered by automated tests.

**Deviations**: None. Reward reconciliation against `categoryId` (ADR-0009 §3's "defense-in-depth" extension to this same function) explicitly deferred to the Task Library epic, per this story's Out of Scope — not implemented here since no `tasks/{taskId}` data exists yet for this trigger's scope to reconcile against.

**Code Review**: Complete — `technical-director` (backend TypeScript, same routing exception auth-account Story 009 used in place of the Flutter/Flame specialist). Verdict: zero required changes, mergeable as-is. Two suggestions applied: (1) switched the cap guard from `typeof storedEnergy !== "number"` to `Number.isFinite(storedEnergy)` so a `NaN` value is correctly treated as malformed rather than silently clamped to 100; (2) the `onTaskApproved.run` test now reuses the shared `buildAfterSnapshot` helper instead of duplicating an inline mock, for structural symmetry with the `enforceStoredEnergyCap` block.

**Test Evidence**: `functions/test/index.test.ts` — 18/18 passing (10 new + Story 009's original 8). `npm run build` (tsc) clean. Full Dart suite unaffected (this story has no Dart code): 120/120 passing (+1 pre-existing skip).
