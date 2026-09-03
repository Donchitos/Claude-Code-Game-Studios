# BossStateMachine（守阵妖兽·碧鳞蟒）

> **Status**: Designed / Full Review Pending
> **Author**: 用户 + Codex（lean authoring；consulted systems-designer / ai-programmer / qa-lead / art-director）
> **Created / Last Updated**: 2026-09-03
> **Implements Pillar**: 以可读、可躲的两阶段终局考题，同时检验单体输出、走位、清杂与生存构筑
> **Scope**: MVP production behavior/content contract；不包含完整 WaveSchedule、最终平衡、最终资产或实现 ADR

## 1. Overview

BossStateMachine 是 `behavior_id=8`“守阵妖兽·碧鳞蟒”的行为内容 owner。它冻结 12:00 mandatory 入场、两阶段 FSM、三类基础攻击、Phase 2 毒域收束、双段扑咬、噬灵虫召唤、阶段切换、Boss 致死预览及胜利表现语义。

EnemySystem 继续拥有 `EnemyBossPoolable/v1` 载体、HP、位置、受击、死亡与 lifecycle；SpawnDirector 拥有实际生成与容量准入；ProjectileSystem 拥有毒弹载体；DamageSystem 拥有伤害与 hazard 聚合；GameRoot/BATTLE_RULES 拥有 terminal precollection、核心灵药 REWARD 与 Outcome。BossStateMachine 不创建第二套 Boss Node，不直接写 HP、Pool、Grid、Player 或 Outcome，也不成为新的 GameRoot phase participant；它由 EnemySystem 在既有 ENEMY participant 内按 typed content row 驱动。

旧的固定世界原点 Boss 区和固定竞技场外围毒雾不再生效。Boss 从玩家相对视野外入场；Phase 2 在阶段转换时冻结一次玩家位置为 `encounter_anchor`，以解析式外圆毒域压缩该次遭遇的安全半径。毒域是可进入但会受伤的 hazard，不是碰撞墙、camera clamp 或世界边界。

## 2. Player Fantasy

玩家应感到自己用 12 分钟形成的构筑正在接受一场公平的终局验证，而不是被高数值突然判死：

- Phase 1 先教会三种词汇：直线扑咬要求横移，扇形毒液要求绕侧，环形毒弹要求读相邻弹道间的安全线。
- 每招都遵守“锁向/预警 → 生效 → 后摇”，伤害前至少有形状、姿态两条非颜色通道。
- Phase 2 不把世界重新关进盒子，而是在玩家跨阶段的位置展开一处毒域；安全区逐渐收束，逼迫玩家继续输出并处理召唤物。
- 双扑咬是两次可分辨、可分别闪避的攻击，不是无断点加速长冲；召虫是清杂压力，不偷改 Boss 本体的公平预警。
- Boss 被击败的同 tick 即形成胜利。核心灵药与传送阵是奖励和离场意象，不要求玩家在已结束战斗中再走一次路。

## 3. Detailed Design

### 3.1 权威边界与 Config schema

`BossBehaviorConfigV1` 恰有一行 behavior 8，并进入 `BattleConfigSnapshot` content hash。字段至少为：

`{schema_version,behavior_id,stable_name,base_max_hp,base_damage,move_speed,gameplay_shape_code,shape_bound,knockback_resistance,arrival_lock_ticks,phase_threshold_ratio,fsm_table_id,attack_profile_id,fog_profile_id,summon_profile_id,presentation_profile_id}`。

扩展表为 `BossAttackProfileV1`、`BossFogProfileV1`、`BossSummonProfileV1`、`BossScheduleV1` 与 `BossPresentationManifestV1`。缺行、重行、unknown enum、非 finite 数值、引用断裂、hash mismatch 或错误 schema 都在 Node/Pool 初始化前使 `battle_ready=false`；Active 中不得补默认或热改。

`BossRuntimeStateV1` 在 Loading 预分配，至少包含 `{fsm_state,state_ticks,active_age_ticks,phase_code,phase_transition_pending,phase_transition_generation,attack_slot,action_generation,locked_axis,bite_index,bite_progress,bite_hit_player_borrow_id,fog_anchor,fog_elapsed_ticks,fog_generation,summon_generation,terminal_preview_generation}`。所有字段随 Boss borrow identity reset、snapshot、resume 与 teardown；禁止用 Dictionary、Node metadata、AnimationPlayer callback 或 signal 到达顺序承载玩法状态。

每个 Active tick 最多跨一条有时长边和一条 0-tick提交边，迁移硬上限 2；超过即 fail closed，不允许用 `while` 在一 tick 内吞完整招式链。

### 3.2 12:00 mandatory 入场

- `BOSS_FINAL={due_tick=43200,behavior_id=8,class=BOSS,count=1}`。due tick 指 completed Active gameplay ticks；Paused 不推进，skip-over 仍只生成一次，terminal 已锁定则不生成。
- SpawnDirector 用 phase 开始时 matching Player committed position及四-strip规则在视野外生成。Boss intent priority 高于 Elite、Summon、Normal；无合法位置、Boss reserved slot不可用、Pool borrow失败或Grid publish失败均进入 `ControlledGameplayFault`，不得屏内降级或静默缺 Boss。
- Boss 首次 authority publish tick 为 `S`；同 tick发布 `BossArrivalCueV1`，包含完整 Boss identity、来向、名称、HP bar identity与 50% 阶段刻度。预加载 fallback不可用时 Boss保持不能伤害玩家并走安全故障。
- `ARRIVAL_LOCK=120 Active ticks`。期间 Boss可沿通用 tracking移动、被攻击、击退或击杀，但 damage/projectile/fog/summon contribution均为0；首个攻击还必须满足自身预警，入场门不能替代招式预警。
- 12:00 后不再启动新普通 WaveSchedule row；已在场 Normal/Elite和已PONR spawn/lifecycle继续按各 owner收敛，Phase 2 Boss召虫除外。

### 3.3 顶层 FSM 与确定性轮转

顶层状态图：

