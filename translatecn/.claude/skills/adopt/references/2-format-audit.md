# /adopt — Phase 2: Format Audit

# /adopt — 阶段 2：格式审计

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/adopt` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## Phase 2: Format Audit

## 阶段 2：格式审计

**In this file:**

**本文件内容：**

- 2a: GDD Format Audit
- 2b: ADR Format Audit
- 2c: systems-index.md Format Audit
- 2d: Story Format Audit
- 2e: Infrastructure Audit
- 2f: Project Config Audit
- 2g: v1.0 Migration Check

- 2a：GDD 格式审计
- 2b：ADR 格式审计
- 2c：systems-index.md 格式审计
- 2d：故事格式审计
- 2e：基础设施审计
- 2f：项目配置审计
- 2g：v1.0 迁移检查

For each artifact type in scope (based on argument mode **and the resolved
workflow tier**), check not just that the file exists but that it contains the
internal structure the template requires. At `minimal`, scope the audit to
`design/game-brief.md` — do not audit for GDDs, ADRs, or UX specs (they are not expected).
Steps 2e (the Engine reference row only), 2f (project config) and 2g (v1.0
migration check) run at every tier.

对于范围内的每一种产物类型（依据参数模式**以及已解析的工作流层级**），不仅检查文件是否存在，还要检查它是否包含模板所要求的内部结构。在 `minimal` 层级下，将审计范围限定为 `design/game-brief.md` —— 不审计 GDD、ADR 或 UX 规格（它们不在预期之内）。步骤 2e（仅 Engine reference 那一行）、2f（项目配置）和 2g（v1.0 迁移检查）在每个层级都会运行。

### 2a: GDD Format Audit

### 2a：GDD 格式审计

**Gather section presence deterministically — do not read the GDDs to count
headings.** For each GDD discovered in Phase 1, pass its path explicitly to the
structure-check script:

**以确定的方式收集各节是否存在 —— 不要通过阅读 GDD 来统计标题。** 对于阶段 1 中发现的每个 GDD，将其路径显式传给结构检查脚本：

```
Bash: bash .claude/scripts/gdd-structure-check.sh [path-to-gdd]
```

**Pass paths one at a time; do not invoke it bare.** The no-argument form sweeps
`design/gdd/` only, and a brownfield project's GDDs are not guaranteed to live
there — pass whatever paths Phase 1 found. The script prints a `PRESENT:` list
and, when applicable, an `ABSENT:` list per file. It reports **presence only**
and makes no REQUIRED/ADVISORY judgment (that is the tier logic below), and it
already accepts `## Detailed Design` as satisfying the `Detailed Rules`
requirement, so do not flag that alias as missing.

**一次传入一个路径；不要不带参数地调用它。** 无参数形式只扫描 `design/gdd/`，而棕地项目的 GDD 并不保证存放在那里 —— 传入阶段 1 找到的所有路径。脚本会打印一个 `PRESENT:` 列表，并在适用时打印每个文件的 `ABSENT:` 列表。它只报告**是否存在**，不做 REQUIRED/ADVISORY 判断（那是下面的层级逻辑），而且它已经接受 `## Detailed Design` 作为满足 `Detailed Rules` 要求，因此不要将该别名标记为缺失。

If the script prints `Not found:` for a path or errors, that is a **discovery
failure, not a format gap** — report it as "could not audit [path]" and do not
count it as a missing-sections finding.

如果脚本对某个路径打印 `Not found:` 或报错，那是**发现失败，而不是格式缺口** —— 将其报告为 "无法审计 [path]"，并且不要把它计入缺失章节的发现。

**Then apply the workflow tier** resolved above to each file's PRESENT/ABSENT
lists. Which sections are **required** (a miss = gap) vs **advisory** (a miss =
informational):

**然后将上面解析出的工作流层级**应用到每个文件的 PRESENT/ABSENT 列表。哪些章节是**必需**的（缺失 = 缺口），哪些是**建议**的（缺失 = 仅供参考）：

