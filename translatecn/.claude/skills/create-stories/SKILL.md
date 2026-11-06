---
name: create-stories
description: "Breaks one epic into implementable stories with acceptance criteria. Use when the user wants stories for an epic or the next batch of work to build. Not for turning the whole design into epics."
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-stories/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh extract *), Bash(bash .claude/scripts/md-section.sh list *)
model: sonnet
---
---
name: create-stories
description: "将一个史诗拆解为带验收标准的可实施故事。当用户想要某个史诗的故事，或下一批要构建的工作时使用。不用于将整个设计转化为史诗。"
argument-hint: "[epic-slug | epic-path] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/create-stories/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh extract *), Bash(bash .claude/scripts/md-section.sh list *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,workflow,docs.density,story_granularity,qa.level,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.
用提问工具提问。若没有该工具，则把选项编号列出并结束本轮等待。
被跳过或关闭的提问不算答复：请用纯文本再次提问。

# Create Stories
# 创建故事

A story is one implementable behaviour: small enough for the size
`story_granularity` sets, self-contained, and traced to a requirement and the
decision that governs it. Run this skill once per epic, in dependency order:
Foundation epics first, then Core, Feature, Presentation.
一个故事是一种可实施的行为：小到符合 `story_granularity` 设定的规模，
自包含，并可追溯到一项需求以及管辖它的决策。按依赖顺序，每个史诗运行一次此技能：
先是基础（Foundation）史诗，然后是核心（Core）、功能（Feature）、表现（Presentation）。

**Writes:** `production/epics/[epic-slug]/story-NNN-[slug].md`, the epic's
`EPIC.md` Stories table, and its row in `production/epics/index.md`.
**Next:** `/dev-story [story-path]` at `workflow: minimal`; otherwise
`/story-readiness [story-path]`, then `/dev-story`.
**写入：** `production/epics/[epic-slug]/story-NNN-[slug].md`、该史诗的
`EPIC.md` Stories 表，以及它在 `production/epics/index.md` 中的行。
**下一步：** 在 `workflow: minimal` 时使用 `/dev-story [story-path]`；否则
先用 `/story-readiness [story-path]`，再用 `/dev-story`。

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).
提问遵循 `.claude/docs/automation-modes.md`（协作模式总是询问，引导模式
仅在重大选择上询问，自主模式记录后继续；`automation_always_ask`
类别总是询问）。

Checklist (copy it and tick as you go):
检查清单（复制它，边做边勾选）：

```
- [ ] Phase 1: epic found, tier resolved
- [ ] Phase 2: inputs loaded, each ADR's status reported
- [ ] Phase 3-4: stories drafted, typed, Ready or Blocked
- [ ] Phase 5: QA lead review run, or its skip noted
- [ ] Phase 6: story list shown, one ask to write
- [ ] Phase 7: stories, EPIC.md and index.md written (or index absence said)
- [ ] Phase 8: next step asked, closing block printed
```

## Phase 1: Epic and settings
## 阶段 1：史诗与设置

**Tier.** `workflow` for the epic's system: the `system_overrides` row for the epic
slug (its GDD system) if there is one, else the project value.
**Tier。** 该史诗系统的 `workflow`：若有该史诗 slug（其 GDD 系统）的
`system_overrides` 行则用该行，否则用项目值。

**`story_granularity`** sets each story's acceptance-criteria load. Group or split
criteria to hit it:
**`story_granularity`** 设定每个故事的验收标准负载。对标准进行分组或拆分以达到它：

| `story_granularity` | ACs per story | Size |
|---|---|---|
| `coarse` (default, `rigor: minimal`) | 5-10 | a whole feature, multi-day |
| `balanced` (`rigor: standard`) | 2-4 | one task, about one session |
| `fine` | 1 | one criterion; the story name restates it |
| `story_granularity` | 每个故事的 AC 数 | 规模 |
|---|---|---|
| `coarse`（默认，`rigor: minimal`） | 5-10 | 一整个功能，多天 |
| `balanced`（`rigor: standard`） | 2-4 | 一项任务，约一次会话 |
| `fine` | 1 | 一条标准；故事名称重述它 |

