# Object Pooling（对象池）

> **Status**: Re-review Pending — 2026-08-31 GameRoot 第十轮传播：单`FINALIZE_POOL_RELEASE` closure exact-once；须第十一轮复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-09-03
> **Implements Pillar**: 300敌人、400投射物、300掉落物同屏时稳定且无复用幽灵
> **Scope**: MVP gameplay Node pooling；presentation降级策略须由各自GDD显式批准

## Overview

Object Pooling 为敌人、投射物、掉落物及后续伤害数字/VFX提供预实例化、定容、可验证复用。它以 primitive `borrow_id`、slot generation 与稳定 Node instance ID 区分每次借用，阻止旧引用在同一 Node 被再次借出后“复活”。对象池不决定生成时机、死亡规则或 SpatialGrid 查询行为；它只保证对象在 `borrow→初始化→可选Grid绑定→解除绑定→reset→release` 的唯一生命周期中不会被重复释放、带脏状态复用或在 Paused transaction 中过早借出。

## Player Fantasy

玩家不会看到对象池，只会感到怪潮、飞剑和灵气掉落连续出现而不突然卡顿；被击杀的妖兽不会幽灵般再次受击，旧投射物不会携带上次的穿透次数，暂停选择后也不会出现重复奖励或对象身份错乱。技术故障时系统宁可安全停止本局，也不能通过动态实例化、静默丢失 gameplay 对象或复用仍在快照中的 Node 来掩盖容量和生命周期错误。

## Detailed Rules

### R1 — PoolSet、PoolKey 与预分配

- 每场 battle 使用一个 `BattlePoolSet`；按 immutable、非零 signed 32-bit int `pool_key` 建立 typed pool。pool_key由Config registry稳定分配，不在runtime用String/StringName/scene path替代。不同 PackedScene/脚本契约不得共享同一 key，禁止用一个“万能 Node 池”在 borrow 时动态换脚本或场景。
- `config-data-system.md`的同一`BattleConfigSnapshot`在BATTLE_LOADING提供非零`config_snapshot_id`、每个 key 的capacity、criticality、factory/reset contract与`PoolLimits`；PoolSet不得使用本地默认值。`init(config_snapshot)`必须把snapshot ID与flattened配置值一起复制进PoolSet，并在整个READY/Paused生命周期只读保存；只读`get_config_snapshot_id()`不创建对象、不改变状态，供GameRoot在开放consumer及resume前做一致性预检。PoolSet 在开放 battle input 前一次性实例化全部 slot、建立定容 free stack/slot table/transaction workspace并执行 warmup validation。
- PoolSet 主状态固定为 `INACTIVE`、`READY`、`DRAINING`、`TORN_DOWN`。`init(config)` 只允许 `INACTIVE→READY`；runtime API只允许READY；`teardown`完成 `READY→DRAINING→TORN_DOWN`。同一PoolSet不从TORN_DOWN复活，下一场battle创建新PoolSet。
- `init`先验证snapshot ID非零、snapshot readiness/config、checked capacity与workspace尺寸，再实例化Node。零snapshot ID=`INVALID_ARGUMENT`；其他config/domain失败=`INIT_LIMIT_EXCEEDED`。factory/instance/reset warmup任一步失败时，Pool停止并free本次已创建Node、清空private table、将保存的config snapshot ID复位为0且保持INACTIVE；不得留下可借用的部分PoolSet。factory/instance失败=`OBJECT_INVALID`，warmup reset失败=`RESET_FAILED`。
- Active、PAUSE_PENDING、BATTLE_PAUSED resume transaction 与正常 spawn/despawn期间不得新增 slot、扩容 PackedArray/Array/Dictionary或临时 instantiate。只有下一场 battle 的 BATTLE_LOADING 可以用新 config重建PoolSet。
- 当前压力锚点是 ENEMY active 303、PROJECTILE active 400、DROP active 300，但它们只是 `max_concurrent_borrowed` 下界，不等于最终 pool capacity；暂停替换重叠、同tick spawn-before-release与安全 spare 见F1。
- Config schema v1已冻结六key：`enemy_normal=320`、`enemy_elite=6`、`enemy_boss=1`、`projectile_gameplay=448`、`drop_gameplay=320`、`damage_number=96`，总计1191；PoolLimits为`16 keys/512 per key/1536 total`。本GDD只执行这些值，不拥有或覆盖它们。RiskChoice裁决保持ENEMY总cap303并把class active上限改为298 Normal+4 Elite+1 Boss；`enemy_elite` 的4 active真实覆盖两只fixed与两只持久risk Elite，不再借用safety spare冒充active容量。F1 四项输入项的冻结值（source = `config-data-system.md` R4/R15）echo 如下，供本 GDD 自校验 checked sum：

  | pool_key | max_concurrent | pause_overlap | spawn_before_release | safety_spare | Σ=configured |
  |---|---|---|---|---|---|
  | enemy_normal | 298 | 0 | 12 | 10 | 320 |
  | enemy_elite | 4 | 0 | 1 | 1 | 6 |
  | enemy_boss | 1 | 0 | 0 | 0 | 1 |
  | projectile_gameplay | 400 | 0 | 32 | 16 | 448 |
  | drop_gameplay | 300 | 0 | 16 | 4 | 320 |
  | damage_number | 64 | 0 | 16 | 16 | 96 |
- `criticality=GAMEPLAY` 的 pool exhaustion 是 contract failure；不得动态 instantiate、偷用其他 pool或静默少生成。`criticality=PRESENTATION` 的 pool 溢出**不是技术故障**，不得终止 gameplay：返回 `OVERFLOW_DROPPED`（success 类）并记 telemetry，跳过本次借出的新对象，gameplay 不中断。具体降级细节（合并窗口、cap 行为、drop 优先级）由 owner GDD 细化，Object Pooling 不越权定义；在 damage-number/VFX GDD 完成前以此 safe default 兜底。boss 独占插槽不变量：`enemy_boss` 同屏唯一，`capacity=1` 即 active 上界，无 pause/spawn overlap 语义，零余量合理。

### R2 — Public identity、carrier 与 status

