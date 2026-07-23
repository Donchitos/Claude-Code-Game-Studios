import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StateProvider` moved to the legacy export in riverpod 3.x — same fix
// already applied throughout this codebase (`auth_providers.dart`,
// `router_provider.dart`); required here for [pendingCardStatusProvider].
import 'package:flutter_riverpod/legacy.dart';

import '../core/game_event_bus.dart';
import '../core/models/child_profile.dart';
import '../core/models/task_model.dart';
import '../providers/auth_providers.dart';
import '../providers/parent_approval_providers.dart';
import '../providers/task_providers.dart';
import 'app_colors.dart';
import 'create_custom_task_sheet.dart';
import 'select_child_action.dart';

/// Parent Shell's Dashboard tab (Parent Dashboard UI Story 001,
/// TR-parentdash-001) — the real Tab Nhiệm vụ: pending-task list wired to
/// Approve/Reject, per `design/ux/parent-dashboard-ui.md`. Replaces the bare
/// placeholder body main-navigation-shell Story 003 left here, in place,
/// same convention as `ParentDashboardFamilyTab` (Story 003) editing its own
/// placeholder file rather than swapping the widget name.
///
/// Named `ParentDashboardTasksTab` to match ADR-0014 Decision §3's own code
/// sample exactly (`parentShellRoute`'s branch builder), unchanged from the
/// placeholder.
///
/// **App bar title change, and the pre-existing regression tests it
/// touches**: the placeholder used a literal `Text('Parent Dashboard')` app
/// bar title purely as a routing-regression marker for
/// `root_redirect_test.dart`/`router_redirect_test.dart`/`parent_shell_test.dart`
/// (main-navigation-shell / auth_account epics, both already Complete). This
/// story's own AC/UX spec (`design/ux/parent-dashboard-ui.md` Layout Zones,
/// ASCII Wireframe) require the REAL app bar title "Nhiệm vụ" instead. Per
/// this task's authoritative brief, the story's own AC governs — so those 3
/// pre-existing tests have been updated (not this file) to assert on the
/// route's URI instead of the now-superseded literal copy string, which is
/// what they actually intended to verify ("did routing really reach
/// `/parent/dashboard`"), not the exact wording of a placeholder marker.
///
/// **This is the FIRST real call site of `ParentApprovalRepository
/// .approveTask()`/`rejectTask()` and the first live `GameEvent(taskApproved)`/
/// `(petLeveledUp)` emission anywhere in the running app** (ADR-0013 §2,
/// ADR-0004 §3 adapter (a)) — see [_approveTask]'s doc comment for the exact
/// emission contract.
///
/// **GameEventBus replay risk — now live, not fixed here** (Story 001
/// Implementation Note 11 / Parent Approval epic's Known Risks /
/// ADR-0004 §5 Consequences → Risks): `GameEventBus` caches and replays the
/// LAST event per `GameEventType` to any newly-subscribing listener. Once
/// any task has ever been approved through this widget, every later remount
/// of a Flame component subscribing to `taskApproved`/`petLeveledUp` (e.g.
/// Pet Room navigated away and back) will receive a spurious replay and
/// incorrectly re-trigger the bounce/level-up animation. This is pre-existing
/// tech debt in the bus's design (flagged in ADR-0013's own Consequences →
/// Risks section before this story existed) — this story is simply the
/// first thing that ever makes it reachable by being the first real emitter.
/// Fixing it requires an ADR-0004 revision (excluding trigger-type events
/// from the replay cache, or giving components an "already-handled" event
/// identity) — a cross-cutting change explicitly OUT OF SCOPE for this
/// story (see its own Out of Scope section). Recorded here, not silently
/// shipped, per Parent Approval epic's Definition of Done item 5.
///
/// A `StatefulWidget` (now `ConsumerStatefulWidget`) with a public
/// (not `_`-prefixed) `State` class is used deliberately — main-navigation-
/// shell Story 003's AC-4 ("state preservation across tabs") needs a real
/// test seam proving no rebuild/dispose occurs across a branch round-trip.
/// `ConsumerState<ParentDashboardTasksTab>` still satisfies
/// `State<ParentDashboardTasksTab>` (the type `parent_shell_test.dart`
/// reaches via `tester.state<ParentDashboardTasksTabState>(...)`), so this
/// story adds Riverpod consumption without touching that seam's identity —
/// see [ParentDashboardTasksTabState.initCount].
class ParentDashboardTasksTab extends ConsumerStatefulWidget {
  const ParentDashboardTasksTab({super.key});

