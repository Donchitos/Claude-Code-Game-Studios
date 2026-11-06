# /review-all-gdds — Phase 1: Load Everything
# /review-all-gdds — 阶段 1：加载全部内容

> Part of `/review-all-gdds`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/review-all-gdds` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## Phase 1: Load Everything
## 阶段 1：加载全部内容

**In this file:**
**本文件内容：**

- Phase 1a — L0: Summary Scan (fast, low tokens)
- Phase 1b — Registry Pre-Load (fast baseline)
- Phase 1c — L1/L2: Section Load

- 阶段 1a — L0：摘要扫描（快速、低 token 消耗）
- 阶段 1b — 注册表预加载（快速基线）
- 阶段 1c — L1/L2：分区加载

### Phase 1a — L0: Summary Scan (fast, low tokens)
### 阶段 1a — L0：摘要扫描（快速、低 token 消耗）

Before reading any full document, use Grep to extract `## Summary` sections
from all GDD files:

在读取任何完整文档之前，先用 Grep 从所有 GDD 文件中提取 `## Summary` 分区：

```
Grep pattern="## Summary" glob="design/gdd/*.md" output_mode="content" -A 5
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/gdd/*.md` and count **N**. A scan matching fewer than N means those GDDs
predate `## Summary` — never treat an absent Summary as a system out of scope.
A zero-match scan means "no GDD carries a Summary yet", not "nothing to review".
This review is holistic and loads its in-scope GDDs regardless (see Phase 1c);
the Summary scan only builds the manifest and narrows `since-last-review`, it
never shrinks the review set.

**缺失 Summary 时按开放方式处理（fail open）。** 先确立分母：用 glob 匹配
`design/gdd/*.md` 并计数为 **N**。扫描匹配数少于 N，说明这些 GDD 早于
`## Summary` 存在——绝不要把缺失的 Summary 当作某系统不在范围内。零匹配扫描意味着
“尚无任何 GDD 带有 Summary”，而不是“没有可审查的内容”。本审查具有整体性，无论扫描结果
如何都会加载范围内的 GDD（见阶段 1c）；Summary 扫描只用于构建清单并收窄
`since-last-review`，它绝不会缩减审查集合。

Display a manifest to the user:

向用户显示清单：

```
Found [N] GDDs. Summaries:
  • combat.md — [summary text]
  • inventory.md — [summary text]
  ...
```

```
找到 [N] 个 GDD。摘要：
  • combat.md — [摘要文本]
  • inventory.md — [摘要文本]
  ...
```

For `since-last-review` mode, compute the scope deterministically instead of
reasoning through git history:

对于 `since-last-review` 模式，应以确定性的方式计算范围，而不是通过推理 git 历史：

```
Bash: bash .claude/scripts/review-scope.sh
```

It prints `PRIOR_REVIEW:`, a `CHANGED:` list, and a `DEPS ...:` list of each
changed GDD's declared dependencies. Use those lists as the scope — the
dependency lines are already the "Key deps" expansion, so no second pass is
needed. If `PRIOR_REVIEW: NONE`, a full review is required; fall back to `full`
mode.

它会打印 `PRIOR_REVIEW:`、一个 `CHANGED:` 列表，以及一个 `DEPS ...:` 列表（列出每个
已变更 GDD 所声明的依赖）。把这些列表直接作为范围——依赖行本身就是 “Key deps” 的展开，
因此无需第二轮处理。如果输出 `PRIOR_REVIEW: NONE`，则必须进行完整审查；回退到 `full`
模式。

Show the user which GDDs are in scope based on summaries before doing any full
reads. Only proceed to L1 for the `CHANGED` set plus the GDDs named on the
`DEPS` lines.

在进行任何完整读取之前，基于摘要向用户展示哪些 GDD 在范围内。只为 `CHANGED` 集合加上
`DEPS` 行中点名的 GDD 继续进入 L1。

### Phase 1b — Registry Pre-Load (fast baseline)
### 阶段 1b — 注册表预加载（快速基线）

Before full-reading any GDD, check for the entity registry:

在完整读取任何 GDD 之前，先检查实体注册表：

```
Read path="design/registry/entities.yaml"
```

If the registry exists and has entries, use it as a **pre-built conflict
baseline**: known entities, items, formulas, and constants with their
authoritative values and source GDDs. In Phase 2, grep GDDs for registered
names first — this is faster than reading all GDDs in full before knowing
what to look for.

如果注册表存在且有条目，就把它用作**预构建的冲突基线**：已知实体、物品、公式和常量，
及其权威取值与来源 GDD。在阶段 2 中，先在 GDD 中 grep 已注册的名称——这比在还不知道
要找什么之前就完整读取所有 GDD 更快。

If the registry is empty or absent: proceed without it. Note in the report:
"Entity registry is empty — consistency checks rely on full GDD reads only.
Run `/consistency-check` after this review to populate the registry."

如果注册表为空或不存在：不借助它继续。在报告中注明：
“实体注册表为空——一致性检查仅依赖对 GDD 的完整读取。
本次审查结束后运行 `/consistency-check` 以填充注册表。”

