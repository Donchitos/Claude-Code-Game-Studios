---
name: create-architecture
description: "Author the architecture blueprint before code is written. Validates decisions against the pinned engine, flags knowledge gaps."
argument-hint: "[focus-area: full | layers | data-flow | api-boundaries | adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/create-architecture/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Create Architecture

This skill produces `docs/architecture/architecture.md` — the master architecture
document that translates all approved GDDs into a concrete technical blueprint.
It sits between design and implementation, and must exist before sprint planning begins.

**Distinct from `/architecture-decision`**: ADRs record individual point decisions.
This skill creates the whole-system blueprint that gives ADRs their context.

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = layer diagrams + decision bullets,
no essays; `balanced` = diagrams + paragraph explanations of layer choices
(`rigor: standard`); `thorough` = full prose with rationale, trade-offs, and alternatives
considered per layer. Apply it to every section you author.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full architecture: all layers, module ownership, data flow, API
  boundaries, full ADR audit.
- `standard` — simplified: system layer map + critical ADR list only.
- `minimal` — not required. Can still be run voluntarily.

**Argument modes:**
- **No argument / `full`**: Full guided walkthrough — all sections, start to finish
- **`layers`**: Focus on the system layer diagram only
- **`data-flow`**: Focus on data flow between modules only
- **`api-boundaries`**: Focus on API boundary definitions only
- **`adr-audit`**: Audit existing ADRs for engine compatibility gaps only

---

## Phase 0: Load All Context

**Read `references/0-load-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 1: System Layer Mapping

**Read `references/1-layers.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Module Ownership Map

**Read `references/2-module-ownership.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Data Flow

**Read `references/3-data-flow.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: API Boundaries

**Read `references/4-api-boundaries.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: ADR Audit + Traceability Check

**Read `references/5-adr-audit.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Missing ADR List

**Read `references/6-missing-adrs.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Write the Master Architecture Document

**Read `references/7-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Handoff

**Read `references/8-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

This skill follows the collaborative design principle at every phase:

1. **Load context silently** — do not narrate file reads
2. **Present findings** — show the knowledge gap inventory and layer proposals
3. **Ask before deciding** — present options for each architectural choice
4. **Draft before approval** — show the content inline before asking to write it.
   Never ask approval for a section the user has not yet seen.
5. **Use `AskUserQuestion` for write approvals** — plain text "May I?" is not
   sufficient. Use the structured tool with labeled options [A]/[B]/[C] (write now /
   show full draft first / not yet). For multi-file changesets, list every file
   and what changes, then ask once grouped — not separate plain-text asks per file.
6. **One write, after every section is approved** — the document is written once,
   at Phase 7; Phase 7b's Step 4 only updates its Document Status, after its own
   ask. Record each approved section's decisions in
   `production/session-state/active.md` as you go, so a crash loses no decision.
   A revision that Phase 7b forces is written the same way — once, after its
   re-drafted sections are approved — and an update (Phase 0e) writes only the
   sections it chose.

Never make a binding architectural decision without user input. If the user is
unsure, present 2-4 options with pros/cons before asking them to decide.

---

## Recommended Next Steps

- Run `/architecture-decision [title]` for each required ADR listed in Phase 6 — Foundation layer ADRs first
- Run `/architecture-review` — bootstraps the Requirements Traceability Matrix and TR registry from the ADRs just written. Required before the Pre-Production gate.
- Run `/test-setup` to scaffold `tests/unit/`, `tests/integration/`, CI workflow, and an example test (required for gate-check)
- Run `/ux-design` to initialize `design/ux/interaction-patterns.md` and `design/accessibility-requirements.md` (required for gate-check)
- Run `/create-control-manifest` once the required ADRs are written to produce the layer rules manifest
- Run `/gate-check pre-production` when all required ADRs, `/test-setup`, and `/ux-design` are complete
