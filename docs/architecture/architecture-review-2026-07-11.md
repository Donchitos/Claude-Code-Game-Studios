# Architecture Review Report

**Date**: 2026-07-11
**Engine**: Flutter 3.44.4 / Flame 1.37.0 / Dart 3.12.2
**Mode**: `/architecture-review` (full)
**GDDs Reviewed**: 21 system GDDs (`design/gdd/systems-index.md` used as the authoritative list)
**ADRs Reviewed**: 10 (`ADR-0001` Accepted; `ADR-0002`–`ADR-0010` Proposed)

> This review was run in a session that did not author any of the reviewed ADRs, per the
> project's rule that architecture review must be independent of the authoring session.
> Heavy-lifting analysis (Phases 1–6) was performed by a fresh general-purpose agent with
> no prior context; the engine-specific findings were independently cross-checked by a
> second, separate `flame-specialist` consultation. Both agents were instructed to verify
> claims against actual file content rather than trust prior status labels, per this
> project's own track record (every ADR/GDD reviewed so far has had at least one real
> defect found by independent review).

---

## Traceability Summary

| Status | Count | % |
|--------|-------|---|
| ✅ Covered | 52 | 50.0% |
| ⚠️ Partial | 1 | 1.0% |
| ❌ Gap | 51 | 49.0% |
| **Total** | **104** | **100%** |

All 51 gaps map 1:1 onto the 12 "should-have" Feature/Presentation ADRs that
`architecture.md` already scoped as required-but-not-yet-written. No gap was found
outside that planned set. The 9 "must-have" Foundation/Core ADRs are all drafted
(0002–0010), which is the state `architecture.md`'s own TD sign-off expected at this
point — but see **B2** below: drafted is not the same as Accepted, and Accepted is the
actual gate condition.

**Finding A1 (stale document)**: `architecture.md`'s own "Traceability Coverage Check"
section still reads "1 of 104 covered / 103 gaps" and marks all 21 systems as GAP. This
directly contradicts the same document's header, which already lists ADR-0002 through
ADR-0010. The section was never re-synced after those 9 ADRs were written. Needs a
refresh pass so the master architecture doc doesn't report 103 phantom gaps to anyone
reading it after this review.

---

## Full Traceability Matrix

### Auth & Account (`design/gdd/auth-account.md`) — ADR-0002

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-auth-account-001 | Max 4 child profiles; PIN = parent-controlled child access | ADR-0002 | ✅ |
| TR-auth-account-002 | Parent-only Firebase Auth; child = Firestore doc, no child Auth UID | ADR-0002 | ✅ |
| TR-auth-account-003 | PBKDF2-HMAC-SHA256 100k iterations, 16-byte per-child salt, never bare SHA-256 | ADR-0002 | ✅ |
| TR-auth-account-004 | PIN fail-lockout 3→60s in flutter_secure_storage, survives force-close | ADR-0002 | ✅ |
| TR-auth-account-005 | `sessionStateProvider` derived 4-state enum = sole routing source of truth | ADR-0002 | ✅ |
| TR-auth-account-006 | Parent override via `reauthenticateWithCredential`, does not dispose child session | ADR-0002 | ✅ |
| TR-auth-account-007 | Cloud Function `onChildProfileDelete` recursive Admin-SDK delete | ADR-0002 | ✅ |
| TR-auth-account-008 | FCM `onTokenRefresh` → `families/{parentId}.fcmToken` | ADR-0002 | ✅ |
| TR-auth-account-009 | `resetChildPin()` fresh salt/hash, reset failCount, no session kick | ADR-0002 | ✅ |

### Time & Decay (`design/gdd/time-decay.md`) — ADR-0005

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-time-decay-001 | Energy computed on app-foreground only, no background timer | ADR-0005 | ✅ |
| TR-time-decay-002 | Decay = f(now − lastApprovedAt), no per-second recompute, pure function | ADR-0005 | ✅ |
| TR-time-decay-003 | Clock-manipulation guard: clamp hoursElapsed to [0, 168] | ADR-0005 | ✅ |
| TR-time-decay-004 | Pure calculation, zero Firestore writes, exposes `energyProvider` | ADR-0005 | ✅ |

> ⚠️ **GDD Revision Flag applied to this system** — see "GDD Revision Flags" section below. Status covered structurally by ADR-0005, but the GDD's own code snippet (Core Rule 2, line 35) still contains the bug the ADR corrected.

