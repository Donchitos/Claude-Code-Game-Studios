---
name: setup-engine
description: "Configure engine and version. Pins it in CLAUDE.md; WebSearch fills reference docs when the version is beyond LLM training data."
argument-hint: "[engine] | [engine version] | refresh | upgrade [old-version] [new-version] | no args for guided selection"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/setup-engine/../../hooks/yaml-helper.sh" resolve_config *), Bash(godot --version), Bash(godot --headless --path . --import), Bash(command -v godot), Bash(uname -s), Bash(bash .claude/scripts/project-coherence.sh*)
model: sonnet
---

---
name: setup-engine
description: "配置引擎及其版本。在 CLAUDE.md 中固定它；当版本超出 LLM 训练数据时，用 WebSearch 填充参考文档。"
argument-hint: "[engine] | [engine version] | refresh | upgrade [old-version] [new-version] | no args for guided selection"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/setup-engine/../../hooks/yaml-helper.sh" resolve_config *), Bash(godot --version), Bash(godot --headless --path . --import), Bash(command -v godot), Bash(uname -s), Bash(bash .claude/scripts/project-coherence.sh*)
model: sonnet
---

# Engine Setup

When this skill is invoked:

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow`

**Tier awareness.** The `workflow` tier resolved above governs which design
artifact this skill expects and the finish path it recommends in §12:
- **`minimal`** — the design artifact is the one-page `design/game-brief.md`
  (no GDDs, systems decomposition, or per-system design at this tier).
  `/setup-engine` runs *first* in the minimal path, so a missing brief here is
  normal, not a gap. The finish path is the 4-step floor.
- **`standard` / `full`** — the design artifact is `design/gdd/game-concept.md`
  and the finish path is the full pipeline.

If the block did not render (shell preprocessing disabled), assume `minimal` (the default).

# 引擎设置

当本技能被调用时：

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow`

**档位感知。** 上面解析出的 `workflow` 档位决定本技能预期哪一份设计
资产，以及它在 §12 中推荐的收尾路径：
- **`minimal`** —— 设计资产是一页的 `design/game-brief.md`
  （该档位下没有 GDD、系统拆解或逐系统设计）。
  `/setup-engine` 在 minimal 路径中*最先*运行，因此这里缺失简报是
  正常的，不算缺口。收尾路径是 4 步下限。
- **`standard` / `full`** —— 设计资产是 `design/gdd/game-concept.md`，
  收尾路径是完整流水线。

如果该配置块未渲染（shell 预处理被禁用），假定为 `minimal`（默认值）。

## 1. Parse Arguments

Four modes:

- **Full spec**: `/setup-engine godot 4.7` — engine and version provided
- **Engine only**: `/setup-engine unity` — engine provided, version will be looked up
- **No args**: `/setup-engine` — fully guided mode (engine recommendation + version)
- **Refresh**: `/setup-engine refresh` — update reference docs (see Section 10)
- **Upgrade**: `/setup-engine upgrade [old-version] [new-version]` — migrate to a new engine version (see Section 11)

---

## 1. 解析参数

四种模式：

- **完整规格**：`/setup-engine godot 4.7` —— 已提供引擎和版本
- **仅引擎**：`/setup-engine unity` —— 已提供引擎，版本将被查询
- **无参数**：`/setup-engine` —— 完全引导模式（引擎推荐 + 版本）
- **刷新**：`/setup-engine refresh` —— 更新参考文档（见第 10 节）
- **升级**：`/setup-engine upgrade [old-version] [new-version]` —— 迁移到新的引擎版本（见第 11 节）

---

## 2. Guided Mode (No Arguments)

**Read `references/2-guided-mode.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 2. 引导模式（无参数）

**现在读取 `references/2-guided-mode.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 3. Look Up Current Version

**Read `references/3-version.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 3. 查询当前版本

**现在读取 `references/3-version.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 4. Update CLAUDE.md Technology Stack

**Read `references/4-claude-md-stack.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. 更新 CLAUDE.md 技术栈

**现在读取 `references/4-claude-md-stack.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 5. Populate Technical Preferences

**Read `references/5-technical-preferences.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5. 填充技术偏好

**现在读取 `references/5-technical-preferences.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 5.5 Populate `project.yaml` (Primary Config Store)

**Read `references/5.5-project-yaml.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5.5 填充 `project.yaml`（主配置存储）

**现在读取 `references/5.5-project-yaml.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 6. Determine Knowledge Gap

**Read `references/6-knowledge-gap.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. 确定知识缺口

**现在读取 `references/6-knowledge-gap.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 7. Populate Engine Reference Docs

**Read `references/7-reference-docs.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 7. 填充引擎参考文档

**现在读取 `references/7-reference-docs.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 7.5 Scaffold the Engine Project

**Read `references/7.5-scaffold.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 7.5 搭建引擎项目骨架

**现在读取 `references/7.5-scaffold.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 8. Verify the CLAUDE.md Import

**Read `references/8-verify.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 8. 验证 CLAUDE.md 导入

**现在读取 `references/8-verify.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 9. Update Agent Instructions

Ask: "May I add a Version Awareness section to the engine specialist agent files?" before making any edits.

For the chosen engine's specialist agents, verify they have a
"Version Awareness" section. If not, add one following the pattern in
the existing Godot specialist agents.

