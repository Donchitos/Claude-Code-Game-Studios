---
name: team-ui
description: "Orchestrate the UI team through the UX pipeline — authoring, visual design, implementation, review, polish. Uses /ux-design, /ux-review, studio templates."
argument-hint: "[UI feature description] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/team-ui/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
When this skill is invoked, orchestrate the UI team through a structured pipeline.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

`review_mode` sets gate depth:
- `full` — spawn all director and lead gates as described
- `lean` — skip director gates unless they are PHASE-GATE type (CD-PHASE-GATE, TD-PHASE-GATE, PR-PHASE-GATE, AD-PHASE-GATE)
- `solo` — skip all director gate spawning entirely; run the skill without any agent gates

`automation` drives the Decision Points note above. See the Decision Points note above and
`.claude/docs/automation-modes.md` for how each mode changes pipeline behavior.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `ui-programmer` + `ux-designer`. Other agents consulted via these two, not spawned separately.
- **`small`**: + `accessibility-specialist` + `art-director`.
- **`studio`**: + engine UI specialist + an adversarial review pass.
Directors (CD/TD/PR) still spawn at phase gates regardless of size; a non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point before the pipeline advances** — not every phase. Apply the test literally: if the phase below has no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Announce the active set before Step 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. Both sets differ per orchestrator.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents — `team-release` names eight and runs one, `team-narrative`
names six across five phases and runs `writer` alone. **The collapse is correct**:
`team.size` is rigor-fronted and the narrow default is the token lever, measured
at roughly 10x. What was wrong is that nothing said so, so a reader could not
distinguish a correctly-collapsed run from a broken pipeline, and the per-agent
"routes through the nearest core agent with an informational note" rule above
fires at routing time and never states the shape of the run as a whole.

This is the same rule as the skipped-check reporting elsewhere in this file: **a constraint that is enforced but never surfaced is
indistinguishable, to the person reading the output, from one that was never
enforced.**

**Director gate skip rule**: Before spawning creative-director, art-director, or any other Tier 1/2 director for review (outside of PHASE-GATE triggers), apply the resolved mode: skip if solo mode; skip if lean mode and this is not a PHASE-GATE.

## Team Composition
- **ux-designer** — User flows, wireframes, accessibility, input handling
- **ui-programmer** — UI framework, screens, widgets, data binding, implementation
- **art-director** — Visual style, layout polish, consistency with art bible
- **engine UI specialist** — Validates UI implementation patterns against engine-specific best practices (`specialists.ui` from `project.yaml`; if absent, the UI Specialist line of `## Engine Specialists` in `.claude/docs/technical-preferences.md`)
- **accessibility-specialist** — Audits accessibility compliance at Phase 4

> **`specialists.ui: null` means UNSET.** Treat it as absent and skip the engine
> UI specialist; never spawn `null` as an agent name. The v1.0 migration writes
> the whole `specialists` block whenever any one member is set, so `null` here is
> ordinary — and the config reader returns it as the non-empty string `"null"`.

