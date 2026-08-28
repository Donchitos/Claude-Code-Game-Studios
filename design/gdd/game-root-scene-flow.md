# GameRoot & Scene Flow（全局根与场景流）

> **Status**: Re-review Pending — 第三轮 full design-review（NEEDS REVISION）全部 BLOCKING 已按权威 owner 聚焦修订，待第四轮独立复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-08-28 — 第三轮 full design-review 后修订；不代表 runtime、performance 或 evidence gate 已通过
> **Implements Pillar**: 战斗—暂停选择—结算—再开局的可靠闭环
> **Scope**: MVP minimum；不定义各玩法系统内部规则
> **Review Mode**: full；InputSystem 内部 FSM 以 `input-system.md` 为唯一权威，本 GDD 只冻结 GameRoot 可观察编排契约

## Overview

GameRoot 是唯一的场景流控制器和战斗 physics phase 编排者。它负责洞府、开局准备、战斗、暂停选择、结算与受控故障之间的合法转换；在战斗中，它显式调用所有 phase participant，而不是依赖 Godot Node 的隐式 `_physics_process` 顺序。GameRoot 还拥有本局的权威状态 bundle、查询/碰撞阶段的双缓冲 staging、SpatialGrid lease 调度，以及 pause/resume 的可回滚引用交换。它不计算伤害、不生成敌人、不选择技能，也不替各系统拥有业务对象。

## Player Fantasy

玩家应感觉每次进入试炼、暂停选择、恢复战斗和结算都干净、即时且可信：点击暂停后不会再挨一刀，升级或机缘选择不会造成重复奖励，恢复时不会出现幽灵敌人或目标跳变，系统异常也不会伪装成一次正常失败。GameRoot 的理想表现与 SpatialGrid 一样是“无感”——玩家只感到战斗节奏连贯、页面切换确定、意外情况下游戏诚实地停止并保护局外数据。

## Detailed Rules

### R1 — 单一 owner 与 process 规则

- GameRoot 是唯一 gameplay physics 编排者，精确使用 `PROCESS_MODE_ALWAYS`；`_physics_process(delta)` 只在允许技术 tick 时驱动七 phase，`_process(delta)` 只在 Paused/Resume 驱动 control pump。participant 不得定义自主 gameplay `_physics_process/_process/_input/_unhandled_input`。
- participant 在 load 时按稳定表注册，Active 后不可增删或重排；接口为 `run_phase(phase, context, lease_id) -> int status`。GameRoot 独占 SpatialGrid `begin_phase/end_phase`，lease 只在当前同步调用栈有效。
- InputSystem 的状态机、callback ABI、held-touch bank、geometry rebuild 与三字段 tuple 以 `design/gdd/input-system.md` 为唯一权威。GameRoot 只依赖其公开 API、primitive status 与后置条件，不复制内部 FSM。
- GameRoot 是 battle Viewport `gui_disable_input` 的唯一 writer；正确 setter 为 `set_disable_input(bool)`。固定激活序列为 `PRE_ACQUIRE → SET_TRUE_IN_FLIGHT → GATE_HELD → Input ACTIVE publish → GameRoot local commit → reasoned release`。
- `SceneTree.set_pause(false)` 返回后，GameRoot **显式**执行 post-unpause observer；不得等待 `PROCESS_MODE_ALWAYS` 的 Host/shield/VJ 收到 `NOTIFICATION_UNPAUSED`。Input geometry 事件源和 Window→Host relay 归 InputSystem，GameRoot只消费其 typed invalidation revision。
- bootstrap、Viewport gate、callback 重入、allocation 与移动端 lifecycle 的运行时真实性必须通过 GATE-OQ；正文目标行为不等于 evidence 已通过。

### R2 — 场景与战斗状态机

MVP 顶层状态固定为：

| State | 玩家可见页面 | 允许行为 |
|---|---|---|
| `BOOT` | 启动遮罩 | 装载最小配置/存档；成功后进入 HOME，失败进入 CONTROLLED_FAULT |
| `HOME` | 黄枫谷洞府 | 打开功法/掌天瓶入口，进入 PREP |
| `PREP` | 掌天瓶准备页 | 选择或跳过灵药，创建 immutable `RunStartRequest` |
| `BATTLE_LOADING` | 战斗加载遮罩 | 构建immutable Config snapshot，按其上限预分配bundle/carrier，依次初始化SpatialGrid、BattlePoolSet与owners |
| `BATTLE_ACTIVE` | 战斗页 | 执行完整 physics tick；接受 pause/end intent |
| `PAUSE_PENDING` | 战斗画面 + 输入锁定；必要时显示“正在稳固战局…” | 不产生新 gameplay intent，只执行最多一个 drain tick |
| `BATTLE_PAUSED` | 手动暂停、升级、宝匣或机缘选择层 | gameplay frozen；可读 frozen snapshot；blocking choice 完成前不可恢复 |
| `RESUME_PREPARING` | 保持暂停层；必要时显示“松开手指后继续” | consumer closed；执行 prepare→arm→owner swap→publish→lease close，或在publish完成且无open lease后执行RESUME_HELD_DRAIN |
| `BATTLE_ENDING` | 战斗输入锁定 | 在安全边界完成 teardown，生成 normal outcome 或 abandoned outcome |
| `SETTLEMENT` | 结算页 | 展示成功/失败统计与奖励；可再战或回洞府 |
| `CONTROLLED_FAULT` | 技术故障阻断层 | 停止 gameplay 与 fault tick 新奖励发布；按 fault 前已提交事实尝试部分奖励补偿，只允许安全返回洞府 |

合法主路径为：

`BOOT→HOME→PREP→BATTLE_LOADING→BATTLE_ACTIVE↔PAUSE_PENDING/BATTLE_PAUSED/RESUME_PREPARING→BATTLE_ENDING→SETTLEMENT→HOME/PREP`。

BATTLE_LOADING 固定顺序为：`Config build(battle_ready, RunStartRequest.run_seed) → RNG init(snapshot.run_seed) → 按同一 snapshot ID 预分配 carriers → Input initialize → SpatialGrid.init → Pool.init → owners warmup → owner/Grid/Pool snapshot ID 一致性预检 → Viewport gate acquire → Input ACTIVE publish → GameRoot BATTLE_ACTIVE local commit → ACTIVATION_SUCCESS release`。任一步失败都保持 consumer 与 battle input 关闭，逆序 cleanup；只有全部成功才开放第一下 fresh OS press。

任意非法边在 debug assert；release 返回 `WRONG_STATE`、保持原状态并限频记录。`CONTROLLED_FAULT` 只能经完整 cleanup 返回 `HOME`，不能直接恢复当前 battle。

### R3 — BattleAuthorityBundle 与 ownership

- GameRoot 在进入 BATTLE_ACTIVE 前预分配两个等容量 `BattleAuthorityBundle` bank（A/B）及两个 `ResolutionStagingBank`。一个 authority bank 为 published，只读给 consumer；另一个为 inactive staging。引用交换是 O(1)，不得逐条复制后宣称原子。
- authority bundle 至少包含：`authority_revision`、SpatialGrid authoritative registration SoA、各生命周期 owner 的 active handle/object-ID view、target cache 与本 tick deferred-removal queue。具体 gameplay 字段归各系统 GDD，但必须进入同一可切换 bundle 或提供等价可回滚 bank。
- ResolutionStagingBank 至少分区保存 damage、pickup、target-selection 与 consumer-defined effects 的定容记录。consumer 只能写 inactive resolution bank；任何 query/resolve/fatal narrowphase failure 都丢弃整 bank。
- 每次写 inactive authority bank 前按冻结 `AuthorityCopyManifest` 逐字段复制当前 published 权威范围，再应用 mutation。A/B 每个 primitive carrier 在 BATTLE_LOADING 预 resize 到最大长度并保持独占 backing；Active/Paused 路径禁止 `clear/resize/append_array/duplicate/slice`、共享 COW alias 与容器替换。每个字段以自己的权威 `count` 定义 `[0,count)`，tail 非权威。禁止 dirty-patch；具体分配行为由 allocator evidence 验证，不把 Variant 表示等同于 heap allocation。
- resolution publish 同时写唯一 `published_tick_revision`；DEFERRED_REMOVAL只能消费等于当前 tick且尚未消费的bank一次。failure不生成新published token，因此不得重新消费上一tick的resolution。
- 正常 DEFERRED_REMOVAL publish 后，`authority_revision` 必须等于当时仍权威的 SpatialGrid `snapshot_revision`；Paused resume candidate则预置为arm预检的 next snapshot revision，matching publish后两者必须相等。
- GameRoot 只拥有 bundle 与 bank 引用，不因此拥有 pooled Node 生命周期。对象仍由 Enemy/Drop/Projectile 等 lifecycle owner 管理；release/queue_free 必须遵守 SpatialGrid 的 remove-success 后置条件。
- 每个 bank 都在 battle load 时定容。Active tick、pause drain、resume publication 与 fault cleanup 不得扩容或创建 Array/Dictionary/RefCounted result。

### R4 — 唯一 Active physics tick

`BATTLE_ACTIVE` 的每个技术 tick 严格执行以下步骤；空工作 phase 也必须 begin/end：

| Order | Spatial phase | GameRoot 行为 | publish point |
|---:|---|---|---|
| 1 | `SPAWN_INTENT` | 调用 spawn/despawn intent participant；处理新spawn insert与sync前cancel/remove | 无 |
| 2 | `MOVEMENT_COMMIT` | 稳定顺序先调用InputSystem写movement carrier，再调用Player/Enemy movement并逐handle stage最终committed position | 无 |
| 3 | `GRID_SYNC` | 调用 `SpatialGrid.sync(lease_id)` | 仅 sync=`OK` 发布 Grid snapshot |
| 4 | `QUERY` | Damage/Projectile/Player/Enemy 写 caller-owned query buffers | 无 |
| 5 | `QUERY_CONSUME` | resolve handle、执行 shape/swept narrowphase、写 inactive resolution bank | matching end=`OK` 后一次交换 resolution bank |
| 6 | `DEFERRED_REMOVAL` | 应用已发布 damage，处理死亡/拾取/回收，按 remove→release 顺序更新 inactive authority bank | matching end=`OK` 后一次发布 authority bundle |
| 7 | `POST_DEFERRED_BARRIER` | 记录指标、按优先级latch battle-end/pause intent；pause时先InputSystem cancel，成功后才调用`request_pause(lease_id)` | matching end 生成下一 expected tick pair |

每个 phase 使用同一模板：

1. `begin_phase(expected_phase,tick_revision,lease_out)`；
2. 若 begin success，按稳定 participant 顺序执行 phase；
3. phase 末尾检查 RNG 等 service participant 的 `has_fault()`（无参形式，任一流 FAULTED 即 true）。RNG 是 service participant，无独立 phase 边界检查机会，故由 GameRoot 在 phase 边界集中检查（强制，非可选；消费方 `has_fault(stream_id)` 守卫为二级防御，见 rng-system R8）。`has_fault()=true` 视为本 phase transaction failure，转入步骤 4 的 fault path——fault 返回的零值（如 `weighted_pick` index 0）与合法高权重结果不可区分，仅 fault latch 区分，故不得在未检 `has_fault()` 前将 roll 返回值用于 gameplay 决策；
4. 无论 participant success/failure，都以 single-exit cleanup 调 matching `end_phase(lease_id)`；
5. 只有 participant 与 matching end 均 success 且无 service `has_fault()` 命中才进入下一 phase；唯一控制流例外是 R6 barrier 的 `PENDING_WORK`，其 matching end后进入PAUSE_PENDING；其余情况执行 R5 fault path。

Gameplay elapsed time、波次计时、Buff duration 与玩家可见战斗计时只在普通 `BATTLE_ACTIVE` tick 增加；PAUSE_PENDING drain tick 不增加这些时钟。

### R5 — status 分类与整阶段 rollback

