---
name: story-readiness
description: "Checks whether a story is ready to implement: clear acceptance criteria, no open questions, valid ADR and dependencies. Use when the user asks if a story, or the sprint's stories, are ready to start or build."
argument-hint: "[story-file-path or 'all' or 'sprint'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-readiness/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/adr-status.sh *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,workflow,qa.level,gate_level,story_granularity,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

# Story Readiness

Checks that a story file holds everything a developer needs before writing code:
no design questions mid-build, no guessing, no vague acceptance criteria.

**Read-only.** It never writes or edits a file. It reports, and offers to draft
fixes in the conversation.

**Verdicts**, one per story. The first that matches wins, in this order:

1. **BLOCKED**: a finding the reader can clear. A referenced ADR is missing,
   `Proposed`, `Deprecated` or `Superseded`; a dependency story is missing or
   `Draft`; or a criterion holds an UNRESOLVED design question with no owner.
2. **NEEDS WORK**: a blocking checklist item fails. The story can be fixed now.
3. **NOT ASSESSED**: the story could not be evaluated. The file is unreadable,
   a referenced ADR has no readable `## Status`, or the design document it names
   cannot be found. Name what could not be read. It is never READY: a story
   nobody could check has not been shown ready. It ranks below the two failures,
   because a known blocker is more useful than an unknown.
4. **READY**: every item passes, is N/A with a reason, or is advisory. Advisory
   gaps are still listed.

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

## Phase 1: Scope

The scope is the text typed after the skill name, with any `--review <mode>` pair
removed. What remains is one value; a path may contain spaces. With nothing typed,
the story, epic or sprint the user's request names is the scope.

- **A story path**: that story.
- **`sprint`**: the stories the current sprint lists (Phase 2 reads them).
- **`all`**: every `story-*.md` under `production/epics/`.
- **An epic** (a slug or its folder): the `story-*.md` files in that folder.
- **Blank**: Ask: "What would you like to check?" Options: A specific story file /
  All stories in the current sprint / All stories in production/epics/ / The
  stories of one epic.

**Zero stories in scope: stop with `NOT ASSESSED — no stories in scope`.** Name the
scope and the path that was empty, and route to `/create-stories` (at `standard`
and `full`, `/create-epics` first). Never print a `Ready: 0 / Needs Work: 0` summary
over an empty list: it reads as a clean result. For `sprint`, "no sprint plan
found" and "the sprint plan lists no stories" are different reports; say which.

Say "Checking [N] story files." before going on.

## Phase 2: Facts, read once for the run

1. **Stories.** Run the story helper over the scope, with the `story_granularity`
   resolved above:
   ```
   bash .claude/scripts/story-facts.sh --lint --granularity <story_granularity> [--sprint | --all | <path> ...]
   ```
   Each `STORY` row gives a story's status, type, layer, estimate, TR-IDs, ADRs,
   acceptance-criteria count, test-evidence line and dependencies. Each `LINT` row
   is a rule the story trips. Rows are observations; the verdict is yours. Exit 3
   means a file was not found. With `NOT_FOUND` rows, each names a sprint `file:`
   entry or a path that is not a file: report each as a missing story and check
   the rest. With no `NOT_FOUND` row and `--sprint`, there is no
   `production/sprint-status.yaml`: report "no sprint plan found". Read each story file too: the testability, scope and
   asset items below need its words.
2. **ADRs.** One call gives every ADR's status and layer:
   `bash .claude/scripts/adr-status.sh`. A `no_status` or `UNFILLED` status is a
   malformed ADR: never treat an absent status as a failed one (route:
   `/architecture-decision retrofit [file]`). An ADR a story cites with no row is missing.
3. **Control manifest.** Only its `Manifest Version` line in
   `docs/architecture/control-manifest.md`. Missing file: note it once.
4. **TR registry.** Look up each story's TR-IDs, with their `status`, in
   `docs/architecture/tr-registry.yaml`. Missing file: note it once; the TR-ID
   item passes for every story.
5. **Sprint priority** (`sprint` scope): which stories are Must Have and Should
   Have, from the newest plan in `production/sprints/`.

**Tier per story.** `workflow` is resolved per story: use the `system_overrides`
row for the story's system (the GDD filename stem of its `GDD:` path; the `[system]`
of a `TR-[system]-NNN` ID only when there is no GDD path), else the project value.
Stories in one run can sit at different tiers.

## Phase 3: The checklist

Check every item for every story. The tier decides which groups block:

