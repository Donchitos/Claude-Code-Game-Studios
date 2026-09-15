# DamageSystem

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：STEAM_MISSION_V1/STEAM_SAVE_V2的目标、终态与完整恢复要求见mission-objectives.md、save-steam-pc.md及ADR-0006。本owner的目标身份/生命周期（适用时）、matching-tick snapshot、schema/validator/migration、required-owner与容量贡献待正式冻结并接线；下方legacy合同不因本路由而自动满足新profile，缺失时禁止生产启用。

> **Status**: In Review / Re-review Pending
> **Author**: User + Codex
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 移动躲避 + 自动御剑 + 功法进化的战斗爽快度；险境翻盘
> **Review Mode**: lean

## Overview

DamageSystem 是战斗阶段中唯一的确定性数值结算域：它接收 Weapon、Projectile、Enemy、Boss、掉落物与风险选择产生的类型化伤害、恢复和 Buff 意图，按固定顺序完成命中归并、暴击、增减伤、恢复及危险区域预测，并在 phase 5 发布只读结算结果。PlayerController 与 EnemySystem 分别保留自身 HP、生命状态和实体生命周期权威，只在 phase 6 应用与当前 battle、tick、authority revision 完全匹配的结果。该系统让玩家感受到飞剑成长后的明确杀伤、危险攻击的公平反馈和低血量翻盘，同时保证同一 seed 与输入得到相同结果；表现层溢出可以降级，但任何 gameplay 结算错误都必须 fail closed，不能静默少算、多算或重复结算。

## Player Fantasy

玩家应感到自己的构筑正在真实改变战场，而不是只看到数字变大：飞剑增加、技能进化或 Buff 成型后，同一类敌人应更快倒下，怪潮中能形成清晰的破局时刻。

玩家受到伤害时，应能理解“伤害从哪里来、为什么命中、实际损失多少”，并相信闪避预警有效；低血量恢复、护盾减伤和替身符触发应形成“提前留有后手，因此逃过一劫”的韩立式生存体验，而不是系统暗中宽容。

DamageSystem 本身应尽量不可见。玩家直接感知的是三件事：攻击有分量、危险可判断、构筑差异可解释。相同战斗输入必须产生相同结算，伤害统计必须能追溯到具体技能和来源，让玩家能够复盘自己的选择。

## Detailed Design

### Core Rules

#### R1 — 权威边界与阶段

- DamageSystem 是伤害、恢复、Buff 修正、伤害归因和复活危险快照的唯一结算 owner，但不直接写入 Player/Enemy HP、生命状态或实体生命周期。
- required participant row 固定为 `DAMAGE`、`stable_order=6`，参与 `QUERY`、`QUERY_CONSUME` 和 `DEFERRED_REMOVAL`。
- `QUERY` 只展开范围目标并写入预分配候选区；`QUERY_CONSUME` 完成结算并发布 resolution；`DEFERRED_REMOVAL` 只消费 HP owner 返回的实际应用结果、累计统计，不重新计算伤害。
- DamageSystem 不定义独立 `_process/_physics_process`，只接受 GameRoot 的 typed phase context。
- Paused、Loading、teardown 或错误 phase 不推进持续伤害、恢复计时、Buff 时长和 hazard 时间窗。

`DAMAGE_PHASE_ROW_V1={participant_id=DAMAGE,role_id=DAMAGE,stable_order=6,allowed_phases={QUERY,QUERY_CONSUME,DEFERRED_REMOVAL},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=DamageSystem/v1,owner_gdd_path=design/gdd/damage-system.md,phase_row_id=DAMAGE_PHASE_ROW_V1,required=true}`。

#### R2 — 类型化输入

所有来源只能提交以下预分配 intent，不得直接写 HP：

- `DamageIntentV1`：一次明确的单目标命中，包含 battle/config/tick/source identity、目标 identity、skill ID、基础伤害、伤害类型、暴击资格和稳定 intent sequence。
- `AreaDamageIntentV1`：圆形范围攻击，包含中心、半径、来源、技能、基础伤害和命中规则；DamageSystem 在 `QUERY` 使用 `ENEMY` mask 展开成单目标 intent。
- `RecoveryIntentV1`：玩家恢复，数值类型限定为 `FLAT` 或 `MAX_HP_RATIO`，并携带 recovery reason/source mask。
- `BuffModifierIntentV1`：只描述下一 tick 起生效或失效的 modifier；当前 tick 结算只读取已发布 snapshot。
- `ReviveHazardIntentV2`：明确声明下一 tick 仍会伤害玩家的危险区域，包含稳定 hazard ID、shape code、圆心/半径语义和 active tick 窗口；封闭enum至少支持危险圆`CIRCLE`与圆外危险`EXTERIOR_CIRCLE`。

每个 intent 必须携带完整 battle、config、tick、source authority、instance/borrow identity；缺字段、过期引用、非有限数值或非法枚举均在写入 staging 前拒绝。

#### R3 — 候选展开与稳定顺序

- 单体命中由 Weapon、Projectile、Enemy 或 Boss 提供目标 identity。
- 圆形范围伤害由 DamageSystem 调用 SpatialGrid 的 caller-owned `ENEMY` 查询，再用目标真实 bound 做窄相；不得全场遍历。
- 玩家受击不得查询不存在的 `PLAYER` Grid mask，必须使用 matching `PlayerMotionCommitCarrierV1` 与攻击 shape 做直接窄相。
- 所有合法单目标 intent 按 `target_kind ASC → target_id ASC → target_borrow_id ASC → source_role_order ASC → source_id ASC → skill_id ASC → intent_sequence ASC` 稳定排序。
- 不允许使用 Node 遍历顺序、Dictionary 顺序、signal 到达顺序或 native unstable sort 决定结算顺序。
- 同一 intent identity 重复提交只保留第一条；payload 不同但 identity 相同属于 contract fault，不允许覆盖。

#### R4 — Buff 快照与生效边界

- DamageSystem 在每 tick 开始时只读取 matching、只读的 `CombatModifierSnapshotV1`。
- Buff 新增、刷新、层数变化或移除统一写入 inactive bank，最早从下一 tick 生效；当前批次禁止半途改变公式。
- MVP modifier 分为：攻击增幅、技能倍率修正、暴击率、暴击倍率、范围增伤、伤害减免、护盾吸收、恢复增幅、击退强度和抗击退。
- 同一 modifier 必须有稳定 `modifier_id/source_id/stack_group`；重复 ID 不叠加，冲突 payload 触发 fault。
- Buff 只影响其显式声明的 damage type、skill tag、source 或 target；禁止默认作用于全部伤害。
- DamageSystem 不拥有 Buff 持续时间的玩法来源，但拥有 modifier 合法性校验、固定叠加顺序和结算快照。
- RiskChoice 的 `RISK_WARD` 是已冻结特例：`modifier_kind=TARGET_DAMAGE_MULTIPLIER,value=0.80,duration_gameplay_ticks=600,combine_rule=REPLACE_MIN_MULTIPLIER`。它不是shield余额；在existing mitigation后、shield absorption前应用。重复同identity不刷新，同组不相加，Paused不推进窗口；来源拥有窗口，Damage拥有matching snapshot合法性与结算。

#### R5 — 暴击与伤害结算

- 每条 `crit_eligible=true` 的单目标 intent 按 canonical 顺序精确消费一次 RNG `CRIT` roll；不可暴击 intent 消费零次。
- 范围攻击对每个目标独立判定暴击，避免整屏攻击全部暴击或全部不暴击。
- 持续伤害、环境伤害、自爆和 Boss 场地伤害默认不可暴击；只有 Config 明确开启才可暴击。
- 固定结算顺序为 `base damage → skill/attack modifiers → generic increase → crit → target mitigation → RISK_WARD target multiplier → shield absorption → non-negative validation`；无ward时该步identity=1.0。
- 同一目标同一 tick 最终发布一条 resolution；该 resolution 可引用多条有序 contribution，以保留技能和来源归因。
- 伤害结果不做显示取整，不设置隐藏最小伤害；正伤害若经 float64 运算后逐 bit 无法改变结果，视为数值合同错误。
- DamageSystem 产生最终结算值和来源归因；HP owner 负责按当前 HP 截断 overkill。

