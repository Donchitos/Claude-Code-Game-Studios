# Game Brief: [Working Title]

<!--
THE ONE-PAGE BRIEF. At the `minimal` workflow tier this is the ENTIRE design doc —
it replaces the full concept doc, systems decomposition, and per-system GDDs. It is
also the one-shot's prompt: /prototype builds from it, whatever the rigor.
Keep it to one screen ("In your words" does not count). If a field needs a second
paragraph, you're writing a GDD, not a brief. Six fields are REQUIRED: Pitch, Core
loop, Goal & fail state, Features, Out of scope, Build order. The one-shot also
fills Look and references, First minute and Challenge: the brief is what it builds
from, and those three are what a good brief has that a vague one lacks. The other
lines are cheap: fill them when known, and the one-shot guesses, and marks, any it needs.
Engine is set separately
(project.yaml / /setup-engine) and the goal is `project.goal` — don't restate either.

Headings and marks stay in English whatever language the person writes in, so
/cut and the door can read any brief. A field the person did not give is marked:
*(guessed)* or *(inferred (strong))* for what was worked out, *(provisional)* for an
answer to "you pick". Unmarked means they said it.

Briefs from before 1.3.0 still read: MVP is Features (unmarked), One-sentence pitch
is Pitch, Player goal & fail state is Goal & fail state, Art & audio direction, Label
and Art direction are Look and references, Reference game is Games you love / don't.

Field set grounded in industry practice — Tim Ryan (*Anatomy of a Design Document*),
Stone Librande (GDC *One-Page Designs*: the one-page constraint forces the real
thinking and cuts ceremony), and lean/agile GDD practice.
-->

## In your words
<!-- The person's own description, word for word: what they typed, their answers to the quick questions, or a longer doc in full. Never rewritten, never summarised; every later change is checked against it. Empty when they said only "you pick". After play, what they say is added on lines that start `After play:`. -->

**Pitch:** [The game in one excited sentence. If it takes two, cut until it's one — "the longer your pitch, the more diluted your vision."]

**Genre:** [e.g. "maze chase", "roguelike deckbuilder"]

**Controls:** [How you play, on which keys or inputs. e.g. "arrow keys to steer, space to dash."]

**Question:** [What the prototype must answer. e.g. "is dodging through a crowd fun for ten minutes?"]

**Hooks:** [The signature hook or hooks: the thing that makes it this game and not its genre.]

**Intent:** [Usually empty. Only these entries, each with its source — you said, from <reference>, or provisional: no goal to reach · soft or no failure · payoff builds · staged failure · needs N players · outside the window]

## Look and references
<!-- How it looks, in words, so the build draws it as named: the view (2D, 2.5D, 3D) and the camera, the shapes, the palette with its roles, and one signature detail (`.claude/genres/art-direction.md`). Then the reference games, each with what it gives. Every figure drawn: no emoji, no plain circles. -->
- Look: [e.g. "warm painterly low-poly medieval; small readable villagers; night turns blue-dark with pools of torchlight; every figure drawn, never emoji or plain circles."]
- References: [e.g. "Manor Lords (the town and the hauling), The Settlers II (goods visible on the roads)."]
- View: [2D, 2.5D or 3D] · Camera: [e.g. "angled top-down, about 50 degrees, with pan, zoom and rotate."]

## First minute
<!-- What the player sees and does in the first 60 seconds, step by step, ending on the first moment the hook pays off. Taught by doing, never by a wall of text. A short paragraph. -->

## Challenge
<!-- When the first real trouble arrives (a minute range or a wave), what it is, what a loss costs, and what changes later. The game is never trivially easy. A short paragraph. -->

## Core loop
<!-- The cycle the player repeats. What they do → what they get → why they do it again. 2–4 bullets. -->
-

## Goal & fail state
<!-- What the player is trying to achieve (the win, the score, or the point) and how a run ends or fails. Even a cozy or sandbox game has a "a session feels complete when…". This is the one field your stories' ACCEPTANCE CRITERIA trace back to — it turns "the game works" into something testable. One or two lines. -->
-

## Features
<!-- The ruthlessly short list without which this ISN'T the game yet. `[x]` built, `[ ]` not yet: the one-shot marks what it built, and /create-stories writes a story for each `[ ]` item. Longer than ~7 and it's not an MVP. A system on Your systems shows here at its mark: a `thin stand-in` one ending `(thin stand-in)`, a `later` one not at all. -->
- [ ]

## Your systems
<!-- Every system the person named (combat, a shop, crafting, day and night...), one a line in their words, each with one of three marks: `in the slice` (built for real in the first build), `thin stand-in` (there and wired to the rest, at its simplest) or `later` (not built yet; Out of scope has it with its step). Left out when they named no system. The line format is fixed, so the step that plans stories can read it in order: `- <system> · in the slice` | `- <system> · thin stand-in` | `- <system> · later`, then *(guessed)* when Claude Code Game Studios chose the mark. -->
-

## Keep
<!-- What the person loves in the game as built, in their words; never changed without asking. Empty until they have played it. Each line ends with the config.js values behind it, when there are any: `- the dash feels snappy *(you said)* · pins: dash_speed 14, dash_time 0.12`; the self-check flags a pinned value that moved. -->
-

## Avoid
<!-- What they don't want: every removal in their words ("no combat", "no waiting") and anything they rejected. Every guess, reference and default respects it. -->
-

## Out of scope
<!-- What you're deliberately NOT doing. The list that saves the project. Be specific: "no multiplayer", "no save system", "one level only". A Features item cut with /cut moves here as `- [-] <item> · cut: <reason> (<date>)`. -->
-

## Build order
<!-- The sequence to build the Features. Risky / core-fun thing FIRST — prove it's fun before you polish. Step 1, with the goal and the way to lose, is the one-shot's slice. -->
1.

---
<!-- One line each: cheap but optional. The one-shot guesses any it needs. -->
**Kill condition:** [When to drop the prototype, not how the player loses. e.g. "if steering still feels floaty after two tuning rounds."]

**Who it's for / what they feel:** [One line: the player and the feeling. e.g. "solo puzzle fans who want a cozy 20-minute sitting."]

**Games you love / don't:** [Any number, each with a word on why. e.g. "Love Vampire Survivors (the auto-attack loop); don't love Brotato (too busy)." A clone is said in the person's words: "a clone of Pac-Man".]

<!-- /cut adds a Dates line here when the goal is sell, early_access or publisher: `**Dates:** target <date> (<release, Early Access launch, or pitch or demo>) · freeze <date>`, ISO dates. Recorded, never enforced yet. -->
