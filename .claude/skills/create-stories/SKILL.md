---
name: create-stories
description: "Break one epic into implementable stories embedding TR-ID, ADR guidance, acceptance criteria. Reads the control manifest. After /create-epics."
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-stories/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,story_granularity,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


# Create Stories

A story is a single implementable behaviour — small enough to complete in one
focused session, self-contained, and fully traceable to a GDD requirement and
an ADR decision. Stories are what developers pick up. Epics are what architects
define.

**Run this skill per epic**, not per layer. Run it for Foundation epics first,
then Core, and so on — matching the dependency order.

**Output:** `production/epics/[epic-slug]/story-NNN-[slug].md` files

**Previous step:** `/create-epics [system]`
**Next step after stories exist:** `/story-readiness [story-path]` then `/dev-story [story-path]`

---

## 1. Parse Argument


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** for this epic's system (per `.claude/docs/workflow-modes.md`) —
use the `system_overrides` row for `<system>` if the block lists one, else the
project value. `<system>` is the epic slug / its GDD system. The tier sets which prerequisites block — see the note in Step 2.

**`story_granularity`** — it sets each
story's AC load: **5–10 ACs covering a whole feature** at `coarse`, **2–4 ACs
covering one task** at `balanced` (default), **1 AC** at `fine` (the story name is
the AC restatement). Group or split ACs into stories to hit the target.

**`docs.density`** — it controls the *depth* of each story's prose (context,
implementation notes, ADR summary), not the AC count (that is
`story_granularity`) and never the AC text itself. `modes.rigor` sets it
alongside `workflow`; set `docs.density` explicitly to vary story prose alone:
`terse` = notes as bullets, no preamble; `balanced` = short context paragraph +
notes (default); `thorough` = full context, implementation guidance, and ADR
rationale. The embedded TR-ID reference, ADR Version stamp, and acceptance
criteria are structural and are never trimmed by density.

- `/create-stories [epic-slug]` — e.g. `/create-stories combat`
- `/create-stories production/epics/combat/EPIC.md` — full path also accepted
- No argument — at `minimal` there are no epics yet (Option A): skip to Step 2's
  `minimal` branch and synthesize the epic from `design/game-brief.md`. At
  `standard`/`full`, ask "Which epic would you like to break into stories?" and
  Glob `production/epics/*/EPIC.md` to list available epics with their status.

  > **If that glob returns nothing at `standard`/`full`, stop — do not build a
  > question with no options.** Report:
  > "No epics found under `production/epics/`. Run `/create-epics layer: foundation`
  > first — an epic is what this skill decomposes."
  >
  > **The zero-epic path is load-bearing.** Asking which epic *and* globbing to
  > list them leaves an `AskUserQuestion` with nothing to offer when the glob is
  > empty. Route to `/create-epics` instead — it is named as **Previous step**
  > in this skill's own header.
  >
  > Note what this skill guarded and what it did not. Step 2's ADR validation is
  > thorough: three tiers, each with its own stop condition, and an explicit
  > message naming the missing file. That is the **deepest** input. The **first**
  > input — does an epic exist at all — went unchecked. Guarding the far end of a
  > chain while leaving the near end open is the shape to watch for.
  >
  > At `minimal` this does not apply: there are deliberately no epics, and the
  > branch above synthesizes one from the brief.

---

## 2. Load Everything for This Epic

> **`minimal` tier — synthesize the epic from the brief** (Option A). At
> `minimal` there is no `/create-epics` step and no `EPIC.md`. Instead:
> 1. Read `design/game-brief.md` in full (it is one page).
> 2. Synthesize an implicit epic: write a lightweight
>    `production/epics/<slug>/EPIC.md`, where `<slug>` is the brief's slugified
>    working title (`mvp` if untitled) — goal = the brief's one-sentence pitch,
>    scope = its MVP feature list, ordering = its **Build order**. Keep it terse;
>    this is the container `/dev-story` and `/sprint-status` expect.
> 3. Generate **one coarse story per MVP feature** (Step 3+), in Build-order
>    sequence, each traced to the brief (not a GDD/TR-ID). Leave stories unblocked
>    on ADR grounds — none exist at this tier.
> Skip the GDD, control-manifest, TR-registry, and ADR reads below (none exist at
> `minimal`), then continue to Step 3 with the synthesized epic.

For `standard`/`full` (a `/create-epics` epic exists), read in full (these are small):

