# Zhangtian Bottle（掌天瓶）

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：新Steam任务/存档适配见campaign-flow.md与save-steam-pc.md：M01-03首次grant唯一开放备战，禁用旧首次胜败starter；PREPARED内offer持久曝光后不可取消/重抽，恢复同reservation/seed/offer。具体v2 preparation schema、grant资源映射、补偿after-image与预算待本owner冻结，legacy byte ABI不自动套用。

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / economy-designer / qa-lead / UX reviewer）
> **Created / Last Updated**: 2026-09-08 — 第七次fresh-context full review仍为MAJOR REVISION NEEDED；用户“继续”后完成第七轮作者静态整改，待第八次独立复审
> **Implements Pillar**: 根据已有储备做一次明确的战前取舍；局外选择影响下一局但不替代构筑与走位
> **Scope**: MVP三种灵药种子、即时催熟、每局至多一种丹药、开局reservation、下一局只读投影与结算种子入账；不含真实时间等待、种植田、炼丹配方、品质、失败率或商业化

## 1. Overview

Zhangtian Bottle 是灵药种子库存、催熟选择、丹药效果语义与开局资源 reservation after-image 的唯一业务 owner。玩家在每局前可消耗一枚凝气草、铁灵花或雷元果种子，分别制成聚气丹、锻体丹或明心丹，也可不服丹直接出战；掌天瓶只提供下一局准备，不直接造成伤害。

种子扣减必须先 durable，随后 GameRoot 才能进入 `BATTLE_LOADING`。丹药效果只从 matching reservation 构建本局 immutable projection，Active、Paused、恢复或晚到 callback 均不得热改。Save 只保存 canonical domain/after-image并仲裁 exact-once，不解释灵药规则；Prep UI 只提交选择 identity，不拥有库存。

## 2. Player Fantasy

玩家在出发前像韩立一样审视已经拥有的储备，为这一局做一次明确取舍：想更快成型就服聚气丹，担心容错就选锻体丹，追求爆发则选明心丹。种子的取得顺序可以随机，但是否消耗、消耗哪一种始终由玩家决定；选择明确、立刻生效、不强迫等待，也允许“这局先不用”。MVP把它定位为胜利偏置、可积累的随机储备：首次正常结算提供三类starter reserve；排除一次性starter后，Victory的**随机gross grant/Active-minute**严格高于任一有随机奖励的Defeat路线。该承诺不等同于逐局净库存优势：是否服丹、胜率与局长会改变net flow，净库存斜率仅由预注册经济模拟与玩家试玩判定，不再宣称“任意Victory路线净增必高于Defeat”。

催熟不是冗长制作小游戏。选卡只改变预览，确认后一次短促封签反馈表示资源已安全记录；未确认、失败或结果不明时绝不假装种子已消耗。首次正常结算获得三类种子各一枚，使新手即使首局失败也能体验三种准备方向；赠礼不会自动替玩家选择或连续服用。

## 3. Detailed Design

### 3.1 Owner、stable IDs 与非目标

`HerbSeedIdV1={NONE=0,NINGQI_GRASS=1,TIELING_FLOWER=2,LEIYUAN_FRUIT=3}`；`PillIdV1={NONE=0,QI_GATHERING_PILL=1,IRON_BODY_PILL=2,CLEAR_MIND_PILL=3}`。映射固定一一对应，不允许配置交换ID：

| Seed | Pill | Next-run effect |
|---|---|---|
| `NINGQI_GRASS` 凝气草 | `QI_GATHERING_PILL` 聚气丹 | 起始局内等级+1，并产生1个初始普通功法选择 |
| `TIELING_FLOWER` 铁灵花 | `IRON_BODY_PILL` 锻体丹 | 最大生命加法比例+0.15 |
| `LEIYUAN_FRUIT` 雷元果 | `CLEAR_MIND_PILL` 明心丹 | 暴击率加8个百分点，即+0.08 |

- Zhangtian为app-scope feature service，不是GameRoot七phase participant；四类gameplay contribution均为0。
- 不拥有Outcome胜负、Save介质、run seed建立、战斗HP/暴击/升级执行、Prep布局或Settlement展示。
- MVP无真实时间等待、第二催熟槽、连续炼制、品质、配方、失败率、广告加速、种子兑换或自动选择。
- 掌天瓶与Prep是同一个玩家流程，不新增独立库存主页面。

### 3.2 Persistent domain

```text
ZhangtianProfileDomainV1={
  schema_version:i32=1,
  domain_revision:i64,
  zhangtian_content_revision:i64,
  available_seed_counts:i64[3],
  earned_seed_counts:i64[3],
  reserved_seed_counts:i64[3],
  consumed_seed_counts:i64[3],
  unlocked:i32,
  starter_seed_grant_claimed:i32,
  next_preparation_id:i64
}
```

canonical payload固定little-endian、no-padding、132 bytes；数组物理顺序固定凝气草/铁灵花/雷元果。空档为revision0、四组count全0、unlocked=0、claim=0、next ID=1。`next_preparation_id`是Zhangtian持久allocator，GameRoot只编排其分配；`preparation_id=old.next_preparation_id`，同一reserve transaction令`next_preparation_id'=checked_add(old.next_preparation_id,1)`，0永不发布、崩溃允许跳号但不复用。

每类不变量为`available_i+reserved_i+consumed_i=earned_i`，四项均为checked non-negative int64；`available_i+reserved_i<=SEED_HELD_CAP=999`，`earned_i/consumed_i`是终身累计量，不受held cap限制但不得超过`INT64_MAX`。`sum(reserved_seed_counts)∈{0,1}`，与Save最多1条 unresolved reservation一致。V1 flag合法组合只有`{unlocked=0,starter_seed_grant_claimed=0}`与`{1,1}`，即两者必须逐位相等；locked组合还要求三类available/reserved/consumed/earned全0。首次成功保存的Victory或Defeat在同一Settlement transaction令两flag从0→1并发放starter reserve；不存在“已解锁但未claim”或“已claim仍锁定”的可接受V1字节。两flag均只能0→1，next ID只增不减。unknown/缺/重/乱序、非canonical bytes、非法flag组合、负数、held cap/守恒/checked-add失败或未来schema均fail closed，不clamp或补默认。合法奖励按F2对held room显式saturation，绝不因历史累计达到999而停止结算。

#### Static config 与动态投影分界

```text
HerbRecipeConfigV1={stable_order:i32,seed_id:i32,pill_id:i32,
  seed_cost:i32,effect_kind:i32,effect_i64:i64,effect_f64:f64,
  display_unit_id:i32,localization_key_id:i32}

HerbConfigV1={schema_version:i32=1,content_revision:i64,
  seed_kind_count:i32=3,seed_held_cap:i64=999,
  defeat_seed_eligible_ticks:i64=43200,victory_min_ticks:i64=43200,
  max_active_ticks:i64=108000,
  victory_seed_quantity:i32=3,
  starter_seed_grant_per_kind:i32=1,seed_weights:i32[3],
  recipe_rows:HerbRecipeConfigV1[3],config_hash:Hash256}

ZhangtianProjectionRulesV1={schema_version:i32=1,content_revision:i64,
  qi_curve_credit:i64=14,qi_initial_choice_count:i32=1,
  iron_max_hp_bonus_ratio:f64=0.15,mind_crit_bonus_points:f64=0.08,
  rules_hash:Hash256}
```

三个recipe row按`NINGQI/TIELING/LEIYUAN`稳定顺序，seed/pill一一映射、`seed_cost=1`；对应effect只允许`CURVE_CREDIT/I64=14`、`MAX_HP_RATIO/F64=0.15`、`CRIT_POINTS/F64=0.08`，未使用的数值槽必须为规范零。静态manifest只含这些规则、stable localization key ID与hash；玩家库存、profile/domain/reservation/preparation/battle/run identity及选择结果禁止进入静态content hash。run-specific `ZhangtianBattleProjectionV1`只能从matching静态rules+durable reservation生成。

### 3.3 Normal settlement seed grant

每个admitted run在BATTLE_LOADING完成全部Config/RNG preflight后，以Config snapshot持有的owner-private、只读`PackedInt32Array([1,1,1])`调用`roll_weighted_pick(ZHANGTIAN_HERB, weights)`精确一次。`ZHANGTIAN_HERB.max_weights_length=3`，RNG三槽scratch在调用前预分配；消费方在使用返回index前检查fault，只有无fault且`rng_call_end=rng_call_begin+1`才按canonical row `index0/1/2→NINGQI/TIELING/LEIYUAN`冻结独立candidate。candidate wire schema固定为：

