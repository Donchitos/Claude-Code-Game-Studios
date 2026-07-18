# Epic: Parent Approval System

> **Layer**: Feature
> **GDD**: design/gdd/parent-approval.md
> **Architecture Module**: Parent Approval (#11)
> **Status**: Stories Complete — Blocked on Parent Dashboard UI (#21) for 2 DoD items (see Definition of Done)
> **Stories**: 2 stories (2/2 Complete)

## Overview

Parent Approval is the single atomic operation that turns a submitted task into a
real reward. When a parent taps Approve, one Firestore `runTransaction` touches
five systems' fields in one commit: task status flips to `approved`, xu and energy
are credited (Currency #7, Time & Decay #2), the child's pending seed pops
(`seedCount -= 1`, Seed Buffer #10), and the pet's lifetime effort counter advances
with a level-up/chest-milestone check (`totalXuEarned`/`petLevel`, Pet Leveling #16;
`approvedTaskCount`/`chestCount`, Gacha/Loot #12). Reject uses the same idempotency
shape with no reward writes. Parent Approval owns no field it touches — it is purely
the assembly point that guarantees no double-grant across three known race
conditions (double-tap, two-parent-device race, mid-transaction failure).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0013: Parent Approval Transaction Architecture | `ParentApprovalRepository.approveTask()`/`rejectTask()` — single client-side `runTransaction`, idempotency-gated on `task.status` as the first read, computes `leveledUp`/`hitChestMilestone`/`chestDelta` in-memory, writes all fields atomically, returns a result (never emits events itself — that's the caller's job per ADR-0004 §3) | LOW |
| ADR-0004: Flutter-Flame Event Bridge Architecture | `taskApproved`/`petLeveledUp` are distinct `GameEventType`s with their own payload contracts; two sanctioned emit adapters only (`ref.listen` in a `ConsumerWidget`, or a Flame tap/drag handler) — a repository is neither | MEDIUM |

**Epic Engine Risk: MEDIUM** (highest among governing ADRs — carried from ADR-0004's Flame lifecycle-idiom risk, not from ADR-0013 itself).

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|---------------|
| TR-parentapproval-001 | Single `runTransaction` assembles all reward writes atomically on approve | ADR-0013 ✅ |
| TR-parentapproval-002 | Idempotency read (`status == 'pending'`) happens first, inside the transaction | ADR-0013 ✅ |
| TR-parentapproval-003 | One transaction per task; no Approve-All batch operation | ADR-0013 ✅ |
| TR-parentapproval-004 | `lastApprovedAt = serverTimestamp()` is written on approve | ADR-0013 ✅ |
| TR-parentapproval-005 | `chestDelta` combines level-up-chest and gacha-milestone-chest additively, never suppressing one for the other | ADR-0013 ✅ |
| TR-parentapproval-006 | Reject uses the same idempotency guard as approve, and writes its own `rejectedAt` field | ADR-0013 ✅ |
| TR-parentapproval-007 | `taskApproved` is its own `GameEventType` with a payload distinct from `petMoodChanged` | ADR-0004 ✅ |
| TR-parentapproval-008 | Transaction failure handling is unified (single error path), no invented auto-retry loop | ADR-0013 ✅ |

**Coverage: 8 / 8.** No untraced requirements.

## Scope Note — nextLevelThreshold Initialization Gap (revised at story-creation time)

ADR-0013's own Migration Plan flags a real gap: nothing ever sets the child
doc's *initial* `nextLevelThreshold` value (150). Investigated further at
`/create-stories` time: this field is **write-only** inside `approveTask()` —
it is never read back to compute `leveledUp` (that computation calls the pure
`nextLevelThreshold()` function, not the cached Firestore field). The cached
field exists only for a future consumer (a Pet Leveling & Evolution #16
progress-bar UI, which has no epic yet). All fields `approveTask()` *does*
read (`totalXuEarned`, `petLevel`, `approvedTaskCount`) already default safely
(`?? 0`, `?? 1`) per ADR-0013's own code — matching this codebase's established
missing-field-defaults pattern.

**Bigger gap found while investigating**: there is no `createChildProfile()` write
path anywhere in the codebase (`src/lib/`, `functions/src/index.ts`) — Auth &
Account (marked Complete, 13/13 stories) never built it. This is out of Parent
Approval's scope entirely and is **not** included in this epic. Flagged separately
(see production/session-state/active.md and the spawned background task) for a
future Auth & Account story. `approveTask()`/`rejectTask()` work correctly against
a child doc missing all these fields regardless, so this epic is not blocked by
the gap.

## Known Risks Carried From Governing ADRs (not resolved by this epic — flagged for story-time awareness)

- **GameEventBus replay risk (ADR-0013 Consequences → Risks, found during ADR-0013's own validation pass)**: `GameEventBus` (ADR-0004 §5) caches and replays the last event per `GameEventType` to any newly-subscribing listener. `taskApproved`/`petLeveledUp` are one-shot *trigger* events with no distinguishing identity in their payload — once any task has ever been approved, every later remount of a subscribing Flame component (screen nav away/back, `IndexedStack` rebuild) will receive a spurious replay and incorrectly re-trigger the bounce/level-up animation. This gap pre-dates this epic (both event types were already in the enum) but this epic is the first to make it *reachable* by being the first real emitter. **Not fixed by this epic** — resolving it means revising ADR-0004's replay mechanism, a cross-cutting change out of this epic's scope. Carried forward here so a story doesn't silently rediscover it.
- **Background→foreground replay path unverified (ADR-0004's own Verification Required field)**: the bridge spike measured live online sync but did not exercise a device offline-at-approve-time then reconnecting. Manual verification (~10 min) explicitly called out as required "during Parent Approval (#11) implementation" — this epic's own stories should include that verification pass, not defer it further.

## Definition of Done

This epic is complete when:
- [x] All stories are implemented, reviewed, and closed via `/story-done`
- [x] All acceptance criteria from `design/gdd/parent-approval.md` (Approve/Reject scope) are verified
- [x] All Logic and Integration stories have passing test files in `tests/`
- [ ] The background→foreground replay verification (ADR-0004) has been performed at least once and the result documented in the relevant story's Completion Notes — **cannot be performed by this epic's own stories**: neither `approveTask()` nor `rejectTask()` has a real caller (both deliberately return without emitting, ADR-0013 §2/§3). This verification requires a live `taskApproved` emission, which only a future Parent Dashboard UI (#21) `ConsumerWidget` can trigger.
- [ ] The GameEventBus replay risk is explicitly acknowledged in the story that first emits `taskApproved`/`petLeveledUp` for real — **not yet applicable**: no story in this epic emits events at all. This item transfers to whichever future story (Parent Dashboard UI #21) first wires `ref.listen` onto `approveTask()`'s result.

**Epic Status: Stories Complete, epic itself left open** — matching the same honest pattern already established for the Push Notification epic ("Stories Complete — Blocked on TestFlight hardware"), not silently marked fully Complete. The repository layer (`approveTask()`/`rejectTask()`) is done, tested, and reviewed; the two remaining DoD items are Parent Dashboard UI's (#21) responsibility to close when that epic is created.

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Approve Transaction — Reward Assembly, Level-Up & Chest Milestone | Integration | Complete | ADR-0013 |
| 002 | Reject Transaction — Idempotent Status-Only Write | Integration | Complete | ADR-0013 |

## Epic Completion Notes

**Stories closed**: 2026-07-18 (both same day)
**Test coverage**: 39 tests total (19 approve + 8 reject + 12 pure-formula unit tests), all independently re-verified. Full project suite: 354 passed / 1 pre-existing skip / 0 failures.
**Code review**: Both stories APPROVED WITH SUGGESTIONS (`flame-specialist` + `qa-tester`, parallel/independent each time) — all suggestions closed before each story's close (petLevel corruption guard, dedicated formula unit tests, missing-reward-field documentation, child-doc-existence invariant documentation).
**Carried-forward gap** (flagged separately, not silently dropped): no `createChildProfile()` write path exists anywhere in the codebase — Auth & Account (marked Complete) never built it. Flagged via a spawned background task during epic creation, not fixed here (out of Parent Approval's scope). `approveTask()`/`rejectTask()` work correctly regardless (all child-doc reads default safely).
**Next recommended**: Parent Dashboard UI (#21) is the natural next epic — it both closes this epic's 2 remaining DoD items (event emission, replay verification) and is the actual consumer of `approveTask()`/`rejectTask()`. Alternatively, Shop System (#13) or Gacha/Loot (#12) — both have existing GDDs/ADRs and no epic yet.

## Next Step

Epic's own implementation work is done. See "Next recommended" above for what to pick up next.
