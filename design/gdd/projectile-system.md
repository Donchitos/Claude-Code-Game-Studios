# ProjectileSystem

> **Status**: Designed / Full Review Pending
> **Author**: User + Codex
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 移动躲避 + 自动御剑 + 功法进化的战斗爽快度
> **Review Mode**: lean

## Overview

ProjectileSystem 是战斗中所有可复用攻击载体的唯一生命周期与运动 owner。它接收 Weapon、Enemy 与 Boss 发布的类型化生成计划，在固定 gameplay tick 内完成借用、运动、碰撞候选查询、命中 intent 发布和延迟回收；它不计算最终伤害、不写 HP、不决定武器冷却，也不直接播放表现。系统统一承载直线飞剑、环绕飞剑、持续区域和敌对投射物，并以固定容量、稳定排序和 A/B 发布保证同一 seed 与输入得到相同结果。

## Player Fantasy

玩家应感到飞剑数量、轨迹与覆盖方式真实地改变了战场：直线剑迅速穿透怪潮，环绕剑形成近身防线，持续区域控制空间，敌方弹体则以清晰轨迹逼迫走位。屏幕再拥挤，弹体也不能凭空消失、重复命中或因为帧率改变轨迹。

## Detailed Design

### Core Rules

#### R1 — 权威边界与 phase

- ProjectileSystem 独占 attack-object 的 pool borrow identity、active slot、运动状态、hit history 与 release reason。
- 它不得写 Player/Enemy HP、技能冷却、Buff snapshot、XP/drop 或战斗终局；命中只发布给 DamageSystem。
- 它作为 required participant 使用 `stable_order=5`，仅参与 `SPAWN_INTENT`、`MOVEMENT_COMMIT`、`QUERY`、`QUERY_CONSUME`、`DEFERRED_REMOVAL`。
- 在 `QUERY/QUERY_CONSUME` 中，Projectile owner 必须先调用 `WEAPON_EXECUTION_CAPABILITY_V1` 的对应子阶段，再执行自身 swept query/consume；Weapon 不是第二个 GameRoot participant。tick T 发布的 Weapon projectile action 仅在 T+1 `SPAWN_INTENT` 进入本系统。
- Elite Enemies的魂针同样只在tick T latch、T+1 `SPAWN_INTENT`进入；每个鬼雾修士恰3行原子batch，MVP最坏3只同tick使Elite contribution=9。Boss环形毒弹为8行原子batch，Boss pending/active contribution均为8；behavior2/4普通远程贡献仍待Normal content冻结。
- 所有推进只来自 GameRoot typed phase context；禁止独立 `_process/_physics_process`、Timer、Tween 或 wall-clock 补偿。

`PROJECTILE_PHASE_ROW_V1={participant_id=PROJECTILE,role_id=PROJECTILE,stable_order=5,allowed_phases={SPAWN_INTENT,MOVEMENT_COMMIT,QUERY,QUERY_CONSUME,DEFERRED_REMOVAL},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=ProjectileSystem/v1,owner_gdd_path=design/gdd/projectile-system.md,phase_row_id=PROJECTILE_PHASE_ROW_V1,required=true}`。

#### R2 — 类型化生成与准入

- 输入为 `ProjectileSpawnIntentV1`：battle/config/tick/authority、source identity、skill ID、faction、mode、origin、direction、speed、lifetime、shape、pierce/hit policy、damage payload ref、stable sequence。
- `SPAWN_INTENT` 先校验完整 batch，再按 `source_role_order → source_id → skill_id → intent_sequence` 排序，最后逐条向 Object Pooling 借用。
- batch header 或任一行非法时整批拒绝；池不足不得部分生成，不得换成别的 projectile，也不得运行时扩容。
- MVP 精确上界：`projectile_active_capacity=400`、`projectile_pending_spawn_capacity=32`、`projectile_pool_capacity=448`（400 active + 32 pending + 16 spare）。

#### R3 — 四种运动模式

- `LINEAR`：`p_next=p_prev+dir_norm*speed*dt`，以 swept segment/capsule 防止高速穿透。
- `ORBITAL`：围绕 matching Player motion carrier，以整数 tick age 推导角度和半径；不读取渲染 transform。
- `PERSISTENT_AREA`：中心可固定或跟随明确 source carrier，位置不依赖 Node 父子变换；按配置 hit interval 产生候选。
- `HOSTILE`：复用 LINEAR/AREA 运动，但 faction 与 Player direct narrow phase 固定为敌对规则。
- 所有模式使用发布的 tick-start snapshot 计算，再原子提交 motion bank；中途 source 失效按冻结的 follow policy 处理。

