# project-stage-detect — 全项目审计定位当前阶段（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/project-stage-detect/SKILL.md) ｜ 阶段：Any ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/project-stage-detect`（可选参数：角色过滤，如 `programmer`、`designer`）
- **一句话职责**：扫描项目判定当前开发阶段、各产物完备度与需要注意的缺口，产出带 Stage Confidence 的阶段报告并推荐下一步；回答"我们在开发的哪一步？"
- **触发前置**：适用于存量项目起步、入职陌生代码库、里程碑前查缺、理解"我们到哪了"；只读诊断技能，不需要派生专家智能体。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | resolve_config 预解析块：`workflow`、`automation` | 运行前解析好、按原样使用；块未渲染则回退 `.claude/docs/config-resolution.md` 默认值 |
| 读取 | `bash .claude/scripts/artifact-check.sh`（无参，全阶段） | 确定性首遍：每步 PRESENT/ABSENT/SHORT（`count=`/`min=`）/PATTERN_MISS/NO_CHECK |
| 读取 | `design/`：`design/gdd/*.md` 计数；`game-concept.md`（`minimal` 下为 `design/game-brief.md`）、`game-pillars.md`、`systems-index.md`；`design/narrative/`、`design/levels/` 计数 | 设计文档完备度；systems-index 存在时数"总系统 vs 已设计系统" |
| 读取 | 代码根（`src/` Godot、`Assets/` Unity、`Source/` Unreal；依 `.claude/docs/code-root-resolution.md` 解析） | 源文件计数、主要系统（5+ 文件的目录）、`core/`/`gameplay/`/`ai/`/`networking/`/`ui/`、LOC 粗估 |
| 读取 | `production/`（sprint 计划、里程碑、roadmap）、`prototypes/`（目录数、README、归档还是活跃）、`docs/architecture/`（ADR 数、总览/索引）、`tests/`（测试文件数、覆盖率粗估） | 其余产物维度 |
| 读取 | `project.yaml` 的 `project.stage`，其次 `production/stage.txt`（遗留回退） | 二者都是 `/gate-check` 写入的显式覆盖；仍要跑启发式并比对 |
| 产出 | `production/project-stage-report.md`（模板：`.claude/docs/templates/project-stage-report.md`）——**必须先获用户批准才写** | 报告含 Date、Stage、Stage Confidence（PASS/CONCERNS/NOT ASSESSED/FAIL）、五维完备度、缺口+澄清问题、优先级排序的下一步 |
| 派生智能体 | 无，主会话直接执行（只读诊断，不需专家代理） | — |

**配置解析**：`modes.automation` 解析链为 `project.local.yaml` → `project.yaml` → 默认 `collaborative`；每次提问与写文件都遵循 `.claude/docs/automation-modes.md`（collaborative 每次都问 · guided 只问重大 · autonomous 记录并推进；`automation_always_ask` 类别恒问）。`workflow` 档位决定哪些缺失文档算缺口——`full` 下每份缺的文档都算，`minimal` 下都不算（brief+引擎即正常状态，代码才是预期下一步）；档位必须解析、**禁止**臆测——猜高会告诉一个 jam 项目它缺 GDD、art bible 和 ADR，正是 `modes.rigor` 要防的"流程和项目不匹配"体验。

## 3. 核心规则（逐条编号 R1、R2……）

### 1. 扫描关键目录
R1. 必须以确定性首遍开场：`bash .claude/scripts/artifact-check.sh`——**必须**按原样执行：项目根目录、相对路径、无参数、无 `cd`、无 `2>&1`（权限授权只匹配这一形式，其它形式会请求批准）。无 `--phase` 时报告全部阶段，一次调用覆盖全项目；**用它取代**逐个工件手工 glob，并把它的 `NO_CHECK` 总数当作"存在性检查能告诉你什么"的诚实上界。它只报观察——阶段判定仍由本技能做，缺口口径仍由档位管。（§1）
R2. 首遍之后再分析脚本覆盖不了的：内容质量、它不追踪的计数、判断题。GDD 完备度（Overview、Detailed Design、Edge Cases 等）必须分节读：用 Grep（pattern `^#`，content 模式）找所需标题，再用 offset/limit 读那些区间。（§1 Design Documentation）
R3. 代码根解析失败时，所有代码分析都没跑：必须报 `NOT ASSESSED — code root unresolved`，**绝不**报"零个源文件"——零会被读成全新项目，而阶段表的源文件行没有计数就无法裁定。（§1 Source Code）
R4. `workflow: minimal` 下没有 sprint：改读 story 文件在 brief build order 中的进度，**绝不**把缺失的 sprint 计划/里程碑/roadmap 报成缺口。（§1 Production Artifacts）

