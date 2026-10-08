---
name: dev-story
description: "Implement a story: ADR guidelines, right programmer agent, code plus test. Then /story-done (/story-readiness before, /code-review after, at standard/full)."
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

**At `workflow: minimal`** the loop is `/dev-story [path]` → `/story-done [path]`:
no QA plan, readiness check or sprint. `/story-done` names the next story.

**With a sprint plan, after all sprint stories are done:** run `/team-qa sprint` to execute the full QA cycle and get a sign-off verdict before advancing the project stage.

**Output:** Source code under the project's **code root** + test file under the engine's **test root** (`tests/` Godot, `Assets/Tests/` Unity, `Source/<Module>/Private/Tests/` Unreal — `.claude/docs/directory-structure.md`). Resolve the code root from `engine.name` (`src/` Godot, `Assets/` Unity, `Source/<Module>/` Unreal) per `.claude/docs/code-root-resolution.md`.

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
expected implementation cycle: **multi-day** at `coarse` (the default, via `rigor: minimal`; give the programmer
subagent longer working context), **1–2 days** at `balanced` (`rigor: standard`), **hours**
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

**Read `references/2-load-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Route to the Right Programmer

**Read `references/3-route.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Implement

**Read `references/4-implement.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Test Evidence Requirements

**Read `references/5-test-evidence.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Collect and Summarise

**Read `references/6-collect.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Update Session State

**Read `references/7-session-state.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

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
- A *referenced* ADR's status is Proposed → do not implement; accept it with `/architecture-decision accept ADR-NNNN` once decided (a story that references no ADR is not blocked on this — see Phase 2)
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Manifest version mismatch → show diff to user, ask whether to proceed with old rules or update story first

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

- **File writes are delegated** — all source code, test files, and evidence docs are written by sub-agents spawned via `Agent`. Each sub-agent enforces the "May I write to [path]?" protocol individually. This orchestrator writes only the following, each after an ask that names it:
  - the story's `Status:` / `Last Updated:` and its `production/sprint-status.yaml` entry — the one "May I mark this story In Progress?" ask (Phase 2)
  - the story's `ADR Version`, `**ADR Decision Summary**` and `## Implementation Notes` (ADR mismatch option [A]), and its `Manifest Version:` / `Manifest-Note:` (manifest option [A] or [B]) — each option names that edit, so choosing it is the ask
  - a dependency story's `Status: Complete` (dependency option [C], then "May I update [dependency path] Status to Complete?")
  - a Config/Data story's data file ("May I write to [path]?")
  - on Unity, `Assets/Scripts/ScreenshotOnArg.cs`, written verbatim from `.claude/docs/run-and-observe.md` ("May I write `Assets/Scripts/ScreenshotOnArg.cs`?", Phase 6)

  The session-state checkpoint in `production/session-state/active.md` is the one write made without an ask.
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
- **Visual/Feel and UI looks are observed, not deferred** — the Phase 6 run
  retains the screenshot (each screen touched for UI; Visual/Feel also needs a
  lead sign-off before `/story-done`), and `qa.level` never waives either. Only
  the *feel* half of a Visual/Feel criterion — timing, weight, responsiveness —
  is marked DEFERRED, for `/team-qa`
- **Ask before large structural decisions** — if the story requires an
  architectural pattern not covered by the ADR, surface it before implementing:
  "The ADR doesn't specify how to handle [case]. My plan is [X]. Proceed?"

---

## Recommended Next Steps

- At `standard`/`full`, run `/code-review [file1] [file2]` to review the implementation before closing the story (not part of the minimal loop)
- Run `/story-done [story-path]` to verify acceptance criteria and mark the story complete
- With a sprint plan, after all sprint stories are done: run `/team-qa sprint` for the full QA cycle before advancing the project stage. At `minimal`, `/story-done` names the next story instead