- `production/epics/[epic-slug]/EPIC.md` — epic overview, governing ADRs, GDD requirements table
- The epic's GDD (`design/gdd/[filename].md`) — at `full` read all 8 sections; at `standard` the 5 required sections (+ conditional Formulas); at `minimal` the GDD may not exist — work from the epic brief + acceptance criteria. Always prioritise Acceptance Criteria, Formulas, and Edge Cases where present.
- `docs/architecture/control-manifest.md` — grep only this epic's layer (`Grep pattern="^## <layer> Layer Rules" path="docs/architecture/control-manifest.md" output_mode="content" -A 40`) plus the header Manifest Version date, not a full read of all layers
- `docs/architecture/tr-registry.yaml` — grep only this system's entries (`Grep pattern="system: <slug>" path="docs/architecture/tr-registry.yaml" output_mode="content" -B1 -A5`, or `id: TR-<slug>-`), not the whole cross-system registry

**Load each governing ADR by section — never with an unbounded full read.** A
substantial ADR exceeds the 25k-token `Read` cap, and a capped read's only
recovery is paging through the remainder — the most expensive possible way to
read a file (measured at 103k tokens on a 34k-token ADR vs ~54k for targeted
reads of the same file). Per ADR:

1. **Map the headings** (cheap — line numbers only):
   ```
   Grep pattern="^## |^### Implementation Guidelines" path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```
2. **Bounded-read exactly the sections this skill consumes**, using the line
   numbers from the map to set `Read(offset, limit)` spans that end where the
   next section begins:
   - `## Summary` and `## Decision` (including its `### Implementation
     Guidelines` subsection) — these feed the story's ADR Decision Summary
     and Implementation Notes.
   - `## Engine Compatibility` — feeds the story's Engine, Risk, and Engine
     Notes fields. (Engine Notes is a *story* field derived from this
     section — it is not an ADR section name; do not search for one.)
3. **Capture the `## Last Verified` date**:
   ```
   Grep pattern="^## (Last Verified|Date)" path="docs/architecture/[adr-file].md" output_mode="content" -A 1
   ```
   Use `Last Verified`, falling back to `Date`, then to `unversioned` if both
   are absent. This becomes the story's `ADR Version` stamp — `/dev-story`
   uses it to decide whether it can trust this story's distilled summary
   instead of re-opening the ADR.

Skip Context, Alternatives Considered, Consequences, Risks, and any
Amendments Log unless a section you loaded explicitly cross-references one of
their entries — then take only the referenced entry with one more bounded
read. If the heading map comes back empty (a nonstandard ADR predating the
template), fall back to one full `Read` — and if that read truncates at the
cap, do **not** page through the remainder; grep for the story-relevant
content directly and flag the ADR for `/architecture-decision [file]
retrofit`.

**ADR existence validation** (tier-gated — resolved in Step 1): After reading the governing ADRs list from the epic, confirm each referenced ADR file exists on disk.

- **`full`** — if **any** referenced ADR file cannot be found, **stop immediately** before decomposing any story.
- **`standard`** — stop only if a **critical (Foundation-layer) ADR** is missing; for a missing non-critical ADR, **warn and continue** (the story embeds the ADR reference and is set `Status: Blocked` until the ADR exists).
- **`minimal`** — no ADR requirement; do **not** stop. Embed any ADR references that do exist; otherwise decompose against the brief + acceptance criteria and leave stories unblocked on ADR grounds.

When stopping (full / standard-critical):

> "Epic references [ADR-NNNN: title] but `docs/architecture/[adr-file].md` was not found.
> Check the filename in the epic's Governing ADRs list, or run `/architecture-decision`
> to create it. Cannot create stories until all referenced ADR files are present."

At `full`, do not proceed to Step 3 until all referenced ADR files are confirmed present.

Report: "Loaded epic [name], GDD [filename], [N] governing ADRs [ADR status], [manifest status]." State the **actual** situation for the resolved tier — e.g. "all confirmed present, control manifest v[date]" at full; "M present, K missing non-critical (embedded + Blocked)" at standard; "no ADRs / manifest required" at minimal. Do not assert "all confirmed present" if any referenced ADR was missing, or name a manifest version when none exists.

---

## 3. Classify Stories by Type

**Story Type Classification** — assign each story a type based on its acceptance criteria:

