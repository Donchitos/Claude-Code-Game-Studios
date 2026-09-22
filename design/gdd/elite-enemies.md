# Elite Enemies（巨甲蜈蚣与鬼雾修士）

> **Status**: Designed / Full Review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / ai-programmer / qa-lead / art-director）
> **Created / Last Updated**: 2026-09-03
> **Implements Pillar**: 以可读、可躲、击杀后有构筑跃迁的“小 Boss”检验玩家走位与目标优先级
> **Scope**: MVP production behavior/content contract；不包含 Boss、完整 WaveSchedule、最终资产或最终数值平衡

## 1. Overview

Elite Enemies 是 `behavior_id=6` 巨甲蜈蚣与 `behavior_id=7` 鬼雾修士的内容 owner。本文冻结两类精英的配置 profile、状态图、攻击几何、入场保护、风险强化兼容、召唤上界、奖励 provenance 与表现语义。

EnemySystem 继续拥有 `EnemyElitePoolable/v1` 载体、HP/lifecycle、移动提交、轻量分离、受击与死亡；本系统不创建第二套敌人 Node 或 phase participant。SpawnDirector 拥有实际生成与容量准入，ProjectileSystem 拥有魂针载体，DamageSystem 拥有伤害结算，DropSystem 拥有 XP/宝匣。本文提供这些 owner 必须消费的 immutable content row 与 typed intent 参数。

MVP 固定精英锚点为 6:00 巨甲蜈蚣、10:00 鬼雾修士；4:00/8:00 的 RiskChoice 还可各生成一只行为 6 或 7 的强化精英。未击杀时最坏为 4 Elite 同屏，其中鬼雾修士最多 3 只。

## 2. Player Fantasy

玩家第一次看到精英时，应在一秒内明白“它将怎样逼我走位”，而不是先吃伤害再学习规则：

- 巨甲蜈蚣是重型直线威胁。它用一次明确锁向串起三段冲刺，第三段结束暴露 2.5 秒破绽，奖励横向闪避与持续输出。
- 鬼雾修士是位移与目标优先级威胁。它先标落点，再显式预告 60° 魂针扇面，随后召唤血傀儡，奖励离开危险扇面并尽快处理施法者。
- 固定与夺宝精英使用完全相同的行为节奏；夺宝版只增加生命与基础伤害，不偷改速度、范围、次数或预警。
- 4 Elite 同屏时，每个会生效的危险仍必须可见。玩家失败应能归因到一次已预警动作，而不是特效遮挡、屏外突伤或容量竞争。

## 3. Detailed Design

### 3.1 权威边界与 Config schema

`EliteBehaviorConfigV1` 恰有两行，按 `behavior_id ASC` 排序并进入 `BattleConfigSnapshot` content hash。字段至少为：

`{schema_version,behavior_id,stable_name,base_max_hp,base_damage,move_speed,shape_bound,knockback_resistance,arrival_lock_ticks,fsm_table_id,attack_profile_id,reward_profile_id,presentation_profile_id}`。

扩展表为 `CentipedeConfigV1`、`GhostCultivatorConfigV1`、`FixedEliteScheduleV1` 与 `ElitePresentationManifestV1`。缺行、重行、未知 behavior、非法 finite 值、FSM 引用断裂或 hash 不匹配均在 Node/Pool 初始化前使 `battle_ready=false`；运行时不得补默认值。

本文冻结内容语义，EnemySystem 按 behavior row dispatch FSM table，不以 `if behavior_id == ...` 硬编码内容。Elite Enemies 不是 GameRoot participant，四类 owner orchestration contribution 均为 0，也不新增 Outcome 字段。

`EliteRuntimeStateV1` 是 Loading 期预分配的 typed state/SoA row，至少冻结 `{fsm_state,state_ticks,active_age_ticks,action_generation,charge_axis,charge_segment_index,charge_progress,charge_hit_mask,blink_cycle_index,blink_landing_position,needle_axis,summon_generation}`。每个字段随 Enemy borrow identity reset/快照/恢复；禁止用 Dictionary、Node metadata、动画回调或运行时新增字段承载玩法状态。一个 Active tick 最多跨一条有时长边加一条0-tick提交边，总迁移数硬上限2；超过即 fault，禁止 `while` 吞完状态链。

### 3.2 固定入场与 Risk 变体

