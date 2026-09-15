# DropSystem + Leveling/XP

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：新STEAM_MISSION_V1首次grant归Campaign、重复与失败收入归本owner/Settlement；短局数值矩阵ECON-MISSION-01未冻结，禁止直接沿用全局局长公式。Save v2续局须保留拾取/经验/升级队列及未完成ledger的matching-tick snapshot，具体schema/预算待本owner冻结。

> **Status**: In Review / Re-review Pending
> **Author**: User + Codex
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 移动收集与持续变强；功法构筑与进化；谨慎走位而非站桩
> **Review Mode**: lean

## Overview

本 GDD 合并定义 DropSystem 与 Leveling/XP 的端到端奖励链，但运行时仍保留两个独立 owner：DropSystem 把已提交的合法敌人死亡转换为确定性的灵气与稀有功能掉落，负责地面 Drop 的池化、空间索引、拾取与回收；Leveling/XP 只消费已提交的 XP PICKUP fact，按固定经验曲线更新本局等级并逐级产生 SkillDraft 请求。二者共同完成“击杀→看到奖励→主动走位拾取→升级暂停→构筑变强”的闭环，不直接写敌人死亡、Player HP、Skill loadout、SceneTree pause 或 UI Node。

合并文档不合并权威边界。`DROP` 与 `LEVELING` 仍各自登记 GameRoot participant、状态、容量和失败域，避免一个超大系统同时拥有死亡、奖励、HP 与构筑权威。

## Player Fantasy

玩家应感到每次击杀都在战场上留下可见的成长机会：绕开危险去吃一簇灵气、为远处的大结晶改变路线，都是可理解的风险收益，而不是后台自动涨经验。前30秒必须出现第一次“修为突破”，随后升级节奏逐渐拉长，让功法成型来自连续正确走位与构筑，而非原地等待。

回春符、引灵符与爆炎符应是稀少、可读、能改变短期决策的战场机缘。它们不能稳定到足以支持站桩，也不能因对象池压力或随机重抽悄悄多给/少给奖励。精英法宝匣承接此前构筑：玩家先铺好五层主动与对应辅助，再让宝匣兑现为进化神通。

## Detailed Design

### Core Rules

#### R1 — 双 owner 与 GameRoot phase

- DropSystem 独占 Drop gameplay identity、种类、XP 数量、世界位置、claim 状态、Pool borrow、Spatial handle、生成/合并/拾取/远距退役计划。
- Leveling 独占本局 `level`、`xp_in_level`、`total_applied_xp`、逐级 choice debt 与其 request identity；SkillDraft 独占技能候选、选择和 loadout。
- 两个 required participant row 固定为：

```text
DROP_PHASE_ROW_V1={participant_id=DROP,role_id=DROP,stable_order=7,
allowed_phases={SPAWN_INTENT,QUERY,QUERY_CONSUME,DEFERRED_REMOVAL},
allowed_success_statuses={OK,OK_NOOP},owner_contract_id=DropSystem/v1,
owner_gdd_path=design/gdd/drop-leveling-system.md,phase_row_id=DROP_PHASE_ROW_V1,required=true}

LEVELING_PHASE_ROW_V1={participant_id=LEVELING,role_id=LEVELING,stable_order=10,
allowed_phases={DEFERRED_REMOVAL},allowed_success_statuses={OK,OK_NOOP},
owner_contract_id=LevelingSystem/v1,owner_gdd_path=design/gdd/drop-leveling-system.md,
phase_row_id=LEVELING_PHASE_ROW_V1,required=true}
```

- phase 1 只物化上个 tick 已提交的 spawn plan；phase 4 只写 caller-owned DROP query buffer；phase 5 resolve+narrowphase 并 arm pickup plan；phase 6 先由 Drop exact-once 提交 PICKUP/lifecycle，再由 Leveling 消费同批 matching XP fact。SkillDraft 在 phase 7 接收已展开 request。
- 两 owner 均为 PAUSABLE，不定义自主 gameplay `_process/_physics_process/_input`，不以带参 signal 传递热路径 payload。

#### R2 — Drop identity、种类与只读 authority

`DropKindV1` 封闭为：`XP=1,RECOVERY=2,MAGNET=3,BLAST=4,TREASURE_BOX=5,CORE_HERB_PRESENTATION=6`；0 为 INVALID。

每个 gameplay Drop 使用：

`DropRuntimeRowV1={drop_id,drop_kind,xp_amount,world_position,source_death_fact_sequence,source_id,spawn_sequence,object_instance_id,borrow_id,spatial_handle_id,claim_state,generation,valid}`。

- `drop_id`、`spawn_sequence` 为本 battle 非零单调 int64，耗尽 fail closed，不复用。
- `claim_state={AVAILABLE,CLAIM_RESERVED,CLAIM_COMMITTED,RELEASE_PENDING,RELEASED}` 单调；`CLAIM_COMMITTED` 后永不重新可拾取。
- A/B `DropAuthorityViewV1` 容量固定 300，按 `drop_id ASC` canonical；不返回可写 PackedArray alias。
- `DropPoolable/v1` reset 必须清除 kind/value/source、所有 Tween/timer/callback、collision、visibility、claim 标志、旧 handle/borrow 与 presentation latch。AVAILABLE 时 process/collision/visibility 全关闭。
- XP 微光与结晶只是 `xp_amount` 的表现档位，不是两套经济真相；`xp_amount>=10` 显示结晶，否则显示微光。

#### R3 — 哪些死亡可以产出奖励

- 只有 EnemySystem 已 COMMITTED 的 `DEATH` fact 与 matching death staging row 可以生成 reward plan。staging 固定并逐字段匹配 `{death_fact_sequence,enemy_id,borrow_id,behavior_id,death_position,spawn_seed,spawn_provenance,source_choice_id}`；非Risk的choice ID必须为0，Risk必须为matching非零ID；缺 sequence/identity、stale borrow 或冲突重复均 fault。
- `OFFSCREEN_RETIRE`、`REVIVE_CLEAR`、spawn suppression、未提交 death、fault-only cleanup 都产生 0 XP、0 utility、0 treasure、0 DROP RNG call。
- 普通敌人保证产生 XP；具体表为 `PROVISIONAL-BALANCE`，待 WaveSchedule 与15分钟试玩冻结：

| behavior | base XP | rule |
|---|---:|---|
| 噬灵虫 0 | 1 | reward-eligible normal |
| 铁背妖狼 1 | 2 | reward-eligible normal |
| 腐毒妖藤 2 | 4 | reward-eligible normal |
| 甲壳妖虫 3 | 6 | reward-eligible normal |
| 魔道符修 4 | 8 | reward-eligible normal |
| 血傀儡 5 | 3 | 仅 WaveSchedule 直接生成；精英召唤 provenance 为 0 XP/utility |

