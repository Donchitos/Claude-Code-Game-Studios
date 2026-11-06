---
name: soak-test
description: "Soak test protocol for extended play — what to observe and log for slow leaks, fatigue, late-appearing edge cases."
argument-hint: "[duration: 30m | 1h | 2h | 4h] [focus: memory | stability | balance | all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/soak-test/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: soak-test
description: "长时游玩的长时测试协议 — 观察并记录缓慢泄漏、疲劳、晚期出现的边界情况。"
argument-hint: "[duration: 30m | 1h | 2h | 4h] [focus: memory | stability | balance | all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/soak-test/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅在重大选择上询问 · 自主模式记录后继续；
`automation_always_ask` 类别总是询问）。

# Soak Test
# 长时测试

A soak test (also called an endurance test) is an extended play session run
with specific observation goals. Unlike a smoke check (broad critical path,
~10 min) or a single-feature playtest (~30 min), a soak test runs for **30
minutes to several hours** to surface:
长时测试（也称为耐久测试）是带有特定观察目标的长时间游玩会话。与
冒烟检查（覆盖广泛关键路径，约 10 分钟）或单功能试玩（约 30 分钟）不同，
长时测试运行 **30 分钟到数小时** 以暴露：

- **Memory leaks** — gradual heap growth that only appears after scene transitions
- **Performance drift** — frame time degradation that worsens over time
- **State accumulation bugs** — issues that only appear after N repetitions
  of a mechanic (inventory full, score overflow, AI state corruption)
- **Fun fatigue** — mechanics that feel good in a first session but grow
  repetitive over extended play
- **Content exhaustion** — the point where players run out of novel content
- **内存泄漏** — 仅在场景切换后才出现的渐进式堆增长
- **性能漂移** — 随时间恶化的帧时间下降
- **状态累积缺陷** — 只有在某个机制重复 N 次后才出现的问题
  （背包满、分数溢出、AI 状态损坏）
- **乐趣疲劳** — 在首次会话中感觉良好、但在长时间游玩后变得
  重复的机制
- **内容枯竭** — 玩家耗尽新颖内容的那个点

**This skill generates the observation protocol and analysis harness — the
human does the actual playing.**
**此技能生成观察协议与分析框架 — 实际游玩由人来做。**

**Output:** `production/qa/soak-test-[date]-[duration].md`
**输出：** `production/qa/soak-test-[date]-[duration].md`

**When to run:**
- Polish phase — before `/gate-check release`
- After fixing a memory or stability issue (regression soak)
- When extended play has not been formally tracked
**何时运行：**
- 打磨阶段 — 在 `/gate-check release` 之前
- 修复内存或稳定性问题之后（回归长时测试）
- 当长时游玩尚未被正式跟踪时

---

## 1. Parse Arguments
## 1. 解析参数

**Duration** (default: `1h`):
- `30m` — short soak; suitable for testing a single mechanic or scene
- `1h` — standard soak; covers most common leak categories
- `2h` — extended soak; recommended for first full Polish soak
- `4h` — deep soak; required for games with long session design (RPGs, sims)
**时长**（默认：`1h`）：
- `30m` — 短时测试；适合测试单个机制或场景
- `1h` — 标准长时测试；覆盖大多数常见的泄漏类别
- `2h` — 延长测试；建议用于首次完整打磨阶段的长时测试
- `4h` — 深度测试；对采用长会话设计的游戏（RPG、模拟类）为必需

**Focus** (default: `all`):
- `memory` — focus on heap size, object count, leak patterns
- `stability` — focus on crash/freeze/hang detection
- `balance` — focus on fun fatigue, content exhaustion, difficulty perception
- `all` — all of the above
**重点**（默认：`all`）：
- `memory` — 聚焦堆大小、对象数量、泄漏模式
- `stability` — 聚焦崩溃/卡死/挂起检测
- `balance` — 聚焦乐趣疲劳、内容枯竭、难度感知
- `all` — 以上全部

---

## 2. Load Context
## 2. 加载上下文

Read:
- `project.yaml` — `engine.name` (for engine-specific memory monitoring
  guidance) and `performance.*` budgets (memory ceiling, target FPS); for any
  key absent or empty (including when `project.yaml` has no `performance` or
  `engine` block), fall back to `.claude/docs/technical-preferences.md`
