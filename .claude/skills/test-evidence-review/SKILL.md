---
name: test-evidence-review
description: "Quality review of test files and evidence — goes beyond existence, evaluates assertion coverage. ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED per story."
argument-hint: "[story-path | sprint | system-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/test-evidence-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`qa.level` and `testing.strict`** (resolved above) decide what this review may
call a blocker — the same rules `/story-done` closes stories by, so a BLOCKING
item here is one that would stop `/story-done`:
- **`qa.level: minimal`** waives tests. A Logic, Integration or Config/Data story
  with no test evidence (for Config/Data, no smoke report) is
  `WAIVED (qa.level: minimal)` — not MISSING — and raises no BLOCKING item; a
  test that does exist is still reviewed, but its gaps are ADVISORY. Visual/Feel and UI evidence (the retained screenshots, and the
  Visual/Feel sign-off) is never waived.
- **Gate level per story type**: take `testing.strict.<type>` from the resolved
  block (Logic→`logic`, Integration→`integration`, Visual/Feel→`visual`,
  UI→`ui`, Config/Data→`config`): `true` → BLOCKING, `false` → ADVISORY, `unset`
  → a plain-boolean `testing.strict: true|false` (legacy form) applies to every
  type; else the Default Gate Level in `.claude/docs/coding-standards.md`
  (BLOCKING for Logic, Integration, Visual/Feel and UI; ADVISORY for
  Config/Data). Every "BLOCKING" below means that story type's gate level.

# Test Evidence Review

`/smoke-check` verifies that test files **exist** and **pass**. This skill
goes further — it reviews the **quality** of those tests and evidence documents.
A test file that exists and passes may still leave critical behaviour uncovered.
A manual evidence doc that exists may lack the sign-offs required for closure.

**Output:** Summary report (in conversation) + optional `production/qa/evidence-review-[date].md`

**When to run:**
- Before QA hand-off sign-off (`/team-qa` Phase 5)
- On any story where test quality is in question
- As part of milestone review for Logic and Integration story quality audit

---

## 1. Parse Arguments

**Modes:**
- `/test-evidence-review [story-path]` — review a single story's evidence
- `/test-evidence-review sprint` — review all stories in the current sprint
- `/test-evidence-review [system-name]` — review all stories in an epic/system
- No argument — ask which scope: "Single story", "Current sprint", "A system"

---

## 2. Load Stories in Scope

Based on the argument:

**Single story**: Read the story file directly. Extract: Story Type, Test
Evidence section, story slug, system name.

**Sprint**: Read the most recently modified file in `production/sprints/`; extract
the list of story file paths from the sprint plan.

**System**: Glob `production/epics/[system-name]/story-*.md`.

> **If the resolved scope contains ZERO stories, stop here.** Report
> `NOT ASSESSED — no stories in scope`, name which scope was searched and which
> path was empty, and route: no sprint file → `/sprint-plan new` (at `workflow: minimal`,
> which has no sprints, `/test-evidence-review [epic-slug]` instead); a sprint plan
> listing no stories → `/create-stories [epic-slug]`; a `[system-name]` glob that
> matched nothing → name the glob. Do not continue to Section 3.
>
> **Guard the empty scope, not just the per-story unknown.** The verdict
> vocabulary here — ADEQUATE / INCOMPLETE / MISSING — needs a "could not check"
> value, or an unverifiable story acquires a verdict claiming somebody verified
> it; that is what `NOT ASSESSED` is for. **But giving the per-story unknown a
> home does nothing for the empty-scope unknown.** With no stories
> the Section 6 report renders an empty Summary table and ends
> `BLOCKING items: 0 / ADVISORY items: 0` — which reads as *everything reviewed,
> all fine*. This skill gates story closure, and `coding-standards.md` marks Logic,
> Integration, Visual/Feel and UI evidence BLOCKING, so a false-clean closes stories nobody
> reviewed.
>
> This is a recurring shape: the sophisticated inner rule present, the outer
> boundary unguarded. Ask it of any skill that aggregates —
> **what does this emit when the set is empty?**

For the resulting story set, collect the fields below with **targeted section
greps, not a full read of each story**:
```
Grep pattern="## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 8
Grep pattern="## Acceptance Criteria" glob="production/epics/**/story-*.md" output_mode="content" -A 15
```
- **Story Type** (Logic / Integration / Visual/Feel / UI / Config/Data) and the
  stated evidence path — both live under `## Test Evidence`, so the first grep's
  `-A 8` captures them.
