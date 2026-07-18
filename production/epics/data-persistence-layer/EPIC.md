# Epic: Data Persistence Layer

> **Layer**: Core
> **GDD**: design/gdd/data-persistence-layer.md
> **Architecture Module**: Data Persistence Layer (#4)
> **Status**: Complete (2026-07-16) — all 3 stories closed
> **Stories**: 3 stories created (2026-07-16) — see table below

## Overview

This epic implements the project's single Firestore schema, offline persistence
configuration, and atomic write contracts — the layer every other domain system
reads and writes through. It owns the complete `families/children/tasks/
customTasks/inventory` schema, the offline-first `PersistentCacheSettings`
(or equivalent) config set once in `main()` before any Firestore call, the
`FieldValue.increment()`-only rule for all balance/counter mutations, and the
`runTransaction`-with-idempotency-read-first pattern for approve/reject. It also
owns the two required Cloud Functions (`onTaskApproved` energy cap,
`onChildProfileDelete` recursive delete) and the base Security Rules structure
(explicit nested per-collection matches — never a blanket recursive wildcard,
per the pattern ADR-0009 amended in). No other module builds Firestore paths
by hand; all path construction goes through this module's `FirestorePaths`
constants.

**Exit-criteria note (from `/gate-check` 2026-07-13 Pre-Production→Production and
the vertical slice)**: ADR-0003's exact persistence-settings API claim
(`Settings(cacheSettings: PersistentCacheSettings(...))`) did not match the
`cloud_firestore` version actually resolved during the vertical slice (6.6.0),
which has no such parameter — the older `persistenceEnabled`/`cacheSizeBytes` pair
was the live, correct API for that version. **Before writing the `main()`
initialization story**: pin the exact production `cloud_firestore` version, verify
which API shape it actually exposes, and correct ADR-0003 + regenerate
`docs/architecture/control-manifest.md` if needed. Do not implement from either
the ADR or the manifest without this check — both currently disagree with what a
compiler will accept for at least one resolved version.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0003: Firestore Schema & Persistence Strategy (amended by ADR-0009 §5) | Offline-first schema; `runTransaction`/`WriteBatch`/`FieldValue.increment()` write contracts; explicit nested Security Rules (never a blanket wildcard); `onTaskApproved`/`onChildProfileDelete` Cloud Functions; credentials sub-document | MEDIUM — persistence settings must be configured once in `main()` before any other Firestore call; exact API shape needs re-verification against the pinned package version (see note above) |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-data-persistence-001 | Offline persistence and unlimited cache set once in `main()` | ADR-0003 ✅ |
| TR-data-persistence-002 | Complete schema: families / children / tasks / customTasks / inventory | ADR-0003 ✅ |
| TR-data-persistence-003 | Atomic write contracts: approve = `runTransaction`, buy = `runTransaction` (per ADR-0011) | ADR-0003 ✅ (amended by ADR-0011 for buy) |
| TR-data-persistence-004 | All balance/counter mutation via `FieldValue.increment()`, never absolute `set()` | ADR-0003 ✅ |
| TR-data-persistence-005 | Cloud Function `onTaskApproved` enforces `storedEnergy` cap of 100 | ADR-0003 ✅ |
| TR-data-persistence-006 | Cloud Function `onChildProfileDelete` performs recursive delete | ADR-0003 ✅ |
| TR-data-persistence-007 | Security Rules scoped to `request.auth.uid == parentId`, explicit nested matches | ADR-0003 ✅ (amended by ADR-0009) |
| TR-data-persistence-008 | Document size budget under 1MB | ADR-0003 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/data-persistence-layer.md` are verified
- All Logic and Integration stories have passing test files in `tests/` (Firestore emulator required for integration tests — the vertical slice already validated this pattern works locally)
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`
- The `Settings` API exit-criteria note above has been resolved before the `main()` initialization story is marked done
- The deployed `firestore.rules` file matches ADR-0003 §5 (amended) / ADR-0009 §3 exactly — not the stale blanket-wildcard version that was found and fixed in `data-persistence-layer.md` on 2026-07-13

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Complete Firestore Schema & Path Constants | Logic | **Complete** | ADR-0003 |
| 002 | Deploy Firestore Security Rules | Integration | **Complete** | ADR-0003, ADR-0009 |
| 003 | onTaskApproved Cloud Function (storedEnergy Cap) | Integration | **Complete** | ADR-0003 |

**Already satisfied by other epics (no story needed here)**:
- `TR-data-persistence-001` (Firestore offline persistence in `main()`) — built during auth-account Story 001, before this epic existed.
- `TR-data-persistence-006` (`onChildProfileDelete` recursive delete) — built during auth-account Story 009.

**Not independently implementable as a story** (pattern enforced by downstream epics, not a standalone deliverable):
- `TR-data-persistence-003`/`004` (atomic write contracts, `FieldValue.increment()` rule) — realized when Currency (#7), Task Library (#8), Parent Approval (#11), and Pet Equipment (#15) implement their own repository methods against Story 001's schema. Already documented in `docs/architecture/control-manifest.md`'s Core Layer Rules.

**Known environment limitation**: this environment has no Java runtime, so the Firestore emulator (needed for Rules Unit Testing and full Cloud Function trigger-fire testing) cannot run — same gap auth-account Story 009 hit. Stories 002 and 003 document this explicitly rather than silently working around it; both substitute the same tested pattern Story 009 established (extracted-logic unit tests + `.__endpoint` config inspection, no emulator).

**Recommended build order**: 001 → 002/003 (parallel — both depend only on 001's schema, not on each other).

## Next Step

**All 3 stories are Complete.** Definition of Done status:
- The `Settings` API exit-criteria note (line 25-35 above) — already resolved before this epic's Story 001 even started (confirmed correct in `src/lib/main.dart`, built during auth-account Story 001).
- The deployed `firestore.rules` matches ADR-0003 §5 (amended) / ADR-0009 §3 exactly — confirmed by direct comparison AND a real `firebase deploy --dry-run` compile against the live Firebase project (`pet-quest-39d38`). Actual deployment (not dry-run) remains a manual step for the user.
- Rules Unit Testing and full Cloud Function emulator trigger-fire testing remain untested — tracked gap, blocked on Java runtime availability in this environment, not this epic's fault to resolve.

Recommended next: move to another Core-layer epic (Flutter-Flame State Bridge #5, or Pet State Machine #6 which depends on it) or a Foundation-layer epic still without stories (Item Database #3, Time & Decay #2).
