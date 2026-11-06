# /design-system — Phase 4: Section-by-Section Design
# /design-system — 第四阶段：逐章节设计

> Part of `/design-system`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/design-system` 的一部分。`SKILL.md` 说明了何时阅读本文件；它已解析的设置，以及其后各标题下的规则，在此同样适用。

## 4. Section-by-Section Design
## 4. 逐章节设计

**In this file:**

**本文件内容：**

- The Section Cycle
- 章节循环
- Section-Specific Guidance
- 章节专项指导
- Section A: Overview
- 章节 A：Overview（概述）
- Section B: Player Fantasy
- 章节 B：Player Fantasy（玩家幻想）
- Section C: Detailed Design (Core Rules, States, Interactions)
- 章节 C：Detailed Design（详细设计：核心规则、状态、交互）
- Section D: Formulas
- 章节 D：Formulas（公式）
- Section E: Edge Cases
- 章节 E：Edge Cases（边界情况）
- Section F: Dependencies
- 章节 F：Dependencies（依赖）
- Section G: Tuning Knobs
- 章节 G：Tuning Knobs（调节旋钮）
- Section H: Acceptance Criteria
- 章节 H：Acceptance Criteria（验收标准）
- Optional Sections: Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions
- 可选章节：Visual/Audio（视觉/音频）、Game Feel（游戏手感）、UI Requirements（UI 需求）、Cross-References（交叉引用）、Open Questions（未决问题）

**Author only the sections required at the resolved tier** (§1). At `standard`,
the walk covers A (Overview), C (Detailed Design), E (Edge Cases),
F (Dependencies), H (Acceptance Criteria) — plus D (Formulas) when the system
defines numeric rules (see §1; the category is a hint, not the test); skip B (Player Fantasy) and
G (Tuning Knobs) unless `workflow_overrides.tuning_knobs: true` forces G. At
`full`, walk all eight (A–H). At `minimal`, the GDD is optional — if authoring
voluntarily, walk the standard set. Any `system_overrides.<system>` tier was
already folded into the resolved tier in §1.

**只撰写已解析层级所要求的章节**（§1）。在 `standard` 下，行走路径覆盖 A（Overview）、C（Detailed Design）、E（Edge Cases）、F（Dependencies）、H（Acceptance Criteria）——当系统定义了数值规则时再加上 D（Formulas）（见 §1；类目是提示，不是判定标准）；跳过 B（Player Fantasy）和 G（Tuning Knobs），除非 `workflow_overrides.tuning_knobs: true` 强制要求 G。在 `full` 下，走完全部八个（A–H）。在 `minimal` 下，GDD 是可选的——如果自愿撰写，就走标准集合。任何 `system_overrides.<system>` 层级在 §1 中都已并入已解析层级。

Walk through each required section in order. For **each section**, follow this cycle:

按顺序走完每个必需章节。对于**每个章节**，遵循以下循环：

### The Section Cycle
### 章节循环

```
Context  ->  Questions  ->  Options  ->  Decision  ->  Draft  ->  Approval  ->  Write
```

```
上下文  ->  提问  ->  选项  ->  决策  ->  草稿  ->  批准  ->  写入
```

1. **Context**: State what this section needs to contain, and surface any relevant
   decisions from dependency GDDs that constrain it.

1. **上下文（Context）**：说明该章节需要包含什么内容，并揭示依赖 GDD 中会约束它的任何相关决策。

2. **Questions**: Ask clarifying questions specific to this section. Use
   `AskUserQuestion` for constrained questions, conversational text for open-ended
   exploration.

2. **提问（Questions）**：提出该章节特有的澄清问题。对受限问题使用 `AskUserQuestion`，对开放式探索使用对话式文本。

3. **Options**: Where the section involves design choices (not just documentation),
   present 2-4 approaches with pros/cons. Explain reasoning in conversation text,
   then use `AskUserQuestion` to capture the decision.

3. **选项（Options）**：当章节涉及设计选择（而不仅仅是文档记录）时，呈现 2-4 种方案及利弊。在对话文本中说明推理，然后用 `AskUserQuestion` 记录决策。

4. **Decision**: User picks an approach or provides custom direction.

4. **决策（Decision）**：用户选择一个方案，或提供自定义方向。

5. **Draft**: Write the section content in conversation text for review. Flag any
   provisional assumptions about undesigned dependencies.

5. **草稿（Draft）**：在对话文本中写出章节内容以供评审。标记出任何关于未设计依赖的临时假设。

6. **Approval**: Per the resolved `modes.automation` mode
   (`.claude/docs/automation-modes.md`):

6. **批准（Approval）**：依据已解析的 `modes.automation` 模式（`.claude/docs/automation-modes.md`）：

   **In `collaborative` mode**: Immediately after the draft — in the SAME
   response — use `AskUserQuestion`. **NEVER use plain text. NEVER skip
   this step.**
   - Prompt: "Approve the [Section Name] section?"
   - Options: `[A] Approve — write it to file` / `[B] Make changes — describe what to fix` / `[C] Start over`

   **在 `collaborative`（协作）模式下**：紧接草稿之后——在**同一个**回复中——使用 `AskUserQuestion`。**绝不要使用纯文本。绝不要跳过这一步。**
   - 提示："批准 [Section Name] 章节吗？"
   - 选项：`[A] Approve — write it to file`（批准——写入文件）/ `[B] Make changes — describe what to fix`（做修改——描述要修正什么）/ `[C] Start over`（重新开始）

   **The draft and the approval widget MUST appear together in one response.
   If the draft appears without the widget, the user is left at a blank prompt
   with no path forward — this is a protocol violation in collaborative mode.**

   **草稿和批准组件必须出现在同一个回复中。如果草稿出现却没有该组件，用户会被留在空白提示处、无路可走——在协作模式下这属于违反协议。**

   **In `guided` mode**: Write the section immediately after the draft with
   a brief one-line summary of what was decided. Skip the per-section widget;
   the multi-section authoring rule (no per-section confirmation) applies.

   **在 `guided`（引导）模式下**：在草稿之后立即写入该章节，并用一行简要摘要说明决定了什么。跳过每章节的组件；多章节撰写规则（不做每章节确认）适用。

   **In `autonomous` mode**: Write the section directly and call
   `log_decision` with `Decision point: Approve [Section Name] section`,
   `Chosen: [A] Approve`, `Category: minor`.

   **在 `autonomous`（自主）模式下**：直接写入该章节，并调用 `log_decision`，参数为 `Decision point: Approve [Section Name] section`、`Chosen: [A] Approve`、`Category: minor`。

7. **Write**: Use the Edit tool to replace the placeholder with the approved content.
   **CRITICAL**: Always include the section heading in the `old_string` to ensure
   uniqueness — never match `[To be designed]` alone, as multiple sections use the
   same placeholder and the Edit tool requires a unique match. Use this pattern:
   ```
   old_string: "## [Section Name]\n\n[To be designed]"
   new_string: "## [Section Name]\n\n[approved content]"
   ```
   Confirm the write.

7. **写入（Write）**：使用 Edit 工具用已批准的内容替换占位符。**关键：** 始终在 `old_string` 中包含章节标题以确保唯一性——绝不要只匹配 `[To be designed]`，因为多个章节使用同一个占位符，而 Edit 工具需要唯一匹配。使用以下模式：
   ```
   old_string: "## [Section Name]\n\n[To be designed]"
   new_string: "## [Section Name]\n\n[approved content]"
   ```
   确认写入。

8. **Registry conflict check** (Sections C and D only — Detailed Design and Formulas):
   After writing, scan the section content for entity names, item names, formula
   names, and numeric constants that appear in the registry. For each match:
   - Compare the value just written against the registry entry.
   - If they differ: **surface the conflict immediately** before starting the next
     section. Do not continue silently.
     > "Registry conflict: [name] is registered in [source GDD] as [registry_value].
     > This section just wrote [new_value]. Which is correct?"
   - If new (not in registry): flag it as a candidate for registry registration
     (will be handled in Phase 5).

8. **注册表冲突检查**（仅章节 C 和 D —— 详细设计与公式）：写入之后，扫描章节内容中出现在注册表里的实体名称、物品名称、公式名称和数值常量。对每一处匹配：
   - 把刚刚写入的值与注册表条目比较。
   - 如果两者不同：在开始下一个章节之前**立即把冲突暴露出来**。不要静默继续。
     > "注册表冲突：[name] 在 [source GDD] 中注册为 [registry_value]。本节刚刚写入的是 [new_value]。哪个正确？"
   - 如果是新的（不在注册表中）：把它标记为注册表登记的候选（将在第五阶段处理）。

After writing each section, update `production/session-state/active.md` with the
completed section name. Use Glob to check if the file exists — use Write to create
it if absent, Edit to update it if present.

每写完一个章节后，用已完成的章节名称更新 `production/session-state/active.md`。使用 Glob 检查文件是否存在——不存在则用 Write 创建，存在则用 Edit 更新。

### Section-Specific Guidance
### 章节专项指导

Each section has unique design considerations and may benefit from specialist agents:

每个章节都有独特的设计考量，并可能受益于专家智能体：

**Every skipped spawn is announced.** When a section's review-mode check below
skips its specialist — in `lean` as well as `solo` — print that section's note
with the mode it ran in, e.g. "`creative-director` not consulted — Lean mode.
Review manually before production." A section drafted without its specialist
must say so in the output, whichever mode skipped it.

**每一次被跳过的生成都要公布。** 当下面某个章节的评审模式检查跳过其专家时——无论是在 `lean` 还是 `solo` 下——都要打印该章节的注释并带上所运行的模式，例如"`creative-director` not consulted — Lean mode. Review manually before production."（未咨询 `creative-director`——精简模式。生产前请人工评审。）没有其专家参与而起草的章节，必须在输出中说明这一点，无论是哪种模式跳过的。

---

### Section A: Overview
### 章节 A：Overview（概述）

**Goal**: One paragraph a stranger could read and understand.

**目标**：一段陌生人读了也能理解的文字。

**Derive recommended options before building the widget**: Read the system's category and layer from the systems index (already in context from Phase 2), then determine the recommended option for each tab:
- **Framing tab**: keyed on the `Category` column (`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`). Player-facing — `Gameplay`, `UI`, `Audio`, `Narrative` → `[C] Both` recommended. Internal — `Core`, `Persistence`, `Meta` → `[A]` recommended. Mixed — `Economy`, `Progression` → `[C] Both`. **Tiebreak, when Layer and Category disagree** (a `Foundation`-layer `Gameplay` system is the common case): **Category wins** — the framing describes what the section is *about*, and a player-facing system stays player-facing wherever it sits in the dependency graph.
- **ADR ref tab**: Glob `docs/architecture/adr-*.md` and grep for the system name in the GDD Requirements section of any ADR. If a matching ADR is found → `[A] Yes — cite the ADR` recommended. If none found → `[B] No` recommended.
- **Fantasy tab**: Foundation/Infrastructure layer → `[B] No` recommended. All other categories → `[A] Yes` recommended.

**在构建组件之前先推导推荐选项**：从系统索引中读取系统的类目和层级（第二阶段已将其放入上下文），然后确定每个标签页的推荐选项：
- **Framing 标签页**：以 `Category` 列为键（`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`）。面向玩家的——`Gameplay`、`UI`、`Audio`、`Narrative` → 推荐 `[C] Both`。内部性的——`Core`、`Persistence`、`Meta` → 推荐 `[A]`。混合型的——`Economy`、`Progression` → `[C] Both`。**当层级与类目不一致时（常见情况是 `Foundation` 层的 `Gameplay` 系统）如何取舍**：**类目优先**——取景描述的是该章节*关于*什么，而面向玩家的系统无论处在依赖图中的哪个位置都仍然是面向玩家的。
- **ADR ref 标签页**：Glob `docs/architecture/adr-*.md`，并在任何 ADR 的 GDD Requirements 章节中 grep 该系统名称。如果找到匹配的 ADR → 推荐 `[A] Yes — cite the ADR`。如果没找到 → 推荐 `[B] No`。
- **Fantasy 标签页**：Foundation/Infrastructure 层 → 推荐 `[B] No`。所有其他类目 → 推荐 `[A] Yes`。

Append `(Recommended)` to the appropriate option text in each tab.

在每个标签页的相应选项文字后追加 `(Recommended)`。

**Framing questions (ask BEFORE drafting)**: Use `AskUserQuestion` with a multi-tab widget:
- Tab "Framing" — "How should the overview frame this system?" Options: `[A] As a data/infrastructure layer (technical framing)` / `[B] Through its player-facing effect (design framing)` / `[C] Both — describe the data layer and its player impact`
- Tab "ADR ref" — "Should the overview reference the existing ADR for this system?" Options: `[A] Yes — cite the ADR for implementation details` / `[B] No — keep the GDD at pure design level`
- Tab "Fantasy" — "Does this system have a player fantasy worth stating?" Options: `[A] Yes — players feel it directly` / `[B] No — pure infrastructure, players feel what it enables`

**取景问题（在起草之前提问）**：使用带多标签页组件的 `AskUserQuestion`：
- 标签页 "Framing" —— "概述应如何为这个系统取景？" 选项：`[A] As a data/infrastructure layer (technical framing)`（作为数据/基础设施层——技术取景）/ `[B] Through its player-facing effect (design framing)`（通过其面向玩家的效果——设计取景）/ `[C] Both — describe the data layer and its player impact`（两者兼具——既描述数据层，也描述其对玩家的影响）
- 标签页 "ADR ref" —— "概述应引用该系统的现有 ADR 吗？" 选项：`[A] Yes — cite the ADR for implementation details`（是——为实现细节引用 ADR）/ `[B] No — keep the GDD at pure design level`（否——让 GDD 保持在纯设计层面）
- 标签页 "Fantasy" —— "这个系统是否有值得陈述的玩家幻想？" 选项：`[A] Yes — players feel it directly`（是——玩家直接感受到它）/ `[B] No — pure infrastructure, players feel what it enables`（否——纯基础设施，玩家感受到的是它所促成的东西）

Use the answers to shape the draft. **In `collaborative` mode, do NOT answer
these questions yourself and auto-draft** — the widget must appear. In `guided`
and `autonomous`, this is a MINOR framing decision: select the recommended
option derived above, state it in one line, and proceed (that is the whole
point of pre-deriving recommendations). Applies to every "ask BEFORE drafting"
widget in this section walk, not just this one.

用这些回答来塑造草稿。**在 `collaborative` 模式下，不要自己回答这些问题并自动起草**——组件必须出现。在 `guided` 和 `autonomous` 下，这是一个次要的取景决策：选择上面推导出的推荐选项，用一行说明，然后继续（这正是预先推导推荐选项的全部意义）。这适用于本次章节行走中每一个"在起草之前提问"的组件，不只是这一个。

**Questions to ask**:
- What is this system in one sentence?
- How does a player interact with it? (active/passive/automatic)
- Why does this system exist — what would the game lose without it?

**要问的问题**：
- 用一句话说，这个系统是什么？
- 玩家如何与它交互？（主动/被动/自动）
- 这个系统为什么存在——没有它游戏会失去什么？

**Cross-reference**: Check that the description aligns with how the systems index
describes it. Flag discrepancies.

**交叉引用**：检查描述是否与系统索引对它的描述一致。标记不一致之处。

**Design vs. implementation boundary**: Overview questions must stay at the behavior
level — what the system *does*, not *how it is built*. If implementation questions
arise during the Overview (e.g., "Should this use an Autoload singleton or a signal
bus?"), note them as "→ becomes an ADR" and move on. Implementation patterns belong
in `/architecture-decision`, not the GDD. The GDD describes behavior; the ADR
describes the technical approach used to achieve it.

**设计与实现的边界**：Overview 的问题必须停留在行为层面——系统*做什么*，而不是*它如何被构建*。如果在 Overview 过程中出现了实现问题（例如"这里应该用 Autoload 单例还是信号总线？"），把它们记为"→ 成为 ADR"然后继续。实现模式属于 `/architecture-decision`，不属于 GDD。GDD 描述行为；ADR 描述用来达成该行为的技术方案。

---

### Section B: Player Fantasy
### 章节 B：Player Fantasy（玩家幻想）

**Goal**: The emotional target — what the player should *feel*.

**目标**：情感目标——玩家应当*感受到*什么。

**Derive recommended option before building the widget**: Read the system's category and layer from Phase 2 context:
Keyed on the `Category` column (`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`):
- Player-facing — `Gameplay`, `UI`, `Audio`, `Narrative` → `[A] Direct` recommended
- Internal — `Core`, `Persistence`, `Meta` → `[B] Indirect` recommended
- Mixed — `Economy`, `Progression` → `[C] Both` recommended

**在构建组件之前先推导推荐选项**：从第二阶段的上下文中读取系统的类目和层级：
以 `Category` 列为键（`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`）：
- 面向玩家的——`Gameplay`、`UI`、`Audio`、`Narrative` → 推荐 `[A] Direct`
- 内部性的——`Core`、`Persistence`、`Meta` → 推荐 `[B] Indirect`
- 混合型的——`Economy`、`Progression` → 推荐 `[C] Both`

**When Layer and Category disagree, Category wins** — same tiebreak as the
Framing tab above.

**当层级与类目不一致时，类目优先**——与上面 Framing 标签页相同的取舍规则。

Append `(Recommended)` to the appropriate option text.

在相应的选项文字后追加 `(Recommended)`。

**Framing question (ask BEFORE drafting)**: Use `AskUserQuestion`:
- Prompt: "Is this system something the player engages with directly, or infrastructure they experience indirectly?"
- Options: `[A] Direct — player actively uses or feels this system` / `[B] Indirect — player experiences the effects, not the system` / `[C] Both — has a direct interaction layer and infrastructure beneath it`

**取景问题（在起草之前提问）**：使用 `AskUserQuestion`：
- 提示："这个系统是玩家直接接触的东西，还是他们间接体验到的基础设施？"
- 选项：`[A] Direct — player actively uses or feels this system`（直接——玩家主动使用或感受到这个系统）/ `[B] Indirect — player experiences the effects, not the system`（间接——玩家体验到的是效果，而不是系统本身）/ `[C] Both — has a direct interaction layer and infrastructure beneath it`（两者兼具——既有直接交互层，其下也有基础设施）

Use the answer to frame the Player Fantasy section appropriately. Do NOT assume the answer.

用该回答恰当地为 Player Fantasy 章节取景。不要假定答案。

**Questions to ask**:
- What emotion or power fantasy does this serve?
- What reference games nail this feeling? What specifically creates it?
- Is this a "system you love engaging with" or "infrastructure you don't notice"?

**要问的问题**：
- 它服务于什么情感或权力幻想？
- 哪些参考游戏精准地呈现了这种感受？具体是什么造就了它？
- 这是一个"你乐于与之互动的系统"，还是"你不会注意到的底层基础设施"？

**Cross-reference**: Must align with the game pillars. If the system serves a pillar,
quote the relevant pillar text.

**交叉引用**：必须与游戏支柱一致。如果该系统服务于某个支柱，引用相关的支柱文字。

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`creative-director` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**评审模式检查**（在生成之前应用）：
- `solo` → 跳过此智能体的生成。在没有该专家的情况下起草该章节。添加注释："`creative-director` not consulted — Solo mode. Review manually before production."（未咨询 `creative-director`——单人模式。生产前请人工评审。）
- `lean` → 除非该章节具有 HIGH（高）实现风险（仅章节 D 和 H），否则跳过。对于其他章节，不经该智能体直接起草。
- `full` → 按下面的描述生成。

**Agent delegation (MANDATORY)**: After the framing answer is given but before drafting,
spawn `creative-director` via `Agent`:
- Provide: system name, framing answer (direct/indirect/both), game pillars, any reference games the user mentioned, the game concept summary
- Ask: "Shape the Player Fantasy for this system. What emotion or power fantasy should it serve? What player moment should we anchor to? What tone and language fits the game's established feeling? Be specific — give me 2-3 candidate framings."
- Collect the creative-director's framings and present them to the user alongside the draft.

**智能体委派（强制）**：在给出取景回答之后、起草之前，通过 `Agent` 生成 `creative-director`：
- 提供：系统名称、取景回答（直接/间接/两者）、游戏支柱、用户提到的任何参考游戏、游戏概念摘要
- 询问："为这个系统塑造 Player Fantasy。它应服务于什么情感或权力幻想？我们应锚定在哪个玩家时刻？什么语调和语言契合游戏已确立的感觉？要具体——给我 2-3 个候选取景。"
- 收集创意总监的取景方案，并把它们与草稿一起呈现给用户。

**Do NOT draft Section B without first consulting `creative-director`.** The framing
answer tells us *what kind* of fantasy it is; the creative-director shapes *how it's
described* — tone, language, the specific player moment to anchor to.

**没有先咨询 `creative-director`，就不要起草 Section B。** 取景回答告诉我们这是*哪一种*幻想；创意总监塑造的是*它如何被描述*——语调、语言、要锚定的那个具体玩家时刻。

---

### Section C: Detailed Design (Core Rules, States, Interactions)
### 章节 C：Detailed Design（详细设计：核心规则、状态、交互）

**Goal**: Unambiguous specification a programmer could implement without questions.

**目标**：一份无歧义的规格说明，程序员无需提问即可实现。

This is usually the largest section. Break it into sub-sections:

这通常是最大的章节。把它拆成子章节：

1. **Core Rules**: The fundamental mechanics. Use numbered rules for sequential
   processes, bullets for properties.
2. **States and Transitions**: If the system has states, map every state and
   every valid transition. Use a table.
3. **Interactions with Other Systems**: For each dependency (upstream and downstream),
   specify what data flows in, what flows out, and who owns the interface.

1. **Core Rules（核心规则）**：基础机制。对顺序流程使用编号规则，对属性使用要点列表。
2. **States and Transitions（状态与转换）**：如果系统有状态，映射每一个状态和每一个有效转换。使用表格。
3. **Interactions with Other Systems（与其他系统的交互）**：对每个依赖（上游和下游），说明哪些数据流入、哪些流出，以及谁拥有该接口。

**Questions to ask**:
- Walk me through a typical use of this system, step by step
- What are the decision points the player faces?
- What can the player NOT do? (Constraints are as important as capabilities)

**要问的问题**：
- 一步步带我走一遍这个系统的一次典型使用
- 玩家面临哪些决策点？
- 玩家**不能**做什么？（约束与能力同样重要）

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note naming them: "`[the Section 6 routing table's Primary and Supporting Agents for this category]` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**评审模式检查**（在生成之前应用）：
- `solo` → 跳过此智能体的生成。在没有该专家的情况下起草该章节。添加注释并指名它们："`[the Section 6 routing table's Primary and Supporting Agents for this category]` not consulted — Solo mode. Review manually before production."（未咨询该专家——单人模式。生产前请人工评审。）
- `lean` → 除非该章节具有 HIGH（高）实现风险（仅章节 D 和 H），否则跳过。对于其他章节，不经该智能体直接起草。
- `full` → 按下面的描述生成。

**Agent delegation (MANDATORY)**: Before drafting Section C, spawn specialist agents via `Agent` in parallel:
- Look up the system category in the routing table (Section 6 of this skill)
- Spawn the Primary Agent AND Supporting Agent(s) listed for this category
- Provide each agent: system name, game concept summary, pillar set, dependency GDD excerpts, the specific section being worked on
- Collect their findings before drafting
- Surface any disagreements between agents to the user via `AskUserQuestion`
- Draft only after receiving specialist input

**智能体委派（强制）**：在起草 Section C 之前，通过 `Agent` 并行生成专家智能体：
- 在路由表（本技能第 6 节）中查找系统类目
- 生成该类目列出的主智能体**和**支持智能体
- 向每个智能体提供：系统名称、游戏概念摘要、支柱集合、依赖 GDD 摘录、正在处理的具体章节
- 在起草之前收集它们的发现
- 通过 `AskUserQuestion` 把智能体之间的任何分歧暴露给用户
- 只有在收到专家输入之后才起草

**Do NOT draft Section C without first consulting the appropriate specialists.** A `systems-designer` reviewing rules and mechanics will catch design gaps the main session cannot.

**没有先咨询相应的专家，就不要起草 Section C。** 一位 `systems-designer` 评审规则和机制时，能捕捉到主会话无法发现的设计缺口。

**Cross-reference**: For each interaction listed, verify it matches what the
dependency GDD specifies. If a dependency defines a value or formula and this
system expects something different, flag the conflict.

**交叉引用**：对列出的每一处交互，验证它与依赖 GDD 的规定一致。如果某个依赖定义了一个值或公式，而本系统期待不同的东西，标记该冲突。

---

### Section D: Formulas
### 章节 D：Formulas（公式）

**Goal**: Every mathematical formula, with variables defined, ranges specified,
and edge cases noted.

**目标**：每一个数学公式，都定义变量、指明范围并注明边界情况。

**Completion Steering — always begin each formula with this exact structure:**

**完成度引导——始终以这个确切的结构开始每个公式：**

```
The [formula_name] formula is defined as:

`[formula_name] = [expression]`

**Variables:**
| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| [name] | float/int | [min–max] | data file / calculated / constant | [what it represents] |

**Output Range:** [min] to [max] under normal play; [behaviour at extremes]
**Example:** [worked example with real numbers]
```

```
The [formula_name] formula is defined as:

`[formula_name] = [expression]`

**Variables（变量）:**
| 变量 | 类型 | 范围 | 来源 | 描述 |
|----------|------|-------|--------|-------------|
| [name] | float/int | [min–max] | data file（数据文件）/ calculated（计算得出）/ constant（常量） | [它代表什么] |

**Output Range（输出范围）:** 正常玩法下 [min] 到 [max]；[极端情况下的行为]
**Example（示例）:** [带真实数字的完整演算示例]
```

Do NOT write `[Formula TBD]` or describe a formula in prose without the variable
table. A formula without defined variables cannot be implemented without guesswork.

不要写 `[Formula TBD]`，也不要在没有变量表的情况下以散文描述公式。没有定义变量的公式无法在不猜测的情况下实现。

> **These columns match `templates/guidance/game-design-document-guide.md`
> exactly; do not rename them.** The `Source` column carries
> the coding-standards rule *"gameplay values must be data-driven (external
> config), never hardcoded"* into the design document — a variable marked
> `data file` is a tuning knob, one marked `constant` is a deliberate exception,
> and the distinction is invisible under a `Symbol` column. Put a symbol, where
> one helps, in the expression itself.

