---
name: start
description: "Guides a first-time user through onboarding and picks the right workflow. Use when the user is new, just cloned or installed the studio, has no idea or engine yet, asks where to begin, or wants to bring in an existing game."
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Bash(bash .claude/scripts/project-state.sh*), Bash(bash .claude/scripts/set-stage.sh *), Bash(bash .claude/scripts/config-set.sh *)
model: sonnet
---

---
name: start
description: "引导首次使用的用户完成入门，并挑选合适的工作流。当用户是新人、刚克隆或安装了工作室、还没有想法或引擎、询问从哪里开始，或想引入一个已有的游戏时使用。"
argument-hint: "[no arguments]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Bash(bash .claude/scripts/project-state.sh*), Bash(bash .claude/scripts/set-stage.sh *), Bash(bash .claude/scripts/config-set.sh *)
model: sonnet
---

# Guided Onboarding

The entry point for a new user. It assumes no game idea, no engine and no experience: it reads
the project, asks where the user is starting from, shows what it assumes about the project, and
names the one next step. It never runs that step itself.

It writes these settings to `project.yaml`, all through helpers, and only after an explicit yes:
`project.stage` (with its legacy mirror `production/stage.txt`), `modes.rigor` and
`modes.automation`. It never writes `modes.review_mode` or `production/review-mode.txt`, and none
of the other knobs rigor fronts (`modes.workflow`, `docs.density`, `qa.level`,
`modes.story_granularity`, `team.size`): a written value pins that knob over the rigor expansion,
and a mirror file outranks it.

Ask with the question tool. Without one, list the options numbered and end your turn to wait. The
question is the last thing in the reply: no path, note or advice after it. A skipped or dismissed
question is not an answer: ask again in plain text.

The questions in Phases 2, 4 and 5 shape the project, so they are asked in every automation mode.
The engine is not one of them: `/setup-engine` chooses it. Phase 6's last question follows a
`modes.automation` already in `project.yaml`, per `.claude/docs/automation-modes.md`; with none
set, ask it.

# 引导式入门

新用户的入口。它假定没有游戏想法、没有引擎、也没有经验：它读取
项目，询问用户从哪里起步，展示它对项目的假设，并
点名唯一的下一步。它从不亲自运行那一步。

它把这些设置写入 `project.yaml`，全部通过辅助脚本，且仅在明确同意之后：
`project.stage`（连同其旧版镜像 `production/stage.txt`）、`modes.rigor` 和
`modes.automation`。它从不写入 `modes.review_mode` 或 `production/review-mode.txt`，也不写
rigor 所映射的其他任何旋钮（`modes.workflow`、`docs.density`、`qa.level`、
`modes.story_granularity`、`team.size`）：已写入的值会固定该旋钮、优先于 rigor 的展开，
而镜像文件的优先级又高于它。

用提问工具询问。没有工具时，把选项编号列出并结束你的回合等待。问题是
回复中的最后一件事：其后没有路径、注解或建议。被跳过或关闭的
问题不算回答：用纯文本再问一次。

阶段 2、4 和 5 中的问题会塑造项目，因此在每种自动化模式下都会询问。
引擎不在其中：由 `/setup-engine` 选择它。阶段 6 的最后一个问题遵循
`project.yaml` 中已有的 `modes.automation`，依据 `.claude/docs/automation-modes.md`；若未设置，
则询问它。

## Phase 1: Read the project

Run `bash .claude/scripts/project-state.sh` and keep its rows. Do not show them yet; they check
the user's answer in Phase 2.

| Row | Use |
|---|---|
| `engine`, `code_root`, `source_files` | Is an engine set, and how much code is there. `source_files` of `unknown` means the code root could not be found: say that, never "no code" |
| `concept` | `design/gdd/game-concept.md` or `design/game-brief.md` exists |
| `gdd_files`, `adr` | Design documents and architecture decisions on disk (they set the stage in Phase 4) |
| `prototype`, `sprint`, `milestone`, `story` | Other existing work |
| `origin_url` | Contains `donchitos/claude-code-game-studios`, matched case-insensitively: the clone still points at the template repo, so a push or pull request would go there. A fork under another owner is the user's own |
| `stage` | The stage already recorded, if any |

