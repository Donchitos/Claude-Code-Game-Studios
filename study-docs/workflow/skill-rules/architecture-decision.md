# architecture-decision — 创建/改造 ADR（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/architecture-decision/SKILL.md) ｜ 阶段：Phase 3 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/architecture-decision [title | retrofit <path> | accept <ADR-id>] [--review full|lean|solo]`
- **一句话职责**：撰写一篇 ADR（架构决策记录），记录某项技术决策的上下文、备选方案与后果；含改造（retrofit，为既有文件补 ADR）与接受（accept，将 ADR 置为 Accepted）两种特殊模式。
- **触发前置**：常规模式需要决策标题（缺失则先询问，见 R4）；`retrofit` 模式需给出既有文件路径；`accept` 模式需给出 ADR 编号。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode`、`automation`、`workflow`、`docs.density`、`team.size`（经 `hooks/yaml-helper.sh resolve_config`；`--review` 覆盖 `review_mode`；无输出块则用 `.claude/docs/config-resolution.md` 默认值） | 评审模式、提问节奏、ADR 范围、散文深度、校验者构成 |
| 读取 | 引擎上下文（Phase 1，`references/1-engine-context.md`，"ALWAYS FIRST"） | 决策必须对照钉定引擎 |
| 读取 | `docs/architecture/` 下既有 ADR | 确定下一个 ADR 编号 |
| 读取 | 决策上下文（Phase 3，`references/3-gather-context.md`） | 决策依据 |
| 读取 | `docs/architecture/architecture.md` 的 `## Required ADRs` 节、`docs/architecture/adr-*.md` 列表；无 architecture.md 时查 `technical-preferences.md` / `systems-index.md` 中标记的前置 ADR | 收尾判断哪些必需 ADR 尚未写 |
| 产出 | `docs/architecture/adr-*.md`（新 ADR，状态由 Step 5 保证为 `Proposed`）；注册表可选更新 | ADR 编号连续递增 |
| 派生智能体 | `technical-director`（门禁 TD-ADR）+ 引擎专家（engine-specialist）——任何 `team.size` 档位都是这两个；本技能在任何规模下都不派引擎子专家、不派对抗性评审者 | `team.size` 与 review_mode/workflow 正交 |

**配置键档位**：
- `team.size`：`individual`（默认）= TD + 引擎专家；`small` 与 `studio` = 同样两个。
- `docs.density`（控制 ADR 散文节的"深度"，骨架固定产出的节不随档位增减；`modes.rigor` 与 `workflow` 联动设定它，显式设置可单独调 ADR 冗长度）：`terse`（默认，经 `rigor: minimal`）= 决策 + 备选方案作条目，各一行理由；`balanced` = 每节一段、轻量理由（`rigor: standard`）；`thorough` = 完整散文体，Decision、Alternatives、Consequences 含权衡与成型的论证。Engine Compatibility、ADR Dependencies、GDD Requirements 三张表是结构性内容，任何密度下都保持完整。
- `workflow`：`full` = 必需 ADR 清单上的全部 ADR 都要完成；`standard` = 仅关键 ADR（Foundation 层系统）；`minimal` = 不要求（可自愿运行）。

## 3. 核心规则（逐条编号 R1、R2……）

**模式分派与参数守卫（Step 0）**
R1. 参数以 `retrofit` + 文件路径开头时必须立即读取并遵循 `references/0-retrofit.md`；以 `accept` + ADR 编号开头时必须立即读取并遵循 `references/0-accept.md`；两者皆非时进入常规 ADR 撰写流程。会话压缩或恢复后处于该阶段必须重读对应文件。（出处：Step 0）
R2. 无参数守卫：标题为空时必须在运行 Phase 0 前询问"你要记录什么技术决策？请给出简短标题（如 `event-system-architecture`、`physics-engine-choice`）"，以用户回答为标题再继续。（出处：No-argument guard）
R3. 每次 `AskUserQuestion` 必须遵循 `.claude/docs/automation-modes.md`（collaborative 恒提问 · guided 仅重大事项 · autonomous 记录后继续；`automation_always_ask` 类别恒提问）；派生智能体自读其 `.claude/docs/director-gates/[gate-id].md` 门禁文件，父会话禁止代读。（出处：Step 0）

**撰写流程（Steps 1–5）**
R4. 第一步必须加载引擎上下文（"ALWAYS FIRST"），步骤在 `references/1-engine-context.md`；随后扫描 `docs/architecture/` 既有 ADR 确定下一个编号；再按 `references/3-gather-context.md` 收集上下文、`references/4-decide.md` 协作引导决策、`references/5-generate.md` 生成 ADR。各阶段文件进入时必读、压缩/恢复后重读。（出处：Steps 1–5）
R5. ADR 生成后的状态必须是 `Proposed`（由 Step 5 保证）——Accepted 只能经 `accept` 模式（`/architecture-decision accept ADR-NNNN`）达成。（出处：Step 6 / Do NOT unblock）