- `design/gdd/game-concept.md` — intended session length (for comparison against
  soak duration), core loop description (or `design/game-brief.md`, the one-page
  brief that replaces it at `rigor: minimal` — core loop, and session length only
  if its "Who it's for" line states one). Read it by section: find the headings you
  need with the Grep tool (pattern `^#`, content mode) and Read those ranges
  with offset and limit.
- Most recent file in `production/qa/playtests/` — prior playtest findings
  (to avoid re-documenting known issues)
- Most recent file in `production/qa/qa-plan-*.md` — current sprint test coverage
  (to understand what has been formally tested vs. what the soak covers)
读取：
- `project.yaml` — `engine.name`（用于引擎专属的内存监控
  指导）与 `performance.*` 预算（内存上限、目标 FPS）；对于任何
  缺失或为空的键（包括 `project.yaml` 没有 `performance` 或
  `engine` 块的情况），回退到 `.claude/docs/technical-preferences.md`
- `design/gdd/game-concept.md` — 预期会话时长（用于与
  长时测试时长对比）、核心循环描述（或 `design/game-brief.md`，即在 `rigor: minimal`
  时取代它的一页式简报 — 核心循环，以及仅在其"Who it's for"一行
  给出时才有的会话时长）。按小节读取：用 Grep 工具（模式 `^#`，content 模式）
  找到你需要的标题，再用 offset 与 limit 读取那些范围。
- `production/qa/playtests/` 中最近的文件 — 既往试玩发现
  （以避免重复记录已知问题）
- `production/qa/qa-plan-*.md` 中最近的文件 — 当前冲刺的测试覆盖
  （以了解哪些已被正式测试 vs. 长时测试覆盖了什么）

Note any performance budget targets (`performance.*` from `project.yaml`, else `.claude/docs/technical-preferences.md`):
- Memory ceiling: [N MB, or "not set"]
- Target FPS: [N, or "not set"]
- Frame budget: [N ms, or "not set"]
记录任何性能预算目标（`project.yaml` 中的 `performance.*`，否则用 `.claude/docs/technical-preferences.md`）：
- 内存上限：[N MB，或"未设置"]
- 目标 FPS：[N，或"未设置"]
- 帧预算：[N ms，或"未设置"]

---

## 3. Define Observation Checkpoints
## 3. 定义观察检查点

Based on duration, generate timed checkpoints:
根据时长生成定时检查点：

**30m soak**: T+0, T+10, T+20, T+30
**1h soak**: T+0, T+15, T+30, T+45, T+60
**2h soak**: T+0, T+20, T+40, T+60, T+80, T+100, T+120
**4h soak**: T+0, T+30, T+60, T+90, T+120, T+180, T+240
**30m 长时测试**：T+0、T+10、T+20、T+30
**1h 长时测试**：T+0、T+15、T+30、T+45、T+60
**2h 长时测试**：T+0、T+20、T+40、T+60、T+80、T+100、T+120
**4h 长时测试**：T+0、T+30、T+60、T+90、T+120、T+180、T+240

At each checkpoint, the observer records the observation items defined in
Phase 4.
在每个检查点，观察者记录阶段 4 定义的观察项。

---

## 4. Generate the Soak Test Protocol
## 4. 生成长时测试协议

### Memory / Stability observation items (if focus = memory or all)
### 内存 / 稳定性观察项（若 focus = memory 或 all）

Engine-specific monitoring guidance.
引擎专属监控指导。

> **Record the unit the tool shows; never convert, and never assume one.**
> A soak test looks for **growth**, so every threshold below is a *ratio or a
> delta against this session's own T+0 baseline* — which is unit-agnostic and
> stays correct however the editor reports the number. Write the unit down at
> T+0 exactly as displayed and use it consistently for the rest of the run.
> **记录工具显示的単位；绝不换算，也绝不假定单位。**
> 长时测试寻找的是**增长**，因此下文每个阈值都是*相对本次会话自身 T+0 基线的
> 比值或增量* — 它与单位无关，无论编辑器如何报告该数值都保持正确。
> 在 T+0 时按显示原样写下单位，并在本次运行余下部分一致地使用它。

