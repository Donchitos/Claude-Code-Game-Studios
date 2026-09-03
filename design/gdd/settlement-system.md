# SettlementSystem（结算系统，含BATTLE_RULES终局投影）

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / economy-designer / qa-lead / UX reviewer）
> **Created / Last Updated**: 2026-09-03
> **Implements Pillar**: 诚实复盘、失败有积累、成功可理解；所有收益以durable事实为准
> **Scope**: MVP终局规则投影、奖励/纪录候选、sealed Outcome到多domain after-image、保存/放弃/对账呈现、伤害与承伤复盘；不含排行榜、云端、赛季、装备掉落、复杂历史或社交分享

## 1. Overview

SettlementSystem 是终局结果到局外永久档案的唯一业务映射者，也是结算页面的只读 presenter。为闭合 systems index 中未单列但 GameRoot 已要求的 `BATTLE_RULES` role，本文将其定义为 Settlement 的battle-ending子域：它在战斗中只积累生存/最终等级并在终局安全阶段生成typed reward/record projection；页面层只消费 exposed sealed Outcome、Completion、Save与冻结的mutation bundle，绝不回读已销毁battle Node或猜测胜负。

Settlement构造一次完整 `PersistentProfileEnvelopeV1` after-image，把灵石、残页、种子、核心灵药、纪录、掌天瓶reservation resolution及解锁标记放入同一Save commit。durable success前只显示“待保存”，PONR后结果不明只允许核对；不能因UI动画、callback超时或页面重建提前宣布到账。

## 2. Player Fantasy

每局结束都给玩家一个可信、克制而有用的复盘：我活了多久、击杀了什么、哪套功法真正造成伤害、我为何倒下、两次机缘带来了什么，以及哪些收益已经安全带回洞府。失败不是十分钟努力清零，但主动放弃也不会被包装成奖励路径。

玩家应能从伤害排行和承伤来源理解下一局怎么调整，而不是只看一个夸张总分。成功落印只发生一次；保存异常使用中性、可恢复的语言，不用失败重音施压。再次挑战必回Prep重新做准备，不自动沿用或消耗上一局丹药。

## 3. Detailed Design

### 3.1 双scope owner与BATTLE_RULES row

- `BattleOutcomeRulesV1`是battle-scope required participant，role=`BATTLE_RULES`、`stable_order=11`；`SettlementPresenterV1`是app-scope UI/service，不参与七phase。
- phase row固定：`{participant_id=BATTLE_RULES,role_id=BATTLE_RULES,stable_order=11,allowed_phases={DEFERRED_REMOVAL,POST_DEFERRED_BARRIER},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=SettlementSystem/BattleOutcomeRulesV1,owner_gdd_path=design/gdd/settlement-system.md,phase_row_id=BATTLE_RULES_PHASE_ROW_V1,required=true}`。
- owner contribution固定`LIFECYCLE_INTENT=0,FACT_COMMIT=6,PAUSE_CLOSURE=0,BLOCKING_CHOICE=0`；六行只用于terminal reward staging，不能产生战斗玩法效果。
- BATTLE_RULES拥有RunOutcome的8个field：`survival_ticks,level,reward_fact_count,record_count,reward_fact_ids[],reward_amounts[],record_ids[],record_candidate_values[]`。GameRoot仍唯一拥有`outcome_kind`与seal；Damage/Enemy/Risk等仍拥有各自字段。
- 不拥有Damage/Enemy/Leveling事实、Save介质/reducer、Progression/Zhangtian内部规则、UI输入gate、战斗对象或Audio terminal winner。

### 3.2 Terminal accumulation 与 reward manifest

BATTLE_RULES只从matching published authority与COMMITTED fact/receipt读取：每个完整Active tick在phase7 checked推进`survival_ticks`；最终level从Leveling matching snapshot copy；灵石从reward-eligible committed DEATH provenance聚合；核心灵药沿既有Boss precollection→phase6 REWARD fact；种子候选来自Loading已冻结的Zhangtian seed candidate；残页raw amount来自survival ticks。

`SettlementRewardManifestV1`恰6行，stable IDs/顺序固定：

| ID | Reward kind | Outcome amount | Target |
|---:|---|---|---|
| 1 | `SPIRIT_STONES` | BATTLE_RULES聚合actual | Settlement domain |
| 2 | `CULTIVATION_PAGES` | 0..8 raw；Settlement再按remaining room cap | Progression domain |
| 3 | `SEED_QI` | Victory candidate×2或Boss线Defeat×1，另可含starter×1 | Zhangtian NINGQI |
| 4 | `SEED_IRON` | Victory candidate×2或Boss线Defeat×1，另可含starter×1 | Zhangtian TIELING |
| 5 | `SEED_THUNDER` | Victory candidate×2或Boss线Defeat×1，另可含starter×1 | Zhangtian LEIYUAN |
| 6 | `CORE_HERB` | VICTORY恰1，否则0 | Settlement trophy |

