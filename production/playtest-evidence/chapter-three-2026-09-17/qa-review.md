# 第三章（涨潮）战役扩充独立 QA 复核

日期：2026-09-17。复核人：qa-lead。对象：S1-M03-01..08 八关增量代码、潮汐机制、阈值跨越奖励、局部经济校准及其全部自动化测试证据。设计基准：design/chapter-three-playable.md、docs/architecture/adr-0011-chapter-three-tidal-encounters.md；措辞纪律对照 production/playtest-evidence/chapter-two-2026-09-16/qa-review.md。

内容绑定：campaign_game.json sha256 前 12 位 `44fab78cd781`（与主线程 runs/44fab78cd781/ 目录及各 run.json 的 content_hash 一致），Godot 4.7.1-stable。本 QA 所有复跑在此内容上执行，未修改项目文件与历史证据。

## 独立复跑结果

以下为本 QA 独立执行（非转引主线程日志），均以 `grep -c "SCRIPT ERROR"` 独立核验：

| Suite | 结果 | 日志 |
|---|---|---|
| campaign_chapter_three_test.gd | 196 checks / 0 fail，exit 0，16 场胜利矩阵全胜 | /tmp/ch3-qa-mechanics.log |
| campaign_chapter_three_rewards_test.gd | CH3_THRESHOLD_XP_RESTORE_NO_REPEAT_PASS，exit 0 | /tmp/ch3-qa-rewards.log |
| campaign_package_e_test.gd | checks=466 failures=0 accepted=438，exit 0 | /tmp/ch3-qa-package-e.log |
| campaign_terminal_disk_test.gd（`-- --campaign-validation`，evidence 隔离于 /tmp/ch3-qa-terminal） | TERMINAL_DISK_PASS：victory tick4490 / timeout tick22801，两模式 preterminal_replay_equal=true、duplicate_settlement_zero_write=true、settlement_failure_zero_write=true；0 SCRIPT ERROR（两行 STORAGE_COMMIT_FAILED_2_RELOAD_REQUIRED 为注入结算 IO_ERROR 场景的预期输出） | /tmp/ch3-qa-terminal-disk.log |
| campaign_precision_roundtrip_test.gd | PROFILE_20_RELOAD_SETTINGS_SNAPSHOT_EXACT_AND_STALE_REJECT_PASS，exit 0 | /tmp/ch3-qa-precision.log |
| campaign_chapter_three_journey.gd（seed 711，evidence 隔离于 /tmp/ch3-qa-journey） | 运行中——主线程 12:24 实例被外部终止且未产出任何结果（见 P2-1），本 QA 重启的独立执行截至定稿未结束 | /tmp/ch3-qa-journey-safe.log |

主线程提供的回归全景（本 QA 未重复执行，引用）：ch3 机制 196/0（与本 QA 独立复跑一致）、rewards PASS（一致）、Combat 287/0、包 A135 / B132 / C237 / D-fix40 / E466（与本 QA 复跑一致）/ G58 / Root PASS、Profile 581/0、Content 1170/0、BossEntry 130/0、Pacing PASS、UpgradeGuard 9/0、SnapshotSafety 225/0、ch2 机制 246/0、ch2 旅程 PASS。

catalog 数据核对：8 关 chapter_three 全部 xp_base=6 / xp_step=4 / upgrade_interval_ticks=180，tide_flats 仅 M03-05、hunt_phase_xp=8 仅 M03-02/07、tide_boss 仅 M03-08；两张布局 roots 均为 (90,150,210) 错峰 offset 0/150/300、damage=4；index 24 = S1-M04-01（chapter 4，无 xp_base/xp_step，走默认 2+1）。与 ADR-0011 逐项吻合。

## Findings

### P0

无。

### P1

无。

### P2

1. **冻结门两项未闭合：ch3 旅程安全路线（seed 711）与 alternate 路线（seed 977）均无完成结果。** ADR-0011 Acceptance Criteria 明确要求"真实1→24两路线"与"终局失败写盘"作为验收项，Consequences 明确"两条新档1→24连续路线是自动证据"——旅程是 AC 必需项而非可选回归。撰写本报告期间发现：主线程 12:24 启动的安全路线实例已死亡——无 journey.json 落盘、无 /tmp/ch3-failed-restore.json 失败 dump、进程消失，判定为被外部终止（与终端超时清理事件同期），既非测试失败也非 PASS，该次运行不产生任何可用证据。本 QA 已随即以隔离 evidence root（/tmp/ch3-qa-journey）重启独立执行（seed 711），截至本报告定稿仍在运行。在两条路线 journey.json 落盘且 PASS 前，不得执行源码冻结。本 verdict 以此为前提条件。
2. **机缘风险分支的旅程覆盖依赖 alternate 的运行参数。** journey 代码中 `--risk-route` 与 `--alternate-build` 是独立开关：安全路线固定 `choose_event(false)`（稳妥），若 alternate 启动时不附带 `--risk-route`，则 M03-03 中段机缘的"冒险"分支（true）在旅程层零覆盖（fixture 层也只测了 false + event_count==1）。ch2 先例（"第二角色/风险"路线）是双变化合并跑的。要求：启动 alternate 时确认命令行含 `--risk-route`；否则机缘风险分支需另行补证。