> **NOT SOURCEABLE — the tool, panel and counter names below are not covered by
> `docs/engine-reference/`**: Godot's Debugger → Monitors and its memory
> counters, Unity's Memory Profiler and its fields, Unreal's `stat memory`. Mark
> them so in the protocol: they are pointers for the tester to confirm in their
> own editor at T+0, not verified paths. If no memory tool can be found, nothing
> was measured, and the Verdict section's NOT ASSESSED applies.
> **NOT SOURCEABLE — 下文的工具、面板与计数器名称不在
> `docs/engine-reference/` 的覆盖范围内**：Godot 的 Debugger → Monitors 及其内存
> 计数器、Unity 的 Memory Profiler 及其字段、Unreal 的 `stat memory`。在协议中
> 如此标记它们：它们是供测试者在 T+0 时于自己的编辑器中确认的指引，而非已验证的路径。
> 若找不到任何内存工具，则什么都没被测量，裁定小节的 NOT ASSESSED 适用。

**Godot 4:**
- Open Debugger → Monitors tab; track `Memory → Static Memory` and
  `Object Count → Objects` across checkpoints
- Record: Static Memory (**unit as displayed**), Object Count, Orphan Nodes count
- Alert threshold: Memory growth > 20% from T+0 after the first 15 minutes
  (some growth on load is expected; sustained growth indicates a leak)
- **Orphan Nodes is the one absolute number worth watching**: it should return to
  its T+0 value after a scene unload. A ratio hides that; a non-zero floor that
  keeps rising is a leak regardless of units
**Godot 4：**
- 打开 Debugger → Monitors 标签页；跨检查点跟踪 `Memory → Static Memory` 与
  `Object Count → Objects`
- 记录：Static Memory（**按显示单位**）、Object Count、Orphan Nodes 数量
- 告警阈值：前 15 分钟后，内存相对 T+0 增长 > 20%
  （加载时有些增长是预期的；持续增长表明存在泄漏）
- **Orphan Nodes 是唯一值得关注的绝对数值**：场景卸载后它应回到
  其 T+0 值。比值会掩盖这一点；一个持续上升的非零底数
  无论单位如何都是泄漏

**Unity:**
- Open Memory Profiler (Window → Analysis → Memory Profiler)
- Record: Total Reserved Memory, GC Allocated, Object Count at each checkpoint
  (**units as displayed**)
- Alert threshold: GC Allocated growing monotonically across 3+ checkpoints —
  a monotonicity check, deliberately unit-free
**Unity：**
- 打开 Memory Profiler（Window → Analysis → Memory Profiler）
- 在每个检查点记录：Total Reserved Memory、GC Allocated、Object Count
  （**按显示单位**）
- 告警阈值：GC Allocated 在 3 个以上检查点间单调增长 —
  这是一项单调性检查，刻意不依赖单位

**Unreal Engine:**
- Use `stat memory` console command at each checkpoint
- Record: Physical Memory Used, Physical Memory Available (**units as displayed**)
- Alert threshold: Physical Memory Used growth **> 20% over the full soak**,
  measured against this run's T+0. An absolute threshold such as "> 50MB"
  silently assumes both the unit *and* a project scale — 50MB is a rounding
  error for one game and a catastrophe for another
**Unreal Engine：**
- 在每个检查点使用 `stat memory` 控制台命令
- 记录：Physical Memory Used、Physical Memory Available（**按显示单位**）
- 告警阈值：Physical Memory Used 增长**超过整个长时测试的 20%**，
  以本次运行的 T+0 为基准测量。诸如"> 50MB"之类的绝对阈值
  会静默假定单位*以及*项目规模 — 50MB 对一个游戏是舍入
  误差，对另一个游戏则是灾难

### Stability observation items (if focus = stability or all)
### 稳定性观察项（若 focus = stability 或 all）

At each checkpoint, note:
- [ ] No crash, hang, or freeze occurred since last checkpoint
- [ ] Frame rate still within target budget ([target FPS] fps)
- [ ] Audio still playing correctly (no desync or silence)
- [ ] All HUD elements still rendering correctly
- [ ] Input responding as expected (no input loss or lag spike)
在每个检查点，记录：
- [ ] 自上个检查点以来未发生崩溃、挂起或卡死
- [ ] 帧率仍在目标预算内（[target FPS] fps）
- [ ] 音频仍在正确播放（无不同步或静音）
- [ ] 所有 HUD 元素仍正确渲染
- [ ] 输入按预期响应（无输入丢失或延迟尖峰）