  @override
  ConsumerState<ParentDashboardTasksTab> createState() =>
      ParentDashboardTasksTabState();
}

/// Public test seam (main-navigation-shell Story 003's own AC-4 design, see
/// class doc comment above) — must NOT be `_`-prefixed, since
/// `tests/integration/main-navigation-shell/parent_shell_test.dart` reaches
/// it via `tester.state<ParentDashboardTasksTabState>(...)`, which requires
/// the type to be visible outside this library.
class ParentDashboardTasksTabState
    extends ConsumerState<ParentDashboardTasksTab> {
  /// Incremented exactly once, in [initState] — never touched again. See
  /// the original placeholder's doc comment (preserved in spirit): proves
  /// `StatefulShellRoute.indexedStack` never disposes this branch across a
  /// switch to the sibling "Gia đình" branch and back.
  int initCount = 0;

  @override
  void initState() {
    super.initState();
    initCount++;
  }

  @override
  Widget build(BuildContext context) {
    // Deliberately does NOT `ref.watch` anything here — the Scaffold shell
    // (app bar/FAB) must not rebuild on every pending-list change (Control
    // Manifest: targeted Consumer/Selector rebuild scoping, ADR-0001). The
    // list content lives in its own `ConsumerWidget` below.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhiệm vụ'),
        actions: const [SelectChildAction()],
      ),
      // Story 004 (ADR-0015 Decision §6) superseded the reserved
      // `SizedBox.shrink()` banner slot this `Column` used to hold — the
      // FCM/reminder banner now renders at the `ParentShellScaffold` level
      // via `MaterialBanner`/`ScaffoldMessenger`, not inline in this tab's
      // own layout. No `Column` wrapper is needed anymore now that there's
      // only one child.
      body: const _PendingTaskListSection(),
      floatingActionButton: FloatingActionButton(
        key: const Key('createCustomTaskFab'),
        onPressed: () => showCreateCustomTaskSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Per-card Approve/Reject action status (**P1** single-flight guard,
/// Implementation Note 6) — screen-scoped Riverpod state, keyed by
/// `TaskModel.id`, deliberately NOT local `State` on the card widget: it
/// must survive a `familyPendingTasksProvider` list rebuild mid-transaction
/// (e.g. a sibling card's action completing, or an unrelated snapshot
/// re-emission) and a tab switch away and back while a transaction is still
/// in flight (AC-6 / QA AC-6). Absent key == idle (never tapped / already
/// resolved).
class PendingCardStatus {
  const PendingCardStatus({this.inFlight = false, this.errorMessage});

  final bool inFlight;
  final String? errorMessage;

  /// Explicit value equality — `_PendingTaskCard`'s
  /// `pendingCardStatusProvider.select((map) => map[task.id] ?? ...)` relies
  /// on this to skip a sibling card's rebuild when ITS status is unchanged.
  /// Without this override, every construction site in this file would need
  /// to stay `const` forever for Dart's const-canonicalization to provide
  /// the same identity-equality effect implicitly — a real but easy-to-miss
  /// invariant (found in code review). An explicit override makes the
  /// targeted-rebuild guarantee hold even if a future edit adds a
  /// non-const construction (e.g. an error message embedding dynamic text).
  @override
  bool operator ==(Object other) =>
      other is PendingCardStatus &&
      other.inFlight == inFlight &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(inFlight, errorMessage);
}

final pendingCardStatusProvider =
    StateProvider<Map<String, PendingCardStatus>>((ref) => const {});

void _setCardStatus(WidgetRef ref, String taskId, PendingCardStatus status) {
  final current = ref.read(pendingCardStatusProvider);
  ref.read(pendingCardStatusProvider.notifier).state = {
    ...current,
    taskId: status,
  };
}

void _clearCardStatus(WidgetRef ref, String taskId) {
  final current = ref.read(pendingCardStatusProvider);
  if (!current.containsKey(taskId)) return;
  final next = {...current}..remove(taskId);
  ref.read(pendingCardStatusProvider.notifier).state = next;
}

/// Unified, cause-agnostic error copy (ADR-0013 §5 — "any `runTransaction`
/// throw (offline, transient, or other) is caught identically, no
/// cause-specific branching") — used for BOTH the offline pre-check
/// (Implementation Note 9) and any real `approveTask()`/`rejectTask()`
/// failure. This story wires to Parent Approval's own unified error
/// handling; it does not invent a second, differently-worded error path for
/// the offline case.
const _genericActionErrorMessage = 'Không thực hiện được — thử lại';

/// Best-effort offline pre-check (Implementation Note 9 / GDD Core Rule 2) —
/// wrapped in its own try/catch so a platform-channel failure (e.g. this
/// exact widget-test environment, which has no `connectivity_plus` platform
/// implementation wired up unless a test explicitly overrides
/// [connectivityProvider]) never blocks the action. Per ADR-0013's own
/// Constraints, this pre-check is "a UX optimization, not the actual safety
/// mechanism" — the real `approveTask()`/`rejectTask()` call is what
/// actually protects correctness, so failing to determine connectivity
/// falls open (assume online) rather than falling closed.
Future<bool> _isOfflineBestEffort(WidgetRef ref) async {
  try {
    return await isDeviceOffline(ref.read(connectivityProvider));
  } catch (_) {
    return false;
  }
}

/// **Approve tap handler — the sanctioned adapter (a) usage** (ADR-0004 §3 /
/// ADR-0013 §2 / Implementation Note 7): `await`s the transaction result
/// directly inside this `ConsumerWidget`'s own tap-handler continuation — no
/// bridge widget, no `ref.listen` (that shape, used by `mood_event_bridge.dart`,
/// is for a DIFFERENT adapter case — a state change with no natural
/// "awaitable call site" of its own; this handler already has one). If the
/// result is non-null (a real commit, not the idempotent no-op path),
/// `GameEvent(taskApproved)` emits unconditionally, then
/// `GameEvent(petLeveledUp, result.newPetLevel)` emits only if
/// `result.leveledUp` — in that order, matching AC-4 exactly.
Future<void> _approveTask(WidgetRef ref, TaskModel task) async {
  // Re-entrant P1 guard, checked SYNCHRONOUSLY at entry — the button's own
  // `onPressed: status.inFlight ? null : ...` only disables itself once
  // Riverpod's state write actually triggers a rebuild, which needs a pump;
  // a second tap landing in the same frame (no pump in between, e.g. a
  // rapid double-tap) still fires this handler against the STILL-mounted
  // enabled button. Without this check, both invocations would race past
  // this point and each call `approveTask()` — found as a real bug (not
  // theoretical) verifying this story: `test_rapidDoubleTapApprove_
  // callsApproveTaskExactlyOnce` failed with 2 calls before this fix, same
  // regression class this epic's `ResetPinDialog._confirm()` (Story 003)
  // already guards against via its own `if (!_canConfirm) return;` first
  // line — mirrored here.
  if (ref.read(pendingCardStatusProvider)[task.id]?.inFlight ?? false) return;

  final parentId = ref.read(authStateProvider).value?.uid;
  if (parentId == null) return; // defensive — unreachable from an authed-only screen

  _setCardStatus(ref, task.id, const PendingCardStatus(inFlight: true));

  if (await _isOfflineBestEffort(ref)) {
    _setCardStatus(
      ref,
      task.id,
      const PendingCardStatus(errorMessage: _genericActionErrorMessage),
    );
    return;
  }

  try {
    final result = await ref.read(parentApprovalRepositoryProvider).approveTask(
          parentId: parentId,
          childId: task.childId,
          taskId: task.id,
        );
    if (result != null) {
      GameEventBus().emit(const GameEvent(GameEventType.taskApproved, null));
      if (result.leveledUp) {
        GameEventBus()
            .emit(GameEvent(GameEventType.petLeveledUp, result.newPetLevel));
      }
    }
    // Idempotent no-op (result == null) — silent, no error, no event, per
    // ADR-0013 §2 (double-tap / two-device race, both handled upstream).
    //
    // Safe to use `ref` here despite this card possibly having just been
    // removed from `familyPendingTasksProvider`'s list (the now-approved
    // task no longer matches its `status == pending` filter): Flutter defers
    // actual widget unmounting to a frame boundary, which cannot happen
    // until the current microtask queue drains — and this whole `await`
    // continuation runs as one microtask, completing before any new frame
    // is built. `ref` is therefore guaranteed still-mounted here regardless
    // of provider-state ordering (found in code review — do not "fix" a
    // theoretical unmounted-ref risk by adding a `mounted`-style guard here,
    // there isn't one for a plain `WidgetRef` and none is needed).
    _clearCardStatus(ref, task.id);
  } catch (_) {
    _setCardStatus(
      ref,
      task.id,
      const PendingCardStatus(errorMessage: _genericActionErrorMessage),
    );
  }
}

/// **Reject tap handler** (Implementation Note 8): calls `rejectTask()` and
/// emits NOTHING — GDD Core Rule 3, reject's "wither" animation is UI-local
/// (Task Management UI #19's job, on the child's own device), not a
/// GameEventBus trigger.
Future<void> _rejectTask(WidgetRef ref, TaskModel task) async {
  // Re-entrant P1 guard — same rationale as `_approveTask`'s identical
  // check above (a rapid double-tap can land its second tap before the
  // first's state write triggers a rebuild).
  if (ref.read(pendingCardStatusProvider)[task.id]?.inFlight ?? false) return;

  final parentId = ref.read(authStateProvider).value?.uid;
  if (parentId == null) return;

  _setCardStatus(ref, task.id, const PendingCardStatus(inFlight: true));

  if (await _isOfflineBestEffort(ref)) {
    _setCardStatus(
      ref,
      task.id,
      const PendingCardStatus(errorMessage: _genericActionErrorMessage),
    );
    return;
  }

  try {
    await ref.read(parentApprovalRepositoryProvider).rejectTask(
          parentId: parentId,
          childId: task.childId,
          taskId: task.id,
        );
    _clearCardStatus(ref, task.id);
  } catch (_) {
    _setCardStatus(
      ref,
      task.id,
      const PendingCardStatus(errorMessage: _genericActionErrorMessage),
    );
  }
}

/// Watches [familyPendingTasksProvider] + [childProfilesProvider] and
/// renders skeleton (**P5**) / inline error+retry / empty state (**P6**) /
/// the real list — isolated into its own `ConsumerWidget` so a pending-list
/// change never rebuilds the parent Scaffold/app bar/FAB (Control Manifest:
/// targeted rebuild scoping).
class _PendingTaskListSection extends ConsumerWidget {
  const _PendingTaskListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(familyPendingTasksProvider);
    final childrenAsync = ref.watch(childProfilesProvider);

    void retry() {
      ref.invalidate(familyPendingTasksProvider);
      ref.invalidate(childProfilesProvider);
    }

    return tasksAsync.when(
      loading: () => const _PendingListSkeleton(),
      error: (_, _) => _PendingListError(onRetry: retry),
      data: (tasks) => childrenAsync.when(
        loading: () => const _PendingListSkeleton(),
        error: (_, _) => _PendingListError(onRetry: retry),
        data: (children) => _PendingTaskListView(tasks: tasks, children: children),
      ),
    );
  }
}

class _PendingTaskListView extends StatelessWidget {
  const _PendingTaskListView({required this.tasks, required this.children});

  final List<TaskModel> tasks;
  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      // P6 — empty state; FAB stays usable (it lives in the parent Scaffold,
      // unaffected by this widget).
      return const Center(
        child: Text(
          'Chưa có nhiệm vụ nào chờ duyệt',
          style: TextStyle(color: AppColors.primaryText),
        ),
      );
    }

    final childrenById = {for (final c in children) c.childId: c};
    return ListView.builder(
      key: const Key('pendingTaskList'),
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _PendingTaskCard(
          key: ValueKey(task.id),
          task: task,
          child: childrenById[task.childId],
        );
      },
    );
  }
}

