---
name: dev-story
description: "Implement a story: ADR guidelines, right programmer agent, code plus test. After /story-readiness, before /code-review and /story-done."
argument-hint: "[story-path]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/dev-story/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,story_granularity,qa.level,testing.strict,system_overrides`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.


# Dev Story

This skill bridges planning and code. It reads a story file in full, assembles
all the context a programmer needs, routes to the correct specialist agent, and
drives implementation to completion — including writing the test.

**The loop for every story:**
```
/qa-plan sprint           ← define test requirements before sprint begins
/story-readiness [path]   ← validate before starting
/dev-story [path]         ← implement it  (this skill)
/code-review [files]      ← review it
/story-done [path]        ← verify and close it
```

**After all sprint stories are done:** run `/team-qa sprint` to execute the full QA cycle and get a sign-off verdict before advancing the project stage.

**Output:** Source code under the project's **code root** + test file in `tests/`. Resolve the code root from `engine.name` (`src/` Godot, `Assets/` Unity, `Source/<Module>/` Unreal) per `.claude/docs/code-root-resolution.md`.

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Workflow tier**: resolved per the story's system (per
`.claude/docs/workflow-modes.md`) — **the GDD filename stem** of the story's
`GDD:` path (`design/gdd/<stem>.md` → `<stem>`), with the `[system]` segment of
its `TR-[system]-NNN` ID accepted only as a fallback alias: use the
`system_overrides` row for that system if the block lists one, else the
project value. Resolve it at the start of Phase 2 (the story header is
read there) and apply it to the prerequisite gate.

**`story_granularity`** — it sets the
expected implementation cycle: **multi-day** at `coarse` (give the programmer
subagent longer working context), **1–2 days** at `balanced` (default), **hours**
at `fine` (tighter context). It does not change the prerequisite gate.

**`qa.level`**: controls whether the programmer brief carries
a test requirement. At `minimal`, omit the "Test requirement" line (Phase 4 item 7)
— tests are not required; at `standard`, include the per-type test requirement; at
`full`, also pass a coverage target. Distinct from `workflow: minimal`. When tests
are not required (`minimal`), the Phase 5 `testing.strict` gate is a no-op.

## Phase 1: Find the Story

**If a path is provided**: read that file directly.

**If no argument**: check `production/session-state/active.md` for the active
story. If found, confirm: "Continuing work on [story title] — is that correct?"
If not found, ask: "Which story are we implementing?" Glob
`production/epics/**/*.md` and list stories with Status: Ready.

---

## Phase 2: Load Full Context

**Before loading any context, resolve the workflow tier for this story's system** (see the Workflow tier note above), then **verify required files exist.** Extract the ADR path from the story's `ADR Governing Implementation` field. The "If missing — `full`" column is the baseline; the tier columns relax it:

| File | Path | If missing — `full` | `standard` | `minimal` |
|------|------|---------------------|-----------|-----------|
| TR registry | `docs/architecture/tr-registry.yaml` | **STOP** — "TR registry not found at `docs/architecture/tr-registry.yaml`. Run `/architecture-review` to bootstrap the registry from your GDDs and ADRs." | optional — proceed without it | not expected — proceed |
| Governing ADR | path from story's ADR field | **STOP** — "ADR file [path] not found. Run `/architecture-decision` to create it, or correct the filename in the story's ADR field." | **STOP only if the story references an ADR** and its file is missing/Proposed; if it references none, proceed | no ADR required — proceed |
| Control manifest | `docs/architecture/control-manifest.md` | **WARN and continue** — "Control manifest not found — layer rules cannot be checked. Run `/create-control-manifest`." | WARN and continue | skip — not expected |

At `full`, if the TR registry or governing ADR is missing, set the story status to **BLOCKED** in the session state and do not spawn any programmer agent. At `standard`/`minimal`, only a story that references an ADR whose file is **missing or `Proposed`** is set BLOCKED; a missing TR registry, or an absent-by-design ADR, does **not** block — implement against the story's acceptance criteria + the GDD/brief.

