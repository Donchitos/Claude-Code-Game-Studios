# /create-architecture — Phase 0: Load All Context
# /create-architecture — 阶段 0：加载全部上下文

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.
> `/create-architecture` 的一部分。`SKILL.md` 指明何时读取本文件；它解析出的设置
> 及其后续标题下的规则在此仍然适用。

## Phase 0: Load All Context
## 阶段 0：加载全部上下文

**In this file:**
**本文件内容：**

- 0a. Engine Context (Critical)
- 0a. 引擎上下文（关键）
- 0b. Design Context + Technical Requirements Extraction
- 0b. 设计上下文 + 技术需求提取
- 0c. Existing Architecture Decisions
- 0c. 现有架构决策
- 0d. Generate Knowledge Gap Inventory
- 0d. 生成知识缺口清单
- 0e. Existing Architecture Document
- 0e. 现有架构文档

Before anything else, load the full project context in this order:
在做任何其它事情之前，按以下顺序加载完整的项目上下文：

### 0a. Engine Context (Critical)
### 0a. 引擎上下文（关键）

Read the four project-wide engine documents in full — they are small, and every
part of each is used:
完整读取四份项目级引擎文档 — 它们很小，而且每一份的每一部分都会被用到：

1. `docs/engine-reference/[engine]/VERSION.md`
   → Extract: engine name, version, LLM cutoff, post-cutoff risk levels
1. `docs/engine-reference/[engine]/VERSION.md`
   → 提取：引擎名称、版本、LLM 训练截止点、训练截止后风险等级
2. `docs/engine-reference/[engine]/breaking-changes.md`
   → Extract: all HIGH and MEDIUM risk changes
2. `docs/engine-reference/[engine]/breaking-changes.md`
   → 提取：所有 HIGH 和 MEDIUM 风险的变更
3. `docs/engine-reference/[engine]/deprecated-apis.md`
   → Extract: APIs to avoid
3. `docs/engine-reference/[engine]/deprecated-apis.md`
   → 提取：应避免使用的 API
4. `docs/engine-reference/[engine]/current-best-practices.md`
   → Extract: post-cutoff best practices that differ from training data
4. `docs/engine-reference/[engine]/current-best-practices.md`
   → 提取：与训练数据不同的训练截止后最佳实践

Then read **only the module docs whose domain this game actually uses** —
not the whole `modules/` directory:
然后只读取**本游戏实际使用的领域所对应的模块文档** — 而不是整个
`modules/` 目录：

5. `docs/engine-reference/[engine]/modules/` — glob it to establish what exists,
   then match against the domains present in `design/gdd/systems-index.md`
   (the same domain vocabulary the ADR template uses: Physics, Rendering, UI,
   Audio, Navigation, Animation, Networking, Core, Input). Read the matching
   modules; skip the rest.
   → Extract: current API patterns per domain
5. `docs/engine-reference/[engine]/modules/` — 用 glob 确立存在哪些内容，
   然后与 `design/gdd/systems-index.md` 中出现的领域进行匹配
   （即 ADR 模板使用的同一套领域词汇：Physics、Rendering、UI、
   Audio、Navigation、Animation、Networking、Core、Input）。读取匹配的
   模块；跳过其余部分。
   → 提取：每个领域的当前 API 模式

   A game with no multiplayer system does not need the networking module loaded
   to write its architecture, and loading it costs the same as one that does.
   **If the domain match is ambiguous, read the module** — a missed engine
   constraint is far more expensive here than a redundant read, because this
   phase is where those constraints get baked into the architecture.
   一个没有多人系统的游戏不需要加载 networking 模块来编写其架构，而加载它
   的代价与需要它的项目相同。**若领域匹配有歧义，就读取该模块** — 在此处
   漏掉一项引擎约束，代价远高于一次冗余读取，因为这一阶段正是这些约束被
   固化进架构的地方。

If no engine is configured, stop and prompt:
若未配置引擎，停下并提示：
> "No engine is configured. Run `/setup-engine` first. Architecture cannot be
> written without knowing which engine and version you are targeting."
> （未配置引擎。请先运行 `/setup-engine`。在不知道你所针对的引擎和版本的情况下，
> 无法编写架构。）