### Item Database (`design/gdd/item-database.md`) — ADR-0006

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-item-database-001 | Global top-level `items/{itemId}` collection, not family-scoped | ADR-0006 | ✅ |
| TR-item-database-002 | One-time `get()` + session `FutureProvider` (not `.autoDispose`, not `snapshots()`) | ADR-0006 | ✅ |
| TR-item-database-003 | Read-only Security Rule (`allow read`, `write: if false`) | ADR-0006 | ✅ |
| TR-item-database-004 | Catalog hard cap 500 items (MVP 30) before pagination needed | ADR-0006 | ✅ |

### Data Persistence Layer (`design/gdd/data-persistence-layer.md`) — ADR-0003

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-data-persistence-001 | Offline persistence + unlimited cache set once in `main()` via `PersistentCacheSettings` | ADR-0003 | ✅ |
| TR-data-persistence-002 | Complete schema: families/children/tasks/customTasks/inventory | ADR-0003 | ✅ |
| TR-data-persistence-003 | Atomic write contracts (approve = `runTransaction`, buy = `WriteBatch`) | ADR-0003 | ✅ |
| TR-data-persistence-004 | All balance/counter mutation via `FieldValue.increment()` | ADR-0003 | ✅ |
| TR-data-persistence-005 | Cloud Function `onTaskApproved` enforces `storedEnergy` cap 100 | ADR-0003 | ✅ |
| TR-data-persistence-006 | Cloud Function `onChildProfileDelete` recursive delete | ADR-0003 | ✅ |
| TR-data-persistence-007 | Security Rules scoped `request.auth.uid == parentId` | ADR-0003 | ✅ |
| TR-data-persistence-008 | Document size budget < 1MB | ADR-0003 | ✅ |

> ⚠️ **GDD Revision Flag applied to this system** — see below. The GDD's own Security Rules block (lines 199–209) still contains only the pre-ADR-0009 blanket wildcard rule; it was never synced with ADR-0009's amendment.

### Flutter-Flame State Bridge (`design/gdd/flutter-flame-state-bridge.md`) — ADR-0004

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-bridge-001 | `GameEventBus` pure-Dart broadcast singleton, app-lifetime | ADR-0004 | ✅ |
| TR-bridge-002 | `GameEvent` typed per-type payload, one-way Flutter→Flame | ADR-0004 | ✅ |
| TR-bridge-003 | `ref.listen` is the sanctioned bridge adapter | ADR-0004 | ✅ |
| TR-bridge-004 | Flame subscriber `isMounted` guard + `cancel()` in `onRemove()` | ADR-0004 | ✅ |
| TR-bridge-005 | Background→foreground replay-last-state per event type (not full history) | ADR-0004 | ✅ |
| TR-bridge-006 | Measured end-to-end latency avg 151ms / max 439ms (spike-validated) | ADR-0004 | ✅ |

> ⚠️ **GDD Revision Flag applied to this system** — see below. Acceptance Criteria (line ~203) still says subscription happens "trong `onLoad()`", contradicting the corrected Core Rule 5 (`onMount()`).

### Pet State Machine (`design/gdd/pet-state-machine.md`) — ADR-0007

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-petstate-001 | Two-layer model: persistent Base Mood + transient Triggered State | ADR-0007 | ✅ |
| TR-petstate-002 | Mood = pure lookup on energy float (owned here per ADR-0005 delegation) | ADR-0007 | ✅ |
| TR-petstate-003 | Priority ordering + non-interruptible LEVELING_UP | ADR-0007 | ✅ |
| TR-petstate-004 | Triggered timers pause/resume correctly across app background | ADR-0007 | ✅ |

### Currency System (`design/gdd/currency-system.md`) — ADR-0008

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-currency-001 | Single currency (xu), no dual-currency/IAP/ad-reward | ADR-0008 | ✅ |
| TR-currency-002 | All balance mutation via `FieldValue.increment()` | ADR-0008 | ✅ |
| TR-currency-003 | ≥0 floor enforced pre-write by consumer + screen-level single-flight guard | ADR-0008 | ✅ |
| TR-currency-004 | `xuBalanceProvider` realtime stream scoped to active child | ADR-0008 | ✅ |

