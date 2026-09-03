# Zhangtian Bottle（掌天瓶）

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / economy-designer / qa-lead / UX reviewer）
> **Created / Last Updated**: 2026-09-03
> **Implements Pillar**: 根据已有储备做一次明确的战前取舍；局外选择影响下一局但不替代构筑与走位
> **Scope**: MVP三种灵药种子、即时催熟、每局至多一种丹药、开局reservation、下一局只读投影与结算种子入账；不含真实时间等待、种植田、炼丹配方、品质、失败率或商业化

## 1. Overview

Zhangtian Bottle 是灵药种子库存、催熟选择、丹药效果语义与开局资源 reservation after-image 的唯一业务 owner。玩家在每局前可消耗一枚凝气草、铁灵花或雷元果种子，分别制成聚气丹、锻体丹或明心丹，也可不服丹直接出战；掌天瓶只提供下一局准备，不直接造成伤害。

种子扣减必须先 durable，随后 GameRoot 才能进入 `BATTLE_LOADING`。丹药效果只从 matching reservation 构建本局 immutable projection，Active、Paused、恢复或晚到 callback 均不得热改。Save 只保存 canonical domain/after-image并仲裁 exact-once，不解释灵药规则；Prep UI 只提交选择 identity，不拥有库存。

## 2. Player Fantasy

玩家在出发前像韩立一样审视已经拥有的储备，为这一局做一次明确取舍：想更快成型就服聚气丹，担心容错就选锻体丹，追求爆发则选明心丹。种子的取得顺序可以随机，但是否消耗、消耗哪一种始终由玩家决定；选择明确、立刻生效、不强迫等待，也允许“这局先不用”。MVP把它定位为胜利偏置、可积累的随机储备：首次正常结算提供三类starter reserve，后续胜利是主要净增来源，失败不能成为高于胜利的seed/min路线。

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

每类不变量为`available_i+reserved_i+consumed_i=earned_i`，四项均为checked non-negative int64；`available_i+reserved_i<=SEED_HELD_CAP=999`，`earned_i/consumed_i`是终身累计量，不受held cap限制但不得超过`INT64_MAX`。`sum(reserved_seed_counts)∈{0,1}`，与Save最多1条 unresolved reservation一致。首次成功保存的Victory或Defeat令unlocked与`starter_seed_grant_claimed`从0→1并发放starter reserve；两flag均只能0→1，next ID只增不减。unknown/缺/重/乱序、非canonical bytes、负数、held cap/守恒/checked-add失败或未来schema均fail closed，不clamp或补默认。合法奖励按F2对held room显式saturation，绝不因历史累计达到999而停止结算。

#### Static config 与动态投影分界

```text
HerbRecipeConfigV1={stable_order:i32,seed_id:i32,pill_id:i32,
  seed_cost:i32,effect_kind:i32,effect_i64:i64,effect_f64:f64,
  display_unit_id:i32,localization_key_id:i32}

HerbConfigV1={schema_version:i32=1,content_revision:i64,
  seed_kind_count:i32=3,seed_held_cap:i64=999,
  defeat_seed_eligible_ticks:i64=43200,victory_seed_quantity:i32=2,
  starter_seed_grant_per_kind:i32=1,seed_weights:i32[3],
  recipe_rows:HerbRecipeConfigV1[3],config_hash:Hash256}

ZhangtianProjectionRulesV1={schema_version:i32=1,content_revision:i64,
  qi_curve_credit:i64=14,qi_initial_choice_count:i32=1,
  iron_max_hp_bonus_ratio:f64=0.15,mind_crit_bonus_points:f64=0.08,
  rules_hash:Hash256}
```

三个recipe row按`NINGQI/TIELING/LEIYUAN`稳定顺序，seed/pill一一映射、`seed_cost=1`；对应effect只允许`CURVE_CREDIT/I64=14`、`MAX_HP_RATIO/F64=0.15`、`CRIT_POINTS/F64=0.08`，未使用的数值槽必须为规范零。静态manifest只含这些规则、stable localization key ID与hash；玩家库存、profile/domain/reservation/preparation/battle/run identity及选择结果禁止进入静态content hash。run-specific `ZhangtianBattleProjectionV1`只能从matching静态rules+durable reservation生成。

### 3.3 Normal settlement seed grant

