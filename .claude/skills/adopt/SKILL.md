---
name: adopt
description: "Brownfield audit — do existing artifacts actually work? Numbered migration plan. Unlike /project-stage-detect, checks compliance not existence."
argument-hint: "[focus: full | gdds | adrs | stories | infra]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Write, AskUserQuestion, Bash(bash "*/.claude/skills/adopt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,automation_always_ask,workflow`

Resolved above — use as-is. `/adopt` also inspects `project.yaml` and the legacy
config files directly when reporting and writing migration state; that raw
inspection is deliberate and separate from the resolved values above.


# Adopt — Brownfield Template Adoption

This skill audits an existing project's artifacts for **format compliance** with
the template's skill pipeline, then produces a prioritised migration plan.

**This is not `/project-stage-detect`.**
`/project-stage-detect` answers: *what exists?*
`/adopt` answers: *will what exists actually work with the template's skills?*

A project can have GDDs, ADRs, and stories — and every format-sensitive skill
will still fail silently or produce wrong results if those artifacts are in the
wrong internal format.

**Output:** `docs/adoption-plan-[date].md` — a persistent, checkable migration plan.

**Argument modes:**

**Audit mode:** `$ARGUMENTS[0]` (blank = `full`)

- **No argument / `full`**: Complete audit — all artifact types
- **`gdds`**: GDD format compliance only
- **`adrs`**: ADR format compliance only
- **`stories`**: Story format compliance only
- **`infra`**: Infrastructure artifact gaps only (registry, manifest, sprint-status, stage.txt)

---

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** (per `.claude/docs/workflow-modes.md`). It scopes the Phase 2 audit and
Phase 3 severity: `full` audits all doc types at full structure; `standard` audits
only the required docs/sections (optional sections are informational, not gaps);
`minimal` is a `design/game-brief.md` format check — GDDs/ADRs/UX are not expected. See Phase 2.

## Phase 1: Detect Project State

Emit one line before reading: `"Scanning project artifacts..."` — this confirms the
skill is running during the silent read phase.

Then read silently before presenting anything else.

### Existence check
- `project.stage` in `project.yaml` (fallback `production/stage.txt`) — if either is present, use that value (authoritative phase)
- `design/gdd/game-concept.md` (or, at the minimal tier, `design/game-brief.md`) — concept exists?
- `design/gdd/systems-index.md` — systems index exists?
- Count GDD files: `design/gdd/*.md` (excluding game-concept.md and systems-index.md)
- Count ADR files: `docs/architecture/adr-*.md`
- Count story files: `production/epics/**/*.md` (excluding EPIC.md)
- `project.yaml` (`engine.name`) / `.claude/docs/technical-preferences.md` — engine configured?
- `docs/engine-reference/` — engine reference docs present?
- Glob `docs/adoption-plan-*.md` — note the filename of the most recent prior plan if any exist

### Infer phase (if no project.stage / stage.txt)
Use the same heuristic as `/project-stage-detect`:
- 10+ source files in the code root → Production
- Stories in `production/epics/` → Pre-Production
- ADRs exist → Technical Setup
- systems-index.md exists → Systems Design
- game-concept.md (or `design/game-brief.md`) exists → Concept
- Nothing → Fresh (not a brownfield project — suggest `/start`)

If the project appears fresh (no artifacts at all), use `AskUserQuestion`:
- "This looks like a fresh project — no existing artifacts found. `/adopt` is for
  projects with work to migrate. What would you like to do?"
  - "Run `/start` — begin guided first-time onboarding"
  - "My artifacts are in a non-standard location — help me find them"
  - "Cancel"

Then stop — do not proceed with the audit regardless of which option the user picks
(each option leads to a different skill or manual investigation).

Report: "Detected phase: [phase]. Found: [N] GDDs, [M] ADRs, [P] stories."

---

## Phase 2: Format Audit

For each artifact type in scope (based on argument mode **and the resolved
workflow tier**), check not just that the file exists but that it contains the
internal structure the template requires. At `minimal`, scope the audit to
`design/game-brief.md` — do not audit for GDDs, ADRs, or UX specs (they are not expected).

### 2a: GDD Format Audit

**Gather section presence deterministically — do not read the GDDs to count
headings.** For each GDD discovered in Phase 1, pass its path explicitly to the
structure-check script:

```
Bash: bash .claude/scripts/gdd-structure-check.sh [path-to-gdd]
```

**Pass paths one at a time; do not invoke it bare.** The no-argument form sweeps
`design/gdd/` only, and a brownfield project's GDDs are not guaranteed to live
there — pass whatever paths Phase 1 found. The script prints a `PRESENT:` list
and, when applicable, an `ABSENT:` list per file. It reports **presence only**
and makes no REQUIRED/ADVISORY judgment (that is the tier logic below), and it
already accepts `## Detailed Design` as satisfying the `Detailed Rules`
requirement, so do not flag that alias as missing.

