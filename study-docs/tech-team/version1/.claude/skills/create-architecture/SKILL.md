---
name: create-architecture
description: "Guided, section-by-section authoring of the master architecture document. Reads all feature specs (indexed by tr-registry), existing ADRs, and technical preferences, and validates UE 5.8 API decisions via Context7. Produces a complete architecture blueprint before any code is written."
argument-hint: "[focus-area: full | layers | data-flow | api-boundaries | adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash, AskUserQuestion, Task, run_mcp
model: sonnet
agent: technical-director
---

# Create Architecture

This skill produces `docs/architecture/architecture.md` — the master architecture
document that translates all approved feature specs into a concrete technical blueprint.
It sits between requirements and implementation, and must exist before epic creation begins.

**Distinct from `/architecture-decision`**: ADRs record individual point decisions.
This skill creates the whole-system blueprint that gives ADRs their context.

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

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

The engine is fixed at Unreal Engine 5.8 and the knowledge source is Context7 MCP.
There is no static `docs/engine-reference/` directory to read.

1. Read `.claude/docs/technical-preferences.md`
   → Extract: engine (UE 5.8), naming conventions, performance budgets, forbidden patterns, knowledge-authority rule
2. Read `.claude/docs/engine-specialists.md`
   → Extract: UE sub-specialist roster and routing table
3. **Resolve the library ID**: call Context7 `resolve-library-id(libraryName: "Unreal Engine")`.
4. For each major UE subsystem this architecture will touch (Rendering, GAS, Enhanced Input, Subsystems, Networking, etc.), call Context7 `query-docs` with the specific API/class names to confirm 5.8 signatures. WebSearch fallback to `docs.unrealengine.com/5.8/` when Context7 returns nothing.
5. Build a **UE 5.8 API Risk Inventory** — which APIs the architecture will depend on, and which carry 5.4+ changes (HIGH risk) vs. stable (LOW risk).

If no engine is configured (technical-preferences.md missing or Engine field is `[TO BE CONFIGURED]`), stop and prompt:
> "No engine is configured. Run `/setup-engine` first. Architecture cannot be
> written without the UE 5.8 technical contract."

### 0b. Requirements Context + Technical Requirements Extraction

The requirement source is the **feature spec** indexed by `docs/architecture/tr-registry.yaml`
(this team has no GDDs). Read all approved requirement sources and extract technical
requirements from each:

1. `docs/architecture/tr-registry.yaml` — the authoritative requirement index. Each entry has `id`, `requirement` text, and a `source` path pointing to a feature spec.
2. For each unique `source` feature spec referenced by the registry: read the spec and extract:
   - Data structures implied by the requirements
   - Performance constraints stated or implied
   - UE capabilities the system requires
   - Cross-system communication patterns (what talks to what, how)
   - State that must persist (save/load implications)
   - Threading or timing requirements
3. `.claude/docs/technical-preferences.md` — naming conventions, performance budgets, allowed libraries, forbidden patterns (already loaded in 0a)

Build a **Technical Requirements Baseline** — a flat list of all extracted
requirements across all feature specs, numbered `TR-[feature-slug]-[NNN]` (reuse
IDs from tr-registry where they exist — do not renumber). This is the complete set
of what the architecture must cover. Present it as:

```
## Technical Requirements Baseline
Extracted from [N] feature specs | [X] total requirements

| Req ID | Feature Spec | System | Requirement | Domain |
|--------|--------------|--------|-------------|--------|
| TR-combat-001 | docs/requirements/combat.md | Combat | Hitbox detection per-frame | Physics |
| TR-combat-002 | docs/requirements/combat.md | Combat | Combo state machine | Core |
| TR-inventory-001 | docs/requirements/inventory.md | Inventory | Item persistence | Save/Load |
```

This baseline feeds into every subsequent phase. No requirement should be
left without an architectural decision to support it by the end of this session.

### 0c. Existing Architecture Decisions

Read all files in `docs/architecture/` to understand what has already been decided.
List any ADRs found and their domains.

### 0d. Generate UE 5.8 API Risk Inventory

Before proceeding, display a structured summary:

```
## UE 5.8 API Risk Inventory
Engine: Unreal Engine 5.8
Knowledge Source: Context7 MCP
Library ID: [from resolve-library-id]

### HIGH RISK APIs (5.4+ changes — must verify via Context7 before deciding)
- [API]: [Key changes verified this session]

### MEDIUM RISK APIs (verify key signatures)
- [API]: [Key changes]

### LOW RISK APIs (stable since training cutoff)
- [API]: [no significant post-cutoff changes]

### Requirement domains that touch HIGH/MEDIUM risk APIs:
- [feature spec system] → [API] → [risk level]
```

Use `AskUserQuestion`:
- Prompt: "One or more UE 5.8 APIs are HIGH RISK — the LLM's training data may be unreliable for these. Architectural recommendations in these areas have been verified via Context7. How would you like to proceed?"
- Options:
  - `[A] Proceed — flag HIGH RISK APIs throughout the output`
  - `[B] Let me re-query Context7 for specific APIs first — pause here`
  - `[C] Show me which APIs are HIGH RISK and why`

---

## Phase 1: System Layer Mapping

Map every system from the requirement baseline into an architecture layer. The standard
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

For each requirement system, ask:
- Which layer does it belong to?
- What are its module boundaries?
- What does it own exclusively? (data, state, behaviour)

Present the proposed layer assignment and ask for approval before proceeding to
the next section. Write the approved layer map immediately to the skeleton file.

**UE API awareness check**: For each system assigned to the Core and Foundation
layers, flag if it touches a HIGH or MEDIUM risk UE API (from Phase 0d). Show the
relevant Context7 verification result inline.

