# Audio Feedback（战斗音频反馈）

> **Status**: In Review / Re-review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / qa-lead / audio-director / sound-designer）
> **Created / Last Updated**: 2026-09-08 — Zhangtian第七次full review后create/result/receipt ABI整改传播
> **Implements Pillar**: 低打扰、可读、克制的仙侠战斗反馈；关键生存与危险事件始终优先
> **Scope**: MVP战斗SFX、UI反馈、优先级/并发/聚合/duck/降级与语义handoff；不含最终音乐创作、配音或资产生产

## 1. Overview

Audio Feedback 是战斗表现层唯一的音频调度 owner。它把 matching committed fact、receipt、published authority edge 与 GameRoot winner 转换为确定性的语义声音处置，负责 bus routing、聚合、优先级、保留声道、抢占、duck、静音与缺资产降级；它不创造玩法事件，也不拥有 HP、伤害、敌人状态、选择、pause、terminal 或 Outcome。

系统的目标不是让每次命中都更响，而是在303个敌人、400个攻击对象的压力下，仍让玩家首先听见 Boss/Elite 即将生效的危险、自己的生死与替身符，其次才是构筑、命中和奖励。普通反馈应“轻而密但不成噪声”；手机扬声器、单声道或完全静音时，所有关键玩法仍由视觉/文字/形状独立成立。

## 2. Player Fantasy

玩家听到的是克制、近身、带物性的仙侠战斗：纸符裂响、玉石和薄金属的清脆瞬态、木机括、鳞片摩擦、气息与灵力扰动，而不是老虎机亮音、持续重鼓或预告片式低频轰鸣。

危险声要在出手前帮助判断而不是在受伤后惩罚。Boss与Elite各有清楚的动作词汇；替身符触发是一次明确的“保命成功”，但UNSAFE复活保留不安尾音，不谎称安全或无敌。升级、宝匣和进化有层级，但不会盖过生存信息。玩家关闭声音后不失去操作公平性。

## 3. Detailed Design

### 3.1 Owner、驱动与边界

- AudioFeedback不是GameRoot七phase participant，四类gameplay contribution均为0；不定义gameplay `_process/_physics_process`。
- Active sealed publish后，GameRoot显式调用`present_audio_tick(1/60,bundle)`；Paused/Resume/critical由唯一ALWAYS control pump调用typed presentation advance。音频时钟不得推进玩法tick。
- 唯一引擎写入是预建AudioStreamPlayer状态、bus gain、固定queue/voice/duck状态、reader cursor/ACK与diagnostic。`AUDIO_APP`依`AppServiceTopologyManifestV1`可持有persistent app root预建的app-scope `AudioStreamPlayer`，但不得持有battle Node/RID/Callable或可变battle bank引用；其余app service仍禁止持有Node/RID/Callable。禁止写HP/XP/cooldown/FSM/pause/terminal/fact/Pool/Grid/Outcome。
- 不读Node/FSM、raw intent、query hit、理论target或未publish bank；`play()`被调用不等于语义已合法。
- MOVE start/loop只从连续matching Player frame的`did_translate`边沿派生，不进入gameplay event ledger；stop/turn/edge-blocked默认静默。

### 3.2 Typed source bundle 与事件行

GameRoot在同一sealed capture发布：

```text
AudioFrameBundleV1={schema_version=1,battle_instance_id,config_snapshot_id,
capture_tick,bundle_generation,source_revision_vector,presentation_winner,
player_frame,player_transient_view,player_critical_view,battle_audio_bank,
top_state,pause_reason,terminal_commit_id,valid}
```

各source revision无需数值相等，但battle/config/source identity/revision/generation必须逐项matching。非Player事件建议使用双bank：

```text
BattleAudioEventBankV1={schema_version=1,battle_instance_id,config_snapshot_id,
bank_id,capture_tick,source_revision_vector,row_count,capacity,
published_event_sequence,view_generation,required_ack_mask=0b1,acked_mask,rows,valid}

AudioSemanticEventV1={event_sequence,source_owner_id,source_entity_id,
source_borrow_id,source_generation,source_fact_sequence,
source_authority_revision,commit_tick,event_code,has_position,world_position,
magnitude,variant_code,presentation_winner}
```

