# Story 003: Cooldown Enforcement & Persistence

> **Epic**: Ability / Skill System
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/ability-skill.md`
**Requirement**: `TR-ability-???`

**ADR Governing Implementation**: ADR-0003: Server-Side Game Loop
**ADR Decision Summary**: Cooldown state held in server-side `PlayerState`; persists across ticks; packet loss does not reset cooldowns; client receives correction if prediction diverges.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-3.1**: After firing, ability cannot be fired again until `currentTime >= cooldownExpiresAt`
- [x] **AC-3.2**: Cooldown state persists across brief packet loss (server state authoritative)
- [x] **AC-3.3**: Client with stale-ready cooldown display → server returns `AbilityRejected { reason: "COOLDOWN", cooldownRemainingMs }`

---

## Implementation Notes

- `PlayerState.abilityCooldowns: Map<abilityId, cooldownExpiresAtMs>` — server-authoritative
- `currentTime >= cooldownExpiresAt`: use server tick timestamp, not client timestamp
- Cooldown remaining: `cooldownRemainingMs = cooldownExpiresAt - currentTick * 50`
- Persistence: cooldown state lives in `PlayerState` which persists for the match duration; packet loss doesn't affect it since server holds the state

---

## QA Test Cases

- **AC-3.1**: Cannot fire while on cooldown
  - Given: Ability fired at T=0; cooldownSec=3; current T=2.9s
  - When: `USE_ABILITY` at T=2.9s
  - Then: `AbilityRejected { reason: 'COOLDOWN' }` returned

- **AC-3.1**: Can fire exactly at cooldown expiry
  - Given: Ability on cooldown; `currentTime === cooldownExpiresAt` exactly
  - When: `USE_ABILITY` processed
  - Then: Accepted (boundary condition: AC-7.1 from GDD)

- **AC-3.3**: Stale client prediction corrected
  - Given: Server cooldown active; client predicts cooldown ready (state divergence)
  - When: Client emits `USE_ABILITY`
  - Then: Server returns `AbilityRejected { reason: 'COOLDOWN', cooldownRemainingMs: 850 }`; client UI updates to show remaining time

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/ability-skill/cooldown-enforcement_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (execution pipeline)
- Unlocks: Story 007 (edge cases)
