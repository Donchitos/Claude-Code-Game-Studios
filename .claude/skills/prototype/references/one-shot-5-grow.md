# /prototype — One-shot 5: Grow it

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

On Keep going after play, a one-shot can become the start of the real game: a Vite and TypeScript web project
at the project root, with its values in data files, a rule under test, and a same-seed run that
proves it still plays the same. Everything is copied out of `prototypes/<name>/`; nothing there is
edited, moved or deleted, so the two can be compared and the one-shot is never lost.

**In this file:** 1 The question · 2 The guard · 3 Reference · 4 Copy · 5 TypeScript · 6 Rules
under test · 7 Record · 8 Handover · 9 One feature a sitting

Each step ends in one commit of only the files it wrote (`git add -- <paths>`, never `-A`), so
any step can be undone on its own. A failed check stops the grow at that step: say what
differed, in a plain line, and what is still as it was. With no git there are no commits or tags,
and the one-shot folder is the backup.

## 1. The question

Keep going after play (One-shot 3, section 3) runs the guard (section 2) first. An engine that is set and not
`Web`, or a root already grown, is not offered growing: one line says why ("the game stays a
prototype you can keep changing here: moving it into <engine> is not built yet", "this project already holds a grown game: this one keeps
iterating"), and they can ask for a change any time. Otherwise ask with the question tool, the one question:

"Keep iterating, or grow it into a real web project?"

- **Grow it**: "It becomes the start of the game here: TypeScript, its values in data files,
  tests, the build. Needs Node.js and downloads the web tools from npm. The one-shot stays as it
  is in `prototypes/<name>/`."
- **Keep iterating**: "It stays a one-shot: ask for changes and tune it as now."

No option is marked recommended: both are good next steps and the choice is the person's. Keep
iterating goes back to One-shot 4. Grow it asks nothing more: the yes covers the install (it is
named in the option), and every other choice below is made, not asked.

## 2. The guard

```bash
bash .claude/scripts/one-shot-grow.sh guard <name>
```

Each `guard` row is `pass` or `fail`; exit 3 when one fails. Before anything is written:

- **`node fail`:** "Growing needs Node.js 22.12 or later; 24 is the current long-term release
  (nodejs.org). `/prototype` itself needs no Node: the one-shot keeps working." Name the version
  found, if any. Stop.
- **`engine fail`** or **`root fail`:** as section 1. Stop. An `index.html` at the root fails it
  too: "There is an `index.html` at the top of this project. Move it into a folder first, so the
  grown game can take its place."
- **`no_config`:** a game brought in by the door with no `config.js`: no `data/config.json` and no
  tweak panel are made; its values stay in the code until they are moved (One-shot 0 section 9).
- **`clean fail`:** the game's files have changes that are not committed (the row names the
  first). "Commit or undo the changes in `<path>`, then say grow again." Stop. Never commit,
  undo or keep those changes yourself to get past the guard, even on "you pick" or "just grow
  it": they are the person's, and the choice is theirs.
- **`git none`:** say "Not a git project: the one-shot folder is your backup" and go on, without
  commits or tags.
- **`brief_dirty`:** the debrief's lines in the two briefs, not committed yet. They are the
  person's words, so commit just those two files first: `docs: <name> brief after play`.

## 3. Reference (step 1)

`one-shot/<name>` is the first build's tag; tag it now if the `tag` row says `none`. The grow
starts from the `commit` row's commit, which the record names.

```bash
bash .claude/scripts/one-shot-grow.sh replay <name> --as reference --log "<inputs>" [--stop STEP]
```

It plays the one-shot twice from the same seed by the inputs (`one-shot-run.sh --log`'s format:
what leaves the title, then about a minute of the game's own keys toward the brief's hook), and
keeps the rows and a screenshot in `production/qa/evidence/grow-<name>/`. Read the scene and
state rows to see how far it got. A game that has a `bot.js` from before plays by it instead,
with no `--log`.

A game brought in by the door has no hook: use `--hookless --log "<inputs>"`,
the start and play inputs of its `evidence/baseline/inputs.txt` in one log. Its state rows read
`hookless`, so the frames and screens are what is compared.

- **`exact yes`:** the two runs match, so later runs can be compared with this one exactly.
- **`exact no`:** the one-shot is not repeatable on its own (the row says where the runs
  parted). The grow goes on, checked by screenshots and errors only, and the record says the
  replay is NOT ASSESSED.
