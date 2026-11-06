---
name: bug-report
description: "Structured bug report from a description, or analyze code for potential bugs. Reproduction steps, severity."
argument-hint: "[description] | analyze [path-to-file] | verify [BUG-ID] | close [BUG-ID]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/bug-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: bug-report
description: "根据描述生成结构化的缺陷报告，或分析代码中的潜在缺陷。包含复现步骤和严重程度。"
argument-hint: "[description] | analyze [path-to-file] | verify [BUG-ID] | close [BUG-ID]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/bug-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用和
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅询问重大事项 · 自主模式记录后继续；
`automation_always_ask` 类别始终会询问）。

# Bug Report

# 缺陷报告

**Drafts only.** This skill writes reports to `production/qa/bugs/`. When the
cause is in the engine, a plugin or another vendor's code, add a draft for their
tracker under **Notes** and stop there: never file, open or comment on an issue
or pull request in their repository. The user submits it.

**仅生成草稿。** 本技能把报告写入 `production/qa/bugs/`。当原因位于引擎、插件或另一个供应商的代码中时，在 **Notes** 下为他们的问题跟踪器添加一份草稿并就此打住：永远不要在他们的仓库中提交、打开或评论 issue 或 pull request。由用户来提交。

## Phase 1: Parse Arguments

## 阶段 1：解析参数

Determine the mode from the argument:

从参数判断模式：

- No keyword → **Description Mode**: generate a structured bug report from the provided description
- `analyze [path]` → **Analyze Mode**: read the target file(s) and identify potential bugs
- `verify [BUG-ID]` → **Verify Mode**: confirm a reported fix actually resolved the bug
- `close [BUG-ID]` → **Close Mode**: mark a verified bug as closed with resolution record

- 无关键字 → **描述模式**：根据提供的描述生成结构化的缺陷报告
- `analyze [path]` → **分析模式**：读取目标文件并找出潜在缺陷
- `verify [BUG-ID]` → **验证模式**：确认所报告的修复是否真正解决了该缺陷
- `close [BUG-ID]` → **关闭模式**：将一个已验证的缺陷标记为关闭，并附上解决记录

If no argument is provided, ask the user for a bug description before proceeding.

如果未提供参数，在继续之前请用户提供缺陷描述。

---

## Phase 2A: Description Mode

## 阶段 2A：描述模式

1. **Parse the description** for key information: what broke, when, how to reproduce it, and what the expected behavior is.

2. **Search the codebase** for related files using Grep/Glob to add context (affected system, likely files).

3. **Draft the bug report**:

1. **解析描述**以获取关键信息：什么坏了、何时发生、如何复现，以及预期行为是什么。

2. **搜索代码库**，使用 Grep/Glob 查找相关文件以补充上下文（受影响的系统、可能的文件）。

3. **起草缺陷报告**：

```markdown
# Bug Report

## Summary
**Title**: [Concise, descriptive title]
**ID**: BUG-[NNNN]
**Severity**: [S1-Critical / S2-High / S3-Medium / S4-Low]
**Priority**: [P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]
**Status**: Open
**Reported**: [Date]
**Reporter**: [the reporter's name as the user gives it, else `—`; never an email address or account ID taken from the session]

## Classification
- **Category**: [Gameplay / UI / Audio / Visual / Performance / Crash / Network]
- **System**: [Which game system is affected — when the bug spans systems, the one whose code must change; the others go under Related systems]
- **Frequency**: [Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%)]
- **Regression**: [Yes/No/Unknown -- was this working before?]

## Environment
- **Build**: [Version or commit hash]
- **Platform**: [OS, hardware if relevant]
- **Scene/Level**: [Where in the game]
- **Game State**: [Relevant state -- inventory, quest progress, etc.]

## Reproduction Steps
**Preconditions**: [Required state before starting]

1. [Exact step 1]
2. [Exact step 2]
3. [Exact step 3]

**Expected Result**: [What should happen]
**Actual Result**: [What actually happens]

## Technical Context
- **Likely affected files**: [List of files based on codebase search]
- **Related systems**: [What other systems might be involved]
- **Possible root cause**: [If identifiable from the description]

## Evidence
- **Logs**: [Relevant log output if available]
- **Visual**: [Description of visual evidence]

## Related Issues
- [Links to related bugs or design documents]

## Notes
[Any additional context or observations]
```

