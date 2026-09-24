---
name: design-system
description: "Section-by-section GDD authoring for one system — walks through each required section, cross-references dependencies."
argument-hint: "<system-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(bash "*/.claude/skills/design-system/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.


When this skill is invoked:

## 1. Parse Arguments & Validate


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` = bullet points, 2–5 lines per section,
skip rationale and preambles; `balanced` = paragraphs with light rationale
(default); `thorough` = full prose with rationale, examples, and alternatives
considered. Apply it to every section you author. Mandated structures (the
Formulas variable table, Given-When-Then acceptance criteria) are correctness
requirements at every density — `terse` trims the surrounding prose, never the
required structure itself.

A system name or retrofit path is **required**. If missing:

1. Check if `design/gdd/systems-index.md` exists.
2. If it exists: read it, find the highest-priority system with status "Not Started" or equivalent, and use `AskUserQuestion`:
   - Prompt: "The next system in your design order is **[system-name]** ([priority] | [layer]). Start designing it?"
   - Options: `[A] Yes — design [system-name]` / `[B] Pick a different system` / `[C] Stop here`
   - If [A]: proceed with that system name. If [B]: ask which system to design (plain text). If [C]: exit.
3. If no systems index exists, fail with:
   > "Usage: `/design-system <system-name>` — e.g., `/design-system movement`
   > Or to fill gaps in an existing GDD: `/design-system retrofit design/gdd/[system-name].md`
   > No systems index found. Run `/map-systems` first to map your systems and get the design order."

**Detect retrofit mode:**
If the argument starts with `retrofit` or the argument is a file path to an
existing `.md` file in `design/gdd/`, enter **retrofit mode**:

1. Read the existing GDD file.
2. Identify which of the 8 **possible** sections are present (scan for section
   headings): Overview, Player Fantasy, Detailed Design/Rules, Formulas,
   Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria.
   **Which of them are *required* depends on the effective tier** (§1) — at
   `standard` only 5 are, plus Formulas for math categories, and Player Fantasy
   and Tuning Knobs are skipped **by design**. Report an absent section as a gap
   only when the tier requires it; otherwise list it as available-to-add. Calling
   all 8 required here reports two by-design-absent sections as gaps on every
   `standard` project.
3. Identify which sections contain only placeholder text (`[To be designed]` or
   equivalent — blank, a single line, or obviously incomplete).
4. Present to the user before doing anything:
   ```
   ## Retrofit: [System Name]
   File: design/gdd/[filename].md

   Sections already written (will not be touched):
   ✓ [section name]
   ✓ [section name]

   Missing or incomplete sections (will be authored):
   ✗ [section name] — missing
   ✗ [section name] — placeholder only
   ```
5. Ask: "Shall I fill the [N] missing sections? I will not modify any existing content."
6. If yes: proceed to **Phase 2 (Gather Context)** as normal, but in **Phase 3**
   skip creating the skeleton (file already exists) and in **Phase 4** skip
   sections that are already complete. Only run the section cycle for missing/
   incomplete sections.
7. **Never overwrite existing section content.** Use Edit tool to replace only
   `[To be designed]` placeholders or empty section bodies.

If NOT in retrofit mode, normalize the system name to kebab-case for the
filename (e.g., "combat system" becomes `combat-system`).

**`workflow`** for this system (per `.claude/docs/workflow-modes.md`) — use the
`system_overrides` row for this system if the block lists one, else the project
value.

The resolved tier determines which GDD sections are **required** (applied in §4).
**`## Summary` is required at every tier and is not one of the 8** — §5-pre
authors it unconditionally (*"This runs at every tier"*), but it appeared in none
of the per-tier lists below, and these lists are what other skills and gates
apply. A GDD checked against a tier list alone would pass with no Summary, the
one section `/review-all-gdds` and the tiered-loading readers depend on. Read
every list below as "`## Summary`, plus:".
- `full` — all 8 sections
- `standard` — Overview, Detailed Design, Edge Cases, Dependencies, Acceptance
  Criteria (5 required); **Formulas conditional** — required when the system
  **defines numeric rules**: rates, curves, thresholds, costs, damage, drop
  weights, or any value a balance pass would tune. Optional only when the system
  defines no such value. **The `Category` in `systems-index.md` is a hint, not
  the test** — `Gameplay`, `Economy` and `Progression` systems almost always
  qualify, and a `Core`, `UI` or `Persistence` system that defines a numeric rule
  qualifies too. If the Detailed Design states a quantity that is not a constant
  of the engine, Formulas is required. **Player Fantasy and Tuning Knobs skipped**
  unless `workflow_overrides` force them (`tuning_knobs: true` forces Tuning Knobs)

  > **Do not gate this on a category token.** A rule of the form "required when
  > the system category is combat / economy / progression / AI" does not work:
  > those four tokens are not what `/map-systems` writes — `templates/systems-index.md`
  > defines the categories as `Core · Gameplay · Progression · Economy ·
  > Persistence · UI · Audio · Narrative · Meta` and lists **combat and AI as
  > example systems under `Gameplay`**. A combat system categorised exactly as the
  > template instructs matches none of the four, and Formulas would be dropped for
  > the system most likely to need it.
- `minimal` — a GDD is not required (the game brief replaces it). If invoked
  voluntarily at minimal, author exactly the 5 standard sections (Overview,
  Detailed Design, Edge Cases, Dependencies, Acceptance Criteria) — the
  conditional Formulas rule does NOT re-apply at minimal — and tell the user
  the GDD is optional at this workflow level.

Retrofit mode is unaffected — it fills whatever sections are missing regardless
of tier.

---

## 2. Gather Context (Read Phase)

Read all relevant context **before** asking the user anything. This is the skill's
primary advantage over ad-hoc design — it arrives informed.

### 2a: Required Reads

