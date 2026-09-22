# Enemy System GDD

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：STEAM_MISSION_V1/STEAM_SAVE_V2的目标、终态与完整恢复要求见mission-objectives.md、save-steam-pc.md及ADR-0006。本owner的目标身份/生命周期（适用时）、matching-tick snapshot、schema/validator/migration、required-owner与容量贡献待正式冻结并接线；下方legacy合同不因本路由而自动满足新profile，缺失时禁止生产启用。

> Status: Re-review Pending — 已同步“感知无限、技术有限”Stage V2、SpawnDirector相对生成/退役与world-domain guard；须独立full复审
> Owner: systems-designer + ai-programmer
> Depends on: SpatialGrid / Object Pooling / Config/Data（均处于 GameRoot Round 8 propagation Re-review Pending；foundation contracts 已冻结，runtime evidence OPEN）
> Depended on by: SpawnDirector (Full Review Pending), DropSystem, RiskChoiceSystem, BossStateMachine, Elite Enemies
> Engine: Godot 4.7.1 | Language: GDScript
> Pillar alignment: 300-entity onscreen smoothness + swarm-slaughter satisfaction (infrastructure)
> High-Risk: node architecture (lightweight Node2D + manual update vs CharacterBody2D + physics-driven) — deferred to /architecture-decision ADR

---

## 1. Overview

EnemySystem 是掌天试炼战场中所有敌人的行为与生命周期基础设施。它负责 6
种普通敌人(噬灵虫/铁背妖狼/腐毒妖藤/甲壳妖虫/魔道符修/血傀儡,共享
`EnemyNormalPoolable/v1` 契约,以 config behavior ID 区分)、2 种精英
(巨甲蜈蚣/鬼雾修士,`EnemyElitePoolable/v1` 契约；FSM driver/载体归本 GDD，
behavior 6/7 的状态图、参数、攻击与表现内容唯一归 `elite-enemies.md`)
与 Boss 载体(碧鳞蟒,`EnemyBossPoolable/v1` 契约；driver/载体归本 GDD，
behavior 8 的两阶段FSM、攻击、毒域、召唤与终局输入唯一归 `boss-state-machine.md`)的
生命周期、移动、分离与 GameRoot phase 参与。它向 SpawnDirector 提供借出/
回收接口与 spawn_context schema(何时何地刷何种敌人由 SpawnDirector 决定),
向 DropSystem 发布死亡事件,向 SpatialGrid 以 ENEMY 类型注册并按固定 phase
(insert@SPAWN_INTENT / stage@MOVEMENT_COMMIT / remove@DEFERRED_REMOVAL)
同步位置。在298普通敌人同屏（303 cap另含4 Elite+1 Boss预留）硬约束下,
EnemySystem 冻结行为契约——直线追踪(不完整寻路)、轻量分离(SpatialGrid
query,非刚体碰撞)、对象池零分配 reset;节点架构与碰撞实现方式(Node2D
手动更新 vs CharacterBody2D 物理驱动)作为 High-Risk 决策 defer
`/architecture-decision` ADR,本 GDD 只描述与实现无关的行为契约。

> **Simulation policy**：Stage V2允许敌人位于屏外，但MVP仍不引入按可见性的
> simulation LOD；Boss与所有active敌人每tick更新。Camera/draw-cull只影响表现，
> SpawnDirector负责远离玩家的普通敌无奖励退役，性能压力由active cap、分离query
> 上界、pair-once去重与零分配reset承担。

## 2. Player Fantasy

EnemySystem 支撑的核心幻想是**被怪潮包围但仍能掌控战局**的割草爽快。玩家
应感受到四层:

1. **压迫感**:敌人从屏幕边缘环带源源涌入,数量随时间攀升至 300 同屏,形成
   四面楚歌的密度压力,但每帧流畅——性能是幻想的物理基础,卡顿即破幻想。
2. **可读性**:**5 种鲜明行为剪影**(蓄力冲刺/固定喷毒/贴身毒 aura/远程符弹/
   自爆预警)+ **1 种基线参照(噬灵虫直线追踪)**,玩家 1-2 秒内识别威胁类型并做
   战术取舍:优先清远程?拉开自爆?绕行毒藤?噬灵虫作为基线参照体——数量多、
   行为最简(直线追踪),衬托其余 5 种的剪影差异,本身不要求鲜明可辨(M/B-F3 fix:
   原"6 种各有鲜明剪影"与噬灵虫基线定位矛盾)。**注意**:行为剪影指*可观察行为*,
   非数值属性(高生命/抗击退是属性,须靠行为剪影传达——如甲壳妖虫贴身停下释放
   毒 aura 而非堆血硬抗)。
3. **节拍感**:节奏表驱动的怪潮组合随分钟推进,精英(6:00 巨甲蜈蚣/10:00
   鬼雾修士)出场带"小 Boss + 法宝匣"奖励期待,Boss(12:00 碧鳞蟒)出场带
   两阶段仪式感。
4. **击杀反馈**:死亡即时回收 + 独立 VFX 池播放死亡特效(不截断、不错位)+
   掉落发布,屏幕清空感与战利品期待并存。

阶段倍率以分钟配置、数据驱动,优先通过组合/密度/行为调整难度而非单纯堆血
——保证后期怪潮"更乱更密"而非"更肉更慢",维持割草爽快到底。节拍感(锯齿
张力→释放→更高基准线)由 SpawnDirector 波次调度提供,非本倍率;本倍率只
提供单调基准。health/damage 倍率设上限(见 §4.3),避免长局血量发散违此承诺。

## 3. Detailed Design

### 3.1 敌人分类与 pool 归属

| 类别 | pool_key | capacity | factory_contract | 同屏上界 | FSM 归属 |
|---|---|---|---|---|---|
| 普通敌人(6 种) | enemy_normal=1 | 320 | EnemyNormalPoolable/v1 | 298 | 无(直线追踪,数据驱动) |
| 精英(2 种) | enemy_elite=2 | 6 | EnemyElitePoolable/v1 | 4 | driver/载体归本GDD；内容表归Elite Enemies |
| Boss 载体 | enemy_boss=3 | 1 | EnemyBossPoolable/v1 | 1 | driver/载体归Enemy；behavior8内容归BossStateMachine |

303 cap = 298普通 + 4 Elite + 1 Boss预留（RiskChoice R7 / SpatialGrid R9 / Config R15）。

### 3.2 Behavior ID 数据驱动

按 pool_key 分组共享 Poolable contract,以 `behavior_id` 区分具体敌人:

| behavior_id | 名称 | pool | 行为剪影 |
|---|---|---|---|
| 0 | 噬灵虫 | normal | 直线追踪/低生命/数量多 |
| 1 | 铁背妖狼 | normal | 快速/蓄力冲刺/走位减速 |
| 2 | 腐毒妖藤 | normal | 固定原地/周期喷毒液 |
| 3 | 甲壳妖虫 | normal | 接近后停下贴身释放短程毒 aura(周期伤害光环)（高生命/抗击退为 Config 属性,非剪影,见下注） |

> **behavior 3 可读性设计(decision 2026-08-25)**:甲壳妖虫行为剪影 =
> "接近玩家→停在攻击距离内→周期释放短程毒 aura",与腐毒妖藤(behavior 2,
> 固定原地喷毒,不移动)区分:妖藤*出生即固定*不追玩家,甲壳妖虫*会移动到
> 玩家身边再停下*。高生命/抗击退降为 Config 属性(非行为剪影),玩家通过
> "停身+光环"识别威胁而非"打不动"。"持续伤害"由 aura 实现,非接触 DPS。
> 数值(move_speed/aura_radius/aura_period/base_health/knockback_resistance)
> 在 Config behavior 表,标待调参。
> **B3 fix(第二轮复审,停车判定可编码性)**:原"接近后停下"无 stop_distance 判定 + 无
> 重新追击条件,归在"无 FSM"普通敌人却隐含 stop/resume 切换=mini-FSM。裁定——保留 normal
> 桶(共享 `EnemyNormalPoolable/v1`,行为用 `behavior_id` 索引 Config,非独立 contract),
> 新增数据驱动两参 `stop_distance`(进入 aura 攻击距离阈值,≈aura_radius) + `resume_distance`
> (玩家离开后重新追击阈值,>stop_distance 滞回防抖动)。甲壳妖虫以数据驱动 mini-FSM
> (state: CHASING/ATTACKING)实现:`distance ≤ stop_distance` → ATTACKING(停身释放 aura);
> `distance > resume_distance` → CHASING(重新追击);ATTACKING 与 CHASING 之间滞回带
> (resume_distance > stop_distance)防抖动。见 §7.4 spike 行;normal 桶 mini-FSM
> 不归精英 AC-E30a,新增 AC-E30d 守卫甲壳妖虫 stop/resume 可判(§8.11);第三轮复审 B-4 补齐
> normal 桶其余 4 mini-FSM(铁背妖狼/腐毒妖藤/魔道符修/血傀儡)状态表+参数+AC-E30e/f/g/h(见 §7.4/§8.11)。
| 4 | 魔道符修 | normal | 保持距离/发射符弹 |
| 5 | 血傀儡 | normal | 接近自爆/死亡预警 |
| 6 | 巨甲蜈蚣 | elite | 连续冲刺3次→WEAKENED 虚弱窗口（玩家输出机会）（高生命/高击退抗性为 Config 属性,非剪影,见 §3.2 decision 注） |
| 7 | 鬼雾修士 | elite | 周期瞬移/扇形魂针/召唤血傀儡 |
| 8 | 碧鳞蟒(载体) | boss | 基础追踪/受击/死亡；内容由BossStateMachine capability驱动 |

`behavior_id` 是 spawn_context 首字段,索引 Config behavior 表(属性/动画/
攻击定义)。Config 维护 ID→资源映射;EnemySystem 只消费 `behavior_id`,
不硬编码敌人类型。

### 3.3 spawn_context schema

EnemySystem 冻结 `SpawnContextCarrierV2`（10 primitive 字段，BATTLE_LOADING
预分配、caller-owned carrier，runtime只覆写；V2由RiskChoice集成扩展V1）:

```
spawn_context = {
    behavior_id: int,              # 0-8
    spawn_position: Vector2,      # SpawnDirector玩家相对offscreen ring候选点
    spawn_facing: Vector2,         # 初始朝向(通常朝玩家)
    spawn_time_seconds: float,    # 生成时刻(存活/阶段倍率查询)
    spawn_seed: int,              # SpawnDirector 从 run_seed 派生
    spawn_provenance: int,        # WAVE/RISK_CHOICE/SUMMON等封闭enum
    source_choice_id: int,        # 非Risk为0
    stage_snapshot_id: int,       # matching stage/config identity
    max_hp_multiplier: float,     # 普通为1.0，Risk为1.30
    base_damage_multiplier: float # 普通为1.0，Risk为1.30
}
```

基础阶段倍率/属性/动画仍由 `behavior_id+stage_snapshot_id` 查 Config；两个显式倍率只在基础stage值解析后、runtime modifier前各乘一次。非Risk必须使用1.0/1.0且choice ID=0；Risk必须provenance=RISK_CHOICE、choice ID非零、两倍率均1.30。按 pool_key 版本化:三个 Poolable/v1 各自解析这10字段(语义同,解析路径
按 carrier v2 contract)。spawn_seed 由 SpawnDirector 从全局 run_seed(RNG
GATE-G2)派生;EnemySystem 不直接依赖 RNG。

### 3.4 Poolable contract 实现

每个 pooled 敌人 Node 实现 Object Pooling R3:

- `reset_for_borrow(borrow_id, spawn_context)`:读 spawn_context 10 字段 →
  查 Config behavior 表设属性/动画/初始状态。**不在此 insert SpatialGrid**
  (insert 在 SPAWN_INTENT phase 由 EnemySystem 统一执行,保证 phase 一致性)。
- `reset_for_pool()`:unbind `remove(handle, lease)`(BLOCKING)→ 清 AC-B2
  字段(Timer/Tween/target/damage/pierce/Buff/signal/collision/visibility)。

零分配契约(R3,扩展到 run_phase 全路径,非仅 reset hook):

**reset hook 禁令**(main-thread 稳态借出/归还路径):禁 `set_deferred`/
`call_deferred`/`create_tween`/`Array.clear`(Variant 数组写时逐元素 box 分配)/
`Dictionary`/`connect`-`disconnect`/`String` 字面量/`$NodePath`/`get_node(path)`/
`call(method_string,…)`/`emit_signal(name_string,…)`/`get_children()`(返回
`Array<Node>` 每次分配)/`get_parent()` 动态查;用 `PackedXxxArray.clear()`
(原始连续存储,写不 box、`clear()` 仅重置长度,无 Variant churn)+ 预缓存
`@onready` 子节点引用 + warmup 缓存 `StringName`(`&"..."`,编译期内联;`^"..."`
是 NodePath 字面量非 StringName,engine ref modules/animation.md 示范 `play(&"attack")`)。

**run_phase 热路径额外禁令**(death 事件/精英技能意图/受击在 DEFERRED_REMOVAL/
MOVEMENT_COMMIT 每帧可能触发):
- **禁 `emit_signal` 带参**(Godot 4 emit 装箱 Variant 参数数组是稳态分配,
  违 AC-E4)。死亡事件/技能意图/召唤请求一律写 GameRoot 预分配 staging slot/
  `PackedInt64Array`/fixed-slot bank,由消费方(Combat/Drop/SpawnDirector)
  在其 own run_phase pull;`take_damage` 改直接方法调用(非 signal)。
- 禁 `for i in range(count)`(遵 spatial-grid AC-B7)、`str()`/`var_to_str()`、
  `Callable` 动态构造、`await`。

**Config 访问契约**:`reset_for_borrow` 只读 Config 的 flat scalar/StringName
字段;禁止返回 Dictionary/Array 引用到 carrier,禁止在 reset 内 `duplicate()`
资源。Config behavior 表须是 flat 字段访问(非容器引用)。

**`set_deferred` 与节点架构 ADR 关系**:本禁令假设非物理 Node2D 架构。若
节点架构 ADR 选 CharacterBody2D + CollisionShape2D(物理驱动选项),则
`CollisionShape2D.disabled` 切换 / physics body 进出 `World2D` 须用
`set_deferred`——**B2 fix:其必要原因是 state-sync 正确性**(physics flush 期间
不能改 disabled,否则触发 "Can't change this state while flushing queries"),
**非分配**。`Object.set_deferred("disabled", bool)` 对 bool 值 Variant 内联持有、
MessageQueue 为预分配固定缓冲区,**很可能根本不产生堆分配**(R-GS 核查);故
set_deferred 的零分配禁令依据从"分配"改为"状态同步时序"。此时 ADR 须声明
`set_deferred` 例外 carve-out,仅限 `CollisionShape2D.disabled` 边界切换;若该
路径 per-borrow 调用,ADR 须显式声明其对 AC-E4 的影响(证明 bool Variant 不分配,
或把该路径排除出 AC-E4 计数器断言)——**不归 BATTLE_LOADING warmup 摊销**(原
"warmup 摊销"与 per-borrow 边界切换自相矛盾,已删)。本禁令在 ADR 选物理架构前
对当前(轻量 Node2D)路径生效。

**Godot 4.7.1 实现注意**(非阻塞,记入实现 checklist):`AnimationPlayer.play()`
内部 emit `animation_started/finished`(warmup 不消除;R-GS:缓解为载体
AnimationPlayer 内置信号 warmup 期断开 + gameplay 动画事件改由 FSM 计时器轮询
驱动——原"`current_animation`+`active` 切换"不成立,`active`=AnimationMixer.active
控制 processing 非切换,`playback_active` 4.3 起弃用);packed array 不可加属性
setter 期望逐元素写通知(GH-113228);typed-return 覆盖父类方法须显式 `return`
(GH-115763,**补 AC-E37 守卫**,见 §8);`AnimationLibrary` 须一共享库(behavior
前缀动画名)+ warmup StringName `&"..."` 缓存,禁 per-behavior library swap
(会 `add_library`/`remove_library` 分配)。另:`Array.clear()` 本身不 box(释放
元素引用),真正 box 的是 untyped Array 元素写/append——用 PackedXxxArray 或
typed `Array[T]`(R-GS R7 措辞修正)。

carrier(R2):`pool_epoch`/`borrow_id`/`object_instance_id`/`pool_key`/
`slot_id`/`generation` + `node_ref`(弱引用)+ `spatial_handle_id`(bind
时填)+ `quarantine_revision` + `mini_fsm_state`(int 枚举,第三轮复审 B-4:normal 桶 mini-FSM 状态存储;per behavior_id 的 mini-FSM 状态,见 §3.6 normal 桶 driver 注)。
**R4 载体字段补齐(根因2/4/5,同类 B-4 typed 预分配字段,reset_for_borrow 归零/初始化)**:
- `next_separation_correction: Vector2`(跨tick分离修正槽,根因2:tick T §4.2 QUERY_CONSUME的ACCUMULATE/COMMIT子步写双方并clamp；tick T+1 §4.1 MOVEMENT_COMMIT读取一次后立即归零。禁止把phase 5结果倒灌到同tick已结束的phase 2)。
- `mini_fsm_phase_timer: float`(normal mini-FSM当前状态计时器,reset_for_borrow初始化为
  `base_timer + fsm_phase_offset`;每tick递减/递增，谓词阈值判定用此字段)。
