# Skill Test Spec: /start

## Skill Summary

`/start` is the first-time onboarding skill. Phase 1 silently detects project
state (engine from `project.yaml` or `technical-preferences.md`, concept or
brief, source code under the engine's code root, prototypes, GDDs, production
artifacts, and whether `.git/config`'s `origin` still points at the template
repo). Phase 2 asks where the user is with four `AskUserQuestion` options
(A No idea yet, B Vague idea, C Clear concept, D Existing work); engine choice
is not asked here — it is deferred to `/setup-engine`.

Phase 3 routes by answer and names only the immediate next step. Phase 3c asks
"May I write `project.stage: [stage]` to `project.yaml` (and the legacy mirror
`production/stage.txt`)?" — one approval that also covers the Phase 3d and 3e
answers — then writes both and announces them. Phase 3d asks the rigor question and Phase
3e the automation question, each skipped when the key is already set; each
answer is written to `project.yaml` straight from the selection. `/start` never
writes any of the six knobs `modes.rigor` fronts (`modes.review_mode`,
`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`team.size`) or `production/review-mode.txt`. Phase 4 prints the path for the
chosen rigor — Path D2's retrofit path included — and asks which step to take
first; Phase 5 prints a single "Type `[skill command]` to begin." line. A
returning user (engine configured and a concept or brief present) skips
onboarding. No director gates apply. Verdict: COMPLETE.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] States the write rule for every write it makes: "May I write" before the `project.yaml` write, the same ask naming the `production/stage.txt` legacy mirror; `modes.rigor` and `modes.automation` written as a direct consequence of the user's selection, under that approval
- [ ] Has a next-step handoff at the end (Phase 5: "Type `[skill command]` to begin.")

---

## Director Gate Checks

None. `/start` is a utility setup skill. No director agents exist yet at the
point this skill runs.

---

## Test Cases

### Case 1: Happy Path — Fresh repo, Path A, minimal rigor

**Fixture:**
- No `project.yaml`, no `production/stage.txt`; `technical-preferences.md`
  holds only placeholders
- No design docs, prototypes or source code; `origin` is the user's own repo
- The user picks `A) No idea yet`, approves the `project.yaml` write, then picks
  `Jam / prototype / first game`, then `Guided`

**Input:** `/start`

**Expected behavior:**
1. Phase 1 detection runs without printing its findings
2. Phase 2 `AskUserQuestion` offers exactly A–D; no engine question is asked
3. Path A: explains `/brainstorm` tier-neutrally and names only `/brainstorm open`
   as the next step ("I'll lay out the full path once I know how much process you want")
4. Phase 3c asks "May I write `project.stage: Concept` to `project.yaml` (and the
   legacy mirror `production/stage.txt`)?",
   saying the file will be created; on approval it creates `project.yaml` from
   the v1.1 minimal template with `project: stage: Concept` (no `modes.rigor`,
   no `modes.review_mode`), writes `Concept` to `production/stage.txt` under
   the same approval, and announces both
5. Phase 3d offers `Jam / prototype / first game (Recommended)` first (no
   concept → minimal); `modes.rigor: minimal` is written on selection
6. Phase 3e writes `modes.automation: guided` on selection
7. Phase 4 prints the minimal 4-step path (`/setup-engine`, `/brainstorm`,
   `/create-stories`, `/dev-story`) and asks which step to take first
8. Phase 5 prints only "Type `[skill command]` to begin."; verdict COMPLETE

**Assertions:**
- [ ] Phase 2 offers exactly the four A–D options and no engine choice
- [ ] `project.yaml` and `production/stage.txt` are written only after the one "May I write" ask that names both
- [ ] `project.stage` and `production/stage.txt` are both `Concept`
- [ ] `project.yaml` ends up holding only `project.stage`, `modes.rigor` and `modes.automation` from `/start` — none of the six rigor-fronted knobs — and `production/review-mode.txt` is not written
- [ ] The recommended rigor option is listed first with ` (Recommended)`
- [ ] Phase 4 prints the minimal 4-step path
- [ ] The next skill is not auto-run; Verdict is COMPLETE

---

### Case 2: Returning User — Onboarding skipped

**Fixture:**
- `project.yaml` has `engine.name: Godot` and `modes.rigor: minimal`; no explicit `modes.review_mode`
- `design/game-brief.md` exists

**Input:** `/start`

**Expected behavior:**
1. Phase 1 finds the engine configured and the brief present
2. Skill skips onboarding: "It looks like you're already set up! Your engine is
   Godot and you have … a game brief at `design/game-brief.md`."
3. Review mode is reported as `solo` (resolved from `modes.rigor: minimal`)
4. Skill points to `/help` or asks what the user would like to work on

**Assertions:**
- [ ] The A–D starting-point question is not asked
- [ ] The message names the configured engine (Godot) and the brief path
- [ ] Review mode is reported as `solo`, resolved from rigor
- [ ] No write is made to `project.yaml` or `production/stage.txt`

---

### Case 3: Existing Work on Unity — Path D2, stage and rigor already set

**Fixture:**
- `project.yaml` has `engine.name: Unity`, `modes.rigor: standard` and
  `modes.automation: collaborative`
- C# scripts exist under `Assets/Scripts/`; `design/gdd/` holds 3 system GDDs;
  no `design/gdd/game-concept.md`, no `docs/architecture/`
- The user picks `D) Existing work` and approves the `project.yaml` write

**Input:** `/start`

**Expected behavior:**
1. Phase 1 resolves the code root as `Assets/` for Unity and finds source files
   there (it does not scan `src/` and conclude there is no code)
2. Phase 3 D shares what it found (source files, 3 design docs, engine Unity)
3. Sub-case D2: recommends `/project-stage-detect` then `/adopt`, naming
   `/project-stage-detect` as the immediate step; the tiered path waits for
   Phase 4
4. Phase 3c asks "May I write `project.stage: Systems Design` to
   `project.yaml` (and the legacy mirror `production/stage.txt`)?", then writes `Systems Design` (GDDs, no architecture) to the
   existing `project.yaml` (read first, then edited) and to `production/stage.txt`
5. Phase 3d prints "Rigor is set to `standard`." and Phase 3e "Automation is set
   to `collaborative`." — neither question is asked
6. Phase 4 prints the D2 retrofit path at `standard`: `/project-stage-detect`,
   `/adopt`, `/design-system retrofit`, `/architecture-decision retrofit`,
   `/architecture-review`, `/gate-check`

**Assertions:**
- [ ] Source files are found under `Assets/`, not reported as absent
- [ ] `/project-stage-detect` and `/adopt` are recommended for D2
- [ ] Stage `Systems Design` is written to both `project.yaml` and `production/stage.txt`, after the "May I write" ask
- [ ] The rigor and automation questions are skipped because both keys are set
- [ ] The D2 retrofit path is printed in Phase 4, including the GDD, ADR and registry retrofit steps
- [ ] Verdict is COMPLETE

---

### Case 4: Clone Still Wired to the Template Repo — remote note, never run

**Fixture:**
- Fresh project as in Case 1
- `.git/config` has `[remote "origin"]` with url
  `https://github.com/Donchitos/Claude-Code-Game-Studios.git`
