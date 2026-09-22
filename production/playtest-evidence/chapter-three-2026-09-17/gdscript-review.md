# 第三章（涨潮）GDScript 独立复核

限定 Verdict：CHANGES REQUIRED（窄范围）。发现 1 项 P1（潮墙半场覆盖）与 1 项 P2（淹没切换栅格重锚定的一次性双区重叠），二者均为小改且不触及快照 ABI；其余复核面（静态类型、派生状态、快照一致性、三章互斥、目录/JSON 一致性、分层对称、测试改动正当性）全部通过，未发现 P0。按本项目第二章复核先例（存在未关闭 P1/P2 即为阻断），在上述两项修复或获设计确认前不建议冻结。本报告只裁决 CAMPAIGN_GAMEPLAY_V1 限定下的代码/配置与本人独立执行的验证，不代表商业、真人体验或 20 小时验收。

## 复核范围

- 新增：src/campaign/campaign_chapter_three.gd；tests/integration/campaign_chapter_three_test.gd、campaign_chapter_three_rewards_test.gd、campaign_chapter_three_journey.gd
- 修改：src/campaign/campaign_chapter_two.gd（L47 互斥）、campaign_encounter.gd（preload/schema/valid_definition 分支/advance 淹没派生/valid_state 委托）、campaign_arena.gd（damage_enemy hp_before+Tide.hunt_damage、emit_layout_root 潮池着色与 tide_flat 标记、teaching_text 委托）、campaign_combat.gd（_boss 派发 tide_boss）、campaign_arena_render.gd（潮池外圈与淹没内圈 draw_arc）、tools/campaign/build_catalog.py（apply_chapter_three）、tests/integration/campaign_combat_test.gd（L174 过滤）、campaign_package_e_test.gd（L79-83 断言更新）
- 基准：design/chapter-three-playable.md、docs/architecture/adr-0011-chapter-three-tidal-encounters.md

## 独立验证（本人执行）

Godot v4.7.1 headless，探针仅写 /tmp，未修改项目源码/配置/历史证据：

1. /tmp/ch3-tide-wall-probe.gd（seed 4242，rank 0，M03-08）：phase 2 齐射 8 齿+8 池与正式测试一致；解析命中——boss 出生点 (500,-80) 0 命中、南侧 (500,-300) 0 命中、北带 (390,300) 1 命中、中线 (175,0) 1 命中；自然 bot 战斗 1460 tick 胜利，墙激活 555 tick 中 405 tick（73%）玩家位于 y<-50 墙带之外。PASS（结论见 P1）。
2. /tmp/ch3-flood-transition-probe.gd（seed 909，M03-05，带保活）：tick 460 拆印（451 发射的区存活至 691）→ tick 481 同 flat 出现第 2 枚区，双区状态 validate_snapshot 通过；反向时序 tick 242 拆印 → 首次涨水推迟至 481，静默 238 tick（正常休潮 210）。PASS（结论见 P2）。
3. 静态/数据交叉核对：campaign_game.json missions[16:24] 旗标/chapter/scene 绑定/roots 参数（90/150/210、offset 0/150/300、radius 80、damage 4）/xp 6/4/180/tide_boss 六参数/tier 门 [0,8,24,40,56]/target_ids 身份（:HUNT、:T1..T3、S1-B03）逐一与 build_catalog.py、Tide.valid_definition 及运行时赋值比对，全部一致；未旗标任务对六种 kind 仍有 6-9 个样本（L174 过滤不掉类）。
4. 完整套件（ch3 机制 196/0、rewards、Combat 287/0、包E 466/0、ch2 回归、旅程）数字引用主线程提供的通过结果；因 ch3 旅程后台运行中（CPU 竞争），本人未整体重跑，不将该结果冒称为本人独立执行。本环境未安装 gdtoolkit（gdlint 属 CI 侧），静态检查以人工通读完成。

## P1（应修，阻断冻结）

### P1-1 潮墙仅覆盖半场，且锚定世界原点而非 Boss

