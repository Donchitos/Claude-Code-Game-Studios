# Agent Test Spec: qa-tester

## Agent Summary
- **Domain**: Detailed test case authoring, bug reports (structured format), test execution documentation, regression checklists, smoke check execution docs, test evidence recording per the project's coding standards
- **Does NOT own**: Test strategy and test plan design (qa-lead), implementation fixes for found bugs (reported for assignment through qa-lead), severity calls above S2 (qa-lead), QA process architecture (qa-lead)
- **Category**: qa
- **Gate IDs**: None; flags ambiguous acceptance criteria to qa-lead rather than resolving independently

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references test cases, bug reports, test execution, regression testing)
- [ ] `tools:` list is Read, Glob, Grep, Write, Edit, Bash. The grant cannot be path-scoped, so the no-source-edits boundary must be written in the body: "What This Agent Must NOT Do" lists "Fix bugs (report them for assignment)", and the orchestrated-run write exception covers only a new artifact under `production/`, `docs/` or `tests/`, "never an edit to existing source or config"
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over test strategy, fix implementation, or acceptance criterion definition

---

## Test Cases

### Case 1: In-domain request — test cases for a save system
**Input**: "Write test cases for our save system. It must save and load player position, inventory, and quest state."
**Expected behavior**:
- Produces a test case list with at minimum the following test cases, each containing all four required fields:
  - **TC-SAVE-001**: Save and load player position
  - **TC-SAVE-002**: Save and load full inventory (multiple item types, quantities, equipped state)
  - **TC-SAVE-003**: Save and load quest state (in-progress, completed, and locked quest states)
  - **TC-SAVE-004**: Overwrite an existing save file
  - **TC-SAVE-005**: Load a save file from a previous version (backward compatibility)
  - **TC-SAVE-006**: Corrupt save file handling (file exists but is invalid)
- Each test case includes: **Precondition** (required game state before test), **Steps** (numbered, unambiguous), **Expected Result** (specific, observable outcome), **Pass Criteria** (binary pass/fail condition)
- Does NOT write "verify the save works" as a pass criterion — criteria must be observable and unambiguous

### Case 2: Out-of-domain request — implement a bug fix
**Input**: "You found a bug where the save system loses inventory data on version mismatch. Please fix it."
**Expected behavior**:
- Does not produce any implementation code or attempt to fix the save system
- States that it does not fix bugs — it reports them for assignment (its own rule: "Fix bugs (report them for assignment)"), and the report goes up through qa-lead, to whom it reports; it documents the bug and writes the tests that verify the fix
- Offers to produce: (a) a bug report in `/bug-report`'s template — ID `BUG-NNNN`, Severity (`S1-Critical` … `S4-Low`), Priority (`P1-Fix this sprint` … `P4-Won't fix`), `**Status**: Open`, System, Steps to Reproduce, Expected vs. Actual Result — at `production/qa/bugs/BUG-NNNN.md`, (b) a targeted regression checklist or regression test cases for TC-SAVE-005 (version mismatch) that can be run after the fix
- Does not set a severity above S2 itself: if it judges the inventory loss to be S1, it escalates that call to qa-lead ("Make severity judgments above S2 (escalate to qa-lead)")

### Case 3: Ambiguous acceptance criterion — flag to qa-lead
**Input**: "Write test cases for the tutorial. The acceptance criterion in the story says 'tutorial should feel intuitive.'"
**Expected behavior**:
- Identifies "should feel intuitive" as an unmeasurable acceptance criterion — it is a subjective quality statement, not a testable condition
- Does NOT write test cases against an ambiguous criterion by inventing a definition of "intuitive"
- Flags to qa-lead: "The acceptance criterion 'tutorial should feel intuitive' is not testable as written; needs clarification — e.g., 'X% of first-time players complete the tutorial without using the hint button' or 'no tester requires external help to complete the tutorial in session'"
- Provides two or three concrete, measurable alternative criteria for qa-lead to choose between

### Case 4: Regression test after a hotfix
**Input**: "A hotfix was applied that changed how the inventory serialization handles nullable item slots. Write a targeted regression checklist for the affected systems."
**Expected behavior**:
- Identifies the affected systems: inventory save/load, any UI that reads inventory state, any quest system that checks inventory contents, any crafting system that reads inventory slots
- Produces a regression checklist focused on those systems only — not a full game regression
- Checklist items target the specific change: null item slot handling (empty slots, mixed full/empty slot arrays, slot count boundary conditions)
- Each checklist item specifies: what to test, how to verify pass, and what a failure looks like
- Does NOT produce a generic "test everything" checklist — the value of a targeted regression is specificity

### Case 5: Context pass — test evidence format from coding-standards.md
**Input context**: coding-standards.md (imported by CLAUDE.md) specifies: Logic stories require automated unit tests in `tests/unit/[system]/`. Visual/Feel stories require screenshot + lead sign-off in `production/qa/evidence/`. UI stories require a retained screenshot of each screen touched in `production/qa/evidence/`. The project's `project.yaml` sets `qa.level: minimal`.
**Input**: "Write test cases for the inventory UI (a UI story): grid layout, item tooltip display, and drag-and-drop reordering."
**Expected behavior**:
- Classifies this correctly as a UI story per the provided standards
- Produces manual test cases whose evidence is a retained screenshot of each screen touched (not automated unit tests) — because the coding standard specifies screenshots for UI stories
- Specifies the output location: `production/qa/evidence/` (not `tests/unit/`)
- Test cases include: grid layout verification (all items appear, no overflow), tooltip display (correct item name, stats, description appear on hover/focus), and drag-and-drop (item moves to target slot, original slot becomes empty, slot limits respected)
- States the story type (UI), output location and gate level (BLOCKING) at the start of the test cases, as its Test Evidence Routing section requires for every test case it produces
- Does not drop or downgrade the screenshot evidence because the project runs `qa.level: minimal` — coding-standards.md: "Not waived at `qa.level: minimal` — tests are, the look is not"

---

## Protocol Compliance

- [ ] Stays within declared domain (test case authoring, bug reports, test execution documentation, regression checklists)
- [ ] Declines bug fix requests — reports the bug for assignment through qa-lead and offers a bug report plus regression tests, without writing the fix
- [ ] Flags ambiguous acceptance criteria to qa-lead rather than inventing a testable interpretation
- [ ] Produces targeted regression checklists (system-specific) not full-game regression passes
- [ ] Uses the correct test evidence format and output location per coding-standards.md
- [ ] Writes bugs in `/bug-report`'s template (ID `BUG-NNNN`, Severity, Priority, Status, System) — the lines `/bug-triage` parses — never a format of its own
- [ ] Asks "May I write this to [filepath]?" naming the file before writing any test file, test case list or checklist

---

## Coverage Notes
- Case 1 (test case completeness) is the foundational quality test — missing fields (precondition, steps, expected result, pass criteria) are a failure
- Case 3 (ambiguous criterion) is a coordination test — qa-tester must not silently accept untestable criteria
- Case 5 relies on coding-standards.md, which CLAUDE.md imports, so the test evidence table and the `qa.level: minimal` rule are always in the agent's context; the agent must correctly apply evidence type and location
- The ADVISORY vs. BLOCKING gate level (Case 5) is a detail that affects story completion — verify the agent reports it and does not waive visual evidence at `qa.level: minimal`
- No automated runner; review manually or via `/skill-test`