### Task Library (`design/gdd/task-library.md`) — ADR-0009

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-tasklib-001 | Lifecycle pending→approved/rejected, no cancelled state | ADR-0009 | ✅ |
| TR-tasklib-002 | Reward-integrity guard: Security Rule validates against category reward table at create-time | ADR-0009 | ✅ |
| TR-tasklib-003 | `customTasks` templates structurally distinct from task instances | ADR-0009 | ✅ |
| TR-tasklib-004 | `pendingTasksProvider` / `taskHistoryProvider` composite-indexed queries | ADR-0009 | ✅ |
| TR-tasklib-005 | Reward values data-driven, never client-settable | ADR-0009 | ✅ |

### Push Notification System (`design/gdd/push-notification.md`) — ADR-0010

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-pushnotif-001 | Create-only Firestore trigger (`onDocumentCreated`, 2nd-gen) | ADR-0010 | ✅ |
| TR-pushnotif-002 | FCM payload: notification + data + platform-priority | ADR-0010 | ✅ |
| TR-pushnotif-003 | iOS one-shot permission request; reminder deep-links to Settings | ADR-0010 | ✅ |
| TR-pushnotif-004 | No dedup/idempotency infra — accepted duplicate-notification tradeoff | ADR-0010 | ✅ |
| TR-pushnotif-005 | Deep-link URI contract `petquest://parent/tasks/pending` | ADR-0010 | ✅ |
| TR-pushnotif-006 | Latency <10s typical / <60s hard threshold; fire-and-forget, no attempt-count retry | ADR-0010 | ✅ |

### Parent Approval System (`design/gdd/parent-approval.md`) — ADR-0004 (partial), rest ❌ GAP

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-parentapproval-001 | Single `runTransaction` assembling all reward writes atomically | — | ❌ |
| TR-parentapproval-002 | Idempotency read (`status == 'pending'`) first inside the transaction | — | ❌ |
| TR-parentapproval-003 | One transaction per task; no Approve-All batch | — | ❌ |
| TR-parentapproval-004 | `lastApprovedAt = serverTimestamp()` written on approve | — | ❌ |
| TR-parentapproval-005 | `chestDelta` = level-up-chest + gacha-milestone-chest, additive not suppressive | — | ❌ |
| TR-parentapproval-006 | Reject transaction (same idempotency guard) + `rejectedAt` field | — | ❌ |
| TR-parentapproval-007 | `taskApproved` is its own GameEventType, distinct payload from `petMoodChanged` | ADR-0004 | ✅ |
| TR-parentapproval-008 | Unified transaction-failure handling, no auto-retry loop | — | ❌ |

### Gacha / Loot System (`design/gdd/gacha-loot.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-gacha-001 | Free chest awarded at `approvedTaskCount % 5 == 0` | — | ❌ |
| TR-gacha-002 | Loot roll 70% item / 30% xu, injectable RNG for testability | — | ❌ |
| TR-gacha-003 | Duplicate-item re-roll once, then 10 xu consolation | — | ❌ |
| TR-gacha-004 | `chestCount` decrement via `FieldValue.increment(-1)` (shared-field-safe) | — | ❌ |
| TR-gacha-005 | Client-side roll accepted for MVP (no server-side Cloud Function) | — | ❌ |

### Shop System (`design/gdd/shop-system.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-shop-001 | Catalog filter by source (shop\|both); owned-item badge | — | ❌ |
| TR-shop-002 | Affordability check + atomic batch purchase | — | ❌ |
| TR-shop-003 | Purchase idempotency — `WriteBatch` is not idempotent on `xuBalance` under concurrent duplicate purchase; needs `runTransaction` (tracked as **QQ-01**) | — | ❌ |
| TR-shop-004 | Paid Chest purchase + `onAnimationComplete` handoff to ceremony | — | ❌ |

### Pet Interaction System (`design/gdd/pet-interaction.md`) — ADR-0004 §3b (partial), rest ❌ GAP

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-petinteraction-001 | `TapCallbacks`/`DragCallbacks`; emits `petInteracted` directly (Flame→Bus→Flame, sanctioned reverse-direction case) | ADR-0004 §3b | ⚠️ |
| TR-petinteraction-002 | Per-type cooldown (tap 1.0s, swipe 2.0s) | — | ❌ |
| TR-petinteraction-003 | Swipe detection thresholds (≥40dp, ≤300ms) | — | ❌ |
| TR-petinteraction-004 | No persistent-data mutation from interaction; 80×80dp minimum hit area | — | ❌ |

