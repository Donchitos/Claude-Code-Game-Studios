# story-done — 8 阶段完成审查（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/story-done/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/story-done [story-file-path] [--review full|lean|solo]`
- **一句话职责**：关闭一张已完成的故事卡：逐条验收标准对照证据核验，把与 GDD、ADR 及故事自身范围的偏差作为事实报告，**只有用户明确同意才标记 Complete**。
- **触发前置**：故事已实现（`/dev-story` 之后的环节）；`production/epics/` 下存在故事文件（一张都没有即停止并提示先 `/create-stories`）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, review_gate, automation, automation_always_ask, workflow, qa.level, gate_level, system_overrides`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | `workflow`+`system_overrides` 定档；**`qa.level` 独立于 workflow/rigor**（`workflow: minimal` + `qa.level: standard` 仍要求 Logic 卡的单测）；`gate_level` 定各类型 BLOCKING/ADVISORY；`review_gate` 定双门禁 |
| 读取 | 故事文件整读（标准原文、Test Evidence 路径、`## Files`、Out of Scope）；`story-facts.sh <path>`（状态/类型/层级/TR-ID/ADR/标准数/测试证据状态/依赖）；`story-facts.sh --all`（找进行中卡）；`production/session-state/active.md` 检查点；`tr-registry.yaml`（full 档现行需求文本）；GDD 的 Acceptance Criteria 与 Detailed Design 章节（exit 3 → 试 `Detailed Rules`）；`adr-status.sh` + ADR 的 Decision/Consequences（full 全部、standard 仅关键 ADR）；control manifest 的 `Manifest Version` 行；`review-receipts.sh check`（证据时效）；`git status --porcelain`（范围比对）；`story-status.sh`（收尾找下一张） | 全部按章节读，禁止整读 |
| 产出 | 用户 yes 后：故事卡 `Status`/`Last Updated`/`## Completion Notes`；`production/sprint-status.yaml` 条目（`status: done`、`completed`、顶层 `updated`）；`docs/tech-debt-register.md`（仅用户选该选项时）；**检查点每次运行都写**（无论裁决） | 建议的 commit 命令只打印不执行 |
| 派生智能体 | `skill-gates=run` 时派两个门禁智能体：QL-TEST-COVERAGE 与 LP-CODE-REVIEW（读 `references/review-gates.md` + `.claude/docs/director-gates.md`）；skip 时不加载 | lean 模式改为口头询问 |