| 来源 | due tick | behavior | HP/base damage multiplier | XP | treasure |
|---|---:|---:|---:|---:|---|
| `FIXED_ELITE_1` | 21600 | 6 巨甲蜈蚣 | 1.00 / 1.00 | 160 | true |
| `FIXED_ELITE_2` | 36000 | 7 鬼雾修士 | 1.00 / 1.00 | 300 | true |
| `RISK_CHOICE` | 14400 或 28800 后实际 publish | 6 或 7 | 1.30 / 1.30 | 240 | true |

固定行的 due tick 分别对应 6:00、10:00 completed gameplay time，均为 mandatory Elite intent；Risk 行沿用 RiskChoice identity 与 `SpawnContextCarrierV2`。所有 Elite 都不适用 Normal 的 `OFFSCREEN_RETIRE`。

Risk 变体只改变 resolved max HP 与 base damage，各乘一次 1.30；尺寸、移速、攻击倍率、攻击次数、冷却、预警、blink 落点、召唤数、抗击退、XP 与宝匣数量逐字段等于同 behavior 固定版。

### 3.3 共同入场门与首伤时刻

每只 Elite 首次 authority publish 时写一条 `EliteArrivalCueV1={battle/config/tick,enemy_id,borrow_id,behavior_id,spawn_provenance,risk_tag,edge_direction,cue_sequence}`。`arrival_visible_tick=S` 只在 matching cue 已可由 BattleUI 的预加载 fallback 显示后提交；本体在屏外时仍显示带行为轮廓的方向标。

Elite 从 `S` 进入 `ARRIVAL_LOCK`，可被攻击、击退和击杀，但不得提交任何会伤害玩家的 intent；60 个 Active gameplay ticks 后才进入各自 TRACK。Paused 不推进。首个伤害 eligibility 必须同时满足入场门与该技能自己的预警门，RiskChoice 确认 tick 不得冒充 `S`。

若表现 fallback 未准备、cue 未提交或 identity stale，Elite 保持不可伤害玩家并进入 controlled fault/safe stop；不得为了继续战斗跳过提示。

### 3.4 巨甲蜈蚣 FSM（behavior 6）

状态图：

`ARRIVAL_LOCK → TRACK → TELEGRAPH_CHARGE → CHARGE_1 → LINK_1 → CHARGE_2 → LINK_2 → CHARGE_3 → WEAKENED → TRACK`

| 当前状态 | 可判触发 | action | 下一状态 |
|---|---|---|---|
| `ARRIVAL_LOCK` | `active_age_ticks >= 60` | 启用进攻；冷却从 0 开始 | `TRACK` |
| `TRACK` | `cooldown_ticks>=300 && distance<=6.0` | 以 published Player center 锁定唯一 `charge_axis`，发布三箭节廊道，`charge_index=0` | `TELEGRAPH_CHARGE` |
| `TELEGRAPH_CHARGE` | `state_ticks>=24` | latch 第1段 charge attack；清零投影进度 | `CHARGE_1` |
| `CHARGE_i` | `projected_progress>=6.0` | 本段 hit window 关闭；发布 `charge_index=i` 边界反馈 | `LINK_i`（i<3）或 `WEAKENED`（i=3） |
| `LINK_i` | `state_ticks>=6` | 沿原 `charge_axis` 启动下一段；不重瞄准 | `CHARGE_(i+1)` |
| `WEAKENED` | `state_ticks>=150` | 移除破绽 modifier；清零 chain/cooldown | `TRACK` |

- 三段共用 TELEGRAPH 时锁定的方向；LINK 只提供 6 tick 可观察断点，不读取新 Player 位置。
- 每段 `charge_distance=6.0`、`charge_speed=18.0 units/s`，末步只移动剩余距离。CHARGE 中分离修正只保留垂直于锁定轴的分量，沿轴反推为 0，保证投影单调到达。
- 每段对同一 Player borrow 最多提交一次不可暴击 `DamageIntentV1`，基础伤害倍率 1.0；hit history key 为 `{enemy_borrow_id,chain_generation,charge_index,player_borrow_id}`。TRACK/LINK/WEAKENED 的身体接触不产生额外伤害。
- WEAKENED 持续 150 tick，受到的最终伤害在 existing attack modifiers 后乘 `1.25`，击退抗性暂降为 `0.35`；离开状态立即恢复 profile 值。该 1.25 为 `PROVISIONAL-BALANCE`，结构与 owner 边界 locked。
- 第三段结束与 WEAKENED 开始是同一状态边界，不允许多一帧仍造成 charge damage。

### 3.5 鬼雾修士 FSM（behavior 7）

