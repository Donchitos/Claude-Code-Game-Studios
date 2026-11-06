---
name: hotfix
description: "Emergency fix bypassing normal sprint process — hotfix branch, approvals tracked, backport verified, full audit trail."
argument-hint: "[bug-id or description]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(git rev-parse *), Bash(git tag --list*), Bash(git branch --list *)
model: sonnet
---

---
name: hotfix
description: "绕过常规冲刺流程的紧急修复——热修复分支、跟踪批准、验证回移、完整审计轨迹。"
argument-hint: "[bug-id or description]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(git rev-parse *), Bash(git tag --list*), Bash(git branch --list *)
model: sonnet
---

# Hotfix
# 热修复

> **Explicit invocation only**: This skill should only run when the user explicitly requests it with `/hotfix`. Do not auto-invoke based on context matching.

> **仅显式调用**：本技能应仅在用户用 `/hotfix` 明确请求时运行。不要基于上下文匹配自动调用。

## Phase 1: Assess Severity
## 阶段 1：评估严重程度

Read the bug description or ID. Assess severity on `/bug-triage`'s scale:

读取缺陷描述或 ID。按 `/bug-triage` 的等级评估严重程度：

- **S1 (Critical)**: Crash, data loss, or complete feature failure — the game cannot proceed (rate a security issue by that impact)
- **S2 (High)**: Major feature broken, but the game is still playable
- **S3 or lower**: Feature degraded with a workaround, or cosmetic — normal bug fix workflow applies

- **S1（严重）**：崩溃、数据丢失或功能完全失效——游戏无法继续（按该影响评定安全问题）
- **S2（高）**：主要功能损坏，但游戏仍可游玩
- **S3 或更低**：功能降级但有变通方法，或外观问题——适用常规缺陷修复工作流

Confirm with `AskUserQuestion`:
- Prompt: "I've assessed this as **[assessed severity]** — [brief rationale]. Confirm severity to proceed:"
- Options:
  - `[A] S1 (Critical) — crash, data loss, or complete feature failure`
  - `[B] S2 (High) — major feature broken, game still playable`
  - `[C] S3 or lower — redirect to normal bug fix workflow`

使用 `AskUserQuestion` 确认：
- 提示：“我已将其评估为 **[assessed severity]**——[brief rationale]。确认严重程度以继续：”
- 选项：
  - `[A] S1 (Critical) — crash, data loss, or complete feature failure`
  - `[B] S2 (High) — major feature broken, game still playable`
  - `[C] S3 or lower — redirect to normal bug fix workflow`

If [C]: stop. Verdict: **REDIRECTED** — use the normal bug fix workflow for S3 and below.

如果 [C]：停止。结论：**REDIRECTED**——对 S3 及以下使用常规缺陷修复工作流。

---

## Phase 2: Create Hotfix Record
## 阶段 2：创建热修复记录

Draft the hotfix record:

草拟热修复记录：

```markdown
## Hotfix: [Short Description]
Date: [Date]
Severity: [S1/S2]
Reporter: [Who found it]
Status: IN PROGRESS

### Problem
[Clear description of what is broken and the player impact]

### Root Cause
[To be filled during investigation]

### Fix
[To be filled during implementation]

### Testing
[What was tested and how]

### Approvals
- [ ] Fix reviewed by lead-programmer
- [ ] Regression test passed (qa-tester)
- [ ] Release approved (producer)

### Rollback Plan
[How to revert if the fix causes new issues]
```

```markdown
## 热修复：[简短描述]
日期：[Date]
严重程度：[S1/S2]
报告者：[Who found it]
状态：IN PROGRESS

### 问题
[清晰描述什么损坏以及玩家影响]

### 根本原因
[调查期间填写]

### 修复
[实现期间填写]

### 测试
[测试了什么以及如何测试]

### 批准
- [ ] 修复已由 lead-programmer 评审
- [ ] 回归测试通过（qa-tester）
- [ ] 发布已批准（producer）

### 回滚计划
[如果修复导致新问题，如何回退]
```

