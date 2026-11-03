# team-qa — 完整 QA 周期团队（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-qa/SKILL.md) ｜ 阶段：Phase 6-7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-qa [sprint | feature: system-name] [--review full|lean|solo]`
- **一句话职责**：编排 QA 团队跑完整测试周期——载入范围→QA 策略（含 smoke 判定）→测试计划→测试用例→手工执行→四态签核报告，每 story 全程留痕。
- **触发前置**：可给 sprint 标识、`feature:` 系统名，或从 `production/session-state/active.md` 推断活跃 sprint（无 sprint 则问哪个 epic，**禁止发明 sprint**）；配置经 resolve_config 解析（`review_mode, automation, team.size, qa.level`）；自动化模式遵循 `.claude/docs/automation-modes.md`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, automation, team.size, qa.level`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | `qa.level` 决定证据形态（见 R1） |
| 读取 | `production/sprints/sprint-*.md`（按 sprint 号匹配）；`production/session-state/active.md` + `production/sprint-status.yaml`（无参数时推断）；`project.yaml` 的 `project.stage`（fallback `production/stage.txt`）；`production/qa/bugs/*.md` 的 `**Severity**`/`**Status**`/`**System**` 行（同 `/bug-triage` 读法）；`production/qa/smoke-*.md`（最近修改一份）；GDD 验收标准（如可用） | 范围、阶段、开放 bug、smoke 状态 |
| 产出 | `production/qa/qa-plan-[sprint]-[date].md`（Phase 3，先问后写）；`production/qa/test-cases/[story-slug]-cases.md`（Phase 4，一 story 一份）；`production/qa/bugs/BUG-[NNNN].md`（Phase 5 FAIL 时）；`production/qa/evidence/[story-slug]/`（截图）+ `production/qa/evidence/[story-slug]-evidence.md`（模板 `.claude/docs/templates/test-evidence.md`）；`production/qa/qa-signoff-[sprint]-[date].md`（Phase 6，先问后写）；追加 `production/session-state/active.md` 一行 QA RUN 注释 | bug 编号 = 目录最高 ID + 1 零填充四位 |
| 派生智能体 | `qa-lead`（QA 策略、测试计划生成、story 分类、签核报告起草）；`qa-tester`（测试用例编写、bug 报告编写、手工 QA 文档） | 仅两个 subagent_type；活跃集由 `team.size` 决定（见 R2），qa-lead 在 `individual` 下仅 phase gate spawn |

## 3. 核心规则（逐条编号 R1、R2……）

### 配置与活跃集
R1. **`qa.level` 决定 Logic / Integration / Config-Data story 的证据形态**：`standard`/`full` 用其自动化测试；`minimal` 免测（`.claude/docs/coding-standards.md`）——证据是 Phase 5 的验收标准 walk，**无测试的 story 读 `WAIVED` 而非缺证据**。UI 与 Visual/Feel 的截图**每级必需**。本管线无 director gate——任何 `review_mode` 都不派生 CD-/TD-/PR-/AD-PHASE-GATE。（出处：Phase 0: Resolve Config）
R2. `team.size` 决定活跃集：`individual`（默认）= `qa-tester` 独跑，`qa-lead` **仅 phase gates** spawn；`small` = `qa-lead` + `qa-tester` 全管线（如文档）；`studio` = `qa-lead` + 每 story 一个 `qa-tester` spawn + 签核。`individual` 下的 qa-lead 属活跃集（带限定词）——**它是被 spawn 的，不是经他人咨询的**。（出处：Phase 0 team.size）
R3. **Phase gate 判定按字面逐条测试**：以 `AskUserQuestion` 决策点结束的阶段才是 gate（管线自列的转换或写明的 Gate 步骤），**无论 automation 模式**——guided/autonomous 里那个问题被跳过或被记录，该阶段**仍是** gate；无决策点的阶段不是 gate，"phase gates only" 智能体不在其上 spawn。非每阶段都是 gate。活跃集外智能体经最近活跃核心智能体路由并附说明。（出处：Phase 0 team.size）
R4. **Phase 1 前必须一行宣布活跃集，禁止让收缩沉默**：声明本次实际 spawn 谁、管线提名但**不** spawn 谁（经最近活跃核心智能体咨询，"Raise team.size to widen"）；带限定词 spawn 的智能体（`individual` 的 qa-lead）进活跃集并带其限定词。被强制执行却未浮现的约束与从未执行的约束无法区分。（出处：Announce the active set）

### 委派协议
R5. **简报不倾倒上下文** + **返回契约**：共享输入只读一次、传蒸馏内联简报，已读文档禁止只丢路径；每个智能体 prompt 以返回契约结尾——"把完整输出写到 `[path]`（该命名路径即写授权，免单独批准）；只返回 (1) 路径、(2) ≤5 条决策摘要、(3) BLOCKED/CONCERNS 各一行；禁止复述读过的文档。"（出处：How to Delegate）
R6. **有界写例外三条件**（本管线条件 3 措辞与其它编排器不同）：(1) 路径是**你**在 prompt 命名的；(2) 是 `production/`、`docs/`、`tests/` 下的**新**产物；(3) 产出它的阶段是**上文定义的 phase gate**——管线列明以 `AskUserQuestion` 结束、无论 automation 模式。三条件外必须问；禁止按 subagent 逐个问来"修复"。`studio` 档 Phase 4 每 story 一个 qa-tester 并行 spawn；低于此一 spawn 覆盖全组。（出处：How to Delegate + bounded exception）

### Phase 1 — 载入范围
R7. 参数检测：sprint 标识（如 `sprint-03`）→ Glob `production/sprints/sprint-*.md` 按 sprint 号匹配——`sprint-3`、`sprint-03`、`sprint-003` 都指 sprint 3（`/sprint-plan` 写 `sprint-NNN.md`）；多个匹配取**最近修改**。`feature: [system-name]` → glob 打该系统标签的 story 文件。无参数 → 读 `active.md` 与 `production/sprint-status.yaml` 推断活跃 sprint；**无 sprint**（`rigor: minimal` 下没有）→ 问覆盖哪个 epic、改用 `feature: [epic-slug]`——**禁止发明 sprint**。（出处：Phase 1）
R8. 读 `project.stage` 确认当前项目阶段；**读范围内已立案的开放 bug**（QA 找新 bug 之前已存在的）：grep `production/qa/bugs/*.md` 的 `**Severity**`/`**Status**`/`**System**` 行；Status 非 `Closed`/`Verified Fixed` 即开放；System 命中在范围 story 所属系统、或点名在范围 story 即在范围——**拿不准就列入**。它们作为 **Open bugs in scope** 进 Phase 2 与 Phase 6 简报——范围开放 S1/S2 已使签核 NOT APPROVED。无 bug 文件 → 记 "Open bugs in scope: none on file"。数完 story 向用户报告："QA cycle starting for [sprint/feature]. Found [N] stories. Open bugs in scope: [N — S1: n, S2: n, or none on file]. Current stage: [stage]. Ready to begin QA strategy?"（出处：Phase 1）

### Phase 2 — QA 策略（qa-lead）
R9. 传给 qa-lead 的简报须含 **Open bugs in scope**（ID、severity、story 或 system），令其：读每个 story 文件；分类 **Logic / Integration / Visual-Feel / UI / Config-Data**；判定哪些 story 需要自动化测试证据 vs 手工 QA——**`qa.level: minimal` 下没有 story 需要测试**：无测试的 Logic/Integration/Config-Data story 在 Automated Required 读 `WAIVED`、其验收标准进手工 QA walk；flag 缺验收标准或缺测试证据的 QA blocker；估手工 QA 工作量（需要的测试场次数）。产出策略表（`Story | Type | Automated Required | Manual Required | Blocker?`）+ Smoke Check 行 + Open bugs in scope 行（开放 S1/S2 以已知失败点名）。（出处：Phase 2）
R10. **Smoke check 程序**：评估 smoke 状态**之前**先 Glob `production/qa/smoke-*.md` 并读最近修改的一份；有报告 → **直接用其 verdict 与发现，禁止重新面谈用户**；无报告 → 记 "No prior smoke check report found — run /smoke-check sprint before proceeding." 并置 **UNKNOWN**（继续时按 PASS WITH WARNINGS 对待）。五态：**PASS** / **PASS WITH WARNINGS [清单]** / **NOT ASSESSED [什么没跑]** / **FAIL [失败清单]** / **UNKNOWN（找不到报告）**——每态带来源（`production/qa/smoke-[date].md` 或 "no report found"）。（出处：Phase 2）
R11. **Smoke 分支**：FAIL → qa-lead 须突出列出失败——QA 不得带着失败的 smoke 越过策略阶段；呈现策略后 `AskUserQuestion` 五选项（Looks good — proceed / Adjust story types / Skip blocked stories / Smoke check failed — fix and re-run / Cancel — resolve blockers first）；选 FAIL 修复 → **不进 Phase 3**，呈现 smoke 报告失败并停止——用户修复、重跑 `/smoke-check sprint`、再重跑 `/team-qa`。UNKNOWN → 警告 "No smoke check report found. Recommend running /smoke-check sprint before QA. Proceeding with caution."。NOT ASSESSED → 呈现报告说什么没跑、同样谨慎继续——**签核不能 APPROVED**（Phase 6）。PASS WITH WARNINGS → 记录供签核报告、继续。有 blocker → 明确列出，用户可跳过 blocked stories 或取消。（出处：Phase 2）

### Phase 3-4 — 测试计划与用例
R12. **Phase 3 测试计划**覆盖：Scope（sprint/feature 名、story 数、日期）；Story Classification Table（Phase 2）；Automated Test Requirements（需测试的 story、`tests/` 预期路径——**`qa.level: minimal` 下无**：把 waived stories 列进 Manual QA Scope）；Manual QA Scope（哪些 story 需手工走查、验证什么）；Out of Scope（明确不测什么、为何）；**Entry Criteria（恒含三条**：(1) smoke PASS 或 PASS WITH WARNINGS 报告存在于 `production/qa/smoke-*.md`，(2) 构建稳定（启动不崩），(3) sprint 范围所有 Must Have story 在 `production/sprint-status.yaml` 为 `in-progress`/`review`/`done`；`feature:` 范围每个 story 文件 Status 为 In Progress/In Review/Complete；可加 sprint 特定条目）；Exit Criteria（全部 story PASS，或 FAIL 且 bug 已立案）。问 "May I write the QA plan to `production/qa/qa-plan-[sprint]-[date].md`?"，**批准后才写**。（出处：Phase 3）
R13. **Phase 4 测试用例（qa-tester）**：仅在 Phase 2 smoke 为 PASS / PASS WITH WARNINGS / NOT ASSESSED / UNKNOWN 时运行（FAIL 已在 Phase 2 停止周期）。对每个需手工 QA 的 story（Visual/Feel、UI、无自动化测试的 Integration——及 `qa.level: minimal` 下**每个**免测的 Logic/Integration/Config-Data story：其用例走其验收标准）：`studio` 档每 story 一 spawn 并行，`small`/`individual` 一 spawn 覆盖全组；每 story 传——story 文件路径、该 story 的 QA plan 相关节、被测系统 GDD 验收标准（如有）、**输出路径 `production/qa/test-cases/[story-slug]-cases.md`——prompt 中明确命名，一 story 一份**。理由：并行 spawn 阶段路径不命名的损害最大——每个智能体自造路径，两次运行把同一工件存两处。（出处：Phase 4）
R14. 每份用例集含：**Preconditions**（开始测试前的游戏状态）、**Steps**（编号、无歧义）、**Expected Result**、**Actual Result**（留空给测试者填）、**Pass/Fail**（留空）。按 story 分组呈现用户审阅，`AskUserQuestion` 每 story 组一批（3-4 组）：Approved — begin manual QA / Revise test cases / Skip manual QA — not ready。（出处：Phase 4）

### Phase 5 — 手工执行
R15. 逐 story 走查批准的手工 QA 清单，3-4 个 story 一批用 `AskUserQuestion`（选项：**PASS** — all acceptance criteria verified / **PASS WITH NOTES** — minor issues found / **FAIL** — criteria not met / **BLOCKED** — cannot test yet）。**等测试者的回答，只记录其所述**——测试者没给的结果**绝不代填**；无人作答的 story 保持**未执行** → 签核 NOT ASSESSED（除非其明说 BLOCKED，否则不是 BLOCKED）。（出处：Phase 5）
R16. **FAIL 处理**：`AskUserQuestion` 收失败描述，然后 spawn `qa-tester` 写正式 bug 报告到 `production/qa/bugs/`，用 `/bug-report` 格式——**Severity 与 Priority 标签精确照该模板**（`S2-High`、`P1-Fix this sprint`……），因 `/bug-triage` 解析它们；命名 `BUG-[NNNN].md`，编号 = `production/qa/bugs/` 最高 ID + 1、零填充四位——使 `/bug-report verify` 与 `close` 能按 ID 找到。（出处：Phase 5）
R17. **证据记录**：Visual/Feel 或 UI story 得 PASS / PASS WITH NOTES 后，把证据记入 `production/qa/evidence/`——请测试者把该 story 触及的每屏/效果各保留一张截图存 `production/qa/evidence/[story-slug]/`，并**确认在盘**（`/story-done` 查的是保留图，不只是 write-up）；UI story 由这些截图关闭，Visual/Feel story 还需 lead 签核。然后问 "May I write the evidence for [story titles] to `production/qa/evidence/`?"（每 story 组一次），写 `production/qa/evidence/[story-slug]-evidence.md`——模板 `.claude/docs/templates/test-evidence.md`、**签核表完整带入**、引用截图。没存截图 → 在 Phase 5 摘要点名该 story **缺保留证据**，禁止写暗示有截图的文档。**签核行保持未勾，除非本会话真的签过**——预勾的批准比没有更糟：把缺失签名变成记录在案的签名。（出处：Phase 5）
R18. **证据不是可选簿记——是下一技能门禁的工件**：`/story-done` glob `production/qa/evidence/` 读 Visual/Feel 与 UI story 的签核表；`/story-readiness`、`/test-evidence-review` 与 gate-release 读同一目录。写去别处 → 一个 story 在此通过完整手工 QA 循环，却被 `/story-done` 告知无视觉证据；Visual/Feel 与 UI 门禁**默认 BLOCKING**（唯 `testing.strict.ui` 或 `.visual` 显式 `false` 才降为 flag）——那即死锁：QA 过了、story 关不了。收齐结果后汇总：PASS / PASS WITH NOTES / FAIL（含立案 bug ID）/ BLOCKED 各多少。（出处：Phase 5）

### Phase 6 — 签核
R19. Spawn `qa-lead` 起草签核报告——**此处返回契约是回复中的报告文本，不是文件**：编排器在本阶段末询问后自己写，qa-lead 不写。**简报只传证据与下述裁决规则，绝不传裁决**：策略表、smoke verdict 及来源、每 story 结果、Phase 5 立案 bug、Phase 1 的 Open bugs in scope、裁决规则 verbatim；禁止点名 verdict、禁止预填 `### Verdict:` 行、禁止说哪个事实决定它。拿到后对照同一规则检查其 verdict，再问写；不一致 → **两个都摆出来问，禁止静默换成自己的**。（出处：Phase 6）
R20. 报告格式：`QA Sign-Off Report: [Sprint/Feature]` + Date；**Test Coverage Summary 表**（`Story | Type | Auto Test | Manual QA | Result`——**范围内每个 story 一行**，BLOCKED 与未执行的也含、Result 给原因——没跑的 story 不能从报告里消失）；**Bugs Found 表**（ID/Story/Severity/Status——**全部**范围开放 bug：Phase 1 在档的 + Phase 5 新立的）；`Verdict`；Conditions（如有）；Next Step。（出处：Phase 6）
R21. **裁决顺序——先查 NOT APPROVED**：范围任何开放 S1/S2 bug（Phase 1 已在档的同 Phase 5 新立的一样算）、或 story FAIL 无 documented workaround → **NOT APPROVED**，无论还有什么没执行——已知失败高于未知，降级成 NOT ASSESSED 会把它埋掉。**然后查前提**：APPROVED 与 APPROVED WITH CONDITIONS 都要求**范围内每个 story 产出已执行的证据**（跑过的测试，或走过的手工用例；`qa.level: minimal` 下验收标准 walk 即已执行证据——测试是 WAIVED 不是缺）——任一 story BLOCKED、未执行或无证据 → **NOT ASSESSED** 而非任一种 APPROVED；Phase 2 的 smoke 为 UNKNOWN（无报告）或 NOT ASSESSED 也 → NOT ASSESSED（构建健康从未被检查）。该前提存在的原因：零执行会让规则**空洞地满足**"无 S1/S2 开放"（零执行测试 = 零观察失败）——不加它，完全没测过的构建能读到 APPROVED；签核断言的是**已验证的质量**，没有它规则分不清"验证过是好的"与"从没看过"。（出处：Phase 6 verdict rules）
R22. **四档定义**（前提与 NOT APPROVED 检查之后）：**NOT ASSESSED — NO EVIDENCE**（一个及以上 story 无已执行证据：BLOCKED、`standard`/`full` 下测试没写、用例没走、或 smoke FAIL/UNKNOWN/NOT ASSESSED）——**非通过也非失败**，意为 QA 没发生，须点名哪些 story、为何；**APPROVED**（全 story PASS 或 PASS WITH NOTES；无开放 S1/S2）；**APPROVED WITH CONDITIONS**（开放 S3/S4，或 PASS WITH NOTES 问题已记录；无 S1/S2）；**NOT APPROVED**（任何开放 S1/S2；或 story FAIL 无 documented workaround）。Next Step 各配：NOT ASSESSED → 补缺证据（standard/full 写 Logic 测试；minimal 走 waived story 验收标准；走手工用例；跑 `/smoke-check`）后重跑 `/team-qa`——**禁止凭此 verdict 推进构建**；APPROVED → 跑 `/gate-check` 验证推进；APPROVED WITH CONDITIONS → 推进前解决条件，S3/S4 可推迟到 polish；NOT APPROVED → 修 S1/S2 后重跑 `/team-qa` 或定向手工 QA。最后问 "May I write this QA sign-off report to `production/qa/qa-signoff-[sprint]-[date].md`?"，**批准后才写**。（出处：Phase 6）

### 收尾
R23. **先验证工件**：返回契约命名了路径的，先确认在盘——**命名工件不在磁盘即失败阶段，无论回复多流畅**；点名未满足的契约让其续跑。任何智能体 BLOCKED/错误/不能完成：立即呈现、不越过其阻塞的依赖、总出部分报告。常见阻塞：输入文件缺失 → 重定向到创建它的技能；ADR 为 Proposed → 不实现，决定后 `/architecture-decision accept ADR-NNNN`；范围过大 → `/create-stories` 拆两个 story；ADR 与 story 冲突 → 呈现冲突不猜。（出处：Error Recovery Protocol）
R24. 汇报覆盖：范围 story、smoke 结果、手工 QA 结果、立案 bug（ID 与 severity）、最终四态 verdict。Verdict **COMPLETE**（QA 周期完成）/ **BLOCKED**（smoke 失败或关键 blocker 阻断周期完成，部分报告已出）。（出处：Output）
R25. **Session State Update**：最终阶段完成（签核报告写好或 BLOCKED）后，**静默**追加一行到 `production/session-state/active.md`：`<!-- QA RUN: [date] | Sprint: [sprint identifier or "ad-hoc"] | Verdict: [APPROVED/APPROVED WITH CONDITIONS/NOT APPROVED/NOT ASSESSED/BLOCKED] | Report: production/qa/qa-signoff-[sprint]-[date].md -->`。（出处：Session State Update）

## 4. 门禁与裁决
- **签核四态 + 排序**（首查 NOT APPROVED，再查证据前提，再落档）：NOT APPROVED（范围开放 S1/S2 或 FAIL 无 workaround——已知失败高于一切）> NOT ASSESSED（任一 story 无已执行证据，或 smoke UNKNOWN/NOT ASSESSED/FAIL）> APPROVED WITH CONDITIONS（仅 S3/S4 开放）> APPROVED。
- **Smoke 五态**：PASS / PASS WITH WARNINGS / NOT ASSESSED / FAIL / UNKNOWN——FAIL 在 Phase 2 即停周期；UNKNOWN 与 NOT ASSESSED 可谨慎继续但签核封顶 NOT ASSESSED。
- **Phase gate**：管线自列的 `AskUserQuestion` 决策点（无论 automation 模式）；`individual` 档 qa-lead 仅在这些点 spawn。
- **证据门禁**：Visual/Feel 与 UI 默认 BLOCKING（`testing.strict.ui`/`.visual` 显式 `false` 例外）；下游消费方 `/story-done`、`/story-readiness`、`/test-evidence-review`、gate-release 读 `production/qa/evidence/`。

## 5. 移植建议
- **可直接移植**：R3-R4（gate 字面判定、活跃集宣布）、R5-R6（返回契约、有界例外）、R8（已有 bug 先入简报、拿不准就列、无文件记 none on file）、R10-R11（复用既有报告禁止重新面谈、五态 smoke、FAIL 即停）、R13（并行 spawn 必须逐个命名输出路径）、R15-R16（只记录测试者所述、标签精确因下游解析）、R17-R18（证据是下游门禁的工件、预勾签核比没有更糟）、R19（简报传证据与规则绝不传裁决、不一致摆两个问）、R21-R22（已知失败高于未知、零执行空洞满足"无高危缺陷"、NOT ASSESSED 禁止推进构建）、R25（运行后状态行留痕）。
- **需替换概念**：sprint/story → 项目的迭代与工作单元；S1-S4 → 项目严重度分级；smoke check → 冒烟/启动自检流程；`qa.level` → 测试强度档位；GDD 验收标准 → 需求文档的验收条件；`/bug-report`、`/bug-triage`、`/story-done`、`/gate-check` → 对应缺陷与流转门禁技能；截图证据 → 该项目可留档的执行证据（日志、录屏、测试输出）。
- **改写示例**：
  - R21 → "签核裁决先查'已知失败'：范围内任何未解决的最高两级缺陷，或任一项验证失败且无记录在案的绕行方案，直接判不通过——无论还有多少项没执行；已知失败不得降级为'未评估'来埋掉。然后查证据前提：任一项没有'实际执行过的证据'就只能判未评估，绝不能判通过——零执行的验证会空洞地满足'无高危缺陷'。禁止凭未评估的裁决推进交付。"
  - R17 → "验证类工作的证据文件必须落下游门禁实际扫描的目录，签核行不得预勾。预先打勾的批准比没有批准更糟：它把一个缺失的签名变成了记录在案的签名。"

## 6. 关联文档
- 上游：`/sprint-plan`（`sprint-NNN.md` 命名）、`/smoke-check sprint`（smoke 报告来源）、`/bug-triage`（Severity/Status/System 读法）、`/bug-report`（bug 格式与编号）。
- 下游：`/story-done`、`/story-readiness`、`/test-evidence-review`、gate-release（均读 `production/qa/evidence/`）；`/gate-check`（APPROVED 后）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/coding-standards.md`、`.claude/docs/templates/test-evidence.md`、`.claude/docs/error-recovery-protocol.md`。
