# Enemy System GDD

> Status: DRAFT — Designed under /design-system enemy-system (lean review mode)
> Owner: systems-designer + ai-programmer
> Depends on: SpatialGrid (Approved), Object Pooling (Approved), Config/Data (Draft, foundation frozen)
> Depended on by: SpawnDirector, DropSystem, RiskChoiceSystem, BossStateMachine, Elite Enemies (all Not Started)
> Engine: Godot 4.7.1 | Language: GDScript
> Pillar alignment: 300-entity onscreen smoothness + swarm-slaughter satisfaction (infrastructure)
> High-Risk: node architecture (lightweight Node2D + manual update vs CharacterBody2D + physics-driven) — deferred to /architecture-decision ADR

---

## 1. Overview

EnemySystem 是掌天试炼战场中所有敌人的行为与生命周期基础设施。它负责 6
种普通敌人(噬灵虫/铁背妖狼/腐毒妖藤/甲壳妖虫/魔道符修/血傀儡,共享
`EnemyNormalPoolable/v1` 契约,以 config behavior ID 区分)、2 种精英
(巨甲蜈蚣/鬼雾修士,`EnemyElitePoolable/v1` 契约,有限状态机归本 GDD)
与 Boss 载体(碧鳞蟒,`EnemyBossPoolable/v1` 契约;阶段切换 FSM 归
BossStateMachine #18,本 GDD 只定义其生命/池化/基础追踪/受击/死亡)的
生命周期、移动、分离与 GameRoot phase 参与。它向 SpawnDirector 提供借出/
回收接口与 spawn_context schema(何时何地刷何种敌人由 SpawnDirector 决定),
向 DropSystem 发布死亡事件,向 SpatialGrid 以 ENEMY 类型注册并按固定 phase
(insert@SPAWN_INTENT / stage@MOVEMENT_COMMIT / remove@DEFERRED_REMOVAL)
同步位置。在 300 普通敌人同屏(303 cap 含 2 精英 + 1 Boss 预留)硬约束下,
EnemySystem 冻结行为契约——直线追踪(不完整寻路)、轻量分离(SpatialGrid
query,非刚体碰撞)、屏幕外行为/动画降频、对象池零分配 reset;节点架构与
碰撞实现方式(Node2D 手动更新 vs CharacterBody2D 物理驱动)作为 High-Risk
决策 defer `/architecture-decision` ADR,本 GDD 只描述与实现无关的行为契约。

## 2. Player Fantasy

EnemySystem 支撑的核心幻想是**被怪潮包围但仍能掌控战局**的割草爽快。玩家
应感受到四层:

1. **压迫感**:敌人从屏幕边缘环带源源涌入,数量随时间攀升至 300 同屏,形成
   四面楚歌的密度压力,但每帧流畅——性能是幻想的物理基础,卡顿即破幻想。
2. **可读性**:6 种普通敌人各有鲜明行为剪影(直线追踪/蓄力冲刺/固定喷毒/
   抗击退/远程符弹/自爆预警),玩家 1-2 秒内识别威胁类型并做战术取舍:优先
   清远程?拉开自爆?绕行毒藤?
3. **节拍感**:节奏表驱动的怪潮组合随分钟推进,精英(6:00 巨甲蜈蚣/10:00
   鬼雾修士)出场带"小 Boss + 法宝匣"奖励期待,Boss(12:00 碧鳞蟒)出场带
   两阶段仪式感。
4. **击杀反馈**:死亡即时回收 + 掉落发布,屏幕清空感与战利品期待并存。

阶段倍率以分钟配置、数据驱动,优先通过组合/密度/行为调整难度而非单纯堆血
——保证后期怪潮"更乱更密"而非"更肉更慢",维持割草爽快到底。

## 3. Detailed Design

### 3.1 敌人分类与 pool 归属

| 类别 | pool_key | capacity | factory_contract | 同屏上界 | FSM 归属 |
|---|---|---|---|---|---|
| 普通敌人(6 种) | enemy_normal=1 | 320 | EnemyNormalPoolable/v1 | 300 | 无(直线追踪,数据驱动) |
| 精英(2 种) | enemy_elite=2 | 6 | EnemyElitePoolable/v1 | 2 | 本 GDD |
| Boss 载体 | enemy_boss=3 | 1 | EnemyBossPoolable/v1 | 1 | 阶段切换 defer #18 |

303 cap = 300 普通 + 2 精英 + 1 Boss 预留(SpatialGrid R9 / Config R6)。

### 3.2 Behavior ID 数据驱动

按 pool_key 分组共享 Poolable contract,以 `behavior_id` 区分具体敌人:

| behavior_id | 名称 | pool | 行为剪影 |
|---|---|---|---|
| 0 | 噬灵虫 | normal | 直线追踪/低生命/数量多 |
| 1 | 铁背妖狼 | normal | 快速/蓄力冲刺/走位减速 |
| 2 | 腐毒妖藤 | normal | 固定原地/周期喷毒液 |
| 3 | 甲壳妖虫 | normal | 高生命/抗击退/持续伤害 |
| 4 | 魔道符修 | normal | 保持距离/发射符弹 |
| 5 | 血傀儡 | normal | 接近自爆/死亡预警 |
| 6 | 巨甲蜈蚣 | elite | 高生命/高击退抗性/连续冲刺3次/虚弱 |
| 7 | 鬼雾修士 | elite | 周期瞬移/扇形魂针/召唤血傀儡 |
| 8 | 碧鳞蟒(载体) | boss | 基础追踪/受击/死亡;阶段 defer #18 |

`behavior_id` 是 spawn_context 首字段,索引 Config behavior 表(属性/动画/
攻击定义)。Config 维护 ID→资源映射;EnemySystem 只消费 `behavior_id`,
不硬编码敌人类型。

### 3.3 spawn_context schema

EnemySystem 冻结 enemy spawn_context(5 primitive 字段,BATTLE_LOADING
预分配、caller-owned carrier,runtime 只覆写):

```
spawn_context = {
    behavior_id: int,              # 0-8
    spawn_position: Vector2,      # Stage spawn ring 内侧环带点
    spawn_facing: Vector2,         # 初始朝向(通常朝玩家)
    spawn_time_seconds: float,    # 生成时刻(存活/阶段倍率查询)
    spawn_seed: int               # SpawnDirector 从 run_seed 派生
}
```

阶段倍率/属性/动画由 `behavior_id` 查 Config,**不**入 spawn_context。
按 pool_key 版本化:三个 Poolable/v1 各自解析这 5 字段(语义同,解析路径
按 contract 版本)。spawn_seed 由 SpawnDirector 从全局 run_seed(RNG
GATE-G2)派生;EnemySystem 不直接依赖 RNG。

### 3.4 Poolable contract 实现

每个 pooled 敌人 Node 实现 Object Pooling R3:

- `reset_for_borrow(borrow_id, spawn_context)`:读 spawn_context 5 字段 →
  查 Config behavior 表设属性/动画/初始状态。**不在此 insert SpatialGrid**
  (insert 在 SPAWN_INTENT phase 由 EnemySystem 统一执行,保证 phase 一致性)。
- `reset_for_pool()`:unbind `remove(handle, lease)`(BLOCKING)→ 清 AC-B2
  字段(Timer/Tween/target/damage/pierce/Buff/signal/collision/visibility)。

零分配 reset hook(R3):main-thread、禁 `set_deferred`/`call_deferred`/
`create_tween`/`Array.clear`/`Dictionary`/`connect`-`disconnect`/`String`
字面量;用 `PackedXxxArray.clear()` + 预加载 `AnimationPlayer` + warmup
缓存 `StringName`(`^"..."`)。

carrier(R2):`pool_epoch`/`borrow_id`/`object_instance_id`/`pool_key`/
`slot_id`/`generation` + `node_ref`(弱引用)+ `spatial_handle_id`(bind
时填)+ `quarantine_revision`。

### 3.5 移动行为:直线追踪(普通敌人)

普通敌人不使用完整寻路(source §15.4 第2条),只朝玩家直线移动:

```
direction = Normalize(player_position - enemy_position)
displacement = direction × move_speed × delta_time × stage_move_multiplier
```

无 NavigationServer(300 实体不需要)。移动在 MOVEMENT_COMMIT phase 逐 handle
计算,调 `stage_position(handle, committed_pos, lease)`(grid 在 GRID_SYNC
统一 commit)。分离修正(3.8)叠加到 committed_pos。

### 3.6 精英 FSM

精英用有限状态机(source §15.5):

- **巨甲蜈蚣(6)**:`TRACK → TELEGRAPH_CHARGE → CHARGE(×3) → WEAKENED →
  TRACK` 循环;冲刺后虚弱窗口。
- **鬼雾修士(7)**:`TRACK → BLINK → FAN_NEEDLE → SUMMON_BLOOD_PUPPET →
  TRACK` 循环;瞬移后扇形魂针,周期召唤血傀儡(behavior_id=5)。

FSM 由 EnemyElitePoolable 在 run_phase 内驱动;状态切换由计时器/距离/事件
触发,无随机(抖动由 spawn_seed 派生,非状态选择)。精英技能伤害/范围/
投射物归 Combat/ProjectileSystem;EnemySystem 只定义状态流转与技能**释放
意图**(发信号给 Combat)。召唤血傀儡通过发信号给 SpawnDirector 执行
borrow(保持 admission check 一致性,精英不直接借 pool)。

### 3.7 Boss 载体行为

碧鳞蟒(8)本 GDD 只定义载体:生命/池化/基础追踪/受击/死亡(与普通敌人
同契:直线追踪 + 位置修正分离)。阶段切换 FSM(Phase 1 100%-50% / Phase 2
50%-0%:扑咬/扇形毒液/环形毒弹/后摇/毒雾压缩/召唤噬灵虫)defer
BossStateMachine #18。Boss carrier 暴露 `on_phase_transition(phase)` 钩子
供 #18 调用。

### 3.8 轻量分离(位置修正)

普通/精英/Boss 均用位置修正(source §15.4 第3条,非刚体碰撞):

1. QUERY phase 调 `query_circle_into(enemy_pos, separation_radius +
   max_enemy_bound, ENEMY, buffer, lease)`,排除自身 handle(SpatialGrid R10)。
2. QUERY_CONSUME phase:对每个邻居算穿透深度 `overlap = (sep_a + sep_b) -
   distance(a, b)`;`overlap > 0` 则双方各推 `overlap/2`(普通等质量)。
3. 修正叠加到本帧 committed_pos。

分离用 SpatialGrid query,**禁止遍历全场 active**(R8)。行为契约:分离后无
重叠。`separation_radius`/`max_enemy_bound` 由 Formulas 节定义并回填 registry。
修正时序(本帧即时 vs 下帧 MOVEMENT_COMMIT 生效)随 GameRoot phase 语义
协调,实现 defer ADR。

### 3.9 屏幕外 LOD(两级)

| LOD | 触发 | 行为 |
|---|---|---|
| full | 屏幕内(视口 AABB) | 每 tick 追踪 + 分离 + 动画全频 |
| reduced | 屏幕外 | 隔 tick(N=2)追踪 + 分离 + 动画 1/2 帧率 |

LOD 每帧基于视口 AABB 判定。reduced 不跳过死亡/受击/分离必要事件(只降
频率)。Boss 永远 full。

### 3.10 GameRoot phase 参与

EnemySystem 注册 `participant_id="enemy_system"`,allowed phases:

| phase | 职责 |
|---|---|
| SPAWN_INTENT | 对 SpawnDirector 已 borrow 的敌人执行 SpatialGrid `insert_into` + bind spatial_handle |
| MOVEMENT_COMMIT | 逐 handle 算追踪位移 + 分离修正 → `stage_position` |
| GRID_SYNC | (被动) |
| QUERY | 写分离 query buffer(`query_circle_into`) |
| QUERY_CONSUME | 读 query 结果,算位置修正,叠加 committed_pos |
| DEFERRED_REMOVAL | 死亡/回收:`remove` → release → `reset_for_pool` |
| POST_DEFERRED_BARRIER | (被动) |

`run_phase(phase, context, lease) -> int` 零分配。敌人 `_physics_process`
默认关闭。POOL_EXHAUSTED/OBJECT_INVALID 由 GameRoot 进 ControlledGameplayFault
(GameRoot R5/R9)。borrow 与 insert 的时序协调(同 phase 还是跨 phase)随
SpawnDirector GDD 协调(Not Started)。

### 3.11 死亡与回收

死亡触发:受击后 health ≤ 0(Combat 判定发信号)。流程(DEFERRED_REMOVAL):
发死亡事件 → DropSystem 消费(掉落判定)→ `remove`(BLOCKING)→ release →
`reset_for_pool`。死亡事件含 `behavior_id` + `death_position` + `spawn_seed`
(掉落表查询)。Boss 死亡额外触发 #18 阶段结束。

### 3.12 受击与伤害边界

EnemySystem 不计算伤害(归 Combat/DamageSystem)。敌人暴露
`take_damage(amount, source)` 供 Combat 调用,内部扣血 + 受击反馈;击退
vector 由 Combat 传,EnemySystem 在 MOVEMENT_COMMIT 叠加,并保证越界不超
`index_margin`(Stage F5)。`knockback_max` 归属 Combat/DamageSystem
owner(Open Question #2 确认)。

## 4. Formulas

> 本节公式由 EnemySystem owner 冻结;数值参数待 Config 调参后回填。
> lean 模式下 systems-designer 派生审在 design-review 阶段(新会话)进行。

### 4.1 追踪位移(普通敌人)

```
direction = Normalize(player_position - enemy_position)
displacement = direction × move_speed × delta_time × stage_move_multiplier
committed_pos = current_pos + displacement + separation_correction + knockback_vector
```

变量:
- `move_speed`:per-enemy base speed(Config behavior 表,units/sec)
- `delta_time`:固定 1/60(GameRoot 固定步长)
- `stage_move_multiplier`:见 4.3
- `separation_correction`:见 4.2
- `knockback_vector`:Combat 传入(4.5)

### 4.2 位置修正分离

```
query_radius = self.separation_radius + max_enemy_bound
neighbors = query_circle_into(self.pos, query_radius, ENEMY, buf, lease)  # 排除 self handle
for neighbor in neighbors:
    overlap = (self.separation_radius + neighbor.separation_radius) - distance(self.pos, neighbor.pos)
    if overlap > 0:
        correction_dir = Normalize(self.pos - neighbor.pos)
        correction = correction_dir × (overlap / 2)   # 等质量各推一半
        self.committed_pos += correction
```

变量:
- `separation_radius`:per-enemy 期望分离距离(Config behavior 表)
- `max_enemy_bound`:全局形状包围半径上界(registry 回填,见 4.6)
- 普通敌人等质量→各推 overlap/2;精英/Boss 质量更大→按质量比分配(实现
  defer ADR,行为契约是分离后无重叠)

### 4.3 阶段倍率(source §14.3)

```
stage = floor(battle_time_seconds / 60)   # 以分钟为阶段
stage_health_multiplier = 1 + stage × 0.18
stage_damage_multiplier = 1 + stage × 0.12
stage_move_multiplier = Min(1.35, 1 + stage × 0.03)
```

- 阶段以分钟计,`battle_time_seconds` 从 GameRoot context 读。
- 倍率应用于 spawn 时 max_health/base_damage/move_speed。
- 难度优先组合/密度/行为调整,不只堆血(source §14.3)。

### 4.4 屏幕外 LOD 降频(两级)

```
if not in_viewport(enemy.pos):
    tick_skip = (frame_count + enemy.slot_id) % 2   # 隔 tick,slot_id 错峰
    if tick_skip == 0:
        run tracking + separation   # reduced 频率(1/2)
    animation_frame_rate = 30       # 1/2 of 60
else:
    run tracking + separation every tick
    animation_frame_rate = 60
```

- `slot_id` 错峰避免所有屏幕外敌人同 tick 聚集更新。
- reduced 不跳过死亡/受击/分离必要事件(只降计算频率)。

### 4.5 击退叠加

```
committed_pos += knockback_vector   # Combat 传入
# 约束:|knockback_vector| ≤ knockback_max(Combat owner 保证)
```

击退由 Combat/DamageSystem 计算并传入 vector;EnemySystem 只叠加,不计算。
`knockback_max` 归 Combat/Damage owner(4.6 / Open Question #2)。

### 4.6 Registry 回填值(本 GDD 冻结)

本 GDD 向 registry 回填以下 gated 值(Stage F5 / SpatialGrid
max_query_radius 输入):

| 值 | 定义 | 归属 | 数值 |
|---|---|---|---|
| `max_enemy_bound` | 所有敌人 behavior_id 的 shape_bound 半径**上界** | EnemySystem | `max(per-type shape_bound)`;per-type 在 Config;数值待调参,上界约束见 4.7 |
| `enemy_overshoot_max` | 普通敌人单 tick 最大越界位移 | EnemySystem | `max(per-type move_speed) × (1/60) × 1.35`;数值待 Config move_speed 调参 |
| `separation_radius` | 所有敌人 separation_radius **上界**(max_query_radius 全局预算用) | EnemySystem | `max(per-type separation_radius)`;per-type 在 Config |
| `knockback_max` | 击退最大越界 | **Combat/DamageSystem** | 归属声明:Combat/Damage owner(Open Question #2 确认);EnemySystem 只消费 |

### 4.7 index_margin 下界约束(Stage F5)

```
index_margin_min = player_overshoot + enemy_overshoot_max + knockback_max + max_enemy_bound
```

- `player_overshoot` = 4.5/60 = 0.075(Stage 已冻结)
- 当前 `index_margin` = 2.0(spike),下界 0.075 + 上述三项。
- **约束**:`enemy_overshoot_max + knockback_max + max_enemy_bound ≤ 1.925`
  (保证 2.0 充足)。
- 本 GDD 冻结行为契约;Config 调参后须验证此不等式成立。若 move_speed/
  shape_bound/knockback 超预期导致违反,须重跑 SpatialGrid F3 sweep 并
  上调 `index_margin`(联动 Stage GDD)。

## 5. Edge Cases

### 5.1 池耗尽(POOL_EXHAUSTED)

- enemy_normal pool(320)耗尽:borrow 返回 POOL_EXHAUSTED → GameRoot 进
  ControlledGameplayFault(TECHNICAL_ABORT,不写奖励/纪录)。
- 预防:SpawnDirector admission check 先于 borrow(ENEMY cap=303,普通 300
  上限),理论上 borrow 不应耗尽(320 pool > 300 active)。若耗尽说明状态
  泄漏(slot 未归还),FAULT 是正确响应。
- enemy_elite pool(6)耗尽:精英并发上界 2,6 > 2,理论不耗尽;若耗尽同上。
- enemy_boss pool(1):Boss 唯一,borrow 失败说明 Boss 已存在,SpawnDirector
  须先查 active。

### 5.2 CAPACITY_EXCEEDED(SpatialGrid R9 / AC-E11)

- SpawnDirector admission check:ENEMY 注册数 ≥ 303 时普通怪 borrow 抑制
  (发布前抑制,fresh insert only)。
- 精英/Boss 预留 3 槽(2 elite + 1 boss):普通怪上界 300,即使精英/Boss
  未激活也不挤占预留。
- CAPACITY_EXCEEDED 不产生幽灵实体(AC-E11):被抑制的 spawn 请求不创建
  Node、不借 pool、不 insert grid。

### 5.3 精英并发(夺宝持久化)

- 精英 `max_concurrent = 2`(设计冻结):夺宝机缘可持久化 2 精英同时在场。
- 2 精英占 303 cap 中的 2 槽,与 safety_spare(300 普通 + 2 精英 + 1 Boss)
  对齐。
- **勿改 max_concurrent=2 → 4**(会破坏 303 对齐;若需更多精英,须先扩
  `pool_capacity_enemy_elite` 与 cap,再修订本 GDD + Config R4 + Object
  Pooling R1)。

### 5.4 Grid 失效 / teardown

- Object Pooling R8:teardown 须 SpatialGrid invalidated 后才调
  release/reset_for_pool。
- 顺序:GameRoot 停 phase → SpatialGrid invalidate → EnemySystem
  DEFERRED_REMOVAL remove(已 invalidated,remove 为 no-op 或安全)→
  release pool。
- 若 Grid 未失效即 release,remove 会操作已释放 grid → FAULT。

### 5.5 Paused quarantine(resume binding)

- 暂停(机缘选择/升级)时敌人进 quarantine(Object Pooling R6/R7):
  carrier `quarantine_revision` 标记,position frozen。
- resume:binding transaction 重新绑 SpatialGrid handle(若 grid 重置)或
  恢复 stage_position。
- 暂停期间敌人不更新(phase 驱动,GameRoot 停 phase 即停更新)。

### 5.6 Boss 阶段切换

- Boss carrier 暴露 `on_phase_transition(phase)` 钩子;BossStateMachine #18
  在 health 跨越 50% 时调用。
- 阶段切换不销毁/重 borrow Boss(pool_key=3 唯一);只切 FSM 状态集。
- 切换时若 Boss 在分离修正中,修正继续(载体行为不因阶段切换中断)。

### 5.7 屏幕外失步

- LOD reduced 隔 tick 更新:屏幕外敌人 position 可能滞后 1 tick(16ms),
  玩家不可见,无感。
- 屏幕外→屏幕内切换:下 tick 立即 full,position 已最新(reduced 仍每
  2 tick 更新,非冻结)。
- 屏幕外敌人死亡(被远程/DoT 杀):死亡事件不因 LOD 跳过(DEFERRED_REMOVAL
  每 tick 检查 health,不受 LOD 影响)。

### 5.8 敌人越界 arena

- 敌人追踪可能被分离修正/击退推出 arena AABB。
- `index_margin`(2.0)即为此预留:越界 ≤ index_margin 不算泄漏(grid 仍
  注册)。
- 超出 index_margin:clamp 回 arena 边界 + margin(实现 defer ADR;行为
  契约:敌人不永久脱离战场)。
- 腐毒妖藤(固定原地)不移动,无越界风险。

### 5.9 ControlledGameplayFault

- GameRoot R5/R9:POOL_EXHAUSTED/OBJECT_INVALID/phase failure →
  ControlledGameplayFault。
- 玩家见"战局状态异常"UI;TECHNICAL_ABORT,不写胜负/死亡/奖励/纪录/教程。
- 敌人状态:phase 停,所有 enemy frozen;池不归还(局结束统一 teardown)。

### 5.10 spawn_context 版本不匹配

- spawn_context schema 按 pool_key 版本化(Poolable/v1)。
- 若未来 schema 变(加字段),contract version 升级 v2;旧 spawn_context
  与新 contract 不兼容 → borrow 前 version check,不匹配 FAULT。
- 当前 v1:5 字段(behavior_id/pos/facing/time/seed)。

## 6. Dependencies

### 6.1 上游依赖(本 GDD 须遵循)

| 系统 | 状态 | 依赖契约 |
|---|---|---|
| SpatialGrid | Approved | ENEMY type_mask=1 注册;phase insert/stage/remove;`query_circle_into`(sep_radius+max_enemy_bound);R8 禁遍历全场;R9 CAPACITY_EXCEEDED 303;R10 排除 self handle;AC-E11 无幽灵 |
| Object Pooling | Approved | 三 pool_key(1/2/3,capacity 320/6/1);Poolable contract(reset_for_borrow/reset_for_pool 零分配);carrier 字段;R5 binding matrix;R6/R7 paused quarantine;R8 teardown 顺序;R9 POOL_EXHAUSTED→Fault |
| Config/Data | Draft(foundation 冻结) | EnemyNormalPoolable/v1/Elite/v1/Boss/v1 factory contract;6 普通共享 normal contract(behavior ID 区分);behavior 表(属性/动画/攻击);criticality=GAMEPLAY |
| GameRoot | Draft | phase participant(`participant_id`/`run_phase`/allowed phases);7 phase 顺序;`_physics_process` 默认关闭;R5 status+rollback;R9 ControlledGameplayFault |
| Stage | Approved | arena 22×40;spawn ring depth=4.0;inner_rect;boss_region;`index_margin`=2.0;F5 `index_margin_min` 公式 |
| RNG | Approved(间接) | 不直接依赖;`spawn_seed` 由 SpawnDirector 从 `run_seed`(GATE-G2)派生传入 spawn_context |

### 6.2 下游消费者(本 GDD 提供契约)

| 系统 | 状态 | 本 GDD 提供的接口 |
|---|---|---|
| SpawnDirector | Not Started | borrow 触发时机;spawn_context schema(5 字段);admission check(303 cap,2 elite+1 boss 预留);borrow→insert 时序协调(待 SpawnDirector GDD) |
| DropSystem | Not Started | 死亡事件(`behavior_id`+`death_position`+`spawn_seed`);掉落表查询接口;DEFERRED_REMOVAL 死亡→remove→release 顺序 |
| Combat/DamageSystem | Not Started | `take_damage(amount, source)` 接口;`knockback_vector` 传入;`knockback_max` 归属声明(Combat owner);health ≤ 0 死亡信号 |
| BossStateMachine #18 | Not Started | Boss carrier `on_phase_transition(phase)` 钩子;Boss 基础追踪/受击/死亡;pool_key=3 载体契约 |
| RiskChoiceSystem | Not Started | 暂停时 enemy quarantine(经 GameRoot phase 停);无直接接口(经 GameRoot) |
| Elite Enemies | Not Started | 精英 FSM 契约(本 GDD 已定义,见 3.6);behavior_id=6/7 |

### 6.3 跨系统边界声明

- **spawn_context ownership**:EnemySystem 冻结 schema(5 字段);SpawnDirector
  构造并传入;ObjectPool 按版本化 contract 解析。
- **behavior_id ownership**:Config 维护 ID→资源映射;EnemySystem/SpawnDirector
  只消费 int。
- **knockback ownership**:Combat/Damage 算并传 vector + 保证
  `|vector| ≤ knockback_max`;EnemySystem 只叠加。
- **phase 驱动**:EnemySystem 不自主开 phase;GameRoot 编排;所有更新经
  `run_phase`。
- **死亡掉落判定**:EnemySystem 发事件;DropSystem 判定掉什么;EnemySystem
  不决定掉落表。

## 7. Tuning Knobs

所有数值为数据驱动(Config behavior 表),本 GDD 列出可调项 + 来源约束。
具体数值待 Config 调参 + balance pass。

### 7.1 通用参数(per behavior_id)

| 参数 | 说明 | 约束/来源 |
|---|---|---|
| `move_speed` | 基础移速(units/sec) | per-type;max 影响 `enemy_overshoot_max`(4.6) |
| `base_health` | 基础生命 | per-type;×`stage_health_multiplier`(4.3) |
| `base_damage` | 基础伤害 | per-type;×`stage_damage_multiplier`;Combat 消费 |
| `separation_radius` | 期望分离距离 | per-type;max 影响 registry `separation_radius`(4.6) |
| `shape_bound` | 形状包围半径 | per-type;max = `max_enemy_bound`(4.6);须满足 4.7 约束 |

### 7.2 阶段倍率系数(source §14.3,冻结基线)

| 参数 | 值 | 说明 |
|---|---|---|
| `health_multiplier_per_stage` | 0.18 | 每阶段+18%生命 |
| `damage_multiplier_per_stage` | 0.12 | 每阶段+12%伤害 |
| `move_multiplier_per_stage` | 0.03 | 每阶段+3%移动 |
| `move_multiplier_cap` | 1.35 | 移动倍率上限 |
| `stage_duration_seconds` | 60 | 一阶段=60秒 |

### 7.3 LOD 参数

| 参数 | 值 | 说明 |
|---|---|---|
| `reduced_tick_skip` | 2 | 屏幕外隔 N tick 更新 |
| `reduced_animation_fps` | 30 | 屏幕外动画帧率(1/2) |
| `full_animation_fps` | 60 | 屏幕内动画帧率 |

### 7.4 精英 FSM 参数(per elite behavior_id)

| 参数 | 巨甲蜈蚣(6) | 鬼雾修士(7) |
|---|---|---|
| 冲刺/瞬移 | 3 连续冲刺 | 瞬移周期 |
| 虚弱/魂针 | 虚弱窗口(输出机会) | 扇形魂针范围 |
| 召唤 | — | 召唤血傀儡间隔 + 数量 |
| 击退抗性 | 高 | 中 |
| telegraph 时长 | 冲刺预警 | 瞬移/魂针预警 |

### 7.5 普通敌人行为参数(per normal behavior_id)

| 参数 | 适用 |
|---|---|
| 蓄力冲刺距离/速度 | 铁背妖狼(1) |
| 喷毒周期/范围 | 腐毒妖藤(2) |
| 击退抗性 | 甲壳妖虫(3) |
| 符弹射程/保持距离 | 魔道符修(4) |
| 自爆半径/预警时长 | 血傀儡(5) |
| spawn 数量权重 | 噬灵虫(0),SpawnDirector 用 |

### 7.6 spawn_context 字段(已冻结,3.3)

5 字段 frozen v1:`behavior_id`/`spawn_position`/`spawn_facing`/
`spawn_time_seconds`/`spawn_seed`。schema 变更须升级 contract version(5.10)。

### 7.7 pool 参数(上游冻结,Object Pooling)

| pool_key | capacity | spawn-before-release | criticality |
|---|---|---|---|
| enemy_normal=1 | 320 | 12 | GAMEPLAY |
| enemy_elite=2 | 6 | 1 | GAMEPLAY |
| enemy_boss=3 | 1 | 0 | GAMEPLAY |

不可调(上游冻结);变更须修订 Object Pooling + Config。

## 8. Acceptance Criteria

> lean 模式 H 节:qa-lead 派生审在 design-review 阶段(新会话)进行。
> AC 编号 `AC-E#`(Enemy)。

### 8.1 性能(source §15.4 + technical-preferences)

- **AC-E1**:300 普通敌人 + 2 精英 + 1 Boss = 303 实体同屏,中端 Android
  设备平均 50 FPS+(帧预算 16.6ms)。
- **AC-E2**:303 实体下,EnemySystem `run_phase` 总耗时 ≤ 3ms/帧
  (benchmark_ready gate 测定,待定最终预算)。
- **AC-E3**:屏幕外敌人(reduced LOD)计算量约为屏幕内(full)的 50%
  (隔 tick + 1/2 动画帧率)。

### 8.2 池化与零分配(Object Pooling)

- **AC-E4**:battle 期间(303 实体 + 高频 spawn/despawn)EnemySystem 零 GC
  alloc per frame(reset hook 零分配,profiler heap delta = 0)。
- **AC-E5**:borrow→reset_for_borrow→bind→unbind→release→reset_for_pool
  全链路无 slot 泄漏(归还后 `slot_state=FREE`,可再 borrow)。
- **AC-E6**:teardown 后所有借出 enemy 归还 + pool slot 全 FREE
  (SpatialGrid invalidated 后 release)。

### 8.3 SpatialGrid 契约

- **AC-E7**:EnemySystem 每 phase 调 SpatialGrid API 顺序正确
  (SPAWN_INTENT insert / MOVEMENT_COMMIT stage / DEFERRED_REMOVAL remove),
  无跨 phase 调用。
- **AC-E8**:分离查询走 `query_circle_into`(sep_radius+max_enemy_bound,
  排除 self),**不遍历全场 active**(代码审计 + profiler 验证无 O(n)
  全场扫描)。
- **AC-E9**:CAPACITY_EXCEEDED 时被抑制 spawn 请求不产生幽灵实体(无
  Node/pool slot/grid entry 创建,AC-E11 对齐)。

### 8.4 分离行为

- **AC-E10**:任意两普通敌人重叠(overlap > 0)在 QUERY_CONSUME 后位置
  修正使 overlap ≤ 0(行为契约:分离后无重叠)。
- **AC-E11**:修正对称(等质量各推 overlap/2);精英/Boss 质量更大时按
  质量比分配(行为契约:重敌人位移少)。

### 8.5 phase 契约(GameRoot)

- **AC-E12**:`run_phase` 对未 allowed phase 返回 status 不执行;零分配。
- **AC-E13**:敌人 `_physics_process` 默认关闭(代码审计:无重载或空重载)。
- **AC-E14**:POOL_EXHAUSTED/OBJECT_INVALID/phase failure → GameRoot 进
  ControlledGameplayFault(不 crash,玩家见安全停止 UI)。

### 8.6 LOD 行为

- **AC-E15**:屏幕外敌人 reduced LOD 隔 tick 更新(N=2),slot_id 错峰
  `(frame_count+slot_id)%2`;屏幕内 full 每 tick。
- **AC-E16**:LOD 切换不跳过死亡/受击/分离必要事件(reduced 仍每 2 tick
  检 health;死亡 DEFERRED_REMOVAL 每 tick 检)。
- **AC-E17**:Boss 永远 full LOD(代码审计:Boss 不进 reduced 路径)。

### 8.7 spawn_context 与 behavior

- **AC-E18**:6 种普通敌人共享 `EnemyNormalPoolable/v1`,以 behavior_id
  (0-5)区分(Config R4);无 6 个独立 PackedScene/script contract。
- **AC-E19**:spawn_context 5 字段全 primitive,无 Dictionary/Array 运行时
  构造(零分配验证)。
- **AC-E20**:behavior_id 索引 Config behavior 表设属性/动画;EnemySystem
  无硬编码敌人类型(代码审计:无 `if behavior_id == 0` 分支硬编码)。

### 8.8 死亡与回收

- **AC-E21**:health ≤ 0 → DEFERRED_REMOVAL `remove`(BLOCKING)→ release →
  `reset_for_pool` 顺序执行;remove-before-free(无 queue_free 前未 remove)。
- **AC-E22**:死亡事件含 `behavior_id`+`death_position`+`spawn_seed`;
  DropSystem 消费(掉落判定)。

### 8.9 registry 回填

- **AC-E23**:回填 `max_enemy_bound`/`enemy_overshoot_max`/`separation_radius`
  到 registry(referenced_by `max_query_radius`+`index_margin_lower_bound`);
  `knockback_max` 归属声明 Combat/Damage(Open Question #2)。
- **AC-E24**:回填后重跑 SpatialGrid F3 sweep,验证
  `index_margin_min ≤ index_margin`(2.0);违反须上调 index_margin(联动 Stage)。

### 8.10 边界

- **AC-E25**:EnemySystem 不计算伤害(无 damage formula;`take_damage` 只
  扣血 + 发信号)(Combat 边界)。
- **AC-E26**:不决定 spawn 时机/位置(SpawnDirector 边界);只消费
  spawn_context。
- **AC-E27**:Boss 阶段切换 FSM 不在本 GDD 实现(`on_phase_transition`
  钩子供 #18;#18 Not Started 时 Boss 只跑载体行为)。

## 9. Visual & Audio (optional)

EnemySystem 视觉/音频契约(节点细节 defer 节点架构 ADR):

### 9.1 动画状态

- 每敌人动画状态:idle/move/attack(技能)/hit/death。
- 动画资源由 Config behavior 表索引(`behavior_id` → AnimationLibrary)。
- 动画状态机由 FSM 驱动(普通敌人简单 idle/move/hit/death;精英 FSM
  状态对应动画)。
- 屏幕外动画 1/2 帧率(4.4),屏幕内 60fps。
- 动画切换零分配(`StringName` warmup 缓存,3.4)。

### 9.2 受击反馈

- 受击视觉:闪白(材质 shader param)/击退位移(Combat 传 vector)。
- 受击音效:由 Combat/DamageSystem 或 AudioSystem 触发(EnemySystem 发
  信号,不直接播音频)。
- 死亡视觉:death 动画 + 粒子(VFX GDD);health ≤ 0 触发 DEFERRED_REMOVAL,
  death 动画表现与回收时序 defer ADR(可先回池再播死亡特效,或反之)。

### 9.3 屏幕外降级

- 屏幕外动画 1/2 帧率 + 行为隔 tick(3.9/4.4)。
- 视口剔除:Godot 内置视口 cull 自动处理;是否手动 cull defer 节点架构 ADR。

### 9.4 音频

- 敌人音频(攻击/死亡/精英技能)由 AudioSystem 触发(EnemySystem 发信号)。
- 300 实体音频上限/合并策略归 AudioSystem/VFX GDD;本 GDD 不限。

## 10. Open Questions

1. **节点架构 ADR**(High-Risk,systems-index 标注):轻量 Node2D + 手动
   更新 vs CharacterBody2D + `move_and_slide` 物理驱动 vs 混合。source
   §15.4 倾向轻量,但具体节点/碰撞/动画节点须 `/architecture-decision`
   定。本 GDD 行为契约已冻结,不阻塞 ADR。
2. **knockback_max 归属**:本 GDD 声明归 Combat/DamageSystem owner
   (4.5/4.6);待 DamageSystem GDD 确认。若 DamageSystem 声明归
   EnemySystem,本 GDD 须加 knockback 公式。
3. **max_enemy_bound per-type vs 上界**:本 GDD 选上界(4.6);待 Config
   调参 + F3 sweep 验证上界满足 `index_margin` 约束(4.7)。若超须上调
   `index_margin`。
4. **分离修正时序**:本帧即时修正 vs 下帧 MOVEMENT_COMMIT 生效(1 帧
   延迟)。随 GameRoot phase 语义(Draft)+ ADR 定;行为契约是分离后无
   重叠,不阻塞。
5. **borrow→insert 时序**:同 SPAWN_INTENT phase 还是跨 phase
   (reset_for_borrow 时 vs phase 内)。随 SpawnDirector GDD(Not Started)
   协调;当前假设 SPAWN_INTENT phase 内统一 insert。
6. **Boss carrier 与 #18 run_phase 边界**:Boss 是 EnemySystem participant
   还是 BossStateMachine 独立 participant?`on_phase_transition` 钩子由
   #18 在哪个 phase 调?待 #18 GDD。
7. **腐毒妖藤静态处理**:固定原地不移动,是否仍进 SpatialGrid 分离查询
   (ENEMY 类型一致)还是静态标记?本 GDD 倾向进 grid 一致性,但可优化
   (静态敌人不查分离,只被查)。待 ADR/优化 pass。
8. **精英 FSM 状态集充分性**:巨甲蜈蚣/鬼雾修士 FSM 状态(3.6)是否足够?
   需 playtest + design-review 验证;可能需扩展(瞬移次数上限/虚弱时长
   调参)。
