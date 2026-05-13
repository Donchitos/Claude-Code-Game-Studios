---
name: story-readiness
description: "Validate that a story file is implementation-ready. Checks for embedded GDD requirements, ADR references, engine notes, clear acceptance criteria, and no open design questions. Produces READY / NEEDS WORK / BLOCKED verdict with specific gaps. Use when user says 'is this story ready', 'can I start on this story', 'is story X ready to implement'."
argument-hint: "[story-file-path or 'all' or 'sprint']"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Task
model: sonnet
---

# Story Readiness

This skill validates that a story file contains everything a developer needs
to begin implementation — no mid-sprint design interruptions, no guessing,
no ambiguous acceptance criteria. Run it before assigning a story.

**This skill is read-only.** It never edits story files. It reports findings
and asks whether the user wants help filling gaps.

**Output:** Verdict per story (READY / NEEDS WORK / BLOCKED) with a specific
gap list for each non-ready story.

---

## Phase 0: Resolve Review Mode

Resolve the review mode once at startup (store for all gate spawns this run):

1. If skill was called with `--review [full|lean|solo]` → use that value
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern and mode definitions.

---

## 1. Parse Arguments

**Scope:** `$ARGUMENTS[0]` (blank = ask user via AskUserQuestion)

- **Specific path** (e.g., `/story-readiness production/epics/combat/story-001-basic-attack.md`):
  validate that single story file.
- **`sprint`**: read the current sprint plan from `production/sprints/` (most
  recent file), extract every story path it references, validate each one.
- **`all`**: glob `production/epics/**/*.md`, exclude `EPIC.md` index files,
  validate every story file found.
- **No argument**: ask the user which scope to validate.

If no argument is given, use `AskUserQuestion`:
- "What would you like to validate?"
  - Options: "A specific story file", "All stories in the current sprint",
    "All stories in production/epics/", "Stories for a specific epic"

Report the scope before proceeding: "Validating [N] story files."

---

## 2. Load Supporting Context

Before checking any stories, load reference documents once (not per-story):

- `design/gdd/systems-index.md` — to know which systems have approved GDDs
- `docs/architecture/control-manifest.md` — to know which manifest rules exist
  (if the file does not exist, note it as missing once; do not re-flag per story)
  Also extract the `Manifest Version:` date from the header block if the file exists.
- `docs/architecture/tr-registry.yaml` — index all entries by `id`. Used to
  validate TR-IDs in stories. If the file does not exist, note it once; TR-ID
  checks will auto-pass for all stories (registry predates stories, so missing
  registry means stories are from before TR tracking was introduced).
- All ADR status fields — for each unique ADR referenced across the stories being
  checked, read the ADR file and note its `Status:` field. Cache these so you
  don't re-read the same ADR for every story.
- The current sprint file (if scope is `sprint`) — to identify Must Have /
  Should Have priority for escalation decisions

---

## 3. Story Readiness Checklist

For each story file, evaluate every item below. A story is READY only if all
items pass or are explicitly marked N/A with a stated reason.

### Design Completeness

- [ ] **GDD requirement referenced**: The story includes a `design/gdd/` path
  and quotes or links a specific requirement, acceptance criterion, or rule from
  that GDD — not just the GDD filename. A link to the document without tracing
  to a specific requirement does not pass.
- [ ] **Requirement is self-contained**: The acceptance criteria in the story
  are understandable without opening the GDD. A developer should not need to
  read a separate document to understand what DONE means.
- [ ] **Acceptance criteria are testable**: Each criterion is a specific,
  observable condition — not "implement X" or "the system works correctly".
  Bad example: "Implement the jump mechanic." Good example: "Jump reaches
  max height of 5 units within 0.3 seconds when jump is held."
- [ ] **No acceptance criteria require judgment calls** *(auto-pass for `Type: Visual/Feel`)*: Criteria like
  "feels responsive" or "looks good" are not testable without a defined
  benchmark. For Logic, Integration, UI, and Config/Data stories, these must be
  replaced with specific observable conditions. For Visual/Feel stories, subjective
  criteria are expected and this check auto-passes — instead verify that each
  subjective criterion has a paired playtest protocol or evidence requirement
  (e.g., "evidence doc required at `production/qa/evidence/[slug]-evidence.md`").
  PASS if the acceptance criterion ends with or is accompanied by an explicit reference to a file path such as `production/qa/evidence/[slug]-evidence.md`. NEEDS WORK if the criterion is purely subjective with no evidence file path specified.

### Architecture Completeness

- [ ] **ADR referenced or N/A stated**: The story references at least one ADR,
  OR explicitly states "No ADR applies" with a brief reason.
  A story with no ADR reference and no explicit N/A note fails this check.