app-scope语义另走`AppAudioSemanticEventV2={schema_version:i32=2,event_kind:i32,authority_owner_id:i32,producer_id:i32,operation_id:i64,profile_revision:i64,domain_revision:i64,edge_sequence:i64,stale_presentation_generation:i64,identity_payload_length:i32,identity_payload_hash:Hash256,semantic_key_hash:Hash256,coalesce_key_hash:Hash256,valid:i32}`，不伪造battle identity。`event_kind={PILL_SELECTION_CHANGED=1,PREP_RESERVATION_DURABLE=2,PREP_RESERVATION_RELEASED=3,SAVE_DURABLE_STAMP=4}`；不存在独立`ZHANGTIAN_UNLOCKED` event。`stale_presentation_generation`只用于拒绝旧reader，禁止进入dedupe key。MVP identity union固定：selection=`{page_generation,draft_revision,selected_seed_id}`；reservation/release=`{reservation_id,preparation_id,profile_revision,zhangtian_domain_revision,durable_receipt_id,durable_receipt_hash,state}`，其中reservation/preparation/state来自sealed `PrepareRunAttemptViewV1`；首次reserve的operation/revision/receipt逐位来自matching 204-byte `ReservationCreateResultV3`，terminal release只来自matching 160-byte `TerminalRunResultV2`且`terminal_disposition=RELEASED`。CONSUMED result产生0 `PREP_RESERVATION_RELEASED`。两者都必须能重建Save签发的120-byte `ReservationReceiptV1`且`durable_receipt_id=request_id`。view只能复制result，不能合成receipt或跨request拼接。Save stamp逐字段复制matching `TerminalRunResultV2`或`ProfileDomainMutationResultV2`后由Save签发的124-byte `SaveDurableStampFactV1={operation_kind,operation_id,attempt_generation,request_id,profile_revision,zhangtian_domain_revision,zhangtian_unlock_transition,durable_receipt_id,durable_receipt_hash,fact_hash}`，其中transition只能0/1。`semantic_key_hash=SHA256_V1(event_kind||authority_owner_id||canonical identity payload)`，同key重复只处置一次、同key异payload先fault。

producer唯一：`PILL_SELECTION_CHANGED→PrepDraftAudioAdapter`，`PREP_RESERVATION_DURABLE/RELEASED→SaveReservationAudioAdapter`，`SAVE_DURABLE_STAMP→SaveResolutionAudioAdapter`。SaveReservation只消费fresh-live `ReservationCreateResultV3`或`TerminalRunResultV2(RELEASED)`；CONSUMED、ADVANCE/UPDATE/MARK_ACTIVE/RETIRE及FAILED/UNCERTAIN结果的返还event count=0。SaveResolution只消费fresh-live `SaveDurableStampFactV1`，且stamp逐字段来自matching typed result。locked→unlocked作为stamp payload内的modifier bit选择“落印+解锁”单voice，不再异步join第二事件。`coalesce_key_hash=SHA256_V1("SaveDurableStampCoalesceV2\0"||operation_kind_le32||operation_id_le64||attempt_generation_le64||request_id_le64||durable_receipt_id_le64||durable_receipt_hash)`，其他event该字段为ZERO32。boot scan、reconcile FOUND与duplicate callback没有fresh-live fact，event count=0。资源存在、未静音、无kill/callback-loss的fresh-live durable create或RELEASED必须各启动恰1 voice；只有enqueue/voice边界kill允许0..1，missing asset/mute固定0并产生相应diagnostic/fallback。

总处置固定：普通stamp(bit0)播放一次generic落印；首次解锁stamp(bit1)播放一次解锁变体；同key同payloadduplicate为OK_NOOP；同key异payload为CONFLICT；只有unlock投影而无matching durable stamp时event count=0并记diagnostic；不存在stamp-first/unlock-first等待、wallclock timeout或跨帧join状态。UI rebuild、reconcile结果重投影、取消静音、重新进入页面与boot历史scan均只更新reader cursor，重播0；进程在首次live enqueue/voice前后被kill仍只承诺0..1次，不承诺跨崩溃exactly-once。

- Producer只发布事实语义，不指定stream、bus、priority或duck；这些由`AudioCueProfileV1`映射。
- canonical row order=`commit_tick ASC → source_owner_stable_order ASC → event_sequence ASC`。
- 通用bank不重复收Player transient/critical事件。除Player外的producer rows、per-capture maxima与ACK尚未冻结，保持`BLOCKED-AUDIO-EVENT-ABI/CAPACITY`。

### 3.3 Player required consumer 与ACK

Audio consumer固定为`PLAYER_AUDIO,stable_order=3,ack_bit=0b100`，直接消费Player transient cap1与critical ledger cap2：

- 读取前必须join matching `PlayerPresentationFrameV1 + batch_authority_revision + presentation_winner`。
- transient DAMAGE完成确定性`STARTED / MERGED / EXPLICITLY_DROPPED / AUTHORIZED_SILENT_FALLBACK`处置即可ACK，不能等clip结束，否则cap1阻塞后续publish；仅enqueue不可ACK。
- critical REVIVE/DEATH固定`UNSEEN→BOUND→STARTED→COMPLETED_OR_APPROVED_FALLBACK→ACKED`。必须one-shot完成或签发fallback完成后才ACK。
- master/system mute属于用户授权静音：仍按合法处置推进ACK，不能卡ledger；缺P0资产不等于mute。
- duplicate ACK为OK_NOOP；wrong identity/revision/sequence、unknown bit、未join winner均fault。已ACK不因pause/rebuild/重入重播；未ACK只重绑同identity。
- `VICTORY+lethal`即使统计fact含DAMAGE/DEATH，也必须抑制HIT/DEATH/REVIVE/DEFEAT/pause声音，只播sealed VICTORY。

