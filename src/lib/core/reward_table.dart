/// The authoritative category→reward table (ADR-0009 Decision §2) — the
/// single source of truth Currency (#7) and Time & Decay (#2) reference.
/// Mirrored in THREE independently-maintained places that must stay in
/// sync (ADR-0009's own flagged risk): this file, `firestore.rules`'
/// `rewardTable()` CEL function (the primary, deployed enforcement
/// mechanism — see Data Persistence Layer Story 002), and
/// `design/registry/entities.yaml`'s `task_xu_reward_*`/
/// `task_energy_reward_*` constants (the canonical source this file's own
/// test suite drift-guards against).
const Map<String, ({int xu, int energy})> _rewardTable = {
  'study': (xu: 25, energy: 20),
  'arts': (xu: 25, energy: 20),
  'chores': (xu: 15, energy: 25),
  'sport': (xu: 15, energy: 25),
  'helping': (xu: 10, energy: 30),
  'custom': (xu: 15, energy: 25),
};

/// The reward for [categoryId] — an unknown/invalid category falls back to
/// the `custom` tier `(15, 25)`, matching the ALREADY-deployed Security
/// Rule's own `rewardOk()` fallback behavior (ADR-0009 Decision §3): not
/// exploitable (mid-tier, not max). This function is a convenience for
/// callers computing a reward BEFORE attempting a write (e.g. a UI
/// preview) — it is NOT itself a security boundary; the deployed Security
/// Rule is what actually prevents a mismatched reward from ever being
/// stored.
({int xu, int energy}) rewardFor(String categoryId) {
  return _rewardTable[categoryId] ?? _rewardTable['custom']!;
}

/// The 6 known category IDs — exposed so callers that need to VALIDATE a
/// `categoryId` (e.g. `CustomTaskRepository.createCustomTaskTemplate`,
/// Task Library Story 003) have a single source rather than duplicating
/// this list.
Set<String> get knownCategoryIds => _rewardTable.keys.toSet();

/// The "Quest framing" copy per category (`design/gdd/task-library.md`
/// Core Rule 1's table, `:32-39`) — already-approved GDD copy, not
/// invented here. `TaskModel.flavorText` is a required non-nullable
/// `String` that no prior story ever supplied a value for (Task Library's
/// 4 stories only built the model/reward-table/read-providers/template
/// write, never the task-instance write — see Seed Buffer Story 001's
/// Scope Expansion Note), so this table is added co-located with
/// [rewardFor] per that story's Implementation Notes, same lookup shape.
///
/// `custom`'s value is a PLACEHOLDER, not final content: the GDD's own
/// framing for `custom` is "[bố mẹ tự đặt tên]" (parent-authored, no fixed
/// phrase) — since [flavorTextFor] must return a concrete non-null
/// `String` for every known category, a generic placeholder stands in
/// until a real parent-naming flow exists (out of this story's scope).
const Map<String, String> _flavorTextTable = {
  'study': 'Nạp trí tuệ cho Mochi',
  'arts': 'Truyền cảm hứng cho Mochi',
  'chores': 'Dọn năng lượng cho Mochi',
  'sport': 'Nạp sức mạnh cho Mochi',
  'helping': 'Chia sẻ yêu thương với Mochi',
  'custom': 'Nhiệm vụ đặc biệt', // placeholder — see doc comment above
};

/// The flavor text for [categoryId] — an unknown/invalid category falls
/// back to the same `custom` placeholder [rewardFor] falls back to, for
/// the same reason: this is a pre-write convenience lookup, not a
/// security boundary. Callers that must send only genuinely valid
/// `categoryId`s (e.g. [TaskRepository.submitTask]) validate against
/// [knownCategoryIds] themselves before ever reaching this fallback.
String flavorTextFor(String categoryId) {
  return _flavorTextTable[categoryId] ?? _flavorTextTable['custom']!;
}
