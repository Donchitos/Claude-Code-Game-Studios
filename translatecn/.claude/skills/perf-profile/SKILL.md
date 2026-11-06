---
name: perf-profile
description: "Performance profiling — find bottlenecks, measure against budgets, produce ranked optimization recommendations."
argument-hint: "[system-name or 'full']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" get_effective_yaml_key *)
model: sonnet
---
---
name: perf-profile
description: "性能剖析——查找瓶颈、对照预算测量、产出按优先级排列的优化建议。"
argument-hint: "[system-name or 'full']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" get_effective_yaml_key *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys performance.enforce,automation,workflow`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.
已在上方解析——按原样使用。无块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

# Performance Profile
# 性能剖析

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`（collaborative 始终询问 · guided 仅重大问题 · autonomous 记录并继续；`automation_always_ask` 类别始终提示）。

## Insufficient input — check this before producing any report
## 输入不足——在产出任何报告前先检查

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.
**如果本技能所需的输入不存在，答案就是“无法运行”——而不是一份填好的报告。** 先检查，如果检查失败就停止。

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.
1. 列出本技能读取的输入（数据文件、先前报告、剖析器输出、测试结果、注册表、源代码）。
2. 对每一项记录 `FOUND` 或 `ABSENT`——而不是“假定存在”。
3. 如果某个小节所需的任何输入为 ABSENT，该小节即为 **`NOT ASSESSED — NO DATA`**。不要估算它，不要从相邻产物推断它，也不要留下一个被强制要求的单元格让下一个读模板的人来填。
4. 如果**每项**必需输入都是 ABSENT，停止并以 **`NOT ASSESSED — NO DATA`** 作为整体判定上报，说明缺失了什么以及由哪个技能产出。

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.
**`NOT ASSESSED` 的判定是一种成功。** 在没有数据时，它是对“数据说明了什么？”这一问题的正确、有用的回答。它所防止的失败模式很具体：判定枚举中没有“无法运行”状态的报告会产生**虚假的干净通过**——在没有资产也没有标准的项目上返回 COMPLIANT 的资产审计，或在没有任何剖析器数据、也从未设定预算的情况下报告“相对 16.67ms 预算有 >99% 余量”的性能剖析。

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.
**证据的缺失永远不是缺失的证据。** 因为无文件可扫描而找不到匹配的扫描没有验证任何东西。说明两者中究竟是哪一种——读者无法从一个绿色的结果中分辨出来。

---

## Phase 0: Resolve Budget Enforcement
## 阶段 0：解析预算执行策略

`performance.enforce` decides what a budget violation *means* in this run. It
does not change which budgets are measured — `performance.target_framerate`,
`frame_budget_ms`, `draw_call_limit` and `memory_ceiling_mb` are profiled the
same way at every level:
`performance.enforce` 决定预算违规在本次运行中*意味着*什么。它不改变测量哪些预算——`performance.target_framerate`、`frame_budget_ms`、`draw_call_limit` 和 `memory_ceiling_mb` 在每个层级都以相同方式剖析：

| Value | Effect on this profile's findings |
|-------|-----------------------------------|
| `warn` (default) | Violations are reported as findings. They do not block; CI logs them without failing. |
| `block` | Violations are **blockers**. Say so explicitly in the report — a `block` project treats an over-budget system as release-stopping, and `/gate-check` will FAIL the Polish gate on it. |
| `off` | Budgets are informational only. Still report measured values, but do not raise violations as findings or recommendations to fix. |

| 值 | 对本剖析发现的影响 |
|-------|-----------------------------------|
| `warn`（默认） | 违规作为发现上报。它们不阻塞；CI 会记录它们但不会失败。 |
| `block` | 违规是**阻塞项**。在报告中明确说明——一个 `block` 项目将超预算系统视为阻止发布的工作，`/gate-check` 会在 Polish 门禁上判其 FAIL。 |
| `off` | 预算仅供参考。仍上报测量值，但不要将违规作为发现或修复建议提出。 |

