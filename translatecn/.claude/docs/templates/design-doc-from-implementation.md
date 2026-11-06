# [System Name] — Design Document
# [系统名称] — 设计文档

---
**Status**: Reverse-Documented
**Source**: `[path to implementation code]`
**Date**: [YYYY-MM-DD]
**Verified By**: [User name or "pending review"]
**Implementation Status**: [Fully implemented | Partially implemented | Needs extension]
---
**状态**：逆向文档化
**来源**：`[实现代码路径]`
**日期**：[YYYY-MM-DD]
**验证者**：[用户名或“待审核”]
**实现状态**：[完全实现 | 部分实现 | 需要扩展]
---

> **⚠️ Reverse-Documentation Notice**
>
> This design document was created **after** the implementation already existed.
> It captures current behavior and clarified design intent based on code analysis
> and user consultation. Some sections may be incomplete where implementation is
> partial or design intent was unclear during reverse-engineering.
> **⚠️ 逆向文档化说明**
>
> 本设计文档是在实现**已经存在之后**创建的。
> 它基于代码分析和用户咨询，记录当前行为与澄清后的设计意图。
> 当实现不完整、或逆向工程期间设计意图不清晰时，部分章节可能不完整。

---

## Summary
## 摘要

[2–3 sentences: what this system is, what it does for the player, why it
exists — inferred from code; mark `[inferred — confirm]`]
[2–3 句话：此系统是什么、它为玩家做什么、为何存在 — 从代码推断；标记 `[推断 — 待确认]`]

---

## 1. Overview
## 1. 概述

**Purpose**: [What problem does this system solve?]
**目的**：[此系统解决什么问题？]

**Scope**: [What is included/excluded from this system?]
**范围**：[此系统包含/排除什么？]

**Current Implementation**: [Brief description of what exists in code]
**当前实现**：[对代码中现有内容的简要描述]

**Design Intent** (clarified):
- [Intent 1 — why this feature exists]
- [Intent 2 — what player experience it creates]
- [Intent 3 — how it fits into overall game pillars]
**设计意图**（已澄清）：
- [意图 1 — 此功能为何存在]
- [意图 2 — 它创造了什么玩家体验]
- [意图 3 — 它如何契合整体游戏支柱]

---

## 2. Player Fantasy
## 2. 玩家幻想

[What the player should FEEL when using this system. Code does not record this:
infer it from the player-facing effects above, then CONFIRM it with the designer
and mark it `[inferred — confirm]` until they do.]
[玩家使用此系统时应该**感受**到什么。代码不会记录这一点：
从上述面向玩家的效果中推断，然后与设计师**确认**，在确认之前标记为 `[推断 — 待确认]`。]

---

## 3. Detailed Design
## 3. 详细设计

### 3.1 Core Mechanics
### 3.1 核心机制

[Describe the mechanics as implemented, organized clearly]
[按实现现状描述机制，条理清晰地组织]

**[Mechanic 1 Name]**:
- **Description**: [What it does]
- **Implementation**: [How it works in code]
- **Design Rationale**: [Why it exists — from user clarification]
- **Player-Facing**: [How players experience this]
**[机制 1 名称]**：
- **描述**：[它做什么]
- **实现**：[它在代码中如何运作]
- **设计依据**：[它为何存在 — 来自用户澄清]
- **玩家可感知**：[玩家如何体验它]

**[Mechanic 2 Name]**:
- **Description**: [What it does]
- **Implementation**: [How it works]
- **Design Rationale**: [Why it exists]
- **Player-Facing**: [Player experience]
**[机制 2 名称]**：
- **描述**：[它做什么]
- **实现**：[它如何运作]
- **设计依据**：[它为何存在]
- **玩家可感知**：[玩家体验]

### 3.2 State and Data
### 3.2 状态与数据

**Data Structures** (from code):
- [Data structure 1]: `[fields/properties]`
- [Data structure 2]: `[fields/properties]`
**数据结构**（来自代码）：
- [数据结构 1]：`[字段/属性]`
- [数据结构 2]：`[字段/属性]`

**State Machines** (if applicable):
```
[State diagram or list of states and transitions]
```
**状态机**（如适用）：
```
[状态图，或状态与转换列表]
```

