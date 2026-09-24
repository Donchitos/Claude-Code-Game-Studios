---
name: propagate-design-change
description: "A GDD changed — scan ADRs and the traceability index for now-stale architectural decisions. Impact report, guides resolution."
argument-hint: "[path/to/changed-gdd.md]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/propagate-design-change/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,system_overrides`



# Propagate Design Change

When a GDD changes, architectural decisions written against it may no longer be
valid. This skill finds every affected ADR, compares what the ADR assumed against
what the GDD now says, and guides the user through resolution.

**Usage:** `/propagate-design-change design/gdd/combat-system.md`

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt — ADR/schema impacts here fall
under `schema_changes` and `architecture_decisions`).

**Workflow tier**: resolve for the **changed GDD's system** (per
`.claude/docs/workflow-modes.md`): use the
`system_overrides` row for that system if the block lists one, else the
project value. (A system pinned `minimal` has no ADRs even on a `standard`
project — so its change is N/A.) It scopes the cascade: `full` cascades across all
ADRs; `standard` checks only critical (Foundation-layer) ADRs plus any ADR
referencing the changed GDD; `minimal` is **not applicable** — no ADRs to cascade.
See Step 4.

## 1. Validate Argument

A GDD path argument is **required**. If missing, fail with:
> "Usage: `/propagate-design-change design/gdd/[system].md`
> Provide the path to the GDD that was changed."

Verify the file exists. If not, fail with:
> "[path] not found. Check the path and try again."

---

## 2. Diff the GDD Against Its Previous Version

**Ask git what changed — do not read two whole documents and compare them by
eye.** The previous form of this step read the current GDD in full *and*
`git show`-ed the full committed version, then diffed them mentally: two entire
documents in context to find what is usually a handful of lines, and a model
comparing 400-line documents will eventually miss an edit. Git cannot.

```bash
git diff HEAD -- design/gdd/[filename].md
```

If that is empty, the change may already be committed — widen to the commit that
last touched it:

```bash
git diff HEAD~1 HEAD -- design/gdd/[filename].md
```

If the file has no git history (new file), report:
> "No previous version in git — this appears to be a new GDD, not a revision.
> Nothing to propagate."

If the diff is empty **and** the file has history, report that plainly — "no
uncommitted or last-commit changes to `[file]`" — and ask which revision to
propagate. An empty diff is not "no impact"; it means nothing changed *here*.

From the diff hunks:
- Identify sections that changed (new rules, removed rules, modified formulas,
  changed acceptance criteria, changed tuning knobs). The `@@` hunk headers name
  the enclosing section, so the changed-section list falls out of the diff itself.
- Read the surrounding section from the current GDD **only** where a hunk is too
  small to interpret on its own (a changed number whose meaning depends on the
  rule above it). That is a targeted read of one section, not the document.
- Sections with no hunk are unchanged — by construction, not by inspection.
---

## 3. Produce the Change Summary

From the hunks resolved in step 2:

```
## Change Summary: [GDD filename]
Date of revision: [today]

Changed sections:
- [Section name]: [what changed — new rule, removed rule, formula modified, etc.]

Unchanged sections:
- [Section name]

Key changes affecting architecture:
- [Change 1 — likely to affect ADRs]
- [Change 2]
```

**Downstream GDD impact via the registry.** If `design/registry/entities.yaml`
exists, it already records which other GDDs depend on this system's facts —
compute the affected set from it rather than re-reading every GDD:
```
Grep pattern="source: design/gdd/[filename]" path="design/registry/entities.yaml" output_mode="content" -A 6
```
For each entity/constant/formula this GDD **owns** whose value the diff changed,
its `referenced_by:` list is the set of downstream GDDs that may now be
inconsistent — report them under "Downstream GDDs to re-check". **If
`design/registry/entities.yaml` does not exist or has no entries** (it ships as
an empty stub until `/design-system` populates it), skip this — the ADR cascade
below still runs.

---

## 4. Load Architecture Inputs

Read ADRs in `docs/architecture/` **per the resolved tier**:
- **`full`** — read **all** ADRs.
- **`standard`** — read only **critical (Foundation-layer) ADRs** plus any ADR
  that references the changed GDD.
