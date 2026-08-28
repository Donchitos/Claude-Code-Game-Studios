# GameRoot & Scene Flow（全局根与场景流）

> **Status**: Re-review Pending — 第四轮 full design-review（MAJOR REVISION NEEDED）7 个根 BLOCKING 已聚焦修订，待第五轮独立复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-08-28 — 第四轮复审后修订；不代表 runtime、performance、Save integration 或 evidence gate 已通过
> **Implements Pillar**: 战斗—暂停选择—结算—再开局的可靠闭环
> **Scope**: MVP minimum；冻结中央编排、状态、身份与跨系统后置条件，不定义各玩法系统内部规则
> **Review Mode**: full；InputSystem 内部 FSM 以 `input-system.md` 为唯一权威

## Overview

GameRoot 是应用生命周期内唯一、持续存在的场景流控制器与 gameplay physics phase 编排者。从 `BOOT` 到应用退出恰有一个 GameRoot；HOME、PREP、Battle、Fault 与 Settlement 页面/场景是其可替换 child scope。具体采用 Autoload 还是 main-scene persistent root 归实现 ADR，但不得按页面或每局重建第二个 GameRoot。

GameRoot 负责合法顶层转换、SceneTree pause authority、固定 participant 调度、本局 authority/resolution bank、battle identity、加载/清理 DAG，以及 SpatialGrid、Object Pooling、InputSystem、RNG、Stage 与持久化边界协调。它不计算伤害、不生成敌人、不选择技能，也不复制依赖系统的内部 FSM。

## Player Fantasy

玩家应感觉进入试炼、暂停选择、恢复和结算都干净、即时、可信。暂停请求在安全 barrier 进入 `PAUSE_PENDING` 并显示输入已锁定后，不再产生新的 gameplay effect；此前已经合法提交的事实不会被伪造回滚。技术故障不会伪装成战败，也不会在保存成功前谎报奖励已经到账。

## Detailed Rules

### R1 — Lifetime、单一 owner 与公开边界

- GameRoot 自 `BOOT` 至应用退出保持同一 live identity。battle-scoped carriers、banks、services、participants、Stage child 与 battle Viewport 每局创建并在 Ending/Fault cleanup 完整销毁；HOME/SETTLEMENT 不得持有旧 Node、lease、bank 或 borrow 引用。
- GameRoot 精确使用 `PROCESS_MODE_ALWAYS`：`_physics_process(delta)` 仅在 `SceneTree.paused==false && state==BATTLE_ACTIVE` 驱动七 phase；`_process(delta)` 仅在 `SceneTree.paused==true && state in {BATTLE_PAUSED,RESUME_PREPARING}` 驱动 control pump。participant 使用 PAUSABLE mode，且不得定义自主 gameplay `_physics_process/_process/_input/_unhandled_input`。
- GameRoot 是 `SceneTree.paused` 与目标 battle Viewport `gui_disable_input` 的唯一项目 writer。Viewport 正确 setter 为 `set_disable_input(bool)`；pause writer 只能通过 GameRoot 私有 helper 调用 `SceneTree.set_pause(bool)` 并 readback。
- participant 在 BATTLE_LOADING 按稳定 manifest 注册，Active 后不可增删或重排。manifest 每行冻结 `{participant_id,stable_order,allowed_phases,allowed_success_statuses}`；公开调用为 `run_phase(phase,context,lease_id)->int status`。
- GameRoot 独占 SpatialGrid `begin_phase/end_phase`，lease 不得跨同步调用栈缓存。Input callback ABI、gesture/shield bank、三字段 tuple、geometry rebuild 与内部状态迁移只由 `input-system.md` 定义。
- Window/Viewport size、safe-area、orientation 到 `INPUT_GEOMETRY_CHANGED` revision 的采集与 canonicalization 归 InputSystem。GameRoot 禁止注册或镜像 geometry event source，只消费 typed revision。
- battle input target 入树前，唯一 GameRoot 在 BOOT 完成 Input accumulated disable/readback、ProjectSettings agile readback 与一次历史 buffer flush；本局后续不得重新执行或修改这些设置。

### R2 — 顶层状态、合法边与 scene assembly

| State | 玩家可见页面 | SceneTree pause predicate | 权威行为 |
|---|---|---:|---|
| `BOOT` | 启动遮罩 | false | 最小配置/存档与唯一 Input bootstrap |
| `HOME` | 洞府 | false | 局外入口；不得引用 battle scope |
| `PREP` | 开局准备 | false | 冻结 immutable `RunStartRequest` |
| `BATTLE_LOADING` | 加载遮罩 | false | 构建 typed battle assembly，consumer/input closed |
| `BATTLE_ACTIVE` | 战斗页 | false | 执行完整七 phase tick |
| `PAUSE_PENDING` | 战斗画面+输入锁定反馈 | false | 最多一个零 gameplay-dt drain tick |
| `BATTLE_PAUSED` | 原因对应暂停/选择层 | true | gameplay frozen；control pump 可运行 |
| `RESUME_PREPARING` | 保持暂停层 | true；仅 gated ACTIVE 尾段允许暂时 false | prepare→arm→publish→held-drain→activation |
| `BATTLE_ENDING` | 输入锁定 | false | 安全 teardown，发布 normal/abandoned outcome |
| `SETTLEMENT` | 结算页 | false | 消费 immutable outcome facts 与 Save receipt |
| `CONTROLLED_FAULT` | 技术故障层 | battle child cleanup 中 true；无battle child或移除后 false | 停止新效果；有battle identity时保存fault前事实，支持retry/safe exit |

