# /architecture-review — Phase 8: Write and Update Traceability Index
# /architecture-review — 阶段 8：写入并更新可追溯性索引

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 8: Write and Update Traceability Index
## 阶段 8：写入并更新可追溯性索引

**In this file:**
**本文件内容：**

- The receipt is taken last
- 回执最后采集
- RTM Output (rtm mode only)
- RTM 输出（仅 rtm 模式）
- TR Registry Update
- TR 注册表更新
- Reflexion Log Update
- 反思日志更新
- Session State Update
- 会话状态更新

Use `AskUserQuestion` for the write approval:
使用 `AskUserQuestion` 取得写入批准：
- "Review complete. What would you like to write?"
  - [A] Write all three files — review report (`docs/architecture/architecture-review-[date].md`), traceability index (`docs/architecture/requirements-traceability.md`), TR registry (`docs/architecture/tr-registry.yaml`)
  - [B] Write review report only — `docs/architecture/architecture-review-[date].md`
  - [C] Don't write anything yet — I need to review the findings first
- "Review complete. What would you like to write?"
  （评审完成。你希望写入什么？）
  - [A] Write all three files — review report (`docs/architecture/architecture-review-[date].md`), traceability index (`docs/architecture/requirements-traceability.md`), TR registry (`docs/architecture/tr-registry.yaml`)
    （写入全部三个文件 — 评审报告、可追溯性索引、TR 注册表）
  - [B] Write review report only — `docs/architecture/architecture-review-[date].md`
    （仅写入评审报告）
  - [C] Don't write anything yet — I need to review the findings first
    （暂时什么都不写 — 我需要先查看发现）

**A `single-gdd` run saw one system**, so in that mode [A] writes the review
report and only that system's share of the other two files. Name it so in the
option: "…update [system]'s rows in the traceability index and its TR registry
entries". In `requirements-traceability.md`, replace that system's matrix rows
and recompute the Coverage Summary, keeping every other system's rows as they
are. When the index does not exist yet, write the report and the registry only,
and say a full review creates the index. In the TR registry, append, update and
deprecate only that system's entries: another system's GDD was not read, so its
entries are never proposed for deprecation.
**一次 `single-gdd` 运行只看到一个系统**，因此在该模式下 [A] 写入评审报告，
以及另外两个文件中仅属于该系统的部分。在选项中如此命名："…update [system]'s
rows in the traceability index and its TR registry entries"（更新 [system] 在
可追溯性索引中的行及其 TR 注册表条目）。在 `requirements-traceability.md` 中，
替换该系统的矩阵行并重新计算 Coverage Summary，其它每个系统的行保持原样。
当索引尚不存在时，只写报告和注册表，并说明完整评审会创建索引。在 TR 注册表中，
仅对该系统的条目执行追加、更新和废弃：另一个系统的 GDD 未被读取，因此绝不提议
废弃其条目。

When Phase 4 found a 🔴 conflict and `docs/consistency-failures.md` exists, name
that file in option [A] as well — "…and append [N] conflict entr(y/ies) to
`docs/consistency-failures.md`". Only [A] appends there (see Reflexion Log
Update); [B] writes the report and nothing else.
当阶段 4 发现 🔴 冲突且 `docs/consistency-failures.md` 存在时，也在选项 [A] 中
点名该文件 — "…and append [N] conflict entr(y/ies) to
`docs/consistency-failures.md`"（并向 `docs/consistency-failures.md` 追加 [N] 条
冲突条目）。只有 [A] 会向那里追加（见反思日志更新）；[B] 只写报告，别的什么都
不做。

### The receipt is taken last
### 回执最后采集

Write the review report after the TR registry update and the
`consistency-failures.md` entries, and take its receipt lines at that moment —
never from the Phase 7 draft. Both files are review inputs: a receipt taken
before this run edited them records the old content, and the next run reads
this run's own edit as `CHANGED`.
在 TR 注册表更新和 `consistency-failures.md` 条目之后写入评审报告，并在那一刻
采集其回执行 — 绝不要从阶段 7 的草案中采集。这两个文件都是评审输入：在本次运行
编辑它们之前采集的回执记录的是旧内容，而下次运行会把本次运行自身的编辑读作
`CHANGED`。

