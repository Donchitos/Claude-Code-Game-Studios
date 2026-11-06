---
name: design-review
description: "Reviews one design document for completeness, internal consistency, implementability, and design standards. Before handing to programmers."
argument-hint: "[path-to-design-doc] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/design-review/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-receipts.sh check *), Bash(bash .claude/scripts/review-receipts.sh hash *), Bash(bash .claude/scripts/gdd-structure-check.sh *), Bash(grep -E '^  - name:' design/registry/entities.yaml), Bash(grep -n -i -E *)
model: sonnet
---
---
name: design-review
description: "评审单个设计文档的完整性、内部一致性、可实施性和设计标准。在交给程序员之前进行。"
argument-hint: "[path-to-design-doc] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/design-review/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/review-receipts.sh check *), Bash(bash .claude/scripts/review-receipts.sh hash *), Bash(bash .claude/scripts/gdd-structure-check.sh *), Bash(grep -E '^  - name:' design/registry/entities.yaml), Bash(grep -n -i -E *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. `--depth` is
the pre-1.1 name for the same flag: treat `--depth <mode>` exactly as
`--review <mode>`, and say once that it was renamed. Given both, `--review`
wins and `--depth` is ignored — say so. No block → defaults in
`.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 会覆盖 `review_mode`。`--depth` 是
同一个标志在 1.1 之前的名称：将 `--depth <mode>` 完全按
`--review <mode>` 处理，并说明一次它已被重命名。若两者都给出，`--review`
胜出而 `--depth` 被忽略 — 要说明这一点。无配置块 → 使用
`.claude/docs/config-resolution.md` 中的默认值。

# Design Review
# 设计评审

## Phase 0: Parse Arguments
## 阶段 0：解析参数

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.
完整检查模式见 `.claude/docs/director-gates.md`。各个门禁定义位于 `.claude/docs/director-gates/[gate-id].md` — 被启动的智能体读取自己的门禁文件；不要在父会话中读取它。

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（collaborative 始终询问 · guided 仅主要项 · autonomous 记录并继续；
`automation_always_ask` 类别始终提示）。

**`workflow`** for the GDD under review — use the `system_overrides` row for `<system>` if the block lists one, else the project value. Validation scope follows the tier:
- `full` — all 8 sections validated; any missing section blocks approval.
- `standard` — the 5 required sections (Overview, Detailed Rules, Edge Cases,
  Dependencies, Acceptance Criteria) block if missing; Formulas blocks only when
  the system defines numeric rules (rates, curves, thresholds, costs — the
  category is a hint, not the test); Player Fantasy and
  Tuning Knobs are advisory (warn, never block) unless `workflow_overrides`
  require them.
- `minimal` — no GDD is expected; if one exists, validate the 5 standard
  sections advisorily.
**`workflow`** 针对被评审的 GDD — 若配置块列出了 `<system>` 的 `system_overrides` 行则使用它，否则使用项目值。验证范围随层级变化：
- `full` — 验证全部 8 个节；任何缺失的节都会阻塞批准。
- `standard` — 5 个必需节（Overview、Detailed Rules、Edge Cases、
  Dependencies、Acceptance Criteria）若缺失则阻塞；Formulas 仅当
  系统定义了数值规则（比率、曲线、阈值、成本 — 
  类别只是提示，不是判据）时才阻塞；Player Fantasy 和
  Tuning Knobs 为建议性（警告，绝不阻塞），除非 `workflow_overrides`
  要求它们。
- `minimal` — 不期望有 GDD；若存在一个，以建议性方式验证 5 个标准
  节。

Resolved mode controls how thorough this review is:
已解析模式控制本次评审的彻底程度：

- **`full`**: Complete review — all phases + specialist agent delegation (Phase 3b)
- **`lean`**: All phases, no specialist agents — faster, single-session analysis
- **`solo`**: Phases 1-4 only, no delegation, no Phase 5 next-step prompt — use when called from within another skill
- **`full`**：完整评审 — 所有阶段 + 专家智能体委托（阶段 3b）
- **`lean`**：所有阶段，无专家智能体 — 更快，单会话分析
- **`solo`**：仅阶段 1-4，无委托，无阶段 5 后续步骤提示 — 从其他技能内部调用时使用

---

## Phase 1: Load Documents
## 阶段 1：加载文档

**Freshness check first — a re-review of an unchanged document costs full
price and reproduces the same verdict.** Run:
**先做新鲜度检查 — 对未更改文档的重复评审要付出全部
成本，并复现相同的裁决。**

```
Bash: bash .claude/scripts/review-receipts.sh check "design/gdd/reviews/[doc-name]-review-log.md" "[target-doc-path]" "design/registry/entities.yaml" ".claude/skills/design-review/SKILL.md"
```

The registry is in the check because this review consults it for
cross-document facts — an unchanged GDD reviewed against a *changed*
registry can reach different conclusions, so the skip is only safe when
**every** line reads `UNCHANGED` (a registry that never existed doesn't
appear in the output and doesn't block the skip). This skill's file is in it
because a changed skill reviews differently. The check also compares every
other file the log stamps — the related GDDs, concept or brief and narrative
files earlier reviews read — and prints `GONE:` for one that no longer exists.
注册表参与检查，是因为本次评审会为跨文档事实查阅它 — 一个未更改的 GDD 对照*已更改*的
注册表评审可能得出不同结论，因此只有当
**每一**行都读作 `UNCHANGED` 时跳过才安全（一个从未存在过的注册表
不会出现在输出中，也不阻塞跳过）。此技能的文件也在其中，
因为技能发生变化后评审方式会不同。该检查还会比较日志戳记的每个
其他文件 — 相关 GDD、概念或简报，以及早期评审读取的叙事
文件 — 并为不再存在的文件打印 `GONE:`。

Then read the latest entry's `Review mode:` line. That review **covers** this
run only when its mode is the same as or deeper than the mode resolved now
(`full` > `lean` > `solo`) and its workflow is the same or deeper (`full` >
`standard` > `minimal`). An entry without the line was written before it
existed and covers nothing.
然后读取最新条目的 `Review mode:` 行。仅当那次评审的模式与当前解析的模式相同或更深
（`full` > `lean` > `solo`），且其工作流相同或更深（`full` >
`standard` > `minimal`）时，它才**覆盖**本次
运行。没有该行的条目是在该行存在之前写入的，不覆盖任何内容。

- **All `UNCHANGED`** and the log's latest entry carries a verdict — surface it:
  *"This document is byte-identical to its last review on [date] ([mode]
  review, verdict: [verdict])."* If that verdict was APPROVED and that review
  covers this run, offer via `AskUserQuestion`:
  `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway` —
  `guided` proceeds with [A] and notes it; `autonomous` logs via
  `log_decision` and uses the prior verdict. If it was APPROVED but the
  review asked for now is deeper than the logged one, say so — *"That was a
  [mode] review at workflow [tier]; this run asks for [mode] at [tier]."* —
  and offer `[A] Re-review at [mode] (Recommended)` / `[B] Use the prior
  [mode] verdict`; `guided` and `autonomous` re-review (`autonomous` logs it
  via `log_decision`). If it was NEEDS REVISION or
  MAJOR REVISION NEEDED, say so plainly: the document has not changed since
  it failed review — the prior findings stand; revising the document is the
  next step, not re-reviewing it. Offer to display the prior findings from
  the log.
- **The target doc and this skill's file `UNCHANGED`, and only the registry or
  another stamped cross-document file `CHANGED`, `NEW` or `GONE`** — the prior
  verdict stands except for cross-document facts: re-verify the doc's values
  against the changed files and re-issue the verdict; escalate to a full
  re-review if a conflict appears or that review does not cover this run.
- **Target doc or this skill's file `CHANGED` or `NEW`, or `RECEIPT: NONE`** —
  proceed with the full review below. **Do not offer a partial/delta re-review that skips
  reading or re-analyzing unchanged sections.** A section-scoped re-review
  misses defects a full review finds, and saves little or nothing.
  "Unchanged since last review" only means
  byte-identical to what was reviewed then — it says nothing about whether
  that prior pass was itself complete, and attention narrows to the flagged
  change even under an instruction to scan everything anyway.
- **全部为 `UNCHANGED`** 且日志最新条目带有裁决 — 呈现它：
  *"This document is byte-identical to its last review on [date] ([mode]
  review, verdict: [verdict])."* 如果该裁决为 APPROVED 且该次评审
  覆盖本次运行，通过 `AskUserQuestion` 提供：
  `[A] Use the prior verdict (Recommended)` / `[B] Re-review anyway` —
  `guided` 采用 [A] 并记录；`autonomous` 通过
  `log_decision` 记录并使用先前裁决。如果它是 APPROVED，但当前要求的
  评审比已记录的更深，要说明 — *"That was a
  [mode] review at workflow [tier]; this run asks for [mode] at [tier]."* —
  并提供 `[A] Re-review at [mode] (Recommended)` / `[B] Use the prior
  [mode] verdict`；`guided` 和 `autonomous` 重新评审（`autonomous` 通过
  `log_decision` 记录）。如果它是 NEEDS REVISION 或
  MAJOR REVISION NEEDED，直说：文档自评审失败以来没有变化 — 先前的发现依然成立；修订文档是
  下一步，而不是重新评审它。提供从
  日志显示先前发现的选项。
- **目标文档和此技能的文件 `UNCHANGED`，只有注册表或
  另一个已戳记的跨文档文件 `CHANGED`、`NEW` 或 `GONE`** — 先前的
  裁决依然成立，跨文档事实除外：对照更改的文件重新验证文档中的值
  并重新给出裁决；若出现冲突或该次评审不覆盖本次运行，
  升级为完整重新评审。
- **目标文档或此技能的文件 `CHANGED` 或 `NEW`，或 `RECEIPT: NONE`** —
  继续进行下文的完整评审。**不要提供跳过
  读取或重新分析未更改节的部分/增量重新评审。** 按节范围的重新评审
  会漏掉完整评审能发现的缺陷，而且节省微乎其微甚至没有。
  "Unchanged since last review" 只意味着与当时评审的内容
  字节相同 — 它并不说明那次先前评审本身是否完整，而且即便有指令要求
  仍然扫描全部内容，注意力也会收窄到被标记的更改上。

Read the target design document in full. This step needs the whole GDD: read it in ranges by its headings (found with the Grep tool: pattern `^#`, content mode), since a whole-file Read over 40 KB is refused. Read CLAUDE.md to understand project context and standards.
完整读取目标设计文档。此步骤需要整个 GDD：按其标题分区间读取（用 Grep 工具查找：模式 `^#`，content 模式），因为超过 40 KB 的整文件 Read 会被拒绝。读取 CLAUDE.md 以了解项目上下文和标准。

