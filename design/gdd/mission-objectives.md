# Mission Objectives — Steam 1.0

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> Status: Design Baseline APPROVED / Implementation Gates OPEN（2026-09-11独立senior复核；见reviews/steam-contracts-2026-09-11/review-director-followup.md）。Owner: ST-S02。ADR-0006。六目标产品规则已选定，生产配置/owner snapshot与容量仍待实现前冻结。

## Overview

每个run安装一个Mission owner，消费已完成战斗tick的事实，判定任务目标、失败和超时，产生一个sealed结果。生存、破阵、净化、追猎、护送、Boss共享生命周期与结果接口，不再由任意Boss死亡直接结束游戏。

## Player Fantasy

玩家始终知道这次要做什么、进度如何、为什么成功或失败；主动目标完成后及时结束，不被强迫等待统一15分钟计时。

## Detailed Rules

### Definition与身份

`MissionDefinitionV1={schema:"1",mission_id,definition_hash,objective_kind,scene_id,timeout_ticks,objective_config,required_owner_ids[]}`。kind封闭`SURVIVE/BREAK/CLEANSE/HUNT/ESCORT/BOSS`；timeout_ticks为checked正int64语义，按Config指定，不默认900秒。未知kind、缺配置、零目标、重复target ID、不可达scene拒绝预检。

runtime身份`{profile_id,branch_id,run_seq,mission_id,definition_hash,instance_epoch}`；instance_epoch由本次恢复/创建重新签发，异于存档run_seq。输入事件的source generation不是run身份。目标ID在任务定义内唯一稳定，spawn重新生成只更新spawn epoch，不改变任务语义ID；旧对象/旧epoch事实拒绝。

### 六类完成与失败规则

| kind | objective_config | 完成条件 | 目标特有规则 |
|---|---|---|---|
| SURVIVE | survive_ticks>0；extraction区域ID | active_tick≥survive_ticks且玩家已进入开启的撤离区域 | 撤离前存活不自动完成；timeout必须晚于开启时刻且路线可达 |
| BREAK | target_ids非空且唯一；order_mode=FIXED或PLAYER_CHOICE | 全部目标各收到一次有效死亡事实 | FIXED只开放定义序列当前锚点；PLAYER_CHOICE开放全部未毁锚点，由实际攻击决定次序；UI明确可攻击目标 |
| CLEANSE | ordered_zone_ids；每区required_hold_ticks>0 | 所有区累计合法hold达到需求 | 当前区内玩家存活且区域无blocker时tick+1，离开/受压暂停不清零；不同时推进多个区 |
| HUNT | required_target_ids非空 | 所有指定目标出现有效死亡事实 | 无“逃出屏幕即失败”；目标保持任务存续，不适用普通敌人远距退役；无法保持合法状态为技术故障 |
| ESCORT | escort_target_id；waypoint_ids非空；follow_radius>0；arrival_radius>0 | 目标按序到达全部waypoint且HP>0 | 玩家在follow_radius内才移动，离开停止；目标死亡失败；阻挡不能无限软锁，预检可达路径和运行故障诊断 |
| BOSS | required_boss_ids非空 | 所有指定Boss有效死亡事实 | Boss出场时点由任务schedule提供，不能全局固定720秒；无关Boss/召唤物死亡不完成 |

BREAK的target_ids是稳定定义序列，不将存档数组的任意排列当新配置。FIXED仅当前target可受任务伤害推进，错序权威死亡为INVALID_FACT→TECHNICAL_ABORT；PLAYER_CHOICE任意尚未完成的合法target均可推进，无额外选择菜单。两模式都保存`completed_target_ids`（按定义顺序canonical集合）与`completion_order_ids`（实际提交顺序，不可为编码排序而重排），每target至多一次；objective_progress_revision仅在一个完整合法batch实际改变进度时checked+1，并进入Mission snapshot；FIXED的order必须是定义前缀，PLAYER_CHOICE的order必须唯一且与completed集合相同。完成条件均为该集合等于全部target_ids。

同tick多个锚点死亡按事实聚合器的稳定fact_sequence接纳；上游须以owner stable order、target定义ordinal、spawn epoch形成确定顺序，不能使用回调抵达先后。顺序改变的喷口/桥面等环境效果由Stage在下一tick消费已提交progress revision，重复revision零效果；Mission不直接改环境。matching-tick Stage snapshot须包含已应用revision和待应用效果，缺失不得恢复。暂停/恢复不重新选择顺序，也不重放已应用效果。此附加Stage adapter/容量仍受MO12生产门约束。

