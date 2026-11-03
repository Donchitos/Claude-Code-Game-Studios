# changelog — 内部技术变更日志（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/changelog/SKILL.md) ｜ 阶段：Phase 7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/changelog [version|sprint-number]`
- **一句话职责**：从 git 提交历史与冲刺数据生成**双份**变更日志——内部技术版（含 commit 哈希、Owner、指标）与玩家版（体验视角），先经溯源检查证明历史属于本项目。
- **触发前置**：自动化模式经 resolve_config 解析（`automation`），遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续）；git 仓库已初始化且有提交历史。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 技能头自动注入的两块历史：`git log --oneline -30`、`git tag --list --sort=-v:refname \| head -5`（技能体运行**之前**已求值——读取已发生，检查只管输出可用性） | 起点，禁止重复跑同样命令 |
| 读取 | `git log --oneline [last-tag]..HEAD`（无 tag 时 `-n 100`）；`git rev-parse --is-inside-work-tree`（仓库验证） | 变更数据源 |
| 读取 | `production/sprints/` 相关时段冲刺报告；`design/gdd/` 本时段实现的新特性**完成**设计文档（按节读：Grep 标题 `^#` content 模式，再用 offset/limit 读所需区间）；commit 消息中的任务引用（`[STORY-123]`、`TR-`、`#NNN` 或类似） | 计划工作与变更语境；无界整读禁止 |
| 读取 | `design/` 与代码根（`src/`、`Assets/`、`Source/`）——用于溯源交叉验证 | 确认 Game commit 点名的系统真实存在 |
| 产出 | 会话内输出双份日志；用户同意后写/追加 `docs/CHANGELOG.md`（新条目置顶，最新在前） | 内部版为主工作文档；玩家版评审后可发社区 |
| 派生智能体 | 无，主会话直接执行 | |

## 3. 核心规则（逐条编号 R1、R2……）

### 溯源检查（Provenance check）
R1. **注入的历史可能根本不属于这个游戏**。读注入的提交 subject：**一个都没有（log 空或 git 不可用）→ 跳过本检查**——没有可分类的东西，Phase 1 的无历史分支才是正确停靠。（Provenance）
R2. 否则**逐条分类**为三类：**Game**（机制、内容、平衡、美术、音频、UI，或它们中的 bug）；**Framework / maintenance**（subject 点名 skills、hooks、agents、测试计划、CI 或框架自身文档）；**Unclear**——**按 Framework 处理**。（Provenance）
R3. 按计数决定：**至少一个 Game commit** → 只用它们继续，并说明共几条中用了几条；**零 Game commit** → 停，用原文消息（"The git history in this repo does not appear to belong to [game]: 0 of the [N] recent commits are Game commits…point me at the right history, or supply the change list directly."）。Verdict: **BLOCKED**——不生成 changelog。（Provenance）
R4. **逐条过滤；含维护工作的仓库不是错仓库**：每个基于本框架的项目都会积累动 hooks/CI/skills 的提交——游戏仓库*就是*框架仓库，对它们停会误伤几乎每个真实项目；危害是这些提交变成发布文案，逐条排除正好防止它。本规则与 `/patch-notes` 的**有意保持一致**——两个技能为不同受众读同一段历史，不得对"这是谁的历史"意见相左；要改一起改。（Provenance）
R5. 真正的**错误历史信号**不同：Game commit 点名一个 `design/` 与代码根从未提及的产品——见到即停。**禁止把 preamble 的存在当证据**：注入输出只证明命令跑了，不证明它的 subject 是你的游戏。这是硬停不是警告的理由：框架内部提交渲染成玩家文案读起来像真改动——session-hook 超时会变成 *"Fixed an issue where progress from your last session could be lost on launch"*，而这游戏**没有存档系统**——流畅、可信、全假；读者分不出来，只有这道检查能。（Provenance）

### Phase 1-3 — 参数、取数与分类
R6. 参数为目标版本或冲刺号：版本 → 对应 git tag；冲刺号 → 冲刺日期范围。验证仓库已初始化（`git rev-parse --is-inside-work-tree`），非 git 仓库 → 告知用户并优雅中止。**无历史可读**（非 git 仓库或零提交）→ 输出 "No git history found. A changelog is built from commits — commit the work first, or supply the change list directly." Verdict: **BLOCKED**。（Phase 1）
R7. 读上个 tag 以来的 log：`git log --oneline [last-tag]..HEAD`。无 tag 时**显式限定** `git log --oneline -n 100`——**禁止回退到全量 log**：成熟仓库上那是几千行而 changelog 只覆盖一个版本，最老的最不相关；100 条不够时**说出来并向用户要一个 start ref**，而非盲目加宽。（Phase 2）
R8. 每条变更归入一类：**New Features**（全新玩法系统、模式、内容）；**Improvements**（既有功能增强、UX 改进、性能提升）；**Bug Fixes**（修坏掉的行为）；**Balance Changes**（调玩法数值、难度、经济）；**Technical Debt / Refactoring**（重构与清理——**玩家看不见任何变化**的提交：自称 refactor/clean up/tidy 且不点名 fix、feature 或 tuning 的——**仅内部日志，绝不进玩家版**）；**Known Issues**（已知未解决）；**Miscellaneous**（不匹配以上，或 commit 消息太糊无法自信分类）。（Phase 3）
R9. 每条 commit 检查消息是否含任务 ID 或故事引用（`[STORY-123]`、`TR-`、`#NNN` 或类似）；统计无任何任务引用的提交数，进 Metrics 节：`Commits without task reference: [N]`。（Phase 3）

