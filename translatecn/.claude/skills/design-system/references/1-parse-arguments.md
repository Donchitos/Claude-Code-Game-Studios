# /design-system — Phase 1: Parse Arguments & Validate
# /design-system — 第一阶段：解析参数并校验

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/design-system` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## 1. Parse Arguments & Validate
## 1. 解析参数并校验

**In this file:**

**本文件内容：**

- `docs.density`
- `docs.density`
- No system name given: the systems index picks the next one
- 未给出系统名称：由系统索引挑选下一个
- Detect retrofit mode
- 检测改造（retrofit）模式
- `workflow` for this system, and `## Summary` at every tier
- 本系统的 `workflow`，以及每个层级都需要的 `## Summary`

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

完整的检查模式参见 `.claude/docs/director-gates.md`。各个门禁的定义位于 `.claude/docs/director-gates/[gate-id].md`——被生成的智能体读取它自己的门禁文件；不要在父会话中读取它。


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅询问重大事项 · 自主模式记录后继续；
`automation_always_ask` 类目始终提示）。

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = bullet points, 2–5 lines per section,
skip rationale and preambles; `balanced` = paragraphs with light rationale
(`rigor: standard`); `thorough` = full prose with rationale, examples, and alternatives
considered. Apply it to every section you author. Mandated structures (the
Formulas variable table, Given-When-Then acceptance criteria) are correctness
requirements at every density — `terse` trims the surrounding prose, never the
required structure itself.

**`docs.density`** —— 它控制每个章节的*深度*，而 `workflow` 控制存在哪些章节。`modes.rigor` 会同时设置两者；若要单独改变深度，请显式设置 `docs.density`：`terse`（默认，经由 `rigor: minimal`）= 要点列表，每章节 2–5 行，省略理由说明和前言；`balanced` = 段落并带轻量理由说明（`rigor: standard`）；`thorough` = 完整散文，包含理由说明、示例和已考虑的备选方案。把它应用到你所撰写的每一个章节。强制性的结构（Formulas 变量表、Given-When-Then 验收标准）在任何密度下都是正确性要求——`terse` 修剪的是周边散文，绝不是所需的结构本身。

A system name or retrofit path is **required**. If missing:

系统名称或 retrofit 路径是**必需的**。如果缺失：

1. Check if `design/gdd/systems-index.md` exists.
2. If it exists: read it, find the highest-priority system with status "Not Started" or equivalent, and use `AskUserQuestion`:
   - Prompt: "The next system in your design order is **[system-name]** ([priority] | [layer]). Start designing it?"
   - Options: `[A] Yes — design [system-name]` / `[B] Pick a different system` / `[C] Stop here`
   - If [A]: proceed with that system name. If [B]: ask which system to design (plain text). If [C]: exit.
3. If no systems index exists, fail with:
   > "Usage: `/design-system <system-name>` — e.g., `/design-system movement`
   > Or to fill gaps in an existing GDD: `/design-system retrofit design/gdd/[system-name].md`
   > No systems index found. Run `/map-systems` first to map your systems and get the design order."

1. 检查 `design/gdd/systems-index.md` 是否存在。
2. 如果存在：读取它，找到状态为 "Not Started" 或等价状态中优先级最高的系统，并使用 `AskUserQuestion`：
   - 提示："你的设计顺序中的下一个系统是 **[system-name]**（[priority] | [layer]）。开始设计它吗？"
   - 选项：`[A] Yes — design [system-name]`（是——设计 [system-name]）/ `[B] Pick a different system`（选择其他系统）/ `[C] Stop here`（在此停止）
   - 如果选 [A]：继续使用该系统名称。如果选 [B]：询问要设计哪个系统（纯文本）。如果选 [C]：退出。
3. 如果系统索引不存在，则以以下内容失败：
   > "用法：`/design-system <system-name>` —— 例如 `/design-system movement`
   > 或者，若要填补现有 GDD 中的空白：`/design-system retrofit design/gdd/[system-name].md`
   > 未找到系统索引。请先运行 `/map-systems` 来梳理你的系统并获取设计顺序。"

**Detect retrofit mode:**
If the argument starts with `retrofit` or the argument is a file path to an
existing `.md` file in `design/gdd/`, enter **retrofit mode**:

**检测 retrofit 模式：**
如果参数以 `retrofit` 开头，或参数是 `design/gdd/` 中某个已存在 `.md` 文件的文件路径，则进入 **retrofit 模式**：

