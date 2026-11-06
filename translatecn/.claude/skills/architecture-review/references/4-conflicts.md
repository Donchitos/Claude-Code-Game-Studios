# /architecture-review — Phase 4: Cross-ADR Conflict Detection
# /architecture-review — 阶段 4：跨 ADR 冲突检测

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 4: Cross-ADR Conflict Detection
## 阶段 4：跨 ADR 冲突检测

Compare every ADR against every other ADR to detect contradictions. A conflict
exists when:
将每个 ADR 与其它所有 ADR 逐一比对，以检测矛盾。当出现以下情况时存在冲突：

- **Data ownership conflict**: Two ADRs claim exclusive ownership of the same data
- **数据所有权冲突**：两个 ADR 都声称对同一数据拥有独占所有权
- **Integration contract conflict**: ADR-A assumes System X has interface Y, but
  ADR-B defines System X with a different interface
- **集成契约冲突**：ADR-A 假定系统 X 具有接口 Y，但 ADR-B 以不同的接口定义系统 X
- **Performance budget conflict**: ADR-A allocates N ms to physics, ADR-B allocates
  N ms to AI, together they exceed the total frame budget
- **性能预算冲突**：ADR-A 为物理分配 N ms，ADR-B 为 AI 分配 N ms，合计超出
  总的帧预算
- **Dependency cycle**: ADR-A says System X initialises before Y; ADR-B says Y
  initialises before X
- **依赖循环**：ADR-A 说系统 X 在 Y 之前初始化；ADR-B 说 Y 在 X 之前初始化
- **Architecture pattern conflict**: ADR-A uses event-driven communication for a
  subsystem; ADR-B uses direct function calls to the same subsystem
- **架构模式冲突**：ADR-A 对某个子系统使用事件驱动通信；ADR-B 对同一子系统
  使用直接函数调用
- **State management conflict**: Two ADRs define authority over the same game state
  (e.g. both Combat ADR and Character ADR claim to own the health value)
- **状态管理冲突**：两个 ADR 对同一游戏状态定义了权威（例如 Combat ADR 和
  Character ADR 都声称拥有生命值）

For each conflict found:
对发现的每个冲突：

```
## Conflict: [ADR-NNNN] vs [ADR-MMMM]
Type: [Data ownership / Integration / Performance / Dependency / Pattern / State]
ADR-NNNN claims: [...]
ADR-MMMM claims: [...]
Impact: [What breaks if both are implemented as written]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR Dependency Ordering
### ADR 依赖排序

After conflict detection, analyse the dependency graph across all ADRs.
冲突检测之后，分析所有 ADR 之间的依赖图。

**Build the graph deterministically — do not trace it by hand:**
**以确定性方式构建图 — 不要手工追踪：**

```
Bash: bash .claude/scripts/adr-dep-graph.sh
```

It collects every `Depends On` edge, finds the cycles and the order, and emits
`ADRS:` / `EDGES:` / `NO_DEPS_SECTION:` / `UNFILLED_DEPS:` / `CYCLE:` /
`BLOCKED_BY_CYCLE:` / `ORDER:`. A model tracing A→B→C→A across
a dozen ADRs eventually misses an edge; the algorithm cannot. It reports
observations, not a verdict — you apply the meaning below.
它收集每条 `Depends On` 边，找出循环与顺序，并输出
`ADRS:` / `EDGES:` / `NO_DEPS_SECTION:` / `UNFILLED_DEPS:` / `CYCLE:` /
`BLOCKED_BY_CYCLE:` / `ORDER:`。一个在十几个 ADR 之间追踪 A→B→C→A 的模型
终究会漏掉一条边；算法则不会。它报告的是观察结果而非裁决 — 含义由你按下文
应用。

**`NO_DEPS_SECTION` and `UNFILLED_DEPS` are load-bearing**: they make "no cycles
because the graph is clean" distinguishable from "no cycles because half the ADRs
declare no dependencies, or left the template's placeholder in the row". Report
the second case as a structural gap, never as a clean graph, and name each
`UNFILLED_DEPS` ADR as unfilled: what it depends on is unknown, not none.
**`NO_DEPS_SECTION` 和 `UNFILLED_DEPS` 是承载关键信息的**：它们使
"没有循环，因为图是干净的"能与"没有循环，因为一半的 ADR 声明没有依赖，或在行中
留下了模板的占位符"区分开来。把第二种情况报告为结构性缺口，绝不要报告为干净的
图，并把每个 `UNFILLED_DEPS` 的 ADR 标记为未填写：它依赖什么未知，而不是没有
依赖。

Then interpret:
然后解读：

1. **Topological sort**: the `ORDER:` row, as emitted — ADRs with no
   dependencies come first (Foundation), ADRs that depend on those come next, etc.
   Do not re-sort it by hand. An ADR in `NO_DEPS_SECTION` or `UNFILLED_DEPS` sits
   in it as if it depended on nothing: mark it so.
1. **拓扑排序**：按输出的 `ORDER:` 行 — 没有依赖的 ADR 排在前面（Foundation），
   依赖它们的 ADR 随后，依此类推。不要手工重新排序。位于 `NO_DEPS_SECTION`
   或 `UNFILLED_DEPS` 中的 ADR 在其中看起来像是不依赖任何东西：请如此标记。
2. **Flag unresolved dependencies**: cross the `EDGES:` list against the `## Status`
   values already scanned in Phase 1b. If ADR-A depends on an ADR that is still
   `Proposed` or does not exist, flag it:
   ```
   ⚠️  ADR-0005 depends on ADR-0002 — but ADR-0002 is still Proposed.
       ADR-0005 cannot be safely implemented until ADR-0002 is Accepted.
   ```
