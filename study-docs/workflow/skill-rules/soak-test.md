# soak-test — 长时间浸泡测试协议（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/soak-test/SKILL.md) ｜ 阶段：Phase 6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/soak-test [duration: 30m | 1h | 2h | 4h] [focus: memory | stability | balance | all]`
- **一句话职责**：生成 30 分钟到数小时长会话的观察协议与分析框架（检查点表、观察项、告警阈值、后处理分析、裁决）——**人类实际游玩，技能只产出协议**。
- **触发前置**：`resolve_config --keys automation,workflow` 已解析；`AskUserQuestion` 与文件写入遵循 `.claude/docs/automation-modes.md`。运行时机：Polish 阶段（`/gate-check release` 前）；修复内存或稳定性问题后（回归 soak）；扩展游玩未被正式跟踪时。
- 与相邻检查的区分：smoke check 是宽关键路径（~10 分钟），单特性 playtest ~30 分钟；soak 跑 **30 分钟到数小时**，专捕：内存泄漏（场景切换后才出现的渐进堆增长）、性能漂移（随时间恶化的帧时间）、状态累积 bug（机制重复 N 次后才出现）、乐趣疲劳（首局好玩、长玩腻）、内容耗尽（玩家用完新鲜内容的时点）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `project.yaml` 的 `engine.name` 与 `performance.*`（内存上限、目标 FPS；键缺失/空或无对应块 → 回退 `.claude/docs/technical-preferences.md`）；`design/gdd/game-concept.md`（预期会话长度、核心循环；`rigor: minimal` 时为 `design/game-brief.md`——仅其 "Who it's for" 行声明时才有会话长度；按节读：Grep `^#` 建标题图 + offset/limit）；`production/qa/playtests/` 最新文件（已知问题）；最新 `production/qa/qa-plan-*.md`（正式测过什么 vs soak 覆盖什么） | 引擎专属监控指引 / 预算目标 / 会话设计对比 / 避免重复记录已知问题 |
| 产出 | `production/qa/soak-test-[date]-[duration].md`（写入前须批准） | 协议文档：Pre-Session Setup、Baseline T+0、逐检查点日志、Post-Session Analysis、Verdict、Sign-Off |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则（逐条编号 R1、R2……）

### 1 — 解析参数
R1. **Duration（默认 `1h`）**：`30m` 短 soak（测单一机制或场景）；`1h` 标准 soak（覆盖最常见泄漏类别）；`2h` 扩展 soak（首次完整 Polish soak 推荐）；`4h` 深度 soak（长会话设计游戏——RPG、模拟经营——**必须**）。**Focus（默认 `all`）**：`memory`（堆大小、对象数、泄漏模式）/ `stability`（崩溃/冻结/挂起检测）/ `balance`（乐趣疲劳、内容耗尽、难度感知）/ `all`。（§1）

### 2 — 载入上下文
R2. 载入引擎与预算（回退链如数据依赖表）；GDD 按节读，禁止全文读。报告预算目标：Memory ceiling / Target FPS / Frame budget，各为 [N] 或 "not set"。（§2）

### 3 — 定义观察检查点
R3. 按时长生成定时检查点：
   - **30m** → T+0, T+10, T+20, T+30
   - **1h** → T+0, T+15, T+30, T+45, T+60
   - **2h** → T+0, T+20, T+40, T+60, T+80, T+100, T+120
   - **4h** → T+0, T+30, T+60, T+90, T+120, T+180, T+240
   观察者在每个检查点记录 §4 定义的观察项。（§3）