Outcome只encode amount>0的row，按ID升序，count 0..6；`reward_fact_id`在V1即上述stable reward ID，底层fact sequence/provenance由同row的sealed evidence hash绑定，不把运行时sequence冒充reward kind。缺/重/unknown/乱序、negative amount或kind/outcome不合法时不得seal/commit。

`SettlementRecordManifestV1`恰3行：`BEST_SURVIVAL_TICKS=1,BEST_KILLS=2,BEST_LEVEL=3`。仅Victory/Defeat携带三项candidate；Technical/Abandoned count0。candidate必须finite、非负、为精确整数且分别不超过43200、已签发kill cap、40。

### 3.3 Outcome rules

| Outcome | Rewards | Profile counters/records | Reservation |
|---|---|---|---|
| `VICTORY` | stones、raw pages、random candidate×2、CORE_HERB1、可能starter seed gift | eligible/victory、kills、3 records | consume |
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
```

Input的Outcome/Completion/Save必须同nonzero commit ID且已seal/expose；profile/config/manifest/revisions/hash必须matching。Settlement按stable domain ID顺序验证所有规则、构造三个完整next domain及完整next profile，最后一次发布immutable bundle；任何一步失败为0 partial mutation。bundle随Save `PendingOutcomeRecoveryV1` durable stage，重试/reconcile始终复用同bytes/hash，不重新抽种、不重算奖励、不重新比较纪录。

ABANDONED不构造奖励、纪录或教程mutation，但必须构造matching Zhangtian mandatory consume after-image；Save以同一槽transaction提交“零奖励discard/tombstone + reservation CONSUMED”。其他三类走commit。用户放弃任一普通结果时也只丢弃未保存奖励，不能撤销已获得的丹药成本；Save必须在同一discard transaction解析matching consume after-image。same commit同bundle幂等；same ID different bytes/hash为CONFLICT。

### 3.6 Settlement presentation and Save states

页面只消费一个sealed `SettlementPresentationBundleV1={outcome hash,completion hash,mutation hash,save presentation,profile revisions,view generation}`。任一source stale/不完整时保留上一完整帧或显示noninteractive unavailable，禁止新战果+旧奖励公式拼帧。

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

放弃必须二次确认并明确：灵石、残页、种子、纪录、教程不会到账，已获得的丹药成本仍会消费且不返还。commit/tombstone竞态完全投影Save durable precedence；DISCARDED只有在matching reservation也已CONSUMED后才可离开。只有SUCCEEDED/DISCARDED且archive/retire完成后才能离开；“再次挑战”固定进入Prep且初始NONE。

### 3.7 Statistics projection

首屏显示结果、Save状态、奖励、存活时间/击杀/最终等级；其后显示全部非零技能伤害排行、受到伤害来源、0..2次Risk结果和新纪录。前三项可摘要，但“查看全部”必须能看到所有Outcome actual rows；不持久化每局完整伤害表。

damage/source totals只接受sealed finite nonnegative float64；`-0`归+0。排序为raw total DESC→stable ID ASC，不按本地化名或rounded percent。DEFEAT death cause来自Damage stable ID；Victory/Abandoned/Technical不显示死亡原因。UI RNG、battle Node query与权威写入均为0。

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
| Zhangtian | Loading seed candidate、reservation、domain rule | Victory×2/Boss线Defeat×1/starter/consume or compensation after-image |
| Progression | raw page row/current room | capped grant after-image |
| SaveSystem | attempt/result/presentation/durable stage | immutable bundle+full next profile；durability归Save |
| Config/Data | reward/record/stone manifests与actual capacities | validation/hash；不使用schema hard max1536 |
| BattleUI | staged terminal handoff | BattleUI不渲染完整结算；旧input先撤销 |
| Home/Prep UI | navigation target | resolved后才激活，again→Prep |
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
| Survival ticks | `T` | int64 | 0–43200 current | committed Active ticks |
| Remaining cost | `C` | int64 | 0–180 current | unbought node checked sum |
| Unspent pages | `U` | int64 | 0–INT64_MAX | confirmed Progression balance |

**Output Range:** 0..8；ABANDONED强制0，TECHNICAL只用fault前committed ticks。

**Example:** 37620 ticks得raw6；remaining4且余额2时applied2。

### F4 — Seed and core-herb applied amounts

The `settlement_item_rewards` formula is defined as:

`random_quantity = outcome==VICTORY ? 2 : (outcome==DEFEAT AND survival_ticks>=43,200 ? 1 : 0)`

`starter_i = I(outcome in {VICTORY,DEFEAT} AND starter_seed_grant_claimed==0)`

`requested_seed_i = random_quantity × I(candidate=i) + starter_i; applied_seed_i=min(requested_seed_i,999-(available_i+reserved_i)); core_herb = I(outcome==VICTORY)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Random quantity | `Q` | int32 | 0..2 | Victory=2；Defeat按43,200 tick门槛为1；其他0 |
| Candidate | `S` | enum | three seed IDs | Loading frozen result |
| Starter | `F_i` | int32 | 0 or1 | 首次正常Victory/Defeat且claim=0，各类均1 |

