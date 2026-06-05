# Skill Test Spec: /create-stories

## Skill Summary

`/create-stories` breaks a single epic into developer-ready story files. It reads
the EPIC.md, the corresponding GDD, governing ADRs, the control manifest, and the
TR registry. Each story gets structured frontmatter including: Title, Epic, Layer,
Priority, Status, TR-ID, ADR references, Acceptance Criteria, and Definition of
Done. Stories are classified by type (Logic / Integration / Visual/Feel / UI /
Config/Data) which determines the required test evidence path.

In `full` review mode, a QL-STORY-READY check runs per story after creation. In
`lean` or `solo` mode, QL-STORY-READY is skipped. The skill asks "May I write"
before writing each story file. Stories are written to
`production/epics/[layer]/story-[name].md`.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, NEEDS WORK
- [ ] Contains "May I write" collaborative protocol language (per-story approval)
- [ ] Has a next-step handoff at the end (`/story-readiness`, `/dev-story`)
- [ ] Documents story Status: Blocked when governing ADR is Proposed
- [ ] Documents QL-STORY-READY gate: active in full mode, skipped in lean/solo
- [ ] Embeds ADR Version from the governing ADR's last commit date so `/dev-story` can detect stale story guidance deterministically

---

## Director Gate Checks

In `full` mode: QL-STORY-READY check runs per story after creation. Stories that
fail the check are noted as NEEDS WORK before the "May I write" ask.

In `lean` mode: QL-STORY-READY is skipped. Output notes:
"QL-STORY-READY skipped — lean mode" per story.

In `solo` mode: QL-STORY-READY is skipped with equivalent notes.

---

## Test Cases

### Case 1: Happy Path — Epic with 3 stories, all ADRs Accepted

**Fixture:**
- `production/epics/[layer]/EPIC-[name].md` exists with 3 GDD requirements
- Corresponding GDD exists with matching acceptance criteria
- All governing ADRs have `Status: Accepted`
- `docs/architecture/control-manifest.md` exists
- `docs/architecture/tr-registry.yaml` has TR-IDs for all 3 requirements
- `production/session-state/review-mode.txt` contains `lean`

**Input:** `/create-stories [epic-name]`

**Expected behavior:**
1. Skill reads EPIC.md, GDD, governing ADRs, control manifest, and TR registry
2. Classifies each requirement into a story type (Logic / Integration / Visual/Feel / UI / Config/Data)
3. Drafts 3 story files with correct frontmatter schema, including ADR Version beside the governing ADR
4. QL-STORY-READY is skipped (lean mode) — noted in output
5. Asks "May I write" before writing each story file
6. Writes all 3 story files after approval

**Assertions:**
- [ ] Each story's frontmatter contains: Title, Epic, Layer, Priority, Status, TR-ID, ADR reference, ADR Version, Acceptance Criteria, DoD
- [ ] Story types are correctly classified (at least one Logic type in fixture)
- [ ] "May I write" is asked per story (not once for the entire batch)
- [ ] QL-STORY-READY skip is noted in output
- [ ] All 3 story files are written with correct naming: `story-[name].md`
- [ ] Skill does NOT start implementation

---

### Case 2: Failure Path — No epic file found

**Fixture:**
- The epic path provided does not exist in `production/epics/`

**Input:** `/create-stories nonexistent-epic`

**Expected behavior:**
1. Skill attempts to read the EPIC.md file
2. File not found
3. Skill outputs a clear error with the path it searched
4. Skill suggests checking `production/epics/` or running `/create-epics` first
5. No story files are created

**Assertions:**
- [ ] Skill outputs a clear error naming the missing file path
- [ ] No story files are written
- [ ] Skill recommends the correct next action (`/create-epics`)
- [ ] Skill does NOT create stories without a valid EPIC.md

---

### Case 3: Blocked Story — ADR is Proposed

**Fixture:**
- EPIC.md exists with 2 requirements
- Requirement 1 is covered by an Accepted ADR
- Requirement 2 is covered by an ADR with `Status: Proposed`

**Input:** `/create-stories [epic-name]`

**Expected behavior:**
1. Skill reads the ADR for Requirement 2 and finds Status: Proposed
2. Story for Requirement 2 is drafted with `Status: Blocked`
3. Blocking note references the specific ADR: "BLOCKED: ADR-NNN is Proposed"
4. Story for Requirement 1 is drafted normally with `Status: Ready`
5. Both stories are shown in the draft — user asked "May I write" for both

**Assertions:**
- [ ] Story 2 has `Status: Blocked` in its frontmatter
- [ ] Blocking note names the specific ADR number and recommends `/architecture-decision`
- [ ] Story 1 has `Status: Ready` — blocked status does not affect non-blocked stories
- [ ] Blocked status is shown in the draft preview before writing
- [ ] Both story files are written (blocked stories are still written — just flagged)

---

### Case 4: Edge Case — No argument provided

**Fixture:**
- `production/epics/` directory exists with ≥2 epic subdirectories

**Input:** `/create-stories` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Outputs a usage error: "No epic specified. Usage: /create-stories [epic-name]"
3. Skill lists available epics from `production/epics/`
4. No story files are created

**Assertions:**
- [ ] Skill outputs a usage error when no argument is given
- [ ] Skill lists available epics to help the user choose
- [ ] No story files are written
- [ ] Skill does NOT silently pick an epic without user input

---

### Case 5: Director Gate — Full mode runs QL-STORY-READY; stories failing noted as NEEDS WORK

**Fixture:**
- EPIC.md exists with 2 requirements
- Both governing ADRs are Accepted
- `production/session-state/review-mode.txt` contains `full`
- QL-STORY-READY check finds one story has ambiguous acceptance criteria

**Input:** `/create-stories [epic-name]`

**Expected behavior:**
1. Both stories are drafted
2. QL-STORY-READY check runs for each story
3. Story 1 passes QL-STORY-READY
4. Story 2 fails QL-STORY-READY — noted as NEEDS WORK with specific feedback
5. Both stories are shown to user with pass/fail status before "May I write"
6. User can proceed (story written as-is with NEEDS WORK note) or revise first

**Assertions:**
- [ ] QL-STORY-READY results appear per story in the output
- [ ] Story 2 is flagged as NEEDS WORK with the specific failing criteria
- [ ] Story 1 shows as passing QL-STORY-READY
- [ ] User is given the choice to proceed or revise before writing
- [ ] Skill does NOT auto-block writing of stories that fail QL-STORY-READY without user input

---

## Protocol Compliance

- [ ] All context (EPIC, GDD, ADRs, manifest, TR registry) loaded before drafting stories
- [ ] Story drafts shown in full before any "May I write" ask
- [ ] "May I write" asked per story (not once for the entire batch)
- [ ] Blocked stories flagged before write approval — not discovered after writing
- [ ] TR-IDs reference the registry — requirement text is not embedded inline in story files
- [ ] ADR Version is embedded from `git log -1 --format=%cs -- [adr-file]` when an ADR governs the story
- [ ] Control manifest rules quoted per-story from the manifest, not invented
- [ ] Ends with next-step handoff: `/story-readiness` → `/dev-story`

---

## Coverage Notes

- Integration story test evidence (playtest doc alternative) follows the same
  approval pattern as Logic stories — not independently fixture-tested.
- Story ordering (foundational first, UI last) is validated implicitly via
  Case 1's multi-story fixture.
- The story sizing rule (splitting large requirement groups) is not tested here
  — it is addressed in the `/create-stories` skill's internal logic.
