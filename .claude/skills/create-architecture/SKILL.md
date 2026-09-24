---
name: create-architecture
description: "Author the architecture blueprint before code is written. Validates decisions against the pinned engine, flags knowledge gaps."
argument-hint: "[focus-area: full | layers | data-flow | api-boundaries | adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/create-architecture/../../hooks/yaml-helper.sh" resolve_config *)
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
`docs.density` explicitly to vary depth alone: `terse` = layer diagrams + decision bullets,
no essays; `balanced` = diagrams + paragraph explanations of layer choices
(default); `thorough` = full prose with rationale, trade-offs, and alternatives
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

Before anything else, load the full project context in this order:

### 0a. Engine Context (Critical)

Read the four project-wide engine documents in full — they are small, and every
part of each is used:

1. `docs/engine-reference/[engine]/VERSION.md`
   → Extract: engine name, version, LLM cutoff, post-cutoff risk levels
2. `docs/engine-reference/[engine]/breaking-changes.md`
   → Extract: all HIGH and MEDIUM risk changes
3. `docs/engine-reference/[engine]/deprecated-apis.md`
   → Extract: APIs to avoid
4. `docs/engine-reference/[engine]/current-best-practices.md`
   → Extract: post-cutoff best practices that differ from training data

Then read **only the module docs whose domain this game actually uses** —
not the whole `modules/` directory:

5. `docs/engine-reference/[engine]/modules/` — glob it to establish what exists,
   then match against the domains present in `design/gdd/systems-index.md`
   (the same domain vocabulary the ADR template uses: Physics, Rendering, UI,
   Audio, Navigation, Animation, Networking, Core, Input). Read the matching
   modules; skip the rest.
   → Extract: current API patterns per domain

   A game with no multiplayer system does not need the networking module loaded
   to write its architecture, and loading it costs the same as one that does.
   **If the domain match is ambiguous, read the module** — a missed engine
   constraint is far more expensive here than a redundant read, because this
   phase is where those constraints get baked into the architecture.

If no engine is configured, stop and prompt:
> "No engine is configured. Run `/setup-engine` first. Architecture cannot be
> written without knowing which engine and version you are targeting."

### 0b. Design Context + Technical Requirements Extraction

Load the approved design documents and extract technical requirements from each:

1. `design/gdd/game-concept.md` — game pillars, genre, core loop
2. `design/gdd/systems-index.md` — all systems, dependencies, priority tiers

**Check both exist before reading either. Neither is optional here, and both
need an absence branch** — §0a stops for an unconfigured engine, and these two
matter just as much:

- **`systems-index.md` absent** — stop:
  > "No systems index found. Run `/map-systems` first. An architecture written
  > without it invents layers for systems nobody mapped, and every ADR, epic and
  > story downstream inherits that invention."
  At `minimal` the index is not required (§ tier note above) — say so and proceed
  from the brief instead.
- **`game-concept.md` absent** — at `standard`/`full`, stop and point at
  `/brainstorm`. At `minimal`, read `design/game-brief.md` in its place; if that
  is absent too, stop — there is no design record to architect against.
- **Either present but empty or still template placeholders** — treat as absent.
  Present-but-empty is the case that most looks like present.

Do not proceed on a partial read and note it later. This phase is where design
assumptions get baked into ADRs, and an assumption made here is re-derived by
everything downstream rather than re-checked.
3. Project config — `naming.*` and `performance.*` from `project.yaml` (for any
   key absent or empty, fall back to `.claude/docs/technical-preferences.md`);
   allowed libraries and forbidden patterns from
   `.claude/docs/technical-preferences.md` (not migrated to project.yaml)
4. **Every GDD in `design/gdd/`** — extract technical requirements from the
   sections that carry them, **not from whole files**. Establish the denominator
   first (glob `design/gdd/*.md`, count **N**), then:
   ```
   Grep pattern="^## (Detailed Rules|Detailed Design|Formulas|Dependencies|Tuning Knobs|Acceptance Criteria)" glob="design/gdd/*.md" output_mode="content" -A 40
   ```
   Overview and Player Fantasy are narrative and imply no architecture; the
   scanned set is where rules, numbers, and cross-system contracts live. Accept
   either `## Detailed Rules` or `## Detailed Design` — the design standard and
   the GDD template disagree on the name and they denote the same section.

   Full-read a GDD when it matched **zero** sections (it predates the template —
   a zero-match means "unstructured", never "no requirements") or when a scanned
   section refers to material outside itself. **Never treat an absent section as
   an absent requirement**: report any GDD that contributed nothing, rather than
   letting it drop silently out of the baseline below.

   For each, extract:
   - Data structures implied by the game rules
   - Performance constraints stated or implied
   - Engine capabilities the system requires
   - Cross-system communication patterns (what talks to what, how)
   - State that must persist (save/load implications)
   - Threading or timing requirements

