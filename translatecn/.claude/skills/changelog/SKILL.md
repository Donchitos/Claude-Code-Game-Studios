---
name: changelog
description: "Auto-generate a changelog from git commits and sprint data. Internal and player-facing versions."
argument-hint: "[version|sprint-number]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/changelog/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *), Bash(git tag --list*), Bash(git rev-parse *)
model: sonnet
---

---
name: changelog
description: "从 git 提交和冲刺数据自动生成变更日志。包含内部版和面向玩家版。"
argument-hint: "[version|sprint-number]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/changelog/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *), Bash(git tag --list*), Bash(git rev-parse *)
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

# Changelog

# 变更日志

## Recent History

## 近期历史

Recent commits:

近期提交：

!`git log --oneline -30 2>/dev/null || true`

Recent tags (newest first):

近期标签（最新在前）：

!`git tag --list --sort=-v:refname 2>/dev/null | head -5`

## Provenance check — before trusting the history above

## 来源检查 —— 在信任上面的历史之前

**The commits above may not belong to this game.** This skill's history blocks are
auto-resolved *before* the body runs, so the read has already happened — what this
check governs is whether that output is usable, not whether it is fetched.

**上面的提交可能并不属于这款游戏。** 本技能的历史块是在正文运行*之前*自动解析的，
所以读取已经发生 —— 这项检查所管的是该输出是否可用，而不是它是否已被获取。

1. Read the injected commit subjects above. **If there are none — the log is
   empty or git is unavailable — skip this check**: there is nothing to
   classify, and Phase 1's no-history branch is the right stop.
