---
name: prototype
description: "Concept prototype — validate the core idea is worth designing before writing GDDs. Run right after /brainstorm and /setup-engine. Routes to HTML, Engine, or Paper path based on game type. Produces a throwaway build and a PROCEED/PIVOT/KILL verdict."
argument-hint: "[concept-description] [--path html|engine|paper] [--review full|lean|solo] [--spike]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
model: sonnet
agent: prototyper
isolation: worktree
---

## Purpose

This is the **concept prototype** — a fast, throwaway build that answers one question:
*"Is this core idea actually fun to interact with?"*

**Default use** — run right after `/brainstorm` and `/setup-engine`, before writing
GDDs or architecture docs. Its verdict determines whether the concept is worth the
investment of full design documentation.

**Mid-production?** You can also run this at any stage to test a specific mechanic,
design change, or technical question. Pass `--spike` to activate spike mode: a
lightweight ~4-hour build with no GDD prerequisites and no phase gate implications.

**Already have GDDs and architecture complete?** To validate the full game loop
before committing to Production, run `/vertical-slice` instead.

---

## Phase 1: Define the Question

Resolve the review mode (once, store for all gate spawns this run):
1. If `--review [full|lean|solo]` was passed → use that
2. Else read `production/review-mode.txt` → use that value
3. Else → default to `lean`

**Check for spike mode:** If `--spike` was passed, skip to the **Spike Mode** section
at the bottom of this skill.

Otherwise, use `AskUserQuestion` to confirm intent before proceeding:

- **Prompt**: "How would you like to use this prototype session?"
- **Options**:
  - `Prototype this concept` — build a throwaway build to validate the core idea is fun before writing GDDs (1–3 days)
  - `Skip — concept already proven` — I have enough evidence this works; log it and proceed directly to design
  - `Mid-production spike` — I'm already in Production and want to test a specific mechanic or technical question quickly (~4 hours, no phase gate implications)

**If "Skip — concept already proven":**
Ask (plain text, not a widget): "What evidence do you have that the concept works?"
Record the one-line answer, then stop. Note: "Concept prototype skipped — evidence:
[answer]." Suggest next step: `/map-systems` or `/design-system [mechanic]`.

**If "Mid-production spike"**: skip to the **Spike Mode** section below.

**If "Prototype this concept"**: continue with Phase 1 below.

---

**A note on prototype strategy:** The research on successful indie development
is consistent — building 2-3 concept variants and letting the best one win is
far more likely to succeed than iterating one concept until it works. This is
your first prototype, not necessarily your only one. If this prototype produces
a PIVOT verdict, consider whether to refine this concept OR start fresh with a
different angle on the same game idea and prototype that instead.

**Game jam as a prototype vehicle:** If you're planning a concept prototype anyway,
consider timing it to a game jam (Ludum Dare, GMTK Game Jam, Global Game Jam). Jams
provide a forced timebox (48-72 hours), instant distribution to thousands of players
who rate and review early builds, and a deadline that prevents scope creep by design.
Many shipped games (Celeste, VVVVVV) began as jam prototypes. Not required — but
worth considering if the timing is right.

Read the concept description from the argument. Before building anything, define
the **falsifiable hypothesis** this prototype must answer:

> *"If the player [does X], they will feel [Y] — we will know this is true if [measurable signal Z]."*

Good: "If the player swings on grapple hooks, traversal will feel fluid — we'll know if
players chain 3+ swings without stopping within 2 minutes of picking it up."

Bad: "Does this feel fun?" ← not testable, not falsifiable.

**If the concept is too vague to form a hypothesis, stop here.** Ask the user to
narrow the question before proceeding. A prototype without a clear question wastes time.

Also ask: **"What is the riskiest assumption in this concept?"** That is the first
thing the prototype should test — not the easiest part, the riskiest.

---

## Phase 2: Load Concept Context

Read `design/gdd/game-concept.md` if it exists. Extract:
- Core fantasy (what the player is supposed to feel)
- Core loop (the moment-to-moment action being tested)

Read `CLAUDE.md` and `.claude/docs/technical-preferences.md` for the engine and
language in use.

---

## Phase 3: Choose the Prototype Path

Select the prototype path. If `--path [html|engine|paper]` was passed, use that.
Otherwise, use this quick-reference first, then read the full path details below:

