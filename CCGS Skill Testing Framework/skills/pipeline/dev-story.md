# Skill Test Spec: /dev-story

## Skill Summary

`/dev-story` reads a story file, loads all required context (TR-ID from the
registry, story-embedded ADR guidance, control manifest, engine preferences),
implements the story, verifies that all acceptance criteria are met, and marks
the story Complete. It validates the referenced ADR status with targeted reads,
but does not re-read full ADR files by default when `/create-stories` already
embedded the Decision Summary and Implementation Notes. The skill routes
implementation to the correct specialist agent based on the engine and file
type — it does not write source code directly.

In `full` review mode, an LP-CODE-REVIEW gate runs before marking the story
Complete. In `lean` or `solo` mode, LP-CODE-REVIEW is skipped and the story is
marked Complete after the user confirms all criteria are met. The skill asks
"May I write" before updating story status and before writing code files.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED, IN PROGRESS, NEEDS CHANGES
- [ ] Contains "May I write" collaborative protocol language (story status + code files)
- [ ] Has a next-step handoff at the end (`/story-done`)
- [ ] Documents LP-CODE-REVIEW gate: active in full mode, skipped in lean/solo
- [ ] Notes that implementation is delegated to specialist agents (not done directly)
- [ ] Uses story-embedded ADR Decision Summary / Implementation Notes as the primary implementation brief
- [ ] Avoids full ADR reads by default; uses targeted ADR section reads only for validation or missing/stale guidance
- [ ] Checks story ADR Version against the current ADR last-commit date before trusting embedded ADR guidance

---

## Director Gate Checks

In `full` mode: LP-CODE-REVIEW gate runs after implementation is complete and all
criteria are verified, before marking the story Complete.

In `lean` mode: LP-CODE-REVIEW is skipped. Output notes:
"LP-CODE-REVIEW skipped — lean mode". Story is marked Complete after user confirms.

In `solo` mode: LP-CODE-REVIEW is skipped with equivalent notes.

---

## Test Cases

### Case 1: Happy Path — Story implemented and marked Complete (full mode)

**Fixture:**
- A story file exists at `production/epics/[layer]/story-[name].md` with:
  - `Status: Ready`
  - A TR-ID referencing a registered requirement
  - `ADR Version:` matching the current governing ADR last commit date
  - At least 2 Given-When-Then acceptance criteria
  - A test evidence path
- Referenced ADR has `Status: Accepted`
- `docs/architecture/control-manifest.md` exists
- `.claude/docs/technical-preferences.md` has engine and language configured
- `production/session-state/review-mode.txt` contains `full`

**Input:** `/dev-story production/epics/[layer]/story-[name].md`

**Expected behavior:**
1. Skill reads the story file and all required context
2. Skill verifies the ADR is Accepted using a targeted status read (no block)
3. Skill routes implementation to the correct specialist agent
4. All acceptance criteria are verified as met
5. LP-CODE-REVIEW gate spawns and returns APPROVED
6. Skill asks "May I update story status to Complete?"
7. Story status is updated to Complete

**Assertions:**
- [ ] Skill reads story before spawning any agent
- [ ] ADR status is checked before implementation begins
- [ ] ADR Version is compared against the governing ADR's current last-commit date before embedded guidance is trusted
- [ ] Skill uses the story's embedded ADR Decision Summary and Implementation Notes instead of re-reading the full ADR
- [ ] Implementation is delegated to a specialist agent (not done inline)
- [ ] All acceptance criteria are confirmed before LP-CODE-REVIEW
- [ ] LP-CODE-REVIEW appears in output as a completed gate
- [ ] Story status is updated to Complete only after gate approval and user consent
- [ ] Test file is written as part of implementation (not deferred)

---

### Case 2: Failure Path — Referenced ADR is Proposed

**Fixture:**
- A story file exists with `Status: Ready`
- The story's TR-ID points to a requirement covered by an ADR with `Status: Proposed`

**Input:** `/dev-story production/epics/[layer]/story-[name].md`

**Expected behavior:**
1. Skill reads the story file
2. Skill resolves the TR-ID and reads enough of the governing ADR to verify status
3. ADR status is Proposed — skill outputs a BLOCKED message
4. Skill names the specific ADR blocking the story
5. Skill recommends running `/architecture-decision` to advance the ADR
6. Implementation does NOT begin

**Assertions:**
- [ ] Skill does NOT begin implementation with a Proposed ADR
- [ ] BLOCKED message names the specific ADR number and title
- [ ] Skill recommends `/architecture-decision` as the next action
- [ ] Story status remains unchanged (not set to In Progress or Complete)

