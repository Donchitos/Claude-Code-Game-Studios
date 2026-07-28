// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the full submit -> seed -> approve -> reward ->
// Mochi-reacts loop hold together end-to-end against a real (emulated)
// Firebase backend, at representative code quality?
// Date: 2026-07-13
//
// SCOPE CUT (2026-07-13): real Firebase Auth is NOT used in this slice. The
// Auth Emulator connection on Flutter Web hit a persistent
// `firebase_auth/api-key-not-valid` error that didn't resolve within the
// slice's time budget - a tooling/environment friction point, not the
// architecture risk this slice validates (the Bridge + Firestore transaction
// pattern, which IS fully exercised below). PIN-gated child access (PBKDF2,
// ADR-0002) is still real; it just isn't layered on top of a real Firebase
// Auth identity for this build. See REPORT.md Technical Findings.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/pin_service.dart';
import 'core/game_event_bridge.dart';
import 'data/persistence_repository.dart';
import 'data/repository_providers.dart';
import 'firebase_options.dart';
import 'navigation/app_root.dart';

const _devChildPin = '1234';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);

  // Emulator-only - never point at this host in a real build.
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  // Offline persistence - ADR-0003 specified `Settings(cacheSettings:
  // PersistentCacheSettings(...))`, claiming the older persistenceEnabled/
  // cacheSizeBytes pair was @Deprecated in cloud_firestore ^5.x. REAL FINDING
  // (this vertical slice, 2026-07-13): as actually resolved, cloud_firestore
  // 6.6.0's Settings class has NO cacheSettings/PersistentCacheSettings API
  // at all - persistenceEnabled/cacheSizeBytes is still the live, correct API.
  // ADR-0003 needs a correction after this slice - see REPORT.md Technical
  // Findings.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await _bootstrapDevChild();

  runApp(const ProviderScope(child: PetQuestSliceApp()));
}

/// Dev-only bootstrap - real product has full onboarding (Auth & Account +
/// Onboarding Flow #24, out of this slice's scope). Creates the one
/// PIN-gated child profile the slice exercises.
Future<void> _bootstrapDevChild() async {
  final repo = PersistenceRepository(FirebaseFirestore.instance);
  final salt = PinService.generateSalt();
  final hash = await PinService.hashPin(_devChildPin, salt);
  await repo.seedDevFamilyAndChild(
    parentId: devParentId,
    childId: devChildId,
    childName: 'Bé Dev',
    pinHash: hash,
    pinSalt: salt,
  );
}

class PetQuestSliceApp extends StatelessWidget {
  const PetQuestSliceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetQuest Vertical Slice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD060)),
        useMaterial3: true,
      ),
      home: const GameEventBridge(child: AppRoot()),
    );
  }
}