**For cross-document facts, prefer the registry over sibling GDDs.** If
`design/registry/entities.yaml` exists **and lists entries for this system**,
grep it — these are the established facts this GDD must not contradict, and they
replace reading sibling GDDs to rediscover them:
**对于跨文档事实，优先使用注册表而非同级 GDD。** 如果
`design/registry/entities.yaml` 存在**且列出了本系统的条目**，
grep 它 — 这些是本 GDD 不得违背的既定事实，它们
取代读取同级 GDD 来重新发现这些事实：
```
Grep pattern="source: design/gdd/[system].md" path="design/registry/entities.yaml" output_mode="content" -A 6
Grep pattern="design/gdd/[system].md" path="design/registry/entities.yaml" output_mode="content" -B 8
```
The first finds entries this system **owns** — the `-A 6` context includes their
`referenced_by:` block. The second finds entries that **reference** this system —
`referenced_by:` is a block sequence (the key and its paths are on separate
lines), so match the path with `-B 8` context to see the owning entry, not a
`referenced_by.*name` one-liner (which never matches the block form).
第一个查找本系统**拥有**的条目 — `-A 6` 上下文包含它们的
`referenced_by:` 块。第二个查找**引用**本系统的条目 —
`referenced_by:` 是一个块序列（键及其路径在不同
行），因此用 `-B 8` 上下文匹配路径以看到拥有条目，而不是
`referenced_by.*name` 单行式（它永远匹配不到块形式）。

