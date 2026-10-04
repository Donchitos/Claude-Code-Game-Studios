# Skill Test Spec: /dev-story

## Skill Summary

`/dev-story` implements one story. It finds the story (argument, else the active
story in `production/session-state/active.md`), resolves the workflow tier for the
story's system, verifies required inputs per tier (TR registry, governing ADR,
control manifest), reads the ADR's `## Status`, `## Last Verified` and `## Date` in
one grep — a `Proposed`, `Deprecated` or `Superseded` status blocks the story at
every tier, while a story whose ADR field reads `N/A` references none — and checks ADR
freshness by comparing the story's `ADR Version` with the ADR's current version
(`Last Verified`, else `Date`, else `unversioned` — the rule `/create-stories`
stamps with). It checks the story's `Manifest Version` and its dependencies, asks
to mark the story `In Progress`, and routes implementation to a programmer agent
plus the project's engine specialist. It does not write source code itself, and
every file it does write — story fields, `sprint-status.yaml`, a dependency's
`Status`, a Config/Data file, Unity's `ScreenshotOnArg.cs` — follows an ask that
names it; only the session-state checkpoint is written without one.

After the agent returns it verifies the agent finished, runs the engine parse
check, launches the build to observe anything player-visible (`Run result:`
line), prints an "Implementation Complete" summary and overwrites the CHECKPOINT
block in `active.md`, whose **Next step** follows the result: `/story-done` after
Implementation Complete, `/dev-story` to resume after INCOMPLETE, the unblocking
action after BLOCKED. It never closes the story it implements — `/story-done`
does that; `/code-review` is recommended first at `standard`/`full`. At
`qa.level: minimal` a Logic or Integration story's test requirement is waived and
the waiver is printed; a UI or Visual/Feel story's screenshot is never waived, and
the run-and-observe step runs at every level.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains status keywords: BLOCKED, INCOMPLETE, In Progress, NOT VERIFIED
- [ ] Contains "May I write" collaborative protocol language (its own asks for the files it writes; source and tests delegated to sub-agents)
- [ ] Has a next-step handoff at the end (`/story-done`, with `/code-review` first at standard/full)
- [ ] Documents per-tier input requirements (`full` / `standard` / `minimal`)
- [ ] Notes that implementation is delegated to specialist agents (not done directly)

---

## Director Gate Checks

No director gates. `/dev-story` spawns implementation agents (a primary programmer
and the engine specialist), not director review gates, and does not resolve
`review_mode`. Code review is the separate `/code-review` skill, named as the next
step at `standard`/`full`.

---

## Test Cases

### Case 1: Happy Path — Logic story implemented at full workflow

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `specialists.code: godot-gdscript-specialist`,
  `modes.workflow: full`, `qa.level: standard`
- `production/epics/combat/story-001-damage-calc.md`: `Status: Ready`, Layer Core,
  Type Logic, `Requirement: TR-combat-001`, `ADR Governing Implementation: ADR-0003`,
  an `ADR Version` equal to ADR-0003's `## Last Verified` date, a `Manifest Version`
  equal to the manifest header date, Dependencies None, Test Evidence
  `tests/unit/combat/combat_damage_calc_test.gd`
- `docs/architecture/tr-registry.yaml` has `TR-combat-001`; ADR-0003 exists and is
  Accepted; `docs/architecture/control-manifest.md` exists
- `production/sprint-status.yaml` does not exist

**Input:** `/dev-story production/epics/combat/story-001-damage-calc.md`

**Expected behavior:**
1. Reads the story and greps `id: TR-combat-001` from the registry
2. Greps ADR-0003's `^## (Status|Last Verified|Date)` — Status is Accepted and its
   current version (the `Last Verified` date) matches the story, so the ADR is not read
3. Greps `^## Core Layer Rules` from the manifest; Manifest Version matches, no ask
4. Asks "May I mark this story In Progress?", naming the story file (and not the
   absent `sprint-status.yaml`); on yes sets the story's `Status:` to `In Progress`
   and its `Last Updated:`; prints "Sprint status not updated:
   production/sprint-status.yaml absent"
5. Spawns `gameplay-programmer` with `godot-gdscript-specialist` as secondary,
   briefing the story path, TR-ID lookup, the story's ADR Decision Summary and
   Implementation Notes inline, the Core layer rules, and the test file path
   with the test requirement
6. Confirms the agent finished, runs the Godot parse check and reports its exit code
7. Prints "Implementation Complete: [title]" with files, test function count,
   Verification and a `Run result:` line; next step `/code-review` then `/story-done`
