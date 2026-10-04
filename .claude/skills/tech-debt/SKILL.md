---
name: tech-debt
description: "Track, categorize and prioritize technical debt across the codebase — scans for debt indicators, maintains a register."
argument-hint: "[scan|add|prioritize|report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/tech-debt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`



Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Phase 1: Parse Subcommand

Determine the mode from the argument:

- `scan` — Scan the codebase for tech debt indicators
- `add` — Add a new tech debt entry manually
- `prioritize` — Re-prioritize the existing debt register
- `report` — Generate a summary report of current debt status

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.

---

## Phase 2A: Scan Mode

Search the **code root** (resolve per `.claude/docs/code-root-resolution.md`:
`src/`, `Assets/` or `Source/` by engine) for debt indicators:

- `TODO` comments (count and categorize)
- `FIXME` comments (these are bugs disguised as debt)
- `HACK` comments (workarounds that need proper solutions)
- `@deprecated` markers
- Duplicated code blocks (similar patterns in multiple files)
- Files over 500 lines (potential god objects)
- Functions over 50 lines (potential complexity)

Categorize each finding:

- **Architecture Debt**: Wrong abstractions, missing patterns, coupling issues
- **Code Quality Debt**: Duplication, complexity, naming, missing types
- **Test Debt**: Missing tests, flaky tests, untested edge cases
- **Documentation Debt**: Missing docs, outdated docs, undocumented APIs
- **Dependency Debt**: Outdated packages, deprecated APIs, version conflicts
- **Performance Debt**: Known slow paths, unoptimized queries, memory issues

**Before presenting anything, establish that there was something to scan.**
Count the source files the scan actually covered. If the code root is
unresolved, report `NOT ASSESSED — code root unresolved` and stop as below. If
that count is **zero** — the code root is absent, or holds no source files — report:

> **NOT ASSESSED — no source files to scan.** The code root contains no code, so
> "no debt indicators found" would be a statement about an empty search, not
> about the codebase. Run this once implementation is under way.

and stop. Do not write to the register and do not emit a COMPLETE verdict.

The distinction is the whole point of the scan: **zero findings over 400 files
is a clean codebase; zero findings over zero files is no information at all.**
Rendering both as "COMPLETE — scan findings written to register" reads as the
first. State the denominator whenever findings are reported,
including when it is large and the count is genuinely zero.

Present the findings to the user.

Ask: "May I write these findings to `docs/tech-debt-register.md`?"

If yes, update the register, never overwriting it. **Match before appending:** a
finding with the same file and the same kind of debt as an existing `Open` entry
updates that entry instead of adding a duplicate. An existing `Open` entry whose
pattern is no longer in its file is proposed as `Resolved [date]` — list those and
include them in the same approval. Verdict: **COMPLETE** — scan findings written to register.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2B: Add Mode

Ask the user for the description and affected files (plain text prompts).

Then use `AskUserQuestion` to collect the **category**:
- Prompt: "What category does this tech debt belong to?"
- Options:
  - `[A] Architecture Debt — wrong abstractions, missing patterns, coupling issues`
  - `[B] Code Quality Debt — duplication, complexity, naming, missing types`
  - `[C] Test Debt — missing tests, flaky tests, untested edge cases`
  - `[D] Documentation Debt — missing/outdated docs, undocumented APIs`
  - `[E] Dependency Debt — outdated packages, deprecated APIs, version conflicts`
  - `[F] Performance Debt — known slow paths, memory issues, unoptimized queries`

Then use `AskUserQuestion` to collect the **estimated fix effort**:
- Prompt: "What is the estimated effort to fix this item?"
- Options:
  - `[A] S — Small (under 1 day)`
  - `[B] M — Medium (1–3 days)`
  - `[C] L — Large (3–7 days)`
  - `[D] XL — Extra Large (over 1 week)`

Then use `AskUserQuestion` to collect the **impact if left unfixed** — the
register's Impact column, which `/tech-debt prioritize` scores:
- Prompt: "What does this cost if it is never fixed?"
- Options: `[A] Low` / `[B] Med` / `[C] High` / `[D] Critical`

Present the complete new entry to the user.

