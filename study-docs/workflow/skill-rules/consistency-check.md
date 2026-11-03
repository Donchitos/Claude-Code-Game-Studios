# consistency-check — 跨文档一致性扫描（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/consistency-check/SKILL.md) ｜ 阶段：Phase 2+ ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/consistency-check [full | since-last-review | entity:<name> | item:<name>]`
- **一句话职责**：把全部 GDD 与实体登记表（entity registry，`design/registry/entities.yaml`）对照，检出跨文档不一致——grep 优先，只命中注册名的节，不做全文读（除非冲突需调查）。
- **触发前置**：`design/registry/entities.yaml` 存在且有条目；配置经 `resolve_config --keys automation,workflow,system_overrides` 解析；`AskUserQuestion` 遵循 `.claude/docs/automation-modes.md`。
- **定位**：这是**写时安全网**——捕获 `/design-system` 每节检查可能漏掉的、`/review-all-gdds` 整体审查发现太晚的。运行时机：写完每份新 GDD 后（进入下一系统前）、`/review-all-gdds` 之前（干净基线）、`/create-architecture` 之前（不一致会毒化下游 ADR）、按需单查一个实体。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `design/registry/entities.yaml`（一次性载入建查找表；写入前重读）；`design/gdd/*.md` 范围内 GDD 的命中行（grep `-C 3`）；冲突 GDD 的冲突节（定向读）；`git log`（since-last-review 模式与 registry 时效判定）；`.claude/scripts/registry.sh`（写入后校验） | 登记表 / 文档集 |
| 产出 | 冲突报告（会话内）；经同意的 registry 修正（`design/registry/entities.yaml`）；`docs/consistency-failures.md` 追加（含建头）；`production/session-state/active.md` 面包屑（静默追加，不存在则创建） | 见 R15-R21 |
| 派生智能体 | 无，主会话直接执行 | grep 优先设计，无需专家 |

resolve_config 配置键及档位影响（`workflow` 按 GDD 的**有效**档施加——`system_overrides` 中该 GDD 系统的行（文件名 stem）覆盖项目值）：
- `full`：对全部 GDD 节做完整实体登记交叉核对。
- `standard`：仅对必需节交叉核对；报告的 Scope 行注明，必需节外为注册名所出的值列入"本档未核"。
- `minimal`：无意义（无 GDD 可查）。

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1 — 参数与 registry 载入
R1. 模式：无参数 / `full`——全部注册条目对全部 GDD；`since-last-review`——仅上次审查报告后修改过的 GDD；`entity:<name>` / `item:<name>`——单查一个实体/物品跨全部 GDD。（Phase 1）
R2. registry 不存在或无条目时：输出 "Entity registry is empty. Run `/design-system` to write GDDs — the registry is populated automatically after each GDD is completed. Nothing to check yet."，裁决 **NOT ASSESSED — entity registry empty** 并停止——未比较任何东西就没有 PASS 可给、也无可写。（Phase 1）
R3. 从 registry 建四个查找表：entity_map（name→source/attributes/referenced_by）、item_map（name→value_gold/weight/…）、formula_map（name→variables/output_range）、constant_map（name→value/unit）；报告 "Registry loaded: [N] entities, [N] items, [N] formulas, [N] constants" 与 Scope。`entity:`/`item:` 指定名不在 registry 时裁决 **NOT ASSESSED — `<name>` is not in the registry**——列出最接近的注册名并停止：查未注册名没有比较任何东西，那不是 PASS。（Phase 1）

### Phase 2 — 定位范围内 GDD
R4. Glob `design/gdd/*.md`，排除非系统 GDD：`game-concept.md`、`systems-index.md`、`game-pillars.md`、`gameplay-tags.md`、`entity-registry.md`、`fixture-swap-ledger.md`、`sound-bible.md` 及任何 `gdd-cross-review-*.md`（`/review-all-gdds` 写在此处的报告）。（Phase 2）
R5. `since-last-review` 模式：`git log --name-only --pretty=format: -- design/gdd/ | grep "\.md$" | sort -u`，限自最近 `design/gdd/gdd-cross-review-*.md` 文件创建日期以来修改的 GDD。扫描前报告范围内 GDD 清单；清单为空（无系统 GDD，或 since-last-review 无变更）时裁决 **NOT ASSESSED — no GDDs in scope**，说明哪个过滤器产出零并停止——扫零份无冲突不是 PASS。（Phase 2）

