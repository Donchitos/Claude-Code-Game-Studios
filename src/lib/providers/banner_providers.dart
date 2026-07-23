import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `StateProvider` moved to the legacy export in riverpod 3.x — same fix
// already applied throughout this codebase (`auth_providers.dart`,
// `router_provider.dart`, `parent_dashboard_tasks_tab.dart`); required here
// for [bannerStateProvider].
import 'package:flutter_riverpod/legacy.dart';

/// Parent Dashboard UI Story 004 (TR-parentdash-002) — the FCM foreground
/// banner defer/coalesce state machine. Implements ADR-0015 Decision §2
/// verbatim (do not redesign the shape — see this story's own Out of Scope
/// section). One-domain-per-provider-file convention, matching
/// `parent_approval_providers.dart`.
///
/// This is the epic's only `[LOGIC]`-tier requirement (GDD Core Rule 6,
/// Edge Cases 4-5) — [BannerState]/[BannerActions] is a pure reducer with no
/// `BuildContext`, no Firestore, no async, directly unit-testable per
/// `tests/unit/parent-dashboard-ui/fcm_banner_state_machine_test.dart`
/// (BLOCKING). The widget-layer rendering/navigation side effects that
/// consume this state live in `parent_shell_scaffold.dart`
/// (ADR-0015 Decision §4).

/// What the parent currently sees, ranked by [BannerState.displayKind]'s own
/// precedence (`fcm` always wins over `reminder`; both yield to a deferring
/// modal). `none` covers both "nothing to show" and "deferred by a modal."
enum BannerKind { none, fcm, reminder }

/// Pure, immutable state for the shared Parent Shell banner slot
/// (ADR-0015 Decision §2). `unseenCount`/`lastMessage` drive the FCM
/// banner's text (Decision §5); `isModalOpen` implements Edge Case 4's
/// defer; `reminderConsumedThisSession`/`permissionDeclined` implement Core
/// Rule 7's once-per-session reminder and the banner-slot conflict
/// resolution (Edge Case 5's own "reminder coi như đã được thấy" rule).
///
/// Session = process lifetime (GDD Core Rule 7) — a fresh `BannerState()`
/// (the default constructed by [bannerStateProvider]) only ever happens on a
/// real cold start (a new `ProviderContainer`), never on an
/// `AppLifecycleState.resumed` resume. No persistence is needed or used.
@immutable
class BannerState {
  const BannerState({
    this.unseenCount = 0,
    this.lastMessage,
    this.isModalOpen = false,
    this.reminderConsumedThisSession = false,
    this.permissionDeclined = false,
  });

  /// Incremented once per [BannerActions.messageReceived] call, reset to 0
  /// only by [BannerActions.bannerDismissedOrTapped] while an `fcm` banner
  /// is showing (GDD Edge Case 5 — "chỉ reset khi tap hoặc dismiss," never
  /// by merely viewing the tab).
  final int unseenCount;

  /// The most recently received message — used ONLY to derive the
  /// `unseenCount == 1` display text ("[Tên bé] vừa hoàn thành [task]"),
  /// never for `unseenCount >= 2` (ADR-0015 Decision §5). Not read by this
  /// pure reducer itself; carried through purely for the widget layer.
  final RemoteMessage? lastMessage;

  /// True while `showCreateCustomTaskSheet`/`showResetPinDialog` (the two
  /// known modal call sites, ADR-0015 Decision §3) has an in-flight modal
  /// open. Takes precedence over every other field in [displayKind] — GDD
  /// Edge Case 4.
  final bool isModalOpen;

  /// True once the reminder banner has either been shown-then-replaced by
  /// an FCM banner (banner-slot conflict resolution) or explicitly
  /// dismissed/tapped this session — [displayKind] never returns to
  /// `reminder` again while this is true, for the lifetime of this
  /// [BannerState] lineage (GDD Core Rule 7 / Edge Case 5).
  final bool reminderConsumedThisSession;

  /// Resolved once via `FirebaseMessaging.instance.getNotificationSettings()`
  /// (ADR-0010's contract) — true iff `AuthorizationStatus.denied`. Starts
  /// `false` (not yet resolved / not declined) until
  /// [BannerActions.permissionStatusResolved] writes the real value.
  final bool permissionDeclined;

  /// Pure derivation — NOT stored. This single getter is the entire "what
  /// does the parent see right now" decision, and is what every GDD
  /// Acceptance Criterion in this story ultimately asserts against
  /// (ADR-0015 Decision §2 — copied verbatim, do not alter the precedence
  /// order).
  BannerKind get displayKind {
    if (isModalOpen) return BannerKind.none; // Edge Case 4 — deferred
    if (unseenCount > 0) return BannerKind.fcm; // Core Rule 6 — FCM always wins over reminder
    if (permissionDeclined && !reminderConsumedThisSession) {
      return BannerKind.reminder;
    }
    return BannerKind.none;
  }