- **`minimal`** — **not applicable**: there are no ADRs to cascade. Report "No ADR
  cascade at minimal workflow — design change recorded; no architecture impact
  analysis." and stop here.

**Establish the denominator first.** Glob the in-scope ADRs (per the tier above).
Call the count **N**. If N is 0: "No ADRs found in `docs/architecture/` — nothing
to cascade." Stop.

**Scan the requirement tables — do not full-read the ADRs at this step:**
```
Grep pattern="## GDD Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content" -A 15
```
**Recall net — an ADR may cite the changed GDD in prose without tabling it:**
```
Grep pattern="[changed-gdd-basename]" glob="docs/architecture/adr-*.md" output_mode="files_with_matches"
```
Take the **union** of the two results as the affected set **M**. This turns
N × ~200 lines into N × ~15 lines; §5 full-reads only the M.

Interpret the result — a zero-match scan is **never** "no impact" by default:

| Result | Meaning | Action |
|---|---|---|
| **M ≥ 1** | Normal. | Proceed. The N − M non-matching ADRs are *out of scope for this cascade* — do not describe them as verified unaffected. |
| **Both scans 0, N > 0** | Ambiguous — either no ADR references this GDD, or the ADRs lack requirement tables. | Run `Grep pattern="## GDD Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="files_with_matches"`. If that is **also** empty: "[N] ADRs found, none contains a 'GDD Requirements Addressed' section — traceability cannot be computed (a `gate-pre-production` blocker). Run `/architecture-decision [adr] retrofit`." If it is **non-empty**: the tables exist and genuinely none reference this GDD — "No ADR references [gdd] — no architecture impact." |

Read `docs/architecture/requirements-traceability.md` if it exists.

Report: "Loaded [N] ADRs by scan. [M] reference [gdd filename] ([X] via
requirements table, [Y] via prose reference only)."

---

## 5. Impact Analysis

Now read each ADR in the affected set **M** for its reasoning, not just its
table — judging whether a decision is still valid needs the ADR's `## Context`
and `## Decision` (and `## Consequences` where present), not scan output. **Do
not attempt the judgement below from scan output.**

This read is unbounded only up to a point — check size first
(`Bash: wc -c "docs/architecture/[adr-file].md"`):
- **Under ~50KB** — one full `Read` is fine and cheapest at this size.
- **~50KB or larger** — map headings first
  (`Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n`),
  then bounded-`Read` only `## Context`, `## Decision`, and `## Consequences`.
  An unbounded `Read` on a large ADR hits the 25k-token cap and, unrecovered,
  the only path forward is paging through the entire remainder — measured at
  103k tokens on a 34k-token ADR, most of it content this analysis never uses.

For each ADR that references the changed GDD:

Compare the ADR's "GDD Requirements Addressed" entries against the changed sections
of the GDD. For each referenced requirement:

1. **Locate the requirement** in the current GDD — does it still exist?
2. **Compare**: What did the GDD say when the ADR was written vs. what it says now?
3. **Assess the ADR decision**: Is the architectural decision still valid?

Classify each affected ADR as one of:

| Status | Meaning |
|--------|---------|
| ✅ **Still Valid** | The GDD change doesn't affect what this ADR decided |
| ⚠️ **Needs Review** | The GDD change may affect this ADR — human judgment needed |
| 🔴 **Likely Superseded** | The GDD change directly contradicts what this ADR assumed |

For each affected ADR, produce an impact entry:

```
### ADR-NNNN: [title]
Status: [Still Valid / Needs Review / Likely Superseded]

What the ADR assumed about this GDD:
  "[relevant quote from the ADR's GDD Requirements Addressed section]"

What the GDD now says:
  "[relevant quote from the current GDD]"

Assessment:
  [Explanation of whether the ADR decision is still valid, and why]

Recommended action:
  [Keep as-is | Review and update | Mark Superseded and write new ADR]
```

---

## 6. Present Impact Report

Present the full impact report to the user before asking for any action. Format:

