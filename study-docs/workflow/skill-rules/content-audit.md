# content-audit — 内容实现差距审计（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/content-audit/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/content-audit [system-name | --summary | (无参 = 全审计)]`
- **一句话职责**：对照 GDD 规定的内容数量，审计实际已实现的内容——计划（Specified）对已建（Found）。
- **触发前置**：配置经 `resolve_config --keys workflow,automation` 解析；`modes.workflow` 在审计前解析完毕（档位相关行为跟随解析后档位，绝不假设）；每个 `AskUserQuestion` 与文件写入遵循 `.claude/docs/automation-modes.md`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `design/gdd/systems-index.md`（系统列表、类别、MVP/优先档）；`design/registry/entities.yaml`（entities/items 节——优先的计划命名内容集）；`design/gdd/*.md` 范围内 GDD（按节读，>40KB 拒绝整读）；`design/gdd/*.md` 的 `^## Summary` 与内容计数语言（L0 预扫）；实现目录（资产根与代码根，见 R12）；`.claude/docs/code-root-resolution.md` | 计划侧 / 实现侧 |
| 产出 | `docs/content-audit-[YYYY-MM-DD].md`（经用户同意写入）；`--summary` 模式不写文件 | 报告含 Gap 表、HIGH PRIORITY、逐系统分解 |
| 派生智能体 | 无，主会话直接执行 | — |

resolve_config 配置键及档位影响：
- `workflow`（见 `.claude/docs/workflow-modes.md`）：`full`——对照全部 GDD 规格做全量内容计数审计；`standard`——仅审必需节中的规格，节外计数列入"本档未审"清单；`minimal`——无法运行（无系统索引存在）。
- `automation`：解析顺序 `project.local.yaml` → `project.yaml` → 默认 `collaborative`。

## 3. 核心规则（逐条编号 R1、R2……）

### 前置
R1. 参数解析：无参数→全系统全审计；`[system-name]`→仅审该系统；`--summary`→仅汇总表、不写文件。（入口）
R2. 必需输入（如 `design/gdd/systems-index.md`）缺失时报告 **`NOT ASSESSED — NO DATA`** 而非计算差距百分比——无规定时除零。（引言）
R3. 输入不足前置检查：
   1. 列出全部输入（数据文件、先前报告、profiler 输出、测试结果、registry、源代码）；
   2. 逐项记 `FOUND` 或 `ABSENT`（不是"假设存在"）；
   3. 某节必需输入 ABSENT 时该节记 **`NOT ASSESSED — NO DATA`**——禁止估算、禁止从相邻工件推断、禁止把必填格留给下次读模板的人；
   4. **每一个**必需输入都 ABSENT 时停止并整体报告 `NOT ASSESSED — NO DATA`，点名缺了什么、哪个技能产出它（`/map-systems` 产出 systems-index，`/design-system` 产出 GDD）。`NOT ASSESSED` 是成功；"无证据"绝不是"不存在证据"——零文件可扫的扫描没有验证任何东西。（Insufficient input）

### Phase 1 — 上下文收集
R4. 读 `design/gdd/systems-index.md`（按节读）提取全部系统、类别与 MVP/优先档。（Phase 1-1）
R5. registry 优先计数：`design/registry/entities.yaml` 存在则先读——其 `entities` 与 `items` 节即审计所计的跨 GDD 命名内容（已蒸馏、各带 `source:` GDD）：`Grep pattern="^  - name:" -A 2`——`- name:` 出现在全部四个 registry 节，只留 `-A 2` 上下文显示位于 `entities:` 或 `items:` 之下的名字（非 `formulas:`/`constants:`）。以这些为**计划**命名内容集，无需全文读拥有它们的 GDD。registry 不存在或无条目（空桩，`/design-system` 填充前的默认）时跳过、仅靠 GDD 扫描——行为不变只更贵。（Phase 1-2）
R6. L0 预扫两个 grep **必须分开**、禁止合并模式：
   - (a) `pattern="^## Summary"` files_with_matches——哪些 GDD 带 Summary（分母 / fail-open 检查）；
   - (b) 数字后跟内容名词的模式——哪些 GDD 真正声明内容计数（收窄步）：`[0-9]+[[:space:]]+(enemies|enemy types|levels|areas|maps|stages|items|weapons|equipment|abilities|skills|spells|cutscenes|conversations|dialogue scenes|bosses|quests)|(enemy|item|weapon|ability|level) types:`。
   理由：`## Summary` 匹配每份合规 GDD（与之取并集收窄不了任何东西），字面占位如 `N enemies` 不匹配真实 GDD；模式 (b) 匹配 Step 5 实际提取的数字+内容名词。（Phase 1-3）
