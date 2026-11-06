# bug-report — 结构化 bug 报告四模式（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/bug-report/SKILL.md) ｜ 阶段：Phase 5+ ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/bug-report [description] | analyze [path-to-file] | verify [BUG-ID] | close [BUG-ID]`
- **一句话职责**：从描述生成结构化 bug 报告、分析代码找潜在 bug、验证修复是否生效、关闭已验证 bug——**只产草稿**，绝不代替用户向外部仓库提单。
- **触发前置**：Description/Analyze 模式需用户给描述或文件路径（无参数先要描述）；Verify/Close 模式需 `production/qa/bugs/BUG-*.md` 中存在对应编号的 bug 文件。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`automation`（resolve `modes.automation`，`project.local.yaml` → `project.yaml` → 默认 `collaborative`） | 每次 `AskUserQuestion` 与**每次文件写**遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录并继续；`automation_always_ask` 类别恒问） |
| 读取 | 目标文件（Analyze）；`production/qa/bugs/BUG-*.md`（Verify/Close 按编号定位；Save 前按最高编号+1 分配 ID）；引擎测试根（Godot `tests/`、Unity `Assets/Tests/`、Unreal `Source/<Module>/Private/Tests/`，见 `.claude/docs/directory-structure.md`）；`project.yaml` 的 `commands.test`（跑测试的唯一命令来源）；`production/qa/bug-triage-*.md`（Close 后查引用） | 禁止凭记忆写测试命令行 |
| 产出 | `production/qa/bugs/BUG-[NNNN].md`（新报告，Analyze 多份连续编号）；Verify 更新 Status + `**Verified by**:` 行；Close 追加 Closure Record 并把顶层 Status 改 Closed；引擎/插件/供应商缺陷 → 只在其报告 **Notes** 下加给他们 tracker 的草稿 | 写盘一律先问后写 |
| 派生智能体 | 无，主会话直接执行（注：`qa-lead` 会预载本技能作为子智能体运行——见 R14） | — |

