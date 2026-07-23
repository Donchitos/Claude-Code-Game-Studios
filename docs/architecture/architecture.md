# PetQuest — Master Architecture

## Document Status
- Version: 1.1
- Last Updated: 2026-07-13
- Engine: Flutter 3.44.4 / Flame 1.37.0 / Dart 3.12.2
- GDDs Covered: 21 MVP-tier system GDDs (see `design/gdd/systems-index.md`)
- ADRs Referenced: ADR-0001 (draw-call budget scope for Flame-canvas-hosting screens — Accepted); ADR-0002 (Auth & PIN Security Architecture — Accepted); ADR-0003 (Firestore Schema & Persistence Strategy — Accepted; amended by ADR-0009 §5); ADR-0004 (Flutter-Flame Event Bridge Architecture — Accepted); ADR-0005 (Time & Decay Calculation Strategy — Accepted); ADR-0006 (Item Catalog Data Access Pattern — Accepted); ADR-0007 (Pet State Machine Architecture — Accepted); ADR-0008 (Currency & Balance Mutation Rules — Accepted); ADR-0009 (Task Lifecycle & Reward Integrity — Accepted; amends ADR-0003 §5); ADR-0010 (Push Notification Delivery Architecture — Accepted); ADR-0011 (Shop Purchase Pipeline & Idempotency Fix — Accepted; amends ADR-0003 atomic write contracts)
- Technical Director Sign-Off: 2026-07-07 — APPROVED WITH CONDITIONS (implementation must not begin until the 9 "must have" Foundation/Core ADRs are written and Accepted — see Required ADRs). **Condition met 2026-07-11**: all 9 must-have ADRs (0002–0010) plus ADR-0001 are Accepted. ADR-0011 (should-have, Shop layer) written and Accepted 2026-07-11, closing the QQ-01 idempotency gap.
- Lead Programmer Feasibility: LP-FEASIBILITY skipped — Lean review mode (not a PHASE-GATE)
- Gate History: `/gate-check pre-production` passed 2026-07-13 (verdict CONCERNS) — see `production/gate-checks/gate-check-2026-07-13.md`. Control Manifest generated same day — see `docs/architecture/control-manifest.md`.

## Engine Knowledge Gap Summary

LLM training cutoff: ~Flutter 3.19 / Flame 1.14 (May 2025). Project pinned to Flutter 3.44.4 / Flame 1.37.0 — MEDIUM-HIGH overall risk band per `docs/engine-reference/flutter-flame/VERSION.md`.

**MEDIUM risk domains** (verify key APIs against engine reference before implementation):
- **Rendering** — Impeller is now the default backend (iOS since 3.22, selective Vulkan-capable Android since 3.27). Affects any screen hosting a `GameWidget`/`FlameGame` canvas.
- **Platform / Navigation** — Android edge-to-edge display is enforced (Flutter 3.35+). Affects any `Scaffold`-based screen.
- **Flame Component Lifecycle** — modern idiom uses `findGame()`/`isMounted` rather than cached game references (`HasGameRef`). Affects any component that subscribes to cross-boundary events or timers.

**LOW risk domains** (in training data, no significant post-cutoff change):
- Flame `Vector2` 32-bit change (1.27) — not exercised by PetQuest (no physics/shader math)
- `TapDetector` → `TapCallbacks` migration (Flame 1.21+) — mechanical rename, low ambiguity

Per user direction (Phase 0d): these domains are flagged inline throughout this document rather than blocking on a pre-verification pass.

## System Layer Map

```
┌───────────────────────────────────────────────────────────────────────┐
│ PRESENTATION LAYER                                                    │
│  Main Navigation Shell (#17) · Pet Room Screen UI (#18)                │
│  Task Management UI (#19) · Shop & Reward UI (#20) · Parent Dashboard  │
│  UI (#21)                                                              │
├───────────────────────────────────────────────────────────────────────┤
│ FEATURE LAYER                                                          │
│  Seed Buffer (#10) · Parent Approval (#11) · Gacha/Loot (#12)          │
│  Shop System (#13) · Pet Interaction (#14) · Pet Equipment (#15)       │
│  Pet Leveling & Evolution (#16)                                        │
├───────────────────────────────────────────────────────────────────────┤
│ CORE LAYER                                                             │
│  Data Persistence Layer (#4) · Flutter-Flame State Bridge (#5)         │
│  Currency System (#7) · Pet State Machine (#6) · Task Library (#8)     │
│  Push Notification (#9)                                                │
├───────────────────────────────────────────────────────────────────────┤
│ FOUNDATION LAYER                                                       │
│  Auth & Account (#1) · Item Database (#3) · Time & Decay (#2)          │
├───────────────────────────────────────────────────────────────────────┤
│ PLATFORM LAYER                                                         │
│  Flutter SDK 3.44.4 · Flame 1.37.0 · Firebase (Firestore/FCM/Auth) ·   │
│  iOS / Android OS                                                      │
└───────────────────────────────────────────────────────────────────────┘
```

