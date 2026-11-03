# art-bible — 美术圣经/视觉识别规格（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/art-bible/SKILL.md) ｜ 阶段：Phase 1-2 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/art-bible [--review full|lean|solo]`
- **一句话职责**：撰写美术圣经（Art Bible）——9 节视觉识别规格文档，约束后续所有资产生产；每节内容强制由专家智能体起草、逐节批准、逐节写盘，末尾经创意美术总监 AD-ART-BIBLE 门禁签发
- **触发前置**：`design/gdd/game-concept.md` 存在（或 `rigor: minimal` 档的 `design/game-brief.md`）；两者皆无 → 失败并提示 "No game concept found. Run `/brainstorm` first — the art bible is authored after the game concept is approved."。官方定位在 `/map-systems` 之前运行

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, automation, workflow, docs.density` | `--review` 覆盖 `review_mode`；`docs.density` 管各节深度、`workflow` 管哪些节存在 |
| 读取 | game-concept.md（或 brief）：working title、pitch、core fantasy、全部 pillars、**Visual Identity Anchor**（若有，来自 brainstorm Phase 4 的 art-director 产出）、目标平台 | brief 无 pillars/Anchor/平台，用其 pitch、"Who it's for / what they feel" 行与 "Art & audio direction" 行顶替；按节读（Grep `^#` + offset/limit） |
| 读取 | `project.yaml` 的 `performance.*`、`engine.name`（资产标准约束用） | 键缺失/为空（含无对应块）回退 `.claude/docs/technical-preferences.md` |
| 读取 | retrofit 时 `design/art/art-bible.md` 的节标题与占位符（**不读全文**） | 两条 Grep：`^## ` 取标题行号、`\[To be designed\]|\[TBD\]|\[To be written\]|^_?TODO` 取占位符 |
| 产出 | `design/art/art-bible.md`（9 节，模板 `.claude/docs/templates/art-bible.md`）、头部 Sign-Off 状态行；`production/localization/` 无涉及 | 每节批准后立即写盘；节标题保持模板原样 |
| 派生智能体 | `art-director`（每节起草 + AD-ART-BIBLE 门禁）、`ux-designer`（第 7 节）、`technical-artist`（第 8 节） | 主会话编排，绝不自己起草节内容 |

**docs.density 档位**：`terse`（默认，via `rigor: minimal`）= 每节为约束要点列表 + 引用；`balanced` = 解释每个视觉选择的段落（`rigor: standard`）；`thorough` = 完整散文，含风格探索、参考与每个选择的理由。应用于所写的每个节。

**workflow 档位**：`full` = 全 9 节必需；`standard` = 仅当项目存在视觉资产 story 才必需，必需时第 1–4 节为最小集；`workflow_overrides.art_bible_strict: true` 强制全 9 节不受档位影响；`minimal` = 非必需，可自愿运行。

## 3. 核心规则（逐条编号 R1、R2……）

**Phase 0 参数与上下文（Retrofit 模式）**
R1. Retrofit 检测：Glob `design/art/art-bible.md`。已存在则**禁止读全文**——即将只写不完整节，加载完整节就是加载你不会碰的内容。用两条 Grep（`^## ` 标题行号、占位符标记）构建节状态表：节到下一标题有实质间距且无占位符 = **Complete**；区间内落有标记 = **Placeholder**；相邻标题紧邻 = **Empty**；仍歧义的节用 `Read(offset, limit)` 只读**该节**行范围。呈现表："Found existing art bible … [N] sections are complete, [M] need content. I'll work on the incomplete sections only — existing content will not be touched."。**只做 Empty/Placeholder 节，绝不重写已完成节。**
R2. 文件不存在则全新撰写：先问 "May I create `design/art/art-bible.md` from the art bible template?"；第一个获批节从模板建文件，其后每个获批节用 Edit 替换自己的 `[To be designed]` 行，标题保持模板原样（retrofit 模式读的就是这九个 `## N. Name` 标题）。
R3. **一节的批准即为它的写盘授权**（A section's approval names its write）：每节经 AskUserQuestion 批准，批准选项固定为 `[A] Lock this in and write it to design/art/art-bible.md`；无此批准任何节不写盘——fresh 与 retrofit 一视同仁。