合法边以本表为唯一枚举权威；未列边返回 `WRONG_STATE` 且 `ResourceIdentityManifest` 内所有引用、revision 与 writer ownership 不变：

| Source | Event / guard | Target | Required action / failure edge |
|---|---|---|---|
| `BOOT` | bootstrap success | `HOME` | 发布最小局外依赖；failure→`CONTROLLED_FAULT` |
| `HOME` | start run | `PREP` | battle scope仍为空 |
| `PREP` | confirm `RunStartRequest` | `BATTLE_LOADING` | 分配新 `battle_instance_id`；cancel→`HOME` |
| `BATTLE_LOADING` | assembly+activation success | `BATTLE_ACTIVE` | consumer/input 只在 reasoned release 后开放 |
| `BATTLE_LOADING` | safe abort before persistent uncertainty | `PREP` | 按 cleanup DAG 收敛；root/persistence uncertainty→`CONTROLLED_FAULT` |
| `BATTLE_ACTIVE` | pause request at barrier | `BATTLE_PAUSED` or `PAUSE_PENDING` | Grid立即 frozen→直接Paused；`PENDING_WORK`→Pending |
| `PAUSE_PENDING` | one drain completes | `BATTLE_PAUSED` | 第二次 pending或任一 failure→`CONTROLLED_FAULT` |
| `BATTLE_PAUSED` | all resume predicates true | `RESUME_PREPARING` | 捕获 attempt revisions；manual exit→`BATTLE_ENDING` |
| `RESUME_PREPARING` | pre-publish abort/invalidation/held | `BATTLE_PAUSED` | old owner restored、candidate/lease closed |
| `RESUME_PREPARING` | post-publish held | `RESUME_PREPARING` | substate=`RESUME_HELD_DRAIN`，无 open resource |
| `RESUME_PREPARING` | activation success | `BATTLE_ACTIVE` | Input/GameRoot commit 后 reasoned release |
| `RESUME_PREPARING` | post-point failure/invalidation | `CONTROLLED_FAULT` | 用保存 tx 完成收敛，禁止 rollback |
| any battle state | battle-end intent wins | `BATTLE_ENDING` | 在安全 barrier latch；fault优先走 fault edge；若源状态已pause，则先保持consumer/input关闭，再由唯一writer执行`set_pause(false)`并readback后teardown |
| any battle state | fatal service/contract failure | `CONTROLLED_FAULT` | battle child仍在树中时先由唯一writer执行`set_pause(true)`并readback；保留前序committed facts，当前staging丢弃 |
| `BATTLE_ENDING` | outcome+cleanup success | `SETTLEMENT` | 发布唯一 outcome；failure→`CONTROLLED_FAULT` |
| `SETTLEMENT` | return home / retry run | `HOME` / `PREP` | 旧 battle scope必须为0 |
| `CONTROLLED_FAULT` | retry same commit | `CONTROLLED_FAULT` | 复用同一 `outcome_commit_id`，不得重复发奖 |
| `CONTROLLED_FAULT` | safe exit after battle cleanup | `HOME` | unsaved commit保留为进程内 pending；UI不得称已保存 |

BOOT/HOME/PREP 中尚未发布 `battle_instance_id` 的前置故障不得构造 `RunOutcomeEnvelope`、`outcome_commit_id` 或奖励 reservation；只记录启动诊断，并提供 bootstrap retry 或无“战局已保存”文案的 safe exit。只有已发布 battle identity 的故障才进入 R8/R9 的 technical outcome 与 Save 状态机。

BOOT 先在任何 battle input target/consumer/callback/polling 入树前完成一次 Input bootstrap。每次 BATTLE_LOADING 固定创建 DAG：

`RunStartRequest{battle_instance_id,run_seed}→Config build(battle_ready)→RNG init(snapshot.run_seed)→按battle/config identity预分配carriers/banks→Stage scene assembly{stage_root,stage_camera,battle_viewport}→验证唯一active Camera2D与Viewport identity→Input init→SpatialGrid init(snapshot,stage config)→Pool init→owners warmup→owner/Grid/Pool identity preflight→Viewport gate acquire→Input ACTIVE publish→GameRoot local commit→ACTIVATION_SUCCESS release`。

Stage camera 必须满足 `stage_camera.get_viewport()==battle_viewport` 且 `battle_viewport.get_camera_2d()==stage_camera`；不得存在第二个 enabled battle camera。GameRoot只保存 non-owning assembly引用，不写camera `zoom/position/limit/enabled`。

任一失败只清理已创建资源，按依赖 DAG 收敛而非机械逆序：

