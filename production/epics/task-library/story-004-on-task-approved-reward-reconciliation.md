# Story 004: onTaskApproved Reward Reconciliation (Defense-in-Depth)

> **Epic**: Task Library
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/task-library.md`
**Requirement**: `TR-tasklib-002` (the remaining, defense-in-depth half — the primary Security Rule half is already deployed)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Task Lifecycle & Reward Integrity, Decision §3 (Security Rule primary + Cloud Function defense-in-depth)

**Engine**: Node.js/TypeScript (Firebase Cloud Functions, `functions/` — a different runtime from `src/`, see `docs/architecture/adr-0002-auth-pin-security-architecture.md` §8) | **Risk**: LOW-MEDIUM — extending an EXISTING, already-tested function (`onTaskApproved`, Data Persistence Layer Story 003) rather than writing a new trigger from scratch; the risk is entirely in getting the reconciliation LOGIC right (detecting drift, deciding what "fixing" means), not in Cloud Functions plumbing.

**Control Manifest Rules (this layer)**:
- Required: "`onTaskApproved` additionally reconciles granted reward against `categoryId` (defense-in-depth)" — source: ADR-0009
- Required: "`onTaskApproved` Cloud Function (2nd-gen `onDocumentUpdated`) caps `storedEnergy` at 100 post-commit" — source: ADR-0003 (the EXISTING behavior this story extends, must not regress)

## Already Established (do not re-derive)

- `onTaskApproved` (`functions/src/index.ts`) already exists (Data Persistence Layer Story 003) — a 2nd-gen `onDocumentUpdated` trigger on `families/{parentId}/children/{childId}` that calls `enforceStoredEnergyCap(event.data?.after)`. This story ADDS a second reconciliation call to the SAME trigger handler, does not create a new function or a new trigger.
- The function's own doc comment (lines 66-69 as of this story's authoring) explicitly flags this exact gap: "Does NOT reconcile the granted reward against `categoryId` — that defense-in-depth addition (ADR-0009 §3) belongs to the Task Library epic's future extension of this same function, once `tasks/{taskId}` documents and their reward fields actually exist to reconcile against." That epic is THIS one.
- The PRIMARY guard (the Security Rule) is already deployed and `security-engineer`-reviewed — `firestore.rules`' `tasks/{taskId}` block. This story's reconciliation is explicitly a BACKSTOP for drift that could theoretically occur despite the rule (e.g. a rule bypass, a bug, legacy/corrupted data) — not the primary defense.
- `enforceStoredEnergyCap` was already extracted as a plain, directly-unit-testable function (not embedded in the trigger handler) — same pattern this story should follow for its own new reconciliation function.

---

## Acceptance Criteria

*From ADR-0009 Decision §3 ("Defense-in-depth: the existing `onTaskApproved` Cloud Function additionally reconciles the granted reward against `categoryId`") and Validation Criteria ("`onTaskApproved` reconciliation flags no drift on a correct task"):*

- [x] `onTaskApproved`'s trigger handler, when the child document update corresponds to a task transitioning to `approved` status, checks whether the reward that was granted (inferred from the `xuBalance`/`storedEnergy` delta, OR read directly from the just-approved `tasks/{taskId}` document if the trigger has access to it) matches what `categoryId`'s row in the reward table says it should be. *(Implemented as a separate trigger reading the task document's own fields directly — see Completion Notes for the resolved design decision.)*
- [x] On a CORRECT task (reward matches the table), the reconciliation is a no-op — no write, no log noise, matching `enforceStoredEnergyCap`'s existing no-op-on-the-common-case discipline.
- [x] On a genuinely mismatched reward (the defensive/legacy-data case the ADR anticipates, not expected in normal operation since the rule already prevents it), the function logs the drift explicitly (structured log, not a silent swallow) — this story does NOT need to auto-correct the balance (that's a separate, riskier decision the ADR doesn't mandate; "flags/corrects" per the ADR's Decision §3 wording — flagging via logging satisfies the requirement; auto-correction is optional and should be treated as a follow-up decision, not silently implemented without being called out).
- [x] The EXISTING `enforceStoredEnergyCap` behavior is unchanged and still tested — this story adds a SECOND reconciliation concern to the same trigger, it does not replace or refactor the first one.
- [x] The new reconciliation logic is extracted as its own plain, directly-unit-testable function (matching `enforceStoredEnergyCap`'s established pattern), not embedded inline in the `onDocumentUpdated` handler body.
- [x] The trigger's own doc comment is updated to remove the "Does NOT reconcile..." caveat and describe the new behavior instead — the doc comment must not go stale relative to the code.

---

## Implementation Notes

*From ADR-0009 Decision §3 and the existing `onTaskApproved` code shape:*

- **Real design question this story must resolve, not assume**: `onTaskApproved` triggers on the CHILD document (`families/{parentId}/children/{childId}`), not on the TASK document itself. To reconcile a specific task's reward, the function needs to know WHICH task was just approved and what ITS `xuReward`/`categoryId` were. Options: (a) also read the task document (requires knowing its ID — is the task ID embedded anywhere in the child-document update, e.g. a `lastApprovedTaskId` field? Check the actual schema per `data-persistence-layer.md`/ADR-0003 before assuming this field exists); (b) change the trigger to ALSO listen on `tasks/{taskId}` updates (a second trigger, or an additional `onDocumentUpdated` on the task path) and reconcile that specific document's own `xuReward`/`categoryId` against the table directly, independent of the child-document delta. Investigate the actual schema and existing trigger shape before deciding — do not guess a field that may not exist. Given `onTaskApproved` currently ONLY watches the child document (per Data Persistence Layer Story 003), and the reward table check is fundamentally about ONE task document's own `xuReward` vs `categoryId` (not a balance delta), **option (b) — reconciling by reading the task document's own fields directly — is very likely simpler and more directly correct** than trying to infer anything from the child-document's balance delta. Confirm this design choice is sound before implementing broadly.
- Given the above, the most likely correct shape: EITHER extend `onTaskApproved` to trigger on the `tasks/{taskId}` document's own status transition to `approved` (a `onDocumentUpdated` on `families/{parentId}/children/{childId}/tasks/{taskId}`, checking `event.data?.before.data().status !== 'approved' && event.data?.after.data().status === 'approved'`), reading that SAME document's `categoryId`/`xuReward`/`energyReward` and comparing against the reward table directly — no delta inference needed at all. This may mean adding a SEPARATE Cloud Function trigger (on the task path) rather than literally extending the existing child-document trigger, despite the ADR's phrasing "the existing `onTaskApproved` Cloud Function... reconciles" — if a second trigger is the technically correct shape, implement it that way and document the deviation from a literal reading of the ADR's wording, since the ADR's own intent (defense-in-depth reconciliation exists) is preserved either way.
- Mirror the reward table exactly as already deployed in `firestore.rules`' `rewardTable()` CEL function and Story 001's Dart `rewardFor()` — THREE independent mirrors now exist (rules, Dart, and this TypeScript copy) per ADR-0009's own flagged risk ("Reward-table drift across the 3 mirrors... a change is a 3-file edit"). Add a comment in the TypeScript copy explicitly cross-referencing the other two, matching the established documentation discipline in this codebase.
- Follow the EXISTING `enforceStoredEnergyCap` extraction pattern exactly: a plain exported async function taking a snapshot (or the relevant document data) as its parameter, directly unit-testable via `jest.mock` against `firebase-admin` (no live emulator needed, per this project's established Java-Runtime-unavailable constraint), wired into the actual trigger as a thin wrapper.

---

## Out of Scope

- The PRIMARY Security Rule gate — already deployed (Data Persistence Layer Story 002); this story does not touch `firestore.rules`.
- Auto-correcting a detected reward mismatch (writing a corrected balance) — the ADR's own "flags/corrects" wording is ambiguous on this point; this story implements the FLAGGING (logging) half only, per its own Acceptance Criteria's explicit note. If auto-correction is later decided to be needed, that's a follow-up story requiring its own design decision (what does "correct" mean after the fact — reverse the bad grant? re-derive and top up? — genuinely non-trivial), not something to improvise here.
- `enforceStoredEnergyCap`'s existing behavior — already Complete (Data Persistence Layer Story 003); this story must not regress it, but does not re-implement or re-review it beyond confirming it's still tested.
- `TaskModel`, `rewardFor()`, the providers, `customTasks` — Stories 001-003 (this epic).

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. Derived from ADR-0009 Decision §3 and Validation Criteria ("`onTaskApproved` reconciliation flags no drift on a correct task"):*

```
Test: a correctly-rewarded approved task triggers no reconciliation write/log
  Given: a task document transitioning to status='approved' with categoryId='chores',
    xuReward=15, energyReward=25 (matching the table exactly)
  When: the reconciliation function runs
  Then: no drift is flagged, no write is issued (no-op on the common case, matching
    enforceStoredEnergyCap's own discipline)

Test: a mismatched-reward approved task is flagged (logged), not silently ignored
  Given: a task document transitioning to status='approved' with categoryId='chores' but
    xuReward=999 (a hypothetical drift/legacy-data/bug scenario — NOT reachable via the normal
    client given the already-deployed create-time rule, but must still be handled defensively)
  When: the reconciliation function runs
  Then: a structured log entry is emitted flagging the mismatch — the function does not throw,
    does not crash, and (per this story's explicit scope) does not attempt to auto-correct
    the balance

Test: an unknown/invalid categoryId on an approved task is flagged, not treated as valid
  Given: a task document with categoryId='not_a_real_category', approved
  When: the reconciliation function runs
  Then: flagged as a mismatch (the categoryId doesn't resolve to any table entry) — not
    silently treated as matching some default

Test: enforceStoredEnergyCap's existing behavior is unchanged
  Given: the existing test cases for enforceStoredEnergyCap (already passing from Data
    Persistence Layer Story 003)
  When: the full functions test suite is re-run after this story's changes
  Then: all pre-existing tests still pass — no regression from the new reconciliation logic
    being added alongside it

Test: the reconciliation logic is a plain, directly-unit-testable exported function
  Given: the new function's export
  When: called directly with a constructed snapshot/document-data argument (no live emulator,
    matching enforceStoredEnergyCap's own jest.mock-against-firebase-admin pattern)
  Then: testable without any Firestore emulator or Java Runtime dependency
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `functions/test/index.test.ts` (extends the existing suite) — must exist and pass

**Status**: [x] Created/extended — `functions/test/index.test.ts`, 40/40 passing (full suite, including this story's additions).

---

## Dependencies

- Depends on: Story 001 (this epic) — conceptually mirrors the same reward table (a fresh TypeScript copy, not shared code across the Dart/Node.js runtime boundary). Also depends on Data Persistence Layer Story 003 (Complete) — the existing `onTaskApproved` function this story extends.
- Unlocks: Full defense-in-depth coverage for TR-tasklib-002 — completes the "Security Rule primary + Cloud Function backstop" design ADR-0009 Decision §3 specifies. No downstream epic is blocked waiting on this story specifically (the primary rule already protects the economy); this closes the documented gap the existing function's own doc comment flags.

---

## Completion Notes

**Closed**: 2026-07-16

**Design decision resolved** (per Implementation Notes' own open question): implemented as a NEW, SEPARATE 2nd-gen `onDocumentUpdated` trigger, `onTaskRewardReconciliation`, watching `families/{parentId}/children/{childId}/tasks/{taskId}` directly — rather than a literal extension of the existing `onTaskApproved` (which watches the CHILD document for the unrelated `storedEnergy` cap and has no way to know which task was just approved from a balance delta alone). Reconciles the task document's own `categoryId`/`xuReward`/`energyReward` fields directly against a third TypeScript mirror of the reward table (`REWARD_TABLE` in `functions/src/index.ts`, alongside `firestore.rules`' `rewardTable()` and Dart's `rewardFor()`). Deviation from ADR-0009 Decision §3's literal wording documented in the trigger's own doc comment.

**Code review**: security-engineer (CHANGES REQUIRED — 1 blocking) + qa-tester (GAPS) run in parallel.

1. **Blocking, security-engineer**: `REWARD_TABLE[categoryId]` was a plain bracket lookup on a `{}` object literal, vulnerable to JS prototype-chain collision — `categoryId: 'constructor'` resolved to the built-in `Object` function (truthy) instead of `undefined`, so a corrupted/legacy task with `categoryId: 'constructor'` and missing `xuReward`/`energyReward` would silently pass as "no mismatch," defeating the exact unknown-`categoryId` case the story's own AC requires to always be flagged. Fixed: guarded the lookup with `typeof categoryId === 'string' && Object.hasOwn(REWARD_TABLE, categoryId)`. Confirmed the primary Security Rule (CEL `rewardTable()`/`in`) is NOT vulnerable to the same class of bug — only this new TypeScript mirror was affected. Added regression tests for `'constructor'`, `'__proto__'`, `'toString'` categoryIds.
2. **GAPS, qa-tester**: mismatch-log assertions used `objectContaining` (didn't pin `taskPath` or the full payload); missing coverage for malformed `categoryId`/`xuReward` (undefined, null, NaN, string type-drift); missing coverage for a non-`pending` prior status (`rejected → approved`) transitioning into approved; missing coverage for the asymmetric `before`/`after`-individually-undefined case (collapsed into the same test as `event.data` itself undefined). All four actioned: tightened mismatch assertions to full-payload `toHaveBeenCalledWith`, added `test.each`-driven malformed-input coverage (which also covers the security-engineer's prototype-bypass fix), added a `rejected → approved` transition test, and fixed the test helper (`buildTaskUpdateEvent`) to distinguish "event.data itself undefined" from "only one of before/after undefined" as genuinely separate cases.

Both reviewers independently confirmed the separate-trigger design is sound (no missed-fire or double-fire path), the primary Security Rule remains fully independent and sufficient for reward-value integrity (the Cloud Function is genuinely redundant-by-design, not compensating for a rule gap), and `enforceStoredEnergyCap`'s existing behavior is untouched and still passing.

**Test evidence**: `functions/test/index.test.ts` — 40/40 passing (11 pre-existing + 29 new/extended for this story). `npx tsc --noEmit` and `npm run build` both clean.
