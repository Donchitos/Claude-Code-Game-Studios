# ADR-0003：正式 BattleScope 采用显式阶段驱动与固定容量运行时

- **Status**: Accepted for initial production implementation
- **Date**: 2026-09-10
- **Owners**: Technical Director / Gameplay / Input / Battle UI
- **Scope**: 根目录 production Godot project 的首个可运行 battle runtime

## Context

现有 `production/input-vertical-slice` 只证明输入与 persistent-root 契约的局部可执行性，`prototypes/zhangtian-trial-concept` 只回答 75 秒玩法假设。二者都不是正式项目，不能作为 iOS 真机生命周期、触摸、无障碍或性能证据的目标。

## Decision

根目录 `project.godot` 是正式项目，唯一 main scene 为 `res://src/core/GameRoot.tscn`。GameRoot 持续拥有 root Viewport gate、SceneTree pause writer 和唯一 `_physics_process`；HOME、BattleScope 与 Settlement 都是可替换 child。

每局 BattleScope 独占 StageRuntime、PlayerController、InputSystem、VirtualJoystickHost 和 BattleUI。BattleScope 及其参与者不注册自主 process callback，而由 GameRoot 按 `MOVEMENT_COMMIT → PLAYER_MOVE → STAGE_SIMULATE → PRESENTATION` 的顺序显式调用。敌人、飞剑与经验物采用配置容量的一次性 PackedArray 预分配，容量耗尽时丢弃新增对象并记录计数，不在 hot path 扩容。

正式战斗配置从 `res://assets/config/production_defaults.json` 注入；原型和 harness 目录通过各自 `.gdignore` 与根项目隔离，继续保留其历史证据身份。

## Consequences

- GameRoot replacement 只销毁 battle child，并在重新挂载前等待 frame-end barrier；root 与 root Viewport identity 不变。
- 正式战斗包含移动、自动飞剑、三段刷怪、掉落拾取、升级暂停选择和胜负结算，不依赖 harness mock。
- `--production-smoke` 只改变时间倍率和输入来源，仍执行相同的正式 battle components；它是本地运行证据，不是设备性能或玩家体验结论。
- iOS 导出、真机 touch trace、VoiceOver 和 thermal/performance 必须在本地生命周期验证之后分别取证；本 ADR 不授予 `Approved` 或 `battle_ready`。

## Verification

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/production_lifecycle_test.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -- --production-smoke
```

第一条必须证明 GameRoot/Viewport identity 跨 battle replacement 和 settlement 保持不变，旧 battle scope 在 frame barrier 后失效。第二条必须完成 75 秒三段敌潮并到达 Settlement。

