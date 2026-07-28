// Run with:
//   cd functions && npm test
//
// No Java Runtime is available in this environment, so the Firestore/Cloud
// Functions emulator suite cannot run here — this file cannot exercise a
// real end-to-end trigger fire (client deletes a doc -> emulator invokes the
// deployed function -> Firestore is queried for the cascade result). That
// gap is explicitly acknowledged by the story itself ("this is inherently a
// server-side trigger test, not something the client-side test suite can
// fully exercise; note this limitation in the test file itself").
//
// What IS covered, without the emulator:
//   1. cascadeDeleteChildSubcollections — the actual cascade-delete logic,
//      extracted as a plain function and unit-tested here with
//      firebase-admin/firestore mocked via jest.mock (no real Firestore
//      connection, no credentials needed).
//   2. onChildProfileDelete's trigger wiring — verified via the exported
//      CloudFunction's real `.__endpoint` metadata (platform, event type,
//      document path pattern), which firebase-functions populates at module
//      load time regardless of whether the function ever actually runs.
//      Confirmed by direct inspection this metadata is genuine and
//      accurate — not assumed from documentation.
//   3. onChildProfileDelete.run(event) — firebase-functions' own documented
//      test seam for invoking the actual handler with a constructed event,
//      closing the gap between "configured correctly" (#2) and "does the
//      right thing when it fires" (found in code review — code-review
//      2026-07-15, previously only proven at the extracted-function level).
//
// What is NOT covered, and is a trusted SDK assumption rather than a tested
// property: whether `firestore.recursiveDelete()` genuinely handles being
// called with an ALREADY-DELETED document's own ref as a safe no-op for
// that ref while still walking and deleting its subcollections. This
// project's code relies on that documented `@google-cloud/firestore`
// behavior (see the doc comment on `cascadeDeleteChildSubcollections` in
// `../src/index.ts`) but doesn't re-verify it here, since `recursiveDelete`
// itself is mocked out — re-testing a third-party SDK's own documented
// behavior is out of scope for this project's unit tests. A real emulator
// run would be the way to verify this claim directly, and remains blocked
// by the missing Java Runtime.

import type { DocumentReference, QueryDocumentSnapshot } from "firebase-admin/firestore";

const recursiveDeleteMock = jest.fn().mockResolvedValue(undefined);
const docGetMock = jest.fn();
const docMock = jest.fn((path: string) => ({ get: () => docGetMock(path) }));
const messagingSendMock = jest.fn().mockResolvedValue("message-id");

// Added for Seed Buffer Story 003 (`reconcileSeedCountDrift`) — the FIRST
// story needing `runTransaction`/`collection`/`where`/`get` mocking, so
// none of this scaffolding existed before. Kept deliberately simple/fake
// rather than a full in-memory Firestore simulator: `runTransactionMock`
// just invokes the passed callback with `fakeTransaction` synchronously
// (matching how Firestore actually awaits the callback, just without real
// retry/contention behavior — that behavior is a trusted SDK assumption,
// same category as `recursiveDelete`'s no-op-on-deleted-ref assumption
// documented in this file's header comment, not something a unit test can
// verify without the emulator). `transactionGetMock` is what test cases
// configure per-test (via `mockResolvedValueOnce({ size: N })`) to control
// the "actual pending count" `reconcileSeedCountDrift` reads.
const transactionGetMock = jest.fn();
const transactionUpdateMock = jest.fn();
const fakeTransaction = {
  get: transactionGetMock,
  update: transactionUpdateMock,
};
const runTransactionMock = jest.fn(
  (callback: (transaction: typeof fakeTransaction) => Promise<void>) =>
    callback(fakeTransaction)
);
const collectionWhereMock = jest.fn((field: string, op: string, value: unknown) => ({
  field,
  op,
  value,
}));
const collectionMock = jest.fn((path: string) => ({
  path,
  where: collectionWhereMock,
}));

jest.mock("firebase-admin/app", () => ({
  initializeApp: jest.fn(),
}));

jest.mock("firebase-admin/firestore", () => ({
  getFirestore: () => ({
    recursiveDelete: recursiveDeleteMock,
    doc: docMock,
    collection: collectionMock,
    runTransaction: runTransactionMock,
  }),
}));

jest.mock("firebase-admin/messaging", () => ({
  getMessaging: () => ({
    send: messagingSendMock,
  }),
}));

import {
  cascadeDeleteChildSubcollections,
  enforceStoredEnergyCap,
  onChildProfileDelete,
  onTaskApproved,
  onTaskRewardReconciliation,
  onTaskSubmitted,
  reconcileSeedCountDrift,
  reconcileTaskReward,
  sendTaskSubmittedNotification,
} from "../src/index";

describe("cascadeDeleteChildSubcollections", () => {
  beforeEach(() => {
    recursiveDeleteMock.mockClear();
  });

  test("test_cascadeDeleteChildSubcollections_calls_recursiveDelete_with_the_deleted_ref", async () => {
    const fakeRef = { path: "families/parent-1/children/child-1" } as DocumentReference;

    await cascadeDeleteChildSubcollections(fakeRef);

    expect(recursiveDeleteMock).toHaveBeenCalledTimes(1);
    expect(recursiveDeleteMock).toHaveBeenCalledWith(fakeRef);
  });

  test("test_cascadeDeleteChildSubcollections_is_a_no_op_when_ref_is_undefined", async () => {
    await cascadeDeleteChildSubcollections(undefined);

    expect(recursiveDeleteMock).not.toHaveBeenCalled();
  });

  test("test_cascadeDeleteChildSubcollections_propagates_a_failed_delete", async () => {
    // Proves this function doesn't swallow a rejected recursiveDelete —
    // NOT a test of Cloud Functions' own retry/redelivery behavior on a
    // rejected handler promise, which is a platform-level concern
    // (governed by the trigger's `retry` config) outside this function's
    // code and outside what a unit test can exercise (found in code
    // review — code-review 2026-07-15).
    recursiveDeleteMock.mockRejectedValueOnce(new Error("simulated partial delete failure"));
    const fakeRef = { path: "families/parent-1/children/child-1" } as DocumentReference;

    await expect(cascadeDeleteChildSubcollections(fakeRef)).rejects.toThrow(
      "simulated partial delete failure"
    );
  });
});

