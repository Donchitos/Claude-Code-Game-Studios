# RiskChoiceSystem（机缘抉择）

> 2026-09-16 Campaign E：Campaign 04线索机缘在已有升级积压清空后发布；180tick间隔期间保持可战斗等待，等待态纳入联合恢复验证。安全/风险两路线已做磁盘恢复对照，非完整故障矩阵。 详见[ADR-0009](../../docs/architecture/adr-0009-chapter-one-pacing-and-view.md)与[E包证据](../../production/playtest-evidence/2026-09-16-package-e.md)。仅本地验证，独立复审待完成，battle_ready=false。

> 2026-09-15 C包实施：Campaign开发入口的04线索/一次机缘/延迟猎物、05净化增援、06分段守路、07关闭根区、08三阶段Boss已接入Arena/Encounter快照。见[C包证据](../../production/playtest-evidence/2026-09-15-package-c.md)与[ADR-0008扩展](../../docs/architecture/adr-0008-chapter-one-encounters.md)。专项237、两套8关旅程/91次磁盘恢复通过；保持独立review/真人/商业owner合同待办，battle_ready=false。


> **Status**: Designed / Full Review Pending
> **Author**: User + Codex
> **Created**: 2026-09-03
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 韩立式谨慎取舍；避险或夺宝；低打扰单手战斗决策
> **Review Mode**: lean

## Overview

RiskChoiceSystem 在本局完成 4:00 与 8:00 两个固定 gameplay 时间点时，各产生一次不可跳过、无默认项的“藏锋避险 / 冒险夺宝”二选一。系统拥有两条机缘日程、选择 session、已提交分支、夺宝挑战追踪和 RunOutcome 的 risk rows；它不拥有 SceneTree pause、Player HP、伤害公式、Enemy 生命周期、生成位置、奖励或 UI Node。

选择发生在 GameRoot 的安全暂停 barrier。藏锋只提交一次 25% 最大生命恢复与 10 秒护身 modifier；夺宝只提交一次 mandatory Elite 请求。所有 gameplay effect 均在恢复后的首个完整 Active tick 才进入其 owner phase。两次选择最多贡献两条 blocking-choice row，和 SkillDraft 的 14 条精确组成 GameRoot schema 上限 16。

本文同时裁决旧容量冲突：MVP ENEMY 总注册上限保持 303，但 class 上限改为 `Normal 298 + Elite 4 + Boss 1`。这保证两只未击杀的机缘精英与 6:00、10:00 两只固定精英可同时存活，不把对象池 safety spare 冒充 active 容量。

## Player Fantasy

玩家应感觉自己是在危局中主动取舍：状态不佳时藏锋保命，构筑成型时引来更强精英搏取法宝匣。系统必须把立即收益、持续风险和 45 秒含义在选择前说清楚，不能用隐藏概率、自动选择或模糊的“更强”诱导玩家。

暂停必须干净：原移动触点不能误选，战斗计时、敌人、投射物与 Buff 不推进。提交后反馈来自已发布事实；没有真正恢复、护身生效或精英入场时，UI/音频不得提前表演成功。

## Detailed Design

### R1 — Owner、participant 与 contribution

- required participant 固定为：

```text
RISK_CHOICE_PHASE_ROW_V1={participant_id=RISK_CHOICE,role_id=RISK_CHOICE,
stable_order=9,allowed_phases={POST_DEFERRED_BARRIER},
allowed_success_statuses={OK,OK_NOOP},owner_contract_id=RiskChoiceSystem/v1,
owner_gdd_path=design/gdd/risk-choice-system.md,
phase_row_id=RISK_CHOICE_PHASE_ROW_V1,required=true}
```

- phase 7 只检查 completed gameplay tick、锁存 due event、向 GameRoot blocking-choice pump 提交 intent，并消费已提交 death/outcome view；Paused 中只通过 GameRoot control pump capability 处理选择 command。
- RiskChoice 不定义 gameplay `_process/_physics_process/_input`，不直接写 `SceneTree.paused`、HP、modifier snapshot、Enemy、Pool、Grid、Drop、奖励或 UI。
- `OwnerOrchestrationCapacityContributionManifest` actual rows 固定为：