### Phase 4-6 — 双份生成与输出
R10. **内部 changelog** 固定结构：`# Internal Changelog: [Version]` + Date / Sprint(s) / Commits（`[Count] ([first-hash]..[last-hash])`）；New Features（技术描述 + 受影响系统 + Commits + Owner + Design doc 链接）；Improvements（改了什么、为何 + Commits + Owner）；Bug Fixes（`[BUG-ID]` 描述与根因 + Fix + Commits + Owner）；Balance Changes（`[What] -- [Old value -> New value] -- [Design intent]` + Owner）；Technical Debt / Refactoring（清理了什么、为何 + Commits）；Miscellaneous；Known Issues（描述 -- Severity -- 已知则 ETA）；**Metrics**（Total commits、Files changed、Lines added、Lines removed、Commits without task reference）。（Phase 4）
R11. **玩家版** `# What is New in [Version]`：New Features 用加粗特性名 + 玩家视角描述（现在能做什么、为何兴奋——聚焦体验不是实现）；Improvements（具体但不术语）；Bug Fixes 用 "Fixed an issue where [玩家经历的症状，不是代码哪里错了]"；Balance Changes 用玩家能懂的措辞 + 设计意图（原文示例："Healing potions now restore 50 HP (up from 30) -- we felt players needed more recovery options in late-game encounters."）；Known Issues（玩家措辞 + 有则 workaround）；结尾感谢与反馈链接。（Phase 5）
R12. 两版都输出给用户：内部版是主工作文档；玩家版经评审后即可发社区。（Phase 6）

### Phase 7 — 写盘与下一步（源文件有两个 Phase 7，编号重复系原文如此）
R13. 展示后问 "May I write this changelog to `docs/CHANGELOG.md`?" 选项：`[A] Yes, append this entry`（文件已存在时推荐）/ `[B] Yes, overwrite the file entirely` / `[C] No — I'll copy it manually`。**问之前先查文件是否存在**，存在则默认推荐 append。[A] → 新内部条目追加到文件**顶部**（最新在前）；[B] → 整文件覆写；[C] → 停，不写。写成功 → Verdict: **CHANGELOG WRITTEN**；用户拒绝 → Verdict: **COMPLETE** — changelog generated。（Phase 7）
R14. 下一步：用 `/patch-notes [version]` 生成对外发布的定稿存档版；对外发布 changelog 前先跑 `/release-checklist`。（Phase 7）
R15. **Guidelines**：玩家版**绝不暴露**内部代码引用、文件路径或开发者名；相关变更分组而非逐条 commit 罗列；commit 消息不清 → 查相关文件与冲刺数据定语境；平衡变更必须带设计理由而不只是数字；Known issues 要诚实——玩家赏识透明；历史脏（merge/revert/fixup 提交）→ 清理叙事而非逐字罗列每条提交。（Guidelines）

## 4. 门禁与裁决
- **Verdict**：`BLOCKED`（溯源零 Game commit，或无历史可读）/ `CHANGELOG WRITTEN` / `COMPLETE`（生成但未写盘）。
- **溯源硬门禁**：零 Game commit 即 BLOCKED——不是警告；维护提交从发布文案中**排除**但不触发停（逐条过滤，不做仓库级判定）。
- **消费方**：`/patch-notes`（读内部 changelog 产玩家版）、`/release-checklist`（发布门禁会查 changelog 是否起草）。

## 5. 移植建议
- **可直接移植**：R1-R5（提交溯源三分类、逐条过滤不做仓库级判定、Unclear 按维护处理、"注入输出≠证据"、与姊妹技能规则同步演化）、R7（无 tag 时显式限 100 条并要 start ref，禁止全量 log）、R8（"玩家不可见"类目仅进内部版）、R13（写盘三选项 + 存在性检查定推荐）。
- **需替换概念**：Framework/maintenance 提交 → 任何"工具链/CI/脚手架"类提交（平台仓库与产品仓库同库的项目尤其需要）；`[STORY-123]`/`TR-` → 项目的工单/需求 ID 体系；sprint 报告 → 迭代记录；GDD → 需求文档；`/patch-notes`、`/release-checklist` → 对应发布流程。
- **改写示例**：
  - R3 → "从提交历史生成任何对外文案前，先逐条分类提交为'产品改动/工具链维护/无法判断'三类；零条产品提交即 BLOCKED 并报出 0/N 计数，禁止把维护提交渲染成产品变更。"
  - R7 → "取变更数据时必须显式限定范围：有基准 tag 用 `[last-tag]..HEAD`，没有则限定最近 N 条；N 条不够时向用户要起点引用，禁止回退到全量历史。"

## 6. 关联文档
- 上游：`/sprint-plan`、`/dev-story`、`/story-done`（产生提交与冲刺报告的流程）。
- 下游：`/patch-notes`（以内部 changelog 为数据源产玩家版）、`/release-checklist`（发布门禁查 changelog）。
- 引用：`.claude/docs/automation-modes.md`；其溯源规则与 `/patch-notes` **成对维护**（改一起改）。