- 每个成功init的PoolSet获得非零 signed 64-bit `pool_epoch`，每次成功borrow获得非零 signed 64-bit `borrow_id`；两者均由进程级checked allocator单调生成且永不复用，已保留后失败的ID永久burn。每个slot保存 `{pool_epoch,pool_key,slot_id,generation,borrow_id,object_instance_id,node_ref,slot_state,spatial_handle_id,quarantine_revision}`。
- slot generation 使用 checked increment，永不回绕；即将耗尽的 slot 永久 `RETIRED`。pool epoch耗尽使init失败，borrow ID耗尽使整个PoolSet拒绝新borrow；两者均返回 `ID_EXHAUSTED`且不得复用旧ID。slot generation 与 borrow_id 的 checked 推进在 `borrow_into` 内逻辑原子：若 borrow_id 分配失败，slot 不从 free stack 取出、generation 不推进；若 borrow_id 已分配但后续 reset_for_borrow 失败，borrow_id 永久 burn、slot 退休（generation 不回滚）。
- Godot ObjectDB 会回收已删除对象的 `instance_id` 并分配给新创建的对象；仅凭 `instance_id_valid` 不足以防御 ABA（同帧 N1 被 `queue_free`→ID I1 回收→创建 N2 复用 I1→owner 用 N1 的 borrow_id release→对活对象 N2 执行 reset_for_pool）。因此 slot 保存直接 `node_ref`（Node 引用，弱语义——Node 非 RefCounted，不阻止 `queue_free`，与 `spatial-grid.md` R6 对称）。Pool 内部权威定位一律用 `node_ref`；公开 carrier 中的 `object_instance_id` 仅作诊断与对端比对字段。所有会读取/修改具体slot的 public API 入口（borrow/release/bind/unbind/replace/prepare_resume_bindings，以及R7的`arm_resume_bindings`最终检查）必须三校验：`is_instance_valid(slot.node_ref) AND slot.node_ref.get_instance_id()==slot.object_instance_id AND not slot.node_ref.is_queued_for_deletion()`，且必须以 `is_instance_valid` 在前的短路 `and` 顺序求值——若第一项 false，禁止对 `node_ref` 调用任何方法（对已释放对象调用 `get_instance_id` 会产生 freed-instance error 并可能返回脏 ID）。matching `publish_resume_bindings` 是明确例外：只校验primitive tx/substate并交换已arm metadata，禁止读取slot Node或调用Node API。对象被外部 `queue_free`/`free()`、queued-for-deletion或instance ID 不匹配时必须最迟在arm前返回 `OBJECT_INVALID`，退休slot并对GAMEPLAY pool触发ControlledGameplayFault。无 per-tick sweep，故同帧回收窗口必须靠 Node identity 而非 instance_id 关闭。
- public API返回 primitive `PoolStatus`：`OK`、`OK_NOOP`、`OVERFLOW_DROPPED`、`INVALID_ARGUMENT`、`INIT_LIMIT_EXCEEDED`、`WRONG_STATE`、`THREAD_ERROR`、`POOL_EXHAUSTED`、`STALE_BORROW`、`OBJECT_INVALID`、`STILL_REGISTERED`、`QUARANTINED`、`RESET_FAILED`、`ID_EXHAUSTED`。前三项是success（`OVERFLOW_DROPPED` 仅 PRESENTATION pool 溢出时返回），其余是failure。
- `borrow_into(pool_key,spawn_context,out_borrow: PoolBorrowBuffer) -> int` 使用caller-owned、跨帧复用carrier；字段为 `pool_epoch/borrow_id/object_instance_id/pool_key/slot_id/generation`（标量）外加 `node_ref`（Node 引用，弱语义——与 slot.node_ref 同一引用、零额外分配，owner 据此安全取得 pooled Node 而无需 `instance_from_id`，避免 R2 禁止的 ABA 入口）。Pool不创建Result/Dictionary/Array。
- `spawn_context`同样必须是BATTLE_LOADING预分配、按pool_key版本化的caller-owned carrier；runtime只覆写固定primitive/Object-ID字段。禁止传临时Dictionary/Array/Callable，reset hook不得保留该carrier引用；具体字段由Enemy/Projectile/Drop owner GDD冻结。
- status precedence固定为 `main-thread→PoolSet state/resume-binding substate→carrier→pool_key/args/transaction ID→slot/borrow identity→quarantine→Grid binding`。非主线程=`THREAD_ERROR`；state/thread early failure不读写carrier；malformed carrier保持原样；carrier验证成功后先清零全部标量，再处理key/capacity/reset，因此后续failure保持零值且不权威。有效borrow同时quarantined且BOUND时，release固定返回`QUARANTINED`，不被`STILL_REGISTERED`覆盖。

### R3 — Slot 状态与 Poolable reset contract

slot主状态固定为：

| Slot state | 含义 | 可执行操作 |
|---|---|---|
| `AVAILABLE` | 已reset、禁用且在free stack | borrow |
| `BORROWED_UNBOUND` | 本次borrow有效，尚无SpatialGrid handle或本类型不入Grid | bind、release（若非quarantine） |
| `BORROWED_BOUND` | 绑定一个有效pending/active/suspended SpatialGrid handle | replace/unbind；禁止release |
| `RELEASE_PENDING` | Grid/owner已批准本次生命周期结束，正在等待/执行reset回池 | return reset；禁止再次bind/borrow |
| `RETIRED` | generation耗尽、Node invalid或reset不可再信任 | 仅teardown |

`quarantine_revision!=0` 是正交标志，不创造第二套主状态；任何带quarantine的borrow均禁止release或重新borrow。

每个 pooled Node 必须实现版本化 `Poolable` contract：

- `reset_for_borrow(borrow_id,spawn_context) -> PoolStatus`：清空上次状态后设置本次spawn输入；不得启动自主gameplay physics或调用SpatialGrid；
- `reset_for_pool() -> PoolStatus`：停止Timer/Tween/Animation/Particles、清空目标/伤害/穿透/Buff/临时信号、关闭碰撞monitoring、隐藏并禁用process；不得保留其他borrow的强引用；
- reset hook 必须 main-thread、确定性且**不分配**（可验证契约，非断言）。在 Godot 4.7 下须钉以下约束：(a) reset hook 只在 `DEFERRED_REMOVAL`/`SPAWN_INTENT`（physics query flush 之外）运行；(b) reset hook 内**禁止 `set_deferred` 与 `call_deferred`**（两者均向 SceneTree MessageQueue 排 entry 即分配）；(c) `create_tween()` 分配 Tween Object，且 Godot 4.7 下 Tween 被 kill 后不可 restart——故 owner 须用预加载 AnimationPlayer（warmup 预建 track cache）；若必须用 Tween，reset 时 `stop()` 而非 kill-restart，且不得在 release 路径 kill 它（kill 即破坏复用，下次 borrow 须重新 `create_tween` 分配）；(d) warmup 须 play-and-stop 每个动画以预建 AnimationPlayer track cache，避免首次 borrow 的首次 play 分配；(e) 清空目标/伤害/穿透/Buff 等 gameplay 字段用 `PackedXxxArray.clear()`（元素为非装箱 primitive），**禁止 `Array.clear()`**（Variant 数组每元素 boxing 是稳态分配，与 clear 是否收缩 backing 无关）；(f) 信号连接须在 warmup 一次性建立并跨 borrow 持久存在，reset_for_borrow/reset_for_pool 不得 `connect`/`disconnect`（每次分配 Signal slot），改以 borrow_id 校验的早退守卫在回调入口屏蔽 pooled/旧 borrow 触发；(g) reset hook 内名字查找/调用/发信号必须用 `^"..."` StringName 字面量或 warmup 期缓存的 StringName 常量，禁止把 String 字面量传给接受 StringName 的 API（运行时隐式构造 StringName 分配）；(h) reset hook 不得构建/填充 `Dictionary`（hash bucket 分配 + Variant boxing），gameplay 状态须用预分配 Packed 数组或固定标量字段。hook failure返回 `RESET_FAILED`、slot进入RETIRED；GAMEPLAY pool进入ControlledGameplayFault。

Pool-owned Node在READY期间禁止外部`queue_free`与`free()`（`free()` 立即释放并归还 instance_id，是同帧 ABA 真正来源；`queue_free` 推迟帧末，但两者均在 R2 node_ref 三校验下被 `is_instance_valid=false` 闭合）及热reparent。`queue_free`/`free()` 只允许PoolSet teardown统一执行。

