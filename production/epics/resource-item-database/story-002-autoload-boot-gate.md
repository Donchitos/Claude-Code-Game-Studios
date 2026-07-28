# Story 002: RID Autoload + load-once + Ready state + boot-gate signal

> **Epic**: Resource & Item Database
> **Status: Complete (2026-07-23 — 121/121 suite green, parent-verified)
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: `design/gdd/resource-item-database.md`
**Requirement**: `TR-resource-item-database-025`, `TR-resource-item-database-034`, `TR-resource-item-database-019`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0005 (Boot Sequencing & Initialization Gate) — primary; ADR-0002/0001 — secondary (Autoload `load()`s its own config)
**ADR Decision Summary**: RID is the BLOCKING boot gate — its `validation_complete(result)` signal drives `GameWorld`'s Booting→Wiring transition. Loads definitions once at boot; a second load/initialize is rejected. Any query outside Ready returns an explicit error per the validation-result contract.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes**: Autoloads fully `_ready()` **before** the Main Scene loads, synchronously in declared order — load-bearing for the boot gate (RID is Ready/Failed before injected-tier `setup()` runs). Boot gate is check-then-connect: synchronous `is_ready()` first, `validation_complete.connect(..., CONNECT_ONE_SHOT)` fallback. Never poll for readiness.

**Control Manifest Rules (this layer)**:
- Required: `GameWorld`'s Booting state gates ALL injected-tier `setup()` calls behind RID `Ready`/`Failed`; check-then-connect; on Failed → boot-halt screen, NO `setup()` calls, terminal (ADR-0005).
- Required: only `ResourceItemDatabase` and `TimeTickSystem` are Autoloads; RID `load()`s its own config via `const CONFIG_PATH`.
- Forbidden: never poll for boot readiness (use the signal); no injected-tier `setup()` call site outside `GameWorld`'s Booting path.

---

## Acceptance Criteria

*From GDD `design/gdd/resource-item-database.md`, scoped to this story:*

- [ ] Given valid data files, on boot the database reaches Ready and loads its definitions once (GDD AC1). [TR-resource-item-database-025]
- [ ] A second load/initialize call mid-session is rejected with an error result and the Ready contents are unchanged (GDD AC28). [TR-resource-item-database-025]
- [ ] In any non-Ready state (Unloaded, Validating, Failed), any lookup API call returns an explicit error result per the validation-result contract — never data, never a partial read (GDD AC17). [TR-resource-item-database-034]
- [ ] The `validation_complete` signal drives Scene/World Management's Booting→Wiring gate; RID reaches Ready before Building System / Villager AI initialize (GDD boot-gate contract). [TR-resource-item-database-019]

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

- `ResourceItemDatabase` Autoload with a `BootState`-style lifecycle: `{Unloaded, Validating, Ready, Failed}`. Emit `validation_complete(result)` once when validation resolves.
- Load definitions once via `const CONFIG_PATH` / the definitions directory; guard against a second initialize (return an error result, leave Ready contents intact).
- Every public query checks state first: outside Ready → explicit error result (per the structured validation-result contract from Story 005), never a partial read.
- Expose `is_ready()` (synchronous) so `GameWorld` can check-then-connect; do NOT expose a polling loop.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: the definition schema/wrapper being loaded.
- Story 003: the lookup query methods themselves.
- Stories 004–006, 008: the validation checks that decide Ready vs Failed and populate the structured result.
- Scene/World Management's boot-HALT presentation (its own epic; this story emits the signal it consumes).

---

## QA Test Cases

- **AC-1 (Ready on valid data)**: Given a valid fixture data set; When the DB initializes; Then state = Ready and `validation_complete` fired with a passing result.
- **AC-2 (load-once)**: Given a Ready DB; When initialize is called again; Then it returns an error result and contents are unchanged.
- **AC-3 (non-Ready query guard)**: Given the DB in Unloaded / Validating / Failed; When any lookup is called; Then an explicit error result is returned (never data). Test all three states.
- **AC-4 (gate signal)**: Given a boot harness connecting via `is_ready()` then `validation_complete` fallback; When the DB resolves; Then exactly one gate transition is triggered (no double-fire; `CONNECT_ONE_SHOT`).

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: neues-spiel/`tests/integration/resource_item_database/boot_gate_test.gd` (GdUnit4) — instantiate via `Node.new()`, inject a mock config/data path, call `setup()` directly; assert states and the `validation_complete` emission without Autoload registration. Must pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (definition schema/wrapper must be DONE).
- Unlocks: Story 003, Story 004.
