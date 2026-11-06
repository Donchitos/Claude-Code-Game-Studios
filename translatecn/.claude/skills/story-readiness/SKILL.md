---
name: story-readiness
description: "Checks whether a story is ready to implement: clear acceptance criteria, no open questions, valid ADR and dependencies. Use when the user asks if a story, or the sprint's stories, are ready to start or build."
argument-hint: "[story-file-path or 'all' or 'sprint'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-readiness/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/adr-status.sh *)
model: sonnet
---
---
name: story-readiness
description: "检查一个故事是否已可实施：验收标准清晰、无未决问题、ADR 与依赖有效。当用户询问某个故事或本冲刺的故事是否已可开始或构建时使用。"
argument-hint: "[story-file-path or 'all' or 'sprint'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-readiness/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/adr-status.sh *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,workflow,qa.level,gate_level,story_granularity,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

用询问工具提问。若无该工具，将选项编号列出并结束回合等待。被跳过或关闭的问题不算回答：
请用纯文本再次询问。

# Story Readiness

# 故事就绪检查

Checks that a story file holds everything a developer needs before writing code:
no design questions mid-build, no guessing, no vague acceptance criteria.

检查故事文件是否已包含开发者在写代码前所需的一切：构建过程中没有设计问题、无需猜测、
没有含糊的验收标准。

**Read-only.** It never writes or edits a file. It reports, and offers to draft
fixes in the conversation.

**只读。** 它绝不写入或编辑文件。它只报告，并提议在对话中起草修正。

**Verdicts**, one per story. The first that matches wins, in this order:

**判定**，每个故事一个。按此顺序，首个匹配者胜出：

1. **BLOCKED**: a finding the reader can clear. A referenced ADR is missing,
   `Proposed`, `Deprecated` or `Superseded`; a dependency story is missing or
   `Draft`; or a criterion holds an UNRESOLVED design question with no owner.
2. **NEEDS WORK**: a blocking checklist item fails. The story can be fixed now.
3. **NOT ASSESSED**: the story could not be evaluated. The file is unreadable,
   a referenced ADR has no readable `## Status`, or the design document it names
   cannot be found. Name what could not be read. It is never READY: a story
   nobody could check has not been shown ready. It ranks below the two failures,
   because a known blocker is more useful than an unknown.
4. **READY**: every item passes, is N/A with a reason, or is advisory. Advisory
   gaps are still listed.

1. **BLOCKED**：发现了一项读者可以清除的问题。所引用的 ADR 缺失、为 `Proposed`、`Deprecated`
   或 `Superseded`；依赖故事缺失或为 `Draft`；或某条标准含有无人负责的 UNRESOLVED 设计问题。
2. **NEEDS WORK**：某项阻塞性清单条目未通过。该故事现在即可修复。
3. **NOT ASSESSED**：该故事无法评估。文件不可读、所引用的 ADR 没有可读的 `## Status`，
   或其所指名的设计文档找不到。点明无法读取的内容。它绝不为 READY：无人能检查的故事
   并未被证明就绪。它排在前两者之后，因为已知的阻塞比未知更有用。
4. **READY**：每一项都通过、以理由记为 N/A，或为提示性。提示性缺口仍会列出。

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

询问遵循 `.claude/docs/automation-modes.md`（协作模式始终询问，引导模式就重大选择询问，
自主模式记录并继续；`automation_always_ask` 类别始终询问）。

## Phase 1: Scope

## 阶段 1：范围

The scope is the text typed after the skill name, with any `--review <mode>` pair
removed. What remains is one value; a path may contain spaces. With nothing typed,
the story, epic or sprint the user's request names is the scope.

范围是技能名之后输入的文本，去除任何 `--review <mode>` 对。剩下的就是一个值；路径可能含空格。
未输入任何内容时，范围即用户请求中所指的故事、史诗或冲刺。

- **A story path**: that story.
- **`sprint`**: the stories the current sprint lists (Phase 2 reads them).
- **`all`**: every `story-*.md` under `production/epics/`.
- **An epic** (a slug or its folder): the `story-*.md` files in that folder.
- **Blank**: Ask: "What would you like to check?" Options: A specific story file /
  All stories in the current sprint / All stories in production/epics/ / The
  stories of one epic.