### Phase 3 — grep 优先冲突扫描
R6. 对每个注册条目 grep 每份范围内 GDD 的条目名（`-C 3` 只取命中行与紧邻上下文），**绝不**全文读——核心优化：50 个实体名 × 10 份 GDD 的定向搜索（每次命中约 10 行）替代 10 × 400 行全读（4,000 行）。（Phase 3）
R7. 有效档为 `standard` 的 GDD 只比较必需节下的命中：对该 GDD 先 grep `^## ` 取标题与行号，把每个名下命中归入其上方最近标题；只比 Overview、Detailed Rules / Detailed Design、Formulas、Edge Cases、Dependencies、Acceptance Criteria 之下的命中，加 Tuning Knobs——仅当 `project.yaml` 设 `workflow_overrides.tuning_knobs: true`（该旗只增不减）。其它节的命中（无旗 Tuning Knobs、Player Fantasy、任何其它节）不产生发现也不入发现记录，但把其中出值的逐项（名、GDD、节）列入报告的 `Not checked at this tier` 行。（Phase 3）
R8. 四类扫描：
   - **3a 实体**——grep 各 GDD，提取实体名近旁的数值属性（计数/成本/时长/范围/速率）、类别属性（类型/档位/类别）、衍生值（合计/输出/结果）及其它注册属性，与 registry 条目比对；registry 说 `A.x = value_A` 而 GDD 说 `A has value_B` → **CONFLICT**；GDD 提及实体但未指定属性 → **NOTE**（无冲突，仅不可验证）。
   - **3b 物品**——提取售价/价值/金币值、重量、堆叠规则、堆叠类别比对。
   - **3c 公式**——提取近旁变量名与输出范围/上限：变量名不同 → **CONFLICT**；输出范围所述不同 → **CONFLICT**。
   - **3d 常量**——提取近旁数值：数字不同 → **CONFLICT**。（Phase 3）

### Phase 4 — 深入调查（仅冲突）
R9. 仅对 Phase 3 找到的冲突做定向全文节读（Grep `^#` 定位冲突节 + Read offset/limit；文件大时用更宽上下文的 grep）确认冲突，并回答三问定责：(1) 哪份 GDD 正确——查 registry 的 `source:` 字段，源 GDD 是权威所有者，矛盾的其它 GDD 才是需改的；(2) registry 本身是否过期——源 GDD 在 registry 条目写入后更新过（查 git log）则 registry 可能 stale；(3) 是否真正的设计变更——是则解决次序：改源 GDD → 改 registry → 再改其它 GDD。（Phase 4）
R10. 冲突分类三级：**🔴 CONFLICT**——不同 GDD 中同名实体/物品/公式/常量不同值，架构开始前必须解决；**⚠️ STALE REGISTRY**——源 GDD 值已变但 registry 未更新：registry 需更新，其它 GDD 可能已正确；**ℹ️ UNVERIFIABLE**——提及但无可比属性，非冲突仅记录引用。（Phase 4）

### Phase 5 — 输出与裁决
R11. 报告结构：日期、registry 条目数、扫描 GDD 数与名单、Scope 行（全部 GDD 节 / 仅必需节 — workflow: standard / 逐 GDD 注明有效档不同者及其档）、`Not checked at this tier` 行（必需节外出值的项：名、GDD、节；全部 GDD 均 `full` 时省略）；四节发现：Conflicts Found（must resolve before architecture，逐项含 registry 值与 source、冲突 GDD 及其值、需要的解决方向）、Stale Registry Entries（registry 值与写入日期、源 GDD 新值、更新后查 referenced_by）、Unverifiable References（无冲突、无动作）、Clean Entries（✅ [N] 项全 GDD 无冲突验证过）。（Phase 5）
R12. 裁决：
   - **CONFLICTS FOUND**——检出 ≥1 冲突，列解决步骤；
   - **NOT ASSESSED**——未比较任何东西：registry 为空或指定名不在其中（Phase 1），或无 GDD 在范围内（Phase 2），说明是哪种；
   - **PASS**——无冲突：registry 与 GDD 在所有核过的值上一致，且至少跨一份 GDD。（Phase 5）

### Phase 6 — registry 修正
R13. **写前重读**：Phase 1 在扫描前读的 registry 可能已被其它技能或会话改变——每次 Edit 前读当前 `design/registry/entities.yaml`，以条目**当前**文本锚定编辑，绝不以 Phase 1 所见；新条目追加在其节最后一个既有条目之后。（Phase 6）
R14. 发现 stale 条目时问 "May I update `design/registry/entities.yaml` to fix the [N] stale entries?"；逐条：更新 `value`/属性字段、`revised:` 设为今天、加 YAML 注释 `# was: [old_value] before [date]`。GDD 中发现 registry 没有的新条目时问可否添加——**只**添加出现在多于一份 GDD 的条目（真跨系统事实）。（Phase 6）
R15. **绝不删除 registry 条目**——从全部 GDD 移除的条目设 `status: deprecated`。（Phase 6）
R16. 写入后运行 `bash .claude/scripts/registry.sh validate`，修完关于本次写入新增/改动条目的每一行（DUPLICATE、STATUS 或 LAYOUT 行，或其命名的 PATH_MISSING 行）后才下裁决；关于**其它**条目的行只向用户点名、不擅自修。脚本缺失或无输出时说明 registry 检查未运行，再对照文件头部规则重读所写条目。（Phase 6）
R17. 写入后：裁决 **COMPLETE**——一致性检查完成；仍有未解决冲突则 **BLOCKED**——[N] 个冲突需人工解决后才能开始架构。（Phase 6）
R18. **6b 反思日志**：发现任何 🔴 CONFLICT（无论是否已解决）时问 "May I append [N] entries to `docs/consistency-failures.md` (creating it if absent)?"；同意则逐冲突追加固定格式条目（`### [YYYY-MM-DD] — /consistency-check — 🔴 CONFLICT`：Domain、Documents involved、What happened（实体名、属性、相异值）、Resolution（或 "Unresolved — manual action needed"）、Pattern——泛化教训）；拒绝则说明冲突未记录。文件不存在时先建头（自动维护注释 + 逐冲突一行、按时间序的表）再追加。**绝不自行跳过记录**——文件缺失不是丢失冲突历史的理由，只有用户的"否"才是。（Phase 6b）