#### R4 — 查询与窄相

- Projectile 本身不注册 SpatialGrid，避免 400×动态更新污染网格；友方攻击只用一个 caller-owned `ENEMY` query buffer。
- buffer 容量固定为 Enemy active cap 303，且整个系统复用一组 `query_buffer[303]` 与 `hit_workspace[303]`，禁止为每个弹体分配数组。
- hostile projectile 不查询不存在的 PLAYER mask，只与 matching `PlayerMotionCommitCarrierV1` 做 swept narrow phase。
- 候选按 target identity 排序后窄相；`BUFFER_TOO_SMALL`、stale view 或 overflow 使当前 tick batch fail closed，禁止使用截断集。

#### R5 — 命中与重复命中策略

- `ONCE_PER_LIFETIME`、`ONCE_PER_TICK`、`INTERVAL_TICKS` 与 `PIERCE_COUNT` 都是生成时冻结的数据策略。
- 命中键为 `(projectile_instance_id, projectile_borrow_id, target_id, target_borrow_id, eligible_tick)`；同键最多发布一次。
- pierce 在 canonical target order 中递减；达到上限后标记 pending removal，但已冻结的当前命中仍完整发布。
- 命中只生成 `DamageIntentV1` 或 `AreaDamageIntentV1`；最终 crit、减伤、护盾、击退与实际伤害归 DamageSystem。

#### R6 — 延迟移除与池回收

- 到期、越过技术域、命中耗尽、owner cancel、battle teardown 与 contract fault 只写入 `ProjectileRemovalIntentV1`。
- `DEFERRED_REMOVAL` 按 instance/borrow ID 排序，向 Pool 提交一次 release；成功 receipt 后才清 active slot。
- duplicate removal/release receipt 为 `OK_NOOP`；borrow 不匹配不得影响新实例。
- 正常远距 projectile 退役没有 kill、XP、drop 或 death presentation。

#### R7 — 复活危险贡献

- 能在下一 gameplay tick 命中玩家的 hostile projectile/area 必须发布 `ReviveHazardIntentV2{shape_code=CIRCLE}`，保守 bound 覆盖 swept path。
- Projectile 对 DamageSystem 的 hazard 精确贡献上界为 400；不得为了替身符复活而删除、冻结或改道危险物。
- Boss毒雾要求`ReviveHazardSnapshotV2`的`EXTERIOR_CIRCLE`，但所有Projectile仍只发布`CIRCLE`保守swept row。总容量公式为`400+EnemyNonProjectile_H+2 Boss+Stage_H`；后两类未知项未冻结时 revival integration保持BLOCKED。

#### R8 — 双缓冲、确定性与错误

- motion、hit intent、removal、hazard 都写 inactive bank；完整校验后 selector 只切一次。
- 所有 float 中间量要求 finite，发布前规范化 `-0.0`；固定操作顺序，不依赖 Node/Dictionary/信号顺序。
- gameplay overflow、非法 mode、非有限 motion、重复 identity 冲突均锁存 fault；旧 published bank 保持有效且不发布部分结果。
- 表现池可独立降级，但不得反向改变 active projectile、命中与 damage intent。

### States and Transitions

| State | Meaning | Allowed next |
|---|---|---|
| UNBOUND | 未绑定 battle/config/pool | READY, FAULTED |
| READY | 可接收 spawn batch | ACTIVE, FAULTED, TORN_DOWN |
| ACTIVE | 当前 tick 的运动/查询/命中流程中 | READY, FAULTED, TORN_DOWN |
| FAULTED | 锁存首个 gameplay fault | TORN_DOWN |
| TORN_DOWN | banks invalid，generation 已推进 | UNBOUND |

单 projectile slot 只允许 `FREE → PENDING_SPAWN → ACTIVE → PENDING_REMOVAL → FREE`；任何跨边或 borrow identity 不匹配均 fail closed。

### Interactions with Other Systems

