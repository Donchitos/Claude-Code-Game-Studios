---
name: localize
description: "Localization pipeline — find hardcoded strings, extract string tables, cultural review, VO, RTL, enforce string freeze."
argument-hint: "[scan|extract|validate|status|brief|cultural-review|vo-pipeline|rtl-check|freeze|qa]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/localize/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

---
name: localize
description: "本地化流水线 —— 查找硬编码字符串、提取字符串表、文化审查、VO、RTL、执行字符串冻结。"
argument-hint: "[scan|extract|validate|status|brief|cultural-review|vo-pipeline|rtl-check|freeze|qa]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/localize/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

# Localization Pipeline

# 本地化流水线

Localization is not just translation — it is the full process of making a game
feel native in every language and region. Poor localization breaks immersion,
confuses players, and blocks platform certification. This skill covers the
complete pipeline from string extraction through cultural review, VO recording,
RTL layout testing, and localization QA sign-off.

本地化不仅仅是翻译 —— 它是让游戏在每种语言和地区都显得原生的完整过程。糟糕的本地化会破坏沉浸感、让玩家困惑，并阻碍平台认证。本技能覆盖从字符串提取到文化审查、VO 录音、RTL 布局测试以及本地化 QA 签署的完整流水线。

**Modes:**
- `scan` — Find hardcoded strings and localization anti-patterns (read-only)
- `extract` — Extract strings and generate translation-ready tables
- `validate` — Check translations for completeness, placeholders, and length
- `status` — Coverage matrix across all locales
- `brief` — Generate translator context briefing document for an external team
- `cultural-review` — Flag culturally sensitive content, symbols, colours, idioms
- `vo-pipeline` — Manage voice-over localization: scripts, recording specs, integration
- `rtl-check` — Validate RTL language layout, mirroring, and font support
- `freeze` — Enforce string freeze; lock source strings before translation begins
- `qa` — Run the full localization QA cycle before release

**模式：**
- `scan` —— 查找硬编码字符串和本地化反模式（只读）
- `extract` —— 提取字符串并生成可翻译的表格
- `validate` —— 检查翻译的完整性、占位符和长度
- `status` —— 所有语言区域的覆盖率矩阵
- `brief` —— 为外部团队生成译者背景简报文档
- `cultural-review` —— 标记文化敏感内容、符号、颜色、习语
- `vo-pipeline` —— 管理配音本地化：脚本、录音规范、集成
- `rtl-check` —— 校验 RTL 语言布局、镜像和字体支持
- `freeze` —— 执行字符串冻结；在翻译开始前锁定源字符串
- `qa` —— 在发布前运行完整的本地化 QA 循环

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.

如果未提供子命令，输出用法并停止。结论：**FAIL** —— 缺少必需的子命令。

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式总是询问 · 引导模式仅询问重大事项 · 自主模式记录后继续；
`automation_always_ask` 类别始终会询问）。

## Phase 2A: Scan Mode

## 阶段 2A：扫描模式

Search the **code root** (resolve per `.claude/docs/code-root-resolution.md`) for hardcoded user-facing strings. **If the code root is unresolved, report `NOT ASSESSED — code root unresolved` rather than zero hits.** Zero hits from an unresolved root reads as "nothing to localize", which is the failure this guards:

在**代码根**（按 `.claude/docs/code-root-resolution.md` 解析）中搜索硬编码的面向用户的字符串。**如果代码根无法解析，报告 `NOT ASSESSED — code root unresolved`，而不是零命中。** 从未解析的根得到零命中会被读成"无需本地化"，这正是这里要防止的失败：

- String literals in UI code not wrapped in a localization function (`tr()`, `Tr()`, `NSLocalizedString`, `GetText`, etc.)
- Concatenated strings that should be parameterized
- Strings with positional placeholders (`%s`, `%d`) instead of named ones (`{playerName}`)
- Format strings that mix locale-sensitive data (numbers, dates, currencies) without locale-aware formatting

- UI 代码中未包装在本地化函数（`tr()`、`Tr()`、`NSLocalizedString`、`GetText` 等）中的字符串字面量
- 本应参数化的拼接字符串
- 使用位置占位符（`%s`、`%d`）而非具名占位符（`{playerName}`）的字符串
- 混用对区域敏感的数据（数字、日期、货币）却未做区域感知格式化的格式字符串

Search for localization anti-patterns:

搜索本地化反模式：

- Date/time formatting not using locale-aware functions
- Number formatting without locale awareness (`1,000` vs `1.000`)
- Text embedded in images or textures (flag asset files in `assets/`)
- Strings that assume left-to-right text direction (positional layout, string assembly order)
- Gender/plurality assumptions baked into string logic (must use plural forms or gender tokens)
- Hardcoded punctuation (e.g. `"You won!"` — exclamation styles vary by locale)

- 未使用区域感知函数的日期/时间格式化
- 缺乏区域感知的数字格式化（`1,000` 与 `1.000`）
- 嵌入在图像或纹理中的文字（标记 `assets/` 中的资产文件）
- 假定从左到右文本方向的字符串（位置布局、字符串组装顺序）
- 固化在字符串逻辑中的性别/复数假设（必须使用复数形式或性别标记）
- 硬编码的标点（例如 `"You won!"` —— 感叹风格因区域而异）