If the script prints `Not found:` for a path or errors, that is a **discovery
failure, not a format gap** — report it as "could not audit [path]" and do not
count it as a missing-sections finding.

**Then apply the workflow tier** resolved above to each file's PRESENT/ABSENT
lists. Which sections are **required** (a miss = gap) vs **advisory** (a miss =
informational):
- **`full`** — all 8 sections are required.
- **`standard`** — the 5 required (Overview, Detailed Rules, Edge Cases,
  Dependencies, Acceptance Criteria) + Formulas for any system that defines
  numeric rules (rates, curves, thresholds, costs — the system's `Category` is a
  hint, not the test); Player Fantasy and Tuning Knobs are advisory.
- **`minimal`** — GDDs are not expected; audit `design/game-brief.md` instead. Any GDD
  that does exist is checked at the `standard` bar, advisorily.

The script's 8 canonical labels are: Overview, Player Fantasy, Detailed Rules,
Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria.

A section reported PRESENT can still be an empty heading. For each GDD, also
record with a targeted grep (not a full read):
- Placeholder-only sections — `Grep pattern="\[To be designed\]"` (or an
  equivalent empty/single-line body) marks a present-but-unwritten section.
- The `**Status**:` header field — `Grep pattern="^>?[[:space:]]*\*\*Status\*\*:"`.
  Valid values: `Draft`, `In Design`, `Designed`, `In Review`, `Approved`,
  `Implemented`, `Needs Revision`.

> **The `>?` is load-bearing, and so are `Draft`/`Implemented`.** Both emitters
> write this field inside a blockquote — `.claude/docs/templates/game-design-document.md`
> and `/design-system` produce `> **Status**: …` — so an anchor of
> `^\*\*Status\*\*:` matches nothing and reports *every* template-compliant GDD
> as missing its Status. The template's own value list offers `Draft` and
> `Implemented`, so both must count as valid.

### 2b: ADR Format Audit

For each ADR file found, check for these critical sections:

| Section | Impact if missing |
|---|---|
| `## Status` | **BLOCKING** — `/story-readiness` ADR status check silently passes everything |
| `## ADR Dependencies` | HIGH — dependency ordering in `/architecture-review` breaks |
| `## Engine Compatibility` | HIGH — post-cutoff API risk is unknown |
| `## GDD Requirements Addressed` | MEDIUM — traceability matrix loses coverage |
| `## Performance Implications` | LOW — not pipeline-critical |

For each ADR, record: which sections present, which missing, current Status value
if the Status section exists.

### 2c: systems-index.md Format Audit

If `design/gdd/systems-index.md` exists:

1. **Parenthetical status values** — Grep for any Status cell containing
   parentheses: `"Needs Revision ("`, `"In Progress ("`, etc.
   These break exact-string matching in `/gate-check`, `/create-stories`,
   and `/architecture-review`. **BLOCKING.**

2. **Valid status values** — check that Status column values are only from:
   `Not Started`, `In Progress`, `In Review`, `Designed`, `Approved`, `Needs Revision`
   Flag any unrecognised values.

3. **Column structure** — check that the table has at minimum: System name,
   Layer, Priority, Status columns. Missing columns degrade skill functionality.

### 2d: Story Format Audit

For each story file found:

- **`Manifest Version:` field** — present in story header? (LOW — auto-passes if absent)
- **TR-ID reference** — does story contain `TR-[a-z]+-[0-9]+` pattern? (MEDIUM — no staleness tracking)
- **ADR reference** — does story reference at least one ADR? (check for `ADR-` pattern)
- **Status field** — present and readable?
- **Acceptance criteria** — does the story have a checkbox list (`- [ ]`)?

### 2e: Infrastructure Audit

