# help — 上下文感知的下一步建议（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/help/SKILL.md) ｜ 阶段：Any ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/help`（可选参数：刚完成什么/卡在哪，如 "finished design-review"、"stuck on ADRs"）
- **一句话职责**：回答"我接下来做什么？"——轻量定位当前所处阶段与首个必需步骤，给出唯一主推荐；不是全量审计（那是 `/project-stage-detect`）。
- **触发前置**：卡住、不知道下一步；只读、不写任何文件。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | resolve_config 预解析块：`project.stage`、`workflow` | 运行前由 shell 解析好，按原样使用、**禁止**重读。`project.stage` 是 Step 2 的权威相位（已应用 `project.yaml`→`production/stage.txt` 回退，保留含空格值如 `Systems Design`）；`workflow` 是 Step 2/5 的档位。块未渲染（shell 预处理被关）→ 回退 `.claude/docs/config-resolution.md` 的默认值 |
| 读取 | `.claude/docs/workflow-catalog.yaml` | 全部阶段、有序步骤、required/optional、完成度工件 glob 的权威目录 |
| 读取 | `.claude/skills/*/SKILL.md` 的 frontmatter `name:` | 找目录外技能 |
| 读取 | `production/session-state/active.md` 的 STATUS/CHECKPOINT 块（无标记则读最后一个 `## Session Extract` 块） | 用户刚做什么、进行中任务（schema：`.claude/docs/templates/session-state.md`） |
| 读取 | `bash .claude/scripts/artifact-check.sh --phase [phase]`（minimal 用 `--path minimal`） | 一次性确定性评估目录内每步的 `glob`/`pattern`/`min_count`/`any_of`，每步一行状态 |
| 读取 | `production/sprint-status.yaml`（production 阶段且存在时） | 每条 story 的精确状态，权威于 glob 检查 |
| 读取 | story 状态清单——由 `.claude/scripts/story-status.sh` 在技能读取前自动打印 | 已按路线顺序排好：`IN_REVIEW`→`IN_PROGRESS`→`TODO`→`BLOCKED`/`OTHER`/`NO_STATUS` + `COMPLETE` 计数 |
| 产出 | 无（只读技能，报告发现、不写文件） | — |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则（逐条编号 R1、R2……）

### 总纪律
R1. 本技能只读——报告发现但**禁止**写任何文件。（技能头）
R2. 必须先取配置块里的 `workflow`：为 `minimal` 时项目走 minimal 路线而非阶段梯队——跳过 Step 2 其余部分，读会话上下文（Step 3）后直达 Step 4m；该档位下**禁止**映射 `project.stage`——minimal 路线不跑 `/gate-check`，stage 无论进展都停在 Concept，硬走 Concept 阶段会把已有 stories 的项目拽回 concept 文档、art bible 和 systems map。（Step 2）

### Step 1/1b：目录与目录外技能
R3. 必须读 `.claude/docs/workflow-catalog.yaml`——它是全部阶段、步骤顺序、required/optional、完成度工件 glob 的权威清单。（Step 1）
R4. 读目录后必须 Glob `.claude/skills/*/SKILL.md` 提取各 frontmatter `name:`，与目录 `command:` 值比对；不在目录中的即"uncataloged skill"（可用但不属于阶段门控流程）。仅当至少存在一个时，输出 footer 块 "### Also installed (not in workflow)"（`/skill-name` — frontmatter 描述），并按当前阶段相关性限 10 个（如 QA 技能对应 production、团队技能对应 production/polish）。（Step 1b）

### Step 2：确定当前阶段
R5. 非最小档时按序判定：先取配置块的 `project.stage`（已解析，**禁止**重读），映射目录 phase key（`Concept`→`concept`、`Systems Design`→`systems-design`、`Technical Setup`→`technical-setup`、`Pre-Production`→`pre-production`、`Production`→`production`、`Polish`→`polish`、`Release`→`release`）；两者都没设才按工件推断（最先进匹配胜出）：代码根 ≥10 源文件→`production`；`production/epics/**/story-*.md`→`pre-production`；`docs/architecture/adr-*.md`→`technical-setup`；`design/gdd/systems-index.md`→`systems-design`；`design/gdd/game-concept.md` 或 `design/game-brief.md`→`concept`；什么都没有→`concept`（全新项目）。（Step 2）
R6. `workflow` 档位控制 Step 5 是否把可选文档列为下一步。（Step 2）

