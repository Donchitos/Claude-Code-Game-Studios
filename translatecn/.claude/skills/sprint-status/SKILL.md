---
name: sprint-status
description: "Fast, concise sprint snapshot — burndown and emerging risks for situational awareness. 'How is the sprint going?'"
argument-hint: "[sprint-number or blank for current]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash "*/.claude/skills/sprint-status/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash "*/.claude/skills/sprint-status/../../scripts/story-status.sh"), Bash(bash .claude/scripts/story-status.sh*)
model: haiku
---
---
name: sprint-status
description: "快速、简洁的冲刺快照 — 燃尽情况与新兴风险，用于态势感知。'冲刺进展如何？'"
argument-hint: "[sprint-number or blank for current]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash "*/.claude/skills/sprint-status/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash "*/.claude/skills/sprint-status/../../scripts/story-status.sh"), Bash(bash .claude/scripts/story-status.sh*)
model: haiku
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys story_granularity,workflow`



# Sprint Status

This is a fast situational awareness check, not a sprint review. It reads the
current sprint plan and story files, scans for status markers, and produces a
concise snapshot in under 30 lines. For detailed sprint management, use
`/sprint-plan update` or `/milestone-review`.

# 冲刺状态

这是一次快速态势感知检查，而不是冲刺评审。它读取
当前冲刺计划和故事文件，扫描状态标记，并生成
不超过 30 行的简洁快照。详细冲刺管理请使用
`/sprint-plan update` 或 `/milestone-review`。

**This skill is read-only.** It never proposes changes, never asks to write
files, and makes at most one concrete recommendation.

**此技能只读。** 它从不提议变更，从不请求写入
文件，最多给出一个具体建议。

**`story_granularity`** — it sets the
grain of the burn-down read: **feature-sized** chunks at `coarse` (the default, via `rigor: minimal`), **task-sized**
at `balanced` (`rigor: standard`), **AC-sized** at `fine`.

**`story_granularity`** — 它设定
燃尽读取的粒度：`coarse`（默认，经 `rigor: minimal`）下为**功能大小**的块，
`balanced`（`rigor: standard`）下为**任务大小**，`fine` 下为**验收标准大小**。

---

## 1. Find the Sprint

**Argument:** `$ARGUMENTS` (blank = use current sprint)

- If an argument is given (e.g., `/sprint-status 3`), search
  `production/sprints/` for a file matching `sprint-003.md`, `sprint-03.md`, `sprint-3.md`,
  or similar (`/sprint-plan` writes three digits). Report which file was found.
- If no argument is given, find the most recently modified file in
  `production/sprints/` and treat it as the current sprint.
- If `production/sprints/` does not exist or is empty:
  - **At `workflow: minimal` there are no sprints by design** — the brief's
    build order is the plan and the story files carry it. Report progress
    through it instead, then stop:

## 1. 查找冲刺

**参数：** `$ARGUMENTS`（为空 = 使用当前冲刺）

- 如果给出了参数（例如 `/sprint-status 3`），在
  `production/sprints/` 中搜索匹配 `sprint-003.md`、`sprint-03.md`、`sprint-3.md`
  或类似名称的文件（`/sprint-plan` 写入三位数字）。报告找到了哪个文件。
- 如果未给出参数，找到 `production/sprints/` 中最近修改的文件
  并将其视为当前冲刺。
- 如果 `production/sprints/` 不存在或为空：
  - **在 `workflow: minimal` 下按设计没有冲刺** — 简报的
    构建顺序就是计划，故事文件承载它。改为通过它报告进度，
    然后停止：

    1. The list below was printed by `.claude/scripts/story-status.sh`
       before you read this skill: one line per unfinished story, already in
       the route's order (`IN_REVIEW`, `IN_PROGRESS`, then `TODO` — a `Ready`
       or `Not Started` story — in build order), then `BLOCKED`, `OTHER`,
       `NO_STATUS` and the `COMPLETE` count:

    1. 下面的列表在你读取此技能之前已由 `.claude/scripts/story-status.sh`
       打印：每个未完成故事一行，已按
       路由顺序（`IN_REVIEW`、`IN_PROGRESS`，然后 `TODO` — 即 `Ready`
       或 `Not Started` 的故事 — 按构建顺序），接着是 `BLOCKED`、`OTHER`、
       `NO_STATUS` 以及 `COMPLETE` 计数：

!`bash "${CLAUDE_SKILL_DIR}/../../scripts/story-status.sh"`

    2. Print, in under 15 lines: `Build order: [N] of [M] stories complete`
       from the `COMPLETE` line (count only `Complete` and `Done` stories —
       `In Review` is not complete), then **Next**: the story on the first
       `IN_REVIEW`, `IN_PROGRESS` or `TODO` line. The list is already
       current; do not run the script again, and do not re-rank the story files — an `In Review` story is closed before an
       `In Progress` one continues: its work is written. Recommend
       `/story-done [path]` for `IN_REVIEW`, `/dev-story [path]` for
       `IN_PROGRESS` or `TODO`. Name any `BLOCKED` story with its blocker; it is
       never Next.

    2. 在 15 行以内打印：从 `COMPLETE` 行得出 `Build order: [N] of [M] stories complete`
       （只计 `Complete` 和 `Done` 的故事 —
       `In Review` 不算完成），然后是 **Next**：位于第一条
       `IN_REVIEW`、`IN_PROGRESS` 或 `TODO` 行上的故事。列表已经是
       最新的；不要再运行脚本，也不要重新排列故事文件 — 一个 `In Review` 故事会先于
       一个 `In Progress` 故事继续之前被关闭：它的工作已经写完。建议
       `IN_REVIEW` 用 `/story-done [path]`，`IN_PROGRESS` 或 `TODO` 用
       `/dev-story [path]`。点名任何 `BLOCKED` 故事及其阻断原因；它
       永远不会是 Next。

    3. Every story `Complete` (or `Done`) → "Build order done: [M] of [M]
       stories complete." Offer three ways on: play the build; add the next
       stories from the brief with `/create-stories`; or `/settings` to raise
       `modes.rigor` if the game has outgrown a one-page brief.

    3. 每个故事都 `Complete`（或 `Done`）→ "Build order done: [M] of [M]
       stories complete." 给出三种后续选择：游玩构建；用 `/create-stories` 从简报
       添加下一个故事；或用 `/settings` 提升
       `modes.rigor`，如果游戏已超出一页简报的规模。

    4. `STORIES none` — no story files at all → "No stories yet. Run
       `/create-stories` to turn the brief's build order into stories."

    4. `STORIES none` — 完全没有故事文件 → "No stories yet. Run
       `/create-stories` to turn the brief's build order into stories."

    5. No `IN_REVIEW`, `IN_PROGRESS` or `TODO` line, yet the `COMPLETE` line
       is short of the total — every unfinished story is `BLOCKED`, `OTHER`
       (such as `Draft`) or `NO_STATUS`. There is **no Next**, and the build
       order is **not** done: never say it is. Print the `Build order` line,
       then name each `BLOCKED` story with its blocker — read from its story
       file, usually a `BLOCKED:` note — and each other story with its status
       as written. Recommend one step: what the first blocker needs, or else
       finishing the first `Draft` or unstatused story and setting its Status
       to `Ready`.

    5. 没有 `IN_REVIEW`、`IN_PROGRESS` 或 `TODO` 行，但 `COMPLETE` 行
       少于总数 — 每个未完成故事都是 `BLOCKED`、`OTHER`
       （例如 `Draft`）或 `NO_STATUS`。**没有 Next**，构建
       顺序**并未**完成：绝不要说它完成了。打印 `Build order` 行，
       然后点名每个 `BLOCKED` 故事及其阻断原因 — 从它的故事
       文件中读取，通常是一条 `BLOCKED:` 注记 — 以及其他每个故事按其书写的状态
       点名。建议一个步骤：第一个阻断需要什么，或者
       否则完成第一个 `Draft` 或无状态的故事并将其 Status
       设为 `Ready`。

  - **At `standard` or `full`**, report: "No sprint files found. Start a sprint
    with `/sprint-plan new`." Then stop.

  - **在 `standard` 或 `full` 下**，报告："No sprint files found. Start a sprint
    with `/sprint-plan new`." 然后停止。

Read the sprint file in full. Extract:
- Sprint number and goal
- Start date and end date
- All story or task entries with their priority (Must Have / Should Have /
  Nice to Have), owner, and estimate

完整读取冲刺文件。提取：
- 冲刺编号与目标
- 开始日期与结束日期
- 所有故事或任务条目及其优先级（Must Have / Should Have /
  Nice to Have）、负责人和估算

---

## 2. Calculate Days Remaining

Using today's date and the sprint end date from the sprint file, calculate:
- Total sprint days (end minus start)
- Days elapsed
- Days remaining
- Percentage of time consumed

If the sprint file does not include explicit dates, note "Sprint dates not
found — burndown assessment skipped."

## 2. 计算剩余天数

使用今天的日期和冲刺文件中的冲刺结束日期，计算：
- 冲刺总天数（结束减开始）
- 已过天数
- 剩余天数
- 已消耗时间百分比

如果冲刺文件不包含明确日期，注明 "Sprint dates not
found — burndown assessment skipped."

---

## 3. Scan Story Status

**First: check for `production/sprint-status.yaml`.**

If it exists, read it directly — it is the authoritative source of truth.
Extract each story's `status`, and its `priority`, `owner` and `blocker` when set — they fill the status table's columns. No markdown scanning needed.
Use its `sprint`, `goal`, `start`, `end` fields instead of re-parsing the sprint plan.

## 3. 扫描故事状态

**首先：检查 `production/sprint-status.yaml`。**

如果存在，直接读取它 — 它是权威事实来源。
提取每个故事的 `status`，以及设置时的 `priority`、`owner` 与 `blocker` — 它们填充状态表的列。无需 markdown 扫描。
使用其 `sprint`、`goal`、`start`、`end` 字段，而不是重新解析冲刺计划。

**If `sprint-status.yaml` does not exist** (legacy sprint or first-time setup),
fall back to markdown scanning:

1. If the entry references a story file path, check if the file exists.
   Read the file and scan for status markers: DONE, COMPLETE, IN PROGRESS,
   BLOCKED, NOT STARTED (case-insensitive).
2. If the entry has no file path (inline task in the sprint plan), scan the
   sprint plan itself for status markers next to that entry.
3. If no status marker is found, classify as NOT STARTED.
4. If a file is referenced but does not exist, classify as MISSING and note it.

**如果 `sprint-status.yaml` 不存在**（旧式冲刺或首次设置），
回退到 markdown 扫描：

1. 如果条目引用了故事文件路径，检查该文件是否存在。
   读取该文件并扫描状态标记：DONE、COMPLETE、IN PROGRESS、
   BLOCKED、NOT STARTED（不区分大小写）。
2. 如果条目没有文件路径（冲刺计划中的内联任务），扫描
   冲刺计划本身，查找该条目旁的状态标记。
3. 如果未找到状态标记，归类为 NOT STARTED。
4. 如果引用了文件但不存在，归类为 MISSING 并记录。

When using the fallback, add a note at the bottom of the output:
"⚠ No `sprint-status.yaml` found — status inferred from markdown. Run `/sprint-plan update` to generate one."

使用回退方案时，在输出底部添加一条注记：
"⚠ No `sprint-status.yaml` found — status inferred from markdown. Run `/sprint-plan update` to generate one."

Optionally (fast check only — do not do a deep scan): grep the code root for a
directory or file name that matches the story's system slug to check for
implementation evidence. This is a hint only, not a definitive status.

可选（仅快速检查 — 不要做深度扫描）：在代码根中 grep 匹配
故事系统 slug 的目录或文件名，以检查
实现证据。这仅是提示，不是确定性的状态。

### Stale Story Detection

After collecting status for all stories, check each IN PROGRESS story for staleness:

### 陈旧故事检测

在收集所有故事的状态后，检查每个 IN PROGRESS 故事是否陈旧：

- Resolve the dates with **one grep across the story set, not a read per story**
  — a date is a single line, and opening every in-progress story to find it is
  the whole cost of this check:
  ```
  Grep pattern="\*{0,2}(Last Updated|Updated|last-updated|updated_at)\*{0,2}[[:space:]]*:" glob="production/epics/**/story-*.md" output_mode="content"
  ```
  That one pattern accepts every field-name variant. A story with no match has
  **no date**, which is not the same as being stale — report it as "never
  stamped" and do not compute an age for it.

- 用**跨故事集的一次 grep，而不是逐个故事读取**来确定日期
  — 日期只有一行，而为了找到它打开每个进行中的故事
  就是这项检查的全部成本：
  ```
  Grep pattern="\*{0,2}(Last Updated|Updated|last-updated|updated_at)\*{0,2}[[:space:]]*:" glob="production/epics/**/story-*.md" output_mode="content"
  ```
  这一个模式接受所有字段名变体。没有匹配的故事
  **没有日期**，这与陈旧不同 — 将其报告为"从未
  打戳"，并且不要为它计算天数。

> **The `\*{0,2}` wrappers are why this works at all.** `/create-stories` emits
> `> **Last Updated**: …`, so a pattern requiring `:` immediately after the word
> matches no story. Combined with the "no match = never stamped" rule directly
> above, that failure is silent: every in-progress story reports as never
> stamped and stale-story detection never fires. Do not use a bare `Updated:`
> anchor.

> **`\*{0,2}` 包装正是这能起作用的原因。** `/create-stories` 输出
> `> **Last Updated**: …`，因此一个要求单词后紧跟 `:` 的模式
> 匹配不到任何故事。结合正上方的"无匹配 = 从未打戳"规则，
> 那种失败是无声的：每个进行中的故事都报告为从未
> 打戳，陈旧故事检测永远不会触发。不要使用裸的 `Updated:`
> 锚点。

- Calculate days since that date using today's date.
- If the date is more than 4 days ago, flag the story as **STALE**. (4-day threshold accounts for weekends — a story last touched on Friday won't appear stale until Wednesday.)
- If no date field is found in the story file, note "no timestamp — cannot check staleness."
- If the story has no referenced file (inline task), note "inline task — cannot check staleness."

- 使用今天的日期计算自该日期以来的天数。
- 如果该日期在 4 天以前，将故事标记为 **STALE**。（4 天阈值考虑了周末 — 一个最后在周五触碰的故事要到周三才会显得陈旧。）
- 如果在故事文件中未找到日期字段，注明 "no timestamp — cannot check staleness."
- 如果故事没有引用的文件（内联任务），注明 "inline task — cannot check staleness."

STALE stories are included in the output table and collected into an "Attention Needed"
section (see Phase 5 output format).

STALE 故事会包含在输出表中，并汇总到 "Attention Needed"
小节（见阶段 5 输出格式）。

**Stale story escalation**: If any IN PROGRESS story is flagged STALE (no progress in 4+ days), the burndown verdict
is upgraded to at least **At Risk** — even if the completion percentage is within the normal
On Track window. Record this escalation reason: "At Risk — [S] stale story(ies): [title]
([D] days)[, …]" — [S] is how many stories are STALE, and each is named with its own [D],
the days since its own Last Updated date (not the oldest age, not an average).

**陈旧故事升级**：如果任何 IN PROGRESS 故事被标记为 STALE（4+ 天无进展），燃尽判定
至少升级为 **At Risk** — 即使完成百分比在正常的
On Track 窗口内。记录此升级理由："At Risk — [S] stale story(ies): [title]
([D] days)[, …]" — [S] 是 STALE 故事的数量，每个都带上自己的 [D]，
即自其自身 Last Updated 日期以来的天数（不是最老的天数，也不是平均值）。

---

## 4. Burndown Assessment

Calculate:
- Tasks complete (DONE or COMPLETE)
- Tasks in progress (IN PROGRESS)
- Tasks blocked (BLOCKED)
- Tasks not started (NOT STARTED or MISSING)
- Completion percentage: (complete / total) * 100

## 4. 燃尽评估

计算：
- 已完成任务（DONE 或 COMPLETE）
- 进行中任务（IN PROGRESS）
- 被阻断任务（BLOCKED）
- 未开始任务（NOT STARTED 或 MISSING）
- 完成百分比：(complete / total) * 100

Assess burndown by comparing completion percentage to time consumed percentage:

- **On Track**: completion % is within 10 points of time consumed % or ahead
- **At Risk**: completion % is 10-25 points behind time consumed %
- **Behind**: completion % is more than 25 points behind time consumed %

通过比较完成百分比与已消耗时间百分比来评估燃尽：

- **On Track**：完成百分比与已消耗时间百分比相差在 10 个百分点以内或领先
- **At Risk**：完成百分比落后已消耗时间百分比 10-25 个百分点
- **Behind**：完成百分比落后已消耗时间百分比超过 25 个百分点

If dates are unavailable, skip the burndown assessment and report "On Track /
At Risk / Behind: unknown — sprint dates not found."

如果日期不可用，跳过燃尽评估并报告 "On Track /
At Risk / Behind: unknown — sprint dates not found."

---

## 5. Output

Keep the output concise. The story status table is mandatory — do not truncate it. Aim for under 50 lines total; omit the Emerging Risks section if nothing notable was found. Use this format:

## 5. 输出

保持输出简洁。故事状态表是必需的 — 不要截断它。目标总行数不超过 50 行；如果没有发现值得注意的内容，省略新兴风险小节。使用以下格式：

```markdown
## Sprint [N] Status — [Today's Date]
**Sprint Goal**: [from sprint plan]
**Days Remaining**: [N] of [total] ([% time consumed])