Read the story file and the TR registry simultaneously — these two are
genuinely independent, unconditional reads. **The governing ADR is not part
of this batch — do not include it in the same parallel tool-call group as
these two.** Its own section below is a gate, not a read: whether the ADR
gets opened at all depends on a freshness check that itself depends on the
story file already being read. Do not start implementation until this phase
is fully resolved:

### The story file
Extract and hold:
- **Story title, ID, layer, type** (Logic / Integration / Visual/Feel / UI / Config/Data)
- **TR-ID** — the GDD requirement identifier
- **Governing ADR** reference
- **ADR Version** stamp embedded in story header (absent on pre-stamp stories)
- **ADR Decision Summary** and **Implementation Notes** — the distilled ADR
  guidance; this is the primary source for what the ADR decided
- **Manifest Version** embedded in story header
- **Acceptance Criteria** — every checkbox item, verbatim
- **Implementation Notes** — the ADR guidance section in the story
- **Out of Scope** boundaries
- **Test Evidence** — the required test file path
- **Dependencies** — what must be DONE before this story

### The TR registry
Grep the story's TR-ID from `docs/architecture/tr-registry.yaml`
(`Grep pattern="id: <TR-ID>" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 6`)
rather than reading the whole cross-system registry. Read the matched entry's current
`requirement` text — this is the source of truth for what the GDD requires now. Do not
rely on any inline text in the story file (may be stale).

### The governing ADR

**Do not open the ADR by default.** `/create-stories` already distilled it into
this story's `**ADR Decision Summary**` + `## Implementation Notes`, and its
template states the contract outright: *"This is what the programmer reads
instead of the ADR."* Re-reading the source here discards that work and, on an
ADR past the 25k `Read` cap, costs a failed read plus offset/limit retries
before implementation even starts.

**Check freshness with one line, not one file.** Resolve the ADR path from the
story, then:

```
Grep pattern="^## Last Verified" path="docs/architecture/[adr-file].md" output_mode="content" -A 1
```

Compare that date against the story's `**ADR Version**` field:

| Result | Meaning | Action |
|---|---|---|
| Dates **match** | The summary was distilled from the ADR as it stands. | **Trust the story.** Do not read the ADR. |
| Story has **no `ADR Version`** field | A story written before the stamp existed — *not* evidence of staleness. | **Trust the story**, and note in the Phase 6 summary: "Story predates the ADR Version stamp; summary trusted unverified." |
| Grep returns **no match** and the story reads `unversioned` | The ADR carries no `## Last Verified`. Consistent, not stale. | **Trust the story**; recommend `/architecture-decision [file] retrofit` to add the field. |
| Grep returns **no match** but the story names a date | Ambiguous — the ADR may have lost the field. | Treat as **mismatch** (below). |
| Dates **differ** | The ADR changed after this story was written. | **Mismatch** — resolve below. |

**Never treat an absent stamp as a stale one.** A missing field means "unknown",
and the fallback for unknown is the story, not a 35k-token re-read — the two
staleness gates that already exist (`/story-readiness` on Manifest Version,
`/code-review` post-implementation) are what make that safe.

**On mismatch**, use `AskUserQuestion` — same shape as the Manifest Version
check below:
- Prompt: "Story was written against ADR v[story-date]. The ADR is now
  v[current-date]. Its decision may have changed. How do you want to proceed?"
- Options:
  - `[A] Re-read the changed ADR sections and implement against current guidance (Recommended)`
  - `[B] Implement from the story's summary — I accept the drift risk`
  - `[C] Stop — I want to review the ADR diff first`

If **[A]**: first check the ADR's size — `Bash: wc -c "docs/architecture/[adr-file].md"`:

- **Under ~50KB** — read the whole file with one `Read` call. Measured on this
  branch: at this size one read is *cheaper* than the multi-grep path (48.4k
  vs 52.1k tokens on a 16KB fixture) — per-call overhead outweighs the
  content saved. Targeted reading only pays for itself on files big enough
  to threaten the 25k-token `Read` cap.
