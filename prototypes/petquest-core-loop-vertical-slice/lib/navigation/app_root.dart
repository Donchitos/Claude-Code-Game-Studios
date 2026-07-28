// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does routing driven purely off sessionStateProvider
// (ADR-0002) stay simple even without go_router's StatefulShellRoute?
// Date: 2026-07-13
//
// Scope cut: real Main Navigation Shell (#17) uses GoRouter's
// StatefulShellRoute with 2 persistent branches. This slice validates the
// SESSION-STATE-AS-SOLE-ROUTING-SOURCE principle (ADR-0002) with plain widget
// switching instead - go_router wiring is deferred to production
// implementation, not needed to validate the loop's fun or the Bridge's
// architecture risk.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_state.dart';
import '../screens/login_screen.dart';
import '../screens/parent_dashboard_screen.dart';
import '../screens/pet_room_screen.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStateProvider);

    if (session.activeChildId == null) {
      return const LoginScreen();
    }
    if (session.mode == AppMode.parentDashboard) {
      return const ParentDashboardScreen();
    }
    return const PetRoomScreen();
  }
}