**If `design/registry/entities.yaml` does not exist, or lists no entry for this
system** — the file ships as an empty stub, so this is the default until
`/design-system` has populated it — fall back to reading the related GDDs the
target doc names in its Dependencies section. Bound the read to those, not to
everything "implied". Do not glob-read all of `design/gdd/`.
**如果 `design/registry/entities.yaml` 不存在，或未列出本系统的
条目** — 该文件以空存根形式发布，因此在
`/design-system` 填充它之前这是默认情况 — 回退到读取目标文档在其 Dependencies 节中点名的相关 GDD。
将读取限制在这些文档上，而不是所有"隐含"的内容。不要 glob 读取整个 `design/gdd/`。

**Dependency graph validation:** For every system listed in the Dependencies section, use Glob to check whether its GDD file exists in `design/gdd/`. Flag any that don't exist yet — these are broken references that downstream authors will hit.
**依赖图验证：** 对于 Dependencies 节中列出的每个系统，使用 Glob 检查其 GDD 文件是否存在于 `design/gdd/` 中。标记任何尚不存在的 — 这些是下游作者会遇到的破损引用。

**Lore/narrative alignment:** If `design/gdd/game-concept.md` (or, at `rigor: minimal`, the one-page brief `design/game-brief.md`) or any file in `design/narrative/` exists, read it. Note any mechanical choices in this GDD that contradict established world rules, tone, or design pillars. Pass this context to `game-designer` in Phase 3b.
**世界观/叙事对齐：** 如果 `design/gdd/game-concept.md`（或在 `rigor: minimal` 下，单页简报 `design/game-brief.md`）或 `design/narrative/` 中的任何文件存在，读取它。记录本 GDD 中与既定世界规则、基调或设计支柱相矛盾的任何机制选择。在阶段 3b 将此上下文传给 `game-designer`。

**Prior review check:** Check whether `design/gdd/reviews/[doc-name]-review-log.md` exists. If it does, read the most recent entry — note what verdict was given and what blocking items were listed. This session is a re-review; track whether prior items were addressed.
**先前评审检查：** 检查 `design/gdd/reviews/[doc-name]-review-log.md` 是否存在。如果存在，读取最近条目 — 记录给出的裁决以及列出的阻塞项。本次会话是一次重新评审；跟踪先前条目是否已处理。

---

## Phase 2: Completeness Check
## 阶段 2：完整性检查

**Step 2a — gather section presence deterministically (no document read):**
**步骤 2a — 确定性地收集各节是否存在（不读取文档）：**

```
Bash: bash .claude/scripts/gdd-structure-check.sh [target-doc-path]
```

It prints a `PRESENT:` list and, when applicable, an `ABSENT:` list and a
`PLACEHOLDER:` list (present sections holding only `[To be designed]`: not yet
written, so treat them as missing for the checklist). It reports
**presence only** and makes no REQUIRED/ADVISORY judgment — that is Step 2b's
job. It already accepts `## Detailed Design` as satisfying the `Detailed Rules`
requirement, so do not flag that as missing.
它打印一个 `PRESENT:` 列表，并在适用时打印 `ABSENT:` 列表和
`PLACEHOLDER:` 列表（存在的节只含 `[To be designed]`：尚未
写入，因此在清单中将其视为缺失）。它报告
**仅存在性**，不做 REQUIRED/ADVISORY 判断 — 那是步骤 2b 的
职责。它已接受 `## Detailed Design` 作为满足 `Detailed Rules`
要求，因此不要将其标记为缺失。

**Step 2b — apply the tier.** Using the Step 2a lists, evaluate against the
Design Document Standard checklist below. **Mark each section REQUIRED or
ADVISORY per the resolved workflow tier (Phase 0).** A missing REQUIRED section
blocks approval; a missing ADVISORY section is surfaced as a recommendation but
does not block.
**步骤 2b — 应用层级。** 使用步骤 2a 的列表，对照下文的
设计文档标准清单进行评估。**按已解析的工作流层级（阶段 0）将每一节标记为 REQUIRED 或
ADVISORY。** 缺失的 REQUIRED 节
阻塞批准；缺失的 ADVISORY 节作为建议呈现，但
不阻塞。

A section reported PRESENT can still fail review if it is an empty heading —
spot-read any section the verdict actually turns on.
报告为 PRESENT 的节如果是空标题，仍可能未通过评审 —
对裁决实际依赖的任何节进行抽读。

