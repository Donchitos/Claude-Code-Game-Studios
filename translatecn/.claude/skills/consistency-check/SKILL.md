---
name: consistency-check
description: "Scan GDDs against the entity registry for cross-document conflicts. Grep-first approach targets conflicting sections, different stats."
argument-hint: "[full | since-last-review | entity:<name> | item:<name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/consistency-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *), Bash(bash .claude/scripts/registry.sh validate*)
model: sonnet
---
---
name: consistency-check
description: "对照实体注册表扫描 GDD 以发现跨文档冲突。Grep 优先的方法只针对冲突章节、不同的数值。"
argument-hint: "[full | since-last-review | entity:<name> | item:<name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(bash "*/.claude/skills/consistency-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *), Bash(bash .claude/scripts/registry.sh validate*)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,system_overrides`



# Consistency Check
# 一致性检查

Detects cross-document inconsistencies by comparing all GDDs against the
entity registry (`design/registry/entities.yaml`). Uses a grep-first approach:
reads the registry once, then targets only the GDD sections that mention
registered names — no full document reads unless a conflict needs investigation.
通过将所有 GDD 与实体注册表（`design/registry/entities.yaml`）对比来检测跨文档不一致。采用 grep 优先的方法：读取一次注册表，然后只针对提及已注册名称的 GDD 章节——除非某个冲突需要调查，否则不做整份文档读取。

**This skill is the write-time safety net.** It catches what `/design-system`'s
per-section checks may have missed and what `/review-all-gdds`'s holistic review
catches too late.
**本技能是写入时的安全网。** 它捕捉 `/design-system` 逐章节检查可能遗漏的内容，以及 `/review-all-gdds` 的整体评审发现得太晚的内容。

**When to run:**
- After writing each new GDD (before moving to the next system)
- Before `/review-all-gdds` (so that skill starts with a clean baseline)
- Before `/create-architecture` (inconsistencies poison downstream ADRs)
- On demand: `/consistency-check entity:[name]` to check one entity specifically
**何时运行：**
- 在编写每个新 GDD 之后（在进入下一个系统之前）
- 在 `/review-all-gdds` 之前（让该技能从一个干净的基线开始）
- 在 `/create-architecture` 之前（不一致会毒害下游的 ADR）
- 按需：`/consistency-check entity:[name]` 专门检查一个实体

**Output:** Conflict report + optional registry corrections
**产出：** 冲突报告 + 可选的注册表修正

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`（collaborative 始终询问 · guided 仅重大问题 · autonomous 记录并继续；`automation_always_ask` 类别始终提示）。

**`workflow`** (see `.claude/docs/workflow-modes.md`), applied per GDD at its
**effective** tier — the `system_overrides` row for that GDD's system (its
filename stem) when the block lists one, else the project value:
- `full` — full entity-registry cross-check against all GDD sections.
- `standard` — cross-check against the required sections only. The report's
  Scope line says so, and each value stated for a registered name outside those
  sections is listed as not checked at this tier (Phase 3 applies this).
- `minimal` — not meaningful (no GDDs to check).
**`workflow`**（见 `.claude/docs/workflow-modes.md`），按每个 GDD 在其**生效**层级应用——当该块列出时，使用该 GDD 所属系统（其文件名主干）的 `system_overrides` 行，否则使用项目值：
- `full` — 对所有 GDD 章节进行完整的实体注册表交叉检查。
- `standard` — 仅对必需章节进行交叉检查。报告的 Scope 行会说明这一点，而针对已注册名称、位于这些章节之外的每个值，都会被列为在该层级未检查（阶段 3 应用此规则）。
- `minimal` — 无意义（没有 GDD 可检查）。

## Phase 1: Parse Arguments and Load Registry
## 阶段 1：解析参数并加载注册表

**Modes:**
- No argument / `full` — check all registered entries against all GDDs
- `since-last-review` — check only GDDs modified since the last review report
- `entity:<name>` — check one specific entity across all GDDs
- `item:<name>` — check one specific item across all GDDs
**模式：**
- 无参数 / `full` — 对照所有 GDD 检查所有已注册条目
- `since-last-review` — 仅检查自上次评审报告以来修改过的 GDD
- `entity:<name>` — 跨所有 GDD 检查某一个特定实体
- `item:<name>` — 跨所有 GDD 检查某一个特定物品

**Load the registry:**
**加载注册表：**

```
Read path="design/registry/entities.yaml"
```

