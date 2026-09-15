# WeaponSystem

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：STEAM_MISSION_V1/STEAM_SAVE_V2的目标、终态与完整恢复要求见mission-objectives.md、save-steam-pc.md及ADR-0006。本owner的目标身份/生命周期（适用时）、matching-tick snapshot、schema/validator/migration、required-owner与容量贡献待正式冻结并接线；下方legacy合同不因本路由而自动满足新profile，缺失时禁止生产启用。

> **Status**: Designed / Full Review Pending
> **Author**: User + Codex
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 移动躲避 + 自动御剑 + 功法进化的战斗爽快度
> **Review Mode**: lean

## Overview

WeaponSystem 是韩立六种主动技能的自动释放与构筑执行域：它读取已发布的玩家位置、敌人空间快照和下一 tick 生效的技能快照，按固定 gameplay tick 推进每个技能的攻击节奏，完成确定性选敌，并原子发布类型化执行计划。ProjectileSystem 负责将其中的飞剑、火球、飞盾、傀儡弹体和持续区域变成池化攻击对象；DamageSystem 负责最终伤害、恢复、Buff 数值修正和护盾吸收。Weapon 不直接写 HP、不拥有 projectile 生命周期，也不自行编排 GameRoot phase。

## Player Fantasy

玩家只需专注走位，法术会按构筑自动、可靠地寻找合适目标。青元剑气从一柄稳健飞剑成长为追击剑阵，火弹术从清杂火球成长为连珠火海，玄铁飞盾把贴身危险变成可见防线，傀儡、雷符和灵藤分别提供持续火力、精英爆发与区域控制。

成长不能只是伤害数字增加：每次获得关键层级或进化后，玩家应在下一轮释放中看到数量、覆盖、节奏、目标偏好或战场控制方式发生明确变化。系统应保持“韩立提前布置手段、自己专注脱身”的气质，而不是替玩家移动或暗中修正失败走位。

## Detailed Design

### Core Rules

#### R1 — 权威边界与调度

- WeaponSystem 独占六主动技能的 equipped identity、等级/进化形态读取、cadence state、选敌决策、傀儡逻辑槽和 `WeaponExecutionPlanV1`。
- Weapon 不加入 GameRoot required role 集；它是 `WeaponExecutionCapabilityV1`，由 `PROJECTILE_PHASE_ROW_V1` 的 owner 在 `QUERY` 与 `QUERY_CONSUME` 内按固定子序调用。这样保留 Projectile `stable_order=5`，不引入新的全局 participant 顺序。
- `QUERY` 固定先执行 Weapon 的 snapshot freeze、due 判定与全部 target queries，再执行 Projectile swept queries；`QUERY_CONSUME` 固定先由 Weapon 原子发布 plan，再由 Projectile 解析既有 attack-object hits，随后 Damage（stable order 6）消费全部 direct/area/hit intents。
- tick T 发布的 projectile spawn/cancel action 固定 `eligible_tick=T+1`，由 Projectile 在 T+1 `SPAWN_INTENT` 消费；T 的 direct/area action 可由 Damage 在 T `QUERY_CONSUME` 消费。
- Weapon 不定义 `_process/_physics_process`、Timer、Tween、wall-clock cadence、带参 gameplay signal 或 Node 遍历。

`WEAPON_EXECUTION_CAPABILITY_V1={capability_id=WEAPON_EXECUTION,owner_contract_id=WeaponSystem/v1,invoking_participant_id=PROJECTILE,allowed_phases={QUERY,QUERY_CONSUME},suborder=1,allowed_success_statuses={OK,OK_NOOP},required=true}`。

#### R2 — 技能槽与发布快照

- 玩家最多装备 4 个主动技能；catalog 固定 6 个，每个等级域为 1..5。初始 `QINGYUAN_SWORD_QI` 占一个主动槽。
- SkillDraftSystem 是 build choice owner，发布 `SkillLoadoutSnapshotV1`；Weapon 只读取，不自行升级、塞槽或进化。
- 新增、升级、进化与辅助功法变化只写 inactive loadout bank，最早从下一 gameplay tick 生效；当前 tick 已冻结的执行计划不回写。
- snapshot 行按 `slot_index ASC`，携带 skill ID、level、form ID、config row ID、source revision；重复槽、非法组合或非单调 revision 使整个 tick 计划失败。

#### R3 — 统一技能组件模型

每个主动技能由不可变 Config 组件组合，而不是六套互不兼容脚本：

| Component | Responsibility |
|---|---|
| `CadenceComponentV1` | 初次释放、固定 tick 间隔、每次释放最大 action 数 |
| `TargetPolicyComponentV1` | NONE、NEAREST、DENSEST_CLUSTER、RANDOM_UNIQUE、ELITE_BOSS_THEN_NEAREST |
| `EmissionComponentV1` | projectile、orbital、persistent area、direct strike 或 summon-shot 动作 |
| `PayloadComponentV1` | skill/damage tag、基础倍率引用、crit 资格、modifier intent 引用 |
| `EvolutionComponentV1` | 五层主动 + 指定辅助功法对应的新 form/config row |
| `PresentationTagV1` | 仅提供表现语义，不实例化 VFX/audio/UI |

每个 form 在 Loading 展开成固定宽度的 runtime row；Active 不查动态资源、不构造 Dictionary/Array，也不在技能间共享可变 Config。

#### R4 — 六主动技能与四进化