---

### Case 3: Ambiguous Acceptance Criteria — Skill asks for clarification

**Fixture:**
- A story file exists with `Status: Ready`
- Referenced ADR is Accepted
- One acceptance criterion is ambiguous (not Given-When-Then; uses subjective language like "feels responsive")

**Input:** `/dev-story production/epics/[layer]/story-[name].md`

**Expected behavior:**
1. Skill reads the story and identifies the ambiguous criterion
2. Before routing to the specialist, skill asks the user to clarify the criterion
3. User provides a concrete, testable restatement
4. Skill proceeds with implementation using the clarified criterion
5. Skill does NOT guess at the intended behavior

**Assertions:**
- [ ] Skill surfaces the ambiguous criterion before implementation starts
- [ ] Skill asks for user clarification (not auto-interpretation)
- [ ] Implementation begins only after clarification is provided
- [ ] Clarified criterion is used in the test (not the original vague version)

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
- [ ] If session state has no active story, skill asks which story to implement

---

### Case 5: Director Gate — LP-CODE-REVIEW returns NEEDS CHANGES; lean mode skips gate

**Fixture (full mode):**
- Story is implemented and all criteria appear met
- `production/session-state/review-mode.txt` contains `full`
- LP-CODE-REVIEW gate returns NEEDS CHANGES with specific feedback

**Full mode expected behavior:**
1. LP-CODE-REVIEW gate spawns after implementation
2. Gate returns NEEDS CHANGES with 2 specific issues
3. Story status remains In Progress — NOT marked Complete
4. User is shown the gate feedback and asked how to proceed

**Assertions (full mode):**
- [ ] Story is NOT marked Complete when LP-CODE-REVIEW returns NEEDS CHANGES
- [ ] Gate feedback is shown to the user verbatim
- [ ] Story status stays In Progress until issues are resolved and gate passes

**Fixture (lean mode):**
- Same story, `production/session-state/review-mode.txt` contains `lean`

**Lean mode expected behavior:**
1. Implementation completes
2. LP-CODE-REVIEW gate is skipped — noted in output
3. User is asked to confirm all criteria are met
4. Story is marked Complete after user confirmation

**Assertions (lean mode):**
- [ ] "LP-CODE-REVIEW skipped — lean mode" appears in output
- [ ] Story is marked Complete after user confirms criteria (no gate required)
- [ ] Skill does NOT block on a gate that is skipped

---

### Case 6: Stale ADR Version - Skill prompts before implementation

**Fixture:**
- Story has `ADR Version: 2026-01-15`
- Governing ADR's current `git log -1 --format=%cs -- [adr-file]` date is `2026-03-10`
- Story has embedded ADR Decision Summary and Implementation Notes

**Input:** `/dev-story production/epics/[layer]/story-[name].md`

**Expected behavior:**
1. Skill reads the story file and detects the ADR Version mismatch
2. Skill asks whether to refresh targeted ADR guidance, proceed with stale guidance, or stop
3. Implementation does NOT begin until the user chooses a path
4. If refresh is chosen, the skill reads only targeted ADR sections and updates embedded story guidance before spawning a programmer

**Assertions:**
- [ ] Skill does not trust matching-looking embedded ADR guidance when ADR Version is stale
- [ ] User is prompted before implementation
- [ ] Refresh path uses targeted ADR section reads, not a full ADR read by default
- [ ] Proceed-with-risk path records an ADR-Version-Note in the story header without rewriting the stale ADR Version

---

## Protocol Compliance

- [ ] Does NOT write source code directly — delegates to specialist agents
- [ ] Reads all context (story, TR-ID, story-embedded ADR guidance, manifest, engine prefs) before implementation
- [ ] Does not perform unbounded full-file ADR reads unless embedded guidance is missing, stale, or ambiguous
- [ ] Verifies ADR Version freshness before relying on story-embedded ADR guidance
- [ ] "May I write" asked before updating story status and before writing code files
- [ ] Skipped gates noted by name and mode in output
- [ ] Updates `production/session-state/active.md` after story completion
- [ ] Ends with next-step handoff: `/story-done`

---

## Coverage Notes

- Engine routing logic (Godot vs Unity vs Unreal) is not tested per engine —
  the routing pattern is consistent; engine selection is a config fact.
- Visual/Feel and UI story types (no automated test required) have different
  evidence requirements and are not covered in these cases.
- Integration story type follows the same pattern as Logic but with a different
  evidence path — not independently fixture-tested.