- [ ] Has Overview section (one-paragraph summary) — REQUIRED at all tiers
- [ ] Has Player Fantasy section (intended feeling) — REQUIRED at `full`; ADVISORY at `standard`
- [ ] Has Detailed Rules section (unambiguous mechanics) — REQUIRED at `full`/`standard`. The GDD template titles this section `## Detailed Design` (it carries Core Rules / States / Interactions sub-headings); accept **either** heading as satisfying this requirement — do not flag "Detailed Rules" as missing when a `## Detailed Design` section is present.
- [ ] Has Formulas section (all math defined with variables) — REQUIRED at `full`; at `standard` REQUIRED whenever the system defines numeric rules (rates, curves, thresholds, costs, damage, drop weights), else ADVISORY. The system's `Category` is a hint, not the test — do not clear this on a category token alone
- [ ] Has Edge Cases section (unusual situations handled) — REQUIRED at `full`/`standard`
- [ ] Has Dependencies section (other systems listed) — REQUIRED at `full`/`standard`
- [ ] Has Tuning Knobs section (configurable values identified) — REQUIRED at `full`; ADVISORY at `standard` unless `workflow_overrides.tuning_knobs`
- [ ] Has Acceptance Criteria section (testable success conditions) — REQUIRED at `full`/`standard`
- [ ] 有 Overview 节（单段摘要） — 所有层级均为 REQUIRED
- [ ] 有 Player Fantasy 节（预期感受） — 在 `full` 下 REQUIRED；在 `standard` 下 ADVISORY
- [ ] 有 Detailed Rules 节（无歧义的机制） — 在 `full`/`standard` 下 REQUIRED。GDD 模板将此节命名为 `## Detailed Design`（它带有 Core Rules / States / Interactions 子标题）；接受**任一**标题来满足此要求 — 当存在 `## Detailed Design` 节时，不要将 "Detailed Rules" 标记为缺失。
- [ ] 有 Formulas 节（所有数学都用变量定义） — 在 `full` 下 REQUIRED；在 `standard` 下，只要系统定义了数值规则（比率、曲线、阈值、成本、伤害、掉落权重）即为 REQUIRED，否则 ADVISORY。系统的 `Category` 是提示，不是判据 — 不要仅凭一个类别标记就清除此项
- [ ] 有 Edge Cases 节（已处理异常情况） — 在 `full`/`standard` 下 REQUIRED
- [ ] 有 Dependencies 节（列出其他系统） — 在 `full`/`standard` 下 REQUIRED
- [ ] 有 Tuning Knobs 节（已识别可配置值） — 在 `full` 下 REQUIRED；在 `standard` 下 ADVISORY，除非 `workflow_overrides.tuning_knobs`
- [ ] 有 Acceptance Criteria 节（可测试的成功条件） — 在 `full`/`standard` 下 REQUIRED

---

## Phase 3: Consistency and Implementability
## 阶段 3：一致性与可实施性

**Internal consistency:**
- Do the formulas produce values that match the described behavior?
- Do edge cases contradict the main rules?
- Are dependencies bidirectional (does the other system know about this one)?
**内部一致性：**
- 公式产生的值是否与所描述的行为相符？
- 边界情况是否与主规则矛盾？
- 依赖是否双向（另一个系统是否知道本系统）？

**Implementability:**
- Are the rules precise enough for a programmer to implement without guessing?
- Are there any "hand-wave" sections where details are missing?
- Are performance implications considered?
- Is every acceptance criterion independently testable? Flag each one that is
  not, quoting it — "feels balanced", "works correctly", "performs well" are not
  criteria — with a measurable rewrite. In `full` mode `qa-lead` also checks them
  (Phase 3b); in `lean` and `solo` no specialist runs, so this main-review check
  is the only one.
**可实施性：**
- 规则是否足够精确，让程序员无需猜测即可实现？
- 是否有任何"挥手带过"的节，其中细节缺失？
- 是否考虑了性能影响？
- 每个验收标准是否都可独立测试？标记每一个不可独立测试的，
  并引用它 — "feels balanced"、"works correctly"、"performs well" 不是
  标准 — 并给出可度量的改写。在 `full` 模式下，`qa-lead` 也会检查它们
  （阶段 3b）；在 `lean` 和 `solo` 下不运行专家，因此此次主评审检查
  是唯一的一次。

**Cross-system consistency:**
- Does this conflict with any existing mechanic?
- Does this create unintended interactions with other systems?
- Is this consistent with the game's established tone and pillars?
**跨系统一致性：**
- 这是否与任何现有机制冲突？
- 这是否与其他系统产生意外交互？
- 这是否与游戏既定基调和支柱一致？

**Registry values, wherever the GDD states them.** A value restated in a table,
a catalogue entry or a variant note contradicts the registry as surely as one in
Detailed Rules, and reading by section makes those bodies easy to skim. List the
registry's entry names (`grep -E '^  - name:' design/registry/entities.yaml`),
then search the whole target document once for all of them plus the numeric
keys they carry, case-insensitive, writing each `_` as `[_ ]` so `goblin_scout`
also matches "Goblin scouts":
**注册表值，无论 GDD 在哪里陈述它们。** 在表格、
目录条目或变体注释中重述的值与 Detailed Rules 中的值一样肯定与注册表相矛盾，
而按节读取使这些主体容易被略读。列出
注册表的条目名（`grep -E '^  - name:' design/registry/entities.yaml`），
然后在整个目标文档中一次性搜索所有条目名及其携带的数值
键，不区分大小写，将每个 `_` 写为 `[_ ]`，使 `goblin_scout`
也能匹配 "Goblin scouts"：

```
grep -n -i -E 'goblin[_ ]scout|iron[_ ]sword|health|value[_ ]gold' [target-doc-path]
```

Check every line it prints against the registry, whatever section it sits in.
A line that gives an entry a different value, even for one room, variant, level
or exception, contradicts the owning GDD: list it under Required Before
Implementation with its line number, this document's value and the registry's.
With no registry entries, run the same search for the entities and values the
related GDDs define.
对照注册表检查它打印的每一行，无论它位于哪个节。
若某行给某个条目不同的值，即使只针对一个房间、变体、关卡
或例外，也与拥有它的 GDD 相矛盾：将其列在 Required Before
Implementation 下，附上行号、本文件的值和注册表的值。
若没有注册表条目，则对相关 GDD 定义的实体和值运行相同的搜索。

---

## Phase 3b: Adversarial Specialist Review (full mode only)
## 阶段 3b：对抗性专家评审（仅 full 模式）

**Skip this phase in `lean` or `solo` mode.**
**在 `lean` 或 `solo` 模式下跳过此阶段。**

**This phase is MANDATORY in full mode.** Do not skip it.
**此阶段在 full 模式下是强制的。** 不要跳过它。

**Before spawning any agents**, print this notice:
> "Full review: spawning specialist agents in parallel. This typically takes 8–15 minutes. Use `--review lean` for faster single-session analysis."
**在启动任何智能体之前**，打印此提示：
> "Full review: spawning specialist agents in parallel. This typically takes 8–15 minutes. Use `--review lean` for faster single-session analysis."