Ignore `phase_inferred`: it guesses from file counts, and a project with code but no design
documents is not in Production. If the helper fails, say so and read the same facts by hand
(engine in `project.yaml`, the two concept files, the code root's files, `design/gdd/`).

The helper does not report rigor or automation. Read `project.yaml`, if it exists, and note
whether `modes.rigor` and `modes.automation` are set: a set value is kept, and its question is
not asked (Phases 4 and 5).

**Returning user** (an engine is set and `concept` is present): ask nothing. Say the engine, the
concept or brief found, and the review mode: `modes.review_mode` if set, otherwise the one
`modes.rigor` implies (`minimal` → `solo`, `standard` → `lean`, `full` → `full`). Suggest `/help` for the next step, add the
template-remote note if it applies, and stop.

## 阶段 1：读取项目

运行 `bash .claude/scripts/project-state.sh` 并保留其各行。暂时不要展示它们；它们用于核对
用户在阶段 2 的回答。

| 行 | 用途 |
|---|---|
| `engine`、`code_root`、`source_files` | 是否已设置引擎，以及有多少代码。`source_files` 为 `unknown` 意味着找不到代码根目录：说明这一点，绝不说"没有代码" |
| `concept` | `design/gdd/game-concept.md` 或 `design/game-brief.md` 存在 |
| `gdd_files`、`adr` | 磁盘上的设计文档和架构决策（它们在阶段 4 设定阶段） |
| `prototype`、`sprint`、`milestone`、`story` | 其他已有工作 |
| `origin_url` | 包含 `donchitos/claude-code-game-studios`，不区分大小写匹配：克隆仍指向模板仓库，所以 push 或拉取请求会发往那里。由其他所有者维护的 fork 是用户自己的 |
| `stage` | 已记录的阶段（若有） |

忽略 `phase_inferred`：它按文件计数猜测，而一个有代码但无设计
文档的项目并不处于 Production。如果辅助脚本失败，说明这一点并手动读取相同事实
（`project.yaml` 中的引擎、两个概念文件、代码根目录的文件、`design/gdd/`）。

辅助脚本不报告 rigor 或自动化。如果 `project.yaml` 存在，读取它，并注意
`modes.rigor` 和 `modes.automation` 是否已设置：已设置的值会被保留，其问题
不会被询问（阶段 4 和 5）。

**回访用户**（已设置引擎且 `concept` 存在）：什么都不问。说出引擎、
找到的概念或简报，以及评审模式：若已设置则为 `modes.review_mode`，否则为
`modes.rigor` 所意味着的那个（`minimal` → `solo`，`standard` → `lean`，`full` → `full`）。下一步建议 `/help`，如果适用则加上
模板远程的注解，然后停下。

## Phase 2: Ask where the user is

Ask with the question tool: "Welcome! Where are you starting from with your game?" Options:
- `A) No idea yet`: no game concept; explore and find what to make.
- `B) Vague idea`: a theme, feeling or genre ("something with space", "a cozy farming game").
- `C) Clear concept`: the core idea and genre are known, nothing is written down yet.
- `D) Existing work`: design documents, prototypes, code or plans already exist.

Wait for the answer. If it contradicts Phase 1, say what you found once and ask again: D on an
empty project ("this looks like a fresh template; would A or B fit better?"), or A with code on
disk ("I found code in `[code_root]`; did you mean D?"). If no option fits, let the user describe
their situation and route from that.

## 阶段 2：询问用户所处的起点

用提问工具询问："欢迎！你的游戏是从哪里起步的？" 选项：
- `A) No idea yet`：还没有游戏概念；探索并找出要做什么。
- `B) Vague idea`：一个主题、感觉或类型（"带点太空的东西"、"一个温馨的农场游戏"）。
- `C) Clear concept`：核心想法和类型已明确，但还什么都没写下来。
- `D) Existing work`：设计文档、原型、代码或计划已经存在。

等待回答。如果它与阶段 1 矛盾，说明一次你发现的内容并再问一次：在
空项目上选 D（"这看起来像一个全新的模板；A 或 B 会不会更合适？"），或在磁盘
有代码时选 A（"我在 `[code_root]` 里找到了代码；你是指 D 吗？"）。如果没有选项合适，让用户描述
自己的情况并据此路由。

## Phase 3: Route

Name the immediate next step only. The full path waits for Phase 6, after the rigor is known.

- **A, no idea:** starting
  [hint]` starts from a word or theme. Next step: `/brainstorm open`, or a hint if one comes to
  mind. Describe it as "turns no idea into a written design the next step builds from"; how long
  that design is depends on the rigor, so leave that for Phase 6.
- **B, vague idea:** ask for the idea in a few words, take it as it is, and name
  `/brainstorm [their words]`.
- **C, clear concept:** ask for the concept in one sentence (genre and core mechanic), as plain
  text. Then ask: "How would you like to proceed?" Options: `Formalize it first` (`/brainstorm
  [concept]` writes it down) / `Jump straight in` (`/setup-engine` now, write the design after).
  The next step is their pick.
- **D, existing work:** say what Phase 1 found ("N source files under `[code_root]`, N design
  documents, engine [X / not set]"). Next step: `/setup-engine` when no engine is set and there is
  no more than a concept; otherwise `/project-stage-detect`.

Then say: "I'll lay out the full path in a moment."

## 阶段 3：路由

只点名紧接着的下一步。完整路径要等到阶段 6，在 rigor 已知之后。

- **A，没有想法：** 从
  [hint]` 从一句话或主题起步。下一步：`/brainstorm open`，或如果想到一个提示就给出提示。把它描述为"把没有想法变成下一步可以据以构建的书面设计"；那份设计
  有多长取决于 rigor，所以把它留到阶段 6。
- **B，模糊的想法：** 请用户用几句话说出想法，照原样接受，并点名
  `/brainstorm [their words]`。
- **C，清晰的概念：** 请用户用一句话（类型和核心机制）以纯
  文本说出概念。然后询问："你希望如何推进？" 选项：`Formalize it first`（`/brainstorm
  [concept]` 把它写下来）/ `Jump straight in`（现在就 `/setup-engine`，之后写设计）。
  下一步由他们挑选。
- **D，已有工作：** 说出阶段 1 发现的内容（"`[code_root]` 下有 N 个源文件、N 份设计
  文档、引擎 [X / 未设置]"）。下一步：若未设置引擎且仅有
  一个概念，则用 `/setup-engine`；否则用 `/project-stage-detect`。

然后说："我稍后会铺开完整路径。"

## Phase 4: Show what you assume, then save it

Work out two values.

**Stage.** Paths A, B and C: `Concept`. Path D, from the Phase 1 rows:

| On disk | Stage |
|---|---|
| no engine, or nothing beyond a concept (`gdd_files` 0) | `Concept` |
| `gdd_files` 1 or more, `adr` 0 | `Systems Design` |
| `adr` 1 or more | `Technical Setup` |

**Rigor.** If `modes.rigor` is already set in `project.yaml`, keep it and say so. Otherwise infer
it from what the user said in Phases 2 and 3, using the signals in
`.claude/docs/settings-guidance.md` §3:

| The user's words mention | Rigor |
|---|---|
| open world, RPG, sim, sandbox, factions, crafting, economy, MMO, multiplayer, many systems | `full` |
| release, commercial, Steam, one clear core loop | `standard` |
| jam, weekend, prototype, first game, small, just trying | `minimal` |
| nothing above, or no idea yet | `minimal` (the default) |

A path B hint is still a description: "some kind of open-world survival sim" is `full`.

Show the card:

```
What I'll set up
  Stage:  [stage]  ([why, from what was found or picked])
  Rigor:  [value]  ([why, in the user's words] | already set)
          minimal: short brief, coarse stories, tests optional; about 4 steps to code
          standard: about 8 design documents before code; standard QA evidence
          full: everything in standard plus validation builds; evidence everywhere
  /settings changes either of these any time.
```

Then ask with the question tool: "Save these to `project.yaml` (and the stage to
`production/stage.txt`)?" Options: `Save them` / `Don't save`. Ask no question about the rigor
itself: the card shows it, and `/settings` changes it.

