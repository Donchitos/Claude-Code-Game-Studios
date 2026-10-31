# /architecture-review — Phase 8: Write and Update Traceability Index

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 8: Write and Update Traceability Index

**In this file:**

- The receipt is taken last
- RTM Output (rtm mode only)
- TR Registry Update
- Reflexion Log Update
- Session State Update

Use the `question` tool for the write approval:
- "Review complete. What would you like to write?"
  - [A] Write all three files — review report (`docs/architecture/architecture-review-[date].md`), traceability index (`docs/architecture/requirements-traceability.md`), TR registry (`docs/architecture/tr-registry.yaml`)
  - [B] Write review report only — `docs/architecture/architecture-review-[date].md`
  - [C] Don't write anything yet — I need to review the findings first

**A `single-gdd` run saw one system**, so in that mode [A] writes the review
report and only that system's share of the other two files. Name it so in the
option: "…update [system]'s rows in the traceability index and its TR registry
entries". In `requirements-traceability.md`, replace that system's matrix rows
and recompute the Coverage Summary, keeping every other system's rows as they
are. When the index does not exist yet, write the report and the registry only,
and say a full review creates the index. In the TR registry, append, update and
deprecate only that system's entries: another system's GDD was not read, so its
entries are never proposed for deprecation.

When Phase 4 found a 🔴 conflict and `docs/consistency-failures.md` exists, name
that file in option [A] as well — "…and append [N] conflict entr(y/ies) to
`docs/consistency-failures.md`". Only [A] appends there (see Reflexion Log
Update); [B] writes the report and nothing else.

### The receipt is taken last

Write the review report after the TR registry update and the
`consistency-failures.md` entries, and take its receipt lines at that moment —
never from the Phase 7 draft. Both files are review inputs: a receipt taken
before this run edited them records the old content, and the next run reads
this run's own edit as `CHANGED`.

```
Bash: bash .claude/scripts/review-receipts.sh hash docs/architecture/adr-*.md design/gdd/*.md docs/architecture/tr-registry.yaml docs/architecture/architecture.md docs/engine-reference/[engine]/*.md docs/engine-reference/[engine]/modules/*.md project.yaml .claude/docs/technical-preferences.md docs/consistency-failures.md .opencode/skills/architecture-review/SKILL.md .opencode/skills/architecture-review/references/*.md
```

It is the same list as Phase 1a's check, with `[engine]` filled in the same way.
An optional input that does not exist prints `not stamped, no such file` and is
left out; that is expected. Paste the stamp lines into the report under its
header, where the Phase 7 template shows them.

### RTM Output (rtm mode only)

For `rtm` mode, use the `question` tool:
- "May I write the full Requirements Traceability Matrix?"
  - [A] Yes — write to `docs/architecture/requirements-traceability.md`
  - [B] Not yet — show me the full RTM data first, then ask again

RTM file format:

```markdown
# Requirements Traceability Matrix (RTM)

> Last Updated: [date]
> Mode: /architecture-review rtm
> Coverage: [N]% full chain complete (GDD → ADR → Story → Test)

## How to read this matrix

| Column | Meaning |
|--------|---------|
| TR-ID | Stable requirement ID from tr-registry.yaml |
| GDD | Source design document |
| ADR | Architectural decision governing implementation |
| Story | Story file that implements this requirement |
| Test File | Automated test file path |
| Test Status | COVERED / MISSING / NONE / NO STORY |

## Full Traceability Matrix

| TR-ID | GDD | Requirement | ADR | Story | Test File | Status |
|-------|-----|-------------|-----|-------|-----------|--------|
[Full matrix rows from Phase 3b]

## Coverage Summary

| Status | Count | % |
|--------|-------|---|
| COVERED — full chain complete | [N] | [%] |
| MISSING test — story exists, no test | [N] | [%] |
| NO STORY — ADR exists, not yet implemented | [N] | [%] |
| NO ADR — architectural gap | [N] | [%] |
| **Total requirements** | **[N]** | **100%** |

## Uncovered Requirements (Priority Fix List)

Requirements where the full chain is broken, prioritised by layer:

### Foundation layer gaps
[list with suggested action per gap]

### Core layer gaps
[list]

### Feature / Presentation layer gaps
[list — lower priority]

## History

| Date | Full Chain % | Notes |
|------|-------------|-------|
| [date] | [%] | Initial RTM |
```