1. Read the existing GDD file. Read it by section: find the headings with
   the Grep tool (pattern `^#`, content mode) and Read those ranges with
   offset and limit.
2. Identify which of the 8 **possible** sections are present (scan for section
   headings): Overview, Player Fantasy, Detailed Design/Rules, Formulas,
   Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria.
   **Which of them are *required* depends on the effective tier** (§1) — at
   `standard` only 5 are, plus Formulas for math categories, and Player Fantasy
   and Tuning Knobs are skipped **by design**. Report an absent section as a gap
   only when the tier requires it; otherwise list it as available-to-add. Calling
   all 8 required here reports two by-design-absent sections as gaps on every
   `standard` project.
3. Identify which sections contain only placeholder text (`[To be designed]` or
   equivalent — blank, a single line, or obviously incomplete).
4. Present to the user before doing anything:
   ```
   ## Retrofit: [System Name]
   File: design/gdd/[filename].md

   Sections already written (will not be touched):
   ✓ [section name]
   ✓ [section name]

   Missing or incomplete sections (will be authored):
   ✗ [section name] — missing
   ✗ [section name] — placeholder only
   ```
5. Ask: "Shall I fill the [N] missing sections? I will not modify any existing content."
6. If yes: proceed to **Phase 2 (Gather Context)** as normal, but in **Phase 3**
   skip creating the skeleton (file already exists) and in **Phase 4** skip
   sections that are already complete. Only run the section cycle for missing/
   incomplete sections.
7. **Never overwrite existing section content.** Use Edit tool to replace only
   `[To be designed]` placeholders or empty section bodies.

1. 读取现有的 GDD 文件。按章节读取：用 Grep 工具（模式 `^#`，content 模式）找到标题，再用 offset 和 limit 读取这些区段。
2. 识别 8 个**可能**章节中哪些已存在（扫描章节标题）：Overview、Player Fantasy、Detailed Design/Rules、Formulas、Edge Cases、Dependencies、Tuning Knobs、Acceptance Criteria。
   **其中哪些是*必需*的取决于有效层级**（§1）——在 `standard` 下只有 5 个是必需的，数学类目还需 Formulas，而 Player Fantasy 和 Tuning Knobs **按设计**跳过。仅在层级要求时才把缺失的章节报告为缺口；否则把它列为可添加。如果在这里把全部 8 个都当作必需，就会在每个 `standard` 项目上把两个按设计缺失的章节报告为缺口。
3. 识别哪些章节只包含占位文本（`[To be designed]` 或等价物——空白、单行，或明显不完整）。
4. 在做任何事之前先向用户呈现：
   ```
   ## Retrofit: [System Name]
   File: design/gdd/[filename].md

   Sections already written (will not be touched):
   ✓ [section name]
   ✓ [section name]

   Missing or incomplete sections (will be authored):
   ✗ [section name] — missing
   ✗ [section name] — placeholder only
   ```
   ```
   ## Retrofit: [System Name]
   File: design/gdd/[filename].md

   已写好的章节（不会被改动）：
   ✓ [section name]
   ✓ [section name]

   缺失或不完整的章节（将被撰写）：
   ✗ [section name] —— 缺失
   ✗ [section name] —— 仅有占位符
   ```
5. 询问："要我填补这 [N] 个缺失章节吗？我不会修改任何已有内容。"
6. 如果同意：照常进入**第二阶段（收集上下文）**，但在**第三阶段**跳过创建骨架（文件已存在），在**第四阶段**跳过已完成的章节。只对缺失/不完整的章节运行章节循环。
7. **绝不要覆盖已有的章节内容。** 使用 Edit 工具只替换 `[To be designed]` 占位符或空的章节正文。

If NOT in retrofit mode, normalize the system name to kebab-case for the
filename (e.g., "combat system" becomes `combat-system`).

如果不在 retrofit 模式，把系统名称规范化为文件名用的 kebab-case（例如 "combat system" 变成 `combat-system`）。

**`workflow`** for this system (per `.claude/docs/workflow-modes.md`) — use the
`system_overrides` row for this system if the block lists one, else the project
value.

本系统的 **`workflow`**（依据 `.claude/docs/workflow-modes.md`）——如果该块列出了本系统的 `system_overrides` 行，就使用那一行，否则使用项目值。

