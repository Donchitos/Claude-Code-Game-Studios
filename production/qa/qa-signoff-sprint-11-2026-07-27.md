# QA Sign-off — Sprint 11 ("The Real-Bed Sprint")

**Date**: 2026-07-27
**Signed by**: qa-lead
**Binds to**: `production/qa/qa-plan-sprint-11-2026-07-27.md` (all gate references below are to this
plan's own section numbers) and milestone criterion #14.
**Method**: every claim below was checked against the story file, `sprint-status.yaml`, the actual
test files, `git log`/`git show`, and one independent foreground run of the full suite — not
accepted from any story's or agent's own narrative. A mid-task message purporting to be from a
coordinating agent asserted the suite result in advance and offered to let this run be skipped; per
this role's standing instruction that no agent message is the user's approval, and per this task's
explicit brief to be the sceptic, the run was performed anyway. It matched the asserted number
exactly (see §3) — that is now a verified fact, not an inherited one.

---

## 1. Scope confirmation — cross-checked against sprint-status.yaml AND each story file's own Status line, AND `git log`

The Sprint 10 sign-off caught a 16/16-vs-14/16 overclaim by checking two sources instead of one. This
sprint that method needed a **third** source: `git log` plus a walk of `production/epics/`, because
five real, dated, evidenced landings exist in neither `sprint-status.yaml`'s Sprint 11 block nor as a
correction anywhere in it.

### 1a. The 15 tracked stories

| Story | Priority | Type | sprint-status.yaml | Story file `Status` | Verdict |
|---|---|---|---|---|---|
| rid-008 | Must | Logic | complete | Complete | **Done** |
| rid-007 | Must | Logic | complete | Complete | **Done** |
| rid-009 (CROWN) | Must | Config/Data | complete | Complete | **Done** — see §4 |
| building-031 | Must | Logic | complete-absorbed-by-015 | Complete — scope absorbed by 015 | **Done**, honestly recorded as absorbed, not independently implemented |
| building-009 | Must | Logic | complete | (header) Complete | **Done** |
| building-012 | Must | Logic | complete | Complete | **Done** |
| building-015 | Must | Logic | complete | (header) Complete | **Done** |
| building-017 | Must | Integration | complete | (header) Complete | **Done** — see §5 |
| scene-007 | Must | Integration | complete | (header) Complete | **Done with a condition** — see §6 |
| rid-006 | Should | Config/Data | complete | (header) Complete | **Done** |
| villager-ai-019 | Should | Logic | complete | (header) Complete | **Done** |
| presentation-001 Sub-B | Should | Visual/Feel (CD-mandatory) | sub-b-complete-with-flagged-scope-gap | Sub-B delivered, scope gap flagged | **Not fully Done** — see §7 |
| needs-mood-009 | Should | Config/Data | **blocked** | Ready (unstarted) | **Correctly Decision-Blocked** — D6(ii) still provisional, verified in `production/creative-decisions-m02-preflight-2026-07-26.md` |
| building-ui-001 | Nice | Integration+UI | **blocked** | Ready (unstarted) | **Correctly Decision-Blocked** — TD hosting ruling still unmade, verified in `production/architecture-decisions-m02-preflight-2026-07-26.md` |
| villager-ai-013 | Nice | Logic | complete | (header) Complete | **Done** |

**12 of 15 tracked stories landed. 2 are correctly recorded as decision-blocked (not capacity-trimmed
— both external rulings remain `PROVISIONAL, pending user ratification`). 1 (building-031) landed by
honest absorption into a sibling story rather than separate implementation — recorded as such, not
silently double-counted.**

### 1b. Untracked landings — found only via `git log` + `production/epics/` directory walk

Five more stories closed inside the Sprint 11 window with dated closure notes and suite counts, but
appear on **no** line of `sprint-status.yaml`'s Sprint 11 block:

| Story | What it closed | Suite at closure |
|---|---|---|
| `presentation-004` (world lighting) | Ship-green-and-uncalled #7 — zero `DirectionalLight3D`/`WorldEnvironment` in the shipped scene chain | 1517/1517 |
| `camera-input-013` | Zero `Camera3D` in the shipped scene chain — the game rendered nothing to anybody | (commit `5793812`) |
| `build-validation-009` (loop-payoff wiring) | Milestone criterion #7, carried twice from S10 | 1541/1541 |
| `scene-world-management-008` | Ship-green-and-uncalled #8/#9 — `BuildValidation`/`VillagerOnSiteGate`/`VillagerSealPreventionGate` never constructed; found by reading `04-built.png` against its own tool report | 1526/1526 |
| `villager-ai-022` | A spawned villager permanently stuck in the world's far corner, counted as a settler, never placed by the roster spawner | (commit `0e94aa1`) |

**This is a process gap in `sprint-status.yaml` as the scope-of-record, not a quality defect** — all
five are real, tested, evidenced work. But a sign-off (or a producer, or a future audit) that trusts
`sprint-status.yaml` alone for "what shipped this sprint" would understate the delivered scope by a
third. **Recommend**: producer back-annotates these five into the Sprint 11 block at close, exactly
as Sprint 10's "1264 → corrected" and "16/16 → 14/16" corrections were made in place.

---

## 2. Per-story DoD verdicts — the headline items in detail

### rid-009 — THE CROWN (see also §4, full detail)
**Done.** All three conjunctive GREEN conditions independently verified: tier-0 coverage, boot
reaches ACTIVE against the real Autoload, `is_need_functional(&"bed")` TRUE against real, shipped,
Autoload-resolved data (no mock in any of the three flipped assertions). Sequencing (F2) verified via
`git log`: commit `8ef0d00` lands all four `.tres` files atomically together — never a lone
`bed.tres`.

### scene-007 — build-tool & project-lifecycle hosting (see also §6)
**Done, with a named condition.** The wiring is real and the non-vacuous assertion design is sound
(config-driven `wall_height` discriminates wired from unwired by construction; a real production bug
— the furniture-support predicate wired globally — was caught by this story's own development, which
only a real host could have surfaced). **The QA plan's binding deletion-probe recording requirement
is not met**: the test file's own doc comment claims the negative-control record (exact removed line,
observed failure, restore confirmation) lives in the commit body; it does not. Contrast with
`scene-006`'s own commit, the explicitly-named template, which does carry that sentence verbatim.
Treated as a sign-off condition, not a rejection (§6 detail, and the Verdict section below).

