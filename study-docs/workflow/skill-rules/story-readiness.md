# story-readiness — 故事领取前校验（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/story-readiness/SKILL.md) ｜ 阶段：Phase 4-5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/story-readiness [story-file-path | 'all' | 'sprint' | 史诗slug] [--review full|lean|solo]`
- **一句话职责**：检查故事文件是否备齐开发者动手前所需的一切——验收标准清晰、无未决问题、ADR 与依赖有效——给出 READY / NEEDS WORK / BLOCKED / NOT ASSESSED 四态裁决。
- **触发前置**：范围内存在故事文件；范围内一张卡都没有即停止（`NOT ASSESSED — no stories in scope`）。**本技能只读**：永不写/改文件，只报告并可在对话中代起草修复内容。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, review_gate, automation, workflow, qa.level, gate_level, story_granularity, system_overrides`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | 档位逐故事解析（`workflow`+`system_overrides`）；`story_granularity` 定 AC 下限；`qa.level`/`gate_level` 定测试证据档；`review_gate` 定 QL-STORY-READY |
| 读取 | `story-facts.sh --lint --granularity <值> [--sprint \| --all \| <path>...]`（STORY 行给状态/类型/层级/估时/TR-ID/ADR/AC 数/测试证据行/依赖；LINT 行给触发的规则；exit 3 = 文件未找到）；每个故事文件本体（可测性/范围/资产项需要原文）；`adr-status.sh` 一次取全部 ADR 状态与层级；`docs/architecture/control-manifest.md` 的 `Manifest Version` 行；`docs/architecture/tr-registry.yaml` 查各 TR-ID 与 `status`；`production/sprints/` 最新计划（sprint 范围的优先级） | 事实一次读取、整run 复用 |
| 产出 | 无文件写入；回复内报告（单故事块/多故事汇总）；可在对话中起草缺失内容（用户或 `/create-stories` 负责落盘） | 只读技能 |
| 派生智能体 | `skill-gates=run` 时派 QL-STORY-READY QA 主审智能体（读 `references/qa-lead-gate.md` + `.claude/docs/director-gates.md`，报告前运行）；skip 时不加载 | solo/lean 无智能体 |

## 3. 核心规则
R1. **裁决顺序**（每故事一个，首个命中即胜出）：**BLOCKED**（存在读者可清除的发现：引用的 ADR 缺失/`Proposed`/`Deprecated`/`Superseded`；依赖故事缺失或 `Draft`；或某条标准内嵌无 owner 的 UNRESOLVED 设计问题）→ **NEEDS WORK**（阻断性检查项失败，故事当下可修）→ **NOT ASSESSED**（无法评估：文件不可读、引用 ADR 无可读 `## Status`、所名设计文档找不到；必须点名什么读不了；它**永远不是 READY**——没人能查过的故事不等于已证明就绪；排在两个失败之下，因为已知 blocker 比未知更有用）→ **READY**（每项通过、带理由的 N/A、或 advisory；advisory 缺口仍要列出）。（Verdicts）
R2. 范围解析：技能名后的文本去掉 `--review` 对即为范围值（路径可含空格）；无输入时取请求点名的故事/史诗/冲刺。取值：故事路径 = 该卡；`sprint` = 当前冲刺所列故事；`all` = `production/epics/` 下全部 `story-*.md`；史诗（slug 或文件夹）= 该文件夹下的 `story-*.md`；全空则问"检查什么？"（选项：指定故事文件 / 当前冲刺全部 / production/epics/ 全部 / 某史诗的全部）。（Phase 1）
R3. 范围内零故事：停止并给 `NOT ASSESSED — no stories in scope`，点名范围与空掉的路径，指路 `/create-stories`（`standard`/`full` 先 `/create-epics`）；**禁止**在空清单上打印 `Ready: 0 / Needs Work: 0` 汇总（读起来像全绿）。`sprint` 范围下"没有冲刺计划"与"冲刺计划没列故事"是两种报告，必须说清是哪种。继续前先说 "Checking [N] story files."。（Phase 1）
R4. 事实一次读取（Phase 2）：`story-facts.sh --lint` 的 STORY/LINT 行只是观察，裁决由自己下；`NOT_FOUND` 行逐个报为缺失故事并继续查其余；`--sprint` 且无 `NOT_FOUND` 行 → 无 `production/sprint-status.yaml`，报 "no sprint plan found"。仍须读每个故事文件原文（可测性/范围/资产项要原文措辞）。ADR：`no_status`/`UNFILLED` 是畸形 ADR——**禁止把缺失状态当失败状态**（指路 `/architecture-decision retrofit [file]`）；故事引用但无行的 ADR 即缺失。manifest 只读 `Manifest Version` 行，文件缺失记一次。TR registry 查各 TR-ID 及 `status`，文件缺失记一次且 TR-ID 项对每张卡都算过。sprint 范围另取最新计划的 Must/Should 优先级。（Phase 2）
R5. 档位逐故事解析：用该故事系统（其 `GDD:` 路径的文件名主干；无 GDD 路径时才用 `TR-[system]-NNN` 的 `[system]`）的 `system_overrides` 行，无则项目 `workflow` 值；**同一次运行的不同故事可处于不同档**。（Phase 2）
R6. 检查表分组按档定阻断（Phase 3 表）：Design Completeness——三档都阻断（`minimal` 档 `design/game-brief.md` 顶替 GDD）；Architecture Completeness——`full` 全阻断，`standard` 仅 ADR status 项阻断、其余 advisory（涉及关键 ADR 除外），`minimal` 全 N/A 唯 ADR status 项除外；Scope Clarity——三档都阻断（`minimal` 档 Estimate 为 advisory，因无冲刺计划可为之定尺寸）；Open Questions、Asset References——三档都阻断；Definition of Done——三档都阻断（`minimal` 档测试证据项随 `qa.level`）。advisory 项失败只进 Gaps 附 Fix，**单独绝不把 READY 拉低**。（Phase 3）
R7. **Design Completeness** 四项：Requirement traced——点名 `design/gdd/` 文件且引用或链接具体规则/标准（不能只给文件名；`minimal` 档用 brief + 所实现的 MVP 特性；点名的设计文档不存在 → NOT ASSESSED）；Self-contained——AC 不开 GDD 也说得清"完成"是什么；Testable——每条标准是具体可观察条件（不是"Implement the jump mechanic."，而是"Jump reaches 5 units within 0.3 seconds when held."；单元测试能搭建的标准（任意输入值）即算可测，即便交付数据永远到不了那种情况）；No judgement calls——"feels responsive"/"looks good" 在 Logic、Integration、UI、Config/Data 上失败；在 Visual/Feel 上是预期的：标准点名证据文件（如 `production/qa/evidence/[slug]-evidence.md`）即过，没点名 → NEEDS WORK。（Design Completeness）
R8. **Architecture Completeness** 六项：ADR status（每档都查）——`Accepted` 过；`Proposed` → BLOCKED（Fix：`BLOCKED: ADR-NNNN is Proposed — accept it with /architecture-decision accept ADR-NNNN once decided`）；`Deprecated`/`Superseded` → BLOCKED（Fix：指向后继 ADR，手工改 ADR 字段，`/create-stories` 不重写既有卡）；无文件 → BLOCKED；无可读状态 → 该项 NOT ASSESSED 并点名文件。`standard` 档下关键 ADR（`layer` 为 Foundation 或缺失）缺失或 Proposed 才阻断，其余 ADR 的下列各项 advisory。ADR cited or N/A stated——有 ADR 或显式带理由的 N/A（`ADR: N/A — [原因]` / `N/A (minimal — no ADRs)`），留白即失败。TR-ID valid——每个 `TR-[system]-NNN` 须在 registry 且 `status: active`；`deprecated` 或 `superseded-by`（带不带引号）→ NEEDS WORK（Fix：指向现行需求）；不在 registry → NEEDS WORK（故事可能早于它，或 registry 需要 `/architecture-review`）；无 TR-ID 或无 registry 即过。Manifest Version current——故事卡版本落后于 manifest 即为缺口（之后新增的规则可能适用；即使看起来无关也仍是缺口：说清变了什么、把判断留给用户）；`full` 档无论新增规则涉及什么都 NEEDS WORK，`standard` 档 advisory；Fix 三步：审阅故事日期后新增的 manifest 规则、有适用就更新故事的规则、然后把 Manifest Version 设为当前日期；无该字段或无 manifest 即过。Engine notes——触碰截止版本后引擎 API 的故事须有注记或验证步骤，或声明 "N/A — no engine API involved"。Manifest rules noted——列出该层规则，或 "N/A — manifest not yet created"；无 manifest 即过。（Architecture Completeness）
R9. **Scope Clarity** 三项：Estimate——小时、点数或 t-shirt 尺码；`unfilled Estimate`（仍是模板括号）失败；`minimal` 档 advisory。Out of scope stated——有 Out of Scope 节或边界无歧义的措辞。Dependencies listed——逐个点名所需故事，或明示 "None"。（Scope Clarity）
R10. **Open Questions** 两项：No open markers——无 `marker` 行（TBD、TODO、UNRESOLVED 作为全大写整词）；`?` 不是 marker（`crit ? 2 : 1` 这类公式通过）；写成开放问题的标准仍会挂在 Testable 上。Dependencies exist and are not Draft——依赖故事缺失或 `Draft` → 故事 BLOCKED；`Story NNN` 指同史诗文件夹里那个编号，路径则精确点名。（Open Questions）
R11. **Asset References** 一项：故事读取或依赖的资产存在——`assets/` 下的路径，或带 `.png` `.jpg` `.svg` `.wav` `.ogg` `.mp3` `.glb` `.gltf` `.tres` `.tscn` `.res` 扩展名者；故事说要创建的文件（新场景、新数据文件）不查；缺失 → NEEDS WORK 并点名路径；报告 "Referenced assets verified: [N] found" 或 "No asset references"；**只查存在性**。（Asset References）
R12. **Definition of Done** 四项：Enough acceptance criteria——无 `ac_below_min` 行，AC 下限随 `story_granularity`（`/create-stories` 按它写）：`coarse` 下 Logic/Integration 3、Visual/Feel·UI 2、Config/Data 1；`balanced` 下 2/2/1；`fine` 下 1/1/1。Performance noted——涉及 gameplay loop、渲染或物理的故事须给预算或 "no performance impact expected — [原因]"。Type declared——无 `type_missing`/`type_unknown` 行（Fix：头字段加 `Type: [Logic|Integration|Visual/Feel|UI|Config/Data]`）。Test evidence clear——有 `## Test Evidence` 节说明证据去处：Logic/Integration 是测试文件；UI 是 `production/qa/evidence/` 下每个屏幕的留存截图；Visual/Feel 是截图再加 `production/qa/evidence/[story-slug]-evidence.md`。`qa.level: minimal` 下 Logic、Integration、Config/Data 直接过（测试豁免——对缺失测试文件、`tests/` 目录或 test runner **不列缺口、不加注**）；UI 与 Visual/Feel 仍要查（截图在任何级别都必需）。否则按 `gate_level` 行给该类型定档：`blocking` → 缺节 NEEDS WORK；`advisory` → 只列缺口；Fix：按类型加 `## Test Evidence` 及证据位置。（Definition of Done）
R13. 逐故事按 R1 顺序出裁决；BLOCKED 的故事可以同时有 NEEDS WORK 项——两者都要列。（Phase 4）
R14. QL-STORY-READY：`review_gate` 为 `skill-gates=skip`（solo/lean）→ 跳过且回复写 "QL-STORY-READY skipped — [Solo | Lean] mode"；`skill-gates=run` → 读 `references/qa-lead-gate.md` 与 `.claude/docs/director-gates.md`，报告前运行；skip 时不加载。（Phase 5）
R15. 单故事报告格式：标题 + File + Verdict + Passing Checks（N/[总数]，按六个组）+ Gaps（失败项 + Fix）+ Blockers（BLOCKED 时）。**六个组每次都按精确组名全列**：Design Completeness、Architecture Completeness、Scope Clarity、Open Questions、Asset References、Definition of Done；全无通过项的组写 "none — see Gaps"（让读者看到查过）。Gaps 只列失败的检查项：**禁止**列通过或 N/A 项、**禁止**列检查表之外的观察（冲刺状态、别的文档）。（Phase 6）
R15 对应的单故事报告模板（保留原文格式约定）：

