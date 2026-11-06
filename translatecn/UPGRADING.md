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

# 升级 Claude Code Game Studios

本指南涵盖如何把你的现有游戏项目仓库从模板的一个版本
升级到下一个版本。

**找到你当前的版本**——使用以下最先适用的一项：

- **克隆了模板，或合并过它：** `git describe --tags --abbrev=0` 会打印
  你历史中最新的发布标签，例如 `v1.1.2`。
- **`project.yaml` 中的 `framework.version`：** 该文件最后被打上的版本戳。
  如果在升级时保留了你自己的 `project.yaml`，它可能滞后，而
  1.1 之前的项目根本没有 `project.yaml`。
- **`CHANGELOG.md`：** `grep -m1 '^## \[' CHANGELOG.md` 会打印它列出的
  最新发布，只要该文件仍是模板自带的，这就是你的版本。

---

## Table of Contents

- [Upgrade Strategies](#upgrade-strategies)
- [v1.1.3 → v1.2.0](#v113--v120)
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

## 目录

- [升级策略](#upgrade-strategies)
- [v1.1.3 → v1.2.0](#v113--v120)
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

## 升级策略

引入模板更新有四种方式。请根据你的仓库设置情况选择。

### Strategy A — Git Remote Merge (recommended)

Best when: you cloned the template and have your own commits on top of it —
your repo shares history with the template.

```bash
# Add the template as a remote (one-time setup; skip this if `git remote -v` already lists template)
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git

# Fetch the new version and its release tag
git fetch --tags template main

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

### 策略 A —— Git 远程合并（推荐）

最适用于：你克隆了模板，并在其上拥有自己的提交——
你的仓库与模板共享历史。

```bash
# Add the template as a remote (one-time setup; skip this if `git remote -v` already lists template)
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git

# Fetch the new version and its release tag
git fetch --tags template main

# Merge into your branch
git merge template/main
```

Git 只会在模板*和*你都改动过的文件中标记冲突。逐个解决——你的游戏内容保留进来，
结构性改进也随之而来。然后提交这次合并。

**提示：** 最可能冲突的文件是 `CLAUDE.md`、`project.yaml` 和
`.claude/docs/technical-preferences.md`，因为你已经用引擎和项目设置把它们填好了。
保留你的内容；接受结构性改动。

**如果 git 以 `fatal: refusing to merge unrelated histories` 拒绝**，说明你的
仓库并不是以模板克隆开始的（zip 下载、从零 `git init`）。**不要**用
`--allow-unrelated-histories` 强行合并——没有共同祖先时，git 会把*每一个*模板文件
都标记为冲突，你将不得不手工解决数百个文件。请改用策略 A2。

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

### 策略 A2 —— 选择性检出（无共享历史）

最适用于：你的仓库与模板没有共同历史，但你确实使用 git。

> **首先，检查你是否编辑过任何框架文件。** 下面的检出会**替换** `.claude/` 下的
> 一切。*你添加的*文件会保留，但你对框架也自带的文件的编辑会被覆盖——智能体
> 定义和总监门禁是人们最常定制的。
>
> ```bash
> git log --oneline -- .claude    # commits here mean you have customisations
> ```
>
> 如果它列出了超出你初始导入之外的任何内容，请走一遍下面的恢复
> 步骤，而不是跳过。

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

> **恢复一个文件会完整保留你的版本——包括新版本在那里做的任何改动。**
> 对于你只轻改过的文件，通常更好的做法是采用新版本，再在其上重新应用你的改动，
> 而不是整体保留旧版本。`git diff HEAD template/main -- <file>` 会显示
> 你将放弃什么。

对于 `CLAUDE.md`，不要检出——手工 diff 并合并，保留你的
引擎/项目内容：

```bash
git diff HEAD template/main -- CLAUDE.md
```

`project.yaml` 取决于你从哪里来，而两种情况需要
相反的操作：

- **从 v1.0 升级**（本节所讲的情况）：你没有
  `project.yaml`——它在 v1.0 中并不存在。没有需要手工合并的东西，
  而上面的检出也刻意不去取它。请改从你的旧文件构建它，
  这正是转换器的用途：

  ```bash
  bash .claude/scripts/migrate-v1-config.sh --dry-run   # preview
  bash .claude/scripts/migrate-v1-config.sh             # writes project.yaml
  ```

  如果你跳过这一步，`detect-gaps.sh` 会在下次会话启动时提醒你——
  但最好在这里做，而不是事后才发现。

- **从 v1.1 或更高版本升级：** 你已经有一个持有你设置的
  `project.yaml`。像对待 `CLAUDE.md` 一样对待它——手工 diff 并合并，绝不要
  检出，否则会覆盖你自己的配置：

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

### 策略 B —— 精选特定提交

最适用于：你只想要某一个特定功能（例如只要新技能，而不要
完整更新）。

```bash
# One-time setup; skip it if `git remote -v` already lists template
git remote add template https://github.com/Donchitos/Claude-Code-Game-Studios.git
git fetch template main

# Cherry-pick the specific commit(s) you want
git cherry-pick <commit-sha>
```

每个版本的提交 SHA 列在下面的版本章节中。

---

### Strategy C — Manual file copy

Best when: you didn't use git to set up the template (just downloaded a zip).

1. Download or clone the new version alongside your repo.
2. Copy the files listed under **"Safe to overwrite"** directly — except any
   file the list marks as yours, such as `.claude/docs/technical-preferences.md`.
3. For files under **"Merge carefully"**, open both versions side-by-side
   and manually merge the structural changes while keeping your content.

### 策略 C —— 手动复制文件

最适用于：你没有用 git 来搭建模板（只是下载了一个 zip）。

1. 在你的仓库旁边下载或克隆新版本。
2. 直接复制 **"可安全覆盖"** 下列出的文件——除了列表标记为
   你自己的文件，例如 `.claude/docs/technical-preferences.md`。
3. 对于 **"需谨慎合并"** 下的文件，并排打开两个版本，
   在保留你内容的同时手动合并结构性改动。

---

## v1.1.3 → v1.2.0

**Released:** 2026-10-19
**Commit range:** `v1.1.3..v1.2.0`
**Key themes:** The story skills rebuilt around shared helper scripts; a read
guard for large design docs; Godot 4.7 and Unreal Engine 5.8 references; skills
pre-approve only the commands they run

## v1.1.3 → v1.2.0

**发布日期：** 2026-10-19
**提交范围：** `v1.1.3..v1.2.0`
**核心主题：** 故事类技能围绕共享辅助脚本重建；针对大型设计文档的读取
守卫；Godot 4.7 和 Unreal Engine 5.8 参考；技能
只预先批准它们实际运行的命令

### What Changed

| Category | Changes |
|----------|---------|
| **Config helper** | `yaml-helper.sh` runs six read-only lookups directly (`bash .claude/hooks/yaml-helper.sh resolve_setting <key>` and five more), from the project root; `/settings` and `/perf-profile` call it that way |
| **Hooks** | `post-compact.sh` removed: its output never reached Claude. `pre-compact.sh` only logs the compaction. `session-stop.sh` runs in the background and prints nothing. `notify.sh` fires for permission and idle prompts only |
| **New hooks** | `validate-read.sh` refuses a whole-file read of a design doc over 40 KB and answers with its headings, so the retry reads one section (`features.read_guard: off` turns it off, `features.read_guard_kb` sets the size). `validate-write.sh` and `validate-registry.sh` warn, never block, when a write would break a rule the skills state (a file they never overwrite, the prototype boundary, an append-only registry). `validate-agent-artifact.sh` warns when a subagent stops without writing the file its brief named |
| **Update alert** | Session start prints one line when a newer release is out. It asks GitHub at most once a day, in the background, and never waits; `updates.check: false` in `project.yaml` or `project.local.yaml` turns it off, and CI runs never ask |
| **Worktrees** | `settings.json` sets `worktree.baseRef` to `"head"`, so a worktree (the prototyper's, an isolated subagent's, `claude --worktree`) starts from your current commit, not the remote's default branch. The new `.worktreeinclude` copies `project.local.yaml`, `CLAUDE.local.md` and `.claude/settings.local.json` into each one. The prototyper names uncommitted files its worktree can't see, and says which of its checks it could not run |
| **Rules** | New `.claude/rules/scene-files.md`: engine scene and asset files (`.tscn`, `.tres`, `.unity`, `.prefab`, `Assets/**/*.asset`) are changed in the editor where possible |
| **Templates** | New layouts in `.claude/docs/templates/`: bug reports, launch and certification checklists, patch notes, start paths and more. `/create-stories` writes stories from `story.md`; the other skills do not use the new layouts yet |
| **Permissions** | `settings.json`: the three Bash `.env` deny rules removed; `Read(**/.env*)` and `Edit(**/.env*)` already cover them. No skill pre-approves bare `Bash` any more: 34 skills now pre-approve only the commands their text runs (framework scripts, `git log` and the like). A command a skill does not name, such as your `commands.test`, asks first; approve it once, or add `Bash(<your command> *)` to `.claude/settings.local.json` |
| **Git** | `.gitignore` ignores `.claude/worktrees/` |
| **Docs** | `settings-local-template.md` uses the current permission mode names and narrower example rules |
| **Skill testing** | `CCGS Skill Testing Framework/` is renamed `studio-tests/`. `/skill-test`, `/skill-improve` and the `spec:` paths in its `catalog.yaml` use the new name; the two skills say so while the old folder is still there |
| **Skills** | `/create-stories`, `/story-readiness`, `/create-epics`, `/dev-story`, `/story-done` and `/start` are rebuilt: shorter, with rarely used branches moved to each skill's `references/` folder (`/start` stays one `SKILL.md`) and fixed steps handed to scripts in `.claude/scripts/`. `/dev-story` and `/story-done` replace 1.1.3's numbered phase files with fewer, named ones. `/start` works out the rigor from what you describe and shows it on one card with a single save question, instead of asking for it. `/brainstorm`'s full concept path moved to `references/full-concept.md` |
| **Stories** | New story template `.claude/docs/templates/story.md` with a `## Files` section: `/create-stories` lists the planned files, `/dev-story` replaces the list with the files it changed, and `/story-done` checks scope against it. `/create-stories` proposes an estimate (`S`, `M` or `L`) for each story, which you can change before it writes them |
| **Evidence** | `/dev-story` writes `stamp.txt` beside a story's screenshots. `/story-done` names any of the story's files that changed after the evidence was captured; it reports this and never blocks on it |
| **Gates** | The Technical Setup → Pre-Production gate reads each `/architecture-review` report's `Mode:` line and counts the report only for what that mode checked. Reports written by 1.1.3 have no `Mode:` line and count for nothing, so run `/architecture-review` once after upgrading, before that gate |
| **Engine references** | `docs/engine-reference/` now covers Godot 4.7 (was 4.6) and Unreal Engine 5.8 (was 5.7). Unity stays on 6.3 LTS, the newest LTS, and records 6.4 to 6.6 and the 6.7 beta. Release timelines carry vendor-sourced dates |
| **CI templates** | `/test-setup` writes `actions/checkout@v7` and `actions/upload-artifact@v7` (was `@v4`), names Godot 4.7.2 and gdUnit4 6.2, and `game-ci/unity-test-runner@v4` now resolves to v4.4.0 |

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **配置辅助脚本** | `yaml-helper.sh` 从项目根目录直接执行六个只读查询（`bash .claude/hooks/yaml-helper.sh resolve_setting <key>` 以及另外五个）；`/settings` 和 `/perf-profile` 就是这样调用它的 |
| **钩子** | 移除 `post-compact.sh`：其输出从未到达 Claude。`pre-compact.sh` 只记录压缩。`session-stop.sh` 在后台运行且不打印任何内容。`notify.sh` 仅在权限提示和闲置提示时触发 |
| **新钩子** | `validate-read.sh` 拒绝整文件读取超过 40 KB 的设计文档，并以文档标题作答，好让重试只读一个章节（`features.read_guard: off` 关闭它，`features.read_guard_kb` 设置大小）。`validate-write.sh` 和 `validate-registry.sh` 在写入会破坏技能规定的规则时发出警告、从不阻止（技能从不覆盖的文件、原型边界、只追加的注册表）。`validate-agent-artifact.sh` 在子智能体停止却未写出其任务简报所指明的文件时发出警告 |
| **更新提醒** | 有更新的发布时，会话启动会打印一行。它最多每天在后台向 GitHub 询问一次，且从不等待；`project.yaml` 或 `project.local.yaml` 中的 `updates.check: false` 会关闭它，CI 运行则从不询问 |
| **工作树（worktree）** | `settings.json` 把 `worktree.baseRef` 设为 `"head"`，因此工作树（原型者的、隔离子智能体的、`claude --worktree` 的）会从你当前的提交开始，而不是远程的默认分支。新的 `.worktreeinclude` 会把 `project.local.yaml`、`CLAUDE.local.md` 和 `.claude/settings.local.json` 复制进每一个工作树。原型者会列出其工作树看不到的未提交文件，并说明它哪些检查无法运行 |
| **规则** | 新增 `.claude/rules/scene-files.md`：引擎场景和资产文件（`.tscn`、`.tres`、`.unity`、`.prefab`、`Assets/**/*.asset`）尽可能在编辑器中修改 |
| **模板** | `.claude/docs/templates/` 中的新布局：缺陷报告、发布与认证清单、补丁说明、起始路径等。`/create-stories` 从 `story.md` 写出故事；其他技能尚未使用新布局 |
| **权限** | `settings.json`：移除三条 Bash `.env` 拒绝规则；`Read(**/.env*)` 和 `Edit(**/.env*)` 已经覆盖它们。不再有技能预先批准裸 `Bash`：34 个技能现在只预先批准其正文实际运行的命令（框架脚本、`git log` 之类）。技能未指明的命令，例如你的 `commands.test`，会先询问；批准一次，或把 `Bash(<your command> *)` 加到 `.claude/settings.local.json` |
| **Git** | `.gitignore` 忽略 `.claude/worktrees/` |
| **文档** | `settings-local-template.md` 使用当前的权限模式名称和范围更窄的示例规则 |
| **技能测试** | `CCGS Skill Testing Framework/` 重命名为 `studio-tests/`。`/skill-test`、`/skill-improve` 及其 `catalog.yaml` 中的 `spec:` 路径使用新名称；只要旧文件夹还在，这两个技能就会说明这一点 |
| **技能** | `/create-stories`、`/story-readiness`、`/create-epics`、`/dev-story`、`/story-done` 和 `/start` 被重建：更短，少用的分支移到每个技能的 `references/` 文件夹（`/start` 仍是一个 `SKILL.md`），固定步骤交给 `.claude/scripts/` 中的脚本。`/dev-story` 和 `/story-done` 用更少的、有名字的阶段文件取代 1.1.3 的编号阶段文件。`/start` 根据你的描述推断严谨度，并在一张卡片上连同单个保存问题一起展示，而不是询问它。`/brainstorm` 的完整概念路径移到了 `references/full-concept.md` |
| **故事** | 新故事模板 `.claude/docs/templates/story.md`，带 `## Files` 章节：`/create-stories` 列出计划中的文件，`/dev-story` 用实际改动的文件替换该列表，`/story-done` 对照它检查范围。`/create-stories` 为每个故事提出一个估算（`S`、`M` 或 `L`），你可以在它写出故事之前修改 |
| **证据** | `/dev-story` 在故事截图旁边写入 `stamp.txt`。`/story-done` 列出该故事中在证据捕获后发生变更的任何文件；它会报告这一点，且从不因此阻止 |
| **门禁** | Technical Setup → Pre-Production 门禁读取每份 `/architecture-review` 报告的 `Mode:` 行，并仅按该模式检查过的内容来计该报告。由 1.1.3 写出的报告没有 `Mode:` 行，不计入任何东西，因此升级后、通过该门禁之前，请运行一次 `/architecture-review` |
| **引擎参考** | `docs/engine-reference/` 现在涵盖 Godot 4.7（原为 4.6）和 Unreal Engine 5.8（原为 5.7）。Unity 保持在 6.3 LTS，即最新的 LTS，并记录 6.4 至 6.6 和 6.7 beta。发布时序携带供应商来源的日期 |
| **CI 模板** | `/test-setup` 写出 `actions/checkout@v7` 和 `actions/upload-artifact@v7`（原为 `@v4`），指定 Godot 4.7.2 和 gdUnit4 6.2，且 `game-ci/unity-test-runner@v4` 现在解析为 v4.4.0 |

---

### Files: Safe to Overwrite

**Existing files to overwrite (no user content), and new files to add:**
```
.claude/hooks/*.sh                           ← take the whole folder: 13 hooks
                                               changed, yaml-helper.sh among
                                               them, and 5 are new. Take
                                               .claude/scripts/ in the same
                                               step: the hooks call its helpers
.claude/scripts/**                           ← 25 new helper scripts, 7 changed
.claude/statusline.sh
.claude/skills/**                            ← if you edited a skill, see
                                               Merge Carefully
.claude/agents/*.md                          ← all 49 changed; if you edited
                                               one, see Merge Carefully
.claude/docs/**                              ← EXCEPT technical-preferences.md,
                                               which is yours and unchanged in
                                               1.2.0
.claude/rules/scene-files.md                 ← new
docs/WORKFLOW-GUIDE.md
docs/engine-reference/<engine>/              ← unless your project stays on
                                               Godot 4.6 or Unreal 5.7; see
                                               Merge Carefully
README.md, CHANGELOG.md, UPGRADING.md        ← keep your README if it is your
                                               game's
studio-tests/                                ← renamed from CCGS Skill Testing
                                               Framework/; if you wrote specs
                                               there, see Merge Carefully
production/.gdignore                         ← new: Godot skips production/
```

In a Godot project, after adding `production/.gdignore`, delete the .import files Godot made under `production/`
(`find production -name '*.import' -delete`): Godot imported the evidence screenshots there as game resources,
and a default export packed them into the game.

With Strategy A2, also check out what this release changes outside `.claude`
(your README aside): `git checkout template/main -- studio-tests production/.gdignore .worktreeinclude docs/WORKFLOW-GUIDE.md`.

Take `.claude/hooks/` whole, not only its new files: a 1.1.3 `yaml-helper.sh`
answers the new lookups (`resolve_setting modes.rigor` and the rest) with its
usage line, so `/settings`, `/perf-profile` and the command the update notice
prints stop working, and the rebuilt skills lose their review and gate lines.

### 文件：可安全覆盖

**要覆盖的现有文件（无用户内容），以及要添加的新文件：**
```
.claude/hooks/*.sh                           ← 整个文件夹都取：13 个钩子
                                               有变化，其中就有 yaml-helper.sh，
                                               还有 5 个是新的。同一步取
                                               .claude/scripts/：钩子会调用它的辅助脚本
.claude/scripts/**                           ← 25 个新辅助脚本，7 个有变化
.claude/statusline.sh
.claude/skills/**                            ← 如果你编辑过某个技能，参见
                                               “需谨慎合并”
.claude/agents/*.md                          ← 全部 49 个都有变化；如果你编辑过
                                               其中一个，参见“需谨慎合并”
.claude/docs/**                              ← 除了 technical-preferences.md，
                                               它是你的，且在 1.2.0 中未变
.claude/rules/scene-files.md                 ← 新增
docs/WORKFLOW-GUIDE.md
docs/engine-reference/<engine>/              ← 除非你的项目仍停留在
                                               Godot 4.6 或 Unreal 5.7；参见
                                               “需谨慎合并”
README.md, CHANGELOG.md, UPGRADING.md        ← 如果 README 是你游戏的，保留你的
studio-tests/                                ← 由 CCGS Skill Testing
                                               Framework/ 重命名而来；如果你在那里
                                               写过规格，参见“需谨慎合并”
production/.gdignore                         ← 新增：Godot 跳过 production/
```

在 Godot 项目中，添加 `production/.gdignore` 之后，删除 Godot 在 `production/` 下生成的 .import 文件
（`find production -name '*.import' -delete`）：Godot 曾把那里的证据截图作为游戏资源导入，
而默认导出会把它们打包进游戏。

使用策略 A2 时，还要检出本次发布在 `.claude` 之外变更的内容
（你的 README 除外）：`git checkout template/main -- studio-tests production/.gdignore .worktreeinclude docs/WORKFLOW-GUIDE.md`。

要整体取 `.claude/hooks/`，而不只是它的新文件：1.1.3 的 `yaml-helper.sh`
会用它的用法行来回答新查询（`resolve_setting modes.rigor` 等），
于是 `/settings`、`/perf-profile` 以及更新通知打印的命令都将停止工作，重建的技能也会失去它们的评审与门禁行。

---

### Files: Merge Carefully

**Strategy A:** the merge has already made these changes wherever git could,
which is every file you never edited. Check each item instead of making it
again (a hook entry added twice runs twice). The steps are for files that
conflicted, and for Strategies A2 and C.

**`.claude/settings.json`** — if you have not edited it, overwrite it with the
shipped file. If you have:

- Delete the `"PostCompact"` entry under `hooks`, and delete
  `.claude/hooks/post-compact.sh`. Do both: an entry left pointing at the
  deleted script fails on every compaction.
- Under `"Stop"`, add `"async": true` to the `session-stop.sh` hook.
- Under `"Notification"`, change `"matcher": ""` to
  `"matcher": "permission_prompt|idle_prompt"`.
- Remove `Bash(*>.env*)`, `Bash(cat *.env*)` and `Bash(type *.env*)` from
  `deny`. Keep `Read(**/.env*)` and `Edit(**/.env*)`, which cover Bash file
  commands and redirects to `.env` files, and keep the two PowerShell `.env`
  rules.
- Add `Edit(**/*.uasset)` and `Edit(**/*.umap)` to `deny`. They stop Unreal's
  binary assets being edited or overwritten as text, which corrupts them; an
  `Edit(...)` rule covers writes too.
- Add the four new hooks, copying each entry from the shipped file: under
  `"PreToolUse"`, a `"Write|Edit"` entry running `validate-registry.sh` and
  `validate-write.sh`, and a `"Read"` entry running `validate-read.sh`; under
  `"SubagentStop"`, `validate-agent-artifact.sh` after `log-agent-stop.sh`.
  Take `.claude/hooks/` and `.claude/scripts/` (Safe to Overwrite) first: an
  entry pointing at a missing script fails every time it fires, and the four
  hooks call helpers in `.claude/scripts/`, so without them every Read and
  Write prints "guard skipped".
- Add `"worktree": { "baseRef": "head" }` at the top level. Without it, Claude
  Code makes each worktree from the remote's default branch, so a prototype or
  isolated subagent works on code without your local commits.

**`.gitignore`** — add `.claude/worktrees/`. Without it, a worktree made by the
prototyper, an isolated subagent or `claude --worktree` shows up as untracked
files, and `git add -A` stages it as an embedded repository.

**`.worktreeinclude`** (new, at the root) — take it. It lists the gitignored
local config Claude Code copies into each new worktree. If you add lines, add
only local config, never secrets such as `.env` or keys.

**`.gitattributes`** — add `*.awk text eol=lf` and `.worktreeinclude text eol=lf`.
They keep both LF on every checkout, including `core.autocrlf=true` on Windows:
mawk and BWK awk may misread an awk program with carriage returns, and a CRLF
`.worktreeinclude` leaves every pattern ending in one, so nothing is copied.

### 文件：需谨慎合并

**策略 A：** 只要 git 能做到，合并就已经完成了这些改动，即每一个你从未编辑过的文件。
请逐项检查，而不是再做一遍（重复添加的钩子条目会运行两次）。这些步骤针对的是发生冲突的文件，
以及策略 A2 和 C。

**`.claude/settings.json`** —— 如果你没有编辑过它，就用随附文件覆盖它。如果你编辑过：

- 删除 `hooks` 下的 `"PostCompact"` 条目，并删除
  `.claude/hooks/post-compact.sh`。两件都要做：一个仍指向已删除脚本的
  条目会在每次压缩时失败。
- 在 `"Stop"` 下，为 `session-stop.sh` 钩子添加 `"async": true`。
- 在 `"Notification"` 下，把 `"matcher": ""` 改为
  `"matcher": "permission_prompt|idle_prompt"`。
- 从 `deny` 中移除 `Bash(*>.env*)`、`Bash(cat *.env*)` 和 `Bash(type *.env*)`。
  保留 `Read(**/.env*)` 和 `Edit(**/.env*)`，它们覆盖 Bash 文件
  命令和写入 `.env` 文件的重定向，并保留两条 PowerShell `.env`
  规则。
- 把 `Edit(**/*.uasset)` 和 `Edit(**/*.umap)` 加入 `deny`。它们阻止 Unreal 的
  二进制资产被当作文本编辑或覆盖（这会损坏它们）；`Edit(...)` 规则也覆盖写入。
- 添加四个新钩子，从随附文件复制每个条目：在
  `"PreToolUse"` 下，一个运行 `validate-registry.sh` 和 `validate-write.sh` 的 `"Write|Edit"` 条目，
  以及一个运行 `validate-read.sh` 的 `"Read"` 条目；在
  `"SubagentStop"` 下，在 `log-agent-stop.sh` 之后加 `validate-agent-artifact.sh`。
  先取 `.claude/hooks/` 和 `.claude/scripts/`（可安全覆盖）：一个
  指向缺失脚本的条目每次触发都会失败，而这四个
  钩子会调用 `.claude/scripts/` 中的辅助脚本，没有它们，每次 Read 和
  Write 都会打印 "guard skipped"。
- 在顶层添加 `"worktree": { "baseRef": "head" }`。没有它，Claude
  Code 会用远程的默认分支为每个工作树创建，于是原型或
  隔离子智能体在没有你本地提交的代码上工作。

**`.gitignore`** —— 添加 `.claude/worktrees/`。没有它，由
原型者、隔离子智能体或 `claude --worktree` 创建的工作树会显示为未跟踪
文件，而 `git add -A` 会把它作为一个嵌入式仓库暂存。

**`.worktreeinclude`**（新增，位于根目录）—— 取它。它列出 Claude Code 复制进每个新工作树的
被 git 忽略的本地配置。如果你添加行，只添加本地配置，绝不要添加 `.env` 或密钥之类的机密。

**`.gitattributes`** —— 添加 `*.awk text eol=lf` 和 `.worktreeinclude text eol=lf`。
它们让两者在每次检出时都保持 LF，包括 Windows 上的 `core.autocrlf=true`：
mawk 和 BWK awk 可能误读带回车符的 awk 程序，而 CRLF 的
`.worktreeinclude` 会让每个模式都以它结尾，于是什么都不会被复制。

**`project.yaml`** — optionally set `framework.version: 1.2.0`. Nothing reads it
for this release: the update alert compares against the version stamp in
`.claude/hooks/update-check.sh`, which arrives with the hooks folder. Leave
`updates.check` and `features.read_guard` unset to keep their defaults (on).

**`CLAUDE.md`** — one wording change in the Technical Preferences paragraph;
nothing to do if you edited the file.

**`.claude/settings.local.json`** — if you copied `Bash(git *)` from the old
`settings-local-template.md`, it approves every git command, `git push`
included. Narrow it to the commands you mean, such as `Bash(git add *)` and
`Bash(git commit *)`.

**`studio-tests/`** — the renamed `CCGS Skill Testing Framework/`, same layout.
If you never changed anything in the old folder, take the new one and delete
the old one. If you wrote or edited specs there, move them to the same path
under `studio-tests/`, and in `studio-tests/catalog.yaml` change their `spec:`
paths from `CCGS Skill Testing Framework/` to `studio-tests/`. Then delete the
old folder: `/skill-test` and `/skill-improve` only read the new one.

**`.claude/skills/` and `.claude/scripts/`** — take the rebuilt skill folders
whole (`create-stories`, `story-readiness`, `create-epics`, `dev-story`,
`story-done`, `start`, `brainstorm`), and take `.claude/scripts/` with them: they
call scripts 1.1.3 did not have (`adr-status.sh`, `story-facts.sh`,
`md-section.sh`, `session-state.sh`, `write-guard.sh`, `project-state.sh`,
`set-stage.sh`, `config-set.sh`). If you edited one of these skills, make your
edit again on the new text; the step it changed may now be in the skill's
`references/` folder.

If you keep your own copy of any other skill, take the shipped `allowed-tools:`
line into it: 34 skills replaced a bare `Bash` grant there, and a kept copy
still pre-approves every shell command while it runs.

**`docs/engine-reference/<engine>/`** — take the folder if your project uses
the newer engine (Godot 4.7, Unreal 5.8) or has not pinned one yet. If your
project stays on Godot 4.6 or Unreal 5.7, keep your current folder for that
engine: the new one describes APIs your editor does not have. With Strategy A
the merge takes the new folder without asking; only a file you edited (usually
`VERSION.md`) conflicts. To keep yours, run `git checkout HEAD -- docs/engine-reference/<engine>/` before you commit the merge. Either way, run
`/setup-engine` again afterwards so `Installed at pin time` records your editor.

**`.github/workflows/`** — a workflow `/test-setup` already wrote is not changed.
To move it to the current actions, change `actions/checkout@v4` and
`actions/upload-artifact@v4` to `@v7`. On a self-hosted runner (the Unreal
template), update the runner to 2.327.1 or newer first: v7 runs on Node.js 24.

**`.claude/agents/`** — all 49 agent files changed: an agent ends its turn with
its question instead of waiting for a yes it cannot receive, the GDScript, Unity,
Unreal and Blueprint specialists leave scene and asset files to the editor, the engine agents follow the
new engine versions, and the prototyper checks what its worktree cannot see. Take
the folder; if you edited an agent, make your edit again on the new text.

**Your registries** (`design/registry/entities.yaml`,
`docs/architecture/tr-registry.yaml`, `docs/registry/architecture.yaml`) — keep
yours: they hold your project's entries. The shipped files gained `# LAYOUT:`
comment lines in their headers describing the shape `.claude/scripts/registry.sh`
reads; copy them into your header if you like. Nothing reads the comment.
1.1.3's `/architecture-decision` wrote a replaced entry in
`docs/registry/architecture.yaml` as `status: superseded_by: ADR-NNNN`, without
quotes. Quote each one: `status: "superseded_by: ADR-NNNN"`. Unquoted, the second
colon makes the file invalid YAML. `registry.sh` still reads the old form and
prints an `UNQUOTED` row naming each line to change.

**`.claude/docs/templates/sprint-plan.md`** — take it. It gains a
`## Goal Prerequisites` section that `/sprint-plan` fills; sprint plans you
already wrote need no change.

**Your existing stories and evidence** need no change. A story written before
1.2.0 has no `## Files` section, so `/story-done` checks its scope against the
session checkpoint's files in progress, or reports scope as NOT ASSESSED. Add
the section by hand (one changed file per line) to get the check. Evidence
captured before 1.2.0 has no `stamp.txt`, and `/story-done` says "no stamp"
instead of whether the code changed after it.

**`project.yaml`** —— 可选地设置 `framework.version: 1.2.0`。本次发布没有任何东西读取它：
更新提醒是拿 `.claude/hooks/update-check.sh` 中的版本戳来比较的，而那个文件随钩子文件夹一并到来。
保持 `updates.check` 和 `features.read_guard` 未设置，以保留它们的默认值（开启）。

**`CLAUDE.md`** —— 在 Technical Preferences 段落中有一处措辞变更；
如果你编辑过该文件，则无需处理。

**`.claude/settings.local.json`** —— 如果你从旧的 `settings-local-template.md` 复制了 `Bash(git *)`，
它会批准每一条 git 命令，包括 `git push`。把它收窄为你想要的命令，例如 `Bash(git add *)` 和
`Bash(git commit *)`。

**`studio-tests/`** —— 即被重命名的 `CCGS Skill Testing Framework/`，布局相同。
如果你从未在旧文件夹中改动过任何东西，取新文件夹并删除旧文件夹。
如果你在那里编写或编辑过规格，把它们移到 `studio-tests/` 下的相同路径，
并在 `studio-tests/catalog.yaml` 中把它们的 `spec:` 路径从 `CCGS Skill Testing Framework/`
改为 `studio-tests/`。然后删除旧文件夹：`/skill-test` 和 `/skill-improve` 只读新的那个。

**`.claude/skills/` 和 `.claude/scripts/`** —— 整体取重建后的技能文件夹
（`create-stories`、`story-readiness`、`create-epics`、`dev-story`、
`story-done`、`start`、`brainstorm`），并连同它们一起取 `.claude/scripts/`：它们
会调用 1.1.3 没有的脚本（`adr-status.sh`、`story-facts.sh`、
`md-section.sh`、`session-state.sh`、`write-guard.sh`、`project-state.sh`、
`set-stage.sh`、`config-set.sh`）。如果你编辑过其中某个技能，请在新文本上
重新做你的改动；你改动的那个步骤现在可能位于该技能的 `references/` 文件夹中。

如果你保留了任何其他技能的自有副本，请把随附的 `allowed-tools:` 行取进去：
34 个技能在那里替换掉了裸 `Bash` 授权，而保留下来的副本在运行时仍会预先批准每一条 shell 命令。

**`docs/engine-reference/<engine>/`** —— 如果你的项目使用更新的引擎
（Godot 4.7、Unreal 5.8）或尚未固定引擎，就取该文件夹。如果你的
项目仍停留在 Godot 4.6 或 Unreal 5.7，请保留该引擎当前的文件夹：新文件夹描述的是
你的编辑器没有的 API。使用策略 A 时，合并会不经询问就取用新文件夹；只有你编辑过的文件（通常是
`VERSION.md`）才会冲突。要保留你的版本，请在提交合并之前运行 `git checkout HEAD -- docs/engine-reference/<engine>/`。
无论哪种方式，之后都再次运行 `/setup-engine`，以便 `Installed at pin time` 记录你的编辑器。

**`.github/workflows/`** —— `/test-setup` 已经写好的 workflow 不会被更改。
要把它移到当前的 action 版本，请把 `actions/checkout@v4` 和
`actions/upload-artifact@v4` 改为 `@v7`。在自托管 runner 上（Unreal
模板），请先把 runner 更新到 2.327.1 或更新版本：v7 运行在 Node.js 24 上。

**`.claude/agents/`** —— 全部 49 个智能体文件都有变化：智能体以
它的提问结束回合，而不是等待一个它收不到的“是”；GDScript、Unity、
Unreal 和蓝图专员把场景和资产文件留给编辑器；引擎智能体遵循
新的引擎版本；原型者检查它的工作树看不到的内容。取该
文件夹；如果你编辑过某个智能体，请在新文本上重新做你的改动。

**你的注册表**（`design/registry/entities.yaml`、
`docs/architecture/tr-registry.yaml`、`docs/registry/architecture.yaml`）—— 保留
你自己的：它们持有你项目的条目。随附文件在其头部新增了 `# LAYOUT:`
注释行，描述 `.claude/scripts/registry.sh` 所读取的结构；
如果你愿意，可以把它们复制进你的头部。没有东西读取该注释。
1.1.3 的 `/architecture-decision` 会把被替换的条目写入
`docs/registry/architecture.yaml`，形式为 `status: superseded_by: ADR-NNNN`，不带
引号。请给每一个加上引号：`status: "superseded_by: ADR-NNNN"`。不加引号时，第二个
冒号会让文件变成无效 YAML。`registry.sh` 仍会读取旧形式，并
打印一行 `UNQUOTED`，指明每一处要更改的行。

**`.claude/docs/templates/sprint-plan.md`** —— 取它。它新增了
`## Goal Prerequisites` 章节，由 `/sprint-plan` 填充；你已经写好的冲刺计划
无需更改。

**你现有的故事和证据**无需更改。在 1.2.0 之前写的故事
没有 `## Files` 章节，因此 `/story-done` 会对照会话检查点中正在进行的文件来检查其范围，
或将范围报告为 NOT ASSESSED。手动添加该章节（每行一个改动过的文件）即可获得该检查。
1.2.0 之前捕获的证据没有 `stamp.txt`，`/story-done` 会说 "no stamp"，
而不是说明代码之后是否发生了变更。

---

### Files: Delete

```
.claude/hooks/post-compact.sh      → removed; delete its PostCompact entry in settings.json too
CCGS Skill Testing Framework/      → renamed studio-tests/; move any specs you wrote first (above)
.claude/skills/dev-story/references/2-load-context.md, 3-route.md, 4-implement.md,
  5-test-evidence.md, 6-collect.md, 7-session-state.md
                                   → replaced by engine-checks.md and version-mismatch.md
.claude/skills/story-done/references/1-find-story.md, 2-read-story.md, 3-verify-criteria.md,
  4-deviations.md, 5-code-review-gate.md, 6-completion-report.md, 7-update-status.md,
  8-next-story.md                  → replaced by review-gates.md, sprint-next.md and tech-debt-row.md
```

### 文件：删除

```
.claude/hooks/post-compact.sh      → removed; delete its PostCompact entry in settings.json too
CCGS Skill Testing Framework/      → renamed studio-tests/; move any specs you wrote first (above)
.claude/skills/dev-story/references/2-load-context.md, 3-route.md, 4-implement.md,
  5-test-evidence.md, 6-collect.md, 7-session-state.md
                                   → replaced by engine-checks.md and version-mismatch.md
.claude/skills/story-done/references/1-find-story.md, 2-read-story.md, 3-verify-criteria.md,
  4-deviations.md, 5-code-review-gate.md, 6-completion-report.md, 7-update-status.md,
  8-next-story.md                  → replaced by review-gates.md, sprint-next.md and tech-debt-row.md
```

---

## v1.1.2 → v1.1.3

**Released:** 2026-10-08
**Commit range:** `v1.1.2..v1.1.3`
**Key themes:** Long skills keep their later phases after a compaction; a
question nobody answered is never an answer; the shipped allow rules approve
less; settings read the same from a subfolder

## v1.1.2 → v1.1.3

**发布日期：** 2026-10-08
**提交范围：** `v1.1.2..v1.1.3`
**核心主题：** 长技能在压缩之后仍保留其后续阶段；无人回答的问题
永远不算答案；随附的允许规则批准得更少；从子文件夹读取的设置
结果一致

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

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **长技能（14 个）** | `/adopt`、`/architecture-decision`、`/architecture-review`、`/create-architecture`、`/design-system`、`/dev-story`、`/gate-check`、`/prototype`、`/review-all-gdds`、`/setup-engine`、`/smoke-check`、`/story-done`、`/test-setup` 和 `/ux-design` 把每个阶段保存在 `references/<phase>.md` 中；它们的步骤未变。`/skill-test` 和 `/skill-improve` 也会读取技能的 `references/` 文件 |
| **提问** | `automation-modes.md` 和 `effects-map.md`：被跳过、被忽略或空白的答案永远不算答案；14 个智能体把选项作为列表返回，供技能来提问；`CLAUDE.md` 和 `agent-memory.md` 指明了三处无需“我可以写入吗？”的写入 |
| **设置** | 从子文件夹启动时，`yaml-helper.sh` 会读取项目根目录下的每一项设置；本地 `platform.cert_tier` 无法覆盖该锁定；无效的 `cert_tier` 和 `testing.strict` 值按未设置处理 |
| **钩子和脚本** | `validate-commit.sh` 检查同一条命令中 `git add` 暂存的文件，跳过 `design/gdd/` 中的非系统文件，检查位于更大仓库子文件夹中的项目，并透过工作副本读取以 Git LFS 存储的 JSON；`project-coherence.sh` 读取 Unreal 的 `Build.version` |
| **权限** | `settings.json`：移除七条允许规则，收窄两条 pytest 规则，拒绝 `Edit(**/.env*)` |
| **其他技能** | 十三个技能把最小路线列为下一步；`/design-system`、`/create-stories`、`/dev-story`、`/story-done`、`/consistency-check`、`/architecture-review` 中的注册表查询；`team-polish`、`team-ui`、`/scope-check`；`/start` 只写一个 `modes:` 区块；每个技能都以标题开头 |

没有任何设置改变含义，也没有任何东西被自动迁移。

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

### 文件：可安全覆盖

**要覆盖的现有文件（无用户内容）：**
```
.claude/skills/**                            ← 14 个技能获得 references/
                                               文件夹；如果你编辑过其中
                                               之一，参见“需谨慎合并”。39 个
                                               技能获得标题行
.claude/hooks/validate-commit.sh, validate-push.sh, yaml-helper.sh,
pre-compact.sh, session-stop.sh
.claude/scripts/project-coherence.sh
.claude/agents/*.md                          ← 15 个智能体有变化；合并任何
                                               你编辑过的
.claude/docs/**                              ← 除了 technical-preferences.md，
                                               它是你的，且在 1.1.3 中未变
docs/WORKFLOW-GUIDE.md, docs/CLAUDE.md, docs/COLLABORATIVE-DESIGN-PRINCIPLE.md,
docs/engine-reference/unreal/plugins/gameplay-ability-system.md
README.md, CHANGELOG.md, UPGRADING.md        ← 如果 README 是你游戏的，保留你的
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

### 文件：需谨慎合并

**`.claude/settings.json`** —— 如果你没有编辑过它，就用随附文件覆盖它。
如果你编辑过，请从 `allow` 中移除这些：`Bash(git status*)`、
`Bash(git diff*)`、`Bash(git log*)`、`Bash(git branch*)`、`Bash(git rev-parse*)`、
`Bash(ls *)` 和 `Bash(python -m json.tool*)`；把 `Bash(python -m pytest*)`
和 `Bash(py -m pytest*)` 改成 `Bash(python -m pytest *)` 和
`Bash(py -m pytest *)`；并把 `Edit(**/.env*)` 加入 `deny`。更改之后，
只读 git 命令仍会无需提示运行。**如果你把被移除的任何规则复制进了 `.claude/settings.local.json`，也请在那里删除它们：**
副本会继续不经询问地批准 `git branch -D`、`--output` 文件和 `json.tool` 写入。

**`CLAUDE.md`** —— 如果你除了 Technology Stack 之外没有编辑过它，取
随附的 Collaboration Protocol 章节。如果你编辑过，请复制它的三条新行：
“May I write” 下的豁免项、“A skipped or dismissed question is not an answer”，
以及 “Started outside this file's folder? Warn first”。

**`.claude/rules/agent-memory.md`、`.claude/rules/skill-authoring.md`** —— 如果你
没有编辑过它们，就用随附文件覆盖它们。

**14 个长技能之一，如果你编辑过它** —— 它的 `SKILL.md` 现在持有
设置行、始终适用的规则以及每个阶段一个标题；每个阶段的步骤原封不动地
移到了 `references/<phase>.md`。取随附技能，
然后在该文本现在所在的阶段文件中重新做你的改动。

**`design/registry/entities.yaml`、`docs/architecture/tr-registry.yaml`** ——
这些是你项目的数据；保留你自己的。只有头部注释有变化。
如果你的 TR 注册表有未加引号的 `status: superseded-by: TR-...`，请给
该值加引号（`status: "superseded-by: TR-combat-001"`）：不加引号时，第二个冒号
会让文件变成无效 YAML。`/story-readiness` 两种形式都能读。

**`project.yaml`** —— 可选地设置 `framework.version: 1.1.3`。本次发布没有任何东西读取它。
如果它有两个 `modes:` 区块——`/start` 可能写了第二个——请把它们合并为一个。

---

## v1.1.1 → v1.1.2

**Released:** 2026-09-29
**Commit range:** `v1.1.1..v1.1.2`
**Key themes:** The default minimal path end to end; engine test, build and
parse commands that report the right result; Unity and Unreal treated like
Godot; hook warnings you can see; skills that read the whole argument

## v1.1.1 → v1.1.2

**发布日期：** 2026-09-29
**提交范围：** `v1.1.1..v1.1.2`
**核心主题：** 默认的最小路径端到端打通；引擎测试、构建和
解析命令能报告正确结果；Unity 和 Unreal 得到与
Godot 同等的对待；你能看见的钩子警告；读取完整参数的技能

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

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **最小路径** | `/help`、`/story-done`、`/sprint-status` 和状态行遵循最小路线；约 25 个默认标签得到修正；当没有概念文档时，10 个技能和 4 个总监门禁读取 `design/game-brief.md`；`/dev-story` 和 `/story-done` 写入会话检查点 |
| **引擎命令** | `/setup-engine`、`/test-setup`、`/dev-story`、`/smoke-check`、`qa-tester` 智能体和 `run-and-observe.md` 使用在 Windows 上以 Godot 4.6.1、Unity 6000.3.23f1 和 Unreal 5.7 运行过的命令；Unreal 的 Linux 和 macOS 命令来自 Epic 的文档 |
| **Unity / Unreal** | 八条规则新增 Unity（`Assets/`）和 Unreal（`Source/`、`Content/`、`.usf`/`.ush`）通配；提交和资产钩子检查每个引擎的数据文件夹；状态行和三份清单能找到代码根目录 |
| **钩子** | 警告以钩子 JSON 形式到达（`yaml-helper.sh` 中的 `hook_warn`）；提交和推送检查能在命令中任意位置找到 `git`，跳过带引号的 here-doc 文本，并对 PowerShell 工具运行；提交检查校验每个数据文件的已暂存副本；会话启动会限制其打印的检查点长度 |
| **技能（7 个）** | `/adopt`、`/balance-check`、`/gate-check`、`/review-all-gdds`、`/scope-check`、`/sprint-status`、`/story-readiness` 读取 `$ARGUMENTS`，而不是它的第一个词 |
| **智能体** | 几乎每个智能体文件都有变化：总监以其定义文件所给的裁决词来回答每个门禁；`creative-director`、`producer` 和 `technical-director` 把记忆保存在项目中；`devops-engineer` 采用主干开发，并与 `community-manager` 一起运行在 Sonnet 上；`qa-tester` 的 Unity 和 Unreal 模板可以编译；Unity 和 Unreal 智能体会核对其引擎参考；不写代码的智能体先起草并询问再写入 |

没有任何设置改变含义，也没有任何东西被自动迁移。

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

### 文件：可安全覆盖

**要覆盖的现有文件（无用户内容）：**
```
.claude/skills/**                            ← 几乎所有技能都有变化，包括
                                               gate-check/references/gate-production.md
.claude/hooks/*.sh                           ← validate-commit、validate-push、
                                               validate-assets、validate-skill-change、
                                               session-start、detect-gaps、pre-compact、
                                               post-compact、log-agent、log-agent-stop、
                                               log-instructions、yaml-helper
.claude/statusline.sh
.claude/scripts/artifact-check.sh, project-coherence.sh, migrate-v1-config.sh,
                                               gdd-structure-check.sh, review-scope.sh
.claude/scripts/review-receipts.sh           ← 回退到 shasum，每台 Mac 都有
.claude/scripts/godot-parse-check.gd         ← 新增：/dev-story 的 Godot 解析检查
.claude/scripts/story-status.sh              ← 新增：/help 和
                                               /sprint-status 据此路由的故事列表
.claude/agents/*.md                          ← 几乎每个智能体都有变化（见上文
                                               智能体）；合并任何你编辑过的，并参见
                                               下文的总监智能体记忆
.claude/docs/**                              ← 除了 technical-preferences.md，它是
                                               你的，且在 1.1.2 中未变。
                                               包括 templates/game-brief.md
                                               （新增 Reference game 行）
docs/WORKFLOW-GUIDE.md, docs/skill-flow-diagrams.md,
docs/COLLABORATIVE-DESIGN-PRINCIPLE.md, docs/engine-reference/README.md
docs/engine-reference/godot/current-best-practices.md, breaking-changes.md,
deprecated-apis.md, modules/rendering.md;
docs/engine-reference/unity/current-best-practices.md,
plugins/addressables.md;
docs/engine-reference/unreal/modules/networking.md,
docs/engine-reference/unreal/current-best-practices.md,
plugins/gameplay-ability-system.md
                                             ← 修正的示例；Godot、Unity
                                               和 Unreal 参考新增命令行
                                               章节（各平台的构建和测试命令，
                                               附来源）。如果 /setup-engine
                                               已更新你的某个副本，请改为合并
                                               那个文件
README.md, CHANGELOG.md, UPGRADING.md        ← 如果 README 是你游戏的，保留你的
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

### 文件：需谨慎合并

**`.claude/settings.json`** —— 如果你没有编辑过它，就用随附文件覆盖它。
如果你编辑过，请把运行 `validate-commit.sh` 和 `validate-push.sh` 的
`PreToolUse` 条目的 `matcher` 从
`"Bash"` 改为 `"Bash|PowerShell"`，并复制新的 `deny` 规则：那些
`PowerShell(…)` 规则、`Bash(git push *--force*)` / `Bash(git push * -f*)`，以及
递归删除、`git clean`、`git reset --hard` 和强制推送的各种变体
（`rm -fr`、无空格的 `rm -rf*`、诸如
`rm -r --force` 的 `--recursive` / `--force` 拼法、`git clean* -f*`、`git clean* -df*` 及其他 `git clean`
强制形式，能同时捕获子命令之前 git 选项的
`git *clean* …`、`git *push* -f*` / `-uf*` / `+*` 和
`git *reset *--hard*` 形式
（`git -C x clean -f`）、`git push * +*`、`git * push *--force*`、
`Remove-Item * -r*`）。`git clean` 规则列出常见的强制形式，而不是
`git clean -*f*`，后者还会拒绝诸如
`git clean -n config/` 的试运行，而且没有任何允许规则能撤销一条拒绝。`git` 规则会在
`git` 之后的任意位置匹配，因此一条 git 命令只要文本符合其中之一就会被拒绝，即使
没有运行任何危险操作：一条提到这些
命令之一的提交信息，或诸如 `git commit -m "push + pull"`（`push` 然后 ` +`）的普通散文
——请改写该信息。把 `-f` 写在前的试运行，
`git clean -fn`，也会被拒绝；请把它写成 `git clean -n`。1.1.1 的
`Bash(git clean -f*)` 已被新规则覆盖，可以移除。

**`.claude/rules/*.md`** —— 如果你没有编辑过某条规则，就用随附文件覆盖它。
如果你编辑过，请保留你的文本，复制
随附文件中的每一行 `paths:`——它们在八条规则中都有变化——并
合并下文列出的五个有变化的正文。没有
Unity（`Assets/**`）和 Unreal（`Source/**`、`Content/**`）通配，该规则
在这些引擎上永远不会加载。把每个通配都保留在双引号中——未加引号的
`*` 会破坏 frontmatter，而 frontmatter 无法解析的规则会在每个文件上加载。
代码规则的通配现在标明其文件类型（`*.cs`、
`*.{h,cpp}`），`data-files.md` 的以 `*.json` 结尾，且有五个规则正文有变化：
`test-standards.md` 按引擎命名测试，`shader-code.md`、
`gameplay-code.md` 和 `engine-code.md` 给出 Unity 和 Unreal 示例，而
`agent-memory.md` 指明每个引擎的代码根目录。

**`src/CLAUDE.md`** —— 如果你没有编辑过它，就用随附文件覆盖它。
如果你编辑过，请合并：它的 File Routing 章节现在
指向 `project.yaml` 的 `specialists` 区块，而不是 `CLAUDE.md`。

**`.gitignore`** —— 添加 `/reports/` 和 `/test-results/`（gdUnit4 和 Unity 测试
输出），并在 `bin/` 之后的下一行添加 `!addons/gdUnit4/bin/`：没有它，
`bin/` 规则会把 gdUnit4 的测试运行器挡在你的提交之外，而全新的克隆
或 CI 就没有运行器。

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

**你的 `project.yaml` `commands:` 区块** —— `/setup-engine` 把这些写进了你的
项目，因此更新模板不会改变它们。如果你在 1.1.0 或 1.1.1 上设置过引擎：

| 引擎 | 键 | 旧 (1.1.1) | 新 |
|---|---|---|---|
| Godot | `test` | `godot --headless --script tests/gdunit4_runner.gd` | `godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode` |
| Unity | `build` | `Unity -batchmode -quit -projectPath . -buildTarget <TARGET>` | `"<Unity editor>" -batchmode -quit -projectPath . -buildTarget <TARGET> -build<PLATFORM>Player Builds/<Target>/<Game>.exe`（例如 `-buildWindows64Player`） |
| Unity | `test` | `Unity -runTests -projectPath . -testPlatform PlayMode` | `"<Unity editor>" -batchmode -runTests -projectPath . -testPlatform EditMode -testResults test-results/editmode.xml` |
| Unity | `smoke` | `Unity -batchmode -quit -projectPath . -executeMethod SmokeCheck.Run` | `"<Unity editor>" -batchmode -quit -projectPath . -logFile -` |
| Unreal | `build` | `RunUAT.bat BuildCookRun -project=<project>.uproject -platform=Win64 -build -cook` | `"<UE root>/Engine/Binaries/DotNET/AutomationTool/AutomationTool.exe" BuildCookRun -project="$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -platform=Win64 -build -cook` |
| Unreal | `test` | `UnrealEditor-Cmd.exe <project>.uproject -ExecCmds="Automation RunTests <project>; Quit" -unattended -nullrhi` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -ExecCmds="Automation RunTests <project>.; Quit" -unattended -nullrhi -stdout -FullStdOutLogOutput` |
| Unreal | `smoke` | `UnrealEditor-Cmd.exe <project>.uproject -game -nullrhi -unattended -ExecCmds="Quit"` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -nullrhi -unattended -stdout -ExecCmds="Quit"` |
| Unreal | `run` | `UnrealEditor.exe <project>.uproject -game -windowed -ResX=1280 -ResY=720` | `"<UE root>/Engine/Binaries/Win64/UnrealEditor.exe" "$(pwd -W 2>/dev/null || pwd)/<project>.uproject" -game -windowed -ResX=1280 -ResY=720` |

Godot 还需要在 `addons/gdUnit4/` 下安装 gdUnit4。如果 `godot` 不在
你的 `PATH` 上（Windows 和 macOS 的默认情况），`/setup-engine` 现在会改为写入
编辑器的完整路径：把它用双引号括起，放在每个 Godot
`commands.*` 值的开头，把该值写成单引号的 YAML 标量，并把
同一路径记录为 `engine.path`——
`build: '"C:/Program Files/Godot/Godot_v4.6.1-stable_win64.exe" --headless --export-debug "Windows Desktop"'`。
对于 Unity，
`<Unity editor>` 是编辑器的完整路径，带引号——裸 `Unity` 可能解析到
Unity 独立的 CLI，它会以 exit 2 拒绝 `-batchmode`，与测试失败是同一个退出码。
带引号的路径需要单引号的 YAML 值：
`test: '"C:/Program Files/Unity/Hub/Editor/<version>/Editor/Unity.exe" -batchmode …'`。

Unreal 各行是 Windows 命令。在 Linux 上，`build` 是
`"<UE root>/Engine/Build/BatchFiles/RunUAT.sh" BuildCookRun … -platform=Linux -build -cook`，
而 `test`、`run` 和 `smoke` 使用 `"<UE root>/Engine/Binaries/Linux/UnrealEditor"`，
参数相同。在 macOS 上只保留 `build`（`RunUAT.sh … -platform=Mac`），
其余三个由你自己设置：Epic 没有记录 `UnrealEditor.app` 内部的命令行编辑器。
`/setup-engine` 的 Unreal 章节有确切的命令行。

对于 Unreal，`<UE root>` 是引擎文件夹（`engine.path`）——`PATH` 上没有编辑器
二进制——且项目路径必须是绝对路径：UE 5.7 找不到
相对路径的 `<project>.uproject`，会在运行任何东西之前以 1 退出。
`$(pwd -W 2>/dev/null || pwd)` 在 Git Bash 中给出 `C:/…` 形式，即使设置了
`MSYS_NO_PATHCONV`。这些值含有双引号，因此也采用
单引号的 YAML 标量。

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

**`.github/workflows/tests.yml`（Godot）** —— 如果 `/test-setup` 写过它，请像
随附模板现在所做的那样，为 `test` 任务添加带 `contents: read` 和 `checks: write` 的
`permissions:`。gdUnit4 action 会发布一个 check run，而
新仓库的 token 是只读的，因此没有它，即使每个测试都通过，任务也会失败。
在测试步骤中，复制随附的 `uses:` 行
（`godot-gdunit-labs/gdUnit4-action@v1`），把 `godot-version` 设为 `godot --version`
打印的完整发布号（例如 `4.6.1`；1.1.1 填的是 VERSION.md 的 `4.6`，
那不是一个发布号），并添加 `version: 'installed'`：没有它，action 会删除
你提交在 `addons/` 下的 gdUnit4 并安装最新发布。如果你
保护 `main`，请要求 `Run GdUnit4 Tests` 任务的检查，而不是 `test-results`，
后者即使测试失败也会通过。

**`.github/workflows/tests.yml`（Unreal）** —— 如果 `/test-setup` 写过它，请在测试步骤之前
添加随附 `/test-setup` 中的 `Build Editor Target` 步骤，
在 runner 上设置 `UE_ROOT`，并用
`-stdout -FullStdOutLogOutput` 替换 `-log`，好让结果到达 CI 日志。1.1.1
模板运行的是 `Automation RunTests MyGame.`；请把过滤器改为你项目的
测试根（`<Project>.`，与 `commands.test` 中一样），否则没有测试匹配。全新的检出
没有编译好的游戏模块，因此没有那次构建，编辑器会在运行测试之前退出。
把 `runs-on: self-hosted` 改为 `runs-on: [self-hosted, windows]`：
用裸标签时，GitHub 可能把任务交给该仓库拥有的任意自托管 runner，
包括没有 Unreal 的 Linux runner。把每个
`shell: bash` 改为 `shell: bash --noprofile --norc -eo pipefail "{0}"`：
Windows runner 会把脚本路径不加引号地传给 bash，因此当
runner 的文件夹名里含有空格时，每个步骤都会失败。

**写在 1.1.x 上的测试** —— Unity 从不会编译 `tests/` 下的测试：把它们移到
`Assets/Tests/EditMode/` 或 `Assets/Tests/PlayMode/`，每个都带一个程序集
定义（`/test-setup` 展示了布局）。Unreal 从不会构建 `Source/Tests/`：
把测试移到 `Source/<Module>/Private/Tests/`，并把
`EAutomationTestFlags::GameFilter` 替换为
`EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter`。

**总监智能体的记忆** —— `creative-director`、`producer` 和
`technical-director` 现在声明 `memory: project`，因此它们在此项目中读写
`.claude/agent-memory/<agent>/`。它们此前保存的笔记位于
`~/.claude/agent-memory/<agent>/`，不再被读取；请把属于此项目的笔记
复制过来。如果你编辑过那些智能体文件，请在其 frontmatter 中把
`memory: user` 改为 `memory: project`。

**`production/session-state/active.md`** —— 无需处理。第一次 `/dev-story` 或
`/story-done` 会在较旧文件的顶部添加 STATUS 和 CHECKPOINT 区块，
其余部分保持不变。

**`design/game-brief.md`** —— 可选：添加一行 `**Reference game:**`（参见
模板）。

**Python 3** —— 现在列为必需。如果你在没有它的情况下运行，所有设置都
静默处于默认值；安装它，你的 `project.yaml` 就会生效。

**`modes.review_mode` / `production/review-mode.txt`** —— 1.1.x 的 `/sprint-plan`
在第一次运行时会把评审模式写入 `project.yaml` 和 `production/review-mode.txt`，
从而永久地把它固定在 `modes.rigor` 之上。如果你不是自己选择
那个值，请把两者都移除，好让 `modes.rigor` 重新生效（`/settings`
会显示每个值来自哪里）。

**`project.yaml`** —— 可选地设置 `framework.version: 1.1.2`。本次发布没有任何东西读取它。

---

## v1.1.0 → v1.1.1

**Released:** 2026-09-24
**Commit range:** `d056997..v1.1.1`
**Key themes:** Fix for skills and agents failing to start outside auto mode ([#128](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/128))

## v1.1.0 → v1.1.1

**发布日期：** 2026-09-24
**提交范围：** `d056997..v1.1.1`
**核心主题：** 修复技能和智能体在自动模式之外无法启动的问题（[#128](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/128)）

### What Changed

| Category | Changes |
|----------|---------|
| **Skill fix (66 skills)** | The config line at the top of each skill is now one plain `bash` command, pre-approved in that skill's own `allowed-tools`. The 1.1.0 line aborted the skill outside auto mode |
| **Helper** | `.claude/hooks/yaml-helper.sh` can be run directly as `bash yaml-helper.sh resolve_config …`, and finds the project root from its own location |
| **Docs** | `.claude/docs/config-resolution.md` documents the required form and why |

No settings, config files or agents change. Your `project.yaml` and
`project.local.yaml` are untouched apart from the version stamp.

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **技能修复（66 个技能）** | 每个技能顶部的配置行现在是一条普通的 `bash` 命令，已在该技能自己的 `allowed-tools` 中预先批准。1.1.0 的那一行会让技能在自动模式之外中止 |
| **辅助脚本** | `.claude/hooks/yaml-helper.sh` 可以直接以 `bash yaml-helper.sh resolve_config …` 运行，并从自身位置找到项目根目录 |
| **文档** | `.claude/docs/config-resolution.md` 记录了必需的形式及其原因 |

没有设置、配置文件或智能体发生变化。除版本戳之外，你的 `project.yaml` 和
`project.local.yaml` 均未被改动。

---

### Files: Safe to Overwrite

**Existing files to overwrite (no user content):**
```
.claude/skills/*/SKILL.md                 ← all skills with a config line (66)
.claude/hooks/yaml-helper.sh              ← direct-execution entry point
.claude/docs/config-resolution.md         ← corrected "why this command" section
.claude/docs/director-gates.md            ← example line updated
```

### 文件：可安全覆盖

**要覆盖的现有文件（无用户内容）：**
```
.claude/skills/*/SKILL.md                 ← 所有带配置行的技能（66 个）
.claude/hooks/yaml-helper.sh              ← 直接执行入口点
.claude/docs/config-resolution.md         ← 修正的“为什么是这条命令”章节
.claude/docs/director-gates.md            ← 示例行已更新
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

### 文件：需谨慎合并

**你自己编辑过的技能。** 如果你定制过某个技能，请保留你的
版本并改动其中两行——配置行和 `allowed-tools`
条目——改成这种形式，用你的技能文件夹名替换 `<name>`：

```markdown
allowed-tools: …, Bash(bash "*/.claude/skills/<name>/../../hooks/yaml-helper.sh" resolve_config *)
```
```markdown
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys <same keys as before>`
```

两半都需要：只有配置行而没有授权，仍然会中止。这同样
适用于任何你自己编写、复制了 1.1.0 那一行的技能。

**`project.yaml`** —— 可选地设置 `framework.version: 1.1.1`。本次发布没有任何东西读取它。

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

## v1.0 → v1.1

**发布日期：** 2026-09-23
**核心主题：** `project.yaml` 作为唯一事实来源，一套模式系统
（`modes.rigor` 统辖 `workflow`/`docs.density`/`qa.level`/`story_granularity`，
外加 `review_mode` 和 `automation`）、`/settings`、`project.local.yaml`
按开发者覆盖、迁移工具、token 效率削减。

这是自模板的 `production/stage.txt`
/ `production/review-mode.txt` 时代以来最大的配置变更。阅读
[CHANGELOG.md](CHANGELOG.md#110--2026-09-23) 获取完整的新增列表——
本节讲的是你该如何应对。

### What Changed

See [CHANGELOG.md](CHANGELOG.md#110--2026-09-23) for the complete list. The
short version: `project.yaml` replaces `production/stage.txt`,
`production/review-mode.txt`, and `.claude/docs/technical-preferences.md` as
the primary config store (all three still work as a fallback — nothing is
force-deleted), a new `modes` block controls how much process the project
carries (`modes.rigor: minimal | standard | full`), and a new `/settings`
skill views and edits any of it, including a gitignored
`project.local.yaml` for settings that should vary per developer.

### 变更内容

完整列表见 [CHANGELOG.md](CHANGELOG.md#110--2026-09-23)。简而言之：
`project.yaml` 取代 `production/stage.txt`、
`production/review-mode.txt` 和 `.claude/docs/technical-preferences.md`
成为主要的配置存储（三者仍可作为回退使用——没有任何东西被强制删除），
一个新的 `modes` 区块控制项目承载多少流程
（`modes.rigor: minimal | standard | full`），以及一个新的 `/settings`
技能可以查看并编辑其中任何内容，包括一个被 git 忽略的
`project.local.yaml`，用于按开发者变化的设置。

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

### 注意：你默认得到的流程层级已经改变

`modes.rigor` 现在的默认值是 **`minimal`**，而不是 `standard`。如果你的
`project.yaml` 显式设置了 `modes.rigor`，你不会有任何变化，可以跳过
本节。

如果没有设置，升级是可见的：`rigor` 统辖的六个旋钮中，你从未设置过的那些
会从 `standard` 行移到 `minimal` 行。实际上
这意味着更少的必填 GDD 章节、更简洁的写作、更粗粒度的故事、没有总监评审小组，
以及 `qa.level` 从 `standard` 降到 `minimal`。你*确实*显式设置过的
旋钮不受影响。

**要保留旧行为，用一行固定它：**

```yaml
modes:
  rigor: standard
```

我们改变了默认值，是因为 `standard` 要花更多成本才能达到可工作的代码，
却没有产出更好的结果，而且在有人新接手项目时给不出任何回报。大多数项目都在为没有回报的流程付费。
如果你的项目确实需要——多个相互作用的系统，或某项设计必须由别人来实现——
`standard` 和 `full` 只需一次 `/settings` 调用，而 `/help` 和 `/gate-check`
会在你的项目成长时建议你提升它。

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

### 文件：可安全覆盖

**把 `.claude/` 整体取走。不要只复制其中一部分。** v1.1 在该目录下新增了约 73 个
新文件——`automation-modes.md`、`workflow-modes.md`、
`config-resolution.md`、`effects-map.md`、28 个总监门禁、game-brief
模板、7 个指引模板、8 个脚本、6 个 gate-check 参考、10 个
`CONTRACT.md` 文件——而技能之间会跨越所有这些文件互相引用。部分复制会让技能
指向你没有的文档，这会在你运行它们的时刻失败，而不是在你复制的时刻。
这就是这里没有简短文件清单的原因。

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

> **策略 A（git 合并）会在这里自动保护你** —— git 会把该文件标记为冲突，
> 因为你们双方都改过它。手动复制的策略不会：递归复制会一言不发地覆盖它。

你在 `tests/` 下的自有测试以及 `tools/` 下的任何工具都是你的；模板不会向其中
投放任何东西，所以那里没有风险。

复制是增量的：*你*在 `.claude/` 下添加的文件会保留，因为没有任何东西
被删除。只有模板也自带的文件会被替换。

全部 74 个 `SKILL.md` 文件在 v1.1 中都有变化，其中 66 个现在通过
`resolve_config` 解析配置。如果你没有手动编辑过任何技能文件，全部取走是
安全的。

> **`.claude/` 下有两样东西是你的——复制前先检查它们。**
>
> - `.claude/docs/technical-preferences.md` 仍持有你的 Forbidden Patterns
>   和 Allowed Libraries，它们没有 `project.yaml` 对应项。保留你的
>   副本；参见下文 [需谨慎合并](#claudedocstechnical-preferencesmd)。
> - 你定制过的其他任何东西——智能体定义和总监门禁是
>   最常见的。如果你的项目在 git 中，`git log --oneline -- .claude` 会列出
>   你是否有任何定制。请在新版本之上重新应用你的编辑，而不是整体保留旧文件；
>   新版本几乎肯定也在那里做了改动。

（`project.yaml` 本身不会从模板复制——`/start` 为新项目生成它，
而 `.claude/scripts/migrate-v1-config.sh` 为现有项目从
你的旧配置文件构建它。）

---

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

### 文件：需谨慎合并

#### `project.yaml`（新增——这是**你的**数据，不是模板基础设施）

此文件在 v1.0 中不存在。如果你已有项目，并带有
`production/stage.txt`、`production/review-mode.txt`，或一份填写过的
`.claude/docs/technical-preferences.md`，**不要手工编写
`project.yaml`**——那些文件保存着你项目的实际配置，
手工迁移会带来转录错误，而这正是工具链要避免的。请改为遵循专门的
[迁移指南](docs/migration-guide-v1.1.md)，它带你从头到尾走完
`.claude/scripts/migrate-v1-config.sh`。

如果你是从零开始（没有含真实值的旧文件），只需运行
`/start`——它会为你写出完整的 `project.yaml`。

#### `.claude/docs/technical-preferences.md`

保持原位。它的大部分内容（引擎、命名、性能预算、
测试框架、专员）现在都有对应的 `project.yaml` 条目，并会优先
从那里读取。有两个小节——Forbidden Patterns 和 Allowed
Libraries——没有 `project.yaml` 对应项，此文件永久是它们的
归属地；`--finalize` 迁移从不删除它。

### 升级之后

1. 如果你有现有项目（并非从零开始），请阅读
   [docs/migration-guide-v1.1.md](docs/migration-guide-v1.1.md) 并运行
   `.claude/scripts/migrate-v1-config.sh --dry-run`，在正式执行前查看迁移
   会做什么。
2. 一旦 `project.yaml` 存在，运行 `/settings` 查看你的有效配置
   ——它会显示每个设置的值、来源，以及该设置是否
   可在本地覆盖。
3. 如果你的项目不符合 `minimal` 默认值，考虑显式设置 `modes.rigor`
   ——`/settings modes.rigor=standard` 保留 v1.0 的流程
   层级，`modes.rigor=full` 适合想要每一道
   门禁的项目。迁移报告也会说明这一点。
4. 如果你定制过任何技能，请在依赖它之前对照新版本重新阅读
   ——一个与其他框架解析配置方式不同的技能会悄悄失败，
   表现为走默认分支，而不是报错。

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

## v0.4.1

**发布日期：** 2026-04-02
**核心主题：** 美术方向整合、资产规格流水线

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **新技能** | `/art-bible` —— 引导式逐节视觉识别撰写（9 个章节）。每个章节强制生成 art-director Task。AD-ART-BIBLE 签核门禁。在技术设置阶段为必需项。 |
| **新技能** | `/asset-spec` —— 逐资产视觉规格与 AI 生成提示词生成器。读取 art bible + GDD/关卡/角色文档。写入 `design/assets/specs/` 文件与 `design/assets/asset-manifest.md`。Full/lean/solo 模式。 |
| **新总监门禁（3 个）** | `AD-CONCEPT-VISUAL`（brainstorm 第 4 阶段）、`AD-ART-BIBLE`（art bible 签核）、`AD-PHASE-GATE`（gate-check 面板） |
| **`/brainstorm` 更新** | 在 allowed-tools 中加入 `Task`（此前缺失——阻塞了所有总监生成）。支柱锁定后，art-director 现在与 creative-director 并行生成。Visual Identity Anchor 写入 game-concept.md。 |
| **`/gate-check` 更新** | art-director 作为第 4 个并行总监加入（AD-PHASE-GATE）。视觉产物检查：Visual Identity Anchor（概念门禁）、art bible（技术设置门禁）、AD-ART-BIBLE 签核 + 角色视觉档案（预制作门禁）。 |
| **`/team-level` 更新** | art-director 加入第 1 步并行生成（布局前的视觉方向）。Level-designer 现在把 art-director 的目标作为显式约束接收。第 4 步中 art-director 的职责修正为仅限制作概念。 |
| **`/team-narrative` 更新** | art-director 加入第 2 阶段并行生成（角色视觉设计、环境叙事、电影化基调）。 |
| **`/design-system` 更新** | 路由表扩展：Combat、UI、Dialogue、Animation/VFX、Character 类别加入 art-director + technical-artist。视觉/音频小节现在对 7 个系统类别为强制项（含 art-director Task 生成）。 |
| **`workflow-catalog.yaml`** | `/art-bible` 加入技术设置（必需）。`/asset-spec` 加入预制作（可选、可重复）。 |

### 文件：可安全覆盖

**要添加的新文件：**
```
.claude/skills/art-bible/SKILL.md
.claude/skills/asset-spec/SKILL.md
.claude/docs/director-gates.md
```

**要覆盖的现有文件（无用户内容）：**
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

### 文件：需谨慎合并

无——所有变更都是针对不含用户内容的基础设施文件。

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

## v1.0.0-beta → v1.0

**发布日期：** 2026-05-13
**提交范围：** `49d1e45..HEAD`
**核心主题：** 新的 `/vertical-slice` 门禁、技能打磨与缺陷修复、贡献者文档

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **新技能** | `/vertical-slice` —— 预制作门禁，在进入制作前用一个生产质量的端到端构建验证完整游戏循环。与经过大改的 `/prototype`（紧跟 `/brainstorm` 之后的概念验证）配对使用。 |
| **新流程** | `/map-systems` 中的实体清点步骤——在前期就呈现所有命名实体，让下游 GDD 撰写更干净。 |
| **UX 打磨** | 为 7 个技能补上缺失的 `AskUserQuestion` 组件；对技能的一致性、提示词与流程缺口做了全面审计；在所有 `team-*` 技能的 `argument-hints` 中暴露 `--review` 标志。 |
| **缺陷修复** | log-agent 钩子记录 "unknown" 的 `agent_type`；`/architecture-decision` 与 `/story-done` 缺失 `allowed-tools`；`rg --type gdscript` 无效（现改用 `--glob *.gd`）；session-start 预览显示的是最旧状态而非最新状态；`/architecture-decision` 中有重复的 `## 0.` 标题和错乱的步骤编号。 |
| **项目文档** | 新增 `CONTRIBUTING.md`（框架贡献指南）和 `SECURITY.md`（协同披露政策）。 |
| **计数/引用** | 在 `WORKFLOW-GUIDE.md`、`README.md` 和智能体名册之间同步了智能体/技能/钩子计数；修正了过时的智能体名称和技能模型层级字段。 |

---

### 文件：可安全覆盖

**要添加的新文件：**
```
.claude/skills/vertical-slice/SKILL.md
CONTRIBUTING.md
SECURITY.md
```

**要覆盖的现有文件（无用户内容）：**
- `.claude/skills/` 下在提交范围内被修改的所有文件（技能审计 + AskUserQuestion 组件 + `--review` argument-hints）
- `.claude/hooks/log-agent.sh`（`agent_type` 日志修复）
- `README.md`、`docs/WORKFLOW-GUIDE.md`、`docs/skill-flow-diagrams.md`
- `UPGRADING.md`

---

### 文件：需谨慎合并

无——所有变更都是针对不含用户内容的基础设施文件。

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

## v0.4.x → v1.0

**发布日期：** 2026-03-29
**提交范围：** `6c041ac..HEAD`
**核心主题：** 总监门禁系统、门禁强度模式、Godot C# 专员

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **新系统** | 总监门禁——在所有工作流技能之间共享的具名评审检查点。定义于 `.claude/docs/director-gates.md` |
| **新功能** | 门禁强度模式：`full`（全部总监门禁）、`lean`（仅阶段门禁）、`solo`（无总监）。在 `/start` 期间通过 `production/review-mode.txt` 全局设置，或在任何使用门禁的技能上用 `--review [mode]` 按次覆盖 |
| **新智能体** | `godot-csharp-specialist` —— Godot 4 项目中的 C# 代码质量 |
| **技能更新（13 个）** | 所有使用门禁的技能现在都会解析 `--review [full\|lean\|solo]` 并将其纳入 argument-hint：`brainstorm`、`map-systems`、`design-system`、`architecture-decision`、`create-architecture`、`create-epics`、`create-stories`、`sprint-plan`、`milestone-review`、`playtest-report`、`prototype`、`story-done`、`gate-check` |
| **`/start` 更新** | 新增第 3b 阶段——在入职引导期间设置评阅模式，写入 `production/review-mode.txt` |
| **`/setup-engine` 更新** | 针对 Godot 的语言选择步骤（GDScript vs C#） |
| **文档** | `director-gates.md` —— 完整门禁目录；`WORKFLOW-GUIDE.md` —— 总监评审模式小节；`README.md` —— 评审强度定制 |

---

### 文件：可安全覆盖

**要添加的新文件：**
```
.claude/agents/godot-csharp-specialist.md
.claude/docs/director-gates.md
```

**要覆盖的现有文件（无用户内容）：**
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

### 文件：需谨慎合并

本次发布没有任何文件需要手动合并。所有变更都是针对不含用户内容的基础设施文件。

---

### 新功能

#### 总监门禁系统

所有主要工作流技能现在都会引用定义在
`.claude/docs/director-gates.md` 中的具名门禁检查点。门禁由域前缀和名称标识
（例如 `CD-CONCEPT`、`TD-ARCHITECTURE`、`LP-CODE-REVIEW`）。每个门禁定义了
要生成哪位总监、要传入什么输入、判定结果意味着什么，以及
lean/solo 模式会如何影响它。

技能使用 `Task` 并传入门禁 ID 和文档化的输入来生成门禁，而不是
把总监提示词内联嵌入。这保持了技能主体的整洁，并让
门禁行为在所有工作流阶段保持一致。

#### 门禁强度模式

三种模式让你控制获得多少总监评审：

- **`full`**（默认）—— 在每个评审检查点运行所有总监门禁
- **`lean`** —— 跳过逐技能的总监评审；`/gate-check` 处的阶段门禁仍然运行
- **`solo`** —— 任何地方都没有总监门禁；`/gate-check` 只检查产物是否存在

在 `/start` 期间全局设置（写入 `production/review-mode.txt`）。在任何使用门禁的技能上
用 `--review [mode]` 覆盖单次运行：

```
/design-system combat --review lean
/gate-check systems-design --review full
/brainstorm my-game-idea --review solo
```

---

### 升级之后

1. 运行一次 `/start` 设置你偏好的评阅模式——或手动用 `full`、`lean` 或 `solo` 创建 `production/review-mode.txt`。
2. 如果你身处项目中期，请查阅 `.claude/docs/director-gates.md`，了解哪些门禁适用于你当前阶段。
3. 运行 `/skill-test static all` 验证所有技能通过结构检查。

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

## v0.4.0 → v0.4.1

**发布日期：** 2026-03-26
**提交范围：** `04ed5d5..HEAD`
**核心主题：** 类型无关的智能体、新技能、技能修复

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **新技能（1 个）** | `/consistency-check` —— 跨 GDD 的实体一致性扫描器 |
| **技能修复（所有 team-*）** | 新增无参数守卫、正式的 `Verdict: COMPLETE / BLOCKED` 关键词、逐步 AskUserQuestion 门禁、相邻区域依赖检查（team-level）、伦理强制（team-live-ops）、带阶段跳过的 NO-GO 路径（team-release） |
| **智能体修复（4 个）** | game-designer、systems-designer、economy-designer、live-ops-designer 中的类型无关措辞——移除了 RPG 专属术语 |

---

### 文件：可安全覆盖

**要添加的新文件：**
```
.claude/skills/consistency-check/SKILL.md
```

**要覆盖的现有文件（无用户内容）：**
```
.claude/skills/team-combat/SKILL.md      ← 无参数守卫、判定关键词、门禁改进
.claude/skills/team-narrative/SKILL.md   ← 无参数守卫、判定关键词、门禁改进
.claude/skills/team-ui/SKILL.md          ← 无参数守卫、判定关键词、门禁改进
.claude/skills/team-release/SKILL.md     ← 无参数守卫、判定关键词、NO-GO 路径
.claude/skills/team-polish/SKILL.md      ← 无参数守卫、判定关键词、门禁改进
.claude/skills/team-audio/SKILL.md       ← 无参数守卫、判定关键词、门禁改进
.claude/skills/team-level/SKILL.md       ← 无参数守卫、判定关键词、相邻区域检查
.claude/skills/team-live-ops/SKILL.md    ← 无参数守卫、判定关键词、伦理强制
.claude/skills/team-qa/SKILL.md          ← 无参数守卫、判定关键词、门禁改进
.claude/skills/map-systems/SKILL.md      ← 判定关键词
.claude/skills/create-epics/SKILL.md     ← "May I write" 协议修复、判定关键词
.claude/skills/create-stories/SKILL.md   ← 判定关键词
.claude/agents/game-designer.md          ← 类型无关措辞
.claude/agents/systems-designer.md       ← 类型无关措辞
.claude/agents/economy-designer.md       ← 类型无关措辞
.claude/agents/live-ops-designer.md      ← 类型无关措辞
```

---

### 文件：需谨慎合并

本次发布没有任何文件需要手动合并。所有变更都是针对不含用户内容的基础设施文件。

---

### 升级之后

1. 运行 `/skill-test catalog` 验证所有技能都已纳入索引。
2. 在任何技能编辑后运行 `/skill-test lint [skill-name]` 检查结构合规性。
3. 如果你定制过任何 team-* 技能，请查阅更新后的版本——现在所有 team-* 技能都要求无参数守卫和 `Verdict:` 关键词。

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

## v0.3.0 → v0.4.0

**发布日期：** 2026-03-21
**提交范围：** `b1cad29..HEAD`
**核心主题：** 完整 UX/UI 流水线、完整故事生命周期、棕地采纳、全面的 QA/测试框架、流水线完整性、29 个新技能

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **新技能（17 个）** | `/ux-design`、`/ux-review`、`/help`、`/quick-design`、`/review-all-gdds`、`/story-readiness`、`/story-done`、`/sprint-status`、`/adopt`、`/create-architecture`、`/create-control-manifest`、`/create-epics`、`/create-stories`、`/dev-story`、`/propagate-design-change`、`/content-audit`、`/architecture-review` |
| **新 QA 技能（12 个）** | `/qa-plan`、`/smoke-check`、`/soak-test`、`/regression-suite`、`/test-setup`、`/test-helpers`、`/test-evidence-review`、`/test-flakiness`、`/skill-test`、`/bug-triage`、`/team-live-ops`、`/team-qa` |
| **新钩子（4 个）** | `log-agent-stop.sh` —— 智能体审计轨迹停止；`notify.sh` —— Windows 吐司通知；`post-compact.sh` —— 压缩后的会话恢复提醒；`validate-skill-change.sh` —— 技能编辑后建议运行 `/skill-test` |
| **新模板（8 个）** | `ux-spec.md`、`hud-design.md`、`accessibility-requirements.md`、`interaction-pattern-library.md`、`player-journey.md`、`difficulty-curve.md`，以及 2 个采纳计划模板 |
| **新基础设施** | `workflow-catalog.yaml`（7 阶段流水线，由 `/help` 读取）、`docs/architecture/tr-registry.yaml`（稳定的 TR-ID）、`production/sprint-status.yaml` 架构 |
| **技能更新** | `/gate-check` —— 3 个门禁现在要求 UX 产物；预制作门禁要求垂直切片（HARD 门禁） |
| **技能更新** | `/sprint-plan` —— 写入 `sprint-status.yaml`；`/sprint-status` 读取它 |
| **技能更新** | `/story-done` —— 8 阶段完成评审，更新故事文件，呈现下一个就绪故事 |
| **技能更新** | `/design-review` —— 移除了架构缺口检查（阶段不对） |
| **技能更新** | `/team-ui` —— 完整 UX 流水线（ux-design → ux-review → 团队阶段） |
| **智能体更新** | 14 个专员智能体 —— 新增 `memory: project` |
| **智能体更新** | `prototyper` —— `isolation: worktree`（在隔离的 git 分支中做一次性工作） |
| **模型路由** | Haiku/Sonnet/Opus 层级分配记录在协作规则中；技能在 frontmatter 中声明自己的层级 |
| **目录 CLAUDE.md** | 搭建了 `design/CLAUDE.md`、`src/CLAUDE.md`、`docs/CLAUDE.md` —— 为每个目录提供路径范围指令 |
| **流水线完整性** | TR-ID 稳定性、清单版本化、ADR 状态门禁、TR-ID 引用而非引用原文 |
| **GDD 模板** | 新增 `## Game Feel` 小节（输入响应性、动画目标、打击感时刻） |

---

### 文件：可安全覆盖

**要添加的新文件：**
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

**要覆盖的现有文件（无用户内容）：**
```
.claude/skills/gate-check/SKILL.md
.claude/skills/sprint-plan/SKILL.md
.claude/skills/sprint-status/SKILL.md
.claude/skills/design-review/SKILL.md
.claude/skills/team-ui/SKILL.md
.claude/skills/story-readiness/SKILL.md
.claude/skills/story-done/SKILL.md
.claude/docs/templates/game-design-document.md    ← 新增 Game Feel 小节
README.md
docs/WORKFLOW-GUIDE.md
UPGRADING.md
```

**要覆盖的智能体文件**（如果你没有往里面写过自定义提示词）：
```
.claude/agents/prototyper.md         ← 新增 isolation: worktree
.claude/agents/art-director.md       ← 新增 memory: project
.claude/agents/audio-director.md     ← 新增 memory: project
.claude/agents/economy-designer.md   ← 新增 memory: project
.claude/agents/game-designer.md      ← 新增 memory: project
.claude/agents/gameplay-programmer.md ← 新增 memory: project
.claude/agents/lead-programmer.md    ← 新增 memory: project
.claude/agents/level-designer.md     ← 新增 memory: project
.claude/agents/narrative-director.md ← 新增 memory: project
.claude/agents/systems-designer.md   ← 新增 memory: project
.claude/agents/technical-artist.md   ← 新增 memory: project
.claude/agents/ui-programmer.md      ← 新增 memory: project
.claude/agents/ux-designer.md        ← 新增 memory: project
.claude/agents/world-builder.md      ← 新增 memory: project
```

---

### 文件：需谨慎合并

#### `.claude/settings.json`

此版本注册了四个新钩子。如果你没有定制过 `settings.json`，覆盖是安全的。否则，请手动添加以下钩子条目：

- `log-agent-stop.sh` —— `SubagentStop` 事件（智能体审计轨迹停止）
- `notify.sh` —— `Notification` 事件（Windows 吐司通知）
- `post-compact.sh` —— `PostCompact` 事件（会话恢复提醒）
- `validate-skill-change.sh` —— 过滤到 `.claude/skills/` 写入的 `PostToolUse` 事件

#### 定制过的智能体文件

如果你往智能体 `.md` 文件中添加了项目专属知识，请做一次 diff，并在适当位置手动把 `memory: project` 行加入 YAML frontmatter。创意总监和技术总监智能体有意保留 `memory: user`——只有专员智能体获得 `memory: project`。

---

### 新功能

#### 完整故事生命周期

故事现在有两个技能强制执行的正式生命周期：

- **`/story-readiness`** —— 在开发者接手前验证故事已具备实现条件。检查设计（已关联 GDD 需求）、架构（ADR 已接受）、范围（验收标准可测试）和 DoD（清单版本为当前）。判定：READY / NEEDS WORK / BLOCKED。
- **`/story-done`** —— 实现后的 8 阶段完成评审。验证每条验收标准，检查 GDD/ADR 偏差，提示进行代码评审，把故事文件更新为 `Status: Complete`，并呈现下一个就绪故事。

流程：`/story-readiness` → 实现 → `/story-done` → 下一个故事

#### 完整 UX/UI 流水线

- **`/ux-design`** —— 引导式逐节 UX 规格撰写。三种模式：屏幕/流程、HUD 或交互模式库。读取 GDD UI 需求和玩家旅程。输出到 `design/ux/`。
- **`/ux-review`** —— 验证 UX 规格是否与 GDD 对齐、无障碍层级和模式库相符。判定：APPROVED / NEEDS REVISION / MAJOR REVISION。
- **`/team-ui`** 已更新：第 1 阶段现在把 `/ux-design` + `/ux-review` 作为硬门禁，在视觉设计开始前运行。

#### 棕地采纳

**`/adopt`** 把现有项目接入模板格式。审计 GDD、ADR、故事、systems-index 和基础设施的内部结构。分类缺口（BLOCKING/HIGH/MEDIUM/LOW）。构建有序的迁移计划。从不重新生成现有产物——只填补缺口。

参数模式：`full | gdds | adrs | stories | infra`

此外：`/design-system retrofit [path]` 和 `/architecture-decision retrofit [path]` 会检测现有文件，只添加缺失的小节。

#### 冲刺跟踪 YAML

`production/sprint-status.yaml` 现在是权威的故事跟踪格式：
- 由 `/sprint-plan`（初始化所有故事）和 `/story-done`（把状态设为 `done`）写入
- 由 `/sprint-status`（快速快照）和 `/help`（制作阶段的逐故事状态）读取
- 状态值：`backlog | ready-for-dev | in-progress | review | done | blocked`
- 如果文件不存在，会优雅地回退到 markdown 扫描

#### `/help` —— 上下文感知的下一步

`/help` 读取你当前所处阶段和进行中的工作，检查哪些产物已完成，并准确告诉你下一步该做什么——一个主要必需步骤，外加可选机会。它与 `/start`（仅首次）和 `/project-stage-detect`（全面审计）不同。

#### 全面的 QA 与测试框架

九个新 QA/测试技能，覆盖完整的测试生命周期：

- **`/test-setup`** —— 为你的引擎搭建测试框架和 CI/CD 流水线
- **`/test-helpers`** —— 生成引擎专属的测试辅助库（GDUnit4、NUnit 等）
- **`/qa-plan`** —— 为冲刺或功能生成 QA 测试计划，按测试类型对故事分类
- **`/smoke-check`** —— 在移交给 QA 前运行关键路径冒烟测试门禁
- **`/soak-test`** —— 为长时间游玩会话生成浸泡测试协议（稳定性、内存泄漏）
- **`/regression-suite`** —— 把测试覆盖映射到 GDD 关键路径，找出缺少回归测试的已修复缺陷
- **`/test-evidence-review`** —— 对测试文件和手动证据文档做质量评审
- **`/test-flakiness`** —— 通过读取 CI 运行日志检测非确定性测试
- **`/skill-test`** —— 验证技能文件的结构合规性和行为正确性（三种模式：lint、spec、catalog）

此外新增：**`/bug-triage`** 会重新评估所有未关闭缺陷的优先级、严重度和归属。

#### 技能验证器（`/skill-test`）

`/skill-test` 是一个验证 harness 本身的元技能。在任何技能文件编辑后运行它。三种模式：
- `lint` —— 验证 YAML frontmatter 和必填字段
- `spec [skill-name]` —— 针对特定技能运行行为规格测试
- `catalog` —— 检查 `.claude/skills/` 中的所有技能是否都已纳入目录索引

新的 `validate-skill-change.sh` 钩子会在技能文件被修改时自动提醒你运行 `/skill-test`。

#### Team Live-Ops 与 Team QA 编排

- **`/team-live-ops`** —— 协调 live-ops-designer + economy-designer + community-manager + analytics-engineer 进行发布后内容规划（季节性活动、战斗通行证、留存）
- **`/team-qa`** —— 编排 qa-lead + qa-tester + gameplay-programmer + producer 走完完整的 QA 周期：策略、执行、覆盖和签核

#### 模型层级路由

技能现在根据任务复杂度显式分配到 Haiku、Sonnet 或 Opus 层级。只读状态检查使用 Haiku；复杂的多文档综合使用 Opus；其他一切默认使用 Sonnet。层级分配记录在 `.claude/docs/coordination-rules.md` 中。

#### 目录级 CLAUDE.md 文件

三个新的目录范围 CLAUDE.md 文件（`design/`、`src/`、`docs/`）为在这些目录中工作的智能体提供路径专属指令。当 Claude Code 读取该目录中的文件时，它们会自动加载。

---

### 升级之后

1. **验证新钩子**已在 `.claude/settings.json` 中注册——检查全部四个：`log-agent-stop.sh`、`notify.sh`、`post-compact.sh`、`validate-skill-change.sh`。

2. **测试审计轨迹**，方法是生成任意子智能体——开始和停止事件都应出现在 `production/session-logs/` 中。

3. **生成 sprint-status.yaml**，如果你正处于活跃制作中：
   ```
   /sprint-plan status
   ```

4. **运行 `/adopt`**，如果你有早于此模板版本的现有 GDD 或 ADR——它会识别需要添加哪些小节，而不会覆盖你的内容。

5. **验证你的技能**，在任何技能编辑后用 `/skill-test` 检查——新的 `validate-skill-change.sh` 钩子会自动提醒你这样做。

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

## v0.2.0 → v0.3.0

**发布日期：** 2026-03-09
**提交范围：** `e289ce9..HEAD`
**核心主题：** `/design-system` GDD 撰写、`/map-systems` 改名、自定义状态行

### 破坏性变更

#### `/design-systems` 改名为 `/map-systems`

为清晰起见，`/design-systems` 技能已改名为 `/map-systems`
（分解 = *映射*，而不是*设计*）。

**需要采取的行动：** 更新任何调用
`/design-systems` 的文档、笔记或脚本。新的调用方式是 `/map-systems`。

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **新技能** | `/design-system`（引导式 GDD 撰写，逐节进行） |
| **改名技能** | `/design-systems` → `/map-systems`（破坏性改名） |
| **新文件** | `.claude/statusline.sh`、`.claude/settings.json` 的 statusline 配置 |
| **技能更新** | `/gate-check` —— PASS 时写入 `production/stage.txt`，新的阶段定义 |
| **技能更新** | `brainstorm`、`start`、`design-review`、`project-stage-detect`、`setup-engine` —— 交叉引用修复 |
| **缺陷修复** | `log-agent.sh`、`validate-commit.sh` —— 钩子执行已修复 |
| **文档** | 新增 `UPGRADING.md`，更新 `README.md`，更新 `WORKFLOW-GUIDE.md` |

---

### 文件：可安全覆盖

**要添加的新文件：**
```
.claude/skills/design-system/SKILL.md
.claude/statusline.sh
```

**要覆盖的现有文件（无用户内容）：**
```
.claude/skills/map-systems/SKILL.md      ← 原为 design-systems/SKILL.md
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

**删除（被改名取代）：**
```
.claude/skills/design-systems/   ← 整个目录；由 map-systems/ 取代
```

---

### 文件：需谨慎合并

#### `.claude/settings.json`

新版本新增了一个指向
`.claude/statusline.sh` 的 `statusLine` 配置块。如果你没有定制过 `settings.json`，覆盖
是安全的。否则，请手动添加此块：

```json
"statusLine": {
  "script": ".claude/statusline.sh"
}
```

---

### 新功能

#### 自定义状态行

`.claude/statusline.sh` 在终端状态行中显示 7 阶段制作流水线的
面包屑导航：

```
ctx: 42% | claude-sonnet-5 | Systems Design
```

在制作/打磨/发布阶段，如果存在 `<!-- STATUS -->` 块，它还会从
`production/session-state/active.md` 显示当前活动的史诗/功能/任务：

```
ctx: 42% | claude-sonnet-5 | Production | Combat System > Melee Combat > Hitboxes
```

当前阶段会从项目产物自动检测，也可以通过把阶段名写入
`production/stage.txt` 来固定。

#### `/gate-check` 阶段推进

当门禁 PASS 判定被确认后，`/gate-check` 现在会把新阶段名
写入 `production/stage.txt`。这会立即更新所有未来会话的状态行，
无需手动编辑文件。

---

### 升级之后

1. **删除旧的技能目录：**
   ```bash
   rm -rf .claude/skills/design-systems/
   ```

2. **测试状态行**：启动一个 Claude Code 会话——你应该能在终端页脚
   看到阶段面包屑导航。

3. **验证钩子执行**仍然正常：
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

## v0.1.0 → v0.2.0

**发布日期：** 2026-02-21
**提交范围：** `ad540fe..e289ce9`
**核心主题：** 上下文韧性、AskUserQuestion 集成、`/map-systems` 技能

### 变更内容

| 类别 | 变更 |
|----------|---------|
| **新技能** | `/start`（入职引导）、`/map-systems`（系统分解）、`/design-system`（引导式 GDD 撰写） |
| **新钩子** | `session-start.sh`（恢复）、`detect-gaps.sh`（缺口检测） |
| **新模板** | `systems-index.md`、3 个协作协议模板 |
| **上下文管理** | 大规模重写——新增文件支撑的状态策略 |
| **智能体更新** | 14 个设计/创意智能体——AskUserQuestion 集成 |
| **技能更新** | 所有 7 个 `team-*` 技能 + `brainstorm` —— 阶段转换处的 AskUserQuestion |
| **CLAUDE.md** | 从约 159 行精简到约 60 行；文档导入从 10 个减为 5 个 |
| **钩子更新** | 全部 8 个钩子——Windows 兼容性修复、新功能 |
| **移除的文档** | `docs/IMPROVEMENTS-PROPOSAL.md`、`docs/MULTI-STAGE-DOCUMENT-WORKFLOW.md` |

---

### 文件：可安全覆盖

这些是纯基础设施——你从未定制过它们。直接复制新版本，
对你的项目内容没有风险。

**要添加的新文件：**
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

**要覆盖的现有文件（无用户内容）：**
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

**要覆盖的智能体文件**（如果你没有往里面写过自定义提示词）：
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

如果你*确实*定制过智能体提示词，请参见下文的"需谨慎合并"。

---

### 文件：需谨慎合并

这些文件同时包含模板结构和你的项目专属内容。
**不要**覆盖它们——请手动合并变更。

#### `CLAUDE.md`

模板版本从约 159 行精简到约 60 行。关键的结构性变更：
移除了 5 个文档导入，因为它们本来就会被 Claude Code
自动加载（agent-roster、skills-reference、hooks-reference、
rules-reference、review-workflow）。

**从你的版本中保留什么：**
- `## Technology Stack` 小节（你的引擎/语言选择）
- 你做过的任何项目专属添加

**从新版本中采纳什么：**
- 更精简的导入清单（如果存在那 5 个多余的 `@` 导入，请删掉）
- 更新后的协作协议措辞

#### `.claude/docs/technical-preferences.md`

如果你运行过 `/setup-engine`，此文件含有你的引擎配置、命名
约定和性能预算。全部保留。模板版本只是
空白占位符。

#### `.claude/docs/templates/game-concept.md`

轻微的结构更新——新增了一个指向
`/map-systems` 的 `## Next Steps` 小节。如果你需要更新后的
指引，可以把该小节加入你的副本，但不是必需的。

#### `.claude/settings.json`

检查新版本是否添加了你想要的权限规则。变更
很小（架构更新）。如果你没有定制过 `settings.json`，
覆盖是安全的。

#### 定制过的智能体文件

如果你往任何智能体 `.md` 文件中添加了项目专属知识或自定义行为，
请做一次 diff，并手动加入新的 AskUserQuestion 集成
小节，而不是覆盖。每个智能体的变更都是系统提示词末尾
一个标准化的协作协议块。

---

### 文件：删除

这些文件在 v0.2.0 中被移除。如果你的仓库中存在它们，可以安全
删除——它们已被组织更好的替代方案取代。

```
docs/IMPROVEMENTS-PROPOSAL.md      → 由 WORKFLOW-GUIDE.md 取代
docs/MULTI-STAGE-DOCUMENT-WORKFLOW.md → 内容已并入 context-management.md
```

---

### 升级之后

1. **运行 `/project-stage-detect`**，验证系统用新的检测逻辑
   正确读取你的项目。

2. **运行一次 `/start`**，如果你还没用过它——它现在能正确识别
   你的阶段，并跳过你已完成的入职引导步骤。

3. **检查 `production/session-state/`** 存在且被 git 忽略：
   ```bash
   ls production/session-state/
   cat .gitignore | grep session-state
   ```

4. **测试钩子执行**——如果你在 Windows 上，请验证新钩子在 Git Bash 中
   无错误运行：
   ```bash
   bash .claude/hooks/detect-gaps.sh '{}' '{}'
   bash .claude/hooks/session-start.sh '{}' '{}'
   ```

---

*Each future version will have its own section in this file.*

*未来每个版本都会在此文件中有自己的章节。*