## 3. 核心规则
R1. **只产草稿，禁止外部动作**：本技能写报告到 `production/qa/bugs/`；成因在引擎、插件或其它供应商代码时，只在报告 **Notes** 节为他们 tracker 加一份草稿并到此为止——**禁止向其仓库提单、开 issue、评论或开 PR，由用户提交**。（总则）
R2. 模式解析（Phase 1）：无关键字 → **Description Mode**（从描述生成结构化报告）；`analyze [path]` → **Analyze Mode**（读目标文件识别潜在 bug）；`verify [BUG-ID]` → **Verify Mode**（确认所报修复确实解决了 bug）；`close [BUG-ID]` → **Close Mode**（把已验证 bug 连解决记录一起关闭）。无参数 → 先向用户要一段 bug 描述再继续。（Phase 1）
R3. Description 模式流程（Phase 2A）：(1) 解析描述的关键信息——什么坏了、何时、如何复现、预期行为是什么；(2) 用 Grep/Glob 搜代码库补上下文（受影响系统、可能文件）；(3) 按模板起草报告。（Phase 2A）
R4. Analyze 模式流程（Phase 2B）：(1) 读参数指定的目标文件；(2) 识别潜在 bug——空引用、差一错误、竞态、未处理边界、资源泄漏、错误状态迁移；(3) 每个潜在 bug 按同一模板出报告，填上**可能触发场景与建议修复**。（Phase 2B）
R5. **梯子同步铁律**：Severity 与 Priority 标签必须用 `/bug-triage` 的 S 和 P 编号与名称（它从本文件解析这些字段）；`P4-Won't fix` 即 bug-triage 的 `P4 — Won't fix / Deferred`（**已接受的风险**，不是愿望清单）。**改任一梯子就必须同步改 `.claude/skills/bug-triage/SKILL.md`**。（Phase 2A）
R6. **按编号找 bug 文件**（Verify/Close 通用）：Glob `production/qa/bugs/BUG-*.md`，取**编号**匹配 `[BUG-ID]` 的文件——不管补零位数；旧的三位数带 slug 的文件也按编号找到。无一匹配 → 停止："No bug [BUG-ID] in `production/qa/bugs/`." 裁决 **BLOCKED** — no such bug。找到后读文件，提取复现步骤与预期结果。（Phase 2C）
R7. Verify 第 1 步——重跑复现步骤：用 Grep/Glob 查根因代码路径是否仍如报告所述存在；修复删掉或改动了它就注记该变化。（Phase 2C）
R8. Verify 第 2 步——跑相关测试：bug 的系统在引擎测试根有测试文件时，用 Bash 跑 `project.yaml` 的 `commands.test`（runner 允许时收窄到受影响套件）——**禁止凭记忆写 runner 命令行**（会丢引擎必需的旗标：gdUnit4 没有 `--remote-debug tcp://127.0.0.1:0` 会挂死），报告 pass/fail。`commands.test` 未设 → 没跑测试：点名未设的键，继续第 3 步。（Phase 2C）
R9. Verify 第 3 步——查回归：grep 代码库中导致该 bug 的模式有无新出现。（Phase 2C）
R10. Verify 第 4 步——人工验证：未跑相关测试（无测试覆盖该 bug——`qa.level` 豁免测试时的常态——`commands.test` 未设、运行未完成）或 bug 的 Category 为 **Visual 或 UI**（外观无自动化测试可查）时，问用户："Did you play the reproduction steps in [bug file] on a build with the fix? Which build?" 选项 `[No longer occurs]` / `[Still occurs]` / `[Not played yet]`。答案与 build 照用户原话记录；**改动的代码路径永不当作用户的答案**。（Phase 2C）
R11. Verify 三态裁决：**VERIFIED FIXED**——每一项适用检查都通过：相关测试跑了且过了，且第 4 步问过时用户对具名 build 答 `[No longer occurs]`；没跑测试时那次试玩本身就是验证——**人工验证**，照实记录为 `[user], manual, build [X]`；**单凭改动的代码路径永远不算通过**。**STILL PRESENT**——相关测试在 bug 场景上失败，或用户答 `[Still occurs]`；修复没有解决问题。**CANNOT VERIFY**——第 4 步答 `[Not played yet]`：点名缺什么或什么跑不了（无相关测试、`commands.test` 未设、运行未完成、Visual 或 UI bug），并说明试玩复现步骤即可定案——玩过后再跑一次 `/bug-report verify [BUG-ID]` 并回答其问题。（Phase 2C）
R12. Verify 写盘：问 "May I update `production/qa/bugs/[bug file]` to set Status: Verified Fixed / Still Present / Cannot Verify?"——**点名上面找到的文件，不管其补零或 slug**。写 Status 的同时在其下写 `**Verified by**:` 行——`[test file(s)] — ran and passed`，或人工验证的 `[user], manual, build [X]`。**STILL PRESENT → 重开 bug，Status 改回 Open，并建议重跑 `/hotfix [BUG-ID]`**。（Phase 2C）
R13. **子智能体无提问工具**：`qa-lead` 预载本技能运行时，子智能体没有 `AskUserQuestion`——人工验证问题以短清单结束回复并列出三个选项，**先不给裁决**：调用方去问用户，裁决等答案。（Phase 2C）
R14. Close 前置（Phase 2D）：按 R6 找到文件后，**先确认 Status 是 `Verified Fixed`** 才能关；是别的任何状态 → 停止："Bug [ID] must be Verified Fixed before it can be closed. Run `/bug-report verify [BUG-ID]` first."（Phase 2D）
R15. Close 写盘（Phase 2D）：展示闭合记录与 Status 变化，问 "May I update `production/qa/bugs/[bug file]` to mark it Closed?"——**yes 之前什么都不写**；no 就停止，bug 保持 Verified Fixed。yes → 向 bug 文件追加 Closure Record（模板见下），然后把顶层 `**Status**:` 字段更新为 `**Status**: Closed`。关完检查 `production/qa/bug-triage-*.md`——该 bug 出现在开放的分诊报告里就注记："Bug [ID] is referenced in the triage report. Run `/bug-triage` to refresh the open bug count."。（Phase 2D）
R16. ID 分配（问之前完成，Phase 3）：Glob `production/qa/bugs/BUG-*.md` 取最高编号 +1，补零到四位（一个都没有时 `BUG-0001`）；一次运行出多份报告（Analyze）从那里取**连续编号**、一报告一个——**禁止同一 ID 用两次**。（Phase 3）
R17. 保存（Phase 3）：呈现完整报告后问 "May I write this to `production/qa/bugs/BUG-[NNNN].md`?"；多份时**只问一次并点名每个文件**："May I write these to `production/qa/bugs/BUG-[NNNN].md`, `production/qa/bugs/BUG-[NNNN+1].md`, …?"。yes → 写文件（目录不存在则创建），裁决 **COMPLETE** — bug report filed；no → 就此停止，裁决 **BLOCKED** — user declined write。（Phase 3）
R18. 收尾建议按模式（Phase 4）：**提交后**（Description/Analyze）→ 跑 `/bug-triage` 与既有开放 bug 一起排优先级；**S1 或 S2 → 跑 `/hotfix [BUG-ID]` 走紧急修复流程**。**修复进库后**（开发者确认）→ 跑 `/bug-report verify [BUG-ID]`——**禁止未经验证关 bug：验证不过的修复仍然是 Open**。**CANNOT VERIFY 后** → 在带修复的 build 上试玩复现步骤，再跑 verify 并回答其问题。**VERIFIED FIXED 后** → 跑 `/bug-report close [BUG-ID]` 写闭合记录并更新状态；跑 `/bug-triage` 刷新开放计数并把它移出活跃清单。（Phase 4）

