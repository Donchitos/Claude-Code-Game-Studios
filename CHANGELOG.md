# Changelog

What's new in Claude Code Game Studios, written for the people using it.

See [UPGRADING.md](UPGRADING.md) for step-by-step upgrade instructions, and
[docs/migration-guide-v1.1.md](docs/migration-guide-v1.1.md) if you have an
existing project on the older config files.

---

## [1.1.1] — 2026-09-24

**Skills and agents work again outside auto mode.** A fix release for
[#128](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/128).

### Fixed

- **Skills no longer abort before they start.** In 1.1.0, every skill that reads
  your config began with a shell command Claude Code refuses to run unless it is
  explicitly approved. In the permission mode CCGS ships with (`default`), 66 of
  the 74 skills stopped before doing anything, from any subdirectory of your
  project, and whenever Claude invoked a skill on its own — in auto mode too.
  Each skill now runs the config lookup as one plain command and pre-approves
  exactly that command in its own frontmatter. Nothing else is approved.
- **`game-designer` and `creative-director` launch again.** Both preload skills,
  so the aborting command stopped them at startup with `Shell command permission
  check failed … Contains expansion`. They keep their preloaded skills and still
  have no shell access.
- **Config is found from any folder.** Starting Claude Code inside `src/` or
  `design/` now reads the project's `project.yaml`, not nothing.
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

- **Ask-before-write now holds, whatever your personal settings say.** CCGS
  sets Claude Code's permission mode to `default` in the project settings, so
  every approval gate in the framework actually fires. If your own Claude Code
  config runs in an auto-accept mode, that used to switch the whole
  collaboration protocol off silently and agents would write files you never
  approved. Override it in `.claude/settings.local.json` if you really want to,
  but read `.claude/docs/setup-requirements.md` first.

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
  in their own editor first**; CCGS will not fabricate one, because it cannot
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
  game you're making and CCGS suggests a level, instead of asking you to guess
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