### Pet Equipment System (`design/gdd/pet-equipment.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-petequip-001 | `equippedItems` Map<slot,itemId>, slot never null (default base items) | — | ❌ |
| TR-petequip-002 | One `SpriteComponent` overlay per slot; z-index base < body < accessory < hat | — | ❌ |
| TR-petequip-003 | Ownership check (`inventoryProvider.contains`) is caller's obligation before equip | — | ❌ |
| TR-petequip-004 | `itemEquipped` event triggers SHOWING_OFF state | — | ❌ |

### Pet Leveling & Evolution (`design/gdd/pet-leveling-evolution.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-leveling-001 | `totalXuEarned` increment-only counter | — | ❌ |
| TR-leveling-002 | 5 levels / 3 evolution stages; thresholds 150/400/900/1800 | — | ❌ |
| TR-leveling-003 | xuBonus per level-up | — | ❌ **(GDD self-contradictory — see Blocking Issue B1)** |
| TR-leveling-004 | `chestCount += 1` per level-up (shared field, also written by Gacha) | — | ❌ |
| TR-leveling-005 | `evolutionStage` recomputed as a pure function of `petLevel` on every load (not a one-shot side effect) | — | ❌ |

### Main Navigation Shell (`design/gdd/main-navigation-shell.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-navshell-001 | `GoRouter` root, `StatefulShellRoute` with 2 branches (child/parent) | — | ❌ |
| TR-navshell-002 | Route guard reads `sessionStateProvider` only, never re-derives session state | — | ❌ |
| TR-navshell-003 | `activeChildBranchIndexProvider` is the sole "is this tab active" signal | — | ❌ |
| TR-navshell-004 | Root-navigator push required for non-dismissible full-screen overlays (Chest ceremony) | — | ❌ |

### Pet Room Screen UI (`design/gdd/pet-room-screen-ui.md`) — ADR-0001 (partial), rest ❌ GAP

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-petroom-001 | Screen composition z-order; `GameWidget` hosts exactly one `FlameGame` | — | ❌ |
| TR-petroom-002 | Flame draw-call budget contract (5 draw calls = 2.5% of the 200 budget) | ADR-0001 | ✅ |
| TR-petroom-003 | Tap hit-area padding formula (`hitBoxSize` ≥ 80dp regardless of sprite size) | — | ❌ |
| TR-petroom-004 | Modal defer when Wardrobe open or a competing GameEvent arrives | — | ❌ |
| TR-petroom-005 | Never call FlameGame init/reset on tab return (StatefulShellRoute keeps tabs mounted) | — | ❌ |

### Task Management UI (`design/gdd/task-management-ui.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-taskui-001 | Pending list reversed client-side to oldest-first (source query is newest-first), cap display at 10 | — | ❌ |
| TR-taskui-002 | Staggered catch-up animation `total_duration` formula (approve + reject symmetric) | — | ❌ |
| TR-taskui-003 | Tab-switch interrupt detection via `activeChildBranchIndexProvider` (not widget lifecycle) | — | ❌ |
| TR-taskui-004 | Task-creation reward derived from category table, never child-settable | — | ❌ |

### Shop & Reward UI (`design/gdd/shop-reward-ui.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-shopui-001 | Composition layer over Shop + Gacha + Currency on one route; header always visible | — | ❌ |
| TR-shopui-002 | `navLocked` guard driven by `onAnimationComplete` callback, timer only as fallback ceiling | — | ❌ |
| TR-shopui-003 | Chest ceremony is a non-dismissible full-screen modal via the ROOT navigator | — | ❌ |
| TR-shopui-004 | Purchase→ceremony (2800/3600ms) and ceremony→equip-prompt (250ms) handoff timing | — | ❌ |

### Parent Dashboard UI (`design/gdd/parent-dashboard-ui.md`) — ❌ GAP (no ADR yet)

| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-parentdash-001 | Pending list uncapped; Approve/Reject button state machine matches #11 exactly | — | ❌ |
| TR-parentdash-002 | FCM banner defer-during-modal + coalesce/`unseenCount` state machine | — | ❌ |
| TR-parentdash-003 | `targetChildId` auto-assignment for single-child families | — | ❌ |
| TR-parentdash-004 | Reset PIN dialog calls `resetChildPin()` (real PIN-entry field, not a bare confirm) | — | ❌ |