Build a **Technical Requirements Baseline** — a flat list of all extracted
requirements across all GDDs, numbered `TR-[gdd-slug]-[NNN]`. This is the
complete set of what the architecture must cover. Present it as:

```
## Technical Requirements Baseline
Extracted from [N] GDDs | [X] total requirements

| Req ID | GDD | System | Requirement | Domain |
|--------|-----|--------|-------------|--------|
| TR-combat-001 | combat.md | Combat | Hitbox detection per-frame | Physics |
| TR-combat-002 | combat.md | Combat | Combo state machine | Core |
| TR-inventory-001 | inventory.md | Inventory | Item persistence | Save/Load |
```

This baseline feeds into every subsequent phase. No GDD requirement should be
left without an architectural decision to support it by the end of this session.

### 0c. Existing Architecture Decisions

To learn **what has already been decided and in which domain**, scan the ADR
headers — do not full-read every ADR to produce a list of numbers and domains:
```
Grep pattern="^## (Status|Summary)" glob="docs/architecture/adr-*.md" output_mode="content" -A 4
Grep pattern="\*\*Domain\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
```
`## Summary` (a 2-sentence what-and-why) plus `## Status` and the Engine
Compatibility `Domain` field are exactly "what was decided and its domain". List
the ADRs found, their status, and their domains from the scan. Full-read a
specific ADR only when a new decision this session would collide with it and you
need its reasoning — not to build the inventory.

### 0d. Generate Knowledge Gap Inventory

Before proceeding, display a structured summary:

```
## Engine Knowledge Gap Inventory
Engine: [name + version]
LLM Training Covers: up to approximately [version]
Post-Cutoff Versions: [list]

### HIGH RISK Domains (must verify against engine reference before deciding)
- [Domain]: [Key changes]

### MEDIUM RISK Domains (verify key APIs)
- [Domain]: [Key changes]

### LOW RISK Domains (in training data, likely reliable)
- [Domain]: [no significant post-cutoff changes]

### Systems from GDD that touch HIGH/MEDIUM risk domains:
- [GDD system name] → [domain] → [risk level]
```

Use `AskUserQuestion`:
- Prompt: "One or more engine domains are HIGH RISK — the LLM's knowledge may be unreliable for these areas. Architectural recommendations in these domains should be cross-referenced with the engine docs before being acted on. How would you like to proceed?"
- Options:
  - `[A] Proceed — flag HIGH RISK domains throughout the output`
  - `[B] Let me check the engine reference first — pause here`
  - `[C] Show me which domains are HIGH RISK and why`

---

## Phase 1: System Layer Mapping

Map every system from `systems-index.md` into an architecture layer. The standard
game architecture layers are:

```
┌─────────────────────────────────────────────┐
│  PRESENTATION LAYER                         │  ← UI, HUD, menus, VFX, audio
├─────────────────────────────────────────────┤
│  FEATURE LAYER                              │  ← gameplay systems, AI, quests
├─────────────────────────────────────────────┤
│  CORE LAYER                                 │  ← physics, input, combat, movement
├─────────────────────────────────────────────┤
│  FOUNDATION LAYER                           │  ← engine integration, save/load,
│                                             │    scene management, event bus
├─────────────────────────────────────────────┤
│  PLATFORM LAYER                             │  ← OS, hardware, engine API surface
└─────────────────────────────────────────────┘
```

For each GDD system, ask:
- Which layer does it belong to?
- What are its module boundaries?
- What does it own exclusively? (data, state, behaviour)

Present the proposed layer assignment and ask for approval before proceeding to
the next section. Write the approved layer map immediately to the skeleton file.

**Engine awareness check**: For each system assigned to the Core and Foundation
layers, flag if it touches a HIGH or MEDIUM risk engine domain. Show the relevant
engine reference excerpt inline.

---

## Phase 2: Module Ownership Map

For each module defined in Phase 1, define ownership:

- **Owns**: what data and state this module is solely responsible for
- **Exposes**: what other modules may read or call
- **Consumes**: what it reads from other modules
- **Engine APIs used**: which specific engine classes/nodes/signals this module
  calls directly (with version and risk level noted)

