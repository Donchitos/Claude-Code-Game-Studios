---
name: create-epics
description: "Turns the GDDs and architecture into epics, one per architectural module. Use when the user wants to break the game into epics or plan the work before writing stories. Not for splitting one epic into stories."
argument-hint: "[system-name | layer: foundation|core|feature|presentation | all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-epics/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/gdd-structure-check.sh*), Bash(bash .claude/scripts/adr-status.sh*), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/write-guard.sh overwrite *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,workflow,docs.density,engine_values,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

# Create Epics

An epic is a bounded body of work for one architectural module: **what** gets built
and which decisions govern it. How to build it is for the stories. Run it once per
layer as development reaches that layer: Feature epics written before Core is
nearly done describe a design that will have changed.

**Writes:** `production/epics/[epic-slug]/EPIC.md` per epic and its row in
`production/epics/index.md`, each after its own yes.
**Next:** `/create-stories [epic-slug]` per epic. This skill never writes a story.

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

Checklist (copy it and tick as you go):

```
- [ ] Phase 1: scope and tier
- [ ] Phase 2: inputs loaded and reported
- [ ] Phase 3: each epic shown, "Shall I create Epic: …?" asked one at a time
- [ ] Phase 4: producer review run, or its skip noted
- [ ] Phase 5: each EPIC.md and index row written after its own yes
- [ ] Phase 6: closing block printed
```

## Phase 1: Scope and tier

The text typed after the skill name, with any `--review <mode>` pair removed:

- `all`: every system, in layer order.
- `layer: foundation` (or `core`, `feature`, `presentation`): that layer only.
- a system name: that system only.
- nothing: the request's own words when they name a layer or system ("foundation
  and core"); else ask "Which layer or system would you like epics for?"

**Tier.** The project's `workflow` value sets what is required (Phase 2). Each
in-scope system's own GDD bar comes from its `system_overrides` row, when it has one.

**At `minimal`, tell the user first:** this step is optional at this tier, because
`/create-stories` builds the epic from `design/game-brief.md` by itself. Then go on
when they asked for epics.

## Phase 2: Load the inputs

### `minimal`: the brief

Read `design/game-brief.md`. None: stop, "No `design/game-brief.md` — run `/start`
or `/brainstorm` first." Never ask for GDDs, a systems index, an architecture
document, ADRs, a TR registry or a control manifest, and never send the user to
`/design-system`, `/map-systems` or `/create-architecture` first: this tier has none
by design.

Report first, word for word:

```
Loaded: design/game-brief.md · engine [name version from the engine_values line]
At minimal this step is optional: /create-stories builds the epic from the brief by itself.
```

The epics come from the brief's Features list (MVP in older briefs), in its
**Build order**. A short
brief is one epic, slugged from the brief's working title (the slug `/create-stories`
uses when nothing is typed). When the user asks for the work grouped, make one epic
per group of features that ship together. Every epic names its slug, since
`/create-stories` needs it typed.

### `standard` and `full`: the design and the architecture

1. **The system GDDs.** `bash .claude/scripts/gdd-structure-check.sh` lists every
   system GDD; the game concept, systems index, pillars, cross-reviews and the other
   non-system documents are left out for you. Their count is **N**. N is 0: stop,
   "No system GDDs found in `design/gdd/` — run `/design-system` first."
2. **What is in scope.** Each GDD's `## Summary` quick reference gives its layer and
   priority. A GDD with no Summary (older GDDs predate it) takes its layer from
   `design/gdd/systems-index.md`. Never treat an absent `## Summary` as an absent system:
   it never drops one from scope.
3. **The architecture.** `docs/architecture/architecture.md` is required at both
   tiers: missing, stop with
   "No `docs/architecture/architecture.md` — run `/create-architecture` first." Never invent module boundaries.
4. **For in-scope systems only**, by section, never whole:
   - each GDD's Overview and Acceptance Criteria
     (`bash .claude/scripts/md-section.sh extract design/gdd/<file>.md "Overview"`);
   - `bash .claude/scripts/adr-status.sh` for every ADR's status, layer and missing
     sections; then the GDD Requirements Addressed, Decision and Engine
     Compatibility sections of the ADRs that cover in-scope systems;
   - `docs/architecture/tr-registry.yaml`: the entries whose `system:` is an
     in-scope system;
   - the control manifest's `Manifest Version` line (read if present at `standard`,
     required at `full`);
   - `docs/engine-reference/<engine>/VERSION.md` for the engine's risk levels.

Report before defining anything, with the real state:

```
Loaded: [N] system GDDs, [n] in scope ([names]) · [M] ADRs ([A] Accepted, [P] Proposed) · manifest v[date | absent] · engine [name version from the engine_values line]
```

At `full`, every in-scope GDD needs all 8 sections and Approved status, and the TR
registry and control manifest are required. At `standard`, the GDDs need their 5
required sections, and only critical (Foundation-layer) ADRs are expected.

## Phase 3: Define each epic, ask one at a time

