# macOS性能基线（首次）

## 方法

`tests/integration/performance_probe.gd`固定seed101、临时档案；每个场景预热120tick、采样600tick，计时只包住实际BattleScope.run_gameplay_phase(1/60)，包括当前HUD刷新和危险快照发布。未测Input阶段。高血量避免过早死亡，升级自动选择。未修改生产配置。

- ordinary：新局自然生成，前12秒；不是全长普通局性能代表。
- capacity_stress：319只高HP普通敌人，392枚友弹每tick在计时区外补满并重置到相同位置。刻意让弹体不命中以保持全量候选扫描；不是真实弹幕空间分布、自然玩法密度或最坏GPU overdraw证明。
- boss_phase2：跳到Boss出场，夹具注入50%以下HP回执，玩家飞剑伤害为0，观察二阶段动作与毒弹；不是Boss加满普通敌人的组合压力。

分别运行headless与macOS图形窗口1280×720。图形模式每次模拟后等待process_frame，其帧间隔包括渲染等待、VSync、夹具填充等，不能当纯GPU耗时。每60tick采集OS.get_static_memory_usage；这只是Godot内存跟踪值，不是RSS/显存。采样数组自身增长、字体/引擎缓存和其他用户窗口也会影响读数。短时变化不能证明有/无泄漏。

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/integration/performance_probe.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/integration/performance_probe.gd
```

原始JSON见performance-headless.json及performance-graphical.json。

## Headless结果（Apple M4）

| 场景 | 敌人/友弹/敌弹峰值 | 模拟P50 ms | P95 ms | P99 ms | 超16.67ms |
| --- | --- | --- | --- | --- | --- |
| 开局 | 3/4/0 | 0.044 | 0.060 | 0.068 | 0/600 |
| 容量压力 | 319/392/0 | 42.544 | 45.539 | 56.639 | 600/600 |
| Boss二阶段 | 3/2/8 | 0.036 | 0.057 | 0.118 | 0/600 |

容量压力未达60FPS预算，不能称性能验收通过。脚本输出PASS仅表示夹具执行无故障。

源码检查显示_update_projectiles逐弹遍历全部敌人：319×392=125048次候选检查/tick。推断这是首要热点，尚不是采样profiler独占耗时归因。后续应接空间候选筛选并保留扫掠、最近命中、同距稳定排序及死亡/回收语义，再同夹具对比；不能通过减少敌人/弹体数宣称优化。

## 图形窗口结果

| 场景 | 模拟P95 ms | 帧间隔P95 ms | 帧间隔P99 ms |
| --- | --- | --- | --- |
| 开局 | 0.135 | 13.439 | 15.961 |
| 容量压力 | 44.123 | 67.411 | 71.265 |
| Boss二阶段 | 0.172 | 14.226 | 14.841 |

图形压力场景同样600/600模拟tick超16.67ms。以上为分位数，不是平均FPS。

Godot静态内存采样：headless压力场景124587317→124604873 bytes；图形压力场景132714538→133036266 bytes，结束teardown后132046434 bytes。三场景图形teardown值131123738/132046434/132056650 bytes。存在缓存/夹具开销且采样时间短，不据此断言泄漏或完全稳定；后续需长时循环与RSS/显存分开测。

当前仍In Review / Re-review Pending，battle_ready=false；Windows、独立.app、真机长时热稳定、GPU与完整长局性能未验收。
