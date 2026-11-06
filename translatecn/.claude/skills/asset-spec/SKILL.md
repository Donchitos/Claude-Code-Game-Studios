---
name: asset-spec
description: "Per-asset visual specs plus AI generation prompts from GDDs and character profiles. After the art bible."
argument-hint: "[system:<name> | level:<name> | character:<name>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/asset-spec/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: asset-spec
description: "基于 GDD 和角色档案的逐资产视觉规格以及 AI 生成提示词。在美术圣经之后。"
argument-hint: "[system:<name> | level:<name> | character:<name>] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/asset-spec/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation`

# Asset Spec
# 资产规格

If no argument is provided, check whether `design/assets/entity-inventory.md` exists:
- If it exists: read it, find the first entity or screen with status "Needed" but no spec file yet, and use `AskUserQuestion`:
  - Prompt: "The next unspecced item is **[name]**. Generate specs for it?"
  - Options: `[A] Yes — spec [name]` / `[B] Pick a different item` / `[C] Stop here`
- If no entity inventory: check `design/assets/asset-manifest.md`. If manifest exists, same flow above but reading from manifest.
- If neither exists: **start the Entity & Screen Inventory flow** (Phase 0b below) rather than failing.

如果未提供参数，检查 `design/assets/entity-inventory.md` 是否存在：
- 如果存在：读取它，找到第一个状态为 "Needed" 但尚无规格文件的实体或屏幕，并使用 `AskUserQuestion`：
  - 提示：“下一个未制定规格的条目是 **[name]**。为它生成规格吗？”
  - 选项：`[A] Yes — spec [name]` / `[B] Pick a different item` / `[C] Stop here`
- 如果没有实体清单：检查 `design/assets/asset-manifest.md`。如果清单存在，流程同上，但从清单读取。
- 如果两者都不存在：**启动物体与屏幕清单流程**（下方阶段 0b），而不是失败。

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). **Note**: actually invoking an external image
generator (calling an image API) always prompts regardless of
`modes.automation` — it is an irreversible external action guarded
unconditionally, independent of whether `external_calls` is listed in
`automation_always_ask`. (Today this skill only emits generation-prompt
*text*; the guard applies if live generation is ever wired in.)

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`（协作模式总是询问 · 引导模式仅重大问题 · 自主模式记录并继续；`automation_always_ask` 类别总是提示）。**注意**：实际调用外部图像生成器（调用图像 API）无论 `modes.automation` 如何总是提示——它是无条件守护的不可逆外部行为，与 `automation_always_ask` 中是否列出 `external_calls` 无关。（当前此技能仅发出生成提示*文本*；如果将来接入实时生成，该守护适用。）

## Phase 0b: Entity & Screen Inventory (runs when no arguments and no existing inventory)
## 阶段 0b：实体与屏幕清单（在无参数且无现有清单时运行）

This flow produces `design/assets/entity-inventory.md` — the master list of everything
the game needs visually. Run once before asset spec work begins.

此流程产出 `design/assets/entity-inventory.md`——游戏在视觉上所需一切的主列表。在资产规格工作开始前运行一次。

### Step 1 — Gather from docs
### 步骤 1——从文档收集
Read all available source material in parallel, each doc by section: find the
headings you need with the Grep tool (pattern `^#`, content mode) and Read those
ranges with offset and limit.
- `design/gdd/systems-index.md` — extract every system listed
- GDD asset content — do **not** full-read every GDD. The two wanted sections are
  standard headings, and named entities live in the registry:
  ```
  Grep pattern="## (Visual/Audio Requirements|UI Requirements)" glob="design/gdd/*.md" output_mode="content" -A 25
  ```
  For named entities (characters, enemies, buildings, items), read
  `design/registry/entities.yaml` (`entities`/`items`) if it exists and has
  entries; otherwise grep the GDDs for named content. Full-read a GDD only when
  its Visual/Audio section is missing or reads `[To be designed]` (Phase 1 already
  handles that case). VFX events surface in the Visual/Audio grep context.
- `design/art/art-bible.md` — extract: any named visual categories, asset type expectations
- `design/narrative/` — scan for any character or world entity documents if they exist (optional — not required)

并行读取所有可用源材料，每份文档按章节读取：用 Grep 工具（模式 `^#`，内容模式）查找所需标题，并用 offset 和 limit 读取那些范围。
- `design/gdd/systems-index.md`——提取列出的每个系统
- GDD 资产内容——**不要**完整读取每个 GDD。两个所需章节是标准标题，命名实体位于注册表中：
  ```
  Grep pattern="## (Visual/Audio Requirements|UI Requirements)" glob="design/gdd/*.md" output_mode="content" -A 25
  ```
  对于命名实体（角色、敌人、建筑、物品），如果 `design/registry/entities.yaml`（`entities`/`items`）存在且有条目则读取它；否则在 GDD 中 grep 命名内容。仅当某 GDD 的 Visual/Audio 章节缺失或读作 `[To be designed]` 时才完整读取它（阶段 1 已处理该情况）。VFX 事件会出现在 Visual/Audio grep 上下文中。
