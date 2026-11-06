# Game Studio Agent Architecture -- Quick Start Guide
# 游戏工作室智能体架构 -- 快速入门指南

## What Is This?
## 这是什么？

This is a complete Claude Code agent architecture for game development. It
organizes 49 specialized AI agents into a studio hierarchy that mirrors
real game development teams, with defined responsibilities, delegation
rules, and coordination protocols. It includes engine-specialist agents
for Godot, Unity, and Unreal — each with dedicated sub-specialists for
major engine subsystems. All design agents and templates are grounded in
established game design theory (MDA Framework, Self-Determination Theory,
Flow State, Bartle Player Types). Use whichever engine set matches your project.
这是一套面向游戏开发的完整 Claude Code 智能体架构。它将 49 个专业 AI 智能体组织成镜像真实游戏开发团队的工作室层级，具有明确的职责、委派规则和协调协议。它包含 Godot、Unity 和 Unreal 的引擎专家智能体 — 每个都配备针对主要引擎子系统的专属子专家。所有设计智能体和模板都建立在成熟的游戏设计理论基础之上（MDA 框架、自我决定理论、心流状态、Bartle 玩家类型）。请使用与你项目匹配的引擎集。

## The Default Path: Rigor Minimal
## 默认路径：严谨度 Minimal

`modes.rigor` defaults to `minimal` (`/start` infers it from what you describe and shows it
before saving; `/settings` changes it any time). At `minimal` the path to code is four steps:
`modes.rigor` 默认为 `minimal`（`/start` 根据你所描述的内容推断，并在保存前显示；`/settings` 可随时更改）。在 `minimal` 下，通往代码的路径有四个步骤：

1. `/setup-engine` -- configure the engine
1. `/setup-engine` -- 配置引擎
2. `/brainstorm` -- writes the one-page `design/game-brief.md`, in place of the
   concept doc, systems decomposition and per-system GDDs
2. `/brainstorm` -- 编写单页 `design/game-brief.md`，替代概念文档、系统分解和逐系统 GDD
3. `/create-stories` -- turns the brief's MVP list into stories under
   `production/epics/<slug>/`; the brief's build order is the plan, so there is
   no `/create-epics` or `/sprint-plan`
3. `/create-stories` -- 将简报的 MVP 列表转换为 `production/epics/<slug>/` 下的故事；简报中的构建顺序就是计划，因此不需要 `/create-epics` 或 `/sprint-plan`
4. `/dev-story` then `/story-done`, story by story -- `/story-done` names the
   next story, and `/help` knows this route
4. 然后逐个故事执行 `/dev-story` 与 `/story-done` -- `/story-done` 会指出下一个故事，`/help` 也了解这条路线

