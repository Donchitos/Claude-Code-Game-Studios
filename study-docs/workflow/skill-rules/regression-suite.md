# regression-suite — 回归覆盖映射（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/regression-suite/SKILL.md) ｜ 阶段：Phase 5-6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/regression-suite [update | audit | report]`
- **一句话职责**：维护一份"哪些测试必须永远通过"的精选清单——把测试覆盖映射到 GDD 关键路径、找出已修 bug 中缺回归测试的、检测新功能无对应回归覆盖的漂移。
- **触发前置**：`resolve_config --keys automation,workflow,qa.level,system_overrides` 已解析。回归套件**不是新测试类别**——它是 `tests/` 中已有测试的 curated list（覆盖关键路径与已知故障点），本技能只维护该清单。运行时机：修复 bug 后（确认回归测试已写或识别缺口）；阶段门禁前（`qa.level: full` 时 `/gate-check` 要求回归套件）；sprint 收尾时（检测覆盖漂移）。
- **`qa.level` 档位**：`minimal` → 回归套件**不生成**（报告并停止）；`standard` → Polish 阶段进入时生成；`full` → Production 阶段进入时生成。与 `workflow` 轴独立。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `tests/regression-suite.md`（既有清单）；`tests/unit/**/*_test.*`、`tests/integration/**/*_test.*`、`tests/regression/**/*`（测试清单）；`design/gdd/systems-index.md` + 各系统 GDD（audit 模式，按 workflow 档位）；当前 sprint 计划与 story 文件（update 模式）；`production/qa/bugs/*.md`（`Status: Closed`/`Fixed`）；`production/qa/smoke-*.md` 最新（workflow minimal 时作关键路径源） | 既有注册 / 覆盖映射 / 已修 bug / 漂移信号 |
| 产出 | `tests/regression-suite.md`（manifest；update 追加、audit 重写、report 不写） | curated 索引：注册测试、Known Gaps、Quarantined Tests |
| 派生智能体 | 无，主会话直接执行 | — |

**workflow 档位**：`modes.workflow`（由 `modes.rigor` 供给除非显式设置；audit 模式下逐 GDD 考虑 `system_overrides`）——决定 GDD 关键路径被映射还是覆盖仅按 smoke 路径（见 R6）。

## 3. 核心规则（逐条编号 R1、R2……）

### 1 — 解析参数与早守卫
R1. **早 `qa.level` 守卫**：`qa.level: minimal` 时回归套件不生成——报告 "Regression suite not generated at qa.level minimal" 并在任何扫描前**停止**，对全部模式（update/audit/report）生效。这是 `qa.level` 轴，与 Step 2c 的 workflow 档位 `minimal` 分支（只改变关键路径*来源*，不改变套件*是否运行*）不同——**禁止因 `qa.level` 进入 Step 2c 的 minimal 分支**。此停止的 verdict 为 NOT ASSESSED（该级不要求测试，且什么都没扫）。（§1）
R2. 模式：
   - `update` — 扫描本 sprint 新 bug 修复并检查回归测试存在性，向清单 manifest 加新测试；
   - `audit` — 全量审计所有 GDD 关键路径 vs 现有测试覆盖，标记无回归测试的路径；
   - `report` — 只读状态报告（不写），适合 sprint 评审；
   - 无参数：sprint 明确活跃（sprint 计划存在且有 in-progress story）→ `update`；含糊或未检出活跃 sprint → `AskUserQuestion` 三选项（update / audit / report）。（§1）

### 2 — 载入上下文
R3. **Step 2a**：读 `tests/regression-suite.md`（存在时）——提取总注册回归测试数、最后更新日期、任何 `STALE` 或 `QUARANTINED` 标记；不存在 → 注记 "No regression suite found — will create one."。（§2a）
R4. **Step 2b**：glob 全部测试文件（`tests/unit/**/*_test.*`、`tests/integration/**/*_test.*`、`tests/regression/**/*`）；每文件记 system（目录路径）与文件名；除非需要名字到测试的映射，**不读测试文件内容**。（§2b）
R5. **Step 2c（仅 audit 模式）**：读 `systems-index.md` 取全部系统，按每系统 workflow 档位限定扫描：
   - `full` — 读 GDD 从全部节映射关键路径；
   - `standard` — 从必需节（Acceptance Criteria、Edge Cases，定义数值规则的系统另加 Formulas）；经 `system_overrides` 钉高的系统按高档映射；
   - `minimal` — **跳过 GDD 关键路径扫描**，改读 `production/qa/smoke-*.md` 最新冒烟报告，取其行使的关键路径作为回归范围（Step 3 对那些路径而非 GDD 验收标准做覆盖映射）；无冒烟报告 → 停止，Verdict `NOT ASSESSED — no smoke report to take critical paths from`（minimal 下没有冒烟报告就没有关键路径源——先跑 `/smoke-check`）。
   档位只影响 audit；update 与 report 不受档位影响。GDD 按节读（Grep `^#` + offset/limit）；`full` 时每节都按范围读——40 KB 以上的整文件 Read 会被拒绝。对每个范围内 MVP 档系统的 GDD 提取：Acceptance Criteria（定义关键路径）、Formulas 节（公式必须有回归测试）、Edge Cases 节（已知边缘应有回归测试）。**update 模式跳过全量 GDD 扫描**——改读当前 sprint 计划与 story 文件找本 sprint `Status: Complete` 的 story。（§2c）
