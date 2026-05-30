# ADR-0001: Client-Server Architecture & Monorepo Structure

## Status

Accepted

## Date

2026-05-29

## Last Verified

2026-05-29

## Decision Makers

Technical Director, Lead Programmer

## Summary

BRAWLZONE is a server-authoritative mobile multiplayer game where the client is a display layer only and all game logic runs on the Node.js server. This ADR establishes the monorepo layout (`mobile/` + `server/`), the five non-negotiable architecture principles, and the module-layer assignment for every system in the game.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React Native (Expo SDK) + Node.js |
| **Domain** | Core / Networking / Scripting |
| **Knowledge Risk** | LOW — in training data |
| **References Consulted** | `docs/engine-reference/react-native/VERSION.md`, `docs/architecture/architecture.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0002, ADR-0003, ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011, ADR-0012, ADR-0013, ADR-0014, ADR-0015, ADR-0016 |
| **Blocks** | All epics — no stories may begin until this ADR is Accepted |
| **Ordering Note** | This is the root ADR. All other ADRs depend on the layer boundaries and principles defined here. |

## Context

### Problem Statement

A real-time mobile multiplayer brawler with ranked competitive modes, IAP economy, and anti-cheat requirements needs an architecture that is server-authoritative from day one. Client-side game logic is trivially exploitable and unacceptable for a ranked game. The architecture must be clear enough that 49 coordinated subagents can each own a domain without stepping on each other.

### Current State

New project. No prior architecture.

### Constraints

- Target platforms: iOS + Android only (no desktop)
- Real-time match transport must achieve 20Hz server tick with ≤200ms effective client lag
- Economy math must never execute on the client (IAP fraud surface)
- Memory ceiling: 200MB on mid-range mobile devices
- Stack: React Native + Expo SDK (client), Node.js (server), Supabase/PostgreSQL, Redis

### Requirements

- All game state mutations happen exclusively on the server
- Client renders interpolated snapshots — no authoritative simulation
- Economy grants are idempotent and atomic; no double-grants possible
- Single socket event triggers client profile refresh; no polling
- Content IDs are canonical strings; no hardcoded display strings in code

## Decision

BRAWLZONE uses a **strict client-server architecture** where the Node.js server is the single source of truth for all game state, economy, and progression. The React Native client is a display-and-input terminal that renders server snapshots and emits player inputs.

### Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│  CLIENT (React Native / Expo — iOS + Android)                          │
│                                                                        │
│  PRESENTATION:  Screens (Main Menu, Lobby, Match HUD, Results, Shop)  │
│  FEATURE:       Match State Consumer · HUD State · Economy UI State   │
│  CORE:          Socket.io Client · Profile Store · Inventory Cache     │
│  FOUNDATION:    Supabase Auth · API Client · RevenueCat · AdMob SDK   │
│  PLATFORM:      Expo SDK → React Native → iOS / Android               │
└────────────────────────────────────────────────────────────────────────┘
              ↑↓ JWT auth        ↑↓ Socket.io v4
┌────────────────────────────────────────────────────────────────────────┐
│  SERVER (Node.js — Railway)                                            │
│                                                                        │
│  FEATURE:    Match Flow · Reward · XP · Quest · Battle Pass ·          │
│              Currency · Inventory · IAP · Cosmetic · Ad · Push ·       │
│              Party/Presence · MMR/Ranked · Moderation                  │
│  CORE:       Match Server (20Hz) · Session Manager ·                  │
│              Matchmaking Engine · Disconnect Handler ·                 │
│              Reconnect/Resume · Bot AI · Combat Resolver               │
│  FOUNDATION: JWT Validator · REST API · Socket.io Server ·            │
│              Content Catalog · Character System · Ability Registry ·   │
│              Game Mode Config · Deck/Loadout Validator · Profile Svc   │
│  PLATFORM:   Node.js → PostgreSQL (Supabase) → Redis                  │
└────────────────────────────────────────────────────────────────────────┘

CROSS-CUTTING: Analytics · Remote Config · Logging/Monitoring · Anti-Cheat (Full Vision)
```

### Monorepo Structure

```
/
├── mobile/          # React Native Expo client
│   ├── app/         # Expo Router screens
│   ├── components/  # Shared UI components
│   ├── services/    # Supabase, Socket.io, API clients
│   └── stores/      # Zustand stores (profile, inventory, match state)
├── server/          # Node.js game server
│   ├── src/
│   │   ├── game/    # Match Server, Bot AI, Combat Resolver
│   │   ├── matchmaking/  # Matchmaking Engine
│   │   ├── economy/ # Currency, Inventory, Reward, IAP, etc.
│   │   ├── socket/  # Socket.io event handlers
│   │   ├── api/     # REST route handlers
│   │   └── db/      # PostgreSQL schema + migrations
│   └── tsconfig.json
├── shared/          # Canonical type definitions shared by client + server
│   └── types.ts     # PlayerState, MatchSnapshot, etc.
└── design/gdd/      # All 45 system GDDs (source of truth for requirements)
```

### Five Architecture Principles (Non-Negotiable)

1. **Server is authoritative, client is display.** No game logic, no economy math, no combat resolution on the client. The client sends inputs and renders server state. This is the anti-cheat foundation and is not negotiable.

2. **Idempotency everywhere in economy.** Every grant, debit, or entitlement write is keyed with a unique idempotency key. A duplicate key silently returns the prior result. No grant can be double-applied.

3. **`profile:refresh` is the single client update trigger.** The client never polls for economy or entitlement changes. The server pushes `profile:refresh` via Socket.io on any profile mutation. The client invalidates its cache on receipt.

