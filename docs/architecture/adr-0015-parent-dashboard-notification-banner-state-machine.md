# ADR-0015: Parent Dashboard Notification Banner State Machine

## Status
Accepted (2026-07-22 — flame-widget-specialist-validated at authoring against installed Flutter 3.44.6/riverpod 3.3.2 source; lean review mode, TD-ADR skipped per `production/review-mode.txt`)

## Date
2026-07-22

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 — pure Flutter widget layer, no Flame anywhere in this decision |
| **Domain** | UI / State Management (Riverpod state machine + `MaterialBanner`/`ScaffoldMessenger`) |
| **Knowledge Risk** | LOW-MEDIUM — `MaterialBanner`/`ScaffoldMessenger` internals were verified directly against the installed Flutter 3.44.6 SDK source (`/opt/homebrew/share/flutter`, `scaffold.dart`/`banner.dart`), not assumed from training data. `firebase_messaging.onMessage`/`getNotificationSettings()` were already verified by ADR-0010 against the actually-resolved `16.4.3`; this ADR does not re-derive that, only cites it. |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`; installed Flutter SDK source (`scaffold.dart`, `banner.dart`); installed `flutter_riverpod-3.3.2`/`riverpod-3.3.2` source (`consumer.dart`, confirmed `listenManual` exists — same method this codebase's `mood_event_bridge.dart` already uses); `design/gdd/parent-dashboard-ui.md` Core Rule 6, Edge Cases 4-5; `design/ux/parent-dashboard-ui.md` States & Variants; ADR-0010 (Accepted, payload contract); `src/lib/ui/parent_shell_scaffold.dart` (existing structural constraint); flame-widget-specialist validation (2026-07-22). |
| **Post-Cutoff APIs Used** | None new — `MaterialBanner`/`ScaffoldMessenger` and `ref.listenManual` are both pre-cutoff, stable Flutter/Riverpod APIs, and `firebase_messaging ^16.4.3`'s relevant surface (`onMessage`, `getNotificationSettings().authorizationStatus`) was already verified by ADR-0010. |
| **Verification Required** | None beyond what ADR-0010 already required (iOS TestFlight validation of the permission/Settings-deep-link path — that remains ADR-0010's concern, this ADR only consumes `authorizationStatus`, does not re-verify the permission request flow itself). |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0010 (Push Notification Delivery Architecture, Accepted) — this ADR consumes `FirebaseMessaging.onMessage`'s payload contract and the `AuthorizationStatus` check exactly as ADR-0010 §3/§4 defined them; it does not redefine either. |
| **Enables** | Parent Dashboard UI Story 004 (this ADR is that story's sole blocker). |
| **Blocks** | Parent Dashboard UI Story 004 only — no other epic depends on this ADR. |
| **Ordering Note** | ADR-0010 owns FCM *delivery* (server-side trigger, payload shape, permission request). This ADR owns everything downstream of `onMessage` firing on an already-foregrounded app: the banner's own display/defer/coalesce state machine and its Flutter rendering mechanism. Story 001 (Complete) reserved an empty layout slot inside `parent_dashboard_tasks_tab.dart` under the OLD assumption that the banner would render inline per-tab — this ADR's Decision §4 supersedes that assumption (see Migration Plan). |

## Context

### Problem Statement

`design/gdd/parent-dashboard-ui.md` Core Rule 6 and Edge Cases 4-5 specify a foreground FCM banner with real input-dependent branching — the GDD's own text flags this as the epic's only `[LOGIC]`-tier requirement, on par with Parent Approval (#11)'s button state machine. The behavior is unusually fully-specified already (including the exact "2 messages during a modal, then a 3rd arrives before dismiss" permutation), but nothing has formalized it into a concrete Riverpod state shape, a set of named transitions, or resolved how the banner physically renders given a real structural constraint discovered in this ADR's own drafting: `ParentShellScaffold` (Main Navigation Shell epic, Complete) has an existing regression test that depends on **no `Stack` widget existing** in its subtree, and the banner must render above BOTH tabs (GDD: "global overlay, Parent Shell scaffold level, không tab-specific"), not nested inside one tab's own body.

### Constraints
- **No `Stack` widget may be introduced in `ParentShellScaffold`'s subtree** — its own doc comment states this is a tested structural invariant from Main Navigation Shell Story 003 ("no floating chips" AC). Any banner-rendering approach that wraps `widget.navigationShell` in a `Stack` risks breaking that pre-existing test.
- **Session = process lifetime** (GDD, Core Rule 7) — no persistence; in-memory Riverpod state that resets naturally on cold start (a fresh `ProviderContainer`) is sufficient and correct; no `flutter_secure_storage`/Firestore write is needed for this ADR's state.
- **Manual dismiss only, no auto-dismiss timer** (GDD Tuning Knob, deliberate design choice).
- **Two independent modal call sites** need to defer the same shell-level banner: `create_custom_task_sheet.dart`'s `showCreateCustomTaskSheet` (Tab Nhiệm vụ) and `parent_dashboard_family_tab.dart`'s `showResetPinDialog` (Tab Gia đình) — both already-Complete files this ADR requires small, additive edits to.
- **Reuses ADR-0010's payload contract exactly** — `data.taskId`/`data.childId` (strings), `notification.title`/`notification.body` (pre-formatted server-side) — no new Cloud Function or payload field.

### Requirements
- A pure, testable state reducer covering every GDD Core Rule 6/Edge Case 4-5 transition (unseenCount increment, modal defer, coalesce/live-update, tap/dismiss reset, banner-slot conflict resolution with the permission reminder).
- A rendering mechanism that satisfies "global, not tab-specific" without a `Stack`.
- Explicit division of responsibility between the pure state machine (Logic-tier, unit-testable) and the widget layer (imperative `ScaffoldMessenger` calls, navigation) — matching this epic's own established "screen-scoped Riverpod state + a thin ConsumerWidget layer" convention (Story 001's `pendingCardStatusProvider`/`PendingCardStatus`).

## Decision

**1. `MaterialBanner` shown imperatively via `ScaffoldMessenger`, NOT a `Stack`-positioned custom widget.**

Verified directly against the installed Flutter 3.44.6 SDK source: `Scaffold` composes its `MaterialBanner` slot via `CustomMultiChildLayout`/`_ScaffoldLayout` (`scaffold.dart`), never a `Stack` — showing a banner via `ScaffoldMessenger.of(context).showMaterialBanner(...)` introduces **zero** `Stack` widgets anywhere, satisfying `ParentShellScaffold`'s existing "no Stack" structural test even more robustly than avoiding one manually. Since `ParentShellScaffold` hosts a single persistent `Scaffold` across `StatefulNavigationShell` branch switches (its own already-established IndexedStack-preservation pattern), `ScaffoldMessenger.of(context)` resolves to the same messenger regardless of which tab is active — the banner is genuinely shell-level and tab-independent, matching GDD Core Rule 6 exactly.

**Real, non-hypothetical gotcha to preserve, not "fix" later**: the default `elevation: 0` on `MaterialBanner` makes `Scaffold` **reflow its body content downward** (`extendBodyBehindMaterialBanner = elevation != 0.0`, confirmed in `scaffold.dart`) rather than floating the banner over the content. This is not a bug to patch with a nonzero elevation — it is *exactly* what GDD line 144 specifies: "slide-down + fade-in 200ms... không phải popup chặn màn hình" (not a screen-blocking popup). Do not add `elevation` to make it "float" — that would contradict the GDD's own explicit visual intent.

**GDD correction found during this ADR's drafting**: GDD line 144 says dismiss is via "swipe hoặc tap." `MaterialBanner` has no built-in swipe-to-dismiss gesture (confirmed: no `Dismissible`/swipe code anywhere in `banner.dart`) and `actions` is a required, non-empty parameter (an `assert` in the widget's own constructor). The implementing story MUST provide an explicit dismiss action (an "Đóng"/X `TextButton` in `actions`) to satisfy the non-empty-actions requirement — swipe-to-dismiss, if the team wants to preserve that promised interaction, requires wrapping the banner's `content` in the app's own `Dismissible`; this is a UX-tier implementation choice left to Story 004, not mandated by this ADR. Either way, "tap-to-dismiss via an explicit action" MUST exist; "swipe" is optional, contingent on Story 004's own UX judgment call, not a hard requirement this ADR imposes.

**2. Pure state machine — a `BannerState` reducer + a bound `BannerActions` class, following this epic's own `PendingCardStatus`/`pendingCardStatusProvider` shape.**

```dart
enum BannerKind { none, fcm, reminder }