- `mini_fsm_counter: int`(normal mini-FSM跨周期计数器；reset_for_borrow归零)。
- `mini_fsm_event_flag: bool`(FSM 跨阶段事件标志,根因5:如血傀儡自爆阈值跨越——`take_damage`
  (DEFERRED_REMOVAL)检测 health 跨 30% 时设 true,FSM 下帧 MOVEMENT_COMMIT 轮询消费触发状态迁移;
  1-tick 跨相延迟类击退,§3.12 L426)。
- Elite载体另绑定一行`EliteRuntimeStateV1`，逐字段等于Elite GDD §3.1的
  `{fsm_state,state_ticks,active_age_ticks,action_generation,charge_axis,charge_segment_index,charge_progress,charge_hit_mask,blink_cycle_index,blink_landing_position,needle_axis,summon_generation}`；随borrow reset/quarantine/resume，禁止塞入上述normal mini-FSM通用字段或Dictionary造成别名/容量悬空。

### 3.5 移动行为:直线追踪(普通敌人)

普通敌人不使用完整寻路(source §15.4 第2条),只朝玩家直线移动:

```
direction = Normalize(player_position - enemy_position)
displacement = direction × move_speed × delta_time × stage_move_multiplier
```

无 NavigationServer(300 实体不需要)。移动在 MOVEMENT_COMMIT phase 逐 handle
计算,调 `stage_position(handle, committed_pos, lease)`(grid 在 GRID_SYNC
统一 commit)。分离修正(3.8)叠加到 committed_pos。

### 3.6 精英 FSM driver 与内容所有权

精英用有限状态机(source §15.5)。本 GDD只冻结共享driver、typed runtime state、
phase/Pool/Grid/Damage handoff；`design/gdd/elite-enemies.md` 是behavior 6/7状态表、
计时、攻击、召唤与表现的唯一内容owner。下列两小节为同步echo，若与Elite GDD或其
content hash不同，Config必须在Node创建前失败，不允许选择任一版本继续运行。

**通用约定**:
- FSM 由 EnemyElitePoolable 在 `run_phase` 内驱动(归 MOVEMENT_COMMIT 阶段
  计算 FSM 计时/状态,技能释放意图 latch 到 GameRoot 由 Combat 消费,见下)。
- **normal 桶 mini-FSM driver(第三轮复审 B-4,补 B3 fix 覆盖漏洞+状态存储/驱动归属)**:
  normal 桶 4 个隐含 mini-FSM 敌人(behavior_id=1 铁背妖狼/2 腐毒妖藤/4 魔道符修/5 血傀儡)
  的状态存储于 carrier `mini_fsm_state` 字段(int 枚举,per behavior_id),由 EnemyNormalPoolable
  在 `run_phase`(MOVEMENT_COMMIT)内驱动——仿 EnemyElitePoolable 模式但更简单:normal 桶 mini-FSM
  无技能 intent latch(无技能释放),仅移动/攻击状态切换(2-3 状态),计时器 = `base_timer + fsm_phase_offset`
  (normal behavior的确定性约定,spawn_seed 派生),**存于 carrier `mini_fsm_phase_timer` 字段**(reset_for_borrow 初始化,
  每 tick run_phase 递减/递增,谓词阈值判定用此字段);normal跨周期计数器存 `mini_fsm_counter`。
  **R4 根因4 闭合 B-4 timer/counter 存储悬空**(B-4 仅加 `mini_fsm_state`,
  未声明 timer/counter 存何处)。甲壳妖虫(behavior_id=3,B3 fix)同此 driver。状态表/参数见
  §7.4,AC 见 §8.11 AC-E30e/f/g/h。原 B3 fix 只补甲壳妖虫 1/5,未覆盖 1/2/4/5 + 未定义状态存储/驱动
  归属(§3.6 仅声明精英 driver),本轮系统性补齐。
- 状态切换由计时器/距离/事件触发,**无runtime RNG**。normal mini-FSM可使用borrow期
  静态`fsm_phase_offset`；Elite严格按Elite GDD：arrival/cooldown无offset，blink angle/radius
  只由`{spawn_seed,blink_cycle_index,salt}`纯hash派生，状态本身不随机。
- `frame_count` 源固定为 GameRoot `tick_revision`(非 `Engine.get_physics_frames`,
  以便注入测试;暂停期间不推进遵 §5.5)。
- 精英技能伤害/范围/投射物归 Damage/ProjectileSystem；Elite Enemies定义状态
  流转与技能**释放意图**内容，EnemySystem driver只执行已冻结表。意图**不走 `signal.emit`**(违零分配,见 §3.4),
  而是latch成typed plan写入预分配staging；魂针与召唤都固定由对应owner在
  下一Active tick `SPAWN_INTENT`消费，蜈蚣charge direct hit才在matching QUERY_CONSUME交Damage。
- 召唤血傀儡(behavior_id=5)经 SpawnDirector borrow(保持 admission check
  一致性,精英不直接借 pool);召唤同样走 intent latch,下一 tick SPAWN_INTENT
  phase 由 SpawnDirector 执行 borrow(遵 Object Pooling R4 borrow 限
  SPAWN_INTENT,**禁止跨 phase 同步 borrow**)。

#### 3.6.1 巨甲蜈蚣(behavior_id=6)FSM

`ARRIVAL_LOCK → TRACK → TELEGRAPH_CHARGE → CHARGE_1 → LINK_1 → CHARGE_2 → LINK_2 → CHARGE_3 → WEAKENED → TRACK` 循环；权威表见Elite GDD §3.4。

| 当前状态 | 触发谓词 | action | 下一状态 |
|---|---|---|---|
| ARRIVAL_LOCK | `active_age_ticks >= 60` | 启用进攻；冷却从0开始 | TRACK |
| TRACK | `distance(self,player) ≤ charge_trigger_range` 且 `charge_cooldown_ticks>=300` | 进 TELEGRAPH_CHARGE；锁定唯一冲刺方向 | TELEGRAPH_CHARGE |
| TELEGRAPH_CHARGE | `state_ticks>=24` | latch第1段冲刺；清零segment progress | CHARGE_1 |
| CHARGE_i | authored投影进度达到6.0 | 关闭本段hit window；若i<3发布段界并进LINK，否则立即进入WEAKENED | LINK_i / WEAKENED |
| LINK_i | `state_ticks>=6` | 沿同一锁定方向启动下一段，不重瞄准 | CHARGE_(i+1) |
| WEAKENED | `state_ticks>=150` | 移除破绽modifier；清零chain/cooldown | TRACK |

唯一参数源为Elite GDD §7，本节只echo：trigger/distance/speed=`6/6/18`、
telegraph/link/cooldown/weakened=`24/6/300/150 ticks`、segment count=3。
- 冲刺方向 telegraph 时锁定；segment index上限3防无限循环。
- **CHARGE 行进度量 = authored沿锁定方向投影长度**(不含knockback与垂直分离，避免侧移
  修正膨胀欧氏行进导致提前完成 charge,见 §4.2 时序)。**B1 fix(第二轮复审,敌群中分离反推死锁)**:
  旧R5只覆盖边缘死锁,未覆盖敌群中分离反推致投影不增——CHARGE 中分离修正若含沿
  锁定轴反向分量(密集敌群在冲刺轴前方反推精英),每 tick charge 位移 0.3 可能被反推抵消,
  投影不增 → CHARGE 永不达 charge_distance=6.0 → WEAKENED 永不进入。**裁定**:CHARGE 期间
  分离修正**仅作用于垂直于锁定轴的分量**(沿锁定轴分量不施加分离,精英冲刺不被敌群反推卡死)。
  **第三轮复审 B-3 canonical 裁定**:择此为唯一实现,删除原"或等价地投影单调不减阈值守卫"
  备选分支——该备选在敌群反推场景下投影不增致 charge_distance<6.0 违 AC-E30b(实现2 与实现1
  非等价,ai-programmer/systems-designer/qa-lead 三方核实;原"或等价地"措辞误导)。具体实现 defer
  节点架构 ADR,但行为契约可测(见 AC-E30b 敌群分离反推场景,已并入 CHARGE→WEAKENED
  循环死锁防护)。
- Stage V2没有可见墙或arena clamp。CHARGE只以投影距离完成；Loading期
  world-reachability proof保证正常局不会触达技术域。任何完整足迹越
  `world_safe_aabb`均为`POSITION_OUT_OF_RANGE`并进入ControlledGameplayFault，
  不得伪装成“撞墙完成”。

#### 3.6.2 鬼雾修士(behavior_id=7)FSM

`ARRIVAL_LOCK → TRACK → TELEGRAPH_BLINK → BLINK → TELEGRAPH_NEEDLE → RELEASE_NEEDLE → RECOVER → SUMMON → TRACK` 循环；权威表见Elite GDD §3.5。

| 当前状态 | 触发谓词 | action | 下一状态 |
|---|---|---|---|
| ARRIVAL_LOCK | `active_age_ticks>=60` | 启用进攻并从0累计blink period | TRACK |
| TRACK | `blink_period_ticks>=360` | 按spawn seed+cycle纯hash冻结落点并发布预警 | TELEGRAPH_BLINK |
| TELEGRAPH_BLINK | `state_ticks>=18` | 原子提交landing position | BLINK |
| BLINK | 同tickposition publish成功 | 锁定needle axis并发布60°/5.0扇面 | TELEGRAPH_NEEDLE |
| TELEGRAPH_NEEDLE | `state_ticks>=30` | latch三枚魂针Projectile plan | RELEASE_NEEDLE |
| RELEASE_NEEDLE | 三行完整plan已latch | 关闭危险填充 | RECOVER |
| RECOVER | `state_ticks>=24` | latch三子项召唤cluster | SUMMON |
| SUMMON | cluster已latch | cycle递增、重置period；0 tick提交边 | TRACK |

**BLINK 落点规则(decision 2026-08-25)**:
```
blink_landing_pos = player_position + UnitVector(spawn_seed_derived_angle) × blink_offset_radius
# angle/radius均由{spawn_seed,blink_cycle_index,不同salt}纯hash派生，不消费runtime RNG cursor
# blink_offset_radius ∈ [blink_offset_min, blink_offset_max](Config,spike = [1.5, 2.5])
# 对落点做real_t32 readback与完整足迹world-domain guard；不clamp
# 落点不校验敌人重叠——靠分离(§3.8)消化
```
- 落点在玩家附近偏一个身位(非落玩家点),玩家可读 telegraph 后闪避,**不即死**。
- angle/radius在每个blink cycle入口冻结，cycle内不变。落点不得因技术域改写；若完整足迹越domain则该
  motion batch在发布前失败并进入ControlledGameplayFault。Loading期证明应使此路径
  在合法1800秒战斗中不可达。

**召唤 cap-full 行为(decision 2026-08-25)**:
- 若普通怪 active+pending 已达 298 cap,SpawnDirector admission 抑制本次 borrow。
- FSM 行为:SUMMON_BLOOD_PUPPET 仍视为完成进 TRACK(不重试本周期),发"灵力
  逸散 VFX"意图(独立 VFX 池,见 §3.11)让玩家看到召唤失败反馈(非静默);
- 不计入"已召唤次数"——下一 blink 周期可再次尝试。

Spike锚点与唯一字段名见Elite GDD §7；本节不再拥有第二套数值。魂针预警30 tick
发生在任何Projectile plan之前，旧`fan_needle_duration`统一解释为`recover_ticks=24`。
召唤频率仍等于blink频率，每周期只latch一次cluster。

### 3.7 Boss 载体行为

碧鳞蟒(8)本 GDD 只定义载体：生命/池化/基础追踪/受击/死亡、Enemy phase内的
typed capability调用与位置/分离提交。`boss-state-machine.md`是behavior 8内容唯一owner，
冻结12:00入场、P1三招、50%切换、P2毒域/双扑咬/召虫与致死预测输入。
Boss capability不是新participant；Enemy在自身合法phase同步调用，Boss攻击plan T latch、
Projectile/Spawn在T+1消费。carrier暴露typed `on_phase_transition(PHASE_2)`，不接受动画callback或任意字符串状态。

### 3.8 轻量分离(位置修正)

普通/精英/Boss 均用位置修正(source §15.4 第3条,非刚体碰撞):

1. QUERY phase 调 `query_circle_into(enemy_pos, separation_radius +
   max_separation_radius, ENEMY, buffer, lease)`,排除自身 handle(SpatialGrid R10)。
2. QUERY_CONSUME phase:每个敌人 a 遍历自身 query 结果的邻居,**仅处理
   `neighbor.handle > a.handle` 的邻居 b**(利用对称 overlap 保证无序对 (a,b)
   全局只处理一次,a 侧写双方修正)。算穿透深度 `overlap = (sep_a + sep_b) -
   distance(a, b)`;`overlap > 0` 则按质量比分配(等质量各推 `overlap/2`),
   写**双方**修正(`a.correction += push; b.correction -= push`)。
   **架构裁定(decision 2026-08-25,R1 fix,采 CD Option B 变体)**:per-enemy
   query + inline `handle > self` 去重(写双方),禁 `sort()`/`Dictionary`
   visited-set/生成 pair 列表(零分配)。此模型每对全局只处理一次,pair-ops
   上界 = `303×302/2 = 45,753`(非 per-enemy 各处理一次的 91,606)。
   **修正累加 clamp**:单帧每敌总修正向量长度 ≤ `separation_radius`,防密集簇
   overshoot/振荡。
3. tick T算出的修正写入`next_separation_correction`，只由**tick T+1**的MOVEMENT_COMMIT消费一次；不得回写tick T已经结束的MOVEMENT_COMMIT。

**分离回写时序裁定（2026-08-28第六轮纠错，替代2026-08-25同tick措辞）**:
- tick T的QUERY读取tick T phase 3刚发布的committed位置；tick T的QUERY_CONSUME计算并冻结`next_separation_correction[T]`。tick T+1 MOVEMENT_COMMIT读取、clamp守卫后叠加该值并立即清零，再由GRID_SYNC发布包含该修正的新位置。
- 这是完整一个physics tick的有界延迟；无需新增phase或同phase二次stage。tick T内AoE/投射物与视觉都使用同一已发布位置，tick T+1发布后两者共同看到含分离的新位置，禁止视觉Node提前应用尚未进Grid的修正。
- pause/fault发生在T phase 5之后时，冻结的next correction随authoritative carrier保留；合法resume后的首个MOVEMENT_COMMIT恰消费一次。battle ending/teardown则丢弃，不跨battle复用。

分离用 SpatialGrid query,**禁止遍历全场 active**(R8)。**k 上界声明**:全聚集
玩家点时单次 query 最坏 `neighbors_per_query ≤ 303`(场上 ENEMY 总数上界 303,
为绝对上界;query radius `sep_radius + max_separation_radius` 配 CELL_SIZE 跨
多格,303 来自总数非"3×3 格"约束——spatial-grid F4 的 3×3 聚集注解对应较小
pickup_radius,不对应分离 query);`separation_pair_ops/frame ≤ 303×302/2 =
45,753`(Option B pair-once 去重后,见上)。**R4 根因2 成本补记**:每次 pair 还须
1 次 `resolve_active_into(handle_id, out_ref, lease)` 句柄→carrier 解析(spatial-grid R6,
零分配 lease,非 carrier 引用拷贝),最坏 ~45,753 次 resolve/pair + 每 enemy 自身 1 次 ≤
303 次——此 resolve 调用**计入 AC-E2b QUERY_CONSUME 子预算**(连同 pair-ops 与
distance 计算)。pair-ops 上界 + resolve 上界一并计入 AC-E2 QUERY_CONSUME 子
预算(见 §4.2/§8)。行为契约:**单调收敛**——单遍后两两 overlap 之和严格单调
递减(R14 fix:原"N≤3 帧收敛至 ε"对大簇数学不成立,信息每帧传 1 hop、2D 簇
直径 ~17 需 ~17 帧;降级为"overlap 之和单调递减 + 收敛至 ε(帧数 f(cluster
diameter) 非定值 3)",见 §4.2/AC-E10a)。不要求单遍严格 overlap≤0(数学不可实现,
见 §4.2)。`separation_radius`/`max_enemy_bound`/`max_separation_radius` 由
§4.6 定义并回填 registry。质量比具体数值 defer 节点架构 ADR,但**行为方向契约
可测**(质量大的敌人收到修正 ≤ 质量小的,见 AC-E11)。