- 位置：src/campaign/campaign_chapter_three.gd L38（齿原点 `Vector2(direction*(tooth_spacing*(i+1)-40.0), 0.0)`，世界绝对坐标）、L40-41（`z.angle=PI/2`、`z.length=arm_length`）；配合 src/campaign/campaign_combat.gd L307-308（`line` zone 从中心**单向**延伸 `center + from_angle(angle)*length`）。
- 事实：齿列锚在 y=0、单向上行 1250，有效墙带为 y∈[-50, 640]（半径 34+玩家 16 缓冲），南半场（y<-50）永远无墙；齿 x 位置为世界原点两侧 ±175/±390/±605/±820，与 Boss/玩家位置无关（Boss 出生 (500,-80) 恰在墙带之外，探针 0 命中）。
- 证据：探针 1——自然 bot 战斗中墙激活时间的 73% 玩家根本不在墙带内（bot 并非在躲墙，是纯几何未覆盖）；Boss 自身出生点不被自己的墙覆盖。arm_length=1250≈全场高 1280 的跨度，但锚定 y=0 单向时覆盖半场仅需 640——参数值与锚点语义不自洽，支持"按全高计算了长度、锚点/方向配错"的实现缺陷假设。
- 设计对照：chapter-three-playable.md 与 ADR-0011 均只说"潮墙左右交替、齿间为穿越窗口、几何参数数据化"，从未描述"半场墙"或"南侧安全通道"；教学文案"潮墙左右交替；从齿列之间的缺口穿越"为无条件表述。campaign_chapter_three_test.gd L75 只断言 delay/angle/length，不钉覆盖语义——改成全高墙该测试同样通过，说明覆盖意图未被任何测试固定。
- 影响：M03-08 招牌机制在自然战斗中约 3/4 激活时间对玩家无威胁，"穿越窗口"仅在北半场有意义。
- 建议（二选一）：(a) 修复为全高——每齿上下两段、或锚 y=-625 长 1250、或以 Boss 所在行为基准——并补覆盖断言（如 Boss 位置必须命中至少一齿，或显式豁免并注明）；(b) 设计确认半场意图后在 ADR-0011 记录锚点/覆盖语义并同步教学与简报文案。zone 为通用持久字典（x/y/angle/length），修复不触及快照 ABI，冻结后修改也不破坏旧档。

## P2（建议，随 P1 一并处理）

### P2-1 淹没切换的周期栅格重锚定产生一次性双区重叠（附带静默延长）

- 位置：src/campaign/campaign_encounter.gd L150-152——cycle 由 450 变 240 时发射条件 `(tick-offset-1)%cycle==0` 整体重锚。
- 事实：拆印落在上一区存活期内时，下一个 240 栅格点可在旧区存活期间对同一 flat 再发一枚区。探针 2：tick 460 拆印 → tick 481 双区并存（tide_flat=0 ×2），双区状态快照合法、可跨存档持久化；两区 active 相位重叠约 120 tick，flat 伤害 4→8 翻倍，而拆印位置就是 flat 中心（玩家正站在那里）。反向时序（休潮期拆印）首次涨水最多推迟约 30 tick 出现（静默 238 vs 正常休潮 210），与简报"立即失去休潮、永久翻涌"表述有出入。
- 定性：设计明言"淹没不删除已发预警"，在飞区存活本身是被容忍的；但 451→481 的加密发射是栅格重锚的算术产物，不是"周期 240 无休潮"的节拍表述。有界（每 flat 一次性）、确定性、快照安全，故 P2 而非 P1。
- 建议：发射前若同 flat 已有存活区则跳过该次发射（仍可从 tick 派生，不违反"无第二时钟"约束），或在 ADR-0011 记录该过渡节拍为预期行为。

## P3（记录，不阻断）

- [P3 调参口径] Tide.boss 在 tide_boss 六参数之外仍硬编码：campaign_chapter_three.gd L38 齿内沿 -40 偏移、×1.2 伤害、0.8s 墙持续；L44 池环 220/65/×0.5/4.0s/0.9s 预警；L46 12 弹幕/170 速度；L30 与 campaign_combat.gd L173、campaign_chapter_two.gd L30 三处重复的 zone 上限魔数 128。与 ch2 复核对 furnace_boss 的同类 P3 一致，建议后续并入配置统一调优。
- [P3 击杀跨阈值] campaign_chapter_three.gd L12 `e.hp <= 0: return`——致命一击同时跨越的阈值不发悟性（从 2/3 以上一击致死则两段 8 均无）。与 ch2 行为对称（ch2 存 phase 同样不补发死亡击），仅极端爆发场景可达，记录即可。
- [P3 隐式约束] L16 `e.timer = float(e.cooldown)` 的打断语义依赖 S1-E03 attack_cooldown(2.8) > burrow 切换间隔 1.6（campaign_combat.gd L368 硬编码）。若未来 hunt 精英 cooldown<1.6 会反向缩短出水窗口；该约束未在 ADR 或配置校验中表达，建议补记。
- [P3 schema 缺口] campaign_encounter.gd L25 黑名单与 L31 拒绝列表均未含 `hunt_phase_xp`——ch1/无旗标任务携带该字段可通过 valid_definition 且运行时无读取（惰性）。建议并入 L31 列表闭合。
- [P3 跨章标记] campaign_arena_validation.gd L112-117 不白名单 zone 字典键——ch2 快照携带 tide_flat 标记（或反向）可通过校验并作为惰性键恢复。与 ch2 完全对称，非本章回归。
- [P3 域风格] campaign 域自 ch1 起一致使用 `:=` 推断（编译期推断，无 Variant 推断风险点：全部推断源为 int/float/Dictionary 字面量或 typed 调用；`var index: Variant = z.tide_flat`、`var flooded: bool` 等易错点均已显式标注）。与全局"显式类型注解"标准的偏差为既有域风格，本轮未发现实际类型安全问题。

## 重点核对结论（通过项）

