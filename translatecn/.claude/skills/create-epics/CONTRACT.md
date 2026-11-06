# /create-epics — Handoff Contract

# /create-epics — 交接契约

## Role in Pipeline

## 在流程中的角色

Translates approved GDDs and architecture documents into one EPIC.md file per
architectural module, defining scope, ADR governance, engine risk, and requirement
traceability — sits between architecture review and story decomposition.

将已批准的 GDD 与架构文档转化为每个架构模块一个 EPIC.md 文件，界定范围、ADR 治理、引擎风险
与需求可追溯性 — 位于架构评审与故事拆解之间。

## Inputs Required

## 所需输入

### Files That Must Exist

### 必须存在的文件

| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `design/gdd/systems-index.md` | System list, layer assignments, priority order | Yes |
| `design/gdd/[system].md` | `## Summary`, `## Acceptance Criteria`, `## Overview` (all 8 required sections) | Yes |
| `docs/architecture/architecture.md` | Module ownership, API boundaries | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (all governing ADRs) | `Status:`, `GDD Requirements Addressed`, `Decision`, `Engine Compatibility` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` date in header | Yes |
| `docs/architecture/tr-registry.yaml` | TR-IDs with `id`, `system`, requirement text | Yes |
| `docs/engine-reference/[engine]/VERSION.md` | Engine name, version, risk levels | Yes |

| 文件 | 所需字段 / 小节 | 只读？ |
|------|---------------------------|-----------|
| `design/gdd/systems-index.md` | 系统列表、分层归属、优先级顺序 | 是 |
| `design/gdd/[system].md` | `## Summary`、`## Acceptance Criteria`、`## Overview`（全部 8 个必需小节） | 是 |
| `docs/architecture/architecture.md` | 模块归属、API 边界 | 是 |
| `docs/architecture/adr-NNNN-[slug].md`（所有管辖 ADR） | `Status:`、`GDD Requirements Addressed`、`Decision`、`Engine Compatibility` | 是 |
| `docs/architecture/control-manifest.md` | 头部的 `Manifest Version:` 日期 | 是 |
| `docs/architecture/tr-registry.yaml` | 带 `id`、`system`、需求文本的 TR-ID | 是 |
| `docs/engine-reference/[engine]/VERSION.md` | 引擎名称、版本、风险等级 | 是 |

> **Tier.** The rows above and the preconditions below are the `full` inputs.
> SKILL.md relaxes them by `workflow`: at `standard`, GDDs need the 5 required
> sections (+ conditional Formulas), only critical (Foundation-layer) ADRs are
> expected and traced, and the control manifest is read if present, not required.
> At `minimal` the skill is optional and off the path (`/create-stories`
> synthesizes the epic itself), and it says so first; if run, it skips the GDD and
> architecture reads, reads only `design/game-brief.md` (stopping if that is
> missing), takes its order from the brief's Build order instead of
> `systems-index.md`, and requires no GDD, ADR, architecture document, TR registry
> or control manifest. A short brief is one epic slugged from the brief's working
> title, the slug `/create-stories` uses when nothing is typed; a user who asks for
> the work grouped gets one epic per group of MVP features.

> **层级。** 上面的行与下面的前置条件是 `full` 输入。
> SKILL.md 按 `workflow` 放宽它们：在 `standard` 下，GDD 需要 5 个必需
> 小节（+ 条件性 Formulas），仅预期并追溯关键（Foundation 层）ADR，
> 控制清单若存在则读取，非必需。
> 在 `minimal` 下，本技能是可选的且不在流程路径上（`/create-stories`
> 自行合成史诗），且会先说明；若运行，它跳过 GDD 与
> 架构读取，只读 `design/game-brief.md`（若缺失则停止），
> 从简报的构建顺序而非 `systems-index.md` 取得顺序，
> 且不需要任何 GDD、ADR、架构文档、TR 注册表
> 或控制清单。简短的简报就是一个史诗，slug 取自简报的工作
> 标题，即未输入任何内容时 `/create-stories` 使用的 slug；要求
> 将工作分组的用户，每组 MVP 功能得到一个史诗。

### Preconditions

### 前置条件

- `/create-control-manifest` has been run and `docs/architecture/control-manifest.md` exists
- `/architecture-review` has passed (at minimum Foundation and Core ADRs are Accepted)
- All in-scope GDDs have status `Approved` or `Designed` in `systems-index.md`
- The target layer's GDDs are stable — do not run for Feature layer until Core is nearly complete

- `/create-control-manifest` 已运行且 `docs/architecture/control-manifest.md` 存在
- `/architecture-review` 已通过（至少 Foundation 与 Core 的 ADR 已接受）
- 所有在范围内 GDD 在 `systems-index.md` 中的状态为 `Approved` 或 `Designed`
- 目标分层的 GDD 稳定 — 在 Core 接近完成之前不要为 Feature 层运行

## Outputs Produced

## 产出的输出

### Files Written

### 写入的文件

| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/[epic-slug]/EPIC.md` | `Layer`, `GDD` path, `Architecture Module`, `Status: Ready`, `## Governing ADRs` table, `## GDD Requirements` table with TR-IDs and ADR coverage, `## Definition of Done`, `## Overview` | Created per approved epic |
| `production/epics/index.md` | `Epic`, `Layer`, `System`, `GDD`, `Stories`, `Status` columns | Created, or a row added per new epic; an existing epic's row is updated in place and keeps its `Stories` value |

| 文件 | 保证的字段 / 小节 | 备注 |
|------|------------------------------|-------|
| `production/epics/[epic-slug]/EPIC.md` | `Layer`、`GDD` 路径、`Architecture Module`、`Status: Ready`、`## Governing ADRs` 表、含 TR-ID 与 ADR 覆盖的 `## GDD Requirements` 表、`## Definition of Done`、`## Overview` | 每个已批准史诗创建一个 |
| `production/epics/index.md` | `Epic`、`Layer`、`System`、`GDD`、`Stories`、`Status` 列 | 创建，或每个新史诗添加一行；既有史诗的行原地更新并保留其 `Stories` 值 |

### Output Guarantees

### 输出保证

- Every EPIC.md contains a `## Governing ADRs` table with at least one row (or a documented note if none apply)
- Every EPIC.md contains a `## GDD Requirements` table where each row has a `TR-ID` and an `ADR Coverage` cell: `ADR-NNNN ✅` (an Accepted ADR), `❌ No ADR`, or `❌ No ADR (ADR-NNNN Proposed)` when the only ADR addressing it is not Accepted, so `/create-stories` still sees that ADR and blocks its story
- The `GDD:` field in the EPIC.md header is a valid relative path to the source GDD
- The `Layer:` field is one of: Foundation, Core, Feature, Presentation
- The `Status:` field is set to `Ready`
- The `Stories:` field reads `Not yet created — run /create-stories [epic-slug]` on a new epic; an EPIC.md that already existed is updated in place (after an update-or-skip ask) and keeps its `Stories:` line and `## Stories` table
- Untraced requirements (TR-IDs with no Accepted ADR) are flagged in the GDD Requirements table with `❌ No ADR` and listed under Untraced Requirements; the ⚠️ warning fires for each at `full`, and at `standard` only for Foundation-layer ones
- `production/epics/index.md` has an entry for every epic written in this run
- A PR-EPIC review that could not judge the epics (no milestone timeline or team capacity) is reported as `PR-EPIC: NOT ASSESSED — [input]` and never read as REALISTIC

- 每个 EPIC.md 都包含一个 `## Governing ADRs` 表，至少一行（若无适用项，则为有记录的说明）
- 每个 EPIC.md 都包含一个 `## GDD Requirements` 表，其中每行有一个 `TR-ID` 和一个 `ADR Coverage` 单元格：`ADR-NNNN ✅`（已接受 ADR）、`❌ No ADR`，或当唯一处理它的 ADR 未被接受时为 `❌ No ADR (ADR-NNNN Proposed)`，这样 `/create-stories` 仍能看到该 ADR 并阻塞其故事
- EPIC.md 头部的 `GDD:` 字段是指向源 GDD 的有效相对路径
- `Layer:` 字段为以下之一：Foundation、Core、Feature、Presentation
- `Status:` 字段设为 `Ready`
- 新史诗的 `Stories:` 字段读作 `Not yet created — run /create-stories [epic-slug]`；已存在的 EPIC.md 原地更新（在更新或跳过的询问之后）并保留其 `Stories:` 行与 `## Stories` 表
- 未追溯需求（没有已接受 ADR 的 TR-ID）在 GDD Requirements 表中以 `❌ No ADR` 标记，并列在 Untraced Requirements 下；⚠️ 警告在 `full` 下为每一条激发，在 `standard` 下仅为 Foundation 层的激发
- `production/epics/index.md` 为本次运行写入的每个史诗都有条目
- 无法判断史诗的 PR-EPIC 评审（没有里程碑时间线或团队容量）报告为 `PR-EPIC: NOT ASSESSED — [input]`，绝不被读作 REALISTIC

## Immutability Rules

## 不可变性规则

- READS but does NOT modify: `design/gdd/systems-index.md`, all GDD files, `docs/architecture/architecture.md`, all ADR files in `docs/architecture/adr-NNNN-[slug].md` pattern, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, `docs/engine-reference/[engine]/VERSION.md`
- MODIFIES: `production/epics/[epic-slug]/EPIC.md` (creates, or updates in place keeping its Stories table), `production/epics/index.md` (creates or updates)

- 读取但不修改：`design/gdd/systems-index.md`、所有 GDD 文件、`docs/architecture/architecture.md`、`docs/architecture/adr-NNNN-[slug].md` 模式的所有 ADR 文件、`docs/architecture/control-manifest.md`、`docs/architecture/tr-registry.yaml`、`docs/engine-reference/[engine]/VERSION.md`
- 修改：`production/epics/[epic-slug]/EPIC.md`（创建，或原地更新并保留其 Stories 表）、`production/epics/index.md`（创建或更新）

## Hard Constraints (Never Violate)

## 硬性约束（绝不违反）

