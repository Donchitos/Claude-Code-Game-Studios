import { initializeApp } from "firebase-admin/app";
import type { DocumentReference, QueryDocumentSnapshot } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";

const STORED_ENERGY_CAP = 100;

initializeApp();

/**
 * Recursively deletes everything under `families/{parentId}/children/{childId}`
 * (currently just `private/credentials`, but any future subcollection too).
 * Firestore does not cascade-delete subcollections on its own, and
 * client-side recursive delete is not reliable on mobile — the app can be
 * killed mid-delete — which is the whole reason this runs server-side
 * (ADR-0002 Decision §8, TR-auth-account-007).
 *
 * `recursiveDelete` re-targeting the already-deleted `children/{childId}`
 * ref is intentional, not a bug: deleting an already-absent document is a
 * no-op, and the same call still walks and deletes every subcollection
 * beneath that path — exactly what's needed here.
 *
 * Extracted from the trigger handler below as a plain, directly
 * unit-testable function — no emulator or reconstructed `CloudEvent` needed
 * to test the actual cascade-delete logic (only the thin wiring in
 * `onChildProfileDelete` needs that, and its trigger configuration is
 * verified separately via `.__endpoint`, not by invoking the handler).
 */
export async function cascadeDeleteChildSubcollections(
  deletedRef: DocumentReference | undefined
): Promise<void> {
  if (!deletedRef) {
    return;
  }
  await getFirestore().recursiveDelete(deletedRef);
}

/**
 * The client's job (a different story/epic, out of this story's scope) is
 * only to delete the `children/{childId}` document itself; this function
 * reacts to that deletion. Uses the Admin SDK, which bypasses Security
 * Rules — the correct trust boundary for a server-side trigger.
 */
export const onChildProfileDelete = onDocumentDeleted(
  "families/{parentId}/children/{childId}",
  async (event) => {
    await cascadeDeleteChildSubcollections(event.data?.ref);
  }
);

/**
 * Post-commit clamp for `storedEnergy` at {@link STORED_ENERGY_CAP} (ADR-0003
 * Decision §6, TR-data-persistence-005). `FieldValue.increment()` on the
 * client is atomic but not self-limiting — Firestore has no server-side cap
 * primitive, so this reconciles after the fact. A plain field `update()`,
 * never `FieldValue.increment()`, because this is a clamp (set to exactly
 * the cap), not a delta.
 *
 * No-ops (issues no write) when the value is already at or under the cap —
 * this trigger fires on EVERY update to the child document (buy, equip,
 * level-up all touch it, not just task approval — ADR-0003 Risks), so the
 * no-op path is what keeps it from writing needlessly on the common case.
 *
 * Extracted from the trigger handler below as a plain, directly
 * unit-testable function — same split as {@link cascadeDeleteChildSubcollections}.
 * Reward-against-`categoryId` reconciliation (ADR-0009 §3) is handled by
 * the separate {@link onTaskRewardReconciliation} trigger below, not here —
 * see that trigger's doc comment for why it is a second trigger rather than
 * a literal extension of this one.
 */
export async function enforceStoredEnergyCap(
  afterSnapshot: QueryDocumentSnapshot | undefined
): Promise<void> {
  if (!afterSnapshot) {
    return;
  }
  const storedEnergy = afterSnapshot.data().storedEnergy;
  // Number.isFinite (not typeof === "number") also rejects NaN — a bare
  // typeof check lets NaN through, since `typeof NaN === "number"` but
  // `NaN <= 100` is false, which would silently clamp a NaN field to 100
  // instead of being treated as malformed data (found in code review).
  if (!Number.isFinite(storedEnergy) || storedEnergy <= STORED_ENERGY_CAP) {
    return;
  }
  await afterSnapshot.ref.update({ storedEnergy: STORED_ENERGY_CAP });
}

