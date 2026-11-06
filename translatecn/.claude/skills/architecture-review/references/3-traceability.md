# /architecture-review — Phases 3 and 3b: Traceability Matrix and Story Linkage
# /architecture-review — 阶段 3 与 3b：可追溯性矩阵与故事关联

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 3: Build the Traceability Matrix
## 阶段 3：构建可追溯性矩阵

**In this file:**
**本文件内容：**

- Step 3b-1 — Load stories
- 步骤 3b-1 — 加载故事
- Step 3b-2 — Load test files
- 步骤 3b-2 — 加载测试文件
- Step 3b-3 — Build the extended RTM
- 步骤 3b-3 — 构建扩展 RTM

For each technical requirement extracted in Phase 2, search the ADRs:
对阶段 2 中提取的每项技术需求，搜索 ADR：

1. Use the ADRs **already loaded in Phase 1b** — do not re-read them. Extract each
   ADR's "GDD Requirements Addressed" section from what is already in context.
   (If Phase 1b ran in a mode that did not load every ADR, `Grep pattern="## GDD
   Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content"
   -A 15` fills the gap without a full re-read.)
1. 使用**阶段 1b 中已加载的 ADR** — 不要重新读取它们。从已在上下文中的内容里
   提取每个 ADR 的 "GDD Requirements Addressed" 小节。（若阶段 1b 以未加载
   每个 ADR 的模式运行，`Grep pattern="## GDD
   Requirements Addressed" glob="docs/architecture/adr-*.md" output_mode="content"
   -A 15` 可在不完整重读的情况下补足缺口。）
2. Check if it explicitly references the requirement or its GDD
2. 检查它是否显式引用了该需求或其 GDD
3. Check if the ADR's decision text implicitly covers the requirement
3. 检查该 ADR 的决策文本是否隐含覆盖了该需求
4. Mark coverage status:
4. 标记覆盖状态：

| Status | Meaning |
|--------|---------|
| ✅ **Covered** | An **Accepted** ADR explicitly addresses this requirement |
| 🟡 **Covered (Proposed)** | An ADR addresses it, but that ADR is still `Proposed` |
| ⚠️ **Partial** | An ADR partially covers this, or coverage is ambiguous |
| ❌ **Gap** | No ADR addresses this requirement |
| ❓ **Not assessed** | The ADR is unreadable, or has no `## Status` section |

| 状态 | 含义 |
|--------|---------|
| ✅ **已覆盖** | 一个 **Accepted** 的 ADR 明确处理了该需求 |
| 🟡 **已覆盖（Proposed）** | 有 ADR 处理它，但该 ADR 仍为 `Proposed` |
| ⚠️ **部分覆盖** | 有 ADR 部分覆盖它，或覆盖情况有歧义 |
| ❌ **缺口** | 没有 ADR 处理该需求 |
| ❓ **未评估** | 该 ADR 无法读取，或没有 `## Status` 小节 |

> **Read each ADR's `## Status` before marking coverage — an unaccepted decision
> is not coverage.** If `✅` meant only that *an ADR addresses this*, with no
> status qualification, a requirement covered entirely by `Proposed` ADRs would
> count as covered and this review could return **PASS: All requirements
> covered** over an architecture nobody had accepted. Four skills downstream
> (`create-control-manifest`, `create-epics`, `create-stories`, `gate-check`)
> require `Accepted`, so a PASS on that basis sends work forward that every one
> of them will refuse.
> **在标记覆盖之前，读取每个 ADR 的 `## Status` — 未被接受的决策不算覆盖。**
> 如果 `✅` 仅表示*有 ADR 处理这一点*而不带状态限定，那么完全由 `Proposed`
> ADR 覆盖的需求就会被算作已覆盖，本次评审就可能在一份无人接受的架构之上
> 返回 **PASS: All requirements covered**。下游的四个技能
> （`create-control-manifest`、`create-epics`、`create-stories`、`gate-check`）
> 都要求 `Accepted`，因此基于该依据的 PASS 会把工作推向前方，而它们中的
> 每一个都会拒绝。
>
> `🟡` is **not** a pass state: it caps the verdict at **CONCERNS**, and names the
> route out — `/architecture-decision accept ADR-NNNN`. That route is the only
> thing that moves an ADR to `Accepted`; without it, grading `Proposed` as
> covered would be the only option, which is why it must never be graded so.
>
> `🟡` **不是**通过状态：它把裁决上限设为 **CONCERNS**，并指明出路 —
> `/architecture-decision accept ADR-NNNN`。该路径是唯一能把 ADR 变为
> `Accepted` 的东西；若没有它，把 `Proposed` 评为已覆盖就会成为唯一选项，
> 这正是绝不可如此评级的原因。

Build the full matrix:
构建完整矩阵：

```
## Traceability Matrix

| Requirement ID | GDD | System | Requirement | ADR Coverage | Status |
|---------------|-----|--------|-------------|--------------|--------|
| TR-combat-001 | combat.md | Combat | Hitbox detection < 1 frame | ADR-0003 | ✅ |
| TR-combat-002 | combat.md | Combat | Combo window timing | — | ❌ GAP |
| TR-inventory-001 | inventory.md | Inventory | Persistent item storage | ADR-0005 | ✅ |
```

Count the totals: X covered, Y partial, Z gaps.
统计总数：X 项已覆盖、Y 项部分覆盖、Z 项缺口。

---

## Phase 3b: Story and Test Linkage (RTM mode only)
## 阶段 3b：故事与测试关联（仅 RTM 模式）

*Skip this phase unless the argument is `rtm` or `full` with stories present.*
*除非参数为 `rtm`，或为存在故事的 `full`，否则跳过此阶段。*

