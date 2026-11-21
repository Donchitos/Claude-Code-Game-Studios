# /reverse-document — brief: from a game

> Part of `/reverse-document`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

Reads a browser game someone already made (one `.html` file, or a folder with `index.html`) and
writes its brief, the 1.3.0 one-page shape (`.claude/docs/templates/game-brief.md`), with the
Features it has marked built, so the next story is new work and never a rebuild. It says what it
could not read, by name, instead of guessing. Run as `/reverse-document brief <file or folder>`,
or read by `/prototype`'s door (One-shot 0) for a game it just brought in.

**In this file:** 1 Read what is there · 2 Enough to go on? · 3 Read the code · 4 Look at it ·
5 The brief · 6 The record · 7 Show it and write

## 1. Read what is there

```bash
bash .claude/scripts/game-read.sh <file or folder>
```

It writes nothing. Keep its rows: `title`; `script` (each script, with its length); `minified`;
`network`, `server`, `missing`; `loop`; `input` (with the key codes its file names); `count`
(`Math.random`, `Date.now`, `performance.now`); `save`; `sound`; `other`; `states`; `todo`;
`tune`. A README or notes file beside the game is a source too: read it, name it, never paste it.
Screenshots of it, when the door took them, are in `<folder>/evidence/baseline/`.

## 2. Enough to go on?

The skill's Phase 3b, for a game:

- **`loop none`:** no frame loop and no timer, so there is no game loop to read. Say so: "I can't
  find a game loop in it, so I can only describe what the page shows." The brief keeps the page's
  title and what the screenshots show; Features stay empty, with why.
- **Every script `minified`:** its rules cannot be read. Features come from the screenshots only,
  each *(guessed)*, and the card says so.
- Otherwise go on.

## 3. Read the code

Search, then read by range, in this order: the title; the loop; the input handlers (Controls);
the state or scene names and what moves between them (Core loop, Goal & fail state); win and
lose conditions; the named numbers and config objects (the tuning values a later `config.js`
move would carry); sound; saves; network calls. A file too long to read whole is read by
sections. Note each range you read, and each one you did not.

**A Feature is `[x]` only with evidence:** where it lives in the code (`file:line`), and, when a
screenshot shows it, which one. Count, never judge: the `count` rows go into the record as they
are.

## 4. Look at it

Look at the screenshots (`first.png`, `start.png`, `play-10s.png`, `play-30s.png`): the Pitch,
the look and sound in words, and what is visibly there. No screenshots: say so in the record.

## 5. The brief

Under the title, the skill's banner, naming the game's folder and, for a game the door brought
in, the tag `baseline/<name>` in place of a commit. What the code cannot say is
`INTENT UNKNOWN`. Each field carries the template's marks; unmarked only when the person said it.

| Field | From |
|---|---|
| In your words | what the person wrote about the game, word for word; a README is a source, named, not pasted |
| Pitch, Genre, Hooks | the code and the screenshots *(guessed)*; *(inferred (strong))* when the title or a README says it |
| Look and references | the game's own look in words, from the screenshots *(inferred (strong))*: view, camera, shapes, palette; References: a game it plainly follows *(guessed)* |
| First minute | what the screenshots and the start state show the player seeing and doing first *(inferred (strong))* |
| Challenge | when its first lose condition can fire, and what makes it harder, from the code *(inferred (strong))*; empty with why when it has no way to lose |
| Controls | the `input` rows and their handlers *(inferred (strong))* |
| Question | empty: it was not built to answer one |
| Core loop, Goal & fail state | its states and their win and lose conditions |
| Features | `[x]` each thing it does, with evidence (section 3); `[ ]` only from the person's words, or a plain to-do in the game (a `todo` row, a "coming soon" button) *(inferred (strong))* |
| Keep | empty: the person says what they love. Each answer becomes a Keep line *(you said)* |
| Avoid, Out of scope | the person's words only, else empty |
| Build order | step 1: the game as it came in, all `[x]`; then the `[ ]` items |
| Games you love / don't | a game it plainly copies or follows *(guessed)* |

**Not read, said by name** (in the brief's `INTENT UNKNOWN` lines and in the record; never
guessed):

| Row | Say |
|---|---|
| `minified` | its rules were not read; Features from the screenshots, *(guessed)* |
| `network` | that file was not copied, and the game needs the network to play it; a copy in `vendor/` can be made later, with a yes |
| `missing` | the page asks for it and it is not there; the screenshots show what that does |
| `server` | the server is not here; name what needs it |
| `other` | workers, iframes and service workers were not read |
| a range not read | by line range |
| why anything is as it is | `INTENT UNKNOWN`, never written into Keep |
| how it feels, whether it is fun | not read from code: Keep comes from the person |

## 6. The record

For a game in `prototypes/<name>/`, add a `## Read from the game` section to its
`evidence/door.md` (made when missing): what was read (files and line ranges), where each `[x]`
lives and which screenshot shows it, the not-read list, the tuning values found (name, value,
`file:line`), and the `count` rows. A game outside `prototypes/` keeps the record at the end of
the brief's draft, under `Read from the game`, and nowhere else.

## 7. Show it and write

Show the brief and the record's not-read list, then ask: "Write this brief?" (`Looks right` /
`Change something`). Corrections go into the brief *(you said)*; intent is not asked one question
at a time. Writes: `prototypes/<name>/brief.md`, and `design/game-brief.md` when there is none
or this becomes the game being worked on; the record. Only after the yes.

Then name the next step in plain words: every `[ ]` item is new work. A change to the game itself
is asked for as any change is (`/prototype`, for a game in `prototypes/`); `/create-stories`
writes one story for each `[ ]` item, and none for an `[x]` one.
