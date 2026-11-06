# Quick Design Spec: [Title]
# 快速设计规格：[标题]

**Type**: [Tweak / Addition]
**System**: [System name]
**GDD Reference**: `design/gdd/[filename].md`
**Date**: [today]
**类型**：[微调 / 新增]
**系统**：[系统名称]
**GDD 引用**：`design/gdd/[filename].md`
**日期**：[today]

## Change Summary
## 变更摘要

[1-2 sentences describing what changes and why.]
[1-2 句话描述变更内容及原因。]

## Motivation
## 动机

[Why is this change needed? What player experience problem does it solve?
Reference the relevant MDA aesthetic or player feedback if applicable.]
[为何需要此变更？它解决了什么玩家体验问题？
如适用，引用相关的 MDA 美学或玩家反馈。]

## Design Delta
## 设计增量

Current GDD says (quoting `design/gdd/[filename].md`, [section]):
当前 GDD 写道（引用 `design/gdd/[filename].md`，[section]）：

> [exact quote of the relevant rule or description]
> [相关规则或描述的原文引用]

This spec changes that to:
本规格将其改为：

[New rule or description, written with the same precision as a GDD Detailed
Rules section. A programmer should be able to implement from this text alone.]
[新规则或描述，以与 GDD 详细规则章节相同的精确度书写。程序员应能仅凭这段文字完成实现。]

## New Rules / Values
## 新规则 / 数值

[Full unambiguous statement of the replacement content. If this introduces
new states, list them. If it introduces new parameters, define their ranges.]
[对替换内容的完整无歧义陈述。若引入了新状态，请列出。若引入了新参数，请定义其取值范围。]

## Affected Systems
## 受影响的系统

| System | Impact | Action Required |
|--------|--------|-----------------|
| [system] | [how it is affected] | [update GDD / update data file / no action] |

| 系统 | 影响 | 需要采取的行动 |
|--------|--------|-----------------|
| [系统] | [如何受到影响] | [更新 GDD / 更新数据文件 / 无行动] |

## Acceptance Criteria
## 验收标准

- [ ] [Specific, testable criterion 1]
- [ ] [具体、可测试的标准 1]
- [ ] [Specific, testable criterion 2]
- [ ] [具体、可测试的标准 2]
- [ ] [Specific, testable criterion 3]
- [ ] [具体、可测试的标准 3]
- [ ] No regression: [the original behavior this must not break]
- [ ] 无回归：[此变更不得破坏的原有行为]

## GDD Update Required?
## 是否需要更新 GDD？

[Yes / No]
[是 / 否]
[If yes: which file, which section, and what the update should say.]
[若是：哪个文件、哪个章节，以及更新应写明什么。]
