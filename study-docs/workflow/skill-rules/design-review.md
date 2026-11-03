# design-review — 设计文档审查（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/design-review/SKILL.md) ｜ 阶段：Phase 1-2 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/design-review [path-to-design-doc] [--review full|lean|solo]`
- **一句话职责**：在设计文档（GDD）交给程序员之前，按 8 节标准校验其完整性、内部一致性、可实现性与设计规范。
- **触发前置**：目标设计文档存在；配置经 `resolve_config --keys review_mode,automation,workflow,system_overrides` 解析（无配置块时默认值见 `.claude/docs/config-resolution.md`）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `CLAUDE.md`；目标 GDD 全文；`design/registry/entities.yaml`（存在且列有本系统条目时）；Dependencies 节点名的相关 GDD；`design/gdd/game-concept.md`（`rigor: minimal` 时为 `design/game-brief.md`）；`design/narrative/` 文件；`design/gdd/reviews/[doc-name]-review-log.md`；`design/gdd/systems-index.md` | 项目标准 / 交叉文档事实 / 世界观对齐 / 先前审查 / 收尾选项 |
| 产出 | Phase 4 报告只输出到会话（本技能此阶段只读不写文件）；经用户批准后：追加 `design/gdd/reviews/[doc-name]-review-log.md`（含 `review-receipts.sh hash` 收据行）、更新 `design/gdd/systems-index.md` 状态 | review log 是下次运行新鲜度检查的输入 |
| 派生智能体 | `economy-designer`、`game-designer`、`systems-designer`、`ai-programmer`、`level-designer`、`ux-designer`、`ui-programmer`、`narrative-director`、`gameplay-programmer`、`network-programmer`、`audio-director`、`performance-analyst`、`<engine>-specialist`、`qa-lead`、`creative-director`（终审） | 仅 `full` 模式按域表并行派生；`lean`/`solo` 不派生 |

