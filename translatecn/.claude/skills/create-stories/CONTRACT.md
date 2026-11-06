# /create-stories — Handoff Contract

## Role in Pipeline
Decomposes a single epic into implementable story files by tracing GDD acceptance
criteria through ADR decisions and manifest rules — sits between `/create-epics`
and `/story-readiness` + `/dev-story`.
# /create-stories — 交接契约

## 在流程中的角色
通过将 GDD 验收标准沿着 ADR 决策与清单规则追溯，把单个史诗拆解为可实施的故事文件 — 它位于 `/create-epics`
与 `/story-readiness` + `/dev-story` 之间。

## Inputs Required
## 所需输入

### Files That Must Exist
### 必须存在的文件
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/[epic-slug]/EPIC.md` | `Layer:`, `GDD:` path, `Architecture Module:`, `## Governing ADRs` table, `## GDD Requirements` table with TR-IDs | Yes |
| `design/gdd/[filename].md` | The sections required at the system's tier (all 8 at `full`; the 5 required + conditional Formulas at `standard`), especially `## Acceptance Criteria`, `## Formulas`, `## Edge Cases` | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (all governing ADRs) | `## Status`, `## Summary`, `## Decision` (incl. `### Implementation Guidelines`), `## Engine Compatibility`, `## Last Verified` / `## Date`, the `**Depends On**` row (read through `adr-status.sh`) | Yes |
| `docs/architecture/control-manifest.md` | Layer rules (required patterns, forbidden patterns, guardrails), `Manifest Version:` date in header | Yes |
| `docs/architecture/tr-registry.yaml` | All TR-IDs for the epic's system, with stable `id` values | Yes |
| 文件 | 所需字段 / 小节 | 只读？ |
|------|---------------------------|-----------|
| `production/epics/[epic-slug]/EPIC.md` | `Layer:`、`GDD:` 路径、`Architecture Module:`、`## Governing ADRs` 表、带 TR-ID 的 `## GDD Requirements` 表 | 是 |
| `design/gdd/[filename].md` | 该系统所在 tier 要求的小节（`full` 下全部 8 个；`standard` 下 5 个必需小节 + 条件性的 Formulas），尤其是 `## Acceptance Criteria`、`## Formulas`、`## Edge Cases` | 是 |
| `docs/architecture/adr-NNNN-[slug].md`（所有管辖 ADR） | `## Status`、`## Summary`、`## Decision`（含 `### Implementation Guidelines`）、`## Engine Compatibility`、`## Last Verified` / `## Date`、`**Depends On**` 行（通过 `adr-status.sh` 读取） | 是 |
| `docs/architecture/control-manifest.md` | 层规则（必需模式、禁止模式、护栏）、文件头中的 `Manifest Version:` 日期 | 是 |
| `docs/architecture/tr-registry.yaml` | 该史诗系统的全部 TR-ID，具有稳定的 `id` 值 | 是 |

> **Tier.** The rows above are the `standard`/`full` inputs. At `workflow: minimal`
> the only input is `design/game-brief.md`: the skill writes
> `production/epics/<slug>/EPIC.md` itself from the brief (or uses one that already
> exists there, never rewriting it), needs no `/create-epics`
> run, and reads no GDD, ADR, control manifest or TR registry. Each story traces to
> `Brief MVP feature N` instead of a TR-ID, and its ADR lines read
> `N/A (minimal — no ADRs)` (SKILL.md, the `minimal` branch of Phase 2 and the
> `minimal` field mapping in Phase 7).
> **Tier。** 上表各行是 `standard`/`full` 的输入。在 `workflow: minimal` 下，
> 唯一的输入是 `design/game-brief.md`：该技能从简报自行写入
> `production/epics/<slug>/EPIC.md`（或使用那里已存在的文件，绝不重写它），
> 无需运行 `/create-epics`，且不读取任何 GDD、ADR、控制清单或 TR 注册表。
> 每个故事追溯到 `Brief MVP feature N` 而非 TR-ID，其 ADR 行写为
> `N/A (minimal — no ADRs)`（见 SKILL.md 中阶段 2 的 `minimal` 分支与
> 阶段 7 的 `minimal` 字段映射）。

### Preconditions
- `/create-epics` has been run and the target `EPIC.md` has `Status: Ready`
- The EPIC.md contains a populated `## GDD Requirements` table (not empty)
- All governing ADRs listed in the EPIC.md exist as files
- Foundation epics have stories created before Core epics are started; Core before Feature; Feature before Presentation
### 前置条件
- `/create-epics` 已运行，且目标 `EPIC.md` 具有 `Status: Ready`
- EPIC.md 包含已填充的 `## GDD Requirements` 表（非空）
- EPIC.md 中列出的所有管辖 ADR 均已作为文件存在
- 基础（Foundation）史诗的故事须在核心（Core）史诗开始之前创建；核心在功能（Feature）之前；功能在表现（Presentation）之前