/**
 * Drift detection & correction for the denormalized `seedCount` counter
 * (ADR-0012 Decision §4, `design/gdd/seed-buffer.md` AC-8, TR-seedbuffer-003).
 * `seedCount` is normally maintained by client-side `FieldValue.increment()`
 * on task submit/approve/reject (ADR-0012 Decision §1/§2) — this function is
 * the self-healing backstop for when those increments have drifted from the
 * actual pending-task count (e.g. a partially-failed batch), NOT the
 * primary write mechanism, and NOT implemented here (Out of Scope, Story
 * 003).
 *
 * Runs its OWN `runTransaction` — a real transaction, not a plain
 * `update()` like {@link enforceStoredEnergyCap} — because the safety
 * argument (ADR-0012 Decision §4) genuinely depends on it: reading BOTH the
 * pending-task count AND the current `seedCount` inside the same
 * transaction (via `transaction.get()`, not the trigger's pre-transaction
 * `afterSnapshot`) is what forces Firestore's optimistic-concurrency
 * contention-retry against a concurrent client `increment()` on either —
 * only documents/queries actually read via `transaction.get()` are
 * tracked for conflict detection; a `transaction.update()` on a document
 * never read inside that same transaction carries no precondition and is
 * an unconditional write. **Found in code review (security-engineer +
 * qa-tester, independently, 2026-07-17)**: the original version of this
 * function read `seedCount` from `afterSnapshot` (captured before the
 * transaction opened) instead of re-reading it transactionally — it
 * happened to still be safe today only because every current legitimate
 * `seedCount` writer also touches a `tasks/{taskId}` document the pending-
 * count query would catch on retry, an unenforced convention, not a
 * structural guarantee. Fixed to read the child document transactionally
 * below. This is the FIRST `runTransaction` in this codebase's Cloud
 * Functions — there was no prior one to reuse.
 *
 * The write is an intentional absolute `transaction.update({ seedCount:
 * actualPendingCount })`, not `FieldValue.increment()` — a REGISTERED,
 * SCOPED exception to the `absolute_set_on_balance_or_counters` forbidden
 * pattern (`docs/registry/architecture.yaml`'s `seedcount_drift_correction`
 * entry). That pattern's rationale is multi-device CLIENT races; this
 * correction is server-only, transactional, and recomputes from source of
 * truth rather than blind-decrementing, so the rationale doesn't apply here
 * — do not "fix" this back to an increment.
 *
 * No-ops (no write) when `seedCount` already matches the actual pending
 * count — matching {@link enforceStoredEnergyCap}'s no-op-on-the-common-case
 * discipline. This matters here specifically because `onTaskApproved` fires
 * on EVERY child-doc update (buy, equip, level-up, approve, reject — not
 * just approvals), so an unconditional write here would add needless write
 * cost to the vast majority of invocations that have no actual drift.
 *
 * Extracted from the trigger handler below as a plain, directly
 * unit-testable function — same split as {@link enforceStoredEnergyCap} and
 * {@link reconcileTaskReward}, though this one is exercised via a mocked
 * `runTransaction` rather than a bare `.update()`, since no Firestore
 * emulator is available in this dev environment (see
 * `functions/test/index.test.ts` header comment).
 *
 * `parentId`/`childId` are passed in explicitly (not re-derived from
 * `afterSnapshot.ref`) because they come from the trigger's own
 * `event.params` in {@link onTaskApproved} — this function itself has no
 * access to `event.params`, only to the already-read `after` snapshot.
 */
