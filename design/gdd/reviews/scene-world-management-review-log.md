# Review Log — Scene/World Management

## Review — 2026-07-10 — Verdict: APPROVED (re-review #4, grep-verification pass)
Scope signal: S
Specialists: qa-lead (fresh verification agent — per the CD's terminal-cycle
mandate, NOT a full adversarial round)
Blocking items: 0 (2 residual single-clause defects found and fixed
in-session) | Recommended: 0
Summary: All 5 re-review-#3 fixes VERIFIED with quoted line evidence; all
folds verified; camera-input.md reciprocity confirmed. The pass caught 2
final mirror-residues: (1) the build-placement row still labeled the
aborted drag a "reversible begin-effect," contradicting the corrected
load-failure row that cross-references it; (2) Core Rule 7's
transition-complete bullet listed only 2 of the 3 unwind effects
(overlay missing), asymmetric with the abort bullet. Both patched as
single-clause edits and RE-VERIFIED by the same agent: final call CLEAN —
all 7 "reversible begin-effect" occurrences taxonomy-consistent, success/
abort branches symmetric. First CLEAN pass after 5 rounds. Status:
**APPROVED** (systems index updated; user pre-authorized approve-on-clean).
Prior verdict resolved: Yes (5/5 blockers + 2 verification residues)
## Review — 2026-07-10 — Verdict: NEEDS REVISION (re-review #3 — terminal patch cycle)
Scope signal: S
Specialists: game-designer, systems-designer, qa-lead, godot-specialist + creative-director (senior synthesis)
Blocking items: 5 | Recommended: ~11
Summary: FIRST ROUND WITH ZERO REGRESSIONS — all 8 re-review-#2 fixes hold,
all reciprocal files (camera-input, building-system, building-ui,
villager-info-ui, time-tick) verified consistent, AC10 tick math
cross-checked correct. CD: round-4 findings are a DIFFERENT CLASS than
rounds 1-3 — no design traps, only propagation residue around the new
abort signal + honesty/scoping text. Convergent top blocker (found
independently by 3 specialists, and PREDICTED by systems-designer's agent
memory): the double-trigger debounce still said "until the first
completes" in the Edge Case row and AC7 — stale two-signal wording that,
implemented literally, re-creates the transition-lockout soft-lock.
Others: overlay-unwind missing from AC8/States/Visual-Audio (no abort row
existed to test against); "no trace" overclaim vs. the unrestored
in-flight drag (taxonomy mislabel); return-direction abort undefined
(every abort sentence said "load failure" but return is an UNLOAD);
SceneTree.current_scene property-assignment missing from the Core Rule 2
guardrail. CD verdict: NEEDS REVISION as the TERMINAL patch-and-confirm
cycle — re-review #4 should be a grep-verification pass, NOT another
5-agent adversarial round; mandatory propagation sweep with every fix.
Prior verdict resolved: Yes (8/8 hold; new findings are propagation gaps,
not regressions)

