# Architecture Traceability Index

Last Updated: 2026-07-11
Engine: Flutter 3.44.4 / Flame 1.37.0 / Dart 3.12.2

> Persistent index maintained across `/architecture-review` runs. Re-run the review
> after each new ADR is written to verify coverage improves; this file is refreshed
> each time. Full narrative findings (conflicts, engine audit, blocking issues) live in
> the dated report — see `docs/architecture/architecture-review-2026-07-11.md` for the
> most recent full write-up.

## Coverage Summary

- Total requirements: 104
- Covered: 52 (50.0%)
- Partial: 1 (1.0%)
- Gaps: 51 (49.0%)

## Full Matrix

See `docs/architecture/architecture-review-2026-07-11.md` § "Full Traceability Matrix"
for the complete 104-row matrix (kept in the dated report to avoid duplicating a large
table across two files — this index tracks summary state and known gaps only).

## Known Gaps

| Gap TRs | Suggested ADR Title | Domain | Engine Risk |
|---|---|---|---|
| TR-seedbuffer-001..003 | Seed Buffer Derivation Strategy | Data/derived-state | LOW |
| TR-parentapproval-001,002,003,004,005,006,008 | Parent Approval Transaction Design | Concurrency/economy | LOW-MEDIUM |
| TR-gacha-001..005 | Gacha/Loot Roll Architecture | Economy/RNG | LOW |
| TR-shop-001..004 | Shop Purchase Pipeline & Idempotency Fix (resolves QQ-01) | Economy/concurrency | MEDIUM |
| TR-petinteraction-002..004 | Pet Interaction Input Handling | Flame input | MEDIUM |
| TR-petequip-001..004 | Pet Equipment Ownership & Rendering | Flame rendering | LOW-MEDIUM |
| TR-leveling-001..005 | Pet Leveling & Evolution Consistency | Progression | LOW engine / HIGH design (must resolve xuBonus contradiction, see report B1) |
| TR-navshell-001..004 | Navigation Shell & Route Guard | Flutter routing | MEDIUM |
| TR-petroom-001,003,004,005 | Pet Room Rendering & Interaction Contract | Flame canvas | MEDIUM-HIGH |
| TR-taskui-001..004 | Task Management UI Data & Interrupt | Flutter state | LOW-MEDIUM |
| TR-shopui-001..004 | Shop/Reward Ceremony UI State | Flutter nav | MEDIUM |
| TR-parentdash-001..004 | Parent Dashboard Banner State Machine | Flutter/FCM | LOW-MEDIUM |

## Superseded Requirements

None yet — this is the first review pass with real TR-IDs (registry was previously
empty). Future reviews will list here any requirement whose GDD wording changed enough
to warrant a new TR-ID rather than an in-place `revised:` update.

## Review History

| Date | Verdict | Covered / Total | Notes |
|------|---------|------------------|-------|
| 2026-07-11 | CONCERNS | 52/104 (50%) | First full review. 9 must-have ADRs drafted (all Proposed, none Accepted yet). 3 GDD revision flags applied (time-decay, data-persistence-layer, flutter-flame-state-bridge → Needs Revision in systems-index.md). 1 GDD self-contradiction found (pet-leveling-evolution.md xuBonus, B1). |
