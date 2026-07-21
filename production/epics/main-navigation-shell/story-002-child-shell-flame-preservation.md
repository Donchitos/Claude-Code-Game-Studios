# Story 002: Child Shell — 3-Tab StatefulShellRoute & Flame State Preservation

> **Epic**: Main Navigation Shell
> **Status**: Ready
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: 4h
> **Manifest Version**: 2026-07-16
> **Last Updated**: —

## Context

**GDD**: `design/gdd/main-navigation-shell.md`
**Requirement**: `TR-navshell-001`, `TR-navshell-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0014: Navigation Shell & Route Guard Architecture (Accepted), Decision §2 and §4
**ADR Decision Summary**: `StatefulShellRoute.indexedStack` with 3 `StatefulShellBranch`es (`/child/pet-room`, `/child/tasks` + nested `/child/tasks/new`, `/child/shop`). Branch preservation keeps Pet Room's `FlameGame` instance and its update loop alive while offstage — but **for a narrower reason than "IndexedStack never disposes"**: Flame's `GameLoop` drives itself via a raw `Ticker` that bypasses `TickerMode` entirely, so `game.update(dt)` keeps running every frame even offstage (only `render()`'s pixels are skipped). `activeChildBranchIndexProvider` (owned by this system) is written alongside every `goBranch(index)` call.

**Engine**: Flutter 3.44.4 / `go_router 17.3.0` / Flame `1.37.0` | **Risk**: HIGH — this story's AC-5 is the ADR's single most scrutinized claim during engine-specialist validation
**Engine Notes**: ⚠️ **Read ADR-0014 Decision §2 in full before implementing** — it documents the exact mechanism (raw `Ticker` bypassing `TickerMode`) this story's Flame-survival behavior depends on, a caveat about Riverpod `Consumer`/`ConsumerWidget` subscriptions *pausing* on `TickerMode(false)` (unlike Flame's own loop — relevant if this story's Pet Room screen has any `Consumer` widgets bridging Riverpod state into the game), and a CPU-cost note (the offstage game loop keeps paying its per-frame cost with zero rendering benefit — not fixed by this story, flagged for future perf work).

**Control Manifest Rules (this layer)**:
- Required: `StatefulShellRoute.indexedStack` factory (not the primary constructor directly) — matches ADR-0014's verified usage
- Required: `activeChildBranchIndexProvider` (`StateProvider<int>`, index space 0-2 for this shell) written by bottom-nav `onTap` alongside `goBranch(index)` — registered state ownership (`docs/registry/architecture.yaml`)
- Required: sub-screen (`/child/tasks/new`) uses default `PopScope(canPop: true)` — back returns to `/child/tasks` via go_router's own back-stack, no custom handling

**Performance Budget**: Tab switch fade-through animation 200ms (Material 3 pattern, GDD Visual/Audio Requirements) — AC-4's explicit performance criterion.

---

## Acceptance Criteria

*From GDD Acceptance Criteria AC-3 (nav bar rendering portion), 4, 5, 12, plus the UX-added touch-target criterion:*

- [ ] **AC-3 (nav bar)**: GIVEN bé gõ PIN đúng, THEN Child bottom nav (3 tabs: Nhà/Nhiệm vụ/Shop) hiển thị cùng route `/child/pet-room`.
- [ ] **AC-4**: GIVEN bé ở `/child/pet-room`, WHEN tap tab "Nhiệm vụ", THEN navigate sang `/child/tasks` trong 200ms; tab "Nhà" không còn active.
- [ ] **AC-5 (the critical one)**: GIVEN bé ở `/child/tasks`, WHEN tap tab "Nhà" quay lại, THEN Pet Room screen resume ngay — không rebuild, Flame game loop vẫn running. Silent-failure risk: nếu game loop bị dispose nhầm, không có triệu chứng UI rõ ràng ngoài animation bị reset — test phải assert trực tiếp trên game-loop/FlameGame instance identity, không chỉ quan sát UI.
- [ ] **AC-12**: GIVEN bé ở `/child/tasks/new` (sub-screen), WHEN back-press, THEN navigate về `/child/tasks` — không về Pet Room.
- [ ] **Touch target / no-op re-tap** (added at `/ux-review`): mọi nav-tab đạt tối thiểu 48×48dp; re-tap tab đang active là no-op (không tạo stacked navigation push).
- [ ] **`activeChildBranchIndexProvider` correctness**: GIVEN tap chuyển từ tab 0 sang tab 1, THEN `activeChildBranchIndexProvider`'s value cập nhật đúng thành 1, đồng thời với `goBranch(1)` được gọi — cả hai xảy ra cùng lúc, không có window nào 1 trong 2 đã update còn cái kia chưa.

---

## Implementation Notes

*Derived from ADR-0014 Decision §2 and §4 — copy the code samples closely, this is where the engine-specialist's most detailed findings apply:*

1. `StatefulShellRoute.indexedStack(builder: ..., branches: [...])` — 3 branches exactly as ADR-0014's code sample: `/child/pet-room`, `/child/tasks` (with nested `GoRoute(path: 'new', ...)` for `/child/tasks/new`), `/child/shop`.
2. `ChildShellScaffold` hosts `navigationShell` as `Scaffold.body`. Floating chip cluster (Story 006's scope) renders as a `Stack` overlay above it, not inside — do not couple this story's Scaffold structure to Story 006's chip widgets; leave a clean insertion point.
3. Bottom-nav `onTap`: `navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)` **and** `ref.read(activeChildBranchIndexProvider.notifier).state = index` in the same handler — per ADR-0014 Decision §4's exact wiring pattern.
4. **Do not write a custom re-implementation of Flame lifecycle management** — the survival behavior is a property of `StatefulShellRoute.indexedStack` + Flame's own `GameLoop` implementation, not something this story's code needs to explicitly preserve. The story's job is to NOT accidentally break it (e.g., don't wrap Pet Room's route builder in anything that would force a rebuild/key-change on branch switch — no `ValueKey` tied to branch index on the Pet Room widget, no `AutomaticKeepAliveClientMixin` workarounds that aren't needed given `IndexedStack` already handles this).
5. For AC-5's test: assert against the actual `FlameGame`/`GameLoop` instance's identity (e.g., a test hook exposing whether the same object reference persists across a simulated `goBranch` round-trip) — do not rely solely on a UI-visible proxy (like "animation didn't visibly reset"), since the ADR's own Risks section notes this failure mode has no clear UI symptom.
6. Sub-screen back (`/child/tasks/new` → `/child/tasks`): default `PopScope(canPop: true)`, no custom `onPopInvokedWithResult` — go_router's own nested-route back-stack handles this natively per ADR-0014 Decision §6.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- **Story 001**: root redirect (this story's `StatefulShellRoute` is wired INTO Story 001's route tree, replacing its stub).
- **Story 003**: Parent Shell.
- **Story 005**: Child tab-root back-button exit-confirm dialog (AC-10 — different from this story's AC-12 sub-screen back, which is native go_router back-stack behavior, not a custom dialog).
- **Story 006**: Floating chip cluster rendering (this story only reserves the Scaffold structure for it).
- Actual Pet Room/Tasks/Shop screen *content* — those belong to Pet Room Screen UI (#18), Task Management UI (#19), Shop & Reward UI (#20), none of which have epics yet. This story can use placeholder screens for its own testing if those don't exist yet — note this explicitly in Completion Notes if so.

---

## QA Test Cases

*Transcribed from GDD's own Acceptance Criteria — QL-STORY-READY gate skipped (Solo mode).*

- **AC-4**
  - Given: on `/child/pet-room`
  - When: tap "Nhiệm vụ" tab
  - Then: route becomes `/child/tasks` within 200ms, "Nhà" tab visually inactive
  - Edge cases: rapid double-tap on the target tab — must not double-navigate

- **AC-5 (critical)**
  - Given: Pet Room branch active, `FlameGame` instance reference captured
  - When: switch to Tasks branch, then switch back to Pet Room
  - Then: the SAME `FlameGame`/game-loop instance reference is observed (not a new one), and its update-tick count continued incrementing while offstage (proves the loop kept running, not just that the object survived)
  - Edge cases: switch through all 3 branches in sequence before returning to Pet Room — instance must still be the same one

- **AC-12**
  - Given: on `/child/tasks/new`
  - When: back-press
  - Then: route is `/child/tasks`, NOT `/child/pet-room`

- **Touch target / no-op re-tap**
  - Given: already on the active tab
  - When: tap it again
  - Then: no navigation event fires, no stacked push (assert navigation stack depth unchanged)

- **`activeChildBranchIndexProvider`**
  - Given: provider value is 0
  - When: tap tab index 1
  - Then: provider value is 1 immediately after the tap handler completes, synchronized with `goBranch(1)`

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/main-navigation-shell/child_shell_test.dart` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (Root Redirect) must be Complete — this story's `StatefulShellRoute` wires into that story's route tree.
- Unlocks: Story 006 (Floating Chip Cluster needs the Child Shell's Scaffold structure to render into).