- `design/art/art-bible.md`——提取：任何命名视觉类别、资产类型预期
- `design/narrative/`——扫描任何角色或世界实体文档（如存在）（可选——非必需）

### Step 2 — Build proposed inventory
### 步骤 2——构建建议清单
Organize everything found into categories:

```
Characters / Protagonists
Enemies / Creatures
Buildings / Structures
Environment / Terrain
Items / Props
VFX / Particles
UI Screens (list each screen by name)
HUD Elements
Audio (SFX, music — descriptions only, no generation prompts)
Other
```

将所有发现的内容组织到类别中：

```
Characters / Protagonists
Enemies / Creatures
Buildings / Structures
Environment / Terrain
Items / Props
VFX / Particles
UI Screens (list each screen by name)
HUD Elements
Audio (SFX, music — descriptions only, no generation prompts)
Other
```

For each item, note the source doc it was found in.

对于每个条目，注明它被发现于哪份源文档。

### Step 3 — Present and collaborate
### 步骤 3——呈现并协作
Present the full proposed inventory to the user in conversation. Then use `AskUserQuestion`:
- Prompt: "I found **[N] visual entities and [N] UI screens** across your GDDs and art bible. Review the list — what's missing, what's not needed?"
- Options:
  - `[A] Looks good — save this inventory`
  - `[B] Add items I'll describe`
  - `[C] Remove items that don't apply`
  - `[D] Both add and remove — let me edit`

在对话中向用户呈现完整的建议清单。然后使用 `AskUserQuestion`：
- 提示：“我在你的 GDD 和美术圣经中发现了 **[N] 个视觉实体和 [N] 个 UI 屏幕**。评审列表——缺了什么，什么不需要？”
- 选项：
  - `[A] Looks good — save this inventory`
  - `[B] Add items I'll describe`
  - `[C] Remove items that don't apply`
  - `[D] Both add and remove — let me edit`

If [B] or [D]: ask the user to describe additional items. Accept brief descriptions ("a medieval keep, used as a level background") or detailed ones — either works. Work through them collaboratively until the user is satisfied.

如果 [B] 或 [D]：请用户描述额外条目。接受简短描述（“a medieval keep, used as a level background”）或详细描述——都可以。协作处理直到用户满意。

If [C] or [D]: ask which items to remove and why. Remove them from the list.

如果 [C] 或 [D]：询问要移除哪些条目以及为什么。从列表中移除它们。

### Step 4 — Write inventory
### 步骤 4——写入清单
After user approval, ask: "May I write the entity inventory to `design/assets/entity-inventory.md`?"

在用户批准后，询问：“我可以将实体清单写入 `design/assets/entity-inventory.md` 吗？”

Write the file:

写入文件：

```markdown
# Visual Entity & Screen Inventory

> Generated: [date]
> Sources: [list of source docs read]

## Entities

| # | Name | Type | Description | Source | Status |
|---|------|------|-------------|--------|--------|
| 1 | [name] | Character / Enemy / Building / Environment / Item / Other | [brief description] | [source doc] | Needed |

## UI Screens

| # | Screen Name | Description | Source | Status |
|---|-------------|-------------|--------|--------|
| 1 | Main Menu | [description] | [source] | Needed |

## HUD Elements

| # | Element | Description | Source | Status |
|---|---------|-------------|--------|--------|

## Audio

| # | Name | Type (SFX / Music / Ambient) | Description | Source | Status |
|---|------|------------------------------|-------------|--------|--------|
```

```markdown
# 视觉实体与屏幕清单

> 生成于：[date]
> 来源：[list of source docs read]

## 实体

| # | 名称 | 类型 | 描述 | 来源 | 状态 |
|---|------|------|-------------|--------|--------|
| 1 | [name] | Character / Enemy / Building / Environment / Item / Other | [brief description] | [source doc] | Needed |

## UI 屏幕

| # | 屏幕名称 | 描述 | 来源 | 状态 |
|---|-------------|-------------|--------|--------|
| 1 | Main Menu | [description] | [source] | Needed |

## HUD 元素

| # | 元素 | 描述 | 来源 | 状态 |
|---|---------|-------------|--------|--------|

## 音频

| # | 名称 | 类型（SFX / Music / Ambient） | 描述 | 来源 | 状态 |
|---|------|------------------------------|-------------|--------|--------|
```

After writing, tell the user:
> "Entity inventory saved. Next steps:
> - Run `/ux-design [screen name]` for each UI screen in the inventory
> - Run `/asset-spec system:[name]`, `level:[name]` or `character:[name]` for each
>   visual entity — whichever of the three the entity belongs to
> - Or run `/asset-spec` again to work through the inventory one item at a time"

