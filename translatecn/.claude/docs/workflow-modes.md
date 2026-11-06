# Workflow Modes — Shared Skill Pattern
# 工作流模式 — 共享技能模式

This document defines `modes.workflow` and `workflow_overrides` — how much
design documentation is REQUIRED before code can begin — for every skill that
authors, reviews, gates, or plans against project artifacts. Skills reference
this document instead of embedding the tier tables inline.
本文档为每个编写、评审、门禁或规划项目产物的技能定义 `modes.workflow` 和 `workflow_overrides` — 即在代码可以开始之前 REQUIRE（要求）多少设计文档。技能引用本文档，而不是内嵌层级表。

**Companion spec**: `.claude/docs/effects-map.md`
sections `modes.workflow` and `workflow_overrides` are the source of
truth for behavior. This document is the implementation pattern.
**配套规范**：`.claude/docs/effects-map.md` 中的
`modes.workflow` 和 `workflow_overrides` 部分是行为的唯一事实来源。本文档是实现模式。

> **Do not read `effects-map.md` during a skill run.** It is many times the
> size of everything CLAUDE.md loads per session combined — and it is a
> reference for *authoring and changing the spec*, not a runtime input.
> **This document is self-sufficient** for resolving
> the tier and applying it: the resolution chain, the three tiers, the required
> sections, and the override rules are all here. If you hit a case this document
> genuinely does not cover, read only the one `effects-map.md` section for the
> knob in question — never the file.
> **在技能运行期间不要读取 `effects-map.md`。** 它的规模是 CLAUDE.md 每会话加载的所有内容总和的许多倍 — 而且它是用于*编写和更改规范*的参考，不是运行时输入。**本文档是自足的**，足以解析层级并应用它：解析链、三个层级、必需章节和覆盖规则都在这里。如果你遇到本文档确实未覆盖的情况，只读取 `effects-map.md` 中针对所涉旋钮的那一个章节 — 绝不要读整个文件。

**Related shared docs**: `.claude/docs/automation-modes.md` (how skills prompt),
`.claude/docs/director-gates.md` (which reviewers spawn). `workflow` is
orthogonal to both — it controls *what artifacts must exist*, not *how the
skill prompts* or *who reviews*.
**相关共享文档**：`.claude/docs/automation-modes.md`（技能如何提示）、`.claude/docs/director-gates.md`（哪些评审者生成）。`workflow` 与两者正交 — 它控制*必须存在哪些产物*，而不是*技能如何提示*或*谁来评审*。

---

## How to Use This Document
## 如何使用本文档

A skill that authors, reviews, or gates a design artifact resolves the
effective workflow tier at startup, then applies the required-section /
required-artifact set for that tier.
编写、评审或门禁设计产物的技能会在启动时解析生效的工作流层级，然后应用该层级的必需章节 / 必需产物集。

**Resolution (per skill):**
**解析（逐技能）：**

```
Resolve the workflow tier (store the result; see scope note below):
1. If the resolution is for a named system AND
   `workflow_overrides.system_overrides.<system>` is set → use that tier
2. Else read `modes.workflow` from `project.yaml` → use that value
3. Else → use the tier implied by `modes.rigor`
   (`minimal`→`minimal`, `standard`→`standard`, `full`→`full`;
    `rigor` itself defaults to `minimal`)
```

`modes.workflow` has **no terminal default** — step 3 is the `rigor` expansion,
not a hardcoded `standard`. The resolved value is the same for an unconfigured
project, so nothing observable changed; but a skill that hardcodes `standard` as
its fallback will ignore `rigor: minimal` and `rigor: full` entirely.
`modes.workflow` **没有终端默认值** — 步骤 3 是 `rigor` 展开，而不是硬编码的 `standard`。对于未配置的项目，解析值相同，因此可观察到的内容没有改变；但一个将 `standard` 硬编码为回退值的技能会完全忽略 `rigor: minimal` 和 `rigor: full`。

### What `<system>` is — one derivation, everywhere
### `<system>` 是什么 — 一处推导，处处适用

**`<system>` is the GDD filename stem**: `design/gdd/forge-heat-system.md` →
`forge-heat-system`. That is the key to write under
`workflow_overrides.system_overrides`, and every skill must derive it the same
way.
**`<system>` 是 GDD 文件名主干**：`design/gdd/forge-heat-system.md` →
`forge-heat-system`。这就是要写入 `workflow_overrides.system_overrides` 下的键，每个技能都必须以相同方式推导它。