R7. **fail-open 规则**：glob `design/gdd/*.md` 数出 N 做分母；扫描 (a) 匹配少于 N 意味那些 GDD 早于 `## Summary` 模板——**绝不**把缺失 Summary 当作系统不在范围内；零匹配 (a) 意为"还没有 GDD 带 Summary"而非"无可审内容"；全文读未匹配的在范围内 GDD。（Phase 1-3）
R8. 单系统审计：跳过预扫直接全文读。全审计：全文读扫描 (b) 匹配**且未被 step 2 的 registry 条目完全覆盖**的 GDD，外加扫描 (a) 未命中的每一份——fail-open 规则压过收窄：无 Summary 的 GDD 即使 (b) 未匹配也全文读；只有带 Summary 又无内容计数语言的 GDD（纯机制 GDD）记 "No auditable content counts" 而不全文读。（Phase 1-3）
R9. 全读范围内 GDD（>40KB 时按节读：Grep `^#` 找标题 + Read offset/limit）；逐 GDD 提取显式内容计数或列表并注明所在 `##` 节——`standard` 下必需节之外的计数入 "Not audited at this tier" 清单、**绝不**进库存。提取模式："N enemies" / "enemy types:" / 命名敌人列表、"N levels/areas/maps/stages"、"N items/weapons/equipment pieces"、"N abilities/skills/spells"、"N dialogue scenes/conversations/cutscenes"、"N quests/missions/objectives"、任何显式枚举列表。（Phase 1-4/5）
R10. 构建内容库存表（System | Content Type | Specified Count/List | Source GDD）；GDD 定性描述内容但无计数时记 "Unspecified" 并标记——未指明的计数是值得注意的设计缺口。（Phase 1-5/6）

### Phase 2 — 实现扫描
R11. 对 Phase 1 找到的每类内容扫描相关目录计数已实现量（用 Glob/Grep）。**Unreal**：内容在 `Content/`（地图与数据资产都是），代码根只有 C++——每个 `assets/…` glob 同时在 `Content/` 下跑（数据扩展名换成 `*.uasset`），关卡是 `Content/**/*.umap`；跳过会在每个 Unreal 项目找到零关卡并误报 NOT STARTED。**Unity**：内容在 `Assets/`（大小写精确对比 `code-root-resolution.md`），很少在 `data/` 下——每个 `assets/…` glob 同时在 `Assets/` 下跑且不要求 `data/` 段（items 用 `Assets/**/items/**`、`Assets/**/Items/**`、`Assets/**/*Item*.asset` 三套），数据文件含 `.asset`（ScriptableObject）与 `.prefab`；跳过会在 Unity 项目全零并误报 NOT STARTED。（Phase 2）
R12. 按内容类型扫描：**Levels/Areas/Maps**——Glob `assets/**/*.tscn`、`assets/**/*.unity`、`assets/**/*.umap` 及**代码根**场景文件（`*.tscn` Godot、`*.unity` Unity；Unreal 用 `Content/**/*.umap`）；找 `levels/`、`areas/`、`maps/`、`worlds/`、`stages/` 子目录；数非 UI 场景的唯一文件。**Enemies/Characters/NPC**——`assets/data/**/enemies|characters/**` 与 `<code root>/**/enemies|characters/**`；找 `.json`/`.tres`/`.asset`/`.yaml` 实体数值与场景/prefab。**Items/Equipment/Loot**、**Abilities/Skills/Spells**——对应目录找数据文件。**Dialogue**——`assets/**/*.dialogue|*.csv|*.ink` + grep `assets/data/`。**Quests/Missions**——`quests|missions` 目录找 `.json`/`.yaml`。代码根未解析时报告 `NOT ASSESSED — code root unresolved` 而非零命中。（Phase 2）
R13. 报告必须承认引擎特有注记：计数是近似（不能完美解析每种引擎格式、不能区分编辑器专用文件与发布内容）；场景文件可能混入系统/UI 场景——扫描计全部匹配并注明此告诫。（Phase 2）

### Phase 3 — 差距报告
R14. 差距表（System | Content Type | Specified | Found | Gap | Status）；状态四档：
   - `COMPLETE`——Found ≥ Specified（100%+）；
   - `IN PROGRESS`——Found 为 Specified 的 50-99%；
   - `EARLY`——1-49%；
   - `NOT STARTED`——Found 为 0。（Phase 3）
R15. `HIGH PRIORITY` 标志：状态为 NOT STARTED 或 EARLY，**且**系统在 systems-index 标 MVP 或 Vertical Slice，**或**索引显示该系统阻塞下游系统。（Phase 3）
R16. 汇总行：总规定（Specified 列总和）、总找到（Found 列总和）、总差距百分比 `(Specified - Found) / Specified * 100`。Found 为 `NOT ASSESSED`（代码根未解析）的行无 Gap、无 Status、**绝不**算 NOT STARTED、不进两个总数——汇总中点名该行。（Phase 3）