### Step 3：会话上下文
R7. 必须读 `production/session-state/active.md`（若存在）——**只**读 STATUS 和 CHECKPOINT 块（用 Grep 找 `<!-- /?(STATUS|CHECKPOINT) -->` 标记，从第一个读到最后一个），下面的叙事可能很长。无标记的旧文件：改读其最后一个 `## Session Extract` 块。提取：最近在做什么、进行中任务/未决问题、STATUS 块里的当前 epic/feature/task。每个档位都要跑；`minimal` 下它是 Step 4m 唯一依赖的 checkpoint 读取。读完 `minimal` 直达 Step 4m（不走 Step 4）。（Step 3）

### Step 4：阶段步骤完成度检查
R8. 工件检查必须一次确定性调用 `bash .claude/scripts/artifact-check.sh --phase [current-phase]`，**必须**按原样执行：项目根目录、相对路径、无绝对路径、无 `cd`、无 `2>&1`——权限授权只匹配这一种形式，其它形式都会请求用户批准。**禁止**用 Glob/Grep 重新推导任何结果。（Step 4）
R9. 状态映射必须照抄：`PRESENT`→Complete；`ABSENT`→Incomplete；`SHORT`→Incomplete 且说明差多少（`count=`/`min=` 已给出）；`PATTERN_MISS`→Incomplete 且说明"文件存在但缺标记"——说"missing"会引导用户重建一个已有的文件；`NO_CHECK`→有 `note=` 则 MANUAL，否则 UNKNOWN（完成度不可追踪，如可重复的实现工作）。（Step 4）
R10. `any_of` 是备选清单——一个匹配即足够；手工评估有假"incomplete"风险：如 `engine-setup` 由 `project.yaml` 的 `engine.name` **或** `.claude/docs/technical-preferences.md` 的遗留 `Engine:` 行满足，脚本会报哪个备选命中（`alt=`/`match=`）。（Step 4）
R11. `NO_CHECK` **绝不**等于已完成。脚本在行前打印 `NO_CHECK:` 总数；一个阶段大部分是 NO_CHECK 时必须直说，**禁止**暗示阶段接近完成。（Step 4）
R12. 当前阶段为 `production` 时，做任何 glob 式 story 检查前必须先查 `production/sprint-status.yaml`；存在则直接读：`in-progress`→"currently active"、`ready-for-dev`→"next up"、`done`→计入完成、`blocked`→连同 `blocker` 字段作为阻塞呈现。跳过 `implement` 与 `story-done` 两步的 glob 工件检查——YAML 是权威。（Step 4 特例）
R13. 非生产阶段的 `repeatable: true` 步骤（如 "System GDDs"）：工件检查只说明"是否做过"，不说明"是否做完"——必须换标签：展示已检出的内容，并注明可能仍在进行。（Step 4 特例）