**收尾下一步（Step 6）**
R6. ADR 写完（注册表可选更新）后必须以 `AskUserQuestion` 收尾；生成选项前必须：① 读取 `docs/architecture/architecture.md` 的 `## Required ADRs` 节并逐一对照 `docs/architecture/adr-*.md`——必需但无文件的 ADR 仍未写（无 architecture.md 时改查 technical-preferences.md / systems-index.md 标记的前置）；② 若前置 ADR 已全部写完，加入"开始写 GDD"选项；③ 把**全部**剩余优先 ADR 逐个列为独立选项，禁止只列最近一两个。（出处：Step 6）
R7. 收尾组件格式必须为："[N] ADR-[NNNN] written and registry updated. 接下来做什么？"——选项含每个剩余优先 ADR（附前置清单中的简述）、"Start writing GDDs — 运行 `/design-system [首个未设计系统]`"（仅当全部前置 ADR 已写）、"Stop here for this session"。无剩余优先 ADR 且无未设计 GDD 系统时只提供"Stop here"并建议在新会话运行 `/architecture-review`。（出处：Step 6）
R8. 收尾输出必须**固定包含**以下通知、禁止省略："要在新会话中运行 `/architecture-review` 校验 ADR 对 GDD 的覆盖。**禁止在与 `/architecture-decision` 相同的会话运行 `/architecture-review`**——评审智能体必须独立于撰写上下文才能给出无偏评估，同会话运行会使评审失效。"（出处：Step 6 fixed notice）
R9. 禁止在本技能内解锁（unblock）任何 story：本 ADR 是 `Proposed`，因等待该决策而 `Blocked` 的 story 仍保持 pending——在撰写时解锁会让守卫在最相关的时刻失效（管线看似畅通，实际运行在无人接受的决策上）。必须转而告知用户当前等待接受的事项："ADR-NNNN 已写、状态 `Proposed`。[N] 个 story 仍因它 `Blocked`。决策敲定后运行 `/architecture-decision accept ADR-NNNN`——那才是把它们移到 `Ready` 的动作"，并按路径列出被阻塞的 story，让"留它 Proposed"的代价可见。（出处：Do NOT unblock stories）
R10. `docs.density` 只作用于 ADR 散文节的深度（档位见"数据依赖"节）；三张结构性表格任何密度下保持完整。（出处：docs.density 段）

## 4. 门禁与裁决
- 评审门禁：`technical-director` 执行 **TD-ADR** + 引擎专家校验（`team.size` 任何档位均为此二者，不派引擎子专家与对抗性评审者）；完整检查模式见 `.claude/docs/director-gates.md`，门禁定义在被派智能体自读的 `.claude/docs/director-gates/[gate-id].md`。
- ADR 状态机：`Proposed`（撰写产出）→ 经 `accept` 模式 → `Accepted`；story 解锁只认 `Accepted`。

## 5. 移植建议
- **可直接移植**：R2（无参数先问标题）、R4（先读技术栈/平台上下文再决策）、R6–R9（收尾枚举全部待写决策、跨会话评审独立性、决策未接受不解锁下游任务）——特别是"撰写者与评审者必须分会话"和"Proposed 不解锁"两条纪律，任何项目通用。
- **需替换概念**：ADR → 技术决策记录（TDR/ADR）；引擎 → 锁定的框架/平台版本；GDD → 需求文档；story → 任务/工单（`Blocked`/`Ready` → 阻塞/就绪）；`/design-system` → 需求拆解命令。
- **改写示例**：
  - "决策记录写完后状态为 Proposed；禁止在撰写会话中解锁任何因等待该决策而阻塞的任务——只有显式的接受流程（accept）能把它们转为就绪。"
  - "决策评审必须在与撰写不同的新会话中运行：评审者独立于撰写上下文才无偏，同会话运行即评审失效。"

## 6. 关联文档
- 上游：`/create-architecture`（提供 `## Required ADRs` 清单与蓝图上下文）
- 下游：`/architecture-review`（校验 ADR 覆盖，必须新会话运行）、`/architecture-decision accept`（转 Accepted 并解锁 story）、`/design-system`（全部前置 ADR 写完后开始写 GDD）
- 规范文档：`.claude/docs/director-gates.md`、`automation-modes.md`、`workflow-modes.md`、`config-resolution.md`
