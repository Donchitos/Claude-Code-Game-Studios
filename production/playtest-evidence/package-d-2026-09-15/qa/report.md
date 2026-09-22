# D 包独立 QA / 首章可玩性证据复审

日期：2026-09-15。独立 verdict：**CHANGES REQUIRED（验收覆盖有缺口；D 玩家验收未完成）**。

范围：冻结 dirty worktree 的 A–C Campaign 开发入口，不以 HEAD 冒充实现。已完整阅读首章整改设计、ADR-0008、C 报告、C 专项/旅程及机器人实现，并核对相关 B 测试、Arena、Encounter、ChapterOne、Mission。依 code-review skill 只读审查生产代码；本目录仅新增获授权的 QA 报告和隔离探针。其他引擎/UI专家由主评审协调，本报告不代替其 verdict。

## 当前可确认的结果

- `freeze-check.json`：review-freeze.json 中 57 个文件全部匹配，无生产修改。
- 独立重跑 `campaign_package_c_test.gd`：**237 checks PASS**，日志 `c-specialist-rerun.log`。其中 179 次同一容量填充断言占很大部分，237 不是 237 条独立行为分支。
- 复制 C journey 到本目录并改输出路径，增加**每个实际推进 tick 的快照有效性检查**、选择间隔记录：飞剑合法新档旅程 8/8 胜、46 次真实双槽重载、全程未见非法快照，结果 `journey.json` / `journey-probe.log`。未覆盖或改写 B/C 历史 JSON。
- 对历史两路线原始 JSON 核对后，46+45=91 次真实恢复、06 自然进化/多主动、Boss 各阶段预警记录确实成立。它们支持“这些种子和策略可通关且若干边界可重载”，不能支持全部必要分支的恢复等价，更不能支持真人理解、乐趣或难度结论。
- 真人证据当前 **0**。用户本人将先试玩；后续新玩家另行补齐。设计要求至少 3 名新玩家，不能自动把熟悉项目的作者/用户计作新玩家。

## 必须保留的发现

### QA-D-01 · P1 · 选择后 3 active 秒的明确行为约束未实现

位置：`src/campaign/campaign_arena.gd:304`、`:368`、`:379`；设计 `design/chapter-one-playable-redesign.md:88`。`choose_upgrade` 清理候选后同步调用 `_check_levels()`，没有间隔 tick 或持久化等待状态。

复现：`edge_probe.gd` 的 accumulated_xp 是明确标记的合成积压 XP 夹具；第一次候选正确含 A01/A02/A03，但选择后在 **tick 1→tick 1** 立即出现第二组。更强的自然证据来自本次合法 journey：01 两次选择仅隔 **5 tick / 0.083 秒**；05 为 9 tick；06 有 13、40、72 等小于 180 tick 的间隔。不是只靠修改 XP 才能触发。

影响：即使选择耗费真人数秒，恢复战斗后仍可能立刻再暂停，缺少操作与观察新技能的窗口。C 报告已诚实披露，因此不是 C 隐瞒或 ADR 违规，但仍是原整改目标的实际未完成项，不能给 D 全量通过。

整改应实现并保存间隔及积压提示，同时验证终态优先、事件排队和恢复。不能简单提高全局 XP 门槛作为替代；当前 `assets/config/campaign_game.json:9388` / `:9389` 仍为 2/1，首章 6/4 实验亦未实施（ADR 明确记录该延期）。

### QA-D-02 · P1（证据门）· 91 次重载没有覆盖所声称恢复语义的必要分支

位置：`tests/integration/campaign_package_c_journey.gd:50–68`；`campaign_package_c_test.gd:56–66`、`:99–106`。

journey 每次只比较“当前 snapshot == 重载 snapshot”，随后销毁原 Arena；不存在未中断对照分支。它仅由 stage_ticks / clues / root_mask / attacks / event 变化触发保存；不以猎物 phase、retry、升级 offer、净化 hold、Boss landings 消费变化为触发。初始化 last_stages 的数组形状与后续不同，还会额外计入首个 step 的重载，因此恢复次数不等于独立分支数。

C 的 200 tick 对照只对 **05–08、tick 180、零移动** 各运行一次，04 不在该循环内。半程单测只测 `Encounter.reached` 布尔函数；容量耗尽单测同一个 tick 连续直接调用 `Chapter.advance`，绕过真正的 Arena/Encounter active tick 和暂停路径。它证明有限计数逻辑，不证明 60 active tick、Root fault、磁盘旧槽保全的端到端行为。

补测最低矩阵（不要求用次数凑数）：

| 状态 | 所需证据 |
|---|---|
| 04 clue 1 等升级 / 安全与风险两分支 | 真双槽重载后事件恰好一次，收益/压力与未中断分支一致 |
| 04 猎物未生成 / 活着四个冲锋子态 / 死亡 | 身份与计时不变，至少 200 active tick 连续对照；终态若不足则到终态 |
| 04 retry 1 / 59 / 60 | 真实 step 驱动，暂停不计数，恢复不重置；Root 受控错误且前后双槽 hash 不变 |
| 05 开始 / 半程±1 tick / 离圈暂停 / 区域完成 | 生成消费和计时恢复一致，不补刷 |
| 07 mask 0 / 1 / 3 / 7，预警中与生效中拆锚 | 旧 root 不复活、下一锚不提前受击，含真实磁盘+连续分支 |
| 08 各阶段 pending 警告 / 第二落点前后 / 死亡前后 | 落点、zones、RNG 与未中断分支一致；断言实际发生的攻击而非仅已安排次数 |

