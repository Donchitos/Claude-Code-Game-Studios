---
name: tech-debt
description: "Track, categorize and prioritize technical debt across the codebase — scans for debt indicators, maintains a register."
argument-hint: "[scan|add|prioritize|report]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/tech-debt/../../hooks/yaml-helper.sh" resolve_config *)
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

Search the codebase for debt indicators:

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
Count the source files the scan actually covered. If that count is **zero** —
no `src/` directory, or it holds no source files — report:

> **NOT ASSESSED — no source files to scan.** `src/` contains no code, so
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

If yes, update the register (append new entries, do not overwrite existing ones). Verdict: **COMPLETE** — scan findings written to register.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2B: Add Mode

Ask the user for the description, affected files, and impact if left unfixed (plain text prompts).

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

Present the complete new entry to the user.

Ask: "May I append this entry to `docs/tech-debt-register.md`?"

If yes, append the entry. Verdict: **COMPLETE** — entry added to register.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2C: Prioritize Mode

Read the debt register at `docs/tech-debt-register.md`.

Score each item by: `(impact_if_unfixed × frequency_of_encounter) / fix_effort`

Re-sort the register by priority score and recommend which items to include in the next sprint.

Present the re-prioritized register to the user.

Ask: "May I write the re-prioritized register back to `docs/tech-debt-register.md`?"

If yes, write the updated file. Verdict: **COMPLETE** — register re-prioritized and saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 2D: Report Mode

Read the debt register. Generate summary statistics:

- Total items by category
- Total estimated fix effort
- Items added vs resolved since last report
- Trending direction (growing / stable / shrinking)

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

| ID | Category | Description | Files | Effort | Impact | Priority | Added | Sprint |
|----|----------|-------------|-------|--------|--------|----------|-------|--------|
| TD-001 | [Cat] | [Description] | [files] | [S/M/L/XL] | [Low/Med/High/Critical] | [Score] | [Date] | [Sprint to fix or "Backlog"] |
```

### Rules
- Tech debt is not inherently bad — it is a tool. The register tracks conscious decisions.
- Every debt entry must explain WHY it was accepted (deadline, prototype, missing info)
- "Scan" should run at least once per sprint to catch new debt
- Items older than 3 sprints without action should either be fixed or consciously accepted with a documented reason