- [ ] **ADR is Accepted (not Proposed)**: For each referenced ADR, check its
  `Status:` field using the cached ADR statuses loaded in Section 2.
  - If `Status: Accepted` → pass.
  - If `Status: Proposed` → **BLOCKED**: the ADR may change before it is accepted,
    and the story's implementation guidance could be wrong.
    Fix: `BLOCKED: ADR-NNNN is Proposed — wait for acceptance before implementing.`
  - If the ADR file does not exist → **BLOCKED**: referenced ADR is missing.
  - Auto-pass if story has an explicit "No ADR applies" N/A note.
- [ ] **TR-ID is valid and active**: If the story contains a `TR-[system]-NNN`
  reference, look it up in the TR registry loaded in Section 2.
  - If the ID exists and `status: active` → pass.
  - If the ID exists and `status: deprecated` or `status: superseded-by: ...` →
    NEEDS WORK: the requirement was removed or replaced.
    Fix: update the story to reference the current requirement ID or remove if no longer applicable.
  - If the ID does not exist in the registry → NEEDS WORK: ID was not registered
    (story may predate registry, or registry needs an `/architecture-review` run).
  - Auto-pass if the story has no TR-ID reference OR if the registry does not exist.
- [ ] **Manifest version is current**: If the story has a `Manifest Version:` date
  in its header AND `docs/architecture/control-manifest.md` exists:
  - If story version matches current manifest `Manifest Version:` → pass.
  - If story version is older than current manifest → NEEDS WORK: new rules may
    apply. Fix: review changed manifest rules, update story if any forbidden/required
    entries changed, then update the story's `Manifest Version:` to current.
  - Auto-pass if either the story has no `Manifest Version:` field OR the manifest
    does not exist.
- [ ] **Engine notes present**: For any post-cutoff engine API this story
  is likely to touch, implementation notes or a verification requirement are
  included. If the story clearly does not touch engine APIs (e.g., it is a
  pure data/config change), "N/A — no engine API involved" is acceptable.
- [ ] **Control manifest rules noted**: Relevant layer rules from the control
  manifest are referenced, OR "N/A — manifest not yet created" is stated.
  This item auto-passes if `docs/architecture/control-manifest.md` does not
  exist yet (do not penalize stories written before the manifest was created).

### Scope Clarity

- [ ] **Estimate present**: The story includes a size estimate (hours,
  points, or a t-shirt size). A story with no estimate cannot be planned.
- [ ] **In-scope / Out-of-scope boundary stated**: The story states what
  it does NOT include, either in an explicit Out of Scope section or in
  language that makes the boundary unambiguous. Without this, scope creep
  during implementation is likely.
- [ ] **Story dependencies listed**: If this story depends on other stories
  being DONE first, those story IDs are listed. If there are no dependencies,
  "None" is explicitly stated (not just omitted).

### Open Questions

- [ ] **No unresolved design questions**: The story does not contain text
  flagged as "UNRESOLVED", "TBD", "TODO", "?", or equivalent markers in
  any acceptance criterion, implementation note, or rule statement.
- [ ] **Dependency stories are not in DRAFT**: For each story listed as a
  dependency, check if the file exists and does not have a DRAFT status. A
  story that depends on a DRAFT or missing story is BLOCKED, not just
  NEEDS WORK.

### Asset References Check

- [ ] **Referenced assets exist**: Scan the story text for asset path patterns
  (paths containing `assets/`, or file extensions `.png`, `.jpg`, `.svg`,
  `.wav`, `.ogg`, `.mp3`, `.glb`, `.gltf`, `.tres`, `.tscn`, `.res`).
  - For each asset path found: use Glob to check whether the file exists.
  - If any referenced asset does not exist: **NEEDS WORK** — note the missing
    path(s). (The story references assets that have not been created yet.
    Either remove the reference, create a placeholder, or mark it as an
    explicit dependency on an asset creation story.)
  - If all referenced assets exist: note "Referenced assets verified:
    [count] found."
  - If no asset paths are referenced in the story: note "No asset references
    found in story — skipping asset check." This item auto-passes.
  - This is an existence-only check. Do not validate file format or content.

### Definition of Done

- [ ] **Minimum testable acceptance criteria by story type**:
  - Logic / Integration stories: at least 3
  - Visual/Feel and UI stories: at least 2
  - Config/Data stories: at least 1
  Apply the threshold matching the story's `Type:` field. If the story has fewer than the minimum, mark as NEEDS WORK.
- [ ] **Performance budget noted if applicable**: If this story touches any
  part of the gameplay loop, rendering, or physics, a performance budget or
  a "no performance impact expected — [reason]" note is present.
- [ ] **Story Type declared**: The story includes a `Type:` field in its header
  identifying the test category (Logic / Integration / Visual/Feel / UI / Config/Data).
  Without this, test evidence requirements cannot be enforced at story close.
  Fix: Add `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]` to the story header.
- [ ] **Test evidence requirement is clear**: If the Story Type is set, the story
  includes a `## Test Evidence` section stating where evidence will be stored
  (test file path for Logic/Integration, or evidence doc path for Visual/Feel/UI).
  Fix: Add `## Test Evidence` with the expected evidence location for the story's type.

