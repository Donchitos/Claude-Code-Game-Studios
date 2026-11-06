> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other five — one gate applies per invocation.

> 门禁定义，由 `/gate-check` **仅为目标阶段**加载。绝不加载其余五个——每次调用只适用一个门禁。


# Gate: Technical Setup → Pre-Production

# 门禁：Technical Setup → Pre-Production


**Required Artifacts:**

**必需产物：**

- [ ] Engine chosen (CLAUDE.md Technology Stack is not `[CHOOSE]`)
- [ ] Project config populated (`project.yaml` has engine/naming/performance set, or legacy `.claude/docs/technical-preferences.md` populated)
- [ ] Art bible exists at `design/art/art-bible.md` with at least Sections 1–4 (Visual Identity Foundation)
- [ ] At least 3 Architecture Decision Records in `docs/architecture/` covering
      Foundation-layer systems (scene management, event architecture, save/load)
- [ ] Engine reference docs exist in `docs/engine-reference/[engine]/`
- [ ] Test framework initialized: the engine's test root exists — `tests/unit/` and `tests/integration/` (Godot), `Assets/Tests/EditMode/` and `Assets/Tests/PlayMode/` (Unity), or `Source/<Module>/Private/Tests/` (Unreal); see `.claude/docs/directory-structure.md`
- [ ] CI/CD test workflow exists at `.github/workflows/tests.yml` (or equivalent)
- [ ] At least one example test file exists to confirm the framework is functional
- [ ] Master architecture document exists at `docs/architecture/architecture.md`
- [ ] Architecture traceability index exists at `docs/architecture/requirements-traceability.md`
- [ ] `/architecture-review` has been run (a review report file exists in `docs/architecture/`)
- [ ] `design/accessibility-requirements.md` exists with accessibility tier committed
- [ ] `design/ux/interaction-patterns.md` exists (pattern library initialized, even if minimal)

- [ ] 引擎已选定（CLAUDE.md 的 Technology Stack 不是 `[CHOOSE]`）
- [ ] 项目配置已填写（`project.yaml` 已设置 engine/naming/performance，或旧式的 `.claude/docs/technical-preferences.md` 已填写）
- [ ] 美术圣经存在于 `design/art/art-bible.md`，至少含第 1–4 节（Visual Identity Foundation）
- [ ] `docs/architecture/` 中至少有 3 份架构决策记录，覆盖 Foundation 层系统（场景管理、事件架构、存档/读档）
- [ ] 引擎参考文档存在于 `docs/engine-reference/[engine]/`
- [ ] 测试框架已初始化：引擎的测试根目录存在——`tests/unit/` 与 `tests/integration/`（Godot）、`Assets/Tests/EditMode/` 与 `Assets/Tests/PlayMode/`（Unity），或 `Source/<Module>/Private/Tests/`（Unreal）；见 `.claude/docs/directory-structure.md`
- [ ] CI/CD 测试工作流存在于 `.github/workflows/tests.yml`（或等价物）
- [ ] 至少存在一个示例测试文件，以确认框架可正常工作
- [ ] 总体架构文档存在于 `docs/architecture/architecture.md`
- [ ] 架构可追溯性索引存在于 `docs/architecture/requirements-traceability.md`
- [ ] `/architecture-review` 已运行（`docs/architecture/` 中存在评审报告文件）
- [ ] `design/accessibility-requirements.md` 存在且已确定无障碍层级
- [ ] `design/ux/interaction-patterns.md` 存在（模式库已初始化，即使内容很少）

**Which `/architecture-review` report counts.** Read the `Mode:` line of each
`docs/architecture/architecture-review-*.md`, and for each item below use the
newest report whose mode checked it:

**哪一份 `/architecture-review` 报告算数。** 读取每个 `docs/architecture/architecture-review-*.md` 的 `Mode:` 行，对下面每个项目使用*检查过它的最新报告*：

| Item | Modes that check it |
|---|---|
| `/architecture-review` has been run | `full` |
| Traceability matrix has zero Foundation layer gaps | `full`, `coverage`, `rtm` |
| Engine audit shows no deprecated API usage | `full`, `engine` |

