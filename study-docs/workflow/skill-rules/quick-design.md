# quick-design — 小改动轻量规格（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/quick-design/SKILL.md) ｜ 阶段：Phase 2+ ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/quick-design [brief description of the change]`
- **一句话职责**：为不需要完整 GDD 的小改动（约一周实施量以内）写轻量规格，直接嵌入 stories，跳过完整设计流程
- **触发前置**：改动"对 `/design-system` 太小、但不写书面理由就实施又太有意义"的任何时刻；配置键 `automation, workflow`（resolve_config）。多数微调是小时级；**一周上限是 New Small System 类别的限额**

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `design/gdd/` 下最相关的 GDD（只读受影响节） | 无 GDD 覆盖（常见于 `workflow: minimal`，brief+stories 即设计记录）时读 brief 相关行与所涉 story，报 "No GDD for [system] — using the brief and [story path]"，brief 作为 GDD Reference |
| 读取 | `design/gdd/systems-index.md`（若存在） | 了解系统在依赖图中的位置与所属档位；不存在则记 "No systems index found — skipping dependency tier check." 后继续 |
| 读取 | `design/quick-specs/` 先前规格 | 避免与本系统既有规格矛盾 |
| 读取 | `assets/data/` 数据文件（仅 Tuning 类） | 找到持有相关值的文件 |
| 产出 | `design/quick-specs/[kebab-case-title]-[YYYY-MM-DD].md` | 按类别三种模板之一；目录不存在则创建 |
| 派生智能体 | 无，主会话直接执行 | — |

**提问协议**：每个 AskUserQuestion 遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大决策 · autonomous 记录后继续；`automation_always_ask` 类别恒问）。

## 3. 核心规则（逐条编号 R1、R2……）

**第 1 步：分类**
R1. 先读参数判定改动类别：

| 类别 | 判据 | 示例 |
|------|------|------|
| **Tuning** | 改既有系统的数字/平衡值，无行为变化（最小路径） | "跳跃高度 5→6 单位"、"敌巡逻速度 -10%" |
| **Tweak** | 对既有系统的小行为变化，不引入新状态/分支/系统 | "冲刺第 1 帧无敌"、"连招可取消进翻滚" |
| **Addition** | 给既有系统加小机制，可能引入 1-2 个新状态/交互 | "格挡加招架窗口"、"普攻加蓄力变体" |
| **New Small System** | 独立特性，小到没有既有 GDD、约一周实施量以内 | "成就弹窗系统"、"简单昼夜视觉循环" |
R2. **越界即重定向**：改动引入带重大跨系统依赖的新系统、需一周以上实施、或根本改变既有系统核心规则——停止并转 `/design-system`，`Verdict: REDIRECTED — use /design-system for this change.`。无参数时先纯文本请用户描述改动再分类。
R3. 用 AskUserQuestion 呈现推断分类："I've classified this as **[inferred type]** — [brief reason]. Is that correct?"，选项 `[A] Yes` / `[B] Tuning` / `[C] Tweak` / `[D] Addition` / `[E] New Small System` / `[F] This is too large — redirect me to /design-system`；选 [F] 即停止（REDIRECTED），否则按所选类别继续。

**第 2 步：上下文扫描**
R4. 起草前读相关上下文（GDD 与索引按节读：Grep `^#` 定位、Read 范围），并**报告找到了什么**："Found GDD at [path]. Relevant section: [section name]. Prior quick specs for this system: [each path, and whether it agrees or conflicts with this change — or 'none']."——**即使先前规格与本次一致也要逐个点名**：只说 "no conflicts" 读起来与"没有先前规格"完全相同。

**第 3 步：按类别起草**
R5. **Tuning 用单表规格**（头部：`Type: Tuning` / `System` / `GDD Reference: design/gdd/[filename].md — Tuning Knobs section` / `Date`）：表头 `Parameter | Old Value | New Value | Rationale`；附 **Tuning Knob Mapping**（映射到 GDD 的哪个 Tuning Knob 及其文档化范围；声明新值 within / at the edge of / outside 该范围，outside 须解释为何扩 range）；验收标准：参数从 `assets/data/[file]` 读出新值、行为差异在具体场景可观察、相关行为无回归。
R6. **Tweak/Addition 用差异规格**（头部：`Type: [Tweak / Addition]` / `System` / `GDD Reference` / `Date`），六节：
   - **Change Summary**：1-2 句说清改什么、为什么
   - **Motivation**：解决什么玩家体验问题，可引 MDA 审美或玩家反馈
   - **Design Delta**：先逐字引用现有 GDD 相关规则，再写替换规则——**精度须与 GDD Detailed Rules 节相同：程序员仅凭此文本即可实现**
   - **New Rules / Values**：完整无歧义的替换内容；引入新状态逐一列出；新参数定义范围
   - **Affected Systems** 表：`System | Impact | Action Required`（update GDD / update data file / no action）
   - **Acceptance Criteria**（具体可测试条目 + 一条无回归）+ **GDD Update Required?**（Yes/No；Yes 时写明哪个文件哪节、更新应说什么）