resolve_config 配置键及档位影响：
- `review_mode`（可被 `--review` 覆盖）：`full` = 全部阶段 + Phase 3b 专家派生；`lean` = 全部阶段、无专家（更快，单会话分析）；`solo` = 仅 Phase 1-4、无派生、无 Phase 5 后续提示（供其它技能内部调用时使用）。
- `--depth` 是 `--review` 在 1.1 之前的旧名：按同义处理并提示一次已改名；两者同时给出时 `--review` 生效、`--depth` 忽略并说明。
- `workflow`（GDD 的有效档位，`system_overrides` 行覆盖项目值）：`full` = 8 节全部必验，任一缺失阻断批准；`standard` = 5 个必需节（Overview、Detailed Rules、Edge Cases、Dependencies、Acceptance Criteria）缺失即阻断，Formulas 仅当系统定义数值规则（rates/curves/thresholds/costs——Category 只是提示不是判据）时必需，Player Fantasy 与 Tuning Knobs 仅建议（除非 `workflow_overrides` 要求）；`minimal` = 不期望有 GDD，存在则对 5 个标准节做建议性校验。

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 载入与新鲜度
R1. 必须先做新鲜度检查：运行 `bash .claude/scripts/review-receipts.sh check "design/gdd/reviews/[doc-name]-review-log.md" "[target-doc-path]" "design/registry/entities.yaml" ".claude/skills/design-review/SKILL.md"`——registry 纳入检查因为本审查咨询其交叉文档事实（GDD 未变而 registry 变了结论可能不同），本技能文件纳入因为技能变了审查方式不同；检查同时比对日志盖章的其它所有文件（相关 GDD、concept/brief、narrative 文件），对已不存在的打印 `GONE:`。（Phase 1）
R2. 日志最新条目的 `Review mode:` 行决定覆盖关系：仅当其模式 ≥ 当前解析模式（`full` > `lean` > `solo`）且 workflow 档 ≥ 当前（`full` > `standard` > `minimal`）时该次审查才覆盖本次运行；无此行的旧条目覆盖无效。（Phase 1）
R3. 全部 `UNCHANGED` 且最新条目带裁决时必须呈现："本文档与 [date] 的上次审查逐字节相同（[mode] 审查，裁决：[verdict]）"。APPROVED 且覆盖本次运行时按 automation 模式询问 `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway`；APPROVED 但本次要求更深时反向询问（推荐重审）；NEEDS REVISION / MAJOR REVISION NEEDED 时直说文档自上次未通过后未变、旧发现仍然成立——下一步是修订文档而非重审，并提供展示旧发现。（Phase 1）
R4. 仅 registry 或其它盖章交叉文件 `CHANGED`/`NEW`/`GONE` 而目标文档与本技能文件 `UNCHANGED` 时：旧裁决仍有效，但须对变更文件重核交叉文档事实并重新给出裁决；出现冲突或旧审查不覆盖本次运行时升级为完整重审。（Phase 1）
R5. 目标文档或本技能文件 `CHANGED`/`NEW`，或 `RECEIPT: NONE` 时必须执行下方完整审查，禁止提供跳过未变节阅读/分析的"部分或增量重审"——节级重审会漏掉完整审查能发现的缺陷且几乎不省成本。（Phase 1）
R6. 交叉文档事实优先读 registry 而非兄弟 GDD：registry 存在且列有本系统条目时用两条 Grep（`source: design/gdd/[system].md` 带 `-A 6` 查本系统拥有的条目；`design/gdd/[system].md` 带 `-B 8` 查引用本系统的条目——`referenced_by:` 是块序列，必须按路径配 `-B 8` 才能看到所有者条目）。registry 不存在或无本系统条目（空桩为默认，直到 `/design-system` 填充）时回退读目标文档 Dependencies 节点名的相关 GDD，禁止 glob 全读 `design/gdd/`。（Phase 1）
R7. 依赖图验证：对 Dependencies 节列出的每个系统用 Glob 检查其 GDD 文件是否存在于 `design/gdd/`，不存在的标记为断裂引用（下游作者会踩到）。（Phase 1）
R8. Lore/narrative 对齐：`design/gdd/game-concept.md`（或 `rigor: minimal` 时的 `design/game-brief.md`）或 `design/narrative/` 任一文件存在时必须读，记录与既有世界观规则、基调、设计支柱矛盾的机制选择，并把该上下文传给 Phase 3b 的 `game-designer`。（Phase 1）
R9. 先前审查检查：review log 存在时读最新条目，记录裁决与阻断项；本次即重审，须追踪先前项是否已解决。（Phase 1）

### Phase 2 — 完整性
R10. 两步走：先用 `bash .claude/scripts/gdd-structure-check.sh [target-doc-path]` 确定性收集节的 `PRESENT:`/`ABSENT:`/`PLACEHOLDER:`（仅 `[To be designed]` 的占位节按缺失处理）；脚本只报存在性不做 REQUIRED/ADVISORY 判断——那是 Step 2b 的工作；脚本已接受 `## Detailed Design` 满足 Detailed Rules 要求，不要重复标记缺失。（Phase 2）
R11. 按解析后的 workflow 档逐节标 REQUIRED 或 ADVISORY：缺失 REQUIRED 阻断批准；缺失 ADVISORY 作为建议呈现但不阻断。8 节清单：Overview（全档必需）、Player Fantasy（full 必需 / standard 建议）、Detailed Rules（full+standard 必需，`## Detailed Design` 标题同样满足）、Formulas（full 必需；standard 下系统定义数值规则即 rates/curves/thresholds/costs/damage/drop weights 时必需否则建议——不得仅凭 Category 记号放行）、Edge Cases（full+standard 必需）、Dependencies（full+standard 必需）、Tuning Knobs（full 必需；standard 建议除非 `workflow_overrides.tuning_knobs`）、Acceptance Criteria（full+standard 必需）。PRESENT 的节仍可能是空标题——对裁决所系的节必须抽查。（Phase 2）