| required_role_id | capacity_kind | outcome_field_id_or_none | required_max | owner_contract_id | source_gdd_path | role_stable_order | kind_stable_order | field_stable_order |
|---|---|---|---:|---|---|---:|---:|---:|
| `RISK_CHOICE` | `LIFECYCLE_INTENT` | `NONE` | 0 | `RiskChoiceSystem/v1` | `design/gdd/risk-choice-system.md` | 9 | 1 | 0 |
| `RISK_CHOICE` | `FACT_COMMIT` | `NONE` | 0 | `RiskChoiceSystem/v1` | `design/gdd/risk-choice-system.md` | 9 | 2 | 0 |
| `RISK_CHOICE` | `PAUSE_CLOSURE` | `NONE` | 0 | `RiskChoiceSystem/v1` | `design/gdd/risk-choice-system.md` | 9 | 3 | 0 |
| `RISK_CHOICE` | `BLOCKING_CHOICE` | `NONE` | 2 | `RiskChoiceSystem/v1` | `design/gdd/risk-choice-system.md` | 9 | 4 | 0 |
| `RISK_CHOICE` | `OUTCOME_FIELD` | `risk_choice_count` | 1 | `RiskChoiceSystem/v1` | `design/gdd/risk-choice-system.md` | 9 | 5 | 19 |
| `RISK_CHOICE` | `OUTCOME_FIELD` | `risk_choice_ids` | 2 | `RiskChoiceSystem/v1` | `design/gdd/risk-choice-system.md` | 9 | 5 | 28 |
| `RISK_CHOICE` | `OUTCOME_FIELD` | `risk_choice_results` | 2 | `RiskChoiceSystem/v1` | `design/gdd/risk-choice-system.md` | 9 | 5 | 29 |

`risk_choice_count` 是一个 scalar slot，不是最多一次选择；其值域为 0..2。两个 SoA backing 容量精确为 2，禁止按 GameRoot schema hard max 1536 分配实际 Risk bank。

### R2 — 两条日程与身份

`RiskChoiceEventConfigV1` 恰有两行，按 `event_ordinal ASC`：

| ordinal | risk_choice_id | due_completed_gameplay_ticks | branches |
|---:|---:|---:|---|
| 1 | non-zero stable ID | 14400 | `SAFE / TREASURE` |
| 2 | non-zero stable ID | 28800 | `SAFE / TREASURE` |

- 60 Hz 下分别对应 4:00、8:00。触发谓词为 `previous_completed_ticks < due_tick && due_tick <= current_completed_ticks`；每个 ordinal 只可 latch 一次。
- 完整 identity 为 `{battle_instance_id,config_snapshot_id,risk_choice_id,event_ordinal,due_tick,source_authority_revision,session_generation}`。ID、due tick、ordinal 必须唯一且严格升序；缺行、多行、重复、非法分支或默认补值均使 battle load 失败。
- 卡顿、pause、resume、重复 phase 与 wall clock 不产生额外触发。GameRoot terminal contender 在同 barrier 优先于 pause；terminal 已胜出时该页显示次数为 0。

### R3 — Offer、输入与 exact-once PONR

- `RiskChoiceOfferBankV1` 预分配 2 个 session slot，但同一时刻最多一个前台 offer。每页恰有两行且顺序固定 `SAFE=1,TREASURE=2`。
- UI 只读 immutable offer，提交 `RiskChoiceCommandV1={session_token_subset,command_id,selected_branch_id,expected_offer_revision}`；禁止携带恢复量、护身参数、Elite 类型、倍率或奖励 payload。
- selection token 首次从 matching `COMMIT_PREPARED` 写成 `COMMITTED` 是 PONR。PONR 前必须一次性预留 outcome row、分支 effect slot，以及 SAFE 的 recovery/ward slots或 TREASURE 的 RNG/spawn/challenge slots。
- 同 identity + 同 payload duplicate 为 `OK_NOOP`；同 command ID 冲突 payload、stale revision、跨 battle、旧 generation 或非法 branch 在 selector、ACK、effect、RNG、Outcome 写入前拒绝。
- Choice FSM 固定为 `SCHEDULED→DUE_LATCHED→PAUSE_QUEUED→OFFER_PUBLISHED→COMMIT_PREPARED→COMPLETED`；PONR 前可 `TERMINAL_CANCELED`，错误进入 `FAULTED`。PONR 后只能收敛已预留 subeffect，不得创建新 identity 或追加 RNG call。