### R4 — Borrow 与普通 release

唯一普通生命周期为：

1. owner调用`borrow_into`；Pool从free stack取slot，checked推进generation/borrow_id，先标记BORROWED_UNBOUND，再调用`reset_for_borrow`；
2. reset success后out carrier权威，owner可把Node（取自`carrier.node_ref`）写入spawn intent；reset failure时slot退休且out不权威；
3. 若对象需要SpatialGrid，owner在`insert_into` success后调用R5 bind；若fresh insert failure，对象仍UNBOUND，owner可立即release；
4. 对象死亡/拾取/退出时，若BOUND先取得SpatialGrid remove success并R5 unbind；
5. 只有UNBOUND且非quarantine时`release(borrow_id)`才原子进入RELEASE_PENDING并调用`reset_for_pool`；reset success清除borrow identity并回AVAILABLE，reset failure清除borrow identity、退休slot并返回RESET_FAILED。两种结果都使旧 borrow identity 永久 stale，属于不可回滚的已提交 lifecycle fact。

- release进入RELEASE_PENDING后旧borrow ID即不再允许任何外部mutation；release success或reset failure返回后旧borrow ID均stale。同Node只有reset success回AVAILABLE后才可再次borrow，并得到新generation与新borrow ID。
- double release、旧borrow、错误slot/generation统一`STALE_BORROW`且no-op。
- `release`看到有效spatial handle返回`STILL_REGISTERED`；看到quarantine返回`QUARANTINED`。两者均不调用reset、不改free stack。
- owner不得仅凭Node引用release；所有mutation都必须携带borrow ID，Pool内部再验证instance ID。外部长期缓存必须保存业务handle/borrow ID，不能把Node强引用视为生命周期证明。
- Pool不签发第二套phase capability；它只校验main thread、PoolSet/transaction/slot状态。GameRoot/owner必须把普通borrow/bind限制在SPAWN_INTENT，把正常unbind/release限制在DEFERRED_REMOVAL；仅fresh insert failure可在同一SPAWN_INTENT立即release，Paused candidate borrow与post-resume cleanup按R6–R7执行。跨phase顺序由三系统integration trace gate，不得误称Pool可独立识别调用者phase。
- `DEFERRED_REMOVAL` 使用 GameRoot 预分配的 `LifecycleCommitJournal`，每个稳定intent恰占一条mutable row，其公开`commit_state`只允许`RESERVED→GRID_REMOVED→POOL_UNBOUND→POOL_RELEASED|POOL_RETIRED`单调推进，每个状态最多进入一次。journal容量不足必须在处理首条intent前失败；处理中第N条失败时，已推进rows保持权威，之后不执行。cleanup/重试读取row当前state跳过已完成步骤，不得新增“每步骤一row”、重复reset、重复push free stack或恢复旧binding。Pool在公开`POOL_UNBOUND`之后以私有slot FSM `RELEASE_PENDING→RESET_COMPLETED→AVAILABLE_COMMITTED|RETIRED_COMMITTED`保证reset/free-stack exact-once；这些私有checkpoint不暴露为journal rows。
- PausePending使用GameRoot canonical `FINALIZE_POOL_RELEASE` closure：一个closure绑定一个既有LifecycleCommitJournal row，可从`GRID_REMOVED`或`POOL_UNBOUND`继续，并在同次closure内exact-once完成剩余unbind与release/reset，最终到`POOL_RELEASED|POOL_RETIRED`。Pool内部checkpoint不生成第二个closure、不增加owner `PAUSE_CLOSURE`贡献；因此N条pending lifecycle row最多需要N条Pool closure，而不是2N。

### R5 — SpatialGrid binding matrix

Object Pooling不调用SpatialGrid，但记录binding以阻止错误release。owner按以下唯一矩阵同步两个系统：

| SpatialGrid result | Pool action | Node ownership |
|---|---|---|
| fresh `insert_into=OK` | `bind_spatial_handle(borrow_id,new_handle)`：UNBOUND→BOUND | owner保留，可在sync后active/suspended |
| fresh insert failure | 不bind；允许`release` | caller仍拥有，从未注册成功 |
| duplicate `OK_NOOP` | 保持原bound handle；可选matching bind返回OK_NOOP | 不变 |
| pending `OK_REPLACED` | `replace_spatial_handle(borrow_id,old_handle,new_handle)`一次原子改binding | old stale、new bound；禁止中间release |
| active/suspended变化式duplicate `INVALID_ARGUMENT` | 不改binding | 旧注册权威，不得release |
| `stage_position=OK/STAGED_FOR_SUSPENSION` | 不改binding | 同borrow/handle继续有效 |
| `sync=SYNC_FAILED/ID_EXHAUSTED` | 不改binding | workspace/旧snapshot仍权威，不得release |
| `remove=OK` | 同一intent journal row推进到`GRID_REMOVED`，再`unbind_spatial_handle(borrow_id,old_handle)`并推进到`POOL_UNBOUND`，随后release/reset并把同一row推进到`POOL_RELEASED`或`POOL_RETIRED` | owner可回收；后续失败不得复活旧handle/borrow |
| remove failure | 不unbind | release固定`STILL_REGISTERED` |

- bind要求当前spatial_handle_id=0、新handle非零；错误组合`INVALID_ARGUMENT/STALE_BORROW`且不改状态。
- replace要求当前handle精确等于old、新handle非零且不同；先完整验证再单次提交。
- unbind要求当前handle精确匹配；错误handle不能清除binding。
- PROJECTILE按当前SpatialGrid GDD默认不入Grid，因此保持UNBOUND；它仍必须等待Damage/Projectile owner确认本tick不再被消费后才release。

### R6 — Paused quarantine

- GameRoot在SpatialGrid成功进入PausedFrozen后，以caller-owned `PackedInt64Array published_borrow_ids`调用`begin_quarantine(snapshot_revision,ids,count)`。输入必须精确覆盖published authority bundle引用的全部GAMEPLAY borrow，包括Grid BOUND实体与默认不入Grid的投射物；Pool验证集合数量、唯一性、borrow/Node identity及其与当前全部live GAMEPLAY borrows一致后一次提交，partial quarantine或漏项均禁止。
- published authority中的borrow在resume publish或Grid teardown前始终quarantine。Paused mutation返回failure时，owner不得unbind/release/reborrow这些Node。
- pause期间新spawn可以从剩余AVAILABLE slot borrow，保持UNBOUND并只写inactive authority candidate；它在Grid resume candidate Prepared后加入该transaction quarantine，发布/abort前不得release。
- pool_key在一次borrow期间immutable。若Paused choice要求换成不同PackedScene/class，必须保留旧quarantined borrow并另borrow新slot；禁止对同Node热换脚本/scene。相同pool_key且owner契约允许的Spatial type replace可走old→new remap。
- manual pause无authority变化也必须保持frozen quarantine，直到identity resume publish完成。

### R7 — Resume binding transaction

Pool使用SpatialGrid `transaction_id`，不生成第二套公开tx ID。GameRoot在consumer closed window执行：

