# /dev-story — Handoff Contract
# /dev-story — 交接契约

## Role in Pipeline
## 在流水线中的角色
Bridges planning and code by loading the full context for a single story (story file, TR registry, ADR, control manifest, engine prefs), routing to the correct programmer agent, implementing source code and tests, and leaving the story ready for `/story-done` (with `/code-review` first at `standard`/`full`).
通过为单个故事加载完整上下文（故事文件、TR 注册表、ADR、控制清单、引擎偏好），路由到正确的程序员智能体，实现源代码和测试，并让故事为 `/story-done` 做好准备（在 `standard`/`full` 下先运行 `/code-review`），从而衔接规划与代码。

## Inputs Required
## 所需输入

### Files That Must Exist
### 必须存在的文件
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/**/*.md` (the story file) | `Status: Ready`, `TR-ID`, `Governing ADR`, `Manifest Version`, `## Acceptance Criteria`, `## Test Evidence`, `## Dependencies`, `## Out of Scope` | **Partially mutable.** This skill sets `Status:` to `In Progress` and updates `Last Updated:` before any agent runs (Phase 3), and at the end replaces `## Files` with the files changed — at `minimal` the story file is the only record of progress, since `sprint-status.yaml` is absent. On an ADR version mismatch answered "Re-read the changed ADR" it sets `ADR Version` to the ADR's current version and refreshes `**ADR Decision Summary**` and `## Implementation Notes`; on a manifest mismatch answered "Update" or "Use the old rules" it sets `Manifest Version:` (and on the latter adds `Manifest-Note:`). Everything else in the story file is read-only to this skill |
| `docs/architecture/tr-registry.yaml` | Entry matching the story's TR-ID with current `requirement` text | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (referenced ADR) | `## Status`, `## Last Verified` (else `## Date`) — from `adr-status.sh`; `## Decision` (with its `### Implementation Guidelines`), `## Engine Compatibility`, `## ADR Dependencies` — read only on a version mismatch answered "Re-read the changed ADR" | Yes — the ADR is never edited; a mismatch updates the story's stamp, not the ADR |
| `docs/architecture/control-manifest.md` | `Manifest Version:` header, layer rules (required patterns, forbidden patterns, performance guardrails) | Yes |
| `project.yaml` | `engine.name`, `engine.version`, `naming.*`, `performance.*` — the primary source for each of these fields | Yes |
| `.claude/docs/technical-preferences.md` | Legacy fallback for any field above that is absent or empty in `project.yaml`; **sole** source for forbidden patterns and allowed libraries (deliberately never migrated), plus the `Engine Specialists` section | Yes — required only for fields absent from `project.yaml`, and always for forbidden patterns |
| `docs/engine-reference/[engine]/VERSION.md` | Engine version, LLM knowledge cutoff, post-cutoff risk levels | Yes |
| `production/session-state/active.md` | (read to find active story when no argument given; created if absent) | No |
| 文件 | 必需字段 / 节 | 只读？ |
|------|---------------------------|-----------|
| `production/epics/**/*.md`（故事文件） | `Status: Ready`、`TR-ID`、`Governing ADR`、`Manifest Version`、`## Acceptance Criteria`、`## Test Evidence`、`## Dependencies`、`## Out of Scope` | **部分可变。** 此技能在任何智能体运行之前（阶段 3）将 `Status:` 设为 `In Progress` 并更新 `Last Updated:`，并在结尾用更改的文件替换 `## Files` — 在 `minimal` 下，故事文件是进度的唯一记录，因为 `sprint-status.yaml` 不存在。在 ADR 版本不匹配且回答 "Re-read the changed ADR" 时，它将 `ADR Version` 设为 ADR 的当前版本并刷新 `**ADR Decision Summary**` 和 `## Implementation Notes`；在清单不匹配且回答 "Update" 或 "Use the old rules" 时，它设置 `Manifest Version:`（后者还会添加 `Manifest-Note:`）。故事文件中的其他所有内容对此技能均为只读 |
| `docs/architecture/tr-registry.yaml` | 与故事 TR-ID 匹配且带当前 `requirement` 文本的条目 | 是 |
| `docs/architecture/adr-NNNN-[slug].md`（引用的 ADR） | `## Status`、`## Last Verified`（否则 `## Date`） — 来自 `adr-status.sh`；`## Decision`（含其 `### Implementation Guidelines`）、`## Engine Compatibility`、`## ADR Dependencies` — 仅在版本不匹配且回答 "Re-read the changed ADR" 时读取 | 是 — ADR 绝不编辑；不匹配更新的是故事的戳记，而非 ADR |
| `docs/architecture/control-manifest.md` | `Manifest Version:` 头、层规则（必需模式、禁用模式、性能护栏） | 是 |
| `project.yaml` | `engine.name`、`engine.version`、`naming.*`、`performance.*` — 这些字段各自的主要来源 | 是 |
| `.claude/docs/technical-preferences.md` | 当 `project.yaml` 中上述任何字段缺失或为空时的旧版回退；禁用模式和允许库的**唯一**来源（有意永不迁移），外加 `Engine Specialists` 节 | 是 — 仅当 `project.yaml` 中缺失相应字段时需要，且禁用模式始终需要 |
| `docs/engine-reference/[engine]/VERSION.md` | 引擎版本、LLM 知识截止、截止后的风险等级 | 是 |
| `production/session-state/active.md` | （未提供参数时读取以查找活跃故事；不存在则创建） | 否 |

