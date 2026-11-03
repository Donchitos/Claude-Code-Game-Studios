# create-control-manifest — 从 Accepted ADR 生成扁平程序员规则（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/create-control-manifest/SKILL.md) ｜ 阶段：Phase 3 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/create-control-manifest [update — regenerate from current ADRs] [--review full|lean|solo]`
- **一句话职责**：从 Accepted ADR、项目技术偏好与引擎参考文档中，按架构层提炼一份给程序员的扁平规则清单（必做与禁做）——ADR 说"为什么"，清单说"做什么"。
- **触发前置**：`/architecture-review` 通过且 ADR 为 Accepted 之后运行；每当 ADR 被接受或修订后须重新运行（`update`）。写入 `docs/architecture/control-manifest.md`，且仅在用户明确同意后写。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode`、`review_gate`、`automation`（经 `hooks/yaml-helper.sh resolve_config`；`--review` 覆盖本次 `review_mode`；无输出块则用 `.claude/docs/config-resolution.md` 默认值） | `review_gate` 决定 TD-MANIFEST 门禁跑或跳 |
| 读取 | `bash .claude/scripts/adr-status.sh`：一次扫描全部 `docs/architecture/adr-*.md`，先输出计数（`adrs`、`accepted`、`proposed`、`deprecated`、`superseded`、`unfilled`、`other`、`no_status`），再逐行输出每个 ADR 的状态与层 | 先定分母再读正文 |
| 读取 | `project.yaml` 的 `naming.*` 与 `performance.*`；键缺失/为空时回退 `.claude/docs/technical-preferences.md`；已批准库与禁用模式恒取自 `technical-preferences.md` | 全局规则来源 |
| 读取 | `docs/engine-reference/[engine]/VERSION.md`（引擎与版本）、`deprecated-apis.md`（→禁用 API）、`current-best-practices.md`（存在时） | 引擎参考 |
| 读取 | 既有 `docs/architecture/control-manifest.md`（存在则本次为再生成，写入前必读，Phase 5 会替换它）；`production/epics/*/EPIC.md`（存在则 epic 已有） | Phase 6 择下一步 |
| 读取 | 每个 Accepted ADR 仅四节（`bash .claude/scripts/md-section.sh extract <file> "节名"`）：Decision、Alternatives Considered、Performance Implications、Engine Compatibility | 禁读全文 |
| 产出 | `docs/architecture/control-manifest.md`（程序员速查清单，含 Manifest Version 日期戳） | 结构见 R12 |
| 派生智能体 | `technical-director`（门禁 TD-MANIFEST，仅 `review_gate: skill-gates=run` 时派出；读 `.claude/docs/director-gates/td-manifest.md`） | 检查抽取出的规则；不写文件 |

## 3. 核心规则（逐条编号 R1、R2……）

**提问纪律（开头）**
R1. 提问必须用问题工具；没有该工具时把选项编号列出并结束回合等待。被跳过或被关闭的问题不是答案：必须以纯文本再问一次。（出处：开头）
R2. 提问节奏遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大选择 · autonomous 记录后继续；`automation_always_ask` 类别恒问）。（出处：Asks 段）

**Phase 1：加载输入与分母判定**
R3. 必须先读 `adr-status.sh` 计数、在读任何 ADR 正文前按分母表决策：
- `adrs 0`：无 ADR——提示"未找到 ADR——先运行 `/architecture-decision` 再构建控制清单"并停止；
- `accepted ≥ 1`：正常——Accepted 行构成集合 **A**，其余每个 ADR 连同状态都要在 Phase 4 预览中点名（用户须在知道清单遗漏了什么的前提下批准）；
- `accepted 0` 且部分有状态：无 Accepted ADR——说明"由 Proposed ADR 构建的清单会固化仍可能改变的决策"，询问用 Proposed 继续还是停止；**禁止静默写空清单**；
- 全部 `no_status`：这是**畸形 ADR 而非空 Accepted 集**——提示对每个文件运行 `/architecture-decision retrofit [file]` 并停止；禁止视为 Accepted。
每种停止都以 `Verdict: BLOCKED — [原因]` 结束。（出处：Phase 1 ADRs 表）
R4. 必须记录每条规则来自哪个 ADR 的编号与标题；加载完成须汇报"Loaded [A] Accepted ADRs of [N], engine: [name + version]"。（出处：Phase 1）

**Phase 2：从每个 ADR 抽规则**
R5. 对集合 A 中每个 ADR 只读四节（Decision / Alternatives Considered / Performance Implications / Engine Compatibility），禁止读全文；某 ADR 缺某节：记下并继续；集合 A 中每个 ADR 都缺同一节：必须报告"No Accepted ADR has a `[section]` section — the manifest's [category] rules will be empty. Verify this is intended."；只有当某节明确指向自身之外（如"受 Context 中的约束限制"）时才追读那一节。（出处：Phase 2）
R6. 四类规则的抽取口径：**必用模式**（Decision）= 每个 "must/should/required to/always" 及其规定的模式或做法，含其中的 `### Implementation Guidelines`——禁止只扫该子标题（许多 ADR 把要求直接写在 Decision 下，只扫子标题会得到空节）；**禁用做法**（Alternatives Considered）= 每个被否决的备选方案，以"因 Y 永不用 X"的形式连同否决理由，及一切点名的反模式；**性能护栏**（Performance Implications）= 预算（如"本系统每帧最多 N ms"）与内存上限；**引擎 API 约束**（Engine Compatibility）= 需验证的 post-cutoff API、与模型直觉不符的行为、钉定版本中变更的字段/方法。（出处：Phase 2）
R7. 每条规则归入其治理系统所在的层（ADR 有 `layer` 列则从之）：**Foundation**（场景管理、事件架构、存/读档、引擎启动）、**Core**（核心玩法循环、主要玩家系统、物理与碰撞）、**Feature**（次级系统与机制、AI）、**Presentation**（渲染、音频、UI、VFX、shader）；跨层 ADR 把规则放进每一相关层。（出处：Phase 2 Layer）

**Phase 3：全局规则**
R8. 全层通用规则各带来源（`project.yaml` 键 / `technical-preferences.md` / 引擎参考文件）：命名（`naming.*`：类、变量、信号与事件、文件、常量）；性能预算（`performance.*`：目标帧率、帧预算、draw call、内存上限）；必用模式（`current-best-practices.md` 存在时）；禁用模式（`technical-preferences.md`，照抄原文）。（出处：Phase 3）
R9. 禁用 API 只取 `deprecated-apis.md` 中**确实适用于本项目所构建内容**的条目，禁止整表照抄（其 `GodotPhysics3D → Jolt Physics 3D` 行仅限 3D，2D 项目用不到）；无法判断是否适用（2D/3D、项目未必包含的模块）时，要么限定规则范围（"使用 3D 物理时：……"）要么不收并列为 unresolved——`/create-stories` 会读本文件，不适用的规则是没人读的规则。（出处：Phase 3）

**Phase 4：预览与 TD-MANIFEST 门禁**
R10. 必须先展示固定格式预览（Control Manifest Preview）：引擎与版本、覆盖的 ADR 编号、遗漏的 ADR（每个不在 A 中的 ADR 及状态，或 "None"）、各层抽取计数（required/forbidden/guardrails）、全局计数、unresolved 项；并询问"这份规则摘要看起来完整吗？"（选项：Yes—评审并写入 / Add rules—我还有要加的 / Remove rules—有些该删 / Stop—我要先审 ADR）。（出处：Phase 4）
R11. 按 `review_gate` 行决定技术评审：`skill-gates=skip`（solo 或 lean）不派智能体，记录 `TD-MANIFEST skipped — [Solo | Lean] mode`；`skill-gates=run` 时把评审交给 `technical-director` 智能体执行门禁 **TD-MANIFEST**（其自读门禁文件；目标=写入前检查抽取的规则；提供=含完整规则列表的预览、覆盖的 ADR、引擎版本、取自技术偏好/引擎参考的规则；检查=每个强制性 ADR 模式都被准确捕获、禁用做法完整且归属正确、无规则缺来源 ADR 或偏好文档、护栏与 ADR 约束一致；返回=APPROVE / CONCERNS / REJECT / NOT ASSESSED 并点名缺失输入；边界=不写任何文件）。（出处：Phase 4）
R12. 按裁决行动：APPROVE→进 Phase 5；CONCERNS→询问用户（修改被标记的规则 / 接受并继续 / 进一步讨论）；REJECT→不写任何内容，修复被标记的规则后重新展示摘要；NOT ASSESSED 不是批准——点名缺失项并补齐后重跑，或用户选择无它继续时进 Phase 5 并在回复与最终裁决行中写明 `TD-MANIFEST: NOT ASSESSED — [input]`。（出处：Phase 4）

**Phase 5：写入**
R13. 写入前必须询问"可以把控制清单写入 `docs/architecture/control-manifest.md` 吗？"（选项：Yes, write it / 先看完整草稿再问 / Not yet—还要改）；仅在明确 yes 时写入。（出处：Phase 5）
R14. 文件必须按固定模板：头部含 Engine（名称+版本）、Last Updated（日期）、Manifest Version（生成日期，恒等于 Last Updated——同一日期面向不同读者；story 写入时嵌入该版本，`/story-readiness` 用它比对出基于旧规则写的 story）、ADRs Covered、Status: Active — regenerate with `/create-control-manifest update` when ADRs change；正文依次为 Foundation / Core / Feature / Presentation 四层规则（各含 Required Patterns / Forbidden Approaches，Foundation 与 Core 另含 Performance Guardrails，每条规则带 source）与 Global Rules（命名规范表、性能预算表、已批准库、禁用 API（含引擎版本与来源）、Cross-Cutting Constraints）；开头说明"理由请读对应 ADR"。（出处：Phase 5 模板）

**Phase 6：收尾与裁决**
R15. 下一步按现状二选一：尚无 epic——"运行 `/create-epics layer: foundation`，然后 `/create-stories [epic-slug]`：story 会嵌入本清单的规则与版本"；本次为再生成——"已更新。告知团队规则变化，尤其是新增的 Forbidden 条目"。（出处：Phase 6）
R16. 每条规则必须可追溯到一个 ADR、一条技术偏好或一份引擎参考文档；禁止凭空发明规则，禁止以改变其含义的方式改写。写入后以 `Verdict: COMPLETE — control manifest written` 收尾；用户拒绝写入时以 `Verdict: BLOCKED — user declined the write` 收尾。（出处：尾段）

## 4. 门禁与裁决
- 门禁 ID：**TD-MANIFEST**（审查者 `technical-director`；定义在 `.claude/docs/director-gates/td-manifest.md`，由智能体自读）。
- 触发：`review_gate: skill-gates=run` 时执行；`skip`（solo/lean）时记录跳过。
- 裁决词：APPROVE / CONCERNS / REJECT / NOT ASSESSED（NOT ASSESSED 不是批准，见 R12）。
- 技能级裁决：`Verdict: COMPLETE — control manifest written` / `Verdict: BLOCKED — [原因]`（无 ADR、全 no_status、用户拒绝写入等）。

## 5. 移植建议
- **可直接移植**：R1（跳过的问题不算答案）、R3–R7（先定分母再干活、只读四个规定节、四类规则抽取口径、按层归类）、R9（只收适用的禁用条目、不适用即 unresolved）、R10–R14（预览→评审→明确 yes 才写）、R16（规则必须可溯源、两种 Verdict 收尾）。
- **需替换概念**：ADR → 技术决策记录；引擎参考（deprecated-apis / best-practices）→ 框架的弃用 API 表与最佳实践文档；Foundation/Core/Feature/Presentation 四层 → 项目分层（如基础设施/业务核心/功能/表现）；story/epic → 任务/史诗（工单系统）；帧预算等性能键 → 项目的性能/成本预算键。
- **改写示例**：
  - "规则清单只能从已接受的决策记录（Accepted）提取；无已接受决策时禁止静默产出空清单——必须停下来问用户是降级使用草案决策还是停止。"
  - "每条编码规则必须标注来源（决策记录编号/偏好文档/框架参考）；禁止发明规则，也禁止改写到改变原意的程度。"

## 6. 关联文档
- 上游：`/architecture-decision`（产出 ADR，含 accept/retrofit）、`/architecture-review`（须先通过且 ADR 为 Accepted）
- 下游：`/create-epics`、`/create-stories`（story 嵌入清单规则与 Manifest Version）、`/story-readiness`（比对版本发现旧规则 story）
- 规范文档：`.claude/docs/director-gates.md`、`director-gates/td-manifest.md`、`automation-modes.md`、`config-resolution.md`、`technical-preferences.md`
- 脚本：`.claude/scripts/adr-status.sh`、`md-section.sh`