| Skill | Base targeting/emission | Level 1–5 growth axes | Evolution |
|---|---|---|---|
| 青元剑气 | `NEAREST`；直线飞剑 | 伤害、飞剑数量、穿透 | 剑诀残页 → 小庚剑阵：持续环绕剑阵，并按 cadence 分出追击剑光 |
| 火弹术 | `DENSEST_CLUSTER`；爆炸火球 | 爆炸范围、数量、灼烧 | 聚灵诀 → 连珠火海：连续轰炸密集区并留下持续燃烧区域 |
| 玄铁飞盾 | `NONE`；玩家锚定环绕物 | 数量、半径、转速/击退 | 护体真气 → 金刚护身阵：飞盾常驻、强化击退并周期发布护盾来源 |
| 机关傀儡 | 基础 `NEAREST`；傀儡逻辑槽自动射击 | 攻速、持续时间、数量 | 大衍神念 → 双傀儡杀阵：两个常驻逻辑槽，`ELITE_BOSS_THEN_NEAREST` |
| 雷爆符 | `RANDOM_UNIQUE`；直接雷击 | 雷击数量、伤害、麻痹 | MVP 无进化；符箓真解只提供范围伤害修正 |
| 乙木灵藤 | `NONE`；玩家周围 persistent area | 范围、pulse 频率、减速 | MVP 无进化；长春功的周期恢复走 Damage recovery intent，不由灵藤代发 |

具体每层数值由 Config 表冻结；本表只冻结允许改变的轴，禁止升级时暗改未列属性。

#### R5 — 自动释放与 cadence

- 每个 equipped slot 保存整数 `cooldown_remaining_ticks` 与 `cast_sequence`；首次装备从 snapshot 的 `first_fire_delay_ticks` 开始，值为 0 时立即 eligible。
- 每个 Active tick 只减 1 至 0；remaining=0 时最多释放一次，成功 publish 后以 F1 写入下一周期。暂停不推进 gameplay tick，因此不补发 wall-clock 累积攻击。
- 同一 tick 多技能 due 时按 `slot_index ASC → skill_id ASC` 处理；所有动作先做总容量预检，不能前几个技能成功、后一个被截断。
- 等级/被动变化在下一 tick 按 F2 迁移剩余 tick；进化保持 slot/cast sequence，避免通过选择界面重置冷却或免费多打一轮。

#### R6 — 选敌策略

- `NEAREST`：以 matching `PlayerMotionCommitCarrierV1.position` 或明确 summon anchor 调用 `query_nearest_into(...,ENEMY)`；距离相等沿用 Grid registration sequence tie-break。
- `DENSEST_CLUSTER`：一次 `query_circle_into` 取得完整候选，对每个候选用同一完整集合计算 closed-radius 邻居数；按 `neighbor_count DESC → distance_to_anchor ASC → full target identity ASC` 选中心。不得用 Node 遍历或截断候选近似。
- `RANDOM_UNIQUE`：先得到完整合法候选并按 full identity 升序，再对 `LEI_TARGET` stream 每个选择槽精确消费一次 bounded roll，以 swap-index workspace 无放回选择；候选为空消费 0 次。
- `ELITE_BOSS_THEN_NEAREST`：优先级 `BOSS > ELITE > NORMAL`，同级按中心距离再按 Grid stable identity。
- `NONE`：玩家锚定技能不查询敌人；不得为让技能“看起来有用”偷偷重定向。

#### R7 — 执行计划与容量

- `WeaponExecutionPlanPackageV1` 使用同一 token 下的 typed A/B SoA banks；package header 固定为 `{schema_version=1,battle_instance_id,config_snapshot_id,source_authority_revision,source_skill_snapshot_revision,source_modifier_snapshot_revision,source_player_motion_revision,query_tick_revision,bank_id,plan_publish_revision,projectile_spawn_count,direct_damage_count,area_damage_count,modifier_count,shield_source_count,cancel_count,valid}`。
- plan token 固定为 header 的 `{battle_instance_id,config_snapshot_id,query_tick_revision,bank_id,plan_publish_revision,source_authority_revision}` 子集；row identity 统一为 `{skill_family_id,skill_id,skill_revision,slot_index,activation_sequence,emission_index,intent_sequence}`，按该七段升序发布。
- typed banks 固定为 `ProjectileSpawnIntentBankV1`、`WeaponDirectDamageIntentBankV1`、`WeaponAreaDamageIntentBankV1`、`WeaponModifierIntentBankV1`、`WeaponShieldSourceIntentBankV1` 与 `AttackObjectCancelIntentBankV1`；每行只属于一个 bank，不使用 Variant/Dictionary union。
- spawn row 在 Projectile R2 字段基础上必须携带 `eligible_tick=T+1`、完整 source/skill/target identity、origin revision、mode、shape、lifetime、hit/follow policy与 payload ref；target 是冻结瞄准快照，不授权 homing 或 runtime retarget。
- direct/area row 逐字段转成 Damage intent；burn/slow/paralysis 以 `on_hit_effect_set_id` 随 hit payload 传递，未确认命中前不产生 modifier。cancel row 携带 prior skill revision、projectile instance/borrow、reason 与 `eligible_tick=T+1`。
- Loading 通过 F7 对所有合法 4-skill 构筑求各 typed bank 的精确上界。Projectile 子集与 Enemy/Boss producer 的 checked sum 必须 `<=projectile_pending_spawn_capacity=32`；Weapon 不独占 32，也不借 16 个 pool spare 提升玩法 quota。
- targeting 共用预分配候选/评分/index workspace，各容量 303；plan、workspace 与傀儡逻辑槽在 Active 不增长或换 backing。

