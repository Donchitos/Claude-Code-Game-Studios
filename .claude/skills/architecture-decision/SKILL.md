---
name: architecture-decision
description: "Create an ADR documenting a technical decision: context, alternatives considered, consequences."
argument-hint: "[title | retrofit <path> | accept <ADR-id>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/architecture-decision/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,team.size`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


When this skill is invoked:

## 0. Parse Arguments — Detect Retrofit / Acceptance Mode


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`team.size`**: which agents validate this ADR (orthogonal to review_mode/workflow).
- **`individual`** (default): `technical-director` + `lead-programmer` + the engine-specialist.
- **`small`**: + an engine sub-specialist where applicable.
- **`studio`**: + an adversarial review by an alternate engine-specialist.
Any non-core agent needed at `individual` routes through the nearest active core agent with a note.

**`docs.density`** — it controls the *depth* of the ADR's prose sections, not
which sections the skeleton emits (that is fixed). `modes.rigor` sets it
alongside `workflow`; set `docs.density` explicitly to vary ADR verbosity alone:
`terse` = decision + alternatives as bullets, one line of rationale each;
`balanced` = paragraph per section with light rationale (default); `thorough` =
full prose with trade-offs and worked rationale in Decision, Alternatives, and
Consequences. Apply it to the prose sections; the Engine Compatibility, ADR
Dependencies, and GDD Requirements tables are structural and stay whole at every
density.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — all ADRs on the required ADR list must be completed.
- `standard` — critical ADRs only (Foundation-layer systems).
- `minimal` — not required. Can still be run voluntarily.

**If the argument starts with `retrofit` followed by a file path**
(e.g., `/architecture-decision retrofit docs/architecture/adr-0001-event-system.md`):

Enter **retrofit mode**:

1. Read the existing ADR file completely.
2. Identify which template sections are present by scanning headings:
   - `## Status` — **BLOCKING if missing**: `/story-readiness` cannot check ADR acceptance
   - `## ADR Dependencies` — HIGH if missing: dependency ordering breaks
   - `## Engine Compatibility` — HIGH if missing: post-cutoff risk unknown
   - `## GDD Requirements Addressed` — MEDIUM if missing: traceability lost
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
   - For **Engine Compatibility**: read the engine reference docs (same as Step 1 below)
     and ask the user to confirm the domain. Then generate the table with verified data.
   - For **GDD Requirements Addressed**: ask — "Which GDD systems motivated this decision?
     What specific requirement in each GDD does this ADR address?"
   - Append each missing section to the ADR file using the Edit tool.
   - **Never modify any existing section.** Only append or fill absent sections.
6. After adding all missing sections, update the ADR's `## Date` field if it is absent.
7. Suggest: "Run `/architecture-review` to re-validate coverage now that this ADR
   has its Status and Dependencies fields."

**If the argument starts with `accept` followed by an ADR id**
(e.g., `/architecture-decision accept ADR-0005`):

Enter **acceptance mode**. This is the *only* path in the framework that moves an
ADR from `Proposed` to `Accepted`. Authoring always produces `Proposed`
(Step 5), while
`/create-control-manifest`, `/create-epics`, `/create-stories` and `/gate-check`
all require `Accepted` — so without this mode the pipeline had a state it could
enter and never leave.

1. **Resolve the id to a file, then read it.** Glob
   `docs/architecture/adr-NNNN-*.md` for the given number. If **no** file matches,
   or **more than one** does, stop and say which — do not pick one. If the file
   has no `## Status` section, stop and say so; a missing Status is exactly what
   retrofit mode is for.
2. **Check the current status.** If it is already `Accepted`, say so and stop.
   If it is `Deprecated` or `Superseded`, refuse: reviving a superseded decision
   is a new ADR, not a status edit.
3. **Check its dependencies first.** Read `## ADR Dependencies`.

   **If that section is absent, empty, or reads `UNKNOWN`, do not read it as
   "no dependencies" — refuse and say which:**
   > "ADR-0005's dependency section is [absent / UNKNOWN], so I cannot tell what
   > this decision rests on. An empty dependency list and an unexamined one look
   > identical here, and only one of them is safe to accept. Run
   > `/architecture-decision retrofit <path>` to establish it."

   A dependency check reading a field that defaults to empty is the vacuous-pass
   shape this gate exists to prevent — the check would examine nothing and report
   clean.

   If it depends on any ADR that is not itself `Accepted`, **refuse and name them**:
   > "ADR-0005 depends on ADR-0002, which is still Proposed. Accept ADR-0002
   > first — an accepted decision resting on an unaccepted one is not a decision,
   > it is a deferral with a different label."
   This is the same dependency rule `/architecture-review` already flags; here it
   is enforced rather than reported.