---

## Coverage Gaps → Suggested ADRs

| Gap TRs | Suggested ADR Title | Domain | Engine Risk |
|---|---|---|---|
| TR-seedbuffer-001..003 | Seed Buffer Derivation Strategy | Data/derived-state | LOW |
| TR-parentapproval-001,002,003,004,005,006,008 | Parent Approval Transaction Design | Concurrency/economy | LOW-MEDIUM |
| TR-gacha-001..005 | Gacha/Loot Roll Architecture | Economy/RNG | LOW |
| TR-shop-001..004 | Shop Purchase Pipeline & Idempotency Fix (resolves QQ-01) | Economy/concurrency | MEDIUM |
| TR-petinteraction-002..004 | Pet Interaction Input Handling | Flame input | MEDIUM |
| TR-petequip-001..004 | Pet Equipment Ownership & Rendering | Flame rendering | LOW-MEDIUM |
| TR-leveling-001..005 | Pet Leveling & Evolution Consistency | Progression | LOW engine / **HIGH design** (must resolve B1) |
| TR-navshell-001..004 | Navigation Shell & Route Guard | Flutter routing | MEDIUM |
| TR-petroom-001,003,004,005 | Pet Room Rendering & Interaction Contract | Flame canvas | MEDIUM-HIGH |
| TR-taskui-001..004 | Task Management UI Data & Interrupt | Flutter state | LOW-MEDIUM |
| TR-shopui-001..004 | Shop/Reward Ceremony UI State | Flutter nav | MEDIUM |
| TR-parentdash-001..004 | Parent Dashboard Banner State Machine | Flutter/FCM | LOW-MEDIUM |

---

## Cross-ADR Conflicts

No data-ownership, integration-pattern, performance-budget, or dependency-cycle
conflicts were found across the 10 ADRs. `docs/registry/architecture.yaml` cleanly
assigns a single owner to every piece of shared state (`xu_balance`, `current_energy`,
`firestore_schema`, `task_reward_table`, `pet_base_mood`, etc.), and every field two
systems both write (`chestCount`, `seedCount`) uses `FieldValue.increment()`,
documented as race-safe by design.

**Verified, not just claimed**: ADR-0009's amendment of ADR-0003 §5 (blanket wildcard →
explicit per-collection Security Rules) is genuinely present in ADR-0003's current text
(the "Amended 2026-07-08 (ADR-0009)" block, with the `tasks` match block annotated
"reward-gated — see ADR-0009 §3"). This is not a stale claim.

### C1 — Shop purchase idempotency (live tension, unresolved by any ADR)

ADR-0003 mandates purchase = `WriteBatch`. `shop-system.md` AC-9 requires the `xuBalance`
debit happen exactly once under a concurrent duplicate purchase; the GDD's own Edge Case
already admits `WriteBatch` cannot guarantee this and recommends `runTransaction`.
ADR-0008 closes only the honest-client double-tap case (screen-level single-flight
guard) and explicitly defers the concurrent/modified-client case to the not-yet-written
"Shop Purchase Pipeline & Idempotency Fix" ADR. This is the project's already-tracked
**QQ-01 / TR-shop-003**. Not blocking today (no ADR claims to have solved it), but it is
the single highest-value gap to close next given it is a live ADR-vs-GDD tension, not
just an unwritten decision.

---

## ADR Dependency Order

Collected `Depends On` fields:

```
ADR-0001 → none
ADR-0002 → none
ADR-0003 → 0002
ADR-0004 → 0002
ADR-0005 → 0003
ADR-0006 → 0003, 0002
ADR-0007 → 0004, 0005
ADR-0008 → 0003, 0002
ADR-0009 → 0003, 0002, 0008
ADR-0010 → 0003, 0002, 0009
```

**Topological order (acyclic, verified — no cycles)**:

```
1. ADR-0001  (no deps)
2. ADR-0002  (no deps)
3. ADR-0003  (requires 0002)
4. ADR-0004  (requires 0002)
5. ADR-0005  (requires 0003)
6. ADR-0006  (requires 0002, 0003)
7. ADR-0008  (requires 0002, 0003)
8. ADR-0007  (requires 0004, 0005)
9. ADR-0009  (requires 0002, 0003, 0008)
10. ADR-0010 (requires 0002, 0003, 0009)
```