Format as a table per layer, then as an ASCII dependency diagram.

**Engine awareness check**: For every engine API listed, verify against the
relevant module reference doc. If an API is post-cutoff, flag it:

```
⚠️  [ClassName.method()] — Godot 4.6 (post-cutoff, HIGH risk)
    Verified against: docs/engine-reference/godot/modules/[domain].md
    Behaviour confirmed: [yes / NEEDS VERIFICATION]
```

Get user approval on the ownership map before writing.

---

## Phase 3: Data Flow

Define how data moves between modules during key game scenarios. Cover at minimum:

1. **Frame update path**: Input → Core systems → State → Rendering
2. **Event/signal path**: How systems communicate without tight coupling
3. **Save/load path**: What state is serialised, which module owns serialisation
4. **Initialisation order**: Which modules must boot before others

Use ASCII sequence diagrams where helpful. For each data flow:
- Name the data being transferred
- Identify the producer and consumer
- State whether this is synchronous call, signal/event, or shared state
- Flag any data flows that cross thread boundaries

Get user approval per scenario before writing.

---

## Phase 4: API Boundaries

Define the public contracts between modules. For each boundary:

- What is the interface a module exposes to the rest of the system?
- What are the entry points (functions/signals/properties)?
- What invariants must callers respect?
- What must the module guarantee to callers?

Write in pseudocode or the project's actual language (from technical preferences).
These become the contracts programmers implement against.

**Engine awareness check**: If any interface uses engine-specific types (e.g.
`Node`, `Resource`, `Signal` in Godot), flag the version and verify the type
exists and has not changed signature in the target engine version.

---

## Phase 5: ADR Audit + Traceability Check

Review all existing ADRs from Phase 0c against both the architecture built in
Phases 1-4 AND the Technical Requirements Baseline from Phase 0b.

### ADR Quality Check

For each ADR:
- [ ] Does it have an Engine Compatibility section?
- [ ] Is the engine version recorded?
- [ ] Are post-cutoff APIs flagged?
- [ ] Does it have a "GDD Requirements Addressed" section?
- [ ] Does it conflict with the layer/ownership decisions made in this session?
- [ ] Is it still valid for the pinned engine version?

| ADR | Engine Compat | Version | GDD Linkage | Conflicts | Valid |
|-----|--------------|---------|-------------|-----------|-------|
| ADR-0001: [title] | ✅/❌ | ✅/❌ | ✅/❌ | None/[conflict] | ✅/⚠️ |

### Traceability Coverage Check

Map every requirement from the Technical Requirements Baseline to existing ADRs.
For each requirement, check if any ADR's "GDD Requirements Addressed" section
or decision text covers it:

| Req ID | Requirement | ADR Coverage | Status |
|--------|-------------|--------------|--------|
| TR-combat-001 | Hitbox detection per-frame | ADR-0003 | ✅ |
| TR-combat-002 | Combo state machine | — | ❌ GAP |

Count: X covered, Y gaps. For each gap, it becomes a **Required New ADR**.

### Required New ADRs

List all decisions made during this architecture session (Phases 1-4) that do
not yet have a corresponding ADR, PLUS all uncovered Technical Requirements.
Group by layer — Foundation first:

**Foundation Layer (must create before any coding):**
- `/architecture-decision [title]` → covers: TR-[id], TR-[id]

**Core Layer:**
- `/architecture-decision [title]` → covers: TR-[id]

---

## Phase 6: Missing ADR List

Based on the full architecture, produce a complete list of ADRs that should exist
but don't yet. Group by priority:

**Must have before coding starts (Foundation & Core decisions):**
- [e.g. "Scene management and scene loading strategy"]
- [e.g. "Event bus vs direct signal architecture"]

**Should have before the relevant system is built:**
- [e.g. "Inventory serialisation format"]

**Can defer to implementation:**
- [e.g. "Specific shader technique for water"]

---

## Phase 7: Write the Master Architecture Document

Once all sections are approved, write the complete document to
`docs/architecture/architecture.md`.

Display a one-paragraph summary of what the document will contain (layers, modules, data flows, ADR gaps). Then use `AskUserQuestion`:
- "All sections approved. May I write the master architecture document?"
  - [A] Yes — write to `docs/architecture/architecture.md` now
  - [B] Show me the full draft inline first, then ask again
  - [C] Not yet — I have more changes to discuss

The document structure:

