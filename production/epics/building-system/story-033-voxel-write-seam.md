# Story 033: Voxel World write seam — batched bulk-write + self-write exemption + completion signal

> **Epic**: Building System
> **Status: Complete (2026-07-24 — 827/827 suite green 0 orphans, parent-verified)
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1 day
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/building-system.md`
**Requirement**: `TR-building-system-070`, `TR-building-system-071`, `TR-building-system-072`, `TR-building-system-024`, `TR-building-system-075`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016 (Build-Project Entity Lifecycle) — primary; ADR-0014 (chunked storage / bulk-write) — secondary; ADR-0009 (synchronous signals) — secondary
**ADR Decision Summary**: Built cells mutate only via worker-executed jobs through Voxel World's single batched write path; N cells changing in one frame emit exactly ONE batched signal. Godot signals are synchronous — the self-write exemption prevents re-entrant undo self-invalidation.

**Engine**: Godot 4.7-stable | **Risk**: MEDIUM (Integration with Voxel World; ADR-0009 synchronous-signal fact is load-bearing)
**Engine Notes**: Default signal connections are synchronous (in the `emit()` call stack). The bulk-write API's return value AND the batched signal payload carry per-cell before/after contents (keeps undo lossless). Load-before-write for far-world mutations lives in Voxel World's single batched write path, not here.

**Control Manifest Rules (this layer — Core / write seam):**
- Required: when multiple cells complete/are removed in the same frame, use Voxel World's bulk-write API so ONE batched signal fires (never one per cell); self-originated writes are tagged and ignored by this system's own undo-invalidation listener; a construction-completed signal to Build Validation is batched per FRAME.
- Forbidden: never emit one signal per cell for a multi-cell change; never let the undo-invalidation listener re-enter and self-invalidate entries mid-unwind.
- Guardrail: batching bounds signal count to one per frame regardless of cell count.

---

## Acceptance Criteria

*From GDD `design/gdd/building-system.md`, scoped to this story:*

- [ ] AC46: GIVEN this system completes a cell (its own Voxel World write), WHEN its undo-invalidation listener receives the resulting write signal, THEN the signal is recognized as self-originated and NO undo entry is invalidated (self-write exemption). [TR-024]
- [ ] AC47: GIVEN N cells complete in the same frame (parallel villagers or multi-cell undo removal), WHEN the writes are issued, THEN Voxel World's bulk-write API is used and exactly ONE batched signal fires. [TR-072]
- [ ] AC33: GIVEN a command's cell was modified by another system, WHEN that command is undone, THEN the stale entry is skipped without error or double-removal (undo bookkeeping). [TR-071]
- [ ] A construction-completed signal to Build Validation is batched per frame — N completions across any commands/villagers in one frame fire ONE completion signal. [TR-075]

---

## Implementation Notes

*Derived from ADR-0016 + building-system Interactions (Voxel World, Build Validation) + ADR-0009 synchronous-signal fact, TR-070/071/072/024/075:*

- The only mutation path to Voxel World: call the write API (set/clear cell) when blueprint cells complete or built cells are removed; use the read/raycast API for picking/validity.
- Batching: when multiple cells complete or are removed in the same frame (parallel villagers, multi-cell undo/demolition), use Voxel World's bulk-write API so ONE batched signal fires — never one per cell (per Voxel World's batching mandate). The batched payload + return carry per-cell before/after contents (lossless undo).
- Self-write exemption (AC46): tag writes originating from this system (cell completion, undo removal); this system's undo-invalidation listener MUST ignore them. Godot signals are synchronous — without this, unwinding a command would re-enter the listener mid-unwind and self-invalidate the entries being processed.
- Undo bookkeeping (AC33): a cell changed by another system invalidates affected undo entries; a stale entry is skipped without error or double-removal on undo. (Narrower post-slice: since undo never targets Built cells (Story 011), this guards the self-write-exemption bookkeeping around still-pending entries.)
- Build Validation seam: expose a "construction completed" signal batched per FRAME — N cells completing in one frame fire ONE signal (avoids N region re-analyses).

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 032: the undo stack itself (this story keeps its bookkeeping honest via signals).
- Voxel World's bulk-write internals + load-before-write for far-world (Voxel World epic — this story consumes the API).
- Build Validation's region analysis — separate MVP system (M02).

---

## QA Test Cases

**AC46 — self-write exemption**
- Given: this system issues a Voxel World write (cell completion).
- When: its undo-invalidation listener receives the resulting write signal.
- Then: the signal is recognized as self-originated; no undo entry is invalidated.
- Edge cases: an external (non-self) write to a command's cell DOES invalidate the affected entry.

**AC47 — batched write**
- Given: N cells complete in one frame.
- When: the writes issue.
- Then: the bulk-write API is used; exactly ONE batched signal fires (not N).

**AC33 — stale entry skipped**
- Given: a command's cell modified by another system.
- When: that command is undone.
- Then: the stale entry is skipped without error or double-removal.

**Build Validation completion signal**
- Given: N completions across commands/villagers in one frame.
- When: they complete.
- Then: exactly one batched construction-completed signal fires.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/building_system/voxel_write_seam_test.gd` — must exist and pass.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 029 (completions to write), Story 032 (undo bookkeeping), Voxel World (bulk-write API + change signals) — Foundation.
- Unlocks: honest undo bookkeeping; Build Validation region analysis (M02); underpins demolition writes (Story 009).
