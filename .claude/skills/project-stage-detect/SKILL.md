---
name: project-stage-detect
description: "Analyze project state, detect stage, identify gaps, recommend next steps. 'Where are we in development?'"
argument-hint: "[optional: role filter like 'programmer' or 'designer']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, Bash(bash "*/.claude/skills/project-stage-detect/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
# Read-only diagnostic skill — no specialist agent delegation needed
---

# Project Stage Detection

This skill scans your project to determine its current development stage, completeness
of artifacts, and gaps that need attention. It's especially useful when:
- Starting with an existing project
- Onboarding to a codebase
- Checking what's missing before a milestone
- Understanding "where are we?"

---

## Workflow

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

> **Resolve the tier — do not assume it.** Saying "surface gaps per the **resolved** workflow
> tier" without resolving it — no bootstrap, no helper call — leaves
> the tier as whatever the model assumed. The tier decides what counts as a gap
> at all: at `full` every missing doc is one; at `minimal` none of them are,
> because a brief plus an engine is the normal state and code is the expected
> next step. Guessing high tells a jam project it is missing GDDs, an art bible
> and ADRs — the exact "process feels mismatched to my project" experience
> `modes.rigor` exists to prevent. A missing bootstrap is invisible to a static
> read — the config block simply does not render — so verify it by running.

**`workflow`** (per `.claude/docs/workflow-modes.md`). The tier governs
which absent documents count as gaps (step 3) — below `full`, optional docs are
not flagged.

### 1. Scan Key Directories

**Start with the deterministic pass — it answers "what exists" for every
catalogued artifact in one call:**

```
Bash: bash .claude/scripts/artifact-check.sh
```

With no `--phase` it reports every phase, so a single call covers the whole
project: per step, `PRESENT` / `ABSENT` / `SHORT` (with `count=` and `min=`) /
`PATTERN_MISS` / `NO_CHECK`. Use it instead of hand-globbing each artifact
below, and treat its `NO_CHECK` total as the honest bound on what existence
checks can tell you.

It reports observations only — this skill still decides what stage those
observations imply, and the tier still governs which absences are gaps at all
(see the workflow-tier note below).

Then analyze what the script cannot: content quality, counts it does not
track, and the judgement calls.

**Design Documentation** (`design/`):
- Count GDD files in `design/gdd/*.md`
- Check for game-concept.md (or `design/game-brief.md` at `minimal`), game-pillars.md, systems-index.md
- If systems-index.md exists, count total systems vs. designed systems
- Analyze completeness (Overview, Detailed Design, Edge Cases, etc.)
- Count narrative docs in `design/narrative/`
- Count level designs in `design/levels/`

**Source Code** (the code root — `src/` Godot, `Assets/` Unity, `Source/` Unreal; resolve per `.claude/docs/code-root-resolution.md`):
- Count source files (language-agnostic)
- Identify major systems (directories with 5+ files)
- Check for core/, gameplay/, ai/, networking/, ui/ directories
- Estimate lines of code (rough scale)

**Production Artifacts** (`production/`):
- Check for active sprint plans
- Look for milestone definitions
- Find roadmap documents

**Prototypes** (`prototypes/`):
- Count prototype directories
- Check for READMEs (documented vs undocumented)
- Assess if prototypes are archived or active

**Architecture Docs** (`docs/architecture/`):
- Count ADRs (Architecture Decision Records)
- Check for overview/index documents

**Tests** (`tests/`):
- Count test files
- Estimate test coverage (rough heuristic)

### 2. Classify Project Stage

Based on scanned artifacts, determine stage. Check `project.stage` in `project.yaml` first (if present); else `production/stage.txt` (legacy fallback) — either is an explicit override from `/gate-check`. Otherwise, auto-detect using these heuristics (check from most-advanced backward):

> **Always run the heuristics, even when a stage is configured — then COMPARE.**
> The configured value is authoritative for what the stage *is*; it is not
> evidence that the artifacts support it. Report both, and when they disagree say
> so explicitly:
>
> > "Configured stage: **Release**. Observed artifacts indicate
> > **Pre-Production** (2 source files, 0 ADRs, no architecture doc, no epics).
> > These disagree — the configured stage may be stale, or work exists outside
> > this repo."
>
> Reading config and reporting it back is not detection. This skill's own
> description promises "analyze project state, detect stage", and a stage
> detector that cannot contradict its input is the one thing it must never be.
> Observed live: it reported `Release` for a project whose artifacts matched its
> own Pre-Production row, four stages below, and said nothing.