1. Grid `resume_from`成功并给出完整remap后，调用`prepare_resume_bindings(tx,remap,authority_borrow_ids)`；Pool在预分配workspace构建candidate slot metadata，不改published slot table；
2. Pool逐项验证indexed old handle属于正确frozen borrow、new handle唯一、0→new来自paused UNBOUND borrow、old→0可进入RELEASE_PENDING、old→same/new保持同borrow且pool_key兼容；同时以旧published borrow集合与新`authority_borrow_ids`做差，处理无Grid handle的UNBOUND survivor/removed/new，禁止投射物等unindexed对象逃逸quarantine；
3. Grid arm success后调用`arm_resume_bindings(tx)`完成**最后一次可失败检查**：逐项复检 `is_instance_valid(slot.node_ref) AND slot.node_ref.get_instance_id()==slot.object_instance_id AND not slot.node_ref.is_queued_for_deletion()`、capacity、candidate identity与tx；任一失败保持publish前状态，GameRoot abort Grid与Pool candidate并保留Frozen旧状态；
4. GameRoot 通过 `AuthorityResumeCommitPlan` 再次核对 battle/config/input/background/geometry/authority identity，完成 owner candidate 引用准备后调用 matching Grid publish；
5. 随后 `publish_resume_bindings(tx)` 作为第二次发布，只校验 primitive matching tx/state 并交换已 arm 的 metadata 引用，契约上不可失败。matching tx 下禁止再次调用 Node API、重新验证 identity/capacity 或发现新的可恢复 failure；
6. GameRoot 完成第三次 authority publish 后才关闭 Grid resume lease、清除 survivor/new quarantine并进入 typed `POOL_BINDING_CONSUMER_OPEN` checkpoint；该checkpoint只表示Pool binding/quarantine已收敛，不等于gameplay/Viewport physical input consumer开放。old→0进入RELEASE_PENDING并在所有下游consumer仍关闭时执行 reset/release；只有GameRoot随后完成Input/GameRoot ACTIVE与`ACTIVATION_SUCCESS` gate release，physical consumer才可开放。任一publish checkpoint后发生orchestration fault，必须完成尚可确定的commit收敛并保持consumer closed，不能回到旧Grid/Pool/owner混合状态。

- Pool私有resume-binding substate固定为`NONE`、`PREPARED(tx)`、`ARMED(tx)`；同一PoolSet最多一个candidate。prepare只允许NONE，matching arm只允许PREPARED，matching publish只允许ARMED，matching abort允许PREPARED/ARMED。substate不合法=`WRONG_STATE`；输入tx=0或非matching tx=`INVALID_ARGUMENT`且保持原substate。
- Grid prepare/arm/owner swap failure时`abort_resume_bindings(tx)`丢弃Pool candidate：frozen old borrow保持quarantine，paused candidate-only borrow解除transaction quarantine后可由owner保留或release。
- Grid matching publish后禁止Pool回滚旧binding；matching tx 的Pool publish必须OK。任何“matching publish内部failure”是实现违反arm不变量的不可达断言，不得保留Pool ARMED或形成运行时恢复分支。Pool publish 后仍须等待第三次 authority publish，期间 consumer 继续关闭。
- 若故障注入先用wrong tx调用Pool publish，它必须返回INVALID_ARGUMENT并保持ARMED；由于Grid可能已matching publish，GameRoot必须立即用保存的正确tx完成一次Pool matching publish使三方收敛，再关闭lease并进入fault，禁止恢复旧Grid/owner状态。
- omitted old Node只有在Grid+Pool publish后才解除binding并reset；new Node只有publish后才获得new handle。查询快照中不存在同一Node同时对应old/new borrow的窗口。
- 三次 publish 后的 RELEASE_PENDING reset 若返回 RESET_FAILED，不回滚已发布 Grid/Pool/authority 状态；slot 已退休、旧 borrow stale，GameRoot 将既有intent row单调推进到`POOL_RETIRED`、保持 consumer 关闭并直接走 ControlledGameplayFault teardown。

### R8 — Fault、drain 与 teardown

- ControlledGameplayFault不允许普通release风暴穿插仍open的Grid lease。GameRoot先按phase contract关闭/abort lease与candidate，再使SpatialGrid teardown成功、旧handle全失效，最后调用`BattlePoolSet.teardown(grid_invalidated=true)`。
- teardown是唯一可忽略slot binding/quarantine并统一停止、reset best-effort、`queue_free`全部Pool-owned Node的路径。它只允许READY且resume-binding substate=NONE、Grid已invalidated时执行，从READY进入DRAINING；全部slot失效后清除保存的`config_snapshot_id`并进入TORN_DOWN，重复teardown为OK_NOOP。
- 若Grid尚未证明invalidated，Pool teardown返回`WRONG_STATE`且不free任何BOUND/quarantined Node。不能以scene tree递归free绕过此gate。
- teardown期间reset failure记为suppressed diagnostic，不阻止其余Node停止/queue_free；first gameplay failure不被覆盖。下一场battle创建新PoolSet/新borrow IDs，不复用旧slot identity。
- APP_BACKGROUND与PAUSE_PENDING不改变Pool状态；drain tick只能完成已批准的bind/unbind/release intent，不允许新borrow。该"不新 borrow"约束由 GameRoot phase gate 保证（GameRoot 在此期间不调用 `borrow_into`），不由 Pool 自身拦截——Pool 不识别 caller phase（R4），故仍处 READY；误调路径由 GameRoot phase trace gate 拦截并记 fault（见 AC-D3）。

### R9 — Diagnostics 与调用方责任

- Pool instrumentation至少提供每key：`capacity/available/borrowed/bound/quarantined/release_pending/retired/high_watermark/borrow_failures/reset_failures`，以及 F4 四项零分配 counter：`runtime_slot_growth/runtime_container_resize/borrow_allocation_events/release_allocation_events`（供 AC-F3 allocation positive control 验证）。另须提供 ABA 专项 diagnostic counter（全局，供 AC-F3 ABA 循环断言）：`stale_rejected`（被 STALE_BORROW 拒绝的旧 borrow/Node mutation 次数）、`same_slot_reuse_count`（slot 经 AVAILABLE 回池后被再次 borrow 的次数）、`borrow_id_monotonic_increase`（已签发 borrow_id 计数，校验单调不复用）。
- warning rate-limit key固定为`(status,api,pool_key,pool_epoch)`每epoch一次；telemetry不记录Node内存地址。
- owner必须在权威collection中保存`borrow_id`与`object_instance_id`，Spatial registrant另保存handle。只保存Node引用或只保存slot index不满足生命周期契约。
- gameplay pool任何`THREAD_ERROR/POOL_EXHAUSTED/STILL_REGISTERED/QUARANTINED/OBJECT_INVALID/RESET_FAILED/ID_EXHAUSTED`若出现在非测试路径，都由GameRoot按first-failure协议进入ControlledGameplayFault；不得把它解释为“这次不生成也没关系”。`INIT_LIMIT_EXCEEDED`只允许在BATTLE_LOADING init/validation返回，战斗输入不得开放。

## Formulas

### F1 — Per-key required capacity

对每个`pool_key=k`：