| Story Type | Assign when criteria reference... |
|---|---|
| **Logic** | Formulas, numerical thresholds, state transitions, AI decisions, calculations |
| **Integration** | Two or more systems interacting, signals crossing boundaries, save/load round-trips |
| **Visual/Feel** | Animation behaviour, VFX, "feels responsive", timing, screen shake, audio sync |
| **UI** | Menus, HUD elements, buttons, screens, dialogue boxes, tooltips |
| **Config/Data** | Balance tuning values, data file changes only — no new code logic |

Mixed stories: assign the type that carries the highest implementation risk.
The type determines what test evidence is required before `/story-done` can close the story.

---

## 4. Decompose the GDD into Stories

For each GDD acceptance criterion:

1. Group related criteria that require the same core implementation
2. Each group = one story
3. Order stories: foundational behaviour first, edge cases last, UI last

**Story sizing rule:** size each story to the resolved `modes.story_granularity`
target (above). The "~2-4 hours / one focused session" heuristic is the
`balanced` default — at `coarse` a story spans a whole feature (5–10 ACs,
multi-day), at `fine` a story is a single AC. Split or group criteria to hit the
resolved target, not a fixed session length.

For each story, determine:
- **GDD requirement**: which acceptance criterion(ia) does this satisfy?
- **TR-ID**: look up in `tr-registry.yaml`. Use the stable ID. If no match, use `TR-[system]-???` and warn.
- **Governing ADR**: which ADR governs how to implement this?
  - `Status: Accepted` → embed normally
  - `Status: Proposed` → set story `Status: Blocked` with note: "BLOCKED: ADR-NNNN is Proposed — run `/architecture-decision` to advance it"
  - **Multiple ADRs apply**: List all governing ADRs in the story's `Governing ADRs:` field. Designate the one most directly controlling the implementation pattern as primary (first in the list). Others are listed as secondary references.
  - **No ADR applies at all**: Write `ADR: N/A — [brief reason, e.g. "pure data configuration, no architectural pattern required"]` in the story's ADR field. Do NOT leave the field blank — a blank ADR field means "not checked", not "not applicable".
- **Story Type**: from Step 3 classification
- **Engine risk**: from the ADR's Knowledge Risk field

---

## 4b. QA Lead Story Readiness Gate

**Review mode check** — apply before spawning QL-STORY-READY:
- `solo` → skip. Note: "QL-STORY-READY skipped — Solo mode." Proceed to Step 5 (present stories for review).
- `lean` → skip (not a PHASE-GATE). Note: "QL-STORY-READY skipped — Lean mode." Proceed to Step 5 (present stories for review).
- `full` → spawn as normal.

After decomposing all stories (Step 4 complete) but before presenting them for write approval, spawn `qa-lead` **once** via `Agent` using gate **QL-STORY-READY** (`.claude/docs/director-gates/ql-story-ready.md`). A single call returns **both** the readiness verdict and the test-case specs — do not spawn `qa-lead` a second time to generate specs.

Pass: the full story list with acceptance criteria, story types, and TR-IDs; the epic's GDD acceptance criteria for reference. Require in the return:
1. The QL-STORY-READY verdict per story (ADEQUATE / GAPS / INADEQUATE).
2. For every story it marks **ADEQUATE**, its test-case spec block (formats below) — one Given/When/Then per acceptance criterion for Logic and Integration stories, or manual verification steps for Visual/Feel and UI stories.

Present the assessment. For each story flagged GAPS or INADEQUATE, revise the acceptance criteria before proceeding — untestable criteria cannot be implemented correctly; those stories carry no specs until they reach ADEQUATE (re-request specs for just those in a follow-up call only if a revision was needed). Once all stories are ADEQUATE, proceed with the returned specs.

**Prefer an existing QA plan when one already covers a story** — this substitutes for the qa-lead's specs, it does not add a spawn. Glob `production/qa/qa-plan-*.md` for the most recent file; if it holds test specs for stories in this epic (match titles/slugs in its Automated Tests Required section) that differ from the qa-lead's, use `AskUserQuestion` (Use QA-plan specs / Use qa-lead specs / Skip and leave `*Test cases not yet defined — run /qa-plan to generate them.*`). Either way no additional `qa-lead` spawn occurs.

The spec block formats — Logic/Integration:

```
Test: [criterion text]
  Given: [precondition]
  When: [action]
  Then: [expected result / assertion]
  Edge cases: [boundary values or failure states to test]
```