Nothing at `minimal` runs `/gate-check`, so `project.stage` stays at Concept.
Every skill still runs at any tier. The trade: no GDDs catch design problems
before code. Raise rigor with `/settings` when the game outgrows the brief;
`standard` and `full` are the longer pipelines under
[First Steps for a New Project](#first-steps-for-a-new-project).
`minimal` 下不会运行任何 `/gate-check`，因此 `project.stage` 保持在 Concept。每个技能在任何层级仍然可以运行。代价是：没有 GDD 在代码之前捕获设计问题。当游戏超出简报的承载能力时，用 `/settings` 提高严谨度；`standard` 和 `full` 是 [新项目的首要步骤](#first-steps-for-a-new-project) 下更长的流水线。

## How to Use
## 如何使用

### 1. Understand the Hierarchy
### 1. 理解层级

There are three tiers of agents:
智能体分为三个层级：

- **Tier 1 — Directors** who make high-level decisions (they run on Opus)
- **层级 1 — 总监**，做出高层决策（运行于 Opus）
  - `creative-director` -- vision and creative conflict resolution
  - `creative-director` -- 愿景与创意冲突解决
  - `technical-director` -- architecture and technology decisions
  - `technical-director` -- 架构与技术决策
  - `producer` -- scheduling, coordination, and risk management
  - `producer` -- 排期、协调与风险管理

- **Tier 2 — Department leads** who own their domain
- **层级 2 — 部门主管**，负责各自的领域
  - `game-designer`, `lead-programmer`, `art-director`, `audio-director`,
    `narrative-director`, `qa-lead`, `release-manager`, `localization-lead`
  - `game-designer`、`lead-programmer`、`art-director`、`audio-director`、
    `narrative-director`、`qa-lead`、`release-manager`、`localization-lead`

- **Tier 3 — Specialists** who execute within their domain
- **层级 3 — 专家**，在其领域内执行任务
  - Designers, programmers, artists, writers, testers, engineers
  - 设计师、程序员、美术师、编剧、测试员、工程师

The tiers are seniority of role. Most agents run on your session's model; the
agent file's own `model:` line says which do not
(`.claude/docs/model-tiers.md`).
这些层级是角色的资历。大多数智能体运行在你会话的模型上；智能体文件自己的 `model:` 行说明了哪些不是（`.claude/docs/model-tiers.md`）。

### 2. Pick the Right Agent for the Job
### 2. 为任务选择合适的智能体

Ask yourself: "What department would handle this in a real studio?"
问问自己："在真实工作室中，哪个部门会处理这件事？"

| I need to... | Use this agent |
| 我需要... | 使用此智能体 |
|-------------|---------------|
| Design a new mechanic | `game-designer` |
| 设计新机制 | `game-designer` |
| Write combat code | `gameplay-programmer` |
| 编写战斗代码 | `gameplay-programmer` |
| Create a shader | `technical-artist` |
| 创建着色器 | `technical-artist` |
| Write dialogue | `writer` |
| 编写对话 | `writer` |
| Plan the next sprint | `producer` |
| 规划下一个冲刺 | `producer` |
| Review code quality | `lead-programmer` |
| 评审代码质量 | `lead-programmer` |
| Write test cases | `qa-tester` |
| 编写测试用例 | `qa-tester` |
| Design a level | `level-designer` |
| 设计关卡 | `level-designer` |
| Fix a performance problem | `performance-analyst` |
| 修复性能问题 | `performance-analyst` |
| Set up CI/CD | `devops-engineer` |
| 搭建 CI/CD | `devops-engineer` |
| Design a loot table | `economy-designer` |
| 设计掉落表 | `economy-designer` |
| Resolve a creative conflict | `creative-director` |
| 解决创意冲突 | `creative-director` |
| Make an architecture decision | `technical-director` |
| 做出架构决策 | `technical-director` |
| Manage a release | `release-manager` |
| 管理发布 | `release-manager` |
| Prepare strings for translation | `localization-lead` |
| 准备待翻译字符串 | `localization-lead` |
| Test a mechanic idea quickly | `prototyper` |
| 快速测试一个机制想法 | `prototyper` |
| Review code for security issues | `security-engineer` |
| 评审代码安全问题 | `security-engineer` |
| Check accessibility compliance | `accessibility-specialist` |
| 检查无障碍合规性 | `accessibility-specialist` |
| Get Unreal Engine advice | `unreal-specialist` |
| 获取 Unreal Engine 建议 | `unreal-specialist` |
| Get Unity advice | `unity-specialist` |
| 获取 Unity 建议 | `unity-specialist` |
| Get Godot advice | `godot-specialist` |
| 获取 Godot 建议 | `godot-specialist` |
| Design GAS abilities/effects | `ue-gas-specialist` |
| 设计 GAS 能力/效果 | `ue-gas-specialist` |
| Define BP/C++ boundaries | `ue-blueprint-specialist` |
| 定义 BP/C++ 边界 | `ue-blueprint-specialist` |
| Implement UE replication | `ue-replication-specialist` |
| 实现 UE 复制 | `ue-replication-specialist` |
| Build UMG/CommonUI widgets | `ue-umg-specialist` |
| 构建 UMG/CommonUI 控件 | `ue-umg-specialist` |
| Design DOTS/ECS architecture | `unity-dots-specialist` |
| 设计 DOTS/ECS 架构 | `unity-dots-specialist` |
| Write Unity shaders/VFX | `unity-shader-specialist` |
| 编写 Unity 着色器/VFX | `unity-shader-specialist` |
| Manage Addressable assets | `unity-addressables-specialist` |
| 管理 Addressable 资源 | `unity-addressables-specialist` |
| Build UI Toolkit/UGUI screens | `unity-ui-specialist` |
| 构建 UI Toolkit/UGUI 屏幕 | `unity-ui-specialist` |
| Write idiomatic GDScript | `godot-gdscript-specialist` |
| 编写地道 GDScript | `godot-gdscript-specialist` |
| Write Godot C# code | `godot-csharp-specialist` |
| 编写 Godot C# 代码 | `godot-csharp-specialist` |
| Create Godot shaders | `godot-shader-specialist` |
| 创建 Godot 着色器 | `godot-shader-specialist` |
| Build GDExtension modules | `godot-gdextension-specialist` |
| 构建 GDExtension 模块 | `godot-gdextension-specialist` |
| Plan live events and seasons | `live-ops-designer` |
| 规划在线活动和赛季 | `live-ops-designer` |
| Write patch notes for players | `community-manager` |
| 为玩家编写补丁说明 | `community-manager` |
| Brainstorm a new game idea | Use `/brainstorm` skill |
| 头脑风暴新的游戏创意 | 使用 `/brainstorm` 技能 |

### 3. Use Slash Commands for Common Tasks
### 3. 使用斜杠命令完成常见任务

| Command | What it does |
| 命令 | 功能 |
|---------|-------------|
| `/start` | First-time onboarding — asks where you are, guides you to the right workflow |
| `/start` | 首次入职 — 询问你处于哪个阶段，引导你到正确的工作流 |
| `/help` | Context-aware "what do I do next?" — reads your current phase and artifacts |
| `/help` | 上下文感知的"下一步该做什么？" — 读取你当前阶段和产物 |
| `/project-stage-detect` | Analyze project state, detect stage, identify gaps |
| `/project-stage-detect` | 分析项目状态，检测阶段，识别差距 |
| `/setup-engine` | Configure engine + version, populate reference docs |
| `/setup-engine` | 配置引擎和版本，填充参考文档 |
| `/adopt` | Brownfield audit and migration plan for existing projects |
| `/adopt` | 针对现有项目的棕地审计和迁移计划 |
| `/brainstorm` | Guided game concept ideation from scratch |
| `/brainstorm` | 从零开始的引导式游戏概念创意 |
| `/map-systems` | Decompose concept into systems, map dependencies, guide per-system GDDs |
| `/map-systems` | 将概念分解为系统，映射依赖，指导逐系统 GDD |
| `/design-system` | Guided, section-by-section GDD authoring for a single game system |
| `/design-system` | 针对单个游戏系统的引导式、逐章节 GDD 编写 |
| `/quick-design` | Lightweight spec for small changes — tuning, tweaks, minor additions |
| `/quick-design` | 用于小变更的轻量规格 — 调参、微调、小型新增 |
| `/review-all-gdds` | Cross-GDD consistency and game design theory review |
| `/review-all-gdds` | 跨 GDD 一致性与游戏设计理论评审 |
| `/propagate-design-change` | Find ADRs and stories affected by a GDD change |
| `/propagate-design-change` | 查找受 GDD 变更影响的 ADR 和故事 |
| `/art-bible` | Guided, section-by-section Art Bible authoring — creates visual identity spec before asset production |
| `/art-bible` | 引导式、逐章节美术圣经编写 — 在资源生产前创建视觉身份规格 |
| `/asset-spec` | Generate per-asset visual specifications and AI generation prompts from GDDs or character profiles |
| `/asset-spec` | 从 GDD 或角色档案生成逐资源视觉规格和 AI 生成提示词 |
| `/ux-design` | Author UX specs (screen/flow, HUD, interaction patterns) |
| `/ux-design` | 编写 UX 规格（屏幕/流程、HUD、交互模式） |
| `/ux-review` | Validate UX specs for accessibility and GDD alignment |
| `/ux-review` | 验证 UX 规格的无障碍性和与 GDD 的对齐 |
| `/create-architecture` | Master architecture document for the game |
| `/create-architecture` | 游戏的主架构文档 |
| `/architecture-decision` | Creates an ADR |
| `/architecture-decision` | 创建 ADR |
| `/architecture-review` | Validate all ADRs, dependency ordering, GDD traceability — writes the index to `docs/architecture/requirements-traceability.md` |
| `/architecture-review` | 验证所有 ADR、依赖顺序、GDD 可追溯性 — 将索引写入 `docs/architecture/requirements-traceability.md` |
| `/create-control-manifest` | Flat programmer rules sheet from Accepted ADRs |
| `/create-control-manifest` | 从已接受的 ADR 生成扁平程序员规则表 |
| `/create-epics` | Translate GDDs + ADRs into epics (one per architectural module) |
| `/create-epics` | 将 GDD + ADR 转换为史诗（每个架构模块一个） |
| `/create-stories` | Break a single epic into implementable story files |
| `/create-stories` | 将单个史诗拆分为可实现的故事文件 |
| `/dev-story` | Read a story and implement it — routes to the correct programmer agent |
| `/dev-story` | 读取故事并实现 — 路由至正确的程序员智能体 |
| `/sprint-plan` | Creates or updates sprint plans |
| `/sprint-plan` | 创建或更新冲刺计划 |
| `/sprint-status` | Quick 30-line sprint snapshot |
| `/sprint-status` | 快速 30 行冲刺快照 |
| `/story-readiness` | Validate a story is implementation-ready before pickup |
| `/story-readiness` | 在领取前验证故事是否已准备好实现 |
| `/story-done` | End-of-story completion review — verifies acceptance criteria |
| `/story-done` | 故事完成时的收尾评审 — 验证验收标准 |
| `/estimate` | Produces structured effort estimates |
| `/estimate` | 产出结构化工作量估算 |
| `/design-review` | Reviews a design document |
| `/design-review` | 评审设计文档 |
| `/code-review` | Reviews code for quality and architecture |
| `/code-review` | 评审代码质量和架构 |
| `/balance-check` | Analyzes game balance data |
| `/balance-check` | 分析游戏平衡数据 |
| `/asset-audit` | Audits assets for compliance |
| `/asset-audit` | 审计资源合规性 |
| `/content-audit` | GDD-specified content vs. implemented — find gaps |
| `/content-audit` | GDD 规定内容 vs. 已实现 — 查找差距 |
| `/scope-check` | Detect scope creep against plan |
| `/scope-check` | 相对计划检测范围蔓延 |
| `/perf-profile` | Performance profiling and bottleneck ID |
| `/perf-profile` | 性能分析和瓶颈识别 |
| `/tech-debt` | Scan, track, and prioritize tech debt |
| `/tech-debt` | 扫描、跟踪并优先处理技术债 |
| `/gate-check` | Validate phase readiness (PASS/CONCERNS/NOT ASSESSED/FAIL) |
| `/gate-check` | 验证阶段就绪度（PASS/CONCERNS/NOT ASSESSED/FAIL） |
| `/consistency-check` | Scan all GDDs for cross-document inconsistencies (conflicting stats, names, rules) |
| `/consistency-check` | 扫描所有 GDD 以发现跨文档不一致（冲突的数值、名称、规则） |
| `/security-audit` | Audit for security vulnerabilities: save tampering, cheat vectors, network exploits, data exposure |
| `/security-audit` | 审计安全漏洞：存档篡改、作弊向量、网络漏洞、数据暴露 |
| `/reverse-document` | Generate design/architecture docs from existing code |
| `/reverse-document` | 从现有代码生成设计/架构文档 |
| `/milestone-review` | Reviews milestone progress |
| `/milestone-review` | 评审里程碑进度 |
| `/retrospective` | Runs sprint/milestone retrospective |
| `/retrospective` | 运行冲刺/里程碑回顾 |
| `/bug-report` | Structured bug report creation |
| `/bug-report` | 结构化 bug 报告创建 |
| `/playtest-report` | Creates or analyzes playtest feedback |
| `/playtest-report` | 创建或分析试玩反馈 |
| `/onboard` | Generates onboarding docs for a role |
| `/onboard` | 为某角色生成入职文档 |
| `/release-checklist` | Validates pre-release checklist |
| `/release-checklist` | 验证发布前检查清单 |
| `/launch-checklist` | Complete launch readiness validation |
| `/launch-checklist` | 完整的上线就绪度验证 |
| `/changelog` | Generates changelog from git history |
| `/changelog` | 从 git 历史生成更新日志 |
| `/patch-notes` | Generate player-facing patch notes |
| `/patch-notes` | 生成面向玩家的补丁说明 |
| `/hotfix` | Emergency fix with audit trail |
| `/hotfix` | 带审计跟踪的紧急修复 |
| `/day-one-patch` | Prepare a focused day-one patch for known issues discovered after gold master |
| `/day-one-patch` | 为金盘后发现的已知问题准备有针对性的首日补丁 |
| `/prototype` | Concept prototype — validate core idea before writing GDDs (Phase 1) |
| `/prototype` | 概念原型 — 在编写 GDD 前验证核心想法（阶段 1） |
| `/vertical-slice` | Production-quality end-to-end build — validate full game loop (Phase 4) |
| `/vertical-slice` | 生产质量的端到端构建 — 验证完整游戏循环（阶段 4） |
| `/localize` | Localization scan, extract, validate |
| `/localize` | 本地化扫描、提取、验证 |
| `/team-combat` | Orchestrate full combat team pipeline |
| `/team-combat` | 编排完整战斗团队流水线 |
| `/team-narrative` | Orchestrate full narrative team pipeline |
| `/team-narrative` | 编排完整叙事团队流水线 |
| `/team-ui` | Orchestrate full UI team pipeline |
| `/team-ui` | 编排完整 UI 团队流水线 |
| `/team-release` | Orchestrate full release team pipeline |
| `/team-release` | 编排完整发布团队流水线 |
| `/team-polish` | Orchestrate full polish team pipeline |
| `/team-polish` | 编排完整打磨团队流水线 |
| `/team-audio` | Orchestrate full audio team pipeline |
| `/team-audio` | 编排完整音频团队流水线 |
| `/team-level` | Orchestrate full level creation pipeline |
| `/team-level` | 编排完整关卡创建流水线 |
| `/team-live-ops` | Orchestrate live-ops team for seasons, events, and post-launch content |
| `/team-live-ops` | 为赛季、活动和上线后内容编排在线运营团队 |
| `/team-qa` | Orchestrate full QA team cycle — test plan, test cases, smoke check, sign-off |
| `/team-qa` | 编排完整 QA 团队周期 — 测试计划、测试用例、冒烟检查、签字 |
| `/qa-plan` | Generate a QA test plan for a sprint or feature |
| `/qa-plan` | 为冲刺或功能生成 QA 测试计划 |
| `/bug-triage` | Re-prioritize open bugs, assign to sprints, surface systemic trends |
| `/bug-triage` | 重新排定开放 bug 优先级，分配至冲刺，揭示系统性趋势 |
| `/smoke-check` | Run critical path smoke test gate before QA hand-off (PASS/FAIL) |
| `/smoke-check` | 在 QA 交接前运行关键路径冒烟测试门禁（PASS/FAIL） |
| `/soak-test` | Generate a soak test protocol for extended play sessions |
| `/soak-test` | 为长时间游玩会话生成浸泡测试协议 |
| `/regression-suite` | Map coverage to GDD critical paths, flag gaps, maintain regression suite |
| `/regression-suite` | 将覆盖率映射到 GDD 关键路径，标记差距，维护回归测试套件 |
| `/test-setup` | Scaffold test framework + CI pipeline for the project's engine (run once) |
| `/test-setup` | 为项目引擎搭建测试框架和 CI 流水线（运行一次） |
| `/test-helpers` | Generate engine-specific test helper libraries and factory functions |
| `/test-helpers` | 生成引擎特定的测试辅助库和工厂函数 |
| `/test-flakiness` | Detect flaky tests from CI history, flag for quarantine or fix |
| `/test-flakiness` | 从 CI 历史检测不稳定测试，标记为隔离或修复 |
| `/test-evidence-review` | Quality review of test files and manual evidence — ADEQUATE/INCOMPLETE/MISSING |
| `/test-evidence-review` | 测试文件和手动证据的质量评审 — ADEQUATE/INCOMPLETE/MISSING |
| `/skill-test` | Validate skill files for compliance and correctness (static / spec / audit) |
| `/skill-test` | 验证技能文件的合规性和正确性（静态 / 规格 / 审计） |
| `/skill-improve` | Improve a skill using a test-fix-retest loop — diagnose, propose fix, rewrite, verify |
| `/skill-improve` | 通过测试-修复-重测循环改进技能 — 诊断、提出修复、重写、验证 |

### 4. Use Templates for New Documents
### 4. 使用模板创建新文档

Templates are in `.claude/docs/templates/`:
模板位于 `.claude/docs/templates/`：

- `game-design-document.md` -- for new mechanics and systems
- `game-design-document.md` -- 用于新机制和系统
- `architecture-decision-record.md` -- for technical decisions
- `architecture-decision-record.md` -- 用于技术决策
- `architecture-traceability.md` -- sample layout for a GDD requirement to ADR to
  story index (`/architecture-review` writes its own index to
  `docs/architecture/requirements-traceability.md`)
- `architecture-traceability.md` -- 从 GDD 需求到 ADR 再到故事索引的示例布局（`/architecture-review` 将自己的索引写入 `docs/architecture/requirements-traceability.md`）
- `risk-register-entry.md` -- for new risks
- `risk-register-entry.md` -- 用于新风险
- `narrative-character-sheet.md` -- for new characters
- `narrative-character-sheet.md` -- 用于新角色
- `test-plan.md` -- for feature test plans
- `test-plan.md` -- 用于功能测试计划
- `sprint-plan.md` -- for sprint planning
- `sprint-plan.md` -- 用于冲刺规划
- `milestone-definition.md` -- for new milestones
- `milestone-definition.md` -- 用于新里程碑
- `level-design-document.md` -- for new levels
- `level-design-document.md` -- 用于新关卡
- `game-pillars.md` -- for core design pillars
- `game-pillars.md` -- 用于核心设计支柱
- `art-bible.md` -- for visual style reference
- `art-bible.md` -- 用于视觉风格参考
- `technical-design-document.md` -- for per-system technical designs
- `technical-design-document.md` -- 用于逐系统技术设计
- `post-mortem.md` -- for project/milestone retrospectives
- `post-mortem.md` -- 用于项目/里程碑回顾
- `sound-bible.md` -- for audio style reference
- `sound-bible.md` -- 用于音频风格参考
- `release-checklist-template.md` -- for platform release checklists
- `release-checklist-template.md` -- 用于平台发布检查清单
- `changelog-template.md` -- for player-facing patch notes
- `changelog-template.md` -- 用于面向玩家的补丁说明
- `release-notes.md` -- for player-facing release notes
- `release-notes.md` -- 用于面向玩家的发布说明
- `incident-response.md` -- for live incident response playbooks
- `incident-response.md` -- 用于线上事件响应手册
- `game-concept.md` -- for initial game concepts (MDA, SDT, Flow, Bartle)
- `game-concept.md` -- 用于初始游戏概念（MDA、SDT、Flow、Bartle）
- `game-brief.md` -- for the one-page brief that replaces the concept doc at `rigor: minimal`
- `game-brief.md` -- 用于在 `rigor: minimal` 下替代概念文档的单页简报
- `pitch-document.md` -- for pitching the game to stakeholders
- `pitch-document.md` -- 用于向利益相关者推介游戏
- `economy-model.md` -- for virtual economy design (sink/faucet model)
- `economy-model.md` -- 用于虚拟经济设计（sink/faucet 模型）
- `faction-design.md` -- for faction identity, lore, and gameplay role
- `faction-design.md` -- 用于阵营身份、设定和游戏玩法定位
- `systems-index.md` -- for systems decomposition and dependency mapping
- `systems-index.md` -- 用于系统分解和依赖映射
- `project-stage-report.md` -- for project stage detection output
- `project-stage-report.md` -- 用于项目阶段检测输出
- `design-doc-from-implementation.md` -- for reverse-documenting existing code into GDDs
- `design-doc-from-implementation.md` -- 用于将现有代码反向文档化为 GDD
- `architecture-doc-from-code.md` -- for reverse-documenting code into architecture docs
- `architecture-doc-from-code.md` -- 用于将代码反向文档化为架构文档
- `concept-doc-from-prototype.md` -- for reverse-documenting prototypes into concept docs
- `concept-doc-from-prototype.md` -- 用于将原型反向文档化为概念文档
- `ux-spec.md` -- for per-screen UX specifications (layout zones, states, events)
- `ux-spec.md` -- 用于逐屏幕 UX 规格（布局分区、状态、事件）
- `hud-design.md` -- for whole-game HUD philosophy, zones, and element specs
- `hud-design.md` -- 用于全游戏 HUD 理念、分区和元素规格
- `accessibility-requirements.md` -- for project-wide accessibility tier and feature matrix
- `accessibility-requirements.md` -- 用于全项目无障碍层级和功能矩阵
- `interaction-pattern-library.md` -- for standard UI controls and game-specific patterns
- `interaction-pattern-library.md` -- 用于标准 UI 控件和游戏特定模式
- `player-journey.md` -- for 6-phase emotional arc and retention hooks by time scale
- `player-journey.md` -- 用于 6 阶段情感弧线和按时间尺度的留存钩子
- `difficulty-curve.md` -- for difficulty axes, onboarding ramp, and cross-system interactions
- `difficulty-curve.md` -- 用于难度坐标轴、新手引导曲线和跨系统交互
- `test-evidence.md` -- template for recording manual test evidence (screenshots, walkthrough notes)
- `test-evidence.md` -- 记录手动测试证据的模板（截图、走查笔记）

### 5. Follow the Coordination Rules
### 5. 遵循协调规则

1. Work flows down the hierarchy: Directors -> Leads -> Specialists
1. 工作沿层级向下流动：总监 -> 主管 -> 专家
2. Conflicts escalate up the hierarchy
2. 冲突沿层级向上升级
3. Cross-department work is coordinated by the `producer`
3. 跨部门工作由 `producer` 协调
4. Agents do not modify files outside their domain without delegation
4. 智能体不在未获委派的情况下修改其领域之外的文件
5. All decisions are documented
5. 所有决策都留有记录

## First Steps for a New Project
## 新项目的首要步骤

**Don't know where to begin?** Run `/start`. It asks where you are and routes
you to the right workflow. No assumptions about your game, engine, or experience level.
**不知道从哪里开始？** 运行 `/start`。它会询问你当前所处阶段，并引导你到正确的工作流。不会对你的游戏、引擎或经验水平做任何假设。

The paths below walk the `standard`/`full` pipeline. At `rigor: minimal` (the
default), follow [The Default Path](#the-default-path-rigor-minimal) instead.
下面的路径走的是 `standard`/`full` 流水线。在 `rigor: minimal`（默认）下，请改为遵循 [默认路径](#the-default-path-rigor-minimal)。

If you already know what you need, jump directly to the relevant path:
如果你已经知道需要什么，可直接跳到对应路径：

### Path A: "I have no idea what to build"
### 路径 A："我完全不知道要做什么"

1. **Run `/start`** (or `/brainstorm open`) — guided creative exploration:
   what excites you, what you've played, your constraints
1. **运行 `/start`**（或 `/brainstorm open`）— 引导式创意探索：
   什么让你兴奋、你玩过什么、你的约束条件
   - Generates 3 concepts, helps you pick one, defines core loop and pillars
   - 生成 3 个概念，帮助你选择一个，定义核心循环和支柱
   - Produces a game concept document and recommends an engine
   - 产出游戏概念文档并推荐引擎
2. **Set up the engine** — Run `/setup-engine` (uses the brainstorm recommendation)
2. **设置引擎** — 运行 `/setup-engine`（使用头脑风暴的推荐）
   - Configures CLAUDE.md, detects knowledge gaps, populates reference docs
   - 配置 CLAUDE.md，检测知识缺口，填充参考文档
   - Writes engine, naming conventions, and performance budgets to `project.yaml`
     (the source of truth), mirrored to `.claude/docs/technical-preferences.md`
   - 将引擎、命名约定和性能预算写入 `project.yaml`（唯一事实来源），并镜像到 `.claude/docs/technical-preferences.md`
   - If the engine version is newer than the LLM's training data, it fetches
     current docs from the web so agents suggest correct APIs
   - 如果引擎版本比 LLM 的训练数据更新，它会从网络获取最新文档，使智能体建议正确的 API
3. **Validate the concept** — Run `/design-review design/gdd/game-concept.md`
   (or `design/game-brief.md`, if `/brainstorm` wrote the one-page brief)
3. **验证概念** — 运行 `/design-review design/gdd/game-concept.md`（如果 `/brainstorm` 编写了单页简报，则为 `design/game-brief.md`）
4. **Prototype the mechanic** — Run `/prototype [core-mechanic]` (1 day at most) to
   test that the core idea is fun before you write GDDs
4. **制作机制原型** — 运行 `/prototype [core-mechanic]`（最多 1 天），在编写 GDD 之前测试核心想法是否有趣
5. **Decompose into systems** — Run `/map-systems` to map all systems and dependencies
5. **分解为系统** — 运行 `/map-systems` 映射所有系统和依赖
6. **Design each system** — Run `/design-system [system-name]` (or `/map-systems next`)
   to write GDDs in dependency order, informed by the prototype findings
6. **设计每个系统** — 运行 `/design-system [system-name]`（或 `/map-systems next`），按依赖顺序编写 GDD，并结合原型发现
7. **Plan the first sprint** — After architecture and `/vertical-slice`, run `/sprint-plan new`
7. **规划第一个冲刺** — 在架构完成和 `/vertical-slice` 之后，运行 `/sprint-plan new`
8. Start building
8. 开始构建

### Path B: "I know what I want to build"
### 路径 B："我知道要做什么"

If you already have a game concept and engine choice:
如果你已有游戏概念和引擎选择：

1. **Set up the engine** — Run `/setup-engine [engine] [version]`
   (e.g., `/setup-engine godot 4.7`) — also creates technical preferences
1. **设置引擎** — 运行 `/setup-engine [engine] [version]`
   （例如 `/setup-engine godot 4.7`）— 同时创建技术偏好
2. **Write the Game Pillars** — delegate to `creative-director`
2. **编写游戏支柱** — 委派给 `creative-director`
3. **Decompose into systems** — Run `/map-systems` to enumerate systems and dependencies
3. **分解为系统** — 运行 `/map-systems` 枚举系统和依赖
4. **Design each system** — Run `/design-system [system-name]` for GDDs in dependency order
4. **设计每个系统** — 运行 `/design-system [system-name]` 按依赖顺序编写 GDD
5. **Create the initial ADR** — Run `/architecture-decision`
5. **创建初始 ADR** — 运行 `/architecture-decision`
6. **Create the first milestone** in `production/milestones/`
6. 在 `production/milestones/` 中**创建第一个里程碑**
7. **Plan the first sprint** — Run `/sprint-plan new`
7. **规划第一个冲刺** — 运行 `/sprint-plan new`
8. Start building
8. 开始构建

### Path C: "I know the game but not the engine"
### 路径 C："我知道游戏但不知道引擎"

If you have a concept but don't know which engine fits:
如果你有概念但不知道哪个引擎合适：

1. **Run `/setup-engine`** with no arguments — it will ask about your game's
   needs (2D/3D, platforms, team size, language preferences) and recommend
   an engine based on your answers
1. **运行 `/setup-engine`** 且不传参数 — 它会询问你游戏的需求
   （2D/3D、平台、团队规模、语言偏好）并根据你的回答推荐引擎
2. Follow Path B from step 2 onward
2. 从步骤 2 开始遵循路径 B

### Path D: "I have an existing project"
### 路径 D："我有一个现有项目"

If you have design docs, prototypes, or code already:
如果你已有设计文档、原型或代码：

1. **Run `/start`** (or `/project-stage-detect`) — analyzes what exists,
   identifies gaps, and recommends next steps
1. **运行 `/start`**（或 `/project-stage-detect`）— 分析现有内容，
   识别差距，并推荐下一步
2. **Run `/adopt`** if you have existing GDDs, ADRs, or stories — audits
   internal format compliance and builds a numbered migration plan to fill gaps
   without overwriting your existing work
2. **运行 `/adopt`** 如果你已有 GDD、ADR 或故事 — 审计内部格式合规性，
   构建带编号的迁移计划以填补差距，且不覆盖你现有的工作
3. **Configure engine if needed** — Run `/setup-engine` if not yet configured
3. **如需配置引擎** — 如果尚未配置，运行 `/setup-engine`
4. **Validate phase readiness** — Run `/gate-check` to see where you stand
4. **验证阶段就绪度** — 运行 `/gate-check` 查看你所处位置
5. **Plan the next sprint** — Run `/sprint-plan new`
5. **规划下一个冲刺** — 运行 `/sprint-plan new`

## File Structure Reference
## 文件结构参考

```
CLAUDE.md                          -- Master config (read this first, ~80 lines)
project.yaml                       -- Machine-readable project config (engine, modes, stage) — source of truth
.claude/
  settings.json                    -- Claude Code hooks and project settings
  agents/                          -- 49 agent definitions (YAML frontmatter)
  skills/                          -- 74 slash command definitions (YAML frontmatter)
  hooks/                           -- 15 event hooks (.sh, wired by settings.json) + yaml-helper.sh, update-check.sh
  rules/                           -- 14 path-specific rule files
  docs/
    quick-start.md                 -- This file
    technical-preferences.md       -- Legacy fallback for project.yaml config (mirror; see project.yaml at repo root)
    coding-standards.md            -- Coding and design doc standards
    coordination-rules.md          -- Agent coordination rules
    context-management.md          -- Context budgets and compaction instructions
    directory-structure.md         -- Project directory layout
    workflow-catalog.yaml          -- 7-phase pipeline definition (read by /help)
    setup-requirements.md          -- System prerequisites (Git Bash, jq, Python)
    settings-local-template.md     -- Personal settings.local.json guide
    CLAUDE-local-template.md       -- Personal CLAUDE.local.md guide (gitignored overrides)
    templates/                     -- 62 document templates (+ per-section guidance)
```