## Outputs Produced
## 产生的输出

### Files Written
### 写入的文件
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/[epic-slug]/story-NNN-[slug].md` | `Epic:`, `Status:`, `Layer:`, `Type:`, `Manifest Version:`, `## Context` (GDD path + `TR-[system]-NNN` + ADR reference + ADR Decision Summary + Engine/Risk + Engine Notes + Control Manifest Rules), `## Acceptance Criteria`, `## Implementation Notes`, `## Out of Scope`, `## Files`, `## Test Evidence`, `## Dependencies` | Created per story |
| `production/epics/[epic-slug]/EPIC.md` | `## Stories` table replacing the "Not yet created" placeholder | Updated in-place; a return visit appends rows for new stories only. At `minimal`, when none exists yet, the skill creates it from the brief, after the write ask names it |
| `production/epics/index.md` | The epic's `Stories` column set to `[N] stories` | Only when the index exists; otherwise the run prints `Epics index not updated: production/epics/index.md absent` |
| 文件 | 保证包含的字段 / 小节 | 说明 |
|------|------------------------------|-------|
| `production/epics/[epic-slug]/story-NNN-[slug].md` | `Epic:`、`Status:`、`Layer:`、`Type:`、`Manifest Version:`、`## Context`（GDD 路径 + `TR-[system]-NNN` + ADR 引用 + ADR Decision Summary + Engine/Risk + Engine Notes + Control Manifest Rules）、`## Acceptance Criteria`、`## Implementation Notes`、`## Out of Scope`、`## Files`、`## Test Evidence`、`## Dependencies` | 每个故事创建一个 |
| `production/epics/[epic-slug]/EPIC.md` | `## Stories` 表，替换 "Not yet created" 占位符 | 原地更新；再次访问时只为新故事追加行。在 `minimal` 下，若尚无该文件，技能在写入提问点名它之后，从简报创建它 |
| `production/epics/index.md` | 该史诗的 `Stories` 列设为 `[N] stories` | 仅当索引存在时；否则运行会打印 `Epics index not updated: production/epics/index.md absent` |