> **At `minimal`** (design-system is voluntary at this tier): read
> `design/game-brief.md` in place of the game concept, and **skip the systems-index
> read** — neither `game-concept.md` nor `systems-index.md` exists at `minimal`.
> Author from the brief's relevant MVP feature and its core loop.
>
> **This callout keys on the PROJECT tier, not this system's effective tier.**
> The two differ whenever `workflow_overrides.system_overrides` bumps one system
> above a `minimal` project — the configuration `.claude/docs/settings-guidance.md`
> advertises as the reason the override exists ("bump one deep system"). Those two
> files are absent because the *project* is `minimal`; raising *this system* to
> `standard` or `full` does not create them. So on a `minimal` project, take this
> branch **even for an overridden system**, and read the brief.
>
> The effective tier still governs everything downstream — the required section
> set (§1), the skeleton (§3), the section cycle (§4) and §5a. Only the
> required-*reads* branch here follows the project tier.
>
> **Then derive `Category`, `Layer` and `Priority` from the brief, once, here.**
> Six later steps are keyed on the systems index you just skipped — §2e's engine
> domain, Section A's and Section B's recommended options, the Visual/Audio
> REQUIRED table, §6 specialist routing, and §5-pre's Quick reference — and none
> of them has an absent-index branch. An overridden system reaches all six at
> `standard` or `full`, so "skip the index" leaves them with no input at all.
> Derive from the brief instead:
>
> - **`Category`** — one of the nine in `templates/systems-index.md`
>   (`Core · Gameplay · Progression · Economy · Persistence · UI · Audio ·
>   Narrative · Meta`), chosen from what the brief says the system *does*.
> - **`Layer`** — `Foundation` if other systems depend on it, else `Feature`.
> - **`Priority`** — `MVP` if the brief's build order lists it, else `Post-MVP`.
>
> Carry all three for the rest of the run and treat them as the index's answer.
> **Mark them inferred** in §5-pre's Quick reference (*"Category: Gameplay
> (inferred from the brief — no systems index at this tier)"*) so a later reader
> does not mistake a derivation for an indexed fact. Do **not** write a systems
> index to hold them: `/map-systems` owns that file (§5d).
>
> Read literally without this rule, an overridden system resolves to `full`, falls
> through to the fail-fast reads below, and aborts with *"No game concept found.
> Run `/brainstorm` first"* — killing the escape hatch on step one of the very
> configuration it was built for.

- **Game concept**: Read `design/gdd/game-concept.md` — fail if missing:
  > "No game concept found. Run `/brainstorm` first."
- **Systems index**: Read `design/gdd/systems-index.md` — fail if missing:
  > "No systems index found. Run `/map-systems` first to map your systems."
- **Target system**: Find the system in the index. If not listed, warn:
  > "[system-name] is not in the systems index. Would you like to add it, or
  > design it as an off-index system?"
- **Entity registry**: Read `design/registry/entities.yaml` if it exists.
  Extract all entries referenced by or relevant to this system (grep
  `referenced_by.*[system-name]` and `source.*[system-name]`). Hold these
  in context as **known facts** — values that other GDDs have already
  established and this GDD must not contradict.
- **Reflexion log**: Read `docs/consistency-failures.md` if it exists.
  Extract entries whose Domain matches this system's category. These are
  recurring conflict patterns — present them under "Past failure patterns"
  in the Phase 2d context summary so the user knows where mistakes have
  occurred before in this domain.

### 2b: Dependency Reads

From the systems index, identify:
- **Upstream dependencies**: Systems this one depends on (decisions this system
  must respect).
- **Downstream dependents**: Systems that depend on this one (expectations this
  system must satisfy).

For each dependency GDD that exists, read **only the four sections that carry the
cross-system contract** — not the whole GDD:
```
Grep pattern="## (Dependencies|Formulas|Edge Cases|Tuning Knobs)" glob="design/gdd/[dep].md" output_mode="content" -A 20
```
- Key interfaces and data flow (from Dependencies)
- Formulas that reference this system's outputs
- Edge cases that assume this system's behavior
- Tuning knobs that feed into this system

Much of this is already in `entities.yaml` (loaded in 2a) — the registry's
`formula_map`/`constant_map` carry the owned values with their `source:`. Use the
registry first; the section grep fills what it does not hold.

### 2c: Optional Reads

- **Game pillars**: Read `design/gdd/game-pillars.md` if it exists
- **Existing GDD**: Read `design/gdd/[system-name].md` if it exists (resume, don't
  restart from scratch)
- **Related systems**: do **not** glob-and-read `design/gdd/*.md` hunting for
  "thematically related" systems — there is no deterministic proxy for that and it
  is the read the registry exists to replace. `entities.yaml` (2a) already holds
  the cross-system facts a related GDD would supply. If a specific overlap is
  known, treat it as a dependency above and section-grep it; otherwise rely on the
  registry.

### 2d: Present Context Summary

Before starting design work, present a brief summary to the user:

> **Designing: [System Name]**
> - Priority: [from index] | Layer: [from index]
> - Depends on: [list, noting which have GDDs vs. undesigned]
> - Depended on by: [list, noting which have GDDs vs. undesigned]
> - Existing decisions to respect: [key constraints from dependency GDDs]
> - Pillar alignment: [which pillar(s) this system primarily serves]
> - **Known cross-system facts (from registry):**
>   - [entity_name]: [attribute]=[value], [attribute]=[value] (owned by [source GDD])
>   - [item_name]: [attribute]=[value], [attribute]=[value] (owned by [source GDD])
>   - [formula_name]: variables=[list], output=[min–max] (owned by [source GDD])
>   - [constant_name]: [value] [unit] (owned by [source GDD])
>   *(These values are locked — if this GDD needs different values, surface
>   the conflict before writing. Do not silently use different numbers.)*
>
> If no registry entries are relevant: omit the "Known cross-system facts" section.

If any upstream dependencies are undesigned, warn:
> "[dependency] doesn't have a GDD yet. We'll need to make assumptions about
> its interface. Consider designing it first, or we can define the expected
> contract and flag it as provisional."

### 2e: Technical Feasibility Pre-Check

Before asking the user to begin designing, load engine context and surface any
constraints or knowledge gaps that will shape the design.

**Step 1 — Determine the engine domain for this system:**
Map the system's category (from systems-index.md) to an engine domain:

Keyed on the `Category` column of `systems-index.md`. All nine categories
`templates/systems-index.md` defines appear here; where a category spans several
engine domains, pick the row matching what the system actually does and say
which you picked.

| `Category` | Engine Domain |
|-----------|--------------|
| `Gameplay` | **Physics** for combat / collision / movement; **Navigation** for AI and pathfinding; **Scripting** for rule-only systems with no engine surface |
| `Core` | **Core** — scene management, state, resource loading; **Input** for controls and keybinding |
| `UI` | UI |
| `Audio` | Audio |
| `Narrative` | Scripting — dialogue, quests, cutscenes |
| `Progression` | Scripting — save-adjacent rule logic, no dedicated domain |
| `Economy` | Scripting — data and rule logic, no dedicated domain |
| `Persistence` | Core — save/load, settings, serialization |
| `Meta` | Core — analytics, tutorials, accessibility plumbing |

> Animation, Rendering and Networking are engine domains with no category of
> their own: a system needing them will be `Gameplay` or `Core`. Name the domain
> you read the reference for, whichever row you came in on.