- **~50KB or larger** — read *only* the sections that govern implementation,
  never the whole file:
  ```
  Grep pattern="^## (Decision|Engine Compatibility|ADR Dependencies)" path="docs/architecture/[adr-file].md" output_mode="content" -A 40
  ```
  Escalate to a bounded `Read(offset, limit)` on one section only if a scanned
  section cross-references material outside itself.

Then update the story's `ADR Version` to the current date so the next run is clean.
If **[B]**: proceed on the summary; record it in the Phase 6 "Deviations" summary.
If **[C]**: stop. Do not spawn any agent.

### The control manifest
Read only this story's layer from `docs/architecture/control-manifest.md` — grep that one
section (`Grep pattern="^## <layer> Layer Rules" path="docs/architecture/control-manifest.md" output_mode="content" -A 40`) rather than a full read of every layer. Extract the rules for this story's layer:
- Required patterns
- Forbidden patterns
- Performance guardrails

Check: does the story's embedded Manifest Version match the current manifest header date?
If they differ, use `AskUserQuestion` before proceeding:
- Prompt: "Story was written against manifest v[story-date]. Current manifest is v[current-date]. New rules may apply. How do you want to proceed?"
- Options:
  - `[A] Update story manifest version and implement with current rules (Recommended)`
  - `[B] Implement with old rules — I accept the risk of non-compliance`
  - `[C] Stop here — I want to review the manifest diff first`

If [A]: edit the story file's `Manifest Version:` field to the current manifest date before spawning the programmer. Then read the manifest carefully for new rules.
If [B]: edit the story file's `Manifest Version:` field to the current manifest date AND add a `Manifest-Note: Proceeded with old manifest rules on [date] — non-compliance risk accepted.` line to the story header. Read the manifest for new rules anyway. Note the decision in the Phase 6 summary under "Deviations". `/story-done` will include the Manifest-Note in its deviations section without re-checking staleness.
If [C]: stop. Do not spawn any agent. Let the user review and re-run `/dev-story`.

### Dependency validation

After extracting the **Dependencies** list from the story file, validate each:

1. Glob `production/epics/**/*.md` to find each dependency story file.
2. Read its `Status:` field.
3. If any dependency has Status other than `Complete` or `Done`:
   - Use `AskUserQuestion`:
     - Prompt: "Story '[current story]' depends on '[dependency title]' which is currently [status], not Complete. How do you want to proceed?"
     - Options:
       - `[A] Proceed anyway — I accept the dependency risk`
       - `[B] Stop — I'll complete the dependency first`
       - `[C] The dependency is done but status wasn't updated — mark it Complete and continue`
   - If [B]: set story status to **BLOCKED** in session state and stop. Do not spawn any programmer agent.
   - If [C]: ask "May I update [dependency path] Status to Complete?" before continuing.
   - If [A]: note in Phase 6 summary under "Deviations": "Implemented with incomplete dependency: [dependency title] — [status]."

If a dependency file cannot be found: warn "Dependency story not found: [path]. Verify the path or create the story file."

---

### Engine reference
Read from `project.yaml` first, falling back to `.claude/docs/technical-preferences.md` for any key absent or empty:
- `specialists.*` — the project's chosen specialist agents; **read before**
  `engine.name` when selecting an agent (see Phase 3)
- `engine.name` (else the `Engine:` value) — the generic engine specialist, and
  the fallback when `specialists` is absent
- `naming.*` (else Naming conventions) — class names, file names, signal/event names
- `performance.*` (else Performance budgets) — frame budget, memory ceiling
- Forbidden patterns — from `.claude/docs/technical-preferences.md` (not migrated to project.yaml)

### Mark Story In Progress

Silently update two things before spawning any agent:

1. **`production/sprint-status.yaml`** (if it exists): find the entry matching this story's file path and set `status: in_progress`. Update the top-level `updated` field to today's date. If the file does not exist, say so in one line — `Sprint status not updated: production/sprint-status.yaml absent` — and continue. Do not skip silently: `/sprint-status` reads that file to report progress, so a story that never gets marked `in_progress` is invisible to the very command a producer uses to ask what is moving.