If the file does not exist or has no entries:
> "Entity registry is empty. Run `/design-system` to write GDDs — the registry
> is populated automatically after each GDD is completed. Nothing to check yet."
如果该文件不存在或没有条目：
> “实体注册表为空。运行 `/design-system` 来编写 GDD——注册表会在每个 GDD 完成后自动填充。目前没有可检查的内容。”

Verdict: **NOT ASSESSED — entity registry empty**. Stop: nothing was compared,
so there is no PASS to give and nothing to write.
判定：**NOT ASSESSED——实体注册表为空**。停止：没有做任何比较，因此没有 PASS 可给，也没有可写的内容。

Build four lookup tables from the registry:
- **entity_map**: `{ name → { source, attributes, referenced_by } }`
- **item_map**: `{ name → { source, value_gold, weight, ... } }`
- **formula_map**: `{ name → { source, variables, output_range } }`
- **constant_map**: `{ name → { source, value, unit } }`
从注册表构建四张查找表：
- **entity_map**：`{ name → { source, attributes, referenced_by } }`
- **item_map**：`{ name → { source, value_gold, weight, ... } }`
- **formula_map**：`{ name → { source, variables, output_range } }`
- **constant_map**：`{ name → { source, value, unit } }`

Count total registered entries. Report:
统计已注册条目的总数。报告：
```
Registry loaded: [N] entities, [N] items, [N] formulas, [N] constants
Scope: [full | since-last-review | entity:name]
```

For `entity:<name>` or `item:<name>`, if the registry has no entry by that name
the verdict is **NOT ASSESSED — `<name>` is not in the registry**: list the
closest registered names and stop. Checking an unregistered name compares
nothing, and that is not a PASS.
对于 `entity:<name>` 或 `item:<name>`，如果注册表中没有该名称的条目，判定就是 **NOT ASSESSED——`<name>` 不在注册表中**：列出最接近的已注册名称并停止。检查一个未注册的名称没有比较任何东西，那不是 PASS。

---

## Phase 2: Locate In-Scope GDDs
## 阶段 2：定位范围内的 GDD

```
Glob pattern="design/gdd/*.md"
```

Exclude the docs that live in `design/gdd/` but are not system GDDs:
`game-concept.md`, `systems-index.md`, `game-pillars.md`, `gameplay-tags.md`,
`entity-registry.md`, `fixture-swap-ledger.md`, `sound-bible.md` and any
`gdd-cross-review-*.md` (the report `/review-all-gdds` writes here).
排除位于 `design/gdd/` 但不是系统 GDD 的文档：`game-concept.md`、`systems-index.md`、`game-pillars.md`、`gameplay-tags.md`、`entity-registry.md`、`fixture-swap-ledger.md`、`sound-bible.md`，以及任何 `gdd-cross-review-*.md`（即 `/review-all-gdds` 写到此处的报告）。

For `since-last-review` mode:
对于 `since-last-review` 模式：
```bash
git log --name-only --pretty=format: -- design/gdd/ | grep "\.md$" | sort -u
```
Limit to GDDs modified since the most recent `design/gdd/gdd-cross-review-*.md`
file's creation date.
限定为自最近一个 `design/gdd/gdd-cross-review-*.md` 文件创建日期以来修改过的 GDD。

Report the in-scope GDD list before scanning. **If the list is empty** — no system
GDDs exist, or `since-last-review` found none changed — the verdict is
**NOT ASSESSED — no GDDs in scope**: say which filter produced zero, and stop.
A scan of nothing finds no conflicts, and that is not a PASS.
在扫描前上报范围内的 GDD 列表。**如果列表为空**——不存在系统 GDD，或 `since-last-review` 未发现任何改动——判定就是 **NOT ASSESSED——范围内没有 GDD**：说明是哪个过滤器产生了零结果，并停止。对空无的扫描找不到冲突，那不是 PASS。

---

## Phase 3: Grep-First Conflict Scan
## 阶段 3：Grep 优先的冲突扫描

For each registered entry, grep every in-scope GDD for the entry's name.
Do NOT do full reads — extract only the matching lines and their immediate
context (-C 3 lines).
对每个已注册条目，在所有范围内的 GDD 中 grep 该条目的名称。不要做整份读取——只提取匹配行及其紧邻上下文（-C 3 行）。

This is the core optimization: instead of reading 10 GDDs × 400 lines each
(4,000 lines), you grep 50 entity names × 10 GDDs (50 targeted searches,
each returning ~10 lines on a hit).
这是核心优化：与其读取 10 份 GDD × 每份 400 行（4,000 行），你只需 grep 50 个实体名称 × 10 份 GDD（50 次定向搜索，每次命中的返回约 10 行）。

