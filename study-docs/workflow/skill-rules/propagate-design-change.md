# propagate-design-change — GDD 变更影响传播（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/propagate-design-change/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/propagate-design-change [path/to/changed-gdd.md] [--review full|lean|solo]`
- **一句话职责**：GDD 变更后，找出因此变陈旧的架构决策（ADR，Architecture Decision Record），逐个比较"ADR 当初假设了什么"与"GDD 现在说什么"，并带用户走完每个 ADR 的处置
- **触发前置**：用户改了 GDD 里的数字或规则并问哪些 ADR/架构决策过时。**档位规则**：`workflow` 取被改 GDD 系统的 `system_overrides` 行（无则项目值）——`minimal` 钉死的系统即使身在 `standard` 项目也无 ADR 可查；`full` 查全部 ADR；`standard` 查关键（Foundation 层）ADR + 点名该 GDD 的 ADR；`minimal` 无可查（Phase 4 直接结束）

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `review_mode, review_gate, automation, automation_always_ask, workflow, system_overrides` | `--review` 覆盖 `review_mode`；`review_gate` 的 `skill-gates` 决定 TD-CHANGE-IMPACT 是否运行 |
| 读取 | 被改 GDD 的 git diff（`git diff HEAD --` / `git diff HEAD~1 HEAD --` / `git log`） | **问 git，绝不肉眼比对整文档** |
| 读取 | `design/registry/entities.yaml`（存在且有条目时） | 搜 `source: design/gdd/[filename]`，用 `referenced_by:` 找下游 GDD |
| 执行 | `bash .claude/scripts/adr-status.sh` | 列每个 ADR 的 status/layer/missing sections；`md-section.sh extract/replace` 按节读写 |
| 产出 | ADR 的 `## Status` 节改写（Superseded）、`docs/architecture/requirements-traceability.md` 增行、`docs/architecture/change-impact-[date]-[system-slug].md` | Status 改写是**本技能写的唯一形式** |
| 派生智能体 | `technical-director`（TD-CHANGE-IMPACT 门禁，仅 `skill-gates=run`） | 审查影响报告；**不编辑任何文件** |

**提问协议**：用问题工具提问；无此工具则列编号选项并结束回合等待；被跳过/关闭的问题不是答案——纯文本再问。`automation_always_ask` 类别（本技能中 ADR 影响属 `schema_changes` 与 `architecture_decisions`）恒问。

## 3. 核心规则（逐条编号 R1、R2……）

**Phase 1-2 找变更**
R1. 技能名后的文本（剥掉 `--review <mode>` 对）即被改 GDD 路径，**必需**：缺失报用法 "Usage: `/propagate-design-change design/gdd/[system].md` — give the path to the GDD that changed."；路径不是文件报 "[path] not found. Check the path and try again."
R2. **问 git，绝不肉眼比较两个整文档**：`git diff HEAD -- design/gdd/[filename].md`；为空则扩大到最后一次触及该文件的提交 `git diff HEAD~1 HEAD -- …`。完全无历史（`git log --oneline -1 -- …` 无输出）："No previous version in git — this is a new GDD, not a revision. Nothing to propagate." **停止**。有历史但两个 diff 都空：报告 "no uncommitted or last-commit changes to [file]" 并问要传播哪个修订——空 diff 意味"此处没改"，**不意味"无受影响项"**。
R3. **变更节列表来自 diff 本身**：`@@` 头命名每个变更所在的节；无 hunk 的节按构造即未变。只有当某个 hunk 无法独立理解（改的数字其含义取决于上方规则）才读周围节，且**只读那一节**（`md-section.sh extract design/gdd/[file].md "[Section]"`）。

**Phase 3 变更摘要**
R4. 产出 Change Summary，结构为：
   - `## Change Summary: [GDD filename]` + `Date of revision: [today]`
   - **Changed sections**：每节一条，注明改了什么（新规则 / 删规则 / 公式修改…）
   - **Unchanged sections**：列出
   - **Key changes affecting architecture**：可能影响 ADR 的变更
R5. **下游 GDD**：`entities.yaml` 不存在或无条目（发布时是空 stub，直到 `/design-system` 填充）则跳过——但 ADR 检查照跑。否则搜 `source: design/gdd/[filename]`：本 GDD 拥有且值被 diff 改动的每个实体/常量/公式，其 `referenced_by:` 列表即"现在可能不一致"的 GDD，列在 "Downstream GDDs to re-check" 之下。

