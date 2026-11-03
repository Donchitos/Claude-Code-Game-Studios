# dev-story — 实现故事（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/dev-story/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/dev-story [story-path]`
- **一句话职责**：实现一张故事卡：先检查能否开工，标记 In Progress，把代码工作连同完整任务简报交给正确的程序员智能体，再校验产出（解析、运行、观察），最后交接。
- **触发前置**：存在可实现的故事文件（`production/epics/` 下）；`/story-readiness` 的预检查不是本技能职责（本技能自带 Phase 2 开工检查），故事收尾走 `/story-done`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`automation, workflow, qa.level, gate_level, engine_values, specialists, perf_budgets, system_overrides`（resolve_config；无块 → `.claude/docs/config-resolution.md` 默认） | `workflow` 定档（Phase 2 列与收尾 Next step 都用它，绝不用 `rigor` 或 `qa.level`）；`qa.level` 定测试要求；`gate_level` 定缺测的 BLOCKING/ADVISORY；`specialists` 定引擎专家；`perf_budgets` 进简报 |
| 读取 | 故事文件整读；`story-facts.sh <path>`（类型/层级/TR-ID/ADR/依赖）；`story-facts.sh --all`（无参数时的 TODO 选项）；`production/session-state/active.md` 检查点（无参数时取当前任务）；`adr-status.sh <ADR id>`（状态与 version，**禁止打开 ADR 原文**）；`docs/architecture/tr-registry.yaml`（full 档要求存在）；`docs/architecture/control-manifest.md`（存在时比对 Manifest Version）；`project.yaml` 的 `naming.*`；`.claude/docs/code-root-resolution.md` 定代码根/测试根 | 开工判定与简报原料 |
| 产出 | 故事卡 `Status`、`Last Updated`、`## Files`（各自经点名询问后写）；`production/sprint-status.yaml` 条目（`status: in-progress` + 顶层 `updated`）；会话检查点与证据 stamp（**无需询问**直接写）；截图到 `production/qa/evidence/[story-slug]/` | 程序员智能体在代码根/测试根下写代码与测试 |
| 派生智能体 | 程序员智能体（路由见 R9）+ 引擎专家智能体（每个代码故事；路由见 R10）；Config/Data 故事不派任何智能体 | 主会话负责派发、校验、汇报 |

