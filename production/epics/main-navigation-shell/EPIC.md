# Epic: Main Navigation Shell

> **Layer**: Presentation
> **GDD**: design/gdd/main-navigation-shell.md
> **Architecture Module**: Main Navigation Shell (#17)
> **Status**: In Progress (1/6 stories complete)
> **Stories**: 6 stories

## Overview

Main Navigation Shell is the root `GoRouter` widget every screen in PetQuest lives
inside — it reads `sessionStateProvider` (owned by Auth & Account, never re-derived
here) and renders the correct navigation tree for whichever actor is using the
device. Two `StatefulShellRoute` trees: Child Shell (3 tabs — Pet Room/Tasks/Shop,
must preserve Pet Room's live `FlameGame` instance across tab switches) and Parent
Shell (2 tabs — Dashboard/Gia đình). A single top-level redirect implements the
4-state session guard (`unauthenticated`/`parentAuthed`/`childSelected`/`parentView`).
Parent Override lets a parent view the Parent Shell without disposing the child's
session underneath — the shell's entire purpose is keeping the child's and parent's
experiences structurally separate while each gets an instantly legible way to move
around their own world.

This epic was created after discovering, during Parent Dashboard UI's Story 001
`/dev-story` attempt (2026-07-18), that this foundational routing layer — referenced
as Designed/Approved throughout every other Presentation-layer GDD — had never
actually been implemented (`router_provider.dart` only had flat placeholder routes).
This epic unblocks Parent Dashboard UI's epic entirely, and will unblock Pet Room
Screen UI, Task Management UI, and Shop & Reward UI whenever those epics are created.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0014: Navigation Shell & Route Guard Architecture | Root `GoRouter` + single top-level 4-state redirect + two separate `StatefulShellRoute` trees (Child 3-branch, Parent 2-branch); `ref.listen`-bridged refresh (never `ref.watch`, never the nonexistent `GoRouterRefreshStream`); `activeChildBranchIndexProvider` owned here; `PopScope.onPopInvokedWithResult` for back-button handling (never `WillPopScope`, removed since Flutter 3.22) | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-navshell-001 | `GoRouter` root with a `StatefulShellRoute` of 2 branches (child / parent) | ADR-0014 ✅ (implemented as two separate `StatefulShellRoute` trees, not one shared 2-branch tree — see ADR-0014's Alternatives for the index-space rationale) |
| TR-navshell-002 | Route guard reads `sessionStateProvider` only; never re-derives session state independently | ADR-0014 ✅ |
| TR-navshell-003 | `activeChildBranchIndexProvider` is the sole "is this tab currently active" signal | ADR-0014 ✅ |
| TR-navshell-004 | Root-navigator push is required for non-dismissible full-screen overlays (e.g. Chest ceremony) | ADR-0014 ✅ |

**Coverage: 4 / 4.** No untraced requirements.

## UX Specs

Both **Complete, APPROVED** (`/ux-review` 2026-07-18):
- `design/ux/main-navigation-shell.md` — 2 blocking findings fixed (cold-start loading state added; `/child-selector`→`/select-child` route correction, propagated to the GDD and to Parent Dashboard UI's specs/stories too), 3 advisory fixed.
- `design/ux/hud.md` — 1 blocking finding fixed (FCM banner auto-dismiss directly contradicted Parent Dashboard's own deliberate "manual dismiss only" Tuning Knob decision — corrected to match), 4 advisory fixed.

## Known Engine Risks Carried From ADR-0014 (not resolved by this epic alone — flagged for story-time awareness)

- **AC-5's Flame-survival guarantee is narrower than it looks**: Pet Room's game loop survives offstage branches because Flame's `GameLoop` uses a raw `Ticker` that bypasses `TickerMode` entirely — not because `StatefulShellRoute` guarantees this in general. Re-verify this exact mechanism on any future Flame version bump (ADR-0014 Decision §2).
- **Riverpod `Consumer`/`ConsumerWidget` subscriptions DO pause when offstage** (unlike Flame's own loop) — whichever story wires ADR-0004's Flame↔Riverpod bridge into the persisted Pet Room branch must account for this distinction explicitly, or state updates will silently stop flowing into the game loop while the child is on Tasks/Shop.
- **CPU cost**: the offstage Pet Room's `game.update(dt)` keeps paying its full per-frame cost with zero rendering benefit while not the active branch. Not fixed by this epic — flagged for `performance-analyst` once real-device profiling is possible.
- **Two unverified edge cases** (ADR-0014's own Validation Criteria): deep-linking directly into a non-default branch, and Android predictive-back gesture interaction with `PopScope`. Both need explicit test coverage, not just incidental coverage from the main ACs.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All 14 acceptance criteria from `design/gdd/main-navigation-shell.md` are verified (5 are `[INTEGRATION]` BLOCKING per the GDD's own test-tier note — AC-1, 2, 3, 5, 11, 13, 14 require automated test coverage, not manual walkthrough)
- All Logic and Integration stories have passing test files in `tests/`
- The two unverified edge cases in ADR-0014's Validation Criteria (deep-link-to-non-default-branch, Android predictive back) have explicit test coverage
- `router_provider.dart`'s existing `AppRoutes` constants are migrated per ADR-0014's Migration Plan (`parentDashboard` moves from flat `/parent-dashboard` to `/parent/dashboard`; new `parentFamily`/`childPetRoom`/`childTasks`/`childTasksNew`/`childShop` constants added)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Root Redirect & Session Guard | Integration | Complete | ADR-0014 |
| 002 | Child Shell — 3-Tab StatefulShellRoute & Flame State Preservation | Integration | Ready | ADR-0014 |
| 003 | Parent Shell — 2-Tab StatefulShellRoute | Integration | Ready | ADR-0014 |
| 004 | Parent Override — Switch To/From Parent Mode | Integration | Ready | ADR-0014 |
| 005 | Child Back-Button Exit Dialog & Root-Navigator Push Contract | UI | Ready | ADR-0014 |
| 006 | Floating Chip Cluster — Profile, Xu, Contextual Badge Wiring | Integration | Ready | N/A (references `hud.md`) |

## Next Step

Run `/story-readiness production/epics/main-navigation-shell/story-001-root-redirect-session-guard.md` then `/dev-story` to begin implementation. Story 001 is the foundation every other story depends on.
