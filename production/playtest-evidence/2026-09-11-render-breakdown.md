# 帧耗时拆分与隐藏绘制对照

## 方法

沿用performance_probe的319敌/392友弹、seed101、120tick预热+600采样，不改运动、碰撞、伤害或夹具填充。`--split`只运行同一容量场景的三个可见性对照：正常、Stage隐藏、Stage/Player/HUD/摇杆隐藏。后者称no_canvas，仅指这些战斗内容，不是停止引擎渲染。

循环分段计时：fixture_fill、simulation、bookkeeping、await process_frame。另由Stage默认关闭的measure_draw_cpu测量_draw函数CPU时间，夹具才开启。stage_draw_cpu是wait_next_frame的子区间，不可重复相加。各段P95不能相加；报告使用均值对账。等待区间包含_draw、引擎CPU、提交、GPU可能阻塞、窗口呈现与系统调度，不能命名为GPU耗时。

关闭VSync只调用当前测试窗口的DisplayServer接口，不改project.godot。查询到的模式会写入JSON；OS/compositor仍可能限制呈现。原基线及优化JSON均保留。

## 默认VSync（API模式1，Engine.max_fps=0）

| 对照 | 填充均值ms | 模拟均值ms | 统计均值ms | 等待均值ms | 循环均值ms | 循环P95ms |
| --- | --- | --- | --- | --- | --- | --- |
| 正常 | 0.0418 | 4.7769 | 0.0022 | 21.2858 | 26.1068 | 30.545 |
| 隐藏Stage | 0.0400 | 4.6409 | 0.0014 | 3.7134 | 8.3957 | 11.218 |
| 隐藏战斗内容 | 0.0415 | 4.6548 | 0.0014 | 3.6785 | 8.3762 | 11.300 |

正常Stage绘制函数均值3.8114ms/P95 4.566ms（600次）。填充和统计不是主因；隐藏Stage使循环均值减少约17.71ms，隐藏HUD等没有实质附加收益。由此将首要后续工作定位到Stage绘制及其引擎提交/呈现路径，而不是继续优先优化已经约4.8ms的模拟。

## 边界

关闭VSync复测（API模式0，max_fps=0）：正常循环均值25.3467ms、P95 27.747ms，其中模拟4.7443ms、填充0.0415ms、统计0.0020ms、等待20.5589ms，Stage绘制CPU均值3.6764ms。隐藏Stage循环均值5.8233ms/P95 6.529ms。由此不能将主瓶颈归为VSync。

隐藏全部战斗内容均值7.2448ms/P95 10.089ms反而高于仅隐藏Stage，且模拟均值升至5.5855ms，提示单次串行样本的运行环境/调度漂移，不能声称HUD存在负开销或精确归因。核心结论仅是绘制Stage与隐藏Stage差异显著，需优先分析其路径。

原始报告：performance-graphical-split.json、performance-graphical-split-no-vsync.json。

测试串行执行，未关闭用户其他窗口；没有GPU时间戳、Metal/OpenGL profiler、真实输入或多轮统计置信区间。敌弹/友弹布置和敌人聚集仍是人工压力，不代表完整自然局。不能把全部剩余等待时间归因GPU，也不能凭隐藏画面宣称游戏已经稳定60FPS。

下一步建议对Stage做可见范围剔除、检查批量绘制，分别用分散和聚集实体场景验证。此次只加入诊断计时和可见性对照，没有实施画面降级或生产渲染优化。battle_ready=false。
