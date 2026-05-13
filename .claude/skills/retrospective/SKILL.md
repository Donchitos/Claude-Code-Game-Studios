---
name: retrospective
description: "Generates a sprint or milestone retrospective by analyzing completed work, velocity, blockers, and patterns. Produces actionable insights for the next iteration."
argument-hint: "[sprint-N|milestone-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion
model: sonnet
---

## Phase 1: Parse Arguments

Determine whether this is a sprint retrospective (`sprint-N`) or a milestone retrospective (`milestone-name`).

---

## Phase 1b: Check for Existing Retrospective

Before loading any data, glob for an existing retrospective file:

- For sprint retrospectives: `production/retrospectives/retro-[sprint-slug]-*.md`
  (also check `production/sprints/sprint-[N]-retrospective.md` as an alternate location)
- For milestone retrospectives: `production/retrospectives/retro-[milestone-name]-*.md`

If a matching file is found, use `AskUserQuestion`:
- Prompt: "An existing retrospective was found: [filename]. How do you want to proceed?"
- Options:
  - `[A] Update existing — load it and add/revise sections with new data`
  - `[B] Start fresh — generate a new retrospective (archive the old one)`

If [A]: read the existing file and carry its content forward, revising sections with new data.
If [B]: continue to Phase 2 with a blank slate. Before writing the new file, rename the existing one with a `-archived-[date]` suffix.

---

## Phase 2: Load Sprint or Milestone Data

Read the sprint or milestone plan from the appropriate location:

- Sprint plans: `production/sprints/`
- Milestone definitions: `production/milestones/`

**Also check for `production/sprint-status.yaml`**: if it exists, read it alongside the sprint plan. It is the authoritative source for actual story completion status (status: done, completed dates, blockers). Use it as the primary source for completion metrics in Phase 3. Fall back to markdown scanning only if the yaml does not exist. Note discrepancies between the yaml and the sprint plan (e.g., stories in yaml not in plan, or vice versa).

**If the file does not exist or is empty**, output:

> "No sprint data found for [sprint/milestone]. Run `/sprint-status` to generate
> sprint data first, or provide the sprint details manually."

Then use `AskUserQuestion` to present two options:

- **[A] Provide data manually** — ask the user to paste or describe the sprint
  tasks, dates, and outcomes; use that as the source of truth for the retrospective.
- **[B] Stop** — abort the skill. Verdict: **BLOCKED** — no sprint data available.

If the user chooses [A], collect the data and continue to Phase 3 using what they provide.
If the user chooses [B], stop here.

Extract: planned tasks, estimated effort, owners, and goals.

Run git log for the sprint period to understand what was actually committed and when. Use the Bash tool (which uses Git Bash on Windows — the `2>/dev/null` is bash syntax, not PowerShell):

```
Bash: git log --oneline --since="4 weeks ago" 2>/dev/null || git log --oneline -20
```

Adjust the `--since` date to match the sprint duration if known from the sprint plan.

---

## Phase 3: Analyze Completion and Trends

Scan for completed and incomplete tasks by comparing the plan against actual deliverables. Check for:

- Tasks completed as planned
- Tasks completed but modified from the plan
- Tasks carried over (not completed)
- Tasks added mid-sprint (unplanned work)
- Tasks removed or descoped

Scan the codebase for TODO/FIXME trends:

- Count current TODO/FIXME/HACK comments
- Compare to previous sprint counts if available (check previous retrospectives)
- Note whether technical debt is growing or shrinking

Read previous retrospectives (if any) from `production/retrospectives/` to check:

- Were previous action items addressed?
- Are the same problems recurring?
- How has velocity trended?

---

## Phase 4: Generate the Retrospective

