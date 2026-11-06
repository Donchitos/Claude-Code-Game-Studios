# ADR: [Decision Name]
# ADR：[决策名称]

---
**Status**: Reverse-Documented
**状态**：反向记录
**Source**: `[path to implementation code]`
**来源**：`[实现代码路径]`
**Date**: [YYYY-MM-DD]
**日期**：[YYYY-MM-DD]
**Decision Makers**: [User name or "inferred from code"]
**决策者**：[用户名或"从代码推断"]
**Implementation Status**: [Deployed | Partial | Planned]
**实现状态**：[已部署 | 部分完成 | 计划中]
---

> **⚠️ Reverse-Documentation Notice**
> **⚠️ 反向记录声明**
>
> This Architecture Decision Record was created **after** the implementation already
> existed. It captures the current implementation approach and clarified rationale
> based on code analysis and user consultation. Some context may be reconstructed
> rather than contemporaneously documented.
> 本架构决策记录（ADR）是在实现已存在**之后**创建的。它记录了当前的
> 实现方式，以及基于代码分析和用户沟通澄清的理由。部分上下文可能是
> 重建的，而非当时同步记录的。

---

## Context
## 上下文

**Problem Statement**: [What problem did this implementation solve?]
**问题陈述**：[本实现解决了什么问题？]

**Background** (inferred from code):
**背景**（从代码推断）：
- [Context 1 — why this problem needed solving]
- [上下文 1 — 为何此问题需要解决]
- [Context 2 — constraints at the time]
- [上下文 2 — 当时的约束]
- [Context 3 — alternatives that were likely considered]
- [上下文 3 — 当时可能考虑过的备选方案]

**System Scope**: [What parts of the codebase does this affect?]
**系统范围**：[这影响代码库的哪些部分？]

**Stakeholders**:
**利益相关方**：
- [Role 1]: [Their concern or requirement]
- [角色 1]：[他们的关切或要求]
- [Role 2]: [Their concern or requirement]
- [角色 2]：[他们的关切或要求]

---

## Decision
## 决策

**Approach Taken** (as implemented):
**采用的方法**（按已实现情况）：

[Describe the architectural approach found in the code]
[描述代码中所见的架构方法]

**Key Implementation Details**:
**关键实现细节**：
- [Detail 1]: [How it works]
- [细节 1]：[它如何运作]
- [Detail 2]: [Pattern or structure used]
- [细节 2]：[使用的模式或结构]
- [Detail 3]: [Notable design choice]
- [细节 3]：[值得注意的设计选择]

**Clarified Rationale** (from user):
**澄清后的理由**（来自用户）：
- [Reason 1 — why this approach was chosen]
- [理由 1 — 为何选择此方法]
- [Reason 2 — what problem it solves]
- [理由 2 — 它解决了什么问题]
- [Reason 3 — what benefit it provides]
- [理由 3 — 它提供了什么收益]