### R4 — GameRoot pause 与 touch ownership

- 到期只请求 `RISK_CHOICE` pause source；GameRoot 完成当前 tick、Input lock、零 gameplay-dt drain、`SceneTree.paused` readback 后才允许发布 interactive offer。
- blocking choice 统一按 GameRoot `priority DESC→intent_sequence ASC` 排队；RiskChoice 不依赖 participant、Node 或 signal 到达顺序。存在 SkillDraft/Treasure 时一次只显示队首，后页读取最新 authority。
- outside tap、返回键、滑动、旧 release、旧 VirtualJoystick claim 与 shield-held touch 均不得关闭或选择。只有页面出现后的 fresh press 能生成 command，且其 matching release/cancel 完成前不得恢复 Active；持久 `ChoiceTouchDrain` 是未冻结 BattleUI 前的 required integration gate。
- choice-only 队列清空后可请求 resume；若 MANUAL、APP_BACKGROUND 或 INPUT_GEOMETRY_CHANGED 仍未完成，则继续 Paused，不显示虚假“已恢复”。

### R5 — 藏锋避险

- PONR 后冻结且仅冻结两条 typed intent：
  - `RecoveryIntentV1{type=MAX_HP_RATIO,value=0.25,reason=RISK_CHOICE,source_id=risk_choice_id}`；
  - `BuffModifierIntentV1{modifier_kind=TARGET_DAMAGE_MULTIPLIER,value=0.80,stack_group=RISK_WARD,duration_gameplay_ticks=600,combine_rule=REPLACE_MIN_MULTIPLIER,source_id=risk_choice_id}`。
- Paused 中 HP、modifier snapshot 与持续时间均不变化。恢复后首个 Active tick，Damage 在 phase 5 解析 recovery/next snapshot，Player 在 phase 6 固定按 `damage→lethal→heal clamp` 应用；致命时恢复为 0 且不结转，满血时 actual heal=0，但 ward 仍可生效。
- ward 有效窗口为 `[effective_tick,effective_tick+600)`，只按成功的 Active gameplay tick 推进。相同 stack group 不相加；重复同来源不刷新，若未来合法重叠则保留更低 multiplier 对应的更强减伤并用新窗口替换。
- ward 只在既有 target mitigation 后增加独立倍率步骤：`damage_after_ward=damage_after_existing_mitigation×0.80`，之后才进入 shield absorption。它不是无敌，也不是带余额的吸收盾。0.80 为 `PROVISIONAL-BALANCE`，结构与时序为 locked contract。

### R6 — 冒险夺宝与 RNG

- 每个已提交 TREASURE 分支精确调用一次 `RNG.roll_weighted_pick(RISK_CHOICE,weights)`。Config 为每个 event 冻结恰两项 eligible elite behavior `{6,7}`，初始权重 `{1,1}`；canonical index 按 behavior ID 升序。SAFE 分支消费 0 次，最多 2 calls/run。
- RNG 结果只决定 behavior ID。RiskChoice 发布 `RiskEliteSpawnRequestV1={risk identity,behavior_id,stage_snapshot_id,risk_hp_multiplier=1.30,risk_base_damage_multiplier=1.30,xp_amount=240,treasure_eligible=true,spawn_provenance=RISK_CHOICE,mandatory=true}`。
- `+30%` 只作用当前 stage segment 已解析、尚未叠 runtime modifier 的 `elite_max_hp` 与 `elite_base_damage`，各乘一次；current HP 初始化为强化后的 max HP。不影响移速、攻频、射程、防御/减伤、击退、尺寸、AI timer、XP 或掉落数量。1.30 来自主方案并锁定；受影响字段集合也由本文冻结。
- request 在 Paused、resume prepare 与 pause drain 均不交给 SpawnDirector；恢复后首个完整 Active tick 的 `SPAWN_INTENT` 恰提交一次 mandatory Elite intent。SpawnDirector 仍按每 intent 固定 8 candidates / 24 SPAWN RNG words决定位置；RiskChoice 不 borrow、insert、创建 Node 或重试。
- mandatory no-position、capacity miss、Pool/reset/Grid/publish fault 均走 SpawnDirector `ControlledGameplayFault`，不得屏内降级、变成 Normal suppression、丢失已提交选择或重摇。

