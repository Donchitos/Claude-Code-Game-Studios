---
name: art-bible
description: "Author the Art Bible — visual identity gating asset production. Run before /map-systems."
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/art-bible/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: art-bible
description: "编写美术圣经（Art Bible）— 以视觉识别门禁资产制作。在 /map-systems 之前运行。"
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/art-bible/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.
以上已解析 — 直接使用；`--review` 覆盖 `review_mode`。无配置块 →
使用 `.claude/docs/config-resolution.md` 中的默认值。

# Art Bible
# 美术圣经


## Phase 0: Parse Arguments and Context Check
## 阶段 0：解析参数与上下文检查


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.
完整检查模式参见 `.claude/docs/director-gates.md`。各门禁定义位于 `.claude/docs/director-gates/[gate-id].md` — 被启动的智能体读取它自己的门禁文件；不要在父会话中读取它。


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).
每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅在重大选择上询问 · 自主模式记录后继续；
`automation_always_ask` 类别总是询问）。

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = each section a bulleted list of
constraints + references; `balanced` = paragraphs explaining each visual choice
(`rigor: standard`); `thorough` = full prose including style explorations, references, and
rationale per choice. Apply it to every section you author.
**`docs.density`** — 它控制每个小节*深度*，而 `workflow`
控制存在哪些小节。`modes.rigor` 会同时设定这两者；单独设定
`docs.density` 可只改变深度：`terse`（默认，经由 `rigor: minimal`）= 每个小节是一份
约束与参考的要点列表；`balanced` = 用段落解释每个视觉选择
（`rigor: standard`）；`thorough` = 完整散文，包含风格探索、参考以及每个
选择的理由。将其应用于你编写的每个小节。

**`workflow`** (see `.claude/docs/workflow-modes.md`):
**`workflow`**（参见 `.claude/docs/workflow-modes.md`）：
- `full` — all 9 art bible sections required.
- `standard` — required only if visual asset stories exist in the project;
  sections 1–4 are the minimum when required. `workflow_overrides.art_bible_strict:
  true` forces all 9 sections regardless of tier.
- `minimal` — not required. Can still be run voluntarily.
- `full` — 需要全部 9 个美术圣经小节。
- `standard` — 仅当项目中存在视觉资产故事时才需要；
  需要时，小节 1–4 是最低要求。`workflow_overrides.art_bible_strict:
  true` 会无视 tier 强制要求全部 9 个小节。
- `minimal` — 不需要。仍可自愿运行。

Read `design/gdd/game-concept.md` — or `design/game-brief.md`, the one-page brief
that replaces it at `rigor: minimal`. Read it by section: find the headings you need
with the Grep tool (pattern `^#`, content mode) and Read those ranges with offset
and limit. If neither exists, fail with:
读取 `design/gdd/game-concept.md` — 或 `design/game-brief.md`，即在 `rigor: minimal`
时取代它的一页式简报。按小节读取：用 Grep 工具（模式 `^#`，content 模式）找到你需要的
标题，再用 offset 与 limit 读取那些范围。若两者都不存在，则以如下信息失败：
> "No game concept found. Run `/brainstorm` first — the art bible is authored after the game concept is approved."
> "未找到游戏概念。请先运行 `/brainstorm` — 美术圣经应在游戏概念获批之后编写。"

Extract from game-concept.md (from the brief: working title, pitch, "Who it's for /
what they feel" line and "Art & audio direction" line — it has no pillars, Visual
Identity Anchor or platform):
从 game-concept.md 中提取（若来自简报：工作标题、推介语、"面向谁 /
他们感受如何"一行以及"美术与音频方向"一行 — 简报没有支柱、视觉
识别锚点或平台）：
- Game title (working title)
- Core fantasy and elevator pitch
- Game pillars (all of them)
- **Visual Identity Anchor** section if present (from brainstorm Phase 4 art-director output)
- Target platform (if noted)
- 游戏标题（工作标题）
- 核心幻想与电梯推介语
- 游戏支柱（全部）
- **视觉识别锚点**小节（若存在；来自头脑风暴阶段 4 的美术总监产出）
- 目标平台（若有标注）

**Retrofit mode detection**: Glob `design/art/art-bible.md`. If the file exists,
build the status table **without reading the document** — you are about to author
only the *incomplete* sections, so loading the complete ones is loading exactly
what you will not touch:
**改造模式检测**：用 Glob 查找 `design/art/art-bible.md`。若文件存在，
则**不读取文档本身**即构建状态表 — 你即将只编写*不完整*的小节，因此加载已完整的小节
恰恰是在加载你根本不会触碰的内容：

```
Grep pattern="^## " path="design/art/art-bible.md" output_mode="content" -n
Grep pattern="\[To be designed\]|\[TBD\]|\[To be written\]|^_?TODO" path="design/art/art-bible.md" output_mode="content" -n
```

- The first grep gives the section headings and their line numbers — the gap
  between consecutive headings is that section's size.
- The second gives placeholder markers and where they fall.
- A section is **Complete** if it has substantive distance to the next heading and
  no placeholder marker inside it; **Placeholder** if a marker falls in its range;
  **Empty** if consecutive headings sit adjacent.
- Where the two greps leave a section genuinely ambiguous, read *that section's*
  line range with `Read(offset, limit)` — never the whole file.