```text
ZhangtianSeedCandidateV1={
  schema_version:i32=1,reservation_id:i64,battle_instance_id:i64,
  config_content_revision:i64,config_content_hash:Hash256,
  zhangtian_content_revision:i64,
  stream_id:i32=ZHANGTIAN_HERB,candidate_seed_id:i32,
  logical_call_ordinal:i64=0,rng_call_begin:i64,rng_call_end:i64,
  candidate_hash:Hash256
}
```

canonical little-endian/no-padding固定132 bytes；`rng_call_end=rng_call_begin+1`且logical ordinal只能为0。`config_content_revision+config_content_hash`是跨进程durable key；新进程可以生成不同的process-local `config_snapshot_id`，但只能在完整content key逐位相等后rebind。fault时candidate publish=0并走Loading abort/release，不得把返回零值当凝气草。

候选不得回写已冻结的`RunStartRequestV2`。同一live-process handoff retry额外public call=0；若进程在candidate durable前终止，重启只能从durable run seed与matching config content key初始化独占流、在其他流消费前执行一次deterministic reconstruction并立即持久化candidate checkpoint，逻辑call ordinal仍为0。`VICTORY`只接受`survival_ticks in [VICTORY_MIN_TICKS=43,200,MAX_ACTIVE_TICKS=108,000]`并按candidate发3枚；`DEFEAT`接受`0..108,000`，仅在`survival_ticks>=DEFEAT_SEED_ELIGIBLE_TICKS=43,200`时发1枚；`ABANDONED/TECHNICAL_ABORT`接受`0..108,000`且随机grant=0。域外Outcome整包拒绝，不以奖励0掩盖非法输入。

该规则为`PROVISIONAL-ECONOMY-V6`。速率验收只比较可重复gross随机奖励cohort，明确排除首次starter与本局是否服丹；不用除法作为判定oracle，而对任意合法`T_v,T_d`验证`3*T_d > 1*T_v`。最坏边界为`3*43,200=129,600 > 108,000=1*108,000`，等价于最慢Victory 0.10 gross seed/Active-minute严格高于最快eligible Defeat 1/12。net flow另按`gross grant - matching consumed seed`逐局计算，并必须覆盖Victory/Defeat×服丹/NONE×局长×胜率×held saturation；未冻结目标阈值前只报告分布与10/20局库存斜率，不得把gross证明改称净库存优势。Settlement/UI重建、Save重试或重启只读durable candidate与sealed资格。

首次正常 `VICTORY|DEFEAT` 且starter claim=0时，同一Settlement mutation向三种种子各加1并把claim置1；首次Victory因此通常请求6枚，首次Boss线Defeat请求4枚，较早Defeat请求3枚，均按held room逐类saturation。CORE_HERB是Boss胜利证明/独立reward item，不自动转换成三种种子，也不进入可服丹库存。

这项裁决取代旧传播稿“DEFEAT只保留已拾取种子”的表述：MVP没有三种种子的局内pooled pickup；普通种子唯一来源是Victory/到达Boss线Defeat的冻结随机奖与首次正常结算starter reserve。

### 3.4 Prep draft 与 command

Zhangtian只向Prep的canonical `PrepPresentationBundleV1`提供原子业务切片。wire schema固定为：

```text
HerbRecipeViewV1={stable_order:i32,seed_id:i32,pill_id:i32,
  available_count:i64,seed_cost:i32,effect_kind:i32,
  effect_i64:i64,effect_f64:f64,display_unit_id:i32,
  localization_key_id:i32}

ZhangtianPreparationSliceV1={schema_version:i32=1,
  profile_revision:i64,domain_revision:i64,content_revision:i64,
  unlocked:i32,available_counts:i64[3],
  recipe_rows:HerbRecipeViewV1[3],slice_hash:Hash256}
```

`HerbRecipeViewV1`固定52 bytes，slice固定244 bytes，均little-endian/no-padding。它不包含UI local selection；三row按stable seed ID顺序，包含稳定pill ID、数值、单位与localization key，不把本地化字符串写入hash。Prep初始每次均选`NONE`，不记忆上局丹药。

选卡/切换/返回只改UI draft，产生0 profile write、0 reservation、0成功音。库存0的卡仍显示效果但不可选；“不服丹”始终可选。

唯一开局业务命令类型是Prep GDD的`PrepConfirmCommandV1`，不携带`preparation_id`；来源封闭为`PREP`与仅在未解锁/available全0合法的`HOME_DIRECT_NONE|SETTLEMENT_DIRECT_NONE`，两个direct来源必须分别匹配fresh HOME或resolved SETTLEMENT generation。GameRoot验证fresh surface/press/bundle后取得run-seed candidate并构造Save签发的固定176-byte `ReservationCreateRequestV2`；它只携带source correlation、attempt=1、run seed、expected revisions/content key、selection与bundle hash，不携带尚未分配的operation/request/battle/preparation identity。Save用`{source_kind,source_command_id,source_press_id,request_hash}`做pre-durable duplicate/reconcile key，在同一reservation transaction分配operation/request/battle/reservation identity，再调用Zhangtian持久allocator构造唯一内部请求：

```text
PrepareRunRequestV1={
  schema_version:i32=1,source_command_id:i64,source_press_id:i64,
  preparation_id:i64,battle_instance_id:i64,run_seed:i64,
  expected_profile_revision:i64,expected_domain_revision:i64,
  expected_config_content_revision:i64,expected_config_content_hash:Hash256,
  zhangtian_content_revision:i64,
  selected_seed_id:i32,selected_pill_id:i32,
  prep_bundle_hash:Hash256,request_hash:Hash256
}
```

`PrepareRunRequestV1`只允许由Save transaction内部在全部identity分配成功后构造；它不是外部create ABI。callback丢失时caller只能重发逐位相同的`ReservationCreateRequestV2`，不得猜测request ID或重建第二个`PrepareRunRequestV1`。

correlation固定为`page_generation→press_id→command_id→preparation_id→battle_instance_id=reservation_id`。UI提供的pill/effect仅用于correlation，Zhangtian从matching Config重算映射。确认前必须满足GameRoot在PREP、Save READY、无unresolved outcome/archive/profile mutation/reservation、writer可接纳、revision/hash matching；任何guard失败为0 preparation/battle identity reserve、0 write。

### 3.5 Durable reservation

每次确认都由Save持久`next_identity`在同一reservation transaction内分配非零`battle_instance_id`，并令`reservation_id=battle_instance_id`；run seed只允许PREP release路径的OS entropy producer生成，dev build可用显式forced seed，玩家seed/每日seed不属于MVP。Zhangtian同时分配`preparation_id`。选择种子时构造`available−1,reserved+1` after-image；NONE count逐位不变，但domain/profile revision、两个allocator与typed `NO_PILL` reservation仍推进。任一validate/checked-add失败时所有allocator、seed与domain bytes保持原值；一旦首份可能durable，只能以同identity reconcile。

Save将`DurableReservationV2`、64-byte create correlation、preparation identity、base/next domain hash和after-image放入同一双槽transaction。只有matching `RESERVED` durable success/readback后，GameRoot才冻结`RunStartRequestV2`并进入Loading；PONR前可证明未写入才FAILED，PONR后未知只能UNCERTAIN。

```text
ZhangtianReservationPayloadV2={
  schema_version:i32=1,reservation_id:i64,preparation_id:i64,
  battle_instance_id:i64,run_seed:i64,
  expected_profile_revision:i64,reserved_profile_revision:i64,
  config_content_revision:i64,zhangtian_content_revision:i64,
  selected_seed_id:i32,selected_pill_id:i32,
  base_domain_revision:i64,reserved_domain_revision:i64,
  base_domain_hash:Hash256,reserved_domain_hash:Hash256,
  run_start_recovery:RunStartRecoveryV1,
  battle_projection:ZhangtianBattleProjectionV1,
  create_correlation:ReservationCreateCorrelationV1,
  prepare_request_hash:Hash256
}
```

