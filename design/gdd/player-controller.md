# PlayerController

> 2026-09-14 WP04c：商业恢复责任与 pending/barrier 盘点见 `design/registry/manifests/steam-recovery-responsibilities-v1.json`；显式合同、绑定封装、全量预检及联合验证见 [Steam域与快照适配](steam-save-domain-adapters.md)。清单是责任盘点，商业 owner/schema/容量仍 OPEN，不改变本文件既有 verdict。

> 2026-09-11 WP04b 适配路由：五域结构/联合校验与当前 `LEGACY_STAGE_PC_V1` capture/restore 见 [Steam域与快照适配](steam-save-domain-adapters.md)。Pool/Grid 原生引用不落盘；当前生成逻辑viewport冻结，RNG保存实际seed/state并绑定engine commit；全Scope tick结束才捕获。此实现不补齐本文件全部商业owner合同；真实v2迁移/事务、Mission/SkillDraft/Preparation/Settlement语义和商业最大预算仍OPEN，battle_ready=false。

> 2026-09-11 Steam合同路由（作者传播，implementation gate OPEN）：STEAM_MISSION_V1/STEAM_SAVE_V2的目标、终态与完整恢复要求见mission-objectives.md、save-steam-pc.md及ADR-0006。本owner的目标身份/生命周期（适用时）、matching-tick snapshot、schema/validator/migration、required-owner与容量贡献待正式冻结并接线；下方legacy合同不因本路由而自动满足新profile，缺失时禁止生产启用。

> **Status**: In Review（“感知无限、技术有限”跨文档修订已合入；Full Re-review Pending）
> **Author**: 用户 + Codex agents
> **Last Updated**: 2026-09-02
> **Implements Pillar**: 移动躲避 + 自动御剑 + 功法进化的爽快度

## Overview

| 输入profile | 来源与生命周期权威 | 消费合同 |
| --- | --- | --- |
| STEAM_PC | `input-steam-pc.md` PC01–10；WASD/左轴、fresh-neutral | `PcMovementContext`+共享carrier同tick租约；当前ADR-0003像素尺度 |
| MOBILE_TOUCH / future-port | `input-system.md` MOBILE_TOUCH章节；VJ/fresh touch | 本文PlayerPhaseContextV1、4.5世界单位/秒及移动端AC仍待完整实现 |

下文“单拇指/手指推动摇杆”的来源描述仅适用于MOBILE_TOUCH；PC同样以方向和时机控制身法，不借用VJ claim。

PlayerController 是战局中玩家实体与权威位置的唯一拥有者。玩家通过单拇指虚拟摇杆直接控制韩立走位，系统在每个固定玩法 tick 消费 InputSystem 提供的移动意图，以满速或停止的二元规则提交位置；正式战场不设玩家可见arena边界，Stage相机持续锁定已提交位置，地表与后续怪潮围绕玩家延展。底层位置仍必须落在Stage的大型有限安全域内，但正常配置的可达性证明保证玩家不会在合法局时长触及该技术边界。自动攻击、拾取、受伤、死亡与替身符等系统只通过明确接口读取玩家状态或提交作用，不得绕过 PlayerController 改写位置。

## Player Fantasy

玩家扮演的不是正面碾压一切的莽夫，而是始终留有后手、依靠判断和身法活下来的韩立。手指推动摇杆时，角色应立即朝预期方向移动；松手时立即停下；持续朝任意方向突围时不应撞到可见墙、黑边或沿边滑行。玩家因此敢在怪潮间主动穿行，而不是因控制迟滞或盒状战场选择站桩承伤。

自动御剑与功法负责持续进攻，PlayerController 让玩家把注意力集中在“从哪里突围、何时贴边、何时回身捡取资源”这些生存判断上。理想时刻是妖兽即将合围，玩家以一次干净的变向穿过狭小缺口，身后飞剑自动收割追兵——胜利来自自己的走位，而不是系统暗中修正或代替操作。

替身符触发时应形成一次清晰的绝境翻盘：玩家知道后手已经消耗，重新获得行动机会，但不会产生无敌或可以故意送死的安全感。整个系统服务“稳、准、险”三种感受：控制稳定、方向准确、风险始终真实。

## Detailed Design

### Core Rules

1. **唯一玩家权威**

   PlayerController 是玩家 `committed_position`、朝向、HP、存活状态、替身符状态和复活代次的唯一 writer。Node transform 仅镜像权威位置；其他系统不得直接改写玩家 Node、HP 或位置。

2. **生命周期与阶段**

   `PLAYER` 以 `stable_order=2` 注册，参加：

   - `MOVEMENT_COMMIT`：InputSystem 之后提交本 tick 玩家位置。
   - `DEFERRED_REMOVAL`：按固定顺序应用已结算的伤害与恢复批次，提交伤害、恢复、复活或败北事实。

   允许成功状态仅为 `OK`、`OK_NOOP`。PlayerController 不定义 `_process`、`_physics_process` 或输入回调。

   PLAYER 的 `OwnerOrchestrationCapacityContributionManifest` 贡献固定为：`LIFECYCLE_INTENT=0`、`FACT_COMMIT=2`、`PAUSE_CLOSURE=0`、`BLOCKING_CHOICE=0`；`owner_contract_id=PlayerController/v1`，`role_stable_order=2`，四类 `kind_stable_order=1..4`、`field_stable_order=0`。`FACT_COMMIT=2` 精确覆盖同 tick 的最大合法组合：`DAMAGE+DEATH`、`DAMAGE+HEAL`或单条`HEAL`；不得由Damage/Recovery producer为同一runtime事实重复贡献。替身符清除的lifecycle row带`participant_id=ENEMY`并计入ENEMY的303上界，PLAYER不另计第二份lifecycle容量。完整actual rows见Dependencies，不允许Config补默认字段。

3. **确定性移动**

   每个正常玩法 tick 只读本 tick 的 `MovementIntentCarrier`：

   - `is_active=false`：速度和位移均为零。
   - `is_active=true`：方向必须 finite 且满足单位向量契约，以 `4.5` 世界单位/秒移动。
   - 不增加加速度、惯性、模拟慢速、自动寻路、自动闪避或隐藏方向修正。
   - 非零方向更新朝向；零方向保留最后一次非零朝向。
   - 零位移仍完成一次本 tick 位置提交，用以证明 PlayerController 已执行。
   - `MovementIntentCarrier` 只拥有 InputSystem 冻结的 `{direction,is_active,press_generation,written_tick}`；battle/config/player identity 来自 matching `PlayerPhaseContextV1`，不得假定 movement carrier 含有这些字段。
   - 旧 tick、重复 tick、错误 phase-context identity 或非法 carrier 均返回 typed failure，所有权威字段零修改。
   - BATTLE_LOADING 的初始位置固定为世界安全域原点 `(0,0)`，不另存第二个出生点字段；初始朝向固定为 Godot `Vector2.DOWN=(0,1)`。

4. **完整足迹世界域守卫**

   MVP 玩家 gameplay 足迹为以 Player 原点为圆心的圆，直径由 PlayerConfig 冻结。合法技术中心区域为 `StageWorldDomainViewV2.world_safe_aabb` 按玩家半径向内收缩后的矩形；它不是玩法arena或玩家可见边界。

   正常移动不做边界clamp：

   - F1计算并real_t32 readback后的raw position若完整足迹仍在技术安全域内，原值提交，不截断任一轴。
   - Config必须在BATTLE_LOADING以最大局时长证明合法移动、复活与相对运行包络无法触及此守卫。
   - 若历史位置或本tick候选越过技术安全域，返回`POSITION_OUT_OF_RANGE`并由GameRoot进入`ControlledGameplayFault`；不得clamp、反弹、wrap、传送原点或继续沿边。
   - 初始出生点、足迹或reachability配置非法时在BATTLE_LOADING fail closed，不用静默修正掩盖错误。
   - Player gameplay root 固定 `rotation=0`、`scale=(1,1)`；视觉缩放和插值只能作用于 visual child。

   MVP 权威移动不经过物理碰撞求解。场景根节点使用 `Node2D`，还是把 `CharacterBody2D` 仅作为组件容器，可留给 ADR；`move_and_slide()` 不得成为当前权威位置求解器。

5. **位置提交载体**

   PlayerController 持有两个在 Loading 期预分配、精确定容且 backing 独占的 `PlayerMotionCommitCarrierV1 extends RefCounted`，在每个成功的正常 `MOVEMENT_COMMIT` 做 owner-local A/B swap。字段精确为：

   `{schema_version=1, battle_instance_id:int64, config_snapshot_id:int64, bank_id:int32, player_id:int64, tick_revision:int64, position_revision:int64, batch_authority_revision:int64, previous_position:Vector2, committed_position:Vector2, velocity:Vector2, facing_direction:Vector2, has_movement_intent:bool, did_translate:bool, movement_enabled:bool}`

   `has_movement_intent` 表示输入意图，`did_translate` 表示domain guard通过后位置是否实际改变，二者不得合并。位置 ABI 固定为标准 export 的 real_t32 `Vector2` 位值：标量输入先验证为 finite，以固定顺序提升到 float64 计算，构造 `Vector2` 后立即 readback 实际 real_t32 位值，再以 readback 值求 `actual_displacement/velocity` 并发布。后序查询、伤害和表现系统只读已发布 carrier，不读取 Player Node 或插值位置。

   motion bank 是 phase-2 位置权威；GameRoot `BattleAuthorityBundle` 是 phase-6 HP/life/talisman/fact/lifecycle 权威。普通 phase-2 publish 的 `batch_authority_revision` 精确等于该 tick 输入 context 的 `source_authority_revision`；复活 motion publish 精确等于 matching phase-6 `next_authority_revision`。phase 6先在consumer closed的同一`Phase6AuthorityBatchPlanV1`中准备state slice及本batch需要的motion/HUD/event inactive输出；GameRoot持Player签发的one-shot commit capability，固定提交顺序为`BattleAuthorityBundle selector → optional motion selector → HUD selector → optional transient event selector → optional critical ledger PUBLISHED transition → Node mirror`。所有步骤arm后只做已验证primitive写且不可失败，共享同一`batch_authority_revision`；任一pre-PONR validation/arm failure均不切selector，PONR后只允许保存capability的matching commit。任何gameplay/presentation consumer只在整条链完成后开放。

6. **伤害、恢复与生命归属**

   DamageSystem 负责命中、减伤、伤害来源、死亡原因编码及同 tick 稳定聚合，向预分配 `PlayerDamageResolutionV1` 写入最终伤害批次。PlayerController：

   - 只应用最终批次，不重复计算减伤或暴击。
   - 拥有 `current_hp/max_hp` 与生命归零判定。
   - 每 tick 最多提交一条非零聚合 `DAMAGE` fact；致命批次若未被替身符复活吸收，则最多再提交一条 `DEATH` fact，胜利优先不抹除已经发生的死亡事实。
   - `final_damage=0` 时不写 DAMAGE fact；正伤害若float64相减后HP逐bit不变则返回`CARRIER_INVALID`，不得发布“有伤害事实但HP未变”的状态。
   - DAMAGE/HEAL/DEATH 已提交事实的稳定去重键固定为 `{battle_instance_id,fact_sequence,batch_authority_revision}`；视图重建、pause/resume或节点重新入树不得重放相同键。
   - DamageSystem不得直接写HP、替身符或玩家位置。
   - 同 tick 多次命中不会逐 hit 穿透替身符；它们先形成一个稳定最终批次。
   - Longchun/Buff与RiskChoice等恢复来源只向唯一`PlayerRecoveryResolver`即DamageSystem提交typed intent；DamageSystem在phase 5稳定聚合并发布至预分配`PlayerRecoveryResolutionV1`，任何来源不得直接写Player HP。该owner已在`design/gdd/damage-system.md`冻结作者契约，仍待独立full review。
   - phase 6固定先应用聚合DAMAGE，再判定致命；仅当结果仍为`ALIVE`时应用聚合HEAL并clamp到`max_hp`。致命批次上的同tick恢复不救命、不穿过替身符，也不延期到下一tick；恢复要参与救命必须由其owner在更早tick合法提交。
   - 实际恢复量大于0时最多提交一条`HEAL` fact；满血恢复或`final_recovery=0`为`OK_NOOP`且不写fact。若同tick非致命DAMAGE与HEAL都实际生效，按`DAMAGE fact_sequence < HEAL fact_sequence`提交，最终HP与HUD只发布一次。
   - `max_hp`只在BATTLE_LOADING由Config解析并冻结：功法树与下一局锻体丹通过百分比输入形成`resolved_starting_max_hp`；Active内不接受maxHP热改。周期恢复、藏锋避险和低血恢复只改变`current_hp`。

7. **替身符 exact-once 复活**

   每局初始化一张替身符，状态为 `AVAILABLE`。首次致命伤害批次到达时：

   1. 消费 GameRoot 在 phase-5 resolution publish 后、任何 phase-6 side effect 前冻结的 matching `TerminalPrecollectionViewV1`，确认本 tick 尚无更高优先级的 `FATAL` 或 `VICTORY`；Player 不从 participant 调用顺序或晚到 intent 猜测终局。
   2. 在私有复活计划中暂存替身符将从 `AVAILABLE` 变为 `SPENT`；只有matching phase-6 authority publish才对外exact-once消费，点前失败保持`AVAILABLE`。
   3. 从死亡点、内圈八方向和外圈八方向中选择复活位置，共17个固定候选。
   4. 所有候选按固定float64顺序计算、构造/readback real_t32并验证完整足迹仍在技术安全域；不做arena clamp。随后依据 matching `EnemyThreatSnapshotV1` 与 next-tick `ReviveHazardSnapshotV2` 严格按 `safety rank → surface score DESC → prospective_clear_count ASC → candidate index ASC` 总序选择；不得跳过 clear count 直接以 index 破平。
   5. 若不存在对清场后敌人与 next-tick hazard 都达到非负表面净空的候选，选择最大最小表面净空并标记 `UNSAFE_FALLBACK`；不虚构绝对安全，也不因此产生无敌。
   6. 恢复 `35% max_hp`，推进 `revive_generation`，更新玩家位置。
   7. 以最终复活点为中心提交一次普通敌人清除计划。

   清除计划只影响在最终复活点与玩家完整圆形足迹实际重叠或相切的 `NORMAL` 敌人；Elite与Boss不受影响。它不是半径清屏、不得按固定范围清除非重叠普通敌人。300 仅是 clear carrier 的容量压力上界，不是 production 一次复活的目标效果。被清除敌人不产生击杀数、经验、掉落、奖励或纪录。PlayerController只冻结完整 lifecycle identity 集合，实际 Grid/Pool 生命周期由 Enemy/GameRoot journal 收敛。

   复活不提供持续无敌；当前致命批次不会继续穿透到复活后的HP，玩家从下一完整 gameplay tick 起重新可受伤。

8. **复活事务与不可逆点**

   复活使用私有事务 `EMPTY → PREPARED → ARMED → COMMITTED | ABORTED`，不暴露为第二套玩家顶层状态。

   - prepare时先把完整复活tuple `{position, hp=35% max_hp, talisman=SPENT, revive_generation+1, life=ALIVE, revive_safety_class}` 写入尚不可见的inactive authority bank，并把完整clear identity集合写入Player私有、预定容`ReviveClearIntentBankV1`。Player随后仅通过注入的`ReviveClearLifecycleResolverCapabilityV1`请求Enemy/GameRoot resolver逐行reserve `LifecycleCommitJournal` row（含checked `lifecycle_sequence`、`participant_id=ENEMY`、完整tuple、effect kind与初始`RESERVED`）；Player不直接持有journal backing或执行Grid/Pool副作用。完整reservation proof、DAMAGE fact row及bundle/motion/HUD/event one-shot capability全部arm后才能进入PONR。任一行、sequence、capacity、header或capability失败都发生在PONR前，且不得留下公开或可推进的部分计划。
   - 不可逆操作顺序固定为：全部 reservation 与 capability arm 成功后，先把本次非零DAMAGE fact从`RESERVED`推进为`COMMITTED`，该提交统一定义为 `revive_point_of_no_return`；随后才按完整 lifecycle tuple canonical order 推进已预留的 clear rows。不存在“PONR后才新建row/分配sequence/capability”或“已移除敌人但DAMAGE尚未提交”的合法状态。
   - `revive_point_of_no_return` 前失败：abort inactive plan，玩家、敌人、HP、facts和替身符均零 gameplay effect。
   - `revive_point_of_no_return` 后失败：不得声称整批回滚；Player只可调用同一resolver capability推进下一条已预留row，Enemy/GameRoot执行并记录Grid/Pool副作用。GameRoot必须收敛已提交 lifecycle/fact rows，并把已arm的复活tuple与全部已提交事实在唯一matching authority publish中一起公开，随后进入 `TECHNICAL_ABORT`。
   - 同一敌人若同时发生正常死亡与替身符清除，只保留一条 lifecycle row，正常死亡语义优先。
   - 复活事务必须在同一次 `DEFERRED_REMOVAL` 内终结，不跨暂停或下一 gameplay tick。

9. **败北与终局仲裁**

   致命伤害若未被替身符复活吸收，生命状态进入 `DEATH_LATCHED`。只有不存在更高优先级胜利时才向 GameRoot 提交唯一 defeat intent；PlayerController不直接切换顶层场景、打开结算或执行Save。

   同一屏障采用三步裁定，而不是把非终局复活与暂停塞进同一terminal enum：

   1. phase-5 matching resolution publish 后，GameRoot 通过无副作用 precollection 收齐 BATTLE_RULES/owner 对当前 resolution 的 `FATAL/VICTORY/PAUSE` contender，按独立 golden 冻结 `TerminalPrecollectionViewV1`；缺失、重复、stale或 producer 顺序相关结果在 phase-6 side effect 前 fault。
   2. phase-6 side effect前已知 `FATAL` 时进入技术终止；若FATAL发生在不可逆点后，则先按GameRoot规则收敛已提交journal/fact与唯一authority publish。无FATAL且 `VICTORY` 成立时，保留实际DAMAGE/DEATH事实与`HP=0`，outcome仍为VICTORY；替身符不消耗，pause被终局抑制。玩家可见 terminal winner 唯一为VICTORY：DEATH fact只供统计/结算/死亡原因，不触发普通死亡pose、死亡重音、败北UI或pause UI。
   3. 无FATAL/VICTORY且致命时，替身符可用则产生非终局REVIVE disposition，否则提交DEFEAT contender；phase 7只能把同一 precollection identity 加上 phase-6 已提交的DEFEAT/REVIVE结果 seal/推进，禁止首次发现VICTORY或改判已执行的复活。非终局结果完成后，phase 7独立处理pause，因此成功REVIVE不会吞掉同tick已latch的pause reason。

