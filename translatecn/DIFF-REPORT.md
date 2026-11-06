# 文档体系差异报告：原版 → 当前版本
# Documentation System Diff Report: Original → Current

> **生成日期**：2026-10-29  
> **目的**：帮助你从旧版目录结构和文档功能理解新版变化——哪些被删了、哪些挪了位置、哪些是全新引入的、哪些只是内容重译。  
> **译文位置**：所有现行文档的中英对照译文位于 `translatecn/` 目录，镜像下方的原始路径。

---

## 一、总览 / Summary

| 维度 | 原版 | 当前版 | 变化 |
|------|------|--------|------|
| 根目录 md | 5 | 6 | +1（新增 CHANGELOG.md） |
| docs/ md | 52（含 examples 11） | 51 | -1（examples 目录整体移除） |
| .claude/docs/ md | 60 | 128 | +68（新增 director-gates/ 28 个、模板扩展 30+、顶层 10 个） |
| .claude/agents/ md | 49 | 49 | 0（数量不变，内容全部重译） |
| .claude/skills/ md | 73（仅 SKILL.md） | 186 | +113（新增 1 技能 + 7 CONTRACT + 105 references） |
| **合计** | **239** | **420** | **+181** |

一句话总结：**模板和技能体系大幅扩展，门禁提示词从单文件拆成 28 份独立文档，examples 示例目录整体下线，新增了配置解析/模型层级/自动化模式等一批底层指南**。

---

## 二、删除的文档 / Removed

### 2.1 docs/examples/ — 整个目录移除（11 个）

原路径：`docs/examples/`

这些是之前的"协作会话示例"（session walkthrough），新版已不再维护。想看实际流程，可以读 WORKFLOW-GUIDE.md 里的阶段描述和各 skill 的 SKILL.md 里的使用示例。

| 已删除文件 | 原功能 |
|------------|--------|
| examples/README.md | 示例目录索引 |
| examples/reverse-document-workflow-example.md | 反向文档工作流示例 |
| examples/session-adopt-brownfield.md | /adopt 接入遗留项目会话 |
| examples/session-design-crafting-system.md | 设计制作系统会话 |
| examples/session-design-system-skill.md | /design-system 写 GDD 会话 |
| examples/session-gate-check-phase-transition.md | /gate-check 阶段转换会话 |
| examples/session-implement-combat-damage.md | 实现战斗伤害计算会话 |
| examples/session-scope-crisis-decision.md | 范围危机决策会话 |
| examples/session-story-lifecycle.md | 完整故事生命周期会话 |
| examples/session-ux-pipeline.md | UX 管线会话 |
| examples/skill-flow-diagrams.md | 技能流程图（**已移动到 docs/ 根目录**，见第三节） |

### 2.2 .claude/docs/ — 顶层移除 2 个

| 已删除文件 | 原功能 | 去向 |
|------------|--------|------|
| review-workflow.md | 4 步评审工作流 | **内容被吸收**进 quick-start.md 和各 director-gates 提示词，不再单独成文 |
| agent-coordination-map.md | 完整组织架构/委托规则/9 种协作模式 | **内容被吸收**进 coordination-rules.md + agent-roster.md + 各 director-gates.md |

### 2.3 .claude/docs/templates/ — 删除 4 个

| 已删除文件 | 原功能 | 去向 |
|------------|--------|------|
| templates/skill-test-spec.md | 技能测试规格模板 | **被 skill-test 技能的 SKILL.md 内嵌**，模板不再独立存在 |
| templates/collaborative-protocols/ 整个子目录 | 3 份协作协议模板（design-agent-protocol, leadership-agent-protocol, implementation-agent-protocol） | **内容被吸收**进各 agent 定义文件的 persona 段落和 COLLABORATIVE-DESIGN-PRINCIPLE.md |

---

## 三、移动的文档 / Relocated

只有 1 例：

| 原路径 | 新路径 | 说明 |
|--------|--------|------|
| `docs/examples/skill-flow-diagrams.md` | `docs/skill-flow-diagrams.md` | 从 examples 子目录提升到 docs 根，与 WORKFLOW-GUIDE.md 平级，作为工作流参考资源而非示例 |

---

## 四、新增的文档 / Added

### 4.1 根目录（1 个）