describe("onChildProfileDelete.run (handler invocation, no emulator needed)", () => {
  // CloudFunction.run(event) is firebase-functions' own documented test
  // seam ("Use `run` to test a function.", core.d.ts) — it calls the
  // handler directly with an already-parsed FirestoreEvent, closing the gap
  // between "the trigger is configured correctly" (the __endpoint tests
  // below) and "the handler does the right thing when it actually fires"
  // (found in code review — code-review 2026-07-15).
  beforeEach(() => {
    recursiveDeleteMock.mockClear();
  });

  function buildDeletedEvent(ref: DocumentReference | undefined) {
    return {
      data: ref ? ({ ref } as unknown) : undefined,
      params: { parentId: "parent-1", childId: "child-1" },
    } as Parameters<typeof onChildProfileDelete.run>[0];
  }

  test("test_onChildProfileDelete_run_forwards_the_deleted_ref_to_the_cascade_delete", async () => {
    const fakeRef = { path: "families/parent-1/children/child-1" } as DocumentReference;

    await onChildProfileDelete.run(buildDeletedEvent(fakeRef));

    expect(recursiveDeleteMock).toHaveBeenCalledTimes(1);
    expect(recursiveDeleteMock).toHaveBeenCalledWith(fakeRef);
  });

  test("test_onChildProfileDelete_run_is_a_no_op_when_event_data_is_undefined", async () => {
    await onChildProfileDelete.run(buildDeletedEvent(undefined));

    expect(recursiveDeleteMock).not.toHaveBeenCalled();
  });
});

describe("onChildProfileDelete trigger wiring", () => {
  const endpoint = (onChildProfileDelete as unknown as { __endpoint: any }).__endpoint;

  test("test_onChildProfileDelete_is_a_2nd_gen_function", () => {
    expect(endpoint.platform).toBe("gcfv2");
  });

  test("test_onChildProfileDelete_listens_for_onDocumentDeleted", () => {
    expect(endpoint.eventTrigger.eventType).toBe(
      "google.cloud.firestore.document.v1.deleted"
    );
  });

  test("test_onChildProfileDelete_watches_the_correct_document_path", () => {
    expect(endpoint.eventTrigger.eventFilterPathPatterns.document).toBe(
      "families/{parentId}/children/{childId}"
    );
  });
});

// Shared by both the `enforceStoredEnergyCap` and `onTaskApproved.run`
// describe blocks below — a QueryDocumentSnapshot-shaped fake exposing
// only the two members either code path touches (`data()`, `ref.update`).
function buildAfterSnapshot(storedEnergy: unknown) {
  const updateMock = jest.fn().mockResolvedValue(undefined);
  const snapshot = {
    data: () => ({ storedEnergy }),
    ref: { update: updateMock },
  } as unknown as QueryDocumentSnapshot;
  return { snapshot, updateMock };
}

describe("enforceStoredEnergyCap", () => {
  test("test_enforceStoredEnergyCap_clamps_to_100_when_over_the_cap", async () => {
    const { snapshot, updateMock } = buildAfterSnapshot(150);

    await enforceStoredEnergyCap(snapshot);

    expect(updateMock).toHaveBeenCalledTimes(1);
    expect(updateMock).toHaveBeenCalledWith({ storedEnergy: 100 });
  });

  test("test_enforceStoredEnergyCap_is_a_no_op_exactly_at_the_cap", async () => {
    // Boundary — a future `>=` regression here would start needlessly
    // rewriting every child doc that merely touches the cap exactly.
    const { snapshot, updateMock } = buildAfterSnapshot(100);

    await enforceStoredEnergyCap(snapshot);

    expect(updateMock).not.toHaveBeenCalled();
  });

  test("test_enforceStoredEnergyCap_is_a_no_op_under_the_cap", async () => {
    // The realistic common case — this trigger fires on every child-doc
    // update (buy, equip, level-up), not just approvals (ADR-0003 Risks).
    const { snapshot, updateMock } = buildAfterSnapshot(80);

    await enforceStoredEnergyCap(snapshot);

    expect(updateMock).not.toHaveBeenCalled();
  });

  test("test_enforceStoredEnergyCap_is_a_no_op_when_snapshot_is_undefined", async () => {
    await expect(enforceStoredEnergyCap(undefined)).resolves.toBeUndefined();
  });

  test("test_enforceStoredEnergyCap_is_a_no_op_when_storedEnergy_is_not_a_number", async () => {
    // Defensive guard — a malformed/missing field must not crash the
    // function or attempt a nonsensical numeric comparison.
    const { snapshot, updateMock } = buildAfterSnapshot(undefined);

    await enforceStoredEnergyCap(snapshot);

    expect(updateMock).not.toHaveBeenCalled();
  });
});

// Owned by Seed Buffer Story 003 (`reconcileSeedCountDrift`, ADR-0012
// Decision §4). Updated in code review (security-engineer + qa-tester,
// independently, 2026-07-17): the function now issues TWO
// `transaction.get()` calls in sequence — (1) a transactional re-read of
// the child document itself (for `seedCount`), (2) the pending-tasks query
// — where it previously reused the trigger's pre-transaction snapshot for
// (1). `transactionGetMock` is a single mock shared by both calls, so every
// test below queues exactly two `mockResolvedValueOnce` values, IN THAT
// ORDER: the child-doc read first, the query read second.
//
// `buildDriftAfterSnapshot` is now minimal — just a `.ref` identity, since the
// implementation no longer calls `.data()` on it at all (that's what the
// original bug was: reading `seedCount` off this trigger-provided snapshot
// instead of re-reading transactionally).
function buildDriftAfterSnapshot() {
  return {
    ref: { path: "families/parent-1/children/child-1" },
  } as unknown as QueryDocumentSnapshot;
}

// The shape `transaction.get(afterSnapshot.ref)` resolves to — a
// DocumentSnapshot-like object exposing `seedCount` via a spied `data()`
// (so ordering assertions can prove this read happened before any write).
function buildChildDocSnapshot(seedCount: unknown) {
  const dataMock = jest.fn(() => ({ seedCount }));
  return { snapshot: { data: dataMock }, dataMock };
}