### Phase 7 — 会话状态与收尾
R19. 静默追加单行面包屑到 `production/session-state/active.md`（不存在则创建）：`<!-- CONSISTENCY-CHECK: [date] | GDDs checked: [N] | Conflicts found: [N] | Log: docs/consistency-failures.md -->`——面包屑必须指向 Phase 6 实际追加的文件：指向无人写入的文件的面包屑会把未来会话引向永远找不到的冲突历史且全程无报错；绝不发明报告文件名。（Phase 7）
R20. 以 `AskUserQuestion` 收尾：Prompt "Consistency check complete — [N] conflicts found. What next?"；选项 `[A] Fix the highest-priority conflict now` / `[B] Run /design-review on the most conflicted GDD` / `[C] Stop here`。collaborative 与 guided 模式绝不以纯文本结束技能；autonomous 模式打印发现与建议下一步后 `log_decision`（无小部件）。（Phase 7）
R21. 恢复参考：PASS→运行 `/review-all-gdds` 做整体设计理论审查，或 MVP GDD 全齐时 `/create-architecture`；CONFLICTS FOUND→修被标记 GDD 后重跑 `/consistency-check` 确认；STALE REGISTRY→更新 registry（Phase 6）后重跑验证；写完每份新 GDD 就运行本技能以及早捕获，而非拖到架构时。（Recovery / Reference）

## 4. 门禁与裁决
- **裁决词（报告）**：`PASS` / `CONFLICTS FOUND` / `NOT ASSESSED`；**排序**：CONFLICTS FOUND > NOT ASSESSED > PASS（未比较任何东西就不是 PASS——空 registry、未注册名、零范围内 GDD 三者均 NOT ASSESSED 并点名原因）。
- **裁决词（写入后）**：`COMPLETE`（检查完成且无未解冲突）/ `BLOCKED`（[N] 个冲突需人工解决后才能开始架构）。
- **架构门禁前置**：🔴 CONFLICT 必须在 `/create-architecture` 前解决——不一致会毒化下游 ADR。
- **冲突三级**：🔴 CONFLICT / ⚠️ STALE REGISTRY / ℹ️ UNVERIFIABLE；权威以 registry 的 `source:` 字段定所有者。

## 5. 移植建议
- **可直接移植**：R2/R3/R5（"未比较任何东西就不是 PASS"三连门）、R6-R7（grep 优先 + 按节归位命中的档位过滤）、R9（source 字段定权威所有者 + 三问定责）、R13（写前重读）、R15（永不删除条目只标 deprecated）、R18（失败日志：绝不自行跳过记录）、R19（面包屑指向真实写入文件）。
- **需替换概念**：GDD → 任何成体系的设计/规格文档；entity registry → 跨文档事实登记表（API 注册表、数据字典、术语表）；`docs/architecture/` ADR → 架构决策记录；`/design-system`、`/review-all-gdds`、`/create-architecture` → 各项目的文档生产/整体审查/架构流程。
- **改写示例**：
  - R3 → "被点名检查的名字不在登记表中时，裁决为 NOT ASSESSED 并列出最接近的注册名后停止——检查未注册的名字没有比较任何东西，那不是 PASS。"
  - R19 → "留给未来会话的状态面包屑必须指向本次运行实际写入的文件；指向无人写入文件的面包屑会把后续会话引向永远找不到的历史，且全程无报错。"

## 6. 关联文档
- 上游：`/design-system`（产出 GDD 并自动填充 registry）、`/review-all-gdds`（本技能为其提供干净基线，且其报告 `gdd-cross-review-*.md` 是 since-last-review 的时间锚）。
- 下游：`/create-architecture`（冲突清零后）、`/design-review`（冲突最多的 GDD）、`/consistency-check` 自身重跑验证。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/scripts/registry.sh`、`docs/consistency-failures.md`、`production/session-state/active.md`。