### R7 — 4 Elite 容量裁决

- ENEMY type cap 保持 303；class hard caps 冻结为 `normal_active_pending<=298`、`elite_active_pending<=4`、`boss_active_pending<=1`，且三者 checked sum `<=303`。
- 298 个 Normal 槽是从 battle load 起永久上限，禁止先借满 300 再为 mandatory Elite 可见退场。Normal wave 超出 298 仍用既有无奖励 suppression；不更改 ENEMY 查询 workspace 303、Enemy owner contribution 303 或 total Grid capacity。
- `enemy_normal` Pool 保持 320，但 F1 inputs 改为 `298+0+12+10=320`；`enemy_elite` 改为 `4+0+1+1=6`。Pool capacity 6 现在真实覆盖 4 active + 1 spawn-before-release + 1 spare，不再把 safety spare 当作 active slot。
- 最坏合法序列为 4:00 risk、6:00 fixed、8:00 risk、10:00 fixed 均未死亡，共 4 Elite；12:00 Boss 加入时仍满足 `298+4+1=303`。其 min-spec 性能、WaveSchedule 压力与表现聚合仍需运行时验证，但不能再因合法内容触发 cap fault。

### R8 — 45 秒挑战、死亡 join 与奖励

- Challenge FSM 为 `NONE→SPAWN_RESERVED→SPAWN_PUBLISHED→ACTIVE_TIMED→ACTIVE_OVERTIME→KILLED_IN_TIME/KILLED_OVERTIME`；terminal 存活为 `UNRESOLVED_AT_END`，技术错误为 `FAULTED`。
- 计时从 Enemy authority 首次成功发布的 `spawn_visible_tick=S` 开始，deadline exclusive=`S+2700`。death fact tick `<deadline` 为及时击杀，`>=deadline` 为超时击杀。
- 到 2700 tick 只从 `ACTIVE_TIMED` 转为 `ACTIVE_OVERTIME`；精英不消失、不降级、不触发 OFFSCREEN_RETIRE，继续正常 FSM 与追击。超时不撤销奖励资格。
- 合法 matching DEATH 在及时或超时均由 Drop exact-once 产生 240 XP 与一个宝匣。固定精英 2 + Risk Elite 2 使 treasure provenance 每局最多 4，精确闭合 Drop active/window cap 4；第五个为 Config fault，不静默丢箱。
- RiskChoice 只读 `EnemyDeathStagingV2` 8-field row 与 COMMITTED fact，按非零`source_choice_id`+provenance+enemy/borrow identity join并更新 challenge/result；两次choice抽到同一behavior时不得按behavior猜测关联。它不写 DEATH、XP、宝匣或 Pool release。terminal cleanup 不伪造 death/reward。

### R9 — Outcome、terminal 与 teardown

`RiskChoiceResultV1` 封闭为：`SAFE_COMMITTED=1,TREASURE_KILLED_TIMELY=2,TREASURE_KILLED_LATE=3,TREASURE_ALIVE_AT_TERMINAL=4,TREASURE_TECHNICAL_FAULT=5`。

- `risk_choice_count` 精确等于已 PONR 的选择数；`risk_choice_ids/results[0,count)` 按 `event_ordinal ASC`。tail 非权威。
- terminal 先于选择 PONR：取消未提交 session，effect/RNG/spawn/Outcome=0；选择先 PONR：保留 choice row，但 Ending 后不启动尚未发生的 next-Active effect，结果按已提交状态落入封闭 enum。
- teardown 顺序为 offer/effect/challenge/outcome views invalid → 拒绝旧 command/death/timer → generation 推进 → release backing。新 battle 两条 schedule 从 0 重新建立。

