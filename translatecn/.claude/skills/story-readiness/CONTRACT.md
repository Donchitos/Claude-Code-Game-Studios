# /story-readiness — Handoff Contract

# /story-readiness — 交接契约

## Role in Pipeline

## 在流程中的角色

Validates that a story file contains everything a developer needs to begin
implementation and produces a READY / NEEDS WORK / BLOCKED / NOT ASSESSED verdict — sits between
`/create-stories` and `/dev-story`, acting as a blocking gate before any code is written.

验证故事文件是否包含开发者开始实施所需的一切，并产出 READY / NEEDS WORK / BLOCKED / NOT ASSESSED
判定 — 位于 `/create-stories` 与 `/dev-story` 之间，充当任何代码写入之前的阻塞门禁。

## Inputs Required

## 所需输入

### Files That Must Exist

### 必须存在的文件

| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/[epic-slug]/story-NNN-[slug].md` | All header fields (`Status:`, `Layer:`, `Type:`, `Manifest Version:`), `## Context` (GDD path, TR-ID, ADR reference, Engine Notes, Control Manifest Rules), `## Acceptance Criteria`, `## Test Evidence`, `## Dependencies`, `## Out of Scope` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` date in header, layer rules | Yes (if exists) |
| `docs/architecture/tr-registry.yaml` | `id`, `status` fields per TR entry | Yes (if exists) |
| `docs/architecture/adr-NNNN-[slug].md` (all ADRs referenced in stories) | `## Status`, the `**Layer**` row (read through `adr-status.sh`) | Yes |
| `production/sprint-status.yaml` | `file:` entries (for `sprint` scope, read through `story-facts.sh --sprint`) | Yes (if exists) |

| 文件 | 所需字段 / 小节 | 只读？ |
|------|---------------------------|-----------|
| `production/epics/[epic-slug]/story-NNN-[slug].md` | 所有头部字段（`Status:`、`Layer:`、`Type:`、`Manifest Version:`）、`## Context`（GDD 路径、TR-ID、ADR 引用、Engine Notes、Control Manifest Rules）、`## Acceptance Criteria`、`## Test Evidence`、`## Dependencies`、`## Out of Scope` | 是 |
| `docs/architecture/control-manifest.md` | 头部的 `Manifest Version:` 日期、分层规则 | 是（若存在） |
| `docs/architecture/tr-registry.yaml` | 每个 TR 条目的 `id`、`status` 字段 | 是（若存在） |
| `docs/architecture/adr-NNNN-[slug].md`（故事中引用的所有 ADR） | `## Status`、`**Layer**` 行（通过 `adr-status.sh` 读取） | 是 |
| `production/sprint-status.yaml` | `file:` 条目（`sprint` 范围下，通过 `story-facts.sh --sprint` 读取） | 是（若存在） |

> **Tier.** The manifest, TR registry and ADR rows are
> `standard`/`full` inputs. At `workflow: minimal` the skill is not on the path
> (`/dev-story` follows `/create-stories` directly); run anyway, it checks
> acceptance criteria and scope only and treats Architecture Completeness as N/A
> except the referenced-ADR rule: an ADR the story references that is missing,
> `Proposed`, `Deprecated` or `Superseded` BLOCKS at every tier (SKILL.md, the tier note above Design
> Completeness).

> **层级。** 清单、TR 注册表与 ADR 行为
> `standard`/`full` 输入。在 `workflow: minimal` 下本技能不在流程路径上
> （`/dev-story` 直接跟随 `/create-stories`）；仍可运行，它只检查
> 验收标准与范围，并将架构完整性视为 N/A，
> 但所引用 ADR 规则除外：故事引用的 ADR 若缺失、
> `Proposed`、`Deprecated` 或 `Superseded`，在每个层级都 BLOCKS（SKILL.md，
> 设计完整性之上的层级说明）。

### Preconditions

### 前置条件

- The story file being validated was produced by `/create-stories` (or follows the same format)
- For `sprint` scope: `production/sprint-status.yaml` exists and lists story paths in its `file:` entries
- For `all` scope: `production/epics/` directory exists and contains story files

- 被验证的故事文件由 `/create-stories` 产出（或遵循相同格式）
- `sprint` 范围：`production/sprint-status.yaml` 存在，并在其 `file:` 条目中列出故事路径
- `all` 范围：`production/epics/` 目录存在且包含故事文件

## Outputs Produced

## 产出的输出