Vertical-Slice/Alpha/Full-Vision-tier systems (Background Music, SFX, Onboarding, Settings, Friend/Visit/Gift/Leaderboard, Decoration DB, Room Layout, Analytics) are excluded from this pass — they will slot into the same layers when designed.

## Module Ownership

### Foundation Layer

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| Auth & Account (#1) | Parent Firebase Auth session; child profiles (PIN hash+salt, avatar, name); PIN lockout state (`flutter_secure_storage`); `sessionStateProvider` | `sessionStateProvider`, `activeChildProvider`, `resetChildPin()` | firebase_auth SDK | firebase_auth ^5.x (Platform, not Flutter/Flame risk) |
| Item Database (#3) | Global `items/{itemId}` catalog | `itemCatalogProvider` (cached FutureProvider) | Firestore one-time `get()` | cloud_firestore ^5.x |
| Time & Decay (#2) | Nothing persistent (pure calculation) | `computeEnergy(lastApprovedAt, now)` | `lastApprovedAt` (owned by Data Persistence) | None |

### Core Layer

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| Data Persistence Layer (#4) | Firestore schema, WriteBatch/Transaction contracts, offline persistence config | Repository functions (`approveTask()`, `buyItem()`), path constants | Auth (parentId), all domain models | `CACHE_SIZE_UNLIMITED` setting — ⚠️ MEDIUM: must be set once in `main()` before any Firestore call |
| Flutter-Flame State Bridge (#5) | `GameEventBus` singleton, `GameEvent` typed contract | `GameEventBus.instance.stream` / `.fire()` | Riverpod `ref.listen` (one-way Flutter→Flame) | Flame `Component.isMounted`/`onRemove()` — ⚠️ MEDIUM: use `findGame()`/`isMounted` idiom, not cached `HasGameRef` |
| Currency System (#7) | `xuBalance` (increment-only) | `xuBalanceProvider` (realtime) | Data Persistence's increment contract | `FieldValue.increment()` |
| Pet State Machine (#6) | Base Mood + Triggered State, triggered-state timers | `petStateProvider`, mood lookup | Time & Decay's energy float | Flame `TimerComponent` — ⚠️ MEDIUM: pause/resume across app background must be verified against Flame 1.37 lifecycle |
| Task Library (#8) | `tasks` lifecycle (pending/approved/rejected), `customTasks`, reward lookup table | `pendingTasksProvider`, `taskHistoryProvider` | Data Persistence's query/write contracts | Firestore composite queries (status + orderBy + range — needs composite index) |
| Push Notification (#9) | FCM token registration, Cloud Function trigger contract | Payload contract, deep-link URI scheme | Auth's `fcmToken`, Task Library's create-event | firebase_messaging ^15.x — ⚠️ MEDIUM (iOS): `requestPermission()` one-shot |

### Feature Layer

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| Seed Buffer (#10) | Nothing persistent (derived, drift-correctable counter) | `seedCountProvider` | Task Library's `tasks` collection | None |
| Parent Approval (#11) | The approve/reject transaction | `approveTask()`, `rejectTask()` | Task Library, Pet Leveling (level-up calc), Currency (write), Bridge (fires `taskApproved`) | `runTransaction()` — LOW |
| Gacha/Loot (#12) | RNG roll logic, `chestCount` decrement | `openChest()` | Shop's `inventoryProvider` (dup check), Currency (`chestCount`) | Injectable `Random` — none engine-specific |
| Shop System (#13) | `inventory/{itemId}`, purchase pipeline | `inventoryProvider`, `purchaseItem()` | Item DB, Currency | WriteBatch — ⚠️ KNOWN GAP (TR-shop-003): needs `runTransaction` upgrade (open architectural gap, not a version risk) |
| Pet Interaction (#14) | Tap/swipe cooldown timers, gesture thresholds | Interaction events → Pet State | Pet State (gating) | Flame `TapCallbacks`/`DragCallbacks` — ⚠️ MEDIUM: `TapDetector` deprecated since Flame 1.21 |
| Pet Equipment (#15) | `equippedItems: Map<slotId,itemId>` | `equippedItemsProvider`, `equipItem()` | Shop's `inventoryProvider` (ownership check) | Flame `SpriteComponent` overlay + z-index — LOW |
| Pet Leveling & Evolution (#16) | `totalXuEarned`, `petLevel`, evolution-stage derivation | `petLevelProvider`, evolution lookup | Parent Approval's transaction scope | None (pure function) |

### Presentation Layer

| Module | Owns | Exposes | Consumes | Engine APIs |
|---|---|---|---|---|
| Main Navigation Shell (#17) | Route tree, `activeChildBranchIndexProvider` | Nav actions, branch-active state | `sessionStateProvider` | `go_router` `StatefulShellRoute` (LOW); Scaffold edge-to-edge — ⚠️ MEDIUM: needs `SafeArea` (Flutter 3.35+ enforcement) |
| Pet Room Screen UI (#18) | `GameWidget` + persistent `FlameGame` instance | Nothing (leaf screen) | Bridge, Pet State, Pet Equipment | Flame Canvas rendering — ⚠️ MEDIUM-HIGH: Impeller default backend, governed by ADR-0001's draw-call budget but pipeline behavior needs device testing |
| Task Management UI (#19) | Nothing (pure presentation) | Nothing | `pendingTasksProvider`, `seedCountProvider`, `activeChildBranchIndexProvider` | None |
| Shop & Reward UI (#20) | `navLocked` screen-scoped state | Nothing | Shop, Gacha, Pet Equipment, Pet Leveling (4 providers) | Root-navigator push — LOW |
| Parent Dashboard UI (#21) | FCM foreground-banner state machine (`unseenCount` coalescing) | Nothing | Push Notification (foreground stream), Task Library | firebase_messaging foreground listener — LOW-MEDIUM (shares iOS one-shot dependency above) |

### Dependency Diagram

```
PLATFORM: Flutter/Flame/Firebase/OS
  │
FOUNDATION: Auth(1)  ItemDB(3)  Time&Decay(2)
  │
CORE: DataPersist(4) ← Bridge(5)  Currency(7)  PetState(6) ← Time&Decay  TaskLib(8)  PushNotif(9) ← Auth
  │
FEATURE: SeedBuffer(10)←TaskLib  ParentApproval(11)←TaskLib,PetLvl,Currency,Bridge  Gacha(12)←Shop,Currency
         Shop(13)←ItemDB,Currency  PetInteraction(14)←PetState  PetEquip(15)←Shop  PetLeveling(16)←ParentApproval
  │
PRESENTATION: NavShell(17)←Auth  PetRoom(18)←Bridge,PetState,PetEquip  TaskUI(19)←TaskLib,SeedBuffer,NavShell
              ShopUI(20)←Shop,Gacha,PetEquip,PetLeveling  ParentDash(21)←PushNotif,TaskLib
```

## Data Flow

### 1. Frame Update Path (touch input → render, in-process)

Scenario: player taps the pet in Pet Room Screen.

```
User taps pet sprite
  → Flame TapCallbacks.onTapDown (Pet Interaction #14)
  → cooldown check (1.0s tap / 2.0s swipe) — reject if within cooldown
  → Pet Interaction mutates Pet State Machine (#6) directly (same FlameGame instance)
  → Pet State Machine checks Triggered-State priority (LEVELING_UP is non-interruptible —
     interaction ignored if active)
  → sets Triggered State (e.g. HAPPY_BOUNCE), starts Flame TimerComponent
  → next frame: sprite swap render
  → TimerComponent expires → reverts to state derived from Base Mood
```

Synchronous, no Firestore round-trip — Pet Interaction and Pet State Machine are both plain Dart objects inside the same `FlameGame`.

### 2. Event/Signal Path (cross-boundary: Flutter widget → Flame canvas)

Scenario: parent approves a task while child is in Pet Room.

```
Parent taps Approve (#21, Flutter widget tree)
  → Parent Approval (#11).approveTask(taskId)
  → runTransaction() [Data Persistence #4]: read (idempotency check) → write status='approved' →
     FieldValue.increment(xuBalance, storedEnergy) → write chestDelta
  → commit → Firestore snapshot listeners fire
  → xuBalanceProvider, petLevelProvider update via ref.listen
  → GameEventBus.fire(GameEvent.taskApproved) — the ONLY sanctioned bridge adapter point
  → Pet Room's Flame subscriber (isMounted-guarded) receives event
  → Pet State Machine → LEVELING_UP if applicable (non-interruptible)
  → measured latency: avg 151ms / max 439ms (TR-bridge-006, validated real data)
```

No manual thread-boundary handling needed — the Firestore plugin marshals snapshot callbacks onto the Dart event loop automatically.

### 3. Save/Load Path

Scenario: cold start → child selects profile → Pet Room loads.

```
main(): Firestore persistenceEnabled=true, cacheSizeBytes=CACHE_SIZE_UNLIMITED (must precede any Firestore call)
→ Auth restores session → sessionStateProvider updates
→ child PIN entry → sessionStateProvider = childSelected
→ Item DB: itemCatalogProvider.get() — one-time, session-cached (NOT snapshots())
→ Data Persistence opens snapshot listeners scoped to activeChildProvider
   (xuBalance, petState, pendingTasks, equippedItems, inventory)
→ Time & Decay: computeEnergy() — one-shot on app-foreground, no running timer
→ Pet Room mounts FlameGame, reads current provider values — never calls an init/reset method (TR-petroom-005)
```

No separate "save" step — every mutation is an immediate Firestore write. "Load" = re-subscribing to snapshot listeners; offline cache serves stale-but-valid data until reconnect. Background→foreground resume replays only the LAST known state per event type (TR-bridge-005), not a history log.

### 4. Initialization Order

```
1. Flutter binding + Firebase.initializeApp()
2. Firestore settings (persistenceEnabled, CACHE_SIZE_UNLIMITED) — before any Firestore read/write
3. Auth — restore session or show login
4. GameEventBus — app-lifetime singleton, constructed once at app root (never per-screen)
5. go_router — route guard reads sessionStateProvider
6. On child selection: Data Persistence opens snapshot listeners scoped to activeChildProvider
7. Item Database — fetched lazily on first Shop/Equipment visit (not required for Pet Room)
8. Pet Room Screen — FlameGame constructed only when branch becomes active; never disposed on
   tab switch (StatefulShellRoute)
```

## API Boundaries

These are the highest-invariant contracts programmers implement against — not an exhaustive listing of all 21 modules' exposed surfaces (see Module Ownership above for the full Exposes/Consumes map).

### 1. `sessionStateProvider` (Auth #1)

```dart
enum SessionState { unauthenticated, parentAuthed, childSelected, parentView }
Provider<SessionState> sessionStateProvider;
```
- Invariant: this is the ONLY routing source of truth — `go_router`'s redirect logic must read only this, never Auth internals directly.
- Guarantee: parent-override flow transitions to `parentView` without disposing the active child session (`childSelected` state is preserved underneath).

### 2. `GameEventBus` / `GameEvent` (Bridge #5) — the central cross-boundary contract

```dart
class GameEventBus {
  static GameEventBus get instance;
  Stream<GameEvent> get stream;
  void fire(GameEvent event);
}
class GameEvent {
  final GameEventType type; // enum: taskApproved, petMoodChanged, levelUp, ...
  final dynamic data;       // payload shape is type-specific, never shared across types
}
```
- Invariant: strictly one-way Flutter→Flame. No Flame component may call back into `.fire()`.
- Invariant: each `GameEventType` has its own payload shape — `taskApproved` and `petMoodChanged` must never share a payload type (TR-parentapproval-007).
- Guarantee: `ref.listen` is the only sanctioned adapter that calls `.fire()` — no other call site is permitted.
- Caller obligation: every Flame-side subscriber must guard with `isMounted` and call `cancel()` in `onRemove()` (TR-bridge-004).

### 3. Data Persistence transaction contracts (#4, invoked by Parent Approval #11 / Shop #13 / Gacha #12 / Pet Equipment #15)

```dart
Future<ApproveResult> approveTask(String taskId);   // runTransaction — idempotency read FIRST
Future<void> rejectTask(String taskId);
Future<PurchaseResult> purchaseItem(String itemId); // ⚠️ currently WriteBatch — KNOWN GAP, see below
Future<void> equipItem(String slotId, String itemId);
```
- Invariant (`approveTask`): the read of `status == 'pending'` MUST be the first statement inside the transaction body, not a pre-check outside it (TR-parentapproval-002) — prevents the double-approve race.
- Invariant: one transaction per task — no batched "Approve All" (TR-parentapproval-003).
- Guarantee: `approveTask` bundles `petLevel`+`xuBonus`+`chestCount`+`storedEnergy` atomically; callers never see a partially-applied reward.
- ⚠️ Open gap: `purchaseItem` uses `WriteBatch`, not `runTransaction` — duplicate-purchase race on `xuBalance` is NOT currently idempotent (TR-shop-003). Flagged as a Required ADR in Phase 6, not resolved here.
- Invariant (`equipItem`): caller MUST check `inventoryProvider.contains(itemId)` before calling — this function does not re-validate ownership itself (TR-petequip-003).

### 4. Realtime stream providers

```dart
StreamProvider<int> xuBalanceProvider;          // scoped to activeChildProvider
StreamProvider<PetState> petStateProvider;
StreamProvider<Set<String>> inventoryProvider;  // O(1) ownership lookup
StreamProvider<Map<String,String>> equippedItemsProvider; // every slot has non-null default
StreamProvider<List<Task>> pendingTasksProvider; // composite query, descending order
```
- Guarantee: all of these are `snapshots()`-backed and scoped to `activeChildProvider` — switching child profiles automatically re-scopes every one of them.
- Invariant: nothing outside Data Persistence writes to the underlying documents directly — all mutation goes through the transaction/batch contracts above.

### 5. `activeChildBranchIndexProvider` (Navigation #17)

```dart
Provider<int> activeChildBranchIndexProvider; // which StatefulShellRoute branch is foregrounded
```
- Invariant: this, not widget dispose/lifecycle, is the only valid way for a screen to detect "am I still the active tab?" — `StatefulShellRoute` branches are never disposed on tab switch (TR-navshell-003, TR-taskui-003, TR-petroom-005).

## ADR Audit

### ADR Quality Check

| ADR | Engine Compat | Version | GDD Linkage | Conflicts | Valid |
|---|---|---|---|---|---|
| ADR-0001: Draw-Call Budget Scope | ✅ | ✅ (Flutter 3.44.4/Flame 1.37.0) | ✅ (Pet Room Screen UI #18) | None — consistent with this session's Module Ownership entry for #18 | ✅ |

### Traceability Coverage Check

> **Re-synced 2026-07-13** (was stale since 2026-07-07 — reported 1/104 despite the header already listing ADRs 0002–0010; see `/architecture-review` 2026-07-11 report and `/gate-check pre-production` 2026-07-13 for the full independently-verified traceability matrix at `docs/architecture/architecture-review-2026-07-11.md` and `docs/architecture/traceability-index.md`).

Full 104-row Technical Requirements Baseline was extracted in Phase 0b (see `production/session-state/active.md` history / this document's git history for the source table). **56 of 104** requirements are now fully ADR-covered, **1 is partial** (well-defined but its system's remaining TRs await a Feature-layer ADR), **47 are gaps** — all 47 map 1:1 to the 11 not-yet-written "should-have" ADRs below (no unplanned discovery).

| System | TR count | ADR Coverage | Status |
|---|---|---|---|
| Auth & Account (#1) | 9 | 9/9 — ADR-0002 | ✅ FULL |
| Time & Decay (#2) | 4 | 4/4 — ADR-0005 | ✅ FULL |
| Item Database (#3) | 4 | 4/4 — ADR-0006 | ✅ FULL |
| Data Persistence (#4) | 8 | 8/8 — ADR-0003 | ✅ FULL |
| Bridge (#5) | 6 | 6/6 — ADR-0004 | ✅ FULL |
| Pet State Machine (#6) | 4 | 4/4 — ADR-0007 | ✅ FULL |
| Currency (#7) | 4 | 4/4 — ADR-0008 | ✅ FULL |
| Task Library (#8) | 5 | 5/5 — ADR-0009 | ✅ FULL |
| Push Notification (#9) | 6 | 6/6 — ADR-0010 | ✅ FULL |
| Seed Buffer (#10) | 3 | — | ❌ GAP |
| Parent Approval (#11) | 8 | 1/8 — ADR-0004 (event-type contract only) | ⚠️ PARTIAL |
| Gacha/Loot (#12) | 5 | — | ❌ GAP |
| Shop System (#13) | 4 | 4/4 — ADR-0011 | ✅ FULL |
| Pet Interaction (#14) | 4 | 4/4 — ADR-0004 §3b (001) + ADR-0016 (002-004) | ✅ FULL |
| Pet Equipment (#15) | 4 | — | ❌ GAP |
| Pet Leveling (#16) | 5 | — | ❌ GAP |
| Nav Shell (#17) | 4 | — | ❌ GAP |
| Pet Room UI (#18) | 5 | 5/5 — ADR-0001 (TR-petroom-002, draw-call budget) + ADR-0017 (TR-petroom-001/003/004/005) | ✅ FULL |
| Task Mgmt UI (#19) | 4 | — | ❌ GAP |
| Shop/Reward UI (#20) | 4 | — | ❌ GAP |
| Parent Dashboard UI (#21) | 4 | — | ❌ GAP |

**Count: 56 covered, 1 partial, 47 gaps.**

Every gap becomes a Required New ADR, grouped by layer (each ADR scoped to one system so no TR is left uncovered):

**Foundation layer — ✅ ALL WRITTEN AND ACCEPTED:**
- ~~Auth & PIN Security Architecture~~ — ADR-0002, Accepted — covers TR-auth-account-001..009
- ~~Time & Decay Calculation Strategy~~ — ADR-0005, Accepted — covers TR-time-decay-001..004
- ~~Item Catalog Data Access Pattern~~ — ADR-0006, Accepted — covers TR-item-database-001..004

**Core layer — ✅ ALL WRITTEN AND ACCEPTED:**
- ~~Firestore Schema & Persistence Strategy~~ — ADR-0003, Accepted (amended by ADR-0009 §5) — covers TR-data-persistence-001..008
- ~~Flutter-Flame Event Bridge Architecture~~ — ADR-0004, Accepted — covers TR-bridge-001..006
- ~~Pet State Machine Architecture~~ — ADR-0007, Accepted — covers TR-petstate-001..004
- ~~Currency & Balance Mutation Rules~~ — ADR-0008, Accepted — covers TR-currency-001..004
- ~~Task Lifecycle & Reward Integrity~~ — ADR-0009, Accepted — covers TR-tasklib-001..005
- ~~Push Notification Delivery Architecture~~ — ADR-0010, Accepted — covers TR-pushnotif-001..006

**Feature layer — 1 of 7 written:**
- Seed Buffer Derivation Strategy — covers TR-seedbuffer-001..003 — **not yet written**
- Parent Approval Transaction Design — covers TR-parentapproval-001..006,008 (007 already covered by ADR-0004) — **not yet written**
- Gacha/Loot Roll Architecture — covers TR-gacha-001..005 — **not yet written**
- ~~Shop Purchase Pipeline & Idempotency Fix~~ — **ADR-0011, Accepted (2026-07-11)** — covers TR-shop-001..004, closes QQ-01
- ~~Pet Interaction Input Handling~~ — **ADR-0016, Accepted (2026-07-23)** — covers TR-petinteraction-002..004 (001 already covered by ADR-0004 §3b)
- Pet Equipment Ownership & Rendering — covers TR-petequip-001..004 — **not yet written**
- Pet Leveling & Evolution Consistency — covers TR-leveling-001..005 — **not yet written**

**Presentation layer — 0 of 5 written:**
- Navigation Shell & Route Guard Architecture — covers TR-navshell-001..004 — **not yet written**
- ~~Pet Room Screen Rendering & Interaction Contract~~ — **ADR-0017, Accepted (2026-07-23)** — covers TR-petroom-001,003,004,005 (002 already covered by ADR-0001)
- Task Management UI Data & Interrupt Handling — covers TR-taskui-001..004 — **not yet written**
- Shop/Reward Ceremony UI State Management — covers TR-shopui-001..004 — **not yet written**
- Parent Dashboard Notification Banner State Machine — covers TR-parentdash-001..004 — **not yet written**

## Required ADRs

Same 20 required ADRs identified in the ADR Audit above, regrouped by priority. **12 of 20 written and Accepted as of 2026-07-23** (all 9 must-have + 2 should-have, ADR-0011 and ADR-0016 — note: ADRs 0012–0015 also now exist for other systems in this should-have list but this summary line has not been re-audited against them; see Pet Interaction's own row above, which is verified current as of this edit).

**Must have before coding starts** (Foundation & Core layer — everything downstream depends on these) — **✅ ALL 9 ACCEPTED, condition met 2026-07-11**:
1. ~~Auth & PIN Security Architecture~~ — ADR-0002 ✅
2. ~~Time & Decay Calculation Strategy~~ — ADR-0005 ✅
3. ~~Item Catalog Data Access Pattern~~ — ADR-0006 ✅
4. ~~Firestore Schema & Persistence Strategy~~ — ADR-0003 ✅
5. ~~Flutter-Flame Event Bridge Architecture~~ — ADR-0004 ✅
6. ~~Pet State Machine Architecture~~ — ADR-0007 ✅
7. ~~Currency & Balance Mutation Rules~~ — ADR-0008 ✅
8. ~~Task Lifecycle & Reward Integrity~~ — ADR-0009 ✅
9. ~~Push Notification Delivery Architecture~~ — ADR-0010 ✅

**Should have before the relevant system is built** (Feature + Presentation layer — needed before that specific system's implementation starts, not before all coding) — **2 of 12 done** (plus ADRs 0012–0015 exist for other should-have systems, not yet re-tallied here):
10. Seed Buffer Derivation Strategy — not yet written
11. Parent Approval Transaction Design — not yet written
12. Gacha/Loot Roll Architecture — not yet written
13. ~~Shop Purchase Pipeline & Idempotency Fix~~ — **ADR-0011 ✅ (2026-07-11)**
14. ~~Pet Interaction Input Handling~~ — ADR-0016 ✅ (2026-07-23)
15. Pet Equipment Ownership & Rendering — not yet written
16. Pet Leveling & Evolution Consistency — not yet written
17. Navigation Shell & Route Guard Architecture — not yet written
18. Pet Room Screen Rendering & Interaction Contract — not yet written
19. Task Management UI Data & Interrupt Handling — not yet written
20. Shop/Reward Ceremony UI State Management — not yet written
21. Parent Dashboard Notification Banner State Machine — not yet written

**Can defer to implementation:** None. Every gap identified in this architecture pass is a substantive system-level decision (data ownership, concurrency, or security) — none are the kind of low-stakes, easily-reversible tactical choice this category is meant for.

## Architecture Principles

1. **Single source of truth for cross-layer state** — every piece of state has exactly one owning module; other modules read via a stream/provider, never write directly (e.g. `xuBalance` increment-only, `inventoryProvider` ownership gate, `sessionStateProvider` as sole routing SoT).
2. **One-way Flutter→Flame event flow** — the Flame canvas never mutates Flutter/Riverpod state directly; all cross-boundary communication flows through `GameEventBus` in one direction via the sanctioned `ref.listen` adapter.
3. **Immediate persistence, no explicit save step** — every player-visible mutation (approve, purchase, equip) is an atomic Firestore write at the moment it happens; there is no separate "save game" action to reason about.
4. **Transactions for state that must not race, batches for state that can't** — read-then-write invariants (idempotency checks, level-up calculations) always use `runTransaction`; independent field increments use `WriteBatch`/`FieldValue.increment()`. (Shop's TR-shop-003 gap was a violation of this principle, resolved by ADR-0011 2026-07-11 — Shop purchases now use `runTransaction` gated on a natural key or client-generated idempotency token.)
5. **Design-time measurement over runtime instrumentation** — where the engine doesn't expose a runtime metric (Flame draw calls, Flutter widget compositing cost), GDDs and ADRs use a manual, code-reviewable design-time tally instead of inventing an unverifiable number (established by ADR-0001).

## Open Questions

| ID | Summary | Priority | Resolution Path |
|---|---|---|---|
| QQ-01 | Shop purchase idempotency gap (TR-shop-003) — `WriteBatch` allows duplicate-purchase race on `xuBalance` | High | Shop Purchase Pipeline & Idempotency Fix ADR |
| QQ-02 | Impeller rendering behavior on target hardware not yet device-profiled (3 passes required per ADR-0001 Validation Criteria) | Medium | Device profiling pass once Pet Room Screen UI ships |
| QQ-03 | FCM push retry has no dedup/idempotency infra — accepted MVP tradeoff (TR-pushnotif-004), unclear if acceptable long-term | Low | Revisit in Push Notification Delivery Architecture ADR |
| QQ-04 | Paid Chest purchase needs an `onAnimationComplete` callback (TR-shop-004) that doesn't exist on any current rendering component | Medium | Define in Shop Purchase Pipeline ADR or a rendering-side follow-up |
