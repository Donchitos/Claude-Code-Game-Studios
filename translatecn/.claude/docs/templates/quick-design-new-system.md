# Quick Design Spec: [Title]
# 快速设计规格：[标题]

**Type**: New Small System
**Scope**: [1-2 sentence description of what this system does and doesn't do]
**Date**: [today]
**Estimated Implementation**: [hours]
**类型**：新的小型系统
**范围**：[1-2 句描述该系做什么、不做什么]
**日期**：[today]
**预计实现工时**：[小时]

## Overview
## 概述

[One paragraph a new team member could understand. What does this system do,
when does it activate, and what does it produce?]
[一段新团队成员也能理解的文字。该系统做什么、
何时激活、产出什么？]

## Core Rules
## 核心规则

[Unambiguous rules for the system. Use numbered lists for sequential behavior
and bullet lists for conditions. Be precise enough that a programmer can
implement without asking questions.]
[该系统的无歧义规则。顺序行为使用编号列表，
条件使用项目符号列表。精确到程序员可
无需提问即可实现。]

## Tuning Knobs
## 调校旋钮

| Knob | Default | Range | Category | Rationale |
|------|---------|-------|----------|-----------|
| [name] | [value] | [min–max] | [feel/curve/gate] | [why this default] |

| 旋钮 | 默认值 | 范围 | 类别 | 理由 |
|------|---------|-------|----------|-----------|
| [名称] | [值] | [最小–最大] | [手感/曲线/门槛] | [为何采用此默认值] |

All values must live in `assets/data/[appropriate-file].json`, not hardcoded.
所有数值必须存放于 `assets/data/[appropriate-file].json`，不得硬编码。

## Acceptance Criteria
## 验收标准

- [ ] [Functional criterion: does the right thing]
- [ ] [功能性标准：做正确的事]
- [ ] [Functional criterion: handles the edge case]
- [ ] [功能性标准：处理边缘情况]
- [ ] [Experiential criterion: feels right — what a playtest validates]
- [ ] [体验性标准：手感正确 —— 由试玩验证]
- [ ] [Regression criterion: does not break adjacent system]
- [ ] [回归标准：不破坏相邻系统]

## Systems Index
## 系统索引

This system is not currently in `design/gdd/systems-index.md`.
[If it should be added: suggest which layer and priority tier.]
[If it is too small to track: state "This system is below systems-index
tracking threshold — quick spec is sufficient."]
该系统目前不在 `design/gdd/systems-index.md` 中。
[若应添加：建议哪个层级和优先级档位。]
[若太小无需跟踪：注明“该系统低于 systems-index
跟踪阈值 —— 快速规格已足够。”]