| 项目 | 检查它的模式 |
|---|---|
| `/architecture-review` 已运行 | `full` |
| 可追溯性矩阵的 Foundation 层缺口为零 | `full`、`coverage`、`rtm` |
| 引擎审计显示无废弃 API 使用 | `full`、`engine` |

A `single-gdd` report saw one system and a `consistency` report only compared
ADRs, so neither counts here. When no report's mode checked an item,
that item is NOT ASSESSED, never passed on a narrower report: name the newest report's
mode and the run that closes it (run `/architecture-review full`, or the mode
the table names). A report with no `Mode:` line was written before 1.2.0 and
does not say what it checked, so it counts for none of the three, as
`/architecture-review` itself rules.

`single-gdd` 报告只看到一个系统，`consistency` 报告只比较了 ADR，因此二者在此都不算数。当没有任何报告的模式检查过某个项目时，该项目为 NOT ASSESSED，绝不能凭一份更窄的报告判为通过：点名最新报告的模式以及能了结它的那次运行（运行 `/architecture-review full`，或表中点名的模式）。没有 `Mode:` 行的报告写于 1.2.0 之前，未说明它检查了什么，因此按 `/architecture-review` 自身的规则，它对这三项都不算数。

**Quality Checks:**

**质量检查：**

- [ ] Architecture decisions cover core systems (rendering, input, state management)
- [ ] Technical preferences have naming conventions and performance budgets set
- [ ] Accessibility tier is defined and documented (even "Basic" is acceptable — undefined is not)
- [ ] At least one screen's UX spec started (often the main menu or core HUD is designed during Technical Setup)
- [ ] All ADRs have an **Engine Compatibility section** with engine version stamped
- [ ] All ADRs have a **GDD Requirements Addressed section** with explicit GDD linkage
- [ ] No ADR references APIs listed in `docs/engine-reference/[engine]/deprecated-apis.md`
- [ ] All HIGH RISK engine domains (per VERSION.md) have been explicitly addressed
      in the architecture document or flagged as open questions
- [ ] Architecture traceability matrix has **zero Foundation layer gaps**
      (all Foundation requirements must have ADR coverage before Pre-Production)

- [ ] 架构决策覆盖核心系统（渲染、输入、状态管理）
- [ ] 技术偏好已设定命名约定与性能预算
- [ ] 无障碍层级已定义并记录（即便是 "Basic" 也可接受——未定义则不可）
- [ ] 至少一个界面的 UX 规格已开始（主菜单或核心 HUD 常在 Technical Setup 期间设计）
- [ ] 所有 ADR 都有 **Engine Compatibility 章节**，并标注了引擎版本
- [ ] 所有 ADR 都有 **GDD Requirements Addressed 章节**，明确关联到 GDD
- [ ] 没有 ADR 引用 `docs/engine-reference/[engine]/deprecated-apis.md` 中列出的 API
- [ ] 所有 HIGH RISK 引擎领域（依据 VERSION.md）都已在架构文档中明确处理，或被标记为待解问题
- [ ] 架构可追溯性矩阵的 **Foundation 层缺口为零**（所有 Foundation 需求在进入 Pre-Production 之前都必须有 ADR 覆盖）

**ADR Circular Dependency Check**: run the deterministic graph builder rather than
reading every ADR to trace the graph by hand — a manual trace across a dozen ADRs
eventually misses an edge; the script cannot:

**ADR 循环依赖检查**：运行确定性的图构建器，而不是手工读取每一份 ADR 来追踪依赖图——手工追踪十几份 ADR 终究会漏掉一条边；脚本不会：
```
Bash: bash .claude/scripts/adr-dep-graph.sh
```