#### R8 — 输出 owner 边界

- `PROJECTILE_SPAWN` 交给 Projectile，固定下一 tick 激活；Weapon 不持 projectile borrow/node/position/hit ledger。
- `DIRECT_DAMAGE/AREA_DAMAGE` 转为 Damage typed intent；Weapon 不判 crit、不做 mitigation、不写 HP/death。
- slow、paralysis、damage/range/cooldown modifiers 只发布下一 tick modifier intent；Damage/对应状态 owner 解析，不在 Weapon 中直接改 Enemy 或 Player。
- 金刚护身阵的 `SHIELD_SOURCE` 由 Weapon 保存定容 shield-source 状态并发布只读 snapshot；Damage 计算吸收，phase 6 通过版本化 consumption receipt exact-once 扣减。跨来源统一 ABI 冻结前标 `BLOCKED-DEFENSE-ABI`。
- 傀儡是 Weapon 的最多 2 个纯数据逻辑槽，位置由 frozen anchor policy 推导；傀儡射出的对象才进入 Projectile pool。MVP 不为傀儡创建独立可碰撞/受伤实体。

#### R9 — 状态、错误与确定性

- 所有计划只写 inactive bank，完整成功后 selector 切一次；query/RNG/capacity/identity 任一失败时旧 plan 保持，当前 tick 新输出为 0 并锁存 fault。
- replay 去重键为 `(battle_instance_id,tick_revision,slot_index,cast_sequence,action_ordinal)`；相同 payload 重放为 `OK_NOOP`，冲突 payload fault。
- stale target 在下游消费时不重选；由 Projectile/Damage 按 borrow identity suppress 或 fault，防止同一 cast 因时序变化改打另一目标。
- Weapon 不消费 `CRIT` stream；只有雷爆符 `RANDOM_UNIQUE` 消费 `LEI_TARGET`。同 seed、snapshot、authority 与候选集必须产生相同计划。

### States and Transitions

| Owner state | Meaning | Allowed next |
|---|---|---|
| UNBOUND | 未绑定 battle/config/capability | READY, FAULTED |
| READY | 可接受 matching tick 调用 | PLANNING, FAULTED, TORN_DOWN |
| PLANNING | inactive plan 正在构造，尚不可见 | READY, PUBLISHED, FAULTED |
| PUBLISHED | 当前 tick plan 已原子发布 | READY, FAULTED, TORN_DOWN |
| FAULTED | 首个 gameplay fault 已锁存 | TORN_DOWN |
| TORN_DOWN | view invalid，generation 推进 | UNBOUND |

单技能槽只使用 `EMPTY/EQUIPPED/EVOLVED` loadout 状态；cadence 只有 `NOT_DUE/DUE/COMMITTED` 派生状态，不复制 SkillDraft 的升级 FSM。傀儡逻辑槽只允许 `FREE→ACTIVE→EXPIRED→FREE`，进化为常驻时 `EXPIRED` 只由 battle teardown 触发。

### Interactions with Other Systems

| System | Input to Weapon | Output from Weapon / ownership boundary |
|---|---|---|
| GameRoot | typed phase context、pause/teardown、authority token | 无独立 participant；通过 Projectile capability 调用 |
| SkillDraftSystem | next-tick `SkillLoadoutSnapshotV1` | 不回写选择、等级、槽位或进化资格 |
| PlayerController | matching committed position/identity | 只作攻击 anchor；不改移动/HP |
| SpatialGrid | nearest/circle ENEMY query 与 stable identity | caller-owned carriers；不注册 Weapon/Player |
| RNG System | `LEI_TARGET` bounded roll | 仅雷爆符随机唯一目标；调用次数可审计 |
| ProjectileSystem | capability host 与 32-row spawn intake | projectile lifecycle/motion/collision 全归 Projectile |
| DamageSystem | modifier snapshot与 typed intent schema | direct/area/modifier/shield-source；最终数值与 HP 不归 Weapon |
| Config/Data | 六技能各 form、每级 row、capacity/hash | Active 只读 immutable snapshot |
| BattleUI/VFX/Audio | committed skill/presentation projection | 不能回写 cadence 或生成动作 |

## Formulas

统一数值规则：Config build 与 runtime 每步均 checked finite/checked integer；非法值拒绝而非静默 clamp。Vector2 构造后 readback 再校验，发布前 `-0.0→+0.0`。

### F1 — Effective cadence period

The `effective_period_ticks` formula is defined as:

`effective_period_ticks = max(1, ceil(base_period_ticks * resolved_cooldown_multiplier))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base interval | `B` | int | `[1, INT32_MAX]` | Config 已量化的基础攻击周期 |
| Resolved multiplier | `M` | float64 | `(0,1]` for MVP | Skill snapshot 已解析的冷却倍率；聚灵诀每层 `-6%`，五层基线为 `0.70` |
| Effective interval | `P` | int | `[1,INT32_MAX]` | 下一次成功释放后使用的 tick 周期 |

**Output Range:** 1 到 checked int32 上界；乘法非 finite 或 ceil 溢出时配置/批次失败。  
**Example:** `B=60`、聚灵诀 3 层令 `M=0.82`，则 `P=ceil(49.2)=50 ticks`。

首次延迟允许 `first_fire_delay_ticks=0`。Active tick 先执行 `remaining'=max(remaining-1,0)`；ready 且计划成功发布后才令 `remaining=P`，无目标或失败保持 `remaining=0`。