4. **Confirm with the user, always.** Per `CONTRACT.md`, acceptance authority is
   **the user, or `technical-director` on the user's explicit confirmation — no
   other agent, and never this skill on its own.** Use `AskUserQuestion`:
   - Prompt: "Accept ADR-NNNN — [title]? This is what unblocks stories and epics
     that depend on it."
   - Options: `[A] Yes — accept it` / `[B] Not yet — leave it Proposed`
   **This prompt fires regardless of `modes.automation`, including `autonomous`.**
   Acceptance is the decision the whole architecture pipeline gates on; it is not
   a step to be inferred.
5. **Find the stories this will unblock, BEFORE the prompt in step 4.** Grep
   `production/epics/[epic-slug]/story-*.md` — the one place stories live — for
   files containing **both** `Status: Blocked` and this ADR's id.
   > **Stories live only under `production/epics/`.** A flat top-level stories
   > directory does not exist and no skill creates one — never write or match a
   > path outside `production/epics/`. `/dev-story` matches entries *by file
   > path*, so a story recorded under any other path silently fails to match and
   > never gets picked up. That pairing is what "blocked pending this
   ADR" means — a story blocked for an unrelated reason will not name it. Feed the
   count into step 4's prompt so it reads *"3 stories become Ready"* rather than a
   generic claim: **the user is being asked to authorise an effect, and should be
   shown the effect.** If none match, say "no stories are waiting on this" — that
   is useful information, not an empty result to omit.
6. On confirmation, `Edit` the `## Status` line to `Accepted`. Set the date in the
   ADR's `## Date` section; **if that section is absent, add it** — retrofit mode
   already owns this shape, and acceptance must not fail on a template that
   predates the field.
7. Then set each story found in step 5 from `Blocked` to `Ready`. Unblocking is a
   consequence of acceptance, never of authoring — see Step 6's note below.
8. Report what moved: the ADR, its new date, and every story that became Ready.

If NOT in retrofit or acceptance mode, proceed to Step 1 below (normal ADR authoring).

**No-argument guard**: If no argument was provided (title is empty), ask before
running Phase 0:

> "What technical decision are you documenting? Please provide a short title
> (e.g., `event-system-architecture`, `physics-engine-choice`)."

Use the user's response as the title, then proceed to Step 1.

---

## 1. Load Engine Context (ALWAYS FIRST)

Before doing anything else, establish the engine environment:

1. Read `docs/engine-reference/[engine]/VERSION.md` to get:
   - Engine name and version
   - LLM knowledge cutoff date
   - Post-cutoff version risk levels (LOW / MEDIUM / HIGH)

2. Identify the **domain** of this architecture decision from the title or
   user description. Common domains: Physics, Rendering, UI, Audio, Navigation,
   Animation, Networking, Core, Input, Scripting.

3. Read the corresponding module reference if it exists:
   `docs/engine-reference/[engine]/modules/[domain].md`

4. Read `docs/engine-reference/[engine]/breaking-changes.md` — flag any
   changes in the relevant domain that post-date the LLM's training cutoff.

5. Read `docs/engine-reference/[engine]/deprecated-apis.md` — flag any APIs
   in the relevant domain that should not be used.

6. **Display a knowledge gap warning** before proceeding if the domain carries
   MEDIUM or HIGH risk:

   ```
   ⚠️  ENGINE KNOWLEDGE GAP WARNING
   Engine: [name + version]
   Domain: [domain]
   Risk Level: HIGH — This version is post-LLM-cutoff.

   Key changes verified from engine-reference docs:
   - [Change 1 relevant to this domain]
   - [Change 2]

   This ADR will be cross-referenced against the engine reference library.
   Proceed with verified information only — do NOT rely solely on training data.
   ```

   If no engine has been configured yet, prompt: "No engine is configured.
   Run `/setup-engine` first, or tell me which engine you are using."