### Progress: [complete/total] tasks ([%])

| Story / Task         | Priority   | Status      | Owner   | Blocker        |
|----------------------|------------|-------------|---------|----------------|
| [title]              | Must Have  | DONE        | [owner] |                |
| [title]              | Must Have  | IN PROGRESS | [owner] |                |
| [title]              | Must Have  | BLOCKED     | [owner] | [brief reason] |
| [title]              | Should Have| NOT STARTED | [owner] |                |

### Attention Needed
| Story / Task         | Status      | Last Updated   | Days Stale | Note           |
|----------------------|-------------|----------------|------------|----------------|
| [title]              | IN PROGRESS | [date or N/A]  | [N days]   | [STALE / no timestamp — cannot check staleness / inline task — cannot check staleness] |

*(Omit this section entirely if no IN PROGRESS stories are stale or have timestamp concerns.)*

### Burndown: [On Track / At Risk / Behind]
[1-2 sentences. If behind: which Must Haves are at risk. If on track: confirm
and note any Should Haves the team could pull.]

### Must-Haves at Risk
[List any Must Have stories that are BLOCKED or NOT STARTED with less than
40% of sprint time remaining. If none, write "None."]

### Emerging Risks
[Any risks visible from the story scan: missing files, cascading blockers,
stories with no owner. If none, write "None identified."]