10. **拾取与索敌边界**

    PlayerController不注册到 SpatialGrid，不新增 `PLAYER` type，也不调用 Grid：

    - DropSystem读取玩家位置，执行 `DROP` circle query并提交拾取事实。
    - Weapon/TargetingSystem读取玩家位置，按攻击节奏执行 `ENEMY` nearest query。
    - DamageSystem涉及敌人范围查询时查询 `ENEMY`；玩家受击使用位置 carrier 做直接窄相，不查询不存在的 `PLAYER` mask。
    - Object Pooling不是PlayerController直接依赖；替身符复用同一玩家 identity，不返池、不重新借出玩家。

11. **暂停、结束与故障**

    PlayerController不复制 GameRoot 的暂停/恢复状态：

    - `PAUSE_PENDING` 技术 drain、Paused、Resume、Ending和Fault均不得产生新移动、伤害、复活或计时推进。
    - drain中的Player participant只返回 `OK_NOOP`，所有玩家权威字段零修改。
    - Resume后的首次正常移动只接受 InputSystem 同 tick 新写入的 carrier；不重放暂停前方向。
    - teardown后状态不可恢复；新局使用新的 battle identity 和 PlayerController实例。

12. **热路径与错误策略**

    稳态移动为 `O(1)`，Grid调用数为0。禁止 Dictionary、临时Array、带参signal、方法字符串、动态增长及运行时载体替换。复活 one-shot 只允许对预分配 clear workspace 执行本GDD冻结的完整lifecycle-tuple binary insertion sort；该 allowlist 不适用于普通 Active tick，且 comparisons/row moves/primitive writes 必须进入 AC counter。所有派生值先在局部验证，成功后一次提交；任何非有限值、identity错配、stale/duplicate tick、容量错误或非法状态都按冻结 precedence 返回精确 status，由 GameRoot 中止本 phase并进入统一故障流程。

### States and Transitions

| 状态域 | 状态 | 允许转换 |
|---|---|---|
| Owner lifecycle | `UNINITIALIZED` | initialize成功 → `READY` |
| Owner lifecycle | `READY` | teardown → `TERMINATED` |
| Owner lifecycle | `TERMINATED` | 无恢复边 |
| Life | `ALIVE` | 致命且符可用、无FATAL/VICTORY → 原子复活后仍为`ALIVE`；致命且不复活 → `DEATH_LATCHED` |
| Life | `DEATH_LATCHED` | 仅等待GameRoot按VICTORY或DEFEAT收敛和teardown；life不等同outcome |
| Talisman | `AVAILABLE` | 首次合法复活提交 → `SPENT` |
| Talisman | `SPENT` | 本局无恢复边 |
| Revive transaction | `EMPTY` | 合法致命批次完成context/header、候选、hazard、容量、完整clear identity copy与sort，inactive tuple/list校验通过 → `PREPARED`；此前失败保持`EMPTY` |
| Revive transaction | `PREPARED` | 全部lifecycle/fact reservation、checked sequence与bundle/motion/HUD/event capability arm通过 → `ARMED`；此阶段失败 → `ABORTED` |
| Revive transaction | `ARMED` | matching phase-6提交 → `COMMITTED`；不可逆点后失败 → journal收敛后技术终止 |
| Revive transaction | `COMMITTED/ABORTED` | 本次事务终态，不重复消费 |

#### Public API and Status

公开 mutation API仅包括：

- `initialize(context: PlayerInitializeContextV1) -> int`
- `run_phase(phase: int, context: PlayerPhaseContextV1, lease_id: int) -> int`
- `teardown(context: PlayerTeardownContextV1) -> int`

三个 context 均为 `RefCounted`、Loading 期预分配；context header与input view调用期间只读，只有显式`prepared_output`/binding capability允许写入其private inactive backing。禁止 Dictionary/未类型化Variant payload：

- `PlayerInitializeContextV2={schema_version=2,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,initial_tick_revision:int64,top_state:int32,player_config:PlayerConfigV1,stage_view:StageWorldDomainViewV2,movement_banks:PlayerMotionCommitCarrierBankV1,phase6_bindings:Phase6PlayerBankBindingsV1}`。旧V1 context或旧Stage geometry view不得被V2 Player初始化接受。
- `PlayerPhaseContextV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,tick_revision:int64,top_state:int32,phase:int32,source_authority_revision:int64,expected_next_authority_revision:int64,movement_intent:MovementIntentCarrier,resolution_view:PlayerDamageResolutionViewV1,recovery_view:PlayerRecoveryResolutionViewV1,enemy_threat_view:EnemyThreatSnapshotViewV1,revive_hazard_view:ReviveHazardSnapshotViewV2,terminal_precollection_view:TerminalPrecollectionViewV1,phase6_plan:Phase6AuthorityBatchPlanViewV1,prepared_output:Phase6PlayerPreparedOutputV1}`。`MOVEMENT_COMMIT`只允许 movement_intent 权威且其余 phase-6 view/output 为unbound；`DEFERRED_REMOVAL`要求 damage/recovery/enemy/hazard/terminal/phase6 plan matching 且 prepared_output 为可写inactive binding；技术drain要求全部 gameplay payload/output unbound并返回`OK_NOOP`。
- `PlayerTeardownContextV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,tick_revision:int64,top_state:int32,convergence_state:int32,convergence_revision:int64}`；点后 teardown 仅接受 `convergence_state=CONVERGED` 且 revision matching。

所有 nested type 都是冻结 ABI，不允许只以类名代替 schema：

- `StageWorldDomainViewV2={schema_version=2,battle_instance_id:int64,config_snapshot_id:int64,view_generation:int64,world_safe_min:Vector2,world_safe_max:Vector2,camera_visible_world_size:Vector2,spawn_inner_half:Vector2,spawn_outer_half:Vector2,despawn_margin:float64,valid:bool}`；Player只消费world safe min/max与identity，Camera/Spawn字段只做cross-manifest一致性验证，不进入移动公式。
- `PlayerMotionCommitCarrierBankV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,capacity:int32=2,published_bank_id:int32,published_position_revision:int64,view_generation:int64,bank0:PlayerMotionCommitCarrierV1,bank1:PlayerMotionCommitCarrierV1,valid:bool}`；两个bank由Player私有字段持有，Loading期分别构造，禁止把Packed backing或可写RefCounted返回给消费者。
- `PlayerHpAuthorityViewV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,authority_bank_id:int32,authority_revision:int64,player_id:int64,current_hp:float64,max_hp:float64,life_state:int32,view_generation:int64,valid:bool}`不是第三套bank，而是GameRoot当前published `BattleAuthorityBundle`中Player authority slice的getter-only copy-out。GameRoot每次full authority copy都逐字段复制该slice并更新header revision，因此即使Player本phase无输出、仅其他owner推进authority revision，也能取得matching HP view；Drop只可据此做回春资格判断，不得写HP。
- `PlayerDamageResolutionViewV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,view_generation:int64,resolution_bank_id:int32,resolution_publish_revision:int64,tick_revision:int64,source_authority_revision:int64,has_resolution:bool,row_count:int32,valid:bool}`；`row_count=has_resolution?1:0`，只允许以`copy_resolution_into(out: PlayerDamageResolutionV1)->int`逐字段复制matching row，`has_resolution=false`时row不可读。
- `PlayerRecoveryResolutionViewV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,view_generation:int64,recovery_bank_id:int32,recovery_publish_revision:int64,tick_revision:int64,source_authority_revision:int64,has_recovery:bool,row_count:int32,valid:bool}`；`row_count=has_recovery?1:0`，只允许以`copy_recovery_into(out: PlayerRecoveryResolutionV1)->int`逐字段复制matching row，`has_recovery=false`时row不可读。其A/B backing与selector归唯一`PlayerRecoveryResolver`即DamageSystem，Player只持getter-only view；DamageSystem契约仍待独立full review。
- `EnemyThreatSnapshotViewV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,view_generation:int64,bank_id:int32,publish_revision:int64,tick_revision:int64,authority_revision:int64,count:int32,capacity:int32=303,valid:bool}`；`EnemyThreatRowV1={enemy_id:int64,object_instance_id:int64,spatial_handle_id:int64,borrow_id:int64,center:Vector2,class_code:int32,shape_code:int32,bound_radius:float64,next_tick_swept_bound_radius:float64}`。只允许`copy_enemy_row_into(index:int,out:EnemyThreatRowV1)->int`复制九array的同一index，禁止暴露PackedArray alias。
- `ReviveHazardSnapshotViewV2={schema_version=2,battle_instance_id:int64,config_snapshot_id:int64,view_generation:int64,bank_id:int32,publish_revision:int64,tick_revision:int64,authority_revision:int64,count:int32,capacity:int32,valid:bool}`；`ReviveHazardRowV2={hazard_id:int64,shape_code:int32,center:Vector2,bound_radius:float64,active_tick_from:int64,active_tick_through:int64}`。shape封闭enum为`CIRCLE/EXTERIOR_CIRCLE`；`capacity`逐值等于Config冻结值，只允许`copy_hazard_row_into(index:int,out:ReviveHazardRowV2)->int`。
- `Phase6AuthorityBatchPlanViewV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,tick_revision:int64,source_authority_revision:int64,next_authority_revision:int64,inactive_authority_bank_id:int32,resolution_bank_id:int32,resolution_publish_revision:int64,recovery_bank_id:int32,recovery_publish_revision:int64,terminal_precollection_token:int64,authority_copy_manifest_hash:int64,plan_generation:int64,armed:bool,valid:bool}`；它是GameRoot私有`Phase6AuthorityBatchPlanV1`的getter-only view，Player不得arm、publish或修改plan。
- `Phase6PlayerBankBindingsV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,player_authority_slice:PlayerAuthoritySliceBindingV1,fact_writer:PlayerFactWriterBindingV1,revive_clear_resolver:ReviveClearLifecycleResolverCapabilityV1,hud_banks:PlayerHudSnapshotBankV1,transient_event_banks:PlayerTransientEventBankV1,critical_event_ledger:PlayerCriticalEventLedgerV1,commit_capability:PlayerPhase6CommitCapabilityV1}`。每个binding含matching header、private writable inactive index、精确capacity与`valid`；外部只持有冻结 getter/capability，不得直接取得可写backing。
- `PlayerAuthoritySliceBindingV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,view_generation:int64,inactive_authority_bank_id:int32,source_authority_revision:int64,next_authority_revision:int64,capacity:int32=1,valid:bool}`。
- `PlayerFactWriterBindingV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,tick_revision:int64,view_generation:int64,inactive_authority_bank_id:int32,source_authority_revision:int64,next_authority_revision:int64,capacity:int32=2,reserved_count:int32,written_count:int32,valid:bool}`；只允许Player私有reserve/commit helper写DAMAGE/HEAL/DEATH row；同tick实际DAMAGE+HEAL最多2行，致命DAMAGE+DEATH最多2行，致命批次恢复被抑制，因此上界仍为2。
- `ReviveClearLifecycleResolverCapabilityV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,tick_revision:int64,view_generation:int64,inactive_authority_bank_id:int32,source_authority_revision:int64,next_authority_revision:int64,capacity_source_role_id:int32=ENEMY,journal_participant_id:int32=ENEMY,capacity:int32=300,reserved_count:int32,advanced_count:int32,valid:bool}`；Player只可按已冻结tuple总序调用`reserve_clear_rows(intent_bank)->status`与PONR后的`advance_reserved_row(index)->status`。journal backing、sequence、capacity charge及Grid/Pool副作用全部归Enemy/GameRoot resolver；Player不得直接写journal。
- `PlayerHudSnapshotBankV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,capacity:int32=2,published_bank_id:int32,published_authority_revision:int64,view_generation:int64,bank0:PlayerHudSnapshotV1,bank1:PlayerHudSnapshotV1,valid:bool}`。
- `TerminalPrecollectionViewV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,tick_revision:int64,source_authority_revision:int64,resolution_bank_id:int32,resolution_publish_revision:int64,contender_mask:int32,precollected_winner:int32,producer_coverage_hash:int64,precollection_token:int64,valid:bool}`；mask只含`FATAL/VICTORY/PAUSE`，winner只含`FATAL/VICTORY/PAUSE/NONE`并由GameRoot独立golden计算。Player只读，不得添加/删除 contender。
- `Phase6PlayerPreparedOutputV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,tick_revision:int64,source_authority_revision:int64,next_authority_revision:int64,resolution_bank_id:int32,resolution_publish_revision:int64,recovery_bank_id:int32,recovery_publish_revision:int64,precollection_token:int64,inactive_authority_bank_id:int32,publish_motion:bool,inactive_motion_bank_id:int32,next_position_revision:int64,inactive_hud_bank_id:int32,publish_transient:bool,inactive_transient_bank_id:int32,publish_critical:bool,critical_row_index:int32,disposition:int32,reserved_fact_count:int32,reserved_lifecycle_count:int32,clear_count:int32,commit_capability_id:int64,prepared_state:int32}`；`disposition={NONE,DAMAGE_ONLY,RECOVERY_ONLY,DAMAGE_AND_RECOVERY,REVIVE,DEFEAT,VICTORY_SUPPRESSED,FATAL_SUPPRESSED}`，state=`EMPTY/PREPARED/ARMED/COMMITTED/ABORTED`。
- `PlayerPhase6CommitCapabilityV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,tick_revision:int64,source_authority_revision:int64,next_authority_revision:int64,capability_id:int64,publish_motion:bool,inactive_motion_bank_id:int32,next_position_revision:int64,inactive_hud_bank_id:int32,publish_transient:bool,inactive_transient_bank_id:int32,publish_critical:bool,critical_row_index:int32,plan_generation:int64,armed:bool,consumed:bool,valid:bool}`。`capability_id`初始化为0，每次arm前checked `+1`且必须与matching plan generation绑定；合法状态仅`{armed=false,consumed=false}`、`{true,false}`、`{true,true}`，耗尽或非法组合在PONR前失败。它是Player拥有、Loading期预分配的私有one-shot capability；arm后只允许GameRoot以逐字段matching的同一tuple调用一次 `commit_prepared_player_outputs(...) -> void`。该调用按`optional motion selector → HUD selector → optional transient event selector → optional critical ledger PUBLISHED transition`连续写私有selector/revision，不调用Node/property setter/signal/Callable/await且无failure返回；错误调用必须在arm前由GameRoot拒绝，不能把点后错误变成可恢复status。

凡phase6发布Player HUD，`publish_motion`必须为true：Player先把当前published motion完整复制到inactive motion bank，将其`batch_authority_revision`改为`next_authority_revision`并checked推进`position_revision`，即使位置未改变也切一次motion selector。这样damage-only/recovery-only/revive三类HUD都存在同revision motion可供派生frame联结；只有Player无authority/HUD publish的phase6 no-op才允许`publish_motion=false`。

`PlayerAuthoritySliceBindingV1`、`PlayerFactWriterBindingV1`、`ReviveClearLifecycleResolverCapabilityV1`、HUD/event bank wrapper 均采用private backing + getter-only header + caller-owned copy-out/capability；GDScript层的“独占”以Loading时源对象mutation-isolation测试与运行期无alias writer证明，不依赖不可移植的指针identity内省。teardown先原子置全部binding/view `valid=false`并推进generation，再断开引用；禁止形成RefCounted环。

所有`PlayerPhaseContextV1`的phase不适用payload统一以`null`表示unbound：`MOVEMENT_COMMIT`要求仅`movement_intent`非null；正常`DEFERRED_REMOVAL`要求七个phase-6 view/plan/output非null，且即使`has_resolution=false/has_recovery=false`也必须提供合法damage/recovery view；技术drain要求八个payload字段全部为null。禁止空壳RefCounted、`valid=false`对象或零值header冒充unbound。Player不得解引用当前phase要求为null的字段。

Player不复制 GameRoot top state。每次调用只使用 context 中的冻结值，并按 `schema/finite → battle/config/player identity → owner lifecycle → top_state → phase → lease → tick/revision → payload/header/capacity` 的 first-error precedence 校验。禁止路径的精确结果为：schema/缺参=`INVALID_ARGUMENT`，任一数值非finite=`NON_FINITE_INPUT`，配置/精确定容=`INVALID_CONFIG`，identity=`IDENTITY_MISMATCH`，owner/top state=`WRONG_STATE`，phase=`WRONG_PHASE`，lease=`PHASE_ERROR`，旧/重复/future tick=`STALE_TICK/DUPLICATE_TICK/CARRIER_INVALID`，其他payload/header=`CARRIER_INVALID`，容量=`CAPACITY_EXCEEDED`。首个错误后的所有 writer count 均为0。

消费者在 Loading 期注入只读 carrier/bank binding，不提供公共 `set_position`、`set_hp`、`respawn` 或即时Grid query接口。只读发布面由 `acquire_motion_view(expected_bank_id,expected_position_revision,expected_batch_authority_revision,out)`、GameRoot authority reader的`copy_player_hp_authority_into(expected_authority_revision,out:PlayerHpAuthorityViewV1)`、`acquire_hud_view(expected_authority_revision,out)`、`acquire_presentation_frame(expected_motion_bank_id,expected_position_revision,expected_authority_revision,out)` 与 `read_presentation_events(consumer_id,cursor,out)` 提供；它们不属于 mutation API，只把primitive/Vector2逐字段复制到caller-owned预定容out，不返回可写 backing或PackedArray alias。view 带 matching identity/generation/bank/revision/valid，teardown 先置 `valid=false` 并推进 view generation，再撤 reader 权与断开表现 consumer。

`PlayerStatus` 的V1集合精确包含：

`OK, OK_NOOP, INVALID_ARGUMENT, INVALID_CONFIG, NON_FINITE_INPUT, WRONG_STATE, WRONG_PHASE, PHASE_ERROR, STALE_TICK, DUPLICATE_TICK, IDENTITY_MISMATCH, CARRIER_INVALID, CAPACITY_EXCEEDED, POSITION_OUT_OF_RANGE, ID_EXHAUSTED`

错误lease返回`PHASE_ERROR`。不可逆复活journal尚未收敛或 convergence proof 不matching时调用teardown返回`WRONG_STATE`；GameRoot完成fault convergence后才能再次teardown。

仅 `OK/OK_NOOP` 属于成功类。

### Interactions with Other Systems