### F2 — Snapshot cadence migration

The `migrated_remaining_ticks` formula is defined as:

`migrated_remaining_ticks = min(old_remaining_ticks, new_effective_period_ticks)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Old remaining | `R_old` | int | `[0,old_period]` | 新 snapshot 生效前剩余 tick |
| New period | `P_new` | int | `[1,INT32_MAX]` | F1 新周期 |

**Output Range:** `[0,P_new]`；不会产生负债、补发或同 tick 双 cast。  
**Example:** `R_old=80,P_new=50` 得 50；`R_old=40,P_new=50` 仍为 40。

### F3 — Densest-cluster targeting

The `density_score` formula is defined as:

`density_score(c) = Σ_j I(closed_effect_shape(c) intersects target_shape(j))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Candidate center | `c` | Vector2 | finite world domain | 位于 target range 内的候选敌人中心 |
| Candidate target | `j` | identity+shape | at most 303 | 完整 resolved enemy identity/shape |
| Indicator | `I` | int | `{0,1}` | closed narrow-phase 是否相交 |
| Score | `S` | int | `[1,303]` | 以 c 为落点可覆盖的目标数 |

**Output Range:** 1..303；空集无 winner。  
**Example:** A 落点覆盖 5 个目标、B 覆盖 4 个，则选 A。并列时按 `origin center distance ASC → full target identity ASC`。

宽相半径为 `checked_sum(target_range,effect_radius,max_enemy_bound)`；最坏 303²=91,809 次窄相/activation，目标设备预算仍为 `OPEN-PERF`。

### F4 — Normalized aim direction

The `aim_direction` formula is defined as:

`delta = target_snapshot - origin_snapshot; aim_direction = delta / sqrt(delta.x² + delta.y²)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Origin | `o` | Vector2 | finite world domain | matching committed source pose |
| Target | `t` | Vector2 | finite world domain | query 时冻结的目标中心 |
| Delta | `d` | Vector2 | finite | `t-o` |

**Output Range:** finite unit Vector2 after real_t readback。  
**Example:** `o=(0,0),t=(3,4)` 得 `(0.6,0.8)`。

若 `delta=ZERO`，只允许 Config 的 `HOLD_READY` 或 `USE_FROZEN_FACING`；禁止随机方向。多发偏角为 `offset_i=(i-(count-1)/2)*spread_step`，具体 count/spread 为 Config tuning。

### F5 — Random-unique target selection

The `random_unique_index` formula is defined as:

`j_i = LEI_TARGET.roll_int_range(i,n-1); swap(indices[i],indices[j_i]); selected_i=indices[i]`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Candidate count | `n` | int | `[1,303]` | canonical 排序后的合法目标数 |
| Strike count | `K` | int | `[0,303]` | 当前 form 的雷击数 |
| Strike ordinal | `i` | int | `[0,K-1]` | 固定调用序号 |

**Output Range:** `min(K,n)` 个不重复 target；每次已启动 cast 精确消费 K 个 LEI_TARGET words。  
**Example:** `n=3,K=5` 输出 3 个唯一目标并消费 5 words；候选耗尽后的 2 words 通过冻结的 discard API 推进。

`n=0` 时不启动 activation、消费 0 words并保持 READY。RNG discard capability 未冻结前本公式为 `BLOCKED-LEI-DISCARD-ABI`。

### F6 — Multi-emission spread

The `emission_offset` formula is defined as:

`emission_offset_i = (i - (emission_count - 1) / 2) * spread_step`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Emission ordinal | `i` | int | `[0,N-1]` | 同一次 cast 内稳定序号 |
| Emission count | `N` | int | `[1,32]` | Config 数量 |
| Spread step | `Δ` | float64 | finite bounded | 相邻发射方向的角偏移 |

**Output Range:** 关于 0 对称的 finite offsets。  
**Example:** `N=3,Δ=10°` 得 `[-10°,0°,10°]`；`N=2` 得 `[-5°,5°]`。

### F7 — Exact typed-bank capacities

The `weapon_plan_capacities` formula is defined as:

`W_X = max_{L in legal_loadouts} checked_sum(x_s for s in L); W_PLAN=checked_sum(W_P,W_D,W_A,W_M,W_C)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Legal loadout | `L` | set | at most 4 distinct families | Config 白名单中的合法 base/evolved 构筑 |
| Projectile rows | `p_s` | int | `[0,32]` | form 单 tick 最多 spawn rows |
| Direct rows | `d_s` | int | `[0,303]` | form 单 tick direct target rows |
| Area rows | `a_s` | int | `[0,1]` | 当前仅乙木直接 area |
| Modifier/shield rows | `m_s` | int | `[0,1]` | 当前仅金刚护盾周期 source |
| Cancel rows | `c_s` | int | `[0,400]` | 单次合法替换需取消的 attack objects |

**Output Range:** schema 安全界 `W_PLAN<=737`，但 production required 必须由实际 Config 枚举得到，不能直接填 737。  
**Example:** 若某合法构筑同 tick 各类 maxima 为 `12/4/1/0/8`，则该构筑需要 25 rows。

另须满足 `checked_sum(W_P,Enemy_P,Boss_P)<=32`；不满足则 `battle_ready=false`，不得 runtime 抢占。

### F8 — Downstream damage workload

The `weapon_damage_contribution_max` formula is defined as:

`W_DAMAGE = checked_sum(W_D, checked_mul(303,W_A), W_HIT)`

