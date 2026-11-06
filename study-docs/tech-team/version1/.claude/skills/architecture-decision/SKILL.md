---
name: architecture-decision
description: "Creates an Architecture Decision Record (ADR) documenting a significant technical decision, its context, alternatives considered, and consequences. Every major technical choice should have an ADR."
argument-hint: "[title] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, run_mcp
model: sonnet
---

When this skill is invoked:

## 0. Parse Arguments — Detect Retrofit Mode

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

**If the argument starts with `retrofit` followed by a file path**
(e.g., `/architecture-decision retrofit docs/architecture/adr-0001-event-system.md`):

Enter **retrofit mode**:

1. Read the existing ADR file completely.
2. Identify which template sections are present by scanning headings:
   - `## Status` — **BLOCKING if missing**: `/story-readiness` cannot check ADR acceptance
   - `## ADR Dependencies` — HIGH if missing: dependency ordering breaks
   - `## Engine Compatibility` — HIGH if missing: post-cutoff risk unknown
   - `## Requirements Addressed` — MEDIUM if missing: traceability lost
3. Present to the user:
   ```
   ## Retrofit: [ADR title]
   File: [path]

   Sections already present (will not be touched):
   ✓ Status: [current value, or "MISSING — will add"]
   ✓ [section]

   Missing sections to add:
   ✗ Status — BLOCKING (stories cannot validate ADR acceptance without this)
   ✗ ADR Dependencies — HIGH
   ✗ Engine Compatibility — HIGH
   ```
4. Ask: "Shall I add the [N] missing sections? I will not modify any existing content."
5. If yes:
   - For **Status**: ask the user — "What is the current status of this decision?"
     Options: "Proposed", "Accepted", "Deprecated", "Superseded by ADR-XXXX"
   - For **ADR Dependencies**: ask — "Does this decision depend on any other ADR?
     Does it enable or block any other ADR or epic?" Accept "None" for each field.
   - For **Engine Compatibility**: query Context7 for the domain's APIs (same as Step 1 below)
     and ask the user to confirm the domain. Then generate the table with verified data.
   - For **Requirements Addressed**: ask — "Which feature spec / requirement motivated this decision?
     What specific requirement in each spec does this ADR address?"
   - Append each missing section to the ADR file using the Edit tool.
   - **Never modify any existing section.** Only append or fill absent sections.
6. After adding all missing sections, update the ADR's `## Date` field if it is absent.
7. Suggest: "Run `/architecture-review` to re-validate coverage now that this ADR
   has its Status and Dependencies fields."

If NOT in retrofit mode, proceed to Step 1 below (normal ADR authoring).

**No-argument guard**: If no argument was provided (title is empty), ask before
running Phase 0:

> "What technical decision are you documenting? Please provide a short title
> (e.g., `event-system-architecture`, `gas-ability-framework`)."

Use the user's response as the title, then proceed to Step 1.

---

## 1. Load Engine Context via Context7 (ALWAYS FIRST)

Before doing anything else, establish the engine environment and verify the
domain's UE 5.8 APIs at runtime. Context7 is the knowledge authority — do NOT
rely on training data, and do NOT read a static `docs/engine-reference/` directory.

1. Identify the **domain** of this architecture decision from the title or
   user description. Common UE domains: Physics, Rendering, UI, Audio, Navigation,
   Animation, Networking, Core, Input, GAS, Subsystems, Scripting.

2. **Resolve the library ID**: call Context7 MCP
   `resolve-library-id(libraryName: "Unreal Engine")`. Capture the returned library ID.

3. **Query the domain's APIs**: call Context7 `query-docs` with the specific
   API/class/subsystem names relevant to this decision (e.g.,
   `"UAbilitySystemComponent ApplyGameplayEffectToTarget 5.8 signature"` for a GAS ADR,
   `"Enhanced Input System IMC 5.8"` for an input ADR). Use the most specific query
   you can — each tool is capped at ~3 calls per question.

4. **Flag 5.4+ changes**: from the Context7 results, note any API whose signature,
   behaviour, or existence changed after UE 5.3 (the LLM training cutoff edge).
   These become entries in the Engine Compatibility table.

5. **WebSearch fallback**: if Context7 returns nothing useful for a key API,
   run `WebSearch` against `docs.unrealengine.com/5.8/` and `dev.epicgames.com`.

6. **Display a verification banner** before proceeding if the domain touches
   post-cutoff APIs:

   ```
   ⚠️  UE 5.8 API VERIFICATION (via Context7)
   Engine: Unreal Engine 5.8
   Domain: [domain]
   Library ID: [from resolve-library-id]

   APIs verified this session:
   - [API 1] — [confirmed signature / changed in 5.x / not found → WebSearch fallback]
   - [API 2] — [...]

   This ADR will be cross-referenced against verified UE 5.8 APIs.
   Proceed with verified information only — do NOT rely solely on training data.
   ```

   If Context7 cannot resolve the Unreal Engine library at all, warn the user and
   rely on WebSearch; do not silently fall back to training data.