- 固定精英可配置大额 XP 与宝匣：6:00 巨甲蜈蚣初始锚点 160 XP，10:00 鬼雾修士 300 XP；机缘精英初始锚点 240 XP，并由 RiskChoice Config 明确 `treasure_eligible`。这些值均为 provisional，不在 WaveSchedule GDD 完成前称 production locked。
- Boss 的玩家文案统一为“核心灵药”，stable item name为`CORE_HERB`；它完全不进入Drop gameplay transaction。BATTLE_RULES拥有预分配`CoreHerbRewardStageBankV1`，容量1，header固定`{schema_version=1,battle_instance_id,config_snapshot_id,tick_revision,source_authority_revision,terminal_precollection_token,count,generation,valid}`，row固定`{reserved_fact_sequence,reward_id,source_death_fact_sequence,source_enemy_id,item_id,amount}`且`reward_id=CORE_HERB(6)`、`item_id`为Config非零stable item ID、`amount=1`；`reserved_fact_sequence`只作ledger identity，不得冒充reward kind。phase 6仅在matching `precollected_winner=VICTORY`时写一行并映射到现有ledger：`{fact_sequence=reserved_fact_sequence,producer_role_id=BATTLE_RULES,fact_kind=REWARD,subject_id=item_id,source_id=source_enemy_id,value_i64=amount,value_f64=0,commit_state=COMMITTED,batch_authority_revision}`。同death重复为OK_NOOP、冲突为fault；VICTORY+lethal仍提交一次，FATAL获胜时0次。phase 7不得新建fact，只以`reserved_fact_sequence+terminal_precollection_token+source_death_fact_sequence` join staging与COMMITTED fact；同token最终seal为VICTORY才进入BATTLE_RULES Outcome，非VICTORY技术审计fact不进入玩家结算。核心灵药和传送阵表现只读sealed Outcome，不可交互、不占Drop/Pool/Grid容量。

#### R4 — 固定 DROP RNG 与稀有功能物

- 每个 reward-eligible Normal DEATH 按 `death_fact_sequence ASC` 精确消费一次 `DROP` stream `roll_int_range(1,100000)`；基础 XP 不随机。同一death的award子序冻结为`XP=1,UTILITY=2,TREASURE_BOX=3`，`drop_id/spawn_sequence`也按此序分配，因此同tick共同拾取时XP PICKUP fact先于宝匣；分tick拾取时只按实际PICKUP fact自然顺序生效。
- provisional 权重为：`NO_UTILITY=99600, RECOVERY=250, MAGNET=100, BLAST=50`。总和精确 100000；生成前由 Config checked sum。
- 命中后再检查资格，不重抽：只读GameRoot当前published `BattleAuthorityBundle`中Player slice的getter-only `PlayerHpAuthorityViewV1={schema_version=1,battle_instance_id,config_snapshot_id,authority_bank_id,authority_revision,player_id,current_hp,max_hp,life_state,view_generation,valid}`；每次authority full-copy都会复制该slice，故非Player owner推进revision后view仍matching当前`source_authority_revision`。回春符仅在`current_hp/max_hp<=0.70`，同tick后续damage不反向改变资格。cooldown以60Hz gameplay tick整数表示，Recovery/Magnet/Blast分别为5400/7200/10800 ticks，`current_tick-last_award_tick>=required`时可用，边界相等可用；首次用INVALID sentinel表示未发放。Paused不推进tick，每局reset。每局上限分别3/2/1。未满足映射`NO_UTILITY`，RNG cursor仍推进一次。
- scheduled Elite、Boss、`ELITE_SUMMON`血傀儡、`BOSS_SUMMON`噬灵虫与任何无奖励退役消费0次DROP roll；BOSS_SUMMON不得借behavior0的WAVE奖励表。
- 合并、active cap、Pool/Spatial 成败不得改变已规定的 RNG calls；第 N 次 RNG fault 时本 death batch 不发布任何新 drop plan且不重摇。

#### R5 — 300 active、XP 合并与 phase-1 物化

- 权威上限保持 Config/Pool/Grid 既有契约：`DROP active/registered=300`、`drop_gameplay pool=320`。不存在合法的 `503 DROP` 容量。
- 特殊物硬保留最多10个 active 槽：Recovery 3、Magnet 2、Blast 1、Treasure 4；XP physical rows 最多290。unused reserve 不得借给 XP 突破290。
- phase 6 先对已完成 pickup/retire 的 projected set应用 release，再按 death fact顺序解析新 award。XP 有空槽时建立 next-tick spawn row；XP physical count=290时，合并进 `drop_id` 最小的有效 XP row，使用 checked add并以 `xp_total_to_level_cap=16552` 饱和。饱和只丢弃已超过一局理论构筑上限的冗余值，并记录 saturating diagnostic。
- special 达到自身 run/cooldown/active cap 时使用已消费 RNG 的 `NO_UTILITY` 结果，不挤占 XP，不排队重试。Treasure 奖励不可丢：最多4个 active 宝匣；第五个说明 RiskChoice/Wave 配置违反 hard bound并 fault。
- `DropAwardPlanBankV1`为单调预分配ledger，容量606（303个同tickDEATH×最多2个Drop award），header固定`{schema_version=1,battle_instance_id,config_snapshot_id,tick_revision,source_authority_revision,count,generation,valid}`，row固定`{award_sequence,source_death_fact_sequence,award_kind_order,disposition,drop_kind,xp_amount,merge_target_drop_id,planned_drop_id,planned_spawn_sequence,world_position,source_id}`，canonical key为`{source_death_fact_sequence,award_kind_order}`。
- `DropMaterializeBankV1`容量300，header固定`{schema_version=1,battle_instance_id,config_snapshot_id,source_tick_revision,materialize_tick_revision,count,generation,valid}`；typed reset context固定为`DropSpawnContextV1={schema_version=1,battle_instance_id,config_snapshot_id,drop_id,drop_kind,xp_amount,world_position,source_death_fact_sequence,source_id,spawn_sequence}`。`DropMaterializePlanRowV1={materialize_sequence,spawn_context,state,object_instance_id_or_0,borrow_id_or_0,spatial_handle_id_or_0}`，按`materialize_sequence ASC`，`state={PLANNED,BORROWED,RESET_DONE,GRID_INSERTED,BOUND}`单调。PLANNED时三个runtime ID必须为0；每个后续state只写其刚产生的identity。只有BOUND后才将spawn context与三个非零ID原子写入一条R2 `DropRuntimeRowV1`并清plan row；borrow/reset/insert/bind失败分别保证无identity、release borrow、remove+unbind+release或fault convergence，不得留下可见ghost。
- 两bank的required−1、重复key、stale header或generation均在RNG/authority mutation前fault；teardown先invalid再推进generation。
- phase 1 才执行 `Pool.borrow_into(drop_gameplay)→reset_for_borrow(typed spawn context)→SpatialGrid.insert(DROP)→bind`。任一步失败遵守 Pool/Grid 既有回滚或 fault，不动态 instantiate、不生成 ghost。
- Drop 严格离开 Stage 当前 player-relative retention rect 时，phase 5 建立无奖励 `DROP_EXPIRED` plan，phase 6 走 remove→unbind→release；不自动入账 XP/道具。