4. **Content Catalog is the source of truth at rest.** All character IDs, ability IDs, mode IDs, IAP pack IDs, and prices live in the Content Catalog as canonical records. No hardcoded strings in code; all lookups go through `IContentCatalog.get(canonicalId)`.

5. **Fan-out never blocks match end.** MMR fires synchronously with a 3000ms timeout (timeout → mmrDelta=0 → proceed). After MMR, all economy systems fire in parallel via `Promise.allSettled()`. `match_end` is sent to the client immediately after the fan-out is initiated.

### Key Interfaces

```typescript
// Layer boundary: server never sends game logic to client
// Client only emits inputs; server decides outcomes
type ClientToServerEvent =
  | { event: 'authenticate'; jwt: string }
  | { event: 'queue_join'; mode: GameMode }
  | { event: 'queue_cancel' }
  | { event: 'character_confirmed'; characterId: string; deckSlots: [string, string] }
  | { event: 'BASIC_ATTACK'; targetPlayerId?: string; aimVector?: Vector2 }
  | { event: 'USE_ABILITY'; slotIndex: 0 | 1; targetPlayerId?: string; aimVector?: Vector2 };

type ServerToClientEvent =
  | { event: 'match_state'; tick: number; players: PlayerState[]; projectiles: ProjectileState[] }
  | { event: 'match_end'; results: PlayerResult[]; mmrDeltas: MMRDelta[] }
  | { event: 'profile:refresh'; profile: PlayerProfile }
  | { event: 'reconnect_ack'; snapshot: MatchSnapshot; isConfirmed: boolean };
```

### Implementation Guidelines

- `shared/types.ts` is the canonical location for types used by both client and server. Never duplicate type definitions.
- All server modules must use dependency injection — no module-level singletons that cannot be replaced in tests.
- Match Server holds in-memory state only — it never writes directly to PostgreSQL or Redis.
- Match Flow owns the persistent match record; it reads Match Server output via `endMatch()`.

## Alternatives Considered

### Alternative 1: Client-Side Physics with Server Reconciliation

- **Description**: Client runs authoritative simulation; server periodically corrects divergence.
- **Pros**: Lower server compute; smoother perceived input response.
- **Cons**: Trivially exploitable in a ranked competitive context; requires complex reconciliation logic; inconsistent state between players.
- **Rejection Reason**: Anti-cheat requirement for ranked modes makes client authority unacceptable.

### Alternative 2: Peer-to-Peer Networking

- **Description**: Players connect directly; one player acts as host.
- **Pros**: Zero server infra cost for match simulation.
- **Cons**: Host advantage, host migration complexity, no anti-cheat baseline, NAT traversal complexity on mobile.
- **Rejection Reason**: Ranked integrity and anti-cheat requirements require a neutral server authority.

## Consequences

### Positive

- All game logic is testable in isolation (Node.js unit tests, no device required)
- Anti-cheat baseline is the architecture itself — server never trusts client state
- Client can be rebuilt independently without changing server logic

### Negative

- Match Server is a performance-critical hot path (50ms tick budget, 200MB memory ceiling)
- Server infra cost scales with concurrent match count
- All match state changes require a round trip — contributes to perceived latency

### Neutral

- TypeScript is used on both client and server; `shared/types.ts` bridges the two runtimes

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Tick budget overflow under load | Medium | High | Profile `tick()` under 100-player stress test before launch; shed excess simulation work gracefully |
| Redis becomes single point of failure | Low | High | Supabase PostgreSQL as fallback for critical economy writes; Redis is a cache layer, not the system of record |
| React Native JS thread starvation | Medium | Medium | Move interpolation to UI thread; monitor with Flipper; defer non-critical renders |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Server tick time | — | ≤35ms (15ms buffer remaining) | 50ms |
| Client frame time (JS thread) | — | ≤16.6ms | 16.6ms |
| Memory (client) | — | ≤200MB | 200MB |
| Match state packet size | — | ≤1.5KB/tick | — |

## Migration Plan

New project — no migration required.

**Rollback plan**: Architecture change would require full rewrite. Not applicable at project start.

## Validation Criteria

- [ ] Server tick loop completes in ≤35ms under 8-player FFA load
- [ ] Client receives `match_state` at 20Hz (±2Hz) during active match
- [ ] Client profile updates only via `profile:refresh` — no polling paths in client code
- [ ] All economy writes carry idempotency keys; duplicate key returns prior result
- [ ] Zero game logic in `mobile/` — confirmed by code review at first PR

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/authentication.md` | Auth | Server must validate JWT on every request | JWT Validator in Foundation layer; Socket.io authenticate event mandatory |
| `design/gdd/match-server.md` | Match Server | Authoritative 20Hz server tick | Server Core layer owns all simulation; client renders snapshots |
| `design/gdd/currency-system.md` | Economy | All currency mutations server-side | Economy systems in Server Feature layer; client has no write access |
| `design/gdd/match-flow.md` | Match Flow | fan-out must not block match_end | Principle 5 (Model B fan-out) encoded here |
| `design/gdd/realtime-transport.md` | Transport | Client sends inputs; server sends state | Client-to-server / server-to-client event contract defined above |

## Related

- ADR-0002: Real-Time Transport Protocol (Socket.io v4) — depends on this ADR's layer model
- ADR-0003: Server-Side Game Loop — depends on this ADR's server-authoritative principle
- ADR-0004: Authentication Architecture — depends on this ADR's JWT Validator placement
- ADR-0005: Database Architecture — depends on this ADR's server-only data write principle
