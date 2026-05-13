---
name: content-audit
description: "Audit GDD-specified content counts against implemented content. Identifies what's planned vs built."
argument-hint: "[system-name | --summary | (no arg = full audit)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write
model: sonnet
agent: producer
---

When this skill is invoked:

Parse the argument:
- No argument → full audit across all systems
- `[system-name]` → audit that single system only
- `--summary` → summary table only, no file write

---

## Phase 1 — Context Gathering

1. **Read `design/gdd/systems-index.md`** for the full list of systems, their
   categories, and MVP/priority tier.

2. **L0 pre-scan**: Before full-reading any GDDs, Grep all GDD files for
   `## Summary` sections plus common content-count keywords:
   ```
   Grep pattern="(## Summary|N enemies|N levels|N items|N abilities|enemy types|item types)" glob="design/gdd/*.md" output_mode="files_with_matches"
   ```
   For a single-system audit: skip this step and go straight to full-read.
   For a full audit: full-read only the GDDs that matched content-count keywords.
   GDDs with no content-count language (pure mechanics GDDs) are noted as
   "No auditable content counts" without a full read.

3. **Full-read in-scope GDD files** (or the single system GDD if a system
   name was given).

4. **For each GDD, extract explicit content counts or lists.** Look for patterns
   like:
   - "N enemies" / "enemy types:" / list of named enemies
   - "N levels" / "N areas" / "N maps" / "N stages"
   - "N items" / "N weapons" / "N equipment pieces"
   - "N abilities" / "N skills" / "N spells"
   - "N dialogue scenes" / "N conversations" / "N cutscenes"
   - "N quests" / "N missions" / "N objectives"
   - Any explicit enumerated list (bullet list of named content pieces)

4. **Build a content inventory table** from the extracted data:

   | System | Content Type | Specified Count/List | Source GDD |
   |--------|-------------|---------------------|------------|

   Note: If a GDD describes content qualitatively but gives no count, record
   "Unspecified" and flag it — unspecified counts are a design gap worth noting.

---

## Phase 2 — Implementation Scan

For each content type found in Phase 1, scan the relevant directories to count
what has been implemented. Use Glob and Grep to locate files.

**Levels / Areas / Maps:**
- Glob `assets/**/*.tscn`, `assets/**/*.unity`, `assets/**/*.umap`
- Glob `src/**/*.tscn`, `src/**/*.unity`
- Look for scene files in subdirectories named `levels/`, `areas/`, `maps/`,
  `worlds/`, `stages/`
- Count unique files that appear to be level/scene definitions (not UI scenes)

**Enemies / Characters / NPCs:**
- Glob `assets/data/**/enemies/**`, `assets/data/**/characters/**`
- Glob `src/**/enemies/**`, `src/**/characters/**`
- Look for `.json`, `.tres`, `.asset`, `.yaml` data files defining entity stats
- Look for scene/prefab files in character subdirectories

**Items / Equipment / Loot:**
- Glob `assets/data/**/items/**`, `assets/data/**/equipment/**`,
  `assets/data/**/loot/**`
- Look for `.json`, `.tres`, `.asset` data files

**Abilities / Skills / Spells:**
- Glob `assets/data/**/abilities/**`, `assets/data/**/skills/**`,
  `assets/data/**/spells/**`
- Look for `.json`, `.tres`, `.asset` data files

**Dialogue / Conversations / Cutscenes:**
- Glob `assets/**/*.dialogue`, `assets/**/*.csv`, `assets/**/*.ink`
- Grep for dialogue data files in `assets/data/`

**Quests / Missions:**
- Glob `assets/data/**/quests/**`, `assets/data/**/missions/**`
- Look for `.json`, `.yaml` definition files

**Engine-specific notes (acknowledge in the report):**
- Counts are approximations — the skill cannot perfectly parse every engine
  format or distinguish editor-only files from shipped content
- Scene files may include both gameplay content and system/UI scenes; the scan
  counts all matches and notes this caveat

---

## Phase 3 — Gap Report

Produce the gap table:

```
| System | Content Type | Specified | Found | Gap | Status |
|--------|-------------|-----------|-------|-----|--------|
```

**Status categories:**
- `COMPLETE` — Found ≥ Specified (100%+)
- `IN PROGRESS` — Found is 50–99% of Specified
- `EARLY` — Found is 1–49% of Specified
- `NOT STARTED` — Found is 0

**Priority flags:**
Flag a system as `HIGH PRIORITY` in the report if:
- Status is `NOT STARTED` or `EARLY`, AND
- The system is tagged MVP or Vertical Slice in the systems index, OR
- The systems index shows the system is blocking downstream systems

**Summary line:**
- Total content items specified (sum of all Specified column values)
- Total content items found (sum of all Found column values)
- Overall gap percentage: `(Specified - Found) / Specified * 100`

---

## Phase 4 — Output

### Full audit and single-system modes

Present the gap table and summary to the user. Ask: "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"

If yes, write the file:

```markdown
# Content Audit — [Date]

## Summary
- **Total specified**: [N] content items across [M] systems
- **Total found**: [N]
- **Gap**: [N] items ([X%] unimplemented)
- **Scope**: [Full audit | System: name]

> Note: Counts are approximations based on file scanning.
> The audit cannot distinguish shipped content from editor/test assets.
> Manual verification is recommended for any HIGH PRIORITY gaps.

## Gap Table

| System | Content Type | Specified | Found | Gap | Status |
|--------|-------------|-----------|-------|-----|--------|

## HIGH PRIORITY Gaps

[List systems flagged HIGH PRIORITY with rationale]

## Per-System Breakdown

### [System Name]
- **GDD**: `design/gdd/[file].md`
- **Content types audited**: [list]
- **Notes**: [any caveats about scan accuracy for this system]

## Recommendation

Focus implementation effort on:
1. [Highest-gap HIGH PRIORITY system]
2. [Second system]
3. [Third system]

## Unspecified Content Counts

The following GDDs describe content without giving explicit counts.
Consider adding counts to improve auditability:
[List of GDDs and content types with "Unspecified"]
```

After writing the report, ask:

> "Would you like to create backlog stories for any of the content gaps?"

If yes: for each system the user selects, suggest a story title and point them
to `/create-stories [epic-slug]` or `/quick-design` depending on the size of the gap.

### --summary mode

Print the Gap Table and Summary directly to conversation. Do not write a file.
End with: "Run `/content-audit` without `--summary` to write the full report."

---

## Phase 5 — Next Steps

After the audit, recommend the highest-value follow-up actions:

- If any system is `NOT STARTED` and MVP-tagged → "Run `/design-system [name]` to
  add missing content counts to the GDD before implementation begins."
- If total gap is >50% → "Run `/sprint-plan` to allocate content work across upcoming sprints."
- If backlog stories are needed → "Run `/create-stories [epic-slug]` for each HIGH PRIORITY gap."
- If `--summary` was used → "Run `/content-audit` (no flag) to write the full report to `docs/`."

Verdict: **COMPLETE** — content audit finished.