This phase extends the Phase 3 matrix to include the story that implements
each requirement and the test that verifies it — producing the full
Requirements Traceability Matrix (RTM).
此阶段扩展阶段 3 的矩阵，纳入实现每项需求的故事以及验证它的测试 — 从而产出
完整的需求可追溯性矩阵（RTM）。

### Step 3b-1 — Load stories
### 步骤 3b-1 — 加载故事

Glob `production/epics/**/*.md` (excluding EPIC.md index files) to establish the
denominator. Then collect the fields with **targeted section greps, not a full
read of each story** — the same two-grep form `/test-evidence-review` uses for
this identical extraction:
Glob `production/epics/**/*.md`（排除 EPIC.md 索引文件）以确立分母。然后用
**定向小节 grep 而非完整读取每个故事**的方式收集字段 — 与
`/test-evidence-review` 对同一提取所用的双 grep 形式相同：

```
Grep pattern="## Test Evidence" glob="production/epics/**/story-*.md" output_mode="content" -A 8
Grep pattern="TR-" glob="production/epics/**/story-*.md" output_mode="content"
```

- **TR-ID** — from the second grep.
- **TR-ID** — 来自第二个 grep。
- **Test file path** — under `## Test Evidence`, captured by the first grep's `-A 8`.
- **测试文件路径** — 位于 `## Test Evidence` 之下，由第一个 grep 的 `-A 8` 捕获。
- **Status** — from the story header; add `Grep pattern="^> \*\*Status\*\*"` if not already captured.
- **状态** — 来自故事头部；若尚未捕获，添加 `Grep pattern="^> \*\*Status\*\*"`。
- **Story path and title** — from the file name and path; no read at all.
- **故事路径和标题** — 来自文件名和路径；完全无需读取。

Full-read a story only when its Test Evidence section is missing or ambiguous.
仅当某个故事的 Test Evidence 小节缺失或有歧义时，才完整读取该故事。

### Step 3b-2 — Load test files
### 步骤 3b-2 — 加载测试文件

Glob the engine's test root (`.claude/docs/directory-structure.md`): Godot
`tests/unit/**/*_test.*` and `tests/integration/**/*_test.*`; Unity
`Assets/Tests/**/*Tests.cs`; Unreal `Source/*/Private/Tests/**/*.cpp`. With no
engine configured, say the test index could not be built rather than reading an
empty glob as "no tests". Build an index: system → [test file paths].
Glob 引擎的测试根目录（`.claude/docs/directory-structure.md`）：Godot 为
`tests/unit/**/*_test.*` 和 `tests/integration/**/*_test.*`；Unity 为
`Assets/Tests/**/*Tests.cs`；Unreal 为 `Source/*/Private/Tests/**/*.cpp`。若未
配置引擎，说明无法建立测试索引，而不要把空 glob 读作"没有测试"。建立索引：
系统 → [测试文件路径]。

For each test file path from Step 3b-1, confirm via Glob whether the file
actually exists. Note MISSING if the stated path does not exist.
对步骤 3b-1 中的每个测试文件路径，通过 Glob 确认该文件是否确实存在。若所述
路径不存在，则标记为 MISSING。

### Step 3b-3 — Build the extended RTM
### 步骤 3b-3 — 构建扩展 RTM

For each TR-ID in the Phase 3 matrix, add:
对阶段 3 矩阵中的每个 TR-ID，添加：
- **Story**: the story file path(s) that reference this TR-ID (may be multiple)
- **Story**：引用该 TR-ID 的故事文件路径（可能多个）
- **Test File**: the test file path stated in the story's Test Evidence section
- **Test File**：故事 Test Evidence 小节中所陈述的测试文件路径
- **Test Status**: COVERED (test file exists) / MISSING (path stated but not
  found) / NONE (no test path stated, story type may be Visual/Feel/UI) /
  NO STORY (requirement has no story yet — pre-production gap)
- **Test Status**：COVERED（测试文件存在）/ MISSING（陈述了路径但未找到）/
  NONE（未陈述测试路径，故事类型可能为 Visual/Feel/UI）/
  NO STORY（需求尚无故事 — 预制作缺口）

Extended matrix format:
扩展矩阵格式：

```
## Requirements Traceability Matrix (RTM)

| TR-ID | GDD | Requirement | ADR | Story | Test File | Test Status |
|-------|-----|-------------|-----|-------|-----------|-------------|
| TR-combat-001 | combat.md | Hitbox < 1 frame | ADR-0003 | story-001-hitbox.md | tests/unit/combat/hitbox_test.gd | COVERED |
| TR-combat-002 | combat.md | Combo window | — | story-002-combo.md | — | NONE (Visual/Feel) |
| TR-inventory-001 | inventory.md | Persistent storage | ADR-0005 | — | — | NO STORY |
```

RTM coverage summary:
RTM 覆盖摘要：
- COVERED: [N] — requirements with ADR + story + passing test
- COVERED：[N] — 具备 ADR + 故事 + 通过测试的需求
- MISSING test: [N] — story exists but test file not found
- MISSING test：[N] — 故事存在但未找到测试文件
- NO STORY: [N] — requirements with ADR but no story yet
- NO STORY：[N] — 有 ADR 但尚无故事的需求
- NO ADR: [N] — requirements without architectural coverage (from Phase 3 gaps)
- NO ADR：[N] — 没有架构覆盖的需求（来自阶段 3 缺口）
- Full chain complete (COVERED): [N/total] ([%])
- 完整链路完成（COVERED）：[N/total]（[%]）

---