- **一个故事路径**：该故事。
- **`sprint`**：当前冲刺列出的故事（阶段 2 读取它们）。
- **`all`**：`production/epics/` 下所有 `story-*.md`。
- **一个史诗**（slug 或其文件夹）：该文件夹中的 `story-*.md` 文件。
- **留空**：询问：“你想检查什么？”选项：A specific story file /
  All stories in the current sprint / All stories in production/epics/ /
  The stories of one epic。

**Zero stories in scope: stop with `NOT ASSESSED — no stories in scope`.** Name the
scope and the path that was empty, and route to `/create-stories` (at `standard`
and `full`, `/create-epics` first). Never print a `Ready: 0 / Needs Work: 0` summary
over an empty list: it reads as a clean result. For `sprint`, "no sprint plan
found" and "the sprint plan lists no stories" are different reports; say which.

**范围内零个故事：以 `NOT ASSESSED — no stories in scope` 停止。** 点明范围与为空的路径，
并引导至 `/create-stories`（在 `standard` 与 `full` 下，先 `/create-epics`）。绝不在一份空列表上
打印 `Ready: 0 / Needs Work: 0` 摘要：那读起来像一个干净的结果。对 `sprint`，
“未找到冲刺计划”与“冲刺计划未列出故事”是两种不同报告；说明是哪一种。

Say "Checking [N] story files." before going on.

在继续之前说“正在检查 [N] 个故事文件。”

## Phase 2: Facts, read once for the run

## 阶段 2：事实，本次运行只读一次

1. **Stories.** Run the story helper over the scope, with the `story_granularity`
   resolved above:
   ```
   bash .claude/scripts/story-facts.sh --lint --granularity <story_granularity> [--sprint | --all | <path> ...]
   ```
   Each `STORY` row gives a story's status, type, layer, estimate, TR-IDs, ADRs,
   acceptance-criteria count, test-evidence line and dependencies. Each `LINT` row
   is a rule the story trips. Rows are observations; the verdict is yours. Exit 3
   means a file was not found. With `NOT_FOUND` rows, each names a sprint `file:`
   entry or a path that is not a file: report each as a missing story and check
   the rest. With no `NOT_FOUND` row and `--sprint`, there is no
   `production/sprint-status.yaml`: report "no sprint plan found". Read each story file too: the testability, scope and
   asset items below need its words.
2. **ADRs.** One call gives every ADR's status and layer:
   `bash .claude/scripts/adr-status.sh`. A `no_status` or `UNFILLED` status is a
   malformed ADR: never treat an absent status as a failed one (route:
   `/architecture-decision retrofit [file]`). An ADR a story cites with no row is missing.
3. **Control manifest.** Only its `Manifest Version` line in
   `docs/architecture/control-manifest.md`. Missing file: note it once.
4. **TR registry.** Look up each story's TR-IDs, with their `status`, in
   `docs/architecture/tr-registry.yaml`. Missing file: note it once; the TR-ID
   item passes for every story.
5. **Sprint priority** (`sprint` scope): which stories are Must Have and Should
   Have, from the newest plan in `production/sprints/`.

1. **故事。** 在范围内运行故事辅助脚本，使用上面解析的 `story_granularity`：
   ```
   bash .claude/scripts/story-facts.sh --lint --granularity <story_granularity> [--sprint | --all | <path> ...]
   ```
   每个 `STORY` 行给出故事的状态、类型、分层、估算、TR-ID、ADR、验收标准数量、测试证据行与依赖。
   每个 `LINT` 行是故事触犯的一条规则。行是观察结果；判定由你给出。退出码 3 表示未找到文件。
   若有 `NOT_FOUND` 行，每行点名一个冲刺 `file:` 条目或一个不是文件的路径：将每个报告为缺失故事，
   并检查其余部分。若无 `NOT_FOUND` 行且使用 `--sprint`，则不存在
   `production/sprint-status.yaml`：报告“未找到冲刺计划”。也要读取每个故事文件：下面的可测试性、范围与
   资产条目需要其原文。