> **这些列与 `templates/guidance/game-design-document-guide.md` 完全一致；不要重命名它们。** `Source` 列把编码标准规则*"玩法数值必须数据驱动（外部配置），绝不硬编码"* 带入了设计文档——标记为 `data file` 的变量是调节旋钮，标记为 `constant` 的是一个有意为之的例外，而在 `Symbol` 列下这一区别是不可见的。在表达式本身中放置符号（在有帮助的地方）。

**Questions to ask**:
- What are the core calculations this system performs?
- Should scaling be linear, logarithmic, or stepped?
- What should the output ranges be at early/mid/late game?

**要问的问题**：
- 这个系统执行哪些核心计算？
- 缩放应该是线性、对数还是阶梯式的？
- 在游戏早期/中期/后期，输出范围应当是多少？

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**评审模式检查**（在生成之前应用）：
- `solo` → 跳过此智能体的生成。在没有该专家的情况下起草该章节。添加注释："`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → 除非该章节具有 HIGH（高）实现风险（仅章节 D 和 H），否则跳过。对于其他章节，不经该智能体直接起草。
- `full` → 按下面的描述生成。

**Agent delegation (MANDATORY)**: Before proposing any formulas or balance values, spawn specialist agents via `Agent` in parallel:
- **Always spawn `systems-designer`**: provide Core Rules from Section C, tuning goals from user, balance context from dependency GDDs. Ask them to propose formulas with variable tables and output ranges.
- **For economy/cost systems, also spawn `economy-designer`**: provide placement costs, upgrade cost intent, and progression goals. Ask them to validate cost curves and ratios.
- Present the specialists' proposals to the user for review via `AskUserQuestion`
- The user decides; the main session writes to file
- **Do NOT invent formula values or balance numbers without specialist input.** A user without balance design expertise cannot evaluate raw numbers — they need the specialists' reasoning.

