# ADR-0014: Navigation Shell & Route Guard Architecture

## Status
Accepted

## Date
2026-07-18

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / go_router 17.3.0 |
| **Domain** | Navigation |
| **Knowledge Risk** | HIGH — `go_router 17.3.0` is far post-LLM-cutoff (training data covers roughly the 13.x/14.x API shape). Every API this ADR depends on was read directly from the installed package source (`~/.pub-cache/hosted/pub.dev/go_router-17.3.0`) and the pinned Flutter SDK source (`~/fvm/versions/3.44.4`), not assumed from training data. |
| **References Consulted** | `go_router-17.3.0/lib/src/route.dart` (`StatefulShellRoute`, `StatefulNavigationShell.goBranch`), `flutter/lib/src/widgets/pop_scope.dart` (Flutter 3.44.4, pinned), `docs/engine-reference/flutter-flame/deprecated-apis.md`, `docs/architecture/adr-0002-auth-pin-security-architecture.md`, `docs/registry/architecture.yaml` |
| **Post-Cutoff APIs Used** | `StatefulShellRoute({required branches, redirect, builder, pageBuilder, required navigatorContainerBuilder, ...})` and `StatefulNavigationShell.goBranch(int index, {bool initialLocation = false})` — both constructor/method shapes verified directly against 17.3.0 source, matching the GDD's own assumptions exactly, no drift found. `PopScope<T>({required child, canPop, onPopInvokedWithResult, onPopInvoked (deprecated)})` — verified against the pinned Flutter 3.44.4 SDK source; `WillPopScope` was removed in 3.22 (`deprecated-apis.md`) and must not be used. |
| **Verification Required** | None beyond what's already verified above — both API surfaces were read from installed source directly in this ADR's own authoring pass, not deferred to implementation time. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Auth & PIN Security Architecture, Accepted) — `sessionStateProvider`'s 4-state contract. This ADR is a pure **consumer**: the architecture registry (`docs/registry/architecture.yaml`) already locks `sessionStateProvider` as `write_access: auth-account-only` and explicitly lists `main-navigation-shell` as a referencer under "route guard reads it, does not re-derive" — this ADR does not renegotiate that boundary. |
| **Enables** | Parent Dashboard UI (#21) epic — currently fully Blocked on this ADR/epic existing (found during `/dev-story` on its Story 001, 2026-07-18). Also enables Pet Room Screen UI (#18), Task Management UI (#19), Shop & Reward UI (#20) whenever those epics are created — all four Presentation-layer systems assume this shell hosts their routes. |
| **Blocks** | Any story in the Main Navigation Shell epic; transitively, all of Parent Dashboard UI's stories (001–003; Story 004 has its own separate ADR blocker). |
| **Ordering Note** | Must be Accepted before `/create-stories main-navigation-shell` can produce unblocked stories. Registers `activeChildBranchIndexProvider` as new state this ADR (not Task Management UI or any other system) owns — TR-navshell-003's own requirement. |

## Context

### Problem Statement

Every UI epic in this project (Parent Dashboard UI, and eventually Pet Room, Task Management, Shop & Reward) assumes it renders inside a working `GoRouter` shell that reads `sessionStateProvider` and shows the correct actor's navigation tree. That shell does not exist — `src/lib/providers/router_provider.dart` currently has only flat placeholder routes (a single `/parent-dashboard` route rendering a bare placeholder screen), discovered as a hard blocker while implementing Parent Dashboard UI's Story 001. This ADR defines the real routing architecture: a root `GoRouter` with session-state-driven redirects, two `StatefulShellRoute` trees (Child: 3 tabs: Pet Room/Tasks/Shop; Parent: 2 tabs: Dashboard/Gia đình) that preserve branch state across tab switches (required so Pet Room's Flame game loop survives navigating away and back), and the Parent Override mechanism that lets a parent view the Parent Shell without disposing the child's session underneath.

### Constraints

- **`sessionStateProvider` is read-only here** — owned and derived exclusively by `auth-account` (ADR-0002); this ADR must never re-derive session state from `authStateProvider`/`activeChildProvider`/`parentOverrideProvider` directly.
- **`GoRouterRefreshStream` does not exist** in `go_router ^17.3.0` (removed upstream in v5.0.0, confirmed absent from `lib/` — ADR-0002's own 2026-07-15 correction). The refresh bridge must be `ref.listen(sessionStateProvider, (_, __) => router.refresh())`, matching the pattern ADR-0002's Story 003 already implemented for its own routing needs.
- **Pet Room's Flame game loop must survive tab switches** (GDD AC-5) — this requires `StatefulShellRoute`'s branch-preservation behavior (branches are never disposed on sibling-branch switch), not plain `GoRoute` navigation, which would rebuild/dispose the widget tree.
- **Non-dismissible full-screen ceremony overlays** (e.g. a future Shop & Reward Chest Open) require **root-navigator** push (`Navigator.of(context, rootNavigator: true).push(...)`), not branch-scoped push — otherwise the bottom nav bar (living in the Scaffold, outside the branch Navigator) stays visible/tappable during a supposedly-non-dismissible overlay (GDD Core Rule 1's explicit correction).
- **`WillPopScope` is deprecated and removed** (Flutter 3.22+) — back-button handling must use `PopScope.onPopInvokedWithResult`, not the also-deprecated `onPopInvoked`.
- **Route path correction** (found during this epic's `/ux-review` pass, 2026-07-18): the GDD's own Route Map and both UX specs originally used `/child-selector`; the already-built, already-tested Auth & Account code defines `AppRoutes.selectChild = '/select-child'`. This ADR uses `/select-child` — the already-shipped path — not the GDD's original literal text.

### Requirements

- Root `GoRouter` with a top-level `redirect` implementing the 4-state guard: `unauthenticated → /login`, `parentAuthed → /select-child`, `childSelected → allow /child/*, default /child/pet-room`, `parentView → allow /parent/*, default /parent/dashboard`.
- Child branch: `StatefulShellRoute` with 3 `StatefulShellBranch`es (`/child/pet-room`, `/child/tasks` with `/child/tasks/new` as a nested sub-route within that branch, `/child/shop`).
- Parent branch: a separate `StatefulShellRoute` with 2 `StatefulShellBranch`es (`/parent/dashboard`, `/parent/family`).
- `activeChildBranchIndexProvider`: a new `StateProvider<int>` this ADR defines and this system owns, written by each bottom-nav bar's `onTap` alongside the `goBranch(index)` call, read by other screens needing "am I still the active tab" (e.g. Task Management UI's future interrupt-detection).
- Parent Override: `parentOverrideProvider = true` on long-press+password-confirm navigates to `/parent/dashboard` without disposing the child branch underneath; override-exit returns directly to `/child/pet-room` with no re-PIN.
- Back-button behavior distinct per Core Rule 8: Child tab roots show a confirm dialog; Parent tab roots (not in override) exit directly; Parent tab roots *in override* return to the child session instead of exiting.

## Decision

**1. Single root `GoRouter` with a top-level `redirect` callback implementing the full 4-state guard**, refreshed via the `ref.listen` bridge (not `GoRouterRefreshStream`, which doesn't exist):

```dart
final routerProvider = Provider<GoRouter>((ref) {
  // Bridges a plain Riverpod Provider (not Listenable) to GoRouter's
  // refreshListenable requirement. GoRouterRefreshStream does not exist in
  // go_router ^17.3.0 (ADR-0002's own correction) — this is the only pattern
  // that works directly against sessionStateProvider without extra plumbing.
  final refreshNotifier = ValueNotifier<int>(0);
  // MUST be ref.listen, never ref.watch — watching sessionStateProvider here
  // would rebuild/recreate this entire Provider<GoRouter> (and therefore the
  // GoRouter instance) on every session-state change, tearing down BOTH
  // StatefulShellRoute trees and destroying the exact branch-preservation
  // guarantee (and Pet Room's FlameGame) this ADR exists to protect. This is
  // the single easiest way to silently break AC-5 during implementation
  // (found in engine-specialist validation, 2026-07-18).
  ref.listen(sessionStateProvider, (_, __) => refreshNotifier.value++);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final sessionState = ref.read(sessionStateProvider);
      final location = state.matchedLocation;
      switch (sessionState) {
        case SessionState.unauthenticated:
          return location == AppRoutes.login ? null : AppRoutes.login;
        case SessionState.parentAuthed:
          return location == AppRoutes.selectChild ? null : AppRoutes.selectChild;
        case SessionState.childSelected:
          return location.startsWith('/child/') ? null : AppRoutes.childPetRoom;
        case SessionState.parentView:
          return location.startsWith('/parent/') ? null : AppRoutes.parentDashboard;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.selectChild, builder: (_, __) => const ChildProfileSelectionScreen()),
      GoRoute(path: AppRoutes.pinEntry, builder: (_, __) => const PinEntryScreen()),
      childShellRoute,   // StatefulShellRoute, see §2
      parentShellRoute,  // StatefulShellRoute, see §3
    ],
  );
});
```

Route path constants updated in `AppRoutes` (Migration Plan §, below) — `selectChild` stays `/select-child` (already correct in code), `parentDashboard` moves from the current flat `/parent-dashboard` to `/parent/dashboard`, and new constants are added: `parentFamily = '/parent/family'`, `childPetRoom = '/child/pet-room'`, `childTasks = '/child/tasks'`, `childTasksNew = '/child/tasks/new'`, `childShop = '/child/shop'`.

**2. Child branch — `StatefulShellRoute` with 3 branches, preserving Pet Room's Flame state across tab switches:**

```dart
final childShellRoute = StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => ChildShellScaffold(
    navigationShell: navigationShell,
  ),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: AppRoutes.childPetRoom, builder: (_, __) => const PetRoomScreen()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(
        path: AppRoutes.childTasks,
        builder: (_, __) => const TaskManagementScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, __) => const NewTaskScreen()), // → /child/tasks/new
        ],
      ),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: AppRoutes.childShop, builder: (_, __) => const ShopScreen()),
    ]),
  ],
);
```

`ChildShellScaffold` hosts `navigationShell` directly as the `Scaffold.body`. `StatefulShellRoute.indexedStack`'s container wraps every inactive branch in `Offstage(offstage: true, child: TickerMode(enabled: false, child: ...))` — this mutes tickers created via `TickerProviderStateMixin`/`SingleTickerProviderStateMixin`, but **Flame's `GameLoop` drives itself via a raw `Ticker(_tick)` constructed directly, bypassing `TickerProvider`/`TickerMode` entirely** (verified against `flame-1.37.0`/Flutter 3.44.4 source in engine-specialist validation, 2026-07-18) — so `game.update(dt)` genuinely keeps running every frame even while offstage; only `game.render()`'s pixels are skipped (`Offstage` still lays out and attaches the render tree, it only skips `paint()`). **This is why AC-5 holds — not because `IndexedStack`/`StatefulShellRoute` guarantees it in general, but because of this specific Flame implementation detail.** If a future Flame upgrade ever changes `GameLoop` to use an idiomatic `vsync`/`TickerProvider`-backed ticker, this guarantee breaks silently — re-verify this exact mechanism on any Flame version bump. See also the CPU-cost note in Performance Implications (the update loop keeps paying its per-frame cost while offstage, with zero rendering benefit) and the Riverpod-`Consumer`-pause caveat below. The floating chip cluster (Profile/Xu/Contextual badge, per `hud.md`) renders as a `Stack` overlay above `navigationShell`, not inside it.

**Constraint for ADR-0004's Flame↔Riverpod bridge** (found in engine-specialist validation, 2026-07-18 — corrects an overclaim in this ADR's original Related Decisions line): unlike Flame's raw-`Ticker`-driven update loop, `flutter_riverpod` 3.3.2's `Consumer`/`ConsumerWidget` **does** respect `TickerMode` — it pauses its provider subscriptions when `TickerMode.of(context)` goes `false` and resumes on switch-back (verified against `flutter_riverpod-3.3.2` source). Any `Consumer`/`ConsumerWidget` living inside the offstage Pet Room branch will have its subscriptions silently paused while the child is on Tasks/Shop. A container-level `ref.listen` or manual subscription set up outside any particular widget's `BuildContext` (the same pattern this ADR's own `routerProvider` bridge uses, Decision §1) is NOT paused. Whichever story implements ADR-0004's bridge into the offstage-surviving `FlameGame` must account for this distinction explicitly — this ADR does not resolve it, only flags it so it isn't rediscovered from scratch.

**3. Parent branch — same `StatefulShellRoute` shape, 2 branches, no Flame concerns but the same state-preservation convention for consistency (matches pattern P13):**

```dart
final parentShellRoute = StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => ParentShellScaffold(
    navigationShell: navigationShell,
  ),
  branches: [
    StatefulShellBranch(routes: [
      GoRoute(path: AppRoutes.parentDashboard, builder: (_, __) => const ParentDashboardTasksTab()),
    ]),
    StatefulShellBranch(routes: [
      GoRoute(path: AppRoutes.parentFamily, builder: (_, __) => const ParentDashboardFamilyTab()),
    ]),
  ],
);
```

**4. `activeChildBranchIndexProvider` — new state this ADR defines and this system owns:**

```dart
/// Written by each shell's bottom-nav `onTap`, alongside `goBranch(index)`.
/// 0-2 for Child Shell (Pet Room/Tasks/Shop), 0-1 for Parent Shell
/// (Dashboard/Gia đình) — index space is scoped per-shell, not global.
/// Any screen needing "am I still the active tab" watches this instead of
/// relying on widget lifecycle (branches are never disposed on switch, so
/// dispose()/RouteObserver never fires for a sibling-branch switch).
final activeChildBranchIndexProvider = StateProvider<int>((ref) => 0);
```

Bottom-nav `onTap` wiring (both shells, same shape):
```dart
onDestinationSelected: (index) {
  navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  ref.read(activeChildBranchIndexProvider.notifier).state = index;
},
```

**5. Parent Override — read/write `parentOverrideProvider` (owned by `auth-account`/ADR-0002), never a new provider here:**

Long-press ≥600ms on the Profile chip (owned by this system per GDD Rule 6, rendered by `hud.md`) opens the switch-mode bottom sheet (**P3**); on confirmed password, `ref.read(parentOverrideProvider.notifier).state = true` then `context.go(AppRoutes.parentDashboard)`. The top-level `redirect` above picks up the resulting `sessionState == parentView` transition automatically via the `ref.listen` refresh bridge — no manual navigation-plus-guard duplication needed. Override-exit (GDD Rule 7 / Parent Dashboard's "Xong"/"Quay lại") is the same in reverse: `parentOverrideProvider.notifier.state = false` then `context.go(AppRoutes.childPetRoom)`, landing directly on Pet Room with no re-PIN, since the child branch was never disposed.

**6. Back-button handling — `PopScope.onPopInvokedWithResult`, per shell, per Core Rule 8:**

```dart
// Child Shell, tab-root screens only (not sub-screens like /child/tasks/new):
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => const ExitConfirmDialog(), // P17, kid-styled "Thoát PetQuest?"
    );
    if (shouldExit ?? false) SystemNavigator.pop();
  },
  child: ...,
)

// Parent Shell, tab-root screens, NOT in override:
PopScope(canPop: true, child: ...) // direct exit, no dialog — default system pop behavior

// Parent Shell, tab-root screens, IN override (sessionState == parentView):
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    ref.read(parentOverrideProvider.notifier).state = false;
    context.go(AppRoutes.childPetRoom);
  },
  child: ...,
)
```

Sub-screens (`/child/tasks/new`) use default `PopScope(canPop: true)` — back returns to `/child/tasks` via go_router's own back-stack, per AC-12, no custom handling needed.

**7. Root-navigator push for non-dismissible ceremony overlays** (Core Rule 1's exception — registered here as the sanctioned mechanism; the overlays themselves belong to future epics like Shop & Reward):

```dart
Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute(builder: (_) => const ChestOpenCeremony(), fullscreenDialog: true),
);
```

Root-navigator push covers the bottom nav bar (which lives at the Scaffold level, outside any branch `Navigator`) — a branch-scoped push would leave it visible/tappable, defeating "non-dismissible."

### Architecture Diagram

```
[Root GoRouter] ── redirect(sessionState) ──┐
                                              │
  unauthenticated ──────────► /login
  parentAuthed ──────────────► /select-child
  childSelected ──────────────► childShellRoute (StatefulShellRoute, 3 branches)
                                    ├─ /child/pet-room   (Flame game loop, never disposed on switch)
                                    ├─ /child/tasks (+ /child/tasks/new sub-route)
                                    └─ /child/shop
  parentView ─────────────────► parentShellRoute (StatefulShellRoute, 2 branches)
                                    ├─ /parent/dashboard
                                    └─ /parent/family

  refreshListenable: ValueNotifier bridged from ref.listen(sessionStateProvider)
  (NOT GoRouterRefreshStream — does not exist in go_router 17.3.0)

  activeChildBranchIndexProvider (StateProvider<int>, owned here) ← written by
  each shell's bottom-nav onTap, alongside goBranch(index)
```

### Key Interfaces

```dart
final routerProvider = Provider<GoRouter>(...);
final activeChildBranchIndexProvider = StateProvider<int>((ref) => 0);

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const selectChild = '/select-child'; // unchanged — already correct in shipped code
  static const pinEntry = '/select-child/pin-entry';
  static const childPetRoom = '/child/pet-room';
  static const childTasks = '/child/tasks';
  static const childTasksNew = '/child/tasks/new';
  static const childShop = '/child/shop';
  static const parentDashboard = '/parent/dashboard'; // MOVED from flat '/parent-dashboard'
  static const parentFamily = '/parent/family'; // NEW
}
```

## Alternatives Considered

### Alternative A (chosen): Root `GoRouter` + two `StatefulShellRoute` trees (Child 3-branch, Parent 2-branch), gated by one top-level `redirect`
- **Pros**: Matches the GDD's own Route Map and Formulas contract exactly; single redirect function keeps the 4-state guard logic in one place, matching ADR-0002's own established single-source-of-truth pattern for `sessionStateProvider`.
- **Cons**: Two separate `StatefulShellRoute`s (not one shared 5-branch shell) means Child and Parent bottom-nav/Scaffold code isn't literally shared.
- **Why two trees, not one shared 5-branch tree** (strengthened per engine-specialist validation, 2026-07-18 — a single tree would still technically satisfy AC-5/AC-9's state-preservation requirement, so that alone doesn't distinguish the two designs): a single shared tree would need per-actor branch *visibility* gating (the `redirect` making 2 of 5 branches unreachable depending on session state) plus a bottom-nav widget dynamically rendering a subset of destinations whose list index must still align 1:1 with `goBranch(index)`'s branch index — that cross-actor index-space entanglement is fragile and outside what `StatefulShellRoute` is designed for. Two independent trees keep each `redirect` branch and each shell's `onTap` wiring fully self-contained, with no shared index space to keep in sync.
- **Rejection Reason**: N/A — chosen.

### Alternative B: Two entirely separate `GoRouter` instances, swapped at the `MaterialApp` root based on session state
- **Pros**: Total isolation between Child and Parent routing — no shared redirect logic to get wrong.
- **Cons**: Breaks deep-link resolution across the boundary (a push-notification deep link to `/parent/dashboard` while the app is cold-started would need router-instance selection logic before go_router even runs); duplicates the session-state-watching logic instead of centralizing it; "child session preserved underneath during Parent Override" becomes much harder — swapping the *entire router instance* would naturally dispose the child branch's widget tree (and Pet Room's Flame game loop with it), directly contradicting AC-9's requirement.
- **Rejection Reason**: Directly incompatible with AC-9 (child session must survive Parent Override) — the Flame state-preservation requirement rules this out structurally, not just as a style preference.

### Alternative C: Single flat `GoRouter`, no `StatefulShellRoute`, plain `GoRoute`s with a custom Scaffold wrapper widget
- **Pros**: Simpler mental model, fewer go_router APIs to get right in a post-cutoff version.
- **Cons**: Plain `GoRoute` navigation disposes and rebuilds the destination widget on each navigation — Pet Room's `FlameGame` would be torn down and recreated on every tab switch, directly violating AC-5 ("no rebuild, Flame game loop still running"). Would require hand-rolling an `IndexedStack`-equivalent preservation layer outside go_router's own APIs — reinventing what `StatefulShellRoute` already provides correctly.
- **Rejection Reason**: Fails AC-5 by construction; the "simpler" APIs solve a problem this project doesn't have (no state preservation) while failing to solve the one it does.

## Consequences

### Positive
- Closes the actual foundational gap blocking every Presentation-layer UI epic (Parent Dashboard UI directly; Pet Room, Task Management, Shop & Reward transitively).
- `activeChildBranchIndexProvider` gives every future screen a single, correct way to detect "am I still visible" without relying on widget lifecycle, which `StatefulShellRoute`'s branch-preservation makes unreliable for that purpose.
- Route path drift (`/child-selector` vs. `/select-child`) is resolved now, in the ADR that would otherwise have re-introduced it, rather than being rediscovered per-story.

### Negative
- Two separate `StatefulShellRoute` trees mean some genuine (small) duplication in bottom-nav-bar wiring code between Child and Parent shells — accepted, since the GDD specifies them as structurally distinct UIs, not a shared component.
- The top-level `redirect`'s 4-branch `switch` is a single function multiple future systems depend on being correct — a bug here has wide blast radius. Mitigated by AC-1/2/3/11/13 being tagged `[INTEGRATION]` BLOCKING in the GDD, requiring real automated coverage, not just manual walkthrough.

### Risks
- **Risk**: `go_router 17.3.0`'s `StatefulShellRoute.indexedStack` factory behavior around `initialLocation` (used in the `goBranch` call above) was not exhaustively tested against every edge case (e.g. deep-linking directly into a non-default branch) during this ADR's authoring — the core constructor/method shapes were verified, but full behavioral edge cases were not. **Mitigation**: flagged as a Validation Criteria item below; the implementing story must test deep-link-to-non-default-branch explicitly. `StatefulShellBranch.preload` (confirmed real, default `false`) is a real lever if `initialLocation` alone proves insufficient — noted here per engine-specialist validation, 2026-07-18, not yet needed.
- **Minor, non-blocking**: `go_router`'s own doc comment above `StatefulNavigationShell.goBranch` shows a named-parameter call (`goBranch(index: index)`) that does not match the method's real positional signature (`goBranch(int index, {...})`) — a documentation bug in the package itself, confirmed by direct source inspection. This ADR's own code samples use the correct positional form; noted so an implementer copying from `go_router`'s own doc comments doesn't hit a compile error.
- **Risk**: `PopScope.onPopInvokedWithResult`'s exact async-dialog-then-conditional-pop pattern (shown in Decision §6) needs live-device verification — Android predictive back gesture (a Flutter 3.22+ feature interacting with `PopScope`) has known platform-specific nuances not fully verifiable from source alone. **Mitigation**: flagged as Validation Criteria; verify on a real Android device with predictive back enabled, not just an emulator/desktop run.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| `main-navigation-shell.md` | `GoRouter` root with a `StatefulShellRoute` of 2 branches — TR-navshell-001 | Decision §1-§3 (two separate `StatefulShellRoute` trees, not one 2-branch tree — see Alternatives A rationale for why this still satisfies the GDD's intent) |
| `main-navigation-shell.md` | Route guard reads `sessionStateProvider` only, never re-derives — TR-navshell-002 | Decision §1; Constraints section explicitly locks this per the architecture registry |
| `main-navigation-shell.md` | `activeChildBranchIndexProvider` is the sole "is this tab active" signal — TR-navshell-003 | Decision §4, registered as new state owned by this ADR |
| `main-navigation-shell.md` | Root-navigator push required for non-dismissible full-screen overlays — TR-navshell-004 | Decision §7 |
| `auth-account.md` | `sessionStateProvider` derived 4-state enum as routing source of truth (TR-auth-account-005) | Consumed, not re-implemented — Decision §1 reads it via `ref.read`/`ref.listen` only |

## Performance Implications
- **CPU**: Negligible — `redirect` is a pure synchronous switch over an already-computed enum; no new async work per navigation.
- **Memory**: `StatefulShellRoute`'s `.indexedStack` factory keeps all branches' widget trees alive simultaneously (by design, for state preservation) — this is a deliberate memory-for-correctness tradeoff already required by AC-5, not a new cost this ADR introduces.
- **CPU** *(added per engine-specialist validation, 2026-07-18)*: because Flame's `GameLoop` bypasses `TickerMode` (see Decision §2), Pet Room's `game.update(dt)` keeps executing every frame even while offstage (Tasks/Shop active) — any per-frame simulation cost (physics, pet AI ticks, particle updates) is paid continuously with zero rendering benefit while not the active branch. Not fixed by this ADR — a future story could wire `FlameGame` to `activeChildBranchIndexProvider` to throttle/pause non-essential update work (`game.pauseEngine()` or an internal flag, not the `Ticker` itself) when not active. Flagged for `performance-analyst` review once real device profiling is possible, not resolved here.
- **Load Time**: None beyond existing route resolution.
- **Network**: None.

## Migration Plan

`src/lib/providers/router_provider.dart` currently has flat placeholder routes only (`AppRoutes.parentDashboard = '/parent-dashboard'` rendering a bare placeholder screen; no `/child/*` or `/parent/family` routes exist at all). This ADR's implementation replaces the route tree entirely:
- `AppRoutes.parentDashboard` changes from `/parent-dashboard` (flat) to `/parent/dashboard` (branch) — any existing reference to the old path must be updated.
- `AppRoutes.selectChild = '/select-child'` is unchanged (already correct) — this is what Parent Dashboard UI's own specs were corrected to match during this epic's `/ux-review` pass.
- New constants added: `parentFamily`, `childPetRoom`, `childTasks`, `childTasksNew`, `childShop`.
- The existing bare placeholder screen for `/parent-dashboard` is removed once Parent Dashboard UI's own epic (currently Blocked on this ADR) implements real content.

## Validation Criteria

`main-navigation-shell.md`'s 14 Acceptance Criteria, in particular:
- AC-1, 2, 3, 11, 13 (`[INTEGRATION]` BLOCKING) — the redirect guard's 4-state logic, testable via a fake `sessionStateProvider` override and asserting resolved route.
- AC-5 — Pet Room Flame game loop survival across tab switches; testable by asserting the same `FlameGame` instance (or a widget-tree-alive proxy) persists across a `goBranch` round-trip.
- AC-9 — child session preserved during Parent Override; testable by asserting `activeChildProvider`'s value is unchanged after the override transition.
- Two risks flagged above (deep-link-to-non-default-branch, Android predictive back) need explicit test coverage, not just incidental coverage from the main AC tests.

## Related Decisions
- ADR-0002 (Auth & PIN Security Architecture) — `sessionStateProvider`'s contract this ADR consumes; the `ref.listen` refresh-bridge pattern this ADR reuses.
- ADR-0004 (Flutter-Flame Event Bridge) — Pet Room's Flame component lifecycle. This ADR's branch-preservation guarantee keeps Flame's own raw-`Ticker`-driven update loop running while offstage, but does **not** extend that guarantee to Riverpod `Consumer`/`ConsumerWidget` subscriptions inside the bridge (those pause on `TickerMode(enabled: false)`, per Decision §2's constraint note) — whichever story implements ADR-0004's bridge must account for this distinction explicitly.
- ADR-0013 (Parent Approval Transaction Architecture) — Parent Dashboard UI, hosted at `/parent/dashboard` per this ADR, is `approveTask()`/`rejectTask()`'s first real caller.
- `design/gdd/main-navigation-shell.md` — the GDD this ADR implements.