2. **ADR。** 一次调用给出每个 ADR 的状态与分层：
   `bash .claude/scripts/adr-status.sh`。`no_status` 或 `UNFILLED` 状态是格式错误的 ADR：
   绝不可将缺失状态当作失败状态（路由：`/architecture-decision retrofit [file]`）。
   故事引用却无对应行的 ADR 为缺失。
3. **控制清单。** 只读 `docs/architecture/control-manifest.md` 中的 `Manifest Version` 行。
   文件缺失：记录一次。
4. **TR 注册表。** 在 `docs/architecture/tr-registry.yaml` 中查找每个故事的 TR-ID 及其 `status`。
   文件缺失：记录一次；TR-ID 条目对所有故事均通过。
5. **冲刺优先级**（`sprint` 范围）：从 `production/sprints/` 中最新的计划确定哪些故事是 Must Have
   与 Should Have。

**Tier per story.** `workflow` is resolved per story: use the `system_overrides`
row for the story's system (the GDD filename stem of its `GDD:` path; the `[system]`
of a `TR-[system]-NNN` ID only when there is no GDD path), else the project value.
Stories in one run can sit at different tiers.

**每个故事的层级。** `workflow` 按故事解析：使用该故事所属系统的 `system_overrides`
行（其 `GDD:` 路径的 GDD 文件名主干；仅在没有 GDD 路径时，才用 `TR-[system]-NNN` ID 中的 `[system]`），
否则用项目取值。一次运行中的故事可能处于不同层级。

## Phase 3: The checklist

## 阶段 3：清单

Check every item for every story. The tier decides which groups block:

对每个故事检查每一项。层级决定哪些组构成阻塞：

| Group | `full` | `standard` | `minimal` |
|---|---|---|---|
| Design Completeness | blocks | blocks | blocks; `design/game-brief.md` stands in for the GDD |
| Architecture Completeness | blocks | the ADR status item blocks; the rest advisory unless it concerns a critical ADR | N/A, except the ADR status item |
| Scope Clarity | blocks | blocks | blocks, except Estimate: advisory (no sprint plan to size for) |
| Open Questions | blocks | blocks | blocks |
| Asset References | blocks | blocks | blocks |
| Definition of Done | blocks | blocks | blocks; the test evidence item follows `qa.level` |

| 分组 | `full` | `standard` | `minimal` |
|---|---|---|---|
| 设计完整性 | 阻塞 | 阻塞 | 阻塞；`design/game-brief.md` 代替 GDD |
| 架构完整性 | 阻塞 | ADR 状态项阻塞；其余为提示，除非涉及关键 ADR | N/A，但 ADR 状态项除外 |
| 范围清晰度 | 阻塞 | 阻塞 | 阻塞，但 Estimate 除外：提示性（没有冲刺计划可据以定尺寸） |
| 未决问题 | 阻塞 | 阻塞 | 阻塞 |
| 资产引用 | 阻塞 | 阻塞 | 阻塞 |
| 完成定义 | 阻塞 | 阻塞 | 阻塞；测试证据项遵循 `qa.level` |

An **advisory** item that fails is listed under Gaps with its Fix, and never
lowers READY by itself.

未通过的**提示性**条目会连同其 Fix 列在 Gaps 下，且本身绝不下调 READY。

### Design Completeness

### 设计完整性

- [ ] **Requirement traced**: the story names its `design/gdd/` file and quotes or
  links a specific rule or criterion from it, not just the file name. At
  `minimal`: `design/game-brief.md` and the MVP feature the story implements.
  A named design document that does not exist: NOT ASSESSED.
- [ ] **Self-contained**: the acceptance criteria say what done means without
  opening the GDD.
- [ ] **Testable**: each criterion is a specific, observable condition. Not:
  "Implement the jump mechanic." Yes: "Jump reaches 5 units within 0.3 seconds
  when held." A criterion a unit test can set up (any input values) is testable,
  even when the shipped data never reaches that case.
- [ ] **No judgement calls**: "feels responsive" or "looks good" fails for Logic,
  Integration, UI and Config/Data. For Visual/Feel such criteria are expected:
  pass when the criterion names an evidence file such as
  `production/qa/evidence/[slug]-evidence.md`, NEEDS WORK when it names none.