@immutable
class BannerState {
  const BannerState({
    this.unseenCount = 0,
    this.lastMessage,
    this.isModalOpen = false,
    this.reminderConsumedThisSession = false,
    this.permissionDeclined = false,
  });

  final int unseenCount;
  final RemoteMessage? lastMessage; // for the single-message (unseenCount==1) display text
  final bool isModalOpen;
  final bool reminderConsumedThisSession;
  final bool permissionDeclined; // resolved once via FirebaseMessaging.instance.getNotificationSettings()

  /// Pure derivation — NOT stored. This single getter is the entire
  /// "what does the parent see right now" decision, and is what every
  /// GDD Acceptance Criterion in this story ultimately asserts against.
  BannerKind get displayKind {
    if (isModalOpen) return BannerKind.none;               // Edge Case 4 — deferred
    if (unseenCount > 0) return BannerKind.fcm;             // Core Rule 6 — FCM always wins over reminder
    if (permissionDeclined && !reminderConsumedThisSession) {
      return BannerKind.reminder;
    }
    return BannerKind.none;
  }

  BannerState copyWith({...}); // standard, all fields optional
}

final bannerStateProvider = StateProvider<BannerState>((ref) => const BannerState());

class BannerActions {
  BannerActions(this._ref);
  final Ref _ref;