写入后，告诉用户：
> “实体清单已保存。后续步骤：
> - 为清单中的每个 UI 屏幕运行 `/ux-design [screen name]`
> - 为每个视觉实体运行 `/asset-spec system:[name]`、`level:[name]` 或 `character:[name]`——取决于该实体属于三者中的哪一个
> - 或者再次运行 `/asset-spec`，一次一个条目地处理清单”

---

## Phase 0: Parse Arguments
## 阶段 0：解析参数

Extract:
- **Target type**: `system`, `level`, or `character`
- **Target name**: the name after the colon (normalize to kebab-case)
- **Review mode**: `--review [full|lean|solo]` if present

提取：
- **目标类型**：`system`、`level` 或 `character`
- **目标名称**：冒号后的名称（规范化为 kebab-case）
- **评审模式**：`--review [full|lean|solo]`（如存在）

The effective mode is the one already resolved at the top of this skill via
`resolve_config --keys review_mode`, which applies the full chain; with nothing
set it follows `modes.rigor` — `solo` at `minimal` (the default), `lean` at
`standard`, `full` at `full`. A `--review` argument overrides it for this
run only.

有效模式是本技能顶部已通过 `resolve_config --keys review_mode` 解析的那个，它应用完整链条；未设置时它遵循 `modes.rigor`——`minimal`（默认）下为 `solo`，`standard` 下为 `lean`，`full` 下为 `full`。`--review` 参数仅覆盖本次运行。

**Mode behavior:**
- `full`: spawn both `art-director` and `technical-artist` in parallel
- `lean`: spawn `art-director` only — faster, skips technical constraint pass
- `solo`: no agent spawning — main session writes specs from art bible rules alone. Use for simple asset categories or when speed matters more than depth.

**模式行为：**
- `full`：并行生成 `art-director` 和 `technical-artist`
- `lean`：仅生成 `art-director`——更快，跳过技术约束流程
- `solo`：不生成智能体——主会话仅根据美术圣经规则编写规格。用于简单资产类别，或速度比深度更重要时。

---

## Phase 1: Gather Context
## 阶段 1：收集上下文

Read all source material **before** asking the user anything. Read the art bible and
the GDD by section: find the headings you need with the Grep tool (pattern `^#`,
content mode) and Read those ranges with offset and limit.

在询问用户任何内容**之前**读取所有源材料。按章节读取美术圣经和 GDD：用 Grep 工具（模式 `^#`，内容模式）查找所需标题，并用 offset 和 limit 读取那些范围。

### Required reads:
### 必需读取：
- **Art bible**: Read `design/art/art-bible.md` — fail if missing:
  > "No art bible found. Run `/art-bible` first — asset specs are anchored to the art bible's visual rules and asset standards."

  **Exception — the minimal path.** If there is no art bible but
  `design/game-brief.md` exists (at `rigor: minimal` no art bible is required),
  do not fail: anchor the specs in the brief's **Art & audio direction** line,
  and say so at the top of the output — "Anchored to the brief's one-line art
  direction; there is no art bible, so colour, shape and asset-standard rules
  below are proposals, not constraints." Offer `/art-bible` once, as optional.
  The written spec follows the same anchor: its header reads
  `> **Art direction**: design/game-brief.md (Art & audio direction) — no art bible`
  in place of the `> **Art Bible**:` line, each asset carries
  `**Brief anchor:** [the brief line applied]` in place of the **Art Bible
  Anchors** block, and no spec cites an Art Bible section or §8 tier.
  Extract: Visual Identity Statement, Color System (semantic colors), Shape Language, Asset Standards (art bible Section 8 — dimensions, formats, polycount budgets, texture resolution tiers).

- **Art bible**：读取 `design/art/art-bible.md`——缺失则失败：
  > “未找到美术圣经。先运行 `/art-bible`——资产规格锚定于美术圣经的视觉规则和资产标准。”

  **例外——最小路径。** 如果没有美术圣经但 `design/game-brief.md` 存在（在 `rigor: minimal` 下不要求美术圣经），不要失败：将规格锚定在简报的 **Art & audio direction** 行，并在输出顶部说明——“锚定于简报的一行美术方向；没有美术圣经，因此下方的颜色、形状和资产标准规则是提案，而非约束。”提供一次 `/art-bible`，作为可选。写入的规格遵循相同锚点：其头部以 `> **Art direction**: design/game-brief.md (Art & audio direction) — no art bible` 代替 `> **Art Bible**:` 行，每个资产以 `**Brief anchor:** [the brief line applied]` 代替 **Art Bible Anchors** 块，且没有规格引用 Art Bible 章节或 §8 层级。
  提取：视觉身份声明、色彩系统（语义颜色）、形状语言、资产标准（美术圣经第 8 节——尺寸、格式、多边形预算、纹理分辨率层级）。

