---
name: content-audit
description: "Audit GDD content counts against what's implemented — planned vs built."
argument-hint: "[system-name | --summary | (no arg = full audit)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/content-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: content-audit
description: "对照已实现内容审计 GDD 内容数量——计划与实际构建。"
argument-hint: "[system-name | --summary | (no arg = full audit)]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/content-audit/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与每次文件写入都遵循 `.claude/docs/automation-modes.md`（协作模式总是询问 · 引导模式仅重大问题 · 自主模式记录并继续；`automation_always_ask` 类别总是提示）。

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

已在上方解析——按原样使用。无块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

# Content Audit
# 内容审计

> Resolve `modes.workflow` before auditing: this skill's tier-dependent behaviour
> ("audit only specs in the required sections") follows the resolved tier, never
> an assumed one. When a required input such as `design/gdd/systems-index.md` is
> absent, report
> **`NOT ASSESSED — NO DATA`** rather than computing a gap percentage (which
> divides by zero when nothing is specified).

> 审计前解析 `modes.workflow`：此技能的层级相关行为（“仅审计必需章节中的规格”）遵循已解析的层级，绝不遵循假设的层级。当 `design/gdd/systems-index.md` 等必需输入缺失时，报告 **`NOT ASSESSED — NO DATA`**，而不是计算缺口百分比（在没有指定任何内容时会导致除以零）。


When this skill is invoked:

当本技能被调用时：

Parse the argument:
- No argument → full audit across all systems
- `[system-name]` → audit that single system only
- `--summary` → summary table only, no file write

解析参数：
- 无参数 → 跨所有系统的完整审计
- `[system-name]` → 仅审计该单一系统
- `--summary` → 仅摘要表，不写文件

---

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full content-count audit against all GDD specs.
- `standard` — audit only specs in the required sections; list any count found
  outside them as not audited at this tier.
- `minimal` — cannot run (no systems index exists).

**`workflow`**（参见 `.claude/docs/workflow-modes.md`）：
- `full`——对照所有 GDD 规格进行完整内容数量审计。
- `standard`——仅审计必需章节中的规格；将任何在必需章节之外发现的数量列为该层级未审计。
- `minimal`——无法运行（不存在系统索引）。

## Insufficient input — check this before producing any report
## 输入不足——在产出任何报告前先检查这一点

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

**如果本技能所需的输入不存在，答案是“无法运行”——而不是一份填写完整的报告。** 先检查，如果检查失败就停止。

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it (`/map-systems` for `design/gdd/systems-index.md`, `/design-system` for the GDDs).

1. 列出本技能读取的输入（数据文件、先前报告、性能分析器输出、测试结果、注册表、源代码）。
2. 对每个输入记录 `FOUND` 或 `ABSENT`——而不是“假设存在”。
3. 如果某章节所需的任何输入为 ABSENT，该章节为 **`NOT ASSESSED — NO DATA`**。不要估计它，不要从相邻产物推断它，也不要留下一个由下一个读模板的人填写的强制单元格。
4. 如果**每个**必需输入都为 ABSENT，停止并报告 **`NOT ASSESSED — NO DATA`** 作为整体结论，说明缺失了什么以及哪个技能产出它（`design/gdd/systems-index.md` 用 `/map-systems`，GDD 用 `/design-system`）。

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.

**`NOT ASSESSED` 的结论是一种成功。** 当没有数据时，它是对“数据说明了什么？”的正确、有用回答。这防止的失败模式很具体：如果一个报告的结论枚举中没有“无法运行”状态，就会产生**虚假的干净通过**——在一个没有资产也没有标准的项目上，资产审计返回 COMPLIANT，或性能分析在零性能分析器数据、从未设定预算的情况下报告“相对于 16.67ms 预算有 >99% 余量”。

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

**没有证据绝不是缺席的证据。** 一次扫描因为没有文件可扫描而找不到匹配，并没有验证任何东西。说明发生了这两种情况中的哪一种——读者无法从一个绿色结果中分辨。