2. **The story file itself**: set the story header's `Status:` field to `In Progress`, and edit its `Last Updated:` field to today's date (format: `YYYY-MM-DD`; if the field does not exist, add it after the `Status:` line). Setting `Status:` here is what actually marks the story In Progress — at `minimal` the `sprint-status.yaml` in step 1 is absent, so the story file is the only record of progress at that tier.

---

## Phase 3: Route to the Right Programmer

Based on the story's **Layer**, **Type**, and **system name**, determine which
specialist to spawn via `Agent`.

**Config/Data stories — skip agent spawning entirely:**
If the story's Type is `Config/Data`, no programmer agent or engine specialist is needed. Jump directly to Phase 4 (Config/Data note). The implementation is a data file edit — no routing table evaluation, no engine specialist.

### Primary agent routing table

| Story context | Primary agent |
|---|---|
| Foundation layer — any type | `engine-programmer` |
| Any layer — Type: UI | `ui-programmer` |
| Any layer — Type: Visual/Feel | `gameplay-programmer` (implements) |
| Core or Feature — gameplay mechanics | `gameplay-programmer` |
| Core or Feature — AI behaviour, pathfinding | `ai-programmer` |
| Core or Feature — networking, replication | `network-programmer` |
| Config/Data — no code | No agent needed (see Phase 4 Config note) |

### Engine specialist — always spawn as secondary for code stories

**Read the `specialists` block from `project.yaml` directly — it is not in
the `resolve_config` output at the top of this skill..** `resolve_config` does not emit
`specialists.*`; the five skills that already consume it (`/adopt`,
`/code-review`, `/design-system`, `/gate-check`, `/team-ui`) all read the block
out of `project.yaml` themselves, and so does this one. Adding it to the
frontmatter key list would fail the gate that asserts every requested key is one
`resolve_config` actually emits.

`/setup-engine` writes the block, and it is the project's own answer to "which
specialist implements here" — resolved from the engine *and the language*, which
`engine.name` alone cannot tell you. Resolve in this order:

1. **`specialists.code`** — the language/code specialist, and the right secondary
   for an implementation story. This is the value that distinguishes a Godot C#
   project (`godot-csharp-specialist`) from a Godot GDScript one
   (`godot-gdscript-specialist`); `engine.name` is `Godot` for both.
2. **`specialists.shader`** when the story touches shaders or materials, and
   **`specialists.ui`** when the story's Type is `UI` — in addition to, not
   instead of, `specialists.code`.
3. **The generic `<engine>-specialist`** — derived from `engine.name`
   (Godot→`godot-specialist`, Unity→`unity-specialist`,
   Unreal→`unreal-specialist`) — for architecture-level and broad engine
   concerns, and as the fallback when the `specialists` block is absent.
4. If `engine.name` is also absent or empty, read the Primary line of the
   `## Engine Specialists` section of `.claude/docs/technical-preferences.md`.

**A value of `null` means UNSET — treat that key as absent and fall through to
the generic specialist. Never spawn it as an agent name.** The config reader
returns the four-character string `"null"`, which is not empty and therefore
reads as configured; `null`, empty and missing are the same state here. (This is
the same caveat `/code-review` Phase 2 carries, for the same reason.)

Spawn the resolved specialist alongside the primary agent when the story involves
engine-specific APIs, patterns, or the ADR has HIGH engine risk.

The full roster, for reference when no `specialists` block exists:

| Engine | Specialist agents available |
|--------|----------------------------|
| Godot 4 | `godot-specialist`, `godot-gdscript-specialist`, `godot-csharp-specialist`, `godot-shader-specialist`, `godot-gdextension-specialist` |
| Unity | `unity-specialist`, `unity-ui-specialist`, `unity-shader-specialist`, `unity-dots-specialist`, `unity-addressables-specialist` |
| Unreal Engine | `unreal-specialist`, `ue-gas-specialist`, `ue-blueprint-specialist`, `ue-umg-specialist`, `ue-replication-specialist` |

