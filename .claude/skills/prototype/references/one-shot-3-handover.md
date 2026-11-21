# /prototype — One-shot 3: Hand over

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

Hand over in this order, in one reply: the screenshot and the card, then the commit question as
the last thing. The play (section 3) starts only after the person answers it.

**In this file:** 1 The handover card · 2 Commit and tag · 3 Play it, then the verdict

## 1. The handover card

The build's report (`one-shot-2-build.md` section 6) holds what the card needs. Check that
`evidence/check-run.yaml` is there: the build recorded its small check. Then mark the
brief's Features, in `design/game-brief.md` and its copy `prototypes/<name>/brief.md`: `[x]` for
each item the brief checklist passed (`evidence/checklist.tsv`), `[ ]` for the rest; a promised
one still missing goes on Still to do.
When `design/game-brief.md` is another game's, mark the copy only (`one-shot-files.md`, The folder).
Show the play screenshot, then the card as this text block, line for line, with each line's name
as written. Anything more goes below the card, never in its place:

```text
How to play: <controls>
Open: prototypes/<name>/index.html
Tune: say "let me tune it" for live sliders
Small check: passed <rows> · failed <rows> · not assessed <rows> (why)
Brief checklist: <passed> of <items> pass
  fail <id> <the item's first words>: missing | broken
  not assessed <id> <the item's first words>: <why>
Fixed: <each fix the small check made: what changed>
Nearest game: <name>; this one differs in <what>
Not as you said: <a brief word missed>: <why>
Still broken: <what>
Still to do: <promised but missing>
References: <file> for <what it set>; <sound or link> (note only: not heard | not watched); <n> images not looked at
Guessed: <what the build decided that the brief did not say>
Effort: <the build's effort>
Built in <minutes> minutes
Next: play it first; then /setup-engine <engine>, and /prototype --path engine for what only the engine can answer
Not yet played by a person.
```

The Brief checklist shows every item that is not a pass, one a line; with all passed, the one
line alone. Any stuck screen, overlap or error left after the fix round goes on Still broken.
The Effort line is the build file's true one: `this session's`, `<effort> (set on the builder)`
or `set by CLAUDE_CODE_EFFORT_LEVEL`.
Leave out the Fixed, Not as you said, Still broken, Still to do and Guessed lines when they are empty,
and the Next line unless the brief's Engine line named an engine for after play, the brief's Out
of scope has online play or a later system with its step. For online play, the
Next line adds: `real online play needs a server, enough players to fill a game, and money each
month to run it: not built yet`, after the engine's part when there is one. For each later
system with its step, the Next line adds `<it>: <its step>` ("a career of cups: grow it"). A
row that could not run is named not assessed with why; with no browser: "Small check: not
assessed boots, shot, outlines (no browser here)", and with one that stopped, the same
with "(the browser stopped: <its FATAL line>)". "Built in" counts from the `time` row of
`one-shot-new.sh` to that of the build's last check. A served 3D game's Open line is the
`serve` command instead. "Not yet played by a person" stays until the person has played it:
nothing you ran judges whether it is fun.

The References line shows only when the person's references gave the build something: each one
used and what for ("cave-ui.png for the HUD and palette"), a sound or clip link with its "(note
only: not heard)" or "(note only: not watched)", and how many images were past the eight looked
at.

When the brief names a reference game and Your goal is `sell`, `early_access` or
`publisher`, add one line: the reference's name, art and logos cannot ship, and you can make
original replacements. Say it once; it never holds anything up, and learning and jam games need
no line.

## 2. Commit and tag

The first build is the point every later change can go back to, so it gets a commit and the tag
`one-shot/<name>`. Run `git rev-parse --is-inside-work-tree` to see whether the project has git.

Ask with the question tool: "Commit this first build and tag it `one-shot/<name>`, so any later
change can be undone back to it?" Options: Commit and tag / Not now. With no git, the first
option is "Start git here, commit and tag". The question is the last thing in the reply.

On an explicit yes only:

1. With no git: `git init`.
2. `git add prototypes/<name> design/game-brief.md` (the brief when this build wrote it or marked
   its Features).
3. `git commit -m "feat: one-shot <name>" -m "Brief: design/game-brief.md" -- <the paths added>`:
   only those paths go in, whatever else is staged.
4. `git tag one-shot/<name>`.

Then, on a yes or a no, in this same reply:

1. Say in one line what happened: "Tagged one-shot/<name>", "Not committed", or the step that
   failed and what it printed.
2. Go on to section 3 with this game.

## 3. Play it, then the verdict

Say exactly this, with the card's Open line:
> "The game is ready. Open `prototypes/<name>/index.html` in your browser and play it. Take as
> long as you need, the way a new player would. Come back here when you're done."

**As they answer:** a change they ask for, at any point, goes to One-shot 4
(`references/one-shot-4-change.md`), and this section goes on after it. Their best moment, and
anything else they say they love, become Keep lines in the brief (that file, section 6): write
them and say so in one line. When they say they hate the game, it is still the game they have:
offer to fix what put them off (recommended), pivot it or kill it, and ask what put them off most
when they have not said; a fix goes to One-shot 4. A one-shot made before an engine was set, with
an engine other than Web set now: on a love-it or a Keep going, never offer to move it into that
engine or rebuild it there: say the one line One-shot 5's section 1 gives.

**Once they have played,** ask two things, one at a time, and nothing else:

1. In plain text: "What was the best moment, and the worst?"
2. With the question tool: "Keep going with it, change direction, or drop it?" Options:
   `Keep going` / `Change direction` / `Drop it`.

A vague answer gets one follow-up at most. Then, in one reply:

- **Keep going:** One-shot 5 (`SKILL.md`): its one question, keep iterating or grow it.
- **Change direction:** ask in plain text, "What should the next version keep, and what should
  change most?", write `prototypes/<name>/PIVOT-NOTE.md` from the answer (what to keep, what to
  change: the next brief reads it), then offer the next game: `/prototype <the changed idea, in
  their words>`.
- **Drop it:** say in one line that it is dropped and the game stays in `prototypes/<name>/`,
  then offer `/brainstorm` for another idea.

**Nobody can play it this session:** ask for no verdict and infer none from how it looks. Say it
is built and not yet played, and that saying "I've played it" brings back this section.

Write no report, prototype index or other notes: the card, the brief's Keep lines and the
commits are the record.
