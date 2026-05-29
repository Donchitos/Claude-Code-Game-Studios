# Epics Index

Last Updated: 2026-05-29
Engine: React Native (Expo SDK) + Node.js
Review Mode: lean
ADRs: 16 Accepted (ADR-0001 through ADR-0016)
TR Registry: Pending — run `/architecture-review` to populate

---

## Foundation Layer (12 epics)

| Epic | System | GDD | Primary ADRs | Status |
|------|--------|-----|-------------|--------|
| [Authentication](authentication/EPIC.md) | Auth | authentication.md | ADR-0004, ADR-0001 | Ready |
| [API Client](api-client/EPIC.md) | API Client | api-client.md | ADR-0001, ADR-0004 | Ready |
| [Real-time Transport](realtime-transport/EPIC.md) | Transport | realtime-transport.md | ADR-0002, ADR-0004 | Ready |
| [Player Profile](player-profile/EPIC.md) | Player Profile | player-profile.md | ADR-0005, ADR-0006 | Ready |
| [Content Catalog](content-catalog/EPIC.md) | Content Catalog | content-catalog.md | ADR-0007, ADR-0001 | Ready |
| [Character System](character-system/EPIC.md) | Character System | character-system.md | ADR-0007, ADR-0013 | Ready |
| [Ability / Skill](ability-skill/EPIC.md) | Ability Registry | ability-skill.md | ADR-0007, ADR-0003 | Ready |
| [Game Mode](game-mode/EPIC.md) | Game Mode Config | game-mode.md | ADR-0007, ADR-0003 | Ready |
| [Map / Arena](map-arena/EPIC.md) | Map Config | map-arena.md | ADR-0007, ADR-0003 | Ready |
| [Remote Config](remote-config/EPIC.md) | Remote Config | remote-config.md | ADR-0007 | Ready |
| [Analytics / Telemetry](analytics-telemetry/EPIC.md) | Analytics Service | analytics-telemetry.md | ADR-0015 | Ready |
| [Logging / Monitoring](logging-monitoring/EPIC.md) | Logging Service | logging-monitoring.md | ADR-0001 | Ready |

---

## Core Layer (8 epics)

| Epic | System | GDD | Primary ADRs | Status |
|------|--------|-----|-------------|--------|
| [Session Manager](session-manager/EPIC.md) | Session Manager | session-manager.md | ADR-0012, ADR-0002 | Ready |
| [Match Server](match-server/EPIC.md) | Match Server (GameRoom) | match-server.md | ADR-0003, ADR-0012 | Ready |
| [Matchmaking Engine](matchmaking-engine/EPIC.md) | Matchmaking Engine | matchmaking-engine.md | ADR-0009, ADR-0005 | Ready |
| [Disconnect Handler](disconnect-handler/EPIC.md) | Disconnect Handler | disconnect-handler.md | ADR-0012, ADR-0002 | Ready |
| [Reconnect / Resume](reconnect-resume/EPIC.md) | Reconnect / Resume | reconnect-resume.md | ADR-0012, ADR-0002 | Ready |
| [Bot AI](bot-ai/EPIC.md) | Bot / Fallback AI | bot-ai.md | ADR-0012, ADR-0003 | Ready |
| [Combat System](combat-system/EPIC.md) | Combat Resolver | combat-system.md | ADR-0003 | Ready |
| [Deck / Loadout](deck-loadout/EPIC.md) | Deck/Loadout Validator | deck-loadout.md | ADR-0013, ADR-0007 | Ready |

---

## Feature Layer (16 epics)

