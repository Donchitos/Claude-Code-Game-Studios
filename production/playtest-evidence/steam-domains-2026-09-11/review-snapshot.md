# 独立 Snapshot Code/Engine Review — 2026-09-11

## 当前独立复核 — 最后一轮已报问题验证

Current Verdict: **APPROVED（限本次已报问题整改及 LEGACY_STAGE_PC_V1 adapter）**。

按明确复核范围，仅重新审查此前报告的三个剩余问题及其修复，没有扩大审查范围。未发现本轮整改仍开放的 P1/P2；不代表穷尽所有非法状态。

- `_bounded_motion` 在长度运算前先验证速度分量，再按冻结配置检查 friendly/pending 与 hostile 速度，阻止有限 float32 极端速度进入会溢出的 Vector2 几何计算；damage匹配冻结构筑的float32值。
- Boss enabled 且 completed tick≥43200 时，无Boss快照整体拒绝。
- spawn/attack timer按当前固定tick实现的上/下界验证；attack允许合法负值，未简单错误限制为非负。
- 已报 player位置域、next ID、免费升级/非法构筑、初始化FSM与receipt溢出反例继续被拒绝。

独立运行结果（Godot 4.7.1.stable.official.a13da4feb）：

| 检查 | 当前结果 |
|---|---|
| steam_snapshot_test.gd | 764 checks / 0 failures |
| steam_snapshot_capacity_test.gd | 1905 checks / 0 failures |
| 原始6项review probe | 全部validate=INVALID；restore请求均未成功 |
| 后续3项review probe | projectile_velocity / late_missing_boss / spawn_timer 全部validate=INVALID且restore=INVALID |
| git diff --check | PASS |

原probe在restore拒绝后仍尝试推进fresh CREATED scope，日志中的next20ticks=false是预期WRONG_STATE副结果，不能误读成接受非法快照后的故障。

容量测试的五种构造样本仍是具体legacy容量压力与恢复一致性证据，`natural_reachability_proven=false`、`commercial_budget_frozen=false`保留；不能称完整Steam商业预算、自然可达最大值、Windows持久存档验证或完整Mission/SkillDraft/Preparation恢复。

历史首轮 Verdict: **CHANGES REQUIRED**（以下发现现已完成修复，当前 verdict 见顶部）。仅审核 `LEGACY_STAGE_PC_V1` adapter；不修改实现。依据仓库 code-review Phase 7，重新读取 snapshot/wire 与当前 Stage/BattleScope/Boss/Player 实现，独立运行 Godot 4.7.1.stable.official.a13da4feb 探针。

## 已独立重跑

- `tests/integration/steam_snapshot_test.gd`: **760 checks / 0 failures**。
- `tests/integration/steam_snapshot_capacity_test.gd`: **1905 checks / 0 failures**。五种 full/ring/summon/bite/phase_pending 构造压力状态的 roundtrip 与随后 50 tick 比较通过。
- 上次 `/tmp/steam_snapshot_review_probe.gd` 六反例现在全部 validate=INVALID：next ID=0、越域 Player、tick0 免费升级、无 Boss 的 phase2、level1 百万剑、receipt=I64_MAX。
- `git diff --check`: PASS。

这些运行验证了具体构造样本；未证明自然游玩可同时达到所有填表状态，不是商业最大合法快照预算。容量脚本明确 `natural_reachability_proven=false`、`commercial_budget_frozen=false`，边界表达正确。该脚本重跑会更新其原有 measurements/fixture 输出。

## 历史发现（当前全部 CLOSED）

### [CLOSED / 原 P1] projectile velocity 只校验 finite，接受下一 tick 发生数值故障的状态

`src/persistence/steam_battle_snapshot.gd:123` 的 projectile/weapon 循环仅验证 damage>0；typed vec2 允许任何有限 float32。将合法 tick0 快照的 weapon 设置为 due_tick=1、position=(0,0)、velocity=(float32(3e38),0)、damage=1，**validate=OK、restore=OK，但随后 run_gameplay_phase=false**。CombatGeometry.retention_fraction 中 Vector2 length_squared 溢出，产生非有限碰撞/查询量。

必须按冻结 legacy profile 校验 friendly projectile/weapon 的速度范围（配置 projectile_speed，加 float32 舍入容差），并对 hostile 应用其固定速度合同。还应检查 damage 与该 profile 的来源合同及需要 world-domain 的位置。不要只在运行中吞掉不合法行：snapshot 应在恢复前整体拒绝。添加该 wire 负例，并验证目标 scope 未被修改。