```markdown
## Retrospective: [Sprint N / Milestone Name]
Period: [Start Date] -- [End Date]
Generated: [Date]

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Tasks | [X] | [Y] | [+/- Z] |
| Completion Rate | -- | [Z%] | -- |
| Story Points / Effort Days | [X] | [Y] | [+/- Z] |
| Bugs Found | -- | [N] | -- |
| Bugs Fixed | -- | [N] | -- |
| Unplanned Tasks Added | -- | [N] | -- |
| Commits | -- | [N] | -- |

### Velocity Trend

| Sprint | Planned | Completed | Rate |
|--------|---------|-----------|------|
| [N-2] | [X] | [Y] | [Z%] |
| [N-1] | [X] | [Y] | [Z%] |
| [N] (current) | [X] | [Y] | [Z%] |

**Trend**: [Increasing / Stable / Decreasing]
[One sentence explaining the trend]

### What Went Well
- [Observation backed by specific data or examples]
- [Another positive observation]
- [Recognize specific contributions or decisions that paid off]

### What Went Poorly
- [Specific issue with measurable impact -- e.g., "Feature X took 5 days
  instead of estimated 2, blocking tasks Y and Z"]
- [Another issue with impact]
- [Do not assign blame -- focus on systemic causes]

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| [What blocked progress] | [How long] | [How it was resolved] | [How to prevent recurrence] |

### Estimation Accuracy

| Task | Estimated | Actual | Variance | Likely Cause |
|------|-----------|--------|----------|--------------|
| [Most overestimated task] | [X] | [Y] | [+Z] | [Why] |
| [Most underestimated task] | [X] | [Y] | [-Z] | [Why] |

**Overall estimation accuracy**: [X%] of tasks within +/- 20% of estimate

[Analysis: Are we consistently over- or under-estimating? For which types of
tasks? What adjustment should we apply?]

### Carryover Analysis

| Task | Original Sprint | Times Carried | Reason | Action |
|------|----------------|---------------|--------|--------|
| [Task that was not completed] | [Sprint N-X] | [N] | [Why] | [Complete / Descope / Redesign] |

### Technical Debt Status
- Current TODO count: [N] (previous: [N])
- Current FIXME count: [N] (previous: [N])
- Current HACK count: [N] (previous: [N])
- Trend: [Growing / Stable / Shrinking]
- [Note any areas of concern]

### Previous Action Items Follow-Up

| Action Item (from Sprint N-1) | Status | Notes |
|-------------------------------|--------|-------|
| [Previous action] | [Done / In Progress / Not Started] | [Context] |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | [Specific, measurable action] | [Who] | [High/Med/Low] | [When] |
| 2 | [Another action] | [Who] | [Priority] | [When] |

### Process Improvements
- [Specific change to how we work, with expected benefit]
- [Another improvement -- keep it to 2-3 actionable items, not a wish list]

### Summary
[2-3 sentence overall assessment: Was this a good sprint/milestone? What is
the single most important thing to change going forward?]
```

---

## Phase 5: Save Retrospective

Present the retrospective and top findings to the user (completion rate, velocity trend, top blocker, most important action item).

Ask: "May I write this to `production/retrospectives/retro-sprint-[N]-[date].md`?" (or `production/retrospectives/retro-[milestone-name]-[date].md` for milestone retrospectives)

If yes, write the file, creating the `production/retrospectives/` directory if needed. Verdict: **COMPLETE** — retrospective saved.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 6: Next Steps

Use `AskUserQuestion`:
- Prompt: "Retrospective complete. The action items and velocity data are ready. Would you like to start sprint planning now with this data pre-loaded?"
- Options:
  - `[A] Yes — open sprint planning with retro action items and velocity delta pre-populated`
  - `[B] No — I'll reference the retrospective file manually when I'm ready`

If the user selects [A]: Proceed to invoke `/sprint-plan new`, passing the retrospective file path and a summary of the action items and velocity change so the sprint planner can reference them.

- If this was a milestone retrospective, run `/gate-check` to formally assess readiness for the next phase.

### Guidelines

- Be honest and specific. Vague retrospectives ("communication could be better") produce vague improvements. Use data and examples.
- Focus on systemic issues, not individual blame.
- Limit action items to 3-5. More than that dilutes focus.
- Every action item must have an owner and a deadline.
- Check whether previous action items were completed. Recurring unaddressed items are a process smell.
- If this is a milestone retrospective, also evaluate whether the milestone goals were achieved and what that means for the overall project timeline.