## 3. 核心规则
R1. 定位故事：入参即故事路径；无参数时取 `production/session-state/active.md` 检查点点名的故事并确认（"Continuing work on [title] — is that correct?"）；检查点为空则问"实现哪张卡？"，选项为 `story-facts.sh --all` 的 `TODO` 行；`production/epics/` 下没有任何故事文件则停止并提示先跑 `/create-stories`（`standard`/`full` 无史诗时先 `/create-epics`）。（Phase 1）
R2. 档位判定：取故事所属系统的 `workflow` 值——以其 `GDD:` 路径的文件名主干为键（`design/gdd/<stem>.md` → `<stem>`；无 GDD 路径时才用 TR-ID 的 `[system]`），查 `system_overrides` 行，无则项目值；必须在第一条回复写明 `Tier: workflow [value]`；该值（绝不用 `rigor` 或 `qa.level`）决定 Phase 2 列与收尾 Next step。（Phase 1）
R3. 开工检查按档位（Phase 2 表）：
- TR registry `docs/architecture/tr-registry.yaml`：`full` 缺失即**停止**（提示跑 `/architecture-review` 引导生成）；`standard` 可选；`minimal` 不期待。
- 故事点名的 ADR：`full` 档只要存在缺失/`Proposed`/`Deprecated`/`Superseded` 即**停止**；`standard`/`minimal` 仅当故事点名了 ADR 才同样处理。ADR 字段为 `N/A — [原因]` 视为未点名。
- Control manifest：`full`/`standard` 缺失仅警告后继续；`minimal` 不期待。
R4. ADR 停止文案（照抄）：`Proposed` → "ADR-NNNN is still Proposed. Accept it with `/architecture-decision accept ADR-NNNN` before implementing."；`Deprecated`/`Superseded` → "ADR-NNNN is [status]; point the story at [successor] (edit its ADR field; `/create-stories` never rewrites an existing story) before implementing."；`NOT_FOUND` → "ADR file not found. Run `/architecture-decision`, or correct the story's ADR field."（Phase 2）
R5. **禁止打开 ADR 原文**：程序员读的是故事卡里的 ADR Decision Summary 与 Implementation Notes。用 `adr-status.sh` 的 `version` 与故事卡 `ADR Version` 比对：相等、或卡无 ADR Version（早于戳的写法）、或双方 `unversioned` → 信任卡（后两种须在摘要注明 "summary trusted unverified"）；不一致、或 ADR `unversioned` 而卡写了日期 → 读 `references/version-mismatch.md`（匹配时禁止加载）。缺失戳永远不等同于过期戳；漂移由 `/story-readiness` 与 `/code-review` 事后拦截。（Phase 2）
R6. Manifest 比对：存在时比较其 `Manifest Version` 行与故事卡的；不一致 → 读 `references/version-mismatch.md`。（Phase 2）
R7. 依赖检查：对 Depends on 行的每个路径跑 `story-facts.sh`；状态非 `COMPLETE` 时必须问"[本卡] depends on [依赖], which is [状态], not Complete. How do you want to go on?"，选项：Proceed anyway — I accept the risk / Stop — I'll finish the dependency first / It is done, the status was never updated — mark it Complete。选 Stop → 故事 BLOCKED、不派智能体；选 mark → 先另问一次 "May I set [path] Status to Complete?" 才改；选 Proceed → 记入 Deviations；`NOT_FOUND` → 警告 "Dependency story not found: [path]"。（Phase 2）
R8. 任何停止：不派任何智能体，直接进 Phase 7 写 BLOCKED 检查点。（Phase 2）
R9. **程序员路由表**（Phase 4）：Config/Data 故事**不派智能体**——逐项展示 from → to 值变更，问 "May I write [data file]?" 后直接编辑，跳到 Phase 6。其余按表路由：

| 故事 | 程序员智能体 |
|---|---|
| Foundation 层，任意类型 | `engine-programmer` |
| 类型 UI | `ui-programmer` |
| 类型 Visual/Feel | `gameplay-programmer` |
| Core 或 Feature，gameplay | `gameplay-programmer` |
| Core 或 Feature，AI 或寻路 | `ai-programmer` |
| Core 或 Feature，networking | `network-programmer` |