- **Project config**: Read `performance.*` and `naming.*` from `project.yaml`; for any key absent or empty (including when `project.yaml` has no `performance` or `naming` block), fall back to `.claude/docs/technical-preferences.md`. Extract performance budgets and naming conventions.

- **项目配置**：从 `project.yaml` 读取 `performance.*` 和 `naming.*`；对于任何缺失或为空的键（包括 `project.yaml` 没有 `performance` 或 `naming` 块时），回退到 `.claude/docs/technical-preferences.md`。提取性能预算和命名约定。

### Source doc reads (by target type):
### 源文档读取（按目标类型）：
- **system**: Read `design/gdd/[target-name].md`. Extract the **Visual/Audio Requirements** section. If it doesn't exist or reads `[To be designed]`:
  > "The Visual/Audio section of `design/gdd/[target-name].md` is empty. Either run `/design-system [target-name]` to complete the GDD, or describe the visual needs manually."
  Use `AskUserQuestion`: `[A] Describe needs manually` / `[B] Stop — complete the GDD first`
- **level**: Read `design/levels/[target-name].md`. Extract art requirements, asset list, VFX needs, and the art-director's production concept specs from Step 4.
- **character** or **entity**: Read `design/narrative/characters/[target-name].md` or search `design/narrative/` and `design/assets/entity-inventory.md` for a matching entry. Extract visual description, role, and any specified distinguishing features.
  - **If no source doc exists**: do not fail. Instead, use `AskUserQuestion`:
    - Prompt: "No profile found for **[name]**. Describe it briefly — a sentence or two is enough."
    - Options: `[A] Describe it now` / `[B] Skip this entity` / `[C] Stop here`
    - If [A]: the user's description becomes the source. Brief answers produce concise specs; detailed answers produce detailed specs. Accept whatever level of detail the user provides and work from it.

- **system**：读取 `design/gdd/[target-name].md`。提取 **Visual/Audio Requirements** 章节。如果它不存在或读作 `[To be designed]`：
  > “`design/gdd/[target-name].md` 的 Visual/Audio 章节为空。要么运行 `/design-system [target-name]` 完成 GDD，要么手动描述视觉需求。”
  使用 `AskUserQuestion`：`[A] Describe needs manually` / `[B] Stop — complete the GDD first`
- **level**：读取 `design/levels/[target-name].md`。提取美术需求、资产列表、VFX 需求，以及步骤 4 中 art-director 的制作概念规格。
- **character** 或 **entity**：读取 `design/narrative/characters/[target-name].md`，或在 `design/narrative/` 和 `design/assets/entity-inventory.md` 中搜索匹配条目。提取视觉描述、角色以及任何指定的显著特征。
  - **如果没有源文档**：不要失败。改为使用 `AskUserQuestion`：
    - 提示：“未找到 **[name]** 的档案。简要描述它——一两句话就够了。”
    - 选项：`[A] Describe it now` / `[B] Skip this entity` / `[C] Stop here`
    - 如果是 [A]：用户的描述成为来源。简短回答产生简洁规格；详细回答产生详细规格。接受用户提供的任何细节程度并据此工作。

### Optional reads:
### 可选读取：
- **This target's existing spec**: if `design/assets/specs/[target-name]-assets.md` exists, read it — this is a re-run, and Phase 2 proposes only what is new or changed since (Phase 5 updates the file in place).
- **Existing manifest**: Read `design/assets/asset-manifest.md` if it exists — extract already-specced assets for this target to avoid duplicates.
- **Related specs**: Glob `design/assets/specs/*.md` — scan for assets that could be shared (e.g., a common UI element specced for one system might apply here too).

- **此目标的现有规格**：如果 `design/assets/specs/[target-name]-assets.md` 存在，读取它——这是重新运行，阶段 2 仅提议此后新增或更改的内容（阶段 5 就地更新文件）。
- **现有清单**：如果 `design/assets/asset-manifest.md` 存在，读取它——提取此目标已制定规格的资产以避免重复。
- **相关规格**：Glob `design/assets/specs/*.md`——扫描可共享的资产（例如，为一个系统制定规格的常见 UI 元素也可能适用于此）。

### Present context summary:
> **Asset Spec: [Target Type] — [Target Name]**
> - Source doc: [path] — [N] asset types identified
> - Art bible: found — Asset Standards at Section 8
> - Existing specs for this target: [N already specced / none]
> - Shared assets found in other specs: [list or "none"]

### 呈现上下文摘要：
> **资产规格：[Target Type]——[Target Name]**
> - 源文档：[path]——识别出 [N] 种资产类型
> - 美术圣经：已找到——资产标准位于第 8 节
> - 此目标的现有规格：[N already specced / none]
> - 在其他规格中发现的共享资产：[list or "none"]

