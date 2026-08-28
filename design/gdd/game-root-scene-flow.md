# GameRoot & Scene Flow（全局根与场景流）

> **Status**: Re-review Pending — 第三轮 full design-review（NEEDS REVISION）全部 BLOCKING 已聚焦修订，待第四轮独立复审
> **Author**: 用户 + Codex
> **Created**: 2026-08-19
> **Last Updated**: 2026-08-28 — 第三轮复审后修订；不代表 runtime、performance 或 evidence gate 已通过
> **Implements Pillar**: 战斗—暂停选择—结算—再开局的可靠闭环
> **Scope**: MVP minimum；不定义各玩法系统内部规则
> **Review Mode**: full；InputSystem 内部 FSM 以 `input-system.md` 为唯一权威

## Overview

GameRoot 是唯一场景流控制器与 gameplay physics phase 编排者。它负责洞府、准备、战斗、暂停选择、结算与受控故障之间的合法转换；显式调用固定 participant 表，持有本局 authority/resolution 双 bank，并协调 SpatialGrid、Object Pooling、InputSystem、RNG 与持久化边界。它不计算伤害、不生成敌人、不选择技能，也不替依赖系统拥有内部状态机。

## Player Fantasy

玩家应感觉进入试炼、暂停选择、恢复和结算都干净、即时、可信。暂停请求在安全 barrier 进入 `PAUSE_PENDING` 并显示输入已锁定后，玩家不再受到新伤害；已经在此前合法 phase 提交的效果不会被伪造回滚。技术故障不会伪装成战败，也不会谎报奖励已经到账。

## Detailed Rules

### R1 — 单一 owner 与公开边界

- GameRoot 精确使用 `PROCESS_MODE_ALWAYS`：`_physics_process(delta)` 只驱动允许的技术 tick，`_process(delta)` 只驱动 Paused/Resume control pump。participant 不得定义自主 gameplay `_physics_process/_process/_input/_unhandled_input`。
- participant 在 BATTLE_LOADING 按稳定表注册，Active 后不可增删或重排；公开调用为 `run_phase(phase,context,lease_id)->int status`。GameRoot 独占 SpatialGrid `begin_phase/end_phase`，lease 不得跨同步调用栈缓存。
- InputSystem 的 callback ABI、gesture/shield bank、三字段 tuple、geometry rebuild 和内部状态迁移只由 `design/gdd/input-system.md` 定义。GameRoot 只依赖公开 API、primitive status 与可观察后置条件。
- GameRoot 是目标 battle Viewport `gui_disable_input` 的唯一项目 writer；正确 setter 为 `set_disable_input(bool)`。固定激活序列为 `PRE_ACQUIRE→SET_TRUE_IN_FLIGHT→GATE_HELD→Input ACTIVE publish→GameRoot local commit→reasoned release`。
- `SceneTree.set_pause(false)` 返回后由 GameRoot 显式执行 post-unpause observer；不得等待 `PROCESS_MODE_ALWAYS` 的 Host/shield/VJ 收到 `NOTIFICATION_UNPAUSED`。
- Window size、safe-area、orientation 到 `INPUT_GEOMETRY_CHANGED` revision 的采集/relay 归 InputSystem；GameRoot只消费 typed revision，不镜像其事件源实现。

### R2 — 顶层状态与加载

| State | 玩家可见页面 | 权威行为 |
|---|---|---|
| `BOOT` | 启动遮罩 | 装载最小配置/存档 |
| `HOME` | 洞府 | 打开局外入口 |
| `PREP` | 开局准备 | 创建 immutable `RunStartRequest`，含本局 `run_seed` |
| `BATTLE_LOADING` | 加载遮罩 | 构建 battle-ready snapshot、预分配、初始化依赖 |
| `BATTLE_ACTIVE` | 战斗页 | 执行完整七 phase tick |
| `PAUSE_PENDING` | 战斗画面+输入锁定反馈 | 最多一个零 gameplay-dt drain tick |
| `BATTLE_PAUSED` | 原因对应的暂停/选择层 | gameplay frozen，可读 frozen snapshot |
| `RESUME_PREPARING` | 保持暂停层 | prepare→arm→publish 与显式 observer |
| `BATTLE_ENDING` | 输入锁定 | 安全 teardown，生成 normal/abandoned outcome |
| `SETTLEMENT` | 结算页 | 只消费 immutable `RunOutcome` |
| `CONTROLLED_FAULT` | 技术故障层 | 禁止 fault tick 新效果；尝试提交 fault 前事实派生的补偿 |

