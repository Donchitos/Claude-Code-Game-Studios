# Session State — BRAWLZONE

<!-- STATUS -->
Epic: Logging / Monitoring
Feature: Story 001 Complete
Task: Next: /story-readiness story-002-pii-redaction-correlation-id.md
<!-- /STATUS -->

## Current Task

All 16 ADRs written (2026-05-29). Technical Setup phase architecture is complete. Ready for `/create-epics` to decompose GDDs into implementation backlog, then `/sprint-plan` for first coding sprint.

## Progress Checklist

- [x] Engine configured — React Native (Expo SDK) + Node.js game server
- [x] Tech preferences populated — `.claude/docs/technical-preferences.md`
- [x] Engine reference doc created — `docs/engine-reference/react-native/VERSION.md`
- [x] Systems enumerated — 44 systems, Brawl Stars × Ludus hybrid
- [x] Dependencies mapped and corrected (10 architectural corrections applied)
- [x] Priority tiers assigned — MVP (22) / VS (6) / Alpha (13) / Full Vision (1) / Horizontal (2)
- [x] Systems index written — `design/gdd/systems-index.md`
- [x] Individual system GDDs — 45 / 45 (all blocks complete)
- [x] Architecture document v1.0 — `docs/architecture/architecture.md`
- [x] All 16 ADRs — `docs/architecture/ADR-0001` through `ADR-0016`
  - [x] Block 1 — MVP Foundation: authentication, api-client, analytics-telemetry, logging-monitoring
  - [x] Block 2 — MVP Infrastructure: player-profile, realtime-transport, remote-config
  - [x] Block 3 — MVP Core Data + Game Infrastructure: session-manager, match-server, matchmaking-engine, mmr-ranked, character-system, map-arena
  - [x] Block 4 — MVP Gameplay Core: deck-loadout, ability-skill, combat-system, game-mode, match-flow
  - [x] Block 5 — MVP Presentation: main-menu, lobby, character-deck-select, in-match-hud, match-results, settings-accessibility
  - [x] Block 6 — Vertical Slice: disconnect-handler, reconnect-resume, party-presence, bot-ai, tutorial-onboarding
- [ ] Block 7 — Alpha Economy Foundation (6 GDDs remaining):
  - [ ] currency-system.md
  - [ ] inventory-entitlements.md
  - [ ] push-notification.md
  - [ ] xp-progression.md
  - [ ] quest-mission.md
  - [ ] moderation-reporting.md
- [ ] Block 8 — Alpha Economy Expansion (7 GDDs remaining):
  - [ ] iap-system.md
  - [ ] cosmetic-skin.md
  - [ ] purchase-fulfillment.md
  - [ ] reward-system.md
  - [ ] ad-system.md
  - [ ] shop-offers-screen.md
  - [ ] battle-pass.md ⚠️ (design LAST — depends on all other Alpha systems frozen)
- [ ] Block 9 — Full Vision (1 GDD remaining):
  - [ ] anti-cheat-validation.md ⚠️ (L effort)

## Key Decisions Made

- Tech stack: React Native (Expo) + Node.js — not a traditional game engine
- Review mode: lean
- XP / Reward ownership: Model B (parallel fan-out from Match Flow — no coupling)
- Session Manager orchestrates Match Server (not the reverse)
- Matchmaking at MVP: solo queue only; party queue extended in VS when Party / Presence ships
- Deck / Loadout System is a first-class system, not a subfeature — core Ludus differentiator
- Analytics and Logging are horizontal (always-on) not tiered
- Anti-Cheat deferred to Full Vision (server-authoritative loop provides baseline integrity at MVP)
- Battle Pass designed last in Alpha — depends on Currency, Inventory, IAP, Reward all being frozen first
- **Match Server tick budget**: Input 2ms → Validation 3ms → Simulation 20ms → Win Condition 3ms → State Emit 7ms → 15ms buffer
- **Lag compensation**: rewind = floor(min(playerRtt, 200ms) / 50ms) ticks; applies to hit detection only, not damage
- **MMR fires BEFORE reward distribution** (synchronous, 3000ms timeout)
- **LGU coordinate system**: origin bottom-left, Y-axis up
- **Dual Redis sorted sets per mode**: by queuedAt + by MMR
- **BURNING bypasses SHIELDED** (explicit design choice)
- **Snapshot-only reconnect restore** (no event replay)
- **8 characters with identical base stats**: Vex, Zook, Sera, Fen, Grim, Dash, Colt, Nyx
- **3 game modes**: 1v1 Duel, 3v3 Squad Brawl, 8-player FFA
- **Probabilistic bot ability use** (not cooldown-snapping)
- **`isConfirmed` in reconnect_ack** — resolves character-select reconnect gap
- **`match_found` always beats cancel** — lobby boolean flag prevents race condition

