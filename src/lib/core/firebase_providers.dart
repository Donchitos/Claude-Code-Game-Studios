import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable Firebase SDK singleton seams. Every story that touches Firebase
/// Auth, Firestore, or Messaging should depend on these providers rather than
/// reaching for `FirebaseAuth.instance`/`FirebaseFirestore.instance`/
/// `FirebaseMessaging.instance` directly — this is what makes repositories
/// unit-testable without a live Firebase backend (coding-standards.md:
/// dependency injection over singletons).
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final firebaseMessagingProvider =
    Provider<FirebaseMessaging>((ref) => FirebaseMessaging.instance);