合法主路径：`BOOT→HOME→PREP→BATTLE_LOADING→BATTLE_ACTIVE↔PAUSE_PENDING/BATTLE_PAUSED/RESUME_PREPARING→BATTLE_ENDING→SETTLEMENT→HOME/PREP`。非法边返回 `WRONG_STATE`、保持资源引用不变。

BATTLE_LOADING 固定顺序：`Config build(battle_ready, RunStartRequest.run_seed)→RNG init(snapshot.run_seed)→按同一 snapshot ID 预分配 carriers/banks→Input init→SpatialGrid init→Pool init→owners warmup→owner/Grid/Pool snapshot ID 一致性预检→Viewport gate acquire→Input ACTIVE publish→GameRoot local commit→ACTIVATION_SUCCESS release`。任一步失败都保持 consumer/input 关闭并逆序 cleanup。

### R3 — Authority、resolution 与 exact-once token

- BATTLE_LOADING 预分配两个等容量 `BattleAuthorityBundle` 与两个 `ResolutionStagingBank`。published bank 在 phase 内只读；inactive bank 承接完整 copy 与 mutation；发布是 O(1) 引用交换。
- `AuthorityCopyManifest` 枚举每个 primitive SoA 字段及其独立 authoritative count。A/B carrier 在 load 时预 resize 到最大长度并保持独占 backing；Active/Paused 路径禁止 `clear/resize/append_array/duplicate/slice`、共享 COW alias、容器替换和 dirty-patch。每字段逐 index 复制 `[0,count)`，tail 非权威。
- Resolution publish 写唯一正 `published_tick_revision`。DEFERRED_REMOVAL 仅当 `published_tick_revision==current_tick && consumed_tick_revision!=current_tick` 时消费；消费开始前原子写 `consumed_tick_revision=current_tick`。failure 不生成新 token，不得重放旧 bank。
- diagnostic 使用预分配 `FailureDiagnosticBank`：1 个 first-failure 槽、固定 `MAX_SUPPRESSED_DIAGNOSTICS` 槽与 `suppressed_overflow_count`。热路径只写 primitive 字段，字符串格式化延迟到 gameplay 停止后。

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

每 phase 固定 `begin→stable participants→service has_fault→matching end`。只有全部 status 属于 success class、matching end=`OK` 且 service 无 fault 才进入下一 phase。`PENDING_WORK` 只允许来自 pause barrier。

### R5 — Failure、rollback 与不可逆点

- query/resolve/fatal narrowphase failure 丢弃整个 query transaction；published bank不变，普通 no-hit 仍是 success。
- first failure 保存 `{status,api,participant,phase,tick,snapshot}`；cleanup failure写入预定容 suppressed bank，不覆盖根因。
- pause/resume 中所有可失败 Grid/Pool/owner validation 必须在 arm 完成。第一次 matching publish 调用是不可逆点；matching Grid publish 与 Pool publish 均必须不可失败并用正确 tx 收敛。
- 点前 failure 恢复 old owner、abort candidates、关闭 lease；点后异常完成尚未完成的 matching publish/lease/quarantine cleanup，再进入 `CONTROLLED_FAULT`，禁止伪造双向 rollback。

### R6 — Pause intent、玩家反馈与原因映射

pause source 固定为 `MANUAL/LEVEL_UP/TREASURE_CHOICE/RISK_CHOICE/APP_BACKGROUND/INPUT_GEOMETRY_CHANGED`。优先级仅决定展示顺序：`BLOCKING_CHOICE>APP_BACKGROUND>INPUT_GEOMETRY_CHANGED>MANUAL`；battle-end intent 高于全部 pause intent。

barrier 顺序为 `collect/sort intent→Input cancel→Grid request_pause→matching end→Pool quarantine→Input FROZEN publish→BATTLE_PAUSED`。`PENDING_WORK` 允许恰一个零 gameplay-dt drain tick；进入 `PAUSE_PENDING` 并发出输入锁定反馈后，不再创建 damage/query/spawn gameplay effect。