| System | Contract |
|---|---|
| GameRoot | 驱动五个合法 phase、pause barrier、battle/authority token |
| WeaponSystem | 发布友方 projectile execution/spawn plan；不取得 projectile lifecycle 权威 |
| Enemy/Boss | 发布敌对 projectile spawn plan与明确 source carrier |
| Object Pooling | 提供 448 个 attack-object slot、borrow/release receipts |
| SpatialGrid | 仅查询 ENEMY，caller-owned buffer 303 |
| PlayerController | 提供 matching motion carrier；不让 projectile 直接写 HP |
| DamageSystem | 消费命中 intent 与最多 400 条 hazard contribution |
| Stage/Map | 提供 `world_safe_aabb` 与 reachability/retire 几何 |
| BattleUI/VFX/Audio | 只消费 committed presentation projection，可丢低优先级表现 |

## Formulas

### F1 — Linear motion

`p1 = p0 + normalize_or_zero(direction) * speed * fixed_dt`

约束：`speed>=0`，所有输入/中间量 finite；零方向保持原位并按配置进入 removal，不用随机方向。

### F2 — Orbital motion

`theta_t = theta0 + angular_speed * age_ticks * fixed_dt`

`p_t = anchor_t + radius * (cos(theta_t), sin(theta_t))`

实现必须固定数学路径和读回点；跨架构 bit-exact 在导出物证据完成前为 OPEN。

### F3 — Swept broad-phase bound

`swept_aabb = merge(aabb(p0, shape_bound), aabb(p1, shape_bound))`

窄相使用 closed boundary；端点相切算命中。

### F4 — Lifetime and interval

`age_ticks_next = age_ticks + 1`

`expired = age_ticks_next >= lifetime_ticks`

`interval_eligible = (tick - first_eligible_tick) mod hit_interval_ticks == 0`

`lifetime_ticks>=1`、`hit_interval_ticks>=1`，pause 时 age 与 tick 均不推进。

### F5 — Capacity invariant

`pool_required = active_capacity + pending_spawn_capacity + spare_capacity = 400+32+16=448`

`query_workspace_required = enemy_active_capacity = 303`。

## Edge Cases

- spawn 与 teardown 同 tick：terminal/teardown gate 优先，spawn 不借用。
- 生成点已在目标内部：eligible tick 允许时算一次命中，不重复补扫。
- 高速弹体跨过多个目标：按 swept 命中参数再按稳定 target identity 决定最终 canonical 顺序；pierce 不依赖物理回调顺序。
- source 在 spawn 后死亡：弹体按 frozen detach policy 继续或移除，绝不改绑其他 source。
- target 在 QUERY 后 release：DamageSystem 根据 target borrow identity suppress，不重定向。
- `world_safe_aabb` 越界：写 removal intent；不得 clamp、wrap 或读取 Camera 边界。
- 400 active 满载再来 1 条：整批 admission 失败，禁止只生成前 N 条。
- pause 位于 phase 中间：当前已开始 tick 按 GameRoot barrier 收敛，暂停期间运动/age/hit interval 均零推进。
- hazard 空集必须发布合法 count=0 view；missing/stale/overflow 不得冒充安全。
- presentation object 不足：只丢表现，不回收 gameplay projectile。

## Dependencies

| Dependency | Status / requirement |
|---|---|
| GameRoot & Scene Flow | In Review；需接纳 stable_order=5 row 与 phase workload |
| Object Pooling | In Review；需冻结 448 slot capability/receipt |
| SpatialGrid | In Review；ENEMY buffer 303，BUFFER_TOO_SMALL fail closed |
| Stage & Map | In Review；V2 world domain/retire geometry |
| PlayerController | In Review；matching motion carrier |
| DamageSystem | Designed / Full Review Pending；intent 与 hazard consumer |
| WeaponSystem | Designed / Full Review Pending；通过 versioned capability 在 QUERY/QUERY_CONSUME 发布执行计划，projectile action 固定 T+1 消费 |
| Enemy/Elite/Boss | Enemy In Review；Elite三魂针=9、Boss八弹=8已冻结；behavior2/4 Normal与global producer sum仍BLOCKED |

## Tuning Knobs

