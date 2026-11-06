# start — 首次会话引导与路由（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/start/SKILL.md) ｜ 阶段：Any ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/start`
- **一句话职责**：首次会话引导——读取项目现状、询问用户起点、展示假设并钉住配置，最后只点名"唯一下一步"，绝不亲自执行它。
- **触发前置**：面向新用户（刚 clone/安装、无想法、无引擎、不知从何开始，或要带入存量项目）；可随时运行，`project.yaml` 不存在也能跑。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `bash .claude/scripts/project-state.sh` 的全部行（`engine`/`code_root`/`source_files`/`concept`/`gdd_files`/`adr`/`prototype`/`sprint`/`milestone`/`story`/`origin_url`/`stage`） | 判定引擎、代码量、设计文档与已记录阶段 |
| 读取 | `project.yaml`（若存在） | 补助手不覆盖的 `modes.rigor`/`modes.automation`；已设值保留、不再提问 |
| 读取 | `.claude/docs/automation-modes.md`、`.claude/docs/settings-guidance.md` §3 | Phase 5/6 的 automation 语义；rigor 推断信号表 |
| 产出 | `project.yaml` 的 `project.stage`（含遗留镜像 `production/stage.txt`）、`modes.rigor`、`modes.automation`——全部经 helper 写入，且仅在用户明确同意后 | 幕后约定：写死一个值会"钉住"该旋钮、使其不再随 rigor 扩张变化；镜像文件优先于 yaml 值 |
| 派生智能体 | 无，主会话直接执行 | 全程不派生 |

**写入边界（关键）**：`/start` 只允许写上述 3 个键；**禁止**写 `modes.review_mode`（及 `production/review-mode.txt`），也**禁止**写 `modes.workflow`、`docs.density`、`qa.level`、`modes.story_granularity`、`team.size`。

## 3. 核心规则（逐条编号 R1、R2……）

### 提问纪律（贯穿全程）
R1. 必须用问题工具（AskUserQuestion）提问；没有该工具时，把选项编号列出并结束回合等待。问题是回复的最后内容——其后不得再有任何路径、笔记或建议。（"Guided Onboarding"开头）
R2. 被跳过或被关闭的问题不算回答：必须用纯文本再问一次。（同上）
R3. Phase 2、4、5 的提问在任何 automation 模式下都要照问；引擎除外——引擎由 `/setup-engine` 选择，`/start` 不问引擎。（同上）
R4. Phase 6 的最后一问遵循 `project.yaml` 中已有的 `modes.automation`（依 `automation-modes.md`）；未设置时才问。（同上）

### Phase 1：读项目
R5. 必须运行 `bash .claude/scripts/project-state.sh` 并保留其行，但先不展示——它们用于校验用户 Phase 2 的回答。（Phase 1）
R6. `source_files` 为 `unknown` 时，含义是"找不到代码根"，必须如实说，**禁止**说成"没有代码"。（Phase 1 表）
R7. 忽略 `phase_inferred` 行：它按文件数猜测，"有代码但没有设计文档"不等于 Production。helper 失败时必须说明，并手工读取同等事实（`project.yaml` 的引擎、两份 concept 文件、代码根文件、`design/gdd/`）。（Phase 1）
R8. helper 不报告 rigor/automation——必须自己读 `project.yaml`；`modes.rigor`/`modes.automation` 已设值保留且对应问题不再问（Phase 4/5）。（Phase 1）
R9. `origin_url` 含 `donchitos/claude-code-game-studios`（大小写不敏感）说明 clone 仍指向模板仓库；换 owner 的 fork 属于用户自己。（Phase 1 表）
R10. **回头客判定**：引擎已设且 `concept` 在场——什么都不问，直接报出引擎、找到的 concept/brief、评审模式（`modes.review_mode` 已设则用之，否则用 rigor 隐含值：`minimal`→`solo`、`standard`→`lean`、`full`→`full`），建议 `/help`，视情况附模板远端提示，然后停止。（Phase 1）

### Phase 2：问起点
R11. 必须用问题工具问："Welcome! Where are you starting from with your game?"，四个选项：`A) No idea yet` / `B) Vague idea`（一个主题、感觉或类型）/ `C) Clear concept`（核心想法与类型已知、尚未写下）/ `D) Existing work`（设计文档、原型、代码或计划已存在）。（Phase 2）
R12. 回答与 Phase 1 事实矛盾时，只把发现说一次再重问：空项目上答 D（"这像全新模板，A 或 B 是否更合适？"）、磁盘有代码却答 A（"我在 `[code_root]` 发现代码；您是指 D 吗？"）。没有选项匹配时，让用户自行描述并据此路由。（Phase 2）