| 系统 | 输入PlayerController | PlayerController输出 | 权威边界 |
|---|---|---|---|
| GameRoot | phase、identity、lease、终局优先级 | status、motion commit、facts、defeat/revive intent | GameRoot拥有调度与顶层状态 |
| InputSystem | `MovementIntentCarrier` | 无回写 | Player只读，Input先执行 |
| Config/Stage | snapshot、有限world-domain、原点初始位置、足迹和移动参数 | 加载校验结果 | Stage拥有技术域，Player拥有足迹；不存在玩法arena或第二个出生点字段 |
| DamageSystem | `PlayerDamageResolutionV1` | HP变化、伤害/死亡fact | Damage算伤害，Player应用HP |
| EnemySystem | 已发布敌人位置、复活清除执行能力 | frozen clear selection | Enemy拥有实体生命周期 |
| DropSystem | 无 | 已提交玩家位置和拾取半径view | Drop调用DROP查询并提交拾取 |
| Weapon/Targeting | 无 | 已提交位置、朝向 | Weapon按攻击节奏索敌 |
| BattleUI | 无 | HP、替身符、存活状态只读快照 | UI不得回写 |
| SpatialGrid | 无直接调用 | 无 | Player不注册、不查询 |
| Object Pooling | 无 | 无 | 非直接依赖 |

#### 明确不在本系统范围

普攻按钮、闪避、冲刺、主动技能、自动攻击节奏、索敌评分、伤害公式、Buff、XP与升级、掉落入账、Enemy AI、对象池管理、Camera、HUD布局、Save、静态障碍、玩家击退、hit-stun、护盾、多角色和联机均不属于本次MVP PlayerController。

本轮已同步三项旧冲突：SpatialGrid的拾取/索敌caller改归Drop与Weapon/Targeting，Enemy自爆改为ENEMY查询加Player motion直接窄相，systems-index移除Player对SpatialGrid/Object Pooling的直接依赖。

## Formulas

### F1 — Fixed Movement Step

The `fixed_movement_step` formula is defined as:

`fixed_dt = 1 / physics_ticks_per_second`

`desired_velocity_f64 = is_active ? promote(direction_real_t32) × player_speed : (0.0,0.0)`

`desired_displacement_f64 = desired_velocity_f64 × fixed_dt`

`desired_displacement = Vector2(desired_displacement_f64)`，随后立即readback两个real_t32分量；F2只使用readback值。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Physics tick rate | `T` | int | MVP固定60 | GameRoot/Config权威值 |
| Fixed delta | `dt` | float64 | 固定`1/60` | 不读取callback delta |
| Player speed | `S` | float64 | MVP固定4.5 | 世界单位/秒 |
| Movement direction | `D` | real_t32 `Vector2` | ZERO或finite单位向量 | InputSystem输出的实际位值；计算前逐分量提升为float64 |
| Active flag | `A` | bool | true/false | 是否存在有效移动意图 |

**Output Range:** ZERO时速度/位移模长均为0；非ZERO方向允许Input契约长度容差`[0.999999,1.000001]`，故速度模长范围为`[4.4999955,4.5000045]`，单tick期望位移模长范围为`[0.074999925,0.075000075]`，每轴绝对值不超过`0.075000075`。只有canonical精确单位向量的期望位移模长才精确为0.075。

**Example:** 向右的float64数学结果为`velocity=(4.5,0)`、`displacement=(0.075,0)`；单位右上方向的数学分量约为`0.05303300858899106`。发布值必须以构造Godot `Vector2`后的real_t32 readback位值为准，测试不得要求这些十进制数学值逐bit相等。

`T≠60`、速度非finite或非正、active与方向状态不一致、方向非finite或超出上述单位向量容差时返回typed failure。PlayerController不得再次归一化方向。

### F2 — Full-Footprint World-Domain Guard

The `full_footprint_domain_guard` formula is defined as:

`player_radius = player_collision_diameter / 2`

`exact_legal_min = (-world_safe_half_extent + player_radius, -world_safe_half_extent + player_radius)`

`exact_legal_max = (+world_safe_half_extent - player_radius, +world_safe_half_extent - player_radius)`

`legal_min_rt = componentwise_real_t32_ceil(exact_legal_min)`

`legal_max_rt = componentwise_real_t32_floor(exact_legal_max)`

`raw_position_f64 = promote(previous_position_real_t32) + promote(desired_displacement_real_t32)`

`candidate_position = Vector2(raw_position_f64)`并立即readback

`valid = componentwise(candidate_position_readback >= legal_min_rt && candidate_position_readback <= legal_max_rt)`

若`valid=false`，返回`POSITION_OUT_OF_RANGE`且零提交；若true，`committed_position=candidate_position_readback`。不执行clamp。

`actual_displacement_f64 = promote(committed_position) - promote(previous_position_real_t32)`

`committed_velocity = Vector2(actual_displacement_f64 / fixed_dt)`并立即readback。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| World safe half extent | `H` | float64 | MVP 16384 | Stage V2权威技术上限，不是玩法边界 |
| Collision diameter | `d` | float64 | `0<d≤2H`；MVP调谐`[0.6,1.2]` | 圆形玩法足迹直径 |
| Previous position | `P` | real_t32 `Vector2` | 已通过domain guard | 上一位置bank实际位值 |
| Desired displacement | `Δ` | real_t32 `Vector2` | 数学模长0或约0.075 | F1 readback实际位值 |

`componentwise_real_t32_ceil/floor`继续使用既有Loading期IEEE-754 binary32 inward helper，确保可发布边界位值的完整足迹不越技术域。它只定义fail-fast合法性阈值，不授权运行时把位置钳到该值。Config的Stage F1 reachability proof必须保证正常合法局永远不触发此failure；一旦触发视为配置或实现故障，而不是“玩家撞墙”。

**Example:** `H=16384,d=0.8`时数学合法中心域为`[-16383.6,+16383.6]²`。从`(100,200)`向右移动提交完整readback结果；不存在22×40边界。若恶意fixture从canonical最大边界继续向外，返回`POSITION_OUT_OF_RANGE`，不发布clamped位置。

`d`非finite/非正、合法域反转、旧权威位置已越域或任一派生值非finite时失败且零提交。`d=0.8`为灰盒基准，不是已验证的生产值。

### F3 — HP Application and Lethal Check

The `hp_application` formula is defined as:

```text
if final_damage >= current_hp:
    applied_damage = current_hp
    hp_after_damage = 0.0
    lethal = true
else:
    applied_damage = final_damage
    hp_after_damage = current_hp - final_damage
    lethal = false
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Maximum HP | `Hmax` | float64 | `[1,1,000,000]` | Player authority；基础值当前为100 |
| Current HP | `H` | float64 | ALIVE时`0<H≤Hmax` | 当前权威HP |
| Final damage | `X` | float64 | finite且`X≥0` | DamageSystem稳定聚合后的最终批次 |

**Output Range:** `applied_damage∈[0,H]`、`hp_after_damage∈[0,H]`；`lethal`为bool。DAMAGE fact记录`applied_damage`，不记录overkill。

**Example:** `H=25,X=7.5`得到`17.5 HP`且非致命；`H=25,X=40`得到`applied_damage=25`、`HP=0`且致命。

HP权威类型固定为`float64`，玩法层不取整。负数、NaN、Infinity、非法HP不变量或错误authority revision均返回`CARRIER_INVALID`并保持HP、facts和替身符不变。必须先比较再相减，避免巨大finite伤害产生负无穷。

`final_damage=0` 时HP不变、不写DAMAGE fact并返回`OK_NOOP`。若`final_damage>0`但`current_hp-final_damage`与`current_hp`逐bit相同，则返回`CARRIER_INVALID`且零写，不引入隐藏的运行时最小伤害修正。

### F3A — Starting Maximum HP

`resolved_starting_max_hp = base_max_hp × (1 + progression_max_hp_bonus_ratio + preparation_max_hp_bonus_ratio)`

其中MVP功法树输入固定为`progression_max_hp_bonus_ratio=0.03×long_chun_level`，`long_chun_level∈{0,1,2,3,4,5}`；战前锻体丹输入固定为`preparation_max_hp_bonus_ratio∈{0,0.15}`。Config在BATTLE_LOADING按上述顺序用float64计算并验证所有输入/中间值finite、结果位于`[1,1,000,000]`，再把结果作为本局冻结的`max_hp`；Player不在Active重算或接受热改。

**Progression Tree static propagation（2026-09-03）**：matching `ProgressionBattleProjectionV1`在battle bind时另提供`longchun_charge_count∈{0,1}`、threshold 0.30与recovery ratio 0.10。Player不检测低血条件；Damage返回matching `LONGCHUN_EMERGENCY` recovery resolution与consume token后，Player在phase6把实际HEAL应用与charge 1→0同一authority transaction提交。致命批次不触发/不消费，恰30%不触发，revive不重置charge；当前receipt/phase6 fault matrix尚未版本化，integration保持BLOCKED。

**掌天瓶 static propagation（2026-09-03）**：锻体丹只通过matching `ZhangtianBattleProjectionV1`令`player_preparation_max_hp_bonus_ratio=0.15`，与长春`0.03L`在Loading按既有`player_resolved_starting_max_hp`相加；Player初始化时令current=max并在Active中保持snapshot不可变。聚气/明心不直接写Player authority；reservation/runtime接线未验证前保持BLOCKED。

### F3B — Recovery Application

```text
if lethal:
    applied_recovery = 0.0
    hp_after_recovery = hp_after_damage
else:
    recovery_room = max_hp - hp_after_damage
    applied_recovery = min(final_recovery, recovery_room)
    hp_after_recovery = hp_after_damage + applied_recovery