### Balance / fatigue observation items (if focus = balance or all)
### 平衡 / 疲劳观察项（若 focus = balance 或 all）

Collect subjective observations at each checkpoint:
- [ ] Core mechanic still feels rewarding (Y/N)
- [ ] Perceived difficulty level: [too easy / appropriate / too hard]
- [ ] Any "I've seen this before" moments since last checkpoint? (novel content exhaustion)
- [ ] Any moment of frustration since last checkpoint? Note cause.
- [ ] Any moment of peak engagement since last checkpoint? Note cause.
在每个检查点收集主观观察：
- [ ] 核心机制仍感觉有回报（Y/N）
- [ ] 感知难度水平：[过于简单 / 合适 / 过于困难]
- [ ] 自上个检查点以来是否有"这个我见过"的时刻？（新颖内容枯竭）
- [ ] 自上个检查点以来是否有挫败时刻？记录原因。
- [ ] 自上个检查点以来是否有投入度高峰时刻？记录原因。

---

## 5. Generate the Protocol Document
## 5. 生成协议文档

```markdown
# Soak Test Protocol

> **Date**: [date]
> **Duration**: [duration]
> **Focus**: [memory | stability | balance | all]
> **Engine**: [engine]
> **Generated by**: /soak-test

---

## Pre-Session Setup

Before starting the soak:

- [ ] Game is running from a **fresh launch** (not resumed from a prior session)
- [ ] All background applications closed (minimise OS memory interference)
- [ ] Performance monitoring tool open and recording:
  - **Godot**: Debugger → Monitors tab → Memory section visible
  - **Unity**: Memory Profiler window open
  - **Unreal**: `stat memory` ready in console
  - Tool actually used, as named in this editor: [record it — the names above
    are NOT SOURCEABLE from `docs/engine-reference/`; none found → NOT ASSESSED]
- [ ] Soak target confirmed: [session design intent from game concept]
- [ ] Prior known issues to watch for: [from most recent playtest / qa-plan]

---

## Baseline (T+0) — Record Before Playing

| Metric | Baseline Value |
|--------|---------------|
| Memory / Heap | [record before first frame of gameplay] |
| Object Count | [record] |
| FPS (first 30 seconds) | [record] |
| [Engine-specific metric] | [record] |

---

## Checkpoint Log

### T+[N] minutes

**Memory / Stability** *(if applicable)*:

| Metric | Value | Δ from Baseline | Alert? |
|--------|-------|-----------------|--------|
| Memory / Heap | | | |
| Object Count | | | |
| FPS | | | |
| Crashes / Hangs | | | |

**Stability checks**:
- [ ] No crash or hang since last checkpoint
- [ ] Frame rate within budget ([N] fps target)
- [ ] Audio correct
- [ ] HUD rendering correctly
- [ ] Input responding correctly

**Balance / Fatigue** *(if applicable)*:
- Core mechanic still rewarding: Y / N
- Difficulty perception: too easy / appropriate / too hard
- Notable moments: [note any peak engagement or frustration]
- Content exhaustion signs: Y / N — [describe]

**Free observations**:
*(Note anything unexpected observed since the last checkpoint)*

---

[Repeat Checkpoint Log section for each timed checkpoint]

---

## Post-Session Analysis

### Memory Trend

| Checkpoint | Memory | Δ/hr extrapolated |
|------------|--------|-------------------|
| T+0 | | |
| [T+N] | | |

**Leak detected?** Y / N
**Estimated time to OOM at current rate**: [N hours / not applicable]

### Stability Summary

Total crashes: [N]
Total hangs: [N]
Worst FPS observed: [N] fps at [checkpoint]
Performance degradation: stable / mild / severe

### Balance / Fatigue Summary

Fun curve: [engaged throughout / fatigue onset at T+N / repetitive from start]
Content exhaustion point: [never / at T+N / early]
Difficulty arc: [appropriate / too easy throughout / difficulty spike at T+N]

### Issues Found

| ID | Severity | Checkpoint | Description |
|----|----------|------------|-------------|
| SOAK-001 | S[1-4] | T+[N] | [description] |

---

## Verdict: PASS / PASS WITH CONCERNS / NOT ASSESSED / FAIL

**PASS**: No leaks detected, stability maintained, fun factor consistent
**PASS WITH CONCERNS**: Minor drift or fatigue noted; addressable in Polish
**NOT ASSESSED**: The soak did not run to a length that could show what it looks
for — say how far it got and which checkpoints were never reached
**FAIL**: Memory leak confirmed, stability breach, or severe fun fatigue

> **A short soak cannot return PASS.** Everything this protocol exists to detect
> — slow leaks, fatigue, late-appearing edge cases — is by definition invisible
> early, so a session that ended before the checkpoints it was built around has
> not shown stability; it has shown nothing yet. Record `NOT ASSESSED — reached
> T+[N] of [duration]; checkpoints [list] not reached`. Ranks **above both pass
> values** and **below FAIL**: a crash observed at T+20 is a real finding no
> matter how short the run, and must not be demoted behind the run's length.
> The same applies when the build crashed for reasons unrelated to the soak, when
> no memory instrumentation was available (nothing was measured, so "no leaks
> detected" means "no leaks could have been detected"), or when the protocol was
> written but never executed — a protocol document is not a result.

---

## Sign-Off

- **Tester**: [name] — [date]
- **QA Lead review**: [name] — [date]
```