**`docs.density`** sets the depth of each story's prose (context, implementation
notes, ADR summary), never the AC count or the AC text: `terse` (default) = bullet
notes, no preamble; `balanced` = a short context paragraph plus notes; `thorough` =
full context, guidance and ADR rationale. The TR-ID, ADR Version and acceptance
criteria are never trimmed.
**`docs.density`** 设定每个故事散文的深度（上下文、实现
说明、ADR 摘要），绝不改变 AC 数量或 AC 文本：`terse`（默认）= 要点
说明，无前言；`balanced` = 一段简短上下文加说明；`thorough` =
完整上下文、指导与 ADR 理由。TR-ID、ADR Version 与验收
标准永不被削减。

**Which epic.** The text typed after the skill name, with any `--review <mode>`
pair removed: an epic slug (`combat`) or a path (`production/epics/combat/EPIC.md`).
With nothing typed, the epic the user's request names ("the loot epic") counts as
named.
**哪个史诗。** 技能名之后输入的文本，移除任何 `--review <mode>`
对：史诗 slug（`combat`）或路径（`production/epics/combat/EPIC.md`）。
若未输入任何内容，用户请求中点名的史诗（"战利品史诗"）也算作
已命名。

- **Named, but no `EPIC.md` there:** at `standard` and `full`, stop: "No epic at
  `production/epics/[slug]/EPIC.md`. Run `/create-epics` to create it, or check the
  slug with `ls production/epics/`." Never decompose from a guess. At `minimal`,
  say this tier needs no `/create-epics` epic, take Phase 2's `minimal` branch, and
  name the slug it uses.
- **Blank, at `minimal`:** take Phase 2's `minimal` branch.
- **Blank, at `standard` or `full`:** list `production/epics/*/EPIC.md` with each
  status, then ask: "Which epic would you like to break into stories?" with one
  option per epic. **No epics found:** stop and say "No epics found under
  `production/epics/`. Run `/create-epics layer: foundation` first." Never ask a
  question with no options.
- **已命名，但那里没有 `EPIC.md`：** 在 `standard` 与 `full` 下，停止："没有史诗位于
  `production/epics/[slug]/EPIC.md`。运行 `/create-epics` 创建它，或用
  `ls production/epics/` 检查该 slug。" 绝不凭猜测拆解。在 `minimal` 下，
  说明此 tier 不需要 `/create-epics` 史诗，走阶段 2 的 `minimal` 分支，并
  说明它使用的 slug。
- **留空，在 `minimal` 下：** 走阶段 2 的 `minimal` 分支。
- **留空，在 `standard` 或 `full` 下：** 列出 `production/epics/*/EPIC.md` 及各自
  状态，然后询问："你想把哪个史诗拆解为故事？"，每个史诗一个
  选项。**未找到史诗：** 停止并说明"在 `production/epics/` 下未找到史诗。
  请先运行 `/create-epics layer: foundation`。" 绝不要提出
  没有选项的问题。

## Phase 2: Load the inputs
## 阶段 2：加载输入

### `minimal`: build the epic from the brief
### `minimal`：从简报构建史诗

1. **No `design/game-brief.md`:** stop. "There is no brief to build stories from
   yet: run `/brainstorm` first; it writes the one-page brief." When the code root
   already holds the game (10 or more source files), name `/reverse-document design
   [code root]` instead.
2. Read `design/game-brief.md` in full (one page).
3. **The epic.** `<slug>` is the brief's working title, slugified (`mvp` if it has
   none), or the epic the user named.
   - `production/epics/<slug>/EPIC.md` exists: it is the epic. Use its scope, still
     traced to the brief, and never rewrite it.
   - It does not: draft one, written in Phase 7 only after the Phase 6 ask names
     it. Goal = the brief's one-sentence pitch; scope = its MVP feature list;
     order = its **Build order**. Keep it terse.
   - Stories already in the folder (a return visit): never rewrite an existing
     `story-*.md`. Add stories only for brief items they do not cover, or new ones
     the user names, and number on from the highest existing `story-NNN`.
4. **One story per MVP feature, in Build order**, each traced to the brief. No
   story is blocked on ADR grounds: this tier has none.
1. **没有 `design/game-brief.md`：** 停止。"目前没有可供构建故事的简报：
   请先运行 `/brainstorm`；它会写出一页式简报。" 若代码根目录
   已包含游戏（10 个或更多源文件），则改为指明 `/reverse-document design
   [code root]`。
