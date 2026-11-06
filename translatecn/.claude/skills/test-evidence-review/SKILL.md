---
name: test-evidence-review
description: "Quality review of test files and evidence — goes beyond existence, evaluates assertion coverage. ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED per story."
argument-hint: "[story-path | sprint | system-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/test-evidence-review/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-receipts.sh check *)
model: sonnet
---
---
name: test-evidence-review
description: "对测试文件与证据的质量评审 — 不止于存在性，还评估断言覆盖度。每个故事给出 ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED。"
argument-hint: "[story-path | sprint | system-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/test-evidence-review/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-receipts.sh check *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅重要事项 · autonomous 记录并继续；
`automation_always_ask` 类别总是提示）。

**`qa.level` and `testing.strict`** (resolved above) decide what this review may
call a blocker — the same rules `/story-done` closes stories by, so a BLOCKING
item here is one that would stop `/story-done`:
- **`qa.level: minimal`** waives tests. A Logic, Integration or Config/Data story
  with no test evidence (for Config/Data, no smoke report) is
  `WAIVED (qa.level: minimal)` — not MISSING — and raises no BLOCKING item; a
  test that does exist is still reviewed, but its gaps are ADVISORY. Visual/Feel and UI evidence (the retained screenshots, and the
  Visual/Feel sign-off) is never waived.
- **Gate level per story type**: take `testing.strict.<type>` from the resolved
  block (Logic→`logic`, Integration→`integration`, Visual/Feel→`visual`,
  UI→`ui`, Config/Data→`config`): `true` → BLOCKING, `false` → ADVISORY, `unset`
  → a plain-boolean `testing.strict: true|false` (legacy form) applies to every
  type; else the Default Gate Level in `.claude/docs/coding-standards.md`
  (BLOCKING for Logic, Integration, Visual/Feel and UI; ADVISORY for
  Config/Data). Every "BLOCKING" below means that story type's gate level.

**`qa.level` 与 `testing.strict`**（已在上述解析）决定本次评审可以把什么
称为阻断项 — 与 `/story-done` 关闭故事所用的同一套规则，因此这里的 BLOCKING
事项就是会阻止 `/story-done` 的事项：
- **`qa.level: minimal`** 豁免测试。一个没有测试证据的 Logic、Integration 或 Config/Data 故事
  （对 Config/Data 而言是没有冒烟报告）会被记为
  `WAIVED (qa.level: minimal)` — 而不是 MISSING — 且不产生 BLOCKING 事项；确实
  存在的测试仍会被评审，但其缺口为 ADVISORY。Visual/Feel 与 UI 证据（保留的截图，以及
  Visual/Feel 的签核）从不豁免。
- **按故事类型的门禁级别**：从解析块中取 `testing.strict.<type>`
  （Logic→`logic`、Integration→`integration`、Visual/Feel→`visual`、
  UI→`ui`、Config/Data→`config`）：`true` → BLOCKING，`false` → ADVISORY，`unset`
  → 适用纯布尔的 `testing.strict: true|false`（旧式写法）于每种
  类型；否则适用 `.claude/docs/coding-standards.md` 中的默认门禁级别
  （Logic、Integration、Visual/Feel 与 UI 为 BLOCKING；Config/Data 为
  ADVISORY）。下文每个 "BLOCKING" 都指该故事类型的门禁级别。

# Test Evidence Review

`/smoke-check` verifies that test files **exist** and **pass**. This skill
goes further — it reviews the **quality** of those tests and evidence documents.
A test file that exists and passes may still leave critical behaviour uncovered.
A manual evidence doc that exists may lack the sign-offs required for closure.

**Output:** Summary report (in conversation) + optional `production/qa/evidence-review-[date].md`

**When to run:**
- Before QA hand-off sign-off (`/team-qa` Phase 5)
- On any story where test quality is in question
- As part of milestone review for Logic and Integration story quality audit

# 测试证据评审

