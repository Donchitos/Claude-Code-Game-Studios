# Architecture Traceability Index

**Last Updated:** 2026-08-21
**Engine:** Godot 4.6 (pinned 2026-02-12)
**Source review:** `docs/architecture/architecture-review-2026-08-21.md`

Full per-requirement IDs and text live in `docs/architecture/tr-registry.yaml` (399 entries).
This index records coverage status against the current ADR set.

## Coverage Summary

- Total requirements: **399**
- ✅ Covered: ~19 (~5%)
- ⚠️ Partial: ~8
- ❌ Gaps: ~372

Coverage is early-stage by design: 2 ADRs exist against a 13-system corpus. The tracked
signal is not raw gap count but the **~7 architecture decisions the GDDs self-declare and
no ADR yet covers** (see Known Gaps).

## Covered / Partial Matrix

| TR-ID | GDD | Requirement (abridged) | ADR | Status |
|-------|-----|------------------------|-----|--------|
| TR-reliquias-003 | reliquias-bendiciones.md | `effective_stat(u,s,t)` per-instance over read-only base | ADR-0001 | ✅ |
| TR-reliquias-004 | reliquias-bendiciones.md | Combate exposes `effective_attack_damage(instance)` read-hook | ADR-0001 | ✅ |
| TR-reliquias-005 | reliquias-bendiciones.md | Modifier keyed `(relic_id, unit_instance_id)`, per-instance | ADR-0001 | ✅ |
| TR-reliquias-006 | reliquias-bendiciones.md | Never write `CombatProfile`/`HeroDefinition`; ephemeral layer only | ADR-0001 | ✅ |
| TR-reliquias-007 | reliquias-bendiciones.md | Additive across distinct relics; refresh-on-repick per relic_id | ADR-0001 | ✅ |
| TR-reliquias-008 | reliquias-bendiciones.md | `max_stat_bonus(s)` bound computable | ADR-0001 | ⚠️ (structure only) |
| TR-reliquias-009 | reliquias-bendiciones.md | Flat additive `+N`, no percent multipliers (Combate Regla 5) | ADR-0001 | ✅ |
| TR-reliquias-020 | reliquias-bendiciones.md | Expiry by physics tick, semi-open interval | ADR-0001 + ADR-0002 | ✅ (tick source = TimeControl.game_tick) |
| TR-reliquias-021 | reliquias-bendiciones.md | Expiry swept at tick start, before phase-1 damage | ADR-0001 | ✅ |
| TR-reliquias-022 | reliquias-bendiciones.md | Defensive expiry clamps, never `apply_damage`, never kills | ADR-0001 | ✅ |
| TR-reliquias-023 | reliquias-bendiciones.md | Instant effects skip tick bookkeeping | ADR-0001 | ⚠️ (partial) |
| TR-combate-001 | combate-dano.md | Single `apply_damage` path (Regla 1) | ADR-0001 | ✅ (constraint honoured) |
| TR-permadeath-003 | permadeath.md | `game_time_paused` ownership + consumers | ADR-0002 | ✅ (owner → TimeControl; Permadeath requests PAUSED) |
| TR-permadeath-004 | permadeath.md | Cooperative pause, never `SceneTree.paused` | ADR-0002 | ✅ |
| TR-permadeath-006 | permadeath.md | Beat clock exempt, unscaled delta | ADR-0002 | ⚠️ (mechanism reconciliation — see GDD flag) |
| TR-reliquias-024 | reliquias-bendiciones.md | `offering_time_scale` uniform slow-mo; requests, not owns | ADR-0002 | ✅ |
| TR-reliquias-025 | reliquias-bendiciones.md | Time-scale applier + fixed-step interaction + exemptions | ADR-0002 | ✅ |
| TR-reliquias-026 | reliquias-bendiciones.md | Precedence PAUSED > SLOWED; offering preserved | ADR-0002 | ✅ |
| TR-reliquias-027 | reliquias-bendiciones.md | Anti-stall timers run real-time | ADR-0002 | ⚠️ (exemption implied, not enumerated) |
| TR-combate-029 | combate-dano.md | Cooldowns follow game time; freeze on `game_time_paused` | ADR-0002 | ✅ |
| TR-kaiju-029 | encuentro-con-kaiju.md | Cooperative freeze on `game_time_paused` (Regla 11) | ADR-0002 | ✅ |
| TR-kaiju-030 | encuentro-con-kaiju.md | All clocks accumulate game-time delta in `_physics_process` | ADR-0002 | ⚠️ (clock source now TimeControl) |
| TR-temporizador-010 | temporizador-de-preparacion-ritual.md | `elapsed_s` accumulates game-time delta (pause/scale aware) | ADR-0002 | ✅ |
| TR-heroes-023 | sistema-de-heroes.md | Beat animation node exempt from pause | ADR-0002 | ⚠️ (mechanism reconciliation — see GDD flag) |

## Known Gaps (require ADRs)

Foundation layer:
- **Save / Persistence** — checksum, serialization, ephemeral-invocation round-trip
  (OQ-RB2), `expiry_tick` rebasing on reload, `forge_counter` int64, schema migration.
  Cross-review blocker S4; both existing ADRs defer to it.
- **Era lifecycle / init-ordering** — `LOADING→LOADED`, era-`LOADED` signal, Autoload
  init order (TR-era-011, TR-permadeath-017), per-era cap re-validation.
- **Camera/zoom constant ownership** — `world_unit_scale`/`camera_pan_speed`/`zoom_min`/
  `zoom_max` (Era vs Control), `Camera2D.zoom` sign (OQ-INPUT-2, F2-W5).
- **Input context enforcement** — `current_context` contract (OQ-INPUT-5) + Pillar-1
  frame ordering Input→Control→Permadeath (OQ-INPUT-1).

Feature layer:
- **`CombatProfile` storage** — Combate OQ-1 (embedded vs parallel resource); ADR-0001
  left it open.
- **Relic-registry representation** — Forja OQ-FL4/FL5 + Reliquias OQ-RB6.
- **Kaiju intent-controller** — controller home + immediate `apply_damage` wiring + sole-
  caller exclusion from Combate's auto-attack loop.
- **Permadeath implementation-pattern** — OQ-P5 (Autoload vs node, reset_queue softlock,
  hook forms, 4.6 engine spike).

Cross-cutting:
- **Config-enforcement + determinism convention** — loud-fail vs clamp split across ~10
  GDDs; seeded-RNG / monotonic-`entity_id` seam. ADR or control-manifest.

## Superseded Requirements

None yet — first review; no GDD was revised after an ADR referencing it was written.
(Note: ADR-0002 supersedes ADR-0001's provisional `Engine.get_physics_frames()` tick
source with `TimeControl.game_tick` — an ADR-internal supersession, not a requirement one.)