### Phase 3 — 一致性与可实现性
R12. 内部一致性：公式产出值须与描述行为吻合；边缘情形不得与主规则矛盾；依赖须双向（对方系统是否知道本系统）。可实现性：规则须精确到程序员无需猜测；标记"含糊带过"节；性能影响须被考虑；每条验收标准独立可测——逐条引用不可测项（"feels balanced"、"works correctly"、"performs well" 不是标准）并给出可测改写；`lean`/`solo` 模式下无专家运行，主审查的这项检查是唯一一道。（Phase 3）
R13. registry 值全文档核对：列出 registry 全部条目名（`grep -E '^  - name:' design/registry/entities.yaml`），对全文一次不区分大小写搜索所有条目名及其数值键，`_` 写成 `[_ ]` 使 `goblin_scout` 也匹配 "Goblin scouts"；核对它打印的每一行（无论位于哪一节）——任何一行给出不同值，即使只针对一个房间、变体、等级或例外，都与所有者 GDD 矛盾：连同行号、本文档值、registry 值记入 Required Before Implementation。无 registry 条目时对相关 GDD 定义的实体与值做同样搜索。（Phase 3）

### Phase 3b — 对抗性专家审查（仅 full 模式）
R14. 本阶段在 full 模式下强制执行（lean/solo 跳过）；spawn 任何代理前必须打印提示："Full review: spawning specialist agents in parallel. This typically takes 8–15 minutes. Use `--review lean` for faster single-session analysis."。（Phase 3b）
R15. 用 Phase 1 已加载的 GDD（禁止重读）识别全部涉及域并按域表并行 spawn：成本/价格/掉落/经济→`economy-designer`；战斗数值/伤害/血量/DPS→`game-designer`+`systems-designer`；AI 行为/寻路/索敌→`ai-programmer`；关卡布局/刷怪/波次→`level-designer`；进度/XP/解锁→`economy-designer`+`game-designer`；UI/HUD/菜单→`ux-designer`+`ui-programmer`；对话/任务/剧情→`narrative-director`；动画/手感/时序→`gameplay-programmer`；多人/同步/复制→`network-programmer`；音频提示/音乐触发→`audio-director`；性能/绘制调用/内存→`performance-analyst`；引擎特定模式→主引擎专家（`engine.name` 派生 Godot→`godot-specialist`、Unity→`unity-specialist`、Unreal→`unreal-specialist`，回退 `technical-preferences.md` 的 Primary 行）；验收标准/测试覆盖→`qa-lead`；数据模式/资源结构→`systems-designer`；任何玩法系统→`game-designer`（恒派）。所有 Agent 调用必须同时发出，禁止逐个 spawn。（Phase 3b Step 1-2）
R16. 必须发出真实 `Agent` 调用（独立上下文窗口的子会话）——那不是任务跟踪；禁止在主会话内模拟专家视角或自行推演各域观点；模拟审查不是专家审查。（Phase 3b Step 2）
R17. 对每个专家用对抗式提示："你的任务不是认可这份设计——你的任务是找问题……欢迎与主审查分歧"，并指示按节读 GDD（Grep `^#` 找标题 + Read offset/limit）。附加专属指令：`game-designer` 锚定 GDD Section B 的 Player Fantasy（设计是否真的交付该感受，标记为可实现性服务却损害既定感受的规则）；`systems-designer` 对每条公式代入边界值（最小/最大合理输入）报告退化输出（负值、除零、无穷、极端处无意义结果）；`qa-lead` 逐条审验收标准、标记不可测项并给出具体改写。（Phase 3b Step 2）
R18. 全部专家回应后 spawn `creative-director` 作资深审查者（提供 GDD、全部专家发现、分歧），其综合即 Phase 4 的最终裁决——用本技能的裁决词，绝不用 READY/REJECT 等 director-gate 词。（Phase 3b Step 3）
R19. 专家之间或与 creative-director 分歧时禁止默默选边，必须在 Phase 4 显式呈现供用户裁决；每个发现标注来源（`[game-designer]`、`[economy-designer]`、`[creative-director]` 等）。（Phase 3b Step 4）