- **`full`** — all 8 sections are required.

- **`standard`** — the 5 required (Overview, Detailed Rules, Edge Cases,
  Dependencies, Acceptance Criteria) + Formulas for any system that defines
  numeric rules (rates, curves, thresholds, costs — the system's `Category` is a
  hint, not the test); Player Fantasy and Tuning Knobs are advisory.

- **`minimal`** — GDDs are not expected; audit `design/game-brief.md` instead,
  against `.claude/docs/templates/game-brief.md`: each of the six required fields
  present and not a placeholder; the three one-liners advisory. Any GDD that
  does exist is checked at the `standard` bar, advisorily.

- **`full`** —— 全部 8 个章节都是必需的。

- **`standard`** —— 5 个必需章节（Overview、Detailed Rules、Edge Cases、Dependencies、Acceptance Criteria），加上任何定义数值规则的系统（速率、曲线、阈值、成本 —— 该系统的 `Category` 只是提示，不是判定依据）所需的 Formulas；Player Fantasy 和 Tuning Knobs 为建议章节。

- **`minimal`** —— 不期望有 GDD；改为依据 `.claude/docs/templates/game-brief.md` 审计 `design/game-brief.md`：六个必需字段均应存在且不是占位符；三个一句话字段为建议章节。任何确实存在的 GDD 都按 `standard` 标准以建议方式检查。

The script's 8 canonical labels are: Overview, Player Fantasy, Detailed Rules,
Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria.

脚本的 8 个规范标签是：Overview、Player Fantasy、Detailed Rules、Formulas、Edge Cases、Dependencies、Tuning Knobs、Acceptance Criteria。

A section reported PRESENT can still be an empty heading. For each GDD, also
record with a targeted grep (not a full read):

某章节被报告为 PRESENT 时仍可能只是空标题。对于每个 GDD，还要用有针对性的 grep（而非完整读取）记录：

- Placeholder-only sections — the script's `PLACEHOLDER:` line names the
  present sections that hold only `[To be designed]` or nothing; a
  single-line stub body is the same in effect, so spot-check short sections.

- The `**Status**:` header field — `Grep pattern="^>?[[:space:]]*\*\*Status\*\*:"`.
  Valid values: `Draft`, `In Design`, `Designed`, `In Review`, `Approved`,
  `Implemented`, `Needs Revision`.

- 仅有占位符的章节 —— 脚本的 `PLACEHOLDER:` 行会列出仅包含 `[To be designed]` 或什么都没有的现存章节；单行的存根正文在效果上相同，因此请抽查较短的章节。

- `**Status**:` 头部字段 —— `Grep pattern="^>?[[:space:]]*\*\*Status\*\*:"`。有效值：`Draft`、`In Design`、`Designed`、`In Review`、`Approved`、`Implemented`、`Needs Revision`。

> **The `>?` is load-bearing, and so are `Draft`/`Implemented`.** Both emitters
> write this field inside a blockquote — `.claude/docs/templates/game-design-document.md`
> and `/design-system` produce `> **Status**: …` — so an anchor of
> `^\*\*Status\*\*:` matches nothing and reports *every* template-compliant GDD
> as missing its Status. The template's own value list offers `Draft` and
> `Implemented`, so both must count as valid.

> **`>?` 是关键的，`Draft`/`Implemented` 同样如此。** 两个写入方都把该字段写在引用块内 —— `.claude/docs/templates/game-design-document.md` 和 `/design-system` 都会生成 `> **Status**: …` —— 因此以 `^\*\*Status\*\*:` 为锚点什么都匹配不到，并且会把*每一个*符合模板的 GDD 都报告为缺少 Status。模板自身的取值列表提供了 `Draft` 和 `Implemented`，所以两者都必须算作有效。

### 2b: ADR Format Audit

### 2b：ADR 格式审计

For each ADR file found, check for these critical sections:

对于找到的每个 ADR 文件，检查以下关键章节：

