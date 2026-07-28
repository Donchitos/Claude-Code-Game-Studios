# Architecture Review Report — Rerun (Delta)

> **Date**: 2026-07-11 (same-day rerun; baseline: `architecture-review-2026-07-11.md`)
> **Engine**: Godot 4.7-stable · **GDDs**: 11 approved MVP + game-concept (revised) · **ADRs**: 14 (13 Accepted, ADR-0003 Superseded)
> **Mode**: Delta against the morning baseline (documented deviation — the baseline is hours old; re-extracting all 349 requirements would re-derive an unchanged set. Changed surface: ADR statuses, spike results, ADR-0014 large-world supersede + its propagation)
> **Run context**: user-delegated autonomous session; verification pass executed by an independent subagent, findings fixed before verdict

---

## What changed since the baseline

1. **Spike QQ3 executed and PASSED** (`prototypes/perf-spike-qq3/REPORT.md`) — resolved the baseline's central gating fact ("all 13 Proposed"). All 13 original ADRs moved to Accepted.
2. **Large-world scope change** (creative director): ADR-0014 (chunked voxel rendering + packed storage, prototype-validated at 2000×2000×32 in `prototypes/chunked-mesher/`) supersedes ADR-0003. Load-bearing propagation applied to ADR-0005/0007/0012/0013, voxel-world.md, camera-input.md, game-concept.md, control-manifest, registry, systems-index.
3. **Pre-gate artifacts** all landed: tests/ + CI (green example test), accessibility-requirements, interaction-patterns, control-manifest v2026-07-11 (regenerated for 14 ADRs).

## Delta verification findings (all fixed this session, commit fa6fc89)

| # | Finding | Fix |
|---|---|---|
| 1 | ADR-0004/0007/0013 `Depends On` pointed at Superseded ADR-0003 (story-blocking semantics) | Re-pointed to ADR-0014 |
| 2 | ADR-0014 coverage set: phantom `TR-voxel-world-016`; dropped TR-building-system-002/026 + TR-villager-info-ui-014/015 vs ADR-0003's actual set | Corrected to the full inherited set |
| 3 | architecture.md stale: "ADRs: none authored", Rendering/Physics/Navigation "unresolved", Voxel World "Dictionary-backed", GridMap ghosts | Updated to resolved state |
| 4 | systems-index risk table: rendering + serialization "unresolved" | Marked RESOLVED with ADR refs |
| 5 | tr-registry TR-voxel-world-025 "open decision" wording | Revised (ID unchanged) |

## Traceability

Baseline: 349 requirements, 0 gaps, 63 registered TR-IDs. Delta: no GDD added or
removed requirements today (the voxel-world/camera-input revisions changed
constraint VALUES and added revision notes, not new architectural asks — the
large-world constraint itself is carried by ADR-0014). ADR-0014 inherits
ADR-0003's full TR set (verified after fix #2). **Coverage: unchanged, 0 gaps.**

## Cross-ADR conflicts

None blocking. The subagent verified ADR-0014 against 0004/0005/0009/0012/0013:
all reconciled (0005 boot timing, 0012 payload, 0013 offset math each carry
dated revision notes; 0009's `current_cell` contract explicitly unaffected —
storage change is behind the unchanged accessor API). Dependency graph acyclic
with 0014 inserted (0014 → 0006 → 0002 → 0001).

## Engine compatibility

ADR-0014 uses no deprecated APIs (checked against deprecated-apis.md); all its
load-bearing APIs were exercised on 4.7 by the validating prototype rather than
paper-verified. No new post-cutoff conflicts. Baseline engine findings stand.

## Open items (tracked, non-blocking for this phase)

- **QQ5**: settlement-core nav-graph region sizing spike — REQUIRED before
  Villager AI implementation stories start (not before gate).
- **VS re-measure set**: save payload (ADR-0012), draw-call density margin
  (ADR-0014 greedy-meshing reserve), Deciding-pass cost watch-item (ADR-0008).
- QQ1 (wave-defense spatial contract), QQ2 (prosperity definition), QQ4
  (villager identity) — unchanged from baseline, all post-MVP-design scope.

---

## Verdict: **PASS**

All 349 requirements covered (0 gaps, 0 partial), no blocking conflicts, engine
consistent, every ADR resolved (Accepted or Superseded-with-successor), all four
pre-gate artifacts present, and the two empirical keystones (spike QQ3, chunked
mesher) are measured rather than assumed. The baseline's CONCERNS drivers are
all closed.

**Conditions carried forward**: QQ5 spike before Villager AI stories; VS
re-measure set above.

## Rerun trigger
Re-run after the QQ5 spike, after any new ADR, or if a GDD revision adds
requirements.
