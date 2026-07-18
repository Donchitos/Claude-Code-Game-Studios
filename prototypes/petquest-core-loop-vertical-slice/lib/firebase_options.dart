// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the offline-first Firestore + Auth architecture work?
// Date: 2026-07-13
//
// Placeholder FirebaseOptions for EMULATOR-ONLY use. No real Firebase project
// exists yet - these values are never sent to a real backend because main.dart
// points the Auth/Firestore SDKs at the local emulator suite before any use.
// A real project's `flutterfire configure` output must replace this file before
// any production build.

import 'package:firebase_core/firebase_core.dart';

class DevFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'dev-emulator-key',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'petquest-vertical-slice',
    authDomain: 'petquest-vertical-slice.firebaseapp.com',
    storageBucket: 'petquest-vertical-slice.appspot.com',
  );
}