状态图：

`ARRIVAL_LOCK → TRACK → TELEGRAPH_BLINK → BLINK → TELEGRAPH_NEEDLE → RELEASE_NEEDLE → RECOVER → SUMMON → TRACK`

| 当前状态 | 可判触发 | action | 下一状态 |
|---|---|---|---|
| `ARRIVAL_LOCK` | `active_age_ticks>=60` | 启用进攻并令 blink period 从 0 开始 | `TRACK` |
| `TRACK` | `blink_period_ticks>=360` | 按 F3 冻结本周期 landing point；发布落点预警 | `TELEGRAPH_BLINK` |
| `TELEGRAPH_BLINK` | `state_ticks>=18` | 原子提交 landing position；禁止插值改点 | `BLINK` |
| `BLINK` | 同 tick position publish 成功 | 以 landing→published Player center 锁定 `needle_axis`，发布 60°/5.0 扇面 | `TELEGRAPH_NEEDLE` |
| `TELEGRAPH_NEEDLE` | `state_ticks>=30` | latch 三枚魂针的 typed projectile rows | `RELEASE_NEEDLE` |
| `RELEASE_NEEDLE` | 三行完整 plan 已 latch | 关闭危险填充，保留释放残影 | `RECOVER` |
| `RECOVER` | `state_ticks>=24` | latch 一条三子项召唤 cluster | `SUMMON` |
| `SUMMON` | cluster 已 latch（不等实际 borrow） | `blink_cycle_index++`，重置 period | `TRACK` |

原 EnemySystem 中“BLINK 落地即释放 FAN_NEEDLE”与 30 tick 魂针预警冲突，以本表为内容权威：伤害载体只能在 `TELEGRAPH_NEEDLE` 满 30 tick 后 latch。原 `fan_needle_duration=0.4s` 统一解释为释放后的 `recover_ticks=24`，不再是预警前的死参数。

### 3.6 Blink、魂针与 Projectile handoff

- blink 落点为 Player center 外 1.5–2.5 units；角度和半径都按 `spawn_seed + blink_cycle_index` 的纯 hash 派生，不消费 runtime RNG cursor。同一 seed/config/tick trace逐 bit复现；每周期可变化，单周期内不可重算。
- 落点完整 footprint 必须在 `world_safe_aabb`，经 real_t32 readback仍合法；不得 clamp、wrap、改成当前点或因敌人重叠重选。合法域内重叠交给 EnemySystem 分离。
- 魂针为三枚 `HOSTILE/LINEAR` Projectile，方向为 `needle_axis` 的 `-30°/0°/+30°`，速度 `10.0 units/s`、射程 `5.0`、半径 `0.12`、生命周期 30 tick，每枚只命中 Player 一次、不可暴击、伤害倍率为 `0.75 × resolved base_damage`。
- 三枚 projectile row 是原子 batch：Projectile intake不足3行时本次 resolution 不发布并进入统一 fault，不得只发1或2枚。视觉扇面与三条轨迹必须从同一 axis/range/angle row派生。
- tick T 的 Enemy FSM 只 latch plan；Projectile 只能在 T+1 `SPAWN_INTENT` 原子借出三行。T 内生成、移动或命中数均为0。
- MVP 最坏同时存活3只behavior7，因此Elite hostile projectile contribution为`3×3=9 rows/tick`。Boss已冻结8，但Weapon与behavior2/4 Normal远程仍未知；global pending公式`Weapon_P+NormalEnemy_P+9+8<=32`继续`BLOCKED-CAPACITY`。
- 每枚仍可能在下一 tick 命中时，由 ProjectileSystem 贡献一条 matching `ReviveHazardIntentV2{shape_code=CIRCLE}`；Boss传播后总式仍等待Enemy nonprojectile与Stage贡献，本文不擅自填总容量。

### 3.7 血傀儡召唤与 SpawnDirector handoff

每个 SUMMON 状态 latch 一条 `EliteSummonClusterIntentV1={battle/config/tick,summoner_enemy_id,summoner_borrow_id,behavior_id=5,spawn_provenance=ELITE_SUMMON,cluster_generation,child_count=3,source_position,source_spawn_seed,mandatory=false}`。SpawnDirector 在下一 Active tick 的 `SPAWN_INTENT` 将其展开为 3 个稳定 child intent，并对整 cluster 先 plan、后原子 admission：