### 4 — 生成观察项
R4. **单位纪律**：记录工具显示的单位，**绝不换算、绝不假设单位**。soak 找的是**增长**，所以每个阈值都是*相对本会话自身 T+0 基线的比率或 delta*——单位无关，编辑器怎么报都成立。T+0 时把单位按显示原样写下，全程一致使用。（§4）
R5. **NOT SOURCEABLE 标注**：所列工具/面板/计数器名（Godot 的 Debugger → Monitors 与内存计数器、Unity 的 Memory Profiler 及其字段、Unreal 的 `stat memory`）不被 `docs/engine-reference/` 覆盖——协议中必须如此标记：它们是测试者 T+0 在自己编辑器里确认的指针，不是验证过的路径。**找不到内存工具 = 什么都没测量** → Verdict 的 NOT ASSESSED 适用。（§4）
R6. 引擎专属监控与告警阈值：
   - **Godot 4**：Debugger → Monitors 页跟踪 `Memory → Static Memory` 与 `Object Count → Objects`；记录 Static Memory（**按显示的单位**）、Object Count、Orphan Nodes。告警阈值：**前 15 分钟后内存较 T+0 增长 > 20%**（加载期一定增长属预期，持续增长才是泄漏）。**Orphan Nodes 是唯一值得盯的绝对数**：场景卸载后应回到 T+0 值——比率会掩盖它；持续上升的非零下限无论单位是什么都是泄漏。
   - **Unity**：Memory Profiler（Window → Analysis）；每检查点记录 Total Reserved Memory、GC Allocated、Object Count（**按显示的单位**）。告警阈值：**GC Allocated 跨 3+ 个检查点单调增长**——故意做成单位无关的单调性检查。
   - **Unreal**：每检查点跑 `stat memory`；记录 Physical Memory Used / Available（**按显示的单位**）。告警阈值：**整场 soak 较 T+0 增长 > 20%**。绝对阈值（如 ">50MB"）会同时静默假设单位*和*项目规模——50MB 对一个游戏是舍入误差，对另一个是灾难。（§4）
R7. **Stability 观察项**（focus = stability 或 all），每检查点核对：无崩溃/挂起/冻结；帧率仍在目标预算（[target FPS] fps）；音频正常（无失步或静音）；全部 HUD 元素渲染正常；输入符合预期（无丢失或延迟尖峰）。（§4）
R8. **Balance/fatigue 观察项**（focus = balance 或 all），每检查点收集主观观察：核心机制仍有回报（Y/N）；感知难度（too easy / appropriate / too hard）；上次检查点以来有无 "I've seen this before" 时刻（新颖内容耗尽）；有无挫败时刻（记原因）；有无高峰投入时刻（记原因）。（§4）

### 5 — 协议文档结构
R9. 协议必须含：
   - **Pre-Session Setup**：游戏从**全新启动**运行（不是从先前会话恢复）；后台应用全关（减少 OS 内存干扰）；性能监控工具打开并记录——**按本编辑器实际所用工具记录其名**（上文工具名 NOT SOURCEABLE，找不到 → NOT ASSESSED）；soak 目标确认（game concept 的会话设计意图）；先前已知问题清单（来自最新 playtest / qa-plan）；
   - **Baseline (T+0)** 表：Memory/Heap（gameplay 首帧前记录）、Object Count、FPS（前 30 秒）、引擎专属指标；
   - **Checkpoint Log**：每定时检查点重复一节——Memory/Stability 表（Metric / Value / Δ from Baseline / Alert?）+ stability checks + Balance/Fatigue 主观项 + Free observations（记上次检查点以来的任何意外）；
   - **Post-Session Analysis**：Memory Trend 表含 Δ/hr 外推、Leak detected? Y/N、Estimated time to OOM at current rate；Stability Summary（总崩溃/总挂起/最差 FPS 及所在检查点、性能退化 stable / mild / severe）；Balance/Fatigue Summary（乐趣曲线：全程投入 / T+N 疲劳 onset / 从头重复；内容耗尽点：never / at T+N / early；难度弧）；Issues Found 表（ID `SOAK-NNN`、Severity `S[1-4]`、Checkpoint `T+[N]`、描述）；
   - **Verdict** 与 **Sign-Off**（Tester + QA Lead review，各带姓名与日期）。（§5）