```
Bash: bash .claude/scripts/review-receipts.sh hash docs/architecture/adr-*.md design/gdd/*.md docs/architecture/tr-registry.yaml docs/architecture/architecture.md docs/engine-reference/[engine]/*.md docs/engine-reference/[engine]/modules/*.md project.yaml .claude/docs/technical-preferences.md docs/consistency-failures.md .claude/skills/architecture-review/SKILL.md .claude/skills/architecture-review/references/*.md
```

It is the same list as Phase 1a's check, with `[engine]` filled in the same way.
An optional input that does not exist prints `not stamped, no such file` and is
left out; that is expected. Paste the stamp lines into the report under its
header, where the Phase 7 template shows them.
它与阶段 1a 校验的是同一份清单，`[engine]` 也以相同方式填充。不存在的可选输入
会打印 `not stamped, no such file` 并被略过；这是预期行为。将盖章行粘贴到报告
头部之下，即阶段 7 模板所示的位置。

### RTM Output (rtm mode only)
### RTM 输出（仅 rtm 模式）

For `rtm` mode, use `AskUserQuestion`:
对于 `rtm` 模式，使用 `AskUserQuestion`：
- "May I write the full Requirements Traceability Matrix?"
  - [A] Yes — write to `docs/architecture/requirements-traceability.md`
  - [B] Not yet — show me the full RTM data first, then ask again
- "May I write the full Requirements Traceability Matrix?"
  （我可以写入完整的需求可追溯性矩阵吗？）
  - [A] Yes — write to `docs/architecture/requirements-traceability.md`
    （是 — 写入 `docs/architecture/requirements-traceability.md`）
  - [B] Not yet — show me the full RTM data first, then ask again
    （暂不 — 先给我看完整 RTM 数据，然后再问一次）

RTM file format:
RTM 文件格式：

```markdown
# Requirements Traceability Matrix (RTM)

> Last Updated: [date]
> Mode: /architecture-review rtm
> Coverage: [N]% full chain complete (GDD → ADR → Story → Test)

## How to read this matrix

| Column | Meaning |
|--------|---------|
| TR-ID | Stable requirement ID from tr-registry.yaml |
| GDD | Source design document |
| ADR | Architectural decision governing implementation |
| Story | Story file that implements this requirement |
| Test File | Automated test file path |
| Test Status | COVERED / MISSING / NONE / NO STORY |

## Full Traceability Matrix

| TR-ID | GDD | Requirement | ADR | Story | Test File | Status |
|-------|-----|-------------|-----|-------|-----------|--------|
[Full matrix rows from Phase 3b]

## Coverage Summary

| Status | Count | % |
|--------|-------|---|
| COVERED — full chain complete | [N] | [%] |
| MISSING test — story exists, no test | [N] | [%] |
| NO STORY — ADR exists, not yet implemented | [N] | [%] |
| NO ADR — architectural gap | [N] | [%] |
| **Total requirements** | **[N]** | **100%** |

## Uncovered Requirements (Priority Fix List)

Requirements where the full chain is broken, prioritised by layer:

### Foundation layer gaps
[list with suggested action per gap]

### Core layer gaps
[list]

### Feature / Presentation layer gaps
[list — lower priority]

## History

| Date | Full Chain % | Notes |
|------|-------------|-------|
| [date] | [%] | Initial RTM |
```