`ARRIVAL_LOCK → TRACK_P1 → P1_ACTION → RECOVER → TRACK_P1 → PHASE_SHIFT → TRACK_P2 → P2_ACTION → RECOVER → TRACK_P2 → DEATH_LATCHED`

| State | 可判触发 | Action | Next |
|---|---|---|---|
| `ARRIVAL_LOCK` | `active_age_ticks>=120` | 进攻开放，`attack_slot=0` | `TRACK_P1` |
| `TRACK_P1` | `distance<=9.0` | 按 slot 选择 `BITE/FAN/RING`，冻结action row | 对应telegraph |
| P1 attack | 见 §3.5–3.7 | 生效后进入该招后摇 | `RECOVER` |
| `RECOVER` | 正常为action-specific recover完成；若phase pending则下一`MOVEMENT_COMMIT`立即取消剩余recover | 正常时`attack_slot=(slot+1) mod 3`；pending时不推进slot | `PHASE_SHIFT`或`TRACK_P1` |
| `PHASE_SHIFT` | `state_ticks>=90` | 提交P2、毒域active与`attack_slot=0` | `TRACK_P2` |
| `TRACK_P2` | `distance<=9.0` | 按 slot 选择 `DOUBLE_BITE/FAN/RING/SUMMON` | 对应telegraph |
| P2 attack | 见 §3.5–3.8 | 生效后进入该招后摇 | `RECOVER` |
| `RECOVER` | action-specific recover完成 | `attack_slot=(slot+1) mod 4` | `TRACK_P2` |
| any living | matching predicted Boss HP `<=0` | 停止新攻击并发布terminal preview | `DEATH_LATCHED` |

不新增 Boss RNG stream。两阶段攻击顺序固定，重放结果不依赖 Node 顺序、动画长度、实时随机数或 Player当前方向。TRACK 只负责接近到攻击门；身体普通接触不造成额外伤害。

### 3.4 50% 阶段切换

- 阈值以当前 `resolved_max_hp` 乘 `0.50` 得到。Enemy在phase6实际应用matching Boss aggregate resolution并取得receipt后，以`hp_before>threshold_hp && 0<hp_after<=threshold_hp` exact-once latch `phase_transition_pending=true`；phase5的pure lethal projection不得写该latch。一次伤害跨过阈值、等于阈值、duplicate receipt都只latch一次；HP不回退到P1。
- 若 crossing tick 时 Boss 在 TRACK，下一 Active `MOVEMENT_COMMIT`进入 `PHASE_SHIFT`；若仍在ARRIVAL_LOCK，pending保留至`active_age_ticks>=120`再切阶段，首伤门不得被跳过。若处于尚未跨release PONR的telegraph，取消该未提交招式并在下一 `MOVEMENT_COMMIT`切换；若正在BITE，只收敛至当前18-tick segment边界；FAN/RING已release的effect继续由各owner收敛，但Boss剩余recovery取消。pending后不再启动新的P1动作。
- `PHASE_SHIFT` 持续90 Active ticks，Boss仍可受伤、受击退和死亡，但不产生新攻击或召唤。进入状态时冻结 matching Player committed position为 `fog_anchor`，发布毒域边界预览；毒域伤害与 hazard active window从90 ticks完成后的下一 Active tick开始。
- `on_phase_transition(PHASE_2)` 只在 EnemySystem下一 `MOVEMENT_COMMIT` 调用一次，并只切 FSM/表现/毒域状态，不销毁、重borrow、瞬移Boss，不打断通用分离修正。
- crossing 与 predicted lethal 同tick时只走DEATH，不进入PHASE_SHIFT；Paused期间pending保留但所有时钟和回调推进为0。

### 3.5 直线扑咬与 Phase 2 双扑咬

单段状态为 `TELEGRAPH_BITE → BITE → RECOVER_BITE`。P1 一段；P2 为 `TELEGRAPH_BITE_1 → BITE_1 → TELEGRAPH_BITE_2 → BITE_2 → RECOVER_BITE`。

- 第一段 telegraph 开始时，从 Boss center指向 matching Player center冻结 `locked_axis`；零距离使用 matching spawn facing，仍为finite单位向量。P2 第二段在第一段结束时重新锁向，并显示24 ticks的新廊道，不能在无预警时追踪。
- P1与P2第一段 `telegraph=42 ticks`；P2第二段telegraph=24 ticks。每段 `distance=5.4`、`speed=18.0 units/s`，恰18 Active ticks完成；末tick只提交剩余距离。第二段telegraph期间无扑咬damage。
- 碰撞几何是 Boss gameplay圆形头部沿p0→p1的swept capsule；视觉双獠牙廊道不得窄于实际 swept shape。只对matching Player做直接窄相，不查询不存在的PLAYER Grid。
- 每段对同一 Player borrow最多一条不可暴击伤害，倍率 `1.00 × resolved_base_damage`。hit key为 `{boss_borrow_id,action_generation,bite_index,player_borrow_id}`；TRACK/TELEGRAPH/RECOVER身体接触伤害为0。
- P1/P2后摇均为36 ticks；P2两段之间不进入后摇。分离只保留垂直于locked axis的分量，沿轴反推为0，保证每段18 ticks到达。

### 3.6 扇形毒液

状态为 `TELEGRAPH_FAN → RELEASE_FAN → RECOVER_FAN`：

- telegraph开始时冻结 Boss→Player axis；预警48 ticks，扇形总角70°、半径7.0。
- RELEASE只产生一次直接 `AreaDamageIntentV1`，形状为同源扇形窄相，不生成projectile或持续puddle；扇外与半径外安全。DamageSystem若V1只支持圆形，必须先版本化 area shape ABI，不能用外接圆多伤玩家。
- 命中伤害不可暴击，倍率 `0.70 × resolved_base_damage`；同一action对Player最多一条。后摇48 ticks。
- Phase 1/2参数相同；P2压力来自毒域与动作组合，不缩短预警或扩大扇面。

### 3.7 环形毒弹与 Projectile handoff

状态为 `TELEGRAPH_RING → RELEASE_RING → RECOVER_RING`：