> **Tier.** SKILL.md Phase 2 decides by `workflow`: the TR registry is required at
> `full`, optional at `standard` and not expected at `minimal`; a missing control
> manifest warns at `full`/`standard` and is not expected at `minimal`; an ADR
> blocks when the story references one that is missing, `Proposed`, `Deprecated`
> or `Superseded`.
> **层级。** SKILL.md 的阶段 2 依据 `workflow` 决定：TR 注册表在
> `full` 下必需，在 `standard` 下可选，在 `minimal` 下不作要求；缺失的控制
> 清单在 `full`/`standard` 下发出警告，在 `minimal` 下不作要求；当故事引用的 ADR
> 缺失、为 `Proposed`、`Deprecated`
> 或 `Superseded` 时，ADR 会阻塞。

### Preconditions
### 前置条件
- The target story must have `Status: Ready` (validated by `/story-readiness` at `standard`/`full`; at `minimal`, `/create-stories` writes stories `Ready` and `/story-readiness` is not on the path)
- The ADR referenced in the story must have `Status: Accepted` — if `Status: Proposed`, do not implement; surface this as a blocker and direct user to `/architecture-decision accept [ADR-id]`; `Deprecated` or `Superseded` also blocks, naming the successor. A story whose ADR field reads `N/A` references none, at every tier
- All `## Dependencies` stories listed in the story file must already have `Status: Complete` (or `Status: Done`)
- An engine must be configured — `engine.name` in `project.yaml`, or as legacy fallback an `**Engine**:` value in `.claude/docs/technical-preferences.md` that is not `[TO BE CONFIGURED]`
- At `full`, `docs/architecture/tr-registry.yaml` must contain the story's TR-ID (optional at `standard`, not expected at `minimal`)
- `docs/architecture/control-manifest.md` supplies the layer rules when present; a missing one warns and never stops the skill
- 目标故事必须具有 `Status: Ready`（在 `standard`/`full` 下由 `/story-readiness` 验证；在 `minimal` 下，`/create-stories` 将故事写为 `Ready`，而 `/story-readiness` 不在路径上）
- 故事中引用的 ADR 必须具有 `Status: Accepted` — 若为 `Status: Proposed`，不要实现；将其作为阻塞项呈现，并引导用户运行 `/architecture-decision accept [ADR-id]`；`Deprecated` 或 `Superseded` 也会阻塞，并点名继任者。ADR 字段为 `N/A` 的故事不引用任何 ADR，在所有层级均如此
- 故事文件中列出的所有 `## Dependencies` 故事必须已具有 `Status: Complete`（或 `Status: Done`）
- 必须已配置引擎 — `project.yaml` 中的 `engine.name`，或作为旧版回退的 `.claude/docs/technical-preferences.md` 中不为 `[TO BE CONFIGURED]` 的 `**Engine**:` 值
- 在 `full` 下，`docs/architecture/tr-registry.yaml` 必须包含故事的 TR-ID（在 `standard` 下可选，在 `minimal` 下不作要求）
- `docs/architecture/control-manifest.md` 在存在时提供层规则；缺失时发出警告，绝不使技能停止

