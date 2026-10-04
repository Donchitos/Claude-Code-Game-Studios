# Skill Test Spec: /create-stories

## Skill Summary

`/create-stories` breaks a single epic into developer-ready story files. At
`standard`/`full` workflow it reads `production/epics/[epic-slug]/EPIC.md`, the
epic's GDD, the governing ADRs (section-bounded reads, never unbounded), this
layer's rules from the control manifest and this system's entries in the TR
registry. At `minimal` it synthesizes an implicit epic from
`design/game-brief.md` instead, and writes that epic's `EPIC.md` only after the
write ask names it.

Each story is classified by type (Logic / Integration / Visual/Feel / UI /
Config/Data), which fixes its required test evidence. A story governed by a
Proposed ADR is set `Status: Blocked`. In `full` review mode `qa-lead` is spawned
**once** with gate QL-STORY-READY (verdicts ADEQUATE / GAPS / INADEQUATE) and
returns test-case specs for ADEQUATE stories; GAPS go to the user (Revise /
Accept / Discuss), INADEQUATE blocks the story until it is revised; in
`lean`/`solo` the gate is skipped with a note. All stories are presented in one
summary and the skill asks once — "May I write these [N] stories to
`production/epics/[epic-slug]/`, and update `production/epics/[epic-slug]/EPIC.md`
and `production/epics/index.md`?" — then writes `story-NNN-[slug].md` files and
updates the epic's `EPIC.md` and `production/epics/index.md`. Verdicts: COMPLETE
or BLOCKED (user declined).

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" collaborative protocol language (one approval for the full story set)
- [ ] Has a next-step handoff at the end (`/story-readiness`, `/dev-story`)
- [ ] Documents story Status: Blocked when governing ADR is Proposed
- [ ] Documents QL-STORY-READY gate: active in full mode, skipped in lean/solo

---

## Director Gate Checks

In `full` mode: `qa-lead` is spawned once via `Agent` with gate QL-STORY-READY
after all stories are decomposed and before the write ask. It returns a verdict per
story (ADEQUATE / GAPS / INADEQUATE) plus Given/When/Then specs (Logic,
Integration) or manual verification steps (Visual/Feel, UI) for ADEQUATE stories.
GAPS → `AskUserQuestion` with `Revise flagged criteria` / `Accept and proceed` /
`Discuss further` — nothing is revised before the user chooses. INADEQUATE →
blocking: the story is revised with the user (or dropped and named) before the
write ask. NOT ASSESSED [missing input] → never read as ADEQUATE: the input is
supplied and the verdict re-requested, or the story is written without qa-lead
specs and marked `QL-STORY-READY: NOT ASSESSED — [input]` in the story list.

In `lean` mode: QL-STORY-READY is skipped. Output notes:
"QL-STORY-READY skipped — Lean mode."

In `solo` mode: QL-STORY-READY is skipped. Output notes:
"QL-STORY-READY skipped — Solo mode."

---

## Test Cases

### Case 1: Happy Path — Epic with 3 stories, all ADRs Accepted

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `modes.workflow: full`,
  `modes.review_mode: lean`, `modes.story_granularity: fine` (one story per
  acceptance criterion)
- `production/epics/combat/EPIC.md` exists with 3 GDD requirements and its
  governing ADRs listed
- The epic's GDD exists with exactly one acceptance criterion per requirement (one
  is a damage formula)
- All governing ADR files exist with `## Status` Accepted
- `docs/architecture/control-manifest.md` exists
- `docs/architecture/tr-registry.yaml` has TR-IDs for all 3 requirements
- `production/epics/index.md` has a row for the epic with `Not yet created`

**Input:** `/create-stories combat`

**Expected behavior:**
1. Reads EPIC.md and the GDD in full; greps this layer's `## <layer> Layer Rules`
   from the manifest and this system's TR-registry entries; loads each ADR by
   heading map + bounded reads