- [ ] **需求可追溯**：故事点名其 `design/gdd/` 文件，并引用或链接其中某条具体规则或标准，
  而不只是文件名。在 `minimal` 下：`design/game-brief.md` 与故事实现的 MVP 功能。
  所指名的设计文档不存在：NOT ASSESSED。
- [ ] **自包含**：验收标准无需打开 GDD 即可说明“完成”意味着什么。
- [ ] **可测试**：每条标准都是具体、可观察的条件。不是：“实现跳跃机制。”而是：“按住时，
  跳跃在 0.3 秒内达到 5 个单位。”单元测试能构造出（任意输入值）的标准就是可测试的，
  即使发布数据永远到不了该情形。
- [ ] **无主观判断**：“感觉灵敏”或“看起来不错”对 Logic、Integration、UI 与 Config/Data 不通过。
  对 Visual/Feel，这类标准是预期的：当标准点名证据文件（如
  `production/qa/evidence/[slug]-evidence.md`）时通过，未点名时 NEEDS WORK。

### Architecture Completeness

### 架构完整性

- [ ] **ADR status**, at every tier: each ADR the story cites, by the Phase 2
  table.
  - `Accepted`: pass.
  - `Proposed`: BLOCKED. Fix: `BLOCKED: ADR-NNNN is Proposed — accept it with
    /architecture-decision accept ADR-NNNN once decided`.
  - `Deprecated` or `Superseded`: BLOCKED. Fix: `BLOCKED: ADR-NNNN is [status] —
    point the story at [successor] (edit its ADR field;
    /create-stories never rewrites an existing story)`.
  - No such ADR file: BLOCKED.
  - No readable status: NOT ASSESSED for this item; name the file.
  At `standard`, a **critical** ADR (its `layer` is Foundation, or missing) that
  is missing or Proposed blocks; for other ADRs the items below are advisory.
- [ ] **ADR cited or N/A stated**: an ADR, or an explicit N/A with a reason
  (`ADR: N/A — [reason]`, or `N/A (minimal — no ADRs)`). Blank fails.
- [ ] **TR-ID valid**: each `TR-[system]-NNN` is in the registry with `status:
  active`. `deprecated` or `superseded-by` (quoted or not): NEEDS WORK, Fix: point
  the story at the current requirement. Not in the registry: NEEDS WORK (the story
  may predate it, or the registry needs `/architecture-review`). Passes with no
  TR-ID, or no registry.