Process by layer: Foundation, then Core, Feature, Presentation; within a layer, the
systems index order (at `minimal`, the brief's Build order). For each system, its
module from `architecture.md` (at `minimal`, the brief's feature group).

**Requirement coverage** (not at `minimal`). Each TR-ID of the system is:

- **covered** when an **Accepted** ADR addresses it;
- **untraced** otherwise. A requirement whose only ADR is `Proposed` (or any other
  status) is untraced, never covered: its row reads `❌ No ADR (ADR-NNNN Proposed)`,
  so `/create-stories` still sees that ADR and blocks its story.

Untraced requirements are listed under **Untraced Requirements**. The ⚠️ warning
below is for each untraced requirement at `full`, and only for untraced
Foundation-layer requirements at `standard`; any other untraced requirement at
`standard` is listed as information, with no warning.

```
## Epic: [System Name]
**Layer**: [Foundation | Core | Feature | Presentation]
**GDD**: design/gdd/[file].md   (at minimal: design/game-brief.md, Features [list])
**Architecture Module**: [module]
**Governing ADRs**: [Accepted ADRs, or "none"]
**Engine Risk**: [LOW | MEDIUM | HIGH — the highest among governing ADRs, else VERSION.md's]
**Requirements covered by Accepted ADRs**: [n / total]
**Untraced Requirements**: [TR-IDs with why, or "None"]
```

The warning, when it applies: "⚠️ [N] requirements in [system] have no Accepted ADR.
Their stories will be written with no governing ADR, or Blocked on a Proposed one.
Run `/architecture-decision` first if they need a decision, or go on and accept the
gap."

Then ask, **for this epic alone**: "Shall I create Epic: [name]?" Options: Yes,
create it / Skip this epic / Pause — I need to write ADRs first. Show and ask the
next epic only after this answer. Never fold several epics into one question.

A yes covers the epic it answers, and only that one, even when it is worded for all
("all of it", "go ahead with everything"): an epic is approved on sight. Show the
next epic's block and ask again, until every epic in scope has been shown and
answered.

## Phase 4: Producer review

Read the `review_gate` line above. `skill-gates=skip` (solo or lean): no agent; note
`PR-EPIC skipped — [Solo | Lean] mode` in the reply and the closing block.
`skill-gates=run`: read `references/pr-epic-gate.md` and
`.claude/docs/director-gates.md`, and run it now, after every epic in scope is
defined and before any write. On a skip, do not load it.

## Phase 5: Write each epic

For each epic the user said yes to, in order:

**Already has an `EPIC.md`:** never overwrite it. Ask "An EPIC.md already exists for
[name]. Update it in place, or skip it?" Options: Update in place / Skip this epic.
An update edits only what this skill owns (the header fields other than Stories,
Overview, Governing ADRs, GDD Requirements, Definition of Done) and leaves the
`**Stories**` line and any `## Stories` table as they are: `/create-stories` wrote
them, and resetting them orphans the stories already there.

**New:** ask "May I write `production/epics/[epic-slug]/EPIC.md` and add its row to
`production/epics/index.md`[, creating it]?" This is its own ask, one per epic, after
the Phase 3 yes: that yes approved the epic, not the write. Write only on an explicit
yes to it. Right
before writing, run `bash .claude/scripts/write-guard.sh overwrite
production/epics/[epic-slug]/EPIC.md`. It always prints a `checked` row; an
`OVERWRITE` row back means the file exists after all, so write nothing and ask the
update question instead.

`docs.density` sets the depth of the Overview (`terse` bullets, `balanced` a short
paragraph, `thorough` full prose with ADR rationale and risks); the tables stay
whole at every density.

```markdown
# Epic: [System Name]

> **Layer**: [Foundation | Core | Feature | Presentation]
> **GDD**: design/gdd/[file].md
> **Architecture Module**: [module]
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories [epic-slug]`

## Overview

[What this epic implements, from the GDD Overview and the module's responsibilities]

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-NNNN: [title] | [one line] | LOW/MEDIUM/HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-[system]-001 | [requirement text from the registry] | ADR-NNNN ✅ |
| TR-[system]-002 | [requirement text] | ❌ No ADR (ADR-NNNN Proposed) |

## Definition of Done

- Every story implemented, reviewed and closed with `/story-done`
- Every acceptance criterion of design/gdd/[file].md verified
- Logic and Integration stories have passing tests in the test root
- Visual/Feel and UI stories have retained screenshots in `production/qa/evidence/`
  (a lead sign-off too for Visual/Feel)
```

At `minimal`, the GDD line names `design/game-brief.md`, the Governing ADRs and GDD
Requirements tables are left out, and a **Scope** list holds the epic's
Features items in Build order.

**`production/epics/index.md`:** one row per epic. An epic that already has a row
keeps it: update it in place, never add a second row, never reset its Stories cell.

```markdown
# Epics Index

Last Updated: [date]
Engine: [name version]

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [name] | [layer] | [system] | [file] | Not yet created | Ready |
```

## Phase 6: Close

At `standard` and `full`, once Foundation and Core epics exist, add: "Foundation and
Core epics are what the Pre-Production → Production gate needs. `/gate-check
production` checks readiness." Never at `minimal`.

Every epic's content comes from the GDDs, ADRs and architecture docs (the brief at
`minimal`); none is invented.

**The run's last reply ends with this block** (repeat it if you showed it earlier):

```
Verdict: COMPLETE — [N] epics written: [slugs]
Review: [PR-EPIC skipped — Solo mode | skipped — Lean mode | its verdict]
Index: production/epics/index.md [created | updated]
Next step: /create-stories [first-epic-slug]
```

When the user skipped or declined every epic: `Verdict: BLOCKED — no epic written
([why])`. No in-scope system found: `Verdict: BLOCKED — no eligible systems in
[scope]`.
