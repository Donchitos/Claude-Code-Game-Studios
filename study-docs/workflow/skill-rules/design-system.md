# design-system — 逐节撰写系统 GDD（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/design-system/SKILL.md)（含 references/1~5） ｜ 阶段：Phase 2 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/design-system <system-name> [--review full|lean|solo]`（另有 `retrofit design/gdd/[system].md` 补洞模式）
- **一句话职责**：为一个系统逐节协作撰写 GDD——先建骨架文件，再对每个必需节走"上下文→问题→选项→决定→草案→批准→写盘"循环，复杂节强制并行派生专家智能体提供领域输入
- **触发前置**：`design/gdd/game-concept.md` 与 `design/gdd/systems-index.md` 存在（`minimal` 档读 brief 替代）；主 SKILL.md 是路由器，六个阶段的步骤分别在 `references/1`~`5` 中，进入每阶段时必须现读对应文件（会话被压缩/恢复后也要重读）

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, workflow, docs.density, system_overrides` | `--review` 覆盖 `review_mode`；`system_overrides` 行可单独提升本系统的 workflow 档 |
| 读取 | game-concept / systems-index / `design/registry/entities.yaml`（`registry.sh slice`）/ `docs/consistency-failures.md` | 概念、索引、已锁定的跨系统事实（known facts）、历史失败模式 |
| 读取 | 依赖 GDD 的**四节**（Dependencies/Formulas/Edge Cases/Tuning Knobs） | 只读携带跨系统契约的节，非全文；注册表优先、节 grep 补缺 |
| 读取 | `project.yaml` 的 `engine.name`/`engine.version`（各自独立解析，缺失回退 technical-preferences.md）、`docs/engine-reference/[engine]/VERSION.md`、`modules/[domain].md`、`breaking-changes.md`、ADR 的 `**Domain**` 字段 | 技术可行性预检 |
| 产出 | `design/gdd/[system-name].md`（先骨架后逐节填充）、`design/registry/entities.yaml`、systems-index 行更新、`production/session-state/active.md` | 系统名规范化为 kebab-case 文件名 |
| 派生智能体 | 见 §4 路由表（`systems-designer`、`game-designer`、`economy-designer`、`creative-director`、`art-director`、`qa-lead` 等） | 主会话编排；**agents 不直接写文件——主会话拥有全部文件写** |

**docs.density 档位**：`terse`（默认，via `rigor: minimal`）= 要点列表、每节 2-5 行、跳过理由与前言；`balanced` = 带轻理由的段落；`thorough` = 完整散文含理由、示例、备选。**强制结构（Formulas 变量表、Given-When-Then 验收标准）在任何密度下都是正确性要求——terse 只修剪周边散文，绝不裁剪必需结构本身。**

## 3. 核心规则（逐条编号 R1、R2……）

**§1 参数解析与档位（references/1）**
R1. 系统名或 retrofit 路径**必需**：缺省时若索引存在，读索引选最高优先级 "Not Started" 系统并问"The next system in your design order is **[system]** ([priority] | [layer]). Start designing it?"（Yes / Pick a different / Stop）；无索引则报用法错误并指路 `/map-systems`。
R2. **retrofit 模式**（参数以 `retrofit` 开头或是 `design/gdd/` 下已存在文件）：读现有 GDD，识别 8 个可能节（Overview、Player Fantasy、Detailed Design/Rules、Formulas、Edge Cases、Dependencies、Tuning Knobs、Acceptance Criteria）哪些已写/缺失/仅占位符；**缺失是否算 gap 取决于有效档位**——`standard` 下 Player Fantasy 和 Tuning Knobs 是按设计跳过的，把全部 8 节当必需会每个 standard 项目误报两个 gap。呈现 ✓/✗ 摘要并问"Shall I fill the [N] missing sections? I will not modify any existing content."；同意后跳过骨架创建与已完成节；**绝不覆盖已有节内容**，只用 Edit 替换 `[To be designed]` 占位符或空节体。retrofit 不受档位影响，缺什么补什么。
R3. **档位决定必需节集**（`system_overrides` 行优先于项目值）。`## Summary` 在**每一档**都必需且不属于 8 节——各档列表一律读作"Summary, plus:"。`full`=全 8 节。`standard`=Overview、Detailed Design、Edge Cases、Dependencies、Acceptance Criteria 五节；**Formulas 条件性**——系统定义数值规则（rates、curves、thresholds、costs、damage、drop weights 或任何平衡调整会动的值）即必需，`Category` 只是提示不是判据（`Gameplay`/`Economy`/`Progression` 几乎必中，`Core`/`UI`/`Persistence` 定义数值规则也算；Detailed Design 写出非引擎常量的量即触发）；Player Fantasy 与 Tuning Knobs 跳过，除非 `workflow_overrides` 强制（`tuning_knobs: true`）。`minimal`=GDD 非必需；自愿撰写时**恰好五节**（条件 Formulas 规则不再适用），并告知用户 GDD 在此档可选。**禁止按 category token 门控 Formulas**——模板九类是 `Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`，combat 和 AI 只是 `Gameplay` 下的示例系统，按 "combat/economy/progression/AI" 匹配会让最需要公式的系统漏掉。