### Phase 4 — 输出
R17. 全审计/单系统模式：呈现差距表与汇总后问 "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"；批准则写文件：Summary（Total specified / Total found / Gap 计数与百分比 / Scope 行（全审计或单系统；全部 GDD 节或 required sections only (workflow: standard)）/ Not audited at this tier 行（full 时省略））+ 近似告诫（计数基于文件扫描、不能区分发布内容与编辑器/测试资产、HIGH PRIORITY 缺口建议人工验证）+ Gap Table + HIGH PRIORITY Gaps（含理由）+ Per-System Breakdown（GDD 路径、已审内容类型、扫描精度注记）+ Recommendation（聚焦前三个系统）+ Unspecified Content Counts（GDD 与内容类型列表）。写后问 "Would you like to create backlog stories for any of the content gaps?"——同意则为用户选的每个系统建议 story 标题，按缺口大小指向 `/create-stories [epic-slug]` 或 `/quick-design`。（Phase 4）
R18. `--summary` 模式：Gap 表与 Summary 直接打印到会话，**不写文件**，以 "Run `/content-audit` without `--summary` to write the full report." 收尾。（Phase 4）

### Phase 5 — 后续与裁决
R19. 按条件推荐最高价值后续：任一系统 `NOT STARTED` 且 MVP 标→"运行 `/design-system [name]` 在实现开始前给 GDD 补上缺失的内容计数"；总差距 >50%→"运行 `/sprint-plan` 把内容工作分配到即将到来的 sprint"；任一 HIGH PRIORITY→"为每个 HIGH PRIORITY 缺口运行 `/create-stories [epic-slug]`"；用过 `--summary`→"运行 `/content-audit`（无 flag）把完整报告写入 `docs/`"。（Phase 5）
R20. 收尾裁决与本次运行匹配：**COMPLETE**——内容审计完成；**NOT ASSESSED — NO DATA**——必需输入缺失（见顶部注记）、范围内无物给出计数（无 registry 条目且每份 GDD 为 "Unspecified" 或 "No auditable content counts"）、或某 Found 计数取不到（`NOT ASSESSED — code root unresolved`）——点名是哪种，缺失计数时点名 `/design-system`。**绝不**为算不出差距的运行打印 COMPLETE。（Phase 5）

## 4. 门禁与裁决
- **裁决词（收尾）**：`COMPLETE` / `NOT ASSESSED — NO DATA`。
- **状态档（逐行）**：`COMPLETE` / `IN PROGRESS` / `EARLY` / `NOT STARTED`（Found 占 Specified 的百分比定档）。
- **取最严原则**：HIGH PRIORITY = (NOT STARTED 或 EARLY) ∧ (MVP/Vertical Slice 或阻塞下游)；任何 NOT ASSESSED 行不进总数、不算 NOT STARTED。
- **硬规则**：minimal 档无法运行；算不出差距的运行绝不打印 COMPLETE。

## 5. 移植建议
- **可直接移植**：R3（输入不足检查）、R6-R8（两条分离的预扫 grep + fail-open 规则——"缺标记不等于不在范围内"）、R16（NOT ASSESSED 行不进总数不算未开始）、R20（无差距可算绝不报完成）、HIGH PRIORITY 双条件（进度 × 优先级）。
- **需替换概念**：GDD → 规格/需求文档；systems-index → 模块索引；MVP/Vertical Slice → 里程碑标签；引擎资产根差异（Content/Assets）→ 各构建产物目录差异；`/design-system`、`/sprint-plan`、`/create-stories` → 各项目的文档/排期/任务工具。
- **改写示例**：
  - R8 → "预扫收窄不得吞掉 fail-open：缺 'Summary' 标记的文档即使未被内容计数模式命中也必须全文读——那类文档早于标记模板存在，缺失标记不等于不在审计范围内。"
  - R20 → "裁决必须匹配本次运行：算不出差距（必需输入缺失、所有文档均未给计数、或实现侧计数无法获取）时报告 NOT ASSESSED — NO DATA 并点名原因，绝不打印 COMPLETE。"

## 6. 关联文档
- 上游：`/map-systems`（产出 systems-index）、`/design-system`（产出 GDD 与 registry 条目——补内容计数的指定出口）。
- 下游：`/sprint-plan`（差距 >50%）、`/create-stories` 与 `/quick-design`（为缺口建 backlog story）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/code-root-resolution.md`、`.claude/docs/config-resolution.md`。
