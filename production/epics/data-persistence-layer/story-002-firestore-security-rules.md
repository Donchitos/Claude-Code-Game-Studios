# Story 002: Deploy Firestore Security Rules

> **Epic**: Data Persistence Layer
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-16

## Context

**GDD**: `design/gdd/data-persistence-layer.md`
**Requirement**: `TR-data-persistence-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Firestore Schema & Persistence Strategy, Decision §5 (primary — base rule structure); ADR-0009: Task Lifecycle & Reward Integrity, §3 (secondary — the `tasks` reward-gate block)

**Engine**: Firestore Security Rules v2 (`rules_version = '2'`) | **Risk**: MEDIUM — the `tasks` reward-gate uses a CEL map-literal with quoted string keys, a less-commonly-written rules feature ADR-0009 itself flags as needing syntax verification.

**Control Manifest Rules (this layer)**:
- Required: "Security Rules must use explicit nested per-collection `match` blocks, NEVER a blanket recursive wildcard — rules are OR'd across matching blocks" — source: ADR-0003/ADR-0009
- Required: "Security Rule MUST reject mismatched `xuReward`/`energyReward` vs category table on `create`; reward/category fields immutable on `update`" — source: ADR-0009
- Required: "Rules map-literal keys MUST be quoted CEL strings, not JS-style bare keys" — source: ADR-0009
- Required: "Pending→approved/rejected status-transition constraint lives in the `tasks` match block itself, not a broader match" — source: ADR-0009 (this story does NOT implement that specific transition constraint — see Out of Scope; the block structure must simply not preclude it being added later)

## Scope Decision (user-approved, 2026-07-16)

This story deploys the **complete** `firestore.rules` file in one pass — including the `tasks` reward-gate block from ADR-0009 §3 — even though the Task Library epic (which will actually write to `tasks/{taskId}` documents) has no stories yet. Rationale: both ADR-0003 and ADR-0009 are `Accepted` with fully worked-out rule text; Security Rules are a single deployed file, and splitting deployment into "base now, tasks block later" would mean a second deployment story later for no benefit (nothing exercises the `tasks` block until Task Library's own client code writes to that path — an inert-but-correct rule sitting in the deployed file today is harmless). This also matches this epic's own overview: "It also owns... the base Security Rules structure."

## Known Environment Limitation (carried forward from auth-account Story 009)

Firestore Rules Unit Testing (`@firebase/rules-unit-testing`) requires the Firestore emulator, which requires a Java Runtime — **not available in this environment** (same gap Story 009 hit for the Cloud Functions emulator). This means the rules file cannot be automatically verified against real allow/deny behavior in this session. See Test Evidence below for how this gap is handled — it is disclosed up front, not discovered mid-implementation and quietly worked around.

---

## Acceptance Criteria

*From `design/gdd/data-persistence-layer.md`'s Firestore Security Rules section, ADR-0003 Decision §5, and ADR-0009 §3:*

- [x] `firestore.rules` exists at the repo root, `rules_version = '2'`, matching ADR-0003 Decision §5 + ADR-0009 §3's rule text exactly (not a paraphrase — the exact block structure, including the `rewardTable()`/`rewardOk()` CEL helper functions with quoted string keys).
- [x] `items/{itemId}`: `allow read: if request.auth != null; allow write: if false` (global read-only catalog, per ADR-0006).
- [x] `families/{parentId}`: `allow read, write: if request.auth.uid == parentId`.
- [x] `families/{parentId}/customTasks/{customTaskId}`: `allow read, write: if request.auth.uid == parentId`.
- [x] `families/{parentId}/children/{childId}`: `allow read, write: if request.auth.uid == parentId` (economy fields remain client-writable — the accepted MVP tradeoff from ADR-0003's Non-Goals, not a bug to fix in this story).
- [x] `families/{parentId}/children/{childId}/private/credentials`: `allow read, write: if request.auth.uid == parentId`.
- [x] `families/{parentId}/children/{childId}/inventory/{itemId}`: `allow read, write: if request.auth.uid == parentId`.
- [x] `families/{parentId}/children/{childId}/tasks/{taskId}`: `create` requires `status == 'pending'` AND `rewardOk(request.resource.data)`; `update` requires `xuReward`/`energyReward`/`categoryId` to be unchanged from the existing document (immutable reward/category fields).
- [x] No blanket recursive wildcard (`{document=**}`) anywhere in the file — every collection has its own explicit `match` block, per the OR'd-matching-blocks rule both ADRs flag as the reason the original draft was wrong.
- [x] `firebase.json` (already exists, from auth-account Story 009) references this `firestore.rules` file in its `firestore.rules` config key, so `firebase deploy --only firestore:rules` would pick it up correctly if run.

---

## Implementation Notes

*From ADR-0003 Decision §5 and ADR-0009 §3 (the exact rule text is already fully specified in both ADRs — this story transcribes it correctly, it does not design new rule logic):*

- Copy the rule text from ADR-0009 §3 verbatim for the `tasks` block (it already supersedes ADR-0003's earlier, less-complete version of that block) — do not hand-retype from memory, `Read` the ADR file directly and copy the exact CEL syntax.
- The `rewardTable()` function's keys (`'study'`, `'chores'`, etc.) MUST be quoted strings — ADR-0009 explicitly warns that JS-style bare-key object literal syntax does not parse in the Firestore rules language. This is the single most likely place to introduce a real bug by "cleaning up" the syntax.
- Deploying: check whether `firebase deploy --only firestore:rules` can actually run in this environment (it needs an authenticated Firebase CLI session, which may not be available non-interactively). If it cannot run here, do NOT silently skip — surface it explicitly as a manual step the user must run themselves (`firebase deploy --only firestore:rules`), matching this project's "downloading/deploying anything requires explicit user action" boundary for anything with real-world side effects outside this repo.
- This story does not implement the `tasks` status-transition constraint mentioned in the manifest's Required Patterns list ("pending→approved/rejected... lives in the tasks match block itself") — that specific `allow update` refinement is Parent Approval epic's responsibility (per ADR-0009's own Ordering Note: "It does NOT own the approve *transaction* mechanics"). This story's `tasks` block only implements the reward-integrity gate (create validation + reward-field immutability on update), which is everything ADR-0009 §3 actually specifies today.

---

## Out of Scope

- Story 001 (this epic): schema/path constants — this story consumes that schema but doesn't define it.
- Story 003 (this epic): `onTaskApproved` Cloud Function.
- The `tasks` status-transition constraint (pending→approved/rejected) — Parent Approval epic's future story, per ADR-0009's Ordering Note.
- Actually running `firebase deploy` if CLI auth isn't available in this environment — flag as a manual step, don't attempt to work around it.
- Firestore Rules Unit Testing via the emulator — blocked by the Java-runtime environment gap; see Test Evidence.

---

## QA Test Cases

*Lean review mode — QA-lead gate skipped. ADR-0003's Validation Criteria specifies the required coverage:*

> "Rules test (emulator): a session with `request.auth.uid != parentId` is denied all access to that family tree."

*This cannot run in this environment (no Java runtime for the Firestore emulator — see Known Environment Limitation above). The manual/deferred verification steps below stand in for it:*

```
Manual check: rules file matches the ADR text exactly
  Setup: firestore.rules written, ADR-0003 §5 and ADR-0009 §3 open side by side
  Verify: line-by-line comparison of every match block, the rewardTable()/rewardOk() functions,
    and the quoted-key CEL syntax
  Pass condition: no divergence from either ADR's rule text