- **Save them:** run `bash .claude/scripts/set-stage.sh "[stage]"`, then, only when rigor was not
  already set, `bash .claude/scripts/config-set.sh modes.rigor [value]`. Check the read-back rows
  match. Say: "Saved. Rigor `[value]` sets six other settings; `/settings` shows them and changes
  any of them."
- **Don't save**, or anything other than an explicit yes: write nothing, keep the values for this
  run, and say they were not saved.

If a helper exits non-zero, show its output, say which setting was not written, and go on with the
value for this run.

## 阶段 4：展示你的假设，然后保存

算出两个值。

**阶段。** 路径 A、B 和 C：`Concept`。路径 D，依据阶段 1 的各行：

| 磁盘上 | 阶段 |
|---|---|
| 无引擎，或除概念外别无他物（`gdd_files` 为 0） | `Concept` |
| `gdd_files` 为 1 或更多，`adr` 为 0 | `Systems Design` |
| `adr` 为 1 或更多 | `Technical Setup` |

**Rigor。** 如果 `project.yaml` 中已设置 `modes.rigor`，保留它并说明。否则依据
用户在阶段 2 和 3 中所说，使用
`.claude/docs/settings-guidance.md` §3 中的信号来推断：

| 用户的话提到 | Rigor |
|---|---|
| 开放世界、RPG、模拟、沙盒、派系、制作、经济、MMO、多人、许多系统 | `full` |
| 发布、商业、Steam、一个清晰的核心循环 | `standard` |
| game jam、周末、原型、第一个游戏、小、只是试试 | `minimal` |
| 以上都没有，或还没有想法 | `minimal`（默认） |