  void permissionStatusResolved({required bool declined}) =>
      _patch((s) => s.copyWith(permissionDeclined: declined));

  void modalOpened() => _patch((s) => s.copyWith(isModalOpen: true));
  void modalClosed() => _patch((s) => s.copyWith(isModalOpen: false));

  /// The ONLY place `unseenCount` increments. Banner-slot conflict
  /// resolution (GDD's explicit "reminder đang hiện, FCM đến → reminder
  /// coi như đã được thấy" case) is evaluated against state BEFORE this
  /// message is applied — only suppresses the reminder if it was the
  /// banner ACTUALLY being displayed at the moment of arrival, per the
  /// GDD's literal "GIVEN reminder đang hiện" wording (not a blanket
  /// "any FCM this session permanently voids the reminder" rule).
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

  /// Shared by BOTH tap and swipe-dismiss — GDD makes no state-transition
  /// distinction between them, only a navigation-side-effect distinction
  /// (tap navigates if not already on Tab Nhiệm vụ; dismiss never
  /// navigates). Navigation itself is the WIDGET layer's job (needs
  /// BuildContext/GoRouter) — this method is state-only.
  void bannerDismissedOrTapped() {
    final current = _ref.read(bannerStateProvider);
    switch (current.displayKind) {
      case BannerKind.fcm:
        _ref.read(bannerStateProvider.notifier).state =
            current.copyWith(unseenCount: 0);
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
```

This reducer is a pure function of `BannerState` (no `BuildContext`, no Firestore, no async) — directly unit-testable per the story's own BLOCKING Logic-tier Test Evidence requirement, by feeding a `BannerState` in and asserting the resulting `BannerState`/`displayKind` out. Every GDD Acceptance Criterion (banner appears, defers during modal, coalesces, live-updates, banner-slot conflict) reduces to a `messageReceived`/`modalOpened`/`modalClosed`/`bannerDismissedOrTapped` sequence and a `displayKind`/`unseenCount` assertion.

**3. Modal-open signal: each modal explicitly notifies the provider (confirmed with user) — not a `NavigatorObserver`.**

`create_custom_task_sheet.dart`'s `showCreateCustomTaskSheet` and `parent_dashboard_family_tab.dart`'s `showResetPinDialog` are each wrapped to call `ref.read(bannerActionsProvider).modalOpened()` immediately before `showDialog`/`showModalBottomSheet`, and `.modalClosed()` immediately after the awaited call returns (in a `finally`, so a thrown error during the modal's own lifecycle still clears the defer state). This is explicit and minimal — two small, additive edits to already-Complete files, no new cross-cutting `NavigatorObserver` concern, consistent with this codebase's general preference for explicit DI over implicit framework-wide observers.

**4. Subscription lifecycle and rendering side-effect both live in `_ParentShellScaffoldState`.**

```dart
// initState:
_onMessageSub = FirebaseMessaging.onMessage.listen(
  (message) => ref.read(bannerActionsProvider).messageReceived(message),
);
FirebaseMessaging.instance.getNotificationSettings().then((settings) {
  if (!mounted) return;
  ref.read(bannerActionsProvider).permissionStatusResolved(
    declined: settings.authorizationStatus == AuthorizationStatus.denied,
  );
});
ref.listenManual<BannerKind>(
  bannerStateProvider.select((s) => s.displayKind),
  (previous, next) => _syncMaterialBanner(next),
);

// dispose:
_onMessageSub.cancel();
```

`ref.listenManual` (not `ref.listen` inside `build`) is required here for the same reason `mood_event_bridge.dart` already established in this codebase: a one-time `initState` subscription to an imperative side effect, not a per-build declarative watch. Confirmed present in the actually-pinned `flutter_riverpod 3.3.2` (`consumer.dart`), the same method this codebase's own `MoodEventBridge` already uses.

**5. Display text derivation is the widget layer's job, reusing already-loaded data — no new Firestore read.**

GDD Core Rule 6 wants "[Tên bé] vừa hoàn thành [task]" for `unseenCount == 1` — a format distinct from ADR-0010's own `notification.title`/`.body` (which are tray-notification-styled, with an emoji and separate title/body). Rather than adding a new Firestore lookup keyed by `message.data['taskId']`/`['childId']`, `_syncMaterialBanner` resolves the child name and task title by looking the arriving task up in the SAME `familyPendingTasksProvider`/`childProfilesProvider` data Story 001 already merges for the pending-list cards (the task that triggered this push should already be present in that live snapshot by the time `onMessage` fires). Falls back to a generic "Có nhiệm vụ mới cần duyệt" string if the lookup momentarily misses (a low-stakes display-text race, not a correctness-critical path — the underlying `unseenCount`/`displayKind` state is unaffected either way). For `unseenCount >= 2`, the text is the GDD's fixed "N nhiệm vụ mới đang chờ" — never derived from `lastMessage`'s content.

**6. `ParentDashboardTasksTab`'s reserved banner slot (Story 001) is superseded, not reused.**

Story 001 reserved an empty `SizedBox.shrink()` inside its own `Column`, under the assumption the banner would render inline per-tab. Since this ADR's `MaterialBanner`/`ScaffoldMessenger` approach renders at the `ParentShellScaffold` level (outside any single tab's widget tree), that reserved slot becomes dead code. Story 004 should remove it as part of implementing this ADR (small, in-scope cleanup — the direct consequence of this ADR's resolved architecture, not scope creep).

### Architecture Diagram
```
FirebaseMessaging.onMessage (ADR-0010's payload) ──┐
                                                     ▼
              _ParentShellScaffoldState.initState()
                 .listen(...) → bannerActionsProvider.messageReceived(message)
                                                     │
create_custom_task_sheet.dart ──┐                   │
  showCreateCustomTaskSheet()   ├─ modalOpened()/modalClosed() ─┤
parent_dashboard_family_tab.dart┘   (explicit, wrapped calls)   │
                                                     ▼
                                    bannerStateProvider (BannerState)
                                    displayKind = f(unseenCount, isModalOpen,
                                                     permissionDeclined,
                                                     reminderConsumedThisSession)
                                                     │
                                 ref.listenManual(displayKind) in initState
                                                     ▼
                       ScaffoldMessenger.of(context).showMaterialBanner(...)
                       / .hideCurrentMaterialBanner()
                       (Scaffold's own CustomMultiChildLayout slot — NO Stack)
                                                     │
                              tap/dismiss action → bannerDismissedOrTapped()
                              (+ widget-layer navigation if tapped AND not
                               already on Tab Nhiệm vụ — GoRouter, not state)
```

### Key Interfaces
```dart
enum BannerKind { none, fcm, reminder }

class BannerState {
  const BannerState({
    this.unseenCount = 0, this.lastMessage, this.isModalOpen = false,
    this.reminderConsumedThisSession = false, this.permissionDeclined = false,
  });
  final int unseenCount;
  final RemoteMessage? lastMessage;
  final bool isModalOpen;
  final bool reminderConsumedThisSession;
  final bool permissionDeclined;
  BannerKind get displayKind; // pure, see Decision §2
}

final bannerStateProvider = StateProvider<BannerState>((ref) => const BannerState());

class BannerActions {
  void permissionStatusResolved({required bool declined});
  void modalOpened();
  void modalClosed();
  void messageReceived(RemoteMessage message);
  void bannerDismissedOrTapped();
}
final bannerActionsProvider = Provider<BannerActions>((ref) => BannerActions(ref));
```

## Alternatives Considered

### Alternative A (chosen): `MaterialBanner` via `ScaffoldMessenger`, pure `BannerState` reducer, explicit modal-notify
- **Pros**: Zero `Stack` widgets (verified against Scaffold's own internals); genuinely shell-level/tab-independent; state machine is a pure, directly unit-testable reducer; explicit modal signaling matches this codebase's DI-over-magic convention; reuses ADR-0010's payload and Story 001's already-loaded task/child data.
- **Cons**: Two small edits required to already-Complete files (the two modal call sites).
- **Rejection Reason**: N/A — chosen.

### Alternative B: `Stack`-positioned custom banner widget inside `ParentShellScaffold`
- **Description**: Wrap `widget.navigationShell` in a `Stack`, position a custom banner widget at the top.
- **Pros**: Full manual control over animation/positioning.
- **Cons**: Directly violates `ParentShellScaffold`'s existing "no Stack" structural invariant, risking a regression in an already-Complete, already-tested epic (Main Navigation Shell Story 003); reinvents what `MaterialBanner` already provides for free.
- **Rejection Reason**: Unnecessary risk to a pre-existing test for zero architectural benefit — `MaterialBanner` already does everything the GDD asks for.

### Alternative C: `NavigatorObserver`-based automatic modal detection
- **Description**: A global `NavigatorObserver` detects modal route push/pop automatically, no per-call-site opt-in.
- **Pros**: New modals added later wouldn't need to remember to wire in.
- **Cons**: Adds a new cross-cutting concern; harder to scope correctly ("which modals count as Parent-Shell-relevant" isn't structurally obvious from a route alone); this codebase has exactly 2 known call sites today, both cheap to touch explicitly.
- **Rejection Reason**: User's own explicit choice (confirmed via `AskUserQuestion` during this ADR's drafting) — over-engineered for the current known scope; can be revisited if a third modal appears.

## Consequences

### Positive
- The epic's only `[LOGIC]`-tier requirement gets a precise, directly-testable state machine, closing the last real design gap in Parent Dashboard UI.
- Resolves a genuine structural conflict (banner needs to be shell-level; shell has a tested "no Stack" invariant) using a built-in Flutter mechanism rather than a workaround.
- No new Firestore reads, no new Cloud Function, no changes to ADR-0010's payload contract.

### Negative
- Two already-Complete files (`create_custom_task_sheet.dart`, `parent_dashboard_family_tab.dart`) need small additive edits — minor scope bleed into prior stories' files, same class of cross-story touch already established by this session's Task Library post-closure fix and Story 001's "Chọn bé" absorption.
- Story 001's reserved banner slot becomes dead code needing removal (Decision §6) — a small cleanup, not a functional regression.
- `MaterialBanner`'s content-reflow-not-overlay behavior (Decision §1) is correct per the GDD but may surprise a future maintainer expecting a floating overlay; documented explicitly to prevent a well-intentioned but wrong "fix."

### Risks
- **GDD's "swipe hoặc tap" dismiss wording doesn't match `MaterialBanner`'s native capability** (no built-in swipe gesture). *Mitigation*: Decision §1 explicitly requires an action-button dismiss at minimum; swipe is an optional `Dismissible`-wrapper addition left to Story 004's UX judgment, not silently dropped.
- **Display-text lookup race** (arriving task not yet in `familyPendingTasksProvider`'s snapshot when `onMessage` fires). *Mitigation*: Decision §5's explicit fallback string; does not affect `unseenCount`/`displayKind` correctness, only cosmetic text for one edge case.
- **Two modal call sites must both remember to call `modalOpened`/`modalClosed`** — a manual convention, not enforced by the type system. *Mitigation*: explicit code comments at both call sites (Story 004's responsibility) referencing this ADR; low risk since there are only 2 sites and both are edited in the same story.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| parent-dashboard-ui.md | Core Rule 6 — banner appears on `onMessage`, live-updates in place, coalesces at `unseenCount >= 2`, resets only on tap/dismiss | Decision §2 (`BannerState`/`BannerActions`), Decision §4 (subscription wiring) |
| parent-dashboard-ui.md | Edge Case 4 — banner deferred during any modal | Decision §2 (`isModalOpen` in `displayKind`), Decision §3 (explicit modal signaling) |
| parent-dashboard-ui.md | Edge Case 5 — coalescing, including the 3rd-message-during-open-banner permutation | Decision §2's `messageReceived` — a pure increment + re-derive, no special-casing needed for the 3-message case since `displayKind`/text are always derived fresh from `unseenCount` |
| parent-dashboard-ui.md | Banner-slot conflict resolution (reminder → FCM replaces, reminder "seen") | Decision §2's `messageReceived` reminder-suppression logic |
| parent-dashboard-ui.md | "Global overlay, Parent Shell scaffold level, không tab-specific" | Decision §1 (`ScaffoldMessenger` at `ParentShellScaffold`'s persistent `Scaffold`) |
| parent-dashboard-ui.md | Session = process lifetime (reminder shown once) | Decision §2 (`reminderConsumedThisSession`, plain in-memory Riverpod state, no persistence) |

## Performance Implications
- **CPU**: Trivial — a handful of Riverpod state reads/writes per FCM message or modal open/close, no polling, no timers.
- **Memory**: Negligible — `BannerState` holds at most one `RemoteMessage` reference at a time.
- **Load Time**: N/A.
- **Network**: None new — reuses ADR-0010's existing FCM delivery, no additional reads/writes.

## Migration Plan
Greenfield for the state machine itself. Two small edits to already-Complete files:
1. `create_custom_task_sheet.dart`'s `showCreateCustomTaskSheet` — wrap the existing `showModalBottomSheet` call with `modalOpened()`/`modalClosed()` (try/finally).
2. `parent_dashboard_family_tab.dart`'s `showResetPinDialog` — same wrapping around its existing `showDialog` call.
3. `parent_dashboard_tasks_tab.dart` — remove the now-dead reserved `SizedBox.shrink()` banner slot (Decision §6).
4. `parent_shell_scaffold.dart` — add the `onMessage` subscription, permission-status resolution, and `ref.listenManual`-driven `ScaffoldMessenger` sync described in Decision §4, plus lifecycle cleanup in `dispose()`.

No GDD text changes required beyond the swipe-dismiss note already captured in Decision §1/Risks (informational, not a contradiction requiring a GDD edit — the GDD's intent, "manual dismiss only," is fully satisfied by an action-button dismiss; "swipe" was descriptive, not a hard requirement, and Story 004 may add it via `Dismissible` at its own discretion without needing this ADR revised).

## Validation Criteria
- Unit (Logic-tier, BLOCKING per `tests/unit/parent-dashboard-ui/fcm_banner_state_machine_test.dart`): every `BannerActions` method tested as a pure reducer — `messageReceived` increments/coalesces correctly including the 3-message-during-modal permutation; `modalOpened`/`modalClosed` correctly gate `displayKind`; `bannerDismissedOrTapped` resets the correct field depending on `displayKind` at call time; the banner-slot conflict (`reminderWasShowing` → `messageReceived` sets `reminderConsumedThisSession`) is a dedicated test case, not incidental coverage.
- Integration: `ParentShellScaffold`'s `ScaffoldMessenger` genuinely shows/hides/updates a `MaterialBanner` in response to `bannerStateProvider` changes, across a real tab switch (banner persists visually correct after switching Nhiệm vụ → Gia đình → back).
- Integration: the two modal call sites correctly defer an in-flight banner and resume it after the modal closes.

## Related Decisions
- ADR-0010 (Push Notification Delivery Architecture) — owns FCM delivery/payload/permission-request; this ADR is its direct downstream consumer for the foreground case ADR-0010 §4 explicitly deferred to "Parent Dashboard UI (#21) ADR (upcoming)."
- ADR-0004 (Flutter-Flame Event Bridge) — NOT applicable here; this banner never touches `GameEventBus`/Flame, confirmed during drafting.
- `design/gdd/parent-dashboard-ui.md` Core Rule 6, Edge Cases 4-5 — the ratified design this ADR formalizes.
- `design/ux/parent-dashboard-ui.md` States & Variants — visual/animation spec (200ms slide-down, 150ms fade-out dismiss) this ADR's Decision §1 confirms is achievable with the chosen mechanism.