每个admitted run在BATTLE_LOADING完成全部Config/RNG preflight后，以Config snapshot持有的owner-private、只读`PackedInt32Array([1,1,1])`调用`roll_weighted_pick(ZHANGTIAN_HERB, weights)`精确一次。`ZHANGTIAN_HERB.max_weights_length=3`，RNG三槽scratch在调用前预分配；消费方在使用返回index前检查fault，只有无fault且`rng_call_end=rng_call_begin+1`才按canonical row `index0/1/2→NINGQI/TIELING/LEIYUAN`冻结独立 `ZhangtianSeedCandidateV1`。fault时candidate publish=0并走Loading abort/release，不得把返回零值当凝气草。

候选不得回写已冻结的`RunStartRequestV2`。同一live-process handoff retry额外public call=0；若进程在candidate durable前终止，重启只能从durable run seed初始化独占流、在其他流消费前执行一次deterministic reconstruction并立即持久化candidate checkpoint，逻辑call ordinal仍为0。`VICTORY`按candidate发2枚；`DEFEAT`仅在`survival_ticks>=DEFEAT_SEED_ELIGIBLE_TICKS=43,200`（Boss入场线，60Hz下12分钟）时发1枚；更早Defeat、`ABANDONED`与`TECHNICAL_ABORT`保留审计candidate但随机grant=0。该规则为`PROVISIONAL-ECONOMY-V3`：任何Defeat路线的seed/Active-minute不得高于Victory envelope。Settlement/UI重建、Save重试或重启只读durable candidate与sealed资格。

首次正常 `VICTORY|DEFEAT` 且starter claim=0时，同一Settlement mutation向三种种子各加1并把claim置1；首次Victory因此通常请求5枚，首次Boss线Defeat请求4枚，较早Defeat请求3枚，均按held room逐类saturation。CORE_HERB是Boss胜利证明/独立reward item，不自动转换成三种种子，也不进入可服丹库存。

这项裁决取代旧传播稿“DEFEAT只保留已拾取种子”的表述：MVP没有三种种子的局内pooled pickup；普通种子唯一来源是Victory/到达Boss线Defeat的冻结随机奖与首次正常结算starter reserve。

### 3.4 Prep draft 与 command

Zhangtian只向Prep的canonical `PrepPresentationBundleV1`提供原子业务切片：`ZhangtianPreparationSliceV1={schema_version,profile_revision,domain_revision,content_revision,unlocked,available_counts[3],recipe_rows:HerbRecipeViewV1[3],slice_hash}`。它不包含UI local selection；三row按stable seed ID顺序，包含稳定pill ID、数值、单位与localization key，不把本地化字符串写入hash。Prep初始每次均选`NONE`，不记忆上局丹药。

选卡/切换/返回只改UI draft，产生0 profile write、0 reservation、0成功音。库存0的卡仍显示效果但不可选；“不服丹”始终可选。

唯一开局业务命令类型是Prep GDD的`PrepConfirmCommandV1`，不携带`preparation_id`；来源封闭为`PREP`与仅在未解锁/available全0合法的`HOME_DIRECT_NONE`。GameRoot验证fresh surface/press/bundle后取得run-seed candidate；Save在reservation transaction分配battle/reservation identity，并调用Zhangtian持久allocator构造唯一内部请求：

```text
PrepareRunRequestV1={
  schema_version:i32=1,source_command_id:i64,source_press_id:i64,
  preparation_id:i64,battle_instance_id:i64,run_seed:i64,
  expected_profile_revision:i64,expected_domain_revision:i64,
  expected_config_revision:i64,zhangtian_content_revision:i64,
  selected_seed_id:i32,selected_pill_id:i32,
  prep_bundle_hash:Hash256,request_hash:Hash256
}
```

correlation固定为`page_generation→press_id→command_id→preparation_id→battle_instance_id=reservation_id`。UI提供的pill/effect仅用于correlation，Zhangtian从matching Config重算映射。确认前必须满足GameRoot在PREP、Save READY、无unresolved outcome/archive/profile mutation/reservation、writer可接纳、revision/hash matching；任何guard失败为0 preparation/battle identity reserve、0 write。

### 3.5 Durable reservation

每次确认都由Save持久`next_identity`在同一reservation transaction内分配非零`battle_instance_id`，并令`reservation_id=battle_instance_id`；run seed只允许PREP release路径的OS entropy producer生成，dev build可用显式forced seed，玩家seed/每日seed不属于MVP。Zhangtian同时分配`preparation_id`。选择种子时构造`available−1,reserved+1` after-image；NONE count逐位不变，但domain/profile revision、两个allocator与typed `NO_PILL` reservation仍推进。任一validate/checked-add失败时所有allocator、seed与domain bytes保持原值；一旦首份可能durable，只能以同identity reconcile。

