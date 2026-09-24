---
name: ux-design
description: "Section-by-section UX spec authoring for a screen, flow or HUD. Reads the player journey to provide context; also project-wide accessibility."
argument-hint: "[screen/flow name] or 'hud' or 'patterns' or 'accessibility'"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/ux-design/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,docs.density`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.


When this skill is invoked:

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Authoring guidance**: the skeletons below are self-contained — author from them
directly. When a section needs depth (worked examples, pattern catalogs,
accessibility criteria), the matching guide has it:

| Producing | Guide |
|---|---|
| UX spec | `.claude/docs/templates/guidance/ux-spec-guide.md` |
| HUD design | `.claude/docs/templates/guidance/hud-design-guide.md` |
| Interaction patterns | `.claude/docs/templates/guidance/interaction-pattern-library-guide.md` (routes to three topic files) |
| Accessibility requirements | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

**Load a guide per-section, never whole** — each is organised by section and the
pointers in the templates name the exact section to read.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — a UX spec is required per screen.
- `standard` — core screens only (main menu, HUD, primary game loop).
- `minimal` — not required. Can still be run voluntarily.

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which screens are specced. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` = wireframe descriptions +
interaction bullets; `balanced` = wireframes + paragraph descriptions of flows
(default); `thorough` = full prose including user-research summaries and
alternative flow considerations. Apply it to every section you author.

## 1. Parse Arguments & Determine Mode

Four authoring modes exist based on the argument:

| Argument | Mode | Output file |
|----------|------|-------------|
| `hud` | HUD design | `design/ux/hud.md` |
| `patterns` | Interaction pattern library | `design/ux/interaction-patterns.md` |
| `accessibility` | Project-wide accessibility requirements | `design/accessibility-requirements.md` |
| Any other value (e.g., `main-menu`, `inventory`) | UX spec for a screen or flow | `design/ux/[argument].md` |
| No argument | Ask the user | (see below) |

> **`accessibility` is the only mode that writes outside `design/ux/`.** Its
> output is a project-wide standard the per-screen specs consult, not a spec for
> one screen — `.claude/docs/workflow-catalog.yaml`, the Pre-Production and
> Polish gates, and `/architecture-review` all check
> `design/accessibility-requirements.md` at that exact path. Do not "tidy" it
> under `design/ux/`: every one of those checks would stop matching, and the
> Technical Setup → Pre-Production gate would become unpassable again.

**If no argument is provided**, do not fail — ask instead. Use `AskUserQuestion`:
- "What are we designing today?"
  - Options: "A specific screen or flow (I'll name it)", "The game HUD", "The interaction pattern library", "The project-wide accessibility requirements", "I'm not sure — help me figure it out"

If the user selects "I'll name it" or types a screen name, normalize it to kebab-case
for the filename (e.g., "Main Menu" becomes `main-menu`).

---

## 2. Gather Context (Read Phase)

Read all relevant context **before** asking the user anything. The skill's value
comes from arriving informed.

### 2a: Required Reads

- **Game concept**: Read `design/gdd/game-concept.md` — if missing, warn:
  > "No game concept found. Run `/brainstorm` first to establish the game's
  > foundation before designing UX."
  > Continue anyway if the user asks.

### 2b: Player Journey

Read `design/player-journey.md` if it exists. For each relevant section, extract:
- Which journey phase(s) does this screen appear in?
- What is the player's emotional state on arrival at this screen?
- What player need is this screen serving in the journey?
- What critical moments (from the journey map) does this screen deliver?

If the player journey file does not exist, note the gap and proceed:
> "No player journey map found at `design/player-journey.md`. Designing without it
> means we'll be making assumptions about player context. Consider running a player
> journey session after this spec is drafted."

Also add to the UX spec's Open Questions section:
> "Player journey map not yet created. Author it from the template at `.claude/docs/templates/player-journey.md` to establish player context for this screen."

> **Do not tell the user to "run `/ux-design` Phase 2b" to create it.** Phase 2b
> is this step — the one that *reads* the file. That remediation is circular: it
> sends the user back to the check that just reported the gap. No skill
> writes `design/player-journey.md`; it is hand-authored from its template.