**Status blocker (not a structural cycle, a gate-condition gap)**: ADR-0001 is the only
Accepted ADR. ADR-0002–0010 are all **Proposed**, and every one of them depends
(directly or transitively) on ADR-0002. `architecture.md`'s own TD sign-off condition
("implementation must not begin until the 9 must-have ADRs are written **and
Accepted**") is not yet met — they are written, not Accepted. Accept in the topological
order above, starting with ADR-0002.

Also verified: ADR-0005's own precondition note ("should not reach Accepted
independently of the `parent-approval.md` B1 lastApprovedAt fix") — that fix **is**
already applied (`parent-approval.md` Core Rule 2 writes `lastApprovedAt`), so ADR-0005
has no remaining blocker of its own beyond the general Accept-in-order gate.

---

## Engine Compatibility Issues

Validated independently by a `flame-specialist` consultation reading the same ADR and
GDD files directly (not trusting the first pass's summary).

- **Version consistency**: all 10 ADRs declare Flutter 3.44.4 / Flame 1.37.0. Confirmed. ✅
- **No deprecated API adoption**: `HasGameRef`, `TapDetector`,
  `Settings(persistenceEnabled:/cacheSizeBytes:)` appear only as explicit "do NOT use"
  references. Confirmed. ✅
- **All 10 ADRs have an Engine Compatibility section**. Confirmed. ✅
- **Post-cutoff API consistency**: `Settings(cacheSettings: PersistentCacheSettings(...))`
  for Firestore persistence (ADR-0003); Flame lifecycle via `onMount`/`isMounted`/
  `onRemove` (never `onLoad`, ADR-0004 §4, ADR-0007); `TapCallbacks` (ADR-0007);
  `pauseWhenBackgrounded=true` default relied on (ADR-0007); FCM `requestPermission()` +
  2nd-gen `onDocumentCreated` (ADR-0010). No two ADRs make contradictory assumptions
  about the same post-cutoff API. Confirmed. ✅
- **ADR-0004's `onMount()`-not-`onLoad()` subscription model**: confirmed accurate
  against real Flame 1.37 component lifecycle. `onMount`/`onRemove` are guaranteed
  1:1-paired (including on `changeParent()` reparenting), so there is no
  double-subscription risk in the model as specified.
- **ADR-0007's auto-pause claim**: confirmed accurate. `GameRenderBox`'s
  `WidgetsBindingObserver` calls `pauseEngine()` on background, stopping the Flame
  ticker, so `TimerComponent`/`Timer` correctly pause/resume with zero extra wiring.
  This is a Flutter `AppLifecycleState` mechanism, not an Impeller/rendering-backend
  concern — no iOS/Android divergence exists here, and the ADR is correct not to invoke
  one. Note for later: this only pauses the Flame component tree, not Flutter overlay
  widgets — moot while backgrounded, but worth remembering if a future BGM ADR wants
  audio to continue backgrounded (ADR-0007's own Risk section already flags this
  correctly as a future constraint to coordinate with `flame-audio-specialist`).
- **ADR-0001's "no runtime draw-call counter" claim**: confirmed still true for Flame
  1.37 — no built-in instrumentation exists; manual design-time tally + platform-native
  profilers (Xcode Metal System Trace / Android GPU Inspector) is the correct fallback.

### Confirmed live gaps (found by both independent passes)

1. **`data-persistence-layer.md` lines 199–209**: contains only the original blanket
   wildcard rule (`match /families/{parentId}/{document=**} { allow read, write: if
   request.auth.uid == parentId; }`). There is no nested `tasks`-specific block in this
   file at all — it was never synced with either ADR-0003 §5's amended rules or
   ADR-0009 §3's reward gate. Deploying rules straight from this GDD file today would
   reproduce exactly the vulnerability ADR-0009 exists to close (unconditional write
   access to `xuReward`/`categoryId` on task documents). Neither ADR-0003's nor
   ADR-0009's Migration Plan tasked anyone with fixing this specific file — the fix was
   only ever applied inside the ADR documents' own inline rule listings.
2. **`time-decay.md` line 35 (Core Rule 2)**: still reads
   `hoursElapsed = (now - lastApprovedAt).inMinutes / 60.0` — invalid Dart (`DateTime`
   has no `operator-`; must be `.difference()`) with a truncation bias
   (`.inMinutes` drops sub-minute precision). ADR-0005 §2 identifies and replaces this
   exact pattern with `elapsed.inMicroseconds / Duration.microsecondsPerHour`, but its
   Migration Plan only tasked correcting Core Rule 4 (the energy→mood table annotation)
   — Core Rule 2's actual formula snippet was never touched.
3. **`flutter-flame-state-bridge.md` line ~203 (Acceptance Criteria)**: still states
   subscription happens "trong `onLoad()`", directly contradicting the corrected Core
   Rule 5 (`onMount()`, with an inline rationale note already present at line 82). Verified
   directly via grep — both the fixed Core Rule 5 and the stale AC coexist in the same file.

These three are addressed under **GDD Revision Flags** below.

---

## Architecture Document Coverage

- **System coverage**: all 21 MVP systems appear in `architecture.md`'s layer map and
  Module Ownership tables; Vertical-Slice/Alpha/Full-Vision systems are explicitly
  excluded with a note. No orphaned architecture entries. ✅
- **Data-flow coverage**: the four documented data-flow scenarios (frame update,
  cross-boundary event, save/load, init order) cover the principal cross-system paths
  named across the 21 GDDs. Adequate.
- **A1 (already noted above)**: `architecture.md`'s Traceability Coverage Check and
  Required ADRs sections are stale — need re-sync to this review's actual 52/104
  coverage and to mark the 9 must-have ADRs as authored.
- **A2 (minor stale note)**: `pet-room-screen-ui.md` Formula 1 still says the draw-call
  scope is "interpretation, chưa phải ADR chính thức" and recommends a future ADR —
  ADR-0001 now *is* that ADR (and ratifies exactly this GDD's own reading). The note is
  obsolete and should be updated to cite ADR-0001 directly.

---

## GDD Revision Flags (Architecture → Design Feedback)

These GDD assumptions conflict with verified engine behavior or accepted ADR decisions.
Confirmed by two independent passes (general-purpose extraction + `flame-specialist`
re-verification against actual Flame 1.37/Firestore behavior and actual current file
text). The GDDs should be revised before their systems re-enter implementation.

| GDD | Assumption in GDD | Reality (from ADR / verified engine behavior) | Action |
|---|---|---|---|
| `time-decay.md` (line 35, Core Rule 2) | `hoursElapsed = (now - lastApprovedAt).inMinutes / 60.0` | `DateTime` has no `operator-` (invalid Dart); `.inMinutes` truncates sub-minute precision. ADR-0005 §2 mandates `.difference().inMicroseconds / Duration.microsecondsPerHour` | Revise GDD |
| `data-persistence-layer.md` (lines 199–209, Security Rules block) | Blanket `match /families/{parentId}/{document=**}` grants unconditional write to all subcollections including `tasks/` | ADR-0009 §3 verified Firestore rules OR across matching blocks (any allow = allowed) — this wildcard makes any stricter nested rule inert. Registered forbidden pattern `blanket_recursive_firestore_rule` | Revise GDD |
| `flutter-flame-state-bridge.md` (line ~203, Acceptance Criteria) | AC states subscription happens "trong `onLoad()`" | ADR-0004 §4 verified (Flame 1.37 source): `isMounted` is false throughout `onLoad()`, silently dropping events; Core Rule 5 was already corrected to `onMount()` (line 67–82) but this AC was left stale | Revise GDD |

**Systems-index update applied** (approved by user, this session): rows #2 (Time &
Decay), #4 (Data Persistence Layer), #5 (Flutter-Flame State Bridge) in
`design/gdd/systems-index.md` changed from `Approved` → `Needs Revision`. Progress
Tracker "Design docs approved" updated from 21 to 18, with a note explaining the 3
flagged systems.

---

## Verdict: CONCERNS

The Foundation/Core architecture (10 ADRs) is internally coherent, version-consistent,
and free of cross-ADR conflicts — including a genuinely-applied amendment (ADR-0009 →
ADR-0003 §5) rather than a merely-claimed one. However, **PASS is not warranted**: the
9 core ADRs are all still Proposed (the coding gate is unmet), 12 Feature/Presentation
ADRs remain unwritten (51 requirement gaps, all within the already-planned scope), and
independent review surfaced concrete defects — most seriously a self-contradicting
formula in `pet-leveling-evolution.md` and three GDDs still teaching code/config the
ADRs have verified as broken on the pinned Flutter 3.44.4/Flame 1.37.0 combination.

### Blocking Issues (must resolve before this can PASS)

1. **B1 — `pet-leveling-evolution.md` xuBonus is internally contradictory.** Core Rule
   2's table gives xuBonus L2/L3/L4/L5 = **+50/+80/+120/+200**; the Formula and Tuning
   Knob give `xuBonus = level×25+25` = **+75/+100/+125/+150**; the Acceptance Criteria
   (line 188) uses **+75**. Three different values for the same quantity, and Parent
   Approval's transaction grants `xuBonus(newLevel)` with no single fixed source. Must
   be reconciled — in both the GDD and the future Pet Leveling ADR — before any leveling
   story is implementable.
2. **B2 — Core ADRs not Accepted.** ADR-0002 through ADR-0010 are Proposed; the entire
   dependency chain roots on ADR-0002. Accept in the topological order above before
   implementation begins, per the TD sign-off condition in `architecture.md`.
3. **B3 — `data-persistence-layer.md` still teaches the exact Security Rules pattern
   ADR-0009 forbids** (blanket recursive wildcard). Must sync this GDD's rules block to
   ADR-0003 §5 (amended) + ADR-0009 §3 before anyone deploys rules copied from it.
4. **B4 — Shop idempotency (C1 / TR-shop-003 / QQ-01) unresolved.** Needs the Shop
   Purchase Pipeline & Idempotency Fix ADR.
5. **B5 — `architecture.md`'s own traceability section is stale** (A1): reports 103
   phantom gaps against the 9 already-drafted ADRs. Re-sync before using that document
   as a coverage reference.

### Required ADRs (prioritized)

1. **Accept** ADR-0002, then 0003, 0004, 0005, 0006, 0008, 0007, 0009, 0010 (topological
   order) — closes B2.
2. Write **Shop Purchase Pipeline & Idempotency Fix** (resolves QQ-01/TR-shop-003/C1) —
   highest-value gap; live ADR-vs-GDD tension already exists.
3. Write **Pet Leveling & Evolution Consistency** — must resolve B1's xuBonus
   contradiction as part of the ADR.
4. Write **Parent Approval Transaction Design** — only 1 of 8 TRs currently covered.
5. Write **Gacha/Loot Roll Architecture**, **Pet Equipment Ownership & Rendering**,
   **Pet Interaction Input Handling**, **Seed Buffer Derivation Strategy**, then the four
   Presentation-layer ADRs (**Navigation Shell & Route Guard**, **Pet Room Rendering &
   Interaction Contract**, **Task Management UI Data & Interrupt**, **Shop/Reward
   Ceremony UI State**, **Parent Dashboard Banner State Machine**) before each
   corresponding system enters implementation.

---

## Ambiguous Matches / Judgment Calls (for the record)

1. **TR-petinteraction-001 marked ⚠️ Partial**, not ✅. ADR-0004 §3(b) explicitly
   sanctions Pet Interaction's direct Flame→Bus→Flame `emit`, but no ADR yet ratifies
   the interaction *system* itself (cooldowns, swipe thresholds, hit-area sizing). A
   stricter reviewer could count the whole system as gap instead (51→53 gaps, 52→51
   covered). Kept as Partial since the emit contract genuinely is architecturally
   settled.
2. **Verdict boundary CONCERNS vs FAIL.** 51/104 (49%) uncovered reads FAIL on a raw
   percentage basis, but every gap is a planned, already-scoped Feature/Presentation
   ADR — none represents an unplanned discovery. Weighted toward CONCERNS given the
   coherent, conflict-free Foundation/Core layer. A reviewer who treats "9 core ADRs
   still Proposed" as a hard gate failure on its own would tip this to FAIL — flagging
   explicitly since the user, not this review, owns that threshold call.

---

## Session Extract — `/architecture-review` 2026-07-11

- Verdict: **CONCERNS**
- Requirements: 104 total — 52 covered, 1 partial, 51 gaps
- New TR-IDs registered: 104 (first real entries in `tr-registry.yaml`, previously empty)
- GDD revision flags: `time-decay.md`, `data-persistence-layer.md`, `flutter-flame-state-bridge.md`
- Top ADR gaps: Shop Purchase Pipeline & Idempotency Fix (QQ-01), Pet Leveling & Evolution Consistency (must resolve B1), Parent Approval Transaction Design
- Report: `docs/architecture/architecture-review-2026-07-11.md`
