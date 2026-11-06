---
name: start
description: "First-time onboarding — asks where you are, then guides you to the right workflow. No assumptions."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion
model: sonnet
---

# Guided Onboarding

This skill writes one file: `production/review-mode.txt` (review mode config set in Phase 3b).

This skill is the entry point for new users. It does NOT assume you have a feature spec, an engine preference, or any prior experience. The engine is pinned to **Unreal Engine 5.8** and the knowledge source is **Context7 MCP** — these are fixed. The skill asks where you are in the requirements → implementation pipeline, then routes you.

---

## Phase 1: Detect Project State

Before asking anything, silently gather context so you can tailor your guidance. Do NOT show these results unprompted — they inform your recommendations, not the conversation opener.

Check:
- **Engine configured?** Read `.claude/docs/technical-preferences.md`. If the Engine field contains `[TO BE CONFIGURED]`, the engine is not set. (It should read `Unreal Engine 5.8`.)
- **Requirements exist?** Check for `docs/architecture/tr-registry.yaml` (indexes user-provided feature specs) and any feature spec files referenced by it.
- **Source code exists?** Glob for source files in `Source/` and `src/` (`*.cpp`, `*.h`, `*.cs`).
- **Architecture docs exist?** Count files in `docs/architecture/` (`adr-*.md`, `architecture.md`, `control-manifest.md`).
- **Production artifacts?** Check for files in `production/epics/` or `production/sprints/`.

Store these findings internally to validate the user's self-assessment and tailor recommendations.

---

## Phase 2: Ask Where the User Is

This is the first thing the user sees. Use `AskUserQuestion` with these exact options so the user can click rather than type:

- **Prompt**: "Welcome to the UE 5.8 technical implementation team! Before I suggest anything, I'd like to understand where you're starting from. Do you have existing requirements / feature spec?"
- **Options**:
  - `A) No requirements yet` — I don't have a feature spec. I need to define what to build before any technical work.
  - `B) Have feature spec` — I have a requirements / feature spec document (or several). Ready to start technical setup.
  - `C) Architecture done` — I already have ADRs + architecture doc + control manifest. Ready to break requirements into epics/stories.
  - `D) Existing work` — I already have code, ADRs, and/or stories done. I want to organize or continue the work.

Wait for the user's selection. Do not proceed until they respond.

---

## Phase 3: Route Based on Answer

The pipeline is 3 stages: **Technical Setup → Requirements Breakdown → Implementation**.

#### If A: No requirements yet

The user needs to author a feature spec before technical work begins. This team does not generate requirements — requirements come from the user.

1. Acknowledge that starting from a feature spec is the required entry point
2. Explain: "Write a feature spec describing what to build (scope, acceptance criteria, target platform notes). Place it under `docs/requirements/` or wherever you keep specs. Once you have at least one, run `/setup-engine` to configure the technical contract, then `/architecture-decision` to record key decisions."
3. Show the recommended path:
   **Technical Setup phase:**
   - Author a feature spec (`docs/requirements/[feature].md`)
   - `/setup-engine` — configure the UE 5.8 technical contract (platforms, naming, performance budget, test framework, UE sub-specialist routing)
   - `/architecture-decision (×N)` — record Foundation-layer decisions (≥3)
   - `/create-architecture` — master architecture blueprint
   - `/create-control-manifest` — flatten ADRs into programmer rules
   - `/architecture-review` — validate coverage + engine compatibility (via Context7)
   **Requirements Breakdown phase:**
   - `/create-epics` — map architecture modules to epics
   - `/create-stories` — break epics into implementable stories
   **Implementation phase:** → pick up stories with `/dev-story`

#### If B: Have feature spec

1. Ask them to confirm where the feature spec(s) live (path). If they haven't yet, suggest placing them under `docs/requirements/` and registering them in `docs/architecture/tr-registry.yaml`.
2. Show the recommended path:
   **Technical Setup phase:**
   - `/setup-engine` — configure the UE 5.8 technical contract
   - `/architecture-decision (×N)` — record Foundation-layer decisions (≥3)
   - `/create-architecture` — master architecture blueprint
   - `/create-control-manifest` — flatten ADRs into programmer rules
   - `/architecture-review` — validate coverage + engine compatibility (via Context7)
   **Requirements Breakdown phase:**
   - `/create-epics` — map architecture modules to epics
   - `/create-stories` — break epics into implementable stories
   **Implementation phase:** → pick up stories with `/dev-story`

#### If C: Architecture done