2. Reports "Loaded epic [name], GDD [filename], [N] governing ADRs [status], [manifest status]."
3. Classifies each story by type (the damage-formula story is Logic)
4. Notes "QL-STORY-READY skipped — Lean mode."
5. Presents the story list (title, type, ADR, covered TR-IDs, test/evidence path)
6. Asks once: "May I write these 3 stories to `production/epics/combat/`, and
   update `production/epics/combat/EPIC.md` and `production/epics/index.md`?"
7. Writes `story-001-[slug].md` … `story-003-[slug].md`, updates the EPIC.md
   Stories table and the index row to `3 stories`
8. Asks what next, recommending `/story-readiness [first-story-path]`; Verdict: COMPLETE

**Assertions:**
- [ ] Exactly 3 stories are drafted — one per acceptance criterion at `fine`
- [ ] Each story file has the header fields Epic, Status, Layer, Type, Manifest Version, and a Context block with GDD, `Requirement: TR-[system]-NNN`, ADR Governing Implementation, ADR Version, Engine/Risk
- [ ] Each story has Acceptance Criteria, QA Test Cases, Test Evidence and Dependencies sections
- [ ] The formula story is typed Logic with evidence path `tests/unit/[system]/…` (the Godot test root)
- [ ] "QL-STORY-READY skipped — Lean mode." appears and each QA Test Cases section reads "N/A — no qa-lead specs at this tier…" (no improvised test cases)
- [ ] "May I write" is asked once, after the full list is shown, and names the 3 stories, `EPIC.md` and `production/epics/index.md`
- [ ] Files are named `production/epics/combat/story-NNN-[slug].md`
- [ ] Skill does NOT start implementation

---

### Case 2: Failure Path — Named epic does not exist

**Fixture:**
- `project.yaml`: `modes.workflow: full`
- `production/epics/` contains other epics but no `nonexistent-epic/` directory

**Input:** `/create-stories nonexistent-epic`

**Expected behavior:**
1. Skill looks for `production/epics/nonexistent-epic/EPIC.md` — not found
2. Skill outputs a clear error naming that path
3. Skill recommends `/create-epics` (the Previous step) or checking the slug
   against the epics under `production/epics/`
4. No story files are created and no epic is synthesized from the brief

**Assertions:**
- [ ] Skill outputs a clear error naming `production/epics/nonexistent-epic/EPIC.md`
- [ ] No story files, EPIC.md or index row are written
- [ ] Skill recommends `/create-epics`
- [ ] Skill does NOT fall through to the `minimal` brief-synthesis branch at `full`

---

### Case 3: Blocked Story — ADR is Proposed

**Fixture:**
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: solo`,
  `modes.story_granularity: fine`
- EPIC.md exists with 2 requirements, one acceptance criterion each; both
  governing ADR files exist
- Requirement 1 is governed by an ADR with `## Status` Accepted
- Requirement 2 is governed by ADR-0007 with `## Status` Proposed

**Input:** `/create-stories [epic-slug]`

**Expected behavior:**
1. Both ADR files exist, so the `full`-tier existence check passes
2. Skill reads each governing ADR's status and finds ADR-0007 Proposed
3. Story 2 is drafted with `Status: Blocked` and the note
   "BLOCKED: ADR-0007 is Proposed — accept it with `/architecture-decision accept ADR-0007` once decided"
4. Story 1 is drafted with `Status: Ready`
5. The blocked story is flagged in the story list before the single "May I write" ask

**Assertions:**
- [ ] The ADR status is taken from the ADR's `## Status` section, not assumed
- [ ] Story 2 has `Status: Blocked` and the note names ADR-0007 and `/architecture-decision accept` — never a bare `/architecture-decision`, which starts a new ADR
- [ ] Variant — ADR-0007's `## Status` reads `Superseded by ADR-0009`: story 2 is still `Status: Blocked`, and its note names ADR-0009 as the ADR to point it at
- [ ] Story 1 has `Status: Ready` — the blocked ADR does not affect it
- [ ] The blocked story is flagged before write approval, not discovered after writing
- [ ] Both story files are written (blocked stories are still written — just flagged)

---

### Case 4: Edge Case — No argument provided

**Fixture:**
- `project.yaml`: `modes.workflow: standard`
- `production/epics/` contains 2 epic subdirectories, each with an `EPIC.md`