Save将`DurableReservationV1`、preparation identity、base/next domain hash和after-image放入同一双槽transaction。只有matching `RESERVED` durable success/readback后，GameRoot才冻结`RunStartRequestV2`并进入Loading；PONR前可证明未写入才FAILED，PONR后未知只能UNCERTAIN。

```text
ZhangtianReservationPayloadV1={
  schema_version:i32=1,reservation_id:i64,preparation_id:i64,
  battle_instance_id:i64,run_seed:i64,
  expected_profile_revision:i64,reserved_profile_revision:i64,
  config_content_revision:i64,zhangtian_content_revision:i64,
  selected_seed_id:i32,selected_pill_id:i32,
  base_domain_revision:i64,reserved_domain_revision:i64,
  base_domain_hash:Hash256,reserved_domain_hash:Hash256,
  run_start_recovery:RunStartRecoveryV1,
  battle_projection:ZhangtianBattleProjectionV1,request_hash:Hash256
}
```

canonical `RunStartRecoveryV1`固定276 bytes、little-endian、no-padding：`{schema_version:i32,reservation_id:i64,battle_instance_id:i64,run_seed:i64,preparation_id:i64,selected_seed_id:i32,selected_pill_id:i32,source_profile_revision:i64,source_domain_revision:i64,config_content_revision:i64,zhangtian_content_revision:i64,projection_hash:Hash256,prep_commit_operation_id:i64,handoff_checkpoint:i32,candidate_present:i32,candidate_seed_id:i32,rng_call_begin:i64,rng_call_end:i64,pre_active_choice_state:i32,pre_active_choice_request_id:i64,pre_active_offer_hash:Hash256,pre_active_choice_command_id:i64,pre_active_loadout_hash:Hash256,pre_active_skill_draft_rng_cursor:i64,next_level_request_sequence:i64,recovery_hash:Hash256}`。它本身足以逐位恢复run start、candidate和pre-active choice；wrapper中的重复字段必须逐位相等，否则首字节写入前`CONFLICT`。

`PrepCommitCheckpointV1`唯一枚举为`IDENTITIES_RESERVED=1,RESERVATION_DURABLE=2,RUN_START_FROZEN=3,PREP_TOUCH_RETIRED=4,LOADING_COMMITTED=5,SEED_CANDIDATE_DURABLE=6,PRE_ACTIVE_CHOICE_DURABLE_OR_SKIPPED=7,ACTIVE_ENTRY_DURABLE=8`。checkpoint1只存在于尚未写入的内存candidate；首次reservation transaction原子写入domain after-image、完整base recovery与journal checkpoint2并readback。之后每次journal/recovery更新都是同一reservation的单调slot transaction；不得使用`RESERVATION_REQUESTED/HANDOFF_DURABLE`别名。durable后任一失败优先继续同一handoff；只有canonical failure disposition允许先durable RELEASE再返回fresh Prep。

首次合法Active开放前，Save必须durable写入matching `ActiveEntryFactV1`；该事实存在而无sealed Outcome的跨进程恢复按CONSUME，防止强杀返丹。正常`VICTORY/DEFEAT/ABANDONED`均处理matching reservation为CONSUME：若有种子则`reserved−1,consumed+1`，NONE则count不变；奖励commit或discard不能撤销该成本。ABANDONED采用同一transaction中的“零奖励tombstone + mandatory consume after-image”，不是“profile逐位不变”。retryable load abort在Active前RELEASE；明确sealed `TECHNICAL_COMPENSATION`执行RELEASE。duplicate为OK_NOOP，同ID异payload为CONFLICT；UNCERTAIN冻结换药、返回、购买和新局，只允许同operation reconcile。

### 3.6 Battle projection 与生效

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