### Step 1 — Identify all domains the GDD touches
### 步骤 1 — 识别 GDD 涉及的所有领域

Using the GDD **already loaded in Phase 1** — do not re-read it — identify every domain present. A GDD can touch multiple domains simultaneously — be thorough. Common signals:
使用**阶段 1 已加载的** GDD — 不要重新读取它 — 识别存在的每个领域。一个 GDD 可以同时涉及多个领域 — 要彻底。常见信号：

| If the GDD contains... | Spawn these agents |
|------------------------|-------------------|
| Costs, prices, drops, rewards, economy | `economy-designer` |
| Combat stats, damage, health, DPS | `game-designer`, `systems-designer` |
| AI behaviour, pathfinding, targeting | `ai-programmer` |
| Level layout, spawning, wave structure | `level-designer` |
| Player progression, XP, unlocks | `economy-designer`, `game-designer` |
| UI, HUD, menus, player-facing displays | `ux-designer`, `ui-programmer` |
| Dialogue, quests, story, lore | `narrative-director` |
| Animation, feel, timing, juice | `gameplay-programmer` |
| Multiplayer, sync, replication | `network-programmer` |
| Audio cues, music triggers | `audio-director` |
| Performance, draw calls, memory | `performance-analyst` |
| Engine-specific patterns or APIs | Primary engine specialist (`<engine>-specialist` from `engine.name` — Godot→`godot-specialist`, Unity→`unity-specialist`, Unreal→`unreal-specialist`; fall back to the Primary line of `## Engine Specialists` in `technical-preferences.md`) |
| Acceptance criteria, test coverage | `qa-lead` |
| Data schema, resource structure | `systems-designer` |
| Any gameplay system | `game-designer` (always) |
| 若 GDD 包含…… | 启动这些智能体 |
|------------------------|-------------------|
| 成本、价格、掉落、奖励、经济 | `economy-designer` |
| 战斗属性、伤害、生命值、DPS | `game-designer`、`systems-designer` |
| AI 行为、寻路、目标选择 | `ai-programmer` |
| 关卡布局、生成、波次结构 | `level-designer` |
| 玩家成长、经验值、解锁 | `economy-designer`、`game-designer` |
| UI、HUD、菜单、面向玩家的显示 | `ux-designer`、`ui-programmer` |
| 对话、任务、故事、世界观 | `narrative-director` |
| 动画、手感、时机、打击感 | `gameplay-programmer` |
| 多人、同步、复制 | `network-programmer` |
| 音频提示、音乐触发 | `audio-director` |
| 性能、绘制调用、内存 | `performance-analyst` |
| 引擎特定模式或 API | 主引擎专家（由 `engine.name` 得到 `<engine>-specialist` — Godot→`godot-specialist`，Unity→`unity-specialist`，Unreal→`unreal-specialist`；回退到 `technical-preferences.md` 中 `## Engine Specialists` 的 Primary 行） |
| 验收标准、测试覆盖 | `qa-lead` |
| 数据模式、资源结构 | `systems-designer` |
| 任何玩法系统 | `game-designer`（始终） |

Spawn `game-designer` for all GDDs that describe gameplay mechanics or player-facing rules.
Spawn `systems-designer` for all GDDs that contain formulas or system interaction rules.
These are the most common baselines — but not required for pure UI specs, audio specs, or lore documents. Use the domain table above to determine which specialists are truly relevant.
为所有描述玩法机制或面向玩家规则的 GDD 启动 `game-designer`。
为所有包含公式或系统交互规则的 GDD 启动 `systems-designer`。
这些是最常见的基线 — 但对于纯 UI 规格、音频规格或世界观文档并非必需。使用上文的领域表确定哪些专家真正相关。

### Step 2 — Spawn all relevant specialists in parallel
### 步骤 2 — 并行启动所有相关专家

**CRITICAL: `Agent` in this skill spawns a SUBAGENT — a separate independent Claude session
with its own context window. It is NOT task tracking. Do NOT simulate specialist
perspectives internally. Do NOT reason through domain views yourself. You MUST issue
actual `Agent` calls. A simulated review is not a specialist review.**
**关键：此技能中的 `Agent` 会启动一个子智能体 — 一个拥有自己上下文窗口的独立 Claude 会话。
它不是任务跟踪。不要在内部模拟专家
视角。不要自己推理领域观点。你必须发出
实际的 `Agent` 调用。模拟的评审不是专家评审。**

Issue all `Agent` calls simultaneously. Do NOT spawn one at a time.
同时发出所有 `Agent` 调用。不要一次启动一个。

**Prompt each specialist adversarially:**
> "Here is the GDD for [system] and the main review's structural findings so far.
> Your job is NOT to validate this design — your job is to find problems.
> Challenge the design choices from your domain expertise. What is wrong,
> underspecified, likely to cause problems, or missing entirely?
> Be specific and critical. Disagreement with the main review is welcome.
> Read the GDD by section: find the headings with the Grep tool (pattern `^#`,
> content mode) and Read those ranges with offset and limit."
**以对抗性方式提示每位专家：**
> "Here is the GDD for [system] and the main review's structural findings so far.
> Your job is NOT to validate this design — your job is to find problems.
> Challenge the design choices from your domain expertise. What is wrong,
> underspecified, likely to cause problems, or missing entirely?
> Be specific and critical. Disagreement with the main review is welcome.
> Read the GDD by section: find the headings with the Grep tool (pattern `^#`,
> content mode) and Read those ranges with offset and limit."

**Additional instructions per agent type:**
**按智能体类型的附加指令：**

