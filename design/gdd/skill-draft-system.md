# SkillDraftSystem

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：STEAM_MISSION_V1/STEAM_SAVE_V2的目标、终态与完整恢复要求见mission-objectives.md、save-steam-pc.md及ADR-0006。本owner的目标身份/生命周期（适用时）、matching-tick snapshot、schema/validator/migration、required-owner与容量贡献待正式冻结并接线；下方legacy合同不因本路由而自动满足新profile，缺失时禁止生产启用。

> **Status**: In Review / Re-review Pending
> **Author**: User + Codex
> **Last Updated**: 2026-09-08 — Zhangtian第七次独立full review后OLD/NEW scratch reconcile整改传播
> **Implements Pillar**: 功法构筑与进化；谨慎取舍、留有后手
> **Review Mode**: lean

## Overview

SkillDraftSystem 是单局功法构筑、升级选择与神通进化提交的唯一 owner。它接收 Leveling 的升级请求和精英宝匣请求，在战斗暂停后从 6 个主动技能、6 个辅助功法构成的合法候选池中生成最多三项的确定性选择，管理每局基础两次、若大衍诀L5则三次免费刷新，并把玩家选择原子发布为下一 gameplay tick 生效的 `SkillLoadoutSnapshotV1`。它不计算 XP、不决定武器伤害、不直接修改 cooldown/Buff/HP，也不让 UI 成为构筑权威。

## Player Fantasy

每次升级都应像一次有信息的取舍：玩家能看懂当前构筑缺什么、哪张辅助功法能铺垫进化、继续强化旧招还是开辟新路线。随机性负责制造不同局势，基础两次、大衍诀圆满后三次免费刷新负责给谨慎玩家留后手；保底规则避免连续“没有可用强化”的挫败，但不会自动替玩家选出唯一最优解。

当五层主动技能与对应辅助功法齐备、精英宝匣出现时，玩家应明确感到此前布局兑现为神通，而不是系统在背后偷偷进化。相同 seed、构筑和选择必须得到同样的候选序列，方便复盘和调参。

## Detailed Design

### Core Rules

#### R1 — 权威与阶段

- SkillDraftSystem 独占 active/passive slot identity、level、evolution ID、draft/refresh ordinal、guarantee streak、choice token 与 loadout snapshot。
- required participant 固定 `stable_order=8`，只在 `POST_DEFERRED_BARRIER` 接收已提交的 level-up/treasure-box request并请求 blocking pause；实际候选生成、刷新、选择与恢复由 GameRoot persistent control pump 通过版本化 capability 驱动。
- Paused choice capability 可消费 `SKILL_DRAFT`/`TREASURE_BOX` RNG，但不得推进 gameplay tick、Weapon cadence、Buff duration、Enemy、Projectile、XP 或伤害。
- SkillDraft 不直接写 Weapon runtime、Damage snapshot、Player stats、XP/drop或UI Node。

`SKILL_DRAFT_PHASE_ROW_V1={participant_id=SKILL_DRAFT,role_id=SKILL_DRAFT,stable_order=8,allowed_phases={POST_DEFERRED_BARRIER},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=SkillDraftSystem/v1,owner_gdd_path=design/gdd/skill-draft-system.md,phase_row_id=SKILL_DRAFT_PHASE_ROW_V1,required=true}`。

owner contribution 为 `LIFECYCLE_INTENT=0,FACT_COMMIT=0,PAUSE_CLOSURE=0,BLOCKING_CHOICE=S_PENDING`；`S_PENDING=max_pending_level_up_requests+max_pending_treasure_requests=10+4=14`，由 Leveling/Drop 的冻结上界 checked sum并计入GameRoot总上限16。同一时刻最多一个前台 choice，多个请求串行处理；多于10个升级请求留在Leveling 39-row debt，不丢失、不压缩。

#### R2 — 构筑域与初始状态

- 主动槽 4、辅助槽 4；catalog 为 6 主动 + 6 辅助；每项 level 1..5；同 family 只能占一个槽。
- 新局初始 `QINGYUAN_SWORD_QI` level 1 占 active slot 0，其余为空；matching Progression projection令refresh charges=`2+extra_free_refreshes`，范围2..3，两个 guarantee counters=0。若matching聚气丹projection，GameRoot在`PRE_ACTIVE_CHOICE`、Active/movement/survival前创建恰1个普通`LEVEL_UP` choice request，`source_fact_kind=PREPARATION_CURVE_CREDIT`、`draft_ordinal=1`；其候选、early guarantee、strengthening streak与普通首个升级完全相同。base offer页不扣refresh，玩家主动刷新才按R6扣1；提交后Leveling为`level=2,xp=0,starting_level_curve_credit=14,total_applied_xp=14`，再进入Loading的ActiveEntry checkpoint。该请求不与Leveling/Risk treasure并发，不改变14-row active queue上界。
- 聚气路径的base offer、每次refresh与choice commit不是仅内存状态：每次成功publish前，GameRoot把完整replay字段写入同一360-byte `RunStartRecoveryV1`并durable readback，包括choice/request、offer revision/hash、refresh used/remaining、selected candidate、durable semantic generation/draft/rule/streak、config content identity、command、loadout revision/hash、SkillDraft RNG cursor与next sequence。base offer记录`request_sequence=1`；commit后固定`next_level_request_sequence=2`并推进Prep checkpoint6。callback loss/restart按R7协议重建同一offer rows或已提交loadout，不再抽取；任一重复字段或replay不等为CONFLICT。玩家不拥有pre-durable cancel公共动作；base offer前deterministic build失败只能按GameRoot LFD25系统级durable RELEASE，首个offer一旦durable，Back/关闭/重启只恢复同一offer，不得release后生成fresh随机页。
- 普通升级候选类型仅 `NEW_ACTIVE/UPGRADE_ACTIVE/NEW_PASSIVE/UPGRADE_PASSIVE`；普通升级不直接进化。
- 满槽时过滤对应 `NEW_*`；level 5 项过滤 `UPGRADE_*`；已进化主动不再出现基础技能升级。