### TR Registry Update

Also ask: "May I update `docs/architecture/tr-registry.yaml` with new requirement
IDs from this review?"

If yes, read the current `docs/architecture/tr-registry.yaml` again first:
the review read it at the start, and another skill or session may have changed
it since. Build the update from that fresh read, never from the earlier copy,
and keep every entry already in it. Then:
- **Append** any new TR-IDs that weren't in the registry before this review
- **Update** `requirement` text and `revised` date for any entries whose GDD
  wording changed (ID stays the same)
- **Mark** `status: deprecated` for any registry entries whose GDD requirement
  no longer exists (confirm with user before marking deprecated; in `single-gdd`
  mode, only the reviewed system's entries)
- **Mark** `status: "superseded-by: TR-[system]-NNN"` for an entry whose
  requirement was split or replaced, naming the new TR-ID(s). Keep the quotes:
  unquoted, the second colon makes the file invalid YAML
- **Never** renumber or delete existing entries
- Update the `last_updated` and `version` fields at the top

After writing, run `bash .claude/scripts/registry.sh validate` and fix every row
about an entry this write added or changed (a DUPLICATE, STATUS or LAYOUT row,
or a PATH_MISSING row for a path it named) before you go on; name rows about
other entries to the user rather than fixing them unasked. If the script is
missing or prints nothing, say the registry check did not run, then re-read the
entries you wrote against the rules in the file's header.

This ensures all future story files can reference stable TR-IDs that persist
across every subsequent architecture review.

### Reflexion Log Update

When the user chose Phase 8's [A] — the option that named this file — append
any 🔴 CONFLICT entries found in Phase 4 to `docs/consistency-failures.md` (if
the file exists), before writing the review report (its receipt is taken last):

```markdown
### [YYYY-MM-DD] — /architecture-review — 🔴 CONFLICT
**Domain**: Architecture / [specific domain e.g. State Ownership, Performance]
**Documents involved**: [ADR-NNNN] vs [ADR-MMMM]
**What happened**: [specific conflict — what each ADR claims]
**Resolution**: [how it was or should be resolved]
**Pattern**: [generalised lesson for future ADR authors in this domain]
```

Only append CONFLICT entries — do not log GAP entries (missing ADRs are expected
before the architecture is complete). Do not create the file if missing — only
append when it already exists.

### Session State Update

After writing all approved files, silently append to
`production/session-state/active.md`:

    ## Session Extract — /architecture-review [date]
    - Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
    - Requirements: [N] total — [X] covered, [Y] partial, [Z] gaps
    - New TR-IDs registered: [N, or "None"]
    - GDD revision flags: [comma-separated GDD names, or "None"]
    - Top ADR gaps: [top 3 gap titles from the report, or "None"]
    - Report: docs/architecture/architecture-review-[date].md

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."

The traceability index — written to `docs/architecture/requirements-traceability.md`,
the path `/propagate-design-change` and the Pre-Production gate read; `rtm` mode
later extends the same file with story and test columns — uses this format:

```markdown
# Architecture Traceability Index
Last Updated: [date]
Engine: [name + version]

## Coverage Summary
- Total requirements: [N]
- Covered: [X] ([%])
- Partial: [Y]
- Gaps: [Z]

## Full Matrix
[Complete traceability matrix from Phase 3]

## Known Gaps
[All ❌ items with suggested ADRs]

## Superseded Requirements
[Requirements whose GDD was changed after the ADR was written]
```

---
