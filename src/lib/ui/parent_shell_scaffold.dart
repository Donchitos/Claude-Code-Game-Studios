import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/firebase_providers.dart';
import '../core/models/child_profile.dart';
import '../core/models/task_model.dart';
import '../providers/auth_providers.dart';
import '../providers/banner_providers.dart';
import '../providers/router_provider.dart';
import '../providers/task_providers.dart';
import 'app_colors.dart';
import 'parent_override_actions.dart';

/// Hosts the Parent Shell's [StatefulNavigationShell] as the `Scaffold.body`,
/// with a 2-destination bottom [NavigationBar] (Nhiệm vụ/Gia đình) driving
/// `goBranch` (main-navigation-shell Story 003, ADR-0014 Decision §3/§4).
///
/// Structurally mirrors [ChildShellScaffold] (`child_shell_scaffold.dart`) —
/// same `initState`/`didUpdateWidget` guarded post-frame sync of
/// [activeChildBranchIndexProvider] from `navigationShell.currentIndex`, and
/// the same synchronous `goBranch` + provider-write tap handler. This exact
/// sync was added to `ChildShellScaffold` during Story 002's code review
/// after a real bug was found there — `activeChildBranchIndexProvider`
/// staying stuck at its default value when a route lands on a non-default
/// branch WITHOUT a tap (e.g. a deep link or restored navigation state).
/// Reproduced here deliberately, not reinvented, to avoid reintroducing that
/// same bug in this shell.
///
/// Unlike [ChildShellScaffold], there is NO `Stack` overlay here — Parent
/// Shell has no floating chips (GDD Core Rule 5 / Main Navigation Shell
/// Story 003's Implementation Note 2). `body: widget.navigationShell` is
/// passed directly to [Scaffold], so no `Stack` widget exists anywhere in
/// this subtree — the structural proof that story's "no floating chips"
/// acceptance criterion tests against
/// (`tests/integration/main-navigation-shell/parent_shell_test.dart`'s
/// `test_AC3_noFloatingChips_...`), and a real, registered forbidden
/// pattern (`docs/registry/architecture.yaml`'s
/// `forbidden_patterns.parent_shell_stack_overlay`).
///
/// **FCM foreground banner + permission reminder (Parent Dashboard UI
/// Story 004, ADR-0015)**: rendered via
/// `ScaffoldMessenger.of(context).showMaterialBanner(...)`/
/// `.hideCurrentMaterialBanner()`/`.removeCurrentMaterialBanner()` — NOT a
/// `Stack`-positioned widget — so it introduces zero new `Stack`s while
/// still being genuinely shell-level (both tabs share the one persistent
/// `Scaffold`/`ScaffoldMessenger` this class owns). [_onMessageSub]
/// subscribes to `FirebaseMessaging.onMessage` in [initState] and forwards
/// each message to [bannerActionsProvider]'s `messageReceived`; the
/// notification-permission status is resolved once via
/// `firebaseMessagingProvider.getNotificationSettings()` (DI'd, not the
/// bare `FirebaseMessaging.instance` static ADR-0015's own code sample used
/// — this codebase's established convention, `firebase_providers.dart`,
/// and what keeps this widget testable without a live Firebase app; see
/// [_ParentShellScaffoldState.initState]'s doc comment for the full
/// rationale). [_syncMaterialBanner] is driven by
/// `ref.listenManual(bannerStateProvider.select((s) => s.displayKind), ...)`
/// — the same one-time-`initState`-subscription idiom already established
/// by `mood_event_bridge.dart` in this codebase.
///
/// Visual tone is deliberately distinct from [ChildShellScaffold]'s default
/// `NavigationBar`: navy-toned and more subdued, 24dp icons / 12sp labels
/// (Implementation Note 4). Set via a [NavigationBarTheme] scoped to only
/// this widget's own `NavigationBar`, using [AppColors.parentNavy] (found in
/// code review to be a real, already-cited-elsewhere GDD value — not a
/// single-widget concern after all, see `app_colors.dart`'s own doc comment)
/// — this guarantees Child Shell and Parent Shell can never accidentally end
/// up sharing one `NavigationBar` widget config, while still keeping the
/// color itself centralized.
///
/// **Open accessibility question, flagged not silently resolved** (found in
/// code review): `design/ux/main-navigation-shell.md:232`'s 2026-07-13/14
/// contrast audit says text/icons on a Navy background must use Primary text
/// (`#3D2B1F`) — but that audit only tested Primary text against the 7
/// existing light/mid-tone Art Bible fills, none of which is this dark a
/// background. Primary text (itself dark brown) on dark Navy would almost
/// certainly fail contrast in the OPPOSITE direction the audit was guarding
/// against. This widget uses a light, high-contrast tone instead
/// (`Colors.white70`) as the safer choice pending a real
/// WCAG check of text-on-Navy specifically — not yet run. Do not copy the
/// literal "always Primary text" rule here without that audit.
///
/// **Back-press (Story 004, AC-13; ADR-0014 Decision §6's THIRD code
/// sample)**: every screen inside this shell is wrapped in the
/// override-exit `PopScope` — `canPop: false`, and
/// `onPopInvokedWithResult` calls
/// [endParentOverrideAndReturnToPetRoom] instead of letting the pop
/// proceed (which would otherwise exit the app, since this shell has no
/// screen below it on the Navigator stack). Deliberately unconditional,
/// not branched on `ref.watch(parentOverrideProvider)`: ADR-0014 Decision
/// §6 also documents a second, plain `PopScope(canPop: true)` shape for
/// "Parent Shell tab-root, NOT in override" — but that case is
/// structurally UNREACHABLE here. `redirectForSessionState` only ever
/// routes to `/parent/*` (where this shell lives) for
/// `SessionState.parentView`, and `sessionStateProvider`'s own derivation
/// (`auth_providers.dart`) defines `parentView` as `activeChild != null &&
/// parentOverrideProvider == true` — i.e. reaching this shell at all
/// already guarantees override is `true`. Branching on the provider here
/// would be dead code the redirect guard can never exercise; flagged
/// rather than added speculatively (found during this story's own
/// implementation, not guessed at ahead of time).
class ParentShellScaffold extends ConsumerStatefulWidget {
  const ParentShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ParentShellScaffold> createState() =>
      _ParentShellScaffoldState();
}

