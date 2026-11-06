---
name: code-review
description: "Architectural code review — coding standards, SOLID, testability, performance concerns."
argument-hint: "[path-to-file-or-directory]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Agent, AskUserQuestion, Bash(bash "*/.claude/skills/code-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: code-review
description: "架构级代码评审 — 编码规范、SOLID、可测试性、性能关注点。"
argument-hint: "[path-to-file-or-directory]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git log *), Agent, AskUserQuestion, Bash(bash "*/.claude/skills/code-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

# Code Review

# 代码评审



Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅重大事项 · 自主模式记录并继续；
`automation_always_ask` 类别始终提示）。

## Insufficient input — check this before producing any report

## 输入不足 — 在生成任何报告之前先检查

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

**如果本技能所需的输入不存在，答案就是"无法运行" —
而不是一份填好的报告。** 先检查，检查失败就停止。

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

1. 列出本技能读取的输入（数据文件、既有报告、性能分析器输出、
   测试结果、注册表、源代码）。
2. 对每一项记录 `FOUND` 或 `ABSENT` — 而不是"假定存在"。
3. 如果某章节所需的任一输入为 ABSENT，该章节即为
   **`NOT ASSESSED — NO DATA`**。不要估算它，不要从相邻产物推断它，
   也不要留下一个强制单元格等着下一个读模板的人来填。
4. 如果**所有**必需输入都是 ABSENT，就停止，并将
   **`NOT ASSESSED — NO DATA`** 作为整体结论报告，同时指明缺了什么以及
   由哪个技能产出它。

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.

**`NOT ASSESSED` 的结论是一种成功。** 当没有数据时，它是对
"数据说了什么？"这一问题的正确且有用的回答。它防止的失败模式很具体：
一个结论枚举中没有"无法运行"状态的报告会产生
**虚假的干净通过** — 资产审计在一个没有资产、也没有标准的项目上返回 COMPLIANT，
或者性能剖析在零剖析器数据、且从未设定预算的情况下报告"相对 16.67ms 预算有 >99% 余量"。

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

**缺乏证据从来不是不存在的证据。** 一次因为没有文件可扫描而找不到任何匹配的扫描，
并没有验证任何东西。要说明这两种情况中实际发生的是哪一种 —
读者无法从绿色结果中分辨。

---

## Phase 1: Load Target Files

## 阶段 1：加载目标文件

Read the target file(s) in full. Read CLAUDE.md for project coding standards.

完整读取目标文件。读取 CLAUDE.md 以获取项目编码规范。

---

## Phase 2: Identify Engine Specialists

## 阶段 2：识别引擎专家

Read the `specialists` block from `project.yaml`; if it is absent, fall back to the `## Engine Specialists` section of `.claude/docs/technical-preferences.md`. Note:

从 `project.yaml` 读取 `specialists` 块；若不存在，则回退到 `.claude/docs/technical-preferences.md` 的 `## Engine Specialists` 章节。注意：