`required_capacity_k = max_concurrent_borrowed_k + max_pause_replacement_overlap_k + max_spawn_before_release_overlap_k + safety_spare_k`

所有项均为非负int并checked sum。Config必须同时满足`required_capacity_k≤configured_capacity_k≤max_capacity_per_key`、`pool_key_count≤max_pool_keys`与`checked Σconfigured_capacity_k≤max_total_capacity`；任一违反都在实例化前返回`INIT_LIMIT_EXCEEDED`且不进入READY。303/400/300同时是 Config 冻结值与 `max_concurrent_borrowed` 下界锚点，只分别约束相关Enemy/Projectile/Drop keys的`max_concurrent_borrowed`总和，不能自动把它们当作单key最终capacity。

**`max_concurrent_borrowed` 的 scope 与 Grid cap 的关系**（防 pause 场景"Pool POOL_EXHAUSTED 但 Grid admission 通过"不一致）：`max_concurrent_borrowed` 是 Pool 的 borrowed 集合范围，包含 SpatialGrid per-type cap（Grid active+pending）的 BOUND 子集，还含 RELEASE_PENDING 与不入 Grid 的 borrowed（如 UNBOUND 投射物）。pause 期间 quarantined 的旧 published authority 仍是 borrowed 集合成员（resume publish 前不可 release），**已计入 `max_concurrent_borrowed`，不是该集合之外的额外 slot**——因此不得在 `max_concurrent_borrowed` 之上再把 `quarantine` 作为独立项叠加：quarantined 实体既是 Grid active handle 计入 per-type cap、又是 borrowed 成员计入 `max_concurrent_borrowed`，任一之上再叠都重复。`max_pause_replacement_overlap` 只建模 pause 期间**净增**的新 borrow（如"冒险夺宝"精英）超出稳态 `max_concurrent_borrowed` 的部分；当 Config v1 取 overlap=0 时，该净增预算转由 `safety_spare` 吸收（见下）。因此 Pool capacity ≠ Grid cap 的真正原因是 Pool 须容纳全部 borrowed（含 RELEASE_PENDING 与不入 Grid 类型），而 Grid cap 只反映注册在 Grid 的条目；权威容量公式即本节 `required_capacity`，**不得用 `Grid_cap + quarantine + ...` 形式重述**（该形式对非 Grid 键 Grid_cap=0 会丢 `max_concurrent`、对 boss 会算出 2>1 与 R1 boss 不变量冲突）。

**`max_pause_replacement_overlap=0` 时的语义**（Config v1 全 6 key 均为 0）：pause 期间旧+新并存预算实际由 `safety_spare` 项吸收。例如 enemy_normal：`configured(320) − max_concurrent(298) − spawn_before_release(12) = 10 = safety_spare`；enemy_elite为`6−4−1=1`。上界证明义务归 owner GDD + fixed-seed churn。`safety_spare` 不得被当作active slot或“掩盖泄漏的百分比魔法值”。

### F2 — Slot conservation

对每个Ready pool：

`capacity = available + borrowed_unbound + borrowed_bound + release_pending + retired`

`effective_capacity = capacity - retired`

quarantine是borrowed/release-pending集合上的标志，不额外加入总和。任意API前后都必须保持等式；同一slot不得同时出现在free stack和borrowed table。READY期间必须持续满足`effective_capacity≥required_capacity`；retirement击穿下限立即触发failure/fault，不动态补slot。

### F3 — Borrow validity

`borrow_identity_valid = pool_epoch_match AND slot_state∈{BORROWED_UNBOUND,BORROWED_BOUND,RELEASE_PENDING} AND slot.borrow_id==input_borrow_id`

`node_alive = is_instance_valid(slot.node_ref) AND slot.node_ref.get_instance_id()==slot.object_instance_id AND not slot.node_ref.is_queued_for_deletion()`

两者必须分开判定，**不得合并为单个 `borrow_valid`**：若把 `node_alive` 并入 `borrow_identity_valid`，则 Node 失效时 identity 判定先短路返回 STALE_BORROW，使下方 `OBJECT_INVALID` 分支永不可达，Node 失效不 retire、不 fault，削弱 ABA 防御（见 R2 / EC3）。

generation是Pool内部slot invariant与诊断字段，不是第二个caller authority token；所有public mutation只以全局不复用的`borrow_id`定位当前slot，再校验该slot保存的generation/instance ID未被内部破坏。

`release_allowed = borrow_identity_valid AND node_alive AND slot_state==BORROWED_UNBOUND AND spatial_handle_id==0 AND quarantine_revision==0`

`release_allowed` 是便于阅读的合取；实际 `release` 返回的精确 `PoolStatus` 由下列分段判定推出，并显式声明 precedence `quarantine > state > handle`（RELEASE_PENDING 这类"已在释放流程"的 state 优先于 BORROWED_BOUND 的 handle 检查，因 release 发起前须已 unbind、handle 为脏残留时仍按 double release 处理；与 R2 6 层 precedence 一致）：

```
release_status =
  if !borrow_identity_valid:                              STALE_BORROW      # borrow_id/slot/generation 不匹配
  elif !node_alive:                                        OBJECT_INVALID    # ABA/外部 queue_free → 退休 slot + GAMEPLAY fault
  elif quarantine_revision != 0:                          QUARANTINED       # precedence over STILL_REGISTERED
  elif slot_state == RELEASE_PENDING:                     STALE_BORROW      # 已在释放中（double release）
  elif slot_state == BORROWED_BOUND or spatial_handle_id != 0: STILL_REGISTERED  # 仍注册在 Grid
  elif slot_state == BORROWED_UNBOUND and spatial_handle_id == 0: OK              # 唯一可 release 路径
  else:                                                    STALE_BORROW
```

当 borrow 同时满足 quarantined 且 BOUND 时，`release` 固定返回 `QUARANTINED`，不被 `STILL_REGISTERED` 覆盖。`OBJECT_INVALID` 触发 slot 退休并对 GAMEPLAY pool 触发 ControlledGameplayFault（与 R2 / EC3 / AC-B3 / AC-B4 一致）。`BORROWED_BOUND` 释放前必须先 `unbind_spatial_handle`（清零 `spatial_handle_id`）再 release——handle 清零是 unbind 的契约，`release_allowed` 不负责清零 handle。release不满足后式时保持原状态并返回精确status，不能best-effort清理。

### F4 — Runtime allocation budget

`runtime_slot_growth = 0`

`runtime_container_resize = 0`

`borrow_allocation_events = release_allocation_events = 0`

上述约束覆盖Active、pause drain与resume transaction；BATTLE_LOADING/teardown的实例化与queue_free不计入steady-state，但必须单独记录峰值内存和时长。

## Edge Cases

