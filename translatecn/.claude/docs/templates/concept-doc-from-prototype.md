# [Prototype Name] — Concept Document
# [原型名称] — 概念文档

---
**Status**: Reverse-Documented from Prototype
**状态**：从原型反向记录
**Prototype Path**: `prototypes/[name]/`
**原型路径**：`prototypes/[name]/`
**Date**: [YYYY-MM-DD]
**日期**：[YYYY-MM-DD]
**Creator**: [User name]
**创建者**：[用户名]
**Outcome**: [Success | Partial Success | Failed | Needs More Testing]
**结果**：[成功 | 部分成功 | 失败 | 需更多测试]
---

> **⚠️ Reverse-Documentation Notice**
> **⚠️ 反向记录声明**
>
> This concept document was created **after** the prototype was built. It captures
> the core mechanic, learnings, and design insights discovered through prototyping.
> This is a formalization of experimental work, not a pre-planned design.
> 本概念文档是在原型构建完成"之后"创建的。它记录了通过原型发现的核心机制、经验教训与设计洞察。
> 这是对实验性工作的形式化，而非预先规划的设计。

---

## 1. Prototype Overview
## 1. 原型概览

**Original Hypothesis**:
**原始假设**：
[What question or idea was this prototype testing?]
[本原型在测试什么问题或想法？]

**Approach**:
**方法**：
[How was the prototype built? Quick and dirty? Focused on one mechanic?]
[原型如何构建？快速粗略？聚焦于单个机制？]

**Duration**:
**持续时间**：
- Time spent: [X hours/days]
- 投入时间：[X 小时/天]
- Complexity: [Throwaway | Could be production-ready | Needs full rewrite]
- 复杂度：[抛弃型 | 可能上线就绪 | 需完全重写]