export async function reconcileSeedCountDrift(
  afterSnapshot: QueryDocumentSnapshot | undefined,
  parentId: string,
  childId: string
): Promise<void> {
  if (!afterSnapshot) {
    return;
  }
  await getFirestore().runTransaction(async (transaction) => {
    // Both reads below must happen INSIDE this transaction (not read
    // separately before it opens, and not reused from the trigger's
    // pre-transaction `afterSnapshot`) — this is what makes the correction
    // safe under concurrent client increments (ADR-0012 Decision §4): only
    // a document/query actually read via `transaction.get()` is tracked for
    // Firestore's optimistic-concurrency conflict detection.
    //
    // The child-document read comes FIRST, matching ADR-0003's "idempotency
    // read must be the FIRST read inside the transaction" rule — this read
    // IS this function's idempotency check (it's what "already correct, no
    // write needed" is decided from).
    const childSnapshot = await transaction.get(afterSnapshot.ref);
    const seedCount = childSnapshot.data()?.seedCount;

    // No centralized path-constants module exists on this Node side (unlike
    // Dart's `FirestorePaths`) — this file builds paths as inline template
    // literals everywhere (see `onTaskSubmitted` below), so match that
    // convention here too.
    const pendingTasksSnapshot = await transaction.get(
      getFirestore()
        .collection(`families/${parentId}/children/${childId}/tasks`)
        .where("status", "==", "pending")
    );
    const actualPendingCount = pendingTasksSnapshot.size;

    if (seedCount === actualPendingCount) {
      return;
    }
    transaction.update(afterSnapshot.ref, { seedCount: actualPendingCount });
  });
}

/**
 * Hosts TWO independent, unrelated reconciliation concerns in a single
 * trigger invocation — `enforceStoredEnergyCap` (see its own doc comment)
 * and `reconcileSeedCountDrift` (ADR-0012 Decision §4, added by Seed Buffer
 * Story 003) — following the same "reuse this trigger for a second
 * concern" precedent ADR-0009 already established here for reward
 * reconciliation (later moved to its own trigger, {@link
 * onTaskRewardReconciliation}, below — see that trigger's doc comment for
 * why). Each concern here is a fully independent operation with its own
 * no-op-on-the-common-case guard, so a non-approval update (buy, equip,
 * level-up) that triggers neither concern's correction issues no EXTRA
 * WRITE beyond the guard checks. The guard checks themselves are not free,
 * though — `reconcileSeedCountDrift`'s guard IS a transactional Firestore
 * query (billed read) that runs on every single invocation of this
 * trigger, drift or not (found in code review, security-engineer,
 * 2026-07-17) — bounded by the child's own small pending-task count, but
 * not literally costless.
 */
export const onTaskApproved = onDocumentUpdated(
  "families/{parentId}/children/{childId}",
  async (event) => {
    await enforceStoredEnergyCap(event.data?.after);
    await reconcileSeedCountDrift(
      event.data?.after,
      event.params.parentId,
      event.params.childId
    );
  }
);

/**
 * ADR-0009's authoritative reward table (Decision §2), mirrored a THIRD
 * time here — alongside `firestore.rules`' `rewardTable()` CEL function
 * (the PRIMARY, deployed enforcement) and Dart's `rewardFor()` (Task
 * Library Story 001, `src/lib/core/reward_table.dart`) — per ADR-0009's own
 * flagged risk ("Reward-table drift across the 3 mirrors... a change is a
 * 3-file edit"). Keep all three in sync by hand; there is no shared-code
 * mechanism across the Dart/Node.js/CEL runtime boundary.
 */
const REWARD_TABLE: Record<string, { xu: number; energy: number }> = {
  study: { xu: 25, energy: 20 },
  arts: { xu: 25, energy: 20 },
  chores: { xu: 15, energy: 25 },
  sport: { xu: 15, energy: 25 },
  helping: { xu: 10, energy: 30 },
  custom: { xu: 15, energy: 25 },
};

/**
 * Defense-in-depth reward-integrity check (ADR-0009 Decision §3, Task
 * Library Story 004). The PRIMARY guard is the already-deployed Security
 * Rule (`firestore.rules`'s `rewardOk()`), which rejects a mismatched
 * reward at `tasks/{taskId}` CREATE time — this is a BACKSTOP for drift
 * that could theoretically occur despite the rule (a rule bypass, a bug,
 * legacy/corrupted data written before the rule existed), not something
 * reachable via the normal client today.
 *
 * No-ops (no write, no log) when [afterSnapshot]'s `xuReward`/`energyReward`
 * match its `categoryId`'s row in {@link REWARD_TABLE} exactly — matching
 * `enforceStoredEnergyCap`'s own no-op-on-the-common-case discipline.
 *
 * On a mismatch (including an unknown/invalid `categoryId`, which cannot
 * match any table entry), logs a structured error flagging the drift.
 * Deliberately does NOT auto-correct the balance — deciding what
 * "correct" means after the fact (reverse the grant? re-derive and top
 * up?) is a separate, riskier design question ADR-0009 does not mandate
 * answering here (Task Library Story 004 Out of Scope).
 *
 * Extracted as a plain, directly unit-testable function — same split as
 * {@link enforceStoredEnergyCap} and {@link cascadeDeleteChildSubcollections}.
 */