### P3

1. **潮池 zone 的 delay 未与布局 warning_ticks 绑定。** campaign_chapter_three.gd `valid_state` 对 tide_flat zone 校验 x/y/radius/damage/duration 匹配 layout.roots[index]，但不校验 `z.delay == row.warning_ticks/60.0`。篡改快照的潮池预警时长可通过验证，恢复后预警窗口被改。这不是 ch3 回归——ch2 thermal_vent（campaign_chapter_two.gd L70）同样不查 delay，属两章共有的验证边界。建议下轮与 ch2 一起统一补绑定与负例。
2. **boss phase 与 hp 的派生一致性未绑定。** Tide.boss 的 phase 恒等于 `mini(2,int((1-hp/max_hp)*3))`（真实路径无其他来源），但 valid_state 不校验；篡改 e.phase=0 且低 hp 的快照恢复后 boss() 会按 `phase > e.phase` 重发 36 XP。ch2 的 HUNT 精英有同款派生绑定先例（campaign_chapter_two.gd L81），ch3 boss 可零成本补上。同样非回归（ch2 boss 亦无）。单机主动篡改场景、经济自作弊性质，P3。
3. **hunt 打断机制无直接断言。** hunt_damage 中 `e.timer = cooldown`（阶段突破打断回潜、延长出水窗口）是 M03-07 的核心设计，rewards 测试只断言 XP 数值，未断言 timer 被重置。建议补一行断言。
4. **boss 容量边界正例缺失。** 127 满容量不发射（含精确 `==127` 断言防部分发射）已测；"恰好 112+16=128 允许全量发射"的边界正例未测（若实现误写为 `>=128` 拒绝，现有测试不会发现少发一轮）。低概率、易补。
5. **包E断言 label 措辞与 checks 数披露。** 见下文"测试假设取代设计"一节：改动正当，但 "curated six-plus-four curve" 的 "curated" 措辞与 ADR"此次不改全游戏经济价格曲线"的临时性定位不符，建议改为反映"局部沿用 ch2 曲线、全局重平衡延后"的表述，且证据链需披露 465→466。
6. **非 BREAK/boss 关的潮池相位边界采样为 incidental。** journey fingerprint 的 tide 维度只对 index 20（tick%450>=90）与 index 23（aim<0）生效；M03-01/03/04/06（含潮池相叠净化的 M03-04）的潮池相位边界恢复验证依赖其他分量触发 + 200 tick 对照窗。正确性风险低（潮池完全由 tick 与 completed_ids 派生、无第二存储，campaign_encounter.gd L145-153 已核对），属覆盖密度问题，注明即可。
7. **流程备注：主线程此前的 terminal-disk 后台实例未带 `--campaign-validation` 参数。** 该测试第 38 行 `assert("--campaign-validation" in OS.get_cmdline_user_args())` 在 headless 下失败只打 SCRIPT ERROR 不中止，按项目纪律（ch2 报告："exit0但有ERROR的日志不算最终通过"）该次输出不可采信，且进程已消失无日志留存。本 QA 已带正确参数重跑并 PASS，可作正式证据。建议后续所有 terminal-disk 调用固定携带该参数。

### 关于两个假想负例的结论（复核重点 1 的边界讨论）

- **"拆闸印后篡改 completed_ids 伪造淹没"**：不需要也无法新增负例。结构自洽的伪造（completed_ids + completion_order + progress + 删除对应实体四方耦合全部一致）在验证上不可区分于真实历史——ADR-0011 定义 completed_ids 为唯一权威（"全部由tick与completed_ids派生"），validation 的合同是拒绝结构不一致而非证明历史真实。真正的结构负例（实体存活却标记 completed）已被 live/completed 耦合拒绝（Tide.valid_state L74-79，测试 L30-33 缺实体负例、L141-143 FIXED 顺序强制）。
- **"tide_flat 标记与实际淹没状态不一致"**：tide_flat 与淹没状态本就解耦——zone 是瞬态（休潮期可不存在），淹没由 completed_ids 派生。越界（<0/>2）与错绑定（几何不匹配 layout.roots）已覆盖（测试 L48-51）。残余缺口即 P3-1 的 delay 未绑定。

