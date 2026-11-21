# /prototype — Phase 3: Choose the Prototype Path

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Choose the Prototype Path

**In this file:**

- Path: Engine (engine project)
- Path: Paper (rules document + play log)
- The path question (the browser sketch is its third option)

This route runs when the project names an engine. Select the prototype path. If `--path
engine` or `--path paper` was typed after the skill name, use that. Otherwise, use this
quick-reference first, then read the full path details below:

| Genre | Recommended path | Key reason |
|-------|-----------------|------------|
| Platformer / action / fighter | **Engine** | Feel IS the hypothesis; test it in the engine the game ships in |
| Racing / sports | **Engine** | Same — timing and physics feedback are the point |
| Top-down shooter / twin-stick | **Engine** | Aim feel is timing-sensitive |
| Puzzle (logic) | **Paper** | Timing is not the point; logic and clarity are |
| Card game | **Paper** first | Fastest iteration by hand before touching code |
| Narrative / visual novel | **Paper** (Twine / Ink / Yarn Spinner) | Story is the mechanic — test it without code overhead |
| Strategy / 4X / city builder | **Paper** (spreadsheet sim) | Validate economy and progression rules before building |
| Roguelike (systems-heavy) | **Paper** → Engine | Validate that the ruleset is interesting before building |
| Idle / clicker / incremental | **Paper** (spreadsheet sim) | The numbers are the game; validate the curve first |
| Rhythm game | **Paper** first (design levels in audio) | Design levels before the engine exists |
| RPG / open world | **Paper** → Engine | Systems complexity: validate rules, then validate feel |
| Horror / atmospheric | **Engine** | Atmosphere requires real rendering |

**Rule of thumb:** "Does this feel right?" → Engine. "Are these rules interesting?" or "Is this logic correct?" → Paper.

### Path: Engine (engine project)

**Best for:** Action games, platformers, physics-heavy games, anything where
moment-to-moment feel IS the hypothesis, tested in the engine the game ships in.

Expect several rounds of iteration: this is normal, not a failure.

**Limitation — requires engine installed and running.** This path is a
multi-turn collaborative loop:
1. You write the code
2. User runs it in the engine
3. User reports errors or observations
4. You fix and iterate

**Sunk cost rule:** If the user has been iterating for more than 2 hours without
reaching a playable state, stop. The scope is too large or the question is wrong.
Reframe the hypothesis and simplify aggressively, or switch to Paper path.

**Output:** A minimal runnable engine project in `prototypes/[name]-concept/`.

**Lighter alternative — Love2D (Lua):** If the project engine (Godot, Unity, Unreal)
feels too heavy to stand up for a throwaway build, consider Love2D — a minimal 2D
framework that installs in minutes, requires no project scaffolding, and renders
natively. Balatro was made in it. It is heavier than opening a browser and lighter
than setting up a full engine project. Best for 2D
action/platformer feel validation when the project engine is 3D-first or takes
significant time to configure.

---

### Path: Paper (rules document + play log)

**Best for:** Strategy games, card games, board game-style mechanics, economy
systems, progression loops, any game where the logic can be simulated by hand.
Works for any genre when you need to validate rules, not feel.

No code, no engine, no install.

**Limitation — cannot validate moment-to-moment feel.** Paper prototypes prove
that the rules are internally consistent and the decisions are interesting. They
cannot tell you whether jumping feels right or whether explosions feel satisfying.

**Paper playtest observation protocol (run this with 5+ people):**
1. Brief the rules once. Hand them the rule summary sheet. Then step back.
2. Do not explain further. Do not help. Do not clarify. Confusion is data.
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

Assess which path best fits the hypothesis, then ask with the question tool, with your
recommendation stated first. Ask it even when the person named the engine or says it is the
only one they have: the browser sketch is one of the options now, never promised for later.

- **Prompt**: "Which prototype path would you like to use? (Based on your concept, I'd recommend [path] — [one sentence reason].)"
- **Options**:
  - `Engine — native prototype` — action, platformer, physics, or anything where feel is the hypothesis. Several iteration rounds are normal. Needs the engine installed.
  - `Paper — rules document + play log` — strategy, economy, logic, board-game-style mechanics. Cannot validate feel.
  - `Browser sketch (not recommended here)` — a playable one-folder browser game, built in one go. This project names an engine, so the sketch is thrown away when the engine build starts; it suits testing the loop before the engine is installed, not feel.

**Browser sketch chosen:** go on at One-shot 1 with this concept's question, then Phases 6-9.

---