### Phase 4 — 输出
R20. 报告必须含：标题、Specialists consulted、Re-review 行；Completeness `X/N`（N 不是硬编码 8——按 `modes.workflow`：full=8、standard=5（+数值系统时的 Formulas）、minimal=0；ADVISORY 缺口单独标 "advisory at `standard`"，不得列为缺失）；Dependency Graph（每个依赖及其文件存在性 ✓/✗）；Registry Values（搜索词、打印行数、逐项冲突及行号，无可搜时明说 "No registry entries or related-GDD values: values not cross-checked"）；Required Before Implementation（仅阻断项，带来源标签）；Recommended Revisions；Specialist Disagreements（两面并呈）；Nice-to-Have；Senior Verdict `[creative-director]`；Scope Signal。（Phase 4）
R21. Scope Signal 按依赖数、公式数、触及系统数、是否需要新 ADR 估：`S`（单系统、无公式、无新 ADR、<3 依赖）/`M`（中等、1-2 公式、3-6 依赖）/`L`（多系统集成、3+ 公式、可能需新 ADR）/`XL`（横切关注、5+ 依赖、多个新 ADR 可能）；必须标注 "Rough scope signal: M (producer should verify before sprint planning)" 式说明。（Phase 4）

### Phase 5 — 收尾
R22. 所有收尾交互必须用 `AskUserQuestion`，禁止纯文本。APPROVED 首过（无修订）直接走 systems-index 小部件、review-log 小部件、最终关闭小部件，不单独显示"下一步"小部件；NOT ASSESSED 时无物可审——不提供追踪更新，直接最终关闭小部件并领衔指出产出缺失输入的技能（如不存在的 GDD 用 `/design-system [system]`）。（Phase 5）
R23. NEEDS REVISION / MAJOR REVISION NEEDED 时从发现构建选项：`[A] Revise the GDD now — address blocking items together` / `[B] Stop here — revise in a separate session` / `[C] Accept as-is and move on`——仅当每个发现都是 advisory（Required Before Implementation 为空）时才含 [C]；有任何阻断项时只提供 [A] 和 [B]。（Phase 5）
R24. 选 [A] 时：处理全部阻断项，只有 GDD 与既有文档无法自行解决的设计决策才提问，且把全部设计决策问题合并为单个多标签 `AskUserQuestion` 后才开始编辑——禁止修订中途逐个打断。完成后展示汇总表（阻断项→已施修复）并给修订后收尾小部件（含上下文用量注记：>50% 时附 "Recommended: /clear before re-review — this session has used X% context. A full re-review runs 5 agents and needs clean context."；选项 `[A] Re-review in a new session` / `[B] Accept revisions for now — mark In Review` / `[C] Move to next system` / `[D] Stop here`）。collaborative/guided 模式绝不以纯文本结束修订流；autonomous 模式总结结果并 `log_decision`。（Phase 5）
R25. APPROVED 时用单个 `multiSelect: true` 的 `AskUserQuestion` 批量两项追踪更新（systems-index 标 `Approved`；追加 review log 条目）；修订裁决时用两个独立小部件：先问可否把 systems-index 标为 `Needs Revision`（修订未完成期间的精确字符串）或 `In Review`（已应用待重审）——该提示绝不提供 `Approved`（修订裁决不是批准）；再问可否追加 review log。（Phase 5）
R26. review log 条目格式：`## Review — [YYYY-MM-DD] — Verdict: [...]`、`Review mode: [full/lean/solo] · Workflow: [full/standard/minimal]`、`Scope signal: [S/M/L/XL]`、`Specialists: [list]`、`Blocking items: [count] | Recommended: [count]`、`Summary`（creative-director 裁决的 2-3 句）、`Prior verdict resolved: [Yes/No/First review]`、`Findings:`（每发现一行、按所在节命名，`[BLOCKING]`/`[RECOMMENDED]` 前缀，无发现写 `- none`——这是给人读的修订史），最后是 `review-receipts.sh hash` 收据行：盖章本次审查读过交叉文档事实的每个文件（目标文档、registry、本技能文件、读过的相关 GDD、game-concept.md 或 game-brief.md、design/narrative/ 文件；不存在的文件打印 `not stamped, no such file` 并略去）。hash 行无论裁决如何都必须始终包含——未变文档上次 FAILED 正是跳过冗余重审省钱最多的场景（旧发现逐字成立）。（Phase 5）
R27. 最终关闭小部件（全部文件写完后始终显示）：先读 `design/gdd/systems-index.md` 找其它 Status 为 In Review 或 Needs Revision 的系统（按节读），统计 `design/gdd/` 的 `.md` 文件数（排除 game-concept.md、systems-index.md）判断 `/review-all-gdds` 是否值得提供（≥2 份 GDD），找设计顺序中下一个 Not Started 系统。动态构建选项——只含真正可用的：审查另一待审 GDD / `Run /consistency-check`（存在 ≥1 份其它 GDD 时恒含）/ `Run /review-all-gdds`（≥2 份 GDD 时）/ `Run /design-system [next-system]`（恒含，写实际系统名）/ `Stop here`；只为入选项编号字母，把最能推进管线的标 `(recommended)`。collaborative/guided 模式文件写后绝不以纯文本结束；autonomous 打印下一步并 `log_decision`。（Phase 5）