`consumer/input close→owner rollback/teardown→close/abort leases+candidates→SpatialGrid teardown并使旧handle失效→Pool teardown(grid_invalidated=true)→Grid reset→Input terminal + battle input child cleanup→Home/Prep/Fault UI成为唯一input target→reasoned Viewport gate release→Stage child removal→carriers/banks/RNG/config snapshot release`。

### R3 — Battle identity、authority/resolution bank 与 exact-once token

- PREP 每次确认新局都分配非零、应用生命周期内单调且不复用的 `battle_instance_id:int64`；耗尽=`ID_EXHAUSTED`。`run_seed`可以重复，不是identity。`config_snapshot_id`是 `BattleConfigSnapshot.snapshot_id` 的跨文档同义名，仅表示本局Config实例，也不是持久化幂等键。
- 两个等容量 `BattleAuthorityBundle` 在load预分配，header固定为 `{battle_instance_id,config_snapshot_id,bank_id in {0,1},authority_revision}`。初始published authority revision=0；每次DEFERRED_REMOVAL或Paused choice/resume authority publish checked `+1`，空但合法publish也递增；failure不递增，耗尽=`ID_EXHAUSTED`。
- `AuthorityCopyManifest` 枚举每个 primitive SoA 字段及独立 authoritative count。A/B carrier预resize并独占backing；Active/Paused禁止 `clear/resize/append_array/duplicate/slice`、共享COW alias、容器替换和dirty-patch。每字段逐index复制 `[0,count)`，tail非权威。
- 两个 `ResolutionStagingBank` header固定为 `{battle_instance_id,bank_id,source_authority_revision,tick_revision}`。matching QUERY_CONSUME publish产生 `ResolutionPublishToken={battle_instance_id,bank_id,source_authority_revision,tick_revision}`。
- DEFERRED_REMOVAL 仅当published token逐字段匹配当前battle、published bank、source authority与tick，且 `consumed_token!=published_token` 时消费。消费任何effect前原子复制完整token到 `consumed_token`；同token二次消费为0。failure不产生新token，不得重放旧bank；跨battle、错bank、错authority或错tick token均fault。
- Grid `snapshot_revision`、GameRoot `authority_revision`、`tick_revision`、Config `snapshot_id` 与Input/background/geometry revision是独立轴，不得统称 `snapshot revision`。
- `FailureDiagnosticBank` 在load预分配：1个first槽、固定 `MAX_SUPPRESSED_DIAGNOSTICS=C` 槽与overflow counter。first schema固定为 `{battle_instance_id,state,tick_revision,phase,status,api_id,participant_id,config_snapshot_id}`；热路径只写primitive稳定ID，字符串格式化在gameplay停止后进行。

### R4 — 唯一 Active tick

| Order | Phase | 行为 | publish point |
|---:|---|---|---|
| 1 | `SPAWN_INTENT` | spawn/despawn intent、fresh insert/cancel | 无 |
| 2 | `MOVEMENT_COMMIT` | Input carrier→Player/Enemy committed position | 无 |
| 3 | `GRID_SYNC` | `SpatialGrid.sync` | sync=`OK` 发布 Grid snapshot |
| 4 | `QUERY` | consumer 写 caller-owned query buffers | 无 |
| 5 | `QUERY_CONSUME` | resolve+narrowphase→inactive resolution | matching end=`OK` 后发布 resolution |
| 6 | `DEFERRED_REMOVAL` | damage/death/pickup/remove→release | matching end=`OK` 后发布 authority |
| 7 | `POST_DEFERRED_BARRIER` | metrics、battle-end/pause intent | matching end 生成 next tick pair |

每phase固定 `begin→stable participants→enumerated service has_fault→matching end`。service集合至少包含RNG global fault、Input async fault service、SpatialGrid与Pool状态；仅全部status属于manifest success class、matching end=`OK`且无service fault才进入下一phase。

phase failure只丢弃当前phase未提交staging并阻止未来phase；此前phase已经成功发布的Grid/resolution/authority事实保持，不得伪造整tick rollback。`PENDING_WORK`只允许来自pause barrier。

### R5 — Failure、rollback 与不可逆点

- query/resolve/fatal narrowphase failure 丢弃整个 query transaction；published bank不变，普通 no-hit 仍是 success。
- first failure保存R3固定schema；cleanup failure按注入顺序写suppressed槽，不覆盖root cause。
- pause/resume 中所有可失败 Grid/Pool/owner validation 必须在 arm 完成。第一次 matching publish 调用是不可逆点；matching Grid publish 与 Pool publish 均必须不可失败并用正确 tx 收敛。
- 点前 failure 恢复 old owner、abort candidates、关闭 lease；点后异常完成尚未完成的 matching publish/lease/quarantine cleanup，再进入 `CONTROLLED_FAULT`，禁止伪造双向 rollback。
- failure发生在phase 6/7时，phase 5/6已经发布的前序事实仍可进入TECHNICAL_ABORT的fault-before-fact结算；当前失败phase的新staging不得进入。

### R6 — Pause intent、reason queue、drain 与 pause-on

