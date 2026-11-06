# patch-notes — 玩家语言补丁说明（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/patch-notes/SKILL.md) ｜ 阶段：Phase 7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/patch-notes [version] [--style brief|detailed|full]`
- **一句话职责**：从内部 changelog 与 git 历史生成**玩家语言的**补丁说明——把开发者的技术措辞翻译成玩家体验描述，优先用项目自己的语气指南与模板。
- **触发前置**：自动化模式经 resolve_config 解析（`automation`），遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续）；无版本参数时必须先问用户。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `git log --oneline -20`（溯源采样）；`production/releases/[version]/changelog.md`（存在时）；`docs/CHANGELOG.md` 该版本条目；上一 release tag 到当前 tag/HEAD 的 `git log`（fallback） | 变更数据源，内部 changelog 优先 |
| 读取 | `production/sprints/` 冲刺回顾；`design/balance/` 平衡变更文档；QA 修复记录 | 变更语境 |
| 读取 | 语气指南：`.claude/docs/technical-preferences.md`（tone/voice/style 字段或节）→ `docs/PATCH-NOTES-STYLE.md` → `design/community/tone-guide.md` | 按顺序检测，取第一个有内容的 |
| 读取 | 模板：Glob `docs/patch-notes-template.md` 与 `.claude/docs/templates/patch-notes-template.md` | 找到则替代内置样式模板 |
| 读取 | `design/` 与代码根（`src/`、`Assets/`、`Source/`）——溯源交叉验证 | Game commit 点名的系统应真实存在 |
| 产出 | 会话内输出说明 + 按类目变更计数 + 被排除的内部改动清单（供评审）；用户同意后写 `docs/patch-notes/[version].md` **和**归档副本 `production/releases/[version]/patch-notes.md` | yes/no 二选一：yes 写两份，no 一份都不写 |
| 派生智能体 | 无，主会话直接执行 | |

## 3. 核心规则（逐条编号 R1、R2……）

### 溯源检查（Provenance check — Phase 2 之前必跑）
R1. **读历史之前先确认它属于这个游戏**。采样 `git log --oneline -20`：空或 git 不可用 → 跳过本检查——没有可分类的东西，Phase 2 的无 changelog 数据分支才是正确停靠。（Provenance）
R2. 范围内**每条 commit 逐一**分到恰好一类：**Game**——玩家玩的那个游戏的改动：机制、内容、平衡、美术、音频、UI、其中任何 bug；**Framework / maintenance**——改 CCGS 自身或项目工具：subject 点名 skills、hooks、agents、测试计划、CI、框架自身文档——**从玩家说明中排除，但不是停下来的理由**；**Unclear**——按 framework 处理：没法自信归位的提交不是写玩家文案的提交。（Provenance）
R3. 按计数决定：**至少一个 Game commit** → 只用它们继续，说明共几条中用了几条（让读者看见过滤跑了）；**零 Game commit** → 停，用原文消息并报出 0 of N 计数。Verdict: **BLOCKED**——不生成说明。（Provenance）
R4. **逐条过滤；不要对"仅仅包含维护工作"的仓库停**：每个基于本框架的项目都会积累 hooks/CI/skills 提交——游戏仓库*就是*框架仓库，仓库级停会误伤几乎每个真实项目。危险不是这些提交**存在**，而是它们被**渲染成玩家文案**；逐条排除正好解决，仓库级停解决不了。（Provenance）
R5. **廉价交叉验证**：Game commit 点名的系统应出现在 `design/` 与代码根中；它们点名一个这些目录从未提及的产品才是真正的错误历史信号——停。这是硬停不是警告：框架提交渲染成玩家文案流畅、可信、全假（session-hook 超时 → *"Fixed an issue where progress from your last session could be lost on launch"*，而游戏**没有存档系统**）；读者分不出来，只有这道检查能。（Provenance）

### Phase 1-2 — 参数与数据
R6. 参数：`version`——目标版本（如 `1.2.0`）；`--style`——`brief`（要点）/ `detailed`（带语境）/ `full`（带开发者评注），**默认 `detailed`**。无版本 → 先问用户再继续。（Phase 1）
R7. 取数：内部 changelog → `docs/CHANGELOG.md` 条目 → git log（fallback）；再读冲刺回顾、平衡文档、QA 修复记录。**无 changelog 数据**（`production/releases/[version]/changelog.md` 与 `docs/CHANGELOG.md` 该版条目都不存在，且 git log 空或不可用）→ 输出 "No changelog data found for [version]. Run `/changelog [version]` first…"。Verdict: **BLOCKED**。（Phase 2）

