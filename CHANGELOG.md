# Changelog

What's new in Claude Code Game Studios, written for the people using it.

See [UPGRADING.md](UPGRADING.md) for step-by-step upgrade instructions, and
[docs/migration-guide-v1.1.md](docs/migration-guide-v1.1.md) if you have an
existing project on the older config files.

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