**Outcome** (clarified):
**结果**（已澄清）：
- ✅ **Validated**: [What worked and should move forward]
- ✅ **已验证**：[有效并应推进的内容]
- ⚠️ **Needs Work**: [What showed promise but needs refinement]
- ⚠️ **需要改进**：[有前景但需打磨的内容]
- ❌ **Invalidated**: [What didn't work and should be abandoned]
- ❌ **已否定**：[无效并应放弃的内容]

---

## 2. Core Mechanic
## 2. 核心机制

**What the Prototype Does**:
**原型做了什么**：
[Describe the mechanic or system that was prototyped]
[描述被原型化的机制或系统]

**How It Feels** (user feedback):
**感觉如何**（用户反馈）：
- [Feeling 1 — e.g., "Satisfying", "Clunky", "Too complex"]
- [感受 1 — 例如 "令人满足"、"笨拙"、"过于复杂"]
- [Feeling 2 — e.g., "Intuitive", "Confusing", "Needs tutorial"]
- [感受 2 — 例如 "直观"、"令人困惑"、"需要教程"]
- [Feeling 3 — e.g., "Fun", "Boring", "Has potential"]
- [感受 3 — 例如 "有趣"、"无聊"、"有潜力"]

**Player Fantasy**:
**玩家幻想**：
[What fantasy or experience does this mechanic create?]
[本机制创造了什么幻想或体验？]

**Core Loop** (if applicable):
**核心循环**（如适用）：
```
[Action 1] → [Result 1] → [Action 2] → [Result 2] → [Repeat or Conclude]
```
```
[行动 1] → [结果 1] → [行动 2] → [结果 2] → [重复或结束]
```

**Emergent Behaviors** (unintended but interesting):
**涌现行为**（无意但有趣）：
- [Behavior 1]: [What players did that wasn't planned]
- [行为 1]：[玩家做出的未计划行为]
- [Behavior 2]: [Unexpected strategy or interaction]
- [行为 2]：[意外的策略或交互]

---

## 3. What Worked
## 3. 哪些有效

### Mechanic Successes
### 机制成功之处

✅ **[Success 1]**: [What worked well]
✅ **[成功 1]**：[有效的方面]
- **Why**: [What made this successful]
- **原因**：[使其成功的因素]
- **Keep for Production**: [Should this be preserved?]
- **保留至生产**：[应保留吗？]

✅ **[Success 2]**: [What worked well]
✅ **[成功 2]**：[有效的方面]
- **Why**: [What made this successful]
- **原因**：[使其成功的因素]
- **Keep for Production**: [Should this be preserved?]
- **保留至生产**：[应保留吗？]

### Technical Successes
### 技术成功之处

✅ **[Technical win 1]**: [What technical approach worked]
✅ **[技术成果 1]**：[有效的技术方法]
- **Lesson**: [What we learned]
- **经验**：[我们学到了什么]
- **Reusable**: [Can this code/approach be used in production?]
- **可复用**：[此代码/方法可用于生产吗？]

✅ **[Technical win 2]**: [What worked]
✅ **[技术成果 2]**：[有效的方面]
- **Lesson**: [What we learned]
- **经验**：[我们学到了什么]

---

## 4. What Didn't Work
## 4. 哪些无效

### Mechanic Failures
### 机制失败之处

❌ **[Failure 1]**: [What didn't work]
❌ **[失败 1]**：[无效的方面]
- **Why**: [Root cause]
- **原因**：[根本原因]
- **Could It Be Fixed**: [Is it salvageable or fundamentally flawed?]
- **能否修复**：[可挽救还是根本性缺陷？]

❌ **[Failure 2]**: [What didn't work]
❌ **[失败 2]**：[无效的方面]
- **Why**: [Root cause]
- **原因**：[根本原因]
- **Could It Be Fixed**: [Yes/No + how]
- **能否修复**：[是/否 + 方式]

### Technical Failures
### 技术失败之处

❌ **[Technical issue 1]**: [What caused problems]
❌ **[技术问题 1]**：[造成问题的方面]
- **Lesson**: [What to avoid in production]
- **经验**：[生产中应避免什么]

❌ **[Technical issue 2]**: [What caused problems]
❌ **[技术问题 2]**：[造成问题的方面]
- **Lesson**: [What to avoid]
- **经验**：[应避免什么]

---

## 5. What Needs Refinement
## 5. 需要打磨的内容

⚠️ **[Element 1]**: [What showed promise but needs work]
⚠️ **[元素 1]**：[有前景但需打磨的内容]
- **Issue**: [What's wrong with it currently]
- **问题**：[当前有何问题]
- **Path Forward**: [How to improve it]
- **改进路径**：[如何改进]
- **Effort**: [Small | Medium | Large refactor]
- **工作量**：[小 | 中 | 大型重构]

⚠️ **[Element 2]**: [What needs refinement]
⚠️ **[元素 2]**：[需打磨的内容]
- **Issue**: [Current problem]
- **问题**：[当前问题]
- **Path Forward**: [Improvement approach]
- **改进路径**：[改进方法]
- **Effort**: [Estimate]
- **工作量**：[估计]

---

## 6. Key Learnings
## 6. 关键经验

### Design Insights
### 设计洞察

💡 **[Insight 1]**: [What we learned about game design]
💡 **[洞察 1]**：[我们学到的游戏设计经验]
- **Implication**: [How this affects future work]
- **影响**：[对后续工作的影响]

💡 **[Insight 2]**: [Design learning]
💡 **[洞察 2]**：[设计经验]
- **Implication**: [Impact on GDD or other systems]
- **影响**：[对 GDD 或其他系统的影响]

### Technical Insights
### 技术洞察

💡 **[Insight 3]**: [Technical learning]
💡 **[洞察 3]**：[技术经验]
- **Implication**: [Architecture or implementation guidance]
- **影响**：[架构或实现指南]

💡 **[Insight 4]**: [Technical learning]
💡 **[洞察 4]**：[技术经验]
- **Implication**: [Future technical decisions]
- **影响**：[未来的技术决策]

### Player Psychology Insights
### 玩家心理洞察

💡 **[Insight 5]**: [What we learned about player behavior]
💡 **[洞察 5]**：[我们学到的玩家行为经验]
- **Implication**: [How this affects design philosophy]
- **影响**：[对设计理念的影响]

---

## 7. Production Readiness Assessment
## 7. 生产就绪评估

**Should This Become a Full Feature?**: [Yes | No | Needs More Testing | Pivot to Different Approach]
**应否成为完整功能？**：[是 | 否 | 需更多测试 | 转向不同方法]

**If Yes — Production Requirements**:
**若是 — 生产需求**：
- [ ] [Requirement 1 — e.g., "Rewrite for performance"]
- [ ] [需求 1 — 例如 "为性能重写"]
- [ ] [Requirement 2 — e.g., "Add proper UI"]
- [ ] [需求 2 — 例如 "添加正式 UI"]
- [ ] [Requirement 3 — e.g., "Design 10 more variations"]
- [ ] [需求 3 — 例如 "设计 10 个变体"]
- [ ] [Requirement 4 — e.g., "Integrate with progression system"]
- [ ] [需求 4 — 例如 "与进度系统集成"]

**Estimated Production Effort**: [Small | Medium | Large]
**预计生产工作量**：[小 | 中 | 大]
- Prototype reusability: [X%] of code can be kept
- 原型可复用性：[X%] 的代码可保留
- From-scratch effort: [X hours/days to production-ready]
- 从零开始工作量：[X 小时/天达到生产就绪]

**If No — Why Not?**:
**若否 — 为何？**：
- [Reason 1 — e.g., "Fun but doesn't fit game pillars"]
- [原因 1 — 例如 "有趣但不符合游戏支柱"]
- [Reason 2 — e.g., "Too complex for target audience"]
- [原因 2 — 例如 "对目标受众过于复杂"]
- [Reason 3 — e.g., "Technically infeasible at scale"]
- [原因 3 — 例如 "规模化时技术上不可行"]

**If Pivot — Suggested Direction**:
**若转向 — 建议方向**：
- [Alternative approach 1]
- [备选方法 1]
- [Alternative approach 2]
- [备选方法 2]

---

## 8. Design Pillars Alignment
## 8. 设计支柱对齐

**How This Relates to Game Pillars** (if game pillars are defined):
**本机制如何与游戏支柱关联**（若已定义游戏支柱）：

| Pillar | Alignment | Notes |
|--------|-----------|-------|
| [Pillar 1] | ✅ Strong / ⚠️ Weak / ❌ Conflicts | [Explanation] |
| [Pillar 2] | ✅ Strong / ⚠️ Weak / ❌ Conflicts | [Explanation] |
| [Pillar 3] | ✅ Strong / ⚠️ Weak / ❌ Conflicts | [Explanation] |

| 支柱 | 对齐程度 | 备注 |
|--------|-----------|-------|
| [支柱 1] | ✅ 强 / ⚠️ 弱 / ❌ 冲突 | [说明] |
| [支柱 2] | ✅ 强 / ⚠️ 弱 / ❌ 冲突 | [说明] |
| [支柱 3] | ✅ 强 / ⚠️ 弱 / ❌ 冲突 | [说明] |

**Overall Pillar Fit**: [Does this belong in the game?]
**整体支柱契合度**：[它属于本游戏吗？]

---

## 9. Next Steps
## 9. 后续步骤

### Immediate (If Moving Forward)
### 立即（若推进）
1. **[Task 1]**: [e.g., "Create full design doc for this system"]
1. **[任务 1]**：[例如 "为本系统创建完整设计文档"]
2. **[Task 2]**: [e.g., "Write ADR for technical approach"]
2. **[任务 2]**：[例如 "为技术方案编写 ADR"]
3. **[Task 3]**: [e.g., "Add to backlog for Sprint X"]
3. **[任务 3]**：[例如 "加入冲刺 X 的待办"]

### Before Production (If Needs More Work)
### 生产前（若需更多工作）
1. **[Task 1]**: [e.g., "Build second prototype testing X variation"]
1. **[任务 1]**：[例如 "构建测试 X 变体的第二个原型"]
2. **[Task 2]**: [e.g., "Playtest with 5+ people"]
2. **[任务 2]**：[例如 "与 5 人以上试玩"]
3. **[Task 3]**: [e.g., "Investigate technical feasibility of Y"]
3. **[任务 3]**：[例如 "调研 Y 的技术可行性"]

### If Abandoning
### 若放弃
1. **[Task 1]**: [e.g., "Archive prototype with this document"]
1. **[任务 1]**：[例如 "将原型连同本文档归档"]
2. **[Task 2]**: [e.g., "Extract reusable code/learnings"]
2. **[任务 2]**：[例如 "提取可复用代码/经验"]
3. **[Task 3]**: [e.g., "Update game pillars if this changed thinking"]
3. **[任务 3]**：[例如 "若本机制改变了思路则更新游戏支柱"]

---

## 10. Technical Notes
## 10. 技术备注

**Prototype Implementation**:
**原型实现**：
- Language/Engine: [What was used]
- 语言/引擎：[使用什么]
- Architecture: [How it was structured]
- 架构：[如何组织]
- Shortcuts taken: [What was hacky or throwaway]
- 走的捷径：[哪些是临时或抛弃式的]

**Reusable Code** (if any):
**可复用代码**（如有）：
- `[file/path 1]`: [What it does, reusability]
- `[file/path 1]`：[功能与可复用性]
- `[file/path 2]`: [What it does, reusability]
- `[file/path 2]`：[功能与可复用性]

**Technical Debt** (if moving to production):
**技术债**（若进入生产）：
- [Debt 1]: [What needs rewriting]
- [债务 1]：[需重写的内容]
- [Debt 2]: [What needs proper implementation]
- [债务 2]：[需正式实现的内容]

---

## 11. Playtest Feedback
## 11. 试玩反馈

*(If prototype was playtested)*
*（若原型经过试玩）*

**Testers**: [N people, [internal/external]]
**试玩者**：[N 人，[内部/外部]]

**Positive Feedback**:
**正面反馈**：
- "[Quote 1]" — [Tester name/role]
- "[引用 1]" — [试玩者姓名/角色]
- "[Quote 2]" — [Tester name/role]
- "[引用 2]" — [试玩者姓名/角色]

**Negative Feedback**:
**负面反馈**：
- "[Quote 1]" — [Tester name/role]
- "[引用 1]" — [试玩者姓名/角色]
- "[Quote 2]" — [Tester name/role]
- "[引用 2]" — [试玩者姓名/角色]

**Suggestions**:
**建议**：
- "[Suggestion 1]" — [Tester name]
- "[建议 1]" — [试玩者姓名]
- "[Suggestion 2]" — [Tester name]
- "[建议 2]" — [试玩者姓名]

**Themes**:
**主题**：
- [Theme 1]: [What multiple testers agreed on]
- [主题 1]：[多名试玩者一致同意的内容]
- [Theme 2]: [Common feedback]
- [主题 2]：[常见反馈]

---

## 12. Related Work
## 12. 相关作品

**Inspired By** (games/mechanics this was influenced by):
**受启发自**（影响本机制的游戏/机制）：
- [Game 1]: [What mechanic or feeling]
- [游戏 1]：[什么机制或感受]
- [Game 2]: [What was borrowed or adapted]
- [游戏 2]：[借鉴或改编了什么]

**Differs From** (how this is unique or different):
**区别于**（本机制如何独特或不同）：
- [Difference 1]
- [差异 1]
- [Difference 2]
- [差异 2]

**Integrates With** (existing game systems):
**集成于**（现有游戏系统）：
- [System 1]: [How they would connect]
- [系统 1]：[它们如何连接]
- [System 2]: [How they would connect]
- [系统 2]：[它们如何连接]

---

## 13. Open Questions
## 13. 待解决问题

**Design Questions**:
**设计问题**：
1. **[Question 1]**: [What's still undecided about the design?]
1. **[问题 1]**：[设计上还有什么未决？]
2. **[Question 2]**: [What needs playtesting or iteration?]
2. **[问题 2]**：[什么需要试玩或迭代？]

**Technical Questions**:
**技术问题**：
3. **[Question 3]**: [What technical unknowns remain?]
3. **[问题 3]**：[还有哪些技术未知？]
4. **[Question 4]**: [What needs feasibility testing?]
4. **[问题 4]**：[什么需要可行性测试？]

---

## 14. Appendix: Prototype Assets
## 14. 附录：原型资产

**Code**:
**代码**：
- Location: `prototypes/[name]/src/`
- 位置：`prototypes/[name]/src/`
- Status: [Archival | Partial reuse | Full reuse]
- 状态：[归档 | 部分复用 | 完全复用]

**Art/Audio** (if any):
**美术/音频**（如有）：
- Location: `prototypes/[name]/assets/`
- 位置：`prototypes/[name]/assets/`
- Status: [Placeholder | Production-ready | Needs replacement]
- 状态：[占位 | 生产就绪 | 需替换]

**Documentation**:
**文档**：
- README: [Exists | Missing]
- README：[存在 | 缺失]
- Build instructions: [Exists | Missing]
- 构建说明：[存在 | 缺失]

---

## Version History
## 版本历史

| Date | Author | Changes |
|------|--------|---------|
| [Date] | Claude (reverse-doc) | Initial concept doc from prototype analysis |
| [Date] | [User] | Clarified outcomes, added playtest feedback |

| 日期 | 作者 | 变更 |
|------|--------|---------|
| [日期] | Claude (反向记录) | 从原型分析生成初始概念文档 |
| [日期] | [用户] | 澄清结果、添加试玩反馈 |

---

**Final Recommendation**: [GO | NO-GO | PIVOT]
**最终建议**：[推进 | 否决 | 转向]

**Rationale**: [1-2 sentence summary of why]
**理由**：[1-2 句话概述原因]

---

*This concept document was generated by `/reverse-document concept prototypes/[name]`*
*本概念文档由 `/reverse-document concept prototypes/[name]` 生成*