2. 完整读取 `design/game-brief.md`（一页）。
3. **史诗。** `<slug>` 是简报的工作标题的 slug 化形式（若无标题则为 `mvp`），
   或用户点名的史诗。
   - `production/epics/<slug>/EPIC.md` 存在：它就是史诗。使用其范围，仍
     追溯到简报，且绝不重写它。
   - 不存在：起草一个，只在阶段 6 的提问点名它之后于阶段 7 写入。
     目标 = 简报的一句话推介语；范围 = 其 MVP 功能列表；
     顺序 = 其 **Build order**。保持简洁。
   - 文件夹中已有故事（再次访问）：绝不重写既有
     `story-*.md`。只为它们未覆盖的简报条目、或用户点名的新条目
     添加故事，并从现有最高的 `story-NNN` 继续编号。
4. **每个 MVP 功能一个故事，按 Build order**，各自追溯到简报。没有
   故事因 ADR 原因被阻塞：此 tier 没有 ADR。

Read no GDD, control manifest, TR registry or ADR at `minimal`. Go to Phase 3.
在 `minimal` 下不读取任何 GDD、控制清单（control manifest）、TR 注册表或 ADR。进入阶段 3。

### `standard` and `full`: the epic and what governs it
### `standard` 与 `full`：史诗及管辖它的内容

1. **The epic:** `production/epics/[epic-slug]/EPIC.md` in full (its layer, GDD,
   governing ADRs, and the GDD Requirements table with TR-IDs).
