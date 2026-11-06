# /adopt — Phase 4: Build the Migration Plan

# /adopt — 阶段 4：构建迁移计划

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/adopt` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## Phase 4: Build the Migration Plan

## 阶段 4：构建迁移计划

Compose a numbered, ordered action plan. Ordering rules:
1. BLOCKING gaps first (must fix before any pipeline skill runs reliably)
2. HIGH gaps next, infrastructure before GDD/ADR content (bootstrapping needs correct formats)
3. MEDIUM gaps ordered: GDD gaps before ADR gaps before story gaps (stories depend on GDDs and ADRs)
4. LOW gaps last

编写一份带编号、有顺序的行动计划。排序规则：
1. 先处理阻断缺口（必须在任何流水线技能可靠运行之前修复）
2. 其次是高缺口，基础设施先于 GDD/ADR 内容（引导需要正确的格式）
3. 中缺口的顺序：GDD 缺口先于 ADR 缺口，再先于故事缺口（故事依赖于 GDD 和 ADR）
4. 低缺口最后

For each gap, produce a plan entry with:
- A clear problem statement (one sentence, no jargon)
- The exact command to fix it, if a skill handles it
- Manual steps if it requires direct editing
- A time estimate (rough: 5 min / 30 min / 1 session)
- A checkbox `- [ ]` for tracking

对于每个缺口，生成一条计划条目，包含：
- 清晰的问题陈述（一句话，不用行话）
- 如果由某个技能处理，给出修复它的确切命令
- 如果需要直接编辑，给出手动步骤
- 时间估算（粗略：5 分钟 / 30 分钟 / 1 个会话）
- 用于跟踪的复选框 `- [ ]`

**Special case — systems-index parenthetical status values:**
This is always the first item if present. Show the exact values that need changing
and the exact replacement text. Offer to fix this immediately before writing the plan.

**特殊情况 —— systems-index 中带括号的状态值：**
如果存在，这始终是第一项。显示需要修改的确切值以及确切的替换文本。在编写计划之前，提供立即修复的选项。

**Special case — ADRs missing Status field:**
For each affected ADR, the fix is:
`/architecture-decision retrofit docs/architecture/adr-[NNNN]-[slug].md`
List each ADR as a separate checkable item.

**特殊情况 —— ADR 缺少 Status 字段：**
对于每个受影响的 ADR，修复方式是：
`/architecture-decision retrofit docs/architecture/adr-[NNNN]-[slug].md`
将每个 ADR 列为单独的可勾选条目。

**Special case — GDDs missing sections:**
For each affected GDD, list which sections are missing and the fix:
`/design-system retrofit design/gdd/[filename].md`

**特殊情况 —— GDD 缺少章节：**
对于每个受影响的 GDD，列出缺失的章节以及修复方式：
`/design-system retrofit design/gdd/[filename].md`

**Infrastructure bootstrap ordering** — always present in this sequence:
1. Fix ADR formats first (registry depends on reading ADR Status fields)
2. Run `/architecture-review` → bootstraps `tr-registry.yaml`
3. Run `/create-control-manifest` → creates manifest with version stamp
4. Run `/sprint-plan update` → creates `sprint-status.yaml`
5. Run `/gate-check [phase]` (the gate into the phase the project is in; at Concept there is none — Concept is the default stage, nothing to run) → writes `project.stage` in `project.yaml` (and legacy `stage.txt`) authoritatively

**基础设施引导顺序** —— 始终按此顺序呈现：
1. 先修复 ADR 格式（注册表依赖于读取 ADR 的 Status 字段）
2. 运行 `/architecture-review` → 引导生成 `tr-registry.yaml`
3. 运行 `/create-control-manifest` → 创建带版本戳的清单
4. 运行 `/sprint-plan update` → 创建 `sprint-status.yaml`
5. 运行 `/gate-check [phase]`（通往项目当前所在阶段的门禁；在概念阶段没有门禁 —— 概念是默认阶段，无需运行任何东西）→ 以权威方式写入 `project.yaml` 中的 `project.stage`（以及旧版 `stage.txt`）

**At `workflow: minimal` the plan prescribes none of this sequence.** None of it
is on the minimal path: ADRs are not expected, the brief's build order is the
plan (no `/sprint-plan`), and nothing there runs `/gate-check`. The plan's
Step 3 says so in one line and names the path's next step instead —
`/create-stories` when no stories exist, else `/dev-story`.

**在 `workflow: minimal` 下，计划不规定此序列中的任何一步。** 它们都不在 minimal 路径上：不期望有 ADR，简报的构建顺序就是计划（没有 `/sprint-plan`），并且那里没有任何东西会运行 `/gate-check`。计划的第 3 步用一行说明这一点，并改为指出该路径的下一步 —— 在没有故事时是 `/create-stories`，否则是 `/dev-story`。

**Existing stories** — note explicitly:
> "Existing stories continue to work with all template skills — all new format
> checks auto-pass when the fields are absent. They won't benefit from TR-ID
> staleness tracking or manifest version checks until they're regenerated. This
> is intentional: do not regenerate stories that are already in progress."

**现有故事** —— 明确说明：
> "现有故事继续与所有模板技能兼容 —— 当字段缺失时，所有新的格式检查都会自动通过。在它们被重新生成之前，它们不会从 TR-ID 陈旧度跟踪或清单版本检查中受益。这是有意为之：不要重新生成已经在进行中的故事。"

---