Manual check: rules deploy cleanly (syntax validation)
  Setup: Firebase CLI available
  Verify: run `firebase deploy --only firestore:rules --dry-run` (if supported by the installed
    CLI version) or `firebase emulators:start --only firestore` briefly to confirm the rules
    file at least parses without a syntax error, even without running actual allow/deny test cases
  Pass condition: no CEL syntax error reported

DEFERRED — requires Java runtime / Firestore emulator, not available in this session:
  Full rules-unit-testing suite (@firebase/rules-unit-testing) asserting allow/deny behavior
  for every match block, including the tasks reward-gate's create/update conditions.
```

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/data_persistence/` — BLOCKING gate normally requires a passing integration test or a documented playtest record. Given the Java-runtime/emulator gap disclosed above, this story substitutes a **documented, explicit limitation record** (this section) plus the verification actually performed below, following the exact precedent set by auth-account Story 009 (Cloud Functions could not be emulator-tested either, for the same underlying reason).

**Status**: Better than planned — `firebase deploy --only firestore:rules --dry-run` was run against the real, pinned Firebase project (`pet-quest-39d38`, from `.firebaserc`) and **compiled successfully** ("cloud.firestore: rules file firestore.rules compiled successfully"). This is real server-side CEL compilation by Firebase's own backend, not a local guess — it confirms the `rewardTable()`/`rewardOk()` quoted-key map literal and every `match` block are syntactically valid. This is a non-destructive, read-only validation (dry-run makes no changes) — actually deploying (`firebase deploy --only firestore:rules`, without `--dry-run`) remains a manual step for the user per this project's boundary on side effects outside the repo. The line-by-line rule-text comparison against both ADRs (first manual check above) was also performed and found no divergence.

