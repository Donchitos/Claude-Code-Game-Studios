# Systems Index: BRAWLZONE

> **Status**: Draft
> **Created**: 2026-05-24
> **Last Updated**: 2026-05-28
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

BRAWLZONE is a mobile-first real-time PvP brawler with a strategic meta layer — a hybrid of
Brawl Stars (fast arena combat, short sessions, live-service cadence) and Ludus (deck/loadout
construction, pre-match tactical composition, meaningful strategic differentiation). This hybrid
identity requires two distinct system clusters: a **server-authoritative real-time match cluster**
(combat, game modes, match flow, networking) and a **strategic meta cluster** (deck building,
ability composition, progression, economy). Both clusters must be independently coherent while
interacting cleanly at the character-select boundary and the reward layer.

Platform: iOS + Android via React Native / Expo with a Node.js game server, Socket.io real-time
transport at 20Hz, and Supabase for auth and PostgreSQL persistence. Monetization: Diamonds (IAP),
Play Pass subscription, and AdMob for free players. The **Deck / Loadout System** is the primary
strategic differentiator and must be designed with the same depth as Combat itself.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 0 | Game Pillars | Foundation | MVP | Draft | design/gdd/game-pillars.md | — |
| 1 | Authentication | Foundation | MVP | Draft | design/gdd/authentication.md | Supabase Auth (external) |
| 2 | Real-time Transport | Foundation | MVP | Draft | design/gdd/realtime-transport.md | Authentication |
| 3 | Matchmaking Engine | Server | MVP | Draft | design/gdd/matchmaking-engine.md | MMR, Session Manager, Player Profile, Remote Config |
| 4 | Match Server | Server | MVP | Draft | design/gdd/match-server.md | Session Manager, Real-time Transport, Character System |
| 5 | Character System | Gameplay | MVP | Draft | design/gdd/character-system.md | Content Catalog, Inventory*, Remote Config |
| 6 | Deck / Loadout System | Gameplay | MVP | Draft | design/gdd/deck-loadout.md | Character System, Content Catalog, Inventory* |
| 7 | Ability / Skill System | Gameplay | MVP | Draft | design/gdd/ability-skill.md | Character System |
| 8 | Game Mode System | Gameplay | MVP | Draft | design/gdd/game-mode.md | Combat, Match Server, Map / Arena, Content Catalog, Remote Config |
| 9 | Combat System | Gameplay | MVP | Draft | design/gdd/combat-system.md | Character, Ability / Skill, Map / Arena, Match Server |
| 10 | Match Flow System | Gameplay | MVP | Draft | design/gdd/match-flow.md | Game Mode, Matchmaking, Session Manager |
| 11 | Map / Arena System | Gameplay | MVP | Draft | design/gdd/map-arena.md | Content Catalog |
| 12 | MMR / Ranked System | Economy | MVP | Draft | design/gdd/mmr-ranked.md | Player Profile |
| 13 | Currency System | Economy | Alpha | Draft | design/gdd/currency-system.md | Player Profile |
| 14 | Reward System | Economy | Alpha | Draft | design/gdd/reward-system.md | Match Flow, Currency, Inventory, Battle Pass |
| 15 | XP & Progression | Economy | Alpha | Draft | design/gdd/xp-progression.md | Player Profile, Match Flow, Character System |
| 16 | Quest / Mission System | Economy | Alpha | Draft | design/gdd/quest-mission.md | Match Flow, Analytics, Character System |
| 17 | IAP System | Economy | Alpha | Draft | design/gdd/iap-system.md | Currency, API Client, Authentication |
| 18 | Battle Pass / Play Pass | Economy | Alpha | Draft | design/gdd/battle-pass.md | IAP, Currency, Inventory, Match Flow |
| 19 | Ad System | Economy | Alpha | Draft | design/gdd/ad-system.md | Authentication, Inventory, Currency System, Remote Config, Analytics / Telemetry, Player Profile |
| 20 | Push Notification System | Ops | Alpha | Draft | design/gdd/push-notification.md | Authentication, API Client |
| 21 | Player Profile & Persistence | Foundation | MVP | Draft | design/gdd/player-profile.md | Authentication |
| 22 | API Client | Foundation | MVP | Draft | design/gdd/api-client.md | — |
| 23 | Content Catalog | Foundation | MVP | Draft — Canonical Registry ✅ | design/gdd/content-catalog.md | — |
| 24 | Remote Config / Live Tuning | Ops | VS | Draft | design/gdd/remote-config.md | API Client |
| 25 | Analytics / Telemetry | Ops | Horizontal | Draft | design/gdd/analytics-telemetry.md | API Client, Authentication |
| 26 | Session Manager | Server | MVP | Draft | design/gdd/session-manager.md | Real-time Transport, Authentication, Player Profile |
| 27 | Disconnect Handler | Server | VS | Draft | design/gdd/disconnect-handler.md | Session Manager, Real-time Transport |
| 28 | Reconnect / Resume System | Server | VS | Draft | design/gdd/reconnect-resume.md | Session Manager, Real-time Transport |
| 29 | Anti-Cheat / Validation | Ops | Full Vision | Draft | design/gdd/anti-cheat-validation.md | Authentication, Match Server, Session Manager |
| 30 | Inventory / Entitlements | Economy | Alpha | Draft | design/gdd/inventory-entitlements.md | Player Profile, Content Catalog |
| 31 | Purchase Fulfillment | Economy | Alpha | Draft | design/gdd/purchase-fulfillment.md | IAP, Inventory, Currency, Authentication, Player Profile |
| 32 | Cosmetic / Skin System | Economy | Alpha | Draft | design/gdd/cosmetic-skin.md | Inventory, Character System |
| 33 | Main Menu & Navigation | UI | MVP | Draft | design/gdd/main-menu.md | Authentication, Player Profile |
| 34 | Lobby & Team Formation | UI | MVP | Draft | design/gdd/lobby.md | Matchmaking, Party / Presence* |
| 35 | Character / Deck Select | UI | MVP | Draft | design/gdd/character-deck-select.md | Character System, Deck / Loadout, Lobby, Session Manager |
| 36 | In-Match HUD | UI | MVP | Draft | design/gdd/in-match-hud.md | Combat, Game Mode, Real-time Transport |
| 37 | Match Results Screen | UI | MVP | Draft | design/gdd/match-results.md | Match Flow, MMR (Reward System added in Alpha) |
| 38 | Shop & Offers Screen | UI | Alpha | Draft | design/gdd/shop-offers-screen.md | Currency, Content Catalog, IAP, Battle Pass, Cosmetic |
| 39 | Settings & Accessibility | UI | MVP | Draft | design/gdd/settings-accessibility.md | Authentication, Push Notification*, Remote Config* |
| 40 | Party / Presence System | Social | VS | Draft | design/gdd/party-presence.md | Authentication, Real-time Transport |
| 41 | Tutorial / Onboarding | Social | VS | Draft | design/gdd/tutorial-onboarding.md | Main Menu, Character System, Match Flow, Content Catalog, Remote Config |
| 42 | Bot / Fallback AI | Social | VS | Draft | design/gdd/bot-ai.md | Character System, Match Server, Disconnect Handler |
| 43 | Moderation / Reporting | Ops | Alpha | Draft | design/gdd/moderation-reporting.md | Authentication, Player Profile, Match Flow, Analytics |
| 44 | Logging / Monitoring | Ops | Horizontal | Draft | design/gdd/logging-monitoring.md | — |

