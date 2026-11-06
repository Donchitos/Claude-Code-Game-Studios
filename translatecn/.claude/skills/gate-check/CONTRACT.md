# /gate-check — Handoff Contract
# /gate-check — 交接契约

## Role in Pipeline
## 在流水线中的角色
Validates whether the project is ready to advance from one development phase to the next by auditing required artifacts and quality checks, producing a PASS / NOT ASSESSED / CONCERNS / FAIL verdict (NOT ASSESSED outranks PASS — a gate that could not check part of its scope has not established readiness; see SKILL.md's verdict section for the precedence order), and — on PASS with user confirmation, or on CONCERNS when the user explicitly accepts the listed risks — writing the new stage name to `project.stage` in `project.yaml` (and legacy `production/stage.txt` for backward compatibility).
通过审计所需制品和质量检查，验证项目是否已准备好从一个开发阶段推进到下一个阶段，产出 PASS / NOT ASSESSED / CONCERNS / FAIL 裁决（NOT ASSESSED 优先级高于 PASS — 无法检查其部分范围的门禁并未确立就绪状态；优先级顺序见 SKILL.md 的裁决节），并且 — 在 PASS 且用户确认时，或在 CONCERNS 且用户明确接受所列风险时 — 将新阶段名写入 `project.yaml` 中的 `project.stage`（并为向后兼容写入旧版 `production/stage.txt`）。

## Inputs Required
## 所需输入

### Files That Must Exist
### 必须存在的文件
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `project.yaml` (`project.stage`, fallback `production/stage.txt`) | Stage name (used when no argument provided, to auto-detect current stage) | Yes |
| `project.yaml` (`modes.workflow`, which follows `modes.rigor` — `minimal` by default; `workflow_overrides.system_overrides.*`, `workflow_overrides.art_bible_strict`) | Workflow tier — selects the per-gate artifact checklist (Section 2b); per-system overrides resolved when validating MVP GDDs | Yes |
| `docs/engine-reference/[engine]/VERSION.md` | Engine version, post-cutoff risk levels (read during engine validation checks) | Yes |
| `.claude/docs/technical-preferences.md` | Legacy fallback for `engine.*`, `naming.*` and `performance.*` when those keys are absent or empty in `project.yaml`; sole source for forbidden patterns (never migrated). Referenced in quality checks | Yes — required only for keys absent from `project.yaml` |
| `docs/consistency-failures.md` | Domain-tagged entries surfaced as increased-scrutiny context (read if exists; skip if absent) | Yes |
| 文件 | 必需字段 / 节 | 只读？ |
|------|---------------------------|-----------|
| `project.yaml`（`project.stage`，回退 `production/stage.txt`） | 阶段名（未提供参数时使用，用于自动检测当前阶段） | 是 |
| `project.yaml`（`modes.workflow`，其跟随 `modes.rigor` — 默认 `minimal`；`workflow_overrides.system_overrides.*`、`workflow_overrides.art_bible_strict`） | 工作流层级 — 选择各门禁的制品清单（第 2b 节）；验证 MVP GDD 时解析逐系统覆盖 | 是 |
| `docs/engine-reference/[engine]/VERSION.md` | 引擎版本、截断后的风险等级（在引擎验证检查期间读取） | 是 |
| `.claude/docs/technical-preferences.md` | 当 `project.yaml` 中这些键缺失或为空时，`engine.*`、`naming.*` 和 `performance.*` 的旧版回退；禁用模式的唯一来源（从未迁移）。在质量检查中被引用 | 是 — 仅当 `project.yaml` 中缺失相应键时才需要 |
| `docs/consistency-failures.md` | 带领域标签的条目，作为加强审查的上下文呈现（存在则读取；不存在则跳过） | 是 |

### Phase-specific inputs (subset read depending on target gate)
### 阶段特定输入（根据目标门禁读取子集）
| Target Gate | Key Files Checked |
|-------------|------------------|
| Concept → Systems Design | `design/gdd/game-concept.md`; pillars either inside it **or** in an optional `design/gdd/game-pillars.md` — at the `minimal` tier, `design/game-brief.md` instead (pillars check drops) |
| Systems Design → Technical Setup | `design/gdd/systems-index.md`, all MVP GDDs in `design/gdd/`, cross-GDD review report |
| Technical Setup → Pre-Production | `docs/architecture/` ADRs (≥3), `docs/engine-reference/[engine]/deprecated-apis.md`, `docs/architecture/architecture.md`, `docs/architecture/requirements-traceability.md`, `design/accessibility-requirements.md`, `design/ux/interaction-patterns.md` |
| Pre-Production → Production | `production/sprints/` (first sprint plan), `docs/architecture/control-manifest.md`, `production/epics/` (Foundation + Core layer epics), `design/ux/hud.md`, `design/ux/` key screen specs; recommended, not blocking: `prototypes/*-vertical-slice/REPORT.md` and its playtest in `production/qa/playtests/` — at the `minimal` tier, only a filled `design/game-brief.md` with its build order and stories under `production/epics/` (no sprint plan; the rest drops, the Vertical Slice items included — two checks on the current build replace them: the core loop is fun, and it runs end to end) |
| Production → Polish | code-root subsystems (resolve per `.claude/docs/code-root-resolution.md`), the engine's test root — `tests/unit/` + `tests/integration/` (Godot), `Assets/Tests/` (Unity), `Source/<Module>/Private/Tests/` (Unreal) — with all Logic stories covered, `production/qa/smoke-*.md` (PASS or PASS WITH WARNINGS), `production/qa/playtests/` (≥3 sessions) |
| Polish → Release | Full story test evidence for all Must Have stories, QA sign-off report, localization check, `production/qa/` QA plan, release checklist output, changelog, the newest full-scope `production/security/security-audit-*.md` (plus any later `quick` re-run) |
| 目标门禁 | 检查的关键文件 |
|-------------|------------------|
| Concept → Systems Design | `design/gdd/game-concept.md`；支柱要么在其内部，**要么**在可选的 `design/gdd/game-pillars.md` 中 — 在 `minimal` 层级下，改为 `design/game-brief.md`（支柱检查被移除） |
| Systems Design → Technical Setup | `design/gdd/systems-index.md`、`design/gdd/` 中所有 MVP GDD、跨 GDD 评审报告 |
| Technical Setup → Pre-Production | `docs/architecture/` ADR（≥3）、`docs/engine-reference/[engine]/deprecated-apis.md`、`docs/architecture/architecture.md`、`docs/architecture/requirements-traceability.md`、`design/accessibility-requirements.md`、`design/ux/interaction-patterns.md` |
| Pre-Production → Production | `production/sprints/`（首个冲刺计划）、`docs/architecture/control-manifest.md`、`production/epics/`（基础 + 核心层史诗）、`design/ux/hud.md`、`design/ux/` 关键界面规格；建议但非阻塞：`prototypes/*-vertical-slice/REPORT.md` 及其在 `production/qa/playtests/` 中的试玩 — 在 `minimal` 层级下，只需一份填写完整的 `design/game-brief.md` 及其构建顺序和 `production/epics/` 下的故事（无冲刺计划；其余移除，包括垂直切片条目 — 取而代之的是对当前构建的两项检查：核心循环有趣，且能端到端运行） |
| Production → Polish | 代码根子系统（按 `.claude/docs/code-root-resolution.md` 解析）、引擎的测试根 — `tests/unit/` + `tests/integration/`（Godot）、`Assets/Tests/`（Unity）、`Source/<Module>/Private/Tests/`（Unreal） — 且所有逻辑故事已覆盖、`production/qa/smoke-*.md`（PASS 或 PASS WITH WARNINGS）、`production/qa/playtests/`（≥3 次会话） |
| Polish → Release | 所有 Must Have 故事的完整故事测试证据、QA 签核报告、本地化检查、`production/qa/` QA 计划、发布检查清单输出、变更日志、最新的全范围 `production/security/security-audit-*.md`（以及之后任何 `quick` 重跑） |

### Preconditions
### 前置条件
- The target phase argument must be one of: `systems-design`, `technical-setup`, `pre-production`, `production`, `polish`, `release`; if omitted, auto-detects from `project.stage` in `project.yaml` (fallback `production/stage.txt`) and validates the next transition
- The skill does not require any prior skill to have run in the same session, but it will surface missing prerequisites (e.g., missing ADRs, missing playtest reports) as blockers in the verdict
- 目标阶段参数必须是以下之一：`systems-design`、`technical-setup`、`pre-production`、`production`、`polish`、`release`；如果省略，则从 `project.yaml` 中的 `project.stage`（回退 `production/stage.txt`）自动检测，并验证下一次过渡
- 此技能不要求同一会话中先前运行过任何技能，但会在裁决中将缺失的前置条件（例如缺少 ADR、缺少试玩报告）作为阻塞项呈现

## Outputs Produced
## 产生的输出

### Files Written
### 写入的文件
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/gate-checks/gate-[phase]-[date].md` (or path chosen by user) | Full checklist with per-item status, Blockers list, Recommendations, Verdict, Chain-of-Verification note | written only after user approves ("May I write this gate check report to production/gate-checks/?") |
| `project.yaml` (`project.stage`) + legacy `production/stage.txt` | New stage name (dual-write for backward compat) | written ONLY when the verdict is PASS and the user explicitly confirms, or the verdict is CONCERNS and the user explicitly accepts the listed risks; never written on FAIL or NOT ASSESSED |
| 文件 | 保证的字段 / 节 | 备注 |
|------|------------------------------|-------|
| `production/gate-checks/gate-[phase]-[date].md`（或用户选择的路径） | 带逐项状态的完整清单、Blockers 列表、Recommendations、Verdict、Chain-of-Verification 说明 | 仅在用户批准后写入（"May I write this gate check report to production/gate-checks/?"） |
| `project.yaml`（`project.stage`）+ 旧版 `production/stage.txt` | 新阶段名（为向后兼容而双写） | **仅**在裁决为 PASS 且用户明确确认时，或裁决为 CONCERNS 且用户明确接受所列风险时写入；在 FAIL 或 NOT ASSESSED 下绝不写入 |

### Output Guarantees
### 输出保证
- The gate report always contains: artifact checklist (with file sizes or "MISSING"), quality check results, list of blockers (empty if PASS), recommendations, and the Chain-of-Verification note — plus an `### Accepted Risks` section (each concern, accepted by the user, dated) when the user advanced on CONCERNS
- `project.stage` (and legacy `production/stage.txt`) is updated to the new stage name only on a confirmed PASS, or on CONCERNS after the user explicitly accepts the risks — never speculatively
- Any item that cannot be automatically verified is marked `MANUAL CHECK NEEDED` and the user is asked before the verdict is finalized
- 门禁报告始终包含：制品清单（带文件大小或 "MISSING"）、质量检查结果、阻塞项列表（若为 PASS 则为空）、建议，以及 Chain-of-Verification 说明 — 当用户在 CONCERNS 下推进时，还包含一个 `### Accepted Risks` 节（每项疑虑、由用户接受、带日期）
- `project.stage`（以及旧版 `production/stage.txt`）仅在确认的 PASS 下，或在用户明确接受风险后的 CONCERNS 下，更新为新阶段名 — 绝不投机性更新
- 任何无法自动验证的条目都会被标记为 `MANUAL CHECK NEEDED`，并在裁决最终确定前询问用户

## Immutability Rules
## 不可变性规则
- READS but does NOT modify: all GDDs in `design/gdd/`, all ADRs in `docs/architecture/`, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, `.claude/docs/technical-preferences.md` (legacy fallback), `docs/engine-reference/[engine]/VERSION.md`, `docs/engine-reference/[engine]/deprecated-apis.md`, all story files in `production/epics/`, all sprint files in `production/sprints/`, all playtest files in `production/qa/playtests/`, source files in the code root (Grep only), test files under the engine's test root (run via Bash)
- MODIFIES: `project.yaml` (`project.stage` only) + legacy `production/stage.txt` (both on a confirmed PASS or an accepted CONCERNS override only), `production/gate-checks/[report].md` (new file, with user approval)
- Does NOT modify story files, ADRs, GDDs, or any source/test code
- 读取但**不**修改：`design/gdd/` 中的所有 GDD、`docs/architecture/` 中的所有 ADR、`docs/architecture/control-manifest.md`、`docs/architecture/tr-registry.yaml`、`.claude/docs/technical-preferences.md`（旧版回退）、`docs/engine-reference/[engine]/VERSION.md`、`docs/engine-reference/[engine]/deprecated-apis.md`、`production/epics/` 中的所有故事文件、`production/sprints/` 中的所有冲刺文件、`production/qa/playtests/` 中的所有试玩文件、代码根中的源文件（仅 Grep）、引擎测试根下的测试文件（通过 Bash 运行）
- 修改：`project.yaml`（仅 `project.stage`）+ 旧版 `production/stage.txt`（仅限在确认的 PASS 或已接受的 CONCERNS 覆盖下）、`production/gate-checks/[report].md`（新文件，需用户批准）
- **不**修改故事文件、ADR、GDD 或任何源/测试代码

## Hard Constraints (Never Violate)
## 硬性约束（永不违反）
- Never writes stage (either `project.yaml` `project.stage` or legacy `production/stage.txt`) unless the verdict is PASS and the user has explicitly confirmed advancement, or the verdict is CONCERNS and the user has explicitly accepted every listed risk (recorded in the report's `### Accepted Risks`)
- Never writes stage on a FAIL or NOT ASSESSED verdict under any circumstances — no override turns either into a stage change
- Never auto-advances stage — even a PASS verdict requires explicit user confirmation before the file is written
- Never assumes PASS for items that cannot be automatically verified — always marks them `MANUAL CHECK NEEDED` and asks the user
- Never blocks the user from working — the verdict decides only whether the stage is written; a CONCERNS override records the accepted risks in the gate report
- Never passes a director "none" for an artifact the target gate does not require yet — that is "not expected before [phase]" (or "not required at `workflow: [tier]`"), and not a finding; "none" is reserved for an artifact the gate asks for that does not exist
- Always runs Chain-of-Verification (5 challenge questions) after drafting the verdict before finalizing it
- If any Vertical Slice Validation item is NO at the Pre-Production → Production gate, the verdict is automatically FAIL regardless of all other checks, at `full` and `standard`; at `minimal`, where the slice items drop, a "no" to either current-build check (the core loop is fun, it runs end to end) is FAIL the same way (tier reductions relax what must *exist*, never make a broken build passable)
- Workflow-tier reductions (Section 2b) only ever *relax* a requirement (Required → CONCERNS-if-absent, or drop); they never add one. The sole exception that adds is `workflow_overrides`: a system pinned via `system_overrides` to a higher tier than the project blocks the gate until that one system's GDD meets the higher section count, and `art_bible_strict: true` forces the complete art bible regardless of tier
- gate-check honors `modes.workflow` but is exempt from `modes.automation` — the collaborative prompting protocol (the Collaborative Protocol section) always applies; a phase gate is never auto-run
- 绝不写入阶段（无论是 `project.yaml` 的 `project.stage` 还是旧版 `production/stage.txt`），除非裁决为 PASS 且用户已明确确认推进，或裁决为 CONCERNS 且用户已明确接受每一项所列风险（记录在报告的 `### Accepted Risks` 中）
- 在任何情况下都绝不在 FAIL 或 NOT ASSESSED 裁决下写入阶段 — 任何覆盖都不能把其中任一变成阶段变更
- 绝不自动推进阶段 — 即使裁决为 PASS，也需要用户明确确认后才写入文件
- 绝不对无法自动验证的条目假定 PASS — 始终标记为 `MANUAL CHECK NEEDED` 并询问用户
- 绝不阻止用户工作 — 裁决只决定是否写入阶段；CONCERNS 覆盖会在门禁报告中记录已接受的风险
- 绝不向总监对目标门禁尚未要求的制品传递 "none" — 那是 "not expected before [phase]"（或 "not required at `workflow: [tier]`"），不是发现；"none" 保留给门禁要求但确实不存在的制品
- 始终在起草裁决后、最终确定前运行 Chain-of-Verification（5 个挑战性问题）
- 如果在 Pre-Production → Production 门禁处有任何垂直切片验证条目为 NO，则在 `full` 和 `standard` 下，无论其他所有检查如何，裁决自动为 FAIL；在 `minimal` 下，切片条目被移除，对任一当前构建检查（核心循环有趣、能端到端运行）回答 "no" 同样为 FAIL（层级削减放宽的是必须*存在*的内容，绝不使损坏的构建变得可通过）
- 工作流层级削减（第 2b 节）只会*放宽*要求（Required → 缺失时 CONCERNS，或移除）；绝不新增要求。唯一新增的例外是 `workflow_overrides`：通过 `system_overrides` 固定到比项目更高层级的系统会阻塞门禁，直到该系统 GDD 满足更高节数，而 `art_bible_strict: true` 会强制要求完整美术圣经，无论层级如何
- gate-check 遵循 `modes.workflow`，但豁免于 `modes.automation` — 协作提示协议（协作协议节）始终适用；阶段门禁绝不自动运行

## Downstream Skill Expects
## 下游技能期望
**Next skill (on PASS):** varies by gate
**下一个技能（在 PASS 时）：** 因门禁而异

| Gate Passed | Enabled downstream skill |
|-------------|-------------------------|
| Concept → Systems Design | `/map-systems` — or `/design-system` for the first system when `design/gdd/systems-index.md` already exists |
| Systems Design → Technical Setup | `/create-architecture` first — the master architecture and the ADR work plan (it needs an engine, so `/setup-engine` if none is configured) — then `/architecture-decision` |
| Technical Setup → Pre-Production | `/create-control-manifest` if `docs/architecture/control-manifest.md` does not exist yet, then `/vertical-slice`; `/create-epics` and `/create-stories` once the slice has validated the core loop |
| Pre-Production → Production | `/dev-story`, `/sprint-plan`, `/story-readiness` |
| Production → Polish | `/perf-profile`, `/playtest-report`, `/smoke-check` |
| Polish → Release | `/launch-checklist`, `/team-release` (the release checklist, changelog and security audit are done before this gate) |
| 已通过门禁 | 启用的下游技能 |
|-------------|-------------------------|
| Concept → Systems Design | `/map-systems` — 或者当 `design/gdd/systems-index.md` 已存在时，对第一个系统使用 `/design-system` |
| Systems Design → Technical Setup | 先 `/create-architecture` — 主架构和 ADR 工作计划（它需要引擎，因此若未配置则先 `/setup-engine`） — 然后 `/architecture-decision` |
| Technical Setup → Pre-Production | 若 `docs/architecture/control-manifest.md` 尚不存在则先 `/create-control-manifest`，然后 `/vertical-slice`；一旦切片验证了核心循环，再 `/create-epics` 和 `/create-stories` |
| Pre-Production → Production | `/dev-story`、`/sprint-plan`、`/story-readiness` |
| Production → Polish | `/perf-profile`、`/playtest-report`、`/smoke-check` |
| Polish → Release | `/launch-checklist`、`/team-release`（发布检查清单、变更日志和安全审计在此门禁之前完成） |

- Downstream skills read `project.stage` from `project.yaml` (fallback `production/stage.txt`) to confirm their phase is active before proceeding
- `/create-epics` reads `docs/architecture/control-manifest.md` — required at `full`, read if present at `standard` — and the Pre-Production → Production gate checks it
- 下游技能从 `project.yaml`（回退 `production/stage.txt`）读取 `project.stage`，以确认其阶段处于活跃状态后再继续
- `/create-epics` 读取 `docs/architecture/control-manifest.md` — 在 `full` 下必需，在 `standard` 下若存在则读取 — 且 Pre-Production → Production 门禁会检查它

## Known Fragile Points
## 已知脆弱点
- `project.stage` in `project.yaml` (with legacy `production/stage.txt` as fallback) is the authoritative stage indicator — if either is manually edited to a wrong value outside of `/gate-check`, auto-detection in future sessions will be incorrect; never edit them outside `/gate-check`'s stage write
- The Production → Polish gate runs the test suite via Bash. If the test runner command is not configured or fails to start (e.g. gdUnit4 is not installed at `addons/gdUnit4/`), the test check yields `NOT ASSESSED`, which outranks PASS — so the gate cannot advance a stage on the strength of a suite that never ran. With a concern also found, the verdict is CONCERNS, and its override is not offered while that check is NOT ASSESSED
- The Pre-Production → Production gate has a hard Vertical Slice validation block; any subjective checklist item (e.g., "core mechanic feels good") requires a user response via `AskUserQuestion` — if the user answers without playing the build, a false PASS is possible
- Gate report files in `production/gate-checks/` are not validated for completeness by any downstream skill; a partial report written due to a session interruption will look identical to a complete one
- `docs/consistency-failures.md` is optional context that adjusts scrutiny but does not change the formal checklist; if this file exists but is stale, the increased-scrutiny signals may point at resolved issues
- `project.yaml` 中的 `project.stage`（以旧版 `production/stage.txt` 作为回退）是权威的阶段指示器 — 若其中任一在 `/gate-check` 之外被手动编辑为错误值，未来会话中的自动检测将不正确；绝不要在 `/gate-check` 的阶段写入之外编辑它们
- Production → Polish 门禁通过 Bash 运行测试套件。如果测试运行器命令未配置或无法启动（例如 `addons/gdUnit4/` 处未安装 gdUnit4），测试检查会产出 `NOT ASSESSED`，其优先级高于 PASS — 因此门禁不能依赖一个从未运行过的套件来推进阶段。若同时发现疑虑，裁决为 CONCERNS，且在该检查为 NOT ASSESSED 期间不提供其覆盖
- Pre-Production → Production 门禁有一个硬性的垂直切片验证块；任何主观检查清单条目（例如 "core mechanic feels good"）都需要用户通过 `AskUserQuestion` 作出回答 — 如果用户未游玩构建就回答，可能出现虚假的 PASS
- `production/gate-checks/` 中的门禁报告文件不会被任何下游技能验证完整性；因会话中断而写成的部分报告会与完整报告看起来完全相同
- `docs/consistency-failures.md` 是可选上下文，用于调整审查强度但不改变正式清单；若此文件存在但已过时，加强审查的信号可能指向已解决的问题