#### R6 — Player 伤害与恢复发布

- Player 每 tick 最多发布一条 `PlayerDamageResolutionV1` 和一条 `PlayerRecoveryResolutionV1`；无结果以 `has_resolution=false,row_count=0` 表示，不允许发布零值假行。
- 两类结果分别使用 Loading 期预分配的 A/B bank、独立 selector 和完整 publish token。
- Damage resolution 必须逐字段兼容 PlayerController 已冻结的 schema，不另造第二个 resolution identity。
- Player 在 phase 6 固定执行 `damage → lethal 判定 → 非致命时 recovery → HP/HUD 单次发布`。
- 致命批次抑制同 tick 恢复且不结转；非致命时恢复不超过 `max_hp`。
- 多个恢复 intent 按 `reason_priority → source_id → intent_sequence` 稳定聚合为一条 recovery resolution。
- RiskChoice 在 Paused 中只能冻结恢复 intent，最早在恢复后的第一个 Active tick 结算。

#### R7 — Enemy 伤害发布与实际归因

- 每个受到命中的 active Enemy 每 tick 最多一条 `EnemyDamageResolutionV1`，容量上限为 303 个目标。
- resolution 包含 aggregate damage、ordered contribution span、knockback result、primary reason 和 source attribution。
- EnemySystem 在 phase 6 按 contribution 顺序应用伤害，截断 overkill，最多产生一次死亡和一次 release 计划。
- EnemySystem 将实际应用量写入预分配 receipt；DamageSystem 随后累计 skill/source damage totals。
- 已死亡、旧 borrow、已进入 release 的敌人不接收后续 contribution；这些 contribution 记为 suppressed，不转移到其他目标。
- DamageSystem 不创建或释放敌人，也不重复提交 Enemy 已提交的 DAMAGE/DEATH fact。

#### R8 — 恢复、护盾与击退

- 护盾是伤害结算中的吸收层，不是额外 HP；吸收量不能超过当前已发布护盾值。
- 护盾消耗结果随 resolution 返回，由对应 HP/Buff owner 在 phase 6 exact-once 应用。
- 恢复只作用于仍存活的 Player；MVP 不支持敌人治疗。
- 击退只输出有限 `KnockbackResolutionV1`，由 EnemySystem 在下一 tick movement commit 应用；DamageSystem 不直接改位置。
- 抗击退只缩放击退量，不影响实际伤害。
- Boss 可通过明确 modifier 获得阶段性减伤或抗击退，但不得使用未公开的伤害免疫。

#### R9 — 复活危险快照

- Projectile、Boss、Enemy 场地攻击和持续伤害区必须为下一 tick 仍有效的危险提交 `ReviveHazardIntentV2`。Projectile swept危险为`CIRCLE`；Boss毒域为`EXTERIOR_CIRCLE`。
- DamageSystem 按 `hazard_id ASC` 去重并发布唯一 `ReviveHazardSnapshotV2` A/B bank。snapshot精确采用PlayerController版本化后的parallel-array schema并增加`shape_codes`；hazard不可被替身符清除。
- `revive_hazard_capacity`必须等于所有producer最坏workload checked sum。Projectile=400、Boss nonprojectile=2已知，总式为`400+EnemyNonProjectile_H+2+Stage_H`；后两项未冻结前保持`BLOCKED-CAPACITY`，不得暂填402、303或任意默认值。
- 缺失、过期或容量不足的 hazard 快照使复活集成 fail closed，不能把未知危险当作安全。

#### R10 — 确定性、容量与故障

- 所有 staging、query、resolution、receipt、modifier 和 hazard bank 均在 Loading 精确定容；Active 不扩容。
- producer 必须各自登记 intent/hazard contribution，Config 只校验 checked sum，不替 owner 猜容量。
- 任一 gameplay bank 溢出、RNG fault、identity mismatch、非法数值或依赖失败，当前 resolution 不发布并进入统一 ControlledGameplayFault。
- `damage_number` 属于 PRESENTATION：容量 96 用尽时返回 `OVERFLOW_DROPPED`、记录 telemetry，gameplay resolution 保持有效。
- 相同 seed、Config、已发布 authority 和有序 intent 必须逐 bit 产生相同 resolution 与 RNG 调用次数。

#### R11 — 统计与表现边界

- DamageSystem 累计实际应用后的技能伤害、来源伤害、受到伤害来源和死亡原因，供 Settlement/Outcome 使用。
- 统计只读取 committed receipt/fact，不使用理论伤害或 overkill。
- DamageSystem 发布 typed presentation intent，但不直接创建伤害数字、播放动画、音效或震动。
- 同目标短时间内的伤害数字可由 BattleUI 合并；合并只改变显示，不改变 hit、暴击、统计或 HP。
- `VICTORY + lethal` 时保留 runtime DAMAGE/DEATH 事实供统计，但必须遵守 GameRoot 已冻结的 `presentation_winner=VICTORY`，抑制死亡表现。

### States and Transitions

DamageSystem 不复制 GameRoot 顶层 FSM，只维护局部事务状态：

| 状态 | 含义 | 合法下一状态 |
|---|---|---|
| `UNBOUND` | 尚未绑定 battle/config 与预分配 backing | `READY`, `TORN_DOWN` |
| `READY` | 等待当前 tick 的合法 phase context | `QUERY_STAGED`, `FAULTED`, `TORN_DOWN` |
| `QUERY_STAGED` | 当前 tick 候选、intent 与 modifier snapshot 已冻结 | `RESOLUTION_PUBLISHED`, `FAULTED` |
| `RESOLUTION_PUBLISHED` | matching damage/recovery/hazard bank 已发布，等待 phase 6 receipt | `READY`, `FAULTED`, `TORN_DOWN` |
| `FAULTED` | 首次故障已锁存，不接受新 gameplay intent | `TORN_DOWN` |
| `TORN_DOWN` | 所有 view 已失效、generation 已推进 | 无 |

- `READY → QUERY_STAGED` 只允许 matching `QUERY` 成功结束。
- `QUERY_STAGED → RESOLUTION_PUBLISHED` 只允许 matching `QUERY_CONSUME` 完整成功并切换 selector。
- `RESOLUTION_PUBLISHED → READY` 只允许 phase 6 receipts/统计消费完成或明确为零。
- Paused 不创建本地暂停状态；GameRoot 不调用 gameplay phase，DamageSystem 的局部状态和 bank 保持不变。
- 任一非法跳转都在写入前失败，不通过重置为 `READY` 掩盖错误。

### Interactions with Other Systems

