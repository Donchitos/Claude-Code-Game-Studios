---
name: review-all-gdds
description: "Holistic cross-GDD review — contradictions between systems, dominant strategies, economic imbalance, cognitive overload, pillar drift."
argument-hint: "[focus: full | consistency | design-theory | since-last-review]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/review-all-gdds/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-scope.sh*)
model: opus
---
---
name: review-all-gdds
description: "整体性的跨 GDD 评审 — 系统之间的矛盾、支配性策略、经济失衡、认知过载、支柱漂移。"
argument-hint: "[focus: full | consistency | design-theory | since-last-review]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/review-all-gdds/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-scope.sh*)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,system_overrides`

# Review All GDDs

# 评审所有 GDD

This skill reads every system GDD simultaneously and performs two complementary
reviews that cannot be done per-GDD in isolation:

本技能同时读取每个系统 GDD，并执行两项无法在单个 GDD 内孤立完成的互补评审：

1. **Cross-GDD Consistency** — contradictions, stale references, and ownership
   conflicts between documents
2. **Game Design Holism** — issues that only emerge when you see all systems
   together: dominant strategies, broken economies, cognitive overload, pillar
   drift, competing progression loops

1. **跨 GDD 一致性** — 文档之间的矛盾、过时引用与归属冲突
2. **游戏设计整体性** — 只有把所有系统放在一起才能显现的问题：支配性策略、崩溃的经济、认知过载、
   支柱漂移、相互竞争的成长循环

**This is distinct from `/design-review`**, which reviews one GDD for internal
completeness. This skill reviews the *relationships* between all GDDs.

**这不同于 `/design-review`**，后者评审单个 GDD 的内部完整性。本技能评审所有 GDD 之间的*关系*。

**When to run:**
- After all MVP-tier GDDs are individually approved
- After any GDD is significantly revised mid-production
- Before `/create-architecture` begins (architecture built on inconsistent GDDs
  inherits those inconsistencies)

**何时运行：**
- 在所有 MVP 层级 GDD 都被逐一批准之后
- 在生产中期任何 GDD 被大幅修订之后
- 在 `/create-architecture` 开始之前（建立在不一致 GDD 之上的架构会继承这些不一致）

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅重要事项 · 自主模式记录并继续；
`automation_always_ask` 类别始终询问）。

**Argument modes:**

**参数模式：**

**Focus:** `$ARGUMENTS` (blank = `full`)

**焦点：** `$ARGUMENTS`（留空 = `full`）

- **No argument / `full`**: Both consistency and design theory passes
- **`consistency`**: Cross-GDD consistency checks only (faster)
- **`design-theory`**: Game design holism checks only
- **`since-last-review`**: Only GDDs modified since the last review report (git-based)

- **无参数 / `full`**：同时执行一致性与设计理论两轮
- **`consistency`**：仅做跨 GDD 一致性检查（更快）
- **`design-theory`**：仅做游戏设计整体性检查
- **`since-last-review`**：仅检查自上次评审报告以来被修改的 GDD（基于 git）

---

**`workflow`** per GDD (per `.claude/docs/workflow-modes.md`): each GDD validates
against its effective tier — the project value, overridden per system by the
`system_overrides` row for that system when the block lists one. At `full`, validate all 8
sections across all GDDs. At `standard`, validate the 5 required sections;
optional sections (Player Fantasy, Tuning Knobs, conditional Formulas) are
surfaced as advisory only. At `minimal`, this skill is not applicable (no GDDs).

**按 GDD 的 `workflow`**（参见 `.claude/docs/workflow-modes.md`）：每个 GDD 按其生效层级验证 —
项目取值，当配置块列出某系统的 `system_overrides` 行时，按该系统覆盖。在 `full` 下，验证所有 GDD
的全部 8 个小节。在 `standard` 下，验证 5 个必需小节；可选小节（Player Fantasy、Tuning Knobs、
条件性 Formulas）仅作为提示呈现。在 `minimal` 下，本技能不适用（无 GDD）。

## Phase 1: Load Everything