- The **Primary** specialist — `<engine>-specialist` derived from `engine.name` (Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`); used for architecture and broad engine concerns
- The **Language/Code Specialist** — `specialists.code` — used when reviewing the project's primary language files
- The **Shader Specialist** — `specialists.shader` — used when reviewing shader files
- The **UI Specialist** — `specialists.ui` — used when reviewing UI code

- **主**专家 — 由 `engine.name` 推导出的 `<engine>-specialist`（Godot→`godot-specialist`，Unity→`unity-specialist`，Unreal→`unreal-specialist`）；用于架构和广泛的引擎关注点
- **语言/代码专家** — `specialists.code` — 在评审项目的主要语言文件时使用
- **着色器专家** — `specialists.shader` — 在评审着色器文件时使用
- **UI 专家** — `specialists.ui` — 在评审 UI 代码时使用

**A value of `null` means UNSET — treat that key as absent and skip its
specialist. Never spawn it as an agent name.** The v1.0 migration writes `null`
for any specialist the legacy file did not name, and it writes the whole block
whenever *one* member is set — so a project that configured only its code
specialist carries `shader: null` and `ui: null`. The config reader returns the
four-character string `"null"` for these, which is not empty and therefore reads
as configured. `null`, empty, and missing are the same state here.

**值为 `null` 意味着未设置 — 将该键视为不存在并跳过其
专家。绝不要把它当作智能体名称来派生。** v1.0 迁移会为旧文件中未命名的任何专家写入 `null`，
并且只要设置*一个*成员就会写入整个块 — 因此一个只配置了代码专家的项目
会带有 `shader: null` 和 `ui: null`。配置读取器会为这些返回
四字符字符串 `"null"`，它不是空值，因此会被读作已配置。`null`、空值和缺失在此处是同一状态。

If no engine is configured (no `engine.name` in `project.yaml`, and `technical-preferences.md` reads `[TO BE CONFIGURED]` or is missing), skip engine specialist steps. **Record ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)`` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell engine guidance was never sought.

如果未配置引擎（`project.yaml` 中没有 `engine.name`，且 `technical-preferences.md` 内容为 `[TO BE CONFIGURED]` 或缺失），跳过引擎专家步骤。**在本次运行的输出中记录 ``Engine validation: NOT ASSESSED — no engine configured (`engine.name` unset in `project.yaml`)``。** 一项什么都不说的跳过检查与一项通过的检查无法区分；读者无法分辨从未寻求过引擎指导。

---

## Phase 3: ADR Compliance Check

## 阶段 3：ADR 符合性检查

**Argument:** `/code-review [file(s)]` may optionally include a story file path as the last argument (e.g., `/code-review Assets/Scripts/Combat/Attack.cs production/epics/combat/story-001.md`). If a story path is provided, read it to extract the governing ADR reference.

**参数：** `/code-review [file(s)]` 可选择性地把故事文件路径作为最后一个参数（例如 `/code-review Assets/Scripts/Combat/Attack.cs production/epics/combat/story-001.md`）。如果提供了故事路径，读取它以提取管辖的 ADR 引用。

Search for ADR references in, in priority order:
1. The story file (if provided as argument)
2. Header comments at the top of the implementation files
3. Commit messages referencing these files (`git log --oneline -- [file]`)

按优先级顺序搜索 ADR 引用：
1. 故事文件（若作为参数提供）
2. 实现文件顶部的头部注释
3. 引用这些文件的提交信息（`git log --oneline -- [file]`）

Look for patterns like `ADR-NNNN` or `docs/architecture/adr-` (either case).

查找诸如 `ADR-NNNN` 或 `docs/architecture/adr-` 的模式（不区分大小写）。

If no ADR references found, note: "No ADR references found — ADR compliance check skipped. For full ADR compliance review, provide the story path: `/code-review [files] [story-path]`."

如果未找到 ADR 引用，注明："No ADR references found — ADR compliance check skipped. For full ADR compliance review, provide the story path: `/code-review [files] [story-path]`."

For each referenced ADR, load **only the sections this check needs — never an unbounded full read.** A substantial ADR exceeds the 25k-token `Read` cap, and a capped read's only recovery is paging the remainder — the most expensive way to read a file. Use the same pattern as `/dev-story` and `/create-stories`:

对每个被引用的 ADR，只加载**本检查所需的章节 — 绝不进行无界的完整读取。** 一份内容充实的 ADR 会超出 25k token 的 `Read` 上限，而被截断的读取唯一补救方式是分页读取剩余部分 —
这是读取文件最昂贵的方式。使用与 `/dev-story` 和 `/create-stories` 相同的模式：

1. **Map the headings** (cheap — line numbers only): `Grep pattern="^## " path="[adr-file]" output_mode="content" -n`
2. **Bounded-read only `## Decision` and `## Consequences`**, using the line numbers to set `Read(offset, limit)` spans that end where the next heading begins. If the heading map is empty (a nonstandard ADR predating the template), fall back to one full `Read`; if that truncates at the cap, grep for the decision/consequence content directly rather than paging the remainder.

1. **映射标题**（廉价 — 仅行号）：`Grep pattern="^## " path="[adr-file]" output_mode="content" -n`
2. **仅对 `## Decision` 和 `## Consequences` 进行有界读取**，用行号设置 `Read(offset, limit)` 区间，使其在下一个标题开始处结束。如果标题映射为空（早于模板的非标准 ADR），回退为一次完整 `Read`；若它在上限处被截断，就直接 grep 决策/后果内容，而不是分页读取剩余部分。

A referenced ADR whose file is missing, or that cannot be read, makes ADR
Compliance `NOT ASSESSED — [ADR] could not be read`: name it. No reference at
all is `NO ADRS FOUND`, a different result.

被引用但其文件缺失、或无法读取的 ADR，会使 ADR
符合性为 `NOT ASSESSED — [ADR] could not be read`：要指明它。完全没有任何引用
则是 `NO ADRS FOUND`，这是不同的结果。

From those two sections, classify any deviation:

根据这两个章节，对任何偏离进行分类：

- **ARCHITECTURAL VIOLATION** (BLOCKING): Uses a pattern explicitly rejected in the ADR
- **ADR DRIFT** (WARNING): Meaningfully diverges from the chosen approach without using a forbidden pattern
- **MINOR DEVIATION** (INFO): Small difference from ADR guidance that doesn't affect overall architecture

- **ARCHITECTURAL VIOLATION**（阻断）：使用了 ADR 中明确拒绝的模式
- **ADR DRIFT**（警告）：实质性地偏离所选方案，但未使用被禁止的模式
- **MINOR DEVIATION**（信息）：与 ADR 指导的细微差异，不影响整体架构

---

## Phase 4: Standards Compliance

## 阶段 4：规范符合性

Identify the system category (engine, gameplay, AI, networking, UI, tools) and evaluate:

识别系统类别（引擎、玩法、AI、网络、UI、工具）并评估：

- [ ] Public methods and classes have doc comments
- [ ] Cyclomatic complexity under 10 per method
- [ ] No method exceeds 40 lines (excluding data declarations)
- [ ] Dependencies are injected (no static singletons for game state)
- [ ] Configuration values loaded from data files
- [ ] Systems expose interfaces (not concrete class dependencies)

- [ ] 公共方法和类具有文档注释
- [ ] 每个方法的圈复杂度低于 10
- [ ] 没有方法超过 40 行（不含数据声明）
- [ ] 依赖通过注入提供（游戏状态不使用静态单例）
- [ ] 配置值从数据文件加载
- [ ] 系统暴露接口（而非依赖具体类）

---

## Phase 5: Architecture and SOLID

## 阶段 5：架构与 SOLID

**Architecture:**
- [ ] Correct dependency direction (engine <- gameplay, not reverse)
- [ ] No circular dependencies between modules
- [ ] Proper layer separation (UI does not own game state)
- [ ] Events/signals used for cross-system communication
- [ ] Consistent with established patterns in the codebase

**架构：**
- [ ] 依赖方向正确（引擎 <- 玩法，而非反向）
- [ ] 模块之间没有循环依赖
- [ ] 分层恰当（UI 不拥有游戏状态）
- [ ] 使用事件/信号进行跨系统通信
- [ ] 与代码库中既有的模式保持一致

**SOLID:**
- [ ] Single Responsibility: Each class has one reason to change
- [ ] Open/Closed: Extendable without modification
- [ ] Liskov Substitution: Subtypes substitutable for base types
- [ ] Interface Segregation: No fat interfaces
- [ ] Dependency Inversion: Depends on abstractions, not concretions

**SOLID：**
- [ ] 单一职责：每个类只有一个变更理由
- [ ] 开闭原则：无需修改即可扩展
- [ ] 里氏替换：子类型可替换基类型
- [ ] 接口隔离：没有臃肿接口
- [ ] 依赖倒置：依赖抽象，而非具体实现

---

## Phase 6: Game-Specific Concerns

## 阶段 6：游戏特定关注点

- [ ] Frame-rate independence (delta time usage)
- [ ] No allocations in hot paths (update loops)
- [ ] Proper null/empty state handling
- [ ] Thread safety where required
- [ ] Resource cleanup (no leaks)

- [ ] 帧率无关（使用 delta time）
- [ ] 热路径（更新循环）中无内存分配
- [ ] 恰当处理 null/空状态
- [ ] 在需要处保证线程安全
- [ ] 资源清理（无泄漏）

---

## Phase 7: Specialist Reviews (Parallel)

## 阶段 7：专家评审（并行）

Spawn all applicable specialists simultaneously via `Agent` — do not wait for one before starting the next.

通过 `Agent` 同时派生所有适用的专家 — 不要在启动下一个之前等待一个完成。

> **Verify every specialist finding before reporting it. Do not pass findings
> through unchecked.** For each finding, record in the report:
>
> - **File and line** it refers to.
> - **Evidence** — the quoted code, or the concrete input/state that triggers it.
> - **Confidence** — `VERIFIED` (you checked it yourself) or `UNVERIFIED —
>   specialist claim` (you could not).
>
> A finding you could not verify is reported as unverified or dropped, never
> promoted to a defect on the strength of confident phrasing.
>
> **Why this is mandatory.** Agents are reliable when deriving and unreliable when
> diagnosing existing code: a **wrong** claim about a short function can be fluent
> enough to pass a skim, and a claimed bug can fall apart once you enumerate the
> inputs. Without this step the parent review is a laundering channel: a guess
> enters as a specialist finding and leaves as a reviewed defect.

> **在报告每一条专家发现之前都要核实它。不要未经检查地放行发现。**
> 对每条发现，在报告中记录：
>
> - 它所指向的**文件与行号**。
> - **证据** — 引用的代码，或触发它的具体输入/状态。
> - **置信度** — `VERIFIED`（你自己检查过）或 `UNVERIFIED —
>   specialist claim`（你没能检查）。
>
> 你无法核实的发现要么作为未核实报告，要么丢弃，绝不
> 仅凭自信的措辞就将其提升为缺陷。
>
> **为什么这是强制性的。** 智能体在推导时可靠，在诊断既有代码时不可靠：
> 一个关于短函数的**错误**论断可以流畅到足以通过略读，而一旦枚举输入，
> 一个声称的缺陷就可能站不住脚。没有这一步，父级评审就成了一条洗白通道：
> 一个猜测以专家发现的身份进入，却以已评审缺陷的身份离开。

### Engine Specialists

### 引擎专家

If an engine is configured, determine which specialist applies to each file and spawn in parallel:

如果配置了引擎，确定每个文件适用哪位专家并并行派生：

- Primary language files (`.gd`, `.cs`, `.cpp`) → Language/Code Specialist
- Shader files (`.gdshader`, `.hlsl`, shader graph) → Shader Specialist
- UI screen/widget code → UI Specialist
- Cross-cutting or unclear → Primary Specialist

- 主要语言文件（`.gd`、`.cs`、`.cpp`）→ 语言/代码专家
- 着色器文件（`.gdshader`、`.hlsl`、着色器图）→ 着色器专家
- UI 界面/控件代码 → UI 专家
- 横切或不清楚 → 主专家

Also spawn the **Primary Specialist** for any file touching engine architecture (scene structure, node hierarchy, lifecycle hooks).

对任何触及引擎架构（场景结构、节点层级、生命周期钩子）的文件，也要派生**主专家**。

### QA Testability Review

### QA 可测试性评审

For Logic and Integration stories, also spawn `qa-tester` via `Agent` in parallel with the engine specialists. Pass:
- The implementation files being reviewed
- The story's `## QA Test Cases` section (the pre-written test specs from qa-lead)
- The story's `## Acceptance Criteria`

对于逻辑与集成故事，还要通过 `Agent` 与引擎专家并行派生 `qa-tester`。传入：
- 正在评审的实现文件
- 故事的 `## QA Test Cases` 章节（来自 qa-lead 的预写测试规格）
- 故事的 `## Acceptance Criteria`

Ask the qa-tester to evaluate:
- [ ] Are all test hooks and interfaces exposed (not hidden behind private/internal access)?
- [ ] Do the QA test cases from the story's `## QA Test Cases` section map to testable code paths?
- [ ] Are any acceptance criteria untestable as implemented (e.g., hardcoded values, no seam for injection)?
- [ ] Does the implementation introduce any new edge cases not covered by the existing QA test cases?
- [ ] Are there any observable side effects that should have a test but don't?

请 qa-tester 评估：
- [ ] 所有测试钩子和接口是否已暴露（未被隐藏在 private/internal 访问之后）？
- [ ] 故事 `## QA Test Cases` 章节中的 QA 测试用例是否映射到可测试的代码路径？
- [ ] 是否有任何验收标准按当前实现无法测试（例如硬编码值、没有注入接缝）？
- [ ] 实现是否引入了既有 QA 测试用例未覆盖的新边界情况？
- [ ] 是否有任何可观察的副作用本应有测试却没有？

For Visual/Feel and UI stories: qa-tester reviews whether the manual verification steps in `## QA Test Cases` are achievable with the implementation as written — e.g., "is the state the manual checker needs to reach actually reachable?"

对于视觉/手感与 UI 故事：qa-tester 评审 `## QA Test Cases` 中的手动验证步骤在按当前编写的实现下是否可达成 — 例如，"手动检查者需要达到的状态是否真的可达？"

Collect all specialist findings before producing output.

在生成输出之前收集所有专家发现。

---

## Phase 8: Output Review

## 阶段 8：输出评审

```
## Code Review: [File/System Name]

### Engine Specialist Findings: [N/A — no engine configured / CLEAN / ISSUES FOUND]
[Findings from engine specialist(s), or "No engine configured." if skipped]

### Testability: [N/A — no story path given / N/A — Visual/Feel or Config story / TESTABLE / GAPS / BLOCKING]
[qa-tester findings: test hooks, coverage gaps, untestable paths, new edge cases]
[If BLOCKING: implementation must expose [X] before tests in ## QA Test Cases can run]

### ADR Compliance: [NOT ASSESSED / NO ADRS FOUND / COMPLIANT / DRIFT / VIOLATION]
[List each ADR checked, result, and any deviations with severity]

### Standards Compliance: [X/6 passing]
[List failures with line references; a missing doc comment names the method or class]

### Architecture: [NOT ASSESSED / CLEAN / MINOR ISSUES / VIOLATIONS FOUND]
[List specific architectural concerns]

### SOLID: [NOT ASSESSED / COMPLIANT / ISSUES FOUND]
[List specific violations]

### Game-Specific Concerns
[List game development specific issues]

### Positive Observations
[What is done well -- always include this section]

### Required Changes
[Must-fix items before approval — ARCHITECTURAL VIOLATIONs always appear here]

### Suggestions
[Nice-to-have improvements]

### Verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]
```

Choose the verdict, first match wins:
- **CHANGES REQUIRED** — anything under Required Changes
- **NOT ASSESSED** — nothing to review (the no-data path above), the engine
  specialist review did not run — no engine configured, or a specialist that
  could not be spawned — or any report section reads `NOT ASSESSED` (ADR
  Compliance with a referenced ADR that could not be read, Architecture, SOLID);
  name which. NOT ASSESSED ranks below CHANGES REQUIRED, because a known
  defect is more actionable than a skipped check, and above both approvals: a
  review that skipped the engine check has not approved the code. (`NO ADRS
  FOUND` is not NOT ASSESSED: with no ADR to check, it does not stop an
  approval.)
- **APPROVED WITH SUGGESTIONS** — only Suggestions
- **APPROVED** — no required changes and no suggestions

选择结论，最先匹配者胜出：
- **CHANGES REQUIRED** — 必需变更下有任何条目
- **NOT ASSESSED** — 无可评审内容（上述无数据路径），引擎
  专家评审未运行 — 未配置引擎，或某个专家无法派生 — 或任何报告章节读作 `NOT ASSESSED`
  （ADR 符合性中某个被引用的 ADR 无法读取，架构，SOLID）；
  指明是哪一项。NOT ASSESSED 排在 CHANGES REQUIRED 之下，因为已知
  缺陷比跳过的检查更可行动，而排在两种批准之上：一次
  跳过了引擎检查的评审并没有批准代码。（`NO ADRS
  FOUND` 不是 NOT ASSESSED：没有 ADR 可检查时，它不会阻止
  批准。）
- **APPROVED WITH SUGGESTIONS** — 仅有建议
- **APPROVED** — 没有必需变更也没有建议

This skill is read-only — no files are written.

本技能为只读 — 不写入任何文件。

---

## Phase 9: Next Steps

## 阶段 9：后续步骤

Use `AskUserQuestion`:
- Prompt: "Code review complete — verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]. How would you like to proceed?" (the Phase 8 verdict, word for word)
- Options (adjust based on verdict):
  - If APPROVED:
    - `[A] Run /story-done to mark the story complete`
    - `[B] Stop here`
  - If APPROVED WITH SUGGESTIONS:
    - `[A] Apply the suggestions, then run /story-done`
    - `[B] Run /story-done now — suggestions noted for later`
    - `[C] Stop here`
  - If CHANGES REQUIRED:
    - `[A] Fix the issues and re-run /code-review`
    - `[B] Run /story-done anyway with noted exceptions`
    - `[C] Stop here`
  - If NOT ASSESSED:
    - `[A] Fix what stopped the review (point me at the code, run /setup-engine, or fix the unreadable ADR reference), then re-run /code-review`
    - `[B] Stop here`

使用 `AskUserQuestion`：
- 提示："Code review complete — verdict: [NOT ASSESSED / APPROVED / APPROVED WITH SUGGESTIONS / CHANGES REQUIRED]. How would you like to proceed?"（第 8 阶段的结论，逐字不变）
- 选项（根据结论调整）：
  - 若为 APPROVED：
    - `[A] Run /story-done to mark the story complete`
    - `[B] Stop here`
  - 若为 APPROVED WITH SUGGESTIONS：
    - `[A] Apply the suggestions, then run /story-done`
    - `[B] Run /story-done now — suggestions noted for later`
    - `[C] Stop here`
  - 若为 CHANGES REQUIRED：
    - `[A] Fix the issues and re-run /code-review`
    - `[B] Run /story-done anyway with noted exceptions`
    - `[C] Stop here`
  - 若为 NOT ASSESSED：
    - `[A] Fix what stopped the review (point me at the code, run /setup-engine, or fix the unreadable ADR reference), then re-run /code-review`
    - `[B] Stop here`

If an ARCHITECTURAL VIOLATION is found:
- If the violation contradicts an **existing ADR**: fix the implementation to comply with `docs/architecture/[adr-file].md`. If the design has legitimately changed, run `/architecture-decision` to formally *revise* the existing ADR — do not create a competing one.
- If **no ADR exists** for the pattern that was violated: run `/architecture-decision` to document the correct approach before fixing the code.

如果发现 ARCHITECTURAL VIOLATION：
- 如果违规与**既有 ADR** 相矛盾：修改实现以符合 `docs/architecture/[adr-file].md`。如果设计已合理地变化，运行 `/architecture-decision` 来正式*修订*既有 ADR — 不要创建一份相互竞争的 ADR。
- 如果被违反的模式**没有 ADR**：先运行 `/architecture-decision` 记录正确方案，再修改代码。