### Phase 2b — 语气指南与模板检测
R8. **语气指南**：按顺序查三处（见数据依赖表），任一含 tone/voice/style 指令即提取并应用到生成文案的语言与框架。**全无 → 默认**：玩家友好的非技术语言；热情但不夸张；聚焦玩家体验而非开发者改动。（Phase 2b）
R9. **模板**：两个位置 Glob；任一存在 → 读它并作为 Phase 4 输出结构，**替代**内置 Brief/Detailed/Full 模板（传了 `--style` 也要说明被模板替代）。把分类数据映射进模板节——每个类目对应到"意思相同"的节（New Content → 其新特性节、Bug Fixes → 其修复节）；没有对应节的类目放进**最接近**的节，**绝不丢弃**；模板的头尾文字保持原样。不存在 → 用 Phase 4 内置样式模板。（Phase 2b）

### Phase 3-4 — 分类、翻译与生成
R10. 玩家向类目：**New Content**（新特性、地图、角色、物品、模式）；**Gameplay Changes**（平衡、机制、进度）；**Quality of Life**（UI 改进、便利特性、辅助功能）；**Bug Fixes**（**按系统分组**：战斗、UI、网络等）；**Performance**（玩家会注意到的优化）；**Known Issues**（未解决问题的透明度）。（Phase 3）
R11. **开发者语言 → 玩家语言**，原文示例："Refactored damage calculation pipeline" → "Improved hit detection accuracy"；"Fixed null reference in inventory manager" → "Fixed a crash when opening inventory"；"Reduced GC allocations in combat loop" → "Improved combat performance"。删除纯内部改动（不影响玩家的）；平衡变更**保留具体数字**（damage: 50 → 45）。（Phase 3）
R12. 三种样式模板：**Brief**（New / Changes / Fixes / Known Issues 要点，Changes 带 before → after 值）；**Detailed**（Highlights 1-2 句、New Content 每特性 2-3 句、Balance 用 `| Change | Before | After | Reason |` 表、Mechanics、Quality of Life、Bug Fixes 按系统小节、Performance、Known Issues）；**Full** = Detailed + **Developer Commentary**（第一人称团队口吻：为何做、考虑过什么、学到什么）。（Phase 4）

### Phase 5-7 — 自查、保存与下一步
R13. 生成稿自查清单：无内部行话（技术词换玩家友好语言）；无内部系统、工单、冲刺号引用；平衡变更带 before/after 值；bug 修复描述**玩家体验**不是技术根因；语气匹配游戏调性（按游戏风格调正式度）。（Phase 5）
R14. 展示完成说明，附：按类目的变更计数、**被排除的内部改动清单**（供评审）。问 "May I write these patch notes to `docs/patch-notes/[version].md`, and an archive copy to `production/releases/[version]/patch-notes.md`?"——yes 写两份（需要时建目录）；no **一份都不写**。（Phase 6）
R15. Verdict: **COMPLETE** — patch notes generated and saved（写盘被拒则为 generated and shown, not saved）。发布前跑 `/release-checklist` 验证其余发布门禁；公开发布前把草稿交 **community-manager** 做语气评审。（Phase 7）

## 4. 门禁与裁决
- **Verdict**：`BLOCKED`（溯源零 Game commit，或无 changelog 数据且无历史）/ `COMPLETE`（saved 或 shown-not-saved）。
- **溯源硬门禁**：与 `/changelog` 同构——逐条过滤、零 Game 即停；本技能额外明确 Framework 提交"排除但不触发停"。
- **数据依赖门禁**：内部 changelog 缺失时引导先跑 `/changelog`，不凭空编造。

## 5. 移植建议
- **可直接移植**：R1-R5（溯源三分类 + 交叉验证）、R8-R9（语气指南三处检测、外部模板替代内置样式且"类目不丢弃"）、R11（翻译对照表原则：症状不写根因、数字要保留）、R13（自查清单）、R14（双写路径 + 排除项供评审）。
- **需替换概念**：CCGS framework 提交 → 工具链/CI/脚手架提交；community-manager → 对外文案评审角色；`design/balance/`、sprint 回顾 → 产品的变更记录；游戏"调性" → 产品品牌语气。
- **改写示例**：
  - R11 → "对外变更说明只写用户能感知的结果：'重构了 X 管道'要写成'X 更准了'，'修了 Y 的空引用'要写成'打开 Y 不再崩溃'；纯内部改动直接删除，参数调整保留前后数值。"
  - R9 → "项目若提供对外文案模板，模板替代默认结构：逐类目映射到语义相同的节，无对应节的类目并入最接近的节且绝不丢弃，模板头尾保持原样，并在输出中声明用了哪个模板。"

## 6. 关联文档
- 上游：`/changelog`（内部 changelog 是首选数据源；溯源规则与它**成对维护**——改一起改）。
- 下游：`/release-checklist`（发布前验证）；community-manager 语气评审；`/launch-checklist` 的 "Patch notes for launch version published" 项。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/technical-preferences.md`、`docs/patch-notes-template.md` / `.claude/docs/templates/patch-notes-template.md`（存在时）。