**Input:** `/create-stories` (no argument)

**Expected behavior:**
1. Skill detects no argument at `standard`
2. Globs `production/epics/*/EPIC.md`
3. Asks via `AskUserQuestion`: "Which epic would you like to break into stories?"
   with the 2 epics (and their status) as options
4. Decomposes only the epic the user picks

**Assertions:**
- [ ] Skill asks "Which epic would you like to break into stories?" rather than erroring
- [ ] Both epics from the glob are offered as options
- [ ] No story files are written before the user picks
- [ ] Skill does NOT silently pick an epic without user input
- [ ] Skill does NOT take the `minimal` brief-synthesis branch at `standard`

**Fixture (no epics):**
- `project.yaml`: `modes.workflow: standard`
- `production/epics/` holds no `EPIC.md`

**Expected behavior (no epics):**
1. The glob returns nothing, so the skill stops: "No epics found under
   `production/epics/`. Run `/create-epics layer: foundation` first — an epic is
   what this skill decomposes."

**Assertions (no epics):**
- [ ] No "Which epic…" question is asked with an empty option list
- [ ] The stop names `/create-epics` and nothing is written

---

### Case 5: Director Gate — Full mode, one story returns GAPS from QL-STORY-READY

**Fixture:**
- `project.yaml`: `modes.workflow: full`, `modes.review_mode: full`,
  `modes.story_granularity: fine`
- EPIC.md exists with 2 requirements, one acceptance criterion each; both
  governing ADRs Accepted
- QL-STORY-READY returns ADEQUATE for story 1 and GAPS for story 2 (one vague
  acceptance criterion)
- At the GAPS question the user picks `Revise flagged criteria`

**Input:** `/create-stories [epic-slug]`

**Expected behavior:**
1. Both stories are decomposed
2. `qa-lead` is spawned once with QL-STORY-READY for the whole story list
3. The assessment is presented: story 1 ADEQUATE with its test-case specs; story 2
   GAPS naming the vague criterion
4. `AskUserQuestion` for story 2: `Revise flagged criteria` / `Accept and proceed`
   / `Discuss further`
5. On Revise: story 2's revised criteria are drafted and shown; specs for story 2
   alone are re-requested in one follow-up call
6. Once both are ADEQUATE, the story list is presented and the single write ask is
   made; each story's QA Test Cases section holds the qa-lead specs