**Step 2 — Read engine context (if available):**
- Identify the engine and version: read `engine.name` and `engine.version` from `project.yaml`. Resolve each field independently — if its key is absent or empty (including when `project.yaml` has no `engine:` block), fall back to `.claude/docs/technical-preferences.md` (a `[TO BE CONFIGURED]` value means not set)
- If engine is configured, read `docs/engine-reference/[engine]/VERSION.md`
- Read `docs/engine-reference/[engine]/modules/[domain].md` if it exists.
  **If it does not exist, say so by name** — *"no engine reference for `[domain]`
  under `docs/engine-reference/[engine]/modules/`; feasibility not checked against
  the pinned engine"* — and carry that into §5-pre. A silent skip here is
  indistinguishable from a feasibility check that ran and found nothing wrong,
  which is the failure `.claude/rules/skill-authoring.md` obligation 3 exists to
  stop.

  > **This is not a rare branch.** The domain table above names `Scripting` and
  > `Core` for five of the nine categories (`Narrative`, `Progression`, `Economy`
  > → Scripting; `Persistence`, `Meta` → Core), plus a sub-row each under
  > `Gameplay` and `Core`. The Godot reference ships `animation, audio, input,
  > navigation, networking, physics, rendering, ui` — **there is no
  > `scripting.md` and no `core.md`**. So the majority of non-`Gameplay` systems
  > hit the absent branch every time, and `if it exists` turned that into
  > silence. Either the reference gains those two files or the check reports it;
  > until the former, do the latter.
- Read `docs/engine-reference/[engine]/breaking-changes.md` for domain-relevant entries
- Find the domain-matching ADRs without reading every ADR to learn the field you
  filter on — grep the Domain field first, then read only the matches:
  ```
  Grep pattern="\*\*Domain\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
  ```
  Read only the ADRs whose Domain matches this system's category (its `## Decision`
  and `## Engine Compatibility` sections); skip the rest.

**Step 3 — Present the Feasibility Brief:**

If engine reference docs exist, present before starting design:

```
## Technical Feasibility Brief: [System Name]
Engine: [name + version]
Domain: [domain]

### Known Engine Capabilities (verified for [version])
- [capability relevant to this system]
- [capability 2]

### Engine Constraints That Will Shape This Design
- [constraint from engine-reference or existing ADR]

### Knowledge Gaps (verify before committing to these)
- [post-cutoff feature this design might rely on — mark HIGH/MEDIUM risk]

### Existing ADRs That Constrain This System
- ADR-XXXX: [decision summary] — means [implication for this GDD]
  (or "None yet")
```

If no engine reference docs exist (engine not yet configured), show a short note:
> "No engine configured yet — skipping technical feasibility check. Run
> `/setup-engine` before moving to architecture if you haven't already."

**Step 4 — Ask before proceeding:**

Use `AskUserQuestion`:
- "Any constraints to add before we begin, or shall we proceed with these noted?"
  - Options: "Proceed with these noted", "Add a constraint first", "I need to check the engine docs — pause here"

---

Use `AskUserQuestion`:
- "Ready to start designing [system-name]?"
  - Options: "Yes, let's go", "Show me more context first", "Design a dependency first"

---

## 3. Create File Skeleton

Once the user confirms, **immediately** create the GDD file with empty section
headers. This ensures incremental writes have a target.

**Scaffold only the sections required at the resolved tier** (§1): at
`standard`, omit Player Fantasy and Tuning Knobs (and Formulas only when the
system defines no numeric rule — see §1; the category is a hint, not the test);
at `full`, scaffold all 8.
**Only the sections §1 named as omitted are skipped** — do not leave empty
`[To be designed]` placeholders for those. Every other section in the template
is scaffolded with its placeholder, including the ones §4 has not decided yet.
This sentence governs the three tier omissions above (Player Fantasy, Tuning
Knobs, and Formulas when no numeric rule exists) and nothing else: it is not a
licence to strip a section because it looks optional, and §4 cannot fill a
section §3 never created.

Use the template structure from `.claude/docs/templates/game-design-document.md`:

```markdown
# [System Name]

> **Status**: In Design
> **Author**: [user + agents]
> **Last Updated**: [today's date]
> **Last Verified**: [today's date]
> **Implements Pillar**: [from context]

## Summary

[To be designed]

> **Quick reference** — Layer: `[Foundation | Core | Feature | Presentation]` · Priority: `[MVP | Vertical Slice | Alpha | Full Vision]` · Key deps: `[System names or "None"]`

## Overview

[To be designed]

## Player Fantasy

[To be designed]

## Detailed Design

### Core Rules

[To be designed]

### States and Transitions

[To be designed]

### Interactions with Other Systems

[To be designed]

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## Game Feel

[To be designed]

## UI Requirements

[To be designed]

## Cross-References

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
```

> **This skeleton and the template must stay identical in section set and
> order.** They diverged once and it was invisible: the skeleton omitted
> `## Game Feel` and `## Cross-References`, so §3's own rule — *"§4 cannot fill a
> section §3 never created"* — made both unreachable **at every tier, `full`
> included**, while §3's prose above still said *"every other section in the
> template is scaffolded"*. Two agents authoring a combat GDD noticed the gap
> only by opening the template. If you add a section to one file, add it to the
> other in the same commit.

Ask: "May I create the skeleton file at `design/gdd/[system-name].md`?"

If the user declines: Stop with the following message:
> "Verdict: **BLOCKED** — skeleton creation declined. The design session cannot proceed without the skeleton file, as all subsequent phases use it as the base. Re-run `/design-system [system]` when ready to create the file."
Do not proceed to Section A.

After writing, update `production/session-state/active.md`:
- Use Glob to check if the file exists.
- If it **does not exist**: use the **Write** tool to create it. Never attempt Edit on a file that may not exist.
- If it **already exists**: use the **Edit** tool to update the relevant fields.

File content:
- Task: Designing [system-name] GDD
- Current section: Starting (skeleton created)
- File: design/gdd/[system-name].md

---

## 4. Section-by-Section Design

**Author only the sections required at the resolved tier** (§1). At `standard`,
the walk covers A (Overview), C (Detailed Design), E (Edge Cases),
F (Dependencies), H (Acceptance Criteria) — plus D (Formulas) when the system
defines numeric rules (see §1; the category is a hint, not the test); skip B (Player Fantasy) and
G (Tuning Knobs) unless `workflow_overrides.tuning_knobs: true` forces G. At
`full`, walk all eight (A–H). At `minimal`, the GDD is optional — if authoring
voluntarily, walk the standard set. Any `system_overrides.<system>` tier was
already folded into the resolved tier in §1.

Walk through each required section in order. For **each section**, follow this cycle:

### The Section Cycle

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

1. **Context**: State what this section needs to contain, and surface any relevant
   decisions from dependency GDDs that constrain it.

2. **Questions**: Ask clarifying questions specific to this section. Use
   `AskUserQuestion` for constrained questions, conversational text for open-ended
   exploration.

3. **Options**: Where the section involves design choices (not just documentation),
   present 2-4 approaches with pros/cons. Explain reasoning in conversation text,
   then use `AskUserQuestion` to capture the decision.

4. **Decision**: User picks an approach or provides custom direction.

5. **Draft**: Write the section content in conversation text for review. Flag any
   provisional assumptions about undesigned dependencies.