**Phase 1 定框**
R4. 撰写前用双 tab widget 问两件事：**Scope**（`Full bible — all 9 sections` / `Visual identity core (sections 1–4 only)` / `Asset standards only (section 8)` / `Resume — fill in missing sections`）与 **References**（自由文本，禁止预设选项）。Scope 选项按已解析的 `workflow` 档标 `(Recommended)` 并说明理由：`full` → Full bible；`standard` → 1–4 节（"Sections 1–4 are what `standard` requires; 5–9 are available if you want them."）；`minimal` → 先说明本档不要求美术圣经，把 1–4 作为"想要就有用"的选项而非默认 9 节；`art_bible_strict: true` → Full bible。**这是本技能最大的成本杠杆**：每节都带一次专家派生，在只要求 4 节的档位写 9 节会让下游谁也不检查的产物多花一倍以上。
R5. 只写所选 scope 内的节（Resume = retrofit 表的 Empty/Placeholder 行）；Phase 2–4 对 scope 外的节整段跳过，跳空后任何 phase 直接略过；Phase 6 必须点名本次未写的每节及原因。game-concept 有 Visual Identity Anchor 则声明用作圣经基础。

**Phase 2 视觉识别地基（第 1–4 节）**
R6. 第 1–4 节定义核心视觉语言，**其余一切节由此流出**；逐节"批准→写盘"后才进下一节。
R7. **派生策略**：第 1 节单独派生（它是地基，用户要在锚方向之间先做选择）；第 2–4 节在**一次** `art-director` 调用中一并索取（同一 agent 同输入——Visual Identity Statement + pillars——mood、shape、colour 相互依赖，美术总监天然一起定义；拆三次会让 agent 在不知道自己刚写的 shape language 的情况下推 color）。**这不是削减专家介入**——每节仍由专家撰写（art-bible 派生是强制的），只是三次派对并作一次；逐节用户批准与立即写盘不变。要求三块**相互一致**（palette 服务 mood targets 与 shape hierarchy）且**分别标注**、各自独立批准写盘；**禁止一次性呈现三节**（batching 在派生里，不在 review 里）。第 3、4 节不再 spawn，直接用该次返回的对应块。
R8. **Section 1 Visual Identity Statement**：一行视觉规则 + 2–3 条支撑原则，每条带一句设计测试（"when X is ambiguous, this principle says choose Y"）；每条原则必须锚定具体 pillar（brief 无 pillars 时锚定 pitch 与 "what they feel" 行）。有 anchor 时先问：直接基于它扩建 / 先修订 / 换新方向重新起。强制 spawn `art-director`（输入概念 pitch、core fantasy、全 pillars、平台、参考、anchor）。批准选项：`[A] Lock this in and write it` / `[B] Revise the one-liner` / `[C] Revise a supporting principle` / `[D] Describe my own direction`。
R9. **Section 2 Mood & Atmosphere**：按本游戏的每个主要状态（探索/战斗/胜利/失败/菜单……按实际适配）定义：primary emotion/mood target、lighting character（时刻、色温、对比度）、3–5 个氛围形容词、energy level（frenetic/measured/contemplative 等）——具体到灯光师可直接开工；"dark and foreboding" 这种程度不够。
R10. **Section 3 Shape Language**：角色剪影哲学（缩略图尺寸下可读性？每原型一个区分特征？）、环境几何（angular/curved/organic/geometric 谁主导、为何）、UI 形状语法（呼应世界还是独立的 HUD 语言）、hero shapes vs supporting shapes（什么抓眼、什么退后）。
R11. **Section 4 Color System**：主色板 5–7 色带角色含义（不是裸 hex，而是每色在本世界的语义）、语义色用词（红/金/蓝/白各传达什么）、每 biome/区域的色温规则（若有分区）、UI 色板（允许与世界色板不同，但须**显式定义分歧**）、色盲安全（哪些语义色需 shape/icon/sound 备份、哪些配色对色盲玩家会失效）。

