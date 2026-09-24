---
name: start
description: "First-time onboarding — asks where you are, then guides you to the right workflow."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion
model: sonnet
---

# Guided Onboarding

This skill writes `project.yaml` — the `project.stage`, `modes.rigor` and
`modes.automation` settings — plus one legacy mirror, `production/stage.txt`,
for backward compatibility with hooks that have not migrated. `modes.rigor` and
`modes.automation` have no legacy mirror; they are written to `project.yaml`
only.

> **`/start` never writes `modes.review_mode`, in either location.** It is a
> rigor-fronted knob: writing it explicitly pins it and shadows the `modes.rigor`
> expansion, so the Phase 3d question would stop changing director-review depth
> (see Phase 3d, and the same rule in `project.yaml`'s header comment). It must
> **not** write `production/review-mode.txt` either — the legacy step sits
> **above** the rigor expansion in the resolution chain, deliberately, so a genuine
> v1.0 project's explicit choice survives migration. On a new project that
> ordering works against you: a mirror file written here would outrank the
> expansion permanently. Verified: `rigor: minimal` plus a `review-mode.txt`
> containing `lean` resolves to `lean`, not the expected `solo`.

This skill is the entry point for new users. It does NOT assume you have a game idea, an engine preference, or any prior experience. It asks first, then routes you to the right workflow.

---

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). **Note**: on a fresh project no
`modes.automation` is set yet, so `/start` runs collaboratively — it is
creating the config. Its core onboarding questions (starting point, rigor,
automation) are project-shaping and always prompt regardless
of mode. Engine choice is **not** among them — it is deferred to
`/setup-engine`, which Phase 4 hands off to.
If `/start` is re-run on an already-configured project, the resolved mode
applies per `.claude/docs/automation-modes.md`.

## Phase 1: Detect Project State

Before asking anything, silently gather context so you can tailor your guidance. Do NOT show these results unprompted — they inform your recommendations, not the conversation opener.

Check:
- **Engine configured?** Read `engine.name` from `project.yaml`; if that key is absent or empty (including when `project.yaml` has no `engine:` block), fall back to `.claude/docs/technical-preferences.md` (an Engine field of `[TO BE CONFIGURED]`, or no file, means not set). The engine is configured if either source yields a real engine name.
- **Game concept exists?** Check for `design/gdd/game-concept.md` (or `design/game-brief.md` at the `minimal` tier).
- **Source code exists?** Resolve the code root from the `engine.name` read above (`src/` Godot, `Assets/` Unity, `Source/` Unreal; full order in `.claude/docs/code-root-resolution.md`), then Glob it for source files (`*.gd`, `*.cs`, `*.cpp`, `*.h`, `*.rs`, `*.py`, `*.js`, `*.ts`). **If the code root is unresolved, say so rather than concluding there is no code** — a Unity or Unreal project scanned as `src/` returns zero files and reads as greenfield.
- **Prototypes exist?** Check for subdirectories in `prototypes/`.
- **Design docs exist?** Count markdown files in `design/gdd/`.
- **Production artifacts?** Check for files in `production/sprints/` or `production/milestones/`.

Store these findings internally to validate the user's self-assessment and tailor recommendations.

---

## Phase 2: Ask Where the User Is

This is the first thing the user sees. Use `AskUserQuestion` with these exact options so the user can click rather than type:

- **Prompt**: "Welcome to Claude Code Game Studios! Before I suggest anything, I'd like to understand where you're starting from. Where are you at with your game idea right now?"
- **Options**:
  - `A) No idea yet` — I don't have a game concept at all. I want to explore and figure out what to make.
  - `B) Vague idea` — I have a rough theme, feeling, or genre in mind (e.g., "something with space" or "a cozy farming game") but nothing concrete.
  - `C) Clear concept` — I know the core idea — genre, basic mechanics, maybe a pitch sentence — but haven't formalized it into documents yet.
  - `D) Existing work` — I already have design docs, prototypes, code, or significant planning done. I want to organize or continue the work.

