import 'package:flutter/material.dart';

/// `/child/tasks/new` sub-screen, nested inside the Tasks branch (Decision
/// §2's `GoRoute(path: 'new', ...)`). Uses the default
/// `PopScope(canPop: true)` — no custom `onPopInvokedWithResult` — so
/// back-press returns to `/child/tasks` via go_router's own nested-route
/// back-stack (AC-12, Implementation Note 6, Decision §6's sub-screen case).
/// The tab-root exit-confirm dialog from Decision §6 is a different case
/// (Story 005), out of scope here.
///
/// A bare placeholder `Scaffold` — real content belongs to Task Management UI
/// (#19), an epic that doesn't exist yet (this story's Out of Scope note).
class NewTaskScreen extends StatelessWidget {
  const NewTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: true,
      child: Scaffold(body: Center(child: Text('New Task'))),
    );
  }
}