/// P5 — skeleton/shimmer while the first `familyPendingTasksProvider`/
/// `childProfilesProvider` snapshot is pending; never a blank screen or a
/// spinner-with-character.
class _PendingListSkeleton extends StatelessWidget {
  const _PendingListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        3,
        (_) => Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.cloudWhite,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Inline error + retry — new Acceptance Criteria (gap the GDD didn't cover,
/// added during `/ux-design`): `familyPendingTasksProvider`/
/// `childProfilesProvider` throwing must never crash the whole screen.
class _PendingListError extends StatelessWidget {
  const _PendingListError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.primaryText, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Không tải được danh sách — thử lại',
            style: TextStyle(color: AppColors.primaryText),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('pendingListRetryButton'),
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lavenderSoft,
              foregroundColor: AppColors.primaryText,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

/// Category icon+label display table (presentation-only, no reward
/// implication — same "kept local to this file" precedent as
/// `create_custom_task_sheet.dart`'s own `_categoryLabels`, but covering all
/// 6 known category IDs including `custom`, since a PENDING task (unlike the
/// create-task sheet's dropdown) can legitimately be any of the 6 real
/// stored `categoryId` values). Falls back to `custom`'s entry for an
/// unrecognized ID, mirroring `reward_table.dart`'s own fallback contract.
const Map<String, ({IconData icon, String label})> _categoryDisplay = {
  'study': (icon: Icons.menu_book, label: 'Học tập'),
  'arts': (icon: Icons.palette, label: 'Nghệ thuật'),
  'chores': (icon: Icons.cleaning_services, label: 'Việc nhà'),
  'sport': (icon: Icons.sports_soccer, label: 'Thể thao'),
  'helping': (icon: Icons.favorite, label: 'Giúp đỡ'),
  'custom': (icon: Icons.star, label: 'Khác'),
};

({IconData icon, String label}) _categoryDisplayFor(String categoryId) =>
    _categoryDisplay[categoryId] ?? _categoryDisplay['custom']!;

/// "submitted X phút/giờ trước" (UX spec Layout Zones / Interaction Map) —
/// pure, vi-only formatting (see UX spec's Localization Considerations) of
/// the elapsed time since [submittedAt]. [now] is injectable so tests are
/// deterministic (test-standards.md: no time-dependent assertions without a
/// fixed clock).
String relativeSubmittedAtLabel(DateTime submittedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final elapsed = reference.difference(submittedAt);
  if (elapsed.inMinutes < 1) return 'submitted vừa xong';
  if (elapsed.inHours < 1) return 'submitted ${elapsed.inMinutes} phút trước';
  if (elapsed.inDays < 1) return 'submitted ${elapsed.inHours} giờ trước';
  return 'submitted ${elapsed.inDays} ngày trước';
}

/// A single pending-task card: avatar+tên bé, category icon+label, task
/// title, relative time, Approve/Reject (**P1** + **P8**).
///
/// [child] is nullable — defensive against a task whose owning child profile
/// can't be resolved (e.g. a stale/deleted profile); renders a placeholder
/// name rather than crashing, matching this codebase's established
/// defensive-render convention (`_LoadErrorContent` etc.) rather than a
/// silent wrong-child render (AC-2's own multi-child correctness concern —
/// showing a visibly-wrong placeholder is safer than a plausible-looking but
/// incorrect name).
class _PendingTaskCard extends ConsumerWidget {
  const _PendingTaskCard({super.key, required this.task, required this.child});

  final TaskModel task;
  final ChildProfile? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      pendingCardStatusProvider.select(
        (map) => map[task.id] ?? const PendingCardStatus(),
      ),
    );
    final category = _categoryDisplayFor(task.categoryId);

    return Card(
      key: Key('pendingTaskCard_${task.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.lavenderSoft,
                  child: Icon(Icons.pets, color: AppColors.primaryText),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    child?.name ?? '—',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                Icon(category.icon, size: 18, color: AppColors.secondaryText),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    category.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(fontSize: 16, color: AppColors.primaryText),
            ),
            const SizedBox(height: 4),
            Text(
              relativeSubmittedAtLabel(task.submittedAt),
              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
            if (status.errorMessage != null) ...[
              const SizedBox(height: 8),
              _ErrorMessage(message: status.errorMessage!),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    key: Key('rejectButton_${task.id}'),
                    onPressed: status.inFlight ? null : () => _rejectTask(ref, task),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryText),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: Key('approveButton_${task.id}'),
                    onPressed: status.inFlight ? null : () => _approveTask(ref, task),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mintBreeze,
                      foregroundColor: AppColors.primaryText,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// **P8**: icon + color feedback, never color-alone — same shape as
/// `CreateCustomTaskSheet`'s own private `_ErrorMessage` (duplicated by
/// necessity; that class is library-private).
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.primaryText, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(message, style: const TextStyle(color: AppColors.primaryText)),
        ),
      ],
    );
  }
}
