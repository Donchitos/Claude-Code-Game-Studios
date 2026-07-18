# Epic: Currency System

> **Layer**: Core
> **GDD**: design/gdd/currency-system.md
> **Architecture Module**: Currency System (#7)
> **Status**: Complete
> **Stories**: 1 story created (2026-07-16), Complete — see table below

## Overview

This epic implements the game's single currency (xu): an increment-only balance
with closed sources (task approval, Gacha chest reward) and closed sinks (Shop
item purchase, Paid Chest purchase). It owns `xuBalanceProvider`, a realtime
stream scoped to the active child. The ≥0 floor is enforced by the *consumer*
(Shop) pre-write, not by this module or by Security Rules — deliberately, to
avoid an extra transaction cost that ADR-0008 judged unjustified for the honest-
client threat model this project targets. This module also owns the
screen-scoped `isPurchasing` single-flight guard requirement that Shop must
implement to prevent the honest-client double-tap race.

**Exit-criteria note (from `/gate-check` 2026-07-13 Pre-Production→Production and
the vertical slice)**: ADR-0008 prescribes `.valueOrNull` for reading
`xuBalanceProvider` safely — the vertical slice found `riverpod` 3.x removed
`.valueOrNull` (`.value` is now the safe accessor). Verify which applies against
the pinned production `riverpod` version before writing `xuBalanceProvider`
(same check as the Auth & Account epic — do this once, apply consistently).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0008: Currency & Balance Mutation Rules | Single currency, `FieldValue.increment()`-only mutation; closed sources/sinks; ≥0 floor enforced by Shop pre-write, not this module; realtime `xuBalanceProvider`; screen-level single-flight purchase guard (mandatory) | LOW — mostly inherits ADR-0003's transaction/increment guarantees; the `.valueOrNull` version check is the only open item |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-currency-001 | Single currency (xu); no dual-currency, IAP, or ad-reward paths | ADR-0008 ✅ |
| TR-currency-002 | All balance mutation via `FieldValue.increment()` | ADR-0008 ✅ |
| TR-currency-003 | Balance floor of ≥0 enforced pre-write by the consumer, plus a screen-level single-flight guard | ADR-0008 ✅ |
| TR-currency-004 | `xuBalanceProvider` is a realtime stream scoped to the active child | ADR-0008 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/currency-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- The `.valueOrNull`/`.value` exit-criteria note above has been resolved before `xuBalanceProvider` is marked done
- A test explicitly covers the negative-balance defense (UI displays 0, disables purchases, never renders/crashes on a negative value)

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | xuBalanceProvider (Realtime Balance Read) | Integration | Complete | ADR-0008 |

**Dependency note**: ADR-0008 explicitly states Currency owns NO mutation method — balance writes happen inside Parent Approval (#11)/Gacha (#12)/Shop (#13)'s own transactions, none of which exist as epics yet. TR-currency-001/002/003 are documented as binding constraints on those future epics, not independently buildable now. Only TR-currency-004 (`xuBalanceProvider`, the read side) is in scope here — hence a single-story epic.

## Next Step

Epic complete. `xuBalanceProvider` now exists for future Presentation-layer epics (Main Nav Shell #17, Shop & Reward UI #20) to display. Parent Approval (#11)/Gacha (#12)/Shop (#13) must satisfy TR-currency-001/002/003 as binding constraints when they eventually mutate `xuBalance` — cross-reference ADR-0008 at that time.