| Epic | System | GDD | Primary ADRs | Milestone | Status |
|------|--------|-----|-------------|-----------|--------|
| [Match Flow](match-flow/EPIC.md) | Match Flow | match-flow.md | ADR-0010, ADR-0008 | MVP | Ready |
| [MMR / Ranked](mmr-ranked/EPIC.md) | MMR / Ranked | mmr-ranked.md | ADR-0010, ADR-0005 | MVP | Ready |
| [Currency System](currency-system/EPIC.md) | Currency System | currency-system.md | ADR-0008, ADR-0005 | Alpha | Ready |
| [Reward System](reward-system/EPIC.md) | Reward System | reward-system.md | ADR-0010, ADR-0008 | Alpha | Ready |
| [XP & Progression](xp-progression/EPIC.md) | XP System | xp-progression.md | ADR-0013, ADR-0008 | Alpha | Ready |
| [Quest / Mission](quest-mission/EPIC.md) | Quest System | quest-mission.md | ADR-0010, ADR-0008 | Alpha | Ready |
| [IAP System](iap-system/EPIC.md) | IAP + Fulfillment | iap-system.md | ADR-0011, ADR-0008 | Alpha | Ready |
| [Battle Pass](battle-pass/EPIC.md) | Battle Pass | battle-pass.md | ADR-0010, ADR-0011 | Alpha | Ready |
| [Inventory / Entitlements](inventory-entitlements/EPIC.md) | Inventory | inventory-entitlements.md | ADR-0008, ADR-0005 | Alpha | Ready |
| [Purchase Fulfillment](purchase-fulfillment/EPIC.md) | Purchase Fulfillment | purchase-fulfillment.md | ADR-0011, ADR-0008 | Alpha | Ready |
| [Cosmetic / Skin](cosmetic-skin/EPIC.md) | Cosmetic / Skin | cosmetic-skin.md | ADR-0008, ADR-0007 | Alpha | Ready |
| [Ad System](ad-system/EPIC.md) | Ad System | ad-system.md | ADR-0016, ADR-0008 | Alpha | Ready |
| [Push Notification](push-notification/EPIC.md) | Push Notification | push-notification.md | ADR-0014 | Alpha | Ready |
| [Party / Presence](party-presence/EPIC.md) | Party / Presence | party-presence.md | ADR-0002, ADR-0004 | VS | Ready |
| [Moderation / Reporting](moderation-reporting/EPIC.md) | Moderation | moderation-reporting.md | ADR-0001, ADR-0004 | Alpha | Ready |
| [Anti-Cheat](anti-cheat-validation/EPIC.md) | Anti-Cheat | anti-cheat-validation.md | ADR-0001, ADR-0003 | Full Vision | Ready |

---

## Presentation Layer (8 epics)

| Epic | System | GDD | Primary ADRs | Milestone | Status |
|------|--------|-----|-------------|-----------|--------|
| [Main Menu](main-menu/EPIC.md) | Main Menu | main-menu.md | ADR-0006, ADR-0004 | MVP | Ready |
| [Lobby](lobby/EPIC.md) | Lobby | lobby.md | ADR-0002, ADR-0006 | MVP | Ready |
| [Character / Deck Select](character-deck-select/EPIC.md) | Char/Deck Select | character-deck-select.md | ADR-0013, ADR-0006 | MVP | Ready |
| [In-Match HUD](in-match-hud/EPIC.md) | In-Match HUD | in-match-hud.md | ADR-0006, ADR-0002 | MVP | Ready |
| [Match Results](match-results/EPIC.md) | Match Results | match-results.md | ADR-0010, ADR-0006 | MVP | Ready |
| [Shop & Offers](shop-offers-screen/EPIC.md) | Shop Screen | shop-offers-screen.md | ADR-0011, ADR-0007 | Alpha | Ready |
| [Settings / Accessibility](settings-accessibility/EPIC.md) | Settings | settings-accessibility.md | ADR-0006, ADR-0004 | MVP | Ready |
| [Tutorial / Onboarding](tutorial-onboarding/EPIC.md) | Tutorial | tutorial-onboarding.md | ADR-0006, ADR-0012 | VS | Ready |

---

## Summary

| Layer | Epics | MVP | VS | Alpha | Full Vision |
|-------|-------|-----|----|-------|-------------|
| Foundation | 12 | 12 | 0 | 0 | 0 |
| Core | 8 | 6 | 2 | 0 | 0 |
| Feature | 16 | 2 | 1 | 12 | 1 |
| Presentation | 8 | 6 | 1 | 1 | 0 |
| **Total** | **44** | **26** | **4** | **13** | **1** |

## Next Steps

1. Run `/create-stories [epic-slug]` for each epic to break it into implementable stories
2. Run `/gate-check production` after Foundation + Core epics have stories to check Pre-Production → Production readiness
3. Run `/sprint-plan` to schedule the first implementation sprint

> **Priority order for story creation:** Foundation layer first (all 12 are MVP blockers), then Core (6 MVP + 2 VS), then Feature MVP epics (match-flow, mmr-ranked), then Presentation MVP epics.