- 三个 child 的顺序为 `child_index=0,1,2`；每个仍固定消费 8 candidates × 3 SPAWN_POSITION words，成功早停也 discard 到24 words。
- candidate 以 matching summoner published position 为中心，在 `[1.5,2.5]` local ring 采样；不要求屏外，但需通过 world domain、stage/hazard禁生区、Player 最小表面净空与完整 footprint检查。
- 任一 child 无合法位置、Normal `active+pending` 剩余槽少于3、summoner identity stale或 cluster backing不足时，整 cluster 生成0只；72 words仍精确消费，发布一次 `SUMMON_DISSIPATED` 表现，不在本周期重试。
- 全部3个 child plan 合法才按 child index 发布；实际 publish 前不得播放血傀儡出现成功表现。召唤 provenance 的 behavior 5 击杀固定为0 XP、0 utility、0 treasure。

最坏3只鬼雾修士同tick召唤9只。合法容量为`max(12 Wave+9 Elite summon+1 Elite+1 Boss,12 Wave+9 Elite summon+2 Boss summon)=23`；Boss P2只在fixed rows均已消费后发生。`SpawnIntentBankV2.capacity=23`、position words=552不变，不提高active class cap或pool容量。

### 3.8 四 Elite 并发、暂停、死亡与奖励

- class admission固定 `Elite active+pending<=4`，MVP composition上界为1只固定蜈蚣+1只固定鬼修+2只Risk；behavior 7最多3只。
- 状态、计时器、chain/cycle index、locked axis/landing、hit history 与 presentation generation都属于 borrow identity。Pause期间全部冻结；resume后从同一值继续，不用 wall clock补时。
- 4 Elite 均参与 EnemySystem 的current+swept threat snapshot；Player复活只清 Normal，不清 Elite。next-tick swept bound必须覆盖当前状态所有合法位移：TRACK按通用move上界，CHARGE至少`shape_bound+0.3`，`TELEGRAPH_BLINK`最后tick至少`shape_bound+distance(current,landing)`；未知landing或较小常量均不得冒充安全。
- 合法 DEATH 仍只由 EnemySystem提交。为使两次Risk抽到同一behavior时可唯一归因，death staging升级为 `EnemyDeathStagingV2` 八字段 `{death_fact_sequence,enemy_id,borrow_id,behavior_id,death_position,spawn_seed,spawn_provenance,source_choice_id}`；非Risk为0，Risk必须逐字段等于spawn context。Drop根据 behavior/provenance/source choice精确产生固定160/300或Risk240 XP与一个宝匣；RiskChoice以source choice join timely/late/alive outcome。死亡、奖励、入场、破绽、召唤表现都必须 join matching committed identity，stale/replay为0。
- terminal后不启动新攻击/召唤；已提交 projectile、damage、death与reward按各 owner 的PONR规则收敛。Risk Elite在45秒后不消失，只将挑战章切为“持续追击”。

## 4. Formulas

### F1 — Elite resolved stats

```text
stage_hp_multiplier = min(3.0, 1 + 0.18 * stage)
stage_damage_multiplier = min(2.5, 1 + 0.12 * stage)
resolved_max_hp = base_max_hp * stage_hp_multiplier * spawn_hp_multiplier
resolved_base_damage = base_damage * stage_damage_multiplier * spawn_damage_multiplier
```

**Variables**: `stage`为非负整数分钟阶段；base值finite且>0；spawn倍率仅可为固定版1.0或matching Risk 1.30。  
**Output**: 两值finite且>0；current HP初始化为resolved max HP。  
**Example**: 蜈蚣spike base HP=1200、stage=6、固定版倍率1，得`1200×2.08=2496 HP`。

### F2 — Charge step and projected progress

```text
remaining = charge_distance - projected_progress
axis_step = min(charge_speed / 60, remaining)
committed_delta = charge_axis * axis_step + perpendicular_separation
projected_progress_next = projected_progress + dot(committed_delta, charge_axis)
```

**Variables**: distance=6.0，speed=18.0，axis为finite单位向量；分离分量与axis点积必须逐bit为0。  
**Output**: progress单调、位于`[0,6]`，每段恰20 Active ticks完成。  
**Example**: 起点0时每tick推进0.3，第20 tick到6.0；轴前方反推被移除，不会死锁。

### F3 — Deterministic blink landing

```text
angle_u = hash_u16(spawn_seed, blink_cycle_index, BLINK_ANGLE_SALT) / 65535
radius_u = hash_u16(spawn_seed, blink_cycle_index, BLINK_RADIUS_SALT) / 65535
angle = 2*pi*angle_u
radius = lerp(1.5, 2.5, radius_u)
landing = player_position + unit_vector(angle) * radius
```

