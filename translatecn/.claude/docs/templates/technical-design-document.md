# Technical Design: [System Name]
# 技术设计：[系统名称]

## Document Status
## 文档状态
- **Version**: 1.0
- **Last Updated**: [Date]
- **Author**: [Agent/Person]
- **Reviewer**: lead-programmer
- **Related ADR**: [ADR-XXXX if applicable]
- **Related Design Doc**: [Link to game design doc this implements]
- **版本**：1.0
- **最后更新**：[Date]
- **作者**：[智能体/人员]
- **评审人**：lead-programmer
- **相关 ADR**：[ADR-XXXX（若适用）]
- **相关设计文档**：[指向本设计所实现的游戏设计文档的链接]

## Engine API Surface
## 引擎 API 接口面

| Field | Value |
|-------|-------|
| 字段 | 值 |
|-------|-------|
| **Engine** | [e.g. Godot 4.7 / Unity 6 / Unreal Engine 5.8] |
| **APIs Depended On** | [Specific classes/methods/nodes used, version-pinned — e.g. `CharacterBody3D.move_and_slide() (Godot 4.x)`] |
| **References Consulted** | [engine-reference docs read before writing this — e.g. `docs/engine-reference/godot/modules/physics.md`] |
| **Post-Cutoff Features Used** | [Features from engine versions beyond LLM training cutoff, or "None"] |
| **Unverified Assumptions** | [API behaviours assumed but not yet tested against the target version, or "None"] |
| **Engine Upgrade Risk** | [LOW / MEDIUM / HIGH — how fragile is this design if the engine version changes?] |
| **引擎** | [例如 Godot 4.7 / Unity 6 / Unreal Engine 5.8] |
| **依赖的 API** | [使用的具体类/方法/节点，锁定版本——例如 `CharacterBody3D.move_and_slide() (Godot 4.x)`] |
| **查阅的参考** | [撰写本文前阅读的引擎参考文档——例如 `docs/engine-reference/godot/modules/physics.md`] |
| **使用的后截止版本特性** | [超出 LLM 训练截止时间的引擎版本中的特性，或 "None"] |
| **未验证的假设** | [已假设但尚未针对目标版本测试的 API 行为，或 "None"] |
| **引擎升级风险** | [低 / 中 / 高——若引擎版本变化，此设计有多脆弱？] |

> **Rule**: If any **Unverified Assumptions** are listed, this document cannot be marked
> as Accepted until those assumptions are validated in the actual engine environment.
> **规则**：若列出了任何**未验证的假设**，则在 › 这些假设于实际引擎环境中得到验证之前，
> 本文档不能标记为已接受。

## Overview
## 概述
[2-3 sentence summary of what this system does and why it exists]
[2-3 句话概述此系统做什么以及为何存在]

## Requirements
## 需求
### Functional Requirements
### 功能需求
- [FR-1]: [Description]
- [FR-2]: [Description]
- [FR-1]：[描述]
- [FR-2]：[描述]

### Non-Functional Requirements
### 非功能需求
- **Performance**: [Budget — e.g., "< 1ms per frame"]
- **Memory**: [Budget — e.g., "< 50MB at peak"]
- **Scalability**: [Limits — e.g., "Support up to 1000 entities"]
- **Thread Safety**: [Requirements]
- **性能**：[预算——例如 "< 1ms 每帧"]
- **内存**：[预算——例如 "峰值 < 50MB"]
- **可扩展性**：[限制——例如 "支持多达 1000 个实体"]
- **线程安全**：[需求]

## Architecture
## 架构

### System Diagram
### 系统图
```
[ASCII diagram showing components and data flow]
```
```
[展示组件与数据流的 ASCII 图]
```

### Component Breakdown
### 组件分解
| Component | Responsibility | Owns |
| --------- | -------------- | ---- |
| 组件 | 职责 | 拥有 |
| --------- | -------------- | ---- |
| [Name] | [What it does] | [What data it owns] |
| [名称] | [它做什么] | [它拥有什么数据] |

### Public API
### 公共 API
```
[Interface/API definition in pseudocode or target language]
```

### Data Structures
### 数据结构
```
[Key data structures with field descriptions]
```

### Data Flow
### 数据流
[Step by step: how data moves through the system during a typical frame]
[逐步说明：在典型的一帧中数据如何流经此系统]

## Implementation Plan
## 实现计划

### Phase 1: [Core Functionality]
### 阶段 1：[核心功能]
- [ ] [Task 1]
- [ ] [Task 2]
- [ ] [任务 1]
- [ ] [任务 2]

### Phase 2: [Extended Features]
### 阶段 2：[扩展功能]
- [ ] [Task 3]
- [ ] [Task 4]
- [ ] [任务 3]
- [ ] [任务 4]

### Phase 3: [Optimization/Polish]
### 阶段 3：[优化/打磨]
- [ ] [Task 5]
- [ ] [任务 5]

## Dependencies
## 依赖
| Depends On | For What |
| ---------- | -------- |
| 依赖于 | 用途 |
| ---------- | -------- |
| [System] | [Reason] |
| [系统] | [原因] |

| Depended On By | For What |
| -------------- | -------- |
| 被依赖于 | 用途 |
| -------------- | -------- |
| [System] | [Reason] |
| [系统] | [原因] |

## Testing Strategy
## 测试策略
- **Unit Tests**: [What to test at unit level]
- **Integration Tests**: [Cross-system tests needed]
- **Performance Tests**: [Benchmarks to create]
- **Edge Cases**: [Specific scenarios to test]
- **单元测试**：[在单元层面测试什么]
- **集成测试**：[所需的跨系统测试]
- **性能测试**：[要创建的基准]
- **边界情况**：[要测试的具体场景]

## Known Limitations
## 已知限制
[What this design intentionally does NOT support and why]
[此设计有意不支持什么以及为何]

## Future Considerations
## 未来考量
[What might need to change if requirements evolve — but do NOT build for this now]
[若需求演进，可能需要改变什么——但现在不要为此构建]