> **\* Cross-tier dependencies**: A `*` marks a dependency that belongs to a later milestone tier.
> At MVP, the dependent system operates in a reduced mode (e.g., Lobby runs solo-queue only until
> Party / Presence ships in VS; Match Results shows a stub until Reward System ships in Alpha).

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Foundation** | Core infrastructure with zero game-specific dependencies — every other system depends on these | Auth, API Client, Content Catalog, Player Profile |
| **Server** | Server-side game infrastructure — session lifecycle, authoritative simulation, matchmaking | Session Manager, Match Server, Matchmaking Engine, Disconnect Handler, Reconnect / Resume |
| **Gameplay** | In-match game systems — everything that happens during an active match | Character, Deck / Loadout, Ability / Skill, Map / Arena, Combat, Game Mode, Match Flow |
| **Economy** | Resources, currencies, rewards, and monetization | MMR, Currency, Inventory, Reward, XP & Progression, Quest / Mission, IAP, Battle Pass, Ad System, Purchase Fulfillment, Cosmetic / Skin |
| **Social** | Player relationships, resilience, and AI fallbacks | Party / Presence, Bot / Fallback AI, Tutorial / Onboarding |
| **UI** | All client-facing screens and HUD | Main Menu, Lobby, Character / Deck Select, HUD, Match Results, Shop, Settings |
| **Ops** | Analytics, remote config, monitoring, safety, moderation | Analytics, Remote Config, Logging, Anti-Cheat, Moderation, Push Notification |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | The combat loop works end-to-end: queue → select → fight → results. Without these, you can't test if the game is fun. | Closed beta | Design FIRST |
| **Vertical Slice** | A production-quality match with resilience: reconnect, party queue, bots for thin queues, and onboarding. Demonstrates the full hybrid experience. | Internal demo / soft launch prep | Design SECOND |
| **Alpha** | Full economy layer active: currency, IAP, Battle Pass, rewards, cosmetics, shop. Complete scope, balance-tunable. | Public beta | Design THIRD |
| **Full Vision** | Hardened systems for public scale: anti-cheat enforcement, advanced moderation. | Launch | Design as needed |
| **Horizontal** | Cross-cutting concerns that are always active. Design the event taxonomy and observability interface alongside Block 1; implement incrementally throughout all tiers. | Continuous | Design ALONGSIDE MVP Block 1 |