| 系统 | 输入 DamageSystem | DamageSystem 输出 | 权威边界 |
|---|---|---|---|
| GameRoot | phase context、lease、resolution token、authority snapshot | status、published bank、fault latch | GameRoot 调度；Damage 只结算 |
| Config/Data | 技能、modifier、伤害类型、容量与 manifest | schema/readiness 校验结果 | Config 冻结值，Damage 不热改 |
| RNG | `CRIT` stream | 固定顺序 roll 消费 | RNG 产随机数，Damage 定消费规则 |
| SpatialGrid | `ENEMY` query API | caller-owned query buffer | Grid 找候选，Damage 做窄相 |
| PlayerController | motion/HP/maxHP/护盾只读 view、实际应用 receipt | damage/recovery/hazard resolution | Player 独占 HP、死亡、复活 |
| EnemySystem | identity、bound、defence/modifier、actual receipt | enemy damage/knockback resolution | Enemy 独占 HP、死亡与 release |
| Elite Enemies | charge/needle intent、WEAKENED target modifier、producer maxima | Player/Elite resolution与hazard join | Elite定行为；Damage唯一应用数值 |
| ProjectileSystem | 单体或区域 damage intent、hazard contribution | 命中 disposition | Projectile 独占飞行与碰撞生命周期 |
| WeaponSystem | 技能/source intent | resolution/统计归因 | Weapon 决定攻击节奏，Damage 决定数值 |
| SkillDraftSystem | 已生效技能等级与 modifier | 无直接回写 | Draft 改构筑，下一 tick snapshot 生效 |
| Zhangtian Bottle | matching `DamagePreparationInputV1` | 无回写 | 只把明心丹+0.08 points并入本局immutable crit snapshot；不读profile/UI |
| Drop/Leveling | 回春符等 recovery intent | recovery disposition | Drop 决定拾取，Damage 结算恢复 |
| BossStateMachine | Boss direct上界2、nonprojectile hazard上界2、cone/exterior-circle shape与lethal projection input | Boss/Player resolution | Boss决定行为，Damage结算；Designed / Full Review Pending |
| BattleUI | 无 gameplay 输入 | presentation intent、统计只读 view | UI 不得反写结算 |
| Settlement | 无 runtime 输入 | committed skill/source totals、death cause | Settlement 只读最终统计 |

当前 provisional 边界：

`DamagePreparationInputV1={schema_version:i32=1,battle_instance_id:i64,reservation_id:i64,source_profile_revision:i64,source_domain_revision:i64,config_content_revision:i64,projection_hash:Hash256,pill_id:i32,crit_bonus_points:f64,valid:i32}`。只有`pill_id=NONE,bonus=0`或`pill_id=CLEAR_MIND_PILL,bonus=0.08`合法；其他pill必须bonus=0。Loading逐字段匹配Zhangtian projection并一次性复制到Damage immutable snapshot，Active/Pause/Resume只读；stale、hash/revision/identity错配、NaN/Infinity、重复bind或热改均在consumer开放前fault。

- Boss 与 BattleUI 已有作者GDD但均未独立full review；Projectile、Weapon、SkillDraft、Drop/Leveling同样仍有部分ABI按各自Open Question保持BLOCKED。BattleUI明确不在通用shield owner/view未冻结时自造盾条。
- Drop回春已冻结为next-Active-tick `RecoveryIntentV1{type=MAX_HP_RATIO,value=0.30,reason=DROP_RECOVERY}`；爆炎的Normal全场处决、Elite `max_hp×blast_elite_ratio`与Boss免疫仍为`BLOCKED-BLAST-ABI`，Damage/Enemy/Config不得在实现中自创接口或比率。
- `revive_hazard_capacity`在Projectile=400与Boss=2后仍等待Enemy nonprojectile和Stage producer；V2 shape集成与总量冻结前保持`BLOCKED-CAPACITY`。
- Elite作者合同已冻结：蜈蚣每segment对Player最多1条direct intent、鬼修每次三魂针且Enemy Projectile pending上界9；WEAKENED提交`TARGET_DAMAGE_TAKEN_MULTIPLIER=1.25`（PROVISIONAL-BALANCE），只在150 Active ticks窗口进入target mitigation step且在RISK_WARD前恰应用一次。全producer checked sum与hazard总量仍BLOCKED。
- 本节是作者上下文中的 lean 设计，不代表独立 review、实现可行性或运行时验证。

## Formulas

所有玩法标量和中间量均以 float64 按下列步骤顺序计算。每步赋值后立即检查 finite；禁止重排运算、FMA、显示取整或隐藏最小伤害。`-0.0` 在发布前规范化为 `+0.0`。

### F1 — Normal Attack Damage

The `damage_normal_attack` formula is defined as:

```text
step_attack = attack * skill_multiplier
step_level = step_attack * skill_level_modifier
normal_damage = step_level * generic_damage_multiplier
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Attack | `A` | float64 | finite, `>=0` | 攻击者已发布攻击；MVP 玩家基线 10 |
| Skill multiplier | `Ms` | float64 | finite, `>=0` | 技能基础倍率 |
| Skill-level modifier | `Ml` | float64 | finite, `>=0` | 技能等级修正 |
| Generic multiplier | `Mg` | float64 | finite, `>=0` | 已解析通用增伤；无修正时 1.0 |

**Output Range:** `normal_damage>=0` 且 finite；生产上限由 Config 冻结。

**Example:** `10 * 1.0 * 1.0 * 1.0 = 10`。这是 identity fixture，不是新平衡值。

### F2 — Critical Hit

The `damage_critical_hit` formula is defined as:

```text
if !crit_eligible:
    crit = false
    crit_damage = normal_damage
else:
    u = RNG.roll_float_range(CRIT, 0.0, 1.0)
    crit = u < crit_chance
    crit_damage = crit ? normal_damage * crit_multiplier : normal_damage
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Eligibility | `E` | bool | true/false | 该命中是否可暴击 |
| Roll | `u` | float64 | `[0,1)` | `CRIT` 子流精确一次 roll |
| Crit chance | `C` | float64 | `[0,1]` | MVP 基线 0.05 |
| Crit multiplier | `Mc` | float64 | finite, `>=1` | MVP 基线 1.5 |
| Normal damage | `N` | float64 | finite, `>=0` | F1 输出 |

**Output Range:** `crit_damage>=0` 且 finite；不可暴击时 roll 次数为 0。

**Example:** `N=10,C=.05,Mc=1.5`；`u=.049` 输出 15，`u=.05` 输出 10。

RNG 返回后必须先检查 `has_fault()`。跨架构逐 bit 证据受 RNG GATE-G4/OQ3 约束，当前标记 `OPEN-RNG-EVIDENCE`。

### F3 — Target Mitigation

The `damage_target_mitigation` formula is defined as:

```text
mitigation_factor = 1.0 - damage_reduction_ratio
damage_after_existing_mitigation = crit_damage * mitigation_factor
mitigated_damage = damage_after_existing_mitigation * risk_ward_multiplier
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Reduction ratio | `R` | float64 | `[0,1]` | matching modifier snapshot 已解析减伤；Player 基线 0 |
| Crit-stage damage | `Dcrit` | float64 | finite, `>=0` | F2 输出 |
| Risk ward multiplier | `Mw` | float64 | `{0.80,1.0}` | matching RISK_WARD有效时0.80，否则1.0 |

**Output Range:** `mitigated_damage` 在 `[0,Dcrit]` 且 finite。

**Example:** `Dcrit=15,R=.05,Mw=1` 得14.25；matching ward时再得11.4。

禁止对非法 ratio 做 runtime clamp；通用多个减伤的 stack-group 解析规则仍属 `PROVISIONAL-CONFIG-TUNING`，但`RISK_WARD`的0.80、窗口与不叠加规则已由RiskChoiceSystem冻结。

### F4 — Shield Absorption

The `damage_shield_absorption` formula is defined as:

```text
absorbed_i = min(mitigated_damage_i, shield_remaining_before_i)
shield_remaining_after_i = shield_remaining_before_i - absorbed_i
hp_damage_i = mitigated_damage_i - absorbed_i
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Mitigated contribution | `Di` | float64 | finite, `>=0` | F3 输出 |
| Shield before | `Si` | float64 | finite, `>=0` | tick 起点护盾余额 |

**Output Range:** `absorbed_i in [0,Di]`、`shield_after in [0,Si]`、`hp_damage_i in [0,Di]`。

**Example:** `Di=14.25,Si=4` 得 `absorbed=4,shield_after=0,hp_damage=10.25`。

护盾 owner、上限与叠层规则属 `BLOCKED-DOWNSTREAM-GDD/PROVISIONAL-CONFIG-TUNING`；DamageSystem 只发布消耗结果。