### 2c: GDD UI Requirements

Glob `design/gdd/*.md` and grep for `UI Requirements` sections. Read any GDD whose
UI Requirements section references this screen by name or category.

These GDD UI Requirements are the **requirements input** to this spec. Collect them
as a list of constraints the spec must satisfy.

If designing the HUD, you need the UI Requirements of **every** system — the HUD
aggregates them. Collect them with one scan rather than opening each GDD:

```
Grep pattern="^#+ .*UI Requirements" glob="design/gdd/*.md" output_mode="content" -A 20
```

Establish the denominator first (glob `design/gdd/*.md`, count **N**) and check
the match count against it. **A GDD with no UI Requirements section is not a GDD
with no UI needs** — it may predate the section. List the unmatched ones and
confirm with the user that they are genuinely headless before excluding them
from the HUD's requirement set; a HUD that silently omits a system's readout is
the exact failure this aggregation exists to prevent.

### 2d: Existing UX Specs

Glob `design/ux/*.md` and note which screens already have specs. For screens that
will link to or from the current screen, read their navigation/flow sections to
find the entry and exit points this spec must match.

### 2e: Interaction Pattern Library

If `design/ux/interaction-patterns.md` exists, read the pattern catalog index
(the list of pattern names and their one-line descriptions). Do not read full
pattern details — just the catalog. This tells you which patterns already exist
so you can reference them rather than reinvent them.

### 2f: Art Bible

Check for `design/art/art-bible.md`. If found, read the visual direction
section. UX layout must align with the aesthetic commitments already made.

### 2g: Accessibility Requirements

Check for `design/accessibility-requirements.md`. If found, read it. The spec
must satisfy the accessibility tier committed to there.

### 2h: Input Method (from Project Config)

Read the `platform` block from `project.yaml`; if `project.yaml` has no
`platform` block, fall back to the `## Input & Platform` section of
`.claude/docs/technical-preferences.md`. Store these values for use throughout
the skill — they drive the Interaction Map and inform accessibility
requirements:

- **Primary Input** — `platform.primary_input` — the dominant input for this game
- **Gamepad Support** — `platform.gamepad_support` — Full / Partial / None
- **Touch Support** — `platform.touch_support` — Full / Partial / None
- **Target Platforms** — `platform.targets` — for safe zone and aspect ratio decisions
- **Input Methods** — the set of supported methods. When reading from
  `project.yaml`, derive it: keyboard/mouse if `PC` or `Web` is in `targets`;
  gamepad if gamepad support is Full/Partial; touch if touch support is
  Full/Partial; plus the primary input. When falling back to
  `technical-preferences.md`, use its explicit Input Methods field.