Wait for the user's selection. Do not proceed until they respond.

---

## Phase 3: Route Based on Answer

#### If A: No idea yet

The user needs creative exploration before anything else.

1. Acknowledge that starting from zero is completely fine
2. Briefly explain what `/brainstorm` does: it turns "no idea" into a written design your next step can build from. Mention that it has two modes: `/brainstorm open` for fully open exploration, or `/brainstorm [hint]` if they have even a vague theme (e.g., "space", "cozy", "horror").

   > **Describe it tier-neutrally here.** Phase 3d has not run, so you do not yet
   > know how much process this project wants — and `/brainstorm` changes shape
   > completely on that answer. At `minimal` it runs a short Lean Brief flow and
   > stops, producing a one-page `design/game-brief.md`; at `standard`/`full` it
   > runs the full ideation walk (MDA, player psychology, verb-first design) and
   > produces the concept document. Naming the full walk here, then having Phase 4
   > describe the same skill as "produce the one-page brief", gives the user two
   > contradicting accounts of one skill inside a single `/start` run. Phase 4 is
   > where the tier-specific description belongs.
3. Recommend running `/brainstorm open` as the next step, but invite them to use a hint if something comes to mind
4. Name the **immediate next step only** — `/brainstorm open`. Do not list the
   full pipeline here. Phase 3d has not yet asked how much process the user
   wants, and that answer changes the path substantially. Say: "I'll lay out the
   full path once I know how much process you want — two quick questions away."

#### If B: Vague idea