**§2 收集上下文（references/2）**
R4. 问用户任何问题前先读完所有相关上下文（这是本技能相对 ad-hoc 设计的核心优势——带着信息到场）。GDD/ADR 一律按节读。
R5. `minimal` 档（本技能自愿运行时）：读 `design/game-brief.md` 替代概念、跳过索引读取——**该分支键于项目档而非系统有效档**（minimal 项目上的 overridden 系统也要读 brief）；随后从 brief 一次性派生 `Category`（九选一）、`Layer`（Foundation 若被依赖否则 Feature）、`Priority`（MVP 若 build order 列有否则 Post-MVP），全程视作索引答案并在 Quick reference 标注 *inferred*；**禁止自己写 systems-index**（`/map-systems` 拥有该文件）。
R6. 常规必读：game-concept（缺则报错指路 `/brainstorm`）、systems-index（缺则报错指路 `/map-systems`）、目标系统行（不在索引则警告并问：加入还是 off-index 设计）；`entities.yaml` 存在时用 `registry.sh slice` 取本系统拥有/引用的条目作 **known facts**（其它 GDD 已确立、本 GDD 不得矛盾的值）；`docs/consistency-failures.md` 存在时提取 Domain 匹配的条目作"Past failure patterns"呈现。
R7. 依赖读取：从索引识别上游（须尊重的决策）与下游（须满足的期望）；每个已存在的依赖 GDD **只读四节**（Dependencies/Formulas/Edge Cases/Tuning Knobs，grep 截取）；**禁止 glob-and-read 全部 GDD 找"主题相关"系统**——注册表就是为替代该读取而存在。
R8. 呈现上下文摘要（Priority/Layer、上下游及是否有 GDD、须尊重的决策、pillar 对齐、known facts——**这些值已锁定，本 GDD 需要不同值必须先浮出冲突，禁止默默改数**）；上游未设计时警告（做假设 / 先设计它 / 定义临时契约）。registry 无相关条目则省略该小节。
R9. 技术可行性预检：按 `Category` 映射引擎域（Gameplay→Physics/Navigation/Scripting；Core→Core/Input；UI→UI；Audio→Audio；Narrative/Progression/Economy→Scripting；Persistence/Meta→Core；Animation/Rendering/Networking 无自有类别，命名实际读取的域）；`modules/[domain].md` **不存在时必须按名声明**（"no engine reference for `[domain]`…feasibility not checked against the pinned engine"）并带入 §5——静默跳过与"查过没问题"不可区分（Godot 参考无 scripting.md/core.md，多数非 Gameplay 系统每次都命中此分支：每次都要报）。呈现可行性简报（已验证能力/将塑形设计的约束/知识缺口标 HIGH/MEDIUM 风险/相关 ADR）后，问"Any constraints to add…?"再问"Ready to start designing [system]?"。

