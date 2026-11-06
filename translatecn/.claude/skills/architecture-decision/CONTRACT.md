# /architecture-decision — Handoff Contract
# /architecture-decision — 交接契约

## Role in Pipeline
## 在管线中的角色

Authors a new Architecture Decision Record (ADR) by guiding a collaborative design session, cross-referencing the engine reference library and existing architectural stances, and writing a fully-structured ADR file to `docs/architecture/` as `Proposed`. Its `accept` mode is the only route to `Accepted`, and acceptance is what unblocks the stories and epics that depend on the decision.
通过引导一场协作式设计会话、交叉引用引擎参考库和现有架构立场，并写入一份结构完整的 ADR 文件到 `docs/architecture/`（状态为 `Proposed`），来撰写新的架构决策记录（ADR）。其 `accept` 模式是通往 `Accepted` 的唯一路径，而接受正是解除依赖该决策的故事和史诗阻塞的机制。

Two checks inside the run emit `NOT ASSESSED` rather than passing silently, and
a reader of the resulting ADR should expect them: **engine validation** when no
engine is configured (`engine.name` unset and no legacy fallback), and **GDD
sync** when the referenced design docs cannot be read. A skipped check that says
nothing is indistinguishable from a check that passed.
运行时内部有两项检查会输出 `NOT ASSESSED` 而非静默通过，所生成 ADR 的读者应当预期看到它们：未配置引擎时的**引擎校验**（`engine.name` 未设置且无遗留回退），以及无法读取所引用的设计文档时的 **GDD 同步**。一项什么也不说的被跳过检查，与一项已通过的检查无法区分。

## Inputs Required
## 所需输入

### Files That Must Exist
### 必须存在的文件

| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `docs/engine-reference/[engine]/VERSION.md` | Engine name + version, LLM knowledge cutoff date, post-cutoff risk levels per domain | Yes |
| `docs/engine-reference/[engine]/modules/[domain].md` | Domain-specific API reference (read if exists for the decision's domain) | Yes |
| `docs/engine-reference/[engine]/breaking-changes.md` | Post-cutoff breaking changes in the relevant domain | Yes |
| `docs/engine-reference/[engine]/deprecated-apis.md` | APIs that must not be referenced in the new ADR | Yes |
| `docs/registry/architecture.yaml` | All existing architectural stances (state ownership, interface contracts, forbidden patterns, performance budgets) — checked for conflicts before the design begins | Yes |
| `docs/architecture/` (existing ADRs) | Scanned to determine the next sequential ADR number | Yes |
| `design/gdd/[system].md` (GDDs relevant to the decision) | Specific rules, formulas, performance constraints, or integration points that motivate the decision | Yes |
| `project.yaml` | `engine.name` — derives the primary specialist (`<engine>-specialist`) to spawn for validation (Step 5.5) | Yes |
| `.claude/docs/technical-preferences.md` | `Engine Specialists` section — legacy fallback, used only when `engine.name` is absent or empty in `project.yaml` | Yes — required only when `engine.name` is absent |

| 文件 | 必需字段 / 小节 | 只读？ |
|------|---------------------------|-----------|
| `docs/engine-reference/[engine]/VERSION.md` | 引擎名称 + 版本、LLM 知识截止日期、各领域截止后风险级别 | 是 |
| `docs/engine-reference/[engine]/modules/[domain].md` | 领域特定 API 参考（若决策所在领域存在则读取） | 是 |
| `docs/engine-reference/[engine]/breaking-changes.md` | 相关领域中截止后的破坏性变更 | 是 |
| `docs/engine-reference/[engine]/deprecated-apis.md` | 新 ADR 中不得引用的 API | 是 |
| `docs/registry/architecture.yaml` | 所有现有架构立场（状态归属、接口契约、禁止模式、性能预算）——在设计开始前检查冲突 | 是 |
| `docs/architecture/`（现有 ADR） | 扫描以确定下一个顺序 ADR 编号 | 是 |
| `design/gdd/[system].md`（与决策相关的 GDD） | 促成该决策的具体规则、公式、性能约束或集成点 | 是 |
| `project.yaml` | `engine.name` — 派生用于校验（第 5.5 步）的主专家（`<engine>-specialist`） | 是 |
| `.claude/docs/technical-preferences.md` | `Engine Specialists` 小节——遗留回退，仅当 `project.yaml` 中 `engine.name` 缺失或为空时使用 | 是——仅当 `engine.name` 缺失时必需 |

### Preconditions
### 前提条件

- An engine must be configured (`docs/engine-reference/[engine]/VERSION.md` must exist) — if not, the skill prompts to run `/setup-engine` first
- The title or subject of the decision must be provided by the user before Step 0 proceeds (if no argument is given, the skill asks)
- If in **retrofit mode** (`retrofit [path]` argument), the target ADR file must already exist on disk
- Any conflict with a registered architectural stance in `docs/registry/architecture.yaml` must be resolved or explicitly accepted as an exception before the ADR is drafted (Step 3a is a BLOCKING gate)
- 必须配置引擎（`docs/engine-reference/[engine]/VERSION.md` 必须存在）——若没有，技能会提示先运行 `/setup-engine`
- 决策的标题或主题必须由用户在第 0 步继续之前提供（如果没有给出参数，技能会询问）
- 如果处于**改造模式**（`retrofit [path]` 参数），目标 ADR 文件必须已存在于磁盘上
- 与 `docs/registry/architecture.yaml` 中已注册架构立场的任何冲突，都必须在起草 ADR 之前解决或被明确接受为例外（第 3a 步是阻塞门禁）

## Outputs Produced
## 产出的输出

### Files Written
### 写入的文件

| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `docs/architecture/adr-NNNN-[slug].md` | `## Status`, `## Date`, `## Engine Compatibility` (table with engine, domain, knowledge risk, post-cutoff APIs, verification required), `## ADR Dependencies` (table with depends-on, enables, blocks, ordering note), `## Context` (problem statement, constraints, requirements), `## Decision` (+ architecture diagram + key interfaces), `## Alternatives Considered`, `## Consequences` (positive, negative), `## Risks`, `## GDD Requirements Addressed` (table), `## Performance Implications`, `## Migration Plan`, `## Validation Criteria`, `## Related` | created after user approves ("May I write this ADR to docs/architecture/adr-NNNN-[slug].md?") |
| `docs/registry/architecture.yaml` | New stance entries (state ownership, interface contracts, performance budgets, forbidden patterns) derived from the ADR; existing entries marked `status: superseded_by` if overridden | appended after separate user approval ("May I update docs/registry/architecture.yaml with these N new stances?") |

| 文件 | 保证包含的字段 / 小节 | 说明 |
|------|------------------------------|-------|
| `docs/architecture/adr-NNNN-[slug].md` | `## Status`、`## Date`、`## Engine Compatibility`（表格：引擎、领域、知识风险、截止后 API、所需验证）、`## ADR Dependencies`（表格：depends-on、enables、blocks、排序说明）、`## Context`（问题陈述、约束、需求）、`## Decision`（+ 架构图 + 关键接口）、`## Alternatives Considered`、`## Consequences`（正面、负面）、`## Risks`、`## GDD Requirements Addressed`（表格）、`## Performance Implications`、`## Migration Plan`、`## Validation Criteria`、`## Related` | 在用户批准后创建（"May I write this ADR to docs/architecture/adr-NNNN-[slug].md?"） |
| `docs/registry/architecture.yaml` | 从 ADR 派生的新立场条目（状态归属、接口契约、性能预算、禁止模式）；若被覆盖，现有条目标记为 `status: superseded_by` | 在用户另行批准后追加（"May I update docs/registry/architecture.yaml with these N new stances?"） |

### Output Guarantees
### 输出保证

- The ADR number is the next sequential integer after the highest existing `adr-NNNN-*` filename in `docs/architecture/`
- `## Status` is always present. Authoring writes `Proposed`; retrofit writes the status the user gives, except that an `Accepted` answer is written as `Proposed` and handed to acceptance mode. Only acceptance mode writes `Accepted`, after its dependency check and the user's confirmation
- `## Engine Compatibility` is always populated using verified data from the engine reference docs — never from training data alone when the domain carries MEDIUM or HIGH risk
- `## GDD Requirements Addressed` is always present (if no GDD motivated the decision, it documents which GDDs the decision will constrain or enable)
- `## ADR Dependencies` is always present (fields set to "None" if no ordering constraints exist)
- Engine specialist validation (Step 5.5) runs before the file is written if an engine specialist is configured; blocking issues found by the specialist cause the Decision section to be revised before saving
- ADR 编号是 `docs/architecture/` 中现有最高 `adr-NNNN-*` 文件名之后的下一个顺序整数
- `## Status` 总是存在。撰写写入 `Proposed`；改造写入用户给出的状态，但 `Accepted` 的回答会写成 `Proposed` 并交给接受模式。只有接受模式才写入 `Accepted`，且在其依赖检查与用户确认之后
- `## Engine Compatibility` 总是使用来自引擎参考文档的已核实数据填充——当该领域带有 MEDIUM 或 HIGH 风险时，绝不只凭训练数据填充
- `## GDD Requirements Addressed` 总是存在（如果没有 GDD 促成该决策，它记录该决策将约束或启用哪些 GDD）
- `## ADR Dependencies` 总是存在（若无排序约束，字段设为 "None"）
- 如果配置了引擎专家，引擎专家校验（第 5.5 步）会在文件写入前运行；专家发现的阻塞问题会导致决策小节在保存前被修订

## Immutability Rules
## 不可变性规则

- READS but does NOT modify: all existing ADR files in `docs/architecture/` (including in retrofit mode — existing sections are never touched), all GDD files in `design/gdd/`, `docs/engine-reference/**`, `project.yaml`, `.claude/docs/technical-preferences.md` (legacy fallback)
- MODIFIES: `docs/architecture/adr-NNNN-[slug].md` (new file created; or missing sections appended in retrofit mode), `docs/registry/architecture.yaml` (append only; existing entries get `status: superseded_by` annotation, never deleted or rewritten)
- In retrofit mode: appends only the missing sections — never modifies any section that is already present in the target ADR file
- 读取但不修改：`docs/architecture/` 中的所有现有 ADR 文件（包括改造模式——现有小节从不被触碰）、`design/gdd/` 中的所有 GDD 文件、`docs/engine-reference/**`、`project.yaml`、`.claude/docs/technical-preferences.md`（遗留回退）
- 修改：`docs/architecture/adr-NNNN-[slug].md`（创建新文件；或在改造模式下追加缺失的小节）、`docs/registry/architecture.yaml`（仅追加；现有条目获得 `status: superseded_by` 注释，绝不删除或重写）
- 在改造模式下：仅追加缺失的小节——绝不修改目标 ADR 文件中已存在的任何小节

## Hard Constraints (Never Violate)
## 硬性约束（绝不违反）

- Never sets `Status: Accepted` without explicit user confirmation — the default on creation is always `Status: Proposed`
- **Acceptance route: `/architecture-decision accept ADR-NNNN`** — the only path that sets `Accepted`. It refuses when a dependency is still Proposed, and prompts for confirmation regardless of `modes.automation`. Retrofit mode's `Accepted` answer, for a decision already in force, is written as `Proposed` and handed to this route. Without this route acceptance would be enforced by ten skills, owned per the authority below, and reachable by nobody.
- **Acceptance authority: the user, or `technical-director` on the user's explicit confirmation — no other agent, and not this skill on its own.** Recorded here because every consumer enforces the consequences of acceptance, and without this line nothing would say who can produce it. This narrows *who* may set the field; it does not relax the confirmation rule above.
- Never assigns an ADR number that is already in use — always scan `docs/architecture/` first and use the next sequential number
- Never proceeds past the architectural stance conflict check (Step 3a) if a conflict exists — surface the conflict and require resolution or explicit exception acknowledgment before drafting
- Never references APIs listed in `docs/engine-reference/[engine]/deprecated-apis.md` in the Decision or Key Interfaces sections
- Never writes the ADR file without asking: "May I write this ADR to docs/architecture/adr-NNNN-[slug].md?"
- Never writes to `docs/registry/architecture.yaml` without a separate ask: "May I update docs/registry/architecture.yaml with these N new stances?"
- In retrofit mode: never modifies any existing section — only appends absent sections
- 绝不在没有用户明确确认的情况下设置 `Status: Accepted`——创建时的默认值始终是 `Status: Proposed`
- **接受路径：`/architecture-decision accept ADR-NNNN`**——唯一能设置 `Accepted` 的路径。当某个依赖仍为 Proposed 时它会拒绝，并且无论 `modes.automation` 如何都会提示确认。改造模式对一项已生效决策给出的 `Accepted` 回答，会写成 `Proposed` 并交给这条路径。没有这条路径，接受将被十个技能强制执行、按下文所述权威归其所有，却无人能够到达。
- **接受权威：用户，或在用户明确确认下的 `technical-director`——没有其他智能体，也不是本技能自身。** 记录于此，是因为每个消费者都强制执行的接受后果，而没有这一行就没有任何地方说明谁能产生它。这收窄了*谁*可以设置该字段；它并未放宽上文的确认规则。
- 绝不分配已被使用的 ADR 编号——总是先扫描 `docs/architecture/` 并使用下一个顺序编号
- 如果存在冲突，绝不越过架构立场冲突检查（第 3a 步）——呈现冲突，并在起草前要求解决或明确确认例外
- 绝不在决策或关键接口小节中引用 `docs/engine-reference/[engine]/deprecated-apis.md` 所列的 API
- 绝不在未询问的情况下写入 ADR 文件："May I write this ADR to docs/architecture/adr-NNNN-[slug].md?"
- 绝不在未另行询问的情况下写入 `docs/registry/architecture.yaml`："May I update docs/registry/architecture.yaml with these N new stances?"
- 在改造模式下：绝不修改任何现有小节——仅追加缺失的小节

## Downstream Skill Expects
## 下游技能的期望

**Next skills:** `/create-epics`, `/create-stories`, `/dev-story`, `/architecture-review`
**后续技能：** `/create-epics`、`/create-stories`、`/dev-story`、`/architecture-review`

### `/create-epics` reads ADRs expecting:
### `/create-epics` 读取 ADR 时期望：

- `## Status` field — value must be `Accepted` for epics to reference it
- `## GDD Requirements Addressed` table — used to link epics to GDD traceability
- `## Engine Compatibility` section — checked during the Technical Setup → Pre-Production gate
- `## Status` 字段——值必须为 `Accepted`，史诗才能引用它
- `## GDD Requirements Addressed` 表格——用于将史诗与 GDD 可追溯性关联
- `## Engine Compatibility` 小节——在技术设置 → 前期制作门禁期间检查

### `/create-stories` reads ADRs expecting:
### `/create-stories` 读取 ADR 时期望：

- `### Implementation Guidelines` (under `## Decision`) — the concrete "must / must never" patterns programmer agents follow; the ADR template carries this subsection
- `## ADR Dependencies` table — stories referencing a `Depends On` ADR that is still `Proposed` are automatically set `Status: Blocked`
- `### Implementation Guidelines`（位于 `## Decision` 下）——程序员智能体遵循的具体"必须 / 绝不"模式；ADR 模板包含该子小节
- `## ADR Dependencies` 表格——引用仍为 `Proposed` 的 `Depends On` ADR 的故事会被自动设为 `Status: Blocked`

### `/dev-story` reads ADRs expecting:
### `/dev-story` 读取 ADR 时期望：

- `## Decision` (full text, verbatim — not summarized)
- `### Implementation Guidelines` (under `## Decision`, verbatim)
- `## Engine Compatibility` (post-cutoff API risks, verification required)
- `## ADR Dependencies` (to detect if this ADR's dependencies are unresolved)
- `## Decision`（全文，逐字——不是摘要）
- `### Implementation Guidelines`（位于 `## Decision` 下，逐字）
- `## Engine Compatibility`（截止后 API 风险、所需验证）
- `## ADR Dependencies`（用于检测此 ADR 的依赖是否未解决）

### `/architecture-review` reads ADRs expecting:
### `/architecture-review` 读取 ADR 时期望：

- All required sections present (it flags gaps)
- `## Status` is set (required for coverage matrix)
- `## Engine Compatibility` is stamped with the correct engine version
- 所有必需小节都存在（它会标记缺失）
- `## Status` 已设置（覆盖矩阵所需）
- `## Engine Compatibility` 已盖上正确的引擎版本

## Known Fragile Points
## 已知脆弱点

- If the ADR number scan misses a file (e.g., a file in a subdirectory of `docs/architecture/` or with a non-standard naming pattern), a duplicate number can be assigned — all ADR files must follow the `adr-NNNN-[slug].md` naming convention at the top level of `docs/architecture/`
- Acceptance mode moves a story from `Blocked` to `Ready` only when the story file, under `production/epics/`, contains a Blocked Status line in any of the forms `/create-stories` writes (`> **Status**: Blocked`, `**Status:** Blocked`, `Status: Blocked`) and this ADR's id. A story blocked pending this ADR that never names its id is not found, and stays `Blocked` until it is updated by hand
- The `## GDD Requirements Addressed` table is populated based on what the user tells the skill during the collaborative session; if the user does not know which GDDs motivated the decision, this table may be incomplete — `/create-epics` and `/gate-check` both rely on this linkage for traceability
- Engine specialist validation (Step 5.5) is skipped only when **both** sources are unset — `engine.name` absent or empty in `project.yaml` **and** `.claude/docs/technical-preferences.md` still reading `[TO BE CONFIGURED]`. A project configured solely via `project.yaml` **does** get specialist validation. When both are unset, post-cutoff engine API risks are not caught before the ADR is written
- `docs/registry/architecture.yaml` is append-only by design; if a stance entry becomes permanently invalid (not superseded by another ADR), it must be manually removed — there is no cleanup mechanism
- In retrofit mode, if the existing ADR has sections present but empty (e.g., a `## Status` heading with no value), the skill treats the section as present and does not fill it — an empty Status is effectively invisible to downstream skills like `/story-readiness`
- 如果 ADR 编号扫描漏掉某个文件（例如位于 `docs/architecture/` 子目录中的文件，或使用非标准命名模式的文件），就可能分配重复编号——所有 ADR 文件都必须遵循 `docs/architecture/` 顶层的 `adr-NNNN-[slug].md` 命名约定
- 接受模式只有在 `production/epics/` 下的故事文件包含 `/create-stories` 所写的任一形式的 Blocked Status 行（`> **Status**: Blocked`、`**Status:** Blocked`、`Status: Blocked`）并且包含此 ADR 的编号时，才会把故事从 `Blocked` 移至 `Ready`。一个搁置于此 ADR、却从未写出其编号的故事不会被找到，并会保持 `Blocked` 直到被手工更新
- `## GDD Requirements Addressed` 表格根据用户在协作会话中告诉技能的内容填充；如果用户不知道哪些 GDD 促成了该决策，此表可能不完整——`/create-epics` 和 `/gate-check` 都依赖此关联来实现可追溯性
- 引擎专家校验（第 5.5 步）仅在**两个**来源都未设置时才跳过——`project.yaml` 中 `engine.name` 缺失或为空**并且** `.claude/docs/technical-preferences.md` 仍为 `[TO BE CONFIGURED]`。仅通过 `project.yaml` 配置的项目**确实**会获得专家校验。当两者都未设置时，截止后的引擎 API 风险在 ADR 写入前不会被捕获
- `docs/registry/architecture.yaml` 按设计仅可追加；如果某个立场条目永久失效（未被另一 ADR 取代），必须手动移除——没有清理机制
- 在改造模式下，如果现有 ADR 的小节存在但为空（例如一个没有值的 `## Status` 标题），技能会将小节视为存在而不填充它——空的 Status 实际上对 `/story-readiness` 等下游技能不可见