**Phase 4 圈定 ADR 范围**
R6. `adr-status.sh` 列全部 ADR（status/layer/missing）。按档取范围：`full`=全部；`standard`=关键者（`layer` 列读 Foundation，或无层值——**有疑问即关键**）+ 点名被改 GDD 的 ADR；`minimal`：报 "No ADR check at minimal workflow — design change recorded; no architecture impact analysis." **停止**。**先立分母 N**；N=0："No ADRs found in `docs/architecture/` — nothing to check." **停止**。
R7. **找引用（不读整 ADR）**：① 每个 ADR 的 "GDD Requirements Addressed" 节（`md-section.sh extract`）里点名被改 GDD 的行；② 在 ADR 里全文搜被改 GDD 的文件名（抓住正文引用而无表行的）。两者**并集 = 受影响集 M**。三种结果：

   | 结果 | 含义 | 行动 |
   |---|---|---|
   | **M ≥ 1** | 正常 | 继续；其余 N−M 个**只说"不在本次检查范围"，绝不描述为"已验证不受影响"** |
   | **M = 0** 且所有范围内 ADR 缺 GDD Requirements Addressed 节 | 追踪性不可计算 | "[N] ADRs found, none has a 'GDD Requirements Addressed' section — traceability cannot be computed (a pre-production gate blocker). Run `/architecture-decision retrofit [adr]`." **停止** |
   | **M = 0** 且节都在 | 无 ADR 引用此 GDD | "No ADR references [gdd] — no architecture impact." **停止** |

   存在 `docs/architecture/requirements-traceability.md` 时读它。报告："Checked [N] ADRs. [M] reference [gdd filename] ([X] in a requirements table, [Y] in prose only)."

**Phase 5-6 影响分析与审查**
R8. 对 M 中每个 ADR：用 `md-section.sh extract` 读其 **Context、Decision、Consequences** 三节——**决策是否仍成立需要其推理，绝不仅看表行**；再对它列出的每条来自被改 GDD 的需求回答：需求还在吗？ADR 写时 GDD 说什么、现在说什么？决策仍成立吗？三态分类：✅ **Still Valid**（变更不触及该 ADR 决定的事）、⚠️ **Needs Review**（可能受影响，需人判断）、🔴 **Likely Superseded**（变更与该 ADR 的假设矛盾）。每个 ADR 按固定五段式报告：
   - `### ADR-NNNN: [title]` + `Status: [Still Valid | Needs Review | Likely Superseded]`
   - **What the ADR assumed about this GDD**：从其 GDD Requirements Addressed 或 Context 引用原文
   - **What the GDD now says**：从当前 GDD 引用原文
   - **Assessment**：决策是否仍成立及原因
   - **Recommended action**：`Keep as-is | Review and update | Mark Superseded and write a new ADR`
R9. **先展示完整报告再问任何行动**（Design Change Impact Report：GDD、日期、Changes detected: N sections changed、ADRs referencing: M、Not Affected / Needs Review ([count]) / Likely Superseded ([count]) 三分组）。
R10. **技术审查**：`review_gate` 为 `skill-gates=skip`（solo/lean）——不派 agent，注记 `TD-CHANGE-IMPACT skipped — [Solo | Lean] mode`。`skill-gates=run`——交给 `technical-director` 跑 **TD-CHANGE-IMPACT** 门禁（agent 自己读门禁文件；简报=目标（用户行动前审查报告）、给整份报告（变更摘要+每个受影响 ADR 的分类与建议）、检查点（无 ADR 被低估、建议行动合理、无对其他 ADR/系统的连锁效应遗漏）、返回 APPROVE / CONCERNS / REJECT / NOT ASSESSED、边界（**不编辑任何文件**））。
R11. 裁决处理：**APPROVE**→进 Phase 7。**CONCERNS**→展示被点名的 ADR/行动并问 "How do you want to go on?"（Revise the impact assessment / Accept with the noted concerns / Discuss further）。**REJECT**→**不进 Phase 7**，先重新分析影响。**NOT ASSESSED 不是批准**：命名缺失输入、补齐重跑；或用户选择带病继续时进 Phase 7，但在报告和最终 Verdict 行声明 `TD-CHANGE-IMPACT: NOT ASSESSED — [input]`。

