import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_paths.dart';
import 'models/child_credentials.dart';
import 'models/child_profile.dart';

/// Owns the two structurally-separate child-data read paths for Auth &
/// Account Story 005 — kept as distinct methods (not just different field
/// selections on one query) so "credentials never load with the
/// profile-selection list" can't be silently violated by a future refactor
/// (ADR-0002 §7).
class ChildProfileRepository {
  ChildProfileRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Lists child profiles for the profile-selection screen — display fields
  /// only (`name`, `avatarId`, `mochiName`). Never touches the `private/`
  /// subcollection. One-shot `get()`, not a `snapshots()` listener: the
  /// profile-selection screen doesn't need live updates while open (adding
  /// a child is a Parent Dashboard action, a different screen — see
  /// ADR-0003's 2026-07-15 amendment note for the full exception rationale).
  ///
  /// A malformed doc (missing a required field — e.g. a partial write from
  /// a crashed profile-creation flow) is skipped rather than failing the
  /// whole list: with up to 4 siblings sharing this query, one corrupt
  /// document must not lock every child in the family out of profile
  /// selection. Deliberate choice, made during Story 005's code review —
  /// the opposite of `AuthRepository.getParentProfile`'s single-document
  /// context, where propagating the error is correct because there's
  /// nothing else in that result to preserve.
  Future<List<ChildProfile>> getChildProfiles(String parentId) async {
    final snapshot =
        await _firestore.collection(FirestorePaths.children(parentId)).get();
    final profiles = <ChildProfile>[];
    for (final doc in snapshot.docs) {
      try {
        profiles.add(ChildProfile.fromFirestore(doc.id, doc.data()));
      } catch (e) {
        // Skip-and-log, not crash-the-list — see doc comment above.
        debugPrint('ChildProfileRepository: skipping malformed child doc '
            '${doc.id}: $e');
      }
    }
    return profiles;
  }

  /// Reads the credentials sub-document. Returns null (does not throw) if
  /// absent — same "never throw on missing doc" contract as
  /// `AuthRepository.getParentProfile`. One-shot `get()` only, invoked at
  /// PIN-entry time by Story 004 — this method does not call itself
  /// automatically from anywhere in this story.
  Future<ChildCredentials?> getChildCredentials(
    String parentId,
    String childId,
  ) async {
    final snapshot = await _firestore
        .doc(FirestorePaths.childCredentials(parentId, childId))
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ChildCredentials.fromFirestore(data);
  }

  /// Overwrites the credentials sub-document with a freshly-hashed PIN
  /// (Story 007 `resetChildPin`) — same isolated path
  /// [getChildCredentials] reads, never the profile-list document. Callers
  /// own generating the fresh salt/hash (via `pin_crypto.dart`, shared with
  /// Story 004's verification path) — this method is pure Firestore I/O.
  Future<void> setChildCredentials(
    String parentId,
    String childId,
    ChildCredentials credentials,
  ) async {
    await _firestore
        .doc(FirestorePaths.childCredentials(parentId, childId))
        .set(
      {'pinHash': credentials.pinHash, 'pinSalt': credentials.pinSalt},
      SetOptions(merge: true),
    );
  }
}