**Templates used by this pipeline:**
- `ux-spec.md` — Standard screen/flow UX specification
- `hud-design.md` — HUD-specific UX specification
- `interaction-pattern-library.md` — Reusable interaction patterns
- `accessibility-requirements.md` — Committed accessibility tier and requirements

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: ux-designer` — User flows, wireframes, accessibility, input handling
- `subagent_type: ui-programmer` — UI framework, screens, widgets, data binding
- `subagent_type: art-director` — Visual style, layout polish, art bible consistency
- `subagent_type: [UI engine specialist]` — Engine-specific UI pattern validation (e.g., unity-ui-specialist, ue-umg-specialist, godot-specialist)
- `subagent_type: accessibility-specialist` — Accessibility compliance audit

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs.

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight — the same call already made for `consistency-check` appending to `active.md`. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or `tests/`, never an edit to existing source or config; (3) the phase that produced it is itself gated by an `AskUserQuestion` before the pipeline advances. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

Launch independent agents in parallel where the pipeline allows it (e.g., Phase 4 review agents can run simultaneously).

## Pipeline

### Phase 1a: Context Gathering

Before designing anything, read and synthesize:
- `design/gdd/game-concept.md` — platform targets and intended audience
- `design/player-journey.md` — player's state and context when they reach this screen
- All GDD UI Requirements sections relevant to this feature
- `design/ux/interaction-patterns.md` — existing patterns to reuse (not reinvent)
- `design/accessibility-requirements.md` — committed accessibility tier (e.g., Basic, Enhanced, Full)

**Report the status of every document above before designing anything.** Phase 1a
reads five inputs; for a long time only the pattern library was guarded, and the
other four could be absent without anything noticing. List each as
present or ABSENT.

**`design/accessibility-requirements.md` is the one that must not pass silently.**
It carries the committed accessibility tier, which **Phase 3 implements against**
and **Phase 4 gates on** ("verify compliance against the committed accessibility
tier … flag any violations as blockers"). If the file is missing there is no tier,
so that gate has no criterion and would pass while checking nothing — a gate made
of an absent standard, the same shape as an assertion that can never fail. When it
is absent:
- Say so here, and carry it forward: **Phase 4 must report
  `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)`
  and must NOT report the accessibility gate as passed.**
- The ux-designer states which tier they designed against as an explicit
  assumption, so a later reader can see it was assumed rather than committed.
- Recommend `/ux-design accessibility` to establish the tier.

Absence of `design/gdd/game-concept.md`, `design/player-journey.md` or
`design/ux/hud.md` is not blocking, but name each missing one in the brief you
pass to the ux-designer so they design knowing what context they lack, rather
than inferring it.

**If `design/ux/interaction-patterns.md` does not exist**, surface the gap immediately:
> "interaction-patterns.md does not exist — no existing patterns to reuse."

Then use `AskUserQuestion` with options:
- (a) Run `/ux-design patterns` first to establish the pattern library, then continue
- (b) Proceed without the pattern library — ui-programmer will treat all patterns created as new and add each to a new `design/ux/interaction-patterns.md` at completion

Do NOT invent or assume patterns from the feature name or GDD alone. If the user chooses (b), explicitly instruct ui-programmer in Phase 3 to treat all patterns as new and document them in `design/ux/interaction-patterns.md` when implementation is complete. Note the pattern library status (created / absent / updated) in the final summary report.

Summarize the context in a brief for the ux-designer: what the player is doing, what they need, what constraints apply, and which existing patterns are relevant.

### Phase 1b: UX Spec Authoring

Invoke `/ux-design [feature name]` skill OR delegate directly to ux-designer to produce `design/ux/[feature-name].md` following the `ux-spec.md` template.

If designing the HUD, use the `hud-design.md` template instead of `ux-spec.md`.

> **Notes on special cases:**
> - For HUD design specifically, invoke `/ux-design` with `argument: hud` (e.g., `/ux-design hud`).
> - For the interaction pattern library, run `/ux-design patterns` once at project start and update it whenever new patterns are introduced during later phases.

Output: `design/ux/[feature-name].md` with all required spec sections filled.

### Phase 1c: UX Review

After the spec is complete, invoke `/ux-review design/ux/[feature-name].md`.

**Gate**: Do not proceed to Phase 2 until the verdict is APPROVED. If the verdict is NEEDS REVISION, the ux-designer must address the flagged issues and re-run the review. The user may explicitly accept a NEEDS REVISION risk and proceed, but this must be a conscious decision — present the specific concerns via `AskUserQuestion` before asking whether to proceed.

### Phase 2: Visual Design

Delegate to **art-director**:
- Review the full UX spec (flows, wireframes, interaction patterns, accessibility notes) — not just the wireframe images
- Apply visual treatment from the art bible: colors, typography, spacing, animation style
- Check that visual design preserves accessibility compliance: verify color contrast ratios, and confirm color is never the only indicator of state (shape, text, or icon must reinforce it)
- Specify all asset requirements needed from the art pipeline: icons at specified sizes, background textures, fonts, decorative elements — with precise dimensions and format requirements
- Ensure consistency with existing implemented UI screens
- Output: visual design spec with style notes and asset manifest

### Phase 3: Implementation

Before implementation begins, spawn the **engine UI specialist** (`specialists.ui` from `project.yaml`; if absent, the UI Specialist line of `## Engine Specialists` in `.claude/docs/technical-preferences.md`) to review the UX spec and visual design spec for engine-specific implementation guidance:
- Which engine UI framework should be used for this screen? (e.g., UI Toolkit vs UGUI in Unity, Control nodes vs CanvasLayer in Godot, UMG vs CommonUI in Unreal)
- Any engine-specific gotchas for the proposed layout or interaction patterns?
- Recommended widget/node structure for the engine?
- Output: engine UI implementation notes to hand off to ui-programmer before they begin