**§3 骨架（references/3）**
R10. 用户确认后**立即**创建含空节头的 GDD 骨架（增量写盘要有目标）。**只脚手架档位要求的节**：`standard` 省略 Player Fantasy 与 Tuning Knobs（及无数值规则的 Formulas）；`full` 全 8。**只有 §1 命名省略的节才跳过**——不留空占位符；模板其余各节（Visual/Audio、Game Feel、UI Requirements、Cross-References、Open Questions）都带 `[To be designed]` 脚手架；§4 不能填充 §3 没创建的节。先问"May I create the skeleton file at `design/gdd/[system].md`?"——拒绝则以 `Verdict: BLOCKED — skeleton creation declined…` 停止，不进 Section A。写后更新 `active.md`（Glob 查存在；**绝不 Edit 可能不存在的文件**，缺失用 Write 创建）。

**§4 逐节设计（references/4）**
R11. 只走档位要求的节：`standard` 走 A(Overview)/C(Detailed Design)/E(Edge Cases)/F(Dependencies)/H(Acceptance Criteria)+条件 D(Formulas)，跳过 B(Player Fantasy) 与 G(Tuning Knobs)（除非 override 强制 G）；`full` 走全部 A-H；`minimal` 自愿时走 standard 集。每节循环：Context → Questions → Options → Decision → Draft → Approval → Write。
R12. **批准协议**：`collaborative` 下草案与批准 widget **必须在同一响应中出现**——草案后立即用 AskUserQuestion 问"Approve the [Section Name] section?"（`[A] Approve — write it to file` / `[B] Make changes` / `[C] Start over`），**绝不用纯文本、绝不跳过**；`guided` 下草案后立即写盘附一行摘要、跳过每节 widget；`autonomous` 下直接写盘并 `log_decision`（Category: minor）。
R13. **写盘模式**：用 Edit 替换占位符时 `old_string` **必须包含节标题**确保唯一——**绝不单独匹配 `[To be designed]`**（多节共用同一占位符，Edit 需唯一匹配）。每节写盘后更新 `active.md` 记录完成节名。
R14. **注册表冲突检查**（仅 C、D 两节）：写后扫描节内容中命中注册表的实体/物品/公式/数值常量；值不一致必须**立即浮出**（"Registry conflict: [name] is registered in [source GDD] as [registry_value]. This section just wrote [new_value]. Which is correct?"），禁止默默继续；新条目标记为注册候选留给 Phase 5。
R15. **每个被跳过的专家派生都要宣布**：solo 或 lean 跳过某节的专家时，必须打印该节注记及运行模式（如 "`creative-director` not consulted — Lean mode. Review manually before production."）——无论哪种模式跳过，无专家起草的节都必须在输出中说明。
R16. Section A(Overview)：一段陌生人能懂；先按 `Category` 派生各 tab 推荐项（player-facing 类→Both、internal 类→技术框架、mixed→Both；**Layer 与 Category 冲突时 Category 赢**）并标 `(Recommended)`，再问三 tab 框架问题（Framing / ADR ref / Fantasy）；`collaborative` 下**禁止自答自起草**——widget 必须出现。问题保持行为级（做什么而非怎么建）：实现类问题记"→ becomes an ADR"后继续——GDD 描述行为，ADR 描述技术方案。
R17. Section B(Player Fantasy)：情感目标；起草前**必须** spawn `creative-director`（提供系统名、框架答案、pillars、参考游戏、概念摘要，索要 2-3 个候选框架）并与草案一起呈现给用户；**禁止未咨询 creative-director 就起草 B**。须与 pillars 对齐并引用 pillar 原文。
R18. Section C(Detailed Design)：程序员无疑问可实现的规范；子节=Core Rules（编号规则/bullet 属性）、States and Transitions（全状态全转换表）、Interactions（每个上下游依赖的数据流入流出与接口归属）。起草前**必须**按 §6 路由表**并行 spawn** Primary + Supporting agents（提供系统名、概念摘要、pillar 集、依赖 GDD 摘录、正撰写的节），收集各方发现后才起草，agent 分歧经 AskUserQuestion 呈现用户裁决；**禁止未咨询适当专家就起草 C**。每个交互须与依赖 GDD 核对，值或公式不符即标记冲突。
R19. Section D(Formulas)：每条公式以**固定结构**开始——公式名、表达式、**Variables 表**（`Variable | Type | Range | Source | Description`，列名与指南一致**禁止改名**——`Source` 列承载"游戏值必须数据驱动、绝不硬编码"的编码标准：`data file` 即 tuning knob、`constant` 即显式例外）、**Output Range**、**Example**（真实数字演算）；**禁止写 `[Formula TBD]` 或无变量表的散文公式**。起草前**必须** spawn `systems-designer`（给 C 的规则+调优目标+平衡上下文），经济/成本系统再加 `economy-designer` 验证成本曲线与比率；**禁止无专家输入发明公式值或平衡数字**。
R20. Section E(Edge Cases)：格式 `**If [condition]**: [exact outcome].`；**禁止模糊条目**（如 "handle appropriately"）——无解决方案的边界情况是开放问题不是规范。定稿前**必须** spawn `systems-designer`（给完成的 C、D 节）找遗漏；叙事系统加 `narrative-director`。
R21. Section F(Dependencies)：呈现索引已知依赖并问漏项、每依赖的数据接口、硬依赖（没它不能跑）vs 软依赖（没它也能跑）；**必须双向一致**——本系统列 "depends on Combat" 则 Combat GDD 应列反向，单向依赖标记修正。
R22. Section G(Tuning Knobs)：每设计者可调值含安全范围与极端行为；solo 下自己从 D 变量表派生（注意：此节委托的也是 `systems-designer`，与 D 的 solo 跳过守卫一致）；依赖 GDD 已有的 knob 引用即可，**禁止造重复 knob**——指向真相源。
R23. Section H(Acceptance Criteria)：每条 Given-When-Then；至少 **C 每条核心规则一条、D 每条公式一条**；禁止"系统按设计工作"这类空话——每条须 QA 不读 GDD 即可独立验证。定稿前**必须** spawn `qa-lead`（给完成的 C、D、E 节）验证可测试性与覆盖。**若 D 被跳过但 C 写出了量**（rate/threshold/cost/curve）——这是 §1 判据事后命中：停下、告知 Formulas 必需、先补 D 再定稿（该升级仅 `standard` 档适用；`minimal` 下 C 的量属预期，内联写值即可；`full` 下 D 无条件必需不会发生）。
R24. 可选五节（Visual/Audio、Game Feel、UI Requirements、Cross-References、Open Questions）不受档位管、由本块独立管：**Visual/Audio 对 `Gameplay`/`UI`/`Narrative`/`Audio` 四类 REQUIRED**（不得提供跳过）且必须先 spawn `art-director`；**Game Feel 对 `Gameplay`/`UI` REQUIRED**；**Cross-References 只要 Dependencies 命名了其它 GDD 即 REQUIRED**（无引用时写 "None — this system references no other GDD" 而非留占位符）。提供可选节的问题里**只列仍未被强制者**（提供跳过刚被强制的节 = 强制节被跳过的成因），且**禁止陈述固定节数**（"8 sections complete" 在 full 以下每次都错）；`minimal` 下五节全降为可选。Visual/Audio 写实后输出 Asset Spec 提示（跑 `/asset-spec`）；UI Requirements 写实后立即输出 **UX Flag**（Pre-Production 阶段先跑 `/ux-design`，UI story 引用 `design/ux/[screen].md` 而非 GDD）。