| 新文件 | 功能 |
|--------|------|
| CHANGELOG.md | 完整版本历史，从 v1.0.0 到最新版本的 Added / Changed / Fixed / Removed / Deprecated |

> 旧版变更散落在 UPGRADING.md 里，现在独立成 CHANGELOG.md，UPGRADING.md 只讲迁移操作。

### 4.2 docs/（1 个 + 1 个从 examples 移入）

| 新文件 | 功能 |
|--------|------|
| migration-guide-v1.1.md | v1.0 → v1.1 project.yaml 迁移指南，讲如何把旧 project.yaml 之外的遗留配置文件（stage.txt、review-mode.txt、technical-preferences.md）合并到新格式 |
| skill-flow-diagrams.md | 技能流程图（从 examples/ 移入），展示最小/标准/严格工作流下各技能链的调用路径 |

### 4.3 .claude/docs/ 顶层新增 10 个

旧版 `.claude/docs/` 有 14 个顶层文件，现在有 24 个，新增如下：

| 新文件 | 功能定位 | 简述 |
|--------|----------|------|
| **model-tiers.md** | 底层机制 | Opus/Sonnet/Haiku 三个模型层级何时被调用、技能的 `model:` 如何覆盖会话模型、自动模式是否支持 Haiku |
| **agent-teams.md** | 团队协作 | `/team-*` 技能如何组建多智能体团队并行协作、团队结构与调度 |
| **workflow-modes.md** | 工作流 | minimal / standard / full 三种严格度模式的差异与切换 |
| **automation-modes.md** | 自动化 | collaborative / permissionless / always-ask 三种自动化模式的门禁行为差异 |
| **config-resolution.md** | 配置解析 | project.yaml、project.local.yaml、命令行覆盖值的合并优先级规则 |
| **code-root-resolution.md** | 代码根目录 | 如何定位 src/、prototypes/、docs/ 等关键目录的根 |
| **error-recovery-protocol.md** | 故障恢复 | 会话崩溃、上下文丢失、写文件失败等异常下的标准恢复步骤 |
| **run-and-observe.md** | 运行观察 | 如何运行项目并让智能体观察行为（日志、截图、性能指标） |
| **settings-guidance.md** | 设置指南 | 项目.yaml 各字段的说明与推荐值 |
| **effects-map.md** | 效果映射 | 架构影响矩阵——改某文件会波及哪些智能体、哪些门禁、哪些技能 |

### 4.4 .claude/docs/director-gates/ — 全新子目录（28 个）

旧版门禁提示词全部塞在 `director-gates.md` 一个长文件里，现在拆成 **28 个独立 prompt 文件**，放在 `director-gates/` 子目录。配合 `director-gates.md` 顶层文件的索引使用。

**命名规则**：`{团队缩写}-{门禁主题}.md`

| 团队缩写 | 所属总监/主管 | 文件数 | 示例 |
|----------|--------------|--------|------|
| CD | creative-director（创意总监） | 7 | cd-pillars.md、cd-systems.md、cd-narrative.md、cd-gdd-align.md、cd-playtest.md、cd-phase-gate.md |
| TD | technical-director（技术总监） | 9 | td-architecture.md、td-adr.md、td-phase-gate.md、td-engine-risk.md、td-feasibility.md、td-manifest.md、td-change-impact.md、td-system-boundary.md |
| AD | art-director（美术总监） | 4 | ad-art-bible.md、ad-visual.md、ad-concept-visual.md、ad-phase-gate.md |
| LP | lead-programmer（首席程序员） | 2 | lp-feasibility.md、lp-code-review.md |
| PR | producer（制作人） | 7 | pr-scope.md、pr-phase-gate.md、pr-milestone.md、pr-epic.md、pr-sprint.md |
| QL | qa-lead（QA 主管） | 2 | ql-test-coverage.md、ql-story-ready.md |
| ND | narrative-director（叙事总监） | 1 | nd-consistency.md |

> **28 = 7 CD + 9 TD + 4 AD + 2 LP + 7 PR + 2 QL + 1 ND**

### 4.5 .claude/docs/templates/ — 新增 34 个，删除 4 个，净增 30 个

#### 新增模板（26 个主模板）

