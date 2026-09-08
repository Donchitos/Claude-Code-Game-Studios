# SettlementSystem（结算系统，含BATTLE_RULES终局投影）

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / economy-designer / qa-lead / UX reviewer）
> **Created / Last Updated**: 2026-09-08 — Zhangtian第七次独立full review后typed detail pagination整改传播
> **Implements Pillar**: 诚实复盘、失败有积累、成功可理解；所有收益以durable事实为准
> **Scope**: MVP终局规则投影、奖励/纪录候选、sealed Outcome到多domain after-image、保存/放弃/对账呈现、伤害与承伤复盘；不含排行榜、云端、赛季、装备掉落、复杂历史或社交分享

## 1. Overview

SettlementSystem 是终局结果到局外永久档案的唯一业务映射者，也是结算页面的只读 presenter。为闭合 systems index 中未单列但 GameRoot 已要求的 `BATTLE_RULES` role，本文将其定义为 Settlement 的battle-ending子域：它在战斗中只积累生存/最终等级并在终局安全阶段生成typed reward/record projection；页面层只消费 exposed sealed Outcome、Completion、Save与冻结的mutation bundle，绝不回读已销毁battle Node或猜测胜负。

Settlement构造一次完整 `PersistentProfileEnvelopeV1` after-image，把灵石、残页、种子、核心灵药、纪录、掌天瓶reservation resolution及解锁标记放入唯一`ReservationUpdateRequestV2(RESOLVE)+ResolveReservationPayloadV3`。Save在同一slot transaction提交reward或tombstone、next profile、reservation终态、marker清除与receipt；MVP不得另发`SaveCommitRequestV1`形成第二次写。durable success前只显示“待保存”，PONR后结果不明只允许核对；不能因UI动画、callback超时或页面重建提前宣布到账。

## 2. Player Fantasy

每局结束都给玩家一个可信、克制而有用的复盘：我活了多久、击杀了什么、哪套功法真正造成伤害、我为何倒下、两次机缘带来了什么，以及哪些收益已经安全带回洞府。失败不是十分钟努力清零，但主动放弃也不会被包装成奖励路径。

玩家应能从伤害排行和承伤来源理解下一局怎么调整，而不是只看一个夸张总分。成功落印只发生一次；保存异常使用中性、可恢复的语言，不用失败重音施压。再次挑战重新评估当前可用种子：有库存才进入Prep，无库存则同一按键明确NONE并直接开局；两路都不自动沿用或消耗上一局丹药。

## 3. Detailed Design

### 3.1 双scope owner与BATTLE_RULES row

- `BattleOutcomeRulesV1`是battle-scope required participant，role=`BATTLE_RULES`、`stable_order=11`；`SettlementPresenterV1`是app-scope UI/service，不参与七phase。
- phase row固定：`{participant_id=BATTLE_RULES,role_id=BATTLE_RULES,stable_order=11,allowed_phases={DEFERRED_REMOVAL,POST_DEFERRED_BARRIER},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=SettlementSystem/BattleOutcomeRulesV1,owner_gdd_path=design/gdd/settlement-system.md,phase_row_id=BATTLE_RULES_PHASE_ROW_V1,required=true}`。
- owner contribution固定`LIFECYCLE_INTENT=0,FACT_COMMIT=6,PAUSE_CLOSURE=0,BLOCKING_CHOICE=0`；六行只用于terminal reward staging，不能产生战斗玩法效果。
- BATTLE_RULES拥有RunOutcome的8个field：`survival_ticks,level,reward_fact_count,record_count,reward_fact_ids[],reward_amounts[],record_ids[],record_candidate_values[]`。GameRoot仍唯一拥有`outcome_kind`与seal；Damage/Enemy/Risk等仍拥有各自字段。
- 不拥有Damage/Enemy/Leveling事实、Save介质/reducer、Progression/Zhangtian内部规则、UI输入gate、战斗对象或Audio terminal winner。

### 3.2 Terminal accumulation 与 reward manifest

BATTLE_RULES只从matching published authority与COMMITTED fact/receipt读取：每个完整Active tick在phase7 checked推进`survival_ticks`；最终level从Leveling matching snapshot copy；灵石从reward-eligible committed DEATH provenance聚合；核心灵药沿既有Boss precollection→phase6 REWARD fact；种子候选来自Loading已冻结的Zhangtian seed candidate；残页raw amount来自survival ticks。tick边界固定为`completed_before_tick`、`executing_tick_ordinal=completed_before_tick+1`、`completed_after_tick`：第43200个执行tick先让Boss due predicate可见，phase7再将survival_ticks从43199推进到43200，因此同tick Victory合法且不得因顺序误判为43199。

`SettlementRewardManifestV1`恰6行，stable IDs/顺序固定：

