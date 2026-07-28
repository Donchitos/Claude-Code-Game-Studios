# Story 005: CONTRACTS.md — spine contract sheet + data-definition immutability contract

> **Epic**: Foundation Spine (Boot, DI, Config & Test Harness)
> **Status: Complete (2026-07-23 — doc story, signatures grep-verified, suite 128/128, parent-verified)
> **Layer**: Foundation
> **Type**: Config/Data
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: (set by /dev-story when implementation begins)

## Context

**GDD**: N/A — ADR-driven infrastructure. CONTRACTS.md is a Milestone-01 Must-Ship deliverable ("Boot/DI/config spine + test harness + CONTRACTS.md").
**Requirement**: `TR-resource-item-database-010`, `TR-resource-item-database-023`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time. These two are ADR-0006's data-definition immutability + `visual_asset` requirements, captured here as a written contract for the `resource-item-database` epic to implement against.)*

**ADR Governing Implementation**: ADR-0006: Data Definition Immutability & Reference Format (primary); ADR-0001/0002/0005 (secondary — the DI, config, and boot contracts CONTRACTS.md also records)
**ADR Decision Summary (ADR-0006)**: Two-type split — a private, freely `@export`-editable `ItemDefinitionResource` for authoring/storage, and a public getter-only `ItemDefinition extends RefCounted` view that `get_by_id()` returns (wrapping, never copying, the stored data). `visual_asset` is a typed `Mesh` reference, not a path string. `ItemDefinition` has zero setters and zero writable `var`s.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM
**Engine Notes** (from ADR-0006 Engine Compatibility): the `RefCounted`-wrapping-a-`Resource` pattern is valid with no lifecycle gotcha. Note the documented residual: GDScript's `Object.get("_source")` reflection can bypass the getter-only wrapper — the guarantee is against accidental/idiomatic misuse, not deliberate reflection. Boot validation must check the `ItemDefinitionResource` loaded non-null BEFORE the `visual_asset != null` check (distinct diagnostics, both terminal). Cross-reference `docs/engine-reference/godot/`.

**Control Manifest Rules (Foundation Layer)**:
- Required: data definitions two-type split — private `ItemDefinitionResource` + public getter-only `ItemDefinition extends RefCounted` returned by `get_by_id()`, a fresh lightweight wrapper per call (wraps, never copies); `visual_asset` is a typed `Mesh`, never a path string; boot validation checks resource-null BEFORE `visual_asset != null`, distinct diagnostics, both terminal.
- Forbidden: `ItemDefinition` has zero setters and zero writable `var`s; nothing outside RID holds an `ItemDefinitionResource`; cross-system references are opaque string ids only; never defensive-copy via `duplicate()` for definition queries.
- Global: one terminal-halt severity model (RID Failed pattern) reused by config blocking-invariants (ADR-0002) and data-definition validation (ADR-0006) — never invent a new severity scheme.

---

## Acceptance Criteria

*This story writes `CONTRACTS.md` — the contract every Milestone-01 system is verified against:*

- [ ] `CONTRACTS.md` exists at the project root (or `docs/` — location fixed at `/dev-story`), dated, referencing Manifest Version 2026-07-23.
- [ ] It records the **DI contract** (ADR-0001): injected-tier `@export` + `setup()`, the two Autoloads, the "never `@export` an Autoload / never wire in `_ready()`" rules.
- [ ] It records the **config contract** (ADR-0002): one `Resource`-derived config per module, `validate()` two-tier clamp/halt, read-only-at-runtime, `.tres` only.
- [ ] It records the **boot contract** (ADR-0005): `BootState` machine, RID Ready/Failed unified gate, check-then-connect, terminal halt.
- [ ] It records the **data-definition immutability contract** (ADR-0006): the two-type split, getter-only `ItemDefinition`, `visual_asset` as typed `Mesh`, resource-null-before-visual-asset validation order — as the binding contract the `resource-item-database` epic implements against.
- [ ] Each contract entry cites its governing ADR and the relevant TR-IDs so downstream stories can trace back.
- [ ] It notes the single terminal-halt severity model shared by ADR-0002 (config blocking invariants), ADR-0005 (RID Failed), and ADR-0006 (data-definition validation).

---

## Implementation Notes

*Derived from ADR-0006 Decision (two-type split) and the epic's DoD ("CONTRACTS.md exists"):*

- CONTRACTS.md is a **written contract sheet**, not code — it is the durable reference the milestone's later systems (RID, Building System, Villager AI) implement against and that reviews check compliance with. It mirrors the Control Manifest's Foundation-layer rules but framed as promises this spine makes to its consumers.
- The ADR-0006 data-definition immutability pattern has **no standalone code in this epic** — the concrete `ItemDefinitionResource` / `ItemDefinition` types live in the `resource-item-database` epic. This story captures the pattern as a contract so RID's implementation has an authoritative, single-source description to build against.
- The prototype's `prototypes/last-seal-vertical-slice/CONTRACTS.md` is reference-only (throwaway slice) — do not import it; author fresh to production standards from the Accepted ADRs.
- Keep it concise and grep-friendly: one section per contract (DI / Config / Boot / Data-Definition), each with Required / Forbidden / governing ADR + TR-IDs.

---

## Out of Scope

*Handled by neighbouring stories / other epics — do not implement here:*

- The concrete `ItemDefinitionResource` / `ItemDefinition` type implementations and the RID boot validation pipeline — `resource-item-database` epic (this story writes the contract they satisfy).
- Stories 001–004: the actual DI/gate/config code and boot test (CONTRACTS.md documents them, does not build them).
- Save/load serialization contract (ADR-0012) — VS-tier, not this milestone.

---

## QA Test Cases

*Config/Data story — smoke-check verification (no automated logic test):*

- **Manual check (contract completeness)**:
  - Setup: open `CONTRACTS.md`.
  - Verify: all four contracts (DI, Config, Boot, Data-Definition) are present, each cites its governing ADR (0001/0002/0005/0006) and relevant TR-IDs, and the shared terminal-halt severity model is noted.
  - Pass condition: a developer picking up the `resource-item-database` epic can implement the two-type split from CONTRACTS.md alone without re-reading ADR-0006.

- **Manual check (no stale/prototype content)**:
  - Setup: diff CONTRACTS.md against `prototypes/last-seal-vertical-slice/CONTRACTS.md`.
  - Verify: it is authored fresh (not copied), reflects Manifest Version 2026-07-23, and contains no slice-only assumptions (e.g. `CULL_DISABLED`, full-world-at-boot).
  - Pass condition: no reference-only prototype text carried over.

---

## Test Evidence

**Story Type**: Config/Data
**Required evidence**:
- Smoke check pass recorded at `production/qa/smoke-[date].md` confirming CONTRACTS.md completeness against the four ADRs.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Stories 001–004 substantively DONE (CONTRACTS.md should describe the as-built spine, not a projection). Can be drafted in parallel and finalized once 001–004 land.
- Unlocks: `resource-item-database` epic (implements the data-definition contract) and every downstream module (implements the DI/config/boot contracts).