export async function reconcileTaskReward(
  afterSnapshot: QueryDocumentSnapshot | undefined
): Promise<void> {
  if (!afterSnapshot) {
    return;
  }
  const data = afterSnapshot.data();
  const categoryId = data.categoryId;
  // A plain bracket lookup (`REWARD_TABLE[categoryId]`) walks the JS
  // prototype chain — `categoryId: 'constructor'` would resolve to the
  // built-in `Object` function (truthy), silently passing as "matched" if
  // xuReward/energyReward also happen to be undefined. `Object.hasOwn`
  // guards against exactly the reserved-prototype-name inputs this
  // function exists to catch (found in code review, security-engineer,
  // 2026-07-16).
  const expected =
    typeof categoryId === "string" && Object.hasOwn(REWARD_TABLE, categoryId)
      ? REWARD_TABLE[categoryId]
      : undefined;
  if (
    expected &&
    data.xuReward === expected.xu &&
    data.energyReward === expected.energy
  ) {
    return;
  }
  console.error("onTaskRewardReconciliation: reward mismatch detected", {
    taskPath: afterSnapshot.ref.path,
    categoryId,
    xuReward: data.xuReward,
    energyReward: data.energyReward,
    expected: expected ?? null,
  });
}

/**
 * Defense-in-depth trigger (ADR-0009 Decision §3, Task Library Story 004).
 *
 * A SEPARATE trigger from `onTaskApproved` above — which watches the CHILD
 * document, for the unrelated `storedEnergy` cap — rather than a literal
 * extension of it, despite ADR-0009 Decision §3's own phrasing ("the
 * existing `onTaskApproved` Cloud Function... reconciles"). `onTaskApproved`
 * has no way to know WHICH task was just approved or what ITS
 * `categoryId`/`xuReward` were from a child-document delta alone.
 * Reconciling against the task document's OWN fields directly, on its own
 * `tasks/{taskId}` trigger, needs no such inference — the technically
 * simpler and more directly correct shape (Task Library Story 004's own
 * Implementation Notes anticipated this exact deviation; ADR-0009's intent
 * — a defense-in-depth reconciliation backstop exists — is preserved
 * either way).
 *
 * Only reconciles when this update transitions the task INTO `approved`
 * status (the point a reward is actually granted) — an edit to a
 * still-pending task, or an already-approved task being touched again,
 * does not re-check.
 */
export const onTaskRewardReconciliation = onDocumentUpdated(
  "families/{parentId}/children/{childId}/tasks/{taskId}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after) {
      return;
    }
    if (before.data().status === "approved" || after.data().status !== "approved") {
      return;
    }
    await reconcileTaskReward(after);
  }
);

const NOTIFICATION_TITLE_MAX_LENGTH = 50;
const NOTIFICATION_BODY_TASK_TITLE_MAX_LENGTH = 80;

/**
 * Truncates by Unicode code point, not UTF-16 code unit — `.slice()`/
 * `.length` operate on code units, so a cut point landing between the two
 * units of a surrogate pair (e.g. an emoji in a child-entered task title)
 * would produce a malformed/unpaired surrogate sent to FCM. `Array.from`
 * splits on code points, avoiding that (found in code review,
 * flame-specialist, 2026-07-16).
 */
function truncateWithEllipsis(value: string, maxLength: number): string {
  const codePoints = Array.from(value);
  return codePoints.length > maxLength
    ? `${codePoints.slice(0, maxLength).join("")}…`
    : value;
}

