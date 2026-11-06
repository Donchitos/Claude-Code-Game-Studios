# /gate-check — Section 3: Run the Gate Check

# /gate-check — 第 3 节：运行门禁检查

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/gate-check`。`SKILL.md` 指明了何时读取本文件；它已解析的设置，以及其后各标题下的规则，在此处仍然适用。

## 3. Run the Gate Check

## 3. 运行门禁检查

**In this file:**

**本文件包括：**

- Artifact Checks
- Quality Checks
- Cross-Reference Checks

- 产物检查
- 质量检查
- 交叉引用检查

**Before running artifact checks**, read `docs/consistency-failures.md` if it exists.
Extract entries whose Domain matches the target phase (e.g., if checking
Systems Design → Technical Setup, pull entries in Economy, Combat, or any GDD domain;
if checking Technical Setup → Pre-Production, pull entries in Architecture, Engine).
Carry these as context — recurring conflict patterns in the target domain warrant
increased scrutiny on those specific checks.

**在运行产物检查之前**，若 `docs/consistency-failures.md` 存在则先读取它。提取其中 Domain 与目标阶段相符的条目（例如，若检查 Systems Design → Technical Setup，则提取 Economy、Combat 或任何 GDD 领域的条目；若检查 Technical Setup → Pre-Production，则提取 Architecture、Engine 领域的条目）。将这些作为上下文携带——目标领域内反复出现的冲突模式值得对那些特定检查给予更高的审视。

For each item in the target gate:

对目标门禁中的每一项：

### Artifact Checks

### 产物检查

**Resolve existence and counts deterministically — do not open files to find out
what exists:**

**以确定性的方式解析存在性与计数——不要靠打开文件来弄清存在什么：**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [source-phase]
```

Pass the phase being advanced *from* (its steps are the work that must be
complete): `systems-design` for the Systems Design → Technical Setup gate,
`pre-production` for Pre-Production → Production, and so on.

传入正在*从*其推进的阶段（其步骤即必须完成的工作）：Systems Design → Technical Setup 门禁用 `systems-design`，Pre-Production → Production 用 `pre-production`，依此类推。

At `workflow: minimal`, also run
`bash .claude/scripts/artifact-check.sh --path minimal`: the brief and stories
live on that path, not on any phase, and its `game-brief` and `create-stories`
rows are this tier's floor.

在 `workflow: minimal` 下，还要运行 `bash .claude/scripts/artifact-check.sh --path minimal`：简报和故事位于该路径上，而不属于任何阶段，其 `game-brief` 与 `create-stories` 行就是本层级的下限。

It reads `workflow-catalog.yaml` — which already encodes each step's `glob`,
`pattern`, `min_count` and `any_of` — and reports per step:

它读取 `workflow-catalog.yaml`——其中已编码每个步骤的 `glob`、`pattern`、`min_count` 和 `any_of`——并按步骤报告：

| status | Meaning |
|---|---|
| `PRESENT` | glob matched, `min_count` met, `pattern` found where specified |
| `ABSENT` | nothing matched |
| `SHORT` | matched but fewer than `min_count` (`count=` and `min=` given) |
| `PATTERN_MISS` | files exist but none contains the required marker |
| `NO_CHECK` | the step declares no artifact — **not detectable from disk** |

| 状态 | 含义 |
|---|---|
| `PRESENT` | glob 匹配、满足 `min_count`、在指定处找到 `pattern` |
| `ABSENT` | 无任何匹配 |
| `SHORT` | 有匹配但少于 `min_count`（给出 `count=` 与 `min=`） |
| `PATTERN_MISS` | 文件存在但无一含有必需标记 |
| `NO_CHECK` | 该步骤未声明任何产物——**无法从磁盘检测** |

It emits observations, never a verdict: **you** apply the workflow tier and the
required/optional split from Section 2. An `ABSENT` required artifact is a
blocker at `full` and frequently not one at `minimal`; the script does not know
that and does not decide it.

它输出的是观察结果，而非裁定：**由你**应用第 2 节的工作流层级以及必需 / 可选之分。一个 `ABSENT` 的必需产物在 `full` 下是阻塞项，而在 `minimal` 下往往不是；脚本并不知道这一点，也不会替你决定。

**`NO_CHECK` is not `PRESENT`.** The header prints a `NO_CHECK:` count before any
row precisely so this cannot be skimmed past. Those steps were *scanned*, not
*satisfied* — carry each into Section 4 (Collaborative Assessment) and ask, or
mark MANUAL CHECK NEEDED. A gate that reports PASS because most of its checklist
was undetectable is the failure mode this count exists to prevent.