### Phase 3：路由
R13. 只点名**紧邻的下一步**；完整路径留到 Phase 6（rigor 已知后）。A：`/brainstorm open` 自由探索或 `/brainstorm [hint]` 从一个词开始，描述为"把没想法变成一份书面设计，下一步以此为起点"。B：要用户用几个词说出想法，原样接受，点名 `/brainstorm [their words]`。C：要用户用一句话（类型+核心机制）、纯文本给出概念，然后问"How would you like to proceed?"：`Formalize it first`（`/brainstorm [concept]` 写下来）或 `Jump straight in`（立即 `/setup-engine`，设计后补）。D：先报出 Phase 1 发现（"N source files under `[code_root]`, N design documents, engine [X / not set]"）；无引擎且不超出一个 concept 时下一步 `/setup-engine`，否则 `/project-stage-detect`。（Phase 3）
R14. 路由后必须说一句："I'll lay out the full path in a moment."。（Phase 3）

### Phase 4：展示假设并存盘
R15. Stage 取值：A/B/C → `Concept`；D 按 Phase 1 行查表——无引擎或不超出 concept（`gdd_files` 0）→ `Concept`；`gdd_files` ≥1 且 `adr` 0 → `Systems Design`；`adr` ≥1 → `Technical Setup`。（Phase 4）
R16. Rigor 取值：`project.yaml` 已设则保留并声明；否则按 settings-guidance.md §3 从用户原话推断：提到 open world/RPG/sim/sandbox/factions/crafting/economy/MMO/multiplayer/many systems → `full`；release/commercial/Steam/one clear core loop → `standard`；jam/weekend/prototype/first game/small/just trying → `minimal`；全不沾或没想法 → `minimal`（默认）。路径 B 的 hint 也是描述——"some kind of open-world survival sim" 即 `full`。（Phase 4）
R17. 必须按模板展示卡片（Stage+理由、Rigor+理由、三档简述、`/settings` 可随时改），然后用问题工具问："Save these to `project.yaml` (and the stage to `production/stage.txt`)?"，选项 `Save them` / `Don't save`。**禁止**就 rigor 本身再提问——卡片已展示，`/settings` 负责修改。（Phase 4）
R18. 选 Save：先 `bash .claude/scripts/set-stage.sh "[stage]"`，再（仅当 rigor 原先未设）`bash .claude/scripts/config-set.sh modes.rigor [value]`；核对回读行一致；说"Saved. Rigor `[value]` sets six other settings; `/settings` shows them and changes any of them."。（Phase 4）
R19. 选 Don't save 或任何非明确同意：**什么都不写**，本次运行沿用该值，并声明未保存。helper 非零退出：展示其输出、说明哪个设置没写下去，继续用本次运行的值。（Phase 4）

### Phase 5：问确认量
R20. `modes.automation` 已设：只说 "Automation is `[value]`" 并继续；未设则问："Last one: how much should I confirm with you as we work?"，选项 `Guided (Recommended)`（小事自决，大事——范围变更、删除、schema 变更——仍停）/ `Collaborative`（每个重要步骤前询问、写前出示草稿）/ `Autonomous`（推进并记录决策，仅 always-ask 类别才停；最快、token 最多），映射为小写 `guided`/`collaborative`/`autonomous`。（Phase 5）
R21. 用户的选择即写入授权：运行 `bash .claude/scripts/config-set.sh modes.automation [value]`——除非 Phase 4 的保存被拒绝（此时只说未保存）。（Phase 5）