- 预警60 ticks；8枚 `HOSTILE/LINEAR`毒弹按45°等距全圆展开。偶数action generation初相位0°，奇数为22.5°；视觉刻度与实际8条方向同源，安全路线位于相邻弹道之间而非一个固定大缺口。
- 每弹速度6.0 units/s、半径0.18、生命周期120 ticks，只命中Player一次、不可暴击，伤害倍率 `0.25 × resolved_base_damage`。
- 8行是原子 `BossProjectileBatchV1`。tick T Boss只latch计划，Projectile在T+1 `SPAWN_INTENT`完整借出；intake剩7行时不部分发射并进入统一fault。
- Boss pending projectile contribution精确为8 rows/tick，active contribution上界为8。P1完整轮转最短312 ticks，P2完整轮转最短444 ticks，跨阶段最短间隔也大于120 ticks，因此两批Boss毒弹不重叠。全局仍须满足 `Weapon_P + NormalEnemy_P + 9 Elite_P + 8 Boss_P <=32`；Weapon合法loadout与behavior2/4普通远程贡献尚未枚举，因此global pending gate仍BLOCKED，不得把15当Weapon已获配额或在runtime抢占。
- 每枚下一tick危险由ProjectileSystem计入其既有400-row hazard contribution，Boss不得重复登记同一弹道hazard。后摇60 ticks。

### 3.8 Phase 2 毒域收束

毒域使用 `BossFogHazardIntentV2`/`BossFogStateViewV1`：

`{battle/config/tick/authority,boss_identity,fog_generation,shape_code=EXTERIOR_CIRCLE,center=fog_anchor,current_safe_radius,next_safe_radius,active_tick_from,active_tick_through,damage_interval_ticks,damage_ratio,valid}`。

- `fog_anchor`只在进入PHASE_SHIFT时从matching Player committed position冻结一次；不跟Camera、Boss或Player继续移动，也不绑定世界原点。
- 安全半径从10.0在3600 Active ticks内线性收束到4.5，之后保持4.5直到 Boss death/terminal。玩家完整足迹若 `distance(player_center,fog_anchor)+player_radius > current_safe_radius`，即处于危险侧；恰好内切时净空为0且仍安全。毒域不阻挡移动、不clamp、不传送。
- 每60 Active ticks最多提交一条不可暴击Player damage intent，倍率 `0.20 × resolved_base_damage`。进入危险侧或边界本身不会额外即时多跳；离开再进入不重置全局tick cadence。
- Boss非Projectile hazard contribution精确为2：持续fog 1行，加同tick最多1条bite或fan的next-tick保守圆危险。跨文档schema统一为 `ReviveHazardSnapshotV2`，在V1 header/identity/window语义上新增 `shape_codes`，至少支持 `CIRCLE`与`EXTERIOR_CIRCLE`。Player F7按shape计算signed surface clearance，禁止用大外接圆冒充fog；bite/fan可用覆盖真实下一tick几何的保守CIRCLE，不得漏危险。虽然文档合同已传播为V2，精确总容量与运行时copy-out证据仍未闭合。
- Projectile contribution仍为400，故总式为`revive_hazard_capacity=400+EnemyNonProjectile_H+2+Stage_H`。腐毒妖藤/血傀儡与6:00–8:00 Stage区域尚未冻结，最终容量仍 `BLOCKED-HAZARD-TOTAL`，Config不得暂填402。
- 毒雾视觉只读matching state view；危险权威失效前不得先消失，VICTORY/FATAL后不得继续造成玩法伤害。

### 3.9 Phase 2 噬灵虫召唤

状态为 `TELEGRAPH_SUMMON → RELEASE_SUMMON → RECOVER_SUMMON`：

- 预警45 ticks；尾击与两个卵形槽位显示计划数量。RELEASE latch `BossSummonClusterIntentV1`，child count固定2、behavior 0噬灵虫、`spawn_provenance=BOSS_SUMMON`、mandatory=false。
- SpawnDirector下一Active tick按child index 0..1展开，以matching Boss published position为中心在 `[1.5,2.5]` local ring采样；每child固定8 attempts×3 words=24 words，并检查world domain、Stage/hazard禁生区、Player净空与完整footprint。
- cluster采用0或2原子语义：Normal剩余槽少于2、任一candidate失败、source stale或backing不足时生成0、仍消费48 words、播放一次 `SUMMON_DISSIPATED`，本周期不重试。实际2只publish后才播放成功孵化。
- BOSS_SUMMON噬灵虫击杀固定0 XP、0 utility、0 treasure、0 DROP roll；仍占Normal active cap并适用Normal远距无奖励退役。
- Boss进入P2时43200 Boss row及21600/36000 fixed Elite rows已消费，不会再与Boss召虫同tick；因此合法并发上界为 `max(12 Wave+9 Elite summon+1 Elite+1 Boss, 12 Wave+9 Elite summon+2 Boss summon)=23`，position RNG上界仍`23×24=552`。若未来允许12:00后新Elite/Boss mandatory row或Boss召虫数>2，必须先升级capacity。后摇45 ticks。

### 3.10 Boss死亡、终局与奖励

- DamageSystem phase5发布matching resolution后，Boss capability只提供getter-only `BossLethalProjectionInputV1={resolution_publish_token,boss_identity,current_hp,final_damage_to_boss,predicted_post_hp,source_damage_sequence,generation,valid}`；构造过程无owner-state mutation。尚未完整设计的BATTLE_RULES消费它并发布VICTORY preview，供GameRoot在任何phase6 side effect前冻结 `TerminalPrecollectionViewV1`；BossStateMachine不得冒充BATTLE_RULES或自行seal终局。
- terminal总序保持 `FATAL > VICTORY > DEFEAT > PAUSE > NONE`。Boss与Player同tick致死且无FATAL时，VICTORY为唯一winner；Player HP/DAMAGE/DEATH统计事实仍提交，但死亡/复活/败北表现被抑制。
- phase6 EnemySystem应用matching Boss resolution、提交唯一DEATH fact与八字段 `EnemyDeathStagingV2`（`source_choice_id=0`）并按journal回收Boss。BossStateMachine不重复写death。
- BATTLE_RULES只在matching precollected VICTORY下向capacity1 `CoreHerbRewardStageBankV1`提交amount1核心灵药REWARD；phase7 seal同token后才进入Outcome。Boss不产XP、utility、treasure或DROP roll。
- 毒域与新攻击/召唤在terminal preview后关闭；已PONR projectile/damage/death/reward按owner收敛。Boss本体可回池，死亡演出读frozen death position独立完成。
- 核心灵药与传送阵只在sealed VICTORY后作为不可交互结算表现出现，不占Drop/Pool/Grid，不提供拾取半径、碰撞或第二个胜利条件；完成短演出后进入Settlement。