**`NO_CHECK` 不等于 `PRESENT`。** 表头在任何行之前先打印 `NO_CHECK:` 计数，正是为了让人无法一扫而过。那些步骤是被*扫描过*，而不是被*满足*——把每一项带入第 4 节（协作式评估）去询问，或标记为 MANUAL CHECK NEEDED。一个因为其检查清单大部分都无法检测而报告 PASS 的门禁，正是这个计数存在的目的所要防止的失败模式。

**Existence is not adequacy.** The script cannot tell a real document from a
template skeleton. So: for any artifact the verdict actually turns on, spot-read
it and confirm it has real content — the same escalation rule the
`gdd-structure-check.sh` step below uses. Do not spot-read artifacts the verdict
does not turn on.

**存在不等于充分。** 脚本无法分辨真实文档与模板骨架。因此：对于裁定实际所依赖的任何产物，都要抽读它并确认其中是真实内容——与下文 `gdd-structure-check.sh` 步骤所用的升级规则相同。不要抽读裁定并不依赖的产物。

> **A smoke report is always an artifact the verdict turns on — spot-reading it
> is mandatory, not discretionary.** At `minimal` it is frequently the *only*
> required artifact, so the whole gate rests on one file that nothing generated
> and nothing verifies. Check its claims against the repo, and raise any that the
> tree contradicts:
>
> - It reports a passing automated suite → the engine's test root must actually
>   contain test files and the project must have a runner. "24 passed, 0 failed"
>   in a repo with no test files under that root — `tests/unit/` and
>   `tests/integration/` on Godot, `Assets/Tests/` on Unity,
>   `Source/<Module>/Private/Tests/` on Unreal — and no runner is a finding, not
>   evidence.
> - It marks a critical path PASS → the code for that path must exist in the code
>   root. A PASS on "banking ends the run" with no banking code is a finding.
> - It carries no date, or predates the newest commit touching the code root →
>   say so; a stale smoke report describes a build that no longer exists.
>
> Report a contradiction at the same level the artifact was required at: a
> Blocker where the smoke check is required, CONCERNS where it is recommended.
> Existence plus a verdict-line grep would clear a fabricated report.

> **冒烟报告永远是裁定所依赖的产物——抽读它是强制性的，不是可选的。** 在 `minimal` 下，它常常是 *唯一* 必需的产物，因此整个门禁都压在一个既非任何东西生成、也无任何东西验证的文件上。将其声称与仓库对照核验，并对任何与目录树相矛盾的声称予以提报：
>
> - 它报告自动化测试套件通过 → 引擎的测试根目录中必须确实存在测试文件，且项目必须配有运行器。一个在该根目录下没有任何测试文件的仓库 — Godot 的 `tests/unit/` 与 `tests/integration/`、Unity 的 `Assets/Tests/`、Unreal 的 `Source/<Module>/Private/Tests/` — 里出现"24 passed, 0 failed"，且没有运行器，那就是一项发现，而不是证据。
> - 它把某条关键路径标为 PASS → 该路径的代码必须存在于代码根目录。在没有任何银行相关代码的情况下对"banking ends the run"给出 PASS，是一项发现。
> - 它没有日期，或早于最近一次触及代码根目录的提交 → 要指出来；一份陈旧的冒烟报告描述的是已不存在的构建。
>
> 在与该产物被要求的同一级别报告矛盾：冒烟检查为必需处报 Blocker，为建议处报 CONCERNS。存在性加一条裁定行的 grep 就足以揭穿伪造的报告。

For code checks, verify directory structure and file counts.

对于代码检查，核验目录结构与文件计数。

