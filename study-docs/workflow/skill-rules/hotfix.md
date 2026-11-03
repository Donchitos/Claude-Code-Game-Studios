# hotfix — 紧急修复工作流（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/hotfix/SKILL.md) ｜ 阶段：Phase 7+ ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/hotfix [bug-id or description]`（disable-model-invocation：**仅显式调用**，禁止基于上下文匹配自动触发）
- **一句话职责**：绕过常规冲刺的紧急修复流程——严重度确认、hotfix 记录、从 release 基线切分支、批准前不动码、三方并行签核、QA 重入门禁、部署硬门禁、回植验证与事后复盘，全程留审计轨迹。
- **触发前置**：用户显式 `/hotfix`；无 resolve_config（本技能不读配置文件——部署门禁对 `modes.automation` 一视同仁）；git 仓库存在性运行时探测。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | bug 描述或 ID；`production/qa/bugs/` 原始 bug 文件（按编号找，同 `/bug-report verify`）；`project.yaml` 的 `commands.test`；`git rev-parse --is-inside-work-tree`、`git tag --list`、`git branch --list 'release/*'` | 严重度/复现/测试命令/基线 |
| 读取 | 用 Grep 找出**所有触碰改动文件的系统**（callers） | 给 qa-lead 定 QA 范围 |
| 产出 | `production/hotfixes/hotfix-[date]-[short-name].md`（Problem / Root Cause / Fix / Testing / Approvals / Rollback Plan，`Status: IN PROGRESS`，先问后写）；hotfix 分支 `hotfix/[short-name]`；补丁 tag（下一补丁版本，如 `v1.2.0` → `v1.2.1`）；bug 文件 Fix Record + `Status: Fixed — Pending Verification`（先问）；部署摘要 | 回滚计划**部署前**必须已记录 |
| 派生智能体 | `lead-programmer`（修复正确性与副作用评审）、`qa-tester`（受影响系统定向回归）、`producer`（部署时机与沟通批准）、`qa-lead`（QA 重入范围裁决）；复杂超 4 小时升级 `technical-director` | 签核三者并行派发 |

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1-3 — 严重度、记录与分支
R1. 按 `/bug-triage` 的量表评严重度：**S1 (Critical)**——崩溃、数据丢失或完整功能失效，游戏无法继续（**安全问题按该影响评级**）；**S2 (High)**——主要功能坏但游戏仍可玩；**S3 或更低**——带 workaround 的功能降级或外观问题，走普通 bug 修复流程。（Phase 1）
R2. `AskUserQuestion` 确认："I've assessed this as **[severity]** — [rationale]. Confirm severity to proceed:"，选项 `[A] S1` / `[B] S2` / `[C] S3 or lower — redirect`。选 C → 停，Verdict: **REDIRECTED**——S3 及以下用普通 bug 修复流程。（Phase 1）
R3. 先起草 hotfix 记录（模板：`## Hotfix: [Short Description]`、Date、Severity、Reporter、`Status: IN PROGRESS`；Problem；Root Cause（调查中填）；Fix（实现中填）；Testing；**Approvals** 三勾——Fix reviewed by lead-programmer / Regression test passed (qa-tester) / Release approved (producer)；Rollback Plan）。问 "May I write this to `production/hotfixes/hotfix-[date]-[short-name].md`?"——yes 才写（需要时建目录）。（Phase 2）
R4. git 检查：`git rev-parse --is-inside-work-tree` 失败或空 → 记 "Not a git repository — create the branch manually." 并跳过建分支。**`[base-ref]` 是 bug 所在的那个 release**：release 是 main（主干）上的 tag，所以是该 release 的 tag（`git tag --list`，最新通常是线上构建）——或为稳定该 release 而切的 `release/*` 分支（`git branch --list 'release/*'`）。**绝不用 main 的 head**——它可能带着没发布的工作。（Phase 3）
R5. 建分支前 `AskUserQuestion`："Ready to create hotfix branch 'hotfix/[short-name]' from [base-ref]?"，选项 `[A] Yes — create branch` / `[B] Use a different base ref` / `[C] Skip — I'll create the branch myself`。只有 A 才跑 `git checkout -b hotfix/[short-name] [base-ref]`；B 先问出 ref 再跑；C 跳过建分支直接 Phase 4。（Phase 3）

### Phase 4/4b — 调查与实现
R6. 找根因；起草**最小修复**：改哪些文件、改动做什么、**刻意不动什么**。**禁止顺手重构、清理或加特性**。展示根因与方案后问 "May I implement this fix?"——**批准前禁止改任何代码**：紧急流程的审计轨迹靠改动**存在之前**获批来挣，不是之后。（Phase 4）
R7. 只在批准后实现已批准的最小改动。用 `project.yaml` 的 `commands.test`（runner 允许时收窄到受影响套件）跑受影响系统定向测试——**禁止凭记忆写 runner 命令行**（会丢引擎需要的 flags：gdUnit4 没有 `--remote-debug tcp://127.0.0.1:0` 会挂起）。检查相邻系统回归。`commands.test` 未设或该系统无测试 → 说明并在记录 Testing 节写 `Tests: NOT RUN — [reason]`，由 Phase 5b 的 QA 门禁承担验证。更新记录的根因、修复细节与测试结果。（Phase 4b）