---

## Phase 2: Asset Identification
## 阶段 2：资产识别

From the source doc, extract every asset type mentioned — explicit and implied.

从源文档中提取提到的每种资产类型——显式和隐含的。

**For systems**: look for VFX events, sprite references, UI elements, audio triggers, particle effects, icon needs, and any "visual feedback" language.

**对于系统**：查找 VFX 事件、精灵引用、UI 元素、音频触发器、粒子效果、图标需求，以及任何“视觉反馈”措辞。

**For levels**: look for unique environment props, atmospheric VFX, lighting setups, ambient audio, skybox/background, and any area-specific materials.

**对于关卡**：查找独特环境道具、大气 VFX、光照设置、环境音频、天空盒/背景，以及任何区域特定材质。

**For characters**: look for sprite sheets (idle, walk, attack, death), portrait/avatar, VFX attached to abilities, UI representation (icon, health bar skin).

**对于角色**：查找精灵表（待机、行走、攻击、死亡）、肖像/头像、附加到能力的 VFX、UI 表示（图标、血条皮肤）。

Group assets into categories:
- **Sprite / 2D Art** — character sprites, UI icons, tile sheets
- **VFX / Particles** — hit effects, ambient particles, screen effects
- **Environment** — props, tiles, backgrounds, skyboxes
- **UI** — HUD elements, menu art, fonts (if custom)
- **Audio** — SFX, music tracks, ambient loops *(note: audio specs are descriptions only — no generation prompts)*
- **3D Assets** — meshes, materials (if applicable per engine)

将资产归入类别：
- **Sprite / 2D Art**——角色精灵、UI 图标、图块表
- **VFX / Particles**——命中效果、环境粒子、屏幕效果
- **Environment**——道具、图块、背景、天空盒
- **UI**——HUD 元素、菜单美术、字体（如果是自定义的）
- **Audio**——SFX、音乐曲目、环境循环 *(注意：音频规格仅为描述——没有生成提示)*
- **3D Assets**——网格、材质（如果引擎适用）

Present the full identified list to the user. Use `AskUserQuestion`:
- Prompt: "I identified [N] assets across [N] categories for **[target]**. Review before speccing:"
- Show the grouped list in conversation text first
- Options: `[A] Proceed — spec all of these` / `[B] Remove some assets` / `[C] Add assets I didn't catch` / `[D] Adjust categories`

向用户呈现完整的已识别列表。使用 `AskUserQuestion`：
- 提示：“我为 **[target]** 在 [N] 个类别中识别出 [N] 个资产。在制定规格前评审：”
- 先在对话文本中展示分组列表
- 选项：`[A] Proceed — spec all of these` / `[B] Remove some assets` / `[C] Add assets I didn't catch` / `[D] Adjust categories`

Do NOT proceed to Phase 3 without user confirmation of the asset list.

在用户确认资产列表之前，不要进入阶段 3。

---

## Phase 3: Spec Generation
## 阶段 3：规格生成

Spawn specialist agents based on review mode. **Issue all `Agent` calls simultaneously — do not wait for one before starting the next.**

根据评审模式生成专家智能体。**同时发出所有 `Agent` 调用——不要在开始下一个之前等待一个。**

### Full mode — spawn in parallel:
### 完整模式——并行生成：

**`art-director`** via `Agent`:
- Provide: full asset list from Phase 2, art bible Visual Identity Statement, Color System, Shape Language, the source doc's visual requirements, and any reference games/art mentioned in the art bible Section 9
- Ask: "For each asset in this list, produce: (1) a 2–3 sentence visual description anchored to the art bible's shape language and color system — be specific enough that two different artists would produce consistent results; (2) a generation prompt ready for use with AI image tools (Midjourney/Stable Diffusion style — include style keywords, composition, color palette anchors, negative prompts); (3) which art bible rules directly govern this asset (cite by section). For audio assets, describe the sonic character instead of a generation prompt."

**`art-director`** 通过 `Agent`：
- 提供：阶段 2 的完整资产列表、美术圣经视觉身份声明、色彩系统、形状语言、源文档的视觉需求，以及美术圣经第 9 节提到的任何参考游戏/美术
- 询问：“对于此列表中的每个资产，产出：(1) 锚定于美术圣经形状语言和色彩系统的 2–3 句视觉描述——要足够具体，使两个不同美术师产出结果一致；(2) 可直接用于 AI 图像工具的生成提示（Midjourney/Stable Diffusion 风格——包括风格关键词、构图、色彩调色板锚点、负面提示）；(3) 哪些美术圣经规则直接管辖此资产（按章节引用）。对于音频资产，描述声音特征而不是生成提示。”