`/smoke-check` 验证测试文件**存在**且**通过**。此技能更进一步 —
它评审那些测试与证据文档的**质量**。
一个存在且通过的测试文件仍可能让关键行为未被覆盖。
一份存在的手工证据文档可能缺少关闭所需的签核。

**输出：** 摘要报告（在对话中）+ 可选的 `production/qa/evidence-review-[date].md`

**何时运行：**
- 在 QA 移交签核之前（`/team-qa` 阶段 5）
- 在任何测试质量存疑的故事上
- 作为里程碑评审的一部分，用于 Logic 与 Integration 故事的质量审计

---

## 1. Parse Arguments

**Modes:**
- `/test-evidence-review [story-path]` — review a single story's evidence
- `/test-evidence-review sprint` — review all stories in the current sprint
- `/test-evidence-review [system-name]` — review all stories in an epic/system
- No argument — ask which scope: "Single story", "Current sprint", "A system"

## 1. 解析参数

**模式：**
- `/test-evidence-review [story-path]` — 评审单个故事的证据
- `/test-evidence-review sprint` — 评审当前冲刺中的所有故事
- `/test-evidence-review [system-name]` — 评审某个史诗/系统中的所有故事
- 无参数 — 询问范围："Single story"、"Current sprint"、"A system"

---

## 2. Load Stories in Scope

Based on the argument:

**Single story**: Read the story file directly. Extract: Story Type, Test
Evidence section, story slug, system name.

**Sprint**: Read the most recently modified file in `production/sprints/`; extract
the list of story file paths from the sprint plan.

**System**: Glob `production/epics/[system-name]/story-*.md`.

## 2. 加载范围内的故事

依据参数：

**单个故事**：直接读取故事文件。提取：故事类型、测试
证据小节、故事 slug、系统名称。

**冲刺**：读取 `production/sprints/` 中最近修改的文件；从冲刺计划中提取
故事文件路径列表。

**系统**：Glob `production/epics/[system-name]/story-*.md`。

> **If the resolved scope contains ZERO stories, stop here.** Report
> `NOT ASSESSED — no stories in scope`, name which scope was searched and which
> path was empty, and route: no sprint file → `/sprint-plan new` (at `workflow: minimal`,
> which has no sprints, `/test-evidence-review [epic-slug]` instead); a sprint plan
> listing no stories → `/create-stories [epic-slug]`; a `[system-name]` glob that
> matched nothing → name the glob. Do not continue to Section 3.
>
> **Guard the empty scope, not just the per-story unknown.** The verdict
> vocabulary here — ADEQUATE / INCOMPLETE / MISSING — needs a "could not check"
> value, or an unverifiable story acquires a verdict claiming somebody verified
> it; that is what `NOT ASSESSED` is for. **But giving the per-story unknown a
> home does nothing for the empty-scope unknown.** With no stories
> the Section 6 report renders an empty Summary table and ends
> `BLOCKING items: 0 / ADVISORY items: 0` — which reads as *everything reviewed,
> all fine*. This skill gates story closure, and `coding-standards.md` marks Logic,
> Integration, Visual/Feel and UI evidence BLOCKING, so a false-clean closes stories nobody
> reviewed.

> **如果解析出的范围内故事数为零，在此停止。** 报告
> `NOT ASSESSED — no stories in scope`，点名搜索了哪个范围、哪个
> 路径为空，并路由：没有冲刺文件 → `/sprint-plan new`（在 `workflow: minimal`
> 下没有冲刺，改为 `/test-evidence-review [epic-slug]`）；冲刺计划
> 未列出任何故事 → `/create-stories [epic-slug]`；`[system-name]` 的 glob
> 什么也没匹配到 → 点名该 glob。不要继续到第 3 节。
>
> **要守护空范围，而不只是单个故事的未知。** 这里的判定
> 词汇 — ADEQUATE / INCOMPLETE / MISSING — 需要一个"无法检查"的
> 值，否则一个无法验证的故事就会获得一个声称有人验证过
> 它的判定；这正是 `NOT ASSESSED` 的用途。**但为单个故事的未知提供
> 归宿，对空范围的未知毫无帮助。** 没有故事时
> 第 6 节的报告会渲染出空的摘要表，并以
> `BLOCKING items: 0 / ADVISORY items: 0` 结束 — 读起来像是*全都评审过，
> 一切正常*。此技能是故事关闭的门禁，而 `coding-standards.md` 将 Logic、
> Integration、Visual/Feel 与 UI 证据标为 BLOCKING，因此一次虚假的干净会关闭无人
> 评审过的故事。

