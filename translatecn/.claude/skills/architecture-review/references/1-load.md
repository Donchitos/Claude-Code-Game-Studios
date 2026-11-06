# /architecture-review — Phase 1: Load Everything
# /architecture-review — 阶段 1：加载全部内容

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/architecture-review` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 1: Load Everything
## 阶段 1：加载全部内容

**In this file:**
**本文件内容：**

- Phase 1a — L0: Summary Scan (fast, low tokens)
- 阶段 1a — L0：摘要扫描（快速、低 token 消耗）
- Phase 1b — L1/L2: Targeted Section Load
- 阶段 1b — L1/L2：按节定向加载
- Design Documents
- 设计文档
- Architecture Documents
- 架构文档
- Engine Reference
- 引擎参考
- Project Standards
- 项目标准

### Phase 1a — L0: Summary Scan (fast, low tokens)
### 阶段 1a — L0：摘要扫描（快速、低 token 消耗）

**Freshness check before any scan.** A prior report can stand in for this run
only if nothing it rests on has changed: the documents, the engine reference,
the project config, this skill, and the kind of review that produced it.
**任何扫描之前先做新鲜度检查。** 只有在其依赖的一切都未改变时，先前的报告才能
代替本次运行：文档、引擎参考、项目配置、此技能，以及产出它的评审类型。

In `rtm` mode, skip the check and say so — *"Freshness check: not run — rtm
builds the matrix fresh, because stories and tests change without any review
input changing."*
在 `rtm` 模式下，跳过该检查并说明 — *"Freshness check: not run — rtm
每次重新构建矩阵，因为故事和测试会在评审输入未改变的情况下发生变化。"*

Otherwise locate the latest prior report — Glob
`docs/architecture/architecture-review-*.md` and take the newest — and check
**the review inputs**: every file the phases below read that can change a
finding or the verdict. `[engine]` is the lowercased `engine.name` from
`project.yaml`, the value Phase 5 uses; with no engine configured, leave the two
engine-reference paths out.
否则定位最近的先前报告 — 用 Glob 匹配
`docs/architecture/architecture-review-*.md` 并取最新的一个 — 然后检查
**评审输入**：下文各阶段会读取的、可能改变某项发现或裁决的每一个文件。`[engine]` 是
`project.yaml` 中 `engine.name` 的小写形式，即阶段 5 使用的值；若未配置引擎，
则省略两个引擎参考路径。

```
Bash: bash .claude/scripts/review-receipts.sh check "[latest-report]" docs/architecture/adr-*.md design/gdd/*.md docs/architecture/tr-registry.yaml docs/architecture/architecture.md docs/engine-reference/[engine]/*.md docs/engine-reference/[engine]/modules/*.md project.yaml .claude/docs/technical-preferences.md docs/consistency-failures.md .claude/skills/architecture-review/SKILL.md .claude/skills/architecture-review/references/*.md
```

Phase 8 stamps the same list into this run's report; keep the two identical,
and add any file a phase starts reading to both. The check also compares every
file the prior report stamped, named here or not, and prints `GONE:` for one
that no longer exists.
阶段 8 会把同一份清单盖章写入本次运行的报告；保持两者完全一致，
并把任何阶段开始读取的文件同时加入两者。该校验还会比对先前报告
盖章过的每一个文件（无论此处是否列出），并对已不存在的文件打印 `GONE:`。

Then read the prior report's `Mode:` and `Workflow:` lines. It **covers** this
run only when its Mode is this run's mode (for `single-gdd`, the same path) or
`full`, and its Workflow is this run's resolved `workflow` or `full`. A report
without those lines was written before they existed and covers nothing.
然后读取先前报告的 `Mode:` 和 `Workflow:` 行。仅当其 Mode 是本次运行的模式
（对 `single-gdd` 而言是同一路径）或 `full`，且其 Workflow 是本次运行解析出的
`workflow` 或 `full` 时，它才**覆盖**本次运行。缺少这些行的报告写于这些行
出现之前，不覆盖任何内容。

- **Any `UNRESOLVED`** — check this FIRST; it disqualifies every option
  below. A glob matched no file, so that whole document class was never
  examined and the comparison covered less than it appears to. Say which
  pattern came back unresolved, and neither stand on the prior report nor
  scope a re-run from it: an ADR or GDD directory that is empty, renamed or
  misspelled is a finding about the project. Run the review as asked; its
  verdict is NOT ASSESSED for the missing class (Phase 7), never a stop with
  no report. Never read a set of `UNCHANGED` lines as
  "everything is current" while an `UNRESOLVED` line is present — the set
  compared was not the set requested.
- **任何 `UNRESOLVED`** — 优先检查这一项；它会使下面的每一个选项都失效。
  某个 glob 未匹配到任何文件，因此整个文档类别从未被检查，比对覆盖的范围
  比看上去更小。说明哪个模式返回了未解析结果，并且既不要依赖先前报告，
  也不要据此划定重跑范围：一个为空、被重命名或拼写错误的 ADR 或 GDD 目录
  本身就是关于项目的一项发现。按请求执行评审；其裁决对缺失的类别为
  NOT ASSESSED（阶段 7），绝不可在没有报告的情况下停下。只要存在
  `UNRESOLVED` 行，就绝不可把一组 `UNCHANGED` 行解读为"一切都是最新的" —
  被比对的内容集并不是所请求的内容集。
- **The prior report does not cover this run** — check this second, whatever
  the other lines say. Say why: *"The last report was a [mode] review at
  workflow [tier]; it does not cover this run."* Run the review as asked.
  Never offer to stand on it or to scope a re-run from it.
- **先前报告不覆盖本次运行** — 其次检查这一项，无论其它行怎么说。说明原因：
  *"上次报告是在 workflow [tier] 下进行的 [mode] 评审；它不覆盖本次运行。"*
  按请求执行评审。绝不要提议依赖它或据此划定重跑范围。
- **Everything `UNCHANGED`** — nothing this review reads has changed since
  that report; re-running reproduces it. Surface the prior report's date,
  mode and verdict and offer via `AskUserQuestion`: `[A] Stand on the prior
  report (Recommended)` / `[B] Re-run the full review anyway` — `guided`
  proceeds with [A] and notes it; `autonomous` logs via `log_decision` and
  stands on the prior report.
- **全部 `UNCHANGED`** — 自那份报告以来，本次评审会读取的内容没有任何改变；
  重跑只会复现它。呈现先前报告的日期、模式和裁决，并通过 `AskUserQuestion`
  提供选项：`[A] Stand on the prior report (Recommended)` / `[B] Re-run the full
  review anyway` — `guided` 模式按 [A] 继续并注明；`autonomous` 模式通过
  `log_decision` 记录并依赖先前报告。
- **Only GDDs or ADRs `CHANGED`/`NEW`** — name them, then scope instead of
  re-running everything: recommend `/architecture-review single-gdd [path]`
  for just the changed systems. A full re-run stays available on request, and
  a `NEW` ADR warrants one.
- **仅有 GDD 或 ADR 为 `CHANGED`/`NEW`** — 列出它们，然后划定范围，而不是
  重跑全部：对仅发生变更的系统推荐 `/architecture-review single-gdd [path]`。
  完整的重跑仍可按请求执行，而 `NEW` 的 ADR 值得完整重跑一次。
- **Anything else `CHANGED`, `NEW` or `GONE`** — a deleted GDD or ADR, the TR
  registry, `architecture.md`, the engine reference, `project.yaml`,
  `technical-preferences.md`, `consistency-failures.md`, or this skill's own
  files. These reach every phase, so recommend re-running the review as
  asked, never a `single-gdd` scope, and name each input with what it
  affects — e.g. *"The engine reference changed after the
  last report: its deprecated-API audit, which `/gate-check` reads, was made
  against the old one."*
- **其它任何 `CHANGED`、`NEW` 或 `GONE`** — 被删除的 GDD 或 ADR、TR 注册表、
  `architecture.md`、引擎参考、`project.yaml`、`technical-preferences.md`、
  `consistency-failures.md`，或此技能自身的文件。这些会影响每个阶段，因此建议
  按请求重跑评审，而绝不是 `single-gdd` 范围，并逐个说明每个输入影响什么 —
  例如 *"引擎参考在上次报告之后发生了变化：其中被 `/gate-check` 读取的
  废弃 API 审计是针对旧版本做的。"*
- **`RECEIPT: NONE`** — no prior report, or one written before receipts
  existed. Proceed with the full review; this run's report will carry the
  first stamps.
- **`RECEIPT: NONE`** — 没有先前报告，或报告写于回执功能出现之前。继续执行
  完整评审；本次运行的报告将携带首次盖章。

Before reading any full document, use Grep to extract `## Summary` sections
from all GDDs and ADRs:
在读取任何完整文档之前，使用 Grep 从所有 GDD 和 ADR 中提取 `## Summary` 小节：

```
Grep pattern="## Summary" glob="design/gdd/*.md" output_mode="content" -A 4
Grep pattern="## Summary" glob="docs/architecture/adr-*.md" output_mode="content" -A 3
```

**Fail open on a missing Summary.** Establish the denominator: glob
`design/gdd/*.md` and count **N**. A scan matching fewer than N means those GDDs
predate `## Summary` (`/design-system` emits it, but older GDDs lack it) — never
treat an absent Summary as a system out of scope. A zero-match scan means "no GDD
carries a Summary yet", not "nothing to review": full-read the unmatched set.
**缺少 Summary 时采用失败开放（fail open）策略。** 先确立分母：glob
`design/gdd/*.md` 并计数 **N**。扫描匹配数少于 N 意味着那些 GDD 早于
`## Summary` 存在（`/design-system` 会产出它，但较旧的 GDD 没有）— 绝不要把
缺失的 Summary 视为某个系统不在范围内。零匹配的扫描意味着"尚无任何 GDD
带有 Summary"，而不是"没有可评审的内容"：对未匹配的集合进行完整阅读。

For `single-gdd [path]` mode: use the target GDD's summary to identify which
ADRs reference the same system (Grep ADRs for the system name), then load only
those ADRs' sections per Phase 1b. Skip unrelated GDDs entirely.
对于 `single-gdd [path]` 模式：使用目标 GDD 的摘要来确定哪些 ADR 引用了
同一系统（在 ADR 中 Grep 该系统名称），然后按阶段 1b 仅加载那些 ADR 的
小节。完全不读取无关的 GDD。

For `engine` mode: load ADR sections only — GDDs are not needed for engine checks.
In practice this is the `## Engine Compatibility` scan alone.
对于 `engine` 模式：仅加载 ADR 小节 — 引擎检查不需要 GDD。实际上这仅仅是
`## Engine Compatibility` 扫描。

For `coverage` or `full` mode: proceed to Phase 1b for the full in-scope set.
**This is a section load, not a full-file load** — see below for why, and for the
narrow cases that still justify escalating to a whole document.
对于 `coverage` 或 `full` 模式：进入阶段 1b，处理完整的范围内集合。
**这是按节加载，而不是整文件加载** — 原因见下文，以及仍然有理由升级为
整文档读取的少数情形。

### Phase 1b — L1/L2: Targeted Section Load
### 阶段 1b — L1/L2：按节定向加载

Load the sections the later phases actually consume — **not whole files**. This
skill reads the two largest document sets in the project (every GDD *and* every
ADR); at realistic sizes a full load of both exhausts the context window before
Phase 2 starts, and most of what it loads is narrative this skill never uses.
加载后续阶段实际会用到的小节 — **而不是整个文件**。此技能读取项目中两个
最大的文档集合（每个 GDD *和* 每个 ADR）；在现实的规模下，完整加载两者会在
阶段 2 开始之前就耗尽上下文窗口，而其中加载的大部分内容是此技能从不使用的
叙事。

**Establish the denominator first.** Glob `design/gdd/*.md` and count **N_gdd**;
glob `docs/architecture/adr-*.md` and count **N_adr**. Report both. A section
scan matching fewer than the denominator means those documents lack the section —
**never treat an absent section as an absent document.** The scan narrows the
*read* set; it never shrinks the *in-scope* set.
**先确立分母。** Glob `design/gdd/*.md` 并计数 **N_gdd**；glob
`docs/architecture/adr-*.md` 并计数 **N_adr**。两者都要报告。按节扫描的匹配数
少于分母，意味着那些文档缺少该小节 — **绝不要把缺失的小节当作缺失的文档。**
扫描收窄的是*读取*集合；它从不缩小*范围内*集合。

### Design Documents
### 设计文档

Phase 2 extracts *technical requirements* — data structures, performance
constraints, engine capabilities, cross-system communication, persistence,
threading, platform needs. Those live in a known set of sections; Overview and
Player Fantasy are narrative and yield none.
阶段 2 提取*技术需求* — 数据结构、性能约束、引擎能力、跨系统通信、持久化、
线程、平台需求。这些内容位于一组已知的小节中；Overview 和 Player Fantasy
是叙事的，不会产出任何技术需求。

```
Grep pattern="^## (Detailed Rules|Detailed Design|Formulas|Dependencies|Tuning Knobs|Acceptance Criteria)" glob="design/gdd/*.md" output_mode="content" -A 40
```

Accept **either** `## Detailed Rules` or `## Detailed Design` — the design
standard and the GDD template disagree on the name and they denote the same
required section. Full-read a single GDD only when a scanned section
cross-references material outside itself, or when a GDD matched zero sections
(it predates the template — read it whole and say so).
**要么**接受 `## Detailed Rules`，**要么**接受 `## Detailed Design` — 设计标准
和 GDD 模板对名称意见不一致，但二者指同一个必需小节。仅当被扫描的小节
交叉引用了其自身之外的材料，或某个 GDD 匹配到零个小节时（它早于模板 — 完整
阅读它并说明这一点），才完整读取该单个 GDD。

- `design/gdd/systems-index.md` — the authoritative list of systems; read whole (small, and it is an index)
- `design/gdd/systems-index.md` — 系统的权威清单；完整读取（很小，而且它是一个索引）

### Architecture Documents
### 架构文档

Phases 3–5 need the traceability table, the decision itself, engine claims, and
the dependency edges — not Context, Consequences, Alternatives, Migration Plan or
Validation Criteria, which explain *why* a decision was made.
阶段 3–5 需要可追溯性表格、决策本身、引擎主张以及依赖边 — 而不是 Context、
Consequences、Alternatives、Migration Plan 或 Validation Criteria，后者解释
决策*为何*做出。

```
Grep pattern="^## (Status|Decision|GDD Requirements Addressed|Engine Compatibility|ADR Dependencies|Performance Implications)" glob="docs/architecture/adr-*.md" output_mode="content" -A 30
```

Interpret against **N_adr**, and distinguish the two zero-match cases — they are
not the same finding:
对照 **N_adr** 解读，并区分两种零匹配情形 — 它们不是同一项发现：

| Result | Meaning | Action |
|---|---|---|
| N_adr matches | Normal. | Proceed on the scanned sections. |
| Some ADRs match, some do not | Those ADRs are missing sections. | Record each as a **structural gap** in the Phase 7 report — a missing `## GDD Requirements Addressed` is itself a traceability finding. |
| **0 matches, N_adr > 0** | **Malformed ADRs**, not "no architecture". | "[N_adr] ADRs found, none carries a scannable section — run `/architecture-decision retrofit [file]` on each." Do **not** report zero coverage; that would read as a design failure when it is a format failure. |

| 结果 | 含义 | 操作 |
|---|---|---|
| 匹配 N_adr | 正常。 | 基于已扫描的小节继续。 |
| 部分 ADR 匹配，部分不匹配 | 那些 ADR 缺少小节。 | 在阶段 7 报告中把每一个记录为**结构性缺口** — 缺少 `## GDD Requirements Addressed` 本身就是一项可追溯性发现。 |
| **0 匹配，N_adr > 0** | **ADR 格式错误**，而不是"没有架构"。 | "找到 [N_adr] 个 ADR，没有一个包含可扫描的小节 — 对每一个运行 `/architecture-decision retrofit [file]`。"**不要**报告零覆盖；那会在实际是格式失败时被读作设计失败。 |

Escalate to a full read of one ADR only when judging a conflict needs its
reasoning (Phase 4) — that is a per-ADR decision, not a blanket load.
仅当判断某个冲突需要其推理（阶段 4）时，才升级为完整读取某一 ADR — 这是
针对单个 ADR 的决定，而不是一概全量加载。

- `docs/architecture/architecture.md` if it exists
- `docs/architecture/architecture.md`，若存在

### Engine Reference
### 引擎参考
- `docs/engine-reference/[engine]/VERSION.md`
- `docs/engine-reference/[engine]/breaking-changes.md`
- `docs/engine-reference/[engine]/deprecated-apis.md`
- **Only the module docs the in-scope ADRs actually name** — take the union of
  each ADR's `References Consulted` and `Post-Cutoff APIs Used` fields (already
  captured by the `## Engine Compatibility` scan above) and read those files.
  Reading the whole `modules/` directory loads engine subsystems the project may
  not use at all. If no ADR names any module, read none and note it: Phase 5
  cannot cross-check engine claims that were never made.
- **仅读取范围内 ADR 实际点名的模块文档** — 取每个 ADR 的 `References
  Consulted` 和 `Post-Cutoff APIs Used` 字段的并集（已由上面的
  `## Engine Compatibility` 扫描捕获），然后读取这些文件。读取整个
  `modules/` 目录会加载项目可能完全不会使用的引擎子系统。若没有任何 ADR
  点名模块，则不读取任何模块并注明：阶段 5 无法交叉检查从未提出的引擎主张。

### Project Standards
### 项目标准
- `project.yaml` — `naming.*` and `performance.*`; plus `.claude/docs/technical-preferences.md` for those keys when absent and for forbidden patterns / allowed libraries
- `project.yaml` — `naming.*` 和 `performance.*`；此外，当这些键缺失时，从 `.claude/docs/technical-preferences.md` 获取，并获取禁用模式和允许的库

Report a count: "Loaded [N] GDDs, [M] ADRs, engine: [name + version]."
报告数量："Loaded [N] GDDs, [M] ADRs, engine: [name + version]."
（已加载 [N] 个 GDD、[M] 个 ADR，引擎：[名称 + 版本]。）

**Also read `docs/consistency-failures.md`** if it exists. Extract entries with
Domain matching the systems under review (Architecture, Engine, or any GDD domain
being covered). Surface recurring patterns as a "Known conflict-prone areas" note
at the top of the Phase 4 conflict detection output.
**同时读取 `docs/consistency-failures.md`**（若存在）。提取 Domain 与受评审
系统相匹配的条目（Architecture、Engine，或任何正在覆盖的 GDD 领域）。把反复
出现的模式作为"Known conflict-prone areas"注释，呈现在阶段 4 冲突检测输出的
顶部。

---