- GameRoot 必须按 primitive enum 比较 SpatialGrid/consumer status。只有 API 契约声明的 success class 可继续；不得用 truthy、字符串或“非负值”判断。
- InputSystem的`InputStatus`同样只有`OK`为success；state publish、barrier/resume/foreground cancel或Host invalidation rebuild任一非OK通常记录为first failure，保持shield/consumer closed并走本节fault path。唯一控制分类例外是BATTLE_LOADING中typed `preactive_invalidation_latched=true`时initialize或`IDLE→ACTIVE`返回的`WRONG_STATE`：它表示APP_BACKGROUND/INPUT_GEOMETRY_CHANGED安全中止，GameRoot保持IDLE=`true/false/false`、逆序cleanup回PREP，不记录technical fault；同status在其他state或无该latch时仍按failure处理。若status来自Host async latch，触发该返回的同步API已在验证本次caller tick前原子capture+ack，并以InputSystem内部最近一次已接受的`safe_close_tick_revision`执行一次state-aware safe-close：ACTIVE先原子进入LOCK_PENDING=`true/false/true`再STOP/clear，IDLE保持`true/false/false`，既有locked state保持`true/false/true`。GameRoot不得要求它采用本次invalid/stale tick，也不得因返回captured root status重复调用原API。GameRoot保存该status为权威根因，下一步直接调用teardown，已消费latch不得再次遮挡cleanup。GameRoot不得在失败后从phase/context隐式“补”Input状态。
- Host rebuild的root status必须按InputSystem精确表原样保留：argument、stale identity/revision、wrong state、invalid config、dirty clean、epoch exhaustion与candidate/tree/signal failure不得折叠为通用failure；GameRoot对任一非OK都保持consumer closed并fault，但telemetry与fault-injection oracle使用原status，cleanup failure只作suppressed diagnostic。
- `PENDING_WORK` 只在 R6 的 pause barrier 是可重试控制结果；它在任何其他调用点都视为 contract violation 并进入 fault。
- `QUERY` 中任一 query failure、`QUERY_CONSUME` 中任一 `resolve_active_into` failure，以及 consumer 明确声明的 fatal narrowphase/domain failure，均使**整个 query/collision transaction**失败。GameRoot不得读取 failure carrier，不得发布较早 consumer 的 staging。
- 普通 no-hit/shape-not-intersect 是合法 gameplay result，不是 failure；它不触发 rollback。
- failure 顺序固定为：标记 transaction aborted → 调Input的state-aware consumer-close（ACTIVE原子进入LOCK_PENDING=`true/false/true`；既有locked保持该tuple；IDLE保持`true/false/false`且不启service）并关闭consumer → 清零 inactive staging count/authority candidate validity → matching end cleanup → 记录 first-failure `{status,api,participant,phase,tick,snapshot}`（RNG fault 的 first-failure 须含 `run_seed`、各流 `stream_id`/调用计数/state，与 rng-system R7 telemetry schema 对齐，供 AC-G2 可复现诊断）→ 进入 `CONTROLLED_FAULT`并调用Input teardown，随后 RNG teardown（各流 state 写入 first-failure telemetry）。首个 failure 权威，后续 cleanup failure或迟到async callback追加suppressed diagnostic，不能覆盖根因；teardown必须先原子提交TERMINATED=`false/false/false`并撤销callback写权，再执行route/node cleanup。
- query/collision transaction success 时，仅在 `QUERY_CONSUME end_phase=OK` 后交换 resolution bank。deferred lifecycle success 时，仅在 `DEFERRED_REMOVAL end_phase=OK` 后交换 authority bundle。因此任何 phase/end failure 都不会留下部分 gameplay effect。

### R6 — pause intent、PENDING_WORK 与 drain tick

- pause source 固定为 `MANUAL`、`LEVEL_UP`、`TREASURE_CHOICE`、`RISK_CHOICE`、`APP_BACKGROUND`、`INPUT_GEOMETRY_CHANGED`。GameRoot只latch intent，不在任意consumer callback中直接pause SceneTree。后两者共享Host invalidation/rebuild协议，不是玩家选择。
- blocking choice优先于APP_BACKGROUND/INPUT_GEOMETRY_CHANGED，两种invalidation优先于MANUAL；多个blocking choice按权威event sequence排队。BATTLE_PAUSED内一次展示一个，全部完成后才允许resume，禁止多个选择层叠加。
- GameRoot 在完成deferred removal与authority publish后，于`POST_DEFERRED_BARRIER`按稳定子顺序执行：收集/排序intent → 写只读context `{pause_intent_latched,pause_reason,tick_revision}` → 调InputSystem participant执行`cancel_input`（其内部先以callback不可观察的纯标量提交原子发布`ACTIVE→LOCK_PENDING + true/false/true`，再启完整movement-rect STOP shield，最后按pressed/raw dirty predicate清actions/carrier）→ 只有InputStatus=`OK`才调`SpatialGrid.request_pause(lease_id)`。`ACTION_CLEAR_FAILED`保留LOCK_PENDING tuple但不得调用Grid pause，须先matching end再进入fault。其他Input非OK同样不得调用Grid pause。Grid返回：
  - `OK`：完成 matching end 后，先以已发布 authority bundle 的定容 borrow-ID carrier（含BOUND实体与UNBOUND投射物）调 Object Pool `begin_quarantine(snapshot_revision,...)`；只有 matching quarantine=`OK`，再调用`InputSystem.publish_runtime_state(FROZEN,tick_revision)=OK`，才进入`BATTLE_PAUSED`、设置SceneTree paused并开放相应pause UI；state publish非OK保持UI/consumer closed并fault；
  - `PENDING_WORK`：保持 Grid Active，完成 matching end，进入 `PAUSE_PENDING`；立即锁定 gameplay 输入/新 spawn/AI/攻击/战斗计时，若跨过一个 render frame则显示非交互“正在稳固战局…”；
  - 其他 status：matching cleanup 后进入 `CONTROLLED_FAULT`。
- PAUSE_PENDING 只允许一个 `MAX_PAUSE_DRAIN_TICKS=1` 的额外 drain tick。“首次request”定义为进入pause路径后第一次实际调用`SpatialGrid.request_pause`；foreground preflight只执行Input cancel与Host rebuild，不调用Grid request，因此preflight后紧接的第一个零gameplay-dt technical tick中调用的是“首次request”，不计入`extra_pause_drain_ticks`。若它返回`PENDING_WORK`，才允许唯一额外drain tick。额外tick仍完整begin/end七个phase以保持revision trace，但不得产生新gameplay intent：SPAWN/MOVEMENT不新增工作，GRID_SYNC只提交遗留pending/staged，QUERY/QUERY_CONSUME不产生效果，DEFERRED_REMOVAL只完成已排队cleanup，battle timers不推进。额外drain barrier返回`OK`则Frozen；仍为`PENDING_WORK`或任何failure则fault。
- pause intent 发出后，从当前 tick 尚未完成的合法 staging可以正常提交；进入 PAUSE_PENDING 后不再产生新的伤害。因而玩家不会在“正在暂停”的 drain tick继续受伤。
- APP_BACKGROUND lifecycle或Host safe-area/resize callback以checked monotonic signed 64-bit counter为本次事件分配新的正`input_rebuild_revision`；每个新APP_BACKGROUND另分配严格递增的正`background_revision`并令`background_readiness_required_revision=background_revision`，立即使readiness gate未满足，duplicate同revision不推进，多个未确认事件可coalesce为最新required。`background_readiness_acked_revision`只由全部preflight/choice完成后的合法readiness/Continue推进到当时最新required；旧ack不得跨越更新的required。callback latch reason并同步设置`foreground_input_blocked=true`，Host同时令active node不可命中新press。耗尽时保持consumer closed并fault，不复用旧revision。runtime ingress已开放时callback除唯一hit-route disable外不写其他Node属性，且不写actions/carrier、不迁移顶层状态、不重建节点；preactive时只写bootstrap invalidation latch并由BATTLE_LOADING安全中止。若Active当前tick能完成，则按上述barrier cancel；若进程直接挂起，恢复后的preflight在任何普通BATTLE_ACTIVE tick前依次完成Input cancel与`ensure_rebuilt_after_invalidation(input_rebuild_revision,geometry_snapshot,tick_revision)`。preflight不调Grid request；成功后直接启动PAUSE_PENDING的第一个零gameplay-dt technical tick，其barrier完成本次pause路径的首次`request_pause`。首次OK则Frozen；首次PENDING则仍可按F2执行唯一额外drain。preflight非OK不得运行任何七phase；RESUME_PREPARING重复ensure只有在同revision、fingerprint相等且完整canonical geometry field bits逐项相等时才可无副作用跳过重建。

#### Input invalidation 全状态矩阵

本GDD中“同revision + fingerprint + canonical geometry fields”均为简写，权威含义与InputSystem一致：geometry和instance-frozen candidate-config两个fingerprint及两组完整canonical fields必须全部exact equality；任一不等返回`STALE_TICK`且不得命中no-op。

| GameRoot state | APP_BACKGROUND / INPUT_GEOMETRY_CHANGED 后的唯一处理 |
|---|---|
| `BOOT/HOME/PREP` | 无battle Host；页面lifecycle自行恢复，不创建VJ |
| `BATTLE_LOADING` | runtime ingress始终未arm；touch走PREACTIVE_DISCARD；background/geometry写preactive invalidation latch。initialize或ACTIVE publish观察后返回typed `WRONG_STATE`，GameRoot逆序cleanup回PREP且technical fault=0；不得恢复partial load或静默继续ACTIVE |
| `BATTLE_ACTIVE` | latch pause；当前tick可完成则走barrier，否则foreground preflight后先运行首次零gameplay-dt pause tick；首次request=PENDING时再按F2允许恰一个额外drain，不运行普通Active tick |
| `PAUSE_PENDING` | 保持consumer closed；preflight成功前不继续drain或开放UI输入 |
| `BATTLE_PAUSED` | 保持Paused；每个main-loop iteration先service pending Input fault；preflight cancel+rebuild成功并推进VJ/shield epoch后，才允许choice gate按Host结果开放 |
| `RESUME_PREPARING` | 立即启shield并关闭ingress，每iteration先service pending Input fault。首次Grid/Pool matching publish前：invalidation先dirty-aware cancel/verify再恢复old owner、abort/close并rollback；合法shield-held touch则fault-free恢复old owner、abort/close、rollback FROZEN并回Paused等待terminal。不可逆点后：invalidation完成正确publish/cleanup后fault；合法shield-held touch完成publish/cleanup后保持RESUME_LOCKED、SceneTree paused、无open lease进入RESUME_HELD_DRAIN，terminal后只执行ACTIVE尾段 |
| `BATTLE_ENDING/CONTROLLED_FAULT` | 保持ingress永久关闭，不重建，继续teardown；迟到signal只计诊断 |
| `SETTLEMENT` | battle Host已teardown，不创建/重建VJ；页面lifecycle自行恢复 |

> **Foreground readiness override**：`INPUT_GEOMETRY_CHANGED`在应用始终foreground且无MANUAL/APP_BACKGROUND/choice残留时，preflight、Grid pause/quarantine与Input FROZEN publish成功后可自动生成resume latch。reason集合含`APP_BACKGROUND`时，无论是否与geometry/choice/MANUAL合并，foreground后都保持Paused、gameplay phase/damage/timer推进数为0；全部preflight与choice完成后必须等待一个真实readiness/Continue，使`background_readiness_acked_revision`追平当时最新required。MANUAL与APP_BACKGROUND只共用一个确认，不叠加按钮；该press不建立movement generation，ACTIVE后仍等待新的OS movement press。确认后、ACTIVE publish前若到达更新的background revision，required立即领先acked并重新关闭readiness gate；generic resume latch可保留，但不得自动重试，直至新revision完成preflight并再次确认。

### R7 — Paused read、choice 与原子 resume

- BATTLE_PAUSED 中 gameplay participant 全部冻结。UI 若需查看技能/属性/进化关系，可开启不重叠 `PAUSE_READ` lease读取 frozen snapshot；每次 read 必须 matching end，不能与 RESUME_EXCLUSIVE 重叠。
- GameRoot的paused control pump在每个BATTLE_PAUSED/RESUME_PREPARING main-loop iteration、每次choice/resume入口先调用`InputSystem.service_pending_input_fault(tick_revision)`；无latch时包括Input内部trusted tick在内完全零修改并返回OK，非OK在同iteration保存root status并进入fault cleanup，禁止继续读取choice predicate或开lease。BattleUI随后在每次choice press入口读取`VirtualJoystickHost.is_choice_input_blocked()`；true时只消费并忽略该press，不提交choice intent。该值在旧VJ movement claim或shield-held bank任一非空时为true；两者为空，或invalidation preflight已checked推进相应epoch并淘汰旧epoch时才可false。BattleUI不得自行缓存或推断该值。场景输入顺序固定为可交互pause/choice UI→consumer-closed movement shield→VJ；shield不得覆盖或吞合法UI target，也不得夺走旧VJ touch-focus release/cancel。
- 手动暂停只改变 UI state；升级、宝匣、机缘选择可以修改 inactive authority bank/config-derived runtime state，但不得直接调用 SpatialGrid mutation。frozen registrant 与可能被移除的 Node在 publish/teardown 前 quarantine，不能返池再借出。
- GameRoot按下表从冻结的pause reason集合生成唯一`resume_requested_latched`；它是幂等bool，不计数、不队列化，只有ACTIVE publish成功、battle ending或fault cleanup才清除。APP_BACKGROUND的玩家准备度另由checked monotonic `background_readiness_required_revision/background_readiness_acked_revision`配对表达，不能复用generic bool冒充每个新background都已确认；battle创建时两者均为0，ACTIVE publish成功、battle ending或fault cleanup后均安全归零，任一resume attempt在途时禁止reset或equalize掩盖新revision。duplicate/coalesced reason不得累计intent或重复choice effect：