For Visual/Feel and UI stories, produce manual verification steps instead:
```
Manual check: [criterion text]
  Setup: [how to reach the state]
  Verify: [what to look for]
  Pass condition: [unambiguous pass description]
```

These test case specs are embedded directly into each story's `## QA Test Cases` section. The developer implements against these cases. The programmer does not write tests from scratch — QA has already defined what "done" looks like.

---

## 5. Present Stories for Review

Before writing any files, present the full story list:

```
## Stories for Epic: [name]

Story 001: [title] — Logic — ADR-NNNN
  Covers: TR-[system]-001 ([1-line summary of requirement])
  Test required: tests/unit/[system]/[slug]_test.[ext]

Story 002: [title] — Integration — ADR-MMMM
  Covers: TR-[system]-002, TR-[system]-003
  Test required: tests/integration/[system]/[slug]_test.[ext]

Story 003: [title] — Visual/Feel — ADR-NNNN
  Covers: TR-[system]-004
  Evidence required: production/qa/evidence/[slug]-evidence.md

[N stories total: N Logic, N Integration, N Visual/Feel, N UI, N Config/Data]
```

Use `AskUserQuestion`:
- Prompt: "May I write these [N] stories to `production/epics/[epic-slug]/`?"
- Options: `[A] Yes — write all [N] stories` / `[B] Not yet — I want to review or adjust first`

---

## 6. Write Story Files

For each story, write `production/epics/[epic-slug]/story-[NNN]-[slug].md`:

> **At `minimal` tier the Context/traceability inputs do not exist** (no GDD, ADR,
> TR registry, or control manifest). Fill the template from the brief instead —
> apply this mapping exactly, so every run is deterministic rather than improvised:
> - **GDD** → `design/game-brief.md`
> - **Requirement** → `Brief MVP feature N` (the feature this story implements — NOT a `TR-[system]-NNN` ID)
> - **ADR Governing Implementation / ADR Decision Summary / ADR Version** → `N/A (minimal — no ADRs)`
> - **Manifest Version** and **Control Manifest Rules (this layer)** → `N/A (minimal — no control manifest)`
> - **Engine** and **Risk** → read `docs/engine-reference/<engine>/VERSION.md`
>   (engine from `engine.name`). **Engine** is `engine.name` + `engine.version`.
>   **Risk** is the risk level that file assigns to the pinned version — its
>   post-cutoff timeline row, or its stated overall risk. If the file is missing
>   or assigns no level, write `NOT ASSESSED (no VERSION.md risk rating)` — never
>   guess a level.
>
>   > **This field is load-bearing and had no rule, so it was improvised.**
>   > `/dev-story` Phase 3 spawns the engine specialist as a mandatory secondary
>   > "when engine risk is HIGH (from the ADR or VERSION.md)". At `minimal` there
>   > is no ADR, so `VERSION.md` is the *only* source — and nothing here told this
>   > skill to read it. A story written with an invented `Risk: MEDIUM` against a
>   > `VERSION.md` rating of HIGH silently disables the specialist review. In the
>   > run that found this, that review was what caught two wrong engine defaults.
>   > Treat `NOT ASSESSED` as HIGH for the spawn decision: an unknown risk is not
>   > a low one.
> - **Engine Notes** → `none (no ADR engine-compatibility analysis at minimal)`
> - The Acceptance-Criteria source line → "From `design/game-brief.md` (the **Player goal & fail state** field + the MVP feature this story implements), scoped to this story" — derive concrete, testable ACs from what the user wrote there rather than inventing them from a bare MVP bullet
> - The **`## QA Test Cases`** section → at any tier where the QL-STORY-READY / qa-lead gate is skipped (`minimal`, or `lean`/`solo` review mode) no qa-lead specs are authored; write "*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*" rather than improvising test cases.
> - Any **Test Evidence / DoD** line is governed by `qa.level`, not this template — at `qa.level: minimal` it is **waived** (advisory, never "must exist and pass").

```markdown
# Story [NNN]: [title]

> **Epic**: [epic name]
> **Status**: Ready
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Type**: [Logic | Integration | Visual/Feel | UI | Config/Data]
> **Estimate**: [hours or t-shirt size — fill before sprint planning]
> **Manifest Version**: [date from control-manifest.md header]
> **Last Updated**: [set by /dev-story when implementation begins]

## Context

**GDD**: `design/gdd/[filename].md`
**Requirement**: `TR-[system]-NNN`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentence summary of what the ADR decided]
**ADR Version**: [the ADR's `## Last Verified` date, else its `## Date`, else `unversioned`]

