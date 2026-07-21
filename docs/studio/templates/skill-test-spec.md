# Skill Test Spec: $skill-name

## Skill Summary

[One paragraph: what this skill does, when to use it, what it produces. Include
the primary output artifact, the verdict format it uses, and which pipeline stage
it belongs to.]

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name` and `description`
- [ ] Has `agents/openai.yaml` with Codex-facing skill interface metadata
- [ ] Has ≥2 phase headings (## Phase N or numbered ## sections)
- [ ] Contains verdict keywords: [list the ones expected, e.g., PASS, FAIL, CONCERNS]
- [ ] Contains "May I write" collaborative protocol language (if skill writes files)
- [ ] Has a next-step handoff at the end

---

## Test Cases

### Case 1: Happy Path — [short description]

**Fixture:** [Describe the assumed project state. Which files exist? What do they
contain? E.g., "game-concept.md exists with all 8 required sections complete.
systems-index.md exists. All MVP GDDs are present and individually reviewed."]

**Input:** `$skill-name [args]`

**Expected behavior:**
1. [Phase 1 action — what the skill should read or check]
2. [Phase 2 action — what the skill should evaluate]
3. [Phase N action — what the skill should output]

**Assertions:**
- [ ] Skill reads [specific file] before producing output
- [ ] Output includes verdict keyword [PASS/FAIL/etc.]
- [ ] Output lists [specific content] from the fixture
- [ ] Skill asks for approval before writing any file

---

### Case 2: Failure Path — [short description, e.g., "Missing required artifact"]

**Fixture:** [Describe the failure state. E.g., "game-concept.md is missing.
No files exist in design/gdd/."]

**Input:** `$skill-name [args]`

**Expected behavior:**
1. [Phase 1: skill detects missing file]
2. [Phase 2: skill surfaces the gap rather than assuming OK]
3. [Output: FAIL or BLOCKED verdict with specific blocker named]

**Assertions:**
- [ ] Skill does NOT output PASS when the fixture is incomplete
- [ ] Skill names the specific missing artifact
- [ ] Skill suggests a remediation action (e.g., "Run /[other-skill]")
- [ ] Skill does not create files to fill in the gap without asking

---

### Case 3: Edge Case — [short description, e.g., "No argument provided"]

**Fixture:** [State of project files for this case]

**Input:** `$skill-name` (no argument)

**Expected behavior:**
1. [What the skill should do when invoked without arguments]

**Assertions:**
- [ ] [assertion]

---

## Protocol Compliance

- [ ] Uses "May I write" before all file writes
- [ ] Presents findings or report before asking for write approval
- [ ] Ends with a recommended next step or follow-up skill
- [ ] Never auto-creates files without explicit user approval
- [ ] Does not skip phases or jump straight to a verdict without checking

---

## Coverage Notes

[Document what is intentionally NOT tested in this spec and why. Examples:
- "Case 3 (all-mode) is not covered because it runs too many checks to evaluate
  in a single spec — test each sub-mode individually."
- "The database integration path is not covered as it requires a live environment."
- "Edge cases involving corrupted YAML files are deferred to a future spec."]