```markdown
# [Game Name] — Master Architecture

## Document Status
- Version: [N]
- Last Updated: [date]
- Engine: [name + version]
- GDDs Covered: [list]
- ADRs Referenced: [list]

## Engine Knowledge Gap Summary
[Condensed from Phase 0d inventory — HIGH/MEDIUM risk domains and their implications]

## System Layer Map
[From Phase 1]

## Module Ownership
[From Phase 2]

## Data Flow
[From Phase 3]

## API Boundaries
[From Phase 4]

## ADR Audit
[From Phase 5]

## Required ADRs
[From Phase 6]

## Architecture Principles
[3-5 key principles that govern all technical decisions for this project,
derived from the game concept, GDDs, and technical preferences]

## Open Questions
[Decisions deferred — must be resolved before the relevant layer is built]
```

---

## Phase 7b: Technical Director Sign-Off + Lead Programmer Feasibility Review

After writing the master architecture document, perform an explicit sign-off before handoff.

**Step 1 — Technical Director self-review** (this skill runs as technical-director):

Apply gate **TD-ARCHITECTURE** (`.claude/docs/director-gates/td-architecture.md`) as a self-review. Check all four criteria from that gate definition against the completed document.

**Review mode check** — apply before spawning LP-FEASIBILITY:
- `solo` → skip. Note: "LP-FEASIBILITY skipped — Solo mode." Proceed to Phase 8 handoff.
- `lean` → skip (not a PHASE-GATE). Note: "LP-FEASIBILITY skipped — Lean mode." Proceed to Phase 8 handoff.
- `full` → spawn as normal.

**Step 2 — Spawn `lead-programmer` via `Agent` using gate LP-FEASIBILITY (`.claude/docs/director-gates/lp-feasibility.md`):**

Pass: architecture document path, technical requirements baseline summary, ADR list.

**Step 3 — Present both assessments to the user:**

Show the Technical Director assessment and Lead Programmer verdict side by side.

Use `AskUserQuestion` — "Technical Director and Lead Programmer have reviewed the architecture. How would you like to proceed?"
Options: `Accept — proceed to handoff` / `Revise flagged items first` / `Discuss specific concerns`

**Step 4 — Record sign-off in the architecture document:**

Update the Document Status section:
```
- Technical Director Sign-Off: [date] — APPROVED / APPROVED WITH CONDITIONS
- Lead Programmer Feasibility: FEASIBLE / CONCERNS ACCEPTED / REVISED
```

Show the proposed Document Status block inline, then use `AskUserQuestion`:
- "May I update the Document Status section with the sign-off results?"
  - [A] Yes — apply to `docs/architecture/architecture.md`
  - [B] Not yet — I want to revisit the concerns first

---

## Phase 8: Handoff

**Step 1 — Update session state**: Write a summary to `production/session-state/active.md` covering: artifact written, TD/LP sign-off verdicts, any blockers, required ADRs remaining, and next step.

**Step 2 — Output the handoff** using exactly this template (no freeform prose, no rephrasing of section titles):

---

## Architecture Complete

`docs/architecture/architecture.md` v1.0 — [TD verdict: APPROVED / APPROVED WITH CONCERNS / CONCERNS]. [One sentence on what the architecture covers.]

---

## Run These ADRs Next

**1. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence: what it defines and what it unblocks.]

**2. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence.]

**3. `/architecture-decision "[Title]"` → ADR-[XXXX]**
[One sentence.]

List top 3 from Phase 6 in priority order. If fewer than 3 remain, list only what's outstanding.

---

## Gate-Check Readiness

> **Required before `/gate-check [stage]`:**
> - [ ] Accept ADRs: [list Proposed ADR IDs that must be Accepted]
> - [ ] Write ADRs: [list ADR IDs that must still be written]
> - [ ] Run `/test-setup` — scaffolds `tests/unit/`, `tests/integration/`, CI workflow, and an example test file
> - [ ] Run `/ux-design` — creates `design/ux/interaction-patterns.md` and `design/accessibility-requirements.md`
>
> Run `/gate-check [stage]` when all boxes are checked.

If nothing is blocking, write instead:
> No blockers — run `/gate-check [stage]` now.

---

## Open Questions to Watch

| ID | Summary | Priority | Resolution Path |
|----|---------|----------|-----------------|
| QQ-XX | [short description] | High / Medium / Low | [ADR or system that resolves it] |

Omit this section entirely if there are no open QQs.

---

(End of handoff. Do not add trailing commentary after the closing rule.)

---

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
6. **Incremental writing** — write each approved section immediately; do not
   accumulate everything and write at the end. This survives session crashes.

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