| Paused reason组合 | 置`resume_requested_latched=true`的唯一条件 | Continue要求 |
|---|---|---|
| `MANUAL` only | 合法Continue press被接受 | 必须 |
| blocking choice only | 全部choice按event sequence提交完成 | 不需要，自动 |
| `INPUT_GEOMETRY_CHANGED` only（始终foreground） | reconfigure preflight、Grid pause/quarantine与Input FROZEN publish全部成功 | 不需要，自动 |
| geometry + blocking choice（无MANUAL/background） | 上述preflight/FROZEN完成且全部choice提交完成 | 不需要，自动 |
| 任意组合含`APP_BACKGROUND` | foreground preflight/FROZEN及全部choice完成后，合法readiness/Continue同时置generic latch并令acked追平当时最新required；若新background revision随后到达则generic latch可保留但revision gate重新不满足 | 每个尚未确认的最新revision必须；与MANUAL共用一个确认 |
| 任意组合仍含`MANUAL`但无background | choice/geometry完成后保持latch=false；合法Continue被接受才置true | 必须 |

每个Paused iteration在无resume transaction在途时先service pending Input fault，再读取`is_choice_input_blocked()`；只有`can_start_resume = resume_requested_latched && background_readiness_acked_revision == background_readiness_required_revision && predicate==false`才由pump自动且恰启动一个resume attempt。predicate或revision gate任一blocked时保留已有generic latch、保持BATTLE_PAUSED，并仅在aggregate blocked predicate由false→true时显示一次低打扰反馈，期间不重复动画/音效/震动/辅助功能播报；只有aggregate predicate由true→false时清除一次。若generic latch=false，terminal只解除block，绝不能凭空创建resume intent；若acked不等于required，terminal也不能替代readiness确认。同一choice authority mutation不得重复应用。每个attempt固定保存`attempt_input_rebuild_revision`、`attempt_background_revision`与`attempt_geometry_snapshot`；任一可重入边界若当前`input_rebuild_revision`或background required/acked不再等于保存值，或出现新的invalidation latch/reason，即为`attempt_invalidation_changed`，不得由pending Input fault或held检查替代：
  1. 在consumer closed且未开Grid lease的一个无await、无项目主动callback的main-thread前缀中，再次确认predicate=false且background required/acked相等；随后原子捕获当前`input_rebuild_revision`、`background_readiness_required_revision`与geometry snapshot作为本attempt三项快照，调用`InputSystem.publish_runtime_state(RESUME_LOCKED,tick_revision)`并验证后置精确为`runtime_ingress_armed=false、shield_bank_service_enabled=true`，再调用`cancel_input(RESUME_PREPARING,tick_revision)`且保持同一组合；任一非OK直接fault cleanup；
  2. 若pause reason集合含APP_BACKGROUND或INPUT_GEOMETRY_CHANGED，调用`VirtualJoystickHost.ensure_rebuilt_after_invalidation(attempt_input_rebuild_revision,attempt_geometry_snapshot,tick_revision)`；调用前必须已由Input cancel证明shield/gates closed、carrier当前tick精确clear、pending release为空且四action clean。若preflight已处理同revision，只有fingerprint与完整canonical geometry field bits均相等才是无副作用OK，否则成功时唯一registered新节点、VJ gesture epoch与shield epoch推进、旧shield bank清空且movement carrier仍ZERO。新节点在RESUME_LOCKED/consumer closed期间保持不可命中，只有尾段ACTIVE publish成功且GameRoot完成`ACTIVATION_SUCCESS` release才物理开放；前置或rebuild非OK直接fault cleanup；
  3. 在开lease前再次service pending fault，并读取held predicate与`attempt_invalidation_changed`；若此时shield-held，直接发布FROZEN并回Paused等待terminal，保留`resume_requested_latched`；terminal且service=OK后仅在完整`can_start_resume`恢复时由pump自动启动恰一个新attempt。若revision/invalidation已变化，则走对应invalidation rollback/preflight/readiness路径，不得开lease。否则以 frozen `snapshot_revision` 开 `RESUME_EXCLUSIVE` lease；
  4. 从 inactive authority bank 填充预分配 `AuthoritativeRegistrationBuffer`；
  5. `resume_from(input,remap_out,lease)` 生成 Prepared candidate；
  6. 将 remap 应用到 inactive authority/target-cache bank，不改 published bank，并调用 Object Pool `prepare_resume_bindings(tx,remap,authority_borrow_ids)`；
  7. 依次调用 Grid `arm_resume_commit(tx,lease)` 与 Pool `arm_resume_bindings(tx)`，完成两个系统全部可失败检查；
  8. 保存旧 published bundle 引用，再 O(1) 交换 owner bundle；owner swap失败必须恢复旧引用并 abort两个candidate。prepare、arm与swap后各在下一可重入stage边界先service pending fault并读取held predicate与`attempt_invalidation_changed`；首次matching publish前若发现合法shield-held，恢复旧owner、fault-free abort两个candidate、matching close全部lease、清candidate quarantine并发布FROZEN，回Paused等待terminal且保留唯一resume latch；terminal后仅在完整`can_start_resume`重新为true时自动单次重试。若发现revision/invalidation变化，则同样先走invalidation cancel/abort/close/rollback并保留generic latch；新background使acked落后required时，必须完成新preflight与readiness确认后才可重试。两路都不得重复choice effect、累计intent或同时存在两个attempt；
  9. 依次调 matching Grid `publish_resume(tx,lease)` 与 Pool `publish_resume_bindings(tx)`；第一次matching publish调用开始即越过resume不可逆点，两次matching publish契约上均不可失败且必须 `OK`。两次publish之间若存在可重入边界，先service pending fault并读取held predicate与`attempt_invalidation_changed`；无论发现captured fault、revision/invalidation变化或合法shield-held，都仍以保存的正确tx完成第二次publish与后续cleanup。captured fault或revision/invalidation变化在cleanup后进入fault；只有无前两者的合法held才进入RESUME_HELD_DRAIN；
  10. matching Grid `end_phase(lease)`关闭resume lease；在consumer仍关闭时由Pool清除survivor/new quarantine并完成old→0的RELEASE_PENDING reset/release。cleanup完成后再次service pending fault并读取held predicate与`attempt_invalidation_changed`：captured fault或revision/invalidation变化保持`foreground_input_blocked=true`并进入fault；仅held非空时保持Input=RESUME_LOCKED、SceneTree paused、`consumer_open=false`且`open lease/candidate/quarantine=0`进入`RESUME_HELD_DRAIN`。反馈只在进入drain时触发一次；每个paused drain iteration都按`service→attempt_invalidation_changed→held predicate`顺序复核，revision/invalidation变化立即转fault，全部matching release/cancel后不重跑Grid/Pool resume。held清空后进入固定的**Viewport-gated两阶段激活提交**，期间GameRoot顶层state始终保持`RESUME_PREPARING`且`_physics_process` state gate禁止任何physics/gameplay phase：①验证目标battle Viewport identity、`gui_disable_input=false`与`viewport_input_gate_owned=false`，checked取得owner sentinel并调用`set_disable_input(true)`；等待同步focus/leave/tooltip callback完整返回后，按`service pending fault→attempt_invalidation_changed→held predicate`第一次复核。failure/revision变化保持Viewport disabled并进入点后fault；若仅held重新出现，则保持SceneTree paused、先以`release_viewport_input_gate(HELD_ONLY_RETURN_TO_DRAIN)`恢复Viewport input并清owner sentinel，再回RESUME_HELD_DRAIN以允许matching terminal。②第一次复核clean时，保持Input=RESUME_LOCKED、shield STOP、`consumer_open=false`与`foreground_input_blocked=true`调用`SceneTree.set_pause(false)`；等待同步`NOTIFICATION_UNPAUSED`完整返回后执行同序第二次复核。failure/revision变化立即重新pause并保持Viewport disabled进入fault；held-only重新pause、等待同步pause callback返回后以`release_viewport_input_gate(HELD_ONLY_RETURN_TO_DRAIN)`恢复Viewport input/owner并回drain。③两次均clean才在Viewport disabled下调用带Host activation guard的`InputSystem.publish_runtime_state(ACTIVE,next_tick_revision)`；filter setter的同步notification/signal只能latch，所有`push_input`在Control picking前返回，故VJ event delivery/claim/action/generation均为0。非OK立即重新pause，保持`gui_disable_input=true`、`foreground_input_blocked=true`与`consumer_open=false`并fault。④Input返回OK后不再调用可能派发项目callback的引擎API，只以局部字段提交`foreground_input_blocked=false`、GameRoot=`BATTLE_ACTIVE`、`consumer_open=true`、清`resume_requested_latched`与feedback；最后调用`release_viewport_input_gate(ACTIVATION_SUCCESS)`，由只写bool的false setter作为唯一物理开放点并清owner sentinel。下一physics tick使用SpatialGrid保存的next`(tick,SPAWN_INTENT)`，Input gate仍等待fresh press且carrier为ZERO；Viewport false返回后至首tick前的新OS press可建立generation。除held-only回drain外，任何activation failure的Viewport gate都只在battle input teardown完成且ControlledFault/Home UI成为唯一target后恢复，禁止故障页永久不可操作。
  - RESUME_LOCKED publish、Input cancel或Host rebuild failure发生在Grid lease前，保持旧frozen bundle并直接进入fault cleanup。新APP_BACKGROUND/INPUT_GEOMETRY_CHANGED在首次Grid/Pool matching publish调用前到达时，GameRoot保持shield/consumer closed，先调用`cancel_input(invalidation_reason,tick_revision)`并验证四action`pressed=false/raw=0`、carrier当前tick精确clear且pending release为空；OK时才恢复旧owner引用、abort每个已prepare candidate并matching close所有lease，Input仍FROZEN时publish数=0，已RESUME_LOCKED时再publish FROZEN，随后保留`resume_requested_latched`回Paused做preflight。纯geometry且无manual/background hold在preflight完成后可由pump自动重试；新APP_BACKGROUND revision会推进required而不推进acked，必须等待新readiness确认，不能因保留generic latch自动重试。若该第二次cancel/clean失败，禁止继续正常resume或发布FROZEN，但**允许且必须**执行emergency resource cleanup：保存cancel为root failure→保持shield/consumer closed→若未越过不可逆点则恢复old owner、对每个未publish candidate执行fault-abort、matching close每个open lease、清inactive staging/quarantine→Input teardown→Grid/Pool teardown；cleanup failure只作suppressed status。首次matching publish调用开始后即不可逆；此后到达invalidation或真正故障都必须用保存的正确tx完成尚未完成的matching publish与lease/quarantine cleanup，禁止恢复旧bundle或调用Input rollback，随后保持consumer closed并`CONTROLLED_FAULT` teardown，不重试resume。合法shield-held touch按步骤8-10的fault-free rollback/drain处理，不与invalidation/failure混同。其他Grid/Pool prepare或arm、publish前wrong-tx、owner-swap等failure仍在不可逆点前恢复旧owner引用、fault-abort candidate/关闭lease并fault。Viewport `PRE_ACQUIRE` failure、true setter后的observer、unpause observer或Input activation guard任一失败时，Grid/Pool/owner bundle已一致发布，不回滚三系统；GameRoot必须按步骤10重新pause或维持pause，并保持Input/consumer/foreground block closed。只有已进入`GATE_HELD`的后三类failure保持Viewport true至fault teardown；pre-acquire failure不写Viewport、不取得gate。Grid arm revision exhaustion保持Prepared，只允许fault-abort/end cleanup，不能重试resume；paused candidate-only borrow按Pool fault-abort契约解除transaction quarantine后再由fault teardown清理。
  - Viewport `PRE_ACQUIRE` buffering/identity/owner/gate failure时`gui_disable_input`保持原false、owner=false、true/false setter调用数=0；`SET_TRUE_IN_FLIGHT`或`GATE_HELD` observer/guard failure在true setter最终返回后确认readback并进入held cleanup，保持`gui_disable_input=true`、`foreground_input_blocked=true`、`consumer_open=false`直至Input与battle input nodes teardown完成。只有ControlledFault/Home UI成为唯一输入target后，GameRoot才以`release_viewport_input_gate(LOAD_ABORT_OR_FAULT_CLEANUP)`恰false/clear一次；该恢复不是resume成功、不得清first failure或重新开放battle consumer。