Report all findings with file paths and line numbers. This mode is read-only — no files are written.

报告所有发现，附上文件路径和行号。此模式为只读 —— 不写入任何文件。

---

## Phase 2B: Extract Mode

## 阶段 2B：提取模式

- Scan all source files for localized string references
- Compare against the existing string table in `assets/data/strings/`
- Generate new entries for strings not yet keyed
- Suggest key names following the convention: `[category].[subcategory].[description]`
  - Example: `ui.hud.health_label`, `dialogue.npc.merchant.greeting`, `menu.main.play_button`
- Each new entry must include a `context` field — a translator comment explaining:
  - Where it appears (which screen, which scene)
  - Maximum character length
  - Any placeholder meaning (`{playerName}` = the player's chosen display name)
  - Gender/plurality context if applicable

- 扫描所有源文件中的本地化字符串引用
- 与 `assets/data/strings/` 中现有的字符串表对比
- 为尚未建立键的字符串生成新条目
- 按约定建议键名：`[category].[subcategory].[description]`
  - 示例：`ui.hud.health_label`、`dialogue.npc.merchant.greeting`、`menu.main.play_button`
- 每个新条目必须包含 `context` 字段 —— 一段译者注释，说明：
  - 它出现在哪里（哪个界面、哪个场景）
  - 最大字符长度
  - 任何占位符的含义（`{playerName}` = 玩家选择的显示名称）
  - 适用时的性别/复数背景

Output a diff of new strings to add to the string table.

输出要添加到字符串表的新字符串 diff。

Present the diff to the user. Ask: "May I write these new entries to `assets/data/strings/strings-en.json`?"

向用户呈现该 diff。询问："我可以把这些新条目写入 `assets/data/strings/strings-en.json` 吗？"

If yes, write only the diff (new entries), not a full replacement. Verdict: **COMPLETE** — strings extracted and written.

如果同意，只写入 diff（新条目），而不是完整替换。结论：**COMPLETE** —— 字符串已提取并写入。

---

## Phase 2C: Validate Mode

## 阶段 2C：校验模式

Read all string table files in `assets/data/strings/`. For each locale, check:

读取 `assets/data/strings/` 中的所有字符串表文件。对每种语言区域检查：

- **Completeness** — key exists in source (en) but no translation for this locale
- **Placeholder mismatches** — source has `{name}` but translation omits it or adds extras
- **String length violations** — translation exceeds the character limit recorded in the source `context` field
- **Plural form count** — locale requires N plural forms; translation provides fewer
- **Orphaned keys** — translation exists but nothing in the code root references the key
- **Stale translations** — source string changed after translation was written (flag for re-translation)
- **Encoding** — non-ASCII characters present and font atlas supports them (flag if uncertain)

- **完整性** —— 键在源（en）中存在，但该语言区域没有翻译
- **占位符不匹配** —— 源中有 `{name}`，但翻译遗漏了它或增加了额外的占位符
- **字符串长度违规** —— 翻译超出了源 `context` 字段记录的长度限制
- **复数形式数量** —— 语言区域需要 N 种复数形式；翻译提供的更少
- **孤立键** —— 翻译存在，但代码根中没有任何内容引用该键
- **过时翻译** —— 源字符串在翻译写入之后发生了变化（标记为需要重新翻译）
- **编码** —— 存在非 ASCII 字符且字体图集支持它们（不确定时标记）

Report validation results grouped by locale and severity. This mode is read-only — no files are written.

按语言区域和严重程度分组报告校验结果。此模式为只读 —— 不写入任何文件。

---

## Phase 2D: Status Mode

## 阶段 2D：状态模式

- Count total localizable strings in the source table
- Per locale: count translated, untranslated, stale (source changed since translation)
- Generate a coverage matrix:

- 统计源表中可本地化字符串的总数
- 按语言区域：统计已翻译、未翻译、过时（自翻译后源已变化）的数量
- 生成覆盖率矩阵：

```markdown
## Localization Status
Generated: [Date]
String freeze: [Active / Not yet called / Lifted]

| Locale | Total | Translated | Missing | Stale | Coverage |
|--------|-------|-----------|---------|-------|----------|
| en (source) | [N] | [N] | [N] | [N] | [N]% |
| [locale] | [N] | [N] | [N] | [N] | [X]% |

> **Every cell above is a count you must take from the string table — including
> the source row.** Do not pre-fill the source locale as `100%`: that asserts a
> result before counting, and on a project with no `assets/data/strings/` it
> produces a coverage report for a table that does not exist. If the string table
> is absent, the whole status output is
> **`NOT ASSESSED — no string table found`**, not a matrix of zeros with a
> confident source row.

### Issues
- [N] hardcoded strings found in source code (run /localize scan)
- [N] strings exceeding character limits
- [N] placeholder mismatches
- [N] orphaned keys
- [N] strings added after freeze was called (freeze violations)
```

```markdown
## 本地化状态
生成时间：[Date]
字符串冻结：[Active / Not yet called / Lifted]

| 语言区域 | 总数 | 已翻译 | 缺失 | 过时 | 覆盖率 |
|--------|-------|-----------|---------|-------|----------|
| en（源） | [N] | [N] | [N] | [N] | [N]% |
| [locale] | [N] | [N] | [N] | [N] | [X]% |

> **上面每个单元格都是你必须从字符串表中取得的计数 —— 包括源语言行。**
> 不要把源语言区域预填为 `100%`：那是在计数之前就断言结果，而在一个没有
> `assets/data/strings/` 的项目上，它会为一个不存在的表生成覆盖率报告。
> 如果字符串表缺失，整个状态输出就是
> **`NOT ASSESSED — no string table found`**，而不是一个带有一行自信源数据的零矩阵。

### 问题
- 源代码中发现 [N] 个硬编码字符串（运行 /localize scan）
- [N] 个字符串超出字符限制
- [N] 个占位符不匹配
- [N] 个孤立键
- 冻结生效后新增的 [N] 个字符串（冻结违规）
```

This mode is read-only — no files are written.

此模式为只读 —— 不写入任何文件。

---

## Phase 2E: Brief Mode

## 阶段 2E：简报模式

Generate a translator context briefing document. This document is sent to the
external translation team or localisation vendor alongside the string table export.

生成一份译者背景简报文档。该文档与字符串表导出一起发送给外部翻译团队或本地化供应商。

Read:
- `design/gdd/` — extract game genre, tone, setting, character names. Read the
  GDDs by section: find the headings you need with the Grep tool (pattern `^#`,
  content mode) and Read those ranges with offset and limit.
- `assets/data/strings/strings-en.json` — the source string table
- Any existing lore or narrative documents in `design/narrative/`

读取：
- `design/gdd/` —— 提取游戏类型、基调、设定、角色名称。按小节读取 GDD：
  用 Grep 工具（模式 `^#`，内容模式）找到需要的标题，然后用 offset 和 limit 读取相应范围。
- `assets/data/strings/strings-en.json` —— 源字符串表
- `design/narrative/` 中任何现有的世界观或叙事文档

Generate `production/localization/translator-brief-[locale]-[date].md`:

生成 `production/localization/translator-brief-[locale]-[date].md`：

```markdown
# Translator Brief — [Game Name] — [Locale]

## Game Overview
[2-3 paragraph summary of the game, genre, tone, and audience]

## Tone and Voice
- **Overall tone**: [e.g., "Darkly comic, not slapstick — think Terry Pratchett, not Looney Tunes"]
- **Player address**: [e.g., "Second person, informal. Never formal 'vous' — always 'tu' for French"]
- **Profanity policy**: [e.g., "Mild — PG-13 equivalent. Match intensity to source, do not soften or escalate"]
- **Humour**: [e.g., "Wordplay exists — if a pun cannot translate, invent an equivalent local joke; do not translate literally"]

## Character Glossary
| Name | Role | Personality | Notes |
|------|------|-------------|-------|
| [Name] | [Role] | [Personality] | [Do not translate / transliterate as X] |

## World Glossary
| Term | Meaning | Notes |
|------|---------|-------|
| [Term] | [What it means] | [Keep in English / translate as X] |

## Do Not Translate List
The following must appear verbatim in all locales:
- [Game name]
- [UI terms that match in-engine labels]
- [Brand or trademark names]

## Placeholder Reference
| Placeholder | What it represents | Example |
|-------------|-------------------|---------|
| `{playerName}` | Player's chosen display name | "Shadowblade" |
| `{count}` | Integer quantity | "3" |

## Character Limits
Tight UI fields with hard limits are marked in the string table `context` field.
Where no limit is stated, target ±30% of the English length as a guideline.

## Contact
Direct questions to: [placeholder for user/team contact]
Delivery format: JSON, same schema as strings-en.json
```

```markdown
# 译者简报 —— [Game Name] —— [Locale]

## 游戏概述
[关于游戏、类型、基调和受众的 2-3 段摘要]

## 基调与语气
- **整体基调**：[例如 "黑色幽默，而非闹剧 —— 想想特里·普拉切特，而不是乐一通"]
- **玩家称呼**：[例如 "第二人称，非正式。永远不用正式的'vous' —— 法语中始终用'tu'"]
- **粗俗用语政策**：[例如 "轻度 —— 相当于 PG-13。与源文强度匹配，不要弱化或升级"]
- **幽默**：[例如 "存在文字游戏 —— 若双关无法翻译，就发明一个对等的本地笑话；不要直译"]

## 角色词汇表
| 名称 | 角色 | 性格 | 备注 |
|------|------|-------------|-------|
| [Name] | [Role] | [Personality] | [Do not translate / transliterate as X] |

## 世界词汇表
| 术语 | 含义 | 备注 |
|------|---------|-------|
| [Term] | [What it means] | [Keep in English / translate as X] |

## 禁止翻译清单
以下内容在所有语言区域中必须逐字保持不变：
- [Game name]
- [与引擎内标签一致的 UI 术语]
- [品牌或商标名称]

## 占位符参考
| 占位符 | 代表什么 | 示例 |
|-------------|-------------------|---------|
| `{playerName}` | 玩家选择的显示名称 | "Shadowblade" |
| `{count}` | 整数数量 | "3" |

## 字符限制
带硬性限制的紧凑 UI 字段在字符串表 `context` 字段中标注。
未声明限制之处，以英语长度的 ±30% 为目标作为指导。

## 联系方式
将问题发送至：[user/team contact 的占位符]
交付格式：JSON，与 strings-en.json 相同的 schema
```

Ask: "May I write this translator brief to `production/localization/translator-brief-[locale]-[date].md`?"

询问："我可以把这份译者简报写入 `production/localization/translator-brief-[locale]-[date].md` 吗？"

---

## Phase 2F: Cultural Review Mode

## 阶段 2F：文化审查模式

Spawn `localization-lead` via `Agent`. Ask them to audit the following for cultural sensitivity across the target locales (read from `assets/data/strings/` and `assets/`):

通过 `Agent` 启动 `localization-lead`。请他们针对目标语言区域审查以下内容的文化敏感性（从 `assets/data/strings/` 和 `assets/` 读取）：

### Content Areas to Review

### 需要审查的内容领域

**Symbols and gestures**
- Thumbs up, OK hand, peace sign — meanings vary by region
- Religious or spiritual symbols in art, UI, or audio
- National flags, map representations, disputed territories

**符号与手势**
- 竖大拇指、OK 手势、V 字手势 —— 含义因地区而异
- 艺术、UI 或音频中的宗教或灵性符号
- 国旗、地图表示、争议领土

**Colours**
- White (mourning in some Asian cultures), green (political associations in some regions), red (luck vs danger)
- Alert/warning colours that conflict with cultural associations

**颜色**
- 白色（在某些亚洲文化中代表哀悼）、绿色（在某些地区有政治关联）、红色（幸运与危险）
- 与文化联想冲突的警示/警告颜色

**Numbers**
- 4 (death in Japanese/Chinese), 13, 666 — flag use in UI (room numbers, item counts, prices)

**数字**
- 4（在日语/中文中代表死亡）、13、666 —— 标记其在 UI 中的使用（房间号、物品数量、价格）

**Humour and idioms**
- Idioms that translate as offensive in other locales
- Toilet/bodily humour that is inappropriate in some markets (notably Japan, Germany, Middle East)
- Dark humour around topics that are culturally sensitive in specific regions

**幽默与习语**
- 在其他语言区域会被翻译成冒犯性内容的习语
- 在某些市场（尤其是日本、德国、中东）不合适的厕所/身体幽默
- 围绕特定地区文化敏感主题的黑色幽默

**Violence and content ratings**
- Content that would require ratings changes in DE (Germany), AU (Australia), CN (China), or AE (UAE)
- Blood colour, gore level, drug references — flag all for region-specific asset variants if needed

**暴力与内容分级**
- 会导致 DE（德国）、AU（澳大利亚）、CN（中国）或 AE（阿联酋）分级变化的内容
- 血液颜色、血腥程度、毒品引用 —— 如有需要，全部标记以制作区域专用资产变体

**Names and representations**
- Character names that are offensive, profane, or carry negative meaning in target locales
- Stereotyped representation of nationalities, religions, or ethnic groups

**名称与表现**
- 在目标语言区域中具有冒犯性、粗俗或有负面含义的角色名称
- 对国籍、宗教或族群的刻板化表现

Present findings as a table:

以表格形式呈现发现：

| Finding | Locale(s) Affected | Severity | Recommended Action |
|---------|--------------------|----------|--------------------|
| [Description] | [Locale] | [BLOCKING / ADVISORY / NOTE] | [Change / Flag for review / Accept] |

| 发现 | 受影响的语言区域 | 严重程度 | 建议行动 |
|---------|--------------------|----------|--------------------|
| [Description] | [Locale] | [BLOCKING / ADVISORY / NOTE] | [Change / Flag for review / Accept] |

BLOCKING = must fix before shipping that locale. ADVISORY = recommend change. NOTE = informational only.

BLOCKING = 在该语言区域发布前必须修复。ADVISORY = 建议修改。NOTE = 仅供参考。

Ask: "May I write this cultural review report to `production/localization/cultural-review-[date].md`?"

询问："我可以把这份文化审查报告写入 `production/localization/cultural-review-[date].md` 吗？"

---

## Phase 2G: VO Pipeline Mode

## 阶段 2G：VO 流水线模式

Manage the voice-over localization process. Determine the sub-task from the argument:

管理配音本地化流程。从参数判断子任务：

- `vo-pipeline scan` — identify all dialogue lines that require VO recording
- `vo-pipeline script` — generate recording scripts with director notes
- `vo-pipeline validate` — check that all recorded VO files are present and correctly named
- `vo-pipeline integrate` — verify VO files are correctly referenced in code/assets

- `vo-pipeline scan` —— 找出所有需要 VO 录音的对话台词
- `vo-pipeline script` —— 生成带导演注释的录音脚本
- `vo-pipeline validate` —— 检查所有已录制的 VO 文件是否存在且命名正确
- `vo-pipeline integrate` —— 校验 VO 文件在代码/资产中被正确引用

### VO Pipeline: Scan

### VO 流水线：扫描

Read `assets/data/strings/` and `design/narrative/`. Identify:
- All dialogue lines (keys matching `dialogue.*`) with source text
- Lines already recorded (audio file exists in `assets/audio/vo/`)
- Lines not yet recorded

读取 `assets/data/strings/` 和 `design/narrative/`。找出：
- 所有带源文本的对话台词（键匹配 `dialogue.*`）
- 已录制的台词（音频文件存在于 `assets/audio/vo/`）
- 尚未录制的台词

Output a recording manifest:

输出录音清单：

```
## VO Recording Manifest — [Date]

| Key | Character | Source Line | Status |
|-----|-----------|-------------|--------|
| dialogue.npc.merchant.greeting | Merchant | "Welcome, traveller." | Recorded |
| dialogue.npc.merchant.haggle | Merchant | "That's my final offer." | Needs recording |
```

```
## VO Recording Manifest — [Date]

| Key | Character | Source Line | Status |
|-----|-----------|-------------|--------|
| dialogue.npc.merchant.greeting | Merchant | "Welcome, traveller." | Recorded |
| dialogue.npc.merchant.haggle | Merchant | "That's my final offer." | Needs recording |
```

```
## VO 录音清单 —— [Date]

| 键 | 角色 | 源台词 | 状态 |
|-----|-----------|-------------|--------|
| dialogue.npc.merchant.greeting | Merchant | "Welcome, traveller." | 已录制 |
| dialogue.npc.merchant.haggle | Merchant | "That's my final offer." | 需要录音 |
```

### VO Pipeline: Script

### VO 流水线：脚本

Generate a recording script document for each character, grouped by scene. Include:

为每个角色生成一份按场景分组的录音脚本文档。包括：

- Character name and brief personality note
- Full dialogue line with pronunciation guide for unusual proper nouns
- Emotion/direction note for each line (`[Warm, welcoming]`, `[Annoyed, clipped]`)
- Any lines that are responses in a conversation (provide context: "Player just said X")

- 角色名称和简短的性格说明
- 完整对话台词，并为不寻常的专有名词提供发音指南
- 每句台词的的情境/表演注释（`[Warm, welcoming]`、`[Annoyed, clipped]`）
- 任何作为对话回应的台词（提供上下文："Player just said X"）

Ask: "May I write the VO recording scripts to `production/localization/vo-scripts-[locale]-[date].md`?"

询问："我可以把 VO 录音脚本写入 `production/localization/vo-scripts-[locale]-[date].md` 吗？"

### VO Pipeline: Validate

### VO 流水线：校验

Glob `assets/audio/vo/[locale]/` for all `.wav`/`.ogg` files. Cross-reference against the VO manifest. Report:
- Missing files (line in script, no audio file)
- Extra files (audio file exists, no matching string key)
- Naming convention violations

用 Glob 查找 `assets/audio/vo/[locale]/` 中所有 `.wav`/`.ogg` 文件。与 VO 清单交叉比对。报告：
- 缺失文件（脚本中有台词，但没有音频文件）
- 多余文件（存在音频文件，但没有匹配的字符串键）
- 命名约定违规

### VO Pipeline: Integrate

### VO 流水线：集成

Grep the code root for VO audio references. Verify each referenced path exists in `assets/audio/vo/[locale]/`. Report broken references.

在代码根中 Grep 查找 VO 音频引用。校验每个引用路径都存在于 `assets/audio/vo/[locale]/` 中。报告损坏的引用。

---

## Phase 2H: RTL Check Mode

## 阶段 2H：RTL 检查模式

Right-to-left languages (Arabic, Hebrew, Persian, Urdu) require layout mirroring beyond
just translating text. This mode validates the implementation.

从右到左的语言（阿拉伯语、希伯来语、波斯语、乌尔都语）除了翻译文本之外还需要布局镜像。此模式校验实现情况。

Determine the engine: read `engine.name` from `project.yaml`; if that key is absent or empty (including when `project.yaml` has no `engine:` block), fall back to `.claude/docs/technical-preferences.md`. Then check:

确定引擎：从 `project.yaml` 读取 `engine.name`；如果该键缺失或为空（包括 `project.yaml` 没有 `engine:` 块的情况），回退到 `.claude/docs/technical-preferences.md`。然后检查：

**Layout mirroring**
- Is RTL layout enabled in the engine? (Godot: `Control.layout_direction`, Unity: `RTL Support` package, Unreal: text direction flags)
- Are all UI containers set to auto-mirror, or are positions hardcoded?
- Do progress bars, health bars, and directional indicators mirror correctly?

**布局镜像**
- 引擎中是否启用了 RTL 布局？（Godot：`Control.layout_direction`，Unity：`RTL Support` 包，Unreal：文本方向标志）
- 所有 UI 容器是否都设置为自动镜像，还是位置被硬编码？
- 进度条、生命条和方向指示器是否能正确镜像？

**Text rendering**
- Are fonts loaded that support Arabic/Hebrew character sets?
- Is Arabic text rendered with correct ligatures (connected script)?
- Are numbers displayed as Eastern Arabic numerals where required?

**文本渲染**
- 是否加载了支持阿拉伯语/希伯来语字符集的字体？
- 阿拉伯语文本是否以正确的连字（连写书写）渲染？
- 在需要时数字是否显示为东部阿拉伯数字？

**String assembly**
- Are there any string concatenations that assume left-to-right reading order?
- Do `{placeholder}` positions in sentences work correctly when sentence structure is reversed?

**字符串组装**
- 是否存在假定从左到右阅读顺序的字符串拼接？
- 当句子结构反转时，句子中的 `{placeholder}` 位置是否仍然正确？

**Asset review**
- Are there UI icons with directional arrows or asymmetric designs that need mirrored variants?
- Do any text-in-image assets exist that require RTL versions?

**资产审查**
- 是否有带方向箭头或非对称设计的 UI 图标需要镜像变体？
- 是否存在需要 RTL 版本的图内文字资产？

Grep patterns to check:
- Engine-specific RTL flags in scene/prefab files
- Any `HBoxContainer`, `LinearLayout`, `HorizontalBox` nodes — verify layout_direction settings
- String concatenation with `+` near dialogue or UI code

要检查的 Grep 模式：
- 场景/预制体文件中引擎特定的 RTL 标志
- 任何 `HBoxContainer`、`LinearLayout`、`HorizontalBox` 节点 —— 校验 layout_direction 设置
- 对话或 UI 代码附近使用 `+` 的字符串拼接

Report findings. Flag BLOCKING issues (content unreadable without fix) vs ADVISORY (cosmetic improvements).

报告发现。标记 BLOCKING 问题（不修复则内容无法阅读）与 ADVISORY（外观改进）。

Ask: "May I write this RTL check report to `production/localization/rtl-check-[date].md`?"

询问："我可以把这份 RTL 检查报告写入 `production/localization/rtl-check-[date].md` 吗？"

---

## Phase 2I: Freeze Mode

## 阶段 2I：冻结模式

String freeze locks the source (English) string table so that translations can proceed
without the source changing under the translators.

字符串冻结会锁定源（英语）字符串表，以便翻译在源不会于译者脚下发生变化的情况下推进。

### freeze call

### 冻结调用

Check current freeze status in `production/localization/freeze-status.md` (if it exists).

检查 `production/localization/freeze-status.md`（如果存在）中的当前冻结状态。

If already frozen:
> "String freeze is currently ACTIVE (called [date]). [N] strings have been added or modified since freeze. These are freeze violations — they require re-translation or an approved freeze lift."

如果已冻结：
> "字符串冻结当前为 ACTIVE（调用于 [date]）。自冻结以来已新增或修改 [N] 个字符串。这些是冻结违规 —— 它们需要重新翻译或经批准的冻结解除。"

If not frozen, present the pre-freeze checklist:

如果未冻结，呈现冻结前检查清单：

```
Pre-Freeze Checklist
[ ] All planned UI screens are implemented
[ ] All dialogue lines are final (no further narrative revisions planned)
[ ] All system strings (error messages, tutorial text) are complete
[ ] /localize scan shows zero hardcoded strings
[ ] /localize validate shows no placeholder mismatches in source (en)
[ ] Marketing strings (store description, achievements) are final
```

```
Pre-Freeze Checklist
[ ] All planned UI screens are implemented
[ ] All dialogue lines are final (no further narrative revisions planned)
[ ] All system strings (error messages, tutorial text) are complete
[ ] /localize scan shows zero hardcoded strings
[ ] /localize validate shows no placeholder mismatches in source (en)
[ ] Marketing strings (store description, achievements) are final
```

```
冻结前检查清单
[ ] 所有计划的 UI 界面都已实现
[ ] 所有对话台词均已定稿（不再计划进一步的叙事修订）
[ ] 所有系统字符串（错误信息、教程文本）均已完成
[ ] /localize scan 显示零个硬编码字符串
[ ] /localize validate 显示源（en）中无占位符不匹配
[ ] 营销字符串（商店描述、成就）已定稿
```

Use `AskUserQuestion`:
- Prompt: "Call string freeze now? This writes `production/localization/freeze-status.md` (Status: ACTIVE) and locks the source table."
- Options: `[A] Yes — call string freeze now` / `[B] No — I still have strings to add`

使用 `AskUserQuestion`：
- 提示："现在调用字符串冻结吗？这会写入 `production/localization/freeze-status.md`（Status: ACTIVE）并锁定源表。"
- 选项：`[A] 是 —— 现在调用字符串冻结` / `[B] 否 —— 我仍有字符串要添加`

If [A]: Write `production/localization/freeze-status.md`:

如果选 [A]：写入 `production/localization/freeze-status.md`：

```markdown
# String Freeze Status

**Status**: ACTIVE
**Called**: [date]
**Called by**: [user]
**Total strings at freeze**: [N]

## Post-Freeze Changes
[Any strings added or modified after freeze are listed here automatically by /localize extract]
```

```markdown
# String Freeze Status

**Status**: ACTIVE
**Called**: [date]
**Called by**: [user]
**Total strings at freeze**: [N]

## Post-Freeze Changes
[Any strings added or modified after freeze are listed here automatically by /localize extract]
```

```markdown
# 字符串冻结状态

**Status**: ACTIVE
**Called**: [date]
**Called by**: [user]
**Total strings at freeze**: [N]

## 冻结后变更
[冻结后新增或修改的任何字符串会由 /localize extract 自动列在此处]
```

### freeze lift

### 冻结解除

If argument includes `lift`: ask "May I update `freeze-status.md` to LIFTED?", then set its Status to `LIFTED` and record the reason and date. Warn: "Lifting the freeze requires re-translation of all modified strings. Notify the translation team."

如果参数包含 `lift`：询问"我可以把 `freeze-status.md` 更新为 LIFTED 吗？"，然后将其 Status 设为 `LIFTED` 并记录原因和日期。警告："解除冻结需要重新翻译所有已修改的字符串。请通知翻译团队。"

### freeze check (auto-integrated into extract)

### 冻结检查（自动集成到 extract）

When `extract` mode finds new or modified strings and `freeze-status.md` shows Status: ACTIVE — name `freeze-status.md` in extract's own "May I write" question, append the new keys to its `## Post-Freeze Changes` on approval, and warn:
> "⚠️ String freeze is active. [N] new/modified strings have been added. These are freeze violations. Notify your localization vendor before proceeding."

当 `extract` 模式发现新增或修改的字符串，且 `freeze-status.md` 显示 Status: ACTIVE —— 在 extract 自己的"我可以写入吗"问题中点明 `freeze-status.md`，批准后把新键追加到其 `## Post-Freeze Changes`，并警告：
> "⚠️ 字符串冻结已生效。已新增 [N] 个新增/修改的字符串。这些是冻结违规。在继续之前请通知你的本地化供应商。"

---

## Phase 2J: QA Mode

## 阶段 2J：QA 模式

Localization QA is a dedicated pass that runs after translations are delivered but
before any locale ships. This is not the same as `/localize validate` (which checks
completeness) — this is a structured playthrough-based quality check.

本地化 QA 是一个专门的环节，在翻译交付之后、任何语言区域发布之前运行。它不同于 `/localize validate`（后者检查完整性）—— 这是一个结构化的、基于实机游玩的质检。

Spawn `localization-lead` via `Agent` with:
- The target locale(s) to QA
- The list of all screens/flows in the game (from `design/gdd/` or `/content-audit` output)
- The current `/localize validate` report
- The cultural review report (if it exists)

通过 `Agent` 启动 `localization-lead`，并提供：
- 要 QA 的目标语言区域
- 游戏中所有界面/流程的清单（来自 `design/gdd/` 或 `/content-audit` 输出）
- 当前的 `/localize validate` 报告
- 文化审查报告（如果存在）

Ask the localization-lead to produce a QA plan covering:

请 localization-lead 制定一份 QA 计划，涵盖：

1. **Functional string check** — every string displays in-game without truncation, placeholder errors, or encoding corruption
2. **UI overflow check** — translated strings that exceed UI bounds (even if within character limits, some languages expand)
3. **Contextual accuracy** — a sample of 10% of strings reviewed in-game for translation accuracy and natural phrasing
4. **Cultural review items** — verify all BLOCKING items from the cultural review are resolved
5. **VO sync check** — if VO exists, verify lip sync or subtitle timing is acceptable after translation
6. **Platform cert requirements** — check platform-specific localization requirements (age ratings text, legal notices, ESRB/PEGI/CERO text)

1. **功能字符串检查** —— 每个字符串在游戏中显示时无截断、占位符错误或编码损坏
2. **UI 溢出检查** —— 超出 UI 边界的翻译字符串（即使符合字符限制，某些语言也会膨胀）
3. **语境准确性** —— 抽取 10% 的字符串在游戏中审查翻译准确性和自然措辞
4. **文化审查项** —— 校验文化审查中的所有 BLOCKING 项均已解决
5. **VO 同步检查** —— 如果存在 VO，校验翻译后口型同步或字幕时序可接受
6. **平台认证要求** —— 检查平台特定的本地化要求（年龄分级文本、法律声明、ESRB/PEGI/CERO 文本）

Output a QA verdict per locale:

按语言区域输出 QA 结论：

```
## Localization QA Verdict — [Locale]

**Status**: PASS / PASS WITH CONDITIONS / NOT ASSESSED / FAIL
**Reviewed by**: localization-lead
**Date**: [date]

### Findings
| ID | Area | Description | Severity | Status |
|----|------|-------------|----------|--------|
| LOC-001 | UI Overflow | "Settings" button text overflows on [Screen] | BLOCKING | Open |
| LOC-002 | Translation | [Key] translation is literal — sounds unnatural | ADVISORY | Open |

### Conditions (if PASS WITH CONDITIONS)
- [Condition 1 — must resolve before ship]

### Sign-Off
[ ] All BLOCKING findings resolved
[ ] Producer approves shipping [Locale]
```

```
## Localization QA Verdict — [Locale]

**Status**: PASS / PASS WITH CONDITIONS / NOT ASSESSED / FAIL
**Reviewed by**: localization-lead
**Date**: [date]

### Findings
| ID | Area | Description | Severity | Status |
|----|------|-------------|----------|--------|
| LOC-001 | UI Overflow | "Settings" button text overflows on [Screen] | BLOCKING | Open |
| LOC-002 | Translation | [Key] translation is literal — sounds unnatural | ADVISORY | Open |

### Conditions (if PASS WITH CONDITIONS)
- [Condition 1 — must resolve before ship]

### Sign-Off
[ ] All BLOCKING findings resolved
[ ] Producer approves shipping [Locale]
```

```
## Localization QA Verdict — [Locale]

**Status**: PASS / PASS WITH CONDITIONS / NOT ASSESSED / FAIL
**Reviewed by**: localization-lead
**Date**: [date]

### Findings
| ID | 领域 | 描述 | 严重程度 | 状态 |
|----|------|-------------|----------|--------|
| LOC-001 | UI Overflow | "Settings" 按钮文本在 [Screen] 上溢出 | BLOCKING | Open |
| LOC-002 | Translation | [Key] 的翻译过于直译 —— 听起来不自然 | ADVISORY | Open |

### 条件（若为 PASS WITH CONDITIONS）
- [条件 1 —— 必须在发布前解决]

### 签署
[ ] 所有 BLOCKING 发现均已解决
[ ] 制作人批准发布 [Locale]
```

First match wins: **FAIL** if any BLOCKING finding is open; else **NOT ASSESSED**
if a check could not run — the checks are playthrough-based, so a locale nobody
has played in-game (or whose translations were not delivered) cannot pass on the
string tables alone; name each check that did not run; else **PASS WITH
CONDITIONS** if conditions remain; else **PASS**. NOT ASSESSED outranks both
pass values — an unplayed locale has not passed — and ranks below FAIL, so an
open BLOCKING finding is never buried behind it.

首先匹配者优先：如果有任何 BLOCKING 发现未关闭，则 **FAIL**；否则如果某项检查无法运行则 **NOT ASSESSED** —— 这些检查基于实机游玩，因此一个无人实机游玩过的语言区域（或其翻译尚未交付）无法仅凭字符串表通过；要逐一说明未运行的检查；否则如果仍有条件则 **PASS WITH CONDITIONS**；否则 **PASS**。NOT ASSESSED 优先于两个通过值 —— 未游玩过的语言区域并未通过 —— 且低于 FAIL，因此未关闭的 BLOCKING 发现永远不会被它掩盖。

Ask: "May I write this localization QA report to `production/localization/loc-qa-[locale]-[date].md`?"

询问："我可以把这份本地化 QA 报告写入 `production/localization/loc-qa-[locale]-[date].md` 吗？"

**Gate integration**: At `workflow: full`, the Polish → Release gate requires a PASS or PASS WITH CONDITIONS verdict for every translated locale being shipped (recommended at `standard`; dropped at `minimal`). A FAIL blocks release for that locale only — other locales may still proceed if their QA passes. A NOT ASSESSED locale has not passed: its QA did not run.

**门禁集成**：在 `workflow: full` 下，Polish → Release 门禁要求每个将要发布的已翻译语言区域都得到 PASS 或 PASS WITH CONDITIONS 结论（在 `standard` 下推荐；在 `minimal` 下取消）。FAIL 仅阻塞该语言区域的发布 —— 其他语言区域若其 QA 通过仍然可以继续。NOT ASSESSED 的语言区域并未通过：它的 QA 没有运行。

---

## Phase 3: Rules and Next Steps

## 阶段 3：规则与后续步骤

### Rules

### 规则

- English (en) is always the source locale
- Every string table entry must include a `context` field with translator notes, character limits, and placeholder meaning
- Never modify translation files directly — generate diffs for review
- Character limits must be defined per-UI-element and enforced in validate mode
- String freeze must be called before sending strings to translators — never translate a moving target
- RTL support must be designed in from the start — retrofitting RTL layout is expensive
- Cultural review is required for any locale where the game will be sold commercially
- VO scripts must include director notes — raw dialogue lines produce flat recordings

- 英语（en）始终是源语言区域
- 每个字符串表条目都必须包含 `context` 字段，其中写明译者注释、字符限制和占位符含义
- 永远不要直接修改翻译文件 —— 生成 diff 供审查
- 字符限制必须按 UI 元素定义，并在 validate 模式中强制执行
- 在把字符串发送给译者之前必须调用字符串冻结 —— 永远不要翻译一个移动的目标
- RTL 支持必须从一开始就设计进去 —— 事后改造 RTL 布局代价高昂
- 对于游戏将商业销售的任何语言区域，都必须进行文化审查
- VO 脚本必须包含导演注释 —— 原始对话台词会产生平淡的录音

### Recommended Workflow

### 推荐工作流

```
/localize scan            → find hardcoded strings
/localize extract         → build string table
/localize freeze          → lock source before sending to translators
/localize brief           → generate translator briefing document
[Send to translators]
/localize validate        → check returned translations
/localize cultural-review → flag culturally sensitive content
/localize rtl-check       → if shipping Arabic / Hebrew / Persian
/localize vo-pipeline     → if shipping dubbed VO
/localize qa              → full localization QA pass
```

```
/localize scan            → find hardcoded strings
/localize extract         → build string table
/localize freeze          → lock source before sending to translators
/localize brief           → generate translator briefing document
[Send to translators]
/localize validate        → check returned translations
/localize cultural-review → flag culturally sensitive content
/localize rtl-check       → if shipping Arabic / Hebrew / Persian
/localize vo-pipeline     → if shipping dubbed VO
/localize qa              → full localization QA pass
```

```
/localize scan            → 查找硬编码字符串
/localize extract         → 构建字符串表
/localize freeze          → 在发送给译者前锁定源
/localize brief           → 生成译者简报文档
[Send to translators]
/localize validate        → 检查返回的翻译
/localize cultural-review → 标记文化敏感内容
/localize rtl-check       → 如果发布阿拉伯语 / 希伯来语 / 波斯语
/localize vo-pipeline     → 如果发布配音 VO
/localize qa              → 完整的本地化 QA 环节
```

After `qa` returns PASS or PASS WITH CONDITIONS for every translated locale you ship, include the QA report paths when running `/gate-check release`.

在 `qa` 对你发布的每个已翻译语言区域返回 PASS 或 PASS WITH CONDITIONS 之后，运行 `/gate-check release` 时请附上 QA 报告路径。