**Persistence**:
- Saved: [What is saved to player save file]
- Not saved: [What is session-only or recalculated]
**持久化**：
- 已保存：[写入玩家存档文件的内容]
- 未保存：[仅会话期间存在或重新计算的内容]

### 3.3 Integration Points
### 3.3 集成点

**Dependencies** (systems this depends on):
- [System 1]: [What it provides]
- [System 2]: [What it provides]
**依赖**（此系统所依赖的系统）：
- [系统 1]：[它提供什么]
- [系统 2]：[它提供什么]

**Dependents** (systems that depend on this):
- [System 3]: [How it uses this system]
- [System 4]: [How it uses this system]
**被依赖方**（依赖此系统的系统）：
- [系统 3]：[它如何使用此系统]
- [系统 4]：[它如何使用此系统]

**API Surface** (public interface):
- [Method/Function 1]: [Purpose]
- [Method/Function 2]: [Purpose]
**API 接口面**（公共接口）：
- [方法/函数 1]：[用途]
- [方法/函数 2]：[用途]

---

## 4. Formulas
## 4. 公式

**Formulas Discovered in Code**:
**代码中发现的公式**：

| Formula | Expression | Purpose | Verified? |
|---------|-----------|---------|-----------|
| [Formula 1] | `[mathematical expression]` | [What it calculates] | ✅ / ⚠️ needs tuning |
| [Formula 2] | `[expression]` | [Purpose] | ✅ / ⚠️ needs tuning |

| 公式 | 表达式 | 用途 | 已验证？ |
|---------|-----------|---------|-----------|
| [公式 1] | `[数学表达式]` | [它计算什么] | ✅ / ⚠️ 需要调参 |
| [公式 2] | `[表达式]` | [用途] | ✅ / ⚠️ 需要调参 |

**Clarifications**:
- [Formula X]: Originally [value/approach], user clarified intent is [corrected intent]
- [Formula Y]: Implemented as [X], but should be [Y] — flagged for update
**澄清**：
- [公式 X]：最初为 [数值/方法]，用户澄清的意图是 [修正后的意图]
- [公式 Y]：实现为 [X]，但应为 [Y] — 已标记待更新

---

## 5. Edge Cases
## 5. 边界情况

