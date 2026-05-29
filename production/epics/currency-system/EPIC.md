# Epic: Currency System

> **Layer**: Feature
> **GDD**: design/gdd/currency-system.md
> **Architecture Module**: Currency System
> **Status**: Ready
> **Stories**: 3/3 Complete

## Overview

The Currency System manages two currencies: **Coins** (earned via matches, quests, ads; spent on cosmetics and offers; hard ceiling 50,000) and **Diamonds** (IAP-purchased; spent on premium items, Battle Pass, Play Pass; no ceiling). All credit and debit operations accept a caller-supplied idempotency key, with a PostgreSQL UNIQUE constraint as the double-grant backstop. `creditCoins` uses `LEAST(balance + amount, 50_000)` SQL to enforce the ceiling atomically. `debitCoins` throws `InsufficientFundsError` if result < 0. After every write, `profile:refresh` is emitted.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Economy Transaction Safety | Idempotency keys; UNIQUE DB constraint; 50k ceiling via SQL LEAST; InsufficientFundsError | LOW |
| ADR-0005: Database Architecture | Coin/diamond balances in player_profiles; idempotency_key on transactions table | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0008 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/currency-system.md` verified
- Duplicate idempotency key → second call returns first result, balance unchanged (unit test)
- creditCoins beyond 50,000 → clamped to 50,000, no error (unit test)
- debitCoins with insufficient balance → InsufficientFundsError, balance unchanged (unit test)
- 1000 concurrent creditCoins → correct final balance (load test)

## Next Step

Run `/create-stories currency-system` to break this epic into implementable stories.