**`technical-artist`** via `Agent`:
- Provide: full asset list, art bible Asset Standards (Section 8), performance budgets (`performance.*` from `project.yaml`, else `technical-preferences.md`), engine name and version
- Ask: "For each asset in this list, specify: (1) exact dimensions or polycount (match the art bible Asset Standards tiers — do not invent new sizes); (2) file format and export settings; (3) naming convention (`naming.*` from `project.yaml`, else `technical-preferences.md`); (4) any engine-specific constraints this asset type must respect; (5) LOD requirements if applicable. Flag any asset type where the art bible's preferred standard conflicts with the engine's constraints."

**`technical-artist`** 通过 `Agent`：
- 提供：完整资产列表、美术圣经资产标准（第 8 节）、性能预算（`project.yaml` 中的 `performance.*`，否则 `technical-preferences.md`）、引擎名称和版本
- 询问：“对于此列表中的每个资产，指定：(1) 精确尺寸或多边形数（匹配美术圣经资产标准层级——不要发明新尺寸）；(2) 文件格式和导出设置；(3) 命名约定（`project.yaml` 中的 `naming.*`，否则 `technical-preferences.md`）；(4) 此资产类型必须遵守的任何引擎特定约束；(5) 如适用，LOD 要求。标记任何美术圣经首选标准与引擎约束冲突的资产类型。”

### Lean mode — spawn art-director only (skip technical-artist).
### Lean 模式——仅生成 art-director（跳过 technical-artist）。

### Solo mode — skip both. Derive specs from art bible rules alone, noting that technical constraints were not validated.
### Solo 模式——两者都跳过。仅根据美术圣经规则推导规格，并注明技术约束未经验证。

**Announce every skipped agent by name in the output**, before the specs:
"technical-artist skipped — Lean mode: technical constraints not validated." /
"art-director and technical-artist skipped — Solo mode: specs derived in this
session; technical constraints not validated." A spec drafted without an agent
must not read like one an agent reviewed.

**在输出中按名称宣布每个被跳过的智能体**，置于规格之前：
"technical-artist skipped — Lean mode: technical constraints not validated." /
"art-director and technical-artist skipped — Solo mode: specs derived in this session; technical constraints not validated." 没有智能体起草的规格，绝不能读起来像经过智能体评审的规格。

**Collect both responses before Phase 4.** If any conflict exists between art-director and technical-artist (e.g., art-director specifies 4K textures but technical-artist flags the engine budget requires 512px), surface it explicitly — do NOT silently resolve.

**在阶段 4 之前收集两个响应。** 如果 art-director 和 technical-artist 之间存在任何冲突（例如，art-director 指定 4K 纹理但 technical-artist 标记引擎预算要求 512px），明确呈现它——不要静默解决。

---

## Phase 4: Compile and Review
## 阶段 4：编译与评审

Combine the agent outputs into a draft spec per asset. Present all specs in conversation text using this format:

将智能体输出合并为每个资产的草拟规格。使用此格式在对话文本中呈现所有规格：

```
## ASSET-[NNN] — [Asset Name]

| Field | Value |
|-------|-------|
| Category | [Sprite / VFX / Environment / UI / Audio / 3D] |
| Dimensions | [e.g. 256×256px, 4-frame sprite sheet] |
| Format | [PNG / SVG / WAV / etc.] |
| Naming | [e.g. vfx_frost_hit_01.png] |
| Polycount | [if 3D — e.g. <800 tris] |
| Texture Res | [e.g. 512px — matches Art Bible §8 Tier 2] |

**Visual Description:**
[2–3 sentences. Specific enough for two artists to produce consistent results.]

**Art Bible Anchors:**
- §3 Shape Language: [relevant rule applied]
- §4 Color System: [color role — e.g. "uses Threat Blue per semantic color rules"]

**Generation Prompt:**
[Ready-to-use prompt. Include: style keywords, composition notes, color palette anchors, lighting direction, negative prompts.]

**Status:** Needed
```

```
## ASSET-[NNN] — [Asset Name]

| 字段 | 值 |
|-------|-------|
| 类别 | [Sprite / VFX / Environment / UI / Audio / 3D] |
| 尺寸 | [e.g. 256×256px, 4-frame sprite sheet] |
| 格式 | [PNG / SVG / WAV / etc.] |
| 命名 | [e.g. vfx_frost_hit_01.png] |
| 多边形数 | [if 3D — e.g. <800 tris] |
| 纹理分辨率 | [e.g. 512px — matches Art Bible §8 Tier 2] |

**视觉描述：**
[2–3 sentences. Specific enough for two artists to produce consistent results.]

**美术圣经锚点：**
- §3 形状语言：[relevant rule applied]
- §4 色彩系统：[color role — e.g. "uses Threat Blue per semantic color rules"]

**生成提示：**
[Ready-to-use prompt. Include: style keywords, composition notes, color palette anchors, lighting direction, negative prompts.]

**状态：** Needed
```