**智能体委派（强制）**：在提出任何公式或平衡数值之前，通过 `Agent` 并行生成专家智能体：
- **始终生成 `systems-designer`**：提供来自 Section C 的 Core Rules、用户的调节目标、来自依赖 GDD 的平衡上下文。请他们提出带变量表和输出范围的公式。
- **对于经济/成本系统，还要生成 `economy-designer`**：提供放置成本、升级成本意图和进程目标。请他们验证成本曲线和比率。
- 通过 `AskUserQuestion` 把专家提案呈现给用户评审
- 用户做决定；主会话写入文件
- **不要在没有专家输入的情况下编造公式值或平衡数值。** 没有平衡设计专长的用户无法评估原始数字——他们需要专家的推理。

**Cross-reference**: If a dependency GDD defines a formula whose output feeds into
this system, reference it explicitly. Don't reinvent — connect.

**交叉引用**：如果某个依赖 GDD 定义的公式其输出会输入到本系统，显式引用它。不要重新发明——建立连接。

---

### Section E: Edge Cases
### 章节 E：Edge Cases（边界情况）

**Goal**: Explicitly handle unusual situations so they don't become bugs.

**目标**：显式处理异常情形，使它们不会变成 bug。

**Completion Steering — format each edge case as:**
- **If [condition]**: [exact outcome]. [rationale if non-obvious]

