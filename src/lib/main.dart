import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/auth_providers.dart';
import 'providers/router_provider.dart';
import 'providers/time_decay_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence before the first Firestore call —
  // required by ADR-0003, per docs/architecture/control-manifest.md's Core
  // Layer Rules (persistenceEnabled/cacheSizeBytes pair, not the nonexistent
  // cacheSettings/PersistentCacheSettings API — see that ADR's Correction note).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: PetQuestApp()));
}

class PetQuestApp extends ConsumerWidget {
  const PetQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps fcmTokenRefreshListenerProvider actively watched for the app's
    // lifetime (Story 008) — same liveness requirement as routerProvider.
    ref.watch(fcmTokenRefreshListenerProvider);
    // Same liveness requirement — constructs the single AppLifecycleListener
    // once at app root (Time & Decay Story 002), never per-screen.
    ref.watch(appLifecycleListenerProvider);
    return MaterialApp.router(
      title: 'PetQuest',
      routerConfig: ref.watch(routerProvider),
    );
  }
}