If neither source is configured, ask once:
> "Input methods aren't configured yet. What does this game target?"
> Options: "Keyboard/Mouse only", "Gamepad only", "Both (PC + Console)", "Touch (mobile)", "All of the above"
>
> (Run `/setup-engine` to save this permanently so you won't be asked again.)

Store the answer for the rest of this session. Do **not** ask again per section
or per screen.

### 2i: Present Context Summary

Before any design work, present a brief summary to the user:

> **Designing: [Screen/Flow Name]**
> - Mode: [UX Spec / HUD Design / Pattern Library]
> - Journey phase(s): [from player-journey.md, or "unknown — no journey map"]
> - GDD requirements feeding this spec: [count and names, or "none found"]
> - Related screens already specced: [list, or "none yet"]
> - Known patterns available: [count, or "no pattern library yet"]
> - Accessibility tier: [from requirements doc, or "not yet defined"]
> - Input methods: [derived from the `project.yaml` platform block, or "asked above"]

Then ask: "Anything else I should read before we start, or shall we proceed?"

---

## 2b. Retrofit Mode Detection

Before creating a skeleton, check if the target output file already exists.

Glob `design/ux/[filename].md` (where `[filename]` is the resolved output path from Phase 1).

**If the file exists — retrofit mode:**
- Read the file in full
- For each expected section, check whether the body has real content (more than a `[To be designed]` placeholder) or is empty/placeholder
- Present a section status summary to the user:

> "Found existing UX spec at `design/ux/[filename].md`. Here's what's already done:
>
> | Section | Status |
> |---------|--------|
> | Overview & Context | [Complete / Empty / Placeholder] |
> | Player Journey Integration | ... |
> | Screen Layout & Information Architecture | ... |
> | Interaction Model | ... |
> | Feedback & State Communication | ... |
> | Accessibility | ... |
> | Edge Cases & Error States | ... |
> | Open Questions | ... |
>
> I'll work on the [N] incomplete sections only — existing content will not be overwritten."

- Skip Section 3 (skeleton creation) — the file already exists
- In Phase 4 (Section Authoring), only work on sections with Status: Empty or Placeholder
- Use `Edit` to fill placeholders in-place rather than creating a new skeleton

**If the file does not exist — fresh authoring mode:**
Proceed to Phase 3 (Create File Skeleton) as normal.

---

## 3. Create File Skeleton

Once the user confirms, **immediately** create the output file with empty section
headers. This ensures incremental writes have a target and work survives interruptions.

Ask: "May I create the skeleton file at `design/ux/[filename].md`?" — except in
`accessibility` mode, where the path is `design/accessibility-requirements.md`
(see the mode table in Section 1; it is deliberately not under `design/ux/`).

---

### Skeleton for UX Spec (screen or flow)

```markdown
# UX Spec: [Screen/Flow Name]

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Journey Phase(s)**: [from context]
> **Template**: UX Spec

---

## Purpose & Player Need

[To be designed]

---

## Player Context on Arrival

[To be designed]

---

## Navigation Position

[To be designed]

---

## Entry & Exit Points

[To be designed]

---

## Layout Specification

### Information Hierarchy

[To be designed]

### Layout Zones

[To be designed]

### Component Inventory

[To be designed]

### ASCII Wireframe

[To be designed]

---

## States & Variants

[To be designed]

---

## Interaction Map

[To be designed]

---

## Events Fired

[To be designed]

---

## Transitions & Animations

[To be designed]

---

## Data Requirements

[To be designed]

---

## Accessibility

[To be designed]

---

## Localization Considerations

[To be designed]

---

## Acceptance Criteria

[To be designed]

---

## Open Questions

[To be designed]
```

---

### Skeleton for HUD Design

```markdown
# HUD Design

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Template**: HUD Design

---

## HUD Philosophy

[To be designed]

---

## Information Architecture

### Full Information Inventory

[To be designed]

### Categorization

[To be designed]

---

## Layout Zones

[To be designed]

---

## HUD Elements

[To be designed]

---

## Dynamic Behaviors

[To be designed]

---

## Platform & Input Variants

[To be designed]

---

## Accessibility

[To be designed]

---

## Open Questions

[To be designed]
```

---

### Skeleton for Interaction Pattern Library

```markdown
# Interaction Pattern Library

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Template**: Interaction Pattern Library

---

## Overview

[To be designed]

---

## Pattern Catalog

[To be designed]

---

## Patterns

[Individual pattern entries added here as they are defined]

---

## Gaps & Patterns Needed

[To be designed]

---

## Open Questions

[To be designed]
```

---

### Skeleton for Accessibility Requirements

Section list mirrors `.claude/docs/templates/accessibility-requirements.md` — if
the template gains or loses a section, this skeleton follows it, not the reverse.

```markdown
# Accessibility Requirements

> **Status**: In Design
> **Author**: [user + ux-designer]
> **Last Updated**: [today's date]
> **Template**: Accessibility Requirements

## Accessibility Tier Definition

[To be designed]

---

## Visual Accessibility

[To be designed]

---

## Motor Accessibility

[To be designed]

---

## Cognitive Accessibility

[To be designed]

---

## Auditory Accessibility

[To be designed]

---

## Platform Accessibility API Integration

[To be designed]

---

## Per-Feature Accessibility Matrix

[To be designed]

---

## Accessibility Test Plan

[To be designed]

---

## Known Intentional Limitations

[To be designed]

---

## Audit History

[To be designed]

---

## External Resources

[To be designed]

---

## Open Questions

[To be designed]
```

> **The tier commitment is the gated part.** `gate-pre-production.md` requires
> the file to exist *with an accessibility tier committed*, and
> `gate-production.md` checks that tier is addressed in every key screen spec.
> A skeleton whose Tier Definition is still `[To be designed]` satisfies the
> glob but not the gate — author that section first.

---

After writing the skeleton, update `production/session-state/active.md` with:
- Task: Designing [screen/flow name] UX spec
- Current section: Starting (skeleton created)
- File: design/ux/[filename].md (or `design/accessibility-requirements.md` in `accessibility` mode)

---

## 4. Section-by-Section Authoring

Walk through each section in order. For **each section**, follow this cycle:

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

1. **Context**: State what this section needs to contain and surface any relevant
   constraints from context gathered in Phase 2.
2. **Questions**: Ask what is needed to draft this section. Use `AskUserQuestion`
   for constrained choices, conversational text for open-ended exploration.
3. **Options**: Where design choices exist, present 2-4 approaches with pros/cons.
   Explain reasoning in conversation, then use `AskUserQuestion` to capture the decision.
4. **Decision**: User picks an approach or provides custom direction.
5. **Draft**: Write the section content in conversation for review. Flag provisional
   assumptions explicitly.
6. **Approval**: Use `AskUserQuestion`:
   - "Does this capture the [section name] correctly?"
   - Options: "Yes — write it to the file", "Small changes needed (describe below)", "Major rethink needed"
   Do not proceed to step 7 until the user selects "Yes".
7. **Write**: Use `AskUserQuestion`: "May I write the [section name] section to `[filepath]`?"
   - Options: "Yes, write it", "Wait — one more change"
   Once confirmed, use `Edit` to replace the `[To be designed]` placeholder with approved content.

After writing each section, update `production/session-state/active.md`.

---

### Section guidance — read the ONE file for the active mode

Per-section authoring guidance lives in its own file per mode. **When you reach
Phase 4, read only the file matching the mode resolved in Section 1; never load
the other two.**

| Mode | Guidance file |
|------|---------------|
| UX Spec (screen or flow) | `.claude/skills/ux-design/references/sections-ux-spec.md` |
| HUD Design | `.claude/skills/ux-design/references/sections-hud.md` |
| Interaction Pattern Library | `.claude/skills/ux-design/references/sections-patterns.md` |
| Accessibility Requirements | `.claude/docs/templates/guidance/accessibility-requirements-guide.md` |

> The accessibility guidance lives under `templates/guidance/` rather than this
> skill's `references/` because the template it documents
> (`.claude/docs/templates/accessibility-requirements.md`) is consumed by
> `/ux-review` and the gate files too. Same rule applies: load only the part
> covering the section you are authoring, never the whole file.

Apply `docs.density` (Section 1) to whatever that file tells you to author — it
controls the depth of each section, not which sections exist.

---

## 5. Cross-Reference Check

Before marking the spec as ready for review, run these checks:

**1. GDD requirement coverage**: Does every GDD UI Requirement that references
this screen have a corresponding element in this spec? Present any gaps.

**2. Pattern library alignment**: Are all interaction patterns used in this spec
referenced by name? If a new pattern was invented during this spec session, flag
it for addition to the pattern library:
Use `AskUserQuestion`:
- "This spec uses [pattern name], which isn't in the pattern library yet. What should we do?"
- Options: "Add it to the pattern library now", "Flag it as a gap and continue", "Skip — this pattern is one-off"

**3. Navigation consistency**: Do the entry/exit points in this spec match the
navigation map in any related specs? Flag mismatches.

**4. Accessibility coverage**: Does the spec address the accessibility tier
committed to in `design/accessibility-requirements.md`? If not, flag open questions.

**5. Empty states**: Does every data-dependent element have an empty state defined?
Flag any that don't.

Present the check results:
> **Cross-Reference Check: [Screen Name]**
> - GDD requirements: [N of M covered / all covered]
> - New patterns to add to library: [list or "none"]
> - Navigation mismatches: [list or "none"]
> - Accessibility gaps: [list or "none"]
> - Missing empty states: [list or "none"]

---

## 6. Handoff

When all sections are approved and written:

### 6a: Update Session State

Update `production/session-state/active.md` with:
- Task: [screen-name] UX spec
- Status: Complete (or In Review)
- File: design/ux/[filename].md
- Sections: All written
- Next: [suggestion]

### 6b: Suggest Next Step

Before presenting options, state clearly:

> "This spec should be validated with `/ux-review` before it enters the
> implementation pipeline. The Pre-Production gate requires all key screen specs
> to have a review verdict."

Then use `AskUserQuestion`:
- "Run `/ux-review [filename]` now, or do something else first?"
  - Options:
    - "Run `/ux-review` now — validate this spec"
    - "Design another screen first, then review all specs together"
    - "Update the interaction pattern library with new patterns from this spec"
    - "Stop here for this session"

If the user picks "Design another screen first", add a note: "Reminder: run
`/ux-review` on all completed specs before running `/gate-check pre-production`."

### 6c: Cross-Link Related Specs

If other UX specs link to or from this screen, note which ones should reference
this spec. Do not edit those files without asking — just name them.

---

## 7. Recovery & Resume

If the session is interrupted (compaction, crash, new session):

1. Read `production/session-state/active.md` — it records the current screen
   and which sections are complete.
2. Read `design/ux/[filename].md` — sections with real content are done;
   sections with `[To be designed]` still need work.
3. Resume from the next incomplete section — no need to re-discuss completed ones.

This is why incremental writing matters: every approved section survives any
disruption.

---

## 8. Specialist Agent Routing

This skill uses `ux-designer` as the primary agent (set in frontmatter). For
specific sub-topics, additional context or coordination may be needed:

| Topic | Coordinate with |
|-------|----------------|
| Visual aesthetics, color, layout feel | `art-director` — UX spec defines zones; art defines how they look |
| Implementation feasibility (engine constraints) | `ui-programmer` — before finalizing component inventory |
| Gameplay data requirements | `game-designer` — when data ownership is unclear |
| Narrative/lore visible in the UI | `narrative-director` — for flavor text, item names, lore panels |
| Accessibility tier decisions | Handled by this session — owned by ux-designer |

When delegating to another agent via the `Agent` tool:
- Provide: screen name, game concept summary, the specific question needing expert input
- The agent returns analysis to this session
- This session presents the agent's output to the user
- The user decides; this session writes to file
- Agents do NOT write to files directly — this session owns all file writes

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see the per-mode rules in `.claude/docs/automation-modes.md` — the steps below
describe what collaborative mode requires, not what applies universally.

This skill follows the collaborative design principle at every step:

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?"
   - Phase 4 (each section): design questions, approach options, draft approval
   - Phase 5: "Run cross-reference check? What's next?"
3. **"May I write to [filepath]?"** before the skeleton and before each section write
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write

**Aesthetic deference**: When layout or visual choices come down to personal taste,
present the options and ask. Do not select a layout because it is "standard" — always
confirm. The user is the creative director.

**Conflict surfacing**: When a GDD requirement and the available screen real estate
conflict, surface the conflict and present resolution options. Never silently drop
a requirement. Never silently expand the layout without flagging it.

**Never** auto-generate the full spec and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved UX spec without flagging the conflict.
**Always** show where decisions come from (GDD requirements, player journey, user choices).

Verdict: **COMPLETE** — UX spec written and approved section by section.

---

## Recommended Next Steps

- Run `/ux-review [filename]` to validate this spec before it enters the implementation pipeline
- Run `/ux-design [next-screen]` to continue designing remaining screens or flows
- Run `/gate-check pre-production` once all key screens have approved UX specs