8. Overwrites the `<!-- CHECKPOINT -->` block in `active.md`

**Assertions:**
- [ ] ADR-0003 is not read in full when its `Last Verified` matches the story's `ADR Version`
- [ ] The In Progress ask names the story file; `Status:` becomes `In Progress` only after it and before any agent is spawned, and the sprint-status-absent line is printed
- [ ] Primary is `gameplay-programmer`; secondary comes from `specialists.code`, not the roster table
- [ ] The ADR guidance is passed inline, not as the ADR path
- [ ] The brief names `tests/unit/combat/combat_damage_calc_test.gd` (`[system]_[feature]_test.gd`) and requires one test per acceptance criterion
- [ ] The parse check's command and exit code are reported, and exactly one `Run result:` line appears
- [ ] Story is NOT marked Complete; the handoff is `/code-review` then `/story-done`
- [ ] The CHECKPOINT block in `active.md` is overwritten, not appended to

---

### Case 2: Failure Path — Referenced ADR is Proposed

**Fixture:**
- `project.yaml`: `modes.workflow: standard`
- Story file with `Status: Ready` and `ADR Governing Implementation: ADR-0005`
- `docs/architecture/adr-0005-*.md` exists with `## Status` Proposed

**Input:** `/dev-story production/epics/[epic-slug]/story-[NNN]-[slug].md`

**Expected behavior:**
1. Skill reads the story and resolves the `standard` tier
2. Skill determines that the referenced ADR-0005 is Proposed
3. Story is set BLOCKED in session state; no programmer agent is spawned
4. Output names ADR-0005 and recommends `/architecture-decision accept ADR-0005`
5. A partial report is produced; the story file's `Status:` is not changed

**Assertions:**
- [ ] The Proposed status is read from ADR-0005's `## Status` section, not inferred
- [ ] No programmer or engine-specialist agent is spawned
- [ ] Output names ADR-0005 and recommends `/architecture-decision`
- [ ] The story header stays `Status: Ready`, and no "May I mark this story In Progress?" ask is shown
- [ ] BLOCKED is recorded in session state, and the checkpoint's **Next step** names `/architecture-decision accept ADR-0005` — not `/story-done`

---

### Case 2b: Failure Path — Proposed ADR at the `full` tier

The `full` column of the file-check table has its own STOP rule, so the
`standard` case above does not exercise it.

**Fixture:**
- `project.yaml`: `modes.workflow: full`
- Story file with `Status: Ready`, `ADR Governing Implementation: ADR-0005` and an
  `ADR Version` older than ADR-0005's `## Last Verified` date
- `docs/architecture/adr-0005-*.md` exists with `## Status` Proposed;
  `docs/architecture/tr-registry.yaml` and the control manifest exist

**Input:** `/dev-story production/epics/[epic-slug]/story-[NNN]-[slug].md`

**Expected behavior:**
1. Skill greps ADR-0005's `^## (Status|Last Verified|Date)` and reads `Proposed`
2. It stops before the freshness comparison: "ADR [path] is still Proposed. Accept
   it with `/architecture-decision accept ADR-0005` before implementing."
3. Story is set BLOCKED in session state; no programmer agent is spawned

**Assertions:**
- [ ] The stop happens at `full`
- [ ] The Status decides before the freshness check: no ADR-version mismatch prompt is shown although the versions differ, and the ADR is not read beyond the one Grep
- [ ] No programmer or engine-specialist agent is spawned, and the story stays `Status: Ready`

---

### Case 3: ADR changed since the story was written

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: full`
- Story file with `Status: Ready`, Type Logic, `Requirement: TR-combat-002`,
  `ADR Governing Implementation: ADR-0004`, an `ADR Version` older than ADR-0004's
  `## Last Verified` date, a `Manifest Version` equal to the manifest header date,
  Dependencies None
- `docs/architecture/tr-registry.yaml` has `TR-combat-002`; ADR-0004 exists with
  `## Status` Accepted and is under 50KB; `docs/architecture/control-manifest.md`
  exists
- User picks `[A]` at the prompt

**Input:** `/dev-story production/epics/[epic-slug]/story-[NNN]-[slug].md`

**Expected behavior:**
1. `Grep "^## (Status|Last Verified|Date)"` on ADR-0004 reads Accepted and a
   `Last Verified` date different from the story's `ADR Version`