The section should instruct the agent to:
1. Read `docs/engine-reference/<engine>/VERSION.md`
2. Check deprecated APIs before suggesting code
3. Check breaking changes for relevant version transitions
4. Use WebSearch to verify uncertain APIs

---

## 9. 更新智能体指令

在做出任何编辑之前询问："我可以向引擎专家智能体文件添加一个版本感知（Version Awareness）章节吗？"

对于所选引擎的专家智能体，验证它们具有
"Version Awareness" 章节。如果没有，则依照
现有 Godot 专家智能体的模式添加一个。

该章节应指示智能体：
1. 读取 `docs/engine-reference/<engine>/VERSION.md`
2. 在建议代码前检查已弃用的 API
3. 检查相关版本迁移中的破坏性变更
4. 用 WebSearch 验证不确定的 API

---

## 10. Refresh Subcommand

If invoked as `/setup-engine refresh`:

1. Read the existing `docs/engine-reference/<engine>/VERSION.md` to get
   the current engine and version
2. Use WebSearch to check for:
   - New engine releases since last verification
   - Updated migration guides
   - Newly deprecated APIs
3. Update all reference docs with new findings
4. Update "Last verified" dates on all modified files
5. Report what changed

---

## 10. 刷新子命令

如果以 `/setup-engine refresh` 调用：

1. 读取既有的 `docs/engine-reference/<engine>/VERSION.md`，获取
   当前引擎和版本
2. 用 WebSearch 检查：
   - 自上次验证以来新的引擎发布
   - 更新的迁移指南
   - 新近弃用的 API
3. 用新发现更新所有参考文档
4. 更新所有被修改文件的"Last verified"日期
5. 报告改动了什么

---

## 11. Upgrade Subcommand

**Read `references/11-upgrade.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 11. 升级子命令

**现在读取 `references/11-upgrade.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## 12. Output Summary

**Read `references/12-output-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 12. 输出摘要

**现在读取 `references/12-output-summary.md` 并遵循它** —— 该阶段的步骤在那个文件里，不在这里。如果对话在此阶段中被压缩或恢复，再读一次。

## Guardrails

- NEVER guess an engine version — always verify via WebSearch or user confirmation
- `project.yaml` is the primary config store (v1.1). Always dual-write engine
  config to BOTH `project.yaml` (primary) and `technical-preferences.md` (legacy
  mirror). If the two ever diverge, `project.yaml` is authoritative.
- NEVER overwrite existing reference docs without asking — append or update
- If reference docs already exist for a different engine, ask before replacing
- Always show the user what you're about to change before making CLAUDE.md edits
- If WebSearch returns ambiguous results, show the user and let them decide
- When the user chose **GDScript**: copy the GDScript CLAUDE.md template from **A1** in `references/godot-language-config.md` exactly. NEVER add "C++ via GDExtension" to the Language field. GDScript projects may use GDExtension, but it is not a primary project language. The `godot-gdextension-specialist` in the routing table is available for when native extensions are needed — it does not make C++ a project language.

---

## 护栏

- 绝不猜测引擎版本 —— 始终通过 WebSearch 或用户确认来验证
- `project.yaml` 是主配置存储（v1.1）。始终把引擎配置同时双写到
  `project.yaml`（主）和 `technical-preferences.md`（旧版
  镜像）。如果两者出现分歧，`project.yaml` 是权威。
- 未经询问绝不覆盖既有参考文档 —— 追加或更新
- 如果已存在其他引擎的参考文档，替换前先询问
- 在编辑 CLAUDE.md 之前，始终向用户展示你即将更改的内容
- 如果 WebSearch 返回模糊结果，展示给用户并让他们决定
- 当用户选择 **GDScript** 时：完全照抄 `references/godot-language-config.md` 中 **A1** 的 GDScript CLAUDE.md 模板。绝不在 Language 字段中添加"C++ via GDExtension"。GDScript 项目可以使用 GDExtension，但它不是项目的主要语言。路由表中的 `godot-gdextension-specialist` 在需要原生扩展时可用 —— 它并不会让 C++ 成为项目语言。

---

## Appendix A — Godot Language Configuration

Moved out of this file so it costs nothing on non-Godot runs.

**When the chosen engine is Godot, read**
`references/godot-language-config.md`
and use the subsection for the chosen language:

- **A1** — CLAUDE.md Technology Stack templates (GDScript / C# / Both)
- **A2** — naming conventions
- **A3** — engine specialist routing and file-extension tables

**Load discipline.** On any engine other than Godot, **never load it** — nothing in Sections 4, 5 or 5.5 needs it, and reading it anyway spends the tokens the split exists to save. On Godot, read it once when you first reach Section 4 and keep using it for Sections 5 and 5.5; do not re-read it at each reference.

## 附录 A —— Godot 语言配置

已从本文件移出，以便在非 Godot 运行中不产生任何开销。

**当选定的引擎是 Godot 时，读取**
`references/godot-language-config.md`
并使用所选语言对应的小节：

- **A1** —— CLAUDE.md 技术栈模板（GDScript / C# / Both）
- **A2** —— 命名约定
- **A3** —— 引擎专家路由和文件扩展名表

**加载纪律。** 在除 Godot 之外的任何引擎上，**绝不加载它** —— 第 4、5 或 5.5 节都不需要它，无论如何读取它都会花掉拆分本就是为了节省的 token。在 Godot 上，首次进入第 4 节时读一次，并在第 5 和 5.5 节继续使用它；不要在每个引用点重读。