## 3. 核心规则
R1. 定位故事：入参去掉 `--review` 对即故事路径；无输入时依次：检查点的 **Current task** 行点名故事 → `story-facts.sh --all` 中 `IN_REVIEW`/`IN_PROGRESS` 行（多张则问"关哪张？"每卡一选项）→ 问路径；`production/epics/` 无任何故事文件则停止（提示 `/create-stories`，`standard`/`full` 无史诗先 `/create-epics`）。（Phase 1）
R2. 档位与证据要求：档位取故事系统（`GDD:` 路径文件名主干，无 GDD 路径才用 TR-ID 的 `[system]`）的 `system_overrides` 行，无则项目 `workflow` 值。证据要求取 `qa.level` 行（**绝不取自 `workflow` 或 `rigor`**），按表：Logic/Integration 测试——`minimal` 豁免、`standard`/`full` 必需；Config/Data smoke 报告——`minimal` 豁免、`standard` 必需且默认 advisory、`full` 必需且默认 **blocking**；Visual/Feel、UI 留存截图——**三级全必需**（观感永不豁免）；未测标准的升级——`minimal` 永不升级、`standard` 过半才阻断、`full` 任一即阻断。`full` 档下 Config/Data 的默认 advisory 变 blocking，但显式 `testing.strict.config: false` 仍使其 advisory。（Phase 1）
R3. 对照材料按档加载（全部按章节读）：`full`——每个 TR-ID 的**现行**需求文本（registry 中 `id: <TR-ID>\s*$` 匹配行及其下条目文本；锚定防 `TR-combat-001` 误配 `TR-combat-0010`，`\s*` 兼容 Windows 行尾；**禁止用故事卡里引的文本**）、GDD 的 Acceptance Criteria 与 Detailed Design、每个 ADR 的状态 + Decision/Consequences；`standard`——同样 GDD 章节，ADR 章节仅关键 ADR（`adr-status.sh` layer 列为 Foundation 或无 layer）；`minimal`——无，故事卡的标准即规格。每档都要在 control manifest 存在时记下 `Manifest Version` 行。（Phase 2）
R4. 逐条核验标准，四种方式：**看**（Criterion 点名的文件存在；点名的测试文件存在——报告 "test file present"，**绝不报告 "test passes"**：此处不运行任何东西；游戏代码里本应进数据文件的数字字面量；代码根里本应进本地化文件的面向玩家字符串——根按 `code-root-resolution.md` 解析，解析不出报 `NOT ASSESSED — code root unresolved`，绝不报零命中）；**问**（行为、手感、性能类标准，禁止靠读代码判过——代码说的是"应该发生什么"不是"构建做了什么"；每次问至多四条："Does [criterion]?" 选项 Yes — passes / No — fails / Not tested yet，`Not tested yet` 即 UNTESTED 且把裁决压到至多 NOT ASSESSED 直到有人查过）；**屏上看**（可见类标准由 `production/qa/evidence/[story-slug]/`（故事文件名去 `.md`）下**你打开并亲眼见过**的留存图像覆盖；禁止描述没打开过的图像；检查点的 `Run result: OBSERVED` 是 `/dev-story` 的描述，只能照此引用）；**需完整试玩**（`DEFERRED — requires playtest session`，不阻断）。（Phase 3）
R5. 建立可追溯表（| Criterion | Covered by | Status |，COVERED/UNTESTED），把每条标准映射到覆盖物（测试根下的测试、"Yes — passes"、留存图像）；未测标准按 Phase 1 表升级：线上为阻断；线下为 advisory，在 Completion Notes 列 "Untested criteria: [AC-N list]"。（Phase 3）
R6. 测试证据按类型核对（在 Phase 1 的 gate level 下；`qa.level` 豁免的检查要跳过并声明 `Test evidence: waived at qa.level minimal`）：Logic——故事 Test Evidence 节的精确路径，否则 `tests/unit/[system]/` 下任意处；Integration——`tests/integration/[system]/` 下，否则 `production/qa/playtests/` 中点名本卡的试玩记录（`/playtest-report` 产）；UI——每个触及屏幕的留存截图（`production/qa/evidence/` 下），无需证据文档或 sign-off；Visual/Feel——截图 **加** sign-off（`production/qa/evidence/[story-slug]-evidence.md`，每行 `[x] Approved`，一人可签全部角色）；Config/Data——`production/qa/smoke-*.md` 报告，没有则提示跑 `/smoke-check`；无 Type——advisory（"Story Type not declared. Add `Type:` to the story header."）。缺失项按 gate level 记缺口：BLOCKING 挡下 COMPLETE，ADVISORY 进注记；点名缺什么、去哪补。**旁边没有图像的证据文档不是证据**：被描述过的检查只是断言。（Phase 4）
R7. 证据时效：留存图像须跑 `review-receipts.sh check production/qa/evidence/[story-slug]/stamp.txt`；每个 `CHANGED:`/`GONE:` 文件报"[file] changed after the evidence was captured — re-capture it."；`RECEIPT: NONE` 报 "no stamp — whether the evidence is older than the code cannot be told"。这些行只报告，**永不改变裁决**。（Phase 4）
R8. Run result（其余所有类型）：取 `/dev-story` 检查点（仅当其 **Current task** 点名本卡）或故事 Completion Notes 的 `Run result:` 行。`OBSERVED` 带路径 → 记下；`N/A — <原因>` → 只接受说明了"为何无可观察"的原因（"这是 Logic 故事"不算）；`NOT VERIFIED` 出现在标准点名屏幕内容的卡上 → 按 gate level 记缺口；没有该行 → advisory（"confirm the build was launched and looked at"）。用户对屏幕类标准答 "Yes — passes" 而无留存图像是断言不是观察 → 按 gate level 记缺口。（Phase 4）
R9. 偏差与范围检查按档（`minimal` 跳过第 1、3 项）：(1) GDD 规则（`full`；`standard` 限必需章节）——在改动文件中搜现行 GDD 文本与 TR 需求使用的名字；(2) Manifest——故事 `Manifest Version` 落后于 manifest 的为 ADVISORY（"written against manifest v[story]; current is v[current] — run `/story-readiness` to check"），无 manifest 跳过，故事里的 `Manifest-Note:` 行原样带进偏差；(3) ADR 约束（`full`；`standard` 限关键 ADR）——搜 ADR Decision 或 manifest 禁止的模式；(4) 改动文件中的硬编码值；(5) 范围——故事 `## Files` 清单对照 `git status --porcelain` 的代码与测试改动：改了而清单没点名 → **OUT OF SCOPE**；故事无 `## Files` 节 → 检查点 Current task 点名本卡时用其 **Files in progress**，否则报 `Scope: NOT ASSESSED — the story lists no files`；工作树干净 → 报 `Scope: not checked — no uncommitted changes to compare`。每条偏差标 **BLOCKING**（与 GDD 或 ADR 矛盾）/ **ADVISORY**（漂移但行为相同，用户裁决）/ **OUT OF SCOPE**（仅供知悉），一律陈述为事实，由用户判断。（Phase 5）
R10. 双门禁：`skill-gates=skip` → 不派智能体，注明 `QL-TEST-COVERAGE skipped — [Solo | Lean] mode` 与 `LP-CODE-REVIEW skipped — [Solo | Lean] mode`；**lean 模式必须问**"Did you run `/code-review` on the implemented files?"（选项：Yes — it passed or was approved with suggestions / No — skipping review for this story / No — I'll run it before the sprint close-out），答案决定 Reviewed by。`skill-gates=run` → 读 `references/review-gates.md` 与 `.claude/docs/director-gates.md`，立即运行两个门禁；skip 时不加载。（Phase 6）
R11. **Reviewed by 永不为空**：LP-CODE-REVIEW 跑了 → `lead-programmer`；lean 的 Yes → ``/code-review (you said you ran it; not verified here)``；solo 模式、两个 No、以及尚无实现文件时 → `self, no independent review`。（Phase 6）
R12. 报告按标准块输出（Story Done 标题；Story/Type/Date；Acceptance Criteria `[x]/[ ]/[?]` 勾选与 X/Y；Traceability 表；Test Evidence 的 Required/Found；Deviations；Review 的 Reviewed by；Verdict）。（Phase 7）
R12 对应的报告块模板（保留原文格式约定）：