| ID | Reward kind | Outcome amount | Target |
|---:|---|---|---|
| 1 | `SPIRIT_STONES` | BATTLE_RULES聚合actual | Settlement domain |
| 2 | `CULTIVATION_PAGES` | 0..8 raw；Settlement再按remaining room cap | Progression domain |
| 3 | `SEED_QI` | 只冻结random gross requested：candidate命中时Victory=3、eligible Defeat=1，否则0 | Zhangtian NINGQI |
| 4 | `SEED_IRON` | 只冻结random gross requested：candidate命中时Victory=3、eligible Defeat=1，否则0 | Zhangtian TIELING |
| 5 | `SEED_THUNDER` | 只冻结random gross requested：candidate命中时Victory=3、eligible Defeat=1，否则0 | Zhangtian LEIYUAN |
| 6 | `CORE_HERB` | VICTORY恰1，否则0 | Settlement trophy |

Outcome只encode amount>0的row，按ID升序，count 0..6；seed row只承载本局冻结的random gross requested及candidate provenance，明确不含starter、cap disposition或最终applied amount。`reward_fact_id`在V1即上述stable reward ID，底层fact sequence/provenance由同row的sealed evidence hash绑定，不把运行时sequence冒充reward kind。starter只由matching durable Zhangtian flag在mutation阶段请求一次；缺/重/unknown/乱序、negative amount或kind/outcome不合法时不得seal/commit。

`SettlementRecordManifestV1`恰3行：`BEST_SURVIVAL_TICKS=1,BEST_KILLS=2,BEST_LEVEL=3`。仅Victory/Defeat携带三项candidate；Technical/Abandoned count0。candidate必须finite、非负、为精确整数且分别不超过108000、已签发kill cap、40。108000来自Stage `max_battle_duration_seconds=1800 × 60Hz`，不以Boss入场tick充当整局上限。

### 3.3 Outcome rules

| Outcome | Rewards | Profile counters/records | Reservation |
|---|---|---|---|
| `VICTORY` | Outcome含stones、raw pages、random candidate×3、CORE_HERB1；mutation可按flag另请求starter | eligible/victory、kills、3 records | consume |
| `DEFEAT` | stones、raw pages；`survival_ticks>=43,200`才有random seed | eligible/defeat、kills、3 records | consume |
| `ABANDONED` | 全0 | 全0；不更新教程/纪录 | consume已选丹药，不补偿 |
| `TECHNICAL_ABORT` | fault前committed stones/pages；seed/core/record为0 | 不计eligible run/胜负/纪录；可累计已确认stones/pages | 只按sealed technical compensation |

PreOutcome identity unavailable、未sealed/未expose或producer completeness缺失时不创建Settlement success页、reward plan或Save commit。正常Outcome seal后的cleanup fault只显示completion警告，不能改outcome kind或重算奖励。

### 3.4 Persistent settlement domain

```text
SettlementProfileDomainV1={
  schema_version:i32=1,domain_revision:i64,
  settlement_content_revision:i64,
  unspent_spirit_stones:i64,earned_spirit_stones_total:i64,
  spent_spirit_stones_total:i64,core_herb_count:i64,
  eligible_runs:i64,victories:i64,defeats:i64,total_kills:i64,
  record_count:i32=3,record_ids:i64[3],record_values:i64[3]
}
```

canonical little-endian/no-padding固定136 bytes。空档revision0、所有count/value为0、record IDs固定1/2/3。MVP没有灵石sink，`spent_spirit_stones_total=0`且`unspent=earned`；灵石仅作为积累/未来兼容显示，不接功法、不解锁战力。`eligible_runs=victories+defeats` checked；records分别等于历史合法最大值，CORE_HERB只作战利品计数，不转成种子/丹药。

### 3.5 Immutable settlement input and mutation bundle

```text
SettlementInputBundleV1={
  schema_version:i32=1,outcome:RunOutcomeEnvelopeV1,
  outcome_hash:Hash256,completion:RunCompletionStatusV1,
  save_attempt:SaveCommitAttemptV1,confirmed_profile:PersistentProfileEnvelopeV1,
  expected_profile_revision:i64,config_content_revision:i64,
  reward_manifest_hash:Hash256,record_manifest_hash:Hash256,
  reservation_evidence_hash:Hash256,bundle_hash:Hash256
}

SettlementMutationBundleV1={
  schema_version:i32=1,outcome_commit_id:i64,
  expected_profile_revision:i64,next_profile_revision:i64,
  settlement_before_hash:Hash256,settlement_after_hash:Hash256,
  progression_before_hash:Hash256,progression_after_hash:Hash256,
  zhangtian_before_hash:Hash256,zhangtian_after_hash:Hash256,
  reservation_resolution_hash:Hash256,
  applied_reward_count:i32,applied_reward_rows[6],
  new_record_bits:i32,mutation_bundle_hash:Hash256,
  next_profile:PersistentProfileEnvelopeV1
}

AppliedRewardRowV1={
  reward_id:i32,outcome_requested:i64,starter_requested:i64,
  applied_amount:i64,cap_disposition:i32,
  provenance_hash:Hash256
}
```