#### R6 — 拾取查询与不可逆点

- phase 4 以 matching `PlayerMotionCommitCarrierV1.committed_position` 调用 `query_circle_into(center,pickup_radius,DROP,capacity=300)`；Player 不调用 Grid。
- `pickup_radius` 只允许 Config 已冻结的 center-distance `[1.8,1.98]`。phase 5 resolve完整 lifecycle identity 后，窄相固定为 `distance(drop_center,player_center)<=pickup_radius`；不加 Drop sprite/shape 半径。
- 候选按 `drop_id ASC`，单 tick 最多领取4个 Treasure；更多重叠宝匣保持 AVAILABLE 至下个 Active tick。普通 pickup 总数最多300。
- 若本 tick拾取 MAGNET，则同一 plan 额外包含当时 matching authority 中所有 AVAILABLE XP rows；不递归拾取 Recovery/Blast/Treasure。
- `DropPickupPlanBankV1`容量300，header固定`{schema_version=1,battle_instance_id,config_snapshot_id,tick_revision,source_authority_revision,next_authority_revision,count,plan_generation,armed,valid}`，row固定`{claim_sequence,drop_id,drop_kind,xp_amount,object_instance_id,borrow_id,spatial_handle_id,pickup_fact_sequence,lifecycle_sequence,effect_slot_id,leveling_plan_row_or_none,request_id_or_none,commit_state}`；按`drop_id ASC`且identity唯一。`commit_state={RESERVED,FACT_COMMITTED,EFFECT_COMMITTED,GRID_REMOVED,POOL_UNBOUND,POOL_RELEASED}`单调。
- 每个 claim 在任何 side effect 前一次性 reserve matching PICKUP fact、lifecycle row、effect/request slot与authority plan；含XP时还必须让Leveling完成R8的完整prefix apply-plan预写与arm。任一reserve/prewrite/arm失败时fact/effect/lifecycle/public authority均0。每条PICKUP fact首次COMMITTED分别是该claim与对应Leveling slice的PONR；随后只推进该slice的不可失败committed-prefix latch，未commit的后续slice绝不应用。matching end或fault convergence按实际连续committed prefix恰发布一次Leveling snapshot/debt/request selector，再把每个已commit Drop row收敛至effect→Grid remove→Pool unbind→release。技术性Pool/Grid收敛失败可进入已有journal fault路径，但不得遗漏或重复已commit的XP、恢复、爆炎或宝匣请求。
- `PICKUP.value_i64` 对 XP 为实际 `xp_amount`，对非 XP 为稳定 `DropKindV1` code；Leveling 只消费 XP fact。GameRoot fact sequence是跨 Drop/Leveling/SkillDraft 的唯一排序锚。

#### R7 — 功能物效果边界

- 回春符在 pickup commit 后产生一个 next-Active-tick `RecoveryIntentV1{type=MAX_HP_RATIO,value=0.30,reason=DROP_RECOVERY}`，由 DamageSystem 唯一 PlayerRecoveryResolver 结算；Drop 不写 HP，满血时实际 HEAL fact 可为0。
- 引灵符只扩展同一 pickup plan 的 XP rows；每行仍有独立 PICKUP fact/lifecycle identity，不把多物品压成一条不可追溯事实。
- 爆炎符只发布 `DropBlastIntentV1` 给 DamageSystem 下一 tick QUERY：目标行为为清除 active Normal、对 Elite 造成 `max_hp×blast_elite_ratio`、Boss 不受影响；所有正常死亡再由 Enemy DEATH fact产生奖励，防止双发。`blast_elite_ratio`、全场 ENEMY 扫描 API 与 normal execution ABI 未冻结前标 `BLOCKED-BLAST-ABI`。
- 法宝匣 PICKUP 生成一个 `SkillChoiceRequestV1{request_kind=TREASURE_BOX,source_fact_kind=PICKUP,source_fact_sequence,...}`；一个 box 一 request，quantity 不压缩。
- CORE_HERB 不作为 gameplay pooled pickup；BATTLE_RULES按R3唯一提交REWARD并写Outcome，Drop只允许表现层读取该fact。

#### R8 — Leveling 状态、经验应用与等级上限