**完成度引导——把每个边界情况格式化为：**
- **If [条件]**：[确切结果]。[不明显时补充理由]

Example (adapt terminology to the game's domain):
- **If [resource] reaches 0 while [protective condition] is active**: hold at minimum until condition ends, then apply consequence.
- **If two [triggers/events] fire simultaneously**: resolve in [defined priority order]; ties use [defined tiebreak rule].

示例（把术语适配到游戏的领域）：
- **如果 [资源] 在 [保护条件] 生效时降到 0**：保持在最低值，直到条件结束，然后应用后果。
- **如果两个 [触发器/事件] 同时触发**：按 [已定义的优先级顺序] 解决；并列时使用 [已定义的打破平局规则]。

Do NOT write vague entries like "handle appropriately" — each must name the exact
condition and the exact resolution. An edge case without a resolution is an open
design question, not a specification.

不要写像"适当处理"这样含糊的条目——每一条都必须指名确切的条件和确切的解决方案。没有解决方案的边界情况是一个未决的设计问题，而不是规格说明。

**Questions to ask**:
- What happens at zero? At maximum? At out-of-range values?
- What happens when two rules apply at the same time?
- What happens if a player finds an unintended interaction? (Identify degenerate strategies)

**要问的问题**：
- 在零时会发生什么？在最大值时？在越界值时？
- 当两条规则同时适用时会发生什么？
- 如果玩家发现了非预期的交互会发生什么？（识别退化策略）

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**评审模式检查**（在生成之前应用）：
- `solo` → 跳过此智能体的生成。在没有该专家的情况下起草该章节。添加注释："`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → 除非该章节具有 HIGH（高）实现风险（仅章节 D 和 H），否则跳过。对于其他章节，不经该智能体直接起草。
- `full` → 按下面的描述生成。

**Agent delegation (MANDATORY)**: Spawn `systems-designer` via `Agent` before finalising edge cases. Provide: the completed Sections C and D, and ask them to identify edge cases from the formula and rule space that the main session may have missed. For narrative systems, also spawn `narrative-director`. Present their findings and ask the user which to include.

**智能体委派（强制）**：在最终确定边界情况之前，通过 `Agent` 生成 `systems-designer`。提供：已完成的 Section C 和 D，并请他们从公式和规则空间中指出主会话可能遗漏的边界情况。对于叙事系统，还要生成 `narrative-director`。呈现他们的发现并询问用户要包含哪些。

**Cross-reference**: Check edge cases against dependency GDDs. If a dependency
defines a floor, cap, or resolution rule that this system could violate, flag it.

**交叉引用**：对照依赖 GDD 检查边界情况。如果某个依赖定义了下限、上限或解决规则而本系统可能违反，标记它。

---

### Section F: Dependencies
### 章节 F：Dependencies（依赖）

**Goal**: Map every system connection with direction and nature.

**目标**：映射每一个系统连接，标明方向与性质。

This section is partially pre-filled from the context gathering phase. Present the
known dependencies from the systems index and ask:
- Are there dependencies I'm missing?
- For each dependency, what's the specific data interface?
- Which dependencies are hard (system cannot function without it) vs. soft
  (enhanced by it but works without it)?

本节已由上下文收集阶段部分预填。呈现系统索引中已知的依赖并询问：
- 有没有我遗漏的依赖？
- 对每个依赖而言，具体的数据接口是什么？
- 哪些依赖是硬依赖（没有它系统无法运作），哪些是软依赖（有它更好，但没有也能工作）？

**Cross-reference**: This section must be bidirectionally consistent. If this system
lists "depends on Combat", then the Combat GDD should list "depended on by [this
system]". Flag any one-directional dependencies for correction.