路径 B 的提示仍然是一种描述："某种开放世界生存模拟" 就是 `full`。

展示卡片：

```
What I'll set up
  Stage:  [stage]  ([why, from what was found or picked])
  Rigor:  [value]  ([why, in the user's words] | already set)
          minimal: short brief, coarse stories, tests optional; about 4 steps to code
          standard: about 8 design documents before code; standard QA evidence
          full: everything in standard plus validation builds; evidence everywhere
  /settings changes either of these any time.
```

```
我将设置的
  阶段:  [stage]  ([为什么，依据发现或挑选的内容])
  Rigor:  [value]  ([为什么，用用户的话] | 已设置)
          minimal: 简短简报，粗粒度故事，测试可选；约 4 步到代码
          standard: 代码前约 8 份设计文档；标准 QA 证据
          full: standard 中的一切加上验证构建；处处有证据
  /settings 可随时更改其中任一项。
```

然后用提问工具询问："把这些保存到 `project.yaml`（并把阶段保存到
`production/stage.txt`）？" 选项：`Save them` / `Don't save`。不要就 rigor
本身提问：卡片显示了它，`/settings` 可更改它。

- **Save them：** 运行 `bash .claude/scripts/set-stage.sh "[stage]"`，然后，仅在 rigor 尚未
  设置时，运行 `bash .claude/scripts/config-set.sh modes.rigor [value]`。检查回读的各行
  是否匹配。说："已保存。Rigor `[value]` 会设置另外六项设置；`/settings` 会显示它们并可更改
  其中任何一项。"
- **Don't save**，或任何非明确同意的回答：什么都不写，为本次
  运行保留这些值，并说明它们未被保存。

如果辅助脚本以非零退出，展示其输出，说明哪项设置未写入，并继续使用
本次运行的值。

## Phase 5: Ask how much to confirm

If `modes.automation` is already set, say "Automation is `[value]`" and go on. Otherwise ask:
"Last one: how much should I confirm with you as we work?" Options:
- `Guided (Recommended)`: I decide small things and still stop for big ones (scope changes,
  deletions, schema changes).
- `Collaborative`: I ask before each significant step and show drafts before writing.
- `Autonomous`: I proceed and log decisions, stopping only for the always-ask categories. Fastest,
  most tokens.