- fresh run通常为 `level=1,xp_in_level=0,starting_level_curve_credit=0,total_applied_xp=0`；若matching聚气丹projection，则在Active/生存计时前固定为`level=2,xp_in_level=0,starting_level_curve_credit=14,total_applied_xp=14`并先完成1次普通level-up ordinal=1 SkillDraft选择。14是起始曲线credit，不伪造XP PICKUP fact、掉落或残页；本局硬上限仍为 `level_cap=40`，因此剩余到L40为`16552-14=16538`。
- Leveling 仅按PICKUP fact sequence逐条消费本batch XP；重复matching fact为`OK_NOOP`，stale/missing/conflicting payload在首个matching slice PONR前fault。
- `LevelUpDebtBankV1`为39-row单调ledger，header固定`{schema_version=1,battle_instance_id,config_snapshot_id,bank_id,authority_revision,count,transfer_cursor,generation,valid}`，row固定`{debt_id,level_request_sequence,crossing_pickup_fact_sequence,level_before,level_after,request_id,transfer_state}`，按`{crossing_pickup_fact_sequence,level_after,level_request_sequence}`canonical，`transfer_state={RESERVED,QUEUED,COMPLETED,TERMINAL_CANCELED}`单调且row不复用。
- `LevelingApplyPlanV1`在任一matching XP PICKUP fact commit前构造并arm，header固定`{schema_version=1,battle_instance_id,config_snapshot_id,tick_revision,source_authority_revision,next_authority_revision,inactive_snapshot_bank_id,inactive_debt_bank_id,first_pickup_fact_sequence,fact_count,max_new_debt_count,committed_prefix_count,plan_generation,armed,valid}`；其预分配300-row disposition固定`{pickup_fact_sequence,raw_xp,accepted_xp,xp_at_cap_delta,first_debt_index,debt_count,level_after_prefix,xp_after_prefix,total_applied_xp_after_prefix,xp_at_cap_after_prefix,cumulative_debt_count}`。preflight按F5逐fact预写每个可能连续prefix的完整标量结果、debt rows、最多10个可见request reservation并验证SkillDraft/debt-transfer capability。每条fact commit后只允许不可失败地令`committed_prefix_count`从N推进N+1；若第N条commit前失败则prefix=N−1，commit后失败则prefix=N。matching end/fault convergence只发布该prefix对应的snapshot、debt authority count与request子集，整个GameRoot batch selector至多切一次；未commit suffix保持非权威且绝不发布。arm后不再执行可能失败的算术、分配或身份生成。
- 每个XP fact逐条计算accepted XP并按F1跨级；每跨一级建立一条独立debt row，不得把quantity>1压成一次SkillDraft choice。`total_applied_xp`只加accepted XP且范围`0..16552`；达到40级后`xp_in_level=0,total_applied_xp=16552`，超额及后续XP计入saturating int64 `xp_at_cap` diagnostic，仍完成Drop release但不再产生request。
- Leveling A/B snapshot 为`LevelingSnapshotV1={schema_version=1,battle_instance_id,config_snapshot_id,bank_id,authority_revision,level,xp_in_level,starting_level_curve_credit,total_applied_xp,xp_at_cap,debt_count,next_level_request_sequence,generation,valid}`；`starting_level_curve_credit∈{0,14}`且只在Loading绑定时写一次，debt backing固定39 rows。每次matching armed plan恰切一次snapshot selector并与GameRoot batch authority revision一致。

#### R9 — 多级连升、14槽 choice window 与顺序

- Leveling debt最多39行；SkillDraft可见 FIFO 中 Leveling 同时最多10个 request，Drop/Treasure同时最多4个，因此 `S_PENDING=14`。这不是总升级次数上限，而是暂停控制泵的暴露窗口。
- phase 6 将新 debt 按 `{crossing_pickup_fact_sequence ASC,level_after_gain ASC,level_request_sequence ASC}` 排序并尽量填入10个 Leveling queue slots。
- GameRoot进入Paused后，SkillDraft每完成一个choice并发布loadout，persistent control pump可调用`LevelingDebtTransferCapabilityV1={schema_version=1,battle_instance_id,config_snapshot_id,source_debt_bank_id,expected_debt_authority_revision,expected_transfer_cursor,capability_generation,valid}`把下一条已展开debt row移入空槽；成功要求完整identity/revision/cursor匹配并原子推进cursor与row state，duplicate为OK_NOOP，stale/conflict为fault。该能力只移动预存request，不增加XP/level、不推进gameplay timer；teardown先invalid再推进generation。
- 所有 debt 与 treasure request完成/terminal-cancel 前不得 resume。后一个升级页必须读取前一个 choice 已发布的最新 loadout，不预生成。
- 统一request总序为`source_fact_sequence ASC→request_kind_order(LEVEL_UP=1,TREASURE_BOX=2)→request_sequence ASC`。同一精英的XP/宝匣在同tick拾取时，由R4冻结的drop_id与pickup commit子序保证XP fact先提交，故其level-up debt先于treasure request；若玩家分tick拾取，则严格服从实际拾取先后，较早拾取的宝匣不会预见未来XP choice。
- SkillDraft 的普通候选数 `n=3/2/1` 时诚实显示三/二/一选一；不得复制卡或补非法项。`n=0` 只允许 Leveling 已到40且不再生成普通 request，否则是 authority/config fault。

#### R10 — Pause、terminal 与 teardown

- Drop/Leveling 不写 `SceneTree.paused`。phase 7 由 SkillDraft根据 pending request请求 blocking pause；Paused期间 Drop query/spawn/expire、XP、cooldown与 gameplay timer均不推进。
- `FATAL` precollected 时不建立新的可选 reward/request，只收敛 PONR 后行；`VICTORY/DEFEAT/ABANDONED` 高于 PAUSE 时不打开 choice UI。已提交 XP/level可进入最终快照，未选择的普通升级与宝匣 request按 terminal-cancel exact-once清理，不自动选卡。
- teardown先 invalid Drop/Leveling views与debt/request capability，再推进generation，然后由GameRoot完成Grid invalidation、Pool teardown。旧 fact/token/command不得污染新 battle。

#### R11 — Owner capacity contributions

| role | LIFECYCLE_INTENT | FACT_COMMIT | PAUSE_CLOSURE | BLOCKING_CHOICE |
|---|---:|---:|---:|---:|
| DROP (stable 7) | 300 | 300 | 300 | 0 |
| LEVELING (stable 10) | 0 | 0 | 0 | 0 |
| SKILL_DRAFT (stable 8, cross-doc) | 0 | 0 | 0 | 14 |

Drop的一条 claim/expire最多一条lifecycle row与一个 finalizer closure；引灵符扩展后总 active仍≤300，不能把触发符本身与XP行算成301。Leveling只更新owner authority与request debt，不重复提交 PICKUP/REWARD fact。Leveling/Drop的10/4是 SkillDraft queue输入上界，不能再次作为各自 `BLOCKING_CHOICE` contribution重复计数。

RiskChoice actual contribution已冻结为2，故GameRoot blocking checked sum为SkillDraft14+RiskChoice2=16。该局部容量闭合不等于`battle_ready`，其余owner、workload与运行时gate仍可阻断。

#### R12 — Config 与 readiness

`DropConfigV1` 至少冻结：behavior XP/provenance表、100000权重表、资格/cooldown/run cap、subtype active cap、pickup/retention语义、blast ratio/ABI版本、treasure provenance上界、DropPoolable reset contract。

`LevelingConfigV1` 至少冻结：F1系数、level cap40、debt39、queue window10、request schema与 terminal policy。全部进入 BattleConfig content hash，Active/Paused不可热改。

当前 readiness 边界：