R7. **New Small System 用裁剪版 GDD**：只留直接必要节——**跳过 Player Fantasy、完整 Formulas、Edge Cases**（除非系统确需）；Overview（新队员能懂的一段）；Core Rules（顺序行为用编号、条件用 bullet，精确到程序员无需提问）；Tuning Knobs 表（`Knob | Default | Range | Category (feel/curve/gate) | Rationale`）——**所有值必须放 `assets/data/[appropriate-file].json`，禁止硬编码**；验收标准（功能对/边界情况/体验对——playtest 验证/不破坏相邻系统）；Systems Index 小节（建议加入索引时给出层与优先级档；太小时声明 "This system is below systems-index tracking threshold — quick spec is sufficient."）。

**第 4 步：批准与归档**
R8. 完整呈现草案后问："Here's the Quick Design Spec draft. How do you want to proceed?"（`[A] Approve — write it as shown` / `[B] Revise — I'll describe what to change` / `[C] This grew too large — redirect to /design-system instead`）；[B] 收集修改、改稿、重新呈现同一问题；[C] 停止（REDIRECTED）。
R9. 批准后再单独问写盘："May I write this Quick Design Spec to `design/quick-specs/[kebab-case-title]-[YYYY-MM-DD].md`?"——文件名用**当天日期**与 kebab-case 标题（如 `jump-height-tuning-2026-03-10`）；同意后按需创建 `design/quick-specs/` 目录再写文件。
R10. **GDD 更新单独授权**：规格标记了 GDD Update Required 时，写完规格后**再单独问**："This spec modifies rules in [System Name]. May I update `design/gdd/[filename].md` — specifically the [section name] section?"——**问之前必须展示将改动的确切文本（旧 vs 新）；未经明确批准禁止做任何 GDD 编辑**。

**第 5 步：交接**
R11. 写盘后输出交接块，字段依次为：
   ```
   Quick Design Spec written to: design/quick-specs/[filename].md
   Type: [Tuning / Tweak / Addition / New Small System]
   System: [system name]
   GDD update: [Required — pending approval / Applied / Not required]
   Next step: This spec is ready for /story-readiness validation before implementation
   (at workflow: minimal, go straight to /dev-story). Reference this spec in the story's GDD Reference field.
   ```
   `Verdict: COMPLETE — quick design spec written and ready for implementation.` 推荐后续：跑 `/story-readiness [story-path]` 验证（`rigor: minimal` 跳过、`/dev-story` 直接）并在 story 的 GDD Reference 字段引用本规格；通过后 `/dev-story [story-path]` 实施；改动比预期大则 `/design-system [system-name]` 改写完整 GDD。

**管道边界**
R12. Quick Design Specs **按设计绕过** `/design-review` 与 `/review-all-gdds`——为小、低风险、范围明确的改动而生，此时全量审查管道的成本超过改动风险。
R13. **升级回全管道的触发条件**（任一为真即建议转 `/design-system`）：改动新增了应入系统索引的系统；显著改变跨系统行为或系统对外的契约；引入影响游戏 MDA 审美平衡的新玩家面向机制；实施可能超一周。此时说："This change has grown beyond quick-spec scope. I recommend using `/design-system` to author a full GDD for this."

## 4. 门禁与裁决（如适用）
（SKILL.md 无门禁——本技能刻意不设审查门禁，以 R12/R13 的边界规则替代；唯一裁决词是 `Verdict: COMPLETE / REDIRECTED`。）

## 5. 移植建议
- **可直接移植**：R1-R3（四类分级+越界重定向+分类确认问）、R4（点名既有规格而非只说"无冲突"）、R8-R10（三段式授权：批准稿→写盘→改源文档各自单独问，改前展示旧 vs 新）、R12-R13（轻量路径的豁免边界与升级触发条件）。
- **需替换概念**：Tuning/Tweak/Addition/New Small System → 配置变更/行为微调/小功能追加/独立小模块；GDD 与 Tuning Knobs → 规格书与配置项；`/design-review`、`/review-all-gdds` → 正式评审流程；`/story-readiness`、`/dev-story` → 任务准入检查、实施流程；MDA 审美平衡 → 用户体验平衡。
- **改写示例**：
  - "改动分四类（改配置值 / 小行为变化 / 加小功能 / 独立小模块）；凡引入重大跨模块依赖、超一周工作量或改写既有核心规则者，必须停止并转完整规格流程（Verdict: REDIRECTED）。"
  - "轻量规格按设计豁免正式评审；但新增应入架构清单的模块、改变模块对外契约、或实施超一周时，必须升级回完整流程——豁免有边界，边界用触发条件写死。"

## 6. 关联文档
- 上游/替代：`/design-system`（重量级路径，越界时重定向目标）
- 下游：`/story-readiness`（验证后实施）、`/dev-story`（minimal 档直接实施）
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/templates/`（GDD 模板，New Small System 裁剪自它）