**Phase 3 生产指南（第 5–8 节）**
R12. 这四节把视觉识别翻成具体生产规则——外包团队**无需额外 briefing** 即可照做。
R13. **Sections 5–6 一次派生**（同 agent 同输入 = sections 1–4，第二次调用只会重发整个视觉识别）：角色设计方向（玩家角色视觉原型、每类角色一眼可辨的区分特征规则——敌人/NPC/盟友怎么区分、表情/姿态风格目标、LOD 哲学——游戏相机距离下保留多少细节）+ 环境设计语言（建筑风格与世界文化/历史的关系、纹理哲学 painted vs. PBR vs. stylized 及为何、prop 密度规则、无文字的环境叙事指南）。要求角色与环境**彼此可读**（角色剪影要在本 brief 自己定义的环境纹理密度上读得出来），返回两块分别标注。先呈现批准写盘第 5 节，再第 6 节；第 6 节不再 spawn。
R14. **Section 7 UI/HUD**：并行 spawn `art-director`（diegetic vs. screen-space HUD、字体方向（个性/字重/字号层级）、图标风格 flat/outlined/illustrated/photorealistic、UI 动画感）与 `ux-designer`（UX 对齐检查：视觉方向是否支持本游戏要求的交互模式，标记美术方向与可读性/无障碍的冲突）。两者冲突（如 art-director 要精致 diegetic UI 而 ux-designer 标记会降低战斗可读性）必须**显式并列两方立场浮出**，**禁止静默解决**，AskUserQuestion 交用户裁决。
R15. **Section 8 Asset Standards**：并行 spawn `art-director`（文件格式偏好、命名约定方向、纹理分辨率档、LOD 期望、导出设置哲学）与 `technical-artist`（引擎硬约束：每资产类别 polycount 预算、纹理内存上限、material slot 数、导入器约束、`performance.*` 预算）。美术偏好与技术约束冲突（如美术要 4K 纹理而移动端预算只允许 2K）必须浮出并三选：理想标准 / 受限标准 / 两者都记录由逐资产裁量——**资产标准里的含糊正是生产成本出生的地方**。
R16. **Section 9 Reference Direction（Phase 4）**：spawn `art-director`（带完成的 1–8 节）编制 3–5 个参考源（游戏/电影/画派/具体艺术家）；每个参考必须指明**确切借鉴什么视觉元素**（一个具体技法、配色选择或构图规则——不是"总体审美"）、**明确回避或偏离什么**（防"想抄 X"的观感）；参考之间应相互补充——两个参考指向完全相同方向即冗余。

**Phase 5 总监签发** — 见 §4。
**Phase 6 收尾**
R17. 先点名本次未写的每节及原因（scope 外 / 已完成），例："Not authored this run: sections 5–9 (outside the chosen scope; `standard` requires 1–4)."——**停在 Section 4 的运行不得读起来像一部完成的圣经**。
R18. 呈现下一步前先查项目状态，只把真正未做的选项放进池子：`systems-index.md` 存在 → 跳过 `/map-systems`；引擎已配置（`project.yaml` 有 `engine.name`，或 technical-preferences 中引擎字段非 `[TO BE CONFIGURED]`）→ 跳过 `/setup-engine`；`design/gdd/` 有任何 `*.md` → 跳过 `/design-system`；存在 `gdd-cross-review-*.md` → 跳过 `/review-all-gdds`；有 GDD → 加入 `/consistency-check` 与 `/asset-spec` 选项。`workflow: minimal` 档选项池为 `/create-stories`（尚无 story）或 `/dev-story [next story]` 加 Stop here（GDD/architecture 池仅 `standard`/`full`）。字母只分配给实际包含的选项，最合逻辑的推进项标 `(recommended)`；`standard`/`full` 恒含 `/create-architecture` 与 Stop here。

**协作协议（collaborative 档）**
R19. 每节循环固定为 **Question → Options → Decision → Draft（来自 art-director agent）→ Approval → Write to file**。**绝不自己起草任何节**——每节内容必须来自相关专家；一次委派可覆盖多节（2–4 共享一次调用，5–6 也是），但没有任何节可凭编排者自己的判断写出。
R20. 每节批准后**立即写盘**——写盘与批准都不得批量；批量只在派生调用层；用户仍是一次看一节、批一节、落一节。agent 之间的分歧全部浮给用户（尤其 art-director vs. technical-artist），**禁止静默解决**。
R21. 美术圣经是约束文档：用未来决策的自由度换视觉一致性——每节都应像在**有效收窄**解空间，而不是加描述。