| Knob | MVP bound/default | Owner |
|---|---:|---|
| `projectile_active_capacity` | 400 | Config/Projectile |
| `projectile_pending_spawn_capacity` | 32 | Config/Projectile |
| `projectile_pool_capacity` | 448 | Config/Pool |
| `projectile_pool_spare_capacity` | 16 | Config/Pool |
| speed/lifetime/radius/angular_speed | per-skill, finite bounded | Weapon/Config |
| pierce_count | per-skill integer >=0 | Weapon/Config |
| hit_interval_ticks | integer >=1 | Weapon/Config |
| hostile telegraph lead | Boss/Enemy-owned, ticks | Boss/Enemy |
| Elite hostile pending contribution | 9 rows/tick | Elite Enemies |
| Boss hostile pending / active contribution | 8 / 8 rows | BossStateMachine；8弹原子batch、120t lifetime |
| Normal hostile pending / active contribution | 未冻结 | behavior2/4 owner；与Weapon+Elite+Boss checked sum须分别<=32/400 |

## Visual/Audio Requirements

- 直线、环绕、持续区域、敌对弹体必须有不同轮廓与运动语言；敌对危险不可只靠颜色区分。
- gameplay carrier 与视觉 trail 分离；trail、残影、火花溢出可降级，碰撞载体不可丢失。
- hit、pierce exhausted、area tick 与 hostile near-miss 只由 committed event 触发，失败/重放/remote retire 不播放命中反馈。
- 音频并发与合并窗口由 Audio owner 冻结；缺资源时静默降级，不改变 gameplay。

## UI Requirements

- BattleUI 不显示逐弹体调试状态；只显示技能冷却/等级、committed damage 与关键危险提示。
- 开发 overlay 可显示 active/pending/pool/query/hazard counts 和 overflow/fault，但 release build 默认关闭且只读。
- 敌对持续区域必须有与真实 bound 对齐的地面预警；误差阈值与最低规格可读性留待 BattleUI/Boss 联合验收。

## Acceptance Criteria

