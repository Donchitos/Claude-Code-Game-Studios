# Story [NNN]: [title]
# 故事 [NNN]：[标题]

> **Epic**: [epic name]
> **Status**: [Ready | Blocked — BLOCKED: <reason>]
> **Layer**: [Foundation / Core / Feature / Presentation]
> **Type**: [Logic | Integration | Visual/Feel | UI | Config/Data]
> **Estimate**: [S | M | L, or hours — /create-stories proposes one]
> **Manifest Version**: [date from control-manifest.md header]
> **Last Updated**: [set by /dev-story when implementation begins]
> **史诗**：[epic name]
> **状态**：[Ready | Blocked — BLOCKED: <reason>]
> **层级**：[Foundation / Core / Feature / Presentation]
> **类型**：[Logic | Integration | Visual/Feel | UI | Config/Data]
> **估算**：[S | M | L，或小时数 —— 由 /create-stories 提议]
> **清单版本**：[control-manifest.md 头部中的日期]
> **最后更新**：[实现开始时由 /dev-story 设置]

## Context
## 上下文

**GDD**: `design/gdd/[filename].md`
**Requirement**: `TR-[system]-NNN`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*
**GDD**：`design/gdd/[filename].md`
**需求**：`TR-[system]-NNN`
*（需求文本位于 `docs/architecture/tr-registry.yaml` —— 评审时重新读取）*