## Outputs Produced
## 产生的输出

### Files Written
### 写入的文件
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `<code root>/[system]/[file].[ext]` | Doc-commented public APIs; no hardcoded gameplay values; follows ADR Implementation Guidelines and control-manifest required patterns | created or modified by the programmer agent; code root resolved per `.claude/docs/code-root-resolution.md` |
| `tests/unit/[system]/[story-slug]_test.[ext]` OR `tests/integration/[system]/[story-slug]_test.[ext]` | One test function per acceptance criterion (Logic/Integration stories only); naming per engine (`.claude/rules/test-standards.md`); no random seeds; no external I/O | created by the programmer agent; path matches `## Test Evidence` in story |
| The story file's `## Files` section | The code and test files the programmer agent created or changed, one per line | replaced through `md-section.sh replace` (the section is added at the end when the story has none); named in the one In Progress ask, skipped when that ask is declined. `/story-done` checks scope against it |
| `production/session-state/active.md` | `<!-- CHECKPOINT -->` block: current task (story path), next step, blocker, files in progress, run result | written on every outcome by `session-state.sh checkpoint`: the block is replaced, never appended (the file is created from `.claude/docs/templates/session-state.md` if absent) |
| 文件 | 保证的字段 / 节 | 备注 |
|------|------------------------------|-------|
| `<code root>/[system]/[file].[ext]` | 带文档注释的公共 API；无硬编码玩法数值；遵循 ADR Implementation Guidelines 和 control-manifest 必需模式 | 由程序员智能体创建或修改；代码根按 `.claude/docs/code-root-resolution.md` 解析 |
| `tests/unit/[system]/[story-slug]_test.[ext]` 或 `tests/integration/[system]/[story-slug]_test.[ext]` | 每个验收标准一个测试函数（仅逻辑/集成故事）；命名按引擎（`.claude/rules/test-standards.md`）；无随机种子；无外部 I/O | 由程序员智能体创建；路径与故事中的 `## Test Evidence` 一致 |
| 故事文件的 `## Files` 节 | 程序员智能体创建或更改的代码和测试文件，每行一个 | 通过 `md-section.sh replace` 替换（当故事没有该节时在末尾添加）；在 In Progress 的一次询问中提及，当该询问被拒绝时跳过。`/story-done` 依据它检查范围 |
| `production/session-state/active.md` | `<!-- CHECKPOINT -->` 块：当前任务（故事路径）、下一步、阻塞项、进行中的文件、运行结果 | 在每种结果下由 `session-state.sh checkpoint` 写入：该块被替换，绝不追加（若不存在则从 `.claude/docs/templates/session-state.md` 创建该文件） |

