# Epic: Foundation Spine (Boot, DI, Config & Test Harness)

> **Layer**: Foundation
> **GDD**: N/A — cross-cutting infrastructure (ADR-driven). Sources: `docs/architecture/architecture.md` §Initialization order + §Required ADRs 1/2/5/6
> **Architecture Module**: No single module — the boot/DI/config spine that ALL injected-tier modules sit on (architecture.md "Initialization order" + Control Manifest Foundation Layer Rules)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 5 stories created (2026-07-23)

## Overview

This epic builds the load-bearing infrastructure every other Foundation and Core
module attaches to: the dependency-injection reference model (Autoload vs.
injected-tier), the tuning/config data strategy (typed `.tres` Resource classes
with `validate()`), the unified boot-sequencing gate (`GameWorld` Booting →
Wiring → Active, gated behind the Resource & Item Database Ready/Failed signal),
the data-definition immutability pattern, and the headless test harness plus
`CONTRACTS.md` that the whole milestone is verified against. It corresponds to
Milestone 01's first Must-Ship feature ("Boot/DI/config spine + test harness +
CONTRACTS.md"). It is deliberately module-agnostic: it owns the *patterns and the
boot orchestration*, while each module epic owns its concrete implementation.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Inter-System Reference & DI Pattern | Hybrid model — only `TimeTickSystem`/`ResourceItemDatabase` are Autoloads; every other module is injected-tier typed `@export`, wired in `GameWorld.tscn`; all wiring in an explicit `setup()`, never `_ready()` | MEDIUM |
| ADR-0002: Tuning/Config Data Strategy | One custom `Resource`-derived config class per module, typed `@export` fields, `.tres` text files, `validate() -> Array[String]` called once at boot | MEDIUM |
| ADR-0005: Boot Sequencing & Initialization Gate | `GameWorld` Booting state gates ALL injected `setup()` behind RID `Ready`/`Failed`; check-then-connect (`is_ready()` then `validation_complete` CONNECT_ONE_SHOT); BootState `{WAITING_FOR_DATABASE, WIRING, ACTIVE, HALTED}`; boot loads only the initial residency set, not the full world | MEDIUM |
| ADR-0006: Data Definition Immutability & Reference Format | Two-type split (private authoring Resource + public getter-only view); pattern shared infra (concrete RID impl lives in the `resource-item-database` epic) | MEDIUM |

Engine-risk basis (Godot 4.7 knowledge-gap policy): MEDIUM. The spine relies on
post-cutoff behaviors the LLM does not reliably know — scene-tree bottom-up
`_ready()` ordering with `@export` population, `load()` returning the shared
cached Resource (why config is read-only), and Autoloads readying before the Main
Scene. All are documented engine facts in the Control Manifest "Engine Facts That
Differ From LLM Instinct" table and must be cross-referenced against
`docs/engine-reference/godot/` before any API is finalized. No HIGH-risk engine
domain (rendering/physics/nav/input) is touched here.

## GDD Requirements

This epic is ADR-governed rather than GDD-governed. Traceability runs through the
ADRs' "GDD Requirements Addressed" tables. Representative TRs it satisfies (all
covered by an Accepted ADR):

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-scene-world-management-004 | Boot gate: RID Ready before Valley attaches / Building+Villager init; DB failure → terminal halt | ADR-0005 ✅ |
| TR-scene-world-management-023 | Boot-order enforcement owned by a dedicated boot-order mechanism | ADR-0005 ✅ |
| TR-resource-item-database-019 | Validation-complete signal drives the boot gate | ADR-0005 ✅ |
| TR-building-ui-038 / TR-villager-ai-behavior-016 / TR-resource-item-database-007 | Modules are headless-mockable via DI (`Node.new()` + `@export` mocks + `setup()`) | ADR-0001 ✅ |
| TR-scene-world-management-030, TR-voxel-world-023, TR-camera-input-019, TR-time-tick-system-020, TR-building-system-038 | All tunables read from typed `.tres` config, never hardcoded | ADR-0002 ✅ |

**Coverage summary**: All ADR-worthy spine requirements trace to Accepted ADRs
(0001/0002/0005/0006). No untraced requirements.

**At-risk / deferred**: None for MVP. (Save-file serialization, ADR-0012, is
Accepted but VS-tier; it reuses this spine's patterns but is not built here.)

## Milestone 01 Notes

- **Home of the M01 "Boot/DI/config spine + test harness + CONTRACTS.md" feature**
  (milestone-01 Must-Ship #1). Sequence FIRST per the milestone risk register
  ("Production quality bar costs more than slice standards" → boot/DI/config +
  test harness first; property corpus as its own story).
- Does **not** own any tech debt or CD-protected item. It is the substrate the
  tech-debt stories in other epics build on (config-change discipline for the
  per-tick re-tune and ADR-0015 tuning both use this epic's `.tres` + rationale
  pattern).

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- The game boots through the ADR-0005 gate; a headless boot test proves DI wiring
  (ADR-0001) and external config reads (ADR-0002/0006)
- The GdUnit4 headless harness runs and `CONTRACTS.md` exists
- All Logic stories have passing test files in `tests/`

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | GameWorld root scene + injected-tier DI scaffold (`setup()` wiring) | Integration | Ready | ADR-0001 |
| 002 | Boot-sequencing gate — BootState machine + RID Ready/Failed gate | Logic | Ready | ADR-0005 |
| 003 | Config Resource pattern — typed `.tres` + `validate()` two-tier clamp/halt | Logic | Ready | ADR-0002 |
| 004 | Headless boot integration test — DI wiring + gate + config reads, green | Integration | Ready | ADR-0005 |
| 005 | CONTRACTS.md — spine contract sheet + data-definition immutability contract | Config/Data | Ready | ADR-0006 |

Dependency order: 001 → 002 → 003 → 004 → 005 (005 drafted in parallel, finalized after 004).

## Next Step

Run `/story-readiness production/epics/foundation-spine/story-001-gameworld-di-scaffold.md`, then `/dev-story` to begin implementation in dependency order.
