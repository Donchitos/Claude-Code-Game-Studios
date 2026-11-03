# perf-profile — 结构化性能剖析（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/perf-profile/SKILL.md) ｜ 阶段：Phase 6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/perf-profile [system-name or 'full']`
- **一句话职责**：静态分析代码库找性能瓶颈（CPU/内存/渲染/IO 四类热点）、对照已提交的预算逐项评估、产出按优先级排序的优化建议清单并落盘报告。
- **触发前置**：配置经 `resolve_config --keys performance.enforce,automation,workflow` 解析；每个 `AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `get_effective_yaml_key performance.target_framerate / frame_budget_ms / draw_call_limit / memory_ceiling_mb`（每键一条独立命令；空输出=未设）；config 不载的设计文档/CLAUDE.md 兜底（Target FPS、内存预算〔总量与分系统〕、加载时长目标、draw call 预算、多人时网络带宽上限）；代码库全文（按 Phase 3 四类目标扫描） | 预算必须来自已提交配置而非散文 |
| 产出 | `production/polish/[scope]-report-[date].md`（先征询"May I write this profiling report to …？"；目录缺失则创建） | 与 `/team-polish` 同一落点，两次运行才能对比 |
| 派生智能体 | 无，主会话直接执行 | 模型档位 sonnet |

**配置键影响**：`performance.enforce` 决定预算违例在本次运行中的*含义*（见 R4），不改变测量哪些预算——四个预算在任何档位都以相同方式被剖析。

## 3. 核心规则（逐条编号 R1、R2……）

### 输入不足前置检查
R1. 产出任何报告前必须先核对本技能所需输入的存在性：
   1. 列出全部输入（数据文件、先前报告、profiler 输出、测试结果、registry、源代码）；
   2. 逐项记 `FOUND` 或 `ABSENT`（不是"假设存在"）；
   3. 某节必需输入 ABSENT 时该节记 **`NOT ASSESSED — NO DATA`**——禁止估算、禁止从相邻工件推断、禁止把必填格留给下次读模板的人；
   4. **每一个**必需输入都 ABSENT 时停止并整体报告 `NOT ASSESSED — NO DATA`，点名缺了什么、哪个技能产出它。（Insufficient input）
R2. `NOT ASSESSED` 是成功而非失败——它是"数据说什么"在无数据时的正确答案。要防的失效模式很具体：裁决枚举没有"无法运行"态的报告会产出**假性干净通过**——零 profiler 数据、从未设预算却报 ">99% headroom against a 16.67ms budget"。"无证据"绝不是"不存在证据"：零文件可扫的扫描没有验证任何东西，必须说明是哪一种。（Insufficient input）

### Phase 0 — 解析预算强制档
R3. `performance.enforce` 三档：

   | 值 | 对本次剖析发现的影响 |
   |---|---|
   | `warn`（默认） | 违例作为发现报告；不阻断，CI 记日志不失败 |
   | `block` | 违例是 **blocker**；报告中明说——`block` 项目视超预算系统为停止发布级，`/gate-check` 会在 Polish gate 上 FAIL |
   | `off` | 预算仅信息性；仍报告测量值，但不把违例列为发现或修复建议 |（Phase 0）
R4. 只认 `warn`/`block`/`off` 三个值；其它值必须呈报用户并回退 `warn`，禁止猜。该键可本地覆盖（`/settings --local performance.enforce=block`）——必须用解析出的块而非读 `project.yaml`（队友更严的本地设置就该只咬他们的机器）。（Phase 0）

### Phase 1-2 — 定范围与载预算
R5. 参数为系统名 → 聚焦剖析该系统；`full` → 全系统综合剖析。（Phase 1）
R6. **预算先从已提交的 config 读**（四键各自一条裸命令——helper 自行回到项目根，所以在子目录启动的会话也能用；本技能只预批准这一形式，`source` 或 `cd … &&` 包装每次都会问用户）；空输出即该预算未设。config 不载的才回退设计文档/CLAUDE.md。必须从 `project.yaml` 而非散文解析这些预算：用户在 `project.yaml` 里设了 `performance.target_framerate: 60`，若从设计文档或 CLAUDE.md 读就会被忽略。（Phase 2）
R7. **无已提交预算的指标是 `NOT ASSESSED`，不是通过**。禁止对着模板的 `[16.67ms]` 占位符测量——没人选定的预算不是被满足的预算，对着没人选的数字报余量正是本技能头部警告的那种 fabrication。（Phase 2）

### Phase 3 — 分析代码库
R8. 四类剖析目标全查：
   - **CPU**：`_process()`/`Update()`/`Tick()` 函数全列出并估成本；大集合上的嵌套循环；热路径里的字符串操作；逐帧代码中的内存分配模式；游戏实体上未优化的搜索/排序；每帧昂贵物理查询（raycast、overlap）；
   - **内存**：大数据结构及增长模式；纹理/资产内存足迹估算；对象池 vs instantiate/destroy 模式；泄漏引用（该释放未释放的对象）；缓存大小与逐出策略；
   - **渲染**（如适用）：draw call 估算；重叠透明物体的 overdraw；shader 复杂度；未优化粒子系统；缺 LOD 或遮挡剔除；
   - **IO**：存/读档性能；资产加载模式（同步 vs 异步）；网络消息频率与体积。（Phase 3）

### Phase 4 — 生成报告
R9. 报告**必须写入** `production/polish/[scope]-report-[date].md`（先按协作协议征询），目录缺失则创建——禁止只把模板渲染进对话：只活在 transcript 里的剖析随会话结束就没了，且两次运行无法对比。`production/polish/` 与 `/team-polish` 写的是同一位置，属刻意设计——两条路线做的剖析归属一处，本技能要实现的对比才成立。（Phase 4）
R10. 若有 `NOT ASSESSED` 节存活进报告，**写盘时必须保留**——半路把缺口编辑掉的剖析，事后读起来像一次完整的测量。（Phase 4）
R11. 报告模板：`## Performance Profile: [System or Full]` + Generated → Performance Budgets 表（Metric | Budget | Estimated Current | Status〔OK/WARNING/OVER/**NOT ASSESSED**〕；行：Frame time、Memory、Load time、Draw calls）→ Hotspots Identified 表（# | Location | Issue | Estimated Impact | Fix Effort）→ Optimization Recommendations（优先级序；每条含 Title、Description、Location〔file:line〕、Expected gain、Risk〔Low/Med/High〕、Approach）→ Quick Wins（每项 <1 小时）→ Requires Investigation（需真实运行时 profiling 确认影响的区域）。（Phase 4）
R12. 报告带摘要输出：top 3 热点、对每个已设预算的估算余量（未设的记 `no budget set — headroom not assessed`）、建议的下一步动作。（Phase 4）