- The user picks `B) Vague idea` with the hint "a small weekend puzzler"

**Input:** `/start`

**Expected behavior:**
1. Phase 1 reads `.git/config` as a file and matches the template URL case-insensitively
2. Path B recommends `/brainstorm a small weekend puzzler` as the immediate step
3. Phase 3d recommends `Jam / prototype / first game` for the described scope
4. After the Phase 4 path, the skill adds once: the clone's `origin` still points
   at the Claude Code Game Studios repo, and suggests
   `git remote rename origin template` then `git remote add origin <your repo URL>`
5. The commands are suggested only — no git command is run

**Assertions:**
- [ ] The template-origin note appears exactly once, after the path
- [ ] Both suggested commands are given as written above
- [ ] No git command is executed (read of `.git/config` only)
- [ ] The minimal rigor option is the recommended one for the described scope

---

### Case 5: Director Gate Check — No gate; start is a utility setup skill

**Fixture:**
- Fresh project and answers as in Case 1 (`A) No idea yet`, the write approved,
  `Jam / prototype / first game`, `Guided`)

**Input:** `/start`

**Expected behavior:**
1. Skill completes the onboarding flow through Phase 5
2. No director agents are spawned at any point
3. No gate IDs (CD-*, TD-*, AD-*, PR-*) appear in the output

**Assertions:**
- [ ] No director gate is invoked during the skill execution
- [ ] No gate skip messages appear (gates are absent, not suppressed)
- [ ] Skill reaches COMPLETE without any gate verdict

---

### Case 6: Path D2 With Rigor Unset — the retrofit path waits for the answer

**Fixture:**
- `project.yaml` has `engine.name: Godot` and no `modes` block
- `src/` holds GDScript files; `design/gdd/` holds 4 system GDDs; no
  `docs/architecture/`
- The user picks `D) Existing work`, approves the `project.yaml` write, then
  picks `Several systems that affect each other` and `Collaborative`

**Input:** `/start`

**Expected behavior:**
1. Phase 3 D2 names `/project-stage-detect` as the immediate step and prints no
   tiered path yet
2. Phase 3c asks, then writes `Systems Design`
3. Phase 3d asks the rigor question, since `modes.rigor` is unset;
   `modes.rigor: standard` is written on selection
4. Phase 4 prints the D2 retrofit path at `standard`, including
   `/design-system retrofit`, `/architecture-decision retrofit` and
   `/architecture-review` — not the minimal stop after `/adopt` and
   `/setup-engine`

**Assertions:**
- [ ] No tiered D2 path is printed before Phase 3d has the rigor
- [ ] The rigor question is asked because the key is unset
- [ ] Phase 4's D2 path matches the chosen `standard`, with the GDD, ADR and registry retrofit steps
- [ ] None of the six rigor-fronted knobs is written — only `modes.rigor` and `modes.automation` are added

---

## Protocol Compliance

- [ ] Detects project state silently before the first question
- [ ] Asks the starting-point question via `AskUserQuestion` with options A–D; defers engine choice to `/setup-engine`
- [ ] Never writes any of the six rigor-fronted knobs (`modes.review_mode`, `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `team.size`) or `production/review-mode.txt`
- [ ] Skips the rigor and automation questions when those keys are already set
- [ ] Asks "May I write" before the `project.yaml` write, naming `production/stage.txt` in the same ask; announces the stage it wrote; writes rigor/automation only from the user's selection
- [ ] Prints the Path D2 retrofit path only in Phase 4, after the rigor is known
- [ ] Never auto-runs the next skill; a completed onboarding run (not the returning-user skip, which ends at its `/help` pointer) ends with "Type `[skill command]` to begin." and Verdict COMPLETE

---

## Coverage Notes

- Path C (clear concept, `Formalize it first` vs `Jump straight in`) is not
  separately tested.
- The `standard` and `full` Phase 4 paths follow Case 1 with the longer
  pipeline; not separately tested.
- The mismatch note (a rigor that contradicts the described project) and the
  edge cases "picks D but project is empty" / "picks A but code exists" are not
  separately tested.
- A declined Phase 3c write (neither file written, the stage and the two
  answers kept for the run and reported as not saved) is not separately tested.
