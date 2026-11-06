# /gate-check — Sections 7 and 8: Next Step and Follow-Up

# /gate-check — 第 7 与 8 节：下一步与后续行动

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> 属于 `/gate-check`。`SKILL.md` 指明了何时读取本文件；它已解析的设置，以及其后各标题下的规则，在此处仍然适用。

## 7. Closing Next-Step Widget

## 7. 收尾的下一步组件

**In this file:**

**本文件包括：**

- 7. Closing Next-Step Widget: per gate, and the `workflow: minimal` route
- 8. Follow-Up Actions

- 7. 收尾的下一步组件：按门禁区分，以及 `workflow: minimal` 路线
- 8. 后续行动

After the verdict is presented and any stage update is complete (project.yaml + stage.txt), close with a structured next-step prompt using `AskUserQuestion`.

在裁定呈现完毕且任何阶段更新都已完成（project.yaml + stage.txt）之后，用 `AskUserQuestion` 给出结构化的下一步提示来收尾。

**Tailor the options to the gate that just ran.** The argument names the phase
being entered, so `/gate-check systems-design` is the Concept → Systems Design gate.

**将选项裁剪到刚运行的那个门禁上。** 参数命名的是正要进入的阶段，因此 `/gate-check systems-design` 是 Concept → Systems Design 门禁。

**At `workflow: minimal`, skip the menus below.** They walk the phase ladder, and
the minimal route is not the ladder: offer the first incomplete step of
`paths.minimal` instead (the `--path minimal` rows from Section 3):
`/setup-engine`, then `/brainstorm` (or `/reverse-document design [code root]`
when the code root already holds the game: it writes the brief from what is
built), then `/create-stories`, then `/dev-story` on the next story — the route
`/help` gives.

**在 `workflow: minimal` 下，跳过下面的菜单。** 它们沿阶段阶梯推进，而 minimal 路线并不是那架阶梯：改为提供 `paths.minimal` 中第一个未完成的步骤（第 3 节中的 `--path minimal` 行）：`/setup-engine`，然后 `/brainstorm`（当代码根目录已包含游戏时改用 `/reverse-document design [code root]`：它根据已构建的内容写出简报），然后 `/create-stories`，再对下一个故事运行 `/dev-story`——即 `/help` 给出的路线。

For **Concept → Systems Design** (`/gate-check systems-design`) PASS — option [A] is
`/map-systems` when `design/gdd/systems-index.md` does not exist yet (many
projects write it during Concept, as the workflow catalog orders it), otherwise
`/design-system [first system in the index's design order]`:
```
Gate passed. What would you like to do next?
[A] Run /map-systems — decompose the concept into systems and a design order (recommended next step)
    — or, when the systems index already exists: Run /design-system [first system] — author its GDD
[B] Revisit the concept first — return here when it is settled
[C] Stop here for this session
```

对于 **Concept → Systems Design**（`/gate-check systems-design`）PASS——当 `design/gdd/systems-index.md` 尚不存在时（许多项目在 Concept 阶段就写出它，正如工作流目录所排定的顺序），选项 [A] 是 `/map-systems`，否则是 `/design-system [系统索引设计顺序中的第一个系统]`：
```
Gate passed. What would you like to do next?
[A] Run /map-systems — decompose the concept into systems and a design order (recommended next step)
    — or, when the systems index already exists: Run /design-system [first system] — author its GDD
[B] Revisit the concept first — return here when it is settled
[C] Stop here for this session
```

```
门禁已通过。接下来你想做什么？
[A] 运行 /map-systems——把概念分解为多个系统并给出设计顺序（推荐的下一步）
    ——或者，当系统索引已存在时：运行 /design-system [第一个系统]——撰写其 GDD
[B] 先重新审视概念——等它确定后再回到这里
[C] 本次会话到此为止
```

