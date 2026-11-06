---
name: architecture-review
description: "Traceability matrix mapping GDD requirements to ADRs. Finds gaps, cross-ADR conflicts, engine compatibility. PASS/CONCERNS/NOT ASSESSED/FAIL."
argument-hint: "[focus: full | coverage | consistency | engine | rtm | single-gdd path/to/gdd.md]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/architecture-review/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-receipts.sh check *), Bash(bash .claude/scripts/review-receipts.sh hash *), Bash(bash .claude/scripts/adr-dep-graph.sh*), Bash(bash .claude/scripts/registry.sh validate*)
model: opus
---
---
name: architecture-review
description: "将 GDD 需求映射到 ADR 的可追溯性矩阵。发现缺口、跨 ADR 冲突、引擎兼容性。PASS/CONCERNS/NOT ASSESSED/FAIL。"
argument-hint: "[focus: full | coverage | consistency | engine | rtm | single-gdd path/to/gdd.md]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/architecture-review/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-receipts.sh check *), Bash(bash .claude/scripts/review-receipts.sh hash *), Bash(bash .claude/scripts/adr-dep-graph.sh*), Bash(bash .claude/scripts/registry.sh validate*)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

# Architecture Review
# 架构评审

The architecture review validates that the complete body of architectural decisions
covers all game design requirements, is internally consistent, and correctly targets
the project's pinned engine version. It is the quality gate between Technical Setup
and Pre-Production.
架构评审验证整套架构决策是否覆盖所有游戏设计需求、内部是否一致，并是否正确针对
项目固定的引擎版本。它是技术搭建与预制作之间的质量门禁。

**Argument modes:**
- **No argument / `full`**: Full review — all phases
- **`coverage`**: Traceability only — which GDD requirements have no ADR
- **`consistency`**: Cross-ADR conflict detection only
- **`engine`**: Engine compatibility audit only
- **`single-gdd [path]`**: Review architecture coverage for one specific GDD
- **`rtm`**: Requirements Traceability Matrix — extends the standard matrix
  to include story file paths and test file paths; outputs
  `docs/architecture/requirements-traceability.md` with the full
  GDD requirement → ADR → Story → Test chain. Use in Production phase when
  stories and tests exist.
**参数模式：**
- **无参数 / `full`**：完整评审 — 所有阶段
- **`coverage`**：仅可追溯性 — 哪些 GDD 需求没有 ADR
- **`consistency`**：仅跨 ADR 冲突检测
- **`engine`**：仅引擎兼容性审计
- **`single-gdd [path]`**：评审某一特定 GDD 的架构覆盖
- **`rtm`**：需求可追溯性矩阵 — 扩展标准矩阵
  以包含故事文件路径和测试文件路径；输出
  `docs/architecture/requirements-traceability.md`，含完整的
  GDD 需求 → ADR → 故事 → 测试链路。在有故事和测试的制作阶段使用。

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（collaborative 始终询问 · guided 仅主要项 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full traceability matrix across all GDDs and all ADRs.
- `standard` — reduced scope: architecture doc + critical ADRs only.
- `minimal` — not applicable (no architecture doc required).
**`workflow`**（见 `.claude/docs/workflow-modes.md`）：
- `full` — 覆盖所有 GDD 和所有 ADR 的完整可追溯性矩阵。
- `standard` — 缩减范围：仅架构文档 + 关键 ADR。
- `minimal` — 不适用（不要求架构文档）。

## Phase 1: Load Everything
## 阶段 1：加载全部内容

**Read `references/1-load.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/1-load.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 2: Extract Technical Requirements from Every GDD
## 阶段 2：从每个 GDD 提取技术需求

**Read `references/2-extract-requirements.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/2-extract-requirements.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 3: Build the Traceability Matrix
## 阶段 3：构建可追溯性矩阵

**Read `references/3-traceability.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/3-traceability.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 4: Cross-ADR Conflict Detection
## 阶段 4：跨 ADR 冲突检测

**Read `references/4-conflicts.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/4-conflicts.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 5: Engine Compatibility Cross-Check
## 阶段 5：引擎兼容性交叉检查