### Recommendation
[One concrete action, or "Sprint is on track — no action needed."]
```

```markdown
## Sprint [N] Status — [Today's Date]
**Sprint Goal**: [from sprint plan]
**Days Remaining**: [N] of [total] ([% time consumed])

### Progress: [complete/total] tasks ([%])

| Story / Task         | Priority   | Status      | Owner   | Blocker        |
|----------------------|------------|-------------|---------|----------------|
| [title]              | Must Have  | DONE        | [owner] |                |
| [title]              | Must Have  | IN PROGRESS | [owner] |                |
| [title]              | Must Have  | BLOCKED     | [owner] | [brief reason] |
| [title]              | Should Have| NOT STARTED | [owner] |                |

### Attention Needed
| Story / Task         | Status      | Last Updated   | Days Stale | Note           |
|----------------------|-------------|----------------|------------|----------------|
| [title]              | IN PROGRESS | [date or N/A]  | [N days]   | [STALE / no timestamp — cannot check staleness / inline task — cannot check staleness] |

*(Omit this section entirely if no IN PROGRESS stories are stale or have timestamp concerns.)*

### Burndown: [On Track / At Risk / Behind]
[1-2 sentences. If behind: which Must Haves are at risk. If on track: confirm
and note any Should Haves the team could pull.]