pause source固定为 `MANUAL/LEVEL_UP/TREASURE_CHOICE/RISK_CHOICE/APP_BACKGROUND/INPUT_GEOMETRY_CHANGED`。GameRoot持有预分配pending-reason队列，每项含 `{reason,priority,intent_sequence,completed_or_acked}`；排序为 `priority DESC→intent_sequence ASC`。同级choice不按类型覆盖，保持稳定产生顺序。

优先级为 `BATTLE_END > BLOCKING_CHOICE > APP_BACKGROUND > INPUT_GEOMETRY_CHANGED > MANUAL`。presentation每次只显示队首原因，但其他reason不得丢失；`can_start_resume`要求全部choice完成、manual已确认、latest background revision已ack、geometry已处理、Input clean且held=false。

barrier顺序：`collect/sort intent→Input cancel→Grid request_pause→matching end→Pool quarantine→Input FROZEN publish→SceneTree.set_pause(true)→readback true→GameRoot BATTLE_PAUSED commit→pause UI publish`。

`PENDING_WORK`允许恰一个零gameplay-dt drain tick。drain仍留下七phase matching trace，但只允许完成pause request前已经批准的cancel/unbind/release/lease closure；fresh borrow、spawn/query/narrowphase/damage/pickup/reward、movement、gameplay timer与新intent均为0，其他participant返回`OK_NOOP`。第二次pending或任一failure进入ControlledFault。

| Reason | 标题/短提示 | 完成条件 |
|---|---|---|
| `MANUAL` | “试炼暂停” | Continue确认 |
| `LEVEL_UP` | “境界提升：选择一项” | choice exact-once完成 |
| `TREASURE_CHOICE` | “法宝机缘：选择一项” | choice exact-once完成 |
| `RISK_CHOICE` | “机缘抉择：选择一项” | choice exact-once完成 |
| `APP_BACKGROUND` | “已安全暂停，准备好后继续” | latest background revision确认 |
| `INPUT_GEOMETRY_CHANGED` | “界面已调整” | geometry处理完成；无manual/background时可自动 |

每次choice press前读取 `is_choice_input_blocked()`。若拒绝，intent=0；本blocked episode首个拒绝press显示一次“请先松开移动手指”，后续不重复，predicate恢复false时清除。

### R7 — Paused control pump 与 resume checkpoints

- 每个 `BATTLE_PAUSED/RESUME_PREPARING` control-pump iteration固定执行：`service_pending_input_fault→读取typed input/background/geometry revisions→更新pending reason completion/ack→检查choice/held→若can_start_resume且无attempt则启动/继续attempt`。任一async fault不得等玩家再次点击才被观察。
- `PAUSE_READ`只读lease必须matching end，且不得与`RESUME_EXCLUSIVE`重叠。choice mutation只写inactive authority bank；frozen/removed Node保持quarantine。
- 每个attempt只捕获一次 `{battle_instance_id,input_revision,background_required/acked,geometry_revision,authority_revision,grid_snapshot_revision}`，并在Grid prepare前、arm前、首次publish前、两次publish之间、cleanup后、held-drain每次iteration、unpause返回后、Input ACTIVE前和Viewport release前复核。
- 固定事务：`Input RESUME_LOCKED/cancel→optional rebuild→Grid resume_from→Pool prepare→Grid arm→Pool arm(final Node/capacity check)→owner swap→matching Grid publish→matching Pool publish→end/quarantine cleanup→Viewport PRE_ACQUIRE/SET_TRUE_IN_FLIGHT/GATE_HELD→set_pause(false) return→GameRoot explicit observer→Input ACTIVE→GameRoot ACTIVE→ACTIVATION_SUCCESS release`。
- 首次matching publish前发现revision/invalidation/held：fault-free恢复old owner、abort/close、Input回FROZEN、保持SceneTree paused并回`BATTLE_PAUSED`。首次publish后发现invalidation/failure：用保存tx完成收敛后fault，禁止rollback。
- 首次publish后仅出现合法held touch时，顶层仍为 `RESUME_PREPARING`，substate=`RESUME_HELD_DRAIN`；candidate/lease/quarantine必须为0，SceneTree保持paused，UI一次显示“请松开移动手指以继续”。terminal后自动重跑ACTIVE尾段，不重跑Grid/Pool transaction。
- `set_pause(false)`返回后显式observer若发现held-only，先由唯一pause helper重新`set_pause(true)`并readback，再回held-drain；若发现fault/invalidation则保持Viewport gate与consumer closed并走fault。

### R8 — Battle end、immutable outcome 与 commit identity

`outcome_kind`冻结为 `VICTORY/DEFEAT/ABANDONED/TECHNICAL_ABORT`。victory、death、已二次确认的manual exit只latch `battle_end_intent`，在安全barrier进入BATTLE_ENDING；manual exit固定ABANDONED且不写新纪录。

GameRoot在teardown前发布一次immutable、versioned `RunOutcomeEnvelope`：

`{schema_version,outcome_commit_id,outcome_kind,battle_instance_id,run_seed,config_snapshot_id,authority_revision,survival_ticks,committed_kill_counts,level,skill_damage_totals,damage_received_by_source,risk_choice_results,reward_source_facts,new_record_candidates,technical_failure_value}`。