### Files Written

### 写入的文件

None. This skill is strictly read-only and produces no file modifications under any circumstance.

无。本技能严格只读，任何情况下都不产生文件修改。

### Output Guarantees

### 输出保证

- A verdict of READY, NEEDS WORK, BLOCKED or NOT ASSESSED is produced for every story file evaluated. `NOT ASSESSED` is not a synonym for `BLOCKED`: BLOCKED names a real, listable obstacle, while NOT ASSESSED means the story could not be evaluated at all. An empty scope yields `NOT ASSESSED — no stories in scope`, never a `Ready: 0 / Needs Work: 0 / Blocked: 0` summary over an empty list
- Every non-READY verdict includes a specific gap list with fix instructions for each failing checklist item
- Every BLOCKED verdict names the specific blocker (missing dependency story path, Proposed ADR ID, or unresolved design question marker)
- For `sprint` scope: a sprint-level escalation warning is prepended if any Must Have story is not READY (NEEDS WORK, BLOCKED or NOT ASSESSED)
- The skill offers to draft missing sections in conversation but never writes or edits a file

- 对每个被评估的故事文件都产出 READY、NEEDS WORK、BLOCKED 或 NOT ASSESSED 判定。`NOT ASSESSED` 不是 `BLOCKED` 的同义词：BLOCKED 点名一个真实、可列出的障碍，而 NOT ASSESSED 表示该故事根本无法评估。空范围产出 `NOT ASSESSED — no stories in scope`，绝不在空列表上给出 `Ready: 0 / Needs Work: 0 / Blocked: 0` 摘要
- 每个非 READY 判定都包含具体缺口列表，并为每个未通过的清单条目给出修正说明
- 每个 BLOCKED 判定都点名具体阻塞项（缺失的依赖故事路径、Proposed ADR ID，或未解决的设计问题标记）
- `sprint` 范围：若有任何 Must Have 故事未 READY（NEEDS WORK、BLOCKED 或 NOT ASSESSED），在最前附加冲刺级升级警告
- 本技能提议在对话中起草缺失小节，但绝不写入或编辑文件

## Immutability Rules

## 不可变性规则

- READS but does NOT modify: story files, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, all ADR files, sprint files, any referenced asset files (existence only)
- MODIFIES: nothing

- 读取但不修改：故事文件、`docs/architecture/control-manifest.md`、`docs/architecture/tr-registry.yaml`、所有 ADR 文件、冲刺文件、任何被引用的资产文件（仅检查存在性）
- 修改：无

## Hard Constraints (Never Violate)

## 硬性约束（绝不违反）

- Never write or edit a file under any circumstances
- Never draft corrections directly into files — offer drafts in conversation only
- Never mark a story READY if its governing ADR has `Status: Proposed`, `Deprecated` or `Superseded`, at any tier
- Never mark a story READY if a dependency story file is missing or has `Status: Draft`
- Never re-read ADR statuses per story — one `adr-status.sh` call serves the run
- Never penalize a story for missing `Manifest Version:` if `control-manifest.md` does not exist
- Never penalize a story for missing TR-ID if `tr-registry.yaml` does not exist

- 任何情况下绝不写入或编辑文件
- 绝不把修正直接起草进文件 — 只在对话中提供草稿
- 若故事的管辖 ADR 为 `Status: Proposed`、`Deprecated` 或 `Superseded`，在任何层级都不将该故事标记为 READY
- 若依赖故事文件缺失或为 `Status: Draft`，绝不将该故事标记为 READY
- 绝不按故事重复读取 ADR 状态 — 一次 `adr-status.sh` 调用即服务本次运行
- 若 `control-manifest.md` 不存在，绝不因缺失 `Manifest Version:` 而惩罚故事
- 若 `tr-registry.yaml` 不存在，绝不因缺失 TR-ID 而惩罚故事

## Downstream Skill Expects

## 下游技能期望

**Next skill:** /dev-story

**下一个技能：** /dev-story