- **`not_assessed`:** nothing could play the game (no inputs, no browser): the same as `exact
  no`, with the reason named.

Commit the evidence folder: `test: <name> same-seed reference run before growing`.

## 4. Copy (step 2)

```bash
bash .claude/scripts/one-shot-grow.sh copy <name>
```

A grown game is a Web project, so its code root is Web's from the engine table, `src/`: every
`src/` path in this file is that root.

It copies the web scaffold's tooling (`package.json` named after the game, the lockfile, the
Vite, TypeScript and Playwright configs, `src/hook.ts`) and the game, still JavaScript: the
page's markup and styles into `index.html` (its header, `config.js` and `tune.js` tags gone), its
inline script into `src/main.js`, `window.CONFIG` into `data/config.json` (one entry a line, the
same keys, values, ranges and seed) with its comments in `data/config-notes.md`, `assets/` with
`provenance.yaml`, and `feel-log.md` into `design/feel-log.md` with no header. `src/config.js`
sets `window.CONFIG` from the data file and loads the tweak panel (`src/dev/tune.ts`) on the dev
server only. Nothing is written over a file that is there (`EXISTS`).

- **`left` rows:** what it did not carry. A `vendor` file becomes a pinned npm dependency at
  the version `assets/provenance.yaml` records (`npm install --save-exact <package>@<version>`),
  imported where the game used it; with no version recorded, copy it into `assets/vendor/`,
  import it, and say so in the handover. A `script` or `label` row: carry that script into
  `src/` as a module imported by `main.js`, in the page's order.
- **`config_lost`:** a value JSON cannot hold; compute it in the code from the others.

