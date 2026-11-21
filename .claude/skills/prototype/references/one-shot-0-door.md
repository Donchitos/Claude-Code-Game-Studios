# /prototype — One-shot 0: Bring it in

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

The person already has a game that runs in a browser: one `.html` file, or a folder with an
`index.html`. This brings a copy in, exactly as it is, so it can be changed, tuned and grown like
a one-shot. The original is only ever read: nothing in it is edited, moved or deleted.

**In this file:** 1 When it runs · 2 Look first · 3 The one question · 4 Copy, commit, tag ·
5 Screenshots · 6 The brief · 7 Where its files came from · 8 Exports from an engine or tool ·
9 After the door

## 1. When it runs

`/prototype --from <path>`, or a message that brings a game without it (a path to a game,
"bring in my game"). `/start` sends people here when it finds a game in the project.

## 2. Look first

```bash
bash .claude/scripts/door-in.sh <path> --dry-run
```

It writes nothing. Its rows say what it found:

- **`kind game`:** go on. The `name` row is the folder it will use (from the page's title), the
  `file` rows each file with its size, `skipped` what is left out and why, `big` a file over 50
  MB.
- **`kind export <what>`:** made by an engine or tool (Godot, Unity, Construct, Twine...): section 8.
- **`kind web_project`:** it has a `package.json`, so it has its own build. Say: "This is a web
  project with its own build. `/setup-engine web` sets Claude Code Game Studios up around it as it is." Stop.
- **`kind not_a_game`:** say what is missing in plain words ("I can't find a game in it: the page
  has no script") and ask for the right file. Stop. When the `refused` row names the folder's page
  (a game saved as one page with its own name), ask whether to bring that page in; on a yes, this
  step again with its path.

## 3. The one question

Ask with the question tool: "Bring <the page's title> in as `prototypes/<name>/`, exactly as it
is, committed and tagged `baseline/<name>`?" Under it, in plain lines: how many files and how
big, what is left out (`skipped`), any file over 50 MB, and when the original is inside this
project, that it stays where it is and the copy is the one you will change.

- Options: **Bring it in** / **Not now**. With no git: **Start git here and bring it in** /
  **Bring it in without git** / **Not now**.
- This one yes covers the copy, the commit and the tag. Ask nothing else before section 6.

## 4. Copy, commit, tag

```bash
bash .claude/scripts/door-in.sh <path>
```

It copies every file byte for byte (a single file becomes `index.html`), checks each copy's
SHA-256 against the original (`copied <n> same`), and tells git to keep the game's bytes as they
are (`attributes`). Then, with git:

1. `git add -- prototypes/<name>`
2. `git commit -m "feat: bring in <name> as it is" -- prototypes/<name>`: only the game's files.
3. `git tag baseline/<name>`
4. `bash .claude/scripts/door-in.sh --verify <name> <path>`: every `verify` row must say `same`.
   One that differs or is missing stops the door: say which file, and that nothing else was done.

Without git: say "Not a git project: your original is the backup, and there are no checkpoints."

## 5. Screenshots

The game is played a little, untouched, so every later change can be checked against how it
came in. First read its controls in the code: the keys its `keydown` listeners check, which one
starts a game (`Enter`, `Space`, a click) and which move and act. Then:

```bash
bash .claude/scripts/door-in.sh --shots <name> --start <start keys> --play "<a few seconds of play>"
```

`--play` is an input log as `one-shot-run.sh` reads it (`KeyW:1 KeyJ KeyD:1 Space`), repeated to
fill 30 seconds. A game started by a button, or by a menu of buttons, takes
`click:text=<its words>` (underscores for spaces: `click:text=Start_game`), which scrolls the
button into view first; a run's `text` rows say what words the page shows and where. It plays a temp copy four times the same way, with no change to the game: the
first screen, after the start key, and after 10 and 30 seconds of play, into
`evidence/baseline/` with the inputs. Look at the four pictures.

- **`blank`:** that screen drew nothing. Say so; a first screen that waits for a click can be blank.
- **`errors` above 0:** the untouched game threw errors; say so plainly. They are the game's own.
- **`not_assessed`:** that run could not play (no browser here, or a page that must be served);
  say which and why.

Then `bash .claude/scripts/door-in.sh --after <name> <path>`: it adds `assets/provenance.yaml`
(section 7), `evidence/door.md` (the record of where the game came from, with every file's
hash) and a line in the project's `.gitattributes` that keeps the game's bytes as they are in
any copy of the project. None of them changes a file the game brought.

## 6. The brief

Read `.claude/skills/reverse-document/references/from-a-game.md` and follow its sections 1 to 6
for `prototypes/<name>/`: it reads the game into the brief and its Features, built ones marked
`[x]` with evidence in `evidence/door.md`, and names what it could not read. Without that file,
the step is switched off: say so in one line, write `brief.md` with the title, the person's words
about the game, and the Features list left for them to fill in, and go on.

Then the card, with a line left out when it has nothing in it:

```text
<Pitch> · <Genre> · Controls: <controls>
Brought in: <source> → prototypes/<name>/ (<n> files, <size>) · tag baseline/<name>
Made with: <plain HTML and JavaScript | <library> from the network | ...>
Has: <the [x] Features> · Next: <the [ ] Features, or "tell me what you want next">
Keep: tell me what you love about it, and I'll never change it without asking
Origin: unknown for <n> files: tell me if you made them, and how
Fan game: <reference>'s name, art, characters and UI stay its owner's: build and learn freely, not to sell or publish
Not read: <each not-read item, with why>
Checked: <the four screenshots, and what they reached> · not assessed: <what, and why>
Writes: prototypes/<name>/brief.md, assets/provenance.yaml, evidence/, .gitattributes [, design/game-brief.md]
```

Ask before writing the brief: "Write this brief?" (`Looks right` / `Change something`). On the
yes, commit what the door added: `git add -- prototypes/<name> .gitattributes` then `git commit
-m "docs: brief and screenshots for <name>" -- prototypes/<name> .gitattributes`.
`design/game-brief.md` is written with it, as for any one-shot.

## 7. Where its files came from

Every file brought in is listed in `assets/provenance.yaml` with its `sha256` and `origin:
unknown`. Nobody knows yet whether it was made by a person, an AI or bought, so it stays unknown
until the person says. When they do ("I made it with Claude", "the music is from a CC0 pack"),
set those entries' `origin` (`ai` with `tool`, `you`, `cc0`, `licensed`).

**A fan game:** when the game uses a named game's name, characters, art or UI (its title, text
or files say so), the card shows the Fan game line above, whatever the goal. A game that
only plays like another needs none.

## 8. Exports from an engine or tool

A `kind export <what>` row means its code was made by that engine or tool, so changes belong in
the tool: an export changed here is lost on the next export. It comes in as a reference for a
remake instead:

- The same question, worded for it: "Bring <title> in as a reference in `references/<name>/`, so
  a new game can be made from it here?" Then `door-in.sh <path>` copies it there. No tag, no
  `config.js` offer.
- One screenshot of its first screen: `bash .claude/scripts/page-shot.sh
  references/<name>/index.html references/<name>-first.png`.
- A brief from what can be seen and read (Twine passages and Bitsy text are readable), then the
  offer: **Remake it here**, which builds a new one-shot from that brief (One-shot 1).
- For Godot or Unity also say: "To keep working on this game itself, bring its project, not the
  export, and run `/setup-engine`."

## 9. After the door

- **Tuning values** (after the brief): "Move its tuning values into `config.js`, so you can tune
  them with sliders? It becomes checkpoint iteration 1; the baseline stays as it came in." On yes:
  the numbers a designer would tune (speeds, damage, timings) become `window.CONFIG` entries with
  value, min, max and step (plus `seed` only when the game has a seeded random), the code reads
  `tune.<name>`, and the page gains the `config.js` and `tune.js` lines (`one-shot-files.md`).
  Then `bash .claude/scripts/door-in.sh --shots <name> --check` must say `same` four times: the
  game still plays exactly as it came in. Commit it as One-shot 4 commits a change. On no: it is
  changed without sliders, and not asked again unless they ask to tune.
- **Then** it is a one-shot after its handover: each change is One-shot 4's, a checkpoint each.
  Skip the play request in One-shot 3 section 3: they played it before they brought it.
- **Going back to the start:** `baseline/<name>` is how it came in (One-shot 4, Going back).
- **Claude Code Game Studios' game-state hook** (`window.game`) is not added by the door: it is a change the person
  can ask for, like any other.
- **Growing it** works as for any one-shot (One-shot 5).
- The door writes nothing to `project.yaml`.