**ADR Governing Implementation**: [ADR-NNNN: title]
**ADR Decision Summary**: [1-2 sentence summary of what the ADR decided]
**ADR Version**: [the ADR's `## Last Verified` date, else its `## Date`, else `unversioned`]
**约束实现的 ADR**：[ADR-NNNN: title]
**ADR 决策摘要**：[1-2 句概述该 ADR 决定了什么]
**ADR 版本**：[该 ADR 的 `## Last Verified` 日期，否则其 `## Date`，否则 `unversioned`]

**Engine**: [name + version] | **Risk**: [LOW / MEDIUM / HIGH]
**Engine Notes**: [from ADR Engine Compatibility section — post-cutoff APIs, verification required]
**引擎**：[名称 + 版本] | **风险**：[LOW / MEDIUM / HIGH]
**引擎备注**：[来自 ADR 的引擎兼容性章节 —— 截止日期后的 API，需要验证]

**Control Manifest Rules (this layer)**:
- Required: [relevant required pattern]
- Forbidden: [relevant forbidden pattern]
- Guardrail: [relevant performance guardrail]
**控制清单规则（本层级）**：
- 必需：[相关的必需模式]
- 禁止：[相关的禁止模式]
- 护栏：[相关的性能护栏]

---

## Acceptance Criteria
## 验收标准

*From GDD `design/gdd/[filename].md`, scoped to this story:*
*来自 GDD `design/gdd/[filename].md`，限定于本故事：*

- [ ] [criterion 1 — directly from GDD]
- [ ] [标准 1 —— 直接来自 GDD]
- [ ] [criterion 2]
- [ ] [标准 2]
- [ ] [performance criterion if applicable]
- [ ] [性能标准（如适用）]

---

## Implementation Notes
## 实现备注

*Derived from ADR-NNNN Implementation Guidelines:*
*源自 ADR-NNNN 的实现指南：*

[Specific, actionable guidance from the ADR. Do not paraphrase in ways that
change meaning. This is what the programmer reads instead of the ADR.]
[来自该 ADR 的具体、可执行的指导。不要以改变含义的方式转述。
这是程序员代替阅读 ADR 时所读的内容。]

---

## Out of Scope
## 范围之外

*Handled by neighbouring stories — do not implement here:*
*由相邻故事处理 —— 不要在此实现：*

- [Story NNN+1]: [what it handles]
- [故事 NNN+1]：[它处理的内容]

---

## Files
## 文件

*The code and test files this story creates or changes. `/create-stories` lists the
planned ones; `/dev-story` replaces the list with the files it changed; `/story-done`
checks scope against it.*
*本故事创建或更改的代码与测试文件。`/create-stories` 列出计划中的文件；
`/dev-story` 将其替换为实际更改的文件；`/story-done` 据此核对范围。*

- [path under the code root]
- [代码根目录下的路径]
- [test path]
- [测试路径]

---

## QA Test Cases
## QA 测试用例

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation. (At tiers where the QL-STORY-READY gate is skipped — `minimal`, or `lean`/`solo` review mode — no qa-lead specs exist, and this section reads: N/A — no qa-lead specs at this tier; implement against the Acceptance Criteria above.)*
*由 qa-lead 在故事创建时编写。开发人员依据这些用例实现 —— 实现过程中不要自行发明新测试用例。（在跳过 QL-STORY-READY 门控的层级 —— `minimal`，或 `lean`/`solo` 评审模式 —— 不存在 qa-lead 规格，此章节写为：N/A —— 本层级没有 qa-lead 规格；依据上方的验收标准实现。）*

**[For Logic / Integration stories — automated test specs]:**
**[适用于 Logic / Integration 故事 —— 自动化测试规格]：**

- **AC-1**: [criterion text]
  - Given: [precondition]
  - When: [action]
  - Then: [assertion]
  - Edge cases: [boundary values / failure states]
- **AC-1**：[标准文本]
  - 前提： [precondition]
  - 当： [action]
  - 则： [assertion]
  - 边界情况：[边界值 / 失败状态]

**[For Visual/Feel / UI stories — manual verification steps]:**
**[适用于 Visual/Feel / UI 故事 —— 手动验证步骤]：**

- **AC-1**: [criterion text]
  - Setup: [how to reach the state]
  - Verify: [what to look for]
  - Pass condition: [unambiguous pass description]
- **AC-1**：[标准文本]
  - 准备：[如何到达该状态]
  - 验证：[应观察什么]
  - 通过条件：[无歧义的通过描述]

---

## Test Evidence
## 测试证据

*Governed by `qa.level`: at `qa.level: minimal` tests are **waived** (advisory, never "must exist and pass"), but a Visual/Feel or UI story's retained screenshot is not.*
*受 `qa.level` 约束：在 `qa.level: minimal` 下测试**被豁免**（仅作建议，绝非“必须存在且通过”），但 Visual/Feel 或 UI 故事保留的截图不豁免。*

**Story Type**: [type]
**Required evidence**:
- Logic: `tests/unit/[system]/[story-slug]_test.[ext]` — must exist and pass (`/story-done` checks that it EXISTS; pass/fail is established by `/gate-check` and `/smoke-check`, both later)
- Integration: `tests/integration/[system]/[story-slug]_test.[ext]` OR playtest doc
- Visual/Feel: a retained screenshot in `production/qa/evidence/` + sign-off in `production/qa/evidence/[story-slug]-evidence.md`
- UI: a retained screenshot of each screen touched, in `production/qa/evidence/`
- Config/Data: smoke check pass (`production/qa/smoke-*.md`)
**故事类型**：[type]
**必需证据**：
- Logic：`tests/unit/[system]/[story-slug]_test.[ext]` —— 必须存在并通过（`/story-done` 检查其是否**存在**；通过/失败由后续的 `/gate-check` 和 `/smoke-check` 判定）
- Integration：`tests/integration/[system]/[story-slug]_test.[ext]` 或试玩文档
- Visual/Feel：`production/qa/evidence/` 中保留的截图 + `production/qa/evidence/[story-slug]-evidence.md` 中的签署确认
- UI：每个涉及界面的保留截图，存放于 `production/qa/evidence/`
- Config/Data：冒烟检查通过（`production/qa/smoke-*.md`）

**Status**: [ ] Not yet created
**状态**：[ ] 尚未创建

---

## Dependencies
## 依赖

- Depends on: [the path of each story that must be DONE first, e.g. `production/epics/<epic>/story-001-<slug>.md`, or "None"]
- Unlocks: [the path of each story this one unblocks, or "None"]
- 依赖于：[必须先完成（DONE）的每个故事的路径，例如 `production/epics/<epic>/story-001-<slug>.md`，或“None”]
- 解锁：[本故事为其解除阻塞的每个故事的路径，或“None”]
