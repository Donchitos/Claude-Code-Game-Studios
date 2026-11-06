---
name: brainstorm
description: "Guides the user through finding and choosing a game concept. Use when the user wants game ideas, a new concept, a game jam idea, or to explore other directions, including dropping the current idea and starting over."
argument-hint: "[genre or theme hint, or 'open'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, WebSearch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/brainstorm/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
---
name: brainstorm
description: "引导用户寻找并选定一个游戏概念。当用户想要游戏点子、新概念、游戏创作营点子，或探索其他方向——包括放弃当前想法从头开始——时使用。"
argument-hint: "[genre or theme hint, or 'open'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, WebSearch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/brainstorm/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,docs.density,workflow`

Resolved above; use as-is. No block → the defaults in `.claude/docs/config-resolution.md`
(`workflow: minimal`, `review_mode: solo`, `automation: collaborative`, `docs.density: terse`), and
say that the settings were not read.
已在上方解析；按原样使用。无块 → 使用 `.claude/docs/config-resolution.md` 中的默认值（`workflow: minimal`、`review_mode: solo`、`automation: collaborative`、`docs.density: terse`），并说明这些设置未被读取。

# Brainstorm
# 头脑风暴

Turns no idea, or a rough one, into a written design the next step builds from. How much it writes
depends on `workflow`:
将没有任何想法、或只有一个粗糙想法的情况，转化为一份下一步可据以构建的书面设计。它写多少取决于 `workflow`：

- **`minimal`:** the Lean Brief flow below: a one-page `design/game-brief.md`, then stop. No
  discovery questions, pillars, director gates or `game-concept.md`, and do not load
  `references/full-concept.md`.
- **`standard` or `full`:** read `references/full-concept.md` and follow it. It writes
  `design/gdd/game-concept.md` from `.claude/docs/templates/game-concept.md`. Its gates follow
  `.claude/docs/director-gates.md`; each director agent is given its own gate file,
  `.claude/docs/director-gates/<gate-id in lower case>.md` (`cd-pillars.md`,
  `ad-concept-visual.md`, `td-feasibility.md`, `pr-scope.md`), and you do not read those files
  yourself.
- **`minimal`：** 下方的精简简报流程：一页 `design/game-brief.md`，然后停止。没有探索性问题、支柱、总监门禁或 `game-concept.md`，也不要加载 `references/full-concept.md`。
- **`standard` 或 `full`：** 读取 `references/full-concept.md` 并遵循它。它依据 `.claude/docs/templates/game-concept.md` 写入 `design/gdd/game-concept.md`。其门禁遵循 `.claude/docs/director-gates.md`；每个总监智能体会获得自己的门禁文件 `.claude/docs/director-gates/<gate-id in lower case>.md`（`cd-pillars.md`、`ad-concept-visual.md`、`td-feasibility.md`、`pr-scope.md`），而你自己不读取那些文件。

`--review` in the text typed after the skill name overrides `review_mode` for this run.
`docs.density` sets each section's depth: `terse` = bullets; `balanced` = with brief rationale;
`thorough` = rationale and alternatives. Questions follow `.claude/docs/automation-modes.md`
(collaborative asks, guided asks only for major decisions, autonomous logs and proceeds; the
always-ask categories always ask).
按技能名称之后输入的文本中的 `--review` 会为本次运行覆盖 `review_mode`。`docs.density` 设定每个章节的深度：`terse` = 要点列表；`balanced` = 附带简短理由；`thorough` = 理由与备选方案。提问遵循 `.claude/docs/automation-modes.md`（collaborative 询问，guided 仅对重大决策询问，autonomous 记录并继续；始终询问类别始终询问）。

Ask with the question tool. Without one, list the options numbered and end your turn to wait. The
question is the last thing in the reply: no advice or lean after it. A skipped or dismissed
question is not an answer: ask again in plain text.
用提问工具提问。若没有该工具，将选项编号列出并结束你的回合以等待。问题必须是回复中的最后一项：其后再无建议或倾向性表述。被跳过或忽略的问题不是回答：用纯文本再次提问。

## Lean Brief flow (`workflow: minimal`)
## 精简简报流程（`workflow: minimal`）

A few exchanges, not fifteen: capture the thinking that carries the game on one page, then get to
code. Write from the template `.claude/docs/templates/game-brief.md` (six required fields, three
one-liners). If `design/game-brief.md` exists, read it and refine it instead of starting over.
几次交流，而非十五次：在一页纸上捕捉支撑这款游戏的核心思路，然后进入编码。依据模板 `.claude/docs/templates/game-brief.md` 来写（六个必填字段、三个一句话）。如果 `design/game-brief.md` 已存在，读取并完善它，而不是从头开始。