生产映射固定S1-M02-07、S1-M07-07、S1-M08-02为PLAYER_CHOICE，其余当前BREAK任务为FIXED；Config须显式写order_mode、不得默认猜测。此映射保留产品的“改变喷口节奏/选择拆除次序/选择锚点顺序”；目标ID、效果与具体容量仍需生成配置冻结。

坐标/圆边界采用Stage/CombatGeometry权威；上述半径必须finite正值，任务配置不得绕过world-domain检查。目标实体所属Pool/Grid/HP和AI规则由相应owner定义，Mission不直接移动或扣HP。

### tick顺序与事实输入

GameRoot在所有本tick移动、伤害、死亡、目标运动/区域事实提交后，调用一次`evaluate_tick(context,facts)`，然后在最终barrier选择继续或terminal。Mission不注册自主_process/physics，不消费呈现回调推测真值。现有阶段参与者与容量manifest必须加入MISSION实际行后才可开生产任务；本GDD不私自占用一个旧stable_order。

facts为caller-owned有界只读批次，包含`run_seq/instance_epoch/tick/fact_sequence/source_owner/target_id/spawn_epoch/kind/value`，序列严格递增；允许kind为`TARGET_DEAD/WAYPOINT_REACHED/ZONE_SAMPLE/EXTRACTION_SAMPLE`。ZONE/EXTRACTION_SAMPLE是每tick唯一sample，value为合规布尔值；WAYPOINT_REACHED需当前waypoint ID。在入口整批验证且未通过前不得部分推进：外部旧run/旧instance_epoch/退役对象回调返回STALE_FACT，零效果、零终态、不污染当前合法batch。当前实例权威批次的错tick、重复序号、未注册owner、非法值或容量溢出返回INVALID_FACT并停止本tick，GameRoot在最终barrier封唯一TECHNICAL_ABORT；不继续普通胜利。先验完整性检查失败不得先用部分事实推进。

收集由GameRoot聚合，Damage/Stage/Enemy等owner签发。一个目标死亡重复sample不得重复计进度；正常重复业务由上游去重，Mission守卫提供二次拒绝。数组容量和每owner贡献由Config生成，不在hot path扩容。

### 终态仲裁（新任务profile规则）

同一tick先完成事实校验，再按以下优先级仅选一次：

1. 当前权威链owner/identity/容量/快照不一致（外部stale事实不属此类）：TECHNICAL_ABORT，禁止生成普通成功奖励；补偿仅按已提交事实由Settlement处理。
2. player committed life=DEAD：DEFEAT / PLAYER_DEAD，即使本tick目标也完成。
3. ESCORT目标committed life=DEAD：DEFEAT / ESCORT_DEAD。
4. 目标完成：VICTORY / OBJECTIVE_COMPLETE（可在timeout相等tick成功）。
5. active_tick≥timeout_ticks：DEFEAT / TIMEOUT。
6. 否则继续ACTIVE。

主动放弃在tick barrier外单独请求：若本tick已sealed结果则返回ALREADY_TERMINAL，不以放弃覆盖胜负；否则GameRoot接纳放弃、关闭本局并封ABANDONED，经STAGE_RESULT→COMPLETE提交；未sealed是请求接纳前置，不是在封结果后再次要求其未sealed。这套优先级只用于新Mission profile，不能悄悄改写当前legacy Boss优先适配。

`MissionResultV1={schema:"1",profile_id,branch_id,run_seq,mission_id,definition_hash,terminal_tick,result_kind,reason,objective_progress_hash}`。sealed后字段不可变，结果hash按Save v2 canonical codec。Mission不包含具体奖励数。持久语义结果不含instance_epoch；实时交付用`MissionResultDeliveryV1={instance_epoch,result,result_hash}`，只由GameRoot当前实例提交。恢复RESULT_PENDING则由Save验证head中的terminal_intent与run/definition/hash绑定，给Settlement恢复路径提交原结果和原COMPLETE请求；无需旧BattleScope或旧epoch。该路径不接收任意UI结果，不重新计算奖励，也不重复调用实时结果接纳。

### 暂停、保存与恢复