Ask: "May I write this to `production/hotfixes/hotfix-[date]-[short-name].md`?"

询问：“我可以将此写入 `production/hotfixes/hotfix-[date]-[short-name].md` 吗？”

If yes, write the file, creating the directory if needed.

如果是，写入文件，必要时创建目录。

---

## Phase 3: Create Hotfix Branch
## 阶段 3：创建热修复分支

Check whether this is a git repository:

检查这是否是 git 仓库：

`Bash: git rev-parse --is-inside-work-tree 2>/dev/null`

If this command fails or returns empty: note "Not a git repository — create the branch manually." and skip branch creation.

如果此命令失败或返回空：注明“不是 git 仓库——手动创建分支。”并跳过分支创建。

`[base-ref]` is the release the bug is in. Releases are tags on `main` (the
trunk), so it is that release's tag (`git tag --list`; the newest is usually
the live build) — or its `release/*` branch, if one was cut to stabilise that
release (`git branch --list 'release/*'`). Never the head of `main`: it may carry
work that has not shipped.

`[base-ref]` 是缺陷所在的发布版。发布版是 `main`（主干）上的标签，因此它是该发布版的标签（`git tag --list`；最新的通常是线上构建）——或其 `release/*` 分支，如果曾切出一个来稳定该发布版（`git branch --list 'release/*'`）。绝不是 `main` 的头部：它可能带有尚未发布的工作。

If the check passes, use `AskUserQuestion` before creating the branch:
- Prompt: "Ready to create hotfix branch 'hotfix/[short-name]' from [base-ref]?"
- Options:
  - `[A] Yes — create branch`
  - `[B] Use a different base ref — I'll specify it`
  - `[C] Skip — I'll create the branch myself`

如果检查通过，在创建分支前使用 `AskUserQuestion`：
- 提示：“准备从 [base-ref] 创建热修复分支 'hotfix/[short-name]' 吗？”
- 选项：
  - `[A] Yes — create branch`
  - `[B] Use a different base ref — I'll specify it`
  - `[C] Skip — I'll create the branch myself`

Only run `git checkout -b hotfix/[short-name] [base-ref]` if user selects [A]. If [B]: ask the user for the base ref, then run the command with that ref. If [C]: skip branch creation and proceed to Phase 4.

仅在用户选择 [A] 时运行 `git checkout -b hotfix/[short-name] [base-ref]`。如果 [B]：向用户询问 base ref，然后用该 ref 运行命令。如果 [C]：跳过分支创建并进入阶段 4。

---

## Phase 4: Investigate and Propose
## 阶段 4：调查并提议

Find the root cause. Draft the minimal fix: which files change, what the change does, and what it deliberately leaves alone. Do NOT refactor, clean up, or add features alongside the hotfix.

找到根本原因。草拟最小修复：哪些文件更改、更改做什么，以及它有意不碰什么。不要在热修复之外重构、清理或添加功能。

Present the root cause and proposed fix, then ask: "May I implement this fix?" Do not modify any code before this approval — an emergency flow earns its audit trail by approving the change *before* it exists, not after.

呈现根本原因和建议修复，然后询问：“我可以实现此修复吗？”在此批准之前不要修改任何代码——紧急流程通过在变更*存在之前*而非之后批准它，来赢得其审计轨迹。

---

## Phase 4b: Implement (only after approval)
## 阶段 4b：实现（仅在批准后）

Implement the approved minimal change. Validate the fix by running targeted tests for the affected system, with `commands.test` from `project.yaml` (narrowed to the affected suite where the runner allows) — never a runner line written from memory, which drops the flags the engine needs (gdUnit4 hangs without `--remote-debug tcp://127.0.0.1:0`). Check for regressions in adjacent systems. If `commands.test` is unset, or no test covers the affected system, say so and record `Tests: NOT RUN — [reason]` in the hotfix record's Testing section; the Phase 5b QA gate then carries the verification.