| Artifact | Path | Impact if missing |
|---|---|---|
| TR registry | `docs/architecture/tr-registry.yaml` | HIGH — no stable requirement IDs |
| Control manifest | `docs/architecture/control-manifest.md` | HIGH — no layer rules for stories |
| Manifest version stamp | In manifest header: `Manifest Version:` | MEDIUM — staleness checks blind |
| Sprint status | `production/sprint-status.yaml` | MEDIUM — `/sprint-status` falls back to markdown |
| Stage file | `project.stage` in `project.yaml` (fallback `production/stage.txt`) | MEDIUM — phase auto-detect unreliable |
| Engine reference | `docs/engine-reference/[engine]/VERSION.md` | HIGH — ADR engine checks blind |
| Architecture traceability | `docs/architecture/requirements-traceability.md` | MEDIUM — no persistent matrix |

### 2f: Project Config Audit

Read `project.yaml` (the primary config store) and `.claude/docs/technical-preferences.md` (legacy mirror). A setting counts as configured if EITHER source has a real value (in technical-preferences.md, `[TO BE CONFIGURED]` means unconfigured):
- `engine.name`/`version`/`language`/`rendering`/`physics` (else the Engine/Language/Rendering/Physics fields) → HIGH if unconfigured in both (ADR skills fail)
- `naming.*` (else Naming conventions) → MEDIUM
- `performance.*` (else Performance budgets) → MEDIUM
- Forbidden Patterns, Allowed Libraries (technical-preferences.md only — not migrated to project.yaml) → LOW (starts empty by design)

### 2g: v1.0 Migration Check

A project is a **v1.0 project needing migration** when `project.yaml` does NOT
exist at the repo root AND at least one legacy file does: `production/stage.txt`,
`production/review-mode.txt`, or a `.claude/docs/technical-preferences.md` with
real values.

"Real values" means one of the keys the converter actually migrates — Engine,
Language, Rendering, Physics, the naming, platform and performance fields,
Framework, or the specialists. Not merely "some bullet is filled in": the
shipped template ships one prose default (`- **Required Tests**: …`) that is
never migrated, and counting it made every fresh clone read as a v1.0 project.

Do not hand-migrate. Run the converter, which is deterministic and covered by
the framework's own test suite:

```bash
bash .claude/scripts/migrate-v1-config.sh --dry-run
```

Report what it lists. If the user approves, run it without `--dry-run`. It
writes `project.yaml` plus `production/migration-report.md` and **deletes
nothing** — the whole operation stays reversible with `git checkout`.

Then tell the user to read `production/migration-report.md` before running:

```bash
bash .claude/scripts/migrate-v1-config.sh --finalize
```

`--finalize` deletes a legacy file only after proving its value is present in
`project.yaml`; on mismatch it deletes nothing and exits 4. It never deletes
`technical-preferences.md`, which still holds Forbidden Patterns and Allowed
Libraries.

**If the script refuses with exit 3**, do not work around it. Exit 3 means one
of two things, and the message says which:

- **the values DISAGREE** — two sources of truth and no way to know which the
  user edited last. Surface it and let them decide.
- **a `production/migration-report.md` is already present** — a migration ran
  here, so these are post-migration leftovers and `--finalize` is the next step,
  not a second `migrate`.

Both files merely *existing* is not exit 3 and must not be reported as a
conflict: `/start` writes `production/stage.txt` on every new v1.1 project as a
mirror, so agreement is the normal state. The script says
`the legacy files mirror it (values agree)` and exits 0 for that.

Classify as **BLOCKING** in Phase 3: until migration runs, every skill reads
config through the legacy fallback chain, and v1.1 settings are unavailable.

---

## Phase 3: Classify and Prioritise Gaps

Organise every gap found across all audits into four severity tiers:

**BLOCKING** — Will cause template skills to silently produce wrong results *right now*.
Examples: ADR missing Status field, systems-index parenthetical status values,
engine not configured when ADRs exist.