### 3.4 唯一语义owner表

| Semantic | Sole source | 禁止重复来源 |
|---|---|---|
| Player damage/crit/shield/heal | Damage committed receipt + Player event projection | raw hit、Projectile、Weapon |
| Player revive/death | Player critical ledger + winner | Damage death guess、HP值 |
| Weapon cast/release | Weapon committed execution plan或Projectile committed spawn（二者需Config选唯一row） | query due、cooldown ready |
| Projectile travel/near-miss/expire | Projectile committed lifecycle | damage hit重音 |
| Enemy hit/death | Damage applied receipt / Enemy committed DEATH | raw contribution、retire、REVIVE_CLEAR |
| Drop pickup/level crossing | Drop PICKUP / Leveling committed crossing | magnet target、visual tween |
| Choice select/upgrade/evolution | SkillDraft matching commit revision | press、offer open、Leveling重复重音 |
| Risk choice / Elite arrival | Risk committed choice / actual Elite publish | button press、spawn request |
| Boss/Elite telegraph/release | matching action generation/cue sequence | animation callback |
| Terminal | GameRoot sealed `terminal_commit_id` | Boss HP、UI文案、death fact |
| Pill selection changed | `PrepDraftAudioAdapter`发布matching draft revision edge | 卡片pressed/focus/重复tap、Home |
| Prep reservation durable/released | `SaveReservationAudioAdapter`发布首次matching durable receipt edge | Zhangtian、pending、callback次数、reconcile重投影 |
| Save durable stamp / Zhangtian first unlock | `SaveResolutionAudioAdapter`唯一发布`SAVE_DURABLE_STAMP`；confirmed `locked→unlocked`只作同payload modifier bit | 独立unlock event、Home/Prep页面出现、Settlement第二voice、unmute、rebuild |

Weapon-vs-Projectile cast、Damage-vs-Enemy death、Leveling-vs-SkillDraft突破的actual唯一owner row尚需双方签发；签发前不能实现对应成功音。

### 3.5 全局priority与保护lane

Canonical priority enum：

| Value | Class | Examples |
|---:|---|---|
| 7 | `TERMINAL_FAULT` | FATAL、sealed victory/defeat、input-safe fault |
| 6 | `PLAYER_LIFE` | revive、death |
| 5 | `BOSS_IMMINENT` | Boss即将生效招式 |
| 4 | `ELITE_IMMINENT` | Elite/自爆即将生效危险 |
| 3 | `PLAYER_STATUS` | actual damage、shield break、low HP、ward end |
| 2 | `CHOICE_PROGRESS` | commit、evolution、treasure、level |
| 1 | `COMBAT` | weapon、hit、kill、pickup |
| 0 | `AMBIENCE_DECOR` | movement、ambient decoration |

- 已开始的Boss/Elite即将生效预警为protected，不被revive、choice或普通hit截断；Player critical使用独立center lane。FATAL/terminal先由winner使已失效combat语义停止，再播terminal，不通过任意遍历顺序抢占。
- 低优先级永不占关键保留lane。相同优先级默认merge或drop-new，避免free-list/arrival order改变结果。
- priority数字表、protected flag、bus、merge class、duck class进入`AudioPriorityManifestV1` canonical hash。

### 3.6 Voice topology、准入与steal

结构性关键容量为`Boss1+Elite4+PlayerLife/Terminal1=6`。推荐MVP预建基线为22 voices，状态为`PROVISIONAL-AUDIO-CAPACITY`：

| Lane | Voices | Node kind | Rule |
|---|---:|---|---|
| critical/danger | 6 | 5 spatial + 1 centered | 保留；低级不可占 |
| combat spatial | 8 | spatial | 按8方向扇区聚合 |
| UI/reward | 4 | centered | choice/progression/pickup |
| music | 2 | centered streaming | current+incoming crossfade |
| ambience | 2 | centered/spatial profile | bed+Boss/fog layer |

`total=6+8+4+2+2=22`。若一个危险identity需要telegraph与release同时保留，critical需求变为`2*(1+4)+1=11`，必须先升级manifest。

准入顺序：same-key merge → lane free slot → higher-priority deterministic steal → drop-new。victim为最小tuple`{priority ASC,audibility_bucket ASC,start_event_sequence ASC,slot_id ASC}`，仅`new.priority>victim.priority`可偷取；protected不可成为低级victim。每次处置写telemetry与ACK状态。