```markdown
# 缺陷报告

## 概要
**标题**：[简明的描述性标题]
**ID**：BUG-[NNNN]
**严重程度**：[S1-Critical / S2-High / S3-Medium / S4-Low]
**优先级**：[P1-Fix this sprint / P2-Fix soon / P3-Backlog / P4-Won't fix]
**状态**：Open
**报告时间**：[Date]
**报告人**：[用户提供的报告人姓名，否则为 `—`；绝不要使用从会话中取得的电子邮件地址或账号 ID]

## 分类
- **类别**：[Gameplay / UI / Audio / Visual / Performance / Crash / Network]
- **系统**：[受影响的游戏系统 —— 当缺陷跨越多个系统时，填必须修改其代码的那一个；其他归入"相关系统"]
- **频率**：[Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%)]
- **回归**：[Yes/No/Unknown —— 之前是否正常？]

## 环境
- **构建**：[版本或提交哈希]
- **平台**：[操作系统、相关时的硬件]
- **场景/关卡**：[游戏中的位置]
- **游戏状态**：[相关状态 —— 物品栏、任务进度等]

## 复现步骤
**前提条件**：[开始前需要的状态]

1. [确切的步骤 1]
2. [确切的步骤 2]
3. [确切的步骤 3]

**预期结果**：[应该发生什么]
**实际结果**：[实际发生了什么]

## 技术背景
- **可能受影响的文件**：[基于代码库搜索的文件清单]
- **相关系统**：[可能涉及的其它系统]
- **可能的根本原因**：[如果可以从描述中确定]

## 证据
- **日志**：[如有可用的相关日志输出]
- **视觉**：[视觉证据的描述]

## 相关问题
- [相关缺陷或设计文档的链接]

## 备注
[任何额外的背景或观察]
```

The **Severity** and **Priority** labels use `/bug-triage`'s S and P numbers and
names, which it parses out of this file. `P4-Won't fix` is its `P4 — Won't fix /
Deferred` (an accepted risk), not a wishlist. If you change either ladder, change
`.claude/skills/bug-triage/SKILL.md` too.

**严重程度**和**优先级**标签使用 `/bug-triage` 的 S 和 P 编号与名称，后者会从本文件中解析它们。`P4-Won't fix` 对应它的 `P4 — Won't fix / Deferred`（一种已接受的风险），而不是愿望清单。如果你更改了任一级别阶梯，也要同步修改 `.claude/skills/bug-triage/SKILL.md`。

---

## Phase 2B: Analyze Mode

## 阶段 2B：分析模式

1. **Read the target file(s)** specified in the argument.

2. **Identify potential bugs**: null references, off-by-one errors, race conditions, unhandled edge cases, resource leaks, incorrect state transitions.

3. **For each potential bug**, generate a bug report using the template above, with the likely trigger scenario and recommended fix filled in.

1. **读取**参数中指定的**目标文件**。

2. **找出潜在缺陷**：空引用、差一错误、竞态条件、未处理的边界情况、资源泄漏、错误的状态转换。

3. **对每个潜在缺陷**，使用上述模板生成一份缺陷报告，并填入可能的触发场景和建议修复。

---

## Phase 2C: Verify Mode

## 阶段 2C：验证模式

**Find the bug file by its number**, here and in close mode: Glob
`production/qa/bugs/BUG-*.md` and take the file whose number matches `[BUG-ID]`,
whatever its zero-padding — an older three-digit file with a slug is found by
its number too. If none
matches, stop: "No bug [BUG-ID] in `production/qa/bugs/`." Verdict: **BLOCKED**
— no such bug.

**按编号找到缺陷文件**，在此处和关闭模式中都是如此：用 Glob 查找
`production/qa/bugs/BUG-*.md`，取编号与 `[BUG-ID]` 匹配的文件，
无论其补零方式如何 —— 一个带 slug 的更早的三位数文件也能按编号找到。如果都不
匹配，停止："`production/qa/bugs/` 中没有缺陷 [BUG-ID]。" 结论：**BLOCKED**
—— 不存在这样的缺陷。