Mapping: `Guided` → `guided`, `Collaborative` → `collaborative`, `Autonomous` → `autonomous`. The
pick is the consent to write it: run `bash .claude/scripts/config-set.sh modes.automation [value]`,
unless the Phase 4 save was declined (then say it was not saved).

## 阶段 5：询问确认程度

如果 `modes.automation` 已设置，说"自动化模式为 `[value]`"并继续。否则询问：
"最后一个：我们工作时我该向你确认多少？" 选项：
- `Guided (Recommended)`：我自己决定小事，但仍会为大事停下（范围变更、
  删除、模式变更）。
- `Collaborative`：我在每个重大步骤前询问，并在写入前展示草稿。
- `Autonomous`：我继续并记录决策，只为止步于 always-ask 类别。最快、
  最费 token。

映射：`Guided` → `guided`，`Collaborative` → `collaborative`，`Autonomous` → `autonomous`。
所选项就是写入它的同意：运行 `bash .claude/scripts/config-set.sh modes.automation [value]`，
除非阶段 4 的保存被拒绝（则说明它未被保存）。

## Phase 6: Show the path

Say: "Here's your path at rigor `[value]`. Every skill still runs at any rigor; rigor changes
what's required, not what's allowed."

The path starts with the step Phase 3 named. When that was `/brainstorm` (paths A and B, and C's
`Formalize it first`), list `/brainstorm` first and `/setup-engine` second: each runs without the
other.

**`minimal`: 4 steps to running code**
1. `/setup-engine`: choose and configure the engine
2. `/brainstorm`: write the one-page `design/game-brief.md`
3. `/create-stories`: turn the brief's MVP list into stories (no epics or sprint plan needed)
4. `/dev-story`: the first line of game code

**`standard`**
- Concept: `/setup-engine` → `/brainstorm` → `/prototype` → `/art-bible` → `/gate-check`
- Systems Design: `/map-systems` → `/design-system` (once per system) → `/review-all-gdds` →
  `/gate-check`
- Architecture: `/create-architecture` → `/architecture-decision` (once per decision) →
  `/create-control-manifest` → `/architecture-review` → `/test-setup` → `/ux-design`
  (accessibility and interaction patterns) → `/gate-check`
- Pre-Production: `/ux-design` (HUD and key screens) → `/create-epics` → `/create-stories` →
  `/sprint-plan` → `/gate-check`
- Production: `/dev-story`

Each `/gate-check` moves the project one stage, and only when it passes.

**`full`:** everything in `standard`, plus `/vertical-slice` and `/playtest-report` in
Pre-Production and `/design-review` after each GDD.

**Path D with existing work** (stage `Systems Design` or later, or code on disk) gets this instead.
Print only the steps that apply, and for the brief only the one source that applies. At `minimal`:
1. `/project-stage-detect`: what stage the project is at and what is missing
2. `/adopt`: whether the existing files are in the format the skills read
3. `/setup-engine`: only when no engine is set; leave it out when `engine` names one
4. The brief, only if `concept` is absent: `/reverse-document design [code_root]` when the code
   root holds 10 or more source files (it writes the brief from the game), and then do not mention
   `/brainstorm` at all; `/brainstorm` only when it holds fewer

At `standard` and `full`, steps 1 to 3, then `/design-system retrofit [path]`,
`/architecture-decision retrofit [path]`, `/architecture-review` and `/gate-check`.

Present `minimal` as the documented floor, not a lesser mode, and name its trade once: no GDDs, so
design problems show up in code.

If `origin_url` pointed at the template repo, add: "Your clone's `origin` still points at the
CCGS template repo, so a push or pull request would go there. When you're ready, run
`git remote rename origin template`, then `git remote add origin <your repo URL>`. `UPGRADING.md`
pulls updates from `template`; skip its own `git remote add template` step, since that remote now
exists." Suggest it; do not run it.

Ask: "Would you like to start with [first step]?" Options: `Yes, start with [first step]` /
`Something else first`. Either answer leads to Phase 7, never to running the step.