2. `AskUserQuestion`: "Story was written against ADR v[story-date]. The ADR is now
   v[current-date]. Its decision may have changed. How do you want to proceed?"
   with `[A] Re-read the changed ADR sections…` (naming the refresh of this story's
   ADR summary and ADR Version) / `[B] Implement from the story's summary…` /
   `[C] Stop…`
3. On [A]: checks the size with `wc -c`; under ~50KB, reads the ADR with one `Read`
4. Sets the story's `ADR Version` to ADR-0004's `Last Verified` date and replaces
   its ADR Decision Summary and Implementation Notes with the re-read guidance
5. Spawns the programmer with that guidance inline

**Assertions:**
- [ ] The mismatch prompt is shown before any agent is spawned
- [ ] All three options ([A] re-read / [B] accept drift / [C] stop) are offered, and [A] names the story edit it makes
- [ ] On [A] the size is checked and a sub-50KB ADR is read in a single `Read`
- [ ] The story's `ADR Version` becomes ADR-0004's `Last Verified` date — not today's date — before the programmer is spawned
- [ ] The programmer brief carries the freshly read Decision guidance inline, not the summary the story held before [A]

**Fixture (Date fallback):**
- As above, but ADR-0004 has no `## Last Verified` section; its `## Date` equals the
  story's `ADR Version` (the value `/create-stories` stamped from it)

**Expected behavior (Date fallback):**
1. The same Grep finds no `Last Verified`, so the ADR's current version is its `## Date`
2. That matches the story's `ADR Version`: the story is trusted, no prompt is shown,
   and the ADR is not read

**Assertions (Date fallback):**
- [ ] No mismatch prompt is shown — an ADR stamped from its `## Date` is not treated as stale for lacking `## Last Verified`
- [ ] ADR-0004 is not read beyond the one Grep

---

### Case 4: Edge Case — No argument; reads from session state

**Fixture:**
- No argument is provided
- `production/session-state/active.md` references an active story file
- That story file exists with `Status: In Progress`

**Input:** `/dev-story` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Skill reads `production/session-state/active.md`
3. Skill finds the active story reference
4. Skill confirms with user: "Continuing work on [story title] — is that correct?"
5. After confirmation, skill proceeds with that story

**Assertions:**
- [ ] Skill reads session state when no argument is provided
- [ ] Skill confirms the active story with the user before proceeding
- [ ] Skill does NOT silently assume the active story without confirmation

**Fixture (no active story):**
- No argument is provided
- `production/session-state/active.md` names no active story
- `production/epics/` holds two stories with `Status: Ready` and one `In Progress`

**Expected behavior (no active story):**
1. Skill asks "Which story are we implementing?"
2. It globs `production/epics/**/*.md` and lists the two `Status: Ready` stories

**Assertions (no active story):**
- [ ] The question is asked instead of guessing a story
- [ ] Only the `Status: Ready` stories are listed

---

### Case 5: Minimal tier, Logic story — tests waived

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: minimal`, `qa.level: minimal`
- Story Type Logic with `Requirement: Brief MVP feature 1` and ADR fields
  `N/A (minimal — no ADRs)`
- No TR registry, no ADRs, no control manifest
- `docs/engine-reference/godot/VERSION.md` rates the pinned version HIGH risk

**Input:** `/dev-story production/epics/[slug]/story-001-[slug].md`

**Expected behavior:**
1. Phase 2 does not stop or set BLOCKED for the absent registry, ADR or manifest
2. Before spawning, prints a `Briefing omits: …` line naming the TR registry, the
   ADR guidance and the control manifest
3. Spawns `gameplay-programmer` plus the engine specialist (VERSION.md risk HIGH)
4. The brief omits the test requirement and tells the agent: "Do not write a test
   file for this story — test evidence is waived at `qa.level: minimal`."
5. Phase 5 is skipped; the summary prints "Test evidence: waived at
   `qa.level: minimal` — no test was required or written for this story."
6. Run-and-observe still runs and prints one `Run result:` line
7. Next step is `/story-done [story-path]` directly — no `/code-review`

**Assertions:**
- [ ] No STOP or BLOCKED for the absent TR registry, ADR or manifest at `minimal`
- [ ] The `Briefing omits:` line names all three dropped inputs, the ADR included
- [ ] The engine specialist is spawned because VERSION.md rates the risk HIGH
- [ ] The test waiver is stated to the agent and printed in the summary; no tests row or "run your test suite" paragraph appears
- [ ] A `Run result:` line is printed — run-and-observe is not waived
- [ ] The handoff is `/story-done` with no `/code-review` step

---

### Case 5b: Minimal tier, UI story — the screenshot is still required

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: minimal`, `qa.level: minimal`
- Story Type UI with `Requirement: Brief MVP feature 2` and ADR fields
  `N/A (minimal — no ADRs)`