| Reason | 标题/短提示 | Continue |
|---|---|---|
| `MANUAL` | “试炼暂停” | 必须 |
| `LEVEL_UP` | “境界提升：选择一项” | choice 完成后自动 |
| `TREASURE_CHOICE` | “法宝机缘：选择一项” | choice 完成后自动 |
| `RISK_CHOICE` | “机缘抉择：选择一项” | choice 完成后自动 |
| `APP_BACKGROUND` | “已安全暂停，准备好后继续” | 每个最新 background revision 必须确认 |
| `INPUT_GEOMETRY_CHANGED` | “界面已调整” | 无 manual/background 时自动 |

每次 choice press 前读取 `is_choice_input_blocked()`。若 press 被拒绝，必须保持 intent=0，并对本次 blocked episode 首个被拒绝 press 显示一次“请先松开移动手指”；后续拒绝不重复播报，predicate 恢复 false 时清除。

### R7 — Paused mutation 与 resume

- `PAUSE_READ` 只读 lease 必须 matching end，且不得与 `RESUME_EXCLUSIVE` 重叠。choice mutation只写 inactive authority bank，frozen/removed Node保持 quarantine。
- `resume_requested_latched` 是幂等 bool；APP_BACKGROUND 另使用 monotonic `required_revision/acked_revision`，新 revision 必须重新确认。
- resume 前置 gate：service pending fault、choice/held predicate false、background revision matched、Input clean、owner/Grid/Pool `config_snapshot_id` 全相等。
- 固定事务：`capture revisions→Input RESUME_LOCKED/cancel→optional rebuild→Grid resume_from→Pool prepare→Grid arm→Pool arm(含最后 Node identity/capacity check)→owner swap→matching Grid publish→matching Pool publish→end/quarantine cleanup→Viewport PRE_ACQUIRE/SET_TRUE_IN_FLIGHT/GATE_HELD→set_pause(false) return→GameRoot explicit post-unpause observer→Input ACTIVE→GameRoot ACTIVE→ACTIVATION_SUCCESS release`。
- held touch 在不可逆点前走 fault-free abort/close/FROZEN；点后完成 publish/cleanup 后进入 `RESUME_HELD_DRAIN`，terminal 后只重跑 ACTIVE 尾段，不重跑 Grid/Pool transaction。

### R8 — Battle end 与 `RunOutcome`

victory、death、manual exit 只 latch `battle_end_intent`，在安全 barrier 后进入 BATTLE_ENDING；manual exit 固定 `outcome_kind=ABANDONED`。

GameRoot 在 teardown 前发布 immutable、versioned `RunOutcomeEnvelope`：

`{schema_version,outcome_kind,run_seed,config_snapshot_id,authority_revision,survival_ticks,committed_kill_counts,level,skill_damage_totals,damage_received_by_source,risk_choice_results,reward_source_facts,new_record_candidates,technical_failure_ref,commit_state}`。

GameRoot拥有 envelope、source revision 与 producer completeness；各 gameplay owner提供其字段；Settlement/Save 拥有展示与持久化 schema。缺 mandatory producer 时不得 teardown 后猜测重建，story保持 BLOCKED。

### R9 — ControlledGameplayFault 与持久化

- `TECHNICAL_ABORT` 不写胜负、死亡原因、纪录或教程完成度；禁止 fault tick 未提交 staging 进入奖励。
- 部分奖励来源固定：灵石=已提交击杀事实；功法残页=已提交存活 tick；种子=仅 fault 前已拾取数量，未拾取为0。开局灵药消耗通过同一 reservation/commit 补偿。
- fault UI 状态为 `SAVE_PENDING/SAVE_SUCCEEDED/SAVE_FAILED`：pending 显示“正在保存异常前进度…”；成功后才显示“异常前进度已保存”；失败显示“进度保存失败，请重试或安全退出”。不得在 commit 前声称奖励已到账。
- SaveSystem GDD 未完成前，接口与状态机可冻结，但任何永久资源 integration story 保持 BLOCKED。

### R10 — Engine/Performance Evidence Gates

