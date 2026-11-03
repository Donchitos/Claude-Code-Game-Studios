# code-review — 架构级代码审查（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/code-review/SKILL.md) ｜ 阶段：Phase 5+ ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/code-review [path-to-file-or-directory] [story-path]`（末位可选 story 文件路径，用于提取治理 ADR 引用）
- **一句话职责**：对实现代码做架构级审查——编码标准、SOLID、可测试性、性能关注、ADR 合规。
- **触发前置**：目标文件/目录存在；配置经 `resolve_config --keys automation` 解析；每个 `AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续；`automation_always_ask` 类别恒提示）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 目标文件全文；`CLAUDE.md`；`project.yaml` 的 `specialists` 块（缺失回退 `.claude/docs/technical-preferences.md` 的 `## Engine Specialists` 节）；story 文件（作为参数时）；ADR 文件的 `## Decision`/`## Consequences` 节；`git log`（ADR 引用溯源） | 编码标准 / 专家路由 / 治理决策 / 提交历史 |
| 产出 | 审查报告（会话内输出）——本技能只读，不写任何文件 | 裁决驱动 `/story-done` 等下游动作 |
| 派生智能体 | 引擎专家（Language/Code、Shader、UI、Primary `<engine>-specialist`）、`qa-tester`（Logic/Integration story 时） | 全部并行 spawn；无引擎配置则引擎专家步骤跳过并留痕 |

## 3. 核心规则（逐条编号 R1、R2……）

### 输入不足前置检查
R1. 产出任何报告前必须先核对本技能所需输入的存在性：
   1. 列出全部输入（数据文件、先前报告、profiler 输出、测试结果、registry、源代码）；
   2. 逐项记 `FOUND` 或 `ABSENT`（不是"假设存在"）；
   3. 某节必需输入 ABSENT 时该节记 **`NOT ASSESSED — NO DATA`**——禁止估算、禁止从相邻工件推断、禁止把必填格留给下次读模板的人；
   4. **每一个**必需输入都 ABSENT 时停止并整体报告 `NOT ASSESSED — NO DATA`，点名缺了什么、哪个技能产出它。（Insufficient input）
R2. `NOT ASSESSED` 裁决是成功而非失败——它是"数据说什么"在无数据时的正确答案。禁止缺"无法运行"态的裁决枚举产生假性干净通过（零资产零标准却报 COMPLIANT、无 profiler 数据无预算却报 ">99% headroom against a 16.67ms budget"）。"无证据"绝不是"不存在证据"：零文件可扫的扫描没有验证任何东西，必须说明是哪一种——读者无法从绿色结果分辨。（Insufficient input）

### Phase 1-2 — 载入与专家识别
R3. 全文读取目标文件；读 `CLAUDE.md` 了解项目编码标准。（Phase 1）
R4. 从 `project.yaml` 的 `specialists` 块识别四类专家（缺失则回退 `technical-preferences.md` 的 `## Engine Specialists` 节）：Primary（`<engine>-specialist`，由 `engine.name` 派生：Godot→`godot-specialist`、Unity→`unity-specialist`、Unreal→`unreal-specialist`，管架构与广泛引擎关注）、Language/Code（`specialists.code`，审主语言文件）、Shader（`specialists.shader`）、UI（`specialists.ui`）。（Phase 2）
R5. `specialists` 键值为 `null` 即 UNSET：按缺失处理并跳过该专家，**绝不**把 `null` 当代理名 spawn——v1.0 迁移会给未配置的专家写 `null`（仅配 code 专家的项目带 `shader: null`、`ui: null`），配置读取器返回四字符串 `"null"` 并非空所以会被当成已配置。`null`、空、缺键三态同义。（Phase 2）
R6. 未配置引擎时（`project.yaml` 无 `engine.name` 且 `technical-preferences.md` 读 `[TO BE CONFIGURED]` 或缺失）跳过引擎专家步骤，并在输出记录 `Engine validation: NOT ASSESSED — no engine configured`——沉默跳过的检查与通过的检查无法区分。（Phase 2）

