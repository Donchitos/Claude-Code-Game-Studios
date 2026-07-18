/// Centralized Firestore path constants (per ADR-0006's "catalog path
/// constant lives in centralized path constants" rule, applied here as the
/// first Firestore-touching story rather than deferred to a later one).
abstract final class FirestorePaths {
  static String family(String parentId) => 'families/$parentId';

  /// The `children` subcollection under a family — list this to render the
  /// profile-selection screen (name/avatarId/mochiName fields only; never
  /// the credentials sub-document — see [childCredentials]).
  static String children(String parentId) => 'families/$parentId/children';

  static String child(String parentId, String childId) =>
      '${children(parentId)}/$childId';

  /// The credentials sub-document — `get()` only at PIN-entry, never
  /// streamed, never fetched as part of the profile-selection list
  /// (ADR-0002 §7 / data-persistence-layer.md).
  static String childCredentials(String parentId, String childId) =>
      '${child(parentId, childId)}/private/credentials';

  /// A child's task instances (`title, flavorText, categoryId, status,
  /// xuReward, energyReward, submittedAt, approvedAt?, rejectedAt?`) —
  /// ~200 bytes/doc, far under Firestore's 1MB limit (ADR-0003 §2/§8).
  /// Owned by Task Library (#8); reward/category fields are write-gated by
  /// this epic's Security Rules (ADR-0009 §3), not by this repository.
  static String tasks(String parentId, String childId) =>
      '${child(parentId, childId)}/tasks';

  static String task(String parentId, String childId, String taskId) =>
      '${tasks(parentId, childId)}/$taskId';

  /// Family-scoped custom-task **templates** (`title, categoryId,
  /// targetChildId, createdAt` — no `status`/reward fields, unlike
  /// [tasks]) — ~150 bytes/doc, far under Firestore's 1MB limit. A parent
  /// picks `targetChildId` at creation time, so this does NOT nest under a
  /// child path the way [tasks] does (ADR-0003 §2, GDD Detailed Design
  /// §2). Owned by Parent Dashboard UI (#21).
  static String customTasks(String parentId) =>
      '${family(parentId)}/customTasks';

  static String customTask(String parentId, String customTaskId) =>
      '${customTasks(parentId)}/$customTaskId';

  /// A child's owned items (`itemId, acquiredAt, source`) — `itemId` is
  /// the document ID itself (idempotent re-purchase, ADR-0003 §3), ~100
  /// bytes/doc. Owned by Shop (#13) / Gacha-Loot (#12) / Pet Equipment
  /// (#15) — this path is the shared write target for all three.
  static String inventory(String parentId, String childId) =>
      '${child(parentId, childId)}/inventory';

  static String inventoryItem(String parentId, String childId, String itemId) =>
      '${inventory(parentId, childId)}/$itemId';

  /// The global, top-level item catalog — NOT scoped under [family] (ADR-0006
  /// Decision §1, §4: a deliberate, scoped exception to this file's own
  /// family-tree-mutation convention, since this is a global, read-only,
  /// static collection).
  static const String items = 'items';
}