---

## Phase 1 — Context Gathering
## 阶段 1——上下文收集

1. **Read `design/gdd/systems-index.md`** for the full list of systems, their
   categories, and MVP/priority tier. Read it by section: find the headings you need
   with the Grep tool (pattern `^#`, content mode) and Read those ranges with
   offset and limit.

1. **读取 `design/gdd/systems-index.md`**，获取系统完整列表、其类别以及 MVP/优先级层级。按章节读取：用 Grep 工具（模式 `^#`，内容模式）查找所需标题，并用 offset 和 limit 读取那些范围。

2. **Registry-first count**: If `design/registry/entities.yaml` exists, read it
   first. Its `entities` and `items` sections are the cross-GDD named content
   the audit is counting, already distilled with a `source:` GDD per entry:
   ```
   Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 2
   ```
   `- name:` appears in all four registry sections; keep only the names whose
   `-A 2` context shows they sit under `entities:` or `items:` (the named
   content this audit counts — not `formulas:`/`constants:`). Use those as the
   **planned** named-content set without full-reading the GDDs that own them.
   **If `design/registry/entities.yaml` does not exist or has no entries** (it
   ships as an empty stub until `/design-system` populates it), skip this step
   and rely on the GDD scan below — behaviour is unchanged, only more expensive.

2. **注册表优先计数**：如果 `design/registry/entities.yaml` 存在，先读取它。其 `entities` 和 `items` 部分是审计正在计数的跨 GDD 命名内容，已按条目提炼出 `source:` GDD：
   ```
   Grep pattern="^  - name:" path="design/registry/entities.yaml" output_mode="content" -A 2
   ```
   `- name:` 出现在所有四个注册表章节中；只保留那些 `-A 2` 上下文显示其位于 `entities:` 或 `items:` 之下的名称（即本审计计数的命名内容——不是 `formulas:`/`constants:`）。将它们作为**计划**命名内容集，无需完整读取拥有它们的 GDD。
   **如果 `design/registry/entities.yaml` 不存在或没有条目**（它作为空桩发布，直到 `/design-system` 填充它），跳过此步骤并依赖下方的 GDD 扫描——行为不变，只是开销更大。

3. **L0 pre-scan**: Before full-reading any GDDs, run **two** greps — they
   answer different questions and must not share a pattern:

   a. Which GDDs carry a Summary (the denominator / fail-open check):
   ```
   Grep pattern="^## Summary" glob="design/gdd/*.md" output_mode="files_with_matches"
   ```

   b. Which GDDs actually declare content counts (the narrowing step):
   ```
   Grep pattern="[0-9]+[[:space:]]+(enemies|enemy types|levels|areas|maps|stages|items|weapons|equipment|abilities|skills|spells|cutscenes|conversations|dialogue scenes|bosses|quests)|(enemy|item|weapon|ability|level) types:" glob="design/gdd/*.md" output_mode="files_with_matches"
   ```