**Variables**: seed为int64，cycle为checked非负int32，两个salt为不同冻结常量。  
**Output**: radius属于闭区间`[1.5,2.5]`；real_t32 readback后仍须通过完整足迹world guard。  
**Example**: `angle_u=0.25,radius_u=0.5`时，落点为玩家位置加 `(0,2.0)`。

### F4 — Soul-needle fan directions

```text
offset_deg(i) = -30 + 30*i, i in {0,1,2}
needle_direction_i = rotate(needle_axis, radians(offset_deg(i)))
needle_damage = resolved_base_damage * 0.75
```

**Variables**: axis为landing指向published Player center的单位向量；零向量时使用spawn facing，不重新采样。  
**Output**: 三方向finite单位向量，对称张成60°范围；damage finite且>0。  
**Example**: axis朝右时三枚方向角为`-30°/0°/+30°`。

### F5 — Spawn workload bound

```text
max_ghosts = fixed_ghosts + max_risk_ghosts = 1 + 2 = 3
max_summoned_children = max_ghosts * 3 = 9
max_spawn_intents = max(wave_normal_anchors + elite_summon_children + elite + boss,
                        wave_normal_anchors + elite_summon_children + boss_summon_children)
                  = max(12 + 9 + 1 + 1, 12 + 9 + 2) = 23
max_spawn_rng_words = 23 * 8 * 3 = 552
```

**Variables**: 四项均为checked非负int。  
**Output**: intent capacity 23、word bound 552。  
**Example**: 三只鬼修同tick施法且同tick有12个普通波次child和Boss intent时恰好满载，不overflow。

### F6 — Earliest damaging tick

```text
earliest_damage_tick = max(arrival_visible_tick + 60,
                           attack_telegraph_start_tick + attack_telegraph_ticks)
```

**Variables**: tick为checked int64；telegraph为蜈蚣24或魂针30。  
**Output**: 在`[S,S+59]`伤害 contribution 恒为0；Paused不改变差值。  
**Example**: 蜈蚣在S+60开始24 tick预警，最早S+84可伤害。

## 5. Edge Cases

1. Elite在 ARRIVAL_LOCK 内被击杀：攻击/召唤为0，合法death仍给对应奖励。
2. 入场时处于屏外：方向标从S可见，60 tick不等本体入镜后才开始，也不允许无提示计时。
3. 同tick arrival结束与pause提交：pause barrier胜出，攻击计时在resume后继续。
4. 蜈蚣charge中Player穿到背后：三段方向不变，不重瞄准。
5. charge轴前拥挤：只移除沿轴分离反推，垂直分离保留；20 tick仍完成本段。
6. 蜈蚣在WEAKENED最后tick受击：`[start,start+150)`内乘1.25，边界tick恢复1.0。
7. blink候选越world domain：不clamp、不换当前点，整motion batch失败并fault。
8. blink landing与另一个Enemy重合：合法发布，由下一tick分离处理，不暗改落点。
9. landing恰等Player center：正常hash半径不可能；非法Config/hash实现使batch失败，fallback facing只用于needle axis零差值。
10. Projectile intake只剩2行：三魂针原子batch失败，不部分发射。
11. Normal只剩2个槽：召唤cluster为0并一次逸散，不生成2只，也不本周期重试。
12. 三只鬼修同tick召唤：展开9 child，稳定按summoner identity/cluster/child排序。
13. 召唤latch后summoner死亡：已合法latch的cluster按frozen source position执行；stale重复callback为0。
14. 4 Elite+Boss同屏：总ENEMY303仍成立；任何Normal不得占Elite/Boss预留。
15. 45秒Risk deadline到期：行为不变，不退场、不降倍率、不撤宝匣。
16. terminal与attack同tick：terminal gate禁止新latch；已PONR事实按owner规则收敛。

## 6. Dependencies

