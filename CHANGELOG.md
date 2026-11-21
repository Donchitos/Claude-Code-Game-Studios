# Changelog

What's new in Claude Code Game Studios, written for the people using it.

See [UPGRADING.md](UPGRADING.md) for step-by-step upgrade instructions, and
[docs/migration-guide-v1.1.md](docs/migration-guide-v1.1.md) if you have an
existing project on the older config files.

---

## [1.3.0] — 2026-11-09

**"Make me a game" is the main road: `/prototype` asks a few questions, writes a
one-page brief, builds a browser game from it, checks it against the brief,
and fixes what the check finds before you get it.** After you play it, you
change it by asking, and when you like it you grow it into a real web project
and build on it one feature at a time. Web is an engine, and the agents, the
`team-*` pipelines and the design-document ladder are now called studio mode.
A minor release. [UPGRADING.md](UPGRADING.md#v120--v130) lists the new
folders, the `settings.json` changes and the three renamed skill specs.

**What is shown, and what is not yet.** The first build is the tested part: in
a blind comparison the brief written from Claude Code Game Studios' questions was picked over a
hand-written brief for all three game ideas tried, and all six games built from
the two kinds of brief were ones the tester would build on. Growing was shown
on one game, a one-shot grown through six stories into a game the tester would
keep building. The engine route and deepening one system in a design document
are built but not yet shown in a test like these.

### Make me a game

**`/prototype` asks a few questions, writes a one-page brief, and builds a
first playable game you'd build on.** Say "make me a game" with your idea. It
asks one round of questions picked from the genre (with the usual answer shown,
so "you pick" works), and writes `design/game-brief.md` with how it looks, its
first minute and its challenge. You say Build it. The game is built from the
brief in your session, as a browser game in `prototypes/<name>/` that opens
with a double-click: no emoji art, no copy of another game, your words kept,
and not trivially easy. A short scripted check runs before you get it. Then you change it
by asking, add a tweak panel when you want to tune it yourself, share it, or
grow it into a real project.

- **The questions.** One round of at most about eight, from the genre's sheet:
  the choices that shape the game, how it should feel, how it looks, how hard
  it is, the goal, and whether you want a slice of the game or a quick test of
  one mechanic (a quick test goes to `/prototype --spike`). A vague idea ("a
  racing game") gets two or three one-line pitches first; "none of these" gets
  new ones, and what you said against the old ones is kept as an Avoid line.
  Two genres in one idea are combined system by system, and the brief says
  which genre leads each. Online play, VR, a phone or a console gets one plain
  line on what is built instead. Asked for a copy of a named game, it asks one
  question (an original game in that genre, or that game with your own twist)
  and never builds the copy.
- **The brief** (`.claude/docs/templates/game-brief.md`) has new sections:
  In your words (kept exactly as you typed it), Look and references, First
  minute, Challenge, Your systems (each system you named, marked in the slice,
  a thin stand-in or later), Keep, Avoid and Out of scope. Each field it filled for
  you is marked guessed, inferred or provisional. A brief written by an older
  release still works: its missing sections are asked for or filled.
- **Your references.** Images, screenshots and sounds you drop into a
  `references/` folder at the project root, with a line each in
  `references/notes.md` (take, avoid, or use), shape the look; an image you
  paste is saved there on Build it. A project without the folder is unchanged.
- **The build** runs in your session, with no extra reports or tests. A builder agent runs it only when you name another
  effort ("build it at medium"). Every tuning value goes into `config.js`, so you
  can tune it with sliders. Asked how long it has been building, it reads the
  clock rather than guessing.
- **A short check runs before you get it.** The first build writes no
  robot player and never tunes the difficulty by a script: your play is the
  check. A few scripted key presses in a headless browser show the game opens
  with no errors and responds, one screenshot of play is looked at against the
  brief, and four rows check it boots, keeps your words and draws every figure
  with no emoji. Text that is too small, overlapping or off screen and screens
  that freeze are fixed in one round; anything left is listed as still broken. The brief
  checklist marks every line of the brief pass, missing, broken or not
  assessed, from the screenshots and the game's code. The handover card shows all of it, what is
  still broken, what was guessed and the true effort, and ends "Not yet played
  by a person".
- **Commit and tag.** The first build is offered a commit and the tag
  `one-shot/<name>`, the point every later change can go back to.
- **Change it after play.** Each change you ask for is checked against the
  brief's Keep, Avoid and Out of scope lines first. A big ask is made all at
  once, and is split into rounds you play in between only when you ask. A change does what you asked: a bigger rework only when you ask for
  one. Tuning goes into `config.js`. Before you
  accept, a light check runs, not the full check again: a few
  scripted key presses play the game once and it screenshots what the change
  touched (changed text or screens again in a small window); a balance change
  is checked by your next play. Each change you accept is one commit, "iteration N:
  <what>". "Go back to iteration 2" or to the first build is a checkpoint too. A Keep line can pin a
  value (`pins: <key> <value>`) that the check compares with `config.js`. Hating
  it after play offers fix, pivot or kill on that game. A change, love it or
  hate it said in a new session still reaches `/prototype`.
- **Too easy gets a new rule.** "Too easy" or "every part is the same" after play
  adds at least one rule that raises the pressure or gives a new choice (a threat
  that escalates, a chase, a new hazard or tool) before any number moves. The
  brief's Out of scope lists only what you can do later (grow it, add it as a
  feature, change it after play, needs a server), not what is untested.
- **The tweak panel** is added when you ask to tune: `tune.js` opens on the
  backquote key, or `?tune` in the address, with a slider for each value in
  `config.js`. Save copies a short block; pasted back to `/prototype`, it is
  written into `config.js` with a feel-log line for each value by
  `one-shot-tune.sh`. It works on a page opened from your computer or
  localhost.
- **Share it.** Asked to share or export a one-shot, `/prototype` runs
  `one-shot-share.sh`, which makes `prototypes/<name>/dist/` without the tweak
  panel and the working files. `.claude/docs/share-link.md` says how to put a
  game on a hidden itch.io page or a web link, and `itch-zip.sh` zips a grown
  game's build for itch.io and checks it against itch.io's limits.
- **Bring your own game in.** `/prototype --from <path>` (or `/start`, when it
  finds a game) copies a browser game you already have into
  `prototypes/<name>/` byte for byte, commits it, tags it `baseline/<name>`,
  screenshots it untouched and writes its brief from what it shows, so it can be
  changed and grown like a one-shot. The original is only read.
  `/reverse-document brief` writes a brief from any game's code, with its built
  features marked done.

### Grow it

- **On PROCEED, a one-shot can grow into a web project** at the project root:
  Vite and TypeScript, its values in data files, a rule under test, the four
  commands (`npm run dev`, `build`, `test`, `smoke`), and a same-seed run that
  proves it still plays the same. One question asks keep iterating or grow it.
  Each step is its own commit and the result is tagged `grown/<name>`; the
  one-shot's folder is copied from and never changed. It needs Node.js and
  downloads the web tools from npm.
- **After the grow, one feature a sitting.** Say the next feature in your own words:
  `/prototype` builds it, runs the smoke script and the same-seed run, and asks to keep it
  as a commit. Stories, epics and gates only when you ask for them, or in studio mode.
- **Stories, when you ask for them.** `/create-stories` builds the skeleton first from the
  brief's Your systems list. When every Feature is built, it asks what to add
  and adds it to the brief with your yes, instead of writing no stories.
  `/dev-story` plays the same-seed run and the game's own smoke script after
  every story and shows any change before the story can close. `/story-done`
  lists the AI's own calls beyond the design for you to keep or change, ticks
  the story's Features line in the brief, sets its row in `EPIC.md` and asks to
  commit the story's own files. `/next-step` names `/design-system` first when
  the next story deepens a system with no design document, and names studio
  mode once, as a suggestion, when a grown game passes about nine stories or
  Features.
- **`/cut`, a new skill,** proposes cuts and a polish list to finish the game
  from its brief and what is built, and you pick each cut. A game to sell,
  for early access or for a publisher also gets a target date and a feature
  freeze. Its helpers are `cut-read.sh` and `cut-apply.sh`.

### Added

- **Genre sheets.** `.claude/genres/` holds what `/prototype` asks and builds
  from: `chipsets.yaml` and a sheet for each of 69 genres in `chipsets/`, each
  with the choices that shape a game, its feel lines, its card defaults and what
  comes later. `mashups.md` says how two genres combine, `art-direction.md` how
  a look is written and offered, `online-and-devices.md` what is built for an
  online, VR, phone or console ask, and `sources.md` lists the public sources
  the sheets cite. No user content: the folder is the framework's.
- **Web is an engine.** `engine.name: Web` is a value, and every place that
  switches on the engine reads one table, `.claude/engines/engines.tsv` (each
  engine's code, test and asset folders and default commands), explained in
  `.claude/engines/README.md`. `/setup-engine` offers web first to a new
  project that names no engine, and asks one question, the starter: nothing
  extra, three.js, Phaser or PixiJS. An existing web project is recorded as it
  is, with none of its files changed. The web scaffold has build, single-file
  build, Vitest and Playwright commands, and `docs/engine-reference/web/` has
  pinned versions, toolchain changes and pages for three.js, Phaser 4 and
  PixiJS 8. An existing project keeps its engine.
- **`engine.code_root` and `engine.test_root`** (optional, `project.yaml` only)
  name the project's own code and test folders when they are not the engine's
  usual ones; `.` is the project root, for a flat web game. A value that cannot
  be used makes every code check report NOT ASSESSED with the reason (at
  session start, in the commit check's SKIPPED line, in `project-state.sh`'s
  `invalid` row, and as `code-markers.sh` exit 3), and never falls back to the
  engine's folder.
- **`project.goal`**: jam, learn, hobby, portfolio, sell, early_access,
  publisher, mobile or other. `/start` guesses it from what you say, shows it
  on its card and writes it only on Save them; `config-set.sh` refuses other
  values. The one-shot card shows it, and `/cut` reads it. A project without it
  is unchanged.
- **Read-only framework scripts run without asking, all session.** Claude Code
  applies a skill's `allowed-tools` only in the turn that starts it, so a
  skill's own scripts asked again after its first question. `settings.json` adds
  28 allow rules: the scripts and subcommands that only read and print
  (`Bash(bash .claude/scripts/<name>.sh *)`) and `yaml-helper.sh`'s seven read
  functions. Scripts that write or run your code keep their skill's own grant,
  and the deny list is unchanged.
- **19 new helper scripts** in `.claude/scripts/`: the one-shot's
  (`one-shot-new.sh`, `one-shot-check.sh`, `one-shot-run.sh` with
  `one-shot-driver.js`, `one-shot-tune.sh`, `one-shot-share.sh`,
  `one-shot-grow.sh`, `page-shot.sh`, `references-save.sh`, `vendor-three.sh`),
  the door's (`door-in.sh`, `game-read.sh`), the web engine's
  (`web-detect.sh`, `web-scaffold.sh`, `engine-row.awk`, `json-flat.awk`),
  `/cut`'s two and `itch-zip.sh`. Each prints observations, not verdicts, and
  each shell script among them has `--help`. They need only bash and awk, except: the screenshots and
  played runs need Chrome, Edge or Chromium (without one, the checks say not
  assessed), `one-shot-driver.js` runs in that browser, `vendor-three.sh` and
  the grow need Node.js and npm, and `itch-zip.sh` needs `zip` or Python.
  `references-save.sh` reads Claude Code's session log, so elsewhere it
  reports not assessed and the card asks for the file.
- **The one-shot's starter**, `.claude/docs/templates/one-shot-lean/`
  (`index.html` and `config.js`, with the tweak panel's `tune.js` beside them,
  copied in only when you ask to tune).

### Changed

- **`/start` and `/next-step` lead with making a game,** changing it after play
  and growing it; the agents, the `team-*` pipelines and the design-document
  ladder are presented as studio mode, with when it fits. "Make me a game" is
  `/start`'s first answer, and its idea route can build the game there and
  then. A project with design documents and nothing to play is offered a
  playable built from its concept doc first, and with no engine set,
  `/prototype` comes before `/setup-engine`. `/brainstorm` hands a picked
  concept straight to `/prototype`. `/start`'s card gains a Change something
  answer.
- **`/prototype` with an engine set** offers the browser sketch as one option at
  its path question, not recommended; the engine and paper prototypes are
  otherwise as before. A one-shot made before an engine was set is never offered
  a move to it.
- **Three skills renamed:** `/help` is `/next-step`, `/settings` is
  `/project-settings`, `/changelog` is `/write-changelog`, because the old names
  clash with commands other AI tools keep for themselves. The old names still
  work: each says the new name once and runs the new skill with its own model
  and grants. `release-manager` now preloads `write-changelog`. A
  `skillOverrides` entry or permission rule naming an old skill needs the new
  name.
- **Four skills do their specialists' work themselves.** `/design-system`
  drafts every section in the conversation under each specialist's lens
  (`references/lens-*.md`) instead of starting eight agents; `/art-bible` does
  the same except Sections 1-4 and 9, which still go to `art-director`, whose
  drafts there scored better; `/architecture-review` takes the engine specialist's look
  itself; `/code-review` keeps one engine helper and checks testability itself.
  Their modes, headings and verdict words are unchanged, and the agent files
  stay.
- **Every hook command in `settings.json` has a new form,** so a Windows
  machine without Git Bash skips the hooks instead of refusing every Read,
  Write, Edit and shell call: session start prints a warning to install Git for
  Windows, and the read, write and commit checks are off until then. On bash
  the hooks run exactly as before. Session start's timeout is 20 seconds (was
  10). The commit, push, asset and skill-change hooks leave sooner on a call
  that is not theirs.
- **`CLAUDE.md` imports no engine reference until an engine is set.**
  `/setup-engine`, the grow's record step and `/project-settings engine.name`
  write the import line, and session start warns when an engine is set and
  nothing is imported.
- **`notify.sh`** prints its line before it starts PowerShell, and detaches it.
- **`model-tiers.md`** names the models the pins resolve to today: Sonnet 5.5
  and Haiku 5.5.
- **Wording in agents and skills,** with no change in behaviour: rules say
  their reason instead of shouting, skills name their own reference files so
  each loads only when needed, and plain words in the skills 1.3.0 touched.

### Fixed

- **Rotating the session state can no longer lose its notes.** When the dated
  log file could not be written (a folder in its place, or a file where
  `production/session-logs/` goes), `rotate-session-state.sh` still replaced
  `active.md`, and the only copy of the narrative was gone. The log is now
  written to a temporary file, checked, and moved into place before
  `active.md` changes; otherwise the script stops and says `active.md` is
  unchanged (#158, reported by @rudycelekli — thanks for the report).
- **`git commit -m "message" -a` is checked on a machine without Python.**
  The commit check missed an `-a` or `--all` after a quoted message, so every
  changed data file went in unchecked. It now finds them, and still ignores an
  `-a` inside the message or in a later command (#155, reported by
  @rudycelekli — thanks for the report).
- **The Godot reference says Vulkan is the Windows default and Compositor is a
  resource.** It said Direct3D 12 became the default in 4.6 and told agents to
  add Compositor as a child node; Compositor is assigned to the `compositor`
  property of a WorldEnvironment or Camera3D, and the rendering sample now does
  that (#143, reported by @mamonbleau — thanks for the report).
- **Five skills that change a file in place list `Edit` in `allowed-tools`:**
  `/team-qa`, `/review-all-gdds`, `/write-changelog`, `/localize` and
  `/skill-test` granted only Write, so the step stopped on a permission prompt
  or became a whole-file rewrite (#156, reported by @rudycelekli — thanks for
  the report).
- **`/create-stories` on a project with no engine set** wrote Godot 4.7 in a
  story's Engine field. It now says no engine is set and points to
  `/setup-engine`, and writes an unset code or test folder as unset.
- **`/create-stories` says "Test: waived at qa.level minimal"** for a Logic or
  Integration story at that level, as `/dev-story` does, not "Test required".
- **The next story command is printed for you to type.** `/create-stories`
  and `/story-done` offered "Start implementing: /dev-story" as an option,
  which could only end in "you have to type it".
- **`/dev-story`'s programmer brief sends new gameplay values to the data
  file,** not literals in the code.
- **On a grown game, `/story-done` counts what the run's screenshot plainly
  shows,** and a behaviour check you have not played yet can wait: "I'll check it when I
  play" marks it DEFERRED for a playtest instead of holding the verdict.

---

## [1.2.0] — 2026-10-19

**The story skills are rebuilt around shared helper scripts, a read guard stops
whole-file reads of large design docs, the engine references move to Godot 4.7
and Unreal Engine 5.8, and no skill pre-approves every shell command any more.**
A minor release. [UPGRADING.md](UPGRADING.md#v113--v120) lists the
`settings.json` merges, the new files and the renamed `studio-tests/` folder.

### Added

- **Session start says when a newer release is out**, in one line with the
  release page and how to stop the notice; nothing is downloaded or changed.
  The hook only reads a per-user cache outside your project. A background job
  refreshes it by asking GitHub for the latest release at most once a day, so
  session start never waits and nothing about your project is sent. Turn it off
  with `/settings --local updates.check=false`, or for the team with
  `updates.check: false` in `project.yaml`; it is always off when `CI` is set.
- **A read guard for large design docs.** The new `validate-read.sh` hook
  refuses a whole-file read of a doc over 40 KB under `design/`,
  `docs/architecture/` or `production/session-state/` and answers with its
  headings by line, so the retry reads one section; a ranged read always
  passes. Coordination rule 6 and most skills that read a GDD, ADR or the art
  bible now read by section. `features.read_guard: off` (or `false`) turns it off and
  `features.read_guard_kb` sets the size (#136, #140, suggested by @mamonbleau).
- **Evidence knows when its code changed.** `/dev-story` writes `stamp.txt`
  beside a story's retained screenshots, recording the files they prove.
  `/story-done` and `/test-evidence-review` name each of those files changed
  since ("re-capture it"), or say "no stamp" for older evidence. They report it
  and never block on it (#135, proposed by @jiangshoujie).
- **Stories list their files.** The new story template,
  `.claude/docs/templates/story.md`, has a `## Files` section: `/create-stories`
  lists the planned files, `/dev-story` replaces them with the files it changed,
  and `/story-done` checks scope against the list. Its scope check used to look
  for a list no story had, so it could not run.
- **Helper scripts answer what skills worked out by hand.** New scripts in
  `.claude/scripts/` read story facts, ADR status, a Markdown section to its next
  heading, the project's stage, the session checkpoint and config writes. The
  rebuilt skills and `/settings` use them, so the same question gets the same
  answer each time and a long section is never cut off by a fixed-size grep.
  More ship alongside them for you to run: bug counts, code markers,
  sprint arithmetic, tech-debt scores, flaky-test rates, asset checks, content
  counts, test runs and test scaffolding. Each prints observations, not
  verdicts, and has `--help`. All but `agent-check.sh` and
  `compat-inventory.sh`, which need Python 3, need only bash and awk. `resolve_config` also
  answers six more questions for skill authors (`gate_level`, `engine_values`,
  `specialists`, `review_gate`, `input_methods`, `perf_budgets`).
- **Registry checks.** `registry.sh` lists, looks up and validates the three
  registries and hands out the next ID as the highest ever used plus one, so a
  retired ID is never reused. It reads the unquoted `status: superseded_by:`
  lines 1.1.3's `/architecture-decision` wrote, and names each one to quote. The new `validate-registry.sh` hook warns when a
  write to the entity or TR-ID registry would delete or renumber an entry or set
  a status the header does not list, and the skills that write a registry
  validate it afterwards.
- **Write rules that warn, never block.** `validate-write.sh` flags a write
  that would replace a file skills never overwrite (an existing `EPIC.md`,
  `project.godot`, an engine reference doc), set a config value outside its
  list, cross the prototype boundary or break a localization freeze.
  `validate-agent-artifact.sh` tells you when a subagent stops without writing
  the file its brief named.
- **`/sprint-plan` checks the sprint goal can be shown.** It lists what showing
  the goal needs (the scene it runs in, the setting that starts it, anything a
  picked story names but none builds) and reports any gap in a new Goal
  Prerequisites section and in Risks, without blocking (based on an idea in #76
  by @FreedomPortal).
- **Rules for engine scene and asset files**, which a bad hand edit can corrupt.
  The new path-scoped `.claude/rules/scene-files.md` covers `.tscn`, `.tres`,
  `.unity`, `.prefab` and `Assets/**/*.asset`: use the editor where you can,
  never invent a Godot `uid://`, never hand-edit Unity YAML while an Editor is
  reachable. `settings.json` denies `Edit(**/*.uasset)` and `Edit(**/*.umap)`,
  which covers writes too.
- **Agents never file upstream.** Coordination rule 7: no agent files, opens or
  comments on an issue or pull request in an engine, plugin or vendor
  repository, even when asked. It writes a draft for you to submit, and
  `/bug-report` says it drafts only.
- **`/skill-test static` checks agents and Claude Code-only features**:
  descriptions close enough to pick the wrong agent, an agent told to ask the
  user, settings Claude Code ignores, and each place a skill, agent, hook or
  setting depends on something only Claude Code provides. These never change a
  verdict. `/skill-test` and `/skill-improve` now say what a pass proves: they
  read files and never run the skill.
- **New templates** in `.claude/docs/templates/` for layouts the skills write,
  from bug reports and certification checklists to `/help` output and
  `sprint-status.yaml`. `/create-stories` writes from `story.md`; the other
  skills do not use the new layouts yet. The GDD template is now exactly the
  skeleton `/design-system` writes, its guidance moved to
  `guidance/game-design-document-guide.md`.

### Changed

- **Six skills rebuilt to Anthropic's skill-authoring guidance.**
  `/create-stories`, `/story-readiness`, `/create-epics`, `/dev-story`,
  `/story-done` and `/start` are shorter: the main path in `SKILL.md`, rare
  branches in `references/` (`/start` is a single `SKILL.md`), fixed steps in
  the helper scripts. `/dev-story` and
  `/story-done` replace 1.1.3's numbered phase files with fewer, named ones, and
  `/brainstorm` loads its full concept flow only at `standard` and `full`.
  - `/start` works out the rigor from what you describe and shows it with the
    stage on one card with a single Save them / Don't save question.
  - `/create-stories` reports each governing ADR's status before drafting and
    blocks a story whose ADR depends on one not yet Accepted; `/create-epics`
    marks a requirement whose only ADR is Proposed, so that block still holds.
  - `/dev-story` hands every code story's changed files to the engine
    specialist, and its brief rules out one-off helpers, handling for errors
    that cannot happen, and values special-cased so a test passes.
  - `/story-done`'s report carries a **Reviewed by** line that is never blank:
    `lead-programmer`, `/code-review (you said you ran it; not verified here)`
    or `self, no independent review` (#135).
- **Engine references move to Godot 4.7 and Unreal Engine 5.8.** The Godot
  docs cover 4.7 (latest patch 4.7.2): AreaLight3D, HDR output, the Asset
  Store, VirtualJoystick, Jolt changes and typed-return overrides. Unreal 5.8
  (latest hotfix 5.8.3) is recorded across the breaking changes, deprecated
  APIs, modules and plugins. Unity stays on 6.3 LTS, the newest LTS, and lists 6.4 to
  6.6 and the 6.7 beta as newer releases with unconfirmed APIs. Timelines carry
  vendor-sourced dates; Unreal's pooling sample and GAS tag calls are corrected.
  Where the 5.8 editor disagrees with Epic's release notes, the Unreal reference
  says so: MegaLights' tooltip still calls it Experimental and says it needs
  hardware ray tracing and skips directional lights, and the Iris plugin still
  carries a Beta flag.
  Staying on Godot 4.6 or Unreal 5.7? Keep your current engine folder.
- **CI templates.** `/test-setup` writes `actions/checkout@v7` and
  `actions/upload-artifact@v7` (a self-hosted runner needs 2.327.1 or newer)
  and names Godot 4.7.2 and gdUnit4 6.2. On Godot 4.7, `/setup-engine` runs a
  new project's first import again when it exits 139, a crash on exit after
  the import has finished.
- **Worktrees start from your current commit and get your local config.**
  `settings.json` sets `worktree.baseRef: "head"`, so a worktree (the
  prototyper's, an isolated subagent's, `claude --worktree`) starts from your
  commit, not the remote's default branch. The new `.worktreeinclude` copies
  `project.local.yaml`, `CLAUDE.local.md` and `.claude/settings.local.json` into
  it, and `.gitignore` ignores `.claude/worktrees/`. The prototyper names its
  worktree and branch, lists uncommitted files it cannot see and asks you to
  commit the ones it needs, pulls Git LFS files when the project uses LFS, and
  says which checks it could not run.
- **Hooks that did nothing stop running.** `post-compact.sh` is removed: Claude
  Code discards its output, and `session-start.sh` already restores context.
  The Stop hook runs in the background, so it no longer holds up a turn, and
  `notify.sh` fires for permission and idle prompts only.
- **Agents end their turn with the question.** The 49 agents were told to "wait
  for yes", which an agent started by a skill cannot do; they now end the turn
  with the draft and the question for the caller to put to you. `/balance-check`,
  `/tech-debt` and `/bug-report` do the same when run as a subagent.
- **`/settings` refuses a bare `testing.strict` other than `true` or `false`**
  instead of writing it, and suggests the nearest known key and asks before
  writing an unknown one (#135).
- **`/prototype` is capped at one day everywhere**; `/team-release` may start
  `/release-checklist`; `/launch-checklist` runs only when you type it.
- **The skill and agent spec folder is now `studio-tests/`**, renamed from
  `CCGS Skill Testing Framework/`. Every skill spec pins the settings its cases
  assume, and `/settings` has a spec. UPGRADING says how to move your own specs;
  `/skill-test` and `/skill-improve` say so while the old folder is still there.
- **`/create-stories` proposes an estimate.** Each story gets a size (`S`, `M`
  or `L`) that you can change before the stories are written. `/story-readiness`
  still fails a story with no estimate at `standard` and `full`, and a new story
  now has one.
- **`yaml-helper.sh` answers six read-only lookups directly**, run from the
  project root (`bash .claude/hooks/yaml-helper.sh resolve_setting <key>` and
  five more); `/settings` and `/perf-profile` use them.
- **`.gitattributes` keeps awk programs and `.worktreeinclude` LF** on every
  checkout, `core.autocrlf=true` on Windows included.

### Fixed

- **A repeated key in `project.yaml` is merged and named.** A second `modes:`
  block wiped the first while the schema check passed. Blocks are now merged,
  and session start, `/settings` and `resolve_config` name the repeated keys.
- **A saved review is reused only when nothing it read has changed.**
  `/architecture-review` reused its last report after an engine upgrade or a
  TR registry, `architecture.md` or budget change. It now checks every file it
  read, names a deleted GDD or ADR, and never stands on a narrower report.
  `/design-review` logs its mode and tier.
- **`/design-review` checks every place a registry value appears**, so a value
  restated in a long GDD's tables (an enemy's health, a drop rate) that
  contradicts the registry is a blocking item with its line number.
- **`/story-readiness` asks for as many acceptance criteria as
  `story_granularity` wrote** (coarse 3/2/1, balanced 2/2/1, fine 1), instead of
  demanding three of a Logic story written at `fine` or `balanced`.
- **Requirement IDs and ADRs.** `/create-architecture` keeps registered TR-IDs
  and marks new ones provisional, so a re-run no longer renumbers what stories
  cite. `/architecture-review` may now Edit, so its appends to
  `tr-registry.yaml` stop rewriting the whole file. `/architecture-decision`
  writes the ADR Layer row; without it every ADR counted as critical, turning
  advisory items into blockers at `standard`. A superseded status is written
  quoted, as YAML requires.
- **The commit check** skips GDD copies in `design/gdd/` subfolders such as
  `archive/` (#133), checks the copy the commit takes, and reads a PowerShell
  `git add` path with backslashes. `gdd-structure-check.sh` names sections
  holding only `[To be designed]` as placeholders.
- **Session start.** A stray `.claude/.claude/` no longer makes hooks write
  `.claude/production/`, and neither does a `CLAUDE_PROJECT_DIR` that points at
  `.claude/` itself. The checkpoint preview says when it was written on
  another branch. "Open bugs" counts only bugs that are not Closed or Verified
  Fixed. The sparse-design-docs notice counts only the GDDs at the top of
  `design/gdd/`, as the commit check does, and names the copies in subfolders
  such as `archive/` that it skipped.
- **Rotating `active.md` keeps the live checkpoint**; it used to move it into
  the session log when the file came from the template.
- **Missing prerequisites name the skill that makes them**: `/dev-story` and
  `/story-done` with no story point to `/create-stories`, and `/create-epics`
  stops without `architecture.md` at `standard` and `full`.
- **`/adopt`'s "help me find them" option works**: it searches by heading,
  shows where each doc belongs and asks before moving it with `git mv`. At
  `workflow: minimal`, a project whose code already holds the game is sent to
  `/reverse-document design [code root]`, not `/brainstorm`.
- **`/estimate` measures the size and branching it asks for**, from Grep counts
  reported as an approximation.
- **A partial check says what it skipped.** A focused `/review-all-gdds` labels
  its verdict ("consistency only") and does not count as a full review at the
  Technical Setup gate; `/smoke-check quick` says coverage was not checked, and
  the Polish and Release gates do not count it. The Pre-Production gate counts
  an `/architecture-review` report only for what its mode checked: a
  `single-gdd` or `consistency` report no longer passes the Foundation-gap and
  engine-audit items, and a report from before 1.2.0, which has no `Mode:`
  line, counts for none of them.
- **A stage never advances past a check that could not run.** A gate with a
  concern and an unrun required check returned CONCERNS, and accepting the
  concerns moved the stage. `/gate-check` now offers no override until that
  check runs, and its report names it.
- **`/sprint-plan` asks before it writes the plan**, even after a "yes, go
  ahead" to its QA-plan question, which it used to take as approval to write.
- **Godot no longer imports `production/`.** In a Godot project the evidence
  screenshots in `production/qa/evidence/`, and the `.wav` Movie Maker writes
  beside them, were imported as game resources with `.import` files, and a
  default export packed them into the game. The new `production/.gdignore`
  makes Godot skip the folder.
- **Playtest records count as test evidence.** `/story-done`,
  `/test-evidence-review` and `/qa-plan` looked for them in
  `production/session-logs/`, which is gitignored. They now read
  `production/qa/playtests/`, where `/playtest-report` writes them.
- **`/help` and `/gate-check` see when stories are missing.** Two `EPIC.md`
  files counted as the two story files the Create Stories step needed, so the
  step read as done before any story existed.
- **ADR cycles name only the ADRs on the cycle.** `adr-dep-graph.sh` also
  listed every ADR that depends on a cycle, so the advice was to cut a
  legitimate dependency. It now also prints a build order and names a Depends On
  row still holding the template text, instead of reading it as no dependency.
- **`/architecture-review single-gdd` writes only that system.** Its "write all
  three files" replaced the project-wide traceability index with one system's
  rows and could propose retiring other systems' requirements. A review with no
  ADRs now reports NOT ASSESSED instead of stopping without a report, and the
  argument hint lists `rtm`.
- **The architecture skills.** `/architecture-decision` reads the ADRs still to
  write from `architecture.md`'s Required ADRs, and writes the first entry of an
  empty registry section as valid YAML. `/create-architecture` says no system
  goes in the Platform layer, which has no manifest rules.
- **`/setup-engine` on a new Godot project** reports the gdUnit4 runner it names
  in `commands.test` as expected until `/test-setup` installs it, instead of
  asking you to resolve it. It no longer expects `/brainstorm` to recommend an
  engine: `/brainstorm` records your preference and never recommends one.
- **Review receipts written on Windows read correctly on Linux and macOS.** A
  receipt with Windows line endings read every file as CHANGED there.
- **Pointers to sections that no longer exist** in `/gate-check`,
  `/setup-engine`, `/create-architecture` and `/create-stories` name the right
  ones.
- **A multi-line value in `project.yaml` is read as text.** The lines under a
  `|` or `>` value were read as settings: a note holding `review_mode: full`
  could change the review mode, and a `stage:` line in one was reported as an
  invalid stage. Every reader, the stage writer and `/settings` now skip that
  text; `/settings` will not overwrite a multi-line value.

### Security

- **Skills pre-approve only the commands they run.** A bare `Bash` entry in
  `allowed-tools` let 34 skills run any shell command without asking in the
  default permission mode. Each now names the framework scripts and read-only
  commands its text runs. Anything else, including your `commands.test`, asks
  first: approve it once, or add `Bash(<your command> *)` to
  `.claude/settings.local.json`. A skill you keep your own copy of needs the
  shipped `allowed-tools:` line.
- **Tagging, merging and deploying are flagged before they run.** The push check
  also warns on `git tag`, `git merge`, `gh release`, `butler push` and
  `steamcmd +run_app_build`, which `/hotfix` and `/team-release` ask about first.
- **The same `.env` protection with fewer rules.** The three Bash `.env` deny
  rules are gone: `Read(**/.env*)` and `Edit(**/.env*)` already cover Bash file
  commands and redirects. `settings-local-template.md` no longer suggests
  `Bash(git *)`, which approves `git push` too.

---

## [1.1.3] — 2026-10-08

**Long skills keep their later steps through a long session, a question nobody
answered is never taken as an answer, and the shipped permissions approve
less.** A fix release for 1.1.2.

### Fixed

- **The 14 longest skills keep their later phases after a compaction.** Claude
  Code re-attaches only the first part of an invoked skill after a compaction,
  so the later phases of a long skill could drop out in the middle of a session.
  `/adopt`, `/architecture-decision`, `/architecture-review`,
  `/create-architecture`, `/design-system`, `/dev-story`, `/gate-check`,
  `/prototype`, `/review-all-gdds`, `/setup-engine`, `/smoke-check`,
  `/story-done`, `/test-setup` and `/ux-design` now keep each phase in its own
  file in the skill's `references/` folder, read when the phase starts and
  again after a compaction. The steps themselves are unchanged. The files are
  named relative to the skill folder, so they are found wherever the skill is
  installed, and every reference file over 100 lines opens with a list of what
  it holds. `/skill-test` and `/skill-improve` read those files too, so they
  judge a split skill whole and put a fix in the file that holds the text.
- **A question that is skipped, dismissed or comes back empty is not an
  answer**, in any mode: nothing is written, set or picked on it, and it is
  asked again in plain text. Guided mode no longer contradicts itself: a new
  file waits for "May I write?", and an update to an existing file goes ahead
  after a short summary.
- **Agents return their options as a short list for the skill to ask.** Fourteen
  agents were told to use the question tool, which an agent started by a skill
  does not have.
- **Settings read from a subfolder use the project root.** Started in `src/`,
  per-system overrides read as none, notes about invalid or locked values
  disappeared, and the older `review-mode.txt` and `stage.txt` were never
  found. `/settings` and `/perf-profile` also work from a subfolder now.
- **Setting values.** A hand-edited local `platform.cert_tier` no longer
  overrides the locked value, and an invalid `cert_tier` or `testing.strict`
  value counts as unset rather than being used. On Windows the locked-key note
  no longer ends each key with a stray carriage return, and an always-ask item
  that contains a comma is no longer split in two.
- **The commit check sees files a `git add` in the same command stages**
  (`git add -A && git commit`), and no longer asks `systems-index.md`,
  `game-concept.md` and the other non-system files in `design/gdd/` for GDD
  sections (#133).
- **The commit check works for a project in a subfolder of a larger
  repository.** A game in `game/` of a bigger repo got no data, GDD or code
  checks at commit; staged paths are now read from the project folder. **A JSON
  data file stored with Git LFS** is checked through its working copy instead of
  being blocked as invalid, and one with no working copy is named as skipped.
- **`/smoke-check` no longer waits forever on Unreal.** The version check ran
  `UnrealEditor-Cmd -version`, which opens the editor and never returns. It now
  reads the engine's `Build.version` file.
- **Registry lookups.** `/design-system` finds the entities other systems
  reference it from; the requirement lookups in `/create-stories`, `/dev-story`
  and `/story-done` no longer match `combat-ai` when asked for `combat`; the
  documented superseded status is valid YAML; `/consistency-check` and
  `/architecture-review` re-read their registry before writing to it. Your own
  registry files are not changed.
- **Next steps at `workflow: minimal`.** Thirteen skills offered only a sprint as
  the next step; at minimal they now name the brief's build order.
  `gameplay-programmer` no longer asks for an ADR there, and five templates name
  `design/game-brief.md` beside the concept doc.
- **`team-polish` and `team-ui` keep their core members at the `lean` review
  mode.**
- **`/scope-check`'s verdict bands no longer overlap** at exactly 10% and 25%.
- **`/start` writes a single `modes:` block.** Its rigor and automation
  questions could each add one. If your `project.yaml` has two `modes:` blocks,
  merge them into one.
- **Every skill opens with a title.** 39 skills had no top-level heading, and in
  `/architecture-decision` the first one was the ADR template's placeholder
  (#83, reported by @specterslient95-lgtm).
- **A settings line that runs for more than two minutes** reaches the skill as a
  task notice instead of the settings; `config-resolution.md` now says what that
  notice means and where to read the settings instead.
- **The three writes that need no "May I write?"** — agent memory, appends to
  `active.md`, and an agent's new file at the path its skill named — are now
  named in `CLAUDE.md`, which named none of them, and in the agent-memory rule,
  which named one.
- **Docs corrected**: the settings, workflow and protocol docs, the README, the
  setup requirements and the 1.1.0 and 1.1.2 notes on what the default
  permission mode covers, and three overstatements in `/story-done`, the
  workflow guide and UPGRADING.

### Security

- **The shipped allow rules no longer approve deleting a branch or writing files
  without asking.** Four allow rules had no space before their `*`, so they
  matched any text after the command name: `git branch -D` and `-m`, `git log`
  and `git diff` with `--output=<file>`, and `python -m json.tool <in> <out>`
  ran without a prompt, and in auto mode an allow rule also skips the
  classifier. Those rules are removed; read-only git commands such as
  `git status` and `git log` still run without a prompt. See
  [UPGRADING.md](UPGRADING.md#v112--v113) if you merged `settings.json` or
  copied these rules into `settings.local.json`.
- **Start Claude Code at the project root.** It loads `.claude/settings.json`
  only from the folder it starts in, so a session started in `src/` or `design/`
  runs without the project's hooks, deny rules and ask-first mode. The README
  says so, and Claude now warns when it was started somewhere else.
- **`.env` files are denied to Edit.**

---

## [1.1.2] — 2026-09-29

**The default path works end to end, Unity and Unreal get the same care as
Godot, and the checks tell you what they found.** A fix release for bugs in
1.1.1, each reproduced before it was fixed.

### The default path (`rigor: minimal`)

- **`/help`, `/story-done` and the status line follow the path you're on.**
  Nothing at minimal runs `/gate-check`, so the stage never moves. `/help` read
  that as the Concept phase and asked a project with a brief and three stories
  for a concept doc, an art bible and a systems map. It now follows the minimal
  route: engine → `design/game-brief.md` → stories → `/dev-story` ↔ `/story-done`.
  `/story-done` names the next story instead of printing the sprint close-out,
  and the status line shows `Minimal · 1/3 stories`.
- **No more dead ends into sprints.** `/sprint-status` reports progress through
  the brief's build order instead of refusing. `/create-stories`, `/dev-story`,
  `/qa-plan`, `/smoke-check`, `/team-qa`, `/retrospective`,
  `/test-evidence-review` and others offer a minimal route instead of "run
  `/sprint-plan`". The production gate at minimal asks for the brief and stories,
  not a sprint plan.
- **The defaults are stated correctly.** About 25 places named the `standard`
  values as the defaults. The default is `minimal`, which gives `coarse`
  stories, `terse` docs and `solo` review. `/start` recommends `minimal` when
  nothing points either way.
- **Skills that read the concept doc also read the brief.** Ten skills and four
  director gates warned "no game concept" or failed on a minimal project that
  had a brief.
- **`/story-done` still checks screenshots at `qa.level: minimal`.** Tests are
  waived there; the Visual/UI screenshot is not, but the skip covered both. A UI
  story now closes on its retained screenshot, and a Visual/Feel story on the
  screenshot plus sign-off, as `coding-standards.md` says — every UI story used
  to need an evidence doc and sign-off as well. The stories `/create-stories`
  writes no longer say their visual evidence is waived at minimal.
- **Your place is saved.** `/dev-story` and `/story-done` update the checkpoint
  in `production/session-state/active.md`, which the next session shows you,
  instead of appending notes nothing read. The checkpoint carries `/dev-story`'s
  run result, which `/story-done` checks.
- **The status line counts the right stories.** An explicit `workflow: minimal`
  under another rigor showed Concept; "Not Done" counted as done; bold and
  bulleted Status lines were skipped; and after a `cd` it looked for
  `project.yaml` in the wrong folder. It also finds Python once per render rather
  than once for every setting it reads.
- **Every story status is handled.** `/help`, `/story-done` and `/sprint-status`
  route `In Review` and `Not Started` stories, and `/sprint-status` says when
  the build order is done. All three agree on the order: an `In Review` story
  is closed first, then an `In Progress` one continues, then the next `Ready`
  or `Not Started` story in the build order. The new
  `.claude/scripts/story-status.sh` lists the stories in that order before
  `/help` and `/sprint-status` run, and only `Complete` and `Done` stories
  count as done. `/project-stage-detect` no longer asks a minimal project for a
  sprint plan, and `/retrospective` no longer counts a story closed without
  tests against you at `qa.level: minimal`. `/create-stories` adds to a finished build order
  instead of starting again at `story-001`, and stops if there is no brief.
  `/brainstorm` asks for the player goal and fail state that stories' acceptance
  criteria come from, and the production gate says which of its quality checks
  apply at minimal.
- The guides (WORKFLOW-GUIDE, quick-start, skill-flow diagrams) describe the
  minimal path, and the review-mode default: no director reviews at minimal.

### Engines

- **Godot tests run.** The test command `/setup-engine` wrote loaded a runner
  gdUnit4 never shipped, so every run failed, passing or not. It is now
  gdUnit4's own runner, with the flag that stops a script error from hanging the
  run at a `debug>` prompt. A run that finds no tests is NOT ASSESSED, not a
  pass. `/dev-story`'s parse check exited 0 on a parse error; it now loads each
  changed script with `.claude/scripts/godot-parse-check.gd`, which also accepts
  code that uses an autoload. `/smoke-check` imports the project before the
  tests: on a fresh clone, with no class cache, gdUnit4's runner did not load
  and the run exited 1 without a verdict.
- **Unity tests compile.** They went under `tests/`, which Unity never compiles,
  so a run reported "0 tests, Passed". They now go under `Assets/Tests/`. The
  build command builds a player, and the smoke command no longer calls a
  `SmokeCheck.Run` nothing creates. The commands name the editor by its full
  path: bare `Unity` can be Unity's separate CLI, which fails with the exit code
  of a failed test. A compile error is a FAIL, and the last run's results file
  is no longer read as this run's. The project coherence check finds the editor
  from `commands.test` and reads `6000.3` and `6.3` as the same Unity, so a
  correctly set up project no longer reports its version as different.
- **Unreal tests compile and are found.** The `qa-tester` template used a flag
  that does not exist, and tests went in `Source/Tests/`, which is never built.
  CI and `/smoke-check` build the editor target first: a fresh checkout has no
  compiled game module, and the editor quit before running a test. The CI
  template asks for a Windows self-hosted runner; it asked for any self-hosted
  runner, so a repository with a Linux one could send the job there. Its steps
  also run when the runner's folder has a space in it, which failed every step
  before. The test
  command prints its results — run from a shell, the editor printed nothing, so
  "no tests matched" could not be told from a failure. Every Unreal command
  names the editor by its full path and gives the project as an absolute path:
  UE 5.7 does not find a relative `.uproject`, so the test, run and smoke
  commands exited 1 before doing anything. A failing test and a run that
  matched nothing both exit 255, so `/smoke-check` now reads the output to tell
  them apart.
- **`/smoke-check` runs your tests first**, and reports NOT ASSESSED when nothing
  ran instead of passing. At `qa.level: minimal`, where tests are waived, a
  project with no game tests is checked by its build, launch and critical paths
  instead, so the Polish and Release gates can pass at the default rigor. The
  build check runs `commands.smoke` (else `commands.build`) when set, and a
  build nobody launched this session is NOT ASSESSED — it could pass with
  nothing run.
- **Godot commands name the editor.** `/setup-engine` wrote bare `godot` into
  `commands.*` even where it says Godot is not on `PATH` (Windows, macOS); it now
  writes the editor's full path, quoted, and records it as `engine.path`.
  `/smoke-check` and `/dev-story`'s parse check find the editor from
  `commands.test`, then `engine.path`, then `PATH`, and say when none is found.
  A flag or path `/smoke-check` needs is added for that run and reported, never
  written into `commands.test`. The project coherence check finds the Godot
  editor the same way — it reported "no Godot binary" on a correct project —
  and looks for Unity Hub's editors on macOS and Linux as well as Windows.
  [UPGRADING.md](UPGRADING.md#v111--v112) says how to update a 1.1.x project.
- **Engine skills read each engine's own output.** `/test-flakiness` looked for
  `Result: Success`, which Unreal never prints, and read Unity results with a
  JUnit pattern, so every test read as consistent; it now reads Unreal's
  `Result={…}`, Unity's NUnit `<test-case>` results and gdUnit4's `reports/`
  folder. `/test-helpers`' Godot signal asserts could never see a signal; they
  now record it in a Dictionary. `/content-audit` scans `Assets/` on Unity, where
  it found no content at all. The Godot and Unity references gain sourced
  command-line sections (runner flags and exit codes); the Unity reference says
  `RecordRenderGraph` is URP's and documents HDRP's `CustomPass`, and
  `unity-shader-specialist` no longer applies the URP one to HDRP.
  `godot-csharp-specialist` uses `[Export(PropertyHint.Range, …)]` — there is
  no `[ExportRange]` — and `ue-gas-specialist` and the GAS reference name the
  base-value clamp hooks. Unreal test names follow the root `commands.test`
  filters on.
- **Unity and Unreal get the rules and checks Godot gets.** The coding rules for
  gameplay, engine, AI, network, UI, shader, data and test code now load in
  `Assets/` and `Source/` projects. Broken data JSON in `Assets/**/Data/` and
  `Content/**/Data/` is caught, PascalCase assets are no longer flagged, the
  data-file rule applies to JSON only (not C# or C++ in a `Data/` folder), the
  test rule names tests the way each engine's language does,
  `/tech-debt`, `/launch-checklist` and `/release-checklist` stop reporting "no
  `src/`", the status line reaches Production, and session start no longer reads
  every texture looking for TODOs. The Unity and Unreal code rules load on code
  files only, and the shader, gameplay and engine rules give examples for all
  three engines. Skill examples, templates and the rules reference name each
  engine's code folder instead of only Godot's `src/`, and the guide's
  `/localize` and `/reverse-document` examples are ones that run.
- **Test results mean what they say.** Each gdUnit4 exit code maps to a verdict —
  101 (every test passed, a node leaked) is a warning, not a failure. The Godot
  CI template runs the gdUnit4 in your repo instead of replacing it with the
  latest release, and asks for a full Godot version. The Unity guidance covers
  the package references and `Editor/` folders an assembly definition needs, the
  `qa-tester` Unity template compiles, and test output is gitignored. The Godot
  CI template asks for `checks: write`: without it the job failed on every new
  repository, even with every test passing. If you protect `main`, require the
  job's check, not `test-results`, which passes even when a test fails. The `qa-tester` Unreal template
  compiles as filled in and gives each test its own class — two tests that
  shared one failed to link — and the Godot one frees its subject.
- **Engine reference corrections.** Godot's `@abstract` example gave an abstract
  method a body, which does not parse; the 4.4 `Texture2D` → `Texture` note now
  names the `Shader` default-texture methods it applies to, not the shading
  language. Unreal's server RPC sample declares `WithValidation`, which its
  `_Validate` function needs. The Unity Addressables migration example keeps its
  handle and releases it. `godot-gdextension-specialist` had the compatibility
  direction backwards: an extension built for an older Godot loads in a newer
  one, not the reverse.
- **Unreal on Linux and macOS.** The Unreal commands named only Windows paths.
  `/setup-engine` now writes Linux commands on Linux (`RunUAT.sh`,
  `Engine/Binaries/Linux/UnrealEditor`), and `/smoke-check`, `/dev-story` and
  `/test-setup` build the editor target there with `Build.sh`; on macOS it writes
  the build command and leaves test, run and smoke for you to set, because Epic documents no
  command-line editor inside `UnrealEditor.app`. `/smoke-check` picks the
  commands for the machine it runs on and reports NOT ASSESSED for Unreal tests
  on macOS until `commands.test` is set. The sources are in
  `docs/engine-reference/unreal/current-best-practices.md`.

### Checks and hooks

- **Warnings you can see.** The commit, push, asset and skill-edit checks printed
  their warnings where neither you nor Claude saw them. They now show in your
  terminal and reach Claude. They never approve anything on your behalf.
- **The commit check covers chained commands.** `git add -A && git commit`,
  `git -C . commit`, `git -C "a path with spaces" commit`, `if git commit`,
  `{ git commit; }`, `/usr/bin/git`, `git.exe`, `env X=y git commit`, a commit
  on a second line and commits through the PowerShell tool all skipped it, and
  on macOS every chained form did. So did `bash -c "git commit"`, `sudo` and
  `xargs git commit`, `git --git-dir .git commit`, and git named by a quoted or
  Windows path (`& "C:\Program Files\Git\cmd\git.exe" commit`), and any
  command with an emoji in it when `jq` is not installed. With data files
  staged and no Python to check them —
  including the Windows Store `python` placeholder, which the check used to
  mistake for Python — it now blocks and says why. The asset check no longer
  calls valid JSON invalid when that placeholder is first on `PATH`.
- **Here-doc text isn't a command.** A commit message written through a here-doc
  that mentions `git push` no longer triggers the push warning, and writing a
  document through a here-doc that mentions `git commit` no longer runs the
  commit check, which could block it. Other quoted text (`echo "git commit"`) is
  still checked. A tab-indented `<<-EOF`, a CRLF here-doc and `/bin/bash <<EOF`
  are now read correctly too.
- **The commit check reads what you commit.** It validates the staged copy of
  each data file, not the one on disk; checks the files `git commit <path>`
  takes, whatever the pathspec (`.`, a folder, a glob, `:/`), and no longer
  mistakes a `-F` message file for one; checks `.JSON` as well as `.json`; no
  longer skips data files with non-ASCII names; and judges a UTF-8 BOM the same
  way the asset check does. The push warning also fires on a refspec that
  targets a protected branch (`HEAD:main`, `+main`, `refs/heads/main`). On a
  command that does not mention git, the commit and push checks now exit at
  once (~116 ms instead of ~350).
- **Dangerous commands are denied in PowerShell too.** The deny rules for
  force-push, `reset --hard`, `clean -f`, recursive delete and reading `.env`
  covered only the Bash tool. They now cover the PowerShell tool, and
  `git push origin main --force` as well as `git push --force` — and `rm -fr`,
  `git clean -df`, a `+main` refspec, `git -C . push --force` and
  `Remove-Item -r`, which were only prompted before.
- **Session start keeps what matters on screen.** A long checkpoint is cut to
  25 lines with a note, and warnings print before it, since hook output over
  10,000 characters reaches Claude only as a 2,000-character preview. At
  minimal it no longer tells you to run `/gate-check`, and it reads the stage
  from `project.yaml`, which it had never done. It no longer warns of an engine reference mismatch on a
  correct project whose `project.name` is one word: it read that line as the
  engine.
- **Counts print cleanly on macOS.** BSD `wc` pads its numbers, so session
  start showed `Code health:        2 TODOs` and the compaction hook
  `(      35 lines)`.
- **A section review never skips an edited section.** The change check behind
  `/design-review` and `/architecture-review` hashed with `git` or `sha1sum`
  only. It now also uses `shasum`, which every Mac has; and with no hash tool at
  all it reports every section as changed and says why on stderr, where it used
  to report an edited section as unchanged.
- The compaction hooks no longer claim their output reaches Claude; session
  start is what restores your place after a compaction. The agent log no longer
  records Claude Code's own internal agents (prompt suggestions, `/btw`) as
  unknown agents.
- **Fewer ways of calling git skip the commit check.** Quoted option
  values (`git -c user.name="A B" commit`, `--git-dir=".git"`, `-C "$(pwd)"`),
  `timeout` and `nice` in front of git, `-a` after the message (`-m "x" -a`,
  `--all`) and a relative path after `cd` (`cd assets && git commit -m x
  data/item.json`) each let a commit through unchecked. A `-C` directory the hook
  cannot resolve (`"$CLAUDE_PROJECT_DIR"`, `~/x`) is now checked rather than
  skipped; only a commit in a different repository is left alone. A commit
  limited to named paths (`git commit -m x src/player.gd`) is no longer blocked
  by an unrelated broken file staged for later, and a redirection (`2>&1`,
  `> out.log`) is not read as a path. `Git` or `GIT` in any case, a quoted
  `"git"`, `stdbuf`, `winpty` or `command -p` in front of it, and a commit on a
  backslash-continued line are checked now too; a `git -C <other repo> commit`
  earlier in a chain no longer lets a later commit of this repository through;
  and text inside a PowerShell `@'…'@` here-string is not read as a command.
- **The push warning names the branches you protect.** It warns on `main`,
  `master` and `release/*` — a short-lived release branch is where a release is
  stabilised — and no longer on `develop`, which trunk-based development
  doesn't have. It checks every push in a chain, not only the first, and reads
  a quoted branch name or refspec.
- **Python 2 on `PATH` no longer fails valid data files**, and with no Python 3
  the GDD section check says it did not run instead of passing silently.
- **More spellings of dangerous commands are denied**: `rm` with `--recursive`
  and `--force`, and force-push, `clean -f` and `reset --hard` with git options
  before the subcommand. The `git` rules match anywhere after `git`, so a git
  command whose text fits one is denied even when nothing dangerous runs — a
  commit message that mentions one, or prose such as `git commit -m "push +
  pull"`; reword the message. `git clean -fn` is denied too; write a dry run
  as `git clean -n`.
- **Smaller fixes.** The status line counts a story whose status reads `Done.`
  or `Complete, verified` as done, as `/sprint-status` does. The skill-edit
  reminder no longer fires for skills outside the project, such as your own
  `~/.claude/skills/`. `/help` finds an engine set only in
  `technical-preferences.md`. On Windows and macOS a Godot project with `src/`
  and `assets/` gets its code root found — Godot's `assets/` was read as Unity's
  `Assets/`. Session start shows `solo` as the review mode when there is no
  `project.yaml`, which is what the skills use.

### Skills and docs

- **Skills read the whole argument.** `/scope-check inventory crafting system`
  checked `inventory`, and `/gate-check --review full` took `--review` as the
  phase. Seven skills read only the first word; they read all of it now.
- **`/design-review --depth` works again** — it was renamed `--review` in 1.1.0
  and old calls were silently ignored.
- **The brief has a Reference game line** — the shipped game yours is closest
  to, and the part of it your MVP keeps. `/brainstorm` asks for it.
- **`/start` spots a clone still wired to this repo** and suggests renaming
  `origin`, so your pushes and pull requests go to your game — on every path,
  a returning user's included, and not for your own fork.
- **Skills pre-approve only the commands they run.** `/help`, `/scope-check`,
  `/asset-audit`, `/project-stage-detect` and `/reverse-document` allowed any
  shell command while active; each now names its commands. `/prototype` and
  `/vertical-slice` no longer claim a worktree isolation skills cannot have, and
  `/design-review` says which flag wins when given both `--depth` and `--review`.
  `/help` accepts the quoted form of its one script, which it was denied about
  half the time, and that script no longer fails when `MSYS_NO_PATHCONV` is set.
- **Skill model pins are documented as they behave.** A skill you type as
  `/skill-name` runs on the model it declares, except that auto mode ignores a
  Haiku pin. A skill Claude starts on its own runs on your session's model. So
  `/gate-check`, `/architecture-review` and `/review-all-gdds`, which declare
  Opus, cost more when typed in a Sonnet session. The docs had said pins were
  never applied.
- **Agent models are documented as they run**, with the one-line setting that
  fixes a pinned agent overflowing a large-context session
  ([#67](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/67)).
- **Agent specs can be run, and they match the agents.** `/skill-test spec` and
  `/skill-test category` looked only in `.claude/skills/`, so every agent spec
  in the testing framework was refused as not found; both now take an agent
  name. The specs stated models no agent declares (36 of 49 — the three
  directors and `lead-programmer` named the right tier, but as a full model
  ID) and checked `allowed-tools:`, a skill field agents don't have. Each now
  asserts its agent's own `model:` and `tools:`.
  Tiers are written as the aliases `model:` takes — `opus`, `sonnet`, `haiku`,
  `inherit` — never as model IDs, so a new model release leaves them correct;
  the agent roster and gate index no longer repeat them
  ([#131](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/131)).
- **`devops-engineer` and `community-manager` run on Sonnet.** They were the
  only agents pinned to Haiku, the tier `model-tiers.md` keeps for read-only
  lookups and formatting. One builds your CI pipelines and the other writes what
  your players read — the judgement `/patch-notes` is on Sonnet for.
- **Every behavioral spec describes the skill or agent as it is.** A full
  `/skill-test spec` run failed all 121 specs in the testing framework. Most
  had been written against older versions and expected verdict words, paths and
  features the skills and agents don't have — `/help`'s spec expected "HELP
  COMPLETE", a word the skill has never used. Each spec is rewritten against
  its current skill or agent, and each case still tests a specific behavior.
  `/skill-test` now judges an agent by what it actually sees: its own file,
  `CLAUDE.md` and the files it imports, the gate definition for a gate case, and
  any skills it preloads. A rule every agent receives, such as escalating a
  conflict to the shared parent, is no longer reported missing from each one.
- **Directors answer each gate in its own words.** The four directors were told
  to answer every gate APPROVE / CONCERNS / REJECT (the producer REALISTIC /
  CONCERNS / UNREALISTIC), but eight gates define their own — `PR-MILESTONE` is ON
  TRACK / AT RISK / OFF TRACK, `TD-FEASIBILITY` VIABLE / CONCERNS / HIGH RISK,
  `PR-SCOPE` REALISTIC / OPTIMISTIC / UNREALISTIC, `AD-CONCEPT-VISUAL` CONCEPTS /
  STRONG / CONCERNS,
  every phase gate READY / CONCERNS / NOT READY — and the skills act on those words, so
  `/milestone-review` could never see OFF TRACK and refuse a GO. Each director
  now reads the verdict words from the gate's definition file. `/map-systems`
  and `/brainstorm` handle PR-SCOPE's OPTIMISTIC, which they had never expected.
- **Agents preload only skills they can run.** `game-designer` and
  `creative-director` preloaded `/design-review` and `/brainstorm`, which need
  tools those agents don't have, and `producer` preloaded the skills that spawn
  it for a gate. Those preloads are gone.
- **Unity and Unreal agents check their engine reference** before suggesting an
  API, as the Godot agents already did, and every engine agent asks which
  editor is installed when the pin says `NOT DETERMINED`. `godot-specialist` no
  longer tells itself to use WebSearch, a tool it doesn't have.
- **Agents that don't write code no longer follow a programmer's workflow.**
  `qa-lead`, `sound-designer`, `writer`, `performance-analyst`,
  `community-manager`, `release-manager`, `analytics-engineer` and
  `localization-lead` asked "static utility class or scene node?" and offered to
  write tests; each now drafts, proposes and asks before writing.
- **`security-engineer` rates findings on `/security-audit`'s scale** — CRITICAL
  / HIGH / MEDIUM / LOW, HIGH counting as CRITICAL in multiplayer — when you ask
  it directly, not only inside the audit.
- **Agents name each other where their work meets**: `network-programmer` and
  `security-engineer`, `writer` and `world-builder`, `art-director` and
  `audio-director`, `ux-designer` and `accessibility-specialist`, and others.
  `live-ops-designer` leaves prices to `economy-designer`, as `/team-live-ops`
  already did; agents with a built-in budget (latency, bandwidth) use the
  project's figure when it gives one.
- **`devops-engineer` follows trunk-based development.** It prescribed GitFlow —
  a long-lived `develop` branch with feature branches cut from it — while
  CLAUDE.md sets trunk-based. It now describes the trunk flow `/team-release`
  and `/hotfix` now use too: short-lived branches off `main`, releases tagged
  on `main`, a release branch only to stabilise one. `release-manager` and
  `/hotfix` merge fixes back to `main` rather than a "development branch", and
  two hook samples in `hooks-reference/` no longer assume `develop`.
- **Director memory stays in the project.** `creative-director`, `producer` and
  `technical-director` kept their memory in your home folder, shared by every
  project on the machine. Like the other 14 agents, they now keep it in the
  project's gitignored `.claude/agent-memory/`. Notes already in the home folder
  are not moved — [UPGRADING.md](UPGRADING.md#v111--v112) says how to keep them.
- **Python 3 and Bash are listed as required** — every skill reads
  `project.yaml` through Python, and every hook runs in Bash. Install steps lead
  with Claude Code's native installer, and the VS Code extension's own
  permission setting is named; counts, links and examples that had drifted are
  corrected.
- **Engine commands say how to run on a Mac.** `/smoke-check` wraps each
  engine run in `timeout`, which macOS does not have; it now names `gtimeout`
  (Homebrew `coreutils`) and a `perl` form that needs nothing installed.
  `/setup-engine` says no engine is on `PATH` on macOS either, and names the
  Godot binary inside its app bundle, so `commands.*` gets a path that runs.
- **The reference docs match Claude Code 2.1.282**: hook schemas (the 10,000-
  character output cap, SessionStart's `fork` source, every exit-2 event), the
  effects map, context windows, director-gate model tiers, and
  the bundled review command (`/review`).
- **A Proposed ADR blocks a story again.** In 1.1.0 `/dev-story` stopped reading
  an ADR's status, so a story built on an unaccepted decision went ahead. It
  now stops and tells you to accept the ADR with `/architecture-decision
  accept`. `/create-stories` reads the status it marks stories Blocked on, and
  stops when the epic you name doesn't exist; `/story-readiness` reports a
  Proposed or missing ADR as BLOCKED at every `workflow` tier, as `/dev-story`
  stops on it. Accepting an ADR keeps its `## Date`: rewriting it made every
  story drafted against the Proposed ADR look out of date to `/dev-story`.
- **`/architecture-review` writes the traceability index where the gate reads
  it**, `docs/architecture/requirements-traceability.md`. It had named no path,
  so the Pre-Production gate could not find the file outside `rtm` mode.
- **One evidence rule, everywhere.** `/test-evidence-review`, `/qa-plan`, the
  evidence template and the effects map now agree with `/story-done`: a UI
  story closes on its retained screenshots, a Visual/Feel story on screenshots
  and sign-off, and no `qa.level` waives either. `/test-evidence-review` checks
  the evidence path the story names before guessing, looks in each engine's test
  folder, and no longer asks UI stories for three sign-offs and a walkthrough.
  `/test-setup` creates `production/qa/evidence/`, and `/smoke-check` counts
  only files your engine's test runner can run.
- **One bug severity scale.** `/bug-report` filed S2-Major, S3-Minor and
  S4-Trivial, which `/bug-triage` doesn't read, and `/hotfix` called a bug with
  a workaround S2, which triage calls S3. `/bug-report`, `/hotfix`, `qa-lead`,
  the release and launch checklists and the incident template now use S1
  Critical / S2 High / S3 Medium / S4 Low. `/bug-report` numbers a new bug one
  past the highest existing ID, and `/team-qa` files bugs the same way —
  `BUG-0001.md`, where it wrote `BUG-001-[slug].md` — so `/bug-report verify`
  and `close` find any bug by its number, older ones included.
- **Director reviews go to the director the gate names, and only in the modes
  that run them.** `/art-bible` sent its review to `creative-director` instead
  of `art-director`, and `/create-architecture` reviewed its own architecture
  in every mode instead of spawning `technical-director`. A rejected
  architecture can no longer be accepted. `/create-control-manifest` and
  `/propagate-design-change` read the review mode they branch on;
  `/architecture-decision` names the reviewers it actually spawns; and
  `/team-narrative` runs its narrative consistency review in every review mode
  when `narrative-director` is on the team, and says so when it is not.
- **`/gate-check` can pass at `standard`.** It required "all four directors"
  READY after narrowing the panel, and on entering Systems Design it
  recommended `/create-architecture` instead of `/map-systems`. `/map-systems`
  no longer skips its verdict and session save when a review is skipped.
- **Every verdict has a word for "could not check".** `/release-checklist`,
  `/regression-suite`, `/consistency-check` (with an empty registry, a name
  the registry doesn't have, or no GDDs in scope),
  `/content-audit`, `/story-readiness` and `/tech-debt` (with no register)
  report NOT ASSESSED instead of passing, and `/prototype` recommends NOT
  ASSESSED for a prototype nobody has played. In `/team-qa` an open S1 or S2 bug
  means NOT APPROVED even when other evidence is missing; it read as NOT
  ASSESSED. `/security-audit`'s
  FIX CRITICALS FIRST is now **FIX BEFORE SHIPPING** — open HIGH findings, no
  CRITICAL — with a rule for choosing each verdict. `/qa-plan`, `/bug-triage`,
  `/perf-profile` and `/story-done` (for a deferred criterion) always end with
  a verdict, and `/code-review`, `/asset-audit` and `/review-all-gdds` use one
  verdict scale each.
- **Team skills spawn every agent they use.** Each `team.size` set in
  `/team-audio`, `/team-level`, `/team-release` and `/team-live-ops` now
  includes the agents its own steps call, which were otherwise never spawned.
  `/team-narrative` drafts in `production/narrative/` and asks once before
  writing the finals to `design/narrative/`. `/team-combat` says when no engine
  is set, and `/team-level` and `/team-ui` show usage when given no argument.
  At `team.size: studio`, the "adversarial review pass" in `/team-combat`,
  `/team-ui` and `/team-polish` is now defined — that phase's reviewers are told
  to find how the work breaks, and the report says the pass ran — and extras
  that no step defined were removed from `/team-audio`, `/team-polish`,
  `/team-narrative` and `/team-live-ops`.
  `/team-narrative` at `small` adds its lore and localization agents only at
  `review_mode: full`.
- **Skills ask before they write, and write what they say.** `/dev-story`,
  `/sprint-plan`, `/patch-notes`, `/localize` and `/adopt` wrote files without
  asking, or wrote files the question didn't name. `/create-architecture` writes
  once, at the end. `/perf-profile` can save the report it offers, `/tech-debt`
  no longer appends a debt item that's already in the register, and
  `/consistency-check` no longer offers to save a report it has no path for.
- **`/skill-improve` no longer discards your uncommitted edits.** It reverted a
  rejected change with `git checkout`, dropping every edit to the skill since
  your last commit; it now restores the copy it saved.
- **Test helpers compile on Unity and Unreal.** `/test-helpers` put them under
  `tests/helpers/`, which neither engine builds; they now go in each engine's
  test folder, and the Godot scene helper no longer extends a test suite.
  `/test-flakiness` names quarantine mechanisms from each test framework's own
  documentation, and says Unreal's is not covered.
- **Templates match what the skills write.** The reverse-documentation GDD
  template has all eight standard sections. The art bible template had a
  different set of sections from the nine `/art-bible` writes; it now has those
  nine, and `/art-bible` creates the file from it. `/ux-design`'s HUD spec has
  the sections `/ux-review` checks, so a HUD spec can now be approved, plus the
  Information Hierarchy and Acceptance Criteria its template always had; a UX
  spec gains the input-method checklist and the Platform Target line
  `/ux-review` asks for. Templates and skills use the same section names, and
  `/art-bible` and `/ux-design` list an existing document's sections by them.
- **`/create-epics` works at `minimal`**, building epics from the brief instead
  of stopping for GDDs. `/setup-engine` asks whether an Unreal project's
  gameplay lives mostly in C++ or in Blueprints, and other skills fix smaller dead ends: `/onboard`
  without a role, `/playtest-report` without an argument, a failed smoke test
  in `/hotfix`, and `/retrospective` pointing at the read-only `/sprint-status`.
- **Directors can say they could not judge.** A director gate can now answer
  NOT ASSESSED, naming the input it did not get, instead of picking a
  confident word; every skill that spawns one treats it as "not approved" and
  says what was missing. "Revise flagged items" now means the specialist
  re-drafts the section and you approve it again before it is written.
- **`/sprint-plan` no longer sets your review mode.** On the first `new` sprint
  of a project it asked for a review depth and wrote it into `project.yaml` and
  `production/review-mode.txt`, overriding `modes.rigor` for good. It now uses
  the resolved mode; `/settings` changes it when you mean to. It also numbers the
  new sprint after the last one and carries unfinished stories over.
- **Checks that could pass on nothing now say so.** `/asset-audit` said
  COMPLIANT with zero assets scanned — and on every Unreal project, whose assets
  live in `Content/`; `/balance-check` said HEALTHY with no targets to compare;
  `/code-review` said APPROVED when the engine review never ran. Each now
  reports NOT ASSESSED, as do `/launch-checklist`, `/team-polish`,
  `/localize qa` and `/project-stage-detect` where they could not check.
  `/security-audit`'s FIX BEFORE SHIPPING now outranks NOT ASSESSED, so an open
  HIGH finding is never hidden behind a category it could not scan.
- **The release gate checks security and localisation.** `/gate-check release`
  reads the newest `/security-audit` (at `standard` and `full`, an open CRITICAL
  or HIGH blocks it) and each locale's `/localize qa` result (required at
  `full`), and names the bug severities that block per tier (S1–S3 at `full`,
  S1 below). It is a readiness gate, run before shipping: the release checklist,
  changelog, security audit and localization checks now sit in the Polish phase
  in `/help` and the workflow guide, and `/team-release` expects the stage to
  read `Release` already.
- **Releases and hotfixes are trunk-based everywhere.** `/team-release` tags
  `main` and cuts a release branch only to stabilise one; `/hotfix` starts from
  the release tag and merges back to `main`. `/team-release` has
  `release-manager` write the patch notes — `community-manager` has no shell to
  run `/patch-notes` — and `community-manager` writes the announcement from them.
- **The guides name the right gate.** The workflow guide named every phase gate
  one phase late and showed a `/gate-check concept` that does not exist;
  `/design-system`, `/map-systems` and the systems-index template sent you to the
  wrong gate once your GDDs were done. `/gate-check`'s argument is the phase
  you are entering, everywhere.
- **More asking before writing.** `/start` asks before writing `project.yaml`;
  `/dev-story` asks before marking a story In Progress; `/team-combat` writes the
  GDD itself after asking; nine design agents ask before creating a skeleton
  file; `/create-architecture` no longer overwrites an existing architecture
  document, and its focus runs now save their section.
- **The default path, more of it.** `/help` reads your checkpoint at `minimal`,
  so it recommends `/story-done` after `/dev-story` instead of `/dev-story`
  again; `/quick-design` works on a system with no GDD from the brief and the
  story; `/qa-plan`, `/story-readiness`, `/dev-story` and `/team-qa` no longer
  waive a UI story's screenshot at `qa.level: minimal`.
- **Agents.** `accessibility-specialist` drafts findings instead of following a
  programmer's workflow; `security-engineer` reports in `/security-audit`'s
  format; `godot-specialist`, `unity-specialist` and `unreal-specialist` say
  when a request is for another engine;
  and dozens of agents state rules their specs expected but their files left
  implied. A `.gdextension` example commented with `#` swallowed its
  `[libraries]` section — ConfigFile comments start with `;`.
- **Verdicts and records that could mislead.** `/security-audit` let a
  category it could not scan replace FIX BEFORE SHIPPING with NOT ASSESSED; a
  known HIGH now decides. It also says when `security-engineer` was not
  spawned. `/team-qa` no longer records a manual-QA result the tester did not give, and its qa-lead drafts the
  sign-off for you to approve instead of writing it first. `/bug-report verify`
  says CANNOT VERIFY when the related test did not run, and never puts an email
  address in a bug. `/consistency-check` at `standard` compares only the
  required sections. `/create-architecture` runs its director review after a
  one-section update too. `/dev-story` and `/create-stories` read an ADR's
  status in one step even with a blank line under each heading. The shipped
  `.gitignore` no longer drops gdUnit4's test runner (`addons/gdUnit4/bin/`),
  and `/team-narrative` reads the project's canon before any agent drafts.
- **Team skills ask before agents write code.** `/team-combat`, `/team-audio`,
  `/team-ui` and `/team-polish` let their agents write code, shaders and audio
  files as if they were drafts, without asking; each agent now lists the files
  it will create or change, and the skill asks once for the set.
  `security-engineer` rates its own findings in `/security-audit`, and a
  category the audit could not scan is never reported as reviewed. In
  `/gate-check`, answering "no" to a manual check fails that item instead of
  leaving it unchecked. `/skill-test`'s category mode says which verdict it
  gives when, `/patch-notes` maps its categories onto your template's sections,
  and `/create-control-manifest` names the source of each naming and budget rule.
- **Handoffs name every step the next gate reads.** `/create-architecture`'s
  handoff now lists `/architecture-review`, which `/gate-check pre-production`
  requires, and `/create-control-manifest`. `/team-combat` sizes its design
  document by `modes.workflow`, as `/design-system` does — all eight sections
  only at `full`, optional at `minimal` — and starts it from the GDD template,
  `## Summary` included. `/brainstorm` asks before changing a scope the producer
  calls unrealistic, and a blocked agent's report names what was missing and
  where it was expected. `/create-architecture` asks you to approve its API
  boundaries like every other section, `/review-all-gdds` reports how many of
  the GDDs present it reviewed and names any it could not read, `/team-live-ops`
  no longer starts economy design before you approve the theme and says what to
  do when an ethics flag blocks the plan, and `/team-release` keeps its 48-hour
  watch in the post-release phase.
- **`/gate-check` passes a project that is ready.** Directors were told "none"
  for work a later phase does — the architecture before Pre-Production, the
  sprint plan before Production — and read it as missing; it is now passed as
  "not expected before [phase]". The four phase-gate reviews judge readiness for
  the phase being entered, against that gate's required artifacts at your tier.
  On CONCERNS you can advance by accepting the listed risks, which the gate
  report records under Accepted Risks; a FAIL or NOT ASSESSED never moves the
  stage. At `workflow: minimal` the production gate no longer asks for a
  Vertical Slice — two checks on the current build replace it (the core loop is
  fun, it runs end to end) — and the technical-setup gate passes with its "not
  applicable" note. An unplayed Vertical Slice reads NOT ASSESSED, not FAIL,
  and at `lean` and `solo` a skipped art-bible sign-off is not counted missing.
  The release gate no longer asks for a localisation QA report for the source
  language, reads the newest full-scope security audit so a narrower later one
  can't clear an open HIGH, and names only `/release-checklist` as the release
  checklist. `technical-director` and `creative-director` ask before writing a
  decision down, as `producer` did.
- **A release waits for the release gate.** `/team-release` could tag and deploy
  while the project was still in Polish, recommending `/gate-check release`
  afterwards. It now stops before spawning anyone unless the stage reads
  `Release`; proceeding anyway takes an explicit override, written into the
  go/no-go record. Its QA step uses the release gate's bug thresholds (S1; S1–S3
  at `workflow: full`), and its agents each write their own sign-off file — two
  wrote to one and could overwrite each other. `/release-checklist` read open
  bugs from the milestone file, which lists none; it reads `production/qa/bugs/`
  and says NOT ASSESSED when there are no bug records. `/launch-checklist` never
  asked about what only a person can confirm (on-call, EULA, press keys), so it
  could only end NOT ASSESSED; it now asks once per section (yes / no / not yet
  / N/A), so READY and CONDITIONAL are reachable, and no longer creates
  `production/releases/` before you approve the write. `/day-one-patch` asks once
  before `lead-programmer` changes code and runs tests with `commands.test`.
  `/hotfix` defines S1 as `/bug-triage` does and records `Tests: NOT RUN` when
  `commands.test` is unset. `/localize` requires a QA PASS or PASS WITH
  CONDITIONS for each translated locale at `workflow: full` only (recommended at
  `standard`), as the gate does.
  `release-manager` runs `/patch-notes` itself, `community-manager` follows your
  project's voice guide over its defaults, and `devops-engineer` no longer asks
  game-code architecture questions.
- **QA works at every `qa.level`.** `/team-qa` at `minimal` covers a Logic story
  with no test by walking its acceptance criteria, where every sign-off ended NOT
  ASSESSED; it reads the bugs already on file before QA starts, so an open S1 or
  S2 is known up front, handles a smoke report that says NOT ASSESSED, and finds
  `sprint-003.md` for `/team-qa sprint-3`. `/test-evidence-review` follows
  `qa.level` (a missing test is WAIVED at `minimal`) and takes each story type's
  gate level from `testing.strict`. `/bug-report verify` runs your
  `commands.test`, and can verify a bug no test covers by asking whether you
  played the reproduction steps; `close` shows the closure record and asks before
  changing the bug file — it wrote first. `qa-tester` writes bugs in
  `/bug-report`'s format, so `/bug-triage` and `/milestone-review` count them.
  `/bug-triage` with no bug files ends with a verdict, and `/milestone-review`
  calls an overridden OFF TRACK a CONDITIONAL GO.
- **Stories, ADRs and sprints agree.** `/dev-story` wrote `in_progress` to
  `sprint-status.yaml`, which nothing else reads; it now writes `in-progress`, and
  after an unfinished run the checkpoint says to resume `/dev-story` instead of
  "Next step: /story-done". At `workflow: full` a story with `ADR: N/A` no longer
  stops `/dev-story`; a Deprecated or Superseded ADR now blocks a story, naming
  its successor. `/architecture-decision accept` finds the blocked stories it
  should unblock — it searched for a status form `/create-stories` never
  writes. `/story-done` picks the next story from the same list as `/help`, and
  asks you about behaviour criteria instead of reading them off the code.
  `/code-review` could approve code whose ADR it could not read; that is now NOT
  ASSESSED. `/scope-check` and `/sprint-status` read the three-digit sprint names
  `/sprint-plan` writes, and `/propagate-design-change` says how it finds
  Foundation-layer ADRs.
- **Team skills say what they did.** `/team-polish` had `performance-analyst`
  fix code its own agent file forbids it to write; its report is now the
  optimisation list with an owner per item, `engine-programmer` (added to the
  `small` and `studio` sets) and `tools-programmer` implement it after one ask
  for the whole set, and at `individual` the list is handed to `/dev-story`. The
  team skills said directors "still spawn at phase gates", which none did; a
  phase gate is now a decision point the pipeline lists, in every automation
  mode. `/team-audio`, `/team-level`, `/team-live-ops` and `/team-ui` name a
  working file per agent where they said `[path]`. `/team-audio` keeps the sound
  bible at `design/audio/sound-bible.md`, out of the GDD checks. `/team-combat`,
  `/team-audio`, `/team-narrative` and `/team-ui` no longer end a plain COMPLETE
  when a check could not run: the verdict names it (`COMPLETE — engine
  validation NOT ASSESSED (…)`). An "ADR is Proposed" blocker points at
  `/architecture-decision accept`.
- **`/security-audit` reports keep their findings.** Reports are named by scope
  (`security-audit-[date]-[scope].md`), so a same-day `quick` run no longer
  overwrites the full audit. `security-engineer` gets a fixed brief that says
  every finding is rated from its table — it could arrive with findings
  already rated — and a category the audit had no source for (the usual case
  on Unity and Unreal) is named with how to fix it. The credential scan also catches
  `ApiKey`, `sk_live_…` and each engine's log call.
- **Design skills finish on the path you're on.** `/art-bible` records a
  skipped sign-off in the art bible's header (`SKIPPED [date] — [mode] mode`),
  so the production gate finds it; asks you when `art-director` and
  `technical-artist` disagree on an asset standard, as it already did for UX;
  and at `workflow: minimal` hands off to `/create-stories` and `/dev-story`
  instead of GDDs and architecture. `/prototype` names the minimal route and
  reports NOT ASSESSED for a build nobody has played. `/adopt` audits the brief
  against its template at `minimal` and says Concept has no gate to run.
  `/tech-debt add` checks the register for a matching entry before appending.
  `/ux-review` marks Pattern Library N/A for a HUD spec instead of NOT
  ASSESSED, and the UX templates carry the `Template` line it picks its
  checklist by. `/ux-design`, `ux-designer` and the accessibility template agree
  on who sets the accessibility tier.
- **`/skill-test` judges the same way in every mode.** Category mode ranked NOT
  ASSESSED differently from static and spec mode, and dropped a skill missing
  from the catalog from `category all`; unparseable frontmatter is now
  NON-COMPLIANT, and agents are listed from `.claude/agents/`. The spec
  templates use the headings the specs do.
- **The skill-flow diagram shows each step in its phase.** Release preparation
  (`/security-audit`, `/localize qa`, `/release-checklist`, `/changelog`,
  `/patch-notes`) sits in Polish, before the release gate that checks it, and
  the test framework and accessibility specs sit in Technical Setup, before the
  gate that requires them at `full`. Five output paths now match what the skills write,
  and the effects map names the skills that read `project.stage`,
  `commands.test`, `testing.strict` and `qa.level`, and those that write the stage.
- **Team skills say plainly that they run no director gate.** The `review_mode`
  note in all nine still said `lean` runs the four director phase gates, though
  no team pipeline has one.
- **A team pipeline that skipped an agent ends BLOCKED.** Choosing "skip this
  agent and note the gap" lets the other phases run, but the verdict names the
  gap instead of reading COMPLETE.
- **`/code-review` no longer reads as ranking `NO ADRS FOUND` above an
  approval.** The ranking sentence belonged to NOT ASSESSED.
- **Accepting an ADR unblocks only the stories waiting on it.** A story still on
  a superseded ADR, which names the new one as its successor, stays Blocked. The
  advice for that story now says to edit its ADR field — `/create-stories` never
  rewrites an existing story — and the effects map lists `Deprecated` and
  `Superseded` ADRs as blocking, as the skills do.
- **Smaller gaps closed.** `/setup-engine` asks before writing a new engine
  `VERSION.md`; `/release-checklist`'s report says how many files its
  TODO/FIXME/HACK counts cover; `/team-combat` defines NEEDS WORK; `/team-live-ops`
  waits for both parallel phases before writing content; `/map-systems` shows the
  revised map after a rejected boundary review; `/review-all-gdds` flags both GDDs
  of a contradiction and names a GDD that is present but empty on its `Not read:`
  line; declining `/architecture-decision`'s retrofit writes nothing.
- **Agents state what they used to leave implied.** performance-analyst escalates
  code-quality trade-offs to technical-director; release-manager schedules from
  the dates you give it; sound-designer specs list attenuation detail; the Godot
  GDExtension specialist redirects GDScript and shader work and lists the rebuild
  steps for an upgrade; the GDScript specialist wants profiler evidence before
  moving code to GDExtension; network-programmer answers hosting questions with
  the network-side contract only; technical-artist names particle-specific
  reductions.

Every engine command on Windows was run on Godot 4.6.1 (gdUnit4 6.1.3), Unity
6000.3.23f1 and Unreal Engine 5.7 before it was written down, and the Godot and
Unreal CI templates ran on GitHub Actions. The Unreal commands for Linux and
macOS, the Unity CI template and the Unity assembly-definition guidance were
checked against their documentation, not run. Checked on Claude
Code 2.1.281 to 2.1.284, on Windows, Linux (bash 5 and 3.2) and macOS. **If you ran `/setup-engine` on 1.1.0 or 1.1.1**, your
`project.yaml` still holds the old test and build commands —
[UPGRADING.md](UPGRADING.md#v111--v112) lists what to change.

---

## [1.1.1] — 2026-09-24

**Skills and agents work again outside auto mode.** A fix release for
[#128](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/128).

### Fixed

- **Skills no longer abort before they start.** In 1.1.0, every skill that reads
  your config began with a shell command Claude Code refuses to run unless it is
  explicitly approved. In the permission mode Claude Code Game Studios ships with (`default`), 66 of
  the 74 skills stopped before doing anything, from any subdirectory of your
  project, and whenever Claude invoked a skill on its own — in auto mode too.
  Each skill now runs the config lookup as one plain command and pre-approves
  exactly that command in its own frontmatter. Nothing else is approved.
- **`game-designer` and `creative-director` launch again.** Both preload skills,
  so the aborting command stopped them at startup with `Shell command permission
  check failed … Contains expansion`. They keep their preloaded skills and still
  have no shell access.
- **Skills find `project.yaml` from any folder.** A skill run in a session
  started inside `src/` or `design/` now reads the project's `project.yaml`, not
  nothing. Claude Code itself still loads the project's hooks, deny rules and
  permission mode only when it is started at the project root.
- **`/changelog` works in a repository with no commits yet.**

Checked on Claude Code 2.1.277 and 2.1.281, in every permission mode, from the
project root and from subdirectories. See `.claude/docs/config-resolution.md`
for the form every skill's config line must take, if you write your own.

---

## [1.1.0] — 2026-09-23

**One config file, and a process weight you choose — one you can see and adjust,
not a question you answer once at setup and forget.** A solo game jam and a
studio production no longer have to carry the same overhead.

### Added

- **Sessions start in ask-before-write mode.** Claude Code Game Studios sets Claude Code's
  permission mode to `default` in the project settings, so a terminal session
  started at the project root asks before writing, even if your own Claude Code
  config runs in an auto-accept mode. It sets the starting mode only: resuming a
  session, switching modes mid-session, the VS Code extension and the Desktop
  app can still put you in another one. `.claude/docs/setup-requirements.md`
  lists them, and how to change the starting mode.

- **`project.yaml` — one place for your project's configuration.** Engine,
  naming conventions, specialists and process settings all live here. It
  replaces three separate files that used to hold this between them.

- **`project.local.yaml` — your personal settings, not your team's.** Git
  ignores it, so you can run leaner reviews or fewer confirmations on your own
  machine without changing anything for anyone else.

- **`modes.rigor` — one question instead of six.** Set `minimal`, `standard` or
  `full` and it configures six underlying settings at once. You can still
  override any single one; the rest stay where rigor put them.
  - **`minimal`** — no design documents required, terse writing, light test
    evidence. The fastest route from setup to running code.
  - **`standard`** — 5 required design sections, balanced depth.
  - **`full`** — all 8 design sections, thorough docs, full test evidence on
    every story.

- **Per-system exceptions.** One system can be held to a higher standard than
  the rest of the project — your combat system can require the full treatment
  while everything else stays light. Exceptions can only make requirements
  stricter, never looser.

- **A real jam path, not the full pipeline with switches turned off.**
  `minimal` now rests on a one-page game brief with six fields, replacing the
  30-section concept document, the systems breakdown and the per-system design
  docs. Four steps to running code: pick your engine → write the brief →
  `/create-stories` → `/dev-story`. On Godot, `/setup-engine` now also creates
  the `project.godot` the engine needs to open what those steps produce — until
  it did, the path delivered real source files with no project to load them, and
  the claim above was not true. **Unity and Unreal projects must still be created
  in their own editor first**; Claude Code Game Studios will not fabricate one, because it cannot
  source what those files should contain.

- **`modes.review_mode`** — how many director agents review your work.
  **On the `team-*` orchestrators, `full` and `lean` currently behave the same.**
  Those nine skills only ever call phase-gate reviewers, and `lean` is defined as
  "skip the director gates that aren't phase gates" — so it has nothing to skip.
  `solo` does differ: it turns director gates off entirely. Elsewhere (design and
  architecture review) all three levels differ as described.
- **`modes.automation`** — how often you're asked to confirm before something
  happens. In `autonomous` mode, decisions are written to a log instead of
  interrupting you. You can always list categories that must ask regardless.
  **Four skills ignore this setting on purpose and always ask:** `/setup-engine`,
  `/gate-check`, `/hotfix` and `/day-one-patch` — engine choice is a one-time
  irreversible decision, a gate verdict nobody reads defeats the gate, and the
  two release skills need explicit sign-off. See
  `.claude/docs/automation-modes.md` for the full list and reasons.
- **`qa.level`** — how much test evidence is required before a story is done.
- **`docs.density`** — how deeply written sections go.
- **`team.size`** — which agents take part by default. Affects review depth
  only; it never changes what a story has to deliver.
- **`testing.strict` per test type** — a logic story can block on a failing
  test while a visual story stays advisory.

- **`/settings`** — see your effective configuration, check one value, or
  change it. `/settings --local` writes to your personal file. It warns you when
  a change would be overridden by something else.

- **`/start` rework** — asks everything it needs up front and writes a complete
  config in one pass, instead of scattering questions across later steps.

- **Migration tooling for existing projects.** A converter moves a v1.0 project
  onto `project.yaml`. It previews by default, only deletes old files once it
  has proved every value survived, and deletes nothing if anything is missing.
  `/adopt` spots an older project and runs it for you, and you'll get a reminder
  at session start if you have old config files and no `project.yaml`.

- **Recommendations for how much process your project needs.** Describe the
  game you're making and Claude Code Game Studios suggests a level, instead of asking you to guess
  what "standard" means for a weekend jam versus a two-year production.

### Changed

- **Claude no longer starts the four risky commands by itself.** `/hotfix`,
  `/day-one-patch`, `/dev-story` and `/story-done` now run only when you type
  them. They bypass the sprint process, patch shipped builds, write game code
  and close out stories — none of that should begin because a conversation
  drifted near the topic. Everything else still gets suggested as before.
- **Engine specialists can only hand work to their own sub-specialists.** The
  Godot, Unity and Unreal specialists are now limited to the four
  sub-specialists under each of them. Previously any of them could call any
  agent in the studio. This was already the documented rule; now it is enforced
  rather than trusted.
- **Fifteen agents that never delegated no longer can.** They were carrying the
  ability to spawn other agents and never using it.

- **Light is now the default, not just the recommendation.** `modes.rigor`
  defaults to `minimal` instead of `standard`, so a project that never opens
  `/settings` gets the fast path: a one-page brief instead of a full design
  pipeline, terse writing, light test evidence, no director review panels.
  We changed this because we measured the old default. Built both ways, the
  heavier tier cost several times more to reach working code, did not produce a
  better result, and gave nothing back when someone else picked the project up.
  It was not buying more; it was buying nothing we could detect. If your project
  outgrows the light
  path, `/help` and `/gate-check` will say so, and `/settings
  modes.rigor=standard` is one command. Projects that already set `rigor`
  explicitly are completely unaffected.
- **Setup steers light by default.** `/start` now recommends the minimal,
  guided path for new projects, so you land somewhere light and step up if you
  need to.
- **Setup asks about your game, not about the framework.** The question is
  "what best describes what you're building?" — a game jam, a focused project,
  something systems-heavy — rather than "how much process do you want?"
- **Your process level is always visible.** The status line shows it next to
  your project stage, e.g. `Concept · minimal`.
- **Advice goes both ways.** `/help` can suggest tightening up as a project
  grows, not just lightening up when you sound overwhelmed.
- **Moving into Production offers a check-in** on whether the level you chose at
  the start still fits. It's a suggestion — it never changes the verdict.
- **`team.size: solo` is now `team.size: individual`**, so it isn't confused
  with `review_mode: solo`, which means something different.
- **Less of your session is spent on the framework itself.** Roughly 40% of the
  per-turn overhead was removed, leaving more room for your actual game.
- **Picking up after a `/clear` or `/compact` is more reliable.** Your session
  checkpoint is now a defined part of your session notes rather than an
  ever-growing file, so what comes back is the same every time and leaves far
  more room for actual work. Older notes can be archived without losing
  anything.

### Fixed

- **Unity and Unreal projects were silently skipping three commit and
  session checks.** The hooks that look for hardcoded gameplay values,
  unowned TODOs, undocumented gameplay systems and missing architecture
  docs all searched `src/` — which is where Godot keeps code. Unity keeps
  it in `Assets/` and Unreal in `Source/`, so on those engines the searches
  matched nothing, every check quietly did nothing, and the result was
  indistinguishable from a clean pass. They now resolve the code root from
  your engine, and if they cannot work out where your code lives they say
  so instead of reporting nothing found.

- **Godot C# projects can now hand C# work to the C# specialist.** The Godot
  specialist listed only three of its four sub-specialists, leaving
  `godot-csharp-specialist` unreachable — even though setup routes every `.cs`
  file to it. If you chose C# or Both, your game code had no specialist path.
- **The rules badge in the README said 11. There are 13.**

- **`/hotfix` now gets your approval before touching code.** It used to
  implement the fix first and collect approvals afterwards.
- **`/sprint-plan` no longer promises a review step that your settings skip.**
  It now says which reviews run at which levels.
- **`/story-done` can no longer close a story with failing acceptance criteria
  in autonomous mode.** The safeguard existed but couldn't be reached.
- **`/settings` no longer shows rigor-derived values as "locked"**, which read
  as "you can't change this" when you can.
- **`/design-system` no longer insists on 8 design sections** at levels that
  require fewer.
- **`/localize`** pointed at a command that doesn't exist.
- **`/team-narrative`** ran two phases together with no checkpoint between them.
- **Upgrade instructions no longer suggest a merge that conflicts on every
  file** for projects that don't share history with the template.
- **Upgrade instructions now tell you to check for your own customisations
  first.** Replacing the framework overwrites your edits to any file it also
  ships — agent definitions and hook registrations especially. The steps show
  you how to find those before you start, and how to keep the ones you want.
- **Re-running a review on unchanged work now offers to skip it** instead of
  repeating the whole thing at full cost.
- **Several documented settings quietly did nothing.** They looked correct and
  matched nothing.
- **Jam and prototype projects are no longer warned about design-document
  sections they were never meant to write.** The check now respects the level
  you picked.
- **Two file checks were silently doing nothing on Windows.** They ran, found
  nothing, and reported success. They now work.
- **Passing a phase gate can actually advance your project stage.** `/gate-check`
  reached the right verdict but couldn't record it.
- **`/bug-report` can now run tests**, which it always said it would.
- **Committing gameplay code no longer prints a wall of raw search output**
  alongside the warning.
- **The status line can show what you're working on** — the epic, feature and
  task breadcrumb was described in the docs but never actually appeared.
- **Fixed broken links** in the Unity reference documentation.

### Removed

- **The bundled example game and the sample session transcripts.** They
  described a project that didn't match the current workflow. Both are
  recoverable from git history if you want them.

### Deprecated

- `production/stage.txt`, `production/review-mode.txt` and
  `.claude/docs/technical-preferences.md` are superseded by `project.yaml`.
  **Nothing breaks if you keep them** — they're still read when `project.yaml`
  doesn't have a value. Run the migration script with `--finalize` when you're
  ready to retire the first two. The third is kept on purpose: it still holds
  your Forbidden Patterns and Allowed Libraries, which have no `project.yaml`
  equivalent yet.

### Known limitations

- **Windows is the verified platform.** Everything was checked on Windows.
  macOS and Linux should work but haven't been confirmed.
- **No Unity or Unreal project was compiled.** Configuration, routing and
  documentation were verified for both engines, but nothing here builds or
  launches a real project in either.
- **Some engine reference details are marked unverified rather than guessed.**
  Where a version number or API detail couldn't be confirmed from a real source,
  it's flagged in place instead of filled in with something plausible. You'll
  see the flag where it matters.

### Settings that don't do anything yet

These six are documented and accepted, but nothing reads them. **Setting one
today has no effect.** `/settings` says so when you view or change one, so you
won't configure something expecting a result:

`accessibility.target` · `cadence.sprint_length` · `cadence.milestone_length` ·
`strict_gate_checks` · `project.kind` · `features.token_budget_warn_at`

---

## Earlier releases

For v1.0 and earlier, see the version history in
[UPGRADING.md](UPGRADING.md) — each release has its own "What Changed" section
written at the time it shipped.