### 0b. Design Context + Technical Requirements Extraction
### 0b. 设计上下文 + 技术需求提取

Load the approved design documents and extract technical requirements from each.
Read each one by section: find the headings you need with the Grep tool (pattern
`^#`, content mode) and Read those ranges with offset and limit.
加载已批准的设计文档，并从每一份中提取技术需求。按节读取每一份：用 Grep 工具
（pattern `^#`，content 模式）找到你需要的标题，并用 offset 和 limit 读取那些
范围。

1. `design/gdd/game-concept.md` — game pillars, genre, core loop
2. `design/gdd/systems-index.md` — all systems, dependencies, priority tiers
1. `design/gdd/game-concept.md` — 游戏支柱、类型、核心循环
2. `design/gdd/systems-index.md` — 所有系统、依赖关系、优先级层级

**Check both exist before reading either. Neither is optional here, and both
need an absence branch** — §0a stops for an unconfigured engine, and these two
matter just as much:
**在读取任一文件之前，先检查两者是否都存在。这里两者都不是可选的，且二者都
需要缺失分支** — §0a 会为未配置的引擎而停下，而这两份文件同样重要：

- **`systems-index.md` absent** — stop:
  > "No systems index found. Run `/map-systems` first. An architecture written
  > without it invents layers for systems nobody mapped, and every ADR, epic and
  > story downstream inherits that invention."
  At `minimal` the index is not required (the `workflow` list in SKILL.md) — say so and proceed
  from the brief instead.
- **`systems-index.md` 缺失** — 停下：
  > "No systems index found. Run `/map-systems` first. An architecture written
  > without it invents layers for systems nobody mapped, and every ADR, epic and
  > story downstream inherits that invention."
  > （未找到系统索引。请先运行 `/map-systems`。在没有它的情况下编写的架构，
  > 会为没人绘制过的系统凭空发明分层，而下游的每个 ADR、史诗和故事都会继承
  > 这项发明。）
  在 `minimal` 下索引不是必需的（SKILL.md 中的 `workflow` 列表）— 说明这一点
  并改为基于简报继续。
- **`game-concept.md` absent** — at `standard`/`full`, stop and point at
  `/brainstorm`. At `minimal`, read `design/game-brief.md` in its place; if that
  is absent too, stop — there is no design record to architect against.
- **`game-concept.md` 缺失** — 在 `standard`/`full` 下，停下并指向
  `/brainstorm`。在 `minimal` 下，改为读取 `design/game-brief.md`；若它也不存在，
  停下 — 没有可供架构参照的设计记录。
- **Either present but empty or still template placeholders** — treat as absent.
  Present-but-empty is the case that most looks like present.
- **任一文件存在但为空，或仍是模板占位符** — 视为缺失。存在但为空，是最像
  "存在"的情形。

Do not proceed on a partial read and note it later. This phase is where design
assumptions get baked into ADRs, and an assumption made here is re-derived by
everything downstream rather than re-checked.
不要基于部分读取继续、之后再补注。这一阶段正是设计假设被固化进 ADR 的地方，
而在此处做出的假设会被下游的一切重新推导，而不是被重新检查。
3. Project config — `naming.*` and `performance.*` from `project.yaml` (for any
   key absent or empty, fall back to `.claude/docs/technical-preferences.md`);
   allowed libraries and forbidden patterns from
   `.claude/docs/technical-preferences.md` (not migrated to project.yaml)
3. 项目配置 — 来自 `project.yaml` 的 `naming.*` 和 `performance.*`（对于任何
   缺失或为空的键，回退到 `.claude/docs/technical-preferences.md`）；允许的库和
   禁用模式来自 `.claude/docs/technical-preferences.md`（未迁移到 project.yaml）
4. **Every GDD in `design/gdd/`** — extract technical requirements from the
   sections that carry them, **not from whole files**. Establish the denominator
   first (glob `design/gdd/*.md`, count **N**), then:
   ```
   Grep pattern="^## (Detailed Rules|Detailed Design|Formulas|Dependencies|Tuning Knobs|Acceptance Criteria)" glob="design/gdd/*.md" output_mode="content" -A 40
   ```
   Overview and Player Fantasy are narrative and imply no architecture; the
   scanned set is where rules, numbers, and cross-system contracts live. Accept
   either `## Detailed Rules` or `## Detailed Design` — the design standard and
   the GDD template disagree on the name and they denote the same section.