- No TR registry, no ADRs, no control manifest

**Input:** `/dev-story production/epics/[slug]/story-002-[slug].md`

**Expected behavior:**
1. Spawns `ui-programmer`; the brief has no test item and no "Do not write a test
   file" sentence — the test requirement only ever covered Logic and Integration
2. The summary prints "Retained screenshot required under
   `production/qa/evidence/[story-slug]/` before this story can be closed…"
3. Run-and-observe retains a screenshot under `production/qa/evidence/[story-slug]/`
   and prints `Run result: OBSERVED — …` with the path
4. Next step is `/story-done [story-path]`

**Assertions:**
- [ ] The UI story is not told its evidence is waived — neither in the brief nor as a "Test evidence: waived" line in the summary
- [ ] The screenshot-required line is printed at `qa.level: minimal`
- [ ] `Run result: OBSERVED` names a retained screenshot; a `NOT VERIFIED` result would be reported as a blocker, not a note
- [ ] The handoff is `/story-done` with no `/code-review` step

---

### Case 6: Unity — code under `Assets/`, capture script asked for

**Fixture:**
- `project.yaml`: `engine.name: Unity`, `specialists.code: unity-specialist`,
  `specialists.ui: unity-ui-specialist`, `commands.smoke` and `commands.run` set,
  `modes.workflow: minimal`, `qa.level: minimal`
- Story Type UI (an inventory screen) with `Requirement: Brief MVP feature 3` and
  ADR fields `N/A (minimal — no ADRs)`
- The project has `Assets/` and no `src/`; no `ScreenshotOnArg.cs` exists under `Assets/`
- `docs/engine-reference/unity/VERSION.md` rates the pinned version HIGH risk

**Input:** `/dev-story production/epics/[slug]/story-003-[slug].md`

**Expected behavior:**
1. Spawns `ui-programmer` with `unity-specialist` (`specialists.code`) and
   `unity-ui-specialist` (`specialists.ui`, for a UI story)
2. The brief sends the code to `Assets/Scripts/<System>/`, the Unity code root
3. Verification runs `commands.smoke` and reports its exit code
4. Before launching, globs `Assets/**/ScreenshotOnArg.cs`, finds none and asks
   "May I write `Assets/Scripts/ScreenshotOnArg.cs`?"; on yes writes the script
   verbatim from `.claude/docs/run-and-observe.md`
5. Launches the built player with `--scene`/`--screenshot` and prints
   `Run result: OBSERVED — …` with the retained path

**Assertions:**
- [ ] No file is written under `src/` — the Godot row is not a default
- [ ] Both specialists come from the `specialists` block, not the roster table
- [ ] `ScreenshotOnArg.cs` is written only after its ask, at `Assets/Scripts/`, exactly as run-and-observe.md gives it
- [ ] If the user declines that ask, the result is `Run result: NOT VERIFIED — ScreenshotOnArg.cs not written`, not an observation
- [ ] Verification names `commands.smoke` and its exit code

---

### Case 7: Engine unset — the code root is unresolved, nothing is written

**Fixture:**
- `project.yaml` has no `engine` block; `.claude/docs/technical-preferences.md`
  reads `Engine: [TO BE CONFIGURED]`
- The project has none of `src/`, `Assets/` or `Source/`
- `modes.workflow: minimal`; the story is Type Logic

**Input:** `/dev-story production/epics/[slug]/story-001-[slug].md`

**Expected behavior:**
1. The code root cannot be resolved (`.claude/docs/code-root-resolution.md`: no
   `engine.name`, no legacy `Engine:` value, no single unambiguous root in the tree)
2. No source file is written, and the output says the code root is unresolved

**Assertions:**
- [ ] No file is created under `src/` or any other guessed root
- [ ] The output names the unresolved code root as the reason nothing was written
- [ ] "Implementation Complete" is not printed

---

### Case 8: Dependency marked Complete through option [C]

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: minimal`, `qa.level: minimal`
- `story-003` lists `story-002` under Dependencies; `story-002` has
  `Status: In Progress`
- At the dependency prompt the user picks `[C]`, then approves the update

**Input:** `/dev-story production/epics/[slug]/story-003-[slug].md`

**Expected behavior:**
1. Reads story-002's `Status:` and asks: "Story '[story-003 title]' depends on
   '[story-002 title]' which is currently In Progress, not Complete. How do you
   want to proceed?" with `[A] Proceed anyway` / `[B] Stop` / `[C] The dependency
   is done but status wasn't updated — mark it Complete and continue`