Only `warn`, `block` and `off` are recognized. Surface any other value to the
user and fall back to `warn` rather than guessing.
只识别 `warn`、`block` 和 `off`。将任何其他值向用户暴露，并回退到 `warn`，而不是猜测。

> The value is locally overridable (`/settings --local performance.enforce=block`),
> so use the resolved block above rather than reading `project.yaml` — a
> teammate's stricter local setting is meant to bite on their machine only.
> 该值可在本地覆盖（`/settings --local performance.enforce=block`），因此使用上方解析后的块，而不是去读 `project.yaml`——队友更严格的本地设置只应在他自己的机器上生效。

## Phase 1: Determine Scope
## 阶段 1：确定范围

Read the argument:
读取参数：

- System name → focus profiling on that specific system
- `full` → run a comprehensive profile across all systems
- 系统名称 → 将剖析聚焦于该特定系统
- `full` → 跨所有系统运行一次全面剖析

---

## Phase 2: Load Performance Budgets
## 阶段 2：加载性能预算

**Read the committed budgets from config first** — they are the project's
record of what it agreed to, and design docs are the fallback, not the source:
**先从配置读取已提交的预算**——它们是项目对已同意内容的记录，而设计文档是后备，不是来源：

```bash
bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" get_effective_yaml_key performance.target_framerate
bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" get_effective_yaml_key performance.frame_budget_ms
bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" get_effective_yaml_key performance.draw_call_limit
bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" get_effective_yaml_key performance.memory_ceiling_mb
```

Run each line as its own plain command, one key per call: the helper moves to
the project root itself, so it works when the session was started in a
subfolder, and this skill pre-approves that form only (a `source` or `cd ... &&`
wrapper asks the user every time). Empty output means that budget is not set.
将每一行作为它自己的普通命令运行，一次一个键：该辅助脚本会自行移动到项目根目录，因此当会话是在子文件夹中启动时也能正常工作，而本技能只预批准这种形式（用 `source` 或 `cd ... &&` 包裹每次都会询问用户）。空输出意味着该预算未设置。

> **Resolve these budgets from `project.yaml`, not from prose.** Phase 0 above
> states these four budgets "are profiled the same way at every level". A user
> who set `performance.target_framerate: 60` in `project.yaml` has it ignored if
> the budget is read from design docs or CLAUDE.md instead.
> **从 `project.yaml` 解析这些预算，而不是从散文里。** 上方阶段 0 声明这四个预算“在每个层级都以相同方式剖析”。如果改为从设计文档或 CLAUDE.md 读取预算，用户在 `project.yaml` 中设置的 `performance.target_framerate: 60` 就会被忽略。

Then fall back to design docs or CLAUDE.md for anything config does not carry:
对于配置未承载的任何内容，回退到设计文档或 CLAUDE.md：

- Target FPS (e.g., 60fps = 16.67ms frame budget)
- Memory budget (total and per-system)
- Load time targets
- Draw call budgets
- Network bandwidth limits (if multiplayer)
- 目标 FPS（例如 60fps = 16.67ms 帧预算）
- 内存预算（总计与按系统）
- 加载时间目标
- Draw call 预算
- 网络带宽限制（若为多人游戏）

**A metric with no committed budget is `NOT ASSESSED`, not a pass.** Do not
measure against the template's `[16.67ms]` placeholder — an unset budget is not
a budget that was met, and reporting headroom against a number nobody chose is
the exact fabrication this skill's own header warns about.
**没有已提交预算的指标是 `NOT ASSESSED`，不是通过。** 不要对照模板的 `[16.67ms]` 占位符测量——未设置的预算不是已满足的预算，而相对一个没人选择的数字上报余量，正是本技能自身头部所警告的那种编造。

---

## Phase 3: Analyze Codebase
## 阶段 3：分析代码库

