# Story 009: Serialization Integrity

> **Epic**: Real-time Transport
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: XS
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/realtime-transport.md`
**Requirement**: `TR-transport-???`

**ADR Governing Implementation**: ADR-0002: Real-Time Transport Protocol
**ADR Decision Summary**: All events JSON-serialized; every declared field present with correct type; no undeclared fields; no `undefined` values serialized.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW

---

## Acceptance Criteria

- [ ] **AC-RT-17**: Any event payload emitted from server → client deserializes JSON → all declared fields present with correct types; no extra undeclared fields; no `undefined` values serialized
- [ ] `EntityState` schema: `{ id: string, type: string, x: number, y: number, vx: number, vy: number, hp: number, facing: number, state: string }` — all fields present in every `state_snapshot` entity
- [ ] `EntityDelta` schema: only changed fields present (optional); `id` always present; `destroyed` only present when true

---

## Implementation Notes

- Implement a TypeScript schema validator for `MatchSnapshot` and `EntityState` using `zod` or manual type guards
- Use `JSON.parse(JSON.stringify(payload))` on the server before emit to strip `undefined` values (JSON.stringify drops undefined)
- Test: for each event type in the typed event registry (ADR-0002), generate a sample payload and validate it against the schema

---

## QA Test Cases

- **AC-RT-17**: Schema compliance for state_snapshot
  - Given: Server emits `state_snapshot` with 2 entities
  - When: Client receives and parses JSON
  - Then: Each entity has all 9 required fields with correct types; no extra fields (e.g., no internal `_isBot` server flag leaked); no `undefined` values
  - Edge cases: Entity with `vx = 0` → still present (not omitted because falsy)

- **AC-delta-schema**: EntityDelta only contains changed fields
  - Given: Server computes delta between two ticks where only `hp` changed
  - When: `state_delta` emitted
  - Then: Delta entity has `{ id, hp }` only; `x`, `y`, `vx`, `vy` absent

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/realtime-transport/serialization-integrity_test.ts` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 002 (broadcast pipeline established)
- Unlocks: No remaining realtime-transport stories (this is the last)