## 阶段 1：加载全部内容

**Read `references/1-load.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**现在读取 `references/1-load.md` 并遵循它** — 本阶段的步骤在该文件中，不在此处。若本阶段期间对话被压缩或恢复，请重新读取。

### Parallel Execution

### 并行执行

Phase 2 (Consistency) and Phase 3 (Design Theory) are independent — they read
the same GDD inputs but produce separate reports. Spawn both as parallel `Agent`
agents simultaneously rather than waiting for Phase 2 to complete before
starting Phase 3. Collect both results before writing the combined report.

阶段 2（一致性）与阶段 3（设计理论）相互独立 — 它们读取相同的 GDD 输入但产出各自独立的报告。
将二者作为并行的 `Agent` 智能体同时派生，而不是等阶段 2 完成后再开始阶段 3。在写入合并报告前
收集两者的结果。

Spawn both as `game-designer` sub-agents (`subagent_type: game-designer`) — GDD
consistency and design-theory review is its domain.

将二者都作为 `game-designer` 子智能体派生（`subagent_type: game-designer`）— GDD
一致性与设计理论评审正是其领域。

**When spawning the Phase 2 and Phase 3 agents, always pass:**
- The loaded GDD **content** each phase needs — **not file paths**. Paste the
  sections; the sub-agent has its own context and cannot re-read Phase 1's
  results, so a path forces a full re-read (and contradicts the "do not re-read"
  rule below). Pass only the phase's slice: Phase 2 (consistency) needs each GDD's
  Dependencies, Detailed Design/Rules, Formulas, Tuning Knobs and Acceptance
  Criteria; Phase 3 (design theory) needs Player Fantasy, progression/reward
  structure and the game pillars.
- The full entity registry contents (`design/registry/entities.yaml`) if loaded in Phase 1b (paste the registry text, not just a file path)
- The specific checklist items assigned to that agent's phase (Phase 2 gets 2a–2f; Phase 3 gets 3a–3g)
- The engine name and version — `engine.name` and `engine.version` from `project.yaml`, resolving each field independently (if its key is absent or empty, use `.claude/docs/technical-preferences.md`) — plus `docs/engine-reference/[engine]/VERSION.md`

**派生阶段 2 与阶段 3 智能体时，始终传入：**
- 各阶段所需的已加载 GDD **内容** — **而不是文件路径**。粘贴小节内容；子智能体有自己的上下文，
  无法重读阶段 1 的结果，因此路径会强制其完整重读（并违反下面的“不要重读”规则）。只传该阶段的切片：
  阶段 2（一致性）需要每个 GDD 的 Dependencies、Detailed Design/Rules、Formulas、Tuning Knobs 与
  Acceptance Criteria；阶段 3（设计理论）需要 Player Fantasy、成长/奖励结构与游戏支柱。
- 完整的实体注册表内容（`design/registry/entities.yaml`），若在阶段 1b 中加载（粘贴注册表文本，而不只是文件路径）
- 分配给该智能体阶段的具体清单项（阶段 2 得到 2a–2f；阶段 3 得到 3a–3g）
- 引擎名称与版本 — `project.yaml` 中的 `engine.name` 与 `engine.version`，各自独立解析（若其键缺失或为空，
  使用 `.claude/docs/technical-preferences.md`）— 外加 `docs/engine-reference/[engine]/VERSION.md`

Do not rely on the subagent to re-read these files — it has its own context window and cannot access Phase 1 results unless they are explicitly passed in the `Agent` prompt.

不要指望子智能体重读这些文件 — 它有自己的上下文窗口，除非在 `Agent` 提示词中显式传入，否则无法访问阶段 1 的结果。

---

## Phase 2: Cross-GDD Consistency

## 阶段 2：跨 GDD 一致性

**Read `references/2-consistency.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**现在读取 `references/2-consistency.md` 并遵循它** — 本阶段的步骤在该文件中，不在此处。若本阶段期间对话被压缩或恢复，请重新读取。

## Phase 3: Game Design Holism

