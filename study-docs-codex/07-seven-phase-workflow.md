# 07 七阶段游戏开发工作流

## 1. 工作流总览

权威机器可读目录位于 `.claude/docs/workflow-catalog.yaml`。七个阶段是：

```text
Concept
  → Systems Design
  → Technical Setup
  → Pre-Production
  → Production
  → Polish
  → Release
```

`/help` 根据当前阶段和工件存在性推荐下一步，`/gate-check` 检查能否进入下一阶段。Gate 是建议，不自动替用户推进。

## 2. 各阶段目标与主要工件

| 阶段 | 核心问题 | 关键命令 | 主要工件 |
|---|---|---|---|
| Concept | 做什么游戏、为谁、核心体验是什么？ | `/brainstorm`、`/setup-engine`、`/art-bible`、`/map-systems` | game concept、art bible、systems index |
| Systems Design | 每个系统的规则、公式、边界是什么？ | `/design-system`、`/design-review`、`/review-all-gdds` | 每系统 GDD、跨 GDD 审查 |
| Technical Setup | 如何在指定引擎中可靠实现？ | `/create-architecture`、`/architecture-decision`、`/architecture-review`、`/create-control-manifest` | architecture、ADRs、TR registry、control manifest |
| Pre-Production | 体验和生产方案是否足够成熟？ | `/ux-design`、`/prototype`、`/vertical-slice`、`/create-epics`、`/create-stories`、`/sprint-plan` | UX specs、原型/切片报告、Epics、Stories、首个 Sprint |
| Production | 如何按故事稳定交付？ | `/dev-story`、`/code-review`、`/story-done`、`/qa-plan` | 游戏代码、测试、故事状态、Sprint 记录 |
| Polish | 性能、平衡、资产和体验是否达标？ | `/perf-profile`、`/balance-check`、`/asset-audit`、`/playtest-report`、`/team-polish` | 性能报告、3 次以上试玩记录、修复清单 |
| Release | 是否具备发布和运营条件？ | `/release-checklist`、`/launch-checklist`、`/changelog`、`/patch-notes` | 发布检查、变更日志、补丁说明 |

## 3. Concept 与 Systems Design

概念阶段先定义核心幻想、支柱、目标审美和范围，再把概念拆成系统依赖图。不要在只有一句玩法想法时立刻写生产代码。

每个正式 GDD 包含八部分：Overview、Player Fantasy、Detailed Rules、Formulas、Edge Cases、Dependencies、Tuning Knobs、Acceptance Criteria。系统按 Foundation → Core → Feature → Presentation → Polish 顺序设计。

“闪避方块”可拆为：

- Foundation：输入、时间、碰撞；
- Core：玩家移动、障碍生成、胜负判定；
- Presentation：HUD、音效、反馈；
- Polish：难度曲线和视觉效果。

## 4. Technical Setup

这一阶段把“游戏规则”转成“工程决策”：

- Master Architecture 给出模块与数据流；
- ADR 记录为什么选某个方案及其代价；
- TR Registry 为技术要求分配稳定 ID；
- Control Manifest 把已接受 ADR 压成程序员可直接遵守的 Required/Forbidden/Guardrails。

最低要求不是“写几篇文档”，而是关键 GDD 要求能追踪到明确技术决定。

## 5. Prototype 与 Vertical Slice

这两个概念容易混淆：

| 项目 | Prototype | Vertical Slice |
|---|---|---|
| 时机 | 早期概念阶段 | 架构和 GDD 之后的预制作阶段 |
| 目的 | 验证核心假设是否有趣 | 验证端到端生产质量和完整循环 |
| 代码质量 | 可丢弃，规则放宽 | 接近生产质量 |
| 决策 | Proceed / Pivot / Kill | 是否有条件进入全面 Production |

不要把“做出来能跑”误认为 Vertical Slice。切片必须覆盖一个完整玩家循环，并验证内容、UX、技术和制作流程能共同交付。

## 6. Story 生命周期

```text
GDD + ADR + TR
      │
      ▼
/create-epics
      ▼
/create-stories
      ▼
/story-readiness
      ▼
/dev-story ──► 实现 + 测试证据
      ▼
/code-review
      ▼
/story-done
      ▼
下一条 READY Story
```

`/dev-story` 不应成为“根据一句话随意编码”的入口。它检查依赖 Story 是否完成、TR 文本是否最新、ADR 是否已接受、Manifest 版本是否过期，并按文件/系统路由到程序专家和引擎专家。

## 7. Gate 的使用方式

在阶段末运行：

```text
/gate-check systems-design
/gate-check technical-setup
/gate-check pre-production
/gate-check production
/gate-check polish
/gate-check release
```

Gate 从三个维度给结论：

- Required Artifacts：必需文件是否存在；
- Quality Checks：文档、测试和状态是否达到标准；
- Director Panel：创意、技术、生产、视觉是否 READY。

即便结论为 PASS，也要由用户确认后才写入新阶段。CONCERNS 表示可以带风险推进，FAIL 表示应先解决阻塞。

## 8. Brownfield 路径

已有项目不要从头重做：

1. `/project-stage-detect` 判断实际阶段和缺口；
2. `/adopt` 检查已有 GDD、ADR、Story 是否符合框架内部格式；
3. `/design-system retrofit <path>` 填缺失章节，不覆盖有效内容；
4. `/reverse-document` 从代码/原型恢复设计或架构；
5. `/gate-check` 验证迁移后的阶段完整性。

## 本课练习

为“闪避方块”写一张阶段工件清单，每阶段只保留最小必要内容。若你能解释为什么“碰撞公式”属于 GDD、“碰撞 API 选择”属于 ADR、“实现碰撞组件”属于 Story，就掌握了主流程的分层。

