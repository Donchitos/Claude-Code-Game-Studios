# team-release — 发布协调团队（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-release/SKILL.md) ｜ 阶段：Phase 7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-release [version number or 'next'] [--review full|lean|solo]`
- **一句话职责**：编排发布团队从候选构建走到部署——发布计划→版本候选→质量门→本地化/性能/分析→Go/No-Go→部署→发布后监控，产出完整发布记录。
- **触发前置**：版本号可由参数给出、或从 `production/session-state/active.md` 与最近 `production/milestones/` 文件推断（须向用户确认）；`/gate-check release` 已 PASS（`project.stage` 为 `Release`）；配置经 resolve_config 解析（`review_mode, automation, team.size, workflow, project.stage`）；自动化模式遵循 `.claude/docs/automation-modes.md`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, automation, team.size, workflow, project.stage`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | stage check 与活跃集依据 |
| 读取 | `project.yaml` 的 `platform.online`、`platform.multiplayer`（Phase 3 条件判断；**键缺失不等于 `false`**）；`production/session-state/active.md` + `production/milestones/` 最新文件（无参数时推断版本）；Polish 阶段的 `/release-checklist` 与 `/changelog`、`/patch-notes` 草稿 | 条件 spawn、版本推断、Phase 2/6 定稿 |
| 产出 | `production/releases/` 下 12 份：`release-plan-[version].md`、`release-checklist-[version].md`（目的地由 `/release-checklist` 固定）、`qa-gate-[version].md`、`build-[version].md`、`security-signoff-[version].md`、`netcode-signoff-[version].md`、`localization-signoff-[version].md`、`performance-signoff-[version].md`、`analytics-signoff-[version].md`、`go-no-go-[version].md`、`announcement-[version].md`、`release-report-[version].md`；加 `docs/patch-notes/[version].md`（目的地由 `/patch-notes` 固定） | 共 13 份、每智能体一份——**禁止一份追加式记录**：Phase 3/4 并行向同一文件追加会竞争，输者小节无声消失；活跃智能体代班时写被代智能体的那份文件 |
| 派生智能体 | `release-manager`（发布 tag、版本号、changelog、patch notes、部署）；`qa-lead`（测试签核、回归套件、发布质量门）；`devops-engineer`（构建管线、产物、部署自动化）；`security-engineer`（发布前安全审计——有在线/多人/玩家数据时）；`network-programmer`（netcode 稳定签核——多人游戏时）；`analytics-engineer`（遥测事件与看板验证）；`localization-lead`（全字符串翻译签核）；`performance-analyst`（发布构建对标性能目标基准）；`community-manager`（基于 patch notes 的发布公告与玩家侧沟通）；`producer`（Go/No-Go 决策、利益相关者沟通、排期）；`technical-director`（Phase 5 发布候选技术签核，**仅 `review_mode: full`** spawn） | 活跃集由 `team.size` 决定（见 R4） |

## 3. 核心规则（逐条编号 R1、R2……）

### 入口与配置
R1. **参数检查**：无版本号 → 读 `production/session-state/active.md` 与 `production/milestones/` 最新文件推断目标版本；推断到 → 报告 "No version argument provided — inferred [version] from milestone data. Proceeding." 并用 `AskUserQuestion` 确认 "Releasing [version]. Is this correct?"；推不到 → `AskUserQuestion` 问 "What version number should be released?" 等用户输入。**禁止默认到硬编码版本字符串**。（出处：Argument check）
R2. **Stage check 先于一切 spawn**：本技能交付发布，`/gate-check release` 是必须先过的就绪门禁，只有其 PASS 把 `project.stage` 设为 `Release`。解析出的 `project.stage` 是其他任何值（`Polish`、更早阶段、未设）→ 在 Phase 1 前停止、不 spawn 任何智能体，报 "The release readiness gate has not passed (project.stage: [stage]) — run /gate-check release first."。随后**在任何 automation 模式下**都用 `AskUserQuestion`（覆盖决定绝不代用户做）：`[A] Stop — I'll run /gate-check release (recommended)` / `[B] Proceed anyway — override the stage check`；A → 结束运行，Verdict **BLOCKED**；B → 纯文本问原因，把覆盖记录为 `Stage override: project.stage was [stage] — release gate not passed; the user chose to proceed: [reason]`，写入 Phase 1 简报、go/no-go 记录（`go-no-go-[version].md`）与最终报告。**覆盖从不改变 stage 本身**。（出处：Phase 0 Stage check）
R3. 本管线**无 director gate**：任何 `review_mode` 下都不派生 CD-/TD-/PR-/AD-PHASE-GATE；本管线的 phase gate = Decision Points 转换、stage check、Phase 6 部署问题，**无论 automation 模式**。（出处：Phase 0）