class _ParentShellScaffoldState extends ConsumerState<ParentShellScaffold> {
  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'Nhiệm vụ',
    ),
    NavigationDestination(
      icon: Icon(Icons.family_restroom_outlined),
      selectedIcon: Icon(Icons.family_restroom),
      label: 'Gia đình',
    ),
  ];

  /// Cancelled in [dispose] — `FirebaseMessaging.onMessage` is a plain
  /// static broadcast `StreamController` (verified against the installed
  /// `firebase_messaging_platform_interface-4.9.2` source,
  /// `platform_interface_messaging.dart`), not a per-widget resource, so an
  /// un-cancelled subscription here would keep forwarding messages to a
  /// disposed `ref` after this widget is torn down.
  StreamSubscription<RemoteMessage>? _onMessageSub;

  @override
  void initState() {
    super.initState();
    _syncActiveBranchIndexAfterBuild();

    // ADR-0015 Decision §4 — Parent Dashboard UI Story 004.
    _onMessageSub = FirebaseMessaging.onMessage.listen(
      (message) => ref.read(bannerActionsProvider).messageReceived(message),
    );
    // Resolved via the DI'd `firebaseMessagingProvider`
    // (`core/firebase_providers.dart`), NOT the bare `FirebaseMessaging
    // .instance` static ADR-0015's own code sample shows — `.instance`
    // resolves through `Firebase.app()` and throws `[core/no-app]` without a
    // live Firebase app, which would crash every widget test that mounts
    // this scaffold (including the already-Complete Main Navigation Shell
    // Story 003 regression suite) unless each one were updated to bootstrap
    // real Firebase. `firebaseMessagingProvider` defaults to the exact same
    // `FirebaseMessaging.instance` in production while staying overridable
    // with a fake in tests — same DI-over-singleton convention this
    // codebase already applies everywhere else Firebase is touched
    // (`notification_providers.dart`'s `requestPermissionOnce`,
    // `auth_providers.dart`'s `fcmTokenRefreshListenerProvider`). Zero
    // behavior change in production; a deliberate, low-risk deviation from
    // ADR-0015's literal code sample for testability.
    ref.read(firebaseMessagingProvider).getNotificationSettings().then((settings) {
      if (!mounted) return;
      ref.read(bannerActionsProvider).permissionStatusResolved(
            declined: settings.authorizationStatus == AuthorizationStatus.denied,
          );
    });
    // Fires only when `displayKind` itself CHANGES (none<->fcm<->reminder),
    // never on an in-kind `unseenCount` change (e.g. 2->3 while `fcm` stays
    // `fcm`) — that in-place text update is handled reactively by
    // `_buildBanner`'s own `Consumer`, not by re-invoking this listener
    // (ADR-0015 Decision §2's "live-update in place, never a second
    // banner" requirement — see Edge Case 5's 3-message-during-modal
    // permutation).
    ref.listenManual<BannerKind>(
      bannerStateProvider.select((s) => s.displayKind),
      _syncMaterialBanner,
    );
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ParentShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Covers any route arriving at a non-default branch WITHOUT going
    // through `_onDestinationSelected`'s tap handler — same rationale as
    // `ChildShellScaffold.didUpdateWidget` (main-navigation-shell Story 002
    // code review finding).
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _syncActiveBranchIndexAfterBuild();
    }
  }

  /// Deferred to a post-frame callback — see `ChildShellScaffold`'s own copy
  /// of this method for the full rationale (Riverpod disallows modifying
  /// provider state mid-build; the `!=` guard makes this idempotent with the
  /// tap handler's own synchronous write below).
  void _syncActiveBranchIndexAfterBuild() {
    final index = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(activeChildBranchIndexProvider) != index) {
        ref.read(activeChildBranchIndexProvider.notifier).state = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        endParentOverrideAndReturnToPetRoom(ref, context);
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.parentNavy,
            // No GDD-specified indicator shade exists yet — derived from the
            // base tone rather than inventing an undocumented hex.
            indicatorColor: Color.lerp(AppColors.parentNavy, Colors.white, 0.15),
            iconTheme: const WidgetStatePropertyAll(
              IconThemeData(size: 24, color: Colors.white70),
            ),
            labelTextStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          child: NavigationBar(
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _destinations,
          ),
        ),
      ),
    );
  }

  /// `goBranch` and `activeChildBranchIndexProvider`'s write happen in the
  /// same synchronous handler, with no `await` between them (ADR-0014
  /// Decision §4's exact wiring pattern; same shape as
  /// `ChildShellScaffold._onDestinationSelected`).
  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    ref.read(activeChildBranchIndexProvider.notifier).state = index;
  }

  /// `ref.listenManual(bannerStateProvider.select((s) => s.displayKind))`'s
  /// callback (ADR-0015 Decision §4). Only fires on a KIND transition, so
  /// [previous] is only ever null on the very first call (riverpod's
  /// `listenManual` convention) — treated the same as `none` here, since
  /// [BannerState]'s own default is `unseenCount: 0, permissionDeclined:
  /// false`, i.e. `displayKind == none` at construction.
  void _syncMaterialBanner(BannerKind? previous, BannerKind next) {
    final messenger = ScaffoldMessenger.of(context);
    if (next == BannerKind.none) {
      messenger.hideCurrentMaterialBanner();
      return;
    }
    // Banner-slot conflict resolution (reminder<->fcm, GDD Edge Case 5 /
    // Core Rule 6) transitions directly between two non-`none` kinds with
    // no intervening `none`. `showMaterialBanner` while one is already
    // visible ENQUEUES it behind the current banner's exit animation
    // (verified against the installed Flutter 3.44.6
    // `scaffold.dart`'s `ScaffoldMessengerState.showMaterialBanner` doc
    // comment: "the given material banner will be added to a queue and
    // displayed after the earlier material banners have closed") — that
    // would show a dismiss-then-show animation, directly violating GDD's
    // "FCM banner thay thế NGAY tại cùng vị trí" (replaces immediately, same
    // position). `removeCurrentMaterialBanner()` clears the old banner with
    // no exit animation first, so the immediately-following
    // `showMaterialBanner` starts fresh rather than queuing.
    if (previous != null && previous != BannerKind.none) {
      messenger.removeCurrentMaterialBanner();
    }
    messenger.showMaterialBanner(_buildBanner(next));
  }

  /// GDD line 144 (Cloud White background, Lavender Soft accent, no
  /// elevation — see this file's class doc comment for why `elevation: 0`,
  /// the default, is correct and must not be "fixed"). [content] is a
  /// [Consumer] so `unseenCount`/`lastMessage` changes WITHIN the same
  /// [BannerKind] (the 2->3 coalescing case) update this already-shown
  /// banner's text in place, without this method or
  /// [_syncMaterialBanner] running again.
  MaterialBanner _buildBanner(BannerKind kind) {
    return MaterialBanner(
      backgroundColor: AppColors.cloudWhite,
      leading: const Icon(Icons.notifications_active, color: AppColors.lavenderSoft),
      content: GestureDetector(
        key: const Key('parentShellBannerTapTarget'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _handleBannerTap(kind),
        child: Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(bannerStateProvider);
            return Text(
              bannerDisplayText(ref, state, kind),
              style: const TextStyle(color: AppColors.primaryText),
            );
          },
        ),
      ),
      // `actions` is a required, non-empty parameter (an assert in
      // MaterialBanner's own constructor, ADR-0015 Decision §1) — an
      // explicit "Đóng" dismiss action satisfies GDD's "swipe hoặc tap"
      // dismiss wording via tap; swipe-to-dismiss is an optional
      // `Dismissible`-wrapper enhancement left out here (ADR-0015 Decision
      // §1's own explicit UX-judgment-call note), not a hard requirement.
      actions: [
        TextButton(
          key: const Key('parentShellBannerDismissButton'),
          onPressed: _handleBannerDismiss,
          style: TextButton.styleFrom(foregroundColor: AppColors.lavenderSoft),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  /// GDD Core Rule 6 — tap navigates to Tab Nhiệm vụ (branch index 0) only
  /// if [kind] is `fcm` and not already there; a `reminder` tap never
  /// navigates (the reminder only ever renders while Tab Nhiệm vụ is
  /// already the default/active tab on cold start — Core Rule 7 — and
  /// wiring a tap to the Settings-deep-link/re-prompt flow is Push
  /// Notification #9's permission-request territory, explicitly out of
  /// scope for this story). `kind` is the value captured when THIS banner
  /// was built, not re-derived from state after
  /// `bannerDismissedOrTapped()` has already run (which may have already
  /// changed `displayKind`).
  void _handleBannerTap(BannerKind kind) {
    ref.read(bannerActionsProvider).bannerDismissedOrTapped();
    if (kind == BannerKind.fcm && widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      ref.read(activeChildBranchIndexProvider.notifier).state = 0;
    }
  }

  /// Dismiss never navigates, for either [BannerKind] — GDD Core Rule 6 /
  /// Edge Case 5. Shares the exact same state transition as
  /// [_handleBannerTap] (`bannerDismissedOrTapped()`); the only difference
  /// is this navigation no-op.
  void _handleBannerDismiss() {
    ref.read(bannerActionsProvider).bannerDismissedOrTapped();
  }
}

/// ADR-0015 Decision §5 — display text derivation, widget-layer
/// responsibility, reusing already-loaded data (no new Firestore read).
/// `unseenCount == 1` resolves "[Tên bé] vừa hoàn thành [task]" by looking
/// up `state.lastMessage`'s `taskId`/`childId` (ADR-0010's payload
/// contract) against the SAME [familyPendingTasksProvider]/
/// [childProfilesProvider] snapshots Story 001's pending-list cards already
/// read. `unseenCount >= 2` always uses the fixed "N nhiệm vụ mới đang chờ"
/// string, never derived from message content. Falls back to "Có nhiệm vụ
/// mới cần duyệt" on a lookup miss (a low-stakes display-text race, not a
/// correctness-critical path per the ADR's own Risks section) — exposed
/// (not private) so the pure-reducer test file can exercise it directly
/// without pumping a widget tree.
String bannerDisplayText(WidgetRef ref, BannerState state, BannerKind kind) {
  if (kind == BannerKind.reminder) {
    // Push Notification #9 GDD's own ratified copy
    // (`design/gdd/push-notification.md`), reused verbatim rather than
    // reinvented here.
    return 'Bật thông báo để biết ngay khi con submit task →';
  }

  if (state.unseenCount >= 2) {
    return '${state.unseenCount} nhiệm vụ mới đang chờ';
  }

  final data = state.lastMessage?.data;
  final taskId = data?['taskId'] as String?;
  final childId = data?['childId'] as String?;
  if (taskId != null && childId != null) {
    final tasks = ref.watch(familyPendingTasksProvider).value ?? const <TaskModel>[];
    final children = ref.watch(childProfilesProvider).value ?? const <ChildProfile>[];

    TaskModel? task;
    for (final t in tasks) {
      if (t.id == taskId) {
        task = t;
        break;
      }
    }
    ChildProfile? child;
    for (final c in children) {
      if (c.childId == childId) {
        child = c;
        break;
      }
    }
    if (task != null && child != null) {
      return '${child.name} vừa hoàn thành ${task.title}';
    }
  }

  return 'Có nhiệm vụ mới cần duyệt';
}