**§5 后设计验证（references/5）**
R25. **5-pre 写 Summary**：全部节完成后写 `## Summary`（2-3 句）与 Quick reference（Layer/Priority 来自索引、Key deps 来自刚写的 Dependencies）——每档无条件执行；`/create-epics`、`/architecture-review`、`/review-all-gdds` 都靠 grep 它决定是否全读。
R26. **5a 自检**：从**文件**（非对话记忆）读回完整 GDD 按标题分段（整文件 Read 超 40 KB 会被拒）；验证 Summary 已填、档位要求的每节有真实内容（**禁止按固定 8 节校验**）、公式引用已定义变量、边界情况有解、依赖带接口、验收标准可测试。
R27. **5b 更新注册表**：扫描跨系统事实（命名实体/物品/公式/多处引用的常量）。**先查注册表存在**：缺失则问是否创建（拒绝则跳过并声明注册表未写——不把跳过当干净通过）；**空注册表须防注释示例误判**（模板注释带 `base_inventory_slots: 20` 等示例值，只匹配 live `entities:`/`items:`/`formulas:`/`constants:` 键下条目）；呈现 NEW/ALREADY REGISTERED 摘要并问"May I update…?"。写后跑 `registry.sh validate` 并修复本次写入引入的每一行，其他条目的问题只向用户点名；**绝不擅自修改既有 value 字段**——先浮出为冲突。
R28. **5c 设计审查交接**：呈现完成摘要后引导用户**开新会话**跑 `/design-review design/gdd/[system].md`；**绝不在本会话内运行或提议内联运行 `/design-review`**——审查者必须独立于创作上下文，同会话运行会继承全部设计历史、使独立批判不可能。
R29. **5d 更新索引**：先查索引存在（minimal 下可能缺失：一行说明后跳过，**禁止自己创建**——`/map-systems` 拥有该文件）。Status 更新规则：design-review APPROVED→"Approved"；NEEDS REVISION/MAJOR REVISION NEEDED→"Needs Revision"（**精确字符串**）；跳过审查→"Designed"；用户自己先审→"Designed"。问"May I update the systems index…?"后更新目标行、Design Doc 链接与 Progress Tracker。
R30. **5e/5f**：`active.md` 写 Task/Status/File/**按名列实际撰写的节（绝不写固定计数 "All 8"）**/Next；最后问"What's next?"（`/consistency-check`（推荐）/ Design next system / Fix review findings / Stop / `/gate-check`）。