#### R3 — 普通候选池

- 每个 family 在一次 draft 中最多贡献一张当前合法的 next-step card，因此候选上限固定 12。
- 候选按 `candidate_kind_order → family_id → target_level` 排序后写入预分配 bank；不得依赖 Config、Dictionary 或 UI 顺序。
- 基础权重使用非负 int32 定点值。冻结关系为 `owned_unmaxed_weight > new_skill_weight > 0`；能补齐已持有五层主动进化条件的辅助功法再加 `evolution_pair_bonus`，且 `0 < bonus < new_skill_weight`，保持“轻微加成”。具体值由 Config/试玩冻结。
- 正常 offer 的 `offer_size=min(3,legal_candidate_count)`，发布 3/2/1 张互不相同的合法 card；候选不足3时诚实显示三/二/一选一，不得复制、塞入非法满级项或临时发明奖励。`legal_candidate_count=0` 只允许已到Leveling硬上限40且没有新升级request；否则为 authority/config fault。

#### R4 — 两种保底

- `early_new_active_guarantee`：第 1、2 个普通 level-up draft，在 active slot 未满且仍有未拥有主动时，slot 0 必须从 `NEW_ACTIVE` 子池抽取；否则记录 `NOT_APPLICABLE`，不伪造候选。
- `strengthening_guarantee`：若前两个已完成的普通 draft offer 都没有出现 `UPGRADE_ACTIVE/UPGRADE_PASSIVE`，第三个 draft 的 slot 0 必须从当前合法 owned-unmaxed 子池抽取；子池为空时 `NOT_APPLICABLE`。
- `no_strengthening_offer_streak` 只根据最终被选择前的当前 offer 是否包含强化卡更新，与玩家选了哪张无关；最大 2，出现任一强化卡后归 0。
- refresh 属于同一个 draft ordinal，不推进 early counter或streak；最终提交 choice 后才更新一次。
- 当前 session 的每一版 refresh offer 都必须重新满足 session 打开时锁定的 guarantee bits，不能通过刷新绕过保底。

#### R5 — 1..3张卡与固定 RNG 调用

- 每份 offer 令 `n=min(3,legal_candidate_count)`，精确执行 `n` 个无放回 weighted selections，再执行 `n-1` 次固定 Fisher-Yates display permutation；合计精确消费 `2n-1` 次 `SKILL_DRAFT` roll，即n=1/2/3分别为1/3/5次。保证 selection slot 从对应强制子池抽取，其余 slot 从剩余总池抽取；两种保底同时适用时它们来自互斥candidate kind，故合法池至少2且分别占一个selection slot。
- 选中一张后把该 candidate 从本次 workspace 移除；禁止 rejection loop、native shuffle或可变次数重抽。
- 任一步 RNG fault、总权重非法、`legal_candidate_count=0`却存在request或 bank overflow 都使整份 offer 不发布且不消耗 refresh/counters。普通Active draft仍按RNG fault协议终止且不得retry/reseed；pre-active必须使用下述`PreActiveRngWindowLeaseV1`，失败时只丢弃scratch，权威cursor从未推进，不存在“RNG已消费但offer未记录”的状态。
- offer row identity 为 `(draft_request_id,offer_revision,slot_index,candidate_id)`；n张按 slot `0..n-1` 发布。pre-active的`offer_revision`从1开始，`slot_index=stable_order=0..2`，其持久`candidate_id=checked_add(checked_mul(offer_revision-1,4),slot_index+1)`；因此同seed/content/history跨进程生成相同ID，且不复用上一offer的1..3号。非pre-active运行时choice仍用本局bank identity，不写入durable semantic carrier。任一checked arithmetic失败在publish前fail closed。

#### R6 — 刷新

- 每局基础2次免费刷新；仅matching大衍诀L5 projection增加1次，初始范围2..3。只有处于已发布、未选择的普通 offer 才可刷新。
- 合法刷新先取得`PreActiveRngWindowLeaseV1={reservation_id,old_cursor,next_offer_revision,roll_count,scratch_state,next_cursor,offer_semantic_hash}`：从old cursor复制到预分配scratch，按当时`n`精确试算`2n-1`次`SKILL_DRAFT` roll，不写权威stream。包含next cursor、next revision、remaining charge与完整semantic offer的`UPDATE_RECOVERY`双镜像readback成功后，才在一个主线程无callback commit内发布权威cursor+offer并减1 charge。PONR前FAILED丢弃scratch，旧cursor/offer/charge/revision逐位不变且允许重新尝试；UNCERTAIN关闭refresh并只reconcile。Save必须返回selected formal reservation hash：`RECONCILE_FOUND+next hash`采用durable next并commit scratch，`RECONCILE_FOUND_OLD+old hash`discard scratch并保持old cursor/offer/charge/revision，`RECONCILE_NOT_FOUND_UNPROVEN`继续冻结；任一code/hash错配fault。全reservation `PROVEN_ABSENT`不得替代既有reservation update的OLD证明。普通Active refresh不走durable lease，任何draw fault直接关闭该request且不得沿旧offer再次refresh。
- 新 offer 内仍为n张互异合法卡，但允许与上一版部分或全部相同；不为“看起来不同”增加 rejection RNG。
- treasure-box choice 不消耗普通刷新次数。

#### R7 — 选择提交与下一 tick 生效