## Cross-System Gaps (Resolve Before Alpha)

1. Add `prevRankTier` to `match_results_payload` in match-flow.md (needed by match-results screen)
2. Add `xpAtLevelStart` / `xpToNextLevel` to `match_results_payload` in match-flow.md
3. Add `isInactive` flag to Match Server `PlayerState` schema (needed by bot-ai.md)
4. Define `dequeued` event with `reason` field in matchmaking-engine.md (needed by lobby.md)
5. Enforce `RECONNECT_WINDOW_S` = `RECONNECT_GRACE_PERIOD_S` invariant in code docs

## Files Written This Session

**Block 1 (MVP Foundation):**
- `design/gdd/api-client.md`
- `design/gdd/analytics-telemetry.md`
- `design/gdd/logging-monitoring.md`

**Block 2 (MVP Infrastructure):**
- `design/gdd/player-profile.md`
- `design/gdd/realtime-transport.md`
- `design/gdd/remote-config.md`

**Block 3 (MVP Core Data + Game Infrastructure):**
- `design/gdd/session-manager.md`
- `design/gdd/match-server.md`
- `design/gdd/matchmaking-engine.md`
- `design/gdd/mmr-ranked.md`
- `design/gdd/character-system.md`
- `design/gdd/map-arena.md`

**Block 4 (MVP Gameplay Core):**
- `design/gdd/deck-loadout.md`
- `design/gdd/ability-skill.md`
- `design/gdd/combat-system.md`
- `design/gdd/game-mode.md`
- `design/gdd/match-flow.md`

**Block 5 (MVP Presentation):**
- `design/gdd/main-menu.md`
- `design/gdd/lobby.md`
- `design/gdd/character-deck-select.md`
- `design/gdd/in-match-hud.md`
- `design/gdd/match-results.md`
- `design/gdd/settings-accessibility.md`

**Block 6 (Vertical Slice):**
- `design/gdd/disconnect-handler.md`
- `design/gdd/reconnect-resume.md`
- `design/gdd/party-presence.md`
- `design/gdd/bot-ai.md`
- `design/gdd/tutorial-onboarding.md`

## Session Extract — /review-all-gdds 2026-05-29
- Verdict: PASS
- GDDs reviewed: 45 system GDDs + game-concept + game-pillars + systems-index
- Flagged for revision: None (all 10 prior blockers resolved; systems-index "Needs Revision" flags cleared → Draft)
- Blocking issues: None
- Fixed inline this run: character ID format normalized to `character:{slug}` across 9 GDDs; mode IDs normalized to duel_1v1/squad_3v3/ffa_8 across 13 GDDs; remote-config maxSkillSpreadMMR 200→300; removed fictional `brawler_kai`/`brawler_*` names
- Carried-forward warnings (non-blocking): W-D-01 coin surplus, W-D-02 FFA cognitive load (playtest gate), W-D-03 options≠power, W-D-04 BP pacing, W-D-05 Play Pass guardrail, S-W-03 wallet-cap ordering
- Recommended next: /gate-check systems-design → /create-architecture
- Report: design/gdd/gdd-cross-review-2026-05-29.md