**Match before appending:** if an existing `Open` entry already has the same
file and the same category, show it to the user and ask whether to update that
entry instead of adding a duplicate.

Ask: "May I append this entry to `docs/tech-debt-register.md`?" (or, on a match,
"May I update the existing entry instead?")

If yes, append the entry (or update the matched one). Verdict: **COMPLETE** — entry added to register.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2C: Prioritize Mode

Read the debt register at `docs/tech-debt-register.md`. If it does not exist:
Verdict: **NOT ASSESSED** — no register at `docs/tech-debt-register.md`; run
`/tech-debt scan` first. Stop.

Score each item from its own columns: `impact ÷ effort`, with Impact `Low` 1,
`Med` 2, `High` 3, `Critical` 4 and Effort `S` 1, `M` 2, `L` 3, `XL` 4, rounded to
one decimal and written to Priority. Higher scores first; ties go to the older
`Added` date. An item whose Impact or Effort is `—` gets no score: list it after
the scored items as "not scored — [column] not judged" rather than guessing one.

Re-sort the register by priority score and recommend which items to include in the next sprint.

Present the re-prioritized register to the user.

Ask: "May I write the re-prioritized register back to `docs/tech-debt-register.md`?"

If yes, write the updated file. Verdict: **COMPLETE** — register re-prioritized and saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2D: Report Mode

Read the debt register. If it does not exist: Verdict: **NOT ASSESSED** — no
register to report on; run `/tech-debt scan` first. Stop.

Generate summary statistics:

- Open items by category, and total estimated fix effort for them
- Items added and items resolved during the current sprint, from each entry's
  `Added` date and its `Resolved [date]` status
- Trending direction (growing / stable / shrinking) — added vs resolved in that window

Flag any items that have been in the register for more than 3 sprints.

Output the report to the user. This mode is read-only — no files are written. Verdict: **COMPLETE** — debt report generated.

---

## Phase 3: Next Steps

- Run `/sprint-plan` to schedule high-priority debt items into the next sprint.
- Run `/tech-debt report` at the start of each sprint to track debt trends over time.

### Debt Register Format

```markdown
## Technical Debt Register
Last updated: [Date]
Total items: [N] | Estimated total effort: [T-shirt sizes summed]

| ID | Category | Description | Files | Effort | Impact | Priority | Status | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|--------|-------|--------|
| TD-001 | [Cat] | [Description] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | [Score] | [Open / Resolved YYYY-MM-DD / Accepted — reason] | [YYYY-MM-DD] | [Sprint to fix or "Backlog"] |
```

Every skill that adds a row — this one, and `/story-done` when it logs
deviations as debt — writes all ten columns in this order, and a skill that
creates the file writes the header and table head above first:

- **ID** — `TD-` and three digits, one above the highest ID already in the
  register (`TD-001` in a new one). IDs are never reused.
- **Category** — one of the six categories under Scan Mode, written without
  "Debt": `Architecture`, `Code Quality`, `Test`, `Documentation`, `Dependency`,
  `Performance` — the spelling `/story-done` writes, so Report Mode groups them once.
- **Description** — what the debt is and why it was taken on.
- **Files** — the affected paths, comma-separated; `—` when the debt has no single file.
- **Effort** — `S`, `M`, `L` or `XL`, as in Add Mode; `—` if not yet estimated.
- **Impact** — `Low`, `Med`, `High` or `Critical`: the cost if left unfixed; `—`
  if not yet judged.
- **Priority** — the score `/tech-debt prioritize` writes; `—` until it runs.
- **Status** — `Open` when added. `Resolved YYYY-MM-DD` records the day the debt
  was fixed; `Accepted — reason` records a conscious decision to keep it.
- **Added** — the day the row was written, `YYYY-MM-DD`. Report Mode counts items
  added and resolved from this date and the `Resolved` date.
- **Sprint** — the sprint scheduled to fix it, or `Backlog`.

### Rules
- Tech debt is not inherently bad — it is a tool. The register tracks conscious decisions.
- Every debt entry must explain WHY it was accepted (deadline, prototype, missing info)
- "Scan" should run at least once per sprint to catch new debt
- Items older than 3 sprints without action should either be fixed or consciously accepted with a documented reason