`AppliedRewardRowV1` canonical little-endian/no-padding固定64 bytes，按reward ID升序放入固定capacity6的tail，未用row全零。`outcome_requested`逐位等于Outcome对应row（无row则0），对seed即random gross requested；seed starter只允许正常VICTORY/DEFEAT且confirmed Zhangtian flag为`unlocked/claimed=0/0`时各类1，其他情况0；`applied_amount`是consume-before-grant后同时受held room与lifetime room约束的唯一到账真相。`cap_disposition={FULL=1,PARTIAL_HELD=2,PARTIAL_LIFETIME=3,NO_ROOM=4,NOT_APPLICABLE=5,PARTIAL_BOTH=6}`，按封闭优先级计算：requested=0→NOT_APPLICABLE；applied=requested>0→FULL；applied=0<requested→NO_ROOM；0<applied<requested且`held_room<lifetime_room`→PARTIAL_HELD；`lifetime_room<held_room`→PARTIAL_LIFETIME；两者相等→PARTIAL_BOTH。不得由UI从requested反推，也不得把相等tie任意归给某一cap。seed row的`provenance_hash`绑定Outcome candidate row与starter flag before-image；其他reward绑定其sealed fact。

Zhangtian解锁/赠礼flag合法矩阵只有`0/0`与`1/1`：空档locked时三类available/reserved/consumed/earned必须全0；首次正常VICTORY/DEFEAT transaction在同一next profile中写三类starter requested并原子迁移到`1/1`。`0/1`、`1/0`或locked非零ledger整包fail closed，不修补、不猜测。

Input的Outcome/Completion/Save必须同nonzero commit ID且已seal/expose；profile/config/manifest/revisions/hash必须matching。Settlement按stable domain ID顺序验证所有规则、构造三个完整next domain及完整next profile，最后一次发布immutable bundle；任何一步失败为0 partial mutation。bundle与包含其hash、Outcome/Completion hash、264-byte resolution及完整next profile的`ResolveReservationPayloadV3`随Save `PendingOutcomeRecoveryV1` durable stage，重试/reconcile始终复用同一terminal request bytes/hash，不重新抽种、不重算奖励、不重新比较纪录。

ABANDONED不构造奖励、纪录或教程mutation，但必须构造matching Zhangtian mandatory consume after-image；唯一terminal request的`terminal_operation_kind=OUTCOME_DISCARD,terminal_disposition=CONSUMED`，Save以同一槽transaction提交“零奖励discard/tombstone + reservation CONSUMED”。其他正常结果用`OUTCOME_COMMIT/CONSUMED`；技术补偿才可`TECHNICAL_COMPENSATION/RELEASED`。用户放弃任一普通结果时也只丢弃未保存奖励，不能撤销已获得的丹药成本。same commit同bundle幂等；same ID different bytes/hash为CONFLICT。

### 3.6 Settlement presentation and Save states

页面只消费一个sealed `SettlementPresentationBundleV1={outcome_hash,completion_hash,mutation_hash,save_presentation,profile_revision,zhangtian_domain_revision,config_content_revision,config_content_hash,save_state_revision,available_seed_total,view_generation,direct_none_start_slice:DirectNoneStartSliceV2,bundle_hash}`。奖励文案/数量只读matching `AppliedRewardRowV1.applied_amount+cap_disposition`，绝不展示Outcome random requested或自行叠加starter。`DirectNoneStartSliceV2`沿Prep签发的128-byte exact schema；再次挑战available=0时，`SETTLEMENT_DIRECT_NONE` command的source generation、profile/domain/config/save revisions、两flag与hash必须逐位来自同一bundle内该slice，不得临时跨owner拼接。任一source stale/不完整时保留上一完整帧或显示noninteractive unavailable，禁止新战果+旧奖励公式拼帧。

| State | Player meaning | Primary action |
|---|---|---|
| `VALIDATING/PLAN_READY` | 正在核对本局结果；奖励待保存 | 无重复提交 |
| `NOT_STARTED` | 本局待保存 | 保存本局结果 |
| `SAVE_PENDING` | 正在保存 | 无按钮，等待 |
| `SAVE_UNCERTAIN` | 保存结果待确认 | 核对保存结果 |
| `SAVE_FAILED` | 进度尚未写入 | 重试保存 |
| `SAVE_SUCCEEDED` | 已保存/已到账 | 再次挑战；次级返回洞府/前往研习/掌天瓶 |
| `DISCARD_PENDING` | 正在确认放弃 | 继续放弃或核对；不得离开 |
| `DISCARDED` | 本局进度未保存 | 返回洞府；可再挑战 |

放弃必须二次确认并明确：灵石、残页、种子、纪录、教程不会到账，已获得的丹药成本仍会消费且不返还。commit/tombstone竞态完全投影Save durable precedence；DISCARDED只有在matching reservation也已CONSUMED后才可离开。只有SUCCEEDED/DISCARDED且archive/retire完成后才能离开。“再次挑战”先读取同一confirmed profile的available seed total：大于0时进入fresh Prep且初始NONE；等于0时由同一press发`SETTLEMENT_DIRECT_NONE`，经noninteractive PREP创建0页面并共享reservation路径直接开局。后一路视觉CTA与screen-reader accessible name都必须明确为“**不服丹，再次挑战**”，不能只写“再次挑战”让NONE语义隐身。

### 3.7 Statistics projection

首屏显示结果、Save状态、奖励、存活时间/击杀/最终等级；其后显示全部非零技能伤害排行、受到伤害来源、0..2次Risk结果和新纪录。前三项可摘要，但“查看全部”必须能看到所有Outcome actual rows；不持久化每局完整伤害表。