A `TR-[system]-NNN` ID's `[system]` segment is **an alias, not the key**. Accept
it as a fallback match when the GDD stem yields nothing, but never derive the key
from it in preference to the stem.
`TR-[system]-NNN` ID 的 `[system]` 段是**别名，不是键**。当 GDD 主干没有产出时，接受它作为回退匹配，但绝不要优先于主干从它推导键。

> **Why this is stated here rather than per skill.** Reading *"the `[system]`
> segment of its `TR-[system]-NNN` ID (else its `design/gdd/` path)"* — TR-ID
> **first** — is the wrong order. A system whose GDD is `forge-heat-system.md` and
> whose requirements are `TR-forge-001` would then have **two different override
> keys depending on whether a registry entry existed**, and the documented remedy
> for a missing GDD section — "set
> `workflow_overrides.system_overrides.forge-heat-system: full`" — would be looked
> up under `forge`, find nothing, and continue at the project tier **silently**.
> The escape hatch would exist and could not be reached.
> **为什么在此说明而不是逐技能说明。** 按*"其 `TR-[system]-NNN` ID 的 `[system]` 段（否则其 `design/gdd/` 路径）"*来读取 — TR-ID **优先** — 是错误的顺序。一个 GDD 为 `forge-heat-system.md` 且需求为 `TR-forge-001` 的系统，随后会**根据是否存在注册表条目而拥有两个不同的覆盖键**，而针对缺失 GDD 章节的文档化补救措施 — "设置 `workflow_overrides.system_overrides.forge-heat-system: full`" — 会在 `forge` 下查找、什么也找不到，并**静默地**继续使用项目层级。逃生舱会存在却无法到达。

**A key that matches no system is an error, not a no-op.** If
`workflow_overrides.system_overrides` contains a key that resolves to no GDD stem
in `design/gdd/`, say so — naming the unmatched key and the stems available.
Silently ignoring it would leave an override that does nothing, unnoticed.
**不匹配任何系统的键是错误，而不是空操作。** 如果 `workflow_overrides.system_overrides` 包含一个在 `design/gdd/` 中解析不到任何 GDD 主干的键，请说明 — 指出未匹配的键和可用的主干。静默忽略它会留下一个不起作用的覆盖，且无人察觉。

> **Checked where GDDs are expected to already exist — not by the skill that
> writes them.** `/gate-check` is the single implementing site (see
> `.claude/skills/gate-check/SKILL.md` §"Per-system overrides"), and it runs at a
> phase boundary, by which point every in-scope GDD should be on disk. An
> unmatched key there is genuinely suspicious.
>
> `/design-system` **creates** `design/gdd/<system>.md`, so before its first run
> the override key matches no stem *by definition* — that is the healthy case,
> not an error. It must not report the key as orphaned, and must not refuse to
> apply the tier it names. The same holds for any other authoring skill running
> before the GDD exists. Applying this rule there would fire on exactly the
> configuration it was written to protect.
> **在预期 GDD 已经存在之处检查 — 而不是由编写它们的技能检查。** `/gate-check` 是唯一的实现位置（见 `.claude/skills/gate-check/SKILL.md` §"Per-system overrides"），它在阶段边界运行，到那时每个范围内 GDD 都应已在磁盘上。那里的未匹配键确实可疑。
>
> `/design-system` **创建** `design/gdd/<system>.md`，因此在其首次运行之前，覆盖键*按定义*不匹配任何主干 — 这是健康情况，不是错误。它不得将键报告为孤立，也不得拒绝应用它所指名的层级。对于在 GDD 存在之前运行的任何其他编写技能同样如此。在那里应用此规则会恰好触发它被编写来保护的配置。

---

Step 1 (the per-system override) applies to skills that act on a named system:
步骤 1（逐系统覆盖）适用于作用于具名系统的技能：
- **Single-system, resolve once per run**: `design-system`, `design-review`,
  `dev-story`, `story-done`, `create-stories` (one story/epic per invocation).