**Read `references/5-engine.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/5-engine.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 6: Architecture Document Coverage
## 阶段 6：架构文档覆盖

**Read `references/6-document-coverage.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/6-document-coverage.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 7: Output the Review Report
## 阶段 7：输出评审报告

**Read `references/7-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/7-report.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 8: Write and Update Traceability Index
## 阶段 8：写入并更新可追溯性索引

**Read `references/8-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/8-write.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Phase 9: Handoff
## 阶段 9：交接

**Read `references/9-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.
**立即读取 `references/9-handoff.md` 并按其执行** — 本阶段的具体步骤在该文件中，而非此处。如果对话在本阶段被压缩或恢复，请重新读取该文件。

## Error Recovery Protocol
## 错误恢复协议

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "fails to complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.
**首先，验证产物。** 如果返回契约点名了某个路径，在将该阶段视为完成之前检查
该路径是否存在 — **点名但不在磁盘上的产物是失败的阶段，无论响应读起来多么流畅。** 智能体可能
耗尽整个阶段并返回一段看似合理的开场白，却什么都没写，这
既不是 BLOCKED，也不是错误，也不是 "fails to complete"，因此下文的触发条件
永远不会触发。请点名未满足的契约来恢复它；上下文
通常仍在。

If any spawned agent returns BLOCKED, errors, or fails to complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report** (retry scope here = fewer GDDs / single-system). Full procedure:
`.claude/docs/error-recovery-protocol.md`.
如果任何已启动的智能体返回 BLOCKED、出错或未能完成：**立即呈现它，
不要越过它阻塞的依赖继续，并始终生成
部分报告**（此处的重试范围 = 更少的 GDD / 单系统）。完整流程：
`.claude/docs/error-recovery-protocol.md`。

---

## Collaborative Protocol
## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.
**在 `collaborative` 模式（默认）下适用。** 对于 `guided` 和
`autonomous` 模式，请参阅 `.claude/docs/automation-modes.md` — 下文规则
描述的是协作模式的要求，而非普遍行为。

1. **Read silently** — do not narrate every file read
2. **Show the matrix** — present the full traceability matrix before any write
   approval; let the user see the state
3. **Don't guess** — if a requirement is ambiguous, ask: "Is [X] a technical
   requirement or a design preference?"
4. **Draft before approval** — always show the content that will be written (the
   report, the updated ADR section, the systems-index row) inline in the conversation
   before requesting approval. Never ask to write something the user has not yet seen.
5. **Use `AskUserQuestion` for write approvals** — plain text "May I?" is not
   sufficient. Use the structured tool with labeled options [A]/[B]/[C] so the
   user can choose between "write now", "show full draft first", and "not yet".
   Multi-file changesets must list every file and what changes, then ask once
   with grouped options — not a separate plain-text question per file.
6. **Non-blocking** — the verdict is advisory; the user decides whether to continue
   despite CONCERNS or even FAIL findings
1. **静默读取** — 不要叙述每一次文件读取
2. **展示矩阵** — 在任何写入批准之前呈现完整的可追溯性矩阵；让用户看到状态
3. **不要猜测** — 如果需求含糊，询问："Is [X] a technical
   requirement or a design preference?"
4. **批准前先起草** — 始终在请求批准之前，把将要写入的内容（
   报告、更新后的 ADR 节、systems-index 行）内联展示在对话中。绝不要请求写入用户尚未看到的内容。
5. **使用 `AskUserQuestion` 进行写入批准** — 纯文本 "May I?" 不够。
   使用带标签选项 [A]/[B]/[C] 的结构化工具，使用户
   可以在 "write now"、"show full draft first" 和 "not yet" 之间选择。
   多文件变更集必须列出每个文件及其更改，然后用分组选项询问一次
   — 而不是为每个文件单独进行纯文本提问。
6. **非阻塞** — 裁决是建议性的；用户决定是否在存在 CONCERNS 甚至 FAIL 发现的情况下继续