> **Do not pick from this table when `specialists` is set.** The table lists what
> *exists* for an engine; the block records what this project *chose*. Reading the
> table instead of the block is how a Godot C# project ends up reviewed by the
> GDScript specialist.

**When engine risk is HIGH** (from the ADR or VERSION.md): always spawn the engine
specialist, even for non-engine-facing stories. High risk means the ADR records
assumptions about post-cutoff engine APIs that need expert verification.

> **Read the risk, do not trust the story card alone.** If the story's `Risk`
> field is absent, or says `NOT ASSESSED`, **or disagrees with
> `docs/engine-reference/<engine>/VERSION.md`, the VERSION.md rating wins** and an
> unknown counts as HIGH. At `minimal` there is no ADR, so VERSION.md is the only
> source; a story card carrying an improvised `MEDIUM` against a VERSION.md
> rating of HIGH would skip this spawn without saying so — which is how two wrong engine
> defaults reached a project unreviewed. `/create-stories` now derives the field
> from the same file, so the two should agree; this check is what catches it when
> they do not.

---

## Phase 4: Implement

Spawn the chosen programmer agent(s) via `Agent` with the full context package:

Brief the agent with file paths and targeted reading instructions — do not serialize document content into the `Agent` prompt. The agent reads what it needs directly.

> **Tier note (from Phase 2):** items 2–4 below assume the `full` baseline. At
> `standard`, include the TR registry only if it exists and the governing ADR
> only where the story references one. At `minimal`, the TR registry, ADR, and
> control manifest are typically absent — **omit items 2–4 and brief the agent to
> implement against the story's Acceptance Criteria and the GDD/brief** (the
> story file from item 1). Never instruct the agent to read a file Phase 2
> confirmed missing.
>
> **Say which items you dropped, and say it to both readers.** The rule item 7
> already carries applies unchanged to items 2–4: *an omitted item and a
> forgotten one are indistinguishable to the agent.* They are equally
> indistinguishable to the user reading the Phase 6 summary.
> - **To the agent**, in the prompt: *"No TR registry entry is passed for this
>   story — `docs/architecture/tr-registry.yaml` does not exist at this tier.
>   Implement against the story's Acceptance Criteria and the GDD/brief. Do not
>   go looking for it."* Same form for an absent ADR or control manifest.
> - **To the user**, one line before spawning: `Briefing omits: TR registry
>   (absent), control manifest (absent) — implementing against acceptance
>   criteria + GDD.`
>
> Without this, a `standard` run where the registry legitimately does not exist
> and one where `/architecture-review` was supposed to bootstrap it and nobody
> did produce **identical output**.

1. **Story file**: `[story-path]` — the agent reads this one file; it carries the acceptance criteria, Out of Scope boundaries, and QA test cases
2. **GDD requirement**: look up TR-ID `[TR-XXX-NNN]` in `docs/architecture/tr-registry.yaml` — use the `requirement` field as source of truth
3. **ADR guidance**: pass the story's `**ADR Decision Summary**` and `## Implementation Notes` **inline in the prompt** — do not pass the ADR path. Phase 2 already established that this summary is current; handing the agent a path makes it re-read the whole ADR in its own context, paying the cost this skill just avoided. Pass the path *only* if Phase 2 hit the mismatch branch and the user chose `[C]`-style deferral, in which case say which sections to grep.
4. **Control manifest**: `docs/architecture/control-manifest.md` — read rules for the **[layer]** layer only
5. **Engine preferences**: `naming.*` and `performance.*` from `project.yaml` (for any key absent or empty, fall back to `.claude/docs/technical-preferences.md`)
6. **Test file path**: `[path from story's Test Evidence section]` — this file must be created as part of implementation
7. **Test requirement** (Logic and Integration stories only; **omit this entire item at `qa.level: minimal`** — tests are not required there. When you omit it, tell the agent so explicitly: *"Do not write a test file for this story — test evidence is waived at `qa.level: minimal`."* An omitted item and a forgotten one are indistinguishable to the agent, and a programmer briefed with no test instruction may write tests anyway, or may silently assume they were meant to): The test file MUST be created at `[path from the story's Test Evidence section]`. Write the test alongside the implementation — do not defer it. At `qa.level: standard`/`full` the story cannot be closed via `/story-done` without this file present. Each acceptance criterion must have at least one test function covering it. Test file naming: `[system]_[feature]_test.[ext]`. Function naming: `test_[scenario]_[expected_outcome]`. No random seeds, no time-dependent assertions, no external I/O.
8. **Explicit instruction**: implement this story following the ADR guidelines, respect the manifest rules, stay within the story's Out of Scope boundaries. Write clean, doc-commented public APIs.