## 阶段 3：游戏设计整体性

**Read `references/3-design-holism.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**现在读取 `references/3-design-holism.md` 并遵循它** — 本阶段的步骤在该文件中，不在此处。若本阶段期间对话被压缩或恢复，请重新读取。

## Phase 4: Cross-System Scenario Walkthrough

## 阶段 4：跨系统场景走查

**Read `references/4-scenarios.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**现在读取 `references/4-scenarios.md` 并遵循它** — 本阶段的步骤在该文件中，不在此处。若本阶段期间对话被压缩或恢复，请重新读取。

## Phase 5: Output the Review Report

## 阶段 5：输出评审报告

**Read `references/5-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**现在读取 `references/5-report.md` 并遵循它** — 本阶段的步骤在该文件中，不在此处。若本阶段期间对话被压缩或恢复，请重新读取。

## Phase 6: Write Report and Flag GDDs

## 阶段 6：写入报告并标记 GDD

**Read `references/6-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**现在读取 `references/6-write.md` 并遵循它** — 本阶段的步骤在该文件中，不在此处。若本阶段期间对话被压缩或恢复，请重新读取。

## Phase 7: Handoff

## 阶段 7：交接

**Read `references/7-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

**现在读取 `references/7-handoff.md` 并遵循它** — 本阶段的步骤在该文件中，不在此处。若本阶段期间对话被压缩或恢复，请重新读取。

## Error Recovery Protocol

## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "fails to complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

**首先，验证产物。** 若返回契约点名了某个路径，在将该阶段视为完成之前检查该路径是否存在 —
**点名却不在磁盘上的产物就是失败的阶段，无论回复读起来多么流畅。** 智能体可能耗尽一整个阶段，
返回一段看似合理的开场白却什么也没写，这既不是 BLOCKED，也不是错误，也不属于“未能完成”，
因此下面的触发条件永远不会激发。以未满足的契约点名并恢复它；上下文通常还在。

If any spawned agent returns BLOCKED, errors, or fails to complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report** (retry scope here = fewer GDDs / single-system). Full procedure:
`.claude/docs/error-recovery-protocol.md`.

若任何派生的智能体返回 BLOCKED、出错或未能完成：**立即暴露它，不要越过它所阻塞的依赖继续，
并始终产出一份部分报告**（此处的重试范围 = 更少的 GDD / 单系统）。完整流程：
`.claude/docs/error-recovery-protocol.md`。

---

## Collaborative Protocol

## 协作协议

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see `.claude/docs/automation-modes.md`. In `autonomous` mode the
PASS/CONCERNS/FAIL verdict is still printed and logged — only the closing
handoff widget is skipped.

**在 `collaborative` 模式（默认）下。** 关于 `guided` 与 `autonomous` 模式，
见 `.claude/docs/automation-modes.md`。在 `autonomous` 模式下，PASS/CONCERNS/FAIL 判定仍会打印并记录 —
仅跳过收尾交接控件。

1. **Read silently** — load all GDDs before presenting anything
2. **Show everything** — present the full consistency and design theory analysis
   before asking for any action
3. **Distinguish blocking from advisory** — not every issue needs to block
   architecture; be clear about which do
4. **Don't make design decisions** — flag contradictions and options, but never
   unilaterally decide which GDD is "right"
5. **Ask before writing** — confirm before writing the report or updating the
   systems index
6. **Be specific** — every issue must cite the exact GDD, section, and text
   involved; no vague warnings

1. **静默读取** — 在呈现任何内容之前加载所有 GDD
2. **展示全部** — 在请求任何行动之前呈现完整的一致性与设计理论分析
3. **区分阻塞与提示** — 并非每个问题都需要阻塞架构；清楚说明哪些需要
4. **不做设计决策** — 标记矛盾与选项，但绝不单方面决定哪个 GDD 是“对的”
5. **写入前先询问** — 写入报告或更新系统索引之前先确认
6. **具体明确** — 每个问题都必须引用确切的 GDD、小节与相关文本；不要含糊的警告
