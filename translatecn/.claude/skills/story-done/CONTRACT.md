# /story-done — Handoff Contract

# /story-done — 交接契约

## Role in Pipeline
Closes the implementation loop for a single story by verifying every acceptance criterion, checking test evidence, detecting GDD/ADR deviations, and — after user approval — updating the story file to `Status: Complete` with a `## Completion Notes` section.

## 在流水线中的角色
通过验证每条验收标准、检查测试证据、检测 GDD/ADR 偏离，并在用户批准后把故事文件更新为 `Status: Complete` 并添加 `## Completion Notes` 章节，来为单个故事关闭实现循环。

## Inputs Required

## 所需输入

### Files That Must Exist
| File | Required Fields / Sections | Read-Only? |
|------|---------------------------|-----------|
| `production/epics/**/*.md` (the story file) | `Status:` (expected: `In Progress`, or `Ready` if `/dev-story` was skipped — `/dev-story` sets `In Progress`, and `/story-done` is the only skill that closes a story it verified — `/dev-story`'s dependency option `[C]` also sets `Complete`, on a dependency the user says is done, after an ask), `Type:`, `Manifest Version`, TR-ID(s), ADR reference(s), `## Acceptance Criteria`, list of files to create/modify, `## Test Evidence` path | No — status and completion notes written after approval |
| `docs/architecture/tr-registry.yaml` | Entry per TR-ID with current `requirement` text | Yes |
| GDD section referenced by each TR-ID | Acceptance criteria and key rules for cross-check | Yes |
| `docs/architecture/adr-NNNN-[slug].md` (referenced ADR) | `## Decision`, `## Consequences` | Yes |
| `docs/architecture/control-manifest.md` | `Manifest Version:` header date, forbidden patterns | Yes (existence checked; absent = skip staleness check) |
| `production/session-state/active.md` | Active story path (used when no argument given) | No — `<!-- CHECKPOINT -->` block overwritten |

### 必须存在的文件
| 文件 | 必需字段 / 章节 | 只读？ |
|------|----------------|--------|
| `production/epics/**/*.md`（故事文件） | `Status:`（预期：`In Progress`，或若跳过 `/dev-story` 则为 `Ready` — `/dev-story` 设置 `In Progress`，而 `/story-done` 是唯一会关闭自己所验证故事的技能 — `/dev-story` 的依赖选项 `[C]` 也会在询问后、用户说某依赖已完成时设置 `Complete`）、`Type:`、`Manifest Version`、TR-ID、ADR 引用、`## Acceptance Criteria`、要创建/修改的文件列表、`## Test Evidence` 路径 | 否 — 状态与完成备注在批准后写入 |
| `docs/architecture/tr-registry.yaml` | 每个 TR-ID 的条目及其当前 `requirement` 文本 | 是 |
| 每个 TR-ID 引用的 GDD 章节 | 用于交叉核对的验收标准与关键规则 | 是 |
| `docs/architecture/adr-NNNN-[slug].md`（被引用的 ADR） | `## Decision`、`## Consequences` | 是 |
| `docs/architecture/control-manifest.md` | `Manifest Version:` 头部日期、禁止模式 | 是（检查存在性；缺失 = 跳过陈旧度检查） |
| `production/session-state/active.md` | 活动故事路径（无参数时使用） | 否 — `<!-- CHECKPOINT -->` 块被覆盖 |

> **Tier.** The TR registry, GDD-section and ADR rows are `standard`/`full` inputs.
> At `workflow: minimal` the story traces to the brief, and Phase 5 runs no GDD
> or ADR check; the manifest, hardcoded-value and scope checks still run. At
> `qa.level: minimal` no test evidence is required (SKILL.md Phase 4) — but the
> Visual/UI run-and-observe screenshot is not waived.

> **层级。** TR 注册表、GDD 章节和 ADR 行是 `standard`/`full` 输入。
> 在 `workflow: minimal` 下，故事追溯到简报，阶段 5 不运行 GDD
> 或 ADR 检查；清单、硬编码值和范围检查仍会运行。在
> `qa.level: minimal` 下不需要测试证据（SKILL.md 阶段 4）— 但
> Visual/UI 的"运行并观察"截图不被豁免。

### Test Evidence Files (presence checked, not pre-required to exist — absence triggers gate)
| Story Type | Expected Location |
|------------|------------------|
| Logic | `tests/unit/[system]/[story-slug]_test.[ext]` |
| Integration | `tests/integration/[system]/[story-slug]_test.[ext]` OR `production/qa/playtests/` playtest record |
| Visual/Feel | `production/qa/evidence/[story-slug]-evidence.md` + a retained screenshot |
| UI | A retained screenshot of each screen touched, under `production/qa/evidence/` — no evidence doc or sign-off required |
| Config/Data | `production/qa/smoke-*.md` |

### 测试证据文件（检查存在性，不预先要求存在 — 缺失会触发门禁）
| 故事类型 | 预期位置 |
|----------|----------|
| Logic | `tests/unit/[system]/[story-slug]_test.[ext]` |
| Integration | `tests/integration/[system]/[story-slug]_test.[ext]` 或 `production/qa/playtests/` 中的试玩记录 |
| Visual/Feel | `production/qa/evidence/[story-slug]-evidence.md` + 一张留存截图 |
| UI | 每个涉及界面的留存截图，位于 `production/qa/evidence/` 下 — 无需证据文档或签署 |
| Config/Data | `production/qa/smoke-*.md` |

### Preconditions
- The story file must be findable either by argument path, in `production/session-state/active.md`, or in the current sprint file as `IN PROGRESS`
- Implementation must have been attempted (the files the story's `## Files` section lists should exist) — this skill does not implement; it verifies
- At `qa.level: full`, a Config/Data story's smoke report is BLOCKING by default (an explicit `testing.strict.config: false` keeps it advisory), and any UNTESTED acceptance criterion blocks; at `standard` only more than half untested blocks
- For Logic and Integration stories, the test file at the `## Test Evidence` path must **exist** before a COMPLETE verdict is possible — unless `testing.strict` in `project.yaml` sets that type to advisory (`testing.strict.logic`/`.integration: false`), in which case a missing test is recorded as a warning but does not block
- For Visual/Feel and UI stories, a retained screenshot must exist under `production/qa/evidence/` before a COMPLETE verdict is possible, and for Visual/Feel an evidence doc with every sign-off `[x] Approved` too (UI needs the screenshot only, as `coding-standards.md` says) — unless `testing.strict.visual`/`.ui` is set to `false`, in which case the gap is recorded as a warning but does not block
- **This skill does not execute the test.** Phase 4 checks that the file exists; nothing runs. A test that exists and FAILS satisfies the gate, so a failing test cannot block a COMPLETE verdict here — this gate is existence, not "exist and pass". Pass/fail is established by `/gate-check` and `/smoke-check`, both of which run a suite and both of which come after story closure. See Phase 3 of `SKILL.md`.

### 前置条件
- 故事文件必须可找到：通过参数路径、在 `production/session-state/active.md` 中，或在当前冲刺文件中作为 `IN PROGRESS`
- 实现必须已尝试过（故事 `## Files` 章节所列的文件应存在）— 本技能不实现；它验证
- 在 `qa.level: full` 下，Config/Data 故事的冒烟报告默认是阻断的（显式的 `testing.strict.config: false` 使其保持建议性），且任何 UNTESTED 验收标准都阻断；在 `standard` 下仅超过一半未测试才阻断
- 对于 Logic 和 Integration 故事，在 COMPLETE 结论可能之前，`## Test Evidence` 路径处的测试文件必须**存在** — 除非 `project.yaml` 中的 `testing.strict` 将该类型设为建议性（`testing.strict.logic`/`.integration: false`），此时缺失的测试记录为警告但不阻断
- 对于 Visual/Feel 和 UI 故事，在 COMPLETE 结论可能之前，`production/qa/evidence/` 下必须存在留存截图，且 Visual/Feel 还需要一份每项签署均为 `[x] Approved` 的证据文档（UI 只需截图，如 `coding-standards.md` 所述）— 除非 `testing.strict.visual`/`.ui` 设为 `false`，此时缺口记录为警告但不阻断
- **本技能不执行测试。** 阶段 4 检查文件是否存在；不运行任何东西。存在但 FAIL 的测试满足该门禁，因此失败的测试在此不能阻止 COMPLETE 结论 — 该门禁是存在性，而非"存在且通过"。通过/失败由 `/gate-check` 和 `/smoke-check` 确定，二者都运行测试套件，且都在故事关闭之后。见 `SKILL.md` 的阶段 3。

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH NOTES` / `NOT ASSESSED` / `BLOCKED`.

## 发出的结论
`COMPLETE` / `COMPLETE WITH NOTES` / `NOT ASSESSED` / `BLOCKED`。

`NOT ASSESSED` outranks `COMPLETE` — one or more acceptance criteria could not
be evaluated at all, which is not the same as evaluating them and finding them
met. Precedence is `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH NOTES`,
then `COMPLETE`; see the verdict section of `SKILL.md`.

`NOT ASSESSED` 优先于 `COMPLETE` — 一条或多条验收标准完全无法
评估，这与评估它们并认定其已满足并不相同。优先级为 `BLOCKED`，
然后 `NOT ASSESSED`，然后 `COMPLETE WITH NOTES`，
然后 `COMPLETE`；见 `SKILL.md` 的结论章节。

## Outputs Produced

## 产出的输出

### Files Written
| File | Guaranteed Fields / Sections | Notes |
|------|------------------------------|-------|
| `production/epics/**/*.md` (the story file) | `Status: Complete`, `## Completion Notes` block (date, criteria count, deviations, test evidence path, code review status, Reviewed by) | updated after explicit user approval |
| `production/sprint-status.yaml` | `status: done`, `completed: [date]`, top-level `updated` field | updated silently alongside story file if file exists |
| `docs/tech-debt-register.md` | Advisory deviation entries (if user confirms) | appended if advisory deviations exist and user agrees |
| `production/session-state/active.md` | `<!-- CHECKPOINT -->` block: current task (story path, verdict, closed or left open), next step (the next story, or the fix the verdict named), blocker, tech debt count | written on every verdict, closed or not, by `session-state.sh checkpoint`: the block is replaced, never appended (the file is created from `.claude/docs/templates/session-state.md` if absent) |

### 写入的文件
| 文件 | 保证的字段 / 章节 | 备注 |
|------|------------------|------|
| `production/epics/**/*.md`（故事文件） | `Status: Complete`、`## Completion Notes` 块（日期、标准数、偏离、测试证据路径、代码评审状态、Reviewed by） | 在用户明确批准后更新 |
| `production/sprint-status.yaml` | `status: done`、`completed: [date]`、顶层 `updated` 字段 | 若文件存在，则与故事文件一并静默更新 |
| `docs/tech-debt-register.md` | 建议性偏离条目（若用户确认） | 若存在建议性偏离且用户同意，则追加 |
| `production/session-state/active.md` | `<!-- CHECKPOINT -->` 块：当前任务（故事路径、结论、已关闭或留待开放）、下一步（下一个故事，或结论所指的修复）、阻断项、技术债计数 | 由 `session-state.sh checkpoint` 在每次结论时写入，无论是否关闭：该块被替换，绝不追加（若缺失，则从 `.claude/docs/templates/session-state.md` 创建文件） |

### Output Guarantees
- `Status: Complete` is written only after the user explicitly approves: on a COMPLETE or COMPLETE WITH NOTES verdict, or — on a BLOCKED or NOT ASSESSED verdict — only when the user explicitly asks to close anyway (the Phase 7 override, which always prompts as a `scope_changes` decision), with the override risk recorded in `## Completion Notes`
- `## Completion Notes` always contains: completion date, criteria pass count, deviation summary, test evidence path (or "None required"), code review status, and a Reviewed by line: `lead-programmer`, `/code-review (you said you ran it; not verified here)`, or `self, no independent review` when nobody else reviewed the work
- Session state always records the final verdict and the next recommended story path

### 输出保证
- `Status: Complete` 仅在用户明确批准后写入：在 COMPLETE 或 COMPLETE WITH NOTES 结论下，或 — 在 BLOCKED 或 NOT ASSESSED 结论下 — 仅在用户明确要求仍然关闭时（阶段 7 的覆盖，始终作为 `scope_changes` 决策提示），并在 `## Completion Notes` 中记录覆盖风险
- `## Completion Notes` 始终包含：完成日期、标准通过数、偏离摘要、测试证据路径（或 "None required"）、代码评审状态，以及 Reviewed by 行：`lead-programmer`、`/code-review (you said you ran it; not verified here)`，或在无人评审该工作时为 `self, no independent review`
- 会话状态始终记录最终结论和下一个推荐的故事路径

## Immutability Rules
- READS but does NOT modify: `docs/architecture/tr-registry.yaml`, `docs/architecture/adr-NNNN-[slug].md` (Decision + Consequences only), GDD sections, `docs/architecture/control-manifest.md`, source files under the code root — `src/`, `Assets/` or `Source/` by engine (searched only) — and test files under the engine's test root (existence checked; never run or edited)
- MODIFIES: the story `.md` file (status + completion notes), `production/sprint-status.yaml` (if exists), `production/session-state/active.md` (the `<!-- CHECKPOINT -->` block, overwritten), `docs/tech-debt-register.md` (append a row, and update its `Last updated:` and `Total items:` lines, only with user approval)
- Does NOT write to the code root or the test root under any circumstances

## 不可变性规则
- 只读但不修改：`docs/architecture/tr-registry.yaml`、`docs/architecture/adr-NNNN-[slug].md`（仅 Decision + Consequences）、GDD 章节、`docs/architecture/control-manifest.md`、代码根目录下的源文件 — 按引擎为 `src/`、`Assets/` 或 `Source/`（仅搜索）— 以及引擎测试根目录下的测试文件（检查存在性；绝不运行或编辑）
- 修改：故事 `.md` 文件（状态 + 完成备注）、`production/sprint-status.yaml`（若存在）、`production/session-state/active.md`（`<!-- CHECKPOINT -->` 块，被覆盖）、`docs/tech-debt-register.md`（追加一行，并更新其 `Last updated:` 和 `Total items:` 行，仅在用户批准时）
- 在任何情况下都不写入代码根目录或测试根目录

## Hard Constraints (Never Violate)
- Never sets `Status: Complete` without explicit user approval ("May I update the story file?")
- Never marks a Logic story Complete on a missing unit test when its resolved gate level is BLOCKING — the level is BLOCKING by default and whenever `testing.strict.logic` is `true`; it is ADVISORY only when `testing.strict.logic` is explicitly `false`
- Never marks an Integration story Complete on missing evidence (integration test file or playtest session log) when its resolved gate level is BLOCKING — BLOCKING by default and under `testing.strict.integration: true`; ADVISORY only under an explicit `false`
- Never marks a Visual/Feel or UI story Complete on a missing retained screenshot in `production/qa/evidence/` when its resolved gate level is BLOCKING — BLOCKING by default and under `testing.strict.visual`/`.ui: true`; ADVISORY only under an explicit `false`. A written description of a visual check is not a substitute for the image
- Never auto-fixes failing acceptance criteria — report failures and ask the user what to do
- Never proceeds to Phase 7 (file update) on its own when the verdict is BLOCKED or NOT ASSESSED — list blockers and offer help resolving them; Phase 7 is reached only on the user's explicit request to close anyway, and then always prompts (`scope_changes`), even in autonomous mode
- Never silently overrides a BLOCKED verdict — if the user insists on advancing despite blockers, document the override risk explicitly in `## Completion Notes`

## 硬性约束（绝不违反）
- 绝不在未经用户明确批准的情况下设置 `Status: Complete`（"May I update the story file?"）
- 当其解析后的门禁级别为 BLOCKING 时，绝不在缺少单元测试的情况下将 Logic 故事标为 Complete — 该级别默认是 BLOCKING，且每当 `testing.strict.logic` 为 `true` 时也是如此；仅当 `testing.strict.logic` 显式为 `false` 时才是 ADVISORY
- 当其解析后的门禁级别为 BLOCKING 时，绝不在缺少证据（集成测试文件或试玩会话日志）的情况下将 Integration 故事标为 Complete — 默认是 BLOCKING，在 `testing.strict.integration: true` 下亦然；仅在显式 `false` 下才是 ADVISORY
- 当其解析后的门禁级别为 BLOCKING 时，绝不在 `production/qa/evidence/` 中缺少留存截图的情况下将 Visual/Feel 或 UI 故事标为 Complete — 默认是 BLOCKING，在 `testing.strict.visual`/`.ui: true` 下亦然；仅在显式 `false` 下才是 ADVISORY。对视觉检查的书面描述不能替代图像
- 绝不自动修复失败的验收标准 — 报告失败并询问用户该怎么做
- 当结论为 BLOCKED 或 NOT ASSESSED 时，绝不自行进入阶段 7（文件更新）— 列出阻断项并提供解决帮助；仅在用户明确要求仍然关闭时才到达阶段 7，且届时始终提示（`scope_changes`），即使在自主模式下
- 绝不悄悄覆盖 BLOCKED 结论 — 若用户坚持在有阻断项的情况下推进，在 `## Completion Notes` 中明确记录覆盖风险

## Downstream Skill Expects
**Next skill:** `/gate-check` (Production → Polish gate, or end-of-sprint review)
- It will read: story files in `production/epics/` checking `Status: Complete` and presence of `## Completion Notes`
- It will read: `tests/unit/` and `tests/integration/` for test file presence and will run the test suite via Bash
- It assumes: every Complete Logic story whose `testing.strict.logic` gate resolved to BLOCKING (the default) has a corresponding test file that **exists**; under an explicit `testing.strict.logic: false` a Logic story may be Complete with the test gap documented in `## Completion Notes`
  > **Existence, not passing.** `/story-done` checks that the test file exists and runs nothing, so a Complete Logic story may carry a test that fails. `/gate-check` running the suite is the FIRST point at which pass/fail is established, so it must never treat a Complete status as evidence the tests passed — it has to run them. That is also why an unconfigured test runner is `NOT ASSESSED` there rather than a silent skip: with no run, nothing upstream has verified the story either.
- It assumes: Visual/Feel and UI stories that are Complete have a retained screenshot in `production/qa/evidence/`, and Visual/Feel ones a signed-off evidence doc as well — that gate is BLOCKING by default; only under an explicit `testing.strict.visual`/`.ui: false` may such a story be Complete with the deviation documented in `## Completion Notes`
- It will read: `production/sprint-status.yaml` for `status: done` entries if that file exists

## 下游技能的预期
**下一个技能：** `/gate-check`（生产 → 打磨门禁，或冲刺末尾评审）
- 它将读取：`production/epics/` 中的故事文件，检查 `Status: Complete` 以及是否存在 `## Completion Notes`
- 它将读取：`tests/unit/` 和 `tests/integration/` 以检查测试文件是否存在，并通过 Bash 运行测试套件
- 它假设：每个 `testing.strict.logic` 门禁解析为 BLOCKING（默认）的 Complete Logic 故事都有一个**存在**的对应测试文件；在显式 `testing.strict.logic: false` 下，Logic 故事可以在 `## Completion Notes` 中记录测试缺口的情况下为 Complete
  > **存在性，而非通过。** `/story-done` 只检查测试文件是否存在，不运行任何东西，因此一个 Complete Logic 故事可能带有一个失败的测试。`/gate-check` 运行套件是确定通过/失败的第一个时点，因此它绝不能把 Complete 状态当作测试已通过的证据 — 它必须运行它们。这也是为什么在那里未配置测试运行器会成为 `NOT ASSESSED` 而非悄悄跳过：没有运行，上游也没有任何东西验证过该故事。
- 它假设：Complete 的 Visual/Feel 和 UI 故事在 `production/qa/evidence/` 中有留存截图，Visual/Feel 故事还有一份已签署的证据文档 — 该门禁默认是 BLOCKING；仅在显式 `testing.strict.visual`/`.ui: false` 下，此类故事才能在 `## Completion Notes` 中记录偏离的情况下为 Complete
- 它将读取：`production/sprint-status.yaml` 中的 `status: done` 条目（若该文件存在）

## Known Fragile Points
- The story's `## Test Evidence` path is checked first; when it does not match, Phase 4 searches `tests/unit/[system]/` (or `tests/integration/[system]/`) before flagging the test missing, so a file under a slightly different name is still found — one outside that folder is not
- The scope check reads the story's `## Files` list (filled by `/create-stories`, replaced by `/dev-story`). A story written before the section existed falls back to the checkpoint's **Files in progress** when it names this story, else reports scope NOT ASSESSED; changes already committed are not seen, since it compares uncommitted files only
- If `Type:` is absent from the story header, test evidence gate enforcement is ADVISORY only — stories can slip through without tests
- Manifest version staleness check is skipped if `docs/architecture/control-manifest.md` does not exist; the check being skipped is noted in the report but is non-blocking
- `production/sprint-status.yaml` update is silent (no separate approval); if that file uses a different key structure than expected, the update silently fails and sprint tracking becomes stale
- The traceability table escalation rule (>50% UNTESTED = BLOCKING at `qa.level: standard`, any UNTESTED at `full`) can be triggered by deferred Visual/Feel criteria that are legitimately not automatable — ensure deferred criteria are explicitly marked `DEFERRED` (not left as unchecked) to avoid false escalation

## 已知脆弱点
- 先检查故事的 `## Test Evidence` 路径；当它不匹配时，阶段 4 会在标记测试缺失之前搜索 `tests/unit/[system]/`（或 `tests/integration/[system]/`），因此名称略有不同的文件仍会被找到 — 该文件夹之外的文件则不会
- 范围检查读取故事的 `## Files` 列表（由 `/create-stories` 填充，由 `/dev-story` 替换）。在该章节存在之前编写的故事，当其点名本故事时回退到检查点的 **Files in progress**，否则报告范围为 NOT ASSESSED；已提交的变更不会被看到，因为它只比较未提交的文件
- 若故事头部缺少 `Type:`，测试证据门禁的强制执行仅为建议性 — 故事可能在没有测试的情况下蒙混过关
- 若 `docs/architecture/control-manifest.md` 不存在，则跳过清单版本陈旧度检查；跳过该检查会在报告中注明，但不阻断
- `production/sprint-status.yaml` 的更新是静默的（无单独批准）；若该文件使用的键结构与预期不同，更新会静默失败，冲刺跟踪会变得陈旧
- 可追溯表升级规则（在 `qa.level: standard` 下 >50% UNTESTED = BLOCKING，在 `full` 下任何 UNTESTED）可能被合理地无法自动化的延迟 Visual/Feel 标准触发 — 确保延迟标准被明确标记为 `DEFERRED`（而非留为未勾选）以避免误升级