- `PROVISIONAL-BALANCE`：敌人 XP 与 utility 权重需要 WaveSchedule + 15分钟试玩。
- `BLOCKED-BLAST-ABI`：Damage/Enemy未冻结爆炎全场清杂与Elite比例伤害接口。
- `RESOLVED-RISK-CAPACITY`：RiskChoice恰两次event、blocking contribution=2；两次risk+两次fixed Elite使treasure provenance最多4，正好等于本系统cap4。第5个仍为配置fault。
- `BLOCKED-WORKLOAD-REGEN`：GameRoot RW01..11 的 `{1,303,384,503}` 与 Config/Pool/Grid 的 DROP 300、pool 320 冲突；必须整体重生成 active vector、operation vector与hash，禁止只把503替成300后称通过。

### States and Transitions

| Drop state | Meaning | Allowed next |
|---|---|---|
| UNBOUND | 无 battle/config | READY, FAULTED |
| READY | 可接收phase | QUERY_STAGED, SPAWN_STAGED, CLAIM_STAGED, FAULTED, TORN_DOWN |
| QUERY_STAGED | query完成待consume | CLAIM_STAGED, READY, FAULTED |
| SPAWN_STAGED | award已解析待下tick物化 | READY, FAULTED |
| CLAIM_STAGED | facts/journal/effects已reserve | COMMITTING, READY, FAULTED |
| COMMITTING | PONR后收敛pickup/release | READY, FAULTED |
| FAULTED | 首错锁存、consumer关闭 | TORN_DOWN |
| TORN_DOWN | views invalid | UNBOUND |

| Leveling state | Meaning | Allowed next |
|---|---|---|
| UNBOUND | 无 snapshot | READY, FAULTED |
| READY | 可消费 matching XP facts | APPLYING, TORN_DOWN, FAULTED |
| APPLYING | 写inactive snapshot/debt | DEBT_PENDING, READY, FAULTED |
| DEBT_PENDING | Paused control pump串行转移request | DEBT_PENDING, READY, TERMINAL_CANCELED, FAULTED |
| TERMINAL_CANCELED | 高优先级terminal已清请求 | TORN_DOWN |
| FAULTED | 首错锁存 | TORN_DOWN |
| TORN_DOWN | view/capability invalid | UNBOUND |

### Interactions with Other Systems

| System | Input | Output / ownership boundary |
|---|---|---|
| EnemySystem | committed DEATH fact + typed staging | Drop plan；不重复写DEATH/kill |
| Object Pooling | borrow/bind/unbind/release | Drop owns lifecycle intent；Pool owns slot/reset FSM |
| SpatialGrid | DROP query/insert/remove | Drop owns query与handle；Player不接触Grid |
| PlayerController | published position/pickup radius/HP view | 不写position/HP；恢复交Damage |
| DamageSystem | recovery/blast intent capability | Damage结算恢复/伤害；正常死亡再产reward |
| Config/Data | immutable Drop/Leveling config | 缺字段不补默认，load fail closed |
| RNG | DROP stream | reward-eligible normal固定1 call |
| SkillDraft | individual level/treasure requests | Draft ownsoffer/choice/loadout |
| GameRoot | phase、fact/journal、pause/control capability | owners不写top state/pause |
| BattleUI | read-only Drop/Leveling/choice views | UI不提交XP或自带reward payload |
| Settlement/Save | final level/reward facts | 不读取已销毁Node；Settlement作者GDD已冻结6-row映射，runtime待证 |

## Formulas

### F1 — XP required for next level

The `xp_to_next` formula is defined as:

`T(L)=checked_add(8,checked_mul(5,L),ceil_div(checked_mul(3,checked_mul(L,L)),5))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| current level | `L` | int64 | `[1,39]` | level 40不再求阈值 |

**Output Range:** `14..1116` XP；所有乘加在Config build与runtime使用checked int64。  
**Example:** `L=1→8+5+ceil(3/5)=14`；`L=10→8+50+60=118`。

### F2 — Cumulative XP and level cap

The `xp_total_to_level` formula is defined as:

`C(N)=checked_sum(T(L),L=1..N-1)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| target level | `N` | int64 | `[1,40]` | 到达目标等级 |

**Output Range:** `C(1)=0`，`C(40)=16552`。  
**Example:** `C(4)=14+21+29=64`；达到40级总需16552 XP。

### F3 — Utility weighted result

The `drop_utility_pick` formula is defined as:

`r=DROP.roll_int_range(1,W); winner=min{k|prefix_weight(k)>=r}`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| ordered weights | `w_i` | int32[] | 4 rows, each `>=0` | NONE/RECOVERY/MAGNET/BLAST |
| total | `W` | int64 | `[1,W_MAX_SAFE]` | production provisional=100000 |
| roll | `r` | int32 | `[1,W]` | 每eligible Normal death一次 |

**Output Range:** 一个 DropKind 或 NONE；资格失败映射NONE且不重抽。  
**Example:** provisional prefix `[99600,99850,99950,100000]`，`r=99970→BLAST`。

### F4 — Pickup predicate

The `drop_pickup_hit` formula is defined as:

`hit=distance_squared(drop_center,player_center)<=pickup_radius²`

**Variables:** `drop_center/player_center` 为 matching committed float64/readback position；`pickup_radius∈[1.8,1.98]`。  
**Output Range:** bool；边界相等为true，禁止加sprite radius。  
**Example:** radius1.8、距离1.8时命中；距离1.8001时不命中。

### F5 — XP application and level debt

The `level_advance` formula is defined as:

```text
for fact in matching_xp_pickup_facts ordered by fact_sequence ASC:
    remaining_to_cap = 16552 - total_applied_xp
    accepted_xp = min(fact.raw_xp, remaining_to_cap)
    xp_at_cap_delta = fact.raw_xp - accepted_xp
    x = checked_add(x, accepted_xp)
    total_applied_xp = checked_add(total_applied_xp, accepted_xp)
    while level < 40 and x >= T(level):
        x = x - T(level)
        level = level + 1
        append_preallocated_debt_row(level, fact.fact_sequence)
    if level == 40: x = 0
    xp_at_cap = saturating_add_i64(xp_at_cap, xp_at_cap_delta)
```

**Variables:** 每个`fact.raw_xp`为非负int64且逐fact处理；debt capacity=39。  
**Output Range:** level `1..40`、xp `0..T(level)-1`（level40为0）、`total_applied_xp=0..16552`、新增debt `0..39`，每条debt保留真实crossing fact。  
**Example:** 普通fresh run拾取64 XP，依次扣14/21/29，得到level4、xp0、3条独立request debt；聚气开局从`level2,total_applied_xp=14`开始，到L40剩余16538 XP且首个普通draft已经由起始credit触发。

### F6 — Pending SkillDraft capacity

The `skill_draft_pending_capacity` formula is defined as:

`S_PENDING=checked_add(max_pending_level_up_requests,max_pending_treasure_requests)=10+4=14`

**Variables:** Leveling exposed window=10；Drop treasure window=4。  
**Output Range:** exact 14；GameRoot global schema16仍需 RiskChoice contribution `<=2`。  
**Example:** 10个升级+4个宝匣同时存在时queue满14，额外升级留在39-row debt，不丢失或压缩。

### F7 — Physical cap conservation

The `drop_active_cap` formula is defined as:

`active_drop_count=xp_rows+recovery_rows+magnet_rows+blast_rows+treasure_rows<=290+3+2+1+4=300`

**Variables:** 各row count为非负int，受对应hard cap约束。  
**Output Range:** `0..300`；Pool configured capacity仍320。  
**Example:** 290 XP+3回春+2引灵+1爆炎+4宝匣=300，下一XP award只能merge，不能borrow第301个active。

## Edge Cases

- **If death staging有fact但缺完整identity/sequence**：Drop不猜测关联，整batch fault；远距退役不得伪装DEATH。
- **If同一death重复到达**：matching payload `OK_NOOP`；同identity冲突payload fault且不追加RNG call。
- **If XP rows已达290**：merge进canonical XP row；不丢有效cap内XP、不自动加给玩家。
- **If special roll命中但HP/cooldown/run cap不合法**：结果为NONE，不重抽、不补偿另一道具。
- **If四个宝匣同时进入pickup radius**：均可提交；第五个保持地面到下一Active tick。超过active hard cap4是配置fault。
- **If引灵符与普通XP重叠**：XP identity只进plan一次；引灵符不递归吸自己或其他功能物。
- **If pickup fact已commit但remove/reset失败**：reward exact-once保留，drop保持不可再claim，GameRoot收敛journal后fault。
- **If同一XP pickup跨越多级**：逐级debt，不合并choice；paused pump逐页读取最新loadout。
- **If普通候选只剩2/1项**：SkillDraft显示诚实二/一选一；0项只允许已到40级。
- **If terminal与pause同tick**：terminal胜出，不打开升级/宝匣页；不自动选择或把构筑带出本局。
- **If玩家远离Drop retention rect**：无奖励退役；不因无限地表观感自动入账。
- **If达到level40**：停止level request，XP bar显示MAX；后续XP不改变authority。
- **If爆炎符触发大量死亡**：只由新COMMITTED DEATH facts在后续合法Drop phase产奖励，每个敌人最多一次，不由Blast直接发XP。
- **If GameRoot workload仍要求503 active DROP**：当前生产workload判INCONCLUSIVE/BLOCKED，不扩Pool/Grid迎合陈旧数字。

## Dependencies

| Dependency | Type | Current boundary |
|---|---|---|
| GameRoot | Hard | phase/fact/journal/pause与two rows/contribution已传播；workload regen BLOCKED |
| EnemySystem | Hard | 8-field `EnemyDeathStagingV2`（含source_choice_id）已传播；独立复审/runtime evidence OPEN |
| Elite Enemies | Hard for Elite rewards | fixed6/7与Risk/summon provenance；160/300/240+treasure及summoned5零奖仍由本文结算 |
| Object Pooling | Hard | DropPoolable/v1、320 slots；runtime/memory evidence OPEN |
| SpatialGrid | Hard | DROP cap/query carrier300；已冻结 |
| Config/Data | Hard | DropConfigV1/LevelingConfigV1与owner rows已传播；content hash/runtime evidence OPEN |
| RNG | Hard for utility | DROP fixed-call；跨架构/runtime evidence OPEN |
| PlayerController | Hard for pickup/recovery | position/radius/HP只读；radius 1.8..1.98已冻结 |
| DamageSystem | Hard for items | recovery存在；blast ABI BLOCKED |
| SkillDraft | Hard | 10+4 queue、debt transfer与3/2/1 reduced-choice已传播；独立复审OPEN |
| RiskChoice | Hard for final capacity | 已冻结两次event、2 risk treasure与blocking=2；作者设计待独立复审 |
| BattleUI | Hard for experience | XP bar/item/choice UI未设计 |
| Settlement/Save | Soft runtime, hard final | 读取final level/reward；Designed / Full Review Pending，integration BLOCKED |
| Progression Tree | Hard next-run pickup modifier | 大衍level0..5发布`pickup_radius=1.8*(1+0.02D)`；当前局只读matching projection |

## Tuning Knobs

| Knob | Initial value/domain | Status |
|---|---|---|
| XP curve | `8+5L+ceil(3L²/5)` | concept locked, balance unverified |
| level cap | 40 | structural locked |
| enemy XP | `1/2/4/6/8/3`, Elite `160/300/240` | PROVISIONAL-BALANCE |
| utility weights | `99600/250/100/50` per100000 | PROVISIONAL-BALANCE |
| total utility chance | 0.40%, safe `0.20%..0.80%` | provisional |
| item cooldowns | 90/120/180 gameplay sec | provisional |
| item run caps | 3/2/1 | provisional |
| pickup radius | 1.8..1.98 | locked upstream |
| active Drop/Grid | 300 | locked upstream |
| Drop pool | 320 | locked upstream |
| XP/special physical split | 290/10 | structural initial |
| Leveling debt/window | 39/10 | structural initial |
| Treasure active/window | 4/4 | LOCKED；RiskChoice已证明2 risk+2 fixed≤4 |
| blast Elite ratio | `[0,1]` | BLOCKED-BLAST-ABI |

调参顺序固定为：先冻结 WaveSchedule/每类击杀数，再调敌人 XP，再调曲线系数；不得用扩大拾取半径掩盖产出问题。观测必须区分 generated/picked/expired/at-cap XP、每分钟等级、单次连升、utility命中/被资格拒绝与移动/站桩分组。

## Visual/Audio Requirements

- XP 微光、XP 结晶、回春、引灵、爆炎、法宝匣必须以轮廓/图标/运动语言区分，不只靠颜色；宝匣优先级最高。
- PICKUP fact commit前不播放“已获得”重音；commit后可用独立presentation trail飞向玩家，不能让视觉Tween成为gameplay position权威。
- 大额XP合并只改变表现档位，不制造额外拾取音；引灵符大量吸取需限并发音效并保留一次主反馈。
- `DROP_EXPIRED`、REVIVE_CLEAR、OFFSCREEN_RETIRE无奖励音效/VFX。Pool overflow/fault不能伪装普通拾取。
- 首次升级、普通升级、进化、达到MAX使用不同强度；终局优先时不叠加升级弹窗重音。