---

## 2. Determine the next ADR number

Scan `docs/architecture/` for existing ADRs to find the next number.

---

## 3. Gather context

### 3a: Architecture Registry Check (BLOCKING gate) — do this FIRST

Read `docs/registry/architecture.yaml`. Extract entries relevant to this ADR's
domain and decision (grep by system name, domain keyword, or state being touched).
Run this before reading any existing ADR — the registry exists specifically so a
new ADR's author does not need to open prior ADRs to learn their binding facts
(state ownership, interface contracts, forbidden patterns).

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

### 3b: Existing ADRs and Related GDDs — registry-scoped, never unbounded

The registry (3a) covers *what* prior decisions bind — not always *why*. If the
registry surfaced a directly relevant ADR and its reasoning matters here (not
just its stated facts), read that specific ADR — never glob-and-read every
ADR in `docs/architecture/` on the chance one is relevant:

1. **Map its headings first** (cheap):
   ```
   Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```
2. **Under ~50KB** (`Bash: wc -c "docs/architecture/[adr-file].md"`) — one full
   `Read` is fine; per-call overhead exceeds the savings from bounded reads at
   this size (measured elsewhere in this project).
3. **~50KB or larger** — bounded-read only `## Context`, `## Decision`, and
   `## Consequences` (the sections that carry reasoning, not just facts) via
   `Read(offset, limit)` from the heading map.

Read GDDs the same way `/design-system` Step 2b does: only GDDs the registry
or the ADR list names as directly relevant, and only their `## Dependencies`,
`## Formulas`, and `## Edge Cases` sections
(`Grep pattern="^## (Dependencies|Formulas|Edge Cases)" ... -A 40`) — never a
speculative full read of `design/gdd/*.md` looking for anything that might
relate.

Skip 3b entirely if the registry already answers everything this decision
needs — most ADRs will.

---

## 4. Guide the decision collaboratively

Before asking anything, derive the skill's best guesses from the context already
gathered (GDDs read, engine reference loaded, existing ADRs scanned). Then present
a **confirm/adjust** prompt using `AskUserQuestion` — not open-ended questions.

**Derive assumptions first:**
- **Problem**: Infer from the title + GDD context what decision needs to be made
- **Alternatives**: Propose 2-3 concrete options from engine reference + GDD requirements
- **Dependencies**: Scan existing ADRs for upstream dependencies. **If the scan is
  inconclusive, present `UNKNOWN — scan inconclusive, please confirm`, never
  `None`.** The two are not interchangeable: `None` asserts that nothing upstream
  constrains this decision, and a user confirming a prefilled list cannot tell an
  assertion from a guess. This field is load-bearing — `/architecture-review`
  flags unaccepted dependencies, `/dev-story` reads it, and the acceptance route
  in Phase 0 **refuses to accept an ADR whose dependencies are not themselves
  Accepted**. A dependency list that defaulted to empty makes that check pass
  while examining nothing. `UNKNOWN` must be resolved during the confirm/adjust
  prompt; it is a prompt state, never a value written to the file
- **GDD linkage**: Extract which GDD systems the title directly relates to
- **Status**: Always `Proposed` for new ADRs — never ask the user what the status is

**Scope of assumptions tab**: Assumptions cover only: problem framing, alternative approaches, upstream dependencies, GDD linkage, and status. Schema design questions (e.g., "How should spawn timing work?", "Should data be inline or external?") are NOT assumptions — they are design decisions belonging to a separate step after the assumptions are confirmed. Do not include schema design questions in the assumptions AskUserQuestion widget.

**After assumptions are confirmed**, if the ADR involves schema or data design choices, use a separate multi-tab `AskUserQuestion` to ask each design question independently before drafting.

**Present assumptions with `AskUserQuestion`:**

