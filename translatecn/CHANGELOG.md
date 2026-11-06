# Changelog

What's new in Claude Code Game Studios, written for the people using it.

See [UPGRADING.md](UPGRADING.md) for step-by-step upgrade instructions, and
[docs/migration-guide-v1.1.md](docs/migration-guide-v1.1.md) if you have an
existing project on the older config files.

# 更新日志

Claude Code Game Studios 的新内容，面向使用它的人撰写。

查看 [UPGRADING.md](UPGRADING.md) 获取逐步升级说明；如果你的现有项目仍在使用
较旧的配置文件，请查看 [docs/migration-guide-v1.1.md](docs/migration-guide-v1.1.md)。

---

## [1.2.0] — 2026-10-19

**The story skills are rebuilt around shared helper scripts, a read guard stops
whole-file reads of large design docs, the engine references move to Godot 4.7
and Unreal Engine 5.8, and no skill pre-approves every shell command any more.**
A minor release. [UPGRADING.md](UPGRADING.md#v113--v120) lists the
`settings.json` merges, the new files and the renamed `studio-tests/` folder.

**故事类技能围绕共享辅助脚本重建，一个读取守卫会阻止对大型设计文档的整文件读取，
引擎参考升级到 Godot 4.7 和 Unreal Engine 5.8，且不再有技能预先批准所有 shell 命令。**
一个次要版本。[UPGRADING.md](UPGRADING.md#v113--v120) 列出了
`settings.json` 的合并、新增文件以及改名后的 `studio-tests/` 文件夹。

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

### 新增

- **会话启动时会告知有新版本发布**，一行显示发布页面以及如何关闭该提示；不会下载或更改任何内容。
  该钩子只读取项目之外的用户级缓存。后台任务最多每天一次向 GitHub 询问最新发布来刷新它，
  因此会话启动从不等待，也不会发送任何关于你项目的信息。用
  `/settings --local updates.check=false` 关闭它，或为团队在
  `project.yaml` 中设置 `updates.check: false`；当设置了 `CI` 时它始终关闭。
- **针对大型设计文档的读取守卫。** 新的 `validate-read.sh` 钩子
  会拒绝在 `design/`、`docs/architecture/` 或 `production/session-state/` 下
  对超过 40 KB 的文档做整文件读取，并按其行号返回标题，
  以便重试时只读取一个小节；范围读取始终通过。协作规则 6 以及大多数读取 GDD、ADR 或
  美术圣经的技能现在都按小节读取。`features.read_guard: off`（或 `false`）关闭它，
  `features.read_guard_kb` 设置大小（#136、#140，由 @mamonbleau 建议）。
- **证据知道自己对应的代码何时改变。** `/dev-story` 会在故事保留的截图旁
  写入 `stamp.txt`，记录它们所证明的文件。`/story-done` 和
  `/test-evidence-review` 会点名自那以后发生变化的每个文件（"重新截取"），
  或对较旧的证据说"无戳记"。它们只报告，从不因此阻塞（#135，由 @jiangshoujie 提出）。
- **故事会列出自己的文件。** 新的故事模板
  `.claude/docs/templates/story.md` 有一个 `## Files` 小节：`/create-stories`
  列出计划中的文件，`/dev-story` 用实际更改的文件替换它们，
  而 `/story-done` 依据该清单检查范围。它过去的范围检查会去找一份没有任何故事拥有的清单，
  因此根本无法运行。
- **辅助脚本回答技能过去手工推导的问题。** `.claude/scripts/` 中的新脚本
  可读取故事事实、ADR 状态、一个 Markdown 小节到下一个标题的边界、
  项目阶段、会话检查点和配置写入。重建后的技能和 `/settings` 使用它们，
  因此同一个问题每次都得到同样的答案，长小节也不会被固定大小的 grep 截断。
  此外还附带了更多供你运行的脚本：缺陷计数、代码标记、
  冲刺运算、技术债评分、不稳定测试率、资产检查、内容
  计数、测试运行和测试脚手架。每个都输出观察结果而非
  判定，并带有 `--help`。除需要 Python 3 的 `agent-check.sh` 和
  `compat-inventory.sh` 外，其余只需 bash 和 awk。`resolve_config` 还为技能作者
  多回答六个问题（`gate_level`、`engine_values`、
  `specialists`、`review_gate`、`input_methods`、`perf_budgets`）。
- **注册表检查。** `registry.sh` 可列出、查找并校验三个
  注册表，并以"历史最高值加一"分配下一个 ID，因此
  退役的 ID 永不被复用。它可读取 1.1.3 的 `/architecture-decision` 写下的、
  未加引号的 `status: superseded_by:` 行，并逐一指出需要加引号的那行。新的
  `validate-registry.sh` 钩子会在对实体或 TR-ID 注册表的
  写入将删除或重新编号某个条目，或设置标头未列出的状态时发出警告，
  而写入注册表的技能随后会校验它。
- **只警告、从不禁用的写入规则。** `validate-write.sh` 会标记这样的写入：
  将替换技能从不覆盖的文件（已存在的 `EPIC.md`、
  `project.godot`、引擎参考文档）、设置超出其清单的配置值、
  越过原型边界，或破坏本地化冻结。
  `validate-agent-artifact.sh` 会在子智能体停止时未写入其任务书点名的
  文件时告知你。
- **`/sprint-plan` 会检查冲刺目标能否演示。** 它列出演示
  目标所需的内容（运行所在的场景、启动它的设置、被选故事点名但无人构建的任何东西），
  并在新的 Goal Prerequisites 小节和 Risks 中报告任何缺口，
  而不阻塞（基于 #76 中 @FreedomPortal 的想法）。
- **针对引擎场景和资产文件的规则**，糟糕的手工编辑可能损坏它们。
  新的路径范围规则 `.claude/rules/scene-files.md` 覆盖 `.tscn`、`.tres`、
  `.unity`、`.prefab` 和 `Assets/**/*.asset`：尽可能使用编辑器，
  绝不编造 Godot 的 `uid://`，在编辑器可访问时绝不手工编辑 Unity YAML。
  `settings.json` 拒绝 `Edit(**/*.uasset)` 和 `Edit(**/*.umap)`，
  这也覆盖写入操作。
- **智能体绝不上游提交。** 协作规则 7：任何智能体都不得在引擎、插件或供应商
  仓库中提交、开启或评论 issue 或 pull request，即使被要求也不行。它只写一份
  草稿供你提交，而 `/bug-report` 说明它只起草。
- **`/skill-test static` 会检查智能体和仅限 Claude Code 的特性**：
  描述过于接近以致可能选错智能体、被要求询问用户的智能体、
  Claude Code 会忽略的设置，以及每个技能、智能体、钩子或
  设置依赖仅由 Claude Code 提供之能力的点。这些从不改变
  判定。`/skill-test` 和 `/skill-improve` 现在会说明通过证明了什么：它们
  只读取文件，从不运行技能。
- **新模板**位于 `.claude/docs/templates/`，用于技能写出的各类版式，
  从缺陷报告和认证清单到 `/help` 输出和
  `sprint-status.yaml`。`/create-stories` 从 `story.md` 写出；其他
  技能尚未使用这些新版式。GDD 模板现在正好是
  `/design-system` 写出的骨架，其指引已移至
  `guidance/game-design-document-guide.md`。

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

### 变更

- **六个技能按 Anthropic 的技能撰写指引重建。**
  `/create-stories`、`/story-readiness`、`/create-epics`、`/dev-story`、
  `/story-done` 和 `/start` 变得更短：主路径在 `SKILL.md`，罕见
  分支在 `references/`（`/start` 是单个 `SKILL.md`），固定步骤在
  辅助脚本中。`/dev-story` 和
  `/story-done` 用更少、具名的文件替换了 1.1.3 的编号阶段文件，而
  `/brainstorm` 仅在 `standard` 和 `full` 下加载完整概念流程。
  - `/start` 从你的描述推断严格度，并在同一张卡片上把它与
    阶段一起展示，只问一个"保存 / 不保存"问题。
  - `/create-stories` 在起草前报告每个管辖 ADR 的状态，并
    阻塞其 ADR 依赖尚未接受项的故故事；`/create-epics`
    标记唯一 ADR 仍为 Proposed 的需求，因此该阻塞依然成立。
  - `/dev-story` 把每个代码故事更改过的文件交给引擎
    专员，其任务书排除了临时辅助函数、对不会发生的错误的处理，
    以及为使测试通过而特设的值。
  - `/story-done` 的报告带有**Reviewed by**行，永不为空：
    `lead-programmer`、`/code-review (you said you ran it; not verified here)`
    或 `self, no independent review`（#135）。
- **引擎参考升级到 Godot 4.7 和 Unreal Engine 5.8。** Godot
  文档覆盖 4.7（最新补丁 4.7.2）：AreaLight3D、HDR 输出、Asset
  Store、VirtualJoystick、Jolt 变更和带类型返回的覆盖。Unreal 5.8
  （最新热修复 5.8.3）的破坏性变更、弃用 API、模块和插件
  均已记录。Unity 仍为 6.3 LTS（最新的 LTS），并列出 6.4 到
  6.6 以及 6.7 测试版作为 API 尚未确认的更新版本。时间线采用
  供应商来源的日期；Unreal 的对象池示例和 GAS 标签调用已修正。
  当 5.8 编辑器与 Epic 的发布说明不一致时，Unreal 参考
  会说明这一点：MegaLights 的提示仍称其为 Experimental，并称需要
  硬件光线追踪且会跳过方向光；Iris 插件仍
  带有 Beta 标记。
  仍停留在 Godot 4.6 或 Unreal 5.7？保留你当前的引擎文件夹。
- **CI 模板。** `/test-setup` 写出 `actions/checkout@v7` 和
  `actions/upload-artifact@v7`（自托管 runner 需要 2.327.1 或更新版本）
  并点名 Godot 4.7.2 和 gdUnit4 6.2。在 Godot 4.7 上，`/setup-engine`
  会在新项目首次导入以 139 退出时（导入完成后退出崩溃）重新运行它。
- **工作树从你当前的提交开始，并获得你的本地配置。**
  `settings.json` 设置 `worktree.baseRef: "head"`，因此工作树（
  原型师的、隔离子智能体的、`claude --worktree`）从你的
  提交开始，而不是远程的默认分支。新的 `.worktreeinclude` 会把
  `project.local.yaml`、`CLAUDE.local.md` 和 `.claude/settings.local.json` 复制进去，
  而 `.gitignore` 忽略 `.claude/worktrees/`。原型师会命名其
  工作树和分支，列出它看不到的未提交文件并要求你
  提交它需要的那些，在项目使用 LFS 时拉取 Git LFS 文件，并
  说明它无法运行哪些检查。
- **什么也不做的钩子停止运行。** `post-compact.sh` 被移除：Claude
  Code 会丢弃它的输出，而 `session-start.sh` 已经恢复了上下文。
  Stop 钩子在后台运行，因此不再拖延一轮对话，而
  `notify.sh` 只针对权限提示和空闲提示触发。
- **智能体以提问结束回合。** 49 个智能体曾被要求"等待 yes"，
  而由技能启动的智能体做不到；它们现在以草稿和问题结束回合，
  由调用方转达给你。`/balance-check`、
  `/tech-debt` 和 `/bug-report` 作为子智能体运行时也这样做。
- **`/settings` 拒绝仅写一个非 `true` 或 `false` 的 `testing.strict`**，
  而不再写入它，并建议最接近的已知键，在写入未知键前询问
  （#135）。
- **`/prototype` 在所有地方都限制为一天**；`/team-release` 可以启动
  `/release-checklist`；`/launch-checklist` 仅在你输入时运行。
- **技能和智能体规格文件夹现在是 `studio-tests/`**，由
  `CCGS Skill Testing Framework/` 改名而来。每个技能规格都会固定其用例
  所假设的设置，`/settings` 也有一个规格。UPGRADING 说明了如何迁移你自己的规格；
  在旧文件夹仍存在时，`/skill-test` 和 `/skill-improve` 也会提示这一点。
- **`/create-stories` 会提出估算。** 每个故事获得一个规模（`S`、`M`
  或 `L`），你可以在故事写出前更改。`/story-readiness`
  在 `standard` 和 `full` 下仍会让没有估算的故事失败，而新故事
  现在已有估算。
- **`yaml-helper.sh` 直接回答六个只读查询**，从
  项目根目录运行（`bash .claude/hooks/yaml-helper.sh resolve_setting <key>` 以及
  另外五个）；`/settings` 和 `/perf-profile` 使用它们。
- **`.gitattributes` 在每次检出时保持 awk 程序和 `.worktreeinclude` 使用 LF**，
  包括 Windows 上的 `core.autocrlf=true`。

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

### 修复

- **`project.yaml` 中重复的键会被合并并点名。** 第二个 `modes:`
  块会在架构检查通过的同时抹掉第一个。现在各块会被合并，
  而会话启动、`/settings` 和 `resolve_config` 会点名重复的键。
- **保存的评审只在其读取过的任何内容都未变化时才会被复用。**
  `/architecture-review` 曾在引擎升级或 TR 注册表、`architecture.md` 或预算变化后
  复用上一次报告。现在它会检查自己读取过的每个文件，
  点名被删除的 GDD 或 ADR，且绝不依据范围更窄的报告。
  `/design-review` 会记录其模式和层级。
- **`/design-review` 检查注册表值出现的每一处**，因此若某个值
  在长 GDD 的表格中重述（敌人生命值、掉落率）且与注册表矛盾，
  会成为一个带行号的阻塞项。
- **`/story-readiness` 要求的验收标准数量与 `story_granularity` 写出的相符**
  （coarse 3/2/1、balanced 2/2/1、fine 1），而不是
  在 `fine` 或 `balanced` 下写出的 Logic 故事上硬性要求三项。
- **需求 ID 和 ADR。** `/create-architecture` 保留已注册的 TR-ID，
  并把新的标记为暂定，因此重跑不再重新编号故事所引用的内容。
  `/architecture-review` 现在可以 Edit，因此它对 `tr-registry.yaml`
  的追加不再重写整个文件。`/architecture-decision`
  会写入 ADR Layer 行；缺少它时每个 ADR 都被计为关键，
  从而在 `standard` 下把建议项变成阻塞项。被取代的状态会按 YAML 要求
  加引号写出。
- **提交检查**会跳过 `design/gdd/` 子目录（如 `archive/`）中的 GDD 副本
  （#133），检查提交实际采纳的副本，并能读取带反斜杠的 PowerShell
  `git add` 路径。`gdd-structure-check.sh` 会把仅含 `[To be designed]` 的小节点名为占位符。
- **会话启动。** 多余的 `.claude/.claude/` 不再让钩子写入
  `.claude/production/`，指向 `.claude/` 自身的 `CLAUDE_PROJECT_DIR`
  也不会。检查点预览会说明它是在
  另一个分支上写入的。"Open bugs"只统计非 Closed 或 Verified
  Fixed 的缺陷。稀疏设计文档提示只统计 `design/gdd/` 顶层的 GDD，
  与提交检查一致，并点名它在 `archive/` 等子目录中跳过的副本。
- **轮换 `active.md` 会保留活动检查点**；过去当该文件来自模板时，
  它会把它移入会话日志。
- **缺失的前置条件会点名生成它们的技能**：没有故事时 `/dev-story` 和
  `/story-done` 会指向 `/create-stories`，而 `/create-epics`
  在 `standard` 和 `full` 下没有 `architecture.md` 时会停止。

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

- **`/adopt` 的"帮我找到它们"选项可用了**：它按标题搜索，
  显示每个文档应归何处，并在用 `git mv` 移动前询问。在
  `workflow: minimal` 下，代码中已包含游戏的项目会被导向
  `/reverse-document design [code root]`，而不是 `/brainstorm`。
- **`/estimate` 测量它要求的规模和分支数**，来自以近似值形式报告的 Grep 计数。
- **部分检查会说明它跳过了什么。** 聚焦的 `/review-all-gdds` 会标注
  其判定（"仅一致性"），在技术设置门禁处不算作完整评审；
  `/smoke-check quick` 会说明未检查覆盖率，而
  打磨和发布门禁不计入它。预制作门禁只按其模式检查过的内容
  计入 `/architecture-review` 报告：`single-gdd` 或 `consistency` 报告
  不再通过基础缺口和引擎审计项，而 1.2.0 之前的报告
  没有 `Mode:` 行，因此不计入其中任何一项。
- **阶段绝不会越过一项无法运行的检查。** 一个有疑虑且有一项必需检查未运行的
  门禁会返回 CONCERNS，而接受疑虑就会推进阶段。`/gate-check` 现在在该检查
  运行前不提供任何覆盖，且其报告会点名它。
- **`/sprint-plan` 在写出计划前会询问**，即使它对 QA 计划问题
  已得到"yes, go ahead"，过去它会把它当作写入批准。
- **Godot 不再导入 `production/`。** 在 Godot 项目中，`production/qa/evidence/`
  中的证据截图，以及 Movie Maker 写在其旁的 `.wav`，
  会被当作游戏资源连同 `.import` 文件导入，而
  默认导出会把它们打包进游戏。新的 `production/.gdignore`
  让 Godot 跳过该文件夹。
- **游玩测试记录算作测试证据。** `/story-done`、
  `/test-evidence-review` 和 `/qa-plan` 过去在
  `production/session-logs/` 中查找它们，而该目录被 git 忽略。它们现在读取
  `production/qa/playtests/`，即 `/playtest-report` 写入之处。
- **`/help` 和 `/gate-check` 能察觉故事缺失。** 两个 `EPIC.md`
  文件曾被当作创建故事步骤所需的两个故事文件，因此该步骤
  在任何故事存在前就被读作已完成。
- **ADR 循环只点名循环上的 ADR。** `adr-dep-graph.sh` 还会
  列出所有依赖某个循环的 ADR，因此建议成了切断一项
  正当依赖。它现在还会打印构建顺序，并点名仍然保留模板文本的
  Depends On 行，而不是把它读作无依赖。
- **`/architecture-review single-gdd` 只写入该系统。** 其"写入全部
  三个文件"会用单个系统的行替换项目级的可追溯性索引，
  并可能建议让其他系统的需求退役。没有 ADR 的评审
  现在报告 NOT ASSESSED，而不是不产出报告就停止，而
  参数提示会列出 `rtm`。
- **架构技能。** `/architecture-decision` 从 `architecture.md` 的 Required ADRs
  读取仍需编写的 ADR，并把空注册表小节的第一个条目
  写成合法 YAML。`/create-architecture` 说明没有系统
  进入 Platform 层，该层没有清单规则。
- **在新 Godot 项目上运行 `/setup-engine`** 会把它在
  `commands.test` 中点名的 gdUnit4 runner 报告为在 `/test-setup` 安装前的预期状态，
  而不是要求你去解决它。它不再期望 `/brainstorm` 推荐引擎：
  `/brainstorm` 记录你的偏好，从不推荐引擎。
- **在 Windows 上写出的评审回执在 Linux 和 macOS 上能正确读取。**
  带 Windows 行尾的回执在那里会把每个文件都读作 CHANGED。
- **指向已不存在小节的指针**在 `/gate-check`、
  `/setup-engine`、`/create-architecture` 和 `/create-stories` 中现在指向正确的
  小节。
- **`project.yaml` 中的多行值会被当作文本读取。** `|` 或 `>`
  值下方的行曾被读作设置：一条含 `review_mode: full` 的笔记
  可能改变评阅模式，而其中的 `stage:` 行会被报告为
  无效阶段。所有读取器、阶段写入器和 `/settings` 现在都会跳过
  该文本；`/settings` 不会覆盖多行值。

### 安全

- **技能只预先批准它们运行的命令。** `allowed-tools` 中一个裸 `Bash`
  条目曾让 34 个技能在默认权限模式下不经询问运行任意 shell 命令。
  现在每个技能都点名其文本会运行的框架脚本和只读
  命令。其他任何内容（包括你的 `commands.test`）都会先询问：
  批准一次，或把 `Bash(<your command> *)` 加入
  `.claude/settings.local.json`。你自留副本的技能需要
  随附的 `allowed-tools:` 行。
- **打标签、合并和部署在运行前会被标记。** 推送检查
  也会对 `git tag`、`git merge`、`gh release`、`butler push` 和
  `steamcmd +run_app_build` 发出警告，而 `/hotfix` 和 `/team-release` 会先询问。
- **相同的 `.env` 保护，规则更少。** 三条 Bash `.env` 拒绝
  规则已移除：`Read(**/.env*)` 和 `Edit(**/.env*)` 已覆盖 Bash 文件
  命令和重定向。`settings-local-template.md` 不再建议
  `Bash(git *)`，因为它也会批准 `git push`。

---

## [1.1.3] — 2026-10-08

**Long skills keep their later steps through a long session, a question nobody
answered is never taken as an answer, and the shipped permissions approve
less.** A fix release for 1.1.2.

**长技能在漫长会话中能保留其后续步骤，无人回答的问题永远不会被当作答案，
而随附的权限批准的内容更少。** 一个针对 1.1.2 的修复版本。

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

### 修复

- **14 个最长的技能在压缩后仍保留其后续阶段。** Claude
  Code 在压缩后只会重新附加被调用技能的第一部分，
  因此长技能的后续阶段可能在会话中途脱落。
  `/adopt`、`/architecture-decision`、`/architecture-review`、
  `/create-architecture`、`/design-system`、`/dev-story`、`/gate-check`、
  `/prototype`、`/review-all-gdds`、`/setup-engine`、`/smoke-check`、
  `/story-done`、`/test-setup` 和 `/ux-design` 现在把每个阶段放在技能
  `references/` 文件夹自己的文件中，在阶段开始时读取，
  并在压缩后再读取。步骤本身未变。这些文件
  相对于技能文件夹命名，因此无论技能安装在何处都能找到，
  且每个超过 100 行的参考文件都以内容清单开头。
  `/skill-test` 和 `/skill-improve` 也会读取这些文件，因此它们
  把拆分后的技能作为整体来判断，并把修复放进持有该文本的文件。
- **被跳过、被忽略或返回空的问题不是答案**，在任何模式下都是如此：
  不会据此写入、设置或选择任何东西，而会以纯文本再次询问。
  引导模式不再自相矛盾：新文件会等待"May I write?"，
  而对现有文件的更新会在简短摘要后直接进行。
- **智能体以简短列表返回选项，供技能来提问。** 14 个
  智能体曾被要求使用提问工具，而由技能启动的智能体
  并没有该工具。
- **从子文件夹读取设置时使用项目根目录。** 在 `src/` 中启动时，
  按系统覆盖会读作无，关于无效或锁定值的提示
  消失，而较旧的 `review-mode.txt` 和 `stage.txt` 从未
  被找到。`/settings` 和 `/perf-profile` 现在也能从子文件夹工作。
- **设置值。** 手工编辑的本地 `platform.cert_tier` 不再
  覆盖锁定值，而无效的 `cert_tier` 或 `testing.strict`
  值会被视为未设置而不是被使用。在 Windows 上，锁定键提示
  不再以多余的回车符结束每个键，而含逗号的
  始终询问项不再被拆成两项。
- **提交检查能看到同一命令中 `git add` 暂存的文件**
  （`git add -A && git commit`），并且不再向 `design/gdd/` 中的
  `systems-index.md`、`game-concept.md` 及其他非系统文件
  索要 GDD 小节（#133）。
- **提交检查适用于位于更大仓库子文件夹中的项目。**
  位于更大仓库 `game/` 中的游戏过去在提交时得不到数据、GDD 或代码
  检查；暂存路径现在从项目文件夹读取。**用 Git LFS 存储的 JSON
  数据文件**会通过其工作副本检查，而不是
  被当作无效阻塞；没有工作副本的则被标记为跳过。
- **`/smoke-check` 不再在 Unreal 上无限等待。** 版本检查曾运行
  `UnrealEditor-Cmd -version`，它会打开编辑器且永不返回。它现在
  读取引擎的 `Build.version` 文件。
- **注册表查找。** `/design-system` 能找到引用它的其他系统
  实体；`/create-stories`、`/dev-story`
  和 `/story-done` 中的需求查找在被要求 `combat` 时不再匹配 `combat-ai`；
  文档中的被取代状态是合法 YAML；`/consistency-check` 和
  `/architecture-review` 在写入注册表前会重新读取它。你自己的
  注册表文件不会被更改。
- **`workflow: minimal` 下的下一步。** 13 个技能过去只把冲刺作为
  下一步；在 minimal 下它们现在点名任务书中的构建顺序。
  `gameplay-programmer` 在那里不再索取 ADR，而五个模板会在概念文档旁
  点名 `design/game-brief.md`。
- **`team-polish` 和 `team-ui` 在 `lean` 评阅模式下保留其核心成员。**
- **`/scope-check` 的判定区间不再重叠**，此前恰好会在 10% 和 25% 处重叠。
- **`/start` 只写入一个 `modes:` 块。** 它的严格度和自动化
  问题过去会各自添加一个。如果你的 `project.yaml` 有两个 `modes:` 块，
  请合并为一个。
- **每个技能都以标题开头。** 39 个技能没有顶层标题，而在
  `/architecture-decision` 中第一个标题是 ADR 模板的占位符
  （#83，由 @specterslient95-lgtm 报告）。
- **运行超过两分钟的设置行**会以任务通知的形式到达技能，
  而不是设置值；`config-resolution.md` 现在说明了该
  通知的含义以及应从哪里读取设置。
- **三项无需"May I write?"的写入**——智能体记忆、对
  `active.md` 的追加，以及智能体在其技能指定路径下的新文件——现在
  在 `CLAUDE.md` 中得到点名（此前一个都没点名），也在智能体记忆规则中
  得到点名（此前只点名了一个）。
- **文档已修正**：设置、工作流和协议文档、README、
  设置要求，以及 1.1.0 和 1.1.2 中关于默认权限模式覆盖范围的说明，
  还有 `/story-done`、工作流指南和 UPGRADING 中的三处夸大表述。

### 安全

- **随附的允许规则不再批准删除分支或不经询问写入文件。**
  有四条允许规则在其 `*` 前没有空格，因此会匹配命令名之后的任意文本：
  `git branch -D` 和 `-m`、带 `--output=<file>` 的 `git log`
  和 `git diff`，以及 `python -m json.tool <in> <out>`
  都会无提示运行，而在自动模式下允许规则还会跳过
  分类器。这些规则已被移除；`git status` 和 `git log` 等
  只读 git 命令仍会无提示运行。如果你合并过 `settings.json` 或
  把这些规则复制进了 `settings.local.json`，请参见
  [UPGRADING.md](UPGRADING.md#v112--v113)。
- **在项目根目录启动 Claude Code。** 它只会从启动所在的文件夹
  加载 `.claude/settings.json`，因此在 `src/` 或 `design/` 中启动的会话
  会在没有项目钩子、拒绝规则和先询问模式的情况下运行。README
  说明了这一点，而 Claude 现在会在从别处启动时发出警告。
- **`.env` 文件禁止 Edit。**

---

## [1.1.2] — 2026-09-29

**The default path works end to end, Unity and Unreal get the same care as
Godot, and the checks tell you what they found.** A fix release for bugs in
1.1.1, each reproduced before it was fixed.

**默认路径端到端可用，Unity 和 Unreal 得到与 Godot 同样的照顾，
而检查会告诉你它们发现了什么。** 一个针对 1.1.1 中缺陷的修复版本，
每个缺陷都在修复前得到复现。

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

### 默认路径（`rigor: minimal`）

- **`/help`、`/story-done` 和状态行会跟随你所在的路径。** 在 minimal 下
  没有任何东西运行 `/gate-check`，因此阶段从不移动。`/help` 曾把它读作
  概念阶段，于是向一个已有任务书和三个故事的项目索要概念文档、美术圣经和
  系统地图。它现在遵循 minimal 路线：引擎 → `design/game-brief.md` → 故事 →
  `/dev-story` ↔ `/story-done`。`/story-done` 会点名下一个故事，而不是打印冲刺收尾；
  状态行显示 `Minimal · 1/3 stories`。
- **不再有通向冲刺的死胡同。** `/sprint-status` 会按任务书的构建顺序报告进度，
  而不是拒绝。`/create-stories`、`/dev-story`、
  `/qa-plan`、`/smoke-check`、`/team-qa`、`/retrospective`、
  `/test-evidence-review` 及其他技能会提供 minimal 路线，而不是"运行
  `/sprint-plan`"。在 minimal 下，制作门禁要求任务书和故事，而不是冲刺计划。
- **默认值得到了正确陈述。** 约 25 处曾把 `standard` 的值说成默认值。
  默认值是 `minimal`，它带来 `coarse` 故事、`terse` 文档和 `solo` 评阅。
  当没有任何指向时，`/start` 推荐 `minimal`。
- **读取概念文档的技能也会读取任务书。** 十个技能和四个
  总监门禁在只有任务书的 minimal 项目上会警告"无游戏概念"或失败。
- **`/story-done` 在 `qa.level: minimal` 下仍检查截图。** 测试在那里被豁免；
  视觉/UI 截图不在豁免之列，但豁免曾同时覆盖两者。UI
  故事现在以保留的截图关闭，视觉/手感故事以截图加签核关闭，
  正如 `coding-standards.md` 所述——过去每个 UI 故事还需要证据文档和签核。
  `/create-stories` 写出的故事不再声称其视觉证据在 minimal 下被豁免。
- **你的进度会被保存。** `/dev-story` 和 `/story-done` 会更新
  `production/session-state/active.md` 中的检查点，下一个会话会把它展示给你，
  而不是追加无人读取的笔记。该检查点携带 `/dev-story` 的
  运行结果，由 `/story-done` 检查。
- **状态行统计正确的故事。** 在另一严格度下显式设置 `workflow: minimal`
  曾显示 Concept；"Not Done"曾被计为完成；加粗和
  项目符号形式的 Status 行曾被跳过；而在 `cd` 之后它会在错误的文件夹中寻找
  `project.yaml`。它现在每次渲染只查找一次 Python，而不是每读一个设置就查找一次。
- **每种故事状态都得到处理。** `/help`、`/story-done` 和 `/sprint-status`
  会路由 `In Review` 和 `Not Started` 故事，而 `/sprint-status` 会在
  构建顺序完成时说明。三者在顺序上一致：先关闭 `In Review` 故事，
  再继续一个 `In Progress` 故事，然后按构建顺序处理下一个 `Ready`
  或 `Not Started` 故事。新的
  `.claude/scripts/story-status.sh` 会在 `/help` 和 `/sprint-status` 运行前
  按该顺序列出故事，且只有 `Complete` 和 `Done` 故事
  才算完成。`/project-stage-detect` 不再向 minimal 项目索要
  冲刺计划，`/retrospective` 也不再在 `qa.level: minimal` 下把没有测试就关闭的故事
  记为你的问题。`/create-stories` 会追加到已完成的构建顺序，
  而不是从 `story-001` 重新开始；如果没有任务书则停止。
  `/brainstorm` 会询问故事验收标准所源自的玩家目标和失败状态，
  而制作门禁会说明其中哪些质量检查在 minimal 下适用。
- 各指南（WORKFLOW-GUIDE、quick-start、技能流程图）描述了
  minimal 路径，以及评阅模式的默认值：在 minimal 下没有总监评审。

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

### 引擎

- **Godot 测试可以运行。** `/setup-engine` 写出的测试命令会加载一个
  gdUnit4 从未发布过的 runner，因此每次运行都失败，无论测试是否通过。
  它现在是 gdUnit4 自己的 runner，并带有阻止脚本错误
  在 `debug>` 提示处挂起运行的标志。找不到测试的运行是 NOT ASSESSED，而不是
  通过。`/dev-story` 的解析检查在解析错误时曾以 0 退出；它现在用
  `.claude/scripts/godot-parse-check.gd` 加载每个更改过的脚本，该脚本也接受
  使用 autoload 的代码。`/smoke-check` 在测试前导入项目：在全新克隆、
  没有类缓存时，gdUnit4 的 runner 不会加载，
  运行会以 1 退出且无判定。
- **Unity 测试可以编译。** 它们过去放在 `tests/` 下，而 Unity 从不编译该目录，
  因此运行会报告"0 tests, Passed"。它们现在放在 `Assets/Tests/` 下。
  构建命令会构建玩家版本，而冒烟命令不再调用无人创建的
  `SmokeCheck.Run`。命令用完整路径点名编辑器：裸 `Unity` 可能是 Unity
  独立的 CLI，它会以测试失败的退出码失败。编译错误是 FAIL，
  上一次运行的结果文件不再被当作本次运行的。项目一致性检查会从
  `commands.test` 找到编辑器，并把 `6000.3` 和 `6.3` 读作同一个 Unity，
  因此正确设置的​​项目不再报告版本不同。
- **Unreal 测试可以编译并被找到。** `qa-tester` 模板曾使用一个
  并不存在的标志，且测试放在 `Source/Tests/` 下，而该目录从不被构建。
  CI 和 `/smoke-check` 会先构建编辑器目标：全新检出没有
  已编译的游戏模块，编辑器会在运行测试前退出。CI
  模板要求 Windows 自托管 runner；它过去要求任意自托管
  runner，因此带 Linux runner 的仓库可能把任务发到那里。它的步骤
  在 runner 文件夹含空格时也会运行，而此前这会让每一步都失败。测试
  命令会打印其结果——从 shell 运行时，编辑器不打印任何内容，因此
  无法把"没有匹配的测试"与失败区分开。每个 Unreal 命令
  都用完整路径点名编辑器，并以绝对路径给出项目：
  UE 5.7 找不到相对路径的 `.uproject`，因此测试、运行和冒烟
  命令在做事之前就会以 1 退出。失败的测试和没有匹配任何内容的运行
  都以 255 退出，因此 `/smoke-check` 现在读取输出来区分它们。
- **`/smoke-check` 先运行你的测试**，并在什么都没运行时
  报告 NOT ASSESSED 而不是通过。在 `qa.level: minimal` 下测试被豁免，
  没有游戏测试的项目改由其构建、启动和关键路径
  检查，因此打磨和发布门禁可以在默认严格度下通过。构建检查
  在设置时运行 `commands.smoke`（否则 `commands.build`），而本会话
  无人启动的构建是 NOT ASSESSED——它可能在什么都没运行时通过。
- **Godot 命令会点名编辑器。** `/setup-engine` 曾把裸 `godot` 写入
  `commands.*`，即使它说明 Godot 不在 `PATH` 上（Windows、macOS）；它现在
  写出编辑器带引号的完整路径，并记录为 `engine.path`。
  `/smoke-check` 和 `/dev-story` 的解析检查会从
  `commands.test`、然后 `engine.path`、然后 `PATH` 找到编辑器，并在都找不到时说明。
  `/smoke-check` 需要的标志或路径会为该次运行添加并报告，绝不
  写入 `commands.test`。项目一致性检查以同样方式找到 Godot
  编辑器——它曾在正确的项目上报告"no Godot binary"——
  并在 macOS 和 Linux 以及 Windows 上查找 Unity Hub 的编辑器。
  [UPGRADING.md](UPGRADING.md#v111--v112) 说明了如何更新 1.1.x 项目。
- **引擎技能会读取各引擎自己的输出。** `/test-flakiness` 曾查找
  `Result: Success`，而 Unreal 从不打印它，并以
  JUnit 模式读取 Unity 结果，因此每个测试都被读作一致的；它现在读取 Unreal 的
  `Result={…}`、Unity 的 NUnit `<test-case>` 结果和 gdUnit4 的 `reports/`
 文件夹。`/test-helpers` 的 Godot 信号断言过去永远看不到信号；它们
  现在把信号记录到 Dictionary 中。`/content-audit` 在 Unity 上扫描 `Assets/`，
  此前它在那里根本找不到内容。Godot 和 Unity 参考新增了有来源的
  命令行小节（runner 标志和退出码）；Unity 参考说明
  `RecordRenderGraph` 属于 URP，并记录了 HDRP 的 `CustomPass`，而
  `unity-shader-specialist` 不再把 URP 的那一套套用到 HDRP。
  `godot-csharp-specialist` 使用 `[Export(PropertyHint.Range, …)]`——不存在
  `[ExportRange]`——而 `ue-gas-specialist` 和 GAS 参考点名了
  基值钳制钩子。Unreal 测试名称遵循根 `commands.test` 所过滤的规则。
- **Unity 和 Unreal 获得 Godot 所拥有的规则和检查。** 针对
  玩法、引擎、AI、网络、UI、着色器、数据和测试代码的编码规则现在会在
  `Assets/` 和 `Source/` 项目中加载。`Assets/**/Data/` 和
  `Content/**/Data/` 中损坏的数据 JSON 会被捕获，PascalCase 资产不再被标记，
  数据文件规则只适用于 JSON（不适用于 `Data/` 文件夹中的 C# 或 C++），
  测试规则按各引擎语言的惯例命名测试，
  `/tech-debt`、`/launch-checklist` 和 `/release-checklist` 不再报告"no
  `src/`"，状态行能到达 Production，会话启动不再读取
  每个纹理来寻找 TODO。Unity 和 Unreal 代码规则只在代码
  文件上加载，而着色器、玩法和引擎规则给出了全部
  三个引擎的示例。技能示例、模板和规则参考现在点名各
  引擎的代码文件夹，而不仅是 Godot 的 `src/`；指南中的
  `/localize` 和 `/reverse-document` 示例也换成了可运行的。
- **测试结果名副其实。** 每个 gdUnit4 退出码都映射到判定——
  101（所有测试通过、有节点泄漏）是警告，不是失败。Godot
  CI 模板运行你仓库中的 gdUnit4，而不是用最新发布替换它，
  并要求完整的 Godot 版本。Unity 指引覆盖了
  程序集定义所需的包引用和 `Editor/` 文件夹，`qa-tester` Unity 模板可以编译，
  测试输出被 git 忽略。Godot CI 模板要求 `checks: write`：没有它，任务会在每个新
  仓库上失败，即使所有测试都通过。如果你保护 `main`，请要求
  任务的检查，而不是 `test-results`，因为后者在测试失败时也会通过。`qa-tester` Unreal 模板
  按填写内容即可编译，并给每个测试自己的类——两个共享一个类的测试
  会链接失败——而 Godot 模板会释放其对象。
- **引擎参考修正。** Godot 的 `@abstract` 示例给抽象
  方法加了方法体，无法解析；4.4 的 `Texture2D` → `Texture` 说明现在
  点名它所适用的 `Shader` 默认纹理方法，而不是着色
  语言。Unreal 的服务器 RPC 示例声明了 `WithValidation`，其
  `_Validate` 函数需要它。Unity Addressables 迁移示例保留了其
  句柄并释放它。`godot-gdextension-specialist` 把兼容方向弄反了：
  为较旧 Godot 构建的扩展会在较新版本中加载，而不是相反。
- **Linux 和 macOS 上的 Unreal。** Unreal 命令过去只点名 Windows 路径。
  `/setup-engine` 现在在 Linux 上写出 Linux 命令（`RunUAT.sh`、
  `Engine/Binaries/Linux/UnrealEditor`），而 `/smoke-check`、`/dev-story` 和
  `/test-setup` 在那里用 `Build.sh` 构建编辑器目标；在 macOS 上它只写出
  构建命令，把测试、运行和冒烟留给你设置，因为 Epic 没有记录
  `UnrealEditor.app` 内的命令行编辑器。`/smoke-check` 会为运行所在的机器挑选
  命令，并在 `commands.test` 设置前对 macOS 上的 Unreal 测试报告 NOT ASSESSED。
  来源在 `docs/engine-reference/unreal/current-best-practices.md`。

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

### 检查与钩子

- **你能看到警告了。** 提交、推送、资产和技能编辑检查把警告打印在你和 Claude 都看不到的地方。现在它们会显示在你的终端里，也能传达给 Claude。它们绝不会替你批准任何事。
- **提交检查覆盖链式命令。** `git add -A && git commit`、`git -C . commit`、`git -C "a path with spaces" commit`、`if git commit`、`{ git commit; }`、`/usr/bin/git`、`git.exe`、`env X=y git commit`、写在第二行的提交，以及通过 PowerShell 工具执行的提交，全都跳过了它，而在 macOS 上所有链式写法都会被跳过。同样被跳过的还有 `bash -c "git commit"`、`sudo` 和 `xargs git commit`、`git --git-dir .git commit`，以及用引号或 Windows 路径指名的 git（`& "C:\Program Files\Git\cmd\git.exe" commit`），还有在未安装 `jq` 时任何包含 emoji 的命令。在有数据文件暂存、却没有 Python 可供检查它们时——包括 Windows Store 的 `python` 占位符（检查此前会把它误认为 Python）——它现在会拦截并说明原因。当该占位符排在 `PATH` 首位时，资产检查不再把有效的 JSON 判为无效。
- **Here-doc 中的文本不是命令。** 通过 here-doc 写入的提交信息即使提到 `git push`，也不再触发推送警告；通过 here-doc 写文档即使提到 `git commit`，也不再运行可能阻挠它的提交检查。其他被引用的文本（`echo "git commit"`）仍会被检查。制表符缩进的 `<<-EOF`、使用 CRLF 换行的 here-doc 以及 `/bin/bash <<EOF` 现在也能被正确读取。
- **提交检查读取的是你实际提交的内容。** 它校验每个数据文件的暂存副本，而不是磁盘上的那一份；检查 `git commit <path>` 实际纳入的文件，无论路径规格写成什么（`.`、某个文件夹、通配符、`:/`），不再把 `-F` 指定的信息文件误认为是其中之一；同时检查 `.JSON` 和 `.json`；不再跳过文件名包含非 ASCII 字符的数据文件；并以与资产检查相同的方式判断 UTF-8 BOM。当 refspec 指向受保护分支时，推送警告也会触发（`HEAD:main`、`+main`、`refs/heads/main`）。对于未提及 git 的命令，提交检查和推送检查现在会立即退出（约 116 ms，而不是约 350 ms）。
- **危险命令在 PowerShell 中同样被拒绝。** 针对强制推送、`reset --hard`、`clean -f`、递归删除和读取 `.env` 的拒绝规则此前只覆盖 Bash 工具。现在它们也覆盖 PowerShell 工具，并且包括 `git push origin main --force` 与 `git push --force`——还有此前只会弹出提示的 `rm -fr`、`git clean -df`、`+main` refspec、`git -C . push --force` 和 `Remove-Item -r`。
- **会话启动会把关键内容留在屏幕上。** 过长的检查点会被截断为 25 行并附注说明，警告则打印在它之前，因为超过 10,000 字符的钩子输出传达到 Claude 时只会变成 2,000 字符的预览。在 minimal 模式下，它不再提示你运行 `/gate-check`，并且会从 `project.yaml` 读取阶段——这是它此前从未做过的事。对于一个 `project.name` 只有一个单词的正确项目，它不再误报引擎参考不匹配：它把那一行当成了引擎。
- **在 macOS 上计数打印整齐。** BSD 的 `wc` 会给数字补空格，因此会话启动曾显示 `Code health:        2 TODOs`，压缩钩子曾显示 `(      35 lines)`。
- **分区评审绝不会跳过被编辑过的分区。** `/design-review` 和 `/architecture-review` 背后的变更检查此前只用 `git` 或 `sha1sum` 计算哈希。现在它还会使用每台 Mac 都有的 `shasum`；而在完全没有哈希工具时，它会把每个分区都报告为已变更，并在 stderr 上说明原因——此前它会把已编辑的分区报告为未变更。
- 压缩钩子不再声称其输出能传达给 Claude；在一次压缩之后，恢复你所在位置的是会话启动。智能体日志不再把 Claude Code 自身的内部智能体（提示建议、`/btw`）记录为未知智能体。
- **更少的 git 调用方式会跳过提交检查。** 带引号的选项值（`git -c user.name="A B" commit`、`--git-dir=".git"`、`-C "$(pwd)"`）、git 前面的 `timeout` 和 `nice`、放在信息之后的 `-a`（`-m "x" -a`、`--all`），以及 `cd` 之后的相对路径（`cd assets && git commit -m x data/item.json`），都曾让提交未经检查地通过。钩子无法解析的 `-C` 目录（`"$CLAUDE_PROJECT_DIR"`、`~/x`）现在会被检查而不是跳过；只有发生在其他仓库中的提交才不予理会。仅针对具名路径的提交（`git commit -m x src/player.gd`）不再因为另一个无关的损坏文件被暂存以备后用而被拦截，重定向（`2>&1`、`> out.log`）也不会被当作路径读取。任意大小写的 `Git` 或 `GIT`、带引号的 `"git"`、位于其前的 `stdbuf`、`winpty` 或 `command -p`，以及写在反斜杠续行上的提交，现在都会被检查；链条中较早出现的 `git -C <other repo> commit` 不再让本仓库后续的提交蒙混过关；PowerShell `@'…'@` 字符串中的文本也不会被当作命令读取。
- **推送警告会列出你所保护的分支。** 它会在 `main`、`master` 和 `release/*` 上发出警告——短期发布分支正是稳定一次发布的地方——而不再对 `develop` 警告，因为主干开发并没有这个分支。它会检查链条中的每一次推送，而不仅是第一次，并能读取带引号的分支名或 refspec。
- **`PATH` 上的 Python 2 不再让有效的数据文件失败**，并且在没有 Python 3 时，GDD 分区检查会说明它没有运行，而不是静默通过。
- **更多危险命令的写法会被拒绝**：带 `--recursive` 和 `--force` 的 `rm`，以及在子命令前带 git 选项的强制推送、`clean -f` 和 `reset --hard`。`git` 规则会匹配 `git` 之后的任何位置，因此只要 git 命令的文本符合其中一条，即使实际没有执行任何危险操作也会被拒绝——例如提到其中之一的提交信息，或诸如 `git commit -m "push + pull"` 这样的普通文字；请改写该信息。`git clean -fn` 也会被拒绝；试运行请写成 `git clean -n`。
- **较小的修复。** 状态行会把状态读作 `Done.` 或 `Complete, verified` 的故事计为已完成，与 `/sprint-status` 的做法一致。技能编辑提醒不再为项目之外的技能触发，例如你自己的 `~/.claude/skills/`。`/help` 现在只会在 `technical-preferences.md` 中查找引擎设置。在 Windows 和 macOS 上，包含 `src/` 和 `assets/` 的 Godot 项目能找到其代码根目录——此前 Godot 的 `assets/` 被当作 Unity 的 `Assets/` 读取。当不存在 `project.yaml` 时，会话启动会把 `solo` 显示为评审模式，这正是技能所使用的值。

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

### 技能与文档

- **技能会读取完整参数。** `/scope-check inventory crafting system` 此前只检查 `inventory`，而 `/gate-check --review full` 把 `--review` 当成了阶段名。有七个技能只读第一个词；现在它们会读取全部内容。
- **`/design-review --depth` 重新可用**——它在 1.1.0 中被改名为 `--review`，旧写法被静默忽略了。
- **简报中新增 Reference game 行**——也就是你的游戏最接近的已发行作品，以及你的 MVP 从中保留的部分。`/brainstorm` 会询问它。
- **`/start` 能识别仍指向本仓库的克隆**，并建议重命名 `origin`，让你的推送和拉取请求进入你自己的游戏仓库——在所有路径上都会如此，包括回访用户的路径，且对自己的 fork 不适用。
- **技能只预批准它们实际运行的命令。** `/help`、`/scope-check`、`/asset-audit`、`/project-stage-detect` 和 `/reverse-document` 此前在活动期间允许任意 shell 命令；现在每个技能都会列出自己的命令。`/prototype` 和 `/vertical-slice` 不再声称拥有技能根本无法获得的工作树隔离，`/design-review` 也说明了同时给出 `--depth` 和 `--review` 时哪个标志优先。`/help` 接受其唯一脚本的带引号写法（此前约有一半情况会被拒绝），并且该脚本在设置了 `MSYS_NO_PATHCONV` 时不再失败。
- **技能模型锁定按实际行为记录。** 你以 `/skill-name` 键入的技能会运行在它声明的模型上，但自动模式会忽略 Haiku 锁定。由 Claude 自行启动的技能运行在当前会话的模型上。因此，声明 Opus 的 `/gate-check`、`/architecture-review` 和 `/review-all-gdds` 在 Sonnet 会话中键入时费用更高。此前的文档曾说锁定从不生效。
- **智能体模型的记录与其实际运行一致**，并附上那行修复「被锁定智能体在大上下文会话中溢出」问题的设置（[#67](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/67)）。
- **智能体规格可以运行了，而且与智能体相符。** `/skill-test spec` 和 `/skill-test category` 此前只在 `.claude/skills/` 中查找，因此测试框架中的每个智能体规格都被判为未找到；现在两者都接受智能体名称。这些规格曾声明没有任何智能体使用的模型（49 个中有 36 个——三位总监和 `lead-programmer` 写对了层级，但用了完整模型 ID），还检查 `allowed-tools:`——那是技能字段，智能体并没有。现在每个规格都断言其智能体自己的 `model:` 和 `tools:`。
  层级以 `model:` 接受的别名书写——`opus`、`sonnet`、`haiku`、`inherit`——绝不写成模型 ID，因此新模型发布后它们依然正确；智能体名册和门禁索引不再重复这些内容（[#131](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/131)）。
- **`devops-engineer` 和 `community-manager` 改为运行在 Sonnet 上。** 它们此前是仅有的被锁定到 Haiku 的智能体，而 `model-tiers.md` 把该层级保留给只读查询和格式化。一个负责构建你的 CI 流水线，另一个撰写玩家会读的内容——这正是 `/patch-notes` 使用 Sonnet 的那份判断力所需。
- **每个行为规格都按技能或智能体的当前形态来描述。** 一次完整的 `/skill-test spec` 运行让测试框架中的全部 121 个规格都失败了。多数规格是针对旧版本写的，期望了技能和智能体并不具备的判决词、路径和功能——`/help` 的规格期望「HELP COMPLETE」，而该技能从未用过这个词。现在每个规格都按其当前的技能或智能体重写，每个用例仍测试具体行为。`/skill-test` 现在按智能体实际能看到的内容来评判：它自己的文件、`CLAUDE.md` 及其导入的文件、门禁用例对应的门禁定义，以及它预加载的任何技能。每个智能体都会收到的规则（例如把冲突上报给共同的父级）不再被逐一报告为缺失。
- **总监按每个门禁自己的措辞作答。** 四位总监此前被告知对每个门禁都回答 APPROVE / CONCERNS / REJECT（制作人是 REALISTIC / CONCERNS / UNREALISTIC），但有八个门禁定义了自己的判决——`PR-MILESTONE` 是 ON TRACK / AT RISK / OFF TRACK，`TD-FEASIBILITY` 是 VIABLE / CONCERNS / HIGH RISK，`PR-SCOPE` 是 REALISTIC / OPTIMISTIC / UNREALISTIC，`AD-CONCEPT-VISUAL` 是 CONCEPTS / STRONG / CONCERNS，每个阶段门禁是 READY / CONCERNS / NOT READY——而技能会依据这些词行动，因此 `/milestone-review` 此前永远看不到 OFF TRACK，也就无法拒绝 GO。现在每位总监都从门禁的定义文件中读取判决词。`/map-systems` 和 `/brainstorm` 会处理 PR-SCOPE 的 OPTIMISTIC，这是它们此前从未预料到的。
- **智能体只预加载它们能运行的技能。** `game-designer` 和 `creative-director` 此前预加载了 `/design-review` 和 `/brainstorm`，而它们需要这两个智能体并不具备的工具；`producer` 还预加载了为门禁生成它自己的那些技能。这些预加载已移除。
- **Unity 和 Unreal 智能体在建议 API 之前会检查其引擎参考**，正如 Godot 智能体早已做的那样；当锁定值为 `NOT DETERMINED` 时，每个引擎智能体都会询问已安装哪个编辑器。`godot-specialist` 不再要求自己使用 WebSearch——它并没有这个工具。
- **不写代码的智能体不再遵循程序员的流程。** `qa-lead`、`sound-designer`、`writer`、`performance-analyst`、`community-manager`、`release-manager`、`analytics-engineer` 和 `localization-lead` 此前会问「静态工具类还是场景节点？」，并主动提出写测试；现在每个都先起草、提案，并在写入前询问。
- **`security-engineer` 按 `/security-audit` 的量表评定发现**——CRITICAL / HIGH / MEDIUM / LOW，多人游戏中 HIGH 视同 CRITICAL——即使你直接询问它，而不仅是在审计内部。
- **智能体会在工作交汇处点名彼此**：`network-programmer` 与 `security-engineer`、`writer` 与 `world-builder`、`art-director` 与 `audio-director`、`ux-designer` 与 `accessibility-specialist`，等等。`live-ops-designer` 把定价交给 `economy-designer`，正如 `/team-live-ops` 早已如此；带有内置预算（延迟、带宽）的智能体在项目给出数值时会采用项目的数值。
- **`devops-engineer` 遵循主干开发。** 它此前规定 GitFlow——长期存在的 `develop` 分支及其分出的功能分支——而 CLAUDE.md 设定的是主干开发。现在它描述的是 `/team-release` 和 `/hotfix` 也在使用的主干流程：从 `main` 分出的短期分支、在 `main` 上打发布标签、仅为稳定发布而设的发布分支。`release-manager` 和 `/hotfix` 把修复合并回 `main` 而不是某个「开发分支」，`hooks-reference/` 中的两个钩子示例也不再假定 `develop`。
- **总监的记忆留在项目中。** `creative-director`、`producer` 和 `technical-director` 此前把记忆保存在你的主目录中，与机器上每个项目共享。与其他 14 个智能体一样，现在它们把它保存在项目内被 gitignore 的 `.claude/agent-memory/` 中。主目录中已有的笔记不会被迁移——[UPGRADING.md](UPGRADING.md#v111--v112) 说明了如何保留它们。
- **Python 3 和 Bash 被列为必需项**——每个技能都通过 Python 读取 `project.yaml`，每个钩子都在 Bash 中运行。安装步骤以 Claude Code 的原生安装器开头，并点明了 VS Code 扩展自己的权限设置；已过时的计数、链接和示例都已更正。
- **引擎命令说明了在 Mac 上如何运行。** `/smoke-check` 会把每次引擎运行包在 `timeout` 中，而 macOS 没有这个命令；现在它点出 `gtimeout`（Homebrew `coreutils`）以及一种无需安装任何东西的 `perl` 写法。`/setup-engine` 也说明在 macOS 上 `PATH` 中没有引擎，并指出应用包内的 Godot 二进制路径，让 `commands.*` 得到一条可运行的路径。
- **参考文档与 Claude Code 2.1.282 保持一致**：钩子 schema（10,000 字符输出上限、SessionStart 的 `fork` 来源、所有 exit-2 事件）、影响图、上下文窗口、总监门禁模型层级，以及内置的评审命令（`/review`）。
- **Proposed 状态的 ADR 再次会阻挡故事。** 在 1.1.0 中 `/dev-story` 不再读取 ADR 的状态，于是基于未被接受的决策而构建的故事照常推进。现在它会停下，并提示你用 `/architecture-decision accept` 接受该 ADR。`/create-stories` 会读取它用来标记故事为 Blocked 的状态，并在你指定的史诗不存在时停下；`/story-readiness` 在每个 `workflow` 层级都会把 Proposed 或缺失的 ADR 报告为 BLOCKED，正如 `/dev-story` 会因此停下。接受 ADR 时会保留其 `## Date`：此前改写它会让所有针对该 Proposed ADR 起草的故事在 `/dev-story` 看来已过期。
- **`/architecture-review` 会在门禁读取的位置写入可追溯性索引**，即 `docs/architecture/requirements-traceability.md`。它此前没有指定任何路径，因此在 `rtm` 模式之外，Pre-Production 门禁找不到该文件。
- **统一的证据规则，处处一致。** `/test-evidence-review`、`/qa-plan`、证据模板和影响图现在与 `/story-done` 一致：UI 故事凭保留的截图关闭，Visual/Feel 故事凭截图与签核关闭，任何 `qa.level` 都不能豁免这两者。`/test-evidence-review` 会先检查故事点名的证据路径再作猜测，会查看各引擎的测试文件夹，并且不再要求 UI 故事提供三次签核和一次走查。`/test-setup` 会创建 `production/qa/evidence/`，`/smoke-check` 只统计你的引擎测试运行器能运行的文件。
- **统一的缺陷严重度量表。** `/bug-report` 此前使用 S2-Major、S3-Minor 和 S4-Trivial，而 `/bug-triage` 并不读这些；`/hotfix` 还把带有规避方案的缺陷称为 S2，而分诊称其为 S3。`/bug-report`、`/hotfix`、`qa-lead`、发布与上线检查清单以及事件模板现在统一使用 S1 Critical / S2 High / S3 Medium / S4 Low。`/bug-report` 给新缺陷编号时会取现有最大 ID 加一，`/team-qa` 也以同样方式归档缺陷——`BUG-0001.md`，而它此前写的是 `BUG-001-[slug].md`——这样 `/bug-report verify` 和 `close` 就能按编号找到任何缺陷，包括较早的缺陷。
- **总监评审交给门禁点名的总监，且只在运行它们的模式下进行。** `/art-bible` 此前把评审发给 `creative-director` 而不是 `art-director`，`/create-architecture` 在每种模式下都自行评审其架构，而不是启动 `technical-director`。被否决的架构不再能被接受。`/create-control-manifest` 和 `/propagate-design-change` 会读取它们所依据的评审模式；`/architecture-decision` 会说明它实际启动的评审者；`/team-narrative` 在团队中有 `narrative-director` 时，会在每种评审模式下运行其叙事一致性评审，没有时也会说明。
- **`/gate-check` 可以在 `standard` 下通过。** 它在收窄评审小组后仍要求「全部四位总监」READY，并且在进入 Systems Design 时建议 `/create-architecture` 而不是 `/map-systems`。`/map-systems` 在跳过评审时不再跳过其判决和会话保存。
- **每种判决都有表达「无法检查」的用词。** `/release-checklist`、`/regression-suite`、`/consistency-check`（注册表为空、注册表中没有该名称，或范围内没有 GDD 时）、`/content-audit`、`/story-readiness` 和 `/tech-debt`（没有登记簿时）会报告 NOT ASSESSED 而不是通过；`/prototype` 对无人试玩过的原型建议 NOT ASSESSED。在 `/team-qa` 中，未关闭的 S1 或 S2 缺陷意味着 NOT APPROVED，即使其他证据缺失；此前它会被读作 NOT ASSESSED。`/security-audit` 的 FIX CRITICALS FIRST 现在是 **FIX BEFORE SHIPPING**——存在未关闭的 HIGH 发现、但没有 CRITICAL——并附有选择每种判决的规则。`/qa-plan`、`/bug-triage`、`/perf-profile` 和 `/story-done`（针对延期的验收标准）始终以判决结尾，`/code-review`、`/asset-audit` 和 `/review-all-gdds` 各自使用统一的判决量表。

- **团队技能会生成它们用到的每一个智能体。** `/team-audio`、`/team-level`、`/team-release` 和 `/team-live-ops` 中的每个 `team.size` 组合现在都包含其自身步骤所调用的智能体，而此前这些智能体从未被生成。`/team-narrative` 在 `production/narrative/` 中起草，并在把终稿写入 `design/narrative/` 之前询问一次。`/team-combat` 会在未设置引擎时说明，`/team-level` 和 `/team-ui` 在未给参数时显示用法。在 `team.size: studio` 下，`/team-combat`、`/team-ui` 和 `/team-polish` 中的「对抗式评审轮」现在有了定义——该阶段的评审者被告知要找出工作如何会崩坏，报告也会说明该轮已运行——并且从 `/team-audio`、`/team-polish`、`/team-narrative` 和 `/team-live-ops` 中移除了没有任何步骤定义的额外项。`/team-narrative` 在 `small` 下只有在 `review_mode: full` 时才加入其设定与本地化智能体。
- **技能在写入前询问，并且写它们所说的内容。** `/dev-story`、`/sprint-plan`、`/patch-notes`、`/localize` 和 `/adopt` 此前不询问就写文件，或写入的问题并未点名的文件。`/create-architecture` 只在最后写一次。`/perf-profile` 可以保存它提供的报告，`/tech-debt` 不再追加登记簿中已有的债务项，`/consistency-check` 不再主动提出保存一份它并没有路径可写的报告。
- **`/skill-improve` 不再丢弃你未提交的编辑。** 它此前用 `git checkout` 还原被否决的变更，从而丢掉自你上次提交以来对该技能的所有编辑；现在它会恢复自己保存的副本。
- **测试辅助代码在 Unity 和 Unreal 上可以编译。** `/test-helpers` 此前把它们放在 `tests/helpers/` 下，而这两个引擎都不会构建该目录；现在它们会放到各引擎的测试文件夹中，Godot 的场景辅助代码也不再继承测试套件。`/test-flakiness` 依据各测试框架自己的文档点名隔离机制，并说明 Unreal 的机制未被覆盖。
- **模板与技能写入的内容一致。** 逆向文档的 GDD 模板包含全部八个标准分区。美术圣经模板的分区集合与 `/art-bible` 写入的九个分区不同；现在它包含这九个分区，`/art-bible` 也据此创建文件。`/ux-design` 的 HUD 规格包含 `/ux-review` 检查的分区，因此 HUD 规格现在可以获批，此外还包含其模板一直都有的 Information Hierarchy 和 Acceptance Criteria；UX 规格则新增了输入方式检查清单和 `/ux-review` 要求的 Platform Target 行。模板与技能使用相同的分区名，`/art-bible` 和 `/ux-design` 也按这些名称列出现有文档的分区。
- **`/create-epics` 在 `minimal` 下可用**，从简报构建史诗，而不是为 GDD 停下。`/setup-engine` 会询问一个 Unreal 项目的玩法主要写在 C++ 还是 Blueprints 中；其他技能修好了更小的死胡同：没有角色的 `/onboard`、没有参数的 `/playtest-report`、`/hotfix` 中失败的冒烟测试，以及指向只读 `/sprint-status` 的 `/retrospective`。
- **总监可以表示他们无法判断。** 总监门禁现在可以回答 NOT ASSESSED，并点明它没有获得的输入，而不是挑一个信心十足的词；每个生成总监的技能都会把它当作「未获批准」，并说明缺少了什么。「修订被标记项」现在意味着由专家重新起草该分区，并在写入前由你再次批准。
- **`/sprint-plan` 不再设置你的评审模式。** 在项目的第一个 `new` 冲刺中，它此前会询问评审深度并写入 `project.yaml` 和 `production/review-mode.txt`，永久覆盖 `modes.rigor`。现在它使用已解析的模式；当你确实想改时可用 `/settings`。它还会在上一冲刺之后为新冲刺编号，并把未完成的故事结转过来。
- **在空集上也能通过的检查，现在会如实说明。** `/asset-audit` 曾在扫描到零个资产时报告 COMPLIANT——在每个 Unreal 项目上都是如此，因为其资产放在 `Content/` 中；`/balance-check` 曾在没有可比对目标时报告 HEALTHY；`/code-review` 曾在引擎评审从未运行时报告 APPROVED。现在这些都会报告 NOT ASSESSED；`/launch-checklist`、`/team-polish`、`/localize qa` 和 `/project-stage-detect` 在无法检查时也会如此。`/security-audit` 的 FIX BEFORE SHIPPING 现在优先于 NOT ASSESSED，因此未关闭的 HIGH 发现绝不会被它无法扫描的分类所掩盖。
- **发布门禁会检查安全与本地化。** `/gate-check release` 会读取最新的 `/security-audit`（在 `standard` 和 `full` 下，未关闭的 CRITICAL 或 HIGH 会阻断）以及每个语言区域的 `/localize qa` 结果（在 `full` 下为必需），并按层级点名会阻断的缺陷严重度（`full` 下为 S1–S3，以下为 S1）。这是一个就绪门禁，在发布前运行：发布检查清单、更新日志、安全审计和本地化检查现在在 `/help` 和工作流指南中都归入 Polish 阶段，`/team-release` 也预期阶段已读作 `Release`。
- **发布与热修在所有地方都基于主干。** `/team-release` 在 `main` 上打标签，仅为稳定发布而开发布分支；`/hotfix` 从发布标签开始并合并回 `main`。`/team-release` 让 `release-manager` 撰写补丁说明——`community-manager` 没有可运行 `/patch-notes` 的 shell——再由 `community-manager` 据此撰写公告。
- **指南点名了正确的门禁。** 工作流指南把每个阶段门禁都晚写了一个阶段，并展示了一个并不存在的 `/gate-check concept`；`/design-system`、`/map-systems` 和系统索引模板在你的 GDD 完成后会把你引向错误的门禁。在所有地方，`/gate-check` 的参数都是你正在进入的阶段。
- **更多在写入前询问。** `/start` 在写 `project.yaml` 前询问；`/dev-story` 在把故事标记为 In Progress 前询问；`/team-combat` 在询问后才撰写 GDD 本身；九个设计智能体在创建骨架文件前询问；`/create-architecture` 不再覆盖已有的架构文档，其聚焦运行现在会保存自己的分区。
- **默认路径，更多内容。** `/help` 在 `minimal` 下会读取你的检查点，因此它在 `/dev-story` 之后建议 `/story-done` 而不是再来一次 `/dev-story`；`/quick-design` 可以仅凭简报和故事，在尚无 GDD 的系统上工作；`/qa-plan`、`/story-readiness`、`/dev-story` 和 `/team-qa` 在 `qa.level: minimal` 下不再豁免 UI 故事的截图。
- **智能体。** `accessibility-specialist` 改为起草发现，而不是遵循程序员的流程；`security-engineer` 按 `/security-audit` 的格式报告；`godot-specialist`、`unity-specialist` 和 `unreal-specialist` 会在请求属于其他引擎时说明；还有数十个智能体写明了其规格期望、但其文件此前只作暗示的规则。一个用 `#` 注释的 `.gdextension` 示例吞掉了它的 `[libraries]` 分区——ConfigFile 的注释以 `;` 开头。
- **可能误导的判决与记录。** `/security-audit` 此前会让一个无法扫描的分类用 NOT ASSESSED 取代 FIX BEFORE SHIPPING；现在已知的 HIGH 会起决定作用。它还会说明 `security-engineer` 未被生成。`/team-qa` 不再记录测试者并未给出的手动 QA 结果，其 qa-lead 会起草签核供你批准，而不是先行写入。`/bug-report verify` 在相关测试未运行时说明 CANNOT VERIFY，并且绝不会把电子邮件地址写进缺陷。`/consistency-check` 在 `standard` 下只比较必需分区。`/create-architecture` 在单分区更新后也会运行其总监评审。`/dev-story` 和 `/create-stories` 能一步读取 ADR 的状态，即使每个标题下都有一行空行。随附的 `.gitignore` 不再排除 gdUnit4 的测试运行器（`addons/gdUnit4/bin/`），`/team-narrative` 也会在任何智能体起草之前读取项目的既有设定。
- **团队技能在智能体写代码之前会询问。** `/team-combat`、`/team-audio`、`/team-ui` 和 `/team-polish` 此前让它们的智能体像写草稿一样写代码、着色器和音频文件，却不询问；现在每个智能体都会列出它将创建或修改的文件，技能则针对该文件集合询问一次。`security-engineer` 在 `/security-audit` 中评定自己的发现，审计无法扫描的分类绝不会被报告为已评审。在 `/gate-check` 中，对手动检查回答「否」会让该项失败，而不是保持未检查。`/skill-test` 的分类模式会说明它在何时给出哪种判决，`/patch-notes` 把其分类映射到你模板的分区上，`/create-control-manifest` 会点明每条命名与预算规则的来源。
- **交接会点名下一个门禁要读取的每一步。** `/create-architecture` 的交接现在会列出 `/architecture-review`（`/gate-check pre-production` 要求它）和 `/create-control-manifest`。`/team-combat` 按 `modes.workflow` 决定其设计文档的规模，与 `/design-system` 一致——全部八个分区仅在 `full` 下必需，`minimal` 下可选——并从 GDD 模板起步，包含 `## Summary`。`/brainstorm` 在修改制作人认为不现实的范围内之前会询问，被阻塞智能体的报告会点明缺少什么以及它本应在何处。`/create-architecture` 会像对待其他每个分区一样请你批准其 API 边界，`/review-all-gdds` 会报告它评审了现有 GDD 中的多少份并点名无法读取的，`/team-live-ops` 不再在你批准主题之前启动经济设计，并说明当伦理标记阻断计划时该怎么做，`/team-release` 则把其 48 小时观察保留在发布后阶段。
- **`/gate-check` 会让准备就绪的项目通过。** 总监们此前对后续阶段才做的工作——Pre-Production 之前的架构、Production 之前的冲刺计划——被告知「none」，并把它读作缺失；现在改为传入「not expected before [phase]」。四项阶段门禁评审会针对进入阶段所需的、你所在层级要求的产物，判断准备情况。在 CONCERNS 下，你可以通过接受所列风险来推进，门禁报告会把这些记录在 Accepted Risks 下；FAIL 或 NOT ASSESSED 绝不会推进阶段。在 `workflow: minimal` 下，生产门禁不再要求 Vertical Slice——由针对当前构建的两项检查取代（核心循环有趣、能端到端运行）——技术设置门禁也会带着其「不适用」的说明通过。未试玩过的 Vertical Slice 读作 NOT ASSESSED 而非 FAIL，在 `lean` 和 `solo` 下，跳过美术圣经签核也不会被计为缺失。发布门禁不再为源语言要求本地化 QA 报告，会读取最新的全范围安全审计（这样后续更窄的审计无法清除未关闭的 HIGH），并且只把 `/release-checklist` 列为发布检查清单。`technical-director` 和 `creative-director` 会像 `producer` 那样在写下决策前询问。
- **发布要等待发布门禁。** `/team-release` 此前可能在项目仍处于 Polish 时就打标签并部署，事后再建议运行 `/gate-check release`。现在除非阶段读作 `Release`，否则它会在生成任何智能体之前停下；仍要推进需要显式覆写，并写入 go/no-go 记录。其 QA 步骤使用发布门禁的缺陷阈值（S1；在 `workflow: full` 下为 S1–S3），其智能体各自写入自己的签核文件——此前有两个写到同一文件，可能互相覆盖。`/release-checklist` 此前从里程碑文件中读取未关闭缺陷，而那里一个都不列；它现在读取 `production/qa/bugs/`，在没有缺陷记录时说明 NOT ASSESSED。`/launch-checklist` 此前从不询问只有人才能确认的事项（值班、EULA、媒体密钥），因此只可能以 NOT ASSESSED 结束；现在它按分区各询问一次（是／否／尚未／不适用），因此 READY 和 CONDITIONAL 可以达成，并且在你批准写入之前不再创建 `production/releases/`。`/day-one-patch` 在 `lead-programmer` 修改代码之前询问一次，并用 `commands.test` 运行测试。`/hotfix` 按 `/bug-triage` 的方式定义 S1，并在 `commands.test` 未设置时记录 `Tests: NOT RUN`。`/localize` 仅在 `workflow: full` 下要求每个已翻译语言区域获得 QA PASS 或 PASS WITH CONDITIONS（`standard` 下为建议），与门禁一致。
  `release-manager` 自己运行 `/patch-notes`，`community-manager` 优先遵循你项目的语气指南而非其默认值，`devops-engineer` 不再询问游戏代码架构问题。
- **QA 在每个 `qa.level` 下都能工作。** `/team-qa` 在 `minimal` 下会通过走查验收标准来覆盖一个没有测试的 Logic 故事，而此前每次签核都以 NOT ASSESSED 结束；它会在 QA 开始前读取已存档的缺陷，因此未关闭的 S1 或 S2 一开始就已知，能处理说明 NOT ASSESSED 的冒烟报告，并为 `/team-qa sprint-3` 找到 `sprint-003.md`。`/test-evidence-review` 遵循 `qa.level`（`minimal` 下缺失的测试为 WAIVED），并从 `testing.strict` 获取每种故事类型的门禁层级。`/bug-report verify` 会运行你的 `commands.test`，并能通过询问你是否执行了复现步骤来验证没有测试覆盖的缺陷；`close` 会展示关闭记录并在修改缺陷文件前询问——此前它先写入。`qa-tester` 按 `/bug-report` 的格式写缺陷，因此 `/bug-triage` 和 `/milestone-review` 能统计它们。`/bug-triage` 在没有缺陷文件时会以判决结束，`/milestone-review` 则把经覆写的 OFF TRACK 称为 CONDITIONAL GO。
- **故事、ADR 与冲刺保持一致。** `/dev-story` 此前把 `in_progress` 写入 `sprint-status.yaml`，而其他任何地方都不读这个值；现在它写入 `in-progress`，并且在一次未完成的运行之后，检查点会提示继续 `/dev-story`，而不是「Next step: /story-done」。在 `workflow: full` 下，`ADR: N/A` 的故事不再让 `/dev-story` 停下；Deprecated 或 Superseded 的 ADR 现在会阻挡故事，并点名其继任者。`/architecture-decision accept` 能找到它应当解除阻塞的那些被阻塞故事——它此前搜索的是 `/create-stories` 从不写入的状态写法。`/story-done` 从与 `/help` 相同的列表中挑选下一个故事，并且就行为验收标准询问你，而不是从代码中推断。`/code-review` 此前可能在读不到 ADR 的情况下批准代码；现在那会读作 NOT ASSESSED。`/scope-check` 和 `/sprint-status` 能读取 `/sprint-plan` 写入的三位数冲刺名，`/propagate-design-change` 则说明它如何查找 Foundation 层的 ADR。
- **团队技能会说明它们做了什么。** `/team-polish` 此前让 `performance-analyst` 去修代码，而它自己的智能体文件禁止它写代码；现在其报告是带逐项负责人的优化清单，由 `engine-programmer`（已加入 `small` 和 `studio` 组合）和 `tools-programmer` 在一次针对整组清单的询问后实施，`individual` 下该清单则交给 `/dev-story`。团队技能此前说总监「仍会在阶段门禁生成」，而实际没有任何一个会这样做；现在阶段门禁是流水线列出的一个决策点，在所有自动化模式下都是如此。`/team-audio`、`/team-level`、`/team-live-ops` 和 `/team-ui` 在每个此前写 `[path]` 的地方都点为每个智能体指定了工作文件。`/team-audio` 把音效圣经放在 `design/audio/sound-bible.md`，不再进入 GDD 检查。`/team-combat`、`/team-audio`、`/team-narrative` 和 `/team-ui` 在一项检查无法运行时，不再以单纯的 COMPLETE 结束：判决会点名它（`COMPLETE — engine validation NOT ASSESSED (…)`）。「ADR is Proposed」的阻塞项会指向 `/architecture-decision accept`。
- **`/security-audit` 报告会保留其发现。** 报告按范围命名（`security-audit-[date]-[scope].md`），因此当天的一次 `quick` 运行不再覆盖完整审计。`security-engineer` 会收到固定简报，说明每项发现都要依据其表格评定——它此前可能在到达时发现已被评级——并且对审计没有来源的分类（Unity 和 Unreal 上的常见情形）会点明它并说明如何修复。凭据扫描现在也能捕获 `ApiKey`、`sk_live_…` 以及各引擎的日志调用。
- **设计技能会沿着你所在路径收尾。** `/art-bible` 会在美术圣经的头部记录被跳过的签核（`SKIPPED [date] — [mode] mode`），以便生产门禁找到它；当 `art-director` 与 `technical-artist` 就资产标准不一致时会询问你，正如它在 UX 上早已如此；在 `workflow: minimal` 下则交接给 `/create-stories` 和 `/dev-story`，而不是 GDD 与架构。`/prototype` 会点明最小路线，并对无人试玩过的构建报告 NOT ASSESSED。`/adopt` 在 `minimal` 下按模板审计简报，并说明 Concept 没有可运行的门禁。`/tech-debt add` 在追加前会检查登记簿中是否有匹配条目。`/ux-review` 对 HUD 规格把 Pattern Library 标为不适用而不是 NOT ASSESSED，UX 模板也带有它用来选择检查清单的 `Template` 行。`/ux-design`、`ux-designer` 和无障碍模板在由谁设定无障碍层级上保持一致。
- **`/skill-test` 在每种模式下判定方式一致。** 分类模式此前对 NOT ASSESSED 的排序与静态模式和规格模式不同，并把目录中缺失的技能从 `category all` 中漏掉；无法解析的 frontmatter 现在为 NON-COMPLIANT，智能体则从 `.claude/agents/` 中列出。规格模板使用与规格相同的标题。
- **技能流程图把每一步放在其所属阶段。** 发布准备（`/security-audit`、`/localize qa`、`/release-checklist`、`/changelog`、`/patch-notes`）位于 Polish，在检查它的发布门禁之前；测试框架与无障碍规格位于 Technical Setup，在 `full` 下要求它们的门禁之前。五个输出路径现在与技能写入的内容一致，影响图也会点名读取 `project.stage`、`commands.test`、`testing.strict` 和 `qa.level` 的技能，以及写入阶段值的技能。
- **团队技能明确表示它们不运行总监门禁。** 全部九个中的 `review_mode` 说明仍然写着 `lean` 会运行四项总监阶段门禁，而没有任何团队流水线拥有这样的门禁。
- **跳过某个智能体的团队流水线会以 BLOCKED 结束。** 选择「跳过此智能体并记下缺口」会让其他阶段继续运行，但判决会点明该缺口，而不是读作 COMPLETE。
- **`/code-review` 不再读起来像是把 `NO ADRS FOUND` 排在批准之上。** 那句话属于 NOT ASSESSED 的排序。
- **接受 ADR 只会解除等待它的那些故事的阻塞。** 仍在已废弃 ADR 上、而该 ADR 又点名了继任者的故事保持 Blocked。针对该故事的建议现在会说明要编辑其 ADR 字段——`/create-stories` 从不重写已有故事——影响图也会像技能那样把 `Deprecated` 和 `Superseded` 的 ADR 列为阻断项。
- **更小的缺口已补上。** `/setup-engine` 在写入新的引擎 `VERSION.md` 前询问；`/release-checklist` 的报告会说明其 TODO/FIXME/HACK 计数覆盖了多少文件；`/team-combat` 定义了 NEEDS WORK；`/team-live-ops` 会在写入内容前等待两个并行阶段都完成；`/map-systems` 在边界评审被否决后展示修订后的地图；`/review-all-gdds` 会标记矛盾涉及的两份 GDD，并在其 `Not read:` 行中点名存在但为空的 GDD；拒绝 `/architecture-decision` 的改造不会写入任何内容。
- **智能体写明了它们此前只是暗示的内容。** performance-analyst 把代码质量权衡上报给 technical-director；release-manager 依据你给出的日期排期；sound-designer 的规格会列出衰减细节；Godot GDExtension 专家会转交 GDScript 与着色器工作，并列出升级所需的重建步骤；GDScript 专家在把代码迁移到 GDExtension 之前要求性能分析证据；network-programmer 只用网络侧契约回答托管问题；technical-artist 会点明粒子专属的削减项。

Every engine command on Windows was run on Godot 4.6.1 (gdUnit4 6.1.3), Unity
6000.3.23f1 and Unreal Engine 5.7 before it was written down, and the Godot and
Unreal CI templates ran on GitHub Actions. The Unreal commands for Linux and
macOS, the Unity CI template and the Unity assembly-definition guidance were
checked against their documentation, not run. Checked on Claude
Code 2.1.281 to 2.1.284, on Windows, Linux (bash 5 and 3.2) and macOS. **If you ran `/setup-engine` on 1.1.0 or 1.1.1**, your
`project.yaml` still holds the old test and build commands —
[UPGRADING.md](UPGRADING.md#v111--v112) lists what to change.

在 Windows 上的每条引擎命令在写入文档之前都已在 Godot 4.6.1（gdUnit4 6.1.3）、Unity 6000.3.23f1 和 Unreal Engine 5.7 上运行过，Godot 与 Unreal 的 CI 模板也已在 GitHub Actions 上运行。面向 Linux 和 macOS 的 Unreal 命令、Unity CI 模板以及 Unity 程序集定义指南是按其文档核对的，并未实际运行。已在 Claude Code 2.1.281 至 2.1.284 上，在 Windows、Linux（bash 5 和 3.2）和 macOS 上核验。**如果你在 1.1.0 或 1.1.1 上运行过 `/setup-engine`**，你的 `project.yaml` 中仍然是旧的测试和构建命令——[UPGRADING.md](UPGRADING.md#v111--v112) 列出了需要修改的内容。

---

## [1.1.1] — 2026-09-24

**Skills and agents work again outside auto mode.** A fix release for
[#128](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/128).

**技能与智能体在自动模式之外重新可用。** 这是针对 [#128](https://github.com/Donchitos/Claude-Code-Game-Studios/issues/128) 的修复版本。

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
- **Skills find `project.yaml` from any folder.** A skill run in a session
  started inside `src/` or `design/` now reads the project's `project.yaml`, not
  nothing. Claude Code itself still loads the project's hooks, deny rules and
  permission mode only when it is started at the project root.
- **`/changelog` works in a repository with no commits yet.**

### 修复

- **技能不再在开始之前就中止。** 在 1.1.0 中，每个读取你配置的技能都以一条 Claude Code 除非被显式批准否则拒绝运行的 shell 命令开头。在 CCGS 随附的权限模式（`default`）下，74 个技能中有 66 个在开始做任何事之前就停下了，无论从项目的哪个子目录运行，也无论 Claude 何时自行调用技能——在自动模式下同样如此。现在每个技能都以一条普通命令执行配置查找，并在自己的 frontmatter 中精确地预批准该命令。其他任何命令都不获批准。
- **`game-designer` 和 `creative-director` 重新可以启动。** 两者都会预加载技能，因此那条会中止的命令在启动时以 `Shell command permission check failed … Contains expansion` 让它们停下。它们保留了预加载的技能，并且仍然没有 shell 访问权限。
- **技能可从任何文件夹找到 `project.yaml`。** 在从 `src/` 或 `design/` 内部启动的会话中运行的技能，现在会读取项目的 `project.yaml`，而不是什么都读不到。Claude Code 本身仍只在项目根目录启动时才加载项目的钩子、拒绝规则和权限模式。
- **`/changelog` 在没有提交记录的仓库中也能工作。**

Checked on Claude Code 2.1.277 and 2.1.281, in every permission mode, from the
project root and from subdirectories. See `.claude/docs/config-resolution.md`
for the form every skill's config line must take, if you write your own.

已在 Claude Code 2.1.277 和 2.1.281 上核验，覆盖每种权限模式，并从项目根目录和子目录分别测试。如果你要编写自己的技能，请参阅 `.claude/docs/config-resolution.md`，了解每个技能的配置行必须采用的写法。

---

## [1.1.0] — 2026-09-23

**One config file, and a process weight you choose — one you can see and adjust,
not a question you answer once at setup and forget.** A solo game jam and a
studio production no longer have to carry the same overhead.

**一个配置文件，以及一个由你选择的流程权重——它可见、可调整，而不是在设置时回答一次就被遗忘的问题。** 单人 game jam 与工作室制作不再需要承担相同的开销。

### Added

- **Sessions start in ask-before-write mode.** CCGS sets Claude Code's
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

### 新增

- **会话以写入前询问模式启动。** CCGS 在项目设置中把 Claude Code 的权限模式设为 `default`，因此在项目根目录启动的终端会话在写入前会询问，即使你自己的 Claude Code 配置运行在自动接受模式中。它只设定起始模式：恢复会话、在会话中途切换模式、VS Code 扩展和 Desktop 应用仍可能让你处于其他模式。`.claude/docs/setup-requirements.md` 列出了这些情况，以及如何更改起始模式。

- **`project.yaml`——项目配置的唯一位置。** 引擎、命名约定、专家和流程设置都集中在这里。它取代了此前分摊这些内容的三个独立文件。

- **`project.local.yaml`——你的个人设置，而非团队的。** Git 会忽略它，因此你可以在自己的机器上运行更精简的评审或更少的确认，而不影响其他任何人。

- **`modes.rigor`——一个问题取代六个。** 设定 `minimal`、`standard` 或 `full`，它会一次性配置六个底层设置。你仍然可以覆写其中任意一个；其余的保持在 rigor 设定的位置。
  - **`minimal`**——无需设计文档，文字简洁，测试证据从轻。从设置到可运行代码的最快路径。
  - **`standard`**——5 个必需的设计分区，深度均衡。
  - **`full`**——全部 8 个设计分区，详尽文档，每个故事都有完整测试证据。

- **按系统的例外。** 可以把某个系统要求得比项目其余部分更严格——你的战斗系统可以采用完整处理，而其余一切保持从轻。例外只能让要求更严格，绝不会更宽松。

- **一条真正的 game jam 路径，而不是把开关全关掉的完整流水线。** `minimal` 现在基于一份含六个字段的单页游戏简报，取代 30 分区的概念文档、系统拆解以及按系统的设计文档。四步即可运行代码：选择引擎 → 写简报 → `/create-stories` → `/dev-story`。在 Godot 上，`/setup-engine` 现在还会创建引擎打开这些步骤产物所需的 `project.godot`——在此之前，该路径交付的是真实源文件，却没有可加载它们的项目，因此上述说法并不成立。**Unity 和 Unreal 项目仍必须先在各自的编辑器中创建**；CCGS 不会伪造一个，因为它无法得知那些文件应当包含什么。

- **`modes.review_mode`**——有多少总监智能体评审你的工作。**在 `team-*` 编排器上，`full` 和 `lean` 目前行为相同。** 那九个技能只会调用阶段门禁评审者，而 `lean` 的定义是「跳过不是阶段门禁的总监门禁」——所以它没有可跳过的内容。`solo` 确实不同：它完全关闭总监门禁。在其他地方（设计与架构评审），三个层级都按描述有所区别。
- **`modes.automation`**——在事情发生之前，系统多久会请你确认。在 `autonomous` 模式下，决策会写入日志，而不是打断你。你始终可以列出无论如何都必须询问的分类。**有四个技能有意忽略此设置并始终询问：** `/setup-engine`、`/gate-check`、`/hotfix` 和 `/day-one-patch`——引擎选择是一次性且不可逆的决策，没人阅读的门禁判决会让门禁失去意义，而两个发布技能需要显式签核。完整列表与原因见 `.claude/docs/automation-modes.md`。
- **`qa.level`**——故事完成前需要多少测试证据。
- **`docs.density`**——写下的分区有多深入。
- **`team.size`**——默认有哪些智能体参与。只影响评审深度；绝不会改变故事必须交付的内容。
- **按测试类型的 `testing.strict`**——逻辑故事可以因测试失败而阻塞，而视觉故事则保持建议性质。

- **`/settings`**——查看你的生效配置、检查某个值，或修改它。`/settings --local` 会写入你的个人文件。当某项更改会被其他设置覆写时，它会警告你。

- **`/start` 重做**——一次把所需的一切问清，并在一轮内写出完整配置，而不是把问题分散到后续步骤中。

- **面向已有项目的迁移工具。** 一个转换器可以把 v1.0 项目迁移到 `project.yaml`。它默认先预览，只有在证明每个值都存活之后才删除旧文件，若有任何缺失则什么都不删。`/adopt` 能识别较旧的项目并替你运行它；如果你有旧配置文件却没有 `project.yaml`，会话启动时会收到提醒。

- **关于项目需要多少流程的建议。** 描述你正在做的游戏，CCGS 就会建议一个层级，而不是让你去猜「standard」对于一个周末 game jam 和两年期制作分别意味着什么。

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

### 变更

- **Claude 不再自行启动那四条高风险命令。** `/hotfix`、`/day-one-patch`、`/dev-story` 和 `/story-done` 现在只在你键入时运行。它们会绕过冲刺流程、修补已发布的构建、编写游戏代码并关闭故事——这些都不应仅因为对话漂移到相关话题就自动开始。其他一切仍像以前一样被建议。
- **引擎专家只能把工作交给自己的子专家。** Godot、Unity 和 Unreal 专家现在被限制为各自手下的四个子专家。此前它们任何一个都可以调用工作室里的任何智能体。这本就是文档中的规则；现在它被强制执行，而不再靠自觉。
- **十五个从不委派工作的智能体不再拥有该能力。** 它们此前带着生成其他智能体的能力，却从未使用。

- **轻量现在是默认，而不仅是建议。** `modes.rigor` 的默认值从 `standard` 改为 `minimal`，因此从不打开 `/settings` 的项目会走上快速路径：一份单页简报取代完整设计流水线、文字简洁、测试证据从轻、没有总监评审小组。我们改变这一点是因为我们测量了旧的默认值。两种方式各建一遍后，较重的层级达到可运行代码的成本高出数倍，却没有产生更好的结果，而且在别人接手项目时没有带来任何回报。它不是在换来更多；它换来的东西我们完全探测不到。如果你的项目超出了轻量路径，`/help` 和 `/gate-check` 会说明，而 `/settings modes.rigor=standard` 就是一条命令。已显式设定 `rigor` 的项目完全不受影响。
- **设置过程默认引导走向轻量。** `/start` 现在为新项目推荐最小化的引导路径，让你先落在一个轻量的位置，再按需升级。
- **设置询问的是你的游戏，而不是框架。** 那个问题是「什么最能描述你正在做的东西？」——一次 game jam、一个聚焦项目、某个系统密集的作品——而不是「你想要多少流程？」
- **你的流程层级始终可见。** 状态行会在项目阶段旁显示它，例如 `Concept · minimal`。
- **建议是双向的。** `/help` 可以在项目成长时建议收紧，而不只是在听上去不堪重负时建议放松。
- **进入 Production 时会提供一次检查**，看你最初选择的层级是否仍然合适。这只是建议——绝不会改变判决。
- **`team.size: solo` 现在改为 `team.size: individual`**，以免与含义不同的 `review_mode: solo` 混淆。
- **你花在框架本身上的会话时间更少了。** 每轮开销减少了约 40%，为你的实际游戏留出更多空间。
- **在 `/clear` 或 `/compact` 之后接着工作更可靠了。** 你的会话检查点现在是会话笔记中一个定义清晰的部分，而不是一个不断增长的文件，因此每次恢复的内容都一致，并为实际工作留出多得多的空间。较旧的笔记可以归档而不会丢失任何东西。

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

### 修复

- **Unity 和 Unreal 项目此前在静默中跳过了三项提交与会话检查。** 用于查找硬编码玩法数值、无归属的 TODO、未记录的玩法系统以及缺失架构文档的钩子，此前都搜索 `src/`——而那是 Godot 存放代码的位置。Unity 把代码放在 `Assets/`，Unreal 放在 `Source/`，因此在那些引擎上搜索匹配不到任何内容，每项检查都悄无声息地什么都没做，结果与干净通过毫无区别。现在它们会按你的引擎解析代码根目录；如果无法确定你的代码在哪里，它们会如实说明，而不是报告没找到任何东西。

- **Godot C# 项目现在可以把 C# 工作交给 C# 专家。** Godot 专家此前只列出其四个子专家中的三个，导致 `godot-csharp-specialist` 不可达——尽管设置会把每个 `.cs` 文件路由给它。如果你选择了 C# 或 Both，你的游戏代码就没有专家路径。
- **README 中的规则徽章写的是 11。实际有 13 条。**

- **`/hotfix` 现在会先获得你的批准再动代码。** 它此前先实施修复，事后再收集批准。
- **`/sprint-plan` 不再承诺一个会被你的设置跳过的评审步骤。** 它现在会说明哪些评审在哪些层级运行。
- **`/story-done` 在自主模式下不再能关闭验收标准未通过的故事。** 保护措施原本存在，但无法被触达。
- **`/settings` 不再把由 rigor 派生的值显示为「已锁定」**，那会被读作「你改不了」，而你其实可以改。
- **`/design-system` 不再在要求更少分区的层级上坚持 8 个设计分区。**
- **`/localize`** 曾指向一个并不存在的命令。
- **`/team-narrative`** 曾把两个阶段连在一起运行，之间没有任何检查点。
- **升级说明不再建议对与模板没有共同历史的项目执行会与每个文件都冲突的合并。**
- **升级说明现在要求你先检查自己的自定义内容。** 替换框架会覆盖你对其同时随附的任何文件所做的修改——尤其是智能体定义和钩子注册。步骤展示了如何在开始前找到这些内容，以及如何保留你想要的那些。
- **在未变更的工作上重跑评审时，现在会提供跳过选项**，而不是以完整成本重复全部流程。
- **若干已记录的设置此前悄无声息地什么都不做。** 它们看起来正确，却匹配不到任何东西。
- **Game jam 与原型项目不再收到关于它们本不该撰写的设计文档分区的警告。** 该检查现在会尊重你选择的层级。
- **两项文件检查此前在 Windows 上静默地什么都不做。** 它们运行了、什么也没找到、然后报告成功。现在它们可以正常工作了。
- **通过阶段门禁现在真的能推进你的项目阶段。** `/gate-check` 此前达到了正确判决，却无法记录它。
- **`/bug-report` 现在能运行测试**，这是它一直声称会做的。
- **提交玩法代码时不再在警告旁打印一整墙原始搜索输出。**
- **状态行可以显示你正在做什么**——史诗、功能与任务的面包屑在文档中有描述，却从未真正出现。
- **修复了 Unity 参考文档中的失效链接。**

### Removed

- **The bundled example game and the sample session transcripts.** They
  described a project that didn't match the current workflow. Both are
  recoverable from git history if you want them.

### 移除

- **随附的示例游戏与示例会话记录。** 它们描述的是一个与当前工作流不符的项目。如果你需要，两者都可以从 git 历史中找回。

### Deprecated

- `production/stage.txt`, `production/review-mode.txt` and
  `.claude/docs/technical-preferences.md` are superseded by `project.yaml`.
  **Nothing breaks if you keep them** — they're still read when `project.yaml`
  doesn't have a value. Run the migration script with `--finalize` when you're
  ready to retire the first two. The third is kept on purpose: it still holds
  your Forbidden Patterns and Allowed Libraries, which have no `project.yaml`
  equivalent yet.

### 弃用

- `production/stage.txt`、`production/review-mode.txt` 和 `.claude/docs/technical-preferences.md` 已被 `project.yaml` 取代。**保留它们不会有任何东西损坏**——当 `project.yaml` 没有对应值时，它们仍会被读取。当你准备停用前两个时，可用 `--finalize` 运行迁移脚本。第三个是有意保留的：它仍然保存你的 Forbidden Patterns 和 Allowed Libraries，这些目前还没有 `project.yaml` 中的对应项。

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

### 已知限制

- **Windows 是经验证的平台。** 一切都在 Windows 上核验过。macOS 和 Linux 应当可用，但尚未确认。
- **没有编译任何 Unity 或 Unreal 项目。** 两个引擎的配置、路由和文档都已核验，但这里没有任何东西会构建或启动其中任一个的真实项目。
- **部分引擎参考细节被标记为未核验，而不是猜测。** 当版本号或 API 细节无法从真实来源确认时，会在原处标记出来，而不是填入看似合理的内容。在重要之处你会看到该标记。

### Settings that don't do anything yet

These six are documented and accepted, but nothing reads them. **Setting one
today has no effect.** `/settings` says so when you view or change one, so you
won't configure something expecting a result:

`accessibility.target` · `cadence.sprint_length` · `cadence.milestone_length` ·
`strict_gate_checks` · `project.kind` · `features.token_budget_warn_at`

### 暂不起作用的设置

这六项已被记录并接受，但没有任何代码读取它们。**今天设置其中任何一项都不会产生效果。** 当你查看或修改某一项时，`/settings` 会说明这一点，因此你不会配置某个东西却期待结果：

`accessibility.target` · `cadence.sprint_length` · `cadence.milestone_length` ·
`strict_gate_checks` · `project.kind` · `features.token_budget_warn_at`

---

## Earlier releases

For v1.0 and earlier, see the version history in
[UPGRADING.md](UPGRADING.md) — each release has its own "What Changed" section
written at the time it shipped.

## 更早的版本

关于 v1.0 及更早版本，请参阅 [UPGRADING.md](UPGRADING.md) 中的版本历史——每个版本都有自己的「What Changed」章节，写于其发布当时。
