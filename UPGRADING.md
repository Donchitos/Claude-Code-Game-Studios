# Upgrading Claude Code Game Studios

This guide covers upgrading your existing game project repo from one version
of the template to the next.

**Find your current version** — use the first of these that applies:

- **Cloned the template, or merged it:** `git describe --tags --abbrev=0` prints
  the newest release tag in your history, for example `v1.1.2`.
- **`framework.version` in `project.yaml`:** the version the file was last stamped
  with. It can lag behind after an upgrade that kept your own `project.yaml`, and a
  project from before 1.1 has no `project.yaml`.
- **`CHANGELOG.md`:** `grep -m1 '^## \[' CHANGELOG.md` prints the newest release it
  lists, which is your version while that file is still the template's.

---

## Table of Contents

- [Upgrade Strategies](#upgrade-strategies)
- [v1.1.2 → v1.1.3](#v112--v113)
- [v1.1.1 → v1.1.2](#v111--v112)
- [v1.1.0 → v1.1.1](#v110--v111)
- [v1.0 → v1.1](#v10--v11)
- [v1.0.0-beta → v1.0](#v100-beta--v10)
- [v0.4.x → v1.0](#v04x--v10)
- [v0.4.0 → v0.4.1](#v040--v041)
- [v0.3.0 → v0.4.0](#v030--v040)
- [v0.2.0 → v0.3.0](#v020--v030)
- [v0.1.0 → v0.2.0](#v010--v020)

---

## Upgrade Strategies

There are four ways to pull in template updates. Choose based on how your
repo is set up.

### Strategy A — Git Remote Merge (recommended)

Best when: you cloned the template and have your own commits on top of it —
your repo shares history with the template.

```bash
# Add the template as a remote (one-time setup; skip this if `git remote -v` already lists template)
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git

# Fetch the new version
git fetch template main

# Merge into your branch
git merge template/main
```

Git will flag conflicts only in files that both the template *and* you have
changed. Resolve each one — your game content goes in, structural improvements
come along for the ride. Then commit the merge.

**Tip:** The files most likely to conflict are `CLAUDE.md`, `project.yaml`, and
`.claude/docs/technical-preferences.md`, because you've filled them in with
your engine and project settings. Keep your content; accept the structural changes.

**If git refuses with `fatal: refusing to merge unrelated histories`**, your
repo did not start as a clone of the template (zip download, `git init` from
scratch). Do **not** force it with `--allow-unrelated-histories` — with no
common ancestor, git flags *every* template file as a conflict and you'll be
resolving hundreds of files by hand. Use Strategy A2 instead.

### Strategy A2 — Selective checkout (no shared history)

Best when: your repo has no common history with the template but you do use git.

> **First, check whether you have edited any framework files.** The checkout
> below **replaces** everything under `.claude/`. Files *you added* survive, but
> your edits to files the framework also ships are overwritten — agent
> definitions and director gates are the ones people customise most.
>
> ```bash
> git log --oneline -- .claude    # commits here mean you have customisations
> ```
>
> If that lists anything beyond your initial import, work through the restore
> step below rather than skipping it.

```bash
# One-time setup; skip it if `git remote -v` already lists template
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git
git fetch template main

# Take the framework-owned paths wholesale from the new version.
# This overwrites/adds template files but never deletes files you added.
git checkout template/main -- .claude UPGRADING.md CHANGELOG.md docs/migration-guide-v1.1.md

# The checkout is STAGED, not committed — so nothing is lost yet, and this
# lists every framework file it changed:
git diff --cached --stat -- .claude

# Restore any file whose local edits you want to keep. This is one command per
# file, deliberately: each is a decision between your version and the new one.
git checkout HEAD -- .claude/docs/technical-preferences.md   # v1.0 config; v1.1 keeps config in project.yaml
git checkout HEAD -- <any other file you customised>

git status   # review what changed before committing
```

> **Restoring a file keeps your version of it in full — including whatever the
> new release changed there.** For a file you edited lightly, it is usually
> better to take the new version and re-apply your change on top than to keep
> the old one wholesale. `git diff HEAD template/main -- <file>` shows what you
> would be giving up.

For `CLAUDE.md`, don't checkout — diff and merge by hand, keeping your
engine/project content:

```bash
git diff HEAD template/main -- CLAUDE.md
```

`project.yaml` depends on where you are coming from, and the two cases need
opposite actions:

- **Upgrading from v1.0** (the case this section is about): you have no
  `project.yaml` — it did not exist in v1.0. There is nothing to merge by hand,
  and the checkout above deliberately does not fetch it. Build it from your
  legacy files instead, which is what the converter is for:

  ```bash
  bash .claude/scripts/migrate-v1-config.sh --dry-run   # preview
  bash .claude/scripts/migrate-v1-config.sh             # writes project.yaml
  ```

  If you skip this, `detect-gaps.sh` will nudge you at the next session start —
  but do it here rather than discovering it later.

- **Upgrading from v1.1 or later:** you already have a `project.yaml` holding
  your settings. Treat it like `CLAUDE.md` — diff and merge by hand, never
  checkout, or you will overwrite your own configuration:

  ```bash
  git diff HEAD template/main -- project.yaml
  ```

---

### Strategy B — Cherry-pick specific commits

Best when: you only want one specific feature (e.g., just the new skill, not
the full update).

```bash
# One-time setup; skip it if `git remote -v` already lists template
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git
git fetch template main

# Cherry-pick the specific commit(s) you want
git cherry-pick <commit-sha>
```

Commit SHAs for each version are listed in the version sections below.

---

### Strategy C — Manual file copy

Best when: you didn't use git to set up the template (just downloaded a zip).

1. Download or clone the new version alongside your repo.
2. Copy the files listed under **"Safe to overwrite"** directly — except any
   file the list marks as yours, such as `.claude/docs/technical-preferences.md`.
3. For files under **"Merge carefully"**, open both versions side-by-side
   and manually merge the structural changes while keeping your content.

---

## v1.1.2 → v1.1.3

**Released:** 2026-10-08
**Commit range:** `v1.1.2..v1.1.3`
**Key themes:** Long skills keep their later phases after a compaction; a
question nobody answered is never an answer; the shipped allow rules approve
less; settings read the same from a subfolder

### What Changed

| Category | Changes |
|----------|---------|
| **Long skills (14)** | `/adopt`, `/architecture-decision`, `/architecture-review`, `/create-architecture`, `/design-system`, `/dev-story`, `/gate-check`, `/prototype`, `/review-all-gdds`, `/setup-engine`, `/smoke-check`, `/story-done`, `/test-setup` and `/ux-design` keep each phase in `references/<phase>.md`; their steps are unchanged. `/skill-test` and `/skill-improve` read a skill's `references/` files too |
| **Questions** | `automation-modes.md` and `effects-map.md`: a skipped, dismissed or empty answer is never an answer; 14 agents return options as a list for the skill to ask; `CLAUDE.md` and `agent-memory.md` name the three writes that need no "May I write?" |
| **Settings** | `yaml-helper.sh` reads every setting under the project root when started from a subfolder; the local `platform.cert_tier` cannot override the lock; invalid `cert_tier` and `testing.strict` values count as unset |
| **Hooks and scripts** | `validate-commit.sh` checks files a `git add` in the same command stages, skips non-system files in `design/gdd/`, checks a project in a subfolder of a larger repository, and reads Git LFS-stored JSON through its working copy; `project-coherence.sh` reads Unreal's `Build.version` |
| **Permissions** | `settings.json`: seven allow rules removed, the two pytest rules narrowed, `Edit(**/.env*)` denied |
| **Other skills** | Thirteen skills name the minimal route as a next step; registry lookups in `/design-system`, `/create-stories`, `/dev-story`, `/story-done`, `/consistency-check`, `/architecture-review`; `team-polish`, `team-ui`, `/scope-check`; `/start` writes one `modes:` block; every skill opens with a title |

No setting changes meaning, and nothing is migrated automatically.

---

### Files: Safe to Overwrite

**Existing files to overwrite (no user content):**
```
.claude/skills/**                            ← 14 skills gain a references/
                                               folder; if you edited one of
                                               them, see Merge Carefully. 39
                                               skills gain a title line
.claude/hooks/validate-commit.sh, validate-push.sh, yaml-helper.sh,
pre-compact.sh, session-stop.sh
.claude/scripts/project-coherence.sh
.claude/agents/*.md                          ← 15 agents changed; merge any
                                               you edited
.claude/docs/**                              ← EXCEPT technical-preferences.md,
                                               which is yours and unchanged in
                                               1.1.3
docs/WORKFLOW-GUIDE.md, docs/CLAUDE.md, docs/COLLABORATIVE-DESIGN-PRINCIPLE.md,
docs/engine-reference/unreal/plugins/gameplay-ability-system.md
README.md, CHANGELOG.md, UPGRADING.md        ← keep your README if it is your
                                               game's
CCGS Skill Testing Framework/
```

---

### Files: Merge Carefully

**`.claude/settings.json`** — if you have not edited it, overwrite it with the
shipped file. If you have, remove these from `allow`: `Bash(git status*)`,
`Bash(git diff*)`, `Bash(git log*)`, `Bash(git branch*)`, `Bash(git rev-parse*)`,
`Bash(ls *)` and `Bash(python -m json.tool*)`; change `Bash(python -m pytest*)`
and `Bash(py -m pytest*)` to `Bash(python -m pytest *)` and
`Bash(py -m pytest *)`; and add `Edit(**/.env*)` to `deny`. Read-only git
commands still run without a prompt after the change. **If you copied any of
the removed rules into `.claude/settings.local.json`, remove them there too:** a
copy keeps approving `git branch -D`, `--output` files and `json.tool` writes
without asking.

**`CLAUDE.md`** — if you have not edited it outside the Technology Stack, take
the shipped Collaboration Protocol section. If you have, copy its three new
lines: the exemptions under "May I write", "A skipped or dismissed question is
not an answer", and "Started outside this file's folder? Warn first".

**`.claude/rules/agent-memory.md`, `.claude/rules/skill-authoring.md`** — if you
have not edited them, overwrite them with the shipped files.

**One of the 14 long skills, if you edited it** — its `SKILL.md` now holds the
settings line, the always-apply rules and one heading per phase; each phase's
steps moved word for word into `references/<phase>.md`. Take the shipped skill,
then make your change again in the phase file that now holds that text.

**`design/registry/entities.yaml`, `docs/architecture/tr-registry.yaml`** —
these are your project's data; keep yours. Only the header comments changed.
If your TR registry has an unquoted `status: superseded-by: TR-...`, quote the
value (`status: "superseded-by: TR-combat-001"`): unquoted, the second colon
makes the file invalid YAML. `/story-readiness` reads either form.

**`project.yaml`** — optionally set `framework.version: 1.1.3`. Nothing reads it
for this release. If it has two `modes:` blocks — `/start` could write a second
one — merge them into one.

---

## v1.1.1 → v1.1.2

**Released:** 2026-09-29
**Commit range:** `v1.1.1..v1.1.2`
**Key themes:** The default minimal path end to end; engine test, build and
parse commands that report the right result; Unity and Unreal treated like
Godot; hook warnings you can see; skills that read the whole argument

### What Changed

| Category | Changes |
|----------|---------|
| **Minimal path** | `/help`, `/story-done`, `/sprint-status` and the status line follow the minimal route; about 25 default labels corrected; 10 skills and 4 director gates read `design/game-brief.md` when there is no concept doc; `/dev-story` and `/story-done` write the session checkpoint |
| **Engine commands** | `/setup-engine`, `/test-setup`, `/dev-story`, `/smoke-check`, the `qa-tester` agent and `run-and-observe.md` use commands run on Windows with Godot 4.6.1, Unity 6000.3.23f1 and Unreal 5.7; Unreal's Linux and macOS commands come from Epic's documentation |
| **Unity / Unreal** | Eight rules gain Unity (`Assets/`) and Unreal (`Source/`, `Content/`, `.usf`/`.ush`) globs; the commit and asset hooks check every engine's data folder; the status line and three checklists find the code root |
| **Hooks** | Warnings arrive as hook JSON (`hook_warn` in `yaml-helper.sh`); the commit and push checks find `git` anywhere in a command, skip quoted here-doc text, and run for the PowerShell tool; the commit check validates the staged copy of each data file; session start caps the checkpoint it prints |
| **Skills (7)** | `/adopt`, `/balance-check`, `/gate-check`, `/review-all-gdds`, `/scope-check`, `/sprint-status`, `/story-readiness` read `$ARGUMENTS`, not its first word |
| **Agents** | Nearly every agent file changed: directors answer each gate in the verdict words its definition file gives; `creative-director`, `producer` and `technical-director` keep memory in the project; `devops-engineer` is trunk-based and, with `community-manager`, runs on Sonnet; `qa-tester`'s Unity and Unreal templates compile; Unity and Unreal agents check their engine reference; agents that don't write code draft and ask before writing |

No setting changes meaning, and nothing is migrated automatically.

---

### Files: Safe to Overwrite

**Existing files to overwrite (no user content):**
```
.claude/skills/**                            ← nearly every skill changed, including
                                               gate-check/references/gate-production.md
.claude/hooks/*.sh                           ← validate-commit, validate-push,
                                               validate-assets, validate-skill-change,
                                               session-start, detect-gaps, pre-compact,
                                               post-compact, log-agent, log-agent-stop,
                                               log-instructions, yaml-helper
.claude/statusline.sh
.claude/scripts/artifact-check.sh, project-coherence.sh, migrate-v1-config.sh,
                                               gdd-structure-check.sh, review-scope.sh
.claude/scripts/review-receipts.sh           ← falls back to shasum, which every Mac has
.claude/scripts/godot-parse-check.gd         ← new: /dev-story's Godot parse check
.claude/scripts/story-status.sh              ← new: the story list /help and
                                               /sprint-status route from
.claude/agents/*.md                          ← nearly every agent changed (see Agents
                                               above); merge any you edited, and see
                                               Director agents' memory below
.claude/docs/**                              ← EXCEPT technical-preferences.md, which
                                               is yours and unchanged in 1.1.2.
                                               Includes templates/game-brief.md
                                               (new Reference game line)
docs/WORKFLOW-GUIDE.md, docs/skill-flow-diagrams.md,
docs/COLLABORATIVE-DESIGN-PRINCIPLE.md, docs/engine-reference/README.md
docs/engine-reference/godot/current-best-practices.md, breaking-changes.md,
deprecated-apis.md, modules/rendering.md;
docs/engine-reference/unity/current-best-practices.md,
plugins/addressables.md;
docs/engine-reference/unreal/modules/networking.md,
docs/engine-reference/unreal/current-best-practices.md,
plugins/gameplay-ability-system.md
                                             ← corrected examples; the Godot, Unity
                                               and Unreal references gain Command Line
                                               sections (build and test commands per
                                               platform, with sources). If /setup-engine
                                               has updated your copy of one, merge
                                               that file instead
README.md, CHANGELOG.md, UPGRADING.md        ← keep your README if it is your game's
CCGS Skill Testing Framework/
```

---

### Files: Merge Carefully

**`.claude/settings.json`** — if you have not edited it, overwrite it with the
shipped file. If you have, change the `matcher` of the
`PreToolUse` entry that runs `validate-commit.sh` and `validate-push.sh` from
`"Bash"` to `"Bash|PowerShell"`, and copy the new `deny` rules: the
`PowerShell(…)` ones, `Bash(git push *--force*)` / `Bash(git push * -f*)`, and
the variants of recursive delete, `git clean`, `git reset --hard` and force push
(`rm -fr`, `rm -rf*` with no space, the `--recursive` / `--force` spellings such
as `rm -r --force`, `git clean* -f*`, `git clean* -df*` and the other `git clean`
force forms, the `git *clean* …`, `git *push* -f*` / `-uf*` / `+*` and
`git *reset *--hard*` forms that also catch git options before the subcommand
(`git -C x clean -f`), `git push * +*`, `git * push *--force*`,
`Remove-Item * -r*`). The `git clean` rules name the common force forms rather
than `git clean -*f*`, which would also deny a dry run such as
`git clean -n config/`, and no allow rule can undo a deny. The `git` rules match
anywhere after `git`, so a git command whose text fits one of them is denied even
when nothing dangerous runs: a commit message that mentions one of these
commands, or plain prose such as `git commit -m "push + pull"` (`push` then ` +`)
— reword the message. A dry run written with `-f` first,
`git clean -fn`, is denied too; write it `git clean -n`. 1.1.1's
`Bash(git clean -f*)` is covered by the new rules and can go.

**`.claude/rules/*.md`** — if you have not edited a rule, overwrite it with the
shipped file. If you have, keep your text, copy
every `paths:` line from the shipped file — they changed in eight rules — and
merge the five changed bodies named below. Without
the Unity (`Assets/**`) and Unreal (`Source/**`, `Content/**`) globs the rule
never loads on those engines. Keep each glob in double quotes — an unquoted
`*` breaks the frontmatter, and a rule whose frontmatter does not parse loads
on every file. The code-rule globs now name their file types (`*.cs`,
`*.{h,cpp}`), `data-files.md`'s end in `*.json`, and five rule bodies changed:
`test-standards.md` names tests per engine, `shader-code.md`,
`gameplay-code.md` and `engine-code.md` give Unity and Unreal examples, and
`agent-memory.md` names every engine's code root.

**`src/CLAUDE.md`** — if you have not edited it, overwrite it with the shipped
file. If you have, merge: its File Routing section now
points to the `specialists` block of `project.yaml` instead of `CLAUDE.md`.

**`.gitignore`** — add `/reports/` and `/test-results/` (gdUnit4 and Unity test
output), and `!addons/gdUnit4/bin/` on the line after `bin/`: without it the
`bin/` rule keeps gdUnit4's test runner out of your commits, and a fresh clone
or CI has no runner.

**Your `project.yaml` `commands:` block** — `/setup-engine` wrote these into your
project, so updating the template does not change them. If you set up an engine
on 1.1.0 or 1.1.1:

| Engine | Key | Old (1.1.1) | New |
|---|---|---|---|
| Godot | `test` | `godot --headless --script tests/gdunit4_runner.gd` | `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode` |
| Unity | `build` | `Unity -batchmode -quit -projectPath . -buildTarget <TARGET>` | `"<Unity editor>" -batchmode -quit -projectPath . -buildTarget <TARGET> -build<PLATFORM>Player Builds/<Target>/<Game>.exe` (e.g. `-buildWindows64Player`) |
| Unity | `test` | `Unity -runTests -projectPath . -testPlatform PlayMode` | `"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml` |
| Unity | `smoke` | `Unity -batchmode -quit -projectPath . -executeMethod SmokeCheck.Run` | `"<Unity editor>" -batchmode -quit -projectPath . -logFile -` |
| Unreal | `build` | `RunUAT.bat BuildCookRun -project=<project>.uproject -platform=Win64 -build -cook` | `"<UE root>/Engine/Binaries/DotNET/AutomationTool/AutomationTool.exe" BuildCookRun -project="$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -platform=Win64 -build -cook` |
| Unreal | `test` | `UnrealEditor-Cmd.exe <project>.uproject -ExecCmds="Automation RunTests <project>; Quit" -unattended -nullrhi` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -ExecCmds="Automation RunTests <project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput` |
| Unreal | `smoke` | `UnrealEditor-Cmd.exe <project>.uproject -game -nullrhi -unattended -ExecCmds="Quit"` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -nullrhi -unattended -stdout -ExecCmds="Quit"` |
| Unreal | `run` | `UnrealEditor.exe <project>.uproject -game -windowed -ResX=1280 -ResY=720` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -windowed -ResX=1280 -ResY=720` |

Godot also needs gdUnit4 installed under `addons/gdUnit4/`. If `godot` is not
on your `PATH` (the default on Windows and macOS), `/setup-engine` now writes the
editor's full path instead: put it, double-quoted, at the start of each Godot
`commands.*` value, make the value a single-quoted YAML scalar, and record the
same path as `engine.path` —
`build: '"C:/Program Files/Godot/Godot_v4.6.1-stable_win64.exe" --headless --export-debug "Windows Desktop"'`.
For Unity,
`<Unity editor>` is the editor's full path, quoted — bare `Unity` can resolve to
Unity's separate CLI, which rejects `-batchmode` with exit 2, the same code as a
failed test. The quoted path needs a single-quoted YAML value:
`test: '"C:/Program Files/Unity/Hub/Editor/<version>/Editor/Unity.exe" -batchmode …'`.

The Unreal rows are the Windows commands. On Linux, `build` is
`"<UE root>/Engine/Build/BatchFiles/RunUAT.sh" BuildCookRun … -platform=Linux -build -cook`
and `test`, `run` and `smoke` use `"<UE root>/Engine/Binaries/Linux/UnrealEditor"`
with the same arguments. On macOS keep only `build` (`RunUAT.sh … -platform=Mac`)
and set the other three yourself: Epic documents no command-line editor inside
`UnrealEditor.app`. `/setup-engine`'s Unreal section has the exact lines.

For Unreal, `<UE root>` is the engine folder (`engine.path`) — no editor binary
is on `PATH` — and the project path must be absolute: UE 5.7 does not find a
relative `<project>.uproject` and exits 1 before running anything.
`$(pwd -W 2>/dev/null || pwd)` gives the `C:/…` form in Git Bash, even with
`MSYS_NO_PATHCONV` set. These values contain double quotes, so they take
single-quoted YAML scalars too.

**`.github/workflows/tests.yml` (Godot)** — if `/test-setup` wrote it, add
`permissions:` with `contents: read` and `checks: write` to the `test` job, as
the shipped template now does. The gdUnit4 action publishes a check run, and a
new repository's token is read-only, so without it the job fails even when
every test passes. In the test step, copy the shipped `uses:` line
(`godot-gdunit-labs/gdUnit4-action@v1`), set `godot-version` to the full release
`godot --version` prints (e.g. `4.6.1`; 1.1.1 filled in VERSION.md's `4.6`,
which is not one), and add `version: 'installed'`: without it the action deletes
the gdUnit4 you commit under `addons/` and installs the latest release. If you
protect `main`, require the `Run GdUnit4 Tests` job's check, not `test-results`,
which passes even when a test fails.

**`.github/workflows/tests.yml` (Unreal)** — if `/test-setup` wrote it, add the
`Build Editor Target` step from the shipped `/test-setup` before the test step,
set `UE_ROOT` on the runner, and replace `-log` with
`-stdout -FullStdOutLogOutput` so the results reach the CI log. The 1.1.1
template ran `Automation RunTests MyGame.`; change the filter to your project's
test root (`<Project>.`, as in `commands.test`), or no test matches. A fresh checkout
has no compiled game module, so without the build the editor quits before
running a test. Change `runs-on: self-hosted` to `runs-on: [self-hosted, windows]`:
with the bare label, GitHub can give the job to any self-hosted runner the
repository has, including a Linux one with no Unreal on it. Change each
`shell: bash` to `shell: bash --noprofile --norc -eo pipefail "{0}"`: the
Windows runner passes bash its script path unquoted, so every step fails when
the runner's folder has a space in it.

**Tests written on 1.1.x** — Unity never compiled tests under `tests/`: move them
to `Assets/Tests/EditMode/` or `Assets/Tests/PlayMode/`, each with an assembly
definition (`/test-setup` shows the layout). Unreal never built `Source/Tests/`:
move tests to `Source/<Module>/Private/Tests/`, and replace
`EAutomationTestFlags::GameFilter` with
`EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter`.

**Director agents' memory** — `creative-director`, `producer` and
`technical-director` now declare `memory: project`, so they read and write
`.claude/agent-memory/<agent>/` in this project. Notes they saved before are in
`~/.claude/agent-memory/<agent>/` and are no longer read; copy the ones that
belong to this project across. If you edited those agent files, change
`memory: user` to `memory: project` in their frontmatter.

**`production/session-state/active.md`** — no action. The first `/dev-story` or
`/story-done` adds the STATUS and CHECKPOINT blocks at the top of an older file
and leaves the rest alone.

**`design/game-brief.md`** — optional: add a `**Reference game:**` line (see the
template).

**Python 3** — now listed as required. If you ran without it, every setting was
silently at its default; install it and your `project.yaml` takes effect.

**`modes.review_mode` / `production/review-mode.txt`** — 1.1.x's `/sprint-plan`
wrote a review mode into `project.yaml` and `production/review-mode.txt` the first
time it ran, which pinned it over `modes.rigor` for good. If you did not choose
that value yourself, remove both so `modes.rigor` applies again (`/settings`
shows where each value comes from).

**`project.yaml`** — optionally set `framework.version: 1.1.2`. Nothing reads it
for this release.

---

## v1.1.0 → v1.1.1

**Released:** 2026-09-24
**Commit range:** `d056997..v1.1.1`
**Key themes:** Fix for skills and agents failing to start outside auto mode ([#128](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/128))

### What Changed

| Category | Changes |
|----------|---------|
| **Skill fix (66 skills)** | The config line at the top of each skill is now one plain `bash` command, pre-approved in that skill's own `allowed-tools`. The 1.1.0 line aborted the skill outside auto mode |
| **Helper** | `.claude/hooks/yaml-helper.sh` can be run directly as `bash yaml-helper.sh resolve_config …`, and finds the project root from its own location |
| **Docs** | `.claude/docs/config-resolution.md` documents the required form and why |

No settings, config files or agents change. Your `project.yaml` and
`project.local.yaml` are untouched apart from the version stamp.

---

### Files: Safe to Overwrite

**Existing files to overwrite (no user content):**
```
.claude/skills/*/SKILL.md                 ← all skills with a config line (66)
.claude/hooks/yaml-helper.sh              ← direct-execution entry point
.claude/docs/config-resolution.md         ← corrected "why this command" section
.claude/docs/director-gates.md            ← example line updated
```

---

### Files: Merge Carefully

**Skills you have edited yourself.** If you customised a skill, keep your
version and change two lines in it — the config line and the `allowed-tools`
entry — to this form, with your skill's folder name in place of `<name>`:

```markdown
allowed-tools: …, Bash(bash "*/.claude/skills/<name>/../../hooks/yaml-helper.sh" resolve_config *)
```
```markdown
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys <same keys as before>`
```

Both halves are needed: the line without the grant still aborts. The same
applies to any skill you wrote yourself that copied the 1.1.0 line.

**`project.yaml`** — optionally set `framework.version: 1.1.1`. Nothing reads it
for this release.

---

## v1.0 → v1.1

**Released:** 2026-09-23
**Key themes:** `project.yaml` as the single source of truth, a modes system
(`modes.rigor` fronting `workflow`/`docs.density`/`qa.level`/`story_granularity`,
plus `review_mode` and `automation`), `/settings`, `project.local.yaml`
per-developer overrides, migration tooling, token-efficiency cuts.

This is the biggest config change since the template's `production/stage.txt`
/ `production/review-mode.txt` era. Read
[CHANGELOG.md](CHANGELOG.md#110--2026-09-23) for the full list of additions —
this section covers what to do about it.

### What Changed

See [CHANGELOG.md](CHANGELOG.md#110--2026-09-23) for the complete list. The
short version: `project.yaml` replaces `production/stage.txt`,
`production/review-mode.txt`, and `.claude/docs/technical-preferences.md` as
the primary config store (all three still work as a fallback — nothing is
force-deleted), a new `modes` block controls how much process the project
carries (`modes.rigor: minimal | standard | full`), and a new `/settings`
skill views and edits any of it, including a gitignored
`project.local.yaml` for settings that should vary per developer.

### Heads-up: the process level you get by default has changed

`modes.rigor` now defaults to **`minimal`**, not `standard`. If your
`project.yaml` sets `modes.rigor` explicitly, nothing changes for you and you
can skip this.

If it does not, the upgrade is visible: any of the six knobs `rigor` fronts that
you never set moves from the `standard` row to the `minimal` row. In practice
that means fewer required GDD sections, terser writing, coarser stories, no
director review panels, and `qa.level` dropping from `standard` to `minimal`.
Knobs you *did* set explicitly are untouched.

**To keep the old behaviour, pin it in one line:**

```yaml
modes:
  rigor: standard
```

We changed the default because `standard` costs more to reach working code
without producing a better result, and gives nothing back when someone new
picks the project up. Most projects were paying for process that did not repay.
If yours is one that does -- several interacting systems, or a design someone
else has to implement -- `standard` and `full` are one `/settings` call away,
and `/help` and `/gate-check` will suggest raising it as your project grows.

### Files: Safe to Overwrite

**Take `.claude/` as a whole. Do not copy a subset.** v1.1 adds around 73 new
files under that directory — `automation-modes.md`, `workflow-modes.md`,
`config-resolution.md`, `effects-map.md`, 28 director gates, the game-brief
template, 7 guidance templates, 8 scripts, 6 gate-check references, 10
`CONTRACT.md` files — and the skills cross-reference each other across all of
them. A partial copy leaves skills pointing at documents you do not have, which
fails at the moment you run them rather than at the moment you copy. That is why
there is no short file list here.

```
.claude/          (the whole directory — new and changed files alike)
                  EXCEPT .claude/docs/technical-preferences.md — see the note below.
                  The template ships a placeholder copy of that file; overwriting
                  yours silently discards your Forbidden Patterns and Allowed
                  Libraries, which have no project.yaml equivalent. Back it up
                  before you copy and restore it afterwards.
README.md
CHANGELOG.md
UPGRADING.md
.gitignore        (adds project.local.yaml)
```

> **Strategy A (git merge) protects you here automatically** — git flags that file
> as a conflict because you both changed it. The manual-copy strategies do not:
> a recursive copy overwrites it without a word.

Your own tests under `tests/` and any tooling under `tools/` are yours; the
template ships nothing into either, so nothing there is at risk.

Copying is additive: files *you* added under `.claude/` survive, because nothing
is deleted. Only files the template also ships get replaced.

All 74 `SKILL.md` files changed in v1.1, and 66 of them now resolve config via
`resolve_config`. If you have not hand-edited any skill file, taking them all is
safe.

> **Two things under `.claude/` are yours — check them before you copy.**
>
> - `.claude/docs/technical-preferences.md` still holds your Forbidden Patterns
>   and Allowed Libraries, which have no `project.yaml` equivalent. Keep your
>   copy; see [Merge Carefully](#claudedocstechnical-preferencesmd) below.
> - Anything else you customised — agent definitions and director gates are the
>   usual ones. If your project is in git, `git log --oneline -- .claude` lists
>   whether you have any. Re-apply your edits on top of the new version rather
>   than keeping your old file wholesale; the new version almost certainly
>   changed there too.

(`project.yaml` itself is not copied from the template — `/start` generates it
for new projects, and `.claude/scripts/migrate-v1-config.sh` builds it from
your legacy config files for existing ones.)

### Files: Merge Carefully

#### `project.yaml` (new — this is YOUR data, not template infrastructure)

This file does not exist in v1.0. If you have an existing project with
`production/stage.txt`, `production/review-mode.txt`, or a filled-in
`.claude/docs/technical-preferences.md`, **do not hand-author
`project.yaml`** — those files hold your project's actual configuration and
migrating them by hand risks transcription errors the tooling is built to
avoid. Follow the dedicated
[migration guide](docs/migration-guide-v1.1.md) instead, which walks
`.claude/scripts/migrate-v1-config.sh` end to end.

If you're starting fresh (no legacy files with real values), just run
`/start` — it writes a complete `project.yaml` for you.

#### `.claude/docs/technical-preferences.md`

Stays in place. Most of its content (engine, naming, performance budgets,
testing framework, specialists) has a `project.yaml` equivalent now and is
read from there first. Two sections — Forbidden Patterns and Allowed
Libraries — have no `project.yaml` equivalent and this file remains their
home permanently; `--finalize` migration never deletes it.

### After Upgrading

1. If you have an existing project (not starting fresh), read
   [docs/migration-guide-v1.1.md](docs/migration-guide-v1.1.md) and run
   `.claude/scripts/migrate-v1-config.sh --dry-run` to see what migration
   would do before committing to it.
2. Run `/settings` to see your effective configuration once `project.yaml`
   exists — it shows you the value, source, and whether each setting is
   locally overridable.
3. Consider setting `modes.rigor` explicitly if your project doesn't match
   the `minimal` default — `/settings modes.rigor=standard` to keep the
   process level v1.0 had, `modes.rigor=full` for a project that wants every
   gate. The migration report says this too.
4. If you customised any skill, re-read it against the new version before
   relying on it — a skill that resolves config differently from the rest of
   the framework fails quietly, by taking a default branch rather than by
   erroring.

---

## v0.4.1

**Released:** 2026-04-02
**Key themes:** Art direction integration, asset specification pipeline

### What Changed

| Category | Changes |
|----------|---------|
| **New skill** | `/art-bible` — guided section-by-section visual identity authoring (9 sections). Mandatory art-director Task spawn per section. AD-ART-BIBLE sign-off gate. Required at Technical Setup phase. |
| **New skill** | `/asset-spec` — per-asset visual spec and AI generation prompt generator. Reads art bible + GDD/level/character docs. Writes `design/assets/specs/` files and `design/assets/asset-manifest.md`. Full/lean/solo modes. |
| **New director gates (3)** | `AD-CONCEPT-VISUAL` (brainstorm Phase 4), `AD-ART-BIBLE` (art bible sign-off), `AD-PHASE-GATE` (gate-check panel) |
| **`/brainstorm` update** | Added `Task` to allowed-tools (was missing — blocked all director spawning). Art-director now spawns in parallel with creative-director after pillars lock. Visual Identity Anchor written to game-concept.md. |
| **`/gate-check` update** | Art-director added as 4th parallel director (AD-PHASE-GATE). Visual artifact checks: Visual Identity Anchor (Concept gate), art bible (Technical Setup gate), AD-ART-BIBLE sign-off + character visual profiles (Pre-Production gate). |
| **`/team-level` update** | Art-director added to Step 1 parallel spawn (visual direction before layout). Level-designer now receives art-director targets as explicit constraints. Step 4 art-director role corrected to production-concepts only. |
| **`/team-narrative` update** | Art-director added to Phase 2 parallel spawn (character visual design, environmental storytelling, cinematic tone). |
| **`/design-system` update** | Routing table expanded with art-director + technical-artist for Combat, UI, Dialogue, Animation/VFX, Character categories. Visual/Audio section now mandatory (with art-director Task spawn) for 7 system categories. |
| **`workflow-catalog.yaml`** | `/art-bible` added to Technical Setup (required). `/asset-spec` added to Pre-Production (optional, repeatable). |

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/art-bible/SKILL.md
.claude/skills/asset-spec/SKILL.md
.claude/docs/director-gates.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/brainstorm/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/team-level/SKILL.md
.claude/skills/team-narrative/SKILL.md
.claude/skills/design-system/SKILL.md
.claude/docs/workflow-catalog.yaml
README.md
UPGRADING.md
```

### Files: Merge Carefully

None — all changes are to infrastructure files with no user content.

---

## v1.0.0-beta → v1.0

**Released:** 2026-05-13
**Commit range:** `49d1e45..HEAD`
**Key themes:** New `/vertical-slice` gate, skill polish & bug fixes, contributor docs

### What Changed

| Category | Changes |
|----------|---------|
| **New skill** | `/vertical-slice` — Pre-Production gate that validates the full game loop with a production-quality end-to-end build before Production. Pairs with the overhauled `/prototype` (concept validation right after `/brainstorm`). |
| **New flow** | Entity inventory step in `/map-systems` — surfaces all named entities up front for cleaner downstream GDD authoring. |
| **UX polish** | Added missing `AskUserQuestion` widgets to 7 skills; comprehensive skill audit for consistency, prompts, and flow gaps; exposed `--review` flag in `argument-hints` for all `team-*` skills. |
| **Bug fixes** | log-agent hooks logged "unknown" `agent_type`; missing `allowed-tools` in `/architecture-decision` and `/story-done`; `rg --type gdscript` is invalid (now uses `--glob *.gd`); session-start preview showed oldest state instead of newest; duplicate `## 0.` heading and broken step numbering in `/architecture-decision`. |
| **Project docs** | Added `CONTRIBUTING.md` (framework contribution guidelines) and `SECURITY.md` (coordinated disclosure policy). |
| **Counts/refs** | Synced agent/skill/hook counts across `WORKFLOW-GUIDE.md`, `README.md`, and agent rosters; fixed stale agent names and skill model-tier fields. |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/vertical-slice/SKILL.md
CONTRIBUTING.md
SECURITY.md
```

**Existing files to overwrite (no user content):**
- All files under `.claude/skills/` modified in the commit range (skill audit + AskUserQuestion widgets + `--review` argument-hints)
- `.claude/hooks/log-agent.sh` (`agent_type` logging fix)
- `README.md`, `docs/WORKFLOW-GUIDE.md`, `docs/skill-flow-diagrams.md`
- `UPGRADING.md`

---

### Files: Merge Carefully

None — all changes are to infrastructure files with no user content.

---

## v0.4.x → v1.0

**Released:** 2026-03-29
**Commit range:** `6c041ac..HEAD`
**Key themes:** Director gates system, gate intensity modes, Godot C# specialist

### What Changed

| Category | Changes |
|----------|---------|
| **New system** | Director gates — named review checkpoints shared across all workflow skills. Defined in `.claude/docs/director-gates.md` |
| **New feature** | Gate intensity modes: `full` (all director gates), `lean` (phase gates only), `solo` (no directors). Set globally via `production/review-mode.txt` during `/start`, or override per-run with `--review [mode]` on any gate-using skill |
| **New agent** | `godot-csharp-specialist` — C# code quality in Godot 4 projects |
| **Skill updates (13)** | All gate-using skills now parse `--review [full\|lean\|solo]` and include it in their argument-hint: `brainstorm`, `map-systems`, `design-system`, `architecture-decision`, `create-architecture`, `create-epics`, `create-stories`, `sprint-plan`, `milestone-review`, `playtest-report`, `prototype`, `story-done`, `gate-check` |
| **`/start` update** | Added Phase 3b — sets review mode during onboarding, writes `production/review-mode.txt` |
| **`/setup-engine` update** | Language selection step for Godot (GDScript vs C#) |
| **Docs** | `director-gates.md` — full gate catalog; `WORKFLOW-GUIDE.md` — Director Review Modes section; `README.md` — review intensity customization |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/agents/godot-csharp-specialist.md
.claude/docs/director-gates.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/brainstorm/SKILL.md
.claude/skills/map-systems/SKILL.md
.claude/skills/design-system/SKILL.md
.claude/skills/architecture-decision/SKILL.md
.claude/skills/create-architecture/SKILL.md
.claude/skills/create-epics/SKILL.md
.claude/skills/create-stories/SKILL.md
.claude/skills/sprint-plan/SKILL.md
.claude/skills/milestone-review/SKILL.md
.claude/skills/playtest-report/SKILL.md
.claude/skills/prototype/SKILL.md
.claude/skills/story-done/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/start/SKILL.md
.claude/skills/quick-design/SKILL.md
.claude/skills/setup-engine/SKILL.md
README.md
docs/WORKFLOW-GUIDE.md
UPGRADING.md
```

---

### Files: Merge Carefully

No files require manual merging in this release. All changes are to infrastructure files with no user content.

---

### New Features

#### Director Gates System

All major workflow skills now reference named gate checkpoints defined in
`.claude/docs/director-gates.md`. Gates are identified by domain prefix and name
(e.g., `CD-CONCEPT`, `TD-ARCHITECTURE`, `LP-CODE-REVIEW`). Each gate defines
which director to spawn, what inputs to pass, what verdicts mean, and how
lean/solo modes affect it.

Skills spawn gates using `Task` with the gate ID and documented inputs, rather
than embedding director prompts inline. This keeps skill bodies clean and makes
gate behavior consistent across all workflow phases.

#### Gate Intensity Modes

Three modes let you control how much director review you get:

- **`full`** (default) — all director gates run at every review checkpoint
- **`lean`** — per-skill director reviews are skipped; phase gates at `/gate-check` still run
- **`solo`** — no director gates anywhere; `/gate-check` checks artifact existence only

Set globally during `/start` (writes `production/review-mode.txt`). Override any
individual run with `--review [mode]` on any gate-using skill:

```
/design-system combat --review lean
/gate-check systems-design --review full
/brainstorm my-game-idea --review solo
```

---

### After Upgrading

1. Run `/start` once to set your preferred review mode — or create `production/review-mode.txt` manually with `full`, `lean`, or `solo`.
2. If you're mid-project, review `.claude/docs/director-gates.md` to understand which gates apply to your current phase.
3. Run `/skill-test static all` to verify all skills pass structural checks.

---

## v0.4.0 → v0.4.1

**Released:** 2026-03-26
**Commit range:** `04ed5d5..HEAD`
**Key themes:** Genre-agnostic agents, new skills, skill fixes

### What Changed

| Category | Changes |
|----------|---------|
| **New skills (1)** | `/consistency-check` — cross-GDD entity consistency scanner |
| **Skill fixes (all team-*)** | Added no-argument guards, formal `Verdict: COMPLETE / BLOCKED` keywords, per-step AskUserQuestion gates, adjacent area dependency checks (team-level), ethics enforcement (team-live-ops), NO-GO path with Phase skip (team-release) |
| **Agent fixes (4)** | Genre-agnostic language in game-designer, systems-designer, economy-designer, live-ops-designer — removed RPG-specific terms |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/consistency-check/SKILL.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/team-combat/SKILL.md      ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-narrative/SKILL.md   ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-ui/SKILL.md          ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-release/SKILL.md     ← no-arg guard, verdict keywords, NO-GO path
.claude/skills/team-polish/SKILL.md      ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-audio/SKILL.md       ← no-arg guard, verdict keywords, gate improvements
.claude/skills/team-level/SKILL.md       ← no-arg guard, verdict keywords, adjacent area checks
.claude/skills/team-live-ops/SKILL.md    ← no-arg guard, verdict keywords, ethics enforcement
.claude/skills/team-qa/SKILL.md          ← no-arg guard, verdict keywords, gate improvements
.claude/skills/map-systems/SKILL.md      ← verdict keywords
.claude/skills/create-epics/SKILL.md     ← "May I write" protocol fix, verdict keywords
.claude/skills/create-stories/SKILL.md   ← verdict keywords
.claude/agents/game-designer.md          ← genre-agnostic language
.claude/agents/systems-designer.md       ← genre-agnostic language
.claude/agents/economy-designer.md       ← genre-agnostic language
.claude/agents/live-ops-designer.md      ← genre-agnostic language
```

---

### Files: Merge Carefully

No files require manual merging in this release. All changes are to infrastructure files with no user content.

---

### After Upgrading

1. Run `/skill-test catalog` to verify all skills are indexed.
2. Run `/skill-test lint [skill-name]` after any skill edits to check structural compliance.
3. If you've customized any team-* skills, review the updated versions — no-argument guard and `Verdict:` keywords are now required for all team-* skills.

---

## v0.3.0 → v0.4.0

**Released:** 2026-03-21
**Commit range:** `b1cad29..HEAD`
**Key themes:** Full UX/UI pipeline, complete story lifecycle, brownfield adoption, comprehensive QA/testing framework, pipeline integrity, 29 new skills

### What Changed

| Category | Changes |
|----------|---------|
| **New skills (17)** | `/ux-design`, `/ux-review`, `/help`, `/quick-design`, `/review-all-gdds`, `/story-readiness`, `/story-done`, `/sprint-status`, `/adopt`, `/create-architecture`, `/create-control-manifest`, `/create-epics`, `/create-stories`, `/dev-story`, `/propagate-design-change`, `/content-audit`, `/architecture-review` |
| **New skills QA (12)** | `/qa-plan`, `/smoke-check`, `/soak-test`, `/regression-suite`, `/test-setup`, `/test-helpers`, `/test-evidence-review`, `/test-flakiness`, `/skill-test`, `/bug-triage`, `/team-live-ops`, `/team-qa` |
| **New hooks (4)** | `log-agent-stop.sh` — agent audit trail stop; `notify.sh` — Windows toast notifications; `post-compact.sh` — session recovery reminder after compaction; `validate-skill-change.sh` — advises `/skill-test` after skill edits |
| **New templates (8)** | `ux-spec.md`, `hud-design.md`, `accessibility-requirements.md`, `interaction-pattern-library.md`, `player-journey.md`, `difficulty-curve.md`, and 2 adoption plan templates |
| **New infrastructure** | `workflow-catalog.yaml` (7-phase pipeline, read by `/help`), `docs/architecture/tr-registry.yaml` (stable TR-IDs), `production/sprint-status.yaml` schema |
| **Skill updates** | `/gate-check` — 3 gates now require UX artifacts; Pre-Production gate requires vertical slice (HARD gate) |
| **Skill updates** | `/sprint-plan` — writes `sprint-status.yaml`; `/sprint-status` reads it |
| **Skill updates** | `/story-done` — 8-phase completion review, updates story file, surfaces next ready story |
| **Skill updates** | `/design-review` — removed architecture gap check (wrong stage) |
| **Skill updates** | `/team-ui` — full UX pipeline (ux-design → ux-review → team phases) |
| **Agent updates** | 14 specialist agents — `memory: project` added |
| **Agent updates** | `prototyper` — `isolation: worktree` (throwaway work in isolated git branch) |
| **Model routing** | Haiku/Sonnet/Opus tier assignments documented in coordination rules; skills declare their tier in frontmatter |
| **Directory CLAUDE.md** | Scaffolded `design/CLAUDE.md`, `src/CLAUDE.md`, `docs/CLAUDE.md` — path-scoped instructions for each directory |
| **Pipeline integrity** | TR-ID stability, manifest versioning, ADR status gates, TR-ID reference not quote |
| **GDD template** | `## Game Feel` section added (input responsiveness, animation targets, impact moments) |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/ux-design/SKILL.md
.claude/skills/ux-review/SKILL.md
.claude/skills/help/SKILL.md
.claude/skills/quick-design/SKILL.md
.claude/skills/review-all-gdds/SKILL.md
.claude/skills/story-readiness/SKILL.md
.claude/skills/story-done/SKILL.md
.claude/skills/sprint-status/SKILL.md
.claude/skills/adopt/SKILL.md
.claude/skills/create-architecture/SKILL.md
.claude/skills/create-control-manifest/SKILL.md
.claude/skills/create-epics/SKILL.md
.claude/skills/create-stories/SKILL.md
.claude/skills/dev-story/SKILL.md
.claude/skills/propagate-design-change/SKILL.md
.claude/skills/content-audit/SKILL.md
.claude/skills/architecture-review/SKILL.md
.claude/skills/qa-plan/SKILL.md
.claude/skills/smoke-check/SKILL.md
.claude/skills/soak-test/SKILL.md
.claude/skills/regression-suite/SKILL.md
.claude/skills/test-setup/SKILL.md
.claude/skills/test-helpers/SKILL.md
.claude/skills/test-evidence-review/SKILL.md
.claude/skills/test-flakiness/SKILL.md
.claude/skills/skill-test/SKILL.md
.claude/skills/bug-triage/SKILL.md
.claude/skills/team-live-ops/SKILL.md
.claude/skills/team-qa/SKILL.md
.claude/hooks/log-agent-stop.sh
.claude/hooks/notify.sh
.claude/hooks/post-compact.sh
.claude/hooks/validate-skill-change.sh
.claude/docs/workflow-catalog.yaml
.claude/docs/templates/ux-spec.md
.claude/docs/templates/hud-design.md
.claude/docs/templates/accessibility-requirements.md
.claude/docs/templates/interaction-pattern-library.md
.claude/docs/templates/player-journey.md
.claude/docs/templates/difficulty-curve.md
design/CLAUDE.md
src/CLAUDE.md
docs/CLAUDE.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/gate-check/SKILL.md
.claude/skills/sprint-plan/SKILL.md
.claude/skills/sprint-status/SKILL.md
.claude/skills/design-review/SKILL.md
.claude/skills/team-ui/SKILL.md
.claude/skills/story-readiness/SKILL.md
.claude/skills/story-done/SKILL.md
.claude/docs/templates/game-design-document.md    ← adds Game Feel section
README.md
docs/WORKFLOW-GUIDE.md
UPGRADING.md
```

**Agent files to overwrite** (if you haven't written custom prompts into them):
```
.claude/agents/prototyper.md         ← adds isolation: worktree
.claude/agents/art-director.md       ← adds memory: project
.claude/agents/audio-director.md     ← adds memory: project
.claude/agents/economy-designer.md   ← adds memory: project
.claude/agents/game-designer.md      ← adds memory: project
.claude/agents/gameplay-programmer.md ← adds memory: project
.claude/agents/lead-programmer.md    ← adds memory: project
.claude/agents/level-designer.md     ← adds memory: project
.claude/agents/narrative-director.md ← adds memory: project
.claude/agents/systems-designer.md   ← adds memory: project
.claude/agents/technical-artist.md   ← adds memory: project
.claude/agents/ui-programmer.md      ← adds memory: project
.claude/agents/ux-designer.md        ← adds memory: project
.claude/agents/world-builder.md      ← adds memory: project
```

---

### Files: Merge Carefully

#### `.claude/settings.json`

Four new hooks are registered in this version. If you haven't customized `settings.json`, overwriting is safe. Otherwise, add the following hook entries manually:

- `log-agent-stop.sh` — `SubagentStop` event (agent audit trail stop)
- `notify.sh` — `Notification` event (Windows toast notification)
- `post-compact.sh` — `PostCompact` event (session recovery reminder)
- `validate-skill-change.sh` — `PostToolUse` event filtered to `.claude/skills/` writes

#### Customized agent files

If you've added project-specific knowledge to agent `.md` files, do a diff and manually add the `memory: project` line to the YAML frontmatter where appropriate. Creative and technical director agents intentionally keep `memory: user` — only specialist agents get `memory: project`.

---

### New Features

#### Complete Story Lifecycle

Stories now have a formal lifecycle enforced by two skills:

- **`/story-readiness`** — validates a story is implementation-ready before a developer picks it up. Checks Design (GDD req linked), Architecture (ADR accepted), Scope (criteria testable), and DoD (manifest version current). Verdict: READY / NEEDS WORK / BLOCKED.
- **`/story-done`** — 8-phase completion review after implementation. Verifies each acceptance criterion, checks for GDD/ADR deviations, prompts code review, updates the story file to `Status: Complete`, and surfaces the next ready story.

Flow: `/story-readiness` → implement → `/story-done` → next story

#### Full UX/UI Pipeline

- **`/ux-design`** — guided section-by-section UX spec authoring. Three modes: screen/flow, HUD, or interaction pattern library. Reads GDD UI requirements and player journey. Output to `design/ux/`.
- **`/ux-review`** — validates UX specs against GDD alignment, accessibility tier, and pattern library. Verdict: APPROVED / NEEDS REVISION / MAJOR REVISION.
- **`/team-ui`** updated: Phase 1 now runs `/ux-design` + `/ux-review` as a hard gate before visual design begins.

#### Brownfield Adoption

**`/adopt`** onboards existing projects to the template format. Audits internal structure of GDDs, ADRs, stories, systems-index, and infra. Classifies gaps (BLOCKING/HIGH/MEDIUM/LOW). Builds an ordered migration plan. Never regenerates existing artifacts — only fills gaps.

Argument modes: `full | gdds | adrs | stories | infra`

Also: `/design-system retrofit [path]` and `/architecture-decision retrofit [path]` detect existing files and add only missing sections.

#### Sprint Tracking YAML

`production/sprint-status.yaml` is now the authoritative story tracking format:
- Written by `/sprint-plan` (initializes all stories) and `/story-done` (sets status to `done`)
- Read by `/sprint-status` (fast snapshot) and `/help` (per-story status in production phase)
- Status values: `backlog | ready-for-dev | in-progress | review | done | blocked`
- Falls back gracefully to markdown scanning if file doesn't exist

#### `/help` — Context-Aware Next Step

`/help` reads your current stage and in-progress work, checks which artifacts are complete, and tells you exactly what to do next — one primary required step, plus optional opportunities. Distinct from `/start` (first-time only) and `/project-stage-detect` (full audit).

#### Comprehensive QA and Testing Framework

Nine new QA/testing skills covering the full testing lifecycle:

- **`/test-setup`** — scaffolds the test framework and CI/CD pipeline for your engine
- **`/test-helpers`** — generates engine-specific test helper libraries (GDUnit4, NUnit, etc.)
- **`/qa-plan`** — generates a QA test plan for a sprint or feature, classifying stories by test type
- **`/smoke-check`** — runs the critical path smoke test gate before QA hand-off
- **`/soak-test`** — generates a soak test protocol for extended play sessions (stability, memory leaks)
- **`/regression-suite`** — maps test coverage to GDD critical paths, identifies fixed bugs lacking regression tests
- **`/test-evidence-review`** — quality review of test files and manual evidence documents
- **`/test-flakiness`** — detects non-deterministic tests by reading CI run logs
- **`/skill-test`** — validates skill files for structural compliance and behavioral correctness (three modes: lint, spec, catalog)

Also new: **`/bug-triage`** re-evaluates all open bugs for priority, severity, and ownership.

#### Skill Validator (`/skill-test`)

`/skill-test` is a meta-skill for validating the harness itself. Run it after editing any skill file. Three modes:
- `lint` — validates YAML frontmatter and required fields
- `spec [skill-name]` — runs behavioral spec tests against a specific skill
- `catalog` — checks that all skills in `.claude/skills/` are indexed in the catalog

The new `validate-skill-change.sh` hook reminds you to run `/skill-test` automatically when a skill file is modified.

#### Team Live-Ops and Team QA Orchestration

- **`/team-live-ops`** — coordinates live-ops-designer + economy-designer + community-manager + analytics-engineer for post-launch content planning (seasonal events, battle pass, retention)
- **`/team-qa`** — orchestrates qa-lead + qa-tester + gameplay-programmer + producer through a full QA cycle: strategy, execution, coverage, and sign-off

#### Model Tier Routing

Skills are now explicitly assigned to Haiku, Sonnet, or Opus tiers based on task complexity. Read-only status checks use Haiku; complex multi-document synthesis uses Opus; everything else defaults to Sonnet. Tier assignments are documented in `.claude/docs/coordination-rules.md`.

#### Directory CLAUDE.md Files

Three new directory-scoped CLAUDE.md files (`design/`, `src/`, `docs/`) provide path-specific instructions to agents working in those directories. These load automatically when Claude Code reads files in that directory.

---

### After Upgrading

1. **Verify new hooks** are registered in `.claude/settings.json` — check for all four: `log-agent-stop.sh`, `notify.sh`, `post-compact.sh`, `validate-skill-change.sh`.

2. **Test the audit trail** by spawning any subagent — both start and stop events should appear in `production/session-logs/`.

3. **Generate sprint-status.yaml** if you're in active production:
   ```
   /sprint-plan status
   ```

4. **Run `/adopt`** if you have existing GDDs or ADRs that predate this template version — it will identify which sections need to be added without overwriting your content.

5. **Validate your skills** after any skill edits with `/skill-test` — the new `validate-skill-change.sh` hook will automatically remind you to do this.

---

## v0.2.0 → v0.3.0

**Released:** 2026-03-09
**Commit range:** `e289ce9..HEAD`
**Key themes:** `/design-system` GDD authoring, `/map-systems` rename, custom status line

### Breaking Changes

#### `/design-systems` renamed to `/map-systems`

The `/design-systems` skill was renamed to `/map-systems` for clarity
(decomposing = *mapping*, not *designing*).

**Action required:** Update any documentation, notes, or scripts that invoke
`/design-systems`. The new invocation is `/map-systems`.

### What Changed

| Category | Changes |
|----------|---------|
| **New skills** | `/design-system` (guided GDD authoring, section-by-section) |
| **Renamed skills** | `/design-systems` → `/map-systems` (breaking rename) |
| **New files** | `.claude/statusline.sh`, `.claude/settings.json` statusline config |
| **Skill updates** | `/gate-check` — writes `production/stage.txt` on PASS, new phase definitions |
| **Skill updates** | `brainstorm`, `start`, `design-review`, `project-stage-detect`, `setup-engine` — cross-reference fixes |
| **Bug fixes** | `log-agent.sh`, `validate-commit.sh` — hook execution fixed |
| **Docs** | `UPGRADING.md` added, `README.md` updated, `WORKFLOW-GUIDE.md` updated |

---

### Files: Safe to Overwrite

**New files to add:**
```
.claude/skills/design-system/SKILL.md
.claude/statusline.sh
```

**Existing files to overwrite (no user content):**
```
.claude/skills/map-systems/SKILL.md      ← was design-systems/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/brainstorm/SKILL.md
.claude/skills/start/SKILL.md
.claude/skills/design-review/SKILL.md
.claude/skills/project-stage-detect/SKILL.md
.claude/skills/setup-engine/SKILL.md
.claude/hooks/log-agent.sh
.claude/hooks/validate-commit.sh
README.md
docs/WORKFLOW-GUIDE.md
UPGRADING.md
```

**Delete (replaced by rename):**
```
.claude/skills/design-systems/   ← entire directory; replaced by map-systems/
```

---

### Files: Merge Carefully

#### `.claude/settings.json`

The new version adds a `statusLine` configuration block pointing to
`.claude/statusline.sh`. If you haven't customized `settings.json`, overwriting
is safe. Otherwise, add this block manually:

```json
"statusLine": {
  "script": ".claude/statusline.sh"
}
```

---

### New Features

#### Custom Status Line

`.claude/statusline.sh` displays a 7-stage production pipeline breadcrumb in
the terminal status line:

```
ctx: 42% | claude-sonnet-5 | Systems Design
```

In Production/Polish/Release stages, it also shows the active Epic/Feature/Task
from `production/session-state/active.md` if a `<!-- STATUS -->` block is present:

```
ctx: 42% | claude-sonnet-5 | Production | Combat System > Melee Combat > Hitboxes
```

The current stage is auto-detected from project artifacts, or can be pinned by
writing a stage name to `production/stage.txt`.

#### `/gate-check` Stage Advancement

When a gate PASS verdict is confirmed, `/gate-check` now writes the new stage
name to `production/stage.txt`. This immediately updates the status line for all
future sessions without requiring manual file edits.

---

### After Upgrading

1. **Delete the old skill directory:**
   ```bash
   rm -rf .claude/skills/design-systems/
   ```

2. **Test the status line** by starting a Claude Code session — you should see
   the stage breadcrumb in the terminal footer.

3. **Verify hook execution** still works:
   ```bash
   bash .claude/hooks/log-agent.sh '{}' '{}'
   bash .claude/hooks/validate-commit.sh '{}' '{}'
   ```

---

## v0.1.0 → v0.2.0

**Released:** 2026-02-21
**Commit range:** `ad540fe..e289ce9`
**Key themes:** Context Resilience, AskUserQuestion integration, `/map-systems` skill

### What Changed

| Category | Changes |
|----------|---------|
| **New skills** | `/start` (onboarding), `/map-systems` (systems decomposition), `/design-system` (guided GDD authoring) |
| **New hooks** | `session-start.sh` (recovery), `detect-gaps.sh` (gap detection) |
| **New templates** | `systems-index.md`, 3 collaborative-protocol templates |
| **Context management** | Major rewrite — file-backed state strategy added |
| **Agent updates** | 14 design/creative agents — AskUserQuestion integration |
| **Skill updates** | All 7 `team-*` skills + `brainstorm` — AskUserQuestion at phase transitions |
| **CLAUDE.md** | Slimmed from ~159 to ~60 lines; 5 doc imports instead of 10 |
| **Hook updates** | All 8 hooks — Windows compatibility fixes, new features |
| **Docs removed** | `docs/IMPROVEMENTS-PROPOSAL.md`, `docs/MULTI-STAGE-DOCUMENT-WORKFLOW.md` |

---

### Files: Safe to Overwrite

These are pure infrastructure — you have not customized them. Copy the new
versions directly with no risk to your project content.

**New files to add:**
```
.claude/skills/start/SKILL.md
.claude/skills/map-systems/SKILL.md
.claude/skills/design-system/SKILL.md
.claude/docs/templates/systems-index.md
.claude/hooks/detect-gaps.sh
.claude/hooks/session-start.sh
production/session-state/.gitkeep
docs/examples/README.md
.github/ISSUE_TEMPLATE/bug_report.md
.github/ISSUE_TEMPLATE/feature_request.md
.github/PULL_REQUEST_TEMPLATE.md
```

**Existing files to overwrite (no user content):**
```
.claude/skills/brainstorm/SKILL.md
.claude/skills/design-review/SKILL.md
.claude/skills/gate-check/SKILL.md
.claude/skills/project-stage-detect/SKILL.md
.claude/skills/setup-engine/SKILL.md
.claude/skills/team-audio/SKILL.md
.claude/skills/team-combat/SKILL.md
.claude/skills/team-level/SKILL.md
.claude/skills/team-narrative/SKILL.md
.claude/skills/team-polish/SKILL.md
.claude/skills/team-release/SKILL.md
.claude/skills/team-ui/SKILL.md
.claude/hooks/log-agent.sh
.claude/hooks/pre-compact.sh
.claude/hooks/session-stop.sh
.claude/hooks/validate-assets.sh
.claude/hooks/validate-commit.sh
.claude/hooks/validate-push.sh
.claude/rules/design-docs.md
.claude/docs/hooks-reference.md
.claude/docs/skills-reference.md
.claude/docs/quick-start.md
.claude/docs/directory-structure.md
.claude/docs/context-management.md
docs/COLLABORATIVE-DESIGN-PRINCIPLE.md
docs/WORKFLOW-GUIDE.md
README.md
```

**Agent files to overwrite** (if you haven't written custom prompts into them):
```
.claude/agents/art-director.md
.claude/agents/audio-director.md
.claude/agents/creative-director.md
.claude/agents/economy-designer.md
.claude/agents/game-designer.md
.claude/agents/level-designer.md
.claude/agents/live-ops-designer.md
.claude/agents/narrative-director.md
.claude/agents/producer.md
.claude/agents/systems-designer.md
.claude/agents/technical-director.md
.claude/agents/ux-designer.md
.claude/agents/world-builder.md
.claude/agents/writer.md
```

If you *have* customized agent prompts, see "Merge carefully" below.

---

### Files: Merge Carefully

These files contain both template structure and your project-specific content.
Do **not** overwrite them — merge the changes manually.

#### `CLAUDE.md`

The template version was slimmed from ~159 lines to ~60 lines. The key
structural change: 5 doc imports were removed because they're auto-loaded
by Claude Code anyway (agent-roster, skills-reference, hooks-reference,
rules-reference, review-workflow).

**What to keep from your version:**
- The `## Technology Stack` section (your engine/language choices)
- Any project-specific additions you made

**What to adopt from the new version:**
- Slimmer imports list (drop the 5 redundant `@` imports if present)
- Updated collaboration protocol wording

#### `.claude/docs/technical-preferences.md`

If you ran `/setup-engine`, this file has your engine config, naming
conventions, and performance budgets. Keep all of it. The template version
is just the empty placeholder.

#### `.claude/docs/templates/game-concept.md`

Minor structural update — a `## Next Steps` section was added pointing to
`/map-systems`. Add that section to your copy if you want the updated
guidance, but it's not required.

#### `.claude/settings.json`

Check whether the new version adds any permission rules you want. The change
was minor (schema update). If you haven't customized your `settings.json`,
overwriting is safe.

#### Customized agent files

If you've added project-specific knowledge or custom behavior to any agent
`.md` file, do a diff and manually add the new AskUserQuestion integration
sections rather than overwriting. The change in each agent is a standardized
collaborative protocol block at the end of the system prompt.

---

### Files: Delete

These files were removed in v0.2.0. If present in your repo, you can safely
delete them — they're replaced by better-organized alternatives.

```
docs/IMPROVEMENTS-PROPOSAL.md      → superseded by WORKFLOW-GUIDE.md
docs/MULTI-STAGE-DOCUMENT-WORKFLOW.md → content merged into context-management.md
```

---

### After Upgrading

1. **Run `/project-stage-detect`** to verify the system reads your project
   correctly with the new detection logic.

2. **Run `/start`** once if you haven't used it — it now correctly identifies
   your stage and skips onboarding steps you've already done.

3. **Check `production/session-state/`** exists and is gitignored:
   ```bash
   ls production/session-state/
   cat .gitignore | grep session-state
   ```

4. **Test hook execution** — if you're on Windows, verify the new hooks run
   without errors in Git Bash:
   ```bash
   bash .claude/hooks/detect-gaps.sh '{}' '{}'
   bash .claude/hooks/session-start.sh '{}' '{}'
   ```

---

*Each future version will have its own section in this file.*