## Formulas

### F1 — Due tick

`due_tick=round_to_int64(due_seconds×60)`，故 `240×60=14400`、`480×60=28800`。输入必须为冻结的整数秒且乘法 checked。

### F2 — 藏锋恢复

`raw_recovery=max_hp_at_source_revision×0.25`；实际值复用 registry `player_recovery_application`，即致命为 0，否则 `min(raw×recovery_multiplier,max_hp-hp_after_damage)`。

### F3 — 护身

`ward_end_tick=checked_add(effective_tick,600)`；窗口 `[effective_tick,ward_end_tick)`。`damage_after_ward=damage_after_existing_mitigation×0.80`，每步 float64 finite 检查。

### F4 — 夺宝强化

`risk_max_hp=stage_elite_max_hp×1.30`；`risk_base_damage=stage_elite_base_damage×1.30`。输入必须 finite、非负并绑定 matching stage/config revision。

### F5 — 45 秒结果

`deadline_exclusive=checked_add(spawn_visible_tick,2700)`；`death_tick<deadline_exclusive ? KILLED_TIMELY : KILLED_LATE`。

### F6 — Blocking capacity

`MAX_PENDING_BLOCKING_CHOICES=SkillDraft(14)+RiskChoice(2)=16`。required−1/required/+1 中只允许 exact 16 的 production manifest。

### F7 — Enemy class capacity

`max_enemy_registered=checked_add(normal_cap=298,elite_cap=4,boss_cap=1)=303`；任一 class 或总和越界均在 borrow/publish 前失败。

## Edge Cases

1. tick 从 14399 跳到 14401：ordinal 1 只 latch 一次。
2. 到期与 terminal 同 barrier：terminal 胜出，offer 不显示。
3. 到期与升级/宝匣同 tick：都入统一队列，只展示一个，不覆盖。
4. 玩家一直按住摇杆：页面可见但不可提交，直到旧 touch terminal 后 fresh press。
5. double tap 或 duplicate command：最多一次 PONR、一次 effect、一次音效。
6. SAFE 时满血：heal=0，ward 正常生效；UI 不播放虚假治疗。
7. SAFE 与致命伤同首个 Active tick：先致命，heal=0 且不结转。
8. ward 期间再次 pause：600 tick 计时不推进。
9. TREASURE 在第一个候选位置成功或第八个失败：SPAWN stream 都推进 24 words。
10. 第三、第四只 Elite 入场：正常成功；第五只在 Config/admission 前失败。
11. risk Elite 越过 retention rect：继续存在，不触发无奖励退役。
12. death 恰在 `S+2700`：记超时击杀，奖励仍发。
13. terminal 时 risk Elite 存活：结果为 `TREASURE_ALIVE_AT_TERMINAL`，不伪造 death/reward。
14. PONR 后 mandatory spawn 技术失败：选择保留，结果为 `TREASURE_TECHNICAL_FAULT`并进入统一 fault。
15. RNG fault：不重摇、不发布 spawn，保留诊断 cursor。
16. teardown 后旧 command/death callback：拒绝且新局状态不变。

## Dependencies

| System | Contract | Status |
|---|---|---|
| GameRoot | phase 7、pause/control pump、terminal precedence、Outcome ABI | Re-review Pending；Risk rows由本文补齐 |
| Config/Data | 两条 event、倍率、权重、容量与 manifest | Re-review Pending；本文 actual rows待独立复审 |
| InputSystem | old-touch shield、fresh press、resume drain | In Review；BattleUI glue未设计 |
| PlayerController | HP/max HP view、phase-6 recovery apply | Full Re-review Pending |
| DamageSystem | RecoveryIntent、RISK_WARD modifier、snapshot与公式顺序 | Designed / Full Review Pending；本次补充ABI仍待复审 |
| RNG | `RISK_CHOICE` weighted pick、fixed call count与fault | Re-review Pending |
| SpawnDirector | next-Active mandatory Elite、24 SPAWN words、capacity | Designed / Full Review Pending；class cap同步待复审 |
| EnemySystem | risk context、HP/death/provenance authority与Elite driver | In Review；4 Elite cap同步待复审 |
| SpatialGrid / Pool | ENEMY 303、class cap 298/4/1、pool 320/6/1 | In Review / Re-review Pending |
| DropSystem + Leveling | 240 XP、treasure、8-field death join（含source_choice_id）、cap 4 | Designed / Full Review Pending |
| Elite Enemies | behavior 6/7完整FSM、60t入场门、攻击/召唤/表现 | Designed / Full Review Pending |
| BattleUI / Audio | offer、touch、HUD、方向标、feedback | 两者均Designed / Full Review Pending，已冻结Risk两行、commit/arrival分层与持续追击语义；正式event rows/assets/runtime仍BLOCKED |