R3/R4 对应的报告模板（保留原文格式约定，Phase 2A）：

```markdown
# Bug Report

## Summary
**Title**: [Concise, descriptive title]
**ID**: BUG-[NNNN]
**Severity**: [S1-Critical / S2-High / S3-Medium / S4-Low]
**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]
**Status**: Open
**Reported**: [Date]
**Reporter**: [用户给出的名字，否则 —；禁止取会话中的邮箱或账号 ID]

## Classification
- **Category**: [Gameplay / UI / Audio / Visual / Performance / Crash / Network]
- **System**: [受影响系统——跨系统时填代码必须改的那个，其余进 Related systems]
- **Frequency**: [Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%)]
- **Regression**: [Yes/No/Unknown -- was this working before?]

## Environment
- **Build**: [Version or commit hash] · **Platform**: [OS, hardware if relevant]
- **Scene/Level**: [Where in the game] · **Game State**: [inventory, quest progress, etc.]

## Reproduction Steps
**Preconditions**: [Required state before starting]
1. [Exact step 1] 2. [Exact step 2] 3. [Exact step 3]
**Expected Result**: [What should happen]
**Actual Result**: [What actually happens]

## Technical Context
- **Likely affected files**: [基于代码库搜索的文件列表]
- **Related systems**: [其它可能牵涉的系统]
- **Possible root cause**: [可从描述识别时]

## Evidence
- **Logs**: [ Relevant log output if available] · **Visual**: [Description of visual evidence]

## Related Issues
- [Links to related bugs or design documents]

## Notes
[Any additional context or observations]
```

R15 对应的 Closure Record 模板（追加到 bug 文件末尾，Phase 2D）：

```markdown
## Closure Record
**Closed**: [date]
**Resolution**: Fixed — [one-line description of what was changed]
**Fix commit / PR**: [if known]
**Verified by**: [verify 记录的 **Verified by**: 行——跑过且通过的测试，或 "[user], manual, build [X]"]
**Closed by**: [user]
**Regression test**: [test file path, or "Manual verification" when verify recorded a manual play]
**Status**: Closed
```

## 4. 门禁与裁决
- 本技能无审查门禁、无派生智能体。内含裁决：
- **Verify 三态**：VERIFIED FIXED / STILL PRESENT / CANNOT VERIFY——人工试玩才算验证、改动代码路径永不折算为通过。
- **Close 前置**：必须 `Verified Fixed` 才能关。
- **保存裁决**：COMPLETE（已写）/ BLOCKED（用户拒写，或无此 bug）。

## 5. 移植建议
- **可直接移植**：R1（供应商缺陷只产草稿、永不代提单）、R5（两技能共用枚举必须同步改）、R6（按编号定位、容忍补零差异）、R7-R11（四步验证、测试命令只从配置读、人工验证记录格式、三态裁决）、R12-R15（Verified by 行、重开规则、Close 前置、yes 前不写）、R13（子智能体无提问工具时以清单结束且不给裁决）、R16（最高编号+1、多报告连续编号）、R18（验证不过的修复仍是 Open）。
- **需替换概念**：Gameplay/Scene/Level → 业务模块/功能区域；引擎测试根 → 项目测试目录；`commands.test` → 测试命令配置键；`/bug-triage`、`/hotfix`、`/team-qa`、`/smoke-check` → 分诊/紧急修复/批量测试/冒烟复检流程；gdUnit4 旗标例 → 各自工具链的必需参数。
- **改写示例**：
  - "缺陷验证三态取首项命中：VERIFIED FIXED（相关测试通过，或用户在具名构建上确认不再复现——人工验证照实记录为‘[user], manual, build [X]’）> STILL PRESENT（测试失败或用户确认仍复现）> CANNOT VERIFY（尚无人试玩，点名缺项，试玩即可定案）。"
  - "缺陷必须先经验证为已修复才能关闭；闭合记录须引用验证时留下的验证者行，不得凭代码路径变更直接判定通过。"

## 6. 关联文档
- 上游：`/playtest-report`（试玩发现的 bug 转入本技能）、`/team-qa`（批量产 bug）。
- 下游：`/bug-triage`（排优先级、刷新开放计数）、`/hotfix [BUG-ID]`（S1/S2 紧急修复、STILL PRESENT 重开后的修复）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/directory-structure.md`、`.claude/skills/bug-triage/SKILL.md`（梯子同步）。