describe("reconcileSeedCountDrift", () => {
  beforeEach(() => {
    transactionGetMock.mockReset();
    transactionUpdateMock.mockClear();
    runTransactionMock.mockClear();
    collectionMock.mockClear();
    collectionWhereMock.mockClear();
  });

  test("test_reconcileSeedCountDrift_corrects_to_the_true_recomputed_count_not_a_naive_decrement", async () => {
    // GDD worked example (AC-8): seedCount stored as 5, actual pending
    // count = 3. A naive decrement bug would produce 5 - 1 = 4 — this must
    // be the fresh recompute (3), not that.
    const { snapshot: childSnapshot } = buildChildDocSnapshot(5);
    transactionGetMock.mockResolvedValueOnce(childSnapshot); // child-doc read
    transactionGetMock.mockResolvedValueOnce({ size: 3 }); // pending-count query
    const afterSnapshot = buildDriftAfterSnapshot();

    await reconcileSeedCountDrift(afterSnapshot, "parent-1", "child-1");

    expect(transactionUpdateMock).toHaveBeenCalledTimes(1);
    expect(transactionUpdateMock).toHaveBeenCalledWith(afterSnapshot.ref, { seedCount: 3 });
  });

  test("test_reconcileSeedCountDrift_reads_the_child_document_transactionally_not_from_the_trigger_snapshot", async () => {
    // Regression test for the code-review finding: the child document's
    // CURRENT seedCount must come from `transaction.get(afterSnapshot.ref)`
    // (tracked for contention-retry), not from `afterSnapshot.data()`
    // (a value captured before the transaction opened, with no Firestore
    // precondition). Proven here by making `afterSnapshot` itself have NO
    // `data()` method at all — if the implementation regressed to reading
    // from it, this test would throw a TypeError instead of passing.
    const bareAfterSnapshot = {
      ref: { path: "families/parent-1/children/child-1" },
    } as unknown as QueryDocumentSnapshot;
    const { snapshot: childSnapshot } = buildChildDocSnapshot(5);
    transactionGetMock.mockResolvedValueOnce(childSnapshot);
    transactionGetMock.mockResolvedValueOnce({ size: 3 });

    await reconcileSeedCountDrift(bareAfterSnapshot, "parent-1", "child-1");

    expect(transactionGetMock).toHaveBeenNthCalledWith(1, bareAfterSnapshot.ref);
    expect(transactionUpdateMock).toHaveBeenCalledWith(bareAfterSnapshot.ref, { seedCount: 3 });
  });

  test("test_reconcileSeedCountDrift_queries_the_correct_pending_tasks_collection_and_filter", async () => {
    const { snapshot: childSnapshot } = buildChildDocSnapshot(5);
    transactionGetMock.mockResolvedValueOnce(childSnapshot);
    transactionGetMock.mockResolvedValueOnce({ size: 3 });

    await reconcileSeedCountDrift(buildDriftAfterSnapshot(), "parent-1", "child-1");

    expect(collectionMock).toHaveBeenCalledWith("families/parent-1/children/child-1/tasks");
    expect(collectionWhereMock).toHaveBeenCalledWith("status", "==", "pending");
  });

  test("test_reconcileSeedCountDrift_is_a_no_op_when_seedCount_already_matches_the_actual_pending_count", async () => {
    // The common case — this trigger fires on nearly every child-doc
    // update (buy, equip, level-up), not just approvals, so a wrongly
    // unconditional write here would defeat the "scoped, narrow exception"
    // justification for the absolute-set write below.
    const { snapshot: childSnapshot } = buildChildDocSnapshot(3);
    transactionGetMock.mockResolvedValueOnce(childSnapshot);
    transactionGetMock.mockResolvedValueOnce({ size: 3 });

    await reconcileSeedCountDrift(buildDriftAfterSnapshot(), "parent-1", "child-1");

    expect(transactionUpdateMock).not.toHaveBeenCalled();
  });

  test("test_reconcileSeedCountDrift_is_a_no_op_when_afterSnapshot_is_undefined", async () => {
    await expect(
      reconcileSeedCountDrift(undefined, "parent-1", "child-1")
    ).resolves.toBeUndefined();

    expect(runTransactionMock).not.toHaveBeenCalled();
  });

  test("test_reconcileSeedCountDrift_is_a_no_op_when_seedCount_is_undefined_on_the_child_document", async () => {
    // Defensive edge case (qa-tester GAP, 2026-07-17): a child document
    // that has never had seedCount set at all. `undefined !==
    // actualPendingCount` (for any real pending count) fails the equality
    // guard and triggers a corrective write — safe by construction (no
    // Number.isFinite guard needed here, unlike enforceStoredEnergyCap,
    // because this is a strict equality check, not a numeric comparison).
    const { snapshot: childSnapshot } = buildChildDocSnapshot(undefined);
    transactionGetMock.mockResolvedValueOnce(childSnapshot);
    transactionGetMock.mockResolvedValueOnce({ size: 0 });
    const afterSnapshot = buildDriftAfterSnapshot();

    await reconcileSeedCountDrift(afterSnapshot, "parent-1", "child-1");

    expect(transactionUpdateMock).toHaveBeenCalledWith(afterSnapshot.ref, { seedCount: 0 });
  });

  test("test_reconcileSeedCountDrift_propagates_a_rejected_transaction", async () => {
    // Proves this function doesn't swallow a failed transaction (e.g.
    // Firestore's contention-retry exhausted) — matches the established
    // propagates-a-failure precedent already used for
    // cascadeDeleteChildSubcollections above.
    runTransactionMock.mockImplementationOnce(() =>
      Promise.reject(new Error("simulated transaction contention failure"))
    );

    await expect(
      reconcileSeedCountDrift(buildDriftAfterSnapshot(), "parent-1", "child-1")
    ).rejects.toThrow("simulated transaction contention failure");
  });

  test("test_reconcileSeedCountDrift_reads_both_values_transactionally_before_any_write", async () => {
    // Proves the ordering requirement: the child-document read, the
    // pending-count query, AND the seedCount value extraction all happen
    // before `transaction.update()` — this is what ADR-0012 Decision §4's
    // safety argument depends on (reading BOTH values inside the
    // transaction is what forces Firestore's contention-retry against a
    // concurrent client increment on either one). `invocationCallOrder`
    // proves actual call sequence, not just that all were eventually
    // called.
    const { snapshot: childSnapshot, dataMock } = buildChildDocSnapshot(5);
    transactionGetMock.mockResolvedValueOnce(childSnapshot);
    transactionGetMock.mockResolvedValueOnce({ size: 3 });

    await reconcileSeedCountDrift(buildDriftAfterSnapshot(), "parent-1", "child-1");

    const firstGetOrder = transactionGetMock.mock.invocationCallOrder[0];
    const dataOrder = dataMock.mock.invocationCallOrder[0];
    const secondGetOrder = transactionGetMock.mock.invocationCallOrder[1];
    const updateOrder = transactionUpdateMock.mock.invocationCallOrder[0];
    expect(firstGetOrder).toBeLessThan(updateOrder);
    expect(dataOrder).toBeLessThan(updateOrder);
    expect(secondGetOrder).toBeLessThan(updateOrder);
  });

  test("test_reconcileSeedCountDrift_is_idempotent_on_repeated_invocation_with_the_SAME_stale_trigger_snapshot", async () => {
    // Simulates Cloud Functions' actual at-least-once/retry semantics: the
    // SAME event redelivers, so `afterSnapshot` is the SAME object both
    // times (unlike a prior version of this test, which used two different
    // hand-built snapshots — that couldn't distinguish true retry-safety
    // from just running two independent scenarios back to back; qa-tester
    // GAP, 2026-07-17). Because seedCount is now read transactionally
    // (not from the stale `afterSnapshot`), each invocation sees the
    // CURRENT document state regardless of what the original trigger event
    // captured — first invocation observes drift (5 vs 3) and corrects;
    // second invocation, same event object, now observes the corrected
    // state (3 vs 3) and stays a no-op. No double-application artifact.
    const afterSnapshot = buildDriftAfterSnapshot();

    const { snapshot: firstChildSnapshot } = buildChildDocSnapshot(5);
    transactionGetMock.mockResolvedValueOnce(firstChildSnapshot);
    transactionGetMock.mockResolvedValueOnce({ size: 3 });
    await reconcileSeedCountDrift(afterSnapshot, "parent-1", "child-1");
    expect(transactionUpdateMock).toHaveBeenCalledTimes(1);
    expect(transactionUpdateMock).toHaveBeenCalledWith(afterSnapshot.ref, { seedCount: 3 });

    const { snapshot: secondChildSnapshot } = buildChildDocSnapshot(3);
    transactionGetMock.mockResolvedValueOnce(secondChildSnapshot);
    transactionGetMock.mockResolvedValueOnce({ size: 3 });
    await reconcileSeedCountDrift(afterSnapshot, "parent-1", "child-1"); // SAME afterSnapshot object

    expect(transactionUpdateMock).toHaveBeenCalledTimes(1); // still just the first call
  });
});