If no engine is configured, skip this step. **Record `Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.

Delegate to **ui-programmer**:
- Implement the UI following the UX spec and visual design spec
- **Use patterns from `design/ux/interaction-patterns.md`** — do not reinvent patterns that are already specified. If a pattern almost fits but needs modification, note the deviation and flag it for ux-designer review.
- **UI NEVER owns or modifies game state** — display only; emit events for all player actions
- All text through the localization system — no hardcoded player-facing strings
- Support both input methods (keyboard/mouse AND gamepad)
- Implement accessibility features per the committed tier in `design/accessibility-requirements.md`
- Wire up data binding to game state
- **If any new interaction pattern is created during implementation** (i.e., something not already in the pattern library), add it to `design/ux/interaction-patterns.md` before marking implementation complete
- Output: implemented UI feature

### Phase 4: Review (parallel)

Delegate in parallel:
- **ux-designer**: Verify implementation matches wireframes and interaction spec. Test keyboard-only and gamepad-only navigation. Check accessibility features function correctly.
- **art-director**: Verify visual consistency with art bible. Check at minimum and maximum supported resolutions.
- **accessibility-specialist**: Verify compliance against the committed accessibility tier documented in `design/accessibility-requirements.md`. Flag any violations as blockers. **If that file is absent there is no committed tier, so this gate has no criterion: report `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)` and do NOT report the gate as passed**. Carry forward whatever tier Phase 1a recorded as assumed, and say plainly that it was assumed.

All three review streams must report before proceeding to Phase 5.

### Phase 5: Polish

- Address all review feedback
- Verify animations are skippable and respect the player's motion reduction preferences
- Confirm UI sounds trigger through the audio event system (no direct audio calls)
- Test at all supported resolutions and aspect ratios
- **Verify `design/ux/interaction-patterns.md` is up to date** — if any new patterns were introduced during this feature's implementation, confirm they have been added to the library
- **Confirm all HUD elements respect the visual budget** defined in `design/ux/hud.md` (element count, screen region allocations, maximum opacity values)

## Quick Reference — When to Use Which Skill

- `/ux-design` — Author a new UX spec for a screen, flow, or HUD from scratch
- `/ux-review` — Validate a completed UX spec before implementation
- `/team-ui [feature]` — Full pipeline from concept through polish (calls `/ux-design` and `/ux-review` internally)
- `/quick-design` — Small UI changes that don't need a full new UX spec

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
- ADR status is Proposed → do not implement; run `/architecture-decision` first
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess

## File Write Protocol

All file writes (UX specs, interaction pattern library updates, implementation files) are
delegated to sub-agents and sub-skills. The two follow **different** rules:

- **Sub-agents spawned via `Agent`** (e.g. `ui-programmer`) follow the **bounded
  exception** documented above under "Why this does not violate the Collaboration
  Protocol" — the path is one you named, the artifact is new under `production/`,
  `docs/` or `tests/`, and the phase is gated by an `AskUserQuestion`. A sub-agent
  does **not** prompt per write inside those bounds; outside them it must ask.
- **Sub-skills** (`/ux-design`) are not sub-agents and the exception does not reach
  them. They follow the normal Collaboration Protocol and ask before writing.

This orchestrator does not write files directly.

## Output

A summary report covering: UX spec status, UX review verdict, visual design status, implementation status, accessibility compliance, input method support, interaction pattern library update status, and any outstanding issues.

Verdict: **COMPLETE** — UI feature delivered through full pipeline (UX spec → visual → implementation → review → polish).
Verdict: **BLOCKED** — pipeline halted; surface the blocker and its phase before stopping.

## Next Steps

- Run `/ux-review` on the final spec if not yet approved.
- Run `/code-review` on the UI implementation before closing stories.
- Run `/team-polish` if visual or audio polish pass is needed.