**CPU Profiling Targets:**
- `_process()` / `Update()` / `Tick()` functions — list all and estimate cost
- Nested loops over large collections
- String operations in hot paths
- Allocation patterns in per-frame code
- Unoptimized search/sort over game entities
- Expensive physics queries (raycasts, overlaps) every frame
**CPU 剖析目标：**
- `_process()` / `Update()` / `Tick()` 函数——全部列出并估算开销
- 对大集合的嵌套循环
- 热点路径中的字符串操作
- 逐帧代码中的分配模式
- 对游戏实体的未优化搜索/排序
- 每帧都执行的昂贵物理查询（射线检测、重叠检测）

**Memory Profiling Targets:**
- Large data structures and their growth patterns
- Texture/asset memory footprint estimates
- Object pool vs instantiate/destroy patterns
- Leaked references (objects that should be freed but aren't)
- Cache sizes and eviction policies
**内存剖析目标：**
- 大型数据结构及其增长模式
- 纹理/资产内存占用估算
- 对象池 vs 实例化/销毁模式
- 泄漏的引用（本应释放却没有释放的对象）
- 缓存大小与淘汰策略

**Rendering Targets (if applicable):**
- Draw call estimates
- Overdraw from overlapping transparent objects
- Shader complexity
- Unoptimized particle systems
- Missing LODs or occlusion culling
**渲染目标（若适用）：**
- Draw call 估算
- 重叠透明物体造成的过度绘制
- 着色器复杂度
- 未优化的粒子系统
- 缺失的 LOD 或遮挡剔除

**I/O Targets:**
- Save/load performance
- Asset loading patterns (sync vs async)
- Network message frequency and size
**I/O 目标：**
- 存档/读档性能
- 资产加载模式（同步 vs 异步）
- 网络消息频率与大小

---

## Phase 4: Generate Profiling Report
## 阶段 4：生成剖析报告

**Write the report to `production/polish/[scope]-report-[date].md`**, asking first
per the Collaboration Protocol: *"May I write this profiling report to
`production/polish/[scope]-report-[date].md`?"* Create the directory if absent.
**将报告写入 `production/polish/[scope]-report-[date].md`**，并按协作协议先询问：*“我可以将这份剖析报告写入 `production/polish/[scope]-report-[date].md` 吗？”* 若目录不存在则创建。

> **Name the destination — do not just render the template into the
> conversation.** A profile that lives only in the transcript is gone the moment
> the session ends, and no two runs can be compared. `production/polish/`
> is the same location `/team-polish` writes, deliberately: a profile taken by
> either route belongs in one place, or the comparison this skill exists to enable
> cannot be made.
>
> If a `NOT ASSESSED` section survives into the report, keep it in the written
> file. A profile whose gaps are edited out on the way to disk reads, later, as a
> complete measurement.
> **点名目的地——不要只是把模板渲染到对话里。** 只存在于转录中的剖析在会话结束的那一刻就消失了，两次运行也无法比较。`production/polish/` 正是 `/team-polish` 写入的同一位置，这是有意为之：无论经由哪条路径取得的剖析都应归入同一处，否则本技能存在所要促成的比较就无法进行。
>
> 如果某个 `NOT ASSESSED` 小节留存到了报告中，请把它保留在写入的文件里。一份在落盘途中被抹去缺口的剖析，日后读起来就像一次完整的测量。


```markdown
## Performance Profile: [System or Full]
Generated: [Date]

### Performance Budgets
| Metric | Budget | Estimated Current | Status |
|--------|--------|-------------------|--------|
| Frame time | [16.67ms] | [estimate] | [OK/WARNING/OVER/NOT ASSESSED] |
| Memory | [target] | [estimate] | [OK/WARNING/OVER/NOT ASSESSED] |
| Load time | [target] | [estimate] | [OK/WARNING/OVER/NOT ASSESSED] |
| Draw calls | [target] | [estimate] | [OK/WARNING/OVER/NOT ASSESSED] |

### Hotspots Identified
| # | Location | Issue | Estimated Impact | Fix Effort |
|---|----------|-------|------------------|------------|

### Optimization Recommendations (Priority Order)
1. **[Title]** — [Description]
   - Location: [file:line]
   - Expected gain: [estimate]
   - Risk: [Low/Med/High]
   - Approach: [How to implement]

### Quick Wins (< 1 hour each)
- [Simple optimization 1]

### Requires Investigation
- [Area that needs actual runtime profiling to confirm impact]
```

Output the report with a summary: top 3 hotspots, estimated headroom against
each budget that is set — for a metric with none, `no budget set — headroom not
assessed` — and recommended next action.
输出报告并附摘要：前三名热点、相对每个已设置预算的估算余量——对于没有预算的指标，写 `no budget set — headroom not assessed`——以及建议的下一步动作。

---

## Phase 5: Scope and Timeline Decision
## 阶段 5：范围与时间线决策

Activate this phase only if any hotspot has Fix Effort rated M or L.
仅当任何热点的修复工作量被评为 M 或 L 时才激活本阶段。

Present significant-effort items and ask the user to choose for each:
呈现高工作量事项，并请用户为每一项选择：

- **A) Implement the optimization** (proceed with fix now or schedule it — at `workflow: minimal`, which has no sprints, add it to the brief's build order)
- **B) Reduce feature scope** (run `/scope-check [feature]` to analyze trade-offs)
- **C) Accept the performance hit and defer to Polish phase** (log as known issue)
- **D) Escalate to technical-director for an architectural decision** (run `/architecture-decision`)
- **A) 实现优化**（现在着手修复或安排它——在 `workflow: minimal` 下没有冲刺，可将其加入简报的构建顺序）
- **B) 缩减功能范围**（运行 `/scope-check [feature]` 分析取舍）
- **C) 接受性能损失并推迟到 Polish 阶段**（记录为已知问题）
- **D) 上报 technical-director 做架构决策**（运行 `/architecture-decision`）