`outcome_commit_id`在Ending/Fault gameplay停止后创建一次，是跨Save retry稳定的opaque identity；生成算法与跨进程持久化归Save ADR。`technical_failure_value`是复制后的稳定primitive/value schema或incident ID，不得引用即将teardown的diagnostic bank。

GameRoot拥有facts envelope、source revision与producer completeness；各gameplay owner提供字段。Settlement/Save不得在teardown后读取battle Node或猜测重建。缺mandatory producer时不发布Settlement success，story保持BLOCKED。

保存状态不在immutable envelope内。Save coordinator按同一commit ID拥有 `SaveCommitAttempt={state in NOT_STARTED/SAVE_PENDING/SAVE_SUCCEEDED/SAVE_FAILED,attempt_count,receipt_id}`；normal/fault均使用同一状态机与幂等键。

### R9 — ControlledGameplayFault、Save retry 与安全退出

- TECHNICAL_ABORT不写胜负、死亡原因、纪录或教程完成度；禁止fault tick未提交staging进入奖励。
- 部分奖励来源：灵石=已提交击杀；功法残页=已提交存活tick；种子=仅fault前已拾取数量，未拾取为0。开局灵药reservation补偿与奖励commit复用同一 `outcome_commit_id`，retry不得重复补发或重复扣除。
- normal Settlement与fault UI都必须诚实显示 `SAVE_PENDING/SAVE_SUCCEEDED/SAVE_FAILED`。成功前“奖励已到账/已保存”出现数=0；失败可按同一commit ID重试。
- fault safe exit只在battle cleanup完成后进入HOME。若commit仍失败，pending attempt保留于当前进程，HOME显示“异常前进度尚未保存，可重试”；关闭应用前必须警告可能丢失，且永久资源仍不可见为到账。跨进程恢复能力保持BLOCKED on Save GDD。
- fault UI或HOME pending badge的重复render/callback不得启动第二个并发commit；任意时刻同一commit ID最多一个in-flight attempt。

### R10 — Engine/Performance Evidence Gates

| Gate | Owner | Artifact / pass condition | Failure contingency |
|---|---|---|---|
| `GATE-OQ-INPUT` | InputSystem | Godot 4.7.1 callback/Window relay trace；真实 background/safe-area/orientation | 修订 Input GDD/relay，不由 GameRoot镜像 workaround |
| `GATE-OQ-VIEWPORT` | GameRoot+Input | set_disable_input与set_pause同步重入、reasoned release trace | redesign activation/pause observer |
| `GATE-OQ-ALLOC` | Performance | release artifact、observer/baseline、allocator/container/COW evidence及positive controls | 无有效observer则INCONCLUSIVE，story不得Done |
| `GATE-OQ-TIME` | Producer+Performance | min-spec、artifact、workload、timer、thermal、warmup/sample、percentile算法与p95/p99 | 保持OPEN，不发明阈值 |
| `GATE-OQ-STATIC` | QA | `project.godot`、GDUnit4、`tools/ci/static_guard_check.py` 实际存在且通过 | implementation-ready=false |

## Formulas

### F1 — Transaction commit

`transaction_success = all(status(ci) in participant_manifest[ci].allowed_success_statuses) AND matching_end==OK AND no_enumerated_service_fault`

`ci`域为当前phase的稳定participant行；空集 `all(empty)=true`。success只发布当前transaction；failure保持当前transaction目标bank identity/revision不变，前序phase已发布事实保留。

### F2 — Pause drain

`extra_pause_drain_ticks in {0,1}`。`physics_dt`必须finite且`>=0`；普通ACTIVE tick才有 `gameplay_dt=physics_dt`，Pending/Paused/Resume/Fault均为0。非法dt进入ControlledFault，不能clamp或fallback。

### F3 — Revision axes

- `tick_revision`：每局初值1；POST_DEFERRED_BARRIER成功checked `+1`。
- `grid_snapshot_revision`：Grid init为0；仅Grid sync/resume publish按其GDD递增。
- `authority_revision`：GameRoot init为0；每次authority publish checked `+1`。
- resolution token：精确绑定 `{battle_instance_id,bank_id,source_authority_revision,tick_revision}`。
- `config_snapshot_id`：Config snapshot identity，pause/resume不变。

任何int64 checked increment耗尽=`ID_EXHAUSTED`，不回绕。pause/resume不额外增加tick，但合法Paused authority mutation publish会增加authority revision。

### F4 — Pause ordering and resume predicate

`reason_order = sort(priority DESC,intent_sequence ASC)`。

`can_start_resume = all_choices_completed AND manual_confirmed_if_present AND background_acked==background_required AND geometry_clean AND input_clean AND held_count==0 AND no_service_fault`。

### F5 — Runtime metrics

结果记录 `{artifact_id,artifact_hash,device_manifest,observer_name,observer_version,workload_id,baseline_id,timer_resolution,thermal_state,warmup_samples,measured_samples,percentile_method,p50,p95,p99,max,allocator_events,allocator_bytes}`。`measured_samples>0`；缺artifact、positive control、observer或非空workload时=`INCONCLUSIVE`。desktop结果只能`SPIKE_ONLY`。

