# Review Log — Needs & Mood System

## Review — 2026-07-10 — Verdict: APPROVED (verification pass)
Scope signal: L
Specialists: qa-lead (fresh verification agent, grep-verification per the
project's terminal-cycle discipline)
Blocking items: 0 (3 residual mirror-defects found and fixed in-session) |
Recommended: 0
Summary: All 17 fix areas across the 3-file changeset VERIFIED with
quoted evidence (state+events model, source enum, Core Rules 10/11,
states table, EC1/EC3, F2 clamp, BVN row, pacing note, probes, ACs
14/24–35, OQ4/7/8, villager-ai reciprocals, building 17b). Mirror-defect
hunt caught 3 propagation residues: villager-ai OQ1 still said "reports
only bed-vs-ground" (contradicting its own patched Interactions row),
villager-ai AC24 still used the pre-widening "reduced-recovery flag",
and needs-mood's Overview still described the binary two-tier model.
All 3 patched → re-verified CLEAN (micro-sweep: no unquoted stale
phrasing). Status: **APPROVED** (user pre-authorized approve-on-clean).
Prior verdict resolved: Yes (11 must-fixes + 3 verification residues)

## Review — 2026-07-10 — Verdict: NEEDS REVISION
Scope signal: L
Specialists: game-designer, systems-designer, ai-programmer, qa-lead
+ creative-director (senior synthesis)
Blocking items: 11 consolidated must-fixes (5 requiring user decisions) |
Recommended: ~15
Summary: Strong single-document design with uniform SEAM-specification
debt — every blocker lives at a boundary (Needs↔AI, Needs↔BVN, Needs↔UI,
Needs↔Building); qa-lead independently re-simulated F1–F3 and confirmed
the math EXACT (1072/140/350 ticks; full cycle 1212). Must-fixes:
M1 why-string underspecified (Pillar-4 deliverable; cannot distinguish
no-bed/bed-unreachable/bed-unsheltered — "tired — no bed" directs the
player to the WRONG fix for a trapped villager; 3 sources feed one UI
slot with no precedence; CD overrode ai-programmer's RECOMMENDED to
BLOCKING); M2 no live-pair integration AC (both GDDs mock each other —
the AC40/40b precedent unapplied); M3 signal model unreconciled
(edge-once vs level-polling, no latch); M4 bed-removal notification
unowned (Rule 10b covers only moving villagers; 3-way circular punt;
job-claims have revocation, beds don't); M5 state-table cluster
(Urgent-exit ≠ Recovering-entry; interruption ≤25 uncovered; EC11 zero
ACs); M6 ladder invariant + 0.7 rung unenforced in the owning doc;
M7 F2 overshoot >100 at legal knob combos; M8 BVN missing from Upstream/
Quick-Ref/systems-index (bidirectionality ×3); M9 stale PROVISIONAL
markers in villager-ai-behavior.md lines 280-283/586/587 VERIFIED
(claimed "CONFIRMED" was never patched — cross-document claimed-vs-
verified defect); M10 report-API shape undefined; M11 AC14 snap-zone +
AC27 ±5% determinism defects. G1 pacing dead-zone (~6-7 min inert
between build payoff and needs payoff inside the ~10-min MVP window)
adjudicated as documentation + playtest probe, NOT paper tuning.
Changeset touches villager-ai-behavior.md (APPROVED — M9 mandatory) and
conditionally building-system.md. OQ-folds: dead-man path (recovery
starting >95) → both OQ4s; VS synchronized-spawn decay spike; EMA
ramp-lag disclosure.
Prior verdict resolved: First review

**Post-review revision (same session, 2026-07-10):** all 11 must-fixes
applied with 4 user decisions (all CD-recommended options): (M3) signal
model = QUERYABLE STATE + events-as-hints (Core Rule 3 rewritten; AI
reads state at decision points, missed events harmless, save/load
re-derives); (M1) why-string owned by Needs — new Core Rule 11
(selection rule, 5 templates keyed by the widened source enum
bed_sheltered/bed_unsheltered/ground_no_bed_owned/ground_bed_unreachable/
ground_trapped, UI-slot precedence: distress > need-why > BVN detail);
(M4) bed-removal = furniture-revocation contract — building-system.md
Core Rule 17b added (symmetric to job revocation), villager-ai EC5 cites
the channel, Needs EC3 pins the chain + zero-credit removal tick; (M7)
F2 domain clamp min(100, …). G1 pacing: documented as deliberate
hypothesis (Tuning Knobs cross-ref note) + playtest probes (pacing +
Beat-3 unprompted-mood-notice) — no paper tuning, per CD adjudication.
Mechanical: Core Rule 10 (discrete start/stop report API + intra-tick
ordering: reports land before the F-pass, removal tick credits zero);
States table aligned (Urgent-exit = start_recovery report; Recovering
re-reads source per tick; stop_recovery exit incl. no-second-urgent
rule); EC1 below-threshold branch; ladder-invariant config validation
owned HERE (+ courtesy-duplicate note re BVN footnote); 0.7 worked
example (200 ticks = 100s); BVN upstream row + Quick-Ref + systems-index
edge; statuses refreshed (Approved/Designed, villager-info-ui confirmed);
Breather exclusion explicit; AC14 snap-zone guard; AC27 → exact ticks
(1072/1212); AC24/25 → DEFERRED convention; NEW AC28–35 (0.7 rung,
invariant check, EC11 up/downgrade, below-threshold interruption,
why-string templates, F2 clamp, LIVE-PAIR integration AC per the AC40/40b
precedent, Game-Feel evidence hook). OQ4 dead-man caveat; new OQ7 (VS
synchronized-spawn spike) + OQ8 (EMA ramp-lag). RECIPROCAL FILES:
villager-ai-behavior.md (APPROVED) — stale PROVISIONAL markers at the
Interactions row + Cross-References (both "not yet authored" rows) +
downstream table PATCHED and verified; consumption model + source enum
stated; EC5 trigger channel pinned. building-system.md (APPROVED) — Core
Rule 17b + EC11 cross-ref. Propagation sweep grep-VERIFIED (stale wording
survives only as quoted history). ACs now 35. **Re-review pending** —
fresh session, or verification pass per the established discipline.