### 活跃集（team.size）
R4. `team.size` 决定活跃集：`individual`（默认）= `release-manager` 独一个，其余经它咨询不单独 spawn；`small` = + `producer` + `devops-engineer` + `qa-lead` + `community-manager`；`studio` = + `security-engineer` + `analytics-engineer` + `localization-lead` + `performance-analyst`，及多人游戏时的 `network-programmer`。（出处：Phase 0 team.size）
R5. **Phase 1 前必须一行宣布活跃集，禁止让收缩沉默**：声明本次实际 spawn 谁、管线提名但**不** spawn 谁（经最近活跃核心智能体咨询，"Raise team.size (or modes.rigor) to widen"）。"被强制执行却从未浮现的约束与从未执行的约束无法区分"——`team-release` 提名十个、默认只跑一个，不说明则读者无法区分正确收缩与坏掉的管线。（出处：Announce the active set）
R6. 活跃集之外的智能体经最近活跃核心智能体路由并附说明性注释，适用全管线；"phase gates only" 限制的智能体只在那些点 spawn。（出处：Phase 0 team.size）

### 委派协议
R7. **简报不倾倒上下文**：共享输入只读一次，传蒸馏后的内联简报；已读文档禁止只丢路径；只对未读且仅该智能体需要的文档传路径。（出处：How to Delegate）
R8. **每个智能体 prompt 以返回契约结尾**："把完整输出写到 `[path]`——该命名路径即有界例外下的写授权，无需另问；只返回 (1) 路径、(2) ≤5 条决策摘要、(3) BLOCKED/CONCERNS 各一行；禁止复述读过的文档。"（出处：How to Delegate）
R9. **有界写例外三条件**：(1) 路径是**你**在 prompt 命名的；(2) 是 `production/`、`docs/`、`tests/` 下的**新**产物；(3) 产出它的阶段受 `AskUserQuestion` 门禁。三条件外必须问；**禁止按 subagent 逐个问来"修复"**。Phase 3 智能体可并行启动。（出处：How to Delegate + bounded exception）