For the resulting story set, collect the fields below with **targeted section
greps, not a full read of each story**:
```
Grep pattern="## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 8
Grep pattern="## Acceptance Criteria" glob="production/epics/**/story-*.md" output_mode="content" -A 15
```
- **Story Type** (Logic / Integration / Visual/Feel / UI / Config/Data) and the
  stated evidence path — both live under `## Test Evidence`, so the first grep's
  `-A 8` captures them.
- Acceptance Criteria list — the `## Acceptance Criteria` block from the second grep.
- Story slug (from the file name) and System (from the directory path) — no read.
Full-read a story only when its Test Evidence section is missing or ambiguous.
(In Sprint mode, scope the globs to the sprint plan's story paths.)

对得到的故事集合，用**定向的小节 grep，而不是完整读取每个故事**来收集
以下字段：
```
Grep pattern="## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 8
Grep pattern="## Acceptance Criteria" glob="production/epics/**/story-*.md" output_mode="content" -A 15
```
- **故事类型**（Logic / Integration / Visual/Feel / UI / Config/Data）与
  声明的证据路径 — 两者都在 `## Test Evidence` 下，因此第一个 grep 的
  `-A 8` 会捕获它们。
- 验收标准列表 — 第二个 grep 得到的 `## Acceptance Criteria` 块。
- 故事 slug（来自文件名）与系统（来自目录路径）— 无需读取。
只有当故事测试证据小节缺失或含糊时，才完整读取该故事。
（在冲刺模式下，将 glob 限定到冲刺计划的故事路径。）

---

## 3. Locate Evidence Files

For each story, find the evidence. **Check the story's stated evidence path first**
— the one Section 2 captured from its `## Test Evidence` section. If it exists, use
it. Fall back to searching only when no path is stated or it is not found:

## 3. 定位证据文件

对每个故事，查找证据。**先检查故事声明的证据路径**
— 即第 2 节从其 `## Test Evidence` 小节捕获的那个。如果存在，使用
它。只有在未声明路径或未找到时才回退到搜索：

**Logic stories**: search the engine's unit-test root — `tests/unit/[system]/`
(Godot), `Assets/Tests/EditMode/` (Unity), `Source/<Module>/Private/Tests/`
(Unreal); see `.claude/docs/directory-structure.md` — for a file whose name
contains the story slug or its system. Test files are named per
`.claude/rules/test-standards.md`, not necessarily `[story-slug]_test.*`.

**Logic 故事**：搜索引擎的单元测试根 — `tests/unit/[system]/`
（Godot）、`Assets/Tests/EditMode/`（Unity）、`Source/<Module>/Private/Tests/`
（Unreal）；参见 `.claude/docs/directory-structure.md` — 查找文件名
包含故事 slug 或其系统的文件。测试文件的命名依据
`.claude/rules/test-standards.md`，不一定为 `[story-slug]_test.*`。

**Integration stories**: the same, under the integration root (`tests/integration/[system]/`,
`Assets/Tests/PlayMode/`, or Unreal's test root)
  - Also check `production/qa/playtests/` for playtest records mentioning the story

**Integration 故事**：同上，在集成根下（`tests/integration/[system]/`、
`Assets/Tests/PlayMode/`，或 Unreal 的测试根）
  - 同时检查 `production/qa/playtests/` 中提及该故事的试玩记录

**Visual/Feel and UI stories**: Glob `production/qa/evidence/` for a retained image
(`*.png`, `*.jpg`, `*.gif`) belonging to this story, and for
`[story-slug]-evidence.*`

**Visual/Feel 与 UI 故事**：Glob `production/qa/evidence/` 查找属于该故事的保留图像
（`*.png`、`*.jpg`、`*.gif`），以及
`[story-slug]-evidence.*`

**Config/Data stories**: Glob `production/qa/smoke-*.md` (any smoke check report)

**Config/Data 故事**：Glob `production/qa/smoke-*.md`（任何冒烟检查报告）

Note what was found (path) or not found (gap) for each story.

对每个故事记录找到的内容（路径）或未找到的内容（缺口）。

---

## 4. Review Automated Test Quality (Logic / Integration)

For each test file found, read it and evaluate:

### Assertion coverage

Count the number of distinct assertions (lines containing assert, expect,
check, verify, or engine-specific assertion patterns). Low assertion count is
a quality signal — a test that makes only 1 assertion per test function may
not cover the range of expected behaviour.

Thresholds:
- **3+ assertions per test function** → normal
- **1-2 assertions per test function** → note as potentially thin
- **0 assertions** (test exists but no asserts) → flag as BLOCKING (the story
  type's gate level; ADVISORY at `qa.level: minimal`) — the test passes
  vacuously and proves nothing

## 4. 评审自动化测试质量（Logic / Integration）

对找到的每个测试文件，读取并评估：

### 断言覆盖度

统计不同断言的数量（包含 assert、expect、
check、verify 或引擎特定断言模式的行）。断言数量低是一个
质量信号 — 每个测试函数只有 1 个断言的测试可能
没有覆盖预期行为的范围。

阈值：
- **每个测试函数 3+ 个断言** → 正常
- **每个测试函数 1-2 个断言** → 记为可能偏薄
- **0 个断言**（测试存在但没有断言）→ 标记为 BLOCKING（该故事
  类型的门禁级别；在 `qa.level: minimal` 下为 ADVISORY）— 该测试空洞地
  通过，什么也无法证明

### Edge case coverage

For each acceptance criterion in the story that contains a number, threshold,
or "when X happens" conditional: check whether a test function name or
test body references that specific case.

Heuristics:
- Grep test file for "zero", "max", "null", "empty", "min", "invalid",
  "boundary", "edge" — presence of any is a positive signal
- If the story has a Formulas section with specific bounds: check whether
  tests exercise at minimum/maximum values

### 边界情况覆盖度

对故事中每个包含数字、阈值
或"当 X 发生时"条件式的验收标准：检查某个测试函数名或
测试体是否引用了那个具体情形。

启发式：
- 在测试文件中 Grep "zero"、"max"、"null"、"empty"、"min"、"invalid"、
  "boundary"、"edge" — 出现其中任何一个都是正向信号
- 如果故事有带具体边界的 Formulas 小节：检查
  测试是否覆盖了最小值/最大值

### Naming quality

Test function names should describe: the scenario + the expected result.
Pattern per engine (`.claude/rules/test-standards.md`): Godot
`test_[scenario]_[expected]`, Unity `[Scenario]_[Expected]`, Unreal
`<Project>.[System].[Scenario]`.

Flag functions named generically (`test_1`, `test_run`, `testBasic`) as
**naming issues** — they make failures harder to diagnose.

### 命名质量

测试函数名应描述：场景 + 预期结果。
按引擎的模式（`.claude/rules/test-standards.md`）：Godot
`test_[scenario]_[expected]`、Unity `[Scenario]_[Expected]`、Unreal
`<Project>.[System].[Scenario]`。

将命名泛化的函数（`test_1`、`test_run`、`testBasic`）标记为
**命名问题** — 它们使失败更难诊断。

### Formula traceability

For Logic stories where the GDD has a Formulas section: check that the test
file contains at least one test whose name or comment references the formula
name or a formula value. A test that exercises a formula without mentioning
it by name is harder to maintain when the formula changes.

### 公式可追溯性

对于 GDD 含 Formulas 小节的 Logic 故事：检查测试
文件是否至少包含一个测试，其名称或注释引用了公式
名称或某个公式值。一个演练公式却不点名它的
测试，在公式变更时更难维护。

---

## 5. Review Manual Evidence Quality (Visual/Feel / UI)

For each evidence document found, read it and evaluate the checks below.

**A UI story needs no evidence document.** When it has none, its retained
screenshots are the evidence: apply only Screenshot / artefact completeness (an
image of each screen the story changes — a screen a criterion only navigates to,
such as the title screen after Quit, needs none of its own) and Date coverage (the images'
dates). A UI story is ADEQUATE on those two — never INCOMPLETE for lacking a doc,
its criterion linkage or a sign-off.

## 5. 评审手工证据质量（Visual/Feel / UI）

对找到的每份证据文档，读取并评估以下检查。

**UI 故事不需要证据文档。** 当它没有时，其保留的
截图就是证据：仅适用 截图/产物完整性（故事
改变的每个屏幕都应有一张图像 — 某项标准只是导航到的屏幕，
例如退出后的标题画面，不需要自己的图像）与 日期覆盖（图像的
日期）。UI 故事在这两项上是 ADEQUATE — 绝不因为缺少文档、
标准关联或签核而判为 INCOMPLETE。

### Criterion linkage

The evidence doc should reference each acceptance criterion from the story.
Check: does the evidence doc contain each criterion (or a clear rephrasing)?
Missing criteria mean a criterion was never verified.

### 标准关联

证据文档应引用故事中的每条验收标准。
检查：证据文档是否包含每条标准（或清晰的转述）？
缺失的标准意味着某条标准从未被验证。

### Sign-off completeness

What closes the story follows the evidence table in
`.claude/docs/coding-standards.md` — the same rule `/story-done` applies, at every
`qa.level`:
- **Visual/Feel**: the evidence doc (from the test-evidence template) must have
  every sign-off row `[x] Approved`. A blank or missing row is INCOMPLETE.
- **UI**: no sign-off is required — the retained screenshots close it. Note a
  sign-off if one exists; never mark a UI story INCOMPLETE for lacking one.

### 签核完整性

什么能关闭故事遵循 `.claude/docs/coding-standards.md` 中的证据表
— 与 `/story-done` 在每个
`qa.level` 下适用的规则相同：
- **Visual/Feel**：证据文档（来自测试证据模板）必须每
  一行签核行都是 `[x] Approved`。空白或缺失的行即 INCOMPLETE。
- **UI**：不需要签核 — 保留的截图即可关闭它。如果存在
  签核则记录；绝不因缺少签核而将 UI 故事标为 INCOMPLETE。

### Screenshot / artefact completeness

For Visual/Feel stories: Glob `production/qa/evidence/` for a retained image
(`*.png`, `*.jpg`, `*.gif`) belonging to this story. A doc that describes a
visual check but retains no image is INCOMPLETE — this gate is BLOCKING by
default, and a description is an assertion rather than evidence.

For UI stories: require the same retained screenshot of each screen touched.
A walkthrough log is welcome but not required.

### 截图/产物完整性

对于 Visual/Feel 故事：Glob `production/qa/evidence/` 查找属于该故事的保留图像
（`*.png`、`*.jpg`、`*.gif`）。一份描述视觉检查却不保留
图像的文档即 INCOMPLETE — 此门禁默认是 BLOCKING，
而描述是断言而非证据。

对于 UI 故事：要求每个所触及屏幕都有同样的保留截图。
走查日志受欢迎但非必需。

### Evidence older than its code

For each story with a retained image, run
`bash .claude/scripts/review-receipts.sh check production/qa/evidence/[story-slug]/stamp.txt`.
List each `CHANGED:` or `GONE:` file as POTENTIALLY STALE — it changed after the
evidence was captured. `RECEIPT: NONE`: say "no stamp" and use the date check
below. A report line only: it never changes the story's verdict.

### 证据早于其代码

对每个有保留图像的故事，运行
`bash .claude/scripts/review-receipts.sh check production/qa/evidence/[story-slug]/stamp.txt`。
将每个 `CHANGED:` 或 `GONE:` 文件列为 POTENTIALLY STALE — 它在
证据捕获之后发生了变更。`RECEIPT: NONE`：说明"no stamp"并使用下方的
日期检查。仅是一条报告行：它从不改变故事的判定。

### Date coverage

Evidence doc should have a date. If the date is earlier than the story's
last major change (heuristic: compare against sprint start date from the sprint
plan), flag as POTENTIALLY STALE — the evidence may not cover the final
implementation.

### 日期覆盖

证据文档应有日期。如果该日期早于故事
最后一次重大变更（启发式：与冲刺计划中的冲刺开始日期
比较），标记为 POTENTIALLY STALE — 证据可能未覆盖最终的
实现。

---

## 6. Build the Review Report

For each story, assign a verdict:

| Verdict | Meaning |
|---------|---------|
| **ADEQUATE** | Test/evidence exists, passes quality checks, all criteria covered |
| **INCOMPLETE** | Test/evidence exists but has quality gaps (thin assertions, missing sign-offs) |
| **MISSING** | No test or evidence found for a story type that requires it at this `qa.level` |
| **NOT ASSESSED** | The review could not be performed for this story — see below |
| **WAIVED (qa.level: minimal)** | A Logic, Integration or Config/Data story with no test evidence at `qa.level: minimal` — tests are not required, so nothing is missing; name it as waived |

## 6. 构建评审报告

对每个故事，指派一个判定：

| 判定 | 含义 |
|---------|---------|
| **ADEQUATE** | 测试/证据存在，通过质量检查，覆盖所有标准 |
| **INCOMPLETE** | 测试/证据存在但存在质量缺口（断言偏薄、缺少签核） |
| **MISSING** | 对在此 `qa.level` 下需要证据的故事类型，未找到任何测试或证据 |
| **NOT ASSESSED** | 无法对该故事执行评审 — 见下文 |
| **WAIVED (qa.level: minimal)** | 在 `qa.level: minimal` 下没有测试证据的 Logic、Integration 或 Config/Data 故事 — 不要求测试，因此没有缺失；将其命名为已豁免 |

> **`NOT ASSESSED` is required, and it is not a softer `MISSING`.**
> The other three verdicts all presume the review actually ran. `MISSING` means
> *I looked and there was nothing there* — a real, reportable failure. It must
> never be used for *I could not look*, which is not a finding about the story
> at all. Use `NOT ASSESSED` when:
>
> - the story's **type cannot be determined**, so the required evidence is
>   unknown (the type→evidence mapping in `.claude/docs/coding-standards.md` is
>   what makes any other verdict meaningful);
> - the evidence path is named but **unreadable or outside this run's scope**;
> - the story file itself could not be parsed.
>
> **Say which of those it was, per story.** A reader cannot act on a bare
> `NOT ASSESSED`, and the whole point of separating it from `MISSING` is that
> the two have different fixes: one needs a test written, the other needs the
> reviewer given access or the story classified.

> **`NOT ASSESSED` 是必需的，且它不是更温和的 `MISSING`。**
> 其他三种判定都预设评审确实运行了。`MISSING` 意味着
> *我看过了，那里什么也没有* — 一次真实的、可报告的失败。它绝不能
> 用于*我无法查看*，后者根本不是关于故事的发现。在以下情况使用 `NOT ASSESSED`：
>
> - 故事的**类型无法确定**，因此所需证据
>   未知（`.claude/docs/coding-standards.md` 中的类型→证据映射
>   正是使任何其他判定有意义的东西）；
> - 证据路径已点名但**不可读或超出本次运行的范围**；
> - 故事文件本身无法解析。
>
> **逐个故事说明属于哪一种。** 读者无法依据一个光秃秃的
> `NOT ASSESSED` 采取行动，而把它与 `MISSING` 区分开的全部意义
> 就在于两者的修复方式不同：一个需要撰写测试，另一个需要
> 给评审者访问权限或对故事进行分类。

The overall sprint/system verdict is the worst story verdict present, and
**`NOT ASSESSED` outranks `ADEQUATE`**: a run that could not assess part of its
scope has not established that the scope is adequate. It does not outrank
`INCOMPLETE` or `MISSING` — a known failure is more actionable than an unknown,
and demoting a real failure behind an access problem would bury it. `WAIVED`
ranks below `ADEQUATE`: the overall verdict reads WAIVED only when every story
in scope was waived, and the report names each waived story either way.

整体冲刺/系统判定是所出现的最差故事判定，且
**`NOT ASSESSED` 高于 `ADEQUATE`**：一次无法评估其部分
范围的运行，并未确立该范围是充分的。它不高于
`INCOMPLETE` 或 `MISSING` — 已知的失败比未知更可行动，
把真实失败降到访问问题之后会把它埋没。`WAIVED`
低于 `ADEQUATE`：只有当范围内每个故事都被豁免时，整体判定才读作 WAIVED，
而报告无论如何都会点名每个被豁免的故事。

> Why this matters: evidence review **gates story completion**, and
> `coding-standards.md` makes Logic, Integration, Visual/Feel and UI evidence BLOCKING. A verdict
> vocabulary with no way to express "I could not check" forces every unknown
> into one of three claims about the story — which is how a story nobody
> verified acquires a verdict that says somebody did.

> 为什么这很重要：证据评审**门禁故事完成**，而
> `coding-standards.md` 使 Logic、Integration、Visual/Feel 与 UI 证据为 BLOCKING。一个无法表达"我无法检查"的判定
> 词汇，会把每个未知都逼进关于故事的三种断言之一
> — 这正是无人验证的故事获得一个声称有人验证过的判定的方式。

```markdown
## Test Evidence Review

> **Date**: [date]
> **Scope**: [single story path | Sprint [N] | [system name]]
> **Stories reviewed**: [N]
> **Overall verdict**: ADEQUATE / INCOMPLETE / MISSING / NOT ASSESSED / WAIVED
> **qa.level**: [minimal | standard | full] — **testing.strict**: [the resolved per-type values, or "unset — coding-standards.md defaults"]

---

### Story-by-Story Results

#### [Story Title] — [Type] — [ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED/WAIVED]

**Test/evidence path**: `[path]` (found) / (not found)

**Automated test quality** *(Logic/Integration only)*:
- Assertion coverage: [N per function on average] — [adequate / thin / none]
- Edge cases: [covered / partial / not found]
- Naming: [consistent / [N] generic names flagged]
- Formula traceability: [yes / no — formula names not referenced in tests]

**Manual evidence quality** *(Visual/Feel/UI only)*:
- Criterion linkage: [N/M criteria referenced]
- Lead sign-off: [✓ approved | ✗ missing | deferred — reason] *(Visual/Feel only; a UI story needs none)*
- Artefacts: [screenshots present / missing / N/A]
- Freshness: [dated [date] — current / potentially stale]

**Issues**:
- BLOCKING: [description] *(prevents story-done)*
- ADVISORY: [description] *(should fix before release)*

---

### Summary

| Story | Type | Verdict | Issues |
|-------|------|---------|--------|
| [title] | Logic | ADEQUATE | None |
| [title] | Integration | INCOMPLETE | Thin assertions (avg 1.2/function) |
| [title] | Visual/Feel | INCOMPLETE | Lead sign-off missing |
| [title] | Logic | MISSING | No test file found |
| [title] | Logic | WAIVED | No test — waived at `qa.level: minimal` |

**BLOCKING items** (must resolve before story can be closed): [N]
**ADVISORY items** (should address before release): [N]
```

```markdown
## Test Evidence Review

> **Date**: [date]
> **Scope**: [single story path | Sprint [N] | [system name]]
> **Stories reviewed**: [N]
> **Overall verdict**: ADEQUATE / INCOMPLETE / MISSING / NOT ASSESSED / WAIVED
> **qa.level**: [minimal | standard | full] — **testing.strict**: [the resolved per-type values, or "unset — coding-standards.md defaults"]

---

### Story-by-Story Results

#### [Story Title] — [Type] — [ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED/WAIVED]

**Test/evidence path**: `[path]` (found) / (not found)

**Automated test quality** *(Logic/Integration only)*:
- Assertion coverage: [N per function on average] — [adequate / thin / none]
- Edge cases: [covered / partial / not found]
- Naming: [consistent / [N] generic names flagged]
- Formula traceability: [yes / no — formula names not referenced in tests]

**Manual evidence quality** *(Visual/Feel/UI only)*:
- Criterion linkage: [N/M criteria referenced]
- Lead sign-off: [✓ approved | ✗ missing | deferred — reason] *(Visual/Feel only; a UI story needs none)*
- Artefacts: [screenshots present / missing / N/A]
- Freshness: [dated [date] — current / potentially stale]

**Issues**:
- BLOCKING: [description] *(prevents story-done)*
- ADVISORY: [description] *(should fix before release)*

---

### Summary

| Story | Type | Verdict | Issues |
|-------|------|---------|--------|
| [title] | Logic | ADEQUATE | None |
| [title] | Integration | INCOMPLETE | Thin assertions (avg 1.2/function) |
| [title] | Visual/Feel | INCOMPLETE | Lead sign-off missing |
| [title] | Logic | MISSING | No test file found |
| [title] | Logic | WAIVED | No test — waived at `qa.level: minimal` |

**BLOCKING items** (must resolve before story can be closed): [N]
**ADVISORY items** (should address before release): [N]
```

---

## 7. Write Output (Optional)

Present the report in conversation.

Ask: "May I write this test evidence review to
`production/qa/evidence-review-[date].md`?"

This is optional — the report is useful standalone. Write only if the user
wants a persistent record.

After the report:

- For BLOCKING items: "These must be resolved before `/story-done` can mark the
  story Complete. Would you like to address any of them now?"
- For thin assertions: "Consider running `/test-helpers [system]` to see
  scaffolded assertion patterns for common cases."
- For missing sign-offs: "Manual sign-off is required from [role]. Share
  `[evidence-path]` with them to complete sign-off."

Verdict: **COMPLETE** — evidence review finished. Use CONCERNS if BLOCKING items were found.

## 7. 写入输出（可选）

在对话中呈现报告。

询问："May I write this test evidence review to
`production/qa/evidence-review-[date].md`?"

这是可选的 — 报告本身独立就有用。仅在用户
想要持久记录时才写入。

报告之后：

- 对于 BLOCKING 事项："在 `/story-done` 将故事标记为 Complete 之前，必须先解决这些事项。
  你现在想处理其中任何一项吗？"
- 对于偏薄的断言："考虑运行 `/test-helpers [system]`，查看
  常见情形的脚手架断言模式。"
- 对于缺少的签核："需要来自 [role] 的手工签核。将
  `[evidence-path]` 分享给他们以完成签核。"

Verdict: **COMPLETE** — 证据评审已完成。如发现 BLOCKING 事项，使用 CONCERNS。

---

## Collaborative Protocol

- **Report quality issues, do not fix them** — this skill reads and evaluates;
  it does not modify test files or evidence documents
- **ADEQUATE means adequate for shipping, not perfect** — avoid nitpicking
  tests that are functioning and comprehensive enough to give confidence
- **BLOCKING vs. ADVISORY distinction is important** — only flag BLOCKING when
  the gap leaves a story criterion genuinely unverified
- **Ask before writing** — the report file is optional; always confirm before writing

## 协作协议

- **报告质量问题，不要修复它们** — 此技能读取并评估；
  它不修改测试文件或证据文档
- **ADEQUATE 意味着足以发布，而非完美** — 避免对
  运行良好且足够全面、能给人信心的测试吹毛求疵
- **BLOCKING 与 ADVISORY 的区分很重要** — 只有当
  缺口使某条故事标准真正未被验证时才标为 BLOCKING
- **写入前询问** — 报告文件是可选的；写入前始终确认