## 专项复核

### 1. 负例闭合（机制测试 196 checks 拆解核对）

已有负例：HUNT 身份伪装（entities[0].id 改 S1-E01 拒绝）、目标缺失（entities 清空拒绝）、tide_flat 错绑定（改 index 几何失配拒绝）、boss family 伪装（改 "enemy" 拒绝）、越序拆闸无伤害（ordinal!=1 hp 不变）、逐座拆闸的精确淹没集合（flat_flooded 逐池断言，未拆者保持 rest）、每步快照 validate、boss 侧别两轮交替（phase0 单墙东→西翻转直接证明 aim 持久化；phase2 双墙 4+4）、容量 127 精确不发射、致死不发射、M03-03 event_count==1 且 waypoint>=2。独立复跑 196/0 与主线程一致。缺口仅 P3-1/2/3/4 所列，无 P1 级以上洞。

### 2. journey 设计（复核重点 2）

- fingerprint 联合分量 `[stage_ticks, event_id, event_done, last_upgrade_tick, completed_ids, tide]`，任一变化触发 快照→validate→真实双槽写盘→free→重载→configure→逐字节快照相等→200 tick 双分支逐 tick 对照→重置恢复分支。结构正确。
- index 20 的 `tick%450>=90`：粗二值相位信号，拆闸瞬间由 completed_ids 变化必然捕捉（恰是周期 450→240 的切换点），相位翻转每 450 tick 提供两次额外采样。弱点：拆闸后实际周期 240 与采样信号 450 脱钩（P3-6 已注明），但 200 tick 对照窗覆盖 240 周期的大部分相位段，可接受。
- index 23 的 `entities[0].aim<0`：aim 取值 {0,-1,1}，首次发射 0→-1 翻转信号、此后每次发射在 -1/1 间翻转，即 boss 每次发射（cooldown 150 tick）都触发一次磁盘恢复对照——恢复点密度充足，且直接验证"侧别由实体 aim 携带"跨磁盘持久化，与设计核心一致。
- tier3 gate 断言位置正确：8..23 关每关 `assert(not purchase_branch(0))`（全程拒绝），24 关全胜后 `completed==24 and pages>=4` 时断言 tier3 可买、tier4（同支再购）拒绝，与"M03-08 胜利时达到 24 关三阶、四阶仍 40 关"吻合。gate 段有条件保护（非全胜则 journey 整体 FAIL 且 completed!=24 兜底断言），可接受。
- 失败路径写 /tmp/ch3-failed-restore.json dump（run 快照与原始快照并列）便于诊断，好设计；失败路径不清理 /tmp stem 属诊断用途可接受。

### 3. "测试假设被设计取代"的诚实性（复核重点 3）

**判断：改动正当，是净增强，但 label 措辞需修正、diff 需披露。**

- 正当性：ch2 冻结时包E把"ch3 未实现状态下的默认曲线 2+1"断言成了期望（"chapter three keeps the old default curve"），这实质是把未实现内容的当前默认值冻结为规格。ADR-0011 与用户批准的"本章范围局部经济校准"（ch3=6+4、全局重平衡延后）是后来的合法设计决定，测试必须跟随设计而非反之。旧断言与实现矛盾时保留旧断言等于用测试否决设计。
- 净增强：新断言不仅断言 ch3=6，还新增 index 24（S1-M04-01）=默认 2，把"局部校准不泄漏到后续章节"钉死为回归守卫。465→466 的 +1 即断言 1→2 条（本 QA 独立复跑 466/0 确认，2026-09-16 历史 log 为 465/0）。
- 更诚实的写法：label 去掉 "curated"（ADR 明说"此次不改全游戏经济价格曲线，富余资源不是已关闭问题"，6+4 是沿用而非精心策划终值），改为如 "chapter three reuses the chapter-two curve pending global rebalance"；并在断言处或证据报告中记录变更缘由与 checks 数变化。结构性教训：包级测试不应断言未实现内容的默认行为，若必须断言应标注 provisional/chN-pending，迫使实现时强制复查。
- 披露要求：本报告即为披露处——ch3 证据链引用包E结果时必须写"466（2026-09-17 断言更新后，原 465；ch3 局部经济校准见 ADR-0011）"。

### 4. 证据边界表述（复核重点 4）