### F5 — Recovery Resolution

The `damage_recovery_resolution` formula is defined as:

```text
raw_recovery_i = kind == FLAT ? flat_amount : max_hp_at_source_revision * max_hp_ratio
modified_recovery_i = raw_recovery_i * recovery_multiplier
final_recovery = ordered_sum(modified_recovery_i)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Flat amount | `Rf` | float64 | finite, `>=0` | FLAT intent 的恢复量 |
| Maximum HP | `Hmax` | float64 | `[1,1000000]` | source authority revision 下的 Player max HP |
| HP ratio | `Rhp` | float64 | `[0,1]` | MAX_HP_RATIO intent |
| Recovery multiplier | `Mr` | float64 | finite, `>=0` | matching modifier snapshot 恢复倍率 |

**Output Range:** `final_recovery>=0` 且 finite；DamageSystem 不按 HP room clamp。

**Example:** 回春符 `Hmax=100,Rhp=.30,Mr=1` 输出 30。

逐条按 `reason_priority → source_id → intent_sequence` 做 float64 加法并每步 finite 检查。Player 应用时直接引用 registry 已有 `player_recovery_application`，不重复登记同义公式。

### F6 — Knockback Resolution

The `damage_knockback_resolution` formula is defined as:

```text
scaled_knockback = base_knockback * knockback_multiplier
resisted_knockback = scaled_knockback * (1.0 - knockback_resistance)
uncapped_vector = knockback_direction * resisted_knockback
knockback_vector = clamp_magnitude(uncapped_vector, knockback_max)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Direction | `V` | Vector2 | ZERO 或 finite 单位向量 | 命中 producer 显式提供 |
| Base knockback | `Kb` | float64 | finite, `>=0` | 技能基础击退 |
| Knockback multiplier | `Mk` | float64 | finite, `>=0` | 攻击方修正 |
| Resistance | `Kr` | float64 | `[0,1]` | 目标抗击退 |
| Maximum knockback | `Kmax` | float64 | finite, `>=0` | Config 生产上限 |

**Output Range:** real_t32 readback 后向量 finite 且模长 `<=Kmax`。

**Example:** `Kb=2,Mk=1,Kr=.85,Kmax>=.3` 得模长 .3。

`knockback_max` 当前为 `BLOCKED-CAPACITY/PROVISIONAL-CONFIG-TUNING`；禁止从零长度 source-target 差值现场猜方向。

### F7 — Per-target Tick Aggregation

The `damage_tick_aggregation` formula is defined as:

```text
aggregate_hp_damage_0 = 0.0
aggregate_absorbed_0 = 0.0
for i in canonical contributions:
    aggregate_hp_damage_i = aggregate_hp_damage_(i-1) + hp_damage_i
    aggregate_absorbed_i = aggregate_absorbed_(i-1) + absorbed_i
final_damage = aggregate_hp_damage_n
shield_consumed = aggregate_absorbed_n
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Contribution count | `n` | int32 | `[0,contribution_capacity]` | 目标的有序 contribution 数 |
| HP contribution | `Dhpi` | float64 | finite, `>=0` | F4 的 HP 伤害 |
| Absorbed contribution | `Dshi` | float64 | finite, `>=0` | F4 的护盾吸收 |

**Output Range:** `final_damage>=0`、`shield_consumed>=0` 且 finite；`n=0` 时无 resolution row。

**Example:** canonical HP contributions `[6,4.25]` 得 `final_damage=10.25`。

精确 intent/contribution 总容量由 Weapon/Projectile/Boss producer checked sum 决定，当前标记 `BLOCKED-CAPACITY`。

### F8 — Actual Attribution and Overkill

The `damage_actual_attribution` formula is defined as:

```text
remaining_0 = applied_damage
for i in canonical contributions:
    actual_i = min(hp_damage_i, remaining_(i-1))
    remaining_i = remaining_(i-1) - actual_i
    suppressed_overkill_i = hp_damage_i - actual_i
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Applied damage | `Da` | float64 | `[0,final_damage]` | HP owner matching committed receipt |
| Contribution damage | `Di` | float64 | finite, `>=0` | canonical contribution |

**Output Range:** `actual_i in [0,Di]`、`suppressed_overkill_i>=0`；结束时 `remaining_n` 必须逐 bit 为 `+0.0`。

**Example:** 当前 HP=10，contributions=`[6,8]`，则 `final=14,applied=10,actual=[6,4],overkill=[0,4]`；第二条是 lethal contribution/death source。

Player HP 截断直接引用 registry 已有 `hp_application`。理论伤害、护盾吸收和 overkill 不进入“实际伤害”统计。

## Edge Cases

- **If a valid intent resolves to exactly zero damage**: retain no DAMAGE fact and do not create a zero-value resolution row unless a nonzero shield/knockback result must be applied; crit and attribution counters remain unchanged except diagnostic attempted-hit telemetry.
- **If `crit_chance=0` or `1`**: an eligible hit still consumes exactly one CRIT roll; strict `u<C` makes the results always false or always true respectively.
- **If an ineligible hit carries crit values**: ignore neither silently nor partially; reject the intent as `CARRIER_INVALID` because eligibility is part of its schema.
- **If shield equals incoming mitigated damage**: HP damage is exactly `+0.0`, shield becomes exactly `+0.0`, only shield-consumed presentation may fire.
- **If shield is smaller than damage**: publish both the exact shield consumption and remaining HP damage; UI must not portray the hit as fully blocked.
- **If damage and recovery target Player in the same tick**: apply damage first; lethal suppresses recovery without carry-over, otherwise recovery clamps at max HP.
- **If multiple contributions jointly become lethal**: canonical prefix attribution selects the contribution that first exhausts remaining HP as death source; later contributions are overkill and do not change death cause.
- **If a target died or changed borrow identity after QUERY but before apply**: reject that target row as stale, do not retarget or transfer its damage, and follow the batch fault/convergence contract if any irreversible work already committed.
- **If the source is released after its valid hit intent was frozen**: the immutable intent may still resolve when its source identity matched at freeze time; no Node reference is dereferenced later.
- **If the same intent identity appears twice with identical payload**: accept the first and mark the later row duplicate/no-effect; different payload under the same identity is a fault.
- **If a SpatialGrid area query returns `BUFFER_TOO_SMALL` or another failure**: publish no partial area result and do not consume CRIT rolls for that area.
- **If an area touches a target boundary exactly**: count it as a hit using the documented closed-circle narrow-phase predicate; radius zero is legal and only hits a target whose footprint contains the exact point.
- **If intent, contribution, resolution, receipt or hazard capacity is exceeded**: fail before selector publish; never truncate, resize, allocate, sample a subset or prefer visually important targets.
- **If RNG faults after earlier CRIT rolls in the same batch**: discard the unpublished resolution, latch the battle fault and never retry that tick; prior RNG state is diagnostic evidence, not a reason to re-roll.
- **If any arithmetic intermediate becomes NaN or Infinity**: fail before publish and preserve the prior published banks and HP authority.
- **If a positive final damage cannot change the target's finite HP due to float64 precision**: HP owner rejects the resolution; DamageSystem must not inject a hidden minimum point of damage.
- **If knockback resistance is 1**: publish zero knockback; damage still resolves normally. A zero direction is valid only when the requested knockback is also zero.
- **If a Buff is added and removed in the same tick**: resolve the next snapshot by stable modifier transition order; the current tick continues using its already-published snapshot.
- **If RISK_WARD starts while Paused**: only freeze its typed intent; its `[effective_tick,effective_tick+600)` window begins at the first matching Active snapshot, Paused callbacks never decrement it.
- **If two hazard rows share `hazard_id`**: identical payload deduplicates; conflicting payload faults. A hazard is included only when its closed active window contains the next gameplay tick.
- **If no valid hazard is active next tick**: publish a valid snapshot with `count=0`; absence of hazards is distinct from an invalid or missing view.
- **If Paused begins after resolution publish but before application**: GameRoot finishes or safely holds the already-started phase boundary according to its pause protocol; DamageSystem never advances timers from pause callbacks.
- **If a phase-6 receipt is missing, duplicated or mismatched**: do not update skill/source totals; duplicate matching receipt is `OK_NOOP`, while missing/mismatched required receipt faults before the next tick.
- **If damage-number pool capacity 96 is full**: return `OVERFLOW_DROPPED` for the new number, increment telemetry and preserve identical gameplay resolution, facts and statistics.
- **If `VICTORY` and lethal Player damage coincide**: preserve committed DAMAGE/DEATH data for statistics but publish only the VICTORY-facing presentation winner; no HIT/DEATH/DEFEAT presentation is emitted.
- **If a distant Normal enemy is retired without reward or an enemy is removed by `REVIVE_CLEAR`**: generate no damage, kill credit, XP, drop, death VFX or kill sound.

