# /ux-design — Sections 2 and 2b: Gather Context and Retrofit Detection

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 2. Gather Context (Read Phase)

**In this file:**

- 2a: Required Reads
- 2b: Player Journey
- 2c: GDD UI Requirements
- 2d: Existing UX Specs
- 2e: Interaction Pattern Library
- 2f: Art Bible
- 2g: Accessibility Requirements
- 2h: Input Method (from Project Config)
- 2i: Present Context Summary

Read all relevant context **before** asking the user anything. The skill's value
comes from arriving informed.

### 2a: Required Reads

- **Game concept**: Read `design/gdd/game-concept.md` — or `design/game-brief.md`,
  the one-page brief that replaces it at `rigor: minimal` — if neither exists, warn:
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
the match count against it. Count system GDDs only: `game-concept.md`,
`systems-index.md`, `game-pillars.md`, `gameplay-tags.md`, `entity-registry.md`,
`fixture-swap-ledger.md`, `sound-bible.md` and any `gdd-cross-review-*.md` live
there too, but they are not systems and have no UI to aggregate.
**A GDD with no UI Requirements section is not a GDD
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

Glob the resolved output path from Phase 1 — `design/ux/[filename].md`, or
`design/accessibility-requirements.md` in `accessibility` mode.

**If the file exists — retrofit mode:**
- Read the file in full
- For each expected section, check whether the body has real content (more than a `[To be designed]` placeholder) or is empty/placeholder
- Present a section status summary to the user:

> "Found existing UX spec at `design/ux/[filename].md`. Here's what's already done:
>
> | Section | Status |
> |---------|--------|
> | Purpose & Player Need | [Complete / Empty / Placeholder] |
> | Player Context on Arrival | ... |
> | Navigation Position | ... |
> | Entry & Exit Points | ... |
> | Layout Specification | ... |
> | States & Variants | ... |
> | Interaction Map | ... |
> | Data Requirements | ... |
> | Events Fired | ... |
> | Transitions & Animations | ... |
> | Input Method Completeness Checklist | ... |
> | Accessibility | ... |
> | Localization Considerations | ... |
> | Acceptance Criteria | ... |
> | Open Questions | ... |
>
> (Rows are the skeleton's own `##` headings for the active mode — the list above is
> UX spec mode; HUD and accessibility modes list their skeleton's headings.)
>
> I'll work on the [N] incomplete sections only — existing content will not be overwritten."

- Skip Section 3 (skeleton creation) — the file already exists
- In Phase 4 (Section Authoring), only work on sections with Status: Empty or Placeholder
- Use `Edit` to fill placeholders in-place rather than creating a new skeleton

**If the file does not exist — fresh authoring mode:**
Proceed to Phase 3 (Create File Skeleton) as normal.

---