6. **Approval**: Per the resolved `modes.automation` mode
   (`.claude/docs/automation-modes.md`):

   **In `collaborative` mode**: Immediately after the draft — in the SAME
   response — use `AskUserQuestion`. **NEVER use plain text. NEVER skip
   this step.**
   - Prompt: "Approve the [Section Name] section?"
   - Options: `[A] Approve — write it to file` / `[B] Make changes — describe what to fix` / `[C] Start over`

   **The draft and the approval widget MUST appear together in one response.
   If the draft appears without the widget, the user is left at a blank prompt
   with no path forward — this is a protocol violation in collaborative mode.**

   **In `guided` mode**: Write the section immediately after the draft with
   a brief one-line summary of what was decided. Skip the per-section widget;
   the multi-section authoring rule (no per-section confirmation) applies.

   **In `autonomous` mode**: Write the section directly and call
   `log_decision` with `Decision point: Approve [Section Name] section`,
   `Chosen: [A] Approve`, `Category: minor`.

7. **Write**: Use the Edit tool to replace the placeholder with the approved content.
   **CRITICAL**: Always include the section heading in the `old_string` to ensure
   uniqueness — never match `[To be designed]` alone, as multiple sections use the
   same placeholder and the Edit tool requires a unique match. Use this pattern:
   ```
   old_string: "## [Section Name]\n\n[To be designed]"
   new_string: "## [Section Name]\n\n[approved content]"
   ```
   Confirm the write.

8. **Registry conflict check** (Sections C and D only — Detailed Design and Formulas):
   After writing, scan the section content for entity names, item names, formula
   names, and numeric constants that appear in the registry. For each match:
   - Compare the value just written against the registry entry.
   - If they differ: **surface the conflict immediately** before starting the next
     section. Do not continue silently.
     > "Registry conflict: [name] is registered in [source GDD] as [registry_value].
     > This section just wrote [new_value]. Which is correct?"
   - If new (not in registry): flag it as a candidate for registry registration
     (will be handled in Phase 5).

After writing each section, update `production/session-state/active.md` with the
completed section name. Use Glob to check if the file exists — use Write to create
it if absent, Edit to update it if present.

### Section-Specific Guidance

Each section has unique design considerations and may benefit from specialist agents:

---

### Section A: Overview

**Goal**: One paragraph a stranger could read and understand.

**Derive recommended options before building the widget**: Read the system's category and layer from the systems index (already in context from Phase 2), then determine the recommended option for each tab:
- **Framing tab**: keyed on the `Category` column (`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`). Player-facing — `Gameplay`, `UI`, `Audio`, `Narrative` → `[C] Both` recommended. Internal — `Core`, `Persistence`, `Meta` → `[A]` recommended. Mixed — `Economy`, `Progression` → `[C] Both`. **Tiebreak, when Layer and Category disagree** (a `Foundation`-layer `Gameplay` system is the common case): **Category wins** — the framing describes what the section is *about*, and a player-facing system stays player-facing wherever it sits in the dependency graph.
- **ADR ref tab**: Glob `docs/architecture/adr-*.md` and grep for the system name in the GDD Requirements section of any ADR. If a matching ADR is found → `[A] Yes — cite the ADR` recommended. If none found → `[B] No` recommended.
- **Fantasy tab**: Foundation/Infrastructure layer → `[B] No` recommended. All other categories → `[A] Yes` recommended.

Append `(Recommended)` to the appropriate option text in each tab.

**Framing questions (ask BEFORE drafting)**: Use `AskUserQuestion` with a multi-tab widget:
- Tab "Framing" — "How should the overview frame this system?" Options: `[A] As a data/infrastructure layer (technical framing)` / `[B] Through its player-facing effect (design framing)` / `[C] Both — describe the data layer and its player impact`
- Tab "ADR ref" — "Should the overview reference the existing ADR for this system?" Options: `[A] Yes — cite the ADR for implementation details` / `[B] No — keep the GDD at pure design level`
- Tab "Fantasy" — "Does this system have a player fantasy worth stating?" Options: `[A] Yes — players feel it directly` / `[B] No — pure infrastructure, players feel what it enables`

Use the answers to shape the draft. **In `collaborative` mode, do NOT answer
these questions yourself and auto-draft** — the widget must appear. In `guided`
and `autonomous`, this is a MINOR framing decision: select the recommended
option derived above, state it in one line, and proceed (that is the whole
point of pre-deriving recommendations). Applies to every "ask BEFORE drafting"
widget in this section walk, not just this one.

**Questions to ask**:
- What is this system in one sentence?
- How does a player interact with it? (active/passive/automatic)
- Why does this system exist — what would the game lose without it?

**Cross-reference**: Check that the description aligns with how the systems index
describes it. Flag discrepancies.

**Design vs. implementation boundary**: Overview questions must stay at the behavior
level — what the system *does*, not *how it is built*. If implementation questions
arise during the Overview (e.g., "Should this use an Autoload singleton or a signal
bus?"), note them as "→ becomes an ADR" and move on. Implementation patterns belong
in `/architecture-decision`, not the GDD. The GDD describes behavior; the ADR
describes the technical approach used to achieve it.

---

### Section B: Player Fantasy

**Goal**: The emotional target — what the player should *feel*.

**Derive recommended option before building the widget**: Read the system's category and layer from Phase 2 context:
Keyed on the `Category` column (`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`):
- Player-facing — `Gameplay`, `UI`, `Audio`, `Narrative` → `[A] Direct` recommended
- Internal — `Core`, `Persistence`, `Meta` → `[B] Indirect` recommended
- Mixed — `Economy`, `Progression` → `[C] Both` recommended

**When Layer and Category disagree, Category wins** — same tiebreak as the
Framing tab above.

Append `(Recommended)` to the appropriate option text.

**Framing question (ask BEFORE drafting)**: Use `AskUserQuestion`:
- Prompt: "Is this system something the player engages with directly, or infrastructure they experience indirectly?"
- Options: `[A] Direct — player actively uses or feels this system` / `[B] Indirect — player experiences the effects, not the system` / `[C] Both — has a direct interaction layer and infrastructure beneath it`

Use the answer to frame the Player Fantasy section appropriately. Do NOT assume the answer.

**Questions to ask**:
- What emotion or power fantasy does this serve?
- What reference games nail this feeling? What specifically creates it?
- Is this a "system you love engaging with" or "infrastructure you don't notice"?

**Cross-reference**: Must align with the game pillars. If the system serves a pillar,
quote the relevant pillar text.

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`creative-director` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY)**: After the framing answer is given but before drafting,
spawn `creative-director` via `Agent`:
- Provide: system name, framing answer (direct/indirect/both), game pillars, any reference games the user mentioned, the game concept summary
- Ask: "Shape the Player Fantasy for this system. What emotion or power fantasy should it serve? What player moment should we anchor to? What tone and language fits the game's established feeling? Be specific — give me 2-3 candidate framings."
- Collect the creative-director's framings and present them to the user alongside the draft.