## Dependencies

| Dependency | Type | Contract consumed or provided | Current status |
|---|---|---|---|
| GameRoot & Scene Flow | Hard | Seven-phase context, lease, resolution publish token, terminal precollection, fact/receipt ordering | In Review / Re-review Pending |
| Config/Data System | Hard | Immutable damage/modifier schemas, exact capacities, participant and owner manifests | In Review / Re-review Pending |
| RNG System | Hard for crit | `CRIT` stream and fault API | In Review / Re-review Pending; runtime math evidence OPEN |
| SpatialGrid | Hard for area damage | Caller-owned `ENEMY` query and stable identities | In Review / Re-review Pending |
| PlayerController | Hard | HP/maxHP/motion read views; consumes frozen damage/recovery/hazard ABI | In Review / Full Re-review Pending |
| EnemySystem | Hard | Enemy identity/bounds/modifiers, HP application receipts and lifecycle | In Review / Re-review Pending |
| ProjectileSystem | Hard downstream | Single-target/area intent, projectile hazard and contribution capacity | Designed / Full Review Pending；总容量仍 provisional |
| WeaponSystem | Hard downstream | Attack/skill intent, skill/source IDs and modifier inputs | Designed / Full Review Pending；on-hit/modifier/defense ABI仍 BLOCKED |
| SkillDraftSystem | Hard downstream | Skill levels/evolutions and next-tick modifier transitions | Designed / Full Review Pending；modifier revision builder仍BLOCKED |
| DropSystem + Leveling | Hard for recovery loop | Recovery 0.30 ratio intent、blast intent与committed XP consumer边界 | Designed / Full Review Pending；blast ABI仍BLOCKED |
| RiskChoiceSystem | Hard for recovery/ward | Recovery 0.25、RISK_WARD 0.80×600 Active ticks与next-Active publish | Designed / Full Review Pending |
| Elite Enemies | Hard for Elite combat | 三段charge hit-once、三魂针T+1、WEAKENED 1.25/150t与Enemy producer max9 | Designed / Full Review Pending；global capacity仍BLOCKED |
| BossStateMachine | Hard for complete MVP | Boss direct2、projectile8、nonprojectile hazard2、fog exterior shape与lethal projection | Designed / Full Review Pending；global capacities仍BLOCKED |
| BattleUI | Soft for isolated simulation, hard for MVP experience | Presentation intents、HP及尚未冻结owner的shield view、damage statistics | Designed / Full Review Pending；CombatPresentation bank、64/96 merge/drop/ACK仍BLOCKED |
| SettlementSystem | Soft during battle | Reads canonical committed totals and death cause | Deferred combined meta flow |

Required interfaces are versioned, getter-only across ownership boundaries and invalidated before teardown references are released. Every A/B view carries schema version, battle/config identity, bank ID, publish revision, tick revision, source authority revision, generation and validity. Unbound is represented only by `null`, never by an invalid shell object.

Damage owner orchestration contribution is currently `LIFECYCLE_INTENT=0`、`FACT_COMMIT=0`、`PAUSE_CLOSURE=0`、`BLOCKING_CHOICE=0`; Player/Enemy HP owners commit runtime DAMAGE/HEAL/DEATH facts. Damage instead owns the GameRoot-frozen RunOutcome fields `death_cause_code`、`death_source_id`、`skill_damage_count`、`damage_source_count`、`skill_ids[]`、`skill_damage_totals[]`、`damage_source_ids[]` and `source_damage_totals[]`. Exact outcome row capacities remain Config-owned.

Integration remains blocked until Boss/BattleUI presentation producer views与Damage contribution/retention rows精确签发、Drop blast ABI冻结、全部provisional接口双向协调。RiskChoice recovery 0.25、RISK_WARD与owner/outcome rows已在作者合同冻结，Drop recovery 0.30亦已冻结；均尚无独立review与runtime证据。

## Tuning Knobs

| Knob | Baseline / domain | Owner | Extreme behaviour / gate |
|---|---|---|---|
| `player_base_attack` | 10 | Config/Player stats | Frozen MVP baseline; Active hot change forbidden |
| `base_crit_chance` | 0.05 | Config/Player stats | Domain `[0,1]`; 0/1 still consume eligible roll |
| `base_crit_multiplier` | 1.5 | Config/Player stats | Domain `>=1`; production upper bound pending Config |
| `skill_multiplier` | Per skill, `>=0` | Weapon/Skill config | `PROVISIONAL-CONFIG-TUNING` |
| `skill_level_modifier` | Per level, `>=0` | SkillDraft/Skill config | `PROVISIONAL-CONFIG-TUNING` |
| `generic_damage_multiplier` | 1.0 without bonus | Modifier snapshot | Combination and upper bound pending downstream GDD |
| `damage_reduction_ratio` | Player baseline 0; domain `[0,1]` | Modifier snapshot | 1 means explicit full mitigation; hidden immunity forbidden |
| `risk_ward_multiplier/duration` | 0.80 / 600 Active ticks | RiskChoice + Damage | 结构locked，0.80为PROVISIONAL-BALANCE；不等于无敌或shield |
| `elite_weakened_damage_taken/duration` | 1.25 / 150 Active ticks | Elite + Damage | PROVISIONAL-BALANCE；target mitigation内、RISK_WARD前应用一次 |
| `shield_capacity/refresh` | `>=0` | Weapon/Buff config | Owner and stacking contract provisional |
| `recovery_multiplier` | 1.0 without bonus | Modifier snapshot | No HP-room clamp in Damage; Player owns final clamp |
| `knockback_resistance` | `[0,1]`; elite spike anchors .85/.5 | Enemy/Boss config | Existing values remain spike/provisional until owner freeze |
| `knockback_max` | finite `>=0` | Config + Damage/Enemy | `BLOCKED-CAPACITY`; must feed world reachability proof |
| `damage_intent_capacity` | Exact producer checked sum | Config + all producers | `BLOCKED-CAPACITY`; no fallback/default |
| `revive_hazard_capacity` | `400+EnemyNonProjectile_H+2+Stage_H` | Config + Projectile/Enemy/Boss/Stage/Damage | 后两项与V2 schema未闭合，`BLOCKED-CAPACITY` |