22只是voice node基线，不是event bank容量。`H_audio=checked_sum(H_damage,H_enemy_action,H_projectile,H_drop,H_leveling,H_skill,H_risk,H_boss,H_elite,H_terminal)`；各H由owner声明每sealed capture最大rows并消除包含关系。当前不可用303/400/606/22填默认。

### 3.7 聚合、variant与空间

- Player同tick多次受击按actual HP loss每tick最多1声；强度按max-HP band，不按raw hit数。
- Enemy先按target committed aggregate，再把普通impact/death/near-miss按8方向扇区与event class压缩；Boss/Elite identity危险不并入普通扇区。
- 4 Elite同类cue可按behavior/action聚合，但保留最高危险、动作种类与Risk语义。引灵大量拾取保留1个主反馈；REVIVE_CLEAR不逐敌播放。
- merge key=`{event_code,variant_class,spatial_sector,source_risk_class}`。Player critical、terminal、choice commit、不同Elite action或Boss identity互不merge。
- impact窗口建议6 Active ticks，death/pickup 12，fog提醒至少180 ticks，均`PROVISIONAL-AUDIO-TUNING`。Paused不推进窗口，resume不补播suppressed gameplay队列。
- variant不用全局/墙钟随机：`variant_index=minimum_event_sequence mod variant_count`。若未来需要随机pitch/variant，必须新增Audio RNG stream与固定call table。
- stereo pan/2D position只辅助；mono downmix与手机扬声器必须仍能按timbre/rhythm识别危险。

### 3.8 Bus树与duck

预建10-bus最小树（包含父级Master与SFX）：

```text
Master
├─ Music
├─ Ambience
└─ SFX
   ├─ Critical
   ├─ Hostile
   ├─ Player
   ├─ Friendly
   ├─ World
   └─ UI
```

用户设置只暴露Master/Music/SFX/UI。Loading缓存并验证bus name/index/parent/effect hash；缺bus不允许Godot静默回退Master。运行中不增删bus/effect。

Duck request取当前最强（最负dB），不累加。初始建议：hostile danger令Friendly/World `-4..-6dB`、Ambience `-3dB`；Player生命事件令Music/Ambience/Friendly/World `-4..-8dB`但不压Hostile；blocking choice在真实Paused后Music `-3dB`、Ambience/World `-6dB`。attack 40..100ms、release 180..500ms均为provisional，最终按Sound Bible/真机mix签发。

### 3.9 事件声音语义

- Boss：低频必须叠700Hz–4kHz可由手机扬声器读取的鳞/牙瞬态。扑咬=收颈鳞擦+獠牙扣；扇毒=毒腺湿压+喷吐；环弹=盘身摩擦+一次八向复合刻度；fog只首次侵入及≥180tick提醒，不逐tick蜂鸣。
- Elite：蜈蚣三连用三段甲节棘轮；鬼修blink用落点逆吸，魂针三针成簇。召唤只在actual children publish后成功；0-child只一次逸散。
- Player：damage按实际HP损失聚合；partial/full shield与HP伤害不同。低血用克制心跳/灵力紊乱，不持续重鼓；revive一次纸符裂响+显形，无持续shield loop；UNSAFE带不稳定尾音。
- Progression：choice open只轻提示；press无成功重音；matching commit一次。evolution强于普通upgrade；terminal存在时升级/宝匣重音为0。
- Combat/Drop：普通击杀轻而密并聚合；Elite/Boss命中更重；Drop commit前无获得重音。remote retire、REVIVE_CLEAR、DROP_EXPIRED、0奖励Boss summon均无奖励/击杀音。

### 3.10 Pause、terminal、fallback与teardown

- Pause后不产生新gameplay cue；movement loop停止，resume只有fresh `did_translate` edge重启。UI/choice音可由control pump播放。
- Danger voice的pause/continue策略与Player critical paused advance必须在Godot 4.7.1目标build验证；不能假定PAUSABLE host会使AudioStreamPlayer按期继续。验证前`BLOCKED-GODOT-RUNTIME`。
- Terminal先应用winner并清空失效pending/voice，再按`terminal_commit_id`exact-once播放。normal seal后的cleanup fault不重播或改winner音。
- app-scope四类事件按§3.2 live-edge identity去重。正常未静音、资产或授权fallback可用且callback未被process-kill截断时，selection/reservation durable/release/first unlock各matching edge必须恰播放1次；只有process-kill窗口允许0..1次。reconcile/rebuild/unmute均不得补播，consumed terminal不得播放release cue。
- 资产降级：app selection=P3，missing→`SILENT_DROPPED`；reservation/release与Save-stamp/unlock=P2，优先使用同family预载generic seal/unseal/stamp，仍缺失时`AUTHORIZED_SILENT_FALLBACK`并依赖可见文字/状态，不阻断Loading。battle P2/P3 missing→`SILENT_DROPPED`；battle P1→同family generic fallback，否则只有签发非音频P0 ready才可authorized silence；Player critical/terminal至少要有预载generic critical mapping，否则load fail。不能用别的成功音冒充。
- 设备静音/无输出不是资产失败；所有关键语义仍由BattleUI/VFX P0成立，并按授权静音路径ACK。
- teardown先invalid generation/cursor与撤callback writer，再stop battle voices/释放duck owner并detach；迟到finished只记suppressed diagnostic。app-scope music若保留必须独立identity，不持旧battle引用。

