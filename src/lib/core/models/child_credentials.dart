/// The `families/{parentId}/children/{childId}/private/credentials`
/// sub-document — PBKDF2 hash + salt only, per ADR-0002 §7. Deliberately
/// isolated from [ChildProfile]: never fetched as part of the
/// profile-selection list, only via [ChildProfileRepository.getChildCredentials]
/// at PIN-entry time (Story 004).
class ChildCredentials {
  const ChildCredentials({required this.pinHash, required this.pinSalt});

  final String pinHash;
  final String pinSalt;

  factory ChildCredentials.fromFirestore(Map<String, dynamic> data) {
    return ChildCredentials(
      pinHash: data['pinHash'] as String,
      pinSalt: data['pinSalt'] as String,
    );
  }
}