Read that file. Extract the reproduction steps and expected result.

读取该文件。提取复现步骤和预期结果。

1. **Re-run reproduction steps** — use Grep/Glob to check whether the root cause code path still exists as described. If the fix removed or changed it, note the change.
2. **Run the related test** — if the bug's system has a test file in the engine's test root (`tests/` Godot, `Assets/Tests/` Unity, `Source/<Module>/Private/Tests/` Unreal — `.claude/docs/directory-structure.md`), run it via Bash with `commands.test` from `project.yaml`, narrowed to the affected suite where the runner allows — never a runner line written from memory, which drops the flags the engine needs (gdUnit4 hangs without `--remote-debug tcp://127.0.0.1:0`) — and report pass/fail. `commands.test` unset → no test ran: name the unset key and go on to step 3.
3. **Check for regression** — grep the codebase for any new occurrence of the pattern that caused the bug.
4. **Manual verification** — when no related test ran (none covers the bug — the usual case where `qa.level` waives tests — `commands.test` is unset, or the run did not complete), or the bug's Category is Visual or UI, whose look no automated test checks, ask via `AskUserQuestion`: "Did you play the reproduction steps in [bug file] on a build with the fix? Which build?" —
   `[No longer occurs]` / `[Still occurs]` / `[Not played yet]`.
   Record the answer and the build as the user gives them; a changed code path is never taken as their answer.
   **Run as a subagent?** `qa-lead` preloads this skill, and a subagent has no
   `AskUserQuestion`. End your reply with the question and its three options as
   a short list, and give no verdict yet: whoever called you asks the user, and
   the verdict waits for the answer.

1. **重新运行复现步骤** —— 使用 Grep/Glob 检查根本原因的代码路径是否仍如所述存在。如果修复移除或更改了它，记下该变化。
2. **运行相关测试** —— 如果该缺陷的系统在引擎的测试根目录中有测试文件（Godot 为 `tests/`，Unity 为 `Assets/Tests/`，Unreal 为 `Source/<Module>/Private/Tests/` —— 见 `.claude/docs/directory-structure.md`），通过 Bash 使用 `project.yaml` 中的 `commands.test` 运行它，在运行器允许时缩小到受影响的测试套件 —— 绝不使用凭记忆写的运行器命令行，那会丢掉引擎所需的标志（gdUnit4 在没有 `--remote-debug tcp://127.0.0.1:0` 时会挂起）—— 并报告通过/失败。`commands.test` 未设置 → 没有运行测试：指出未设置的键，然后继续步骤 3。
3. **检查是否回归** —— 在代码库中 grep 查找导致该缺陷的模式是否有任何新的出现。
4. **手动验证** —— 当没有相关的测试运行时（没有测试覆盖该缺陷 —— 在 `qa.level` 豁免测试时是常见情况 —— `commands.test` 未设置，或运行未完成），或该缺陷的类别是 Visual 或 UI、其外观没有自动化测试检查时，通过 `AskUserQuestion` 询问："你在带修复的构建上玩过 [bug file] 中的复现步骤吗？哪个构建？" ——
   `[No longer occurs]` / `[Still occurs]` / `[Not played yet]`。
   按用户提供的原样记录答案和构建；改变的代码路径永远不会被当作他们的答案。
   **作为子智能体运行？** `qa-lead` 预加载本技能，而子智能体没有
   `AskUserQuestion`。用该问题及其三个选项作为简短清单结束你的回复，
   暂时不要给出结论：调用你的人会去问用户，结论等待答案。

Produce a verification verdict:

给出验证结论：

- **VERIFIED FIXED** — the bug is gone by every check that applies: any related test ran and passed, and, where step 4 asked, the user answered `[No longer occurs]` for a named build. With no test run, that play alone is the verification — a manual one, recorded as such: `[user], manual, build [X]`. A changed code path on its own is never a pass
- **STILL PRESENT** — a related test fails on the bug's case, or the user answered `[Still occurs]`; the fix did not resolve the issue
- **CANNOT VERIFY** — step 4 was answered `[Not played yet]`: name what is missing or could not run (no related test, `commands.test` unset, a run that did not complete, a Visual or UI bug), and say that playing the reproduction steps settles it — run `/bug-report verify [BUG-ID]` again once played