| System | Contract / status |
|---|---|
| EnemySystem | Elite载体、HP/lifecycle、movement/separation、FSM table driver；In Review，须接受本文为behavior 6/7内容owner |
| Config/Data | 两行profile、schedule、FSM/attack/presentation hash、23/552容量；Re-review Pending |
| SpawnDirector | fixed/Risk intent、local summon cluster、23-row bank；Designed，须同步V2 |
| DamageSystem | charge/needle伤害、WEAKENED target modifier、hazard aggregate；Designed，global capacities仍BLOCKED |
| ProjectileSystem | 三魂针原子HOSTILE batch、Elite contribution=9；Designed，global producer sum仍BLOCKED |
| Drop + Leveling | fixed160/300、Risk240、每只一个宝匣、summoned puppet 0奖；Designed |
| RiskChoice | 两次weighted Elite、1.30倍率、45秒持续；Designed |
| PlayerController | published center与threat/revive规则；In Review |
| BattleUI / Audio / VFX | BattleUI与Audio作者GDD已冻结方向/危险voice/聚合语义；正式Elite presentation/audio rows、P0资产与runtime仍BLOCKED，VFX未设计 |
| BossStateMachine | Boss projectile8、nonprojectile hazard2、P2 0/2召虫与视觉优先级；Designed / Full Review Pending |

## 7. Tuning Knobs

下列 base stats 是 `PROVISIONAL-BALANCE` 的首个可玩 spike，不是最终 production lock；行为结构、上下界和时序为 locked contract。

| Knob | 巨甲蜈蚣 | 鬼雾修士 | 状态 |
|---|---:|---:|---|
| base max HP | 1200 | 1000 | PROVISIONAL-BALANCE |
| base damage | 16 | 14 | PROVISIONAL-BALANCE |
| move speed | 3.4 | 3.0 | PROVISIONAL-BALANCE |
| shape bound | 0.80 | 0.65 | PROVISIONAL-BOUNDS；须回填Stage/Grid proof |
| base knockback resistance | 0.85 | 0.50 | PROVISIONAL-BALANCE |
| arrival lock | 60 ticks | 60 ticks | LOCKED minimum |
| charge trigger / telegraph / distance / speed | 6.0 / 24t / 6.0 / 18 | — | LOCKED structure；values tune via revision |
| link / cooldown / weakened | 6t / 300t / 150t | — | LOCKED structure；balance review pending |
| weakened damage taken / KB resistance | 1.25 / 0.35 | — | PROVISIONAL-BALANCE |
| blink period / blink telegraph | — | 360t / 18t | LOCKED structure；balance review pending |
| needle telegraph / recover / count | — | 30t / 24t / 3 | LOCKED |
| needle range / speed / angle / damage ratio | — | 5.0 / 10.0 / 60° / 0.75 | PROVISIONAL-BALANCE |
| summon count / local radius | — | 3 / 1.5–2.5 | LOCKED workload；radius tune pending |

固定XP `160/300` 与Risk XP `240`保持 `PROVISIONAL-BALANCE`；每只宝匣资格与4箱hard cap为locked。

## 8. Visual & Audio Requirements

- 巨甲蜈蚣用低宽、多节、贴地重甲轮廓；鬼雾修士用高瘦、无脚悬浮、烟化袍摆轮廓。不得只靠颜色与普通狼/符修或Boss蟒区分。
- 蜈蚣蓄力廊道显示同轴三箭节；每段完成按 `charge_index=1/2/3` exact-once熄灭一节并给一次边界冲击。WEAKENED使用伏地开甲、断盾图形与收拢计时，不显示未冻结的百分比文案。
- blink预警主要画在最终 landing：断环、空心中心、四角定位；原点只留收缩残影。魂针在伤害前显示30 tick的60°瞄准框与三条实体针槽；三条针槽才是实际危险几何，框内空隙不得用实心填充误导，视觉槽宽不得窄于Projectile swept shape。
- 召唤成功只在child实际publish后逐只出现；cluster失败只播一次空心断环“灵力逸散”，成功生成声/尘/命中为0。
- Risk变体用双层断环头标、宝匣章与不同HP框纹样；禁止放大本体、加速动画、扩大技能或增加段数来表现30%。45秒后改为链形“持续追击”，不显示失败或奖励失效。
- 表现优先级：P0 Player/Boss致命/当前Elite危险几何；P1 Elite剪影、Risk章、方向标、入场与破绽；P2 Elite命中/死亡/召唤；P3普通命中、己方装饰与重复数字。池压下先丢P3/P2，P0必须有预加载无粒子fallback。
- 音频优先级为Boss/致命/玩家生命事件 > Elite即将生效动作 > Elite入场/破绽 > 召唤/Risk状态 > 普通反馈。四个同类cue可按稳定identity确定性聚合，但不能遮掉动作种类和最高危险等级。
- 静音与色觉模拟下信息等价：三箭节、断盾、blink断环、魂针硬边、召唤空环、Risk宝匣章均为非颜色通道；立体声方向不得是唯一提示。

