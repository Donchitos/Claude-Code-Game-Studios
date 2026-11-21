# Skill Test Spec: /cut

## Skill Summary

`/cut` finishes a game from its brief. It runs only when asked (`/cut`, "what should I cut?",
"how do I finish this?") and works on the game `design/game-brief.md` describes. Phase 1 runs
`cut-read.sh` for observation rows: the Features list by number with its marks, Keep, Avoid and
Out of scope, the Dates line, `project.goal`, the built game (a one-shot's last check record,
run again once when stale and never fixed; a project's smoke command), the feel log's last
checklist, the polish list and the stories traced to a Features item. With no brief it stops and
names `/scope-check` when GDDs exist.

Phase 2 proposes cuts in a fixed order, each with a reason from what exists, and never an item a
Keep line names; polish rows come only from sources (check fails, smoke failures, the person), each ending `· from: <source>`. Phase 3
asks a target date and proposes a freeze date 70% of the way to it only for `sell`,
`early_access` and `publisher`; any other goal gets no date. An unset goal is guessed with
`/start`'s table and shown *guessed*; it is written (through `config-set.sh`) only when the
person changes it on the screen. Phase 4 shows one screen with a Writes line and asks the pick,
multi-select. Phase 5 runs `cut-apply.sh` (the `[-]` move into Out of scope, marks, the Dates
line, polish rows, a cut story's Blocked status, the renumbering of stories after a moved item)
and makes one commit of exactly those files, the pick being the commit instruction. In
`autonomous` it writes the polish list only and reports the proposals; cuts and dates wait. The
freeze date is recorded and never enforced. No director gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec`, no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Resolves `automation` and names `collaborative`, `guided` and `autonomous`
- [ ] Names every write on the Writes line before the pick, and writes nothing before it
- [ ] Never proposes an item a Keep line names
- [ ] Asks dates only for `sell`, `early_access` and `publisher`
- [ ] Has a next-step handoff (`/create-stories` for the not-yet items left)

---

## Director Gate Checks

None. `/cut` proposes; the person picks. No gate is invoked.

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` § Fixture defaults.

---

## Test Cases

### Case 1: A one-shot to sell — cuts proposed, dates asked

**Fixture:**
- `project.goal: sell`
- `design/game-brief.md` "Drowned Tower" and the same text in `prototypes/drowned-tower/brief.md`;
  Features `[x] Climb one floor`, `[ ] Ghost companion`, `[x] Tide rises`, `[ ] Boss rush mode`;
  Keep names the tide; Out of scope says "no boss fights"
- `prototypes/drowned-tower/evidence/check-run.yaml` newer than every game file, with
  `base.readable` failed and not marked deliberate

**Input:** `/cut`

**Expected behavior:**
1. Runs `cut-read.sh`; its rows show both briefs, `dates asked` and a fresh record
2. Proposes "Boss rush mode" first (Out of scope rules out boss fights), with that reason
3. Never offers "Tide rises" (a Keep line names the tide)
4. Polish shows a row for the readable fail, `· from: readable check of <date>`
5. Asks the cut pick (multi-select) and when to release it in one call; then runs
   `cut-read.sh --target <date>` and asks "Freeze on <date>?" with `Freeze then` / `Another date`
6. On the pick: `cut-apply.sh` with both `--brief` paths, `--cut 4 "<reason>"`, `--dates` and
   `--polish`; one commit `docs: cut Boss rush mode · dates · polish list (1 rows)` of the files
   the `wrote` rows name

**Assertions:**
- [ ] The Writes line names both briefs and `design/polish-list.md` before the pick
- [ ] The cut row in Out of scope is `- [-] Boss rush mode · cut: <reason> (<date>)`
- [ ] The Dates line is `**Dates:** target <date> (release) · freeze <date>`, ISO dates
- [ ] Nothing says the freeze date is enforced

---

### Case 2: A hobby goal — no date

**Fixture:** as Case 1, with `project.goal: hobby`

**Input:** `/cut`

**Expected behavior:**
1. `cut-read.sh` shows `dates not_asked`
2. The screen has no Dates line and no date is asked
3. The pick and the writes go as in Case 1, with no `--dates`

**Assertions:**
- [ ] No target or freeze date is asked, shown or written
- [ ] `project.goal` is not written

---

### Case 3: No goal set — guessed, shown guessed

**Fixture:** as Case 1 with no `project.goal`; the brief's In your words says "I want to put
it on Steam"

**Input:** `/cut`

**Expected behavior:**
1. `cut-read.sh` shows `goal - unset` and `dates guess`
2. Guesses `sell` with `/start`'s goal table and shows `Goal: sell (guessed)`
3. Asks the dates, as for `sell`
4. Writes no `project.goal`

**Assertions:**
- [ ] The goal is shown *guessed*
- [ ] `config-set.sh` is not run unless the person changes the goal on the screen

---

### Case 4: The goal changed on the screen

**Fixture:** as Case 2 (`hobby`)

**Input:** `/cut`, then "actually I want to sell it"

**Expected behavior:**
1. Runs `bash .claude/scripts/config-set.sh project.goal sell`
2. Asks the dates at once

**Assertions:**
- [ ] `project.goal` is the only `project.yaml` key written

---

### Case 5: No brief

**Fixture:** no `design/game-brief.md`; `design/gdd/combat.md` exists

**Input:** `/cut`

**Expected behavior:**
1. `cut-read.sh` prints `brief none` and exits 1
2. Says /cut works from the brief's Features list and names `/scope-check`; stops

**Assertions:**
- [ ] Nothing is written and nothing is asked

---

### Case 6: A stale record

**Fixture:** as Case 1, with `prototypes/drowned-tower/config.js` changed after the record

**Input:** `/cut`

**Expected behavior:**
1. `cut-read.sh` shows `record ... stale prototypes/drowned-tower/config.js`
2. Runs the check once (`one-shot-check.sh`, then `--record`) and fixes
   nothing; runs `cut-read.sh` again
3. Polish rows come from the new record

**Assertions:**
- [ ] No game file is changed

---

### Case 7: A project with stories, autonomous

**Fixture:** a grown game (`package.json` at the root, `engine.name: Web`), `project.goal: sell`,
`modes.automation: autonomous`; stories `story-001` (`Brief MVP feature 2`, Ready) and
`story-002` (`Brief MVP feature 4`, Ready)

**Input:** `/cut`

**Expected behavior:**
1. Runs `timeout 900 npm run smoke`; a failure becomes a polish row
2. Asks nothing; writes the polish list with `cut-apply.sh --polish`
3. Reports the proposed cuts and that the dates wait for the person; nothing is committed

**Assertions:**
- [ ] No `--cut` or `--dates` is passed
- [ ] No commit is made

---

### Case 8: A cut item with a story, and bring it back

**Fixture:** as Case 7 with `modes.automation: collaborative`

**Input:** `/cut`, pick item 2; later "bring back Ghost companion"

**Expected behavior:**
1. `cut-apply.sh --cut 2` moves the item; `story-001`'s Status becomes
   `Blocked — BLOCKED: cut by /cut <date>: <reason>` and its Requirement
   `Brief Out of scope: Ghost companion`; `story-002` becomes `Brief MVP feature 3`
2. The commit includes both stories
3. "Bring back" runs `cut-apply.sh --back "Ghost companion" not_yet`: the item is the last
   Features item, `story-001` points at its new number and is Ready again

**Assertions:**
- [ ] No story file is deleted
- [ ] The renumbered story is named on the Writes line

---

## Protocol Compliance

- [ ] Shows the proposals, polish rows and dates on one screen before asking the pick
- [ ] Names every file on the Writes line before writing, and writes nothing before the pick
- [ ] Asks with the question tool, multi-select; without one, lists the options numbered and ends the turn; a skipped or dismissed question is asked again in plain text
- [ ] Commits only the `wrote` paths in one commit, the pick being the commit instruction; with no git, says "Not committed"
- [ ] In `autonomous`, writes the polish list only, leaves cuts and dates in the report, and commits nothing
- [ ] Writes `project.goal` only when the person changes it on the screen
- [ ] Ends with the next step: build what is left before the freeze (`/create-stories` in a project) and work down the polish list