`ZhangtianReservationPayloadV2` canonical little-endian/no-padding固定724 bytes：156-byte fixed fields before recovery + 360-byte recovery + 112-byte projection + 64-byte create correlation + 32-byte internal prepare request hash。create correlation逐位绑定外部`ReservationCreateRequestV2`；internal hash必须逐位等于matching `PrepareRunRequestV1.request_hash`，二者均为foreign repeated hash而非payload self-hash。

canonical `RunStartRecoveryV1`固定360 bytes、little-endian、no-padding：`{schema_version:i32,reservation_id:i64,battle_instance_id:i64,run_seed:i64,preparation_id:i64,selected_seed_id:i32,selected_pill_id:i32,source_profile_revision:i64,source_domain_revision:i64,config_content_revision:i64,config_content_hash:Hash256,zhangtian_content_revision:i64,projection_hash:Hash256,prep_commit_operation_id:i64,handoff_checkpoint:i32,candidate_present:i32,candidate_seed_id:i32,rng_call_begin:i64,rng_call_end:i64,pre_active_choice_state:i32,pre_active_choice_request_id:i64,pre_active_offer_hash:Hash256,pre_active_choice_command_id:i64,pre_active_loadout_hash:Hash256,pre_active_skill_draft_rng_cursor:i64,next_level_request_sequence:i64,pre_active_offer_revision:i64,pre_active_refreshes_used:i32,pre_active_free_refreshes_remaining:i32,pre_active_selected_candidate_id:i64,pre_active_semantic_generation:i64,pre_active_draft_ordinal:i32,pre_active_required_rule_bits:i32,pre_active_reinforcement_miss_streak:i32,pre_active_committed_loadout_revision:i64,recovery_hash:Hash256}`。`pre_active_semantic_generation=1`是本局唯一pre-active持久语义代次，与runtime session/bank/generation无关。`PreActiveChoiceStateV1={NOT_STARTED=0,OFFER_DURABLE=1,CHOICE_DURABLE=2,SKIPPED=3}`；`prep_commit_operation_id`必须逐位等于wrapper `recovery_operation_id`，其余wrapper重复字段也必须相等，否则首字节写入前`CONFLICT`。

该carrier不依赖hash反推出选择，恢复协议固定为：`PRE_ACTIVE_CHOICE`是本局`SKILL_DRAFT`流的首个consumer；从durable run seed、matching `{config_content_revision,config_content_hash}`和canonical initial loadout（青元L1，其余空）初始化流。`pre_active_offer_hash`只能是SkillDraft签发的252-byte `PreActiveOfferSemanticV1.semantic_hash`，`pre_active_loadout_hash`只能是296-byte `PreActiveLoadoutSemanticV1.semantic_hash`；两者明确排除process-local snapshot/bank/generation/presentation identity。新进程先逐位验证semantic bytes/hash，再把当前process-local identity绑定到新的runtime carrier，旧local ID不进入持久比较。按`pre_active_offer_revision`与`pre_active_refreshes_used`重放base页及已durable refresh，验证每版最终cursor、semantic offer hash、remaining refresh、guarantee bits、draft ordinal与streak。每次base/refresh draw都使用SkillDraft的`PreActiveRngWindowLeaseV1`：从当前durable cursor复制到预分配scratch，精确试算`2n-1` rolls；只有包含next cursor与semantic offer的同reservation update双镜像readback成功后，才一次发布runtime cursor/offer/revision并扣refresh。FAILED时scratch丢弃且权威cursor/charge/revision逐位不变；UNCERTAIN冻结输入并用Save typed update proof核对selected formal reservation hash：`RECONCILE_FOUND+next hash`才采用durable next cursor，`RECONCILE_FOUND_OLD+old hash`丢弃scratch并保持old cursor，UNPROVEN继续冻结。既有reservation update不得用全reservation PROVEN_ABSENT猜OLD。不存在“RNG已消费但refresh未记录”的可重试状态。`OFFER_DURABLE`恢复同一candidate semantic rows；`CHOICE_DURABLE`必须在重建offer中找到`pre_active_selected_candidate_id`，以原`pre_active_choice_command_id`应用一次并逐位验证committed semantic loadout revision/hash；`SKIPPED`只允许非聚气。任一输入、replay结果或hash不等均fail closed，不重抽、不默认首卡、不发布Active。exact config artifact由Config的append-only `ConfigArtifactRetentionManifestV1`保证；缺失/hash不等仍保持同reservation为`UPDATE_REQUIRED`且新局关闭，不通过release制造fresh seed，并阻止该release build签发。Active marker后的无Outcome强杀仍按orphan CONSUME。

`PrepCommitCheckpointV1`唯一枚举为`RESERVATION_DURABLE=1,RUN_START_FROZEN=2,PREP_TOUCH_RETIRED=3,LOADING_COMMITTED=4,SEED_CANDIDATE_DURABLE=5,PRE_ACTIVE_CHOICE_DURABLE_OR_SKIPPED=6,ACTIVE_ENTRY_DURABLE=7`。不存在memory-only checkpoint或第二份journal真相；首次reservation transaction原子写入domain after-image、完整base recovery与`DurableReservationV2.prep_commit_journal` checkpoint1并readback。`SaveStorePayloadV1`不再另存顶层journal；所有后续journal/recovery更新都是同一reservation的单调slot transaction。durable后任一失败优先继续同一handoff；只有canonical failure disposition允许先durable RELEASE再返回fresh Prep。

首次合法Active开放前，Save必须durable写入matching `ActiveEntryFactV1`；该事实存在而无sealed Outcome的跨进程恢复按CONSUME，防止强杀返丹。正常`VICTORY/DEFEAT/ABANDONED`均通过唯一`ReservationUpdateRequestV2(RESOLVE)+ResolveReservationPayloadV3`处理matching reservation为CONSUME：若有种子则`reserved−1,consumed+1`，NONE则count不变；同一slot transaction同时写奖励或tombstone、完整next profile、264-byte resolution、清live marker并返回160-byte `TerminalRunResultV2`，不得另发Save commit。ABANDONED采用同一transaction中的“零奖励tombstone + mandatory consume after-image”，不是“profile逐位不变”。retryable load abort在Active前RELEASE；明确sealed `TECHNICAL_COMPENSATION`执行RELEASE。result的terminal disposition必须逐位区分CONSUMED/RELEASED；duplicate为OK_NOOP，同ID异payload为CONFLICT；UNCERTAIN冻结换药、返回、购买和新局，只允许同operation reconcile。

### 3.6 Battle projection 与生效

第八轮 hash/ABI 优先级覆盖：本节及其相邻历史段中的 `ZhangtianReservationPayloadV1`、六行 Meta UI 与旧 84-row fixture 均为迁移审计；当前实现输入必须使用 `ZhangtianReservationPayloadV2`、八行 Meta UI 与 132-row（11×12）crash fixture。

```text
ZhangtianBattleProjectionV1={
  schema_version:i32=1,reservation_id:i64,preparation_id:i64,
  source_profile_revision:i64,source_domain_revision:i64,
  zhangtian_content_revision:i64,selected_seed_id:i32,
  pill_id:i32,starting_level_curve_credit:i64,
  initial_level_choice_count:i32,max_hp_bonus_ratio:f64,
  crit_bonus_points:f64,projection_hash:Hash256
}
```

合法取值只有NONE=`0/0/0/0`、聚气丹=`14/1/0/0`、锻体丹=`0/0/0.15/0`、明心丹=`0/0/0/0.08`。Zhangtian在reserve时按matching静态`HerbConfigV1`构建run-specific projection并随reservation durable。Config的静态content hash只覆盖`HerbConfigV1`和projection schema/rules，不包含每玩家/每局动态值；Loading显式接收durable projection与receipt，逐字段验证identity/revisions/hash后复制进battle snapshot。Player、Damage、Leveling、SkillDraft只读matching projection。