R10. **引擎专家路由**（每个代码故事都派）：取 `specialists` 行的 `code`（`specialists.code`，语言专家：它能区分 Godot C# 与 GDScript 项目，`engine.name` 做不到）；故事涉及 shader/材质时加 `shader`；UI 故事加 `ui`；`code` 为 `unset` 时用 `primary`（通用引擎专家）。禁止凭记忆报名字——该行是项目的选择。全部 `unset` 且无 `primary`：说 "No engine specialist configured" 并继续（不带专家）。（Phase 4）
R11. 标记 In Progress 前必须只问一次："May I mark this story In Progress?"（说明将改故事卡 `Status`、`Last Updated`、`sprint-status.yaml` 条目，最后在 `## Files` 列改动文件；sprint 文件不存在时不提它）；问题必须是回复的最后一段。同意后：`md-section.sh set-field <story> Status "In Progress"`，再 `set-field "Last Updated" <YYYY-MM-DD> --after Status`（`minimal` 档故事文件是唯一进度记录）；sprint 文件写 `status: in-progress` 与顶层 `updated` 今日，文件缺失则明说 `Sprint status not updated: production/sprint-status.yaml absent`。拒绝：两处都不改，摘要打印 `Story not marked In Progress — declined`，继续。（Phase 3）
R12. **简报只指文件，禁止整篇粘贴**。必含：Objective（按 AC 实现 [story path]，不越 Out of Scope）；Sources 六项——(1) 故事文件（标准/边界/QA 用例）；(2) 每个 TR-ID 到 `tr-registry.yaml` 查 `id: <TR-ID>\s*$` 行，其 `requirement` 文本才是真源而非卡内引文；(3) ADR 指引**内联**（卡内 ADR Decision Summary 与 Implementation Notes，绝不给 ADR 路径）；(4) control manifest 的 [Layer] Layer Rules（按章节）；(5) `project.yaml` 的 `naming.*` 与 `perf_budgets` 行；(6) 故事 Test Evidence 节的测试文件路径。（Phase 5）
R13. 测试指令按 `qa.level`（仅 Logic 与 Integration 故事）：`minimal` → 必须明说"不要为这张卡写测试文件——`qa.level: minimal` 豁免"（省略该行与遗忘该行对智能体无差别）；`standard` → "在 [路径] 随代码写测试，每条 AC 至少一个测试函数"，命名按 `.claude/rules/test-standards.md` 的引擎规则，禁止随机种子、时间依赖断言、外部 I/O；`full` → 同上再加"每条标准必须覆盖：`/story-done` 会拦截任何未测标准"。（Phase 5）
R14. 简报的 Boundaries：代码只写进解析出的代码根、测试只写进测试根；代码根未解析 → 什么都不写并报告；不碰故事范围外的文件（报告需求而非动手）；公共 API 写文档注释；ADR 未覆盖的架构选择 → 报告方案、不做决定；不为一次性使用造 helper/抽象、不为不可能发生的场景写错误处理（只在输入与数据文件边界校验）、写通用逻辑绝不为了让某个测试通过而特判值。（Phase 5）
R15. 简报省略了什么必须告诉双方：Phase 2 发现缺失的输入（TR registry、ADR、manifest）不进简报——告诉智能体"没有传 [输入]——该档不存在，不要去找"；派发前用一行告诉用户：`Briefing omits: [inputs] — implementing against the acceptance criteria and the [GDD | brief].`（Phase 5）
R16. 程序员汇报后把引擎检查交给专家：对照 `docs/engine-reference/<engine>/` 检查改动文件中在 [engine + version] 下用错或已变的引擎 API；返回 文件/行/问题/修复 清单；**禁止编辑任何东西**。破坏某条 AC 的问题退回程序员一次；其余进摘要。（Phase 5）
R17. 智能体未完成（提前停、撞上限、报告中断）→ 故事 **INCOMPLETE**：作为标题说清、列已有产物、点名断点、提议恢复该智能体；绝不在其上打印 "Implementation Complete"；状态保持原样。（Phase 6）
R18. 核实产出而非采信报告：报告点名的文件不在磁盘上即失败步骤（报告再流畅也算）→ 恢复智能体并点名缺失文件；报告 BLOCKED/出错/"cannot complete" → 立刻说明、不再越过阻断点、给部分报告（`.claude/docs/error-recovery-protocol.md`）；范围太大 → 用 `/create-stories` 拆分；ADR 与故事卡冲突 → 报告冲突，禁止猜测。（Phase 6）
R19. 测试在场检查：`qa.level: standard`/`full` 的 Logic/Integration 故事，查 Test Evidence 路径的文件；缺失时按 `gate_level` 行上该类型的档位处理：BLOCKING → 标记 "story unverifiable — test required before `/story-done`"；ADVISORY → 记为建议。`minimal` 无可查（测试豁免）。（Phase 6）
R20. 解析检查必须真跑并报告命令、退出码与错误行：Godot → 先 `godot --headless --path . --import` 一次，再 `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<每个改动的 .gd>`（exit 1 = 脚本未加载，其 `PARSE FAIL:` 行点名）；禁止用 `--check-only`，仅 `--import` 不算解析检查。可执行文件取 `commands.test` 所指且文件名含 godot 者（`bash run-tests.sh` 之类包装器不算编辑器），否则 `engine.path`，否则 `godot`；禁止在磁盘上搜索；三者都跑不起来 → 检查未验证。Unity/Unreal → 读 `references/engine-checks.md`。无引擎可执行 → `parse NOT VERIFIED — engine binary not available`；禁止靠读代码推断能解析。（Phase 6）
R21. **运行并观察**（`.claude/docs/run-and-observe.md`）：玩家可见的每个故事（所有 Visual/Feel 与 UI 故事、及其它有界面的故事）：直接启动进故事触及的场景，截图存 `production/qa/evidence/[story-slug]/`（slug=故事文件名去 `.md`，先 `mkdir -p`），用 `review-receipts.sh hash <每个改动文件> > .../stamp.txt` 盖戳，打开图像与标准比对；`qa.level: minimal` 也不豁免。只回一行以 `Run result:` 开头的纯文本（禁止加粗，`/story-done` 原样读取）：`OBSERVED — <屏幕内容>` 带留存路径 / `NOT VERIFIED — <原因>`（默认门禁下会在 `/story-done` 阻断 Visual/Feel 或 UI 故事）/ `N/A — <原因>`（原因必须说明为何无可观察，`/story-done` 不接受"这是 Logic 故事"）。Visual/Feel 标准中只有"手感"半边（时序、重量）DEFERRED 给 `/team-qa`——静态图呈现不了。（Phase 6）
R22. 引擎运行授权：本技能预批准 PATH 上的 `godot`；经 `engine.path` 或 `commands.test` 点名的可执行文件运行前要先问——用户批准一次，或把 `Bash(<该可执行> *)` 加进 `.claude/settings.local.json`。（Phase 6）
R23. 摘要按标准块输出（Files changed / Test evidence / Verification / Acceptance criteria 勾选与依据 / Deviations / Engine risks / Blockers）；`standard`/`full` 加一句"运行你的测试套件并确认新测试通过后再 `/story-done`：它只查测试文件存在，不运行"；`minimal` 省略。Visual/Feel 或 UI 故事无留存图像时加"截图留存于 `production/qa/evidence/[story-slug]/` 是 `/story-done` 前置"（Visual/Feel 还要 `production/qa/evidence/[story-slug]-evidence.md` 的 sign-off）。（Phase 7）
R23 对应的摘要块模板（保留原文格式约定）：