- 上一条所称“preflight完成后自动启动new attempt”只适用于始终foreground的纯geometry路径且无MANUAL/APP_BACKGROUND hold；reason含APP_BACKGROUND或MANUAL时，preflight完成仅解除技术阻塞，仍须按R7等待一个readiness/Continue，terminal本身不得创建intent。
- 任一matching publish后若出现代码路径声称 failure，视为不可达 invariant violation；不得尝试“双向回滚已发布 Grid/Pool”，必须保持consumer关闭并进入ControlledFault teardown。
- Grid matching publish后若故障注入先传wrong tx给Pool publish，Pool保持ARMED；GameRoot必须立即以保存的正确tx完成matching Pool publish，再完成Grid lease cleanup并进入fault，禁止恢复旧bundle。
- 两次publish成功后的 matching resume end只关闭已知Grid lease，不分配或推进revision，使用正确ID时必须 `OK`。若测试先注入wrong-ID end，Grid保持lease open，GameRoot必须立即以保存的正确ID完成一次cleanup并进入fault；此时新Grid、Pool binding与owner bundle已一致发布，禁止恢复旧bundle或开放consumer。

> **第十七轮对R7步骤10的权威覆盖**：步骤10中的“验证并取得gate”拆为`PRE_ACQUIRE(buffering=false/identity/owner/gate validation)→SET_TRUE_IN_FLIGHT(owner acquire + true setter callbacks while bool may remain false；合法ScreenTouch由shield containment)→true return/readback→GATE_HELD`。setter-in-flight只要求VJ/action/carrier/choice/gameplay consumer/top-state effect=0，不要求Viewport delivery=0；loading允许PREACTIVE_DISCARD，resume允许STOP shield `accept_event()`与current-epoch held-bank FSM写。held区间才要求Viewport/Control/VJ delivery=0。第一次observer发现held-only时保持pause并以`HELD_ONLY_RETURN_TO_DRAIN` release；若press与matching release/cancel均在setter返回前完成、bank已回空且其他条件clean，则可继续unpause。unpause后第二次observer发现held-only时先`SceneTree.set_pause(true)`，同步pause notification返回后仍保持Input RESUME_LOCKED/shield STOP/consumer closed，再以同一reason release并回drain。repause callback若写invalidation，由下一paused drain iteration固定的`service→attempt_invalidation_changed→held`在任何ACTIVE retry前必达观察。成功仅以`ACTIVATION_SUCCESS` release；fault/load-abort仅以`LOAD_ABORT_OR_FAULT_CLEANUP` release。每个owner周期false/clear各恰一次。

> **第十八轮对R7的启用谓词覆盖**：步骤1发布RESUME_LOCKED及随后所有cancel/rollback/held-drain/Viewport activation observer都必须保持`callbacks_armed=true、runtime_ingress_armed=false、shield_bank_service_enabled=true`。合法ScreenTouch只在该已启用service内写bank/FSM；callback、first/second observer、held-only release与repause对两个enable字段写次数均为0。只有步骤10的guarded Input ACTIVE局部提交可原子变为`true/true/false`；failure保持`true/false/true`直到Input teardown原子变为`false/false/false`。

### R8 — battle end、teardown 与 scene change

- victory、player death、manual exit 都只产生 `battle_end_intent`。GameRoot 在当前 phase完成安全 cleanup后进入 BATTLE_ENDING；不得在 consumer callback 中直接 `change_scene` 或 free battle root。
- normal victory/death 完成当前 tick的 resolution、deferred removal、authority commit后生成 immutable `RunOutcome` 并进入 Settlement。manual exit 的奖励/消耗策略归 Settlement/Save GDD；在其完成前标为 `ABANDONED`，不得误记为 death/victory。
- BATTLE_ENDING 必须保证没有 open SpatialGrid lease。若Input仍为ACTIVE，先以`BATTLE_ENDING/CONTROLLED_FAULT` reason执行state-aware cancel，使其在任何STOP setter/clear前原子进入LOCK_PENDING=`true/false/true`；若已为LOCK_PENDING/FROZEN/RESUME_LOCKED则cancel保持该tuple；若仍为loading IDLE则不得开启shield bank service，保持`true/false/false`并可直接调用`InputSystem.teardown()`。teardown必须在任何filter setter、disconnect、remove_child或queue_free前先原子提交TERMINATED=`false/false/false`、清bank并撤销bank/choice/pending latch写权，再完成route/node cleanup；之后依次执行 `SpatialGrid.teardown()→BattlePoolSet.teardown(grid_invalidated=true)→SpatialGrid.reset_to_inactive()`。若teardown本身是async latch首观察者，它必须在同一调用capture/ack、完成上述state-aware safe-close与terminal commit并返回captured root status；GameRoot以终态确认cleanup完成且不发起第二次teardown，返回status继续作为first-failure telemetry。terminal commit后的迟到callback只作suppressed diagnostic。旧 handle 与 borrow全部失效后才能 release battle bundle/scene。
- scene load/init failure 不进入 BATTLE_ACTIVE；它返回 PREP 并显示“无法进入试炼，请重试”。若 cleanup 本身无法证明安全，则进入 CONTROLLED_FAULT。
- 快速重复点击开始、返回、暂停或继续必须由 state gate 去重。一次 scene transition 在完成或失败前不接受第二个目标。

### R9 — ControlledGameplayFault 玩家与持久化路径

- `CONTROLLED_FAULT` 是技术故障，不是战斗失败。进入后立即锁定 input、AI、spawn、timer、damage 与新 reward publication；保留 first-failure diagnostic。若尚未越过resume不可逆点，emergency cleanup必须恢复old owner、fault-abort每个未publish Grid/Pool candidate、matching close每个open lease并清inactive staging/quarantine；若已越过不可逆点，则以保存的正确tx完成matching publish、lease与quarantine cleanup。两路都必须在Input/Grid/Pool teardown前达到`open lease=0、candidate=0`，不得把“禁止正常rollback”误解为禁止故障资源释放。
- release UI 只显示低干扰文案：“战局状态异常，本局已安全停止。已按异常前进度结算部分奖励，请返回洞府后重试。”唯一操作为“返回洞府”；dev build 可追加 status/api/phase/tick，release 不显示堆栈或对象 ID。fault 不进入正常 Settlement 页（避免将技术故障呈现为一次正常结算），部分奖励由 SaveSystem reservation/commit 在 HOME 之前透明提交。
- fault run 标记为 `TECHNICAL_ABORT`，不得写入胜负、死亡原因、纪录或教程完成度（技术故障不伪造结局）。但对齐概念设计 12.1「失败仍可获得部分灵石、功法残页和种子」，fault settlement 按已 committed 的存活时间/击杀数授予与 gameplay failure 等价的部分奖励（灵石/功法残页/种子），由 SaveSystem 采用 reservation/commit 提交；奖励源是 fault 发生前已 committed 的统计，不来自 faulted tick 的未结算 staging。开局灵药消耗必须由同一 reservation/commit 补偿；SaveSystem GDD 未完成前，任何会永久消耗灵药或提交部分奖励的集成 story 都是 BLOCKING。
- fault cleanup按`关闭consumer/shield保持STOP→resume emergency cleanup至无open lease/candidate→Input teardown→SpatialGrid teardown→BattlePoolSet teardown(grid_invalidated=true)→SpatialGrid reset`执行并返回HOME；任一cleanup failure只追加suppressed status且继续可安全执行的后续cleanup。若无法证明无open lease/candidate或本地保存/恢复失败，保持fault层并允许应用级退出，不能继续使用可能损坏的battle state。
- 若fault发生时`viewport_input_gate_owned=true`，上述cleanup期间保持目标Viewport `gui_disable_input=true`；Input与battle input节点移除、无open lease/candidate且ControlledFault/Home UI已成为唯一target后，GameRoot调用一次`release_viewport_input_gate(LOAD_ABORT_OR_FAULT_CLEANUP)`并验证false readback及owner sentinel清除。恢复Viewport input只恢复故障/返回页面交互，不得开放battle consumer；若无法证明target已切换则保持禁用并允许应用级退出。
- telemetry 至少记录 artifact/version、run seed、scene state、tick/snapshot、first status/API/participant/phase 与 cleanup suppressed statuses；不得记录玩家隐私或 Node 内存地址。

## Formulas

### F1 — phase transaction commit

对 query/collision transaction 中的调用集合 `C={c1...cn}`：

`transaction_success = all(status(ci) ∈ allowed_success(ci)) AND query_end_status == OK AND query_consume_end_status == OK AND no service has_fault()`

`published_resolution := staged_resolution`（交换 inactive→published bank）当且仅当 `transaction_success=true`；否则 `published_resolution := previous_published_resolution`（**不交换 bank**，inactive staging 整 bank 丢弃，上一 published bank 保持不变——非"清空 published bank"）。普通 no-hit 的 status 仍为 success，因此不会令 `transaction_success=false`。

**变量表：**

| 变量 | Type | Range | Description |
|------|------|-------|-------------|
| `C` | set<call> | n≥0 | 本 transaction 内全部 consumer query/resolve 调用集合 |
| `ci` | call | — | C 中第 i 个调用 |
| `status(ci)` | primitive enum | SpatialGrid `R9` status enum | ci 的返回 status |
| `allowed_success(ci)` | set<enum> | ⊆ status enum | ci 的合法 success class，由 SpatialGrid R9 status enum 定义，success class = `{OK, OK_NOOP, OK_REPLACED, STAGED_FOR_SUPPRESSION}`；`BUFFER_TOO_SMALL` 等为 failure |
| `query_end_status` | primitive enum | status enum | QUERY phase matching end 返回 |
| `query_consume_end_status` | primitive enum | status enum | QUERY_CONSUME phase matching end 返回 |
| `has_fault()` | bool | {true,false} | RNG 等 service participant phase 边界 fault 检查（GATE-G3），任一流 FAULTED 即 true |
| `transaction_success` | bool | {true,false} | 全部 ci 成功 + 两个 end OK + 无 service fault |
| `published_resolution` | bank ref | published/previous | 发布给 consumer 的 resolution bank 引用 |

**空消费者集 `C={}`：** `all()` vacuously true；若 `query_end_status==OK AND query_consume_end_status==OK AND no has_fault()`，则 `transaction_success=true`（空 query phase 合法，首 tick SPAWN_INTENT 后可能无 damage consumer）。

**工作示例：**
- 3 consumer 全 OK → `transaction_success=true`，bank 交换。
- 3 consumer，第 3 个 `STALE_HANDLE` → `transaction_success=false`，前 2 个 staging 丢弃，published bank 不变。
- 1 consumer，no-hit（`OK,count=0`）→ `transaction_success=true`，空结果合法。
- 任一 consumer 期间 RNG `has_fault()=true` → `transaction_success=false`，staging 丢弃，fault 零值不进下一 phase committed state。

### F2 — pause drain 上界

`extra_pause_drain_ticks ∈ {0,1}`，`MAX_PAUSE_DRAIN_TICKS=1`。

| 变量 | Type | Range | Description |
|------|------|-------|-------------|
| `extra_pause_drain_ticks` | int | {0,1} | 额外 drain tick 数，受 `MAX_PAUSE_DRAIN_TICKS` 硬上界 |
| `MAX_PAUSE_DRAIN_TICKS` | const int | 1 | 固定安全上限，不得线上调大以隐藏持续 pending work |
| `physics_dt` | float | >0 | 单 physics tick 时长（BATTLE_ACTIVE） |
| `gameplay_dt` | float | ≥0 | 玩家可见 gameplay elapsed 增量 |