The resolved tier determines which GDD sections are **required** (applied in §4).
**`## Summary` is required at every tier and is not one of the 8** — §5-pre
authors it unconditionally (*"This runs at every tier"*). The per-tier lists
below do not repeat it, and a GDD checked against a tier list alone would pass
with no Summary, the one section `/review-all-gdds` and the tiered-loading
readers depend on. Read every list below as "`## Summary`, plus:".
- `full` — all 8 sections
- `standard` — Overview, Detailed Design, Edge Cases, Dependencies, Acceptance
  Criteria (5 required); **Formulas conditional** — required when the system
  **defines numeric rules**: rates, curves, thresholds, costs, damage, drop
  weights, or any value a balance pass would tune. Optional only when the system
  defines no such value. **The `Category` in `systems-index.md` is a hint, not
  the test** — `Gameplay`, `Economy` and `Progression` systems almost always
  qualify, and a `Core`, `UI` or `Persistence` system that defines a numeric rule
  qualifies too. If the Detailed Design states a quantity that is not a constant
  of the engine, Formulas is required. **Player Fantasy and Tuning Knobs skipped**
  unless `workflow_overrides` force them (`tuning_knobs: true` forces Tuning Knobs)

  > **Do not gate this on a category token.** A test such as "the category is
  > combat / economy / progression / AI" matches tokens `/map-systems` does not
  > write — `templates/systems-index.md` defines the categories as `Core ·
  > Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative ·
  > Meta` and lists **combat and AI as example systems under `Gameplay`**. A
  > combat system categorised exactly as the template instructs matches none of
  > the four, and Formulas would be dropped for the system most likely to need it.
- `minimal` — a GDD is not required (the game brief replaces it). If invoked
  voluntarily at minimal, author exactly the 5 standard sections (Overview,
  Detailed Design, Edge Cases, Dependencies, Acceptance Criteria) — the
  conditional Formulas rule does NOT re-apply at minimal — and tell the user
  the GDD is optional at this workflow level.

已解析的层级决定了哪些 GDD 章节是**必需的**（在 §4 中应用）。**`## Summary` 在每个层级都是必需的，且不属于那 8 个章节之一**——§5-pre 无条件地撰写它（*"这在每个层级都会运行"*）。下面的各层级清单不会重复它，而仅对照层级清单检查的 GDD 会在没有 Summary 的情况下通过，而这恰恰是 `/review-all-gdds` 和分层加载读取者所依赖的那一个章节。请把下面每一个清单都读作"`## Summary`，外加："。
- `full` —— 全部 8 个章节
- `standard` —— Overview、Detailed Design、Edge Cases、Dependencies、Acceptance Criteria（5 个必需）；**Formulas 为条件性**——当系统**定义了数值规则**时必需：比率、曲线、阈值、成本、伤害、掉落权重，或任何平衡调整会调节的值。仅当系统不定义此类值时才是可选。**`systems-index.md` 中的 `Category` 是提示，不是判定标准**——`Gameplay`、`Economy` 和 `Progression` 系统几乎总是符合，定义了数值规则的 `Core`、`UI` 或 `Persistence` 系统同样符合。如果 Detailed Design 陈述了一个并非引擎常量的数量，那么 Formulas 就是必需的。**Player Fantasy 和 Tuning Knobs 跳过**，除非 `workflow_overrides` 强制要求它们（`tuning_knobs: true` 强制 Tuning Knobs）

  > **不要用类目标签来决定这件事。** 诸如"类目是 combat / economy / progression / AI"这样的判断，匹配的是 `/map-systems` 根本不会写出的标签——`templates/systems-index.md` 定义的类目是 `Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`，并把 **combat 和 AI 列为 `Gameplay` 下的示例系统**。完全按照模板指示归类的战斗系统，不匹配这四个中的任何一个，于是 Formulas 会从最可能需要它的那个系统中被丢弃。
- `minimal` —— 不要求 GDD（游戏简报表替代它）。如果在 minimal 下被自愿调用，就只撰写那 5 个标准章节（Overview、Detailed Design、Edge Cases、Dependencies、Acceptance Criteria）——条件性的 Formulas 规则在 minimal 下**不会**重新适用——并告知用户，在此工作流层级下 GDD 是可选的。

Retrofit mode is unaffected — it fills whatever sections are missing regardless
of tier.

Retrofit 模式不受影响——它补齐所有缺失的章节，无论层级如何。

---