Then `npm ci` (the lockfile's exact tree), `npm run build:single`, and:

```bash
bash .claude/scripts/one-shot-grow.sh replay <name> --as copy
```

`match yes` is the proof that moving into the web project changed nothing. `match no` names the
first row that differs and the reference's row there (`was`): fix the copy until it matches, and
never change the reference. Commit: `feat: grow <name> into a web project, still JavaScript`.

## 5. TypeScript (step 3)

Split `src/main.js` by what the code does, and move it to TypeScript:

- **`src/game/`:** rules with no browser in them (no `document`, `window`, canvas, audio,
  `localStorage` or `location`), so Vitest runs them in Node: at least the pure pieces of the
  brief's core loop (a score, a cost, a timer, a level curve), as small exported functions the
  game calls. The state's types go here too.
- **`src/config.ts`:** imports `data/config.json`, exports `CONFIG` and the live `tune` reads
  the game used (typed to the file's keys), and keeps `src/config.js`'s dev-only tweak panel line.
- **The drawing kit, the sound, the input:** a module each when the one-shot has them as
  sections (`screen.ts`, `audio.ts`). Scenes and the loop stay in `main.ts`.
- **`src/hook.ts`:** use the scaffold's (`params`, `manual`, `clock`, `seedFrom`,
  `audioContext`, `install`) in place of the one-shot's own copies.

Behaviour does not change, only where code lives and its types: the same order of `rng()` calls,
the same arithmetic, the same scene names and the same keys in `state` (a key added to the state
shows in the run's rows). Renames, fixes and cleanups are stories after the grow. `strict` stays
on, and `npx tsc --noEmit` lists what is left to type. Type every parameter, the save and the
data tables, and the state and entities where their fields are few. Objects the code builds
field by field, kind by kind (a big game's foes, effects and zones), share one alias,
`type Loose = any` in `src/game/types.ts`: the record names each kind that uses it, as typing
still to do. Delete `src/main.js` and `src/config.js`,
point `index.html` at `./src/main.ts`, then `npm run build:single` (it runs `tsc --noEmit`) and:

```bash
bash .claude/scripts/one-shot-grow.sh replay <name> --as typescript
```

`match yes` is the before-and-after proof. Commit: `refactor: <name> in TypeScript, split by
what the code does; same-seed run matches`.

## 6. Rules under test (step 4)

Start from the scaffold's two tests, `.claude/engines/web/scaffold/tests/unit/rules.test.ts.tmpl`
and `tests/integration/boot.spec.ts.tmpl`:

- **`tests/unit/rules.test.ts`:** at least one rule from `src/game/` that the brief's core loop
  names, its values read from `data/config.json`; a literal only where the exact number is the
  point (a rounding boundary). Break the rule once, see the test fail, restore it.
- **`tests/integration/boot.spec.ts`:** the `@boot` test, with the game's first scene; and the
  scripted run through the hook (`?manual=1&seed=`, `press`, `hold`, `step`), the reference replay's
  opening inputs, asserting what it does and that the same seed repeats it exactly.

`npm test` runs both. Commit: `test: <name>'s rules under Vitest; boot and same-seed replay under
Playwright`.

## 7. Record (step 5)

```bash
bash .claude/scripts/one-shot-grow.sh record <name>
```

It writes `engine.name: Web` and `engine.version` into `project.yaml` only when the engine was
unset (`engine written`); a set `Web` stays (`engine kept`). Nothing else in `project.yaml`
changes. `claude_md written` points CLAUDE.md's engine reference import at
`docs/engine-reference/web/VERSION.md` and fills its Technology Stack lines that were still
placeholders, as `/setup-engine` does, so no session loads another engine's reference. Then:

- **The brief:** `design/game-brief.md` stays the design record. Mark each Features line from
  what the grown game does: built `[x]`, not yet `[ ]`. Keep, Avoid and Out of scope stay word
  for word; `prototypes/<name>/brief.md` is left as it was.
- **The checks:** `npm run build`, `bash .claude/scripts/test-run.sh web` (its `rule` row must be
  `web:pass`), and `npm run smoke`. A failure stops here, named.
- **The record:** `production/qa/evidence/grow-<name>/grow.md`: a table of the five steps with
  each result (`exact`, `match`, the tests' counts, the checks), the screenshot it was seen in
  (`typescript.png`), a line naming what was NOT ASSESSED, or "nothing", and one naming what is
  still `Loose`. Look at `typescript.png` beside `reference.png` before writing it.

Commit (`chore: <name> grown: engine Web, record and screenshot`), with `CLAUDE.md` in it when
the row said `written`, then `git tag grown/<name>`.

## 8. Handover (step 6)

In plain lines:

- **Play it:** `npm run dev`, then open the address it prints. The tweak panel is there, on the
  backquote key or `?tune`; its Save block is written into `data/config.json` and
  `design/feel-log.md` by `one-shot-tune.sh .` (One-shot 4 section 5 holds for a grown game).
- **The four commands:** `npm run build` (the folder to ship), `npm test` (Vitest, then
  Playwright), `npm run smoke` (the boot test), `npm run dev`.
- **What was proven:** the same-seed run matched before and after, or NOT ASSESSED with why.
- **Next:** say the next feature in your own words: it is built in one sitting (section 9),
  checked and committed. Stories (`/create-stories`) only when you ask for them, or in studio mode.
  When the game is close to finished, `/cut` proposes what to cut and a polish list.

## 9. One feature a sitting

After the grow, the person names the next feature in their own words and it is built in this
sitting. With none named, offer the brief's first `[ ]` Features line, or ask what it should do
next. No stories, epics, design documents or gates: they run only when the person asks for them, or in studio mode
(`workflow` `standard` or `full`).

- **Build it** in `src/`, its new values in `data/config.json` with a line each in
  `data/config-notes.md`.
- **Check what it touched:** `npm run smoke`, then `npm run build:single` and `bash .claude/scripts/one-shot-grow.sh replay <name> --as story`.
  Open `story.png` beside the last accepted run's screenshot. An error the feature caused: fix it
  and check once more. A `match no` row is expected when the feature changes play: say in plain
  words what changed. What the run cannot reach is not checked, and the person's play covers it.
  Write no robot player or tests of your own.
- **Keep or undo:** show `story.png` and `Added: <what>` / `Errors: none | <each> | not checked:
  <why>`, then ask "Keep this feature? It becomes a commit." Options: Keep / Undo it. Keep: mark
  its Features line `[x]` in `design/game-brief.md` (add one when the brief has none), run
  `one-shot-grow.sh accept <name>` when the run changed, then `git add -- <the files it changed>
  design/game-brief.md` and `git commit -m "feat: <what>" -- <those paths>`. Undo it: put back
  each edit made for it; their hand edits stay.

Then one line: "Say the next feature when you're ready."
