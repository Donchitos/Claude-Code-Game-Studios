# /adopt — Phase 1: Detect Project State

# /adopt — 阶段 1：检测项目状态

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/adopt` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## Phase 1: Detect Project State

## 阶段 1：检测项目状态

Emit one line before reading: `"Scanning project artifacts..."` — this confirms the
skill is running during the silent read phase.

在读取之前先输出一行：`"Scanning project artifacts..."` —— 这确认了技能在静默读取阶段正在运行。

Then read silently before presenting anything else.

然后在呈现任何其他内容之前静默读取。

### Existence check

### 存在性检查

- `project.stage` in `project.yaml` (fallback `production/stage.txt`) — if either is present, use that value (authoritative phase)

- `project.yaml` 中的 `project.stage`（回退到 `production/stage.txt`）—— 只要其中任一存在，就使用该值（权威阶段）

- `design/gdd/game-concept.md` (or, at the minimal tier, `design/game-brief.md`) — concept exists?

- `design/gdd/game-concept.md`（或在 minimal 层级下为 `design/game-brief.md`）—— 概念是否存在？

- `design/gdd/systems-index.md` — systems index exists?

- `design/gdd/systems-index.md` —— 系统索引是否存在？

- Count GDD files: `design/gdd/*.md` (excluding game-concept.md and systems-index.md)

- 统计 GDD 文件数量：`design/gdd/*.md`（排除 game-concept.md 和 systems-index.md）

- Count ADR files: `docs/architecture/adr-*.md`

- 统计 ADR 文件数量：`docs/architecture/adr-*.md`

- Count story files: `production/epics/**/*.md` (excluding EPIC.md)

- 统计故事文件数量：`production/epics/**/*.md`（排除 EPIC.md）

- `project.yaml` (`engine.name`) / `.claude/docs/technical-preferences.md` — engine configured?

- `project.yaml`（`engine.name`）/ `.claude/docs/technical-preferences.md` —— 引擎是否已配置？

- `docs/engine-reference/` — engine reference docs present?

- `docs/engine-reference/` —— 引擎参考文档是否存在？

- Glob `docs/adoption-plan-*.md` — note the filename of the most recent prior plan if any exist

- 用 Glob 匹配 `docs/adoption-plan-*.md` —— 若存在以往的规划，记下最近一份规划的文件名

### Infer phase (if no project.stage / stage.txt)

### 推断阶段（若无 project.stage / stage.txt）

Use the same heuristic as `/project-stage-detect`:

使用与 `/project-stage-detect` 相同的启发式规则：

- 10+ source files in the code root → Production

- 代码根目录中有 10 个以上源文件 → 制作阶段（Production）

- Stories in `production/epics/` → Pre-Production

- `production/epics/` 中存在故事 → 前期制作阶段（Pre-Production）

- ADRs exist → Technical Setup

- 存在 ADR → 技术准备阶段（Technical Setup）

- systems-index.md exists → Systems Design

- 存在 systems-index.md → 系统设计阶段（Systems Design）

- game-concept.md (or `design/game-brief.md`) exists → Concept

- 存在 game-concept.md（或 `design/game-brief.md`）→ 概念阶段（Concept）

- Nothing → Fresh (not a brownfield project — suggest `/start`)

- 什么都没有 → 全新项目（不是棕地项目 —— 建议运行 `/start`）

If the project appears fresh (no artifacts at all), use `AskUserQuestion`:

如果项目看起来是全新的（完全没有产物），使用 `AskUserQuestion`：

- "This looks like a fresh project — no existing artifacts found. `/adopt` is for
  projects with work to migrate. What would you like to do?"
  - "Run `/start` — begin guided first-time onboarding"
  - "My artifacts are in a non-standard location — help me find them"
  - "Cancel"

- "这看起来是一个全新项目 —— 未找到任何现有产物。`/adopt` 适用于有工作要迁移的项目。你想怎么做？"
  - "运行 `/start` —— 开始引导式首次上手"
  - "我的产物在非标准位置 —— 帮我找到它们"
  - "取消"

`/start` and Cancel end this skill: say which, and stop.

`/start` 和"取消"会结束本技能：说明选择的是哪一个，然后停止。

**If they pick "help me find them"**, search before asking anything else:

**如果他们选择"帮我找到它们"**，先搜索，再询问其他任何内容：

1. Search the folder they named, if they named one; otherwise the whole
   project, skipping `.claude/`, `.git/`, `docs/engine-reference/`,
   `studio-tests/`, `node_modules/` and the engine's build and
   cache folders.

1. 搜索他们指定的文件夹（如果他们指定了的话）；否则搜索整个项目，跳过 `.claude/`、`.git/`、`docs/engine-reference/`、`studio-tests/`、`node_modules/` 以及引擎的构建和缓存文件夹。

2. Glob `**/*.md` there, then Grep the matches for the headings each artifact
   carries: a GDD has `## Overview` with `## Detailed Rules` or
   `## Detailed Design`; an ADR `## Status` with `## Decision`; a story
   `## Acceptance Criteria` with a `Status` line; a concept doc
   `## Elevator Pitch` or `## Game Pillars`; a brief `## Core loop` with
   `## MVP`.

2. 在那里用 Glob 匹配 `**/*.md`，然后对匹配项执行 Grep，查找各类产物特有的标题：GDD 有 `## Overview` 以及 `## Detailed Rules` 或 `## Detailed Design`；ADR 有 `## Status` 以及 `## Decision`；故事有 `## Acceptance Criteria` 以及一行 `Status`；概念文档有 `## Elevator Pitch` 或 `## Game Pillars`；简报有 `## Core loop` 以及 `## MVP`。