For **Systems Design → Technical Setup** (`/gate-check technical-setup`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — produce your master architecture blueprint and ADR work plan (recommended next step)
[B] Design more GDDs first — return here when all MVP systems are complete
[C] Stop here for this session
```

对于 **Systems Design → Technical Setup**（`/gate-check technical-setup`）PASS：
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — produce your master architecture blueprint and ADR work plan (recommended next step)
[B] Design more GDDs first — return here when all MVP systems are complete
[C] Stop here for this session
```

```
门禁已通过。接下来你想做什么？
[A] 运行 /create-architecture——产出你的总体架构蓝图与 ADR 工作计划（推荐的下一步）
[B] 先设计更多 GDD——等所有 MVP 系统都完成后回到这里
[C] 本次会话到此为止
```

> **Note for the Systems Design → Technical Setup PASS**: `/create-architecture` is the required next step before writing any ADRs. It produces the master architecture document and a prioritized list of ADRs to write. Running `/architecture-decision` without this step means writing ADRs without a blueprint — skip it at your own risk.

> **Systems Design → Technical Setup PASS 的说明**：在撰写任何 ADR 之前，`/create-architecture` 是必需的下一步。它会产出总体架构文档以及一份排定优先级的待写 ADR 清单。跳过这一步直接运行 `/architecture-decision`，意味着在没有蓝图的情况下撰写 ADR——若跳过，风险自负。

For **Technical Setup → Pre-Production** (`/gate-check pre-production`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-control-manifest — generate the layer rules manifest from your Accepted ADRs (first, if docs/architecture/control-manifest.md does not exist yet)
[B] Run /vertical-slice — build the Vertical Slice (do this before writing epics — validate fun first)
[C] Write more ADRs first — run /architecture-decision [next-system]
[D] Stop here for this session
```

对于 **Technical Setup → Pre-Production**（`/gate-check pre-production`）PASS：
```
Gate passed. What would you like to do next?
[A] Run /create-control-manifest — generate the layer rules manifest from your Accepted ADRs (first, if docs/architecture/control-manifest.md does not exist yet)
[B] Run /vertical-slice — build the Vertical Slice (do this before writing epics — validate fun first)
[C] Write more ADRs first — run /architecture-decision [next-system]
[D] Stop here for this session
```

```
门禁已通过。接下来你想做什么？
[A] 运行 /create-control-manifest——根据你的 Accepted ADR 生成层级规则清单（若 docs/architecture/control-manifest.md 尚不存在，应最先做这一步）
[B] 运行 /vertical-slice——构建 Vertical Slice（在撰写史诗之前做这一步——先验证好玩与否）
[C] 先撰写更多 ADR——运行 /architecture-decision [next-system]
[D] 本次会话到此为止
```

> **Note for the Technical Setup → Pre-Production PASS**: The Pre-Production sequence is deliberately ordered
> to validate fun before committing to detailed planning:
>
> 1. `/create-control-manifest` — extract technical rules from Accepted ADRs, if not done yet (`/create-epics` requires it at `full`)
> 2. `/vertical-slice` — build the Vertical Slice **FIRST**, before writing epics or stories
> 3. Playtest → `/playtest-report` — at least 1 documented session, 3+ better before committing the full team. `/gate-check production` treats the slice as recommended: skipped → CONCERNS, unplayed → NOT ASSESSED
> 4. `/ux-design [screen]` — UX specs for main menu, core HUD, pause menu (if not done)
> 5. `/create-epics layer:foundation` then `/create-epics layer:core` — plan after fun is validated
> 6. `/create-stories [epic-slug]` for each epic
> 7. `/sprint-plan new`
>
> **Why prototype before epics?** If the prototype reveals the core loop needs to change,
> epics written before that discovery will be partially wrong. Validate fun cheaply first,
> then plan in detail. This is the #1 lesson from GDC postmortem data.

> **Technical Setup → Pre-Production PASS 的说明**：Pre-Production 的顺序是有意排定的，目的是在投入详细规划之前先验证好玩与否：
>
> 1. `/create-control-manifest`——从 Accepted ADR 中提取技术规则，若尚未完成（`/create-epics` 在 `full` 下要求它）
> 2. `/vertical-slice`——**首先**构建 Vertical Slice，在撰写史诗或故事之前
> 3. 试玩 → `/playtest-report`——至少 1 次有记录的试玩会话，在投入完整团队之前达到 3 次以上更好。`/gate-check production` 将切片视为建议项：跳过 → CONCERNS，未被玩过 → NOT ASSESSED
> 4. `/ux-design [screen]`——为主菜单、核心 HUD、暂停菜单编写 UX 规格（若尚未完成）
> 5. `/create-epics layer:foundation` 然后 `/create-epics layer:core`——在好玩性得到验证之后再规划
> 6. 为每个史诗运行 `/create-stories [epic-slug]`
> 7. `/sprint-plan new`
>
> **为什么在撰写史诗之前先做原型？** 如果原型揭示核心循环需要改变，那么在该发现之前写下的史诗会部分出错。先以低成本验证好玩性，然后再做详细规划。这是 GDC 复盘数据中的头号教训。

For all other gates, offer the two most logical next steps for that phase plus "Stop here".

对于所有其他门禁，提供该阶段最合乎逻辑的两个下一步，外加"Stop here"（到此为止）。

---

## 8. Follow-Up Actions

## 8. 后续行动

Based on the verdict, suggest specific next steps:

根据裁定，建议具体的下一步：

- **No art bible?** → `/art-bible` to create the visual identity specification
- **Art bible exists but no asset specs?** → `/asset-spec system:[name]` to generate per-asset visual specs and generation prompts from approved GDDs
- **No game concept?** → `/brainstorm` to create one
- **No systems index?** → `/map-systems` to decompose the concept into systems
- **Missing design docs?** → `/reverse-document` or delegate to `game-designer`
- **Small design change needed?** → `/quick-design` for changes under about one week of implementation (bypasses full GDD pipeline)
- **No UX specs?** → `/ux-design [screen name]` to author specs, or `/team-ui [feature]` for full pipeline
- **UX specs not reviewed?** → `/ux-review [file]` or `/ux-review all` to validate
- **No accessibility requirements doc?** → `/ux-design accessibility` to write `design/accessibility-requirements.md`
- **No interaction pattern library?** → `/ux-design patterns` to initialize it
- **Concept or a GDD not reviewed?** → `/design-review [doc]`
- **GDDs not cross-reviewed?** → `/review-all-gdds` (run after all MVP GDDs are individually approved)
- **Cross-GDD consistency issues?** → fix flagged GDDs, then re-run `/review-all-gdds`
- **No test framework?** → `/test-setup` to scaffold the framework for your engine
- **No QA plan for current sprint?** → `/qa-plan sprint` to generate one before implementation begins
- **Missing ADRs?** → `/architecture-decision` for individual decisions
- **No master architecture doc?** → `/create-architecture` for the full blueprint
- **ADRs missing engine compatibility sections?** → Re-run `/architecture-decision`
  or manually add Engine Compatibility sections to existing ADRs
- **Missing control manifest?** → `/create-control-manifest` (requires Accepted ADRs)
- **Missing epics?** → `/create-epics layer: foundation` then `/create-epics layer: core` (requires control manifest)
- **Missing stories for an epic?** → `/create-stories [epic-slug]` (run after each epic is created)
- **Stories not implementation-ready?** → `/story-readiness` to validate stories before developers pick them up
- **Tests failing?** → delegate to `lead-programmer` or `qa-tester`
- **No playtest data?** → `/playtest-report`
- **No playtest sessions beyond the minimum?** → Additional sessions give more reliable signal. 3+ total is recommended before committing the full team. Use `/playtest-report` to structure findings.
- **No Difficulty Curve doc?** → Author `design/difficulty-curve.md` by hand from the template at `.claude/docs/templates/difficulty-curve.md`. (`/quick-design` is a related session but writes to `design/quick-specs/`, not to this path — use it to think the curve through, then copy the outcome here.)
- **No player journey map?** → Author `design/player-journey.md` by hand from the template at `.claude/docs/templates/player-journey.md`.

- **没有美术圣经？** → 运行 `/art-bible` 来创建视觉标识规格
- **美术圣经存在但没有资产规格？** → 运行 `/asset-spec system:[name]`，根据已批准的 GDD 生成逐资产的视觉规格与生成提示词
- **没有游戏概念？** → 运行 `/brainstorm` 创建一个
- **没有系统索引？** → 运行 `/map-systems` 把概念分解为系统
- **缺少设计文档？** → 运行 `/reverse-document`，或委派给 `game-designer`
- **需要小幅设计变更？** → 对实现量约一周以内的变更使用 `/quick-design`（绕过完整的 GDD 流程）
- **没有 UX 规格？** → 用 `/ux-design [screen name]` 撰写规格，或用 `/team-ui [feature]` 走完整流程
- **UX 规格未评审？** → 用 `/ux-review [file]` 或 `/ux-review all` 进行验证
- **没有无障碍需求文档？** → 运行 `/ux-design accessibility` 写出 `design/accessibility-requirements.md`
- **没有交互模式库？** → 运行 `/ux-design patterns` 初始化它
- **概念或某个 GDD 未评审？** → 运行 `/design-review [doc]`
- **GDD 未做交叉评审？** → 运行 `/review-all-gdds`（在所有 MVP GDD 均单独获批之后运行）
- **跨 GDD 一致性问题？** → 修复被标记的 GDD，然后重跑 `/review-all-gdds`
- **没有测试框架？** → 运行 `/test-setup` 为你的引擎搭建框架
- **当前冲刺没有 QA 计划？** → 运行 `/qa-plan sprint`，在实现开始前生成一份
- **缺少 ADR？** → 用 `/architecture-decision` 逐项撰写决策
- **没有总体架构文档？** → 运行 `/create-architecture` 获取完整蓝图
- **ADR 缺少引擎兼容性章节？** → 重跑 `/architecture-decision`，或手动为现有 ADR 添加 Engine Compatibility 章节
- **缺少控制清单？** → 运行 `/create-control-manifest`（需要 Accepted ADR）
- **缺少史诗？** → 先 `/create-epics layer: foundation` 再 `/create-epics layer: core`（需要控制清单）
- **某个史诗缺少故事？** → 运行 `/create-stories [epic-slug]`（每创建一个史诗后运行）
- **故事尚未达到可实现状态？** → 运行 `/story-readiness`，在开发者领取之前验证故事
- **测试失败？** → 委派给 `lead-programmer` 或 `qa-tester`
- **没有试玩数据？** → 运行 `/playtest-report`
- **试玩会话未超过最低要求？** → 更多会话能带来更可靠的信号。在投入完整团队之前建议至少 3 次。用 `/playtest-report` 来组织发现。
- **没有难度曲线文档？** → 依据 `.claude/docs/templates/difficulty-curve.md` 的模板手工撰写 `design/difficulty-curve.md`。（`/quick-design` 是一个相关的会话，但它写入 `design/quick-specs/`，而不是这个路径——可用它把曲线想清楚，再把结果复制到这里。）
- **没有玩家旅程地图？** → 依据 `.claude/docs/templates/player-journey.md` 的模板手工撰写 `design/player-journey.md`。

> **Neither of these has a skill that writes it — do not name one.**
> "`/ux-design` Phase 2b" is the step that *reads* `design/player-journey.md`,
> so it lands the user back at the check that just failed. `/quick-design`
> writes `design/quick-specs/[name]-[date].md` and leaves this gate still
> failing. Say plainly that both docs are hand-authored from their templates.

> **这两者都没有能写入它们的技能——不要点名任何技能。** "`/ux-design` Phase 2b" 是*读取* `design/player-journey.md` 的步骤，因此它会让用户回到刚刚失败的那项检查。`/quick-design` 写入 `design/quick-specs/[name]-[date].md`，会让本门禁仍然失败。要直说这两份文档都是根据其模板手工撰写的。

- **Need a quick sprint check?** → `/sprint-status` for current sprint progress snapshot
- **Performance unknown?** → `/perf-profile`
- **Not localized?** → `/localize`
- **No security audit, or open CRITICAL/HIGH findings?** → `/security-audit` (after fixes, `/security-audit quick` to confirm)
- **Ready for release?** → `/launch-checklist`

- **需要快速查看冲刺状态？** → 用 `/sprint-status` 获取当前冲刺进度快照
- **性能未知？** → 运行 `/perf-profile`
- **未本地化？** → 运行 `/localize`
- **没有安全审计，或存在未关闭的 CRITICAL/HIGH 发现？** → 运行 `/security-audit`（修复之后，用 `/security-audit quick` 确认）
- **准备发布？** → 运行 `/launch-checklist`

---