1. Ask them to share their vague idea — even a few words is enough
2. Validate the idea as a starting point (don't judge or redirect)
3. Recommend running `/brainstorm [their hint]` to develop it
4. Name the **immediate next step only** — `/brainstorm [their hint]`. Do not
   list the full pipeline here; Phase 3d has not yet asked how much process the
   user wants, and that answer changes the path. Say: "I'll lay out the full
   path once I know how much process you want — two quick questions away."

#### If C: Clear concept

1. Ask them to describe their concept in one sentence — genre and core mechanic. Use plain text, not AskUserQuestion (it's an open response).
2. Acknowledge the concept, then use `AskUserQuestion` to offer two paths:
   - **Prompt**: "How would you like to proceed?"
   - **Options**:
     - `Formalize it first` — Run `/brainstorm [concept]` to structure it into a proper game concept document
     - `Jump straight in` — Go to `/setup-engine` now and write the GDD manually afterward
3. Name the **immediate next step only** — their pick from step 2. Do not list
   the full pipeline here; Phase 3d has not yet asked how much process the user
   wants, and that answer changes the path. Say: "I'll lay out the full path
   once I know how much process you want — two quick questions away."

#### If D: Existing work

1. Share what you found in Phase 1:
   - "I can see you have [X source files / Y design docs / Z prototypes]..."
   - "Your engine is [configured as X / not yet configured]..."

2. **Sub-case D1 — Early stage** (engine not configured or only a game concept exists):
   - Recommend `/setup-engine` first if engine not configured
   - Then `/project-stage-detect` for a gap inventory

   **Sub-case D2 — GDDs, ADRs, or stories already exist:**
   - Explain: "Having files isn't the same as the template's skills being able to use them. GDDs might be missing required sections. `/adopt` checks this specifically."
   - Recommend:
     1. `/project-stage-detect` — understand what phase and what's missing entirely
     2. `/adopt` — audit whether existing artifacts are in the right internal format

3. Show the recommended path for D2:
   - `/project-stage-detect` — phase detection + existence gaps
   - `/adopt` — format compliance audit + migration plan
   - `/setup-engine` — if engine not configured
   - `/design-system retrofit [path]` — fill missing GDD sections
   - `/architecture-decision retrofit [path]` — add missing ADR sections
   - `/architecture-review` — bootstrap the TR requirement registry
   - `/gate-check` — validate readiness for next phase

---

## Phase 3c: Write Initial Stage

After confirming the starting path, write the initial stage to BOTH `project.yaml` (primary) AND `production/stage.txt` (legacy fallback for hooks that haven't migrated yet). Create the `production/` directory if it does not exist.

In `project.yaml`, ensure a `project:` block exists with `stage: [value]`.
- **If `project.yaml` already exists**: Read it first (the Edit tool requires the
  file to have been read in this session), then use the Edit tool to add/update
  the `project:` block, placing it immediately after the `framework:` block.
- **If `project.yaml` does not exist** at the repo root: create it with the Write
  tool using this v1.1 minimal template (replace `[value]` and the date):
  ```yaml
  # CCGS project configuration — single source of truth for project settings.
  # Schema: grep the `## <key>` section of .claude/docs/effects-map.md —
  # it is ~31k tokens whole, ~900 per section. Do not open it entire.

  schema_version: 1

  framework:
    version: 1.1.1
    last_upgraded: <YYYY-MM-DD>

  project:
    stage: [value]
  ```
  **Do not seed `modes.review_mode` here.** It is a rigor-fronted knob —
  `modes.rigor` supplies its value, so an explicit value here would shadow the
  rigor expansion and pin the review mode regardless of the rigor the user picks
  in Phase 3d. `modes.rigor` itself is omitted for a related reason: Phase 3d skips
  its question when the key is already set, so seeding it would suppress that
  question. Tests Y.3 and Y.6 lock both in.

Then also write the same single-line stage name to `production/stage.txt` (no trailing newline) so legacy tooling still works.

Stage mapping:
- **Path A, B, or C (starting from scratch)**: write `Concept`
- **Path D, existing project, engine not configured or only a game concept exists**: write `Concept`
- **Path D, existing project with GDDs but no architecture documents**: write `Systems Design`
- **Path D, existing project with full architecture (ADRs, architecture doc)**: write `Technical Setup`

Do this silently — no "May I write?" needed for these stage anchors.

Say: "I've set `project.stage` to `[stage]` (and updated `production/stage.txt`) — this anchors your status line and stage detection."

---

## Phase 3d: Set Rigor

Check whether `modes.rigor` is already set in `project.yaml`. **If it is**, show
it — "Rigor is set to `[current]`." — and proceed to **Phase 3e**. Do not ask
again. Either way, **carry the resolved value forward** — Phase 4 branches its
recommended path on it.

**If it is not set**: first pick a recommendation, then ask.

**Seed the recommendation** from what the user described in Phase 2, using the
archetype presets in `.claude/docs/settings-guidance.md § 2–3`:
- Map their concept to an archetype (e.g. "open-world RPG with crafting and
  factions" → systems-heavy → `full`; "a small weekend puzzler" → `minimal`).
- If the user has **no concept at all** (Path A, or a Path B hint with nothing in
  §3's signal table), recommend the jam/prototype option (`minimal`) and add:
  "You can raise this after `/brainstorm` once the concept is clearer —
  `/settings` changes it anytime."
- **A Path B hint still counts as a description.** "Still exploring" is about
  having no signal, not about which path the user picked. If the vague idea trips
  §3's signals — "some kind of open-world survival sim" hits open-world, sim and
  survival — seed from the signal, not from the path, and say why in the user's
  own terms. Recommending `minimal` for a described systems-heavy game is the
  mismatch Phase 4 would then have to flag, caused here.
- If nothing in the description points either way, recommend the middle option
  (`standard`, the documented default).

Then use `AskUserQuestion`. Order the options so the **recommended** archetype is
first and append ` (Recommended)` to its label (per the AskUserQuestion
convention); the other two follow in any order.

- **Prompt**: "What best describes what you're building? This sets how much process
  the project carries — you can change it anytime with `/settings`."
- **Options** (base labels — the recommended one also gets ` (Recommended)`):
  - `Jam / prototype / first game` — Short docs, coarse stories, evidence optional. **~4 steps to your first line of code instead of ~18.** Shipping beats recording; design lives in your head. The trade: no GDDs, so design problems surface in code rather than before it.
  - `Several systems that affect each other` — Balanced docs, normal story size, standard QA evidence. **Expect ~8 design documents and roughly an hour of design work before your first line of code.** Worth paying when systems interact and a design mistake is expensive to unpick once it is in code. **Intending to finish is not the test** — most small games ship faster on the jam path and can move up later with `/settings`.
  - `Big systems-heavy or team project` — Thorough docs, fine-grained stories, evidence required everywhere. Many interacting systems (open-world, sim, RPG), a firm release date, or shared ownership.

Value mapping (ignore any ` (Recommended)` suffix on the first option):
`Jam / prototype / first game` → `minimal`, `Several systems that affect each other` → `standard`,
`Big systems-heavy or team project` → `full`.

Write `modes.rigor` to `project.yaml` immediately after the user selects — no
separate "May I write?" needed, as the write is a direct consequence of the
selection. Use the Edit tool to add it under the `modes:` block. There is **no
legacy mirror file** for this setting, so this is a single write, not a dual-write.

Then say: "Set `modes.rigor` to `[choice]`. That drives six settings —
`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode` (director-review depth), and `team.size` (how many agents are
active on team tasks) — a lighter rigor means fewer reviews, a smaller active
team, and fewer tokens. Run `/settings` to see the exact value each one takes, or
set any of them explicitly to override just that one."

**Why this is asked here.** These six knobs each change what skills produce, and
before `rigor` existed `/start` never asked about any of them — so every project
silently ran at defaults the user had never seen. Asking once, at onboarding, is
the only point where the answer is cheap; skipping this question puts the project
back where it was.

---

## Phase 3e: Set Automation Mode

Check whether `modes.automation` is already set in `project.yaml`. **If it is**,
show it — "Automation is set to `[current]`." — and proceed to Phase 4. Do not
ask again.

**If it is not set**: Use `AskUserQuestion`:

- **Prompt**: "Last one: how much should I confirm with you as we work?"
- **Options**:
  - `Collaborative` — I ask before each significant step and show drafts before writing. Most control; best while you are learning the workflow and want to see everything.
  - `Guided (recommended)` — I decide the small stuff and proceed, but still stop for the big calls (scope changes, file deletions, schema changes). Far fewer interruptions than collaborative, without giving up control of the decisions that matter.
  - `Autonomous` — I proceed and log decisions rather than asking, except for the always-ask categories. Fastest to run, but it makes every call itself and costs more tokens; best for trusted, well-scoped runs.

Value mapping: `Collaborative` → `collaborative`, `Guided (recommended)` →
`guided`, `Autonomous` → `autonomous`.

Write `modes.automation` to `project.yaml` immediately after the user selects —
no separate "May I write?" needed, as the write is a direct consequence of the
selection. Use the Edit tool to add it under the `modes:` block. There is **no
legacy mirror file** for this setting.

Then say: "Set `modes.automation` to `[choice]`. See
`.claude/docs/automation-modes.md` for exactly what each mode asks vs. proceeds
on. `guided` and `autonomous` still always stop for the `automation_always_ask`
categories (scope changes, file deletions, schema changes)."

**Why this is asked here.** `modes.automation` controls how often every skill
stops to confirm. A project that wants to move fast should not have to discover
the knob after fifty approval prompts — that is the frustration this setting
answers. Asked once, at onboarding, like the others. Do **not** seed
`modes.automation` into the Phase 3c template: Phase 3e skips when the key is
already set, so seeding it would suppress its own question (the collision Y.3
and Y.6 guard for the other knobs).

---

## Phase 4: Show the Path, Then Confirm

**Now** present the recommended path — after Phase 3d, so it can match the rigor
the user actually chose. Print **one** of the three below, using the `modes.rigor`
value resolved or written in Phase 3d; if it is somehow still unset, use
`standard` (its documented default) rather than skipping the path. (Paths A/B/C
only; path D users are retrofitting an existing project and were given their
path in Phase 3.)

Say first: "Here's your path at `rigor: [chosen]`. Every skill still runs at any
level — rigor changes what's *required*, not what's allowed. So at `minimal` you can
still call `/art-bible`, `/ux-design`, `/qa-plan` or anything else the moment you want
it — nothing is locked, it simply is not demanded up front. And if one system alone
deserves more care, raise just that one with
`workflow_overrides.system_overrides.<system>` rather than the whole project."

**If `minimal` — 4 steps to running code:**
- `/setup-engine` — configure the engine
- `/brainstorm` — produce the one-page `design/game-brief.md` (the lean-tier design artifact; it replaces the full concept doc, systems decomposition, and per-system GDDs)
- `/create-stories` — turn the brief's MVP list into implementable stories (the epic is implicit — no separate `/create-epics` or `/sprint-plan`; the brief's build order is the plan)
- `/dev-story` — **first line of game code**

**If `standard` (default) — the full pipeline:**
- **Concept:** `/setup-engine` → `/brainstorm` → `/prototype` → `/art-bible` → `/map-systems` → `/design-system` (×N systems) → `/review-all-gdds` → `/gate-check`
- **Architecture:** `/create-architecture` → `/architecture-decision` (×N) → `/create-control-manifest` → `/architecture-review`
- **Pre-Production:** `/ux-design` → `/create-epics` → `/create-stories` → `/sprint-plan`
- **Production:** `/dev-story`

**If `full` — the full pipeline plus validation builds:**
- Everything in `standard`, plus `/vertical-slice` and `/playtest-report` (×1+)
  in Pre-Production, and `/design-review` after each GDD.

> **Do not present the minimal path as lesser.** It is the tier's documented
> floor (`.claude/docs/workflow-modes.md` — "engine choice and a filled
> `design/game-brief.md` are required before code starts … everything else can
> be skipped"), not a degraded mode. Equally, do not oversell it: at `minimal`
> there are no GDDs to catch design problems before they reach code, which is
> the trade being made.

If the user picked a rigor that contradicts what they described in Phase 2 —
overriding the seeded recommendation, e.g. choosing `minimal` after describing a
multi-year commercial project, or `full` for a weekend jam — apply the "mismatch"
trigger in `.claude/docs/settings-guidance.md § 4`: say so once, in one sentence,
and offer `/settings` to change it. Do not re-ask.

Then use `AskUserQuestion` to ask which step they'd like to take first. Never auto-run the next skill.

- **Prompt**: "Would you like to start with [recommended first step]?"
- **Options**:
  - `Yes, let's start with [recommended first step]`
  - `I'd like to do something else first`

---

## Phase 5: Hand Off

When the user confirms their next step, respond with a single short line: "Type `[skill command]` to begin." Nothing else. Do not re-explain the skill or add encouragement. The `/start` skill's job is done.

Verdict: **COMPLETE** — user oriented and handed off to next step.

---

## Edge Cases

- **User picks D but project is empty**: Gently redirect — "It looks like the project is a fresh template with no artifacts yet. Would Path A or B be a better fit?"
- **User picks A but project has code**: Mention what you found — "I noticed there's already code in `[code root]`. Did you mean to pick D (existing work)?"
- **User is returning (engine configured, concept exists)**: Skip onboarding entirely — "It looks like you're already set up! Your engine is [X] and you have a game concept at `design/gdd/game-concept.md` (or a game brief at `design/game-brief.md`). Review mode: `[resolve modes.review_mode — an explicit value if set, otherwise it follows modes.rigor: minimal→solo, standard→lean, full→full]`. Want to pick up where you left off? Try `/sprint-plan` or just tell me what you'd like to work on."
- **User doesn't fit any option**: Let them describe their situation in their own words and adapt.

---

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Ask first** — never assume the user's state or intent
2. **Present options** — give clear paths, not mandates
3. **User decides** — they pick the direction
4. **No auto-execution** — recommend the next skill, don't run it without asking
5. **Adapt** — if the user's situation doesn't fit a template, listen and adjust