---

## Dependency Map

### Foundation Layer (no game dependencies)

1. **Authentication** — identity anchor; every other system references user identity
2. **API Client** — HTTP transport for non-realtime server calls; used by Profile, Config, Analytics, Push, IAP
3. **Content Catalog** — static game data registry (characters, maps, loadout items, mode configs); upstream of Character, Map, Deck, Game Mode, Shop, Tutorial
4. **Logging / Monitoring** — observability interface; no game dependency

### Infrastructure Layer (depends on Foundation)

5. **Player Profile & Persistence** — account state, stats, unlock list; upstream of MMR, Currency, Inventory, Matchmaking, Main Menu
6. **Real-time Transport** — Socket.io client connection + event routing; upstream of Session Manager, Party / Presence, HUD
7. **Remote Config / Live Tuning** — runtime tunable values; upstream of Character (balance overlays), Matchmaking (queue rules), Game Mode (event variants), Tutorial, Ad System, Settings
8. **Analytics / Telemetry** *(horizontal)* — event sink receiving from Match Flow, Rewards, Quests, Shop, Onboarding; no downstream game dependency
9. **Push Notification System** — Auth + API Client; leaf node for engagement

### Core Data Layer (depends on Foundation + Infrastructure)

10. **Session Manager** — Real-time Transport, Authentication, Player Profile; orchestrates Match Server lifecycle
11. **Party / Presence System** — Authentication, Real-time Transport; prerequisite for team queue in Matchmaking
12. **MMR / Ranked System** — Player Profile; feeds Matchmaking and Match Results
13. **Inventory / Entitlements** — Player Profile, Content Catalog; gates all owned-item logic

*(Alpha-tier items below are listed here for topological completeness — designed in Alpha Block)*

14. **Currency System** — Player Profile
15. **Character System** — Content Catalog, Inventory, Remote Config

### Game Infrastructure Layer (depends on Core Data)

16. **Match Server** — Session Manager, Real-time Transport; runs authoritative simulation
17. **Matchmaking Engine** — MMR, Session Manager, Player Profile, Party / Presence, Remote Config
18. **Map / Arena System** — Content Catalog
19. **Deck / Loadout System** — Character System, Content Catalog, Inventory
20. **Ability / Skill System** — Character System