- Build a section status table:
- 第一个 grep 给出小节标题及其行号 — 相邻标题之间的间隔就是该小节的篇幅。
- 第二个 grep 给出占位标记及其所在位置。
- 若某小节与下一个标题之间有实质距离，且其内部没有占位标记，则该小节为**完成**；
  若有标记落在其范围内，则为**占位**；若相邻标题紧挨着，则为**空**。
- 若两次 grep 仍使某小节确实存在歧义，则用 `Read(offset, limit)` 读取*该小节*的
  行范围 — 绝不要读整个文件。
- 构建小节状态表：

```
Section | Status
--------|--------
1. Visual Identity Statement | [Complete / Empty / Placeholder]
2. Mood & Atmosphere | ...
3. Shape Language | ...
4. Color System | ...
5. Character Design Direction | ...
6. Environment Design Language | ...
7. UI/HUD Visual Direction | ...
8. Asset Standards | ...
9. Reference Direction | ...
```

- Present this table to the user:
  > "Found existing art bible at `design/art/art-bible.md`. [N] sections are complete, [M] need content. I'll work on the incomplete sections only — existing content will not be touched."
- Only work on sections with Status: Empty or Placeholder. Do not re-author sections that are already complete.
- 将此表呈现给用户：
  > "在 `design/art/art-bible.md` 找到既有美术圣经。[N] 个小节已完成，[M] 个需要内容。我将只处理不完整的小节 — 既有内容不会被触碰。"
- 只处理状态为 空 或 占位 的小节。不要重新编写已完成的小节。

If the file does not exist, this is a fresh authoring session. The first
approved section creates the file from `.claude/docs/templates/art-bible.md`,
whose nine `## N. Name` headings are the ones retrofit mode reads — ask first:
"May I create `design/art/art-bible.md` from the art bible template?" Each
approved section then replaces its own `[To be designed]` line with `Edit`;
keep the headings as the template has them.
若文件不存在，则这是一次全新编写会话。第一个获批的小节会用
`.claude/docs/templates/art-bible.md` 创建文件，其九个 `## N. Name` 标题正是
改造模式会读取的标题 — 先问：
"我可以用美术圣经模板创建 `design/art/art-bible.md` 吗？" 随后每个
获批的小节用 `Edit` 替换它自己的 `[To be designed]` 行；
标题保持模板原样。

