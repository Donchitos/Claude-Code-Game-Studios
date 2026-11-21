# /prototype — One-shot 4: Change it

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

The person has played and asks for a change. Make it without touching what they love, keep the
brief in step, and make each change they accept a checkpoint they can go back to. The asks in one
message are one change, unless they ask to split it into rounds (section 4).

**In this file:** 1 Which game · 2 Read again · 3 Their hand edits · 4 Check the ask · 5 Make the
change · 6 Keep the brief in step · 7 Check before accept · 8 Accept or undo · Going back ·
Share it

## 1. Which game

The game just handed over, or the one the person names. Its brief is `prototypes/<name>/brief.md`,
and `design/game-brief.md` too while that is the same game's (`one-shot-files.md`, The folder).
A change shown and not yet accepted or undone is answered first: ask again before the next one.

## 2. Read again

Before each change, read the game's brief by section, and read the person's
references as `one-shot-files.md` says: `notes.md` again, and any file added since the build.

## 3. Their hand edits

Run `git status --short -- prototypes/<name>` and `git diff HEAD -- prototypes/<name>`, adding
`design/game-brief.md` to both when it is this game's. A change there you did not make is the
person's hand edit: keep it, never undo it, and name it in the Changed line (section 8).
A hand edit that moves a pinned Keep value moves its pin too: say so. Files in `evidence/` are the
checks', never hand edits. With no commit to compare with, say once: "Hand edits are not tracked:
nothing is committed yet."

## 4. Check the ask

Before you change anything, check the ask against the brief's Keep, then Avoid, then Out of scope:

- **Keep:** an ask that changes what a Keep line names, or moves one of its pins: ask first, "This
  changes <the Keep line>. Change it anyway, or keep it and <another way>?"
- **Avoid:** an ask that goes against an Avoid line: ask the same way.
- **Out of scope:** an ask for something the brief leaves out: ask whether to bring it in.

On a yes the brief changes with the game (section 6): the Keep line and its pins rewritten or
taken out, the Avoid line taken out, the item moved to Features. An ask none of them touch goes
straight on. With nobody there (the autonomous automation mode), leave the line as it is, make the
ask another way or not at all, and log why.

**A big ask goes all at once.** When the note asks for more than one change beyond tuning, or for
one big one (a new roster or faction, many new units or levels, a rebalance across every matchup,
a new look), make it all at once, with no time or cost estimate.

**A change does what the note says.** Offer a bigger rework only when they ask for one, and never
recommend one.

- **They ask to split it** (now or before you start): make the first round as this file says,
  accept or undo it, and hand back to play. The next round waits for their word, and their notes
  after play may change it. Never offer or suggest rounds yourself.
- **Tuning, or one small change** (a fix, one new thing) goes straight on.
- **Nobody there:** make it all at once.

Note the clock (`date +%H:%M`) when you start making a change: asked how long it is taking, answer
as `one-shot-2-build.md` section 1 says.

## 5. Make the change

- Tuning goes into `config.js`'s values (`one-shot-files.md`), never into the game's code.
- **Too easy, or every part the same:** add at least one rule that raises the pressure or gives a
  new choice (a threat that escalates, a chase, a new hazard or tool), then move numbers. Numbers
  alone do not answer this note.
- **Values from the tweak panel:** a pasted block that starts `Tuned in the panel: <name>` is a
  change to that game. Run `bash .claude/scripts/one-shot-tune.sh prototypes/<name>` with each of
  its lines as an argument in quotes, and `--why "<their words>"` when they said why. It writes
  each value into `config.js` with its feel-log line, and its rows name what it left alone:
  `moved` (config.js changed since they tuned: ask which to keep), `out_of_range`, `unknown`, and
  `unreadable` (a value spread over lines: write that one yourself). A tuned value that moves a
  pinned Keep value moves its pin too, as their hand edit does: say so. Asked to keep their
  tuning with no block, say: "Press ` in the game, then Save, and paste what it copies here."
- **The tweak panel on request:** when they ask to tune it themselves ("let me tune it", sliders),
  and the game has no `tune.js`, run `bash .claude/scripts/one-shot-new.sh <name> --add tune.js`
  and wire it as its opening comment says. Then tell them: "Press ` in the game for live sliders;
  Save copies the values: paste them here to keep them."


- The build's rules still hold: who wins (`one-shot-1-card.md` section 1) and Never (`one-shot-files.md`).

## 6. Keep the brief in step

With every change, in the game's brief (both copies while they are the same game's):

- **In your words:** add what they said, word for word, on a line that starts `After play:`. What
  is there already is never rewritten.
- **Keep:** each thing they say they love becomes a line in their words, marked *(you said)*, then
  the `config.js` values behind it as they are now, when there are any:
  `- the dash feels snappy *(you said)* · pins: dash_speed 14, dash_time 0.12`
  A line with no value behind it ("the music") has no pins. Never add a line they did not say, and
  never move a pin without their yes or their own hand edit.
- **Avoid:** each thing they turn down ("no screen shake") becomes a line in their words.
- **Features, Controls and the rest** change to match the game; a feature added is `[x]`.
  A system added goes on Your systems as `in the slice`.

