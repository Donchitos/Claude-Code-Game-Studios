// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does a derived sessionStateProvider (ADR-0002) cleanly
// drive routing without any system re-deriving session state itself?
// Date: 2026-07-13
//
// Slice simplification: real product has 4 session states (locked/child/parent/
// parentOverride) driven by PIN + Firebase Auth. This slice cuts full onboarding,
// multi-child profile management, AND real Firebase Auth entirely (see
// main.dart header note - Auth Emulator wiring hit an unresolved web-specific
// error). What IS preserved: child access is PIN-gated UI state only, never a
// Firestore-enforced boundary (ADR-0002 Non-Goals) - true here even more
// literally than in the real product, since there is no auth boundary at all
// in this build.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum AppMode { childActive, parentDashboard }

class SessionState {
  final String? activeChildId;
  final AppMode mode;
  const SessionState({required this.activeChildId, required this.mode});
}

/// Which child is currently PIN-unlocked. Null = no child unlocked yet
/// (PIN entry screen shows).
final activeChildIdProvider = StateProvider<String?>((ref) => null);

/// Manual mode toggle - this slice cuts real push notifications, so a parent
/// switches to the dashboard via a button instead of a notification tap.
final appModeProvider = StateProvider<AppMode>((ref) => AppMode.childActive);

/// The single derived routing source of truth (ADR-0002 "Required Patterns" -
/// sessionStateProvider is the sole SoT; no other system re-derives it).
final sessionStateProvider = Provider<SessionState>((ref) {
  final activeChildId = ref.watch(activeChildIdProvider);
  final mode = ref.watch(appModeProvider);
  return SessionState(activeChildId: activeChildId, mode: mode);
});
