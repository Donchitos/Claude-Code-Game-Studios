---
name: perf-profile
description: "Performance profiling — find bottlenecks, measure against budgets, produce ranked optimization recommendations."
argument-hint: "[system-name or 'full']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys performance.enforce,automation`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
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
specific and has been observed in practice: report templates whose verdict
enum had no "could not run" state produced **false clean passes** — an asset audit
returning COMPLIANT on a project with no assets and no standards, and a
performance profile reporting ">99% headroom against a 16.67ms budget" with zero
profiler data and no budget ever set.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 0: Resolve Budget Enforcement

`performance.enforce` decides what a budget violation *means* in this run. It
does not change which budgets are measured — `performance.target_framerate`,
`frame_budget_ms`, `draw_call_limit` and `memory_ceiling_mb` are profiled the
same way at every level:

| Value | Effect on this profile's findings |
|-------|-----------------------------------|
| `warn` (default) | Violations are reported as findings. They do not block; CI logs them without failing. |
| `block` | Violations are **blockers**. Say so explicitly in the report — a `block` project treats an over-budget system as release-stopping, and `/gate-check` will FAIL the Polish gate on it. |
| `off` | Budgets are informational only. Still report measured values, but do not raise violations as findings or recommendations to fix. |

Only `warn`, `block` and `off` are recognized. Surface any other value to the
user and fall back to `warn` rather than guessing.

> The value is locally overridable (`/settings --local performance.enforce=block`),
> so use the resolved block above rather than reading `project.yaml` — a
> teammate's stricter local setting is meant to bite on their machine only.

## Phase 1: Determine Scope

Read the argument:

- System name → focus profiling on that specific system
- `full` → run a comprehensive profile across all systems

---

## Phase 2: Load Performance Budgets

**Read the committed budgets from config first** — they are the project's
record of what it agreed to, and design docs are the fallback, not the source:

```bash
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/yaml-helper.sh" 2>/dev/null
get_effective_yaml_key performance.target_framerate
get_effective_yaml_key performance.frame_budget_ms
get_effective_yaml_key performance.draw_call_limit
get_effective_yaml_key performance.memory_ceiling_mb
```

> Written as four literal keys rather than a loop over leaf names, deliberately.
> The dead-settings audit matches the **full dotted key**, so a loop building
> `performance.$k` leaves three of the four spelled nowhere and the audit
> reports them DEAD while this skill reads them. Spell each key out in full.

> **Resolve these budgets from `project.yaml`, not from prose.** Phase 0 above
> states these four budgets "are profiled the same way at every level". Sending
> the reader to *"design docs or CLAUDE.md"* instead means a user who set
> `performance.target_framerate: 60` in `project.yaml` has it ignored by the one
> skill that profiles against budgets. The keys resolve correctly — this phase
> has to actually ask for them.

Then fall back to design docs or CLAUDE.md for anything config does not carry:

- Target FPS (e.g., 60fps = 16.67ms frame budget)
- Memory budget (total and per-system)
- Load time targets
- Draw call budgets
- Network bandwidth limits (if multiplayer)

**A metric with no committed budget is `NOT ASSESSED`, not a pass.** Do not
measure against the template's `[16.67ms]` placeholder — an unset budget is not
a budget that was met, and reporting headroom against a number nobody chose is
the exact fabrication this skill's own header warns about.

---

## Phase 3: Analyze Codebase

**CPU Profiling Targets:**
- `_process()` / `Update()` / `Tick()` functions — list all and estimate cost
- Nested loops over large collections
- String operations in hot paths
- Allocation patterns in per-frame code
- Unoptimized search/sort over game entities
- Expensive physics queries (raycasts, overlaps) every frame

**Memory Profiling Targets:**
- Large data structures and their growth patterns
- Texture/asset memory footprint estimates
- Object pool vs instantiate/destroy patterns
- Leaked references (objects that should be freed but aren't)
- Cache sizes and eviction policies

**Rendering Targets (if applicable):**
- Draw call estimates
- Overdraw from overlapping transparent objects
- Shader complexity
- Unoptimized particle systems
- Missing LODs or occlusion culling

**I/O Targets:**
- Save/load performance
- Asset loading patterns (sync vs async)
- Network message frequency and size

---

## Phase 4: Generate Profiling Report

**Write the report to `production/polish/[scope]-report-[date].md`**, asking first
per the Collaboration Protocol: *"May I write this profiling report to
`production/polish/[scope]-report-[date].md`?"* Create the directory if absent.

> **Name the destination — do not just render the template into the
> conversation.** A profile that lives only in the transcript is gone the moment
> the session ends, and no two runs can be compared. `production/polish/`
> is the same location `/team-polish` writes, deliberately: a profile taken by
> either route belongs in one place, or the comparison this skill exists to enable
> cannot be made.
>
> If a `NOT ASSESSED` section survives into the report, keep it in the written
> file. A profile whose gaps are edited out on the way to disk reads, later, as a
> complete measurement.


```markdown
## Performance Profile: [System or Full]
Generated: [Date]

### Performance Budgets
| Metric | Budget | Estimated Current | Status |
|--------|--------|-------------------|--------|
| Frame time | [16.67ms] | [estimate] | [OK/WARNING/OVER] |
| Memory | [target] | [estimate] | [OK/WARNING/OVER] |
| Load time | [target] | [estimate] | [OK/WARNING/OVER] |
| Draw calls | [target] | [estimate] | [OK/WARNING/OVER] |

### Hotspots Identified
| # | Location | Issue | Estimated Impact | Fix Effort |
|---|----------|-------|------------------|------------|

### Optimization Recommendations (Priority Order)
1. **[Title]** — [Description]
   - Location: [file:line]
   - Expected gain: [estimate]
   - Risk: [Low/Med/High]
   - Approach: [How to implement]

### Quick Wins (< 1 hour each)
- [Simple optimization 1]

### Requires Investigation
- [Area that needs actual runtime profiling to confirm impact]
```

Output the report with a summary: top 3 hotspots, estimated headroom vs budget, and recommended next action.

---

## Phase 5: Scope and Timeline Decision

Activate this phase only if any hotspot has Fix Effort rated M or L.

Present significant-effort items and ask the user to choose for each:

- **A) Implement the optimization** (proceed with fix now or schedule it)
- **B) Reduce feature scope** (run `/scope-check [feature]` to analyze trade-offs)
- **C) Accept the performance hit and defer to Polish phase** (log as known issue)
- **D) Escalate to technical-director for an architectural decision** (run `/architecture-decision`)

If multiple items are deferred to Polish (choice C), record them under `### Deferred to Polish`.

This skill is read-only — no files are written. Verdict: **COMPLETE** — performance profile generated.

---

## Phase 6: Next Steps

- If bottlenecks require architectural change: run `/architecture-decision`.
- If scope reduction is needed: run `/scope-check [feature]`.
- To schedule optimizations: run `/sprint-plan update`.

### Rules
- Never optimize without measuring first — gut feelings about performance are unreliable
- Recommendations must include estimated impact — "make it faster" is not actionable
- Profile on target hardware, not just development machines
- Static analysis (this skill) identifies candidates; runtime profiling confirms