- **单系统，每次运行解析一次**：`design-system`、`design-review`、`dev-story`、`story-done`、`create-stories`（每次调用一个故事/史诗）。
- **Multi-system, resolve once per item**: `story-readiness` (per story across
  `all`/`sprint` scope), `qa-plan` and `regression-suite` audit (per GDD/system).
  These do NOT freeze a single tier for the run — different systems in one run
  may resolve to different tiers.
- **多系统，逐项解析一次**：`story-readiness`（跨 `all`/`sprint` 范围逐故事）、`qa-plan` 和 `regression-suite` 审计（逐 GDD/系统）。这些不会为运行冻结单一层级 — 一次运行中的不同系统可能解析为不同层级。

Skills that operate project-wide (`gate-check`, `create-epics`) use the
project-level `workflow` plus consider per-system overrides where the tier table
says so.
在项目范围运作的技能（`gate-check`、`create-epics`）使用项目级 `workflow`，并在层级表规定之处考虑逐系统覆盖。

> **"Critical ADR" (used in the tier tables):** an ADR governing a
> **Foundation-layer** system (scene management, event architecture, save/load,
> and the like — the systems whose decisions everything else depends on). At
> `standard`, only critical ADRs are required/blocking; non-critical ADRs are
> advisory. When in doubt about an ADR's layer, treat it as critical (fail safe
> toward requiring it).
> **"关键 ADR"（用于层级表）：** 治理**基础层**系统（场景管理、事件架构、存档/读档等 — 其他所有决策都依赖的系统）的 ADR。在 `standard` 下，只有关键 ADR 是必需/阻塞的；非关键 ADR 是建议性的。当不确定某个 ADR 的层级时，将其视为关键（朝要求它的方向失效安全）。

`modes.workflow` reads via **`resolve_config --keys workflow`** (or
`resolve_setting modes.workflow`), which applies the whole chain including the
`rigor` expansion. Do **not** use `get_effective_yaml_key modes.workflow`: it
reads the two YAML files only, so on a project that sets `modes.rigor` and not
`modes.workflow` it returns **empty** while the effective tier is whatever rigor
implies. (`project.local.yaml` is not allowed to override workflow — it is locked
to `project.yaml` per the whitelist — so the only sources are `project.yaml` and
the expansion.) Per-system overrides read via
`get_yaml_key project.yaml workflow_overrides.system_overrides.<system>`.
`modes.workflow` 通过 **`resolve_config --keys workflow`**（或 `resolve_setting modes.workflow`）读取，它应用包含 `rigor` 展开在内的整条链。**不要**使用 `get_effective_yaml_key modes.workflow`：它只读取两个 YAML 文件，因此在设置了 `modes.rigor` 而未设置 `modes.workflow` 的项目上，它会返回**空**，而生效层级是 rigor 所蕴含的任何值。（`project.local.yaml` 不允许覆盖 workflow — 按白名单它被锁定到 `project.yaml` — 因此唯一来源是 `project.yaml` 和展开。）逐系统覆盖通过 `get_yaml_key project.yaml workflow_overrides.system_overrides.<system>` 读取。

---

## The Three Tiers
## 三个层级

| Tier | Token/time cost | Required before code | Best for |
| 层级 | Token/时间成本 | 代码前的必需项 | 适用场景 |
|------|----------------|---------------------|----------|
| `full` | High | All 8 GDD sections per system, full architecture, all ADRs, art bible, UX specs per screen | Teams, commercial titles, learning the full pipeline |
| `full` | 高 | 每个系统的全部 8 个 GDD 章节、完整架构、所有 ADR、美术圣经、逐屏幕 UX 规格 | 团队、商业作品、学习完整流水线 |
| `standard` | Balanced | 5 GDD sections per system, one architecture doc, critical ADRs, game concept, systems index | Projects that outgrew a brief - several interacting systems, or a design someone else implements |
| `standard` | 均衡 | 每个系统 5 个 GDD 章节、一份架构文档、关键 ADR、游戏概念、系统索引 | 超出简报承载能力的项目 - 若干个相互作用的系统，或由他人实现的设计 |
| `minimal` | Low | One-page `design/game-brief.md` + engine choice (its build-order field is the plan — no separate sprint plan) | **Default.** Jam projects, small scope, design already in your head |
| `minimal` | 低 | 单页 `design/game-brief.md` + 引擎选择（其构建顺序字段就是计划 — 没有单独的冲刺计划） | **默认。** 开发挑战赛项目、小范围、设计已在脑中 |