### Phase 5/5b — 签核与 QA 重入门禁
R8. 用 Agent 工具**并行**请求三方签核：`lead-programmer`（正确性与副作用）、`qa-tester`（受影响系统定向回归）、`producer`（部署时机与沟通计划）。**三者全部 APPROVE 才继续**；任一返回 CONCERNS 或 REJECT → 不部署，先暴露并解决问题。（Phase 5）
R9. 签核后派 `qa-lead` 裁定 QA 范围，给它：hotfix 描述与受影响系统、Phase 5 回归结果、Grep 得到的全部触碰改动文件的系统清单。问：**"Is a full smoke check sufficient, or does this fix require a targeted team-qa pass?"**（Phase 5b）
R10. 按裁决执行：**Smoke check sufficient** → 对 hotfix 构建跑 `/smoke-check`——PASS 或 PASS WITH WARNINGS → 进 Phase 6（警告写进记录）；**FAIL → 不部署**：带着失败检查回 Phase 4，在那里拿到修订修复的批准、实现（Phase 4b），**再重跑 Phase 5 的全部签核（含 qa-tester 的回归）和本 QA 步骤**——打破冒烟套件的 hotfix 是第二次事故不是修复。**Targeted QA pass required** → 跑 `/team-qa feature: [affected-system]` 只限改动系统；APPROVED 或 APPROVED WITH CONDITIONS → Phase 6；NOT APPROVED 或 BLOCKED → 按 smoke FAIL 处理。**Full QA required**——触及核心系统的 S1 修复可能要完整 `/team-qa sprint`：延迟部署但防止坏补丁。（Phase 5b）
R11. **QA 步骤返回 `NOT ASSESSED` = 门禁没跑——按未满足处理，不按已满足**。`/smoke-check` 在套件从未执行时返回它，`/team-qa` 在周期没有已执行证据时返回它。**NOT ASSESSED 不是通过**——时间压力下宽松解读最显得合理，所以白纸黑字写明。要么补齐结果（verdict 点名缺什么才能跑），要么把决定**显式**交给 producer——作为"部署一个未验证 hotfix"的决策而非悄悄清过的门禁——并把该决策（谁做的、为什么）记进记录 Testing 节。禁止跳过这道门禁：打破别的东西的 hotfix 比原 bug 更糟。（Phase 5b）

### Phase 6 — 部署（硬门禁）
R12. **部署无条件要求显式批准**——合并 hotfix 与打补丁 tag 是本技能唯一的不可逆动作，所以虽然建分支（可逆）已门控、它还要门控。任何 merge/tag/deploy 前 `AskUserQuestion`："Hotfix validated and approved. Merge to [targets], tag [patch tag] and deploy?"（targets = `main` + 该 release 的 `release/*` 分支——仅当存在）。选项 `[A] Yes — merge and deploy` / `[B] Merge to main only — hold the release` / `[C] Stop here`。**该门控对 `modes.automation` 一视同仁，含 `autonomous`**——紧急流程恰是未审不可逆步骤最可能出现、最不可恢复的地方。（Phase 6）
R13. 执行：A → hotfix 分支合并到 `main`，release 有 `release/*` 分支时也合并过去；在**修复后的构建**上打补丁 tag（下一补丁版本，如 `v1.2.0` → `v1.2.1`）——有 `release/*` 分支取其 head，否则取 hotfix 分支 head——**部署那个 tag，不是 main 的 head**。B → 只合并 `main`——不合 release 分支、不打 tag、不部署。C → 停——不 merge、不 tag、不部署、**也不更新 bug 文件**；记录 Status 保持 IN PROGRESS，并说明。（Phase 6）
R14. **不验证就没有 backport**——frontmatter 宣称 "backport verified"，但合并后必须确认修复存在于 `main`（主干），release 有 `release/*` 分支时也在其上，并**陈述结果**。未回植的 hotfix 意味着 bug 在下一个从 main 打 tag 的版本里回归——这是最常见的 hotfix 回归。（Phase 6）
R15. 存在原始 bug 文件时（按编号在 `production/qa/bugs/` 找）**先问**："May I update `production/qa/bugs/[bug file]` with the fix record below and set its Status to `Fixed — Pending Verification`?" 写入 Fix Record（`**Fixed in**: hotfix/[branch-name] — [commit hash or description]`、Fixed date、`**Status**: Fixed — Pending Verification`），并把 bug 文件头部的 Status 同步设置。（Phase 6）
R16. 输出部署摘要，**标题随 Phase 6 答复**：A → `Hotfix Deployed: [short-name]`；B → `Hotfix Merged to main — release held: [short-name]`（且收尾行省略 Tag——没打过）。字段：Severity / Root cause / Fix（各一行）；QA gate（`Smoke check PASS` / `Team-QA APPROVED` / `NOT ASSESSED — [为什么，以及是谁显式决定照样部署]`）；Approvals（`lead-programmer ✓ / qa-tester ✓ / producer ✓`）；Backport（`verified present on main`（及 `release/*`）——或 `NOT VERIFIED` 及没查什么）；Rollback plan（Phase 2 记录）；`Merge to: [targets] · Tag: [patch tag]`；`Next: /bug-report verify [BUG-ID] after deploy to confirm resolution`。（Phase 6）
R17. **Rules**：hotfix 必须是修问题的**最小**改动——不清理、不重构；每个 hotfix **部署前**必须有记录的回滚计划；分支从它所修的 release 起点（其 tag，或其 `release/*` 分支——存在时），合并到 `main`（主干），只在存在时也合并 `release/*`；补丁 release 打 tag；全部 hotfix 要求 **48 小时内**事后复盘；修复复杂到超过 **4 小时** → 升级 `technical-director`。（Rules）