`MissionSnapshotV1={schema:"1",mission_id,definition_hash,run_seq,active_tick,next_fact_sequence,objective_progress_revision,state,objective_progress,sealed_result_or_null}`。progress为各kind对应的已完成target集合/当前target索引、BREAK的completion_order_ids、zone累计ticks、escort当前waypoint等；对象运动/HP/敌群/RNG由其owner snapshot承接，Mission快照不能替代世界快照。

暂停后禁止evaluate_tick推进；capture在所有fact账本提交且无未决半事务的barrier执行。可继续游玩的未sealed恢复点验证definition hash、进度域、owner映射及目标存续，重新绑定runtime epoch。sealed后必须按Save的STAGE_RESULT持久终局请求；RESULT_PENDING直接恢复该请求，不恢复可玩战场。旧epoch事实不得被重放。无法恢复合法目标时保留存档并技术故障，不偷偷清空目标状态重开。

## Formulas

active tick只计实际60Hz gameplay tick：`elapsed_seconds=active_tick/60`，菜单/暂停/后台不加。净化`hold_next=min(required,hold+1)`仅当current zone合法sample true；false不变。FIXED破阵当前索引只在matching当前target死亡时+1；PLAYER_CHOICE新增任一合法未完成target，completed_count每target至多+1；护送waypoint仅当前点推进。所有加法checked，集合只接受定义内ID。一次结果数`0≤sealed_count≤1`。

## Edge Cases

同tick死亡与目标完成按上述优先级；完成与timeout相等时胜利但死亡仍优先。目标无故退役不是完成；没有required targets不能利用空集真值获胜。world域外、路径不可达、采样重复与数组满均明确技术错误，不随机换目标。已持久的sealed intent恢复只能重试原COMPLETE，不能再打Boss；只有内存sealed而STAGE_RESULT未形成head时，崩溃回退到最后合法checkpoint（不宣称未保存结果已持久）。

## Dependencies

campaign-flow.md、save-steam-pc.md、game-root-scene-flow.md、settlement-system.md、config-data-system.md、stage-map.md、enemy-system.md、spawn-director.md、damage-system.md、boss-state-machine.md、battle-ui.md、rng-system.md。目标entity/HP/路线、required-owner快照、MISSION phase与容量贡献尚待这些owner传播及验证，保持implementation gate OPEN。

## Tuning Knobs

每任务timeout、生存时段、净化hold、护送半径/路线、目标数与schedule为版本化Config；变更definition hash后旧快照需迁移或保留旧定义加载。范围/容量由对应owner给出，不从64任务数推出同屏对象数。

## Acceptance Criteria

- MO01 六kind各有成功/失败基例；未知kind、零目标/重复ID/缺配置拒绝预检。
- MO02 SURVIVE满足时间但未入撤离区不胜；到达时间边界且进入则胜。
- MO03 BREAK两模式各测三目标：FIXED仅前缀推进、当前权威乱序死亡走fault；PLAYER_CHOICE六种排列均可完成且每target只推进一次，外部旧epoch零效果；缺order_mode/集合与order不一致拒绝。
- MO04 CLEANSE有效sample恰加1，离开/有blocker/暂停不加不回退；满值不溢出。
- MO05 HUNT目标出屏仍存续；普通远距退役不得作用于任务目标；缺目标技术故障而非胜利。
- MO06 ESCORT近随/远停、依次到点、死亡失败；死亡与到达同tick失败。
- MO07 BOSS只接受指定身份；第8章M07的Boss死亡不会直接结束整个campaign。
- MO08 同tick矩阵覆盖fault/death/escort_death/completion/timeout，结果与优先级唯一一致。
- MO09 外部旧run/epoch事实返回STALE_FACT、进度与sealed_count不变；当前权威批次错tick/重复/非法值/溢出返回INVALID_FACT且在barrier产生恰一个TECHNICAL_ABORT、零普通奖励；hot path不扩数组。
- MO10 pause/capture/restore保持进度与tick；恢复后旧epoch拒绝，新合法事实连续推进。
- MO11 E1封结果→stage持久→E2恢复，原result字节/hash和COMPLETE身份不变；late abandon返回ALREADY_TERMINAL，结算只提交一次；stage前强杀明确回旧checkpoint。
- MO12 六kind最大合法workload、owner snapshot、阶段/容量manifest全部生成并验证后才能启用生产mission profile。

- MO13 BREAK同tick多死亡按稳定fact_sequence记录order；中途恢复保持已选顺序、Stage已应用revision与待应用效果，不重放；三项PLAYER_CHOICE产品任务及其余FIXED映射由Config验证。