- **`game-designer`**: Anchor your review to the Player Fantasy stated in Section B of this GDD. Does this design actually deliver that fantasy? Would a player feel the intended experience? Flag any rules that serve implementability but undermine the stated feeling.
- **`systems-designer`**: For every formula in the GDD, plug in boundary values (minimum and maximum plausible inputs). Report whether any outputs go degenerate — negative values, division by zero, infinity, or nonsensical results at the extremes.
- **`qa-lead`**: Review every acceptance criterion. Flag any that are not independently testable — phrases like "feels balanced", "works correctly", "performs well" are not ACs. Suggest concrete rewrites for any that fail this test.
- **`game-designer`**：将你的评审锚定在本 GDD B 节陈述的 Player Fantasy 上。此设计真的交付了那个幻想吗？玩家会感受到预期的体验吗？标记任何服务于可实施性但削弱所述感受的规则。
- **`systems-designer`**：对 GDD 中的每个公式，代入边界值（最小和最大合理输入）。报告是否有任何输出退化 — 负值、除以零、无穷大，或在极端情况下的荒谬结果。
- **`qa-lead`**：评审每个验收标准。标记任何不可独立测试的 — 诸如 "feels balanced"、"works correctly"、"performs well" 的短语不是 AC。对任何未通过此测试的提出具体改写。

### Step 3 — Senior lead review
### 步骤 3 — 资深负责人评审

After all specialists respond, spawn `creative-director` as the **senior reviewer**:
- Provide: the GDD, all specialist findings, any disagreements between them
- Ask: "Synthesise these findings. What are the most important issues? Do you agree with the specialists? What is your overall verdict on this design — APPROVED, NEEDS REVISION or MAJOR REVISION NEEDED?"
- The creative-director's synthesis becomes the **final verdict** in Phase 4, in this skill's verdict words — never a director-gate word such as READY or REJECT.
在所有专家响应后，启动 `creative-director` 作为**资深评审者**：
- 提供：GDD、所有专家发现、它们之间的任何分歧
- 询问："Synthesise these findings. What are the most important issues? Do you agree with the specialists? What is your overall verdict on this design — APPROVED, NEEDS REVISION or MAJOR REVISION NEEDED?"
- creative-director 的综合结论成为阶段 4 的**最终裁决**，使用此技能的裁决措辞 — 绝不用 READY 或 REJECT 之类的总监门禁措辞。

### Step 4 — Surface disagreements
### 步骤 4 — 呈现分歧

If specialists disagree with each other or with the creative-director, do NOT silently pick one view. Present the disagreement explicitly in Phase 4 so the user can adjudicate.
如果专家彼此或与 creative-director 意见不一致，不要静默选择一种观点。在阶段 4 明确呈现分歧，以便用户裁定。

Mark every finding with its source: `[game-designer]`, `[economy-designer]`, `[creative-director]` etc.
用其来源标记每项发现：`[game-designer]`、`[economy-designer]`、`[creative-director]` 等。

---

## Phase 4: Output Review
## 阶段 4：输出评审

```
## Design Review: [Document Title]
Specialists consulted: [list agents spawned]
Re-review: [Yes — prior verdict was X on YYYY-MM-DD / No — first review]

### Completeness: [X/N sections present, where N is the count REQUIRED at this project's `modes.workflow`]
[List only sections missing that are REQUIRED at this tier. Mark ADVISORY gaps
separately as "advisory at `standard`" — do not list them as missing.]

> **N is not 8 unless `workflow: full`.** The tier table earlier in this skill is
> authoritative: 8 required at `full`, 5 at `standard` (+ Formulas when the system
> defines numeric rules), 0 at `minimal`. Do not hardcode `/8` here: reporting a
> `standard` project as "5/8 missing Player Fantasy, Formulas, Tuning Knobs"
> warns about three sections that project's own configuration says it does not
> need, which trains the reader to ignore the review.

### Dependency Graph
[List each declared dependency and whether its GDD file exists on disk]
- ✓ enemy-definition-data.md — exists
- ✗ loot-system.md — NOT FOUND (file does not exist yet)

### Registry Values
[The whole-document search from Phase 3: the terms searched, how many lines it
printed, and each conflict with its line number. With nothing to search, say so:
"No registry entries or related-GDD values: values not cross-checked."]

### Required Before Implementation
[Numbered list — blocking issues only. Each item tagged with source agent.]

### Recommended Revisions
[Numbered list — important but not blocking. Source-tagged.]

### Specialist Disagreements
[Any cases where agents disagreed with each other or with the main review.
Present both sides — do not silently resolve.]

### Nice-to-Have
[Minor improvements, low priority.]

### Senior Verdict [creative-director]
[Creative director's synthesis and overall assessment.]

### Scope Signal
Estimate implementation scope based on: dependency count, formula count,
systems touched, and whether new ADRs are required.
- **S** — single system, no formulas, no new ADRs, <3 dependencies
- **M** — moderate complexity, 1-2 formulas, 3-6 dependencies
- **L** — multi-system integration, 3+ formulas, may require new ADR
- **XL** — cross-cutting concern, 5+ dependencies, multiple new ADRs likely
Label clearly: "Rough scope signal: M (producer should verify before sprint planning)"

### Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED / NOT ASSESSED]

> **`NOT ASSESSED` when the review could not actually be performed.**
> The other three verdicts are all claims about the design's quality, so each one
> asserts that the document was read and judged. Use `NOT ASSESSED` instead when
> the target document is absent, unreadable, or empty of the sections being
> reviewed, or when a document it depends on is missing so the criteria cannot be
> applied. **Name what was unavailable and which skill produces it.**
>
> `APPROVED` is the dangerous default here: a review that could not find its
> input has not approved anything, and this verdict is consumed downstream as a
> sign-off. `NOT ASSESSED` outranks `APPROVED` in any aggregate — it does not
> outrank the two revision verdicts, because a known problem is more actionable
> than an unknown one.
```

This skill is read-only — no files are written during Phase 4.
此技能是只读的 — 阶段 4 期间不写入任何文件。

---

## Phase 5: Next Steps
## 阶段 5：后续步骤

Use `AskUserQuestion` for ALL closing interactions. Never plain text.
对所有收尾交互使用 `AskUserQuestion`。绝不用纯文本。

