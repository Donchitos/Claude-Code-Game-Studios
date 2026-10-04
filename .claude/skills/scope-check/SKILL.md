---
name: scope-check
description: "Scope creep check — current scope versus the original plan. Flags additions, quantifies bloat, recommends cuts. 'Any scope creep?'"
argument-hint: "[feature-name or sprint-N]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *)
model: haiku
---

# Scope Check

This skill is read-only — it reports findings but writes no files.

Compares original planned scope against current state to detect, quantify, and triage
scope creep.

**Argument:** `$ARGUMENTS` — the whole string: a feature name (it may be several words), sprint number, or milestone name.

---

## Phase 1: Find the Original Plan

Locate the baseline scope document for the given argument:

- **Feature name** → read `design/gdd/[feature].md` or matching file in `design/`
- **Sprint number** (e.g., `sprint-3`) → read `production/sprints/sprint-003.md` (the name `/sprint-plan` writes) or similar
- **Milestone** → read `production/milestones/[name].md`

If the document is not found, report the missing file and stop. Do not proceed without
a baseline to compare against.

---

## Phase 2: Read the Current State

Check what has actually been implemented or is in progress:

- Scan the codebase for files related to the feature/sprint
- Read git log for commits related to this work (`git log --oneline --since=[start-date]`)
- Check for TODO/FIXME comments that indicate unfinished scope additions
- Check active sprint plan if the feature is mid-sprint

---

## Phase 3: Compare Original vs Current Scope

Produce the comparison report:

```markdown
## Scope Check: [Feature/Sprint Name]
Generated: [Date]

### Original Scope
[List of items from the original plan]

### Current Scope
[List of items currently implemented or in progress]

> **If Phase 4 will return NOT ASSESSED, do not render the numeric block below.**
> Replace the counts and the Bloat Score with
> `[Baseline | Current state] unusable — see verdict` (whichever side could not
> be read) and give the reason. A rendered
> `Original items: 0 / Net scope change: 0%` one section above a NOT ASSESSED
> verdict re-creates the exact "0% reads as on track" hazard Phase 4 exists to
> kill, one phase earlier — and readers trust a number over a caveat.

### Scope Additions (not in original plan)
| Addition | Source | When | Justified? | Effort |
|----------|--------|------|------------|--------|
| [item] | [commit/person] | [date] | [Yes/No/Unclear] | [S/M/L] |

### Scope Removals (in original but dropped)
| Removed Item | Reason | Impact |
|-------------|--------|--------|
| [item] | [why removed] | [what's affected] |

### Bloat Score
- Original items: [N]
- Current items: [N]
- Items added: [N] (+[X]%)
- Items removed: [N]
- Net scope change: [+/-N] ([X]%)

### Risk Assessment
- **Schedule Risk**: [Low/Medium/High] — [explanation]
- **Quality Risk**: [Low/Medium/High] — [explanation]
- **Integration Risk**: [Low/Medium/High] — [explanation]

### Recommendations
1. **Cut**: [Items that should be removed to stay on schedule]
2. **Defer**: [Items that can move to a future sprint/version]
3. **Keep**: [Additions that are genuinely necessary]
4. **Flag**: [Items that need a decision from producer/creative-director]
```

---

## Phase 4: Verdict

Assign a canonical verdict based on net scope change:

| Net Change | Verdict | Meaning |
|-----------|---------|---------|
| ≤10% | **PASS** | On Track — within acceptable variance |
| 10–25% | **CONCERNS** | Minor Creep — manageable with targeted cuts |
| 25–50% | **FAIL** | Significant Creep — must cut or formally extend timeline |
| >50% | **FAIL** | Out of Control — stop, re-plan, escalate to producer |

**Before applying that table, check that the percentage means something.** Emit
**NOT ASSESSED** instead — never a computed percentage — when any of:

- The **baseline document exists but enumerates no scope items** (all headings,
  placeholders, or `[TO BE CONFIGURED]`). Phase 1 stops when the file is *absent*;
  this is the case where it is present and empty, and it is the more dangerous
  one, because zero items yields a 0% net change that renders as **PASS — On
  Track**. Nothing was compared. Nothing was on track.
- The **current state cannot be determined** — no related source files, no commits
  in the window, nothing in progress to read. Comparing a real baseline against an
  unreadable present is not a 0% change, and not the −100% that zero current
  items computes — the table reads both as PASS.
- The denominator would be zero for any other reason. A percentage computed from
  no baseline items is not a small number; it is not a number.

`NOT ASSESSED` **outranks PASS** (a comparison that never happened has not shown
scope is on track) and **ranks below CONCERNS and FAIL** (measured creep is more
actionable than an unmeasurable baseline).

Output the verdict prominently:

```
**Scope Verdict: [PASS / CONCERNS / NOT ASSESSED / FAIL]**
Net change: [+X%] — [On Track / Minor Creep / Significant Creep / Out of Control]
           [or: NOT ASSESSED — [which side could not be read, and why]]
```

---

## Phase 5: Next Steps

After presenting the report, offer concrete follow-up:

- **PASS** → no action required. Suggest re-running before next milestone.
- **NOT ASSESSED** → say which side was unreadable and what would fix it (populate
  the baseline document, or point the skill at where the work actually lives).
  Do not offer a re-run against the same inputs — it will produce the same
  non-answer.
- **CONCERNS** → offer to identify the 2–3 additions with best cut ratio. Reference `/sprint-plan update` to formally re-scope.
- **FAIL** → recommend escalating to producer. Reference `/sprint-plan update` for re-planning or `/estimate` to re-baseline timeline.

End every verdict except NOT ASSESSED with:
> "Run `/scope-check [name]` again after cuts are made to verify the verdict improves."

(NOT ASSESSED ends with what would make it assessable, above — a re-run against
the same inputs would repeat the non-answer.)

---

### Rules

- Scope creep is additions without corresponding cuts or timeline extensions
- Not all additions are bad — some are discovered requirements. But they must be acknowledged and accounted for
- When recommending cuts, prioritize preserving the core player experience over nice-to-haves
- Always quantify scope changes — "it feels bigger" is not actionable, "+35% items" is