**Do NOT draft Section B without first consulting `creative-director`.** The framing
answer tells us *what kind* of fantasy it is; the creative-director shapes *how it's
described* — tone, language, the specific player moment to anchor to.

---

### Section C: Detailed Design (Core Rules, States, Interactions)

**Goal**: Unambiguous specification a programmer could implement without questions.

This is usually the largest section. Break it into sub-sections:

1. **Core Rules**: The fundamental mechanics. Use numbered rules for sequential
   processes, bullets for properties.
2. **States and Transitions**: If the system has states, map every state and
   every valid transition. Use a table.
3. **Interactions with Other Systems**: For each dependency (upstream and downstream),
   specify what data flows in, what flows out, and who owns the interface.

**Questions to ask**:
- Walk me through a typical use of this system, step by step
- What are the decision points the player faces?
- What can the player NOT do? (Constraints are as important as capabilities)

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "Specialist agents not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY)**: Before drafting Section C, spawn specialist agents via `Agent` in parallel:
- Look up the system category in the routing table (Section 6 of this skill)
- Spawn the Primary Agent AND Supporting Agent(s) listed for this category
- Provide each agent: system name, game concept summary, pillar set, dependency GDD excerpts, the specific section being worked on
- Collect their findings before drafting
- Surface any disagreements between agents to the user via `AskUserQuestion`
- Draft only after receiving specialist input

**Do NOT draft Section C without first consulting the appropriate specialists.** A `systems-designer` reviewing rules and mechanics will catch design gaps the main session cannot.

**Cross-reference**: For each interaction listed, verify it matches what the
dependency GDD specifies. If a dependency defines a value or formula and this
system expects something different, flag the conflict.

---

### Section D: Formulas

**Goal**: Every mathematical formula, with variables defined, ranges specified,
and edge cases noted.

**Completion Steering — always begin each formula with this exact structure:**

```
The [formula_name] formula is defined as:

`[formula_name] = [expression]`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| [name] | float/int | [min–max] | data file / calculated / constant | [what it represents] |

**Output Range:** [min] to [max] under normal play; [behaviour at extremes]
**Example:** [worked example with real numbers]
```

Do NOT write `[Formula TBD]` or describe a formula in prose without the variable
table. A formula without defined variables cannot be implemented without guesswork.

> **These columns must match `templates/game-design-document.md` exactly.** They
> did not: this block said `Symbol` where the template says `Source`, so a
> correctly-authored GDD was wrong against whichever of the two its reader
> happened to hold. `Source` is the column that stays, because it is what carries
> the coding-standards rule *"gameplay values must be data-driven (external
> config), never hardcoded"* into the design document — a variable marked
> `data file` is a tuning knob, one marked `constant` is a deliberate exception,
> and the distinction is invisible under a `Symbol` column. Put a symbol, where
> one helps, in the expression itself.

**Questions to ask**:
- What are the core calculations this system performs?
- Should scaling be linear, logarithmic, or stepped?
- What should the output ranges be at early/mid/late game?

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY)**: Before proposing any formulas or balance values, spawn specialist agents via `Agent` in parallel:
- **Always spawn `systems-designer`**: provide Core Rules from Section C, tuning goals from user, balance context from dependency GDDs. Ask them to propose formulas with variable tables and output ranges.
- **For economy/cost systems, also spawn `economy-designer`**: provide placement costs, upgrade cost intent, and progression goals. Ask them to validate cost curves and ratios.
- Present the specialists' proposals to the user for review via `AskUserQuestion`
- The user decides; the main session writes to file
- **Do NOT invent formula values or balance numbers without specialist input.** A user without balance design expertise cannot evaluate raw numbers — they need the specialists' reasoning.

**Cross-reference**: If a dependency GDD defines a formula whose output feeds into
this system, reference it explicitly. Don't reinvent — connect.

---

### Section E: Edge Cases

**Goal**: Explicitly handle unusual situations so they don't become bugs.

**Completion Steering — format each edge case as:**
- **If [condition]**: [exact outcome]. [rationale if non-obvious]

Example (adapt terminology to the game's domain):
- **If [resource] reaches 0 while [protective condition] is active**: hold at minimum until condition ends, then apply consequence.
- **If two [triggers/events] fire simultaneously**: resolve in [defined priority order]; ties use [defined tiebreak rule].

Do NOT write vague entries like "handle appropriately" — each must name the exact
condition and the exact resolution. An edge case without a resolution is an open
design question, not a specification.

**Questions to ask**:
- What happens at zero? At maximum? At out-of-range values?
- What happens when two rules apply at the same time?
- What happens if a player finds an unintended interaction? (Identify degenerate strategies)

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY)**: Spawn `systems-designer` via `Agent` before finalising edge cases. Provide: the completed Sections C and D, and ask them to identify edge cases from the formula and rule space that the main session may have missed. For narrative systems, also spawn `narrative-director`. Present their findings and ask the user which to include.

**Cross-reference**: Check edge cases against dependency GDDs. If a dependency
defines a floor, cap, or resolution rule that this system could violate, flag it.

---

### Section F: Dependencies

**Goal**: Map every system connection with direction and nature.

This section is partially pre-filled from the context gathering phase. Present the
known dependencies from the systems index and ask:
- Are there dependencies I'm missing?
- For each dependency, what's the specific data interface?
- Which dependencies are hard (system cannot function without it) vs. soft
  (enhanced by it but works without it)?

**Cross-reference**: This section must be bidirectionally consistent. If this system
lists "depends on Combat", then the Combat GDD should list "depended on by [this
system]". Flag any one-directional dependencies for correction.

---

### Section G: Tuning Knobs

**Goal**: Every designer-adjustable value, with safe ranges and extreme behaviors.

**Questions to ask**:
- What values should designers be able to tweak without code changes?
- For each knob, what breaks if it's set too high? Too low?
- Which knobs interact with each other? (Changing A makes B irrelevant)

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Derive the knobs from Section D's variable table yourself. Add a note: "`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless Section D defines a formula whose knobs interact (changing one makes another inert).
- `full` → delegate as described below.

**Agent delegation**: If formulas are complex, delegate to `systems-designer`
to derive tuning knobs from the formula variables.

> The guard above was missing here while Sections B, C, D, E and H all carried
> one — and this delegation names `systems-designer`, the same agent Section D's
> guard has already told a `solo` run to skip. Read without it, `solo` skips the
> specialist for the formulas and then consults it for the knobs derived from
> those same formulas.

**Cross-reference**: If a dependency GDD lists tuning knobs that affect this system,
reference them here. Don't create duplicate knobs — point to the source of truth.

---

### Section H: Acceptance Criteria

**Goal**: Testable conditions that prove the system works as designed.

**Completion Steering — format each criterion as Given-When-Then:**
- **GIVEN** [initial state], **WHEN** [action or trigger], **THEN** [measurable outcome]