```markdown
## Story Done: [title]
**Story**: [path] · **Type**: [type] · **Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [criterion] — [how verified]
- [ ] [criterion] — FAILS: [reason]
- [?] [criterion] — DEFERRED: requires playtest

### Traceability
[the Phase 3 table]

### Test Evidence
**Required**: [what the type needs at this qa.level, or "waived at qa.level minimal"]
**Found**: [YES — path | NO — BLOCKING | NO — ADVISORY]

### Deviations
[NONE, or each: BLOCKING / ADVISORY / OUT OF SCOPE — description — reference]

### Review
**Reviewed by**: [value]

### Verdict: [COMPLETE | COMPLETE WITH NOTES | NOT ASSESSED | BLOCKED]
```

R15 对应的 Completion Notes 模板（文件编辑追加，禁止 shell 写）：

```markdown
## Completion Notes
**Completed**: [date]
**Criteria**: [X/Y passing] ([deferred items])
**Deviations**: [None, or the advisory ones]
**Test Evidence**: [path, or "waived at qa.level minimal", or "none required"]
**Reviewed by**: [value]
```

R13. **裁决四态，首个命中即胜**：**BLOCKED**（某标准 FAILS，或存在 BLOCKING 缺口/偏差）→ **NOT ASSESSED**（标准无法评估：未命名可观察结果、用户答 "Not tested yet"、门禁返回 NOT ASSESSED 且输入未补、证据存在但读不了、或偏差所对照的 GDD/ADR 缺失；逐个点名及"什么能定案"；**它排在两个通过之上、永不掩盖失败**）→ **COMPLETE WITH NOTES**（每条标准通过或 DEFERRED，advisory 项已列；信息行不算 advisory 项——证据戳行、缺失的冲刺文件、run result 永远不把 COMPLETE 变成 COMPLETE WITH NOTES）→ **COMPLETE**（全部通过、无 advisory）。（Phase 7）
R14. 写任何东西前必须问："How do you want to proceed?" 选项：Close the story — mark it Complete and log notes (Recommended) / Close and log the advisory deviations as tech debt / Don't close yet — I'll fix things first / Close anyway, accepting the deviations。BLOCKED 或 NOT ASSESSED 时推荐 "Don't close yet" 并列出必须改变的事项；关闭这样的故事属于 `scope_changes` 决策——`automation_always_ask` 行列有它时，**任何自动化模式都必须问**（哪怕是被用户自己的请求带到这里）。只在明确选择关闭时写入。（Phase 7）
R15. 关闭动作（选了关闭后）：(1) `set-field <story> Status Complete`，再 `set-field "Last Updated" <YYYY-MM-DD> --after Status`；(2) 用文件编辑（**禁止 shell 命令**，shell 写绕过项目写检查）在故事末尾加 `## Completion Notes`（Completed/Criteria/Deviations/Test Evidence/Reviewed by）；(3) 选 "Close and log as tech debt" 时读 `references/tech-debt-row.md`，每条 advisory 偏差加一行；(4) `sprint-status.yaml` 存在时：本卡条目 `status: done` + `completed: [日期]` + 顶层 `updated` 今日（关闭的答复已覆盖此写）；(5) 打印建议 commit：`git add [改动的代码与测试文件] [故事路径]` 与 `git commit -m "feat: [故事标题] ([TR-ID])"`。（Phase 7）
R16. 选 "Don't close yet"：不改任何故事文件；列出用户标记的事项；**禁止自己修失败的标准**——报告并问怎么办。（Phase 7）
R17. 下一张故事（`production/sprints/` 无冲刺计划时，`workflow: minimal` 恒为无）：关闭后跑 `story-status.sh`（让新状态进清单；按其路由序打印未完成卡，**禁止重排**）：首个 `IN_REVIEW` 行为下一张，否则首个 In Progress，否则首个 Ready/Not Started（`TODO`）。按 "### Next Up" 块输出（`/story-done [path]` 关闭 In Review 卡，否则 `/dev-story [path]` 实现）。`workflow: minimal` 时**完全不打印** `/story-readiness` 行（连选项都不给——不在该路径上）；`standard`/`full` 无冲刺计划时加 "Run `/story-readiness [path]` first."。只剩 `COMPLETE N of N` → 全部建成，给三条出路（玩构建并记下手感问题；`/create-stories` 从 brief 加卡；`/settings` 调高 `modes.rigor`）。只剩 `BLOCKED`/`OTHER`/`NO_STATUS` 行 → 没有 Next Up 且 build order **未完成**（逐卡点名 blocker、`Draft` 或无状态）。该分支**禁止打印 Sprint Close-Out Sequence**（没有冲刺）。有冲刺计划时读 `references/sprint-next.md`。（Phase 8）
R18. 检查点每种裁决都写（关没关都写）：管道给 `session-state.sh checkpoint`（替换旧块）：Updated/Branch/Current task（`/story-done — [故事路径]: [裁决], [closed | left open]`）/Next step/Blocked on/Files in progress: none/Open questions（tech debt logged: N items, or none）。（Phase 8）
R19. 运行最后一条回复以收尾块结束（重复展示过也要再打）：`Verdict: [...] — [story path]` / `Story: [closed — Status: Complete | left open — Status: [状态]]` / `Review: [Reviewed by 值；门禁跳过注记]` / `Next step: [/dev-story [path] | /story-done [path] | 修复动作 | play the build]`。（Phase 8）
R20. 提问规则：有提问工具就用工具；没有则编号列选项并结束回合等待；被跳过/关闭的提问不算答案，纯文本再问。（全局）