### Phase 6：展示路径
R22. 必须先说："Here's your path at rigor `[value]`. Every skill still runs at any rigor; rigor changes what's required, not what's allowed."。路径以 Phase 3 点名的步骤开头；那是 `/brainstorm` 时（A、B、C 的 Formalize），`/brainstorm` 排第一、`/setup-engine` 第二——二者互不依赖。（Phase 6）
R23. `minimal` 四步到可运行代码：1 `/setup-engine`；2 `/brainstorm`（写一页 `design/game-brief.md`）；3 `/create-stories`（把 brief 的 MVP 列表变成 stories，无需 epics 或 sprint 计划）；4 `/dev-story`（第一行游戏代码）。（Phase 6）
R24. `standard` 全梯队：Concept：`/setup-engine`→`/brainstorm`→`/prototype`→`/art-bible`→`/gate-check`；Systems Design：`/map-systems`→`/design-system`（每系统一次）→`/review-all-gdds`→`/gate-check`；Architecture：`/create-architecture`→`/architecture-decision`（每决策一次）→`/create-control-manifest`→`/architecture-review`→`/test-setup`→`/ux-design`（无障碍与交互模式）→`/gate-check`；Pre-Production：`/ux-design`（HUD 与关键界面）→`/create-epics`→`/create-stories`→`/sprint-plan`→`/gate-check`；Production：`/dev-story`。每次 `/gate-check` 通过才把项目推前一阶段。（Phase 6）
R25. `full`：standard 的一切，另加 Pre-Production 中的 `/vertical-slice` 与 `/playtest-report`、每份 GDD 后的 `/design-review`。（Phase 6）
R26. 路径 D 有存量（stage `Systems Design` 或更晚，或磁盘有代码）改用存量路径，只打印适用步骤：`minimal`：1 `/project-stage-detect`；2 `/adopt`；3 `/setup-engine`（仅无引擎时，`engine` 已有则略）；4 brief 仅当 `concept` 缺失——代码根 ≥10 个源文件用 `/reverse-document design [code_root]`（从成品写 brief），此后**绝不**再提 `/brainstorm`；不足 10 个才 `/brainstorm`。`standard`/`full`：步骤 1–3，再 `/design-system retrofit [path]`、`/architecture-decision retrofit [path]`、`/architecture-review`、`/gate-check`。（Phase 6）
R27. 必须把 `minimal` 呈现为"有文档的底线"而非"低一等模式"，其代价只说一次：没有 GDD，设计问题会在代码里暴露。（Phase 6）
R28. `origin_url` 指向模板仓库时，附上：把 origin 重命名（`git remote rename origin template`，再 `git remote add origin <你的仓库 URL>`）、`UPGRADING.md` 从 `template` 拉更新并跳过它自己的 `git remote add template` 步骤——**只建议，禁止代跑**。（Phase 6）
R29. 问："Would you like to start with [first step]?"，选项 `Yes, start with [first step]` / `Something else first`。两种回答都只通向 Phase 7，**绝不**通向执行该步骤。（Phase 6）

### Phase 7：交接
R30. 必须且只用一行回复："Type `[skill]` to begin."。**禁止**启动该技能或为其调用 skill 工具——用户说了 yes 也不行，由用户亲手输入；选了别的就同样方式点名对应技能。（Phase 7）
R31. Verdict：**COMPLETE**——用户已定向并完成交接。用户若在 Phase 7 前中止，必须说明哪些设置已存、哪些未存。（Phase 7）

## 4. 门禁与裁决
- 无门禁。本技能是纯引导/路由，不跑 `/gate-check`；唯一的"裁决"是 Phase 2 矛盾检测（R12）与 Phase 4 的 Stage/Rigor 查表（R15/R16）。

## 5. 移植建议
- **可直接移植**：R1–R12、R14、R17–R22、R27、R29–R31（提问纪律、只点名下一步不代跑、显式同意才写配置、写入范围白名单、路径分档展示、交接协议）与任何"配置旋钮+镜像文件"双写体系的边界约定（R 后写入边界）完全通用。
- **需替换概念**：`project.yaml`/`production/stage.txt` → 目标项目的配置文件及其遗留镜像；`modes.rigor` → 项目的流程强度档位；游戏阶段名（Concept/Systems Design/…）→ 领域里程碑；`/brainstorm`、`/setup-engine` 等命令 → 你工作流中的对应入口；`origin_url` 模板仓库检测 → 任何"脚手架来源仓库"检测。
- **改写示例**：
  - "必须只向用户点名一个下一步命令，禁止自动执行它；用户确认后也只用一行 'Type `[command]` to begin.' 交接，由用户亲手输入。"
  - "只有用户明确同意后才可写配置，且只允许写引导技能名下的 3 个键；写死任何其它键都会钉住该旋钮，禁止。"

## 6. 关联文档
- 下游：`/brainstorm`、`/setup-engine`、`/project-stage-detect`、`/adopt`、`/reverse-document`、`/help`、`/settings`（全部只点名不代跑）
- 引用 docs：`.claude/docs/automation-modes.md`、`.claude/docs/settings-guidance.md` §3
- 脚本：`.claude/scripts/project-state.sh`、`set-stage.sh`、`config-set.sh`