- foreground preflight不调用`request_pause`且不计technical tick；preflight后第一个零gameplay-dt PAUSE_PENDING tick在barrier发起本路径的首次request；
- 首次 barrier `request_pause=OK`：`extra_pause_drain_ticks=0`；
- 首次为 `PENDING_WORK`、drain barrier 为 `OK`：`extra_pause_drain_ticks=1`；
- drain barrier 仍为 `PENDING_WORK` 或 drain tick 内部任一 phase failure / `has_fault()` 命中：仍先执行 matching barrier end（因此技术 tick revision按SpatialGrid规则推进），随后进入 ControlledGameplayFault；不启动第三个 technical tick。

玩家可见 gameplay elapsed 增量为：

`gameplay_dt = physics_dt` 仅当 state=`BATTLE_ACTIVE` 且非 drain；否则 `0`。

### F3 — tick 与 revision

| 变量 | Type | Range | Description |
|------|------|-------|-------------|
| `tick_revision` | int64 | ≥1，单调递增 | 当前技术 tick，init 后首 pair =1 |
| `snapshot_revision` | int64 | ≥0，单调非递减 | SpatialGrid authoritative registration 快照版本，init=0 |
| `expected_phase` | primitive enum | {SPAWN_INTENT, MOVEMENT_COMMIT, GRID_SYNC, QUERY, QUERY_CONSUME, DEFERRED_REMOVAL, POST_DEFERRED_BARRIER} | 当前期望 phase |
| `authority_revision` | int64 | = snapshot_revision（Active publish 后） | authority bundle 版本，正常 DEFERRED_REMOVAL publish 后须等于当时权威 `snapshot_revision`；Paused resume candidate 预置为 arm 预检的 next snapshot revision，matching publish 后两者必须相等 |

- SpatialGrid init 后首 pair 固定为 `(tick_revision=1,phase=SPAWN_INTENT)`、`snapshot_revision=0`；
- matching Active phase end 推进 expected phase；只有 sync=`OK` 增加 snapshot revision；
- matching POST_DEFERRED_BARRIER end checked 生成 `next_tick_revision=tick_revision+1` 并**把 phase 重置为 `SPAWN_INTENT`**（与 SpatialGrid R3 一致）；
- pause/resume 不额外增加 tick；matching resume publish增加 snapshot，resume end只关闭 lease并**保留 barrier 已生成的 next Active `(tick,SPAWN_INTENT)` pair**供下一 Active tick 使用；
- 任一 checked increment overflow遵守 SpatialGrid `ID_EXHAUSTED` cleanup并进入 fault，不回绕。

### F4 — pause reason priority

`BLOCKING_CHOICE > APP_BACKGROUND > INPUT_GEOMETRY_CHANGED > MANUAL`。该优先级只决定处理/展示顺序；resume hold以R7矩阵为准，任意APP_BACKGROUND或MANUAL都要求一个玩家确认，二者重叠不叠加按钮。

| 变量 | Type | Range | Description |
|------|------|-------|-------------|
| `pause_reason` | set<enum> | ⊆ {MANUAL, LEVEL_UP, TREASURE_CHOICE, RISK_CHOICE, APP_BACKGROUND, INPUT_GEOMETRY_CHANGED} | 本 pause 的 reason 集合；invalidation 类可合并为集合 |
| `event_sequence` | int64 | ≥1，单调递增 | blocking choice 排序键，同优先级升序 |
| `input_rebuild_revision` | int64 | ≥1，严格递增 | 每个 APP_BACKGROUND/INPUT_GEOMETRY_CHANGED 新 invalidation 分配；preflight 只处理最新 geometry snapshot，旧 revision 返回 `STALE_TICK` |

同优先级blocking choice使用`event_sequence`升序；相同sequence是invariant violation。APP_BACKGROUND与INPUT_GEOMETRY_CHANGED可合并为一次pause reason集合，但每个新invalidation仍分配严格递增`input_rebuild_revision`，preflight只处理最新geometry snapshot且旧revision返回STALE_TICK。manual duplicate合并为一个intent，不能生成多层pause UI。

> **`published_tick_revision` 字段声明**（ResolutionStagingBank 结构）：R3 ResolutionStagingBank 除 damage/pickup/target-selection/effects 分区外，包含字段 `published_tick_revision: int64`——resolution publish 同时写唯一 `published_tick_revision`（= 当前 `tick_revision`）；DEFERRED_REMOVAL 只能消费 `published_tick_revision == 当前 tick_revision` 且尚未消费的 bank 一次（"尚未消费"标记 = published_tick_revision 比较 + consumed bool，不依赖单独 bool）。failure 不生成新 published token，故不得重新消费上一 tick 的 resolution。

## Edge Cases

1. **If** pause intent 在 GRID_SYNC/QUERY 中产生：**Then** 只 latch，在本 tick authority commit后的 barrier处理，不中断当前 phase。
2. **If** pause intent 与 player death/victory 同 tick：**Then** battle-end intent优先；不展示 choice UI，未消费 choice保留给 outcome/上游系统裁决。
3. **If** 首次 pause 返回 `PENDING_WORK`：**Then** 锁输入和新效果，执行一个零 gameplay-dt drain tick；玩家不再受伤。
4. **If** drain 后仍 `PENDING_WORK`：**Then** 进入 ControlledGameplayFault，不无限 spinner、不继续模拟。
5. **If** 多个 blocking choice 同 tick：**Then** Frozen 后按 event_sequence逐个展示，期间不 resume。
6. **If** manual pause 与 blocking choice或lifecycle reason重叠：**Then** blocking choice/preflight先处理；完成后`resume_requested_latched`仍为false并保持手动暂停，玩家明确点击继续才置latch并resume。
7. **If** query/resolve/fatal narrowphase failure 发生在最后一个 consumer：**Then** 较早 consumer staging也全部丢弃，不能提交部分伤害/拾取/索敌。
8. **If** narrowphase合法未命中：**Then** 继续 transaction并允许其他合法效果发布。
9. **If** owner swap失败：**Then** 恢复旧 bundle引用、abort candidate、关闭 lease并 fault；consumer从未看到新 bank。
10. **If** wrong transaction/lease publish：**Then** Grid保持 Armed，GameRoot恢复旧 owner引用并用正确 tx/lease abort；随后 fault。
11. **If** matching Armed publish：**Then** 必须 `OK`；成功后重复 publish按 SpatialGrid state-first为 `WRONG_STATE`，仅用于测试，不是恢复流程。
12. **If** manual exit发生于 Active phase：**Then** latch到安全边界；不得直接释放有 open lease 的 Grid。
13. **If** 应用进入后台且系统未派发touch release，或active期间safe geometry变化：**Then** 不补算墙钟时间；callback推进`input_rebuild_revision`、设置`foreground_input_blocked`并同步关闭Host new-press ingress，但除唯一hit-route disable外不写其他Node属性且不写carrier/action/state。恢复/重配置后在任何普通Active tick前执行Input cancel与Host invalidation rebuild，旧epoch signal失效、carrier保持ZERO；preflight不调Grid request，随后启动第一个零gameplay-dt PAUSE_PENDING technical tick并在barrier发起首次request。若首次PENDING，仍可执行唯一额外drain；上界后仍PENDING则fault。preflight非OK进入fault，禁止先跑普通MOVEMENT_COMMIT或牺牲一次玩家手势。
14. **If** battle load任何 config/carrier/Grid init校验失败：**Then** 不开放战斗输入、不消费永久资源，cleanup后返回 PREP或 fault。
15. **If** fault UI被连续点击：**Then** 只启动一次 HOME cleanup transition。

## Dependencies

### 上游/被编排契约

| Dependency | GameRoot 使用方式 | 当前状态 |
|---|---|---|
| Godot SceneTree/process mode | scene切换、pause、main-thread physics callback | 引擎契约；项目尚未建立运行工程 |
| SpatialGrid | phase lease、sync/query、pause/resume、teardown | `design/gdd/spatial-grid.md` 已冻结 core contract；implementation 未开始 |
| Config/Data | immutable snapshot、pool keys/capacities、Spatial limits/readiness | `design/gdd/config-data-system.md` Draft；foundation contract已冻结，battle_ready依赖仍开放 |
| Stage | arena、walkable region、production CELL_SIZE/index_margin | `design/gdd/stage-map.md` Draft；静态几何/StageSpatialConfig 已冻结，生产 CELL_SIZE/index_margin 收紧值 gated |
| Object Pooling/lifecycle owners | remove-success 后回收、Paused quarantine、resume binding publish | `design/gdd/object-pooling.md` Draft；implementation/integration 未开始 |
| InputSystem / VirtualJoystickHost | movement carrier、UNARMED→seed→exact callback connect、callbacks/runtime/shield-service三字段状态矩阵、PREACTIVE_DISCARD与consumer-closed bank FSM分离、typed state publish/pause cancel、无latch service不推进trusted tick、精确rebuild status+candidate-config identity、geometry自动/per-background-revision readiness矩阵、attempt revision全边界复核，以及GameRoot独占Viewport physical gate下的统一ACTIVE提交/fresh-press/choice gate | `design/gdd/input-system.md` Approved；第二十轮已确认callback-observable consumer-close/terminal transaction闭环，implementation/project assets与integration/evidence gates仍未完成 |
| RNG System | BATTLE_LOADING 初始化为 service participant；phase 边界 `has_fault()` 检查义务；telemetry first-failure 各流 state 对齐 | `design/gdd/rng-system.md` Approved；GATE-G3（game-root has_fault 检查义务落地）OPEN until 本 GDD 更新 |
| SaveSystem | pre-run consumable reservation、RunOutcome commit、TECHNICAL_ABORT补偿 | GDD 未设计；永久资源 integration gate |

### 下游

- InputSystem、PlayerController、EnemySystem、SpawnDirector、DamageSystem、ProjectileSystem、DropSystem 等必须实现 GameRoot phase participant接口，禁止自主 gameplay physics orchestration。
- BattleUI 消费scene/pause/fault view model；不得直接切state或调用SpatialGrid；每次choice press须只读Host choice gate，不得缓存推断。
- SkillDraft/RiskChoice/Leveling 只提交 blocking choice与 authority mutation intent；GameRoot负责 safe pause和resume transaction。
- SettlementSystem 只消费 immutable `RunOutcome`；不得从已 teardown battle nodes重建结果。

### 跨文档一致性

- SpatialGrid 的 phase enum、status、carrier ownership、Paused substate与本 GDD相同；若任一侧修改，必须同时更新另一侧 AC。
- InputSystem的MOVEMENT_COMMIT相对顺序、UNARMED/`callbacks_armed`/`runtime_ingress_armed`/`shield_bank_service_enabled`四段职责与固定状态tuple、callback-observable consumer-close/terminal commit、callback ABI、PREACTIVE_DISCARD/lifecycle latch、`pause_intent_latched` context、InputStatus/rebuild status、typed state publish时点、RESUME_PREPARING hook、foreground/geometry preflight与per-background required/acked readiness、GameRoot唯一Viewport gate writer、`SET_TRUE_IN_FLIGHT` ScreenTouch containment/first-observer held-drain、成功与fault恢复顺序、choice gate及process-mode职责必须与`design/gdd/input-system.md`同步；任一侧修改须同时更新AC-A/D/E及IG-IS1。
- RNG的 service participant 注册、phase 边界 `has_fault()` 检查义务、fault 返回零值不进下一 phase committed state、first-failure telemetry schema（`run_seed`/`stream_id`/调用计数/state）与 BATTLE_LOADING init 时点必须与`design/gdd/rng-system.md`同步（GATE-G3）；任一侧修改须同时更新AC-G2与 rng-system AC-E1/AC-F3。
- 本GDD不决定伤害公式、选择内容、奖励数值或Save schema；逐key对象池容量、PoolLimits与Spatial基础limits由Config schema v1权威提供。Stage与owner query/reset/spawn字段未完成前保留integration gate，不在实现中猜值或覆盖snapshot。

## Tuning Knobs

GameRoot 没有玩法数值旋钮。以下均为安全/表现配置，不能用于掩盖契约错误：