R18/R19 对应的检查点块与收尾块模板（保留原文格式约定）：

```
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /story-done — [story path]: [verdict], [closed | left open]
**Next step:** [the Next Up command, or the fix the verdict named]
**Blocked on:** [nothing, or what blocked the verdict]
**Files in progress:** none
**Open questions:** [tech debt logged: N items, or none]
```

```
Verdict: [COMPLETE | COMPLETE WITH NOTES | NOT ASSESSED | BLOCKED] — [story path]
Story: [closed — Status: Complete | left open — Status: [status]]
Review: [Reviewed by value; the gates' skip notes]
Next step: [/dev-story [path] | /story-done [path] | the fix | play the build]
```

## 4. 门禁与裁决
- **门禁 ID**：QL-TEST-COVERAGE（测试覆盖）与 LP-CODE-REVIEW（代码评审），双双受 `review_gate` 的 `skill-gates` 控制：`run` → 派智能体（依据 `references/review-gates.md` + `.claude/docs/director-gates.md`）；`skip` → 注明跳过，lean 模式以口头询问替代 LP-CODE-REVIEW。
- **主裁决**（Phase 7，首个命中）：BLOCKED > NOT ASSESSED > COMPLETE WITH NOTES > COMPLETE。
- **取最严**：NOT ASSESSED 排在两个通过之上、永不掩盖失败；信息行（证据戳、缺失冲刺文件、run result）不参与升级；证据断言（描述而无图像）按 gate level 记缺口。

