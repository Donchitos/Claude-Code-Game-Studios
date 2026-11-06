# /prototype — Phase 2: Load Concept Context
# /prototype — 第二阶段：加载概念上下文

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## Phase 2: Load Concept Context
## 第二阶段：加载概念上下文

Read `design/gdd/game-concept.md` — or `design/game-brief.md`, the one-page brief
that replaces it at `rigor: minimal` — if either exists. Read it by section: find the
headings you need with the Grep tool (pattern `^#`, content mode) and Read those
ranges with offset and limit. Extract:
- Core fantasy (what the player is supposed to feel)
- Core loop (the moment-to-moment action being tested)

如果任一文件存在，请阅读 `design/gdd/game-concept.md`——或者 `design/game-brief.md`，即在 `rigor: minimal` 下替代它的一页版简报。按章节阅读：用 Grep 工具（模式 `^#`，content 模式）找到你需要的标题，再用 offset 和 limit 读取这些区段。提取：
- 核心幻想（玩家应当感受到的东西）
- 核心循环（正在被测试的逐时逐刻的动作）

Determine the engine and language in use: read `engine.name` and
`engine.language` from `project.yaml`. For each field, if its key is absent or
empty (including when `project.yaml` has no `engine:` block), fall back to
`CLAUDE.md` and `.claude/docs/technical-preferences.md`. Treat a
`[TO BE CONFIGURED]` value as not set.

确定所使用的引擎和语言：从 `project.yaml` 读取 `engine.name` 和 `engine.language`。对于每个字段，如果其键缺失或为空（包括 `project.yaml` 中没有 `engine:` 块的情况），就回退到 `CLAUDE.md` 和 `.claude/docs/technical-preferences.md`。将 `[TO BE CONFIGURED]` 值视为未设置。

---
