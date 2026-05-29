# BRAWLZONE — Master Architecture

## Document Status

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | 2026-05-29 |
| **Engine** | React Native (Expo SDK) + Node.js |
| **GDDs Covered** | All 45 system GDDs (cross-review PASS 2026-05-29) |
| **ADRs Referenced** | None yet — see §Required ADRs |
| **Technical Director Sign-Off** | 2026-05-29 — APPROVED WITH CONDITIONS (ADR-0001 must be first) |
| **Lead Programmer Feasibility** | Skipped (lean mode) |

---

## Engine Knowledge Gap Summary

```
Engine:         React Native (Expo SDK) + Node.js
LLM Cutoff:     May 2025
Risk Level:     LOW — all core dependencies within training data

HIGH RISK:  NONE
MEDIUM RISK: NONE
LOW RISK:   React Native, Expo SDK, Socket.io v4, Supabase JS,
            Node.js HTTP/WS, RevenueCat SDK, AdMob, PostgreSQL, Redis

Advisory: Verify expo-notifications and react-native-google-mobile-ads
          against Expo changelog for any post-May-2025 API changes.
```

---

## Architecture Principles

Five principles govern all technical decisions:

1. **Server is authoritative, client is display.** No game logic, no economy math, no combat resolution on the client. The client sends inputs and renders server state. This is not negotiable — it is the anti-cheat foundation and the design invariant.

2. **Idempotency everywhere in economy.** Every grant, debit, or entitlement write is keyed with a unique idempotency key. A duplicate key silently returns the prior result. No grant can be double-applied. This extends to IAP, quests, battle pass, and match rewards.

3. **Profile:refresh is the single client update trigger.** The client never polls for economy or entitlement changes. The server pushes `profile:refresh` via Socket.io on any profile mutation. The client invalidates its cache on receipt. No exception.

4. **Content Catalog is the source of truth at rest.** All character IDs, ability IDs, mode IDs, IAP pack IDs, and prices live in `content-catalog.md` as canonical records. No hardcoded strings in code; all lookups go through `IContentCatalog.get(canonicalId)`.

5. **Fan-out never blocks match end.** Model B: MMR fires synchronously with a 3000ms timeout (timeout → mmrDelta=0 → proceed). After MMR, all economy systems (Reward, XP, Quest, Battle Pass) fire in parallel via `Promise.allSettled()`. `match_end` is sent to the client immediately after the fan-out is initiated — the client does not wait for economy settlement.

---

## System Layer Map

BRAWLZONE is a client-server mobile game with two distinct runtime stacks. Standard game engine layers are adapted accordingly.

### Client Stack (React Native / Expo — iOS + Android)

```
┌─────────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER (React Native Screens + Navigation)             │
│  Main Menu · Lobby · Character/Deck Select · In-Match HUD ·         │
│  Match Results · Shop & Offers · Settings & Accessibility ·         │
│  Tutorial / Onboarding                                               │
├─────────────────────────────────────────────────────────────────────┤
│  FEATURE LAYER (Client-Side Game Logic)                              │
│  Match State Consumer (interpolation) · HUD State Manager ·         │
│  Economy UI State · Loadout Builder UI · Character Select Logic ·   │
│  Party/Presence UI                                                   │
├─────────────────────────────────────────────────────────────────────┤
│  CORE LAYER (Client Infrastructure)                                  │
│  Socket.io Client (connection lifecycle, event routing) ·            │
│  Profile Store (Zustand / React Context, cache + invalidation) ·    │
│  Inventory Cache · Remote Config Reader                              │
├─────────────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER (Platform Adapters)                                │
│  Supabase Auth Client (JWT storage + refresh) ·                     │
│  API Client (HTTP + retry + JWT injection) ·                        │
│  RevenueCat SDK · AdMob SDK · Expo Notifications                     │
├─────────────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                                      │
│  iOS / Android · Expo SDK · React Native Runtime                    │
└─────────────────────────────────────────────────────────────────────┘
```