所有Hash256沿Save codec ADR的`SHA256_V1`与canonical little-endian codec；禁止Godot `hash()`。`HashPreimageManifestV1`必须为每个实际hash字段恰一行：`HerbConfigV1.config_hash→HerbConfigV1\0`、`ZhangtianProjectionRulesV1.rules_hash→ZhangtianProjectionRulesV1\0`、`DomainRecordV1.domain_hash(Zhangtian)→ZhangtianProfileDomainV1\0`、`ZhangtianPreparationSliceV1.slice_hash→ZhangtianPreparationSliceV1\0`、`PrepPresentationBundleV1.bundle_hash→PrepPresentationBundleV1\0`、`PrepareRunRequestV1.request_hash→PrepareRunRequestV1\0`、`ZhangtianReservationPayloadV1.request_hash→ZhangtianReservationPayloadV1\0`、`RunStartRecoveryV1.recovery_hash→RunStartRecoveryV1\0`、`DurableReservationV1.reservation_hash→DurableReservationV1\0`、`ZhangtianBattleProjectionV1.projection_hash→ZhangtianBattleProjectionV1\0`、`ZhangtianSeedCandidateV1.candidate_hash→ZhangtianSeedCandidateV1\0`、`ActiveEntryFactV1.fact_hash→ActiveEntryFactV1\0`。每行固定field order、exact bytes、嵌套inline/hash规则与32-byte zero range；没有self-hash的`PrepConfirmCommandV1`不得单列tag。golden至少覆盖NONE、三pill、held cap999、preparation/battle ID边界、单字段翻转、重复字段不等与zero-field；generated manifest/golden未签发时保持`BLOCKED-HASH-CODEC`。

聚气丹令Leveling初始snapshot为level2、xp0、`starting_level_curve_credit=14`，到L40的remaining accepted-XP budget为16538。它预置普通`LEVEL_UP` ordinal1；GameRoot在Loading内进入`PRE_ACTIVE_CHOICE`，root/input/gameplay gate保持关闭。基础offer、每次主动refresh与最终commit都先更新同一`RunStartRecoveryV1`并durable readback；记录offer/loadout hash、SkillDraft RNG cursor、command identity和choice state。commit后`next_level_request_sequence=2`，callback loss或进程重启只恢复同一页面/已提交loadout，不重抽或复用sequence；结果不明时冻结并reconcile。玩家在choice commit前返回须先durable RELEASE，完成后回fresh Prep/NONE。该前置选择不推进survival tick、不伪造XP fact；从Prep CTA release到offer interactive、choice commit与首次移动分别计时，继续标`PROVISIONAL-PREP-LEVEL-V2`。

### 3.7 States and transitions

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
| `PRE_ACTIVE_CHOICE_PENDING` | 聚气offer/refresh/commit持久恢复链 | ACTIVE_MARK_PENDING, RELEASE_PENDING, UNCERTAIN |
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
| Prep/Home UI | typed view/同一PrepConfirm command | 有库存进Prep；无库存HOME_DIRECT_NONE；UI无库存/Save writer |
| Audio Feedback | selected/reserved/released semantic edge | preview轻触与durable封签；无循环pending音 |

## 4. Formulas

### F1 — Settlement seed draw

The `zhangtian_seed_draw` formula is defined as:

`seed_index = roll_weighted_pick(ZHANGTIAN_HERB, preallocated_weights_111)`

