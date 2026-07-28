# Review Log — Building System

## Review — 2026-07-09 — Verdict: NEEDS REVISION
Scope signal: XL
Specialists: game-designer, systems-designer, qa-lead, ai-programmer, godot-specialist, gameplay-programmer, performance-analyst + creative-director (senior synthesis)
Blocking items: 10 | Recommended: 7
Summary: Core design (blueprint-then-build, 6-tool modal set, geometric-only
validity) judged sound — "the problems are in the seams, not the skeleton."
Top convergent findings: missing max-cells-per-command cap (3 independent
finds), self-signal reentrancy in undo bookkeeping (2 finds), silent-failure
seam at the "earned pride" moment (no doors in MVP + no unreachable-blueprint
signal), and false prototype provenance on build-over-time pacing (2 finds —
the prototype explicitly excluded build-over-time).
Prior verdict resolved: First review

## Review — 2026-07-10 — Verdict: APPROVED
Scope signal: XL
Specialists: game-designer, systems-designer, qa-lead, ai-programmer, godot-specialist, gameplay-programmer, performance-analyst + creative-director (senior synthesis)
Blocking items: 0 | Recommended: 5 doc-cleanup patches + 1 ADR seam + backlog (all applied in-session)
Summary: RE-REVIEW after the 2026-07-09 NEEDS REVISION. All 10 prior
blockers verified as HOLDING under a second adversarial pass (incl.
numerically: 512-cap inclusive boundary, F3↔Villager-AI-F1 timing
convergence, lockstep no-off-by-one). Residue was documentation hygiene
(summary overclaim, stale "provisional" body text, weight-ownership
deferral, carport caveat, F2 cap mention — all patched), one genuine seam
(mid-path solidification race → building/AI ADR, OQ 3b + Villager AI OQ 3),
and additive rigor (AC50 + Villager AI AC40/40b added; ghost ceiling +
degraded-preview mechanism + memory-byte assumption → ADR backlog, OQ 3c).
CD: "Ship it — the doc needs a proofreader and an ADR, not another
adversarial round."
Prior verdict resolved: Yes

## Review — 2026-07-09 — Verdict: NEEDS REVISION (superseded)

**Post-review revision (same session, 2026-07-09):** all 10 blocking items
resolved in-session with user decisions: `max_cells_per_command=512` +
`preview_degradation_threshold=128`; self-write exemption + bulk-write
batching rules added to Interactions; Edge Case 5 now owns a pulsing-orange
unreachable-ghost signal + UI hint; prototype provenance corrected (planning
loop validated, construction loop marked design hypothesis/PROVISIONAL);
burst rule fixed as per-villager/job; Core Rule 14b occupancy authority
split added; Core Rule 12 job contract fully specified (per-cell jobs, one
job per villager, parallel per-cell claims, "on site" defined); impact
moments concretized; ACs revised to 49 (AC6/15/36 split, AC26 rewritten,
AC39–49 added); Dragging state exit + per-frame re-rasterization specified.
Recommended items also applied ("nothing is precious" honesty rewording, F4
wording alignment, F5 Flat stub, furniture-on-blueprint support rule,
memory-claim math). **Re-review NOT yet run** — user chose to proceed to the
next system; run `/design-review design/gdd/building-system.md` in a fresh
session to confirm the fixes before implementation.
