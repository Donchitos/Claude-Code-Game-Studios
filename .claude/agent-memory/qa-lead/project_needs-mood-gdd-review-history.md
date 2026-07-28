---
name: project-needs-mood-gdd-review-history
description: needs-mood-system.md adversarial AC review history — r1 (2026-07-10) NEEDS REVISION, 7 blockers incl. unspecified why-string contract and untested Edge Case 11
metadata:
  type: project
---

`design/gdd/needs-mood-system.md` review history (Gameplay-layer GDD, zero
AC tags — consistent with [[project-gdd-tag-convention-state]], not a
blocker).

**r1 (2026-07-10, adversarial first full review of 27 ACs) — NEEDS REVISION.**
Formulas independently re-simulated in Node (double-precision) and confirmed
correct: F1's 1072-tick urgency boundary, F2's 140-tick bed / 350-tick ground
recovery worked examples, and F3's snap-to-70.0-exactly all reproduce bit-for-
bit as the GDD claims — the math itself is sound.

7 BLOCKING findings:
1. **Why-string generation is completely unspecified** — no Core Rule, no
   Formula, no AC define how "the strongest current drain plus its missing
   source" is computed; it appears only as a one-line UI Requirements bullet,
   yet `villager-info-ui.md` depends on it verbatim (its Rule 5, AC9). Biggest
   gap in the doc.
2. Edge Case 11 (recovery source upgraded/downgraded mid-recovery, re-
   evaluated per tick, added 2026-07-10 from a cross-review walkthrough) has
   **zero AC coverage** — a Logic/state-transition rule with no test evidence.
3. Edge Case 3's "re-enters ... Urgent" branch (interruption landing BELOW
   `urgency_threshold`) has no AC — AC13 only tests the above-threshold
   ("re-enters Satisfied") landing at value=60.
4. AC14's GIVEN doesn't exclude the F3 snap-rule zone (`abs(mean-mood)<0.05`)
   — as literally written a test author could pick a mock value inside the
   snap zone and the "moves by exactly (mean-mood)/smoothing" assertion would
   be false (snap should fire instead). Needs an explicit "≥0.05" precondition.
5. AC27's "within ±5%" on a fully deterministic tick-based cycle (exact ticks:
   1072 decay + 140 bed recovery = 1212 ticks = 606s at 1x) is unjustified
   slack that contradicts every other AC's exactness and risks being
   implemented as a literal wall-clock assertion (violates the project's
   no-time-dependent-assertions determinism rule). Should assert the exact
   tick count instead.
6. The recovery-ladder ordering invariant (`ground_penalty` < the-
   `unsheltered_bed_multiplier` < 1.0, documented in Tuning Knobs as a hard
   "collapse" failure mode) has **no AC and no described runtime/config
   validation** — confirmed by full-text read, not just AC-list scan.
7. The "Villager AI reports a recovery activity" boundary (mocked by ACs 3,
   8-13) has no concrete interface (method/signal signature, param shape for
   source id + shelter flag) defined in either this GDD or
   `villager-ai-behavior.md` — and that GDD's own Dependencies/Cross-
   References tables (lines 280-283, 586) still say "undesigned —
   PROVISIONAL" / "(not yet authored)" despite this GDD's Dependencies table
   claiming to have "CONFIRMED" and resolved that provisional marker. Stale
   cross-doc reference, verified via grep per [[feedback-verify-fix-claims-against-file]].