## 9. UI Requirements

- Elite不用全屏Boss血条。视野内每只显示compact HP、行为图形与Risk奖励章；离屏方向标至少携带行为轮廓、固定/夺宝标识与同类数量。
- 同方向标可合并外框，但不得隐藏reward-bearing数量或任何已生效危险几何；同种精英仍按enemy identity跟踪。
- 入场提示短句固定为“巨甲蜈蚣来袭：闪开三连冲刺”或“鬼雾修士来袭：避开落点与魂针”；不暂停战斗、不连续弹多页。
- WEAKENED只写“破绽”并显示150 tick视觉计时；Risk 45秒后写“持续追击”，不误导为奖励过期。
- BattleUI只能读 matching presentation view；stale cue、suppressed spawn、未publish summon与replay不得提前显示成功。

## 10. Acceptance Criteria

- **AC-EL01 `[C][BLOCKING]` schema**：两行behavior、两行fixed schedule及FSM/attack/presentation引用缺/重/乱序/hash错误时，Node/Pool创建数0；合法行逐字段读回。
- **AC-EL02 `[U][I][BLOCKING]` schedule**：21600/36000 tick各产生恰一mandatory behavior6/7；Paused不推进，skip-over仍exact-once，terminal后0。
- **AC-EL03 `[U][I][BLOCKING]` Risk parity**：固定/Risk逐字段比较，除HP/base damage×1.30及presentation/provenance外全部相同，额外技能/RNG/drop为0。
- **AC-EL04 `[U][I][BLOCKING]` arrival gate**：固定/Risk×两behavior×屏内/屏外×pause/resume中，`[S,S+59]` damage contribution=0，首伤不早于F6；无cue fallback时不攻击。
- **AC-EL05 `[U][BLOCKING]` centipede FSM**：逐边注入required−1/required/+1 tick和距离，状态精确匹配§3.4，无散文“动画完成”触发。
- **AC-EL06 `[U][I][BLOCKING]` charge geometry**：三段均为6.0、同一axis、不重瞄准；密集敌群轴向反推场景仍各20 tick完成，world越界不clamp。
- **AC-EL07 `[U][I][BLOCKING]` charge hit-once**：每段同一Player最多一条不可暴击intent，三段最多3条；重复overlap、LINK/TRACK/WEAKENED身体接触不多伤。
- **AC-EL08 `[U][I][BLOCKING]` weakened**：窗口149/150/151边界、pause、death与replay下1.25/0.35只在合法窗口生效一次并恢复；第三段末无残留伤害窗。
- **AC-EL09 `[U][BLOCKING]` ghost FSM**：blink360、落点18、魂针30、recover24逐边可判；needle intent在30 tick预警前为0。
- **AC-EL10 `[U][I][BLOCKING]` blink determinism**：固定seed/cycle/Player view输出逐bit一致；cycle变化按hash变化；合法点不改写，越域不publish并fault，runtime RNG calls=0。
- **AC-EL11 `[U][I][BLOCKING]` fan**：三方向恰为−30/0/+30、range5、speed10、lifetime30；每条针槽内/相切/外ε与实际swept shape同源，无“视觉安全但受伤”采样点，三槽间空隙不伪装成实心危险区。
- **AC-EL12 `[U][I][BLOCKING]` projectile atomicity**：intake剩2/3/4行时仅3/4合法发布完整三行；不足不部分发射，Enemy max contribution=9，global sum>32使Loading失败。
- **AC-EL13 `[U][I][BLOCKING]` summon cluster**：0/2/3 Normal剩余槽、任一candidate失败与全成功下，cluster实际数只能0或3；失败72 words、一次逸散、本周期重试0；成功表现只跟actual publish。
- **AC-EL14 `[C][I][BLOCKING]` spawn capacity**：23-row/8-workspace/552-word在required−1/required/+1只接受精确artifact；`12+9+1+1`与互斥的`12+9+2`两类满载均不growth/truncate。
- **AC-EL15 `[U][I][BLOCKING]` summon reward**：ELITE_SUMMON behavior5 death产生XP/utility/treasure/DROP RNG均0；fixed/Risk matching death各自产160/300/240与一箱exact-once。
- **AC-EL16 `[I][BLOCKING]` four-Elite**：298 Normal+4 Elite+1 Boss准入合法；第5 Elite在publish前fault，Normal不可占5个reserved槽，revive clear影响Elite数0。
- **AC-EL17 `[I][BLOCKING]` pause/resume**：所有FSM tick、axis、landing、cycle、hit history和arrival window逐字段冻结；resume无补帧、重复动作或重播。
- **AC-EL18 `[I][BLOCKING]` identity/PONR**：stale borrow、重复plan、death与terminal竞态不误伤新实例、不重复reward或presentation；已PONR事实按owner收敛。
- **AC-EL18b `[I][BLOCKING]` Risk death join**：两次Risk均抽中同一behavior并反序死亡时，八字段death staging的`source_choice_id`分别join正确choice；缺/0/冲突ID在Drop/Risk副作用前fault，fixed行必须为0。
- **AC-EL19 `[P][BLOCKING-TOOLING]` hot path**：FSM/intent/hit/summon backing预分配，10000 tick无allocator/growth/COW、带参signal、Dictionary/Array构造或unstable sort；缺guard/positive control为INCONCLUSIVE。
- **AC-EL20 `[P][E][OPEN-EVIDENCE]` full load**：最低规格Android、release、60Hz下以298+4+1 Enemy、400 attacks、最坏9 summons与完整presentation跑10000 ticks×3，报告phase p50/p95/p99/max及原始counter；缺artifact不得通过。
- **AC-EL21 `[UX][E][OPEN-ASSETS]` silhouette**：5名非作者测试者在三档viewport、灰阶与三类色觉模拟各看24个1秒trial，每人≥22/24且每behavior≥10/12。
- **AC-EL22 `[UX][E][OPEN-ASSETS]` state readability**：三连、段界、破绽、blink、魂针、召唤逸散、Risk七类各4次，每人≥25/28且每类≥3/4。
- **AC-EL23 `[UX][E][OPEN-ASSETS]` dodge direction**：正常音频与静音组分别看18个3秒clip，每人≥16/18且每类≥5/6；两组不可合并过线。
- **AC-EL24 `[V][A][I][BLOCKING-PRESENTATION]` degradation**：逐级耗尽P3/P2/P1，P0 fallback仍存在；gameplay hash、FSM、Damage与Drop逐bit等于完整质量baseline。
- **AC-EL25 `[A][E][OPEN-ASSETS]` audio collision**：4 Elite同tick动作+Boss预警+低HP组合中，高优先级cue被低优先级完全遮盖次数0；静音重跑AC-EL23门槛不降低。