damage/source totals只接受sealed finite nonnegative float64；`-0`归+0。排序为raw total DESC→stable ID ASC，不按本地化名或rounded percent。DEFEAT death cause来自Damage stable ID；Victory/Abandoned/Technical不显示死亡原因。UI RNG、battle Node query与权威写入均为0。

#### 3.7a Typed detail pagination

`SettlementDetailKindV1={SKILL_DAMAGE=1,DAMAGE_TAKEN=2,RISK_RESULT=3,RECORD=4}`是唯一stable kind order；每kind内部继续按`raw_total DESC→stable_id ASC`，RECORD无raw total时使用canonical 0并按stable ID。`SettlementDetailSourceV1={schema_version:i32=1,outcome_commit_id:i64,source_hash:Hash256,row_count:i32,rows:{detail_kind:i32,stable_id:i64,raw_total:f64,localization_key_id:i32,args_hash:Hash256}[]}`在sealed bundle发布时一次冻结。canonical little-endian/no-padding长度为`48+56*row_count`，`source_hash=SHA256("SettlementDetailSourceV1\0" || canonical source with bytes12..43=ZERO)`；row_count与乘加checked，stable ID/locale key必须正，NaN/Inf/negative raw total、重复kind+stable ID或非canonical order整组拒绝。

`SettlementDetailPageViewV1={schema_version:i32=1,screen_generation:i64,layout_generation:i64,page_generation:i64,source_hash:Hash256,page_index:i32,page_count:i32,first_source_index:i32,visible_count:i32=0..6}`固定76 bytes；`page_count=max(1,ceil(row_count/6))`，`first_source_index=page_index*6`，每个source row只映射到唯一`floor(index/6)`。`SettlementPageCommandV1={schema_version:i32=1,screen_generation:i64,layout_generation:i64,page_generation:i64,source_hash:Hash256,direction:i32(PREVIOUS=1,NEXT=2),command_id:i64}`固定72 bytes。所有identity/hash逐位matching且目标页合法时，presenter checked推进page/layout generation并原子发布新snapshot；边界command、stale/duplicate或source hash不等为0 mutation/0 business command。

翻页后initial focus固定落在page status node5013；随后reading order进入本页首个存在的detail slot，再到prev/next。若新页visible_count=0则从status直接到可用navigation。page status使用POLITE live announcement且每个新page generation最多一次；reflow不改变page index，source更新必须创建新screen generation并回page0。prev/next由Input的ACTIVATE_FOCUSED或native accessibility ACTIVATE产生同一`SettlementPageCommandV1`，四个focus方向只移动presenter focus，不伪造page command。

### 3.8 States and transitions

```text
UNBOUND → VALIDATING → PLAN_READY → NOT_STARTED
NOT_STARTED → SAVE_PENDING
SAVE_PENDING → SAVE_SUCCEEDED | SAVE_FAILED | SAVE_UNCERTAIN
SAVE_FAILED → SAVE_PENDING | DISCARD_PENDING
SAVE_UNCERTAIN → SAVE_PENDING(reconcile/commit) | DISCARD_PENDING
DISCARD_PENDING → DISCARD_PENDING | DISCARDED | SAVE_SUCCEEDED
SAVE_SUCCEEDED | DISCARDED → ARCHIVE_PENDING → DONE
```

任何invalid identity/schema/hash/capacity进入`BLOCKED`，不假装空结算。后半状态是Save carrier只读投影，Settlement不复制第二套reducer。

### 3.9 Interactions with other systems

| System | Input | Output / boundary |
|---|---|---|
| GameRoot | terminal precollection、sealed Outcome/Completion、archive handoff | BATTLE_RULES phase row/reward+record fields；GameRoot仍seal kind |
| Damage/Enemy/Leveling/Risk | committed totals/counts/level/results | 只copy到Outcome，不重算事实 |
| Zhangtian | Loading seed candidate、reservation、domain rule | Victory×3/Boss线Defeat×1/starter/consume or compensation after-image |
| Progression | raw page row/current room | capped grant after-image |
| SaveSystem | attempt/result/presentation/durable stage | immutable bundle+full next profile；durability归Save |
| Config/Data | reward/record/stone manifests与actual capacities | validation/hash；不使用schema hard max1536 |
| BattleUI | staged terminal handoff | BattleUI不渲染完整结算；旧input先撤销 |
| Home/Prep UI | navigation target | resolved后才激活；again按available分流Prep/direct NONE |
| Audio Feedback | terminal/save/unlock semantics | terminal不重播；durable success合并一次提示 |

## 4. Formulas

### F1 — Spirit stone value

The `settlement_spirit_stone_value` formula is defined as:

`stone_value = reward_eligible ? ceil(committed_reward_xp / 4) : 0`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Reward XP | `X` | int64 | 0–300 current | matching death provenance的已提交XP价值 |
| Eligibility | `E` | bool | false/true | summon/retire/revive-clear为false |
| Stone value | `V` | int64 | 0–75 current | per death checked result |

**Output Range:** current enemy rows 0..75；Config值/除数改变需重签经济manifest。