1. 静态类型/惯用法：无 Variant 推断风险；参数 duck-typing（`hunt_damage(a, e, before)`）与 ch1/ch2 模块一致。
2. flat_flooded 派生：仅由 tick+completed_ids 派生（encounter L150-152），ch3 的 encounter dict 保持 6 字段（valid_state L188 的 7/6 形状检查证明无第二时钟入快照）；稳态淹没周期 240 与区寿命 240（delay 90+ttl 150）精确咬合，advance_zones 先于 Encounter.advance 的执行顺序保证同 tick 过期+重发无缝。
3. hunt_damage 阈值跨越：campaign_arena.gd L560 在 L561 扣血前捕获 hp_before，L563 仅 ch3 传 before；gained 为单次伤害前后相位差，跨两阶段一次发 16；恢复后无伤害事件故不重发（rewards 测试 L29-34 已正式化——正是 ch2 复核 P3"正式负向覆盖"建议的落实）；S1-E03 为 burrow 无治疗路径，HP 单调、阈值不重跨。L549 burrow 相位免伤保证奖励仅在出水窗口触发。
4. Boss aim 侧别：aim∈{0,-1,1} 由 valid_state L83 钉住；side 由 aim 推导后翻转（初始 0→首墙东侧）；phase 2 双侧齐发（wall 0 用 side、wall 1 用 -side）；阶段突破 XP 在 timer/容量闸之前结算（L22-25 先于 L30），容量预检 `zones.size()+columns*walls+pools>128` 覆盖整轮齐射，容量满时不消耗冷却、不部分发射（测试 L110-112 实证 127+16>128 全不发、timer 保持 0 下 tick 重试）。
5. snapshot/codec：tide_flat int 标记走通用 Codec 镜像；valid_state L68-73 将 tide_flat 区逐字段（center/radius/damage/duration=active_ticks/60）绑回 layout.roots；负例闭合——错 hunt 实体 id、清空实体、篡改 tide_flat 索引+重算 numeric_bits、篡改 boss family 均被拒（测试 L28-33/L48-51/L62-64）。
6. 三章互斥链（全部入口闭合）：Tide.valid_definition L50 拒 chapter_c+chapter_two；Thermal L47 拒 chapter_three；encounter L24-26 非 chapter_c 字段黑名单 + L31 无旗标任务拒 furnace_boss/thermal_anchors/rest_waypoint/tide_boss/tide_flats/hunt_enemy_id（chapter_c+chapter_three 组合经 Tide L50 拒；chapter_c+tide_boss 经 L31 拒）；schema() L9-11 的优先序在互斥成立后无歧义；configure 为唯一入口，profile 复用同一 gate。
7. build_catalog.apply_chapter_three ↔ JSON：8 关旗标、scene 绑定（16-19 harbor / 20-23 court）、roots 参数、xp 6/4/180、tide_boss 六参数与 valid_definition expected 完全一致；tier 门 [0,8,24,40,56] 与"24 关三阶、40 关四阶"一致；mission 19 净化圈 [440,60] 与潮池 [480,-40] 距离 107.7<170，"南圈与潮池相叠"成立。
8. 分层对称：ch1（有状态 encounter.chapter）→ ch2（无状态 helper+实体存 phase）→ ch3（无状态+零奖励账本）逐层去状态化；teaching/valid_definition/valid_state 三件套与 ch2 对称；ch3 比 ch2 多钉 boss aim 合法值、少一个 phase↔HP 一致性检查——后者正确，因相位字段已归潜地行为专用（设计明文）。

## 测试改动正当性判定

- campaign_combat_test.gd L174（过滤扩至三章旗标）：正当。ch2 轮已认可同型调整（通用目标夹具不得冒充专有有限遭遇验收）；未旗标任务对 SURVIVE/BREAK/CLEANSE/HUNT/ESCORT/BOSS 仍有 6-9 个样本，过滤不掉类。
- campaign_package_e_test.gd L79-83（"ch3 保留旧默认 2+1"改为"ch3=6 且 ch4 index24=默认 2"）：正当。ADR-0011 明文"第三章沿用 6+4 递增悟性、3 秒升级间隔"，build_catalog 与 JSON 均为 6/4/180——旧断言与设计文档矛盾，属测试假设过时而非实现回退；新断言额外钉住 ch4 回归默认曲线的边界，覆盖强于旧断言。方向是"设计决定取代测试假设"且新增边界，非"改测试迁就实现"。

## Verdict

CHANGES REQUIRED（窄范围）：修复或设计确认 P1-1 潮墙覆盖语义，并处理 P2-1 淹没过渡节拍（二者均小改、不触及快照 ABI）；此后短程复核（重跑 ch3 机制测试 + 一次 M03-08/M03-05 定向探针）即可转 APPROVED WITH SUGGESTIONS。其余全部复核面通过；P3 六条仅记录。保留 battle_ready=false、新玩家试玩 SKIPPED_BY_USER；本报告不补齐 Windows/Steam、商业 Save V2、真人试玩与性能验收。
