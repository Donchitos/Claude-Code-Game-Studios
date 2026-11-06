---
name: patch-notes
description: "Player-facing patch notes from git history and changelogs. Translates developer language into player communication."
argument-hint: "[version] [--style brief|detailed|full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/patch-notes/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *)
model: sonnet
---
---
name: patch-notes
description: "根据 git 历史与变更日志生成面向玩家的补丁说明。将开发者语言翻译为玩家沟通语言。"
argument-hint: "[version] [--style brief|detailed|full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(bash "*/.claude/skills/patch-notes/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**自动化模式**：解析 `modes.automation`（`project.local.yaml` →
`project.yaml` → 默认 `collaborative`）。每次 `AskUserQuestion` 调用与
每次文件写入都遵循 `.claude/docs/automation-modes.md`
（collaborative 总是询问 · guided 仅重要事项 · autonomous 记录并继续；
`automation_always_ask` 类别总是提示）。

# Patch Notes

## Provenance check — before reading any history

**Confirm the history you are about to read belongs to THIS game.** Run this
before Phase 2 and stop if it fails.

# 补丁说明

## 来源核查 — 在读取任何历史之前

**确认你即将读取的历史属于本游戏。** 在阶段 2 之前运行此检查，若失败则停止。

1. Sample the recent log: `git log --oneline -20`. **If it is empty or git is
   unavailable, skip this check** — there is nothing to classify, and Phase 2's
   no-changelog-data branch is the right stop.
2. **Classify every commit in the range, one at a time**, into exactly one of:
   - **Game** — changes the game the player plays: mechanics, content, balance,
     art, audio, UI, a bug in any of those.
   - **Framework / maintenance** — changes CCGS itself or the project's tooling:
     subjects naming skills, hooks, agents, the test plan, CI, the framework's
     own docs. **Excluded from player-facing notes, but not a reason to stop.**
   - **Unclear** — treat as framework. A commit you cannot confidently place is
     not one to write player copy from.
3. Then decide from the counts:
   - **At least one Game commit** → proceed, using **only** those. Say how many
     of how many you used, so the reader can see the filter ran.
   - **Zero Game commits** → stop, using the message below, and give the count (0 of how many) so the reader can see the filter ran.

1. 抽样查看最近的日志：`git log --oneline -20`。**如果它为空或 git
   不可用，跳过此检查** — 没有可分类的内容，阶段 2 的
   无变更日志数据分支才是正确的停止点。
2. **逐一分类范围内每个提交**，归入且仅归入以下之一：
   - **Game** — 改变玩家所玩游戏的提交：机制、内容、平衡、
     美术、音频、UI，以及其中任何一项的缺陷。
   - **Framework / maintenance** — 改变 CCGS 本身或项目工具链的提交：
     主题点名技能、钩子、智能体、测试计划、CI、框架自身的
     文档。**从面向玩家的说明中排除，但不是停止的理由。**
   - **Unclear** — 视为框架。你无法有把握归类的提交
     不是用来撰写玩家文案的依据。
3. 然后依据计数决定：
   - **至少有一个 Game 提交** → 继续，**只**使用这些提交。说明你用了多少个
     共多少个，让读者看到过滤器确实运行了。
   - **零个 Game 提交** → 使用下方消息停止，并给出计数（0 个，共多少个），让读者看到过滤器确实运行了。

> **Filter per commit; do not stop on a repo that merely contains maintenance
> work.** Every project built on this framework accumulates commits touching
> hooks, CI and skills — the game repo *is* the framework repo, so a repo-level
> stop fires on virtually every real project. The danger is not that such
> commits *exist*; it is that they get **rendered as player-facing copy**.
> Excluding them addresses that exactly, and a repo-level stop does not.

> **按提交过滤；不要因为一个仅仅包含维护工作的仓库而停止。**
> 每个构建在此框架上的项目都会累积触及
> 钩子、CI 和技能的提交 — 游戏仓库*就是*框架仓库，因此仓库级
> 停止几乎会在每个真实项目上触发。危险不在于这些
> 提交*存在*；而在于它们被**渲染成面向玩家的文案**。
> 排除它们恰好解决了这个问题，而仓库级停止则不行。

Corroborate before you proceed, cheaply: the Game commits should name systems
that appear in `design/` and the code root (`src/`, `Assets/` or `Source/`). If
they name a product those directories
never mention, that is the real wrong-history signal — stop.

