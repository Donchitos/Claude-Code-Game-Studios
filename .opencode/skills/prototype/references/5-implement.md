# /prototype — Phase 5: Implement

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Implement

Ask: "May I create the prototype directory at `prototypes/[concept-name]-concept/`
and begin implementation?"

If yes, create the directory. Every file must begin with:

```
[comment] PROTOTYPE - NOT FOR PRODUCTION
[comment] Question: [Core question being tested]
[comment] Date: [Current date]
```

Write `[comment]` in each file's own comment syntax — `#` in GDScript (`.gd`) and
Python, `//` in C#, C++ and JavaScript, `--` in Lua, `<!-- … -->` in HTML and
Markdown. A header in another language's syntax is a parse error, not a label.
Files that cannot hold a comment (JSON, engine-generated scene and project
files) are exempt.

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