1. Acknowledge that technical setup is behind them.
2. Show the recommended path:
   **Requirements Breakdown phase:**
   - `/create-epics` — map architecture modules to epics
   - `/create-stories` — break epics into implementable stories
   **Implementation phase:**
   - `/story-readiness [path]` — validate a story before starting
   - `/dev-story [path]` — implement it (core)
   - `/code-review [files]` — review it
   - `/story-done [path]` — verify and close it
   - `/team-feature [description]` — complex multi-agent features
   - `/gate-check [stage]` — phase transition gate (TD only)

#### If D: Existing work

1. Share what you found in Phase 1:
   - "I can see you have [X source files / Y ADRs / Z stories]..."
   - "Your engine is [configured as Unreal Engine 5.8 / not yet configured]..."

2. **Sub-case D1 — Early stage** (engine not configured or no architecture docs):
   - Recommend `/setup-engine` first if engine not configured
   - Then `/project-stage-detect` for a gap inventory

   **Sub-case D2 — ADRs, architecture, or stories already exist:**
   - Explain: "Having files isn't the same as the template's skills being able to use them. ADRs might be missing required sections. `/adopt` checks this specifically."
   - Recommend:
     1. `/project-stage-detect` — understand what phase and what's missing entirely
     2. `/adopt` — audit whether existing artifacts are in the right internal format

3. Show the recommended path for D2:
   - `/project-stage-detect` — phase detection + existence gaps
   - `/adopt` — format compliance audit + migration plan
   - `/setup-engine` — if engine not configured
   - `/architecture-decision retrofit [path]` — add missing ADR sections
   - `/architecture-review` — validate coverage and engine compatibility
   - `/gate-check` — validate readiness for next phase

---

## Phase 3c: Write Initial Stage File

After confirming the starting path (and before asking about review mode), write the initial stage to `production/stage.txt`. Create the `production/` directory if it does not exist.

Stage mapping (3 stages):
- **Path A or B (starting from scratch)**: write `Technical Setup`
- **Path C (architecture already done)**: write `Requirements Breakdown`
- **Path D, existing project, engine not configured or no architecture docs**: write `Technical Setup`
- **Path D, existing project with architecture docs but no epics**: write `Requirements Breakdown`
- **Path D, existing project with epics/stories already**: write `Implementation`

Do this silently — no "May I write?" needed for this single-line file.

Say: "I've set `production/stage.txt` to `[stage]` — this anchors your status line and stage detection."

---

## Phase 3b: Set Review Mode

Check if `production/review-mode.txt` already exists.

**If it exists**: Read it and show the current mode — "Review mode is set to `[current]`." — then proceed to Phase 4. Do not ask again.

**If it does not exist**: Use `AskUserQuestion`:

- **Prompt**: "One setup choice: how much technical review would you want as you work through the workflow?"
- **Options**:
  - `Full` — Technical director reviews at each key workflow step. Best for teams, learning the workflow, or when you want thorough feedback on every decision.
  - `Lean (recommended)` — Technical director only at phase gate transitions (/gate-check). Skips per-skill reviews. Balanced approach for solo devs and small teams.
  - `Solo` — No director reviews at all. Maximum speed. Best for prototypes or if the reviews feel like overhead.

Write the choice to `production/review-mode.txt` immediately after the user
selects — no separate "May I write?" needed, as the write is a direct
consequence of the selection:
- `Full` → write `full`
- `Lean (recommended)` → write `lean`
- `Solo` → write `solo`

Create the `production/` directory if it does not exist.

---

## Phase 4: Confirm Before Proceeding

After presenting the recommended path, use `AskUserQuestion` to ask the user which step they'd like to take first. Never auto-run the next skill.

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
- **User picks A but project has code**: Mention what you found — "I noticed there's already code in `Source/`. Did you mean to pick D (existing work)?"
- **User is returning (engine configured, architecture exists)**: Skip onboarding entirely — "It looks like you're already set up! Your engine is Unreal Engine 5.8 and you have architecture docs at `docs/architecture/`. Review mode: `[read from production/review-mode.txt, or 'lean (default)' if missing]`. Want to pick up where you left off? Try `/help` or just tell me what you'd like to work on."
- **User doesn't fit any option**: Let them describe their situation in their own words and adapt.

---

## Collaborative Protocol

1. **Ask first** — never assume the user's state or intent
2. **Present options** — give clear paths, not mandates
3. **User decides** — they pick the direction
4. **No auto-execution** — recommend the next skill, don't run it without asking
5. **Adapt** — if the user's situation doesn't fit a template, listen and adjust