## Tuning Knobs

| Knob | Value | Status / Owner |
|---|---:|---|
| `risk_choice_due_ticks` | `{14400,28800}` | LOCKED / RiskChoice+Config |
| `safe_recovery_ratio` | 0.25 | LOCKED / RiskChoice+Damage |
| `ward_duration_ticks` | 600 | LOCKED / RiskChoice+Damage |
| `ward_taken_multiplier` | 0.80 | PROVISIONAL-BALANCE / Config |
| `risk_elite_hp_multiplier` | 1.30 | LOCKED / RiskChoice+Enemy |
| `risk_elite_base_damage_multiplier` | 1.30 | LOCKED / RiskChoice+Enemy |
| `risk_elite_weights` | behavior 6:1, behavior 7:1 | PROVISIONAL-BALANCE / Config |
| `risk_elite_xp` | 240 | PROVISIONAL-BALANCE / Drop |
| `risk_elite_treasure_eligible` | true | LOCKED / RiskChoice+Drop |
| `challenge_duration_ticks` | 2700 | LOCKED / RiskChoice |
| `normal/elite/boss active caps` | 298 / 4 / 1 | LOCKED / Config+Enemy+Spawn |

## Visual / Audio Requirements

- portrait 基准 `720×1280`，覆盖 `360×640 / 390×844 / 430×932`；bottom sheet 不超过 interactive safe viewport 50%，两张纵向等权卡无需滚动即可完整看到。
- 顶部只显示“机缘抉择”、当前 `HP/Max HP` 与一句提示。藏锋卡明确“实际预计恢复 +X、20%减伤10秒、不增加敌人”；夺宝卡明确“新增1只生命与基础伤害+30%的精英、45秒后仍持续追击、击杀240灵气+法宝匣”。
- 两项同时用名称、图标轮廓、边框形态与“稳/险”文字章区分，颜色只能辅助。护身用盾纹+分段计时，不用“无敌”；强化精英用独立轮廓、奖励章和方向标，不只染红。
- matching commit 后才播放确认。精英实际 publish 且`EliteArrivalCueV1`的P0视觉fallback可见后才显示“夺宝精英降临”；所有Elite统一进入60 Active ticks `ARRIVAL_LOCK`，首伤还须晚于技能自身预警末端。结构与时序已由Elite GDD冻结，资产/真机可读性证据仍`BLOCKED-PRESENTATION/OPEN-UX`。
- 45 秒计时只按 gameplay tick；到点切为“持续追击”，不显示负数、不播失败音、不逐秒滴答，只提示一次。ward 最后 3 秒可用不高于 2 Hz 的轻量轮廓呼吸。
- 音频优先级：Boss/致命/濒死/复活/终局 > 强化精英入场与危险动作 > ward 即将结束 > RiskChoice 打开/确认/生效/持续追击 > 普通命中与环境。静音时信息仍完整。

## UI Requirements

- 整张卡为热区；行高 `max(56,safe_height×0.044)`，间距 `max(8,safe_height×0.00625)`，内容完全位于 safe area 与 system gesture inset。
- 固定输入路由为 `choice UI → movement shield → VirtualJoystick`，不得依赖 `z_index` 推断 ownership。
- blocked、ready、pressed、submitting、committed、stale/error、queued-behind-other-choice 状态都要有非颜色反馈；blocked 首次仅在触点邻近提示一次“请先松开移动手指”。
- 同时多只 risk/fixed Elite 的方向标聚合按威胁优先级、距离与 stable enemy ID 破平；具体显示数和遮挡策略由 BattleUI 冻结，不能隐藏 reward-bearing Elite。
- copy 只读已发布 Config/authority；字段缺失时显示安全错误态并禁用提交，不自行猜默认值。