### Step 4m：minimal 路线（仅 `workflow: minimal`）
R14. `minimal` 下路线是目录的 `paths.minimal` 而非某个阶段：引擎→`design/game-brief.md`→stories→`/dev-story`↔`/story-done`。必须一次调用 `bash .claude/scripts/artifact-check.sh --path minimal` 解析，状态映射同 Step 4；`implement` 与 `story-done` 设计时就是 NO_CHECK——story 状态行就是它们的检查。（Step 4m）
R15. 下一步取第一个适用项：1）`engine-setup` 非 PRESENT→`/setup-engine`；2）`game-brief` 非 PRESENT→代码根已有 ≥10 个源文件（与 Step 2 的 production 判据同）用 `/reverse-document design [code root]`（从成品写 brief），否则 `/brainstorm`（`minimal` 下写一页 brief；对已建成的游戏会变成开新想法）；3）`create-stories` 非 PRESENT→无参 `/create-stories`（直接从 brief 的 MVP 列表建 stories）；4）stories 已存在→看 story 状态清单。（Step 4m）
R16. 状态清单已由脚本预打印且即最新：**禁止**重跑脚本、重读或重排 story 文件。Next up = 第一条 `IN_REVIEW`/`IN_PROGRESS`/`TODO` 行上的 story。In Review 的 story 先于 In Progress 的收尾——其工作已写下，`/story-done` 很快。（Step 4m）
R17. 逐状态处置：`IN_REVIEW`→`/story-done [path]`；`IN_PROGRESS`→**没**完成——无论代码或提交如何暗示，只有 `/story-done` 才能使 story Complete；仅当用户、`active.md` 或 git log 表明其实现已写完才推荐 `/story-done [path]`，否则 `/dev-story [path]` 继续；`TODO`→`/dev-story [path]`；`BLOCKED`→点名 story 及其 blocker，**绝不**作为 Next up。（Step 4m）
R18. 无 `IN_REVIEW`/`IN_PROGRESS`/`TODO` 行但残留 `BLOCKED`/`OTHER`/`NO_STATUS`：没有可建的下一步，且 build order 未完——逐条点名（状态照抄，blocked 的 blocker 从该 story 文件读出）；Next up 是清除其中第一个：解 blocker，或给 `OTHER`/`NO_STATUS` 的 story 一条路线可读的 `Status:` 行（可建时写 `Ready`）。（Step 4m）
R19. 全部 story `Complete`（或 `Done`）→brief 的 build order 已完成：如实说，并给出路三条——玩构建成品；用 `/create-stories` 从 brief 追加下一批 story；游戏已超出一页 brief 时用 `/settings` 调高 `modes.rigor`。（Step 4m）
R20. `minimal` 下**绝不**把以下任何一项呈现为必需或阻塞：游戏 concept 文档、art bible、systems map、GDDs、`/create-epics`、sprint 计划、`/gate-check`、sprint 收尾（`/smoke-check`、`/team-qa`、`/retrospective`）。brief 替代设计文档，其 build order 替代 sprint 计划（workflow-modes.md——minimal 底线）。用户点名要时每一项照跑；只有用户参数问起才提。（Step 4m）
R21. `minimal` 下跳过 Step 5 与 Step 8，Step 7 用 minimal 输出形状。（Step 4m）

### Step 5/6：定位与进行中工作
R22. 从完成度数据判定四项：最后确认完成的步骤（最靠后的已完成 required 步骤）；当前 blocker（第一个未完成 required 步骤=用户下一步）；可选机会（未完成 optional 步骤，按档位呈现：`full` 全列；`standard` 只列当前系统/阶段所需者，**禁止**把真正可选的文档标记为缺口；`minimal` 不跑本步，由 Step 4m 取代）；后续必需步骤（blocker 之后，以"coming up"呈现供提前规划）。（Step 5）
R23. 用户给了参数（如 "just finished design-review"）时，即使用于越过其所指步骤，即使工件检查结果含糊。（Step 5）
R24. `active.md` 显示有活动任务或 epic：置顶显著呈现 "It looks like you were working on [X]"，建议继续或确认是否已完成。（Step 6）

### Step 7/8：输出与门禁提示
R25. 输出必须短而直接（快速定向，不是报告），按模板：`## Where You Are: [Phase Label]`、In progress、`### ✓ Done`、`### → Next up (REQUIRED)`（含 `Command: [/command]`）、`### ~ Also available (OPTIONAL)`、`### Coming up after that`、结尾门禁行 "Approaching **[next phase]** gate → run `/gate-check` when ready."。格式：`✓` 已确认完成；`→` 当前唯一必需下一步（只有一个——第一个 blocker）；`~` 现在可做的可选步骤；命令行内反引号展示；无命令的步骤解释怎么做而非给斜杠命令；MANUAL 步骤问用户 "I can't tell if [step] is done — has it been completed?"。（Step 7）
R26. `minimal` 用另一种形状：无阶段标签、无门禁行，`## Where You Are: Minimal path — [N] of [M] stories complete`；N 只数状态行为 `Complete` 或 `Done` 的 story，✓ Done 只给计数不给标题（N、M 即 `COMPLETE` 行上的两个数）；Next up 按状态给 `/story-done [story-path]`（In Review 或工作已写完的 In Progress）或 `/dev-story [story-path]`；Coming up 最多列 3 个后续 Ready story。（Step 7）
R27. Verdict：**COMPLETE**——下一步已识别。（Step 7）
R28. Step 8 在 `minimal` 跳过（无阶段门控）。当前阶段全部必需步骤完成（或接近完成）时加："You're close to the **[Current] → [Next]** gate. Run `/gate-check` when ready."；剩多个必需步骤则跳过——尚不相关。（Step 8）

