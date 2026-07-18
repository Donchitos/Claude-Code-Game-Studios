/// The `families/{parentId}/children/{childId}` document fields relevant to
/// Auth & Account's profile-selection list — per
/// `design/gdd/data-persistence-layer.md`'s schema. Fields owned by other
/// systems (`xuBalance`, `storedEnergy`, `petLevel`, etc.) are not modeled
/// here; they belong to their owning systems' own models.
///
/// Story 002 (`sessionStateProvider`) introduced this class as a
/// single-field placeholder (just `childId`) so `activeChildProvider` could
/// be typed per ADR-0002. Story 005 (this) widens it in place with the
/// profile-display fields — not a subclass, per Story 002's own doc comment
/// on why that would break existing `ChildProfile(childId: x)` callsites.
class ChildProfile {
  const ChildProfile({
    required this.childId,
    required this.name,
    required this.avatarId,
    required this.mochiName,
  });

  final String childId;
  final String name;
  final String avatarId;
  final String mochiName;

  factory ChildProfile.fromFirestore(String childId, Map<String, dynamic> data) {
    return ChildProfile(
      childId: childId,
      name: data['name'] as String,
      avatarId: data['avatarId'] as String,
      mochiName: data['mochiName'] as String,
    );
  }
}