实现已批准的最小变更。通过为受影响系统运行定向测试来验证修复，使用 `project.yaml` 中的 `commands.test`（在运行器允许的情况下收窄到受影响套件）——绝不要凭记忆写运行器命令行，因为那会丢掉引擎所需的标志（gdUnit4 在没有 `--remote-debug tcp://127.0.0.1:0` 时会挂起）。检查相邻系统是否有回归。如果 `commands.test` 未设置，或没有测试覆盖受影响系统，说明这一点，并在热修复记录的 Testing 部分记录 `Tests: NOT RUN — [reason]`；随后阶段 5b 的 QA 门禁承担验证。

Update the hotfix record with root cause, fix details, and test results.

用根本原因、修复细节和测试结果更新热修复记录。

---

## Phase 5: Collect Approvals
## 阶段 5：收集批准

Use the `Agent` tool to request sign-off in parallel:

使用 `Agent` 工具并行请求签核：

- `subagent_type: lead-programmer` — Review the fix for correctness and side effects
- `subagent_type: qa-tester` — Run targeted regression tests on the affected system
- `subagent_type: producer` — Approve deployment timing and communication plan

- `subagent_type: lead-programmer`——评审修复的正确性和副作用
- `subagent_type: qa-tester`——对受影响系统运行定向回归测试
- `subagent_type: producer`——批准部署时机和沟通计划

All three must return APPROVE before proceeding. If any returns CONCERNS or REJECT, do not deploy — surface the issue and resolve it first.

三方都必须返回 APPROVE 才能继续。如果任何一方返回 CONCERNS 或 REJECT，不要部署——呈现问题并先解决它。

---

## Phase 5b: QA Re-Entry Gate
## 阶段 5b：QA 重入门禁

After approvals, determine the QA scope required before deploying the hotfix. Spawn `qa-lead` via `Agent` with:
- The hotfix description and affected system
- The regression test results from Phase 5
- A list of all systems that touch the changed files (use Grep to find callers)

在批准后，确定部署热修复前所需的 QA 范围。通过 `Agent` 生成 `qa-lead`，提供：
- 热修复描述和受影响系统
- 阶段 5 的回归测试结果
- 触及已更改文件的所有系统列表（使用 Grep 查找调用方）

Ask qa-lead: **Is a full smoke check sufficient, or does this fix require a targeted team-qa pass?**

询问 qa-lead：**完整冒烟检查是否足够，还是此修复需要定向 team-qa 流程？**

Apply the verdict:
- **Smoke check sufficient** — run `/smoke-check` against the hotfix build. If PASS or
  PASS WITH WARNINGS, proceed to Phase 6 (carry the warnings into the hotfix record).
  If **FAIL**, do not deploy: return to Phase 4 with the failing checks, get the
  revised fix approved there, implement it (Phase 4b), then re-run Phase 5's
  approvals — qa-tester's regression run among them — and this QA step. A hotfix
  that breaks the smoke suite is a second incident, not a fix.
- **Targeted QA pass required** — run `/team-qa feature: [affected-system]` scoped to the changed system only. If QA returns APPROVED or APPROVED WITH CONDITIONS, proceed to Phase 6; if NOT APPROVED or BLOCKED, handle it as a smoke-check FAIL above.
- **Full QA required** — S1 fixes that touch core systems may require a full `/team-qa sprint`. This delays deployment but prevents a bad patch.