Example (adapt terminology to the game's domain):
- **GIVEN** [initial state], **WHEN** [player action or system trigger], **THEN** [specific measurable outcome].
- **GIVEN** [a constraint is active], **WHEN** [player attempts an action], **THEN** [feedback shown and action result].

Include at least: one criterion per core rule from Section C, and one per formula
from Section D. Do NOT write "the system works as designed" — every criterion must
be independently verifiable by a QA tester without reading the GDD.

> **When Section D was not authored** (Formulas optional at this tier because the
> system defines no numeric rule), there are no formulas to cover and the
> criteria come from Section C alone — say so in one line rather than silently
> writing fewer criteria. **If Section D was skipped but Section C states a
> quantity** — a rate, threshold, cost or curve — that is the §1 test being met
> after the fact: stop, tell the user Formulas is required for this system, and
> author it before finalising the criteria. A criterion cannot verify a number
> the GDD never defines.
>
> **That escalation applies at `standard` only.** It re-runs §1's *conditional*
> Formulas test, and §1 disables that conditional at `minimal` outright — *"the
> conditional Formulas rule does NOT re-apply at minimal"*. At `minimal` a
> Section C quantity is expected and does **not** pull Formulas back in: state
> the value inline in Core Rules so it stays implementable, and move on. At
> `full`, Section D is unconditionally required, so the case cannot arise. Read
> without this scope, the two rules contradict each other for any `minimal`
> system that defines a rate — which is most of them.

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`qa-lead` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**Agent delegation (MANDATORY)**: Spawn `qa-lead` via `Agent` before finalising acceptance criteria. Provide: the completed GDD sections C, D, E, and ask them to validate that the criteria are independently testable and cover all core rules and formulas. Surface any gaps or untestable criteria to the user.

**Questions to ask**:
- What's the minimum set of tests that prove this works?
- What performance budget does this system get? (frame time, memory)
- What would a QA tester check first?

**Cross-reference**: Include criteria that verify cross-system interactions work,
not just this system in isolation.

---

### Optional Sections: Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions

These five are the template sections that are **not** among §1's eight. They are
governed here, not by the tier: §1's per-tier lists decide the *required* set,
and this block decides the rest independently. Adding a section here therefore
never changes a tier's section count.

Visual/Audio and Game Feel are **REQUIRED** for some categories — not optional.
Determine the requirement level before asking:

**Keyed on the `Category` column of `systems-index.md`** — the nine values
`templates/systems-index.md` defines. Every one of the nine appears below
exactly once, so nothing falls through:

**Visual/Audio is REQUIRED (mandatory — do not offer to skip) for:**
- `Gameplay` — combat, AI, stealth, movement, interaction: everything the player
  sees resolve
- `UI` — HUD, menus, inventory screens, dialogue UI
- `Narrative` — dialogue, quests, cutscenes, lore delivery
- `Audio` — by definition

> **`Gameplay` is the row this table was missing.** It is the category
> `/map-systems` assigns to combat, AI and movement — the largest bucket in most
> action games. If it appears in **neither** this list nor the "all other" list
> below, the skill has no defined behaviour for it and the author has to guess.
> All nine categories must be covered between the two lists.

For required systems: **spawn `art-director` via `Agent`** before drafting this section. Provide: system name, game concept, game pillars, art bible sections 1–4 if they exist. Ask them to specify: (1) VFX and visual feedback requirements for this system's events, (2) any animation or visual style constraints, (3) which art bible principles most directly apply to this system. Present their output; do NOT leave this section as `[To be designed]` for visual systems.

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`art-director` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this system's visual feedback is central to it (a `Gameplay` or `UI` system whose events the player reads to play). Otherwise draft without the agent.
- `full` → spawn as described above.

> Sections B, C, D, E and H each carry this block and this spawn did not, while
> being worded as mandatory (*"do NOT leave this section as `[To be designed]`"*).
> Two agents in `solo` skipped it anyway, on the strength of the other five, and
> both flagged the guess. `director-gates.md`'s *"solo → no director gates
> anywhere"* governs director **gates**, not specialist spawns, so it did not
> settle it — this block does.

**Game Feel is REQUIRED (mandatory — do not offer to skip) for `Gameplay` and
`UI`** — the categories whose systems the player directly operates, where
responsiveness, weight and snap are design targets rather than polish. It is
optional for the other seven. The template argues the point itself: feel *"drives
animation budgets, input handling architecture, and hitbox timing. Retrofitting
feel targets after implementation is expensive."*

**Cross-References is REQUIRED whenever the Dependencies section names another
GDD.** The rule is derived, not category-keyed: if this document references
another system's mechanic, value or rule anywhere, that reference belongs in the
table. Where Dependencies names nothing, write *"None — this system references no
other GDD"* rather than leaving the placeholder. `/review-all-gdds` Phase 2c
reads this table when it exists.

For the remaining five categories — `Core`, `Progression`, `Economy`,
`Persistence`, `Meta` — Visual/Audio is optional: offer the optional sections
after the required sections.

> **At `minimal`, force nothing.** §1 says a voluntary `minimal` GDD is *"exactly
> the 5 standard sections"*, which contradicts a category rule that makes
> Visual/Audio or Game Feel mandatory. §1 wins: at `minimal` both drop to
> optional and the whole set goes through the widget below. The contradiction is
> real — an agent authoring a `minimal` inventory GDD hit it and had to choose.

Use `AskUserQuestion`:
- "The required sections for this workflow tier are complete. Which of the
  remaining template sections do you want to define?"
  - Options: "All of them", "Just Cross-References and open questions", "Skip — I'll add these later"
  - List in the question only the ones still outstanding: Visual/Audio, Game
    Feel, UI Requirements, Cross-References, Open Questions **minus** any this
    system's category or dependencies already made mandatory above. Offering to
    skip a section the rules just made required is how a mandatory section gets
    skipped.
  - **Recommended option**: "All of them" when the system has any dependency,
    UI surface or player-facing feedback; "Just Cross-References and open
    questions" otherwise. `autonomous` needs a marked recommendation to pick —
    the three options previously carried none, unlike the Section A/B widgets,
    so an unattended run had nothing to choose by and defaulted to skipping.

  Do **not** state a section count here. The required set is tier-dependent
  (§1: 8 at `full`, 5 + conditional Formulas at `standard`, 5 at a voluntary
  `minimal`), so the previous hardcoded "8 required sections are complete" was
  false on every run below `full` — it told a `standard`-tier user that 8
  sections existed when 6 had been authored.

For **Visual/Audio** (non-required systems): Coordinate with `art-director` and `audio-director` if detail is needed. Often a brief note suffices at the GDD stage.

> **Asset Spec Flag**: After the Visual/Audio section is written with real content, output this notice:
> "📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:[system-name]` to produce per-asset visual descriptions, dimensions, and generation prompts from this section."

For **UI Requirements**: Coordinate with `ux-designer` for complex UI systems.
After writing this section, check whether it contains real content (not just
`[To be designed]` or a note that this system has no UI). If it does have real
UI requirements, output this flag immediately:

> **📌 UX Flag — [System Name]**: This system has UI requirements. In Phase 4
> (Pre-Production), run `/ux-design` to create a UX spec for each screen or
> HUD element this system contributes to **before** writing epics. Stories that
> reference UI should cite `design/ux/[screen].md`, not the GDD directly.
>
> Note this in the systems index for this system if you update it.

For **Open Questions**: Capture anything that came up during design that wasn't
fully resolved. Each question should have an owner and target resolution date.

---

## 5. Post-Design Validation

After all sections are written:

### 5-pre: Author the Summary

Write `## Summary` and its `> **Quick reference**` line now — after the design
exists, so the summary distils real content rather than intentions. This runs
**at every tier**, including `standard` and a voluntary `minimal` GDD: the
Summary is what lets a later skill scan 20 GDDs and decide which to read in full
(`/create-epics`, `/architecture-review`, `/review-all-gdds` all grep it), so a
GDD without it silently forces those consumers back to full reads.

- **Summary body**: 2–3 sentences — what this system is, what it does for the
  player, why it exists in this game. No jargon; a reader who has not seen the
  GDD should learn whether it is relevant to their task.
- **Quick reference**: `Layer` and `Priority` from the systems index
  (`design/gdd/systems-index.md`); `Key deps` from the Dependencies section just
  written (system names, or `None`).

Replace the `[To be designed]` Summary placeholder in the skeleton. Then apply
the section cycle's Write step as for any other section.

### 5a: Self-Check

Read back the complete GDD from file (not from conversation memory — the file is
the source of truth). Verify:
- The `## Summary` and its Quick reference are populated (not the placeholder)
- Every section **required at this system's effective tier** has real content
  (not placeholders) — §1: 8 at `full`, 5 + conditional Formulas at `standard`,
  5 at a voluntary `minimal`. Do not verify against a fixed count of 8: below
  `full` that reports a correctly-authored GDD as incomplete, which is the same
  error already corrected in the optional-sections prompt above
- Formulas reference defined variables
- Edge cases have resolutions
- Dependencies are listed with interfaces
- Acceptance criteria are testable

### 5a-bis: Creative Director Pillar Review

**Review mode check** — apply before spawning CD-GDD-ALIGN:
- `solo` → skip. Note: "CD-GDD-ALIGN skipped — Solo mode." Proceed to Step 5b.
- `lean` → skip (not a PHASE-GATE). Note: "CD-GDD-ALIGN skipped — Lean mode." Proceed to Step 5b.
- `full` → spawn as normal.

Before finalizing the GDD, spawn `creative-director` via `Agent` using gate **CD-GDD-ALIGN** (`.claude/docs/director-gates/cd-gdd-align.md`).

Pass: completed GDD file path, game pillars (from `design/gdd/game-concept.md` or `design/gdd/game-pillars.md`), MDA aesthetics target.

Handle verdict per the standard rules in `director-gates.md`. After resolution, record the verdict in the GDD Status header:
`> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]`

---

### 5b: Update Entity Registry

Scan the completed GDD for cross-system facts that should be registered:
- Named entities (enemies, NPCs, bosses) with stats or drops
- Named items with values, weights, or categories
- Named formulas with defined variables and output ranges
- Named constants referenced by value in more than one place

**First check the registry exists** — §2a reads it *"if it exists"*, and this
step never carried the same guard. At `standard` and below the file is often
absent, and a grep against a missing path returns nothing, which is
indistinguishable from "no candidate is registered yet":

- **Absent** — say so, and ask whether to create it:
  *"`design/registry/entities.yaml` does not exist. May I create it with these
  [N] entries?"* If the user declines, skip 5b and say the registry was not
  written — do not treat the skip as a clean pass.
- **Present but empty** — every list is `[]`, or the only matches are inside
  comment blocks. Treat it as present, register the candidates, but say which
  state you found: *"registry exists and is empty — all [N] entries are new."*
  The shipped template's comments carry fully-formed examples referencing
  `design/gdd/inventory.md` with real-looking values (`base_inventory_slots: 20`,
  `gold_carry_limit: 9999`), so §2a's prescribed
  `grep referenced_by.*[system-name]` returns **comment lines** on an empty
  registry — and §2d would then present those invented numbers to the user as
  *"These values are locked."* Match entries under a live `entities:`/`items:`/
  `formulas:`/`constants:` key, never a commented example.
- **Present** — for each candidate, check whether it is already registered:

```
Grep pattern="  - name: [candidate_name]" path="design/registry/entities.yaml"
```

Present a summary:
```
Registry candidates from this GDD:
  NEW (not yet registered):
    - [entity_name] [entity]: [attribute]=[value], [attribute]=[value]
    - [item_name] [item]: [attribute]=[value], [attribute]=[value]
    - [formula_name] [formula]: variables=[list], output=[min–max]
  ALREADY REGISTERED (referenced_by will be updated):
    - [constant_name] [constant]: value=[N] ← matches registry ✅
```

Ask: "May I update `design/registry/entities.yaml` with these [N] new entries
and update `referenced_by` for the existing entries?" (If the file was absent
and the user approved creating it, the wording is *create*, not *update*, and
there are no `referenced_by` arrays to merge.)