**Default**: `minimal` (the rationale block above `_yaml_helper_defaults` in
`.claude/hooks/yaml-helper.sh` carries the reasoning and the ordering
constraint). **Set by**: `/start` (via `modes.rigor`), `/settings`. **Locked to
`project.yaml`** (not locally overridable — divergence would change which
artifacts must exist on disk).
**默认**：`minimal`（`.claude/hooks/yaml-helper.sh` 中 `_yaml_helper_defaults` 上方的理由块承载了推理和排序约束）。**设置方式**：`/start`（通过 `modes.rigor`）、`/settings`。**锁定到 `project.yaml`**（不可本地覆盖 — 分歧会改变磁盘上必须存在哪些产物）。

> **Permissive, not restrictive.** `workflow` controls what is REQUIRED, not
> what is ALLOWED. Any skill can run at any tier. The setting changes what
> `gate-check` enforces and what completeness checks validate — never what the
> user can invoke.
> **宽松，而非限制性。** `workflow` 控制什么是 REQUIRE（要求）的，而不是什么是 ALLOWED（允许）的。任何技能都可以在任何层级运行。该设置改变的是 `gate-check` 强制执行的内容和完整性检查验证的内容 — 绝不是用户可以调用的内容。

> **`minimal` floor.** Even at minimal, engine choice and a filled
> **`design/game-brief.md`** are required before code starts — the brief's
> build-order field is the plan, so there is no separate `sprint-plan` step.
> Everything else can be skipped.
> **`minimal` 底线。** 即使在 minimal 下，引擎选择和填写完毕的 **`design/game-brief.md`** 也是代码开始前的必需项 — 简报的构建顺序字段就是计划，因此没有单独的 `sprint-plan` 步骤。其他一切都可以跳过。

> **"Game brief" is a real artifact at `minimal`: `design/game-brief.md`.**
> `/brainstorm` writes it from the one-page template
> (`.claude/docs/templates/game-brief.md`) when the effective tier is `minimal`,
> in place of the full-length `design/gdd/game-concept.md` it writes at
> `standard`/`full`. The two are distinct files for distinct tiers: any check,
> gate, or glob for the `minimal` design artifact must target
> **`design/game-brief.md`**; `game-concept.md` remains the `standard`/`full`
> concept doc.
> **"游戏简报"是 `minimal` 下的真实产物：`design/game-brief.md`。** 当生效层级为 `minimal` 时，`/brainstorm` 会从单页模板（`.claude/docs/templates/game-brief.md`）编写它，替代它在 `standard`/`full` 下编写的完整长度 `design/gdd/game-concept.md`。两者是不同层级的不同文件：任何针对 `minimal` 设计产物的检查、门禁或 glob 都必须以 **`design/game-brief.md`** 为目标；`game-concept.md` 仍是 `standard`/`full` 概念文档。

---

## GDD Required Sections per Tier
## 各层级 GDD 必需章节

The 8 GDD sections: Overview, Player Fantasy, Detailed Rules, Formulas,
Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria.
8 个 GDD 章节：Overview、Player Fantasy、Detailed Rules、Formulas、Edge Cases、Dependencies、Tuning Knobs、Acceptance Criteria。

> **Section-name alias.** "Detailed Rules" is the canonical name in the design
> standard, but the GDD template (`.claude/docs/templates/game-design-document.md`)
> and `/design-system` author this section under the heading `## Detailed Design`
> (with Core Rules / States / Interactions sub-headings). The two names denote the
> **same required section** — any skill that detects or validates section presence
> (`design-review`, `gate-check`, `adopt`, `project-stage-detect`) must accept
> either heading. Do not treat "Detailed Rules" as missing when `## Detailed
> Design` is present.
> **章节名别名。** "Detailed Rules" 是设计标准中的规范名称，但 GDD 模板（`.claude/docs/templates/game-design-document.md`）和 `/design-system` 以 `## Detailed Design` 作为标题编写该章节（带有 Core Rules / States / Interactions 子标题）。两个名称表示**同一个必需章节** — 任何检测或验证章节存在的技能（`design-review`、`gate-check`、`adopt`、`project-stage-detect`）都必须接受任一标题。当出现 `## Detailed Design` 时，不要将 "Detailed Rules" 视为缺失。