- **AC-PR01 `[U][I][BLOCKING]` phase/owner**：逐 phase spy 证明只在五个合法 phase 执行；直接 HP、skill cooldown、XP/drop、Node lifecycle 与独立 process 写入均为 0。
- **AC-PR02 `[U][BLOCKING]` typed spawn validation**：合法 batch 原子进入 pending；逐字段非法、stale token、冲突 duplicate 在 borrow/RNG/query 前失败，旧 bank 不变。
- **AC-PR03 `[U][I][BLOCKING]` capacity admission**：active/pending/pool 在 required-1/required/required+1 下仅精确合法 manifest 可启动；运行时 overflow 不截断、不扩容、不部分 spawn。
- **AC-PR03b `[U][I][BLOCKING][OPEN-WEAPON/NORMAL]` producer checked sum**：给定`Weapon_P+NormalEnemy_P=14/15/16`、Elite=9、Boss=8，Loading分别得到31/32/33；前两者通过pending hard cap，33在任何bank/Pool创建前失败。Weapon合法loadout或behavior2/4 Normal枚举缺失时该gate保持OPEN，禁止把剩余额度视为先到先得。
- **AC-PR04 `[U][BLOCKING]` slot FSM**：所有合法边成功，跨边/borrow mismatch 失败；每个 borrow 恰有一个 matching release receipt。
- **AC-PR05 `[U][BLOCKING]` F1 linear golden**：零方向、轴向、斜向与边界输入逐步等于 float64 golden，finite 且 `-0.0` 已规范化。
- **AC-PR06 `[U][BLOCKING][OPEN-RNG-EVIDENCE]` F2 orbital golden**：不同 age/radius/angular speed 与 pause-resume 轨迹一致；跨导出物 bit 结论在证据前保持 OPEN。
- **AC-PR07 `[U][I][BLOCKING]` swept collision**：高速穿越、端点相切、生成点重叠及多个目标均不漏判/重复；结果不依赖 physics callback 顺序。
- **AC-PR08 `[U][I][BLOCKING]` query workspace**：303 targets 使用唯一 caller-owned buffer/workspace；304 或 BUFFER_TOO_SMALL 原子 fault，无截断命中。
- **AC-PR09 `[U][I][BLOCKING]` hostile direct narrow phase**：hostile 仅读取 matching Player carrier；PLAYER Grid query、Camera/transform 读取为 0。
- **AC-PR10 `[U][BLOCKING]` hit policies**：四种 policy 在边界 tick、pause、pierce=0/N 下符合 R5，同 hit key 最多一次。
- **AC-PR11 `[U][I][BLOCKING]` canonical determinism**：producer/Node/Dictionary/候选排列改变时，spawn、motion、hit、removal 与 hazard 输出逐 bit 相同。
- **AC-PR12 `[U][I][BLOCKING]` damage handoff**：每个 committed hit 只发布一条 matching Damage intent；Projectile 对 crit/mitigation/shield/HP 的写入为 0。
- **AC-PR13 `[U][I][BLOCKING]` stale target/source**：target borrow 变化后不误伤新实例；source release 后按 frozen policy 处理且无 Node 解引用。
- **AC-PR14 `[U][I][BLOCKING]` removal exact-once**：到期、越界、pierce exhausted、cancel、teardown 每实例最多一条 removal 和一个 release receipt；duplicate 为 OK_NOOP。
- **AC-PR15 `[U][I][BLOCKING]` world domain**：越界只延迟移除，不 clamp/wrap；remote projectile retire 不产生 kill/XP/drop/death feedback。
- **AC-PR16 `[U][I][BLOCKING]` pause barrier**：pause 前已开始 tick 按 barrier 完成；paused 期间 spawn/motion/age/interval/query/hazard window 推进均为 0，resume 无补帧。
- **AC-PR17 `[U][I][BLOCKING][OPEN-HAZARD-TOTAL]` hazard contribution**：Projectile的0/1/400条CIRCLE row均按ID稳定发布并保守覆盖next-tick path，401 fault；再与`EnemyNonProjectile_H+Boss2+Stage_H`做checked sum。后两类未知项未冻结、V2 shape copy-out或总容量required±1证据缺失前不得宣布revive ready。
- **AC-PR18 `[U][I][BLOCKING]` double buffer failure**：任一 mid-batch fault 不切 selector、不发布部分 hit/removal/hazard，旧 view 持续有效。
- **AC-PR19 `[I][E][BLOCKING]` presentation isolation**：视觉池满、trail/audio 缺失不改变 gameplay hashes、damage intents、release tick 或 active count。
- **AC-PR20 `[U][I][BLOCKING]` teardown isolation**：各状态 teardown 后旧 token/view/borrow 全拒绝，新 battle 无污染。
- **AC-PR21 `[P][BLOCKING-TOOLING]` static allocation guard**：生产热路径禁止容器构造/增长、closure、带参 signal、unstable sort、runtime node/resource 创建；guard 与正反 fixture 缺失时 INCONCLUSIVE。
- **AC-PR22 `[P][E][OPEN-EVIDENCE]` full load**：最低规格 release build 在 400 active、32 pending、303 candidates 下运行 10000 tick×3，gameplay allocator/growth/overflow 为 0并报告帧耗时分位；缺 artifact/raw evidence 不通过。

## Open Questions

| ID | Status | Decision | Owner |
|---|---|---|---|
| OQ-PR01 | `PARTIAL-SPAWN-ABI` | Weapon已冻结T+1 plan；Elite=9、Boss=8均冻结原子batch；仍需Projectile逐字段接纳、behavior2/4 Normal row、first-error与global checked capacities | Producer owners |
| OQ-PR02 | `BLOCKED-POOL-ABI` | 冻结 448 attack-object capability、borrow/release receipt 映射 | Pool + Projectile |
| OQ-PR03 | `BLOCKED-HIT-HISTORY` | 选择固定容量 hit-history 表结构及最坏上界 | Projectile + Config |
| OQ-PR04 | `BLOCKED-HAZARD-TOTAL` | Projectile=400、Boss nonprojectile=2已知；汇总Enemy nonprojectile/Stage后冻结V2 revive_hazard_capacity | Damage + Enemy + Boss + Stage + Config |
| OQ-PR05 | `OPEN-MATH-EVIDENCE` | 验证 Godot 4.7.1 orbital/swept 数学跨目标导出物一致性 | QA + RNG ADR |
| OQ-PR06 | `PARTIAL-PRESENTATION` | Audio/BattleUI已冻结priority/voice与低级降级；Projectile travel/near-miss/expire row、Weapon cast与Damage hit唯一owner、trail/VFX及真机阈值仍BLOCKED | VFX + Audio + BattleUI |
| OQ-PR07 | `RE-REVIEW-PENDING` | 将 phase row、容量与 workload/hash 传播到 GameRoot/Config/Pool/registry | Architecture owners |