```

`final_recovery`必须finite且`≥0`，matching `PlayerRecoveryResolutionV1`绑定同一battle/config/tick/source authority。Player固定先执行F3，再执行本式；致命批次恢复被抑制且不得结转。只有`applied_recovery>0`才写一条canonical `HEAL` fact，其`value_f64=applied_recovery`；非致命同tick伤害与恢复均生效时，fact顺序固定为DAMAGE后HEAL，最终HP/HUD只发布一次。满血恢复与0恢复均不产生HEAL fact。

### F4 — Talisman HP Restoration

The `talisman_restore_hp` formula is defined as:

`revive_hp = max_hp_at_source_revision × REVIVE_HP_RATIO`

`next_revive_generation = checked_add(revive_generation, 1)`

其中`REVIVE_HP_RATIO=0.35`。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Source-revision max HP | `Hsrc` | float64 | `[1,1,000,000]` | Damage批次绑定authority revision中的最大HP |
| Restore ratio | `Rhp` | float64 | 固定0.35 | MVP替身符恢复比例 |
| Revive generation | `G` | int64 | `[0,INT64_MAX-1]` | 本局复活代次 |

**Output Range:** `revive_hp∈[0.35,350000]`；generation精确增加1。

**Example:** `max_hp=100`时恢复35；`max_hp=137.8`时玩法数学值为48.23，不做floor、ceil或四舍五入。HUD可只读取整显示，但不得回写权威HP。

仅当`lethal && talisman==AVAILABLE && !FATAL && !VICTORY`时执行。公式结果先写入已arm但不可见的inactive authority bank，matching phase-6 publish才使HP、代次与`SPENT`同时可见。比例漂移、source revision不匹配、乘积非finite或generation耗尽均在消费替身符前失败。

### F5 — Seventeen Fixed Revive Candidates

The `revive_candidate_position` formula is defined as:

`raw_candidate_i = death_position + revive_relocation_radius × ring_multiplier_i × direction_i`

`candidate_i = readback_real_t32(Vector2(raw_candidate_i))`

每个slot随后执行F2同一完整足迹world-domain guard；任一slot越域均在PONR前以`POSITION_OUT_OF_RANGE`终止整个计划，不clamp、不wrap、不丢弃该slot。

固定方向ABI为：

| Index | Direction |
|---:|---|
| 0 | `(0,0)` |
| 1 / 9 | 右 `(1,0)` |
| 2 / 10 | 右上 `(INV_SQRT2,-INV_SQRT2)` |
| 3 / 11 | 上 `(0,-1)` |
| 4 / 12 | 左上 `(-INV_SQRT2,-INV_SQRT2)` |
| 5 / 13 | 左 `(-1,0)` |
| 6 / 14 | 左下 `(-INV_SQRT2,INV_SQRT2)` |
| 7 / 15 | 下 `(0,1)` |
| 8 / 16 | 右下 `(INV_SQRT2,INV_SQRT2)` |

`INV_SQRT2=0.7071067811865476`；`ring_multiplier_0=0`、`ring_multiplier_1..8=1`、`ring_multiplier_9..16=2`。索引和倍率均为ABI，不得配置重排。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Death position | `Pd` | Vector2 | F2技术安全中心域 | 本tick致命位置 |
| Relocation radius | `Rmove` | float64 | 灰盒`[1.5,3.0]`，基准2.0 | 附近候选距离 |
| Candidate direction | `Ui` | Vector2 | 中心+两组固定八方向 | index是稳定ABI |
| Ring multiplier | `Mi` | int | `0/1/2` | 中心、内圈、外圈固定倍率 |
| Collision radius | `r` | float64 | F2合法域 | 用于完整足迹domain guard |

**Output Range:** 精确产生17个slot，每个都位于F2技术安全中心域。candidate workspace容量必须精确为17；real_t32 readback后重复候选合法，禁止动态去重或改变index。

**Example:** `d=0.8`、`Rmove=2.0`、死亡点`(10.5,19.5)`时，全部候选按原方向落在该点附近并参与评分；不会因为旧22×40 arena把右侧候选挤到同一条边界。

半径或死亡位置非finite、乘加溢出、real_t canonicalization失败时候选发布数为0，HP、位置和替身符均不改变。`Rmove=2.0`是灰盒基准，不是生产验证结果。

### F6 — Normal Enemy Clear Predicate

The `revive_clear_predicate` formula is defined as:

`prospective_distance_sq_ij = (enemy_center_j.x-candidate_i.x)² + (enemy_center_j.y-candidate_i.y)²`

`required_separation_j = player_radius + enemy_shape_bound_j`

`prospective_clear_ij = enemy_class_j==NORMAL && prospective_distance_sq_ij<=required_separation_j²`

`committed_clear_j = prospective_clear_selected_index,j`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Enemy center | `E` | Vector2 | finite合法世界坐标 | Enemy本tick committed center |
| Candidate / selected position | `Pi/Psel` | Vector2 | F2技术安全中心域 | 评分时逐候选计算；提交时只冻结F7选中项 |
| Player radius | `r` | float64 | F2合法域 | 玩家圆形玩法足迹半径 |
| Enemy shape radius | `Bj` | float64 | finite且`≥0` | 对clear-eligible NORMAL必须是`shape_code=CIRCLE`的实际玩法圆半径；对只参与评分的ELITE/BOSS可为保守bound |
| Enemy class | `K` | enum | NORMAL/ELITE/BOSS | 敌人分类 |

**Output Range:** 每个`candidate×enemy`得到一个prospective bool；F7选中候选后，每个敌人得到一个committed bool，清除集合数量`[0,300]`。只有NORMAL可能为true，距离边界采用闭集语义。

**Example:** `Psel=(0,0)`、`r=0.4`、NORMAL的`Bj=0.6`时，中心距`1.0`会因相切被清除，中心距`1.0001`保留；Elite/Boss即使与玩家中心重合也不会被清除。

任何非法足迹、bound、坐标、分类、平方溢出或容量不足都必须在`revive_point_of_no_return`前使整个计划失败，不得保留部分清除集合。300只验证clear workspace容量，不改变该几何谓词。

### F7 — Revive Threat Score and Selection

The `revive_threat_score` formula is defined as:

`required_separation_j = player_radius + enemy_shape_bound_j`

`enemy_surface_clearance_ij = sqrt(distance_sq(candidate_i,enemy_j)) - required_separation_j`

`enemy_next_tick_required_separation_j = player_radius + enemy_next_tick_swept_bound_j`

`circle_hazard_clearance_ik = sqrt(distance_sq(candidate_i,hazard_center_k)) - (player_radius + hazard_radius_k)`

`exterior_hazard_clearance_ik = hazard_radius_k - (sqrt(distance_sq(candidate_i,hazard_center_k)) + player_radius)`

`hazard_surface_clearance_ik = select_by_shape_code(circle_hazard_clearance_ik,exterior_hazard_clearance_ik)`

候选评分只考虑该候选对应的`prospective_clear_ij=false`敌人：

`score_i = min(enemy_surface_clearance_ij, enemy_next_tick_surface_clearance_ij for every surviving enemy j, hazard_surface_clearance_ik for every hazard active on checked_next_tick)`

先计算`checked_next_tick=checked_add(tick_revision,1)`；耗尽返回`ID_EXHAUSTED`且发生在PONR前。选择总序固定为：

1. safety rank：`SAFE_UNCONSTRAINED > SAFE > UNSAFE_FALLBACK`；Enemy与`EXTERIOR_CIRCLE`净空`≥0`安全，`CIRCLE`净空必须`>0`（相切算危险）；所有约束均安全才为`SAFE`；
2. 同一`SAFE`或`UNSAFE_FALLBACK`内，以finite float64数值比较，score较大者优先；禁止把IEEE-754原始bit pattern作有符号或无符号整数排序；`SAFE_UNCONSTRAINED`之间跳过score；
3. safety rank相同且score在规范化`-0.0→+0.0`后逐bit相等（或均无约束）时，`prospective_clear_count`较小者优先，避免在不牺牲安全/净空时无必要清怪；
4. 上述仍相等时candidate index较小者优先；每次clearance先把`-0.0`规范化为`+0.0`；
5. 若17个候选全部未通过shape-aware安全谓词，仍按最大score、较小clear count、较小index选择并标`UNSAFE_FALLBACK`，不附加无敌；CIRCLE相切导致score=0也属于本分支。

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Candidate position | `Pi` | Vector2 | 17个F5候选之一 | 被评分位置 |
| Enemy position | `Ej` | Vector2 | finite合法世界坐标 | 已发布敌人中心 |
| Enemy bound | `Bj` | float64 | finite且`≥0` | EnemyConfig保守形状半径 |
| Enemy next-tick swept bound | `Bnextj` | float64 | finite且`≥Bj` | 以本tickcenter为圆心、覆盖敌人下一tick所有合法center的保守半径；由Enemy owner发布 |
| Player radius | `r` | float64 | F2合法域 | 玩家圆形足迹半径 |
| Prospective clear predicate | `Qij` | bool | F6逐候选输出 | 若最终选择该候选，该普通敌人是否会被清除 |
| Hazard position/radius/shape | `Hk/Rhk/Sk` | Vector2/float64/enum | next-tick active且finite | `ReviveHazardSnapshotV2`；CIRCLE圆内危险，EXTERIOR_CIRCLE圆外危险；hazard永不被清除 |

**Output Range:** `selected_index∈[0,16]`，`revive_safety_class∈{SAFE,SAFE_UNCONSTRAINED,UNSAFE_FALLBACK}`。score为各shape signed clearance最小值；CIRCLE相切仍危险，EXTERIOR_CIRCLE的0表示完整足迹恰好位于安全圆内。它不承诺对未登记攻击或更晚tick安全。

**Example:** `r=0.4`。候选0附近与玩家足迹重叠的NORMAL会被清除；剩余Boss距候选0为2、bound为0.8，则`score0=2-(0.4+0.8)=0.8`。候选1与该Boss重合时`score1=0-1.2=-1.2`，因此选择候选0。

不得用Infinity作为热路径初始化值；使用`has_constraint`标志处理首个survivor/hazard及无约束候选。所有零score先canonicalize为`+0.0`。输入物理顺序变化不得改变结果。扫描复杂度固定为`17×N_enemy×2 + 17×N_hazard + N_enemy`（每敌人current+swept两次净空）；选中项clear identities复制到预分配workspace后，使用固定容量原地binary insertion sort按`{enemy_id,object_instance_id,spatial_handle_id,borrow_id}`升序总序重排四字段row。算法只允许primitive比较与标量row move，不用Array/Callable/native sort；`n≤300`时comparison与row-move各自硬上界为`n(n-1)/2=44,850`，每个row move固定复制4个int64字段，counter分别记录comparison、row move与primitive field write。

## Edge Cases

### A. 输入、移动与技术域

- **If 正常tick收到 inactive + ZERO**：速度与位移为ZERO，位置和朝向不变；仍发布一次零位移motion bank并推进revision。
- **If active + 合法单位方向且未触边**：按F1/F2提交，不加速、不平滑、不二次归一化。
- **If inactive但方向非ZERO，或active但方向为ZERO**：返回`CARRIER_INVALID`，位置bank、Node transform、朝向和revision均零写。
- **If 方向含NaN/Infinity**：返回`NON_FINITE_INPUT`，不得先进入ZERO、clamp或normalize分支。
- **If 方向模长超出`1±1e-6`**：返回`CARRIER_INVALID`；容差内按原向量计算。
- **If 玩家在正常可达范围持续朝任意方向移动**：每tick提交完整F1位移，不存在arena法向截断、沿边滑行或隐藏方向修正。
- **If raw position精确等于技术安全域canonical边界**：该点合法并原值提交，不加epsilon；该fixture只用于故障边界测试，不代表正常玩法可达。
- **If raw position越过技术安全域或previous committed position已越域**：返回`POSITION_OUT_OF_RANGE`并进入统一fault；禁止用本tick clamp、wrap或传送修复历史漂移。
- **If gameplay root rotation/scale漂移或Node transform被外部改写**：触发contract fault；不得用Node值覆盖权威位置。
- **If碰撞直径非法或不在MVP manifest范围**：BATTLE_LOADING返回`INVALID_CONFIG`，不得回退到0.8默认值。
- **If首tick输入为ZERO**：位置保持世界安全域原点，朝向保持初始化的`Vector2.DOWN`。

### B. Identity、tick、phase与carrier

- **If任一carrier的battle/config/player identity不匹配**：返回`IDENTITY_MISMATCH`，motion、facts、journal、HP、符和Node均零写。
- **If输入tick早于期望值**：返回`STALE_TICK`；等于已消费tick返回`DUPLICATE_TICK`；晚于期望tick返回`CARRIER_INVALID`，不得跳tick。
- **If调用phase不在PLAYER manifest或不等于GameRoot当前phase**：返回`WRONG_PHASE`。
- **If lease不是当前matching lease**：返回`PHASE_ERROR`，不得读取或改写payload。
- **If两个motion bank共享对象/backing、bank ID非法或schema/capacity漂移**：初始化返回`INVALID_CONFIG`，运行时返回`CARRIER_INVALID`，不得swap。
- **If position revision递增将溢出int64**：返回`ID_EXHAUSTED`，不得复用旧revision。
- **If Damage、Recovery或Enemy snapshot revision与本tick绑定revision不一致**：返回`CARRIER_INVALID`，不得以“最新snapshot”替换预期snapshot。
- **If新局收到上一局carrier**：即使tick/config数值碰巧相同，也因battle identity不同被拒绝。

### C. Damage、Recovery与HP

- **If本tick没有PlayerDamageResolution且没有PlayerRecoveryResolution**：`DEFERRED_REMOVAL`返回`OK_NOOP`，HP、符、life和facts均零写。
- **If本tick只有matching recovery resolution**：按F3B应用并发布最终HP/HUD；实际恢复量大于0时写一条HEAL fact，否则`OK_NOOP`且不publish。
- **If final damage为0**：HP不变，不写DAMAGE fact。
- **If `0<damage<current_hp`**：提交一条DAMAGE fact，HP精确减去该值，其他玩家状态不变。
- **If `damage==current_hp`**：精确判为致命，不使用epsilon。
- **If damage大于current HP**：applied damage只记current HP；overkill不进入fact，也不穿透复活后的35% HP。
- **If正伤害因float64精度导致相减后HP逐bit不变**：返回`CARRIER_INVALID`，不写fact或HP。
- **If damage为负、NaN、Infinity，或HP不变量非法**：返回`CARRIER_INVALID`，所有伤害、复活和清除效果均为0。
- **If同tick有多个hit**：DamageSystem必须先聚合为一个batch；Player只消费一次，不逐hit触发替身符。
- **If同tick出现第二个damage batch或重复token**：不得合并或覆盖；按duplicate/token规则拒绝并由GameRoot收敛首个已提交事实。
- **If非致命damage与recovery同tick**：固定先damage后recovery；若两者均实际改变HP，则DAMAGE fact在HEAL fact之前，最终HP/HUD只publish一次。
- **If recovery超过缺失HP**：实际恢复量clamp为`max_hp-hp_after_damage`，HEAL fact只记录clamp后的量；满血或0恢复不写fact。
- **If damage致命且同tick有recovery**：恢复量固定为0且不结转；后续按VICTORY/REVIVE/DEFEAT规则处理，恢复不得救命或穿过替身符。
- **If recovery为负、NaN、Infinity、header stale或第二个recovery batch**：在任何HP/fact/HUD写入前失败，不使用“最新”bank替换matching token。
- **If战前maxHP修正输入非法、F3A中间值非finite或结果越界**：BATTLE_LOADING失败；不得回退base=100，也不得在Active中修正或热改。
- **If life已经是`DEATH_LATCHED`仍收到普通damage或movement调用**：返回`WRONG_STATE`，不得重复发DEATH、DEFEAT或REVIVE。

### D. Fatal、Victory、Revive、Defeat与Pause

- **If phase-6 side effect前已经存在FATAL**：不应用本批玩家玩法效果、不消费符、不建立清除计划，进入技术终止。
- **If FATAL发生在本batch不可逆点后**：保留已提交journal/facts，执行唯一fault-convergence authority publish，结果为`TECHNICAL_ABORT`。
- **If无FATAL且VICTORY与致命伤同时成立**：HP归0，保留DAMAGE和DEATH事实，outcome为VICTORY；替身符保持AVAILABLE，不执行复活或暂停UI。
- **If无FATAL/VICTORY且致命、符为AVAILABLE**：提交DAMAGE并执行一次复活；DEATH fact和defeat intent均为0。
- **If无FATAL/VICTORY且致命、符为SPENT**：HP归0，提交DAMAGE和DEATH，latch唯一DEFEAT。
- **If非致命伤与pause同tick**：先完成本tick伤害与HP提交，再在phase 7暂停；技术drain不得重放伤害。
- **If复活与pause同tick**：先完整提交复活，随后保留并执行pause reason；Paused UI读取复活后的HP、符和位置。
- **If DEFEAT或VICTORY与pause同tick**：终局结果胜出，pause reason不展示为pause UI。
- **If复活后的下一完整玩法tick再次受到致命伤**：符已SPENT，直接走DEFEAT；不存在隐藏无敌tick。
- **If normal outcome已经seal后cleanup/Save再故障**：不修改VICTORY/DEFEAT，只更新独立completion fault。

### E. 十七点候选与评分

- **If Enemy与next-tick hazard snapshot均为空**：17个候选均为`SAFE_UNCONSTRAINED`，选择index 0，即readback后的死亡点。
- **If real_t32量化使多个候选位置相同**：仍保留全部17个slot，不动态去重；相同位置取最小index。
- **If十七个候选score全部小于0**：按最大surface-clearance score、较小`prospective_clear_count`、较小index依次选择，tuple标记`UNSAFE_FALLBACK`，无隐藏无敌。
- **If存在对清场后敌人与next-tick hazards均为非负净空的候选**：`SAFE`候选优先于所有负分候选；同类内依次比较score、`prospective_clear_count`、index。
- **If score为`-0.0`**：先规范化为`+0.0`再比较。
- **If两个候选safety rank相同且score数值相等**：先取`prospective_clear_count`较小者，再取较小index；只接近但不相等时取数值更大者，不使用epsilon。
- **If Enemy或hazard snapshot物理遍历顺序变化但逻辑集合不变**：全部score和最终index必须相同。
- **If十七点因real_t32量化出现重复位置**：重复slot仍各自评分，完全同序时较小index胜出；不去重、不扩大半径、不生成第18个点。
- **If候选、迁移半径、敌人/hazard坐标或bound发生非finite/overflow**：在不可逆点前abort，玩家、符、敌人和facts均零effect。
- **If Elite/Boss与所有候选重叠**：它们始终作为survivor参与评分且永不清除；仍按最大score位置复活。
- **If next-tick hazard覆盖所有候选**：hazard始终参与评分且不可被清场；选择`UNSAFE_FALLBACK`并从下一完整tick正常承受hazard效果。

### F. 普通敌人清除

- **If NORMAL与复活后玩家圆形足迹重叠或相切**：进入清除集合；表面净空为正则保留，不使用epsilon扩圈。
- **If Elite/Boss与玩家足迹重叠甚至中心重合**：仍不清除、不伤害、不降级class。
- **If NORMAL仅因替身符被清除**：使用稳定`REVIVE_CLEAR`原因；不生成kill、XP、drop、reward、record或DEATH fact。
- **If同一NORMAL同时正常死亡和被复活清除选中**：只保留一条lifecycle row，正常死亡语义优先，其合法奖励事实保留且不重复。
- **If清除集合或Enemy snapshot出现重复identity**：返回`CARRIER_INVALID`，不得运行时随意去重。
- **If计划冻结后迟到callback试图修改class、位置或计划**：callback写入为0；revision漂移按不可逆点前abort或点后fault convergence处理。
- **If 300个NORMAL被装入容量压力fixture**：只有与最终玩家足迹真实重叠/相切的行进入clear集合；300不得被解释为production清场数量目标，2 Elite与1 Boss始终保留并参与评分。
- **If任一NORMAL缺少冻结shape bound**：PlayerConfig/Enemy snapshot不得标production-ready，也不得以默认清除半径替代实际足迹判定。

### G. 容量与不可逆故障

- **If候选容量不等于17、Enemy snapshot容量不等于303、clear workspace容量不等于300、PLAYER fact容量不等于2，或hazard容量不等于Config冻结的`revive_hazard_capacity`**：BATTLE_LOADING返回`INVALID_CONFIG`；required−1和required+1均失败。
- **If运行时敌人数超过303、hazard数超过冻结容量、清除需求超过300或所需fact超过2**：在不可逆点前返回`CAPACITY_EXCEEDED/CARRIER_INVALID`并进入故障。
- **If revive或position generation将溢出**：在arm前返回`ID_EXHAUSTED`，不得wrap。
- **If `Phase6AuthorityBatchPlanV1/ViewV1`的copy、header、manifest或identity验证失败**：journal、facts、remove和authority publish均为0。
- **If全部preflight成功**：先冻结并canonical sort完整clear列表、reserve非零DAMAGE row，再arm复活tuple；禁止边扫描边remove。
- **If DAMAGE fact尚未进入COMMITTED时失败**：无论clear count是否为0都abort计划，所有玩法效果为0。
- **If DAMAGE fact首次进入COMMITTED**：无论clear count是否为0，该瞬间统一成为`revive_point_of_no_return`；随后才按已预留row的完整lifecycle tuple总序推进clear rows。
- **If不可逆点后第N项操作失败**：已提交row单调收敛，旧handle不复活，未开始row不执行；已arm玩家复活tuple与已提交事实通过唯一authority publish公开，随后TECHNICAL_ABORT。
- **If同一token或row再次执行**：exact-once gate使side effect为0，不重复remove、release、消费符或推进generation。

### H. Pause、Resume、Teardown与跨局

- **If本tickmovement已在phase 2提交后phase 7才latch pause**：该次movement保留，不回滚。
- **If PAUSE_PENDING技术drain调用Player**：验证state/phase/lease后返回`OK_NOOP`；不推进position revision、HP、符或复活计划。
- **If在Paused、Resume、Ending或Fault直接调用普通Player phase**：返回`WRONG_STATE`，玩法效果为0。
- **If resume后首个正常tick没有fresh OS press**：Input carrier为ZERO；Player发布一次零位移bank，不重放暂停前方向。
- **If resume收到暂停前旧generation/tick的非ZERO carrier**：返回`STALE_TICK`或identity错误并进入统一故障。
- **If teardown发生在不可逆点前的PREPARED事务**：abort staging后teardown，玩家与敌人玩法效果为0。
- **If teardown发生在不可逆点后且journal尚未收敛**：返回`WRONG_STATE`；GameRoot必须先完成fault convergence，再重新teardown。
- **If matching teardown重复调用**：返回`OK_NOOP`且不重复释放；TERMINATED后initialize/run_phase均返回`WRONG_STATE`。
- **If新局初始化**：使用新controller和battle identity，HP=max、符=AVAILABLE、revive generation=0、位置为world safe domain原点、朝向为DOWN。
- **If上局迟到damage、clear completion、Node callback或UI写入到达新局**：identity guard拒绝，对当前局权威写入次数为0。

## Dependencies

### Direct Upstream Dependencies

| System | Strength | Interface consumed by PlayerController | Current status |
|---|---|---|---|
| GameRoot & Scene Flow | Hard | battle/config identity、七阶段调度、phase lease、authority/fact/journal banks、终局与pause仲裁 | Re-review Pending |
| InputSystem | Hard | 本tick只读`MovementIntentCarrier`；在`MOVEMENT_COMMIT`中先于Player执行 | Re-review Pending |
| Config/Data System | Hard | immutable PlayerConfig、participant manifest、owner容量贡献、carrier容量与identity | Re-review Pending |
| Stage & Map | Hard | `StageWorldDomainViewV2`有限安全域与reachability proof；Player初始位置为域原点，Camera读取已发布motion跟随 | Re-review Pending |
| DamageSystem | Hard, provisional | 预分配`PlayerDamageResolutionV1`，包含稳定聚合后的最终伤害、source authority revision、伤害来源和死亡原因 | 尚无GDD |
| DamageSystem / PlayerRecoveryResolver | Hard, Full Review Pending | phase-5预分配`PlayerRecoveryResolutionV1`，稳定聚合Longchun/Buff/RiskChoice typed recovery intent | `design/gdd/damage-system.md` Designed；待独立full review |
| EnemySystem | Hard for talisman, provisional | 本tick已发布敌人position/class/bound快照；执行冻结的`REVIVE_CLEAR` lifecycle计划 | In Review |
| ReviveHazard producer | Hard for talisman, provisional | next-tick会伤害玩家的保守hazard位置、bound与active tick窗口 | owner/GDD未冻结 |

DamageSystem已作为唯一PlayerRecoveryResolver完成作者设计，冻结伤害/恢复来源的排序与聚合公式；其独立full review与后续Projectile/Weapon/Boss容量回填仍未完成，因此本GDD的运行时集成仍保持BLOCKED。

#### Provisional `PlayerDamageResolutionV1`

在 DamageSystem GDD 冻结前，最小row schema为：

`PlayerDamageResolutionV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,tick_revision:int64,source_authority_revision:int64,player_id:int64,resolution_bank_id:int32,resolution_publish_revision:int64,final_damage:float64,damage_reason_code:int32,death_reason_code:int32}`。

发布容器固定为`PlayerDamageResolutionBankV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,bank_id:int32,publish_revision:int64,row_count:int32,has_resolution:bool,row:PlayerDamageResolutionV1}`的A/B两bank与单一selector。`row_count∈{0,1}`且必须等于`has_resolution?1:0`；无伤害时row count为0、row内容不可读，不能用一条`final_damage=0`伪造presence。两个bank在Loading期分配且backing identity不同，producer只写inactive bank，完整校验后一次切selector。

- 幂等identity只使用GameRoot canonical `ResolutionPublishTokenV1={battle_instance_id,resolution_bank_id,source_authority_revision,tick_revision,resolution_publish_revision}`；Player row逐字段复制该tuple，不创建scalar token或第二个identity。
- DamageSystem唯一生产并发布该resolution；PlayerController只消费matching row，不修改它。
- PlayerController负责把实际应用的非零damage提交为runtime DAMAGE fact；未被复活吸收的致命批次再提交DEATH fact，`producer_role_id=PLAYER`。
- DamageSystem仍拥有damage/death reason稳定码与RunOutcome中DAMAGE-owned字段的最终投影；不得为同一runtime事实再创建第二条Player fact。
- 相同resolution token第二次消费为duplicate/no-effect；错误identity、revision、schema或非finite damage返回精确failure且Player零写。

#### Provisional `PlayerRecoveryResolutionV1`

在恢复resolver owner GDD冻结前，最小row schema为：

`PlayerRecoveryResolutionV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,tick_revision:int64,source_authority_revision:int64,player_id:int64,recovery_bank_id:int32,recovery_publish_revision:int64,final_recovery:float64,recovery_reason_code:int32,recovery_source_mask:int64}`。

发布容器固定为`PlayerRecoveryResolutionBankV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,bank_id:int32,publish_revision:int64,row_count:int32,has_recovery:bool,row:PlayerRecoveryResolutionV1}`的A/B两bank与唯一selector。`row_count=has_recovery?1:0`，两个bank在Loading期分配且backing identity不同；producer在phase 5稳定聚合typed intent，只写inactive bank，完整校验后切一次selector。Player只消费matching battle/config/tick/source-authority row；重复token无effect，错误header、负值或非finite恢复使Player在任何HP/fact/HUD写入前失败。RiskChoice在Paused期间只能冻结intent，恢复不得在Paused生效；其首个合法消费点是resume后的第一个Active deferred batch。

恢复幂等identity固定为`RecoveryPublishTokenV1={battle_instance_id:int64,recovery_bank_id:int32,source_authority_revision:int64,tick_revision:int64,recovery_publish_revision:int64}`；row逐字段复制该tuple。Player在HP应用前把完整token复制到私有`consumed_recovery_token`，相同token二次消费为`OK_NOOP`，跨battle、错bank、错authority、错tick或错publish revision均在任何写入前失败；不得把damage `ResolutionPublishTokenV1`或单一scalar revision复用为恢复identity。

#### Provisional `EnemyThreatSnapshotV1`

替身符选点所需最小bank schema为：

`EnemyThreatSnapshotV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,bank_id:int32,publish_revision:int64,tick_revision:int64,authority_revision:int64,count:int32,capacity:int32,enemy_ids:PackedInt64Array,object_instance_ids:PackedInt64Array,spatial_handle_ids:PackedInt64Array,borrow_ids:PackedInt64Array,centers:PackedVector2Array,class_codes:PackedInt32Array,shape_codes:PackedInt32Array,bound_radii:PackedFloat64Array,next_tick_swept_bound_radii:PackedFloat64Array}`。

- 两个snapshot bank与单一selector在Loading定容；`0≤count≤capacity=303`，九个parallel array长度精确为303并跨tick复用，Active禁止resize、append、duplicate或替换backing。
- `[0,count)`中`{enemy_id,object_instance_id,spatial_handle_id,borrow_id}`构成完整lifecycle identity，字段必须非零且tuple唯一；每行position finite、class属于`NORMAL/ELITE/BOSS`、bound finite且非负。
- MVP所有NORMAL必须`shape_code=CIRCLE`，且`bound_radii`逐bit等于其实际玩法碰撞圆半径；否则battle load失败，Player不得用保守外接圆造成非真实clear。`next_tick_swept_bound_radii`以当前center为圆心，至少等于`bound_radii + max_center_displacement_next_tick`并覆盖下一tick所有合法center；NORMAL/ELITE/BOSS均用它参与F7安全评分，只有当前实际`bound_radii`参与clear。任一swept bound小于current bound或producer无法证明上界时battle load失败。
- 物理存储顺序不构成玩法契约；Player将选中项的完整identity复制进容量300的预分配workspace，再按`{enemy_id,object_instance_id,spatial_handle_id,borrow_id}`完整tuple升序执行固定原地canonical sort。评分与结果必须对输入排列不敏感；不要求`enemy_id`单字段唯一。
- snapshot必须matching本battle/config/tick/authority revision；Player不得用更新或更旧snapshot代替expected row。
- EnemySystem正式GDD修订后必须反向接纳或版本化替换此provisional schema。

#### Versioned `ReviveHazardSnapshotV2`

next-tick安全评分所需最小bank schema为：

`ReviveHazardSnapshotV2={schema_version=2,battle_instance_id:int64,config_snapshot_id:int64,bank_id:int32,publish_revision:int64,tick_revision:int64,authority_revision:int64,count:int32,capacity:int32,hazard_ids:PackedInt64Array,shape_codes:PackedInt32Array,centers:PackedVector2Array,bound_radii:PackedFloat64Array,active_tick_from:PackedInt64Array,active_tick_through:PackedInt64Array}`。

- A/B bank、selector与全部parallel array在Loading按Config给出的精确`revive_hazard_capacity`定容；该容量的producer预算尚未冻结，因此复活production集成保持`BLOCKED-HAZARD-CONTRACT`，Player不得自定任意默认容量。
- Player先以checked add生成`checked_next_tick=tick_revision+1`；耗尽在PONR前返回`ID_EXHAUSTED`。仅`active_tick_from≤checked_next_tick≤active_tick_through`的行进入F7；每个hazard identity非零且唯一，shape只允许CIRCLE/EXTERIOR_CIRCLE，center/bound finite，`bound≥0`，tick窗口合法。
- CIRCLE使用“圆内/相切危险”，EXTERIOR_CIRCLE使用“玩家完整足迹越出安全圆才危险”。snapshot不授权Player清除、停用或改写hazard；Boss毒域必须用EXTERIOR_CIRCLE，Projectile swept危险用CIRCLE。V1或unknown shape fail closed。

### Direct Downstream Dependents

| System | Data received from PlayerController | Ownership boundary |
|---|---|---|
| DropSystem | committed player position | pickup radius由PlayerStats/Progression/Config提供；Drop调用SpatialGrid DROP circle query并提交拾取 |
| Weapon/TargetingSystem | committed position、朝向、player identity | Weapon按攻击节奏调用ENEMY nearest query |
| RiskChoiceSystem | 玩家存活状态与位置只读view | RiskChoice只提交typed recovery intent，不得直接改HP或位置 |
| Leveling/XP | 玩家identity与下一局Config最大HP修正输入 | 升级规则归Leveling；Active无maxHP更新API，永久增益只经下一局Config生效 |
| BattleUI | HP/maxHP、存活、替身符、revive generation只读snapshot | UI只展示，不持有或回写权威状态 |
| GameRoot | participant status、DAMAGE/HEAL/DEATH facts、REVIVE/DEFEAT intent | GameRoot拥有顶层状态、terminal oracle与authority publish |

### Indirect and Transitive Dependencies

- SpatialGrid不是PlayerController直接依赖。Player不注册Grid、不持有SpatialHandle、不执行circle或nearest query。Drop、Weapon、Damage、Enemy分别按各自职责调用Grid。
- Object Pooling不是PlayerController直接依赖。玩家本局保持单一identity；替身符复用当前Player，不进行borrow/release。
- Progression Tree通过战前Config snapshot提供永久最大HP修正；Active中不得直接热改PlayerConfig。Longchun/Buff/RiskChoice的战斗内恢复只走唯一PlayerRecoveryResolver（DamageSystem）。
- ProjectileSystem、BuffSystem和SkillDraftSystem可能间接影响Damage或Weapon，但不得绕过对应owner直接写Player。

### Required Manifest and Capacity Contracts

`RequiredParticipantManifest` actual row必须逐字段为：

`{participant_id=PLAYER,role_id=PLAYER,stable_order=2,allowed_phases={MOVEMENT_COMMIT,DEFERRED_REMOVAL},allowed_success_statuses={OK,OK_NOOP},owner_contract_id=PlayerController/v1,owner_gdd_path=design/gdd/player-controller.md,phase_row_id=PLAYER_PHASE_ROW_V1,required=true}`。

`OwnerOrchestrationCapacityContributionManifest` actual rows必须逐字段为：

| required_role_id | capacity_kind | outcome_field_id_or_none | required_max | owner_contract_id | source_gdd_path | role_stable_order | kind_stable_order | field_stable_order |
|---|---|---|---:|---|---|---:|---:|---:|
| PLAYER | LIFECYCLE_INTENT | NONE | 0 | PlayerController/v1 | design/gdd/player-controller.md | 2 | 1 | 0 |
| PLAYER | FACT_COMMIT | NONE | 2 | PlayerController/v1 | design/gdd/player-controller.md | 2 | 2 | 0 |
| PLAYER | PAUSE_CLOSURE | NONE | 0 | PlayerController/v1 | design/gdd/player-controller.md | 2 | 3 | 0 |
| PLAYER | BLOCKING_CHOICE | NONE | 0 | PlayerController/v1 | design/gdd/player-controller.md | 2 | 4 | 0 |

Player不生产RunOutcome SoA字段；其DAMAGE/HEAL/DEATH facts由GameRoot及对应resolution owner按既有Outcome producer契约归并。`REVIVE_CLEAR` journal row的`participant_id`与capacity charge均为ENEMY并计入其303上界，PLAYER的`LIFECYCLE_INTENT=0`保持不变。若未来把Player fact producer整体改归其他owner，PLAYER的`FACT_COMMIT`必须同步改为0，禁止两边重复计容。

### Player Workload and Oracle Artifacts

Config冻结并哈希 `PlayerRuntimeWorkloadSupplementV1`，schema为：

`{workload_id,measurement_class,parent_runtime_workload_id,sample_unit,warmup_samples,measured_samples,independent_runs,enemy_count,hazard_count,clear_count,expected_movement_commits,expected_damage_resolutions,expected_recovery_resolutions,expected_candidate_count,expected_enemy_clearance_evaluations,expected_hazard_clearance_evaluations,expected_clear_copies,expected_sort_comparisons_max,expected_sort_row_moves_max,expected_fact_rows,expected_lifecycle_rows,expected_bundle_selector_commits,expected_motion_selector_commits,expected_hud_rows,expected_transient_event_rows,expected_critical_event_rows,start_postcondition_id,end_postcondition_id}`。

实际四行固定为：

| workload_id | parent | sample | active inputs | exact Player vector |
|---|---|---|---|---|
| `PWM01_PLAYER_STEADY_MOVEMENT` | `RW01` | `PHYSICS_TICK;120/1000/3` | `enemy=303,hazard=0,clear=0` | `movement=1,damage=0,recovery=0,candidate=0,enemy_eval=0,hazard_eval=0,clear_copy=0,sort_cmp=0,sort_move=0,fact=0,lifecycle=0,bundle_selector=0,motion_selector=1,hud=0,transient=0,critical=0` |
| `PWM02_PLAYER_DAMAGE_BATCH` | `RW01` | `PHYSICS_TICK;120/1000/3` | `enemy=303,hazard=0,clear=0` | `movement=1,damage=1,recovery=0,candidate=0,enemy_eval=0,hazard_eval=0,clear_copy=0,sort_cmp=0,sort_move=0,fact=1,lifecycle=0,bundle_selector=1,motion_selector=1,hud=1,transient=1,critical=0` |
| `PWM03_PLAYER_REVIVE_MAX` | `RW01` | `COMPLETE_OPERATION;120/1000/3` | `enemy=303,hazard=H,clear=300` | `movement=0,damage=1,recovery=0,candidate=17,enemy_eval=10302,hazard_eval=17H,clear_copy=300,sort_cmp≤44850,sort_move≤44850,fact=1,lifecycle=300,bundle_selector=1,motion_selector=1,hud=1,transient=0,critical=1` |
| `PWM04_PLAYER_RECOVERY_ONLY` | `RW01` | `PHYSICS_TICK;120/1000/3` | `enemy=303,hazard=0,clear=0` | `movement=1,damage=0,recovery=1,candidate=0,enemy_eval=0,hazard_eval=0,clear_copy=0,sort_cmp=0,sort_move=0,fact=1,lifecycle=0,bundle_selector=1,motion_selector=1,hud=1,transient=0,critical=0` |

`H`必须在Hazard owner完成后展开为非负实际整数并进入Config hash；未展开时`PWM03`不是production row且`battle_ready=false`。PWM01/02/04必须与parent RW01同一1191-active fixture运行；PWM03同时提供Player isolated microbenchmark与叠加RW01 active counts的full integration row，不允许用isolated结果宣称全局frame budget。

`PlayerPhase6FaultMatrixV1`与`PlayerContextStateMatrixV1`同样是Config-hashed actual-row artifacts，不由实现或fixture动态生成expected结果。公共writer vector字段顺序固定为：

`{motion_selector,authority_selector,position,hp,life,talisman,revive_generation,fact,lifecycle,hud,transient,critical,node_mirror,view_invalidation}`。

冻结向量为：`WV0={0,0,0,0,0,0,0,0,0,0,0,0,0,0}`、`WV_INIT={1,0,1,1,1,1,1,0,0,1,0,0,1,0}`、`WV_MOTION={1,0,1,0,0,0,0,0,0,0,0,0,1,0}`、`WV_DAMAGE={1,1,0,1,0,0,0,1,0,1,1,0,0,0}`、`WV_RECOVERY={1,1,0,1,0,0,0,1,0,1,0,0,0,0}`、`WV_REVIVE(k)={1,1,1,1,1,1,1,1,k,1,0,1,1,0}`、`WV_TEARDOWN={0,0,0,0,0,0,0,0,0,0,0,0,0,1}`。counter记录commit次数而非字段写次数。

纯验证、候选生成、clear copy与sort期间transaction保持`EMPTY`；完整tuple与canonical clear list已写入inactive backing并通过校验后，才原子进入`PREPARED`并开始reservation/arm。`PlayerPhase6FaultMatrixV1` schema固定为`{row_id,stable_order,clear_count,checkpoint,checkpoint_index,expected_status,expected_tx_state,expected_writer_vector,expected_completion}`；`expected_tx_state∈{EMPTY,PREPARED,ARMED,COMMITTED,ABORTED,UNCHANGED}`，`expected_completion∈{ABORT_BEFORE_PONR,TECHNICAL_ABORT}`。实际24行如下；`stable_order`逐行精确等于row ID的十进制后缀`1..24`：

| row | clear | checkpoint/index | expected status | tx | writer | completion |
|---|---:|---|---|---|---|---|
| PFM01 | 0 | `CONTEXT_HEADER/0` identity mismatch | `IDENTITY_MISMATCH` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM02 | 0 | `PLAN_HEADER/0` | `CARRIER_INVALID` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM03 | 0 | `AUTHORITY_FULL_COPY/0` | `CARRIER_INVALID` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM04 | 0 | `CANDIDATE_BUILD/0` nonfinite | `NON_FINITE_INPUT` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM05 | 1 | `CLEAR_IDENTITY_COPY/1` | `CARRIER_INVALID` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM06 | 300 | `CLEAR_IDENTITY_COPY/300` overflow | `CAPACITY_EXCEEDED` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM07 | 300 | `SORT_COMPARISON_LIMIT/44851` | `CAPACITY_EXCEEDED` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM08 | 300 | `SORT_ROW_MOVE_LIMIT/44851` | `CAPACITY_EXCEEDED` | `EMPTY` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM09 | 1 | `LIFECYCLE_RESERVE/1` | `CAPACITY_EXCEEDED` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM10 | 1 | `LIFECYCLE_SEQUENCE/1` exhausted | `ID_EXHAUSTED` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM11 | 300 | `LIFECYCLE_RESERVE/1` | `CAPACITY_EXCEEDED` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM12 | 300 | `LIFECYCLE_RESERVE/150` | `CAPACITY_EXCEEDED` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM13 | 300 | `LIFECYCLE_RESERVE/300` | `CAPACITY_EXCEEDED` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM14 | 0 | `DAMAGE_FACT_RESERVE/1` | `CAPACITY_EXCEEDED` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM15 | 0 | `AUTHORITY_TUPLE_ARM/0` | `CARRIER_INVALID` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM16 | 0 | `BUNDLE_CAPABILITY_ARM/0` | `CARRIER_INVALID` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM17 | 0 | `MOTION_CAPABILITY_ARM/0` | `CARRIER_INVALID` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM18 | 0 | `DAMAGE_COMMIT_PRECONDITION/0` | `CARRIER_INVALID` | `ABORTED` | `WV0` | `ABORT_BEFORE_PONR` |
| PFM19 | 0 | `AFTER_PONR_BEFORE_PUBLISH/0` | `CARRIER_INVALID` | `COMMITTED` | `WV_REVIVE(0)` | `TECHNICAL_ABORT` |
| PFM20 | 1 | `CLEAR_ADVANCE/0` | `CARRIER_INVALID` | `COMMITTED` | `WV_REVIVE(0)` | `TECHNICAL_ABORT` |
| PFM21 | 1 | `CLEAR_ADVANCE/1` | `CARRIER_INVALID` | `COMMITTED` | `WV_REVIVE(1)` | `TECHNICAL_ABORT` |
| PFM22 | 300 | `CLEAR_ADVANCE/0` | `CARRIER_INVALID` | `COMMITTED` | `WV_REVIVE(0)` | `TECHNICAL_ABORT` |
| PFM23 | 300 | `CLEAR_ADVANCE/1` | `CARRIER_INVALID` | `COMMITTED` | `WV_REVIVE(1)` | `TECHNICAL_ABORT` |
| PFM24 | 300 | `AFTER_CLEAR_BEFORE_PUBLISH/300` | `CARRIER_INVALID` | `COMMITTED` | `WV_REVIVE(300)` | `TECHNICAL_ABORT` |

PFM19–24中的status是注入的首个操作failure，表中tx/writer/completion均表示fault convergence完成后的最终观测；GameRoot不得把failure当作可回滚返回，而必须先完成表中writer vector对应的matching publish再进入`TECHNICAL_ABORT`。未推进的reserved lifecycle rows保持不可见且不得执行。

`PlayerContextStateMatrixV1` payload bit固定为`movement=0x01,resolution=0x02,enemy=0x04,hazard=0x08,terminal=0x10,plan=0x20,prepared_output=0x40,recovery=0x80`；合法mask仅`PM_MOVEMENT=0x01`、`PM_PHASE6=0xFE`、`PM_UNBOUND=0x00`，非`PlayerPhaseContextV1` API使用`PM_NOT_APPLICABLE=-1`。schema固定为`{row_id,stable_order,api,start_owner_state,top_state,phase,payload_binding_mask,first_invalid_field,expected_status,expected_tx_state,expected_writer_vector}`，actual row count精确为33，`stable_order`逐行精确等于row ID的十进制后缀`1..33`：

| row | API / start / top / phase / mask | first invalid | status | tx | writer |
|---|---|---|---|---|---|
| PCM01 | `initialize/UNINITIALIZED/BATTLE_LOADING/NONE/PM_NOT_APPLICABLE` | `NONE` | `OK` | `EMPTY` | `WV_INIT` |
| PCM02 | `initialize/UNINITIALIZED/BATTLE_LOADING/NONE/PM_NOT_APPLICABLE` | `schema_version` | `INVALID_ARGUMENT` | `EMPTY` | `WV0` |
| PCM03 | `initialize/UNINITIALIZED/BATTLE_LOADING/NONE/PM_NOT_APPLICABLE` | `battle_instance_id` | `IDENTITY_MISMATCH` | `EMPTY` | `WV0` |
| PCM04 | `initialize/READY/BATTLE_LOADING/NONE/PM_NOT_APPLICABLE` | `owner_state` | `WRONG_STATE` | `EMPTY` | `WV0` |
| PCM05 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` translate | `NONE` | `OK` | `UNCHANGED` | `WV_MOTION` |
| PCM06 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` zero | `NONE` | `OK` | `UNCHANGED` | `WV_MOTION` |
| PCM07 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `direction.finite` | `NON_FINITE_INPUT` | `UNCHANGED` | `WV0` |
| PCM08 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `config_snapshot_id` | `IDENTITY_MISMATCH` | `UNCHANGED` | `WV0` |
| PCM09 | `run_phase/TERMINATED/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `owner_state` | `WRONG_STATE` | `UNCHANGED` | `WV0` |
| PCM10 | `run_phase/READY/BATTLE_PAUSED/MOVEMENT_COMMIT/PM_MOVEMENT` | `top_state` | `WRONG_STATE` | `UNCHANGED` | `WV0` |
| PCM11 | `run_phase/READY/BATTLE_ACTIVE/QUERY_CONSUME/PM_MOVEMENT` | `phase` | `WRONG_PHASE` | `UNCHANGED` | `WV0` |
| PCM12 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `lease_id` | `PHASE_ERROR` | `UNCHANGED` | `WV0` |
| PCM13 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `tick_revision=expected-1` | `STALE_TICK` | `UNCHANGED` | `WV0` |
| PCM14 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `tick_revision=consumed` | `DUPLICATE_TICK` | `UNCHANGED` | `WV0` |
| PCM15 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `tick_revision=expected+1` | `CARRIER_INVALID` | `UNCHANGED` | `WV0` |
| PCM16 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_PHASE6` | `payload_binding_mask` | `CARRIER_INVALID` | `UNCHANGED` | `WV0` |
| PCM17 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_MOVEMENT` | `movement_bank.capacity` | `CARRIER_INVALID` | `UNCHANGED` | `WV0` |
| PCM18 | `run_phase/READY/BATTLE_ACTIVE/DEFERRED_REMOVAL/PM_PHASE6` no damage/no recovery | `NONE` | `OK_NOOP` | `EMPTY` | `WV0` |
| PCM19 | `run_phase/READY/BATTLE_ACTIVE/DEFERRED_REMOVAL/PM_PHASE6` nonlethal damage | `NONE` | `OK` | `EMPTY` | `WV_DAMAGE` |
| PCM20 | `run_phase/READY/BATTLE_ACTIVE/DEFERRED_REMOVAL/PM_MOVEMENT` | `payload_binding_mask` | `CARRIER_INVALID` | `EMPTY` | `WV0` |
| PCM21 | `run_phase/READY/PAUSE_PENDING/DEFERRED_REMOVAL/PM_UNBOUND` drain | `NONE` | `OK_NOOP` | `UNCHANGED` | `WV0` |
| PCM22 | `run_phase/READY/PAUSE_PENDING/DEFERRED_REMOVAL/PM_PHASE6` drain | `payload_binding_mask` | `CARRIER_INVALID` | `UNCHANGED` | `WV0` |
| PCM23 | `teardown/READY/ENDING/NONE/PM_NOT_APPLICABLE` pre-PONR prepared | `NONE` | `OK` | `ABORTED` | `WV_TEARDOWN` |
| PCM24 | `teardown/READY/CONTROLLED_FAULT/NONE/PM_NOT_APPLICABLE` post-PONR | `convergence_state` | `WRONG_STATE` | `COMMITTED` | `WV0` |
| PCM25 | `teardown/READY/CONTROLLED_FAULT/NONE/PM_NOT_APPLICABLE` converged | `NONE` | `OK` | `COMMITTED` | `WV_TEARDOWN` |
| PCM26 | `teardown/TERMINATED/ENDING/NONE/PM_NOT_APPLICABLE` repeated | `NONE` | `OK_NOOP` | `UNCHANGED` | `WV0` |
| PCM27 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/PM_UNBOUND` | `movement_intent=null` | `CARRIER_INVALID` | `UNCHANGED` | `WV0` |
| PCM28 | `run_phase/READY/BATTLE_ACTIVE/MOVEMENT_COMMIT/0x03` | `resolution_view unexpected` | `CARRIER_INVALID` | `UNCHANGED` | `WV0` |
| PCM29 | `run_phase/READY/BATTLE_ACTIVE/DEFERRED_REMOVAL/PM_PHASE6` | `phase6_plan.valid=false` | `CARRIER_INVALID` | `EMPTY` | `WV0` |
| PCM30 | `run_phase/READY/BATTLE_ACTIVE/DEFERRED_REMOVAL/PM_PHASE6` | `phase6_plan.plan_generation stale` | `CARRIER_INVALID` | `EMPTY` | `WV0` |
| PCM31 | `run_phase/READY/BATTLE_ACTIVE/DEFERRED_REMOVAL/PM_PHASE6` | `prepared_output backing alias` | `CARRIER_INVALID` | `EMPTY` | `WV0` |
| PCM32 | `run_phase/READY/PAUSE_PENDING/DEFERRED_REMOVAL/PM_UNBOUND` | `empty RefCounted used as unbound` | `CARRIER_INVALID` | `UNCHANGED` | `WV0` |
| PCM33 | `run_phase/READY/BATTLE_ACTIVE/DEFERRED_REMOVAL/PM_PHASE6` recovery only | `NONE` | `OK` | `EMPTY` | `WV_RECOVERY` |

actual artifact必须逐行展开上述值并按stable order存储；`WV_*`在artifact中展开为14个实际int counter，PFM19–24的`k`展开为该row表定的`0/1/300`，不得存符号表达式。缺行、多行、未知行、row count非`24/33`、实现从expected表反推判定或任一hash不匹配，均使Player integration gate失败。

### Cross-Document Propagation Required

本轮获批修订必须同步保持以下一致性：

1. systems-index：移除Player对SpatialGrid、Object Pooling的直接依赖，增加GameRoot、Stage、DamageSystem和EnemySystem。
2. SpatialGrid：删除PlayerController的DROP circle与ENEMY nearest调用方行；保留DropSystem拾取，并新增Weapon/Targeting索敌调用方。
3. SpatialGrid pickup radius归属：数值producer改为PlayerStats/Progression/Config，实际query consumer为DropSystem。
4. EnemySystem：自爆Grid查询只使用ENEMY mask，玩家目标改读Player motion carrier后直接窄相。
5. GameRoot/Config：补PLAYER participant、phase coverage、owner contribution、phase5后terminal precollection与非终局REVIVE三步reducer/oracle。
6. InputSystem、Stage及各下游GDD完成时反向引用`PlayerMotionCommitCarrierV1`，不得读取Player Node作为权威。
7. Stage/SpawnDirector：Camera与下一tick生成环都读取matching已发布位置；Player不读取Camera，不为spawn提供第二套坐标；有限world-domain只做fail-fast guard，不形成玩法clamp。

第二轮获批修订继续同步GameRoot、Config、Enemy、Stage、technical-preferences、systems-index与registry；Enemy已静态接纳同版snapshot/clear边界，但自身独立复审与runtime integration仍待完成。DamageSystem、ProjectileSystem、Weapon/Targeting、DropSystem + Leveling/XP与BattleUI均已有作者GDD但为Full Review Pending。BattleUI已承接matching Player frame、stable order 2与`0b010` ACK，但正式bundle/runtime集成仍BLOCKED。Drop已静态接纳matching published position、pickup radius与只读HP revision，实际query仍归Drop。不得把静态传播等同独立复审通过。

## Tuning Knobs

| Setting | Owner | Classification | Baseline | Allowed / safe range | Extreme behavior and coupling |
|---|---|---|---:|---|---|
| `player_collision_diameter` | PlayerConfig | Graybox tuning | 0.8 | `[0.6,1.2]` | 越大越难穿过怪潮缝隙；改变后必须重测技术域guard、敌我窄相和复活净空 |
| `revive_relocation_radius` | PlayerConfig | Graybox tuning | 2.0 | `[1.5,3.0]` | 过小无法摆脱包围，过大像跨场传送；与Stage reachability proof及outer ring固定倍率耦合 |
| `base_max_hp` | PlayerConfig | Balance tuning | 100 | schema域`[1,1,000,000]`；玩法安全范围待Damage/Progression GDD | 改变敌人伤害节奏、治疗价值和35%复活绝对HP；不得在Active中热改 |
| `progression_max_hp_bonus_ratio` | PlayerConfig resolved input | External derived | `0.03×long_chun_level` | `{0,0.03,0.06,0.09,0.12,0.15}` | 只在Loading进入F3A，Active不重算 |
| `preparation_max_hp_bonus_ratio` | PlayerConfig resolved input | External derived | `0`或`0.15` | `{0,0.15}` | 锻体丹只影响下一局起始maxHP |
| `resolved_starting_max_hp` | Config | Derived authority input | F3A | `[1,1,000,000]`且finite | Player初始化时同时赋给`max_hp/current_hp` |
| `pickup_radius_base` | PlayerStats/Config | External tuning | 1.8 | 由Progression规则约束 | Player只发布数值view，实际query归DropSystem |
| `pickup_radius_max` | Progression | External derived | 1.98 | `1.8×(1+5×2%)` | 不是PlayerController的Grid半径或性能查询责任 |
| `max_normal_enemy_bound` | EnemyConfig | External blocker | 未冻结 | finite且`≥0` | 校验NORMAL shape-bound snapshot与足迹相交；缺值时不得进入production |
| `revive_hazard_capacity` | Hazard producer + Config | External blocker | 未冻结 | 正整数、由producer workload证明 | 必须与A/B hazard bank精确定容一致；Player不得补默认值 |

以下为冻结契约，不是普通调谐旋钮：

- `player_speed=4.5`、`physics_ticks_per_second=60`、`fixed_dt=1/60`。
- `REVIVE_HP_RATIO=0.35`。
- `revive_candidate_count=17`、outer ring multiplier=2及固定方向/index顺序。
- 每局替身符数量为1，本局不可恢复。
- 清除目标仅限NORMAL，Elite/Boss永不清除。
- 复活后持续无敌时间为0；当前致命batch不穿透，下一完整玩法tick重新可受伤。
- 初始位置为world safe domain原点，初始朝向为`Vector2.DOWN`。
- HP使用float64，玩法层不取整。
- 所有调谐值只随新Config snapshot进入下一局；Active中热改返回失败。

调谐验证要求：

- 足迹直径、迁移半径必须做最小值、基准值、最大值三点灰盒测试，并纳入Stage reachability proof；shape bound与hazard容量按各producer完整workload边界测试。
- 清除没有独立半径旋钮；任何尝试扩大到非重叠NORMAL的配置都必须被schema/静态检查拒绝。
- 任何旋钮变更必须重跑四边/四角移动、十七点候选退化、303敌人峰值、hazard全覆盖和故意送死策略测试。
- 当前参数仅为静态设计与灰盒范围，没有真机手感或性能验收证据。

## Visual/Audio Requirements

表现层只消费allocation-free派生的`PlayerPresentationFrameV1`与定容event bank。Frame没有第三套backing、bank或selector；reader只在同一次调用中联结已发布motion与HUD并逐字段copy-out：

`PlayerPresentationFrameV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,motion_view_generation:int64,hud_view_generation:int64,motion_bank_id:int32,hud_bank_id:int32,position_revision:int64,batch_authority_revision:int64,position:Vector2,facing_direction:Vector2,did_translate:bool,life_state:int32,talisman_state:int32,revive_generation:int64,revive_safety_class:int32,critical_presentation_pending:bool,terminal_outcome:int32,presentation_winner:int32,valid:bool}`。`acquire_presentation_frame(...)`仅当motion/HUD的battle、config、player、各自generation与expected bank/revision匹配，且`motion.batch_authority_revision==hud.published_authority_revision`时成功；否则out保持不变并返回`CARRIER_INVALID/IDENTITY_MISMATCH`，不得拼接跨revision帧。

表现传输拆成两类，不再让非fact事件冒充`fact_sequence`：

- `PlayerPresentationConsumerManifestV1` actual rows精确为：`{PLAYER_VISUAL,stable_order=1,consumer_kind=VISUAL,required_mask=DAMAGE|REVIVE|DEATH}`、`{BATTLE_UI,2,UI,DAMAGE|REVIVE|DEATH}`、`{PLAYER_AUDIO,3,AUDIO,DAMAGE|REVIVE|DEATH}`。header固定为`{schema_version=1,consumer_count=3,ack_word_capacity=1,required_ack_mask=0b111,manifest_hash:int64}`；每个consumer的ack bit固定为`1 << (stable_order-1)`。consumer ID、顺序、mask缺失/重复/未知均使Battle load失败。未来增删consumer必须升级manifest/content hash，不能复用V1空bit。
- `PlayerTransientEventV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,event_sequence:int64,event_identity_kind:int32,source_fact_sequence:int64,batch_authority_revision:int64,event_code:int32,reason_code:int32,magnitude:float64}`；`PlayerTransientEventBankV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,capacity_per_bank:int32=1,published_bank_id:int32,published_event_sequence:int64,view_generation:int64,consumer_manifest_hash:int64,required_ack_mask:int64,bank0_acked_mask:int64,bank1_acked_mask:int64,bank0:PlayerTransientEventV1,bank1:PlayerTransientEventV1,valid:bool}`。只承载非终局聚合DAMAGE；每个required consumer必须在下一次Player event publish前ack matching `{battle_instance_id,view_generation,event_sequence,consumer_manifest_hash}`，ack以其stable-order bit exact-once OR进published bank的acked mask。`acked_mask==required_ack_mask`前禁止覆盖或切到会覆盖未读row的bank；缺ack时GameRoot保持consumer closed并fault。
- `PlayerCriticalEventV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,event_sequence:int64,event_identity_kind:int32,source_fact_sequence:int64,revive_generation:int64,batch_authority_revision:int64,event_code:int32,reason_code:int32,revive_safety_class:int32,delivery_state:int32}`；`PlayerCriticalEventLedgerV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,player_id:int64,capacity:int32=2,row_count:int32,next_event_sequence:int64,view_generation:int64,consumer_manifest_hash:int64,required_ack_mask:int64,row0_acked_mask:int64,row1_acked_mask:int64,row0:PlayerCriticalEventV1,row1:PlayerCriticalEventV1,valid:bool}`。两行分别覆盖本局至多一次REVIVE与一次terminal DEATH，row state=`EMPTY/PUBLISHED/DELIVERING/ACKED`单调推进；只有matching row的`acked_mask==required_ack_mask`时才可进入`ACKED`。Critical row在此之前不得覆盖、回收或被下一bank替代，overflow、未知consumer bit或重复identity进入fault。

reader cursor统一为`{battle_instance_id,view_generation,consumer_manifest_hash,consumer_id,next_event_sequence}`，每consumer独立保存ack；REVIVE identity精确为`{battle_instance_id,revive_generation}`，DEATH/DAMAGE使用`{battle_instance_id,source_fact_sequence,batch_authority_revision}`。MOVE start/stop/loop只由连续presentation frame的`did_translate`边沿派生，不进入event ledger。

`event_identity_kind={FACT=1,REVIVE_GENERATION=2}`。DAMAGE/DEATH必须使用`FACT`、`source_fact_sequence>0`且`revive_generation=0`；REVIVE必须使用`REVIVE_GENERATION`、`source_fact_sequence=0`且`revive_generation>0`。event sequence从1开始checked单调递增，耗尽在publish前返回`ID_EXHAUSTED`；新row的acked mask初始化为0，重复ACK不改变mask或state。

GameRoot在phase-6 publish前把Player authority slice、matching terminal precollection、presentation projection按同一`batch_authority_revision`联结；phase7 sealed RunOutcome只能确认同一precollection winner。所有animation/audio/UI consumer在读取或ack event前必须取得matching revision的frame。`VICTORY+lethal`时仍可发布DAMAGE/DEATH统计fact，但`presentation_winner=VICTORY`，event bank不得含`PLAYER_DEATH_LATCHED`，也不得触发HIT、死亡pose、死亡重音、REVIVE、DEFEAT或pause UI。

### Animation States

| State/Event | Entry condition | Exit |
|---|---|---|
| `IDLE` | ALIVE且`did_translate=false` | 实际位移出现 → MOVE |
| `MOVE` | ALIVE且`did_translate=true` | 实际位移为ZERO → IDLE |
| `HIT` | 非零DAMAGE已提交，且`presentation_winner=NONE`、未死亡/复活 | one-shot结束后按最新motion回IDLE/MOVE |
| `DEATH` | 公开life进入`DEATH_LATCHED`且`presentation_winner=DEFEAT` | 本局终态，等待结算/teardown |
| `REVIVE` event | matching authority publish推进`revive_generation` | 不形成第二套生命状态，结束后回IDLE/MOVE |

表现优先级为`REVIVE > DEATH > HIT > MOVE/IDLE`。同一致命batch只播放一种生命转折表现；成功复活不得先播死亡。

- visual child只消费已发布position、facing、life和fact。
- gameplay root保持`rotation=0`、`scale=(1,1)`。
- 镜像、recoil、squash、闪色、残影和普通移动插值只能发生在visual child。
- 初始化、复活、teardown及其他位置跳变必须清空插值偏移并立即snap。
- 动画回调不得写HP、位置、朝向、替身符或Gameplay状态。

### Movement and Hit Feedback

- 实际移动时播放轻量move动画，可带低优先级衣摆、尘迹或短尾迹，但不得制造加速、惯性或自动闪避错觉。
- `did_translate=false`时下一可见帧进入idle；纯向外贴边输入可用轻微“踏稳”变体，但不播放反弹、撞墙火花、震屏或重复碰撞音。
- 朝向读取已发布`facing_direction`；即使贴边未移动，也应立即表现新的朝向。
- 受击只按已提交的聚合DAMAGE batch播放一次，不按原始hit数量叠加；可使用短轮廓闪色或visual-child recoil，但不得造成根节点位移、hit-stun或足迹变化。
- 连续伤害必须限频，禁止高频全屏白闪或不安全的明暗闪烁。

### Talisman Feedback

替身符只在matching authority publish后，以`{battle_instance_id,revive_generation}`和`AVAILABLE→SPENT`为exact-once触发依据。`PREPARED/ARMED`阶段不得提前显示。

反馈由三部分组成：

1. 旧位置留下短暂纸符燃尽或残影；
2. 新位置首个可见帧立即显示韩立，不沿路径插值成冲刺；
3. 新位置玩家足迹边界出现一次短促符纹净空确认。

净空确认只允许`SAFE/SAFE_UNCONSTRAINED`使用，并只表达与复活后玩家足迹真实重叠/相切的普通敌人清除，不得画成固定半径清屏。`UNSAFE_FALLBACK`使用不同的短促破损符纹与危险脉冲，只表达“已显形但仍处危险”，不得显示净空、护盾或持续无敌语义；该差异必须存在于P0预加载fallback，不依赖高级粒子或颜色。Elite/Boss穿过符纹时不得闪白、受击或播放死亡反馈。被清普通敌人使用统一“符力驱散”反馈，不播放逐个击杀、经验、掉落或奖励表现。

建议视觉语言为纸金/象牙白主体配朱砂符纹，避开毒区绿色和危险预警的大面积红色；最终色值由art bible冻结。除颜色外，必须同时依靠旧点符纸、新点显形和径向符纹三种形态，保证色觉差异下仍可理解。

### VFX Priority and Performance

- `P0`：玩家轮廓、受击确认、死亡、替身符显形与消耗确认；不可静默丢失。
- `P1`：伤害方向、净空波、旧位置残影；可降低粒子量。
- `P2`：移动尘迹、衣摆拖尾、装饰火星；性能压力下优先关闭。

所有效果必须预热、定容并有固定生命周期。禁止按hit数或清除敌人数动态增长Node/粒子；不为每个被清普通敌人创建完整死亡VFX。稳态禁止动态Tween、Material复制、Gradient/Curve创建和带参signal。池耗尽时先丢P2，再降低P1，P0必须保留基础降级反馈。

P0最低降级manifest不依赖运行时新建资源：DAMAGE至少使用Player visual child上预加载的单次轮廓闪色；DEATH至少切换到预加载的基础死亡pose/sprite；REVIVE至少在新位置显示预加载的符纹sprite，并由HUD在同一snapshot显示`SPENT`。高级粒子、残影与音频即使不可用，也不得丢失上述最低视觉语义。精确资源槽数量和完整质量容量留给Asset Spec，但每个P0事件必须有一个可用的预加载fallback引用，否则Battle load失败。

粒子数、纹理尺寸、draw call、overdraw、显存与GPU预算需在min-spec Android artifact确定后测量，目前保持OPEN。

### Audio Events

| Event | Feedback | Priority |
|---|---|---|
| `PLAYER_REVIVE_COMMITTED` | 符纸裂响/燃尽、短促显形、一次净空冲击；无持续护盾loop | Critical |
| `PLAYER_DEATH_LATCHED` | 唯一死亡重音，覆盖普通受击 | Critical |
| `PLAYER_DAMAGE_COMMITTED` | 每个聚合batch一次；可按伤害占最大HP比例分轻重 | High |
| `PLAYER_MOVE_START/LOOP` | 极轻衣摆或步法声，可在密集战斗中降级 | Low |
| `PLAYER_MOVE_STOP/TURN/EDGE_BLOCKED` | 默认静默 | None |
| `REVIVE_CLEAR` | 并入单次复活事件，不按清除数量播放 | Critical group |

同一batch先应用GameRoot presentation winner，再在非终局Player事件中按`REVIVE > DEATH > DAMAGE`选择音频反馈。VICTORY winner抑制HIT/DEATH/REVIVE音频而不删除统计fact。受击按DAMAGE fact去重；复活按battle identity与revive generation去重；死亡按已投影的critical event去重。Critical presentation host自身仍为PAUSABLE且不定义`_process/_physics_process`；REVIVE+pause时由既有persistent GameRoot ALWAYS control pump显式调用其typed `advance_critical_presentation(presentation_dt)`，只推进预加载P0 visual/audio时钟并禁止写任何gameplay authority，完成后各consumer才ack。Pause、resume、视图重建和节点重新入树只重绑定未ACKED row，不重播已ACKED事件。

Critical可以抢占低优先级移动/受击声，但不得遮蔽Boss或Elite致命预警。精确响度、bus、duck量、冷却窗口、振动和素材风格归Audio GDD。

### Deferred to Art Bible / Asset Spec

角色比例与授权形象、四向/八向动画、帧数和pivot、精确色板、符纸纹样、Shader和粒子参数、贴图/atlas规格、音效素材与bus routing，以及VFX池容量和GPU降级阈值均留待art bible、asset spec和真机profiling。

不得defer的核心契约是：表现只消费已发布权威状态、复活不先播死亡、不跨复活点插值、不暗示持续无敌、清除不伪装成击杀，以及关键反馈exact-once。

## UI Requirements

### Published UI View

PlayerController向BattleUI提供只读、版本化的`PlayerHudSnapshotV1`，字段精确为：

`PlayerHudSnapshotV1={schema_version=1,battle_instance_id:int64,config_snapshot_id:int64,view_generation:int64,bank_id:int32,batch_authority_revision:int64,player_id:int64,current_hp:float64,max_hp:float64,life_state:int32,talisman_state:int32,revive_generation:int64,revive_safety_class:int32,critical_presentation_pending:bool,terminal_outcome:int32,presentation_winner:int32,valid:bool}`。字段集合对V1精确封闭；新增字段必须升级schema，不使用“至少包含”扩展。

两个HUD bank在Loading期预分配，Player/GameRoot只写inactive bank并在matching authority publish后切selector；`acquire_hud_view(expected_authority_revision,out)`只返回只读view，revision/bank/generation任一不匹配均失败且不返回旧值。

BattleUI不得持有Player Node、Damage carrier或未发布的inactive authority bank，也不得向PlayerController回写状态。

### Required HUD Information

- 战斗HUD必须持续显示当前HP与最大HP。
- HP显示可以采用血条和数值组合，但数值格式化只属于表现层，不得把显示取整结果回写float64权威HP。
- 替身符必须有常驻、单手可读的状态标识：
  - `AVAILABLE`：明确显示本局仍有一次后手。
  - `SPENT`：同一位置保留已消耗状态，不直接隐藏图标，避免玩家误以为UI漏显示。
- `DEATH_LATCHED`后HUD停止接受普通玩法更新，只等待GameRoot切换到胜利、败北或技术故障目标界面。

### Update and Exact-Once Rules

- 普通伤害只在matching authority publish后更新HP；不得读取瞬时hit或未提交Damage resolution提前掉血。
- 替身符复活必须在同一个已发布snapshot更新中同时呈现：
  - 新HP为`35% max_hp`；
  - `talisman_state=SPENT`；
  - `revive_generation`增加1。
- UI不得出现“先显示HP=0和死亡，再跳回35%”的假死亡序列。
- 复活反馈按`{battle_instance_id,revive_generation}`去重；pause/resume、BattleUI重建或节点重新入树不得重播。
- 胜利与致命伤同tick时，UI服从GameRoot最终VICTORY，不显示死亡pose、死亡重音、败北或pause UI；替身符仍显示AVAILABLE，统计层仍可读取DAMAGE/DEATH fact。
- 不可逆点后故障收敛时，BattleUI只读取最终发布snapshot与GameRoot completion状态，不自行猜测应回滚到哪一帧。

### Pause and Lifecycle Behavior

- BATTLE_PAUSED期间HUD保持最近一次已发布HP、替身符和life状态，不推进动画计时或模拟玩法变化；HUD不展示或持有玩家位置。
- 成功复活后同tick又进入pause时，pause界面必须显示复活后的HP与已消耗替身符。
- 若该复活为`UNSAFE_FALLBACK`，pause界面与角色附近P0 fallback必须保留非颜色危险标记，且hazard/Boss warning优先于revive impact；Critical row完成全部consumer ack前保持`critical_presentation_pending=true`。
- Loading期间Player HUD保持不可交互、不可显示未绑定的默认值。
- Teardown后旧snapshot view必须失效；新局只能绑定新的battle identity。

### Accessibility and Clarity

- 替身符状态不得只靠颜色区分；AVAILABLE/SPENT还必须有不同形状、纹样或破损状态。
- HP与替身符状态必须在竖屏单手玩法下快速扫读，但不遮挡玩家、敌人攻击预警或虚拟摇杆区域。
- 复活不显示持续护盾环、无敌倒计时或其他并不存在的机制。
- 被替身符清除的普通敌人不显示击杀、经验、掉落或奖励UI反馈。

### Ownership Boundary

本GDD不冻结HUD具体位置、尺寸、字体、色值、动效时长、安全区适配和触控布局。BattleUI GDD与后续`design/ux/`规范负责这些内容，但必须遵守本节的数据、时序和exact-once契约。

## Acceptance Criteria

证据标签：`[U]`表示确定性unit/headless测试，`[I]`表示integration/golden scene，`[R]`表示Godot runtime/export证据，`[M]`表示冻结设备与artifact的移动端证据，`[S]`表示静态CI/manifest检查。`[S]`不得替代运行时或分配证据；所有`BLOCKED`与`OPEN`项在依赖解除并生成对应证据前不得标为PASS。

### A. Authority, Manifest, and Initialization

- **AC-PC01 `[S][I]` 唯一写入者**：Given扫描所有运行时代码和集成夹具，When查找玩家位置、HP、生命状态、替身符状态写入点，Then仅PlayerController可提交这些权威字段，其他系统只能提交输入或读取已发布快照。
- **AC-PC02 `[S][I][BLOCKED-INTEGRATION]` PLAYER manifest actual rows**：Given production manifests，When加载PLAYER participant行与四条owner contribution行，Then字段集合、字段名、source path、orders、phase set、success set与Dependencies逐字段相等；缺行、多行、未知字段或Config补默认均加载失败。
- **AC-PC03 `[I]` 调度顺序**：Given一个正常gameplay tick，When GameRoot执行`MOVEMENT_COMMIT`，Then InputSystem与PlayerController各执行恰好一次，且InputSystem严格先于PlayerController。
- **AC-PC04 `[U][I]` 拒绝矩阵**：Given phase、lease、battle/config identity、tick revision、schema任一缺失或不匹配，When PlayerController收到输入、伤害或事务提交请求，Then返回规定的精确failure，且位置、HP、生命、替身符、carrier、fact、journal均零写入。
- **AC-PC05 `[U][I]` 初始状态**：Given合法battle loading，When PLAYER初始化完成，Then位置为`(0,0)`、朝向`DOWN`、`current_hp=max_hp`、生命为`ALIVE`、替身符为`AVAILABLE`，revision与当前battle/config identity一致。

### B. Movement, Domain Guard, and Publish

- **AC-PC06 `[U]` F1/F2数值表**：Given ZERO、四轴、四个对角及`1±1e-6`方向边界，When以固定float64顺序计算并构造/readback Godot `Vector2`，Then数学速度模长位于`[4.4999955,4.5000045]`、数学位移模长位于`[0.074999925,0.075000075]`，发布carrier逐bit等于real_t32 readback，actual velocity从readback位置反算；技术域外、NaN、Infinity零写入。
- **AC-PC07 `[U][I]` active语义**：Given `is_active=false`或active与direction不一致，When消费MovementIntentCarrier，Then inactive只允许ZERO；任何不一致均返回精确failure，且不发布motion commit。
- **AC-PC08 `[U][I]` 无玩法边界截断**：Given玩家从原点沿四轴/四对角连续移动并保持在Stage reachability envelope内，When运行等长tick，Then每tick实际位移只受F1 real_t32 readback影响，不出现22×40 clamp、法向归零、沿边滑行、wrap或位置重置。
- **AC-PC09 `[U][I]` 技术域越界fail closed**：Given完整足迹分别从world safe domain四边/四角canonical内侧跨到外侧，When执行F2，Then边界内值原样提交，任一外侧值返回`POSITION_OUT_OF_RANGE`且motion/Node/camera写入0，GameRoot进入ControlledGameplayFault；不得clamp。
- **AC-PC10 `[U]` real_t技术域精度**：Given技术合法边界canonicalize后的real_t32位值及沿外法线的下一个可表示real_t32值，When验证domain guard，Then边界位值保持不变并成功，外侧next-representable失败且零提交；测试不得以float64 ULP替代Godot export ABI。
- **AC-PC11 `[R]` 根节点权威移动**：Given Player场景运行，When连续移动并播放表现动画，Then只有权威根节点位置参与gameplay，视觉子节点可局部偏移但不得改变碰撞、查询或已发布位置。
- **AC-PC12 `[U][I]` A/B carrier**：Given连续100个成功正常tick，When每tick提交`PlayerMotionCommitCarrierV1`，Then两个预分配bank严格交替；每次只发布完整inactive bank，ZERO移动也推进revision，Active期间不替换backing storage。

### C. Damage, HP, and Revive Values

- **AC-PC13 `[U]` HP算术**：Given四个独立向量`{H=100,X=0→applied=0,hp_after=100,lethal=false}`、`{H=25,X=7.5→7.5,17.5,false}`、`{H=25,X=25→25,0,true}`、`{H=25,X=40→25,0,true}`且`max_hp=100`，When应用批次，Then结果逐字段等于箭头后的float64值，actual damage不含overkill；负数、NaN、Infinity及“正伤害但HP逐bit不变”均被拒绝且writer vector=`WV0`。
- **AC-PC14 `[U][I][BLOCKED-DAMAGE-GDD]` 同tick聚合**：Given同tick多个命中及一个matching `PlayerDamageResolutionV1`，When Player消费该resolution，Then仅应用一次最终聚合伤害、最多提交一条DAMAGE fact；相同canonical `ResolutionPublishTokenV1`第二次消费返回`OK_NOOP`且零effect，任一token字段错误返回`CARRIER_INVALID/IDENTITY_MISMATCH`的冻结优先级结果并零写入。
- **AC-PC15 `[U]` 35%恢复**：Given `max_hp`为`1, 100, 137.8, 1e6`，When替身符合法触发，Then `current_hp=0.35×max_hp`、生命恢复`ALIVE`、替身符为`SPENT`、`revive_generation`恰好加一，且不做显示层取整。

### D. Revive Selection and Capacity

- **AC-PC16 `[U]` 十七候选ABI**：Given任意domain-safe死亡点和合法迁移半径，When生成候选，Then精确17个slot依次为中心、内圈固定八方向、外圈相同八方向；倍率精确为`0/1/2`，每点构造/readback后通过完整足迹domain guard，不做arena clamp，量化重复坐标不去重；任一slot越域则整计划在PONR前失败。
- **AC-PC17 `[U][I][BLOCKED-ENEMY-BOUND]` NORMAL真实足迹相交**：Given `shape_code=CIRCLE`的NORMAL与ELITE/BOSS分别位于`distance<,=,>`玩家半径加实际圆半径，When冻结clear集合，Then只清除真实重叠或相切NORMAL；非重叠NORMAL及全部ELITE/BOSS保留。另以非圆NORMAL配置验证battle load失败，禁止把保守外接圆误作clear形状。
- **AC-PC18 `[U][I][BLOCKED-HAZARD-CAPACITY]` 表面净空、shape与fallback**：Given实际坐标/bit-pattern golden覆盖enemy current+swept、next-tick hazard为空、CIRCLE内/相切/外ε、EXTERIOR_CIRCLE内/内切/外ε、有SAFE、有SAFE_UNCONSTRAINED、全部危险、`-0`、逐bit同分、clear-count不同、real_t32量化重复，以及V1/unknown shape，When执行F5–F7，Then CIRCLE仅`>0`安全、EXTERIOR_CIRCLE为`>=0`安全，并严格按`safety rank→score DESC→clear_count ASC→index ASC`选择；全危险标`UNSAFE_FALLBACK`，旧schema/unknown shape fail closed，无Infinity、无敌或输入顺序依赖。
- **AC-PC19 `[U]` 顺序无关与复杂度**：Given相同敌人/hazard逻辑集合及duplicate enemy_id/different lifecycle tuple的多种物理排列，When评分并冻结clear列表，Then选点一致、完整lifecycle identities按四字段tuple总序一致；扫描计数精确为`34×N_enemy+17×N_hazard+N_enemy`，binary insertion sort在`n=0/1/300`的comparison/row-move均不超过44,850且每row move精确4个int64写，allocation-capable native sort调用数0。
- **AC-PC20 `[U][I][BLOCKED-HAZARD-CONTRACT]` 精确定容分层**：Given所需容量`{candidate=17,threat=303,clear=300,player_fact=2,transient_event=1,critical_event=2,hazard=revive_hazard_capacity}`，WhenConfig artifact各项required±1，Thenbuild返回`INVALID_MANIFEST`且snapshot数0；When伪造snapshot进入Player initialize，Then返回`INVALID_CONFIG`且writer数0；只有逐项精确相等成功，Active不扩容。
- **AC-PC21 `[U][I][R]` producer/consumer/私有helper溢出分层**：GivenEnemy/Hazard producer尝试写capacity+1、伪造published count、Player clear workspace第301行，以及private-helper第18候选/第3 fact负例，When分别执行，Thenproducer返回`CAPACITY_EXCEEDED`且selector不切，forged view由Player返回`CARRIER_INVALID`，clear overflow在PONR前返回`CAPACITY_EXCEEDED`；private-helper负例只证明内部guard，不冒充production可达路径。全部不resize、不截断、不覆盖旧行。

### E. Outcome, Revive, and Pause Priority

- **AC-PC22 `[U][I][BLOCKED-DAMAGE-GDD]` 预副作用终局**：Given伤害批次到达但尚未产生不可逆副作用，When同tick存在更高优先级FATAL，Then不消费替身符、不移动玩家、不清敌、不发布复活tuple，并按FATAL收敛。
- **AC-PC23 `[I][R][BLOCKED-DAMAGE-GDD]` 胜利加致命伤害**：Given phase5 resolution后冻结的matching terminal precollection含VICTORY、致命伤害、可用替身符和pause，Whenphase-6 authority与presentation projection一起发布、phase7 seal同一winner，Then HP=0、life=`DEATH_LATCHED`、DAMAGE=1、DEATH=1、outcome/presentation winner=VICTORY、talisman=AVAILABLE；DEATH/HIT/REVIVE/DEFEAT/pause event与consumer counter均0，VICTORY consumer=1。相同artifact另含普通死亡、合法复活和纯pause positive controls，防止所有表现consumer失效造成假通过。
- **AC-PC24 `[I][BLOCKED-DAMAGE-GDD]` 致命伤害复活**：Given无FATAL/VICTORY、伤害致命且替身符AVAILABLE，When批次提交成功，Then只产生一次REVIVE，发布完整`{position,hp,talisman=SPENT,generation+1,life=ALIVE}` tuple，不产生DEFEAT。
- **AC-PC25 `[I][BLOCKED-DAMAGE-GDD]` 致命伤害失败**：Given无FATAL/VICTORY、伤害致命且替身符SPENT，When批次提交，Then HP为0、生命为`DEATH_LATCHED`、提交DAMAGE与DEATH事实并产生DEFEAT，不产生REVIVE。
- **AC-PC26 `[I][BLOCKED-DAMAGE-GDD]` 非致命伤害加暂停**：Given非致命伤害与pause同tick发生，When仲裁，Then伤害先作为该tick权威结果提交，随后pause进入规定状态；不得漏伤或重复伤害。
- **AC-PC27 `[I][BLOCKED-DAMAGE-GDD]` 复活加暂停**：Given复活与pause同tick发生且无terminal，When复活事务完成，Then复活发布后pause仍被保留并生效，不得被REVIVE吞掉。
- **AC-PC28 `[I]` terminal加暂停**：Given terminal outcome与pause同tick竞争，When GameRoot仲裁，Then terminal优先，Player不发布额外pause状态或遗留pause lease。
- **AC-PC29 `[I][R][BLOCKED-DAMAGE-GDD]` 无隐藏无敌**：Given玩家在tick N复活，When进入下一完整gameplay tick N+1并收到合法伤害，Then该伤害正常生效；不存在未声明的invulnerability、护盾或命中忽略窗口。

### F. Transaction, PONR, and Exact-Once

- **AC-PC30 `[U][I][BLOCKED-DAMAGE-GDD]` PONR前失败矩阵**：Given immutable `PlayerPhase6FaultMatrixV1`的PFM01–18，When逐row注入，Thenstatus/tx/writer/completion逐字段等于actual row；PFM01–08保持`EMPTY`，PFM09–18进入`ABORTED`，全部writer vector=`WV0`。
- **AC-PC31 `[I][BLOCKED-DAMAGE-GDD]` 统一PONR后收敛**：Given同一matrix的PFM19–24且全部N条lifecycle row/fact/capability已预留并arm，非零DAMAGE fact首次进入`COMMITTED`构成唯一PONR，When在表定checkpoint注入故障，Thenfact不回滚、已推进row数与`WV_REVIVE(k)`逐字段相等，未推进row保持RESERVED且不得执行或新分配；完整armed tuple与事实经唯一matching authority/presentation publish公开后进入TECHNICAL_ABORT。
- **AC-PC32 `[I][BLOCKED-DAMAGE-GDD]` copy/publish oracle**：Given clear count为0或非0，When枚举inactive-bank copy、selector commit feasibility、plan/capability arm的PONR前failure，以及PONR后convergence，Then点前所有selector/ledger state均不切且零公开；点后不再注入commit failure，consumer保持closed，严格执行`bundle→optional motion→HUD→optional transient→optional critical PUBLISHED→Node mirror`且每个表定步骤恰一次，全部输出的`batch_authority_revision`逐bit等于bundle next revision，随后reader只能看到该revision。
- **AC-PC33 `[U][I][BLOCKED-DAMAGE-GDD]` 正常死亡与clear去重**：Given同一敌人在同tick同时满足正常死亡和REVIVE_CLEAR，When冻结lifecycle rows，Then仅保留一个stable identity row，正常死亡语义优先，不重复奖励、释放或删除。
- **AC-PC34 `[U][I][BLOCKED-DAMAGE-GDD][BLOCKED-RECOVERY-GDD]` 重放幂等**：Given同一damage/recovery token、lifecycle row、fact row及publish token被重放100次，When执行恢复或重复callback，Then HP、替身符、generation、clear、DAMAGE/HEAL/DEATH事实及表现各只发生一次。

### G. State, Teardown, and Cross-Document Consistency

- **AC-PC35 `[U][I]` typed context与状态矩阵**：Given实际哈希的`PlayerContextStateMatrixV1` PCM01–33及本GDD逐字段冻结的view/binding/plan/capability schema，When逐row执行，并对PCM01/05/18/23/33五个合法base row逐字段做min/max/缺字段/多字段/非finite边界变异，ThenPCM row的first-error/status/tx/writer逐字段相等；额外边界变异的expected只由本节冻结的first-error precedence与字段domain生成，且不得读取实现结果。正常Active只接受对应payload，drain只接受`PM_UNBOUND`并`OK_NOOP`，Paused/Resuming/Ending/Fault拒绝玩法，点后teardown缺convergence proof时`WRONG_STATE`；实现不得读取matrix。
- **AC-PC36 `[I]` 恢复后新输入**：Given暂停前最后carrier为非ZERO，When恢复后的首个gameplay tick没有新触控输入，Then Player读取新revision的ZERO carrier，不复用暂停前方向或速度。
- **AC-PC37 `[I][R]` teardown与跨局隔离**：Given从active、paused、armed或fault状态触发teardown，When新battle开始，Then旧battle的carrier、token、fact、clear计划、HP、替身符和表现去重键均不可被新battle接受。
- **AC-PC38 `[S][I]` SpatialGrid零调用**：Given静态调用图和运行时spy，When覆盖移动、受伤、复活、拾取与索敌场景，Then PlayerController对SpatialGrid的注册、circle、nearest、remove调用次数始终为0。
- **AC-PC39 `[S][BLOCKED-INTEGRATION]` 跨文档规范一致**：Given全仓库GDD与系统索引，When搜索Player→SpatialGrid、Player→Pool、任何含PLAYER bit的Grid组合mask及未传播状态，Then不得残留与本GDD冲突的production契约；正式通过前相关文档必须完成传播并移除`Not Started`/旧依赖描述。

### H. Zero-Allocation Evidence

- **AC-PC40 `[S][BLOCKED-TOOLING]` 静态denylist与sort allowlist**：Given冻结production roots、非空实现门、known-good/known-bad fixtures与`NativeAllocationCallAllowlistV1`，When运行`tools/ci/static_guard_check.py`，Then禁止`Array/Dictionary`构造、append/push/resize/duplicate/slice/map/filter/reduce、native/custom sort、Callable/closure、带参signal、方法字符串、backing替换与运行时资源创建；只允许Player私有primitive binary-insertion helper，普通Active movement路径出现sort必须失败。脚本尚不存在，故BLOCKED。
- **AC-PC41 `[R][OPEN]` 分路径运行时分配**：Given与GameRoot workload hash绑定的`PWM01/PWM02/PWM03/PWM04`、同一release artifact、固定observer与positive controls，When按row各跑3次独立run，Then每run分别满足`allocator_events=0、allocator_bytes=0、container_growth_events=0、cow_events=0、unexpected_allocation_capable_native_calls=0`；禁止用alloc/free净值或paired baseline相减宣称0。observer无法归因、positive control未检出或任一row/hash/marker不匹配则`INCONCLUSIVE`。

### I. Visual, Audio, and UI

- **AC-PC42 `[I][R][BLOCKED-DAMAGE-GDD]` 聚合受击反馈**：Given同tick多个命中聚合为一条DAMAGE fact，When表现层消费已提交事实，Then只播放一次聚合受击反馈；raw hit和未发布resolution不触发表现。
- **AC-PC43 `[I][R]` 复活反馈时序**：Given复活事务尚未publish、已publish及被重复重建，When表现层观察状态，Then只有matching publish后播放一次复活反馈并snap至权威位置；不得同时播放死亡、普通受击或持续循环复活反馈。
- **AC-PC44 `[I][R]` 死亡与胜利组合**：Given普通死亡、替身符复活、VICTORY+致命三种golden vectors，When先联结相同`batch_authority_revision`的Player frame、terminal precollection、fact bank与event ledger，再由phase7 seal同一winner，Then普通死亡只播DEATH，复活只播REVIVE，VICTORY+致命保留统计DEATH fact但只呈现VICTORY，HIT/死亡pose/重音/败北/pause均为0；缺matching frame时consumer不得读取或ack event。
- **AC-PC45 `[I][R][BLOCKED-ENEMY-BOUND]` 清除不是击杀也不是容量清屏**：Given300个NORMAL容量fixture、2 ELITE、1 BOSS，且NORMAL分布在足迹重叠/相切/正净空三类，When REVIVE_CLEAR执行，Then仅前两类NORMAL无奖励清退；正净空NORMAL与非普通敌人保留，不出现kill/XP/drop/reward/record反馈，clear count不被强制为300。
- **AC-PC46 `[S][I][R][BLOCKED-ASSET]` 事件bank与P0降级**：Given三行`PlayerPresentationConsumerManifestV1`、`required_ack_mask=0b111`、transient capacity=1、critical capacity=2、完整资产、缺P1/P2、缺P0、三个consumer逐一/重复/未知bit ACK、slow consumer、旧cursor、未ack覆盖尝试及VICTORY+lethal vector，When加载/发布/消费，Thenmanifest/hash/header逐字段matching，重复ACK无effect、未知bit fault；缺P1/P2确定性降级且五维零增量，缺任一P0加载失败；未达`0b111`的transient禁止覆盖，critical row保留至matching row ack mask恰为`0b111`后才进入ACKED，overflow fault；REVIVE row含generation/safety，VICTORY vector不含DEATH/HIT/REVIVE事件。
- **AC-PC47 `[I][R]` HUD发布门**：Given raw hit、未提交resolution、已提交Player snapshot依次出现，When HUD刷新，Then前两者不改变HP显示，只有matching已发布snapshot可更新HP、生命和替身符。
- **AC-PC48 `[I][R]` 复活HUD原子性**：Given一次合法复活，When authority publish，Then HUD在同一snapshot显示`HP=0.35×max_hp`、`SPENT`、`generation+1`，不得出现可见的中间HP=0死亡帧。
- **AC-PC49 `[I][R]` UI状态组合**：Given复活+pause、胜利+致命、普通死亡、loading、teardown及新battle，When逐帧观察HUD，Then显示状态与权威快照一致，无旧局残留、重复弹层、虚假无敌提示或未提交状态。
- **AC-PC50 `[M][BLOCKED-UX]` 可读性、遮挡与可访问性**：Given冻结BattleUI布局、字号、安全区、目标设备和预登记脚本，When至少5名测试者在每种目标分辨率完成20次HP/替身符识别，Then每人正确率`≥19/20`、中位响应`≤1s`，关键warning/摇杆遮挡率为0；AVAILABLE/SPENT在灰阶与三类常见色觉模拟下仍由非颜色形状区分。缺规格/artifact/raw记录则INCONCLUSIVE。

### J. Mobile Fantasy and Performance

- **AC-PC51 `[M][OPEN]` 松手归零延迟协议**：Given冻结build hash、设备/OS、60Hz模式、时钟同步与trace schema，When每档×每手预热3次后记录至少100次有效release，Then从OS release timestamp到matching ZERO motion publish timestamp的`p50/p95/max`均报告且`p95≤50ms`，丢帧/无效样本按预登记理由剔除并保留raw trace；缺任一元数据或positive timestamp sanity check则INCONCLUSIVE。
- **AC-PC52 `[I][M][BLOCKED-FIXTURE]` “手指即身法”灰盒**：Given与InputSystem AC-IS28相同的immutable fixture及hash，且使用本GDD冻结后的数值`player_collision_diameter`，When恰好5名预登记参与者按每档、每手3次warm-up和20次计分完成窄道与两次90°反转，Then每人每个“档×手”cell均至少18/20在timeout内无碰撞抵达；不得跨人汇总或补试。
- **AC-PC53 `[M][OPEN][BLOCKED-HAZARD-CONTRACT]` 最低规格性能协议**：Given manifest-bound设备/OS/build、release artifact、60Hz、GameRoot 1191-active full baseline与`PWM03`精确hazard/300-clear vector，When先跑Player isolated microbenchmark，再用1000个fresh battle或pre-armed immutable fixture完成1000次revive（load/reset在marker外归COLD，禁止同实例SPENT→AVAILABLE），Then逐run报告p50/p95/p99/max、五维allocation delta、scan/sort/selector/HUD/event counters与无overflow；gameplay state/workload/config hash跨同seed运行一致，raw sample artifact hash只要求各自存在可校验、不要求彼此相等。缺任一row/hash/marker/容量/预算/raw evidence则OPEN/INCONCLUSIVE。
- **AC-PC54 `[U][I]` 起始最大HP解析**：Given`long_chun_level=0..5`、锻体丹`false/true`与边界/非finite恶意输入，When Config执行F3A并初始化Player，Then合法组合逐值等于`base×(1+0.03×level+(pill?0.15:0))`且`current_hp=max_hp=resolved_starting_max_hp`；非法或越界组合在BATTLE_LOADING失败，Active修改请求零写入。
- **AC-PC55 `[U][I][BLOCKED-RECOVERY-GDD]` 恢复顺序与事实**：Given恢复0、满血恢复、非致命伤害+恢复、过量恢复、致命伤害+恢复与stale recovery token，When phase6执行，Then固定damage→lethal→recovery顺序、恢复clamp、致命抑制不结转；仅实际恢复量大于0时恰一条HEAL fact，DAMAGE+HEAL时sequence严格递增，最终HP/HUD恰发布一次，stale输入零写入。
- **AC-PC56 `[U][I][R]` 派生表现帧与一体提交**：Givenmotion/HUD同revision、跨revision、generation stale及带/不带各optional事件的prepared tuple，When调用one-shot commit并取得frame，Then提交顺序严格为`bundle→motion?→HUD→transient?→critical?→Node`且每项0/1次；frame只由同revision已发布motion+HUD copy-out生成，无独立selector/backing，任何错配返回失败且out不变、consumer不可ack事件。
- **AC-PC57 `[U][I][BLOCKED-INTEGRATION]` REVIVE_CLEAR归属与计容**：Given0/1/300 clear rows及Player/Enemy双方容量manifest，Whenprepare、reserve、推进与故障收敛，ThenPlayer只写intent bank并调用scoped resolver；所有journal row的`participant_id=ENEMY`且计入ENEMY 303上界，PLAYER lifecycle contribution恒为0，只有Enemy/GameRoot持journal backing并执行Grid/Pool副作用。
- **AC-PC58 `[U][I][BLOCKED-INTEGRATION]` HP authority copy-out**：GivenPlayer damage/recovery/revive输出与仅Enemy/Drop等非Player owner推进authority revision的对照，WhenGameRoot每次full-copy并调用`copy_player_hp_authority_into`，Thenview逐字段等于当前published Player slice且authority revision始终matching；HUD可保持旧revision但不影响该view。stale expected revision、旧generation、teardown/new-run均拒绝且out不变，Drop直接HP写入为0。

## Open Questions

以下仅保留尚未决的问题；已冻结规则不在此重复。`BLOCKED`项阻塞对应集成、production或证据gate，但不被误记为当前已解决。

| ID | Status | Question / Required Decision | Owner | Target Resolution |
|---|---|---|---|---|
| OQ-PC01 | DEFERRED-ADR | Player根节点采用`Node2D`还是仅作容器的`CharacterBody2D`？无论选择哪种，都不得使用`move_and_slide()`产生第二套移动权威。 | Godot Specialist | Player实现开始前 |
| OQ-PC02 | BLOCKED-DAMAGE-GDD | 正式冻结`PlayerDamageResolutionV1`、同tick聚合、reason code、DAMAGE/DEATH fact及RunOutcome投影的唯一owner。 | DamageSystem GDD | Damage集成与AC-PC14、AC-PC22–34、AC-PC42前 |
| OQ-PC03 | RE-REVIEW-PENDING | EnemySystem已静态接纳同版`EnemyThreatSnapshotV1`、next-tick swept bound与REVIVE_CLEAR完整tuple接口；仍须其clean-context复审和runtime integration证明。 | EnemySystem + Config | 复活集成前 |
| OQ-PC04 | BLOCKED-TUNING | 冻结`player_collision_diameter`与每类Enemy `shape_bound`；清除只使用真实足迹相交，不存在独立production清除距离旋钮。 | Systems Designer + Enemy Owner | AC-IS28 fixture及production config冻结前 |
| OQ-PC05 | FULL-REVIEW-PENDING | 第四轮lean整改已补齐恢复/maxHP、派生presentation join、一体输出commit及REVIVE_CLEAR归属；仍需clean-context full re-review与creative-director确认。 | GameRoot + Config Owner | 下一轮独立full review |
| OQ-PC06 | PARTIAL-PROPAGATION | Drop、Weapon/Targeting、BattleUI已完成作者GDD并反向核对Player只读/ACK边界；GameRoot atomic bundle、runtime集成与各自独立full review仍待完成。 | Systems Owner | AC-PC39/58执行前 |
| OQ-PC07 | BLOCKED-TOOLING | 创建并验证`tools/ci/static_guard_check.py`正反fixture，同时冻结Godot运行时分配采样器与positive control。 | QA Lead + Performance Analyst | AC-PC40/41执行前 |
| OQ-PC08 | BLOCKED-ASSET | 冻结Player表现资产manifest、P0/P1/P2分级、预载fallback、VFX池容量及GPU降级规则。 | Art Director + Technical Art | production asset manifest前 |
| OQ-PC09 | BLOCKED-UX | 冻结BattleUI布局、安全区、字号、替身符状态、暂停组合、可访问性与遮挡验收方案。 | UX Designer | AC-PC50真机验收前 |
| OQ-PC10 | PARTIAL-AUDIO-PROPAGATION | Audio作者GDD已冻结PLAYER_AUDIO bit0b100、DAMAGE transient与REVIVE/DEATH critical ACK时机、priority/bus/降级；正式资产、Godot paused playback、22-voice真机与event ABI仍BLOCKED。 | Audio Designer | 音频集成前 |
| OQ-PC11 | BLOCKED-TEST-PROTOCOL | 冻结最低规格设备、release artifact、统一帧预算、采样器误差/排除预算、输入延迟trace及移动端测试矩阵；协议冻结后，尚未执行的结果另标`OPEN-EVIDENCE`。 | QA Lead + Performance Analyst | AC-PC51–53执行前 |
| OQ-PC12 | BLOCKED-HAZARD-CAPACITY | `ReviveHazardSnapshotV2` shape语义已由Boss传播；仍需冻结Enemy nonprojectile/Stage贡献、精确总容量与303敌人并存workload。 | Stage/Projectile/Enemy/Boss + Config | 复活production集成与AC-PC18/20/53前 |
| OQ-PC13 | RESOLVED-AUTHORING / RE-REVIEW-PENDING | 唯一`PlayerRecoveryResolver` owner已指定为DamageSystem，并冻结phase-5聚合顺序与A/B发布边界；待Damage/Player clean-context full review验证。 | DamageSystem + Player + Config | 恢复集成与AC-PC55前 |