describe("onTaskApproved.run (handler invocation, no emulator needed)", () => {
  // Same `.run(event)` seam as `onChildProfileDelete.run` above — closes
  // the gap between "the trigger is configured correctly" (the __endpoint
  // tests below) and "the handler does the right thing when it actually
  // fires" (event.data?.after correctly reaches enforceStoredEnergyCap and
  // reconcileSeedCountDrift, and event.params reaches the latter).
  beforeEach(() => {
    transactionGetMock.mockReset();
    transactionUpdateMock.mockClear();
    collectionMock.mockClear();
  });

  function buildUpdatedEvent(after: QueryDocumentSnapshot | undefined) {
    return {
      data: after ? ({ after } as unknown) : undefined,
      params: { parentId: "parent-1", childId: "child-1" },
    } as Parameters<typeof onTaskApproved.run>[0];
  }

  test("test_onTaskApproved_run_clamps_storedEnergy_when_over_the_cap", async () => {
    transactionGetMock.mockResolvedValueOnce({ data: () => ({ seedCount: 0 }) });
    transactionGetMock.mockResolvedValueOnce({ size: 0 });
    const { snapshot, updateMock } = buildAfterSnapshot(150);

    await onTaskApproved.run(buildUpdatedEvent(snapshot));

    expect(updateMock).toHaveBeenCalledWith({ storedEnergy: 100 });
  });

  test("test_onTaskApproved_run_is_a_no_op_when_event_data_is_undefined", async () => {
    await expect(
      onTaskApproved.run(buildUpdatedEvent(undefined))
    ).resolves.toBeUndefined();
  });

  // Test Evidence item (5): does not interfere with the existing
  // storedEnergy-cap logic already in `onTaskApproved`. Both concerns run
  // in the SAME invocation, via two entirely independent write mechanisms
  // (`afterSnapshot.ref.update` vs `transaction.update`) — this proves
  // neither one's write short-circuits or clobbers the other's. Note
  // `reconcileSeedCountDrift` now reads `seedCount` via its own
  // transactional `transaction.get(afterSnapshot.ref)` (queued as the
  // FIRST `transactionGetMock` value below), not from `afterSnapshot`
  // itself — `buildAfterSnapshot`'s `data()` only needs to supply
  // `storedEnergy` for `enforceStoredEnergyCap`'s sake.
  //
  // `reconcileTaskReward`/`onTaskRewardReconciliation` are NOT exercised
  // here: per this story's corrected Implementation Notes, that reward
  // reconciliation actually lives on its own separate trigger
  // (`onTaskRewardReconciliation`, watching `tasks/{taskId}`, not the child
  // document `onTaskApproved` watches) — this story's change to
  // `onTaskApproved` cannot interfere with a different trigger's code path.
  // Non-interference with that suite is instead demonstrated by its own
  // `describe("onTaskRewardReconciliation...")` block below continuing to
  // pass unmodified, since no line in this story touches that trigger.
  test("test_onTaskApproved_run_runs_enforceStoredEnergyCap_and_reconcileSeedCountDrift_independently_without_interference", async () => {
    transactionGetMock.mockResolvedValueOnce({ data: () => ({ seedCount: 5 }) });
    transactionGetMock.mockResolvedValueOnce({ size: 3 });
    const { snapshot, updateMock } = buildAfterSnapshot(150);

    await onTaskApproved.run(buildUpdatedEvent(snapshot));

    expect(updateMock).toHaveBeenCalledWith({ storedEnergy: 100 });
    expect(transactionUpdateMock).toHaveBeenCalledWith(snapshot.ref, { seedCount: 3 });
  });

  test("test_onTaskApproved_run_leaves_storedEnergy_untouched_when_only_seedCount_has_drifted", async () => {
    // The inverse combination — proves reconcileSeedCountDrift's own write
    // doesn't spuriously trigger enforceStoredEnergyCap's write (and vice
    // versa, covered by the prior test): each guard is evaluated purely
    // from its own field, not from whether the other concern also wrote.
    transactionGetMock.mockResolvedValueOnce({ data: () => ({ seedCount: 5 }) });
    transactionGetMock.mockResolvedValueOnce({ size: 3 });
    const { snapshot, updateMock } = buildAfterSnapshot(80);

    await onTaskApproved.run(buildUpdatedEvent(snapshot));

    expect(updateMock).not.toHaveBeenCalled();
    expect(transactionUpdateMock).toHaveBeenCalledWith(snapshot.ref, { seedCount: 3 });
  });

  test("test_onTaskApproved_run_passes_event_params_parentId_and_childId_through_to_the_pending_tasks_query", async () => {
    transactionGetMock.mockResolvedValueOnce({ data: () => ({ seedCount: 0 }) });
    transactionGetMock.mockResolvedValueOnce({ size: 0 });
    const { snapshot } = buildAfterSnapshot(50);

    await onTaskApproved.run(buildUpdatedEvent(snapshot));

    expect(collectionMock).toHaveBeenCalledWith("families/parent-1/children/child-1/tasks");
  });
});

