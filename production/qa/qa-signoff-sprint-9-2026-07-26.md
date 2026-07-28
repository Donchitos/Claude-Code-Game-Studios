# QA Sign-Off — Sprint 9 (Milestone 02 Opener)

**Date**: 2026-07-26
**QA Lead**: qa-lead (this artifact)
**Sprint file**: `production/sprints/sprint-09.md` ("Sprint Result — CLOSED 2026-07-26")
**QA plan**: `production/qa/qa-plan-sprint-9-2026-07-26.md`
**Milestone criterion #14**: this is the **first `qa-signoff-sprint-*.md` artifact ever produced** for this
project (`production/qa/` held nine plans and zero sign-offs before this file). The habit starts here.

---

## 1. Scope confirmation

The QA plan's own Test Summary table covers **14 stories** (11 Must + 2 Should + 1 Nice), as scoped at the
time it was written. The sprint file was **amended twice after the QA plan was written** to add
`vox-020`, `vox-021`, and `scene-005` (bringing the tracked sprint to 17 stories), and — verified on
disk, not assumed — **`build-validation-006` also landed this sprint although it appears in neither the
QA plan nor `production/sprint-status.yaml`'s tracked story list** (commit `b8d1653`, story file reads
`Status: Complete`, its own test file `shelter_classification_test.gd` exists and is part of the green
suite). This is recorded as a **process gap**, not a quality gap: `build-validation-006` has its own
Test Evidence section, its own passing test file, and is a Logic story — it was simply never entered
into this sprint's QA plan or its status tracker, so no QA plan explicitly named its evidence
requirement in advance. **Flagged as a condition below (carry-forward item).**

All 18 stories that actually shipped or were explicitly deferred, with `Status` confirmed against each
story file (not inferred from the plan):

| Story | Declared Type | Status at sign-off | In QA plan's Test Summary? |
|---|---|---|---|
| villager-ai-026 | Logic | Complete | Yes |
| build-validation-001 | Integration | Complete | Yes |
| build-validation-002 | Logic | Complete | Yes |
| build-validation-003 | Logic | Complete | Yes |
| build-validation-004 | Logic | Complete | Yes |
| needs-mood-001 | Integration | Complete | Yes |
| needs-mood-002 | Logic | Complete | Yes |
| needs-mood-003 | Logic | Complete | Yes |
| building-023 | Visual/Feel | Complete | Yes |
| building-001 | Logic | Complete | Yes |
| villager-ai-021 | Integration | Complete | Yes |
| build-validation-005 | Integration (Should) | Complete | Yes |
| build-validation-010 | Integration (Should) | Complete | Yes |
| building-011 | Logic (Nice) | **Deferred to S10** (not landed) | Yes |
| vox-020 | Integration | Complete | **No — added to sprint after QA plan was written** |
| vox-021 | Integration + Config/Data | Complete | **No — added to sprint after QA plan was written** |
| scene-005 | Integration | Complete | **No — added to sprint after QA plan was written** |
| build-validation-006 | Logic | Complete | **No — not in QA plan or sprint-status.yaml at all** |

**Verified**: every "Complete" status line above was read directly from its story file's own header, not
copied from the sprint summary. `building-011`'s deferral is confirmed both in `sprint-status.yaml`
(`status: deferred-to-s10`) and the sprint file's own Sprint Result line.

---

## 2. Per-story DoD verdict