**Example:** XP160精英给`ceil(160/4)=40`；XP6普通敌给2；无奖励召唤物给0。

### F2 — Spirit stones per outcome

The `settlement_spirit_stones` formula is defined as:

`raw_stones = Σ stone_value(committed eligible death) + (outcome==VICTORY ? 100 : 0)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Death values | `v_i` | int64[] | each 0–75 current | fact sequence stable order |
| Victory bonus | `B` | int64 | 0 or 100 | normal Victory only |
| Outcome | `K` | enum | four kinds | Abandoned overrides to0；Technical无bonus |

**Output Range:** 0..checked manifest maximum；ABANDONED=0，TECHNICAL仅fault前committed sum。

**Example:** 10只XP2普通敌、1只XP160精英并Victory：`10×1+40+100=150`灵石。

### F3 — Cultivation pages applied

The `settlement_cultivation_pages` formula is defined as:

`raw=min(8,floor(survival_ticks/5400)); room=max(0,remaining_tree_cost-unspent_pages); applied=min(raw,room)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Survival ticks | `T` | int64 | 0–108000 | committed Active ticks；Stage 30分钟技术域 |
| Remaining cost | `C` | int64 | 0–180 current | unbought node checked sum |
| Unspent pages | `U` | int64 | 0–INT64_MAX | confirmed Progression balance |

**Output Range:** 0..8；ABANDONED强制0，TECHNICAL只用fault前committed ticks。

**Example:** 37620 ticks得raw6；remaining4且余额2时applied2。

### F4 — Seed and core-herb applied amounts

The `settlement_item_rewards` formula is defined as:

`random_quantity = outcome==VICTORY ? 3 : (outcome==DEFEAT AND survival_ticks>=43,200 ? 1 : 0)`

`starter_i = I(outcome in {VICTORY,DEFEAT} AND starter_seed_grant_claimed==0)`

`consume_i = I(reservation_disposition==CONSUME AND selected_seed_id==i)`

`available_i^c=available_i; reserved_i^c=reserved_i-consume_i; consumed_i^c=consumed_i+consume_i`

`requested_seed_i = random_quantity × I(candidate=i) + starter_i`

`applied_seed_i=min(requested_seed_i,999-(available_i^c+reserved_i^c),INT64_MAX-earned_i); core_herb = I(outcome==VICTORY)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Random quantity | `Q` | int32 | 0..3 | Victory=3；Defeat按43,200 tick门槛为1；其他0 |
| Candidate | `S` | enum | three seed IDs | Loading frozen result |
| Starter | `F_i` | int32 | 0 or1 | 首次正常Victory/Defeat且claim=0，各类均1 |

**Output Range:** normal Settlement transaction先consume matching reservation，再以post-consume held room与lifetime room发放；requested seed row each0..4、requested total0..6，逐类实际applied显式返回`FULL/PARTIAL_HELD/PARTIAL_LIFETIME/PARTIAL_BOTH/NO_ROOM/NOT_APPLICABLE`之一；core herb0/1。Victory只接受ticks43200..108000，其他outcome接受0..108000；一次性starter不进入Victory/Defeat随机gross seed-per-minute比较。

**Example:** 首次正常Victory且candidate=SEED_IRON：requested seed amounts `[1,4,1]`，core herb1；若铁灵花held=998则实际为`[1,1,1]`并返回partial-cap disposition。

### F5 — Persistent record update

The `settlement_record_update` formula is defined as:

`next_record=max(old_record,candidate); new_record=(eligible && candidate>old_record)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Old record | `O` | int64 | 0–manifest max | durable value |
| Candidate | `C` | int64 | 0–manifest max | sealed exact integer |
| Eligible | `E` | bool | Victory/Defeat=true | Technical/Abandoned=false |

**Output Range:** monotonic int64；tie不是新纪录，ineligible保持old。

**Example:** best kills300、candidate300保持300且不显示新纪录；candidate301更新并置bit。

### F6 — Total kills

The `settlement_total_kills` formula is defined as:

`total_kills = checked_sum(committed_kill_counts[0...count])`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Kill counts | `k_i` | int64[] | each ≥0；count=actual cap | Enemy sealed rows |

**Output Range:** 0..checked configured maximum；overflow使bundle invalid。

**Example:** rows `[120,30,1]`输出151；remote retire与REVIVE_CLEAR不在committed reward kills。

### F7 — Damage share display

The `settlement_damage_share` formula is defined as:

`raw_i=1000×damage_i/Σdamage; tenths_i=floor(raw_i)+largest_remainder_units_i`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Damage | `d_i` | float64[] | finite ≥0 | sealed actual totals |
| Sum | `D` | float64 | finite ≥0 | stable ID order canonical sum |
| Tenths | `p_i` | int32 | 0–1000 | 0.1 percentage points |

**Output Range:** D>0时`Σp_i=1000`；D=0时全0。余数单位按fraction DESC→stable ID ASC分配。

**Example:** 三项各1伤害，floor后333/333/333，最后1单位给stable ID最小项，显示33.4%/33.3%/33.3%。

## 5. Edge Cases

