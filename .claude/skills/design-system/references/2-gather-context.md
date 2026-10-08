# /design-system — Phase 2: Gather Context

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Gather Context (Read Phase)

**In this file:**

- 2a: Required Reads
- 2b: Dependency Reads
- 2c: Optional Reads
- 2d: Present Context Summary
- 2e: Technical Feasibility Pre-Check

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
- **Entity registry**: If `design/registry/entities.yaml` exists, grep it for
  the entries this system owns and the entries that reference it:
  ```
  Grep pattern="source: design/gdd/[system-name].md" path="design/registry/entities.yaml" output_mode="content" -A 6
  Grep pattern="design/gdd/[system-name].md" path="design/registry/entities.yaml" output_mode="content" -B 8
  ```
  `referenced_by:` is a block list (the key and its paths are on separate
  lines), so match the path with `-B 8` context to see the owning entry; a
  `referenced_by.*[system-name]` one-liner never matches it. Hold these
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
Grep pattern="^## ([0-9]+\. )?(Dependencies|Formulas|Edge Cases|Tuning Knobs)" glob="design/gdd/[dep].md" output_mode="content" -A 20
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