**交叉引用**：本节必须双向一致。如果本系统列出"依赖于 Combat"，那么 Combat 的 GDD 就应列出"被 [本系统] 依赖"。标记任何单向依赖以供更正。

---

### Section G: Tuning Knobs
### 章节 G：Tuning Knobs（调节旋钮）

**Goal**: Every designer-adjustable value, with safe ranges and extreme behaviors.

**目标**：每一个设计师可调节的值，附带安全范围和极端行为。

**Questions to ask**:
- What values should designers be able to tweak without code changes?
- For each knob, what breaks if it's set too high? Too low?
- Which knobs interact with each other? (Changing A makes B irrelevant)

**要问的问题**：
- 设计师应当能在不改代码的情况下调整哪些值？
- 对每个旋钮而言，设得过高会破坏什么？过低呢？
- 哪些旋钮会相互影响？（改变 A 会使 B 失去意义）

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Derive the knobs from Section D's variable table yourself. Add a note: "`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless Section D defines a formula whose knobs interact (changing one makes another inert).
- `full` → delegate as described below.

**评审模式检查**（在生成之前应用）：
- `solo` → 跳过此智能体的生成。由你自己从 Section D 的变量表推导这些旋钮。添加注释："`systems-designer` not consulted — Solo mode. Review manually before production."
- `lean` → 除非 Section D 定义了一个其旋钮会相互影响的公式（改变其中一个会使另一个失效），否则跳过。
- `full` → 按下面的描述委派。