4. **`design/gdd/` 中的每个 GDD** — 从承载技术需求的小节中提取技术需求，
   **而不是从整个文件中提取**。先确立分母（glob `design/gdd/*.md`，计数
   **N**），然后：
   ```
   Grep pattern="^## (Detailed Rules|Detailed Design|Formulas|Dependencies|Tuning Knobs|Acceptance Criteria)" glob="design/gdd/*.md" output_mode="content" -A 40
   ```
   Overview 和 Player Fantasy 是叙事的，不隐含任何架构；被扫描的集合才是规则、
   数值和跨系统契约所在之处。接受 `## Detailed Rules` 或 `## Detailed Design`
   中的任一个 — 设计标准和 GDD 模板对该名称意见不一致，但二者指同一个小节。

   Full-read a GDD when it matched **zero** sections (it predates the template —
   a zero-match means "unstructured", never "no requirements") or when a scanned
   section refers to material outside itself. **Never treat an absent section as
   an absent requirement**: report any GDD that contributed nothing, rather than
   letting it drop silently out of the baseline below.
   当某个 GDD 匹配到**零个**小节时（它早于模板 — 零匹配意味着"无结构"，绝不是
   "没有需求"），或当被扫描的小节引用了其自身之外的材料时，完整读取该 GDD。
   **绝不要把缺失的小节当作缺失的需求**：报告任何未贡献内容的 GDD，而不是让它
   从下面的基线中悄然消失。

   For each, extract:
   - Data structures implied by the game rules
   - Performance constraints stated or implied
   - Engine capabilities the system requires
   - Cross-system communication patterns (what talks to what, how)
   - State that must persist (save/load implications)
   - Threading or timing requirements
   对每一份，提取：
   - 游戏规则所隐含的数据结构
   - 明示或隐含的性能约束
   - 系统所需的引擎能力
   - 跨系统通信模式（什么与什么通信、如何通信）
   - 必须持久化的状态（存档/读档的影响）
   - 线程或时序需求

Build a **Technical Requirements Baseline** — a flat list of all extracted
requirements across all GDDs, numbered `TR-[system]-[NNN]`, the TR registry's
ID format. This is the
complete set of what the architecture must cover.
构建一份**技术需求基线** — 所有 GDD 中提取出的全部需求的扁平清单，编号为
`TR-[system]-[NNN]`，即 TR 注册表的 ID 格式。这就是架构必须覆盖的完整集合。

**The IDs come from the TR registry, not from a fresh count.** Stories and ADRs
cite TR-IDs, and `/architecture-review` keeps them permanent in
`docs/architecture/tr-registry.yaml`. A baseline numbered from 001 on a re-run
gives a requirement a different ID from the one stories already cite. So, before
numbering:
**ID 来自 TR 注册表，而不是重新计数。** 故事和 ADR 会引用 TR-ID，而
`/architecture-review` 会在 `docs/architecture/tr-registry.yaml` 中使它们永久
化。若在重跑时从 001 开始为基线编号，就会给某项需求分配与故事已引用 ID 不同的
ID。因此，在编号之前：

- **Registry present with entries:** read `docs/architecture/tr-registry.yaml`.
  A requirement that matches an `active` entry for the same system (same intent,
  wording may differ) keeps that entry's ID. Skip `deprecated` and
  `superseded-by` entries; they were retired on purpose. Every other requirement
  is **provisional**: number it from `bash .claude/scripts/registry.sh next-id tr
  <system>` onwards, so it cannot reuse a registered or retired ID, and mark it
  `(provisional)`. `/architecture-review` registers it and gives the permanent ID.
- **注册表存在且有条目：** 读取 `docs/architecture/tr-registry.yaml`。与同一
  系统的 `active` 条目匹配的需求（意图相同，措辞可能不同）保留该条目的 ID。
  跳过 `deprecated` 和 `superseded-by` 条目；它们是刻意退役的。其它每项需求都是
  **临时的**：从 `bash .claude/scripts/registry.sh next-id tr <system>` 起编号，
  这样它就不会复用已登记或已退役的 ID，并标记为 `(provisional)`。
  `/architecture-review` 会登记它并赋予永久 ID。