### 2. 分类项目阶段
R5. 阶段判定顺序：先查 `project.yaml` 的 `project.stage`（若有），其次 `production/stage.txt`（遗留回退）——二者都是 `/gate-check` 写入的显式覆盖；否则用启发式从最先进的阶段向后匹配。（§2）
R6. **即使已有配置阶段也必须跑启发式并比对。** 配置值只权威于"阶段是什么"，不是"产物支持它"的证据。两个都报告，不一致时必须明说："Configured stage: **Release**. Observed artifacts indicate **Pre-Production** (2 source files, 0 ADRs, no architecture doc, no epics). These disagree — the configured stage may be stale, or work exists outside this repo."。读配置再复述不叫检测——不能反驳自己输入的阶段检测器是它绝不能成为的东西。（§2 引注）
R7. 阶段表：**Concept**——无游戏概念文档，brainstorming 阶段；**Systems Design**——game concept 已存在，systems index 缺失或不完整；**Technical Setup**——systems index 已存在，引擎未配置；**Pre-Production**——引擎已配置，代码根 <10 个源文件；**Production**——代码根 ≥10 个源文件，活跃开发；**Polish**——仅显式（由 `/gate-check` Production→Polish 门设置）；**Release**——仅显式（由 `/gate-check` Polish→Release 门设置）。（§2 表）
R8. 配置与观察不一致 → Stage Confidence 记 **CONCERNS**（信号歧义），无论产物多完整。唯一例外：`workflow: minimal` 下没有东西跑 `/gate-check`，配置阶段停留在 `/start` 所设——此时报观察到的阶段，并说明该档位下配置阶段不前进是预期、不是分歧。（§2 引注）

### 3. 协作式缺口识别
R9. 缺口必须按解析出的 `workflow` 档位呈现：`full`——每种缺失文档类型（GDD、art bible、UX 规格、ADR）都标记为缺口；`standard`——只标必需文档：已建成系统缺失的 GDD 和关键（Foundation 层）ADR 缺失；**不**标缺失的 art bible，除非存在视觉资产 story；**不**标非核心 UX 规格；`minimal`——`design/game-brief.md` + 引擎在场即正常状态，**不**把缺失的 GDD、art bible、UX 规格、ADR、epics、sprint 计划标为缺口：brief 的 build order 就是计划，预期下一步是代码。（§3）
R10. **禁止**只罗列缺失文件。必须对（档位说要呈现的）缺口提澄清问题，如："我在 `<code root>/gameplay/combat/` 看到战斗代码但没有 `design/gdd/combat-system.md`——这是先做了原型，还是该 reverse-document？"；"有 15 个 ADR 却没有架构总览，要不要我建一份帮助新成员？"；（`standard`/`full` 才问）"`<code root>/` 下有 N 个系统但 `docs/architecture/` 无 ADR——决策记录在别处，还是用 `/architecture-decision` 补关键的？"；（`standard`/`full` 才问）"`production/` 没有 sprint 计划——你们在别处追踪工作吗（Jira、Trello 等）？"；"有 game concept 但无 systems index——已分解过吗，还是跑 `/map-systems`？"；"prototypes 下 3 个项目无 README——实验品，还是需要文档？"（§3）