| Group | `full` | `standard` | `minimal` |
|---|---|---|---|
| Design Completeness | blocks | blocks | blocks; `design/game-brief.md` stands in for the GDD |
| Architecture Completeness | blocks | the ADR status item blocks; the rest advisory unless it concerns a critical ADR | N/A, except the ADR status item |
| Scope Clarity | blocks | blocks | blocks, except Estimate: advisory (no sprint plan to size for) |
| Open Questions | blocks | blocks | blocks |
| Asset References | blocks | blocks | blocks |
| Definition of Done | blocks | blocks | blocks; the test evidence item follows `qa.level` |

An **advisory** item that fails is listed under Gaps with its Fix, and never
lowers READY by itself.

### Design Completeness

- [ ] **Requirement traced**: the story names its `design/gdd/` file and quotes or
  links a specific rule or criterion from it, not just the file name. At
  `minimal`: `design/game-brief.md` and the Features item the story implements.
  A named design document that does not exist: NOT ASSESSED.
- [ ] **Self-contained**: the acceptance criteria say what done means without
  opening the GDD.
- [ ] **Testable**: each criterion is a specific, observable condition. Not:
  "Implement the jump mechanic." Yes: "Jump reaches 5 units within 0.3 seconds
  when held." A criterion a unit test can set up (any input values) is testable,
  even when the shipped data never reaches that case.
- [ ] **No judgement calls**: "feels responsive" or "looks good" fails for Logic,
  Integration, UI and Config/Data. For Visual/Feel such criteria are expected:
  pass when the criterion names an evidence file such as
  `production/qa/evidence/[slug]-evidence.md`, NEEDS WORK when it names none.

### Architecture Completeness

- [ ] **ADR status**, at every tier: each ADR the story cites, by the Phase 2
  table.
  - `Accepted`: pass.
  - `Proposed`: BLOCKED. Fix: `BLOCKED: ADR-NNNN is Proposed — accept it with
    /architecture-decision accept ADR-NNNN once decided`.
  - `Deprecated` or `Superseded`: BLOCKED. Fix: `BLOCKED: ADR-NNNN is [status] —
    point the story at [successor] (edit its ADR field;
    /create-stories never rewrites an existing story)`.
  - No such ADR file: BLOCKED.
  - No readable status: NOT ASSESSED for this item; name the file.
  At `standard`, a **critical** ADR (its `layer` is Foundation, or missing) that
  is missing or Proposed blocks; for other ADRs the items below are advisory.
- [ ] **ADR cited or N/A stated**: an ADR, or an explicit N/A with a reason
  (`ADR: N/A — [reason]`, or `N/A (minimal — no ADRs)`). Blank fails.
- [ ] **TR-ID valid**: each `TR-[system]-NNN` is in the registry with `status:
  active`. `deprecated` or `superseded-by` (quoted or not): NEEDS WORK, Fix: point
  the story at the current requirement. Not in the registry: NEEDS WORK (the story
  may predate it, or the registry needs `/architecture-review`). Passes with no
  TR-ID, or no registry.