### Step 9：升级路径
R29. 仅当用户输入显出困惑（如 "I don't know"、"stuck"、"lost"、"not sure"）才附加升级块（简单 "what's next?" 不加）：`/project-stage-detect`（全量缺口分析）、`/gate-check`（下一阶段正式就绪检查）、`/start`（从头重新定向）、`/settings`（流程与项目不匹配时调 `modes.rigor`）。`/settings` 的 rigor 行只在 settings-guidance.md §4 触发器真的命中时展示：用户被流程压垮（且 rigor 还不是 `minimal`）→降档；项目已超出当前档（系统众多，或在 `workflow: minimal` 下已进 Production）→升档。`minimal` 下省去 `/gate-check` 行。（Step 9）

### 协作协议
R30. **绝不**自动运行下一个技能——只推荐，由用户调用。（Collaborative Protocol）
R31. MANUAL 步骤必须询问用户，**禁止**臆断完成或未完成。（Collaborative Protocol）
R32. 必须匹配用户语气——用户听起来有压力（"I'm totally lost"）时给安抚和**一个**行动，不是六个选项的清单。（Collaborative Protocol）
R33. 必须只有一个主推荐——用户离开时清楚知道接下来要做的一件事；可选步骤与"coming up"只是次级上下文。（Collaborative Protocol）

## 4. 门禁与裁决
- 无自身门禁。裁决性规则：状态映射表（R9）、"最先进匹配胜出"的阶段推断（R5）、`minimal` 下的路线优先级与逐状态处置（R15–R19）、门禁提示的触发条件（R28）。

## 5. 移植建议
- **可直接移植**：R1、R3、R7–R13、R22–R33——"只读诊断 + 一次性确定性检查脚本 + 状态映射不重推导 + NO_CHECK 不算完成 + 唯一主推荐 + 绝不自动跑下一步"，是任何工作流导航助手的通用骨架。
- **需替换概念**：`workflow-catalog.yaml` → 目标项目的阶段/步骤目录（含 required/optional 与完成度工件）；`workflow` 档位 → 流程强度档；`project.stage`/`production/stage.txt` → 项目状态键及其遗留回退；`artifact-check.sh`/`story-status.sh` → 你的确定性检查脚本；游戏阶段名 → 领域里程碑；story 状态词（`IN_REVIEW` 等）→ 你的任务状态机。
- **改写示例**：
  - "工件完成度必须由一个确定性脚本一次算齐，禁止用 glob 逐项重推导；脚本输出 NO_CHECK 的步骤绝不视为已完成，一个阶段大部分不可追踪时必须直说。"
  - "回答'下一步做什么'时必须只给一个主推荐并显式标注；绝不自动运行所推荐的技能，由用户亲手调用。"

## 6. 关联文档
- 上游：`/start`（重新定向）
- 下游（只推荐）：`/setup-engine`、`/brainstorm`、`/reverse-document`、`/create-stories`、`/dev-story`、`/story-done`、`/gate-check`、`/settings`
- 升级路径：`/project-stage-detect`（全量缺口分析）
- 引用 docs：`.claude/docs/workflow-catalog.yaml`、`.claude/docs/config-resolution.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/settings-guidance.md` §4、`.claude/docs/templates/session-state.md`
- 脚本：`.claude/scripts/artifact-check.sh`、`.claude/scripts/story-status.sh`