2. **Classify each one** as **Game** (mechanics, content, balance, art, audio,
   UI, or a bug in those), **Framework / maintenance** (subjects naming skills,
   hooks, agents, the test plan, CI, or the framework's own docs), or **Unclear**
   — and treat Unclear as Framework.
3. Decide from the counts:
   - **At least one Game commit** → proceed using only those, and state how many
     of how many you used.
   - **Zero Game commits** → stop, using the message below.

1. 读取上面注入的提交主题。**如果没有 —— 日志为空或 git 不可用 —— 跳过此检查**：没有
   可分类的内容，阶段 1 的无历史分支就是正确的停止点。
2. **对每一个进行分类**为 **Game**（机制、内容、平衡、美术、音频、
   UI，或这些方面的缺陷）、**Framework / maintenance**（主题中提及技能、
   钩子、智能体、测试计划、CI 或框架自带文档），或 **Unclear**
   —— 并将 Unclear 视为 Framework。
3. 根据计数决定：
   - **至少有一个 Game 提交** → 只使用这些继续，并说明你使用了多少个（共多少个）。
   - **零个 Game 提交** → 停止，使用下面的消息。

> **Filter per commit; a repo containing maintenance work is not a wrong repo.**
> Every project on this framework accumulates commits touching hooks, CI and
> skills — the game repo *is* the framework repo, so stopping on them would fire
> on virtually every real project. The harm is those commits becoming release copy,
> and excluding them prevents that precisely.
>
> This rule is kept identical to `/patch-notes`' on purpose — the two read the
> same history for different audiences, and they must not disagree about whose
> history it is. Change both together.

> **按提交逐个过滤；一个包含维护工作的仓库并不是错误的仓库。**
> 这个框架上的每个项目都会积累涉及钩子、CI 和
> 技能的提交 —— 游戏仓库*就是*框架仓库，因此因它们而停止几乎会在每个真实项目上触发。
> 危害在于那些提交变成发布文案，而排除它们正好防止这一点。
>
> 这条规则刻意与 `/patch-notes` 保持完全一致 —— 两者为不同受众读取
> 同一份历史，它们不可以在"这是谁的历史"上产生分歧。要改就一起改。

The genuine wrong-history signal is different: Game commits naming a product that
`design/` and the code root (`src/`, `Assets/` or `Source/`) never mention. If you
see that, stop.

真正的错误历史信号是不同的：Game 提交提及一个 `design/` 和代码根
（`src/`、`Assets/` 或 `Source/`）从未提及的产品。如果你
看到这种情况，停止。

If **no** commit in the range is this game's, say so and stop:

如果范围内**没有**任何提交属于这款游戏，说明这一点并停止：

> "The git history in this repo does not appear to belong to [game]: 0 of the [N]
> recent commits are Game commits. The recent
> commits describe [what they actually describe]. I cannot generate a changelog
> from it — point me at the right history, or supply the change list directly."

> "此仓库中的 git 历史看起来并不属于 [game]：最近的 [N] 个提交中有 0 个是 Game 提交。
> 最近的提交描述的是 [它们实际描述的内容]。我无法据此生成变更日志 —— 请把我指向正确的历史，
> 或直接提供变更清单。"

Verdict: **BLOCKED** — stop here without generating a changelog.

结论：**BLOCKED** —— 在此停止，不生成变更日志。

**Why this is a hard stop, not a warning.** Framework-internal commits rendered
as player copy read as real changes: a session-hook timeout becomes *"Fixed an
issue where progress from your last session could be lost on launch"* in a game
with **no save system**. That copy is fluent, plausible, and entirely false. A
reader cannot tell the difference; only this check can.

**为什么这是硬性停止，而不是警告。** 把框架内部的提交渲染成玩家文案会被读成真实变更：一次会话钩子超时
会变成 *"修复了上次会话的进度可能在启动时丢失的问题"*，而这款游戏**没有存档系统**。
那段文案流畅、可信，而且完全错误。读者无法分辨差别；只有这项检查可以。

**Do not treat the preamble's existence as evidence.** Injected output means the
command ran, never that its subject is your game.

**不要把前导代码的存在当作证据。** 注入的输出只意味着命令运行了，绝不意味着它的主题是你的游戏。

---

Both blocks are resolved before this skill runs. Use them as the starting point
for Phase 2 rather than re-running the same commands.

两个块都在本技能运行之前解析完成。把它们作为阶段 2 的起点，
而不是重新运行相同的命令。

---

## Phase 1: Parse Arguments

## 阶段 1：解析参数

Read the argument for the target version or sprint number. If a version is given, use the corresponding git tag. If a sprint number is given, use the sprint date range.

读取参数以获取目标版本或冲刺编号。如果给出的是版本，使用对应的 git 标签。如果给出的是冲刺编号，使用该冲刺的日期范围。

Verify the repository is initialized: run `git rev-parse --is-inside-work-tree` to confirm git is available. If not a git repo, inform the user and abort gracefully.

校验仓库已初始化：运行 `git rev-parse --is-inside-work-tree` 确认 git 可用。如果不是 git 仓库，告知用户并优雅中止。

**If there is no history to read** — not a git repository, or no commits yet:

**如果没有可读取的历史** —— 不是 git 仓库，或还没有提交：

> "No git history found. A changelog is built from commits — commit the work
> first, or supply the change list directly."

> "未找到 git 历史。变更日志是基于提交构建的 —— 请先提交工作，
> 或直接提供变更清单。"

Verdict: **BLOCKED** — stop here without generating a changelog.

结论：**BLOCKED** —— 在此停止，不生成变更日志。

---

## Phase 2: Gather Change Data

## 阶段 2：收集变更数据

Read the git log since the last tag or release:

读取自上一个标签或发布以来的 git 日志：

```
git log --oneline [last-tag]..HEAD
```

```
git log --oneline [last-tag]..HEAD
```

If no tags exist, bound the range explicitly — `git log --oneline -n 100`. Do not
fall back to the full log: on an established repo that is thousands of lines for
a changelog covering one release, and the oldest of them are the least relevant.
If 100 commits does not reach far enough back, say so and ask for a start ref
rather than widening blindly.

如果没有标签存在，明确限定范围 —— `git log --oneline -n 100`。不要
回退到完整日志：在一个成熟仓库中，那将是数千行，而这份变更日志只覆盖一个发布，
其中最旧的提交相关性最低。如果 100 个提交追溯得不够远，请说明并询问起始引用，
而不是盲目扩大范围。

Read sprint reports from `production/sprints/` for the relevant period to understand planned work and context behind changes.

从 `production/sprints/` 读取相关时期的冲刺报告，以了解计划的工作和变更背后的背景。

Read completed design documents from `design/gdd/` for any new features implemented during this period. Read them by section: find the headings you need with the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and limit.

从 `design/gdd/` 读取此期间实现的任何新功能的已完成设计文档。按小节读取：用 Grep 工具（模式 `^#`，内容模式）找到需要的标题，然后用 offset 和 limit 读取相应范围。

---

## Phase 3: Categorize Changes

## 阶段 3：归类变更

Categorize every change into one of these categories:

把每项变更归入以下类别之一：

- **New Features**: Entirely new gameplay systems, modes, or content
- **Improvements**: Enhancements to existing features, UX improvements, performance gains
- **Bug Fixes**: Corrections to broken behavior
- **Balance Changes**: Tuning of gameplay values, difficulty, economy
- **Technical Debt / Refactoring**: Refactors and cleanup of the game's code that change nothing the player sees — a commit that says it refactors, cleans up or tidies, and names no fix, feature or tuning. Internal changelog only; never in the player-facing one
- **Known Issues**: Issues the team is aware of but have not yet resolved
- **Miscellaneous**: Changes that do not fit the above categories, or commits whose messages are too vague to classify confidently

- **新功能**：全新的玩法系统、模式或内容
- **改进**：对现有功能的增强、UX 改进、性能提升
- **缺陷修复**：对损坏行为的修正
- **平衡变更**：对玩法数值、难度、经济的调整
- **技术债务 / 重构**：对游戏代码的重构和清理，不改变玩家看到的任何东西 —— 一个声称重构、清理或整理，且未指明任何修复、功能或调参的提交。仅限内部变更日志；绝不能出现在面向玩家的那一份中
- **已知问题**：团队已知但尚未解决的问题
- **杂项**：不符合上述类别的变更，或消息过于含糊而无法有把握地归类的提交

For each commit, check whether the message contains a task ID or story reference
(e.g. `[STORY-123]`, `TR-`, `#NNN`, or similar). Count commits that lack any task reference
and include this count in the Phase 4 Metrics section as: `Commits without task reference: [N]`.

对每个提交，检查其消息是否包含任务 ID 或故事引用
（例如 `[STORY-123]`、`TR-`、`#NNN` 或类似形式）。统计缺少任何任务引用的提交数，
并在阶段 4 的指标部分以如下形式纳入该计数：`Commits without task reference: [N]`。

---

## Phase 4: Generate Internal Changelog

## 阶段 4：生成内部变更日志

```markdown
# Internal Changelog: [Version]
Date: [Date]
Sprint(s): [Sprint numbers covered]
Commits: [Count] ([first-hash]..[last-hash])

## New Features
- [Feature Name] -- [Technical description, affected systems]
  - Commits: [hash1], [hash2]
  - Owner: [who implemented it]
  - Design doc: [link if applicable]

## Improvements
- [Improvement] -- [What changed technically and why]
  - Commits: [hashes]
  - Owner: [who]

## Bug Fixes
- [BUG-ID] [Description of bug and root cause]
  - Fix: [What was changed]
  - Commits: [hashes]
  - Owner: [who]

## Balance Changes
- [What was tuned] -- [Old value -> New value] -- [Design intent]
  - Owner: [who]

## Technical Debt / Refactoring
- [What was cleaned up and why]
  - Commits: [hashes]

## Miscellaneous
- [Change that didn't fit other categories, or vague commit message]
  - Commits: [hashes]

## Known Issues
- [Issue description] -- [Severity] -- [ETA for fix if known]

## Metrics
- Total commits: [N]
- Files changed: [N]
- Lines added: [N]
- Lines removed: [N]
- Commits without task reference: [N]
```

```markdown
# 内部变更日志：[Version]
日期：[Date]
冲刺：[Sprint numbers covered]
提交数：[Count]（[first-hash]..[last-hash]）

## 新功能
- [Feature Name] —— [技术描述、受影响的系统]
  - 提交：[hash1]、[hash2]
  - 负责人：[who implemented it]
  - 设计文档：[link if applicable]

## 改进
- [Improvement] —— [技术上改了什么以及为什么]
  - 提交：[hashes]
  - 负责人：[who]

## 缺陷修复
- [BUG-ID] [缺陷描述和根本原因]
  - 修复：[What was changed]
  - 提交：[hashes]
  - 负责人：[who]

## 平衡变更
- [What was tuned] —— [Old value -> New value] —— [Design intent]
  - 负责人：[who]

## 技术债务 / 重构
- [清理了什么以及为什么]
  - 提交：[hashes]

## 杂项
- [不符合其他类别的变更，或含糊的提交消息]
  - 提交：[hashes]

## 已知问题
- [Issue description] —— [Severity] —— [ETA for fix if known]

## 指标
- 总提交数：[N]
- 更改的文件数：[N]
- 新增行数：[N]
- 删除行数：[N]
- 无任务引用的提交数：[N]
```

---

## Phase 5: Generate Player-Facing Changelog

## 阶段 5：生成面向玩家的变更日志

```markdown
# What is New in [Version]

## New Features
- **[Feature Name]**: [Player-friendly description of what they can now do
  and why it is exciting. Focus on the experience, not the implementation.]

## Improvements
- **[What improved]**: [How this makes the game better for the player.
  Be specific but avoid jargon.]

## Bug Fixes
- Fixed an issue where [describe what the player experienced, not what was
  wrong in the code]
- Fixed [player-visible symptom]

## Balance Changes
- [What changed in player-understandable terms and the design intent.
  Example: "Healing potions now restore 50 HP (up from 30) -- we felt
  players needed more recovery options in late-game encounters."]

## Known Issues
- We are aware of [issue description in player terms] and are working on a
  fix. [Workaround if one exists.]

---
Thank you for playing! Your feedback helps us make the game better.
Report issues at [link].
```

```markdown
# [Version] 中的新内容

## 新功能
- **[Feature Name]**：[对玩家现在能做什么、以及为什么这令人兴奋的
  面向玩家的描述。聚焦体验，而不是实现。]

## 改进
- **[What improved]**：[这如何让游戏对玩家更好。
  要具体，但避免术语。]

## 缺陷修复
- 修复了一个问题，其中 [描述玩家经历的情况，而不是代码中
  出错的地方]
- 修复了 [player-visible symptom]

## 平衡变更
- [用玩家能理解的方式说明改了什么以及设计意图。
  示例："治疗药水现在恢复 50 点生命（从 30 提升）—— 我们觉得
  玩家在后期遭遇战中需要更多恢复手段。"]

## 已知问题
- 我们已注意到 [用玩家语言描述的问题]，正在着手
  修复。[如果存在变通方法，请注明。]

---
感谢游玩！你的反馈帮助我们让游戏变得更好。
在 [link] 报告问题。
```

---

## Phase 6: Output

## 阶段 6：输出

Output both changelogs to the user. The internal changelog is the primary working document. The player-facing changelog is ready for community posting after review.

向用户输出两份变更日志。内部变更日志是主要的工作文档。面向玩家的变更日志经评审后即可用于社区发布。

---

## Phase 7: Offer File Write

## 阶段 7：提议写入文件

After presenting the changelogs, ask the user:

在呈现变更日志之后，询问用户：

> "May I write this changelog to `docs/CHANGELOG.md`?
> [A] Yes, append this entry (recommended if the file already exists)
> [B] Yes, overwrite the file entirely
> [C] No — I'll copy it manually"

> "我可以把这份变更日志写入 `docs/CHANGELOG.md` 吗？
> [A] 是，追加此条目（如果文件已存在则推荐）
> [B] 是，完全覆盖该文件
> [C] 否 —— 我会手动复制"

- Check whether `docs/CHANGELOG.md` exists before asking. If it does, default the
  recommendation to **[A] append**.
- If the user selects [A]: append the new internal changelog entry to the top of
  the existing file (newest entries first).
- If the user selects [B]: overwrite the file with the new changelog.
- If the user selects [C]: stop here without writing.

- 在询问之前检查 `docs/CHANGELOG.md` 是否存在。如果存在，把推荐默认设为 **[A] 追加**。
- 如果用户选择 [A]：把新的内部变更日志条目追加到现有文件的顶部
  （最新条目在前）。
- 如果用户选择 [B]：用新的变更日志覆盖该文件。
- 如果用户选择 [C]：在此停止，不写入。

After a successful write: Verdict: **CHANGELOG WRITTEN** — changelog saved to `docs/CHANGELOG.md`.
If the user declines: Verdict: **COMPLETE** — changelog generated.

成功写入后：结论：**CHANGELOG WRITTEN** —— 变更日志已保存到 `docs/CHANGELOG.md`。
如果用户拒绝：结论：**COMPLETE** —— 变更日志已生成。

---

## Phase 7: Next Steps

## 阶段 7：后续步骤

- Use `/patch-notes [version]` to generate a styled, saved version for public release.
- Use `/release-checklist` before publishing the changelog externally.

- 使用 `/patch-notes [version]` 为公开发布生成一个带样式、已保存的版本。
- 在对外发布变更日志之前使用 `/release-checklist`。

### Guidelines

### 指南

- Never expose internal code references, file paths, or developer names in the player-facing changelog
- Group related changes together rather than listing individual commits
- If a commit message is unclear, check the associated files and sprint data for context
- Balance changes should always include the design reasoning, not just the numbers
- Known issues should be honest — players appreciate transparency
- If the git history is messy (merge commits, reverts, fixup commits), clean up the narrative rather than listing every commit literally

- 绝不要在面向玩家的变更日志中暴露内部代码引用、文件路径或开发者姓名
- 将相关变更归为一组，而不是逐条列出各个提交
- 如果提交消息不清楚，检查相关文件和冲刺数据以获取上下文
- 平衡变更应始终包含设计理由，而不仅仅是数字
- 已知问题应诚实 —— 玩家欣赏透明度
- 如果 git 历史凌乱（合并提交、回滚、fixup 提交），整理叙事，而不是逐字列出每个提交