| Section / 章节 | Impact if missing / 缺失时的影响 |
|---|---|
| `## Status` | **BLOCKING** — `/story-readiness` ADR status check silently passes everything<br>**阻断** —— `/story-readiness` 的 ADR 状态检查会对所有内容静默通过 |
| `## ADR Dependencies` | HIGH — dependency ordering in `/architecture-review` breaks<br>高 —— `/architecture-review` 中的依赖排序会失效 |
| `## Engine Compatibility` | HIGH — post-cutoff API risk is unknown<br>高 —— 截止点之后的 API 风险未知 |
| `## GDD Requirements Addressed` | MEDIUM — traceability matrix loses coverage<br>中 —— 追溯矩阵失去覆盖 |
| `## Performance Implications` | LOW — not pipeline-critical<br>低 —— 对流水线不关键 |

For each ADR, record: which sections present, which missing, current Status value
if the Status section exists.

对于每个 ADR，记录：哪些章节存在、哪些缺失，以及 Status 章节存在时的当前 Status 值。

### 2c: systems-index.md Format Audit

### 2c：systems-index.md 格式审计

If `design/gdd/systems-index.md` exists:

如果 `design/gdd/systems-index.md` 存在：

1. **Parenthetical status values** — Grep for any Status cell containing
   parentheses: `"Needs Revision ("`, `"In Progress ("`, etc.
   These break exact-string matching in `/gate-check`, `/create-stories`,
   and `/architecture-review`. **BLOCKING.**

2. **Valid status values** — check that Status column values are only from:
   `Not Started`, `In Progress`, `In Review`, `Designed`, `Approved`, `Needs Revision`
   Flag any unrecognised values.

3. **Column structure** — check that the table has at minimum: System name,
   Layer, Priority, Status columns. Missing columns degrade skill functionality.

1. **带括号的状态值** —— Grep 查找任何包含括号的 Status 单元格：`"Needs Revision ("`、`"In Progress ("` 等。这些会破坏 `/gate-check`、`/create-stories` 和 `/architecture-review` 中的精确字符串匹配。**阻断。**

2. **有效的状态值** —— 检查 Status 列的值仅来自：`Not Started`、`In Progress`、`In Review`、`Designed`、`Approved`、`Needs Revision`。标记任何无法识别的值。

3. **列结构** —— 检查表格至少包含：System name、Layer、Priority、Status 列。缺少列会降低技能功能。

### 2d: Story Format Audit

### 2d：故事格式审计

For each story file found:

对于找到的每个故事文件：

- **`Manifest Version:` field** — present in story header? (LOW — auto-passes if absent)
- **TR-ID reference** — does story contain `TR-[a-z]+-[0-9]+` pattern? (MEDIUM — no staleness tracking)
- **ADR reference** — does story reference at least one ADR? (check for `ADR-` pattern)
- **Status field** — present and readable?
- **Acceptance criteria** — does the story have a checkbox list (`- [ ]`)?

- **`Manifest Version:` 字段** —— 是否出现在故事头部？（低 —— 缺失时自动通过）
- **TR-ID 引用** —— 故事是否包含 `TR-[a-z]+-[0-9]+` 模式？（中 —— 没有陈旧度跟踪）
- **ADR 引用** —— 故事是否引用了至少一个 ADR？（检查 `ADR-` 模式）
- **Status 字段** —— 是否存在且可读？
- **验收标准** —— 故事是否有复选框列表（`- [ ]`）？

### 2e: Infrastructure Audit

### 2e：基础设施审计