| Genre | Recommended path | Key reason |
|-------|-----------------|------------|
| Platformer / action / fighter | **Engine** | Feel IS the hypothesis; browser latency produces false results |
| Racing / sports | **Engine** | Same — timing and physics feedback are the point |
| Top-down shooter / twin-stick | **Engine** | Aim feel is timing-sensitive |
| Puzzle (logic) | **HTML** or **Paper** | Timing is not the point; logic and clarity are |
| Card game | **Paper** first | Fastest iteration by hand before touching code |
| Narrative / visual novel | **Paper** (Twine / Ink / Yarn Spinner) | Story is the mechanic — test it without code overhead |
| Strategy / 4X / city builder | **Paper** (spreadsheet sim) | Validate economy and progression rules before building |
| Roguelike (systems-heavy) | **Paper** → Engine | Validate that the ruleset is interesting before building |
| Idle / clicker / incremental | **HTML** | Turn-based logic, no feel sensitivity required |
| Rhythm game | **Paper** first (design levels in audio) | Design levels before the engine exists |
| RPG / open world | **Paper** → Engine | Systems complexity: validate rules, then validate feel |
| Horror / atmospheric | **Engine** | Atmosphere requires real rendering |

**Rule of thumb:** "Does this feel right?" → Engine. "Are these rules interesting?" → Paper. "Is this logic correct?" → HTML or Paper.

### Path: HTML (browser-playable)

**Best for:** Puzzle games, card games, turn-based strategy, word games, idle games,
top-down logic games. Anything where timing precision doesn't matter.

**Reliability:** ~85–90% one-shot. The agent writes a single self-contained HTML
file the user opens in a browser — no install required.

**Limitation — browser latency lies about game feel.** Browsers introduce
50–133ms of rendering variance. This makes HTML prototypes fundamentally unreliable
for action games, platformers, fighting games, or anything where input timing,
jump arcs, or collision feel are what you're testing. If feel is the hypothesis,
use the Engine path instead.

**Alternative tools for this path:** PICO-8 (extreme constraints, great for retro
arcade concepts, web-export in one command), Phaser.js (more capable browser game
framework, still no install needed), or Twine (narrative/choice-based games).
These are faster than raw HTML for their respective genres — suggest them if appropriate.

**Output:** A single `prototype.html` (or PICO-8/Phaser equivalent) the user opens in any browser.

**Distribution — the HTML path's biggest advantage:** Unlike Engine prototypes, this
build can reach real players globally in minutes. Use this actively:
- **itch.io** — upload the file, share the link, get play counts and written feedback
  within hours. Free. The indie community plays rough builds here without expecting
  polish. This is genuine external validation at zero cost.
- **Loom + file share** — share via Google Drive/Dropbox, ask someone to record their
  screen + audio with Loom while playing. You get a video of real first-impression
  reactions and confusion without synchronous scheduling.
- **r/playmygame or r/WebGames** (Reddit) — active communities that specifically
  test early builds and give unsolicited honest feedback.
- **Game dev Discord servers** (GMTK, Brackeys, GameDev.tv) — members test each
  other's prototypes routinely; an HTML file is the easiest possible ask.

---

### Path: Engine (engine project)

**Best for:** Action games, platformers, physics-heavy games, anything where
moment-to-moment feel IS the hypothesis. Use this when HTML latency would lie about
the result.

**Reliability:** ~50–60% one-shot. Expect 2–4 rounds of iteration — this is
normal, not a failure.

**Limitation — requires engine installed and running.** This path is a
multi-turn collaborative loop:
1. Agent writes the code
2. User runs it in the engine
3. User reports errors or observations
4. Agent fixes and iterates

**Sunk cost rule:** If the user has been iterating for more than 2 hours without
reaching a playable state, stop. The scope is too large or the question is wrong.
Reframe the hypothesis and simplify aggressively, or switch to Paper path.

**Output:** A minimal runnable engine project in `prototypes/[name]-concept/`.

**Lighter alternative — Love2D (Lua):** If the project engine (Godot, Unity, Unreal)
feels too heavy to stand up for a throwaway build, consider Love2D — a minimal 2D
framework that installs in minutes, requires no project scaffolding, and renders
natively with no browser latency. Used by many indie devs for rapid 2D action and
platformer prototypes (Balatro prototyped in Love2D; Nuclear Throne's early builds
used it). It sits between HTML overhead and full engine overhead: heavier than
opening a browser, lighter than setting up a full engine project. Best for 2D
action/platformer feel validation when the project engine is 3D-first or takes
significant time to configure.

