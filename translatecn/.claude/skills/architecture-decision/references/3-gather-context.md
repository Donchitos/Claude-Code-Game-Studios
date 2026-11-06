# /architecture-decision — Steps 3a and 3b: Gather Context

# /architecture-decision —— 步骤 3a 和 3b：收集上下文

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/architecture-decision` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## 3. Gather context

## 3. 收集上下文

### 3a: Architecture Registry Check (BLOCKING gate) — do this FIRST

### 3a：架构注册表检查（阻断门禁）—— 首先做这个

Read `docs/registry/architecture.yaml`. Extract entries relevant to this ADR's
domain and decision (grep by system name, domain keyword, or state being touched).
Run this before reading any existing ADR — the registry exists specifically so a
new ADR's author does not need to open prior ADRs to learn their binding facts
(state ownership, interface contracts, forbidden patterns).

读取 `docs/registry/architecture.yaml`。提取与该 ADR 的领域和决策相关的条目（按系统名称、领域关键词或涉及的状态进行 grep）。在读取任何现有 ADR 之前先运行这一步 —— 注册表存在的目的正是让新 ADR 的作者无需打开先前的 ADR 就能了解其约束性事实（状态归属、接口契约、禁止模式）。

Present any relevant stances to the user **before** the collaborative design
begins, as locked constraints:

在协作设计开始**之前**，将任何相关的立场作为锁定约束呈现给用户：

```
## Existing Architectural Stances (must not contradict)

State Ownership:
  player_health → owned by health-system (ADR-0001)
  Interface: HealthComponent.current_health (read-only float)
  → If this ADR reads or writes player health, it must use this interface.

Interface Contracts:
  damage_delivery → signal pattern (ADR-0003)
  Signal: damage_dealt(amount, target, is_crit)
  → If this ADR delivers or receives damage events, it must use this signal.

Forbidden Patterns:
  ✗ autoload_singleton_coupling (ADR-0001)
  ✗ direct_cross_system_state_write (ADR-0000)
  → The proposed approach must not use these patterns.
```

If the user's proposed decision would contradict any registered stance, surface
the conflict immediately:

如果用户的提议决策会与任何已注册的立场相矛盾，立即揭示该冲突：

> "⚠️ Conflict: This ADR proposes [X], but ADR-[NNNN] established that [Y] is
> the accepted pattern for this purpose. Proceeding without resolving this will
> produce contradictory ADRs and inconsistent stories.
> Options: (1) Align with the existing stance, (2) Supersede ADR-[NNNN] with
> an explicit replacement, (3) Explain why this case is an exception."

> "⚠️ 冲突：该 ADR 提议 [X]，但 ADR-[NNNN] 已确立 [Y] 是此用途的已采纳模式。在未解决此问题的情况下继续，将产生相互矛盾的 ADR 和不一致的故事。
> 选项：(1) 与现有立场保持一致，(2) 用明确的替代方案取代 ADR-[NNNN]，(3) 说明为什么此情况是例外。"

Do not proceed to Step 4 (collaborative design) until any conflict is resolved
or explicitly accepted as an intentional exception.

在任何冲突得到解决或被明确接受为有意的例外之前，不要进入步骤 4（协作设计）。

### 3b: Existing ADRs and Related GDDs — registry-scoped, never unbounded

### 3b：现有 ADR 与相关 GDD —— 注册表范围内，绝不无边界

The registry (3a) covers *what* prior decisions bind — not always *why*. If the
registry surfaced a directly relevant ADR and its reasoning matters here (not
just its stated facts), read that specific ADR — never glob-and-read every
ADR in `docs/architecture/` on the chance one is relevant. Read it by section:
find the headings you need with the Grep tool (pattern `^#`, content mode)
and Read those ranges with offset and limit.

注册表（3a）覆盖的是先前决策约束了*什么* —— 并不总是*为什么*。如果注册表浮现出一份直接相关的 ADR，且其推理在这里很重要（而不只是其陈述的事实），就读取那份特定的 ADR —— 绝不要用 glob 读取 `docs/architecture/` 中的每一个 ADR 去碰运气。按章节读取它：用 Grep 工具（模式 `^#`，内容模式）找到你需要的标题，然后用 offset 和 limit 读取那些范围。

1. **Map its headings first** (cheap):
   ```
   Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```

1. **先绘制其标题地图**（成本低）：
   ```
   Grep pattern="^## " path="docs/architecture/[adr-file].md" output_mode="content" -n
   ```

2. **Under ~40KB** (`Bash: wc -c "docs/architecture/[adr-file].md"`) — one full
   `Read` is fine; per-call overhead exceeds the savings from bounded reads at
   this size.

2. **约 40KB 以下**（`Bash: wc -c "docs/architecture/[adr-file].md"`）—— 一次完整的 `Read` 即可；在这个体量下，每次调用的开销超过了有界读取节省的开销。

3. **~40KB or larger** — bounded-read only `## Context`, `## Decision`, and
   `## Consequences` (the sections that carry reasoning, not just facts) via
   `Read(offset, limit)` from the heading map.

3. **约 40KB 或更大** —— 只通过标题地图用 `Read(offset, limit)` 有界读取 `## Context`、`## Decision` 和 `## Consequences`（承载推理而不只是事实的章节）。

Read GDDs the same way `/design-system` Step 2b does: only GDDs the registry
or the ADR list names as directly relevant, and only their `## Dependencies`,
`## Formulas`, and `## Edge Cases` sections
(`Grep pattern="^## (Dependencies|Formulas|Edge Cases)" ... -A 40`) — never a
speculative full read of `design/gdd/*.md` looking for anything that might
relate.

以 `/design-system` 步骤 2b 的同样方式读取 GDD：只读取注册表或 ADR 列表指明直接相关的 GDD，并且只读取它们的 `## Dependencies`、`## Formulas` 和 `## Edge Cases` 章节（`Grep pattern="^## (Dependencies|Formulas|Edge Cases)" ... -A 40`）—— 绝不要投机性地完整读取 `design/gdd/*.md` 去寻找任何可能相关的内容。

Skip 3b entirely if the registry already answers everything this decision
needs — most ADRs will.

如果注册表已经回答了该决策所需的一切，就完全跳过 3b —— 大多数 ADR 都会如此。

---