```
Here's what I'm assuming before drafting:

Problem: [one-sentence problem statement derived from context]
Alternatives I'll consider:
  A) [option derived from engine reference]
  B) [option derived from GDD requirements]
  C) [option from common patterns]
GDD systems driving this: [list derived from context]
Dependencies: [upstream ADRs if any, otherwise "None"]
Status: Proposed

[A] Proceed — draft with these assumptions
[B] Change the alternatives list
[C] Adjust the GDD linkage
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

## Last Verified
[YYYY-MM-DD — when this ADR was last confirmed accurate against the current
engine version and design. Update this date when you re-read and confirm it is
still correct, even if nothing changed.]

## Decision Makers
[Who was involved in this decision]

## Summary
[2 sentences: what problem this ADR solves, and what was decided. Written for
tiered context loading — a skill scanning 20 ADRs uses this to decide whether to
read the full decision. Be specific: name the system, the problem, and the
chosen approach.]

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | [e.g. Godot 4.6] |
| **Domain** | [Physics / Rendering / UI / Audio / Navigation / Animation / Networking / Core / Input] |
| **Knowledge Risk** | [LOW / MEDIUM / HIGH — from VERSION.md] |
| **References Consulted** | [List engine-reference docs read, e.g. `docs/engine-reference/godot/modules/physics.md`] |
| **Post-Cutoff APIs Used** | [Any APIs from post-LLM-cutoff versions this decision depends on, or "None"] |
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

### Implementation Guidelines
[Specific guidance for the programmer implementing this decision — the rules a
`/create-control-manifest` or `/dev-story` run should follow. State mandates as
"must / must never" so they extract cleanly.]

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

## Risks
- [Things that could go wrong]
- [Mitigation for each risk]

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| [system-name].md | [specific rule, formula, or performance constraint from that GDD] | [how this decision satisfies it] |

## Performance Implications
- **CPU**: [Expected impact]
- **Memory**: [Expected impact]
- **Load Time**: [Expected impact]
- **Network**: [Expected impact, if applicable]

## Migration Plan
[If this changes existing code, how do we get from here to there?]

## Validation Criteria
[How will we know this decision was correct? What metrics or tests?]

## Related
- [Links to related ADRs — note if supersedes, contradicts, or depends on]
- [Links to related design documents]
```