**§7 恢复与上下文**
R31. 会话中断（压缩/崩溃/新开）时：读 `active.md`（记录当前系统与完成节）→ 读 GDD（真实内容=完成、`[To be designed]`=待办，按节读）→ **从下一个未完成节恢复，不重议已完成节**——这正是逐节写盘的意义：每个已批准节在任何中断后都存活。
R32. 长运行技能：每节写盘后检查上下文是否 **≥70%**，是则附加提示（进度已保存，新会话重跑 `/design-system [system]` 会检测完成节并续写）。
R33. 协作铁律：**绝不**自动生成完整 GDD 当既成事实呈现；**绝不**未批准就写节；**绝不**未标记冲突就与已批准 GDD 矛盾；**始终**标明决策来源（依赖 GDD、pillars、用户选择）。

## 4. 门禁与裁决（如适用）

**系统类型路由表（§6，派生专家用）**——两步解析：先取系统 `Category`，再在类内选匹配系统实际所作的行（**行比九类更细是刻意的**：战斗专家≠寻路专家，都是 Gameplay；每类至少一行无遗漏；两行皆符则 spawn 两行 Primary agents 的**联合**并说明原因）：

| Category | 可选行 |
|---|---|
| `Gameplay` | Combat/damage/health · AI/pathfinding/behavior · Animation/character movement · Character systems · Camera/input/controls |
| `Core` | Foundation/Infrastructure · Camera/input/controls |
| `Persistence` | Foundation/Infrastructure |
| `Economy` | Economy/loot/crafting |
| `Progression` | Progression/XP/skills |
| `UI` | UI systems · Visual effects（HUD 邻接 VFX 时） |
| `Audio` | Audio systems |
| `Narrative` | Dialogue/quests/lore |
| `Meta` | Foundation/Infrastructure（分析、教程管道）· UI systems（无障碍选项屏） |