**A section's approval names its write.** Every section is approved through an
`AskUserQuestion` whose approving option is `[A] Lock this in and write it to
design/art/art-bible.md` (Section 1's full option list is below). Choosing it is
the approval to write that section; no section is written without it, fresh or
retrofit.
**小节的批准即为其写入授权。** 每个小节都通过一个 `AskUserQuestion` 获批，
其批准选项为 `[A] Lock this in and write it to
design/art/art-bible.md`（小节 1 的完整选项列表见下文）。选择它即
为写入该小节的批准；无论全新还是改造，没有它就不写入任何小节。

Extract performance budgets and the engine for asset standard constraints: read `performance.*` and `engine.name` from `project.yaml`; for any key absent or empty (including when `project.yaml` has no `performance` or `engine` block), fall back to `.claude/docs/technical-preferences.md`.
提取性能预算与引擎以用于资产标准的约束：从 `project.yaml` 读取 `performance.*`
与 `engine.name`；对于任何缺失或为空的键（包括 `project.yaml` 没有
`performance` 或 `engine` 块的情况），回退到 `.claude/docs/technical-preferences.md`。

---

## Phase 1: Framing
## 阶段 1：框定

Present the session context and ask two questions before authoring anything:
呈现会话上下文，并在编写任何内容之前提出两个问题：

Use `AskUserQuestion` with two tabs:
使用 `AskUserQuestion`，含两个标签页：
- Tab **"Scope"** — "Which sections need to be authored today?"
  Options: `Full bible — all 9 sections` / `Visual identity core (sections 1–4 only)` / `Asset standards only (section 8)` / `Resume — fill in missing sections`
- 标签页 **"Scope"** — "今天需要编写哪些小节？"
  选项：`Full bible — all 9 sections` / `Visual identity core (sections 1–4 only)` / `Asset standards only (section 8)` / `Resume — fill in missing sections`

  **Mark the option the resolved `workflow` tier actually requires as
  (Recommended), and say why** — the tier already decides this and the user
  should not have to know the tier table to answer:
  - `full` → **Full bible** — all 9 sections are required at this tier.
  - `standard` → **Visual identity core (sections 1–4 only)** — that is the
    documented minimum when an art bible is required at all. Say: "Sections 1–4
    are what `standard` requires; 5–9 are available if you want them."
  - `minimal` → no art bible is required. Say so before asking, and offer
    sections 1–4 as the useful-if-you-want-it option rather than defaulting to 9.
  - `workflow_overrides.art_bible_strict: true` → **Full bible** regardless of tier.

  This is the single biggest cost lever in this skill: every authored section
  carries a specialist spawn, so authoring 9 sections where the tier requires 4
  more than doubles the run for artifacts nothing downstream will check.
  **将已解析的 `workflow` tier 实际要求的那个选项标记为
  (Recommended)，并说明理由** — tier 已经决定了这一点，用户
  不应为了回答而必须先了解 tier 表：
  - `full` → **Full bible** — 此 tier 需要全部 9 个小节。
  - `standard` → **Visual identity core (sections 1–4 only)** — 当确实需要
    美术圣经时，这是有文档记载的最低要求。说明："`standard` 要求的正是小节 1–4；
    若你想要，5–9 也可用。"
  - `minimal` → 不需要美术圣经。在提问前说明这一点，并把
    小节 1–4 作为"想要就值得做"的选项提供，而不是默认给 9 个。
  - `workflow_overrides.art_bible_strict: true` → 无论 tier 为何都 **Full bible**。

  这是此技能中最大的成本杠杆：每个编写的小节
  都伴随一次专家启动，因此在 tier 只需 4 个时编写 9 个小节，
  会使运行量翻倍以上，而产出物在下游根本不会被检查。
- Tab **"References"** — "Do you have reference games, films, or art that define the visual direction?"
  (Free text — let the user type specific titles. Do NOT preset options here.)
- 标签页 **"References"** — "你是否有界定视觉方向的参考游戏、电影或美术作品？"
  （自由文本 — 让用户输入具体名称。此处不要预设选项。）

If the game-concept.md has a Visual Identity Anchor section, note it:
若 game-concept.md 有视觉识别锚点小节，则指出：
> "Found a visual identity anchor from brainstorm: '[anchor name] — [one-line rule]'. I'll use this as the foundation for the art bible."
> "从头脑风暴中发现视觉识别锚点：'[anchor name] — [one-line rule]'。我将以此为美术圣经的基础。"

**Author only the sections in the chosen scope.** Phases 2–4 run only the
sections inside it — for `Resume`, the Empty and Placeholder rows of the
retrofit table — and skip every other section, and any phase left with none.
Phase 6 names each section not authored this run and why.
**只编写所选范围内的章节。** 阶段 2–4 只运行其内的
小节 — 对 `Resume` 而言即改造表中的 空 与 占位 行 — 并跳过其他所有小节，
以及任何因此没有任何内容可做的阶段。阶段 6 会逐一说明本次运行未编写的小节及原因。

---

## Phase 2: Visual Identity Foundation (Sections 1–4)
## 阶段 2：视觉识别基础（小节 1–4）

These four sections define the core visual language. **All other sections flow from them.** Author and write each to file before moving to the next.
这四个小节定义核心视觉语言。**所有其他小节都由它们衍生。** 编写并写入文件后再进行下一个。

> **Spawn policy for this phase.** Section 1 is delegated on its own — it is
> foundational and the user chooses between anchor directions before anything
> else can build on it. Sections 2–4 are then delegated in **one** `art-director`
> call, not three: they are the same agent receiving the same inputs (Visual
> Identity Statement + pillars), and mood, shape and colour are interdependent —
> an art director defines them together, not in isolation. Separate calls would
> ask the agent to reason about colour without knowing the shape language it
> had just written.
>
> **This is not reduced specialist involvement** — every section is still
> authored by the specialist, which is the point `.claude/docs/effects-map.md`
> makes about art-bible delegation being mandatory. It is one call instead of
> three for the same three sections. Per-section user approval and
> write-to-file-immediately are unchanged.
> **本阶段的启动策略。** 小节 1 单独委派 — 它具有基础性，用户需要
> 在其他任何内容建立于其上之前先在各锚点方向之间做选择。随后小节 2–4 以**一次**
> `art-director` 调用委派，而非三次：它们是同一个智能体接收同一批输入
> （视觉识别声明 + 支柱），而氛围、形态与色彩相互依存 —
> 美术总监会一起定义它们，而非孤立定义。分开调用等于要求智能体
> 在不了解它刚刚写下的形态语言的情况下推理色彩。
>
> **这不是减少专家参与** — 每个小节仍由专家编写，
> 这正是 `.claude/docs/effects-map.md` 所强调的：美术圣经委派是强制性的。
> 对同样的三个小节，这是一次调用而非三次。逐小节的用户批准与
> 立即写入文件保持不变。

### Section 1: Visual Identity Statement
### 小节 1：视觉识别声明

**Goal**: A one-line visual rule plus 2–3 supporting principles that resolve visual ambiguity.
**目标**：一条一句话视觉规则，外加 2–3 条可消解视觉歧义的支撑原则。

If a visual anchor exists from game-concept.md: present it and ask:
- "Build directly from this anchor?"
- "Revise it before expanding?"
- "Start fresh with new options?"
若 game-concept.md 中存在视觉锚点：呈现它并询问：
- "直接以此锚点为基础构建？"
- "扩展之前先修订它？"
- "以新选项重新开始？"

**Agent delegation (MANDATORY)**: Spawn `art-director` via `Agent`:
- Provide: game concept (elevator pitch, core fantasy), full pillar set, platform target, any reference games/art from Phase 1 framing, the visual anchor if it exists
- Ask: "Draft a Visual Identity Statement for this game. Provide: (1) a one-line visual rule that could resolve any visual decision ambiguity, (2) 2–3 supporting visual principles, each with a one-sentence design test ('when X is ambiguous, this principle says choose Y'). Anchor all principles directly in the stated pillars — each principle must serve a specific pillar. (From a one-page brief, which has no pillars, anchor them in its pitch and "what they feel" line.)"
**智能体委派（强制）**：通过 `Agent` 启动 `art-director`：
- 提供：游戏概念（电梯推介语、核心幻想）、完整支柱集合、目标平台、阶段 1 框定中的任何参考游戏/美术作品、视觉锚点（若存在）
- 要求："为本游戏起草一份视觉识别声明。提供：(1) 一条可消解任何视觉决策歧义的一句话视觉规则；(2) 2–3 条支撑视觉原则，每条附一句设计检验（'当 X 存在歧义时，此原则主张选择 Y'）。将所有原则直接锚定在所述支柱上 — 每条原则都必须服务于某个具体支柱。（若来自一页式简报，因其没有支柱，则锚定在其推介语与'他们感受如何'一行上。）"

Present the art-director's draft to the user. Use `AskUserQuestion`:
- Options: `[A] Lock this in and write it to design/art/art-bible.md` / `[B] Revise the one-liner` / `[C] Revise a supporting principle` / `[D] Describe my own direction`
将美术总监的草稿呈现给用户。使用 `AskUserQuestion`：
- 选项：`[A] Lock this in and write it to design/art/art-bible.md` / `[B] Revise the one-liner` / `[C] Revise a supporting principle` / `[D] Describe my own direction`

Write the approved section to file immediately.
立即将获批的小节写入文件。

### Section 2: Mood & Atmosphere
### 小节 2：氛围与气氛

**Goal**: Emotional targets by game state — specific enough for a lighting artist to work from.
**目标**：按游戏状态定义的情绪目标 — 具体到灯光美术可直接据此工作。

For each major game state (e.g., exploration, combat, victory, defeat, menus — adapt to this game's states), define:
- Primary emotion/mood target
- Lighting character (time of day, color temperature, contrast level)
- Atmospheric descriptors (3–5 adjectives)
- Energy level (frenetic / measured / contemplative / etc.)
针对每个主要游戏状态（例如探索、战斗、胜利、失败、菜单 — 按本游戏的状态调整），定义：
- 主要情绪/氛围目标
- 灯光特征（时段、色温、对比度水平）
- 氛围描述词（3–5 个形容词）
- 能量水平（狂乱 / 从容 / 沉思 / 等等）

**Agent delegation for Sections 2–4 — one call, issued here.** Spawn
`art-director` via `Agent` with the locked Visual Identity Statement and pillar set,
and ask for all three sections in a single brief:
**小节 2–4 的智能体委派 — 一次调用，在此发出。** 通过 `Agent` 启动
`art-director`，传入已锁定的视觉识别声明与支柱集合，
并在同一份简报中请求全部三个小节：

1. **Mood & atmosphere** — "Define mood and atmosphere targets for each major game state in this game. Be specific — 'dark and foreboding' is not enough. Name the exact emotional target, the lighting character (warm/cool, high/low contrast, time of day direction), and at least one visual element that carries the mood. Each game state must feel visually distinct from the others."
2. **Shape language** — "Define the shape language for this game. Connect each shape principle back to the visual identity statement and a specific game pillar. Explain what these shape choices communicate to the player emotionally."
3. **Colour system** — "Design the color system for this game. Every semantic color assignment must be explained — why does this color mean danger/safety/reward in this world? Identify which color pairs might fail colorblind players and specify what backup cues are needed."
1. **氛围与气氛** — "为本游戏的每个主要游戏状态定义氛围与气氛目标。要具体 — '黑暗而凶险'还不够。指明确切的情绪目标、灯光特征（暖/冷、高/低对比、时段方向），以及至少一个承载该氛围的视觉元素。每个游戏状态都必须在视觉上与其他状态清晰可辨。"
2. **形态语言** — "为本游戏定义形态语言。将每条形态原则回溯到视觉识别声明与某个具体游戏支柱。解释这些形态选择在情绪上向玩家传达了什么。"
3. **色彩系统** — "为本游戏设计色彩系统。每一处语义色彩分配都必须解释 — 为何此颜色在这个世界中意味着危险/安全/奖励？找出哪些颜色配对可能让色盲玩家失败，并指明需要哪些备用提示。"

Require the three to be **mutually consistent** — the palette must serve the mood
targets and the shape hierarchy — and returned as three separately labelled
blocks so each can be approved and written on its own.
要求这三者**相互一致** — 调色板必须服务于氛围
目标与形态层级 — 并以三个分别标注的
区块返回，以便各自独立获批和写入。

Then present **Section 2** to the user, approve it, and write it to file
immediately before moving to Section 3. Do not present all three at once: the
batching is in the delegation, not in the review.
随后将**小节 2**呈现给用户，获批并立即写入文件，
然后再进行小节 3。不要一次呈现全部三个：
批处理发生在委派中，而不是评审中。

### Section 3: Shape Language
### 小节 3：形态语言

**Goal**: The geometric vocabulary that makes this game's world visually coherent and distinguishable.
**目标**：使本游戏世界在视觉上连贯且可区分的几何词汇。

Cover:
- Character silhouette philosophy (how readable at thumbnail size? Distinguishing trait per archetype?)
- Environment geometry (angular/curved/organic/geometric — which dominates and why?)
- UI shape grammar (does UI echo the world aesthetic, or is it a distinct HUD language?)
- Hero shapes vs. supporting shapes (what draws the eye, what recedes?)
涵盖：
- 角色剪影哲学（在缩略图尺寸下可读性如何？每个原型的区分特征？）
- 环境几何（棱角/曲线/有机/几何 — 哪一种占主导，为什么？）
- UI 形态语法（UI 是呼应世界美学，还是独立的 HUD 语言？）
- 主角形态与陪衬形态（什么吸引视线，什么后退？）

**Draft source**: the Sections 2–4 delegation issued under Section 2 — use the
shape-language block it returned. Do not spawn again.
**草稿来源**：在小节 2 下发出的 2–4 节委派 — 使用它返回的
形态语言区块。不要再次启动。

Write the approved section to file immediately.
立即将获批的小节写入文件。

### Section 4: Color System
### 小节 4：色彩系统

**Goal**: A complete, producible palette system that serves both aesthetic and communication needs.
**目标**：一套完整、可制作的调色板系统，同时服务于美学与传达需求。

Cover:
- Primary palette (5–7 colors with roles — not just hex codes, but what each color means in this world)
- Semantic color usage (what does red communicate? Gold? Blue? White? Establish the color vocabulary)
- Per-biome or per-area color temperature rules (if the game has distinct areas)
- UI palette (may differ from world palette — define the divergence explicitly)
- Colorblind safety: which semantic colors need shape/icon/sound backup
涵盖：
- 主调色板（5–7 种带角色的颜色 — 不只是十六进制代码，而是每种颜色在这个世界中意味着什么）
- 语义色彩用法（红色传达什么？金色？蓝色？白色？建立色彩词汇）
- 按生物群系或按区域的色温规则（若游戏有不同区域）
- UI 调色板（可与世界调色板不同 — 明确界定差异）
- 色盲安全：哪些语义颜色需要形态/图标/声音备用提示

**Draft source**: the Sections 2–4 delegation issued under Section 2 — use the
colour-system block it returned. Do not spawn again.
**草稿来源**：在小节 2 下发出的 2–4 节委派 — 使用它返回的
色彩系统区块。不要再次启动。

Write the approved section to file immediately.
立即将获批的小节写入文件。

---

## Phase 3: Production Guides (Sections 5–8)
## 阶段 3：制作指南（小节 5–8）

These sections translate the visual identity into concrete production rules. They should be specific enough that an outsourcing team can follow them without additional briefing.
这些小节的视觉识别转化为具体制作规则。它们应足够具体，使外包团队无需额外简报即可遵循。

### Section 5: Character Design Direction
### 小节 5：角色设计方向

**Agent delegation for Sections 5–6 — one call, issued here.** Both sections
need the **same agent with the same input** (`sections 1–4`), so a second call
would only re-send the whole visual identity. Spawn `art-director` once with
sections 1–4 and ask for both:
**小节 5–6 的智能体委派 — 一次调用，在此发出。** 两个小节
都需要**同一智能体与同一输入**（`sections 1–4`），因此第二次调用
只会在重新发送整个视觉识别。以小节 1–4 启动一次 `art-director`
并请求两者：

1. **Character design direction** — "Cover: visual archetype for the player character (if any), distinguishing feature rules per character type (how do players tell enemies/NPCs/allies apart at a glance?), expression/pose style targets (stiff/expressive/realistic/exaggerated), and LOD philosophy (how much detail is preserved at game camera distance?)."
2. **Environment design language** — "Cover: architectural style and its relationship to the world's culture/history, texture philosophy (painted vs. PBR vs. stylized — why this choice for this game?), prop density rules (sparse/dense — what drives the choice per area type?), and environmental storytelling guidelines (what visual details should tell the story without text?)."
1. **角色设计方向** — "涵盖：玩家角色的视觉原型（若有）、按角色类型的区分特征规则（玩家如何一眼分辨敌人/NPC/盟友？）、表情/姿态风格目标（僵硬/富表现力/写实/夸张），以及 LOD 哲学（在游戏镜头距离下保留多少细节？）。"
2. **环境设计语言** — "涵盖：建筑风格及其与世界文化/历史的关系、纹理哲学（手绘 vs. PBR vs. 风格化 — 为何本游戏选择此种？）、道具密度规则（稀疏/密集 — 按区域类型由什么驱动选择？），以及环境叙事准则（哪些视觉细节应无需文字即可讲述故事？）。"

Require characters and environments to be **legible against each other** — a
character silhouette must read against the environment texture density the same
brief defines. Return two separately labelled blocks.
要求角色与环境彼此**清晰可辨** — 角色剪影必须在同一
简报所定义的环境纹理密度下可读。以两个分别标注的区块返回。

Present **Section 5** first, approve, write to file, then Section 6.
先呈现**小节 5**，获批、写入文件，然后再进行小节 6。

### Section 6: Environment Design Language
### 小节 6：环境设计语言

**Draft source**: the Sections 5–6 delegation issued under Section 5 — use the
environment block it returned. Do not spawn again.
**草稿来源**：在小节 5 下发出的 5–6 节委派 — 使用它返回的
环境区块。不要再次启动。

Write the approved section to file.
将获批的小节写入文件。

### Section 7: UI/HUD Visual Direction
### 小节 7：UI/HUD 视觉方向

**Agent delegation**: Spawn in parallel:
- **`art-director`**: Visual style for UI — diegetic vs. screen-space HUD, typography direction (font personality, weight, size hierarchy), iconography style (flat/outlined/illustrated/photorealistic), animation feel for UI elements
- **`ux-designer`**: UX alignment check — does the visual direction support the interaction patterns this game requires? Flag any conflicts between art direction and readability/accessibility needs.
**智能体委派**：并行启动：
- **`art-director`**：UI 的视觉风格 — 叙事内 vs. 屏幕空间 HUD、字体方向（字体性格、字重、字号层级）、图标风格（扁平/描边/插画/照片写实）、UI 元素的动效手感
- **`ux-designer`**：UX 对齐检查 — 视觉方向是否支撑本游戏所需的交互模式？标出美术方向与可读性/可访问性需求之间的任何冲突。

Collect both. If they conflict (e.g., art-director wants elaborate diegetic UI but ux-designer flags it would reduce combat readability), surface the conflict explicitly with both positions. Do NOT silently resolve — use `AskUserQuestion` to let the user decide.
收集两者。若它们冲突（例如美术总监想要精致的叙事内 UI，但 ux-designer 指出这会降低战斗可读性），则明确呈现冲突及双方立场。**不要**悄悄解决 — 使用 `AskUserQuestion` 让用户决定。

Write the approved section to file.
将获批的小节写入文件。

### Section 8: Asset Standards
### 小节 8：资产标准

**Agent delegation**: Spawn in parallel:
- **`art-director`**: File format preferences, naming convention direction, texture resolution tiers, LOD level expectations, export settings philosophy
- **`technical-artist`**: Engine-specific hard constraints — poly count budgets per asset category, texture memory limits, material slot counts, importer constraints, anything from the performance budgets (`performance.*` in `project.yaml`, falling back to `.claude/docs/technical-preferences.md`)
**智能体委派**：并行启动：
- **`art-director`**：文件格式偏好、命名约定方向、纹理分辨率层级、LOD 层级预期、导出设置哲学
- **`technical-artist`**：引擎专属硬性约束 — 每类资产的多边形数量预算、纹理内存上限、材质槽数量、导入器约束，以及性能预算中的任何内容（`project.yaml` 中的 `performance.*`，回退到 `.claude/docs/technical-preferences.md`）

If any art preference conflicts with a technical constraint (e.g., art-director wants 4K textures but performance budget requires 2K for mobile), surface the conflict explicitly with both positions — the ideal and the constrained standard, and the tradeoff. Do NOT silently resolve it — use `AskUserQuestion` to let the user pick (options: the ideal standard, the constrained standard, or document both and let per-asset judgment apply). Ambiguity in asset standards is where production costs are born.
若任何美术偏好与技术约束冲突（例如美术总监想要 4K 纹理，但性能预算要求移动端 2K），则明确呈现冲突及双方立场 — 理想标准与受约束标准，以及权衡。**不要**悄悄解决 — 使用 `AskUserQuestion` 让用户选择（选项：理想标准、受约束标准，或两者都记录并由逐资产判断决定）。资产标准中的含糊正是制作成本的滋生之处。

Write the approved section to file.
将获批的小节写入文件。

---

## Phase 4: Reference Direction (Section 9)
## 阶段 4：参考方向（小节 9）

**Goal**: A curated reference set that is specific about what to take and what to avoid from each source.
**目标**：一组精选参考，明确每个来源该取什么、该避什么。

**Agent delegation**: Spawn `art-director` via `Agent` with the completed sections 1–8. Ask: "Compile a reference direction for this game. Provide 3–5 reference sources (games, films, art styles, or specific artists). For each: name it, specify exactly what visual element to draw from it (not 'the general aesthetic' — a specific technique, color choice, or compositional rule), and specify what to explicitly avoid or diverge from (to prevent the 'trying to copy X' reading). References should be additive — no two references should be pointing in exactly the same direction."
**智能体委派**：通过 `Agent` 启动 `art-director`，传入已完成的小节 1–8。要求："为本游戏汇编一份参考方向。提供 3–5 个参考来源（游戏、电影、美术风格或具体艺术家）。对每个来源：命名它，明确要从中汲取的具体视觉元素（不是'整体美学' — 而是具体技法、颜色选择或构图规则），并明确要避免或背离什么（以防止'试图照搬 X'的观感）。参考应是累积性的 — 不应有两个参考指向完全相同的方向。"

Write the approved section to file.
将获批的小节写入文件。

---

## Phase 5: Art Director Sign-Off
## 阶段 5：美术总监签署

**Review mode check** — apply before spawning AD-ART-BIBLE:
- `solo` → skip. Note: "AD-ART-BIBLE skipped — Solo mode." Then record the skip
  (below) and proceed to Phase 6.
- `lean` → skip (not a PHASE-GATE). Note: "AD-ART-BIBLE skipped — Lean mode."
  Then record the skip (below) and proceed to Phase 6.
- `full` → spawn as normal.
**评审模式检查** — 在启动 AD-ART-BIBLE 之前应用：
- `solo` → 跳过。注明："AD-ART-BIBLE skipped — Solo mode." 然后记录该跳过
  （见下文）并进入阶段 6。
- `lean` → 跳过（不是 PHASE-GATE）。注明："AD-ART-BIBLE skipped — Lean mode."
  然后记录该跳过（见下文）并进入阶段 6。
- `full` → 照常启动。

On either skip, ask "May I record the skipped sign-off in
`design/art/art-bible.md`'s header?" and, on yes, replace the header's
`> **Art Director Sign-Off (AD-ART-BIBLE)**: [Not yet reviewed]` with
`> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED [date] — [solo|lean] mode`
— the gate accepts either form as a recorded sign-off.
无论哪种跳过，都询问"我可以把跳过的签署记录在
`design/art/art-bible.md` 的文件头中吗？"，若答是，则将该文件头的
`> **Art Director Sign-Off (AD-ART-BIBLE)**: [Not yet reviewed]` 替换为
`> **Art Director Sign-Off (AD-ART-BIBLE)**: SKIPPED [date] — [solo|lean] mode`
— 门禁接受任一形式作为已记录的签署。

After all sections are complete (or the scoped set from Phase 1 is complete), spawn `art-director` via `Agent` using gate **AD-ART-BIBLE** (`.claude/docs/director-gates/ad-art-bible.md`).
全部小节完成之后（或阶段 1 所定范围内的集合完成之后），使用门禁 **AD-ART-BIBLE**（`.claude/docs/director-gates/ad-art-bible.md`）通过 `Agent` 启动 `art-director`。

Pass: the art bible path (`design/art/art-bible.md`); the game pillars and core
fantasy; the platform and performance constraints (`platform.*` and
`performance.*` from `project.yaml`, falling back to
`.claude/docs/technical-preferences.md`); and the visual identity anchor. When
Phase 0 read the one-page brief, pass its pitch and "what they feel" line as the
pillars and fantasy, and its "Art & audio direction" line as the anchor.
传入：美术圣经路径（`design/art/art-bible.md`）；游戏支柱与核心
幻想；平台与性能约束（`project.yaml` 中的 `platform.*` 与
`performance.*`，回退到
`.claude/docs/technical-preferences.md`）；以及视觉识别锚点。当
阶段 0 读取的是一页式简报时，传入其推介语与"他们感受如何"一行作为
支柱与幻想，并传入其"美术与音频方向"一行作为锚点。

Handle verdict per standard rules in `director-gates.md`.
按 `director-gates.md` 中的标准规则处理裁决。
On `Revise flagged items`, or to resolve a REJECT, the section's own specialist
— `art-director`, with `ux-designer` for Section 7 and `technical-artist` for
Section 8 — re-drafts each flagged section, which is then presented, approved
and written like any other section before `REVISED [date]` is recorded.
在 `Revise flagged items` 时，或为消解 REJECT，该小节自己的专家
— `art-director`，小节 7 另加 `ux-designer`，小节 8 另加
`technical-artist` — 重新起草每个被标记的小节，随后该小节与其他任何小节一样
被呈现、获批并写入，然后记录 `REVISED [date]`。
A `NOT ASSESSED` answer is never an approval: name the missing input, then
supply it and re-run the gate, or record `NOT ASSESSED`.
`NOT ASSESSED` 答复永远不是批准：指明缺失的输入，然后
补充它并重新运行门禁，或记录 `NOT ASSESSED`。
Record the verdict in the art bible's status header:
`> **Art Director Sign-Off (AD-ART-BIBLE)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`
将裁决记录在美术圣经的状态文件头中：
`> **Art Director Sign-Off (AD-ART-BIBLE)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`

---

## Phase 6: Close
## 阶段 6：收尾

First, name each of the nine sections not authored this run and why — outside
the chosen scope, or already complete — e.g. *"Not authored this run: sections
5–9 (outside the chosen scope; `standard` requires 1–4)."* A run that stopped
after Section 4 must not read like a finished bible.
首先，逐一说明九个中本次运行未编写的小节及原因 — 超出
所选范围，或已完成 — 例如*"本次运行未编写：小节
5–9（超出所选范围；`standard` 要求 1–4）。"* 在
小节 4 之后停止的运行，读起来绝不能像一份已完成的美术圣经。

Before presenting next steps, check project state:
- Does `design/gdd/systems-index.md` exist? → map-systems is done, skip that option
- Is an engine configured — `engine.name` present in `project.yaml`, or a configured Engine field (not `[TO BE CONFIGURED]`) in `.claude/docs/technical-preferences.md`? → setup-engine is done, skip that option
- Does `design/gdd/` contain any `*.md` files? → design-system has been run, skip that option
- Does `design/gdd/gdd-cross-review-*.md` exist? → review-all-gdds is done
- Do GDDs exist (check above)? → include /consistency-check option
在呈现后续步骤之前，检查项目状态：
- `design/gdd/systems-index.md` 是否存在？→ map-systems 已完成，跳过该选项
- 引擎是否已配置 — `project.yaml` 中存在 `engine.name`，或 `.claude/docs/technical-preferences.md` 中 Engine 字段已配置（不是 `[TO BE CONFIGURED]`）？→ setup-engine 已完成，跳过该选项
- `design/gdd/` 是否包含任何 `*.md` 文件？→ design-system 已运行，跳过该选项
- `design/gdd/gdd-cross-review-*.md` 是否存在？→ review-all-gdds 已完成
- GDD 是否存在（见上文检查）？→ 纳入 /consistency-check 选项

Use `AskUserQuestion` for next steps. Only include options that are genuinely next based on the state check above:
使用 `AskUserQuestion` 选择后续步骤。只纳入基于上述状态检查确实属于下一步的选项：

At `workflow: minimal`, the pool is `/create-stories` (no stories yet) or
`/dev-story [next story]`, plus Stop here — the GDD/architecture pool below is
`standard`/`full` only.
在 `workflow: minimal` 下，候选是 `/create-stories`（尚无故事）或
`/dev-story [next story]`，外加 Stop here — 下文的 GDD/架构候选池仅适用于
`standard`/`full`。

**Option pool — include only if not already done:**
- `[_] Run /map-systems — decompose the concept into systems before writing GDDs` (skip if systems-index.md exists)
- `[_] Run /setup-engine — configure the engine (asset standards may need revisiting after engine is set)` (skip if engine configured)
- `[_] Run /design-system — start the first GDD` (skip if any GDDs exist)
- `[_] Run /review-all-gdds — cross-GDD consistency check (required before Technical Setup gate)` (skip if gdd-cross-review-*.md exists)
- `[_] Run /asset-spec — generate per-asset visual specs and AI generation prompts from approved GDDs` (include if GDDs exist)
- `[_] Run /consistency-check — scan existing GDDs against the art bible for visual direction conflicts` (include if GDDs exist)
- `[_] Run /create-architecture — author the master architecture document (next Technical Setup step)`
- `[_] Stop here`
**选项池 — 仅在尚未完成时纳入：**
- `[_] Run /map-systems — decompose the concept into systems before writing GDDs`（若 systems-index.md 存在则跳过）
- `[_] Run /setup-engine — configure the engine (asset standards may need revisiting after engine is set)`（若引擎已配置则跳过）
- `[_] Run /design-system — start the first GDD`（若已有任何 GDD 则跳过）
- `[_] Run /review-all-gdds — cross-GDD consistency check (required before Technical Setup gate)`（若 gdd-cross-review-*.md 存在则跳过）
- `[_] Run /asset-spec — generate per-asset visual specs and AI generation prompts from approved GDDs`（若 GDD 存在则纳入）
- `[_] Run /consistency-check — scan existing GDDs against the art bible for visual direction conflicts`（若 GDD 存在则纳入）
- `[_] Run /create-architecture — author the master architecture document (next Technical Setup step)`
- `[_] Stop here`

Assign letters A, B, C… only to the options actually included. Mark the most logical pipeline-advancing option as `(recommended)`.
只给实际纳入的选项分配字母 A、B、C…。将最合理的推进流程选项标记为 `(recommended)`。

> **Always include** (`standard`/`full` only) `/create-architecture` and Stop here as options — these are always valid next steps once the art bible is complete.
> **始终纳入**（仅 `standard`/`full`）`/create-architecture` 与 Stop here 选项 — 美术圣经完成后，这些永远是有效的下一步。

---

## Collaborative Protocol
## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.
**适用于 `collaborative` 模式（默认）。** 对于 `guided` 与
`autonomous` 模式，参见 `.claude/docs/automation-modes.md` — 以下规则
描述的是协作模式的要求，而非通用行为。

Every section follows: **Question → Options → Decision → Draft (from art-director agent) → Approval → Write to file**
每个小节都遵循：**提问 → 选项 → 决定 → 草稿（来自 art-director 智能体）→ 批准 → 写入文件**

- Never draft a section yourself — every section's content comes from the
  relevant specialist. One delegation may cover several sections (2–4 share a
  call, as do 5–6), but no section may be written from the orchestrator's own
  judgement instead of an agent's.
- Write each section to file immediately after approval — do not batch **the
  writes or the approvals**. Batching applies only to the delegation call; the
  user still sees, approves and commits one section at a time.
- Surface all agent disagreements to the user — never silently resolve conflicts between art-director and technical-artist
- The art bible is a constraint document: it restricts future decisions in exchange for visual coherence. Every section should feel like it narrows the solution space productively.
- 绝不自己起草小节 — 每个小节的内容都来自相关专家。
  一次委派可覆盖多个小节（2–4 共用一次
  调用，5–6 亦然），但任何小节都不得以编排者自己的
  判断代替智能体的判断来写入。
- 每个小节获批后立即写入文件 — 不要批处理**写入
  或批准**。批处理只适用于委派调用；
  用户仍然一次看一个、批准一个、提交一个。
- 向用户呈现智能体间的所有分歧 — 绝不悄悄解决 art-director 与 technical-artist 之间的冲突
- 美术圣经是一份约束文档：它以限制未来决策来换取视觉连贯。每个小节都应让人感到它有效地收窄了解空间。

---

## Recommended Next Steps
## 推荐的后续步骤

After the art bible is approved:
- Run `/map-systems` to decompose the concept into game systems before authoring GDDs
- Run `/setup-engine` if the engine is not yet configured (asset standards may need revisiting after engine selection)
- Run `/design-system [first-system]` to start authoring per-system GDDs
- Run `/consistency-check` once GDDs exist to validate them against the art bible's visual rules
- Run `/create-architecture` to produce the master architecture document
美术圣经获批之后：
- 运行 `/map-systems`，在编写 GDD 之前将概念拆解为游戏系统
- 若引擎尚未配置，运行 `/setup-engine`（引擎选定后资产标准可能需要重新审视）
- 运行 `/design-system [first-system]` 开始编写各系统的 GDD
- 一旦 GDD 存在，运行 `/consistency-check`，对照美术圣经的视觉规则验证它们
- 运行 `/create-architecture` 产出主架构文档
