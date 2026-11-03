# asset-spec — 逐资产视觉规格（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/asset-spec/SKILL.md) ｜ 阶段：Phase 5-6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/asset-spec [system:<name> | level:<name> | character:<name>] [--review full|lean|solo]`
- **一句话职责**：从 GDD 与角色档案生成逐资产视觉规格（尺寸、格式、命名、视觉描述）与 AI 生成提示词；运行于 art bible 之后。
- **触发前置**：art bible 存在（或 `rigor: minimal` 下的 game-brief 例外路径，见 R8）；配置经 `resolve_config --keys review_mode,automation` 解析；`AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续；`automation_always_ask` 类别恒提示）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `design/art/art-bible.md`（Visual Identity Statement、Color System、Shape Language、§8 Asset Standards）；`project.yaml` 的 `performance.*`、`naming.*`（缺失回退 `.claude/docs/technical-preferences.md`）；按目标类型读源文档（system→`design/gdd/[name].md`；level→`design/levels/[name].md`；character→`design/narrative/characters/[name].md` 或搜 `design/narrative/` 与 `design/assets/entity-inventory.md`）；可选：该目标既有 spec、`design/assets/asset-manifest.md`、`design/assets/specs/*.md`；Phase 0b 另读 `design/gdd/systems-index.md`、GDD 的 Visual/Audio 与 UI Requirements 节（仅 grep）、`design/registry/entities.yaml` | 规格锚点 / 性能预算与命名 / 源需求 |
| 产出 | `design/assets/specs/[target-name]-assets.md`（重跑时原位更新）；`design/assets/asset-manifest.md`（不存在则创建，否则追加/更新）；Phase 0b 时 `design/assets/entity-inventory.md` | 写前逐一征得同意 |
| 派生智能体 | `art-director`（视觉描述 + 生成提示词 + art bible 规则引用）；`technical-artist`（尺寸/面数、格式、命名、引擎约束、LOD） | full 双派生并行；lean 仅 art-director；solo 均不派生 |

resolve_config 配置键及档位影响：
- `review_mode` 全链解析；无设置时随 `modes.rigor`——`minimal`（默认）→ `solo`、`standard` → `lean`、`full` → `full`；`--review` 参数仅覆盖本次运行。
- `automation` 决定交互模式；调用外部图像生成器（图像 API）**无论档位一律提示**——不可逆外部动作无条件守护，与 `external_calls` 是否列入 `automation_always_ask` 无关（当前技能只发生成提示词文本；接上实时生成时守护生效）。

## 3. 核心规则（逐条编号 R1、R2……）

### 无参数入口与清单流程（Phase 0b）
R1. 无参数时：查 `design/assets/entity-inventory.md`——存在则读之，找第一个状态 "Needed" 且尚无 spec 文件条目，用 `AskUserQuestion` 问是否为它生成规格（`[A] Yes — spec [name]` / `[B] Pick a different item` / `[C] Stop here`）；无清单则查 `design/assets/asset-manifest.md`，存在则同流程但以 manifest 为源；两者皆无时不失败——启动 Phase 0b 的 Entity & Screen Inventory 流程。（无参数分支）
R2. Phase 0b 产出 `design/assets/entity-inventory.md`（游戏所需全部视觉物的母清单，资产规格工作开始前运行一次）：Step1 并行收集——读 `design/gdd/systems-index.md` 提取全部系统；GDD 资产内容**禁止全文读每份 GDD**，只 `Grep pattern="## (Visual/Audio Requirements|UI Requirements)" glob="design/gdd/*.md" -A 25`，命名实体（角色/敌人/建筑/物品）读 `design/registry/entities.yaml`（`entities`/`items`，存在且有条目时），否则 grep GDD；仅在 Visual/Audio 节缺失或读 `[To be designed]` 时才全文读该 GDD（Phase 1 已处理该情形）；VFX 事件出现在该 grep 上下文中；读 `design/art/art-bible.md` 提取命名视觉类别与资产类型预期；`design/narrative/` 扫描角色/世界实体文档（可选非必需）。（Phase 0b Step 1）
R3. Step2 按固定类别组织：Characters / Protagonists、Enemies / Creatures、Buildings / Structures、Environment / Terrain、Items / Props、VFX / Particles、UI Screens（逐屏名列出）、HUD Elements、Audio（SFX、音乐——仅描述，无生成提示词）、Other；每项注明来源文档。Step3 呈现全部建议清单后 `AskUserQuestion` 四选：`[A] Looks good — save this inventory` / `[B] Add items I'll describe` / `[C] Remove items that don't apply` / `[D] Both add and remove — let me edit`；[B]/[D] 时请用户描述附加项——简繁描述皆可，协作至满意；[C]/[D] 时问删哪些、为何删并移除。Step4 用户批准后问 "May I write the entity inventory to `design/assets/entity-inventory.md`?" 并写文件（Entities/UI Screens/HUD Elements/Audio 四表，Status 列默认 Needed），写后告知下一步：对每个 UI 屏跑 `/ux-design [screen name]`、对每个视觉实体跑 `/asset-spec system:/level:/character:` 三者之一、或再运行 `/asset-spec` 逐项处理。（Phase 0b Step 2-4）

### Phase 0 — 参数与模式
R4. 解析：目标类型（system/level/character）、目标名（冒号后，归一化为 kebab-case）、`--review [full|lean|solo]`。模式行为：`full`——并行 spawn `art-director` 与 `technical-artist`；`lean`——仅 `art-director`（更快，跳过技术约束 pass）；`solo`——不 spawn，主会话仅凭 art bible 规则写规格（用于简单资产类别或速度优先时）。（Phase 0）

### Phase 1 — 收集上下文
R5. 问用户任何问题之前先读完全部源材料；art bible 与 GDD 按节读（Grep `^#` 找标题 + Read offset/limit）。（Phase 1）
R6. art bible 必读——缺失即失败并提示："No art bible found. Run `/art-bible` first — asset specs are anchored to the art bible's visual rules and asset standards."。提取：Visual Identity Statement、Color System（语义色）、Shape Language、Asset Standards（§8——尺寸、格式、面数预算、纹理分辨率档）。（Phase 1）
R7. 读 `project.yaml` 的 `performance.*` 与 `naming.*`；任何键缺失或为空（含 `project.yaml` 无对应块）时回退 `.claude/docs/technical-preferences.md`；提取性能预算与命名约定。（Phase 1）
R8. **minimal 例外**：无 art bible 但 `design/game-brief.md` 存在（`rigor: minimal` 不要求 art bible）时不失败——规格锚定 brief 的 **Art & audio direction** 行，并在输出顶部声明："Anchored to the brief's one-line art direction; there is no art bible, so colour, shape and asset-standard rules below are proposals, not constraints."；可选地提供一次 `/art-bible`。写出的 spec 同锚：头部用 `> **Art direction**: design/game-brief.md (Art & audio direction) — no art bible` 替代 `> **Art Bible**:` 行、每资产用 `**Brief anchor:** [应用的 brief 行]` 替代 **Art Bible Anchors** 块、且不引用任何 Art Bible 节或 §8 档。（Phase 1）
R9. 按目标类型读源文档：system→`design/gdd/[target-name].md` 提取 **Visual/Audio Requirements** 节——缺失或读 `[To be designed]` 时提示（要么运行 `/design-system [target-name]` 补全 GDD，要么手动描述）并 `AskUserQuestion`：`[A] Describe needs manually` / `[B] Stop — complete the GDD first`；level→`design/levels/[target-name].md` 提取美术需求、资产清单、VFX 需求与 art-director 的制作概念规格；character/entity→`design/narrative/characters/[target-name].md` 或搜 `design/narrative/` 与 `design/assets/entity-inventory.md`，提取视觉描述、角色与已指明辨识特征。无源文档不失败：`AskUserQuestion` 三选（`[A] Describe it now` / `[B] Skip this entity` / `[C] Stop here`）；[A] 时用户描述即源——简答出简规格、详答出详规格，接受任意详细度。（Phase 1）
R10. 可选读：该目标既有 spec（`design/assets/specs/[target-name]-assets.md` 存在即重跑——Phase 2 只提新增或变更，Phase 5 原位更新）；`design/assets/asset-manifest.md`（避免重复）；Glob `design/assets/specs/*.md` 扫可共享资产。随后呈现上下文摘要（源文档与资产类型数 / art bible 状态 / 该目标已 spec 数 / 共享资产）。（Phase 1）

### Phase 2 — 资产识别
R11. 从源文档提取每类资产（显式+隐含）：system——VFX 事件、精灵引用、UI 元素、音频触发、粒子效果、图标需求与任何"视觉反馈"用语；level——独有环境道具、氛围 VFX、光照设置、环境音、skybox/背景、区域专属材质；character——精灵表（idle、walk、attack、death）、立绘/头像、技能附带 VFX、UI 呈现（图标、血条皮肤）。分组：Sprite / 2D Art、VFX / Particles、Environment、UI、Audio（**仅描述，无生成提示词**）、3D Assets（按引擎适用）。（Phase 2）
R12. 呈现分组清单后 `AskUserQuestion` 四选：`[A] Proceed — spec all of these` / `[B] Remove some assets` / `[C] Add assets I didn't catch` / `[D] Adjust categories`——用户确认资产清单之前禁止进入 Phase 3。（Phase 2）

### Phase 3 — 规格生成
R13. 按模式派生且**全部 Agent 调用同时发出**，禁止等一个再开下一个。full 模式：`art-director`——提供全部资产清单、Visual Identity Statement、Color System、Shape Language、源文档视觉需求及 art bible §9 提到的参考游戏/美术，要求每资产产出 (1) 锚定 shape language 与 color system 的 2-3 句视觉描述（两个不同艺术家能产出一致结果的精确度）、(2) 可直接用于 AI 图像工具的生成提示词（Midjourney/Stable Diffusion 风格——含风格关键词、构图、色板锚、负提示）、(3) 直接治理该资产的 art bible 规则（按节引用）；音频资产只描述声学特征。`technical-artist`——提供全部资产清单、§8 Asset Standards、性能预算、引擎名与版本，要求每资产指定 (1) 精确尺寸或面数（匹配 §8 档——**禁止发明新尺寸**）、(2) 文件格式与导出设置、(3) 命名约定、(4) 引擎专属约束、(5) LOD 要求；标记 art bible 首选标准与引擎约束冲突的资产类型。lean 模式仅派生 art-director；solo 模式都跳过、仅凭 art bible 规则推导并注明技术约束未验证。（Phase 3）
R14. 每个被跳过的代理必须**按名**在输出中（规格之前）宣布："technical-artist skipped — Lean mode: technical constraints not validated." / "art-director and technical-artist skipped — Solo mode: specs derived in this session; technical constraints not validated."——无代理参与的规格不得读起来像被代理审过。（Phase 3）
R15. 必须收齐两份回应后才进 Phase 4；两者冲突（如 art-director 定 4K 纹理而 technical-artist 标记引擎预算要求 512px）必须显式呈现，禁止默默解决。（Phase 3）

### Phase 4 — 编译与审查
R16. 合并为每资产 `## ASSET-[NNN] — [Asset Name]` 规格块：
   - 字段表：Category / Dimensions / Format / Naming / Polycount（3D 时）/ Texture Res（如 "512px — matches Art Bible §8 Tier 2"）；
   - Visual Description（2-3 句，两个艺术家能产出一致结果的精确度）；
   - Art Bible Anchors（§3 Shape Language 与 §4 Color System 的应用规则）；
   - Generation Prompt（含风格关键词、构图注记、色板锚、光照方向、负提示）；
   - `**Status:** Needed`。
   全部呈现后 `AskUserQuestion` 三选：`[A] Approve all — write to file` / `[B] Revise a specific asset` / `[C] Regenerate with different direction`。（Phase 4）
R17. [B]：问哪项资产、改什么，内联修订后重新呈现——小文本修订**禁止**重新 spawn 代理，仅视觉方向本身需变更才重 spawn；[C]：问改什么方向，带更新后的 brief 重新 spawn 相关代理。（Phase 4）

### Phase 5 — 写文件
R18. 批准后问 "May I write the spec to `design/assets/specs/[target-name]-assets.md`?"；文件已存在（同目标重跑）时**原位更新、绝不整体覆盖**——保留既有 `ASSET-NNN` 块与 ID、仅应用用户批准的变更、新资产以下一个全项目 ID 追加，提示语改为 "May I update …?"。文件头：Source / Art Bible / Generated / Status 计数行（[N] specced / approved / in production / done）。（Phase 5）
R19. 随后更新 `design/assets/asset-manifest.md`：不存在则创建（Progress Summary 表 + Assets by Context 块）；已存在则追加新上下文块——同目标重跑时在既有块中加新行而非追加第二个块——并更新 Progress Summary 计数；问 "May I update `design/assets/asset-manifest.md`?"。（Phase 5）

### Phase 6 — 关闭与横切协议
R20. 关闭用 `AskUserQuestion` 五选：`[A] Spec another system` / `[B] Spec a level` / `[C] Spec a character` / `[D] Run /asset-audit — validate delivered assets against specs` / `[E] Stop here`。（Phase 6）
R21. **Asset ID 全项目顺序分配**（非按上下文）：分配前 `Grep pattern="ASSET-" path="design/assets/asset-manifest.md"` 找当前最高号，新资产从最高 +1 起——保证 ID 全项目稳定唯一；无 manifest 从 `ASSET-001` 起。（Asset ID Assignment）
R22. **共享资产协议**：spec 前先查其它上下文是否已有等价资产（通用 UI 元素、通用环境道具、角色 VFX 底版+色变体）；匹配则引用既有 ASSET-ID 而非新建重复，并在 manifest 的 referenced-by 列记共享使用。（Shared Asset Protocol）
R23. **错误恢复**：任一代理返回 BLOCKED 或未完成——立即呈现 "[AgentName]: BLOCKED — [reason]"；`lean` 模式或 `technical-artist` 阻塞→仅用 art-director 输出并注明技术约束未验证；`solo` 模式或 `art-director` 阻塞→从 art bible 规则推导描述并标记 "Art director not consulted — verify against art bible before production"；**总是产出部分规格**，绝不因一个代理阻塞而丢弃已完成工作。（Error Recovery Protocol）
R24. **协作协议**（collaborative 模式，默认；guided/autonomous 见 automation-modes.md）：每阶段遵循 Identify → Confirm → Generate → Review → Approve → Write——未经用户确认资产清单禁止写规格；规格必须锚定 art bible（与之矛盾的规格是错的）；所有代理分歧必须呈现、不默默选边；仅在显式批准后写规格文件；写规格后立即更新 manifest。（Collaborative Protocol）

## 4. 门禁与裁决
- 本技能无裁决/门禁体系（无 verdict 枚举）；质量控制通过强制顺序实现：资产清单未确认（R12）、规格未批准（R16）、文件写入未获同意（R18/R19）——均不得进入下一步。
- 质量锚点：与 art bible 矛盾的规格是错的；`technical-artist` 的尺寸必须匹配 §8 档、禁止发明新尺寸。
- 派生门禁：full 缺席任一代理时冲突必须并呈（R15）；代理 BLOCKED 走错误恢复（R23），永不静默放弃。

## 5. 移植建议
- **可直接移植**：R3/R12/R16（识别→确认→生成→审查→批准→写的强制链）、R15/R23（冲突并呈 + 部分产出不弃工）、R18（重跑原位更新不整体覆盖）、R21（全项目顺序 ID）、R22（共享资产引用协议）、外部图像 API 无条件提示（resolve_config 注记）。
- **需替换概念**：art bible → 品牌规范 / 设计系统文档；GDD Visual/Audio Requirements → 各领域的需求节；`design/assets/specs/` → 规格目录；art-director / technical-artist → 创意专家与技术约束专家；AI 生成提示词 → 任何外包/生成式工具的提示词产物。
- **改写示例**：
  - R12 → "向用户呈现完整分组清单并经确认（含增删调选项）之前，禁止开始生成任何规格——未确认的清单是规格返工的最大来源。"
  - R18 → "目标规格文件已存在（重跑）时必须原位更新：保留既有块与 ID、仅应用用户本次批准的变更、新条目按全项目顺序 ID 追加；绝不整体覆盖。"

## 6. 关联文档
- 上游：`/art-bible`（规格锚点，缺失即阻断——minimal 例外走 game-brief）、`/design-system`（GDD 的 Visual/Audio Requirements 节）、`/ux-design`（清单中每个 UI 屏）。
- 下游：`/asset-audit`（对照规格验证已交付资产，收尾推荐）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/technical-preferences.md`。