### F6 — Diagnostic capacity

对suppressed尝试数 `S` 与固定容量 `C=MAX_SUPPRESSED_DIAGNOSTICS`：

`stored_suppressed=min(S,C)`；`suppressed_overflow_count=max(0,S-C)`。

first槽保持首次值，前 `min(S,C)` 条按注入顺序保存；bank identity与size始终不变。

## Edge Cases

1. pause与death/victory同tick：battle-end优先，不展示choice UI；pending reason随battle teardown失效。
2. pause request立即OK：跳过PAUSE_PENDING，完成Pool/Input/pause-on后直接BATTLE_PAUSED。
3. drain后仍PENDING：ControlledFault；不执行第二个drain。
4. phase 6/7 failure：保留phase 3/5/6已经合法published事实，只丢当前未提交staging。
5. cross-battle或错bank resolution token：消费0、进入fault；不得碰旧bank。
6. same-tick多choice：按intent sequence逐个展示，每个effect exact-once。
7. manual+choice/background：choice完成不自动resume，直到manual/background条件也满足。
8. resume首次publish前新revision/held：rollback至Paused；点后invalidation收敛后fault，点后held进入substate drain。
9. fault UI spam：同commit ID最多一个in-flight Save attempt。
10. Save commit失败后safe exit：HOME显示unsaved pending，不显示已到账；app close警告。
11. Stage camera missing/disabled/wrong Viewport/竞争active camera：Grid/Input init调用数0，load cleanup收敛。
12. Load cleanup只跳过未创建资源，不改变DAG中已创建资源的依赖顺序。

## Dependencies

| Dependency | GameRoot 使用方式 | Design state / gate |
|---|---|---|
| Godot 4.7.1 | SceneTree、Viewport、Window lifecycle | engine evidence OPEN |
| Config/Data | battle-ready snapshot、run_seed、`snapshot_id/config_snapshot_id`同义identity | GDD存在；runtime evidence OPEN |
| Stage | typed assembly、Stage-owned Camera2D与battle Viewport identity | Re-review Pending；Camera asset OPEN |
| SpatialGrid | phase/pause/resume/query/teardown | Approved design；integration OPEN |
| Object Pooling | lifecycle/quarantine/resume binding | 第三轮传播修订后 Re-review Pending；integration OPEN |
| InputSystem | movement、pause cancel、choice gate、typed geometry revision | Re-review Pending；integration OPEN |
| RNG | run_seed、service fault | Approved；GATE-G2/G3 design-side CLOSED，runtime OPEN |
| SaveSystem | outcome commit identity、reservation/commit/retry | GDD NOT FOUND；integration BLOCKED |
| SettlementSystem/BattleUI | outcome、pause/fault/unsaved presentation | GDD NOT FOUND；integration BLOCKED |

下游 participant 包括 Player、Enemy、Spawn、Damage、Projectile、Drop、SkillDraft、RiskChoice、Leveling；不得自主编排 phase。跨文档 owner 改动必须同步 registry、owner GDD 与本节 gate，不在 GameRoot 复制内部实现。

## Tuning Knobs

| Setting | Value | Rule |
|---|---:|---|
| `MAX_PAUSE_DRAIN_TICKS` | 1 | 固定安全上限，不可调高掩盖pending泄漏 |
| `pause_pending_lock_feedback` | `IMMEDIATE`（固定） | 进入Pending同一控制迭代立即显示，不等待多帧淡入；离开Pending立即reset |
| `MAX_SUPPRESSED_DIAGNOSTICS` | implementation ADR | 必须在 load 定容；overflow只加counter |
| wallclock p95/p99 | OPEN | 由目标设备 benchmark manifest 冻结，不在设计评审中发明 |

## Acceptance Criteria

所有failure fixture使用稳定row schema：`{fixture_id,injection_point,expected_root_status,expected_top_state,matching_end_count,grid_publish_count,pool_publish_count,authority_revision_delta,resolution_token_delta,rollback_owner,open_lease_count,first_diagnostic,suppressed_count}`。每row独立运行，不以“首/中/末”“逐层”替代注入点。

### A. Lifetime、Scene Flow 与 Loading DAG

**AC-A1 persistent root与合法边**：从BOOT到两次完整run循环，GameRoot identity恰一个；每条R2合法边按独立trace执行，battle child/bank/service每局identity不同，HOME/SETTLEMENT旧battle引用数0。Gate: BLOCKING。

**AC-A2 非法边全集**：由R2显式adjacency表生成状态×event未声明集合；逐边返回WRONG_STATE且ResourceIdentityManifest、revision、pause/Viewport writer ownership不变。Gate: BLOCKING。

**AC-A3 Loading成功与identity E2E**：断言BOOT bootstrap恰一次；R2 DAG顺序；RunStartRequest `{battle_instance_id=B,run_seed=S}`→Config snapshot→RNG/owners/Grid/Pool→authority/resolution headers→outcome均携带对应identity。任一方注入B'/snapshot X'时ACTIVE/Settlement publish=0并记录mismatch owner。Gate: BLOCKING。