- request 固定为 `SkillChoiceRequestV1={schema_version,battle_instance_id,config_snapshot_id,source_authority_revision,request_id,request_kind,source_fact_kind,source_fact_sequence,source_id,request_sequence}`；quantity>1必须在入队前展开为一request一choice。聚气只允许`request_kind=LEVEL_UP,source_fact_kind=PREPARATION_CURVE_CREDIT,source_fact_sequence=0,request_sequence=1`，不得另造弱化的PREPARATION候选类型。
- session token 固定为 `SkillChoiceSessionTokenV1={battle_instance_id,config_snapshot_id,blocking_choice_id,request_id,choice_kind,source_authority_revision,source_loadout_revision,draft_ordinal,generation_index,offer_bank_id,offer_publish_revision,rng_call_begin,rng_call_end,free_refreshes_remaining,required_rule_bits,session_generation,valid}`。
- UI 只能回传 `DraftChoiceCommandV1={session_token_subset,command_id,command_kind,selected_candidate_id_or_0,expected_offer_publish_revision}`；SkillDraft 从已发布 bank读取 card，不接受 UI 自带 payload。
- 第一个 matching command 原子应用到 inactive loadout bank，验证槽位/level/family后发布 `SkillLoadoutSnapshotV1`，`effective_tick=next_active_tick`；duplicate 同 payload 为 `OK_NOOP`，冲突/stale command拒绝。
- publish 成功后更新 draft counters、关闭 blocking choice并允许 GameRoot resume。Weapon/Damage 在当前暂停和旧 tick继续读旧 snapshot。
- `SkillLoadoutSnapshotV1` 为 A/B SoA；header固定 `{schema_version=1,battle_instance_id,config_snapshot_id,bank_id,loadout_revision,source_authority_revision,effective_gameplay_tick_revision,active_count,aux_count,free_refreshes_remaining,committed_level_up_draft_count,reinforcement_miss_streak,generation,valid}`。
- active SoA容量4，字段为 slot/family/skill/level/form/config-row IDs；aux SoA容量4，字段为 slot/family/skill/level/config-row IDs。权威区间只含`[0,count)`并按slot升序；tail不权威，不返回可写alias。
- 跨进程比较不得hash上述runtime header。持久语义固定为：

```text
PreActiveCandidateSemanticRowV1={candidate_id:i64,family_id:i32,
  skill_id:i32,target_slot_id:i32,next_level:i32,form_id:i32,stable_order:i32}
PreActiveOfferSemanticV1={schema_version:i32=1,reservation_id:i64,
  battle_instance_id:i64,request_id:i64,config_content_revision:i64,
  config_content_hash:Hash256,offer_revision:i64,refreshes_used:i32,
  free_refreshes_remaining:i32,draft_ordinal:i32,required_rule_bits:i32,
  reinforcement_miss_streak:i32,rng_call_begin:i64,rng_call_end:i64,
  rng_cursor:i64,candidate_count:i32,
  candidates:PreActiveCandidateSemanticRowV1[3],semantic_hash:Hash256}
PreActiveLoadoutSemanticV1={schema_version:i32=1,reservation_id:i64,
  battle_instance_id:i64,config_content_revision:i64,
  config_content_hash:Hash256,loadout_revision:i64,active_count:i32,
  aux_count:i32,free_refreshes_remaining:i32,
  committed_level_up_draft_count:i32,reinforcement_miss_streak:i32,
  active_rows:ActiveLoadoutSemanticRowV1[4],
  aux_rows:AuxLoadoutSemanticRowV1[4],semantic_hash:Hash256}
```

  `PreActiveCandidateSemanticRowV1`固定32 bytes；`ActiveLoadoutSemanticRowV1={slot_id,family_id,skill_id,level,form_id,config_row_id}`固定24 bytes，`AuxLoadoutSemanticRowV1={slot_id,family_id,skill_id,level,config_row_id}`固定20 bytes。offer/loadout semantic分别固定252/296 bytes，未使用fixed-capacity tail逐byte为0并参与hash。semantic carrier明确排除`config_snapshot_id/source_authority_revision/effective_gameplay_tick_revision/blocking_choice_id/generation_index/offer_bank_id/session_generation/bank_id/generation/valid`等process-local、bank或presentation字段；这些字段只在exact content key验证后由GameRoot为新进程重新绑定，绝不与durable semantic hash比较。`PreActiveRngWindowLeaseV1`仅是同线程临时scratch，不持久化、不跨帧公开；可恢复真相只存在于old recovery或已双镜像readback的新recovery。
- 聚气预开局选择使用Zhangtian/Save的360-byte `RunStartRecoveryV1`，不得只存offer/loadout hash。每版可见offer前先durable写入`pre_active_offer_revision,pre_active_refreshes_used,pre_active_free_refreshes_remaining,pre_active_semantic_generation,pre_active_draft_ordinal,pre_active_required_rule_bits,pre_active_reinforcement_miss_streak,config_content_revision,config_content_hash,pre_active_skill_draft_rng_cursor,pre_active_offer_hash`；choice durable时再写`pre_active_selected_candidate_id,pre_active_choice_command_id,pre_active_committed_loadout_revision,pre_active_loadout_hash,next_level_request_sequence=2`。`pre_active_semantic_generation`purely durable：每局该唯一pre-active session固定为1，不得从runtime `session_generation`、bank或presentation generation复制；对应runtime token在每个新进程重新分配且不参与durable比较。
- 跨进程恢复固定使用deterministic replay：该预开局页是本局`SKILL_DRAFT` stream首个consumer；以durable run seed、逐位相等的`config_content_revision+config_content_hash`、青元L1/其余空的canonical initial loadout及记录的draft history重放base页和`pre_active_refreshes_used`次**已durable** refresh。scratch draw从不计入history；只有同reservation update durable后，其next cursor与revision才成为下一次replay输入。`pre_active_offer_hash/pre_active_loadout_hash`分别且只等于上述252/296-byte semantic carrier的self-hash；新进程先验证semantic bytes/hash，再把当前process-local snapshot/bank/generation写入新的runtime carrier，不要求也不得伪造旧local ID相等。每版cursor/semantic hash/offer revision/rule bits/streak/remaining必须相等；若choice已durable，selected candidate必须存在于重建semantic offer，并以原command ID应用到initial semantic loadout后得到相同semantic loadout revision/hash。任一不等即fault并保持Active关闭；禁止从hash反推card、默认第一张、重新让玩家选择已durable结果或产生第二次logical offer。