- **Registry absent, or `requirements: []`:** every ID is provisional. Say so in
  the baseline's header line, so nobody cites them as permanent.
- **注册表缺失，或 `requirements: []`：** 每个 ID 都是临时的。在基线的头部行中
  说明这一点，以免有人把它们当作永久 ID 引用。

Present it as:
将其呈现为：

```
## Technical Requirements Baseline
Extracted from [N] GDDs | [X] total requirements | [R] registered, [P] provisional
(TR registry: [read, E entries | absent | empty])

| Req ID | GDD | System | Requirement | Domain |
|--------|-----|--------|-------------|--------|
| TR-combat-001 | combat.md | Combat | Hitbox detection per-frame | Physics |
| TR-combat-002 | combat.md | Combat | Combo state machine | Core |
| TR-inventory-001 (provisional) | inventory.md | Inventory | Item persistence | Save/Load |
```

```
## 技术需求基线
从 [N] 个 GDD 提取 | [X] 项需求总数 | [R] 已登记，[P] 临时
(TR registry: [read, E entries | absent | empty])

| 需求 ID | GDD | 系统 | 需求 | 领域 |
|--------|-----|--------|-------------|--------|
| TR-combat-001 | combat.md | Combat | 逐帧命中盒检测 | Physics |
| TR-combat-002 | combat.md | Combat | 连招状态机 | Core |
| TR-inventory-001 (provisional) | inventory.md | Inventory | 物品持久化 | Save/Load |
```

This baseline feeds into every subsequent phase. No GDD requirement should be
left without an architectural decision to support it by the end of this session.
该基线会汇入后续每个阶段。到本次会话结束时，不应有任何 GDD 需求缺少支撑它的
架构决策。

### 0c. Existing Architecture Decisions
### 0c. 现有架构决策

To learn **what has already been decided and in which domain**, scan the ADR
headers — do not full-read every ADR to produce a list of numbers and domains:
要了解**已经决定了什么以及在哪个领域**，扫描 ADR 头部 — 不要为了产出编号和领域
清单而完整读取每个 ADR：
```
Grep pattern="^## (Status|Summary)" glob="docs/architecture/adr-*.md" output_mode="content" -A 4
Grep pattern="\*\*Domain\*\*" glob="docs/architecture/adr-*.md" output_mode="content"
```
`## Summary` (a 2-sentence what-and-why) plus `## Status` and the Engine
Compatibility `Domain` field are exactly "what was decided and its domain". List
the ADRs found, their status, and their domains from the scan. Full-read a
specific ADR only when a new decision this session would collide with it and you
need its reasoning — not to build the inventory. Read it by section: find the
headings with the Grep tool (pattern `^#`, content mode) and Read those
ranges with offset and limit.
`## Summary`（两句话说明做什么和为什么）、`## Status` 以及 Engine
Compatibility 的 `Domain` 字段，恰好就是"决定了什么及其领域"。列出扫描中发现的
ADR、它们的状态和领域。仅当本次会话的某项新决策会与某个特定 ADR 冲突且你需要
其推理时，才完整读取它 — 而不是为了建立清单。按节读取它：用 Grep 工具
（pattern `^#`，content 模式）找到标题，并用 offset 和 limit 读取那些范围。

### 0d. Generate Knowledge Gap Inventory
### 0d. 生成知识缺口清单

Before proceeding, display a structured summary:
在继续之前，显示一份结构化摘要：

```
## Engine Knowledge Gap Inventory
Engine: [name + version]
LLM Training Covers: up to approximately [version]
Post-Cutoff Versions: [list]

### HIGH RISK Domains (must verify against engine reference before deciding)
- [Domain]: [Key changes]

### MEDIUM RISK Domains (verify key APIs)
- [Domain]: [Key changes]

### LOW RISK Domains (in training data, likely reliable)
- [Domain]: [no significant post-cutoff changes]

### Systems from GDD that touch HIGH/MEDIUM risk domains:
- [GDD system name] → [domain] → [risk level]
```