**Code Locations**:
**代码位置**：
- `[file/path 1]`: [What's there]
- `[file/path 1]`：[此处有什么]
- `[file/path 2]`: [What's there]
- `[file/path 2]`：[此处有什么]

---

## Alternatives Considered
## 考虑过的备选方案

*(These may be inferred or clarified with user)*
*（这些可能是推断的，或已与用户澄清）*

### Alternative 1: [Approach Name]
### 备选方案 1：[方法名称]

**Description**: [What this alternative would have been]
**描述**：[本备选方案会是什么样]

**Pros**:
**优点**：
- ✅ [Advantage 1]
- ✅ [优势 1]
- ✅ [Advantage 2]
- ✅ [优势 2]

**Cons**:
**缺点**：
- ❌ [Disadvantage 1]
- ❌ [劣势 1]
- ❌ [Disadvantage 2]
- ❌ [劣势 2]

**Why Not Chosen**: [Reason — from user clarification or inference]
**为何未选**：[理由 — 来自用户澄清或推断]

### Alternative 2: [Approach Name]
### 备选方案 2：[方法名称]

**Description**: [What this alternative would have been]
**描述**：[本备选方案会是什么样]

**Pros**:
**优点**：
- ✅ [Advantage 1]
- ✅ [优势 1]
- ✅ [Advantage 2]
- ✅ [优势 2]

**Cons**:
**缺点**：
- ❌ [Disadvantage 1]
- ❌ [劣势 1]
- ❌ [Disadvantage 2]
- ❌ [劣势 2]

**Why Not Chosen**: [Reason]
**为何未选**：[理由]

### Alternative 3: [Status Quo / No Change]
### 备选方案 3：[维持现状 / 不做改变]

**Description**: [What "doing nothing" would mean]
**描述**：["什么都不做"意味着什么]

**Why Not Acceptable**: [Why the problem needed solving]
**为何不可接受**：[为何该问题需要解决]

---

## Consequences
## 后果

### Positive Consequences (Benefits Realized)
### 正面后果（已实现的收益）

✅ **[Benefit 1]**: [How the implementation provides this]
✅ **[收益 1]**：[实现如何提供这一点]

✅ **[Benefit 2]**: [Impact]
✅ **[收益 2]**：[影响]

✅ **[Benefit 3]**: [Impact]
✅ **[收益 3]**：[影响]

### Negative Consequences (Trade-offs Accepted)
### 负面后果（已接受的权衡）

⚠️ **[Trade-off 1]**: [What was sacrificed or made harder]
⚠️ **[权衡 1]**：[牺牲了什么或使什么变得更难]

⚠️ **[Trade-off 2]**: [Limitation or cost]
⚠️ **[权衡 2]**：[限制或成本]

⚠️ **[Trade-off 3]**: [Complexity or maintenance burden]
⚠️ **[权衡 3]**：[复杂度或维护负担]

### Neutral Consequences (Observations)
### 中性后果（观察）

ℹ️ **[Observation 1]**: [Emergent property or side effect]
ℹ️ **[观察 1]**：[涌现特性或副作用]

ℹ️ **[Observation 2]**: [Unexpected outcome]
ℹ️ **[观察 2]**：[意外结果]

---

## Implementation Notes
## 实现备注

**Patterns Used**:
**使用的模式**：
- [Pattern 1]: [Where and why]
- [模式 1]：[何处与为何]
- [Pattern 2]: [Where and why]
- [模式 2]：[何处与为何]

**Dependencies Introduced**:
**引入的依赖**：
- [Dependency 1]: [Why needed]
- [依赖 1]：[为何需要]
- [Dependency 2]: [Why needed]
- [依赖 2]：[为何需要]

**Performance Characteristics**:
**性能特征**：
- Time complexity: [O(n), etc.]
- 时间复杂度：[O(n) 等]
- Space complexity: [Memory usage]
- 空间复杂度：[内存占用]
- Bottlenecks: [Known performance concerns]
- 瓶颈：[已知的性能隐患]

**Thread Safety**:
**线程安全**：
- [Thread safety approach — single-threaded, mutex-protected, lock-free, etc.]
- [线程安全方案 — 单线程、互斥锁保护、无锁等]

**Testing Strategy**:
**测试策略**：
- [How this is tested — unit tests, integration tests, etc.]
- [如何测试 — 单元测试、集成测试等]
- Coverage: [Estimated or measured]
- 覆盖率：[估算或实测]

---

## Validation
## 验证

**How We Know This Works**:
**我们如何确认它有效**：
- ✅ [Evidence 1 — e.g., "6 months in production without issues"]
- ✅ [证据 1 — 例如"在生产中运行 6 个月无问题"]
- ✅ [Evidence 2 — e.g., "handles 10k entities at 60 FPS"]
- ✅ [证据 2 — 例如"以 60 FPS 处理 1 万个实体"]
- ⚠️ [Evidence 3 — e.g., "works but needs monitoring"]
- ⚠️ [证据 3 — 例如"可用但需要监控"]

**Known Issues** (discovered during analysis):
**已知问题**（分析期间发现）：
- ⚠️ [Issue 1]: [Problem and potential fix]
- ⚠️ [问题 1]：[问题与可能的修复]
- ⚠️ [Issue 2]: [Problem and potential fix]
- ⚠️ [问题 2]：[问题与可能的修复]

**Risks**:
**风险**：
- [Risk 1]: [Potential problem if X happens]
- [风险 1]：[若发生 X 时的潜在问题]
- [Risk 2]: [Scalability concern]
- [风险 2]：[可扩展性隐患]

---

## Open Questions
## 待解决问题

**Unresolved During Reverse-Documentation**:
**反向记录期间未解决的事项**：
1. **[Question 1]**: [What's unclear about the decision or implementation?]
1. **[问题 1]**：[关于该决策或实现，何种情况不清楚？]
   - Needs clarification from: [Who]
   - 需要以下人员澄清：[谁]
   - Impact if unresolved: [Consequence]
   - 若未解决的影响：[后果]

2. **[Question 2]**: [What needs to be decided for future work?]
2. **[问题 2]**：[后续工作还需要决定什么？]

---

## Follow-Up Work
## 后续工作

**Immediate**:
**立即**：
- [ ] [Task 1 — e.g., "Add missing unit tests"]
- [ ] [任务 1 — 例如"补充缺失的单元测试"]
- [ ] [Task 2 — e.g., "Document edge case handling"]
- [ ] [任务 2 — 例如"记录边缘情况处理"]

**Short-Term**:
**短期**：
- [ ] [Task 3 — e.g., "Refactor X for clarity"]
- [ ] [任务 3 — 例如"为清晰起见重构 X"]
- [ ] [Task 4 — e.g., "Add performance monitoring"]
- [ ] [任务 4 — 例如"添加性能监控"]

**Long-Term**:
**长期**：
- [ ] [Task 5 — e.g., "Revisit decision when Y is available"]
- [ ] [任务 5 — 例如"当 Y 可用时重新审视该决策"]

---

## Related Decisions
## 相关决策

**Depends On** (ADRs this builds upon):
**依赖于**（本 ADR 所基于的 ADR）：
- [ADR-XXX]: [Related decision]
- [ADR-XXX]：[相关决策]

**Influences** (ADRs affected by this):
**影响**（受本决策影响的 ADR）：
- [ADR-YYY]: [How this impacts it]
- [ADR-YYY]：[如何影响它]

**Supersedes**:
**取代**：
- [ADR-ZZZ]: [Old decision this replaces, if any]
- [ADR-ZZZ]：[本决策取代的旧决策，若有]

**Superseded By**:
**被取代于**：
- [None yet | ADR-WWW if this decision is later replaced]
- [尚无 | 若本决策之后被取代，则填 ADR-WWW]

---

## References
## 参考资料

**Code Locations**:
**代码位置**：
- `[path/file 1]`: [Primary implementation]
- `[path/file 1]`：[主要实现]
- `[path/file 2]`: [Related code]
- `[path/file 2]`：[相关代码]

**External Resources**:
**外部资源**：
- [Article/Book]: [Relevant pattern or technique reference]
- [文章/书籍]：[相关模式或技术参考]
- [Documentation]: [Engine or library docs consulted]
- [文档]：[查阅过的引擎或库文档]

**Design Documents**:
**设计文档**：
- [GDD Section]: [If this implements a design]
- [GDD 章节]：[若本决策实现了某项设计]

---

## Version History
## 版本历史

| Date | Author | Changes |
|------|--------|---------|
| [Date] | Claude (reverse-doc) | Initial reverse-documentation from `[source path]` |
| [Date] | [User] | Clarified rationale for [X] |

| 日期 | 作者 | 变更 |
|------|--------|---------|
| [日期] | Claude（反向记录） | 从 `[源路径]` 进行的初始反向记录 |
| [日期] | [用户] | 澄清 [X] 的理由 |

---

## Status Legend
## 状态图例

- **Proposed**: Under discussion, not implemented
- **提议中**：讨论中，尚未实现
- **Accepted**: Decided, implementation in progress
- **已接受**：已决定，实现进行中
- **Deprecated**: No longer recommended, but may exist in code
- **已弃用**：不再推荐，但代码中可能仍存在
- **Superseded**: Replaced by another decision
- **已被取代**：由另一决策替代
- **Reverse-Documented**: Created after implementation (this document)
- **反向记录**：在实现之后创建（本文档）

---

**Current Status**: **Reverse-Documented**
**当前状态**：**反向记录**

---

*This ADR was generated by `/reverse-document architecture [path]`*
*本 ADR 由 `/reverse-document architecture [path]` 生成*

---

## Appendix: Code Snippets
## 附录：代码片段

**Key Implementation Pattern**:
**关键实现模式**：

```[language]
[Code snippet showing the core pattern or decision]
```

```[language]
[展示核心模式或决策的代码片段]
```

**Rationale**: [Why this code structure embodies the decision]
**理由**：[为何此代码结构体现了该决策]

**Alternative Approach** (not chosen):
**备选方法**（未采用）：

```[language]
[Code snippet showing what the alternative would look like]
```

```[language]
[展示备选方案样貌的代码片段]
```

**Why Not**: [Why the implemented approach was preferred]
**为何不用**：[为何更倾向于已实现的方法]