### Phase 3 — ADR 合规
R7. ADR 引用按优先级搜索：story 文件（作为参数给出时）→ 实现文件头部注释 → 提交信息（`git log --oneline -- [file]`）；模式为 `ADR-NNNN` 或 `docs/architecture/adr-`（大小写均可）。无任何引用时记录 "No ADR references found — ADR compliance check skipped. For full ADR compliance review, provide the story path: `/code-review [files] [story-path]`"。（Phase 3）
R8. 被引用的 ADR 缺失或不可读时，ADR Compliance 记 `NOT ASSESSED — [ADR] could not be read` 并点名该 ADR——这与 `NO ADRS FOUND`（完全无引用）是不同结果。（Phase 3）
R9. 读 ADR 只取本检查所需节，禁止无界全文读：先 `Grep pattern="^## " -n` 建标题图（只要行号，便宜），再用行号有界读 `## Decision` 与 `## Consequences`（到下一标题为止）；标题图为空（模板前的非标 ADR）才回退一次全文 Read，若在 25k-token 上限截断则直接 grep 决策/后果内容而非分页续读（分页是最贵的读法）。（Phase 3）
R10. 偏差三级分类：
   - **ARCHITECTURAL VIOLATION**（BLOCKING）——使用了 ADR 明确拒绝的模式；
   - **ADR DRIFT**（WARNING）——未用禁用模式但对所选方案实质偏离；
   - **MINOR DEVIATION**（INFO）——不影响整体架构的小差异。（Phase 3）

### Phase 4-6 — 静态检查清单
R11. 标准合规 6 项：
   - [ ] 公有方法与类有文档注释；
   - [ ] 每方法圈复杂度低于 10；
   - [ ] 无方法超过 40 行（不含数据声明）；
   - [ ] 依赖被注入（游戏状态无静态单例）；
   - [ ] 配置值从数据文件加载；
   - [ ] 系统暴露接口而非具体类依赖。（Phase 4）
R12. 架构 5 项：依赖方向正确（engine ← gameplay，不反向）；模块间无循环依赖；分层得当（UI 不拥有游戏状态）；跨系统通信用事件/信号；与代码库既有模式一致。SOLID 5 项：单一职责（每类只有一个变更理由）、开闭（可扩展无需修改）、里氏替换（子类型可替换基类型）、接口隔离（无胖接口）、依赖倒置（依赖抽象非具体）。（Phase 5）
R13. 游戏特定关注 5 项：帧率无关（delta time 使用）；热路径（update 循环）无内存分配；空/null 状态处理得当；必要处线程安全；资源清理无泄漏。（Phase 6）

### Phase 7 — 专家审查
R14. 所有适用专家通过 `Agent` **同时并行** spawn——禁止等一个完成再开下一个。（Phase 7）
R15. 每个专家发现必须核实后才能报告，禁止未经核实直接转述。每条发现记录：所指**文件与行号**；**证据**（引用的代码，或触发它的具体输入/状态）；**置信度**——`VERIFIED`（自己查过）或 `UNVERIFIED — specialist claim`（没能查证）。无法核实的发现按未核实报告或直接丢弃，绝不因措辞自信而升格为缺陷。理由：代理在推导时可靠、在诊断既有代码时不可靠——短函数上的错误论断可以流畅到骗过略读，声称的 bug 在枚举输入后会瓦解；没有这一步，父审查就成了洗白通道：猜测以专家发现进场、以已审缺陷出场。（Phase 7）
R16. 引擎专家路由：主语言文件（`.gd`/`.cs`/`.cpp`）→ Code 专家；shader 文件（`.gdshader`/`.hlsl`/shader graph）→ Shader 专家；UI 屏幕/部件代码 → UI 专家；跨切面或不明确 → Primary 专家；任何触及引擎架构的文件（场景结构、节点层级、生命周期钩子）**额外** spawn Primary 专家。（Phase 7）
R17. Logic 与 Integration story 必须额外并行 spawn `qa-tester`，传入实现文件、story 的 `## QA Test Cases` 节（qa-lead 预写的测试规格）、`## Acceptance Criteria`。评估：测试钩子与接口是否全部暴露（未藏于 private/internal）；story 的 QA 测试用例是否映射到可测代码路径；是否有验收标准按现状实现不可测（硬编码值、无注入缝隙）；实现是否引入 QA 用例未覆盖的新边缘情形；是否有本该有测试的可观察副作用。Visual/Feel 与 UI story：qa-tester 审 `## QA Test Cases` 中的手动验证步骤按现状实现是否可达成（手动检查者需要到达的状态是否真的可达）。收集全部专家发现后才产出输出。（Phase 7）

