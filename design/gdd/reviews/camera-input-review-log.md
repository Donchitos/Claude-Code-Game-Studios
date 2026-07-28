# Review Log — Camera & Input

## Review — 2026-07-10 — Verdict: APPROVED (with patches, applied in-session)
Scope signal: S
Specialists: game-designer, systems-designer, qa-lead, godot-specialist + creative-director (senior synthesis; Foundation-batch review with scene-world-management, voxel-world, time-tick-system)
Blocking items: 0 (2 red defects, patched in-session) | Recommended: ~8 (all applied)
Summary: Orbit-camera design (spherical derivation, pole-safe pitch clamp,
raw-delta feel) sound. Two red defects patched: (1) FALSE provenance claim —
"all values come directly from the playtested prototype" while REPORT.md
contains zero camera-value findings; relabeled `[assumption —
prototype-sourced defaults]` (third instance of the provenance-overreach
pattern → now a standing rule in .claude/rules/design-docs.md); (2) the
raw-delta/pause contract cited by building-ui.md and villager-info-ui.md as
"Core Rules 7–8" did not exist — authored as new Core Rules 9 (raw-delta)
and 10 (pause contract, Suspended ≠ Pause), plus Rule 11 (action
registration via project.godot); citing GDDs' cross-references updated to
7–10. Patches: Suspended same-frame ordering pinned, edge-pan explicitly a
decision not an omission, AC15 re-tiered code-review Advisory, AC18–21
added (registered actions, click-ownership, margin-0 clamp, ray round-trip),
1e-4 epsilon note for all exact-value ACs, ray-always-computable
clarification on Rule 8.
Prior verdict resolved: First review