### 3.10 GameRoot phase 参与

EnemySystem 注册 `participant_id="enemy_system"`,allowed phases:

| phase | 职责 |
|---|---|
| SPAWN_INTENT | 对 SpawnDirector 已 borrow 的敌人执行 SpatialGrid `insert_into` + bind spatial_handle |
| MOVEMENT_COMMIT | 逐 handle 算追踪位移 + 分离修正 → `stage_position` |
| GRID_SYNC | (被动) |
| QUERY | 写分离 query buffer(`query_circle_into`) |
| QUERY_CONSUME | tick T读query结果并写`next_separation_correction[T]`；只由tick T+1 MOVEMENT_COMMIT消费，禁止同tick逆序回写 |
| DEFERRED_REMOVAL | 死亡gameplay fact写`CommittedGameplayFactLedger`；回收使同一lifecycle row按`GRID_REMOVED→POOL_UNBOUND→POOL_RELEASED|POOL_RETIRED`推进；visible committed row=0则0 publish、>0则matching end/fault convergence恰一次batch authority publish |
| POST_DEFERRED_BARRIER | (被动) |

`run_phase(phase, context, lease) -> int` 零分配。敌人 `_physics_process`
默认关闭。POOL_EXHAUSTED/OBJECT_INVALID 由 GameRoot 进 ControlledGameplayFault
(GameRoot R5/R9)。borrow 与 insert 的时序协调(同 phase 还是跨 phase)随
SpawnDirector GDD 协调(Not Started)。

### 3.11 死亡与回收