| Setting | MVP value | Owner | Rule |
|---|---:|---|---|
| `MAX_PAUSE_DRAIN_TICKS` | 1 | GameRoot | 固定安全上限；不得线上调大以隐藏持续 pending work |
| `show_pause_pending_overlay_after_frames` | 1 | BattleUI | 超过一个 render frame才显示“正在稳固战局…”；不影响 simulation |
| `fault_diagnostic_detail` | dev=full / release=code-only | Build config | release不得展示内部对象/堆栈 |

Scene transition animation时长、音效和具体视觉样式归对应 UI/Audio GDD，不属于 GameRoot行为契约。

## Acceptance Criteria

### A. Scene Flow

**AC-A1 主循环合法转换**
- Given: 合法 config、save与空闲 GameRoot
- When: 执行 HOME→PREP→BATTLE_LOADING→BATTLE_ACTIVE→victory/death→BATTLE_ENDING→SETTLEMENT→HOME
- Then: 每个 state只进入一次，battle input仅在 Active开放，Settlement只收到一个 immutable RunOutcome
- 验证: deterministic scene-state integration | Gate: BLOCKING

**AC-A2 BATTLE_LOADING单snapshot顺序与preactive ingress**
- Given: Config schema v1 foundation数据、合法Stage/owner fixture与空闲GameRoot
- When: 执行BATTLE_LOADING并在Config/carrier/Grid/Pool/owner每层分别注入failure
- Then: success严格按Config→carriers→Input/Host(callbacks armed、runtime ingress false、IDLE)→Grid→Pool→owners→preactive latch recheck→`PRE_ACQUIRE(buffering=false/identity/owner/gate)`→`SET_TRUE_IN_FLIGHT`→true return/readback进入`GATE_HELD`→guarded Input ACTIVE=OK→GameRoot局部提交BATTLE_ACTIVE/consumer→`ACTIVATION_SUCCESS` release/clear owner；全体snapshot ID相同。分别在initialize、Grid/Pool/owner边界注入press，均只走PREACTIVE_DISCARD。setter-in-flight hostile ScreenTouch允许Viewport delivery但必须由armed-IDLE shield `accept_event()`并PREACTIVE_DISCARD，项目bank/action/claim/generation/carrier/gameplay consumer/top-state effect=0；生产callback直接注入由静态guard判FAIL。held区间经direct push、parse与正常OS路径注入时Viewport/Control/VJ delivery=0。false返回后的新OS press可接受。buffering/identity等pre-acquire failure setter=0；callback invalidation在对应observer阻断，已持gate者cleanup后reasoned release回PREP且technical fault=0。
- Then（第十九轮loading cleanup权威覆盖）: initialize成功至ACTIVE guard提交前精确为`callbacks/runtime/service=true/false/false`，setter-in-flight callback对runtime/service写次数均0且bank/FSM/first-error latch写次数0；guard clean以一次原子提交变为`true/true/false`。任一loading failure从IDLE直接cleanup，teardown terminal commit前始终为`true/false/false`且shield service写次数0，terminal commit恰一次变为`false/false/false`；不得为复用通用cancel临时出现loading service=true。
- 验证: ordered integration spy + fault matrix | Gate: BLOCKING

**AC-A2b Input UNARMED与armed-IDLE初始化隔离**
- Given: Host/shield/VJ已在树且UNARMED，initialize在每个验证、最终geometry重读、seed与Callable connect边界可注入事件
- When: 分别注入movement press/motion/terminal、resize、background notification、connect failure及arm边界press
- Then: arm前及armed-IDLE期间VJ命中/action变化=0，shield只消费且项目owned bank/gesture/pending status写次数=0；允许引擎handled/touch-focus变化。Host preactive notification只可写preactive invalidation latch，seed前不存在safe-close observer。无invalidation的成功路径只在seed与全部exact Callable连接后原子arm callbacks，runtime ingress仍false；失败精确disconnect并保持UNARMED/bank空/连接数0。seed前或armed-IDLE注入background/geometry时latch必达，initialize或ACTIVE publish返回typed WRONG_STATE、ACTIVE publish成功数0、逆序cleanup回PREP且technical fault=0；无invalidation时直到ACTIVE publish后第一下新OS press才可接受
- Then（第十七轮bootstrap activation补充）: armed-IDLE最终ACTIVE前必须先通过buffering readback与Viewport `PRE_ACQUIRE`；true setter内部callback属于`SET_TRUE_IN_FLIGHT`，生产callback只允许写typed latch且不以Viewport delivery=0为oracle。绕过静态guard的hostile合法ScreenTouch必须由shield `accept_event()`后PREACTIVE_DISCARD，项目bank/gesture/action/carrier/pending-status/top-state写次数=0。true返回/readback后进入`GATE_HELD`，Input publish OK时物理event仍disabled；GameRoot字段提交并`ACTIVATION_SUCCESS` release返回后第一下新OS press才可接受。dirty路径Input/consumer提交=0；仅已持gate者cleanup后以`LOAD_ABORT_OR_FAULT_CLEANUP`恢复PREP UI，pre-acquire failure release=0。
- Then（第十九轮armed字段权威覆盖）: UNARMED=`false/false/false`，armed-IDLE=`true/false/false`；preactive lifecycle latch、load abort、IDLE async safe-close与IDLE ending/fault cleanup均不改变该三字段，shield service写次数始终0。只有clean ACTIVE publish允许runtime false→true；teardown先一次性提交`TERMINATED + false/false/false`，再执行setter/tree cleanup。
- 验证: SceneTree input injection + connection spy | Gate: BLOCKING

**AC-A3 非法/重复 scene intent 幂等**
- Given: 任一 transition正在进行
- When: 连续点击开始、返回、暂停、继续各100次，并注入非法 state edge
- Then: 只执行一个合法 transition；非法边=`WRONG_STATE`且状态/资源引用不变，无重复 scene或重复结算
- 验证: state-matrix + UI spam test | Gate: BLOCKING

### B. Physics Orchestration

**AC-B1a 静态守卫（process mode 与 callback ABI）**
- Given: 全场景节点树
- When: `tools/ci/static_guard_check.py` AST 审计（gdtoolkit.parser Lark Tree）
- Then: 唯一GameRoot=`PROCESS_MODE_ALWAYS`且恰定义`_physics_process(delta:float)->void`/`_process(delta:float)->void`；InputSystem及其他gameplay participant为pausable；Host/shield/VJ为ALWAYS且不存在额外ALWAYS gameplay node；gameplay participant 禁定义`_physics_process`/`_process`/`_unhandled_input`/`_input`（`GATE_HELD` 期间 `gui_disable_input=true` 只跳过 gui phase，`push_input` 仍派发 `_unhandled_input`/`_input`，故须静态禁止 participant 定义这些回调）；缺参数、错误类型/返回、职责互换、双跑或错误process mode均FAIL
- 验证: static_guard_check.py AST + 场景审计 | Gate: BLOCKING

**AC-B1b 完整 phase trace与 lease 零分配**
- Given: 首 tick、普通第二 tick、一个无工作 tick与一个 drain tick
- When: GameRoot运行 physics orchestration（10,000 tick）
- Then: 未暂停时仅physics callback驱动每tick严格七组matching begin/end，顺序为SPAWN_INTENT→MOVEMENT_COMMIT→GRID_SYNC→QUERY→QUERY_CONSUME→DEFERRED_REMOVAL→POST_DEFERRED_BARRIER，process control-pump **body**调用数=0（`_process` 在 ALWAYS 节点每帧被引擎调用，但 predicate gate 使 body 不执行；审计计 body 调用数非引擎调用数）；MOVEMENT_COMMIT中InputSystem先写carrier再由PlayerController读取，无participant自主开phase，drain tick gameplay_dt=0。10,000 tick 下 `begin_phase+end_phase` 总 lease 登记分配数=0；lease 登记必须用预分配 SoA（`PackedInt64Array lease_ids` + `lease_epoch` + `open: bool` 标量位图），禁用 Dictionary 登记（违 Forbidden Patterns 精神）。Paused/Resume iteration仅由process callback运行control pump与允许GUI adapter，physics callback七phase调用数=0
- 验证: SpatialGrid spy + participant trace + lease allocation counter | Gate: BLOCKING

**AC-B2 lease 与 revision 单 owner**
- Given: participant尝试缓存旧 lease、自主 begin或重入 callback
- When: 连续运行两个 tick及 pause/resume
- Then: 旧/关闭 lease均失败；只有 GameRoot获得新 lease；init首 pair、sync snapshot、barrier next tick与resume后首 pair逐项等于 SpatialGrid AC-G3
- 验证: adversarial integration | Gate: BLOCKING

**AC-B3 phase failure single-exit cleanup**
- Given: 在每个 phase的首/中/末 participant分别注入 failure，并另注入错误 end/ID_EXHAUSTED
- When: 执行该 tick
- Then: matching lease按契约关闭或保留首根因 diagnostic；不运行后续 participant/phase；没有未关闭 lease、部分 authority publish或下一 tick begin
- 验证: table-driven fault injection | Gate: BLOCKING

### C. Query Transaction

**AC-C1 整阶段 rollback**
- Given: Damage/Pickup已写 staging，最后 consumer分别触发 query failure、STALE_HANDLE、OBJECT_INVALID与fatal narrowphase error
- When: QUERY/QUERY_CONSUME结束
- Then: 全部 resolution staging丢弃，published bank identity/revision不变，damage/pickup/targeting提交数均0，进入 ControlledFault
- 验证: deterministic integration，与 SpatialGrid AC-G4/K5 共用 fixture | Gate: BLOCKING

**AC-C2 no-hit不是failure**
- Given: 一个合法 query为空、一个 shape narrowphase不相交，另有一个合法 damage staging
- When: 完成 transaction
- Then: transaction success，no-hit不产生效果但合法 damage一次发布，不进入 fault
- 验证: integration control fixture | Gate: BLOCKING

### D. Pause and PENDING_WORK

**AC-D1 正常 safe pause**
- Given: QUERY中产生LEVEL_UP pause intent
- When: 当前tick完成resolution、deferred remove、authority commit并进入barrier
- Then: trace严格为intent_latched→Input cancel=OK且state LOCK_PENDING/carrier ZERO→Grid request_pause=OK→matching end→quarantine→Input publish FROZEN=OK→pause UI；Input cancel非OK时Grid调用数=0，FROZEN publish非OK时UI开放数=0，均fault。只有quarantine与publish均OK才显示choice UI；pause前效果恰提交一次，SceneTree paused且战斗计时停止
- 验证: GameRoot+Grid+Pool event/revision/UI trace | Gate: BLOCKING

**AC-D2 单 drain tick与玩家保护**
- Given: 首次 request_pause=`PENDING_WORK`
- When: 执行PAUSE_PENDING
- Then: 首次PENDING前Input cancel已OK且carrier ZERO；最多一个完整drain tick，input/spawn/AI/query effects与gameplay_dt均为0；若第二次request_pause=OK且quarantine与Input publish FROZEN均OK则Frozen，任一非OK或仍PENDING则fault；所有路径中玩家HP均不再下降
- 验证: fault-injected integration | Gate: BLOCKING

**AC-D3 pause reason合并与顺序**
- Given: 同tick产生MANUAL、两个blocking choice、APP_BACKGROUND与INPUT_GEOMETRY_CHANGED intent
- When: 进入Paused
- Then: blocking按event_sequence逐个处理，两个invalidation合并为reason集合且只处理最新input_rebuild_revision/geometry snapshot，但APP_BACKGROUND的readiness hold优先于geometry自动恢复。pairwise fixtures覆盖choice-only、manual-only、geometry-only、background-only、background+geometry、geometry+choice、background+choice、manual+choice、manual+geometry、manual+background+choice及duplicate/coalesced reason：只有不含MANUAL/APP_BACKGROUND的choice/geometry组合在所需preflight/FROZEN/choice完成后自动置唯一latch；任意MANUAL或APP_BACKGROUND组合在全部前置完成后仍latch=false、attempt=0，只有一个合法readiness/Continue使false→true恰一次。该press产生movement generation数=0；不存在叠层按钮/选择UI、中间resume tick、重复choice effect或累计intent
- 验证: deterministic queue test | Gate: BLOCKING

