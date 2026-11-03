# adopt — 存量项目棕地迁移审计（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/adopt/SKILL.md) ｜ 阶段：Any ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/adopt`，审计焦点参数：`full` ｜ `gdds` ｜ `adrs` ｜ `stories` ｜ `infra`（缺省 = `full`）
- **一句话职责**：棕地审计——存量项目的产物能否真正配合模板的技能管线（格式合规性），产出带编号的优先级迁移计划。
- **触发前置**：已有产物的存量项目接入工作流时。与 `/project-stage-detect` 的分工：后者答"有什么？"，本技能答"现有的东西**到底能不能用**？"——项目可以有 GDD、ADR 和 story，但只要内部格式不对，每个格式敏感的技能仍会静默失败或产出错误结果。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | resolve_config 预解析块：`review_mode`、`automation`、`automation_always_ask`、`workflow` | 运行前解析好、按原样使用 |
| 读取 | `project.yaml` 与遗留配置文件（**直接**原始检视） | 报告与写入迁移状态时用；这种原始检视是有意为之、独立于上述解析值之外 |
| 读取 | 分阶段引用文件（每阶段"read now and follow it"）：`references/1-detect.md`（探测项目状态）、`2-format-audit.md`（格式审计）、`3-classify.md`（缺口分类与排序）、`4-migration-plan.md`（构建迁移计划）、`5-summary.md`（展示摘要并请求写入）、`6-write.md`（写采纳计划）、`7-first-action.md`（提供首个行动） | SKILL.md 是调度器，七个阶段的步骤都在引用文件里；会话压缩或恢复后处于该阶段必须重读 |
| 读取 | `.claude/scripts/gdd-structure-check.sh`、`.claude/scripts/migrate-v1-config.sh --dry-run` | GDD 结构检查、v1 配置迁移试运行 |
| 产出 | `docs/adoption-plan-[date].md` —— 一份**持久的、可勾选**的迁移计划（写前必须征得同意） | 产物为"存在检查"之上的合规性审计结论 |
| 派生智能体 | 无，主会话直接执行 | — |

**配置解析**：`modes.automation` 解析链 `project.local.yaml` → `project.yaml` → 默认 `collaborative`；每次 AskUserQuestion 遵循 `.claude/docs/automation-modes.md`（collaborative 每次都问 · guided 只问重大 · autonomous 记录并推进；`automation_always_ask` 类别恒问）。`workflow` 档位框定 Phase 2 审计范围与 Phase 3 严重度：`full` 全结构审计所有文档类型；`standard` 只审必需文档/章节（可选章节是信息性的、不算缺口）；`minimal` 只做 `design/game-brief.md` 格式检查——GDD/ADR/UX 本就不被期望。

## 3. 核心规则（逐条编号 R1、R2……）
R1. 审计对象是**格式合规性**而非存在性：`/project-stage-detect` 查"有没有"，`/adopt` 查"格式敏感的技能读它会不会错"。（# Adopt 开篇）
R2. 七个阶段每一步都必须"Read `references/N-*.md` now and follow it"——该阶段步骤在引用文件里，不在本文件；会话被压缩或恢复后处于该阶段时必须重读。Phase 1 探测项目状态 → Phase 2 格式审计 → Phase 3 缺口分类与优先级 → Phase 4 构建迁移计划 → Phase 5 展示摘要并请求写入 → Phase 6 写采纳计划 → Phase 7 提供首个行动。（Phase 1–7）
R3. 审计焦点由参数决定：无参/`full` 全量审计（全部产物类型）；`gdds` 仅 GDD 格式合规；`adrs` 仅 ADR 格式合规；`stories` 仅 story 格式合规；`infra` 仅基础设施产物缺口（registry、manifest、sprint-status、stage.txt）。（Argument modes）
R4. 审计范围与严重度必须按解析出的 `workflow` 档位：`full` 按全结构审所有文档类型；`standard` 只审必需文档/章节，可选章节信息性、不算缺口；`minimal` 只查 `design/game-brief.md` 格式，GDD/ADR/UX 不在期望之内。（workflow 段）
R5. 产出必须是 `docs/adoption-plan-[date].md`——持久的、可勾选的迁移计划。（Output）

### 协作协议（描述 collaborative 默认模式的要求，非普适行为）
R6. 协作协议适用于 `collaborative`（默认）模式；`guided` 与 `autonomous` 见 `.claude/docs/automation-modes.md`。（Collaborative Protocol）
R7. **静默读完**——全部审计完成前不呈现任何东西。（1）
R8. **先展示摘要**——让用户先看清范围再请求写入。（2）
R9. **写前必须问**——创建采纳计划文件前始终确认。（3）
R10. **建议而非强迫**——计划是咨询性的；修什么、何时修由用户决定。（4）
R11. **一次只提一个行动**——交接计划后只提供一个具体下一步，不是六件事的清单。（5）
R12. **绝不重新生成既有产物**——只填补已有内容中的缺口；禁止重写已有内容的 GDD、ADR 或 story。（6）

## 4. 门禁与裁决
- 无门禁。裁决性规则：存在性 vs 合规性的分工（R1）、档位框定审计范围与严重度（R4）、"可选章节信息性不算缺口"的降级裁决、以及协作协议的写前确认（R9）与永不重写既有产物（R12）。

## 5. 移植建议
- **可直接移植**：R1–R2、R5、R7–R12——"存量接入先做格式合规审计而非存在性清单"、"调度器+按阶段引用文件"、"持久可勾选的迁移计划"、"静默读完、摘要先行、写前必问、一次一个行动、永不重写既有内容"，对任何"棕地项目迁入新工作流"的场景通用。
- **需替换概念**：GDD/ADR/story → 目标工作流所消费的格式敏感产物（模板、规格、工单等）；`registry/manifest/sprint-status/stage.txt` → 你的基础设施状态文件；`workflow` 档位 → 审计强度档位；`docs/adoption-plan-[date].md` → 目标项目的迁移计划存放处；`gdd-structure-check.sh`/`migrate-v1-config.sh --dry-run` → 你的格式校验与配置迁移试运行脚本。
- **改写示例**：
  - "迁移审计的对象是产物能否被流程工具正确消费（格式合规），不是产物是否存在；'存在但不合格式'必须按会静默失败的风险定级，而非计为完成。"
  - "产出迁移计划前必须完整审计、先出摘要征得同意才写文件；计划交接后只建议一个具体下一步，且禁止重写已有内容的产物，只填缺口。"

## 6. 关联文档
- 上游：`/start`（D 存量路径第 2 步点名本技能）
- 对比：`/project-stage-detect`（存在性）、`/help`（轻量导航）
- 引用 docs：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`
- 脚本：`.claude/scripts/gdd-structure-check.sh`、`.claude/scripts/migrate-v1-config.sh --dry-run`
- 阶段引用：`references/1-detect.md` ~ `references/7-first-action.md`