| Story | Verdict | Evidence pointer |
|---|---|---|
| villager-ai-026 | **PASS** | `neues-spiel/tests/unit/villager_ai/walkability_rules_static_test.gd` (exists, 5 tests); Gate 1 below |
| build-validation-001 | **PASS** | `neues-spiel/tests/integration/build_validation/config_and_scaffold_test.gd` (exists); grep guards clean (zero `VillagerAi`-typed field, zero `NavigationServer3D`-family) |
| build-validation-002 | **PASS** | `neues-spiel/tests/unit/build_validation/candidate_cell_test.gd` (exists); single literal-declaration site confirmed (`villager_walkability_rules.gd:61,69`) |
| build-validation-003 | **PASS** | `neues-spiel/tests/unit/build_validation/region_formation_test.gd` (exists) |
| build-validation-004 | **PASS** | `neues-spiel/tests/unit/build_validation/room_verdict_test.gd` (exists) |
| needs-mood-001 | **PASS** | `neues-spiel/tests/integration/needs_mood/config_scaffold_and_ladder_invariant_test.gd` (exists); literal-value assertion for `0.07`/`0.5`/`40.0` confirmed present at lines 46-52/69-71/84-86 |
| needs-mood-002 | **PASS** | `neues-spiel/tests/unit/needs_mood/decay_state_machine_test.gd` (exists) |
| needs-mood-003 | **PASS** | `neues-spiel/tests/unit/needs_mood/recovery_source_rate_table_test.gd` (exists) |
| building-023 | **PASS WITH NOTES** | 4 screenshots present under `production/qa/evidence/` (`building-023-ghost-preview-*-20260726-1.png`) + `ghost-preview-rendering-evidence.md`; **the evidence doc's own Sign-off line reads "awaiting review — evidence prepared for that pass, not yet countersigned."** This sign-off document constitutes that qa-lead countersignature: evidence reviewed and accepted as of 2026-07-26. Deviation flagged (see §9). |
| building-001 | **PASS** | `neues-spiel/tests/unit/building_system/build_editor_mode_test.gd` (exists) |
| villager-ai-021 | **PASS WITH NOTES** | `neues-spiel/tests/integration/villager_ai/starting_roster_test.gd` (10/10 passing); companion evidence substitutes a captured console/log run for the screenshot the QA plan's own checklist asked for, honestly justified (no villager body exists — `presentation-003` unwritten). See §9. |
| build-validation-005 | **PASS** | `neues-spiel/tests/integration/build_validation/analysis_pass_lifecycle_test.gd` (exists); Gate 2 below |
| build-validation-010 | **PASS WITH NOTES** | `neues-spiel/tests/integration/build_validation/reachability_property_corpus_test.gd` (7 tests, exists); corpus shipped at 5 pairs/seed vs. the AC's literal 50, escalated to TD per the plan's own Content Requirement 3 — see §4/§9 |
| building-011 | **NOT LANDED** | Deliberately moved to S10 mid-sprint per producer trim recommendation; no evidence expected |
| vox-020 | **PASS** | `neues-spiel/tests/integration/voxel_world/mesh_invalidation_budget_test.gd` (exists); not in original QA plan scope — see §1 |
| vox-021 | **PASS** | `neues-spiel/tests/integration/voxel_world/boot_mesh_radius_test.gd` (exists); boot-budget evidence `boot-mesh-radius-boot-budget-20260726.md`; not in original QA plan scope |
| scene-005 | **PASS WITH NOTES** | `neues-spiel/tests/integration/scene_world/world_genesis_boot_test.gd` (exists); boot-budget evidence `world-genesis-boot-budget-2026-07-26.md` records an honest first-measurement **MISS** (9082 ms vs. 3.0s ceiling) before remediation — see §9; not in original QA plan scope |
| build-validation-006 | **PASS WITH NOTES** | `neues-spiel/tests/unit/build_validation/shelter_classification_test.gd` (exists); not in QA plan or sprint-status.yaml at all — see §1 and §9 (is_need_functional true-branch deviation) |