**Systems Design → Technical Setup gate — cross-GDD review check**:
Use `Glob('design/gdd/gdd-cross-review-*.md')` to find the `/review-all-gdds` report.
If no file matches: at `full` mark the "cross-GDD review report exists" artifact as
**FAIL** and surface it prominently ("No `/review-all-gdds` report found in
`design/gdd/`. Run `/review-all-gdds` before advancing to Technical Setup."); at
`standard` the report is recommended, so mark it **CONCERNS**, not a blocker; at
`minimal` this gate is not applicable (see the gate file). If a file is found, read it and
check the verdict line: a FAIL verdict means the cross-GDD consistency check failed
and must be resolved before advancing. A NOT ASSESSED verdict means that review
could not compare the GDDs, so it satisfies nothing here: mark the item NOT
ASSESSED for this gate, never passed.
A report whose `Focus:` line names one pass only (a `consistency` or
`design-theory` run) is treated the same way: the other pass never ran.

**Systems Design → Technical Setup 门禁——跨 GDD 评审检查**：
使用 `Glob('design/gdd/gdd-cross-review-*.md')` 查找 `/review-all-gdds` 报告。若无文件匹配：在 `full` 下将"跨 GDD 评审报告存在"这一产物标记为 **FAIL** 并显著提报（"在 `design/gdd/` 中未找到 `/review-all-gdds` 报告。在推进到 Technical Setup 之前先运行 `/review-all-gdds`。"）；在 `standard` 下该报告为建议项，因此标为 **CONCERNS**，不是阻塞项；在 `minimal` 下此门禁不适用（见门禁文件）。若找到文件，则读取并检查裁定行：FAIL 裁定意味着跨 GDD 一致性检查失败，必须在推进前解决。NOT ASSESSED 裁定意味着该次评审无法比较各 GDD，因此它在此不满足任何条件：将该项对本门禁标记为 NOT ASSESSED，绝不算通过。若报告 `Focus:` 行只指明一次评审（`consistency` 或 `design-theory` 运行），也按同样方式处理：另一次评审从未运行。

### Quality Checks

### 质量检查

- For test checks: Run the test suite via `Bash` if a test runner is configured.
  **If no runner is configured, that is `NOT ASSESSED`, not a silent skip** — see
  the trigger in the verdict section. A gate that ran no tests found no test
  failures, which is not the same as passing.
  A test failure's effect on the verdict depends on the `testing.strict` block
  **resolved in Phase 1** (`resolve_config` merges `project.local.yaml` over
  `project.yaml`; reading the file directly would drop a local override), per
  test type:
  - **Logic** — unit-level failures (`tests/unit/` on Godot, Edit Mode on
    Unity), gated by `testing.strict.logic`.
  - **Integration** — failures in `tests/integration/` on Godot, Play Mode on
    Unity, gated by `testing.strict.integration`. On Unreal, where one root
    (`Source/<Module>/Private/Tests/`) holds both, classify a failure by its
    story's Type, or apply the stricter of the two levels when that is unknown.
  - For each type: take `testing.strict.<type>` from that block; use it only
    if its value is `true` or `false` (case-insensitive). If the key is absent,
    empty, or holds any other value, read `testing.strict` as a plain boolean
    (legacy single-value form); if that too is absent or invalid, default to
    `true` (Logic and Integration are both strict by default — behavior unchanged
    from before this setting existed). Surface any unrecognized value to the user.
  - At a strict (`true`) gate level, failures of that type are **Blockers**
    (verdict FAIL). At an advisory (`false`) level, they are **Concerns**
    (verdict minimum CONCERNS, not FAIL) — list them under Recommendations, not
    Blockers.

- 对于测试检查：若配置了测试运行器，则通过 `Bash` 运行测试套件。**若未配置运行器，那就是 `NOT ASSESSED`，而不是悄悄跳过**——见裁定部分中的触发条件。一个未运行任何测试的门禁自然没有发现测试失败，这与通过并不是一回事。
  测试失败对裁定的影响取决于**在第 1 阶段解析**的 `testing.strict` 配置块（`resolve_config` 会将 `project.local.yaml` 合并覆盖到 `project.yaml` 之上；直接读取文件会丢掉本地覆盖），并按测试类型区分：
  - **Logic**——单元级失败（Godot 上的 `tests/unit/`、Unity 的 Edit Mode），由 `testing.strict.logic` 控制。
  - **Integration**——Godot 上 `tests/integration/` 中的失败、Unity 的 Play Mode，由 `testing.strict.integration` 控制。在 Unreal 上，同一个根目录（`Source/<Module>/Private/Tests/`）同时容纳两者，此时按失败所属故事的 Type 分类，若无法确定则套用两个级别中更严格的那个。
  - 对每种类型：从该配置块中取 `testing.strict.<type>`；仅当其值为 `true` 或 `false`（不区分大小写）时才使用它。若该键缺失、为空或持有任何其他值，则将 `testing.strict` 读作一个普通布尔值（旧式单值形式）；若后者同样缺失或无效，则默认为 `true`（Logic 与 Integration 默认均为严格——行为与此设置存在之前相同）。任何无法识别的值都要向用户提报。
  - 在严格（`true`）门禁级别下，该类型的失败是 **Blockers**（裁定 FAIL）。在建议（`false`）级别下，它们是 **Concerns**（裁定最低为 CONCERNS，而非 FAIL）——将其列在 Recommendations 之下，而不是 Blockers 之下。
- For design review checks, gather section presence **deterministically** — do not
  read the GDDs to count headings:

  ```
  Bash: bash .claude/scripts/gdd-structure-check.sh
  ```

  It prints a `PRESENT:` / `ABSENT:` pair per GDD, plus a `PLACEHOLDER:` line
  naming present sections that hold only `[To be designed]` (present but
  unwritten: `5-verdict.md`'s rule for template placeholders applies), and
  already accepts
  `## Detailed Design` as satisfying the `Detailed Rules` requirement. It reports
  presence only and makes no REQUIRED/ADVISORY judgment.

  Then apply each GDD's **effective tier** (per-system resolution below) to those
  lists — all 8 sections at `full`, the 5 standard sections (+ conditional
  Formulas) at `standard`. A missing *required* section blocks; a missing section
  that is optional at the effective tier is advisory. A section reported PRESENT
  can still fail review if it is an empty heading — spot-read any section the
  verdict actually turns on. Read GDDs by section: find the headings with
  the Grep tool (pattern `^#`, content mode) and Read those ranges with offset
  and limit.

- 对于设计评审检查，**以确定性的方式**收集章节存在情况——不要为统计标题而去读 GDD：

  ```
  Bash: bash .claude/scripts/gdd-structure-check.sh
  ```

  它对每个 GDD 打印一对 `PRESENT:` / `ABSENT:`，另加一行 `PLACEHOLDER:` 点名那些存在但只含 `[To be designed]` 的章节（存在但未撰写：适用 `5-verdict.md` 关于模板占位符的规则），并且已将 `## Detailed Design` 视为满足 `Detailed Rules` 要求。它只报告存在性，不做 REQUIRED/ADVISORY 判断。

  然后将每个 GDD 的**有效层级**（下文按系统解析）应用到这些列表上——`full` 下为全部 8 个章节，`standard` 下为 5 个标准章节（+ 条件性的 Formulas）。缺失的*必需*章节会阻塞；在有效层级下为可选的缺失章节则属建议性。一个被报告为 PRESENT 的章节若只是空标题，仍可能评审不通过——要点读裁定实际依赖的任何章节。按章节阅读 GDD：用 Grep 工具（pattern `^#`，content 模式）找出标题，再用 offset 与 limit 读取那些区间。
- For performance checks: read the budgets (`performance.target_framerate`,
  `frame_budget_ms`, `draw_call_limit`, `memory_ceiling_mb`) from `project.yaml`
  (else technical-preferences.md) and compare against any profiling data in
  `tests/performance/` or recent `/perf-profile` output. What a breach *means*
  is set by `performance.enforce`, taken from the Phase 1 resolved block (it is
  locally overridable, so do not read the file for this one):
  - `warn` (default) — breaches are **CONCERNS**, never Blockers.
  - `block` — breaches are **Blockers** from the Polish gate onward.
  - `off` — budgets are informational; do not surface breaches in the verdict.

  Only these three values are recognized. Surface anything else to the user and
  fall back to `warn` rather than guessing.

- 对于性能检查：从 `project.yaml`（否则 technical-preferences.md）读取预算（`performance.target_framerate`、`frame_budget_ms`、`draw_call_limit`、`memory_ceiling_mb`），并与 `tests/performance/` 中的任何剖析数据或近期的 `/perf-profile` 输出相比较。越界*意味着*什么由 `performance.enforce` 设定，取自第 1 阶段解析后的配置块（它可在本地覆盖，因此这一项不要直接读文件）：
  - `warn`（默认）——越界为 **CONCERNS**，绝不为 Blockers。
  - `block`——从 Polish 门禁起，越界为 **Blockers**。
  - `off`——预算仅供参考；不要在裁定中提报越界。

  只识别这三个值。任何其他值都要向用户提报，并回退到 `warn`，而不是臆测。
- For localization checks: `Grep` for hardcoded strings in the **code root** (resolve per `.claude/docs/code-root-resolution.md`). **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.**

- 对于本地化检查：在**代码根目录**中 `Grep` 硬编码字符串（按 `.claude/docs/code-root-resolution.md` 解析）。**若代码根目录未能解析，报告 `NOT ASSESSED — code root unresolved`，而不是零命中。**

### Cross-Reference Checks

### 交叉引用检查

- Compare `design/gdd/` documents against implementations in the **code root**
- Check that every system referenced in architecture docs has corresponding code
- Verify sprint plans reference real work items

- 将 `design/gdd/` 中的文档与**代码根目录**中的实现进行比对
- 检查架构文档中引用的每个系统都有对应的代码
- 核实冲刺计划引用的是真实的工作项

---