```
## Implementation Complete: [title]

**Files changed**:
- `[code root path]` — created / modified ([what])
- `[test path]` — [N] test functions
**Test evidence**: waived at `qa.level: minimal` — no test was required or written   (Logic/Integration at minimal, instead of the test line)
**Verification**: [command] — [exit code and result | parse NOT VERIFIED — <reason>]

**Acceptance criteria**:
- [x] [criterion] — [file:function | test name | OBSERVED in <image path>]
- [ ] [criterion] — DEFERRED: feel, needs a playtest
**Deviations**: [None | files outside scope, an accepted dependency or version risk]
**Engine risks**: [None | the specialist's findings]
**Blockers**: [None | each]
```

R24. `## Files`：用 `md-section.sh replace <story> "Files"`（清单走 stdin）把节正文替换为改动的代码与测试文件清单（一行一个）；故事无该节时用文件编辑（禁止 shell 命令，shell 写会绕过项目写检查）在文末补 `## Files` + 清单；Phase 3 询问被拒时跳过本步。（Phase 7）
R25. 每种结局都写检查点：把块管道给 `session-state.sh checkpoint`（替换旧检查点），含 Updated/Branch/Current task/Next step/Blocked on/Files in progress/**Run result**（`/story-done` 从这里读）/Open questions。（Phase 7）
R26. 运行最后一条回复以收尾块结束，且 `Run result:` 行只在此处打印（回复其它地方禁止出现）：`Story: [path] — [Implemented | INCOMPLETE — <断点> | BLOCKED — <原因>]` + `Run result: [...]` + `Next step: [...]`。Next step 按 Phase 1 的 `workflow` 档：`minimal` → `/story-done [path]`；`standard`/`full` → `/code-review [files]` 再 `/story-done [path]`；INCOMPLETE → `/dev-story [path]` 恢复；BLOCKED → 解锁动作（`/architecture-decision accept ADR-NNNN`、先完成的依赖、待审的 diff）。（Phase 7）
R27. 提问规则：有提问工具就用工具；没有则编号列选项并结束回合等待；被跳过/关闭的提问不算答案，纯文本再问。（全局）

R25/R26 对应的检查点块与收尾块模板（保留原文格式约定）：

```
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /dev-story — [story path] ([title])
**Next step:** [the Next step below]
**Blocked on:** [nothing, or the blocker]
**Files in progress:** [changed files, comma-separated]
**Run result:** [OBSERVED — … | NOT VERIFIED — … | N/A — …, as in the closing block: /story-done reads it here]
**Open questions:** [none, or one line each]
```

```
Story: [path] — [Implemented | INCOMPLETE — <breakage> | BLOCKED — <reason>]
Run result: [OBSERVED — … | NOT VERIFIED — … | N/A — …]
Next step: [Implemented, Tier: workflow minimal → /story-done [path] | Implemented, Tier: workflow standard or full → /code-review [changed files], then /story-done [path] | INCOMPLETE → /dev-story [path] to resume | BLOCKED → the unblocking action]
```

## 4. 门禁与裁决
- 本技能无独立审查门禁（review_gate 不参与），但内含两级裁决：
- **开工裁决**（Phase 2）：TR registry/ADR/manifest 缺失或 ADR 非 Accepted 时按 R3-R4 分档停止；任何停止 → BLOCKED、不派智能体。
- **产物裁决**（Phase 6）：INCOMPLETE / 报告失实 / 测试缺失（按 `gate_level` 的 BLOCKING/ADVISORY）/ parse NOT VERIFIED / Run result NOT VERIFIED（默认门禁下阻断 Visual/Feel 与 UI 故事）。
- 取最严：无法验证的证据一律显式标注 NOT VERIFIED，禁止以读代码代替运行。

## 5. 移植建议
- **可直接移植**：R1-R2（目标定位与档位声明）、R3-R8（开工前检查与停止文案、依赖三选项）、R11（一次询问改状态、问题置于回复末尾）、R12-R15（简报指文件不贴全文、测试指令分档明说、边界纪律、省略项双向告知）、R17-R19（不采信流畅报告、按证据裁决）、R20-R22（可执行文件解析链、一行 Run result 协议）、R24-R27（Files 替换、检查点、收尾块、提问协议）。
- **需替换概念**：程序员智能体（engine/ui/gameplay/ai/network-programmer）→ 按领域划分的实现者角色（如 backend/frontend/data/infra）；引擎专家 `specialists.code/shader/ui/primary` → 技术栈版本专家（如语言专家、框架专家）；Godot 解析检查 → 目标语言的语法/编译检查命令；`engine.path`/`commands.test` → 项目构建/测试入口；TR registry → 需求追踪表；ADR → 技术决策记录；manifest → 变更控制清单。
- **改写示例**：
  - "实现者路由：基础设施层任务交给 infra-programmer；类型为界面的交给 frontend-programmer；领域层按子域交给对应专家；纯配置/数据任务不派智能体，逐项展示值变更并征得同意后直接编辑。"
  - "运行观察结论只允许一行纯文本 `Run result: OBSERVED/NOT VERIFIED/N/A — 原因`，只在收尾块出现一次；后续审查技能原样读取该行。"

## 6. 关联文档
- 上游：`/create-stories`（产故事卡）、`/story-readiness`（推荐预检，非前置）。
- 下游：`/code-review [files]`（`standard`/`full` 档）、`/story-done [story-path]`、`/team-qa`（手感类 DEFERRED）、`/create-stories`（范围过大时拆分）、`/architecture-decision`（解锁 Proposed ADR）。
- 引用：`.claude/docs/code-root-resolution.md`、`.claude/docs/run-and-observe.md`、`.claude/docs/error-recovery-protocol.md`、`.claude/rules/test-standards.md`、`references/version-mismatch.md`、`references/engine-checks.md`。