R6. **Step 2d**：glob `production/qa/bugs/*.md` 过滤 `Status: Closed` 或 `Status: Fixed` 的 bug；记录 bug 所在 story/系统、修复描述中是否提及回归测试。（§2d）

### 3 — 覆盖映射：关键路径（仅 audit）
R7. 对每条 GDD 验收标准（minimal 档改为对冒烟报告的关键路径，跳过 GDD 标准循环）：① grep `tests/unit/[system]/` 与 `tests/integration/[system]/` 找与标准关键名词/动词相关的文件名与函数名；② 赋覆盖状态：**COVERED**（存在针对该标准逻辑的测试文件）/ **PARTIAL**（有测试但不覆盖所有情形，如仅 happy path）/ **MISSING**（该关键路径无测试）/ **EXEMPT**（Visual/Feel 或 UI 标准——设计上不可自动化）；③ **MISSING 中对应公式或状态机的提升为 HIGH PRIORITY gap**——它们是最可能的回归源。（§3）

### 4 — 覆盖映射：已修 bug
R8. 对每个已关闭 bug：① 从 bug 元数据提取 system slug；② grep `tests/unit/[system]/` 与 `tests/integration/[system]/` 找引用该 bug ID 或特定故障场景的测试；③ 赋值：**HAS REGRESSION TEST**（找到能抓住该 bug 的测试）/ **MISSING REGRESSION TEST**（bug 修了但没有防复发的测试）。缺失项：标记为回归 gap；建议测试文件路径 `tests/unit/[system]/[bug-slug]_regression_test.[ext]`；注记 "Without this test, this bug can silently return in a future sprint."。（§4）

### 5 — 检测覆盖漂移
R9. 漂移 = 游戏长大了、回归套件没长。检查指标：
   - 本 sprint 完成但 `tests/` 无对应测试文件的 story；
   - `systems-index.md` 自上次更新以来新增的系统；
   - GDD 节自回归套件上次更新以来新增或修订（有文件修改线索就 Grep，否则问用户）；
   - `tests/regression-suite.md` 最后更新日期 vs 当前——**间隔 > 2 个 sprint 标记为可能 STALE**。（§5）

### 6 — 生成报告与清单 manifest
R10. 会话内报告：模式、既有注册测试数、扫描文件数；Critical Path Coverage 表（audit only：System / Total ACs / Covered / Partial / Missing / Exempt + 非豁免覆盖率 %）；Bug Regression Coverage 表（Bug ID / System / Severity / Has Regression Test? YES/NO ⚠ + 无回归测试 bug 计数）；Coverage Drift Indicators；Recommended New Regression Tests 表（Priority HIGH/MEDIUM、System、建议测试文件、Covers）。（§6）
R11. **分母守卫**：算覆盖率前先查分母——GDD glob 返回**零关键路径**或测试 glob 返回**零测试文件** → **不发百分比**，报告 `Coverage: NOT ASSESSED — [no GDDs found | no test files found]`，点名哪边为空及产出它的技能（GDD → `/map-systems` 和 `/design-system`；测试脚手架 → `/test-setup`）。**空分母算出的百分比不是低分，不是一个数字**：`0%` 读作"测了且糟透了"，`100%` 读作"测了且完美"——两者都是关于从未发生过的比较的声明。（§6）
R12. manifest 结构（`tests/regression-suite.md`）：头部（Last Updated / Total registered tests / Coverage %）；How to run（引擎特定的全量回归命令）；Registered Regression Tests（按系统分节：Test File / Test Function / Covers（AC-N / BUG-NNNN）/ Added）；Known Gaps（Priority / System / Suggested Path / Covers / Reason Not Yet Written——如 "Bug fixed without test"）；Quarantined Tests（Test File / Function / Reason / Quarantined Since）。（§6）