### Phase 8 — 输出与裁决
R18. 报告节：Engine Specialist Findings（`N/A — no engine configured` / `CLEAN` / `ISSUES FOUND`）；Testability（`N/A — no story path given` / `N/A — Visual/Feel or Config story` / `TESTABLE` / `GAPS` / `BLOCKING`——BLOCKING 时说明实现必须先暴露 [X] 才能跑 `## QA Test Cases` 中的测试）；ADR Compliance（`NOT ASSESSED` / `NO ADRS FOUND` / `COMPLIANT` / `DRIFT` / `VIOLATION`，逐 ADR 列结果与偏差严重度）；Standards Compliance（`X/6 passing`，失败项带行引用，缺文档注释须点名方法或类名）；Architecture（`NOT ASSESSED` / `CLEAN` / `MINOR ISSUES` / `VIOLATIONS FOUND`）；SOLID（`NOT ASSESSED` / `COMPLIANT` / `ISSUES FOUND`）；Game-Specific Concerns；Positive Observations（做得好的——**恒含此节**）；Required Changes（批准前必修项——ARCHITECTURAL VIOLATION 恒在此）；Suggestions；Verdict。（Phase 8）
R19. 裁决按首匹配：
   - **CHANGES REQUIRED**——Required Changes 有任何项；
   - **NOT ASSESSED**——无物可审（上述无数据路径）、引擎专家审查未跑（无引擎配置或专家无法 spawn）、或任何报告节读 `NOT ASSESSED`（被引用 ADR 不可读、Architecture、SOLID），并点名是哪些。NOT ASSESSED 排在 CHANGES REQUIRED 之下——已知缺陷比跳过的检查更可行动——且高于两种批准：跳过了引擎检查的审查没有批准代码。`NO ADRS FOUND` 不算 NOT ASSESSED：无 ADR 可查时不阻止批准；
   - **APPROVED WITH SUGGESTIONS**——仅 Suggestions；
   - **APPROVED**——无必修项且无建议。（Phase 8）

### Phase 9 — 收尾
R20. 收尾用 `AskUserQuestion`，提示词逐字带 Phase 8 裁决；选项按裁决分支：APPROVED→`[A] Run /story-done` / `[B] Stop here`；APPROVED WITH SUGGESTIONS→`[A] Apply the suggestions, then run /story-done` / `[B] Run /story-done now — suggestions noted for later` / `[C] Stop here`；CHANGES REQUIRED→`[A] Fix the issues and re-run /code-review` / `[B] Run /story-done anyway with noted exceptions` / `[C] Stop here`；NOT ASSESSED→`[A] Fix what stopped the review (point me at the code, run /setup-engine, or fix the unreadable ADR reference), then re-run /code-review` / `[B] Stop here`。（Phase 9）
R21. 发现 ARCHITECTURAL VIOLATION 时：违反既有 ADR→修实现以合规 `docs/architecture/[adr-file].md`；设计确已合法变更→运行 `/architecture-decision` 正式**修订**既有 ADR——禁止另立竞争性 ADR。被违反的模式无对应 ADR→先运行 `/architecture-decision` 记录正确方案再修代码。（Phase 9）

## 4. 门禁与裁决
- **裁决词**：`NOT ASSESSED` / `APPROVED` / `APPROVED WITH SUGGESTIONS` / `CHANGES REQUIRED`。
- **排序（首匹配）**：CHANGES REQUIRED > NOT ASSESSED > APPROVED WITH SUGGESTIONS > APPROVED。
- **取最严原则**：任何节读 `NOT ASSESSED` 即拉低整体裁决至 NOT ASSESSED（点名）；ARCHITECTURAL VIOLATION 恒入 Required Changes 从而恒 CHANGES REQUIRED。
- **消费方**：裁决驱动 `/story-done`（story 完结门禁）与修复重审循环。

## 5. 移植建议
- **可直接移植**：R1-R2（输入不足前置检查与 NOT ASSESSED 哲学）、R8-R9（ADR 有界读取）、R15（专家发现必须带证据与置信度核验）、R18 的 Positive Observations 恒含、R19 首匹配裁决排序、R21（修订既有决策文档而非另立竞争文档）。
- **需替换概念**：ADR（Architecture Decision Record）→ 任何治理决策文档（RFC、设计决策记录）；引擎专家表 → 技术栈专家（框架专家、DBA、安全专家）；Phase 6 游戏清单 → 按领域换成性能/并发/IO 清单；`/story-done` → 任务完结流程；`project.yaml` 的 `specialists` → 评审路由配置。
- **改写示例**：
  - R15 → "每条来自子代理的审查发现必须核实后报告：记录文件与行号、证据（引用代码或触发输入）、置信度（VERIFIED / UNVERIFIED — specialist claim）。无法核实的发现按未核实报告或丢弃，绝不因措辞自信而升格为缺陷。"
  - R9 → "读取被引用的决策文档时只取 Decision 与 Consequences 节：先建标题行号图再有界读取；超过读取上限时直接检索目标内容，禁止分页续读整个文件。"

## 6. 关联文档
- 上游：`/dev-story`、`/create-stories`（story 与 QA Test Cases 的来源；本技能 ADR 读取模式与之一致）。
- 下游：`/story-done`（裁决为 APPROVED 时）、`/architecture-decision`（修订或新建 ADR）、`/setup-engine`（NOT ASSESSED 时补引擎配置）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/technical-preferences.md`、`docs/architecture/adr-*.md`。