Their best moment in the debrief, and anything they say they love while they play, become Keep
lines the same way, with or without a change.

## 7. Check before accept

A light check of what the change touched. The first build ran the small check; a change does not
run it again. N is the iteration number section 8 counts.

1. **Keep:** `bash .claude/scripts/one-shot-check.sh prototypes/<name> --keep` reads the brief's
   pins against `config.js`, with no run. Its rows:
   - **`changed` or `gone`:** the change moved or removed a value a Keep line pins. Put it back, or
     ask as in section 4.
   - **`unpinned`:** read the change against that line yourself, and say that you did.
   - **`unreadable`:** a pin the script could not read: write it again as `<key> <value>`.
   - **`not_assessed keep`:** the Keep list was not checked; say why, from the row.
2. **Play it once, always:** `bash .claude/scripts/one-shot-run.sh prototypes/<name>
   prototypes/<name>/evidence/iteration-<N>-play.png --log "<inputs>"`, the inputs a few seconds
   that leave the title and use what the change touched. Errors are any `crash`, `error`,
   `nonfinite` or `console` row, or `uncaught` above 0. An error the change caused: fix it and
   play once more. Once: what is still wrong goes in the block as it is. A `not_assessed` row
   (no browser): the block says "not checked: <why>", never "none".
3. **Look at what the change touched.** Each shot is `one-shot-run.sh prototypes/<name>
   prototypes/<name>/evidence/iteration-<N>-<what>.png --log "<inputs>"`, the inputs that reach
   it (`--stop <step>` from the play run's `scene` rows):
   - **Text or screens:** a shot of each screen it touched, and one of them again with `--size
     800x450`, a small window, where text spills first.
   - **New content:** a shot of each new thing in play.
   - **Balance:** no runs; the change says which `config.js` values moved, and the person's next
     play is the check.

   About 5 minutes in all. Write no robot player, probe or headless play of your own; never rerun
   the whole small check. What these runs cannot show, the block says is not checked, and the
   person's next play covers it.
4. **Record it:** add a line to `prototypes/<name>/evidence/changes.tsv`: `iteration <N>` TAB
   `<what changed>` TAB `errors: none`, the error rows, or `not checked: <why>` TAB `<the shots'
   paths>`.

**A game brought in by the door** (`evidence/door.md`) has no check hook. Step
1's `not_assessed keep` row for no `config.js`: read the change against each Keep line yourself,
and say that you did. Step 2 is `bash .claude/scripts/door-in.sh --shots <name> --check`: the
door's four runs again, with `evidence/baseline/inputs.txt`. Errors are its `errors` rows above
0, and a `not_assessed` row is "not checked: <why>". Each `differs` row is a screen that is no
longer as it came in: look at it, since a change can move it on purpose. Step 3's shots are `one-shot-run.sh prototypes/<name>
<png> --hookless --log "<inputs>"`, the start and play inputs from `inputs.txt`, cut to reach
the screen.

## 8. Accept or undo

Show the 1 to 3 shots that show the change best, then this block:

```text
Changed: <what, from → to>
Errors: none | <each, in a few words> | not checked: <why>
```

Ask with the question tool: "Accept this change? It becomes checkpoint iteration <N>." Options:
Accept / Undo it. The question is the last thing in the reply.

- **Accept:** `git add prototypes/<name>`, with `design/game-brief.md` when it is this game's, then
  `git commit -m "iteration <N>: <what>" -m "Brief: <the brief's path>" -- <the paths added>`:
  the paths keep every other file out of the commit, staged or not. N is one more than the
  iteration commits in `git log --oneline -- prototypes/<name>`. A change that adds something
  new (a mode, levels, saves, menus, a system) is `iteration <N>: added <what>`. With no git,
  say "Not a checkpoint: this project has no git." Say in one line what happened.
- **Undo it:** put back each edit you made for this change, the brief and the feel log included;
  their hand edits stay. Say "Undone".

**Growing.** When they say grow it: `SKILL.md`, One-shot 5.

Then go back to where you were: the debrief's next question, or the person's next ask.

## Going back

"Go back to iteration 2", or to the first build: the checkpoint is a commit in `git log --oneline
-- prototypes/<name>`, or the tag `one-shot/<name>` (`baseline/<name>`: a game brought in, as it
came). Uncommitted changes in the game's files would
be lost: ask first. Then run `git restore --source <commit> -- prototypes/<name>`, with the brief
when it is this game's, run the light check (Check before accept), and commit as
`iteration <N>: back to <checkpoint>`.
Going back is a checkpoint too.

## Share it

Asked to share or export the game, run `bash .claude/scripts/one-shot-share.sh prototypes/<name>`.
It makes `prototypes/<name>/dist/`, the game as a player gets it: the tweak panel (`tune.js`) and
the working files (the brief, the feel log, the report, `evidence/`) are left out, and
the page's `tune.js` tag is taken out.
Give the folder's path; for itch.io, zip what is inside it.
A `found` row is a `tune.js` reference the script could not take out: take it out of the game and
run it again. Share `dist/`, never the game's own folder.
