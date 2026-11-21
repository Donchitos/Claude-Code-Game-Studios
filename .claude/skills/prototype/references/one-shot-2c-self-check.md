# /prototype — One-shot 2c: The small check

> Part of `/prototype`. The build file names when to read this file.

**In this file:** 1 Write the brief words · 2 Run it · 3 Read the rows, fix once · 4 The brief
checklist · 5 Record the results

Before the report, a few cheap fixed checks: the game opens with no errors, a screenshot of play
was looked at against the brief, a few scripted keys show it responds, the person's words are
built, and nothing is drawn with emoji. About 5 minutes of checking in all. It is a smoke test,
not a judgement of fun or difficulty: the person's play after the handover is that check. Write
no robot player, and never tune the challenge by a script; difficulty comes from the genre's
starting values and the person's notes after play.

| # | Row | Passes when |
|---|---|---|
| 1 | boots | the run shows no `crash`, `error`, `nonfinite` or `uncaught` above 0, and no blank screen |
| 2 | shot | a screenshot of play is on disk in `evidence/`, and you looked at it |
| 3 | brief words | every look, view and reference word in In your words is in `evidence/brief-words.tsv`, and `evidence/nearest-game.txt` names the nearest game and how this one differs |
| 4 | emoji and outlines | no emoji in the game's code, and `evidence/figures.png` shows every enemy kind and unit with its own outline |

## 1. Write the brief words

`evidence/brief-words.tsv`: one line for each look, view and reference word in In your words
("2.5D", "isometric", "flat vector", "like Manor Lords"): `<word>` TAB `<how the game shows it>`
TAB `<the shot that shows it>`, or `<word>` TAB `miss: <why>`.

## 2. Run it

```bash
bash .claude/scripts/one-shot-check.sh prototypes/<name> --keys "<inputs>"
```

`--keys` is a short run in `one-shot-run.sh --log`'s format: what leaves the title (`Enter`,
`click:text=Start`), then a few seconds of the game's own keys (`ArrowRight:1.5 Space wait:1`).
It plays once from a fresh start, screenshots where it stops (`evidence/play.png`), measures the
text on that screen, and plays the keys again against no input to see the game responds. It
writes `evidence/self-check.tsv`. Then shoot the figures:

```bash
bash .claude/scripts/page-shot.sh prototypes/<name>/index.html prototypes/<name>/evidence/figures.png --query scene=figures
```

`not_assessed` rows say what could not run and why: no browser, a browser that stopped, a served
3D game, or the starter's check hooks removed. Fix what is yours (put the hooks back); a row that
still cannot run is *not assessed* by name in the report, never passed. Never change the game so
a check can run, and never debug the check's scripts. A `capped` shot was taken again in real
time: use that picture.

## 3. Read the rows, fix once

- **Look at `play.png`** and at `figures.png` against the brief's Look and references: the view
  and camera as named, every figure drawn, no two enemy kinds or units with one outline.
- **`crash`, `error`, `nonfinite`, `uncaught` above 0, `console` errors, a blank `screen`:** fix.
- **`responds same`:** the keys changed nothing in play. Check the keys first (the game's own
  controls, after what leaves the title); a game that ignores its own controls is a fix.
- **`text`** outside the window, under 14 px at 1080p or under 3:1 contrast, and **`overlap`**
  (two texts sharing a quarter of the smaller's box): move, size or space them.
- **`stuck`, `noexit`, `norecover`:** the screen froze while input went in, an end screen kept
  the player, or a staged failure never recovered: fix.
- **A `briefword ... unlisted` row:** build the word, or list it with `miss: <why>`.
- **An `art emoji` row:** draw it instead.
- **No `evidence/nearest-game.txt` line, or one naming no game:** write the build rules' line,
  a real game and what this one changes. The check reads the note only; it never judges a copy.

One fix round, with section 4's fixes in it, then the check once more. What still fails goes in
the report as "Still broken: <row>: <what>". The check refuses a third run in a round: a fix
after that is checked with the one run it needs (`one-shot-run.sh`, `page-shot.sh`), never the
whole check again.

## 4. The brief checklist

Every Features item, First minute sentence, Challenge sentence and Look and references line of
the brief is an item, and so is each `in the slice` and `thin stand-in` line of Your systems (a
stand-in passes when it is there and works at its simplest; a `later` one is not an item; a
`conflict` row is a Features item promising a system past its mark: fix the brief):
`one-shot-check.sh prototypes/<name> --checklist` lists them with their ids (F1, M1, C1, L1,
S1...). Write `evidence/checklist.tsv`, a line each: `<id>` TAB `pass`, `missing`, `broken` or
`not_assessed` TAB `<evidence>` TAB `<what you saw, or why it could not be checked>`. The
evidence is a shot already on disk that shows it, or the place in the game's code that builds it
(`index.html:214`). Take no new run per item. `pass` is "it is there and does what the line
says", never "it feels right". An item still not there after the fix round stays `missing` or
`broken` and goes on the card. An item no shot or line of code can show (a sound, a feel line)
is `not_assessed` with its why, never a pass.

## 5. Record the results

```bash
bash .claude/scripts/one-shot-check.sh prototypes/<name> --record boots=pass shot=pass outlines=pass
```

Each of the three is `pass`, `fail`, or `not_run:not-assessed:<why>`. The script reads brief
words, emoji and the checklist itself, records the step time as a measure, and refuses a pass
its rows do not show, an unlisted checklist item or a pass with no evidence, saying why: fix
that and run it again.