---

## 4. Verdict Assignment

Assign one of three verdicts per story:

**READY** — All checklist items pass or have explicit N/A justifications.
The story can be assigned immediately.

**NEEDS WORK** — One or more checklist items fail, but all dependency stories
exist and are not DRAFT. The story can be fixed before assignment.

**BLOCKED** — One or more dependency stories are missing or in DRAFT state,
OR a critical design question (flagged UNRESOLVED in a criterion or rule) has
no owner. The story cannot be assigned until the blocker is resolved. Note:
a story that is BLOCKED may also have NEEDS WORK items — list both.

---

## 5. Output Format

### Single story output

```
## Story Readiness: [story title]
File: [path]
Verdict: [READY / NEEDS WORK / BLOCKED]

### Passing Checks (N/[total])
[list passing items briefly]

### Gaps
- [Checklist item]: [exact description of what is missing or wrong]
  Fix: [specific text needed to resolve this gap]

### Blockers (if BLOCKED)
- [What is blocking]: [story ID or design question that must resolve first]
```

### Multiple story aggregate output

```
## Story Readiness Summary — [scope] — [date]

Ready:      [N] stories
Needs Work: [N] stories
Blocked:    [N] stories

### Ready Stories
- [story title] ([path])

### Needs Work
- [story title]: [primary gap — one line]
- [story title]: [primary gap — one line]

### Blocked Stories
- [story title]: Blocked by [story ID / design question]

---
[Full detail for each non-ready story follows, using the single-story format]
```

### Sprint escalation

If the scope is `sprint` and any Must Have stories are NEEDS WORK or BLOCKED,
add a prominent warning at the top of the output:

```
WARNING: [N] Must Have stories are not implementation-ready.
[List them with their primary gap or blocker.]
Resolve these before the sprint begins or replan with `/sprint-plan update`.
```

---

## 6. Collaborative Protocol

This skill is read-only. It never proposes edits or asks to write files.

After reporting findings, offer:

"Would you like help filling in the gaps for any of these stories? I can
draft the missing sections for your approval."

If the user says yes for a specific story, draft only the missing sections
in conversation. Do not use Write or Edit tools — the user (or
`/create-stories`) handles writing.

**Redirect rules:**
- If a story file does not exist at all: "This story file is missing entirely.
  Run `/create-epics [layer]` then `/create-stories [epic-slug]` to generate stories from the GDD and ADR."
- If a story has no GDD reference and the work appears small: "This story has
  no GDD reference. If the change is small (under ~4 hours), run
  `/quick-design [description]` to create a Quick Design Spec, then reference
  that spec in the story."
- If a story's scope has grown beyond its original sizing: "This story appears
  to have expanded in scope. Consider splitting it or escalating to the producer
  before implementation begins."

---

## 7. Next-Story Handoff

After completing a single-story readiness check (not `all` or `sprint` scope):

1. Read the current sprint file from `production/sprints/` (most recent).
2. Find stories that are:
   - Status: READY or NOT STARTED
   - Not the story just checked
   - Not blocked by incomplete dependencies
   - In the Must Have or Should Have tier

If any are found, surface up to 3:

```
### Other Ready Stories in This Sprint

1. [Story name] — [1-line description] — Est: [X hrs]
2. [Story name] — [1-line description] — Est: [X hrs]

Run `/story-readiness [path]` to validate before starting.
```

If no sprint file exists or no other ready stories are found, skip this section silently.

---

## Phase 8: Director Gate — Story Readiness Review

Apply the review mode resolved in Phase 0 before spawning QL-STORY-READY:

- `solo` → skip. Note: "QL-STORY-READY skipped — Solo mode." Proceed to close.
- `lean` → skip. Note: "QL-STORY-READY skipped — Lean mode." Proceed to close.
- `full` → spawn as normal.

Spawn `qa-lead` via Task using gate **QL-STORY-READY** (`.claude/docs/director-gates.md`).

Pass the following context:
- Story title
- Acceptance criteria list (all items from the story's acceptance criteria section)
- Dependency status (all dependencies listed and their current state: exist / DRAFT / missing)
- Overall verdict (READY / NEEDS WORK / BLOCKED) from Phase 4

Handle the verdict per standard rules in `director-gates.md`:
- **ADEQUATE** → story is cleared. Proceed to close.
- **GAPS [list]** → surface the specific gaps to the user via `AskUserQuestion`:
  options: `Update story with suggested gaps` / `Accept and proceed anyway` / `Discuss further`.
- **INADEQUATE** → surface the specific gaps; ask user whether to update the story or proceed anyway.

---

## Recommended Next Steps

- Run `/dev-story [story-path]` to begin implementation once the story is READY
- Run `/story-readiness sprint` to check all stories in the current sprint at once
- Run `/create-stories [epic-slug]` if a story file is missing entirely