### 3.11 Pause、teardown 与容量贡献

- Pause冻结全部FSM tick、attack slot、locked axis、bite progress/hit history、fog radius/cadence、summon generation与arrival lock；resume从同值继续，不补wall-clock ticks。
- terminal后不启动新动作。teardown先invalid views/capabilities、推进generation，再由Enemy/GameRoot完成Grid/Pool；旧action/hazard/preview不得污染新局。
- BossStateMachine不是独立participant，四类owner orchestration contribution均为0；Boss death lifecycle/fact归ENEMY，核心灵药fact归BATTLE_RULES。BATTLE_RULES的phase row、owner contribution与Outcome字段仍是独立BLOCKED契约，本文不替它填值。
- Boss直接damage producer单tick上界为2：最多1条当前招式直接damage加1条同tick fog damage；Boss projectile spawn为8；Boss非Projectile hazard为2；Boss summon child为2。各owner必须在Config manifest登记，不能把schema hard max当actual required。

## 4. Formulas

### F1 — Phase threshold

The `boss_phase_threshold` formula is defined as:

`threshold_hp = resolved_max_hp * phase_threshold_ratio`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Resolved maximum HP | `Hmax` | float64 | finite, `>0` | Enemy/Config已解析Boss最大HP |
| Phase threshold ratio | `r` | float64 | fixed `0.50` | P1→P2阈值 |
| Applied post HP | `Hp` | float64 | finite, `[0,Hmax]` | phase6 matching Damage resolution实际应用后的HP |

**Output Range:** `threshold_hp=(0,Hmax)`；phase6实际应用后`0<Hp<=threshold_hp`只latch一次P2，`Hp<=0`只走DEATH；phase5 projection写入0。  
**Example:** `resolved_max_hp=12000`时阈值为6000；从6100受伤到6000会latch，受伤到0直接VICTORY preview。

### F2 — Bite movement

The `boss_bite_step` formula is defined as:

`remaining = bite_distance - projected_progress`

`axis_step = min(bite_speed / 60, remaining)`

`committed_delta = locked_axis * axis_step + perpendicular_separation`

`projected_progress_next = projected_progress + dot(committed_delta, locked_axis)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Bite distance | `D` | float64 | fixed `5.4` | 每段轴向总距离 |
| Bite speed | `V` | float64 | fixed `18.0` | world units/s |
| Progress | `p` | float64 | `[0,5.4]` | 当前段已提交轴向距离 |
| Locked axis | `a` | Vector2 | finite unit | 本段telegraph开始锁定 |
| Perpendicular separation | `s` | Vector2 | finite, `dot(s,a)=0` | Enemy分离的合法正交分量 |

**Output Range:** progress单调位于`[0,5.4]`，每段恰18 Active ticks完成。  
**Example:** 每tick轴向步长`18/60=0.3`，第18tick到恰5.4。

### F3 — Attack damage

The `boss_attack_damage` formula is defined as:

`attack_damage = resolved_base_damage * attack_ratio`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Resolved base damage | `B` | float64 | finite, `>0` | stage倍率后Boss基础伤害 |
| Attack ratio | `q` | float64 | `{1.00,0.70,0.25,0.20}` | bite/fan/bullet/fog |

**Output Range:** finite且`>0`；持续毒域、扇面、扑咬、毒弹均不可暴击。  
**Example:** `B=24`时bite=24、fan=16.8、bullet=6、fog tick=4.8。

### F4 — Ring projectile directions

The `boss_ring_direction` formula is defined as:

`initial_deg = (action_generation mod 2) * 22.5`

`direction_i = unit_vector(radians(initial_deg + 45*i))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Projectile index | `i` | int | `[0,7]` | 固定stable row order |
| Action generation | `G` | int64 | non-negative | 奇偶决定初相位 |
| Offset | `o_i` | degrees | `initial+45*i` | 八条等距弹道 |

**Output Range:** 恰8个finite单位方向且首尾不重复；相邻弹道夹角45°。  
**Example:** 偶数generation为0/45/.../315°；奇数为22.5/67.5/.../337.5°。

### F5 — Fog safe radius

The `boss_fog_safe_radius` formula is defined as:

`u = clamp(fog_elapsed_ticks / fog_shrink_ticks, 0, 1)`

`safe_radius = start_radius + (end_radius - start_radius) * u`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Fog elapsed ticks | `t` | int64 | `[0,+max]` | P2毒域active后的Active ticks |
| Shrink ticks | `Ts` | int64 | fixed `3600` | 收束持续时间 |
| Start radius | `R0` | float64 | fixed `10.0` | 初始安全半径 |
| End radius | `R1` | float64 | fixed `4.5` | 最终安全半径 |

**Output Range:** `[4.5,10]`且单调不增；Paused时`t`不变。  
**Example:** t=1800时u=0.5，safe radius=7.25；t>=3600时保持4.5。

### F6 — Shape-aware revive clearance

The `revive_hazard_surface_clearance_v2` formula is defined as:

`circle_clearance = distance(candidate, center) - (hazard_radius + player_radius)`

