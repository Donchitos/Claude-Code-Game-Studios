---
name: playtest-report
description: "Structured playtest report template, or turn existing playtest notes into structured feedback."
argument-hint: "[new|analyze path-to-notes] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/playtest-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: playtest-report
description: "结构化的试玩报告模板，或将既有试玩笔记整理成结构化反馈。"
argument-hint: "[new|analyze path-to-notes] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/playtest-report/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

以上已解析 — 直接使用；`--review` 覆盖本次运行的 `review_mode`。无
配置块 → 使用 `.claude/docs/config-resolution.md` 中的默认值。

# Playtest Report

# 试玩报告



## Phase 1: Parse Arguments

## 阶段 1：解析参数


See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

完整的检查模式见 `.claude/docs/director-gates.md`。各项门禁定义位于 `.claude/docs/director-gates/[gate-id].md` 中 — 被派生的智能体读取自己的门禁文件；不要在父会话中读取它。


Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

每次 `AskUserQuestion` 调用都遵循 `.claude/docs/automation-modes.md`
（协作模式始终询问 · 引导模式仅重大事项 · 自主模式记录并继续；
`automation_always_ask` 类别始终提示）。

Determine the mode:

确定模式：

- `new` → generate a blank playtest report template. This mode ends after
  Phase 2A: a blank template has nothing to route, review or save.
- `analyze [path]` → read raw notes and fill in the template with structured findings
- No argument → ask via `AskUserQuestion`: `[A] New blank template` /
  `[B] Analyze notes — I'll give you the path`

- `new` → 生成空白试玩报告模板。此模式在
  阶段 2A 后结束：空白模板没有可路由、评审或保存的内容。
- `analyze [path]` → 读取原始笔记并用结构化发现填充模板
- 无参数 → 通过 `AskUserQuestion` 询问：`[A] New blank template` /
  `[B] Analyze notes — I'll give you the path`

---

## Phase 2A: New Template Mode

## 阶段 2A：新建模板模式

Generate this template and output it to the user:

生成此模板并输出给用户：

```markdown
# Playtest Report

## Session Info
- **Date**: [Date]
- **Build**: [Version/Commit]
- **Duration**: [Time played]
- **Tester**: [Name/ID]
- **Platform**: [PC/Console/Mobile]
- **Input Method**: [KB+M / Gamepad / Touch]
- **Session Type**: [First time / Returning / Targeted test]

## Test Focus
[What specific features or flows were being tested]

## First Impressions (First 5 minutes)
- **Understood the goal?** [Yes/No/Partially]
- **Understood the controls?** [Yes/No/Partially]
- **Emotional response**: [Engaged/Confused/Bored/Frustrated/Excited]
- **Notes**: [Observations]

## Gameplay Flow
### What worked well
- [Observation 1]

### Pain points
- [Issue 1 -- Severity: High/Medium/Low]

### Confusion points
- [Where the player was confused and why]

### Moments of delight
- [What surprised or pleased the player]

## Bugs Encountered
| # | Description | Severity | Reproducible |
|---|-------------|----------|-------------|

## Feature-Specific Feedback
### [Feature 1]
- **Understood purpose?** [Yes/No]
- **Found engaging?** [Yes/No]
- **Suggestions**: [Tester suggestions]

## Quantitative Data (if available)
- **Deaths**: [Count and locations]
- **Time per area**: [Breakdown]
- **Items used**: [What and when]
- **Features discovered vs missed**: [List]

## Overall Assessment
- **Would play again?** [Yes/No/Maybe]
- **Difficulty**: [Too Easy / Just Right / Too Hard]
- **Pacing**: [Too Slow / Good / Too Fast]
- **Session length preference**: [Shorter / Good / Longer]

## Top 3 Priorities from this session
1. [Most important finding]
2. [Second priority]
3. [Third priority]
```

In `new` mode, stop here with: Verdict: **COMPLETE** — blank template output; nothing saved.

在 `new` 模式下，到此为止：结论：**COMPLETE** — 空白模板已输出；未保存任何内容。

---

## Phase 2B: Analyze Mode

## 阶段 2B：分析模式

Read the raw notes at the provided path. Cross-reference with existing design documents, reading each by section: find the headings you need with the Grep tool (pattern `^#`, content mode) and Read those ranges with offset and limit. Fill in the template above with structured findings. Flag any playtest observations that conflict with design intent.

读取所提供路径处的原始笔记。与既有设计文档交叉引用，按章节读取每个文档：用 Grep 工具（pattern `^#`，content 模式）找到所需标题，并用 offset 和 limit 读取那些区间。用结构化发现填充上面的模板。标记任何与设计意图冲突的试玩观察。

An observation that describes a defect — a crash, a framerate drop, a softlock,
something that plainly breaks rather than plays badly — goes in the **Bugs
Encountered** table, not under Gameplay Flow → Pain points, and is routed as a
bug in Phase 3. Pain points are for how the game feels to play.

描述缺陷的观察 — 崩溃、帧率下降、软锁、
明显是坏掉而非玩起来糟糕的东西 — 放入 **Bugs
Encountered** 表，而不是 Gameplay Flow → Pain points 之下，并在阶段 3 中作为
缺陷路由。Pain points 用来记录游戏玩起来的感觉。

---

## Phase 3: Action Routing

## 阶段 3：行动路由

Categorize all findings into four buckets:

- **Design changes needed** — fun issues, player confusion, broken mechanics, observations that conflict with the GDD's intended experience
- **Balance adjustments** — numbers feel wrong, difficulty too spiked or too flat
- **Bug reports** — clear implementation defects that are reproducible
- **Polish items** — not blocking progress, but friction or feel issues for later

将所有发现归入四个分桶：

- **需要设计变更** — 趣味性问题、玩家困惑、损坏的机制、与 GDD 预期体验冲突的观察
- **平衡调整** — 数值感觉不对、难度过于陡峭或过于平缓
- **缺陷报告** — 清晰、可复现的实现缺陷
- **打磨项** — 不阻碍进度，但属于日后的摩擦或手感问题

Present the categorized list, then route:

呈现分类后的列表，然后路由：

- **Design changes:** "Run `/propagate-design-change [path]` on the affected design document to find downstream impacts before making changes."
- **Balance adjustments:** "Run `/balance-check [system]` to verify the full balance picture before tuning values."
- **Bugs:** "Use `/bug-report` to formally track these."
- **Polish items:** "Add to the polish backlog in `production/` when the team reaches that phase."

- **设计变更：** "Run `/propagate-design-change [path]` on the affected design document to find downstream impacts before making changes."
- **平衡调整：** "Run `/balance-check [system]` to verify the full balance picture before tuning values."
- **缺陷：** "Use `/bug-report` to formally track these."
- **打磨项：** "Add to the polish backlog in `production/` when the team reaches that phase."

---

## Phase 3b: Creative Director Player Experience Review

## 阶段 3b：创意总监玩家体验评审

**Review mode check** — apply before spawning CD-PLAYTEST:
- `solo` → skip. Note: "CD-PLAYTEST skipped — Solo mode." Proceed to Phase 4 (save the report).
- `lean` → skip (not a PHASE-GATE). Note: "CD-PLAYTEST skipped — Lean mode." Proceed to Phase 4 (save the report).
- `full` → spawn as normal.

**评审模式检查** — 在派生 CD-PLAYTEST 之前应用：
- `solo` → 跳过。注明："CD-PLAYTEST skipped — Solo mode." 进入阶段 4（保存报告）。
- `lean` → 跳过（不是 PHASE-GATE）。注明："CD-PLAYTEST skipped — Lean mode." 进入阶段 4（保存报告）。
- `full` → 正常派生。

After categorising findings, spawn `creative-director` via `Agent` using gate **CD-PLAYTEST** (`.claude/docs/director-gates/cd-playtest.md`).

对发现分类后，通过 `Agent` 派生 `creative-director`，使用门禁 **CD-PLAYTEST**（`.claude/docs/director-gates/cd-playtest.md`）。

Pass: the structured report content, game pillars and core fantasy (from
`design/gdd/game-concept.md`), the specific hypothesis being tested. **If
`game-concept.md` does not exist** — expected at `minimal`, where
`design/game-brief.md` replaces it — the brief has no pillars: pass its
one-sentence pitch and its "Who it's for / what they feel" line instead, and say
they stand in for pillars. If neither document exists, say so in the prompt:
*"No pillars available — assess against the hypothesis alone."* A director gate
handed silence about pillars will invent them.

传入：结构化报告内容、游戏支柱与核心幻想（来自
`design/gdd/game-concept.md`）、正在测试的具体假设。**若
`game-concept.md` 不存在** — 在 `minimal` 下预期如此，此时
`design/game-brief.md` 替代它 — 该简报没有支柱：改为传入其
一句话推介语和"Who it's for / what they feel"一行，并说明
它们代替支柱。若两个文档都不存在，在提示中说明：
*"No pillars available — assess against the hypothesis alone."* 一个被交付了关于支柱的沉默的总监门禁
会自己发明支柱。

Present the creative director's assessment before saving the report. If CONCERNS or REJECT, add a `## Creative Director Assessment` section to the report capturing the verdict and feedback. If APPROVE, note the approval in the report. If NOT ASSESSED (the director lacked an input — `.claude/docs/director-gates.md`), add the same section naming what was missing; it is not an approval.

在保存报告之前呈现创意总监的评估。若为 CONCERNS 或 REJECT，向报告添加 `## Creative Director Assessment` 章节，记录结论与反馈。若为 APPROVE，在报告中注明批准。若为 NOT ASSESSED（总监缺少某项输入 — `.claude/docs/director-gates.md`），添加同样的章节并指明缺失了什么；它不是批准。

---

## Phase 4: Save Report

## 阶段 4：保存报告

Ask: "May I write this playtest report to `production/qa/playtests/playtest-[date]-[tester].md`?"

询问："May I write this playtest report to `production/qa/playtests/playtest-[date]-[tester].md`?"

If yes, write the file, creating the directory if needed.

若同意，写入文件，需要时创建目录。

---

## Phase 5: Next Steps

## 阶段 5：后续步骤

Verdict: **COMPLETE** — playtest report generated.

结论：**COMPLETE** — 试玩报告已生成。

- Act on the highest-priority finding category first.
- After addressing design changes: re-run `/design-review` on the updated GDD.
- After fixing bugs: re-run `/bug-triage` to update priorities.

- 先处理优先级最高的发现类别。
- 处理设计变更后：对更新后的 GDD 重新运行 `/design-review`。
- 修复缺陷后：重新运行 `/bug-triage` 以更新优先级。
