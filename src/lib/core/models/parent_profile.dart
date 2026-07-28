import 'package:cloud_firestore/cloud_firestore.dart';

/// The parent-owned `families/{parentId}` document fields relevant to
/// Auth & Account (per `design/gdd/data-persistence-layer.md` — child
/// subcollection fields are not modeled here; they belong to their owning
/// systems).
class ParentProfile {
  const ParentProfile({
    required this.parentId,
    required this.email,
    required this.displayName,
    this.fcmToken,
    this.createdAt,
  });

  final String parentId;
  final String email;
  final String displayName;
  final String? fcmToken;
  final DateTime? createdAt;

  factory ParentProfile.fromFirestore(
    String parentId,
    Map<String, dynamic> data,
  ) {
    return ParentProfile(
      parentId: parentId,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