`exterior_clearance = safe_radius - (distance(candidate, center) + player_radius)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Candidate/center | `P/C` | Vector2 | finite world domain | 复活候选与hazard中心 |
| Hazard or safe radius | `R` | float64 | finite, `>=0` | shape_code解释其语义 |
| Player radius | `Rp` | float64 | finite, `>0` | 玩家实际碰撞圆半径 |
| Shape code | `S` | int | `CIRCLE/EXTERIOR_CIRCLE` | V2封闭enum |

**Output Range:** finite signed distance。`CIRCLE`中`>0`安全、`<=0`危险；`EXTERIOR_CIRCLE`中`>=0`安全、`<0`危险，因为0表示玩家足迹仍恰好完整位于安全圆内。  
**Example:** fog safe radius4.5、candidate距center3、player radius0.4时clearance=1.1；距4.1时为0且安全，再外移任意正ε才危险。

### F7 — Spawn workload

The `boss_spawn_workload` formula is defined as:

`max_spawn_intents = max(wave_normal + elite_summon + elite + boss, wave_normal + elite_summon + boss_summon)`

`max_spawn_rng_words = max_spawn_intents * candidate_attempts * words_per_attempt`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Wave rows | `W` | int | fixed `12` | 单tickWave Normal上界 |
| Elite summon rows | `E` | int | fixed `9` | 三鬼修×三血傀儡 |
| Boss summon rows | `B` | int | fixed `2` | 本文0/2噬灵虫 |
| Scheduled Elite/Boss | `Fe/Fb` | int | fixed `1/1` | 保守mandatory行 |
| Attempts/words | `A/K` | int | fixed `8/3` | 每intent固定RNG预算 |

**Output Range:** intent capacity23、position RNG word上界552；checked arithmetic overflow在Loading失败。  
**Example:** `max(12+9+1+1,12+9+2)=23`，`23×8×3=552`。

### F8 — Projectile producer sum

The `projectile_pending_checked_sum` formula is defined as:

`pending_total = weapon_pending + normal_enemy_pending + elite_pending + boss_pending`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Weapon pending | `Wp` | int | `[0,32]` | 最终SkillConfig合法loadout枚举值 |
| Normal Enemy pending | `Np` | int | `[0,32]` | behavior2/4等普通远程上界 |
| Elite pending | `Ep` | int | fixed `9` | Elite GDD上界 |
| Boss pending | `Bp` | int | fixed `8` | 本文环形毒弹上界 |

**Output Range:** 必须`<=32`；已知Elite+Boss占17，但不能忽略`Np`。  
**Example:** `Wp=13,Np=2`时总计32可admit；`Wp=14,Np=2`时33，Battle Loading失败。

## 5. Edge Cases

1. Boss在ARRIVAL_LOCK被击杀：攻击/毒域/召虫为0，仍按Boss death产生VICTORY与核心灵药。
2. 43200 tick到达时Boss已存在：mandatory duplicate matching为OK_NOOP；不同identity为fault，不借第二个Boss。
3. Boss spawn无合法屏外位置：进入ControlledGameplayFault，不在屏内或世界原点生成。
4. 阈值刚好50%：latch P2；大额伤害到0：直接DEATH，不播阶段转换。
5. threshold crossing发生在telegraph：release PONR前取消；发生在BITE则收敛当前18t segment；已release projectile继续但recovery取消。pending阻止下一P1动作。
6. phase pending期间pause：所有state tick冻结；resume不重播crossing或补90 tick。
7. PHASE_SHIFT中Boss死亡：毒域damage仍未开放；直接VICTORY，阶段表现取消并按winner降级。
8. P2第二扑开始前Player穿到Boss背后：第二段在LINK末重新锁向并重新预警；第一段不追踪。
9. 扑咬密集分离：轴向反推为0、正交分量保留；每段仍18 ticks完成且同Player最多一伤。
10. Fan shape ABI仅有circle：load失败，不以外接圆继续造成扇外伤害。
11. Projectile intake仅7行：8弹原子batch不发布；visual/audio success为0，旧bank保持。
12. 环弹相邻两条轨迹之间存在可走安全线；奇偶generation初相位交替，视觉刻度与实际方向逐行一致。
13. fog安全圆内边界恰好容纳Player完整足迹：视为安全；再外移任意正ε才危险，视觉硬边必须覆盖该分界线。
14. Player跑出局部遭遇域：不碰墙或clamp，按同一外圆毒域cadence受伤；复活评分也视为危险。
15. ReviveHazard V1被注入Phase2：schema mismatch fail closed，不把unknown exterior hazard当安全。
16. Boss summon时Normal只剩0..1槽或第N个candidate失败：整cluster为0，48 words仍消费，本周期不重试。
17. Boss summonlatch后Boss死亡：terminal gate取消尚未PONR cluster；已PONR child按Spawn owner收敛但为禁奖Normal。
18. Boss与Player同tick致死：无FATAL时VICTORY；保留Player统计事实，抑制死亡/复活/败北表现。
19. VICTORY后毒雾视觉先退：只有matching hazard失效后可退；不可出现隐形伤害或仍可伤害的结算画面。
20. teardown/new battle收到旧preview/action/hazard：generation mismatch，所有玩法与表现写入为0。

## 6. Dependencies

| System | Contract / status |
|---|---|
| EnemySystem | Boss载体、HP/lifecycle、tracking/separation、behavior driver与death staging；文档已接纳本文为behavior8唯一内容owner，runtime待实现 |
| SpawnDirector | 43200 mandatory intent、Boss local summon、时序互斥下保持23-row/552-word workload；文档合同已同步，runtime待实现 |
| DamageSystem | Boss direct damage上界2、扇形shape、fog hazard V2与terminal resolution；hazard文档合同已同步，area ABI/runtime仍待完成 |
| ProjectileSystem | 8弹原子batch、Boss pending/active=8；Designed，global producer sum仍BLOCKED-WEAPON |
| PlayerController | matching位置、Player半径、V2 exterior hazard clearance；文档已升级V2，精确容量与runtime集成仍BLOCKED |
| Stage & Map | player-relative offscreen、world_safe_aabb、无固定arena；In Review / Re-review Pending |
| Config/Data | Boss一行profile/FSM/hash、producer maxima、23/552互斥证明与V2 hazard；In Review / Re-review Pending |
| GameRoot/BATTLE_RULES | terminal precollection、VICTORY优先、CoreHerb stage、Settlement handoff；In Review / Re-review Pending |
| Drop + Leveling | Boss无Drop gameplay、核心灵药只走BATTLE_RULES；Designed |
| Elite Enemies | 同屏可读优先级、Elite pending9/summon9；Designed |
| BattleUI / Audio / VFX | BattleUI与Audio作者GDD已冻结Boss bar/phase/方向、危险voice和P0语义；正式Boss presentation/audio rows及runtime仍BLOCKED，VFX未设计 |

## 7. Tuning Knobs

以下base stats与伤害倍率为 `PROVISIONAL-BALANCE` 首个production graybox值；FSM结构、次数、typed边界与容量上界为locked contract。

| Knob | MVP value | Status |
|---|---:|---|
| base max HP | 3000 | PROVISIONAL-BALANCE；stage12倍率3.0后为9000 |
| base damage | 12 | PROVISIONAL-BALANCE；stage12倍率后约29.28 |
| move speed | 1.5 | PROVISIONAL-BALANCE；stage12倍率1.35后为2.025 |
| gameplay shape | CIRCLE, radius1.2 | PROVISIONAL-BOUNDS；装饰尾巴不得造成接触伤害 |
| knockback resistance | 0.90 | PROVISIONAL-BALANCE |
| due / arrival lock | 43200 / 120 ticks | LOCKED |
| phase threshold / shift | 0.50 / 90 ticks | LOCKED structure |
| trigger range | 9.0 | PROVISIONAL-BALANCE |
| bite telegraph1/telegraph2/distance/speed/recover | 42t / 24t / 5.4 / 18 / 36t | LOCKED structure；balance tune by revision |
| fan telegraph / angle / radius / recover | 48t / 70° / 7.0 / 48t | LOCKED structure；shape ABI blocked |
| ring telegraph / count / phase / speed / radius / lifetime / recover | 60t / 8 / 0°或22.5° / 6 / 0.18 / 120t / 60t | count/pending locked；balance provisional |
| fog start/end/shrink/interval | 10.0 / 4.5 / 3600t / 60t | structure/capacity locked；balance provisional |
| summon telegraph/count/ring/recover | 45t / 2 / 1.5–2.5 / 45t | count/workload locked；radius provisional |
| damage ratios bite/fan/bullet/fog | 1.00 / 0.70 / 0.25 / 0.20 | PROVISIONAL-BALANCE |

## 8. Visual & Audio Requirements

- 碧鳞蟒采用连续S形长身、冠鳞大头、抬颈与毒腺轮廓；巨甲蜈蚣保持低宽、多足、离散甲节。不能只靠体积或绿色区分。gameplay可伤圆只覆盖头颈主体，装饰尾段不得暗示接触伤害。
- 入场不抢镜头或锁输入：屏外蛇影、低频地纹、方向标、Boss名与50%刻度HP bar同tick出现；banner不得遮Player、危险几何或摇杆。
- P1鳞片闭合；P2用外翻裂鳞、张冠、持续毒雾尾迹与Boss bar断段，不以全身染红作为唯一差异。
- 扑咬为收颈S弯+双獠牙硬边廊道；Fan为毒腺膨胀+锯齿扇边/液滴纹；Ring为盘身+八枚方向刻度，并清楚保留相邻弹道间的安全线；三者姿态、几何与音色均不同。
- Fog以交叉鳞纹、蛇牙硬边和向内箭纹显示真实EXTERIOR_CIRCLE边界；体积雾位于角色/预警下层。不能按圆周动态实例化Node/粒子，低端先去体积感但保留硬边与危险侧。
- 召虫显示两个卵槽；只有2只actual publish才播放集群成功，0只只播一次巢纹逸散。禁奖召唤物不得有灵气尾迹或奖励音。
- Boss受击用局部鳞片火花/头部微顿并聚合同tick多hit；不得让全身闪白遮掉当前预警。死亡为冠鳞折落、蛇身盘倒、毒域外散；核心灵药清鸣和传送阵只在sealed VICTORY后出现。
- 表现优先级：P0 Player轮廓、Boss/Elite会生效危险、fog边界、终局关键状态；P1 Boss朝向/阶段/HP bar/下一收束预览；P2召虫、阶段/死亡高级效果；P3普通hit、友方装饰和环境微粒。压力下降级P3→P2，P0必须有预加载无粒子fallback。
- 音频优先级为Player致命/复活/终局与Boss即将生效攻击 > Boss release/fog首次侵入 > Elite即将生效攻击 > Boss入场/阶段/后摇 > summon/hit/ambience > Normal/装饰。毒雾持续伤害限频，不逐tick蜂鸣；立体声与震动不是唯一提示。
- 精确色板、材质、帧数、shader、audio bus/duck、VFX池与GPU降级阈值因正式Art Bible/Audio/VFX GDD缺失保持 `BLOCKED-ASSET`。

## 9. UI Requirements

- Boss authority publish后显示唯一全宽Boss HP bar，标题“守阵妖兽·碧鳞蟒”，50%刻度可见；离屏时保持蛇首方向标。UI只读matching Boss presentation view，不持有HP或阶段权威。
- Phase 2只提示一次“碧鳞毒域展开”；Boss bar纹样切换与50%断刻必须来自matching phase generation。stale/replay不重播。
- 当前动作只显示一项必要信息：双扑咬段数、环弹安全线或下一次fog收束预览，不叠加长篇教学。危险世界几何是主通道，HUD不能成为唯一警告。
- Fog外侧显示克制的非颜色危险状态图标；不把vignette覆盖摇杆。替身符UNSAFE_FALLBACK不得被错误画成安全/无敌。
- 核心灵药与传送阵无“靠近拾取/点击离开”按钮；sealed VICTORY后自动进入短演出与Settlement。FATAL时所有成功UI为0。
- 所有Boss屏幕空间表现 `mouse_filter=IGNORE`，不能抢单摇杆触点。具体布局、safe area、字体和多分辨率规范归BattleUI/UX。

## 10. Acceptance Criteria

- **AC-BS01 `[C][BLOCKING]` schema**：**GIVEN** Boss/profile/FSM/attack/fog/summon/presentation表缺/重/乱序/hash错误，**WHEN** Config build，**THEN** Node/Pool创建数0；合法唯一behavior8逐字段readback。
- **AC-BS02 `[U][I][BLOCKING]` schedule**：**GIVEN** 43200前/等于/skip-over、Paused、terminal和existing Boss，**WHEN** SpawnDirector执行，**THEN**仅合法路径产生一次mandatory behavior8；无位置/slot失败进入fault且屏内/world-origin降级为0。
- **AC-BS03 `[U][I][BLOCKING]` arrival gate**：**GIVEN** 四个屏外方向、4 Elite同屏、arrival期间跨50%及pause/resume，**WHEN** Boss publish tick为S，**THEN** `[S,S+119]` Boss damage/projectile/fog/summon=0；早期phase pending保留到arrival完成后才进入PHASE_SHIFT，首伤不早于arrival、phase shift与attack telegraph共同结束。
- **AC-BS04 `[U][BLOCKING]` FSM rows**：**GIVEN** 每条状态边required−1/required/+1 ticks、距离8.999/9/9.001，并在轮转计时fixture中让每次TRACK入口均已处于攻击门内，**WHEN**逐tick执行，**THEN**P1纯动作轮转312t、P2纯动作轮转444t；门外只增加确定性TRACK时长，状态/slot/transition逐字段等于§3.3，无animation callback或随机分支。
- **AC-BS05 `[U][I][BLOCKING]` phase threshold/safe beat**：**GIVEN** HP above/equal/below50%、跨阈值、lethal、duplicate/stale且发生在每个attack state，**WHEN** phase6实际应用matching resolution与receipt，**THEN** P2仅exact-once latch且phase5 projection的latch写入为0；未release telegraph取消、bite收敛当前segment、已release projectile继续而recovery取消，lethal不shift，pending后新P1 action=0。
- **AC-BS06 `[U][I][BLOCKING]` phase shift**：**GIVEN** matching/stale Player position、pause与shift中death，**WHEN**进入90t PHASE_SHIFT，**THEN** anchor只冻结matching committed position，不瞬移/reborrow、不攻击；Paused不推进，death直接terminal。
- **AC-BS07 `[U][I][BLOCKING]` bite geometry/timing**：**GIVEN** P1一段/P2两段、Player穿背、密集分离及廊道内/相切/外ε，**WHEN**扑咬，**THEN**每段18t/5.4units、P2第二段重锁并预警24t、同Player每段最多一伤，视觉安全点受伤数0。
- **AC-BS08 `[U][I][BLOCKING]` fan shape**：**GIVEN** 70°/7.0扇内/边/外ε及仅circle ABI，**WHEN**释放，**THEN**只合法扇区最多一伤、无puddle；旧ABI使load失败而非外接圆运行。
- **AC-BS09 `[U][I][BLOCKING]` ring directions**：**GIVEN** 八offset、generation奇偶与轨迹内/相切/外ε，**WHEN**释放，**THEN**恰8条45°等距方向、初相位0°/22.5°、6 speed/120t；首尾不重复且视觉同源。
- **AC-BS10 `[U][I][BLOCKING]` projectile atomicity**：**GIVEN** intake7/8/9、stale source与重放，**WHEN** T latch/T+1 spawn，**THEN**只有8/9发布完整8行；T内spawn/move/hit=0，不部分发射，Boss pending/active贡献均8。
- **AC-BS11 `[U][I][BLOCKING]` fog radius/cadence**：**GIVEN** t=0/1799/1800/3599/3600/3601、Paused及Player足迹在内/恰好内切/外ε，**WHEN**F5与damage cadence运行，**THEN**半径10/7.25/4.5单调，内切安全、外ε每60t最多一伤，进入退出不重置cadence，无墙/clamp。
- **AC-BS12 `[U][I][BLOCKING]` hazard V2**：**GIVEN** CIRCLE/EXTERIOR_CIRCLE及V1/stale/conflict、17 revive candidates，**WHEN**F6聚合，**THEN**shape-aware clearance与独立golden一致；V1/unknown fail closed，Boss fog contribution恰1，替身符不清hazard。
- **AC-BS13 `[U][I][BLOCKING]` summon 0-or-2**：**GIVEN** Normal剩余0..3、任一candidate失败、stale source与成功，**WHEN**展开，**THEN**actual count仅0或2；失败仍48 words/一次逸散/零重试，成功表现只在actual publish后。
- **AC-BS14 `[C][I][BLOCKING]` Spawn capacity**：**GIVEN** bank22/23/24、两类23-intent互斥满载fixture及非法12:00后额外mandatory row，**WHEN** Config/Spawn执行，**THEN**仅23为production exact并消费552 words；非法调度必须先升级容量，不能越界写；active caps与Pool容量不变。
- **AC-BS15 `[U][I][BLOCKING]` summon reward**：**GIVEN** BOSS_SUMMON噬灵虫death/retire与普通Wave虫positive control，**WHEN** Drop处理，**THEN**前者XP/utility/treasure/DROP calls均0，后者按既有behavior0规则结算。
- **AC-BS16 `[U][I][BLOCKING]` damage maxima/formulas**：**GIVEN** action+fog同tick及F1–F3边界/非finite，**WHEN** Damage staging，**THEN** Boss direct rows最多2、倍率逐值正确、异常在publish前fault且旧bank不变。
- **AC-BS17 `[C][BLOCKING][OPEN-WEAPON/NORMAL]` projectile checked sum**：**GIVEN** Weapon_P+NormalEnemy_P=14/15/16、Elite9、Boss8，**WHEN** Loading F8，**THEN**31/32通过、33拒绝；Weapon和behavior2/4枚举artifact缺失时gate不能PASS。
- **AC-BS18 `[U][I][BLOCKING]` terminal preview**：**GIVEN** Boss nonlethal/lethal、Player lethal、FATAL、pause、duplicate/conflict与phase5/6各checkpoint，**WHEN** precollection/authority/seal运行，**THEN**总序`FATAL>VICTORY>DEFEAT>PAUSE`，Boss+Player lethal为VICTORY且事实保留/死亡表现抑制，phase7不首次发现胜利。
- **AC-BS19 `[U][I][BLOCKING]` core herb/portal**：**GIVEN** normal VICTORY、VICTORY+lethal、FATAL、duplicate/stale与stage capacity0/1/2，**WHEN** BATTLE_RULES按matching precollection在phase6提交奖励、再由Outcome seal同token，**THEN**仅该sealed VICTORY对外暴露一次amount1核心灵药和不可交互传送阵；Drop/Pool/Grid/input写入0，seal前stage row不得被表现层读取。
- **AC-BS20 `[I][BLOCKING]` pause/teardown/identity**：**GIVEN** 每个FSM状态pause/resume及teardown/new battle旧action/hazard/preview，**WHEN**运行，**THEN**所有计时与state冻结恢复、无补帧/重播，旧generation写入0。
- **AC-BS21 `[P][BLOCKING-TOOLING]` hot path**：**GIVEN** production roots、known-good/bad fixture与native allowlist，**WHEN**10000 ticks，**THEN** FSM/hazard/action backing无allocator/growth/COW、Dictionary/Array构造、带参signal、unstable sort或runtime resource/node创建；缺guard/positive control为INCONCLUSIVE。
- **AC-BS22 `[P][E][OPEN-EVIDENCE]` full load**：**GIVEN** min-spec Android release、298 Normal+4 Elite+1 Boss+400 attacks+Phase2 fog+完整构筑，**WHEN**10000 ticks×3，**THEN**报告CPU/GPU p50/p95/p99/max、draw/overdraw/pool/counters且gameplay overflow=0；缺artifact/device/raw sample不能PASS。
- **AC-BS23 `[UX][E][OPEN-ASSETS]` silhouette/readability**：**GIVEN**5名非作者、三档viewport、灰阶与三类色觉模拟，**WHEN**观看Boss/蜈蚣/普通敌24个1秒trial及五类Boss动作各4个clip，**THEN**每人剪影≥22/24且Boss≥11/12，动作≥18/20且每类≥3/4。
- **AC-BS24 `[UX][E][OPEN-ASSETS]` dodge direction**：**GIVEN**正常音频与静音各24个3秒clip，覆盖bite/fan/ring/fog，**WHEN**危险首次可见后1秒内选择安全方向，**THEN**每人每组≥21/24且每类≥5/6；两组不可合并。
- **AC-BS25 `[V][A][I][BLOCKING-PRESENTATION]` priority/degradation**：**GIVEN**Boss+4 Elite预警、低HP/复活与逐级耗尽P3/P2/P1，**WHEN**表现压力运行，**THEN**P0危险、Player轮廓与terminal cue丢失/完全遮挡帧数0，gameplay/Damage/Projectile/hazard/terminal hash与完整质量baseline一致。

## 11. Open Questions / Blockers

1. **FULL-REVIEW-PENDING**：本文为作者上下文；systems/QA/art输入不是clean-context creative-director verdict。
2. **BLOCKED-PROJECTILE-SUM**：Boss=8、Elite=9已冻结，但Weapon合法SkillConfig与behavior2/4普通远程贡献未枚举；global pending/active和仍未闭合。
3. **BLOCKED-HAZARD-TOTAL**：Projectile=400、Boss nonprojectile=2已知，但腐毒妖藤/血傀儡与6:00–8:00场地区域上界未设计，`400+EnemyNonProjectile_H+2+Stage_H`不能冻结。
4. **BLOCKED-HAZARD-V2-INTEGRATION**：Player/Damage/Config文档已同步V2 shape code与F7语义，但精确总容量、运行时copy-out、required±1及跨owner集成证据仍缺失；这些证据存在前不可实现复活production路径。
5. **BLOCKED-AREA-SHAPE-ABI**：Damage `AreaDamageIntentV1`当前只冻结圆形；扇形毒液须先升级typed shape ABI，禁止外接圆近似。
6. **BLOCKED-DAMAGE-CAPACITY**：Boss direct rows=2已知，但全producer Damage intent/contribution/receipt exact capacities仍未闭合。
7. **BLOCKED-WAVE-BALANCE**：12:00后停新普通波次已定；Boss入场时在场怪群、三构筑DPS与13–15分钟完成率仍须WaveSchedule和试玩。
8. **PROVISIONAL-BALANCE/BOUNDS**：Boss base stats、全部倍率、范围、fog半径/伤害与shape bound须灰盒、Stage reachability与min-spec验证。
9. **BLOCKED-PRESENTATION-ASSETS**：BattleUI/Audio作者GDD已建立，但无正式Art/Sound Bible、VFX GDD或P0 fallback资产；可读性、色弱、静音、GPU与音频碰撞证据不存在。
10. **BLOCKED-BATTLE-RULES**：BATTLE_RULES phase row、terminal producer、owner contribution、Boss lethal projection消费与death→reward预留顺序尚未有完整GDD；本文不冒充其owner。
11. **BLOCKED-WORKLOAD-REGEN**：GameRoot现有RuntimeWorkloadManifest仍与400 Projectile/300 Drop权威上限冲突；Boss Phase2 fixture必须随整表重生成。
12. **BLOCKED-SELF-DESTRUCT-CONTRACT**：Elite/Boss召唤链可能同屏出现behavior5血傀儡，其接近/30%HP自爆、友伤和连锁容量仍待Normal Enemy/Damage owner裁决。
13. **OPEN-ADR/PERF**：Boss长身视觉与圆形gameplay carrier边界、Enemy节点拓扑、tail无碰撞表达及固定fog renderer实现需ADR/asset spec；本GDD不以静态文字关闭。