If yes: append new entries and update `referenced_by` arrays. Never modify
existing `value` / attribute fields without surfacing it as a conflict first.

### 5c: Offer Design Review

Present a completion summary:

> **GDD Complete: [System Name]**
> - Sections written: [list]
> - Provisional assumptions: [list any assumptions about undesigned dependencies]
> - Cross-system conflicts found: [list or "none"]

> **To validate this GDD, open a fresh Claude Code session and run:**
> `/design-review design/gdd/[system-name].md`
>
> **Never run `/design-review` in the same session as `/design-system`.** The reviewing
> agent must be independent of the authoring context. Running it here would inherit
> the full design history, making independent critique impossible.

**NEVER offer to run `/design-review` inline.** Always direct the user to a fresh window.

### 5d: Update Systems Index

After the GDD is complete (and optionally reviewed):

**First check the systems index exists.** §2a skips it at `minimal` because it is
never written at that tier, and this step never carried the same guard — the same
class of bug §5b was patched for. It bites hardest on a `minimal` project with a
`system_overrides` bump, where the effective tier is `standard` or `full` and
nothing else in §5 hints the file may be absent.

- **Absent** — say so in one line (*"no `design/gdd/systems-index.md` at this
  workflow tier; nothing to update"*) and skip to §5e. Do **not** offer to create
  one: `/map-systems` owns that file, and a stub written here would be a systems
  index listing exactly one system.
- **Present** — continue:

- Read the systems index
- Update the target system's row:
  - If design-review was run and verdict is APPROVED: Status → "Approved"
  - If design-review was run and verdict is NEEDS REVISION: Status → "In Review"
  - If design-review was skipped: Status → "Designed" (pending review)
  - If the user chose "I'll review it myself first": Status → "Designed"
  - Design Doc: link to `design/gdd/[system-name].md`
- Update the Progress Tracker counts

Ask: "May I update the systems index at `design/gdd/systems-index.md`?"

### 5e: Update Session State

Update `production/session-state/active.md` with:
- Task: [system-name] GDD
- Status: Complete (or In Review if design-review was run)
- File: design/gdd/[system-name].md
- Sections: [list the sections actually authored, by name] — **never a fixed
  count**; §5a forbids verifying against `/8`, and the same reasoning applies to
  recording it. Below `full` a correctly-authored GDD has fewer than 8 sections,
  and writing "All 8 written" into session state makes the next reader believe
  a complete GDD is incomplete
- Next: [suggest next system from design order]

### 5f: Suggest Next Steps

Use `AskUserQuestion`:
- "What's next?"
  - Options:
    - "Run `/consistency-check` — verify this GDD's values don't conflict with existing GDDs (recommended before designing the next system)"
    - "Design next system ([next-in-order])" — if undesigned systems remain
    - "Fix review findings" — if design-review flagged issues
    - "Stop here for this session"
    - "Run `/gate-check`" — if enough MVP systems are designed

---

## 6. Specialist Agent Routing

This skill delegates to specialist agents for domain expertise. The main session
orchestrates the overall flow; agents provide expert content.

**Rows here are finer-grained than the nine `Category` values on purpose** — the
right specialist for combat is not the right specialist for pathfinding, and both
are `Gameplay`. Resolve in two steps: take the system's `Category` from
`systems-index.md`, then pick the row within it that matches what the system
actually does. Every category has at least one row, so nothing falls through.

| `Category` | Rows below to choose from |
|---|---|
| `Gameplay` | Combat/damage/health · AI/pathfinding/behavior · Animation/character movement · Character systems · Camera/input/controls |
| `Core` | Foundation/Infrastructure · Camera/input/controls |
| `Persistence` | Foundation/Infrastructure |
| `Economy` | Economy/loot/crafting |
| `Progression` | Progression/XP/skills |
| `UI` | UI systems · Visual effects (when the system is HUD-adjacent VFX) |
| `Audio` | Audio systems |
| `Narrative` | Dialogue/quests/lore |
| `Meta` | Foundation/Infrastructure (analytics, tutorial plumbing) · UI systems (accessibility options screens) |

If two rows fit, spawn the union of their Primary agents and say why.

| System type | Primary Agent | Supporting Agent(s) |
|----------------|---------------|---------------------|
| **Foundation/Infrastructure** (event bus, save/load, scene mgmt, service locator) | `systems-designer` | `gameplay-programmer` (feasibility), `engine-programmer` (engine integration) |
| Combat, damage, health | `game-designer` | `systems-designer` (formulas), `ai-programmer` (enemy AI), `art-director` (hit feedback visual direction, VFX intent) |
| Economy, loot, crafting | `economy-designer` | `systems-designer` (curves), `game-designer` (loops) |
| Progression, XP, skills | `game-designer` | `systems-designer` (curves), `economy-designer` (sinks) |
| Dialogue, quests, lore | `game-designer` | `narrative-director` (story), `writer` (content), `art-director` (character visual profiles, cinematic tone) |
| UI systems (HUD, menus) | `game-designer` | `ux-designer` (flows), `ui-programmer` (feasibility), `art-director` (visual style direction), `technical-artist` (render/shader constraints) |
| Audio systems | `game-designer` | `audio-director` (direction), `sound-designer` (specs) |
| AI, pathfinding, behavior | `game-designer` | `ai-programmer` (implementation), `systems-designer` (scoring) |
| Level/world systems | `game-designer` | `level-designer` (spatial), `world-builder` (lore) |
| Camera, input, controls | `game-designer` | `ux-designer` (feel), `gameplay-programmer` (feasibility) |
| Animation, character movement | `game-designer` | `art-director` (animation style, pose language), `technical-artist` (rig/blend constraints), `gameplay-programmer` (feel) |
| Visual effects, particles, shaders | `game-designer` | `art-director` (VFX visual direction), `technical-artist` (performance budget, shader complexity), `systems-designer` (trigger/state integration) |
| Character systems (stats, archetypes) | `game-designer` | `art-director` (character visual archetype), `narrative-director` (character arc alignment), `systems-designer` (stat formulas) |

**When delegating via the `Agent` tool**:
- Provide: system name, game concept summary, dependency GDD excerpts, the specific
  section being worked on, and what question needs expert input
- The agent returns analysis/proposals to the main session
- The main session presents the agent's output to the user via `AskUserQuestion`
- The user decides; the main session writes to file
- Agents do NOT write to files directly — the main session owns all file writes

---

## 7. Recovery & Resume

If the session is interrupted (compaction, crash, new session):

1. Read `production/session-state/active.md` — it records the current system and
   which sections are complete
2. Read `design/gdd/[system-name].md` — sections with real content are done;
   sections with `[To be designed]` still need work
3. Resume from the next incomplete section — no need to re-discuss completed ones

This is why incremental writing matters: every approved section survives any
disruption.

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see the per-mode rules in `.claude/docs/automation-modes.md` — the
"Never" lines below describe what collaborative mode requires, not what
applies universally.

This skill follows the collaborative design principle at every step:

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?"
   - Phase 4 (each section): Design questions, approach options, draft approval
   - Phase 5: "May I update the entity registry? May I update the systems
     index? What's next?" — **not** "Run design review?": §5c forbids offering
     `/design-review` inline, because the reviewing agent must not inherit this
     session's design history. Phase 5c presents the hand-off; it never asks.
3. **"May I write to [filepath]?"** before the skeleton and before each section write
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write
6. **Cross-referencing**: Every section checks existing GDDs for conflicts
7. **Specialist routing**: Complex sections get expert agent input, presented to
   the user for decision — never written silently

**Never** auto-generate the full GDD and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved GDD without flagging the conflict.
**Always** show where decisions come from (dependency GDDs, pillars, user choices).

## Context Window Awareness

This is a long-running skill. After writing each section, check if the status line
shows context at or above 70%. If so, append this notice to the response:

> **Context is approaching the limit (≥70%).** Your progress is saved — all approved
> sections are written to `design/gdd/[system-name].md`. When you're ready to continue,
> open a fresh Claude Code session and run `/design-system [system-name]` — it will
> detect which sections are complete and resume from the next one.

---

## Recommended Next Steps

- Run `/design-review design/gdd/[system-name].md` in a **fresh session** to validate the completed GDD independently
- Run `/consistency-check` to verify this GDD's values don't conflict with other GDDs
- Run `/map-systems next` to move to the next highest-priority undesigned system
- Run `/gate-check pre-production` when all MVP GDDs are authored and reviewed
