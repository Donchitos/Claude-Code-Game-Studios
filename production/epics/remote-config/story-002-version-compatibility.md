# Story 002: Version Compatibility Enforcement

> **Epic**: Remote Config
> **Status**: Complete
> **Layer**: Foundation (Ops)
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: not yet created
> **Last Updated**: 2026-05-29

## Context

**GDD**: `design/gdd/remote-config.md`
**Requirement**: `TR-ops-???` *(pending `/architecture-review`)*

**ADR Governing Implementation**: ADR-0007: Content Catalog Architecture
**ADR Decision Summary**: Client sends `schema_version` to server; server returns 409 if `minCompatibleSchemaVersion` not met; force-update modal blocks all navigation.

**Engine**: React Native (Expo SDK) + Node.js | **Risk**: LOW
**Engine Notes**: N/A — pure TypeScript with injected adapters. No game engine API involved.

---

## Acceptance Criteria

- [x] Client `schema_version=1` + server `minCompatibleSchemaVersion=2` → 409 `config_incompatible` response
- [x] On `config_incompatible`: force-update modal appears; back gesture, Android back button, swipe-to-dismiss all blocked
- [x] If `config_incompatible` + server unreachable simultaneously → falls back to hardcoded defaults; proceeds to main menu WITHOUT showing force-update modal (valid server response required)

---

## Implementation Notes

- Config fetch request includes header `X-Config-Schema-Version: {CLIENT_SCHEMA_VERSION}`
- Server: if `requestedVersion < minCompatibleSchemaVersion` → HTTP 409 `{ code: 'config_incompatible' }`
- Client: on 409 response: render `ForceUpdateModal` (non-dismissible); deep-link to app store
- Force-update modal blocks navigation: override back handler with no-op in React Navigation
- Edge case: 409 then network drops → show modal anyway (the 409 was already received)

---

## QA Test Cases

- **AC-version-mismatch**: 409 triggers force update
  - Given: Client `schema_version=1`; server returns `{ code: 'config_incompatible', minVersion: 2 }`
  - When: App initializes config
  - Then: `ForceUpdateModal` rendered; tapping Android back button has no effect (back handler overridden)

- **AC-simultaneous-failure**: 409 + network drop → defaults
  - Given: Server returned 409; then network goes down before modal renders
  - When: Recovery attempted
  - Then: Hardcoded defaults used; main menu renders; force-update modal NOT shown (requires a confirmed 409 response — if connection drops before response, treat as network failure)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/remote-config/version-compatibility_test.ts`

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (config fetch infrastructure)
- Unlocks: Story 003 (hot config push)
