---
name: project-swm-gdd-review-history
description: Review history and recurring defect pattern for design/gdd/scene-world-management.md — check before any future re-review of this GDD
metadata:
  type: project
---

`design/gdd/scene-world-management.md` has gone through 3 review rounds (all 2026-07-10),
each ending NEEDS REVISION, with a **recurring "mirror defect" pattern**: each round's
fix for one soft-lock/trap class re-introduces an equivalent trap in a newly-touched
area of the doc (warp-reset trap → undo-clear-on-begin trap → two-signal abort
soft-lock → now debounce-never-releases-on-abort + missing overlay-unwind-on-abort
coverage, found at re-review #3, 2026-07-10).

Round history:
- Review 1: 3 blockers (warp-reset trap, ordering race, missing boot-order rule).
- Review 2 (re-review #1): new mirror defects (undo-clear-on-begin trap, Core Rule 2
  single-root contradiction) + 4 sloppy-execution defects (claimed-but-not-applied fixes).
- Review 3 (re-review #2): top blocker was the two-signal (begin/complete) model unable
  to unwind reversible effects on load failure → fixed by adding a first-class
  transition-ABORT signal (Core Rule 7 three-signal contract). ACs split: 17a/17b
  (boot success/failure), 18a/18b (Building undo deep-equality / Save-Load deferred).
  New ACs 19 (World Root sibling topology regression guard) and 20 (three return-cue
  screenshot evidence, Visual/Feel Advisory).
- Review 4 (re-review #3, adversarial, this session): found the abort signal's own
  coverage is incomplete — AC7 and the "double-trigger" Edge Case row still say the
  debounce releases only "until the first completes," omitting the abort-release path
  Core Rule 7 itself mandates ("releases on EITHER... never on complete alone") — same
  trap class reintroduced a 4th time, now on the debounce gate itself. Also: AC8 and
  the States-table Transitioning row only assert 2 of Core Rule 7's 3 abort-unwind
  effects (camera + UI, missing overlay-fade-out), and the Visual/Audio Requirements
  table has no row at all for the abort/load-failure case to test against.

- Re-review #4 (2026-07-10, grep-verification-only pass per CD mandate, NOT a
  full adversarial round): claimed fixes 1/2/4/5 (debounce release-on-either,
  overlay triad in AC8/States/Visual-Audio, entry-only-abort propagation,
  SceneTree.current_scene guardrail) all VERIFIED against file text — first
  clean pass on those. But claim 3 (no-trace scoping + "reversible
  begin-effect" mislabel correction for the drag) is only HALF fixed: the
  load-failure Edge Case row (the one that was actually touched) now correctly
  says the in-flight drag is NOT a "reversible begin-effect" in Core Rule 7's
  sense — but the row it cross-references ("next row" = the build-placement-
  mode row) was never touched and still says, unchanged since re-review #2,
  "the aborted drag is a reversible begin-effect per Core Rule 7." Two adjacent
  rows now directly contradict each other on the same fact — the fix edited
  the citing row but not the cited row. Also found a NEW, previously-unnoticed
  instance of the exact "camera/UI restored, no overlay" pattern this doc is
  famous for: Core Rule 7's own **transition-complete** bullet ends with "It
  also ends the reversible begin-effects on the success path (camera resumes
  in the target scene, UI reappears)" — 2 of 3 effects, omitting the overlay,
  right next to the **transition-abort** bullet that DOES list all 3 (camera,
  UI, overlay) after being fixed at re-review #3. The round-3 fix propagated
  the full triad to the abort branch everywhere (Core Rule 7, States, AC8,
  Visual/Audio) but never checked the sibling COMPLETE branch for the same gap
  — no single place in the doc asserts the full triad for the success path
  (Core Rule 7 has camera+UI, the separate Visual/Audio "Transition completes"
  row has only overlay). Verdict: DEFECTS FOUND, not CLEAN — the terminal
  patch cycle needs one more narrow patch-and-confirm (not a full 5-agent
  round) targeting exactly these two spots.

- Re-review #4 follow-up patch (same session, 2026-07-10): both residual
  defects fixed and independently re-verified against the live file text (not
  the patch-request's suggested wording). Build-placement row now says the
  drag "is NOT a 'reversible begin-effect' in Core Rule 7's unwind sense,"
  matching the load-failure row it cross-references — contradiction resolved.
  Core Rule 7's transition-complete bullet now lists the full camera+UI+overlay
  triad, symmetric with the abort bullet. A full sweep of all 7
  "reversible begin-effect" occurrences in the file found no remaining
  mislabel or partial-triad restatement. **Verdict: CLEAN — first clean pass
  after 5 rounds.**

**Why**: `qa-lead` and other reviewers keep validating the NEW fix's rule-text in
isolation without cross-checking every OTHER place in the doc that echoes the same
concept (Edge Cases row, States table, AC text, Visual/Audio table) — the fix lands
in Core Rules but the mirrored copies in adjacent tables/ACs go stale. Round 4
confirms this happens even in "grep-verification only" passes when the fix touches
only the row containing the flagged text and not every row it cross-references or
mirrors — always follow "next row" / "see X" cross-references to their target and
check for symmetric siblings (begin/complete/abort triplets) of any rule being patched.

**How to apply**: On any future review of this GDD (or GDDs with a similarly dense
cross-reference web — Core Rules / Edge Cases / States table / AC / Visual-Audio
table all echoing the same rule), do NOT just check that the rule statement was
updated — grep every other section that restates or depends on that rule's language
(especially exact phrases like "until the first completes") for staleness. See also
[[feedback-verify-fix-claims-against-file]].