3. Show what was found, grouped by type, each with the place every skill reads
   it from: GDD → `design/gdd/[name].md`; ADR →
   `docs/architecture/adr-NNNN-[name].md`; story →
   `production/epics/[epic]/story-NNN-[name].md`; concept →
   `design/gdd/game-concept.md`; brief → `design/game-brief.md`. If nothing
   matched, say so, name the folders and headings searched, and offer `/start`.

3. 按类型分组显示找到的内容，并附上每个技能读取它所在的位置：GDD → `design/gdd/[name].md`；ADR → `docs/architecture/adr-NNNN-[name].md`；故事 → `production/epics/[epic]/story-NNN-[name].md`；概念 → `design/gdd/game-concept.md`；简报 → `design/game-brief.md`。如果没有任何匹配，说明这一点，列出所搜索的文件夹和标题，并提供 `/start`。

4. Ask before moving anything — a move takes the file away from its old path,
   so it is a `file_deletions` decision: "May I move these [N] files to the
   standard folders?" — `[A] Move them all` / `[B] Let me pick which` /
   `[C] Don't move them — I'll do it myself`. Move with `git mv` in a git
   repository (the file's history follows it), plain `mv` otherwise. Never
   overwrite a file already at the target: name the clash and skip that file.
   Files are moved, never edited.

4. 在移动任何内容之前先询问 —— 移动会使文件离开其旧路径，因此这是一个 `file_deletions` 决定："我可以把这些 [N] 个文件移动到标准文件夹吗？" —— `[A] 全部移动` / `[B] 让我来选择` / `[C] 不要移动它们 —— 我自己来做`。在 git 仓库中使用 `git mv` 移动（文件历史会随之保留），否则使用普通 `mv`。绝不要覆盖目标位置已存在的文件：指出冲突并跳过该文件。文件只被移动，绝不被编辑。

5. After the moves, run Phase 1 again from the top, so the audit reads the files
   where every other skill will. With [C], print the moves as a list and stop.

5. 移动完成后，从头再次运行阶段 1，以便审计读取其他所有技能将要读取的文件位置。若选择 [C]，将移动操作以列表形式打印出来，然后停止。

Report: "Detected phase: [phase]. Found: [N] GDDs, [M] ADRs, [P] stories."

报告："检测到的阶段：[phase]。找到：[N] 个 GDD、[M] 个 ADR、[P] 个故事。"

---
