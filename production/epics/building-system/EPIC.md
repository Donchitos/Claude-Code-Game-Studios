# Epic: Building System

> **Layer**: Core
> **GDD**: design/gdd/building-system.md
> **Architecture Module**: Building System (blueprint/project lifecycle; construction job queue/claim contract; placement validity; undo/redo stack; tool state machine)
> **Manifest Version**: 2026-07-23
> **Status**: Ready
> **Stories**: 33 stories created — Block A pre-slice foundation (019–033, TR ~002..101) + Block B slice-revision (001–018, TR-102..127); see Stories table below for build order

## Overview

Building System is the game's central verb — it turns player intent into
structures. It owns the persistent project-entity lifecycle
(DRAFT → BUILDING ⇄ PAUSED → DONE, ADR-0016), the placement toolset (walls/floors/
roofs drag tools, free single-block, furniture), placement validity, pooled-
MeshInstance3D ghost previews, plan-only undo/redo, the worker-claimed
construction job queue (`claim_job`/`release_job`/`on_site_check`), change orders,
and worker-executed demolition (uniform for blocks and furniture). Its placement
pick is DDA-only (structurally incapable of hitting villagers, zero physics
queries). Built cells are authoritative Voxel World data mutated ONLY via worker-
executed jobs — never a direct edit or an undo.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0016: Build-Project Entity Lifecycle | Persistent draft→released→paused→done project entities; 26-neighborhood grouping/merge; change orders attach without recreation; plan-only undo; job-based demolition incl. furniture; cell→project reverse index (O(1) selection); worker attribution — **Accepted, prototype-validated 2026-07-22/23** | MEDIUM |
| ADR-0014: Chunked Voxel Rendering & Large-World Storage | Ghost previews = pooled `MeshInstance3D` (`max_cells_per_command = 512`); ghost-anchored `extra_solid` picking predicate on the §4 DDA path; state colors live on ghost/overlay, never committed-block materials | HIGH |
| ADR-0004: Physics Backend & Picking Strategy | Building System pick calls ONLY the DDA step — zero `intersect_ray`/`PhysicsDirectSpaceState3D` in the pick path (grep-verifiable) | HIGH (shared) |
| ADR-0009: Deterministic Movement & Occupancy Ordering | Seal-prevention negative-write gate: a Planned→Built write that would entrap a villager is gated by reading the discrete `current_cell`/body-column (builder self-seal is the one sanctioned exception, watchdog-healed) | HIGH |
| ADR-0010: Cross-System UI/World Input Arbitration | Build-Mode-gated click routing + Selection arbitration; drag ownership via `_input()` for the drag window; DDA→owning-project resolution feeds Selection | MEDIUM |
| ADR-0012 | `serialize()` includes project entities (`restore_value`, `worker_ids`, pending orders); undo/redo stack excluded — **VS-tier orchestrator** | MEDIUM |
| ADR-0002 / ADR-0001 | Building tunables from typed `.tres` config; injected-tier module | MEDIUM |

Engine-risk basis (4.7 policy): **HIGH** — inherits the rendering/picking HIGH-risk
domain. Ghost rendering (pooled `MeshInstance3D` with `material_override`),
`InputEventKey.echo` for undo/redo repeat, and the DDA-only pick path all sit on
the post-cutoff rendering/input facts flagged in architecture.md. `GridMap` is
forbidden for committed blocks; zero physics in the pick path is grep-verifiable.
Cross-reference `docs/engine-reference/godot/` before any rendering/input API.

## GDD Requirements

96 TRs registered (`TR-building-system-*`) — the largest MVP system. Coverage:

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-building-system-003 / -035 / -039 / -041 | Rendering/ghost representation | ADR-0014 ✅ |
| TR-building-system-002 / -026 | DDA placement pick, zero physics | ADR-0004 / ADR-0014 ✅ |
| TR-building-system-040 | Mid-path solidification race / seal-prevention write gate | ADR-0009 ✅ |
| TR-building-system-038 | Tunables from config | ADR-0002 ✅ |
| TR-building-system-023 / -033 | Serialize projects; exclude undo stack | ADR-0012 / ADR-0016 ✅ (VS orchestrator) |
| (project lifecycle, change orders, demolition, undo) | Draft→built lifecycle, merge, demolition, plan-only undo | ADR-0016 ✅ |

**Coverage summary**: All ADR-worthy TRs trace to Accepted ADRs; the remaining
(majority) are GDD-specified. No untraced requirements.

**At-risk / deferred**: TR-building-system-007 (non-Flat roof formation —
Gable/Hip/Shed) is **VS-tier**; Flat is MVP-sufficient. Do not build the other
three roof algorithms in M01. The save-orchestrator half of ADR-0012 is VS-tier —
M01 builds the `serialize()` contract shape, not the full save/load flow.

## Milestone 01 Notes

- No tech-debt or CD-protected item lands here directly, but M01 delivers the
  **full ADR-0016 lifecycle** as Must-Ship "Building System playable"
  (draft-first projects: draw → release → workers build; room/roof/house tools;
  change orders; worker-executed demolition; plan-only undo), with logic ACs
  covered by unit tests.
