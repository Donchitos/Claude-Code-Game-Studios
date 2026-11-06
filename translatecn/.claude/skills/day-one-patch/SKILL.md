---
name: day-one-patch
description: "Day-one launch patch — focused fix for known issues found after gold master. Mini-sprint with QA gate and rollback."
argument-hint: "[scope: known-bugs | cert-feedback | all]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion
model: sonnet
---

---
name: day-one-patch
description: "首日发布补丁——针对金母版后发现已知问题的集中修复。带 QA 门禁与回滚的迷你冲刺。"
argument-hint: "[scope: known-bugs | cert-feedback | all]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion
model: sonnet
---

# Day-One Patch
# 首日补丁

Every shipped game has a day-one patch. Planning it before launch day prevents
chaos. This skill scopes the patch to only what is safe and necessary, gates it
through a lightweight QA pass, and ensures a rollback plan exists before anything
ships. It is a mini-sprint — not a hotfix, not a full sprint.

每款已发布的游戏都有首日补丁。在发布日前规划它可以防止混乱。本技能将补丁范围限定为仅安全且必要的内容，通过轻量级 QA 流程设门禁，并确保在任何内容发布前存在回滚计划。它是一个迷你冲刺——不是热修复，也不是完整冲刺。

**When to run:**
- After the gold master build is locked (cert approved or launch candidate tagged)
- When known bugs exist that are too risky to address in the gold master
- When cert feedback requires minor fixes post-submission
- When a pre-launch playtest surfaces must-fix issues after the release gate passed

**何时运行：**
- 在金母版构建锁定之后（认证批准或发布候选已打标签）
- 当存在风险过高、不宜在金母版中处理的已知缺陷时
- 当认证反馈要求提交后进行小修复时
- 当发布前试玩在发布门禁通过后暴露出必须修复的问题时

**Day-one patch scope rules:**
- Only P1/P2 bugs that are SAFE to fix quickly
- No new features — this is fix-only
- No refactoring — minimum viable change
- Any fix that requires more than 4 hours of dev time belongs in patch 1.1, not day-one

**首日补丁范围规则：**
- 仅限可快速安全修复的 P1/P2 缺陷
- 不新增功能——仅修复
- 不重构——最小可行变更
- 任何需要超过 4 小时开发时间的修复都属于补丁 1.1，而不是首日补丁

**Output:** `production/releases/day-one-patch-[version].md`

**输出：** `production/releases/day-one-patch-[version].md`

---

## Phase 1: Load Release Context
## 阶段 1：加载发布上下文

Read:
- `project.stage` in `project.yaml` (fallback `production/stage.txt`) — confirm project is in Release stage
- The most recent file in `production/gate-checks/` — read the release gate verdict
- `production/qa/bugs/*.md` — load all bugs with Status: Open or Fixed — Pending Verification
- `production/sprints/` most recent — understand what shipped
- `production/security/security-audit-*.md` most recent — check for any open security items

读取：
- `project.yaml` 中的 `project.stage`（后备为 `production/stage.txt`）——确认项目处于 Release 阶段
- `production/gate-checks/` 中最近的文件——读取发布门禁结论
- `production/qa/bugs/*.md`——加载所有 Status 为 Open 或 Fixed — Pending Verification 的缺陷
- 最近的 `production/sprints/`——了解已发布内容
- 最近的 `production/security/security-audit-*.md`——检查任何未关闭的安全事项

If the resolved stage (project.yaml → stage.txt) is not `Release` or `Polish`:
> "Day-one patch prep is for Release-stage projects. Current stage: [stage]. This skill is not appropriate until you are approaching launch."

如果解析出的阶段（project.yaml → stage.txt）不是 `Release` 或 `Polish`：
> “首日补丁准备适用于 Release 阶段项目。当前阶段：[stage]。在你接近发布之前，此技能并不合适。”

**Check the premise, do not assume it.** This whole skill rests on there being a
gold master that already passed a release gate — that premise is what justifies
its lightweight QA pass instead of a full one. So verify it rather than inferring
it from the stage value:

**检查前提，不要假设它。** 整个技能建立在存在一个已通过发布门禁的金母版之上——该前提正是将其 QA 流程设为轻量级而非完整级的理由。因此要验证它，而不是从阶段值推断：

- **No file in `production/gate-checks/`**, or none recording a release-gate
  verdict: report `Release gate: NOT ASSESSED — no gate-check record found`. Do
  not proceed silently. Say plainly that the reduced QA scope below is justified
  by a gate nobody can find, and ask whether to run `/gate-check` first or
  proceed with a full QA pass instead.