### [CLOSED / 原 P2] 已过 mandatory Boss 时间的无 Boss 快照仍被接受

`src/persistence/steam_battle_snapshot.gd:251` 的无 Boss 分支只检查初始 FSM，未绑定 mandatory schedule。将初始正常快照的 scope/stage tick 都改成44000，其余保持无 Boss 初始状态，**validate=OK、restore=OK、20 tick 后仍可 capture=OK**；首个恢复 tick 重新生成满血 Boss。当前配置启用 Boss且720秒必生成，boss_defeated终局又不属于可续局快照，因此这个组合不可能来自完整安全 tick。

无 Boss 且 boss_enabled 时要求 tick<43200；已生成 Boss 的 active_age/state schedule 也应保持必要一致性。新增边界 tick43199合法、tick43200缺Boss拒绝，并保留已生成Boss正常恢复测试。

### [CLOSED / 原 P2] 无界 spawn/attack timer 可改变后续战斗规则

`STAGE` 的 `_spawn_left/_attack_left` 只要求 finite。将正常 tick0快照 `_spawn_left` 改为1e100，**validate=OK、restore=OK、20 tick与再capture都成功**，此状态会在本局剩余时间内完全停止普通生成。相同方式可以使自动攻击停止。

按当前owner的更新公式验证 timer 合法区间：spawn 初值0.2，每次仅加当前合法wave interval；attack 有合法负值（无敌人时持续减），因此不要错误要求>=0，应从已完成tick和冻结攻击配置导出安全下/上界。新增超大正timer与合法负attack timer测试。

## 正面观察及证据边界

- 逻辑ID排序创建新Pool/Grid映射，再按保存SoA顺序恢复，分别保留tie-break和执行顺序。
- RNG bits64保留有符号原始位模式，seed先于state恢复，engine identity增加具体commit hash。
- 旧反例对应的空间域、next ID、构筑次数/XP关系和未生成Boss baseline修复有效。
- 新scope恢复成功后重新发布fresh Stage epoch的hazard view；已结束tick的瞬时bite/fan展示不属于本次gameplay持久数据承诺，当前没有生产consumer依赖其旧呈现帧。
- 没有在已测试合法样本发现新误拒；这不证明穷尽所有自然Boss/升级组合。
- `_valid_build` 仍依赖冻结config真实有效，Save五domain/商业Mission/完整SkillDraft/Preparation和Windows IO/锁并非此review覆盖范围。

## 历史修复前反例实测输出

```text
base=OK
projectile_velocity validate=OK
projectile_velocity restore=OK
projectile_velocity next20ticks=false
late_missing_boss validate=OK
late_missing_boss restore=OK
late_missing_boss next20ticks=true
late_missing_boss recapture=OK
spawn_timer validate=OK
spawn_timer restore=OK
spawn_timer next20ticks=true
spawn_timer recapture=OK
```

可重跑命令：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/tal/CursorProjects/xiuxian/Claude-Code-Game-Studios --script /tmp/steam_snapshot_review_probe_v2.gd`。脚本另复制为本目录 `review-snapshot-probe-v2.gd.txt`，避免编辑器导入为生产脚本。

## 当前复核 Source hashes

- `src/persistence/steam_battle_snapshot.gd`: `7704fe7fdaa2e6c2533c0bd4f5767fbf08e279d435e2c97c94a399380f23cd2f`
- `src/persistence/steam_wire_types.gd`: `4a9a3f97fe49b29fa84ea19a25589ab3cd92687c7a810b33a1f22a0377b92cb6`
- `src/gameplay/stage/stage_runtime.gd`: `879f0707364e4b48b71d26822c2dfe8c878acce0578d310b50511b568195589e`
- `src/gameplay/battle/battle_scope.gd`: `b62e91cc44f52bf9358a5750de086aa7dc205ed1ba0f26b79e0bca8199716012`
- `tests/integration/steam_snapshot_test.gd`: `92d403ad016b4bf05d5b7da2fa5c81d62133a11cf259f5b69aba3872397ec147`
- `tests/integration/steam_snapshot_capacity_test.gd`: `87cfb7d2ac01ee0a8d409bee8c3f29a5b31a87a03332c4ec8ab13a29a9ee579f`