```
## Story Readiness: [story title]
File: [path]
Verdict: [READY / NEEDS WORK / BLOCKED / NOT ASSESSED]

### Passing Checks (N/[total])
Design Completeness: [passing items]
Architecture Completeness: [passing items, or "N/A at minimal (ADR status checked)"]
Scope Clarity: [passing items]
Open Questions: [passing items]
Asset References: [passing items, or "no asset references"]
Definition of Done: [passing items]

### Gaps
- [Checklist item]: [what is missing or wrong]
  Fix: [the text that resolves it]

### Blockers (if BLOCKED)
- [What blocks]: [the story, ADR or question that must clear first]
```

R16. 多故事：先汇总（`Ready: [N] · Needs Work: [N] · Blocked: [N] · Not Assessed: [N]` + 各裁决的故事清单及主缺口/阻断源/不可读原因），再给每个非 READY 故事一个单故事块。`sprint` 范围下有 Must Have 故事非 READY 时，把警告放最前：`WARNING: [N] Must Have stories are not ready to implement: [各带主缺口]. Fix them before the sprint starts, or replan with /sprint-plan update.`。（Phase 6）
R16 对应的汇总模板（保留原文格式约定）：

```
## Story Readiness Summary — [scope] — [date]
Ready: [N] · Needs Work: [N] · Blocked: [N] · Not Assessed: [N]

Ready: [title] ([path]), ...
Needs Work: [title]: [main gap]
Blocked: [title]: blocked by [story, ADR or question]
Not Assessed: [title]: [what could not be read]
```

