---
name: create-stories
description: "Breaks one epic into implementable stories with acceptance criteria. Use when the user wants stories for an epic or the next batch of work to build. Not for turning the whole design into epics."
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-stories/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh extract *), Bash(bash .claude/scripts/md-section.sh list *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,workflow,docs.density,story_granularity,qa.level,system_overrides,engine_values,engine_row`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Engine and roots** come from the `engine_values` and `engine_row` lines, never from
anything else in context. `name=unset` means no engine is set: never assume one (not
Godot, not web). The Engine field reads `not set (/setup-engine picks one; web for a new
project)`, test paths take no engine's naming, and code and test roots are the ones
`engine_row` gives (`unset` stays `unset`, per `.claude/docs/code-root-resolution.md`).

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

# Create Stories

A story is one implementable behaviour: small enough for the size
`story_granularity` sets, self-contained, and traced to a requirement and the
decision that governs it. Run this skill once per epic, in dependency order:
Foundation epics first, then Core, Feature, Presentation.

**Writes:** `production/epics/[epic-slug]/story-NNN-[slug].md`, the epic's
`EPIC.md` Stories table, and its row in `production/epics/index.md`.
**Next:** `/dev-story [story-path]` at `workflow: minimal`; otherwise
`/story-readiness [story-path]`, then `/dev-story`.

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

Checklist (copy it and tick as you go):

```
- [ ] Phase 1: epic found, tier resolved
- [ ] Phase 2: inputs loaded, each ADR's status reported
- [ ] Phase 3-4: stories drafted, typed, Ready or Blocked
- [ ] Phase 5: QA lead review run, or its skip noted
- [ ] Phase 6: story list shown, one ask to write
- [ ] Phase 7: stories, EPIC.md and index.md written (or index absence said)
- [ ] Phase 8: next step asked, closing block printed
```

## Phase 1: Epic and settings

**Tier.** `workflow` for the epic's system: the `system_overrides` row for the epic
slug (its GDD system) if there is one, else the project value.

**`story_granularity`** sets each story's acceptance-criteria load. Group or split
criteria to hit it:

| `story_granularity` | ACs per story | Size |
|---|---|---|
| `coarse` (default, `rigor: minimal`) | 5-10 | a whole feature, multi-day |
| `balanced` (`rigor: standard`) | 2-4 | one task, about one session |
| `fine` | 1 | one criterion; the story name restates it |

**`docs.density`** sets the depth of each story's prose (context, implementation
notes, ADR summary), never the AC count or the AC text: `terse` (default) = bullet
notes, no preamble; `balanced` = a short context paragraph plus notes; `thorough` =
full context, guidance and ADR rationale. The TR-ID, ADR Version and acceptance
criteria are never trimmed.

**Which epic.** The text typed after the skill name, with any `--review <mode>`
pair removed: an epic slug (`combat`) or a path (`production/epics/combat/EPIC.md`).
With nothing typed, the epic the user's request names ("the loot epic") counts as
named.

- **Named, but no `EPIC.md` there:** at `standard` and `full`, stop: "No epic at
  `production/epics/[slug]/EPIC.md`. Run `/create-epics` to create it, or check the
  slug with `ls production/epics/`." Never decompose from a guess. At `minimal`,
  say this tier needs no `/create-epics` epic, take Phase 2's `minimal` branch, and
  name the slug it uses.
- **Blank, at `minimal`:** take Phase 2's `minimal` branch.
- **Blank, at `standard` or `full`:** list `production/epics/*/EPIC.md` with each
  status, then ask: "Which epic would you like to break into stories?" with one
  option per epic. **No epics found:** stop and say "No epics found under
  `production/epics/`. Run `/create-epics layer: foundation` first." Never ask a
  question with no options.

## Phase 2: Load the inputs

### `minimal`: build the epic from the brief

1. **No `design/game-brief.md`:** stop. "There is no brief to build stories from
   yet: run `/prototype` and say the game in one line; it writes the one-page brief and a
   first build (`/brainstorm` first if you have no idea yet)." When the code root
   already holds the game (10 or more source files), name `/reverse-document design
   [code root]` instead.
2. Read `design/game-brief.md` in full (one page).
3. **The epic.** `<slug>` is the brief's working title, slugified (`mvp` if it has
   none), or the epic the user named.
   - `production/epics/<slug>/EPIC.md` exists: it is the epic. Use its scope, still
     traced to the brief, and never rewrite it.
   - It does not: draft one, written in Phase 7 only after the Phase 6 ask names
     it. Goal = the brief's pitch; scope = its Features list (MVP in briefs from
     before 1.3.0); order = its **Build order**. Keep it terse.
   - Stories already in the folder (a return visit): never rewrite an existing
     `story-*.md`. Add stories only for brief items they do not cover, or new ones
     the user names, and number on from the highest existing `story-NNN`.
4. **One story per Features item not built yet (`[ ]`), in Build order**, each
   traced to the brief. An item marked `[x]` is built already (the one-shot made
   it): it gets no story, and the Phase 6 summary names it. An older brief's MVP
   items are all unbuilt. No story is blocked on ADR grounds: this tier has none.
   **Nothing left to build** (every Features item `[x]` or cut, and no `thin
   stand-in` or `later` system without its stories): never write 0 stories. A
   grown game is often here, since the one-shot built every item. Say "Every
   feature in the brief is built." Ask what to add next, in their own words. Then
   ask "May I add these to the brief's Features as `[ ]` items: <each item, one
   line>?" and write them into `design/game-brief.md` only on a yes. They are
   now the unbuilt items: go on from here with them. With nobody to ask (the
   autonomous automation mode), write nothing and stop with that line and "say
   what to add next".
   A `## Your systems` list changes the order:
   - **No `## Your systems` list** (or only its blank line): Build order.
   - **A `## Your systems` list** (lines `- <system> · in the slice`, `· thin
     stand-in` or `· later`, perhaps ending *(guessed)*): skeleton first, so the
     whole game stands up thin before any one part grows. Three steps, in this
     order:
     1. **Core:** the unbuilt Features items for the core loop and the `in the
        slice` systems, in Build order.
     2. **Every system thin:** one story for each `later` system that makes it
        there and wired to the rest, at its simplest, in the list's order; an
        unbuilt `(thin stand-in)` Features item goes here too.
     3. **Deepen, one system at a time:** one story for each `thin stand-in` and
        `later` system that builds it out in full, in the list's order, one system
        per story. Its criteria come from that system's design doc,
        `design/gdd/<system>.md`, never from its bare name: with no doc yet, the
        one criterion is "built out as `design/gdd/<system>.md` describes", and
        `/design-system <system>` writes that doc before the story is built.

     Each story's header names its step: `> **Build step**: core`, `thin —
     <system>` or `deepen — <system>`. A Features item that names a system goes in
     that system's step. Thin and deepen stories for a `later` system build what
     Out of scope put off: the Phase 6 list says so, and the person can drop any.

Read no GDD, control manifest, TR registry or ADR at `minimal`. Go to Phase 3.

### `standard` and `full`: the epic and what governs it

1. **The epic:** `production/epics/[epic-slug]/EPIC.md` in full (its layer, GDD,
   governing ADRs, and the GDD Requirements table with TR-IDs).
2. **The GDD:** its sections by heading, never the whole file:
   `bash .claude/scripts/md-section.sh extract design/gdd/[file].md "Acceptance Criteria"`,
   and the same for `Formulas`, `Edge Cases` and `Detailed Design` (exit 3: try
   `Detailed Rules`, the design standard's name for the same section); at `full`
   the other required sections too (`list` shows the headings).
3. **The control manifest:** the epic's layer only, and the version:
   `bash .claude/scripts/md-section.sh extract docs/architecture/control-manifest.md "[Layer] Layer Rules"`,
   plus its `Manifest Version` line.
4. **The TR registry:** this system's entries only: in
   `docs/architecture/tr-registry.yaml`, the lines matching `system: <slug>\s*$`,
   with each entry's `id` above and its text below. The anchor keeps `combat` from
   matching `combat-ai`; `\s*` takes a Windows line ending.
5. **The ADRs**, every one the epic names (governing, or in its requirements table,
   Proposed ones included), in one call:
   ```
   bash .claude/scripts/adr-status.sh ADR-0001 ADR-0003 ...
   ```
   Each row gives the status, layer, `version` (the story's ADR Version stamp),
   `depends_on`, and missing sections. Then read only `Summary`, `Decision` (its
   Implementation Guidelines inside) and `Engine Compatibility` of each, with
   `md-section.sh extract`. Engine Notes is a story field taken from Engine
   Compatibility, not an ADR section. An ADR with none of these sections predates
   the template: read it once, and flag it for `/architecture-decision retrofit
   [file]`.

**A named ADR with no file** (`NOT_FOUND`):

- `full`: stop before decomposing any story.
- `standard`: stop only when it is critical (Foundation layer); otherwise warn, go
  on, and write the stories it governs as `Blocked` until it exists.
- On stopping: "Epic references [ADR-NNNN: title] but no file for it was found in
  `docs/architecture/`. Check the epic's Governing ADRs list, or run
  `/architecture-decision` to create it. Cannot create stories until the
  referenced ADR files exist."

**Report before drafting**, with the real state, every ADR on its own with its
status:

```
Loaded: epic [name] · GDD [file] · manifest v[date], [layer] rules
ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0003 Accepted · ADR-0004 Proposed · [ADR-NNNN missing]
```

Never say "all present" when one is missing, or name a manifest version when there
is none.

## Phase 3: Type each story

| Type | When its criteria reference |
|---|---|
| **Logic** | formulas, thresholds, state transitions, AI decisions, calculations |
| **Integration** | two or more systems, signals across boundaries, save/load round-trips |
| **Visual/Feel** | animation, VFX, "feels responsive", timing, screen shake, audio sync |
| **UI** | menus, HUD, buttons, screens, dialogue boxes, tooltips |
| **Config/Data** | balance values and data files only, no new logic |

A mixed story takes the type with the highest implementation risk. The type sets
the evidence `/story-done` needs.

## Phase 4: Draft the stories

Group the requirements that need the same core implementation into one story, at
the `story_granularity` load. Order: foundation behaviour first, edge cases later,
UI last. For each story:

- **Requirement:** the TR-ID from the registry, matched through the epic's GDD
  Requirements table. Only when no entry matches, write `TR-[system]-???` and say
  so.
- **ADR:** the one that governs how to build it (the requirements table names it).
  - `Accepted`: embed it.
  - `Proposed`: `Status: Blocked`, with "BLOCKED: ADR-NNNN is Proposed — accept it
    with `/architecture-decision accept ADR-NNNN` once decided".
  - `Deprecated` or `Superseded`: `Status: Blocked`, with "BLOCKED: ADR-NNNN is
    [status] — point the story at [successor] (edit its ADR field;
    `/create-stories` never rewrites an existing story) before implementing".
  - An `Accepted` ADR whose `depends_on` names an ADR that is not Accepted: Blocked
    the same way, naming that ADR.
  - Several apply: list them all, the most direct first.
  - None applies: `ADR: N/A — [reason]`, e.g. "pure data configuration". Never
    blank: blank means unchecked.
- **ADR Version:** the story's **ADR Version** is the ADR's `## Last Verified`
  date, else its `## Date`, else `unversioned` (the `version` column). `/dev-story`
  trusts the story's ADR summary while this still matches the ADR.
- **Engine risk:** from the ADR's Engine Compatibility (its knowledge risk).
- **Estimate:** propose a t-shirt size from the criteria and the files the story
  touches: `S` (a few hours), `M` (about a day) or `L` (several days). It is a
  proposal: Phase 6 shows it and the user can change it. `/story-readiness` fails
  a story whose Estimate is still the template's bracket, so never leave it.

## Phase 5: QA lead review

Read the `review_gate` line above. `skill-gates=skip` (solo or lean): no review;
note "QL-STORY-READY skipped — [Solo | Lean] mode" in the Phase 6 list and the
closing block. `skill-gates=run`: read `references/qa-lead-gate.md` and
`.claude/docs/director-gates.md`, and run it now, before the Phase 6 ask. On a skip,
do not load it.

## Phase 6: Show the stories, ask once

```
## Stories for Epic: [name]
ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0004 Proposed   (every ADR, from Phase 2)

Story 001: [title] — Logic — ADR-0001 — Ready — Estimate M
  Covers: TR-[system]-001 ([one-line requirement])
  Test required: [test root]/unit/[system]/[the engine's test file name]

Story 002: [title] — Integration — ADR-0004 — BLOCKED (ADR-0004 is Proposed) — Estimate L
  Covers: TR-[system]-002, TR-[system]-003
  Test required: [test root]/integration/[system]/[the engine's test file name]

Story 003: [title] — Visual/Feel — ADR-0001 — Ready — Estimate S
  Covers: TR-[system]-004
  Evidence required: retained screenshot + sign-off in production/qa/evidence/[slug]-evidence.md

[N stories: N Logic, N Integration, N Visual/Feel, N UI, N Config/Data; N Blocked]
QL-STORY-READY: [skipped — Solo mode | its verdicts]
```

At `qa.level: minimal`, a Logic or Integration story's `Test required:` line reads
`Test: waived at qa.level minimal` instead: `/dev-story` writes no test there.

At `minimal`, each line traces to `Brief MVP feature N` (N is the item's number in
the brief's Features list), there is no ADRs line, and there is one story per
unbuilt Features item: no extra stories for brief items outside the list, except
the thin and deepen stories a `## Your systems` list adds. Those trace to `Brief
Your systems: <system>`, and the list is shown under three headings in order,
`Core`, `Every system thin` and `Deepen, one system at a time`, with one line under
the last: "Each deepen story starts with `/design-system <system>` when that system
has no design doc yet." Then
ask: "May I write these [N] stories to `production/epics/[epic-slug]/`, and
[create | update] `production/epics/[epic-slug]/EPIC.md` and update
`production/epics/index.md`?" Options: Yes, write all [N] / Not yet, I want to
adjust first; an adjustment can change any estimate. Name every file Phase 7 touches: *create* `EPIC.md` only when it
does not exist, and leave `index.md` out when it does not exist. Write nothing
before the yes.

## Phase 7: Write

### The story files

**Each story** is `production/epics/[epic-slug]/story-[NNN]-[slug].md`, laid out
as `.claude/docs/templates/story.md`. Never reuse a story number. Write each file
as a file, never through a shell command: a shell write skips the project's write
checks.

At `minimal` there is no GDD, ADR, TR registry or manifest. Fill these fields
exactly:

| Field | Value at `minimal` |
|---|---|
| GDD | `design/game-brief.md` |
| Requirement | `Brief MVP feature N`, or `Brief Your systems: <system>` for a thin or deepen story; never a TR-ID |
| Build step | with a `## Your systems` list only: `core`, `thin — <system>` or `deepen — <system>`, as Phase 2 set it |
| ADR Governing Implementation, ADR Decision Summary, ADR Version | `N/A (minimal — no ADRs)` |
| Manifest Version, Control Manifest Rules | `N/A (minimal — no control manifest)` |
| Engine | `engine.name` + `engine.version`; with no engine set, `not set (/setup-engine picks one; web for a new project)` |
| Risk | the level `docs/engine-reference/<engine>/VERSION.md` gives the pinned version (its timeline row, or its overall rating). No file or no level: `NOT ASSESSED (no VERSION.md risk rating)`, never a guess. `/dev-story` reads NOT ASSESSED as HIGH |
| Engine Notes | `none (no ADR engine-compatibility analysis at minimal)` |
| Acceptance Criteria | from the brief's **Goal & fail state** (Player goal & fail state in older briefs) and the Features item, made concrete and testable; never invented from a bare bullet |

At every tier:
- **QA Test Cases:** when the review was skipped, write
  `*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*`.
  Never improvise test cases.
- **Test Evidence:** `qa.level` governs it. At `qa.level: minimal` tests are
  waived (advisory), but a Visual/Feel or UI story's retained screenshot is not.
- **Estimate:** the size from Phase 6, with any change the user made.
- **Dependencies:** name each story this one needs by its path.
- **Files:** the code and test files the story is planned to create or change,
  under the code root and test root `engine_row` gives, each test named as
  `.claude/rules/test-standards.md` says for the engine. A root that is `unset`
  is written `[code root unset: no engine set]` or `[test root unset: no engine set]`,
  never `src/` or `tests/` by guess. `/dev-story` replaces them with the real list.

### `EPIC.md`

At `minimal` with none yet, write the Phase 2 draft with the table
below. Otherwise replace its "Stories: Not yet created" line with the table, or on
a return visit append one row per new story and leave the rest of the file as it
is:

```markdown
## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [title] | Logic | Ready | ADR-0001 |
| 002 | [title] | Integration | Blocked | ADR-0004 |
```

### `production/epics/index.md`

Set the epic's `Stories` cell to `[N] stories`,
the epic's total after this run. When the file does not exist, say so:
`Epics index not updated: production/epics/index.md absent`.

## Phase 8: Close

Say "[N] stories written to `production/epics/[epic-slug]/`." and print the
next command as a line: "Type `/dev-story [first-story-path]` to build the first
one." at `minimal`, "Run `/story-readiness [first-story-path]` first." otherwise.
`/dev-story` and `/story-done` start only when the person types them, so never offer to start one as an option: print it as a line to type.
If other epics in `production/epics/` have no stories, list them. Then, when an
option below other than stopping applies, ask "What next?" with those that apply:

- Create stories for [next epic]: `/create-stories [slug]` (only when an epic has
  none)
- Plan the sprint: `/sprint-plan new` (only when every epic has stories; never at
  `minimal`, where the brief's build order is the plan)
- Stop here for this session

Never start implementation or write code: this skill stops at the story files.
Acceptance criteria come from the GDD (the brief at `minimal`), implementation
notes from the ADRs, rules from the manifest; none are invented.

**The run's last reply ends with this block**, after the question above is
answered (repeat it if you showed it earlier):

```
Verdict: COMPLETE — [N] stories written to production/epics/[epic-slug]/ ([N] Ready, [N] Blocked)
Review: [QL-STORY-READY skipped — Solo mode | skipped — Lean mode | its verdicts]
Index: [production/epics/index.md updated | Epics index not updated: production/epics/index.md absent]
Next step: [/dev-story [first-story-path] | /story-readiness [first-story-path]]
```

When the user declines the write: `Verdict: BLOCKED — user declined. No story
files written.`
