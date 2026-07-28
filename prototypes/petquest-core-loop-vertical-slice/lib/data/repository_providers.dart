// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: n/a (wiring only)
// Date: 2026-07-13

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'persistence_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final persistenceRepositoryProvider = Provider<PersistenceRepository>((ref) {
  return PersistenceRepository(ref.watch(firestoreProvider));
});

/// Dev-only fixed IDs - real product derives these from Firebase Auth uid
/// (parent) and a profile picker (child). Out of scope for this slice (real
/// Firebase Auth is cut from this build - see main.dart header note).
const String devParentId = 'dev-parent';
const String devChildId = 'dev-child';