1. **If** capacity=0：**Then** 只有明确不使用该key的配置合法；任何borrow返回POOL_EXHAUSTED，不动态创建。
2. **If** 同一borrow连续release两次：**Then** 第一次OK，第二次STALE_BORROW，free stack不重复slot。
3. **If** Node被外部queue_free：**Then** OBJECT_INVALID、slot退休、GAMEPLAY fault；不得实例化替补掩盖。
4. **If** fresh Grid insert失败：**Then** slot仍UNBOUND，可安全release。
5. **If** Grid remove失败：**Then** binding保留，release=STILL_REGISTERED。
6. **If** pending insert被OK_REPLACED：**Then** binding从old原子替换为new，old borrow ID不变。
7. **If** sync失败：**Then** 不解绑、不release，等待ControlledFault cleanup。
8. **If** 任一published GAMEPLAY borrow在Paused期间收到release：**Then** QUARANTINED且no-op。
9. **If** paused新spawn的Grid resume abort：**Then** Grid new handle ID burn；Pool borrow仍UNBOUND，解除tx quarantine后可release，borrow ID不回滚复用。
10. **If** old→0 resume publish：**Then** publish前旧Node仍quarantine/bound；publish后才RELEASE_PENDING→AVAILABLE。
11. **If** old→new且pool_key不兼容：**Then** prepare failure；owner必须改为old→0加独立0→new borrow。
12. **If** slot generation耗尽：**Then** slot退休；有效capacity下降并重新校验required capacity，低于下限则fault。
13. **If** PoolSet teardown时Grid仍Active/Paused且未invalidated：**Then** WRONG_STATE，不free Node。
14. **If** presentation pool exhaustion：**Then** 返回 `OVERFLOW_DROPPED`、丢弃本次借出的新对象、记 telemetry、不 fault、gameplay 不中断；具体 drop 策略（合并窗口/cap 行为/drop 优先级）由 owner GDD 细化。
15. **If** APP_BACKGROUND/PAUSE_PENDING：**Then** 不新borrow；已有borrow identity与quarantine不变。
16. **If** init在第N个Node factory/reset失败：**Then** 前N个已创建Node全部停止/free，PoolSet保持INACTIVE，0个slot可borrow。

## Dependencies

### 上游/并列契约

| Dependency | Object Pooling 使用方式 | 当前状态 |
|---|---|---|
| Godot Node/PackedScene | 预实例化、process/visibility/collision reset、instance ID | 项目尚无运行工程；需Godot spike验证hook成本 |
| Config/Data | per-key ID/factory contract/capacity/criticality/overlap与PoolLimits | `config-data-system.md` Draft；schema v1 foundation contract已冻结 |
| GameRoot | main-thread时序、phase-6 lifecycle journal+gameplay fact ledger、visible-row exact batch authority publish、三段 Paused transaction、fault与teardown授权 | `game-root-scene-flow.md` Re-review Pending（seventh remediation） |
| SpatialGrid | binding status/remap/teardown invalidation契约；Pool不直接调用 | `spatial-grid.md` core contract已冻结 |

### 下游

- EnemySystem、ProjectileSystem、DropSystem必须拥有borrow ID并执行本GDD生命周期矩阵。
- Damage number/VFX若接入Pool，必须在各自GDD声明criticality与exhaustion是否允许视觉降级。
- SpawnDirector只能请求borrow，不能在pool exhaustion时instantiate fallback。
- GameRoot在authority bundle、Paused remap和fault diagnostic中携带borrow ID；BattleUI不得持有borrowed Node作为长期状态。

### Integration gates

- Config已冻结六key容量与PoolLimits；但1191个实际Node尚无min-spec Android内存证据，因此production memory gate仍OPEN。
- Enemy/Projectile/Drop/Damage GDD未完成前，factory asset、reset字段清单与spawn/overlap enforcement仍需各owner补齐；若要拆分既有key必须先修订Config。
- SpatialGrid与GameRoot的Paused集成必须共同通过本GDD AC-E组；任一单体测试不能替代三系统事务证据。

## Tuning Knobs

| Setting | Type | Owner | Rule |
|---|---|---|---|
| `configured_capacity_k` | int | Config | schema v1固定320/6/1/448/320/96；只在下一battle随revision改变 |
| `max_pool_keys/max_capacity_per_key/max_total_capacity` | int | Config + platform/performance | schema v1固定16/512/1536；结构上限不等于memory通过 |
| `safety_spare_k` | int | Config/performance ADR | 不是掩盖泄漏的百分比魔法值；须由fixed-seed churn与内存预算证明 |
| `max_pause_replacement_overlap_k` | int | owner/choice设计 | Paused旧Node quarantine与新Node并存上界 |
| `max_spawn_before_release_overlap_k` | int | Spawn/owner phase设计 | 同tick先spawn后deferred release的峰值重叠 |
| `criticality` | enum | owning GDD | GAMEPLAY默认；PRESENTATION drop须显式AC批准 |

`high_watermark/retired/borrow_failures`是derived instrumentation，不是运行时自动扩容依据。

## Acceptance Criteria

### A. Initialization and Capacity

**AC-A1 定容预实例化**
- Given: 非零snapshot ID的Config schema v1六key与fixed capacities 320/6/1/448/320/96
- When: BATTLE_LOADING init PoolSet
- Then: 精确创建1191个Node与定容workspace；开放input前全部AVAILABLE/reset且getter返回输入snapshot ID；Active/Paused后ID与slot/container capacity不变。注：AC-A1 通过 ≠ memory gate 通过（1191 Node 实例化峰值内存与 warmup 帧预算仍须 min-spec 真机证据，gate 独立于本 AC）
- 验证: unit + scene integration + allocation counters | Gate: BLOCKING

**AC-A2 F1容量与溢出校验**
- Given: 303 Enemy、400 Projectile、300 Drop active下界及逐key pause/spawn overlap，另注入checked sum overflow、capacity少1、per-key/keys/total limit等于上限与大1
- When: validate PoolConfig
- Then: 合法配置required值逐项可追溯且等于各硬上限时成功；overflow、少1或任一硬上限大1返回INIT_LIMIT_EXCEEDED且不进入READY/不实例化Node，不把303/400/300误当所有key最终capacity
- 验证: table-driven config test | Gate: BLOCKING

**AC-A3 init失败原子性**
- Given: 多key配置，并分别在首/中/末Node注入factory、instance identity与warmup reset failure
- When: BATTLE_LOADING init PoolSet
- Then: 返回OBJECT_INVALID或RESET_FAILED；本次已创建Node全部各停止/free一次，private table清空、config snapshot ID=0、状态INACTIVE、0个slot可borrow；清理完成后同一PoolSet以合法配置可从空状态重试
- 验证: scene lifecycle fault injection + leak check | Gate: BLOCKING

**AC-A4 capacity=0 合法配置**
- Given: 某 key 的 `configured_capacity=0` 且该 key 在 Config 中明确声明"不使用"
- When: 该 key 调用 borrow
- Then: 返回 `POOL_EXHAUSTED`、不动态创建 Node、out carrier 零值；其余非零 key 正常借用；不触发 fault
- 验证: table-driven config test | Gate: BLOCKING

### B. Borrow Identity and Reset

**AC-B1 borrow→release→同slot再borrow防ABA**
- Given: capacity=1的typed pool
- When: borrow A、release、再borrow B，并用A的borrow ID/Node引用调用所有mutation
- Then: Node instance ID可相同，但B generation/borrow ID严格更新；A所有调用STALE_BORROW，不能影响B
- 验证: unit + pooled Node fixture | Gate: BLOCKING