3. **L0 预扫描**：在完整读取任何 GDD 之前，运行**两次** grep——它们回答不同问题，绝不能共用一个模式：

   a. 哪些 GDD 带有 Summary（分母 / 开放失败检查）：
   ```
   Grep pattern="^## Summary" glob="design/gdd/*.md" output_mode="files_with_matches"
   ```

   b. 哪些 GDD 实际声明内容数量（收窄步骤）：
   ```
   Grep pattern="[0-9]+[[:space:]]+(enemies|enemy types|levels|areas|maps|stages|items|weapons|equipment|abilities|skills|spells|cutscenes|conversations|dialogue scenes|bosses|quests)|(enemy|item|weapon|ability|level) types:" glob="design/gdd/*.md" output_mode="files_with_matches"
   ```

   > **Keep the two scans separate.** `## Summary` matches every compliant GDD,
   > so a union with it narrows nothing, and a literal placeholder such as
   > `N enemies` matches no real GDD. Pattern (b) matches digits followed by the
   > content nouns step 5 actually extracts.

   > **保持两次扫描分开。** `## Summary` 匹配每个合规 GDD，因此与它取并集不会收窄任何东西，而像 `N enemies` 这样的字面占位符不匹配任何真实 GDD。模式 (b) 匹配数字后跟步骤 5 实际提取的内容名词。

   **Fail open on a missing Summary.** Establish the denominator: glob
   `design/gdd/*.md` and count **N**. **Scan (a)** matching fewer than N means
   those GDDs predate `## Summary` — never treat an absent Summary as a system
   out of scope; a zero-match (a) means "no GDD carries a Summary yet", not "no
   auditable content". Full-read the unmatched in-scope GDDs.

   **在缺少 Summary 时开放失败。** 确立分母：glob `design/gdd/*.md` 并计数 **N**。**扫描 (a)** 匹配少于 N 意味着那些 GDD 早于 `## Summary`——绝不要将缺少 Summary 视为系统超出范围；零匹配的 (a) 意味着“尚无 GDD 带有 Summary”，而不是“没有可审计内容”。完整读取未匹配的在范围内 GDD。

   For a single-system audit: skip this step and go straight to full-read.
   For a full audit: full-read the GDDs that **scan (b)** matched
   **and are not already fully covered by the registry entries from step 2**,
   plus every GDD scan (a) missed — **the fail-open rule wins over this
   narrowing**: a GDD with no `## Summary` is full-read even when scan (b) did
   not match it. Only a GDD that has a Summary and no content-count language (a
   pure mechanics GDD) is noted as "No auditable content counts" without a full
   read.

   对于单系统审计：跳过此步骤，直接完整读取。对于完整审计：完整读取**扫描 (b)** 匹配**且尚未被步骤 2 注册表条目完全覆盖**的 GDD，加上扫描 (a) 遗漏的每个 GDD——**开放失败规则优先于这种收窄**：没有 `## Summary` 的 GDD 即使扫描 (b) 未匹配它也要完整读取。只有带 Summary 且无内容计数措辞的 GDD（纯机制 GDD）才在不完整读取的情况下记为“No auditable content counts”。

4. **Full-read in-scope GDD files** (or the single system GDD if a system
   name was given). This step needs the whole GDD: read it in ranges by its
   headings (found with the Grep tool: pattern `^#`, content mode), since a
   whole-file Read over 40 KB is refused.

4. **完整读取在范围内的 GDD 文件**（如果给出了系统名，则为单个系统 GDD）。此步骤需要整个 GDD：按其标题分范围读取（用 Grep 工具查找：模式 `^#`，内容模式），因为超过 40 KB 的整文件 Read 会被拒绝。

5. **For each GDD, extract explicit content counts or lists**, noting the `##` section each sits under — at `standard`, a count outside the required sections (`.claude/docs/workflow-modes.md`) goes on the "Not audited at this tier" list, never into the inventory. Look for patterns
   like:
   - "N enemies" / "enemy types:" / list of named enemies
   - "N levels" / "N areas" / "N maps" / "N stages"
   - "N items" / "N weapons" / "N equipment pieces"
   - "N abilities" / "N skills" / "N spells"
   - "N dialogue scenes" / "N conversations" / "N cutscenes"
   - "N quests" / "N missions" / "N objectives"
   - Any explicit enumerated list (bullet list of named content pieces)

5. **对每个 GDD，提取显式内容数量或列表**，并注明每个所在 `##` 章节——在 `standard` 下，位于必需章节之外的数量（`.claude/docs/workflow-modes.md`）进入“Not audited at this tier”列表，绝不进入清单。查找如下模式：
   - "N enemies" / "enemy types:" / 命名敌人列表
   - "N levels" / "N areas" / "N maps" / "N stages"
   - "N items" / "N weapons" / "N equipment pieces"
   - "N abilities" / "N skills" / "N spells"
   - "N dialogue scenes" / "N conversations" / "N cutscenes"
   - "N quests" / "N missions" / "N objectives"
   - 任何显式枚举列表（命名内容条目的项目符号列表）