---

## 2. Determine the next ADR number

Scan `docs/architecture/` for existing ADRs to find the next number.

---

## 3. Gather context

Read related code, existing ADRs, and the requirement source. The requirement
source is the **feature spec** indexed by `docs/architecture/tr-registry.yaml`
(not a GDD — this team has no GDDs).

### 3a: Architecture Registry Check (BLOCKING gate)

Read `docs/registry/architecture.yaml`. Extract entries relevant to this ADR's
domain and decision (grep by system name, domain keyword, or state being touched).

Present any relevant stances to the user **before** the collaborative design
begins, as locked constraints:

```
## Existing Architectural Stances (must not contradict)

State Ownership:
  player_health → owned by health-system (ADR-0001)
  Interface: HealthComponent.current_health (read-only float)
  → If this ADR reads or writes player health, it must use this interface.

Interface Contracts:
  damage_delivery → signal pattern (ADR-0003)
  Signal: damage_dealt(amount, target, is_crit)
  → If this ADR delivers or receives damage events, it must use this signal.

Forbidden Patterns:
  ✗ autoload_singleton_coupling (ADR-0001)
  ✗ direct_cross_system_state_write (ADR-0000)
  → The proposed approach must not use these patterns.
```

If the user's proposed decision would contradict any registered stance, surface
the conflict immediately:

> "⚠️ Conflict: This ADR proposes [X], but ADR-[NNNN] established that [Y] is
> the accepted pattern for this purpose. Proceeding without resolving this will
> produce contradictory ADRs and inconsistent stories.
> Options: (1) Align with the existing stance, (2) Supersede ADR-[NNNN] with
> an explicit replacement, (3) Explain why this case is an exception."

Do not proceed to Step 4 (collaborative design) until any conflict is resolved
or explicitly accepted as an intentional exception.

---

## 4. Guide the decision collaboratively

Before asking anything, derive the skill's best guesses from the context already
gathered (feature spec read, Context7 verified, existing ADRs scanned). Then present
a **confirm/adjust** prompt using `AskUserQuestion` — not open-ended questions.

**Derive assumptions first:**
- **Problem**: Infer from the title + requirement context what decision needs to be made
- **Alternatives**: Propose 2-3 concrete options from Context7-verified UE 5.8 APIs + requirement needs
- **Dependencies**: Scan existing ADRs for upstream dependencies; assume None if unclear
- **Requirement linkage**: Extract which feature spec / TR-ID the title directly relates to
- **Status**: Always `Proposed` for new ADRs — never ask the user what the status is

**Scope of assumptions tab**: Assumptions cover only: problem framing, alternative approaches, upstream dependencies, requirement linkage, and status. Schema design questions (e.g., "How should spawn timing work?", "Should data be inline or external?") are NOT assumptions — they are design decisions belonging to a separate step after the assumptions are confirmed. Do not include schema design questions in the assumptions AskUserQuestion widget.

**After assumptions are confirmed**, if the ADR involves schema or data design choices, use a separate multi-tab `AskUserQuestion` to ask each design question independently before drafting.

**Present assumptions with `AskUserQuestion`:**

```
Here's what I'm assuming before drafting:

Problem: [one-sentence problem statement derived from context]
Alternatives I'll consider:
  A) [option derived from Context7-verified UE 5.8 APIs]
  B) [option derived from requirement needs]
  C) [option from common UE patterns]
Requirement sources driving this: [feature spec / TR-ID list derived from context]
Dependencies: [upstream ADRs if any, otherwise "None"]
Status: Proposed

[A] Proceed — draft with these assumptions
[B] Change the alternatives list
[C] Adjust the requirement linkage
[D] Add a performance budget constraint
[E] Something else needs changing first
```

Do not generate the ADR until the user confirms assumptions or provides corrections.

**After engine specialist and TD reviews return** (Step 5.5/5.6), if unresolved
decisions remain, present each one as a separate `AskUserQuestion` with the proposed
options as choices plus a free-text escape:

```
Decision: [specific unresolved point]
[A] [option from specialist review]
[B] [alternative option]
[C] Different approach — I'll describe it
```

**ADR Dependencies** — derive from existing ADRs, then confirm:
- Does this decision depend on any other ADR not yet Accepted?
- Does it unlock or unblock any other ADR or epic?
- Does it block any specific epic from starting?

Record answers in the **ADR Dependencies** section. Write "None" for each field if no constraints apply.

---

## 5. Generate the ADR

Following this format:

