# Story 003: Recovery-report API, source→rate table & F2 recovery

> **Epic**: Needs & Mood System
> **Status: Complete (2026-07-26 — 1175/1175 suite green 0 orphans, agent-verified; parent re-verifies with the concurrent building-023)
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: ~1.5 agent-days
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md`
**Requirement**: `TR-needs-mood-system-034`, `TR-needs-mood-system-035`, `TR-needs-mood-system-036`, `TR-needs-mood-system-042`, `TR-needs-mood-system-044`, `TR-needs-mood-system-050`, `TR-needs-mood-system-052`, `TR-needs-mood-system-053`, `TR-needs-mood-system-065`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0002 (the source→rate table is owned config data) — primary; ADR-0008 (the reporting contract with Villager AI's FSM)
**ADR Decision Summary**: All tunable values live in the typed config Resource, read-only at runtime; the ladder's three multipliers are config knobs whose ordering invariant is enforced at load (story 001). Villager AI reports recovery through discrete `start_recovery`/`stop_recovery` calls from its FSM — it never pushes per-tick recovery amounts, and Needs & Mood never reaches back into Villager AI, Building System, or the item database at runtime.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: Pure GDScript. Default synchronous signal delivery is what makes the intra-tick ordering rule implementable without a deferred queue: a `stop_recovery` arriving from a synchronously-delivered revocation lands **before** that tick's F-pass, so the interruption tick credits zero recovery.

**Control Manifest Rules (this layer)**:
- Required (Foundation): the source→rate table is config data, typed and validated (`.tres`), never a hardcoded branch; config is read-only at runtime.
- Required (Feature): recovery is reported, never inferred — this system scores, Villager AI acts.
- Forbidden: any runtime call into Building System or Resource & Item Database from this module (grep-verifiable); a hardcoded bed/ground `if` in F2.
- Guardrail: F2 is an O(1) table lookup per recovering need per tick; the table is read, never rebuilt per tick.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] Recovery is reported through **discrete** calls — `start_recovery(villager_id, need, source_enum)` and `stop_recovery(villager_id, need, reason)` — not per-tick pushes; `start_recovery` is the only entry into the `Recovering` state. [TR-needs-mood-system-042] [TR-needs-mood-system-034]
- [ ] The source→rate table is keyed by the reported enum `bed_sheltered` / `bed_unsheltered` / `ground_no_bed_owned` / `ground_bed_unreachable` / `ground_trapped`, with the three `ground_*` values sharing **one** rate row (×`ground_penalty`); the sheltered/unsheltered distinction is supplied by the reporter, never derived here. [TR-needs-mood-system-035] [TR-needs-mood-system-036]
- [ ] **AC8**: Given a Recovering need with a mocked `bed_sheltered` source, When 1 tick fires, Then the value increases by exactly `base_recovery_per_tick × 1.0` (F2). [TR-needs-mood-system-053]
- [ ] **AC28**: Given a mocked `bed_unsheltered` source, When 1 tick fires, Then the increase is exactly `base_recovery_per_tick × unsheltered_bed_multiplier` — the ladder's middle rung. [TR-needs-mood-system-053]
- [ ] **AC9**: Given a mocked ground source, When 1 tick fires, Then the increase is `base_recovery_per_tick × ground_penalty`; all three `ground_*` enum values produce the identical increase. [TR-needs-mood-system-053]
- [ ] **AC10**: Given a mocked **new** source id with its own multiplier, When Recovering, Then F2 applies it via table lookup with **no code change** — no hardcoded two-source branch. [TR-needs-mood-system-065]
- [ ] **AC11**: Given a Recovering need crossing `satisfied_threshold`, When the upward cross occurs, Then exactly one "need satisfied" signal is emitted, recovery stops (state → `Satisfied`), and an overshoot of at most one increment is retained — the value is left where it lands. [TR-needs-mood-system-033] [TR-needs-mood-system-053]
- [ ] **AC33**: Given `value = 99.0`, `satisfied_threshold = 100` and increment 2.0 (legal knob extremes), When a recovery tick fires, Then the value is exactly 100.0, never above — the F2 domain clamp `min(100, …)`. [TR-needs-mood-system-053]
- [ ] While Recovering, the need does **not** decay — F2 replaces F1 for that need that tick. [TR-needs-mood-system-053]
- [ ] **Intra-tick ordering**: `start_recovery` / `stop_recovery` reports and source changes land BEFORE that tick's F1–F3 pass; an interruption tick credits **zero** recovery. [TR-needs-mood-system-044]
- [ ] Villager AI's Breather is excluded by construction: no report, no recovery, and **no pause of decay** — a Breather villager's need decays exactly as an idle one's does. [TR-needs-mood-system-050]
- [ ] The module makes **zero** runtime calls into Building System or Resource & Item Database — verified by grep and by a mock-call-count assertion. [TR-needs-mood-system-052]

---

## Implementation Notes

*Derived from ADR-0002/0008 Implementation Guidelines:*

- The table is `Dictionary[StringName, float]` built once from config at `setup()` — five enum keys today, three distinct values. Adding a rung is a config edit plus a key; AC10 is the test that proves it.
- `start_recovery` stores the **reported source per (villager, need)**; each recovery tick re-reads that stored source rather than the one captured at start (story 004 makes it change mid-recovery).
- The satisfied cross is the only value-based exit. Do not clamp back to `satisfied_threshold` — the GDD explicitly keeps the overshoot. The only ceiling is the 0–100 domain clamp (AC33).
- Signature note: the GDD writes `start_recovery(need, source_enum)`; `docs/architecture/architecture.md` and `neues-spiel/architecture.md:373 (NOT CONTRACTS.md — TD ruling NM-5: that file carries no start_recovery reference)` write the villager-id form. **Implement the villager-id form** — this system is per-villager and the GDD text elides the subject.
- Intra-tick ordering: reports mutate state immediately (synchronous), and the F-pass reads that state. Never queue a report for "next tick"; never apply a partial increment on the stop tick.
- Zero outward calls: this module receives ids and enums as opaque values. It never resolves a bed id against the item database, and never asks Building System whether a bed still exists — the reporter tells it.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: what happens when recovery is interrupted or the source changes mid-recovery.
- Story 005: mood.
- Story 007: the why-string built from the same source enum.
- Story 010: the real (unmocked) Villager AI reporting the enum.

---

## QA Test Cases

- **AC8**: Given Recovering with `bed_sheltered`, `base_recovery_per_tick = 0.5`, `value = 30.0`, When 1 tick fires, Then `value == 30.5`.
- **AC28**: Given `bed_unsheltered` and `unsheltered_bed_multiplier = 0.7`, When 1 tick fires, Then `value == 30.35`.
- **AC9**: Given each of `ground_no_bed_owned`, `ground_bed_unreachable`, `ground_trapped` with `ground_penalty = 0.4`, When 1 tick fires, Then each yields `value == 30.2` — identical across all three.
- **AC10**: Given a table extended at runtime-config level with `bed_masterwork = 1.5`, When Recovering from that source, Then the increase is `0.5 × 1.5` with no code path added.
- **AC11**: Given `value = 94.8` Recovering at 0.5 with `satisfied_threshold = 95`, When the tick fires, Then `value == 95.3`, exactly one `need_satisfied` emission, and state reads `Satisfied`; When a further tick fires, Then no second emission.
- **AC33**: Given `value = 99.0`, `satisfied_threshold = 100`, increment 2.0, When 1 recovery tick fires, Then `value == 100.0` exactly.
- **No-decay-while-recovering**: Given Recovering, When 1 tick fires, Then the net change equals the recovery increment with no decay subtracted.
- **Intra-tick ordering**: Given a villager Recovering, When `stop_recovery` is called and a tick then fires, Then the value is unchanged for that tick (zero credited); When `start_recovery` is called and a tick then fires, Then a full increment is credited for that same tick.
- **Breather exclusion**: Given a villager in Breather with no recovery report, When ticks fire, Then the need decays at the normal F1 rate — no pause, no recovery.
- **Isolation**: Given the module under test with mock Building System / item-database doubles wired as neighbours, When a full recovery cycle runs, Then those mocks record **zero** calls.
- Edge cases: `start_recovery` on an already-Recovering need is idempotent for the same source; `stop_recovery` for a need that is not Recovering is a documented no-op; an unknown source enum fails loudly rather than silently recovering at 1.0.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `neues-spiel/tests/unit/needs_mood/recovery_source_rate_table_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 001 (config + ladder knobs), 002 (state machine, tick pass)
- Unlocks: 004, 007, 008, 010
