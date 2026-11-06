# Phase 2: When the ADR or the manifest changed after the story was written

# 第 2 阶段：当 ADR 或清单在故事编写之后发生变更时

Read only when Phase 2 found a version mismatch.

仅在 Phase 2 发现版本不匹配时阅读。

## The ADR

## ADR

The ADR's `version` (from `adr-status.sh`: its Last Verified date, else its Date,
else `unversioned`) differs from the story's `ADR Version`, or the ADR is
`unversioned` while the story names a date. Its decision may have changed.

ADR 的 `version`（来自 `adr-status.sh`：其 Last Verified 日期，否则其 Date，
再否则为 `unversioned`）与故事的 `ADR Version` 不同，或者 ADR 为
`unversioned` 而故事却指定了日期。其决策可能已经变更。

Ask: "Story was written against ADR v[story date]. The ADR is now v[current].
How do you want to go on?" Options:

询问："Story was written against ADR v[story date]. The ADR is now v[current].
How do you want to go on?" 选项：

- **Re-read the changed ADR and refresh the story (Recommended).** Read the ADR's
  Decision, Engine Compatibility and ADR Dependencies sections with
  `bash .claude/scripts/md-section.sh extract <adr> "Decision"` and the same for
  the other two. Then edit the story: `ADR Version` becomes the ADR's `version`
  (never today's date, or the next run mismatches again), and the ADR Decision
  Summary and `## Implementation Notes` are replaced with the guidance you read.
  The programmer's brief carries the new guidance, never the old summary.
- **Implement from the story's summary — I accept the drift.** The brief carries the
  summary and tells the agent it predates the current ADR. Note it under Deviations.
- **Stop — I want to review the ADR first.** No agent runs.

- **重新阅读已变更的 ADR 并刷新故事（推荐）。** 使用
  `bash .claude/scripts/md-section.sh extract <adr> "Decision"` 读取 ADR 的
  Decision、Engine Compatibility 和 ADR Dependencies 章节，其余两个章节同样处理。
  然后编辑故事：`ADR Version` 变为 ADR 的 `version`
  （绝不要用今天的日期，否则下一次运行又会不匹配），并将 ADR Decision
  Summary 和 `## Implementation Notes` 替换为你读取到的指导内容。
  程序员的任务简报携带新的指导内容，而绝不是旧的摘要。
- **根据故事中的摘要来实现 —— 我接受这种偏差。** 任务简报携带
  摘要，并告知智能体它早于当前的 ADR。在 Deviations 下记录这一点。
- **停止 —— 我想先审阅 ADR。** 不运行任何智能体。

## The control manifest

## 控制清单

The story's `Manifest Version` differs from the manifest's. New rules may apply.

故事的 `Manifest Version` 与清单的版本不同。可能适用新的规则。

Ask: "Story was written against manifest v[story date]. The current manifest is
v[current]. How do you want to go on?" Options:

询问："Story was written against manifest v[story date]. The current manifest is
v[current]. How do you want to go on?" 选项：

- **Update the story's manifest version and use the current rules (Recommended).**
  Set the story's `Manifest Version` to the current date, then read the layer's
  rules for the brief.
- **Use the old rules — I accept the risk.** Set `Manifest Version` to the current
  date and add `Manifest-Note: Proceeded with old manifest rules on [date] —
  non-compliance risk accepted.` to the story header. Note it under Deviations;
  `/story-done` carries the note into its deviations.
- **Stop — I want to review the manifest first.** No agent runs.

- **更新故事的清单版本并使用当前规则（推荐）。**
  将故事的 `Manifest Version` 设置为当前日期，然后读取该层的
  规则用于任务简报。
- **使用旧规则 —— 我接受该风险。** 将 `Manifest Version` 设置为当前
  日期，并在故事头部添加 `Manifest-Note: Proceeded with old manifest rules on [date] —
  non-compliance risk accepted.`。在 Deviations 下记录这一点；
  `/story-done` 会把该备注带入其偏差记录。
- **停止 —— 我想先审阅清单。** 不运行任何智能体。

Each option names the story edit it makes, so choosing it is the ask.

每个选项都说明了它所做出的故事编辑，因此选择它即为授权。