It prints `ADRS`, `EDGES` (one `adr-A -> adr-B` per Depends-On reference),
`NO_DEPS_SECTION` (ADRs with no Depends On), `UNFILLED_DEPS` (a Depends On row
still the template's placeholder), a `CYCLE:` line per ADR on a dependency cycle
with its edges into that cycle, `BLOCKED_BY_CYCLE` (ADRs on no cycle that depend
on one) and `ORDER` (the rest, dependencies first).

它打印 `ADRS`、`EDGES`（每条 Depends-On 引用对应一行 `adr-A -> adr-B`）、`NO_DEPS_SECTION`（没有 Depends On 的 ADR）、`UNFILLED_DEPS`（Depends On 行仍是模板占位符的 ADR）、每个处于依赖环上的 ADR 各一行 `CYCLE:` 及其进入该环的边、`BLOCKED_BY_CYCLE`（不在环上但依赖于某个环的 ADR）以及 `ORDER`（其余按依赖先行的顺序）。

- **Any `CYCLE:` lines → FAIL**: "Circular ADR dependency: [the nodes on the
  `CYCLE:` lines]. Neither can reach Accepted while the cycle exists. Remove one
  'Depends On' edge shown on a `CYCLE:` line to break the cycle." Name the
  `BLOCKED_BY_CYCLE` ADRs as waiting on the cycle, not as part of it: none of
  their own edges is the one to remove.
- No `CYCLE:` lines → this check passes. But the acyclic result is only as
  trustworthy as the dependency sections are complete: if `NO_DEPS_SECTION` or
  `UNFILLED_DEPS` lists many ADRs, surface that as a CONCERNS note rather than a
  clean pass, naming each `UNFILLED_DEPS` ADR as unfilled (what it depends on is
  unknown, not none).

- **任何 `CYCLE:` 行 → FAIL**："Circular ADR dependency: [the nodes on the `CYCLE:` lines]. Neither can reach Accepted while the cycle exists. Remove one 'Depends On' edge shown on a `CYCLE:` line to break the cycle."（循环 ADR 依赖：[`CYCLE:` 行上的节点]。只要该环存在，两者都无法达到 Accepted。移除 `CYCLE:` 行上显示的一条"Depends On"边以打破该环。）把 `BLOCKED_BY_CYCLE` 的 ADR 称为*在等待该环*，而不是环的一部分：该移除的边不是它们自己的任何一条边。
- 没有 `CYCLE:` 行 → 此检查通过。但无环结果只与依赖章节的完整程度一样可信：若 `NO_DEPS_SECTION` 或 `UNFILLED_DEPS` 列出了许多 ADR，要将其作为 CONCERNS 注记提报，而不是干净的通过，并点名每个 `UNFILLED_DEPS` ADR 为未填写（它所依赖的是未知，而不是"无"）。

**Engine Validation** (read `docs/engine-reference/[engine]/VERSION.md` first):

**引擎校验**（先读取 `docs/engine-reference/[engine]/VERSION.md`）：

- [ ] ADRs that touch post-cutoff engine APIs are flagged with Knowledge Risk: HIGH/MEDIUM
- [ ] `/architecture-review` engine audit shows no deprecated API usage
- [ ] All ADRs agree on the same engine version (no stale version references)

- [ ] 涉及 cutoff 之后引擎 API 的 ADR 已标记 Knowledge Risk: HIGH/MEDIUM
- [ ] `/architecture-review` 的引擎审计显示无废弃 API 使用
- [ ] 所有 ADR 对同一引擎版本保持一致（无陈旧的版本引用）

## Workflow tier reductions

## 工作流层级削减

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

上述检查清单是 **`full` 基线**。在较低层级，应用对应已解析层级的削减；未被点名的项目保持上述状态。削减只会 *放松* 要求——`workflow_overrides` 是唯一会新增要求的东西。

- **`full`** — engine + art bible §1–4+ + 3+ ADRs + architecture + UX specs started + accessibility doc + traceability index all required
- **`standard`** — art bible required **only if visual-asset stories exist**; ADRs reduced to **critical (Foundation-layer) only**; UX-specs-started, accessibility doc, interaction-patterns, traceability index → recommended
- **`minimal`** — only **engine configured** required (the minimal floor); everything else **drops**

- **`full`**——引擎 + 美术圣经第 1–4 节及以上 + 3 份以上 ADR + 架构文档 + UX 规格已开始 + 无障碍文档 + 可追溯性索引，全部为必需
- **`standard`**——美术圣经**仅在存在视觉资产故事时**为必需；ADR 削减为**仅关键（Foundation 层）**；UX 规格已开始、无障碍文档、交互模式、可追溯性索引 → 转为建议
- **`minimal`**——仅要求**引擎已配置**（minimal 下限）；其余全部**丢弃**