```markdown
# 需求可追溯性矩阵（RTM）

> Last Updated: [日期]
> Mode: /architecture-review rtm
> Coverage: [N]% 完整链路完成（GDD → ADR → 故事 → 测试）

## 如何阅读此矩阵

| 列 | 含义 |
|--------|---------|
| TR-ID | 来自 tr-registry.yaml 的稳定需求 ID |
| GDD | 来源设计文档 |
| ADR | 管辖实现的架构决策 |
| Story | 实现该需求的故事文件 |
| Test File | 自动化测试文件路径 |
| Test Status | COVERED / MISSING / NONE / NO STORY |

## 完整可追溯性矩阵

| TR-ID | GDD | 需求 | ADR | Story | Test File | 状态 |
|-------|-----|-------------|-----|-------|-----------|--------|
[来自阶段 3b 的完整矩阵行]

## 覆盖摘要

| 状态 | 数量 | % |
|--------|-------|---|
| COVERED — 完整链路完成 | [N] | [%] |
| MISSING test — 故事存在，无测试 | [N] | [%] |
| NO STORY — ADR 存在，尚未实现 | [N] | [%] |
| NO ADR — 架构缺口 | [N] | [%] |
| **需求总数** | **[N]** | **100%** |

## 未覆盖需求（优先修复清单）

完整链路断裂的需求，按层排序：

### 基础层缺口
[逐缺口列出建议操作]

### 核心层缺口
[列出]

### 功能 / 表现层缺口
[列出 — 优先级较低]

## 历史

| 日期 | 完整链路 % | 备注 |
|------|-------------|-------|
| [日期] | [%] | 初始 RTM |
```

### TR Registry Update
### TR 注册表更新

Also ask: "May I update `docs/architecture/tr-registry.yaml` with new requirement
IDs from this review?"
还要询问："May I update `docs/architecture/tr-registry.yaml` with new requirement
IDs from this review?"（我可以把本次评审产生的新需求 ID 更新到
`docs/architecture/tr-registry.yaml` 吗？）

If yes, read the current `docs/architecture/tr-registry.yaml` again first:
the review read it at the start, and another skill or session may have changed
it since. Build the update from that fresh read, never from the earlier copy,
and keep every entry already in it. Then:
若同意，先再次读取当前的 `docs/architecture/tr-registry.yaml`：评审在开始时读过
它，此后另一个技能或会话可能已经改变了它。基于这次最新读取构建更新，绝不要基于
先前的副本，并保留其中已有的每个条目。然后：
- **Append** any new TR-IDs that weren't in the registry before this review
- **追加**本次评审之前不在注册表中的任何新 TR-ID
- **Update** `requirement` text and `revised` date for any entries whose GDD
  wording changed (ID stays the same)
- **更新**任何因 GDD 措辞变化而需要更新的条目的 `requirement` 文本和 `revised`
  日期（ID 保持不变）