The agent should:
- Create or modify files under the **resolved code root** following the ADR guidelines. Resolve it per `.claude/docs/code-root-resolution.md` — `src/` is the Godot row, `Assets/Scripts/<System>/` is Unity's, `Source/<Module>/<System>/` is Unreal's. **If the code root cannot be resolved, do not write: report it and stop.** Selecting the engine specialist above is NOT the same as resolving the code root
- Respect all Required and Forbidden patterns from the control manifest
- Stay within the story's Out of Scope boundaries (do not touch unrelated files)
- Write clean, doc-commented public APIs

### Config/Data stories (no agent needed)

For Type: Config/Data stories, no programmer agent is required. The implementation
is editing a data file. Read the story's acceptance criteria and make the specified
changes to the data file directly. Note which values were changed and what they
changed from/to.

### Visual/Feel stories

Spawn `gameplay-programmer` to implement the code/animation calls. The *look*
half of the acceptance criteria — layout, clipping, presence, colour — is
verified in Phase 6 step 4 by launching the build and retaining a screenshot;
it is not deferred. The *feel* half — timing, weight, responsiveness — is not
something a still can show: say which half the run covered, and leave feel to
`/team-qa`.

---

## Phase 5: Test Evidence Requirements

The test requirement was included in the Phase 4 programmer agent brief (item 7). This phase summarizes what evidence each story type requires — used when collecting the Phase 6 summary.

**Skip this phase at `qa.level: minimal`** (resolved earlier) — no test evidence
is required, so there is nothing to gate; do not flag the story unverifiable for a
missing test.

> **Say so in the Phase 6 summary.** A skipped phase must announce itself in the
> output, not only in this file (`.claude/rules/skill-authoring.md`, obligation
> 3). Emit the line:
>
> > *Test evidence: **waived** at `qa.level: minimal` — no test was required or
> > written for this story.*
>
> Without it, a minimal-tier summary that simply lacks a tests row is
> indistinguishable from a `standard`-tier run where the programmer forgot to
> write them — and the permissive reading is the one that gets believed.

Otherwise:

**Resolve the gate level for this story's type** from `testing.strict` in
`project.yaml`. BLOCKING means a missing test marks the story unverifiable;
ADVISORY means a missing test is noted but does not block:

1. Map the Story Type to a `testing.strict` key — Logic→`logic`,
   Integration→`integration`, Visual/Feel→`visual`, UI→`ui`, Config/Data→`config`.
   Take `testing.strict.<key>` from the **the resolved-config block at the top of this skill**, not from
   `project.yaml` directly. If its value is `true` (case-insensitive) →
   BLOCKING; if `false` → ADVISORY; `unset` → fall through.

> `testing.strict.*` is locally overridable (`/settings --local
> testing.strict.logic=false`). Reading `project.yaml` on its own ignores
> `project.local.yaml` entirely, so the override is accepted and then does
> nothing. `resolve_config` merges the two.
2. Else read `testing.strict` as a plain boolean (legacy single-value form) — if
   its value is `true` or `false`, it applies to every type.
3. Else use the **Default Gate Level** column below.

Only `true` and `false` (case-insensitive) are recognized at steps 1–2. A key
that is present but holds any other value — `maybe`, `1`, `yes`, etc. — is
treated as unset: continue to the next step, and surface the unrecognized value
to the user.