### Phase 7 — 部署后验证
R18. 部署后跑 `/bug-report verify [BUG-ID]` 确认修复在部署构建中生效：**VERIFIED FIXED** → `/bug-report close [BUG-ID]` 正式关闭；**STILL PRESENT** → hotfix 失败——立即重开、评估回滚、升级；**CANNOT VERIFY** → 修复未确认——**不关 bug**：在部署构建里跑复现步骤，再跑 verify 并回答其人工试玩问题定案。（Phase 7）
R19. **48 小时内排事后复盘**。`/retrospective` 复盘的是冲刺或里程碑不是事故：用 `.claude/docs/templates/incident-response.md` 记录复盘，把教训带到下一次 `/retrospective`。结尾 `AskUserQuestion`："Hotfix complete. What's the next step?"，选项 A 跑 `/smoke-check` 验证 / B 跑 `/patch-notes` 记录本次 hotfix / C 停。（Phase 7）

## 4. 门禁与裁决
- **Phase 5 三方签核**：lead-programmer / qa-tester / producer 全部 **APPROVE** 才继续；任一 **CONCERNS** 或 **REJECT** → 不部署。
- **Phase 5b QA 重入门禁**：smoke（PASS / PASS WITH WARNINGS / FAIL）/ team-qa（APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / BLOCKED）/ 全量 sprint；**NOT ASSESSED 按未满足处理**，要么补齐要么显式升级为 producer 的"部署未验证修复"决策并留痕。
- **Phase 6 部署硬门禁**：无条件 AskUserQuestion，**含 autonomous 模式**；[C] 停止时连 bug 文件也不更新。
- **Verdict 词**：`REDIRECTED`（S3 及以下）；QA verdict：PASS / PASS WITH WARNINGS / FAIL / NOT ASSESSED / APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / BLOCKED。

## 5. 移植建议
- **可直接移植**：R6-R7（批准前不动码、最小改动、禁止凭记忆写测试命令行）、R8（三方并行签核、全 APPROVE 才放行）、R11（NOT ASSESSED = 门禁没跑；要么补齐要么显式升级决策并留痕）、R12-R14（不可逆动作无条件门禁且对 autonomous 生效、从 release 基线而非主干 head 切分支、回植必须亲自验证）、R17（最小改动/回滚先行/48h 复盘/超时升级）。
- **需替换概念**：`release/*` 分支与 tag → 产品的发布基线机制；lead-programmer / qa-tester / producer / qa-lead / technical-director → 评审负责人 / 测试 / 发布决策者 / 质量负责人 / 技术总监；`/smoke-check`、`/team-qa`、`/bug-report verify|close`、`/retrospective` → 冒烟 / 回归 / 缺陷验证与关闭 / 复盘流程；gdUnit4 flags 示例 → 项目测试 runner 的必要参数。
- **改写示例**：
  - R12 → "紧急变更流程中唯一的不可逆动作（合并发布分支 + 打版本 tag + 部署）必须经用户显式批准，该要求不受自动化模式影响——自动化越彻底、紧急场景越容易出现未审不可逆步骤。"
  - R11 → "质量门禁返回 NOT ASSESSED 时按未满足处理：要么补齐运行条件（verdict 会点名缺什么），要么把'部署未验证修复'显式升级为负责人的决策并记录决策人与理由——禁止在时间压力下按通过解读。"

## 6. 关联文档
- 上游：`/bug-report`（bug 文件与 verify/close）、`/bug-triage`（严重度量表的来源）。
- 下游：`/smoke-check`、`/team-qa`（QA 重入门禁执行者）、`/patch-notes`（记录 hotfix）、`/bug-report verify` / `close`（部署后验证与关闭）、`/retrospective`（复盘，事故本身用 incident-response 模板记录）。
- 引用：`.claude/docs/templates/incident-response.md`、`project.yaml` 的 `commands.test`。