**Progression Tree + 掌天瓶 static propagation（2026-09-03）**：Config以`resolved_attack=base_attack*(1+0.03*qingyuan_level)`作为F1唯一Attack输入，不再把同一青元bonus写入`generic_damage_multiplier`；crit chance固定为`base_crit_chance+0.01*dayan_level+(clear_mind_pill?0.08:0)`并继续strict `u<C`，D=5且明心丹时上界0.18，禁止把0.08再写入generic modifier。长春L5由Damage在matching damage batch检测`hp_before>=0.30H && 0<hp_after_damage<0.30H && !lethal`，产出一次`LONGCHUN_EMERGENCY/MAX_HP_RATIO=0.10` resolution；Player phase6实际应用并原子消费charge。青元pierce增加的hit rows、Longchun recovery contribution priority/capacity与phase6 receipt仍BLOCKED，缺失时不得启用perk。
| `damage_number_capacity` | 96 | Config/Object Pooling | PRESENTATION overflow drops new number only |
| `damage_number_merge_window` | TBD | BattleUI | `BLOCKED-UI-TUNING`; display only, never gameplay |
| `hit_audio_concurrency/merge_window` | 22 voice provisional；impact 6 ticks provisional | Audio/BattleUI | Audio GDD已给结构基线，正式event capacity/assets/mix仍BLOCKED |

Cross-owner knobs are referenced rather than duplicated. Any change to the locked 10 attack、5% crit、150% crit damage or pool capacity 96 must first update its owning Config/registry entry and all consumers.

## Visual/Audio Requirements