死亡触发:受击后 health ≤ 0(Combat 调用 `take_damage`,见 §3.12)。流程
(DEFERRED_REMOVAL):
1. **死亡事件先写入 GameRoot 预分配 SoA staging bank，并以稳定fact ID提交到`CommittedGameplayFactLedger`的`DEATH`行**(不走 `signal.emit`,遵 §3.4
   零分配;R14 fix:Vector2 无法直接入 PackedInt64Array,采 SoA 并行 PackedArray
   布局):payload固定为`{death_fact_sequence,enemy_id,borrow_id,behavior_id,death_position(Vector2),spawn_seed,spawn_provenance,source_choice_id}`；其中fact sequence与已预留/提交DEATH行逐字段相同，enemy/borrow组成完整当前lifecycle identity，provenance为SpawnDirector冻结的int32 enum；`source_choice_id`逐字段复制当前SpawnContext，非Risk为0、Risk为对应非零choice ID。
   拆入8条BATTLE_LOADING预分配定容(303)并行数组——
   `PackedInt64Array death_fact_sequences` + `PackedInt64Array death_enemy_ids` +
   `PackedInt64Array death_borrow_ids` + `PackedInt32Array death_behavior_ids` +
   `PackedVector2Array death_positions` + `PackedInt64Array death_spawn_seeds` +
   `PackedInt32Array death_spawn_provenances` + `PackedInt64Array death_source_choice_ids`。
   写入用 write-index 计数器直接索引写(`arr[idx] = value`,PackedArray 索引写
   零分配),**禁 `append()`**(可能 realloc)。消费方(DropSystem/#18)按 write-index
   边界读。**F-11 fix(reset 语义 + 消费者每帧读契约)**:`write_index` 在每帧
   DEFERRED_REMOVAL 写入开始前**归零**(BATTLE_LOADING 不重分配数组本体,仅计数器
   归零,旧元素就地覆盖)。消费者契约:消费者须在**同帧** DEFERRED_REMOVAL 之后、
   下帧归零之前读完 `[0, write_index)` 区间(跨帧读 = 读到被覆盖的陈旧 payload);
   故消费者须**每帧全量消费**,不保留跨帧游标。`write_index` 归零时点(DEFERRED_REMOVAL
   起点)由 GameRoot phase 排序保证在所有死亡写入之前,防本帧写入被误清。
2. **死亡 VFX 在独立 VFX 池节点播放**(decision 2026-08-25,解 §9.2 defer):
   death 事件触发 VFX 系统在 `death_position` 生成 `death_vfx_id`(Config
   behavior 表索引),VFX 在独立池化节点(与 `damage_number` 同 criticality=
   PRESENTATION 兄弟)上播放,**不阻塞敌人回收**。敌人节点可立即
   `reset_for_pool`——VFX 独立存在,不截断、不错位(避免"回池后再播死亡特效"
   锚到新 borrow 位置)。
3. DropSystem 从 staging bank 读死亡事件消费(掉落判定)。
4. 以稳定death/lifecycle intent ID执行`remove`(BLOCKING)，并使**同一条**lifecycle row按`RESERVED→GRID_REMOVED→POOL_UNBOUND→POOL_RELEASED|POOL_RETIRED`单调推进。`remove=OK`后旧handle不可回滚；后续失败由GameRoot依据已提交fact与row在visible committed row>0时于fault convergence恰一次batch authority publish后进入fault，EnemySystem不得重放已完成步骤。lifecycle journal不承载DEATH/drop/reward等gameplay fact。

死亡事件8字段payload供Drop/RiskChoice按`death_fact_sequence ASC`与matching committed DEATH逐字段join；缺字段、stale borrow、duplicate conflict或Risk choice不匹配均不得猜测关联。
Boss 死亡额外触发 #18 阶段结束(经 staging latch,#18 在其 own phase 消费)。

### 3.12 受击与伤害边界

EnemySystem 不计算伤害(归 Combat/DamageSystem)。敌人暴露
`take_damage(amount, source)` 供 Combat **直接方法调用**(非 `signal.emit`,
遵 §3.4 零分配;`take_damage` 内部须不 emit 带参信号),内部扣血 + 受击反馈;
击退vector由Combat传，EnemySystem在MOVEMENT_COMMIT叠加，并在发布前执行
完整足迹world-domain guard；不得clamp或wrap。`knockback_max`归属Combat/DamageSystem
owner(Open Question #2 确认)。**玩家-敌人接触检测**:因敌人非物理(§3.8
不使用 CollisionShape2D/碰撞层),player-enemy 接触检测由 Combat/DamageSystem
侧用 SpatialGrid `query_circle_into`——以 `player_position` 为查询中心、
`ENEMY` 为 type_mask filter——实现(GD3 fix:SpatialGrid R2 type_mask 无 PLAYER
类型,仅 ENEMY=1/PROJECTILE=2/DROP=4/ALL=7;player 不入 grid,作查询中心非
查询目标),非 Godot physics 信号;4.7 `CollisionShape2D.one_way_collision_direction`
不适用(敌人
非单向平台)。circle query 假定圆形 shape;Boss 长条形精确接触 defer Combat/VFX。
击退有 1-tick 延迟(受击在 DEFERRED_REMOVAL 判定,knockback 下帧
MOVEMENT_COMMIT 叠加),16ms 可接受。

**B4 fix(第二轮复审,血傀儡自爆不可跳过)**:血傀儡(behavior_id=5)自爆触发血量
30%。若 Combat 单次 `take_damage` 把 health 从 >30% 直接打到 ≤0(高爆发/暴击),
health 跨越 30% 阈值未停留,自爆预警丢失,违 §2 可读性(玩家无法读 telegraph)。
**裁定**——`take_damage` 内部检测 health **跨越** 30% 阈值(非停留判定):
health 从 `>0.30·max_health` 变为 `≤0.30·max_health` 时立即 latch 自爆预警 intent
(不可跳过,跨阈值即触发)。**R4 根因5 跨阶段触发机制声明**:`take_damage` 在
**DEFERRED_REMOVAL** phase 运行(§3.12),而 FSM 驱动在 **MOVEMENT_COMMIT**(§3.6,更早 phase)。
跨越检测与 FSM 触发不同相——`take_damage` 检测到 health 跨 30% 时:(1) 设 carrier
`mini_fsm_event_flag=true`(权威 latch 点,载体字段见 §3.4);(2) latch 自爆预警 VFX intent(经
staging bank)。FSM **下一帧 MOVEMENT_COMMIT** 轮询 `mini_fsm_event_flag`→ 消费(flag 归零)→
触发 CHASING→TELEGRAPH_SELF_DESTRUCT 迁移(§7.4 L897)。**1-tick 跨相延迟**(类击退 §3.12 L426
1-tick 延迟,16ms 可接受,已显式声明;消除原"机制未声明"实现歧义)。**双 latch 权威裁定**:
自爆预警 VFX intent 的权威 latch 点为 **§3.12 take_damage**(DEFERRED_REMOVAL),§7.4 L897 FSM
CHASING 行只轮询消费 flag、不二次 latch(消除 §3.12 L433 与 §7.4 L897 双 latch 歧义)。
预警期间即使被击杀至 health ≤0,仍播放自爆 VFX
(预警 latch 优先于死亡流程,死亡 VFX 与自爆 VFX 可同帧叠加)。自爆 intent 经
staging latch 同死亡/技能路径(零分配,§3.4/§3.11)。这要求 `take_damage` 内部
知晓 behavior_id=5 的自爆阈值——以 Config behavior 表查询(非硬编码),与其他
behavior 的 damage hook 统一入口。**自爆伤害归属裁定(第三轮复审 B-5,解 GD-BR2)**:
  自爆伤害归 **Combat/DamageSystem**(与 §3.12"EnemySystem 不计算伤害"原则一致)——
  EnemySystem 在 SELF_DESTRUCT 状态只 **latch self-destruct intent**(写 GameRoot 预分配 staging
  slot,payload = `{borrow_id, behavior_id=5, self_destruct_position, self_destruct_radius, spawn_seed}`,
  零分配,§3.4/§3.11 同死亡/技能路径),Combat 在其 own run_phase pull 后用
  `query_circle_into(self_destruct_position,self_destruct_radius,ENEMY,enemy_buf,lease)` 查询敌人；玩家受击不查询不存在的PLAYER Grid type，而是读取matching `PlayerMotionCommitCarrierV1`并对玩家圆形足迹做一次直接窄相。
  §7.4 血傀儡参数补"自爆伤害值 defer Combat behavior 表"(EnemySystem 不回填伤害数值)。
  §8.11 AC-E30h 守卫"EnemySystem 只 latch intent 不直接施加伤害"(归 AC-E25 damage 边界)。
  **死亡-during-预警 edge**:预警期间(TELEGRAPH_SELF_DESTRUCT)health 被打到 ≤0 时,仍触发
  自爆 intent latch(预警 latch 优先于死亡流程,自爆 VFX 与死亡 VFX 可同帧叠加,§3.11 B4 fix);
  自爆伤害是否仍施加由 Combat 决定(EnemySystem 已 latch intent,Combat pull 即施加)。

### 3.13 Player revive threat snapshot 与 clear lifecycle boundary

EnemySystem在Loading期建立两个独占backing的`EnemyThreatSnapshotV1` bank与单一selector，schema固定为：

`{schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,bank_id:int32,publish_revision:int64,tick_revision:int64,authority_revision:int64,count:int32,capacity:int32,enemy_ids:PackedInt64Array,object_instance_ids:PackedInt64Array,spatial_handle_ids:PackedInt64Array,borrow_ids:PackedInt64Array,centers:PackedVector2Array,class_codes:PackedInt32Array,shape_codes:PackedInt32Array,bound_radii:PackedFloat64Array,next_tick_swept_bound_radii:PackedFloat64Array}`。

- `capacity=303`且九个parallel array长度精确303；`[0,count)`包含所有本tick可威胁玩家的active NORMAL/ELITE/BOSS，不得只写Grid命中子集。物理顺序任意，不是玩法ABI。
- 每行完整lifecycle identity非零且tuple唯一，center为published real_t32位置，`bound_radii`为对应behavior实际玩法形状的finite保守外接圆；class冻结为`NORMAL/ELITE/BOSS`。
- MVP所有NORMAL的`shape_code`必须为`CIRCLE`，且`bound_radii`就是实际玩法碰撞圆半径；非圆NORMAL配置使battle load失败，不能用保守外接圆多清。`next_tick_swept_bound_radii`以当前center为圆心，固定至少为`bound_radii + max_legal_center_displacement_next_tick`，覆盖该behavior下一tick追踪、分离修正、冲刺/静止分支的所有合法center；任何row小于current bound或缺behavior上界都使battle load失败。ELITE/BOSS不进入clear，但current+swept bound都参与安全评分。
- Enemy只写inactive bank，完整校验后切selector；Player只能消费matching battle/config/tick/authority/publish revision的只读view。Active禁止resize/append/duplicate/backing替换。

Player复活只写容量300的私有`ReviveClearIntentBankV1`，每行携带完整`{enemy_id,object_instance_id,spatial_handle_id,borrow_id,reason=REVIVE_CLEAR}`并已按`{enemy_id,object_instance_id,spatial_handle_id,borrow_id}`升序总序canonical sort；不要求enemy_id单字段唯一。Player随后调用注入的`ReviveClearLifecycleResolverCapabilityV1`，由Enemy/GameRoot resolver在PONR前为全部row预留journal row/checked sequence并逐字段核对当前lifecycle identity，才允许DAMAGE fact commit；PONR后仍由同一resolver只推进已预留row，不得新建row。所有`REVIVE_CLEAR` journal row固定`participant_id=ENEMY`，计入ENEMY `LIFECYCLE_INTENT=303`上界；Player contribution保持0，且Player不持有journal backing、不执行Grid/Pool副作用。`REVIVE_CLEAR`只允许Player用`distance≤player_radius+enemy_shape_bound`选择真实重叠/相切NORMAL，不能清ELITE/BOSS或正净空NORMAL；它不产生DEATH、kill、XP、drop、reward或record。300只是workspace/intent容量压力上界，不是production清场目标。

复活事务在phase5后先消费matching terminal precollection；若winner为FATAL/VICTORY则不得建立clear计划。否则先完整reserve所有clear journal rows、sequence与commit capability，再由Player提交非零DAMAGE fact，该commit是唯一PONR；Enemy clear rows只能随后推进。Enemy不得用首条Grid remove重新定义PONR，也不得在DAMAGE fact尚未COMMITTED时执行clear side effect。

## 4. Formulas

> 本节公式由 EnemySystem owner 冻结;数值参数待 Config 调参后回填。
> lean 模式下 systems-designer 派生审在 design-review 阶段(新会话)进行。

### 4.1 追踪位移(普通敌人)

```
direction = Normalize(player_position - enemy_position)   # 用 Godot Vector2.normalized();零向量返回 Vector2.ZERO
if direction == Vector2.ZERO:
    direction = last_known_direction or spawn_facing      # 确定性 fallback,防敌人叠玩家点 NaN/停滞
else:
    last_known_direction = direction                        # 非零帧更新,供后续零向量帧 fallback(F-5 fix:原未声明更新时机,致 fallback 永用 spawn_facing)
displacement = direction × move_speed × delta_time × stage_move_multiplier
separation_to_apply = next_separation_correction   # tick T-1 phase 5 产出；本次读取后立即归零
next_separation_correction = Vector2.ZERO
committed_pos = current_pos + displacement + separation_to_apply + knockback_vector
# last_known_direction 初始化:borrow 时 reset_for_borrow 设为 spawn_facing(Config behavior 表,与 spawn_facing 同源);每非零 direction 帧更新;zero 帧不更新(保留上值)
```

**时序语义（2026-08-28第六轮纠错）**：本次MOVEMENT_COMMIT只消费上一tick QUERY_CONSUME冻结的`next_separation_correction`，读取后立即归零；本tick QUERY_CONSUME再为下一tick写入。`displacement`/`knockback_vector`是本tick值。Grid与视觉只能在本次GRID_SYNC后共同观察含已消费修正的位置；禁止视觉提前应用next槽。knockback与separation可能部分对消（物理合理），不影响正确性。

变量:
- `move_speed`:per-enemy base speed(Config behavior 表,units/sec)
- `delta_time`:固定 1/60(GameRoot 固定步长)
- `stage_move_multiplier`:见 4.3
- `next_separation_correction`:见4.2（tick T QUERY_CONSUME产出，tick T+1 MOVEMENT_COMMIT恰消费一次；完整一physics tick延迟）
- `knockback_vector`:Combat 传入(4.5),1-tick 延迟

### 4.2 位置修正分离

```
# R4 根因2 重写:pair-once 伪代码原 `b.correction -= push` 不可实现——query 返回
# PackedInt64Array handle_ids(int 句柄,spatial-grid R4),非 carrier 引用。声明预分配
# handle→carrier 解析 + 拆 ACCUMULATE/COMMIT 两子步消除 per-enemy 循环内 clamp 竞态。
# BATTLE_LOADING 预分配(spatial-grid R6 `resolve_active_into(handle_id, out_ref, lease)`
# 一次解析一个句柄→carrier slot,零分配 lease out_ref):
#   - 每carrier `next_separation_correction: Vector2` 跨tick槽(§3.4；tick T QUERY_CONSUME起点必须为ZERO)
query_radius = self.separation_radius + max_separation_radius   # 语义统一:用 sep_radius 上界,非 shape_bound
neighbors = query_circle_into(prev_committed_pos, query_radius, ENEMY, buf, lease)  # 读上帧快照,排除 self handle;返回 PackedInt64Array handle_ids + scalar count(spatial-grid R4)
# ── ACCUMULATE 子步(配对写双方累加器,不 clamp;消除循环内 clamp 竞态)──
for b_id in neighbors:                        # b_id 是 int 句柄,非 carrier 引用
    if b_id <= self.handle: continue          # R1 fix (Option B):inline pair-once 去重,仅处理 handle>self,全局每对一次
    resolve_active_into(b_id, b_ref, lease)   # 句柄→carrier 解析(spatial-grid R6,零分配 lease out_ref)
    overlap = (self.separation_radius + b_ref.separation_radius) - distance(self.pos, b_ref.pos)
    if overlap > 0:
        if distance(self.pos, b_ref.pos) == 0:      # 零向量退化(B1 fix):Normalize(零向量)致死锁
            correction_dir = deterministic_axis(self.handle, b_id)   # 见下固定公式
        else:
            correction_dir = Normalize(self.pos - b_ref.pos)   # 用 Godot Vector2.normalized()
        push = correction_dir × (overlap / 2)    # 等质量各推一半;质量比见下
        self.next_separation_correction += push       # 写双方next槽(Option B),累加不clamp
        b_ref.next_separation_correction -= push
# ── COMMIT 子步（tick T phase 5全累加后统一clamp并冻结，禁止apply位置）──
#   对每个active carrier c：
#     c.next_separation_correction = clamp_magnitude(c.next_separation_correction, c.separation_radius)
#     tick T+1 §4.1 MOVEMENT_COMMIT读取该值一次、立即清零并叠加进committed_pos
```

**`deterministic_axis(h_a, h_b)` 固定公式(R-AI N5 fix,可测;F-2 fix 参数序+括号)**:
```
angle = ((((h_a * 2654435761) ^ h_b) mod 65536) / 65536.0) × TAU   # 16-bit hash → [0, 2π);GDScript 用 `^` 非 XOR 关键字;显式括号防优先级歧义
return Vector2.from_angle(angle)                                   # 每对确定唯一方向,避免同轴对称重合(b 被夹中净修正 0)
```
基于 handle 对的确定 hash 派生角度(非简单 `sign(b-a)`——后者致 3 同位敌人 b 净修正 0 卡中,见 R-AI N2)。无 `Math.random`,可复现。**参数序约定(F-2 fix)**:`h_a < h_b`(Option B 已保证调用方 `self.handle < neighbor.handle`,直接传即可;函数内不二次规范化,故 `deterministic_axis(a,b)` 对换参数得不同结果——XOR 非对称,这是期望行为)。AC-E10b 断言帧 1 `correction_dir == deterministic_axis(h_a, h_b)` 据此参数序。**术语澄清(第三轮复审 IC-1)**:此处"规范化"指 `Vector2.from_angle()` 输出单位向量(AC-E10b 语义,"函数内规范化"=输出归一);§4.2"函数内不二次规范化"指不规范化参数序(不在函数内做 min/max(a,b))。两者维度不同,共用"规范化"一词致语义重叠;数值无歧义,oracle 可写且确定(CD 终裁降 RECOMMENDED,同意 godot-gdscript-specialist + qa-lead tie-break;systems-designer 的措辞矛盾 BLOCKING 降级)。**加固(QA-16)**:AC-E10b 补 known-answer 断言——固定 handle 对(h_a=10,h_b=20)→ 期望向量 = `deterministic_axis(10,20)`(预计算常量),强化 tautology oracle。

**契约:单调收敛(decision 2026-08-25,降级 AC-E10,R14 fix)**:不要求单遍严格
overlap≤0(数学不可实现:链式 A-B-C 单遍不收敛)。契约改为:**单遍后两两 overlap
之和严格单调递减**(向收敛靠近);**收敛至 ≤ ε**(ε = `separation_radius × 0.1`,
玩家视觉不可感知),收敛帧数 = f(cluster_diameter)(非定值 3——信息每帧传 1 hop,
2D 簇直径 ~17 需 ~17 帧;原"N≤3 帧"对大簇不成立,已降级)。

**clamp 不变量例外(SD1 fix,声明;F-6 fix 记号类型修正)**:原写
`correction_self + correction_neighbor == overlap` 记号有类型错误(Vector2 + Vector2
不可 == 标量 overlap)。正确不变量:**未 clamp 的 pair 上,双方修正等大反向且沿 pair 轴
投影长度和 == overlap**,即 `correction_self = +push`、`correction_neighbor = -push`、
`|push| == overlap/2`(等质量),或质量比下 `|correction_self| + |correction_neighbor| == overlap`
且方向相反(沿 pair 轴)。当某敌总修正被 `clamp_magnitude` 截断时,其参与的各 pair 局部
违反该等式(被 clamp 一侧实收 < 期望),为**软约束接受**(防密集簇 overshoot/振荡优先
于严格 per-pair 等式)。AC-E11b 同时断言未 clamp 场景的严格等式 + clamp 场景的
"重者位移 ≤ 轻者位移"方向不等式。AC-E10a(b) 据此 clamp 场景降级为全局 overlap 有界非增
(见 §8.4)。

变量:
- `separation_radius`:per-enemy 期望分离距离(Config behavior 表)
- `max_separation_radius`:所有敌人 separation_radius 上界(registry 回填,见 4.6)
- `max_enemy_bound`:全局形状包围半径上界(registry 回填,见 4.6)
- **query_radius 用 max_separation_radius(非 max_enemy_bound)**:保证 query
  覆盖所有 overlap>0 的邻居(B2 fix)。须满足 `max_separation_radius ≥
  max(per-type separation_radius)`(恒成立,定义即上界)。
- `distance()`:须用 SpatialGrid canonical `spatial_distance_components`(float64,
  固定运算顺序,遵 spatial-grid F2),与 grid query 过滤一致(R5 fix)。
- 普通敌人等质量→各推 overlap/2;精英/Boss 质量更大→按质量比分配
  `correction_self = overlap × (mass_other / (mass_self + mass_other))`
  (数值 defer 节点架构 ADR,但**行为方向契约**:质量大者收到修正 ≤ 质量小者,
  且双方修正等大反向、沿 pair 轴投影长度和 == overlap(不变量恒成立,F-6 记号),
  见 AC-E11)。
- `clamp_magnitude(v, max)`:若 |v|>max 则缩放到 max,否则不变。

### 4.3 阶段倍率(source §14.3)

```
stage = Max(0, floor(battle_time_seconds / 60))   # 以分钟为阶段;下界 0(R5 fix:负 battle_time → 负 stage → 负倍率→敌人出生即死)
stage_health_multiplier = Min(health_multiplier_cap, 1 + stage × 0.18)
stage_damage_multiplier = Min(damage_multiplier_cap, 1 + stage × 0.12)
stage_move_multiplier = Min(1.35, 1 + stage × 0.03)
```

- 阶段以分钟计,`battle_time_seconds` 从 GameRoot context 读。
- 倍率应用于 spawn 时 max_health/base_damage/move_speed。
- 难度优先组合/密度/行为调整,不只堆血(source §14.3)。**节拍感锯齿张力**
  由 SpawnDirector 波次调度提供,非本倍率;本倍率只提供单调基准。
- **health/damage cap(decision 2026-08-25)**:`health_multiplier_cap`=3.0/
  `damage_multiplier_cap`=2.5(见 §7.2,已冻结值)防长局发散(无 cap 时 30 分钟
  health=6.4×、60 分钟=11.8× 违 §2"更乱更密 not 更肉更慢")。cap 数值关联玩家 DPS
  增长曲线:若玩家 DPS 12 分钟内增 ≥3.16× 则 3.0 封顶合理(健康压力与 DPS 匹配);
  若 DPS 增长不足须 balance pass 调斜率 0.18→0.10 或改 log 曲线(**R-F13 fix:
  删原 advisory "cap 可设 3.5 左右"——与 §7.2 冻结值 3.0 矛盾;3.5 是讨论过的备选,
  最终裁决取 3.0 封顶于 stage 12,advisory 3.5 不再保留**)。

### 4.4 ~~屏幕外 LOD 降频(两级)~~ — REMOVED

> 本节继续移除。Stage V2虽有屏外敌人，但MVP正式策略仍是所有active敌统一
> full simulation；可见性不是authority分支。普通敌远距退役由SpawnDirector
> 依据玩家相对矩形阈值执行，不能复用旧LOD计时或隔tick状态。

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
| `enemy_step_bound` | 任一敌人单tick移动/冲刺/击退的完整位移上界 | EnemySystem + Combat | `max(actual_move_speed,charge_speed)×(1/60)×1.35 + knockback_max`；用于domain reachability与swept threat，不是边界容忍带 |
| `max_separation_radius` | 所有敌人 separation_radius **上界**(query_radius 用,见 §4.2) | EnemySystem | `max(per-type separation_radius)`;per-type 在 Config |
| `separation_radius` | (同 max_separation_radius,registry 旧名)max_query_radius 全局预算用 | EnemySystem | = `max_separation_radius`;见上 |
| `knockback_max` | 击退最大越界 | **Combat/DamageSystem** | 归属声明:Combat/Damage owner(Open Question #2 确认);EnemySystem 只消费 |

> **registry entry 补充(advisory,回填时执行)**:上述 gated 值
> (`max_enemy_bound`/`enemy_step_bound`/`max_separation_radius`)当前仅
> 作为 `max_query_radius`/`world_reachability_budget` 公式输入出现,无独立
> source-owned registry entry。Config 调参后回填时须补独立 entry(source:
> enemy-system.md)。`deterministic_axis(handle_a, handle_b)` 零向量退化轴
> 非跨边界事实(仅本 GDD 内),不入 registry。

### 4.7 World-domain 与远距退役边界

- EnemySystem每次movement/blink写inactive motion bank前，验证完整足迹位于
  `world_safe_aabb=[-16384,16384]²`；不做clamp、wrap、suspend或origin rebasing。
- Config以1800秒技术时限和`world_reachability_budget`证明合法速度、复活、
  spawn outer extent、despawn margin与最大actor bound不会触达技术域。违反即
  Loading失败；运行时仍越域则`POSITION_OUT_OF_RANGE`→ControlledGameplayFault。
- 普通敌是否因远离玩家而退役不由EnemySystem自行判断。SpawnDirector在
  DEFERRED_REMOVAL生成无奖励retire intent；EnemySystem只按同一lifecycle journal
  执行Grid remove→Pool release。elite/Boss不走此距离退役路径。

## 5. Edge Cases

### 5.1 池耗尽(POOL_EXHAUSTED)

- enemy_normal pool(320)耗尽:borrow 返回 POOL_EXHAUSTED → GameRoot 进
  ControlledGameplayFault。EnemySystem 不再产出本 fault tick 的死亡/掉落 staging；是否结算 fault 前已提交事实与技术补偿只由 GameRoot `RunOutcomeEnvelopeV1`/Save 状态机决定。
- 预防:SpawnDirector admission check 先于 borrow(ENEMY cap=303,普通 298
  上限),理论上 borrow 不应耗尽(320 pool > 298 active)。若耗尽说明状态
  泄漏(slot 未归还),FAULT 是正确响应。
- enemy_elite pool(6)耗尽:精英active并发上界4，另有spawn-before-release 1与spare 1；若耗尽同上。
- enemy_boss pool(1):Boss 唯一,borrow 失败说明 Boss 已存在,SpawnDirector
  须先查 active。

### 5.2 CAPACITY_EXCEEDED(SpatialGrid R9 / AC-E11)

- SpawnDirector admission check:ENEMY 注册数 ≥ 303 时普通怪 borrow 抑制
  (发布前抑制,fresh insert only)。
- 精英/Boss 预留 5 槽(4 elite + 1 boss):普通怪上界 298,即使精英/Boss
  未激活也不挤占预留。
- CAPACITY_EXCEEDED 不产生幽灵实体(AC-E11):被抑制的 spawn 请求不创建
  Node、不借 pool、不 insert grid。

### 5.3 精英并发(夺宝持久化)

- 精英 `max_concurrent = 4`(RiskChoice设计冻结):两只夺宝机缘精英与6:00/10:00两只fixed Elite均未死亡时可同时在场。
- 4 精英占 303 cap 中的 4 槽，normal hard cap=298并另保留1 Boss槽；Pool 6按4 active+1 spawn-before-release+1 spare精确定容。
- 本裁决替代旧的“2 Elite + safety spare”解释；后续若要第5只active Elite，必须同步修订RiskChoice、Config、Spawn、Grid、Pool与本GDD，不能继续借spare。

### 5.4 Grid 失效 / teardown

- 正常phase 6必须在Grid有效时让同一intent row随`remove→unbind→release/reset`单调推进。Fault teardown先停止consumer/phase；GameRoot从journal与fact ledger完成owner logical detach，并按visible committed row=0/＞0执行0/恰1次batch authority publish，再使Grid全局invalid，最后调用Pool teardown best-effort reset/queue_free。Grid已invalidated后禁止伪造一次`remove=OK`；teardown的全局invalidation本身就是旧handle全部stale的已提交事实。
- EnemySystem 不直接拥有 Grid/Pool teardown 顺序，也不在 Grid invalid 后逐 enemy 调 operational remove。任何 release-before-remove（正常 phase）或 invalidation 后继续 operational mutation 都是 fault。

### 5.5 Paused quarantine(resume binding)

- 暂停(机缘选择/升级)时敌人进 quarantine(Object Pooling R6/R7):
  carrier `quarantine_revision` 标记,position frozen。
- resume:binding transaction 重新绑 SpatialGrid handle(若 grid 重置)或
  恢复 stage_position。
- 暂停期间敌人不更新(phase 驱动,GameRoot 停 phase 即停更新)。

### 5.6 Boss 阶段切换

- Boss capability由Enemy在phase6实际应用matching damage resolution并取得receipt后判定50% crossing、exact-once排队；phase5 lethal projection保持只读无状态写。Enemy在下一Active `MOVEMENT_COMMIT`同步调用`on_phase_transition(PHASE_2)`。release PONR前telegraph取消，
  BITE只收敛当前18-tick segment，已release projectile由其owner继续，recovery取消；随后进入90-tick
  PHASE_SHIFT。不存在动画帧节拍或当帧偷偷换参数。
- 阶段切换不销毁/重 borrow Boss(pool_key=3 唯一);只切 FSM 状态集。
- 切换时若 Boss 在分离修正中,修正继续(载体行为不因阶段切换中断)。

### 5.7 ~~屏幕外失步~~ — REMOVED(随 §4.4 LOD 移除)

> 原 edge case 基于已移除的 reduced-LOD 隔 tick 更新。LOD 移除后所有敌人
> 每 tick full 更新,无屏幕外失步。死亡事件每 tick 在 DEFERRED_REMOVAL 检
> health(不受 LOD 影响,此条保留)。

### 5.8 远离玩家与技术域越界

- 普通敌中心越过玩家相对`spawn_outer_half+despawn_margin`时，由SpawnDirector
  生成无奖励退役intent；这不是死亡，不产出DEATH fact、掉落或击杀统计。
- elite/Boss不按距离自动退役，继续full simulation与draw-cull。
- 任意敌完整足迹越`world_safe_aabb`不是正常退役条件，而是配置/状态破坏：
  motion snapshot不发布，进入ControlledGameplayFault；禁止clamp回玩家附近。

### 5.9 ControlledGameplayFault

- GameRoot R5/R9:POOL_EXHAUSTED/OBJECT_INVALID/phase failure →
  ControlledGameplayFault。
- EnemySystem不写胜负/死亡纪录/教程，也不自行计算奖励或补偿。正常Outcome尚未seal时，GameRoot以`TECHNICAL_ABORT`展示“战局状态异常”并只消费fault前已提交facts；若正常Outcome已经seal，后续Enemy cleanup fault不得改写`outcome_kind`，只记录独立`RunCompletionStatusV1.completion_fault_code`。任何路径都严禁把fault tick未COMMITTED staging当成奖励来源。
- 敌人状态:phase 停,所有 enemy frozen;池不归还(局结束统一 teardown)。

### 5.10 零距离重合退化(新增)

- 两敌人 `self.pos == neighbor.pos`(distance=0)时,§4.2 用
  `deterministic_axis(handle_a, handle_b)` 选固定单位向量(基于 handle 差的
  确定性方向),保证 overlap 单调递减不致死锁(详见 §4.2)。300 敌人汇聚
  玩家点时此退化必现,已显式处理(非"待实现")。

### 5.11 spawn_context 版本不匹配

- spawn_context schema 按 carrier version 与 pool_key contract版本化。
- RiskChoice集成已把carrier升级为v2；旧v1 spawn_context
  与新 contract 不兼容 → borrow 前 version check,不匹配 FAULT。
- 当前v2为10字段：V1五字段加provenance、choice ID、stage snapshot ID与两个属性倍率。

### 5.12 Perf-pressure 优雅降级(decision 2026-08-25,R-PA C1/C2 闭合;第二轮复审诚实化)

- LOD 移除(§4.4)后,sim 降级 escape valve 真空——仅剩"full sim"与
  "ControlledGameplayFault(abort 整局)"两档(R-PA 指出此风险)。
- **裁定(诚实化,第二轮复审修订)**:原"不恢复旧 LOD"为绝对话,与档1语义矛盾。
  旧 sim-LOD(隔 tick 更新全 sim)与 §4.2 单调收敛契约(假设每 tick 更新)直接冲突,
  旧固定arena下reduced-sim-LOD曾是死代码；Stage V2后仍因authority一致性而不恢复。
  但**分离域 distance-LOD ≠ 已移除的 sim-LOD**(作用域是分离 query 而非全 sim,
  keying 是"距玩家"而非"屏内外")。escape valve 降级**分离质量**而非 sim 帧率,阶梯:
  1. **分离域 distance-LOD**(诚实命名,是新 LOD 非旧 sim-LOD):远离玩家的敌人
     分离 query 隔 tick。**此档激活时 AC-E10a 降级为"隔 tick 单调非增"**(被 skip tick
     的 pair 不处理,overlap 之和可能持平非严格递减;见 §4.2/AC-E10a 分段契约)。
  2. 分离 query radius 动态收缩:**残留 overlap 守卫**——收缩致邻居漏检,漏检 pair 的
     overlap 不被处理 → 系统性残留 overlap(敌群堆积玩家点)→ **集中接触 DPS 不公平爆发
     风险**(违 §2"可控压力")。须声明残留 overlap 公平性 trade-off + **残留 overlap 上限
     守卫**(单点堆积敌数 ≤ N_safe,超阈值强制 fallback 档3/4 而非容忍无界堆积)。
  3. `pair-ops/frame` 上限 + 残留 overlap 下帧消化:**持续全聚集稳态下此档永不消化完**
     (每帧都超上限),与档2 同样产生持久残留 overlap;AC-E10a 降级为"有界残留"。
  4. 最后才进 ControlledGameplayFault。
- **escape valve 兜底能力诚实声明**:档1-3 本质"用分离精度/玩法公平换 CPU",在全聚集
  割草稳态(非 edge case,见 §2 Player Fantasy"被怪潮包围")下可能**仍不够**——分离降级
  转译为玩法问题(堆积/不公平死亡),最终仍可能 FAULT。**此 valve 是 best-effort 退路,
  非保证兜底**。
- 具体机制与阈值 **defer AC-E1 真机数据 + OQ9 spike**(无 min-spec 真机/GDScript 可行性
  spike 前不冻结);J2 budget ADR + OQ9 spike 为性能 AC release-gate 升级**前置门**(非
  并行项,见 §10 OQ9 / §8.1 AC-E1/E2b spike-gated)。

## 6. Dependencies

### 6.1 上游依赖(本 GDD 须遵循)

| 系统 | 状态 | 依赖契约 |
|---|---|---|
| SpatialGrid | Re-review Pending | ENEMY type_mask=1 注册;phase insert/stage/remove;`query_circle_into`(sep_radius+max_separation_radius,语义统一见 §4.2);phase-6 remove journal；R9 CAPACITY_EXCEEDED 303;R10 排除 self handle |
| Object Pooling | Re-review Pending | 三 pool_key(1/2/3,capacity 320/6/1);Poolable contract(reset_for_borrow/reset_for_pool 零分配);phase-6 release/retire journal；paused quarantine与三次resume publish |
| Config/Data | Draft(foundation 冻结) | EnemyNormalPoolable/v1/Elite/v1/Boss/v1 factory contract;6 普通共享 normal contract(behavior ID 区分);behavior 表(属性/动画/攻击);criticality=GAMEPLAY |
| GameRoot | Draft | phase participant(`participant_id`/`run_phase`/allowed phases);7 phase 顺序;`_physics_process` 默认关闭;R5 status+rollback;R9 ControlledGameplayFault |
| Stage | In Review / Re-review Pending | Camera2D锁玩家；22.5×40可见域；玩家相对offscreen ring；`world_safe_half_extent=16384`；无玩法边界clamp |
| RNG | Re-review Pending(间接) | 不直接依赖;`spawn_seed` 由 SpawnDirector 从 `run_seed`(GATE-G2)派生传入 spawn_context；diagnostic sidecar待集成 |

### 6.2 下游消费者(本 GDD 提供契约)

| 系统 | 状态 | 本 GDD 提供的接口 |
|---|---|---|
| SpawnDirector | Full Review Pending | 玩家相对四strip或summoner-local ring；固定8 attempts/24 RNG words；23-row intake；normal距离退役；SpawnContextCarrierV2十字段；下一tickSPAWN_INTENT借池/insert时序 |
| DropSystem | Designed / Full Review Pending | 死亡事件经GameRoot 303-row staging bank，payload固定8字段`{death_fact_sequence,enemy_id,borrow_id,behavior_id,death_position,spawn_seed,spawn_provenance,source_choice_id}`且不走emit；Drop逐字段join committed DEATH并负责掉落；DEFERRED_REMOVAL死亡→remove→release顺序 |
| Combat/DamageSystem | Not Started | `take_damage(amount, source)`直接调用；`knockback_vector/max`边界；health≤0死亡staging；敌人AoE只查`ENEMY`，玩家受击读取`PlayerMotionCommitCarrierV1`后直接窄相，禁止`PLAYER` Grid type；精英技能intent由Combat在QUERY_CONSUME pull |
| PlayerController | Re-review Pending | 已静态接纳A/B `EnemyThreatSnapshotV1` current+swept schema；提交足迹相交NORMAL的完整tuple总序`ReviveClearIntentBankV1`，Enemy/GameRoot按terminal precollection、full-reserve、fact-first PONR与journal收敛；runtime integration待证 |
| BossStateMachine #18 | Designed / Full Review Pending | behavior8内容唯一owner；Enemy内typed capability、下一MOVEMENT_COMMIT阶段切换、Boss基础追踪/受击/死亡与pool_key=3载体契约 |
| RiskChoiceSystem | Designed / Full Review Pending | `SpawnContextCarrierV2` provenance/choice/stage/1.30倍率；4 active Elite、45秒后不退场、death join只读 |
| Elite Enemies | Designed / Full Review Pending | behavior 6/7内容唯一owner：FSM/攻击/首伤门/召唤/表现；本GDD仅提供driver与载体 |

### 6.2a GameRoot owner capacity contribution（第九轮传播）

以下actual rows只把既有`max active ENEMY=303`与`behavior_id=0..8`映射到中央容量，不新增或抬高玩法数值：

| required_role_id | capacity_kind | outcome_field_id_or_none | required_max | owner_contract_id | source_gdd_path | role_stable_order | kind_stable_order | field_stable_order |
|---|---|---|---:|---|---|---:|---:|---:|
| `ENEMY` | `LIFECYCLE_INTENT` | `NONE` | 303 | `EnemySystem/v1` | `design/gdd/enemy-system.md` | 4 | 1 | 0 |
| `ENEMY` | `FACT_COMMIT` | `NONE` | 303 | `EnemySystem/v1` | `design/gdd/enemy-system.md` | 4 | 2 | 0 |
| `ENEMY` | `PAUSE_CLOSURE` | `NONE` | 303 | `EnemySystem/v1` | `design/gdd/enemy-system.md` | 4 | 3 | 0 |
| `ENEMY` | `BLOCKING_CHOICE` | `NONE` | 0 | `EnemySystem/v1` | `design/gdd/enemy-system.md` | 4 | 4 | 0 |
| `ENEMY` | `OUTCOME_FIELD` | `committed_kill_type_ids` | 9 | `EnemySystem/v1` | `design/gdd/enemy-system.md` | 4 | 5 | 22 |
| `ENEMY` | `OUTCOME_FIELD` | `committed_kill_counts` | 9 | `EnemySystem/v1` | `design/gdd/enemy-system.md` | 4 | 5 | 23 |

前三条303分别来自active cap下每个完整lifecycle identity在同tick最多一条最终remove/retire intent、death fact与未完成lifecycle closure的保守既有上界；同一identity的正常死亡与`REVIVE_CLEAR`先去重且正常死亡语义优先，二者共享而不叠加突破303。所有revive clear journal row也固定计入ENEMY，不转嫁给PLAYER。PAUSE_CLOSURE的一行对应一个journal intent的`FINALIZE_POOL_RELEASE`，内部unbind+release不拆成606条。0表示Enemy不拥有阻塞选择；9来自behavior 0..8。Config按全局tuple排序并校验组合唯一，禁止把owner-local行号或303/9解释成新spawn目标。

### 6.3 跨系统边界声明

- **spawn_context ownership**:EnemySystem 冻结 `SpawnContextCarrierV2` 10字段；SpawnDirector
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
| `move_speed` | 基础移速(units/sec) | per-type；max影响`enemy_step_bound`与world reachability(4.6/4.7) |
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
| `health_multiplier_cap` | 3.0 | 生命倍率上限(source §2"更乱更密 not 更肉更慢";R13 fix:封顶于 **stage 12**(第 12 分钟),`1+0.18×12=3.16→cap 3.0`,非原误称"~17 阶段";防止后期肉到打不动) |
| `damage_multiplier_cap` | 2.5 | 伤害倍率上限(source §2;R13 fix:封顶于 stage 13(`1+0.12×13=2.56→cap 2.5`);防止后期一击秒杀,违 Player Fantasy"可控压力") |
| `stage_duration_seconds` | 60 | 一阶段=60秒 |

> cap 触发后该倍率不再随阶段增长(仅未达 cap 的维度继续涨),保证后期敌人"更密更快"非"更肉更痛"。

### 7.3 精英 FSM 参数 echo（非权威）

唯一内容源为`design/gdd/elite-enemies.md` §7；本表只供Enemy driver接线核对，
Config hash不一致必须fail closed，禁止从本表恢复旧值。

**巨甲蜈蚣(behavior_id=6)** — CHARGE 三连击 → WEAKENED 循环:

| 参数 | spike 值 | 说明 |
|---|---|---|
| `charge_segment_count` | 3 | 一次chain的冲刺段数 |
| `charge_trigger_range` | 6.0 | 进 TELEGRAPH_CHARGE 的距离阈值(units,§3.6.1 唯一独有,R2 fix 补入 §7.3) |
| `charge_distance` | 6.0 | 单次冲刺位移(units;CHARGE 行进度量沿锁定轴投影,见 §3.6.1) |
| `charge_speed` | 18.0 | 冲刺速度(units/sec,~3× 基础移速;越界核查见 §4.6 elite_charge_overshoot) |
| `charge_telegraph_ticks` | 24 | 冲刺前telegraph(玩家闪避窗口) |
| `charge_link_ticks` | 6 | 每段之间可观察断点；保持原锁定方向 |
| `charge_cooldown_ticks` | 300 | 三段chain完成后的循环冷却 |
| `weakened_ticks` | 150 | WEAKENED窗口(玩家输出机会,不反击) |
| `weakened_damage_taken_multiplier` | 1.25 | PROVISIONAL-BALANCE；Damage owner应用 |
| `knockback_resistance` | 0.85 | 击退抗性(0-1,1=免疫) |

**鬼雾修士(behavior_id=7)** — BLINK + 召唤 + 魂针:

| 参数 | spike 值 | 说明 |
|---|---|---|
| `blink_period_ticks` | 360 | BLINK触发周期(召唤频率=blink频率) |
| `telegraph_blink_ticks` | 18 | BLINK落地前telegraph |
| `blink_offset_min` | 1.5 | 落点偏移半径下界(§3.6.2,玩家点+seed 偏移) |
| `blink_offset_max` | 2.5 | 落点偏移半径上界 |
| `summon_count` | 3 | 单次召唤数量(受 pool cap-full 约束,见 §3.6.2 cap-full 行为 + §5.7) |
| `recover_ticks` | 24 | 魂针完整plan latch后的后摇；旧fan_needle_duration别名废弃 |
| `soul_needle_count` | 3 | 三枚原子Projectile batch |
| `soul_needle_range` | 5.0 | 魂针扇形半径(units;§3.6.2 统一用此名,原 `fan_needle_range` 命名分裂已并) |
| `soul_needle_angle_deg` | 60 | 魂针扇形角度 |
| `soul_needle_telegraph_ticks` | 30 | 魂针plan前预警时长 |
| `knockback_resistance` | 0.5 | 击退抗性 |

### 7.4 普通敌人行为参数(per normal behavior_id)

数值为 spike 锚点(标 `[spike]`,待 Config 调参)。每敌人须有 1-2 秒可识别
行为剪影(§2 Player Fantasy)。

| behavior_id | 敌人 | 可识别行为参数(spike) |
|---|---|---|
| 0 | 噬灵虫 | 直线追踪基础(enemy_normal 基线);spawn 数量权重高(SpawnDirector 用);无 mini-FSM |
| 1 | 铁背妖狼 | 蓄力冲刺 mini-FSM(CHASING/TELEGRAPH_CHARGE/CHARGE/RECOVER,见下状态表):冲刺距离 5.0 / 速度 14.0 / telegraph 0.3s / charge_trigger_range 6.0 / charge_cooldown 4.0 / recover 0.5s / 方向锁定(telegraph 时)`[spike]` |
| 2 | 腐毒妖藤 | 静态喷毒 mini-FSM(IDLE/TELEGRAPH_POISON/POISON,见下状态表):喷毒周期 2.0s(=telegraph 0.4s + poison 1.6s 间隔)/ 范围 3.5 / telegraph 0.4s / poison_duration 0.5s `[spike]`(OQ7 静态与否待 performance 核验) |
| 3 | 甲壳妖虫 | 贴身毒 aura mini-FSM(CHASING/ATTACKING,§3.2 B3 fix):aura 半径 1.2 / 伤害周期 0.5s / stop_distance 1.2 / resume_distance 2.0 `[spike]` |
| 4 | 魔道符修 | 保持距离滞回 mini-FSM(CHASING/REPOSITIONING/SHOOTING,见下状态表):符弹射程 7.0 / 保持距离 5.0-6.0(滞回带:<5.0 后退,>6. 接近,中间停下射击)/ 射击周期 1.5s / shoot_duration 0.3s(射击时停移)`[spike]` |
| 5 | 血傀儡 | 自爆 mini-FSM(CHASING/TELEGRAPH_SELF_DESTRUCT/SELF_DESTRUCT,见下状态表):自爆半径 2.5 / 预警时长 0.6s / 触发血量 30% / 预警 latch 跨阈值不可跳过(§3.12 B4 fix)/ 自爆伤害值 defer Combat `[spike]` |

**normal 桶 mini-FSM 状态表(第三轮复审 B-4,补 B3 fix 覆盖漏洞;仿 §3.6 精英 FSM 表格式 `{trigger, action, next}`)**:

**铁背妖狼(behavior_id=1)** — `CHASING → TELEGRAPH_CHARGE → CHARGE → RECOVER → CHASING` 循环:

| 当前状态 | 触发谓词 | action | 下一状态 |
|---|---|---|---|
| CHASING | `distance(self,player) ≤ charge_trigger_range` 且 charge_cooldown 计满 | 进 TELEGRAPH_CHARGE;锁定冲刺方向 = `Normalize(player_pos - self_pos)`(telegraph 时锁定,CHARGE 中不重瞄准) | TELEGRAPH_CHARGE |
| TELEGRAPH_CHARGE | telegraph 计时 ≥ `charge_telegraph_seconds` | 进 CHARGE | CHARGE |
| CHARGE | 冲刺位移完成(行进 ≥ `charge_distance` 或撞墙 clamp) | 方向锁定不重瞄准(单次冲刺,无 `charge_count`;R4 根因4:原 `charge_count++` 为蜈蚣模板复制残留——狼 §7.4 spike 无 `charge_count` 参数,单冲锋完成直接进 RECOVER,消除 CHARGE/RECOVER 双出口歧义) | RECOVER |
| RECOVER | recover 计时 ≥ `recover_seconds` | charge_cooldown 复位 | CHASING |

**腐毒妖藤(behavior_id=2)** — `IDLE → TELEGRAPH_POISON → POISON → IDLE` 循环(静态不移动):

| 当前状态 | 触发谓词 | action | 下一状态 |
|---|---|---|---|
| IDLE | poison 周期计时 ≥ `poison_period_seconds` | 进 TELEGRAPH_POISON | TELEGRAPH_POISON |
| TELEGRAPH_POISON | telegraph 计时 ≥ `poison_telegraph_seconds` | 进 POISON;释放毒液 intent latch(Combat pull 施加 AoE) | POISON |
| POISON | poison 计时 ≥ `poison_duration_seconds` | 重置 poison 周期计时 | IDLE |

**魔道符修(behavior_id=4)** — `CHASING → REPOSITIONING → SHOOTING → CHASING` 滞回带:

| 当前状态 | 触发谓词 | action | 下一状态 |
|---|---|---|---|
| CHASING | `distance > approach_distance`(滞回上界 6.0) | 接近玩家 | CHASING |
| CHASING | `distance ≤ retreat_distance`(滞回下界 5.0) | 进 REPOSITIONING | REPOSITIONING |
| CHASING | `retreat_distance < distance ≤ approach_distance`(滞回带内)且 shoot_cooldown 计满 | 进 SHOOTING | SHOOTING |
| REPOSITIONING | `distance ≥ retreat_distance` | 停止后退;若 shoot_cooldown 计满进 SHOOTING | SHOOTING / CHASING |
| SHOOTING | shoot 计时 ≥ `shoot_duration_seconds` | 释放符弹 intent latch(Combat pull);shoot_cooldown 复位 | CHASING |

**血傀儡(behavior_id=5)** — `CHASING → TELEGRAPH_SELF_DESTRUCT → SELF_DESTRUCT`(自爆后死亡,不循环):

| 当前状态 | 触发谓词 | action | 下一状态 |
|---|---|---|---|
| CHASING | `carrier.mini_fsm_event_flag == true`(由 §3.12 take_damage 跨帧设,1-tick 跨相延迟,R4 根因5) | 消费 flag(归零);进 TELEGRAPH_SELF_DESTRUCT(预警 VFX intent 已在 §3.12 take_damage 权威 latch,本处仅轮询消费,不二次 latch) | TELEGRAPH_SELF_DESTRUCT |
| TELEGRAPH_SELF_DESTRUCT | telegraph 计时 ≥ `self_destruct_telegraph_seconds`(0.6s) | 进 SELF_DESTRUCT | SELF_DESTRUCT |
| SELF_DESTRUCT | 进入即触发 | 释放自爆 intent latch(Combat pull 施加 AoE 伤害,见 §3.12 B-5)+ 自爆 VFX;敌人 health 强制 ≤0 进死亡流程(§3.11) | (死亡,DEFERRED_REMOVAL) |

### 7.5 spawn_context 字段(已冻结,3.3)

10字段 frozen v2：`behavior_id/spawn_position/spawn_facing/spawn_time_seconds/spawn_seed/spawn_provenance/source_choice_id/stage_snapshot_id/max_hp_multiplier/base_damage_multiplier`。schema 变更须升级carrier contract version(5.11)。

### 7.6 pool 参数(上游冻结,Object Pooling)

| pool_key | capacity | spawn-before-release | criticality |
|---|---|---|---|
| enemy_normal=1 | 320 | 12 | GAMEPLAY |
| enemy_elite=2 | 6 | 1 | GAMEPLAY |
| enemy_boss=3 | 1 | 0 | GAMEPLAY |

不可调(上游冻结);变更须修订 Object Pooling + Config。

## 8. Acceptance Criteria

> lean 模式 H 节:qa-lead 派生审已在 design-review 阶段完成(2026-08-25,
> 见 review-log)。AC 编号 `AC-E#`(Enemy)。
>
> **验收设计 vs 已执行证据**:本节为设计契约(待实现验证),非已通过证据。
> 每条 AC 标注 story type 与 gate 级别(coding-standards 测试证据表):
> `[L]`=Logic(BLOCKING 自动单元测试)/`[I]`=Integration(BLOCKING)/
> `[V]`=Visual-feel(ADVISORY 截图+sign-off)/`[U]`=UI(ADVISORY)/
> `[C]`=Config-data(ADVISORY smoke)。性能 AC 无 min-spec 真机前为
> ADVISORY(deferred evidence);真机 `benchmark_ready` manifest 就绪后升级为
> BLOCKING release-gate(非 sprint gate,不阻塞设计冻结)。
> (F0 fix:coding-standards 表仅 BLOCKING/ADVISORY 两档,原自造"OPEN-gate"/
> "conditional"非标准,已统一改为 ADVISORY + release-gate 升级路径。)
>
> AC 须可独立测试:禁止"feels balanced / works correctly / performs well";
> 代码审计类 AC 须给出**字面 `rg` 正则集(正向+负向)+ 命中数断言**(F2 fix:
> 原散文 grep 示例不可重复审计)。编号 E3/E15/E16/E17/E24 已废弃,见 review-log,
> 不复用(编号缺口维持,不重排以免破坏跨文档引用)。

### 8.1 性能(source §15.4 + technical-preferences)

- **AC-E1**`[C,ADVISORY→release-gate,SPIKE-GATED 未冻结]`:303实体同屏（298普通+4 Elite+1 Boss）
  目标 50 FPS+(帧预算 16.6ms)。无 min-spec Android 真机前为 ADVISORY(deferred);
  真机就绪后以 `benchmark_ready` manifest 采样(中端设备 5 分钟战斗 session +
  **stress-window 采样**:含 12:00 Boss 出场 + 满屏怪潮 + 多技能同放的最坏 1 分钟;
  **第二轮复审补 max-clustering 子窗口**:300 敌人 sep_radius 内全聚玩家点 + 玩家释放 AoE
  同 tick——此为 QUERY_CONSUME pair-ops 峰值工况,非"满屏怪潮"铺开负载,两者量级不同,
  割草稳态=全聚集)。profiler 取帧时间 P50/P95/P99,P50 ≤ 16.6ms,**P95 ≤ 33ms**(2 帧,
  R-PA 补)+ **P99 ≤ 50ms** 防长尾(第二轮复审补)。**spike-gated**:性能 AC 在 J2 budget
  ADR + OQ9 GDScript 可行性 spike 证明全聚集 ≤ 子预算前不升级 BLOCKING(见 §10 OQ9)。升级
  为 BLOCKING release-gate 后阻塞 vertical-slice release,非 sprint gate;**拆分冻结**:行为
  契约冻结不阻塞,性能 AC 未冻结。
- **AC-E2**`[L]`+[C,ADVISORY→release-gate]`(R7/R10 fix 拆分):原单一 `[L]` 混合
  逻辑可测与性能时序,**拆为两条**:
  - **AC-E2a**`[L]`(第二轮复审重写,去时序回归+拆 avg/max):原"复杂度不退化为 O(N²)"+"
    耗时回归拟合近 O(N)"与 §4.2 pair-ops 上界 N(N-1)/2=O(N²) 直接矛盾(全聚集=割草稳态非
    edge case),且"耗时"违 coding-standards"no time-dependent assertions"。改为**确定性
    操作计数断言**(非耗时):**(a) avg-散布**:均匀铺开测试区域下 pair-ops ~O(N×avg_neighbors),
    N=10/100/30 三档 pair_ops 比率近 O(N)(容差 ±5%);**(b) max-全聚集**:全聚玩家点下
    pair_ops ≤ N(N-1)/2(N=303 时 ≤45,753,pair-once 去重后,见 §4.2),**不退化为 per-enemy
    各处理一次的 91,606**(Option B 去重上界)。AC-E2a 用"均匀散布"配置测复杂度趋势;AC-E10a
    用"全聚集"测最坏 pair-ops 上界,两者测量目标不同,**不可混用夹具**(R-QA/SD/perf 共识)。
    可单测(操作计数断言,非 wall-clock)。
  - **AC-E2b**`[C,ADVISORY→release-gate,SPIKE-GATED 未冻结]`:303 实体下每 phase 耗时 ≤ 子预算
    (spike 锚点,**待 J2 budget ADR + OQ9 GDScript 可行性 spike 实测重定值**)。
    **量级警告(第二轮复审修订)**:R-PA 指出原 spike(QUERY_CONSUME ≤0.3ms 容纳 45,753 pair
    ops ≈ 1.14M FLOPs ≈ 7.6ms native)量级错误;第二轮复审进一步核算为 **100–1000× 而非
    10–30×**——45,753 pair-ops × ~20-30 GDScript 指令 ≈ 1M+ 指令,GDScript 在中端 Android
    ~5-20M 指令/秒 → QUERY_CONSUME 单项 50-140ms(帧预算 3-8×);**全聚集=割草稳态非 edge
    case**(§2"被怪潮包围"是 normal case)。此量级估算未经真机/spike 验证,GDScript 纯解释
    执行 300 实体全 sim 极可能撑不住 60fps——**性能 AC 在 J2/OQ9 spike 证明全聚集
    QUERY_CONSUME ≤ 子预算前不冻结、不给 BLOCKING 数字**(spike-gated,拆分冻结)。MOVEMENT_COMMIT/
    GRID_SYNC/QUERY/QUERY_CONSUME/DEFERRED_REMOVAL 子预算占比声明,最终值归 J2 owner。**真机
    P95 超预算时触发 §5.12 perf-pressure 降级 escape valve**(best-effort 非保证兜底,可能最终 FAULT)。
- **AC-E3**`[REMOVED]`:sim LOD仍移除；Stage V2的屏内/屏外只影响表现与
  SpawnDirector生成/退役判定，所有active敌统一按AC-E1预算参与模拟。

### 8.2 池化与零分配(Object Pooling)

- **AC-E4**`[L]`:battle 期间(303 实体 + 高频 spawn/despawn)EnemySystem
  零 GC alloc per frame。**R9 fix(测量方法论;第三轮复审 B-6/QA-1 诚实化)**:Godot 4.7.1 无 per-frame
  heap-delta API(`Performance` monitor 仅累积 MEMORY_STATIC/DYNAMIC,引擎内部 churn >> 信号,不可信)。
  **四计数器语义明确**(Object Pooling F4):`borrow_allocation_events`/`release_allocation_events` 计
  pool 级借出/归还路径的 slot 容器分配事件;`runtime_slot_growth` 计 pool slot 数增长(超 capacity 扩容);
  `runtime_container_resize` 计 carrier 容器 realloc。**守卫范围声明**:四计数器只守 **pool 级零分配**
  (slot/container realloc);§3.4 禁令模式(emit_signal 带参装箱/call_deferred/create_tween/Dictionary
  构造等 13+ 项)的运行时检测——4.7.1 无运行时 API 可捕获这些装箱分配,改由 **AC-E4-code 静态守卫**
  (`tools/ci/static_guard_check.py` AST 脚本 + 辅助 rg 正则,R4 根因1:移除虚构 gdlint-AST 引用,
  见 AC-E4-code)守卫,AC-E4 运行时计数器不重复守卫这些模式。
  303 实体稳态 churn 下 `borrow_allocation_events == 0 ∧ release_allocation_events == 0 ∧
  runtime_slot_growth == 0 ∧ runtime_container_resize == 0`。
  **positive control(第三轮复审 B-6/QA-1 修订)**:原"注入 `Dictionary` 字面量构造"对照模式与 §3.4
  禁令模式(emit_signal 装箱等)**不匹配**——Dictionary 构造非禁令模式,positive control 通过只证明
  pool 级 instrumentation 可检测 Dictionary,不证明可检测 emit_signal 装箱(放行风险经由"窄对照通过")。
  修订:positive control 改为注入一路**匹配 pool 级守卫**的已知分配源(如 borrow 路径临时 `Array.append()`
  触发 `runtime_container_resize > 0`),断言对照路径计数器 > 0 证明 pool 级 instrumentation 可检测,
  再撤除断言正式 run_phase 路径四计数器 == 0。§3.4 禁令模式的 positive control 不可行(无运行时 API),
  归 AC-E4-code 静态守卫。对照失败 → INCONCLUSIVE(修复 instrumentation,非放行)。
- **AC-E5**`[L]`:borrow→reset_for_borrow→bind→unbind→release→reset_for_pool
  全链路无 slot 泄漏(归还后 `slot_state=AVAILABLE`,可再 borrow)。术语
  对齐 Object Pooling R3(`AVAILABLE` 非 `FREE`)。
- **AC-E6**`[L]`:teardown 后所有借出 enemy 归还 + pool slot 全 `AVAILABLE`
  (SpatialGrid invalidated 后 release)。

### 8.3 SpatialGrid 契约

- **AC-E7**`[I]`:EnemySystem 每 phase 调 SpatialGrid API 顺序正确
  (SPAWN_INTENT insert / MOVEMENT_COMMIT stage / DEFERRED_REMOVAL remove),
  无跨 phase 调用(phase 记录 oracle 断言)。
- **AC-E8**`[L]`:分离查询走 `query_circle_into`(**query_radius = sep_radius +
  max_separation_radius**,R3 fix:与 §3.8/§4.2 统一;原 AC 写 `max_enemy_bound` 为
  四方矛盾之一;**上游 SpatialGrid L133/L159/L474 已同步 B-1-R(R4 根因3 闭合)**;
  G3/registry separation 项 `checked_add(separation_radius,separation_radius)` 经核实为
  正确全局上界(2×max_sep,非误用 max_enemy_bound),保持不变),
  排除 self,**不遍历全场 active**。代码审计(字面 `rg` 正则集 + 命中数断言,F2 fix):
  负向命中须 == 0:`rg --glob '*.gd' 'for\s+\w+\s+in\s+(all_enemies|active_list|enemies)\b' src/enemy/`;
  正向命中须 ≥ 1:`rg --glob '*.gd' 'query_circle_into' src/enemy/`。
- **AC-E9**`[I]`:CAPACITY_EXCEEDED 时被抑制 spawn 请求不产生幽灵实体(无
  Node/pool slot/grid entry 创建)。与 spatial-grid AC-E11(spatial-grid 域)
  分离编号,本条为 enemy 域幽灵守卫。

### 8.4 分离行为

- **AC-E10a**`[L]`(第二轮复审重写,分段契约+clamp 例外+帧数上界):原"严格单调递减"
  在 clamp_magnitude 截断路径(§4.2 B3,k=303 全聚集必触发 clamp)+ BLINK 落点帧(§3.6.2
  引入新 overlap)+ §5.12 降级档跳过 pair 下**未证明且不成立**(SD/qa/gd/perf 四 specialist
  共识)。改为**作用域明确的分段契约**:
  **(a) 基线(非降级、非 BLINK tick、未触发 clamp 的 pair)**:两两 overlap 之和单调非增
  (允许持平;严格递减仅在无 clamp 单 pair 场景保证,见 §4.2 SD1 clamp 不变量例外);
  **(b) clamp 场景**:被 clamp 敌参与的 pair 局部 overlap 可能不递减(§4.2 已声明软约束),
  AC 改断言**全局 overlap 之和有界非增**(clamp 不致系统性发散);
  **(c) BLINK 帧**:允许瞬时增加(落点新 overlap),但后续 ≤ `frames_to_epsilon` 帧内收敛
  至 ≤ ε(ε = sep_radius × 0.1);**frames_to_epsilon 上界 = advisory spike ~68 帧**(基于
  §4.2 簇直径 ~17 估算;第三轮复审 B-7:原 `4 × ceil(max_cluster_diameter / min_push_hop)` 三变量
  max_cluster_diameter/min_push_hop/因子4 全未定义,上界不可算,降为 advisory spike;精确上界
  defer OQ9 GDScript 可行性 spike 实测,归 release-gate);测试超 spike 上界 FAIL(防无限跑);
  **(d) §5.12 降级档1-3 激活时**:本 AC 降级为"有界残留 overlap"(见 §5.12 残留上限守卫),
  不要求严格收敛。
  测试:**k∈{2, 303}** 两档(k=2 初始 distance=0→overlap=2×sep_radius 完全重合;k=303
  全聚一点;R-QA 修正初始 overlap 描述:完全重合 overlap=2×sep_radius 非 sep_radius),
  sep_radius 用 fixture 常量覆盖；所有overlap变化oracle按“tick T phase 5冻结next槽，tick T+1 phase 2消费并在phase 3发布后再测量”取样，禁止在T phase 5后假定位置已变化。逐帧断言(a)(b)(c)+帧数≤上界。
- **AC-E10b**`[L]`(第二轮复审拆断言时序+参数序):零距离重合退化(distance=0)用确定性
  单位向量(§4.2 B1 fix + deterministic_axis 公式)分离,不产生 NaN/永久重合。
  **断言拆分(R-QA/SD)**:tick T phase 5(distance=0)断言`correction_dir==deterministic_axis(h_a,h_b)`且位置未变、next槽非零；tick T+1 MOVEMENT_COMMIT消费后、GRID_SYNC发布时断言distance>0且next槽已先清零（随后T+1 phase 5可写下一值）；第3个发布位置快照再断言持续分离。参数序约定`h_a<h_b`，见§4.2 F-2 fix。此后
  correction_dir 已切换为 `Normalize(self.pos - b.pos)`,**不再等于** deterministic_axis——
  原AC第3帧断言两者相等会失败。测试：两敌人`spawn_position`完全相同、固定handle对，断言T计算/T+1消费边界与第3个发布快照分离。
- **AC-E11a**`[L]`:等质量对(两普通 / 两精英同级)修正对称(各推 overlap/2)。
- **AC-E11b**`[L]`:异质量对(精英 vs 普通 / Boss vs 普通)按质量比分配(重者
  位移少)。质量比具体数值 defer ADR;AC 用"重者位移 ≤ 轻者位移"行为断言
  (可测不等式,不依赖具体比值)。**R-QA 补(不变量,无需质量值)**:未 clamp 场景
  断言 `|correction_self| + |correction_neighbor| == overlap`(容差 1e-6,
  §4.2 不变量);clamp 场景仅断言方向不等式(§4.2 clamp 例外声明)。
- **AC-E11c**`[L]`(F-9 fix:pair-once 去重守卫):QUERY_CONSUME 每无序对 (a,b)
  全局**仅处理一次**(仅 `neighbor.handle > self.handle` 分支,§3.8/§4.2),
  双方各写一侧修正。测试:构造 N=10 敌人全互相 overlap → 计入 `pair_ops` 计数器,
  断言 == `N(N-1)/2 = 45`(非 `N(N-1)=90`);并断言每对 (a,b) 恰有一方 `next_separation_correction`
  含该对 push(无重复累加)。代码审计:`rg --glob '*.gd' 'handle\s*[<>]=?\s*\w+\.handle' src/enemy/`
  命中去重守卫须存在(非每邻居无条件处理)。

### 8.5 phase 契约(GameRoot)

- **AC-E12**`[L]`:`run_phase` 对未 allowed phase 返回 status 不执行;零分配
  (positive control 同 AC-E4 模式)。
- **AC-E13**`[L]`:敌人 `_physics_process` 默认关闭 + `_process`/`set_process`
  不启用(R-GS:原仅查 `_physics_process` 漏 `_process`/`set_process`/AnimationPlayer
  callback_mode_process)。代码审计(字面 `rg` + lint):负向命中须 == 0:
  `rg --glob '*.gd' 'set_physics_process\(true\)|set_process\(true\)' src/enemy/`;
  **func 定义审计**:`func _physics_process` / `func _process` 负向命中须 == 0
  (禁止定义这些虚函数——原"空体或 pass/return 可接受"判定 grep 不可靠且违 run_phase
  集中驱动契约,**删空体漏洞依赖**,改禁止定义);AnimationPlayer 的
  `callback_mode_process`(4.7:非旧 `process_callback`,后者 4.3 起弃用)须设为非
  每帧自动模式或统一由 run_phase 驱动(场景/资源审计:`callback_mode_process` 是 AnimationPlayer
  属性非 .gd 源码,归场景审计(非 `tools/ci/static_guard_check.py` AST 脚本域);`func _physics_process`/`func _process`
  定义禁令归 rg 正则 L1064;R4 根因1:移除原虚构"gdlint 规则"引用)。
- **AC-E14a**`[I]`:POOL_EXHAUSTED → GameRoot ControlledGameplayFault(R9),
  不 crash。
- **AC-E14b**`[I]`:OBJECT_INVALID → ControlledGameplayFault,不 crash。
- **AC-E14c**`[I]`:phase failure → ControlledGameplayFault;玩家见安全停止
  UI(GameRoot 域)。
- **AC-E14d**`[I]`:Config逐行读回本节6条贡献；303/303/303/0与9/9任一缺失、重复、负数或改变即`battle_ready=false`。phase6 ordinary arm在visible rows=0/1/303各执行全量authority copy恰1，publish分别为0/1/1；不得用整run`<=1`替代逐arm oracle。

### 8.6 LOD 行为

> 整节移除(BL9,LOD reduced 删除)。原 AC-E15/E16/E17 废弃。性能由 §8.1
> 统一预算约束。动画统一帧率见 §9.1。

### 8.7 spawn_context 与 behavior

- **AC-E18**`[L]`:6 种普通敌人共享 `EnemyNormalPoolable/v1`,以 behavior_id
  (0-5)区分(Config R4);无 6 个独立 PackedScene/script contract。代码审计
  (F2 字面 regex):负向命中须 == 0:
  `rg --glob '*.gd' 'class_name\s+Enemy(Wolf|Bug|Vine|Beetle|CharMarionette|Worm)\b' src/enemy/`
  (按 behavior 名列具体 per-behavior 类名,避免泛 `Enemy[A-Z]\w+` 误中基类族);
  文件级断言 `ls src/enemy/enemy_*.gd` 命中数 ≤ 3(允许 poolable 基类族
  `EnemyPoolable`/`EnemyNormalPoolable`/`EnemyElitePoolable`,禁止 6 行为各自独立
  脚本;R-QA:原 ≤1 过严,基类族必然 >1)。
- **AC-E19**`[L]`:`SpawnContextCarrierV2` 10字段全 primitive,无 Dictionary/Array 运行时
  构造(零分配验证 + 代码审计)。**第三轮复审 B-8 守卫方式修订**:原裸 rg regex
  `\{[^}]*behavior_id` 误中 `#` 注释行(schema 记号)与 AC-E30a FSM 数据表
  `{trigger, action, next}` 字面量,需人工核放行——非确定性 CI gate(coding-standards
  要求 Logic AC 自动单测 BLOCKING;qa-lead QA-4 核实)。**canonical 改为 typed carrier
  静态断言 + `tools/ci/static_guard_check.py` AST 守卫**(R4 根因1:原"gdlint AST 规则"虚构——gdlint
  无自定义规则/插件 API,改由 gdtoolkit.parser AST 脚本守卫):spawn_context 载体声明为 BATTLE_LOADING 预分配 typed carrier
  (`class_name SpawnContextCarrier`,per-field typed accessor 非 Dictionary),AC 断言:
  (1) 载体类型为 `SpawnContextCarrierV2`(非 Dictionary);(2) 10字段为typed primitive
  (int/Vector2/float,非 Variant);(3) `tools/ci/static_guard_check.py` AST 守卫(与 AC-E37/E4-code
  同脚本;R4 根因1:用 gdtoolkit.parser 库,非 gdlint 插件 API——后者经 qa-lead 实测确认不存在)
  守卫 src/enemy/ 无 `Dictionary(` 运行时构造 + 无 `{[^}]*behavior_id` 字面量赋值(AST
  可区分注释/schema 记号/FSM 数据表赋值 vs 运行时构造,rg 不能)。裸 rg
  `\{[^}]*behavior_id` 仅作候选定位(非确定性 gate;R4 移除"人工核",AST 脚本为权威判定)。
  §3.3 schema 记号与 AC-E30a 数据表不计负向(R-GS:载体为 BATTLE_LOADING 预分配 typed carrier)。
- **AC-E20**`[L]`:behavior_id 索引 Config behavior 表设属性/动画;EnemySystem
  无硬编码敌人类型。代码审计(字面 regex,F2 fix):负向命中须 == 0:
  `rg --glob '*.gd' 'if\s+behavior_id\s*==|elif\s+behavior_id\s*==|match\s+behavior_id' src/enemy/`
  (R-QA:补 `elif`,字典分发 `dispatch[behavior_id]` 允许);正向命中须 ≥ 1:
  `rg --glob '*.gd' 'behavior_table\[behavior_id\]|config\.behavior_table' src/enemy/`。

### 8.8 死亡与回收

- **AC-E21**`[L]`:health ≤ 0 → DEFERRED_REMOVAL 严格执行
  先提交一条`DEATH` gameplay fact，再使同一lifecycle row按`RESERVED→GRID_REMOVED→POOL_UNBOUND→POOL_RELEASED|POOL_RETIRED`推进；remove-before-release，Pool私有release FSM保证reset/free-stack exact-once，journal不得按side effect新增多row。
- **AC-E21b**`[I]`:构造同tick多敌死亡，在第N个intent的fact commit/remove/unbind/reset后分别注入failure；断言已COMMITTED的DEATH fact恰一次、每intent journal始终一row且state不回退、旧handle/borrow永久stale、之后intent未执行，cleanup重放不重复死亡payload、drop staging、reset或free-stack push。独立运行四类传播fixture：仅COMMITTED fact、仅进入`GRID_REMOVED/POOL_UNBOUND/POOL_RELEASED/POOL_RETIRED`的lifecycle row、两者同时存在、两者均不存在；再分别覆盖visible row总数1/N/capacity与matching success/fault convergence。GameRoot每tickphase-begin full authority copy恰1次；`committed_authority_visible_rows==0`时batch publish=0且revision delta=0，`>0`时matching end或fault convergence batch publish恰1且revision delta=1，next authority逐字段精确反映全部committed facts/rows，随后按seal边界进入ControlledGameplayFault或保留normal outcome。不得以整run copy/publish `<=1` 作为PASS。
- **AC-E22a**`[L]`:死亡事件payload逐字段等于`{death_fact_sequence,enemy_id,borrow_id,behavior_id,death_position,spawn_seed,spawn_provenance,source_choice_id}`（8字段，经GameRoot SoA staging bank，8条并行PackedArray，Vector2入`PackedVector2Array death_positions`，write-index索引写非`append()`）。断言303 required−1/required/+1、存储布局、DEATH fact sequence与Risk choice identity一致及零分配写入路径，非仅“含8字段”。
- **AC-E22b**`[I]`:DropSystem在同帧消费staging完成掉落判定；完整matching行恰消费一次，duplicate matching为OK_NOOP，逐字段缺失/stale borrow/duplicate conflict在额外DROP RNG或plan mutation前fault。

### 8.9 registry 回填

- **AC-E23a**`[C]`:回填`max_enemy_bound`/`enemy_step_bound`/
  `separation_radius`到registry，分别供`max_query_radius`与
  `world_reachability_budget`消费。
- **AC-E23b**`[C]`:以最大速度/冲刺/击退/shape bound重跑Stage V2
  1800秒reachability proof和SpatialGrid F3 sweep；不得创建旧margin或clamp参数。
- **AC-E23c**`[C]`:`knockback_max` 归属声明 Combat/DamageSystem(OQ2);
  本 GDD 不回填,待 DamageSystem GDD 确认 owner。

### 8.10 边界

- **AC-E25**`[L]`:EnemySystem 不计算伤害(无 damage formula;`take_damage` 只
  扣血 + 直接方法调用通知;damage 公式在 Combat)。代码审计(F2 字面 regex):
  负向命中须 == 0:`rg --glob '*.gd' '\*=\s*stage_damage_multiplier|health\s*\*=\s*dmg|apply_multiplier' src/enemy/`
  (R-QA:原 `*= stage_damage_multiplier` 过窄)。
- **AC-E26**`[L]`:不决定 spawn 时机/位置(SpawnDirector 边界);只消费
  spawn_context。代码审计(F2 字面 regex):正向命中须 ≥ 1
  `rg --glob '*.gd' 'SpawnDirector|spawn_director' src/enemy/`(spawn 触发经
  SpawnDirector 接口);负向命中须 == 0
  `rg --glob '*.gd' 'if\s+.*should_spawn|is_spawn_time' src/enemy/`(R-QA:原"无
  spawn 时机判断"散文不可 grep,改为正向接口 + 负向时机判断 regex)。
- **AC-E27**`[L]`:Boss阶段FSM内容不在本GDD重复实现；Enemy只调用BossStateMachine typed capability并拥有载体/HP/lifecycle。没有Boss content row或capability时battle load失败，不以“只跑基础追踪”进入production。

### 8.11 新增 AC(BL4 补齐)

- **AC-E28**`[I]`:paused resume 后 enemy 状态可恢复(quarantine snapshot +
  FIFO mutation queue,经 GameRoot phase 停;resume 不丢 enemy 位置/血量 +
  **FSM 计时器快照**,R-AI N4 补)。测试:pause 中产生 N 个 spawn 请求 →
  resume → 请求按 FIFO 执行 M=N(量化"无丢失",R-QA 补)。
- **AC-E29**`[I]`:精英召唤cluster遇Normal class不足3槽时不重试本周期 + 逸散 VFX
  (F3 fix:行为定义在 **§3.6.2 cap-full 行为 + §3.11 逸散 VFX intent**,非原
  误引"§5.7"——§5.7 是已移除的 LOD 节);不阻塞 GameRoot。测试:构造
  **Normal active+pending 为295/296/297/298**(非"耗尽 normal pool 320"——pool 未必耗尽,
  admission 抑制)→ 鬼雾修士3-child cluster → 断言结果只能3/0/0/0 +
  失败时聚合VFX恰一次 + 下一周期才重试；每child仍消费24 words。
- **AC-E30a**`[L]`:Elite GDD权威FSM表每条边含 `{trigger, action, next}`,
  **trigger 须可判**(整数tick/距离/已latch token,非"动画/释放完成"散文；鬼雾修士
  必须先满足30t TELEGRAPH_NEEDLE再latch三针)。代码审计(F2):负向命中须 == 0
  `rg --glob '*.gd' 'if\s+state\s*==|match\s+state\b' src/enemy/`(FSM 数据表化)。
- **AC-E30b**`[L]`:巨甲蜈蚣三段CHARGE+LINK→WEAKENED→TRACK循环可驱动(单元测试:
  注入触发条件 → 断言状态迁移符合表；无墙/边界分支，仅投影达到
  每段authored progress达到`charge_distance`时segment index递增，段间6t且不重瞄；**含敌群分离
  反推场景 B1 fix**:CHARGE 中在冲刺轴前方注入密集敌群分离反推 → 断言
  charge_progress(沿锁定轴投影)单调不减 + 仍能达 charge_distance=6.0 进
  WEAKENED,验证分离修正仅作用垂直分量未致投影不增死锁)。
- **AC-E30c**`[L]`:鬼雾修士BLINK落点=`player_position + UnitVector(hash(seed,cycle))
  × lerp(1.5,2.5,hash(seed,cycle))`并做real_t32 readback。固定seed/cycle断言落点确定；合法值
  原样发布，越world domain则不发布并fault，断言不存在clamp/wrap。
- **AC-E30d**`[L]`(B3 fix):甲壳妖虫(behavior_id=3,normal 桶)数据驱动
  mini-FSM CHASING/ATTACKING 可判。测试:玩家接近至 `distance ≤ stop_distance`
  → 断言进入 ATTACKING(停身,move 位移为 0);玩家退至 `distance >
  resume_distance` → 断言回 CHASING(恢复追击);玩家在 `stop_distance <
  distance ≤ resume_distance` 滞回带内 → 断言状态不变(防抖动);负向命中
  正向命中须 ≥ 1 `rg --glob '*.gd' 'stop_distance|resume_distance' src/enemy/`
  (两参存在且被判定;第三轮复审 AI-7/QA-17:原标"负向==0"与"两参存在"自相矛盾,此 regex 实为正向存在断言,修正方向)。
- **AC-E30e**`[L]`(第三轮复审 B-4,铁背妖狼 mini-FSM):behavior_id=1 数据驱动 mini-FSM
  CHASING/TELEGRAPH_CHARGE/CHARGE/RECOVER 可判。测试:注入触发条件(distance ≤ charge_trigger_range
  且 cooldown 计满)→ 断言状态迁移符合 §7.4 状态表;冲刺中方向锁定不重瞄准;单次冲刺完成直接进 RECOVER
  (无 `charge_count`,R4 根因4:狼单冲锋非蜈蚣三连击,原 AC "charge_count 累加"为模板残留已删);
  RECOVER 后回 CHASING。
- **AC-E30f**`[L]`(第三轮复审 B-4,腐毒妖藤 mini-FSM):behavior_id=2 数据驱动 mini-FSM
  IDLE/TELEGRAPH_POISON/POISON 可判。测试:poison 周期计满 → TELEGRAPH_POISON → POISON → IDLE
  循环;静态不移动(AC-E35 联动);poison_duration 后回 IDLE。
- **AC-E30g**`[L]`(第三轮复审 B-4,魔道符修 mini-FSM 滞回带):behavior_id=4 数据驱动
  mini-FSM CHASING/REPOSITIONING/SHOOTING 可判。测试:distance>approach(6.0)→ CHASING 接近;
  distance<retreat(5.0)→ REPOSITIONING 后退;滞回带内(5.<distance≤6.0)且 cooldown 计满 → SHOOTING;
  SHOOTING 时 move 位移为 0(射击停移);滞回带内状态不变(防抖动)。
- **AC-E30h**`[L]`(第三轮复审 B-4/B-5,血傀儡 mini-FSM + 自爆归属):behavior_id=5 数据驱动
  mini-FSM CHASING/TELEGRAPH_SELF_DESTRUCT/SELF_DESTRUCT 可判。测试:health 跨越 30% 阈值
  (从 >30% 到 ≤30%)→ 断言进 TELEGRAPH_SELF_DESTRUCT(跨阈值即触发,非停留);telegraph 计满 →
  SELF_DESTRUCT;**自爆伤害归属(§3.12 B-5)**:断言 EnemySystem 只 latch self-destruct intent
  (写 GameRoot staging slot),不直接施加伤害——伤害由 Combat pull 后施加(验证 carrier 无 damage
  formula 调用,归 AC-E25);**死亡-during-预警 edge**:预警期间 health 被打到 ≤0 → 断言仍触发
  自爆 intent latch(预警 latch 优先于死亡流程,§3.12 B4 fix)。
- **AC-E30i**`[U][I]`(Player复活边界):以303行snapshot、duplicate enemy_id/different完整tuple及多种物理排列验证A/B header、九parallel arrays、current/swept bounds与完整identity；Player选中clear行仅含圆形玩法足迹真实重叠/相切NORMAL且按四字段tuple总序，非圆NORMAL、swept<current或behavior swept上界缺失均在load失败。分别注入terminal preview=VICTORY、stale handle/borrow、正净空NORMAL、ELITE/BOSS、全量journal reserve第N行失败、DAMAGE fact commit前失败及commit后第N条lifecycle失败：preview胜利/点前Enemy side effect=0；点后只推进已预留row并exact-once收敛，无DEATH/kill/XP/drop/reward/record。自爆fixture另断言Grid query mask仅为`ENEMY`，玩家窄相只读matching motion carrier，仓库中无`PLAYER` Grid type或组合mask。
- **AC-E31**`[L]`(第二轮复审改 BLINK 帧语义):BLINK 落点不校验敌人重叠(靠分离 §3.8
  消化);落点处即使有重叠,**满足 AC-E10a(c) BLINK 帧分段契约**——允许 BLINK 帧瞬时
  overlap 增加,后续 ≤ frames_to_epsilon 帧内收敛至 ε(原"满足 AC-E10a 单调递减"对 BLINK
  帧不成立,见 §4.2/AC-E10a 分段契约)。
- **AC-E32**`[L]`:spawn_context contract version 不匹配时拒绝 borrow +
  ControlledGameplayFault(§5.11 版本不匹配)。测试:传入 `version=99` →
  断言 borrow 被拒 + fault 触发。
- **AC-E33**`[L]`(R-QA 拆分,原仅测 health cap 一维 → 拆 a/b/c/d):阶段倍率
  触发 cap 时,该维度不再增长,其余维度继续涨(§7.2 core 承诺)。测试注入
  `stage=20`(cap 后):**(a)** `health_multiplier == 3.0`(恒定,20→25 不变);
  **(b)** `damage_multiplier ≤ 2.5`;**(c)** `move_multiplier ≤ 1.35`;
  **(d)** 交互断言(F-3 fix:明指封顶点):`stage=12` 时 `health_multiplier == 3.0`
  恰封顶(`1+0.18×12=3.16→cap`,§7.2)而 `damage_multiplier == 1+0.12×12=2.44 < 2.5`
  未封顶(`stage=13` 才 `2.56→cap 2.5`)→ stage 12→13 增长**只**涨 damage 不动 health
  (验证 cap 独立、各自阶段生效)。
- **AC-E34**`[L]`:enemy移动后完整足迹须位于`world_safe_aabb`。合法位置逐bit
  不改写；越域返回`POSITION_OUT_OF_RANGE`、旧snapshot保持且进入fault，
  断言无clamp/wrap/suspend。
- **AC-E35**`[I,ADVISORY]`:腐毒妖藤(behavior_id=2)静态不移动(OQ7
  待 performance 核验;若改为缓慢漂移则本 AC 作废,改测漂移速度)。F0 fix:
  原"conditional"非标准 gate,改 ADVISORY;OQ7 解后转 BLOCKING 或作废(非
  自造 conditional 状态)。
- **AC-E36**`[I]`:Boss 阶段切换(`on_phase_transition`,#18 DEFERRED_REMOVAL
  调用)时分离延续——Boss 不因阶段切换瞬移重叠普通敌人;阶段切换后第一帧
  AC-E10a/b 仍成立。
- **AC-E37**`[L]`(GH-115763 守卫):EnemySystem 中所有覆盖带类型返回的父类
  方法须显式 `return <value>`(Godot 4.7:覆盖带 typed-return 父类方法不显式
  return 会 crash,GH-115763)。代码审计:负向命中候选定位:
  `rg --glob '*.gd' 'func\s+\w+\(.*\)\s*->\s*\w+.*:' src/enemy/` 命中的方法体
  须含显式 `return`(`tools/ci/static_guard_check.py` AST 守卫——用 gdtoolkit.parser
  遍历 method body 断言含 `return` 节点;grep 仅定位候选,空体判定不可靠;R4 根因1:原
  "gdlint/AST"引用虚构 gdlint 插件 API,改底层 parser 脚本)。
- **AC-E4-code**`[L]`(静态守卫:AC-E4 运行时计数器之外的源码模式守卫;第四轮复审 R4 根因1 重写——移除虚构 gdlint-AST 引用 + 人工 carve-out,改确定性 AST 门控):
  src/enemy/ 稳态借出/归还/run_phase 路径禁 §3.4 全部禁令模式。**主门控 = `tools/ci/static_guard_check.py`**——自定义 CI AST 脚本,用 `gdtoolkit.parser` 库(`from gdtoolkit.parser import parser`;`parser.parse(src)` 返回 Lark `Tree`,遍历 `standalone_call` 节点判定禁用调用)。**qa-lead 2026-08-25 实测 gdtoolkit 4.5. 确认:gdlint 本身无自定义规则/插件 API(`never-returning-function` 规则在 DEFAULT_CONFIG 为注释行未实现),故原"归 gdlint AST 规则"门控为虚构——改用底层 parser 库自建脚本(已验证可导入、可解析、AST 可遍历区分注释/字符串/调用)。** AST 脚本确定性区分注释/字符串常量/FSM 数据表赋值 vs 运行时禁用调用(rg 不能),**无须人工 carve-out**(消除第三轮"命中须人工核"非确定性 CI gate,违 coding-standards Logic AC 须自动 BLOCKING)。脚本须含 **positive control**(≥1 已知违例样本断言被检出,防坏脚本空匹配静默通过 `==0`)。工具本体在实现期建(CI 运行 `python tools/ci/static_guard_check.py src/enemy/`),设计阶段仅定门控契约。
  AST 脚本禁用模式集(§3.4 全覆盖,含 R4 补齐的 regex 缺漏项):`emit_signal(`(带参)、`set_deferred(`、`call_deferred(`、`create_tween(`、`.call(`、`.emit(`(4.x signal.emit 惯用法,绕 emit_signal)、`get_children()`、`get_parent()`、`get_node(`、`.connect(`、`.disconnect(`、`Dictionary(`、`var_to_str(`、`Callable(`、`.bind(`、`.set(`、`.get(`、`instantiate(`、`duplicate(`、`Array(`、`append(`、`str_to_var(`、`String(`、`await`、`for ... in range(`。(R4 补:原 regex 缺 `.emit(`/`Callable(`/`.bind(`/`.set(`/`.get(`/`instantiate(`/`duplicate(`/`Array(`/`append(`/`str_to_var(`/`String(`;`var_to_str\(` 已显式覆盖无拼写问题。)
  辅助 `rg` 正则(快速预筛,非确定性 gate,AST 为权威):`rg --glob '*.gd' 'emit_signal\(|set_deferred\(|call_deferred\(|create_tween\(|\.call\(|\.emit\(|get_children\(\)|get_parent\(\)|get_node\(|\.connect\(|\.disconnect\(|Dictionary\(|var_to_str\(|\bstr\(|await\s+|for\s+\w+\s+in\s+range\(' src/enemy/`。
  稳态路径命中禁用调用 = 违 AC-E4;BATTLE_LOADING warmup 期/非稳态路径例外须在 AST 脚本配置中显式标注路径(annotation-based allowlist,非人工核)。

## 9. Visual & Audio (optional)

EnemySystem 视觉/音频契约(节点细节 defer 节点架构 ADR):

### 9.1 动画状态

- 每敌人动画状态:idle/move/attack(技能)/hit/death。
- 动画资源由 Config behavior 表索引(`behavior_id` → AnimationLibrary)。
- 动画状态机由 FSM 驱动(普通敌人简单 idle/move/hit/death;精英 FSM
  状态对应动画)。
- 动画统一60fps simulation cadence；视口外可停止提交draw，但不得改变
  gameplay FSM、碰撞、threat或lifecycle cadence。
- 动画切换零分配(`StringName` warmup 缓存 `&"..."`,§3.4;R-GS:play() 内部
  emit `animation_started/finished` warmup 不消除,载体 AnimationPlayer 内置
  信号 warmup 期断开,gameplay 动画事件改由 FSM 计时器轮询驱动,非 play() emit)。

### 9.2 受击反馈

- 受击视觉:闪白(材质 shader param)/击退位移(Combat 传 vector)。
- 受击音效：由Damage committed receipt提供唯一命中语义，Audio Feedback调度播放（EnemySystem **写
  staging latch**(零分配,§3.4;禁 `emit_signal` 带参,违 AC-E4),不直接播音频)。
- 死亡视觉:death 动画 + 粒子由**独立 VFX 池节点**播放(非 enemy 载体);
  health ≤ 0 触发 DEFERRED_REMOVAL,enemy 载体立即回池(§3.11,F3 fix:原引
  "§5.6" 为 Boss 阶段切换,非 repool),死亡特效在独立 VFX 池上继续播放至结束。
  载体回池不截断死亡动画表现(BL6 闭合)。
  VFX 池细节归 VFX System GDD。

### 9.3 视口剔除与降级

- **无 sim-LOD**:LOD reduced 移除(BL9,见 §4.4 / §1 注;F3 fix:原"§3.9
  删除"不存在),所有敌人(屏内/屏外)统一参与模拟(分离/受击/死亡),无隔 tick
  降级。**perf-pressure 降级见 §5.12**(非恢复 sim-LOD,而是分离质量降级)。
- **draw-cull**:Godot内置视口cull处理镜头外敌人（渲染层，不影响模拟）。
  是否增加手动presentation cull defer节点架构ADR；任何cull不得成为spawn、
  damage、threat或distance-retire的authority来源。

### 9.4 音频

- 敌人音频中，攻击/精英技能由matching action generation、死亡由committed DEATH提供语义，再由Audio Feedback调度（EnemySystem **写 staging
  latch**(零分配,§3.4;禁 `emit_signal` 带参,违 AC-E4))。
- 303实体压力下的event rows/maxima由Enemy与各content owner签发，voice/合并策略归Audio Feedback；当前H_enemy仍BLOCKED，不能用303直接当voice数。

## 10. Open Questions

1. **节点架构 ADR**(High-Risk,systems-index 标注):轻量 Node2D + 手动
   更新 vs CharacterBody2D + `move_and_slide` 物理驱动 vs 混合。source
   §15.4 倾向轻量,但具体节点/碰撞/动画节点须 `/architecture-decision`
   定。本 GDD 行为契约已冻结,不阻塞 ADR。**子问题**:303 个 Node2D 同屏
   的 SceneTree 开销(节点遍历/通知/transform 传播)是否在 16.6ms 预算内,
   须 ADR 含真机或 spike 数据支撑。**第二轮复审补(perf F3.1)**:303 个
   Node2D 每 tick `position =` 写触发的 CanvasItem transform dirty →
   RenderingServer transform commit 成本(303 次/帧)由 ADR 评估,**计入
   AC-E1 P95 但不计入 AC-E2b 子预算**(子预算只覆盖 committed_pos 计算,
   不覆盖引擎侧 transform 传播)。若 ADR 选非 Node2D 拓扑(如 MultiMesh
   服务端渲染),§3.4 的 `@onready` 子节点引用 / `node_ref` carrier 字段
   需 re-validate。**性能 AC 升 BLOCKING 前须 ADR 冻结 + 真机基准就绪**。
2. **knockback_max 归属**:本 GDD 声明归 Combat/DamageSystem owner
   (4.5/4.6);待 DamageSystem GDD 确认。若 DamageSystem 声明归
   EnemySystem,本 GDD 须加 knockback 公式。
3. **max_enemy_bound per-type vs 上界**:本GDD选上界(4.6)；待Config调参、
   Stage V2 reachability proof与F3 sweep验证。任何失败须调整技术域/时限/速度
   或对象bound并提升revision，不得恢复clamp。
4. **分离修正时序** ✅ RESOLVED（2026-08-28第六轮纠错，替代2026-08-25同tick裁定）：tick T QUERY_CONSUME计算并冻结`next_separation_correction`，tick T+1 MOVEMENT_COMMIT恰消费一次、清零并由GRID_SYNC发布；延迟完整一个physics tick。AC-E10a/b按发布后位置取样。详见§3.8/§4.1/§4.2。原“本帧MOVEMENT_COMMIT生效”在七phase顺序下不可实现，已废弃；“bounded收敛≤3帧”亦保持废弃。
5. **borrow→insert 时序**(部分解):方向已定——**禁止跨 phase 同步 borrow**;
   若 borrow 请求到达时不在 SPAWN_INTENT phase,经 GameRoot **intent latch**
   缓存,下一 tick SPAWN_INTENT 执行(§6.2)。仍未决:同 SPAWN_INTENT phase
   内的 borrow→insert 具体子顺序(reset_for_borrow→bind→grid insert 的原子性),
   随 SpawnDirector GDD(Not Started)协调。
6. **Boss carrier 与 #18 run_phase 边界** ✅ RESOLVED（2026-09-03）：BossStateMachine
   是Enemy `stable_order=4`内部typed capability，不新增participant；Enemy继续拥有pool_key3
   载体/HP/position/death/lifecycle，并在合法phase同步调用。BATTLE_RULES仍是独立未完成owner。
7. **腐毒妖藤静态处理**(待定):固定原地不移动,是否仍进 SpatialGrid 分离
   查询(ENEMY 类型一致)还是静态标记?本 GDD 当前假定进 grid 一致性(被查
   不查;静态敌人可作"只被查"优化)。performance-analyst 建议静态优化提升为
   MVP 必做(避免 300 实体全查分离的浪费),**待定**——需先有真机 separation
   phase 基准数据(AC-E2 子预算)才能裁定优化收益。AC-E35 标 conditional。
8. **精英 FSM 内容所有权** ✅ RESOLVED（2026-09-03）：behavior 6/7状态图、
   tick参数、攻击/召唤/表现唯一归`elite-enemies.md`；本GDD只拥有共享driver与载体。
   仍需clean-context review与playtest，不以authoring同步视为批准。
9. **GDScript 可行性 spike(性能 AC 前置门,第二轮复审新增)**:GDScript 纯解释
   执行 300 实体全 sim 在全聚集割草稳态下的可行性未经验证(AC-E2b 量级估算
   100-1000× 超预算)。须 spike 实测:全聚集 303 实体 QUERY_CONSUME 在中端
   Android 的实际帧耗时,作为 J2 budget ADR 与性能 AC(AC-E1/E2b)release-gate
   升级的前置门。spike 证明可行→性能 AC 升 BLOCKING;证明不可行→技术响应为
   热路径迁 GDExtension/C++ / 降实体数 / 改节点架构(OQ1),**不重做行为契约**
   (拆分冻结:行为契约已冻结)。此 OQ 与 OQ1 节点架构 ADR 强耦合,建议同期推进。
   (注:原 AC-E2b/§5.12 误将性能 spike 称"OQ7",OQ7 实为腐毒妖藤静态处理,已修正为 OQ9。)

10. **SUMMON 瞬时语义** ✅ RESOLVED（2026-09-03）：cluster latch当tick最多一条
   0-tick提交边，实际3-child borrow固定在下一Active tick SPAWN_INTENT；0或3原子结果、
   一次逸散与不重试本周期见Elite GDD §3.7。
11. **blink seed派生** ✅ RESOLVED（2026-09-03）：angle/radius按
   `{spawn_seed,blink_cycle_index,distinct salt}`纯hash派生，cycle入口冻结且不消费runtime RNG；
   公式与real_t32 guard见Elite GDD F3。
12. **精英技能跨phase顺序** ✅ RESOLVED（2026-09-03）：Enemy tick T只latch魂针/
   summon plan；Projectile/SpawnDirector均在T+1 SPAWN_INTENT消费，禁止同tick borrow。
   Damage只消费Projectile后续matching hit；具体global producer sum仍BLOCKED。
13. **Boss 阶段切换帧时机与节拍点语义** ✅ RESOLVED（2026-09-03）：matching
   phase5 resolution只排队；下一Active MOVEMENT_COMMIT切换。telegraph未release则取消，
   BITE只收敛当前18-tick segment，已release projectile继续而recovery取消；90-tick
   PHASE_SHIFT后P2/fog同revision生效，不重borrow、不瞬移，分离修正继续。