```
## 引擎知识缺口清单
Engine: [名称 + 版本]
LLM Training Covers: 至大约 [版本]
Post-Cutoff Versions: [列表]

### HIGH RISK 领域（决策前必须对照引擎参考验证）
- [领域]：[主要变更]

### MEDIUM RISK 领域（验证关键 API）
- [领域]：[主要变更]

### LOW RISK 领域（在训练数据中，可能可靠）
- [领域]：[无显著的训练截止后变更]

### 来自 GDD 且触及 HIGH/MEDIUM 风险领域的系统：
- [GDD 系统名称] → [领域] → [风险等级]
```

Use `AskUserQuestion`:
使用 `AskUserQuestion`：
- Prompt: "One or more engine domains are HIGH RISK — the LLM's knowledge may be unreliable for these areas. Architectural recommendations in these domains should be cross-referenced with the engine docs before being acted on. How would you like to proceed?"
- 提示："One or more engine domains are HIGH RISK — the LLM's knowledge may be unreliable for these areas. Architectural recommendations in these domains should be cross-referenced with the engine docs before being acted on. How would you like to proceed?"
  （一个或多个引擎领域为 HIGH RISK — LLM 在这些领域的知识可能不可靠。这些领域的
  架构建议在落实之前应先与引擎文档交叉参照。你希望如何继续？）
- Options:
  - `[A] Proceed — flag HIGH RISK domains throughout the output`
  - `[B] Let me check the engine reference first — pause here`
  - `[C] Show me which domains are HIGH RISK and why`
- 选项：
  - `[A] Proceed — flag HIGH RISK domains throughout the output`
    （继续 — 在输出中全程标记 HIGH RISK 领域）
  - `[B] Let me check the engine reference first — pause here`
    （让我先查看引擎参考 — 在此暂停）
  - `[C] Show me which domains are HIGH RISK and why`
    （告诉我哪些领域是 HIGH RISK 及其原因）

### 0e. Existing Architecture Document
### 0e. 现有架构文档

Glob `docs/architecture/architecture.md`. If it exists, this run updates it —
it never replaces it unasked. Read its `## Document Status` block and its `##`
headings, then use `AskUserQuestion`:
Glob `docs/architecture/architecture.md`。若它存在，本次运行会更新它 —
它绝不未经请求就替换它。读取其 `## Document Status` 块及其 `##` 标题，然后使用
`AskUserQuestion`：
- Prompt: "An architecture document already exists (v[N], [last updated]). What should this run do?"
- Options: `[A] Update chosen sections in place` / `[B] Rewrite the whole document — replaces the existing file` / `[C] Stop`
- 提示："An architecture document already exists (v[N], [last updated]). What should this run do?"（已存在一份架构文档（v[N]，[最后更新日期]）。本次运行应做什么？）
- 选项：`[A] Update chosen sections in place`（就地更新选定的小节）/ `[B] Rewrite the whole document — replaces the existing file`（重写整个文档 — 替换现有文件）/ `[C] Stop`（停止）

On `[A]`, ask which sections. Phases 1–6 author only those and say which they
skipped; Phase 7 replaces just those sections and raises `Version` to N+1,
leaving every other section as it is. `[B]` runs the full walkthrough, and
Phase 7's ask says it replaces the existing file.
选择 `[A]` 时，询问要更新哪些小节。阶段 1–6 只编写那些小节，并说明跳过了哪些；
阶段 7 仅替换那些小节并将 `Version` 提升至 N+1，其它每个小节保持原样。`[B]`
运行完整的逐步流程，且阶段 7 的询问会说明它将替换现有文件。

A focus-area argument (`layers`, `data-flow`, `api-boundaries`, `adr-audit`)
is `[A]` with that one section chosen: it runs only its phase (1, 3, 4 or 5),
and Phase 7 writes that section. Phase 7b still runs on the updated document —
an update is reviewed like a first draft, at the review modes that review one. With no existing document there is nothing to
update — say so, and offer the full walkthrough instead.
聚焦领域参数（`layers`、`data-flow`、`api-boundaries`、`adr-audit`）等同于选定
那一个小节的 `[A]`：它只运行其对应阶段（1、3、4 或 5），并由阶段 7 写入该小节。
阶段 7b 仍会在更新后的文档上运行 — 更新会像初稿一样，在评审初稿的那几种评审
模式下接受评审。若没有现有文档，就没有可更新的内容 — 说明这一点，并改为提供
完整的逐步流程。

---