1. HIT/CRIT/SHIELD/HEAL/KNOCKBACK/DEATH presentation consumes only matching committed resolution、receipt/fact and `batch_authority_revision`; raw intent、query hit、stale/replayed token and unpublished bank produce zero presentation. A stable event key plays at most once.
2. Multiple Player hits in one tick produce one aggregated flash、light haptic and hit cue. Intensity is based on actual HP loss as a max-HP band, not raw hit count; direction/source category remains readable without a long fullscreen flash or sustained camera shake.
3. Enemy hit feedback uses each target's committed per-tick aggregate. Crit adds a non-colour shape/rhythm cue and a short heavier timbre; it must not replay once per contribution. Elite/Boss weight may exceed Normal feedback but never obscure Boss telegraphs.
4. Functional colours remain sword-cyan、fire-red、shield-gold、spirit-purple、wood/heal-green. Friendly attack、hostile attack、shield and heal also differ by silhouette、motion or texture so greyscale and common colour-vision simulations remain readable.
5. Shield feedback triggers only for committed `shield_absorbed>0`. Partial absorption communicates both shield consumption and HP loss; complete absorption emits no HP-damage heavy cue. Shield break triggers exact-once on a committed positive-to-zero transition.
6. Heal feedback triggers only for actual clamped `HEAL>0`; full-HP intent、lethal-suppressed recovery and stale token produce zero feedback. Heal and shield use distinct shape and timbre and never imply invulnerability.
7. Knockback presentation follows EnemySystem's next-tick committed movement, not DamageSystem's theoretical vector. Resistance may show a brief force response but cannot fake displacement.
8. Enemy death presentation consumes committed DEATH only. Independent pooled death VFX stays at frozen `death_position` after the carrier returns to Pool; remote retirement、`REVIVE_CLEAR` and suppressed contributions produce no kill/reward presentation.
9. Normal Player death is DEATH-only; legal revive is REVIVE-only. `VICTORY+lethal` is VICTORY-only even though runtime facts remain for statistics.
10. Damage numbers show actual applied damage, merge by target/time window and identify crit with a non-colour glyph/style. When the capacity-96 pool is full, low-priority new numbers drop without changing HP、death、statistics、VFX or critical audio.
11. Audio is aggregated and rate-limited by committed result. Priority is Boss/lethal warning and Player damage/shield break, then Elite/Boss hit/death, Player crit/heal, then Normal hit/kill. Overflow drops a low-priority new cue and never interrupts a higher-priority cue.
12. At 300 enemies/400 attack objects, Player silhouette、hostile telegraph and drops outrank ordinary hit particles and numbers. World feedback must not continuously cover the joystick region. VFX/audio caps and target-device evidence remain `BLOCKED-PRESENTATION-BUDGET`.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:damage-system`.

## UI Requirements

- Battle HUD reads HP、max HP、shield、life state and matching presentation winner from the published Player frame; it never reconstructs HP from Damage intents.
- Damage numbers display actual applied value after shield/mitigation and may aggregate only presentation rows sharing target、damage class and configured merge window. Crit、shield-only and heal require non-colour distinctions.
- Player damage direction/source cue must remain outside the movement control's touch region and must not steal input focus.
- Low-HP warning is driven by matching committed HP ratio and edge-triggered state, not repeated per damage contribution.
- Pause/detail view may show current damage modifiers and skill totals, but it is read-only and cannot change the active modifier snapshot.
- Settlement must show per-skill actual damage, damage-source totals and death cause. Totals must reconcile with committed receipts and exclude shield absorption、overkill、remote retirement and `REVIVE_CLEAR`.
- Missing/mismatched frame or terminal winner causes the UI consumer to show no new event and withhold ACK; it must not guess from raw HP or intent data.

**📌 UX Flag — DamageSystem**: Battle HUD、damage-number、directional-hit and settlement-stat flows require `/ux-design` before implementation stories reference them.

## Acceptance Criteria

> 本节是验收设计，不是已执行证据。`[U]`=单元，`[I]`=集成，`[E]`=端到端/表现，`[P]`=性能。

- **AC-DM01 `[U][I][BLOCKING]` 权威与 phase 行**：**GIVEN** 带 spy 的 Player/Enemy HP、life、position、Pool 与 Node 及实际 `DAMAGE_PHASE_ROW_V1`，**WHEN** 在三个合法 phase 与所有错误 phase 调用，**THEN** 仅合法 phase 执行对应展开、发布、receipt 消费；Damage 对 HP/life/position/borrow/release 的直接写入为 0，`_process/_physics_process` 与带参 signal 调用为 0，participant row 逐字段等于冻结值。
- **AC-DM02 `[U][I][BLOCKING]` 局部状态机**：**GIVEN** 六个局部状态及所有边，**WHEN** 逐边触发 bind、phase、receipt、fault、teardown，**THEN** 只允许表列迁移；非法迁移在 selector/统计/HP owner/gameplay backing 写入前失败，FAULTED 只能到 TORN_DOWN，teardown 后旧 view 全部 invalid 且 generation 推进。
- **AC-DM03 `[U][BLOCKING][OPEN-ABI]` typed carrier 与 first-error**：**GIVEN** 五类 intent 的合法行及逐字段非法变体，**WHEN** 提交 staging，**THEN** 合法行写入恰一次；非法行在 staging/RNG/query/selector 写入前以冻结 first-error 返回，旧 published bank 不变。五类 row 逐字段 ABI 未冻结的分支保持 OPEN。
- **AC-DM04 `[U][BLOCKING][OPEN-INTENT-IDENTITY]` 去重与 canonical order**：**GIVEN** 同一逻辑 intent 集的多种物理排列、同 identity 同 payload 重复及冲突 payload，**WHEN** 冻结批次，**THEN** 输出严格按 R3 七段 key 一致；相同 payload 仅首行生效，冲突 payload 在 publish 前 fault，Node/Dictionary/signal/native-sort 顺序不影响结果。
- **AC-DM05 `[U][I][BLOCKING]` 单体、范围与玩家窄相**：**GIVEN** 单体目标、圆形 AoE 内/边界/外、radius=0、303 个 Enemy 及 Player motion carrier，**WHEN** QUERY 展开，**THEN** AoE 只调用 caller-owned `ENEMY` query 并以 closed-circle 真实 bound 窄相；玩家受击只读 matching motion carrier，`PLAYER`/combined Grid mask、全场 Node 遍历与 Camera/transform 读取均为 0。
- **AC-DM06 `[U][I][BLOCKING]` query 原子失败**：**GIVEN** SpatialGrid 返回 OK、`BUFFER_TOO_SMALL`、capacity failure、stale handle 和 dependency fault，**WHEN** 展开同一 AreaDamageIntent，**THEN** 只有 OK 产生完整目标集；其余路径不发布部分结果、不消费 CRIT roll、不重定向目标并锁存故障。
- **AC-DM07 `[U][BLOCKING][OPEN-MODIFIER-ABI]` Buff snapshot 隔离**：**GIVEN** tick N 已发布 snapshot，并在 N 中添加、刷新、叠层、移除或 add+remove 同一 modifier，**WHEN** 结算 N/N+1，**THEN** N 只用原 snapshot，合法变化最早 N+1 生效；scope 不匹配不作用，重复同 payload 不叠加，冲突 payload fault。
- **AC-DM08 `[U][BLOCKING]` F1–F4 golden matrix**：**GIVEN** F1 identity/零值/边界，F2 `u=.049/.05,C=0/1`，F3 `R=0/1/.05`，F4 shield 大于/等于/小于伤害，**WHEN** 按固定步骤以 float64 结算，**THEN** 全部中间量与输出逐字段等于独立 golden，每步 finite，发布前 `-0.0→+0.0`，无 FMA、重排、显示取整或隐藏最小伤害。
- **AC-DM08a `[U][I][BLOCKING]` RISK_WARD**：**GIVEN**无ward/有效ward、599/600/601 tick、Paused、duplicate与同组冲突，**WHEN**构造snapshot并执行F3，**THEN**仅有效窗口在existing mitigation后乘0.80一次、shield前消费结果；Paused不推进、duplicate不刷新、同组不相加，非matching identity effect=0。
- **AC-DM09 `[U][BLOCKING]` CRIT 调用次数与边界**：**GIVEN** canonical 批次含 `Ec` 条合法可暴击展开命中及任意不可暴击行，**WHEN** 结算，**THEN** CRIT stream 精确推进 `Ec` 次；`C=0/1` 仍各消费一次，严格使用 `u<C`，范围攻击逐目标独立 roll，不可暴击行消费 0 次。
- **AC-DM10 `[U][I][BLOCKING]` RNG/算术 fail closed**：**GIVEN** RNG 在第 1/中/末次 roll 后 fault，及 F1–F8 每个中间步骤的 NaN/Infinity/非法 ratio/ID exhaustion，**WHEN** QUERY_CONSUME，**THEN** inactive batch 丢弃、selector 不切、HP/fact/统计/presentation 写入为 0、旧 bank 保持可读、fault 仅锁存一次且该 tick 不重试/re-roll。
- **AC-DM11 `[U][BLOCKING][OPEN-PRESENCE-ABI]` F7 每目标聚合**：**GIVEN** 同一目标 `n=0/1/N` 条 contribution、零伤害、shield-only 与 knockback-only，**WHEN** 执行 F7，**THEN** 每目标每 tick 最多一条 resolution，ordered span 不变，aggregate 与逐步 golden 一致；`n=0` 无 row，纯零且无非零 shield/knockback 不造假行。
- **AC-DM12 `[U][I][BLOCKING]` F5 与 Player 应用顺序**：**GIVEN** FLAT、MAX_HP_RATIO、多来源乱序、满血、过量、非致命/ 致命 damage+recovery 及 stale token，**WHEN** phase 5 聚合并由 Player 在 phase 6 应用，**THEN** F5 按冻结 key 求和；固定 damage→lethal→nonlethal recovery，最终 clamp 到 max HP；致命恢复不生效不结转，仅实际 HEAL>0 产生 fact，HP/HUD 每 tick 恰发布一次。DamageSystem 是唯一 PlayerRecoveryResolver。
- **AC-DM13 `[U][I][BLOCKING][OPEN-DEFENSE-ABI]` Player A/B publish**：**GIVEN** damage/recovery 各0/1 row、inactive bank、同 token 重放及各 header 错配，**WHEN** publish/消费，**THEN** 只在完整合法批次切 selector 一次，row/header 逐字段复制 canonical token；无结果为 `has=false,row_count=0`，重放 `OK_NOOP`，错配零 HP/fact/HUD 写入。Shield consumption 的独立 owner ABI 未冻结前保持 OPEN。
- **AC-DM14 `[U][I][BLOCKING][OPEN-ENEMY-ABI]` Enemy resolution 与 F6**：**GIVEN** active Normal/Elite/Boss、零/非零方向、`Kr=0/.85/1`、不同 `Kmax`与多 contribution，**WHEN** 结算，**THEN** 每 active identity 每 tick 最多一条 Enemy resolution，伤害与 knockback 分离；F6 vector finite、real_t readback 后模长 `<=Kmax`，`Kr=1` 位移为 0 且伤害不变，Damage 对 Enemy position 写入为 0。
- **AC-DM15 `[U][I][BLOCKING][OPEN-RECEIPT-ABI]` F8 receipt、overkill 与死亡来源**：**GIVEN** HP=10、canonical contributions `[6,8]`，及 applied damage 0/10/14、重复/missing/stale/mismatched receipt，**WHEN** HP owner 截断并回执，**THEN** F8 得 `actual=[6,4]`、overkill=`[0,4]`、remaining=`+0.0`，第二条为 death source；统计只加 actual 10，matching receipt 仅消费一次，duplicate 为 `OK_NOOP`，missing/mismatch 在下 tick 前 fault。
- **AC-DM16 `[U][I][BLOCKING]` stale/released identity**：**GIVEN** QUERY 后目标死亡、进入 release、borrow 变化，及 source 在 intent freeze 后合法 release，**WHEN** phase 5/6 继续，**THEN** stale target contribution 被 suppressed 且不转移/重复 DEATH/release；freeze 时完整匹配的 immutable source intent 仍可结算，后续 Node 解引用次数为 0。
- **AC-DM17 `[U][I][BLOCKING][OPEN-HAZARD-CAPACITY]` next-tick hazard 快照**：**GIVEN** V2 CIRCLE/EXTERIOR_CIRCLE、active window覆盖/不覆盖下一tick、同ID同/冲突payload、V1/unknown shape、输入乱序、0行及capacity满载，**WHEN**发布`ReviveHazardSnapshotV2`，**THEN**按hazard ID升序、同payload去重、冲突/旧schema/unknown fault；合法空集发布count0有效view，missing/stale/overflow与空集严格区分并使revive fail closed；替身符不删除hazard。
- **AC-DM18 `[U][I][BLOCKING][OPEN-PAUSE-PROTOCOL]` pause/resume**：**GIVEN** pause 请求在 QUERY 前、resolution publish 后、RiskChoice recovery freeze 后和 hazard window 中到达，**WHEN** GameRoot 锁存请求并在完整 tick/phase barrier 进入 Paused，**THEN** 当前已开始 tick 按 GameRoot 唯一收敛路径完成，Paused 期间新 intent/query/damage/heal/timer/buff-duration/hazard-window 推进均为 0；恢复 intent 最早恢复后首个 Active tick exact-once 消费。
- **AC-DM19 `[U][I][BLOCKING][OPEN-CAPACITY]` capacity required−1/required/required+1**：**GIVEN** intent、area candidate、contribution、modifier、Player damage/recovery、Enemy resolution=303、receipt、hazard 的 manifest-required 容量分别为三个边界，**WHEN** Config build、Loading allocation 与满载 tick 执行，**THEN** 只有精确 required 的 production artifact 被接受；runtime required+1 写入在 publish 前 fault，禁止 truncation/sample/resize/backing replacement。
- **AC-DM20 `[U][I][BLOCKING]` 确定性 replay**：**GIVEN** 相同 seed、Config、authority 和逻辑 intent 集但不同 Node/Dictionary/producer 提交排列，**WHEN** 运行至少两个完整 tick trace，**THEN** resolution、contribution span、hazard、receipt attribution、统计及 CRIT 调用次数逐 bit 相同；跨 artifact/架构结论在 RNG/export 证据冻结前保持 `OPEN-RNG-EVIDENCE`。
- **AC-DM21 `[I][E][BLOCKING][OPEN-PRESENTATION-ABI]` committed-only 表现门**：**GIVEN** raw intent、query hit、unpublished resolution、无 receipt/fact 的 resolution、matching committed receipt/fact 及 stale/replayed event key，**WHEN** Visual/Audio/UI 消费，**THEN** 只有 matching `batch_authority_revision` 的 committed 数据 exact-once 触发；DamageSystem 直接实例化 VFX/audio/haptic/UI 为 0。
- **AC-DM22 `[I][E][BLOCKING][OPEN-BATTLEUI]` 表现语义矩阵**：**GIVEN** 多 Player hits、多 Enemy contributions、crit、shield partial/full/break、actual/full-HP heal、resisted knockback、各类死亡、remote retire 及 REVIVE_CLEAR，**WHEN** committed projection 被消费，**THEN** Player 聚合反馈每类最多一次，Enemy 每目标最多一次，crit 有非颜色 cue，shield/heal/knockback 均与实际 committed 结果一致，retire/REVIVE_CLEAR 无 kill/XP/drop/death 表现。
- **AC-DM23 `[I][E][BLOCKING]` damage-number 96 溢出隔离**：**GIVEN** 95/96/97 个同时显示请求及 300 enemy/400 attack-object AoE 峰值，**WHEN** 池被占满，**THEN** 容量内正常展示，后续低优先级新 number 返回 `OVERFLOW_DROPPED` 且 telemetry +1；HP、shield、death、facts、receipts、totals、VFX 与高优先级 audio 与无溢出 baseline 一致。
- **AC-DM24 `[I][E][BLOCKING]` VICTORY+lethal**：**GIVEN** 同一 token 下 VICTORY、致命 Player damage、可用替身符和 pause，并提供普通死亡/合法复活/纯 pause positive controls，**WHEN** terminal precollection、phase 6 publish 与 phase 7 seal 完成，**THEN** HP=0、DAMAGE/DEATH facts 及 death attribution 保留，唯一 winner 为 VICTORY；HIT/DEATH/REVIVE/DEFEAT/pause event、pose、重音均为 0，VICTORY consumer 恰一次。
- **AC-DM25 `[U][I][BLOCKING]` 统计与 Settlement 对账**：**GIVEN** actual、shield、overkill、suppressed stale contribution、remote retire、REVIVE_CLEAR 及 duplicate receipt 混合 fixture，**WHEN** DEFERRED_REMOVAL 累计并冻结 RunOutcome，**THEN** skill/source totals 之和等于 committed actual receipts，death cause/source 等于 F8 lethal prefix，排除 shield、overkill、理论伤害和无奖励清退；重放不改 totals。
- **AC-DM26 `[U][I][BLOCKING]` teardown 与跨局隔离**：**GIVEN** 从 READY、QUERY_STAGED、RESOLUTION_PUBLISHED 与 FAULTED teardown 后开启新 battle，**WHEN** 重放旧 intent/view/token/receipt/event key，**THEN** 旧 bank 先 invalid、generation 推进，所有旧输入被拒绝且新 battle 零污染，不存在 alias writer 或跨局去重键冲突。
- **AC-DM27 `[P][BLOCKING-TOOLING][INCONCLUSIVE-WITHOUT-GUARD]` 静态零分配门**：**GIVEN** 冻结 production roots、非空实现门、known-good/known-bad fixtures 与 native-call allowlist，**WHEN** 运行静态 guard，**THEN** Active 热路径禁止 Array/Dictionary 构造、append/push/resize/duplicate/slice/map/filter/reduce、Callable/closure、带参 signal、unstable sort、backing replacement 与 runtime resource/node 创建；guard 或正反 fixture 缺失时只能判 INCONCLUSIVE。
- **AC-DM28 `[P][E][OPEN-EVIDENCE][INCONCLUSIVE-WITHOUT-ARTIFACT]` 满载与目标设备证据**：**GIVEN** manifest-bound 最低规格设备/OS、release build、60 Hz、300 enemies/400 attack objects、最大合法 workload、damage-number 96 满池、冻结 observer/hash/marker 与每维 positive control，**WHEN** 预热后独立运行 3 次、每次 10000 tick，**THEN** 每 run 的 allocator events/bytes、container growth、COW、unexpected allocation-capable native calls 分别为 0，无 gameplay overflow/fault，并报告 p50/p95/p99/max 及完整 counters；同时录像证明关键可读性。缺任一 artifact/原始样本/阈值/录像/positive control 时为 OPEN/INCONCLUSIVE，不得以桌面 spike 代替。
- **AC-DM29 `[U][I][BLOCKING]` 明心丹typed consumer**：**GIVEN**NONE/三丹的`DamagePreparationInputV1` golden及identity/revision/hash/finite/bonus单轴破坏，**WHEN**Loading bind→Active/Pause/Resume，**THEN**仅NONE=0与明心=.08通过，其他丹bonus=0；F2 crit chance逐值等于`base+dayan+.08`且只绑定一次，profile/UI读取与Active热改次数均0。

## Open Questions

| ID | Status | Question / required decision | Owner | Resolve before |
|---|---|---|---|---|
| OQ-DM01 | `BLOCKED-DOWNSTREAM-GDD` | Freeze complete `DamageIntentV1/AreaDamageIntentV1` producer ABI and exact checked capacities. | Projectile + Weapon + Boss owners | battle-ready manifest |
| OQ-DM02 | `BLOCKED-HAZARD-CAPACITY` | Projectile400、Boss2已知；冻结Enemy nonprojectile/Stage contribution、V2 shape ABI与exact总容量。 | Projectile + Enemy + Boss + Stage + Config | Player revive integration |
| OQ-DM03 | `BLOCKED-MODIFIER-ABI` | 通用modifier bank字段、其他stack-group总序、上界与add/remove冲突仍待冻结；RiskChoice的RISK_WARD特例已冻结，不代表全局ABI完成。 | Weapon + SkillDraft + Config | Buff-enabled damage integration |
| OQ-DM04 | `BLOCKED-DEFENSE-ABI` | Choose and version the shield resource owner, shield-consumption publish/commit capability and shield-only presence semantics without changing PlayerDamageResolutionV1 silently. | Weapon + Player + GameRoot | shield skill integration |
| OQ-DM05 | `BLOCKED-ENEMY-ABI` | Freeze Enemy resolution/contribution/receipt bank fields, token and first-error precedence. | Damage + Enemy | enemy HP integration |
| OQ-DM06 | `BLOCKED-KNOCKBACK` | Freeze normalization/clamp/readback algorithm, `knockback_max` and world-reachability proof. | Damage + Enemy + Config | knockback implementation |
| OQ-DM07 | `OPEN-RNG-EVIDENCE` | Verify CRIT float roll and fixed-order arithmetic on pinned Godot 4.7.1 export artifacts. | RNG ADR + QA | cross-device determinism claim |
| OQ-DM08 | `BLOCKED-PRESENTATION-ABI` | Freeze committed receipt-to-presentation bank, stable order, ACK/replay rules and damage-number merge window. | BattleUI + Damage + GameRoot | presentation integration |
| OQ-DM09 | `PARTIAL-AUDIO-PROPAGATION` | Audio作者GDD已冻结bus/priority/merge/steal/duck/fallback结构；Damage event rows、H_damage、正式数值与真机mix仍BLOCKED。 | Audio owner | audio implementation |
| OQ-DM10 | `BLOCKED-PRESENTATION-BUDGET` | Freeze min-spec device, VFX/audio caps, occlusion metric and sampling protocol. | QA + Performance + BattleUI | device evidence |
| OQ-DM11 | `BLOCKED-TOOLING` | Implement and positive-control the static allocation guard over actual production roots. | Engineering + QA | AC-DM27 |
| OQ-DM12 | `RE-REVIEW-PENDING` | Reconcile DamageSystem as the unique PlayerRecoveryResolver and all versioned views into Player/Config/GameRoot. | Damage + Player + Config | independent full review |