在继续之前，用低成本方式加以印证：Game 提交应当点名
出现在 `design/` 和代码根（`src/`、`Assets/` 或 `Source/`）中的系统。如果
它们提到的产物是那些目录
从未提及的，那才是真正错误历史的信号 — 停止。

If **no** commit in the range is this game's, say so and stop:

> "The git history in this repo does not appear to belong to [game]: 0 of the [N]
> recent commits are Game commits. The recent
> commits describe [what they actually describe]. I cannot generate release notes
> from it — point me at the right history, or supply the change list directly."

如果范围内**没有**任何提交属于本游戏，说明并停止：

> "The git history in this repo does not appear to belong to [game]: 0 of the [N]
> recent commits are Game commits. The recent
> commits describe [what they actually describe]. I cannot generate release notes
> from it — point me at the right history, or supply the change list directly."

Verdict: **BLOCKED** — stop here without generating notes.

Verdict: **BLOCKED** — 在此停止，不生成说明。

**Why this is a hard stop, not a warning.** Framework-internal commits rendered
as player copy read as real changes: a session-hook timeout becomes *"Fixed an
issue where progress from your last session could be lost on launch"* in a game
with **no save system**. That copy is fluent, plausible, and entirely false. A
reader cannot tell the difference; only this check can.

**为什么这是硬停止而非警告。** 框架内部提交一旦被渲染
成玩家文案，读起来就像真实变更：一个会话钩子超时变成
*"Fixed an issue where progress from your last session could be lost on launch"*，而这发生在一个
**没有存档系统**的游戏中。那段文案流畅、可信，且完全虚假。一个
读者无法分辨差异；只有此检查可以。

---

## Phase 1: Parse Arguments

- `version`: the release version to generate notes for (e.g., `1.2.0`)
- `--style`: output style — `brief` (bullet points), `detailed` (with context), `full` (with developer commentary). Default: `detailed`.

If no version is provided, ask the user before proceeding.

---

## 阶段 1：解析参数

- `version`：要生成说明的发布版本（例如 `1.2.0`）
- `--style`：输出风格 — `brief`（要点）、`detailed`（含上下文）、`full`（含开发者评论）。默认：`detailed`。

如果未提供版本，在继续之前询问用户。

---

## Phase 2: Gather Change Data

- Read the internal changelog at `production/releases/[version]/changelog.md` if it exists
- Also check `docs/CHANGELOG.md` for the relevant version entry
- Run `git log` between the previous release tag and current tag/HEAD as a fallback
- Read sprint retrospectives in `production/sprints/` for context
- Read any balance change documents in `design/balance/`
- Read bug fix records from QA if available

## 阶段 2：收集变更数据

- 如果存在，读取 `production/releases/[version]/changelog.md` 的内部变更日志
- 同时检查 `docs/CHANGELOG.md` 中相关版本的条目
- 作为回退，在上一发布标签与当前标签/HEAD 之间运行 `git log`
- 读取 `production/sprints/` 中的冲刺回顾以获取上下文
- 读取 `design/balance/` 中任何平衡性变更文档
- 如可用，读取 QA 的缺陷修复记录

**If no changelog data is available** (neither `production/releases/[version]/changelog.md`
nor a `docs/CHANGELOG.md` entry for this version exists, and git log is empty or unavailable):

> "No changelog data found for [version]. Run `/changelog [version]` first to generate the
> internal changelog, then re-run `/patch-notes [version]`."

Verdict: **BLOCKED** — stop here without generating notes.

**如果没有可用的变更日志数据**（`production/releases/[version]/changelog.md`
和 `docs/CHANGELOG.md` 中本版本的条目都不存在，且 git log 为空或不可用）：

> "No changelog data found for [version]. Run `/changelog [version]` first to generate the
> internal changelog, then re-run `/patch-notes [version]`."

Verdict: **BLOCKED** — 在此停止，不生成说明。

---

## Phase 2b: Detect Tone Guide and Template

**Tone guide detection** — before drafting notes, check for writing style guidance:

1. Check `.claude/docs/technical-preferences.md` for any "tone", "voice", or "style"
   fields or sections.
2. Check `docs/PATCH-NOTES-STYLE.md` if it exists.
3. Check `design/community/tone-guide.md` if it exists.
4. If any source contains tone/voice/style instructions, extract them and apply
   them to the language and framing of the generated notes.