It will rely on this skill's verdict as follows:
- If verdict is READY: `/dev-story` proceeds with implementation using the story file as its source of truth
- If verdict is NEEDS WORK, BLOCKED or NOT ASSESSED: `/dev-story` must not be run until the story is corrected (or, for NOT ASSESSED, made readable) and re-validated — a story nobody could evaluate has not been shown ready
- `/dev-story` reads the same story fields this skill validates — a READY verdict is an implicit guarantee that those fields are present, parseable, and internally consistent:
  - `Type:` field is set to a valid story type
  - `## Acceptance Criteria` contains specific, testable checkbox items, at least the minimum for the story's type at the project's `story_granularity` (coarse 3/2/1, balanced 2/2/1, fine 1)
  - `## Test Evidence` specifies a concrete evidence path
  - The governing ADR exists and has `Status: Accepted`
  - `Manifest Version:` matches the current control manifest
  - `TR-ID` in `## Context` is present and resolves in `docs/architecture/tr-registry.yaml` (when the registry exists)
  - `## Dependencies` section is present (may say "None")
  - `## Out of Scope` section is present (checked for existence; `/dev-story` uses it to enforce implementation boundaries)

它将按如下方式依赖本技能的判定：
- 若判定为 READY：`/dev-story` 以该故事文件为唯一事实来源继续实施
- 若判定为 NEEDS WORK、BLOCKED 或 NOT ASSESSED：在故事被修正（对 NOT ASSESSED 而言，是变得可读）并重新验证之前，不得运行 `/dev-story` — 无人能评估的故事并未被证明就绪
- `/dev-story` 读取本技能所验证的相同故事字段 — READY 判定是这些字段存在、可解析且内部一致的隐式保证：
  - `Type:` 字段被设为有效的故事类型
  - `## Acceptance Criteria` 包含具体、可测试的复选框条目，至少达到项目 `story_granularity` 下该故事类型的最低数量（coarse 3/2/1，balanced 2/2/1，fine 1）
  - `## Test Evidence` 指明具体的证据路径
  - 管辖 ADR 存在且 `Status: Accepted`
  - `Manifest Version:` 与当前控制清单一致
  - `## Context` 中的 `TR-ID` 存在，并能在 `docs/architecture/tr-registry.yaml` 中解析（当注册表存在时）
  - `## Dependencies` 小节存在（可写“None”）
  - `## Out of Scope` 小节存在（检查其是否存在；`/dev-story` 用它来强制执行实施边界）

## Known Fragile Points

## 已知脆弱点

- If `control-manifest.md` is regenerated with a new `Manifest Version:` date, every story that embeds the old date will fail the manifest version check — a bulk update of all story `Manifest Version:` fields is required before stories can pass readiness again
- If an ADR is silently renamed or moved after stories reference it by ID, the ADR file-existence check will BLOCK those stories even though the decision content is unchanged
- The manifest version comparison is a string date match, not a semantic version comparison — if the date format changes (e.g., from `2026-01-15` to `Jan 15 2026`), all stories will fail the check regardless of actual currency
- Asset existence checks match paths — on Windows, path separator mismatches (`\` vs `/`) may cause a miss that incorrectly flags an asset as missing
- The TR-ID status check auto-passes if the registry does not exist, which means stories written before TR tracking was introduced will always pass this check even if they contain invalid or placeholder IDs like `TR-[system]-???`
- For `sprint` scope, the skill depends on sprint file formatting to extract story paths; if the sprint file format changes, story paths may not be parsed; the run then reports `NOT ASSESSED — no stories in scope` rather than a clean summary

- 若 `control-manifest.md` 以新的 `Manifest Version:` 日期重新生成，每个嵌入旧日期的故事都会在清单版本检查中失败 — 在故事能再次通过就绪检查之前，需要对所有故事的 `Manifest Version:` 字段做批量更新
- 若某个 ADR 在故事以 ID 引用它之后被悄悄重命名或移动，ADR 文件存在性检查会 BLOCK 这些故事，即使决策内容未变
- 清单版本比较是字符串日期匹配，而非语义版本比较 — 若日期格式改变（例如从 `2026-01-15` 改为 `Jan 15 2026`），所有故事都会失败，而不管实际是否是当前版本
- 资产存在性检查按路径匹配 — 在 Windows 上，路径分隔符不匹配（`\` 与 `/`）可能导致漏检，从而错误地将某资产标记为缺失
- 若注册表不存在，TR-ID 状态检查会自动通过，这意味着在引入 TR 跟踪之前写的故事将始终通过此检查，即使其中含有无效或占位 ID（如 `TR-[system]-???`）
- 对 `sprint` 范围，本技能依赖冲刺文件的格式来提取故事路径；若冲刺文件格式改变，故事路径可能无法解析；此时运行会报告 `NOT ASSESSED — no stories in scope`，而不是一份干净的摘要