2. **The GDD:** its sections by heading, never the whole file:
   `bash .claude/scripts/md-section.sh extract design/gdd/[file].md "Acceptance Criteria"`,
   and the same for `Formulas`, `Edge Cases` and `Detailed Design` (exit 3: try
   `Detailed Rules`, the design standard's name for the same section); at `full`
   the other required sections too (`list` shows the headings).
3. **The control manifest:** the epic's layer only, and the version:
   `bash .claude/scripts/md-section.sh extract docs/architecture/control-manifest.md "[Layer] Layer Rules"`,
   plus its `Manifest Version` line.
4. **The TR registry:** this system's entries only: in
   `docs/architecture/tr-registry.yaml`, the lines matching `system: <slug>\s*$`,
   with each entry's `id` above and its text below. The anchor keeps `combat` from
   matching `combat-ai`; `\s*` takes a Windows line ending.
5. **The ADRs**, every one the epic names (governing, or in its requirements table,
   Proposed ones included), in one call:
   ```
   bash .claude/scripts/adr-status.sh ADR-0001 ADR-0003 ...
   ```
   Each row gives the status, layer, `version` (the story's ADR Version stamp),
   `depends_on`, and missing sections. Then read only `Summary`, `Decision` (its
   Implementation Guidelines inside) and `Engine Compatibility` of each, with
   `md-section.sh extract`. Engine Notes is a story field taken from Engine
   Compatibility, not an ADR section. An ADR with none of these sections predates
   the template: read it once, and flag it for `/architecture-decision retrofit
   [file]`.
1. **史诗：** 完整读取 `production/epics/[epic-slug]/EPIC.md`（其层、GDD、
   管辖 ADR，以及带 TR-ID 的 GDD Requirements 表）。
2. **GDD：** 按标题读取其小节，绝不读整个文件：
   `bash .claude/scripts/md-section.sh extract design/gdd/[file].md "Acceptance Criteria"`，
   对 `Formulas`、`Edge Cases` 与 `Detailed Design` 同样处理（退出码 3：改试
   `Detailed Rules`，设计标准中同一小节的名称）；在 `full` 下
   还要读取其他必需小节（`list` 会显示标题）。
3. **控制清单：** 只读该史诗的层，以及版本：
   `bash .claude/scripts/md-section.sh extract docs/architecture/control-manifest.md "[Layer] Layer Rules"`，
   加上其 `Manifest Version` 行。
4. **TR 注册表：** 只读此系统的条目：在
   `docs/architecture/tr-registry.yaml` 中，匹配 `system: <slug>\s*$` 的行，
   每条条目的 `id` 在其上方、文本在其下方。锚点使 `combat` 不会
   匹配到 `combat-ai`；`\s*` 用以容纳 Windows 行尾。
5. **ADR**，即史诗点名的每一个（管辖的，或在其需求表中的，
   包括 Proposed 的），一次调用：
   ```
   bash .claude/scripts/adr-status.sh ADR-0001 ADR-0003 ...
   ```
   每行给出状态、层、`version`（故事中的 ADR Version 戳记）、
   `depends_on` 以及缺失的小节。然后只读取每个 ADR 的 `Summary`、`Decision`（其内含的
   Implementation Guidelines）与 `Engine Compatibility`，用
   `md-section.sh extract`。Engine Notes 是从 Engine
   Compatibility 取的故事字段，不是 ADR 小节。若某 ADR 缺少这些小节中的任何一个，说明它早于
   模板：读取一次，并标记它以便 `/architecture-decision retrofit
   [file]`。

**A named ADR with no file** (`NOT_FOUND`):
**已点名但无文件的 ADR**（`NOT_FOUND`）：

- `full`: stop before decomposing any story.
- `standard`: stop only when it is critical (Foundation layer); otherwise warn, go
  on, and write the stories it governs as `Blocked` until it exists.
- On stopping: "Epic references [ADR-NNNN: title] but no file for it was found in
  `docs/architecture/`. Check the epic's Governing ADRs list, or run
  `/architecture-decision` to create it. Cannot create stories until the
  referenced ADR files exist."
- `full`：在拆解任何故事之前停止。
- `standard`：仅当它至关重要（Foundation 层）时停止；否则警告，继续
  进行，并将它管辖的故事写为 `Blocked`，直至它存在。
- 停止时："史诗引用了 [ADR-NNNN: title]，但在
  `docs/architecture/` 中未找到其文件。请检查该史诗的 Governing ADRs 列表，或运行
  `/architecture-decision` 创建它。在所引用的 ADR 文件存在之前，无法创建故事。"

**Report before drafting**, with the real state, every ADR on its own with its
status:
**起草前先报告**，呈现真实状态，每个 ADR 单独列出并附其
状态：

```
Loaded: epic [name] · GDD [file] · manifest v[date], [layer] rules
ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0003 Accepted · ADR-0004 Proposed · [ADR-NNNN missing]
```

Never say "all present" when one is missing, or name a manifest version when there
is none.
当一个缺失时绝不说"全部存在"，或在没有清单版本时
说出某个版本。

## Phase 3: Type each story
## 阶段 3：为每个故事定类型

| Type | When its criteria reference |
|---|---|
| **Logic** | formulas, thresholds, state transitions, AI decisions, calculations |
| **Integration** | two or more systems, signals across boundaries, save/load round-trips |
| **Visual/Feel** | animation, VFX, "feels responsive", timing, screen shake, audio sync |
| **UI** | menus, HUD, buttons, screens, dialogue boxes, tooltips |
| **Config/Data** | balance values and data files only, no new logic |
| 类型 | 当其标准涉及 |
|---|---|
| **Logic** | 公式、阈值、状态转换、AI 决策、计算 |
| **Integration** | 两个或更多系统、跨边界的信号、存档/读档往返 |
| **Visual/Feel** | 动画、VFX、"感觉灵敏"、时序、屏幕震动、音频同步 |
| **UI** | 菜单、HUD、按钮、界面、对话框、工具提示 |
| **Config/Data** | 仅平衡数值与数据文件，无新逻辑 |

A mixed story takes the type with the highest implementation risk. The type sets
the evidence `/story-done` needs.
混合型故事取实施风险最高的类型。类型决定 `/story-done` 所需的
证据。

## Phase 4: Draft the stories
## 阶段 4：起草故事

Group the requirements that need the same core implementation into one story, at
the `story_granularity` load. Order: foundation behaviour first, edge cases later,
UI last. For each story:
将需要同一核心实现的需求归入一个故事，符合
`story_granularity` 的负载。顺序：先基础行为，后边界情况，
UI 最后。对每个故事：

- **Requirement:** the TR-ID from the registry, matched through the epic's GDD
  Requirements table. Only when no entry matches, write `TR-[system]-???` and say
  so.
- **ADR:** the one that governs how to build it (the requirements table names it).
  - `Accepted`: embed it.
  - `Proposed`: `Status: Blocked`, with "BLOCKED: ADR-NNNN is Proposed — accept it
    with `/architecture-decision accept ADR-NNNN` once decided".
  - `Deprecated` or `Superseded`: `Status: Blocked`, with "BLOCKED: ADR-NNNN is
    [status] — point the story at [successor] (edit its ADR field;
    `/create-stories` never rewrites an existing story) before implementing".
  - An `Accepted` ADR whose `depends_on` names an ADR that is not Accepted: Blocked
    the same way, naming that ADR.
  - Several apply: list them all, the most direct first.
  - None applies: `ADR: N/A — [reason]`, e.g. "pure data configuration". Never
    blank: blank means unchecked.
- **ADR Version:** the story's **ADR Version** is the ADR's `## Last Verified`
  date, else its `## Date`, else `unversioned` (the `version` column). `/dev-story`
  trusts the story's ADR summary while this still matches the ADR.
- **Engine risk:** from the ADR's Engine Compatibility (its knowledge risk).
- **Estimate:** propose a t-shirt size from the criteria and the files the story
  touches: `S` (a few hours), `M` (about a day) or `L` (several days). It is a
  proposal: Phase 6 shows it and the user can change it. `/story-readiness` fails
  a story whose Estimate is still the template's bracket, so never leave it.
- **需求：** 来自注册表的 TR-ID，通过史诗的 GDD
  Requirements 表匹配。仅当没有条目匹配时，才写 `TR-[system]-???` 并
  说明原因。
- **ADR：** 管辖如何构建它的那个（需求表会点名它）。
  - `Accepted`：内嵌它。
  - `Proposed`：`Status: Blocked`，并附"BLOCKED: ADR-NNNN 为 Proposed — 一旦决定，
    用 `/architecture-decision accept ADR-NNNN` 接受它"。
  - `Deprecated` 或 `Superseded`：`Status: Blocked`，并附"BLOCKED: ADR-NNNN 为
    [status] — 在实施前将该故事指向 [successor]（编辑其 ADR 字段；
    `/create-stories` 绝不重写既有故事）"。
  - 一个 `Accepted` 的 ADR，其 `depends_on` 点名了某个并非 Accepted 的 ADR：以同样方式
    阻塞，并点名该 ADR。
  - 多个适用：全部列出，最直接的在前。
  - 无适用：`ADR: N/A — [reason]`，例如"纯数据配置"。绝不
    留空：留空意味着未检查。
- **ADR Version：** 故事的 **ADR Version** 是该 ADR 的 `## Last Verified`
  日期，否则其 `## Date`，再否则 `unversioned`（`version` 列）。`/dev-story`
  在此值仍与 ADR 匹配期间信任故事的 ADR 摘要。
- **引擎风险：** 取自该 ADR 的 Engine Compatibility（其知识风险）。
- **估算：** 依据标准与故事涉及的文件提出一个 T 恤尺码：
  `S`（数小时）、`M`（约一天）或 `L`（数天）。它只是
  提议：阶段 6 会展示它，用户可更改。`/story-readiness` 会使
  估算仍为模板方括号的故事失败，因此绝不留下它。

## Phase 5: QA lead review
## 阶段 5：QA 负责人评审

Read the `review_gate` line above. `skill-gates=skip` (solo or lean): no review;
note "QL-STORY-READY skipped — [Solo | Lean] mode" in the Phase 6 list and the
closing block. `skill-gates=run`: read `references/qa-lead-gate.md` and
`.claude/docs/director-gates.md`, and run it now, before the Phase 6 ask. On a skip,
do not load it.
读取上文的 `review_gate` 行。`skill-gates=skip`（solo 或 lean）：不评审；
在阶段 6 列表与收尾区块中注明 "QL-STORY-READY skipped — [Solo | Lean] mode"。
`skill-gates=run`：读取 `references/qa-lead-gate.md` 与
`.claude/docs/director-gates.md`，并在阶段 6 提问之前立即运行它。若为跳过，
不要加载它。

## Phase 6: Show the stories, ask once
## 阶段 6：展示故事，只问一次

```
## Stories for Epic: [name]
ADRs: ADR-0001 Accepted · ADR-0002 Accepted · ADR-0004 Proposed   (every ADR, from Phase 2)

Story 001: [title] — Logic — ADR-0001 — Ready — Estimate M
  Covers: TR-[system]-001 ([one-line requirement])
  Test required: tests/unit/[system]/[slug]_test.[ext]

Story 002: [title] — Integration — ADR-0004 — BLOCKED (ADR-0004 is Proposed) — Estimate L
  Covers: TR-[system]-002, TR-[system]-003
  Test required: tests/integration/[system]/[slug]_test.[ext]

Story 003: [title] — Visual/Feel — ADR-0001 — Ready — Estimate S
  Covers: TR-[system]-004
  Evidence required: retained screenshot + sign-off in production/qa/evidence/[slug]-evidence.md

[N stories: N Logic, N Integration, N Visual/Feel, N UI, N Config/Data; N Blocked]
QL-STORY-READY: [skipped — Solo mode | its verdicts]
```

At `minimal`, each line traces to `Brief MVP feature N`, there is no ADRs line, and
there is one story per MVP feature: no extra stories for brief items outside the
MVP list. Then
ask: "May I write these [N] stories to `production/epics/[epic-slug]/`, and
[create | update] `production/epics/[epic-slug]/EPIC.md` and update
`production/epics/index.md`?" Options: Yes, write all [N] / Not yet, I want to
adjust first; an adjustment can change any estimate. Name every file Phase 7 touches: *create* `EPIC.md` only when it
does not exist, and leave `index.md` out when it does not exist. Write nothing
before the yes.
在 `minimal` 下，每行追溯到 `Brief MVP feature N`，没有 ADRs 行，且
每个 MVP 功能一个故事：不为 MVP 列表之外的简报条目添加额外故事。然后
询问："我可以把这 [N] 个故事写入 `production/epics/[epic-slug]/`，并
[创建 | 更新] `production/epics/[epic-slug]/EPIC.md` 以及更新
`production/epics/index.md` 吗？" 选项：Yes, write all [N] / Not yet, I want to
adjust first；调整可改变任何估算。点名阶段 7 会触碰的每个文件：仅当
`EPIC.md` 不存在时才*创建*它，`index.md` 不存在时则不提及它。在
Yes 之前不写入任何内容。

## Phase 7: Write
## 阶段 7：写入

### The story files
### 故事文件

**Each story** is `production/epics/[epic-slug]/story-[NNN]-[slug].md`, laid out
as `.claude/docs/templates/story.md`. Never reuse a story number. Write each file
as a file, never through a shell command: a shell write skips the project's write
checks.
**每个故事**都是 `production/epics/[epic-slug]/story-[NNN]-[slug].md`，按
`.claude/docs/templates/story.md` 布局。绝不重复使用故事编号。将每个文件
作为文件写入，绝不通过 shell 命令写入：shell 写入会跳过项目的写入
检查。

At `minimal` there is no GDD, ADR, TR registry or manifest. Fill these fields
exactly:
在 `minimal` 下没有 GDD、ADR、TR 注册表或清单。精确填写这些
字段：

| Field | Value at `minimal` |
|---|---|
| GDD | `design/game-brief.md` |
| Requirement | `Brief MVP feature N`, never a TR-ID |
| ADR Governing Implementation, ADR Decision Summary, ADR Version | `N/A (minimal — no ADRs)` |
| Manifest Version, Control Manifest Rules | `N/A (minimal — no control manifest)` |
| Engine | `engine.name` + `engine.version` |
| Risk | the level `docs/engine-reference/<engine>/VERSION.md` gives the pinned version (its timeline row, or its overall rating). No file or no level: `NOT ASSESSED (no VERSION.md risk rating)`, never a guess. `/dev-story` reads NOT ASSESSED as HIGH |
| Engine Notes | `none (no ADR engine-compatibility analysis at minimal)` |
| Acceptance Criteria | from the brief's **Player goal & fail state** and the MVP feature, made concrete and testable; never invented from a bare bullet |
| 字段 | 在 `minimal` 下的值 |
|---|---|
| GDD | `design/game-brief.md` |
| Requirement | `Brief MVP feature N`，绝不是 TR-ID |
| ADR Governing Implementation、ADR Decision Summary、ADR Version | `N/A (minimal — no ADRs)` |
| Manifest Version、Control Manifest Rules | `N/A (minimal — no control manifest)` |
| Engine | `engine.name` + `engine.version` |
| Risk | `docs/engine-reference/<engine>/VERSION.md` 为所固定版本给出的级别（其时间线行，或其总体评级）。无文件或无级别：`NOT ASSESSED (no VERSION.md risk rating)`，绝不猜测。`/dev-story` 将 NOT ASSESSED 读作 HIGH |
| Engine Notes | `none (no ADR engine-compatibility analysis at minimal)` |
| Acceptance Criteria | 来自简报的 **Player goal & fail state** 与 MVP 功能，使其具体且可测试；绝不从单条要点凭空编造 |

At every tier:
- **QA Test Cases:** when the review was skipped, write
  `*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*`.
  Never improvise test cases.
- **Test Evidence:** `qa.level` governs it. At `qa.level: minimal` tests are
  waived (advisory), but a Visual/Feel or UI story's retained screenshot is not.
- **Estimate:** the size from Phase 6, with any change the user made.
- **Dependencies:** name each story this one needs by its path.
- **Files:** the code and test files the story is planned to create or change,
  under the code root and test root. `/dev-story` replaces them with the real list.
在每个 tier：
- **QA Test Cases：** 当评审被跳过时，写
  `*N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above*`。
  绝不临时编造测试用例。
- **Test Evidence：** 由 `qa.level` 决定。在 `qa.level: minimal` 下测试
  获得豁免（仅作建议），但 Visual/Feel 或 UI 故事的留存截图不豁免。
- **Estimate：** 阶段 6 的规模，加上用户所做的任何更改。
- **Dependencies：** 按路径点名此故事所需的每个故事。
- **Files：** 计划创建或更改的代码与测试文件，
  位于代码根与测试根之下。`/dev-story` 会用真实列表替换它们。

### `EPIC.md`

At `minimal` with none yet, write the Phase 2 draft with the table
below. Otherwise replace its "Stories: Not yet created" line with the table, or on
a return visit append one row per new story and leave the rest of the file as it
is:
在 `minimal` 且尚无 `EPIC.md` 时，用下表写入阶段 2 的草稿。
否则将其 "Stories: Not yet created" 行替换为该表，或在
再次访问时每个新故事追加一行，文件其余部分保持
原样：

```markdown
## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [title] | Logic | Ready | ADR-0001 |
| 002 | [title] | Integration | Blocked | ADR-0004 |
```

### `production/epics/index.md`

Set the epic's `Stories` cell to `[N] stories`,
the epic's total after this run. When the file does not exist, say so:
`Epics index not updated: production/epics/index.md absent`.
将该史诗的 `Stories` 单元格设为 `[N] stories`，
即本次运行后该史诗的总数。若文件不存在，则说明：
`Epics index not updated: production/epics/index.md absent`。

## Phase 8: Close
## 阶段 8：收尾

If other epics in `production/epics/` have no stories, list them. Then ask:
"[N] stories written to `production/epics/[epic-slug]/`. What next?" Options, those
that apply:
若 `production/epics/` 中的其他史诗没有故事，则列出它们。然后询问：
"[N] 个故事已写入 `production/epics/[epic-slug]/`。接下来做什么？" 选项为
适用者：

- Start implementing: `/dev-story [first-story-path]` at `minimal`,
  `/story-readiness [first-story-path]` otherwise (recommended)
- Create stories for [next epic]: `/create-stories [slug]` (only when an epic has
  none)
- Plan the sprint: `/sprint-plan new` (only when every epic has stories; never at
  `minimal`, where the brief's build order is the plan)
- Stop here for this session
- 开始实施：在 `minimal` 下用 `/dev-story [first-story-path]`，
  否则用 `/story-readiness [first-story-path]`（推荐）
- 为 [next epic] 创建故事：`/create-stories [slug]`（仅当某史诗
  尚无故事时）
- 规划冲刺：`/sprint-plan new`（仅当每个史诗都有故事时；在
  `minimal` 下绝不可用，那里简报的 build order 就是计划）
- 本次会话到此停止

Never start implementation or write code: this skill stops at the story files.
Acceptance criteria come from the GDD (the brief at `minimal`), implementation
notes from the ADRs, rules from the manifest; none are invented.
绝不开始实施或编写代码：此技能止于故事文件。
验收标准来自 GDD（`minimal` 下为简报），实现
说明来自 ADR，规则来自清单；一概不凭空编造。

**The run's last reply ends with this block**, after the question above is
answered (repeat it if you showed it earlier):
**本次运行的最后回复以此区块结束**，在上述提问
得到答复之后（若你早先已展示过，则重复它）：

```
Verdict: COMPLETE — [N] stories written to production/epics/[epic-slug]/ ([N] Ready, [N] Blocked)
Review: [QL-STORY-READY skipped — Solo mode | skipped — Lean mode | its verdicts]
Index: [production/epics/index.md updated | Epics index not updated: production/epics/index.md absent]
Next step: [/dev-story [first-story-path] | /story-readiness [first-story-path]]
```

When the user declines the write: `Verdict: BLOCKED — user declined. No story
files written.`
当用户拒绝写入时：`Verdict: BLOCKED — user declined. No story
files written.`