| Gate | Owner | Artifact / pass condition | Failure contingency |
|---|---|---|---|
| `GATE-OQ-INPUT` | InputSystem | Godot 4.7.1 callback/Window relay trace；真实 background/safe-area/orientation | 修订 Input GDD/relay，不由 GameRoot镜像 workaround |
| `GATE-OQ-VIEWPORT` | GameRoot+Input | `set_disable_input`重入与 reasoned release trace | redesign activation observer |
| `GATE-OQ-ALLOC` | Performance | release allocator events/bytes、container growth/COW counters及 positive controls | story不得标 Done |
| `GATE-OQ-TIME` | Producer+Performance | 指定 min-spec、artifact、workload、warmup/sample、p95/p99；覆盖 orchestration self/E2E、authority copy、clean resume、held iteration | 保持 OPEN，不发明阈值 |
| `GATE-OQ-STATIC` | QA | `project.godot`、GDUnit4、`tools/ci/static_guard_check.py` 实际存在且通过 | implementation-ready=false |

## Formulas

### F1 — Transaction commit

`transaction_success = all(status(ci) in allowed_success(ci)) AND matching_end==OK AND no_service_fault`

success 时交换 inactive→published；failure 时 published identity/revision不变，inactive 丢弃。

### F2 — Pause drain

`extra_pause_drain_ticks in {0,1}`；`gameplay_dt=physics_dt` 仅当普通 BATTLE_ACTIVE tick，否则为0。

### F3 — Tick/revision

- init pair=`(tick=1,SPAWN_INTENT)`，snapshot revision=0；
- matching barrier end checked 生成 `(tick+1,SPAWN_INTENT)`；
- pause/resume不额外增加 tick，matching resume publish推进 snapshot；
- overflow=`ID_EXHAUSTED`，不回绕。

### F4 — Pause priority

`BATTLE_END > BLOCKING_CHOICE > APP_BACKGROUND > INPUT_GEOMETRY_CHANGED > MANUAL`。

### F5 — Runtime metrics

性能结果必须记录 `{artifact_id,device_manifest,workload_id,warmup_samples,measured_samples,p50,p95,p99,max,allocator_events,allocator_bytes}`。阈值由 producer 在目标设备确定前保持 `OPEN`；任何 desktop spike 只能标 `SPIKE_ONLY`。

## Edge Cases

1. pause 与 death/victory 同 tick：battle-end 优先，不展示 choice UI。
2. 最后一个 consumer failure：较早 staging 一并丢弃。
3. narrowphase no-hit：transaction继续。
4. drain 后仍 `PENDING_WORK`：ControlledGameplayFault。
5. manual exit 在 Active：只 latch，安全 barrier 后生成 ABANDONED。
6. background 无 terminal：Input revision preflight 后才允许 pause/resume。
7. owner swap点前失败：恢复old owner并abort；点后禁止恢复old owner。
8. fault UI spam：只启动一次 HOME cleanup/保存操作。
9. Save commit失败：保持fault层，不显示已保存。
10. duplicate resolution consume：`consumed_tick_revision`阻止第二次应用。

## Dependencies

| Dependency | GameRoot 使用方式 | Design state / gate |
|---|---|---|
| Godot 4.7.1 | SceneTree、Viewport、Window lifecycle | engine evidence OPEN |
| Config/Data | battle-ready snapshot、run_seed、snapshot ID | GDD存在；runtime evidence OPEN |
| Stage | Stage GDD/scene 持有固定 Camera2D 的规格、identity 与一屏全显22×40契约；GameRoot只在BATTLE_LOADING scene assembly中注册/注入该Stage-owned实例，不拥有或重定义camera内部配置 | GDD存在；Camera asset OPEN |
| SpatialGrid | phase/pause/resume/query/teardown | Approved design；integration OPEN |
| Object Pooling | lifecycle/quarantine/resume binding | 第三轮传播修订后 Re-review Pending；integration OPEN |
| InputSystem | movement、pause cancel、choice gate、geometry revision | 第三轮传播修订后 Re-review Pending；integration OPEN |
| RNG | run_seed、service fault | Approved design；Config GATE-G2待同步 |
| SaveSystem | reservation/commit、RunOutcome persistence | GDD NOT FOUND；integration BLOCKED |
| SettlementSystem/BattleUI | outcome展示、pause/fault presentation | GDD NOT FOUND；integration BLOCKED |

