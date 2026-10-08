# /prototype — Phase 3: Choose the Prototype Path

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Choose the Prototype Path

**In this file:**

- Path: HTML (browser-playable)
- Path: Engine (engine project)
- Path: Paper (rules document + play log)

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