5. If no tone guidance is found anywhere, default to:
   player-friendly, non-technical language; enthusiastic but not hyperbolic;
   focus on what the player experiences, not what the developer changed.

## 阶段 2b：检测语调指南与模板

**语调指南检测** — 在起草说明之前，检查写作风格指引：

1. 检查 `.claude/docs/technical-preferences.md` 中是否有任何 "tone"、"voice" 或 "style"
   字段或小节。
2. 如果存在，检查 `docs/PATCH-NOTES-STYLE.md`。
3. 如果存在，检查 `design/community/tone-guide.md`。
4. 如果任何来源包含语调/voice/风格指引，提取它们并应用
   到生成说明的语言与框架上。
5. 如果在任何地方都没有找到语调指引，默认采用：
   玩家友好、非技术性的语言；热情但不夸张；
   聚焦玩家体验到什么，而非开发者改了什么。

**Template detection** — check whether a patch notes template exists:

1. Glob for `docs/patch-notes-template.md` and `.claude/docs/templates/patch-notes-template.md`.
2. If found at either location, read it and use it as the output structure for Phase 4
   instead of the built-in style templates (Brief / Detailed / Full). Fill in the
   template's sections with the categorized data, mapping each category to the
   template section that means the same (New Content → its new-features section,
   Bug Fixes → its fixes section); a category with no matching section goes under
   the closest one, never dropped. Keep the template's header and footer text
   as written. Say in the output which template was used — and, when `--style`
   was passed, that the template replaced it.
3. If not found, use the built-in style templates as defined in Phase 4.

**模板检测** — 检查是否存在补丁说明模板：

1. Glob 查找 `docs/patch-notes-template.md` 与 `.claude/docs/templates/patch-notes-template.md`。
2. 如果在任一位置找到，读取它并将其用作阶段 4 的输出结构，
   替代内置风格模板（Brief / Detailed / Full）。用分类后的数据填充
   模板的各个小节，将每个类别映射到含义相同的
   模板小节（New Content → 其 new-features 小节，
   Bug Fixes → 其 fixes 小节）；没有匹配小节的类别归入
   最接近的那个，绝不丢弃。保持模板的页眉与页脚文本
   原样。在输出中说明使用了哪个模板 — 并且，当传入了 `--style`
   时，说明模板已替代它。
3. 如果未找到，使用阶段 4 中定义的内置风格模板。

---

## Phase 3: Categorize and Translate

Categorize all changes into player-facing categories:

- **New Content**: new features, maps, characters, items, modes
- **Gameplay Changes**: balance adjustments, mechanic changes, progression changes
- **Quality of Life**: UI improvements, convenience features, accessibility
- **Bug Fixes**: grouped by system (combat, UI, networking, etc.)
- **Performance**: optimization improvements players might notice
- **Known Issues**: transparency about unresolved problems

## 阶段 3：分类与翻译

将所有变更归入面向玩家的类别：

- **新内容**：新功能、地图、角色、物品、模式
- **玩法变更**：平衡性调整、机制变更、进度变更
- **体验优化**：UI 改进、便利功能、无障碍
- **缺陷修复**：按系统分组（战斗、UI、网络等）
- **性能**：玩家可能察觉到的优化改进
- **已知问题**：对未解决问题的透明披露

Translate developer language to player language:

- "Refactored damage calculation pipeline" → "Improved hit detection accuracy"
- "Fixed null reference in inventory manager" → "Fixed a crash when opening inventory"
- "Reduced GC allocations in combat loop" → "Improved combat performance"
- Remove purely internal changes that don't affect players
- Preserve specific numbers for balance changes (damage: 50 → 45)

将开发者语言翻译为玩家语言：

- "Refactored damage calculation pipeline" → "Improved hit detection accuracy"
- "Fixed null reference in inventory manager" → "Fixed a crash when opening inventory"
- "Reduced GC allocations in combat loop" → "Improved combat performance"
- 移除纯内部、不影响玩家的变更
- 为平衡性变更保留具体数字（damage: 50 → 45）

---

## Phase 4: Generate Patch Notes

### Brief Style
```markdown
# Patch [Version] — [Title]

**New**
- [Feature 1]
- [Feature 2]

**Changes**
- [Balance/mechanic change with before → after values]

**Fixes**
- [Bug fix 1]
- [Bug fix 2]

**Known Issues**
- [Issue 1]
```

## 阶段 4：生成补丁说明

