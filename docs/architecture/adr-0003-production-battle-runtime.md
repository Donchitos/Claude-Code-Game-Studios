# ADR-0003：正式 BattleScope 采用显式阶段驱动与固定容量运行时

> 2026-09-11后续方向：ADR-0006已选择未来STEAM_SAVE_V2/STEAM_MISSION_V1；新Save/Campaign/Mission合同和owner路由已写，schema/预算/接线未完成。本文记录当前JSON v1与legacy运行适配，不因新ADR自动升级为v2或完整续局。

- **Status**: Accepted for initial production implementation
- **Date**: 2026-09-10
- **Owners**: Technical Director / Gameplay / Input / Battle UI
- **Scope**: 根目录 production Godot project 的首个可运行 battle runtime

## Context

现有 `production/input-vertical-slice` 只证明输入与 persistent-root 契约的局部可执行性，`prototypes/zhangtian-trial-concept` 只回答 75 秒玩法假设。二者都不是正式项目，不能作为 iOS 真机生命周期、触摸、无障碍或性能证据的目标。

## Decision

根目录 `project.godot` 是正式项目，唯一 main scene 为 `res://src/core/GameRoot.tscn`。GameRoot 持续拥有 root Viewport gate、SceneTree pause writer 和唯一 `_physics_process`；HOME、BattleScope 与 Settlement 都是可替换 child。

每局 BattleScope 独占 StageRuntime、PlayerController、InputSystem、VirtualJoystickHost 和 BattleUI。BattleScope 及其参与者不注册自主 process callback，而由 GameRoot 按 `MOVEMENT_COMMIT → PLAYER_MOVE → STAGE_SIMULATE → PRESENTATION` 的顺序显式调用。敌人、飞剑与经验物采用配置容量的一次性 PackedArray 预分配，容量耗尽时丢弃新增对象并记录计数，不在 hot path 扩容。敌人数值继续使用紧凑 SoA，但每个活动敌人同时借用预创建 Node identity 并绑定稀疏 SpatialGrid handle；自动索敌读取 Grid nearest，死亡与 teardown 固定按 `Grid remove → Pool unbind → Pool release` 收敛。

正式战斗配置从 `res://assets/config/production_defaults.json` 注入；原型和 harness 目录通过各自 `.gdignore` 与根项目隔离，继续保留其历史证据身份。persistent GameRoot 另持有 SaveSystem 与 ProgressionSystem：Steam 运行使用双槽本地档案、payload SHA-256 和写后读回，结算在同一profile写入中提交纪录与Progression after-image；headless按DisplayServer使用内存档，避免污染玩家数据。ProgressionSystem独占90秒里程碑收入、统一残页钱包、三支五级购买与下一局投影语义，Save只替换其传入的opaque domain。

## Consequences

### 2026-09-11 几何批量绘制 checkpoint

普通敌人与友方飞剑采用固定容量MultiMesh几何批次；甲虫/召唤物与狼通过同一mesh的instance custom类型选择保持原数组顺序，飞剑按正式velocity旋转。可见范围剔除在实例提交前执行。Boss存在时敌人自动退回原Canvas primitive路径，以保留Boss血条与敌人遮挡顺序；友方飞剑继续批量绘制。生产开关由`rendering.geometry_batch_enabled`注入，false路径保留给A/B验证。

该方案不使用预渲染纹理。旋转/缩放专项逐像素一致；正式Stage三种319敌/392飞剑布局最大通道差1、差值大于1的像素为0。Apple M4图形复测中普通/容量/Boss/屏内密集容量场景帧间隔P95分别为13.862/10.398/13.912/14.753ms；这只关闭当前Mac基线P95，不转移为Windows、min-spec或长时P99证据。详情见`production/playtest-evidence/2026-09-11-batched-renderer-production.md`。

2026-09-10调参/协议补充：Stage现在先收集普通碰撞最大值与Boss攻击总额，再一次提交Player HP/致命/长春恢复；碰撞冷却只影响普通接触。飞剑使用连续扫掠最早接触，扇形采用圆弧与边距离。T+1毒弹验证source handle/action generation；Boss召唤已从固定两点改为48-word、8候选/child的局部环采样，容量与候选失败均0或2并保持RNG消费，异常插入回滚。完整Config epoch/typed ABI/归因/hazard协议尚未完成。普通血量策略模拟、临时练习入口与真实渲染截图见`production/playtest-evidence/2026-09-10-combat-tuning.md`；移速上限600为待玩家验证的暂定参数。