- Acceptance Criteria list — the `## Acceptance Criteria` block from the second grep.
- Story slug (from the file name) and System (from the directory path) — no read.
Full-read a story only when its Test Evidence section is missing or ambiguous.
(In Sprint mode, scope the globs to the sprint plan's story paths.)

---

## 3. Locate Evidence Files

For each story, find the evidence. **Check the story's stated evidence path first**
— the one Section 2 captured from its `## Test Evidence` section. If it exists, use
it. Fall back to searching only when no path is stated or it is not found:

**Logic stories**: search the engine's unit-test root — `tests/unit/[system]/`
(Godot), `Assets/Tests/EditMode/` (Unity), `Source/<Module>/Private/Tests/`
(Unreal); see `.claude/docs/directory-structure.md` — for a file whose name
contains the story slug or its system. Test files are named per
`.claude/rules/test-standards.md`, not necessarily `[story-slug]_test.*`.

**Integration stories**: the same, under the integration root (`tests/integration/[system]/`,
`Assets/Tests/PlayMode/`, or Unreal's test root)
  - Also check `production/session-logs/` for playtest records mentioning the story

**Visual/Feel and UI stories**: Glob `production/qa/evidence/` for a retained image
(`*.png`, `*.jpg`, `*.gif`) belonging to this story, and for
`[story-slug]-evidence.*`

**Config/Data stories**: Glob `production/qa/smoke-*.md` (any smoke check report)

Note what was found (path) or not found (gap) for each story.

---

## 4. Review Automated Test Quality (Logic / Integration)

For each test file found, read it and evaluate:

### Assertion coverage

Count the number of distinct assertions (lines containing assert, expect,
check, verify, or engine-specific assertion patterns). Low assertion count is
a quality signal — a test that makes only 1 assertion per test function may
not cover the range of expected behaviour.

Thresholds:
- **3+ assertions per test function** → normal
- **1-2 assertions per test function** → note as potentially thin
- **0 assertions** (test exists but no asserts) → flag as BLOCKING (the story
  type's gate level; ADVISORY at `qa.level: minimal`) — the test passes
  vacuously and proves nothing

### Edge case coverage

For each acceptance criterion in the story that contains a number, threshold,
or "when X happens" conditional: check whether a test function name or
test body references that specific case.

Heuristics:
- Grep test file for "zero", "max", "null", "empty", "min", "invalid",
  "boundary", "edge" — presence of any is a positive signal
- If the story has a Formulas section with specific bounds: check whether
  tests exercise at minimum/maximum values

### Naming quality

Test function names should describe: the scenario + the expected result.
Pattern per engine (`.claude/rules/test-standards.md`): Godot
`test_[scenario]_[expected]`, Unity `[Scenario]_[Expected]`, Unreal
`<Project>.[System].[Scenario]`.

Flag functions named generically (`test_1`, `test_run`, `testBasic`) as
**naming issues** — they make failures harder to diagnose.

### Formula traceability

For Logic stories where the GDD has a Formulas section: check that the test
file contains at least one test whose name or comment references the formula
name or a formula value. A test that exercises a formula without mentioning
it by name is harder to maintain when the formula changes.

---

## 5. Review Manual Evidence Quality (Visual/Feel / UI)

For each evidence document found, read it and evaluate the checks below.

**A UI story needs no evidence document.** When it has none, its retained
screenshots are the evidence: apply only Screenshot / artefact completeness (an
image of each screen the story changes — a screen a criterion only navigates to,
such as the title screen after Quit, needs none of its own) and Date coverage (the images'
dates). A UI story is ADEQUATE on those two — never INCOMPLETE for lacking a doc,
its criterion linkage or a sign-off.

### Criterion linkage

The evidence doc should reference each acceptance criterion from the story.
Check: does the evidence doc contain each criterion (or a clear rephrasing)?
Missing criteria mean a criterion was never verified.

### Sign-off completeness

What closes the story follows the evidence table in
`.claude/docs/coding-standards.md` — the same rule `/story-done` applies, at every
`qa.level`:
- **Visual/Feel**: the evidence doc (from the test-evidence template) must have
  every sign-off row `[x] Approved`. A blank or missing row is INCOMPLETE.
- **UI**: no sign-off is required — the retained screenshots close it. Note a
  sign-off if one exists; never mark a UI story INCOMPLETE for lacking one.

### Screenshot / artefact completeness

For Visual/Feel stories: Glob `production/qa/evidence/` for a retained image
(`*.png`, `*.jpg`, `*.gif`) belonging to this story. A doc that describes a
visual check but retains no image is INCOMPLETE — this gate is BLOCKING by
default, and a description is an assertion rather than evidence.

For UI stories: require the same retained screenshot of each screen touched.
A walkthrough log is welcome but not required.

### Date coverage

Evidence doc should have a date. If the date is earlier than the story's
last major change (heuristic: compare against sprint start date from the sprint
plan), flag as POTENTIALLY STALE — the evidence may not cover the final
implementation.

---

## 6. Build the Review Report

For each story, assign a verdict:

| Verdict | Meaning |
|---------|---------|
| **ADEQUATE** | Test/evidence exists, passes quality checks, all criteria covered |
| **INCOMPLETE** | Test/evidence exists but has quality gaps (thin assertions, missing sign-offs) |
| **MISSING** | No test or evidence found for a story type that requires it at this `qa.level` |
| **NOT ASSESSED** | The review could not be performed for this story — see below |
| **WAIVED (qa.level: minimal)** | A Logic, Integration or Config/Data story with no test evidence at `qa.level: minimal` — tests are not required, so nothing is missing; name it as waived |

> **`NOT ASSESSED` is required, and it is not a softer `MISSING`.**
> The other three verdicts all presume the review actually ran. `MISSING` means
> *I looked and there was nothing there* — a real, reportable failure. It must
> never be used for *I could not look*, which is not a finding about the story
> at all. Use `NOT ASSESSED` when:
>
> - the story's **type cannot be determined**, so the required evidence is
>   unknown (the type→evidence mapping in `.claude/docs/coding-standards.md` is
>   what makes any other verdict meaningful);
> - the evidence path is named but **unreadable or outside this run's scope**;
> - the story file itself could not be parsed.
>
> **Say which of those it was, per story.** A reader cannot act on a bare
> `NOT ASSESSED`, and the whole point of separating it from `MISSING` is that
> the two have different fixes: one needs a test written, the other needs the
> reviewer given access or the story classified.

The overall sprint/system verdict is the worst story verdict present, and
**`NOT ASSESSED` outranks `ADEQUATE`**: a run that could not assess part of its
scope has not established that the scope is adequate. It does not outrank
`INCOMPLETE` or `MISSING` — a known failure is more actionable than an unknown,
and demoting a real failure behind an access problem would bury it. `WAIVED`
ranks below `ADEQUATE`: the overall verdict reads WAIVED only when every story
in scope was waived, and the report names each waived story either way.

> Why this needed saying: evidence review **gates story completion**, and
> `coding-standards.md` makes Logic, Integration, Visual/Feel and UI evidence BLOCKING. A verdict
> vocabulary with no way to express "I could not check" forces every unknown
> into one of three claims about the story — which is how a story nobody
> verified acquires a verdict that says somebody did.

```markdown
## Test Evidence Review

> **Date**: [date]
> **Scope**: [single story path | Sprint [N] | [system name]]
> **Stories reviewed**: [N]
> **Overall verdict**: ADEQUATE / INCOMPLETE / MISSING / NOT ASSESSED / WAIVED
> **qa.level**: [minimal | standard | full] — **testing.strict**: [the resolved per-type values, or "unset — coding-standards.md defaults"]

---

### Story-by-Story Results

#### [Story Title] — [Type] — [ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED/WAIVED]

**Test/evidence path**: `[path]` (found) / (not found)

**Automated test quality** *(Logic/Integration only)*:
- Assertion coverage: [N per function on average] — [adequate / thin / none]
- Edge cases: [covered / partial / not found]
- Naming: [consistent / [N] generic names flagged]
- Formula traceability: [yes / no — formula names not referenced in tests]

**Manual evidence quality** *(Visual/Feel/UI only)*:
- Criterion linkage: [N/M criteria referenced]
- Lead sign-off: [✓ approved | ✗ missing | deferred — reason] *(Visual/Feel only; a UI story needs none)*
- Artefacts: [screenshots present / missing / N/A]
- Freshness: [dated [date] — current / potentially stale]

**Issues**:
- BLOCKING: [description] *(prevents story-done)*
- ADVISORY: [description] *(should fix before release)*

---

### Summary

| Story | Type | Verdict | Issues |
|-------|------|---------|--------|
| [title] | Logic | ADEQUATE | None |
| [title] | Integration | INCOMPLETE | Thin assertions (avg 1.2/function) |
| [title] | Visual/Feel | INCOMPLETE | Lead sign-off missing |
| [title] | Logic | MISSING | No test file found |
| [title] | Logic | WAIVED | No test — waived at `qa.level: minimal` |

**BLOCKING items** (must resolve before story can be closed): [N]
**ADVISORY items** (should address before release): [N]
```

---

## 7. Write Output (Optional)

Present the report in conversation.

Ask: "May I write this test evidence review to
`production/qa/evidence-review-[date].md`?"

This is optional — the report is useful standalone. Write only if the user
wants a persistent record.

After the report:

- For BLOCKING items: "These must be resolved before `/story-done` can mark the
  story Complete. Would you like to address any of them now?"
- For thin assertions: "Consider running `/test-helpers [system]` to see
  scaffolded assertion patterns for common cases."
- For missing sign-offs: "Manual sign-off is required from [role]. Share
  `[evidence-path]` with them to complete sign-off."

Verdict: **COMPLETE** — evidence review finished. Use CONCERNS if BLOCKING items were found.

---

## Collaborative Protocol

- **Report quality issues, do not fix them** — this skill reads and evaluates;
  it does not modify test files or evidence documents
- **ADEQUATE means adequate for shipping, not perfect** — avoid nitpicking
  tests that are functioning and comprehensive enough to give confidence
- **BLOCKING vs. ADVISORY distinction is important** — only flag BLOCKING when
  the gap leaves a story criterion genuinely unverified
- **Ask before writing** — the report file is optional; always confirm before writing