After presenting all specs, use `AskUserQuestion`:
- Prompt: "Asset specs for **[target]** — [N] assets. Review complete?"
- Options: `[A] Approve all — write to file` / `[B] Revise a specific asset` / `[C] Regenerate with different direction`

在呈现所有规格后，使用 `AskUserQuestion`：
- 提示：“**[target]** 的资产规格——[N] 个资产。评审完成？”
- 选项：`[A] Approve all — write to file` / `[B] Revise a specific asset` / `[C] Regenerate with different direction`

If [B]: ask which asset and what to change. Revise inline and re-present. Do NOT re-spawn agents for minor text revisions — only re-spawn if the visual direction itself needs to change.

如果 [B]：询问哪个资产以及要更改什么。内联修订并重新呈现。不要为次要文本修订重新生成智能体——仅当视觉方向本身需要更改时才重新生成。

If [C]: ask what direction to change. Re-spawn the relevant agent with the updated brief.

如果 [C]：询问要更改什么方向。用更新的简报重新生成相关智能体。

---

## Phase 5: Write Spec File
## 阶段 5：写入规格文件

After approval, ask: "May I write the spec to `design/assets/specs/[target-name]-assets.md`?"

在批准后，询问：“我可以将规格写入 `design/assets/specs/[target-name]-assets.md` 吗？”

**If that file already exists** (a re-run for the same target), update it in
place — never overwrite it wholesale. Keep its existing `ASSET-NNN` blocks and
IDs, apply only the changes the user approved, and append new assets with the
next project-wide IDs. Show what changes, then ask "May I update
`design/assets/specs/[target-name]-assets.md`?" instead of "May I write".

**如果该文件已存在**（同一目标的重新运行），就地更新它——绝不要整体覆盖。保留其现有 `ASSET-NNN` 块和 ID，仅应用用户批准的更改，并用下一个项目范围 ID 追加新资产。展示更改内容，然后询问“我可以更新 `design/assets/specs/[target-name]-assets.md` 吗？”而不是“我可以写入吗”。

Write the file with:

用以下内容写入文件：

```markdown
# Asset Specs — [Target Type]: [Target Name]

> **Source**: [path to source GDD/level/character doc]
> **Art Bible**: design/art/art-bible.md
> **Generated**: [date]
> **Status**: [N] assets specced / [N] approved / [N] in production / [N] done

[all asset specs in ASSET-NNN format]
```

```markdown
# 资产规格——[Target Type]：[Target Name]

> **来源**：[path to source GDD/level/character doc]
> **美术圣经**：design/art/art-bible.md
> **生成于**：[date]
> **状态**：[N] assets specced / [N] approved / [N] in production / [N] done

[all asset specs in ASSET-NNN format]
```

Then update `design/assets/asset-manifest.md`. If it doesn't exist, create it:

然后更新 `design/assets/asset-manifest.md`。如果它不存在，创建它：

```markdown
# Asset Manifest

> Last updated: [date]

## Progress Summary

| Total | Needed | In Progress | Done | Approved |
|-------|--------|-------------|------|----------|
| [N] | [N] | [N] | [N] | [N] |

## Assets by Context

### [Target Type]: [Target Name]
| Asset ID | Name | Category | Status | Spec File |
|----------|------|----------|--------|-----------|
| ASSET-001 | [name] | [category] | Needed | design/assets/specs/[target]-assets.md |
```

```markdown
# 资产清单

> 最后更新：[date]

## 进度摘要

| 总数 | 需要 | 进行中 | 完成 | 已批准 |
|-------|--------|-------------|------|----------|
| [N] | [N] | [N] | [N] | [N] |

## 按上下文划分的资产

### [Target Type]: [Target Name]
| 资产 ID | 名称 | 类别 | 状态 | 规格文件 |
|----------|------|----------|--------|-----------|
| ASSET-001 | [name] | [category] | Needed | design/assets/specs/[target]-assets.md |
```

If the manifest already exists, append the new context block — on a re-run for this target, add the new rows to its existing block instead of appending a second one — and update the Progress Summary counts.

如果清单已存在，追加新的上下文块——对于此目标的重新运行，将新行添加到其现有块，而不是追加第二个——并更新进度摘要计数。

Ask: "May I update `design/assets/asset-manifest.md`?"

询问：“我可以更新 `design/assets/asset-manifest.md` 吗？”

---

## Phase 6: Close
## 阶段 6：结束

Use `AskUserQuestion`:
- Prompt: "Asset specs complete for **[target]**. What's next?"
- Options:
  - `[A] Spec another system — /asset-spec system:[next-system]`
  - `[B] Spec a level — /asset-spec level:[level-name]`
  - `[C] Spec a character — /asset-spec character:[character-name]`
  - `[D] Run /asset-audit — validate delivered assets against specs`
  - `[E] Stop here`