If multiple items are deferred to Polish (choice C), record them under `### Deferred to Polish`.
如果多个事项被推迟到 Polish（选项 C），将它们记录在 `### Deferred to Polish` 之下。

---

## Verdict
## 判定

Close every run that produced a report — whether or not Phase 5 ran — with:
Verdict: **COMPLETE** — performance profile generated (saved to
`production/polish/[scope]-report-[date].md` if the write was approved). The only
other outcome is the `NOT ASSESSED — NO DATA` path above.
用以下内容结束每一次产出了报告的运行——无论阶段 5 是否运行：
判定：**COMPLETE**——性能剖析已生成（若写入获批准，已保存至 `production/polish/[scope]-report-[date].md`）。唯一的另一种结果是上方的 `NOT ASSESSED — NO DATA` 路径。

---

## Phase 6: Next Steps
## 阶段 6：后续步骤

- If bottlenecks require architectural change: run `/architecture-decision`.
- If scope reduction is needed: run `/scope-check [feature]`.
- To schedule optimizations: run `/sprint-plan update` (at `workflow: minimal`, which has no sprints, add them to the brief's build order instead).
- 若瓶颈需要架构变更：运行 `/architecture-decision`。
- 若需要缩减范围：运行 `/scope-check [feature]`。
- 若要安排优化：运行 `/sprint-plan update`（在 `workflow: minimal` 下没有冲刺，改为将它们加入简报的构建顺序）。

### Rules
### 规则
- Never optimize without measuring first — gut feelings about performance are unreliable
- Recommendations must include estimated impact — "make it faster" is not actionable
- Profile on target hardware, not just development machines
- Static analysis (this skill) identifies candidates; runtime profiling confirms
- 绝不在未先测量的情况下优化——对性能的直觉不可靠
- 建议必须包含估算影响——“让它更快”不可操作
- 在目标硬件上剖析，而不只是在开发机上
- 静态分析（本技能）识别候选对象；运行时剖析加以确认