**First widget — what to do next:**
**第一个组件 — 接下来做什么：**

If APPROVED (first-pass, no revision needed), proceed directly to the systems-index widget, review-log widget, then the final closing widget. Do not show a separate "what to do" widget — the final closing widget covers next steps.
如果 APPROVED（首轮通过，无需修订），直接进入 systems-index 组件、review-log 组件，然后是最终收尾组件。不要显示单独的 "what to do" 组件 — 最终收尾组件涵盖后续步骤。

If NOT ASSESSED, nothing was reviewed: offer no tracking update and go straight
to the final closing widget, leading with the skill that produces the missing
input (e.g. `/design-system [system]` for a GDD that does not exist).
如果 NOT ASSESSED，则未评审任何内容：不提供跟踪更新，直接
进入最终收尾组件，并以产出缺失输入的技能开场
（例如对不存在的 GDD 使用 `/design-system [system]`）。

If NEEDS REVISION or MAJOR REVISION NEEDED, build the options from the findings:
- `[A] Revise the GDD now — address blocking items together`
- `[B] Stop here — revise in a separate session`
- `[C] Accept as-is and move on` — include only when every finding is advisory
  (Required Before Implementation is empty). With any blocking item, offer [A]
  and [B] only.
如果 NEEDS REVISION 或 MAJOR REVISION NEEDED，根据发现构建选项：
- `[A] Revise the GDD now — address blocking items together`
- `[B] Stop here — revise in a separate session`
- `[C] Accept as-is and move on` — 仅当每项发现都是建议性时
  （Required Before Implementation 为空）才包含。若有任何阻塞项，仅提供 [A]
  和 [B]。

**If user selects [A] — Revise now:**
**如果用户选择 [A] — 立即修订：**

Work through all blocking items, asking for design decisions only where you cannot resolve the issue from the GDD and existing docs alone. Group all design-decision questions into a single multi-tab `AskUserQuestion` before making any edits — do not interrupt mid-revision for each blocker individually.
处理所有阻塞项，仅在你无法仅凭 GDD 和现有文档解决问题时才询问设计决策。在进行任何编辑之前，将所有设计决策问题归入一个多标签 `AskUserQuestion` 中 — 不要在工作过程中为每个阻塞项单独打断。

After all revisions are complete, show a summary table (blocker → fix applied) and use `AskUserQuestion` for a **post-revision closing widget**:
在所有修订完成后，显示一张摘要表（阻塞项 → 已应用的修复），并使用 `AskUserQuestion` 显示一个**修订后收尾组件**：

- Prompt: "Revisions complete — [N] blockers resolved. What next?"
- Note current context usage: if context is above ~50%, add: "(Recommended: /clear before re-review — this session has used X% context. A full re-review runs 5 agents and needs clean context.)"
- Options:
  - `[A] Re-review in a new session — run /design-review [doc-path] after /clear`
  - `[B] Accept revisions for now — mark In Review in the systems index; a re-review decides Approved`
  - `[C] Move to next system — /design-system [next-system] (#N in design order)`
  - `[D] Stop here`
- 提示："Revisions complete — [N] blockers resolved. What next?"
- 注明当前上下文用量：如果上下文超过约 50%，添加："(Recommended: /clear before re-review — this session has used X% context. A full re-review runs 5 agents and needs clean context.)"
- 选项：
  - `[A] Re-review in a new session — run /design-review [doc-path] after /clear`
  - `[B] Accept revisions for now — mark In Review in the systems index; a re-review decides Approved`
  - `[C] Move to next system — /design-system [next-system] (#N in design order)`
  - `[D] Stop here`

In collaborative and guided modes, never end the revision flow with plain text —
always close with this widget. In autonomous mode, summarize the outcome and
record via `log_decision`.
在协作和引导模式下，绝不用纯文本结束修订流程 —
始终用此组件收尾。在自主模式下，总结结果并通过 `log_decision`
记录。

**Second widget — tracking records (combined, for APPROVED path):**
**第二个组件 — 跟踪记录（合并，用于 APPROVED 路径）：**

When the verdict is APPROVED, use a single `AskUserQuestion` with `multiSelect: true` to batch the two tracking updates:
- Prompt: "Verdict: APPROVED. I can update the tracking records now. Select any you'd like me to complete:"
- Options:
  - `Update systems-index.md status to 'Approved' for [system]`
  - `Append approval entry to design/gdd/reviews/[doc-name]-review-log.md`
当裁决为 APPROVED 时，使用带有 `multiSelect: true` 的单个 `AskUserQuestion` 来批量执行两项跟踪更新：
- 提示："Verdict: APPROVED. I can update the tracking records now. Select any you'd like me to complete:"
- 选项：
  - `Update systems-index.md status to 'Approved' for [system]`
  - `Append approval entry to design/gdd/reviews/[doc-name]-review-log.md`

If the review-log option is selected, append the same format as below. Execute both selected actions before showing the final closing widget.
如果选择了 review-log 选项，按下文相同格式追加。在显示最终收尾组件之前执行两个选中的操作。

When the verdict is NEEDS REVISION or MAJOR REVISION NEEDED, use separate widgets as before:
当裁决为 NEEDS REVISION 或 MAJOR REVISION NEEDED 时，像之前一样使用单独的组件：

Use a second `AskUserQuestion`:
- Prompt: "May I update `design/gdd/systems-index.md` to mark [system] as [Needs Revision / In Review]?" — `Needs Revision` (that exact string) while the revisions are outstanding, `In Review` once they are applied and await re-review. This prompt never offers `Approved`: a revision verdict is not an approval.
- Options: `[A] Yes — update it` / `[B] No — leave it as-is`
使用第二个 `AskUserQuestion`：
- 提示："May I update `design/gdd/systems-index.md` to mark [system] as [Needs Revision / In Review]?" — 在修订尚未完成时使用 `Needs Revision`（该确切字符串），在应用修订并等待重新评审后使用 `In Review`。此提示从不提供 `Approved`：修订裁决不是批准。
- 选项：`[A] Yes — update it` / `[B] No — leave it as-is`