### 4. 生成阶段报告
R11. 必须用模板 `.claude/docs/templates/project-stage-report.md`，结构含：`# Project Stage Analysis`、Date、Stage、**Stage Confidence**（`PASS`—清晰检出 / `CONCERNS`—信号歧义 / `NOT ASSESSED`—阶段依赖的一项检查没跑 / `FAIL`—关键缺口阻塞进度）；Completeness Overview 五行（Design/Code/Architecture/Production/Tests 各 [X%] 与计数/缺口；`minimal` 下 Production 行写"stories complete in the brief's build order"，**绝不**写 "no sprint plan"）；Gaps Identified（每条缺口+澄清问题）；Recommended Next Steps（按阶段与角色排序）。（§4）
R12. Stage Confidence 首个命中者胜：关键缺口阻塞进度→**FAIL**；已采集的信号歧义（适配多个阶段，或配置阶段与观察阶段不一致，见 §2）→**CONCERNS**；阶段依赖的检查没跑→**NOT ASSESSED**（必须点名，如代码根未解析、存在两个候选根，源文件计数乃至阶段表 Production 行悬而未决）；否则→**PASS**。排序：NOT ASSESSED 压过 PASS（没人能检查的阶段不是清晰检出的），低于 CONCERNS 与 FAIL（已知问题绝不埋没在它后面）。（§4）
R13. 角色过滤（用户给了角色参数时）：`programmer`——聚焦架构文档、测试覆盖、缺失 ADR、代码↔文档缺口；`designer`——聚焦 GDD 完备度、缺失设计章节、原型文档；`producer`——聚焦 sprint 计划、里程碑追踪、roadmap、跨团队协调文档；无角色——全领域全景+各域最高优先级。（§5）
R14. 写报告前必须走协作协议：展示摘要、缺口清单（带问题）、推荐的下一步，然后问 "May I write the full stage analysis to production/project-stage-report.md?"，**等用户批准后**才建文件。（§6）

### 后续行动
R15. 报告后建议的下一步**只针对**解析档位要呈现的缺口；`standard`/`minimal` 下**不**建议补写可选文档（如 `minimal` 缺 GDD 不建议 `/reverse-document`——代码才是预期下一步）。映射：`minimal` 无 `design/game-brief.md`→代码根 ≥10 源文件用 `/reverse-document design <code root>`（从成品写 brief），代码很少则 `/brainstorm`；有 concept 无 systems index→`/map-systems`；缺设计文档→`/reverse-document design <code root>/[system]`；缺架构文档→`/architecture-decision` 或 `/reverse-document architecture`；原型缺文档→`/reverse-document concept prototypes/[name]`；无 sprint 计划→`/sprint-plan`（`rigor: minimal` 不适用，brief 的 build order 即计划）；临近里程碑→`/milestone-review`。（Follow-Up Actions）

### 协作协议
R16. 必须遵循：Question First（问缺口、不臆断）→ Present Options（"要我建 X，还是已在别处追踪？"）→ User Decides（等指示）→ Show Draft（展示报告摘要）→ Get Approval（"可否写入 production/project-stage-report.md？"）。（Collaborative Protocol）
R17. **绝不**静默写文件；**必须**先展示发现并在创建工件前征询。（Collaborative Protocol）

## 4. 门禁与裁决
- 本技能不设门禁，但产出裁决词 **Stage Confidence**：FAIL / CONCERNS / NOT ASSESSED / PASS，按 R12"首个命中者胜 + NOT ASSESSED 压 PASS、低于 CONCERNS/FAIL"裁决。
- 阶段表（R7）即裁决标准；配置阶段与观察阶段不一致的比对规则（R6–R8）是防"检测器只会复述输入"的核心裁决。

## 5. 移植建议
- **可直接移植**：R1–R3、R5–R8、R10–R17——"确定性脚本首遍 + 脚本覆盖不了的才人工分析 + 配置值必须跑启发式比对 + 不一致要敢说 + 分档缺口口径 + 问缺口而非臆断 + 批准后才写报告"，对任何"项目体检/阶段定位"助手都成立。
- **需替换概念**：游戏阶段名与阶段表（Concept→Release）→ 目标领域的成熟度梯队；`workflow`/`modes.rigor` → 流程强度档位；GDD/art bible/ADR/sprint 计划 → 你领域的工件类型及其"必需 vs 可选"；`artifact-check.sh` → 你的存在性检查脚本；`/gate-check` → 你的阶段推进门；10 源文件阈值 → 你的"进入实施"判据。
- **改写示例**：
  - "判定项目阶段时必须同时跑启发式并报告观察结果，即使配置里已有显式阶段值；两者不一致时必须原样指出（配置值、观察值、证据各一条），禁止只复述配置。"
  - "缺口口径由流程档位决定：最低档下'骨架文档+工具链在场'即正常状态，禁止把更高级别的可选文档报成缺口；对每个要呈现的缺口先提问、后建议。"

## 6. 关联文档
- 上游：`/start`（D 路径点名本技能）、`/gate-check`（写入配置阶段的来源）
- 对比：`/adopt` 查"合规性"而非"存在性"；`/help` 是轻量导航，本技能是全量缺口分析
- 引用 docs：`.claude/docs/code-root-resolution.md`、`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/templates/project-stage-report.md`
- 脚本：`.claude/scripts/artifact-check.sh`