| Stage | Indicators |
|-------|-----------|
| **Concept** | No game concept doc, brainstorming phase |
| **Systems Design** | Game concept exists, systems index missing or incomplete |
| **Technical Setup** | Systems index exists, engine not configured |
| **Pre-Production** | Engine configured, code root has <10 source files |
| **Production** | code root has 10+ source files, active development |
| **Polish** | Explicit only (set by `/gate-check` Production → Polish gate) |
| **Release** | Explicit only (set by `/gate-check` Polish → Release gate) |

### 3. Collaborative Gap Identification

**Surface gaps per the resolved workflow tier:**
- **`full`** — flag every missing doc type (GDDs, art bible, UX specs, ADRs) as a gap.
- **`standard`** — flag only required docs: missing GDDs for built systems and
  missing critical (Foundation-layer) ADRs. Do NOT flag an absent art bible unless
  visual-asset stories exist, and do NOT flag non-core UX specs.
- **`minimal`** — a `design/game-brief.md` + engine present is the normal state. Do NOT flag
  absent GDDs, art bible, UX specs, or ADRs as gaps; the expected next step is code.

**DO NOT** just list missing files. Instead, **ask clarifying questions** (only
for gaps the tier above says to surface):

- "I see combat code (`src/gameplay/combat/`) but no `design/gdd/combat-system.md`. Was this prototyped first, or should we reverse-document?"
- "You have 15 ADRs but no architecture overview. Should I create one to help new contributors?"
- "No sprint plans in `production/`. Are you tracking work elsewhere (Jira, Trello, etc.)?"
- "I found a game concept but no systems index. Have you decomposed the concept into individual systems yet, or should we run `/map-systems`?"
- "Prototypes directory has 3 projects with no READMEs. Were these experiments, or do they need documentation?"

### 4. Generate Stage Report

Use template: `.claude/docs/templates/project-stage-report.md`

**Report structure**:
```markdown
# Project Stage Analysis

**Date**: [date]
**Stage**: [Concept/Systems Design/Technical Setup/Pre-Production/Production/Polish/Release]
**Stage Confidence**: [PASS — clearly detected / CONCERNS — ambiguous signals / FAIL — critical gaps block progress]

## Completeness Overview
- Design: [X%] ([N] docs, [gaps])
- Code: [X%] ([N] files, [systems])
- Architecture: [X%] ([N] ADRs, [gaps])
- Production: [X%] ([status])
- Tests: [X%] ([coverage estimate])

## Gaps Identified
1. [Gap description + clarifying question]
2. [Gap description + clarifying question]

## Recommended Next Steps
[Priority-ordered list based on stage and role]
```

### 5. Role-Filtered Recommendations (Optional)

If user provided a role argument (e.g., `/project-stage-detect programmer`):

**Programmer**:
- Focus on architecture docs, test coverage, missing ADRs
- Code-to-docs gaps

**Designer**:
- Focus on GDD completeness, missing design sections
- Prototype documentation

**Producer**:
- Focus on sprint plans, milestone tracking, roadmap
- Cross-team coordination docs

**General** (no role):
- Holistic view of all gaps
- Highest-priority items across domains

### 6. Request Approval Before Writing

**Collaborative protocol**:
```
I've analyzed your project. Here's what I found:

[Show summary]

Gaps identified:
1. [Gap 1 + question]
2. [Gap 2 + question]

Recommended next steps:
- [Priority 1]
- [Priority 2]
- [Priority 3]

May I write the full stage analysis to production/project-stage-report.md?
```

Wait for user approval before creating the file.

---

## Example Usage

```bash
# General project analysis
/project-stage-detect

# Programmer-focused analysis
/project-stage-detect programmer

# Designer-focused analysis
/project-stage-detect designer
```

---

## Follow-Up Actions

After generating the report, suggest relevant next steps — **only for gaps the
resolved workflow tier surfaces** (step 3). At `standard`/`minimal`, do not
suggest authoring optional docs (e.g. don't suggest `/reverse-document` for an
absent GDD at `minimal`, where code is the expected next step):

- **Concept exists but no systems index?** → `/map-systems` to decompose into systems
- **Missing design docs?** → `/reverse-document design src/[system]`
- **Missing architecture docs?** → `/architecture-decision` or `/reverse-document architecture`
- **Prototypes need documentation?** → `/reverse-document concept prototypes/[name]`
- **No sprint plan?** → `/sprint-plan`
- **Approaching milestone?** → `/milestone-review`

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Question First**: Ask about gaps, don't assume
2. **Present Options**: "Should I create X, or is it tracked elsewhere?"
3. **User Decides**: Wait for direction
4. **Show Draft**: Display report summary
5. **Get Approval**: "May I write to production/project-stage-report.md?"

**Never** silently write files. **Always** show findings and ask before creating artifacts.