- **If Outcome/Completion/Save commit ID不一致或未expose**：页面noninteractive，0 bundle/0到账文案。
- **If mandatory producer bit缺失**：不补0、不读Node，进入BLOCKED。
- **If reward row缺/重/unknown/乱序或amount<0**：整份bundle拒绝，0 partial domain mutation。
- **If same outcome重放100次**：复用同bundle/hash，最多一个receipt/after-image/成功反馈。
- **If same commit ID换bundle bytes**：CONFLICT且0写入。
- **If Save PONR前失败**：old profile逐位不变，可fresh retry；所有奖励仍“待保存”。
- **If Save PONR后未知**：只reconcile同commit，不能重算或重新抽种；NOT_FOUND仍UNCERTAIN。
- **If commit与discard竞态**：durable先成立者唯一获胜；callback到达顺序不参与。
- **If ABANDONED**：自动走零奖励discard；奖励卡、新纪录、教程mutation为0，但matching reservation mandatory consume与tombstone同槽，丹药不返。
- **If TECHNICAL_ABORT**：非战败标题，只含fault前committed stones/pages与sealed compensation；无seed/core/record/victory bonus。
- **If normal outcome后cleanup fault**：保持Victory/Defeat bytes与奖励不变，另显示completion警告。
- **If total damage为0**：所有占比显示0，不制造第一名。
- **If totals含NaN/Inf/negative**：整组invalid，不隐藏该行后继续。
- **If raw totals并列**：stable ID ASC；本地化名字不改变排序。
- **If纪录tie**：不显示新纪录；只有strict greater更新。
- **If pages余额已覆盖剩余树**：applied0并说明“现有残页已足够”，不显示虚假+0卡。
- **If首次Victory随机种与赠礼同类**：该类amount4，其余1，属于同一bundle。
- **If CORE_HERB row出现在非Victory**：bundle invalid，不降为普通种子。
- **If页面重建/reconcile found**：不重播terminal/save/unlock声音。
- **If再次挑战**：archive/retire完成后重新读取available；大于0进入fresh Prep/selected NONE，等于0走同press `SETTLEMENT_DIRECT_NONE`并创建Prep页面0，不出现空Prep二次确认，也不伪造HOME generation。

## 6. Dependencies

| Dependency | Contract | Status |
|---|---|---|
| GameRoot | BATTLE_RULES role、Outcome/Completion、save/archive lifecycle | 本文填补缺失owner；需全表传播/full review |
| SaveSystem | PendingOutcome、full profile commit、reconcile/discard | 基础Designed；bundle/136-byte domain/runtime待接 |
| Damage/Enemy/Leveling/Risk | sealed stats/provenance | GDD已设计；actual capacities/replay待证 |
| Progression | F3 cap与domain after-image | Designed；actual Settlement join待证 |
| Zhangtian | F4、reservation resolution、132-byte domain | In Review / Re-review Pending；runtime待证 |
| Config/Data | 6 reward/3 record/stone/participant manifests | 静态传播待完成 |
| BattleUI/Home/Prep | terminal handoff与resolved navigation；again按available分流Prep/direct NONE | 本批次设计；UX/runtime待证 |
| Audio Feedback | terminal/save/unlock one-shot | Designed；正式rows/assets待接 |

## 7. Tuning Knobs

| Knob | Baseline | Classification | Change rule |
|---|---:|---|---|
| reward rows | 6 | FIXED V1 | schema/producer manifest change |
| record rows | 3 | FIXED MVP | 增加需domain migration |
| spirit stone divisor | 4 XP per stone, ceil | PROVISIONAL-ECONOMY-V1 | 无sink前只作积累分数 |
| Victory stone bonus | 100 | PROVISIONAL-ECONOMY-V1 | 与敌人价值/首次通关联调 |
| page milestone/cap | 5400 ticks / 8 | follows Progression | 不复制第二旋钮 |
| seed weights/quantity/starter | 1/1/1；Victory×3、Boss线Defeat×1；首次正常结算each1 | follows Zhangtian `PROVISIONAL-ECONOMY-V6` | 仅gross grant-rate由交叉乘法保证；net flow覆盖服丹/NONE、胜率、局长与饱和 |
| share precision | 0.1% / sum100.0% | UX LOCKED | 改动需排序/舍入golden |
| visible summary skills | top3 + all detail | UX PROVISIONAL | 不得丢其余非零项 |
| Settlement domain max | 136 bytes | FIXED V1 | 改动需migration/capacity重算 |

## 8. Visual / Audio / UI Requirements

页面优先级为：结果标题→Save状态与唯一主CTA→奖励→核心数据→伤害/承伤/Risk详情→resolved导航。奖励在成功前统一加“待保存”，DISCARDED后移除加号和庆祝态。Victory/Defeat/Technical使用完整/断裂/修复中印章加文字，不能只靠颜色；Abandoned明确“主动离开”。

