# /adopt — Phase 3: Classify and Prioritise Gaps

# /adopt — 阶段 3：对缺口进行分类和排序

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/adopt` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## Phase 3: Classify and Prioritise Gaps

## 阶段 3：对缺口进行分类和排序

Organise every gap found across all audits into four severity tiers:

将所有审计中发现的每个缺口归入四个严重程度层级：

**BLOCKING** — Will cause template skills to silently produce wrong results *right now*.
Examples: ADR missing Status field, systems-index parenthetical status values,
engine not configured when ADRs exist.

**阻断** —— *现在就*会导致模板技能静默产生错误结果。示例：ADR 缺少 Status 字段、systems-index 中存在带括号的状态值、在已有 ADR 时引擎未配置。

**HIGH** — Will cause stories to be generated with missing safety checks, or
infrastructure bootstrapping will fail.
Examples: ADRs missing Engine Compatibility, GDDs missing Acceptance Criteria
(stories can't be generated from them), tr-registry.yaml missing.

**高** —— 会导致生成的故事缺少安全检查，或导致基础设施引导失败。示例：ADR 缺少 Engine Compatibility、GDD 缺少验收标准（无法从它们生成故事）、tr-registry.yaml 缺失。

**MEDIUM** — Degrades quality and pipeline tracking but does not break functionality.
Examples: GDDs missing Tuning Knobs or Formulas sections, stories missing TR-IDs,
sprint-status.yaml missing.

**中** —— 降低质量和流水线跟踪能力，但不破坏功能。示例：GDD 缺少 Tuning Knobs 或 Formulas 章节、故事缺少 TR-ID、sprint-status.yaml 缺失。

**LOW** — Retroactive improvements that are nice-to-have but not urgent.
Examples: Stories missing Manifest Version stamps, GDDs missing Open Questions section.

**低** —— 属于锦上添花但并非紧急的事后改进。示例：故事缺少 Manifest Version 版本戳、GDD 缺少 Open Questions 章节。

Count totals per tier. If zero BLOCKING and zero HIGH gaps: report that the project
is template-compatible and only advisory improvements remain.

统计每个层级的缺口总数。如果阻断和高层级缺口均为零：报告该项目与模板兼容，只剩下建议性改进。

---