### 简洁风格
```markdown
# Patch [Version] — [Title]

**New**
- [Feature 1]
- [Feature 2]

**Changes**
- [Balance/mechanic change with before → after values]

**Fixes**
- [Bug fix 1]
- [Bug fix 2]

**Known Issues**
- [Issue 1]
```

### Detailed Style
```markdown
# Patch [Version] — [Title]
*[Date]*

## Highlights
[1-2 sentence summary of the most exciting changes]

## New Content
### [Feature Name]
[2-3 sentences describing the feature and why players should be excited]

## Gameplay Changes
### Balance
| Change | Before | After | Reason |
| ---- | ---- | ---- | ---- |
| [Item/ability] | [old value] | [new value] | [brief rationale] |

### Mechanics
- **[Change]**: [explanation of what changed and why]

## Quality of Life
- [Improvement with context]

## Bug Fixes
### Combat
- Fixed [description of what players experienced]

### UI
- Fixed [description]

### Networking
- Fixed [description]

## Performance
- [Improvement players will notice]

## Known Issues
- [Issue and workaround if available]
```

### 详细风格
```markdown
# Patch [Version] — [Title]
*[Date]*

## Highlights
[1-2 sentence summary of the most exciting changes]

## New Content
### [Feature Name]
[2-3 sentences describing the feature and why players should be excited]

## Gameplay Changes
### Balance
| Change | Before | After | Reason |
| ---- | ---- | ---- | ---- |
| [Item/ability] | [old value] | [new value] | [brief rationale] |

### Mechanics
- **[Change]**: [explanation of what changed and why]

## Quality of Life
- [Improvement with context]

## Bug Fixes
### Combat
- Fixed [description of what players experienced]

### UI
- Fixed [description]

### Networking
- Fixed [description]

## Performance
- [Improvement players will notice]

## Known Issues
- [Issue and workaround if available]
```

### Full Style
Includes everything from Detailed, plus:
```markdown
## Developer Commentary
### [Topic]
> [Developer insight into a major change — why it was made, what was considered,
> what the team learned. Written in first-person team voice.]
```

### 完整风格
包含详细风格的一切，另加：
```markdown
## Developer Commentary
### [Topic]
> [Developer insight into a major change — why it was made, what was considered,
> what the team learned. Written in first-person team voice.]
```

---

## Phase 5: Review Output

Check the generated notes for:

- No internal jargon (replace technical terms with player-friendly language)
- No references to internal systems, tickets, or sprint numbers
- Balance changes include before/after values
- Bug fixes describe the player experience, not the technical cause
- Tone matches the game's voice (adjust formality based on game style)

## 阶段 5：评审输出

检查生成的说明是否：

- 没有内部行话（用玩家友好的语言替换技术术语）
- 没有内部系统、工单或冲刺编号的引用
- 平衡性变更包含前后数值
- 缺陷修复描述玩家体验，而非技术原因
- 语调匹配游戏的声音（根据游戏风格调整正式程度）

---

## Phase 6: Save Patch Notes

Present the completed patch notes to the user along with: a count of changes by category, and any internal changes that were excluded (for review).

Ask: "May I write these patch notes to `docs/patch-notes/[version].md`, and an
archive copy to `production/releases/[version]/patch-notes.md`?"

If yes, write both files, creating the directories if needed.
If no, write nothing.

## 阶段 6：保存补丁说明

将完成的补丁说明呈现给用户，并附上：按类别统计的变更数量，以及被排除的任何内部变更（供评审）。

询问："May I write these patch notes to `docs/patch-notes/[version].md`, and an
archive copy to `production/releases/[version]/patch-notes.md`?"

如果是，写入两个文件，必要时创建目录。
如果否，什么也不写。

---

## Phase 7: Next Steps

Verdict: **COMPLETE** — patch notes generated and saved. (If the write was
declined: Verdict: **COMPLETE** — patch notes generated and shown, not saved.)

- Run `/release-checklist` to verify all other release gates are met before publishing.
- Share the patch notes draft with the community-manager for tone review before posting publicly.

## 阶段 7：后续步骤

Verdict: **COMPLETE** — 补丁说明已生成并保存。（如果写入被
拒绝：Verdict: **COMPLETE** — 补丁说明已生成并展示，未保存。）

- 运行 `/release-checklist` 以在发布前验证所有其他发布门禁都已满足。
- 在公开发布前，将补丁说明草稿分享给 community-manager 做语调评审。