### 管线
R10. **Phase 1 发布计划**（producer）：确认全部里程碑验收标准达标；识别本版推迟的范围项；定目标发布日期并沟通团队；输出带范围确认的发布授权。（出处：Phase 1）
R11. **Phase 2 发布候选**（release-manager）：在 `main` 上 bump 所有相关文件的版本号，携带 bump 的 commit 即发布候选；**开发是 trunk-based——发布是 `main` 上的 tag（Phase 6 打），不是分支**；确认 Polish 阶段的 `/release-checklist`（先于 `/gate-check release` 跑）对该候选完整，没有则现在跑；**仅当**本版需要稳定（冻结、平台认证）才从候选切 `release/[version]` 分支——那里只修 bug，且每个 fix 也落 `main`。（出处：Phase 2）
R12. **Phase 3 质量门（并行）**：`qa-lead`——跑完整回归套件、测全部关键路径、验证无开放 bug 达 `/gate-check release` 对该 `workflow` 拦截的严重度（**S1 每档；`full` 档连 S2、S3**）、签核质量；`devops-engineer`——全目标平台构建发布产物、构建干净可复现、CI 跑自动化测试；`security-engineer`（**有在线特性、多人或玩家数据时**）——发布前安全审计：认证、反作弊、数据隐私合规、安全姿态签核；`network-programmer`（**多人时**）——netcode 稳定签核：延迟补偿、重连处理、负载下带宽。（出处：Phase 3）
R13. Phase 3 条件从 `project.yaml` 的 `platform.online` 与 `platform.multiplayer` 加"是否存玩家数据"判断；**键缺失不是 `false`**——问用户，禁止假想一个单机游戏；按此理由跳过的智能体在 Phase 3 输出中**指名说明**（例：`security-engineer: not spawned — platform.online: false, platform.multiplayer: false, no player data`）。（出处：Phase 3）
R14. **Phase 4 本地化/性能/分析**（可与 Phase 3 并行）：全字符串已翻译（`localization-lead`）；对目标跑性能基准（`performance-analyst`）；`analytics-engineer`——验证全部遥测事件在发布构建上正确触发、看板在收数、关键漏斗（onboarding、progression、适用时的 monetization）有埋点。一智能体一份签核文件（§2 表）。（出处：Phase 4）
R15. **Phase 5 Go/No-Go**：委派前先取 **technical-director** 发布签核——producer 不能 spawn 智能体所以由编排器代 spawn；**仅 `review_mode: full`**（这是 director review 而非 PHASE-GATE，`lean`/`solo` 跳过）；要 GO / CONCERNS / NO-GO，或点名读不到内容的 NOT ASSESSED；未 spawn 时 go/no-go 记录写 `technical-director sign-off: not run (review_mode: <mode>)` 而非列为已给；**NOT ASSESSED 答案如实记录、永不计为签核**。（出处：Phase 5）
R16. 委派 **producer**（传入已收集的全部签核：qa-lead、release-manager、devops-engineer、Phase 3 spawn 的 security-engineer 与 network-programmer、上述 technical-director）：有 stage-check 覆盖则其 `Stage override:` 行随记录带入；评估开放问题（阻塞还是可带病发布）；做 go/no-go 决定并给出理由。（出处：Phase 5）
R17. **NO-GO 处理**：立即呈现决定（"PRODUCER: NO-GO — [rationale]"）；`AskUserQuestion` 三选项——修复 blocker 重跑受影响阶段 / 推迟发布 / **带文档理由覆盖 NO-GO**（用户必须提供书面理由）；**整体跳过 Phase 6**——不 tag、不部署 staging、不部署 production、不 spawn community-manager；产出总结 Phases 1–5 与跳过内容的部分报告；Verdict **BLOCKED**。（出处：Phase 5）
R18. 用户选 "Override NO-GO" 后：纯文本（非组件）问 "Please describe the justification for overriding the NO-GO verdict. This will be embedded in the release record."，等书面理由；在 Phase 6 前的部分批准记录中追加 "⚠️ Override Justification: [user's text]" 字段；**然后**才进 Phase 6。（出处：Phase 5）
R19. **Phase 6 部署（GO 时）——无条件要求显式用户批准，包括 `autonomous` 模式**：生产部署不可逆且高风险，**不在**可配的 `automation_always_ask` 类别覆盖范围内，本技能无条件守卫它。tag 或部署前 `AskUserQuestion`："Producer verdict is GO. Execute Phase 6 — tag, deploy to staging, deploy to production?" 选项 `[A] Yes, deploy` / `[B] Staging only — hold production` / `[C] Stop here`。批准后才委派 **release-manager + devops-engineer**：打发布 tag；定稿 Polish 起草的 `/changelog`（补门禁之后的变化）；部署 staging 做最终冒烟；**仅当用户上面批准 production** 才部署生产；人工团队动作——发布后监控看板与错误率 48 小时，48 小时点排 `/retrospective`。（出处：Phase 6）
R20. Phase 6 并行：委派 **release-manager** 用 `/patch-notes [version]` 定稿 patch notes——**release-manager 携带该技能及其 `git log` 步骤所需的 Bash 访问，community-manager 两者都没有**；然后把 patch notes 交给 **community-manager**：准备发布公告（商店页更新、社媒、社区帖）、有 S3+ 问题发布时起草已知问题帖、输出 deploy 确认后即可发布的全部玩家侧沟通。（出处：Phase 6）
R21. **Phase 7 发布后**：`release-manager` 出发布报告（发了什么、推迟了什么、指标）；`producer` 更新里程碑跟踪并沟通利益相关者；`qa-lead` 监控 bug 报告查回归；`community-manager` 发布全部玩家沟通并监控社区舆情；`analytics-engineer` 确认线上看板健康、缺失关键事件时告警；保持 Phase 6 的 **48 小时监控窗**（bugs、看板、舆情；release-manager 自己的 watch 跑到其 72h 报告）；发生问题则排发布后复盘。（出处：Phase 7）