Save状态卡与底部CTA固定，长统计区域可滚动。全部非零技能伤害、承伤来源、0..2 Risk结果与3条纪录先按`detail_kind stable order→raw total DESC→stable ID ASC`形成有界只读source，再按固定window6分页；每row跨全部pages恰出现一次，边界页prev/next可读但disabled，禁止截断或top3冒充全部。基准720×1280、`canvas_items/expand`；支持四档portrait/cutout、100/115/130%字体、英文+30%、灰阶/色弱、reduce motion和静音。touch≥56 logical px；reading order先结果与保存，再奖励/统计/CTA。SETTLEMENT是ADR-0001 action-bearing TopState：每个confirmed bundle/layout generation发布固定capacity24、exact bytes6060的完整`AccessibleScreenSnapshotV2`，按ASN06最多23行（含detail page status、6-row window与prev/next），248-byte rows携带logical bounds、visible/clipped及奖励/Save状态typed localization args，unused tail全零；翻页/reflow推进presentation/layout generation，旧callback命令0。架构路径已冻结，Android TalkBack/iOS VoiceOver插件、能力握手、dual focus、safe-area与真机trace仍为`BLOCKED-MOBILE-A11Y-RUNTIME`。

终局音只由GameRoot/Audio唯一winner播放，Settlement入页不补播。Save durable success将所有奖励合并为一次低强度落印声；pending无循环，uncertain/failed无惩罚重音，reconcile/rebuild不重播。

📌 **UX Flag**：四Outcome×七Save态、统计展开与放弃确认必须另行`/ux-design`。

📌 **Asset Spec**：结果印章、奖励/来源/Risk图标及落印/异常状态需要正式asset spec。

## 9. Acceptance Criteria

- **AC-ST01 `[L/I][BLOCKING]` — GIVEN**BATTLE_RULES manifest/phase/contribution required−1/exact/+1，**WHEN**Config加载，**THEN**只接受stable11、phase6/7、fact cap6与8个Outcome fields完整行。
- **AC-ST02 `[I][BLOCKING]` — GIVEN**四Outcome及producer completeness组合，**WHEN**seal/expose，**THEN**只按§3.3生成允许reward/record/reservation，缺bit时0 page activation。
- **AC-ST03 `[L/I][BLOCKING]` — GIVEN**6 reward、6个64-byte applied rows与3 record合法/缺/重/乱序/unknown rows，**WHEN**validate，**THEN**只接受stable IDs、actual caps6/6/3与matching target domain；Outcome seed只含random gross，starter/cap/applied只在mutation row且presentation只读applied。
- **AC-ST04 `[L/I][BLOCKING]` — GIVEN**eligible XP0/1/2/4/6/160/240/300及ineligible summon，**WHEN**F1，**THEN**输出0/1/1/1/2/40/60/75及0。
- **AC-ST05 `[L/I][BLOCKING]` — GIVEN**Victory/Defeat/Abandoned/Technical与mixed committed/staging deaths，**WHEN**F2，**THEN**Victory加100、Abandoned0、Technical仅committed且全checked。
- **AC-ST06 `[L/I][BLOCKING]` — GIVEN**ticks0/5399/5400/43200/108000/108001与余额room，**WHEN**validate→F3，**THEN**合法raw0/0/1/8/8且applied按room cap，108001拒绝，Abandoned0。
- **AC-ST07 `[L/I][BLOCKING]` — GIVEN**四Outcome、ticks0/43199/43200/43201/108000/108001、seed candidate、unlock/claim的`0/0,1/1,0/1,1/0`及locked非零ledger、matching seed reservation、held room0/1/2/999与earned邻近INT64_MAX，**WHEN**validate→F4，**THEN**Victory在43200前拒绝且合法时Outcome random candidate×3，Boss线Defeat×1、早败/Technical/Abandoned random0；mandatory consume先于grant room计算，只有合法0/0的首次正常结算在mutation三类starter各1并原子变1/1，非法flag/ledger与108001整包拒绝，held/lifetime saturation与守恒逐值匹配；starter不计入随机速率cohort。
- **AC-ST08 `[L/I][BLOCKING]` — GIVEN**old/candidate低/等/高与eligible，**WHEN**F5，**THEN**strict greater才更新/new bit，Technical/Abandoned保持old。
- **AC-ST09 `[L/I][BLOCKING]` — GIVEN**kill rows0/actual/+1与overflow，**WHEN**F6，**THEN**actual checked sum，+1 upstream拒绝，overflow 0 bundle。
- **AC-ST10 `[L][BLOCKING]` — GIVEN**damage0、[1,1,1]、ties/NaN/Inf/negative，**WHEN**F7，**THEN**0或总计100.0%、tie stable，非法整组拒绝。
- **AC-ST11 `[I][BLOCKING]` — GIVEN**Outcome/Completion/Save/profile/config/hash任一stale，**WHEN**capture，**THEN**保留上一完整帧或unavailable，0 mixed-revision bundle。
- **AC-ST12 `[L/I][BLOCKING]` — GIVEN**三个domain before、所有reward、ABANDONED/用户discard与matching reservation，**WHEN**构建bundle/tombstone，**THEN**commit发布完整next profile；discard奖励/纪录0但mandatory consume after-image与tombstone同一immutable transaction，失败0 partial。
- **AC-ST13 `[I][BLOCKING]` — GIVEN**同commit submit/callback/restart100次，**WHEN**Save处理，**THEN**最多1 after-image/receipt/archive/反馈；异bundle冲突。
- **AC-ST14 `[C/I][BLOCKING]` — GIVEN**temp/replace/mirror/readback fault matrix，**WHEN**commit，**THEN**PONR前FAILED旧档不变，PONR后UNCERTAIN且奖励不标到账。
- **AC-ST15 `[I][BLOCKING]` — GIVEN**commit/tombstone四种先后与callback乱序，**WHEN**reducer，**THEN**durable first fact唯一决定SUCCEEDED/DISCARDED。
- **AC-ST16 `[I][BLOCKING]` — GIVEN**正常sealed outcome+cleanup fault，**WHEN**render，**THEN**结果/reward bytes不变，只显示独立completion warning。
- **AC-ST17 `[I][BLOCKING]` — GIVEN**all Save states，**WHEN**CTA点击/双击，**THEN**逐态唯一主行为、physical writer≤1、pending不能重复submit。
- **AC-ST18 `[I][BLOCKING]` — GIVEN**SUCCEEDED/DISCARDED archive retire任意bit后crash，**WHEN**restart，**THEN**从首个未完成bit继续且resolved前新局0。
- **AC-ST19 `[I][BLOCKING]` — GIVEN**sealed stats与已销毁battle tree，**WHEN**Settlement展示，**THEN**Node读取0、排序/amount/death cause逐值等于Outcome。
- **AC-ST20 `[I][A][BLOCKING]` — GIVEN**再次挑战/返回/前往研习或掌天瓶、available=0/>0、两flag合法/非法组合及`DirectNoneStartSliceV2`任一字段/hash单轴stale，**WHEN**resolved导航，**THEN**archive完成后目标唯一；again在>0时进入Prep且selected NONE，在0时仅从同一confirmed Settlement bundle内128-byte slice发一次`SETTLEMENT_DIRECT_NONE`并创建Prep页面0，视觉/读屏名同为“不服丹，再次挑战”；伪HOME source、非法flag、跨owner拼接或旧Settlement generation为0 command。
- **AC-ST21 `[UX/A][OPEN-EVIDENCE]` — GIVEN**四Outcome×七Save态、四档portrait/cutout、130%字体/长locale/色弱/静音，**WHEN**render，**THEN**P0状态/CTA不裁切、非颜色可辨、touch≥56px。
- **AC-ST22 `[R/M/E][BLOCKING]` — GIVEN**codec golden、1000经济runs、crash/race、device与allocator harness，**WHEN**签收，**THEN**STATIC/RUNTIME/DEVICE/ECONOMY证据分别通过；单次页面/Save success不得代替。
- **AC-ST23 `[I/A][BLOCKING]` — GIVEN**`SettlementDetailSourceV1`含0/1/6/7/12/13条跨四kind的稳定rows、34-row accessibility state manifest、page command的matching/stale/duplicate/hash mismatch与PREVIOUS/NEXT边界组合，**WHEN**生成并翻阅detail pages，**THEN**page_count分别为1/1/1/2/2/3且每个source row按kind→raw total DESC→stable ID恰出现一次；每次合法翻页只递增page/layout generation、focus落5013并最多一次POLITE announcement，边界/stale/duplicate/hash mismatch为0 mutation。Input ACTIVATE与native ACTIVATE产生同一typed page command，四个focus方向只移动focus；source更新新建screen generation并回page0，任何截断/top-N/重复/漏row或运行时扩容均失败。

