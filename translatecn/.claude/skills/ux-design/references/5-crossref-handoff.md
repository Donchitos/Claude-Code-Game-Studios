# /ux-design — Sections 5 and 6: Cross-Reference Check and Handoff
# /ux-design — 第 5 与 6 节：交叉引用检查与交接

> Part of `/ux-design`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/ux-design` 的组成部分。`SKILL.md` 指明何时读取本文件；它已解析的各项设置，
> 以及其后续标题下所列的规则，在此同样适用。

## 5. Cross-Reference Check
## 5. 交叉引用检查

Before marking the spec as ready for review, run these checks:

在把规格标记为可供审查之前，运行以下检查：

**1. GDD requirement coverage**: Does every GDD UI Requirement that references
this screen have a corresponding element in this spec? Present any gaps.

**1. GDD 需求覆盖**：每一条引用了此界面的 GDD UI Requirement，是否在本规格中
都有对应元素？呈现任何缺口。

**2. Pattern library alignment**: Are all interaction patterns used in this spec
referenced by name? If a new pattern was invented during this spec session, flag
it for addition to the pattern library:
Use `AskUserQuestion`:
- "This spec uses [pattern name], which isn't in the pattern library yet. What should we do?"
- Options: "Add it to the pattern library now", "Flag it as a gap and continue", "Skip — this pattern is one-off"

**2. 模式库对齐**：本规格中使用的所有交互模式是否都以名称引用？如果在本规格
会话中发明了新模式，标记以便加入模式库：
使用 `AskUserQuestion`：
- “本规格使用了 [pattern name]，它尚未在模式库中。我们该怎么处理？”
- 选项：“现在加入模式库”、“标记为缺口并继续”、“跳过——此模式是一次性的”

**3. Navigation consistency**: Do the entry/exit points in this spec match the
navigation map in any related specs? Flag mismatches.

**3. 导航一致性**：本规格的进入/退出点是否与任何相关规格中的
导航图一致？标记不匹配处。

**4. Accessibility coverage**: Does the spec address the accessibility tier
committed to in `design/accessibility-requirements.md`? If not, flag open questions.

**4. 无障碍覆盖**：本规格是否处理了 `design/accessibility-requirements.md` 中承诺的
无障碍等级？若未处理，标记这些待解决问题。

**5. Empty states**: Does every data-dependent element have an empty state defined?
Flag any that don't.

**5. 空状态**：每个依赖数据的元素是否都定义了空状态？
标记任何未定义的。

Present the check results:
> **Cross-Reference Check: [Screen Name]**
> - GDD requirements: [N of M covered / all covered]
> - New patterns to add to library: [list or "none"]
> - Navigation mismatches: [list or "none"]
> - Accessibility gaps: [list or "none"]
> - Missing empty states: [list or "none"]

呈现检查结果：
> **交叉引用检查：[Screen Name]**
> - GDD 需求：[已覆盖 N / M / 全部已覆盖]
> - 需加入库的新模式：[列表或 “none”]
> - 导航不匹配：[列表或 “none”]
> - 无障碍缺口：[列表或 “none”]
> - 缺失的空状态：[列表或 “none”]

---

## 6. Handoff
## 6. 交接

When all sections are approved and written:

当所有分区都已批准并写入时：

### 6a: Update Session State
### 6a：更新会话状态

Update `production/session-state/active.md` with:
- Task: [screen-name] UX spec
- Status: Complete (or In Review)
- File: design/ux/[filename].md
- Sections: All written
- Next: [suggestion]

更新 `production/session-state/active.md`，内容为：
- 任务：[screen-name] UX 规格
- 状态：已完成（或审查中）
- 文件：design/ux/[filename].md
- 分区：全部已写入
- 下一步：[建议]

### 6b: Suggest Next Step
### 6b：建议下一步

Before presenting options, state clearly:

在呈现选项之前，明确说明：

> "This spec should be validated with `/ux-review` before it enters the
> implementation pipeline. The Production gate (`/gate-check production`)
> requires all key screen specs to have passed `/ux-review` at `workflow: full`
> (recommended at `standard`)."

> “在进入实现流水线之前，本规格应通过 `/ux-review` 校验。
> 生产关卡（`/gate-check production`）要求所有关键界面规格
> 在 `workflow: full` 下通过 `/ux-review`
> （在 `standard` 下为推荐）。”

Then use `AskUserQuestion`:
- "Run `/ux-review [filename]` now, or do something else first?"
  - Options:
    - "Run `/ux-review` now — validate this spec"
    - "Design another screen first, then review all specs together"
    - "Update the interaction pattern library with new patterns from this spec"
    - "Stop here for this session"

然后使用 `AskUserQuestion`：
- “现在运行 `/ux-review [filename]`，还是先做别的事？”
  - 选项：
    - “现在运行 `/ux-review`——校验本规格”
    - “先设计另一个界面，再一起审查所有规格”
    - “用本规格中的新模式更新交互模式库”
    - “本次会话到此为止”

If the user picks "Design another screen first", add a note: "Reminder: run
`/ux-review` on all completed specs before running `/gate-check production`."

如果用户选择“先设计另一个界面”，添加一条备注：“提醒：在运行
`/gate-check production` 之前，对所有已完成的规格运行 `/ux-review`。”

### 6c: Cross-Link Related Specs
### 6c：交叉链接相关规格

If other UX specs link to or from this screen, note which ones should reference
this spec. Do not edit those files without asking — just name them.

如果有其他 UX 规格链接到或从此界面链接出去，注明哪些应引用
本规格。未经询问不要编辑那些文件——只需点出它们。

---