`W_HIT = max_L checked_sum(h_q for weapon-originated active attack object q)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Direct rows | `W_D` | int | `[0,303]` | 雷爆符等 direct targets |
| Area rows | `W_A` | int | `[0,1]` | 乙木 area，最坏展开 303 targets |
| Object hit rows | `W_HIT` | int | `[0,121200]` | 400 objects × 303 targets 的 schema 安全界 |

**Output Range:** schema 安全界 `W_DAMAGE<=121806`；不是推荐分配量。  
**Example:** production 必须用 pierce/hit policy/persistent count/legal loadout 求精确较小值，再与其他 Damage producer checked sum。

## Edge Cases

- **If 需要目标的技能到期但合法候选为空**：保持 READY，零 plan/Pool/RNG/假音效；目标出现后的首个合法 tick 最多释放一次，不补发积压攻击。
- **If Grid 返回 `BUFFER_TOO_SMALL`、stale 或 missing view**：整份 plan 不发布、所有技能 cadence/cast sequence 不推进，不能只用前 N 个候选。
- **If query 后目标死亡或 borrow 变化**：保留冻结 identity，由下游 suppress/fault；不临时重选。
- **If 同距、同密度或候选物理排列变化**：使用 R6 total order，结果不变。
- **If multi-spawn 下游只剩部分容量**：整 activation 预留失败、0 spawn，不能半发。
- **If Weapon+Enemy+Boss projectile contribution 超过 32**：Loading 失败；不在 runtime 以技能优先级竞争。
- **If 雷爆符 `K>n>0`**：输出 n 个唯一目标并精确消费 K words；`n=0` 不启动 cast也不消费。
- **If origin 与 target 重合**：只执行冻结的 zero-direction policy，不生成 NaN 或现场随机方向。
- **If ready tick 同时发生升级/进化**：tick 起点旧 snapshot 完成当前规则；新 revision 下一 tick 生效，禁止双发。
- **If base 技能进化时仍有 transient projectile**：旧对象按 spawn-time 参数自然收敛；旧 persistent emitter 先在 consumer-closed transaction 中 cancel，下一 tick 再激活 evolved emitter，不允许新旧持续对象同时伤害。
- **If 傀儡 source pose stale**：该 emitter 本 tick 不射击并进入 reconcile；不得换绑 Player 或另一傀儡。
- **If pause 发生**：remaining、summon duration、query、RNG、plan 均 0 推进；resume 不补射。
- **If T 发布 projectile action**：T+1 才能 borrow/activate；T 内新对象 motion/hit 必须为 0。
- **If burn/slow/paralysis 的 projectile miss、stale 或被 suppress**：不产生 modifier；只有 confirmed hit 可令 next-tick modifier 生效。
- **If active projectile 已达 400 或 gameplay pool admission 失败**：整 batch fault；只有 VFX/audio 不足可以降级。
- **If terminal/fault 出现在 plan 中途**：未 publish plan 丢弃；已发布 direct damage intent 按 GameRoot resolution 边界收敛，不重算。
- **If 相同 plan row 重放**：同 payload 为 `OK_NOOP`；同 identity 不同 payload fault。
- **If level 缺行、level=0/6、错误 family 进化或雷/藤出现 MVP evolution**：Loading/choice 拒绝，不填默认。

## Dependencies

| Dependency | Direction | Required contract / current state |
|---|---|---|
| GameRoot | Hard upstream | phase/token/pause/terminal；Weapon 通过 Projectile capability 调用，不新增 role |
| Config/Data | Hard upstream | SkillDefinition/Level/Form whitelist、合法构筑枚举与 capacity manifests；具体平衡仍 OPEN |
| SkillDraftSystem | Hard upstream | `SkillLoadoutSnapshotV1` writer；Designed / Full Review Pending，跨系统revision commit仍BLOCKED |
| PlayerController | Hard upstream | matching committed pose/identity；不得读 Node mirror |
| SpatialGrid | Hard upstream | ENEMY nearest/circle query、303 workspace、stable identity |
| RNG System | Hard for 雷爆符 | `LEI_TARGET`；discard word ABI 待冻结 |
| ProjectileSystem | Hard downstream | T+1 spawn/cancel、source pose、hit lifecycle；Designed / Full Review Pending |
| DamageSystem | Hard downstream | typed direct/area/on-hit modifier/shield ABI；Designed / Full Review Pending |
| EnemySystem | Read-only upstream | target identity/class/bound；Weapon 不写 HP/speed/lifecycle |
| BattleUI/VFX/Audio | Soft runtime, hard experience | committed plan/skill/presentation projection；不得回写 cadence |
| Progression Tree | Hard next-run modifier | Qingyuan L5令`QINGYUAN_FAMILY` projectile pierce +1；只从matching Config projection读取，Active不热改 |

**Progression static propagation（2026-09-03）**：青元L5的额外穿透持续作用于青元family会生成projectile hit链的基础/升级/进化形态；纯环绕direct tick不获得pierce。每枚相关projectile的hit/Damage rows最坏值需按authored pierce+1重算并传播Projectile/Damage/Config；actual capacity未签发前该perk integration保持BLOCKED，不得在压力下截断或静默关闭。

## Tuning Knobs

| Knob | Domain / baseline | Owner / status |
|---|---|---|
| active slots / auxiliary slots | 4 / 4 | Concept, locked |
| active families / level count / evolutions | 6 / 5 / 4 | Concept, locked |
| physics tick rate | 60 Hz | Config/GameRoot, locked |
| first delay / base period | tick integers, `>=0 / >=1` | SkillConfig, OPEN-BALANCE |
| target range / effect radius | finite `>=0` | SkillConfig；需回填 SpatialGrid max |
| damage/level multiplier | finite non-negative | SkillConfig + Damage, OPEN-BALANCE |
| projectile speed/lifetime/bound | Projectile legal domain | SkillConfig, OPEN-BALANCE |
| emission count/spread/pierce | checked against F7 | SkillConfig, OPEN-BALANCE |
| burn tick/duration | integer `>=1` | Damage modifier config, BLOCKED-ABI |
| orbit count/radius/speed/hit interval | bounded by Projectile workload | SkillConfig, OPEN-BALANCE |
| summon count | base config; evolved exactly 2 | Weapon; evolved count locked |
| summon duration/shot period | ticks `>=1` or evolved persistent | SkillConfig, OPEN-BALANCE |
| Lei strike count/paralysis | `K in [0,303]`; duration/strength TBD | SkillConfig + Damage, BLOCKED-ABI |
| vine radius/period/slow | finite/ticks/modifier TBD | SkillConfig + Damage, BLOCKED-ABI |
| shield refresh/cap | finite/ticks TBD | Weapon + Damage, BLOCKED-DEFENSE-ABI |

## Visual/Audio Requirements

- 六 family 可使用剑青、火红、盾金、机关材质、雷紫、木绿作为辅助色，但必须同时以轮廓、运动和音色区分，不能只靠颜色。
- raw target/query/plan 不播放表现；只有 Projectile committed spawn/hit、Damage committed receipt 或 matching SkillSnapshot revision 触发。
- 无目标不播放起手或命中；升级/进化反馈按 revision exact-once。
- 友方满屏特效必须让位 Player 轮廓、敌对 projectile/Boss telegraph 与掉落；表现 overflow 可丢低优先级，不改变 plan hash、cooldown 或 gameplay rows。
- 精确 VFX/audio pool、并发、遮挡阈值与目标设备证据为 `BLOCKED-PRESENTATION-BUDGET`。

## UI Requirements

- HUD 最多显示 4 个主动槽：family 图标、等级/进化状态与已发布 cooldown；UI 不自行倒计时、选目标或写 skill state。
- 升级/宝匣页由 SkillDraftSystem 提交选择；Weapon 最早下一完整 Active tick 读取。
- 进化提示必须显示“五层主动 + 对应辅助 + 精英宝匣选择”；雷爆符和乙木灵藤不得显示伪进化入口。
- debug overlay 只读 slot/ready/target/plan/capacity/RNG counters，release build 默认关闭。

## Acceptance Criteria

- **AC-WP01 `[U][I][BLOCKING]` owner/capability**：**GIVEN** Weapon、Player、SkillDraft、Projectile、Damage、Pool 与 Node spies，**WHEN** 覆盖 Active/Pause/Ending/Fault/teardown，**THEN** Weapon 只写 skill runtime、cadence、cast sequence、target decision 与 plan；HP、Projectile borrow/motion/hit、current Buff snapshot、XP/drop/terminal 直接写入均为 0，GameRoot 无新增 WEAPON row，Weapon 仅由 PROJECTILE 在 QUERY/QUERY_CONSUME 固定调用。
- **AC-WP02 `[U][BLOCKING]` component whitelist**：**GIVEN** 六 family、四 evolution、逐级 row 及未知/非法组合，**WHEN** Loading 展开 runtime rows，**THEN** 只有 R3/R4 允许组合成功；缺 level、重复 row、跨 family 进化、雷/藤 evolution 均 load fail，per-skill 自主 tick/process 数为 0。
- **AC-WP03 `[U][I][BLOCKING]` slot/state**：**GIVEN** 4/5 active、重复 family、level 0/1/5/6、合法/非法 revision，**WHEN** bind/装备/升级/进化/teardown，**THEN** 仅合法状态边成功；进化保持同 slot，非法输入在 cadence/query 前拒绝，旧局 view 全 invalid。
- **AC-WP04 `[U][I][BLOCKING][OPEN-SKILL-SNAPSHOT-ABI]` snapshot identity**：**GIVEN** matching 与逐字段 stale `SkillLoadoutSnapshotV1`，**WHEN** tick 起点 copy-out，**THEN** 仅 matching published bank 被读取；错 battle/config/tick/authority/revision/bank/generation 时 runtime/selector/RNG/query 零变化。
- **AC-WP05 `[U][I][BLOCKING]` next-tick semantics**：**GIVEN** N 已冻结 snapshot 且 N 中升级/进化/被动变化，**WHEN** 运行 N/N+1，**THEN** N 全用旧 row，变化最早 N+1 原子生效；既有 attack object 参数不热改。
- **AC-WP06 `[U][BLOCKING]` F1/F2 cadence golden**：**GIVEN** first delay 0/N、period 1/N、聚灵诀 level 0..5、remaining 大于/小于新 period，**WHEN** 逐 tick 推进，**THEN** effective period 与 migration 逐步等于 independent golden，每 skill 每 tick最多一次 activation，只有成功 plan publish 才 reset cooldown。
- **AC-WP07 `[U][I][BLOCKING]` no-target READY**：**GIVEN** target-required skill 到期而候选为空，随后目标进入范围，**WHEN** 连续运行，**THEN** 空场期间保持 READY、plan/Pool/RNG/表现均 0，目标出现首个合法 tick 精确 cast 一次且无 catch-up burst。
- **AC-WP08 `[U][I][BLOCKING]` phase latency**：**GIVEN** T 中 Weapon 选敌并发布 mixed plan，**WHEN** Projectile/Damage 消费，**THEN** direct/area 可在 T 进入 Damage，projectile spawn 只在 T+1 SPAWN_INTENT 借用且 T 内对应新 object motion/hit=0。
- **AC-WP09 `[U][I][BLOCKING]` nearest**：**GIVEN** 范围内外、边界上和中心等距敌人，**WHEN** 青元/基础傀儡选敌，**THEN** 使用 ENEMY nearest center-distance 与 Grid stable tie-break；Player Node/Camera/render transform 读取为 0。
- **AC-WP10 `[U][I][BLOCKING]` F3 densest**：**GIVEN** 内/边/外、多簇、真实 shape 与并列 score fixture，**WHEN** 火弹术选落点，**THEN** 使用完整 superset、closed narrowphase 与 `score DESC→distance ASC→identity ASC`，输出逐项等于 golden。
- **AC-WP11 `[U][I][BLOCKING]` densest buffer/fanout**：**GIVEN** 303/304 candidates 与 `BUFFER_TOO_SMALL`，**WHEN** 执行 densest query，**THEN** 303 完整计算，后两者整 plan fail；无截断、无部分 cooldown reset。91,809 checks 的设备预算在证据前 OPEN。
- **AC-WP12 `[U][I][BLOCKING][OPEN-LEI-DISCARD-ABI]` F5 random unique**：**GIVEN** `n=0/1/<K/=K/>K` 和固定 words，**WHEN** 雷爆符 cast，**THEN** n=0 为 0 calls/保持 READY；n>0 输出 `min(K,n)` unique targets 且精确 K calls，候选耗尽走 discard；第1/中/末 roll fault 均 0 publish/0 re-roll。
- **AC-WP13 `[U][BLOCKING]` F4/F6 direction/spread**：**GIVEN** 3-4-5 delta、zero delta、奇偶 emission count 和 spread 边界，**WHEN** 构造 aim rows，**THEN** readback finite、非零方向等于 golden、zero 只走冻结 policy、offset 关于 0 对称。
- **AC-WP14 `[U][I][BLOCKING][OPEN-SKILL-CONFIG]` six-skill base matrix**：**GIVEN** 六 family 的 level 1..5 Config fixtures，**WHEN** 各自在 due tick 执行，**THEN** 输出类型、目标策略、成长轴、row count 与 R4 一致；未列成长轴不变。逐级数值未冻结的数值断言保持 OPEN。
- **AC-WP15 `[U][I][BLOCKING]` summon origin/priority**：**GIVEN** Player 与两个傀儡位置分离、Normal/Elite/Boss 混合目标，**WHEN** 基础/进化傀儡射击，**THEN** origin 使用 matching summon pose；进化保持恰 2 逻辑槽，优先 `BOSS>ELITE>NORMAL` 后同类 nearest+identity，不偷读 Player 位置。
- **AC-WP16 `[U][I][BLOCKING][OPEN-EVOLUTION-CONFIG]` four evolutions**：**GIVEN** 四组合法 level-5 active+passive evolution snapshot，**WHEN** 下一 tick 生效，**THEN** 小庚剑阵、连珠火海、金刚护身阵、双傀儡杀阵逐项产生 R4 的组件图；基础版停止新 cadence，transient 自然收敛，persistent cancel 后再激活 evolved，无新旧双伤害。
- **AC-WP17 `[U][I][BLOCKING][OPEN-SKILL-DRAFT]` evolution isolation**：**GIVEN** level<5、缺/错 passive、仅满足但未选择、合法 token 与 duplicate/conflict token，**WHEN** Weapon 消费 snapshot，**THEN** 仅 SkillDraft 已提交的合法 evolution 激活；duplicate OK_NOOP，conflict fault，Weapon 不自行修改槽位或宝匣资格。
- **AC-WP18 `[U][I][BLOCKING][OPEN-SPAWN-ABI]` typed package**：**GIVEN** 五 typed banks 的合法与逐 header/row 错配，**WHEN** publish package，**THEN** 全部合法时 selector 恰切一次且 token 一致；任一错配整包不发布，Weapon 不取得 projectile borrow。
- **AC-WP19 `[U][I][BLOCKING][OPEN-DAMAGE-ABI]` damage/modifier handoff**：**GIVEN** projectile hit、雷 direct、藤 area、burn/paralysis/slow/shield 与 miss/stale/suppress，**WHEN** plan/confirmed hit 被消费，**THEN** 每个明确 direct effect 恰一 typed Damage intent，projectile hit 不重复提交，只有 confirmed hit 可生成 next-tick modifier；crit/mitigation/HP 写入为 0。
- **AC-WP20 `[U][I][BLOCKING][OPEN-DEFENSE-ABI]` shield source**：**GIVEN** 金刚护身阵 refresh、partial/full absorption、duplicate/stale consumption receipt，**WHEN** Damage 结算且 Weapon phase-6 capability提交，**THEN** shield source snapshot与 consumption exact-once 对账；Weapon 不直接减少 HP。ABI 未冻结前此集成保持 BLOCKED。
- **AC-WP21 `[U][I][BLOCKING][OPEN-CAPACITY]` F7 exact maxima**：**GIVEN** 独立合法 loadout 枚举 oracle，**WHEN** 计算 `W_P/W_D/W_A/W_M/W_C/W_PLAN`，**THEN** Config逐项相等；required-1 拒绝、required 成功、required+1 runtime写入 fault，禁止截断/resize/技能优先级丢弃。
- **AC-WP22 `[U][I][BLOCKING]` global spawn sum**：**GIVEN** Weapon+Enemy+Boss projectile contributions 合计 31/32/33，**WHEN** Config build，**THEN** 31/32 可 admit，33 拒绝；16 spare 不计 gameplay quota。
- **AC-WP23 `[U][I][BLOCKING]` F8 Damage workload**：**GIVEN** 每个合法 form 的 pierce/hit/pulse upper bound，**WHEN** 独立枚举 `W_HIT/W_DAMAGE`，**THEN** production manifest等于精确 max且不超过 schema硬界121200/121806；不得直接用硬界冒充推荐容量。
- **AC-WP24 `[U][I][BLOCKING]` atomic fault**：**GIVEN** query、RNG、spawn reservation、Damage writer和第N row fault，**WHEN** 多技能同 tick ready，**THEN** 整个未发布 plan selector、cooldown、cast sequence、RNG重试与下游 rows均不部分提交，旧 plan 保持有效。
- **AC-WP25 `[U][I][BLOCKING]` pause/replay/teardown**：**GIVEN** pause 在 due/query/publish/evolution 边界、逻辑输入排列变化及旧局 token重放，**WHEN** pause-resume/teardown/new battle，**THEN** paused所有推进0、resume无补射；同 seed/input/build 的 targets/plan/RNG calls逐值相同，旧 token 不污染新局。
- **AC-WP26 `[P][BLOCKING-TOOLING][INCONCLUSIVE-WITHOUT-GUARD]` zero allocation**：**GIVEN** production roots、非空实现门、known-good/bad fixtures与native allowlist，**WHEN** static/runtime guard执行，**THEN** 热路径 Array/Dictionary/PackedArray构造或增长、range、Callable、closure、signal boxing、runtime String/StringName、unstable sort、Node/Resource/Timer/Tween创建均0；缺任一 positive control 只能 INCONCLUSIVE。
- **AC-WP27 `[P][I][E][OPEN-EVIDENCE]` full-load/experience**：**GIVEN** 最低规格 Android、Godot 4.7.1 release、60Hz、303 enemies、400 active attacks、32 pending、4 equipped且覆盖进化构筑，**WHEN** 预热后10000 ticks×3并完成预登记试玩，**THEN** allocator/growth/COW/gameplay overflow=0并报告phase p50/p95/p99/max、cast/query/candidate/row/RNG counters；三种构筑各有清杂/Boss/生存短板且目标行为可理解。缺设备、raw samples、预算、assets或试玩记录时保持 OPEN。

## Open Questions

| ID | Status | Required closure | Owner |
|---|---|---|---|
| OQ-W01 | `BLOCKED-CAPABILITY-PROPAGATION` | GameRoot/Projectile 接纳 QUERY/QUERY_CONSUME capability、lease、success/fault boundary | Architecture + Projectile |
| OQ-W02 | `BLOCKED-SPAWN-ABI` | 冻结 ProjectileSpawn/Cancel rows、T+1 receipt 与各 producer 容量 | Weapon + Projectile + Boss/Enemy |
| OQ-W03 | `BLOCKED-DAMAGE-ABI` | 冻结 direct/area/on-hit effect ref、source order 与 contribution capacities | Weapon + Damage |
| OQ-W04 | `BLOCKED-MODIFIER-ABI` | 冻结 burn/slow/paralysis enum、stack order、duration与 hit-confirm transition | Damage + Enemy + Config |
| OQ-W05 | `BLOCKED-DEFENSE-ABI` | 冻结多来源 shield resource snapshot/consumption capability | Damage + Weapon + Player/Risk |
| OQ-W06 | `PARTIAL-SKILL-SNAPSHOT` | SkillDraft 已冻结loadout A/B语义、choice token、next-tick与replay；仍需双方逐字段接纳并闭合GameRoot paused commit | SkillDraft + Weapon + GameRoot |
| OQ-W07 | `OPEN-BALANCE` | 冻结六技能 L1..L5 与四进化 exact Config rows；当前只冻结成长轴 | Game Design + Config |
| OQ-W08 | `BLOCKED-CAPACITY` | 用最终 SkillConfig 求 `W_P/W_D/W_A/W_M/W_C/W_HIT` 并汇总各 producer | Config + QA |
| OQ-W09 | `BLOCKED-LEI-DISCARD-ABI` | RNG 冻结不依赖非法 range 的 exact-one-word discard capability | RNG + Weapon |
| OQ-W10 | `OPEN-PERF` | 在 min-spec 验证 densest 91,809 checks与 summon query fanout | Performance + QA |
| OQ-W11 | `BLOCKED-SPATIAL-CONFIG` | 由最终技能表回填 target/effect/projectile radius maxima | Weapon + SpatialGrid + Config |
| OQ-W12 | `PARTIAL-PRESENTATION` | BattleUI/Audio已冻结HUD、voice/priority与语义owner待办；六family最终silhouette/streams、Weapon-vs-Projectile cast row、VFX池与真机阈值仍BLOCKED | Art + Audio + BattleUI |
| OQ-W13 | `RE-REVIEW-PENDING` | clean-context full review；作者设计不得视作独立批准或 runtime evidence | Review owner |