应用结论：
- **冒烟检查足够**——针对热修复构建运行 `/smoke-check`。如果为 PASS 或 PASS WITH WARNINGS，进入阶段 6（将警告带入热修复记录）。如果为 **FAIL**，不要部署：带着失败检查回到阶段 4，在那里让修订后的修复获得批准，实施它（阶段 4b），然后重新运行阶段 5 的批准——其中包括 qa-tester 的回归运行——以及此 QA 步骤。破坏冒烟套件的热修复是第二次事故，而不是修复。
- **需要定向 QA 流程**——运行 `/team-qa feature: [affected-system]`，范围仅限更改的系统。如果 QA 返回 APPROVED 或 APPROVED WITH CONDITIONS，进入阶段 6；如果 NOT APPROVED 或 BLOCKED，按上述冒烟检查 FAIL 处理。
- **需要完整 QA**——触及核心系统的 S1 修复可能需要完整的 `/team-qa sprint`。这会延迟部署，但可防止糟糕的补丁。

**If the QA step returns `NOT ASSESSED`, the gate did not run — treat it as unmet,
not as met.** `/smoke-check` returns it when the suite never executed and
`/team-qa` when a cycle produced no executed evidence. **A NOT ASSESSED result is
not a pass** — from either skill — and under time pressure the permissive reading
is the one that will feel reasonable,
which is exactly why it is written down here. Either obtain the missing result —
the verdict names what would make it runnable — or take the decision to the
producer explicitly, as a decision to deploy an unverified hotfix rather than as a
gate that quietly cleared. Log that decision — who made it, and why — in the
hotfix record's Testing section.

**如果 QA 步骤返回 `NOT ASSESSED`，门禁未运行——将其视为未满足，而不是已满足。** 当套件从未执行时 `/smoke-check` 会返回它，当某个循环没有产生已执行证据时 `/team-qa` 会返回它。**NOT ASSESSED 结果不是通过**——来自任一技能——而在时间压力下，宽松的解读才是会显得合理的那种，这正是它被写在这里的原因。要么取得缺失的结果——结论会指出什么能让它可运行——要么把决定明确交给 producer，作为部署未验证热修复的决定，而不是作为悄悄清除的门禁。在热修复记录的 Testing 部分记录该决定——谁做的，以及为什么。

Do not skip this gate. A hotfix that breaks something else is worse than the original bug.

不要跳过此门禁。破坏其他东西的热修复比原始缺陷更糟。

---

## Phase 6: Update Bug Status and Deploy
## 阶段 6：更新缺陷状态并部署

> **STOP — deployment requires explicit approval, unconditionally.** Merging a
> hotfix and tagging the patch release is the one irreversible act in this skill,
> so it is gated even though branch creation (reversible) already is. Before any
> merge, tag, or deploy, use `AskUserQuestion`:
>
> - Prompt: "Hotfix validated and approved. Merge to [targets], tag [patch tag]
>   and deploy?" — `[targets]` is `main`, plus the release's `release/*` branch
>   only if it has one
> - Options: `[A] Yes — merge and deploy` / `[B] Merge to main only — hold
>   the release` / `[C] Stop here`
>
> This holds regardless of `modes.automation`, including `autonomous`. An
> emergency process is exactly where an unreviewed irreversible step is most
> likely and least recoverable.

> **停止——部署无条件需要明确批准。** 合并热修复并给补丁发布打标签是本技能中唯一不可逆的行为，因此即使分支创建（可逆）已经设门禁，它也被设门禁。在任何合并、打标签或部署之前，使用 `AskUserQuestion`：
>
> - 提示：“热修复已验证并批准。合并到 [targets]，打标签 [patch tag] 并部署？”——`[targets]` 是 `main`，加上发布版的 `release/*` 分支（仅当其存在时）
> - 选项：`[A] Yes — merge and deploy` / `[B] Merge to main only — hold the release` / `[C] Stop here`
>
> 无论 `modes.automation` 如何，包括 `autonomous`，这一点都成立。紧急流程正是未评审的不可逆步骤最可能出现、也最难恢复的地方。