5.5. **Engine Specialist Validation** — Before saving, spawn the **primary engine specialist** via `Agent` to validate the drafted ADR:
   - Resolve the primary specialist: `<engine>-specialist` derived from `engine.name` in `project.yaml` (Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`); if `engine.name` is absent or empty, read the Primary line of the `## Engine Specialists` section in `.claude/docs/technical-preferences.md`
   - If no engine is configured (neither source yields an engine), skip this step **Record `Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.
   - Spawn `subagent_type: [primary specialist]` with: the ADR's Engine Compatibility section, Decision section, Key Interfaces, and the engine reference docs path. Ask them to:
     1. Confirm the proposed approach is idiomatic for the pinned engine version
     2. Flag any APIs or patterns that are deprecated or changed post-training-cutoff
     3. Identify engine-specific risks or gotchas not captured in the current ADR draft
   - If the specialist identifies a **blocking issue** (wrong API, deprecated approach, engine version incompatibility): revise the Decision and Engine Compatibility sections accordingly, then confirm the changes with the user before proceeding
   - If the specialist finds **minor notes** only: incorporate them into the ADR's Risks subsection

**Review mode check** — apply before spawning TD-ADR:
- `solo` → skip. Note: "TD-ADR skipped — Solo mode." Proceed to Step 5.7 (GDD sync check).
- `lean` → skip (not a PHASE-GATE). Note: "TD-ADR skipped — Lean mode." Proceed to Step 5.7 (GDD sync check).
- `full` → spawn as normal.

5.6. **Technical Director Strategic Review** — After the engine specialist validation, spawn `technical-director` via `Agent` using gate **TD-ADR** (`.claude/docs/director-gates/td-adr.md`):
   - Pass: the ADR file path (or draft content), engine version, domain, any existing ADRs in the same domain
   - The TD validates architectural coherence (is this decision consistent with the whole system?) — distinct from the engine specialist's API-level check
   - If CONCERNS or REJECT: revise the Decision or Alternatives sections accordingly before proceeding

5.7. **GDD Sync Check** — Before presenting the write approval, scan all GDDs
referenced in the "GDD Requirements Addressed" section for naming inconsistencies
with the ADR's Key Interfaces and Decision sections (renamed signals, API methods,
or data types). If any are found, surface them as a **prominent warning block**
immediately before the write approval — not as a footnote:

```
⚠️ GDD SYNC REQUIRED
[gdd-filename].md uses names this ADR has renamed:
  [old_name] → [new_name_from_adr]
  [old_name_2] → [new_name_2_from_adr]
The GDD must be updated before or alongside writing this ADR to prevent
developers reading the GDD from implementing the wrong interface.
```

**This check has three outcomes, not two.** The two above are "found" and "none
found"; the third is **could not check**, and until now it fell through the
silent branch and rendered exactly like a clean result.

- **None found** — print one line, do not stay silent:
  `GDD sync: checked [N] referenced GDD(s), no naming inconsistencies.`
  A silent pass is indistinguishable from a check that never ran, and this one
  guards against developers implementing the wrong interface from a stale GDD.
- **Could not check** — the ADR has no `GDD Requirements Addressed` section, it
  names no GDDs, or a named GDD does not exist on disk. Print:
  `GDD sync: NOT ASSESSED — [which reason, and which files]`
  Do **not** treat an ADR that references no GDDs as one whose GDDs are
  consistent. Nothing was compared.

Only the warning block itself is conditional; the check always reports.

5. **Write approval** — Use `AskUserQuestion`:

If GDD sync issues were found:
- "ADR draft is complete. How would you like to proceed?"
  - [A] Write ADR + update GDD in the same pass
  - [B] Write ADR only — I'll update the GDD manually
  - [C] Not yet — I need to review further

If no GDD sync issues:
- "ADR draft is complete. May I write it?"
  - [A] Write ADR to `docs/architecture/adr-[NNNN]-[slug].md`
  - [B] Not yet — I need to review further

If yes to any write option, write the file, creating the directory if needed.
For option [A] with GDD update: also update the GDD file(s) to use the new names.

6. **Update Architecture Registry**

Scan the written ADR for new architectural stances that should be registered:
- State it claims ownership of
- Interface contracts it defines (signal signatures, method APIs)
- Performance budget it claims
- API choices it makes explicitly
- Patterns it bans (Consequences → Negative or explicit "do not use X")

Present candidates:
```
Registry candidates from this ADR:
  NEW state ownership:      player_stamina → stamina-system
  NEW interface contract:   stamina_depleted signal
  NEW performance budget:   stamina-system: 0.5ms/frame
  NEW forbidden pattern:    polling stamina each frame (use signal instead)
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
1. Read `docs/registry/architecture.yaml` — check if any priority ADRs are still unwritten (look for ADRs flagged in technical-preferences.md or systems-index.md as prerequisites)
2. Check if all prerequisite ADRs are now written. If yes, include a "Start writing GDDs" option.
3. List ALL remaining priority ADRs as individual options — not just the next one or two.

Widget format:
```
ADR-[NNNN] written and registry updated. What would you like to do next?
[1] Write [next-priority-adr-name] — [brief description from prerequisites list]
[2] Write [another-priority-adr] — [brief description]  (include ALL remaining ones)
[N] Start writing GDDs — run `/design-system [first-undesigned-system]` (only show if all prerequisite ADRs are written)
[N+1] Stop here for this session
```

If there are no remaining priority ADRs and no undesigned GDD systems, offer only "Stop here" and suggest running `/architecture-review` in a fresh session.

**Always include this fixed notice in the closing output (do NOT omit it):**

> To validate ADR coverage against your GDDs, open a **fresh Claude Code session**
> and run `/architecture-review`.
>
> **Never run `/architecture-review` in the same session as `/architecture-decision`.**
> The reviewing agent must be independent of the authoring context to give an unbiased
> assessment. Running it here would invalidate the review.

**Do NOT unblock stories here.** This ADR is `Proposed` — Step 5 guarantees it,
and a story blocked *pending this decision* is still pending it. Unblocking on
authoring is how the deadlock stayed invisible: it defeated the guard at the
moment the guard became relevant, so the pipeline appeared to flow while running
on decisions nobody had accepted.

Instead, tell the user what is now waiting on acceptance:

> "ADR-NNNN is written and `Proposed`. [N] stories remain `Blocked` pending it.
> Run `/architecture-decision accept ADR-NNNN` when the decision is settled —
> that is what moves them to `Ready`."

List the blocked stories by path so the cost of leaving it Proposed is visible.
(Acceptance has consequences enforced across many skills and an authority
recorded in only a few, so the route between them must stay explicit.)