本次逐 tick 正常旅程没有发现新的非法自生成快照；上述是明确覆盖不足，不是声称每个分支已有运行故障。

### QA-D-03 · P2 · 构筑/教学节奏只在 06 集中，短关可能完全不选择

历史两路线升级选择次数：

| 任务 | 飞剑 | 多主动 | 设计诊断带 |
|---|---:|---:|---|
| 01 | 2 | 4 | 3–6 |
| 02 | 1 | 0 | 3–7 |
| 03 | 4 | 4 | 3–7 |
| 04 | 1 | 0 | 3–8 |
| 05 | 2 | 4 | 3–8 |
| 06 | 17 | 18 | 6–10 |
| 07 | 1 | 2 | 3–8 |
| 08 | 1 | 0 | 4–8 |

设计 `:87` 明确这是诊断带而非硬通关条件，不能把越界次数直接定成代码 bug。初始候选包含三主动已实现；仍未证明新玩家实际发现拾取、完成首次选择并理解效果。两路线总 active 时长分别约 4.66 / 4.58 分钟，不含任何阅读/选择/结果页时间，也没有理解或求助指标。合法自然进化只出现在 06；其余关常在构筑出现前结束。D 必须据真人行为解释这些数据并迭代，不能为了凑选择次数加隐形 XP 或强制等待。

另一个测试缺口：两套 journey 都在 `campaign_package_c_journey.gd:20–21` 有钱即购买所有三脉一阶；不能证明设计 `:80` 的“任意一脉优先或暂不购买也能完成首章”。需补相应合法完整路径，而非只在孤立关卡配置零三脉。

### QA-D-04 · P2（体验诊断）· 静止也能击败 Boss，三阶段预警计数不等于实际机制体验

`edge_probe.gd` 中 mission 08：目录原值、completed=7、零三脉、无药、seed42；全程零移动，仅在暂停时选择首个合法升级。**18.33 秒胜利**，最终 HP 90.688，累计受伤 107.712；技能 A01 达 4 级。该测试是合法关卡加载的边界诊断，未冒充从新档打来的完整旅程，也未修改敌人、伤害、速度。

phase 3 首次预警 tick 1095，死亡 tick 1100，仅 **5 tick**；`chapter.attacks=[3,4,1]` 在 `src/campaign/campaign_chapter_one.gd:87–93` 于安排预警时增加，不能据此判定玩家经历了第三阶段实际落点/围堵。第三阶段 hits=0 也不能据此认定玩家成功规避。

其它零移动关卡 01/04/05/06/07 均活到其 380–410 秒 timeout（选择由脚本完成），表明目前等待也可能长时间没有失败压力。但这是单种子输入策略诊断，不是“所有玩家无需操作”或乐趣失败的统计结论。应在 D 记录新玩家是否需要移动/反击、是否理解第三阶段，再决定数值/遭遇调整；不要以新增不可跳过无敌条来延长 Boss。

## AC 与当前证据边界

- 布局、01–03有限遭遇、04线索机缘、05累计净化、07关根、08无免伤门：实现/局部测试可见；UI可读性和引擎全面安全由对应独立专家评审。
- 04 target identity、05阈值、07 mask、C rejected config：局部专项 PASS；端到端分支覆盖见 QA-D-02。
- 两种合法构筑及至少一条自然进化：有正面证据，不应否认。
- 两路线都采用安全事件（journey `:48`），风险数值单测不等于风险整章旅程。
- 任意窗口视野外生成：ADR/C 明确未实现；仍需工程整改，不能由 D 真人观察替代几何保证。本 QA 未重复其他专家的几何探针。
- 零真人意味着新玩家理解、乐趣、求助和完整时间组成全部待采；无 Windows/Steam/商业 Save v2 / 20小时内容 / battle_ready 新证据。

## D 真人执行要求

用户先试玩可记录操作问题、路径和意见，但保留其熟悉程度。另招募至少 3 名新玩家，按人记录版本hash、设备/窗口、首次进入各关时间、active战斗、选择阅读、迷路/停顿、结果与备战、退出恢复、失败/重试、求助原话、选择理由及喜欢/困惑点。允许自然失败与不购买；不要用机器人路线指导新玩家，不把代操作或主持人提示算独立理解。

需要判断“理解→操作→反馈→成长”的链是否实际发生，而不只是每个任务显示 victory。真人尚未完成时保持 **D OPEN / In Review**。

## 复现入口与证据

在仓库根目录执行（Godot 4.7.1）：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script production/playtest-evidence/package-d-2026-09-15/qa/journey_probe.gd -- --qa-production-evolution
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script production/playtest-evidence/package-d-2026-09-15/qa/edge_probe.gd
```

`edge-results.json` 区分 synthetic XP fixture 和 idle legal steps；`journey.json` 是独立复跑输出。`supplemental-sha256.json` 绑定实际使用但未列在 review-freeze 的 Bot 与本报告探针。未写生产文件，未使用玩家存档，未覆盖 B/C 历史证据。