## 11. Open Questions / Blockers

1. **FULL-REVIEW-PENDING**：本文是作者上下文，systems/QA/art输入不是clean-context creative-director verdict。
2. **BLOCKED-WAVE-BALANCE**：只冻结两条fixed Elite锚点；普通波次数量/权重与4 Elite压力曲线仍需WaveSchedule/试玩。
3. **BLOCKED-PROJECTILE-SUM**：本文Elite=9、Boss=8已知；Weapon与behavior2/4 Normal远程checked sum/active仍未知，32/400不可宣称满足。
4. **BLOCKED-HAZARD-TOTAL**：Projectile=400、Boss nonprojectile=2已知，但Enemy nonprojectile/Stage active hazard与`revive_hazard_capacity`未冻结。
5. **BLOCKED-DAMAGE-CAPACITY**：charge/needle/WEAKENED typed producer rows须进入Damage总capacity与first-error ABI；Damage当前仍等待完整producer集合。
6. **BLOCKED-PRESENTATION-ASSETS**：BattleUI与Audio作者GDD已建立；VFX未设计，P0 fallback、atlas、正式音频资产/mix、VFX池与真机可读性证据不存在。
7. **PROVISIONAL-BALANCE/BOUNDS**：base stats、1.25破绽、魂针倍率与shape bounds须经灰盒和Stage/Grid reachability/benchmark修订。
8. **BLOCKED-TREASURE-EXHAUSTION**：40级且无可进化技能时宝匣补偿仍归SkillDraft/Economy待定。
9. **OPEN-ADR/PERF**：Enemy Node拓扑、303实体分离与transform成本仍须ADR和min-spec spike；本文不以静态GDD关闭。
10. **BLOCKED-SELF-DESTRUCT-CONTRACT**：被召唤的behavior5在主概念“接近后自爆”与Enemy现有“HP跨30%触发”间不一致，且是否对ENEMY友伤会改变最坏Damage展开、连锁死亡与奖励归因；须由Normal Enemy/Damage owner裁决，本文不暗改。