**HIGH** — Will cause stories to be generated with missing safety checks, or
infrastructure bootstrapping will fail.
Examples: ADRs missing Engine Compatibility, GDDs missing Acceptance Criteria
(stories can't be generated from them), tr-registry.yaml missing.

**MEDIUM** — Degrades quality and pipeline tracking but does not break functionality.
Examples: GDDs missing Tuning Knobs or Formulas sections, stories missing TR-IDs,
sprint-status.yaml missing.

**LOW** — Retroactive improvements that are nice-to-have but not urgent.
Examples: Stories missing Manifest Version stamps, GDDs missing Open Questions section.

Count totals per tier. If zero BLOCKING and zero HIGH gaps: report that the project
is template-compatible and only advisory improvements remain.

---

## Phase 4: Build the Migration Plan

Compose a numbered, ordered action plan. Ordering rules:
1. BLOCKING gaps first (must fix before any pipeline skill runs reliably)
2. HIGH gaps next, infrastructure before GDD/ADR content (bootstrapping needs correct formats)
3. MEDIUM gaps ordered: GDD gaps before ADR gaps before story gaps (stories depend on GDDs and ADRs)
4. LOW gaps last

For each gap, produce a plan entry with:
- A clear problem statement (one sentence, no jargon)
- The exact command to fix it, if a skill handles it
- Manual steps if it requires direct editing
- A time estimate (rough: 5 min / 30 min / 1 session)
- A checkbox `- [ ]` for tracking

**Special case — systems-index parenthetical status values:**
This is always the first item if present. Show the exact values that need changing
and the exact replacement text. Offer to fix this immediately before writing the plan.

**Special case — ADRs missing Status field:**
For each affected ADR, the fix is:
`/architecture-decision retrofit docs/architecture/adr-[NNNN]-[slug].md`
List each ADR as a separate checkable item.

**Special case — GDDs missing sections:**
For each affected GDD, list which sections are missing and the fix:
`/design-system retrofit design/gdd/[filename].md`

**Infrastructure bootstrap ordering** — always present in this sequence:
1. Fix ADR formats first (registry depends on reading ADR Status fields)
2. Run `/architecture-review` → bootstraps `tr-registry.yaml`
3. Run `/create-control-manifest` → creates manifest with version stamp
4. Run `/sprint-plan update` → creates `sprint-status.yaml`
5. Run `/gate-check [phase]` → writes `project.stage` in `project.yaml` (and legacy `stage.txt`) authoritatively

**Existing stories** — note explicitly:
> "Existing stories continue to work with all template skills — all new format
> checks auto-pass when the fields are absent. They won't benefit from TR-ID
> staleness tracking or manifest version checks until they're regenerated. This
> is intentional: do not regenerate stories that are already in progress."

---

## Phase 5: Present Summary and Ask to Write

Present a compact summary before writing:

```
## Adoption Audit Summary
Phase detected: [phase]
Engine: [configured / NOT CONFIGURED]
GDDs audited: [N] ([X] fully compliant, [Y] with gaps)
ADRs audited: [N] ([X] fully compliant, [Y] with gaps)
Stories audited: [N]

Gap counts:
  BLOCKING: [N] — template skills will malfunction without these fixes
  HIGH:     [N] — unsafe to run /create-stories or /story-readiness
  MEDIUM:   [N] — quality degradation
  LOW:      [N] — optional improvements

Estimated remediation: [X blocking items × ~Y min each = roughly Z hours]
```

Before asking to write, show a **Gap Preview**:
- List every BLOCKING gap as a one-line bullet describing the actual problem
  (e.g. `systems-index.md: 3 rows have parenthetical status values`,
  `adr-0002.md: missing ## Status section`). No counts — show the actual items.
- Show HIGH / MEDIUM / LOW as counts only (e.g. `HIGH: 4, MEDIUM: 2, LOW: 1`).

This gives the user enough context to judge scope before committing to writing the file.

If a prior adoption plan was detected in Phase 1, add a note:
> "A previous plan exists at `docs/adoption-plan-[prior-date].md`. The new plan will
> reflect current project state — it does not diff against the prior run."

Use `AskUserQuestion`:
- "Ready to write the migration plan?"
  - "Yes — write `docs/adoption-plan-[date].md`"
  - "Show me the full plan preview first (don't write yet)"
  - "Cancel — I'll handle migration manually"

If the user picks "Show me the full plan preview", output the complete plan as a
fenced markdown block. Then ask again with the same three options.

---

## Phase 6: Write the Adoption Plan

If approved, write `docs/adoption-plan-[date].md` with this structure:

```markdown
# Adoption Plan

> **Generated**: [date]
> **Project phase**: [phase]
> **Engine**: [name + version, or "Not configured"]
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

[One sub-section per blocking gap with problem, fix command, time estimate, checkbox]

---

## Step 2: Fix High-Priority Gaps

[One sub-section per high gap]

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (creates tr-registry.yaml)
Run `/architecture-review` — even if ADRs already exist, this run bootstraps
the TR registry from your existing GDDs and ADRs.
**Time**: 1 session (review can be long for large codebases)
- [ ] tr-registry.yaml created

### 3b. Create control manifest
Run `/create-control-manifest`
**Time**: 30 min
- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file
Run `/sprint-plan update`
**Time**: 5 min (if sprint plan already exists as markdown)
- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage
Run `/gate-check [current-phase]`
**Time**: 5 min
- [ ] `project.stage` in `project.yaml` written (legacy `production/stage.txt` also updated)

---

## Step 4: Medium-Priority Gaps

[One sub-section per medium gap]

---

## Step 5: Optional Improvements

[One sub-section per low gap]

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent — so nothing breaks. They won't benefit from staleness tracking until
regenerated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
```

---

## Phase 6b: Set Review Mode

After writing the adoption plan (or if the user cancels writing), check whether a
review mode is already set — read `modes.review_mode` from `project.yaml` first,
then legacy `production/review-mode.txt`.

**If a mode is already set**: Note the current mode — "Review mode is already set to `[current]`." — skip the prompt.

**If no mode is set**: Use `AskUserQuestion`:

- **Prompt**: "One more setup step: how much design review would you like as you work through the workflow?"
- **Options**:
  - `Full` — Director specialists review at each key workflow step. Best for teams, learning the workflow, or when you want thorough feedback on every decision.
  - `Lean (recommended)` — Directors only at phase gate transitions (/gate-check). Skips per-skill reviews. Balanced for solo devs and small teams.
  - `Solo` — No director reviews at all. Maximum speed. Best for game jams, prototypes, or if reviews feel like overhead.

Write the choice immediately after selection — no separate "May I write?" needed.
Dual-write:
1. Set `modes.review_mode` in `project.yaml` (primary; add the `modes:` block if absent).
2. Also write the single word to `production/review-mode.txt` (legacy fallback).

Value mapping:
- `Full` → `full`
- `Lean (recommended)` → `lean`
- `Solo` → `solo`

Create the `production/` directory if it does not exist.

---

## Phase 7: Offer First Action

After writing the plan, don't stop there. Pick the single highest-priority gap
and offer to handle it immediately using `AskUserQuestion`. Choose the first
branch that applies:

**If there are parenthetical status values in systems-index.md:**
Use `AskUserQuestion`:
- "The most urgent fix is `systems-index.md` — [N] rows have parenthetical status
  values (e.g. `Needs Revision (see notes)`) that break /gate-check,
  /create-stories, and /architecture-review right now. I can fix these in-place."
  - "Fix it now — edit systems-index.md"
  - "I'll fix it myself"
  - "Done — leave me with the plan"

**If ADRs are missing `## Status` (and no parenthetical issue):**
Use `AskUserQuestion`:
- "The most urgent fix is adding `## Status` to [N] ADR(s): [list filenames].
  Without it, /story-readiness silently passes all ADR checks. Start with
  [first affected filename]?"
  - "Yes — retrofit [first affected filename] now"
  - "Retrofit all [N] ADRs one by one"
  - "I'll handle ADRs myself"

**If GDDs are missing Acceptance Criteria (and no blocking issues above):**
Use `AskUserQuestion`:
- "The most urgent gap is missing Acceptance Criteria in [N] GDD(s):
  [list filenames]. Without them, /create-stories can't generate stories.
  Start with [highest-priority GDD filename]?"
  - "Yes — add Acceptance Criteria to [GDD filename] now"
  - "Do all [N] GDDs one by one"
  - "I'll handle GDDs myself"

**If no BLOCKING or HIGH gaps exist:**
Use `AskUserQuestion`:
- "No blocking gaps — this project is template-compatible. What next?"
  - "Walk me through the medium-priority improvements"
  - "Run /project-stage-detect for a broader health check"
  - "Done — I'll work through the plan at my own pace"

> **Adoption plan saved to `docs/adoption-plan-[date].md`.** Re-run `/adopt` at any time to re-check remaining gaps as you complete them.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read silently** — complete the full audit before presenting anything
2. **Show the summary first** — let the user see scope before asking to write
3. **Ask before writing** — always confirm before creating the adoption plan file
4. **Offer, don't force** — the plan is advisory; the user decides what to fix and when
5. **One action at a time** — after handing off the plan, offer one specific next step,
   not a list of six things to do simultaneously
6. **Never regenerate existing artifacts** — only fill gaps in what exists;
   do not rewrite GDDs, ADRs, or stories that already have content