## 4. 门禁与裁决
- **裁决词**：`APPROVED` / `NEEDS REVISION` / `MAJOR REVISION NEEDED` / `NOT ASSESSED`（本技能自带裁决体系，非 director-gate 词）。
- **NOT ASSESSED 语义**：审查无法实际执行时使用——目标文档缺失、不可读、待审节为空，或其依赖的文档缺失以致标准无法应用；必须指出缺了什么、哪个技能产出它。`APPROVED` 是危险缺省值：找不到输入的审查没有批准任何东西，而该裁决在下游被当作签核消费。
- **裁决排序（聚合时）**：`NOT ASSESSED` 高于 `APPROVED`（跳过了检查的审查没有批准），但不高于两个修订裁决（已知问题比未知问题更可行动）。
- **覆盖规则**：旧审查仅在 mode ≥ 当前（full>lean>solo）且 workflow ≥ 当前（full>standard>minimal）时覆盖本次运行。
- **阻断规则**：缺失 REQUIRED 节阻断批准；ADVISORY 缺失永不阻断。

## 5. 移植建议
- **可直接移植**：R1-R5（收据式新鲜度检查与"覆盖关系"）、R6/R13（registry 优先 + 全文档值核对）、R12（不可测验收标准逐条点名改写）、R16/R19（真子会话审查 + 分歧并呈）、R22-R27（小部件化收尾与追踪记录）、以及 NOT ASSESSED 裁决哲学。
- **需替换概念**：GDD → 技术设计文档 / PRD / API 规格文档；art bible / game-concept → 品牌规范 / 产品愿景文档；registry（entities.yaml）→ 跨文档实体事实登记表（接口注册表、数据字典）；游戏域专家表 → 按领域替换（安全、数据、前端、运维……）；`design/gdd/` 目录 → 各项目的文档目录。
- **改写示例**：
  - R5 → "设计文档或审查规则自上次审查后发生变更时，必须执行完整重审。禁止提供跳过未变章节的部分/增量重审——节级重审会漏掉完整审查能发现的缺陷，且几乎不节省成本。"
  - R12 → "每条验收标准必须独立可测。逐条引用不可测表述（'感觉平衡'、'工作正常'、'性能良好'不是标准）并附可测改写；无专家评审运行时，此项主审查检查是唯一一道。"

## 6. 关联文档
- 上游：`/design-system`（产出 GDD 与 registry 条目）、`/map-systems`（产出 systems-index）。
- 下游：`/consistency-check`（跨文档一致性，收尾恒推荐）、`/review-all-gdds`（≥2 份 GDD 时的整体审查）、`/design-system`（下一系统）。
- 引用：`.claude/docs/director-gates.md`、`.claude/docs/director-gates/[gate-id].md`、`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/scripts/review-receipts.sh`、`.claude/scripts/gdd-structure-check.sh`。
