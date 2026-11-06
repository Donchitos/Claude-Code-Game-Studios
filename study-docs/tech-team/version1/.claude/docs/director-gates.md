# Director Gates — 技术域门禁(精简版)

> 沿袭原项目 [director-gates.md](file:///workspace/.claude/docs/director-gates.md),砍掉所有 CD-* / PR-* / AD-* / ND-* 门,只留 TD-* / LP-* / QL-*。
> Skill 通过 gate ID 引用本文件,不内联 prompt(消除漂移)。

---

## How to Use This Document

在 skill 中替换内联 director prompt:

```
Spawn `technical-director` via Task using gate **TD-ADR** from
.claude/docs/director-gates.md.
```

---

## Review Modes(沿袭原项目)

**全局配置**:`production/review-mode.txt` — 一词:`full` / `lean` / `solo`。`/start` 时设置,可直接编辑。

**单次覆盖**:任何 gate-using skill 接受 `--review [full|lean|solo]` 参数,仅本次生效。

| Mode | 运行什么 | 适用 |
|------|----------|------|
| `full` | 所有门禁激活 | 团队 / 学习用户 / 想要每步审查 |
| `lean`(默认) | 只 PHASE-GATE(`/gate-check`) | 单人开发 / 小团队,只在里程碑审查 |
| `solo` | 无门禁 | Game Jam / 原型 / 最大速度 |

**门禁前检查模式(每次 spawn 前应用)**:

```
Before spawning gate [GATE-ID]:
1. 若 skill 带 --review [mode],用该 mode
2. 否则读 production/review-mode.txt
3. 否则默认 lean

Apply:
- solo → 跳过所有门。注:"[GATE-ID] skipped — Solo mode"
- lean → 只 TD-PHASE-GATE 运行,其余跳过。注:"[GATE-ID] skipped — Lean mode"
- full → 正常 spawn
```

---

## Standard Verdict Format(沿袭原项目)

| Verdict | 含义 | 默认动作 |
|---------|------|----------|
| **APPROVE / READY** | 无问题,继续 | 推进流程 |
| **CONCERNS [list]** | 有问题但不阻塞 | `AskUserQuestion` 给用户:修订 / 接受推进 / 进一步讨论 |
| **REJECT / NOT READY [blockers]** | 阻塞 | 告知用户,不写文件/不推进,直到解决 |

**升级规则**:多门并行时取最严 —— 一个 NOT READY 覆盖所有 READY。

---

## Recording Gate Outcomes

门禁解决后,在相关文档状态头记录:

```markdown
> **[Director] Review ([GATE-ID])**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date]
```

Phase gate 记录在 `docs/architecture/architecture.md` 或 `production/session-state/active.md`。

---

## Tier 1 — Technical Director Gates

Agent: `technical-director` | Model: opus | Domain: 架构、引擎风险、性能

---

### TD-FEASIBILITY — 技术可行性评估

**Trigger**: 早期技术风险识别时(架构起草前,或任何带技术未知的概念)

**Context to pass**:
- 核心 loop 描述
- 目标平台
- 引擎(UE 5.8)
- 已识别技术风险列表

**Prompt**:
> "Review these technical risks for a game targeting [platform] using Unreal Engine 5.8. Flag any HIGH risk items that could invalidate the concept as described, any risks commonly underestimated by solo developers. Verify UE 5.8 specific risks against Context7 (call resolve-library-id + query-docs for any UE API mentioned). Return VIABLE (risks manageable), CONCERNS [list with mitigations], or HIGH RISK [blockers requiring scope revision]."

**Verdicts**: VIABLE / CONCERNS / HIGH RISK

---

### TD-ARCHITECTURE — 架构签收

**Trigger**: 主架构文档草拟后(`/create-architecture` 完成),及任何重大架构修订后

**Context to pass**:
- 架构文档路径(`docs/architecture/architecture.md`)
- 技术需求基线(TR-IDs 与数量)
- ADR 列表与状态
- 引擎知识缺口清单(由 Context7 查证结果汇总)

**Prompt**:
> "Review this master architecture document for technical soundness. Check: (1) Is every technical requirement from the baseline covered by an architectural decision? (2) Are all HIGH risk UE 5.8 domains explicitly addressed or flagged? (3) Are the API boundaries clean, minimal, and implementable? (4) Are Foundation layer ADR gaps resolved before implementation? Return APPROVE, CONCERNS [list], or REJECT [blockers]."

**Verdicts**: APPROVE / CONCERNS / REJECT

---

### TD-ADR — 架构决策审查

**Trigger**: 单个 ADR 写完后(`/architecture-decision`),标记 Accepted 前

**Context to pass**:
- ADR 文件路径
- 引擎版本与该域 Context7 知识风险级别
- 相关 ADR(若有)

**Prompt**:
> "Review this Architecture Decision Record. Does it have a clear problem statement and rationale? Are rejected alternatives genuinely considered? Does Consequences acknowledge trade-offs honestly? Is the engine version stamped (UE 5.8)? Are post-cutoff API risks flagged and verified via Context7? Does it link to the feature spec requirements it covers? Return APPROVE, CONCERNS [specific gaps], or REJECT [decision underspecified or makes unsound technical assumptions]."

**Verdicts**: APPROVE / CONCERNS / REJECT

---

### TD-ENGINE-RISK — 引擎版本风险审查(改用 Context7)

**Trigger**: ADR / dev-story / code-review 涉及 UE API 决策时

**Context to pass**:
- 具体 API 或 feature
- Context7 查询词

**流程(改造点)**:
1. `technical-director` 调 Context7 `resolve-library-id`(libraryName: "Unreal Engine")
2. 调 `query-docs` 查具体 API
3. Context7 查不到用 WebSearch 兜底(docs.unrealengine.com/5.8/)

**Prompt**:
> "Review this UE API usage against Context7. Call resolve-library-id for 'Unreal Engine', then query-docs for [specific API]. Is this API present in UE 5.8? Has its signature, behavior, or namespace changed since LLM knowledge cutoff? Are there known deprecations or post-cutoff alternatives? Return APPROVE (safe as described), CONCERNS [verify before implementing], or REJECT [API changed — provide corrected approach]."

**Verdicts**: APPROVE / CONCERNS / REJECT

---

### TD-PHASE-GATE — 阶段切换技术就绪裁决

**Trigger**: `/gate-check` 时(本方案只过这一个门)

**Context to pass**:
- 目标阶段名(technical-setup → requirements-breakdown → implementation)
- 架构文档路径(若存在)
- ADR 列表
- Context7 引擎查证摘要

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a technical direction perspective. Is the architecture sound for this phase? Are all high-risk UE 5.8 domains addressed (verified via Context7)? Are performance budgets realistic and documented? Are Foundation-layer decisions complete enough to begin implementation? Return READY, CONCERNS [list], or NOT READY [blockers]."

**Verdicts**: READY / CONCERNS / NOT READY

---

## Tier 2 — Lead Gates

---

### LP-FEASIBILITY — Lead Programmer 实现可行性

**Trigger**: 主架构文档写完后(`/create-architecture`),或提出新架构模式时

**Context to pass**:
- 架构文档路径
- 技术需求基线摘要
- ADR 列表与状态

**Prompt**:
> "Review this architecture for implementation feasibility with UE 5.8 + C++/Blueprint. Flag: (a) decisions difficult/impossible to implement, (b) missing interface definitions programmers would need to invent, (c) patterns creating avoidable tech debt or contradicting UE idioms. Verify any UE API mentioned via Context7. Return FEASIBLE, CONCERNS [list], or INFEASIBLE [blockers]."

**Verdicts**: FEASIBLE / CONCERNS / INFEASIBLE

---

### LP-CODE-REVIEW — Lead Programmer 代码审查

**Trigger**: dev-story 实现后(`/dev-story`, `/story-done`),或 `/code-review` 的一部分

**Context to pass**:
- 实现文件路径
- 故事文件路径(含验收标准)
- 相关 feature spec 段
- 治理该系统的 ADR

**Prompt**:
> "Review this implementation against story acceptance criteria and governing ADR. Does code match architecture boundary definitions? Violations of coding standards or forbidden patterns? Is public API testable and documented? Correctness issues against feature spec rules? Return APPROVE, CONCERNS [specific issues], or REJECT [must revise before merge]."

**Verdicts**: APPROVE / CONCERNS / REJECT

---

### QL-STORY-READY — QA Lead Story 就绪检查

**Trigger**: story 入 sprint 前 —— `/create-stories` / `/story-readiness` / sprint 选择时

**Context to pass**:
- story 文件路径
- story 类型(Logic / Integration / Visual/Feel / UI / Config/Data)
- 验收标准列表(story 原文)
- 该 story 覆盖的需求(TR-ID + feature spec 文本)

**Prompt**:
> "Review this story's acceptance criteria for testability before sprint. Are all criteria specific enough that a developer knows unambiguously when done? For Logic stories: can every criterion be verified with automated test? For Integration: is each criterion observable in controlled test env? Flag vague criteria and criteria requiring full game build (mark DEFERRED not BLOCKED). Return ADEQUATE, GAPS [specific criteria needing refinement], or INADEQUATE [criteria too vague — story must revise]."

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

---

### QL-TEST-COVERAGE — QA Lead 测试覆盖审查

**Trigger**: 实现 story 完成后,标 epic done 前,或 sprint 收尾时

**Context to pass**:
- 已实现 story 列表(含类型)
- `tests/` 测试文件路径
- feature spec 验收标准

**Prompt**:
> "Review test coverage for these implementation stories. Are all Logic stories covered by passing unit tests? Integration stories covered by integration tests or documented playtests? Are feature spec acceptance criteria each mapped to at least one test? Untested edge cases? Return ADEQUATE, GAPS [specific missing tests], or INADEQUATE [critical logic untested — do not advance]."

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

---

## Gate Coverage by Stage(精简版 3 阶段)

| 阶段 | 必需门 | 可选门 |
|------|--------|--------|
| **Technical Setup** | TD-ARCHITECTURE, TD-ADR (per ADR), LP-FEASIBILITY | TD-FEASIBILITY, TD-ENGINE-RISK |
| **Requirements Breakdown** | QL-STORY-READY (per story) | — |
| **Implementation** | LP-CODE-REVIEW (per story), QL-STORY-READY, QL-TEST-COVERAGE (per sprint 收尾) | TD-ENGINE-RISK |

阶段切换:`/gate-check` 只过 TD-PHASE-GATE(本方案)。

---

## Adding New Gates

新门 ID:`[PREFIX]-[DESCRIPTIVE-SLUG]`。前缀:`TD-` / `LP-` / `QL-`。在对应 director 段下加 5 字段(Trigger / Context / Prompt / Verdicts / 特殊处理),skill 按 ID 引用,不内联 prompt。