**AC-B2 reset清除全部跨borrow状态**
- Given: 为Enemy/Projectile/Drop fixture写入Timer/Tween/target/damage/pierce/Buff/signal/collision/visibility脏状态
- When: release后再borrow
- Then: 仅spawn_context批准字段存在；旧callback不触发；available时process/collision/visibility全禁用；create/resize counter=0
- 验证: owner-specific reset contract tests | Gate: BLOCKING on each owner integration

**AC-B3 double release与外部queue_free**
- Given: 有效borrow
- When: double release及外部queue_free分别执行
- Then: double release第二次STALE_BORROW且free stack唯一；external free=OBJECT_INVALID、slot退休、GAMEPLAY fault
- 验证: adversarial lifecycle test | Gate: BLOCKING

**AC-B4 status precedence 表驱动**
- Given: 构造覆盖 F3 每个分支的代表性输入（每个分支≥1），外加 3 个 precedence 边界 case：(quarantined AND BOUND)→QUARANTINED、(RELEASE_PENDING AND spatial_handle_id!=0 脏残留)→STALE_BORROW、(node_ref 无效 AND borrow_id 匹配)→OBJECT_INVALID；而非对全部(state,substate,carrier,borrow,quarantine,binding)做笛卡尔积
- When: 对每个代表性输入调用 release
- Then: 返回精确 status 符合 F3 分段判定与 precedence `quarantine > state > handle`（与 F3 L185 文本及伪代码 step 顺序一致：quarantine step3 → RELEASE_PENDING state step4 → BOUND/handle step5）；尤其 quarantined AND BOUND → `QUARANTINED`（不被 `STILL_REGISTERED` 覆盖）、double release/RELEASE_PENDING → `STALE_BORROW`、node_ref 失效 → `OBJECT_INVALID`（退休 + GAMEPLAY fault）
- 验证: table-driven precedence matrix test | Gate: BLOCKING

### C. SpatialGrid Lifecycle

**AC-C1 fresh insert failure可返池**
- Given: 新borrow Node且Grid insert分别因参数/容量失败
- When: owner不bind并release
- Then: release=OK、slot回AVAILABLE；无Grid handle、无ghost entry
- 验证: Pool+Grid integration | Gate: BLOCKING

**AC-C2 remove failure禁止返池**
- Given: BOUND active/pending/suspended borrow
- When: Grid remove返回每种failure后尝试unbind/release
- Then: binding不变，错误unbind失败，release=STILL_REGISTERED；Node不reset/不进入free stack
- 验证: status matrix integration | Gate: BLOCKING

**AC-C3 remove success唯一顺序**
- Given: BOUND borrow
- When: 分别测试release-before-remove与remove OK→unbind→release
- Then: 前者STILL_REGISTERED；后者严格由同一intent row按`RESERVED→GRID_REMOVED→POOL_UNBOUND→POOL_RELEASED|POOL_RETIRED`推进，Pool私有slot trace为`RELEASE_PENDING→RESET_COMPLETED→AVAILABLE_COMMITTED|RETIRED_COMMITTED`；各动作一次，旧handle/borrow均stale且只有AVAILABLE slot可安全新borrow
- 验证: deterministic Pool+Grid+journal lifecycle trace | Gate: BLOCKING

**AC-C3b phase 6 第 N 条 failure 不重复/不回滚已提交生命周期**
- Given: 多条 deferred removal intents，在每条 remove/unbind/reset/free-stack checkpoint 注入第 N 次 failure，并在 fault cleanup 中重放同一 intents
- When: GameRoot 依据 journal 收敛 Pool/Grid authority
- Then: 每个intent始终恰一条journal row且state不回退；free stack无重复slot，reset hook每borrow最多一次，retired slot不回AVAILABLE，旧handle/borrow不复活；未开始intents不执行。side effect前BatchPlan已arm，visible committed row=0时0 publish、>0时matching end或fault convergence恰一次batch authority publish，next authority精确排除已committed removals，禁止逐intent/逐state publish
- 验证: exhaustive N-position fault injection + conservation equation | Gate: BLOCKING

**AC-C4 pending replace原子binding**
- Given: pending handle old，同borrow Grid insert返回OK_REPLACED/new
- When: replace_spatial_handle分别给matching与错误old/new
- Then: matching一次提交old→new；错误输入no-op；任何时点release均不能穿过有效binding
- 验证: unit + Grid integration | Gate: BLOCKING

**AC-C5 sync failure保持ownership**
- Given: pending/staged borrowed Nodes
- When: Grid sync=SYNC_FAILED/ID_EXHAUSTED
- Then: Pool binding/quarantine/free counts不变；无Node release；GameRoot进入fault cleanup
- 验证: fault injection integration | Gate: BLOCKING

### D. Quarantine

**AC-D1 Published borrow不可release/reborrow**
- Given: published authority含active/suspended BOUND实体及UNBOUND投射物
- When: begin_quarantine后对每项release并持续borrow到其它free slots
- Then: 全部published borrow的release=QUARANTINED且identity不变；新borrow从不同AVAILABLE slot取得；无published authority Node复用
- 验证: Pool+GameRoot+Grid integration | Gate: BLOCKING

**AC-D2 quarantine validate-then-commit**
- Given: ids中包含duplicate/stale/wrong instance，或漏掉一个BOUND/UNBOUND live GAMEPLAY borrow
- When: begin_quarantine
- Then: failure且0个slot被部分标记；合法输入一次标记全部并revision一致
- 验证: table-driven transaction test | Gate: BLOCKING

**AC-D3 APP_BACKGROUND/PAUSE_PENDING 不新 borrow（GameRoot phase-gate）**
- Given: 已有 live borrow 与部分 quarantine 的 PoolSet；Pool 不新增 pause/drain 状态、不识别 caller phase（R4 哲学）
- When: 进入 APP_BACKGROUND/PAUSE_PENDING，drain tick 期间 GameRoot 不调用 borrow_into；测试另注入"误调"路径验证 trace gate
- Then: APP_BACKGROUND/PAUSE_PENDING 期间无 `borrow_into` 调用由 GameRoot phase trace gate 证明（集成于 game-root-scene-flow.md）；此期间 Pool 仍处 READY，若被误调则按 READY 正常返回 OK/POOL_EXHAUSTED——该误调路径由 trace gate 拦截并记 fault，不由 Pool 返回错误 status；已有 borrow identity、slot state、quarantine_revision 全部不变；drain tick 可完成已批准的 bind/unbind/release intent
- 验证: GameRoot phase trace gate 集成测试 + state isolation test（证明 Pool 内部状态不变） | Gate: BLOCKING

### E. Resume Transaction

**AC-E1 survivor/new/removed remap发布**
- Given: indexed E survivor old→same、F paused new 0→new、G removed old→0，及UNBOUND projectile H survivor、I removed、J paused new
- When: Grid prepare/arm 后按 Grid publish→Pool publish→authority publish 执行
- Then: E保持borrow并绑定same；F同paused borrow绑定new；G/I只在三次 publish 收敛且 consumer 仍关闭时 RELEASE_PENDING→AVAILABLE/RETIRED；H保持同borrow/UNBOUND，J保持新borrow/UNBOUND；只有 authority publish 完成才清除 survivor/new quarantine
- 验证: 三系统deterministic integration | Gate: BLOCKING

