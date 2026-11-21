---
name: code-review
description: "Architectural review of written code: coding standards, SOLID, testability, performance."
argument-hint: "[path-to-file-or-directory]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Agent, AskUserQuestion, Bash(bash "*/.claude/skills/code-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

# Code Review



Every question follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 1: Load Target Files

Read the target file(s) in full. Read CLAUDE.md for project coding standards.

---

## Phase 2: Identify Engine Specialists

Read the `specialists` block from `project.yaml`; if it is absent, fall back to the `## Engine Specialists` section of `.claude/docs/technical-preferences.md`. Note:

- The **Primary** specialist — `<engine>-specialist` derived from `engine.name` (Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`, Web→`lead-programmer`); used for architecture and broad engine concerns
- The **Language/Code Specialist** — `specialists.code` — used when reviewing the project's primary language files
- The **Shader Specialist** — `specialists.shader` — used when reviewing shader files
- The **UI Specialist** — `specialists.ui` — used when reviewing UI code

**A value of `null` means UNSET — treat that key as absent and skip its
specialist. Never start it as an agent name.** The v1.0 migration writes `null`
for any specialist the legacy file did not name, and it writes the whole block
whenever *one* member is set — so a project that configured only its code
specialist carries `shader: null` and `ui: null`. The config reader returns the
four-character string `"null"` for these, which is not empty and therefore reads
as configured. `null`, empty, and missing are the same state here.

If no engine is configured (no `engine.name` in `project.yaml`, and `technical-preferences.md` reads `[TO BE CONFIGURED]` or is missing), skip engine specialist steps. **Record ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.

---

## Phase 3: ADR Compliance Check

**Argument:** `/code-review [file(s)]` may optionally include a story file path as the last argument (e.g., `/code-review Assets/Scripts/Combat/Attack.cs production/epics/combat/story-001.md`). If a story path is provided, read it to extract the governing ADR reference.

Search for ADR references in, in priority order:
1. The story file (if provided as argument)
2. Header comments at the top of the implementation files
3. Commit messages referencing these files (`git log --oneline -- [file]`)

Look for patterns like `ADR-NNNN` or `docs/architecture/adr-` (either case).

If no ADR references found, note: "No ADR references found — ADR compliance check skipped. For full ADR compliance review, provide the story path: `/code-review [files] [story-path]`."

For each referenced ADR, load **only the sections this check needs — never an unbounded full read.** A substantial ADR exceeds the 25k-token read cap, and a capped read's only recovery is paging the remainder — the most expensive way to read a file. Use the same pattern as `/dev-story` and `/create-stories`:

1. **Map the headings** (cheap — line numbers only): grep the ADR for `^## ` with line numbers
2. **Bounded-read only `## Decision` and `## Consequences`**, using the line numbers to set offset-and-limit read spans that end where the next heading begins. If the heading map is empty (a nonstandard ADR predating the template), fall back to one full read; if that truncates at the cap, grep for the decision/consequence content directly rather than paging the remainder.

A referenced ADR whose file is missing, or that cannot be read, makes ADR
Compliance `NOT ASSESSED — [ADR] could not be read`: name it. No reference at
all is `NO ADRS FOUND`, a different result.

From those two sections, classify any deviation:

- **ARCHITECTURAL VIOLATION** (BLOCKING): Uses a pattern explicitly rejected in the ADR
- **ADR DRIFT** (WARNING): Meaningfully diverges from the chosen approach without using a forbidden pattern
- **MINOR DEVIATION** (INFO): Small difference from ADR guidance that doesn't affect overall architecture

---

## Phase 4: Standards Compliance

Identify the system category (engine, gameplay, AI, networking, UI, tools) and evaluate:

- [ ] Public methods and classes have doc comments
- [ ] Cyclomatic complexity under 10 per method
- [ ] No method exceeds 40 lines (excluding data declarations)
- [ ] Dependencies are injected (no static singletons for game state)
- [ ] Configuration values loaded from data files
- [ ] Systems expose interfaces (not concrete class dependencies)

---

## Phase 5: Architecture and SOLID

**Architecture:**
- [ ] Correct dependency direction (engine <- gameplay, not reverse)
- [ ] No circular dependencies between modules
- [ ] Proper layer separation (UI does not own game state)
- [ ] Events/signals used for cross-system communication
- [ ] Consistent with established patterns in the codebase

**SOLID:**
- [ ] Single Responsibility: Each class has one reason to change
- [ ] Open/Closed: Extendable without modification
- [ ] Liskov Substitution: Subtypes substitutable for base types
- [ ] Interface Segregation: No fat interfaces
- [ ] Dependency Inversion: Depends on abstractions, not concretions

---

## Phase 6: Game-Specific Concerns

- [ ] Frame-rate independence (delta time usage)
- [ ] No allocations in hot paths (update loops)
- [ ] Proper null/empty state handling
- [ ] Thread safety where required
- [ ] Resource cleanup (no leaks)

---

## Phase 7: Engine Review and Testability

This phase starts **one** helper agent at most: the engine reviewer below.
Testability is yours; never start `qa-tester` or a second specialist.

### Engine review (one fresh-context helper)

If an engine is configured, start **one** helper agent of the Primary
specialist's type from Phase 2. It reviews in a context that did not write the
code; that is why it stays a helper. Its brief names, as fields:

- `files`: every file under review, each with its type (code, shader, UI, engine architecture)
- `lens`: this skill's `references/lens-engine.md` as a full path (the base
  directory this skill was started with, then that path), and the configured
  specialists whose blocks apply (`specialists.code`, `.shader`, `.ui`; a `null`
  one is left out and its files go to the Primary block). The helper reads the
  lens file: do not load it here