### Output Guarantees
### 输出保证
- All source files follow the naming conventions in `project.yaml` (`naming.*`), falling back to `.claude/docs/technical-preferences.md` for any convention absent there
- Test file path matches exactly the path declared in the story's `## Test Evidence` section
- Every acceptance criterion is mapped to a test function (Logic/Integration), an `OBSERVED` retained screenshot (the *look* half of Visual/Feel and UI), or flagged `DEFERRED` (the *feel* half only — timing, weight, responsiveness) in the implementation summary
- No files are written outside the story's `## Out of Scope` boundary without surfacing the conflict to the user first
- Session state records files changed and the next recommended invocation (`/story-done`; `/code-review` first at `standard`/`full`) — on INCOMPLETE, `/dev-story` to resume; on BLOCKED, the unblocking action
- The implementation summary states a **verification** result — what was run against the written code (Godot: `.claude/scripts/godot-parse-check.gd` over the changed scripts; Unity: `commands.smoke`; Unreal: the editor-target build) and its exit code. When the engine binary is unavailable this is **`NOT VERIFIED — <reason>`**, never an inference that the code is fine because it reads correctly
- The implementation summary states a **run result** — `OBSERVED — <what was on screen>` with a retained screenshot under `production/qa/evidence/[story-slug]/`, `NOT VERIFIED — <reason>`, or `N/A — <reason>` (only for a story with genuinely nothing observable). `NOT VERIFIED` is a blocker at the default gate level for Visual/Feel and UI stories. The run is **not waived at `qa.level: minimal`** — tests are, the look is not. Procedure: `.claude/docs/run-and-observe.md`
- At `qa.level: minimal` no test file is written, and for a Logic or Integration story the summary says so explicitly (`Test evidence: waived at qa.level: minimal`); UI and Visual/Feel stories get no waiver line, because their screenshot still applies. A waived run and a run where tests were forgotten must not produce the same artifact
- **`NOT ASSESSED` is an accepted inbound value of the story's `Risk` field** (`/create-stories` emits it when `VERSION.md` assigns no level). The engine specialist checks every code story, so no Risk value can skip that check
- **Completion is not assumed.** If the programmer agent stopped early or its output fails to parse, the story is reported **INCOMPLETE** with the specific breakage named, and `Implementation Complete` is not emitted
- 所有源文件遵循 `project.yaml` 中的命名约定（`naming.*`），任何在那里缺失的约定回退到 `.claude/docs/technical-preferences.md`
- 测试文件路径与故事 `## Test Evidence` 节中声明的路径完全一致
- 每个验收标准都映射到测试函数（逻辑/集成）、`OBSERVED` 的保留截图（Visual/Feel 和 UI 的*外观*部分），或在实现摘要中标记为 `DEFERRED`（仅*手感*部分 — 时机、重量、响应性）
- 不会在未先向用户呈现冲突的情况下，在故事的 `## Out of Scope` 边界之外写入任何文件
- 会话状态记录更改的文件以及下一个建议调用（`/story-done`；在 `standard`/`full` 下先 `/code-review`） — INCOMPLETE 时，`/dev-story` 以恢复；BLOCKED 时，解除阻塞的操作
- 实现摘要陈述一个**验证**结果 — 对已写代码运行了什么（Godot：对更改的脚本运行 `.claude/scripts/godot-parse-check.gd`；Unity：`commands.smoke`；Unreal：编辑器目标构建）及其退出码。当引擎二进制不可用时，这是 **`NOT VERIFIED — <reason>`**，绝不因为代码读起来正确就推断它没问题
- 实现摘要陈述一个**运行结果** — `OBSERVED — <what was on screen>` 并附 `production/qa/evidence/[story-slug]/` 下的保留截图，或 `NOT VERIFIED — <reason>`，或 `N/A — <reason>`（仅用于确实没有任何可观察内容的故事）。`NOT VERIFIED` 在默认门禁级别下对 Visual/Feel 和 UI 故事是阻塞项。运行**在 `qa.level: minimal` 下不放宽** — 测试放宽，外观不放宽。流程：`.claude/docs/run-and-observe.md`
- 在 `qa.level: minimal` 下不写测试文件，对于逻辑或集成故事，摘要会明确说明（`Test evidence: waived at qa.level: minimal`）；UI 和 Visual/Feel 故事没有豁免行，因为其截图仍然适用。被豁免的运行与忘记写测试的运行绝不应产生相同的产物
- **`NOT ASSESSED` 是故事 `Risk` 字段可接受的入站值**（当 `VERSION.md` 未分配等级时，`/create-stories` 会输出它）。引擎专家检查每个代码故事，因此任何 Risk 值都不能跳过该检查
- **不假定完成。** 如果程序员智能体提前停止或其输出解析失败，故事被报告为 **INCOMPLETE** 并点名具体的断裂处，且不会输出 `Implementation Complete`

## Immutability Rules
## 不可变性规则
- READS but does NOT modify: `project.yaml`, `docs/architecture/tr-registry.yaml`, `docs/architecture/adr-NNNN-[slug].md`, all GDD files in `design/gdd/`, `docs/architecture/control-manifest.md`, `.claude/docs/technical-preferences.md` (legacy fallback), `docs/engine-reference/[engine]/VERSION.md`
- MODIFIES, through the programmer agents: `<code root>/**` (new/updated source files; code root resolved per `.claude/docs/code-root-resolution.md`) and the engine's test root (the new test file; `tests/` on Godot)
- MODIFIES, itself, each after an ask that names the file (in `collaborative` mode; `.claude/docs/automation-modes.md` governs the others): the story file's `Status:`, `Last Updated:`, `## Files`, `ADR Version`, `**ADR Decision Summary**`, `## Implementation Notes`, `Manifest Version:` and `Manifest-Note:` (see the story row above); the story's entry in `production/sprint-status.yaml` (`status: in-progress`, top-level `updated`); a dependency story's `Status:` (that dependency answer only); a Config/Data story's data file; on Unity, `Assets/Scripts/ScreenshotOnArg.cs`, written verbatim from `.claude/docs/run-and-observe.md` when the project has none
- MODIFIES without an ask: `production/session-state/active.md` — its `<!-- CHECKPOINT -->` block is overwritten, never appended
- Sets the story file's own `Status` field to `In Progress` only (Phase 3, before
  any agent runs). Closing the story being implemented is the exclusive
  responsibility of `/story-done`; the one other `Status` this skill writes is a
  dependency's `Complete` under that dependency answer (Hard Constraints)