2. **标记未解决的依赖**：将 `EDGES:` 列表与阶段 1b 中已扫描的 `## Status` 值
   交叉比对。若 ADR-A 依赖于仍为 `Proposed` 或根本不存在的 ADR，则标记：
   ```
   ⚠️  ADR-0005 depends on ADR-0002 — but ADR-0002 is still Proposed.
       ADR-0005 cannot be safely implemented until ADR-0002 is Accepted.
   ```
3. **Cycle detection**: every `CYCLE:` line the script emitted is a
   `DEPENDENCY CYCLE` — report each one, with the edges its line shows (one of
   them is the edge to cut). A `BLOCKED_BY_CYCLE:` ADR is on no cycle: it waits
   for one to break, so list it as blocked, never as part of the cycle, and never
   suggest cutting its own edges. Do not re-derive them by hand:
   ```
   🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003
      This cycle must be broken before either can be implemented.
   ```
3. **循环检测**：脚本输出的每一行 `CYCLE:` 都是一个 `DEPENDENCY CYCLE` —
   逐一报告，并附上该行显示的边（其中一条是需要切断的边）。一个
   `BLOCKED_BY_CYCLE:` 的 ADR 并不在循环之中：它在等待某个循环被打破，因此把
   它列为被阻塞，绝不列为循环的一部分，也绝不建议切断它自己的边。不要手工
   重新推导：
   ```
   🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003
      This cycle must be broken before either can be implemented.
   ```
4. **Output recommended implementation order**:
   ```
   ### Recommended ADR Implementation Order (topologically sorted)
   Foundation (no dependencies):
     1. ADR-0001: [title]
     2. ADR-0003: [title]
   Depends on Foundation:
     3. ADR-0002: [title] (requires ADR-0001)
     4. ADR-0005: [title] (requires ADR-0003)
   Feature layer:
     5. ADR-0004: [title] (requires ADR-0002, ADR-0005)
   ```
4. **输出推荐的实现顺序**：
   ```
   ### Recommended ADR Implementation Order (topologically sorted)
   Foundation (no dependencies):
     1. ADR-0001: [title]
     2. ADR-0003: [title]
   Depends on Foundation:
     3. ADR-0002: [title] (requires ADR-0001)
     4. ADR-0005: [title] (requires ADR-0003)
   Feature layer:
     5. ADR-0004: [title] (requires ADR-0002, ADR-0005)
   ```

---