| Artifact / 产物 | Path / 路径 | Impact if missing / 缺失时的影响 |
|---|---|---|
| TR registry / TR 注册表 | `docs/architecture/tr-registry.yaml` | HIGH — no stable requirement IDs<br>高 —— 没有稳定的需求 ID |
| Control manifest / 控制清单 | `docs/architecture/control-manifest.md` | HIGH — no layer rules for stories<br>高 —— 故事没有层级规则 |
| Manifest version stamp / 清单版本戳 | In manifest header: `Manifest Version:`<br>在清单头部：`Manifest Version:` | MEDIUM — staleness checks blind<br>中 —— 陈旧度检查失明 |
| Sprint status / 冲刺状态 | `production/sprint-status.yaml` | MEDIUM — `/sprint-status` falls back to markdown<br>中 —— `/sprint-status` 回退到 markdown |
| Stage file / 阶段文件 | `project.stage` in `project.yaml` (fallback `production/stage.txt`)<br>`project.yaml` 中的 `project.stage`（回退到 `production/stage.txt`） | MEDIUM — phase auto-detect unreliable<br>中 —— 阶段自动检测不可靠 |
| Engine reference / 引擎参考 | `docs/engine-reference/[engine]/VERSION.md` | HIGH — ADR engine checks blind<br>高 —— ADR 引擎检查失明 |
| Architecture traceability / 架构追溯 | `docs/architecture/requirements-traceability.md` | MEDIUM — no persistent matrix<br>中 —— 没有持久化矩阵 |

At `workflow: minimal` only the Engine reference row applies. The TR registry,
control manifest and its version stamp, sprint status, stage file and
traceability matrix are not on the minimal path, so their absence is not a gap.

在 `workflow: minimal` 下，只有 Engine reference 那一行适用。TR 注册表、控制清单及其版本戳、冲刺状态、阶段文件和追溯矩阵都不在 minimal 路径上，因此它们的缺失不算缺口。

### 2f: Project Config Audit

### 2f：项目配置审计

Read `project.yaml` (the primary config store) and `.claude/docs/technical-preferences.md` (legacy mirror). A setting counts as configured if EITHER source has a real value (in technical-preferences.md, `[TO BE CONFIGURED]` means unconfigured):
- `engine.name`/`version`/`language`/`rendering`/`physics` (else the Engine/Language/Rendering/Physics fields) → HIGH if unconfigured in both (ADR skills fail)
- `naming.*` (else Naming conventions) → MEDIUM
- `performance.*` (else Performance budgets) → MEDIUM
- Forbidden Patterns, Allowed Libraries (technical-preferences.md only — not migrated to project.yaml) → LOW (starts empty by design)

读取 `project.yaml`（主要配置存储）和 `.claude/docs/technical-preferences.md`（旧版镜像）。只要任一来源有真实值，该设置就计为已配置（在 technical-preferences.md 中，`[TO BE CONFIGURED]` 表示未配置）：
- `engine.name`/`version`/`language`/`rendering`/`physics`（否则为 Engine/Language/Rendering/Physics 字段）→ 若两者都未配置则为高（ADR 技能会失败）
- `naming.*`（否则为 Naming conventions）→ 中
- `performance.*`（否则为 Performance budgets）→ 中
- Forbidden Patterns、Allowed Libraries（仅 technical-preferences.md —— 未迁移到 project.yaml）→ 低（按设计初始为空）

### 2g: v1.0 Migration Check

### 2g：v1.0 迁移检查

A project is a **v1.0 project needing migration** when `project.yaml` does NOT
exist at the repo root AND at least one legacy file does: `production/stage.txt`,
`production/review-mode.txt`, or a `.claude/docs/technical-preferences.md` with
real values.

当仓库根目录**不存在** `project.yaml`，且至少存在一个旧版文件时，该项目就是一个**需要迁移的 v1.0 项目**：`production/stage.txt`、`production/review-mode.txt`，或带有真实值的 `.claude/docs/technical-preferences.md`。

"Real values" means one of the keys the converter actually migrates — Engine,
Language, Rendering, Physics, the naming, platform and performance fields,
Framework, or the specialists. Not merely "some bullet is filled in": the
shipped template ships one prose default (`- **Required Tests**: …`) that is
never migrated, and counting it would make every fresh clone read as a v1.0
project.