### Server Stack (Node.js + Supabase / PostgreSQL / Redis)

```
┌─────────────────────────────────────────────────────────────────────┐
│  FEATURE LAYER (Economy + Social Systems)                           │
│  Match Flow (fan-out orchestrator) · Reward System ·                │
│  XP & Progression · Quest/Mission · Battle Pass ·                   │
│  Currency System · Inventory/Entitlements ·                         │
│  Purchase Fulfillment · IAP System · Cosmetic/Skin ·                │
│  Ad System · Push Notification · Party/Presence ·                   │
│  MMR/Ranked · Moderation/Reporting                                   │
├─────────────────────────────────────────────────────────────────────┤
│  CORE LAYER (Real-Time Game Infrastructure)                         │
│  Match Server (20Hz authoritative simulation) ·                     │
│  Session Manager · Matchmaking Engine ·                             │
│  Disconnect Handler · Reconnect/Resume · Bot AI ·                   │
│  Combat Resolver                                                     │
├─────────────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER (Server Infrastructure)                            │
│  JWT Validator · REST API Router · Socket.io Server ·               │
│  Content Catalog Service · Character System ·                       │
│  Ability Registry · Game Mode Config · Deck/Loadout Validator ·     │
│  Player Profile Service                                              │
├─────────────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                                      │
│  Node.js Runtime · PostgreSQL (Supabase) · Redis ·                  │
│  RevenueCat API (webhook receiver) · Expo Push API                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Cross-Cutting (Ops Layer — both sides)

```
Analytics/Telemetry · Remote Config · Logging/Monitoring ·
Anti-Cheat/Validation (Full Vision, server-side)
```

### System → Layer Assignment

| System | Runtime | Layer |
|--------|---------|-------|
| Authentication | Both | Foundation (client SDK + server JWT validator) |
| API Client | Client | Foundation |
| Real-time Transport (Socket.io) | Both | Foundation (server) / Core (client) |
| Player Profile & Persistence | Server-primary, client-cached | Foundation (server) / Core (client) |
| Content Catalog | Server-primary, client-cached | Foundation (server) |
| Remote Config / Live Tuning | Server-primary | Ops |
| Analytics / Telemetry | Both | Ops |
| Logging / Monitoring | Server | Ops |
| Session Manager | Server | Core |
| Match Server | Server | Core |
| Matchmaking Engine | Server | Core |
| Disconnect Handler | Server | Core |
| Reconnect / Resume | Server | Core |
| Bot / Fallback AI | Server | Core |
| Combat Resolver | Server | Core |
| Character System | Server (data) / Client (display) | Foundation (server) |
| Deck / Loadout | Server (validate) / Client (build) | Foundation (server) / Feature (client) |
| Ability / Skill | Server | Foundation (data), Core (cooldown) |
| Game Mode System | Server | Foundation (config), Core (runtime) |
| Map / Arena | Server | Foundation (config), Core (spatial) |
| Match Flow | Server | Feature |
| MMR / Ranked | Server | Feature |
| Currency System | Server | Feature |
| Reward System | Server | Feature |
| XP & Progression | Server | Feature |
| Quest / Mission | Server | Feature |
| IAP System | Server | Feature |
| Battle Pass / Play Pass | Server | Feature |
| Inventory / Entitlements | Server | Feature |
| Purchase Fulfillment | Server | Feature |
| Cosmetic / Skin | Server | Feature |
| Ad System | Both | Feature (server validate) / Foundation (client SDK) |
| Push Notification | Server | Feature |
| Party / Presence | Both | Feature |
| Main Menu & Navigation | Client | Presentation |
| Lobby & Team Formation | Client | Presentation |
| Character / Deck Select | Client | Presentation |
| In-Match HUD | Client | Presentation |
| Match Results Screen | Client | Presentation |
| Shop & Offers Screen | Client | Presentation |
| Settings & Accessibility | Client | Presentation |
| Tutorial / Onboarding | Both | Presentation (client) / Feature (server state) |
| Moderation / Reporting | Server | Feature |
| Anti-Cheat / Validation | Server | Ops (Full Vision) |

---

## Module Ownership

### SERVER FOUNDATION LAYER

| Module | Owns | Exposes | Consumes |
|--------|------|---------|----------|
| **JWT Validator** | Token verification logic | `validateToken(jwt): UserId \| AuthError` | Supabase public key (env) |
| **REST API Router** | Route→handler mapping | HTTP endpoints `/v1/*` | JWT Validator, Feature handlers |
| **Socket.io Server** | WebSocket room management, per-socket auth context | `io.to(roomId).emit()`, `socket.on()` | JWT Validator |
| **Content Catalog Service** | All canonical records; remote overlay cache | `catalog.get(id)`, `catalog.getAll(type)`, `catalog.applyOverlay()` | PostgreSQL, Remote Config |
| **Character System** | CharacterDefinition validation, passive-state init | `char.getDefinition(id)`, `char.getInitialPassiveState(id)`, `char.tickPassive(state, ctx)` | Content Catalog |
| **Ability Registry** | 18 canonical ability definitions, cooldown defaults | `ability.get(id)`, `ability.isValid(id)` | Content Catalog |
| **Game Mode Config** | Per-mode config (maxDurationSec, playerCount, winCondition) | `mode.getConfig("duel_1v1" \| "squad_3v3" \| "ffa_8")` | Content Catalog |
| **Deck/Loadout Validator** | Loadout validation rules (slot count, ownership) | `loadout.validate(userId, deck): ValidationResult` | Character System, Ability Registry, Inventory |
| **Player Profile Service** | 26-field player_profiles; Redis profile cache | `getProfile(userId)`, `updateProfile(userId, delta)` + Socket.io `profile:refresh` push | PostgreSQL, Redis |

### SERVER CORE LAYER

| Module | Owns | Exposes |
|--------|------|---------|
| **Session Manager** | Match session lifecycle; MatchConfig construction | `createSession(config)`, `destroySession(id)`, `getSession(id)` |
| **Match Server** | Authoritative game state; 20Hz tick loop; all PlayerState | `startMatch()`, `processInput(playerId, input)`, `broadcastState()`, `onPlayerReconnected(playerId)`, `getSnapshot()`, `tick()` |
| **Matchmaking Engine** | Queue state in Redis sorted sets (per mode); bracket algorithm | `enqueue(userId, mode, mmr)`, `dequeue(userId, reason)`, `pollMatches()` |
| **Disconnect Handler** | RECONNECT_GRACE_PERIOD_S countdown per disconnected player | `onDisconnect(playerId, sessionId)`, `onReconnect(playerId)` |
| **Reconnect/Resume** | Snapshot push on reconnect; reconnect_ack with isConfirmed | `resumeSession(playerId, sessionId): SnapshotPayload` |
| **Bot AI** | Per-tick bot decision loop; probabilistic ability use | `assignBot(slot): BotPlayerId`, `tickBot(playerId, matchState)` |
| **Combat Resolver** | Damage calculation, status effect application, hit detection | `resolveHit(attacker, target, ability): DamageResult`, `applyStatusEffect(target, effect)` |

**Ownership rules enforced across all modules:**
- Match Server NEVER writes to PostgreSQL/Redis — it holds in-memory state only
- Match Flow owns the persistent match record; it reads Match Server output, not the other way around
- Content Catalog is read-only at runtime — `applyOverlay()` called only by Remote Config

### Dependency Diagram (Server)

```
[Content Catalog]
    /    |     \     \
[Char] [Ability] [Mode] [Map]
   |       |        |
[Deck Val]      [Session Mgr]────────────[Match Server]
                    |                        |     |
            [Matchmaking Eng]         [Combat Res] [Bot AI]
                    |                        |
                [Redis]            [Disconnect Hndlr]
                                        |
                                [Reconnect/Resume]

[Match Server] → [Match Flow] → MMR (sync RPC)
                              → Reward   ──┐
                              → XP       ──┤ Promise.allSettled()
                              → Quest    ──┤
                              → BattlePass┘

[All Feature Systems] → [Currency] ──→ [PostgreSQL]
                      → [Inventory] ─→ [PostgreSQL + Redis]
                      → [Player Profile] → [PostgreSQL + Redis]
```

### CLIENT LAYERS

| Module | Owns | Key API |
|--------|------|---------|
| Supabase Auth Client | JWT storage + refresh | `signIn()`, `signUp()`, `getSession()`, `onAuthStateChange()` |
| API Client | HTTP request/response + retry | `get(path)`, `post(path, body)` — injects JWT header |
| Socket.io Client | WebSocket connection lifecycle | `connect(url, {auth: jwt})`, `emit()`, `on()` |
| Profile Store | Cached profile + economy state | `useProfile()`, `invalidateProfile()` |
| Inventory Cache | Client-side owned-items snapshot | `useInventory()`, `hasItem(id)` |
| Match State Consumer | Interpolated PlayerState array at render time | `useMatchState()` — applies interpolation between server ticks |

---

## Data Flow

### Frame Update Path (20Hz Match Loop)

```
CLIENT                          SOCKET.IO               SERVER (Node.js)
  │ touch input                    │                      │
  ├──BASIC_ATTACK / USE_ABILITY──→ │                      │
  │  {targetPlayerId?, aimVector?} │                      │
  │                                ├──player_input──────→ │ Match Server
  │                                │                      │ 1. Queue input (2ms)
  │                                │                      │ 2. Validate (3ms)
  │                                │                      │ 3. Simulate (20ms)
  │                                │                      │   └─ Combat Resolver
  │                                │                      │   └─ Status ticks
  │                                │                      │   └─ Passive ticks
  │                                │                      │   └─ Cooldown decrements
  │                                │                      │ 4. Win Condition (3ms)
  │                                │                      │ 5. State Emit (7ms)
  │                                │←──match_state───────│ Broadcast to all
  │←──interpolate delta────────────│
  │ render at 60fps                │
```

**Communication type**: Fire-and-forget (UDP-over-WS); no ack in hot path.
**Lag compensation**: rewind = `floor(min(playerRtt, 200ms) / 50ms)` ticks; applies to hit detection only.

---

### Match-End Fan-Out (Model B)

```
Match Server          Match Flow          Downstream Systems
     │                    │
     ├──processMatchEnd──→│
     │                    │ ① MMR sync RPC (3000ms timeout)
     │                    ├──updateRatings()─────────────→ MMR System
     │                    │←──mmrDelta[] or timeout→0─────│
     │                    │
     │                    │ ② Promise.allSettled() (parallel)
     │                    ├──grantXP(result)────────────→ XP System
     │                    ├──calculateAndGrant(result)──→ Reward System
     │                    ├──processMatchResult(result)─→ Quest System
     │                    ├──creditBPXP(...)────────────→ Battle Pass
     │                    │
     │                    ├──emit match_end─────────────→ Client (immediate)
```

**Key invariant**: `match_end` fires to client immediately after fan-out is initiated. Client does not wait for economy settlement.

---

### IAP Purchase → Entitlement Chain

```
Client              RevenueCat SDK        RevenueCat Cloud     Server
  │ tap "Buy Colt"      │                       │                │
  ├──Purchases.purchase()→│                     │                │
  │                    │←── receipt ────────────│                │
  │                    │                        ├──INITIAL_PURCHASE webhook──→│
  │                    │                        │                │ Purchase Fulfillment
  │                    │                        │                │ Atomic transaction:
  │                    │                        │                │  a. creditDiamonds +50
  │                    │                        │                │  b. grantItem character:colt
  │                    │                        │                │  c. grantItem skin:colt_default
  │                    │                        │                │  d. update player_profiles flags
  │                    │                        │                │ Invalidate Redis cache
  │                    │                        │                │ Emit profile:refresh
  │←── profile:refresh via Socket.io ───────────────────────────│
  │ Profile Store invalidated → re-fetch → UI updates
```

---

### Authentication + Session Startup

```
Client               Supabase Auth      API Server       Socket.io Server
  │ signIn(email,pw)     │                  │                  │
  ├─────────────────────→│                  │                  │
  │←── JWT ──────────────│                  │                  │
  │ GET /v1/profile ─────────────────────→  │                  │
  │   Authorization: Bearer {jwt}           │validateToken()   │
  │←── player_profiles ─────────────────── │                  │
  │ socket.connect({auth: jwt}) ───────────────────────────→  │
  │                                                 validateToken()
  │←── connected ──────────────────────────────────────────── │
```

---

### Server Initialisation Order

```
1. Config load (env vars, Remote Config cold keys)
2. PostgreSQL connection pool
3. Redis client
4. Content Catalog Service (loads all records into memory)
5. JWT Validator (loads Supabase public key)
6. Character System (validates CharacterDefinitions against catalog)
7. Ability Registry (loads 18 abilities from catalog)
8. Game Mode Config (loads 3 mode configs from catalog)
9. REST API Router + Socket.io Server (accepts connections)
10. Session Manager + Matchmaking Engine (ready for queue joins)
11. [Per-match] Match Server instantiated by Session Manager on demand
```

---

## API Boundaries

### REST API (Client ↔ Server)

```typescript
// AUTH
POST   /v1/auth/register      { email, password } → { userId, jwt }
POST   /v1/auth/login         { email, password } → { jwt, profile }
POST   /v1/auth/refresh       { refreshToken }    → { jwt }
POST   /v1/auth/anonymous                         → { guestId, jwt }
POST   /v1/auth/migrate-guest  { jwt, email, password } → { userId, jwt }

// PROFILE
GET    /v1/profile             → PlayerProfile (excludes diamond_balance, has_play_pass, region)
PATCH  /v1/profile/settings    { settings }        → PlayerProfile
PATCH  /v1/profile/equipped-skins { characterId, skinId } → equippedSkins map

// MATCHMAKING
POST   /v1/matchmaking/queue   { mode: GameMode }  → 200 | 409 already_in_queue
DELETE /v1/matchmaking/queue                       → 200

// ECONOMY
GET    /v1/catalog             → ContentCatalogSnapshot
GET    /v1/inventory           → EntitlementList
POST   /v1/loadout/:characterId { deckSlots: [AbilityId, AbilityId] } → SavedLoadout | 400

// IAP (server-to-server only, RevenueCat signature protected)
POST   /v1/iap/webhook         { ...RevenueCatEvent }

// ADS
POST   /v1/ads/reward-grant    { adToken, adType } → { coinsGranted } | 403
```

### Socket.io Events (Client ↔ Server)

```typescript
// CLIENT → SERVER (after authenticate)
socket.emit('authenticate',        { jwt: string })   // MUST be first event
socket.emit('queue_join',          { mode: "duel_1v1"|"squad_3v3"|"ffa_8" })
socket.emit('queue_cancel')
socket.emit('character_confirmed', { characterId: string, deckSlots: [string, string] })
socket.emit('BASIC_ATTACK',        { targetPlayerId?: string, aimVector?: Vector2 })
socket.emit('USE_ABILITY',         { slotIndex: 0|1, targetPlayerId?: string, aimVector?: Vector2 })

// SERVER → CLIENT
socket.on('match_found',       ({ matchId, gameMode, players: PlayerStub[], expiresAt }))
socket.on('dequeued',          ({ reason: "match_found"|"player_cancelled"|"timeout"|"queue_error" }))
socket.on('match_state',       ({ tick, timestamp, players: PlayerState[], projectiles: ProjectileState[] }))
socket.on('match_end',         ({ matchId, results: PlayerResult[], mmrDeltas: MMRDelta[] }))
socket.on('character_selected',({ playerId, characterId }))
socket.on('profile:refresh',   ({ profile: PlayerProfile }))
socket.on('inventory:updated', ({ entitlements: EntitlementList }))
socket.on('auth_error',        ({ reason: TokenErrorReason }))
socket.on('reconnect_ack',     ({ snapshot: MatchSnapshot, isConfirmed: boolean }))
```

**Critical socket invariants:**
- Client MUST emit `authenticate` before any other event; unauthenticated sockets disconnected after 5s
- `match_found` always beats `queue_cancel` — server-side boolean flag prevents race condition
- Server NEVER trusts client-supplied game state; all inputs are server-validated

### Match Server Internal API

```typescript
interface IMatchServer {
  startMatch(config: MatchConfig): void;
  endMatch(reason: "win" | "time" | "forfeit"): MatchResultsPayload;
  processInput(playerId: string, input: PlayerInput): void;  // queued; processed on next tick
  getSnapshot(): Readonly<MatchSnapshot>;    // deep-frozen; callers must not mutate
  getPlayerState(id: string): PlayerState | null;
  onPlayerReconnected(playerId: string): void;  // only valid during match_state === "active"
  tick(): void;  // called by tick scheduler every 50ms
}
```

### Economy APIs

```typescript
interface ICurrencySystem {
  creditCoins(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance>;
  debitCoins(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance>;
  creditDiamonds(userId: string, amount: number, source: string, idempotencyKey: string): Promise<Balance>;
  // Invariant: duplicate idempotencyKey → returns existing result silently
  // Invariant: creditCoins clamps to 50,000 Coin ceiling
  // Invariant: debitCoins throws InsufficientFundsError if result < 0
}

interface IInventory {
  grantItem(userId: string, itemId: string, idempotencyKey: string): Promise<GrantResult>;
  hasItem(userId: string, itemId: string): Promise<boolean>;  // Redis-first, PostgreSQL fallback
  revokeItem(userId: string, itemId: string): Promise<void>;
  // Invariant: grantItem is idempotent — duplicate key returns { duplicate: true }
  // Invariant: revokeItem on free-character items throws CANNOT_REVOKE_FREE_CHARACTER
  // Invariant: writes to both entitlements table AND player_profiles in same transaction
}

interface IContentCatalog {
  get<T>(id: string): T | null;                  // canonical {type}:{slug} format
  getAll<T>(type: ContentType): T[];
  applyOverlay(map: Record<string, Partial<CatalogRecord>>): void;  // Remote Config only
  // Invariant: read-only at runtime; applyOverlay() called only by Remote Config on refresh
}
```

---

## ADR Audit

No ADRs exist. All 78 Technical Requirements are uncovered.

| ADR | Status | Engine Compat | GDD Linkage | Note |
|-----|--------|--------------|-------------|------|
| (none) | — | — | — | All TRs are gaps |

---

## Required ADRs

### Foundation Layer (must create before any coding)

| ID | Title | GDDs | TRs Covered |
|----|-------|------|-------------|
| ADR-0001 | Client-Server Architecture & Monorepo Structure | All | TR-auth-001, TR-persist-001 |
| ADR-0002 | Real-Time Transport Protocol (Socket.io v4) | realtime-transport, disconnect-handler, reconnect-resume, match-flow | TR-transport-001–005, TR-recon-001–004, TR-flow-005 |
| ADR-0003 | Server-Side Game Loop (Authoritative Simulation & Tick Budget) | match-server, combat-system, ability-skill | TR-matchsrv-001–007, TR-combat-001–006, TR-ability-003 |
| ADR-0004 | Authentication Architecture (Supabase JWT + Token Lifecycle) | authentication, player-profile | TR-auth-001–004 |
| ADR-0005 | Database Architecture (PostgreSQL + Redis Patterns) | player-profile, inventory-entitlements, currency-system | TR-persist-001–004, TR-inv-001–002, TR-econ-001 |
| ADR-0006 | Client State Management (Profile, Inventory, Match State) | player-profile, realtime-transport, match-results | TR-ui-001–006, TR-persist-002–003 |
| ADR-0007 | Content Catalog Architecture (Static Bundle + Remote Overlay) | content-catalog, character-system, ability-skill, game-mode, map-arena, deck-loadout | TR-char-001–004, TR-ability-001–002, TR-mode-001–004, TR-deck-001–003 |

### Core Layer (before relevant system is built)

| ID | Title | GDDs | TRs Covered |
|----|-------|------|-------------|
| ADR-0008 | Economy Transaction Safety (Idempotency + Atomic Grants) | currency-system, inventory-entitlements, reward-system, purchase-fulfillment | TR-econ-001–004, TR-inv-003–004, TR-iap-002–003 |
| ADR-0009 | Matchmaking Architecture (Redis Queues + Bracket Algorithm) | matchmaking-engine, session-manager | TR-mm-001–005 |
| ADR-0010 | Match Flow Fan-Out Pattern (Model B, Promise.allSettled) | match-flow, reward-system, xp-progression, quest-mission, battle-pass, mmr-ranked | TR-flow-001–005 |
| ADR-0011 | IAP Integration (RevenueCat Webhooks + Fulfillment Chain) | iap-system, purchase-fulfillment, inventory-entitlements, currency-system | TR-iap-001–005 |
| ADR-0012 | Session & Match Lifecycle (createSession → startMatch → endMatch) | session-manager, match-server, disconnect-handler, bot-ai | TR-session-001–004 |
| ADR-0013 | Progression & Ability Unlock Gating (XP Gates + Character XP) | xp-progression, character-system, deck-loadout | TR-econ-006–009, TR-char-003 |

### Can Defer to Implementation

| ID | Title | TRs Covered |
|----|-------|-------------|
| ADR-0014 | Push Notification Integration (Expo Notifications) | TR-ops-004 |
| ADR-0015 | Analytics Event Architecture (Fire-and-Forget Event Sink) | TR-ops-002–003 |
| ADR-0016 | Ad SDK Integration (AdMob Initialization Gate) | TR-ops-005 |

**Priority order for writing ADRs:** 0001 → 0004 → 0005 → 0002 → 0003 → 0007 → 0012 → 0006 → 0009 → 0008 → 0010 → 0011 → 0013 → (0014, 0015, 0016 deferrable)

---

## Technical Requirements Baseline

78 requirements across 14 domains. See [Phase 0b extraction above — all are in scope].
TR registry will be populated by `/architecture-review` after ADRs are written.

Quick domain summary:
- Auth (4) · Transport (5) · Match Server (7) · Session (4) · Matchmaking (5)
- Combat (6) · Character + Ability + Deck (10) · Match Flow (5) · Economy (10)
- Inventory + Entitlements (4) · IAP + Fulfillment (5) · Persistence (4)
- Game Modes (4) · Disconnect/Reconnect (4) · UI/Client (6) · Ops (5)

---

## Open Questions

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-01 | Monorepo vs separate repos for mobile client and Node.js server | High | ADR-0001 |
| QQ-02 | Client state manager: Zustand vs Redux vs React Context for profile/inventory/match state | High | ADR-0006 |
| QQ-03 | Content Catalog delivery: static Expo asset bundle vs server-fetch at startup | High | ADR-0007 |
| QQ-04 | PostgreSQL hosted on Supabase (managed) vs self-hosted Supabase docker | Medium | ADR-0005 |
| QQ-05 | Redis managed service (Upstash) vs Redis Labs vs self-hosted | Medium | ADR-0005 |
| QQ-06 | Analytics sink: direct Supabase table vs Segment vs PostHog | Low | ADR-0015 |
| QQ-07 | Whether to use Expo Router (file-based) vs React Navigation for screen routing | Medium | ADR-0006 |