**In a GDD whose effective tier is `standard`, compare only hits under a
required section.** The effective tier is per GDD: `system_overrides.<stem>`
replaces the project tier for that GDD in either direction (a `full` row makes
every section compared). Grep each such GDD once for `^## ` to get its headings
and line numbers, and file every name hit under the nearest heading above it:
only hits under Overview, Detailed Rules / Detailed Design, Formulas, Edge
Cases, Dependencies or Acceptance Criteria are compared — plus Tuning Knobs when
`project.yaml` sets `workflow_overrides.tuning_knobs: true` (read that flag
once; it only ever adds the section). Any other hit (Tuning Knobs without the
flag, Player Fantasy, any other section) raises no finding and is not logged;
list each one that states a value (name, GDD, section) on the report's
`Not checked at this tier` line.
**在生效层级为 `standard` 的 GDD 中，只比较必需章节下的命中。** 生效层级是按 GDD 的：`system_overrides.<stem>` 在两个方向上替换该 GDD 的项目层级（`full` 行会使所有章节都被比较）。对每个这样的 GDD 用 `^## ` grep 一次，以取得其标题和行号，并把每个名称命中归到其上方最近的标题之下：只有 Overview、Detailed Rules / Detailed Design、Formulas、Edge Cases、Dependencies 或 Acceptance Criteria 下的命中会被比较——此外当 `project.yaml` 设置 `workflow_overrides.tuning_knobs: true` 时也包括 Tuning Knobs（该标志只读一次；它只会增加该章节）。任何其他命中（未设置标志时的 Tuning Knobs、Player Fantasy、任何其他章节）都不产生发现，也不记录；将其中陈述了数值的每一项（名称、GDD、章节）列在报告的 `Not checked at this tier` 行上。

### 3a: Entity Scan
### 3a：实体扫描

For each entity in entity_map:
对 entity_map 中的每个实体：

```
Grep pattern="[entity_name]" glob="design/gdd/*.md" output_mode="content" -C 3
```

For each GDD hit, extract the values mentioned near the entity name:
- any numeric attributes (counts, costs, durations, ranges, rates)
- any categorical attributes (types, tiers, categories)
- any derived values (totals, outputs, results)
- any other attributes registered in entity_map
对每个 GDD 命中，提取实体名称附近提到的值：
- 任何数值属性（数量、成本、持续时间、范围、比率）
- 任何分类属性（类型、层级、类别）
- 任何派生值（总计、输出、结果）
- 在 entity_map 中注册的任何其他属性

Compare extracted values against the registry entry.
将提取的值与注册表条目进行对比。

**Conflict detection:**
- Registry says `[entity_name].[attribute] = [value_A]`. GDD says `[entity_name] has [value_B]`. → **CONFLICT**
- Registry says `[item_name].[attribute] = [value_A]`. GDD says `[item_name] is [value_B]`. → **CONFLICT**
- GDD mentions `[entity_name]` but doesn't specify the attribute. → **NOTE** (no conflict, just unverifiable)
**冲突检测：**
- 注册表说 `[entity_name].[attribute] = [value_A]`。GDD 说 `[entity_name] has [value_B]`。→ **CONFLICT**
- 注册表说 `[item_name].[attribute] = [value_A]`。GDD 说 `[item_name] is [value_B]`。→ **CONFLICT**
- GDD 提到 `[entity_name]` 但没有指明该属性。→ **NOTE**（无冲突，只是无法验证）

### 3b: Item Scan
### 3b：物品扫描

For each item in item_map, grep all GDDs for the item name. Extract:
- sell price / value / gold value
- weight
- stack rules (stackable / non-stackable)
- category
对 item_map 中的每个物品，在所有 GDD 中 grep 该物品名称。提取：
- 售价 / 价值 / 金币价值
- 重量
- 堆叠规则（可堆叠 / 不可堆叠）
- 类别

Compare against registry entry values.
与注册表条目值进行对比。

### 3c: Formula Scan
### 3c：公式扫描

For each formula in formula_map, grep all GDDs for the formula name. Extract:
- variable names mentioned near the formula
- output range or cap values mentioned
对 formula_map 中的每个公式，在所有 GDD 中 grep 该公式名称。提取：
- 公式附近提到的变量名
- 提到的输出范围或上限值

Compare against registry entry:
- Different variable names → **CONFLICT**
- Output range stated differently → **CONFLICT**
与注册表条目对比：
- 变量名不同 → **CONFLICT**
- 输出范围的表述不同 → **CONFLICT**

