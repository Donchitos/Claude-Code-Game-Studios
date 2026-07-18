# Epic: Flutter-Flame State Bridge

> **Layer**: Core
> **GDD**: design/gdd/flutter-flame-state-bridge.md
> **Architecture Module**: Flutter-Flame State Bridge (#5)
> **Status**: Complete (2026-07-16) — all 2 stories closed
> **Stories**: 2 stories created (2026-07-16) — see table below

## Overview

This epic implements the single sanctioned communication channel between the
Flutter/Riverpod state layer and the Flame rendering canvas: `GameEventBus`, a
pure-Dart broadcast singleton carrying typed `GameEvent`s, one-way (Flutter→Flame,
with the sole exception of Flame components emitting directly for their own
input events, e.g. Pet Interaction's tap/swipe). This is the project's
highest-engine-risk Core system — the vertical slice validated the
`onMount()`/`isMounted`-guard/`onRemove()` subscription pattern works correctly in
real Flame 1.37 and measured real end-to-end latency (avg 151ms). No Flame
component may read Riverpod directly; no Notifier may emit a second bus; every
event type owns a distinct payload shape.

**Exit-criteria note — RESOLVED (confirmed 2026-07-16, before writing any stories)**: ADR-0004's "replay last known state" requirement (TR-bridge-005) was originally scoped only to whole-app background→foreground recovery. The vertical slice found the real failure mode is broader — **any Flame component that gets dynamically remounted** (not just the whole app backgrounding) needs the last event of its type replayed, or it silently renders stale/default state with no error signal. ADR-0004 §5 already contains the 2026-07-13 Correction note specifying the true bus-level "cache last event per type, replay to every new subscriber" mechanism — verified by direct read of the ADR file before story creation began. Story 001 implements this corrected version directly; no separate ADR-fix step was needed at story-creation time.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0004: Flutter-Flame Event Bridge Architecture | `GameEventBus` pure-Dart broadcast singleton; typed `GameEvent` per type; `ref.listen` and direct Flame-component-emit are the only two sanctioned adapters; subscribe in `onMount()` not `onLoad()` (source-verified against Flame 1.37); background→foreground replay | MEDIUM — the replay-scope gap above must be corrected before implementation; otherwise the core subscription lifecycle pattern is source-verified and low-risk |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-bridge-001 | `GameEventBus` is a pure-Dart broadcast singleton, app-lifetime | ADR-0004 ✅ |
| TR-bridge-002 | `GameEvent` is typed per event type; communication is one-way Flutter to Flame | ADR-0004 ✅ |
| TR-bridge-003 | `ref.listen` is the sanctioned bridge adapter from Riverpod into Flame | ADR-0004 ✅ |
| TR-bridge-004 | Flame subscriber uses an `isMounted` guard and cancels its subscription in `onRemove()` | ADR-0004 ✅ |
| TR-bridge-005 | Background-to-foreground replays last known state per event type, not full history | ADR-0004 ✅ (scope-widened correction already landed in the ADR — see exit-criteria note above) |
| TR-bridge-006 | Measured end-to-end latency avg 151ms / max 439ms (spike-validated) | ADR-0004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/flutter-flame-state-bridge.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- A test explicitly covers the "component remounted after another component/screen was recreated" case (not just app background/foreground) — this is the exact bug class the vertical slice found — **satisfied**: `test_remount_replay_a_brand_new_component_instance_immediately_reflects_the_cached_event` in `tests/integration/bridge/game_event_subscriber_test.dart`, verified by flame-specialist to use a genuinely new component instance, not a re-added one
- ADR-0004's replay-scope correction (exit-criteria note above) has landed before this epic is marked done — already confirmed at story-creation time

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | GameEventBus Core (Bus, Event Contract, Replay Cache) | Logic | **Complete** | ADR-0004 |
| 002 | Flame Component Subscriber Lifecycle Pattern | Integration | **Complete** | ADR-0004 |

**Not independently implementable as a story** (pattern applied by downstream epics, not a standalone deliverable — same reasoning class as Data Persistence Layer's TR-003/004):
- `TR-bridge-003` (`ref.listen` sanctioned adapter) — lives in whichever Riverpod-consuming widget bridges a specific provider (Pet State Machine, Seed Buffer, Pet Equipment, Pet Leveling); none of those widgets exist yet. Already documented as a pattern rule in `docs/architecture/control-manifest.md`.

**Already satisfied** (not re-implemented):
- `TR-bridge-006`'s end-to-end multi-device latency figure (avg 151ms / max 439ms) — spike-validated in `prototypes/firebase-multidevice-sync-spike-2026-07-03/`. Story 001 only tests the local-delivery-latency portion, which is the part actually exercised by new code.

**Design decision**: Story 002 builds a reusable Flame-component mixin for the subscribe/guard/cancel lifecycle, rather than requiring every future consuming component (`MochiComponent`, `SeedBagComponent`, etc.) to hand-roll ADR-0004 §4's raw pattern each time — in-scope for this epic specifically because ADR-0004's Ordering Note says this ADR owns the subscriber lifecycle itself, not just its documentation.

**Recommended build order**: 001 → 002 (002 depends directly on 001's replay cache).

**Test infrastructure note**: `GameEventBus.resetForTesting()` (a `@visibleForTesting` seam) was added during Story 002's review after the same replay-cache test-pollution bug recurred a 2nd time across the two stories' test suites. Any future epic writing tests against `GameEventBus` (directly or via the `GameEventSubscriber` mixin) should call this in `setUp()` for real per-test isolation, rather than relying on each test using a never-before-emitted `GameEventType`.

## Next Step

**All 2 stories are Complete.** This closes the epic — `GameEventBus` and the `GameEventSubscriber` mixin are ready for every downstream consumer (Pet State Machine #6, Seed Buffer #10, Pet Equipment #15, Pet Interaction #14, Pet Leveling #16, Pet Room Screen UI #18). Recommended next: Pet State Machine (#6), the first real consumer of this bridge (`MochiComponent`, `petMoodChanged`/`petInteracted`/`taskApproved`/`petLeveledUp` handling) — or another Foundation-layer epic still without stories (Item Database #3, Time & Decay #2) if sequencing engine-risk work isn't the priority right now.