## 5. 移植建议
- **可直接移植**：R4-R5（四类核验方式、"test file present"≠"test passes"、断言≠观察）、R6-R8（按类型的证据矩阵、证据时效戳只报告不改裁决、Run result 三态采信规则）、R9（三级偏差 BLOCKING/ADVISORY/OUT OF SCOPE + 范围对照 git status）、R11（Reviewed by 永不为空）、R13-R14（四态裁决排序、关闭前必问、scope_changes 类决策全模式必问）、R15-R16（关闭写序、拒绝关闭不改文件不自修）、R17-R19（Next Up 顺序、检查点、收尾块）。
- **需替换概念**：GDD/TR registry → 需求与追踪表；ADR → 技术决策记录；manifest → 变更控制清单；Visual/Feel sign-off → 需人工签认的交付物；`/code-review`、`/smoke-check`、`/playtest-report`、`/prototype` → 对应评审/冒烟/试用记录/原型流程；tech-debt register → 技术债登记表；`lead-programmer` → 评审负责人。
- **改写示例**：
  - "关闭任务前逐条验收标准必须落到证据：自动化测试、留存截图、或用户当面确认三者之一；用户口头确认而要求截图的交付物缺失时按门禁档位记缺口。"
  - "裁决四态按序取首个命中：BLOCKED（标准失败或阻断性缺口）> NOT ASSESSED（无法评估，点名定案条件，永不折算为通过）> COMPLETE WITH NOTES（全过但有 advisory）> COMPLETE；标记完成必须经用户明确选择关闭。"

## 6. 关联文档
- 上游：`/dev-story`（产实现、Run result 与检查点）、`/create-stories`（产故事卡）。
- 下游：`/story-readiness`（manifest 落后时复查）、`/code-review`（lean 口头确认对象）、`/smoke-check`、`/playtest-report`、`/sprint-plan`（Sprint Close-Out）、`/create-stories`（加卡）、`/settings`。
- 引用：`.claude/docs/coding-standards.md`（证据行）、`.claude/docs/code-root-resolution.md`、`.claude/docs/director-gates.md`、`references/review-gates.md`、`references/tech-debt-row.md`、`references/sprint-next.md`、`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`。