- **The most recent record is FAIL, CONCERNS or NOT ASSESSED**: name it and stop.
  A day-one patch on top of a build that never passed its gate is not a day-one
  patch; it is the release gate, arriving late and scoped to the wrong changes.
- `project.stage: Release` on its own does **not** establish this. The stage is a
  claim about where the project is; the gate record is the evidence that it earned
  the position.

- **`production/gate-checks/` 中没有文件**，或没有记录发布门禁结论：报告 `Release gate: NOT ASSESSED — no gate-check record found`。不得静默继续。明确说明下方缩减的 QA 范围是由一个无人能找到的门禁来证明的，并询问是先运行 `/gate-check`，还是改为进行完整 QA 流程。
- **最近的记录是 FAIL、CONCERNS 或 NOT ASSESSED**：指出它并停止。在一个从未通过门禁的构建之上加首日补丁，不是首日补丁；那是发布门禁迟到，且范围错配到了错误的变更上。
- `project.stage: Release` 本身**并不能**确立这一点。阶段是对项目所在位置的声明；门禁记录才是它赢得该位置的证据。

---

## Phase 2: Scope the Patch
## 阶段 2：确定补丁范围

### Step 2a — Classify open bugs for patch inclusion
### 步骤 2a——分类未关闭缺陷以确定是否纳入补丁

For each open bug, evaluate:

对于每个未关闭缺陷，评估：

| Criterion | Include in day-one? |
|-----------|-------------------|
| S1 or S2 severity | Yes — must include if safe to fix |
| P1 priority | Yes |
| Fix estimated < 4 hours | Yes |
| Fix requires architecture change | No — defer to 1.1 |
| Fix introduces new code paths | No — too risky |
| Fix is data/config only (no code change) | Yes — very low risk |
| Cert feedback requirement | Yes — required for platform approval |
| S3/S4 severity | Only if trivial config fix; otherwise defer |

| 标准 | 纳入首日补丁？ |
|-----------|-------------------|
| S1 或 S2 严重程度 | 是——如果可安全修复则必须纳入 |
| P1 优先级 | 是 |
| 修复估计 < 4 小时 | 是 |
| 修复需要架构变更 | 否——延后到 1.1 |
| 修复引入新代码路径 | 否——风险过高 |
| 修复仅为数据/配置（无代码变更） | 是——风险极低 |
| 认证反馈要求 | 是——平台批准所需 |
| S3/S4 严重程度 | 仅限简单的配置修复；否则延后 |

### Step 2b — Present patch scope to user
### 步骤 2b——向用户呈现补丁范围

Use `AskUserQuestion`:
- Prompt: "Based on open bugs and cert feedback, here is the proposed day-one patch scope. Does this look right?"
- Show: table of included bugs (ID, severity, description, estimated effort)
- Show: table of deferred bugs (ID, severity, reason deferred)
- Options: `[A] Approve this scope` / `[B] Adjust — I want to add or remove items` / `[C] No day-one patch needed`

使用 `AskUserQuestion`：
- 提示：“根据未关闭缺陷和认证反馈，以下是建议的首日补丁范围。这样看起来对吗？”
- 展示：纳入缺陷的表（ID、严重程度、描述、估计工作量）
- 展示：延后缺陷的表（ID、严重程度、延后原因）
- 选项：`[A] Approve this scope` / `[B] Adjust — I want to add or remove items` / `[C] No day-one patch needed`

If [C]: output "No day-one patch required. Proceed to `/launch-checklist`." Stop.

如果 [C]：输出“无需首日补丁。继续执行 `/launch-checklist`。”停止。

### Step 2c — Check total scope
### 步骤 2c——检查总范围

Sum estimated effort. If total exceeds 1 day of work:
> "⚠️ Patch scope is [N hours] — this exceeds a safe day-one window. Consider deferring lower-priority items to patch 1.1. A bloated day-one patch introduces more risk than it removes."

汇总估计工作量。如果总量超过 1 天工作：
> “⚠️ 补丁范围为 [N hours]——这超出了安全的次日窗口。考虑将较低优先级项目延后到补丁 1.1。臃肿的首日补丁引入的风险多于它消除的风险。”

Use `AskUserQuestion` to confirm proceeding or reduce scope.

使用 `AskUserQuestion` 确认继续或缩减范围。

---

## Phase 3: Rollback Plan
## 阶段 3：回滚计划

Before any code is written, define the rollback procedure. This is non-negotiable.

在任何代码编写之前，定义回滚流程。这没有商量余地。