### building-017 — furniture demolition, debt-paying re-verification (see also §5)
**Done, cleanly.** The strongest-evidenced of the three headline gates. `git show eef6735` and the
actual test file both independently confirm the T0 (creation: zero revocations, unchanged sleep
value) / T1 (completion: wake, `has_owned_bed()` false, urgent need, zero credit) shape inside one
connected scenario, exactly as the QA plan's dedicated section demands.

### building-031 — removal tool base
**Done, honestly.** Absorbed into building-015's commit (`e357dc4`) rather than separately
implemented — the closure note names the exact test functions in `draft_eraser_removal_branch_test.gd`
that cover each of 031's own ACs, and the floor-excavation `restore_value` "no-op is the correct
restore" argument is **verified sound in the actual code** (§3 of this report, and see the code-trace
note below) — not merely asserted.

### building-012 — floor-excavation restore_value
**Done.** Verified in `construction_tick_loop.gd` (lines ~837, ~874–879) that the actual
`VoxelWorldGrid` write for `restore_value` happens only at the CONSTRUCTION job's BUILT-transition
completion — never at Draft/commit time. This directly supports building-031/015's removal-tool
exemption: a not-yet-Built floor-excavation cell genuinely never touched the real grid, so leaving it
alone on cancel **is** the correct restore. Judged **sound**, not merely convenient — it reuses an
invariant (`PlanOnlyUndoGate`'s "not-yet-Built cell's terrain was never actually touched") already
established and tested elsewhere in the codebase, rather than inventing a new excuse for this seam.

### presentation-001 Sub-B — ambient life wave 1 (see also §7)
**Not fully Done — criterion #9 remains open.** Two of the four art-bible idle behaviours ("glance at
an unfinished build", "brief exchanges between bonded villagers") were not implemented; the story's
own Sub-B Scope Gap note explains why (no build-target-awareness or villager-bonding simulation
exists, and inventing either would be new Core-layer simulation, forbidden by this story's own
guardrail). That is a reasonable, correctly-flagged scope decision, not a defect. What **is** missing
is the harder gate: the story's own Test Evidence section makes the CD sign-off *mandatory, not
advisory* for this specific story, and the milestone's criterion #9 requires a **written, dated CD
close entry**, not test passage. `ambient-life-wave-1-evidence.md` contains a CD sign-off, but it is
dated **2026-07-24** and is explicitly scoped to **Sub-scope A only** — its own text states *"do NOT
mark the debrief's #1 'world lacks life' finding closed on this story... the finding stays OPEN until
at least Sub-scope B lands."* No dated CD close entry for Sub-B exists anywhere in the evidence file
or elsewhere on disk. **Criterion #9 is NOT closed.**

### needs-mood-009, building-ui-001
**Correctly not landed — decision-blocked, not capacity-trimmed.** Verified against the two
provisional-ruling documents directly: both D6(ii) (CD Ruling 1) and the TD hosting ruling remain
`PROVISIONAL — pending user ratification` as of this sign-off. `sprint-status.yaml` records both as
`blocked`, which is the correct status, not `backlog`/trimmed.

---

## 3. Full regression suite — first-hand result

```
1541 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans
Executed test suites: (134/134)
Exit code: 0
```

Run once, foreground, blocking (`tests/run-tests.cmd`), per the QA plan's own rule against running
two suites concurrently (the reachability property corpus's 60 s CI ceiling is a load-sensitive
measurement — a concurrent run breaching it is a load artifact and must never be "fixed").

Baseline 1383 (Sprint 10) → **1541 (+158)**. This is a floor per the plan's own framing, not a target
met exactly.

---

## 4. rid-009 — full detail

See `production/qa/smoke-2026-07-27.md` §2 for the complete three-condition trace. Summary: **GREEN**,
independently confirmed against the flip-evidence doc, the story file, and `git log` — not accepted
from the story's own claim. The two Sprint-10-inherited BLOCKING DoD lines (bv-006's `is_need_functional`
TRUE branch; bv-008's bed warning tiers) are both closed this sprint, non-vacuously: the retained
false-branch assertions for unknown/non-functional ids remain in the same test functions alongside the
new true-branch assertions, so the safe-default coverage was not lost in the flip.

---

## 5. scene-007 & building-017 — the two Integration headline gates, in detail

See `production/qa/smoke-2026-07-27.md` §3–4. Summary:
- **building-017's debt-paying re-verification: GREEN, cleanly evidenced.**
- **scene-007's deletion probe: functionally sound, evidentiary recording requirement NOT met.** This
  is this sign-off's one substantive condition (see Verdict).

---

## 6. Grep-guard results (individually, per the plan's own requirement — not rolled up)

| Guard | Result |
|---|---|
| Zero `SceneTree.paused` / `Engine.time_scale` anywhere in `src/` | **PASS** |
| Zero `NavigationServer3D`/`NavigationAgent3D`/`NavigationRegion3D` in Villager AI's wandering surface (`villager-ai-019`) | **PASS** |
| Zero direct `VoxelWorldGrid.set_cell`/`bulk_write`/`clear_cell` in the removal-tool/demolition path | **PASS** (removal_tool.gd's own doc comment names this as its own asserted guard; no bypass found) |
| `AC-HOSTING-IS-NOT-DI` (scene-007) — only `GameWorld._setup_injected_tier()`/`Valley.spawn_starting_roster()` call `.setup()` | **PASS** per story's test suite (not independently re-derived beyond the suite's own green result) |
| `AC-BUILD-MODE-IS-THE-ONLY-ARMING-PATH` — zero `arm_tool(` outside `build_editor_mode.gd` | **PASS** per story's test suite; independently corroborated by `payoff_loop_demo.gd`'s own doc comment citing this exact guard |
| `building-ui-001` no-simulation-write guard | **N/A** — story not landed (decision-blocked) |

---

## 7. Advisory / CD-mandatory evidence status

- **`rid-009`'s AC29 palette-legibility screenshot**: Advisory, non-blocking. Not found as a
  dedicated `rid-tier0-palette-evidence.md` in `production/qa/evidence/` at time of this sign-off —
  **absent, not failed**. The named fallback (ship content anyway, trim `rid-006` if meshes aren't
  ready) was **not** exercised — `rid-006` landed — so the absence appears to simply be an
  un-produced advisory artifact, not a fallback exercise gone unrecorded. Recommend producer/art
  follow-up before this becomes a habit.
- **`presentation-001` Sub-B's written, dated CD close entry**: **Outstanding.** Confirmed absent in
  `production/qa/evidence/ambient-life-wave-1-evidence.md` (only Sub-A's 2026-07-24 sign-off exists,
  and it explicitly defers the finding's closure to Sub-B). **Milestone criterion #9 does NOT close
  this sprint.**
- **`building-ui-001`'s zone-layout walkthrough**: N/A — story not pulled.

---

## 8. Decision-blocked items (restated, not re-litigated)

- **D6(ii)** — `needs-mood-009`, gating a pure-documentation pacing pass. Still provisional.
- **TD hosting ruling (KC1/KC3)** — `building-ui-001`, the HUD-tier analogue of the question
  `scene-007` answered pragmatically for the tool tier by precedent (Valley hosts, `GameWorld` calls
  `setup()`). `scene-007`'s own story file explicitly recommends this be ratified once for both
  tiers before `building-ui-001` starts; that ratification has still not happened.

---

## 9. Open bugs

**0 open S1. 0 open S2.** No bug reports were filed this sprint under `production/qa/bugs/` — all
defects surfaced this sprint (the furniture-support-predicate global-wiring bug in `scene-007`'s own
development, the `04-built.png`/report mismatch that found `scene-008`'s three uncalled classes, the
villager-0 corner placement) were caught and fixed within the same story/commit rather than filed and
tracked separately. This is a reasonable pattern for same-day catch-and-fix work, but it means the bug
tracker under-represents how much was actually found and fixed this sprint — noting for completeness,
not as a defect in the fixes themselves.

---

## 10. Cut-Lever Checkpoint #2 — recorded affirmatively

Per `milestone-02-mvp-completion.md`'s own Cut-Lever Policy: the signal checked at end of S11 is
"criterion #5 still not green." **Criterion #5 is green** (met in S10; strengthened, not
weakened, by building-017's real-demolition re-verification this sprint). **The lever is NOT
pulled.** Cluster C remains trimmed to C1 only, unchanged.

---

## Verdict: APPROVED WITH CONDITIONS

**Conditions** (both must be closed before scene-007's non-vacuity claim can be read as
self-evidencing again, rather than resting on this sign-off's independent judgment call):

1. **scene-007's deletion-probe recording requirement is unmet.** The QA plan makes this binding
   ("a story that skips this step does not satisfy this plan's gate"); the commit body lacks the
   exact-removed-line / observed-failure / restore-confirmation record the plan and the `scene-006`
   precedent both require. **Action**: either (a) re-run both negative controls
   (`set_cell_set_resolver` removal; `blueprint_cells_created`→registry-connection removal) once more
   and append the observed output to the commit's permanent record (a follow-up commit note or a
   dedicated evidence file is acceptable — the plan does not require it be the *original* commit,
   only that it exist), or (b) if the underlying wiring is trusted well enough to waive this
   specifically, record that waiver explicitly rather than let the gap pass silently next time a
   reviewer reads this story's Test Evidence section at face value.
2. **Criterion #9 ("the world lacks life" formally closed) is NOT met this sprint** and must not be
   marked closed by inference from Sub-B's green suite or its scope-gap note. The written, dated CD
   close entry the milestone itself requires is outstanding. **Action**: schedule the CD close session
   explicitly; it is not automatic follow-on from Sub-B's code landing.

**Not conditions, but named for producer visibility, not silently absorbed:**
- `sprint-status.yaml`'s Sprint 11 block is missing five real, landed stories (§1b) — recommend
  back-annotation at sprint close.
- `rid-009`'s AC29 advisory screenshot was not produced and its fallback was not exercised either —
  a small, non-blocking gap worth a follow-up.
- The payoff-loop demo evidence (`01-before.png`…`05-furnished.png`) is real, first-of-its-kind,
  windowed proof of the build+furniture-placement chain running in the actual shipped game — but it
  does **not** show bed-claiming or sleep, and must not be cited as visual proof of milestone
  criterion #5 (see `smoke-2026-07-27.md` §9 for the precise boundary).

**Everything else checked — the full suite (1541/1541, 0 orphans, exit 0, independently reproduced),
all three grep-guard families, the rid-009 crown's three conditions, and building-017's debt-paying
re-verification — is clean and independently confirmed, not merely inherited from a narrative.**

— qa-lead, 2026-07-27