- 读取但**不**修改：`project.yaml`、`docs/architecture/tr-registry.yaml`、`docs/architecture/adr-NNNN-[slug].md`、`design/gdd/` 中的所有 GDD 文件、`docs/architecture/control-manifest.md`、`.claude/docs/technical-preferences.md`（旧版回退）、`docs/engine-reference/[engine]/VERSION.md`
- 通过程序员智能体修改：`<code root>/**`（新增/更新的源文件；代码根按 `.claude/docs/code-root-resolution.md` 解析）以及引擎的测试根（新的测试文件；Godot 上为 `tests/`）
- 自身修改，每项都在一次点名文件的询问之后进行（在 `collaborative` 模式下；其他模式由 `.claude/docs/automation-modes.md` 管辖）：故事文件的 `Status:`、`Last Updated:`、`## Files`、`ADR Version`、`**ADR Decision Summary**`、`## Implementation Notes`、`Manifest Version:` 和 `Manifest-Note:`（见上文故事行）；故事在 `production/sprint-status.yaml` 中的条目（`status: in-progress`、顶层 `updated`）；依赖故事的 `Status:`（仅限该依赖回答）；Config/Data 故事的数据文件；在 Unity 上，`Assets/Scripts/ScreenshotOnArg.cs`，当项目没有时从 `.claude/docs/run-and-observe.md` 逐字写入
- 无需询问即修改：`production/session-state/active.md` — 其 `<!-- CHECKPOINT -->` 块被覆盖，绝不追加
- 仅将故事文件自身的 `Status` 字段设为 `In Progress`（阶段 3，在任何智能体运行之前）。
  收尾正在实现的故事是 `/story-done` 的专属
  职责；此技能写入的另一个 `Status` 是该依赖回答下
  依赖的 `Complete`（硬性约束）

## Hard Constraints (Never Violate)
## 硬性约束（永不违反）
- Never marks a story `Status: Done` or `Status: Complete` on its own judgement — that belongs to `/story-done`. The one exception is a dependency the user states is already done (the Phase 2 dependency answer "It is done, the status was never updated"): its `Status` is set to `Complete` only after "May I update [dependency path] Status to Complete?" is approved
- Never begins implementation without loading the full context package (story, TR-ID from registry, ADR Decision + Implementation Guidelines — as distilled in the story, or re-read from the ADR after that mismatch answer — control-manifest layer rules, engine prefs)
- Never implements a story whose referenced ADR has `Status: Proposed`, `Deprecated` or `Superseded` — surface as a blocker
- Never writes a Logic or Integration story as complete without a test file at the path declared in `## Test Evidence`
- Never touches files listed in the story's `## Out of Scope` section without explicit user approval
- Never deviates from the ADR's Implementation Guidelines silently — deviations must be flagged in the summary
- Never modifies ADR files or GDD files under any circumstances
- Source and test files are written by the programmer agents; this skill writes none directly, except the verbatim `ScreenshotOnArg.cs` capture script on Unity, after an ask
- 绝不凭自身判断将故事标记为 `Status: Done` 或 `Status: Complete` — 那属于 `/story-done`。唯一的例外是用户声称已完成的依赖（阶段 2 的依赖回答 "It is done, the status was never updated"）：只有在 "May I update [dependency path] Status to Complete?" 获批后，其 `Status` 才设为 `Complete`
- 绝不在未加载完整上下文包的情况下开始实现（故事、来自注册表的 TR-ID、ADR Decision + Implementation Guidelines — 以故事中提炼的为准，或在该不匹配回答后从 ADR 重新读取 — control-manifest 层规则、引擎偏好）
- 绝不实现所引用 ADR 为 `Status: Proposed`、`Deprecated` 或 `Superseded` 的故事 — 将其作为阻塞项呈现
- 绝不在 `## Test Evidence` 所声明路径处缺少测试文件的情况下，将逻辑或集成故事写为完成
- 绝不在未经用户明确批准的情况下触碰故事 `## Out of Scope` 节中列出的文件
- 绝不静默偏离 ADR 的 Implementation Guidelines — 偏离必须在摘要中标记
- 在任何情况下都不修改 ADR 文件或 GDD 文件
- 源文件和测试文件由程序员智能体写入；此技能不直接写入任何此类文件，除了在 Unity 上、经询问后逐字写入的 `ScreenshotOnArg.cs` 捕获脚本