## 阶段 6：展示路径

说："这是你在 rigor `[value]` 下的路径。每个技能在任何 rigor 下仍可运行；rigor 改变的是
要求，不是允许。"

路径从阶段 3 点名的步骤开始。当那是 `/brainstorm` 时（路径 A 和 B，以及 C 的
`Formalize it first`），先列 `/brainstorm`，再列 `/setup-engine`：两者各自独立运行。

**`minimal`：4 步到能运行的代码**
1. `/setup-engine`：选择并配置引擎
2. `/brainstorm`：写出一页的 `design/game-brief.md`
3. `/create-stories`：把简报的 MVP 列表转成故事（无需史诗或冲刺计划）
4. `/dev-story`：第一行游戏代码

**`standard`**
- 概念：`/setup-engine` → `/brainstorm` → `/prototype` → `/art-bible` → `/gate-check`
- 系统设计：`/map-systems` → `/design-system`（每个系统一次）→ `/review-all-gdds` →
  `/gate-check`
- 架构：`/create-architecture` → `/architecture-decision`（每个决策一次）→
  `/create-control-manifest` → `/architecture-review` → `/test-setup` → `/ux-design`
  （无障碍与交互模式）→ `/gate-check`
- 预制作：`/ux-design`（HUD 和关键界面）→ `/create-epics` → `/create-stories` →
  `/sprint-plan` → `/gate-check`
- 制作：`/dev-story`

每个 `/gate-check` 让项目前进一步，且仅当它通过时。

**`full`：** `standard` 中的一切，外加预制作中的 `/vertical-slice` 和 `/playtest-report`，
以及每份 GDD 之后的 `/design-review`。

**带已有工作的路径 D**（阶段为 `Systems Design` 或更后，或磁盘上有代码）改为走这个。
只打印适用的步骤，简报只列适用的那一个来源。在 `minimal` 下：
1. `/project-stage-detect`：项目处于什么阶段、缺什么
2. `/adopt`：现有文件是否符合技能读取的格式
3. `/setup-engine`：只在未设置引擎时用；当 `engine` 已指名一个时省略
4. 简报，仅在 `concept` 缺失时：当代码根目录持有 10 个或更多源文件时用 `/reverse-document design [code_root]`
   （它根据游戏写出简报），然后完全不要提及
   `/brainstorm`；只在文件更少时用 `/brainstorm`

在 `standard` 和 `full` 下，步骤 1 到 3，然后是 `/design-system retrofit [path]`、
`/architecture-decision retrofit [path]`、`/architecture-review` 和 `/gate-check`。

把 `minimal` 呈现为有文档记载的下限，而不是次等模式，并说明一次它的代价：没有 GDD，所以
设计问题会在代码中显现。

如果 `origin_url` 指向模板仓库，补充："你克隆的 `origin` 仍指向
CCGS 模板仓库，所以 push 或拉取请求会发往那里。准备好时，运行
`git remote rename origin template`，然后 `git remote add origin <your repo URL>`。`UPGRADING.md`
从 `template` 拉取更新；跳过它自己的 `git remote add template` 步骤，因为该远程现已
存在。" 建议它；不要运行它。

询问："你想从 [first step] 开始吗？" 选项：`Yes, start with [first step]` /
`Something else first`。任一回答都通向阶段 7，绝不直接运行该步骤。

## Phase 7: Hand off

Respond with exactly one line: "Type `[skill]` to begin." Do not start that skill or call the
skill tool for it, even after a yes: the user types it. If they picked something else, name the skill for that instead, the same
way.

Verdict: **COMPLETE**, the user is oriented and handed off. If the user stopped before Phase 7,
say which settings were saved and which were not.

## 阶段 7：交接

只用一行回应："Type `[skill]` to begin." 不要启动那个技能，也不要为它调用
技能工具，即使是在同意之后：由用户输入它。如果他们选了别的，就用同样
方式改为点名那个技能。

结论：**COMPLETE**，用户已理清方向并完成交接。如果用户在阶段 7 之前停下，
说明哪些设置已保存、哪些未保存。
