# Epic: Parent Dashboard UI

> **Layer**: Presentation
> **GDD**: design/gdd/parent-dashboard-ui.md
> **Architecture Module**: Parent Dashboard UI (#21)
> **Status**: In Progress (3/4 stories complete) — Story 004 still Blocked on a missing ADR; no further Ready stories remain in this epic
> **Stories**: 4 stories

## Blocker status — corrected 2026-07-22 (Story 001's second blocker now fixed)

Main Navigation Shell (#17)'s blocker (found 2026-07-18) is resolved — all 6 stories Complete, `/parent/dashboard`/`/parent/family` routes and the Parent Shell tab structure now real and tested.

**Story 001's second blocker (Task Library #8 gaps) is now fixed** — see Task Library `EPIC.md`'s "Post-Closure Fix — 2026-07-22" note:
1. `familyPendingTasksProvider` added (`src/lib/providers/task_providers.dart`) — merges pending tasks across all of the family's children, fixing AC-2 (multi-child correctness) and the primary "parent logs in directly, no active child session" flow.
2. `TaskModel` (`src/lib/core/models/task_model.dart`) now has `id`/`childId` fields, required for Story 001 to call `approveTask()`/`rejectTask()` and resolve per-card avatar/name.

Story 001 is Ready. Story 004 remains separately Blocked on a missing ADR (TR-parentdash-002).

## Overview

Parent Dashboard UI is the single screen parents interact with in all of PetQuest —
a pure Flutter widget layer (Material 3, no Flame) hosting 5 surfaces across 2 tabs
inside the Parent Shell that Main Navigation Shell (#17) already routes: the
Nhiệm vụ tab (pending-task list with Approve/Reject, wired to Parent Approval #11's
transaction), a create-custom-task bottom sheet (writes to Task Library #8's new
`customTasks` collection), the Gia đình tab (child profile list with Reset PIN,
calling Auth & Account #1's mechanism), a Reset PIN dialog, and a foreground FCM
banner (Push Notification #9's `onMessage` stream, with a defer/coalesce state
machine — the GDD's only `[LOGIC]`-tier requirement). This epic owns no persistent
data itself — every write goes through a function already defined by the epic that
owns that data; this UI is purely the assembly and presentation layer, matching
the same "no field ownership, just orchestration" shape Parent Approval (#11)
established for its own transaction.

This epic is also the natural closer for Parent Approval (#11)'s two open
Definition of Done items — it's the first real `ConsumerWidget` caller of
`approveTask()`/`rejectTask()`, and therefore the first place `GameEvent(taskApproved)`/
`(petLeveledUp)` are ever actually emitted in the running app.

## Governing ADRs

**None yet.** `architecture.md`'s Required ADRs list names "Parent Dashboard
Notification Banner State Machine" as not yet written — this covers the GDD's
only `[LOGIC]`-tier requirement (Core Rule 6/Edge Case 4-5's banner defer/coalesce
state machine). The remaining 4 surfaces are `[UI]`-tier Flutter widget work
calling already-defined functions from owning systems (#11, #8, #1) and do not
require a dedicated ADR the way a data/transaction system would — user chose to
proceed without blocking epic creation on this, and write the ADR when the
banner-logic story is reached.

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-parentdash-001 | Pending list is uncapped; Approve/Reject button state machine matches Parent Approval exactly | ❌ No ADR (UI-tier, reuses #11's already-Accepted ADR-0013 pattern via P1) |
| TR-parentdash-002 | FCM banner defers while a modal is open, and coalesces via an unseenCount state machine | ❌ No ADR — **the one requirement that genuinely needs one** (Logic-tier) |
| TR-parentdash-003 | targetChildId auto-assigns for single-child families | ❌ No ADR (UI-tier, but BLOCKING test-evidence requirement per GDD — read-back verification) |
| TR-parentdash-004 | Reset PIN dialog calls resetChildPin() and includes a real PIN-entry field, not a bare confirm | ❌ No ADR (UI-tier, calls #1's already-defined mechanism) |

**Coverage: 0 / 4 by ADR** — acceptable per user decision above; TR-parentdash-002's story will be Blocked until an ADR is written for it specifically.

## UX Spec

`design/ux/parent-dashboard-ui.md` — **Complete, APPROVED** (`/ux-review` 2026-07-18, 1 blocking + 4 advisory findings, all fixed). Covers all 5 surfaces: Layout Zones, Component Inventory, Interaction Map, States & Variants (including 3 error states not in the GDD), Events Fired (flags the GameEventBus emission point explicitly), Acceptance Criteria (includes the GDD's own BLOCKING read-back verification for `targetChildId`). Two GDD Open Questions resolved during this pass (Reject reason: stays anonymous; race-condition toast: stays silent). Pattern **P18** (Conditional selector) added to `design/ux/interaction-patterns.md`.

## Known Cross-Epic Connection (not resolved by this epic alone — flagged for story-time awareness)

The Approve button story in this epic is where `GameEvent(taskApproved)`/`(petLeveledUp)` get emitted for the first time in the whole app (per ADR-0013 §2 and this epic's own UX spec, Events Fired section). This directly triggers the **GameEventBus replay risk** already documented in `production/epics/parent-approval/EPIC.md`'s Known Risks — a Flame component remounting (screen nav away/back) will receive a spurious replay of the last `taskApproved`/`petLeveledUp` event. The story that implements Approve-button emission must explicitly address this (mitigate if in scope, or formally carry forward as tech debt) — this is Parent Approval epic's own Definition of Done item 5, which transfers here.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/parent-dashboard-ui.md` AND `design/ux/parent-dashboard-ui.md` are verified
- All Logic and Integration stories have passing test files in `tests/` (the banner state machine, the `targetChildId` read-back verification)
- All UI stories have evidence docs with sign-off in `production/qa/evidence/` (advisory gate per this GDD's own predominantly-UI test tier)
- An ADR exists and is Accepted for the banner defer/coalesce state machine (TR-parentdash-002) before that specific story is implemented
- Parent Approval (#11)'s two remaining DoD items (background→foreground replay verification, GameEventBus replay-risk acknowledgment) are closed by the Approve-button story in this epic — ✅ **done**, Story 001's Completion Notes explicitly acknowledge the replay risk is now live (first real emitter); the risk itself remains open tech debt requiring an ADR-0004 revision, tracked there, not silently closed

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Nhiệm vụ Tab — Pending List, Approve/Reject Wiring & Event Emission | Integration | Complete | N/A (ADR-0013/0004 referenced) |
| 002 | Create Custom Task Bottom Sheet | Integration | Complete | N/A |
| 003 | Gia đình Tab — Child List & Reset PIN Dialog | UI | Complete | N/A |
| 004 | FCM Foreground Banner — Defer/Coalesce State Machine & Permission Reminder | Logic | **Blocked** | None — run `/architecture-decision` |

## Next Step

No Ready stories remain in this epic. Story 004 (FCM Foreground Banner) is the only remaining story — run `/architecture-decision` for "Parent Dashboard Notification Banner State Machine" (TR-parentdash-002) to unblock it.