**Handled in Code**:
- ✅ [Edge case 1]: [How it's handled]
- ✅ [Edge case 2]: [How it's handled]
**代码中已处理**：
- ✅ [边界情况 1]：[如何处理]
- ✅ [边界情况 2]：[如何处理]

**Not Yet Handled** (discovered during analysis):
- ⚠️ [Edge case 3]: [What happens? Needs implementation]
- ⚠️ [Edge case 4]: [What happens? Needs implementation]
**尚未处理**（分析期间发现）：
- ⚠️ [边界情况 3]：[会发生什么？需要实现]
- ⚠️ [边界情况 4]：[会发生什么？需要实现]

**Unclear** (need user clarification):
- ❓ [Edge case 5]: [What should happen? Pending decision]
**不明确**（需要用户澄清）：
- ❓ [边界情况 5]：[应该发生什么？待决定]

---

## 6. Dependencies
## 6. 依赖

**Technical Dependencies**:
- [Dependency 1]: [Why needed]
- [Dependency 2]: [Why needed]
**技术依赖**：
- [依赖 1]：[为何需要]
- [依赖 2]：[为何需要]

**Design Dependencies** (other design docs):
- [System X Design]: [How they interact]
- [System Y Design]: [How they interact]
**设计依赖**（其他设计文档）：
- [系统 X 设计]：[它们如何交互]
- [系统 Y 设计]：[它们如何交互]

**Content Dependencies**:
- [Asset type]: [What's needed]
- [Data files]: [Required config/balance data]
**内容依赖**：
- [资产类型]：[需要什么]
- [数据文件]：[所需的配置/平衡数据]

---

## 7. Tuning Knobs
## 7. 调参旋钮

**Current Values** (as implemented):
**当前值**（按实现现状）：

| Parameter | Current Value | Rationale | Needs Tuning? |
|-----------|--------------|-----------|---------------|
| [Param 1] | [value] | [Why this value] | ✅ / ⚠️ / ❌ |
| [Param 2] | [value] | [Why this value] | ✅ / ⚠️ / ❌ |

| 参数 | 当前值 | 依据 | 需要调参？ |
|-----------|--------------|-----------|---------------|
| [参数 1] | [数值] | [为何用此值] | ✅ / ⚠️ / ❌ |
| [参数 2] | [数值] | [为何用此值] | ✅ / ⚠️ / ❌ |

**Balance Concerns Identified**:
- ⚠️ [Concern 1]: [What's wrong, suggested fix]
- ⚠️ [Concern 2]: [What's wrong, suggested fix]
**已识别的平衡顾虑**：
- ⚠️ [顾虑 1]：[哪里有问题，建议的修复]
- ⚠️ [顾虑 2]：[哪里有问题，建议的修复]

**Recommended Balance Pass**:
- Run `/balance-check` on [specific aspect]
- Playtest with focus on [specific scenario]
**建议的平衡调整轮次**：
- 对 [具体方面] 运行 `/balance-check`
- 以 [具体场景] 为重点进行游戏测试

---

## 8. Acceptance Criteria
## 8. 验收标准

**What Exists** (implemented):
- ✅ [Criterion 1]
- ✅ [Criterion 2]
- ⚠️ [Criterion 3] — partially implemented
**已存在的内容**（已实现）：
- ✅ [标准 1]
- ✅ [标准 2]
- ⚠️ [标准 3] — 部分实现

**What's Missing** (not yet implemented):
- ❌ [Criterion 4] — flagged for future work
- ❌ [Criterion 5] — flagged for future work
**缺失的内容**（尚未实现）：
- ❌ [标准 4] — 已标记为未来工作
- ❌ [标准 5] — 已标记为未来工作

**Definition of Done** (when is this system "complete"?):
- [ ] [Requirement 1]
- [ ] [Requirement 2]
- [ ] [Requirement 3]
**完成定义**（此系统何时算“完成”？）：
- [ ] [需求 1]
- [ ] [需求 2]
- [ ] [需求 3]

---

## Open Questions and Follow-Up Work
## 待决问题与后续工作

### Questions Needing User Decision
### 需要用户决策的问题

1. **[Question 1]**: [What needs to be decided?]
   - Option A: [Approach A]
   - Option B: [Approach B]
1. **[问题 1]**：[需要决定什么？]
   - 选项 A：[方法 A]
   - 选项 B：[方法 B]

2. **[Question 2]**: [What needs to be decided?]
2. **[问题 2]**：[需要决定什么？]

### Flagged Follow-Up Work
### 已标记的后续工作

- [ ] **Update [Formula X]**: Change from exponential to linear (per user clarification)
- [ ] **Implement [Edge Case Y]**: Handle scenario not in current code
- [ ] **Create ADR**: Document why [architectural decision] was chosen
- [ ] **Balance pass**: Run `/balance-check` on progression curve
- [ ] **Extend design doc**: When [related feature] is implemented, update this doc
- [ ] **更新 [公式 X]**：从指数改为线性（依据用户澄清）
- [ ] **实现 [边界情况 Y]**：处理当前代码中不存在的场景
- [ ] **创建 ADR**：记录为何选择 [架构决策]
- [ ] **平衡调整**：对进度曲线运行 `/balance-check`
- [ ] **扩展设计文档**：当 [相关功能] 实现时，更新本文档

---

## Version History
## 版本历史

| Date | Author | Changes |
|------|--------|---------|
| [Date] | Claude (reverse-doc) | Initial reverse-documentation from `[source path]` |
| [Date] | [User] | Clarified design intent, corrected [X] |

| 日期 | 作者 | 变更 |
|------|--------|---------|
| [日期] | Claude（逆向文档） | 基于 `[源路径]` 的初始逆向文档化 |
| [日期] | [用户] | 澄清设计意图，修正 [X] |

---

**Next Steps**:
1. [Priority 1 task based on gaps identified]
2. [Priority 2 task]
3. [Priority 3 task]
**后续步骤**：
1. [基于已识别缺口的优先级 1 任务]
2. [优先级 2 任务]
3. [优先级 3 任务]

**Related Skills**:
- `/balance-check` — Validate formulas and progression
- `/architecture-decision` — Document technical decisions
- `/code-review` — Ensure code matches clarified design
**相关技能**：
- `/balance-check` — 验证公式与进度
- `/architecture-decision` — 记录技术决策
- `/code-review` — 确保代码与澄清后的设计一致

---

*This document was generated by `/reverse-document design [path]`*
*本文档由 `/reverse-document design [path]` 生成*