### Phase 1c — L1/L2: Section Load
### 阶段 1c — L1/L2：分区加载

Read whole (small, and every part is used):

整体读取（文件较小，且每一部分都会被用到）：

1. `design/gdd/game-concept.md` — game vision, core loop, MVP definition (or
   `design/game-brief.md`, the one-page brief that replaces it at `rigor: minimal` —
   pitch, core loop, MVP list)
2. `design/gdd/game-pillars.md` if it exists — design pillars and anti-pillars
3. `design/gdd/systems-index.md` — authoritative system list, layers, dependencies, status

1. `design/gdd/game-concept.md` —— 游戏愿景、核心循环、MVP 定义（或在 `rigor: minimal`
   下替代它的一页式简报 `design/game-brief.md` —— 卖点、核心循环、MVP 清单）
2. `design/gdd/game-pillars.md`（若存在）—— 设计支柱与反支柱
3. `design/gdd/systems-index.md` —— 权威系统列表、分层、依赖关系、状态

Read each document by section: find the headings with the Grep tool (pattern `^#`,
content mode) and Read those ranges with offset and limit. A document read whole
is read in ranges the same way, since a whole-file Read over 40 KB is refused.

按分区读取每份文档：用 Grep 工具（pattern 为 `^#`，content 模式）找到标题，再用 offset
和 limit 读取对应区间。即便是整体读取的文档，也以同样方式按区间读取，因为超过 40 KB 的
整文件 Read 会被拒绝。

Then, for **every in-scope system GDD**, load the sections this review actually
consumes — **not the whole file**:

然后，对**每一个范围内的系统 GDD**，只加载本次审查真正用到的分区——**而不是整个文件**：

```
Grep pattern="^## (Dependencies|Detailed Rules|Detailed Design|Formulas|Tuning Knobs|Acceptance Criteria|Player Fantasy)" glob="design/gdd/*.md" output_mode="content" -A 40
```

That list is not a guess — it is exactly the union the Parallel Execution
contract below already enumerates: Phase 2 needs Dependencies, Detailed
Design/Rules, Formulas, Tuning Knobs and Acceptance Criteria; Phase 3 needs
Player Fantasy and progression/reward structure. Overview is narrative restated
by the Summary this skill already scanned in Phase 1a, and Edge Cases feeds no
checklist item here (`/design-review` owns per-GDD completeness). Loading them
put content in three context windows — this one and both sub-agents' — that no
checklist item ever read.

这份清单并非猜测——它正是下文并行执行契约（Parallel Execution contract）已经列出的并集：
阶段 2 需要 Dependencies、Detailed Design/Rules、Formulas、Tuning Knobs 和
Acceptance Criteria；阶段 3 需要 Player Fantasy 以及进阶/奖励结构。Overview 是被摘要
复述的叙述内容，而该摘要本技能已在阶段 1a 扫描过；Edge Cases 在此不为任何检查清单项提供
输入（`/design-review` 负责单个 GDD 的完整性）。加载它们会把内容塞进三个上下文窗口——
本窗口以及两个子智能体的窗口——而这些内容从未被任何检查清单项读取过。

Accept **either** `## Detailed Rules` or `## Detailed Design`; the design standard
and the GDD template disagree on the name and they denote the same section.

接受 `## Detailed Rules` **或** `## Detailed Design` 中的任意一个；设计标准与 GDD 模板
对这两个名称的用法不一致，但它们指的是同一个分区。

**Escalate to a full read of one GDD** when a scanned section cross-references
material outside itself, or when a GDD matched **zero** sections — that GDD
predates the template, and a zero-match there means "unstructured", not "empty".
Never let a zero-match silently drop a system: the scan narrows the *read*, it
never shrinks the *review set*.

**升级为完整读取某个 GDD** 的情形：当被扫描的分区交叉引用了其自身之外的材料时，或当某个
GDD 匹配到**零**个分区时——该 GDD 早于模板存在，此处零匹配意味着“无结构”，而不是“为空”。
绝不要让零匹配悄悄丢弃一个系统：扫描收窄的是*读取*，它绝不会缩减*审查集合*。

Report: "Loaded [N] system GDDs covering [M] systems. Pillars: [list]. Anti-pillars: [list]."

报告：“已加载 [N] 个系统 GDD，覆盖 [M] 个系统。支柱：[清单]。反支柱：[清单]。”

If fewer than 2 system GDDs exist (count the files present; an empty one is handled under NOT ASSESSED in Phase 5, not here), stop:
> "Cross-GDD review requires at least 2 system GDDs. Write more GDDs first,
> then re-run `/review-all-gdds`."

如果系统 GDD 少于 2 个（统计实际存在的文件；空文件在阶段 5 的 NOT ASSESSED 下处理，
不在此处处理），则停止：
> “跨 GDD 审查至少需要 2 个系统 GDD。请先编写更多 GDD，
> 然后重新运行 `/review-all-gdds`。”

---