- [ ] **Manifest Version current**: the story's `Manifest Version` against the
  manifest's. Older: a gap, because rules added since may apply. It stays a gap
  even when the new rules look unrelated: say what changed, and leave the call to
  the user. At `full` it is NEEDS WORK whatever the new rules cover; at
  `standard` it is advisory. Fix, all three steps: "Review the manifest rules added since
  [story's date]; update the story's rules if any apply; then set its Manifest
  Version to [current date]." Passes with no `Manifest Version` field, or no
  manifest.
- [ ] **Engine notes**: post-cutoff engine APIs the story touches have notes or a
  verification step, or the story states "N/A — no engine API involved".
- [ ] **Manifest rules noted**: the layer's rules are listed, or "N/A — manifest
  not yet created". Passes when there is no manifest.

### Scope Clarity

- [ ] **Estimate**: hours, points or a t-shirt size. `unfilled Estimate` (still the
  template's bracket) fails. Advisory at `minimal`.
- [ ] **Out of scope stated**: an Out of Scope section, or wording that leaves the
  boundary unambiguous.
- [ ] **Dependencies listed**: each story this one needs, or "None" stated.

### Open Questions

- [ ] **No open markers**: no `marker` rows (TBD, TODO or UNRESOLVED as whole
  words in capitals). A `?` is not a marker: a formula like `crit ? 2 : 1` passes.
  A criterion written as an open question still fails Testable.
- [ ] **Dependencies exist and are not Draft**: a dependency story that is missing
  or `Draft` makes the story BLOCKED. `Story NNN` means that number in the same
  epic folder; a path names one exactly.

### Asset References

- [ ] **Assets the story uses exist**: paths under `assets/`, or with `.png`,
  `.jpg`, `.svg`, `.wav`, `.ogg`, `.mp3`, `.glb`, `.gltf`, `.tres`, `.tscn` or
  `.res`, that the story reads or builds on. A file the story says it will create
  (a new scene, a new data file) is not checked. Missing: NEEDS WORK; name the
  path. Report "Referenced assets verified: [N] found", or "No asset references".
  Existence only.

### Definition of Done

- [ ] **Enough acceptance criteria**: no `ac_below_min` row. The minimums follow
  `story_granularity`, because `/create-stories` writes to it:

  | `story_granularity` | Logic, Integration | Visual/Feel, UI | Config/Data |
  |---|---|---|---|
  | `coarse` | 3 | 2 | 1 |
  | `balanced` | 2 | 2 | 1 |
  | `fine` | 1 | 1 | 1 |

- [ ] **Performance noted**: a story touching the gameplay loop, rendering or
  physics states a budget, or "no performance impact expected — [reason]".
- [ ] **Type declared**: no `type_missing` or `type_unknown` row. Fix: add
  `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]` to the header.
- [ ] **Test evidence clear**: a `## Test Evidence` section saying where evidence
  goes: the test file for Logic and Integration; the retained screenshot of each
  screen under `production/qa/evidence/` for UI; that plus
  `production/qa/evidence/[story-slug]-evidence.md` for Visual/Feel.
  - At `qa.level: minimal`, Logic, Integration and Config/Data pass: tests are
    waived. List no gap, and add no note, about a missing test file, `tests/`
    folder or test runner. UI and
    Visual/Feel are still checked: their screenshot is required at every level.
  - Otherwise the `gate_level` line above sets the level for the story's type.
    `blocking`: a missing section is NEEDS WORK. `advisory`: a listed gap only.
    Fix: add `## Test Evidence` with the evidence location for the story's type.

## Phase 4: Verdict

Apply the order at the top to each story. A BLOCKED story may also have NEEDS WORK
items: list both.

## Phase 5: QA lead review

Read the `review_gate` line above. `skill-gates=skip` (solo or lean): skip it, and
the reply says "QL-STORY-READY skipped — [Solo | Lean] mode". `skill-gates=run`:
read `references/qa-lead-gate.md` and `.claude/docs/director-gates.md`, and run it
before reporting. On a skip, do not load it.

## Phase 6: Report and close

One story:

```
## Story Readiness: [story title]
File: [path]
Verdict: [READY / NEEDS WORK / BLOCKED / NOT ASSESSED]

### Passing Checks (N/[total])
Design Completeness: [passing items]
Architecture Completeness: [passing items, or "N/A at minimal (ADR status checked)"]
Scope Clarity: [passing items]
Open Questions: [passing items]
Asset References: [passing items, or "no asset references"]
Definition of Done: [passing items]

### Gaps
- [Checklist item]: [what is missing or wrong]
  Fix: [the text that resolves it]

### Blockers (if BLOCKED)
- [What blocks]: [the story, ADR or question that must clear first]
```

Name all six groups every time, by these exact names. A group with nothing
passing says "none — see Gaps", so the reader sees it was checked.

Gaps lists failed checklist items only: never a passing or N/A item, and never an
observation from outside the checklist (a sprint status, another document).

Several stories: a summary first, then the one-story block for each story that is
not READY.

```
## Story Readiness Summary — [scope] — [date]
Ready: [N] · Needs Work: [N] · Blocked: [N] · Not Assessed: [N]

Ready: [title] ([path]), ...
Needs Work: [title]: [main gap]
Blocked: [title]: blocked by [story, ADR or question]
Not Assessed: [title]: [what could not be read]
```

`sprint` scope: when a Must Have story is not READY, put this first:
`WARNING: [N] Must Have stories are not ready to implement: [each with its main
gap]. Fix them before the sprint starts, or replan with /sprint-plan update.`

**Then, for one story:** look for other stories to start. In the newest plan in
`production/sprints/`, find up to 3 that are Ready or Not Started, not this one,
not waiting on unfinished dependencies, and Must Have or Should Have. List each
with a one-line description and its estimate. When there are none, say which:
`Next ready stories: no sprint file found` or `Next ready stories: none ready in
[sprint]`.

**Offer help.** Ask: "Would you like me to draft the missing parts for any of
these stories?" Options: Yes, draft them / No, that's all. On yes, draft only the
missing parts, in the conversation. The user, or `/create-stories`, writes them.

Redirects:
- Story file missing: run `/create-stories [epic-slug]` (at `standard` and
  `full`, `/create-epics` first).
- No design reference and the change is small (under about a week): run
  `/quick-design [description]` and cite that spec in the story.
- Scope grew past its sizing: split the story, or raise it with the producer.

**End the reply with:**

```
Review: [QL-STORY-READY skipped — Solo mode | skipped — Lean mode | its verdict]
Next ready stories: [up to 3 | no sprint file found | none ready in [sprint]]   (one-story scope)
Next step: [/dev-story [path] when READY | fix the gaps above, then /story-readiness [path]]
Files changed: none
```