## 4. Formulas

### F1 — Critical voice capacity

The `audio_critical_voice_capacity` formula is defined as:

`Ccrit = boss_cap + elite_cap + player_life_or_terminal_cap = 1 + 4 + 1 = 6`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Boss identities | `B` | int32 | fixed 1 | 同刻Boss危险身份 |
| Elite identities | `E` | int32 | fixed 4 | 同刻Elite危险身份 |
| Player/terminal center lane | `P` | int32 | fixed 1 | winner先使互斥语义失效 |

**Output Range:** exact 6；required−1 load失败，required成功。  
**Example:** 1 Boss+4 Elite telegraph+1 revive可保留6声；terminal先终止失效danger再使用center lane。

### F2 — Total provisional voice nodes

The `audio_voice_node_baseline` formula is defined as:

`V = critical(6) + combat(8) + ui_reward(4) + music(2) + ambience(2) = 22`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Critical voices | `Vc` | int32 | fixed 6 | F1关键保留lane |
| Combat voices | `Vb` | int32 | provisional 8 | 八方向普通战斗聚合 |
| UI/reward voices | `Vu` | int32 | provisional 4 | choice/progression/drop |
| Music voices | `Vm` | int32 | provisional 2 | current+incoming crossfade |
| Ambience voices | `Va` | int32 | provisional 2 | bed+Boss/fog layer |

**Output Range:** provisional exact 22；clip overlap/min-spec证据前不是production capacity。  
**Example:** 5 spatial danger+8 spatial combat+9 centered/bed nodes=22。

### F3 — Event bank capacity

The `audio_event_bank_capacity` formula is defined as:

`H_audio=checked_sum(H_damage,H_enemy_action,H_projectile,H_drop,H_leveling,H_skill,H_risk,H_boss,H_elite,H_terminal)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Owner row maxima | `H_i` | int64 | `[0,schema_max]` | 每owner同一sealed capture最大audio rows，且声明包含关系 |
| Schema maximum | `Hmax` | int64 | `>0` | Config冻结event bank hard cap |

**Output Range:** `[0,schema_max]`且checked；当前owners未签全，结果`BLOCKED`。  
**Example:** 不能以22 voices或303 enemies替代H_audio。

### F4 — Deterministic steal

The `audio_voice_victim` formula is defined as:

`victim=argmin{priority,audibility_bucket,start_event_sequence,slot_id}`

`steal_allowed = !protected(victim) && new_priority > victim_priority`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Priority | `p` | int32 | `[0,7]` | AudioPriorityManifest值 |
| Audibility bucket | `a` | int32 | Config封闭非负域 | 稳定可闻性分档，不读实时声压 |
| Start sequence | `s` | int64 | `>=0` | voice开始事件序列 |
| Slot ID | `v` | int32 | `[0,lane_cap-1]` | 预建slot稳定ID |
| Protected | `q` | bool | true/false | critical danger保护位 |

**Output Range:** 一个唯一slot或NONE；同级默认drop-new。  
**Example:** incoming priority4可抢priority1最小tuple，不能抢protected priority5。

### F5 — Merged gain

The `audio_merged_gain_db` formula is defined as:

`gain_db=min(base_gain_db+6,base_gain_db+10*log10(max(1,event_count)))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base gain | `G0` | float64 | finite dB | cue profile基准增益 |
| Event count | `n` | int32 | `[1,owner_cap]` | 同merge group计数 |
| Gain cap | `Gc` | float64 | fixed `+6dB` relative | 聚合最大增益 |

**Output Range:** `[base_gain_db,base_gain_db+6]` dB。  
**Example:** 4 events理论+6.02dB，截为+6dB；100 events仍不超过+6dB。

### F6 — Duck envelope

The `audio_duck_envelope` formula is defined as:

`target_db=min(0,active_request_db_0...active_request_db_n)`  
`u=clamp((presentation_tick-start_tick)/duration_ticks,0,1)`  
`current_db=lerp(start_db,target_db,u)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Duck request | `D_i` | float64 | finite, `<=0dB` | 每个active duck owner请求 |
| Start/target gain | `Ds,Dt` | float64 | finite, `<=0dB` | envelope端点 |
| Presentation tick | `t` | int64 | `>=start_tick` | 非gameplay表现tick |
| Duration | `d` | int64 | `>0` | attack或release ticks |

**Output Range:** 在start与target之间，不做dB累加；最后owner退出后有限release回0。  
**Example:** -3与-6同时存在取-6，而不是-9。

### F7 — Deterministic variant

The `audio_variant_index` formula is defined as:

`variant_index = minimum_event_sequence mod variant_count`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Minimum event sequence | `smin` | int64 | `>=0` | merge group最小稳定序列 |
| Variant count | `N` | int32 | `>=1` | profile预载variant数 |

**Output Range:** `[0,variant_count-1]`；count<=0为invalid manifest。  
**Example:** sequence10、3 variants选择index1。

## 5. Edge Cases

1. **If raw hit/press/target存在但无commit**：成功音为0。
2. **If同event重复100次**：只产生一个disposition；conflict在play/ACK前fault。
3. **If enqueue后节点未start**：不得以STARTED ACK。
4. **If master mute**：走authorized silence并ACK，玩法/视觉不变。
5. **If P0 asset缺失且无签发fallback**：battle load失败，不静默吞critical。
6. **If VICTORY+lethal**：death/revive/hit/pause声为0，VICTORY一次。
7. **If FATAL+VICTORY**：只播technical/fatal winner。
8. **If revive为UNSAFE**：不播安全解决和弦/盾loop，Boss/Elite预警保持可闻。
9. **If 300 REVIVE_CLEAR**：合成一个revive group，逐敌kill/reward声为0。
10. **If pool满且新声低级**：drop-new+telemetry；高优先级不被打断。
11. **If同级pool满**：按merge规则处理，否则drop-new，不依物理顺序steal。
12. **If四Elite同类同tick**：可聚合但保留action kind/highest danger/Risk语义。
13. **If fog持续伤害**：首次进入及≥180tick提醒，非逐tick蜂鸣。
14. **If pause发生**：gameplay窗口/重触发不推进，resume不补播积压。
15. **If revive+pause**：仅GameRoot control pump推进critical并在完成/fallback后ACK。
16. **If audio device切换/后台恢复**：保持generation与处置identity；未验证行为时安全静音/fault，不重播成功。
17. **If mono下左右相消**：该asset不合格，不能靠pan成为唯一危险信息。
18. **If teardown后finished迟到**：0 play/ACK/duck，新局不受影响。

## 6. Dependencies

| System | Contract | Status |
|---|---|---|
| GameRoot | sealed bundle、winner、presenter/control tick、terminal/cleanup | In Review；audio binding待传播 |
| Player | PLAYER_AUDIO bit0b100、transient/critical ACK | Full Re-review Pending；本文冻结consumer端 |
| Damage | committed hit/crit/shield/heal/death semantics | Designed；event bank/merge owner待签 |
| Weapon / Projectile | cast、spawn、travel与hit唯一owner | Designed；存在双响边界待裁决 |
| Enemy / Boss / Elite | death、arrival、telegraph/release/action generation | Mixed review；正式audio rows/maxima待签 |
| Drop / Leveling | pickup、level crossing、MAX | Designed；聚合summary待签 |
| SkillDraft / RiskChoice | choice commit、evolution、risk/arrival | Designed；正式audio rows待签 |
| BattleUI / VFX | 静音等价、非音频P0 readiness | BattleUI Designed；VFX missing |
| Config | priority/bus/asset/voice/event/duck/import manifests | In Review；本文facts待登记 |
| BattleRules / Settlement | sealed terminal与结算音乐handoff | Designed / Full Review Pending；audio asset/runtime handoff BLOCKED |
| Zhangtian / Prep / Save / Home | app-scope selection、reservation durable/release、首次解锁edge | 正常未静音exact-one、process-kill 0..1与consumed=0 release边界已冻结；event bank/assets/runtime BLOCKED |

## 7. Tuning Knobs

| Knob | Initial | Status |
|---|---|---|
| priority enum | 7..0，§3.5 | structural locked |
| critical voices | 6 | structural locked |
| total voices | 22 | provisional capacity |
| merge windows | impact6/death-pickup12/fog180 ticks | provisional |
| merged gain cap | +6dB | provisional mix |
| duck ranges | §3.8 | provisional mix |
| duck attack/release | 40..100 / 180..500ms | provisional mix |
| low-HP enter/reset | 30% / 35% | follows BattleUI provisional |
| user controls | Master/Music/SFX/UI | structural initial |
| variant count/pitch | per asset profile；pitch random off | asset pending |

## 8. Visual & Audio Requirements

- 正式Sound Bible需定义：10-bus layout、每cue family语汇、duration、LUFS/true peak、频谱、mono兼容、import/decode/streaming、fallback、variant与license/source。
- P0 generic critical/terminal/danger fallback必须预载；高级资产缺失不能让声音语义换成错误的成功提示。
- Boss低频必须叠手机可读中频瞬态；Elite动作靠rhythm/timbre区分；危险方向不只靠stereo。
- blocking choice、低血、fog、movement loop必须克制且可关闭；禁止持续满频心跳、逐tick毒雾蜂鸣与每敌死亡独立重音。
- 音频不能成为唯一通道；静音、单声道、听力差异和reduce sensory load均保持BattleUI/VFX验收阈值。

📌 **Asset Spec** — 本文已定义Audio语义与资产族。Sound Bible/Art Bible批准后应运行`/asset-spec system:audio-feedback`，不能直接把placeholder当最终资产。

## 9. UI Requirements

- Settings只暴露Master/Music/SFX/UI，0..100显示值映射到dB的公式归Settings/Audio配置后续冻结；0为mute，不把线性值直接当dB。
- mute、音量与reduce sensory load在下一audio presenter boundary原子应用；不改gameplay或event identity。
- bus缺失、输出设备失效与critical fallback fault只由typed状态驱动安全提示，不弹重复toast。
- Battle HUD不显示“声音方向”作为唯一信息；字幕/危险文字沿用BattleUI的priority与safe-area规则。
- Home已签发`SettingsProfileDomainV1`与四bus百分比；Audio按Home F4映射0为mute、1..100到dB。设备选择仍为session/runtime能力，不持久化进MVP profile。

## 10. Acceptance Criteria

> `[U]` unit、`[I]` integration、`[R]` Godot/runtime、`[M]` min-spec、`[E]` experience、`[A]` accessibility。未附raw artifact的条目均未通过。

- **AC-AF01 `[U][I]` owner boundary**：GIVEN全状态writer spies，WHEN ingest/play/teardown，THEN只写audio presentation/ACK/diagnostic；gameplay writers、phase row、四类contribution均0。
- **AC-AF02 `[U][I]` typed sources**：逐类matching/stale/invalid，只有sealed copy-out产生声音；Node/raw intent/query/未publish bank为0声。
- **AC-AF03 `[I]` committed-only/sole owner**：逐行跑§3.4正负例，每个语义恰一个owner；press、failed spawn、retire、REVIVE_CLEAR无成功/奖励声。
- **AC-AF04 `[I]` Player ACK**：STARTED/MERGED/DROPPED/SILENT与critical lifecycle逐态验证；仅enqueue不ACK，bit精确0b100，重建前后不丢不重播。
- **AC-AF05 `[I]` winner**：31-row terminal priority组合含VICTORY+lethal/FATAL；声音winner唯一且统计fact不反向触发被抑制声。
- **AC-AF06 `[U][I]` priority golden**：全部cue class两两及组合逐行匹配独立manifest/hash，protected danger不被低级截断。
- **AC-AF07 `[U][I]` capacities**：critical5/6/7、voice21/22/23与最终H_audio required−1/required/+1；低级overflow只drop/merge，P0不足fail closed。
- **AC-AF08 `[U]` steal/merge/variant**：多种physical order/free-list下F4/F5/F7输出及trace相同；同级不任意steal。
- **AC-AF09 `[I]` pressure aggregation**：303 enemies、400 projectiles、300 drops、4 Elite+Boss+Player critical；Player每tick一聚合、普通按扇区、引灵一主反馈、fog限频，无300 voices。
- **AC-AF10 `[U][I]` duck**：嵌套enter/refresh/exit、pause/rebuild/missing asset逐项匹配F6，最强request而非dB相加，最终有限恢复baseline。
- **AC-AF11 `[I][R]` pause/critical**：pause中gameplay新cue=0、movement loop停、resume不补播；revive+pause只由control pump推进并完成后ACK。目标build验证真实播放行为。
- **AC-AF12 `[I]` progression/choice**：open/press/commit/stale/refresh/upgrade/evolution/MAX/terminal，成功重音只在matching commit一次，双owner双响=0。
- **AC-AF13 `[I]` Boss/Elite**：arrival/telegraph/release/fog/phase/death与召唤0/actual child，预警早于伤害eligibility，success只在actual publish，四Elite碰撞不遮最高危险。
- **AC-AF14 `[I]` fallback/mute**：final/placeholder/missing/corrupt/P0..P3与master/SFX/system mute；无动态load/错误成功声/gameplay差异，P0无授权fallback时load fail。
- **AC-AF15 `[A][E]` mute equivalence**：静音重跑低血/revive/unsafe/risk/Boss/Elite/choice/terminal任务，正确率与反应门槛不低于BattleUI/VFX；缺逐trial raw记录为INCONCLUSIVE。
- **AC-AF16 `[A][E][R]` mono/output**：mono、手机扬声器、耳机分别跑关键cue单独与最坏碰撞；无相消，pan仅辅助。LUFS/peak/SNR/识别阈值未冻结前OPEN。
- **AC-AF17 `[U][I]` determinism**：同committed stream但producer排列、frame rate与free-list变化，event key/group/asset variant/start-stop-steal-ACK trace逐字段相同；PCM无需跨设备bit-identical。
- **AC-AF18 `[M][R]` full-load**：Active/Paused各预热后10000 iteration×3，project-side动态Node/player/Tween/container/Callable=0；报告main/audio CPU p50/p95/p99/max、underrun、voices、merge/drop/steal、RSS与audio memory，并有positive controls。
- **AC-AF19 `[I][R]` app-scope掌天音频**：GIVEN选择重复tap、204-byte `ReservationCreateResultV3`、160-byte `TerminalRunResultV2`的CONSUMED/RELEASED、`ProfileDomainMutationResultV2`带真实revision+receipt id/hash的fresh-live callback重复与乱序、无receipt的中间reservation update、124-byte `SaveDurableStampFactV1` bit0/1、伪独立unlock、同key异payload、UI rebuild、reconcile、mute→unmute、missing asset及声前/声后kill，WHEN恢复并重投影，THEN create source correlation/operation identity及音频identity逐位源于matching typed result与120-byte receipt、receipt ID逐位等于request ID，只有RELEASED生成返还event且CONSUMED为0，V2 semantic key不含presentation generation，V2 coalesce preimage逐byte包含operation kind/id、attempt、request与receipt id/hash；资源存在/未静音/无kill时create、RELEASED与bit0/1各恰1 voice，missing/mute为0并有diagnostic/fallback，只有kill窗口总次数0..1，中间update与伪独立unlock为0 event，duplicate OK_NOOP、conflict fault，rebuild/reconcile/unmute/boot补播0，pending/失败不得冒充成功音。
- **AC-AF20 `[I][R]` teardown/device**：Active/Paused/critical/terminal/fault、旧finished与device switch/background；旧局0 play/ACK/duck，新局不受污染，app music无旧battle引用。
- **AC-AF21 `[I]` evidence truth**：报告含build/config/priority/capacity/asset/bus hash、Godot import、device/OS/output/volume、raw event+voice trace与thermal；play调用数/无报错/桌面平均CPU/单次耳机试听不能PASS。

## 11. Open Questions / Blockers

| ID | Status | Required closure |
|---|---|---|
| OQ-AF01 | BLOCKED-EVENT-ABI/CAPACITY | 非Player producer audio rows、包含关系、per-capture maxima、bank/ACK。 |
| OQ-AF02 | BLOCKED-SEMANTIC-OWNER | Weapon/Projectile、Damage/Enemy、Leveling/SkillDraft唯一成功音owner rows。 |
| OQ-AF03 | PROVISIONAL-AUDIO-CAPACITY | 22 voices及各lane需clip overlap与min-spec证明；event bank容量仍未知。 |
| OQ-AF04 | BLOCKED-ASSET/MIX | Sound Bible、streams/fallback、bus/effect、LUFS/peak、duck/merge/import。 |
| OQ-AF05 | BLOCKED-GODOT-RUNTIME | 4.7.1 pause/stream_paused/finished/stop/reassign、device switch及engine allocation实测。 |
| OQ-AF06 | BLOCKED-TERMINAL-INTEGRATION | BattleRules/Settlement作者terminal与music handoff已定义；actual event row/assets/runtime仍待证。 |
| OQ-AF07 | BLOCKED-DEFENSE-ABI | shield唯一owner/view未冻结；Risk ward不得冒充shield余额。 |
| OQ-AF08 | BLOCKED-ACCESSIBILITY | 静音/mono/手机扬声器与听力差异证据，音频不可成为唯一通道。 |
| OQ-AF09 | BLOCKED-PERF/EVIDENCE | min-spec audio-thread、underrun、内存、零分配与用户辨识raw evidence。 |
| OQ-AF10 | FULL-REVIEW-PENDING | clean-context独立full review未执行；作者咨询不等于批准。 |
| OQ-AF11 | RUNTIME-BLOCKED | 项目audio bus layout/scene/import assets尚不存在，`battle_ready=false`。 |

全部MVP系统现已有作者设计覆盖。本文可作为Audio事件与资产协商基线；OQ-AF01–09、Home Settings runtime接线及独立full review未闭合前，不得称implementation-ready或runtime verified。