Use a third `AskUserQuestion`:
- Prompt: "May I append this review summary to `design/gdd/reviews/[doc-name]-review-log.md`? This creates a revision history so future re-reviews can track what changed."
- Options: `[A] Yes — append to review log` / `[B] No — skip`
使用第三个 `AskUserQuestion`：
- 提示："May I append this review summary to `design/gdd/reviews/[doc-name]-review-log.md`? This creates a revision history so future re-reviews can track what changed."
- 选项：`[A] Yes — append to review log` / `[B] No — skip`

If yes, append an entry in this format:
如果是，按此格式追加条目：
```
## Review — [YYYY-MM-DD] — Verdict: [APPROVED / NEEDS REVISION / MAJOR REVISION NEEDED]
Review mode: [full / lean / solo] · Workflow: [full / standard / minimal]
Scope signal: [S/M/L/XL]
Specialists: [list]
Blocking items: [count] | Recommended: [count]
Summary: [2-3 sentence summary of key findings from creative-director verdict]
Prior verdict resolved: [Yes / No / First review]
Findings:
- [BLOCKING] [section]: [one-line finding]
- [RECOMMENDED] [section]: [one-line finding]
[output of: Bash: bash .claude/scripts/review-receipts.sh hash "[target-doc-path]" "design/registry/entities.yaml" ".claude/skills/design-review/SKILL.md" [every other file this review read for cross-document facts: the related GDDs in design/gdd/, design/gdd/game-concept.md or design/game-brief.md, the design/narrative/ files] — a file that does not exist prints `not stamped, no such file` and is left out]
```

Findings rules: one line per finding, named by the section it lives in;
write `- none` when the verdict carried no findings. This is documentation
for a human reader of the revision history, not a mechanism the skill reads
back.
发现规则：每项发现一行，以其所在节命名；
当裁决不携带任何发现时写入 `- none`。这是为修订历史的
人类读者准备的文档，不是技能会回读的机制。

The hash line is the receipt Phase 1 reads on the next run to detect a
byte-identical re-review — the one form of skip that's actually safe,
because the input is provably the same, not merely believed to be adequately
covered by a prior pass. Stamp every file the review read: Phase 1's check
compares each stamped file on the next run, whether or not it names it. Always include it, whatever the verdict — an
unchanged document that previously FAILED review is exactly the case where
skipping a redundant re-review saves the most (the prior findings stand
verbatim).
哈希行是阶段 1 在下一次运行时读取以检测
字节相同重新评审的收据 — 这是唯一真正安全的跳过形式，
因为输入可证明是相同的，而不仅仅是相信它已被先前一次评审充分
覆盖。为评审读取的每个文件盖章：阶段 1 的检查
会在下一次运行时比较每个已盖章文件，无论它是否点名了它。始终包含它，无论裁决如何 — 一个
先前未通过评审的未更改文档，恰恰是跳过冗余重新评审节省最多的情况
（先前的发现原样成立）。

---

**Final closing widget — always show after all file writes complete:**
**最终收尾组件 — 在所有文件写入完成后始终显示：**

Once the systems-index and review-log widgets are answered, check project state and show one final `AskUserQuestion`:
一旦 systems-index 和 review-log 组件已回答，检查项目状态并显示最后一个 `AskUserQuestion`：

Before building options, read:
- `design/gdd/systems-index.md` — find any system with Status: In Review or Needs Revision (other than the one just reviewed). Read it by section: find the headings with the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and limit.
- Count `.md` files in `design/gdd/` (excluding game-concept.md, systems-index.md) to determine if `/review-all-gdds` is worth offering (≥2 GDDs)
- Find the next system with Status: Not Started in design order
在构建选项之前，读取：
- `design/gdd/systems-index.md` — 找出任何 Status 为 In Review 或 Needs Revision 的系统（刚评审过的除外）。按节读取：用 Grep 工具（模式 `^#`，content 模式）找到标题，并用 offset 和 limit 读取相应区间。
- 统计 `design/gdd/` 中的 `.md` 文件数（不含 game-concept.md、systems-index.md），以判断是否值得提供 `/review-all-gdds`（≥2 个 GDD）
- 按设计顺序找出下一个 Status 为 Not Started 的系统

Build the option list dynamically — only include options that are genuinely next:
- `[_] Run /design-review [other-gdd-path] — [system name] is still [In Review / Needs Revision]` (include if another GDD needs review)
- `[_] Run /consistency-check — verify this GDD's values don't conflict with existing GDDs` (always include if ≥1 other GDD exists)
- `[_] Run /review-all-gdds — holistic design-theory review across all designed systems` (include if ≥2 GDDs exist)
- `[_] Run /design-system [next-system] — next in design order` (always include, name the actual system)
- `[_] Stop here`
动态构建选项列表 — 只包含真正是下一步的选项：
- `[_] Run /design-review [other-gdd-path] — [system name] is still [In Review / Needs Revision]`（若有另一个 GDD 需要评审则包含）
- `[_] Run /consistency-check — verify this GDD's values don't conflict with existing GDDs`（若存在 ≥1 个其他 GDD 则始终包含）
- `[_] Run /review-all-gdds — holistic design-theory review across all designed systems`（若存在 ≥2 个 GDD 则包含）
- `[_] Run /design-system [next-system] — next in design order`（始终包含，点名实际系统）
- `[_] Stop here`

Assign letters A, B, C… only to included options. Mark the most pipeline-advancing option as `(recommended)`.
仅为包含的选项分配字母 A、B、C……。将最能推进流水线的选项标记为 `(recommended)`。

In collaborative and guided modes, never end the skill with plain text after
file writes — always close with this widget. In autonomous mode, print the next
step and record via `log_decision`.
在协作和引导模式下，绝不在文件写入后用纯文本结束技能 — 始终用此组件收尾。在自主模式下，打印下一步并通过 `log_decision`
记录。