8 RECOMMENDED findings (non-blocking clarity/coverage nits): AC4's "parked at
25.0 for many ticks" describes a state natural decay can never produce
(needs a direct-state-injection framing note); Edge Case 6's specific
double-threshold-cross-in-one-burst scenario has no dedicated AC (only
generic burst ordering, AC21); AC11's "one increment" doesn't say it's
source-rate-dependent; AC19's exact-70.00/40.00 crossing is ambiguous about
mocked-comparator vs. natural-EMA framing; the Game Feel section's playtest
criteria are never referenced from the AC list (orphaned — unlike the sibling
`villager-info-ui.md` AC20, which does reference its own Game Feel criterion);
AC24/25's `[PROVISIONAL — Save/Load]` tag format doesn't match the peer
`[Integration, VS+ — DEFERRED pending the Save/Load & World Persistence GDD]`
convention used in `resource-item-database.md` AC9b and
`scene-world-management.md` AC18b; intra-tick F1→F2→F3 ordering (does F3 on
tick N consume tick N's post-decay value?) isn't explicitly asserted; AC5/AC6
overlap (AC6 is a superset of AC5).

Cross-checks that PASSED cleanly (no defects): `design/registry/entities.yaml`
matches the GDD exactly on `urgency_threshold`(25), `satisfied_threshold`(95),
`ground_penalty`(0.4), `unsheltered_bed_multiplier`(0.7); `decay_per_tick`/
`base_recovery_per_tick` are correctly NOT registered (internal-only per the
registry's own rule, since no other GDD needs the raw value).
`villager-info-ui.md`'s AC7 (raw unsmoothed need bars), AC8 (band-event-only
icon update), AC9 (verbatim why-string pass-through) are all consistent with
what this GDD promises to supply, modulo blocker #1 above.

**Why**: first full adversarial pass — the doc's formulas and state machine
are fundamentally sound (verified independently, not just trusted), but a
load-bearing UI contract (why-string) was never actually specified, and two
state-transition edge cases (11, and half of 3) shipped without test
evidence despite the doc's own "Logic ACs are BLOCKING" framing.

**How to apply**: Do not approve this GDD until at minimum blockers 1-7 are
addressed. When re-reviewing, grep the actual current AC/Core-Rule text for
a why-string Core Rule/Formula and for new ACs covering Edge Case 11 and the
Edge Case 3 Urgent-branch before trusting a "fixed" changelog summary — see
[[feedback-verify-fix-claims-against-file]].

**r2 (2026-07-10, final grep-verification pass, bounded — not a full
adversarial round) — DEFECTS FOUND, not CLEAN.** All 11 r1 must-fixes
verified genuinely applied at their cited locations across the three files
(needs-mood-system.md Core Rules 3/4/10/11, States table, EC1/EC3, F2 clamp
+ worked example, Upstream/Downstream/Quick-Ref rows, Tuning Knobs pacing
note, Game Feel probes, AC14/24-35, OQ4/7/8; villager-ai-behavior.md
Interactions row, Cross-References, Downstream table, EC5; building-system.md
Core Rule 17b + EC11 cross-ref) — the mechanical/formula work is solid.

The bounded mirror-defect hunt found the propagation sweep missed 3 spots,
same pattern as every prior round (one location patched, sibling text left
stale):
1. **villager-ai-behavior.md Open Question 1** (marked "RESOLVED
   2026-07-10") self-contradicts its own patched Interactions row — OQ1
   still says "this system still reports only bed-vs-ground" and frames the
   interface as bare "edge-triggered signals," while the Interactions row
   (correctly patched) states the widened 5-value enum and the state+events-
   as-hints model (Needs Core Rule 3). The enum-widening fix landed in the
   Interactions table only, not the OQ1 summary it was supposed to resolve.
2. **villager-ai-behavior.md AC24** still uses pre-widening "reduced-
   recovery flag set" language (also echoed in Rule 12 and EC5 prose,
   lines 226/464) instead of the source-enum contract, and its GIVEN ("no
   reachable bed") spans two now-distinct enum values
   (`ground_no_bed_owned` vs `ground_bed_unreachable`, which drive different
   why-strings per Needs Core Rule 11) without specifying which applies —
   under-specified relative to the widened enum it should test.
3. **needs-mood-system.md Overview** (System-facing, line ~40, unquoted, no
   revision annotation) still describes the recovery model as pre-widening
   binary "bed = full-rate sleep; ground = penalized sleep," omitting the
   unsheltered-bed middle rung the revision treats as the signature Pillar-1
   payoff. Minor/non-blocking but genuine staleness.

Minor non-blocking nits noted, not counted as defects: AC8 says "mocked bed
source" rather than naming `bed_sheltered` (harmless, unambiguous given
AC28 covers `bed_unsheltered` separately); AC32 doesn't test the
`bed_sheltered`/not-sleeping "no suffix" template branch specifically, but
it's a pure why-string-function unit test with mocked inputs, so this is a
coverage nicety not a defect.

**Verdict**: DEFECTS FOUND — recommend a narrow targeted patch (OQ1
rewrite + AC24 update, optionally the Overview line) rather than a full
re-review; defects are localized and don't touch previously-adjudicated
architecture (state+events model, revocation contract, OQ-track decisions,
G1 no-tuning — none reopened).

**Why**: confirms the project's recurring mirror-defect pattern generalizes
beyond scene-world-management — even a well-executed, mechanically-verified
revision session reliably leaves stale text in the summary/OQ layer when a
core contract (here: the source enum) is widened mid-review. Grep for the
NEW terminology across ALL files in a multi-file changeset, not just the
Core-Rule/table it was formally added to.

**How to apply**: For any GDD revision that widens an enum/contract
touching multiple files, grep every file in the changeset for the OLD
terminology it replaces (e.g. "bed-vs-ground", "reduced-recovery flag") —
Open Questions and AC bodies are the most likely places to retain it,
since they're rarely the section a targeted patch touches.

**r3 (2026-07-10, targeted re-verification of the 3 r2 defects) — CLEAN,
Approved.** All 3 patches verified genuinely applied: villager-ai-behavior.md
OQ1 now states the state+events-as-hints model and the 5-value enum
matching the Interactions row (no more "reports only bed-vs-ground"); AC24
now specifies both ground enum branches
(`ground_no_bed_owned`/`ground_bed_unreachable`) with the disambiguating
condition instead of "reduced-recovery flag"; needs-mood-system.md Overview
now states the 3-tier ladder (sheltered 1.0/unsheltered 0.7/ground 0.4)
instead of binary bed/ground. Micro-sweep grep for `reduced-recovery flag`
/ `bed-vs-ground` across both files: needs-mood-system.md clean; the one
hit in villager-ai-behavior.md is AC24's own properly-quoted historical
citation ("...from the pre-widening 'reduced-recovery flag'..."), not a
live defect. Generic unhyphenated "reduced recovery" prose still exists at
Rule 12 (line 226) and EC5 (line 464) but was never one of the flagged
defects and isn't contradictory — left as acceptable informal description.
**GDD status: ready for Approved** (both needs-mood-system.md and
villager-ai-behavior.md).