R17. 单故事收尾"下一批可开工"：在 `production/sprints/` 最新计划里找至多 3 张 Ready 或 Not Started、非本卡、不等未完成依赖、Must Have 或 Should Have 的故事，各带一行描述与估时；没有时说明是哪种：`Next ready stories: no sprint file found` 或 `Next ready stories: none ready in [sprint]`。（Phase 6）
R18. 提供帮助：问 "Would you like me to draft the missing parts for any of these stories?"（选项：Yes, draft them / No, that's all）；yes 只在**对话中**起草缺失部分——由用户或 `/create-stories` 落盘。（Phase 6）
R19. 重定向：故事文件缺失 → `/create-stories [epic-slug]`（`standard`/`full` 先 `/create-epics`）；无设计引用且改动小（约一周内）→ `/quick-design [description]` 并在故事中引用该规格；范围超出其尺寸 → 拆分故事，或上报 producer。（Phase 6）
R20. 回复必须以块结束：`Review: [QL-STORY-READY skipped — Solo mode | skipped — Lean mode | its verdict]` + `Next ready stories: [...]`（单故事范围）+ `Next step: [/dev-story [path] when READY | fix the gaps above, then /story-readiness [path]]` + `Files changed: none`。（Phase 6）
R20 对应的收尾块模板（保留原文格式约定）：