On `[A]`: merge the hotfix branch to `main`, and to the release's `release/*`
branch if it has one; tag the patch release (the next patch version, e.g.
`v1.2.0` → `v1.2.1`) on the fixed build — the `release/*` branch head if there
is one, else the hotfix branch head — and deploy that tag, not the head of
`main`. On `[B]`: merge to `main` only — no release-branch merge, no tag, no
deploy. On `[C]`: stop — no merge, no tag, no deploy and no bug-file update; the
hotfix record's Status stays IN PROGRESS, and say so.

在 `[A]`：将热修复分支合并到 `main`，如果发布版有 `release/*` 分支也合并到该分支；在修复后的构建上给补丁发布打标签（下一个补丁版本，例如 `v1.2.0` → `v1.2.1`）——如果有 `release/*` 分支则用其头部，否则用热修复分支头部——并部署该标签，而不是 `main` 的头部。在 `[B]`：仅合并到 `main`——不合并发布分支、不打标签、不部署。在 `[C]`：停止——不合并、不打标签、不部署也不更新缺陷文件；热修复记录的 Status 保持 IN PROGRESS，并说明这一点。

> **Backport is not verified unless you verify it.** The frontmatter advertises
> "backport verified". After merging, confirm the fix is present on `main` (the
> trunk) — and on the release's `release/*` branch, if it has one — and state
> the result. An unbackported hotfix means the bug returns in the next release
> tagged from `main`, which is the single most common hotfix regression.

> **除非你验证，否则回移未经验证。** 前置元数据宣称“backport verified”。合并后，确认修复存在于 `main`（主干）上——以及发布版的 `release/*` 分支上（如果存在）——并说明结果。未回移的热修复意味着该缺陷会在从 `main` 打标签的下一个发布版中回归，这是最常见的单一热修复回归。

Update the original bug file if one exists — find it in `production/qa/bugs/`
by its number, as `/bug-report verify` does. Ask first: "May I update
`production/qa/bugs/[bug file]` with the fix record below and set its Status to
`Fixed — Pending Verification`?"

如果原始缺陷文件存在，更新它——像 `/bug-report verify` 那样，在 `production/qa/bugs/` 中按其编号找到它。先询问：“我可以更新 `production/qa/bugs/[bug file]`，写入下方修复记录，并将其 Status 设置为 `Fixed — Pending Verification` 吗？”

```markdown
## Fix Record
**Fixed in**: hotfix/[branch-name] — [commit hash or description]
**Fixed date**: [date]
**Status**: Fixed — Pending Verification
```

```markdown
## 修复记录
**修复于**：hotfix/[branch-name]——[commit hash or description]
**修复日期**：[date]
**状态**：Fixed — Pending Verification
```

Set `**Status**: Fixed — Pending Verification` in the bug file header.

在缺陷文件头部设置 `**Status**: Fixed — Pending Verification`。

Output a deployment summary. Its title follows the Phase 6 answer — `Hotfix
Deployed: [short-name]` on `[A]`, `Hotfix Merged to main — release held:
[short-name]` on `[B]` — and on `[B]` the closing line omits the Tag, since none
was created:

输出部署摘要。其标题取决于阶段 6 的答案——`[A]` 为 `Hotfix Deployed: [short-name]`，`[B]` 为 `Hotfix Merged to main — release held: [short-name]`——并且在 `[B]` 下，结尾行省略 Tag，因为未创建标签：