1. **Concept.** From the hint typed after the skill name (or one quick open question if there is
   none), propose **2 or 3 one-line concepts** (verb-first or a mashup of genre and theme), not
   full concept cards. Ask the user to pick or combine them. This is the one creative question
   every run asks.
2. **Fill the brief** in conversation, several fields per exchange:
   - **Working title:** the brief's title line. Offer one from the chosen concept and let the user
     change it; `/create-stories` names the epic folder after it.
   - **Pitch:** the excited one-liner.
   - **Core loop:** the 2 to 4 steps the player repeats.
   - **Player goal & fail state**: what the player tries to do, and how they lose.
     `/create-stories` turns it into acceptance criteria.
   - **MVP:** the short list that makes it the game; each item becomes a story. **More than 7
     items: push back.** Say it is too long for an MVP, propose which items to cut (the ones the
     core loop works without), and keep the brief to 7 or fewer.
   - **Out of scope:** what they are deliberately not building (the cut items go here).
   - **Build order:** the riskiest or least proven part first.
   - **Who it's for and what they feel**, **Art & audio direction**, **Reference game** (the
     closest shipped game, and the part of it the MVP keeps): one line each; offer, don't force.
3. **Show the filled brief in full.** Then ask, as its own question: "Brief is ready. May I write it
   to `design/game-brief.md`?" `Yes — write it` / `Revise a field first`. Write only on an explicit
   yes to this question; agreeing to a cut or saying "go on" is not a yes to the write. On a
   revision, change the named field, show it before and after, and ask again. Then write
   `design/game-brief.md`, creating folders as needed. Never write `design/gdd/game-concept.md`
   at this tier.
4. **Next steps.** Read `engine.name` in `project.yaml`:
   1. `/setup-engine`: configure the engine. List it **only** when `engine.name` is absent or
      empty: on the minimal path it usually ran before this skill.
   2. `/create-stories`: turn the MVP list into stories. At `minimal` there is no separate
      `/create-epics` or `/sprint-plan`; the build order is the plan.
   3. `/dev-story`: the first line of game code.

   Then one summary line: the pitch, the number of MVP items, and `design/game-brief.md`. End with
   the line `Verdict: COMPLETE — game brief written; next stop is code.`
1. **概念。** 根据技能名称之后输入的提示（若没有，则提出一个简短的开放式问题），提出 **2 或 3 个一句话概念**（动词开头，或类型与主题的混搭），而不是完整的概念卡片。请用户挑选或组合它们。这是每次运行都会问的唯一一个创意问题。
2. **填写简报**，在对话中进行，每次交流填几个字段：
   - **暂定标题：** 简报的标题行。从所选概念中提供一个，并让用户修改；`/create-stories` 会据此命名史诗文件夹。
   - **推介语：** 那句令人兴奋的一句话。
   - **核心循环：** 玩家重复的 2 到 4 个步骤。
   - **玩家目标与失败状态**：玩家试图做什么，以及他们如何失败。`/create-stories` 会将其转化为验收标准。
   - **MVP：** 让这款游戏成其为游戏的那份简短清单；每一项都会变成一个故事。**超过 7 项：要反驳。** 说明这对 MVP 来说太长，提出应砍掉哪些项（核心循环没有它们也能运转的那些），并将简报控制在 7 项或更少。
   - **范围之外：** 他们刻意不构建的东西（被砍掉的项放这里）。
   - **构建顺序：** 最有风险或最未经证实的那部分优先。
   - **面向谁以及他们的感受**、**美术与音频方向**、**参照游戏**（最接近的已发行游戏，以及 MVP 保留它的哪一部分）：各一行；是提供，不是强加。
3. **完整展示填好的简报。** 然后作为独立问题询问：“简报已就绪。我可以把它写入 `design/game-brief.md` 吗？”`Yes — write it` / `Revise a field first`。只有在对这个问题明确回答是时才写入；同意某项删减或说“继续”都不构成对写入的同意。若需修订，修改所指名的字段，展示修改前后，并再次询问。然后写入 `design/game-brief.md`，按需创建文件夹。在该层级绝不要写入 `design/gdd/game-concept.md`。
4. **后续步骤。** 读取 `project.yaml` 中的 `engine.name`：
   1. `/setup-engine`：配置引擎。**仅**当 `engine.name` 缺失或为空时才列出它：在精简路径上，它通常已在本技能之前运行过。
   2. `/create-stories`：将 MVP 清单转化为故事。在 `minimal` 下没有单独的 `/create-epics` 或 `/sprint-plan`；构建顺序就是计划。
   3. `/dev-story`：第一行游戏代码。

   然后一行摘要：推介语、MVP 项数，以及 `design/game-brief.md`。以该行结束 `Verdict: COMPLETE — game brief written; next stop is code.`

If the user stops before the write, say the brief was not written, so it lives only in this
conversation.
如果用户在写入之前停下，说明简报未被写入，因此它只存在于本次对话中。