### 3d: Constant Scan
### 3d：常量扫描

For each constant in constant_map, grep all GDDs for the constant name. Extract:
- Any numeric value mentioned near the constant name
对 constant_map 中的每个常量，在所有 GDD 中 grep 该常量名称。提取：
- 常量名称附近提到的任何数值

Compare against registry value:
- Different number → **CONFLICT**
与注册表值对比：
- 数字不同 → **CONFLICT**

---

## Phase 4: Deep Investigation (Conflicts Only)
## 阶段 4：深入调查（仅冲突）

For each conflict found in Phase 3, do a targeted full-section read of the
conflicting GDD to get precise context:
对阶段 3 中发现的每个冲突，对冲突的 GDD 做一次定向的整节读取，以获得精确上下文：

```
Read path="design/gdd/[conflicting_gdd].md"
```
(Or use Grep with wider context if the file is large)
（如果文件很大，或改用带更宽上下文的 Grep）

Read it by section: find the conflicting section's heading with the Grep tool
(pattern `^#`, content mode) and Read that range with offset and limit.
按节读取：用 Grep 工具（模式 `^#`，内容模式）找到冲突章节的标题，并用 offset 和 limit 读取该范围。

Confirm the conflict with full context. Determine:
1. **Which GDD is correct?** Check the `source:` field in the registry — the
   source GDD is the authoritative owner. Any other GDD that contradicts it
   is the one that needs updating.
2. **Is the registry itself out of date?** If the source GDD was updated after
   the registry entry was written (check git log), the registry may be stale.
3. **Is this a genuine design change?** If the conflict represents an intentional
   design decision, the resolution is: update the source GDD, update the registry,
   then fix all other GDDs.
结合完整上下文确认该冲突。判断：
1. **哪份 GDD 是正确的？** 检查注册表中的 `source:` 字段——源 GDD 是权威所有者。任何与其矛盾的其他 GDD 才是需要更新的那份。
2. **注册表本身是否过时？** 如果源 GDD 在注册表条目写入之后被更新过（检查 git log），注册表可能已过时。
3. **这是否是一次真正的设计变更？** 如果该冲突代表一项有意的设计决策，解决办法是：更新源 GDD、更新注册表，然后修复所有其他 GDD。

For each conflict, classify:
- **🔴 CONFLICT** — same named entity/item/formula/constant with different values
  in different GDDs. Must resolve before architecture begins.
- **⚠️ STALE REGISTRY** — source GDD value changed but registry not updated.
  Registry needs updating; other GDDs may be correct already.
- **ℹ️ UNVERIFIABLE** — entity mentioned but no comparable attribute stated.
  Not a conflict; just noting the reference.
对每个冲突分类：
- **🔴 CONFLICT** — 同一具名实体/物品/公式/常量在不同 GDD 中具有不同数值。必须在架构开始前解决。
- **⚠️ STALE REGISTRY** — 源 GDD 的数值已更改，但注册表未更新。注册表需要更新；其他 GDD 可能已经正确。
- **ℹ️ UNVERIFIABLE** — 提到了实体但未陈述可比较的属性。不是冲突；只是记录该引用。

---

## Phase 5: Output Report
## 阶段 5：输出报告

```
## Consistency Check Report
Date: [date]
Registry entries checked: [N entities, N items, N formulas, N constants]
GDDs scanned: [N] ([list names])
Scope: [all GDD sections | required sections only — workflow: standard | per GDD — name each GDD whose effective tier differs, and its tier]
Not checked at this tier: [each value stated outside the required sections (name, GDD, section) — or "none"; omit when every GDD is at `full`]

---

### Conflicts Found (must resolve before architecture)

🔴 [Entity/Item/Formula/Constant Name]
   Registry (source: [gdd]): [attribute] = [value]
   Conflict in [other_gdd].md: [attribute] = [different_value]
   → Resolution needed: [which doc to change and to what]

---

### Stale Registry Entries (registry behind the GDD)

⚠️ [Entry Name]
   Registry says: [value] (written [date])
   Source GDD now says: [new value]
   → Update registry entry to match source GDD, then check referenced_by docs.

---

### Unverifiable References (no conflict, informational)

ℹ️ [gdd].md mentions [entity_name] but states no comparable attributes.
   No conflict detected. No action required.

---

### Clean Entries (no issues found)

✅ [N] registry entries verified across all GDDs with no conflicts.

---

Verdict: PASS | CONFLICTS FOUND | NOT ASSESSED
```