- Never create story files — this skill stops at the epic level
- Never invent content not sourced from GDDs, ADRs, or architecture docs
- Never skip the per-epic approval prompt before writing
- Never write an EPIC.md without first presenting the epic definition to the user
- Never overwrite an existing EPIC.md or reset its `## Stories` table — update it in place, or skip it. `write-guard.sh overwrite` runs right before each new write and stops it when the file exists
- Never mark a TR-ID as covered by an ADR unless that ADR's `Status:` is `Accepted`
- Never create epics for a layer whose dependency layer is not yet substantially complete

- 绝不创建故事文件 — 本技能止步于史诗层级
- 绝不编造不来源于 GDD、ADR 或架构文档的内容
- 写入前绝不跳过逐史诗的批准询问
- 绝不未先向用户呈现史诗定义就写入 EPIC.md
- 绝不覆盖既有 EPIC.md 或重置其 `## Stories` 表 — 原地更新，或跳过。`write-guard.sh overwrite` 在每次新写入前运行，并在文件存在时阻止写入
- 除非 ADR 的 `Status:` 为 `Accepted`，绝不将 TR-ID 标记为由该 ADR 覆盖
- 绝不为依赖分层尚未基本完成的分层创建史诗

## Downstream Skill Expects

## 下游技能期望

**Next skill:** /create-stories

**下一个技能：** /create-stories

It will read:
- `production/epics/[epic-slug]/EPIC.md` — specifically: `Layer:`, `GDD:` path, `Architecture Module:`, the full `## Governing ADRs` table (ADR IDs and summaries), and the full `## GDD Requirements` table (TR-IDs and ADR coverage status)
- `production/epics/index.md` — to enumerate available epics when no argument is given

它将读取：
- `production/epics/[epic-slug]/EPIC.md` — 具体为：`Layer:`、`GDD:` 路径、`Architecture Module:`、完整的 `## Governing ADRs` 表（ADR ID 与摘要），以及完整的 `## GDD Requirements` 表（TR-ID 与 ADR 覆盖状态）
- `production/epics/index.md` — 在未给参数时枚举可用史诗

It assumes:
- The `GDD:` path in EPIC.md resolves to a readable file
- Every ADR listed in `## Governing ADRs` exists as a file and has an `Accepted` status
- TR-IDs in `## GDD Requirements` match entries in `docs/architecture/tr-registry.yaml`
- The epic slug used in the directory name matches the slug referenced in `index.md`
- `Status: Ready` does not by itself mean no stories exist — an EPIC.md updated in place keeps its stories; read its `Stories:` line

它假设：
- EPIC.md 中的 `GDD:` 路径解析为可读文件
- `## Governing ADRs` 中列出的每个 ADR 都存在文件且状态为 `Accepted`
- `## GDD Requirements` 中的 TR-ID 与 `docs/architecture/tr-registry.yaml` 中的条目一致
- 目录名中使用的史诗 slug 与 `index.md` 中引用的 slug 一致
- `Status: Ready` 本身并不意味着不存在故事 — 原地更新的 EPIC.md 会保留其故事；请读取其 `Stories:` 行

## Known Fragile Points

## 已知脆弱点

- If the EPIC.md template structure changes (section names, header field names, table column order), `/create-stories` will silently fail to parse governance data and may produce incomplete or incorrect stories
- If `tr-registry.yaml` is regenerated with renumbered IDs after EPIC.md files are written, the TR-IDs in existing EPIC.md files become stale and mislead `/create-stories`
- If an ADR is retroactively changed from `Accepted` to `Proposed` after the epic is written, the EPIC.md still shows it as governing. `/create-stories` reads every named ADR's current status with `adr-status.sh` and blocks the stories, but the epic's coverage column stays stale until `/create-epics` updates the epic in place
- If `systems-index.md` layer assignments change after epics are created, the `Layer:` field in existing EPIC.md files will be incorrect and `/create-stories` will use the wrong layer context
- `production/epics/index.md` rows are matched to epics by slug — an epic whose slug changes gets a new row, and the old row stays behind

- 若 EPIC.md 模板结构改变（小节名、头部字段名、表格列顺序），`/create-stories` 会静默解析治理数据失败，可能产出不完整或不正确的故事
- 若 `tr-registry.yaml` 在 EPIC.md 文件写入后以重新编号的 ID 重新生成，既有 EPIC.md 文件中的 TR-ID 会变旧并误导 `/create-stories`
- 若某 ADR 在史诗写入后被追溯地由 `Accepted` 改为 `Proposed`，EPIC.md 仍将其显示为管辖项。`/create-stories` 会用 `adr-status.sh` 读取每个具名 ADR 的当前状态并阻塞故事，但史诗的覆盖列会保持陈旧，直到 `/create-epics` 原地更新该史诗
- 若 `systems-index.md` 的分层归属在史诗创建后改变，既有 EPIC.md 文件中的 `Layer:` 字段将不正确，`/create-stories` 会使用错误的分层上下文
- `production/epics/index.md` 的行按 slug 与史诗匹配 — slug 改变的史诗会得到新行，而旧行会留在原处