"真实值"指的是转换器实际会迁移的键之一 —— Engine、Language、Rendering、Physics、命名/平台/性能字段、Framework 或专家。这不仅仅是"填了某个条目"：随附的模板自带一个从不迁移的散文式默认值（`- **Required Tests**: …`），若把它计入，每个全新克隆都会被读作 v1.0 项目。

Do not hand-migrate. Run the converter, which is deterministic and covered by
the framework's own test suite:

不要手动迁移。运行转换器，它是确定性的，并且由框架自身的测试套件覆盖：

```bash
bash .claude/scripts/migrate-v1-config.sh --dry-run
```

The dry run writes nothing; record what it lists for the report. Do not run the
converter during the audit — Phase 2 reads silently. The migration is
classified BLOCKING in Phase 3, heads the plan, and **Phase 7 offers it as the
first action**: report what the dry run listed, then ask "May I run the
converter? It writes `project.yaml` and `production/migration-report.md`." If
the user approves, run it without `--dry-run`. It
writes `project.yaml` plus `production/migration-report.md` and **deletes
nothing** — the whole operation stays reversible with `git checkout`.

试运行不写入任何内容；记录它列出的内容以供报告。不要在审计期间运行转换器 —— 阶段 2 是静默读取。该迁移在阶段 3 被归类为阻断，位于规划之首，并且**阶段 7 会将其作为首要操作提供**：报告试运行列出的内容，然后询问"我可以运行转换器吗？它会写入 `project.yaml` 和 `production/migration-report.md`。"如果用户批准，则不带 `--dry-run` 运行它。它会写入 `project.yaml` 以及 `production/migration-report.md`，并且**不删除任何内容** —— 整个操作通过 `git checkout` 保持可逆。

Then tell the user to read `production/migration-report.md` before running:

然后告诉用户在运行以下命令之前阅读 `production/migration-report.md`：

```bash
bash .claude/scripts/migrate-v1-config.sh --finalize
```

`--finalize` deletes a legacy file only after proving its value is present in
`project.yaml`; on mismatch it deletes nothing and exits 4. It never deletes
`technical-preferences.md`, which still holds Forbidden Patterns and Allowed
Libraries.

`--finalize` 只有在证明其值已存在于 `project.yaml` 中之后，才会删除旧版文件；不匹配时它不删除任何内容并以 4 退出。它从不删除 `technical-preferences.md`，该文件仍保留 Forbidden Patterns 和 Allowed Libraries。

**If the script refuses with exit 3**, do not work around it. Exit 3 means one
of two things, and the message says which:

**如果脚本以退出码 3 拒绝执行**，不要绕过它。退出码 3 意味着两种情况之一，消息会说明是哪一种：

- **the values DISAGREE** — two sources of truth and no way to know which the
  user edited last. Surface it and let them decide.
- **a `production/migration-report.md` is already present** — a migration ran
  here, so these are post-migration leftovers and `--finalize` is the next step,
  not a second `migrate`.

- **值不一致** —— 两个事实来源，无法知道用户最后编辑的是哪一个。将其呈现出来，让用户决定。
- **已存在 `production/migration-report.md`** —— 这里已经运行过一次迁移，因此这些是迁移后的残留，下一步应是 `--finalize`，而不是再运行一次 `migrate`。

Both files merely *existing* is not exit 3 and must not be reported as a
conflict: `/start` writes `production/stage.txt` on every new v1.1 project as a
mirror, so agreement is the normal state. The script says
`the legacy files mirror it (values agree)` and exits 0 for that.

两个文件仅仅*存在*并不构成退出码 3，也绝不能报告为冲突：`/start` 会在每个新的 v1.1 项目上写入 `production/stage.txt` 作为镜像，因此一致才是正常状态。对于这种情况，脚本会说 `the legacy files mirror it (values agree)` 并以 0 退出。

Classify as **BLOCKING** in Phase 3: until migration runs, every skill reads
config through the legacy fallback chain, and v1.1 settings are unavailable.

在阶段 3 归类为**阻断**：在迁移运行之前，每个技能都通过旧版回退链读取配置，v1.1 的设置不可用。

---