6. **Build a content inventory table** from the extracted data:

   | System | Content Type | Specified Count/List | Source GDD |
   |--------|-------------|---------------------|------------|

   Note: If a GDD describes content qualitatively but gives no count, record
   "Unspecified" and flag it — unspecified counts are a design gap worth noting.

6. **从提取的数据构建内容清单表**：

   | 系统 | 内容类型 | 指定数量/列表 | 来源 GDD |
   |--------|-------------|---------------------|------------|

   注意：如果 GDD 定性描述内容但没有给出数量，记录 "Unspecified" 并标记它——未指定数量是值得注意的设计缺口。

---

## Phase 2 — Implementation Scan
## 阶段 2——实现扫描

For each content type found in Phase 1, scan the relevant directories to count
what has been implemented. Use Glob and Grep to locate files.

对于阶段 1 中发现的每种内容类型，扫描相关目录以计数已实现的内容。使用 Glob 和 Grep 定位文件。

**On Unreal, content lives in `Content/`** — maps and data assets both — and the
code root (`Source/<Module>/`) holds only C++. So on Unreal, every `assets/…` glob
below also runs under `Content/` (`*.uasset` in place of the data extensions),
and levels are `Content/**/*.umap`. Skipping this finds zero levels on every
Unreal project and reports them NOT STARTED.

**在 Unreal 上，内容位于 `Content/`**——地图和数据资产都是——代码根（`Source/<Module>/`）仅包含 C++。因此在 Unreal 上，下方每个 `assets/…` glob 也要在 `Content/` 下运行（用 `*.uasset` 代替数据扩展名），关卡是 `Content/**/*.umap`。跳过这一点会在每个 Unreal 项目上找到零关卡并报告它们 NOT STARTED。

**On Unity, content lives under `Assets/`** (compare the case exactly —
`.claude/docs/code-root-resolution.md`), and rarely in a `data/` folder. So on
Unity every `assets/…` glob below also runs under `Assets/`, without requiring
a `data/` segment — for items, `Assets/**/items/**`, `Assets/**/Items/**` and
`Assets/**/*Item*.asset` — and data files include `.asset` (ScriptableObjects)
and `.prefab`. Skipping this finds zero items, abilities, quests and dialogue
on a Unity project and reports them NOT STARTED.

**在 Unity 上，内容位于 `Assets/` 下**（精确比较大小写——`.claude/docs/code-root-resolution.md`），很少在 `data/` 文件夹中。因此在 Unity 上，下方每个 `assets/…` glob 也要在 `Assets/` 下运行，不要求 `data/` 段——对于物品，为 `Assets/**/items/**`、`Assets/**/Items/**` 和 `Assets/**/*Item*.asset`——数据文件包括 `.asset`（ScriptableObjects）和 `.prefab`。跳过这一点会在 Unity 项目上找到零物品、能力、任务和对话，并报告它们 NOT STARTED。

**Levels / Areas / Maps:**
- Glob `assets/**/*.tscn`, `assets/**/*.unity`, `assets/**/*.umap`
- Glob the **code root** for scene files: `*.tscn` (Godot), `*.unity` (Unity); on Unreal, `Content/**/*.umap` instead (above). Resolve the root per `.claude/docs/code-root-resolution.md`. **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.**
- Look for scene files in subdirectories named `levels/`, `areas/`, `maps/`,
  `worlds/`, `stages/`
- Count unique files that appear to be level/scene definitions (not UI scenes)