## Downstream Skill Expects
## 下游技能期望
**Next skill:** `/story-done`
**下一个技能：** `/story-done`
- It will read: the story file (to check `Status`, `## Acceptance Criteria`, `## Test Evidence` path, `Type:`, referenced ADR, TR-ID)
- It assumes: the test file declared in `## Test Evidence` already exists on disk (for Logic/Integration stories)
- It assumes: `production/session-state/active.md` records the story path and files changed (used to locate the in-progress story when no argument is given)
- It assumes: source files under the resolved code root are present and match the criterion descriptions, so Grep-based deviation checks can run
- 它将读取：故事文件（以检查 `Status`、`## Acceptance Criteria`、`## Test Evidence` 路径、`Type:`、引用的 ADR、TR-ID）
- 它假定：`## Test Evidence` 中声明的测试文件已存在于磁盘上（对于逻辑/集成故事）
- 它假定：`production/session-state/active.md` 记录了故事路径和更改的文件（用于在未提供参数时定位进行中的故事）
- 它假定：已解析代码根下的源文件存在且与标准描述相符，以便基于 Grep 的偏离检查能够运行

## Known Fragile Points
## 已知脆弱点
- If the story's embedded `Manifest Version` differs from the current `docs/architecture/control-manifest.md` header date, rules may have changed since the story was authored — the skill surfaces this, but silently proceeding would produce code that violates newer manifest rules
- The test file path in `## Test Evidence` must be exact: `/story-done` uses that literal path for Glob checks; a typo here causes a false BLOCKING result downstream
- If `docs/architecture/tr-registry.yaml` has a stale `requirement` text that diverges from the GDD, the implementation may satisfy the registry but fail the GDD — always treat the registry as authoritative per design, but flag if a visible discrepancy is noticed
- Agent failures are non-fatal by design (partial reports are surfaced), but a blocked programmer agent means no source files are written — `/story-done` will then fail its file-existence checks
- Config/Data stories produce no test file; `/story-done` must see `Type: Config/Data` in the story header to classify the story correctly — otherwise it resolves the test-evidence gate for the wrong type (e.g. Logic, which is BLOCKING by default) and may flag a missing test
- 如果故事中嵌入的 `Manifest Version` 与当前 `docs/architecture/control-manifest.md` 头部的日期不同，则自故事编写以来规则可能已改变 — 此技能会呈现这一点，但静默继续会产生违反更新清单规则的代码
- `## Test Evidence` 中的测试文件路径必须精确：`/story-done` 使用该字面路径进行 Glob 检查；此处的一个拼写错误会导致下游出现虚假的 BLOCKING 结果
- 如果 `docs/architecture/tr-registry.yaml` 中的 `requirement` 文本已过时且与 GDD 不符，实现可能满足注册表却无法满足 GDD — 按设计始终将注册表视为权威，但若发现明显差异需标记
- 智能体失败在设计上非致命（部分报告会呈现），但程序员智能体被阻塞意味着没有写入源文件 — 随后 `/story-done` 会使其文件存在性检查失败
- Config/Data 故事不产生测试文件；`/story-done` 必须看到故事头部中的 `Type: Config/Data` 才能正确分类该故事 — 否则它会按错误类型（例如逻辑，默认 BLOCKING）解析测试证据门禁，并可能标记缺失测试