**AC-D3b 每个background revision独立readiness**
- Given: `background A→foreground/FROZEN→Continue A→resume尚未越过不可逆点→background B`，以及A/B/C在首次确认前连续到达、duplicate同revision、MANUAL/choice/geometry组合
- When: 执行invalidation rollback、最新preflight、choice与paused pump
- Then: A确认后`acked=A`；B到达立即使`required=B>A`，generic resume latch可保留但`can_start_resume=false`、attempt=0，直到B的前置完成且新Continue令acked追平B。A/B/C未确认时只保留最新required且只需一个确认；duplicate不推进revision或增加按钮；MANUAL与最新background共用一个Continue，choice effect恰一次。每次readiness press产生movement generation数=0，最新revision确认前gameplay phase/damage/timer推进数=0
- 验证: revision-paired state matrix + UI/input spy | Gate: BLOCKING

**AC-D4 APP_BACKGROUND foreground preflight**
- Given: ACTIVE drag中进入后台，OS不派发release且进程不再完成当前tick
- When: foreground恢复并尝试启动下一physics tick
- Then: callback同步设置foreground_input_blocked并令旧node不可命中新press，只允许恰一次manifest登记的hit-route disable，carrier/action/state写次数=0；七phase调用数与Grid request调用数在preflight完成前均为0。Input cancel先证明shield/gates closed、carrier当前tick精确clear、pending release为空且四action`pressed=false/raw=0`，Host ensure才可构建candidate；逐项破坏precondition时candidate build count=0且返回精确InputStatus。合法rebuild中旧node不可命中、以保存Callable精确断signal、移出树并queue_free，VJ gesture epoch与shield epoch对该revision精确+1、旧shield bank清空、registered joystick恰为1但外部可达new movement press route为0，旧epoch迟到signal不改状态；same revision只有geometry与candidate-config两个fingerprint及全部canonical fields均相等才可no-op，任一碰撞fixture必须返回STALE_TICK且不构建candidate。preflight后运行第一个零gameplay-dt PAUSE_PENDING technical tick，在barrier发起首次Grid request：OK则Frozen，PENDING则再运行恰一个额外drain并按F2收敛/fault；FROZEN后保持Paused，foreground至合法readiness/Continue前gameplay phase、damage、timer与resume attempt均为0，readiness press不建立movement generation，之后才进入held gate/single-attempt流程。任一preflight failure则phase/request调用数=0并进入ControlledFault
- 验证: lifecycle integration + stale-signal spy，重复100次 | Gate: BLOCKING

**AC-D4b Input invalidation全状态矩阵与resume边界复核**
- Given: APP_BACKGROUND与INPUT_GEOMETRY_CHANGED分别发生于BOOT/HOME/PREP、BATTLE_LOADING、BATTLE_ACTIVE、PAUSE_PENDING、BATTLE_PAUSED、RESUME_PREPARING、BATTLE_ENDING、CONTROLLED_FAULT、SETTLEMENT
- When: 执行对应callback、foreground/reconfigure preflight与下一次允许的GameRoot入口
- Then: 每态严格符合R6矩阵；preflight前新GUI press接受数与普通七phase调用数均0。BATTLE_LOADING无partial恢复；Paused仍Paused。每个resume attempt必须只捕获一次`attempt_input_rebuild_revision/attempt_background_revision/attempt_geometry_snapshot`。RESUME_PREPARING分别在RESUME_LOCKED publish前、publish后/首次matching publish前、两次matching publish之间、双publish后/lease cleanup前、lease/quarantine cleanup后、RESUME_HELD_DRAIN iteration及Viewport-gated ACTIVE提交前注入APP_BACKGROUND与geometry invalidation；另覆盖Input buffering任一readback漂移的`PRE_ACQUIRE` failure，以及在`SET_TRUE_IN_FLIGHT`的focus/leave/tooltip/focused-Control callback、`SceneTree.set_pause(false)`同步`NOTIFICATION_UNPAUSED` handler及Input activation guard切换mouse-filter时的`mouse_entered/mouse_exited` notification/signal handler内触发geometry/background latch。首次matching publish前严格执行`state-aware cancel(invalidation reason)保持合法locked tuple→验证action/carrier/pending release clean→恢复old owner→abort candidate→matching close lease`，禁止在cancel前由GameRoot另写runtime/service；另在首次resume cancel后让旧focused drag再次写dirty action，invalidation cancel必须再次release。清理成功后第一种Input publish数=0仍FROZEN，第二种恰一次`RESUME_LOCKED→FROZEN`并回Paused。cancel/clean失败时不得发布FROZEN或继续正常resume，但必须执行R7 emergency cleanup：恢复old owner、fault-abort所有未publish candidate、matching close lease、清staging/quarantine，最终candidate/lease=0后teardown；root status仍为cancel failure。首次matching publish开始后的所有失效注入都必须被`attempt_invalidation_changed`或activation guard观察：以保存的正确tx完成剩余matching publish、end与quarantine cleanup。`SET_TRUE_IN_FLIGHT`中的geometry/background invalidation必须在true setter返回后的first observer阻断；unpause invalidation由second observer阻断；Input guard invalidation使publish返回`WRONG_STATE`。只有这些已进入`GATE_HELD`的failure格保持`gui_disable_input=true`至battle input teardown，并以`LOAD_ABORT_OR_FAULT_CLEANUP`恢复；pre-acquire failure保持原false且setter/release=0。failure格均保持`foreground_input_blocked=true`、`consumer_open=false`、Input ACTIVE成功数=0，不得重试resume、进入或继续held drain、清block或恢复旧owner。合法current-epoch ScreenTouch不是本段的invalidation failure：held-only在first或unpause observer后出现时必须先重新pause（若已unpause），以`HELD_ONLY_RETURN_TO_DRAIN` release并清owner，再回RESUME_HELD_DRAIN以允许terminal；repause同步callback写入的invalidation由下一paused iteration必达观察。每格另断言捕获revision写次数=1、Viewport true/false、unpause/repause与activation observer调用次数符合fixture、最终`candidate/open lease/quarantine=0`；Ending/Fault/Settlement重建数0
  - Then（第十七轮setter-in-flight containment补充）: 在上述`SET_TRUE_IN_FLIGHT`另注入合法current-epoch ScreenTouch press、press→release、press→cancel、duplicate press与capacity/FSM异常。press必须由STOP shield `accept_event()`且bank `0→1`，true返回后的first observer只按held分支以`HELD_ONLY_RETURN_TO_DRAIN`回drain；press→terminal在setter返回前必须使bank `0→1→0`并允许其他条件clean时继续；duplicate不新增entry，capacity/FSM异常写existing first-error latch并由first observer转fault。所有格VJ/action/claim/generation/carrier/choice/gameplay consumer/top-state写次数=0，生产callback直接注入仍由静态guard拒绝。
  - Then（第十八轮service补充）: RESUME_LOCKED publish前后及所有observer格精确为`callbacks/runtime/service=true/false/true`；callback可写bank/FSM但对runtime/service字段写次数均0。rollback FROZEN与held drain保留该组合；ACTIVE guard clean才原子变为`true/true/false`，failure teardown才变为`false/false/false`。
  - Then（第十九轮consumer-close权威覆盖）: ACTIVE时完整顺序必须是`cancel前置验证→Input纯标量原子提交LOCK_PENDING + true/false/true→STOP setter及其同步handler→action/carrier clear→OK或ACTION_CLEAR_FAILED`；GameRoot不得在cancel前另写enable字段。在commit前、commit后、STOP handler、clear后分别注入press/terminal，handler只可观察合法稳定tuple；clear failure仍为LOCK_PENDING。IDLE invalidation/load cleanup保持`true/false/false`且service写次数0，既有locked state保持`true/false/true`。
- 验证: table-driven lifecycle/state integration | Gate: BLOCKING

### E. Resume Atomicity

**AC-E1 prepare→arm→swap→publish成功**
- Given: indexed frozen survivor E、paused new F、removed G，UNBOUND projectile H survivor、I removed、J paused new，以及已完成choice mutation
- When: GameRoot执行唯一resume事务
- Then: 按R7矩阵生成latch：choice-only或始终foreground的geometry-only/geometry+choice在全部所需条件完成后`resume_requested_latched`从false→true恰一次；任意MANUAL或APP_BACKGROUND残留时preflight/FROZEN/choice完成后latch仍false、attempt=0，只有一个合法readiness/Continue后才置true并让acked追平当时最新required。readiness press产生movement generation数=0，foreground至此gameplay phase/damage/timer推进数=0。choice authority mutation恰提交一次；duplicate/coalesced reason不累计intent。GameRoot在进入RESUME_PREPARING前先service pending Input fault再读取`is_choice_input_blocked()`并验证`required==acked`；旧VJ claim、shield-held touch或required/acked不等时保持Paused、resume lease/publish调用数=0。完整`can_start_resume`为true后pump才启动恰一个attempt，并原子保存input/background revision与geometry snapshot，后续每个stage只与该快照比较。Grid lease前Input publish RESUME_LOCKED=OK、resume cancel=OK；若含input invalidation则Input clean precondition验证与Host rebuild=OK。pause barrier cancel与resume cancel可共用同一tick revision；若两者之间任一movement action再次`pressed || raw!=0`，resume cancel必须再次release并验证四action均`pressed=false/raw=0`、carrier当前tick精确clear且pending release为空，不得因tick相同no-op或WRONG_STATE。另在RESUME_LOCKED后/首次publish前、两次publish之间、双publish后/ACTIVE前注入合法shield press：不可逆点前恢复old owner、fault-free abort/close、publish FROZEN并回Paused，保留已有唯一latch；terminal且revision gate满足后自动单次重试。再在Continue A后、首次publish前注入background B，必须同样rollback并保留generic latch但因`acked=A<required=B`等待新确认，不得自动重试。连续三次提前press始终`latched intent count=1、in-flight attempt≤1、choice effect count=1`，最终只一次resume成功。不可逆点后且无invalidation时，合法held使流程完成双publish/end/quarantine cleanup并以open lease/candidate=0停在RESUME_HELD_DRAIN，matching terminal后只执行一次ACTIVE尾段且Grid/Pool resume调用数不增加。最终尾段必须先原子断言`required==acked==attempt_background_revision`、`input_rebuild_revision==attempt_input_rebuild_revision`、无invalidation/pending fault且held为空，再允许ACTIVE publish；成功后latch清为false。该成功矩阵technical fault=0、movement carrier ZERO、旧terminal不产生generation。E保留borrow/handle/sequence，F保留paused borrow并获得new handle，G旧handle/borrow只在Grid+Pool双publish后失效并回池；H保持UNBOUND、I双publish后回池、J保持新borrow/UNBOUND；owner/Grid/Pool revision与binding一致；首次matching publish调用是不可逆点，两次matching publish及resume end=OK，尾段Input publish ACTIVE=OK后只准备Input runtime topology；GameRoot局部提交并完成`ACTIVATION_SUCCESS` release后才原子开放物理new-press route。下一Active begin使用SpatialGrid保存的next pair且movement carrier ZERO直到fresh press；false返回后至首tick前的新OS movement press可建立generation
- Then（第十七轮Viewport-gated激活权威补充，覆盖上行旧开放点简写）: 在三系统publish/cleanup完成且held为空后，GameRoot先执行`PRE_ACQUIRE`，验证Input accumulated实时readback与ProjectSettings agile冻结值均false、目标battle Viewport identity、`gui_disable_input=false`与owner空闲；failure不写Viewport。通过后取得owner进入`SET_TRUE_IN_FLIGHT`并调用true setter；同步focus/leave/tooltip/focused-Control callback发生时bool可仍为false，Viewport delivery不作为零值oracle。合法ScreenTouch必须由STOP shield `accept_event()`并按current-epoch FSM更新held bank，但VJ `_gui_input`/claim/action/generation、carrier、choice、gameplay consumer与top-state写次数必须为0。true返回/readback=true才进入`GATE_HELD`并执行first recheck；held时保持pause并以`HELD_ONLY_RETURN_TO_DRAIN`回drain，press与terminal均在setter返回前完成且bank已回空时可在其他条件clean后继续；clean时在Input RESUME_LOCKED、foreground block/consumer closed下unpause并执行second recheck。两次均clean才在Viewport delivery=0的held区间执行Input activation guard与ACTIVE局部提交；Input返回OK后GameRoot局部提交BATTLE_ACTIVE/consumer/block/latch/feedback，再以`release_viewport_input_gate(ACTIVATION_SUCCESS)`作为物理route 0→1点。成功trace精确为`PRE_ACQUIRE→SET_TRUE_IN_FLIGHT→GATE_HELD→post-disable recheck→unpause→post-unpause recheck→guarded Input ACTIVE OK→GameRoot local commit→SUCCESS_RELEASE→clear owner`；false返回后至首tick前的新OS movement press可建立generation。
- Then（第十八轮ACTIVE原子翻转补充）: 进入trace时三字段为`true/false/true`；setter callback、first/second recheck、held-only release/repause均不写runtime/service。guarded Input ACTIVE OK必须以单一局部提交恰一次翻转为`true/true/false`，禁止可观察的双true或双false中间态；GameRoot局部提交与Viewport false release不得再次改这两个字段。
- 验证: GameRoot+SpatialGrid+Object Pooling integration，与 SpatialGrid AC-H5/H7、Object Pooling AC-E1共用 fixture | Gate: BLOCKING