---

## 6. Write Output
## 6. 写入输出

Present the protocol summary in conversation, then ask:
在对话中呈现协议摘要，然后询问：

"May I write this soak test protocol to
`production/qa/soak-test-[date]-[duration].md`?"
"我可以把这份长时测试协议写入
`production/qa/soak-test-[date]-[duration].md` 吗？"

Write only after approval.
仅在批准后写入。

After writing:
写入之后：

"Protocol written. To run the soak:
1. Open the file and follow the Pre-Session Setup checklist
2. Record each checkpoint as you play
3. Complete the Post-Session Analysis section when done
4. File bugs from 'Issues Found' to `production/qa/bugs/`
5. Run `/bug-triage sprint` after the session to integrate any S1/S2 issues (at `workflow: minimal`, which has no sprints: `/bug-triage full`)

If the verdict is FAIL, run `/smoke-check` again after fixing the issues."
"Protocol written. To run the soak:
1. Open the file and follow the Pre-Session Setup checklist
2. Record each checkpoint as you play
3. Complete the Post-Session Analysis section when done
4. File bugs from 'Issues Found' to `production/qa/bugs/`
5. Run `/bug-triage sprint` after the session to integrate any S1/S2 issues (at `workflow: minimal`, which has no sprints: `/bug-triage full`)

If the verdict is FAIL, run `/smoke-check` again after fixing the issues."
协议已写入。要运行长时测试：
1. 打开该文件并遵循 Pre-Session Setup 检查清单
2. 游玩时记录每个检查点
3. 完成后填写 Post-Session Analysis 小节
4. 将 "Issues Found" 中的缺陷提交到 `production/qa/bugs/`
5. 会话后运行 `/bug-triage sprint`，以整合任何 S1/S2 问题（在 `workflow: minimal` 下没有冲刺：用 `/bug-triage full`）

若裁决为 FAIL，修复问题后再次运行 `/smoke-check`。

---

## Collaborative Protocol
## 协作协议

- **This skill generates a protocol — humans run it** — never attempt to
  run a soak test automatically. The observations require a human observer.
- **Duration should match the game's session design** — a 5-minute game
  doesn't need a 4h soak; a city-builder might. Use judgment and ask if unclear.
- **First soak should be `all` focus** — narrow focus (memory-only) is for
  regression soaks after a specific fix, not the first pass
- **Ask before writing** — always confirm before creating the protocol file
- **此技能生成协议 — 由人来运行** — 绝不要尝试
  自动运行长时测试。观察需要人类观察者。
- **时长应与游戏的会话设计匹配** — 5 分钟的游戏
  不需要 4 小时长时测试；城市建造类或许需要。运用判断，不清楚时询问。
- **首次长时测试应为 `all` 重点** — 狭窄重点（仅内存）用于
  特定修复之后的回归长时测试，而非第一轮
- **写入前询问** — 创建协议文件之前始终确认