**Verdict:**
- **CONFLICTS FOUND** — one or more conflicts detected. List resolution steps.
- **NOT ASSESSED** — nothing was compared: the entity registry is empty or the
  named entity is not in it (Phase 1), or no GDDs were in scope (Phase 2). Say
  which.
- **PASS** — no conflicts. Registry and GDDs agree on all checked values, across at least one GDD.
**判定：**
- **CONFLICTS FOUND** — 检测到一个或多个冲突。列出解决步骤。
- **NOT ASSESSED** — 没有做任何比较：实体注册表为空，或所命名的实体不在其中（阶段 1），或范围内没有 GDD（阶段 2）。说明是哪一种。
- **PASS** — 无冲突。注册表与 GDD 在所有已检查的值上一致，且至少覆盖一份 GDD。

---

## Phase 6: Registry Corrections
## 阶段 6：注册表修正

**Re-read before you write.** Phase 1 read the registry before the scans, and
another skill or session may have changed it since. Before each Edit, read the
current `design/registry/entities.yaml`, find the entry in its section, and
anchor the Edit on the entry's current text, never on what Phase 1 saw. Append
a new entry after the last existing entry of its section.
**写前重读。** 阶段 1 在扫描之前读取了注册表，而自那以后另一个技能或会话可能已更改它。在每次编辑之前，读取当前的 `design/registry/entities.yaml`，在其章节中找到该条目，并将编辑锚定在条目的当前文本上，绝不要锚定在阶段 1 所看到的内容上。在其章节的最后一个现有条目之后追加新条目。

If stale registry entries were found, ask:
> "May I update `design/registry/entities.yaml` to fix the [N] stale entries?"
如果发现了过时的注册表条目，询问：
> “我可以更新 `design/registry/entities.yaml` 以修复这 [N] 个过时条目吗？”

For each stale entry:
- Update the `value` / attribute field
- Set `revised:` to today's date
- Add a YAML comment with the old value: `# was: [old_value] before [date]`
对每个过时条目：
- 更新 `value` / 属性字段
- 将 `revised:` 设为今天的日期
- 添加一条带旧值的 YAML 注释：`# was: [old_value] before [date]`

If new entries were found in GDDs that are not in the registry, ask:
> "Found [N] entities/items mentioned in GDDs that aren't in the registry yet.
> May I add them to `design/registry/entities.yaml`?"
如果在 GDD 中发现了不在注册表中的新条目，询问：
> “发现 GDD 中提到了 [N] 个尚未在注册表中的实体/物品。我可以将它们添加到 `design/registry/entities.yaml` 吗？”

Only add entries that appear in more than one GDD (true cross-system facts).
只添加出现在不止一份 GDD 中的条目（真正的跨系统事实）。

**Never delete registry entries.** Set `status: deprecated` if an entry is removed
from all GDDs.
**绝不删除注册表条目。** 如果某条目从所有 GDD 中移除，设置 `status: deprecated`。

After writing, run `bash .claude/scripts/registry.sh validate` and fix every row
about an entry this write added or changed (a DUPLICATE, STATUS or LAYOUT row,
or a PATH_MISSING row for a path it named) before the verdict; name rows about
other entries to the user rather than fixing them unasked. If the script is
missing or prints nothing, say the registry check did not run, then re-read the
entries you wrote against the rules in the file's header.
写入后，运行 `bash .claude/scripts/registry.sh validate`，并在给出判定前修复关于本次写入所添加或更改条目的每一行（DUPLICATE、STATUS 或 LAYOUT 行，或针对其命名路径的 PATH_MISSING 行）；对于涉及其他条目的行，向用户点名，而不是未经询问就修复。如果脚本缺失或没有输出，说明注册表检查未运行，然后对照文件头部的规则重新读取你所写入的条目。

After writing: Verdict: **COMPLETE** — consistency check finished.
If conflicts remain unresolved: Verdict: **BLOCKED** — [N] conflicts need manual resolution before architecture begins.
写入后：判定：**COMPLETE**——一致性检查完成。
如果冲突仍未解决：判定：**BLOCKED**——[N] 个冲突需要在架构开始前手动解决。

### 6b: Append to Reflexion Log
### 6b：追加到反思日志