2. On [C] asks "May I update `production/epics/[slug]/story-002-[slug].md` Status
   to Complete?"
3. On yes sets story-002's `Status:` to `Complete`, then continues with story-003

**Assertions:**
- [ ] The dependency prompt comes before any agent is spawned
- [ ] story-002 is edited only after the "May I update … Status to Complete?" ask, and only its `Status:` changes
- [ ] story-003 itself is not marked Complete — it is set In Progress, after its own ask
- [ ] Had the user picked `[B]`, story-003 would be BLOCKED in session state and no agent spawned

### Case 9: The agent stops early — INCOMPLETE, and the checkpoint says resume

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: minimal`, `qa.level: minimal`
- Story Type Logic, `Status: Ready`, ADR fields `N/A (minimal — no ADRs)`
- The programmer agent reports that it hit its turn limit after adding
  `src/combat/damage.gd`, which calls a helper it never defined

**Input:** `/dev-story production/epics/[slug]/story-001-[slug].md`

**Expected behavior:**
1. Phase 6 treats the story as INCOMPLETE: the headline says so, lists what exists,
   names the undefined helper, and offers to resume the agent
2. "Implementation Complete" is not printed and the story's `Status:` is not advanced
3. The checkpoint's **Next step** reads `/dev-story [story-path] — resume: [the
   undefined helper]`

**Assertions:**
- [ ] No "Implementation Complete" and no `Status:` change past `In Progress`
- [ ] The checkpoint's **Next step** is `/dev-story [story-path]` to resume — never `/story-done`, which `/help` reads as "the work is written"

---

### Case 10: `full` tier, a story with no governing ADR (`ADR: N/A`)

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: full`
- Story `Status: Ready`, Type Logic, `ADR Governing Implementation: N/A — no
  architectural pattern required` (what `/create-stories` writes for a
  requirement `/create-epics` flagged as untraced)
- `docs/architecture/tr-registry.yaml` has the story's TR-ID; the control manifest exists

**Input:** `/dev-story production/epics/[slug]/story-004-[slug].md`

**Expected behavior:**
1. Phase 2 reads the ADR field as `N/A`: the story references no ADR, so the `full`
   column's "ADR file [path] not found" STOP does not fire and no ADR is grepped
2. The story is not set BLOCKED; implementation proceeds, with the ADR guidance
   named in the `Briefing omits:` line

**Assertions:**
- [ ] No STOP and no BLOCKED for the `N/A` ADR field at `full`
- [ ] No ADR file is looked up for `N/A`
- [ ] Variant — the story names `ADR-0006`, whose `## Status` reads `Superseded by ADR-0009`: the story is BLOCKED at every tier, naming ADR-0009 and saying to edit its ADR field (`/create-stories` never rewrites an existing story)

---

## Protocol Compliance

- [ ] Does NOT write source code directly — delegates to specialist agents
- [ ] Resolves the workflow tier and verifies required inputs before any agent is spawned
- [ ] Mismatch and dependency prompts (`AskUserQuestion`) come before implementation
- [ ] Every file the skill itself writes — story fields, `sprint-status.yaml`, a dependency's `Status`, a Config/Data file, `ScreenshotOnArg.cs` — follows an ask that names it; only the `active.md` checkpoint is written without one
- [ ] Code is written only under the resolved code root; an unresolved root writes nothing
- [ ] Skipped phases and dropped briefing items are announced in the output
- [ ] Never emits "Implementation Complete" for an agent that stopped early (INCOMPLETE)
- [ ] Overwrites the CHECKPOINT block in `production/session-state/active.md`
- [ ] Ends with next-step handoff: `/story-done` (`/code-review` first at standard/full)

---

## Coverage Notes

- The code root is covered for Godot (`src/`) and Unity (`Assets/`, Case 6) and for
  an unresolved engine (Case 7). Unreal (`Source/<Module>/<System>/`, with the
  editor-target build as the parse check) is not given a fixture.
- The INCOMPLETE path is Case 9; `parse NOT VERIFIED` when the engine binary is
  unavailable is not given a fixture.
- The Manifest Version mismatch prompt (`[A]` update / `[B]` keep old rules, which
  records a `Manifest-Note` / `[C]` stop) follows Case 3's ask-before-spawn pattern
  and is not separately tested.
- Config/Data stories (no agent spawned) and `testing.strict` per-type overrides
  are not covered.