---

### Path: Paper (rules document + play log)

**Best for:** Strategy games, card games, board game-style mechanics, economy
systems, progression loops, any game where the logic can be simulated by hand.
Works for any genre when you need to validate rules, not feel.

**Reliability:** 100%. No code, no engine, no install.

**Limitation — cannot validate moment-to-moment feel.** Paper prototypes prove
that the rules are internally consistent and the decisions are interesting. They
cannot tell you whether jumping feels right or whether explosions feel satisfying.

**Paper playtest observation protocol (run this with 5+ people):**
1. Brief the rules once. Hand them the rule summary sheet. Then step back.
2. Do NOT explain further. Do NOT help. Do NOT clarify. Confusion is data.
3. Watch silently. Note every moment they slow down, re-read, or ask a question.
4. After the session, ask one question only: "What was confusing?" — not "Did you like it?"
5. Use fresh testers for each iteration. The same person cannot give new first-impression data.
6. If 3+ testers hit the same confusion point, that rule is broken — redesign it before re-testing.

**Output:** A printable rules document + a completed play log showing one simulated session.

**Narrative tools for this path:** For dialogue-heavy and story-driven games, skip the
generic rules doc — use a dedicated narrative scripting tool instead:
- **Twine** — zero-code hypertext fiction; ideal for branching structure experiments and choice-impact testing
- **Ink** (Inkle) — plain-text scripting language used in *80 Days*, *Heaven's Vault*, and *Overboard*; exports directly to Unity and Godot
- **Yarn Spinner** — dialogue scripting used in *A Short Hike*, *DREDGE*, and *Night in the Woods*; integrates natively with Unity and Godot

All three let you write and playtest branching dialogue in minutes. Key metric for
narrative prototypes: **time to first emotional beat** — how many exchanges before
the player feels something? If it takes more than 3-4 exchanges, the opening is too slow.

---

Assess which path best fits the hypothesis, then use `AskUserQuestion` with your
recommendation pre-stated:

- **Prompt**: "Which prototype path would you like to use? (Based on your concept, I'd recommend [path] — [one sentence reason].)"
- **Options**:
  - `HTML — browser prototype` — puzzle, card, turn-based, strategy, idle. Opens by double-clicking, no install. 85–90% reliable. **Not suitable for action games** — browser latency lies about feel.
  - `Engine — native prototype` — action, platformer, physics, or anything where feel IS the hypothesis. 50–60% one-shot; 2–4 iteration rounds are normal. Requires engine installed.
  - `Paper — rules document + play log` — strategy, economy, logic, board-game-style mechanics. 100% reliable. Cannot validate feel.

---

## Phase 4: Plan the Prototype

Define in 3–5 bullet points the minimum viable prototype:

- What is the falsifiable hypothesis?
- What is the riskiest assumption — and how does this prototype test it first?
- What is the absolute minimum needed to answer the question?
- What is explicitly cut? (menus, save systems, error handling, polish, architecture — all of it)

**Scope constraint:** A concept prototype tests ONE mechanic — not the whole game.
If scope covers more than one mechanic, cut it down. When in doubt, cut more.

Present this plan to the user before building. Get confirmation before proceeding.