| 新模板 | 功能 |
|--------|------|
| **game-brief.md** | 游戏简报——最小工作流层级下的单页设计文档，替代完整 GDD |
| **patch-notes-brief.md** | 补丁说明简报（单行） |
| **patch-notes-commentary.md** | 补丁说明详注 |
| **quick-design-tuning.md** | 快速设计——调整现有系统 |
| **quick-design-change.md** | 快速设计——变更现有设计 |
| **quick-design-new-system.md** | 快速设计——新建系统 |
| **certification-none.md** | 无认证平台发布清单 |
| **certification-itch.md** | Itch.io 发布清单 |
| **certification-steam.md** | Steam 发布清单 |
| **certification-console.md** | 主机平台（Xbox/PS/Switch）发布清单 |
| **certification-unknown.md** | 未知平台发布清单 |
| **help-escalation.md** | 帮助请求升级模板 |
| **help-where-you-are.md** | 帮助——"你现在在哪"状态查询 |
| **help-where-you-are-minimal.md** | 帮助——精简版状态查询 |
| **bug-report.md** | Bug 报告模板 |
| **bug-closure-record.md** | Bug 关闭记录 |
| **session-state.md** | 会话状态记录（机器可读） |
| **story.md** | 故事模板（替代旧版 create-stories 的嵌入式模板） |
| **adoption-summary.md** | /adopt 接入摘要 |
| **adoption-plan.md** | /adopt 迁移计划 |
| **changelog-internal.md** | 内部变更日志 |
| **launch-checklist.md** | 发布前检查清单 |
| **release-platform-requirements.md** | 各平台发布要求 |
| **soak-test-protocol.md** | 浸泡测试协议 |
| **start-paths.md** | /start 的五条起始路径定义 |
| **SKILL-CONTRACT-TEMPLATE.md** | 技能契约模板（各 CONTRACT.md 的基底） |

#### 新增 guidance/ 子目录（8 个引导文档）

这是模板的"怎么用"指南，放在 `templates/guidance/` 下：

| 新引导 | 对应模板 |
|--------|----------|
| guidance/game-design-document-guide.md | → game-design-document.md |
| guidance/hud-design-guide.md | → hud-design.md |
| guidance/ux-spec-guide.md | → ux-spec.md |
| guidance/accessibility-requirements-guide.md | → accessibility-requirements.md |
| guidance/interaction-pattern-library-guide.md | → interaction-pattern-library.md（总览） |
| guidance/interaction-pattern-library-guide-standard-controls.md | → interaction-pattern-library.md（标准控件部分） |
| guidance/interaction-pattern-library-guide-game-specific.md | → interaction-pattern-library.md（游戏特定部分） |
| guidance/interaction-pattern-library-guide-navigation-feedback.md | → interaction-pattern-library.md（导航/反馈部分） |

### 4.6 .claude/agents/ — 数量不变（49），但全部重译

没有删除或新增，但每个 agent 的定义都按新版源文件重写了 YAML frontmatter 和 persona 段落。

### 4.7 .claude/skills/ — 新增 113 个文件

这是**变化最大的部分**：旧版只有 73 个 SKILL.md，现在变成 186 个 md 文件。

#### 新增 1 个技能

