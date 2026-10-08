# /design-system — Phase 4: Section-by-Section Design

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Section-by-Section Design

**In this file:**

- The Section Cycle
- Section-Specific Guidance
- Section A: Overview
- Section B: Player Fantasy
- Section C: Detailed Design (Core Rules, States, Interactions)
- Section D: Formulas
- Section E: Edge Cases
- Section F: Dependencies
- Section G: Tuning Knobs
- Section H: Acceptance Criteria
- Optional Sections: Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions

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

**Every skipped spawn is announced.** When a section's review-mode check below
skips its specialist — in `lean` as well as `solo` — print that section's note
with the mode it ran in, e.g. "`creative-director` not consulted — Lean mode.
Review manually before production." A section drafted without its specialist
must say so in the output, whichever mode skipped it.

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
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note naming them: "`[the Section 6 routing table's Primary and Supporting Agents for this category]` not consulted — Solo mode. Review manually before production."
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