```
Review: [QL-STORY-READY skipped — Solo mode | skipped — Lean mode | its verdict]
Next ready stories: [up to 3 | no sprint file found | none ready in [sprint]]   (one-story scope)
Next step: [/dev-story [path] when READY | fix the gaps above, then /story-readiness [path]]
Files changed: none
```

R21. 提问规则：有提问工具就用工具；没有则编号列选项并结束回合等待；被跳过/关闭的提问不算答案，纯文本再问。（全局）

## 4. 门禁与裁决
- **门禁 ID**：QL-STORY-READY（QA 主审）。
- **触发**：`review_gate` 的 `skill-gates`：`skip`（solo/lean）→ 跳过并注明；`run` → 报告前运行（读 `references/qa-lead-gate.md` + `.claude/docs/director-gates.md`；skip 时不加载）。
- **裁决标准**（本技能主裁决，每故事一个）：BLOCKED > NEEDS WORK > NOT ASSESSED > READY，首个命中即定（R1）；advisory 失败不降级 READY。
- **取最严**：NOT ASSESSED 永不折算为 READY；sprint 范围下 Must Have 非 READY 触发置顶 WARNING。

## 5. 移植建议
- **可直接移植**：R1（四态裁决及排序理由）、R3（空范围禁止打印全绿汇总、两种"没有"分开报告）、R4（畸形记录≠失败记录）、R5（同批逐条定档）、R6（分组×档位阻断矩阵、advisory 不降级）、R7（可测标准的正反例）、R9-R12（估时/边界/依赖/开放标记/资产存在性/AC 下限表）、R13-R16（双裁决并列、六组全列、汇总+明细、Must Have 警告置顶）、R17-R21（下一批推荐、对话内起草、重定向、收尾块）。
- **需替换概念**：GDD/设计文档 → 需求/规格文档；ADR → 技术决策记录；TR registry → 需求追踪表；manifest → 变更控制清单；引擎截止版本 API → 关键依赖的版本变更；资产扩展名列表 → 项目的资源类型；`/quick-design`、`/create-stories`、`/architecture-decision`、`/architecture-review` → 对应的补文档/拆卡/决策/评审流程；producer → 资源负责人。
- **改写示例**：
  - "裁决四态按序取首个命中：BLOCKED（存在可清除的引用断链或未决设计问题）> NEEDS WORK（阻断项失败、当下可修）> NOT ASSESSED（无法评估，点名不可读项，永不折算为就绪）> READY；advisory 失败只列缺口不降级。"
  - "依赖任务处于草稿态即判 BLOCKED；同目录内以编号互指的依赖按编号解析，路径则精确解析。"

## 6. 关联文档
- 上游：`/create-stories`（产故事卡）、`/sprint-plan`（sprint 范围与优先级）。
- 下游：`/dev-story [path]`（READY 后开工）、`/create-stories`（重定向与落盘起草内容）、`/quick-design`、`/architecture-decision`（accept/retrofit）、`/architecture-review`（registry 修复）、`/sprint-plan update`（Must Have 未就绪时重排）。
- 引用：`references/qa-lead-gate.md`、`.claude/docs/director-gates.md`、`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`。