### Phase 5 — 范围与时间线决策
R13. 仅当任一热点 Fix Effort 为 M 或 L 时激活本阶段：逐项呈现高投入项让用户选：
   - **A) 实施优化**（现在修或排期——`workflow: minimal` 无 sprint，加进 brief 的 build order）；
   - **B) 缩功能范围**（运行 `/scope-check [feature]` 分析取舍）；
   - **C) 接受性能损失、推迟到 Polish 阶段**（记为 known issue）；
   - **D) 上报 technical-director 做架构决策**（运行 `/architecture-decision`）。（Phase 5）
R14. 多项被推迟到 Polish（选 C）时，统一记录在 `### Deferred to Polish` 节下。（Phase 5）

### 裁决与收尾
R15. 每次产出报告的运行（无论 Phase 5 是否跑过）都以这句收尾：Verdict: **COMPLETE** — performance profile generated（若写入获批则注明保存到 `production/polish/[scope]-report-[date].md`）。唯一其它结局是 `NOT ASSESSED — NO DATA` 路径。（Verdict）
R16. 后续：瓶颈需架构变更 → `/architecture-decision`；需缩范围 → `/scope-check [feature]`；排期优化 → `/sprint-plan update`（`workflow: minimal` 无 sprint，加进 brief 的 build order）。（Phase 6）
R17. 铁律：**先测量后优化**——对性能的直觉不可靠；建议必须含估算影响——"make it faster" 不可行动；在目标硬件而非仅开发机上剖析；静态分析（本技能）识别候选，运行时 profiling 确认。（Rules）

## 4. 门禁与裁决
- **裁决词**：`COMPLETE` / `NOT ASSESSED — NO DATA`。
- **联动**：`performance.enforce: block` 时超预算系统是 blocker，`/gate-check` 会在 Polish gate FAIL；本报告（`tests/performance/` 数据之外）是 Polish → Release 前性能核查的输入源。
- **消费方**：`/gate-check`（Polish gate 读预算对比）、`/architecture-decision`（架构级瓶颈）、`/sprint-plan`（排期优化）。

## 5. 移植建议
- **可直接移植**：R1-R2（输入不足前置检查）、R4（未知配置值回退 warn 并呈报）、R6-R7（预算来自已提交配置、无预算即 NOT ASSESSED 绝不测占位符）、R9-R10（报告必落盘、缺口保留进写盘文件）、R13（每项高投入热点四选一决策）、R17（先测量后优化）。
- **需替换概念**：`_process()/Update()/Tick()` → 目标框架的每帧钩子；draw call/LOD/遮挡剔除 → 按领域换成 DB 查询数、缓存策略、批处理档位；`production/polish/` → 项目的性能报告目录；`performance.*` 四键 → 项目的 SLO/预算配置键。
- **改写示例**：
  - R7 → "没有已提交预算的指标一律记 NOT ASSESSED，不是通过；禁止对着模板占位数字测量——没人选定的预算不是被满足的预算。"
  - R9 → "剖析报告必须写入约定路径并先征询，禁止只渲染进对话；只活在会话记录里的剖析无法与下次运行对比。"

## 6. 关联文档
- 上游：`/setup-engine`、`/settings`（performance.* 预算键）。
- 下游：`/gate-check`（Polish gate 性能检查读 `tests/performance/` 与本技能输出）、`/architecture-decision`、`/scope-check`、`/sprint-plan update`、`/team-polish`（同一报告目录）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/workflow-modes.md`（minimal 的 build order 路由）。