```
## Design Change Impact Report
GDD: [filename]
Date: [today]
Changes detected: [N sections changed]
ADRs referencing this GDD: [M]

### Not Affected
[ADRs referencing this GDD whose decisions remain valid]

### Needs Review ([count])
[ADRs that may need updating]

### Likely Superseded ([count])
[ADRs whose assumptions are now contradicted]
```

---

## 6b. Director Gate — Technical Impact Review

**Review mode check** — apply before spawning TD-CHANGE-IMPACT:
- `solo` → skip. Note: "TD-CHANGE-IMPACT skipped — Solo mode." Proceed to Phase 7.
- `lean` → skip. Note: "TD-CHANGE-IMPACT skipped — Lean mode." Proceed to Phase 7.
- `full` → spawn as normal.

Spawn `technical-director` via `Agent` using gate **TD-CHANGE-IMPACT** (`.claude/docs/director-gates/td-change-impact.md`).

Pass: the full Design Change Impact Report from Phase 6 (change summary, all affected ADRs with their Still Valid / Needs Review / Likely Superseded classifications, and recommended actions).

The technical-director reviews whether:
- The impact classifications are correct (no ADRs under-classified)
- The recommended actions are architecturally sound
- Any cascading effects on other ADRs or systems were missed

Apply the verdict:
- **APPROVE** → proceed to Phase 7 resolution workflow
- **CONCERNS** → surface the specific ADRs or recommendations flagged; use `AskUserQuestion` with options: `Revise the impact assessment` / `Accept with noted concerns` / `Discuss further`
- **REJECT** → do not proceed to resolution; re-analyze the impact before continuing

---

## 7. Resolution Workflow

For each ADR marked "Needs Review" or "Likely Superseded", ask the user what to do:

Ask for each ADR in turn:
> "ADR-NNNN ([title]) — [status]. What would you like to do?"
> Options:
> - "Mark Superseded (I'll write a new ADR)" — updates ADR status line to `Superseded by: [pending]`
> - "Update in place (minor revision)" — opens the ADR for editing; note what to revise
> - "Keep as-is (the change doesn't actually affect this decision)"
> - "Skip for now (revisit later)"

For ADRs marked **Superseded**:
- Update the ADR's Status field: `Superseded by ADR-[next number] (pending — see change-impact-[date]-[system].md)`
- Ask: "May I update the status in [ADR filename]?"

---

## 8. Update Traceability Index

If `docs/architecture/requirements-traceability.md` exists:
- Add the changed GDD requirements to the "Superseded Requirements" table:

```markdown
## Superseded Requirements
| Date | GDD | Requirement | Changed To | ADRs Affected | Resolution |
|------|-----|-------------|------------|---------------|------------|
| [date] | [gdd] | [old requirement text] | [new requirement text] | ADR-NNNN | [Superseded/Updated/Valid] |
```

Ask: "May I update the traceability index?"

---

## 9. Output Change Impact Document

Ask: "May I write the change impact report to `docs/architecture/change-impact-[date]-[system-slug].md`?"

The document contains:
- The change summary from step 3
- The full impact analysis from step 5
- Resolution decisions made in step 7
- List of ADRs that need to be written or updated

If user approved: Verdict: **COMPLETE** — change impact report saved.
If user declined: Verdict: **BLOCKED** — user declined write.

---

## 10. Follow-Up Actions

Based on the resolution decisions, suggest:

- **ADRs marked Superseded**: "Run `/architecture-decision [title]` to write the
  replacement ADR. Then re-run `/propagate-design-change` to verify coverage."
- **ADRs to update in place**: List the specific fields to update in each ADR
- **If many ADRs affected**: "Run `/architecture-review` after all ADRs are updated
  to verify the full traceability matrix is still coherent."

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read silently** — compute the full impact before presenting anything
2. **Show the full report first** — let the user see the scope before asking for action
3. **Ask per-ADR** — don't batch decisions; each affected ADR may need different treatment
4. **Ask before writing** — always confirm before modifying any file
5. **Non-destructive** — never delete ADR content; only add "Superseded by" notes