*(Alpha-tier items below are listed here for topological completeness)*

21. **IAP System** — Currency, API Client, Authentication

### Core Gameplay Layer (depends on Game Infrastructure)

22. **Combat System** — Character System, Ability / Skill, Map / Arena, Match Server
23. **Disconnect Handler** — Session Manager, Real-time Transport
24. **Reconnect / Resume System** — Session Manager, Real-time Transport
25. **Bot / Fallback AI** — Character System, Match Server, Disconnect Handler
26. **Cosmetic / Skin System** — Inventory, Character System
27. **Purchase Fulfillment** — IAP, Inventory, Currency, Authentication, Player Profile
28. **Ad System** — Authentication, Inventory, Remote Config

### Compound Features Layer (depends on Core Gameplay)

29. **Game Mode System** — Combat, Match Server, Map / Arena, Content Catalog, Remote Config
30. **Match Flow System** — Game Mode, Matchmaking, Session Manager
31. **XP & Progression** — Player Profile, Match Flow, Character System *(parallel to Reward — both fan from Match Flow)*
32. **Quest / Mission System** — Match Flow, Analytics, Character System
33. **Moderation / Reporting** — Authentication, Player Profile, Match Flow, Analytics
34. **Battle Pass / Play Pass** — IAP, Currency, Inventory, Match Flow
35. **Reward System** — Match Flow, Currency, Inventory, Battle Pass

### Presentation Layer (depends on Compound Features)

36. **Main Menu & Navigation** — Authentication, Player Profile
37. **Lobby & Team Formation** — Matchmaking, Party / Presence
38. **Character / Deck Select** — Character System, Deck / Loadout, Lobby
39. **In-Match HUD** — Combat, Game Mode, Real-time Transport
40. **Match Results Screen** — Match Flow, MMR *(extended by Reward System in Alpha)*
41. **Shop & Offers Screen** — Currency, Content Catalog, IAP, Battle Pass, Cosmetic / Skin
42. **Settings & Accessibility** — Authentication, Push Notification, Remote Config
43. **Tutorial / Onboarding** — Main Menu, Character System, Match Flow, Content Catalog, Remote Config

### Hardening Layer (depends on everything)

44. **Anti-Cheat / Validation** — Authentication, Match Server, Session Manager

---

## Recommended Design Order

> Systems within the same block can be designed in parallel.
> Complete all systems in a block before starting the next block unless noted.
> Effort: **S** = 1 session · **M** = 2–3 sessions · **L** = 4+ sessions