所有Hash256沿Save codec ADR的`SHA256_V1`与canonical little-endian codec；禁止Godot `hash()`。实际权威是Save GDD签发的25-row `HashPreimageManifestV1`：逐行冻结精确NUL结尾tag、SELF/EXTERNAL mode、exact length或`164+P`公式、zero offset/length、nested策略与owner，且已包含176-byte `ReservationCreateRequestV2`、252-byte `PreActiveOfferSemanticV1`、296-byte `PreActiveLoadoutSemanticV1`、`ReservationUpdateRequestV2`五种payload、264-byte `DurableRunResolutionV2`、124-byte stamp、128-byte `DirectNoneStartSliceV2`与120-byte `ReservationReceiptV1`。`DomainRecordV1.payload_hash(ZHANGTIAN_DOMAIN)`使用EXTERNAL模式：preimage是`ZhangtianProfileDomainV1\0`加132-byte canonical payload，不含188-byte wrapper且zero range为空。`ZhangtianReservationPayloadV2.request_hash`是matching request hash的foreign repeated field，必须相等但不得另列self-hash tag；没有self-hash的`PrepConfirmCommandV1`也不得单列tag。无障碍snapshot另归ADR-0001的6-row `AccessibilityHashPreimageManifestV1`，不得混入本表。actual rows缺失/漂移是设计错误；generated artifact/golden尚未执行仍保持`BLOCKED-HASH-CODEC-EVIDENCE`。

聚气丹令Leveling初始snapshot为level2、xp0、`starting_level_curve_credit=14`，到L40的remaining accepted-XP budget为16538。它预置普通`LEVEL_UP` ordinal1；GameRoot在Loading内进入`PRE_ACTIVE_CHOICE`，root/input/gameplay gate保持关闭。基础offer、每次主动refresh与最终commit都先更新同一360-byte recovery并durable readback，记录§3.5列出的全部replay字段而非只存hash。commit后`next_level_request_sequence=2`，callback loss或进程重启按确定性协议重建同一页面/已提交loadout，不重抽或复用sequence；结果不明时冻结并reconcile。玩家没有pre-durable cancel公共动作；仅在任何offer durable/visible事实之前，base offer clear failure可由LFD25执行durable RELEASE。首个offer一旦durable并对玩家可见，Back/关闭应用/重启都只能恢复同一reservation、run seed、offer revision与剩余refresh，不得生成fresh随机页。该前置选择不推进survival tick、不伪造XP fact；从Prep CTA release到offer interactive、choice commit与首次移动分别计时，继续标`PROVISIONAL-PREP-LEVEL-V2`。

### 3.7 States and transitions

第八轮合同优先级覆盖：本节历史段中的 `ZhangtianReservationPayloadV1`、六行 Meta UI 与 84-row crash fixture 均不得作为当前实现输入；当前分别以 `ZhangtianReservationPayloadV2`、八行 `MetaUiInputActionManifestV1` 及 132-row（RCO V2 11行 × RCC V2 12行）fixture 为准。

| State | Meaning | Allowed next |
|---|---|---|
| `UNAVAILABLE` | profile/config尚未绑定 | DRAFT, BLOCKED |
| `DRAFT` | NONE或单种选择草稿 | DRAFT, RESERVING, BLOCKED |
| `RESERVING` | durable reservation进行中 | RESERVED, UNCERTAIN, DRAFT(confirmed fail) |
| `UNCERTAIN` | 可能已durable | RECONCILING |
| `RECONCILING` | 同operation扫描 | RESERVED, CONSUMED, RELEASED, UNCERTAIN, BLOCKED |
| `RESERVED` | durable reservation成立 | HANDOFF_PENDING, RELEASE_PENDING, CONSUME_PENDING |
| `HANDOFF_PENDING` | 同一PrepCommitJournal收敛至Loading | RESERVED, CANDIDATE_PENDING, RELEASE_PENDING, UNCERTAIN |
| `CANDIDATE_PENDING` | draw/reconstruct并持久candidate | PRE_ACTIVE_CHOICE_PENDING, ACTIVE_MARK_PENDING, RELEASE_PENDING, UNCERTAIN |
| `PRE_ACTIVE_CHOICE_PENDING` | 聚气offer/refresh/commit持久恢复链 | ACTIVE_MARK_PENDING；仅在任何offer durable/visible前的系统级LFD25 clear failure可RELEASE_PENDING；否则恢复同offer或UNCERTAIN |
| `ACTIVE_MARK_PENDING` | Active gate前写durable entry fact | ACTIVE_RESERVED, RELEASE_PENDING, UNCERTAIN |
| `ACTIVE_RESERVED` | Active已开放、等待终局resolution | CONSUME_PENDING, RELEASE_PENDING |
| `CONSUME_PENDING` | mandatory consume进行中 | CONSUMED, UNCERTAIN |
| `RELEASE_PENDING` | pre-Active load abort/technical compensation | RELEASED, UNCERTAIN |
| `CONSUMED` | matching成本已消费 | UNAVAILABLE |
| `RELEASED` | matching种子已返还或NONE resolved | UNAVAILABLE |
| `BLOCKED` | corrupt/update/conflict | UNAVAILABLE |

### 3.8 Interactions with other systems

| System | Input to Zhangtian | Output / boundary |
|---|---|---|
| SaveSystem | profile/revision、reservation result/reconcile | canonical domain与consume/release after-image；Save不解释药效 |
| Settlement/BATTLE_RULES | sealed outcome kind、seed reward fact、starter eligibility | seed income/claim mutation；RNG只在seal前一次 |
| Config/Data | HerbConfig、stable mapping、domain/projection codec | immutable next-run projection |
| RNG | `ZHANGTIAN_HERB` weighted pick | admitted run在Loading恰1 call；VICTORY或满43,200 ticks的DEFEAT才expose grant |
| GameRoot | PREP gate、battle identity/run seed、reservation disposition | durable RESERVED后才Loading |
| Player/Damage | matching projection | maxHP/crit输入一次；Active不热改 |
| Leveling/SkillDraft | 聚气丹initial level/choice | 首个gameplay tick前完成1个普通choice |
| Prep/Home/Settlement UI | typed view/同一PrepConfirm command | 有库存进Prep；无库存使用origin-specific direct NONE；UI无库存/Save writer |
| Audio Feedback | selected/reserved/released semantic edge | preview轻触与durable封签；无循环pending音 |

第八轮 hash 覆盖：`ZhangtianReservationPayloadV2` 的 64-byte create correlation 与 32-byte internal prepare hash 均作为 foreign repeated fields 校验；旧 `ZhangtianReservationPayloadV1.request_hash` 只保留历史迁移说明。

## 4. Formulas

### F1 — Settlement seed draw

The `zhangtian_seed_draw` formula is defined as:

`seed_index = roll_weighted_pick(ZHANGTIAN_HERB, preallocated_weights_111)`