**AC-E2 resume abort保持旧快照**
- Given: Pool prepare后分别注入Grid arm failure、Pool arm failure、owner swap failure
- When: GameRoot abort Grid/Pool candidate
- Then: E/G旧binding与quarantine保持；F解除tx quarantine后仍UNBOUND可release；published slot table identity/revision不变
- 验证: failure matrix integration | Gate: BLOCKING

**AC-E3 matching publish不可失败**
- Given: Grid与Pool均Armed且owner swap成功
- When: matching Grid publish后 matching Pool publish，再由 GameRoot matching authority publish；另在每个 checkpoint 前注入 identity/config mismatch，并先注入一次 wrong Pool tx
- Then: Node invalid/queued/instance mismatch/capacity错误全部在arm返回failure且Grid publish调用数=0；arm成功后 matching Grid/Pool publish 均 OK 且 Pool publish 无 allocation/Node API调用；wrong tx=INVALID_ARGUMENT并保持Pool ARMED，随后正确tx使三方收敛再fault；authority publish 前 consumer 始终 closed，不存在 Grid 已发布而 Pool 保持 ARMED、authority 仍旧却开放 consumer 或回滚旧 binding 的路径
- 验证: invariant test + code review | Gate: BLOCKING

**AC-E4 old→new pool_key 不兼容 fallback**
- Given: paused choice 要求 old quarnatined borrow 换成不同 pool_key 的新 PackedScene/class
- When: prepare_resume_bindings 检测 old→new 的 pool_key 不兼容
- Then: prepare 返回 failure、不部分改 binding；owner 走 old→0（旧 borrow 进入 RELEASE_PENDING）+ 独立 0→new（新 borrow 从 AVAILABLE 取，UNBOUND）；old→0 与 0→new 均 publish 后才生效，无中间可消费窗口
- 验证: fallback path integration | Gate: BLOCKING

### F. Exhaustion, Teardown and Performance

**AC-F1 gameplay pool exhaustion不动态fallback**
- Given: capacity全部BORROWED/quarantined
- When: 再borrow GAMEPLAY key
- Then: POOL_EXHAUSTED、out carrier已验证后为零且无权威值；Node总数/capacity不变；GameRoot进入ControlledFault
- 验证: release black-box + node count | Gate: BLOCKING

**AC-F2 teardown必须晚于Grid invalidation**
- Given: 含BOUND/quarantined slots
- When: 先在Grid未invalidated调用teardown，再按Grid teardown→Pool teardown顺序调用
- Then: 前者WRONG_STATE且0 Node freed；后者全部slot各停止/free一次、旧borrow stale、重复teardown=OK_NOOP
- 验证: lifecycle integration + leak check | Gate: BLOCKING

**AC-F3 满载churn零增长**
- Given: 按F1 capacity运行303 Enemy/400 Projectile/300 Drop、同tickspawn/release峰值、100次pause（含N次完整prepare→arm→publish→end_phase成功路径+M次abort+K次commit-failure）与100,000次capacity=1 ABA循环
- When: release artifact持续运行并记录Pool counters
- Then: runtime_slot_growth/runtime_container_resize/borrow_allocation_events/release_allocation_events均0；conservation等式每tick成立；无duplicate free、stale mutation、bound release或quarantine reuse；ABA 100,000次中 stale_rejected==same_slot_reuse_count==borrow_id_monotonic_increase==100,000
- 验证: deterministic soak + allocation positive control。positive control 须可证伪：A/B 两路唯一差异为 borrow/release/prepare 路径内显式创建一个 Dictionary/Object，observed allocation delta 必须 >0，否则 harness 不合格（harness 与 `spatial-grid.md` AC-B7/J3 共享同一 allocation 测试工具）。 | Gate: BLOCKING before implementation Done

**AC-F4 retirement不静默侵蚀容量**
- Given: 测试钩子令slot generation接近耗尽并制造reset-invalid retirement
- When: slot退休
- Then: retired计数增加、slot不再borrow；effective capacity低于F1 required时立即failure/fault，不动态补slot
- 验证: counter boundary unit | Gate: BLOCKING

**AC-F5 PRESENTATION overflow drop**
- Given: `damage_number`（PRESENTATION，capacity=96）全部 BORROWED 且处于 AoE 峰值（300 敌人、范围技能每 tick 命中数十）
- When: 再 borrow PRESENTATION key
- Then: 返回 `OVERFLOW_DROPPED`（success 类）、不动态 instantiate、不触发 ControlledGameplayFault、gameplay 不中断、telemetry 记 overflow 计数；GAMEPLAY pool 同条件仍 `POOL_EXHAUSTED` + fault
- 验证: overflow injection + telemetry assertion | Gate: BLOCKING

## Coverage Matrices

### 规则/公式 → AC 映射

| Rule/Formula | 覆盖 AC |
|---|---|
| R1 PoolSet/预分配 | AC-A1, AC-A2, AC-A3, AC-A4, AC-F1, AC-F5 |
| R2 identity/carrier/status | AC-B1, AC-B3, AC-B4 |
| R3 slot 状态/reset hook | AC-B2, AC-B3, AC-F3 |
| R4 borrow/release | AC-B1, AC-B3, AC-C3 |
| R5 SpatialGrid binding matrix | AC-C1, AC-C2, AC-C3, AC-C4, AC-C5 |
| R6 Paused quarantine | AC-D1, AC-D2, AC-D3, AC-E1 |
| R7 resume transaction | AC-E1, AC-E2, AC-E3, AC-E4 |
| R8 fault/drain/teardown | AC-F2 |
| R9 diagnostics | AC-F3, AC-F5 |
| F1 required capacity | AC-A2, AC-A4, AC-F1 |
| F2 slot conservation | AC-F3, AC-F4 |
| F3 borrow validity/status precedence | AC-B1, AC-B3, AC-B4 |
| F4 runtime allocation budget | AC-F3 |

### EC → AC 覆盖矩阵

| EC | 描述 | 覆盖 AC |
|---|---|---|
| EC1 | capacity=0 合法 + borrow | AC-A4 |
| EC2 | 同 borrow 连续 release 两次 | AC-B3 |
| EC3 | Node 被外部 queue_free | AC-B3 |
| EC4 | fresh Grid insert 失败 | AC-C1 |
| EC5 | Grid remove 失败 | AC-C2 |
| EC6 | pending insert OK_REPLACED | AC-C4 |
| EC7 | sync 失败 | AC-C5 |
| EC8 | published borrow Paused 期间 release | AC-D1 |
| EC9 | paused 新 spawn resume abort | AC-E2 |
| EC10 | old→0 resume publish | AC-E1 |
| EC11 | old→new pool_key 不兼容 | AC-E4 |
| EC12 | slot generation 耗尽 | AC-F4 |
| EC13 | teardown Grid 未 invalidated | AC-F2 |
| EC14 | presentation pool overflow | AC-F5 |
| EC15 | APP_BACKGROUND/PAUSE_PENDING | AC-D3 |
| EC16 | init 第 N 个 Node 失败 | AC-A3 |

**核对规则**：16 个 EC 全部有 AC 覆盖（16/16），无悬空项。新增 AC 时须同步更新本矩阵，不得留空。