Spawn `release-manager` via `Agent`. Ask them to produce a rollback plan covering:
- How to revert to the gold master build on each target platform
- Platform-specific rollback constraints (some platforms cannot roll back cert builds)
- Who is responsible for triggering the rollback
- What player communication is required if a rollback occurs

通过 `Agent` 生成 `release-manager`。要求其产出一份回滚计划，涵盖：
- 如何在各目标平台上回退到金母版构建
- 平台特定的回滚约束（某些平台无法回滚已认证构建）
- 谁负责触发回滚
- 如果发生回滚，需要什么样的玩家沟通

Present the rollback plan. Ask: "May I write this rollback plan to `production/releases/rollback-plan-[version].md`?"

呈现回滚计划。询问：“我可以将此回滚计划写入 `production/releases/rollback-plan-[version].md` 吗？”

Do not proceed to Phase 4 until the rollback plan is written.

在回滚计划写入之前，不要进入阶段 4。

---

## Phase 4: Implement Fixes
## 阶段 4：实现修复

For each code fix in the approved scope, spawn a focused implementation loop:

对于批准范围内的每个代码修复，生成一个集中的实现循环：

1. Spawn `lead-programmer` via `Agent` with:
   - The bug report (exact reproduction steps and root cause if known)
   - The constraint: minimum viable fix only, no cleanup
   - The affected files (from bug report Technical Context section)

   It returns, for each bug, the minimal fix and the files it would change —
   writing nothing.

1. 通过 `Agent` 生成 `lead-programmer`，提供：
   - 缺陷报告（确切复现步骤，以及已知时的根本原因）
   - 约束：仅最小可行修复，不做清理
   - 受影响文件（来自缺陷报告 Technical Context 部分）

   它针对每个缺陷返回最小修复及将要更改的文件——不写入任何内容。

2. Ask once, for the whole set: "May I apply these fixes? [BUG-ID → files, one
   line each]". No code changes before this approval.

2. 对整套修复一次询问：“我可以应用这些修复吗？[BUG-ID → files, one line each]”。在此批准之前不做代码更改。

3. On yes, hand each approved fix back to `lead-programmer` (a new `Agent` call
   carrying its plan) to implement it and run targeted tests with `commands.test`
   from `project.yaml`, narrowed to the affected suite where the runner allows —
   never a runner line written from memory. If `commands.test` is unset, say so
   and record `Tests: NOT RUN — commands.test unset` for that bug.

3. 在同意后，将每个已批准修复交回 `lead-programmer`（携带其计划的新 `Agent` 调用）来实施，并使用 `project.yaml` 中的 `commands.test` 运行定向测试，在运行器允许的情况下收窄到受影响套件——绝不要凭记忆写运行器命令行。如果 `commands.test` 未设置，说明这一点，并为该缺陷记录 `Tests: NOT RUN — commands.test unset`。

4. Spawn `qa-tester` via `Agent` to verify: does the bug reproduce after the fix?

4. 通过 `Agent` 生成 `qa-tester` 验证：修复后该缺陷是否仍能复现？

For config/data-only fixes: make the change directly (no programmer agent needed). First ask, naming the file and the change: "May I edit `[config file]` — `[key]`: [old value] → [new value]?" Confirm the value changed and re-run any relevant smoke test.

对于仅配置/数据的修复：直接进行更改（无需程序员智能体）。先询问，并说明文件与更改：“我可以编辑 `[config file]`——`[key]`：[old value] → [new value] 吗？”确认值已更改，并重新运行任何相关冒烟测试。

---

## Phase 5: Patch QA Gate
## 阶段 5：补丁 QA 门禁

This is a lightweight QA pass — not a full `/team-qa`. The patch is already QA-approved from the release gate; we are only re-verifying the changed areas.

这是一次轻量级 QA 流程——不是完整的 `/team-qa`。补丁已因发布门禁获得 QA 批准；我们只是重新验证更改区域。

Spawn `qa-lead` via `Agent` with:
- List of all changed files
- List of bugs fixed (with verification status from Phase 4)
- The smoke check scope for the affected systems

通过 `Agent` 生成 `qa-lead`，提供：
- 所有已更改文件的列表
- 已修复缺陷列表（含阶段 4 的验证状态）
- 受影响系统的冒烟检查范围

Ask qa-lead to determine: **Is a targeted smoke check sufficient, or do any fixes touch systems that require a broader regression?**

询问 qa-lead 判断：**定向冒烟检查是否足够，还是任何修复触及需要更广泛回归的系统？**

