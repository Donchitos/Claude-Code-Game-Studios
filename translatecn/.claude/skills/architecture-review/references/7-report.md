# /architecture-review — Phase 7: Output the Review Report
# /architecture-review — 阶段 7：输出评审报告

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 7: Output the Review Report
## 阶段 7：输出评审报告

```
## Architecture Review Report
Date: [date]
Mode: [full / coverage / consistency / engine / single-gdd path/to/gdd.md]
Workflow: [the resolved workflow tier]
Engine: [name + version, or "none configured"]
GDDs Reviewed: [N]
ADRs Reviewed: [M]

[the receipt — one Reviewed-Content-Hash line per review input, taken in
 Phase 8 when the report is written, never in this draft. Phase 1a's freshness
 check reads them, with the Mode and Workflow lines, on the next run]

---

### Traceability Summary
Total requirements: [N]
✅ Covered: [X]
⚠️ Partial: [Y]
❌ Gaps: [Z]

### Coverage Gaps (no ADR exists)
For each gap:
  ❌ TR-[id]: [GDD] → [system] → [requirement]
     Suggested ADR: "/architecture-decision [suggested title]"
     Domain: [Physics/Rendering/etc]
     Engine Risk: [LOW/MEDIUM/HIGH]

### Cross-ADR Conflicts
[List all conflicts from Phase 4]

### ADR Dependency Order
[Topologically sorted implementation order from Phase 4 — dependency ordering section]
[Unresolved dependencies and cycles if any]

### GDD Revision Flags
[GDD assumptions that conflict with verified engine behaviour — from Phase 5b]
[Or: "None — all GDD assumptions consistent with verified engine behaviour"]

### Engine Compatibility Issues
[List all engine issues from Phase 5]

### Architecture Document Coverage
[List missing systems and orphaned architecture from Phase 6]

---

### Verdict: [PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS: All requirements covered by **Accepted** ADRs, no conflicts, engine consistent
NOT ASSESSED: The review could not be performed over its stated scope — name why
CONCERNS: Some gaps, partial coverage, or coverage resting on `Proposed` ADRs,
      but no blocking conflicts
FAIL: Critical gaps (Foundation/Core layer requirements uncovered),
      or blocking cross-ADR conflicts detected

**`NOT ASSESSED` ranks above PASS and below CONCERNS and FAIL.** Emit it when:

- **No ADRs exist, or none could be read.** Zero requirements traced is not full
  coverage — it is an untraced architecture, and a matrix of `❌ Gap` rows at
  least says so while an empty matrix says nothing.
- **The requirement source is missing** — no `tr-registry.yaml` and no GDD
  requirements to trace *from*. A review with no left-hand column cannot report
  coverage; it can only report that it had nothing to compare.
- **An ADR is unreadable or has no `## Status`**, so its rows are `❓` and their
  coverage is unknown rather than absent.
- **Phase 6 could not run** — no `docs/architecture/architecture.md`. It must
  appear as a named `NOT ASSESSED` **line item** in the report rather than as
  absent findings. ADR traceability can still be complete, so a CONCERNS or FAIL
  finding elsewhere still stands; but in `full` mode, whose scope includes
  Phase 6, the verdict cannot be PASS — a review that could not look at part of
  its scope has not shown that part is sound, so it is NOT ASSESSED.
- **No engine is configured** (`full` and `engine` modes) — Phase 5 has no pinned
  engine reference to audit the ADRs against, and the specialist consultation was
  skipped. Record the `Engine validation: NOT ASSESSED` line item; like Phase 6
  above, it keeps the verdict from PASS.

Do not resolve any of these to PASS on the grounds that no gap was *found*. No
gap was looked for.

### Blocking Issues (must resolve before PASS)
[List items that must be resolved — FAIL verdict only]