### 收尾
R22. **先验证工件**：返回契约命名了路径的，先确认路径在盘上——**命名工件不在磁盘即失败阶段，无论回复多流畅**；点名未满足的契约让其续跑。任何智能体 BLOCKED/错误/不能完成：立即呈现、不越过其阻塞的依赖、总出部分报告。（出处：Error Recovery Protocol）
R23. 常见阻塞：输入文件缺失 → 重定向到创建它的技能；ADR 为 Proposed → 不实现，决定后 `/architecture-decision accept ADR-NNNN`；范围过大 → `/create-stories` 拆分；ADR 与 story 冲突 → 呈现冲突不猜。（出处：Error Recovery Protocol）
R24. **File Write Protocol——sub-agents 与 sub-skills 规则不同，此处比管线任何地方都关键**：经 `Agent` 派生的 sub-agents 走有界例外（R9 三条件）；**sub-skills 不是 sub-agents，例外不达它们**——走正常协作协议、写前必问。本编排器不直接写文件。**这里的一切都不授权外向或不可逆动作——tag、push、构建、商店变更无论适用哪条规则都要求显式确认**。（出处：File Write Protocol）
R25. 汇总报告覆盖：发布版本、范围、质量门结果、go/no-go 决定、部署状态、监控计划。Verdict **COMPLETE**（发布已执行并部署）/ **BLOCKED**（发布停止——stage check 拦下、go/no-go 为 NO、或硬 blocker 未解）。（出处：Output）
R26. 下一步：发布后监控看板 48 小时；发布中出现显著问题跑 `/retrospective`。`project.stage` 除被覆盖外读 `Release`：`/gate-check release` 是 Polish → Release 就绪门禁、在本技能之前跑；**只有 `/gate-check` 改 `project.stage`**（PASS 时，或用户接受其风险的 CONCERNS 时）——本技能从不写它或 `production/stage.txt`；覆盖后 stage 保持原值。`Release` 是 `project.stage` 枚举的**终态**，没有 post-launch 档位值；live/post-launch 状态记在发布报告里，不进 `project.stage`。（出处：Next Steps）

## 4. 门禁与裁决
- **Stage check**（先于一切）：`project.stage` 非 `Release` → 停止 + BLOCKED（推荐）或用户显式覆盖（记录 `Stage override:` 行至三处：Phase 1 简报、go-no-go 记录、最终报告；覆盖不改 stage）。
- **Go/No-Go**（Phase 5）：producer 裁决 GO / NO-GO；NO-GO → 跳过 Phase 6 + BLOCKED，除非用户书面理由覆盖（"⚠️ Override Justification:" 嵌入记录）。technical-director 签核仅 `review_mode: full`，未跑或 NOT ASSESSED 永不计为签核、必须如实记录。
- **Phase 6 部署门禁**：无条件 `AskUserQuestion`（A 部署生产 / B 仅 staging / C 停止），任何 automation 模式下都问——生产部署不在 `automation_always_ask` 可配范围内，本技能硬守卫。
- **质量阈值**（qa-lead，沿用 `/gate-check release` 对 `workflow`）：S1 每档拦截；S2、S3 仅 `full` 档拦截。
- **条件签核缺失显形**：security/network 按 `platform.online`/`platform.multiplayer`/玩家数据判定；键缺失不是 `false`，必须问；跳过须指名留痕。

## 5. 移植建议
- **可直接移植**：R1（版本禁止硬编码默认）、R2（就绪门禁先于一切、覆盖留痕不改状态）、R5-R9（活跃集宣布、返回契约、有界例外）、R12-R13 条件判断后半（配置缺失 ≠ false、跳过指名留痕）、R15（未跑的评审如实记 not run、NOT ASSESSED 不算签核）、R17-R19（NO-GO 分支、书面理由嵌入记录、部署无条件确认）、R24（sub-agents 与 sub-skills 两套写权限、不可逆动作恒确认）、R26（状态枚举终态、本技能不改状态文件）。
- **需替换概念**：`project.stage` / `/gate-check release` → 项目的阶段状态机与就绪门禁；版本推断源（milestones/active.md）→ 项目的版本记录；`platform.online`/`platform.multiplayer` → 产品的部署形态键；changelog/patch notes → 对应发布文档流程；48h 监控窗 → 上线观察期。
- **改写示例**：
  - R19 → "生产部署是管线中唯一不可回退的动作：无论自动化档位如何配置，执行前必须向用户显式确认'执行——打 tag、上预发、上生产'，并允许其选择仅到预发为止。该确认不受任何自动化白名单豁免。"
  - R15 → "评审类签核在某档位下未运行时，记录必须写 'not run (mode: X)'，禁止把它列为已给；评审方回答'无法评估'时同样如实记录——未运行的评审与未通过的评审都不能给流程供签核。"

## 6. 关联文档
- 上游：`/gate-check release`（唯一能把 `project.stage` 推到 `Release` 的门禁）、`/release-checklist`（Polish 阶段清单）、`/changelog`、`/patch-notes`（Polish 起草、Phase 6 定稿）。
- 下游：`/retrospective`（48h 点或问题显著时）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`。