| Tier | Required GDD sections |
| 层级 | 必需的 GDD 章节 |
|------|----------------------|
| `full` | All 8 |
| `full` | 全部 8 个 |
| `standard` | **5 required**: Overview, Detailed Rules, Edge Cases, Dependencies, Acceptance Criteria. **Conditional**: Formulas — required when the system **defines numeric rules** (rates, curves, thresholds, costs, damage, drop weights — anything a balance pass would tune); optional only when it defines none. The `Category` column is a hint, not the test. **Skipped**: Player Fantasy, Tuning Knobs. |
| `standard` | **5 个必需**：Overview、Detailed Rules、Edge Cases、Dependencies、Acceptance Criteria。**条件性**：Formulas — 当系统**定义数值规则**（速率、曲线、阈值、成本、伤害、掉落权重 — 任何平衡性调整会调节的内容）时为必需；仅当它不定义任何数值规则时为可选。`Category` 列是提示，不是判断标准。**跳过**：Player Fantasy、Tuning Knobs。 |
| `minimal` | None — `design/game-brief.md` replaces GDDs. A GDD may still be authored voluntarily. |
| `minimal` | 无 — `design/game-brief.md` 替代 GDD。仍可自愿编写 GDD。 |

> **Edge Cases is required at `standard`** (it was promoted from optional —
> skipping it produced "what happens if X is null?" debt during implementation).
> **Edge Cases 在 `standard` 下是必需的**（它从可选提升而来 — 跳过它在实现期间产生了"如果 X 为 null 会怎样？"的债务）。

> **Art bible is conditional at `standard`** — required only if visual asset
> stories exist in the project. Code-focused projects skip it. At `full`, all
> 9 art bible sections are required. (`workflow_overrides.art_bible_strict:
> true` forces all 9 regardless of tier.)
> **美术圣经在 `standard` 下是条件性的** — 仅当项目中存在视觉资源故事时才需要。以代码为重点的项目可跳过它。在 `full` 下，全部 9 个美术圣经章节都是必需的。（`workflow_overrides.art_bible_strict: true` 强制要求全部 9 个，不论层级。）

---

## `workflow_overrides`
## `workflow_overrides`

This key holds two mechanisms with **different directional rules**. Read the one
you are using — conflating them is a known and easy mistake.
该键包含两种具有**不同方向规则**的机制。请阅读你正在使用的那个 — 将它们混为一谈是一个已知且容易犯的错误。

```yaml
workflow_overrides:
  # --- the three boolean FLAGS: additive, stricter-only ---
  edge_cases: false          # force Edge Cases required (no-op at standard/full; relevant at minimal)
  tuning_knobs: false        # force Tuning Knobs required (relevant at standard, no-op at full)
  art_bible_strict: false    # force all 9 art bible sections regardless of asset stories

  # --- system_overrides: replaces a tier, BOTH directions ---
  system_overrides: {}       # per-system tier overrides (see below)
```

**The three boolean flags are additive on top of the chosen `workflow` level —
they make requirements STRICTER, never looser.** Each one only ever forces a
requirement *on*; setting a flag cannot opt out of a requirement the tier
imposes. There is no value of `edge_cases`, `tuning_knobs` or `art_bible_strict`
that removes anything.
**三个布尔标志是在所选 `workflow` 层级之上的附加项 — 它们让要求更严格，绝不更宽松。** 每一个都只会*打开*某项要求；设置标志无法选择退出该层级施加的要求。`edge_cases`、`tuning_knobs` 或 `art_bible_strict` 没有任何值会移除任何内容。