Run the required QA scope:
- **Targeted smoke check** — run `/smoke-check` (it takes no system argument)
- **Broader regression** — run the affected systems' tests in the engine's test root (`tests/unit/` and `tests/integration/` Godot, `Assets/Tests/` Unity, `Source/<Module>/Private/Tests/` Unreal — `.claude/docs/directory-structure.md`) with `commands.test` from `project.yaml`, narrowed to the affected suites where the runner allows — never a runner line written from memory. If `commands.test` is unset, the broader regression is NOT ASSESSED; say so.

运行所需 QA 范围：
- **定向冒烟检查**——运行 `/smoke-check`（它不接受系统参数）
- **更广泛回归**——在引擎的测试根目录中运行受影响系统的测试（Godot 为 `tests/unit/` 和 `tests/integration/`，Unity 为 `Assets/Tests/`，Unreal 为 `Source/<Module>/Private/Tests/`——见 `.claude/docs/directory-structure.md`），使用 `project.yaml` 中的 `commands.test`，在运行器允许的情况下收窄到受影响套件——绝不要凭记忆写运行器命令行。如果 `commands.test` 未设置，更广泛回归为 NOT ASSESSED；说明这一点。

QA verdict must be PASS or PASS WITH WARNINGS before proceeding. If FAIL: scope the failing fix out of the day-one patch and defer to 1.1.

在继续之前，QA 结论必须是 PASS 或 PASS WITH WARNINGS。如果 FAIL：将失败修复移出首日补丁范围并延后到 1.1。

**If the QA verdict is `NOT ASSESSED`, that is not a pass.** `/smoke-check` returns
it when the suite never ran — no build, no runner, or a result nobody confirmed.
Do not proceed on it and do not re-read it as PASS WITH WARNINGS: the warnings
value means somebody looked and saw something minor, and this means nobody looked.
Either obtain the result (the verdict names what would make it runnable) or defer
the fix to 1.1. A day-one patch ships to every player who buys the game on day
one, which is the worst possible audience for an unverified change.

**如果 QA 结论是 `NOT ASSESSED`，那不算通过。** 当套件从未运行时，`/smoke-check` 会返回它——没有构建、没有运行器，或没有人确认的结果。不要据此继续，也不要将其重新解读为 PASS WITH WARNINGS：警告值意味着有人看过并发现了次要问题，而这个意味着没人看过。要么取得结果（结论会指出什么能让它可运行），要么将修复延后到 1.1。首日补丁会发布给每个在首日购买游戏的玩家，那是对未验证变更最糟糕的受众。

---

## Phase 6: Generate Patch Record
## 阶段 6：生成补丁记录

```markdown
# Day-One Patch: [Game Name] v[version]

**Date prepared**: [date]
**Target release**: [launch date or "day of launch"]
**Base build**: [gold master tag or commit]
**Patch build**: [patch tag or commit]

---

## Patch Notes (Internal)

### Bugs Fixed
| BUG-ID | Severity | Description | Fix summary |
|--------|----------|-------------|-------------|
| BUG-NNNN | S[1-4] | [description] | [one-line fix] |

### Deferred to 1.1
| BUG-ID | Severity | Description | Reason deferred |
|--------|----------|-------------|-----------------|
| BUG-NNNN | S[1-4] | [description] | [reason] |

---

## QA Sign-Off

**QA scope**: [Targeted smoke / Broader regression]
**Verdict**: [PASS / PASS WITH WARNINGS / NOT ASSESSED]
**QA lead**: qa-lead agent
**Date**: [date]
**Warnings (if any)**: [list or "None"]
**Not assessed (if any)**: [what could not be checked, and why — or "None"]

---

## Rollback Plan

See: `production/releases/rollback-plan-[version].md`

**Trigger condition**: If [N] or more S1 bugs are reported within [X] hours of launch, execute rollback.
**Rollback owner**: [user / producer]

---

## Approvals Required Before Deploy

- [ ] lead-programmer: all fixes reviewed
- [ ] qa-lead: QA gate PASS confirmed
- [ ] producer: deployment timing approved
- [ ] release-manager: platform submission confirmed

---

## Player-Facing Patch Notes

[Draft for community-manager to review before publishing]

[list player-facing changes in plain language]
```

