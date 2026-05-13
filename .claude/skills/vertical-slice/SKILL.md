---
name: vertical-slice
description: "Pre-Production validation — build a production-quality end-to-end build to confirm the full game loop is achievable before committing to Production. Run after GDDs, architecture, and UX specs are complete. Produces a PROCEED/PIVOT/KILL verdict that gates the Pre-Production → Production transition."
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
model: sonnet
agent: prototyper
isolation: worktree
---

## Purpose

The **vertical slice** answers a different question from the concept prototype:
*"Can we build this full game loop at production quality, on schedule?"*

**Default use** — run late in Pre-Production, after GDDs, architecture, and UX
specs are complete. It is a near-production-quality build demonstrating one complete
[start → challenge → resolution] cycle.

**Post-pivot?** If a PIVOT verdict from an earlier vertical slice sent you back to
revise GDDs and architecture, run this again after revisions to re-validate. It can
be run as many times as needed until a PROCEED or KILL verdict is reached.

It validates:

1. The pipeline (can the team actually produce this quality of content?)
2. Execution feasibility (are the architecture decisions correct for this game?)
3. Fun survival (does the fun from the concept prototype survive full design?)
4. **Velocity** (how long did this take? That's your real production rate estimate.)

**Earlier in the project?** If you haven't written GDDs yet and want to validate
whether the core idea is worth designing, run `/prototype` (concept prototype) instead.

---

## Phase 1: Resolve Review Mode and Load Context

Resolve the review mode:
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

See `.claude/docs/director-gates.md` for the full check pattern.

Read the following files to understand the full design intent:
- `CLAUDE.md` — tech stack and engine
- `design/gdd/game-concept.md` — core fantasy and game pillars
- `design/gdd/systems-index.md` — MVP systems and their priorities
- `docs/architecture/architecture.md` — layer structure
- `docs/architecture/control-manifest.md` — technical rules for implementation
- Key GDDs for the systems being sliced

---

## Phase 2: Define the Slice Scope and Validation Question

Before building, define the **falsifiable validation question**:

> *"Does a player, starting from nothing, experience [core fantasy from game-concept.md]
> within [N] minutes, without developer guidance — and can we build one such loop
> in [X] days at representative quality?"*

Both parts matter: player experience AND build feasibility.

**Scope discipline:**
- Include ALL core loop systems (minimum). If a system is required to complete one
  [start → challenge → resolution] cycle, it must be in the slice.
- **Target scope: 3–5 minutes of polished, continuous gameplay.** This is the
  industry-standard vertical slice length — long enough to demonstrate mechanics
  and tone, short enough to build at representative quality. If your slice would
  take longer than 5 minutes to play through, cut content, not quality.
- **Cut scope before cutting quality.** A low-quality slice that looks nothing like
  the intended game cannot validate production feasibility.
- If the scope feels too large to build in 1–3 weeks, the slice scope is wrong —
  not too big to build, but the slice is trying to prove too much at once.

**Scope creep warning:** The vertical slice is the highest-risk moment for scope
creep in the pre-production phase. Features feel "almost there" and it's tempting
to add "just one more system." Resist this. Cut, do not extend.

Present scope to the user before building and get confirmation.

---

## Phase 3: Plan the Build

Define in bullet points:
- Systems implemented (which GDD sections are being exercised)
- The complete game loop cycle ([start] → [challenge] → [resolution] exactly)
- Art and audio quality level (placeholder acceptable, representative preferred)
- Specific, measurable success criteria for the validation question
- Hard time limit: [X] days. If exceeded, scope was wrong — stop and reassess.

Ask the user to confirm scope before building.

Once confirmed, write a session checkpoint to `production/session-state/active.md`
(create `production/session-state/` if it does not exist). Include: concept name,
validation question, systems in scope, art quality level, and current phase ("Phase
4 — Implement"). Update this file at the end of each build day with what was
completed. This is the primary recovery mechanism if the session ends mid-slice —
multi-week Engine builds will span many sessions.

---

## Phase 4: Implement

Ask: "May I create the vertical slice directory at
`prototypes/[concept-name]-vertical-slice/` and begin implementation?"

If yes, create the directory. Every file must begin with:

```
// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: [What this build is proving]
// Date: [Current date]
```

**Quality standards** — higher than concept prototype, not full production:
- Follow architecture layers from `docs/architecture/control-manifest.md`
- Naming conventions from `.claude/docs/technical-preferences.md`
- No hardcoded gameplay values — use constants or config files
- Basic error handling on critical paths
- Placeholder art acceptable; representative art preferred

**Multi-turn loop:** After writing the initial files, ask the user to run the
build and report what they observe. Iterate until the complete game loop cycle
is demonstrable. Each round:
1. User runs → reports errors or observations
2. Agent fixes errors or adjusts systems
3. Repeat until the full [start → challenge → resolution] cycle is playable

**Sunk cost checkpoint (day 3 of planned timeline):** If the full game loop cycle
is not yet demonstrable, stop and reassess. Either the scope is too large or an
architectural assumption is wrong. Surface the blocker explicitly rather than
continuing to iterate.

Conduct at least 1 playtest session once the loop is demonstrable.

**Playtesting tip:** If you can get anyone who hasn't seen the game to play it —
a friend, family member, online community — watch them silently without explaining
anything. Don't guide them. Their confusion reveals what the game isn't
communicating on its own. This gives much better signal than self-testing.

**No external testers available?** Use rotation within the team: Dev A built
system X, so Dev A is a naive tester for system Y. Even a two-person team can
rotate effectively. Solo? Step away for 2-3 days then play through as a new
player — you won't have perfect first-impression signal but you'll catch the
critical blockers. Also try a "silent walkthrough": play your own slice in one
sitting without stopping to fix anything and log every moment you hesitate.

**Want richer observation data?** Ask the tester to **think aloud** as they play —
narrate what they're doing and why in real time. "I'm trying to figure out how to
attack... I pressed E... nothing... is it click?" This surfaces confusion the
instant it occurs rather than in retrospect. Best for onboarding and UI clarity
validation. Silent observation is still better for feel testing; think-aloud
changes the experience slightly but produces far more granular UX data.

**Async remote option:** Record a Loom or OBS session — give someone the build,
ask them to record their screen + audio, and send you the video. You get genuine
first-impression data without synchronous scheduling. Works across timezones.

**Testing AI, NPC, or complex system behavior before it's fully implemented?** Use the
**Wizard of Oz** technique: one person plays normally while a second person secretly
controls the NPC or system behavior in real time. The player believes it's automated.
This validates the *design intent* of an AI or economy system before the implementation
is complete — and reveals exactly what behaviors the system must produce to feel correct.
Particularly useful for vertical slices where an AI system is in scope but not yet
polished enough for unguided testing.

---

## Phase 5: Playtest Debrief

The loop is demonstrable. Before writing the report, collect structured observations
from actually playing it. Do NOT skip to report generation — the report is only as
good as the observations you capture here.

Say exactly this:
> "Play through the complete [start → challenge → resolution] cycle from scratch,
> as if you're a new player with no knowledge of how it was built. Don't skip ahead
> or use developer shortcuts. Come back when you've completed the full loop —
> or when you've hit something that stopped you."

Once the user returns, ask these questions **one at a time**:

1. **Loop completion:**
   > "Did you complete the full [start → challenge → resolution] cycle on your own,
   > without needing any guidance from me or prior knowledge of the build?"

2. **Time check:**
   > "How long did it take to reach the first meaningful action — the first moment
   > where you felt like you were actually playing the game?"

3. **Core fantasy:**
   > "The game is supposed to make you feel [core fantasy from game-concept.md].
   > Did it? Be honest — not 'kind of' but specifically what you felt and when."

4. **Blockers:**
   > "What stopped you, confused you, or pulled you out of the experience? Any
   > moment where you weren't sure what to do, or where something broke?"

5. **Pipeline check:**
   > "As the developer — not the player — does this feel achievable at this quality
   > for the full game? What surprised you about how long things took to build?"

6. **Verdict:**
   > "PROCEED, PIVOT, or KILL — and the specific reason."

If any answer is vague, ask: "Can you give me the specific moment where that happened?"
Precise observations populate the report. Vague ones produce a useless report.

---

## Phase 6: Generate Vertical Slice Report


Track velocity throughout the build. Log:
- Day 1: what was built
- Day 2: what was built
- etc.

This is the most honest data you will ever have about your production rate. Do not
skip it. It feeds directly into sprint planning.

Read `.claude/docs/templates/vertical-slice-report.md` to get the report structure.
If the template file is not found, use this fallback structure:
- `## Vertical Slice Report — [Game Title] — [Date]`
- `### Executive Summary` (PROCEED / PIVOT / STOP verdict + 2-sentence rationale)
- `### Core Loop Validation` (what was tested, what passed, what failed)
- `### Feel Assessment` (animation, controls, feedback — subjective notes)
- `### Technical Findings` (performance, engine issues, architectural risks)
- `### Velocity Log` (day-by-day actual progress — do not skip)
- `### Recommended Next Steps`

Fill in every section based on what was observed and built during this session.
The velocity log must reflect actual day-by-day progress, not estimates — this is
the most honest production rate data you will ever have. Replace all placeholder
text with real observations.

### Lessons Learned
- What assumptions were broken by actually building to near-production quality?
- What surprised us about the pipeline or architecture?
- What would we change about the slice scope if we ran this again?
```

Ask: "May I write this report to
`prototypes/[concept-name]-vertical-slice/REPORT.md`?"

If yes, write the file. Then update `prototypes/index.md` (create if it does not
exist) — append one row to the vertical slice table: concept name, date, verdict,
and a link to the REPORT.md. Note whether this was a first-run slice or a re-run
after a PIVOT. The velocity log in this report is some of the most valuable data in
the project — cross-reference it with sprint estimates.

---

## Phase 7: Creative Director Review

**Review mode check:**
- `solo` → skip. Note: "CD-PLAYTEST skipped — Solo mode."
- `lean` → skip (not a PHASE-GATE). Note: "CD-PLAYTEST skipped — Lean mode."
- `full` → spawn `creative-director` via Task using gate **CD-PLAYTEST**
  (`.claude/docs/director-gates.md`).

Pass: the full REPORT.md content, the validation question, game pillars and core
fantasy from `design/gdd/game-concept.md`.

The creative director evaluates the vertical slice result against the game's
creative vision and pillars, then confirms, modifies, or overrides the
recommendation. Their verdict is final. Update REPORT.md if the verdict differs.

---

## Phase 8: Summary and Next Steps

Output a summary: the validation question, velocity data, and final recommendation.
Link to `prototypes/[concept-name]-vertical-slice/REPORT.md`.

**If PROCEED:**
Your vertical slice validated the full game loop. The project is ready for
Production.

Recommended next steps:
- `/create-epics layer:foundation` — plan Foundation layer epics
- `/create-epics layer:core` — plan Core layer epics
- `/create-stories [epic-slug]` — break each epic into implementable stories
- `/sprint-plan` — plan the first sprint using velocity data from the slice
- `/gate-check pre-production` — formally advance the stage to Production

**Playtest note:** `/gate-check` will look for documented playtest evidence.
At minimum, 1 documented session with a REPORT.md showing PROCEED is required
to pass the gate. More sessions give more reliable signal — 3+ is recommended
before committing the full team to Production, but is not a hard gate.

**If PIVOT:**

Before routing back to GDD revision, capture the carry-forward note. Ask these
two questions (plain text, one at a time):

1. "What systems or mechanics worked at this quality level and should be preserved in the revised design?"
2. "What specifically failed — the core loop, the architecture, the pipeline, or the fun?"

Ask: "May I write this to `prototypes/[concept-name]-vertical-slice/PIVOT-NOTE.md`?"

If yes, write the file with: what worked, what failed, the specific systems or
architecture decisions that need revision, and what the next slice should prove
differently. When `/vertical-slice` is next run after a PIVOT, check the
`prototypes/` directory for a `PIVOT-NOTE.md` — use it to frame the new validation
question and inform scope decisions.

- Revise affected GDDs with `/design-system [mechanic]`
- Address architecture issues via `/architecture-decision`
- Then re-run `/vertical-slice` to validate the revised direction

**If KILL:**

Before abandoning the concept, confirm the verdict is sound:

- [ ] Full game loop takes >5 minutes even for an experienced player?
- [ ] No emotional high point (delight, surprise, satisfaction) observed in any playtest session?
- [ ] 50%+ of testers confused or stuck at the same point after 2+ slice attempts?
- [ ] Architecture issues would require rebuilding more than 50% of what was built?
- [ ] This is the 3rd vertical slice attempt on the same concept?

If 2+ boxes apply → KILL verdict is sound. If 0–1 apply → one targeted PIVOT may recover the concept.

**Document the kill in `prototypes/GRAVEYARD.md`** (create if it doesn't exist).
Ask: "May I append this to `prototypes/GRAVEYARD.md`?" If yes, add one entry:

```
## [Concept Name] Vertical Slice — YYYY-MM-DD
- **Kill reason:** [what specifically prevented the player from experiencing the core fantasy]
- **What worked at slice quality:** [systems or mechanics that held up]
- **What failed:** [core loop issue, architecture decision, or pipeline blocker]
- **Next time:** [one specific change for the next time a similar concept is attempted]
```

- Return to `/brainstorm` with what you learned
- Or run `/prototype [new-concept]` to test a new direction cheaply first

---

### Important Constraints

- Vertical slice code must NEVER be refactored into production — it is reference only
- Production code must NEVER import from `prototypes/`
- If recommendation is PROCEED, production implementation is written from scratch
  using the slice as a design reference only
- Scope cuts are acceptable; quality cuts are not — a low-quality slice proves nothing
- Total effort: 1–3 weeks. If longer, scope is too large — cut the slice, not the quality.
- Day 3 sunk cost rule: if the full game loop cycle is not demonstrable by then,
  stop and surface the blocker
- **Networked/multiplayer games:** A local vertical slice cannot validate the feel
  of a networked mechanic. Latency fundamentally changes how combat, movement, and
  prediction feel — testing locally at 0ms will feel entirely different at 80ms
  network delay. The slice can validate that the game loop is interesting and
  complete; it cannot validate that networked mechanics feel good under real
  conditions. Network feel requires real peers or simulated latency.