### Output Guarantees
- Every story file contains a `TR-[system]-NNN` reference in its `## Context` section (or `TR-[system]-???` with a warning if the registry has no match) — at `minimal`, `Brief MVP feature N` instead
- Every story file contains an `ADR Governing Implementation:` line referencing at least one ADR, or an explicit `ADR: N/A — [reason]` line
- Every story file has a `Status:` field — either `Ready` or `Blocked` (if the governing ADR is `Proposed`, `Deprecated` or `Superseded`, or an ADR it depends on is not `Accepted`)
- Every story file has a `Type:` field — one of: Logic, Integration, Visual/Feel, UI, Config/Data
- Every story file has a `Manifest Version:` field matching the date from `docs/architecture/control-manifest.md`'s header at time of writing — at `minimal`, `N/A (minimal — no control manifest)`
- Every story file has a `## Test Evidence` section stating the expected evidence location for its type
- Every story file has a `## Acceptance Criteria` section with at least one checkbox item copied from the GDD — at `minimal`, derived from `design/game-brief.md` (its Player goal & fail state and the MVP feature the story implements)
- Every story file has a `## Dependencies` section naming each story it needs by path (may say "None" but is never omitted)
- Every story file has a `## Files` section listing the code and test files it is planned to create or change; `/dev-story` replaces the list with the files it changed, and `/story-done` checks scope against it
- The EPIC.md `## Stories` table is updated with a row per story including `#`, `Story` title, `Type`, `Status`, and `ADR`
- Stories with a `Proposed` ADR have `Status: Blocked` and a note: `BLOCKED: ADR-NNNN is Proposed — accept it with /architecture-decision accept ADR-NNNN once decided`; a `Deprecated` or `Superseded` ADR blocks the same way, naming its successor
- Every story file has an `Engine` and a `Risk` field. `Risk` is taken from `docs/engine-reference/<engine>/VERSION.md`; when that file is missing or assigns no level, `Risk` is **`NOT ASSESSED (no VERSION.md risk rating)`** — never a guessed level
- **`NOT ASSESSED` is an emittable value of the `Risk` field**, and downstream readers must handle it. `/dev-story` treats it as HIGH when deciding whether to hand work to the engine specialist: an unknown risk is not a low one
### 输出保证
- 每个故事文件都在其 `## Context` 小节中包含 `TR-[system]-NNN` 引用（若注册表无匹配，则为 `TR-[system]-???` 并附警告）— 在 `minimal` 下则改为 `Brief MVP feature N`
- 每个故事文件都包含 `ADR Governing Implementation:` 行，引用至少一个 ADR，或一条明确的 `ADR: N/A — [reason]` 行
- 每个故事文件都有 `Status:` 字段 — 为 `Ready` 或 `Blocked`（若管辖 ADR 为 `Proposed`、`Deprecated` 或 `Superseded`，或其依赖的某个 ADR 不是 `Accepted`）
- 每个故事文件都有 `Type:` 字段 — 取值为：Logic、Integration、Visual/Feel、UI、Config/Data
- 每个故事文件都有 `Manifest Version:` 字段，匹配写入时 `docs/architecture/control-manifest.md` 文件头中的日期 — 在 `minimal` 下为 `N/A (minimal — no control manifest)`
- 每个故事文件都有 `## Test Evidence` 小节，说明其类型预期的证据存放位置
- 每个故事文件都有 `## Acceptance Criteria` 小节，至少包含一项从 GDD 复制的复选框条目 — 在 `minimal` 下，源自 `design/game-brief.md`（其 Player goal & fail state 以及该故事所实施的 MVP 功能）
- 每个故事文件都有 `## Dependencies` 小节，按路径点名它所需的每个故事（可写 "None"，但绝不省略）
- 每个故事文件都有 `## Files` 小节，列出计划创建或更改的代码与测试文件；`/dev-story` 会用实际更改的文件替换该列表，`/story-done` 据此检查范围
- EPIC.md 的 `## Stories` 表按每个故事更新一行，包含 `#`、`Story` 标题、`Type`、`Status` 与 `ADR`
- 带有 `Proposed` ADR 的故事具有 `Status: Blocked` 以及一条说明：`BLOCKED: ADR-NNNN is Proposed — accept it with /architecture-decision accept ADR-NNNN once decided`；`Deprecated` 或 `Superseded` 的 ADR 以同样方式阻塞，并点名其继任者
- 每个故事文件都有 `Engine` 与 `Risk` 字段。`Risk` 取自 `docs/engine-reference/<engine>/VERSION.md`；当该文件缺失或未赋予级别时，`Risk` 为 **`NOT ASSESSED (no VERSION.md risk rating)`** — 绝不猜测级别
- **`NOT ASSESSED` 是 `Risk` 字段可输出的值**，下游读取方必须处理它。`/dev-story` 在决定是否将工作交给引擎专家时将其视为 HIGH：未知风险不等于低风险