Once confirmed, write a session checkpoint to `production/session-state/active.md`
(create `production/session-state/` if it does not exist). Include: concept name,
hypothesis, path chosen, scope bullet points, and current phase ("Phase 5 —
Implement"). This lets the next session resume without starting over if the session
ends mid-build — especially important for multi-day Engine path work.

---

## Phase 5: Implement

Ask: "May I create the prototype directory at `prototypes/[concept-name]-concept/`
and begin implementation?"

If yes, create the directory. Every file must begin with:

```
// PROTOTYPE - NOT FOR PRODUCTION
// Question: [Core question being tested]
// Date: [Current date]
```

Standards are intentionally relaxed:

- Hardcode values freely
- Use placeholder assets (colored rectangles, debug shapes)
- Skip error handling entirely
- Use the simplest approach that works
- Copy code rather than importing from production
- No architecture, no patterns, no abstractions

**Do not add polish.** No menus, no game over screens, no music, no tutorial text
unless the tutorial IS the mechanic being tested. Every addition beyond the
hypothesis is waste.

**Playtesting tip:** If you have access to anyone who hasn't seen the game —
friends, family, strangers online — watching them play without explanation gives
far better signal than testing it yourself. Watch silently; don't guide them.
Confusion is data. Ask one question after: "What was confusing?" Not "Did you
like it?"

**No external testers available?** Use rotation: if you built system A, you're a
naive tester for system B. In a two-person team this works well. Solo developer?
Step away for 2-3 days before playing fresh — you won't have perfect first-impression
signal, but you'll surface the worst blockers. Another option: play your own
prototype as a speedrun (force yourself through it in 5 minutes without stopping
to fix things) — the friction you feel is what strangers will hit.

**Want more granular UX data?** Ask the tester to **think aloud** as they play —
narrate their thoughts in real time: "I'm pressing space... nothing happened... is
that the jump key?" This surfaces confusion the moment it happens rather than
waiting for a post-play debrief. Best for UI/UX and onboarding clarity. Silent
observation is still better for testing raw feel; think-aloud changes how people
play slightly but gives much richer data about why they're confused.

**HTML prototype?** itch.io, Reddit (r/playmygame), and Discord (GMTK, Brackeys)
let you reach strangers today at zero cost — see the distribution options in the
HTML path section above.

**Testing AI, NPC, or complex system behavior before writing the code?** Use the
**Wizard of Oz** technique: one person plays normally while a second person secretly
controls the NPC, enemy, or system behavior in real time — making the decisions a
human would make, not an algorithm. The player believes it's automated. This lets
you validate whether your AI design *feels right* before writing a single line of
pathfinding or decision tree code. When you observe what responses the human
controller naturally produces, you learn exactly what the AI needs to do.

### Engine path: multi-turn loop

After writing the initial code:

> "The prototype files are written. Run the project in your engine now.
> If there are errors, paste them here and I'll fix them. If it runs,
> describe what you see and whether it feels like it's answering the question."

Iterate until the prototype is playable. Each loop:
1. User runs → reports errors or observations
2. Agent fixes errors or adjusts the mechanic
3. Repeat until playable or sunk cost rule triggers

### HTML path: single output

Write a single `prototype.html` to `prototypes/[concept-name]-concept/`. Include
all styles, logic, and assets inline. The file must be openable by double-clicking
with no server required.

### Paper path: document + log

Write `prototypes/[concept-name]-concept/rules.md` (the game rules) and
`prototypes/[concept-name]-concept/play-log.md` (a simulated session walking
through one complete play cycle step by step with dice rolls, decisions, and
outcomes narrated).

---

## Phase 6: Playtest Debrief

The prototype is built. Now hand it to the user and capture what they actually
experienced. Do NOT skip to report generation — the report is only as good as the
observations you collect here.

**For HTML path:** Say exactly this:
> "The prototype is ready. Open `prototypes/[name]-concept/prototype.html` in your
> browser and play it. Take as long as you need. Don't rush through it — try to
> approach it the way a new player would. Come back here when you're done."

**For Engine path:** The multi-turn iteration loop already captured errors and
behavior. Now ask for the overall assessment:
> "Now that it's running — play through it a few times as if you're the player,
> not the developer. Come back when you have a feel for it."

**For Paper path:** Say exactly this:
> "Read through `prototypes/[name]-concept/rules.md` and walk through the
> `play-log.md` as if you're playing it for the first time. If you have someone
> nearby, try running the rules with them. Come back when you've seen at least one
> full play cycle."

Once the user returns, ask these questions **one at a time** — wait for each answer
before asking the next:

1. **Hypothesis check:**
   > "The hypothesis was: [restate the hypothesis from Phase 1]. Did it hold up —
   > CONFIRMED, PARTIALLY CONFIRMED, or REFUTED? Tell me what you saw."

2. **Best moment:**
   > "What was the moment — if any — where it felt like it was working? Be specific."

3. **Worst moment:**
   > "What was the most frustrating, confusing, or broken moment? Be specific —
   > not 'it felt slow' but 'the jump took about half a second to respond and it
   > felt like I was fighting the controls'."

4. **Surprise:**
   > "Did anything happen that you didn't expect — good or bad?"

5. **Verdict:**
   > "PROCEED, PIVOT, or KILL — and one sentence why."

Collect all answers before moving to report generation. If any answer is vague
("it felt fine", "pretty good"), ask a follow-up: "Can you be more specific?
What exactly felt fine about it?" Precise observations make the report useful.
Vague ones make it useless.

---

## Phase 7: Generate Prototype Report

Read `.claude/docs/templates/prototype-report.md` to get the report structure.
Fill in every section based on what was observed during this session. Replace all
placeholder text with real observations — no generic filler.

Ask: "May I write this report to `prototypes/[concept-name]-concept/REPORT.md`?"

If yes, write the file. Then update `prototypes/index.md` (create if it does not
exist) — append one row to the concept prototype table: concept name, date, path
used, verdict (PROCEED/PIVOT/KILL), and a link to the REPORT.md. If a PIVOT chain
exists (prior PIVOT-NOTE.md in a related concept folder), note the chain. This file
is the project's complete history of what was tried and what was learned.

---

## Phase 8: Creative Director Review

**Review mode check:**
- `solo` → skip. Note: "CD-PLAYTEST skipped — Solo mode."
- `lean` → skip. Note: "CD-PLAYTEST skipped — Lean mode."
- `full` → spawn `creative-director` via Task using gate **CD-PLAYTEST** if
  `design/gdd/game-concept.md` exists with game pillars defined. If pillars are
  not yet defined, note: "CD-PLAYTEST skipped — game pillars not yet defined at
  concept prototype stage."

Pass: the full REPORT.md content, the original hypothesis, and game pillars /
core fantasy from `design/gdd/game-concept.md`.

The creative director evaluates the result against the game's creative vision and
confirms, modifies, or overrides the recommendation. Their verdict is final. Update
REPORT.md if the verdict differs.

---

## Phase 9: Summary and Next Steps

Output a summary: the hypothesis, the result, and the final recommendation.
Link to `prototypes/[concept-name]-concept/REPORT.md`.

**If PROCEED:**
Your concept prototype validated the core idea. Now design it properly, informed by
what you just learned.

Recommended path (in order):
1. `/design-review design/gdd/game-concept.md` — validate the concept doc against what the prototype revealed
2. `/gate-check` — confirm readiness to advance to Systems Design
3. `/art-bible` — define visual identity (optional but worth doing before GDDs)
4. `/map-systems` — decompose the concept into all game systems
5. `/design-system [mechanic]` — GDD for each MVP system; use prototype learnings
   in the Tuning Knobs and Formulas sections
6. `/review-all-gdds` — cross-system consistency check

**Note:** If you used the HTML path and feel is still uncertain, consider running
a quick engine path prototype targeting feel before writing GDDs.

**If PIVOT:**

Before routing to the next prototype, capture the carry-forward note. Ask these
two questions (plain text, one at a time):

1. "What specifically worked in this prototype that we should preserve in the next version?"
2. "What is the single most important thing to change?"

Ask: "May I write this to `prototypes/[concept-name]-concept/PIVOT-NOTE.md`?"

If yes, write the file with: original hypothesis, what to keep, what to change, and
the revised hypothesis for the next prototype. When `/prototype` is next run, check
`prototypes/` for any `PIVOT-NOTE.md` files — if found, read them and use the
revised hypothesis as the starting point rather than forming one from scratch.

- Run `/prototype [revised-concept]` to test the adjusted direction
- Or `/brainstorm [hint]` if the concept needs more fundamental rethinking

**If KILL:**

Before moving on, run this check to confirm the verdict is sound and not temporary frustration:

- [ ] Core mechanic still unclear to testers after 2+ playtests?
- [ ] No "fun moment" (smile, laugh, or retry by choice) observed in any session?
- [ ] 3+ PIVOT iterations on the same concept with no clear improvement?
- [ ] Concept only works when heavily explained or when the dev guides the player?
- [ ] Building this feels like obligation, not excitement?

If 2+ boxes apply → KILL verdict is sound. If 0–1 apply → consider one more focused PIVOT before killing.

**Document the kill in `prototypes/GRAVEYARD.md`** (create if it doesn't exist).
Ask: "May I append this concept to `prototypes/GRAVEYARD.md`?" If yes, add one entry:

```
## [Concept Name] — YYYY-MM-DD
- **Kill reason:** [specific blocker — not "it was boring" but "players never understood the core action"]
- **What worked:** [2-3 things worth carrying forward to future concepts]
- **What failed:** [the specific mechanic, design decision, or scope issue]
- **Next time:** [one explicit action to try differently on a similar concept]
```

This file exists so the same mistake doesn't get made twice on the next concept.

- Run `/brainstorm open` or `/brainstorm [new-hint]` to explore a different concept
- The prototype report is the deliverable — no further action needed

---

---

## Spike Mode

**Triggered by:** `--spike` flag OR "Mid-production spike" entry choice in Phase 1.

**Purpose:** Test a specific technical or design question mid-production, without
the overhead of a full concept prototype workflow. No GDD prerequisites. No phase
gate implications. Hard cap: ~4 hours.

**When to use:**
- You're in Production and want to test whether a new mechanic should be added
- You're unsure if a technical approach will work before building it properly
- A design change is being considered and you want a quick before/after comparison
- A GDD system is proving harder than expected and you want to prototype the hard part
- You need to confirm target hardware can sustain the required framerate before writing gameplay code (**performance spike** — see below)

**Spike Mode workflow (replaces Phases 1–9):**

1. **Define the spike question** (plain text, not a widget): "What specific question does this spike answer? Give me one sentence: 'Can we [do X] using [approach Y]?'"

2. **Choose path** — same AskUserQuestion widget as Phase 3 (HTML / Engine / Paper).

3. **Scope** — maximum 2-3 bullet points. One mechanic, one technical question, nothing else.

4. **Build** — same relaxed standards as concept prototype. Hard cap: 4 hours. If not demonstrable in 4 hours, the question is too large. Split it.

5. **Observe and decide** — no formal playtest debrief. Ask: "Did the spike answer the question? YES or NO, and why in one sentence."

6. **Write a spike note** (not a full report) to `prototypes/[concept-name]-spike-[date]/SPIKE-NOTE.md`:
   - Question tested
   - Result (YES it works / NO it doesn't / PARTIAL — needs more investigation)
   - What to do next (add to current sprint / investigate further / abandon the idea)

7. **Update `production/session-state/active.md`** to clear the spike and return to the current sprint state.

**No CD gate. No phase gate. No PROCEED/PIVOT/KILL.** Spike results inform decisions; they don't make them. The developer decides whether to add the mechanic/approach to the sprint backlog based on what the spike revealed.

**Performance spike (special case):** If the game involves demanding rendering —
large open worlds, hundreds of simultaneous physics bodies, heavy particle systems,
complex shaders — run a performance spike before writing gameplay code to confirm
the target hardware can sustain the required framerate. This is distinct from other
spikes in two ways:
- The question is "can the engine render [scene X] at 60fps on [minimum spec hardware]?"
  not "does this mechanic feel good?"
- The output is a benchmark number, not a feel verdict
- No gameplay logic is needed — just the maximum intended scene load (terrain, draw
  calls, physics objects, particles) running at once
- Build time stays within the ~4-hour cap; the spike is setting up the rendering
  load, not the game
- If the answer is NO at this scope, this is an architecture or scope constraint
  that affects everything downstream — better to surface it now than during Sprint 8

---

### Important Constraints

- Prototype code must NEVER import from production source files
- Production code must NEVER import from prototype directories
- If the recommendation is PROCEED, production implementation is written from
  scratch — prototype code is never refactored into production
- Total effort is hard-capped at 1 day (concept prototypes test one mechanic)
- Test ONE mechanic — if scope grows, stop and simplify the question
- No polish. No menus, no game over, no music, no UI unless it IS the mechanic
- If stuck after 2 hours of engine iteration, reframe the question or switch paths
- **3 PIVOT iterations → force a KILL decision.** If this is the third time the
  same concept has produced a PIVOT verdict, the concept likely doesn't work.
  Ask: "Is this the right idea, or am I in the sunk cost trap?" A new concept
  prototyped fresh will almost always beat a fourth iteration of a struggling one.
- Building 2-3 different concept variants and picking the best one is a healthier
  strategy than iterating one concept to death. Natural selection between prototypes
  beats willpower.
- **Networked/multiplayer games:** A local prototype cannot validate the feel of a
  networked mechanic. Latency fundamentally changes how combat, movement, and
  prediction feel — a prototype running at 0ms local will feel entirely different at
  80ms network delay. Use a local prototype to validate that the mechanic is
  *interesting*. Do not use it as evidence that it *feels good* under real network
  conditions. Network feel requires real peers or simulated latency (e.g., throttle
  tools, network condition simulators).