```
## Hotfix Deployed: [short-name]

**Severity**: [S1/S2]
**Root cause**: [one line]
**Fix**: [one line]
**QA gate**: [Smoke check PASS / Team-QA APPROVED / NOT ASSESSED — [why, and whose
             explicit decision it was to deploy anyway]]
**Approvals**: lead-programmer ✓ / qa-tester ✓ / producer ✓
**Backport**: [verified present on `main` (and the `release/*` branch, if the
              release has one) — or NOT VERIFIED, with what was not checked]
**Rollback plan**: [from Phase 2 record]

Merge to: [targets] · Tag: [patch tag]
Next: /bug-report verify [BUG-ID] after deploy to confirm resolution
```

```
## 热修复已部署：[short-name]

**严重程度**：[S1/S2]
**根本原因**：[one line]
**修复**：[one line]
**QA 门禁**：[Smoke check PASS / Team-QA APPROVED / NOT ASSESSED——[为什么，以及谁明确决定无论如何都部署]]
**批准**：lead-programmer ✓ / qa-tester ✓ / producer ✓
**回移**：[已验证存在于 `main`（以及发布版的 `release/*` 分支，如果该发布版有的话）——或 NOT VERIFIED，并说明未检查什么]
**回滚计划**：[from Phase 2 record]

合并到：[targets] · 标签：[patch tag]
下一步：部署后运行 /bug-report verify [BUG-ID] 确认解决
```

### Rules
- Hotfixes must be the MINIMUM change to fix the issue — no cleanup, no refactoring
- Every hotfix must have a rollback plan documented before deployment
- A hotfix branch starts from the release it fixes — its tag, or its `release/*`
  branch if one exists — and merges to `main` (the trunk), and to that
  `release/*` branch only if it exists; the patch release is tagged
- All hotfixes require a post-incident review within 48 hours
- If the fix is complex enough to need more than 4 hours, escalate to `technical-director`

### 规则
- 热修复必须是修复问题的最小变更——不清理、不重构
- 每个热修复都必须在部署前记录回滚计划
- 热修复分支从它要修复的发布版开始——其标签，或其 `release/*` 分支（如存在）——并合并到 `main`（主干），且仅当该 `release/*` 分支存在时才合并到它；补丁发布打标签
- 所有热修复都需要在 48 小时内进行事后评审
- 如果修复复杂到需要超过 4 小时，升级给 `technical-director`

---

## Phase 7: Post-Deploy Verification
## 阶段 7：部署后验证

After deploying, run `/bug-report verify [BUG-ID]` to confirm the fix resolved the issue in the deployed build.

部署后，运行 `/bug-report verify [BUG-ID]` 确认修复在已部署构建中解决了问题。

If VERIFIED FIXED: run `/bug-report close [BUG-ID]` to formally close it.
If STILL PRESENT: the hotfix failed — immediately re-open, assess rollback, and escalate.
If CANNOT VERIFY: the fix is unconfirmed — do not close the bug; play its reproduction steps in the deployed build, then run `/bug-report verify [BUG-ID]` again and answer its manual-play question to settle it.

如果 VERIFIED FIXED：运行 `/bug-report close [BUG-ID]` 正式关闭它。
如果 STILL PRESENT：热修复失败——立即重新开启、评估回滚并升级。
如果 CANNOT VERIFY：修复未确认——不要关闭缺陷；在已部署构建中执行其复现步骤，然后再次运行 `/bug-report verify [BUG-ID]` 并回答其手动游玩问题以确定。

Schedule a post-incident review within 48 hours. `/retrospective` reviews a
sprint or milestone, not an incident: record the review with
`.claude/docs/templates/incident-response.md`, and raise its lessons at the next
`/retrospective`.

在 48 小时内安排事后评审。`/retrospective` 评审冲刺或里程碑，而不是事故：用 `.claude/docs/templates/incident-response.md` 记录评审，并在下一次 `/retrospective` 上提出其经验教训。

Use `AskUserQuestion`:
- Prompt: "Hotfix complete. What's the next step?"
- Options:
  - `[A] Run /smoke-check to verify the fix`
  - `[B] Run /patch-notes to document this hotfix`
  - `[C] Stop here`

使用 `AskUserQuestion`：
- 提示：“热修复完成。下一步是什么？”
- 选项：
  - `[A] Run /smoke-check to verify the fix`
  - `[B] Run /patch-notes to document this hotfix`
  - `[C] Stop here`