- Depends on all five Foundation systems (Voxel World, Camera & Input, RID, Time
  & Tick) + the boot spine being integrated first.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/building-system.md` are verified
- Grep proves zero physics API in the pick path; state colors absent from committed materials
- The full draft→built→demolish lifecycle has passing logic unit tests
- Integration stories have passing tests in `tests/`

## Stories

33 stories in two blocks. **File ids do not equal build order** — the pre-slice
FOUNDATION block (019–033) was storyed second but is the PREREQUISITE for the
SLICE-REVISION block (001–018, TR-102..127). Build order is expressed by each
story's `Depends on:` field and by this table's ordering (foundation first).
Do NOT start a slice-block story until its foundation dependencies are Done.

### Block A — Pre-slice Foundation (TR ~002..101) — build these FIRST

| # | Story | Type | Status | ADR (primary) | Depends on |
|---|-------|------|--------|---------------|------------|
| 019 | Tool state machine (Idle/ToolArmed/Dragging/Suspended) | Logic | Ready | ADR-0010 | Camera & Input (Foundation) |
| 020 | DDA placement pick + surface-aware targeting + highlight | Logic | Ready | ADR-0004 | 019, Voxel World |
| 021 | Commit pipeline — click-vs-drag + bounds clamp | Logic | Ready | ADR-0016 | 020, 019 |
| 022 | Placement validity checks | Logic | Ready | ADR-0016 | 021 |
| 023 | Ghost preview rendering + degradation + state tint | Visual/Feel | Ready | ADR-0014 | 020, 022, 019 |
| 024 | Wall tool — F1 extrude | Logic | Ready | ADR-0016 | 021, 020, 022 |
| 025 | Floor tool — F2 rectangle | Logic | Ready | ADR-0016 | 021, 020, 022 |
| 026 | Roof tool — Flat MVP + formation seam | Logic | Ready | ADR-0016 | 021, 020, 022 |
| 027 | Block tool — single-cell place/replace | Logic | Ready | ADR-0016 | 021, 020, 022, 031 |
| 028 | Furniture placement base — single-cell support + palette | Logic | Ready | ADR-0016 | 021, 022, RID |
| 029 | Construction tick loop (Planned→UnderConstruction→Built, F3) | Logic | Ready | ADR-0016 | 021, Time & Tick |
| 030 | Construction job queue — claim/report/on-site/unreachable | Integration | Ready | ADR-0016 | 029, 004 |
| 031 | Removal tool base — Planned→Canceled + job revoke | Logic | Ready | ADR-0016 | 021, 029 |
| 032 | Undo/redo stack core (command model, bounded, transition-clear) | Logic | Ready | ADR-0016 | 021, 022, Scene/World Mgmt |
| 033 | Voxel World write seam — batched + self-write exemption + completion signal | Integration | Ready | ADR-0016 | 029, 032, Voxel World |

### Block B — Slice-revision (TR-102..127) — build AFTER their foundation deps

| # | Story | Type | Status | ADR (primary) | Depends on |
|---|-------|------|--------|---------------|------------|
| 001 | Build/Editor Mode state machine | Logic | Ready | ADR-0010 | 019 |
| 002 | Project entity + blueprint-cell lifecycle rollup + persistence | Logic | Ready | ADR-0016 | 021, 029 |
| 003 | 26-neighborhood grouping/merge + cell→project reverse index | Logic | Ready | ADR-0016 | 002 |
| 004 | Release ("Bau starten") + job-eligibility transition | Logic | Ready | ADR-0016 | 002 |
| 005 | Worker attribution on job claim | Integration | Ready | ADR-0016 | 004, 030 |
| 006 | Project pause / resume | Logic | Ready | ADR-0016 | 004, 030 |
| 007 | Change orders (attach to BUILDING/PAUSED/DONE) | Logic | Ready | ADR-0016 | 003, 004 |
| 008 | Click-selection via cell→project reverse index | Integration | Ready | ADR-0010 | 003, 001 |
| 009 | Demolition orders — block teardown job contract | Logic | Ready | ADR-0016 | 002, 030, 033 |
| 010 | Project cancel / Abriss | Logic | Ready | ADR-0016 | 009, 015 |
| 011 | Plan-only undo/redo | Logic | Ready | ADR-0016 | 002, 009, 032 |
| 012 | Floor excavation flush-replace + restore_value | Logic | Ready | ADR-0016 | 025, 002, 009, 011 |
| 013 | Dig / mining-zone projects (dig-kind lifecycle) | Logic | Ready | ADR-0016 | 002, 003, 031 |
| 014 | Dig-job on-site exclusion | Integration | Ready | ADR-0016 | 013, 030 |
| 015 | Draft eraser (removal-tool micro-state branch) | Logic | Ready | ADR-0016 | 031, 009, 012 |
| 016 | Multi-cell furniture placement (footprint) | Logic | Ready | ADR-0016 | 028, 002 |
| 017 | Furniture demolition — job-gated, atomic multi-cell | Integration | Ready | ADR-0016 | 016, 009, 015 |
| 018 | Higher-level tool batch contract (system-side) | Logic | Ready | ADR-0016 | 003, 024, 025, 026 |

## Next Step

Run `/story-readiness production/epics/building-system/story-019-tool-state-machine.md`,
then `/dev-story` through Block A in id order, then Block B — each story's `Depends on:`
field (and the tables above) define the unambiguous order regardless of file id.