```markdown
# ADR-[NNNN]: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXXX]

## Date
[Date of decision]

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Unreal Engine 5.8 |
| **Domain** | [Physics / Rendering / UI / Audio / Navigation / Animation / Networking / Core / Input / GAS / Subsystems] |
| **Knowledge Risk** | [LOW / MEDIUM / HIGH — from Context7 verification] |
| **Context7 Queries** | [List queries run, e.g. `resolve-library-id "Unreal Engine"`, `query-docs "UAbilitySystemComponent 5.8"`] |
| **APIs Verified** | [APIs confirmed via Context7, with 5.4+ changes flagged] |
| **WebSearch Fallbacks** | [APIs Context7 could not resolve, verified via docs.unrealengine.com/5.8/, or "None"] |
| **Verification Required** | [Specific behaviours to test before shipping, or "None"] |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | [ADR-NNNN (must be Accepted before this can be implemented), or "None"] |
| **Enables** | [ADR-NNNN (this ADR unlocks that decision), or "None"] |
| **Blocks** | [Epic/Story name — cannot start until this ADR is Accepted, or "None"] |
| **Ordering Note** | [Any sequencing constraint that isn't captured above] |

## Context

### Problem Statement
[What problem are we solving? Why does this decision need to be made now?]

### Constraints
- [Technical constraints]
- [Timeline constraints]
- [Resource constraints]
- [Compatibility requirements]

### Requirements
- [Must support X]
- [Must perform within Y budget]
- [Must integrate with Z]

## Decision

[The specific technical decision made, described in enough detail for someone
to implement it.]

### Architecture Diagram
[ASCII diagram or description of the system architecture this creates]

### Key Interfaces
[API contracts or interface definitions this decision creates]

## Alternatives Considered

### Alternative 1: [Name]
- **Description**: [How this would work]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Rejection Reason**: [Why this was not chosen]

### Alternative 2: [Name]
- **Description**: [How this would work]
- **Pros**: [Advantages]
- **Cons**: [Disadvantages]
- **Rejection Reason**: [Why this was not chosen]

## Consequences

### Positive
- [Good outcomes of this decision]

### Negative
- [Trade-offs and costs accepted]

### Risks
- [Things that could go wrong]
- [Mitigation for each risk]

## Requirements Addressed

| Requirement Source | Requirement (TR-ID) | How This ADR Addresses It |
|--------------------|---------------------|---------------------------|
| [feature spec path] | TR-[system]-NNN: [requirement text from tr-registry] | [how this decision satisfies it] |

## Performance Implications
- **CPU**: [Expected impact]
- **Memory**: [Expected impact]
- **Load Time**: [Expected impact]
- **GPU**: [Expected impact]
- **Network**: [Expected impact, if applicable]

## Migration Plan
[If this changes existing code, how do we get from here to there?]

## Validation Criteria
[How will we know this decision was correct? What metrics or tests?]

## Related Decisions
- [Links to related ADRs]
- [Links to related feature specs]
```

5.5. **Engine Specialist Validation** — Before saving, spawn the **primary engine specialist** via Task to validate the drafted ADR:
   - Read `.claude/docs/technical-preferences.md` `Engine Specialists` section (or `.claude/docs/engine-specialists.md`) to get the primary specialist (`unreal-specialist`)
   - If no engine is configured (`[TO BE CONFIGURED]`), skip this step
   - Spawn `subagent_type: unreal-specialist` with: the ADR's Engine Compatibility section, Decision section, Key Interfaces, and the Context7 verification results. Instruct the specialist to:
     1. **Re-verify any UE API the ADR depends on by calling Context7 itself** (the sub-agent is a fresh instance and cannot see this session's Context7 results)
     2. Confirm the proposed approach is idiomatic for UE 5.8
     3. Flag any APIs or patterns that are deprecated or changed in 5.4+
     4. Identify UE-specific risks or gotchas not captured in the current ADR draft
     5. Stamp output: "API 验证:Context7 查询 [查询词] 于 [日期] — [确认/变更/未找到]"
   - If the specialist identifies a **blocking issue** (wrong API, deprecated approach, engine version incompatibility): revise the Decision and Engine Compatibility sections accordingly, then confirm the changes with the user before proceeding
   - If the specialist finds **minor notes** only: incorporate them into the ADR's Risks subsection

**Review mode check** — apply before spawning TD-ADR:
- `solo` → skip. Note: "TD-ADR skipped — Solo mode." Proceed to Step 5.7 (requirement sync check).
- `lean` → skip (not a PHASE-GATE). Note: "TD-ADR skipped — Lean mode." Proceed to Step 5.7 (requirement sync check).
- `full` → spawn as normal.

5.6. **Technical Director Strategic Review** — After the engine specialist validation, spawn `technical-director` via Task using gate **TD-ADR** (`.claude/docs/director-gates.md`):
   - Pass: the ADR file path (or draft content), engine version (UE 5.8), domain, any existing ADRs in the same domain
   - The TD validates architectural coherence (is this decision consistent with the whole system?) — distinct from the engine specialist's API-level check
   - If CONCERNS or REJECT: revise the Decision or Alternatives sections accordingly before proceeding

5.7. **Requirement Sync Check** — Before presenting the write approval, scan all
feature specs referenced in the "Requirements Addressed" section for naming inconsistencies
with the ADR's Key Interfaces and Decision sections (renamed functions, API methods,
or data types). If any are found, surface them as a **prominent warning block**
immediately before the write approval — not as a footnote:

```
⚠️ REQUIREMENT SYNC REQUIRED
[feature-spec].md uses names this ADR has renamed:
  [old_name] → [new_name_from_adr]
  [old_name_2] → [new_name_2_from_adr]
The spec must be updated before or alongside writing this ADR to prevent
developers reading the spec from implementing the wrong interface.
```

If no inconsistencies: skip this block silently.

5. **Write approval** — Use `AskUserQuestion`:

If requirement sync issues were found:
- "ADR draft is complete. How would you like to proceed?"
  - [A] Write ADR + update feature spec in the same pass
  - [B] Write ADR only — I'll update the spec manually
  - [C] Not yet — I need to review further

If no sync issues:
- "ADR draft is complete. May I write it?"
  - [A] Write ADR to `docs/architecture/adr-[NNNN]-[slug].md`
  - [B] Not yet — I need to review further

If yes to any write option, write the file, creating the directory if needed.
For option [A] with spec update: also update the feature spec file(s) to use the new names.

6. **Update Architecture Registry**

Scan the written ADR for new architectural stances that should be registered:
- State it claims ownership of
- Interface contracts it defines (function signatures, method APIs)
- Performance budget it claims
- API choices it makes explicitly
- Patterns it bans (Consequences → Negative or explicit "do not use X")

Present candidates:
```
Registry candidates from this ADR:
  NEW state ownership:      player_stamina → stamina-system
  NEW interface contract:   stamina_depleted delegate
  NEW performance budget:   stamina-system: 0.5ms/frame
  NEW forbidden pattern:    polling stamina each frame (use delegate instead)
  EXISTING (referenced_by update only): player_health → already registered ✅
```

**Registry append logic**: When writing to `docs/registry/architecture.yaml`, do NOT assume sections are empty. The file may already have entries from previous ADRs written in this session. Before each Edit call:
1. Read the current state of `docs/registry/architecture.yaml`
2. Find the correct section (state_ownership, interfaces, forbidden_patterns, api_decisions)
3. Append the new entry AFTER the last existing entry in that section — do not try to replace a `[]` placeholder that may no longer exist
4. If the section has entries already, use the closing content of the last entry as the `old_string` anchor, and append the new entry after it

**BLOCKING — do not write to `docs/registry/architecture.yaml` without explicit user approval.**

Ask using `AskUserQuestion`:
- "May I update `docs/registry/architecture.yaml` with these [N] new stances?"
  - Options: "Yes — update the registry", "Not yet — I want to review the candidates", "Skip registry update"

Only proceed if the user selects yes. If yes: append new entries. Never modify existing entries — if a stance is
changing, set the old entry to `status: superseded_by: ADR-[NNNN]` and add the new entry.

---

## 6. Closing Next Steps

After the ADR is written (and registry optionally updated), close with `AskUserQuestion`.

Before generating the widget:
1. Read `docs/registry/architecture.yaml` — check if any priority ADRs are still unwritten (look for ADRs flagged in technical-preferences.md or architecture.md as prerequisites)
2. Check if all prerequisite ADRs are now written. If yes, include a "Start writing epics" option.
3. List ALL remaining priority ADRs as individual options — not just the next one or two.

Widget format:
```
ADR-[NNNN] written and registry updated. What would you like to do next?
[1] Write [next-priority-adr-name] — [brief description from prerequisites list]
[2] Write [another-priority-adr] — [brief description]  (include ALL remaining ones)
[N] Start writing epics — run `/create-epics layer: foundation` (only show if all prerequisite ADRs are written)
[N+1] Stop here for this session
```

If there are no remaining priority ADRs, offer only "Stop here" and suggest running `/architecture-review` in a fresh session.

**Always include this fixed notice in the closing output (do NOT omit it):**

> To validate ADR coverage against your feature specs, open a **fresh Claude Code session**
> and run `/architecture-review`.
>
> **Never run `/architecture-review` in the same session as `/architecture-decision`.**
> The reviewing agent must be independent of the authoring context to give an unbiased
> assessment. Running it here would invalidate the review.

Update any stories that were `Status: Blocked` pending this ADR to `Status: Ready`.