下游 participant 包括 Player、Enemy、Spawn、Damage、Projectile、Drop、SkillDraft、RiskChoice、Leveling；不得自主编排 phase。跨文档 owner 改动必须同步 registry、owner GDD 与本节 gate，不在 GameRoot 复制内部实现。

## Tuning Knobs

| Setting | Value | Rule |
|---|---:|---|
| `MAX_PAUSE_DRAIN_TICKS` | 1 | 固定安全上限 |
| `show_pause_pending_overlay_after_frames` | 3 | 低于阈值不闪烁；达到阈值淡入 |
| `MAX_SUPPRESSED_DIAGNOSTICS` | implementation ADR | 必须在 load 定容；overflow只加counter |
| wallclock p95/p99 | OPEN | 由目标设备 benchmark manifest 冻结，不在设计评审中发明 |

## Acceptance Criteria

### A. Scene Flow

**AC-A1 合法主循环**：状态矩阵逐边执行合法主路径；每态一次、input只在ACTIVE开放、Settlement只收到一个 envelope。Gate: BLOCKING。

**AC-A2 非法边全集**：对状态枚举笛卡尔积中所有未声明边注入一次，全部返回WRONG_STATE且资源引用不变。Gate: BLOCKING。

**AC-A3 Loading成功顺序**：spy断言R2固定顺序、单snapshot/run_seed、fresh press仅在reasoned release后可达。Gate: BLOCKING。

**AC-A4 Loading逐层失败**：Config/RNG/carrier/Input/Grid/Pool/owner/snapshot-ID/gate逐层注入；consumer保持关闭、逆序cleanup、永久资源未消费。Gate: BLOCKING。

### B. Physics and Transaction

**AC-B1 静态单owner**：AST审计唯一GameRoot callbacks、participant无自主process/input callback；理由是架构单owner，不声称Viewport gate会继续派发input。Gate: BLOCKING；脚本不存在前 implementation prerequisite OPEN。

**AC-B2 七phase trace**：首tick/普通/空/drain各自严格七组matching begin/end，无participant自主开lease。Gate: BLOCKING。

**AC-B3 phase failure**：每phase首/中/末注入failure；matching cleanup一次、后续participant/phase为0、published bank不变。Gate: BLOCKING。

**AC-B4 resolution exact-once**：同tick二次consume只首次应用；failure不重放上一ticktoken；revision overflow fault。Gate: BLOCKING。

### C. Pause and Presentation

**AC-C1 pause/death priority**：同tick pause+death/victory只进入BATTLE_ENDING，choice UI打开数0。Gate: BLOCKING。

**AC-C2 drain保护**：首次PENDING只允许一个零gameplay-dt drain；进入输入锁定反馈后HP权威值不再下降；正常ACTIVE damage positive control必须下降。Gate: BLOCKING。

**AC-C3 reason presentation**：R6每行逐项断言标题、Continue要求、自动/手动恢复与可访问性播报，组合按优先级只展示一个权威原因。Gate: BLOCKING。

**AC-C4 blocked choice feedback**：blocked episode首个拒绝press→intent=0且反馈恰一次；重复press不重复；predicate false后清除；下一episode可再次显示。Gate: BLOCKING。

**AC-C5 background deterministic**：使用 injected lifecycle/geometry adapter 覆盖新revision、duplicate、coalesce、无terminal与foreground；真机只作GATE-OQ evidence，不作为逻辑AC唯一输入。Gate: BLOCKING。

### D. Resume

**AC-D1 resume preflight**：choice/held/revision/Input clean/snapshot-ID逐项失败时 attempt=0、consumer closed。Gate: BLOCKING。

**AC-D2 prepare failure**：Grid prepare、Pool prepare、Grid arm、Pool arm、owner swap逐项注入；恢复old owner、candidate/lease/quarantine归零。Gate: BLOCKING。

**AC-D3 matching publish**：arm已通过后Grid/Pool matching publish均OK；Pool Node-invalid negative fixture必须在arm失败，publish阶段不得返回可恢复failure。Gate: BLOCKING。