**关卡 / 区域 / 地图：**
- Glob `assets/**/*.tscn`、`assets/**/*.unity`、`assets/**/*.umap`
- 在**代码根**中 Glob 场景文件：`*.tscn`（Godot）、`*.unity`（Unity）；在 Unreal 上改为 `Content/**/*.umap`（见上）。按 `.claude/docs/code-root-resolution.md` 解析根。**如果代码根未解析，报告 `NOT ASSESSED — code root unresolved`，而不是零命中。**
- 查找名为 `levels/`、`areas/`、`maps/`、`worlds/`、`stages/` 的子目录中的场景文件
- 计数看似是关卡/场景定义的唯一文件（不是 UI 场景）

**Enemies / Characters / NPCs:**
- Glob `assets/data/**/enemies/**`, `assets/data/**/characters/**`
- Glob `<code root>/**/enemies/**`, `<code root>/**/characters/**`
- Look for `.json`, `.tres`, `.asset`, `.yaml` data files defining entity stats
- Look for scene/prefab files in character subdirectories

**敌人 / 角色 / NPC：**
- Glob `assets/data/**/enemies/**`、`assets/data/**/characters/**`
- Glob `<code root>/**/enemies/**`、`<code root>/**/characters/**`
- 查找定义实体属性的 `.json`、`.tres`、`.asset`、`.yaml` 数据文件
- 查找角色子目录中的场景/预制体文件

**Items / Equipment / Loot:**
- Glob `assets/data/**/items/**`, `assets/data/**/equipment/**`,
  `assets/data/**/loot/**`
- Look for `.json`, `.tres`, `.asset` data files

**物品 / 装备 / 战利品：**
- Glob `assets/data/**/items/**`、`assets/data/**/equipment/**`、`assets/data/**/loot/**`
- 查找 `.json`、`.tres`、`.asset` 数据文件

**Abilities / Skills / Spells:**
- Glob `assets/data/**/abilities/**`, `assets/data/**/skills/**`,
  `assets/data/**/spells/**`
- Look for `.json`, `.tres`, `.asset` data files

**能力 / 技能 / 法术：**
- Glob `assets/data/**/abilities/**`、`assets/data/**/skills/**`、`assets/data/**/spells/**`
- 查找 `.json`、`.tres`、`.asset` 数据文件

**Dialogue / Conversations / Cutscenes:**
- Glob `assets/**/*.dialogue`, `assets/**/*.csv`, `assets/**/*.ink`
- Grep for dialogue data files in `assets/data/`

**对话 / 会话 / 过场动画：**
- Glob `assets/**/*.dialogue`、`assets/**/*.csv`、`assets/**/*.ink`
- 在 `assets/data/` 中 Grep 对话数据文件

**Quests / Missions:**
- Glob `assets/data/**/quests/**`, `assets/data/**/missions/**`
- Look for `.json`, `.yaml` definition files

**任务 / 使命：**
- Glob `assets/data/**/quests/**`、`assets/data/**/missions/**`
- 查找 `.json`、`.yaml` 定义文件

**Engine-specific notes (acknowledge in the report):**
- Counts are approximations — the skill cannot perfectly parse every engine
  format or distinguish editor-only files from shipped content
- Scene files may include both gameplay content and system/UI scenes; the scan
  counts all matches and notes this caveat

**引擎特定说明（在报告中确认）：**
- 计数是近似值——该技能无法完美解析每种引擎格式，或区分仅编辑器文件与已发布内容
- 场景文件可能同时包含玩法内容和系统/UI 场景；扫描计数所有匹配并注明此限制

---

## Phase 3 — Gap Report
## 阶段 3——缺口报告

Produce the gap table:

生成缺口表：

```
| System | Content Type | Specified | Found | Gap | Status |
|--------|-------------|-----------|-------|-----|--------|
```

```
| 系统 | 内容类型 | 指定 | 发现 | 缺口 | 状态 |
|--------|-------------|-----------|-------|-----|--------|
```

**Status categories:**
- `COMPLETE` — Found ≥ Specified (100%+)
- `IN PROGRESS` — Found is 50–99% of Specified
- `EARLY` — Found is 1–49% of Specified
- `NOT STARTED` — Found is 0