- **VERIFIED FIXED**（已验证修复）—— 该缺陷在每一项适用的检查中都消失了：任何相关测试都运行并通过，并且在步骤 4 询问时，用户对某个具名构建回答了 `[No longer occurs]`。若无测试运行，那次游玩本身就是验证 —— 一次手动验证，并如实记录为：`[user], manual, build [X]`。仅凭代码路径发生改变永远不算通过
- **STILL PRESENT**（仍然存在）—— 相关测试在该缺陷的用例上失败，或用户回答了 `[Still occurs]`；修复未解决该问题
- **CANNOT VERIFY**（无法验证）—— 步骤 4 的回答是 `[Not played yet]`：指出缺少什么或什么无法运行（没有相关测试、`commands.test` 未设置、运行未完成、Visual 或 UI 缺陷），并说明游玩复现步骤即可确定 —— 游玩后再次运行 `/bug-report verify [BUG-ID]`

Ask: "May I update `production/qa/bugs/[bug file]` to set Status: Verified Fixed / Still Present / Cannot Verify?" — naming the file found above, whatever its padding or slug. With the Status, write a `**Verified by**:` line under it: `[test file(s)] — ran and passed`, or `[user], manual, build [X]` for a manual verification.

询问："我可以更新 `production/qa/bugs/[bug file]`，把 Status 设为 Verified Fixed / Still Present / Cannot Verify 吗？" —— 点明上面找到的文件，无论其补零或 slug 如何。写入 Status 时，在其下写一行 `**Verified by**:`：`[test file(s)] — ran and passed`，或对手动验证写 `[user], manual, build [X]`。

If STILL PRESENT: reopen the bug, set Status back to Open, and suggest re-running `/hotfix [BUG-ID]`.

如果为 STILL PRESENT：重新打开该缺陷，把 Status 设回 Open，并建议重新运行 `/hotfix [BUG-ID]`。

---

## Phase 2D: Close Mode

## 阶段 2D：关闭模式

Read the bug file, found by its number as in verify mode. Confirm Status is `Verified Fixed` before closing. If status is anything else, stop: "Bug [ID] must be Verified Fixed before it can be closed. Run `/bug-report verify [BUG-ID]` first."

读取该缺陷文件，如验证模式那样按编号找到。在关闭前确认 Status 为 `Verified Fixed`。如果状态是其它任何值，停止："缺陷 [ID] 必须先为 Verified Fixed 才能关闭。请先运行 `/bug-report verify [BUG-ID]`。"

Show the closure record below and the Status change, then ask: "May I update `production/qa/bugs/[bug file]` to mark it Closed?" Nothing is written before a yes; on no, stop — the bug stays Verified Fixed.

展示下面的关闭记录和状态变更，然后询问："我可以更新 `production/qa/bugs/[bug file]` 将其标记为 Closed 吗？" 未经同意不写入任何内容；若不同意，停止 —— 该缺陷保持 Verified Fixed。

On yes, append the closure record to the bug file:

若同意，把关闭记录追加到缺陷文件：

```markdown
## Closure Record
**Closed**: [date]
**Resolution**: Fixed — [one-line description of what was changed]
**Fix commit / PR**: [if known]
**Verified by**: [the verify record's `**Verified by**:` line — the test that ran and passed, or "[user], manual, build [X]"]
**Closed by**: [user]
**Regression test**: [test file path, or "Manual verification" when verify recorded a manual play]
**Status**: Closed
```

```markdown
## 关闭记录
**关闭时间**：[date]
**解决方式**：Fixed —— [对所做更改的一行描述]
**修复提交 / PR**：[if known]
**验证者**：[验证记录中的 `**Verified by**:` 行 —— 运行并通过的测试，或 "[user], manual, build [X]"]
**关闭者**：[user]
**回归测试**：[测试文件路径，或在验证记录为手动游玩时写 "Manual verification"]
**状态**：Closed
```