**Assertions:**
- [ ] `qa-lead` is spawned once for all stories (not once per story, and not a second time for story 1's specs); the only follow-up call covers story 2 alone
- [ ] Per-story verdicts use ADEQUATE / GAPS / INADEQUATE and name the failing criterion
- [ ] The GAPS verdict goes to the user with the three options — story 2's criteria are not revised before the user chooses
- [ ] Story 2's revised criteria are shown before the write ask; it carries no specs until ADEQUATE
- [ ] Had the user picked `Accept and proceed`, story 2 would be written with its criteria unchanged and its QA Test Cases reading `*Test cases not yet defined — run /qa-plan to generate them.*`
- [ ] Story 1's QA Test Cases section contains Given/When/Then (Logic/Integration) or Setup/Verify/Pass condition (Visual/Feel, UI) blocks from the gate
- [ ] No "QL-STORY-READY skipped" note appears in `full` mode

---

### Case 6: Minimal tier — epic synthesized from the brief, then a return visit

**Fixture:**
- `project.yaml`: `engine.name: Godot`, `engine.version: "4.6"`, and no `modes`
  keys — `modes.rigor` defaults to `minimal`, so `workflow`, `qa.level` and the
  review mode resolve to `minimal` / `minimal` / `solo`
- `design/game-brief.md` with working title "Lantern Keeper", a Player goal & fail
  state, 2 MVP features and a Build order
- `docs/engine-reference/godot/VERSION.md` is absent
- No `production/epics/` directory

**Input:** `/create-stories`

**Expected behavior:**
1. No argument at `minimal` takes Step 2's `minimal` branch and reads the brief;
   nothing stops for the absent GDD, ADRs, control manifest or TR registry
2. Drafts `production/epics/lantern-keeper/EPIC.md` without writing it
3. Notes "QL-STORY-READY skipped — Solo mode."
4. Presents 2 stories, one per MVP feature in Build order, and asks once to write
   them and create `production/epics/lantern-keeper/EPIC.md` (no `index.md` — it
   does not exist)
5. Writes `EPIC.md` and both stories; prints `Epics index not updated:
   production/epics/index.md absent`
6. Recommends `/dev-story [first-story-path]` — no `/story-readiness`, no
   `/sprint-plan` option

**Assertions:**
- [ ] Nothing, `EPIC.md` included, is written before the single write ask, and that ask names `EPIC.md`
- [ ] Each story reads `Requirement: Brief MVP feature N`, `N/A (minimal — no ADRs)` in its ADR fields and `N/A (minimal — no control manifest)` as its Manifest Version
- [ ] Each story's Risk is `NOT ASSESSED (no VERSION.md risk rating)` — never a guessed level
- [ ] Each QA Test Cases section reads the "N/A — no qa-lead specs at this tier…" line
- [ ] The index line names `production/epics/index.md`, not the systems index

**Fixture (return visit):**
- As above after that run: `production/epics/lantern-keeper/` holds `EPIC.md` (a
  2-row Stories table), `story-001-…` and `story-002-…`; the brief now lists a 3rd
  MVP feature

**Expected behavior (return visit):**
1. Reads the existing stories and `EPIC.md`; drafts one story for the new feature
2. Asks once, naming the new story and the `EPIC.md` update; writes
   `story-003-[slug].md` and appends one row to the Stories table

**Assertions (return visit):**
- [ ] `story-001` and `story-002` are unchanged
- [ ] The new story is numbered 003, on from the highest existing number
- [ ] `EPIC.md` keeps its two rows and every other section; exactly one row is appended

**Fixture (an `EPIC.md` with no stories yet):**
- As the first fixture, but `/create-epics` was run anyway, so
  `production/epics/lantern-keeper/EPIC.md` exists (scope from the brief, Stories
  "Not yet created") and the folder holds no story files

**Expected behavior (an `EPIC.md` with no stories yet):**
1. The existing `EPIC.md` is the epic: no new one is drafted from the brief
2. The write ask names the 2 stories and says *update* `EPIC.md`, not *create*

**Assertions (an `EPIC.md` with no stories yet):**
- [ ] Every section of the existing `EPIC.md` other than its Stories table is unchanged
- [ ] The Step 5 ask says *update* `EPIC.md`

---

## Protocol Compliance

- [ ] All context (EPIC, GDD, ADRs, manifest layer rules, TR registry entries) loaded before drafting stories
- [ ] Story list shown in full before the "May I write" ask
- [ ] "May I write" asked once for the full story set, not once per story, naming every file it touches (stories, `EPIC.md`, `production/epics/index.md` when present)
- [ ] Blocked stories flagged before write approval — not discovered after writing
- [ ] TR-IDs reference the registry — requirement text is not embedded inline in story files
- [ ] Control manifest rules quoted per-story from the manifest, not invented
- [ ] Ends with next-step handoff: `/story-readiness` → `/dev-story` (`/dev-story` directly at `minimal`)

---

## Coverage Notes

- At `minimal`, the "run `/brainstorm` first" stop when no brief exists and a named
  epic slug that does not exist (the `minimal` branch is taken instead of
  `/create-epics`) are not given fixtures.
- The `full` missing-ADR-file stop and the `standard` critical/non-critical ADR
  split are not separately tested.
- INADEQUATE (the story is revised with the user, or dropped and named) and a
  NOT ASSESSED gate answer are not given fixtures.
- Integration story test evidence (playtest doc alternative) follows the same
  approval pattern as Logic stories — not independently fixture-tested.
- Story sizing is pinned to `fine` in Cases 1, 3 and 5 so the story counts are
  determinate; `coarse` and `balanced` grouping, and prose depth per
  `docs.density`, are not fixture-locked.
- The existing-QA-plan substitution prompt (Use QA-plan specs / Use qa-lead specs /
  Skip) is not tested.