- [ ] **Manifest Version current**: the story's `Manifest Version` against the
  manifest's. Older: a gap, because rules added since may apply. It stays a gap
  even when the new rules look unrelated: say what changed, and leave the call to
  the user. At `full` it is NEEDS WORK whatever the new rules cover; at
  `standard` it is advisory. Fix, all three steps: "Review the manifest rules added since
  [story's date]; update the story's rules if any apply; then set its Manifest
  Version to [current date]." Passes with no `Manifest Version` field, or no
  manifest.
- [ ] **Engine notes**: post-cutoff engine APIs the story touches have notes or a
  verification step, or the story states "N/A — no engine API involved".
- [ ] **Manifest rules noted**: the layer's rules are listed, or "N/A — manifest
  not yet created". Passes when there is no manifest.

- [ ] **ADR 状态**，在所有层级：故事引用的每个 ADR，依据阶段 2 的表格。
  - `Accepted`：通过。
  - `Proposed`：BLOCKED。Fix：`BLOCKED: ADR-NNNN is Proposed — accept it with
    /architecture-decision accept ADR-NNNN once decided`。
  - `Deprecated` 或 `Superseded`：BLOCKED。Fix：`BLOCKED: ADR-NNNN is [status] —
    point the story at [successor] (edit its ADR field;
    /create-stories never rewrites an existing story)`。
  - 无此 ADR 文件：BLOCKED。
  - 无可读状态：本条目为 NOT ASSESSED；点明该文件。
  在 `standard` 下，**关键** ADR（其 `layer` 为 Foundation，或缺失）若缺失或为 Proposed 则阻塞；
  对其他 ADR，下面的条目为提示性。
- [ ] **已引用 ADR 或已声明 N/A**：一个 ADR，或带理由的显式 N/A
  （`ADR: N/A — [reason]`，或 `N/A (minimal — no ADRs)`）。留空不通过。
- [ ] **TR-ID 有效**：每个 `TR-[system]-NNN` 都在注册表中且 `status:
  active`。`deprecated` 或 `superseded-by`（无论是否引号）：NEEDS WORK，Fix：将故事指向
  当前需求。不在注册表中：NEEDS WORK（故事可能早于它，或注册表需要 `/architecture-review`）。
  无 TR-ID，或无注册表，则通过。
- [ ] **Manifest Version 为最新**：将故事的 `Manifest Version` 与清单的对比。较旧：一项缺口，
  因为此后新增的规则可能适用。即使新规则看似无关，它仍是一项缺口：说明变更了什么，把决定留给
  用户。在 `full` 下无论新规则涵盖什么都是 NEEDS WORK；在 `standard` 下为提示性。Fix，共三步：
  “审阅自 [故事日期] 以来新增的清单规则；若有适用项，更新故事的规则；然后将其 Manifest
  Version 设为 [当前日期]。”无 `Manifest Version` 字段，或无清单，则通过。
- [ ] **引擎备注**：故事涉及的 cutoff 后引擎 API 有备注或验证步骤，或故事声明
  “N/A — no engine API involved”。
- [ ] **已记录清单规则**：列出了该分层的规则，或“N/A — manifest
  not yet created”。无清单时通过。

### Scope Clarity

### 范围清晰度

- [ ] **Estimate**: hours, points or a t-shirt size. `unfilled Estimate` (still the
  template's bracket) fails. Advisory at `minimal`.
- [ ] **Out of scope stated**: an Out of Scope section, or wording that leaves the
  boundary unambiguous.
- [ ] **Dependencies listed**: each story this one needs, or "None" stated.

- [ ] **估算**：小时、点数或 T 恤尺码。`unfilled Estimate`（仍是模板的方括号）不通过。
  在 `minimal` 下为提示性。
- [ ] **已声明范围外内容**：有 Out of Scope 小节，或措辞使边界明确无歧义。
- [ ] **已列出依赖**：本故事所需的每个故事，或声明“None”。

### Open Questions

### 未决问题

- [ ] **No open markers**: no `marker` rows (TBD, TODO or UNRESOLVED as whole
  words in capitals). A `?` is not a marker: a formula like `crit ? 2 : 1` passes.
  A criterion written as an open question still fails Testable.
- [ ] **Dependencies exist and are not Draft**: a dependency story that is missing
  or `Draft` makes the story BLOCKED. `Story NNN` means that number in the same
  epic folder; a path names one exactly.

- [ ] **无未决标记**：没有 `marker` 行（以全大写单词形式出现的 TBD、TODO 或 UNRESOLVED）。
  `?` 不是标记：像 `crit ? 2 : 1` 这样的公式通过。写成未决问题的标准仍会在“可测试”项失败。
- [ ] **依赖存在且非 Draft**：依赖故事缺失或为 `Draft` 会使该故事 BLOCKED。`Story NNN`
  指同一史诗文件夹中的该编号；路径则精确指名一个。

### Asset References

### 资产引用

- [ ] **Assets the story uses exist**: paths under `assets/`, or with `.png`,
  `.jpg`, `.svg`, `.wav`, `.ogg`, `.mp3`, `.glb`, `.gltf`, `.tres`, `.tscn` or
  `.res`, that the story reads or builds on. A file the story says it will create
  (a new scene, a new data file) is not checked. Missing: NEEDS WORK; name the
  path. Report "Referenced assets verified: [N] found", or "No asset references".
  Existence only.

- [ ] **故事使用的资产存在**：`assets/` 下的路径，或带 `.png`、`.jpg`、`.svg`、`.wav`、
  `.ogg`、`.mp3`、`.glb`、`.gltf`、`.tres`、`.tscn` 或 `.res` 的路径，且为故事读取或
  在其基础上构建的内容。故事声称将创建的文件（新场景、新数据文件）不检查。缺失：NEEDS WORK；
  点明该路径。报告“已核实引用资产：找到 [N] 个”或“无资产引用”。仅检查存在性。

### Definition of Done

### 完成定义

- [ ] **Enough acceptance criteria**: no `ac_below_min` row. The minimums follow
  `story_granularity`, because `/create-stories` writes to it:

  | `story_granularity` | Logic, Integration | Visual/Feel, UI | Config/Data |
  |---|---|---|---|
  | `coarse` | 3 | 2 | 1 |
  | `balanced` | 2 | 2 | 1 |
  | `fine` | 1 | 1 | 1 |

- [ ] **Performance noted**: a story touching the gameplay loop, rendering or
  physics states a budget, or "no performance impact expected — [reason]".
- [ ] **Type declared**: no `type_missing` or `type_unknown` row. Fix: add
  `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]` to the header.
- [ ] **Test evidence clear**: a `## Test Evidence` section saying where evidence
  goes: the test file for Logic and Integration; the retained screenshot of each
  screen under `production/qa/evidence/` for UI; that plus
  `production/qa/evidence/[story-slug]-evidence.md` for Visual/Feel.
  - At `qa.level: minimal`, Logic, Integration and Config/Data pass: tests are
    waived. List no gap, and add no note, about a missing test file, `tests/`
    folder or test runner. UI and
    Visual/Feel are still checked: their screenshot is required at every level.
  - Otherwise the `gate_level` line above sets the level for the story's type.
    `blocking`: a missing section is NEEDS WORK. `advisory`: a listed gap only.
    Fix: add `## Test Evidence` with the evidence location for the story's type.

- [ ] **验收标准足够**：没有 `ac_below_min` 行。最低数量遵循 `story_granularity`，
  因为 `/create-stories` 按它写入：

  | `story_granularity` | Logic、Integration | Visual/Feel、UI | Config/Data |
  |---|---|---|---|
  | `coarse` | 3 | 2 | 1 |
  | `balanced` | 2 | 2 | 1 |
  | `fine` | 1 | 1 | 1 |

- [ ] **已注明性能**：涉及玩法循环、渲染或物理的故事声明预算，或“预计无性能影响 — [理由]”。
- [ ] **已声明类型**：没有 `type_missing` 或 `type_unknown` 行。Fix：在头部添加
  `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]`。
- [ ] **测试证据清晰**：有 `## Test Evidence` 小节说明证据去往何处：Logic 与 Integration 为
  测试文件；UI 为 `production/qa/evidence/` 下每个画面的留存截图；Visual/Feel 为截图外加
  `production/qa/evidence/[story-slug]-evidence.md`。
  - 在 `qa.level: minimal` 下，Logic、Integration 与 Config/Data 通过：测试被豁免。不要列出
    关于缺失测试文件、`tests/` 文件夹或测试运行器的缺口，也不要添加相关备注。UI 与
    Visual/Feel 仍会检查：它们的截图在每个层级都必需。
  - 否则，上方的 `gate_level` 行为该故事类型设定级别。`blocking`：缺失该小节即 NEEDS WORK。
    `advisory`：仅列为缺口。Fix：添加 `## Test Evidence`，给出该故事类型的证据位置。

## Phase 4: Verdict

## 阶段 4：判定

Apply the order at the top to each story. A BLOCKED story may also have NEEDS WORK
items: list both.

对每个故事应用开头的顺序。BLOCKED 的故事也可能有 NEEDS WORK 条目：两者都列出。

## Phase 5: QA lead review

## 阶段 5：QA 负责人评审

Read the `review_gate` line above. `skill-gates=skip` (solo or lean): skip it, and
the reply says "QL-STORY-READY skipped — [Solo | Lean] mode". `skill-gates=run`:
read `references/qa-lead-gate.md` and `.claude/docs/director-gates.md`, and run it
before reporting. On a skip, do not load it.

读取上方的 `review_gate` 行。`skill-gates=skip`（solo 或 lean）：跳过，且回复说明
“QL-STORY-READY skipped — [Solo | Lean] mode”。`skill-gates=run`：
读取 `references/qa-lead-gate.md` 与 `.claude/docs/director-gates.md`，并在报告前运行。
跳过时不要加载它。

## Phase 6: Report and close

## 阶段 6：报告并收尾

One story:

单个故事：

```
## Story Readiness: [story title]
File: [path]
Verdict: [READY / NEEDS WORK / BLOCKED / NOT ASSESSED]

### Passing Checks (N/[total])
Design Completeness: [passing items]
Architecture Completeness: [passing items, or "N/A at minimal (ADR status checked)"]
Scope Clarity: [passing items]
Open Questions: [passing items]
Asset References: [passing items, or "no asset references"]
Definition of Done: [passing items]

### Gaps
- [Checklist item]: [what is missing or wrong]
  Fix: [the text that resolves it]

### Blockers (if BLOCKED)
- [What blocks]: [the story, ADR or question that must clear first]
```

Name all six groups every time, by these exact names. A group with nothing
passing says "none — see Gaps", so the reader sees it was checked.

每次都按这六个确切名称点明全部六组。没有任何通过项的分组写“none — see Gaps”，
好让读者看出它已被检查。

Gaps lists failed checklist items only: never a passing or N/A item, and never an
observation from outside the checklist (a sprint status, another document).

Gaps 只列出未通过的清单条目：绝不列通过或 N/A 的条目，也绝不列清单之外的观察
（冲刺状态、另一份文档）。

Several stories: a summary first, then the one-story block for each story that is
not READY.

多个故事：先给摘要，然后为每个非 READY 的故事给出单故事块。

```
## Story Readiness Summary — [scope] — [date]
Ready: [N] · Needs Work: [N] · Blocked: [N] · Not Assessed: [N]

Ready: [title] ([path]), ...
Needs Work: [title]: [main gap]
Blocked: [title]: blocked by [story, ADR or question]
Not Assessed: [title]: [what could not be read]
```

`sprint` scope: when a Must Have story is not READY, put this first:
`WARNING: [N] Must Have stories are not ready to implement: [each with its main
gap]. Fix them before the sprint starts, or replan with /sprint-plan update.`

`sprint` 范围：当有 Must Have 故事未 READY 时，将此置于最前：
`WARNING: [N] Must Have stories are not ready to implement: [each with its main
gap]. Fix them before the sprint starts, or replan with /sprint-plan update.`

**Then, for one story:** look for other stories to start. In the newest plan in
`production/sprints/`, find up to 3 that are Ready or Not Started, not this one,
not waiting on unfinished dependencies, and Must Have or Should Have. List each
with a one-line description and its estimate. When there are none, say which:
`Next ready stories: no sprint file found` or `Next ready stories: none ready in
[sprint]`.

**然后，针对单个故事：** 寻找其他可开始的故事。在 `production/sprints/` 中最新计划里，
找出至多 3 个状态为 Ready 或 Not Started、不是本故事、不在等待未完成依赖、且为 Must Have
或 Should Have 的故事。每个给出一行描述与其估算。若没有，说明是哪一种：
`Next ready stories: no sprint file found` 或 `Next ready stories: none ready in
[sprint]`。

**Offer help.** Ask: "Would you like me to draft the missing parts for any of
these stories?" Options: Yes, draft them / No, that's all. On yes, draft only the
missing parts, in the conversation. The user, or `/create-stories`, writes them.

**提供帮助。** 询问：“需要我为其中任何故事起草缺失部分吗？”选项：Yes, draft them /
No, that's all。若同意，只在对话中起草缺失部分。由用户或 `/create-stories` 写入它们。

Redirects:
- Story file missing: run `/create-stories [epic-slug]` (at `standard` and
  `full`, `/create-epics` first).
- No design reference and the change is small (under about a week): run
  `/quick-design [description]` and cite that spec in the story.
- Scope grew past its sizing: split the story, or raise it with the producer.

重定向：
- 故事文件缺失：运行 `/create-stories [epic-slug]`（在 `standard` 与
  `full` 下，先 `/create-epics`）。
- 无设计参考且变更较小（约一周以内）：运行 `/quick-design [description]`，并在故事中引用该规格。
- 范围超出其原定尺寸：拆分故事，或向制作人提出。

**End the reply with:**

**以以下内容结束回复：**

```
Review: [QL-STORY-READY skipped — Solo mode | skipped — Lean mode | its verdict]
Next ready stories: [up to 3 | no sprint file found | none ready in [sprint]]   (one-story scope)
Next step: [/dev-story [path] when READY | fix the gaps above, then /story-readiness [path]]
Files changed: none
```