| 新技能 | 功能 |
|--------|------|
| **settings/** | 查看和修改 project.yaml 配置，内置 yaml-helper.sh 和 config-set.sh 辅助脚本 |

#### 新增 7 个 CONTRACT.md（技能契约）

这些是技能调用时必须遵守的输入/输出/阶段约束：

| 技能 | 契约 |
|------|------|
| gate-check | gate-check/CONTRACT.md |
| dev-story | dev-story/CONTRACT.md |
| story-done | story-done/CONTRACT.md |
| create-epics | create-epics/CONTRACT.md |
| create-stories | create-stories/CONTRACT.md |
| story-readiness | story-readiness/CONTRACT.md |
| architecture-decision | architecture-decision/CONTRACT.md |

#### 新增 105 个 references/ 步骤文件

9 个核心技能有了**详细的分步子文档**，旧版技能的步骤说明塞在 SKILL.md 里，现在拆成独立的编号文件：

| 技能 | references 子目录 | 文件数 |
|------|-------------------|--------|
| setup-engine | 2-guided-mode.md, 3-version.md, 4-claude-md-stack.md, 5-technical-preferences.md, 5.5-project-yaml.md, 6-knowledge-gap.md, 7-reference-docs.md, 7.5-scaffold.md, 8-verify.md, 11-upgrade.md, 12-output-summary.md, godot-language-config.md | **12** |
| gate-check | 2b-workflow-tier.md, 3-run-gate-check.md, 4-assessment.md, 5-verdict.md, 6-update-stage.md, 7-next-steps.md, gate-technical-setup.md, gate-pre-production.md, gate-systems-design.md, gate-production.md, gate-polish.md, gate-release.md | **12** |
| prototype | 1-question.md, 2-load-context.md, 3-choose-path.md, 4-plan.md, 5-implement.md, 6-debrief.md, 7-report.md, 8-cd-review.md, 9-summary.md, spike-mode.md | **10** |
| create-architecture | 0-load-context.md, 1-layers.md, 2-module-ownership.md, 3-data-flow.md, 4-api-boundaries.md, 5-adr-audit.md, 6-missing-adrs.md, 7-write.md, 8-handoff.md | **9** |
| architecture-review | 1-load.md, 2-extract-requirements.md, 3-traceability.md, 4-conflicts.md, 5-engine.md, 6-document-coverage.md, 7-report.md, 8-write.md, 9-handoff.md | **9** |
| ux-design | sections-ux-spec.md, sections-patterns.md, sections-hud.md, 2-gather-context.md, 3-file-skeleton.md, 4-authoring.md, 5-crossref-handoff.md | **7** |
| review-all-gdds | 1-load.md, 2-consistency.md, 3-design-holism.md, 4-scenarios.md, 5-report.md, 6-write.md, 7-handoff.md | **7** |
| smoke-check | 1-detect-setup.md, 2-run-tests.md, 3-coverage.md, 4-manual-checks.md, 5-report.md, 6-write-gate.md | **6** |
| test-setup | 1-detect.md, 2-plan.md, 3-directories.md, 4-ci.md, 5-smoke-seed.md, 6-summary.md | **6** |
| adopt | 1-detect.md, 2-format-audit.md, 3-classify.md, 4-migration-plan.md, 5-summary.md, 6-write.md, 7-first-action.md | **7** |
| architecture-decision | 0-accept.md, 0-retrofit.md, 1-engine-context.md, 3-gather-context.md, 4-decide.md, 5-generate.md | **6** |
| story-done | review-gates.md, sprint-next.md, tech-debt-row.md | **3** |
| dev-story | version-mismatch.md, engine-checks.md | **2** |
| brainstorm | full-concept.md | **1** |
| create-epics | pr-epic-gate.md | **1** |
| create-stories | qa-lead-gate.md | **1** |
| story-readiness | qa-lead-gate.md | **1** |

> **合计 105 个 references 文件**。这让 SKILL.md 本身保持精简（只讲"是什么、何时用、高层步骤"），细节拆到子文件里按需加载，避免一次性撑爆上下文。

---

## 五、数量不变但内容重译的文档

以下目录结构没变，但所有 md 文件都按新版源全文重写了：

| 目录 | 数量 | 重译说明 |
|------|------|----------|
| 根目录 README.md, CLAUDE.md, CONTRIBUTING.md, SECURITY.md, UPGRADING.md | 5 | 新版增加引擎 4.6/4.7 章节、门禁 rigor 参数、自动化模式说明等 |
| docs/engine-reference/* | 46 | Godot 4.7 VirtualJoystick/Asset Store、Unity 6.4–6.7 时间线、Unreal Substrate 渲染管线等 |
| .claude/docs/hooks-reference/ | 6 | 新增 10,000 字符钩子输出上限、SessionStop 事件、各钩子的 rigor 参数 |
| .claude/docs/templates/（保留的 40 个） | 40 | 各模板新增"required/recommended"字段标注、minimal/standard/full 严格度说明 |
| .claude/agents/ | 49 | YAML frontmatter 增加 tools/allowed-tools 精确列表、记忆文件引用、新的 persona 段落 |
| .claude/skills/ SKILL.md | 73 | 各 SKILL.md 增加 references 子目录引用、CONTRACT 引用、rigor 适用范围 |

---

## 六、结构对比图 / Structure Before → After

### 旧版顶层结构

```
/
├── README.md, CLAUDE.md, CONTRIBUTING.md, SECURITY.md, UPGRADING.md
├── docs/
│   ├── CLAUDE.md, WORKFLOW-GUIDE.md, COLLABORATIVE-DESIGN-PRINCIPLE.md
│   ├── engine-reference/  (godot + unity + unreal + README)
│   └── examples/  ← 已删除
└── .claude/
    └── docs/
        ├── 顶层 14 个文件（含 review-workflow.md, agent-coordination-map.md ← 已删）
        ├── templates/  (41 个，含 skill-test-spec.md + collaborative-protocols/ ← 已删)
        └── hooks-reference/  (6 个)
```

### 新版顶层结构

```
/
├── README.md, CHANGELOG.md, CLAUDE.md, CONTRIBUTING.md, SECURITY.md, UPGRADING.md
├── docs/
│   ├── CLAUDE.md, WORKFLOW-GUIDE.md, COLLABORATIVE-DESIGN-PRINCIPLE.md
│   ├── migration-guide-v1.1.md, skill-flow-diagrams.md  ← 新增
│   └── engine-reference/  (godot + unity + unreal + README)
└── .claude/
    └── docs/
        ├── 顶层 24 个文件（10 个新增）
        ├── director-gates/  ← 全新 28 个独立门禁文件
        ├── templates/  (62 个，新增 34 个，含 guidance/ 子目录)
        └── hooks-reference/  (6 个，内容重译)

.claude/agents/  (49，结构不变，内容重译)

.claude/skills/  ← 变化最大
├── 73 个 SKILL.md + 1 个新增 settings/SKILL.md
├── 7 个 CONTRACT.md
└── 105 个 references/ 步骤文件（9 个核心技能有子目录）
```

---

## 七、按目录逐项清单 / Full Change List

### 7.1 根目录（6 个）

| 文件 | 变化 |
|------|------|
| README.md | 重译，新增 rigor 参数说明、自动化模式、新的徽章 |
| CHANGELOG.md | **新增** |
| CLAUDE.md | 重译 |
| CONTRIBUTING.md | 重译 |
| SECURITY.md | 重译 |
| UPGRADING.md | 重译，v1.1 迁移内容简化（迁移指南独立为 migration-guide-v1.1.md） |

### 7.2 docs/ 顶层（5 个）

| 文件 | 变化 |
|------|------|
| CLAUDE.md | 重译，TR 注册表更新 |
| WORKFLOW-GUIDE.md | 重译，新增默认严格度、rigor 参数、15 个钩子 |
| COLLABORATIVE-DESIGN-PRINCIPLE.md | 重译，新增 rigor minimal 说明块 |
| migration-guide-v1.1.md | **新增** |
| skill-flow-diagrams.md | **从 docs/examples/ 移来并重译** |

### 7.3 docs/engine-reference/（46 个）

godot/ 12 + unity/ 16 + unreal/ 17 + README.md = **46 个全部重译**。引擎版本、API 名、插件名均按 2026 年最新文档更新。

### 7.4 docs/examples/（0 个）

**整个目录已删除**（10 个文件下线 + skill-flow-diagrams.md 上移）。

### 7.5 .claude/docs/ 顶层（24 个）

| 文件 | 变化 |
|------|------|
| CLAUDE-local-template.md | 重译 |
| director-gates.md | 重译（现在是 28 个子文件的索引） |
| quick-start.md | 重译 |
| hooks-reference.md | 重译 |
| setup-requirements.md | 重译 |
| skills-reference.md | 重译 |
| agent-roster.md | 重译 |
| coordination-rules.md | 重译 |
| coding-standards.md | 重译 |
| context-management.md | 重译 |
| technical-preferences.md | 重译 |
| rules-reference.md | 重译 |
| directory-structure.md | 重译 |
| settings-local-template.md | 重译 |
| agent-teams.md | **新增** |
| automation-modes.md | **新增** |
| code-root-resolution.md | **新增** |
| config-resolution.md | **新增** |
| effects-map.md | **新增** |
| error-recovery-protocol.md | **新增** |
| model-tiers.md | **新增** |
| run-and-observe.md | **新增** |
| settings-guidance.md | **新增** |
| workflow-modes.md | **新增** |

### 7.6 .claude/docs/director-gates/（28 个，全部新增）

见第四节 4.4 的完整清单。

### 7.7 .claude/docs/templates/（70 个）

**保留并重译（36 个）**：accessibility-requirements、architecture-decision-record、architecture-doc-from-code、architecture-traceability、art-bible、bug-report、design-doc-from-implementation、difficulty-curve、economy-model、faction-design、game-concept、game-design-document、game-pillars、hud-design、incident-response、interaction-pattern-library、level-design-document、milestone-definition、narrative-character-sheet、pitch-document、player-journey、post-mortem、prototype-report、release-checklist-template、release-notes、risk-register-entry、sound-bible、sprint-plan、systems-index、technical-design-document、test-evidence、test-plan、ux-spec、vertical-slice-report、changelog-template、concept-doc-from-prototype

**新增（26 个主模板 + 8 个 guidance）**：见第四节 4.5

**删除（4 个）**：skill-test-spec.md、collaborative-protocols/（3 个）

### 7.8 .claude/docs/hooks-reference/（6 个，全部重译）

hook-input-schemas、post-merge-asset-validation、post-sprint-retrospective、pre-commit-code-quality、pre-commit-design-check、pre-push-test-gate

### 7.9 .claude/agents/（49 个，全部重译）

结构不变，每个 agent 的 YAML frontmatter 和 persona 段落按新版源重译。

### 7.10 .claude/skills/（186 个）

**SKILL.md（74 个 = 73 原版重译 + 1 新增 settings）**

全部重译：adopt、architecture-decision、architecture-review、art-bible、asset-audit、asset-spec、balance-check、brainstorm、bug-report、bug-triage、changelog、code-review、consistency-check、content-audit、create-architecture、create-control-manifest、create-epics、create-stories、day-one-patch、design-review、design-system、dev-story、estimate、gate-check、help、hotfix、launch-checklist、localize、map-systems、milestone-review、onboard、patch-notes、perf-profile、playtest-report、project-stage-detect、propagate-design-change、prototype、qa-plan、quick-design、regression-suite、release-checklist、retrospective、reverse-document、review-all-gdds、scope-check、security-audit、settings（**新增**）、setup-engine、skill-improve、skill-test、smoke-check、soak-test、sprint-plan、sprint-status、start、story-done、story-readiness、team-audio、team-combat、team-level、team-live-ops、team-narrative、team-polish、team-qa、team-release、team-ui、tech-debt、test-evidence-review、test-flakiness、test-helpers、test-setup、ux-design、ux-review、vertical-slice

**CONTRACT.md（7 个，全部新增）**

architecture-decision、create-epics、create-stories、dev-story、gate-check、story-done、story-readiness

**references/（105 个，全部新增）**

分布在 9 个核心技能目录下，完整清单见第四节 4.7。

---

## 八、迁移建议 / Migration Tips

如果你之前已经熟悉了旧版文档体系，快速上手新版的建议：

1. **先读 CHANGELOG.md** — 一眼看完从旧版到新版的所有 Added / Changed / Removed
2. **director-gates/ 是最重要的变化** — 旧版 director-gates.md 一个文件里挤了所有门禁提示词，现在拆成 28 个独立文件。在 SKILL.md 里会引用具体的子文件（如 `director-gates/cd-pillars.md`）
3. **docs/examples/ 没了** — 想看实际流程，去 WORKFLOW-GUIDE.md 的阶段描述 + 各 SKILL.md 的"什么时候用"段落
4. **templates/guidance/ 是新东西** — 每个主模板现在都有对应的使用指南，告诉用户怎么填、填什么、什么时候用
5. **SKILL.md 变薄了** — 旧版 SKILL.md 里塞了完整步骤的技能，现在只留摘要，详细步骤拆到了 references/ 子目录。如果你在 SKILL.md 里找某个具体步骤找不到，去看 references/
6. **CONTRACT.md 是新东西** — 7 个核心技能有了契约文件，定义输入/输出/阶段约束，SKILL.md 里会引用
7. **review-workflow.md 和 agent-coordination-map.md 没了** — 内容分别吸收进 quick-start.md 和 coordination-rules.md + agent-roster.md，直接读这些就行

---

*本报告基于 2026-10-29 的源文件快照与 translatecn 译文快照对比生成。*
