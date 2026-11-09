# Your Path

Here's your path at rigor `[value]`. Every skill still runs at any rigor; rigor changes
what's required, not what's allowed.

**`minimal`: 4 steps to running code**
1. `/setup-engine`: choose and configure the engine (web, unless you name another)
2. `/brainstorm`: write the one-page `design/game-brief.md`
3. `/create-stories`: turn the brief's Features list into stories (no epics or sprint plan needed)
4. `/dev-story`: the first line of game code

With no engine set, `/prototype` builds the brief as a playable browser game: list it
straight after `/brainstorm`, as the recommended next step, and `/setup-engine` after it.

**`standard`** (studio mode)
- Concept: `/setup-engine` → `/brainstorm` → `/prototype` → `/art-bible` → `/map-systems` →
  `/gate-check`. With no engine set, `/setup-engine` moves after `/prototype`: the playable
  first, the engine last
- Systems Design: `/design-system` (once per system) → `/review-all-gdds` → `/gate-check`
- Architecture: `/create-architecture` → `/architecture-decision` (once per decision) →
  `/architecture-review` → `/create-control-manifest` → `/ux-design` (accessibility and
  interaction patterns) → `/test-setup` → `/gate-check`
- Pre-Production: `/ux-design` (HUD and key screens) → `/create-epics` → `/create-stories` →
  `/sprint-plan` → `/gate-check`
- Production: `/dev-story`

Each `/gate-check` moves the project one stage, and only when it passes.

**`full`** (studio mode): everything in `standard`, plus `/vertical-slice` and `/playtest-report`
in Pre-Production and `/design-review` after each GDD.

**Path D with existing work** (stage `Systems Design` or later, or code on disk) gets this instead.
Print only the steps that apply, and for the brief only the one source that applies. When Phase 3
named `/prototype` from their design documents, list it first, before the numbered steps; with an
engine other than `web`, add `/prototype --path html` after step 1 as the fast option. At
`minimal`:
1. `/project-stage-detect`: what stage the project is at and what is missing
2. `/adopt`: whether the existing files are in the format the skills read
3. `/setup-engine`: only when no engine is set; leave it out when `engine` names one
4. The brief, only if `concept` is absent: `/reverse-document design [code_root]` when the code
   root holds 10 or more source files (it writes the brief from the game), and then do not mention
   `/brainstorm` at all; `/brainstorm` only when it holds fewer

At `standard` and `full`, steps 1 to 3, then `/design-system retrofit [path]`,
`/architecture-decision retrofit [path]`, `/architecture-review` and `/gate-check`.

`minimal` is the documented floor, not a lesser mode. Its trade: no GDDs, so design
problems show up in code.