| Order | System | Priority | Layer | Primary Agent(s) | Effort |
|-------|--------|----------|-------|-----------------|--------|
| **Block 1 — MVP Foundation** | | | | | |
| 1 | Authentication | MVP | Foundation | game-designer + security-engineer | S |
| 2 | API Client | MVP | Foundation | game-designer + lead-programmer | S |
| 3 | Content Catalog | MVP | Foundation | game-designer + lead-programmer | M |
| 4 | Analytics / Telemetry *(event taxonomy)* | Horizontal | Infrastructure | game-designer + analytics-engineer | M |
| 5 | Logging / Monitoring *(observability interface)* | Horizontal | Foundation | game-designer + lead-programmer | S |
| **Block 2 — MVP Infrastructure** | | | | | |
| 6 | Player Profile & Persistence | MVP | Infrastructure | game-designer + lead-programmer | M |
| 7 | Real-time Transport | MVP | Infrastructure | game-designer + network-programmer | M |
| 8 | Remote Config / Live Tuning *(designed early; implemented in VS)* | VS | Infrastructure | game-designer + lead-programmer | S |
| **Block 3 — MVP Core Data** | | | | | |
| 9 | Session Manager | MVP | Core Data | game-designer + network-programmer | M |
| 10 | Match Server | MVP | Game Infrastructure | game-designer + network-programmer | L |
| 11 | Matchmaking Engine *(solo queue at MVP; party queue extended in VS)* | MVP | Game Infrastructure | game-designer + network-programmer | M |
| 12 | MMR / Ranked System | MVP | Core Data | game-designer | S |
| 13 | Character System | MVP | Core Data | game-designer + gameplay-programmer | M |
| 14 | Map / Arena System | MVP | Game Infrastructure | game-designer + gameplay-programmer | M |
| **Block 4 — MVP Gameplay Core** | | | | | |
| 15 | Deck / Loadout System ⚠️ | MVP | Game Infrastructure | game-designer + gameplay-programmer | L |
| 16 | Ability / Skill System | MVP | Game Infrastructure | game-designer + gameplay-programmer | M |
| 17 | Combat System ⚠️ | MVP | Core Gameplay | game-designer + gameplay-programmer | L |
| 18 | Game Mode System | MVP | Compound Features | game-designer + gameplay-programmer | M |
| 19 | Match Flow System | MVP | Compound Features | game-designer + network-programmer | M |
| **Block 5 — MVP Presentation** | | | | | |
| 20 | Main Menu & Navigation | MVP | Presentation | game-designer + ui-programmer | S |
| 21 | Lobby & Team Formation *(solo queue at MVP)* | MVP | Presentation | game-designer + ui-programmer | M |
| 22 | Character / Deck Select | MVP | Presentation | game-designer + ui-programmer | M |
| 23 | In-Match HUD | MVP | Presentation | game-designer + ui-programmer | M |
| 24 | Match Results Screen *(stub rewards at MVP; extended in Alpha)* | MVP | Presentation | game-designer + ui-programmer | S |
| 25 | Settings & Accessibility *(local only at MVP; Remote Config extended in VS)* | MVP | Presentation | game-designer + ui-programmer | S |
| **Block 6 — Vertical Slice** | | | | | |
| 26 | Disconnect Handler | VS | Core Gameplay | game-designer + network-programmer | M |
| 27 | Reconnect / Resume System ⚠️ | VS | Core Gameplay | game-designer + network-programmer | M |
| 28 | Party / Presence System | VS | Core Data | game-designer + network-programmer | M |
| 29 | Bot / Fallback AI | VS | Core Gameplay | game-designer + ai-programmer | L |
| 30 | Tutorial / Onboarding | VS | Presentation | game-designer + ui-programmer | M |
| **Block 7 — Alpha Economy Foundation** | | | | | |
| 31 | Currency System | Alpha | Core Data | game-designer + economy-designer | M |
| 32 | Inventory / Entitlements | Alpha | Core Data | game-designer + lead-programmer | M |
| 33 | Push Notification System | Alpha | Infrastructure | game-designer | S |
| 34 | XP & Progression | Alpha | Compound Features | game-designer + economy-designer | M |
| 35 | Quest / Mission System | Alpha | Compound Features | game-designer | M |
| 36 | Moderation / Reporting | Alpha | Hardening | game-designer + security-engineer | M |
| **Block 8 — Alpha Economy Expansion** | | | | | |
| 37 | IAP System | Alpha | Game Infrastructure | game-designer + security-engineer | M |
| 38 | Cosmetic / Skin System | Alpha | Core Gameplay | game-designer | M |
| 39 | Purchase Fulfillment | Alpha | Core Gameplay | game-designer + security-engineer | M |
| 40 | Battle Pass / Play Pass ⚠️ | Alpha | Compound Features | game-designer + economy-designer | L |
| 41 | Reward System | Alpha | Compound Features | game-designer + economy-designer | M |
| 42 | Ad System | Alpha | Core Gameplay | game-designer + security-engineer | S |
| 43 | Shop & Offers Screen | Alpha | Presentation | game-designer + ui-programmer | M |
| **Block 9 — Full Vision** | | | | | |
| 44 | Anti-Cheat / Validation ⚠️ | Full Vision | Hardening | game-designer + security-engineer | L |

---

## Circular Dependencies

No circular dependencies detected.

The two systems closest to a cycle are:

- **Quest / Mission System ↔ Battle Pass / Play Pass**: Quests award Battle Pass XP, and Battle Pass
  unlocks quest slots. However, this is a data relationship (quests emit completion events; Battle
  Pass listens), not an architectural dependency. Battle Pass does not depend on Quest to initialize.
  Resolve by defining a `QuestCompletionEvent` interface that Battle Pass subscribes to — neither
  system holds a direct reference to the other.

- **Reward System ↔ XP & Progression**: Both fan out from Match Flow independently (Model B).
  No coupling introduced.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Combat System (9) ⚠️ | Design + Technical | Real-time brawler feel on touch at 20Hz. Mobile latency tolerance is low; sluggish or stuttery combat kills retention before word-of-mouth activates. | Prototype combat feel before writing the full GDD. Define latency tolerance thresholds (acceptable input lag, interpolation window) as design constraints, not engineering post-hoc. |
| Match Server (4) ⚠️ | Technical | Server-authoritative state at 20Hz with lag compensation across variable mobile connections. Tick budget must survive worst-case network conditions. | Define tick budget, interpolation strategy, and max-lag threshold in Match Server GDD before any implementation begins. |
| Deck / Loadout System (6) ⚠️ | Design | The Ludus differentiator depends entirely on this system. If loadout decisions are not meaningful — too narrow, too random, or too obvious — the game loses its strategic identity and becomes a Brawl Stars clone. | Prototype 2–3 loadout configurations in closed beta. Measure pre-match choice time and deck diversity. Flag if >60% of players use the same 1–2 loadouts. |
| Reconnect / Resume System (28) ⚠️ | Technical | State recovery mid-match in a real-time authoritative server introduces race conditions and state-sync edge cases. A poorly designed reconnect flow corrupts match state. | Design an explicit state snapshot protocol in the Match Server GDD before authoring the Reconnect GDD. Reconnect must restore from snapshot, not reconstruct from events. |
| Battle Pass / Play Pass (18) ⚠️ | Scope | This system modifies Currency, Inventory, IAP, Rewards, and Quests. Changes cascade widely. Designing it before dependent systems are frozen risks constant revision. | Design last within Alpha (Block 8). Freeze Currency, Inventory, IAP, and Reward System first. |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 44 |
| Horizontal systems (always-on) | 2 |
| MVP systems | 22 |
| Vertical Slice systems | 6 |
| Alpha systems | 13 |
| Full Vision systems | 1 |
| Design docs complete (Draft) | 35 |
| Design docs needing revision | 10 (blocking) + 7 (warning) |
| Design docs reviewed | 44 ✅ (cross-review 2026-05-28) |
| Design docs approved | 0 |
| Cross-review verdict | ❌ FAIL — see design/gdd/gdd-cross-review-2026-05-28.md |
| MVP systems designed | 22 / 22 ✅ |
| VS systems designed | 6 / 6 ✅ |
| Alpha systems designed | 13 / 13 ✅ |
| Full Vision systems designed | 1 / 1 ✅ |
| Horizontal systems designed | 2 / 2 ✅ |

---

## Next Steps

- [x] All 44 GDDs authored ✅
- [ ] Run `/review-all-gdds` — cross-document consistency check across all 44 GDDs
- [ ] Resolve cross-system gaps before architecture:
  - Add `prevRankTier` to `match_results_payload` in match-flow.md
  - Add `xpAtLevelStart` / `xpToNextLevel` to `match_results_payload` in match-flow.md (flagged by xp-progression.md §3.9)
  - Add `isInactive` flag to Match Server `PlayerState` schema (flagged by bot-ai.md)
  - Extend `MatchResultForQuests` in Match Flow with `damageDealt`, `abilityUseCounts`, `survived`, `matchStartedAt` (flagged by quest-mission.md §6.2)
  - Define `dequeued` event with `reason` field in matchmaking-engine.md (flagged by lobby.md)
- [ ] Run `/gate-check systems-design` — triggers director sign-off before architecture work begins
- [ ] Run `/create-architecture` after gate-check passes — produces the master architecture blueprint