`seed_reward_quantity = outcome==VICTORY ? 2 : (outcome==DEFEAT AND survival_ticks>=43,200 ? 1 : 0)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Outcome kind | `K` | enum | VICTORY/DEFEAT/ABANDONED/TECHNICAL_ABORT | sealed kind |
| Survival ticks | `T` | int64 | 0–INT64_MAX | committed Active ticks |
| Weights | `W` | PackedInt32Array[3] | exactly [1,1,1] | Config-owned stable seed ID order |
| Seed index | `I` | int32 | 0–2 | Loading中冻结的candidate |

**Output Range:** 每个admitted run恰1 logical public RNG call；Victory grant2，Defeat在T≥43,200时grant1、否则0，Abandoned/Technical grant0且不重抽。

**Example:** roll选择index1且Victory时请求铁灵花种子2枚；Save重试仍读同一reward fact，不重抽。

### F2 — Seed grant after-image

The `zhangtian_seed_grant` formula is defined as:

`requested_i = random_quantity × I(candidate==i) + starter_i`

`room_i = SEED_HELD_CAP - (available_i + reserved_i)`

`applied_i = min(requested_i, room_i)`

`available_i' = available_i + applied_i; earned_i' = earned_i + applied_i`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Current count | `A_i` | int64 | 0–999 | seed i available |
| Random quantity | `N` | int64 | 0, 1 or 2 | F1结果；只加到candidate type |
| Starter grant | `S_i` | int64 | 0 or 1 | 首个正常Victory/Defeat且claim=0时三类均1 |
| Held room | `Q_i` | int64 | 0–999 | `999-(A_i+reserved_i)` |
| Applied grant | `G_i` | int64 | 0–3 | 显式saturation后的实际入账；首次Victory的candidate类可请求3 |

**Output Range:** 未触顶时Victory随机新增2、Boss线Defeat新增1、首次正常结算另新增三类各1。触顶只按held room逐类入账并发布`AT_CAP_PARTIAL/AT_CAP_NO_GRANT`；starter claim仍同transaction置1且重试不补发。`earned/consumed`只受checked int64约束，不因值≥999停止奖励。

**Example:** 首次Victory随机到雷元果、原库存[0,0,0]，输出available=[1,1,3]并starter claim=1。

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

`consume: reserved_s'=reserved_s-1, consumed_s'=consumed_s+1; release: reserved_s'=reserved_s-1, available_s'=available_s+1`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Reserved count | `R_s` | int64 | exactly 1 | matching reservation |
| Resolution | `D` | enum | CONSUME/RELEASE | sealed/durable disposition |

**Output Range:** reserved总和回0；consume使历史consumed+1，release使available恢复1；NONE reservation为no-op。

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
- **If 首次Victory随机种与starter同类**：candidate类本次请求+3、其余+1，非duplicate。
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
| Prep/Home UI | typed view/command、阻断态 | 本批次设计；正式UX待`/ux-design` |
| Audio Feedback | selection/reservation/unlock cue | semantic rows/assets待传播 |

## 7. Tuning Knobs

| Knob | Baseline | Classification | Change rule |
|---|---:|---|---|
| seed/pill types | 3/3 | FIXED MVP | 改动需schema+UX+balance revision |
| normal seed weight | 1/1/1、MVP无pity | PROVISIONAL-BALANCE | RNG分布与玩家缺货/选择率分开验证 |
| Victory random seed | candidate type ×2 | PROVISIONAL-ECONOMY-V3 | 必须高于任何Defeat seed/min envelope |
| Defeat seed eligibility | 43,200 Active ticks | PROVISIONAL-ECONOMY-V3 | −1/= /+1与seed/min试玩 |
| per-seed held cap | available+reserved≤999 | FIXED V1 | lifetime earned/consumed仅受int64约束 |
| first normal settlement starter | each type +1 | CONCEPT LOCKED | Victory/Defeat最先durable者exact-once |
| pills per run | 0 or1 | FIXED MVP | 不支持叠加 |
| real-time maturation | 0 seconds | FIXED MVP | 不引入等待 |
| 聚气丹 | start level +1 / choice +1 | PROVISIONAL-BALANCE/PREP-LEVEL-V1 | 首次操作/流失/成型时间后冻结 |
| 锻体丹 | base maxHP +0.15 additive | PROVISIONAL-BALANCE | 与Player F3A一致；显示resolved前后值 |
| 明心丹 | crit +0.08 points | PROVISIONAL-BALANCE | 与Damage/Dayan同加法域；比较实际可暴击伤害 |
| domain max | 132 bytes | FIXED V1 | schema变更需migration |

## 8. Visual / Audio / UI Requirements

Prep顶部显示当前选择摘要，中部三张灵药卡与明确的“不服丹”第四选项，底部固定唯一主CTA。默认NONE只是本地草稿；玩家按下CTA才构成明确“不服丹”确认。每卡同时显示种子名、库存、丹药名与完整下一局效果；库存0不隐藏。玩家文案固定为聚气“下局以2级开始；行动前先选1项功法”、锻体“下局最大生命X→Y”、明心“下局暴击率X%→Y%”、NONE“本局不服丹；不消耗种子，也没有丹药加成”；credit/hash/revision只进实现合同。选中态用勾、实体边框和“已选择”，不可只靠颜色；触控热区≥56 logical px（目标≥48dp）。

选卡可处置一次轻触但不表达已消费；按钮press无成功重音。matching fresh-live reservation durable edge只允许短封签`at-most-once`，crash窗口可为0..1次，rebuild/reconcile/unmute不补播；pending/uncertain/failure默认音频静默，以中性文字、图形和读屏状态表达。reduce sensory load关闭瓶液循环、墨迹扫屏和数值滚动；静音不损失语义，音画完成不成为Loading gate。

基准720×1280、`canvas_items/expand`，正文列居中且不因宽屏横向拉长；safe-area、360×640、390×844、430×932、100/115/130%字体与长本地化必须成立。可访问顺序固定返回→标题→摘要→四选一radio group→代价说明→主CTA；卡片暴露name、库存、selected/unavailable与position，缺货卡可读但不可激活。Godot 4.7.1 Android TalkBack/iOS VoiceOver bridge或明确缩减支持范围的ADR未签发前保持`BLOCKED-MOBILE-A11Y-ARCHITECTURE`；Control属性不等于移动端读屏已接入。

📌 **UX Flag**：Prep/掌天瓶需在Pre-Production运行`/ux-design`；本文不是完成UX原型。

📌 **Asset Spec**：需为掌天瓶、三种种子/丹药及封签反馈制作不同剪影/材质资产，不得只换色。

## 9. Acceptance Criteria

- **AC-ZB01 `[L/I][BLOCKING]` — GIVEN**132-byte golden、131/133 bytes、schema0/2、逐字段截断、negative、available+reserved>999、合法earned/consumed>999、守恒破坏、reserved sum2、flag2与next ID0，**WHEN**decode→validate→canonical re-encode，**THEN**只接受满足held cap与守恒的canonical bytes，lifetime>999本身不拒绝；future为UPDATE_REQUIRED，其余CORRUPT_BLOCKED，source bytes保留且write/default0。
- **AC-ZB02 `[L/I][BLOCKING]` — GIVEN**durable RESERVED、全部draw前checkpoint OK、call_begin=N及owner-private weights，**WHEN**调用F1，**THEN**成功仅一次public call、call_end=N+1、index按0/1/2映射stable ID；任一fault时candidate publish0并进入release，同run handoff重试额外call0。
- **AC-ZB03 `[L/I][BLOCKING]` — GIVEN**独立seed/call-index→seed-ID golden、8流pre-state，以及流注册/容器顺序扰动和其他流0/100次调用，**WHEN**F1，**THEN**结果等于golden、ZHANGTIAN计数+1、其他7流state/count逐byte不变。
- **AC-ZB04 `[L/I][BLOCKING]` — GIVEN**Victory/Defeat在ticks43199/43200/43201及Abandoned/Technical，**WHEN**生成seed reward，**THEN**Victory=2、Defeat=0/1/1、其余0；任一Defeat路线的seed/Active-minute不得高于Victory envelope。
- **AC-ZB05 `[L/I][BLOCKING]` — GIVEN**available/reserved使held为0/1/998/999、requested0/1/2/3与claim0/1，**WHEN**F2，**THEN**applied按room为0..3、held≤999、守恒成立、cap结果显式且claim exact-once；非法旧档0 mutation。
- **AC-ZB06 `[I][BLOCKING]` — GIVEN**NONE及三种选择切换100次，**WHEN**未确认，**THEN**profile/reservation/RNG写入全0，仅local draft revision按序变化。
- **AC-ZB07 `[I][BLOCKING]` — GIVEN**canonical Prep command的page/press/profile/domain/config/save/content/hash逐字段单轴破坏，**WHEN**validate，**THEN**仅全matching且库存>0或NONE接受；其余在identity/reservation/write/RNG前返回冻结code。
- **AC-ZB08 `[I][BLOCKING]` — GIVEN**seed/NONE、next preparation ID1/MAX与两个同base命令正反到达，**WHEN**reserve，**THEN**唯一胜者分配old next ID并令domain/profile revision各+1；NONE count不变，MAX为ID_EXHAUSTED且旧bytes不变，败者不rebase。
- **AC-ZB09 `[C/I][BLOCKING]` — GIVEN**同request/callback/restart各100次及同identity异hash，**WHEN**reserve/reconcile，**THEN**durable RESERVED/count/receipt最多一次，duplicate返回原receipt、conflict零写；fresh-live audio start0..1且boot/reconcile不补播。
- **AC-ZB10 `[C/I][BLOCKING]` — GIVEN**reserve的temp逐byte、file barrier、replace、directory barrier、两槽write/readback、callback loss、short write/ENOSPC与process kill row manifest，**WHEN**restart，**THEN**只选择完整old或new fact；可证明无durable才FAILED，其余UNCERTAIN，第二identity与Loading均0。
- **AC-ZB11 `[I][BLOCKING]` — GIVEN**UNCERTAIN与matching RESERVED/RELEASED/CONSUMED/NOT_FOUND/conflict/future/corrupt scan，**WHEN**同operation reconcile，**THEN**逐态进入FSM唯一目标；只有RESERVED继续同一handoff，NOT_FOUND保留IDs冻结，其他状态不创建新局。
- **AC-ZB12 `[I][BLOCKING]` — GIVEN**PrepCommitJournal八个canonical checkpoint及每点fail/restart，**WHEN**收敛，**THEN**RESERVATION_DURABLE后按唯一reconcile disposition继续同一run-start或先durable release；第二run/seed/preparation ID、旧page command与战斗movement均0。
- **AC-ZB13 `[I][BLOCKING]` — GIVEN**seed/NONE×Victory/Defeat/Abandoned/Technical×reservation state，**WHEN**resolve，**THEN**V/D/A mandatory consume，Abandoned为零奖励tombstone+consume同事实；Technical仅按sealed compensation release；duplicate exact-noop、UI guess写入0。
- **AC-ZB14 `[C/I][BLOCKING]` — GIVEN**reserve后、Loading中、Active marker前后与sealed outcome前后的process kill，**WHEN**boot recover，**THEN**marker前继续同一handoff或release，marker后无Outcome consume，sealed disposition优先；永不强杀返丹或永久reserved。
- **AC-ZB15 `[L/I][BLOCKING]` — GIVEN**H0=100、长春0..5、B∈{0,0.15}及非法组合，**WHEN**F5，**THEN**无丹为100/103/106/109/112/115、有丹为115/118/121/124/127/130；非法在Active前fail且不热改。
- **AC-ZB16 `[L/I][BLOCKING]` — GIVEN**C0=.05、大衍0..5、B∈{0,.08}与u在C相邻/相等值，**WHEN**F6，**THEN**无丹为.05..10、有丹为.13..18且只有u<C暴击；非法在Active前fail且不热改。
- **AC-ZB17 `[L/I][BLOCKING]` — GIVEN**NONE/聚气丹与matching/mismatched `LEVEL_UP+PREPARATION_CURVE_CREDIT` request、offer fault、duplicate commit，**WHEN**Loading，**THEN**NONE为LV1/xp0/curve-credit0；聚气为LV2/xp0/credit14/remaining16538并在root gate held下完成ordinal1普通规则choice，完成前movement/survival0、失败不发布Active。
- **AC-ZB18 `[I][BLOCKING]` — GIVEN**完整projection golden及identity/revision/hash单轴stale、profile/config热改，**WHEN**bind→Active→Pause→Resume，**THEN**仅全matching projection被消费且当前bank/hash逐byte不变；Zhangtian phase callback与四类contribution均0。
- **AC-ZB19 `[I][BLOCKING]` — GIVEN**CORE_HERB、三seed、cap saturation及row排列/duplicate/unknown，**WHEN**Settlement应用，**THEN**CORE只改Settlement domain，seed只改Zhangtian，合法同类gift+candidate按F2，非法整bundle拒绝。
- **AC-ZB20 `[I][BLOCKING]` — GIVEN**migration_count=0、future schema2与corrupt V1，**WHEN**load，**THEN**migration调用0，分别UPDATE_REQUIRED/CORRUPT_BLOCKED并保留bytes；未来新增V0时必须先提供逐byteV0→V1 golden与kill matrix，空集不得PASS。
- **AC-ZB21 `[UX/A][OPEN-EVIDENCE]` — GIVEN**四个明确safe rect/cutout、字体100/115/130%、中英长文案、DRAFT/selected/empty/reserving/uncertain/releasing/blocked及touch/keyboard/controller/screen-reader，**WHEN**render/navigation，**THEN**P0节点不裁切重叠、touch≥56 logical且目标机≥48dp、focus/reading/live announcement等于状态oracle；保存截图、accessibility tree与input trace。
- **AC-ZB22 `[I][BLOCKING]` — GIVEN**selection/reserve/release/unlock、mute/unmute、detach、rebuild、reconcile与missing asset，**WHEN**app audio disposition，**THEN**每个semantic identity只有一个owner；pending/uncertain静默，fresh-live reserve start0..1，unlock与Save stamp合并且Loading不等待音画。
- **AC-ZB23 `[R/M][OPEN-EVIDENCE]` — GIVEN**签发build/config/workload/device/thermal/storage manifest，**WHEN**执行codec、Loading、reservation crash与100次page rebuild，**THEN**分别报告byte golden、allocation/growth/COW、p50/p95/p99/max、RSS、writer与live page/signal counters；阈值未冻结只判MEASURED/INCONCLUSIVE。
- **AC-ZB24 `[E][OPEN-EVIDENCE]` — GIVEN**预注册目标玩家样本，**WHEN**比较无丹/三丹及重复Prep，**THEN**分别报告first-visible/interactive、choice时长/退出率、全库存条件选择率、缺货P95、10/20局库存斜率与seed/Active-minute；RNG≥1000候选频数单独报告，不代替经济健康。
- **AC-ZB25 `[L/I][BLOCKING]` — GIVEN**合法ledger含`{A=998,R=0,C=1,E=999}`、`{0,0,999,999}`、held999、Victory quantity2、Boss线Defeat quantity1与starter claim0/1，**WHEN**resolve→F2，**THEN**`A'+R'≤999`、`A'+R'+C'=E'`，E/C可超过999但不得int64溢出；历史累计永不使正常结算失活。
- **AC-ZB26 `[C/I][BLOCKING]` — GIVEN**八个Prep checkpoint、candidate draw前/后、每次pre-active offer/refresh/commit及ActiveEntry前后kill/callback loss，**WHEN**restart，**THEN**只从276-byte recovery恢复同一identity/candidate/RNG cursor/choice/loadout；重复字段不等为CONFLICT，第二logical candidate/choice/run均0。
- **AC-ZB27 `[I][BLOCKING]` — GIVEN**`ReservationReconcileDispositionManifestV1`的RESERVED/RELEASED/CONSUMED/NOT_FOUND/CONFLICT/FUTURE/CORRUPT × marker/journal/outcome rows，**WHEN**reconcile，**THEN**每行只有一个target、write count、new-run count与UI state；不得以“继续或release”作为二义expected。
- **AC-ZB28 `[I][BLOCKING]` — GIVEN**`HashPreimageManifestV1`全部hash rows及任一单字段/重复字段翻转，**WHEN**canonical encode/hash，**THEN**每个hash字段恰一tag/zero range/exact length，错误对象tag、missing row、alias backing与外内carrier不等均在write前拒绝。
- **AC-ZB29 `[R/M][OPEN-EVIDENCE]` — GIVEN**签发的exact workload rows、parent hash、markers、warmup、3次独立run、raw sample hash、observer版本与positive control，**WHEN**执行codec-max、reservation/reconcile、NONE/三pill Loading及100-cycle page rebuild，**THEN**结构计数逐行PASS；parent stale或正控无效为INCONCLUSIVE，latency/RSS未冻结只可MEASURED。
- **AC-ZB30 `[E][OPEN-EVIDENCE]` — GIVEN**预注册样本量、置信规则及三丹/NONE/经济阈值，**WHEN**按永久成长层级和全库存条件比较，**THEN**判定CTA→offer/choice/movement时延、退出率、DPS/容错/成型收益、缺货P95、库存斜率与Victory/Defeat seed per Active-minute；只报告或RNG频数不得PASS。

## 10. Open Questions / Evidence Gates

| ID | Gate | Owner | Status |
|---|---|---|---|
| OQ-ZB01 | 聚气丹开局choice是否造成可接受的前置停顿？ | UX/Balance | PROVISIONAL；目标用户试玩 |
| OQ-ZB02 | 等权无pity的缺货P95与三药条件选择率是否健康？ | Economy | PROVISIONAL；RNG频数与玩家行为分开 |
| OQ-ZB03 | reservation wrapper/max slot与codec golden？ | Save/Config | DESIGN CONTRACT REVISED；generated/runtime BLOCKED |
| OQ-ZB04 | ZHANGTIAN_HERB Loading调用与BATTLE_ENDING Outcome join？ | Settlement/RNG/GameRoot | DESIGN CONTRACT REVISED；manifest regen待完成 |
| OQ-ZB05 | Godot 4.7.1 kill/barrier/dual-focus与TalkBack/VoiceOver bridge证据？ | Engine/QA | BLOCKED |
| OQ-ZB06 | 正式Prep UX、Art/Sound assets与真机？ | UX/Art/Audio | BLOCKED |
| OQ-ZB07 | clean-context full review？ | Review team | OPEN |

## 11. Handoff

本文经首次full review与方案A整改后冻结MVP三种种子/丹药、Victory候选×2、Boss线Defeat候选×1、首次正常结算三类starter、held cap999、132-byte持久domain、持久battle/preparation allocator、八checkpoint可恢复handoff、Active marker、Abandoned mandatory consume、pre-active普通SkillDraft、consume/release/technical compensation与下一局投影。它没有证明Save平台durability、聚气丹体验、RNG/经济健康、移动端读屏架构、正式UX/资产或运行时接线。

状态保持`In Review / Re-review Pending`；跨文档传播与静态检查完成后仍应在fresh context运行`/design-review design/gdd/zhangtian-bottle.md --depth full`，不得在本整改会话宣称Approved、implementation-ready或battle_ready。