**Could not independently verify**: none of the 18 stories' test files are missing — every claimed test
path was checked against the actual filesystem and found present. I did not re-execute the full GdUnit4
suite myself in this session (no test-runner invocation was made); the "green"/pass-count claims below
rely on the story files' and evidence docs' own recorded run output, cross-checked for **internal
consistency** (suite counts increment correctly across the commit sequence: 951 → 953 → 958 → ... → 1198,
matching each story's own recorded total) rather than a fresh independent run. This is noted as a
methodology limit, not a blocking concern — the incrementing counts, exit codes, and orphan counts are
consistent across every story file and evidence doc I read, and I found no internal contradiction.

---

## 3. Both headline gates — verdicts

### Gate 1 — `villager-ai-026`'s zero-test-edit proof: **PASS**

Verified mechanically, not assumed:
- `git show --stat 79ba26c -- neues-spiel/tests/` (the story's own commit) shows **3 changed paths, all
  additive** (`walkability_rules_static_test.gd`, its `.uid`, and one unrelated pre-existing `.uid` add) —
  **zero M, zero D, zero R, zero C**. `3 files changed, 150 insertions(+)`, no deletions.
- Both new paths are genuinely new (did not exist at the prior Sprint-8-close commit `313b381`).
- Suite count arithmetic: story header claims 958/958 after landing; the commit's own message states
  "+5 tests" in the new file; cross-checked against the interim baseline (953, after two post-Sprint-8
  commits that are not Sprint 9 stories) — 953 + 5 = 958. Arithmetic holds.
- Grep guards: zero `VillagerWalkabilityRules.new(` in `src/` (the one textual hit is inside a doc
  comment describing the guard itself, not an instantiation); exactly one literal declaration site each
  for `VILLAGER_CLEARANCE`/`MAX_STEP_HEIGHT` (`villager_walkability_rules.gd:61,69`) — `villager_ai.gd`'s
  own consts are alias re-exports (`= VillagerWalkabilityRules.VILLAGER_CLEARANCE`), not second literals.
- **Re-checked at hand-off (item 12 of the plan's Smoke Scope)**: `git diff --name-status
  313b381..652229a -- neues-spiel/tests/` (full sprint span) shows 7 `M` entries against pre-existing
  test files, but every one of them is attributable to a **different**, later Sprint 9 story
  (`scene-005`, `vox-021`, `building-023`, `vox-020`) or to a pre-Sprint-9 hotfix commit (`7dff4a8`,
  which landed *before* `villager-ai-026` and is not a Sprint 9 story). **No commit after `79ba26c`
  touches any file under `tests/*/villager_ai/`.** Gate 1 holds at hand-off, not just at story-landing
  time.

### Gate 2 — `build-validation-005`'s deferred-write correctness case: **PASS**

Read directly from `analysis_pass_lifecycle_test.gd`. The single test function
`test_deferred_write_no_pass_at_completion_then_exactly_one_pass_with_landed_verdict_on_write_landing`
proves both halves in one connected scenario, exactly as the plan required:
- **T0 (job-completion instant)**: a `bulk_write` targeting a non-resident chunk queues the write and
  returns an empty record array; pass count asserted `== baseline` (zero new passes) both before and
  after firing a `construction_completed`-shaped stand-in signal (module is provably indifferent to it).
- **T1 (write-lands instant)**: `update_residency` pages the chunk back in, `_apply_pending_writes` lands
  the queued write, `cells_changed_batch` fires for real; pass count asserted `== baseline + 1` (exactly
  one new pass) and the verdict is asserted to reflect the landed data (`cell_a`/`cell_b` both flip from
  computed `OPEN` to computed `ROOM`).
- **Static half**: `test_setup_subscribes_to_cells_changed_batch_exactly_once` and
  `test_module_has_zero_construction_completed_references` both present and, per grep of
  `build_validation.gd`, only `cells_changed_batch` is ever `.connect()`-ed — `construction_completed`
  appears only in doc comments explaining why it is *not* subscribed.

---

## 4. `build-validation-010`'s corpus result (Should, pulled)

Per `production/qa/evidence/build-validation-010-reachability-corpus-runtime-20260726.md`:
- **Agreement rate: 100%** at every tested configuration (0 disagreements across 9,600 total verdicts
  checked across four configurations, including the shipped one).
- **Ceiling breach at the AC's literal 50-pairs/seed spec**: 183.55 s vs. the 60 s ceiling (3.06× over).
- **Cut-lever applied correctly, per its own policy** (reduce pairs before seeds, re-measure once, escalate):
  reduced to 5 pairs/seed → **44.52 s (74% of budget)**, shipped configuration, **100 seeds preserved**
  (seed diversity never reduced).
- **Escalated to technical-director** as required — recorded in the evidence doc, not silently absorbed.
  Root cause identified as a large fixed per-seed cost (terrain gen + full `VillagerNavGraph` build per
  seed), not primarily pair count — reducing pairs 5× only bought ~3.35× speedup.
- Determinism test present and passing (`test_corpus_two_consecutive_runs_produce_identical_verdict_sequences`).
- **This is a real, honestly-recorded deviation from AC36's literal spec (10x fewer verdicts than
  specified), not a defect being hidden.** Carried forward — see §9 and §10.

---

## 5. `needs-mood-001`'s two-tier config result

- **AC29 BLOCKING ladder invariant**: test file contains the boundary assertions (`0.7`/`0.7` BLOCKING,
  `=1.0` BLOCKING, `0.4`/`0.7` clean) — proven by test, not asserted in prose. **PASS.**
- **This plan's shipped-value literal assertion (Content Requirement 4)**: confirmed present and distinct
  from the ladder check — `assert_float(config.decay_per_tick_sleep).is_equal_approx(0.07, ...)`,
  `base_recovery_per_tick_sleep` → `0.5`, `mood_smoothing_ticks` → `40.0`, at three separate call sites in
  the test file (default-construction, `.tres`-load, and post-`validate()` paths). **PASS.**

---

## 6. Full regression suite counts

Read from the most recent story evidence doc that recorded a full run
(`build-validation-010-reachability-corpus-runtime-20260726.md`, the last Should item, and cross-checked
against `building-001`'s own story header, the sprint's final story):

- **Baseline**: 951 (Sprint 8 actuals) → interim 953 (two post-Sprint-8, pre-Sprint-9 commits) →
  **final: 1198** (`building-001`'s own status line: "1198/1198 suite green 0 orphans, parent-verified";
  matches the Sprint Result's "Suite grew 953 -> 1198").
- **Pass/fail/error/skip**: 1198 test cases, 0 errors, 0 failures, 0 flaky, 0 skipped (per
  `build-validation-010`'s evidence doc, which ran the suite at that point in the sequence: "1,198 test
  cases, 0 errors, 0 failures, 0 flaky, 0 skipped, 0 orphans, exit code 0", runtime 6 min 49 s).
- **Orphan count**: 0, explicitly stated (not inferred from "exit 0" alone, per the plan's own item 11
  requirement).
- **Exit code**: 0, explicitly stated.
- **No dedicated `production/qa/smoke-2026-07-26-sprint9.md` artifact exists.** The only file matching
  `production/qa/smoke-*.md` from 2026-07-26 is a **Sprint 8** story's smoke check (`vox-016`). This is a
  **process gap**: the DoD's own smoke-check line was satisfied in substance (every story's evidence doc
  records a full-suite green run at its own point in the sequence, and the final counts are internally
  consistent), but no single consolidated Sprint 9 smoke-check document exists as its own artifact. Carried
  forward — see §10.

---

## 7. Grep-guard results

| Guard | Result |
|---|---|
| Zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D` in Build Validation | **PASS** (not re-run fresh this session beyond the targeted greps below; no occurrence found in any file read) |
| Zero `VillagerWalkabilityRules.new(` anywhere in `src/` | **PASS** (verified — one textual hit, inside a doc comment describing the guard, not an instantiation) |
| Zero duplicated walkability-constant literals | **PASS** (verified — exactly two literal declarations, both in `villager_walkability_rules.gd`; `villager_ai.gd`'s consts are alias re-exports, not literals) |
| Zero `VillagerAi` type reference in Build Validation's own module | **PASS** (verified — `VillagerAi` appears only inside doc comments in `build_validation.gd`/`build_validation_config.gd`, never as an actual typed field or parameter) |
| `cells_changed_batch` bound exactly once / `construction_completed` bound zero times in Build Validation | **PASS** (verified — `build_validation.gd` connects only `cells_changed_batch`; every `construction_completed` occurrence is a doc comment) |
| Zero grid-write calls from `building-023`'s ghost preview | **Not independently re-verified this session** — relies on the story's own evidence doc claim; no contradiction found |
| `SceneTree.paused` / `Engine.time_scale` zero matches | **Not independently re-run this session** — no contradicting evidence found in any file read |
| Zero `Thread`/`WorkerThreadPool` near Needs & Mood state | **Not independently re-run this session** — no contradicting evidence found |

---

## 8. Open bug list

- **S1/S2 count: 0.** No `production/qa/bugs/*.md` files exist for this sprint (directory empty). The
  three real defects the sprint discovered in already-shipped code (drag release-cell offset, boot
  residency page-in signal gap, nav-graph 6.7s cost) were each **found and fixed inline within the same
  story that discovered them**, with a regression test added in every case — they were never left open as
  standing bugs, so there is nothing to file against the S1/S2 gate. This satisfies the DoD's "no open
  S1/S2 bugs" line, but note the **process gap**: none of these three went through `/bug-report`, so there
  is no bug-tracking-system record of them outside the commit messages and evidence docs. Acceptable for
  same-sprint same-story fixes; would not be acceptable if a defect crossed a story boundary un-filed.
- **S3/S4 count**: none formally filed; not separately assessed this session.

---

## 9. Deviations flagged this sprint (recorded honestly, not absorbed)

1. **`build-validation-010`'s corpus ships at 5 pairs/seed instead of the AC's literal 50**, against a hard
   60 s CI ceiling — escalated to technical-director per the plan's own Cut-Lever Policy. Zero
   disagreements found at any tested density (9,600 verdicts total, including the shipped 1,000). Seed
   diversity (100 checked-in seeds) fully preserved; only per-seed sampling depth was cut. See §4.
2. **`building-023`'s ghost preview ships the State-Blue/State-Orange axis, not the art bible's
   material-tinted long-term commitment** (`design/art/art-bible.md` §7.1, 2026-07-23, user-confirmed).
   Honestly flagged in the story's own evidence doc: no color-resolution utility from item id to real
   material color exists anywhere yet (even the terrain mesher's block coloring is an explicit debug
   placeholder). This is the currently-registered `TR-building-system-093` text, not a silent shortfall —
   follow-on work is named (extend tint resolution once RID color/texture resolution lands).
3. **`needs-mood`'s real-time figures in the GDD are still computed at the stale `ticks_per_second = 2.0`
   rate**, while the shipped rate is `4.0` (raised 2026-07-23, before this sprint). Every real-time
   annotation in `design/gdd/needs-mood-system.md` (F1's "~1429 ticks ≈ 11.9 min", F2's "140 ticks = 70s",
   F3's "= 20s at 1x", etc.) is therefore 2× off as written. Tick *counts* are correct and unaffected;
   only their stated wall-clock meaning is stale. This is explicitly `needs-mood-009`'s job (S10/S11,
   not this sprint) — confirmed via that story's own file, which names the exact stale figures to correct.
4. **`build-validation-006`'s "need-functional" resolution has an untestable true branch until item
   resources exist.** The story resolves need-functional furniture through
   `ResourceItemDatabase.get_by_id(...)` against a typed config list, but no real `ItemDefinitionResource`
   with a need-functional category exists yet (furniture chain `building-028` is S10) — the story is
   correctly built and tested against a mocked provider (BV-1's own sanctioned pattern), but the
   real-item-resource code path cannot be exercised until `building-028` lands. Not a defect; a
   documented, sequenced gap.
5. **The villager body is still absent.** `VillagerAi extends Node` (no mesh, no `Area3D`, no public
   world position beyond the discrete cell). TD-specced as `presentation-003` (D2 in the sprint file) but
   **no story has been authored for it yet** — confirmed via `villager-ai-021`'s own evidence doc, which
   had to substitute a captured console/log run for the screenshot the QA plan's own checklist asked for,
   because there is genuinely nothing new to photograph. This is the most consequential open item for S10
   planning: three `villager-info-ui` stories are blocked on it and it currently has neither an owner story
   nor a scheduled sprint slot beyond "carried to S10."
6. **`building-023`'s evidence doc sign-off line was not yet countersigned** at the time this sign-off
   review began ("awaiting review — evidence prepared for that pass, not yet countersigned"). This
   document's own review of the four screenshots and the automated coverage constitutes that
   countersignature as of 2026-07-26 — recorded here so the discrepancy between the evidence doc's
   internal state and this sign-off is not silently glossed over.

---

## 10. Bugs found in ALREADY-SHIPPED code this sprint

These are not this sprint's own defects — they are real bugs in code that shipped in **prior** sprints,
surfaced only because this sprint's new test coverage happened to exercise the code paths that prior
suites never touched. Recorded because this is itself a signal about test coverage gaps, not just about
this sprint's work:

1. **Drag release-cell off-by-one (building-021, Sprint 6).** `PlacementPick._input()`'s release handler
   read `get_attach_cell()` unconditionally, double-applying a face-normal offset during a multi-frame
   drag — every real (frame-elapsed) drag's release resolved one cell too high. Found while building
   `building-023`'s live-preview re-rasterization test; no prior test caught it because every existing
   test either used a same-frame click or fed press/release cells directly into `CommitPipeline`,
   bypassing the buggy path entirely. Fixed in both `placement_pick.gd` and `ghost_preview.gd`; regression
   test added (`dda_placement_pick_test.gd::test_input_release_cell_matches_locked_plane_after_a_mid_drag_cursor_move`).
2. **Boot residency convergence bug (mesher/streamer interaction, pre-existing).** `vox-020` found that
   residency page-in emitted no signal, so a chunk meshed before its async page-in landed stayed a
   permanent hole — a real defect, distinct from the originally-escalated (and false) premise that the
   mesher subscribed to nothing at all (it does, at `voxel_world_mesher.gd:163`; that premise was
   corrected by TD Addendum D before `vox-020` was authored). Fixed via a new `chunk_became_resident`
   signal feeding the existing dirty-set/budgeted-rebuild mechanism.
3. **The nav-graph's unmeasured 6.7 s build cost.** `scene-005`'s boot-budget measurement was the first
   time `VillagerNavGraph.build()` was ever run against the shipped `nav_region_size = 200` inside a real
   boot sequence — 6697.6 ms, blowing the 3.0 s ceiling by ~3×. This had never been measured before because
   nothing called `VillagerNavGraph.build()` in the boot chain until this story wired it in. Remediated by
   retuning `nav_region_size` 200 → 40 (still within ADR-0007's measured-safe range); re-measured at
   266.6 ms, total boot 2564.9-2585.7 ms, PASS.
4. **Recurring fixture trap, found independently twice** (per the Sprint Result): sealing a gap with a
   solid block can create a legal step-up that reopens the "sealed" escape route — a fixture-authoring
   trap in the Build Validation test suite itself, not a production defect, but worth carrying forward as
   a known trap for future fixture authors in this epic.

None of these four required an S1/S2 bug ticket (all were found and fixed within the same story), but all
four indicate that the suite's coverage prior to this sprint had real blind spots at exactly the seams
this sprint's new stories exercised — worth naming as a pattern for S10's own test-strategy thinking, not
just as isolated fixes.

---

## 11. Provisional-ruling ratification status as of sign-off time

**Not independently re-checked this session against the user** — no evidence was found in any read file
that either pre-flight ruling document (`production/architecture-decisions-m02-preflight-2026-07-26.md`,
`production/creative-decisions-m02-preflight-2026-07-26.md`) has been formally ratified since 2026-07-26.
Both remain, as far as this review can determine, in their PROVISIONAL state. Per the QA plan's own DoD
requirement, **this alone would set the verdict to APPROVED WITH CONDITIONS** even absent every other
finding in this document.

---

## 12. Final verdict: **APPROVED WITH CONDITIONS**

The sprint's committed evidence chain is real and holds up under direct verification: both headline gates
pass on inspection of the actual git history and actual test file contents (not on the story files' own
say-so alone), every claimed test file exists on disk, the Content Requirement 4 literal-value guard is
genuinely present and distinct from the ladder-ordering check, and the corpus's cut-lever escalation was
applied exactly as its own policy prescribes. No S1/S2 bugs are open. This is a genuinely strong first
sign-off to set the precedent with.

**Conditions, named concretely:**

1. **User ratification of both provisional ruling documents remains outstanding** (§11) — the single
   largest open item. Until ratified, treat `villager-ai-026`, `build-validation-002`/`005`, and
   `needs-mood-001`'s shipped values as resting on an unratified planning assumption, per the plan's own
   stated blast-radius analysis (bounded, but real).
2. **`build-validation-006`, `vox-020`, `vox-021`, and `scene-005` shipped without QA-plan or
   sprint-status.yaml tracking** — retroactively confirm their evidence was adequate (this document does
   so) and update `sprint-status.yaml` to include all four, so the tracked-story count matches what
   actually shipped.
3. **`building-023`'s evidence-doc countersignature was outstanding until this document** — treat this
   sign-off as satisfying it, but close the loop by updating the evidence doc's own Sign-off line to point
   here.
4. **No dedicated Sprint 9 smoke-check artifact exists** (§6) — the DoD's smoke-check requirement was met
   in substance across individual story evidence docs, but the next sprint should produce one consolidated
   `production/qa/smoke-[date].md` at hand-off rather than relying on the last story's evidence doc to
   carry that record.
5. **`build-validation-010`'s corpus runs at 1/10 the AC's specified sampling density** — this is an open
   technical-director decision (§4/§9), not something QA can resolve; the milestone criterion #2 claim
   should state "5,000-verdict spec not yet met; 1,000-verdict shipped configuration is 0/0 disagreement"
   rather than being read as fully satisfying AC36 as literally written.

---

## 13. Carry forward to next sprint's QA

- **The villager body (`presentation-003`) has no authored story yet** — three `villager-info-ui` stories
  and this sprint's own companion-evidence gap depend on it. Should be authored before it blocks S11.
- **`needs-mood-009`'s real-time-rate pass** (correcting every stale 2.0-ticks/s figure in the GDD) — named
  and scoped, not yet started.
- **`build-validation-010`'s corpus density** — carry the TD escalation forward; do not let a future sprint
  silently treat the 1,000-verdict configuration as satisfying the 5,000-verdict AC.
- **`building-011`** (plan-only undo/redo) — deferred, not dropped; pull early in S10 per the trim note.
- **`build-validation-006`'s is_need_functional true branch** stays untestable until `building-028` lands
  (S10) — re-verify non-vacuously once it does, per the same discipline already applied to BV-1's
  furniture-transparency guard elsewhere in this epic.
- **Formal `sprint-status.yaml` and QA-plan tracking gap** for stories added to a sprint after its QA plan
  is written (`vox-020`/`021`, `scene-005`, `build-validation-006` this sprint) — future QA plans authored
  before a sprint's amendments land should be re-checked against the sprint file's final amendment state
  before sign-off, not just against the plan's own original Test Summary table.
- **Produce a single consolidated smoke-check artifact per sprint at hand-off**, rather than relying on
  the final story's own evidence doc to carry the full-suite record.
- **`building-023`'s deferred material-tint upgrade** — no action needed until the RID color/texture
  resolution machinery exists; re-visit then.


---

## Parent Verification Addendum (2026-07-26)

Two points from the sign-off, checked and corrected:

1. **Condition #2 is narrower than stated.** Of the four stories reported as absent from
   `sprint-status.yaml`, three (`vox-020`, `vox-021`, `scene-005`) were in fact already tracked;
   only `build-validation-006` was genuinely missing. It has now been added with status
   `complete`. The underlying process observation stands — mid-sprint additions can miss the
   tracking file — but the scope was one story, not four.

2. **The suite WAS executed independently.** The sign-off records that no test run was invoked
   during its own session and that counts rest on story-file records. The parent ran the full
   gate itself after every story landing this sprint, most recently at sprint close:
   `1198 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`, exit code 0.
   The counts the sign-off cross-checked are therefore independently confirmed, not
   self-reported.

The remaining conditions (unratified provisional rulings, the missing consolidated smoke artifact,
building-023's countersignature, and bv-010's reduced corpus density) stand as written.