**状态类别：**
- `COMPLETE`——发现 ≥ 指定（100%+）
- `IN PROGRESS`——发现为指定的 50–99%
- `EARLY`——发现为指定的 1–49%
- `NOT STARTED`——发现为 0

**Priority flags:**
Flag a system as `HIGH PRIORITY` in the report if:
- Status is `NOT STARTED` or `EARLY`, AND
- The system is tagged MVP or Vertical Slice in the systems index, OR
- The systems index shows the system is blocking downstream systems

**优先级标记：**
在报告中将系统标记为 `HIGH PRIORITY`，如果：
- 状态为 `NOT STARTED` 或 `EARLY`，并且
- 该系统在系统索引中被标记为 MVP 或 Vertical Slice，或
- 系统索引显示该系统正在阻塞下游系统

**Summary line:**
- Total content items specified (sum of all Specified column values)
- Total content items found (sum of all Found column values)
- Overall gap percentage: `(Specified - Found) / Specified * 100`

**摘要行：**
- 指定内容条目总数（所有 Specified 列值之和）
- 发现内容条目总数（所有 Found 列值之和）
- 整体缺口百分比：`(Specified - Found) / Specified * 100`

A row whose Found is `NOT ASSESSED` (code root unresolved) has no Gap or
Status, is never `NOT STARTED`, and stays out of both totals; the summary names it.

Found 为 `NOT ASSESSED`（代码根未解析）的行没有 Gap 或 Status，绝不是 `NOT STARTED`，也不进入两个总计；摘要会指出它。

---

## Phase 4 — Output
## 阶段 4——输出

### Full audit and single-system modes
### 完整审计与单系统模式

Present the gap table and summary to the user. Ask: "May I write the full report to `docs/content-audit-[YYYY-MM-DD].md`?"

向用户呈现缺口表和摘要。询问：“我可以将完整报告写入 `docs/content-audit-[YYYY-MM-DD].md` 吗？”

If yes, write the file:

如果是，写入文件：

```markdown
# Content Audit — [Date]

## Summary
- **Total specified**: [N] content items across [M] systems
- **Total found**: [N]
- **Gap**: [N] items ([X%] unimplemented)
- **Scope**: [Full audit | System: name] — [all GDD sections | required sections only (workflow: standard)]
- **Not audited at this tier**: [counts found only outside the required sections — or "none"; omit at `full`]

> Note: Counts are approximations based on file scanning.
> The audit cannot distinguish shipped content from editor/test assets.
> Manual verification is recommended for any HIGH PRIORITY gaps.

## Gap Table

| System | Content Type | Specified | Found | Gap | Status |
|--------|-------------|-----------|-------|-----|--------|

## HIGH PRIORITY Gaps

[List systems flagged HIGH PRIORITY with rationale]

## Per-System Breakdown

### [System Name]
- **GDD**: `design/gdd/[file].md`
- **Content types audited**: [list]
- **Notes**: [any caveats about scan accuracy for this system]

## Recommendation

Focus implementation effort on:
1. [Highest-gap HIGH PRIORITY system]
2. [Second system]
3. [Third system]

## Unspecified Content Counts

The following GDDs describe content without giving explicit counts.
Consider adding counts to improve auditability:
[List of GDDs and content types with "Unspecified"]
```

