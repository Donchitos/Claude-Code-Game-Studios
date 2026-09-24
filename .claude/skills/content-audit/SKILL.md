---
name: content-audit
description: "Audit GDD content counts against what's implemented — planned vs built."
argument-hint: "[system-name | --summary | (no arg = full audit)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/content-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

> This skill declares tier-dependent behaviour ("audit only specs in the required
> sections"), which is unreachable unless the tier is actually resolved — without
> it the skill applies whatever tier it assumed. Resolve `modes.workflow` before
> auditing, and
> when a required input such as `design/gdd/systems-index.md` is absent, report
> **`NOT ASSESSED — NO DATA`** rather than computing a gap percentage (which
> divides by zero when nothing is specified).


When this skill is invoked:

Parse the argument:
- No argument → full audit across all systems
- `[system-name]` → audit that single system only
- `--summary` → summary table only, no file write

---

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full content-count audit against all GDD specs.
- `standard` — audit only specs in the required sections.
- `minimal` — cannot run (no systems index exists).

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

## Phase 1 — Context Gathering

1. **Read `design/gdd/systems-index.md`** for the full list of systems, their
   categories, and MVP/priority tier.

2. **Registry-first count**: If `design/registry/entities.yaml` exists, read it
   first. Its `entities` and `items` sections are the cross-GDD named content
   the audit is counting, already distilled with a `source:` GDD per entry:
   ```
   Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 2
   ```
   `- name:` appears in all four registry sections; keep only the names whose
   `-A 2` context shows they sit under `entities:` or `items:` (the named
   content this audit counts — not `formulas:`/`constants:`). Use those as the
   **planned** named-content set without full-reading the GDDs that own them.
   **If `design/registry/entities.yaml` does not exist or has no entries** (it
   ships as an empty stub until `/design-system` populates it), skip this step
   and rely on the GDD scan below — behaviour is unchanged, only more expensive.

3. **L0 pre-scan**: Before full-reading any GDDs, run **two** greps — they
   answer different questions and must not share a pattern:

   a. Which GDDs carry a Summary (the denominator / fail-open check):
   ```
   Grep pattern="^## Summary" glob="design/gdd/*.md" output_mode="files_with_matches"
   ```

   b. Which GDDs actually declare content counts (the narrowing step):
   ```
   Grep pattern="[0-9]+[[:space:]]+(enemies|enemy types|levels|areas|maps|stages|items|weapons|equipment|abilities|skills|spells|cutscenes|conversations|dialogue scenes|bosses|quests)|(enemy|item|weapon|ability|level) types:" glob="design/gdd/*.md" output_mode="files_with_matches"
   ```

   > **These were one grep, and it narrowed nothing.** The old pattern was
   > `(## Summary|N enemies|N levels|N items|N abilities|enemy types|item types)`.
   > `N enemies` and friends are un-substituted placeholders copied from the
   > template — no real GDD contains the literal letter `N` as a count — while
   > `## Summary` matches every compliant GDD. So the union returned *all* GDDs
   > and step 3's whole purpose (read-avoidance) saved zero tokens. Pattern (b)
   > matches digits followed by the content nouns step 5 actually extracts.

   **Fail open on a missing Summary.** Establish the denominator: glob
   `design/gdd/*.md` and count **N**. **Scan (a)** matching fewer than N means
   those GDDs predate `## Summary` — never treat an absent Summary as a system
   out of scope; a zero-match (a) means "no GDD carries a Summary yet", not "no
   auditable content". Full-read the unmatched in-scope GDDs.

   For a single-system audit: skip this step and go straight to full-read.
   For a full audit: full-read only the GDDs that **scan (b)** matched
   **and are not already fully covered by the registry entries from step 2**.
   GDDs with no content-count language (pure mechanics GDDs) are noted as
   "No auditable content counts" without a full read.

4. **Full-read in-scope GDD files** (or the single system GDD if a system
   name was given).

5. **For each GDD, extract explicit content counts or lists.** Look for patterns
   like:
   - "N enemies" / "enemy types:" / list of named enemies
   - "N levels" / "N areas" / "N maps" / "N stages"
   - "N items" / "N weapons" / "N equipment pieces"
   - "N abilities" / "N skills" / "N spells"
   - "N dialogue scenes" / "N conversations" / "N cutscenes"
   - "N quests" / "N missions" / "N objectives"
   - Any explicit enumerated list (bullet list of named content pieces)

6. **Build a content inventory table** from the extracted data:

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
- Glob the **code root** for scene files: `*.tscn` (Godot), `*.unity` (Unity), `*.umap` (Unreal). Resolve the root per `.claude/docs/code-root-resolution.md`. **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.**
- Look for scene files in subdirectories named `levels/`, `areas/`, `maps/`,
  `worlds/`, `stages/`
- Count unique files that appear to be level/scene definitions (not UI scenes)

**Enemies / Characters / NPCs:**
- Glob `assets/data/**/enemies/**`, `assets/data/**/characters/**`
- Glob `<code root>/**/enemies/**`, `<code root>/**/characters/**`
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