### Required ADRs
[Prioritised list of ADRs to create, most foundational first]
```

```
## 架构评审报告
Date: [日期]
Mode: [full / coverage / consistency / engine / single-gdd path/to/gdd.md]
Workflow: [解析出的 workflow 层级]
Engine: [名称 + 版本，或 "none configured"]
GDDs Reviewed: [N]
ADRs Reviewed: [M]

[回执 — 每个评审输入一行 Reviewed-Content-Hash，在阶段 8 写报告时采集，
 绝不在本草案中采集。阶段 1a 的新鲜度检查会在下次运行时连同 Mode 和
 Workflow 行一起读取它们]

---

### 可追溯性摘要
需求总数：[N]
✅ 已覆盖：[X]
⚠️ 部分覆盖：[Y]
❌ 缺口：[Z]

### 覆盖缺口（不存在 ADR）
对每个缺口：
  ❌ TR-[id]: [GDD] → [系统] → [需求]
     建议 ADR："/architecture-decision [建议标题]"
     Domain: [Physics/Rendering/etc]
     引擎风险：[LOW/MEDIUM/HIGH]

### 跨 ADR 冲突
[列出阶段 4 的所有冲突]

### ADR 依赖顺序
[阶段 4 的拓扑排序实现顺序 — 依赖排序小节]
[未解决的依赖与循环（若有）]

### GDD 修订标记
[与已核实引擎行为相冲突的 GDD 假设 — 来自阶段 5b]
[或："None — all GDD assumptions consistent with verified engine behaviour"]

### 引擎兼容性问题
[列出阶段 5 的所有引擎问题]

### 架构文档覆盖
[列出阶段 6 的缺失系统和孤立架构]

---

### 裁决：[PASS / NOT ASSESSED / CONCERNS / FAIL]

PASS：所有需求均由 **Accepted** ADR 覆盖，无冲突，引擎一致
NOT ASSESSED：评审无法在其声明的范围内执行 — 说明原因
CONCERNS：存在一些缺口、部分覆盖，或覆盖依赖于 `Proposed` ADR，
      但没有阻塞性冲突
FAIL：存在严重缺口（Foundation/Core 层需求未覆盖），
      或检测到阻塞性的跨 ADR 冲突

**`NOT ASSESSED` 的排序高于 PASS，低于 CONCERNS 和 FAIL。** 在以下情况发出它：

- **不存在 ADR，或没有任何 ADR 可读取。** 追踪到零项需求不是完整
  覆盖 — 那是未被追踪的架构，而一张 `❌ Gap` 行的矩阵至少说明了这一点，
  一张空矩阵则什么也没说。
- **需求来源缺失** — 既没有 `tr-registry.yaml`，也没有可供*追溯*的 GDD
  需求。没有左侧列的评审无法报告覆盖；它只能报告自己没有可比对的内容。
- **某个 ADR 无法读取或没有 `## Status`**，因此其行是 `❓`，其覆盖情况
  未知而非不存在。
- **阶段 6 无法运行** — 没有 `docs/architecture/architecture.md`。它必须
  作为一条具名的 `NOT ASSESSED` **明细项**出现在报告中，而不是作为
  缺失的发现。ADR 可追溯性仍可能完整，因此别处的 CONCERNS 或 FAIL
  发现依然成立；但在范围包含阶段 6 的 `full` 模式下，裁决不能是 PASS —
  一次无法检查自身范围某部分的评审，并未证明该部分健全，因此它是
  NOT ASSESSED。
- **未配置引擎**（`full` 和 `engine` 模式）— 阶段 5 没有可用来审计 ADR 的
  固定引擎参考，且专家咨询被跳过。记录 `Engine validation: NOT ASSESSED`
  明细项；如同上面的阶段 6，它使裁决不能为 PASS。

不要以"未*发现*缺口"为由把上述任何一项裁定为 PASS。因为根本没有
去找缺口。

### 阻塞问题（PASS 前必须解决）
[列出必须解决的条目 — 仅 FAIL 裁决时]

### 必要 ADR
[待创建 ADR 的优先级清单，最基础的排在最前]
```

---