---

## Phase 2: Module Ownership Map

For each module defined in Phase 1, define ownership:

- **Owns**: what data and state this module is solely responsible for
- **Exposes**: what other modules may read or call
- **Consumes**: what it reads from other modules
- **UE APIs used**: which specific UE classes/delegates/subsystems this module
  calls directly (with risk level from the Phase 0d inventory)

Format as a table per layer, then as an ASCII dependency diagram.

**UE API awareness check**: For every UE API listed, verify against the
Context7 results from Phase 0a. If an API is HIGH risk, flag it:

```
⚠️  UAbilitySystemComponent::ApplyGameplayEffectToTarget — UE 5.8 (HIGH risk)
    Verified via: Context7 query-docs "UAbilitySystemComponent ApplyGameplayEffectToTarget 5.8"
    Behaviour confirmed: [yes / NEEDS VERIFICATION — re-query Context7]
```

Get user approval on the ownership map before writing.

---

## Phase 3: Data Flow

Define how data moves between modules during key game scenarios. Cover at minimum:

1. **Frame update path**: Input → Core systems → State → Rendering
2. **Event/delegate path**: How systems communicate without tight coupling
3. **Save/load path**: What state is serialised, which module owns serialisation
4. **Initialisation order**: Which modules must boot before others

Use ASCII sequence diagrams where helpful. For each data flow:
- Name the data being transferred
- Identify the producer and consumer
- State whether this is synchronous call, delegate/event, or shared state
- Flag any data flows that cross thread boundaries

Get user approval per scenario before writing.

---

## Phase 4: API Boundaries

Define the public contracts between modules. For each boundary:

- What is the interface a module exposes to the rest of the system?
- What are the entry points (functions/delegates/properties)?
- What invariants must callers respect?
- What must the module guarantee to callers?

Write in pseudocode or C++ (the project's primary language from technical preferences).
These become the contracts programmers implement against.

**UE API awareness check**: If any interface uses UE-specific types (e.g.
`UObject`, `AActor`, `UAbilitySystemComponent`, `TSubclassOf<>`), flag the version
and verify the type exists and has not changed signature in UE 5.8 via Context7.

---

## Phase 5: ADR Audit + Traceability Check

Review all existing ADRs from Phase 0c against both the architecture built in
Phases 1-4 AND the Technical Requirements Baseline from Phase 0b.

### ADR Quality Check

For each ADR:
- [ ] Does it have an Engine Compatibility section?
- [ ] Is the engine version recorded (UE 5.8)?
- [ ] Are HIGH-risk APIs flagged with Context7 verification?
- [ ] Does it have a "Requirements Addressed" section?
- [ ] Does it conflict with the layer/ownership decisions made in this session?
- [ ] Is it still valid for UE 5.8 (re-verify via Context7 if doubtful)?

| ADR | Engine Compat | Version | Req Linkage | Conflicts | Valid |
|-----|---------------|---------|-------------|-----------|-------|
| ADR-0001: [title] | ✅/❌ | ✅/❌ | ✅/❌ | None/[conflict] | ✅/⚠️ |

### Traceability Coverage Check

Map every requirement from the Technical Requirements Baseline to existing ADRs.
For each requirement, check if any ADR's "Requirements Addressed" section
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
- [e.g. "World/Level partitioning and streaming strategy"]
- [e.g. "Event bus vs Blueprint-async pattern architecture"]

**Should have before the relevant system is built:**
- [e.g. "Save object serialisation format"]

**Can defer to implementation:**
- [e.g. "Specific Material technique for water"]

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
# [Project] — Master Architecture

## Document Status
- Version: [N]
- Last Updated: [date]
- Engine: Unreal Engine 5.8
- Knowledge Source: Context7 MCP
- Feature Specs Covered: [list]
- ADRs Referenced: [list]

## UE 5.8 API Risk Summary
[Condensed from Phase 0d inventory — HIGH/MEDIUM risk APIs and their implications]

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
derived from the feature specs and technical preferences]

## Open Questions
[Decisions deferred — must be resolved before the relevant layer is built]
```

---

## Phase 7b: Technical Director Sign-Off + Lead Programmer Feasibility Review

After writing the master architecture document, perform an explicit sign-off before handoff.

**Step 1 — Technical Director self-review** (this skill runs as technical-director):

Apply gate **TD-ARCHITECTURE** (`.claude/docs/director-gates.md`) as a self-review. Check all four criteria from that gate definition against the completed document.

**Review mode check** — apply before spawning LP-FEASIBILITY:
- `solo` → skip. Note: "LP-FEASIBILITY skipped — Solo mode." Proceed to Phase 8 handoff.
- `lean` → skip (not a PHASE-GATE). Note: "LP-FEASIBILITY skipped — Lean mode." Proceed to Phase 8 handoff.
- `full` → spawn as normal.

**Step 2 — Spawn `lead-programmer` via Task using gate LP-FEASIBILITY (`.claude/docs/director-gates.md`):**

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

This skill follows the collaborative design principle at every phase:

1. **Load context silently** — do not narrate file reads
2. **Present findings** — show the UE API risk inventory and layer proposals
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
- Run `/architecture-review` — bootstraps the Requirements Traceability Matrix and TR registry from the ADRs just written. Required before the Requirements Breakdown gate.
- Run `/test-setup` to scaffold `tests/unit/`, `tests/integration/`, CI workflow, and an example test (required for gate-check)
- Run `/create-control-manifest` once the required ADRs are written to produce the layer rules manifest
- Run `/gate-check requirements-breakdown` when all required ADRs and `/test-setup` are complete