### Must-Haves at Risk
[List any Must Have stories that are BLOCKED or NOT STARTED with less than
40% of sprint time remaining. If none, write "None."]

### Emerging Risks
[Any risks visible from the story scan: missing files, cascading blockers,
stories with no owner. If none, write "None identified."]

### Recommendation
[One concrete action, or "Sprint is on track — no action needed."]
```

---

## 6. Fast Escalation Rules

Apply these rules before outputting, and place the flag at the TOP of the
output if triggered (above the status table):

## 6. 快速升级规则

在输出之前应用这些规则，如果触发，将标记放在
输出顶部（状态表之上）：

**Critical flag** — if Must Have stories are BLOCKED or NOT STARTED and
less than 40% of the sprint time remains:

```
SPRINT AT RISK: [N] Must Have stories are not complete with [X]% of sprint
time remaining. Recommend replanning with `/sprint-plan update`.
```

**严重标记** — 如果 Must Have 故事处于 BLOCKED 或 NOT STARTED，且
剩余冲刺时间不足 40%：

```
SPRINT AT RISK: [N] Must Have stories are not complete with [X]% of sprint
time remaining. Recommend replanning with `/sprint-plan update`.
```

**Completion flag** — if all Must Have stories are DONE:

```
All Must Haves complete. Team can pull from Should Have backlog.
```

**完成标记** — 如果所有 Must Have 故事都是 DONE：

```
All Must Haves complete. Team can pull from Should Have backlog.
```

**Missing stories flag** — if any referenced story files do not exist:

```
NOTE: [N] story files referenced in the sprint plan are missing.
Run `/story-readiness sprint` to validate story file coverage.
```

**缺失故事标记** — 如果任何引用的故事文件不存在：

```
NOTE: [N] story files referenced in the sprint plan are missing.
Run `/story-readiness sprint` to validate story file coverage.
```

---

## Collaborative Protocol

This skill is read-only. It reports observed facts from files on disk.

- It does not update the sprint plan
- It does not change story status
- It does not propose scope cuts (that is `/sprint-plan update`)
- It makes at most one recommendation per run

For more detail on a specific story, the user can read the story file directly
or run `/story-readiness [path]`.

For sprint replanning, use `/sprint-plan update`.
For end-of-sprint retrospective, use `/retrospective`.

## 协作协议

此技能只读。它报告磁盘文件上观察到的事实。

- 它不更新冲刺计划
- 它不改变故事状态
- 它不提议削减范围（那是 `/sprint-plan update`）
- 每次运行最多给出一个建议

要了解某个具体故事的更多细节，用户可以直接读取故事文件
或运行 `/story-readiness [path]`。

冲刺重新规划，使用 `/sprint-plan update`。
冲刺结束回顾，使用 `/retrospective`。
