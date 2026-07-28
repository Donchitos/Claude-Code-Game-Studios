// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the offline-first Firestore schema hold up
// end-to-end for the slice's cut-down loop?
// Date: 2026-07-13
//
// Centralized path constants - no system builds Firestore paths by hand
// (ADR-0003 "Forbidden Approaches"). Slice-scope cut: no items/, customTasks/,
// or inventory/ paths (Gacha/Shop/Equipment are out of scope for this slice).

class FirestorePaths {
  FirestorePaths._();

  static String family(String parentId) => 'families/$parentId';

  static String child(String parentId, String childId) =>
      '${family(parentId)}/children/$childId';

  static String credentials(String parentId, String childId) =>
      '${child(parentId, childId)}/private/credentials';

  static String tasks(String parentId, String childId) =>
      '${child(parentId, childId)}/tasks';

  static String task(String parentId, String childId, String taskId) =>
      '${tasks(parentId, childId)}/$taskId';
}