**Post-review revision (same session, 2026-07-10):** all 5 blockers fixed
with 1 user decision: **abort is ENTRY-ONLY** (return handback cannot
abort by construction — Valley always exists per Core Rule 4; freeing the
Dungeon is teardown → existing teardown-ordering OQ; no stranding
safeguard needed). Fixes: debounce Edge Case row + AC7 rewritten with
positive abort-release test; AC8 + States parenthetical extended to the
full camera/UI/overlay triad + new Visual/Audio ABORT row (treatment →
/asset-spec incl. minimum-display-duration guard + tint distance);
"no trace" claim scoped (irreversible + presentation state; explicit
in-flight-interaction exception, drag mislabel corrected); entry-only
declared in Core Rule 7/States/Edge-Case/AC8; guardrail + `current_scene`
property assignment + never-free-World-Root corollary. Folds: signal-name
capitalization normalized; Booting row → AC17b + HALT declared terminal
(app restart); milestone-gated defined; AC12a/12b/13 → GWT (12b + 90-frame
hold precondition); AC15 process_frame disambiguation; AC10(c) → derived
value (10 × ticks_per_second); AC17a circular WHEN reworded; abort-while-
paused composition explicit; anti-spam note (ignored-not-queued); boot-
HALT ≠ SceneTree.paused ADR note. Propagation sweep grep-VERIFIED (stale
two-signal wording only survives as quoted history in revision notes).
**Final verification pass pending** (per CD: grep-verification, not a
full adversarial round).
Scope signal: S
Specialists: game-designer, systems-designer, qa-lead, godot-specialist + creative-director (senior synthesis)
Blocking items: 8 | Recommended: ~10
Summary: All 5 prior blockers HOLD at rule-text level; core design stable.
But the "each fix spawns a mirror defect" pattern recurred a 3rd time, and
the CD named its root cause: a TWO-signal model (begin/complete) covering
THREE outcomes (begin → success OR failure-abort). Top blocker: Core Rule
7's success-only COMPLETE leaves reversible begin-effects (camera
Suspended, UI hidden) with no unwind path on a failed load — a confirmed
soft-lock contradicting AC8. Fix: introduce a first-class transition-ABORT
signal (the round's one design decision). Second: Core Rule 1 was never
updated to the World Root topology (still "Valley as active scene" —
contradicts Core Rule 2, and leaves no engine gate for AC17's boot-halt).
Remainder: missing topology AC, Booting failure-exit missing from States
table, cancel-ordering contradiction vs building-system.md's reactive
Suspended model, AC10(c) flaky-test ambiguity, AC18 split (bit-identical
untestable + Save/Load undesigned), AC13 scope tag missing (falsifying
re-review #1's "all 18 tagged" claim — 2nd consecutive round with an
unverified fix summary; grep-verification now mandatory). CD adjudications:
return-cue ACs downgraded to advisory (Visual/Feel is ADVISORY-gated) with
a Core Rule 5 mapping fix instead; change_scene_to_file() guardrail
ELEVATED to must-land; nav-map/input-routing folded into OQ2.
Prior verdict resolved: Partially (all 12 fixes present; 3 defective in
new mirror-image ways: Core Rule 7 abort trap, Booting States-table gap,
AC13 tag miss)

**Post-review revision (same session, 2026-07-10):** all 8 blockers fixed
with 3 user decisions: (1) transition-ABORT as a first-class third signal —
Core Rule 7 is now a three-signal contract (begin = reversible, complete =
success + irreversible, abort = failure + full unwind), debounce releases
on either end-signal; (2) return-cue mapping = 3 BUCKETS (completion →
amber, voluntary exit → new neutral cue, death/retreat → muted; exit-vs-
retreat enum → Dungeon System GDD) — Core Rule 5 + a third Visual/Audio
row; (3) reciprocal camera-input.md patch approved (Suspended exits on
complete OR abort — States, Dependencies, Cross-Refs, AC10). Other fixes:
Core Rule 1 reworded (engine boots World Root, Valley attached at the boot
gate); Booting failure-exit formalized in the States table; cancel-ordering
aligned to building-system.md's reactive Suspended model; AC10(c) →
deterministic tick advancement; AC18 split (18a Building undo deep-equality
/ 18b Save/Load DEFERRED); AC13 tagged [VS+]. Folds: change_scene_to_file/
_packed/reload_current_scene guardrail in Core Rule 2; hosted-systems list
completed; OQ2 + nav-maps/input-routing/GI facets; AC17 split a/b; AC19
(World Root sibling topology regression guard); AC20 (advisory cue-split
guard); AC15 marked provisional (teardown OQ); AC12b baseline → same-scene
steady-state; AC12 thresholds labeled test-harness constants; 2 new OQs
(repeat-visit fatigue, boot budget); per-beat duration tuning note.
ACs now 20 (17a/b, 18a/b). Every fix grep-VERIFIED against both files
(CD process mandate). **Re-review #3 NOT yet run** — run
`/design-review design/gdd/scene-world-management.md` in a FRESH session.
Scope signal: S
Specialists: game-designer, systems-designer, qa-lead, godot-specialist + creative-director (senior synthesis)
Blocking items: 2 (+4 execution defects from the prior revision) | Recommended: ~6
Summary: All 3 prior blockers verified HOLDING (warp persistence reciprocally
consistent with Time & Tick, no orphaned reset references). But two NEW
defects: (1) the undo-abort trap — Building's undo-clear fired on
transition-BEGIN while the load-failure path aborts in-place, wiping undo
with no scene change (same irreversible-trap class as the fixed warp bug,
reintroduced by the dependency added in the same pass); (2) Core Rule 2
"Valley is the single persistent root" contradicted the two-live-scenes
requirement (Godot has one current_scene — hosting container unnamed).
Plus 4 sloppy-execution defects in the prior revision itself (AC10
malformed, AC7 re-tier claimed-but-not-applied, scope tags not inline,
boot-order Edge Case without AC) — CD: "the summary asserted changes the
artifact didn't contain; verify against the file." CD adjudicated
game-designer's warp-in-dungeon/unattended-Valley blockers OUT of this
GDD's scope (→ Dungeon System GDD OQs), but the hand-waving dismissal in
the Edge Case row had to go.
Prior verdict resolved: Partially (3/3 old blockers hold; new defects found)

**Post-review revision (same session, 2026-07-10):** all 12 findings fixed
with 2 user decisions: side-effect discipline (new Core Rule 7 — begin =
reversible only, irreversible effects bind to COMPLETE; Building Rule 17 +
AC32b updated reciprocally) and return-cue split (victory amber vs.
death/retreat muted "limping home"). World Root container named in Core
Rule 2; AC10 rewritten (4 checkpoints incl. mid-visit); AC7 re-tier
actually applied; inline scope tags on all 18 ACs; AC17 boot-order (MVP,
incl. boot-halt failure behavior); AC18 abort-leaves-no-trace; formal
failure-exit in the States table; AC15 queue_free tolerance; OQ2 reframed
(SceneTree-membership + viewport/audio partitioning); 2 new OQs (warp
meaning in dungeons, unattended-Valley safety). Every fix verified against
the file this time (grep-confirmed). **Re-review #2 NOT yet run** — run
`/design-review design/gdd/scene-world-management.md` in a FRESH session.

## Review — 2026-07-10 — Verdict: NEEDS REVISION
Scope signal: S
Specialists: game-designer, systems-designer, qa-lead + creative-director (senior synthesis; Foundation-batch review with voxel-world, camera-input, time-tick-system)
Blocking items: 3 | Recommended: ~8
Summary: First full review. Three real rule defects: (1) the warp-reset-to-1x
on transition created an irreversible warp trap — Building UI (sole warp
owner) doesn't exist in dungeon scenes, so "manually re-engage" was
impossible and the background Valley silently dropped to 1x against the
player's setting; (2) the reset-call vs. transition-signal ordering was an
unspecified race; (3) the Booting state lacked the boot-order requirement
(Resource & Item DB Ready before dependents). Plus advisories: AC6's "exact
state" contradicted Core Rule 4's continuous simulation, missing
transition-while-paused edge case, missing Building undo-clear dependency
row, MVP/VS scope tags, 2 missing ACs, AC12 formalization.
Prior verdict resolved: First review

**Post-review revision (same session, 2026-07-10):** all 3 blockers resolved
with user decision "Warp bei Rückkehr wiederherstellen": warp now PERSISTS
unchanged across transitions (global state, reset call retired — Time & Tick
GDD reciprocally updated, its AC8 replaced); the ordering race dissolved with
the call's removal (all effects now signal-only); boot-order requirement
recorded as an Edge Case row pointing at the boot-order ADR. Advisories all
applied: AC6 reworded (position/camera restored, simulation elapsed), AC3
split from timing (AC12a owns tolerance), transition-while-paused edge case,
Building undo-clear dependency row, scope tags (AC1–2 MVP, AC3+ VS+), AC7
re-tiered Logic, AC14–16 added, 3 OQs added (teardown signal ordering,
background-scene process mode, boot-order mechanism).
**Re-review NOT yet run** — run
`/design-review design/gdd/scene-world-management.md` in a fresh session.