**Output Range:** requested seed row each0..3、requested total0..5；逐类实际applied受`available+reserved<=999`饱和；core herb0/1。

**Example:** 首次正常Victory且candidate=SEED_IRON：requested seed amounts `[1,3,1]`，core herb1；若铁灵花held=998则实际为`[1,1,1]`并返回partial-cap disposition。

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
- **If首次Victory随机种与赠礼同类**：该类amount2，其余1，属于同一bundle。
- **If CORE_HERB row出现在非Victory**：bundle invalid，不降为普通种子。
- **If页面重建/reconcile found**：不重播terminal/save/unlock声音。
- **If再次挑战**：archive/retire完成后进入fresh Prep/selected NONE，不直达Loading。

## 6. Dependencies

| Dependency | Contract | Status |
|---|---|---|
| GameRoot | BATTLE_RULES role、Outcome/Completion、save/archive lifecycle | 本文填补缺失owner；需全表传播/full review |
| SaveSystem | PendingOutcome、full profile commit、reconcile/discard | 基础Designed；bundle/136-byte domain/runtime待接 |
| Damage/Enemy/Leveling/Risk | sealed stats/provenance | GDD已设计；actual capacities/replay待证 |
| Progression | F3 cap与domain after-image | Designed；actual Settlement join待证 |
| Zhangtian | F4、reservation resolution、132-byte domain | In Review / Re-review Pending；runtime待证 |
| Config/Data | 6 reward/3 record/stone/participant manifests | 静态传播待完成 |
| BattleUI/Home/Prep | terminal handoff与resolved navigation | 本批次设计；UX/runtime待证 |
| Audio Feedback | terminal/save/unlock one-shot | Designed；正式rows/assets待接 |

## 7. Tuning Knobs

| Knob | Baseline | Classification | Change rule |
|---|---:|---|---|
| reward rows | 6 | FIXED V1 | schema/producer manifest change |
| record rows | 3 | FIXED MVP | 增加需domain migration |
| spirit stone divisor | 4 XP per stone, ceil | PROVISIONAL-ECONOMY-V1 | 无sink前只作积累分数 |
| Victory stone bonus | 100 | PROVISIONAL-ECONOMY-V1 | 与敌人价值/首次通关联调 |
| page milestone/cap | 5400 ticks / 8 | follows Progression | 不复制第二旋钮 |
| seed weights/quantity/starter | 1/1/1；Victory×2、Boss线Defeat×1；首次正常结算each1 | follows Zhangtian `PROVISIONAL-ECONOMY-V3` | 不在Settlement另配 |
| share precision | 0.1% / sum100.0% | UX LOCKED | 改动需排序/舍入golden |
| visible summary skills | top3 + all detail | UX PROVISIONAL | 不得丢其余非零项 |
| Settlement domain max | 136 bytes | FIXED V1 | 改动需migration/capacity重算 |

## 8. Visual / Audio / UI Requirements

页面优先级为：结果标题→Save状态与唯一主CTA→奖励→核心数据→伤害/承伤/Risk详情→resolved导航。奖励在成功前统一加“待保存”，DISCARDED后移除加号和庆祝态。Victory/Defeat/Technical使用完整/断裂/修复中印章加文字，不能只靠颜色；Abandoned明确“主动离开”。

Save状态卡与底部CTA固定，长统计区域可滚动。基准720×1280、`canvas_items/expand`；支持四档portrait/cutout、100/115/130%字体、英文+30%、灰阶/色弱、reduce motion和静音。touch≥56 logical px；reading order先结果与保存，再奖励/统计/CTA。Android TalkBack/iOS VoiceOver bridge或缩减支持范围ADR未签发前保持`BLOCKED-MOBILE-A11Y-ARCHITECTURE`；dual focus与safe-area仍需真机证据。

终局音只由GameRoot/Audio唯一winner播放，Settlement入页不补播。Save durable success将所有奖励合并为一次低强度落印声；pending无循环，uncertain/failed无惩罚重音，reconcile/rebuild不重播。