**Phase 7-10 处置与收尾**
R12. 对每个 Needs Review / Likely Superseded 的 ADR **一次一个**问："ADR-NNNN ([title]) — [status]. What would you like to do?" 选项：`Mark it Superseded (I'll write the new ADR)` / `Update it in place`（注明要改什么，用户自己改）/ `Keep it as it is` / `Skip it for now`。
R13. **Mark Superseded**：先问 "May I set the Status of [ADR file] to Superseded?"，yes 后**只替换其 `## Status` 节的正文**为 `Superseded — replacement pending (see docs/architecture/change-impact-[date]-[system-slug].md)`（用 `md-section.sh replace`）。**这是本技能写的唯一形式**：`adr-status.sh` 会读出 Superseded，从而让 `/dev-story` 与 `/create-stories` 阻塞仍指向它的 stories；新 ADR 写成后记录它替换了哪一个。**ADR 的其余内容一字不动**。
R14. `docs/architecture/requirements-traceability.md` 存在时问 "May I add the changed requirements to the traceability index?"，yes 则为每条被改需求加一行（`## Superseded Requirements` 表：`Date | GDD | Requirement | Changed To | ADRs Affected | Resolution`）。
R15. 问 "May I write the change impact report to `docs/architecture/change-impact-[date]-[system-slug].md`?"——内容含变更摘要、影响分析、每个 ADR 的处置、待写/待改的 ADR。写完后按处置给跟进：Superseded→"Run `/architecture-decision [title]` to write the replacement, then `/propagate-design-change` again to check coverage."；就地更新→列出各 ADR 要改的字段；多 ADR 受影响→"Run `/architecture-review` once they are updated, to check the traceability matrix still holds together."
R16. 收尾 Verdict：Phase 9 写盘成功后 `Verdict: COMPLETE — change impact report saved`；用户拒绝写盘则 `Verdict: BLOCKED — user declined the write`。

## 4. 门禁与裁决（如适用）
- **TD-CHANGE-IMPACT**：审查者 `technical-director`（自读 `.claude/docs/director-gates/td-change-impact.md`）；裁决词 APPROVE / CONCERNS / REJECT / NOT ASSESSED；处理见 R11；**NOT ASSESSED 永远不是批准**；边界——门禁 agent 不编辑文件。开关：`review_gate` 的 `skill-gates=skip`（solo/lean，注记跳过）/ `run`（正常派发）。
- **ADR 三态分类**（非门禁，主会话判定）：Still Valid / Needs Review / Likely Superseded（R8）。
- **范围判定**：M=0 的三种结局（继续 / 追踪性不可计算 / 无影响停止）见 R7。

## 5. 移植建议
- **可直接移植**：R2-R3（变更集来自 git diff 而非肉眼比对、`@@` 头即变更节清单）、R6-R7（分母 N 先立、范围外 ≠ 已验证无影响、追踪性缺失即阻塞并指路）、R8（读决策的推理而非仅表行）、R9（完整报告先于任何行动请求）、R11（NOT ASSESSED 不是批准）、R13（只改 Status 节、其余内容不动、让下游流程自然阻塞）。
- **需替换概念**：GDD → 需求/接口规格文档；ADR → 技术决策记录（ADR 本身通用，多数项目已有）；`adr-status.sh` / `md-section.sh` → ADR 索引脚本与按节读写工具；`entities.yaml` 的 `referenced_by` → 接口/常量的消费者清单；`/architecture-decision retrofit`、`/architecture-review` → 决策补录与决策审查流程。
- **改写示例**：
  - "规格文档变更后，用 `git diff` 取变更集：hunk 头命名的节即变更节清单，无 hunk 的节按构造未变；只有 hunk 无法独立理解时才读其所在节。禁止肉眼比对两份完整文档来找差异。"
  - "受影响决策集 M 之外的 N−M 个决策只能说『不在本次检查范围』，禁止表述为『已验证不受影响』；所有决策都缺需求追踪节时，判定追踪性不可计算并阻塞——补录追踪关系后重跑。"

## 6. 关联文档
- 上游：`/design-system`（GDD 作者，填充 entities.yaml）、`/quick-design`（小改动则可能改 GDD）
- 下游：`/architecture-decision`（写替代 ADR / retrofit 补录）、`/architecture-review`（更新后查追踪矩阵）、`/dev-story`、`/create-stories`（读取 Superseded 状态以阻塞 story）
- 引用：`.claude/docs/director-gates.md`、`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/scripts/adr-status.sh`、`.claude/scripts/md-section.sh`、`docs/architecture/requirements-traceability.md`