**Agent delegation**: If formulas are complex, delegate to `systems-designer`
to derive tuning knobs from the formula variables.

**智能体委派**：如果公式复杂，委派给 `systems-designer`，从公式变量推导调节旋钮。

> This delegation names `systems-designer`, the same agent Section D's guard
> already tells a `solo` run to skip. Without the guard above, `solo` skips the
> specialist for the formulas and then consults it for the knobs derived from
> those same formulas.

> 这个委派指向 `systems-designer`，而 Section D 的守卫已经告诉 `solo` 运行跳过同一个智能体。如果没有上面的守卫，`solo` 会为公式跳过该专家，然后又为从同一批公式推导出的旋钮去咨询它。

**Cross-reference**: If a dependency GDD lists tuning knobs that affect this system,
reference them here. Don't create duplicate knobs — point to the source of truth.

**交叉引用**：如果某个依赖 GDD 列出了影响本系统的调节旋钮，在此引用它们。不要创建重复的旋钮——指向事实来源。

---

### Section H: Acceptance Criteria
### 章节 H：Acceptance Criteria（验收标准）

**Goal**: Testable conditions that prove the system works as designed.

**目标**：可测试的条件，用以证明系统按设计运作。

**Completion Steering — format each criterion as Given-When-Then:**
- **GIVEN** [initial state], **WHEN** [action or trigger], **THEN** [measurable outcome]

**完成度引导——把每条标准格式化为 Given-When-Then：**
- **GIVEN** [初始状态]，**WHEN** [动作或触发器]，**THEN** [可测量的结果]