## 10. Open Questions / Evidence Gates

| ID | Gate | Owner | Status |
|---|---|---|---|
| OQ-ST01 | 灵石divisor4/Victory100在无sink MVP中是否保留？ | Economy/Product | PROVISIONAL；试玩/产品决策 |
| OQ-ST02 | BATTLE_RULES phase6 reward staging与fact ledger actual capacity重生成？ | GameRoot/Config | BLOCKED static propagation/runtime |
| OQ-ST03 | 6 reward/3 record manifest及codec golden？ | Config/Save | BLOCKED |
| OQ-ST04 | 三domain bundle、136-byte domain与slot max？ | Save | BLOCKED runtime/capacity |
| OQ-ST05 | damage/source actual presenter caps与0-allocation排序？ | Owners/Performance | BLOCKED |
| OQ-ST06 | 正式Settlement UX、TalkBack/VoiceOver bridge、assets/audio？ | UX/Engine/Art/Audio | ADR-0001路径已冻结；UX/assets/runtime/device BLOCKED |
| OQ-ST07 | clean-context full review？ | Review team | OPEN |

## 11. Handoff

本文把缺失的BATTLE_RULES role并入Settlement，冻结terminal reward/record owners、Outcome random gross与64-byte applied row的单一真相、6-row reward、3-row record、Victory 43200..108000与其他outcome 0..108000输入域、consume-before-grant/lifetime饱和、Victory随机种×3、136-byte持久domain、完整multi-domain bundle、Save状态投影与带128-byte direct-NONE slice的再次挑战。所有灵石数值仍`PROVISIONAL-ECONOMY-V1`；GameRoot/Config/Save反向传播、Godot runtime/crash/device与正式UX均未验证。

状态保持`In Review / Re-review Pending`；应在fresh context运行`/design-review design/gdd/settlement-system.md --depth full`，不能在本作者会话称Approved、implementation-ready或battle_ready。