/**
 * Constructs and sends the fixed FCM payload contract (ADR-0010 Decision
 * §2, Push Notification Story 001) for a single task-submitted event.
 * Takes already-read data rather than raw snapshots — the two extra reads
 * (child's `name`, parent's `fcmToken`) stay in the thin trigger wrapper
 * below, so this function needs no Firestore mocking to test at all.
 *
 * No-ops (never calls `send()`) when [fcmToken] is null/empty/undefined —
 * covers BOTH the null-token case (AC-2) and "parent never granted
 * permission" (AC-7): no permission ever stored means no valid token was
 * ever written, so it's the same guard, not a separate code path.
 *
 * Logs and exits cleanly on an FCM send error (AC-3, e.g.
 * `messaging/registration-token-not-registered`) — no retry, no attempt to
 * mutate `fcmToken` (token cleanup is Auth's job via `onTokenRefresh`).
 */
export async function sendTaskSubmittedNotification({
  taskId,
  childId,
  taskTitle,
  childName,
  fcmToken,
}: {
  taskId: string;
  childId: string;
  taskTitle: string;
  childName: string;
  fcmToken: string | null | undefined;
}): Promise<void> {
  if (!fcmToken) {
    console.warn("onTaskSubmitted: no fcmToken, skipping notification", {
      taskId,
      childId,
    });
    return;
  }

  const title = truncateWithEllipsis(
    `${childName} vừa hoàn thành nhiệm vụ! 🎉`,
    NOTIFICATION_TITLE_MAX_LENGTH
  );
  const body = `${truncateWithEllipsis(
    taskTitle,
    NOTIFICATION_BODY_TASK_TITLE_MAX_LENGTH
  )} — Hãy kiểm tra và approve nhé!`;

  try {
    await getMessaging().send({
      token: fcmToken,
      notification: { title, body },
      data: {
        type: "task_submitted",
        taskId,
        childId,
        deepLink: "petquest://parent/tasks/pending",
      },
      android: { priority: "high" },
      apns: { headers: { "apns-priority": "10" } },
    });
  } catch (error) {
    console.error("onTaskSubmitted: FCM send failed", { taskId, childId, error });
  }
}

/**
 * MVP's one notification trigger (ADR-0010 Decision §1, Push Notification
 * Story 001) — a 2nd-gen `onDocumentCreated` (create-only by definition, no
 * manual `before == null` guard needed) on a task document. Because
 * ADR-0009's reward Security Rule rejects an invalid task at write time,
 * only valid `pending` tasks ever exist to trigger this.
 *
 * No `retry` option is set — 2nd-gen `retry` defaults to disabled when
 * omitted, matching the MVP-disabled requirement (ADR-0010 Decision §6): a
 * systematic handler failure with retry enabled would be time-window- not
 * attempt-bounded, risking many duplicate pushes, not "2-3 rings."
 */
export const onTaskSubmitted = onDocumentCreated(
  { document: "families/{parentId}/children/{childId}/tasks/{taskId}", memory: "256MiB" },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }
    const { parentId, childId, taskId } = event.params;
    // Defensive default, mirroring childName below — firestore.rules'
    // rewardOk() create-rule validates status/categoryId/xuReward/
    // energyReward but does NOT require `title` to exist, so an
    // unguarded read here could throw inside truncateWithEllipsis()
    // before the try/catch is even reached (found in code review,
    // flame-specialist, 2026-07-16).
    const taskTitle = (snapshot.data().title as string | undefined) ?? "";

    const [childDoc, familyDoc] = await Promise.all([
      getFirestore().doc(`families/${parentId}/children/${childId}`).get(),
      getFirestore().doc(`families/${parentId}`).get(),
    ]);

    await sendTaskSubmittedNotification({
      taskId,
      childId,
      taskTitle,
      childName: (childDoc.data()?.name as string | undefined) ?? "",
      fcmToken: familyDoc.data()?.fcmToken as string | undefined,
    });
  }
);