📌 **Asset Spec** — 本系统已定义掉落物与拾取/升级反馈需求；Art Bible批准后应运行 `/asset-spec system:drop-leveling-system`。

## UI Requirements

- Battle HUD 显示 `LV.N`、当前XP/下一阈值与确定性进度条；40级显示MAX，不显示伪造的下一阈值。
- 同tick连升可先显示“连续突破×N”，但每个 SkillDraft choice仍独立、不可批量自动选择。
- 二选一/单卡确认必须真实反映候选数，不复制卡伪装三选一；页面显示当前等级、目标技能层级与剩余debt。
- 功能物用短标签说明实际效果；回春满血实际恢复0时不得显示虚假治疗数值。
- terminal winner出现后不打开新升级/宝匣页；stale view不推进进度条或重复播放反馈。

📌 **UX Flag — DropSystem + Leveling/XP**: XP bar、掉落可读性、连升队列与 reduced-choice 页面需在实现 story 前运行 `/ux-design`。

## Acceptance Criteria

- **AC-DL01 `[U][I][BLOCKING]` 双owner/phase**：**GIVEN** 两participant与所有错误phase，**WHEN**执行完整tick，**THEN** rows逐字段等于R1；Drop不写HP/level/loadout/pause，Leveling不写Drop/HP/loadout/pause，自主callback与带参signal为0。
- **AC-DL02 `[U][I][BLOCKING]` reward eligibility**：**GIVEN** Normal/Elite/Boss DEATH、OFFSCREEN_RETIRE、REVIVE_CLEAR、suppressed spawn、summoned puppet，**WHEN**处理，**THEN**只有R3合法行产对应XP/utility/treasure/reward；禁奖路径及DROP calls均0。
- **AC-DL03 `[U][BLOCKING][PROVISIONAL-BALANCE]` XP table**：**GIVEN**每个behavior/provenance及缺/重配置，**WHEN**build snapshot，**THEN**合法表逐值匹配、summoned puppet=0、非法表在Node创建前失败；WaveSchedule/试玩未完成前数值gate OPEN。
- **AC-DL04 `[U][I][BLOCKING]` fixed DROP RNG/eligibility**：**GIVEN**eligible death 0/1/300、matching/stale `PlayerHpAuthorityViewV1`、仅非Player owner推进authority revision、HP ratio 0.70两侧、同tick后续damage、cooldown tick required−1/required/+1、Paused、跨局reset、资格命中/拒绝及第N次RNG fault，**WHEN**解析，**THEN**full-copy后的Player HP slice仍matching且只读，calls精确0/1/300且无重抽；边界相等可用，Paused不推进cooldown，真正stale/fault不切plan、不改变旧authority。
- **AC-DL05 `[U][I][BLOCKING]` physical cap/merge**：**GIVEN**各subtype required−1/required/required+1与290 XP满载，**WHEN**award，**THEN**active<=300、XP merge checked且canonical、special reserve不被借用、Grid/Pool无301st active或ghost。
- **AC-DL06 `[U][I][BLOCKING]` award/spawn carrier lifecycle**：**GIVEN**DropAward 606与Materialize 300的required−1/required/+1、重复key、stale generation及Pool borrow/reset/Grid insert/bind逐checkpoint fault，**WHEN**解析并在下tickphase1物化，**THEN**plan header/row/canonical key逐字段匹配；三个runtime ID按PLANNED→BOUND状态逐项从0产生，只有BOUND建立完整RuntimeRow。失败在规定边界前零mutation或按上游契约remove/unbind/release/fault，RNG/award不重放且无ghost。
- **AC-DL07 `[U][I][BLOCKING]` pickup query**：**GIVEN**radius1.8/1.98、边界内外、stale handle/borrow与buffer299/300/301，**WHEN**phase4/5，**THEN**只接受center distance<=radius且required capacity300，Player侧Grid calls=0，无shape半径扩张或silent truncation。
- **AC-DL08 `[I][BLOCKING]` pickup/Leveling prefix PONR**：**GIVEN**2/290条XP与混合special，Drop reserve、Leveling逐fact算术/debt/request prefix预写、arm，以及第N条fact commit前/后、selector/effect/remove/unbind/reset各checkpoint fault与100次replay，**WHEN**phase6收敛，**THEN**arm前public mutation为0；只有实际连续COMMITTED prefix的XP/debt/request恰一次，suffix为0，snapshot/debt/request selector全batch恰切一次，commit后Drop不可再拾，journal/debt state单调。
- **AC-DL09 `[U][I][BLOCKING]` magnet expansion**：**GIVEN**0/1/290 XP与混合special、重复query rows，**WHEN**拾取引灵符，**THEN**只扩展所有matching AVAILABLE XP且去重，facts/lifecycle总数<=300，其他special保持。
- **AC-DL10 `[I][BLOCKING]` recovery boundary**：**GIVEN**HP0..max、致命damage同tick与stale intent，**WHEN**回春拾取，**THEN**Drop只发0.30 ratio intent；Damage/Player按下一合法tick与既有damage→lethal→heal规则提交实际HEAL，Drop直接HP写0。
- **AC-DL11 `[I][BLOCKED-BLAST-ABI]` blast**：**GIVEN**Normal/Elite/Boss及同源重放，**WHEN**爆炎提交，**THEN**Drop直接HP/lifecycle/XP写0，Damage处理Normal/Elite、Boss0；后续仅matching DEATH产一次reward。ABI/ratio未冻结前不得PASS。
- **AC-DL12 `[U][BLOCKING]` F1/F2 golden**：**GIVEN**L1..39与边界恶意int，**WHEN**计算，**THEN**T1=14、T2=21、T3=29、T10=118、T39=1116、C4=64、C40=16552；overflow在mutation前失败。
- **AC-DL13 `[U][I][BLOCKING]` per-fact multilevel/cap**：**GIVEN**普通fresh XP=64、聚气`starting_level_curve_credit=14`、相同总XP的不同fact分片/顺序、一次跨1..39级、跨cap超额及duplicate/stale，**WHEN**F5，**THEN**普通路径结果不变；聚气路径初始`level=2/xp=0/total_applied_xp=14`、remaining=16538且恰有ordinal1普通choice，每个后续跨级row绑定真实crossing fact，`total_applied_xp<=16552`，queue最多10、其余保留debt，无quantity压缩或丢失。
- **AC-DL14 `[U][I][BLOCKING]` paused debt pump**：**GIVEN**39-row debt bank required−1/required/+1、debt>10及matching/duplicate/stale/conflict capability和每个choice commit/fault，**WHEN**control pump串行处理，**THEN**header/generation/cursor逐字段matching，只在空槽转移预存row、duplicate OK_NOOP、每页基于最新loadout、XP/timer不推进、全部完成前resume=0。
- **AC-DL15 `[U][I][BLOCKING]` request order/capacity**：**GIVEN**10 levels+4 treasures、同一精英XP/宝匣同tick共同拾取及分别先后拾取，**WHEN**enqueue，**THEN**同tick按XP→treasure、分tick按实际fact序，每页读取相应loadout revision；S_PENDING=14，required−1失败/required成功/+1不得写；RiskChoice contribution必须逐字段等于2且全局sum=16。
- **AC-DL16 `[I][BLOCKING]` reduced choice**：**GIVEN**candidate count3/2/1/0，**WHEN**普通draft，**THEN**显示3/2/1真实不同合法项；0仅level40无新request，非40为fault，无复制/自动首选。
- **AC-DL17 `[I][BLOCKING]` pause/terminal**：**GIVEN**level/box request与FATAL/VICTORY/DEFEAT/ABANDONED组合，**WHEN**phase7，**THEN**terminal优先时choice UI=0、未选request exact cancel、无自动loadout变化；Paused gameplay推进全0。
- **AC-DL18 `[I][BLOCKING]` expire/无限空间**：**GIVEN**Drop位于retention内/边/外及Player大位移/复活snap，**WHEN**评估，**THEN**仅严格外侧无奖励退役，XP/reward/request/audio=0，有限技术域不表现为可见边界。
- **AC-DL19 `[I][BLOCKING]` teardown/跨局**：**GIVEN**各staged/debt/fault状态，**WHEN**teardown并开新局，**THEN**views/capability先invalid、generation推进，旧fact/token/command全拒绝，新局level1/xp0/debt0。
- **AC-DL20 `[P][BLOCKING-TOOLING][INCONCLUSIVE-WITHOUT-GUARD]` 零分配**：**GIVEN**production roots、known-good/bad fixtures与native allowlist，**WHEN**静态guard+10000 tick，**THEN**Active/Paused热路径无容器构造/growth/COW/Callable/带参signal/unstable sort/backing replacement；工具或positive control缺失只判INCONCLUSIVE。
- **AC-DL21 `[P][E][OPEN-EVIDENCE]` 15分钟节奏**：**GIVEN**min-spec release build、冻结Wave/XP/Drop config与预登记路线，**WHEN**独立试玩/回放，**THEN**首次升级<=30秒、4分钟L8..10、6..8分钟首次进化、通关L28..34，并报告generated/picked/expired XP与utility分布；当前灰盒仅证明短闭环，不能PASS本项。
- **AC-DL22 `[I][BLOCKED-WORKLOAD-REGEN]` workload一致性**：**GIVEN**Drop active300/pool320/Grid300与当前RW active vector，**WHEN**Config/runner校验，**THEN**`503 DROP` fixture被拒绝；只有完整重生成active/operation/hash后才可成为production evidence。
- **AC-DL23 `[U][I][BLOCKING]` death staging ABI**：**GIVEN**完整8字段staging、逐字段缺失、两次Risk同behavior反序死亡、stale borrow、duplicate matching/conflict与同tick303 deaths，**WHEN**Drop join committed DEATH facts，**THEN**仅完整matching row按sequence/source choice消费一次，duplicate为OK_NOOP、冲突在额外RNG/plan mutation前fault，Enemy与Drop schema逐字段相同。
- **AC-DL24 `[U][I][BLOCKING]` core herb staging→fact→Outcome**：**GIVEN**1-row stage required−1/required/+1、matching Boss death、普通VICTORY、VICTORY+lethal、FATAL优先、duplicate/conflict与phase-6 stage/reserve/REWARD commit、phase-7 seal各checkpoint fault，**WHEN**BATTLE_RULES处理matching precollection token，**THEN**precollected VICTORY按R3逐字段映射并提交一次amount1通用REWARD fact，FATAL为0；只有同fact sequence/同token最终sealed VICTORY由Outcome join，非VICTORY技术审计fact不结算。phase7新fact=0、Drop gameplay fact/Pool/Grid写入=0，重放不重复。
- **AC-DL25 `[U][I][BLOCKING]` carrier/generation completeness**：**GIVEN**R5/R6/R8/R9全部bank/plan/capability的required−1/required/+1、bank flip、stale battle/config/revision/generation与teardown/new-run，**WHEN**读写，**THEN**逐字段schema/capacity/canonical key匹配，合法计划exact publish，非法计划在PONR前0 mutation，旧能力全部拒绝且热路径不扩容。