If any 🔴 CONFLICT entries were found (regardless of whether they were resolved),
ask: "May I append [N] entries to `docs/consistency-failures.md` (creating it if
absent)?" On yes, append an entry for each conflict; on no, say the conflicts
were not logged.
如果发现了任何 🔴 CONFLICT 条目（无论是否已解决），询问：“我可以将 [N] 条记录追加到 `docs/consistency-failures.md`（若不存在则创建）吗？”若同意，为每个冲突追加一条记录；若不同意，说明这些冲突未被记录。

```markdown
### [YYYY-MM-DD] — /consistency-check — 🔴 CONFLICT
**Domain**: [system domain(s) involved]
**Documents involved**: [source GDD] vs [conflicting GDD]
**What happened**: [specific conflict — entity name, attribute, differing values]
**Resolution**: [how it was fixed, or "Unresolved — manual action needed"]
**Pattern**: [generalised lesson, e.g. "Item values defined in combat GDD were not
referenced in economy GDD before authoring — always check entities.yaml first"]
```

If `docs/consistency-failures.md` does not exist, create it with this header before appending:
如果 `docs/consistency-failures.md` 不存在，在追加前用以下头部创建它：

```markdown
# Consistency Failure Log

<!-- Auto-maintained by /consistency-check. Do not edit manually. -->
<!-- One entry per detected conflict, in chronological order. -->

| Date | GDD A | GDD B | Conflict Type | Status |
|------|-------|-------|---------------|--------|
```

Then append the new conflict entries. Never skip logging on your own — a missing file is not a reason to lose conflict history; only the user's "no" is.
然后追加新的冲突条目。绝不要自行跳过记录——文件缺失不是丢失冲突历史的理由；唯有用户的“不”才是。

---

## Phase 7: Session State and Closing
## 阶段 7：会话状态与收尾

Silently append to `production/session-state/active.md` (create the file if it does not exist):
静默追加到 `production/session-state/active.md`（若文件不存在则创建）：

```
<!-- CONSISTENCY-CHECK: [date] | GDDs checked: [N] | Conflicts found: [N] | Log: docs/consistency-failures.md -->
```

> **Point at `docs/consistency-failures.md` — the file Phase 6 actually appends
> to.** A breadcrumb is a pointer left for a future session to follow. One that
> names a file nothing writes sends that session looking for conflict history it
> will never find, and nothing errors along the way. Never invent a report
> filename here.
> **指向 `docs/consistency-failures.md`——阶段 6 实际追加的那个文件。** 面包屑是留给未来会话去跟随的指针。一个点名的文件若无人写入，就会让那个会话去寻找它永远找不到的冲突历史，而一路上不会有任何报错。绝不要在此处杜撰报告文件名。

Then close with an `AskUserQuestion` widget:
然后用 `AskUserQuestion` 组件收尾：

- **Prompt**: "Consistency check complete — [N] conflicts found. What next?"
- **Options**:
  - `[A] Fix the highest-priority conflict now`
  - `[B] Run /design-review on the most conflicted GDD`
  - `[C] Stop here`
- **提示**：“一致性检查完成——发现 [N] 个冲突。接下来做什么？”
- **选项**：
  - `[A] 立即修复优先级最高的冲突`
  - `[B] 对冲突最多的 GDD 运行 /design-review`
  - `[C] 就此停止`

In collaborative and guided modes, never end the skill with plain text — always
close with this widget. In autonomous mode, print the findings and recommended
next step, then record via `log_decision` (no widget).
在 collaborative 和 guided 模式下，绝不要以纯文本结束本技能——始终用该组件收尾。在 autonomous 模式下，打印发现与建议的下一步，然后通过 `log_decision` 记录（不用组件）。

---

## Recovery / Reference
## 恢复 / 参考

- **If PASS**: Run `/review-all-gdds` for holistic design-theory review, or
  `/create-architecture` if all MVP GDDs are complete.
- **If CONFLICTS FOUND**: Fix the flagged GDDs, then re-run
  `/consistency-check` to confirm resolution.
- **If STALE REGISTRY**: Update the registry (Phase 6), then re-run to verify.
- Run `/consistency-check` after writing each new GDD to catch issues early,
  not at architecture time.
- **若为 PASS**：运行 `/review-all-gdds` 进行整体设计理论评审，或如果所有 MVP GDD 都已完成，则运行 `/create-architecture`。
- **若为 CONFLICTS FOUND**：修复被标记的 GDD，然后重新运行 `/consistency-check` 以确认解决。
- **若为 STALE REGISTRY**：更新注册表（阶段 6），然后重新运行以验证。
- 在编写每个新 GDD 之后运行 `/consistency-check`，以便尽早发现问题，而不是到架构阶段才发现。
