---
name: asset-audit
description: "Audit assets against naming conventions, file size budgets, format standards. Finds orphaned assets, missing references."
argument-hint: "[category|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(stat *), Bash(file *), Bash(od *), Bash(wc *), Bash(du *)
model: sonnet
# Read-only diagnostic skill — no specialist agent delegation needed
---
---
name: asset-audit
description: "按命名约定、文件大小预算、格式标准审计资产。查找孤立资产、缺失引用。"
argument-hint: "[category|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(stat *), Bash(file *), Bash(od *), Bash(wc *), Bash(du *)
model: sonnet
# Read-only diagnostic skill — no specialist agent delegation needed
---

# Asset Audit
# 资产审计

## Measuring file sizes and formats requires Bash
## 测量文件大小和格式需要 Bash

This skill's report asks for **file sizes against budgets**, **texture dimensions**
(power-of-two), **audio sample rates**, and **last-modified times** for orphan
detection. None of those are obtainable from `Read`/`Glob`/`Grep` — they need
`stat` or a binary header read, so the read-only measuring commands (`stat`,
`file`, `od`, `wc`, `du`) are pre-approved above; list files with Glob. Anything
else asks first.
本技能的报告要求提供**对照预算的文件大小**、**纹理尺寸**（2 的幂次方）、**音频采样率**，以及用于孤立资产检测的**最后修改时间**。这些都无法通过 `Read`/`Glob`/`Grep` 获取——它们需要 `stat` 或读取二进制头部，因此只读的测量命令（`stat`、`file`、`od`、`wc`、`du`）已在上方预批准；用 Glob 列出文件。其他任何操作都先询问。

**If you cannot take a measurement, the cell is `NOT ASSESSED`, never an
estimate.** A size budget table filled from guesses is worse than an empty one:
it looks like evidence. This is a live fabrication vector even on a project full
of real assets: if the template demands tables of numbers the tool allowlist
cannot produce, the only way to complete it is to invent them.
**如果你无法进行测量，该单元格就是 `NOT ASSESSED`，绝不能是估算值。** 用猜测填满的大小预算表比空表更糟：它看起来像证据。即便在一个满是真实资产的项目上，这也是一条正在活跃的编造路径：如果模板要求填写工具白名单无法产出的数字表格，唯一能完成它的方式就是凭空捏造。

---

## Insufficient input — check this before producing any report
## 输入不足——在产出任何报告前先检查

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.
**如果本技能所需的输入不存在，答案就是"无法运行"——而不是一份填好的报告。** 先检查，如果检查失败就停止。

