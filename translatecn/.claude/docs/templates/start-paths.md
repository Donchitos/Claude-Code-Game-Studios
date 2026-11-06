# Your Path
# 你的路径

Here's your path at rigor `[value]`. Every skill still runs at any rigor; rigor changes
what's required, not what's allowed.
这是你在严谨度 `[value]` 下的路径。任何严谨度下每个技能仍可运行；严谨度改变的是
要求什么，而不是允许什么。

**`minimal`: 4 steps to running code**
**`minimal`：4 步到达可运行代码**
1. `/setup-engine`: choose and configure the engine
1. `/setup-engine`：选择并配置引擎
2. `/brainstorm`: write the one-page `design/game-brief.md`
2. `/brainstorm`：编写一页纸的 `design/game-brief.md`
3. `/create-stories`: turn the brief's MVP list into stories (no epics or sprint plan needed)
3. `/create-stories`：将简案中的 MVP 清单转化为故事（无需史诗或冲刺计划）
4. `/dev-story`: the first line of game code
4. `/dev-story`：第一行游戏代码

**`standard`**
**`standard`**
- Concept: `/setup-engine` → `/brainstorm` → `/prototype` → `/art-bible` → `/gate-check`
- 概念：`/setup-engine` → `/brainstorm` → `/prototype` → `/art-bible` → `/gate-check`
- Systems Design: `/map-systems` → `/design-system` (once per system) → `/review-all-gdds` →
  `/gate-check`
- 系统设计：`/map-systems` → `/design-system`（每个系统一次）→ `/review-all-gdds` →
  `/gate-check`
- Architecture: `/create-architecture` → `/architecture-decision` (once per decision) →
  `/create-control-manifest` → `/architecture-review` → `/test-setup` → `/ux-design`
  (accessibility and interaction patterns) → `/gate-check`
- 架构：`/create-architecture` → `/architecture-decision`（每个决策一次）→
  `/create-control-manifest` → `/architecture-review` → `/test-setup` → `/ux-design`
  （无障碍与交互模式）→ `/gate-check`
- Pre-Production: `/ux-design` (HUD and key screens) → `/create-epics` → `/create-stories` →
  `/sprint-plan` → `/gate-check`
- 预生产：`/ux-design`（HUD 与关键界面）→ `/create-epics` → `/create-stories` →
  `/sprint-plan` → `/gate-check`
- Production: `/dev-story`
- 生产：`/dev-story`

Each `/gate-check` moves the project one stage, and only when it passes.
每次 `/gate-check` 都会把项目推进一个阶段，且仅在通过时推进。

**`full`:** everything in `standard`, plus `/vertical-slice` and `/playtest-report` in
Pre-Production and `/design-review` after each GDD.
**`full`：** 包含 `standard` 的全部内容，另加预生产阶段的 `/vertical-slice` 与
`/playtest-report`，以及每份 GDD 之后的 `/design-review`。

**Path D with existing work** (stage `Systems Design` or later, or code on disk) gets this instead.
Print only the steps that apply, and for the brief only the one source that applies. At `minimal`:
**路径 D：已有既存工作**（处于 `Systems Design` 阶段或更晚，或磁盘上已有代码）改为采用以下路径。
只打印适用的步骤；对于简案，只打印适用的那一个来源。在 `minimal` 下：
1. `/project-stage-detect`: what stage the project is at and what is missing
1. `/project-stage-detect`：项目处于哪个阶段、还缺什么
2. `/adopt`: whether the existing files are in the format the skills read
2. `/adopt`：现有文件是否处于技能可读取的格式
3. `/setup-engine`: only when no engine is set; leave it out when `engine` names one
3. `/setup-engine`：仅在未设置引擎时使用；若 `engine` 已指明引擎则略去
4. The brief, only if `concept` is absent: `/reverse-document design [code_root]` when the code
   root holds 10 or more source files (it writes the brief from the game), and then do not mention
   `/brainstorm` at all; `/brainstorm` only when it holds fewer
4. 简案，仅在 `concept` 缺失时执行：当代码根目录包含 10 个及以上源文件时使用
   `/reverse-document design [code_root]`（它从游戏中写出简案），之后完全不要提及
   `/brainstorm`；只有当源文件少于 10 个时才使用 `/brainstorm`

At `standard` and `full`, steps 1 to 3, then `/design-system retrofit [path]`,
`/architecture-decision retrofit [path]`, `/architecture-review` and `/gate-check`.
在 `standard` 与 `full` 下，执行步骤 1 至 3，然后执行 `/design-system retrofit [path]`、
`/architecture-decision retrofit [path]`、`/architecture-review` 与 `/gate-check`。

`minimal` is the documented floor, not a lesser mode. Its trade: no GDDs, so design
problems show up in code.
`minimal` 是有文档记载的底线，而非次等模式。它的代价：没有 GDD，因此设计
问题会直接在代码中暴露。