### 2026-09-10 长局接入 checkpoint（取代下方75秒与隔离Boss现状描述）

默认内容现为8段敌潮，覆盖0–720秒，交替压力段与缓冲段；720秒停止普通刷怪并从玩家右侧视野外生成唯一Boss，预留一个敌人位置。900秒为失败上限，Boss死亡优先判胜。BattleScope按60 Hz提交Active tick，残页读取completed_active_ticks；90秒收入已可通过实际运行到达。

BossCombat作为当前Stage敌人适配层执行312/444 tick动作轮转、入场/转场、扑咬、扇毒、T+1八弹、二阶段双召唤与毒域。敌人统一使用Pool/Grid；普通敌人2200px外无奖励回收。当前400 projectile容量拆为392友方+8首领毒弹。现有像素世界按60px/unit解释Boss几何；这些为可运行初始参数，尚未经平衡试玩。

验证入口新增`tests/integration/long_run_test.gd`和`boss_combat_test.gd`：真实90秒奖励/保存、43200边界、暂停、飞剑击杀、8页结算、超时失败，以及312/444动作时序。完整烟测可用`--headless --fixed-fps 60 --path . -- --production-smoke`加速执行，包含高HP与自动走位，不代表玩家生存或性能验证。

剩余：统一Damage/Projectile typed ABI、Boss/Spawn完整身份与候选/RNG协议、召唤48-word采样、完整危险快照、四方向入场选择、正式美术音频与可读性评审。当前召唤采用两个固定相对位置与净空检查，毒弹使用Stage固定数组；不能视为这些正式GDD的完整实现。

- GameRoot replacement 只销毁 battle child，并在重新挂载前等待 frame-end barrier；root 与 root Viewport identity 不变。
- 正式战斗包含移动、自动飞剑、三段刷怪、掉落拾取、升级暂停选择和胜负结算，不依赖 harness mock。
- 当前 Grid/Pool 接线只覆盖敌人 identity、最近目标查询与死亡回收；Projectile/Drop 宽相查询、完整 phase lease、pause quarantine 与 resume transaction 仍是开放门。
- 当前 Progression 已覆盖收入、购买、钱包守恒、持久after-image与投影生成；Home提供余额、三支等级与二次确认购买。下一局已消费青元attack、长春max HP/L5一次恢复及大衍pickup投影；暴击、青元L5穿透与大衍L5刷新仍分别等待Damage/Projectile/SkillDraft owner。同步Save失败可显示失败但尚无UNCERTAIN/reconcile状态机。
- 当前75秒正式切片短于首个90秒残页里程碑，因此生产玩法中尚不可自然获得残页；不得把测试注资购买路径解释为可达经济闭环。
- 当前 Boss 只有隔离FSM核心：12:00调度、arrival/phase/fog/ring/lethal时序有本地测试，但尚未接入Enemy identity、Projectile/Damage/Spawn/BATTLE_RULES，也未把正式战斗从75秒迁移到长局内容。
- 当前 Save 是双槽 JSON 基础实现，不等于 `save-system.md` 冻结的完整 binary codec、reservation、process-kill reconcile 或完整多domain事务协议。
- `--production-smoke` 只改变时间倍率和输入来源，仍执行相同的正式 battle components；它是本地运行证据，不是设备性能或玩家体验结论。
- iOS 导出、真机 touch trace、VoiceOver 和 thermal/performance 必须在本地生命周期验证之后分别取证；本 ADR 不授予 `Approved` 或 `battle_ready`。

## Verification

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/production_lifecycle_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/production_battle_loop_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/spatial_grid_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/object_pool_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/integration/batched_renderer_visual_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/integration/dense_batch_probe.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/integration/performance_probe.gd -- --dense
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/save_system_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/progression_system_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/home_progression_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/boss_state_machine_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -- --production-smoke
```

第一条必须证明 GameRoot/Viewport identity 跨 battle replacement 和 settlement 保持不变，旧 battle scope 在 frame barrier 后失效。第二条必须完成 75 秒三段敌潮并到达 Settlement。