**AC-E2 resume failure不泄漏半发布状态**
- Given: Input RESUME_LOCKED publish failure、Input cancel failure、Host rebuild failure；新input invalidation分别在RESUME_LOCKED publish前、其后/首次matching publish前、两次matching publish之间、双publish后/cleanup前、cleanup后、RESUME_HELD_DRAIN iteration与Viewport-gated ACTIVE提交前到达；另由`set_disable_input(true)`触发的focus/leave/tooltip、`NOTIFICATION_UNPAUSED`及mouse enter/exit同步handler在三个observer窗口内触发；以及Viewport gate已占用/identity错误、Grid/Pool prepare validation、Grid arm exhaustion、Pool arm failure、首次publish前wrong tx/lease、首次publish后wrong Pool tx、owner swap failure、双publish后Input ACTIVE publish failure分别注入
- When: 执行resume
- Then: `consumer_open=false`且shield保持STOP；RESUME_LOCKED/Input/Host failure发生在Grid lease前且旧frozen bundle不变。新input invalidation仅在不可逆点前属于非fault abort，但必须先执行dirty-aware invalidation cancel并验证actions/carrier/pending release clean，之后才恢复旧bundle、abort每个candidate并matching close lease；RESUME_LOCKED publish前Input publish数=0仍FROZEN，其后/首次matching publish前恰一次`RESUME_LOCKED→FROZEN`。cancel或clean verification失败时正常resume rollback/FROZEN publish调用数=0，但emergency cleanup调用数必须覆盖每个未publish candidate和open lease：保存cancel root failure、恢复old owner、fault-abort candidate、matching close lease、清staging/quarantine，最终`candidate=0、open lease=0`后Input→Grid→Pool teardown；cleanup failure仅suppressed。合法held或invalidation回滚成功则回Paused并保留单一generic resume latch；held terminal或纯geometry preflight完成后仅在完整`can_start_resume`为true时自动启动一个新attempt。若回滚原因是更新的APP_BACKGROUND revision，则acked必然落后required，必须等待该revision的新Continue，不得把“保留latch”解释为自动重试；duplicate/coalesced background仍遵AC-D3b。不得重复应用choice effect或为同一revision等待第二按钮。不可逆点后的invalidation、wrong Pool tx或cleanup异常都不得调用Input rollback或恢复旧bundle；在两次publish之间、双publish后/cleanup前、cleanup后、每个held-drain iteration及Viewport-gated ACTIVE提交内分别注入时，均必须由attempt快照或activation guard观察，用正确tx完成尚未完成的matching publish/lease/quarantine cleanup使三方收敛。`PRE_ACQUIRE`的buffering/identity/owner/gate失败不得写Viewport，owner/true/false/clear均为0；`SET_TRUE_IN_FLIGHT`、unpause或filter callback注入须在各自observer处阻断Input ACTIVE，重新pause或保持pause，进入`GATE_HELD`后让`gui_disable_input=true`、`foreground_input_blocked=true`、`consumer_open=false`持续到battle input teardown。teardown后仅以`LOAD_ABORT_OR_FAULT_CLEANUP`为fault/Home UI恢复Viewport与清owner；`SET_TRUE_IN_FLIGHT`断言VJ/gameplay effect=0但不要求Viewport delivery=0，`GATE_HELD`才断言false调用前Viewport/VJ delivery/claim/action/generation=0，Input ACTIVE成功数=0、最终candidate/open lease/quarantine=0。held-only分支须以`HELD_ONLY_RETURN_TO_DRAIN`恢复Viewport input和owner后回drain，不得被误升technical fault。Grid已保留ID按规则burn、paused新borrow不复用；进入ControlledFault且不重试resume并清resume latch
  - Then（第十七轮setter-in-flight补充）: hostile合法ScreenTouch不是上述callback invalidation failure。STOP shield必须contain press并写held bank；first observer看到held时直接`HELD_ONLY_RETURN_TO_DRAIN`，Input ACTIVE成功数=0且technical fault=0。只有capacity/FSM异常或并存invalidation/pending fault才按typed root status进入fault。press与matching terminal均在setter返回前完成时bank回空，可在其他observer clean后进入正常成功对照。
  - Then（第十八轮failure字段补充）: 所有resume failure/held-only/rollback格在Input teardown前保持`callbacks/runtime/service=true/false/true`；bank可按FSM变化，但callback对runtime/service写次数0。Input ACTIVE guard失败不得留下`runtime=true`或`service=false`；teardown单一提交后精确为`false/false/false`。
- 验证: 三系统table-driven integration，与 Object Pooling AC-E2/E3共用fixture | Gate: BLOCKING

### F. Fault, Teardown and Persistence

**AC-F1a 技术故障 persistence 与 telemetry（不伪造结局 + 部分奖励）**
- Given: 任一runtime fatal status（含 RNG stream fault 经 phase 边界 `has_fault()` 捕获）
- When: 进入CONTROLLED_FAULT
- Then: RunOutcome=`TECHNICAL_ABORT`，胜负/死亡原因/纪录/教程完成度均不写（不伪造结局）；但按已 committed 的存活时间/击杀数授予与 gameplay failure 等价的部分奖励（灵石/功法残页/种子），经 SaveSystem reservation/commit 提交，奖励源不含 faulted tick 未结算 staging（对齐概念 12.1）；开局灵药消耗由同一 reservation/commit 补偿；first-failure telemetry保留且无敏感对象信息
- 验证: save spy + telemetry schema test | Gate: BLOCKING（部分奖励/灵药补偿 BLOCKING on SaveSystem persistence integration）

**AC-F1b 技术故障 UI 文案与唯一操作**
- Given: 玩家处于 CONTROLLED_FAULT 层
- When: 显示 fault UI 并连续点击（含 fault UI spam，覆盖 Edge Case 15）
- Then: 只显示低干扰文案“战局状态异常，本局已安全停止。已按异常前进度结算部分奖励，请返回洞府后重试。”；唯一操作为“返回洞府”，连续点击只启动一次 HOME cleanup transition；dev 可追加 status/api/phase/tick，release 不显示堆栈/对象 ID；fault 不进入正常 Settlement 页
- 验证: UI strategy + 截图 + lead sign-off | Gate: ADVISORY

**AC-F2 teardown无open lease/旧handle复活**
- Given: 从Active、Paused、Prepared/Armed cleanup后、Fault与normal ending分别退出；另注入Host callback first-error latch与teardown前迟到callback
- When: GameRoot销毁battle scene并再次开始
- Then: 分别让ACTIVE普通Input API、IDLE/LOCK_PENDING/FROZEN/RESUME_LOCKED下Paused/Resume pump的`service_pending_input_fault`与各state `teardown`成为async latch首观察者。service路径即使玩家无后续点击也须最迟下一main-loop iteration恰一次capture+ack并返回原status；ACTIVE safe-close先原子进入LOCK_PENDING=`true/false/true`，IDLE保持`true/false/false`，既有locked state保持`true/false/true`。普通API路径下一teardown不再返回旧latch且最终TERMINATED；teardown首观察者路径必须单次capture+ack和state-aware safe-close，随后在任何filter/tree操作前先原子提交TERMINATED=`false/false/false`并撤销bank/choice/latch写权，再断连/移出/释放，同时返回captured root status，GameRoot不得因非OK返回发起第二次teardown。分别在STOP setter与terminal commit后的同步handler注入touch/lifecycle callback：前者只观察合法locked tuple，后者bank/pending latch/action/carrier写次数0且只允许suppressed diagnostic。Prepared/Armed路径先按R7/R9 emergency cleanup断言candidate/open lease/quarantine全0，再严格执行Input teardown→Grid teardown→Pool teardown→Grid reset；旧handle/borrow全部stale，新battle新epoch/PoolSet；每个pooled Node、scene与bundle各释放一次
- 验证: GameRoot+Grid+Pool lifecycle integration + leak check | Gate: BLOCKING

**AC-F3 开局消费的故障补偿 gate**
- Given: 玩家在PREP选择灵药，随后load/runtime technical abort
- When: SaveSystem integration尚未提供reservation/commit或补偿
- Then: story保持BLOCKED，不得以“战斗失败”消费灵药；提供机制后测试technical abort的部分奖励结算（按存活/击杀）、normal settlement提交、灵药 reservation/commit 补偿各一次
- 验证: SaveSystem integration contract test | Gate: BLOCKING on persistence integration

### G. Allocation and Observability

**AC-G1a steady-state Active tick 零增长**
- Given: 所有bundle/carrier/participant表在BATTLE_LOADING预分配，participant注册表为预分配 `Array[ParticipantRef]` + 稳定 int index（禁 Dictionary 注册表、禁 `get_children()`/`for p in participants` 迭代，对齐 Forbidden Patterns）
- When: release运行10,000 Active ticks（N 由 fixture 给定，非 magic）
- Then: bank/carrier identity/capacity不变；GameRoot orchestration create/resize counter=0；`variant_box_events`、`signal_emit_events`（稳态禁 `emit_signal(带参)`）、`dictionary_lookup_events` 三个 counter 均=0；不存在通过复制Array/Dictionary实现的伪原子发布；GameRoot 调用 participant 用直接 `Callable.call()`/`participant.run_phase(...)`，禁 `call(method_string,…)` 或带参 `emit_signal`
- 验证: allocation instrumentation + 三 counter positive control（对应违例路径必须观测到 >0 并失败）| Gate: BLOCKING before implementation Done

**AC-G1b 全量 copy 契约与 dirty-patch positive control**
- Given: inactive authority bank 强制全量 copy（R3）
- When: 运行 10,000 Active ticks
- Then: 每个 tick 的 inactive authority bank 写入元素数 = 当前 active count（全量），≤ `MAX_INDEXED_ENTRIES`；positive control 为一个 dirty-patch/增量实现必须观测到写入数 < count 并 FAIL（dirty-patch 被禁，全量 copy 是契约非优化）；inactive 与 published bank 为不同对象引用，published bank 所有字段（含 deferred-removal queue）在 phase 内 byte-identical 于 phase 开始时（隔离 hazard 守卫）
- 验证: write-count instrumentation + dirty-patch positive control + published-immutability spy | Gate: BLOCKING before implementation Done

**AC-G1c pause/resume workspace 零增长**
- Given: 所有bundle/carrier/participant表在BATTLE_LOADING预分配
- When: 100次pause/resume（N 由 fixture 给定）
- Then: bank/carrier identity/capacity不变；resume prepare→arm→swap→publish 不扩容或创建 Array/Dictionary/RefCounted result；O(1) owner bundle 引用交换不逐条复制后宣称原子
- 验证: allocation instrumentation + positive control | Gate: BLOCKING before implementation Done

**AC-G1d fault path cleanup 零增长**
- Given: fault injection 进入 CONTROLLED_FAULT cleanup
- When: 执行 emergency cleanup（恢复 old owner / fault-abort candidate / close lease / teardown）
- Then: cleanup 路径不扩容或创建 Array/Dictionary/RefCounted result（R3 fault cleanup 契约）；suppressed cleanup status 不覆盖 first-failure 根因
- 验证: allocation instrumentation on fault path | Gate: BLOCKING

**AC-G2 可复现诊断**
- Given: 相同artifact/config/run seed/failure injection（含 RNG stream fault 注入）
- When: 重放三次
- Then: first failure的state/tick/snapshot/phase/participant/status/API完全一致，suppressed cleanup status顺序一致；RNG fault 路径下 first-failure telemetry 含 `run_seed`、各流 `stream_id`/调用计数/state（与 rng-system R7 telemetry schema 对齐，闭合 GATE-G3）；RNG fault 在发生 tick 的 phase 边界被 `has_fault()` 捕获而非静默吞并（fault 零值 index 0 不进入下一 phase committed state）
- 验证: deterministic replay artifact | Gate: BLOCKING