`seed_reward_quantity = outcome==VICTORY ? 3 : (outcome==DEFEAT AND survival_ticks>=43,200 ? 1 : 0)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Outcome kind | `K` | enum | VICTORY/DEFEAT/ABANDONED/TECHNICAL_ABORT | sealed kind |
| Survival ticks | `T` | int64 | Victory 43200–108000；其余0–108000 | committed Active ticks；Victory必须在Boss入场线后 |
| Weights | `W` | PackedInt32Array[3] | exactly [1,1,1] | Config-owned stable seed ID order |
| Seed index | `I` | int32 | 0–2 | Loading中冻结的candidate |

**Output Range:** 每个admitted run恰1 logical public RNG call；Victory grant3且只接受T∈[43,200,108,000]，Defeat在T≥43,200时grant1、否则0，Abandoned/Technical grant0且不重抽；任一outcome超出其合法域在生成reward前拒绝。

**Example:** roll选择index1且Victory时请求铁灵花种子3枚；Save重试仍读同一reward fact，不重抽。

### F2 — Seed grant after-image

The `zhangtian_seed_grant` formula is defined as:

`requested_i = random_quantity × I(candidate==i) + starter_i`

`consume_i = I(resolution==CONSUME AND selected_seed_id==i)`

`available_i^c = available_i; reserved_i^c = reserved_i-consume_i; consumed_i^c = consumed_i+consume_i`

`held_room_i = SEED_HELD_CAP - (available_i^c + reserved_i^c)`

`lifetime_room_i = INT64_MAX - earned_i`

`applied_i = min(requested_i, held_room_i, lifetime_room_i)`

`cap_disposition_i`是total function：`requested_i=0→NOT_APPLICABLE`；`applied_i=requested_i>0→FULL`；`applied_i=0<requested_i→NO_ROOM`；其余partial按room较小者分别为`PARTIAL_HELD/PARTIAL_LIFETIME`，`held_room_i=lifetime_room_i`则为`PARTIAL_BOTH`。相等tie不得依赖if分支顺序。

`available_i' = available_i^c + applied_i; reserved_i'=reserved_i^c; consumed_i'=consumed_i^c; earned_i'=earned_i+applied_i`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Current count | `A_i` | int64 | 0–999 | seed i available |
| Random quantity | `N` | int64 | 0, 1 or 3 | F1结果；只加到candidate type |
| Starter grant | `S_i` | int64 | 0 or 1 | 首个正常Victory/Defeat且claim=0时三类均1 |
| Held room | `Q_i` | int64 | 0–999 | mandatory consume后`999-(A_i^c+R_i^c)` |
| Lifetime room | `L_i` | int64 | 0–INT64_MAX | `INT64_MAX-earned_i` |
| Applied grant | `G_i` | int64 | 0–4 | 显式saturation后的实际入账；首次Victory的candidate类可请求4 |

**Output Range:** 同一Settlement transaction严格先按F4 consume matching reservation，再用post-consume held room应用Victory/Defeat/starter grant；未触顶时Victory随机新增3、Boss线Defeat新增1、首次正常结算另新增三类各1。`cap_disposition`使用Settlement封闭值`FULL/PARTIAL_HELD/PARTIAL_LIFETIME/PARTIAL_BOTH/NO_ROOM/NOT_APPLICABLE`；不得再发布未定义的`AT_CAP_*`别名。不得溢出或卡死正常结算；starter claim仍同transaction置1且重试不补发。

**Example:** 首次Victory随机到雷元果、原库存[0,0,0]，输出available=[1,1,4]并starter claim=1。

### F3 — Reservation balance

The `zhangtian_reserve_seed` formula is defined as:

`available_s' = available_s - 1; reserved_s' = reserved_s + 1`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Selected available | `A_s` | int64 | 1–999 | matching seed库存 |
| Selected reserved | `R_s` | int64 | 0 | 全局无pending时 |

**Output Range:** selected available非负、reserved总和=1；NONE选择count逐位不变，但domain revision与next preparation ID推进一次。

**Example:** 铁灵花available=2确认后为1、reserved=1；durable前UI仍显示confirmed旧库存+“正在备战”。

### F4 — Consume or release

The `zhangtian_reservation_resolution` formula is defined as:

`consume: reserved_s^c=reserved_s-1, consumed_s^c=consumed_s+1; release: reserved_s'=reserved_s-1, available_s'=available_s+1`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Reserved count | `R_s` | int64 | exactly 1 | matching reservation |
| Resolution | `D` | enum | CONSUME/RELEASE | sealed/durable disposition |

**Output Range:** reserved总和回0；consume使历史consumed+1并作为正常Settlement F2 grant的强制第一子步，release使available恢复1且不与normal grant同事务；NONE reservation为no-op。

**Example:** available1、reserved1的锻体丹reservation在战败后consume为available1/reserved0/consumed+1。

### F5 — Resolved maximum HP

The `zhangtian_resolved_max_hp` formula is defined as:

`max_hp = base_max_hp × (1 + 0.03 × longchun_level + iron_body_bonus)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base HP | `H0` | float64 | 100 MVP；[1,1,000,000] | Player base |
| Longchun level | `L` | int32 | 0–5 | Progression projection |
| Iron-body bonus | `B` | float64 | 0 or 0.15 | pill projection |

**Output Range:** MVP 100–130；非finite或超Player domain时Loading失败，不clamp。

**Example:** 长春L5+锻体丹=`100×(1+0.15+0.15)=130`，不是132.25。

### F6 — Resolved critical chance

The `zhangtian_resolved_crit_chance` formula is defined as:

`crit_chance = base_crit_chance + 0.01 × dayan_level + clear_mind_bonus`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base crit | `C0` | float64 | 0.05 MVP；[0,1] | Damage base |
| Dayan level | `D` | int32 | 0–5 | Progression projection |
| Clear-mind bonus | `B` | float64 | 0 or 0.08 | 8个百分点 |

**Output Range:** MVP 0.05–0.18；Damage继续strict `u<C`，超[0,1]fail closed。

**Example:** 大衍L5+明心丹=`0.05+0.05+0.08=0.18`。

### F7 — Starting level projection

The `zhangtian_starting_level` formula is defined as:

`starting_level = 1 + (starting_level_curve_credit == 14 ? 1 : 0)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base level | `L0` | int32 | exactly 1 | Leveling fresh run |
| Starting curve credit | `E0` | int64 | 0 or 14 | 聚气丹only；进入`total_applied_xp`但不创建PICKUP fact |

**Output Range:** 1 or 2；credit14同时要求initial level choice count=1且remaining XP=16538。

**Example:** 聚气丹新局以LV2/xp0启动，并在移动开放前完成一项普通功法选择。

## 5. Edge Cases

- **If 三种库存全0**：NONE仍可确认并进入试炼；不显示伪“推荐”或阻断首局。
- **If 库存恰1**：一次reserve后available=0；重复点击/回调不再扣。
- **If 切卡100次但未确认**：durable mutation、RNG call与成功音均为0。
- **If same command重复100次**：返回同pending/result，最多一个reservation；同ID异payload为CONFLICT。
- **If 两个seed command基于同revision**：single writer只接受首个，另一STALE/BUSY且不自动换药。
- **If reserve PONR前失败**：旧domain逐位不变并回DRAFT；不得显示已扣。
- **If reserve结果不确定**：冻结返回、换药、新局和功法购买，仅同operation reconcile；NOT_FOUND仍不判失败。
- **If Loading可重试失败**：先durable RELEASE，完成前Prep不可重新消费；release重复为OK_NOOP。
- **If 已进入合法战斗后主动退出**：丹药CONSUME，不返还。
- **If TECHNICAL_ABORT带TECHNICAL_COMPENSATION**：只按sealed disposition release一次；UI不得自行加回。
- **If 当前战斗中库存/配置变化**：当前projection逐位不变；下一局重新读取。
- **If 首次正常结算commit重试或重建**：starter reserve与claim最多一次，庆祝不重播。
- **If 首次Victory随机种与starter同类**：candidate类本次请求+4、其余+1，非duplicate；starter不计入可重复随机奖励速率cohort。
- **If Defeat早于43,200 committed Active ticks**：candidate仅留审计，random grant=0；starter仍只在首个正常结算exact-once发放。
- **If 合法grant超过某类held cap999**：按F2显式部分/零入账并展示库存已满；累计earned可超过999，结算与claim仍可完成。
- **If normal seed RNG fault**：Outcome不得seal为可保存normal结果；不改用时间、UI或另一流重抽。
- **If CORE_HERB出现**：只显示胜利核心灵药，不进入三seed数组。
- **If 聚气丹initial choice生成失败**：战斗consumer不开放；不把LV2和choice丢失的半状态发布为Active。
- **If 明心/锻体输入非finite或越界**：Loading失败并走reservation release/uncertain协议，不clamp。
- **If domain未来版本或损坏**：UPDATE_REQUIRED/CORRUPT_BLOCKED并保留bytes，不创建空库存。
- **If identity/count checked overflow**：任何写入、音频、Loading transition均为0。
- **If reservation已durable但callback/Prep detach前进程终止**：重启从`RunStartRecoveryV1+PrepCommitJournalV1`继续同一handoff，不生成新seed/run identity。
- **If ActiveEntryFact已durable但无sealed Outcome时进程终止**：恢复执行matching CONSUME；不得强杀返丹。
- **If UI重建或reconcile found**：读取durable状态，不重播封签/解锁/消耗反馈。

## 6. Dependencies

| Dependency | Contract | Status |
|---|---|---|
| SaveSystem | generic domain + reservation/consume/release/reconcile | 静态ABI存在；Zhangtian codec/crash runtime BLOCKED |
| Settlement/BATTLE_RULES | normal seed draw、starter grant、terminal mutation | 本批次设计；integration/runtime待证 |
| Config/Data | HerbConfig、projection schema、domain max132与mapping | 静态合同已传播；generated resource/codec待实现 |
| RNG | fixed `ZHANGTIAN_HERB` stream | core已复审；本消费表需传播/replay |
| GameRoot | HOME→PREP、durable reserve guard、Loading/Outcome disposition | PREP edge需传播 |
| Player/Damage | F5/F6 | 静态传播完成；typed projection AC/runtime待证 |
| Leveling/SkillDraft | F7与initial choice | 静态传播完成；`PROVISIONAL-PREP-LEVEL-V2`待试玩 |
| Progression Tree | Dayan refresh、Longchun/Qingyuan初始loadout projection | Designed / Full Review Pending；matching snapshot/replay runtime待证 |
| BossStateMachine | 43,200 tick入场线与normal Victory/Defeat边界 | Designed / Full Review Pending；terminal integration待证 |
| Stage & Map | 1,800秒技术上限与60Hz→108,000 Active ticks | Re-review Pending；Config equality guard/runtime待证 |
| Prep/Home UI | typed view/command、阻断态 | 本批次设计；正式UX待`/ux-design` |
| Audio Feedback | selection/reservation与`SAVE_DURABLE_STAMP` unlock modifier | V2唯一producer/preimage已传播；assets/runtime待证 |

## 7. Tuning Knobs

| Knob | Baseline | Classification | Change rule |
|---|---:|---|---|
| seed/pill types | 3/3 | FIXED MVP | 改动需schema+UX+balance revision |
| normal seed weight | 1/1/1、MVP无pity | PROVISIONAL-BALANCE | RNG分布与玩家缺货/选择率分开验证 |
| Victory random seed | candidate type ×3 | PROVISIONAL-ECONOMY-V6 | 只承诺gross grant-rate；以`3*T_defeat > T_victory`交叉乘法验证，不做整数除法 |
| Defeat seed eligibility | 43,200 Active ticks | PROVISIONAL-ECONOMY-V6 | net flow另覆盖服丹/NONE、胜率、局长与饱和；合法survival上限108,000 |
| per-seed held cap | available+reserved≤999 | FIXED V1 | lifetime earned/consumed仅受int64约束 |
| first normal settlement starter | each type +1 | CONCEPT LOCKED | Victory/Defeat最先durable者exact-once |
| pills per run | 0 or1 | FIXED MVP | 不支持叠加 |
| real-time maturation | 0 seconds | FIXED MVP | 不引入等待 |
| 聚气丹 | start level +1 / choice +1 | PROVISIONAL-BALANCE/PREP-LEVEL-V2 | 首次操作/流失/成型时间后冻结 |
| 锻体丹 | base maxHP +0.15 additive | PROVISIONAL-BALANCE | 与Player F3A一致；显示resolved前后值 |
| 明心丹 | crit +0.08 points | PROVISIONAL-BALANCE | 与Damage/Dayan同加法域；比较实际可暴击伤害 |
| domain max | 132 bytes | FIXED V1 | schema变更需migration |

## 8. Visual / Audio / UI Requirements

Prep顶部显示当前选择摘要，中部三张灵药卡与明确的“不服丹”第四选项，底部固定唯一主CTA。默认NONE只是本地草稿；玩家按下CTA才构成明确“不服丹”确认。每卡同时显示种子名、库存、丹药名与完整下一局效果；库存0不隐藏。玩家文案固定为聚气“下局以2级开始；行动前先选1项功法”、锻体“下局最大生命X→Y”、明心“下局暴击率X%→Y%”、NONE“本局不服丹；不消耗种子，也没有丹药加成”；credit/hash/revision只进实现合同。选中态用勾、实体边框和“已选择”，不可只靠颜色；触控热区≥56 logical px（目标≥48dp）。

选卡可处置一次轻触但不表达已消费；按钮press无成功重音。资源存在、未静音且无kill/callback-loss的matching fresh-live reservation durable或RELEASED edge必须各播放恰1次短封签；只有enqueue/voice边界的process-kill窗口允许总次数0..1。rebuild/reconcile/unmute不补播；CONSUMED terminal、pending/uncertain/failure均为0返还音并以中性文字、图形和读屏状态表达。reduce sensory load关闭瓶液循环、墨迹扫屏和数值滚动；静音不损失语义，音画完成不成为Loading gate。

基准720×1280、`canvas_items/expand`，正文列居中且不因宽屏横向拉长；safe-area、360×640、390×844、430×932、100/115/130%字体与长本地化必须成立。可访问顺序固定返回→标题→摘要→四选一radio group→代价说明→主CTA；卡片暴露name、库存、selected/unavailable与position，缺货卡可读但不可激活。移动端架构固定采用`docs/architecture/adr-0001-mobile-accessibility-bridge.md`的`MobileAccessibilityBridgeV1`与`AccessibleScreenSnapshotV2`，并逐行匹配ASN03/ASN04 node profile；248-byte row携带layout generation、logical bounds、visible/clipped与typed localization args。Android/iOS原生adapter映射TalkBack/VoiceOver并把动作转回`AccessibilityActionCommandV2`；keyboard/mapped-gamepad只经八行Meta UI InputMap生成同一typed command，raw axis为0。PREP/PRE_ACTIVE_CHOICE/BATTLE_PAUSED/SETTLEMENT的owner明确，HOME由Home presenter，CONTROLLED_FAULT只由persistent GameRoot fault presenter；其余state仍drain stale callback。架构路径已签发；插件实现、导出包能力握手、accessibility tree与真机trace仍为`BLOCKED-MOBILE-A11Y-RUNTIME`。Control属性或桌面读屏不得替代这些证据。

📌 **UX Flag**：Prep/掌天瓶需在Pre-Production运行`/ux-design`；本文不是完成UX原型。

第八轮无障碍覆盖：上述移动端与首页旧口径中的“六行 Meta UI”均由当前 `MetaUiInputActionManifestV1` 八行（含 INCREMENT/DECREMENT）替代；BATTLE_PAUSED 的动态 choice 节点遵循 ADR 互斥容量规则。

📌 **Asset Spec**：需为掌天瓶、三种种子/丹药及封签反馈制作不同剪影/材质资产，不得只换色。

## 9. Acceptance Criteria

- **AC-ZB01 `[L/I][BLOCKING]` — GIVEN**132-byte golden、131/133 bytes、schema0/2、逐字段截断、negative、available+reserved>999、合法earned/consumed>999、守恒破坏、reserved sum2、flag2、`unlocked/claim={0/1,1/0}`、locked但任一ledger非零与next ID0，**WHEN**decode→validate→canonical re-encode，**THEN**只接受满足held cap/守恒且flags为`0/0`或`1/1`、locked ledger全0的canonical bytes，lifetime>999本身不拒绝；future为UPDATE_REQUIRED，其余CORRUPT_BLOCKED，source bytes保留且write/default0。
- **AC-ZB02 `[L/I][BLOCKING]` — GIVEN**durable RESERVED、全部draw前checkpoint OK、call_begin=N及owner-private weights，**WHEN**调用F1，**THEN**成功仅一次public call、call_end=N+1、index按0/1/2映射stable ID；任一fault时candidate publish0并进入release，同run handoff重试额外call0。
- **AC-ZB03 `[L/I][BLOCKING]` — GIVEN**独立seed/call-index→seed-ID golden、8流pre-state，以及流注册/容器顺序扰动和其他流0/100次调用，**WHEN**F1，**THEN**结果等于golden、ZHANGTIAN计数+1、其他7流state/count逐byte不变。
- **AC-ZB04 `[L/I][BLOCKING]` — GIVEN**Victory/Defeat在ticks0/43199/43200/43201/108000/108001及Abandoned/Technical，**WHEN**验证input并生成seed reward，**THEN**Victory仅43200/43201/108000合法且quantity3，Defeat为0/0/1/1/1并拒绝108001，其余合法域内quantity0；速率比较只量化有随机奖励的eligible cohort，即对所有`T_v,T_d∈[43200,108000]`以checked `3*T_d > T_v`成立证明Victory随机seed/Active-minute严格更高。Defeat的0..43199合法零奖励输入只验证quantity=0，不进入速率不等式；除法与零分母路径调用0。
- **AC-ZB05 `[L/I][BLOCKING]` — GIVEN**由合法ledger fixture generator枚举`selected=i`时`reserved_i=1`、非selected时`reserved_i=0`，post-consume held为0/1/998/999、random requested0/1/3、starter requested0/1、earned为`INT64_MAX-{0,1,3,4}`、`held_room<=>lifetime_room`三类及合法flag组合，**WHEN**同一transaction按F4→F2，**THEN**matching reservation先consume再计算held/lifetime room，输出逐seed `{random_requested,starter_requested,applied,cap_disposition}`，tie精确为PARTIAL_BOTH，applied为0..4、held≤999、守恒成立且claim exact-once；任一checked arithmetic失败或非法旧档0 mutation。
- **AC-ZB06 `[I][BLOCKING]` — GIVEN**NONE及三种选择切换100次，**WHEN**未确认，**THEN**profile/reservation/RNG写入全0，仅local draft revision按序变化。
- **AC-ZB07 `[I][BLOCKING]` — GIVEN**canonical Prep command的page/press/profile/domain/config/save/content/hash逐字段单轴破坏，**WHEN**validate，**THEN**仅全matching且库存>0或NONE接受；page/press/source stale返回`WRONG_STATE`，profile/domain/save stale返回`STALE_REVISION`，config revision/hash不等返回`INVALID_CONFIG`，payload/hash不等返回`CONFLICT`，且全部在identity/reservation/write/RNG前失败。
- **AC-ZB08 `[I][BLOCKING]` — GIVEN**seed/NONE、next preparation ID1/MAX与两个同base命令正反到达，**WHEN**reserve，**THEN**唯一胜者分配old next ID并令domain/profile revision各+1；NONE count不变，MAX为ID_EXHAUSTED且旧bytes不变，败者不rebase。
- **AC-ZB09 `[C/I][BLOCKING]` — GIVEN**同176-byte create request、204-byte create V3 result、`ReservationUpdateRequestV2`/callback/restart各100次、五种payload presence矩阵、五类typed mailbox result及同identity异hash，**WHEN**reserve/update/reconcile，**THEN**所有create result回显matching source kind/command/press/request hash；pre-durable correlation重复只分配一组identity，durable RESERVED/count、operation identity与CREATE的非零120-byte receipt最多一次，FAILED/UNCERTAIN/ID_EXHAUSTED时allocated字段全0但source correlation保留；ADVANCE/UPDATE/MARK/RETIRE receipt固定0/ZERO32，唯一`ResolveReservationPayloadV3`返回160-byte terminal result且receipt ID=request ID，CONSUMED/RELEASED逐位可分，duplicate返回原typed result、conflict/错kind payload零写；无kill且未静音的fresh-live create/release恰1声，kill窗口0..1，CONSUMED/boot/reconcile补播0。
- **AC-ZB10 `[C/I][BLOCKING]` — GIVEN**7-row `ReservationCrashOperationManifestV1`×12-row `ReservationCrashCutManifestV2`唯一展开的84-row artifact、reserve的temp逐byte、file barrier、replace、directory barrier、两槽write/readback、callback loss、short write/ENOSPC，**WHEN**逐行kill并restart，**THEN**result schema与profile/reservation/marker/resolution/receipt/tombstone presence只由operation row决定，selected OLD/NEW与public/reconcile code只由stage row决定；首个formal VALID前可证明无durable才FAILED，RCC07/08按selected fact分别FOUND_OLD/FOUND，首个VALID后选择NEW并heal，RCC11 callback loss只返回FOUND，RCC12已发布success的duplicate返回同typed result，第二identity与Loading均0；任一range、自填expected或manifest/golden未生成不得PASS。
- **AC-ZB11 `[I][BLOCKING]` — GIVEN**UNCERTAIN与matching RESERVED/RELEASED/CONSUMED/NOT_FOUND_UNPROVEN/PROVEN_ABSENT/conflict/future/corrupt scan，**WHEN**同operation reconcile，**THEN**逐态进入FSM唯一目标；RESERVED继续同一handoff，NOT_FOUND_UNPROVEN保留IDs冻结，PROVEN_ABSENT只清matching volatile correlation并回fresh Prep，其他状态不创建新局。
- **AC-ZB12 `[I][BLOCKING]` — GIVEN**`DurableReservationV2.prep_commit_journal`七个canonical checkpoint、顶层journal缺失约束及每点fail/restart，**WHEN**收敛，**THEN**checkpoint1与reservation/domain/allocator同槽原子，后续按唯一reconcile disposition继续同一run-start或先durable release；不存在memory-only checkpoint或第二truth source，第二run/seed/preparation ID、旧page command与战斗movement均0。
- **AC-ZB13 `[I][BLOCKING]` — GIVEN**seed/NONE×Victory/Defeat/Abandoned/Technical×reservation state，**WHEN**resolve，**THEN**V/D/A mandatory consume，Abandoned为零奖励tombstone+consume同事实；Technical仅按sealed compensation release；duplicate exact-noop、UI guess写入0。
- **AC-ZB14 `[C/I][BLOCKING]` — GIVEN**reserve后、Loading中、Active marker前后与sealed outcome前后的process kill，**WHEN**boot recover，**THEN**marker前checkpoint1..6+exact config按RRD11继续同一handoff、config不可得按RRD12停在UPDATE_REQUIRED、durable RELEASE按RRD05回fresh Prep；只有完整absence proof按RRD13清volatile correlation，unproved absence按RRD04保持UNCERTAIN；marker后无Outcome按RRD09 consume，sealed disposition按RRD07/08优先；永不使用“继续或release”二义oracle、强杀返丹或永久reserved。
- **AC-ZB15 `[L/I][BLOCKING]` — GIVEN**H0=100、长春0..5、B∈{0,0.15}及非法组合，**WHEN**F5，**THEN**无丹为100/103/106/109/112/115、有丹为115/118/121/124/127/130；非法在Active前fail且不热改。
- **AC-ZB16 `[L/I][BLOCKING]` — GIVEN**C0=.05、大衍0..5、B∈{0,.08}与u在C相邻/相等值，**WHEN**F6，**THEN**无丹为.05..10、有丹为.13..18且只有u<C暴击；非法在Active前fail且不热改。
- **AC-ZB17 `[L/I][BLOCKING]` — GIVEN**NONE/聚气丹与matching/mismatched `LEVEL_UP+PREPARATION_CURVE_CREDIT` request、base offer readback前Back、offer build/durable fault、duplicate commit，**WHEN**Loading，**THEN**NONE为LV1/xp0/curve-credit0；聚气为LV2/xp0/credit14/remaining16538并在root gate held下完成ordinal1普通规则choice；readback前interactive snapshot/action均0且不存在玩家cancel event，clear build failure只经系统LFD25 durable RELEASE后回fresh Prep，任一write possible/readback unknown或durable/visible事实走LFD26并保持同reservation；完成前movement/survival0、失败不发布Active。
- **AC-ZB18 `[I][BLOCKING]` — GIVEN**完整projection golden及identity/revision/hash单轴stale、profile/config热改，**WHEN**bind→Active→Pause→Resume，**THEN**仅全matching projection被消费且当前bank/hash逐byte不变；Zhangtian phase callback与四类contribution均0。
- **AC-ZB19 `[I][BLOCKING]` — GIVEN**CORE_HERB、三seed、cap saturation及row排列/duplicate/unknown，**WHEN**Settlement应用，**THEN**CORE只改Settlement domain，seed只改Zhangtian，合法同类gift+candidate按F2，非法整bundle拒绝。
- **AC-ZB20 `[I][BLOCKING]` — GIVEN**migration_count=0、future schema2与corrupt V1，**WHEN**load，**THEN**migration调用0，分别UPDATE_REQUIRED/CORRUPT_BLOCKED并保留bytes；未来新增V0时必须先提供逐byteV0→V1 golden与kill matrix，空集不得PASS。
- **AC-ZB21 `[UX/A][OPEN-EVIDENCE]` — GIVEN**四个明确safe rect/cutout、字体100/115/130%、中英长文案、DRAFT/selected/empty/reserving/uncertain/releasing/blocked/PRE_ACTIVE_CHOICE/BATTLE_PAUSED及touch/keyboard/gamepad/screen-reader，另含未经Input mapping的native raw gamepad axis负例，**WHEN**按ADR逐状态semantic oracle render/navigation，**THEN**P0节点不裁切重叠、touch≥56 logical且目标机≥48dp、screen bounds/动态库存与X→Y文本参数/focus/reading/live announcement逐行匹配；keyboard/gamepad focus与activation生成同一typed command，raw unmapped axis生成0业务命令；保存截图、accessibility tree与input trace。
- **AC-ZB22 `[I][BLOCKING]` — GIVEN**selection/reserve/CONSUMED/RELEASED、`SAVE_DURABLE_STAMP` unlock bit0/1、伪独立unlock、mute/unmute、detach、rebuild、reconcile、missing asset及声前/声后kill，**WHEN**app audio disposition，**THEN**每个semantic identity只有一个owner；pending/uncertain与CONSUMED返还声为0，未静音且无kill的fresh-live reserve/release恰1 voice，只有kill窗口0..1；unlock只作stamp modifier且恰一voice，伪独立unlock为0 event，Loading不等待音画。
- **AC-ZB23 `[R/M][OPEN-EVIDENCE]` — GIVEN**签发build/config/workload/device/thermal/storage manifest，**WHEN**执行codec、Loading、reservation crash与100次page rebuild，**THEN**分别报告byte golden、allocation/growth/COW、p50/p95/p99/max、RSS、writer与live page/signal counters；阈值未冻结只判MEASURED/INCONCLUSIVE。
- **AC-ZB24 `[E][OPEN-EVIDENCE]` — GIVEN**预注册目标玩家样本，**WHEN**比较无丹/三丹及重复Prep，**THEN**分别报告first-visible/interactive、choice时长/退出率、全库存条件选择率、缺货P95、10/20局库存斜率与seed/Active-minute；RNG≥1000候选频数单独报告，不代替经济健康。
- **AC-ZB25 `[L/I][BLOCKING]` — GIVEN**合法ledger含`{A=998,R=0,C=1,E=999}`、`{0,0,999,999}`、held999、Victory quantity3、Boss线Defeat quantity1与starter claim0/1，**WHEN**resolve→F2，**THEN**`A'+R'≤999`、`A'+R'+C'=E'`，E/C可超过999但不得int64溢出；历史累计永不使正常结算失活。
- **AC-ZB26 `[C/I][BLOCKING]` — GIVEN**七个Prep checkpoint、candidate draw前/后、每次pre-active base/refresh scratch lease的draw前、draw后、durable write前后、publish前后及ActiveEntry前后kill/callback loss、同内容不同process-local snapshot/bank/generation与内容hash不等，**WHEN**restart，**THEN**FAILED scratch不改变old cursor/charge/revision，UNCERTAIN只reconcile；selected formal hash=next时只允许`RECONCILE_FOUND`并采用durable next cursor，selected formal hash=old且双槽/temp/writer证明attempt未durable时只允许`RECONCILE_FOUND_OLD`并discard scratch，UNPROVEN继续冻结，code/hash错配fail closed。只从360-byte recovery恢复同一identity/candidate/RNG并重建逐位相同的252-byte offer与296-byte loadout semantic carriers。仅retention manifest内durable content revision+hash相等可rebind新local identity，第二logical candidate/choice/run均0。
- **AC-ZB27 `[I][BLOCKING]` — GIVEN**`ReservationReconcileDispositionManifestV2`13行、其前置marker/checkpoint/terminal invariant validator、`ReservationUpdatePayloadManifestV1`五行、matching/stale generation/checkpoint/hash、五种payload缺/重/错schema、marker/outcome/config-content与proved/unproved absence组合，**WHEN**update/reconcile/retire，**THEN**矛盾先判CORRUPT且不得被RRD07/08吞掉，其余每行只有一个target/write/new-run/UI state；只有完整RRD13 proof可清volatile correlation。唯一1112-byte `ResolveReservationPayloadV3`原子写reward/tombstone、264-byte resolution、776-byte next profile并清live carriers，160-byte result与restart逐位返回同一120-byte receipt且明确CONSUMED/RELEASED；第二Save commit、out-of-band bytes或二义expected均为0。
- **AC-ZB28 `[I][BLOCKING]` — GIVEN**`HashPreimageManifestV1`全部hash rows及任一单字段/重复字段翻转，**WHEN**canonical encode/hash，**THEN**SELF_ZERO_FIELD行恰一对象tag/zero range/exact length，EXTERNAL_PAYLOAD行只hash独立payload bytes且zero range为空；错误模式、对象tag、missing row、alias backing与外内carrier不等均在write前拒绝。
- **AC-ZB29 `[R/M][OPEN-EVIDENCE]` — GIVEN**签发的exact workload rows、parent hash、markers、warmup、3次独立run、raw sample hash、observer版本与positive control，**WHEN**执行codec-max、reservation/reconcile、NONE/三pill Loading及100-cycle page rebuild，**THEN**结构计数逐行PASS；parent stale或正控无效为INCONCLUSIVE，latency/RSS未冻结只可MEASURED。
- **AC-ZB30 `[E][OPEN-EVIDENCE]` — GIVEN**预注册样本量、置信规则及三丹/NONE/经济阈值，**WHEN**按永久成长层级和全库存条件比较，**THEN**判定CTA→offer/choice/movement时延、退出率、DPS/容错/成型收益、缺货P95、库存斜率与Victory/Defeat seed per Active-minute；只报告或RNG频数不得PASS。

## 10. Open Questions / Evidence Gates

| ID | Gate | Owner | Status |
|---|---|---|---|
| OQ-ZB01 | 聚气丹开局choice是否造成可接受的前置停顿？ | UX/Balance | PROVISIONAL；目标用户试玩 |
| OQ-ZB02 | 等权无pity的缺货P95与三药条件选择率是否健康？ | Economy | PROVISIONAL；RNG频数与玩家行为分开 |
| OQ-ZB03 | reservation wrapper/max slot与codec golden？ | Save/Config | DESIGN CONTRACT REVISED；generated/runtime BLOCKED |
| OQ-ZB04 | ZHANGTIAN_HERB Loading调用与BATTLE_ENDING Outcome join？ | Settlement/RNG/GameRoot | DESIGN CONTRACT REVISED；manifest regen待完成 |
| OQ-ZB05 | Godot 4.7.1 kill/barrier/dual-focus与TalkBack/VoiceOver bridge证据？ | Engine/QA | ADR-0001路径已冻结；runtime/device BLOCKED |
| OQ-ZB06 | 正式Prep UX、Art/Sound assets与真机？ | UX/Art/Audio | BLOCKED |
| OQ-ZB07 | clean-context full review？ | Review team | 第七次MAJOR REVISION NEEDED已整改；第八次OPEN |

## 11. Handoff

### 第八轮跨文档合同整改（2026-09-08）

本轮将当前契约统一为：`DurableReservationV2`/`ZhangtianReservationPayloadV2`分别为1152/724 bytes，持久化64-byte `ReservationCreateCorrelationV1`并与32-byte internal prepare hash分离；`ReservationCreateResultV3`回显五项source correlation（含attempt generation）。`ReservationUpdateIdentityLeaseV1`在Save事务外只读签发candidate request/tombstone identity，实际分配与消费仍在同一update transaction。RCO升级为V2十一个operation，RCC×RCO唯一展开132行；RRD marker/checkpoint前置规则、RESOLVE `FOUND_OLD`返回与旧reservation保留已闭合。ADR新增BATTLE_PAUSED动态choice节点与Settings四持久布尔字段，Input Meta UI扩为8行并加入INCREMENT/DECREMENT；native MPSC row改为68-byte payload、96-byte row，serial ingress补齐76-byte command。Boss tick边界明确为completed-before/executing-ordinal/completed-after，43200执行tick可产生Boss且phase7 survival=43200合法。旧V1/660/1088/84口径仅为历史审计记录，不得作为实现schema。

本文经第七次full review后的作者整改进一步冻结：204-byte create V3 result完整回显source correlation与operation identity、484-byte typed mailbox、durable receipt code与public reconcile code分层、update FOUND_OLD/FIND_NEW hash裁决；唯一`ResolveReservationPayloadV3`终局写与160-byte typed terminal result继续成立。Crash由7-row operation truth×12-row cut truth唯一展开84行；移动端入口补6208-byte MPSC64并发ABI；ADR签发逐node/variant合同，Input区分presenter-local focus与native action，Settlement补typed detail分页。pre-active scratch lease、append-only config retention、random gross而非net库存优势、120-byte receipt、13-row reservation disposition、total cap disposition、七checkpoint和无玩家cancel继续成立。本文仍没有生成codec/hash/crash/config/a11y artifacts，也没有证明Save平台durability、聚气丹体验、RNG/经济健康、Godot/GDUnit4、移动端读屏/gamepad真机、正式UX/资产或运行时接线。

状态保持`In Review / Re-review Pending`；跨文档传播与静态检查已完成，仍应在fresh context运行第八次`/design-review design/gdd/zhangtian-bottle.md --depth full`，不得在本整改会话宣称Approved、implementation-ready、runtime verified或battle_ready。
