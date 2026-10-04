---
name: balance-check
description: "Find balance outliers, broken progressions, degenerate strategies, economy imbalances in formulas and data. 'Check game balance'."
argument-hint: "[system-name|path-to-data-file]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash(bash "*/.claude/skills/balance-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`



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

## Phase 1: Identify Balance Domain

Determine the balance domain from `$ARGUMENTS` — the whole string, since a data-file path may contain spaces:

- **Combat** → weapon/ability DPS, time-to-kill, damage type interactions
- **Economy** → resource faucets/sinks, acquisition rates, item pricing
- **Progression** → XP/power curves, dead zones, power spikes
- **Loot** → rarity distribution, pity timers, inventory pressure
- **File path given** → load that file directly and infer domain from content

If no argument, ask the user which system to check.

---

## Phase 2: Read Data Files

Read relevant files from `assets/data/` and `design/balance/` for the identified domain.
Note every file read — they will appear in the Data Sources section of the report.

---

## Phase 3: Read Design Document

**Registry first.** If `design/registry/entities.yaml` exists, read it before the
GDD. Its `constants` and `formulas` sections hold the cross-GDD named values and
output ranges — the balance targets — already distilled, each with a `source:`
GDD and any `revised:` date:
```
Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 6
```
Take the intended values from the registry for any constant or formula it lists
(the `constants:` and `formulas:` blocks); these are the authoritative cross-doc
figures a GDD must not contradict. **If `design/registry/entities.yaml` does not
exist or has no entries** (it ships as an empty stub until `/design-system`
populates it), skip this and use the GDD alone.

Then read the GDD for the system from `design/gdd/` to understand intended design
targets, tuning knobs, and expected value ranges — for anything the registry did
not already supply. This is the baseline for "correct" behaviour.

If the data files are FOUND but neither source gives targets for this domain,
the sections that judge against targets (Outliers Detected, and Progression
Analysis where the domain has a curve) are `NOT ASSESSED — NO DATA`. Each one names what was missing — the
GDD it looked for in `design/gdd/`, and whether the registry was absent or empty
— and names `/design-system`, which writes both.

---

## Phase 4: Perform Analysis

**Every domain: compare each value with its target.** For each named value in the
data files, take its target from Phase 3 — a registry constant's `value`, a
registry formula's `output_range`, or the range the GDD states — and compare. A
value outside its target is a row in Outliers Detected (`player_damage_base` 140
against 90–110). A value with no target anywhere is neither in range nor an
outlier: list it under Values That Need Attention as `no stated range — not judged`.

Then run domain-specific checks:

**Combat balance:**
- Calculate DPS for all weapons/abilities at each power tier
- Check time-to-kill at each tier
- Identify any options that dominate all others (strictly better)
- Check if defensive options can create unkillable states
- Verify damage type/resistance interactions are balanced

**Economy balance:**
- Map all resource faucets and sinks with flow rates
- Project resource accumulation over time
- Check for infinite resource loops
- Verify gold sinks scale with gold generation
- Check if any items are never worth purchasing

**Progression balance:**
- Plot the XP curve and power curve
- Check for dead zones (no meaningful progression for too long)
- Check for power spikes (sudden jumps in capability)
- Verify content gates align with expected player power
- Check if skip/grind strategies break intended pacing

**Loot balance:**
- Calculate expected time to acquire each rarity tier
- Check pity timer math
- Verify no loot is strictly useless at any stage
- Check inventory pressure vs acquisition rate

---

## Phase 5: Output the Analysis

```
## Balance Check: [System Name]

### Data Sources Analyzed
- [List of files read]

### Health Summary: [NOT ASSESSED / HEALTHY / CONCERNS / CRITICAL ISSUES]

### Outliers Detected
| Item/Value | Expected Range | Actual | Issue |
|-----------|---------------|--------|-------|

### Degenerate Strategies Found
- [Strategy description and why it is problematic]

### Progression Analysis
[Graph description or table showing progression curve health]

### Recommendations
| Priority | Issue | Suggested Fix | Impact |
|----------|-------|--------------|--------|

### Values That Need Attention
[Specific values with suggested adjustments and rationale]
```

Choose the Health Summary by the worst finding, first match wins:
- **CRITICAL ISSUES** — a degenerate strategy (one choice dominates every
  alternative), a progression that stalls or cannot be completed, or an economy
  loop with no sink
- **CONCERNS** — outliers or curve problems a tuning pass can fix, with no
  finding of the critical kind
- **NOT ASSESSED** — nothing to analyze (the no-data path above), a section that
  needs targets is `NOT ASSESSED — NO DATA`, or a value had no stated range to
  judge it against; name which. It ranks below the two finding verdicts, because
  a measured problem is more actionable than a gap, and above HEALTHY
- **HEALTHY** — every value judged against a stated target, no outliers, no
  degenerate strategies, progression within the stated targets

---

## Phase 6: Fix & Verify Cycle

After presenting the report, use `AskUserQuestion`:
- Prompt: "Balance check complete. What would you like to do next?"
- Options:
  - `[A] Fix highest-priority issue now — walk me through it`
  - `[B] Save report to design/balance/balance-check-[system]-[date].md`
  - `[C] Stop here — I'll review the findings manually`

If [A]:
- Ask which issue to address first (refer to the Recommendations table by priority row)
- Guide the user to update the relevant data file in `assets/data/` or formula in `design/balance/`
- After each fix, offer to re-run the relevant balance checks to verify no new outliers were introduced
- If the fix changes a tuning knob defined in a GDD or referenced by an ADR, remind the user:
  > "This value is defined in a design document. Run `/propagate-design-change [path]` on the affected GDD to find downstream impacts before committing."

If [B]:
- Write the report to `design/balance/balance-check-[system]-[date].md` (create the directory if needed). Use the current date for [date] in YYYY-MM-DD format.
- Confirm the file was written, then end with: "Re-run `/balance-check` after fixes to verify."

If [C]:
- Summarize open issues and end with: "Re-run `/balance-check` after fixes to verify."