可以说：fixture 胜利（8 关 × [0,0,0]/[5,5,5] 两成长档 bot 全胜，8.65-109.13 秒）；确定性恢复（每恢复点 200 tick 双分支逐 tick 快照对照）；机制按参数运转（周期 450/240 派生、错峰 150、伤害 4、阈值跨越 XP 16/36、恢复不重发、侧别交替、容量预检、越序免疫）；profile 层 tier3=24 / tier4=40 gate。

不能说：人类试玩体验；"错峰迫使更换安全滩/涨潮只剩月牙安全区"的策略体验强度（bot 有潮池规避评分但 fixture 只证明可通关与机制运转，未量化"迫使"）；20 小时时长（SCOPE-TIME-01 缺口仍在，需整章真人试玩）；Steam 验收；移动端。

既有措辞纪律良好：ADR Consequences 自带"两条新档1→24连续路线是自动证据，不是人类试玩或20小时验证"；run.json scope 字段"automated test evidence, not human or release certification"；journey JSON scope 字段"real new-profile sequential twenty-four missions, bot not human"。与 ch2 报告先例一致，本报告同样保留限定：新玩家 SKIPPED_BY_USER，battle_ready=false。

### 5. 测试自身质量（复核重点 5，对照 .claude/rules/test-standards.md）

- 确定性：机制测试固定 seed 711（本 QA 复跑 196 与主线程完全一致即为可复现证据）；journey 711/977 固定；Bot fixture 为纯确定性函数（17 方向枚举评分，无随机、无时钟依赖），choice/direction 均无外部状态。
- 隔离性：机制/rewards/包E全程内存 + arena free()；journey /tmp stem 含 ticks_usec 唯一化、成功路径清理双槽；evidence 目录 per-PID 原子创建不复用旧输出（campaign_evidence.gd），失败即断言。无跨 suite 顺序依赖（各 suite 独立进程）。
- 命名与结构：campaign 集成层沿用 ch1/ch2 的 SceneTree 脚本 + check() 计数惯例，非 GDUnit4 单测命名，属既有模式的延续而非本次新增偏差（单元层命名规范适用于 tests/unit/）。机制测试为场景化流水（arrange 内联），对该层可接受；逻辑类单测（如 flat_flooded、hunt_damage 的 gained 计算）若下沉 tests/unit/ 更符合分层纪律，非阻塞。
- 数值断言精确（==127、==196、event_count==1、east==4/west==4），无放宽比较；越序伤害用 hp 不变直接断言。

### 6. 补跑项判断（复核重点 6）

判断：**两个都必须跑，且 terminal-disk 不是"可选"**——ADR-0011 AC 明确列有"终局失败写盘"，且 catalog 从 56 关扩到 64 关触及 Profile 的 `completed` 边界（`_integer(l.completed,0,c.missions.size())`）与 content_hash 绑定链，回归面成立。本 QA 已带 `--campaign-validation`、evidence 隔离于 /tmp/ch3-qa-terminal 独立补跑：两项均 PASS（terminal-disk 两模式 tick 4490/22801 与 ch2 冻结基线完全一致，preterminal 逐字节重放相等、重复结算零写、结算失败零写；precision 20 轮往返快照严格相等 + 陈旧 writer 拒绝）。主线程此前的无参数实例输出不可采信（P3-7）。

## 冻结门清单

1. journey 安全路线（seed 711）出 journey.json 且 CHAPTER_THREE_JOURNEY_PASS —— 未闭合；主线程实例已被外部终止（无结果），本 QA 重启的独立执行运行中。
2. journey alternate（seed 977，须含 --risk-route，见 P2-2）PASS —— 未跑。
3. terminal-disk / precision-roundtrip —— 本 QA 已闭合（PASS）。
4. 以上完成后按 ch2 先例记录源码冻结 hash（当前 campaign_game.json sha256 前 12 位 44fab78cd781）与逐文件清单。
5. P3 项均不阻塞冻结，随下轮（建议与 ch2 的 delay/phase 绑定缺口合并为一个跨章验证补丁）。

## Verdict

**APPROVED WITH SUGGESTIONS** —— 限定：第三章增量代码、相关存档保护与本报告列明的自动 QA 范围（含本 QA 独立复跑的五项 suite）。机制、奖励、经济校准、终局写盘与精度往返的独立复核全部通过，发现的缺口均为 P3 级（其中两项为 ch2 既有跨章验证边界，非本次回归）。两个 P2 均为证据未齐而非代码缺陷：冻结动作必须以冻结门清单第 1、2 项（两条 1→24 旅程路线 PASS）完成为前提，本 verdict 不预支该结论。不代替真人试玩、20 小时时长验证、Windows/Steam 发布验收或全局经济重平衡结论；新玩家 SKIPPED_BY_USER，battle_ready=false。