**AC-D4 point-after failure**：首次publish后注入invalidation/wrong tx/cleanup failure；用保存tx完成收敛后fault，不恢复old owner。Gate: BLOCKING。

**AC-D5 explicit post-unpause observer**：ALWAYS Host不接收UNPAUSED仍可成功；`set_pause(false)`返回后GameRoot显式复核。observer污染则重新pause并fault/held-drain，ACTIVE publish=0。Gate: BLOCKING。

**AC-D6 held touch**：点前held无fault rollback；点后held只进入无open-resource drain，terminal后不重跑Grid/Pool。Gate: BLOCKING。

### E. Ending, Outcome and Fault

**AC-E1 victory/death envelope**：mandatory producer字段齐全、revision匹配、teardown后Settlement无需读取battle node。Gate: BLOCKING on producers。

**AC-E2 manual exit latch**：Active任一phase注入manual exit，只在safe barrier进入Ending，outcome=ABANDONED，open lease=0。Gate: BLOCKING。

**AC-E3 TECHNICAL_ABORT sources**：灵石只来自committed kills、残页只来自committed survival、种子只来自picked count；未拾取种子=0；fault tick staging不计。Gate: BLOCKING on Save integration。

**AC-E4 fault save UI**：pending/success/failure三态逐项注入；commit前“已保存/已结算”出现数0，spam只触发一次操作。Gate: BLOCKING on Save/BattleUI。

**AC-E5 teardown state matrix**：Active/Paused/Prepared/Armed/Fault/Ending逐态独立验证consumer-close、terminal commit、candidate/lease清零与旧handle/borrow stale。Gate: BLOCKING。

### F. Allocation, Diagnostics and Time

**AC-F1 authority copy manifest**：每字段写数=该字段count，A/B backing distinct，tail非权威；dirty-patch、clear+append、resize与shared-alias COW各自positive control触发allocator/container-growth failure。Gate: BLOCKING before Done。

**AC-F2 steady tick allocation**：release workload下allocator events/bytes=0、container create/resize/COW=0；带参signal/Dictionary/string dynamic dispatch分别用静态审计和独立positive control，不使用未定义`variant_box_events`做代理。Gate: BLOCKING before Done。

**AC-F3 fault diagnostic capacity**：first+suppressed超过capacity时不扩容，只增加overflow counter；cleanup allocation positive control可被检测。Gate: BLOCKING。

**AC-F4 deterministic diagnostics**：每个 injection row 冻结 expected `{state,tick,phase,status,api}`；改变seed/调用序列的negative control必须改变对应输出，防常量telemetry假通过。Gate: BLOCKING。

**GATE-F5 wallclock evidence**：按F5分别报告 orchestration self/E2E、authority copy、clean resume与full-held iteration的p95/p99；设备/threshold未冻结时保持OPEN，不阻止本次文档修订但阻止implementation Done/benchmark-ready。

## Open Questions

| ID | 问题 | Owner | 关闭条件 | 当前状态 |
|---|---|---|---|---|
| OQ1 | Godot 4.7.1 Input callback、Window geometry relay 与真实 background/orientation 顺序是否满足契约？ | InputSystem | `GATE-OQ-INPUT` artifact + 目标 Android/iOS trace | OPEN |
| OQ2 | Viewport gate setter 的同步重入与三种 reasoned release 是否覆盖真实引擎路径？ | GameRoot + Input | `GATE-OQ-VIEWPORT` hostile harness | OPEN |
| OQ3 | Authority copy、diagnostics 与 steady tick 是否真正零 allocator event/container growth/COW？ | Performance | `GATE-OQ-ALLOC` release trace + positive controls | OPEN |
| OQ4 | orchestration/resume 的 min-spec p95/p99 阈值是多少？ | Producer + Performance | 冻结设备、artifact、workload、样本与阈值后通过 `GATE-OQ-TIME` | OPEN |
| OQ5 | project asset、GDUnit4 与静态守卫是否已落地？ | QA | `GATE-OQ-STATIC` 全部 artifact 存在且通过 | OPEN |
| OQ6 | SaveSystem 对 `RunOutcomeEnvelope` 的幂等 commit、retry 与永久资源原子性如何实现？ | SaveSystem | Save GDD + AC-E1/E3/E4 integration trace | BLOCKED on Save GDD |