```markdown
# 首日补丁：[Game Name] v[version]

**准备日期**：[date]
**目标发布**：[launch date or "day of launch"]
**基础构建**：[gold master tag or commit]
**补丁构建**：[patch tag or commit]

---

## 补丁说明（内部）

### 已修复缺陷
| BUG-ID | 严重程度 | 描述 | 修复摘要 |
|--------|----------|-------------|-------------|
| BUG-NNNN | S[1-4] | [description] | [one-line fix] |

### 延后到 1.1
| BUG-ID | 严重程度 | 描述 | 延后原因 |
|--------|----------|-------------|-----------------|
| BUG-NNNN | S[1-4] | [description] | [reason] |

---

## QA 签核

**QA 范围**：[Targeted smoke / Broader regression]
**结论**：[PASS / PASS WITH WARNINGS / NOT ASSESSED]
**QA 负责人**：qa-lead agent
**日期**：[date]
**警告（如有）**：[list or "None"]
**未评估（如有）**：[what could not be checked, and why — or "None"]

---

## 回滚计划

参见：`production/releases/rollback-plan-[version].md`

**触发条件**：如果发布后 [X] 小时内报告 [N] 个或更多 S1 缺陷，则执行回滚。
**回滚负责人**：[user / producer]

---

## 部署前所需批准

- [ ] lead-programmer：所有修复已评审
- [ ] qa-lead：QA 门禁 PASS 已确认
- [ ] producer：部署时机已批准
- [ ] release-manager：平台提交已确认

---

## 面向玩家的补丁说明

[供 community-manager 在发布前评审的草稿]

[用通俗语言列出面向玩家的更改]
```

Ask: "May I write this patch record to `production/releases/day-one-patch-[version].md`?"

询问：“我可以将此补丁记录写入 `production/releases/day-one-patch-[version].md` 吗？”

---

## Phase 7: Next Steps
## 阶段 7：后续步骤

After the patch record is written:

在补丁记录写入后：

1. Run `/patch-notes` to generate the player-facing version of the patch notes
2. Run `/bug-report verify [BUG-ID]` for each fixed bug after the patch is live
3. Run `/bug-report close [BUG-ID]` for each verified fix
4. Schedule a post-launch review 48–72 hours after launch using `/retrospective [milestone-name]` for the launch milestone in `production/milestones/`

1. 运行 `/patch-notes` 生成面向玩家的补丁说明版本
2. 补丁上线后，为每个已修复缺陷运行 `/bug-report verify [BUG-ID]`
3. 为每个已验证修复运行 `/bug-report close [BUG-ID]`
4. 使用 `/retrospective [milestone-name]` 在发布后 48–72 小时安排发布后评审，针对 `production/milestones/` 中的发布里程碑

**If any S1 bugs remain open after the patch:**
> "⚠️ S1 bugs remain open and were not patched. These are accepted risks. Document them in the rollback plan trigger conditions — if they occur at scale, rollback may be preferable to a follow-up patch."

**如果补丁后仍有任何 S1 缺陷未关闭：**
> “⚠️ S1 缺陷仍未关闭且未打补丁。这些是已接受风险。将它们记录在回滚计划的触发条件中——如果大规模发生，回滚可能比后续补丁更可取。”

Use `AskUserQuestion`:
- Prompt: "Day-one patch complete. What's next?"
- Options:
  - `[A] Run /patch-notes — generate player-facing patch notes`
  - `[B] Run /bug-report to log any issues found post-deploy`
  - `[C] Stop here`

使用 `AskUserQuestion`：
- 提示：“首日补丁完成。下一步做什么？”
- 选项：
  - `[A] Run /patch-notes — generate player-facing patch notes`
  - `[B] Run /bug-report to log any issues found post-deploy`
  - `[C] Stop here`

---

## Collaborative Protocol
## 协作协议

- **Scope discipline is everything** — resist scope creep; every addition increases risk
- **Rollback plan first, always** — a patch without a rollback plan is irresponsible
- **Deferred is not forgotten** — every deferred bug is listed in the record's
  "Deferred to 1.1" table; run `/bug-triage` afterwards to schedule them into the 1.1 sprint
  (if the project has no sprint plan, as on the default minimal workflow, into the brief's build order)
- **Player communication is part of the patch** — `/patch-notes` is a required output, not optional

- **范围纪律就是一切**——抵制范围蔓延；每一次追加都会增加风险
- **始终先有回滚计划**——没有回滚计划的补丁是不负责任的
- **延后不等于遗忘**——每个延后缺陷都列在记录的 "Deferred to 1.1" 表中；之后运行 `/bug-triage` 将它们排入 1.1 冲刺（如果项目没有冲刺计划，如在默认最小工作流下，则排入简报的构建顺序）
- **玩家沟通是补丁的一部分**——`/patch-notes` 是必需输出，而非可选