```markdown
# 内容审计——[Date]

## 摘要
- **指定总数**：[N] 个内容条目，跨 [M] 个系统
- **发现总数**：[N]
- **缺口**：[N] 个条目（[X%] 未实现）
- **范围**：[Full audit | System: name]——[all GDD sections | required sections only (workflow: standard)]
- **该层级未审计**：[仅在必需章节之外发现的数量——或 "none"；在 `full` 下省略]

> 注意：计数是基于文件扫描的近似值。
> 审计无法区分已发布内容与编辑器/测试资产。
> 建议对任何 HIGH PRIORITY 缺口进行人工验证。

## 缺口表

| 系统 | 内容类型 | 指定 | 发现 | 缺口 | 状态 |
|--------|-------------|-----------|-------|-----|--------|

## HIGH PRIORITY 缺口

[列出被标记为 HIGH PRIORITY 的系统及理由]

## 按系统细分

### [System Name]
- **GDD**：`design/gdd/[file].md`
- **已审计内容类型**：[list]
- **备注**：[关于该系统扫描准确性的任何限制]

## 建议

将实现工作集中在：
1. [缺口最大的 HIGH PRIORITY 系统]
2. [第二系统]
3. [第三系统]

## 未指定内容数量

以下 GDD 描述内容但未给出显式数量。
考虑添加数量以提高可审计性：
[GDD 和内容类型为 "Unspecified" 的列表]
```

After writing the report, ask:

写入报告后，询问：

> "Would you like to create backlog stories for any of the content gaps?"

> “你想为任何内容缺口创建待办故事吗？”

If yes: for each system the user selects, suggest a story title and point them
to `/create-stories [epic-slug]` or `/quick-design` depending on the size of the gap.

如果是：对于用户选择的每个系统，建议一个故事标题，并根据缺口大小指向 `/create-stories [epic-slug]` 或 `/quick-design`。

### --summary mode
### --summary 模式

Print the Gap Table and Summary directly to conversation. Do not write a file.
End with: "Run `/content-audit` without `--summary` to write the full report."

直接在对话中打印缺口表和摘要。不要写文件。
以以下内容结束：“运行不带 `--summary` 的 `/content-audit` 以写入完整报告。”

---

## Phase 5 — Next Steps
## 阶段 5——后续步骤

After the audit, recommend the highest-value follow-up actions:

审计后，建议价值最高的后续行动：

- If any system is `NOT STARTED` and MVP-tagged → "Run `/design-system [name]` to
  add missing content counts to the GDD before implementation begins."
- If total gap is >50% → "Run `/sprint-plan` to allocate content work across upcoming sprints."
- If any system is flagged HIGH PRIORITY → "Run `/create-stories [epic-slug]` for each HIGH PRIORITY gap."
- If `--summary` was used → "Run `/content-audit` (no flag) to write the full report to `docs/`."

- 如果任何系统为 `NOT STARTED` 且标记为 MVP → “运行 `/design-system [name]`，在实现开始前为 GDD 添加缺失的内容数量。”
- 如果总缺口 >50% → “运行 `/sprint-plan` 将内容工作分配到即将到来的冲刺。”
- 如果任何系统被标记为 HIGH PRIORITY → “为每个 HIGH PRIORITY 缺口运行 `/create-stories [epic-slug]`。”
- 如果使用了 `--summary` → “运行 `/content-audit`（无标志）将完整报告写入 `docs/`。”

Close with the verdict that matches the run:
- Verdict: **COMPLETE** — content audit finished.
- Verdict: **NOT ASSESSED — NO DATA** — a required input was absent (see the note at
  the top), nothing in scope gives a count (no registry entry, and every GDD is
  "Unspecified" or "No auditable content counts"), or a Found count could not be taken
  (`NOT ASSESSED — code root unresolved`); name which, and for missing counts
  name `/design-system`. Never print COMPLETE for a run that could not compute a gap.

以符合本次运行的结论结束：
- 结论：**COMPLETE**——内容审计已完成。
- 结论：**NOT ASSESSED — NO DATA**——某个必需输入缺失（见顶部说明），范围内没有任何内容给出数量（没有注册表条目，且每个 GDD 都是 "Unspecified" 或 "No auditable content counts"），或无法取得 Found 计数（`NOT ASSESSED — code root unresolved`）；指出是哪一种，对于缺失数量则指出 `/design-system`。绝不要为无法计算缺口的运行打印 COMPLETE。