Example (adapt terminology to the game's domain):
- **GIVEN** [initial state], **WHEN** [player action or system trigger], **THEN** [specific measurable outcome].
- **GIVEN** [a constraint is active], **WHEN** [player attempts an action], **THEN** [feedback shown and action result].

示例（把术语适配到游戏的领域）：
- **GIVEN** [初始状态]，**WHEN** [玩家动作或系统触发器]，**THEN** [具体可测量的结果]。
- **GIVEN** [某个约束生效]，**WHEN** [玩家尝试某个动作]，**THEN** [显示的反馈和动作结果]。

Include at least: one criterion per core rule from Section C, and one per formula
from Section D. Do NOT write "the system works as designed" — every criterion must
be independently verifiable by a QA tester without reading the GDD.

至少包含：Section C 中每条核心规则一条标准，Section D 中每个公式一条标准。不要写"系统按设计运作"——每条标准都必须能被 QA 测试者在不阅读 GDD 的情况下独立验证。

> **When Section D was not authored** (Formulas optional at this tier because the
> system defines no numeric rule), there are no formulas to cover and the
> criteria come from Section C alone — say so in one line rather than silently
> writing fewer criteria. **If Section D was skipped but Section C states a
> quantity** — a rate, threshold, cost or curve — that is the §1 test being met
> after the fact: stop, tell the user Formulas is required for this system, and
> author it before finalising the criteria. A criterion cannot verify a number
> the GDD never defines.
>
> **That escalation applies at `standard` only.** It re-runs §1's *conditional*
> Formulas test, and §1 disables that conditional at `minimal` outright — *"the
> conditional Formulas rule does NOT re-apply at minimal"*. At `minimal` a
> Section C quantity is expected and does **not** pull Formulas back in: state
> the value inline in Core Rules so it stays implementable, and move on. At
> `full`, Section D is unconditionally required, so the case cannot arise. Read
> without this scope, the two rules contradict each other for any `minimal`
> system that defines a rate — which is most of them.

> **当 Section D 未撰写时**（因为系统不定义数值规则，Formulas 在此层级是可选的），就没有公式需要覆盖，标准只来自 Section C——用一行说明这一点，而不是悄无声息地写更少的标准。**如果 Section D 被跳过，但 Section C 陈述了一个数量**——一个比率、阈值、成本或曲线——那正是事后满足了 §1 的判定：停止，告诉用户本系统需要 Formulas，并在最终确定标准之前撰写它。一条标准无法验证 GDD 从未定义的数字。
>
> **这一升级仅在 `standard` 下适用。** 它重新运行 §1 的*条件性* Formulas 判定，而 §1 在 `minimal` 下直接禁用了该条件——*"条件性 Formulas 规则在 minimal 下不会重新适用"*。在 `minimal` 下，Section C 出现数量是预期之中的，并且**不会**把 Formulas 拉回来：在 Core Rules 中内联陈述该值，使其保持可实现，然后继续。在 `full` 下，Section D 无条件必需，因此这种情况不可能出现。若不结合这一适用范围来阅读，这两条规则对任何定义了比率的 `minimal` 系统（也就是大多数）会互相矛盾。

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`qa-lead` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this is a section with HIGH implementation risk (Sections D and H only). For other sections, draft without the agent.
- `full` → spawn as described below.

**评审模式检查**（在生成之前应用）：
- `solo` → 跳过此智能体的生成。在没有该专家的情况下起草该章节。添加注释："`qa-lead` not consulted — Solo mode. Review manually before production."
- `lean` → 除非该章节具有 HIGH（高）实现风险（仅章节 D 和 H），否则跳过。对于其他章节，不经该智能体直接起草。
- `full` → 按下面的描述生成。

**Agent delegation (MANDATORY)**: Spawn `qa-lead` via `Agent` before finalising acceptance criteria. Provide: the completed GDD sections C, D, E, and ask them to validate that the criteria are independently testable and cover all core rules and formulas. Surface any gaps or untestable criteria to the user.

**智能体委派（强制）**：在最终确定验收标准之前，通过 `Agent` 生成 `qa-lead`。提供：已完成的 GDD 章节 C、D、E，并请他们验证这些标准可独立测试、并覆盖所有核心规则和公式。把任何缺口或不可测试的标准暴露给用户。

**Questions to ask**:
- What's the minimum set of tests that prove this works?
- What performance budget does this system get? (frame time, memory)
- What would a QA tester check first?

**要问的问题**：
- 能证明它可行的最小测试集合是什么？
- 这个系统获得多少性能预算？（帧时间、内存）
- QA 测试者会首先检查什么？

**Cross-reference**: Include criteria that verify cross-system interactions work,
not just this system in isolation.

**交叉引用**：包含验证跨系统交互正常工作的标准，而不仅仅是孤立地验证本系统。

---

### Optional Sections: Visual/Audio, Game Feel, UI Requirements, Cross-References, Open Questions
### 可选章节：Visual/Audio（视觉/音频）、Game Feel（游戏手感）、UI Requirements（UI 需求）、Cross-References（交叉引用）、Open Questions（未决问题）

These five are the template sections that are **not** among §1's eight. They are
governed here, not by the tier: §1's per-tier lists decide the *required* set,
and this block decides the rest independently. Adding a section here therefore
never changes a tier's section count.

这五个是模板章节中**不属于** §1 那八个的章节。它们在这里管辖，而不是由层级管辖：§1 的各层级清单决定*必需*集合，而这个块独立地决定其余部分。因此在此添加一个章节，永远不会改变某个层级的章节数。

Visual/Audio and Game Feel are **REQUIRED** for some categories — not optional.
Determine the requirement level before asking:

对某些类目而言，Visual/Audio 和 Game Feel 是**必需的**——不是可选的。在询问之前先确定要求级别：

**Keyed on the `Category` column of `systems-index.md`** — the nine values
`templates/systems-index.md` defines. Every one of the nine appears below
exactly once, so nothing falls through:

**以 `systems-index.md` 的 `Category` 列为键**——即 `templates/systems-index.md` 定义的九个值。九个中的每一个在下面都恰好出现一次，因此不会有遗漏：

**Visual/Audio is REQUIRED (mandatory — do not offer to skip) for:**
- `Gameplay` — combat, AI, stealth, movement, interaction: everything the player
  sees resolve
- `UI` — HUD, menus, inventory screens, dialogue UI
- `Narrative` — dialogue, quests, cutscenes, lore delivery
- `Audio` — by definition

**Visual/Audio 对以下类目是必需的（强制——不要提供跳过选项）：**
- `Gameplay` —— 战斗、AI、潜行、移动、交互：一切玩家看到其落地的内容
- `UI` —— HUD、菜单、背包界面、对话 UI
- `Narrative` —— 对话、任务、过场动画、世界观传达
- `Audio` —— 按定义

> **`Gameplay` belongs in this list.** It is the category `/map-systems` assigns
> to combat, AI and movement — the largest bucket in most action games.

> **`Gameplay` 属于这个清单。** 它是 `/map-systems` 分配给战斗、AI 和移动的类目——在大多数动作游戏中是最大的那一桶。

For required systems: **spawn `art-director` via `Agent`** before drafting this section. Provide: system name, game concept, game pillars, art bible sections 1–4 if they exist. Ask them to specify: (1) VFX and visual feedback requirements for this system's events, (2) any animation or visual style constraints, (3) which art bible principles most directly apply to this system. Present their output; do NOT leave this section as `[To be designed]` for visual systems.

对于必需的系统：在起草本节之前**通过 `Agent` 生成 `art-director`**。提供：系统名称、游戏概念、游戏支柱，以及美术圣经第 1–4 节（如果存在）。请他们明确：(1) 本系统各事件的 VFX 和视觉反馈需求，(2) 任何动画或视觉风格约束，(3) 哪些美术圣经原则最直接适用于本系统。呈现他们的输出；对于视觉系统，不要把本节留作 `[To be designed]`。

**Review mode check** (apply before spawning):
- `solo` → skip this agent spawn. Draft the section without the specialist. Add a note: "`art-director` not consulted — Solo mode. Review manually before production."
- `lean` → skip unless this system's visual feedback is central to it (a `Gameplay` or `UI` system whose events the player reads to play). Otherwise draft without the agent.
- `full` → spawn as described above.

**评审模式检查**（在生成之前应用）：
- `solo` → 跳过此智能体的生成。在没有该专家的情况下起草该章节。添加注释："`art-director` not consulted — Solo mode. Review manually before production."
- `lean` → 除非本系统的视觉反馈对其至关重要（即玩家需要读取其事件来游玩的 `Gameplay` 或 `UI` 系统），否则跳过。否则不经该智能体直接起草。
- `full` → 按上面的描述生成。

> This block applies even though the spawn above is worded as mandatory (*"do
> NOT leave this section as `[To be designed]`"*). `director-gates.md`'s *"solo
> → no director gates anywhere"* governs director **gates**, not specialist
> spawns, so it does not settle this spawn — this block does.

> 即使上面的生成被表述为强制（*"不要把本节留作 `[To be designed]`"*），这个块依然适用。`director-gates.md` 的*"solo → 任何地方都不设总监门禁"* 管辖的是总监**门禁**，而不是专家生成，因此它并不决定这次生成——由本块决定。

**Game Feel is REQUIRED (mandatory — do not offer to skip) for `Gameplay` and
`UI`** — the categories whose systems the player directly operates, where
responsiveness, weight and snap are design targets rather than polish. It is
optional for the other seven. The template's guide argues the point itself: feel *"drives
animation budgets, input handling architecture, and hitbox timing. Retrofitting
feel targets after implementation is expensive."*

**Game Feel 对 `Gameplay` 和 `UI` 是必需的（强制——不要提供跳过选项）**——这些类目的系统由玩家直接操作，其中响应性、重量感和干脆感是设计目标而非打磨。对其他七个类目则是可选的。模板指南本身就论证了这一点：手感*"驱动动画预算、输入处理架构和判定框时序。在实现之后再改造手感目标是昂贵的。"*

**Cross-References is REQUIRED whenever the Dependencies section names another
GDD.** The rule is derived, not category-keyed: if this document references
another system's mechanic, value or rule anywhere, that reference belongs in the
table. Where Dependencies names nothing, write *"None — this system references no
other GDD"* rather than leaving the placeholder. `/review-all-gdds` Phase 2c
reads this table when it exists.

**只要 Dependencies 章节提到了另一个 GDD，Cross-References 就是必需的。** 这条规则是推导出来的，而非以类目为键：如果本文件在任何地方引用了另一个系统的机制、值或规则，该引用就应出现在表中。当 Dependencies 什么都没提时，写 *"None — this system references no other GDD"*（无——本系统不引用其他 GDD），而不是留下占位符。`/review-all-gdds` 的 Phase 2c 会在该表存在时读取它。

For the remaining five categories — `Core`, `Progression`, `Economy`,
`Persistence`, `Meta` — Visual/Audio is optional: offer the optional sections
after the required sections.

对于其余五个类目——`Core`、`Progression`、`Economy`、`Persistence`、`Meta`——Visual/Audio 是可选的：在必需章节之后提供这些可选章节。

> **At `minimal`, force nothing.** §1 says a voluntary `minimal` GDD is *"exactly
> the 5 standard sections"*, which contradicts a category rule that makes
> Visual/Audio or Game Feel mandatory. §1 wins: at `minimal` both drop to
> optional and the whole set goes through the widget below.

> **在 `minimal` 下，什么都不强制。** §1 说自愿撰写的 `minimal` GDD 是*"恰好那 5 个标准章节"*，这与使 Visual/Audio 或 Game Feel 成为必需的类目规则相矛盾。§1 优先：在 `minimal` 下两者都降为可选，整套内容都通过下面的组件处理。

Use `AskUserQuestion`:
- "The required sections for this workflow tier are complete. Which of the
  remaining template sections do you want to define?"
  - Options: "All of them", "Just Cross-References and open questions", "Skip — I'll add these later"
  - List in the question only the ones still outstanding: Visual/Audio, Game
    Feel, UI Requirements, Cross-References, Open Questions **minus** any this
    system's category or dependencies already made mandatory above. Offering to
    skip a section the rules just made required is how a mandatory section gets
    skipped.
  - **Recommended option**: "All of them" when the system has any dependency,
    UI surface or player-facing feedback; "Just Cross-References and open
    questions" otherwise. `autonomous` needs a marked recommendation to pick:
    without one an unattended run has nothing to choose by and skips.

使用 `AskUserQuestion`：
- "此工作流层级的必需章节已完成。你还想定义剩余模板章节中的哪些？"
  - 选项："All of them"（全部）、"Just Cross-References and open questions"（只要交叉引用和未决问题）、"Skip — I'll add these later"（跳过——我稍后添加）
  - 在问题中只列出仍然待定的那些：Visual/Audio、Game Feel、UI Requirements、Cross-References、Open Questions，**减去**本系统类目或依赖在上文已使其成为必需的任何项。提供跳过某个规则刚刚设为必需的章节的选项，正是必需章节被跳过的方式。
  - **推荐选项**：当系统有任何依赖、UI 表面或面向玩家的反馈时，选"All of them"；否则选"Just Cross-References and open questions"。`autonomous` 需要一个已标记的推荐项才能选择：没有它，无人值守的运行就无从选择，于是跳过。

  Do **not** state a section count here. The required set is tier-dependent
  (§1: 8 at `full`, 5 + conditional Formulas at `standard`, 5 at a voluntary
  `minimal`), so a fixed "8 required sections are complete" is false on every
  run below `full` — it tells a `standard`-tier user that 8 sections exist when
  6 have been authored.

  在这里**不要**陈述章节数量。必需集合取决于层级（§1：`full` 下 8 个，`standard` 下 5 个 + 条件性 Formulas，自愿的 `minimal` 下 5 个），因此固定的"8 个必需章节已完成"在 `full` 以下的每次运行中都是错的——它会让 `standard` 层级的用户以为存在 8 个章节，而实际只撰写了 6 个。

For **Visual/Audio** (non-required systems): Coordinate with `art-director` and `audio-director` if detail is needed. Often a brief note suffices at the GDD stage.

对于 **Visual/Audio**（非必需系统）：如果需要细节，与 `art-director` 和 `audio-director` 协调。在 GDD 阶段，通常一条简短说明就足够了。

> **Asset Spec Flag**: After the Visual/Audio section is written with real content, output this notice:
> "📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:[system-name]` to produce per-asset visual descriptions, dimensions, and generation prompts from this section."

> **资源规格标志**：当 Visual/Audio 章节写入了真实内容后，输出此通知：
> "📌 **Asset Spec** —— Visual/Audio 需求已定义。在美术圣经获批之后，运行 `/asset-spec system:[system-name]`，以从本节生成每个资源的视觉描述、尺寸和生成提示词。"

For **UI Requirements**: Coordinate with `ux-designer` for complex UI systems.
After writing this section, check whether it contains real content (not just
`[To be designed]` or a note that this system has no UI). If it does have real
UI requirements, output this flag immediately:

对于 **UI Requirements**：对于复杂的 UI 系统，与 `ux-designer` 协调。写完本节后，检查它是否包含真实内容（而不只是 `[To be designed]`，或一句说明本系统没有 UI 的注释）。如果它确实有真实的 UI 需求，立即输出此标志：

> **📌 UX Flag — [System Name]**: This system has UI requirements. In Phase 4
> (Pre-Production), run `/ux-design` to create a UX spec for each screen or
> HUD element this system contributes to **before** writing epics. Stories that
> reference UI should cite `design/ux/[screen].md`, not the GDD directly.
>
> Note this in the systems index for this system if you update it.

> **📌 UX 标志 —— [System Name]**：本系统有 UI 需求。在第四阶段（预生产）中，在撰写史诗**之前**运行 `/ux-design`，为本系统所贡献的每个界面或 HUD 元素创建 UX 规格。引用 UI 的故事应引用 `design/ux/[screen].md`，而不是直接引用 GDD。
>
> 如果你会更新系统索引，请在其中为本系统注明这一点。

For **Open Questions**: Capture anything that came up during design that wasn't
fully resolved. Each question should have an owner and target resolution date.

对于 **Open Questions**：记录设计过程中出现但未完全解决的所有问题。每个问题都应有负责人和目标的解决日期。

---