**Engine**: [name + version] | **Risk**: [LOW / MEDIUM / HIGH]
**Engine Notes**: [from ADR Engine Compatibility section — post-cutoff APIs, verification required]

**Control Manifest Rules (this layer)**:
- Required: [relevant required pattern]
- Forbidden: [relevant forbidden pattern]
- Guardrail: [relevant performance guardrail]

---

## Acceptance Criteria

*From GDD `design/gdd/[filename].md`, scoped to this story:*

- [ ] [criterion 1 — directly from GDD]
- [ ] [criterion 2]
- [ ] [performance criterion if applicable]

---

## Implementation Notes

*Derived from ADR-NNNN Implementation Guidelines:*

[Specific, actionable guidance from the ADR. Do not paraphrase in ways that
change meaning. This is what the programmer reads instead of the ADR.]

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story NNN+1]: [what it handles]

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation. (At tiers where the QL-STORY-READY gate is skipped — `minimal`, or `lean`/`solo` review mode — no qa-lead specs exist; see the `minimal` mapping note above.)*

**[For Logic / Integration stories — automated test specs]:**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]

**[For Visual/Feel / UI stories — manual verification steps]:**

- **AC-1**: [criterion text]
  - Setup: [how to reach the state]
  - Verify: [what to look for]
  - Pass condition: [unambiguous pass description]

---

## Test Evidence

*Governed by `qa.level`: at `qa.level: minimal` the evidence below is **waived** (advisory, never "must exist and pass").*

**Story Type**: [type]
**Required evidence**:
- Logic: `tests/unit/[system]/[story-slug]_test.[ext]` — must exist and pass (`/story-done` checks that it EXISTS; pass/fail is established by `/gate-check` and `/smoke-check`, both later)
- Integration: `tests/integration/[system]/[story-slug]_test.[ext]` OR playtest doc
- Visual/Feel: `production/qa/evidence/[story-slug]-evidence.md` + sign-off
- UI: `production/qa/evidence/[story-slug]-evidence.md` or interaction test
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: [Story NNN-1 must be DONE, or "None"]
- Unlocks: [Story NNN+1, or "None"]
```

### Also update `production/epics/[epic-slug]/EPIC.md`

Replace the "Stories: Not yet created" line with a populated table:

```markdown
## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [title] | Logic | Ready | ADR-NNNN |
| 002 | [title] | Integration | Ready | ADR-MMMM |
```

### Also update `production/epics/index.md`

Find the row in the index table matching this epic (by epic name or slug). Update its `Stories` column from `Not yet created` to `[N] stories` (where N is the count just written). If the index file does not exist, say so in one line — `Systems index not updated: design/gdd/systems-index.md absent` — and continue. Do not skip silently: the index is what a reader consults to learn which epics have stories, so an un-updated one keeps reporting `Not yet created` for work that now exists, and nothing else would ever reveal the gap.

---

## 7. After Writing

Use `AskUserQuestion` to close with context-aware next steps:

Check:
- Are there other epics in `production/epics/` without stories yet? List them.
- Is this the last epic? If so, include `/sprint-plan` as an option.

Widget:
- Prompt: "[N] stories written to `production/epics/[epic-slug]/`. What next?"
- Options (include all that apply):
  - `[A] Start implementing — run /story-readiness [first-story-path]` (Recommended)
  - `[B] Create stories for [next-epic-slug] — run /create-stories [slug]` (only if other epics have no stories yet)
  - `[C] Plan the sprint — run /sprint-plan new` (only if all epics have stories)
  - `[D] Stop here for this session`

Note in output: "Work through stories in order — each story's `Depends on:` field tells you what must be DONE before you can start it."

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read before presenting** — load all inputs silently before showing the story list
2. **Ask once** — present all stories for the epic in one summary, not one at a time
3. **Warn on blocked stories** — flag any story with a Proposed ADR before writing
4. **Ask before writing** — get approval for the full story set before writing files
5. **No invention** — acceptance criteria come from GDDs, implementation notes from ADRs, rules from the manifest
6. **Never start implementation** — this skill stops at the story file level

After writing (or declining):

- **Verdict: COMPLETE** — [N] stories written to `production/epics/[epic-slug]/`. Run `/story-readiness` → `/dev-story` to begin implementation.
- **Verdict: BLOCKED** — user declined. No story files written.