## Open Questions

| ID | Status | Required decision/evidence | Owner |
|---|---|---|---|
| OQ-DL01 | `PROVISIONAL-BALANCE` | 敌人XP、utility weights/cooldown/run cap经WaveSchedule与15分钟试玩冻结 | Game/Economy/QA |
| OQ-DL02 | `BLOCKED-BLAST-ABI` | 爆炎Normal execution、Elite比例、全场scan与Damage capacity | Damage + Enemy + Config |
| OQ-DL03 | `RESOLVED-RISK-CAPACITY` | 两次机缘的Elite/宝匣provenance=2且RiskChoice blocking contribution=2；2 risk+2 fixed=4 | RiskChoice + GameRoot |
| OQ-DL04 | `BLOCKED-TREASURE-EXHAUSTION` | 40级且无进化/未满已装备技能时宝匣补偿；不得擅加永久货币 | Economy + SkillDraft |
| OQ-DL05 | `BLOCKED-WORKLOAD-REGEN` | 重生成GameRoot RW01..11，修复503 DROP与384 projectile的可运行fixture | GameRoot + Config + Perf |
| OQ-DL06 | `RESOLVED-CROSS-DOC-PENDING-REVIEW` | Enemy death staging已补fact sequence、enemy identity与spawn provenance；待独立复审 | Enemy + GameRoot |
| OQ-DL07 | `DESIGN ANSWERED / RUNTIME BLOCKED` | 聚气丹以`starting_level_curve_credit=14`在Active前完成普通ordinal1 SkillDraft choice；remaining XP=16538，待集成/试玩证据 | Zhangtian + Leveling + SkillDraft |
| OQ-DL08 | `BLOCKED-BATTLEUI/UX` | XP bar、连升、reduced-choice、item反馈与移动端触控 | BattleUI + UX |
| OQ-DL09 | `RE-REVIEW-PENDING` | clean-context full review及Godot/GDUnit4/min-spec/runtime证据 | Review owner |