1. List the inputs this skill reads (data files, prior reports, profiler output,
   test results, registries, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.
1. 列出本技能读取的输入（数据文件、先前报告、分析器输出、测试结果、注册表、源代码）。
2. 对每一项记录 `FOUND` 或 `ABSENT`——而不是"假定存在"。
3. 如果某个小节所需的任何输入为 ABSENT，该小节即为
   **`NOT ASSESSED — NO DATA`**。不要估算它，不要从相邻产物推断它，也不要留下一个被强制要求的单元格让下一个读模板的人来填。
4. 如果**每项**必需输入都是 ABSENT，停止并以
   **`NOT ASSESSED — NO DATA`** 作为整体判定上报，说明缺失了什么以及由哪个技能产出。

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — an asset audit returning COMPLIANT on a project with no
assets and no standards, or a performance profile reporting ">99% headroom against
a 16.67ms budget" with zero profiler data and no budget ever set.
**`NOT ASSESSED` 的判定是一种成功。** 在没有数据时，它是对"数据说明了什么？"这一问题的正确、有用的回答。它所防止的失败模式很具体：判定枚举中没有"无法运行"状态的报告会产生**虚假的干净通过**——在没有资产也没有标准的项目上返回 COMPLIANT 的资产审计，或在没有任何分析器数据、也从未设定预算的情况下报告"相对 16.67ms 预算有 >99% 余量"的性能剖析。

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.
**证据的缺失永远不是缺失的证据。** 因为无文件可扫描而找不到匹配的扫描没有验证任何东西。说明两者中究竟是哪一种——读者无法从一个绿色的结果中分辨出来。

---

## Phase 1: Read Standards
## 阶段 1：读取标准

Read the art bible's Asset Standards section (`design/art/art-bible.md`) and any
asset standards in the relevant design docs — size budgets and format rules come
from there. The naming patterns are the ones in Phase 3 below, unless the art
bible states its own. Read the art bible by section: find the heading with
the Grep tool (pattern `^#`, content mode) and Read that range with offset
and limit.
读取美术圣经的资产标准部分（`design/art/art-bible.md`）以及相关设计文档中的所有资产标准——大小预算和格式规则来自那里。命名模式采用下方阶段 3 中的那些，除非美术圣经声明了自己的命名模式。按小节读取美术圣经：用 Grep 工具（模式 `^#`，内容模式）找到标题，再用 offset 和 limit 读取该范围。

If neither states a size budget — or there is no art bible — the Size section is
`NOT ASSESSED — no size budget set`, and the report names `/art-bible`, whose
Asset Standards section sets budgets, formats and the naming convention.
如果两者都没有声明大小预算——或者根本没有美术圣经——则大小小节为
`NOT ASSESSED — no size budget set`，并且报告点名 `/art-bible`，其资产标准部分负责设定预算、格式和命名约定。

---

## Phase 2: Scan Asset Directories
## 阶段 2：扫描资产目录

Assets live under the engine's asset root: `assets/` on Godot, `Assets/` on
Unity, `Content/` on Unreal. Resolve the engine and its code root per
`.claude/docs/code-root-resolution.md`; that code root is the one Phase 3's
orphan and missing-asset searches read. If it is unresolved, stop:
`NOT ASSESSED — engine unresolved`, naming `/setup-engine`.
资产位于引擎的资产根目录下：Godot 为 `assets/`，Unity 为 `Assets/`，Unreal 为 `Content/`。按
`.claude/docs/code-root-resolution.md` 解析引擎及其代码根目录；该代码根目录正是阶段 3 中孤立资产和缺失资产搜索所读取的对象。如果无法解析，则停止：
`NOT ASSESSED — engine unresolved`，并点名 `/setup-engine`。

Scan the asset root using Glob:
使用 Glob 扫描资产根目录：

- **Godot** — `assets/art/**/*`, `assets/audio/**/*`, `assets/vfx/**/*`,
  `assets/shaders/**/*`, `assets/data/**/*`
- **Unity** — `Assets/**/*`, leaving out scripts (`*.cs`, `*.asmdef`) and `*.meta` files
- **Unreal** — `Content/**/*.uasset` and `Content/**/*.umap`
- **Godot** — `assets/art/**/*`、`assets/audio/**/*`、`assets/vfx/**/*`、
  `assets/shaders/**/*`、`assets/data/**/*`
- **Unity** — `Assets/**/*`，排除脚本（`*.cs`、`*.asmdef`）和 `*.meta` 文件
- **Unreal** — `Content/**/*.uasset` 和 `Content/**/*.umap`

The files matched are `Total assets scanned`. If there are none, the checks on
scanned files — Naming, Size, Format, Orphaned — are
`NOT ASSESSED — no assets under <asset root>`; the missing-asset search still runs.
匹配到的文件数即 `Total assets scanned`。如果没有任何文件，则针对已扫描文件的检查——命名、大小、格式、孤立——为
`NOT ASSESSED — no assets under <asset root>`；缺失资产搜索仍会运行。

---

## Phase 3: Run Compliance Checks
## 阶段 3：运行合规性检查

**Naming conventions:**
- Art: `[category]_[name]_[variant]_[size].[ext]`
- Audio: `[category]_[context]_[name]_[variant].[ext]`
- All files must be lowercase with underscores
**命名约定：**
- 美术：`[category]_[name]_[variant]_[size].[ext]`
- 音频：`[category]_[context]_[name]_[variant].[ext]`
- 所有文件必须小写并使用下划线

These are Godot's conventions. Unity and Unreal name assets in PascalCase, so on
those engines check names only against a naming rule the art bible states; with
none, Naming is `NOT ASSESSED — no naming rule for <engine>` (name `/art-bible`).
这些是 Godot 的约定。Unity 和 Unreal 以 PascalCase 命名资产，因此在那些引擎上只依据美术圣经声明的命名规则检查名称；若没有，则命名为
`NOT ASSESSED — no naming rule for <engine>`（点名 `/art-bible`）。

**File standards:**
- Textures: Power-of-two dimensions, correct format (PNG for UI, compressed for 3D), within size budget
- Audio: Correct sample rate, format (OGG for SFX, OGG/MP3 for music), within duration limits.
  `file` reports an audio file's format and sample rate but not its length, and no
  pre-approved tool here does; a duration budget is therefore
  `NOT ASSESSED — duration not measurable here`, naming the files it covers.
- Data: Valid JSON/YAML, schema-compliant
**文件标准：**
- 纹理：2 的幂次方尺寸，正确格式（UI 用 PNG，3D 用压缩格式），在大小预算内
- 音频：正确采样率，格式（SFX 用 OGG，音乐用 OGG/MP3），在时长限制内。
  `file` 会报告音频文件的格式和采样率，但不报告其长度，此处也没有预批准的工具能做到；因此时长预算为
  `NOT ASSESSED — duration not measurable here`，并点名其覆盖的文件。
- 数据：有效的 JSON/YAML，符合 schema

On Unreal an asset file (`.uasset`, `.umap`) does not keep its source file's
format or dimensions, so Format is `NOT ASSESSED` there; its size is still measured.
在 Unreal 上，资产文件（`.uasset`、`.umap`）不保留其源文件的格式或尺寸，因此那里的格式为 `NOT ASSESSED`；其大小仍会被测量。

**Orphaned assets:** Search the code root for references to each asset file. Flag any with no references.
**孤立资产：** 在代码根目录中搜索对每个资产文件的引用。标记任何没有引用的文件。

**Missing assets:** Search the code root for asset references and verify the files exist.
**缺失资产：** 在代码根目录中搜索资产引用并验证这些文件是否存在。

Both searches need code: if the code root holds no source files, Orphaned and
Missing are `NOT ASSESSED — no code to search`. On Unity and Unreal most asset
references live in scenes, prefabs and other assets rather than code, so an
asset no code names may still be in use: Orphaned is `NOT ASSESSED` there.
这两项搜索都需要代码：如果代码根目录中没有源文件，则孤立和缺失为
`NOT ASSESSED — no code to search`。在 Unity 和 Unreal 上，大多数资产引用存在于场景、预制体和其他资产中而非代码里，因此没有代码命名的资产可能仍在使用：那里的孤立为 `NOT ASSESSED`。

---

## Phase 4: Output Audit Report
## 阶段 4：输出审计报告

```markdown
# Asset Audit Report -- [Category] -- [Date]

## Summary
- **Total assets scanned**: [N]
- **Naming violations**: [N]
- **Size violations**: [N]
- **Format violations**: [N]
- **Orphaned assets**: [N]
- **Missing assets**: [N]
- **Sections not assessed**: [none | each section and why]

## Naming Violations
| File | Expected Pattern | Issue |
|------|-----------------|-------|

## Size Violations
| File | Budget | Actual | Overage |
|------|--------|--------|---------|

## Format Violations
| File | Expected Format | Actual Format |
|------|----------------|---------------|

## Orphaned Assets (no code references found)
| File | Last Modified | Size | Recommendation |
|------|-------------|------|---------------|

## Missing Assets (referenced but not found)
| Reference Location | Expected Path |
|-------------------|---------------|

## Recommendations
[Prioritized list of fixes, one per violation, each naming the change — the
target resolution or compression for a size violation, the corrected name for a
naming violation, the target format for a format violation]

## Verdict: [NOT ASSESSED / COMPLIANT / WARNINGS / NON-COMPLIANT]
```

Choose the verdict by the findings, first match wins:
- **NON-COMPLIANT** — any size violation, or any asset that code references but that does not exist
- **WARNINGS** — only naming, format or orphaned-asset findings
- **NOT ASSESSED** — the audit did not cover its scope: no data at all (the path
  above), zero assets scanned, or any section `NOT ASSESSED` — name which. It
  ranks below the two finding verdicts, because a measured violation is more
  actionable than a gap, and above COMPLIANT
- **COMPLIANT** — at least one asset scanned, every section assessed, no findings
根据发现来选择判定，第一个匹配者胜出：
- **NON-COMPLIANT** — 任何大小违规，或任何被代码引用但不存在的资产
- **WARNINGS** — 仅有命名、格式或孤立资产的发现
- **NOT ASSESSED** — 审计未覆盖其范围：完全无数据（上述情形）、零资产被扫描，或任何小节为 `NOT ASSESSED`——点名是哪一项。它的优先级低于两个"有发现"的判定，因为一个已测量的违规比一处空白更可操作，但高于 COMPLIANT
- **COMPLIANT** — 至少扫描了一个资产，每个小节都已评估，且没有发现

This skill is read-only — it produces a report but does not write files.
此技能是只读的——它产出报告但不写入文件。

---

## Phase 5: Next Steps
## 阶段 5：后续步骤

- Fix naming violations using the Phase 3 patterns (or the art bible's, where it states its own).
- If standards were missing, run `/art-bible` to write its Asset Standards section.
- Delete confirmed orphaned assets after manual review.
- Run `/content-audit` to cross-check asset counts against GDD-specified requirements.
- 使用阶段 3 的模式（或美术圣经声明了自己的模式之处）修复命名违规。
- 如果缺少标准，运行 `/art-bible` 写入其资产标准部分。
- 手动审查后删除已确认的孤立资产。
- 运行 `/content-audit` 将资产计数与 GDD 指定的需求交叉核对。