| 系统类型 | Primary Agent | Supporting Agent(s) |
|---|---|---|
| Foundation/Infrastructure（事件总线、存读档、场景、服务定位） | `systems-designer` | `gameplay-programmer`(可行性)、`engine-programmer`(引擎集成) |
| 战斗/伤害/生命 | `game-designer` | `systems-designer`(公式)、`ai-programmer`(敌 AI)、`art-director`(命中反馈) |
| 经济/掉落/制作 | `economy-designer` | `systems-designer`(曲线)、`game-designer`(循环) |
| 进度/XP/技能 | `game-designer` | `systems-designer`(曲线)、`economy-designer`(回收) |
| 对话/任务/世界观 | `game-designer` | `narrative-director`、`writer`、`art-director` |
| UI 系统（HUD、菜单） | `game-designer` | `ux-designer`、`ui-programmer`、`art-director`、`technical-artist` |
| 音频系统 | `game-designer` | `audio-director`、`sound-designer` |
| AI/寻路/行为 | `game-designer` | `ai-programmer`、`systems-designer`(评分) |
| 关卡/世界系统 | `game-designer` | `level-designer`、`world-builder` |
| 相机/输入/操控 | `game-designer` | `ux-designer`(手感)、`gameplay-programmer`(可行性) |
| 动画/角色移动 | `game-designer` | `art-director`、`technical-artist`(绑定/混合约束)、`gameplay-programmer` |
| 视觉特效/粒子/着色器 | `game-designer` | `art-director`、`technical-artist`(性能预算)、`systems-designer`(触发/状态集成) |
| 角色系统（属性、原型） | `game-designer` | `art-director`、`narrative-director`(角色弧线)、`systems-designer`(属性公式) |

派生协议：提供系统名、概念摘要、依赖 GDD 摘录、正撰写的节、需要专家输入的问题；agent 只返回分析/提案；主会话经 AskUserQuestion 呈现、用户裁决、主会话写盘。

**review-mode 检查**（每节 spawn 前）：`solo`→跳过并按名注记；`lean`→仅 D、H 两节（HIGH 实施风险）spawn，其余照常跳过；`full`→正常 spawn。

**CD-GDD-ALIGN 门禁**（§5a-bis）：`solo`/`lean` 跳过（非 PHASE-GATE）并注记；`full` 下 spawn `creative-director`（传入完成 GDD 路径、pillars、MDA 目标、Player Fantasy 节或说明本档未写）。REJECT 或 Revise flagged items：每个被标节重走节循环（其专家按该节 review-mode 检查咨询）、经"Approve the [Section Name] section?"再批准后才写盘，随后记 `REVISED [date]`；**NOT ASSESSED 绝不是批准**——命名缺失输入补齐重跑，或记录 NOT ASSESSED。裁决写入 GDD Status 头：`> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`。

## 5. 移植建议
- **可直接移植**：R11-R13（节循环+草案与批准同响应+唯一匹配写盘）、R14（写后即查注册表冲突）、R15（跳过的专家要宣布）、R23（验收标准 GWT+一规则一条）、R26（从文件而非记忆自检）、R28（审查者独立于创作会话）、R31（断点续写）、R33（协作铁律）。
- **需替换概念**：GDD 节 → API/模块规格节；registry（entities.yaml）→ 跨模块常量/契约注册表；`systems-index` 的 Category → 领域域；专家 agents（systems-designer 等）→ 领域专家角色（DBA、安全、UX…）；`/design-review` → 独立评审流程；ADR → 技术决策记录（TDR/ADR 本身通用）。
- **改写示例**：
  - "每个规格节走『上下文→问题→选项→决定→草案→批准→写盘』循环；草案与批准提问必须在同一响应出现；写盘的 old_string 必须含节标题以保证唯一替换。每节批准后立即落盘并更新会话状态文件——已批准节在中断后不得重议。"
  - "涉及数值规则的节必须先并行咨询领域专家（公式专家+领域负责人）再起草；跳过咨询时必须在输出中声明『<专家> 未咨询——<模式>，投产前请人工复核』；未经专家输入禁止发明默认值或平衡数字。"

## 6. 关联文档
- 上游：`/map-systems`（系统索引与设计顺序）、`/brainstorm`（概念）
- 下游：`/design-review`（须新会话）、`/consistency-check`、`/review-all-gdds`、`/asset-spec`、`/ux-design`、`/gate-check technical-setup`
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/director-gates.md`、`.claude/docs/templates/game-design-document.md`、`templates/guidance/game-design-document-guide.md`、`.claude/scripts/registry.sh`、references/1~5