## Immutability Rules
- READS but does NOT modify: the epic's GDD, all ADR files, `docs/architecture/tr-registry.yaml`, `docs/architecture/control-manifest.md`
- MODIFIES: `production/epics/[epic-slug]/story-NNN-[slug].md` (creates), `production/epics/[epic-slug]/EPIC.md` (updates Stories section only; created at `minimal` when none exists yet), `production/epics/index.md` (the epic's row, when the index exists) — all after one write ask that names them
## 不可变性规则
- 读取但不修改：该史诗的 GDD、所有 ADR 文件、`docs/architecture/tr-registry.yaml`、`docs/architecture/control-manifest.md`
- 修改：`production/epics/[epic-slug]/story-NNN-[slug].md`（创建）、`production/epics/[epic-slug]/EPIC.md`（仅更新 Stories 小节；在 `minimal` 下且尚无文件时创建）、`production/epics/index.md`（该史诗的行，当索引存在时）— 全部在一次点名它们的写入提问之后进行

## Hard Constraints (Never Violate)
- Never start implementation — this skill stops at the story file level
- Never invent acceptance criteria — all criteria must come from the GDD (from `design/game-brief.md` at `minimal`)
- Never invent implementation notes — all guidance must come from the referenced ADR
- Never write story files without presenting the full story list for approval first
- Never mark a story `Status: Ready` if its governing ADR has `Status: Proposed`, `Deprecated` or `Superseded`
- Never omit the `Manifest Version:` field — downstream readiness checks depend on it
- Never reuse a story number (NNN) that already exists in the epic directory
## 硬性约束（绝不违反）
- 绝不开始实施 — 此技能止于故事文件层面
- 绝不凭空编造验收标准 — 所有标准必须来自 GDD（`minimal` 下来自 `design/game-brief.md`）
- 绝不凭空编造实现说明 — 所有指导必须来自所引用的 ADR
- 绝不在未先呈现完整故事列表以供批准的情况下写入故事文件
- 若故事的管辖 ADR 为 `Status: Proposed`、`Deprecated` 或 `Superseded`，绝不将其标记为 `Status: Ready`
- 绝不省略 `Manifest Version:` 字段 — 下游的就绪检查依赖它
- 绝不重复使用该史诗目录中已存在的故事编号（NNN）

## Downstream Skill Expects
**Next skill:** /story-readiness (then /dev-story)
## 下游技能预期
**下一技能：** /story-readiness（然后 /dev-story）

It will read:
- Each `story-NNN-[slug].md` file — specifically: `Status:`, `Type:`, `Manifest Version:` (header), `TR-[system]-NNN` (in `## Context`), `ADR Governing Implementation:` line, `## Acceptance Criteria` section, `## Test Evidence` section, `## Dependencies` section
- `docs/architecture/control-manifest.md` — to compare its `Manifest Version:` against the story's embedded version
- The referenced ADR file — to verify its `Status:` field is still `Accepted`
它将读取：
- 每个 `story-NNN-[slug].md` 文件 — 具体为：`Status:`、`Type:`、`Manifest Version:`（文件头）、`TR-[system]-NNN`（位于 `## Context`）、`ADR Governing Implementation:` 行、`## Acceptance Criteria` 小节、`## Test Evidence` 小节、`## Dependencies` 小节
- `docs/architecture/control-manifest.md` — 将其 `Manifest Version:` 与故事内嵌的版本进行比对
- 所引用的 ADR 文件 — 核验其 `Status:` 字段仍为 `Accepted`

It assumes:
- `Manifest Version:` in the story header is a date string that can be compared against the manifest's current `Manifest Version:` date
- `TR-[system]-NNN` IDs are resolvable in `docs/architecture/tr-registry.yaml`
- The ADR referenced by name in `ADR Governing Implementation:` exists as a file in `docs/architecture/` (pattern: `adr-NNNN-[slug].md`)
- `Status: Ready` means the story is a candidate for assignment (not Draft, not in progress)
- `## Acceptance Criteria` contains checkbox items that are directly testable
- `## Test Evidence` specifies an exact file path or evidence doc path where proof will be stored
它假定：
- 故事文件头中的 `Manifest Version:` 是一个日期字符串，可与清单当前的 `Manifest Version:` 日期比对
- `TR-[system]-NNN` ID 在 `docs/architecture/tr-registry.yaml` 中可解析
- `ADR Governing Implementation:` 中按名称引用的 ADR 作为文件存在于 `docs/architecture/`（模式：`adr-NNNN-[slug].md`）
- `Status: Ready` 意味着该故事可被分配（不是 Draft，也不在进行中）
- `## Acceptance Criteria` 包含可直接测试的复选框条目
- `## Test Evidence` 指定了将存放证据的确切文件路径或证据文档路径

## Known Fragile Points
- If the story file format (header field names, section names, checkbox syntax) changes, `/story-readiness` will silently skip checks for fields it cannot parse — stories may pass readiness that should fail
- If `control-manifest.md` is regenerated with a new `Manifest Version:` date after stories are written, all existing stories will show a stale manifest version and fail the readiness manifest check — every story in the epic will need its `Manifest Version:` updated
- If a governing ADR is renumbered or its file is renamed after stories are written, the `ADR Governing Implementation:` reference in story files will point to a missing file and `/story-readiness` will BLOCK those stories
- If `tr-registry.yaml` deprecates or supersedes a TR-ID that is already embedded in story files, `/story-readiness` will flag those stories as NEEDS WORK
- The EPIC.md Stories table update is append-style: a return visit appends rows only for new stories, so a hand-edited table that drops the story numbers can gain duplicate rows
## 已知脆弱点
- 若故事文件格式（文件头字段名、小节名、复选框语法）发生变化，`/story-readiness` 会静默跳过它无法解析的字段的检查 — 本应失败的故事可能通过就绪检查
- 若在故事写入之后，`control-manifest.md` 以新的 `Manifest Version:` 日期重新生成，所有既有故事都会显示过时的清单版本，并无法通过就绪清单检查 — 该史诗中的每个故事都需要更新其 `Manifest Version:`
- 若在故事写入之后，某个管辖 ADR 被重新编号或其文件被重命名，故事文件中的 `ADR Governing Implementation:` 引用将指向缺失的文件，`/story-readiness` 会 BLOCK 那些故事
- 若 `tr-registry.yaml` 弃用或取代了已内嵌于故事文件的某个 TR-ID，`/story-readiness` 会将这些故事标记为 NEEDS WORK
- EPIC.md 的 Stories 表更新为追加式：再次访问时只为新故事追加行，因此手工编辑时若丢掉故事编号，就可能产生重复行