### 6 — 写输出
R10. 会话展示协议摘要后询问："May I write this soak test protocol to `production/qa/soak-test-[date]-[duration].md`?"——**批准后才写**。（§6）
R11. 写后给运行指引：（§6）
   - ① 打开文件按 Pre-Session Setup 清单执行；
   - ② 游玩中逐检查点记录；
   - ③ 完成后填 Post-Session Analysis 节；
   - ④ 从 "Issues Found" 向 `production/qa/bugs/` 提 bug；
   - ⑤ 会话后跑 `/bug-triage sprint` 整合任何 S1/S2 问题（`workflow: minimal` 无 sprint → `/bug-triage full`）。

   **verdict 为 FAIL 时：修复问题后重跑 `/smoke-check`**。

### 协作协议
R12. **本技能生成协议——人类运行它**：绝不尝试自动跑 soak test，观察需要人类观察者。时长应匹配游戏的会话设计——5 分钟游戏不需要 4h soak，城建游戏可能需要；用判断，不清楚就问。**首次 soak 应为 `all` focus**——窄焦点（仅 memory）是特定修复后回归 soak 用的，不是首跑用的。始终先问再写。

## 4. 门禁与裁决
- **裁决词**：`PASS` / `PASS WITH CONCERNS` / `NOT ASSESSED` / `FAIL`。
- **定义**：PASS = 无泄漏、稳定维持、乐趣一致；PASS WITH CONCERNS = 轻微漂移或疲劳，Polish 期可解决；NOT ASSESSED = soak 没跑到能展示"它长什么样"的长度——说明跑到多远、哪些检查点未达；FAIL = 确认内存泄漏、稳定性破坏或严重乐趣疲劳。
- **短 soak 不能返回 PASS**：本协议要检测的一切——慢泄漏、疲劳、迟现边缘——定义上早期不可见，在为其设计的检查点之前结束的会话没有展示稳定，什么都没展示。记录 `NOT ASSESSED — reached T+[N] of [duration]; checkpoints [list] not reached`。**排序：高于两个 pass 值、低于 FAIL**——T+20 观察到的崩溃是真实发现，无论运行多短，不得因时长降级。同一逻辑适用于：build 因与 soak 无关的原因崩溃；无内存工具可用（没测量 = "未检测到泄漏" 实为"不可能检测到泄漏"）；协议写了但从未执行——**协议文档不是结果**。
- **消费方**：`/bug-triage`（S1/S2 整合）、`/gate-check release`（Polish 门）、`/smoke-check`（FAIL 后复检）。

## 5. 移植建议
- **可直接移植**：R4（单位纪律——阈值用相对自身基线的比率/delta）、R5（NOT SOURCEABLE 标注——不可溯源的工具名必须在产物中声明）、R6 的 Orphan Nodes 绝对数原则与 ">50MB 静默假设两个东西" 论证、R9 的 T+0 基线表 + 逐检查点 Δ 记录、裁决节的 "短 soak 不能 PASS" 与 "协议文档不是结果"。
- **需替换概念**：引擎监控三分支 → 换成你的运行时监控（APM、profiler、`top`、Prometheus 指标）；"乐趣疲劳/内容耗尽" → 长时运行任务的人因维度（值班疲劳、审阅疲劳）；RPG/sim 会话设计 → 系统的预期连续运行时长（SLA、批处理窗口）；playtester → 长时值守的运维/用户。
- **改写示例**：
  - R4 → "长时运行测试的内存阈值一律以相对本会话 T+0 基线的比率或增量表达，并按监控工具显示的原样记录单位，禁止换算或假设——比率阈值在任一工具的任一单位制下都成立。"
  - 裁决 → "未跑满设计时长的耐久测试只能记 NOT ASSESSED 并注明到达点与未达检查点，绝不允许 PASS：慢泄漏与疲劳在设计上早期不可见，提前结束的会话没有证明稳定，只是什么都没展示。"

## 6. 关联文档
- 上游：`/qa-plan`（当前 sprint 测试覆盖）、`/playtest-report`（先前已知问题）。
- 下游：`/bug-triage`（S1/S2 整合）、`/gate-check release`（Polish 出口门）、`/smoke-check`（FAIL 后复检）、`production/qa/bugs/`（问题落档）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/technical-preferences.md`、`docs/engine-reference/`。