## Acceptance Criteria

- **AC-RC01 `[U][I][BLOCKING]` owner/phase**：覆盖Active/Pause/Resume/Terminal/Teardown，RiskChoice仅写两条schedule/session、challenge与risk Outcome；stable order=9且只跑phase 7/control pump；直接写pause/HP/Enemy/Pool/Grid/Drop/UI次数0。
- **AC-RC02 `[U][I][BLOCKING]` contribution**：四类为0/0/0/2；SkillDraft14+Risk2=16；Outcome scalar slot=1、ids/results capacity=2，required−1/required/+1只exact值成功。
- **AC-RC03 `[U][BLOCKING]` config**：恰两条event、ID非零唯一、ordinal/due严格升序、due={14400,28800}才通过；缺/重/乱序/第三条无默认补值。
- **AC-RC04 `[I][BLOCKING]` tick边界**：14399/14400/14401与28799/28800/28801只各触发一次；pause、卡顿、wall clock和phase重放不增计数。
- **AC-RC05 `[I][BLOCKING]` 安全暂停**：到期时先完整收敛当前tick并readback pause；Paused中movement/Enemy/Projectile/Damage/Drop/buff/spawn/timer推进为0。
- **AC-RC06 `[I][BLOCKING]` 队列**：与Level/Treasure同tick时全部保留、一次一页、按统一priority+sequence排序；全部choice完成前resume=0。
- **AC-RC07 `[U][I][BLOCKING]` command ABI**：UI payload只有token/command/branch/revision；玩法数值只从Config解析。
- **AC-RC08 `[U][I][BLOCKING]` exact-once**：首个matching、100 duplicate、conflict、stale、跨局与非法branch矩阵中，只有首个matching产生一次PONR/effect/outcome/音效；同payload duplicate为OK_NOOP。
- **AC-RC09 `[I][BLOCKING-BATTLEUI]` touch**：100次持续拖动→页面→释放→fresh press，误选、旧触点晋升、重复commit均0；matching terminal前不得resume。
- **AC-RC10 `[U][I][BLOCKING]` recovery**：HP=0/1/max−25%/max与同tick致命/非致命矩阵中，Paused写HP=0，phase5只解析一条0.25 intent，phase6按damage→lethal→heal clamp，实际正恢复最多一条HEAL fact。
- **AC-RC11 `[U][I][BLOCKING]` ward**：0.80只在existing mitigation后、shield前应用一次；窗口599/600/601边界正确，Paused不推进，duplicate不刷新，同组不相加。
- **AC-RC12 `[I][BLOCKING]` SAFE负向保证**：两次SAFE产生Elite/Risk RNG/XP/宝匣均0，recovery与ward各两次exact-once。
- **AC-RC13 `[I][BLOCKING]` next-Active spawn**：Paused commit后仅首个Active SPAWN_INTENT提交一条mandatory request，第二tick不重复，RiskChoice borrow/Grid/Node writer=0。
- **AC-RC14 `[I][BLOCKING]` spawn收敛**：第1/8候选、无位置、cap miss、Pool/reset/Grid fault均消费24 SPAWN words；成功时Pool/Grid/Enemy/visible identity一致，失败无ghost/屏内降级/重试。
- **AC-RC15 `[U][I][BLOCKING]` RNG**：每个TREASURE精确1次两项weighted pick，SAFE 0次；物理排列或其他stream调用不改变behavior、cursor与后续结果。
- **AC-RC16 `[U][I][BLOCKING]` +30%**：只对stage-resolved maxHP/baseDamage各乘1.30一次；move speed、cadence、range、defense、knockback、size、AI timer、XP、drop均逐字段不变。
- **AC-RC17 `[I][BLOCKING]` identity/owner**：matching/stale/duplicate spawn context与旧borrow矩阵中，仅Enemy创建/维护HP/death/lifecycle；risk choice provenance可从spawn到death逐identity追踪。
- **AC-RC18 `[I][BLOCKING]` 最坏容量**：两次risk未杀+6/10分钟fixed未杀时4 Elite均存在；12分钟Boss加入仍满足298+4+1=303，mandatory spawn不fault，Pool/Grid/authority逐类守恒。
- **AC-RC19 `[U][I][BLOCKING]` 45秒**：S+2699及时、S+2700/2701超时；从authority-visible S开始，Paused与wall clock不推进。
- **AC-RC20 `[I][BLOCKING]` 持续追击**：S+2700后只变ACTIVE_OVERTIME；Grid remove/Pool release/DEATH/reward=0，Enemy FSM继续，OFFSCREEN_RETIRE=0。
- **AC-RC21 `[I][BLOCKING]` reward**：及时/迟杀均exact-once 240 XP+1宝匣，duplicate/stale/retire为0；两fixed+两risk=4通过，第5个配置失败。
- **AC-RC22 `[U][I][BLOCKING]` terminal**：terminal与due/PONR前后矩阵满足GameRoot precedence；PONR前UI/effect=0，PONR后row保留但Ending不执行新effect，未选项不自动选择。
- **AC-RC23 `[U][I][BLOCKING]` Outcome**：0/1/2 choices及四种TREASURE结局中count、ids/results逐行对应、按ordinal排序、tail非权威，只有RiskChoice producer写三字段。
- **AC-RC24 `[U][I][BLOCKING]` teardown**：各局部状态 teardown 后view先invalid再generation推进；旧command/death/timer均拒绝，新局日程从0开始。
- **AC-RC25 `[U][I][BLOCKING]` replay**：相同seed/config/commands、打乱Node/signal顺序后choice IDs、elite behavior/seed、倍率、deadline、reward、Outcome与per-stream calls逐值一致。
- **AC-RC26 `[P][BLOCKING-TOOLING]` zero allocation**：两条bank、16 choice、4 Elite、10000 Active ticks与反复Paused control pump中无容器growth/COW/String/Callable.bind/带参signal/native unstable sort；需paired baseline+positive control，否则INCONCLUSIVE。
- **AC-RC27 `[E][OPEN-BATTLEUI/UX]` 布局与反馈**：三档viewport、安全区、动态字体与左右手中，两卡完整无滚动、无裁切越界；commit前确认VFX/audio=0，commit后下一显示帧状态匹配authority。
- **AC-RC28 `[E][OPEN-UX]` 理解度**：5名首次玩家共20个关键事实题至少18/20正确，且“45秒后消失/奖励作废”“护身=无敌”两类关键误解均0人；两选项旅程每cell 20次成功至少19次。