### 7 — 写输出
R13. update 或 audit 模式先询问："May I write/update `tests/regression-suite.md` with the current regression suite manifest?"。**update 只追加新条目，绝不移除既有条目**（用 `Edit` 定向插入）；**audit 全量重写** manifest 带最新覆盖数据；**report 不写任何东西**。（§7）
R14. 写入后（若批准）：每 HIGH 优先 gap → "Consider creating the missing regression test before the next sprint. Run `/test-helpers` to scaffold the test file."；bug 回归 gap > 0 → "These bugs can silently return without regression tests. The next sprint should include a story to write the missing tests."；检出漂移 → "Regression suite may be drifting. Consider running `/regression-suite audit` at the next sprint boundary."。`workflow: minimal` 无 sprint → 三句话改说 "next story"。（§7）
R15. **Verdict 首匹配**：`NOT ASSESSED` — §1 的 `qa.level: minimal` 停止；`NOT ASSESSED` — minimal 档无冒烟报告停止（点名 `/smoke-check` 为修复路径）；`NOT ASSESSED` — 覆盖率返回 `Coverage: NOT ASSESSED`（无 GDD 或无测试文件，点名原因）——**绝不在未算出的覆盖率上报告 COMPLETE**；`BLOCKED` — update/audit 模式且用户拒绝写入；`COMPLETE` — update/audit：套件已更新；report：覆盖报告已展示（report 不写）。（§7）

### 协作协议（collaborative 模式）
R16. **未经明确用户批准，绝不从 manifest 移除既有回归测试**——移除刻意编写的测试本身就是回归风险。**gap 是 advisory 不是阻塞**——清晰浮出但不阻止其它工作推进（`qa.level: full` 除外——阶段门禁要求回归套件）。**隔离不是删除**——间歇失败的测试应被 quarantine（在 manifest 中注记）而非移除；由 `/test-flakiness` 修复。**写前询问**——创建或更新 manifest 前恒确认。

## 4. 门禁与裁决
- **裁决词**：`COMPLETE` / `BLOCKED` / `NOT ASSESSED`；覆盖状态 `COVERED` / `PARTIAL` / `MISSING` / `EXEMPT`；bug 状态 `HAS REGRESSION TEST` / `MISSING REGRESSION TEST`。
- **排序（首匹配）**：三种 NOT ASSESSED（qa.level 停止 / 无冒烟报告 / 空分母）> BLOCKED > COMPLETE。
- **取最严原则**：未算出的覆盖率绝不折算成 COMPLETE；`qa.level: full` 下 gap 从 advisory 升格为阶段门禁硬要求。
- **消费方**：`/gate-check`（full 档要求回归套件）、`/test-flakiness`（读 quarantine 节并诊断）、`/test-helpers`（补写缺失测试的脚手架）。

## 5. 移植建议
- **可直接移植**：R1（配置轴与流程档位两根轴不得混淆——"是否运行"与"数据从哪来"是不同开关）、R8（每个已修 bug 必须能回答"哪个测试会在它复发时变红"）、R9 的 "> 2 个迭代未更新即 STALE"、R11（空分母守卫——"0% 是测了且糟，100% 是测了且完美，都不是没测"）、R13（只追加不删除——删测试本身是回归风险）、R16（隔离≠删除）。
- **需替换概念**：GDD 验收标准/公式/边缘 → 需求文档的可测条目、API 契约、不变量；BUG-NNNN → 工单 ID；sprint → 迭代；`/smoke-check` 报告 → 冒烟/健康检查产物；`/test-helpers` → 测试脚手架工具。
- **改写示例**：
  - R11 → "计算覆盖率前必须核对分母：需求侧或测试侧任一 glob 为空时禁止输出百分比，改报 NOT ASSESSED 并点名缺失侧及其上游生产流程。空分母的百分比不是低分，不是一个数字。"
  - R16 → "回归清单只允许追加。移除一条刻意编写的回归测试必须经用户明确批准——删测试与引入回归是同一个动作。间歇失败的测试隔离（注记停跑）而非删除，且必须保留对应的修复任务。"

## 6. 关联文档
- 上游：`/map-systems`、`/design-system`（GDD 来源）、`/test-setup`（测试脚手架）、`/smoke-check`（minimal 档的关键路径源）、`/bug-triage`（bug 生命周期）。
- 下游：`/test-helpers`（补写缺失回归测试）、`/test-flakiness`（诊断 quarantined 测试）、`/gate-check`（full 档阶段门）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/workflow-modes.md`、`.claude/docs/config-resolution.md`。
