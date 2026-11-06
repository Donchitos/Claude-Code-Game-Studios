# /prototype — Spike Mode
# /prototype — Spike 模式

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/prototype` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

**Triggered by:** `--spike` flag OR "Mid-production spike" entry choice in Phase 1.

**触发方式：** `--spike` 标志，或第一阶段中选择 "Mid-production spike" 入口。

**Purpose:** Test a specific technical or design question mid-production, without
the overhead of a full concept prototype workflow. No GDD prerequisites. No phase
gate implications. Hard cap: ~4 hours.

**目的：** 在量产中途测试某个具体的技术或设计问题，而不承担完整概念原型工作流的开销。没有 GDD 前置要求。不涉及阶段门禁。硬性上限：约 4 小时。

**When to use:**
- You're in Production and want to test whether a new mechanic should be added
- You're unsure if a technical approach will work before building it properly
- A design change is being considered and you want a quick before/after comparison
- A GDD system is proving harder than expected and you want to prototype the hard part
- You need to confirm target hardware can sustain the required framerate before writing gameplay code (**performance spike** — see below)

**何时使用：**
- 你正处于量产阶段，想测试是否应加入某个新机制
- 在正式构建之前，你不确定某个技术方案能否奏效
- 正在考虑某项设计变更，你想要快速的变更前后对比
- 某个 GDD 系统比预期更难，你想对困难部分做原型
- 在编写玩法代码之前，你需要确认目标硬件能否维持所需帧率（**性能 spike**——见下文）

**Spike Mode workflow (replaces Phases 1–9):**

**Spike 模式工作流（替代第一至第九阶段）：**

1. **Define the spike question** (plain text, not a widget): "What specific question does this spike answer? Give me one sentence: 'Can we [do X] using [approach Y]?'"

1. **定义 spike 问题**（纯文本，不用交互组件）："这个 spike 回答什么具体问题？用一句话告诉我：'我们能用 [方案 Y] [做到 X] 吗？'"

2. **Choose path** — same AskUserQuestion widget as Phase 3 (HTML / Engine / Paper).

2. **选择路径** —— 与第三阶段相同的 AskUserQuestion 交互组件（HTML / Engine / Paper）。

3. **Scope** — maximum 2-3 bullet points. One mechanic, one technical question, nothing else.

3. **范围** —— 最多 2-3 个要点。一个机制、一个技术问题，别无其他。

4. **Build** — first ask "May I create `prototypes/[concept-name]-spike-[date]/` and build the spike there?" Same relaxed standards and header as the concept prototype. Hard cap: 4 hours. If not demonstrable in 4 hours, the question is too large. Split it.

4. **构建** —— 先询问"我可以在 `prototypes/[concept-name]-spike-[date]/` 创建目录并在那里构建 spike 吗？"使用与概念原型相同的宽松标准和文件头。硬性上限：4 小时。如果 4 小时内无法演示，说明问题太大。拆分它。

5. **Observe and decide** — no formal playtest debrief. Ask: "Did the spike answer the question? YES or NO, and why in one sentence."

5. **观察并决定** —— 不做正式的试玩复盘。询问："这个 spike 回答那个问题了吗？YES 或 NO，并用一句话说明原因。"

6. **Write a spike note** (not a full report) to `prototypes/[concept-name]-spike-[date]/SPIKE-NOTE.md` — first ask once for this step and the next, naming both files: "May I write `prototypes/[concept-name]-spike-[date]/SPIKE-NOTE.md` and clear the spike from `production/session-state/active.md`?" The note holds:
   - Question tested
   - Result (YES it works / NO it doesn't / PARTIAL — needs more investigation)
   - What to do next (add to current sprint — at `workflow: minimal`, the brief's build order — / investigate further / abandon the idea)

6. **写一份 spike 记录**（不是完整报告）到 `prototypes/[concept-name]-spike-[date]/SPIKE-NOTE.md` —— 先为这一步和下一步一次性征询同意，并指明两个文件："我可以写入 `prototypes/[concept-name]-spike-[date]/SPIKE-NOTE.md` 并从 `production/session-state/active.md` 中清除这个 spike 吗？"记录包含：
   - 所测试的问题
   - 结果（YES 可行 / NO 不可行 / PARTIAL 部分可行——需要进一步调查）
   - 下一步做什么（加入当前冲刺——在 `workflow: minimal` 下为简报的构建顺序——/ 进一步调查 / 放弃这个想法）

7. **Update `production/session-state/active.md`** to clear the spike and return to the current sprint state (at `workflow: minimal`, the story in progress).

7. **更新 `production/session-state/active.md`**，清除该 spike 并恢复到当前冲刺状态（在 `workflow: minimal` 下，即正在进行的故事）。

**No CD gate. No phase gate. No PROCEED/PIVOT/KILL.** Spike results inform decisions; they don't make them. The developer decides whether to add the mechanic/approach to the sprint backlog (at `workflow: minimal`, to the brief's build order) based on what the spike revealed.

**没有创意总监门禁。没有阶段门禁。没有 PROCEED/PIVOT/KILL。** Spike 的结果只是为决策提供信息；它们不代替决策。开发者根据 spike 所揭示的内容，决定是否把该机制/方案加入冲刺待办（在 `workflow: minimal` 下，即加入简报的构建顺序）。

**Performance spike (special case):** If the game involves demanding rendering —
large open worlds, hundreds of simultaneous physics bodies, heavy particle systems,
complex shaders — run a performance spike before writing gameplay code to confirm
the target hardware can sustain the required framerate. This is distinct from other
spikes in two ways:
- The question is "can the engine render [scene X] at 60fps on [minimum spec hardware]?"
  not "does this mechanic feel good?"
- The output is a benchmark number, not a feel verdict
- No gameplay logic is needed — just the maximum intended scene load (terrain, draw
  calls, physics objects, particles) running at once
- Build time stays within the ~4-hour cap; the spike is setting up the rendering
  load, not the game
- If the answer is NO at this scope, this is an architecture or scope constraint
  that affects everything downstream — better to surface it now than during Sprint 8

**性能 spike（特殊情况）：** 如果游戏涉及高要求的渲染——大型开放世界、数百个同时存在的物理刚体、繁重的粒子系统、复杂着色器——请在编写玩法代码之前运行一次性能 spike，以确认目标硬件能维持所需帧率。它与其他 spike 有两点不同：
- 问题不是"这个机制手感好吗？"，而是"引擎能在 [最低规格硬件] 上以 60fps 渲染 [场景 X] 吗？"
- 产出是一个基准数值，而不是手感判定
- 不需要任何玩法逻辑——只需让预期最大场景负载（地形、绘制调用、物理对象、粒子）同时运行
- 构建时间保持在约 4 小时上限之内；该 spike 搭建的是渲染负载，而不是游戏本身
- 如果在此范围内答案是否定的，这就属于会影响所有下游工作的架构或范围约束——现在暴露它比在第八个冲刺中才发现更好

---