## 4. 门禁与裁决
- **AD-ART-BIBLE**（美术总监签发，Phase 5）：spawn 前做 review-mode 检查——`solo` → 跳过，注记 "AD-ART-BIBLE skipped — Solo mode."；`lean` → 跳过（非 PHASE-GATE），注记 "…Lean mode."；`full` → 正常 spawn。跳过时问 "May I record the skipped sign-off in `design/art/art-bible.md`'s header?"，经批准把头部 `> **Art Director Sign-Off (AD-ART-BIBLE)**: [Not yet reviewed]` 改为 `SKIPPED [date] — [solo|lean] mode`——两种形式都算**已记录的签发**。
- 全部节完成（或 Phase 1 的 scoped 集完成）后 spawn `art-director` 执行 **AD-ART-BIBLE** 门禁（门禁定义在 `.claude/docs/director-gates/ad-art-bible.md`，由被派生的 agent 自己读——**主会话禁止读门禁文件**）。传入：art bible 路径、pillars 与 core fantasy、平台与性能约束（`platform.*`/`performance.*`，回退 technical-preferences）、visual identity anchor；brief 档传 pitch 与 "what they feel" 行充当 pillars/fantasy、"Art & audio direction" 行充当 anchor。
- 裁决按 `director-gates.md` 标准规则处理。`Revise flagged items` 或解决 REJECT 时：由**该节自己的专家**重写被标节（Section 7 配 `ux-designer`、Section 8 配 `technical-artist`），重走呈现-批准-写盘后记 `REVISED [date]`。**NOT ASSESSED 绝不是批准**：命名缺失输入补齐重跑，或记录 NOT ASSESSED。
- 裁决写入圣经头部：`> **Art Director Sign-Off (AD-ART-BIBLE)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`。

## 5. 移植建议
- **可直接移植**：R1（不读不改已完成节的 retrofit 扫描）、R3（批准即写盘授权）、R4-R5（档位决定 scope + 成本杠杆注记）、R7（同输入多节合并派生但逐节批准）、R14-R15（专家冲突必须双立场浮出、禁静默解决）、R17（收尾点名未写节——防"半成品读起来像完成品"）、R19-R21（起草权归专家、逐节写盘、约束文档心态）。
- **需替换概念**：美术圣经 → 品牌指南/设计系统文档/视觉规范；9 节 → 适配目标领域的节集合（色彩→配色板与语义色，Shape Language→排版与版式语言，Asset Standards→组件/资产尺寸与格式规范）；pillars → 产品原则；art-director/ux-designer/technical-artist → 品牌/视觉设计师、UX 顾问、前端性能专家；外包团队可照做 → "无需口头澄清即可执行的规格"标准。
- **改写示例**：
  - "每节规格必须由对应领域专家起草，编排会话绝不代笔；一次派生可覆盖多个强耦合小节，但用户审批与写盘必须逐节进行。任何节未经 `[批准即写入]` 选项确认不得落盘。"
  - "品牌/视觉偏好与技术约束（性能预算、平台限制）冲突时，必须把『理想标准 / 受限标准』两个立场并列浮出交由负责人裁决，禁止静默择一；规格中的含糊正是生产成本的出生地。"

## 6. 关联文档
- 上游：`/brainstorm`（概念与 Visual Identity Anchor）、`/setup-engine`（资产标准可能需引擎已定）
- 下游：`/map-systems`、`/design-system`、`/asset-spec`（从获批圣经生成逐资产视觉规格）、`/consistency-check`（扫描 GDD 与圣经的视觉方向冲突）、`/review-all-gdds`、`/create-architecture`
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/director-gates.md`、`.claude/docs/director-gates/ad-art-bible.md`、`.claude/docs/effects-map.md`、`.claude/docs/templates/art-bible.md`、`.claude/docs/technical-preferences.md`
