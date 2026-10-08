---
name: asset-audit
description: "Audit assets against naming conventions, file size budgets, format standards. Finds orphaned assets, missing references."
argument-hint: "[category|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(stat *), Bash(file *), Bash(od *), Bash(wc *), Bash(du *)
model: sonnet
# Read-only diagnostic skill — no specialist agent delegation needed
---

# Asset Audit

## Measuring file sizes and formats requires Bash

This skill's report asks for **file sizes against budgets**, **texture dimensions**
(power-of-two), **audio sample rates**, and **last-modified times** for orphan
detection. None of those are obtainable from `Read`/`Glob`/`Grep` — they need
`stat` or a binary header read, so the read-only measuring commands (`stat`,
`file`, `od`, `wc`, `du`) are pre-approved above; list files with Glob. Anything
else asks first.

**If you cannot take a measurement, the cell is `NOT ASSESSED`, never an
estimate.** A size budget table filled from guesses is worse than an empty one:
it looks like evidence. This is a live fabrication vector even on a project full
of real assets: if the template demands tables of numbers the tool allowlist
cannot produce, the only way to complete it is to invent them.

---

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

## Phase 1: Read Standards

Read the art bible's Asset Standards section (`design/art/art-bible.md`) and any
asset standards in the relevant design docs — size budgets and format rules come
from there. The naming patterns are the ones in Phase 3 below, unless the art
bible states its own.

If neither states a size budget — or there is no art bible — the Size section is
`NOT ASSESSED — no size budget set`, and the report names `/art-bible`, whose
Asset Standards section sets budgets, formats and the naming convention.

---

## Phase 2: Scan Asset Directories

Assets live under the engine's asset root: `assets/` on Godot, `Assets/` on
Unity, `Content/` on Unreal. Resolve the engine and its code root per
`.claude/docs/code-root-resolution.md`; that code root is the one Phase 3's
orphan and missing-asset searches read. If it is unresolved, stop:
`NOT ASSESSED — engine unresolved`, naming `/setup-engine`.

Scan the asset root using Glob:

- **Godot** — `assets/art/**/*`, `assets/audio/**/*`, `assets/vfx/**/*`,
  `assets/shaders/**/*`, `assets/data/**/*`
- **Unity** — `Assets/**/*`, leaving out scripts (`*.cs`, `*.asmdef`) and `*.meta` files
- **Unreal** — `Content/**/*.uasset` and `Content/**/*.umap`

The files matched are `Total assets scanned`. If there are none, the checks on
scanned files — Naming, Size, Format, Orphaned — are
`NOT ASSESSED — no assets under <asset root>`; the missing-asset search still runs.

---

## Phase 3: Run Compliance Checks

**Naming conventions:**
- Art: `[category]_[name]_[variant]_[size].[ext]`
- Audio: `[category]_[context]_[name]_[variant].[ext]`
- All files must be lowercase with underscores

These are Godot's conventions. Unity and Unreal name assets in PascalCase, so on
those engines check names only against a naming rule the art bible states; with
none, Naming is `NOT ASSESSED — no naming rule for <engine>` (name `/art-bible`).

**File standards:**
- Textures: Power-of-two dimensions, correct format (PNG for UI, compressed for 3D), within size budget
- Audio: Correct sample rate, format (OGG for SFX, OGG/MP3 for music), within duration limits.
  `file` reports an audio file's format and sample rate but not its length, and no
  pre-approved tool here does; a duration budget is therefore
  `NOT ASSESSED — duration not measurable here`, naming the files it covers.
- Data: Valid JSON/YAML, schema-compliant

On Unreal an asset file (`.uasset`, `.umap`) does not keep its source file's
format or dimensions, so Format is `NOT ASSESSED` there; its size is still measured.

**Orphaned assets:** Search the code root for references to each asset file. Flag any with no references.

**Missing assets:** Search the code root for asset references and verify the files exist.

Both searches need code: if the code root holds no source files, Orphaned and
Missing are `NOT ASSESSED — no code to search`. On Unity and Unreal most asset
references live in scenes, prefabs and other assets rather than code, so an
asset no code names may still be in use: Orphaned is `NOT ASSESSED` there.

---

## Phase 4: Output Audit Report

```markdown
# Asset Audit Report -- [Category] -- [Date]

## Summary
- **Total assets scanned**: [N]
- **Naming violations**: [N]
- **Size violations**: [N]
- **Format violations**: [N]
- **Orphaned assets**: [N]
- **Missing assets**: [N]
- **Sections not assessed**: [none | each section and why]

## Naming Violations
| File | Expected Pattern | Issue |
|------|-----------------|-------|

## Size Violations
| File | Budget | Actual | Overage |
|------|--------|--------|---------|

## Format Violations
| File | Expected Format | Actual Format |
|------|----------------|---------------|

## Orphaned Assets (no code references found)
| File | Last Modified | Size | Recommendation |
|------|-------------|------|---------------|

## Missing Assets (referenced but not found)
| Reference Location | Expected Path |
|-------------------|---------------|

## Recommendations
[Prioritized list of fixes, one per violation, each naming the change — the
target resolution or compression for a size violation, the corrected name for a
naming violation, the target format for a format violation]

## Verdict: [NOT ASSESSED / COMPLIANT / WARNINGS / NON-COMPLIANT]
```

Choose the verdict by the findings, first match wins:
- **NON-COMPLIANT** — any size violation, or any asset that code references but that does not exist
- **WARNINGS** — only naming, format or orphaned-asset findings
- **NOT ASSESSED** — the audit did not cover its scope: no data at all (the path
  above), zero assets scanned, or any section `NOT ASSESSED` — name which. It
  ranks below the two finding verdicts, because a measured violation is more
  actionable than a gap, and above COMPLIANT
- **COMPLIANT** — at least one asset scanned, every section assessed, no findings

This skill is read-only — it produces a report but does not write files.

---

## Phase 5: Next Steps

- Fix naming violations using the Phase 3 patterns (or the art bible's, where it states its own).
- If standards were missing, run `/art-bible` to write its Asset Standards section.
- Delete confirmed orphaned assets after manual review.
- Run `/content-audit` to cross-check asset counts against GDD-specified requirements.