| Story Type | Required Evidence | Default Gate Level |
|---|---|---|
| **Logic** | Automated unit test at path from story's Test Evidence section | BLOCKING |
| **Integration** | Integration test OR documented playtest record | BLOCKING |
| **Visual/Feel** | Retained screenshot + evidence doc at `production/qa/evidence/[slug]-evidence.md` | BLOCKING |
| **UI** | Retained screenshot of each screen touched, in `production/qa/evidence/` | BLOCKING |
| **Config/Data** | None — smoke check serves as evidence | ADVISORY |

The test is written alongside the implementation (Phase 4, item 7) regardless of
the gate level — strictness controls only how a *missing* test is reported in the
Phase 6 summary. At a BLOCKING level, a missing test is flagged "story
unverifiable — test required before `/story-done`". At an ADVISORY level it is
noted as a recommendation. The **Default Gate Level** column applies when
`testing.strict` is unset.

Visual/Feel and UI default to **BLOCKING**: for a game the rendered result is the
product, and an advisory visual gate gets deferred in favour of whatever does
block. A project that genuinely does not need it sets `testing.strict.visual` or
`testing.strict.ui` to `false`.

For Visual/Feel and UI stories, include in the Phase 6 summary: "Retained screenshot required at `production/qa/evidence/[slug]-evidence.md` before this story can be closed — at the default BLOCKING level a story with no screenshot on disk is unverifiable."

---

## Phase 6: Collect and Summarise

### First: did the agent actually finish?

**Do not assume completion.** A programmer agent can stop at its turn limit
mid-edit, and the work it leaves behind can be syntactically broken — a helper
called but never defined, an import half-moved. Its partial report reads like
progress, and this phase's summary would print "Implementation Complete" over
code that does not load.

Before collecting anything:

1. **Check the agent's own terminal state.** If it reported stopping early, hit a
   turn/step limit, or its report ends mid-task, treat the story as **INCOMPLETE**.
2. **Verify the output parses.** Run the cheapest check the engine offers —
   `commands.test` or `commands.smoke` from `project.yaml`, or for Godot
   `godot --headless --path . --import`, which surfaces parse errors without
   running the game. Report what you ran and what it said.
3. If the engine binary is unavailable, write **`parse NOT VERIFIED — engine
   binary not available`**. Do not infer that the code is fine because it reads
   correctly; that inference is exactly what this step exists to replace.
4. **Run it and look.** A parse check is not a run. For every story that
   changes something a player can see — every Visual/Feel and UI story, and any
   Logic, Integration or Config/Data story with a surface — launch the build
   via `commands.run`, straight into the scene or map the story touched, and
   retain a screenshot under `production/qa/evidence/[story-slug]/`. Then
   `Read` the image and compare it to the acceptance criteria: clipped text,
   an overflowing panel, a missing element are defects, and this is the only
   step that finds them. Procedure per engine, including how to capture
   unattended in Godot, Unity and Unreal: `.claude/docs/run-and-observe.md`.
   Report exactly one line — `Run result: OBSERVED — <what was on screen>`
   with the retained path, `Run result: NOT VERIFIED — <reason>`, or
   `Run result: N/A — <reason>` for a story with genuinely nothing observable.
   **`NOT VERIFIED` is a blocker at the default gate level for Visual/Feel and
   UI, not a note** — `/story-done` reads this line. This step is **not waived
   at `qa.level: minimal`**; tests are, the look is not.

**If INCOMPLETE:** say so as the headline, list what exists so far, name the
specific breakage, and offer to resume the agent. Do **not** emit
"Implementation Complete", and do not advance the story's status.

### Then collect:

- Files created or modified (with paths)
- **Verification result** — what was run, and its outcome (or why it could not run)
- Test file created (path and number of test functions written) — **or**, at
  `qa.level: minimal`, the waiver line from Phase 5
- Any deviations from the story's Out of Scope boundary (flag these)
- Any questions or blockers the agent surfaced
- Any engine-specific risks the specialist flagged

Present a concise implementation summary:

```
## Implementation Complete: [Story Title]

**Files changed**:
- `<code root>/[path]` — created / modified ([brief description])
- `tests/[path]` — test file ([N] test functions) — *omit this line at
  `qa.level: minimal` and print the Phase 5 waiver line instead*

**Verification**: [what was run] — [result, or `NOT VERIFIED — <reason>`]
**Run result**: [`OBSERVED — <what was on screen>` + retained path | `NOT VERIFIED — <reason>` | `N/A — <reason>`] — see `.claude/docs/run-and-observe.md`

**Acceptance criteria covered**:
- [x] [criterion] — implemented in [file:function]
- [x] [criterion] — covered by test [test_name]
- [x] [criterion] — OBSERVED in `production/qa/evidence/[slug]/01-[what].png` (Visual/UI look)
- [ ] [criterion] — DEFERRED: requires playtest (Visual/Feel *feel* — timing, weight; a still cannot show it)

**Deviations from scope**: [None] or [list files touched outside story boundary]
**Engine risks flagged**: [None] or [specialist finding]
**Blockers**: [None] or [describe]

**Before running `/story-done`:** run your test suite locally and confirm the tests you wrote pass. *(At `qa.level: minimal` no tests were written — print the Phase 5 waiver line here instead of this paragraph. Telling a user to confirm the passing of tests that do not exist is worse than saying nothing.)* **`/story-done` does NOT re-run them** — its Phase 3 checks that the test FILE exists, with `Glob`, and nothing executes it. A test that exists and fails satisfies that gate. Nothing downstream makes the local run safe to skip. Pass/fail is established by `/gate-check` and `/smoke-check`, both of which execute a suite — and both come later than story closure.

Ready for: `/code-review [file1] [file2]` then `/story-done [story-path]`
```

---

## Phase 7: Update Session State

Silently append to `production/session-state/active.md`:

```
## Session Extract — /dev-story [date]
- Story: [story-path] — [story title]
- Files changed: [comma-separated list]
- Test written: [path, or "None — Visual/Feel/Config story"]
- Blockers: [None, or description]
- Next: /code-review [files] then /story-done [story-path]
```

Create `active.md` if it does not exist. Confirm: "Session state updated."

---

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, GDD absent) → redirect to the skill that creates it
- A *referenced* ADR's status is Proposed → do not implement; run `/architecture-decision` first (at `standard`/`minimal` a story that references no ADR is not blocked on this — see Phase 2)
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Manifest version mismatch → show diff to user, ask whether to proceed with old rules or update story first

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **File writes are delegated** — all source code, test files, and evidence docs are written by sub-agents spawned via `Agent`. Each sub-agent enforces the "May I write to [path]?" protocol individually. This orchestrator does not write files directly.
- **Load before implementing** — do not start coding until all context is loaded
  (story, TR-ID, ADR, manifest, engine prefs). Incomplete context produces code
  that drifts from design.
- **The ADR is the law** — implementation must follow the ADR's Implementation
  Guidelines. If the guidelines conflict with what seems "better," flag it in the
  summary rather than silently deviating.
- **Stay in scope** — the Out of Scope section is a contract. If implementing
  the story requires touching an out-of-scope file, stop and surface it:
  "Implementing [criterion] requires modifying [file], which is out of scope.
  Shall I proceed or create a separate story?"
- **Test is not optional for Logic/Integration** (at `qa.level: standard`/`full`) —
  do not mark implementation complete without the test file existing. At
  `qa.level: minimal` tests are not required and this does not apply.
- **Visual/Feel criteria are deferred, not skipped** — mark them as DEFERRED
  in the summary; they will be manually verified in `/story-done`
- **Ask before large structural decisions** — if the story requires an
  architectural pattern not covered by the ADR, surface it before implementing:
  "The ADR doesn't specify how to handle [case]. My plan is [X]. Proceed?"

---

## Recommended Next Steps

- Run `/code-review [file1] [file2]` to review the implementation before closing the story
- Run `/story-done [story-path]` to verify acceptance criteria and mark the story complete
- After all sprint stories are done: run `/team-qa sprint` for the full QA cycle before advancing the project stage