- `engine`: `engine.name` and `engine.version`
- `return`: `helper-result/1` — `status` (done / blocked / not_assessed),
  `conclusion`, `evidence` (one entry per finding: file:line, quoted code,
  why), `actions_taken` (empty: it writes nothing), `confidence`, `caveats`

Check the result has those fields before reading it; an empty or malformed
result means the engine review did not run.

> **Verify every engine finding before reporting it. Do not pass findings
> through unchecked.** For each finding, record in the report:
>
> - **File and line** it refers to.
> - **Evidence** — the quoted code, or the concrete input/state that triggers it.
> - **Confidence** — `VERIFIED` (you checked it yourself) or `UNVERIFIED —
>   reviewer claim` (you could not).
>
> A finding you could not verify is reported as unverified or dropped, never
> promoted to a defect on the strength of confident phrasing.
>
> **Why this is mandatory.** Reviewers are reliable when deriving and unreliable when
> diagnosing existing code: a **wrong** claim about a short function can be fluent
> enough to pass a skim, and a claimed bug can fall apart once you enumerate the
> inputs.

### Testability (you do this yourself)

For Logic and Integration stories, check the implementation against the story's
`## QA Test Cases` and `## Acceptance Criteria`:
- [ ] Are all test hooks and interfaces exposed (not hidden behind private/internal access)? Name the method a test would need and where it is hidden.
- [ ] Does each QA test case map to a testable code path? Name any that does not.
- [ ] Are any acceptance criteria untestable as implemented (e.g., hardcoded values, no seam for injection)?
- [ ] Does the implementation introduce edge cases the QA test cases do not cover?
- [ ] Are there observable side effects that should have a test but don't?

For Visual/Feel and UI stories: check that the manual verification steps in
`## QA Test Cases` are achievable with the implementation as written — for each
step, is the state the manual checker needs to reach actually reachable, and how?

---

## Phase 8: Output Review

```
## Code Review: [File/System Name]

### Engine Specialist Findings: [N/A — no engine configured / CLEAN / ISSUES FOUND]
[Findings from the engine review, or "No engine configured." if skipped]

### Testability: [N/A — no story path given / N/A — Visual/Feel or Config story / TESTABLE / GAPS / BLOCKING]
[Testability findings: test hooks, coverage gaps, untestable paths, new edge cases]
[If BLOCKING: implementation must expose [X] before tests in ## QA Test Cases can run]

### ADR Compliance: [NOT ASSESSED / NO ADRS FOUND / COMPLIANT / DRIFT / VIOLATION]
[List each ADR checked, result, and any deviations with severity]

### Standards Compliance: [X/6 passing]
[List failures with line references; a missing doc comment names the method or class]

### Architecture: [NOT ASSESSED / CLEAN / MINOR ISSUES / VIOLATIONS FOUND]
[List specific architectural concerns]

### SOLID: [NOT ASSESSED / COMPLIANT / ISSUES FOUND]
[List specific violations]

### Game-Specific Concerns
[List game development specific issues]

### Positive Observations
[What is done well -- always include this section]

### Required Changes
[Must-fix items before approval — ARCHITECTURAL VIOLATIONs always appear here]

### Suggestions
[Nice-to-have improvements]

### Verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]
```

Choose the verdict, first match wins:
- **CHANGES REQUIRED** — anything under Required Changes
- **NOT ASSESSED** — nothing to review (the no-data path above), the engine
  specialist review did not run — no engine configured, or an engine helper
  result that was empty or malformed — or any report section reads `NOT ASSESSED` (ADR
  Compliance with a referenced ADR that could not be read, Architecture, SOLID);
  name which. NOT ASSESSED ranks below CHANGES REQUIRED, because a known
  defect is more actionable than a skipped check, and above both approvals: a
  review that skipped the engine check has not approved the code. (`NO ADRS
  FOUND` is not NOT ASSESSED: with no ADR to check, it does not stop an
  approval.)
- **APPROVED WITH SUGGESTIONS** — only Suggestions
- **APPROVED** — no required changes and no suggestions

This skill is read-only — no files are written.

---

## Phase 9: Next Steps

Ask:
- Prompt: "Code review complete — verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]. How would you like to proceed?" (the Phase 8 verdict, word for word)
- Options (adjust based on verdict):
  - If APPROVED:
    - `[A] Run /story-done to mark the story complete`
    - `[B] Stop here`
  - If APPROVED WITH SUGGESTIONS:
    - `[A] Apply the suggestions, then run /story-done`
    - `[B] Run /story-done now — suggestions noted for later`
    - `[C] Stop here`
  - If CHANGES REQUIRED:
    - `[A] Fix the issues and re-run /code-review`
    - `[B] Run /story-done anyway with noted exceptions`
    - `[C] Stop here`
  - If NOT ASSESSED:
    - `[A] Fix what stopped the review (point me at the code, run /setup-engine, or fix the unreadable ADR reference), then re-run /code-review`
    - `[B] Stop here`

If an ARCHITECTURAL VIOLATION is found:
- If the violation contradicts an **existing ADR**: fix the implementation to comply with `docs/architecture/[adr-file].md`. If the design has legitimately changed, run `/architecture-decision` to formally *revise* the existing ADR — do not create a competing one.
- If **no ADR exists** for the pattern that was violated: run `/architecture-decision` to document the correct approach before fixing the code.