describe("onTaskApproved trigger wiring", () => {
  const endpoint = (onTaskApproved as unknown as { __endpoint: any }).__endpoint;

  test("test_onTaskApproved_is_a_2nd_gen_function", () => {
    expect(endpoint.platform).toBe("gcfv2");
  });

  test("test_onTaskApproved_listens_for_onDocumentUpdated", () => {
    expect(endpoint.eventTrigger.eventType).toBe(
      "google.cloud.firestore.document.v1.updated"
    );
  });

  test("test_onTaskApproved_watches_the_correct_document_path", () => {
    expect(endpoint.eventTrigger.eventFilterPathPatterns.document).toBe(
      "families/{parentId}/children/{childId}"
    );
  });
});

// Shared by `reconcileTaskReward` and `onTaskRewardReconciliation.run` below
// — a QueryDocumentSnapshot-shaped fake exposing only the members either
// code path touches (`data()`, `ref.path`).
function buildTaskSnapshot(data: {
  status?: string;
  categoryId?: unknown;
  xuReward?: unknown;
  energyReward?: unknown;
}) {
  return {
    data: () => data,
    ref: { path: "families/parent-1/children/child-1/tasks/task-1" },
  } as unknown as QueryDocumentSnapshot;
}

describe("reconcileTaskReward", () => {
  let consoleErrorSpy: jest.SpyInstance;

  beforeEach(() => {
    consoleErrorSpy = jest.spyOn(console, "error").mockImplementation(() => undefined);
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  test("test_reconcileTaskReward_is_a_no_op_when_reward_matches_the_table", async () => {
    const snapshot = buildTaskSnapshot({
      status: "approved",
      categoryId: "chores",
      xuReward: 15,
      energyReward: 25,
    });

    await reconcileTaskReward(snapshot);

    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  test("test_reconcileTaskReward_flags_a_mismatched_xuReward_without_throwing", async () => {
    const snapshot = buildTaskSnapshot({
      status: "approved",
      categoryId: "chores",
      xuReward: 999,
      energyReward: 25,
    });

    await expect(reconcileTaskReward(snapshot)).resolves.toBeUndefined();

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      "onTaskRewardReconciliation: reward mismatch detected",
      {
        taskPath: "families/parent-1/children/child-1/tasks/task-1",
        categoryId: "chores",
        xuReward: 999,
        energyReward: 25,
        expected: { xu: 15, energy: 25 },
      }
    );
  });

  test("test_reconcileTaskReward_flags_a_mismatched_energyReward_without_throwing", async () => {
    // The reverse of the xuReward-mismatch case above — both operands of
    // the `&&` chain need their own coverage, not just one.
    const snapshot = buildTaskSnapshot({
      status: "approved",
      categoryId: "chores",
      xuReward: 15,
      energyReward: 999,
    });

    await reconcileTaskReward(snapshot);

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      "onTaskRewardReconciliation: reward mismatch detected",
      {
        taskPath: "families/parent-1/children/child-1/tasks/task-1",
        categoryId: "chores",
        xuReward: 15,
        energyReward: 999,
        expected: { xu: 15, energy: 25 },
      }
    );
  });

  test("test_reconcileTaskReward_flags_an_unknown_categoryId_as_a_mismatch", async () => {
    const snapshot = buildTaskSnapshot({
      status: "approved",
      categoryId: "not_a_real_category",
      xuReward: 15,
      energyReward: 25,
    });

    await reconcileTaskReward(snapshot);

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    expect(consoleErrorSpy).toHaveBeenCalledWith(
      "onTaskRewardReconciliation: reward mismatch detected",
      {
        taskPath: "families/parent-1/children/child-1/tasks/task-1",
        categoryId: "not_a_real_category",
        xuReward: 15,
        energyReward: 25,
        expected: null,
      }
    );
  });

  test.each([
    ["undefined categoryId", undefined, 15, 25],
    ["null categoryId", null, 15, 25],
    ["NaN xuReward", "chores", NaN, 25],
    ["string xuReward (type drift, not coerced)", "chores", "15", 25],
    // Reserved Object.prototype member names — a plain `{}[categoryId]`
    // bracket lookup would resolve these to a truthy built-in (e.g.
    // `Object`, `Object.prototype.toString`) instead of `undefined`,
    // silently passing as "matched" when xuReward/energyReward are also
    // undefined. This is exactly the "unknown categoryId must always be
    // flagged" AC, applied to inputs a naive lookup would get wrong
    // (found in code review, security-engineer, 2026-07-16).
    ["'constructor' categoryId (prototype-chain bypass)", "constructor", undefined, undefined],
    ["'__proto__' categoryId (prototype-chain bypass)", "__proto__", undefined, undefined],
    ["'toString' categoryId (prototype-chain bypass)", "toString", undefined, undefined],
  ])(
    "test_reconcileTaskReward_fails_closed_and_flags_a_mismatch_for_%s",
    async (_label, categoryId, xuReward, energyReward) => {
      const snapshot = buildTaskSnapshot({
        status: "approved",
        categoryId,
        xuReward,
        energyReward,
      });

      await reconcileTaskReward(snapshot);

      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    }
  );

  test("test_reconcileTaskReward_is_a_no_op_when_snapshot_is_undefined", async () => {
    await expect(reconcileTaskReward(undefined)).resolves.toBeUndefined();

    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });
});

describe("onTaskRewardReconciliation.run (handler invocation, no emulator needed)", () => {
  let consoleErrorSpy: jest.SpyInstance;

  beforeEach(() => {
    consoleErrorSpy = jest.spyOn(console, "error").mockImplementation(() => undefined);
  });

  afterEach(() => {
    consoleErrorSpy.mockRestore();
  });

  function buildTaskUpdateEvent(
    before: QueryDocumentSnapshot | undefined,
    after: QueryDocumentSnapshot | undefined,
    options: { eventDataUndefined?: boolean } = {}
  ) {
    return {
      // `eventDataUndefined` simulates the platform never populating
      // `event.data` at all (a distinct case from `event.data` being
      // present with only `before` or `after` individually missing —
      // the two asymmetric tests below need `data` to stay a truthy
      // object so the handler's `!before || !after` guard is what's
      // actually exercised, not the outer `if (!before || !after)`
      // collapsing both possibilities into the same code path).
      data: options.eventDataUndefined ? undefined : ({ before, after } as unknown),
      params: { parentId: "parent-1", childId: "child-1", taskId: "task-1" },
    } as Parameters<typeof onTaskRewardReconciliation.run>[0];
  }

  test("test_onTaskRewardReconciliation_run_reconciles_on_a_pending_to_approved_transition", async () => {
    const before = buildTaskSnapshot({ status: "pending", categoryId: "chores", xuReward: 999, energyReward: 25 });
    const after = buildTaskSnapshot({ status: "approved", categoryId: "chores", xuReward: 999, energyReward: 25 });

    await onTaskRewardReconciliation.run(buildTaskUpdateEvent(before, after));

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
  });

  test("test_onTaskRewardReconciliation_run_does_not_reconcile_when_already_approved_before_the_update", async () => {
    // Status was already 'approved' before this update fired (e.g. some
    // unrelated field on the task changed) — must not re-check on every
    // touch of an already-approved task, only on the transition itself.
    const before = buildTaskSnapshot({ status: "approved", categoryId: "chores", xuReward: 999, energyReward: 25 });
    const after = buildTaskSnapshot({ status: "approved", categoryId: "chores", xuReward: 999, energyReward: 25 });

    await onTaskRewardReconciliation.run(buildTaskUpdateEvent(before, after));

    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  test("test_onTaskRewardReconciliation_run_does_not_reconcile_when_not_transitioning_to_approved", async () => {
    const before = buildTaskSnapshot({ status: "pending", categoryId: "chores", xuReward: 999, energyReward: 25 });
    const after = buildTaskSnapshot({ status: "rejected", categoryId: "chores", xuReward: 999, energyReward: 25 });

    await onTaskRewardReconciliation.run(buildTaskUpdateEvent(before, after));

    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  test("test_onTaskRewardReconciliation_run_reconciles_on_a_rejected_to_approved_transition", async () => {
    // The guard only checks `before.status !== 'approved'` — it must not
    // special-case 'pending' as the only valid prior state, since a
    // rejected task could in principle be re-approved later.
    const before = buildTaskSnapshot({ status: "rejected", categoryId: "chores", xuReward: 999, energyReward: 25 });
    const after = buildTaskSnapshot({ status: "approved", categoryId: "chores", xuReward: 999, energyReward: 25 });

    await onTaskRewardReconciliation.run(buildTaskUpdateEvent(before, after));

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
  });

  test("test_onTaskRewardReconciliation_run_is_a_no_op_when_only_before_is_undefined", async () => {
    const after = buildTaskSnapshot({ status: "approved", categoryId: "chores", xuReward: 999, energyReward: 25 });

    await expect(
      onTaskRewardReconciliation.run(buildTaskUpdateEvent(undefined, after))
    ).resolves.toBeUndefined();

    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  test("test_onTaskRewardReconciliation_run_is_a_no_op_when_only_after_is_undefined", async () => {
    const before = buildTaskSnapshot({ status: "pending", categoryId: "chores", xuReward: 999, energyReward: 25 });

    await expect(
      onTaskRewardReconciliation.run(buildTaskUpdateEvent(before, undefined))
    ).resolves.toBeUndefined();

    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });

  test("test_onTaskRewardReconciliation_run_is_a_no_op_when_event_data_is_undefined", async () => {
    await expect(
      onTaskRewardReconciliation.run(buildTaskUpdateEvent(undefined, undefined))
    ).resolves.toBeUndefined();

    expect(consoleErrorSpy).not.toHaveBeenCalled();
  });
});

describe("onTaskRewardReconciliation trigger wiring", () => {
  const endpoint = (onTaskRewardReconciliation as unknown as { __endpoint: any }).__endpoint;

  test("test_onTaskRewardReconciliation_is_a_2nd_gen_function", () => {
    expect(endpoint.platform).toBe("gcfv2");
  });

  test("test_onTaskRewardReconciliation_listens_for_onDocumentUpdated", () => {
    expect(endpoint.eventTrigger.eventType).toBe(
      "google.cloud.firestore.document.v1.updated"
    );
  });

  test("test_onTaskRewardReconciliation_watches_the_correct_document_path", () => {
    expect(endpoint.eventTrigger.eventFilterPathPatterns.document).toBe(
      "families/{parentId}/children/{childId}/tasks/{taskId}"
    );
  });
});

describe("sendTaskSubmittedNotification", () => {
  let consoleWarnSpy: jest.SpyInstance;
  let consoleErrorSpy: jest.SpyInstance;

  beforeEach(() => {
    messagingSendMock.mockClear();
    messagingSendMock.mockResolvedValue("message-id");
    consoleWarnSpy = jest.spyOn(console, "warn").mockImplementation(() => undefined);
    consoleErrorSpy = jest.spyOn(console, "error").mockImplementation(() => undefined);
  });

  afterEach(() => {
    consoleWarnSpy.mockRestore();
    consoleErrorSpy.mockRestore();
  });

  test("test_sendTaskSubmittedNotification_sends_the_fixed_payload_contract_shape", async () => {
    await sendTaskSubmittedNotification({
      taskId: "task-1",
      childId: "child-1",
      taskTitle: "Quét nhà",
      childName: "Bông",
      fcmToken: "fcm-token-abc",
    });

    expect(messagingSendMock).toHaveBeenCalledTimes(1);
    expect(messagingSendMock).toHaveBeenCalledWith({
      token: "fcm-token-abc",
      notification: {
        title: "Bông vừa hoàn thành nhiệm vụ! 🎉",
        body: "Quét nhà — Hãy kiểm tra và approve nhé!",
      },
      data: {
        type: "task_submitted",
        taskId: "task-1",
        childId: "child-1",
        deepLink: "petquest://parent/tasks/pending",
      },
      android: { priority: "high" },
      apns: { headers: { "apns-priority": "10" } },
    });
  });

  test("test_sendTaskSubmittedNotification_truncates_a_120_char_taskTitle_to_80_chars_plus_ellipsis", async () => {
    const longTitle = "a".repeat(120);

    await sendTaskSubmittedNotification({
      taskId: "task-1",
      childId: "child-1",
      taskTitle: longTitle,
      childName: "Bông",
      fcmToken: "fcm-token-abc",
    });

    const sentMessage = messagingSendMock.mock.calls[0][0];
    expect(sentMessage.notification.body).toBe(`${"a".repeat(80)}… — Hãy kiểm tra và approve nhé!`);
  });

  test("test_sendTaskSubmittedNotification_does_not_truncate_a_taskTitle_at_exactly_80_chars", async () => {
    // Boundary — a future `>` regression to `>=` here would needlessly
    // truncate a title that fits exactly.
    const exactTitle = "a".repeat(80);

    await sendTaskSubmittedNotification({
      taskId: "task-1",
      childId: "child-1",
      taskTitle: exactTitle,
      childName: "Bông",
      fcmToken: "fcm-token-abc",
    });

    const sentMessage = messagingSendMock.mock.calls[0][0];
    expect(sentMessage.notification.body).toBe(`${exactTitle} — Hãy kiểm tra và approve nhé!`);
  });

  test("test_sendTaskSubmittedNotification_truncates_a_long_childName_driven_title_to_50_chars_plus_ellipsis", async () => {
    const longChildName = "a".repeat(60);

    await sendTaskSubmittedNotification({
      taskId: "task-1",
      childId: "child-1",
      taskTitle: "Quét nhà",
      childName: longChildName,
      fcmToken: "fcm-token-abc",
    });

    const sentMessage = messagingSendMock.mock.calls[0][0];
    expect(sentMessage.notification.title.length).toBe(51); // 50 chars + "…"
    expect(sentMessage.notification.title.endsWith("…")).toBe(true);
  });

  test("test_sendTaskSubmittedNotification_truncates_by_code_point_not_UTF16_unit_no_broken_surrogate_pairs", async () => {
    // 79 'a's + an emoji (a 2-UTF16-code-unit surrogate pair) + 1 more 'a'
    // = 81 code points (82 UTF16 units). Truncating to 80 CODE POINTS
    // should keep the 79 a's + the whole emoji, dropping only the final
    // trailing 'a'. A naive `.slice(0, 80)` on UTF-16 CODE UNITS would
    // instead cut after unit 80 — landing in the middle of the emoji's
    // surrogate pair and producing a malformed/unpaired high surrogate in
    // the sent payload (found in code review, flame-specialist,
    // 2026-07-16).
    const title = `${"a".repeat(79)}🎂a`;

    await sendTaskSubmittedNotification({
      taskId: "task-1",
      childId: "child-1",
      taskTitle: title,
      childName: "Bông",
      fcmToken: "fcm-token-abc",
    });

    const sentMessage = messagingSendMock.mock.calls[0][0];
    const body: string = sentMessage.notification.body;
    expect(body).toBe(`${"a".repeat(79)}🎂… — Hãy kiểm tra và approve nhé!`);
    // The emoji must survive as a complete, matchable surrogate pair — if
    // truncation had split it, this substring check would fail.
    expect(body.includes("🎂")).toBe(true);
  });

  test.each([
    ["null fcmToken (AC-2)", null],
    ["undefined fcmToken (AC-2/AC-7 — permission never granted)", undefined],
    ["empty-string fcmToken", ""],
  ])("test_sendTaskSubmittedNotification_is_a_no_op_and_warns_for_%s", async (_label, fcmToken) => {
    await sendTaskSubmittedNotification({
      taskId: "task-1",
      childId: "child-1",
      taskTitle: "Quét nhà",
      childName: "Bông",
      fcmToken,
    });

    expect(messagingSendMock).not.toHaveBeenCalled();
    expect(consoleWarnSpy).toHaveBeenCalledTimes(1);
  });

  test("test_sendTaskSubmittedNotification_logs_and_does_not_throw_on_an_invalid_token_FCM_error", async () => {
    messagingSendMock.mockRejectedValueOnce(
      Object.assign(new Error("Requested entity was not found."), {
        code: "messaging/registration-token-not-registered",
      })
    );

    await expect(
      sendTaskSubmittedNotification({
        taskId: "task-1",
        childId: "child-1",
        taskTitle: "Quét nhà",
        childName: "Bông",
        fcmToken: "stale-token",
      })
    ).resolves.toBeUndefined();

    expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
  });
});

describe("onTaskSubmitted.run (handler invocation, no emulator needed)", () => {
  beforeEach(() => {
    messagingSendMock.mockClear();
    messagingSendMock.mockResolvedValue("message-id");
    docMock.mockClear();
    docGetMock.mockReset();
  });

  function buildTaskCreatedEvent(
    taskData: Record<string, unknown> | undefined,
    params: { parentId: string; childId: string; taskId: string }
  ) {
    return {
      data: taskData
        ? ({ data: () => taskData } as unknown)
        : undefined,
      params,
    } as Parameters<typeof onTaskSubmitted.run>[0];
  }

  function stubDocs(byPath: Record<string, Record<string, unknown> | undefined>) {
    docGetMock.mockImplementation((path: string) =>
      Promise.resolve({ data: () => byPath[path] })
    );
  }

  test("test_onTaskSubmitted_run_reads_child_name_and_fcmToken_then_sends", async () => {
    stubDocs({
      "families/parent-1/children/child-1": { name: "Bông" },
      "families/parent-1": { fcmToken: "fcm-token-abc" },
    });

    await onTaskSubmitted.run(
      buildTaskCreatedEvent(
        { title: "Quét nhà" },
        { parentId: "parent-1", childId: "child-1", taskId: "task-1" }
      )
    );

    expect(messagingSendMock).toHaveBeenCalledTimes(1);
    // Full payload shape asserted at the integration level too, not just
    // in sendTaskSubmittedNotification's own unit tests — a future
    // refactor that inlined trigger-specific overrides of the fixed
    // fields (type/deepLink/priority headers) instead of delegating would
    // otherwise slip past this test (found in code review, qa-tester,
    // 2026-07-16).
    expect(messagingSendMock).toHaveBeenCalledWith({
      token: "fcm-token-abc",
      notification: {
        title: "Bông vừa hoàn thành nhiệm vụ! 🎉",
        body: "Quét nhà — Hãy kiểm tra và approve nhé!",
      },
      data: {
        type: "task_submitted",
        taskId: "task-1",
        childId: "child-1",
        deepLink: "petquest://parent/tasks/pending",
      },
      android: { priority: "high" },
      apns: { headers: { "apns-priority": "10" } },
    });
  });

  test("test_onTaskSubmitted_run_defaults_to_an_empty_childName_when_the_child_document_is_missing", async () => {
    stubDocs({
      "families/parent-1/children/child-1": undefined, // doc doesn't exist
      "families/parent-1": { fcmToken: "fcm-token-abc" },
    });

    await onTaskSubmitted.run(
      buildTaskCreatedEvent(
        { title: "Quét nhà" },
        { parentId: "parent-1", childId: "child-1", taskId: "task-1" }
      )
    );

    expect(messagingSendMock).toHaveBeenCalledTimes(1);
    const sentMessage = messagingSendMock.mock.calls[0][0];
    expect(sentMessage.notification.title).toBe(" vừa hoàn thành nhiệm vụ! 🎉");
  });

  test("test_onTaskSubmitted_run_is_a_no_op_when_the_family_document_is_missing_no_fcmToken", async () => {
    stubDocs({
      "families/parent-1/children/child-1": { name: "Bông" },
      "families/parent-1": undefined, // doc doesn't exist, no fcmToken
    });

    await onTaskSubmitted.run(
      buildTaskCreatedEvent(
        { title: "Quét nhà" },
        { parentId: "parent-1", childId: "child-1", taskId: "task-1" }
      )
    );

    expect(messagingSendMock).not.toHaveBeenCalled();
  });

  test("test_onTaskSubmitted_run_does_not_throw_when_the_task_document_has_no_title_field", async () => {
    // firestore.rules' rewardOk() create-rule validates status/categoryId/
    // xuReward/energyReward but does NOT require `title` to exist — an
    // unguarded read would throw inside truncateWithEllipsis() before the
    // try/catch is even reached (found in code review, flame-specialist,
    // 2026-07-16).
    stubDocs({
      "families/parent-1/children/child-1": { name: "Bông" },
      "families/parent-1": { fcmToken: "fcm-token-abc" },
    });

    await expect(
      onTaskSubmitted.run(
        buildTaskCreatedEvent(
          {}, // no `title` field at all
          { parentId: "parent-1", childId: "child-1", taskId: "task-1" }
        )
      )
    ).resolves.toBeUndefined();

    expect(messagingSendMock).toHaveBeenCalledTimes(1);
    const sentMessage = messagingSendMock.mock.calls[0][0];
    expect(sentMessage.notification.body).toBe(" — Hãy kiểm tra và approve nhé!");
  });

  test("test_onTaskSubmitted_run_is_a_no_op_when_event_data_is_undefined", async () => {
    await expect(
      onTaskSubmitted.run(
        buildTaskCreatedEvent(undefined, {
          parentId: "parent-1",
          childId: "child-1",
          taskId: "task-1",
        })
      )
    ).resolves.toBeUndefined();

    expect(messagingSendMock).not.toHaveBeenCalled();
  });

  test("test_onTaskSubmitted_run_does_not_leak_data_across_two_concurrent_invocations_for_different_children (AC-6)", async () => {
    stubDocs({
      "families/parent-1/children/child-A": { name: "Bông" },
      "families/parent-1": { fcmToken: "fcm-token-parent1" },
      "families/parent-2/children/child-B": { name: "Sóc" },
      "families/parent-2": { fcmToken: "fcm-token-parent2" },
    });

    await Promise.all([
      onTaskSubmitted.run(
        buildTaskCreatedEvent(
          { title: "Quét nhà" },
          { parentId: "parent-1", childId: "child-A", taskId: "task-A" }
        )
      ),
      onTaskSubmitted.run(
        buildTaskCreatedEvent(
          { title: "Đọc sách" },
          { parentId: "parent-2", childId: "child-B", taskId: "task-B" }
        )
      ),
    ]);

    expect(messagingSendMock).toHaveBeenCalledTimes(2);
    const sentMessages = messagingSendMock.mock.calls.map((call) => call[0]);

    const messageForA = sentMessages.find((m) => m.data.taskId === "task-A");
    expect(messageForA.token).toBe("fcm-token-parent1");
    expect(messageForA.notification.title).toBe("Bông vừa hoàn thành nhiệm vụ! 🎉");
    expect(messageForA.notification.body).toBe("Quét nhà — Hãy kiểm tra và approve nhé!");
    expect(messageForA.data.childId).toBe("child-A");

    const messageForB = sentMessages.find((m) => m.data.taskId === "task-B");
    expect(messageForB.token).toBe("fcm-token-parent2");
    expect(messageForB.notification.title).toBe("Sóc vừa hoàn thành nhiệm vụ! 🎉");
    expect(messageForB.notification.body).toBe("Đọc sách — Hãy kiểm tra và approve nhé!");
    expect(messageForB.data.childId).toBe("child-B");
  });
});

describe("onTaskSubmitted trigger wiring", () => {
  const endpoint = (onTaskSubmitted as unknown as { __endpoint: any }).__endpoint;

  test("test_onTaskSubmitted_is_a_2nd_gen_function", () => {
    expect(endpoint.platform).toBe("gcfv2");
  });

  test("test_onTaskSubmitted_listens_for_onDocumentCreated", () => {
    expect(endpoint.eventTrigger.eventType).toBe(
      "google.cloud.firestore.document.v1.created"
    );
  });

  test("test_onTaskSubmitted_watches_the_correct_document_path", () => {
    expect(endpoint.eventTrigger.eventFilterPathPatterns.document).toBe(
      "families/{parentId}/children/{childId}/tasks/{taskId}"
    );
  });

  test("test_onTaskSubmitted_does_not_enable_retry", () => {
    expect(endpoint.eventTrigger.retry).not.toBe(true);
  });

  test("test_onTaskSubmitted_uses_the_256MiB_memory_string_enum", () => {
    expect(endpoint.availableMemoryMb).toBe(256);
  });
});
