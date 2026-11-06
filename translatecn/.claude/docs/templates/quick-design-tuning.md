# Quick Design Spec: [Title]
# 快速设计规格：[标题]

**Type**: Tuning
**System**: [System name]
**GDD Reference**: `design/gdd/[filename].md` — Tuning Knobs section
**Date**: [today]

**类型**：调校
**系统**：[系统名称]
**GDD 参考**：`design/gdd/[filename].md` — 调校旋钮章节
**日期**：[today]

## Change
## 改动

| Parameter | Old Value | New Value | Rationale |
|-----------|-----------|-----------|-----------|
| [param]   | [old]     | [new]     | [why]     |
| 参数 | 旧值 | 新值 | 理由 |
|-----------|-----------|-----------|-----------|
| [param]   | [old]     | [new]     | [why]     |

## Tuning Knob Mapping
## 调校旋钮映射

Maps to GDD Tuning Knob: [knob name and its documented range].
New value is [within / at the edge of / outside] the documented range.
[If outside: explain why the range should be extended.]

映射到 GDD 调校旋钮：[旋钮名称及其文档记载范围]。
新值[在 / 处于边缘 / 超出]文档记载范围。
[若超出：解释为何应扩展范围。]

## Acceptance Criteria
## 验收标准

- [ ] [Parameter] reads [new value] from `assets/data/[file]`
- [ ] Behavior difference is observable in [specific context]
- [ ] No regression in [related behavior]
- [ ] [参数] 从 `assets/data/[file]` 读取到 [new value]
- [ ] 行为差异在[特定上下文]中可观察
- [ ] [相关行为]无回归