## Open Questions / Readiness

1. **BLOCKED-BATTLEUI/INPUT**：BattleUI 尚未冻结 command error、focus、touch terminal ownership、方向标聚合与完整 copy table。
2. **BLOCKED-WAVE/BALANCE**：WaveSchedule、4 Elite压力、0.80 ward、1:1 elite权重和240 XP仍需15分钟数值仿真与试玩。
3. **BLOCKED-TREASURE-EXHAUSTION**：40级且无可进化技能时宝匣补偿仍未定义；不影响本系统证明“最多4箱”，但阻止完整奖励闭环。
4. **BLOCKED-WORKLOAD-REGEN**：GameRoot现有 workload manifest与400 Projectile/300 Drop权威上限冲突，需整表重生成。
5. **BLOCKED-ELITE-PRESENTATION**：behavior 6/7 FSM与首击门已由Elite GDD冻结；生产资产、P0 fallback、4 Elite同屏可读性与真机证据仍缺。
6. **OPEN-RUNTIME/PERF/UX/AUDIO**：本文仅为静态作者设计。未执行Godot/GDUnit4、allocator guard、min-spec、真机、素材、音频或用户测试。
7. **FULL-REVIEW-PENDING**：系统、QA、视觉/UX specialist 仅参与作者设计输入，不构成 clean-context 独立 verdict；`battle_ready=false`。
