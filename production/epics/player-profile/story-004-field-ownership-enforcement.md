# Story 004: Field Ownership Enforcement

> **Epic**: Player Profile
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/player-profile.md`
**Requirement**: `TR-persist-???`

**ADR Governing Implementation**: ADR-0001: Client-Server Architecture; ADR-0005: Database Architecture
**ADR Decision Summary**: Each field has exactly one owning system; any write attempt by a non-owner returns HTTP 403; no mutation occurs.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [x] **AC-PP-10**: Client-side request attempting to directly set `diamond_balance` or `wins` → HTTP 403; no DB mutation; no Redis invalidation
- [x] Only listed owning authority (per GDD §3.5 Field Ownership Table) can mutate each field
- [x] API route middleware enforces field-level ownership; owned fields are whitelisted per endpoint

---

## Implementation Notes

- Define field allowlists per endpoint in route config:
  - `PATCH /v1/profile/settings`: allowed fields = `{ display_name, avatar_id, region, analytics_consent }`
  - Any other field in request body: strip silently OR return 400 depending on strictness choice
- `diamond_balance`, `wins`, `losses`, `mmr`, etc.: no client-facing endpoint writes these; they are only mutated by internal service functions
- Server-side: use TypeScript typed request body validation (Zod schema); unknown fields → 400
- 403 vs 400: if field exists but is not owned by client → 403; if field doesn't exist on profile → 400 (bad request)

---

## QA Test Cases

- **AC-PP-10**: Client cannot write diamond_balance
  - Given: Authenticated player
  - When: `PATCH /v1/profile { diamond_balance: 99999 }` via raw HTTP
  - Then: HTTP 403 returned; `player_profiles.diamond_balance` unchanged in DB

- **AC-field-strip**: Unknown field stripped from settings update
  - Given: `PATCH /v1/profile/settings { display_name: "NewName", wins: 100 }`
  - When: Request processed
  - Then: `display_name` updated; `wins` unchanged; HTTP 200 (or 400 if strict — implementation choice to document in ADR)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/player-profile/field-ownership_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 005 (economy writes)