**AC-A4 Stage assembly**：合法Stage唯一Camera C且active Viewport匹配；GameRoot register identity=C，对camera create/property write=0。missing/disabled/wrong-parent/wrong-Viewport/second-active-camera逐row使Grid/Input init=0并按DAG cleanup。Gate: BLOCKING。

**AC-A5 Loading failure DAG**：Config/RNG/carrier/Stage/Input/Grid/Pool/owner/preflight/gate分别单row注入；只清理已创建资源，且Grid invalidation先于Pool teardown、UI target接管先于Viewport release、永久资源未消费。Gate: BLOCKING。

**AC-A6 pre-battle fault**：BOOT bootstrap failure与PREP中battle identity发布前failure逐row进入CONTROLLED_FAULT；`RunOutcomeEnvelope/outcome_commit_id/reward reservation/Save attempt`创建数均0，SceneTree pause=false，retry或safe exit不显示战局已保存/奖励到账。Gate: BLOCKING。

### B. Physics and Transaction

**AC-B1 静态单owner**：AST/scene审计唯一persistent GameRoot callbacks、pause/Viewport writer；GameRoot geometry event-source registration=0；participant自主process/input callback=0。脚本不存在前implementation prerequisite OPEN。Gate: BLOCKING before Done。

**AC-B2 七phase与drain trace**：普通/空tick严格七组matching begin/end；drain同样七组但仅allowlist closure计数可非零，fresh borrow/spawn/query/damage/pickup/reward/movement/timer均0，并有普通ACTIVE positive control。Gate: BLOCKING。

**AC-B3 phase-specific failure rows**：对每phase begin/participant/service/end分别注入。当前phase新publish=0、未来phase调用=0；phase 5/6/7 failure分别断言此前Grid/resolution/authority identity保持已提交值，不做整tick rollback。Gate: BLOCKING。

**AC-B4 resolution exact-once bank identity**：A/B bank写不同sentinel；tick T只允许消费token指定bank，effect前consumed token完整匹配；二次consume=0，读取旧/错bank=0；publish failure不生成T token且不能消费T-1。Gate: BLOCKING。

**AC-B5 revision boundary**：初值、空publish、Paused choice publish、failure保持、overflow、跨battle stale token逐row验证R3/F3全部revision轴。Gate: BLOCKING。

### C. Pause、Reason 与 Presentation

**AC-C1 pause/death priority**：同tick pause+death/victory只进入BATTLE_ENDING，choice UI打开数0。Gate: BLOCKING。

**AC-C2 drain零新effect**：进入输入锁定反馈后，HP、position、gameplay timer、spawn/query/damage/pickup/reward/borrow authority counter均不变；只允许预先批准closure计数。ACTIVE positive control必须使对应选定counter变化。Gate: BLOCKING。

**AC-C3 reason queue组合矩阵**：逐项与所有pairwise组合覆盖priority、intent_sequence、presentation、Continue/auto条件；同tick多choice逐个exact-once，manual/background残留时attempt=0。Gate: BLOCKING。

**AC-C4 blocked choice feedback**：首拒绝intent=0且视觉/可访问性反馈恰一次；重复不播，predicate false清除，下一episode可再次播。Gate: BLOCKING。

**AC-C5 geometry owner与background deterministic**：静态证明GameRoot不注册Window/Viewport geometry source；只由Input relay注入typed revision。覆盖new/duplicate/coalesce/foreground/background sequence与expected forward count；真机只作GATE-OQ evidence。Gate: BLOCKING。

**AC-C6 pause truth table**：逐state断言SceneTree pause、setter count/readback、GameRoot/participant `can_process()`；BATTLE_PAUSED/普通Resume保持true，gated尾段false，Fault cleanup完成后false。PAUSABLE gameplay probe与ALWAYS control probe给出正负对照。Gate: BLOCKING。

### D. Resume

**AC-D1 pump与attempt checkpoints**：无玩家输入也每iteration service async fault；逐checkpoint注入input/background/geometry revision，首次publish前rollback，点后收敛fault，ACTIVE开放=0。Gate: BLOCKING。

**AC-D2 prepare failure rows**：Grid prepare、Pool prepare、Grid arm、Pool arm、owner swap逐row注入；old owner恢复、candidate/lease/quarantine=0。Gate: BLOCKING。

**AC-D3 matching publish**：arm后matching Grid/Pool publish均OK；wrong tx保持armed并用保存tx收敛；Node-invalid必须在arm失败，publish阶段Node API调用数0。Gate: BLOCKING。

**AC-D4 point-after failure rows**：两次publish之间、双publish后、cleanup、unpause observer逐row注入；first diagnostic保留root，cleanup错误进suppressed；不恢复old owner。Gate: BLOCKING。

**AC-D5 explicit unpause observer**：ALWAYS Host未收到UNPAUSED仍成功；set_pause(false)返回后GameRoot显式复核。held-only先repause/readback后入drain；fault/invalidation ACTIVE publish=0。Gate: BLOCKING。