**Still deferred** — requires Java runtime / Firestore emulator, not available in this session: the full rules-unit-testing suite asserting actual allow/deny behavior (e.g. "a session with `request.auth.uid != parentId` is denied"). Syntax validity is confirmed; runtime allow/deny behavior is not automatically tested. Tracked as a gap for whenever Java becomes available in this environment or CI.

---

## Dependencies

- Depends on: Story 001 (this epic) — the schema/paths this rules file protects must be defined first, though in practice the rule text is already fully specified by the ADRs independent of Story 001's Dart code.
- Unlocks: Every downstream epic that writes to Firestore under a real security boundary (Task Library #8, Shop #13, Gacha/Loot #12, Pet Equipment #15, Parent Dashboard UI #21) — none of them are currently protected by any deployed rules file.

---

## Completion Notes

**Completed**: 2026-07-16

**Files changed**:
- `firestore.rules` — new, transcribed from ADR-0003 §5 (base structure) + ADR-0009 §3 (`tasks` reward-gate), deployed in full per the Scope Decision above.
- `firebase.json` — added `"firestore": {"rules": "firestore.rules"}` config key.

**Criteria**: 9/9 passing (verified by direct read/comparison against both ADRs plus a real `--dry-run` compile against the live Firebase project — see Test Evidence).

**Deviations**: None from the approved Scope Decision (deploy the full ruleset now, including the not-yet-exercised `tasks` block). Actual deployment (running `firebase deploy --only firestore:rules` for real) was intentionally NOT performed — that remains the user's own action per this project's side-effects-outside-the-repo boundary; only the non-destructive `--dry-run` compile check was run.

**Code Review**: Complete — `security-engineer`. Verdict: zero required changes, no exploitable gap found. Confirmed no blanket wildcard, correct `items` catalog rule, exact reward-table transcription with correctly quoted CEL keys, correct `create`/`update` gate logic (traced for batch-write bypass, indirect-field bypass, and grandfather-via-create-then-lock bypass — none found), and confirmed the client-writable economy-field tradeoff on `children`/`inventory`/`private/credentials` matches ADR-0003's Non-Goals rather than being an oversight. One suggestion noted for a later session (once Java/emulator is available): a drift-guard test asserting the app's reward table, `entities.yaml`, and this rules file's `rewardTable()` stay in sync, since they're three independently-maintained mirrors.

**Test Evidence**: `firestore.rules` compiled successfully via real `firebase deploy --dry-run` against `pet-quest-39d38`. Full Dart suite unaffected (this story has no Dart code): 120/120 passing (+1 pre-existing skip).