#### R8 — 精英宝匣与进化

- 宝匣请求首先枚举“active level 5 + 已持有对应 passive + 尚未进化”的合法 evolution，最多4项；雷爆符与乙木灵藤无MVP evolution。
- 有1项时仍显示确认卡；有多项时列出全部合法项，由玩家选1项，不消耗 RNG。提交后原子替换同一 active slot 的 form/evolution ID，下一 Active tick生效。
- 若无合法进化，则从所有已持有且未满级的 active/passive 项中按 canonical order，用 `TREASURE_BOX` stream精确一次 weighted selection并自动提升1级。
- 若既无进化也无未满技能，不发明奖励，进入 `TREASURE_EXHAUSTION_BLOCKED`，等待 Drop/Leveling/经济 GDD冻结 fallback。

#### R9 — Pause、队列与错误

- choice 打开前必须由 GameRoot 完成当前 tick barrier；SkillDraft 不自行写 `SceneTree.paused`。
- 一次只暴露一个 blocking choice。预分配 FIFO 精确容量14，其中Leveling可见窗口10、Drop宝匣窗口4；Leveling通过`LevelingDebtTransferCapabilityV1`在Paused control pump每腾出一个level slot时搬入下一条已展开debt。该能力不加XP/level、不推进gameplay timer。
- 任一 token/revision/capacity/Config/RNG fault 锁存首错并保持 gameplay consumer关闭；不得自动选第一张、吞掉请求或恢复战斗。
- teardown 先 invalid offer/loadout views再推进 generation；旧 command不能作用于新局。

### States and Transitions

| State | Meaning | Allowed next |
|---|---|---|
| UNBOUND | 未绑定 battle/config/RNG | READY, FAULTED |
| READY | 无当前选择，可接收 request | PAUSE_REQUESTED, FAULTED, TORN_DOWN |
| PAUSE_REQUESTED | 等待 GameRoot pause barrier | GENERATING, FAULTED |
| GENERATING | 构造 inactive offer | OFFER_PUBLISHED, FAULTED |
| OFFER_PUBLISHED | 等待 select/refresh | GENERATING, COMMITTING, FAULTED |
| COMMITTING | 写 inactive loadout并提交 | READY, FAULTED |
| FAULTED | 首错锁存，consumer关闭 | TORN_DOWN |
| TORN_DOWN | view invalid | UNBOUND |

Treasure box复用相同外层状态，但 `offer_kind=EVOLUTION_CONFIRM/EVOLUTION_CHOICE/AUTO_LEVEL_FALLBACK`；普通 refresh 只允许 `OFFER_PUBLISHED→GENERATING`。

### Interactions with Other Systems

| System | Input | Output / boundary |
|---|---|---|
| GameRoot | pause barrier、blocking-choice pump、token | SkillDraft不写SceneTree pause；BLOCKING_CHOICE贡献14 |
| Leveling/XP | committed level-up requests | 不计算XP/等级阈值；串行消费请求 |
| DropSystem | committed elite treasure-box requests | 不生成掉落；只处理宝匣构筑结果 |
| RNG System | SKILL_DRAFT/TREASURE_BOX streams | 普通offer按n=1/2/3固定1/3/5 calls；宝匣fallback固定1 call |
| Config/Data | catalog、weights、evolution map、capacity | Active/Paused只读 immutable snapshot |
| WeaponSystem | — | next-tick `SkillLoadoutSnapshotV1`；不改cadence runtime |
| DamageSystem | — | 被动/状态来源随loadout revision解析；不直接写modifier bank |
| BattleUI | choice commands | UI只显示published rows，不提交自带payload |

## Formulas

所有权重为非负定点整数，累加使用 checked int64 并满足 RNG `W_MAX_SAFE`；不使用 float 权重、取模或 rejection loop。

### F1 — Candidate resolved weight

The `candidate_weight` formula is defined as:

`w(c)=base_weight(kind)+owned_upgrade_bonus(c)+evolution_pair_bonus(c)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base weight | `B` | int32 | `[1,INT32_MAX]` | candidate kind 基础权重 |
| Owned bonus | `U` | int32 | `[0,INT32_MAX]` | 仅已有未满技能；要求最终权重高于普通 new |
| Pair bonus | `E` | int32 | `[0,B-1]` | 匹配已持有主动进化条件的辅助功法轻微加权 |

**Output Range:** 正整数且所有 eligible weights 总和 `<=W_MAX_SAFE`。
**Example:** 仅作结构示例，若 `B=100,U=30,E=20`，已有且匹配的辅助升级权重为150；production 数值仍 `OPEN-WEIGHTS`。

### F2 — Weighted selection without replacement

The `weighted_pick` formula is defined as:

`r=SKILL_DRAFT.roll_int_range(1,Σw); winner=min{k | prefix_sum(k)>=r}`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Eligible row weights | `w_i` | int32[] | length `1..12` | 当前 slot 强制子池或剩余总池 |
| Total weight | `W` | int64 | `[1,W_MAX_SAFE]` | checked sum |
| Roll | `r` | int32 | `[1,W]` | 当前 offer slot 唯一 RNG call |

**Output Range:** 一个合法 candidate identity；选中后从本页 workspace 移除。
**Example:** 权重 `[2,3,5]`、`r=4` 时 winner 为第二项。每份成功 offer固定执行n次selection calls。

### F2b — Display permutation calls

The `offer_rng_call_count` formula is defined as:

`calls_per_offer(n) = n weighted selections + (n-1) bounded display swaps = 2n-1`

其中`n=min(3,legal_candidate_count)`且`n∈[1,3]`；固定执行 `i=n-1..1; j=roll_int_range(0,i); swap(i,j)`。同一n不因保底或卡片类型改变调用数。一次session最多初始页+3次刷新，因此总calls为`Σ(2n_page-1)`，范围1..20；非大衍L5仍最多3页/15 calls。

### F3 — Guarantee predicates

The `draft_guarantee_bits` formula is defined as:

`NEW_ACTIVE_REQUIRED=(draft_ordinal<=2 && active_count<4 && new_active_count>0)`

`PITY_REQUIRED=(miss_streak==2 && reinforcement_count>0)`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `draft_ordinal` | int | `[1,+∞)` | 已提交普通升级 session 数+1 |
| `active_count` | int | `[1,4]` | 当前主动槽占用 |
| `miss_streak` | int | `[0,2]` | 连续最终 offer 无强化次数 |
| candidate counts | int | `[0,12]` | 对应合法子池行数 |

**Output Range:** 两个 bool；两者同时为真时合法池必有至少2个不同candidate，各预留一个selection slot；若n=3，第三张从剩余总池抽。
**Example:** ordinal=2、active=2、new_active=4、streak=2、reinforcement=1 时两 bit 均 true。

### F4 — Reinforcement miss streak

The `next_miss_streak` formula is defined as:

`next = has_reinforcement(final_offer) ? 0 : min(2,current+1)`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `current` | int | `[0,2]` | session开始值 |
| `has_reinforcement` | bool | `{false,true}` | 最终被选择的当前offer是否含 owned level<5 upgrade |

**Output Range:** 0..2。
**Example:** current=1且最终offer无强化得2；下一session触发PITY_REQUIRED。

### F5 — Candidate capacity

The `candidate_capacity` formula is defined as:

`C = active_family_count + auxiliary_family_count = 6+6=12`

**Variables:** catalog family counts均为Config精确值。
**Output Range:** 12 rows；每family当前最多一张new或upgrade。
**Example:** 4主动已持有、2未持有，仍只产生6条active候选中的合法子集。

### F6 — Pending blocking-choice capacity

The `skill_draft_pending_capacity` formula is defined as:

`S_PENDING=checked_add(max_pending_level_up_requests,max_pending_treasure_requests)`

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| level-up pending max | int64 | exact `10` | Leveling可见queue窗口；余量留在39-row debt |
| treasure pending max | int64 | exact `4` | Drop宝匣active/request上界 |

**Output Range:** exact `14`；RiskChoice actual贡献已冻结为2，GameRoot checked sum精确为16。
**Example:** 10个升级+4个宝匣填满FIFO；第11个升级保留在Leveling debt，完成一页后再搬入空槽。

## Edge Cases

- **If candidate pool为2/1**：发布诚实二/一选一，分别固定消费3/1次SKILL_DRAFT RNG；不复制卡、不展示非法卡。
- **If candidate pool为0**：只有Leveling已到40且未生成request才是正常no-op；已有普通request则fault。
- **If early guarantee与pity同时成立**：分别无放回抽一张NEW_ACTIVE与一张REINFORCEMENT；n=3时再从剩余总池抽第三张。
- **If guarantee predicate不适用**：记录NOT_APPLICABLE并使用普通池；不得把空强制子池当成功。
- **If refresh后出现与旧页完全相同的n张**：视为合法随机结果，不暗中追加roll。
- **If refresh在第1/2/3次pick fault**：旧offer与次数不变，整transaction fault，不重摇。
- **If stale/duplicate选择到达**：matching duplicate为OK_NOOP；旧offer、跨局或冲突payload零mutation并fault。
- **If槽位在请求入队后被前一个choice改变**：后续request只在成为前台后基于最新published loadout重新生成，不预生成。
- **If同tick多次升级**：一request一choice，按source fact sequence串行；不把quantity压成一次选择。
- **Ifterminal winner高于pause**：不打开选择页；请求按Leveling/Drop终局规则处理，SkillDraft不自行结算奖励。
- **If宝匣有1..4个进化**：只列合法进化并让玩家选1个；不进入随机升级fallback。
- **If宝匣无进化但有未满技能**：TREASURE_BOX精确1次选择并只升1级，不新增技能。
- **If宝匣无进化且无未满技能**：不得调用空范围RNG或静默丢弃；进入TREASURE_EXHAUSTION_BLOCKED。
- **If进化choice提交**：保持active slot/family/level5，只改变form/evolution ID；现有attack objects按Weapon规则收敛。
- **IfPaused浏览页面**：gameplay tick、XP、Weapon cadence、Enemy、Projectile、Damage和Buff duration均不推进。
- **Ifteardown发生**：先invalid session/offer/loadout views再推进generation，旧UI command不可污染新局。

## Dependencies

| Dependency | Direction | Contract / status |
|---|---|---|
| GameRoot | Hard upstream | phase7 pause、blocking choice、paused authority commit；需接纳actual row/capability |
| RNG System | Hard upstream | SKILL_DRAFT按n固定1/3/5 calls/offer、TREASURE_BOX 1 call fallback；max weights length=12 |
| Config/Data | Hard upstream | 6+6 catalog、weights、4 evolution map、capacity/content hash；具体weights OPEN |
| Leveling/XP | Hard producer | level-up request、39 debt与10-row可见窗口；Designed / Full Review Pending |
| DropSystem | Hard producer | elite treasure-box request与4-row上界；Designed / Full Review Pending |
| WeaponSystem | Hard downstream | next-tick loadout；Designed / Full Review Pending |
| DamageSystem | Hard downstream | auxiliary modifier revision与recovery；ABI部分BLOCKED |
| BattleUI / Prep UI | Hard experience | BattleUI承接局内3/2/1；Prep承接聚气丹说明，PREPARATION选择复用同一原子卡片/typed command语义；两者均Designed，runtime待证 |

## Tuning Knobs

| Knob | Value/domain | Status |
|---|---|---|
| active/auxiliary slots | 4 / 4 | locked |
| active/auxiliary families | 6 / 6 | locked |
| level count / evolution count | 5 / 4 | locked |
| offer size | max 3 distinct；合法池不足时2/1 | locked |
| free refreshes | base 2；Dayan L5=3 per run | concept locked；Progression projection |
| early guarantee sessions | 1 and 2 | locked |
| pity threshold | 2 misses → third guaranteed | locked |
| base weights | positive int32 | OPEN-WEIGHTS |
| owned-upgrade bonus | makes upgrade weight > new | OPEN-WEIGHTS |
| evolution-pair bonus | `0<bonus<base` | OPEN-WEIGHTS |
| pending request capacity | 14 = 10 level + 4 treasure | locked；与RiskChoice 2组成global 16 |
| exhausted pool/treasure compensation | not defined | BLOCKED-ECONOMY |

## Visual/Audio Requirements

- 新技能、升级、匹配进化辅助、可进化、已进化与满级必须有形状/图标/文字多重区分，不只靠颜色。
- 保底可通过轻量“机缘契合”标识解释，但不暴露内部权重数字或制造“系统替你选”的错觉。
- refresh、select、evolution仅在matching committed revision后播放；stale/duplicate command不重复音效。
- 进化使用独立短演出和音效，但不能在resume前推进战斗；缺资源时可简化表现，不影响loadout commit。

## UI Requirements

- 普通页显示最多三张互异合法卡；2/1项时使用诚实reduced-choice布局，并显示类型、当前→目标等级、关键成长轴、槽位状态和剩余刷新次数。
- 第一次获得匹配辅助时标记“可进化条件已满足/仍需主动五层”；不得把“具备条件”显示成“已进化”。
- 宝匣有多项进化时展示全部1..4项并要求选1；无进化的随机+1 fallback显示结果确认，不伪装成三选一。
- 页面打开后只读取immutable offer；按钮command携带token/revision，提交中禁重复输入，失败保持明确安全态。
- `PRE_ACTIVE_CHOICE`是ADR-0001明确的action-bearing TopState：presenter必须从immutable offer按ASN04发布固定capacity12、exact bytes3084、最多9行的`AccessibleScreenSnapshotV2`，卡片name/value/state用typed localization args表达当前→目标等级、槽位与剩余刷新，248-byte row携带当前`layout_generation`、logical bounds、visible/clipped与radio position，unused tail全零。视觉reflow后旧layout callback为0 command。
- 聚气预开局页不暴露玩家cancel。base offer durable readback前页面不可交互；可见后返回节点可读但disabled，播报“选择已保存，请完成本次选择”。不得关闭、自动选择或release重抽；只有base offer任何durable/visible事实之前的系统级clear failure可走LFD25 release。普通局内blocking choice继续按既有pause策略。

## Acceptance Criteria

- **AC-SD01 `[U][I][BLOCKING]` owner/phase**：**GIVEN** SkillDraft及所有相邻系统spy，**WHEN** 覆盖Active/Pause/terminal/teardown，**THEN** 只有candidate/offer/refresh/pity/choice/loadout被写；Weapon cadence、HP/XP/drop/RNG内部state与SceneTree pause直接写入为0，phase row逐字段等于R1。
- **AC-SD02 `[U][I][BLOCKING]` owner contributions**：**GIVEN** 四类贡献、Leveling窗口10与Drop宝匣4，**WHEN** Config admission，**THEN**前三类显式0、BLOCKING_CHOICE精确14且required±1仅required成功；RiskChoice使全局sum>16时battle_ready=false。
- **AC-SD03 `[U][BLOCKING]` state machine**：**GIVEN** 所有状态与合法/非法边，**WHEN** enqueue/generate/refresh/select/commit/fault/teardown，**THEN** 仅表列迁移；前台choice最多1，FAULTED只到TORN_DOWN，旧局token全拒绝。
- **AC-SD04 `[U][BLOCKING]` catalog**：**GIVEN** 6+6、level1..5、四映射及缺/重/跨family/雷藤伪进化，**WHEN** Loading校验，**THEN** 仅完整whitelist成功且不补默认。
- **AC-SD05 `[U][BLOCKING]` initial snapshot**：**GIVEN** fresh battle与Dayan level4/5 matching projection，**WHEN** bind，**THEN** active slot0=青元剑气L1、其他slot empty、aux count0、refresh分别2/3、draft count0、streak0，header/bank/generation matching；projection mismatch时不发布。
- **AC-SD06 `[U][BLOCKING]` candidate matrix**：**GIVEN** 两类slot 0..4、family未有/已有L1..5/base/evolved，**WHEN**枚举，**THEN** 只产生R2四类合法next-step；满槽无new、L5/evolved无upgrade、evolution不入普通池。
- **AC-SD07 `[U][BLOCKING]` canonical/unique**：**GIVEN**相同catalog/loadout的不同物理排列，**WHEN**构造pool，**THEN** count<=12、每family最多1行、identity唯一且canonical rows逐值相同。
- **AC-SD08 `[U][BLOCKING][OPEN-WEIGHTS]` F1 weights**：**GIVEN**new/owned/matching aux与边界权重，**WHEN**解析，**THEN**全部正定点、owned upgrade权重大于new、pair bonus为轻微正值、sum<=W_MAX_SAFE；具体production golden未冻结前OPEN。
- **AC-SD09 `[U][BLOCKING]` reduced distinct offer**：**GIVEN**合法pool count3/2/1，**WHEN**生成offer，**THEN**发布恰3/2/1个不同合法candidate，行按最终display slot `0..n-1`，相同seed/history一致；count0+pending request为fault。
- **AC-SD10 `[U][I][BLOCKING]` first-two guarantee**：**GIVEN**ordinal1/2/3及new-active适用/不适用，**WHEN**生成初始和refresh页，**THEN**前两session每个可见页适用时至少1张NEW_ACTIVE；第三次不因该规则强制，waiver显式可审计。
- **AC-SD11 `[U][I][BLOCKING]` pity**：**GIVEN**连续两次最终offer无REINFORCEMENT及一次含强化对照，**WHEN**生成下一session，**THEN**前者适用时至少1张强化、后者不触发；refresh旧页、宝匣、未提交页不推进streak。
- **AC-SD12 `[U][BLOCKING]` both guarantees**：**GIVEN**F3两bit同时true且pool>=2，**WHEN**生成任一页，**THEN**offer至少含1 NEW_ACTIVE、1 REINFORCEMENT且全部不同，display permutation不破坏成员约束。
- **AC-SD13 `[U][I][BLOCKING]` RNG call table**：**GIVEN**n=1/2/3的普通/任一保底/refresh页及初始refresh2/3，**WHEN**成功生成，**THEN**每页恰有n weighted+n−1 display=1/3/5 SKILL_DRAFT calls；单session最大分别15/20，枚举/选择/reopen为0 calls，无shuffle/rejection。
- **AC-SD14 `[U][I][BLOCKING]` RNG与durability原子性**：**GIVEN**n=1/2/3及第1..`2n-1`次call fault，或pre-active scratch已完成而Save返回FAILED/UNCERTAIN/`RECONCILE_FOUND+next hash`/`RECONCILE_FOUND_OLD+old hash`/`RECONCILE_NOT_FOUND_UNPROVEN`及code/hash错配，**WHEN**初始或refresh生成，**THEN**roll fault不发布offer/selector/loadout且由GameRoot捕获；FAILED逐位保持旧权威cursor/offer/revision/refresh charge并discard scratch，UNCERTAIN与UNPROVEN禁止新roll且保持window冻结，FOUND_NEXT只commit durable next state一次，FOUND_OLD只discard scratch并保持old state；错配fail closed。全reservation PROVEN_ABSENT调用数0。普通Active fault不重摇；任一路径都不存在durable history与权威cursor分叉。
- **AC-SD15 `[U][I][BLOCKING]` refresh budget**：**GIVEN**Dayan level4/5 fresh run，**WHEN**跨session提交刷新，**THEN**分别按2→1→0与3→2→1→0 exact-once消费，下一次0 RNG/0 mutation并返回NO_REFRESH_REMAINING；同command replay OK_NOOP。
- **AC-SD16 `[U][I][BLOCKING]` refresh replacement**：**GIVEN**旧offer、matching/stale/conflict token，**WHEN**refresh，**THEN**完整新页后才原子替换且旧页不可选；新旧完全相同允许，禁止额外roll。
- **AC-SD17 `[U][I][BLOCKING]` choice exact-once**：**GIVEN**matching choice及100次duplicate、stale offer、非页内candidate、跨局/conflict，**WHEN**confirm，**THEN**matching只提交一次，duplicate OK_NOOP，其余在selector/counter/ACK前拒绝。
- **AC-SD18 `[U][I][BLOCKING]` loadout A/B**：**GIVEN**四种普通action与evolve，**WHEN**commit，**THEN**完整copy旧bank后只改/增目标row，selector与revision各+1一次，4+4 rows共享header且无alias/中间态。
- **AC-SD19 `[I][BLOCKING]` next-tick consumers**：**GIVEN**Paused中提交active/passive/evolution，**WHEN**resume首个完整Active tick，**THEN**Weapon与Damage读取同一loadout/authority revision；暂停帧与resume准备阶段不生效，不出现新skill配旧modifier。
- **AC-SD20 `[U][I][BLOCKING]` multi-request serialization**：**GIVEN**同tick多级与宝匣requests，**WHEN**排队处理，**THEN**一request一choice、按source fact sequence串行，后页基于前页已发布loadout重建，不预生成旧候选。
- **AC-SD21 `[U][I][BLOCKING]` pool<3**：**GIVEN**合法候选0/1/2，**WHEN**升级请求到达，**THEN**1/2项发布诚实reduced-choice且calls=1/3；0项+未到40或已有request为fault，level40且无request为no-op；全路径无复制/假卡/无限重抽。
- **AC-SD22 `[U][BLOCKING]` evolution eligibility**：**GIVEN**四组active L4/L5、对应aux有无/L1..5、已进化、错aux与雷藤，**WHEN**枚举，**THEN**仅四组`L5 base+拥有匹配aux`合法，aux等级不限，雷藤永无MVP evolution。
- **AC-SD23 `[U][I][BLOCKING][PROVISIONAL-UX]` treasure evolution**：**GIVEN**eligible count1..4，**WHEN**宝匣打开，**THEN**全部按active slot显示并选择恰1，TREASURE_BOX calls=0；同slot/family/L5保持，仅form改变。
- **AC-SD24 `[U][I][BLOCKING]` treasure fallback**：**GIVEN**无evolution且equipped未满项count1..8，**WHEN**宝匣处理，**THEN**canonical pool上TREASURE_BOX精确1次uniform pick，目标+1且<=5；不新增skill、不消费refresh/普通streak，本箱升级后不立即进化。
- **AC-SD25 `[U][I][BLOCKING][OPEN-TREASURE-EXHAUSTION]` empty treasure**：**GIVEN**无evolution且无未满项，**WHEN**宝匣到达，**THEN**0非法RNG、0假升级并进入明确blocked compensation状态；经济fallback未设计前OPEN。
- **AC-SD26 `[I][BLOCKING]` pause/terminal**：**GIVEN**choice pause及并发VICTORY/FATAL/DEFEAT/ABANDONED，**WHEN**barrier/pump运行，**THEN**terminal优先时UI不打开；Paused期间gameplay tick、Weapon、Projectile、Enemy、Damage、XP均0推进，仅allowlisted choice transaction变化。
- **AC-SD27 `[U][I][BLOCKING]` deterministic replay/teardown**：**GIVEN**同seed/content key/canonical initial loadout/history但不同process-local `config_snapshot_id/bank/generation`、不同物理顺序与其他RNG流调用，以及相同revision但content hash单轴不同的负例，**WHEN**生成/刷新/选择并teardown，**THEN**252-byte offer与296-byte loadout semantic bytes/hash在前组逐位相同、runtime carrier完成当前local rebind且流隔离；content hash不同组在publish前fail closed；旧request/session/offer/command不污染新局，runtime snapshot hash不得与durable semantic hash混用。
- **AC-SD28 `[P][I][E][OPEN-EVIDENCE]` zero-allocation/experience**：**GIVEN**Godot4.7.1目标Android、最大banks/scratch/queue及fixed-seed corpus，**WHEN**10000次offer/refresh/commit soak与预登记试玩，**THEN**allocator/growth/COW/unexpected-native-call=0、无重复/非法卡/卡死/双commit，并报告选择率、refresh/pity/进化率；首次升级≤30秒与首进化6–8分钟缺Leveling/Drop/完整build证据前保持OPEN。
- **AC-SD29 `[U][I][BLOCKING]` 聚气预开局普通首选**：**GIVEN**聚气/无聚气、candidate count1..12、refresh 2/3、base/每次refresh/commit前后kill、callback loss与进程恢复，**WHEN**进入首个Active前选择，**THEN**仅聚气路径出现一次`PRE_ACTIVE_CHOICE`，request为普通LEVEL_UP ordinal1并应用同一early guarantee/streak；每版offer与全部replay字段先写360-byte recovery，base页refresh不变、玩家每次refresh exact-once扣1；首版durable后取消返回WRONG_STATE并恢复同一页；提交后selected candidate、command、loadout revision/hash、credit14、remaining XP16538、next sequence2、checkpoint6逐值成立，跨进程以durable config content identity重建同一offer rows/identity/loadout且第二offer/choice=0，未提交时Active/movement/survival tick均为0。
- **AC-SD30 `[I][A][BLOCKING]` pre-active accessibility**：**GIVEN**`PRE_ACTIVE_CHOICE`在base offer durable readback前/后、1/2/3 cards、refresh0..3、100/115/130%字体、长locale、cutout/reflow及old/new layout callbacks，**WHEN**发布ADR-0001 V2 tree并以TalkBack/VoiceOver action oracle遍历，**THEN**readback前interactive snapshot/action count=0；可见后card radio/name/value/state/bounds/typed args逐行matching，Back节点可读但disabled并播报必须完成，stale layout/disabled/card外action为0 typed command。runtime/device trace未附前保持OPEN-EVIDENCE。

## Open Questions

| ID | Status | Required decision | Owner |
|---|---|---|---|
| OQ-SD01 | `RESOLVED-MERGED-ABI` | F6冻结为10 level窗口+4 treasure=14；RiskChoice全局贡献另见其owning GDD | Leveling + Drop + GameRoot |
| OQ-SD02 | `RESOLVED-REDUCED-CHOICE` | 合法池2/1采用诚实reduced-choice；0项仅允许level40无新request | Game/Economy + Leveling |
| OQ-SD03 | `OPEN-WEIGHTS` | 冻结base/owned/pair bonus定点整数与试玩分布 | Game Design + Config |
| OQ-SD04 | `BLOCKED-RNG-EVIDENCE` | 验证mandatory单项weighted pick仍精确消费word及5-call路径 | RNG + QA |
| OQ-SD05 | `PROVISIONAL-TREASURE-UX` | 批准1..4进化全部展示、单项也确认 | UX + Game Design |
| OQ-SD06 | `PROVISIONAL-TREASURE-DISTRIBUTION` | 宝匣fallback当前采用equipped未满项均匀随机 | Game Design |
| OQ-SD07 | `BLOCKED-TREASURE-EXHAUSTION` | 无进化且全满时的宝匣补偿 | Economy + Drop |
| OQ-SD08 | `RESOLVED-MERGED-ABI` | request/fact identity、terminal取消、多request顺序与debt transfer已冻结 | Leveling + Drop |
| OQ-SD09 | `BLOCKED-MODIFIER-REVISION` | loadout到Weapon/Damage modifier snapshot的同revision builder | Config + Damage + Weapon |
| OQ-SD10 | `BLOCKED-PAUSE-COMMIT` | GameRoot冻结paused authority plan、ACK与failure convergence | GameRoot |
| OQ-SD11 | `BLOCKED-BATTLEUI/INPUT` | 卡片command、focus/touch shield、返回键和错误态 | BattleUI + Input |
| OQ-SD12 | `RE-REVIEW-PENDING` | clean-context full review；当前无runtime/UX/设备证据 | Review owner |
