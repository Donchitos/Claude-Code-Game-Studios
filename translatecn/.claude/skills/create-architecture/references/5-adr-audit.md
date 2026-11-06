# /create-architecture — Phase 5: ADR Audit and Traceability Check
# /create-architecture — 阶段 5：ADR 审计与可追溯性检查

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 5: ADR Audit + Traceability Check
## 阶段 5：ADR 审计 + 可追溯性检查

Review all existing ADRs from Phase 0c against both the architecture built in
Phases 1-4 AND the Technical Requirements Baseline from Phase 0b.
对照阶段 1-4 构建的架构**以及**来自阶段 0b 的技术需求基线，评审来自阶段 0c 的
所有现有 ADR。

### ADR Quality Check
### ADR 质量检查

For each ADR:
对每个 ADR：
- [ ] Does it have an Engine Compatibility section?
- [ ] 它是否有 Engine Compatibility 小节？
- [ ] Is the engine version recorded?
- [ ] 引擎版本是否已记录？
- [ ] Are post-cutoff APIs flagged?
- [ ] 训练截止后 API 是否已标记？
- [ ] Does it have a "GDD Requirements Addressed" section?
- [ ] 它是否有 "GDD Requirements Addressed" 小节？
- [ ] Does it conflict with the layer/ownership decisions made in this session?
- [ ] 它是否与本次会话做出的分层/归属决策冲突？
- [ ] Is it still valid for the pinned engine version?
- [ ] 它对固定的引擎版本是否仍然有效？

| ADR | Engine Compat | Version | GDD Linkage | Conflicts | Valid |
|-----|--------------|---------|-------------|-----------|-------|
| ADR-0001: [title] | ✅/❌ | ✅/❌ | ✅/❌ | None/[conflict] | ✅/⚠️ |

| ADR | 引擎兼容 | 版本 | GDD 关联 | 冲突 | 有效 |
|-----|--------------|---------|-------------|-----------|-------|
| ADR-0001: [标题] | ✅/❌ | ✅/❌ | ✅/❌ | 无/[冲突] | ✅/⚠️ |

### Traceability Coverage Check
### 可追溯性覆盖检查

Map every requirement from the Technical Requirements Baseline to existing ADRs.
For each requirement, check if any ADR's "GDD Requirements Addressed" section
or decision text covers it:
将技术需求基线中的每项需求映射到现有 ADR。对每项需求，检查是否有任何 ADR 的
"GDD Requirements Addressed" 小节或决策文本覆盖它：

| Req ID | Requirement | ADR Coverage | Status |
|--------|-------------|--------------|--------|
| TR-combat-001 | Hitbox detection per-frame | ADR-0003 | ✅ |
| TR-combat-002 | Combo state machine | — | ❌ GAP |

| 需求 ID | 需求 | ADR 覆盖 | 状态 |
|--------|-------------|--------------|--------|
| TR-combat-001 | 逐帧命中盒检测 | ADR-0003 | ✅ |
| TR-combat-002 | 连招状态机 | — | ❌ GAP |

Count: X covered, Y gaps. For each gap, it becomes a **Required New ADR**.
计数：X 项已覆盖、Y 项缺口。每个缺口都会成为一项**必要的新 ADR**。

### Required New ADRs
### 必要的新 ADR

List all decisions made during this architecture session (Phases 1-4) that do
not yet have a corresponding ADR, PLUS all uncovered Technical Requirements.
Group by layer — Foundation first:
列出本次架构会话（阶段 1-4）中做出、但尚无对应 ADR 的所有决策，**加上**所有未被
覆盖的技术需求。按层分组 — Foundation 优先：

**Foundation Layer (must create before any coding):**
- `/architecture-decision [title]` → covers: TR-[id], TR-[id]

**Foundation 层（必须在任何编码之前创建）：**
- `/architecture-decision [title]` → 覆盖：TR-[id]、TR-[id]

**Core Layer:**
- `/architecture-decision [title]` → covers: TR-[id]

**Core 层：**
- `/architecture-decision [title]` → 覆盖：TR-[id]

---