**`system_overrides` is not a flag and is not additive.** It *replaces* the
effective tier for one named system, in **either** direction — see the next
section. A loosening override genuinely loosens: on a `full` project,
`system_overrides.inventory: minimal` drops that system's required sections to
zero. That is the intended design (it is what makes "one trivial system inside a
serious project" expressible), but it means an override is **not** a safe
no-op — do not leave one in place assuming the stricter-only rule protects you.
**`system_overrides` 不是标志，也不是附加项。** 它为某个具名系统*替换*生效层级，方向**可以是任一** — 见下一节。放宽的覆盖确实会放宽：在 `full` 项目中，`system_overrides.inventory: minimal` 会把该系统的必需章节降为零。这是有意设计（它使"严肃项目中的一个琐碎系统"可表达），但这意味着覆盖**不是**安全的空操作 — 不要假定仅更严格的规则会保护你，就把一个覆盖留在那里。

### Per-system overrides
### 逐系统覆盖

```yaml
workflow_overrides:
  system_overrides:
    combat: full              # combat GDD requires all 8 sections regardless of project workflow
    inventory: minimal        # inventory needs no GDD — the game brief covers it (minimal = no required sections)
```

`system_overrides` is a map of `system_name: workflow_level`. The named system
uses the override tier; all other systems use the project-level `workflow`.
A skill acting on a named system resolves its effective tier via step 1 of the
resolution chain above.
`system_overrides` 是 `system_name: workflow_level` 的映射。具名系统使用覆盖层级；所有其他系统使用项目级 `workflow`。作用于具名系统的技能通过上述解析链的步骤 1 解析其生效层级。

---

## Effective-Tier Resolution Worked Example
## 生效层级解析示例

Project has `modes.workflow: standard`, `workflow_overrides.system_overrides.combat: full`.
项目有 `modes.workflow: standard`、`workflow_overrides.system_overrides.combat: full`。

- `/design-system combat` → effective tier **full** → requires all 8 sections
- `/design-system combat` → 生效层级 **full** → 需要全部 8 个章节
- `/design-system inventory` → no override → effective tier **standard** → 5 sections + conditional Formulas
- `/design-system inventory` → 无覆盖 → 生效层级 **standard** → 5 个章节 + 条件性 Formulas
- `/gate-check` (Systems Design → Technical Setup) → requires the combat GDD at 8 sections AND every other MVP GDD at 5 sections before passing
- `/gate-check`（系统设计 → 技术搭建）→ 在通过前要求 combat GDD 达到 8 个章节，并且其他每个 MVP GDD 达到 5 个章节

---

## Per-Skill Behavior (the working summary — sufficient at runtime)
## 逐技能行为（工作摘要 — 运行时足够）

**Authoring** — branch on the effective tier for required sections (and, for
`brainstorm`, for which design artifact is produced — `design/game-brief.md` at
`minimal` vs `design/gdd/game-concept.md` at `standard`/`full`):
`brainstorm`, `design-system`, `art-bible`, `create-architecture`, `ux-design`,
`map-systems`, `architecture-decision`.
**编写** — 根据生效层级对必需章节进行分支（对于 `brainstorm`，还要根据产出哪个设计产物进行分支 — `minimal` 下为 `design/game-brief.md`，`standard`/`full` 下为 `design/gdd/game-concept.md`）：`brainstorm`、`design-system`、`art-bible`、`create-architecture`、`ux-design`、`map-systems`、`architecture-decision`。

**Review/validation** — validate against the effective tier; missing
*required* sections block, missing *optional* sections warn:
`design-review`, `review-all-gdds`, `architecture-review`, `consistency-check`,
`content-audit`.
**评审/验证** — 对照生效层级验证；缺失*必需*章节会阻塞，缺失*可选*章节会警告：`design-review`、`review-all-gdds`、`architecture-review`、`consistency-check`、`content-audit`。

**Gate enforcement** — `gate-check` uses a different artifact checklist per
stage per tier (the highest-visibility impact). Each gate's own checklist and
tier reductions live in `.claude/skills/gate-check/references/gate-<phase>.md`,
and `/gate-check` loads only the one gate it is running — that is the right
place to look, not `effects-map.md`.
**门禁执行** — `gate-check` 按层级为每个阶段使用不同的产物检查清单（最明显的影响）。每个门禁自己的清单和层级缩减位于 `.claude/skills/gate-check/references/gate-<phase>.md`，而 `/gate-check` 只加载它正在运行的单一门禁 — 那才是正确的查看位置，而不是 `effects-map.md`。

**Planning/implementation** — adjust artifact prerequisites:
`create-epics`, `create-stories`, `dev-story`, `story-readiness`, `story-done`,
`qa-plan`, `regression-suite`.
**规划/实现** — 调整产物前置条件：`create-epics`、`create-stories`、`dev-story`、`story-readiness`、`story-done`、`qa-plan`、`regression-suite`。

**Support** — adjust "what's missing" expectations so optional docs aren't
flagged as gaps: `project-stage-detect`, `adopt`, `reverse-document`,
`propagate-design-change`, `help`.
**支持** — 调整"缺少什么"的预期，使可选文档不会被标记为差距：`project-stage-detect`、`adopt`、`reverse-document`、`propagate-design-change`、`help`。

---

## Workflow Change Mid-Project
## 项目中途更改工作流

When `workflow` changes via `/settings`, emit an informational note:
当 `workflow` 通过 `/settings` 更改时，发出信息性说明：

> "Workflow changed from [old] to [new]. Run `/content-audit` to see what's now
> required or extra. No automatic migration — existing files stay in place."
> "工作流已从 [旧] 更改为 [新]。运行 `/content-audit` 查看现在哪些是必需的或多余的。没有自动迁移 — 现有文件保持原位。"

No documents are auto-deleted, auto-generated, or blocked. The setting only
affects *new* enforcement going forward.
不会自动删除、自动生成或阻塞任何文档。该设置只影响后续的*新*执行。

---

## Companion Settings
## 配套设置

These are separate settings that compose with `workflow`. The summaries below
are what a skill needs at runtime; `effects-map.md` carries the exhaustive
per-skill tables for spec authors, and is not worth loading to apply a knob.
这些是与 `workflow` 组合的独立设置。下面的摘要是技能在运行时需要的内容；`effects-map.md` 为规范作者承载详尽的逐技能表，为应用某个旋钮而加载它并不值得。

> **All four below are fronted by `modes.rigor`** (`docs.density`,
> `modes.story_granularity`, `qa.level`, `team.size` — along with `workflow` itself,
> and `modes.review_mode`, for six fronted knobs total). One question at `/start`
> sets all of them; setting any explicitly overrides just that one and leaves its
> siblings on the rigor level. `team.size` and `modes.review_mode` are the two that
> also stay overridable from `project.local.yaml` (they are personal-experience
> knobs, not on-disk artifacts).
> **下面四项全部由 `modes.rigor` 前置**（`docs.density`、`modes.story_granularity`、`qa.level`、`team.size` — 连同 `workflow` 本身和 `modes.review_mode`，总共六个前置旋钮）。`/start` 中的一个问题设置所有项；显式设置任何一项只会覆盖那一项，并让其同类项留在严谨度层级上。`team.size` 和 `modes.review_mode` 是其中两个也仍可从 `project.local.yaml` 覆盖的项（它们是个人体验旋钮，不是磁盘上的产物）。

- **`docs.density`** (`terse` | `balanced` | `thorough`) — `workflow` controls
  *which sections exist*; `density` controls *how deep each section goes*.
  `rigor` sets the two together; override `docs.density` alone to get
  `full` + `terse` = "all 8 sections, each compact."
- **`docs.density`**（`terse` | `balanced` | `thorough`）— `workflow` 控制*存在哪些章节*；`density` 控制*每个章节深入到什么程度*。`rigor` 将两者一起设置；单独覆盖 `docs.density` 可获得 `full` + `terse` = "全部 8 个章节，每个都紧凑"。
- **`modes.story_granularity`** (`coarse` | `balanced` | `fine`) — how big
  each story is and how many per epic/sprint.
- **`modes.story_granularity`**（`coarse` | `balanced` | `fine`）— 每个故事有多大，以及每个史诗/冲刺有多少个。
- **`qa.level`** (`minimal` | `standard` | `full`) — what test evidence is
  required to mark stories Done. Composes with `testing.strict`:
  `qa.level` = is evidence required; `testing.strict` = do failures block.
- **`qa.level`**（`minimal` | `standard` | `full`）— 将故事标记为 Done 需要什么测试证据。与 `testing.strict` 组合：`qa.level` = 是否要求证据；`testing.strict` = 失败是否阻塞。
- **`team.size`** (`individual` | `small` | `studio`) — which agents are active by
  default. Different axis from workflow: workflow controls *what docs are
  required*, team.size controls *which agents exist to make them*.
- **`team.size`**（`individual` | `small` | `studio`）— 默认哪些智能体处于活动状态。与 workflow 是不同的轴：workflow 控制*要求哪些文档*，team.size 控制*有哪些智能体来制作它们*。