使用 `AskUserQuestion`：
- 提示：“**[target]** 的资产规格完成。下一步是什么？”
- 选项：
  - `[A] Spec another system — /asset-spec system:[next-system]`
  - `[B] Spec a level — /asset-spec level:[level-name]`
  - `[C] Spec a character — /asset-spec character:[character-name]`
  - `[D] Run /asset-audit — validate delivered assets against specs`
  - `[E] Stop here`

---

## Asset ID Assignment
## 资产 ID 分配

Asset IDs are assigned sequentially across the entire project — not per-context. Read the manifest before assigning IDs to find the current highest number:

资产 ID 在整个项目范围内顺序分配——不是按上下文。在分配 ID 前读取清单以找到当前最高编号：

```
Grep pattern="ASSET-" path="design/assets/asset-manifest.md"
```

Start new assets from `ASSET-[highest + 1]`. This ensures IDs are stable and unique across the whole project.

从 `ASSET-[highest + 1]` 开始新资产。这确保 ID 在整个项目中稳定且唯一。

If no manifest exists yet, start from `ASSET-001`.

如果尚无清单，从 `ASSET-001` 开始。

---

## Shared Asset Protocol
## 共享资产协议

Before speccing an asset, check if an equivalent already exists in another context's spec:

在制定资产规格之前，检查另一上下文的规格中是否已存在等效项：

- Common UI elements (health bars, score displays) are often shared across systems
- Generic environment props may appear in multiple levels
- Character VFX (hit sparks, death effects) may reuse a base spec with color variants

- 常见 UI 元素（血条、分数显示）通常跨系统共享
- 通用环境道具可能出现在多个关卡中
- 角色 VFX（命中火花、死亡效果）可能复用基础规格并带颜色变体

If a match is found: reference the existing ASSET-ID rather than creating a duplicate. Note the shared usage in the manifest's referenced-by column.

如果找到匹配：引用现有 ASSET-ID，而不是创建重复项。在清单的 referenced-by 列中注明共享使用。

> "ASSET-012 (Generic Hit Spark) already specced for Combat system. Reusing for Tower Defense — adding tower-defense to referenced-by."

> “ASSET-012 (Generic Hit Spark) 已为 Combat 系统制定规格。为 Tower Defense 复用——将 tower-defense 添加到 referenced-by。”

---

## Error Recovery Protocol
## 错误恢复协议

If any spawned agent returns BLOCKED or cannot complete:

如果任何生成的智能体返回 BLOCKED 或无法完成：

1. Surface immediately: "[AgentName]: BLOCKED — [reason]"
2. In `lean` mode or if `technical-artist` blocks: proceed with art-director output only — note that technical constraints were not validated
3. In `solo` mode or if `art-director` blocks: derive descriptions from art bible rules — flag as "Art director not consulted — verify against art bible before production"
4. Always produce a partial spec — never discard work because one agent blocked

1. 立即呈现：“[AgentName]: BLOCKED — [reason]”
2. 在 `lean` 模式下或如果 `technical-artist` 受阻：仅以 art-director 输出继续——注明技术约束未经验证
3. 在 `solo` 模式下或如果 `art-director` 受阻：从美术圣经规则推导描述——标记为“Art director not consulted — verify against art bible before production”
4. 始终产出部分规格——绝不因为一个智能体受阻而丢弃工作

---

## Collaborative Protocol
## 协作协议

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

**适用于 `collaborative` 模式（默认）。** 对于 `guided` 和 `autonomous` 模式，参见 `.claude/docs/automation-modes.md`——以下规则描述协作模式的要求，而非通用行为。

Every phase follows: **Identify → Confirm → Generate → Review → Approve → Write**

每个阶段遵循：**识别 → 确认 → 生成 → 评审 → 批准 → 写入**

- Never spec assets without first confirming the asset list with the user
- Always anchor specs to the art bible — a spec that contradicts the art bible is wrong
- Surface all agent disagreements — do not silently pick one
- Write the spec file only after explicit approval
- Update the manifest immediately after writing the spec

- 绝不在未先与用户确认资产列表的情况下制定资产规格
- 始终将规格锚定于美术圣经——与美术圣经矛盾的规格是错误的
- 呈现所有智能体分歧——不要静默选择一方
- 仅在明确批准后写入规格文件
- 写入规格后立即更新清单

---

## Recommended Next Steps
## 建议的后续步骤

- Run `/asset-spec [next-context]` to continue speccing remaining systems, levels, or characters
- Run `/asset-audit` to validate delivered assets against the written specs and identify gaps or mismatches

- 运行 `/asset-spec [next-context]`，继续为剩余系统、关卡或角色制定规格
- 运行 `/asset-audit`，对照已写规格验证已交付资产并识别缺口或不匹配