  BannerState copyWith({
    int? unseenCount,
    RemoteMessage? lastMessage,
    bool? isModalOpen,
    bool? reminderConsumedThisSession,
    bool? permissionDeclined,
  }) {
    return BannerState(
      unseenCount: unseenCount ?? this.unseenCount,
      lastMessage: lastMessage ?? this.lastMessage,
      isModalOpen: isModalOpen ?? this.isModalOpen,
      reminderConsumedThisSession:
          reminderConsumedThisSession ?? this.reminderConsumedThisSession,
      permissionDeclined: permissionDeclined ?? this.permissionDeclined,
    );
  }
}

/// Screen-scoped (Parent Shell level) — NOT a global singleton (this
/// story's own Control Manifest rule, ADR-0015 Decision §2). A plain
/// `StateProvider` is sufficient: the reducer logic itself lives in
/// [BannerActions], not in a `Notifier` subclass, matching this epic's
/// established `pendingCardStatusProvider` shape.
final bannerStateProvider = StateProvider<BannerState>((ref) => const BannerState());

/// Bound state-mutation methods for [bannerStateProvider] — exposed as a
/// bound object rather than bare top-level functions for the same
/// `Ref`/`WidgetRef` unification reason as `ParentOverrideActions` et al.
/// (`auth_providers.dart`). Every method here is a synchronous, pure state
/// transition; none of them touch `BuildContext`, Firestore, or navigation
/// (ADR-0015 Decision §2/§4 — navigation is the widget layer's job).
class BannerActions {
  BannerActions(this._ref);

  final Ref _ref;

  /// Resolved once in `_ParentShellScaffoldState.initState()` via
  /// `FirebaseMessaging.instance.getNotificationSettings()`
  /// (ADR-0010's contract).
  void permissionStatusResolved({required bool declined}) =>
      _patch((s) => s.copyWith(permissionDeclined: declined));

  /// Called immediately before `showModalBottomSheet`/`showDialog` at the
  /// two known modal call sites (ADR-0015 Decision §3).
  void modalOpened() => _patch((s) => s.copyWith(isModalOpen: true));

  /// Called in a `finally` immediately after the awaited modal call
  /// returns — so a thrown error during the modal's own lifecycle still
  /// clears the defer state (ADR-0015 Decision §3).
  void modalClosed() => _patch((s) => s.copyWith(isModalOpen: false));

  /// The ONLY place `unseenCount` increments. Banner-slot conflict
  /// resolution (GDD's explicit "reminder đang hiện, FCM đến → reminder
  /// coi như đã được thấy" case) is evaluated against state BEFORE this
  /// message is applied — only suppresses the reminder if it was the
  /// banner ACTUALLY being displayed at the moment of arrival, per the
  /// GDD's literal "GIVEN reminder đang hiện" wording (not a blanket "any
  /// FCM this session permanently voids the reminder" rule).
  void messageReceived(RemoteMessage message) {
    final current = _ref.read(bannerStateProvider);
    final reminderWasShowing = current.displayKind == BannerKind.reminder;
    _ref.read(bannerStateProvider.notifier).state = current.copyWith(
      unseenCount: current.unseenCount + 1,
      lastMessage: message,
      reminderConsumedThisSession:
          current.reminderConsumedThisSession || reminderWasShowing,
    );
  }

  /// Shared by BOTH tap and swipe/action-dismiss — GDD makes no
  /// state-transition distinction between them, only a navigation
  /// side-effect distinction (tap navigates if not already on Tab Nhiệm
  /// vụ; dismiss never navigates). Navigation itself is the WIDGET layer's
  /// job (needs `BuildContext`/`GoRouter`) — this method is state-only.
  void bannerDismissedOrTapped() {
    final current = _ref.read(bannerStateProvider);
    switch (current.displayKind) {
      case BannerKind.fcm:
        _ref.read(bannerStateProvider.notifier).state = current.copyWith(unseenCount: 0);
      case BannerKind.reminder:
        _ref.read(bannerStateProvider.notifier).state =
            current.copyWith(reminderConsumedThisSession: true);
      case BannerKind.none:
        break; // no-op — nothing currently showing to dismiss
    }
  }

  void _patch(BannerState Function(BannerState) fn) {
    _ref.read(bannerStateProvider.notifier).state = fn(_ref.read(bannerStateProvider));
  }
}

final bannerActionsProvider = Provider<BannerActions>((ref) => BannerActions(ref));