**AC-D6 held-drain substate**：点后held时top state始终RESUME_PREPARING、substate=RESUME_HELD_DRAIN、open resource=0、反馈恰一次、pump持续；current-epoch release/cancel后自动尾段retry一次，stale terminal不解锁。Gate: BLOCKING。

### E. Ending、Outcome 与 Save

**AC-E1 immutable envelope**：victory/death/abandoned/technical四类mandatory facts、battle/config/authority identity匹配；teardown后Settlement读取Node次数0，envelope byte-identical且无commit_state。Gate: BLOCKING on producers。

**AC-E2 manual exit**：Active/Paused分别经二次确认latch；safe barrier后ABANDONED、new record=0、open lease=0，误触/取消不结束。Gate: BLOCKING。

**AC-E3 TECHNICAL_ABORT facts与reservation**：奖励只来自committed kills/survival/picked seeds，fault staging不计；reservation补偿以同commit ID retry 3次仍exact-once。Gate: BLOCKING on Save integration。

**AC-E4 normal/fault Save state**：两类outcome逐项注入pending/success/failure/retry/safe-exit；成功前已到账文案=0，同commit并发attempt<=1，success后receipt恰一个。HOME pending与app-close warning按R9。Gate: BLOCKING on Save/BattleUI。

**AC-E5 teardown DAG rows**：Active/Paused/Prepared/Armed/Fault/Ending逐row验证consumer-close、pause/Viewport writer、candidate/lease/quarantine、Grid invalidation→Pool teardown→Grid reset、Stage child removal及幂等重复cleanup；Paused/Resume来源须在input/consumer关闭下`set_pause(false)`并readback后移除battle child，Active fatal须先`set_pause(true)`并readback。Gate: BLOCKING。

### F. Copy、Allocation、Diagnostics 与 Time

**AC-F1a copy completeness**：A/B不同sentinel连续两轮交替；每字段write count=count、tail poison不权威、inactive mutation不影响published，dirty-patch被语义oracle捕获。Gate: BLOCKING。

**AC-F1b forbidden operation static guard**：逐项fixture拒绝Active/Paused中的clear/resize/append_array/duplicate/slice、容器替换与已定义alias pattern；不声称其必然分配。Gate: BLOCKING before Done。

**AC-F1c backing isolation evidence**：使用经ADR/引擎spike确认可观察的identity或mutation isolation方法；无可靠observer=`INCONCLUSIVE`，不得PASS。Gate: BLOCKING before Done。

**AC-F2 steady allocation manifest**：release artifact/hash+observer/version+paired baseline；empty tick、满载七phase、authority copy、spawn/remove churn分别非空运行。allocator events/bytes与container growth/COW delta=0；每个static denylist有fail fixture，observer正控失效=`INCONCLUSIVE`。Gate: BLOCKING before Done。

**AC-F3 diagnostic capacity**：对C与S={0,C-1,C,C+1,C+3}验证F6精确公式、first不变、suppressed顺序、bank identity/size不变与allocator delta=0。Gate: BLOCKING。

**AC-F4 deterministic diagnostics与RNG telemetry**：相同seed/call/injection两次全字段一致；只改变phase/status/api/participant时只对应字段变化；只改变seed时稳定位置字段允许不变但run_seed必须变化。RNG fault行另断言stream_id/call counts/pre-fault state与GATE-G3 capture。Gate: BLOCKING。

**GATE-F5 wallclock evidence**：分别报告orchestration self/E2E、authority copy、clean resume、pre-point rollback、post-point held-drain单次pump、setter-in-flight return-to-drain。设备/threshold未冻结时OPEN，不阻止设计修订但阻止Done/benchmark-ready。

## Open Questions

| ID | 问题 | Owner | 关闭条件 | 当前状态 |
|---|---|---|---|---|
| OQ1 | GameRoot落地为Autoload还是main-scene persistent root？ | Technical Director | ADR-GR-001；行为不得偏离R1 lifetime | OPEN before implementation |
| OQ2 | battle/outcome identity的具体生成与持久化算法？ | Technical Director + Save | ADR-GR-001 + Save ADR；满足不复用与retry稳定 | OPEN/BLOCKED on Save |
| OQ3 | Godot Input callback、Window relay与background/orientation顺序？ | InputSystem | GATE-OQ-INPUT目标平台trace | OPEN |
| OQ4 | Viewport/pause setter同步重入是否满足observer契约？ | GameRoot + Input | GATE-OQ-VIEWPORT hostile harness | OPEN |
| OQ5 | copy、diagnostics、steady tick是否零allocator/growth/COW？ | Performance | GATE-OQ-ALLOC release evidence | OPEN |
| OQ6 | min-spec p95/p99阈值？ | Producer + Performance | 冻结完整manifest并通过GATE-OQ-TIME | OPEN |
| OQ7 | project asset、GDUnit4与静态守卫是否已落地？ | QA | GATE-OQ-STATIC artifacts存在且通过 | OPEN |
| OQ8 | SaveSystem如何跨进程恢复pending commit并保证永久资源原子性？ | SaveSystem | Save GDD + AC-E3/E4 integration trace | BLOCKED on Save GDD |
