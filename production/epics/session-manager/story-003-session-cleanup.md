# Story 003: Session Cleanup After Match End

> **Epic**: session-manager
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/session-manager.md`
**Requirement**: `TR-core-???` *(pending `/architecture-review`)*

**ADR Governing Implementation**: ADR-0012
**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure Node.js server logic. No game engine API involved.

---

## Acceptance Criteria

- [x] See GDD `design/gdd/session-manager.md` §8 Acceptance Criteria for this story

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/session-manager/session_manager_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Foundation layer complete
- Unlocks: Story 004