📌 **UX Flag**：四Outcome×七Save态、统计展开与放弃确认必须另行`/ux-design`。

📌 **Asset Spec**：结果印章、奖励/来源/Risk图标及落印/异常状态需要正式asset spec。

## 9. Acceptance Criteria

- **AC-ST01 `[L/I][BLOCKING]` — GIVEN**BATTLE_RULES manifest/phase/contribution required−1/exact/+1，**WHEN**Config加载，**THEN**只接受stable11、phase6/7、fact cap6与8个Outcome fields完整行。
- **AC-ST02 `[I][BLOCKING]` — GIVEN**四Outcome及producer completeness组合，**WHEN**seal/expose，**THEN**只按§3.3生成允许reward/record/reservation，缺bit时0 page activation。
- **AC-ST03 `[L/I][BLOCKING]` — GIVEN**6 reward与3 record合法/缺/重/乱序/unknown rows，**WHEN**validate，**THEN**只接受stable IDs、actual caps6/3与matching target domain。
- **AC-ST04 `[L/I][BLOCKING]` — GIVEN**eligible XP0/1/2/4/6/160/240/300及ineligible summon，**WHEN**F1，**THEN**输出0/1/1/1/2/40/60/75及0。
- **AC-ST05 `[L/I][BLOCKING]` — GIVEN**Victory/Defeat/Abandoned/Technical与mixed committed/staging deaths，**WHEN**F2，**THEN**Victory加100、Abandoned0、Technical仅committed且全checked。
- **AC-ST06 `[L/I][BLOCKING]` — GIVEN**ticks0/5399/5400/43200与余额room，**WHEN**F3，**THEN**raw0/0/1/8且applied按room cap，Abandoned0。
- **AC-ST07 `[L/I][BLOCKING]` — GIVEN**四Outcome、Defeat ticks43199/43200/43201、seed candidate、starter claim及held room0/1/2/999，**WHEN**F4，**THEN**Victory candidate×2、Boss线Defeat×1、早败/Technical/Abandoned随机seed0，首次正常结算三类starter各1，core与Zhangtian saturation/守恒逐值匹配。
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
- **AC-ST20 `[I][BLOCKING]` — GIVEN**再次挑战/返回/前往研习或掌天瓶，**WHEN**resolved导航，**THEN**archive完成后目标唯一；again进入Prep且selected NONE。
- **AC-ST21 `[UX/A][OPEN-EVIDENCE]` — GIVEN**四Outcome×七Save态、四档portrait/cutout、130%字体/长locale/色弱/静音，**WHEN**render，**THEN**P0状态/CTA不裁切、非颜色可辨、touch≥56px。
- **AC-ST22 `[R/M/E][BLOCKING]` — GIVEN**codec golden、1000经济runs、crash/race、device与allocator harness，**WHEN**签收，**THEN**STATIC/RUNTIME/DEVICE/ECONOMY证据分别通过；单次页面/Save success不得代替。

## 10. Open Questions / Evidence Gates

| ID | Gate | Owner | Status |
|---|---|---|---|
| OQ-ST01 | 灵石divisor4/Victory100在无sink MVP中是否保留？ | Economy/Product | PROVISIONAL；试玩/产品决策 |
| OQ-ST02 | BATTLE_RULES phase6 reward staging与fact ledger actual capacity重生成？ | GameRoot/Config | BLOCKED static propagation/runtime |
| OQ-ST03 | 6 reward/3 record manifest及codec golden？ | Config/Save | BLOCKED |
| OQ-ST04 | 三domain bundle、136-byte domain与slot max？ | Save | BLOCKED runtime/capacity |
| OQ-ST05 | damage/source actual presenter caps与0-allocation排序？ | Owners/Performance | BLOCKED |
| OQ-ST06 | 正式Settlement UX、TalkBack/VoiceOver bridge、assets/audio？ | UX/Engine/Art/Audio | BLOCKED |
| OQ-ST07 | clean-context full review？ | Review team | OPEN |

## 11. Handoff

本文把缺失的BATTLE_RULES role并入Settlement，冻结terminal reward/record owners、6-row reward、3-row record、136-byte持久domain、完整多domain bundle、Save状态投影与复盘公式。所有灵石数值仍`PROVISIONAL-ECONOMY-V1`；GameRoot/Config/Save反向传播、Godot runtime/crash/device与正式UX均未验证。

状态保持`In Review / Re-review Pending`；应在fresh context运行`/design-review design/gdd/settlement-system.md --depth full`，不能在本作者会话称Approved、implementation-ready或battle_ready。