- **Mark** `status: deprecated` for any registry entries whose GDD requirement
  no longer exists (confirm with user before marking deprecated; in `single-gdd`
  mode, only the reviewed system's entries)
- 对 GDD 需求已不存在的任何注册表条目**标记** `status: deprecated`（标记废弃前
  先与用户确认；在 `single-gdd` 模式下，仅限受评审系统的条目）
- **Mark** `status: "superseded-by: TR-[system]-NNN"` for an entry whose
  requirement was split or replaced, naming the new TR-ID(s). Keep the quotes:
  unquoted, the second colon makes the file invalid YAML
- 对需求被拆分或替换的条目**标记** `status: "superseded-by: TR-[system]-NNN"`，
  并点名新的 TR-ID。保留引号：不加引号时，第二个冒号会使文件成为无效 YAML
- **Never** renumber or delete existing entries
- **绝不**重新编号或删除现有条目
- Update the `last_updated` and `version` fields at the top
- 更新顶部的 `last_updated` 和 `version` 字段

After writing, run `bash .claude/scripts/registry.sh validate` and fix every row
about an entry this write added or changed (a DUPLICATE, STATUS or LAYOUT row,
or a PATH_MISSING row for a path it named) before you go on; name rows about
other entries to the user rather than fixing them unasked. If the script is
missing or prints nothing, say the registry check did not run, then re-read the
entries you wrote against the rules in the file's header.
写入之后，运行 `bash .claude/scripts/registry.sh validate`，并在继续之前修复
有关本次写入新增或更改的条目的每一行（DUPLICATE、STATUS 或 LAYOUT 行，或它
点名路径的 PATH_MISSING 行）；对于有关其它条目的行，向用户点名，而不是未经
要求就修复。若脚本缺失或没有输出，说明注册表检查未运行，然后对照文件头部的规则
重新读取你写入的条目。

This ensures all future story files can reference stable TR-IDs that persist
across every subsequent architecture review.
这可确保未来所有故事文件都能引用在后续每次架构评审中保持稳定的 TR-ID。

### Reflexion Log Update
### 反思日志更新

When the user chose Phase 8's [A] — the option that named this file — append
any 🔴 CONFLICT entries found in Phase 4 to `docs/consistency-failures.md` (if
the file exists), before writing the review report (its receipt is taken last):
当用户选择了阶段 8 的 [A] — 即点名了该文件的选项 — 在写入评审报告之前（其回执
最后采集），将阶段 4 发现的任何 🔴 CONFLICT 条目追加到
`docs/consistency-failures.md`（若文件存在）：

```markdown
### [YYYY-MM-DD] — /architecture-review — 🔴 CONFLICT
**Domain**: Architecture / [specific domain e.g. State Ownership, Performance]
**Documents involved**: [ADR-NNNN] vs [ADR-MMMM]
**What happened**: [specific conflict — what each ADR claims]
**Resolution**: [how it was or should be resolved]
**Pattern**: [generalised lesson for future ADR authors in this domain]
```

```markdown
### [YYYY-MM-DD] — /architecture-review — 🔴 CONFLICT
**Domain**: Architecture / [具体领域，例如 State Ownership、Performance]
**Documents involved**: [ADR-NNNN] vs [ADR-MMMM]
**What happened**: [具体冲突 — 每个 ADR 各自主张什么]
**Resolution**: [如何解决或应如何解决]
**Pattern**: [为该领域未来 ADR 作者总结的通用经验]
```

Only append CONFLICT entries — do not log GAP entries (missing ADRs are expected
before the architecture is complete). Do not create the file if missing — only
append when it already exists.
仅追加 CONFLICT 条目 — 不要记录 GAP 条目（在架构完成之前，缺失的 ADR 是预期
的）。若文件缺失，不要创建它 — 仅在它已存在时追加。

### Session State Update
### 会话状态更新

After writing all approved files, silently append to
`production/session-state/active.md`:
写入所有已批准的文件之后，静默追加到 `production/session-state/active.md`：

    ## Session Extract — /architecture-review [date]
    - Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]
    - Requirements: [N] total — [X] covered, [Y] partial, [Z] gaps
    - New TR-IDs registered: [N, or "None"]
    - GDD revision flags: [comma-separated GDD names, or "None"]
    - Top ADR gaps: [top 3 gap titles from the report, or "None"]
    - Report: docs/architecture/architecture-review-[date].md

If `active.md` does not exist, create it with this block as the initial content.
Confirm in conversation: "Session state updated."
若 `active.md` 不存在，以该块作为初始内容创建它。
在对话中确认："Session state updated."（会话状态已更新。）

The traceability index — written to `docs/architecture/requirements-traceability.md`,
the path `/propagate-design-change` and the Pre-Production gate read; `rtm` mode
later extends the same file with story and test columns — uses this format:
可追溯性索引 — 写入 `docs/architecture/requirements-traceability.md`，即
`/propagate-design-change` 和 Pre-Production 门禁所读取的路径；`rtm` 模式之后
会用故事和测试列扩展同一文件 — 使用以下格式：

```markdown
# Architecture Traceability Index
Last Updated: [date]
Engine: [name + version]

## Coverage Summary
- Total requirements: [N]
- Covered: [X] ([%])
- Partial: [Y]
- Gaps: [Z]

## Full Matrix
[Complete traceability matrix from Phase 3]

## Known Gaps
[All ❌ items with suggested ADRs]

## Superseded Requirements
[Requirements whose GDD was changed after the ADR was written]
```

```markdown
# 架构可追溯性索引
Last Updated: [日期]
Engine: [名称 + 版本]

## 覆盖摘要
- 需求总数：[N]
- 已覆盖：[X]（[%]）
- 部分覆盖：[Y]
- 缺口：[Z]

## 完整矩阵
[来自阶段 3 的完整可追溯性矩阵]

## 已知缺口
[所有 ❌ 条目及其建议 ADR]

## 已被取代的需求
[在 ADR 写定之后其 GDD 发生变更的需求]
```

---