Then update the top-level `**Status**:` field to `**Status**: Closed`.

然后把顶层的 `**Status**:` 字段更新为 `**Status**: Closed`。

After closing, check `production/qa/bug-triage-*.md` — if the bug appears in an open triage report, note: "Bug [ID] is referenced in the triage report. Run `/bug-triage` to refresh the open bug count."

关闭之后，检查 `production/qa/bug-triage-*.md` —— 如果该缺陷出现在一份未关闭的分诊报告中，注明："缺陷 [ID] 在分诊报告中被引用。运行 `/bug-triage` 刷新未关闭缺陷计数。"

---

## Phase 3: Save Report

## 阶段 3：保存报告

Present the completed bug report(s) to the user.

向用户呈现已完成的缺陷报告。

**Allocate the ID** before asking: Glob `production/qa/bugs/BUG-*.md`, take the
highest number and add 1, zero-padded to four digits (`BUG-0001` when there are
none). Several reports in one run (analyze mode) take consecutive IDs from
there, one each — never the same ID twice.

**在询问之前分配 ID**：用 Glob 查找 `production/qa/bugs/BUG-*.md`，取
最大编号加 1，补零到四位（没有文件时为 `BUG-0001`）。一次运行生成多份报告（分析模式）时从那里开始取连续 ID，每份一个 —— 绝不要两次使用同一个 ID。

Ask: "May I write this to `production/qa/bugs/BUG-[NNNN].md`?" For several
reports, ask once and name every file: "May I write these to
`production/qa/bugs/BUG-[NNNN].md`, `production/qa/bugs/BUG-[NNNN+1].md`, …?"

询问："我可以把它写入 `production/qa/bugs/BUG-[NNNN].md` 吗？" 对于多份
报告，只询问一次并点明每个文件："我可以把这些写入
`production/qa/bugs/BUG-[NNNN].md`、`production/qa/bugs/BUG-[NNNN+1].md`、……吗？"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — bug report filed.

如果同意，写入文件，必要时创建目录。结论：**COMPLETE** —— 缺陷报告已归档。

If no, stop here. Verdict: **BLOCKED** — user declined write.

如果不同意，在此停止。结论：**BLOCKED** —— 用户拒绝写入。

---

## Phase 4: Next Steps

## 阶段 4：后续步骤

After saving, suggest based on mode:

保存后，根据模式给出建议：

**After filing (Description/Analyze mode):**
- Run `/bug-triage` to prioritize alongside existing open bugs
- If S1 or S2: run `/hotfix [BUG-ID]` for emergency fix workflow

**归档后（描述/分析模式）：**
- 运行 `/bug-triage` 与现有未关闭缺陷一起排定优先级
- 如果是 S1 或 S2：运行 `/hotfix [BUG-ID]` 走紧急修复工作流

**After fixing the bug (developer confirms fix is in):**
- Run `/bug-report verify [BUG-ID]` — confirm the fix actually works before closing
- Never mark a bug closed without verification — a fix that doesn't verify is still Open

**修复缺陷后（开发者确认修复已合入）：**
- 运行 `/bug-report verify [BUG-ID]` —— 在关闭前确认修复确实有效
- 永远不要在未验证的情况下把缺陷标记为关闭 —— 一个未通过验证的修复仍然是 Open

**After verify returns CANNOT VERIFY:**
- Play the reproduction steps on a build with the fix, then run `/bug-report verify [BUG-ID]` again and answer its question

**验证返回 CANNOT VERIFY 后：**
- 在带修复的构建上游玩复现步骤，然后再次运行 `/bug-report verify [BUG-ID]` 并回答它的问题

**After verify returns VERIFIED FIXED:**
- Run `/bug-report close [BUG-ID]` — write the closure record and update status
- Run `/bug-triage` to refresh the open bug count and remove it from the active list

**验证返回 VERIFIED FIXED 后：**
- 运行 `/bug-report close [BUG-ID]` —— 写入关闭记录并更新状态
- 运行 `/bug-triage` 刷新未关闭缺陷计数并将其从活动清单中移除
