# test-evidence-review — 测试与手工证据质量审查（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/test-evidence-review/SKILL.md) ｜ 阶段：Phase 5 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/test-evidence-review [story-path | sprint | system-name]`
- **一句话职责**：超越"存在且通过"，审查测试文件与证据文档的**质量**——断言覆盖、边缘覆盖、命名、公式可追溯、签核完整性、截图完备性、证据新鲜度，逐 story 给 ADEQUATE/INCOMPLETE/MISSING/NOT ASSESSED/WAIVED。
- **触发前置**：`resolve_config --keys automation,workflow,qa.level,testing.strict` 已解析；`AskUserQuestion` 与文件写入遵循 `.claude/docs/automation-modes.md`。运行时机：QA 交接签核前（`/team-qa` Phase 5）；任何测试质量存疑的 story；Logic/Integration 质量审计的里程碑评审。
- **定位区分**：`/smoke-check` 验证测试文件**存在且通过**；存在且通过的测试仍可能漏掉关键行为，存在的手工证据文档仍可能缺关闭所需签核——本技能管这些。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | story 文件（定向节 grep：`## Test Evidence` -A 8、`## Acceptance Criteria` -A 15）；story 声明的证据路径（优先）+ 回退搜索：Logic → 引擎 unit root（`tests/unit/[system]/`、Unity `Assets/Tests/EditMode/`、Unreal `Source/<Module>/Private/Tests/`）；Integration → integration root（`tests/integration/[system]/`、`Assets/Tests/PlayMode/`）+ `production/qa/playtests/`；Visual/Feel 与 UI → `production/qa/evidence/` 的保留图片（`*.png`/`*.jpg`/`*.gif`）与 `[story-slug]-evidence.*`；Config/Data → `production/qa/smoke-*.md`；`.claude/docs/coding-standards.md`（Default Gate Level 与证据表）；`review-receipts.sh` 输出 | story 类型与声明路径 / 证据定位 / 门禁级别 / 新鲜度 |
| 产出 | 会话内摘要报告 + **可选** `production/qa/evidence-review-[date].md`（写入前须批准） | 报告独立有用；持久记录仅在用户要求时写 |
| 派生智能体 | 无，主会话直接执行 | — |

**`qa.level` 与 `testing.strict` 决定什么可称 blocker**（与 `/story-done` 关闭 story 的规则相同——这里的 BLOCKING 项就是会挡住 `/story-done` 的项）：
- `qa.level: minimal` 豁免测试：Logic / Integration / Config-Data story 无测试证据（Config/Data 无 smoke 报告）→ `WAIVED (qa.level: minimal)`——**不是 MISSING**——不产生 BLOCKING 项；存在的测试仍审查但其 gap 是 ADVISORY。**Visual/Feel 与 UI 证据（保留截图与 Visual/Feel 签核）从不豁免**。
- 每 story 类型的门禁级别：取 `testing.strict.<type>`（Logic→`logic`、Integration→`integration`、Visual/Feel→`visual`、UI→`ui`、Config/Data→`config`）：`true` → BLOCKING、`false` → ADVISORY、`unset` → 纯布尔 `testing.strict: true|false`（legacy 形式）适用于全部类型；再否则用 `coding-standards.md` 的 Default Gate Level（**Logic、Integration、Visual/Feel、UI 为 BLOCKING；Config/Data 为 ADVISORY**）。下文每个 "BLOCKING" 都指该 story 类型的门禁级别。

## 3. 核心规则（逐条编号 R1、R2……）

### 1 — 解析参数
R1. 模式：`[story-path]` 单 story；`sprint` 当前 sprint 全部 story；`[system-name]` 该 epic/系统全部 story；无参数询问范围（Single story / Current sprint / A system）。（§1）

### 2 — 载入范围内 story
R2. Single story 直读文件提取 Type、Test Evidence 节、slug、system；Sprint 读 `production/sprints/` 最新文件提取 story 路径；System glob `production/epics/[system-name]/story-*.md`。（§2）
R3. **零 story 守卫**：解析出的范围含零 story → **在此停止**，报告 `NOT ASSESSED — no stories in scope`，点名搜索的范围与为空的路径并路由：无 sprint 文件 → `/sprint-plan new`（`workflow: minimal` 无 sprint → 改跑 `/test-evidence-review [epic-slug]`）；sprint 计划列了零 story → `/create-stories [epic-slug]`；`[system-name]` glob 空 → 命名该 glob。禁止继续到 §3。**要守卫的是空范围，不只是逐 story 的 unknown**：给了逐 story unknown 一个家（NOT ASSESSED）对空范围的 unknown 无济于事——零 story 时 §6 报告渲染出空 Summary 表并以 `BLOCKING items: 0 / ADVISORY items: 0` 结束，读起来像*全部审查、一切正常*。本技能门禁 story 关闭，而 coding-standards 把 Logic/Integration/Visual-Feel/UI 证据标 BLOCKING——假干净会关闭没人审查过的 story。（§2）
R4. 对所得 story 集用**定向节 grep 而非逐个全读**收集字段：`## Test Evidence` -A 8（Type 与声明的证据路径都在该节下）+ `## Acceptance Criteria` -A 15；slug 从文件名、system 从目录路径（零读取）。仅当 Test Evidence 节缺失或含糊时才全读该 story（Sprint 模式把 glob 限定到 sprint 计划的 story 路径）。（§2）

### 3 — 定位证据文件
R5. **先查 story 声明的证据路径**（§2 从其 `## Test Evidence` 节捕获的）——存在就用它；仅无声明路径或未找到时回退搜索：Logic → 引擎 unit root 找名字含 story slug 或其 system 的文件（测试按 `.claude/rules/test-standards.md` 命名，**不一定**叫 `[story-slug]_test.*`）；Integration → 同样，在 integration root 下，另查 `production/qa/playtests/` 提及该 story 的记录；Visual/Feel 与 UI → glob `production/qa/evidence/` 找属于该 story 的保留图片与 `[story-slug]-evidence.*`；Config/Data → glob `production/qa/smoke-*.md`（任何冒烟报告）。逐 story 记录找到（路径）或未找到（gap）。（§3）

### 4 — 审查自动化测试质量（Logic / Integration）
R6. **断言覆盖**：数不同断言（含 assert/expect/check/verify 或引擎特定断言模式的行）。低断言数是质量信号——每测试函数只 1 个断言的测试可能覆盖不了预期行为范围。阈值：**3+ 断言/测试函数** → 正常；**1-2** → 注记 potentially thin；**0（测试存在但无断言）** → 标 **BLOCKING**（该 story 类型的门禁级别；`qa.level: minimal` 时 ADVISORY）——测试空洞通过，什么都没证明。（§4）
R7. **边缘覆盖**：对 story 每条含数字、阈值或 "when X happens" 条件的验收标准，检查是否有测试函数名或测试体引用该特定情形。启发式：grep 测试文件中 "zero"、"max"、"null"、"empty"、"min"、"invalid"、"boundary"、"edge"——任一存在是正信号；story 有带具体边界的 Formulas 节 → 检查测试是否至少在最小/最大值上执行。（§4）
R8. **命名质量**：测试函数名应描述 场景 + 预期结果，按引擎模式（Godot `test_[scenario]_[expected]`、Unity `[Scenario]_[Expected]`、Unreal `<Project>.[System].[Scenario]`）。泛命名（`test_1`、`test_run`、`testBasic`）标 **naming issues**——失败时更难诊断。（§4）
R9. **公式可追溯**：GDD 有 Formulas 节的 Logic story → 测试文件至少一个测试的名字或注释引用该公式名或公式值。不提名字就测公式的测试，在公式变化时更难维护。（§4）

### 5 — 审查手工证据质量（Visual/Feel / UI）
R10. **UI story 无需证据文档**：没有时其保留截图就是证据——只应用 Screenshot/artefact completeness（story 改变的每屏一图；某标准 merely 导航到的屏幕（如 Quit 后的标题屏）不需要自己的图）与 Date coverage 两项，UI story 在这两项上 ADEQUATE——**绝不因缺文档、缺 criterion linkage 或缺 sign-off 而 INCOMPLETE**。（§5）
R11. **Criterion linkage**：证据文档应引用 story 的每条验收标准（或清晰改写）。缺标准 = 该标准从未被验证。**Sign-off completeness**：关闭 story 遵循 `coding-standards.md` 证据表——与 `/story-done` 相同规则，**每 `qa.level` 都一样**：Visual/Feel → 证据文档每一 sign-off 行都 `[x] Approved`，空或缺失行 = INCOMPLETE；UI → 无 sign-off 要求——保留截图即关闭；存在就注记，**绝不因缺而 INCOMPLETE**。（§5）
R12. **Screenshot/artefact completeness**：Visual/Feel → glob `production/qa/evidence/` 找属于该 story 的保留图片；**描述了视觉检查但没保留图片的文档 = INCOMPLETE——该门禁默认 BLOCKING，描述是断言不是证据**。UI → 同样要求每个触碰屏幕的保留截图；walkthrough log 欢迎但非必需。（§5）
R13. **Evidence older than its code**：每个有保留图片的 story 跑 `bash .claude/scripts/review-receipts.sh check production/qa/evidence/[story-slug]/stamp.txt`；列出每个 `CHANGED:` 或 `GONE:` 文件为 **POTENTIALLY STALE**（在证据采集后变更过）；`RECEIPT: NONE` → 说 "no stamp" 并用日期检查。**仅是报告行——绝不改变该 story 的 verdict**。（§5）
R14. **Date coverage**：证据文档应有日期；早于 story 最后重大变更（启发式：对比 sprint 计划的 sprint 开始日期）→ 标 **POTENTIALLY STALE**——证据可能不覆盖最终实现。（§5）

### 6 — 构建审查报告
R15. 逐 story verdict 五值：（§6）
   - **ADEQUATE**（测试/证据存在、过质量检查、全部标准覆盖）；
   - **INCOMPLETE**（存在但有质量 gap——断言薄、缺签核）；
   - **MISSING**（在该 `qa.level` 下要求证据的 story 类型没找到测试或证据）；
   - **NOT ASSESSED**（该 story 的审查无法执行——见 R16）；
   - **WAIVED (qa.level: minimal)**（minimal 下无测试证据的 Logic/Integration/Config-Data story——测试不要求，所以没有缺失；按 waived 命名）。
R16. **NOT ASSESSED 是必需的，且不是更软的 MISSING**：其余三个 verdict 都预设审查真的跑了。MISSING 意为*我看了，那里什么都没有*——真实的、可报告的失败；**绝不能**用于*我没法看*——那根本不是关于该 story 的发现。NOT ASSESSED 用于：story 的**类型无法确定**（类型→证据映射使任何其它 verdict 有意义）；证据路径有名字但**不可读或超出本次范围**；story 文件本身无法解析。**逐 story 说明是哪一种**——读者无法对裸 NOT ASSESSED 采取行动；把它与 MISSING 分开的全部意义在于两者修复不同：一个要写测试，另一个要给审查者权限或给 story 分类。（§6）
R17. **整体 verdict = 最差 story verdict**，排序：`NOT ASSESSED` 高于 `ADEQUATE`（没能评估部分范围的运行没有确立该范围 adequate）；**不高于** `INCOMPLETE`/`MISSING`（已知失败比未知更可行动，把真实失败降级到访问问题后面会埋掉它）；`WAIVED` 低于 `ADEQUATE`（仅当范围内每个 story 都 waived 时整体才读 WAIVED，且无论哪种情况报告都点名每个 waived story）。（§6）
R18. 报告结构：（§6）
   - **头部**：Date / Scope / Stories reviewed / Overall verdict / `qa.level` / `testing.strict` 解析值或 "unset — coding-standards.md defaults"；
   - **Story-by-Story Results**：每 story——path found/not found；自动化质量四项——断言覆盖/边缘/命名/公式追溯（Logic/Integration）；手工质量四项——criterion linkage / lead sign-off（Visual/Feel only，UI 无需）/ artefacts / freshness（Visual/Feel/UI）；Issues 分 **BLOCKING**（阻止 story-done）与 **ADVISORY**（发布前应修）；
   - **Summary 表** + `BLOCKING items` / `ADVISORY items` 计数。

### 7 — 写输出（可选）
R19. 会话内展示报告；询问 "May I write this test evidence review to `production/qa/evidence-review-[date].md`?"——**可选**，报告独立有用，仅用户要持久记录时写。报告后：BLOCKING 项 → "These must be resolved before `/story-done` can mark the story Complete. Would you like to address any of them now?"；断言薄 → "Consider running `/test-helpers [system]` to see scaffolded assertion patterns."；缺签核 → "Manual sign-off is required from [role]. Share `[evidence-path]` with them to complete sign-off."。Verdict：**COMPLETE** — evidence review finished；发现 BLOCKING 项时用 **CONCERNS**。（§7）

### 协作协议
R20. **报告质量问题，不修复**——本技能读和评估，禁止修改测试文件或证据文档。**ADEQUATE 意为可交付的足够，不是完美**——避免对功能正常且足够全面的测试吹毛求疵。**BLOCKING vs ADVISORY 区分重要**——仅当 gap 真正留下一条 story 标准未被验证才标 BLOCKING。**写前询问**——报告文件可选，写前恒确认。

## 4. 门禁与裁决
- **裁决词（逐 story）**：`ADEQUATE` / `INCOMPLETE` / `MISSING` / `NOT ASSESSED` / `WAIVED (qa.level: minimal)`；**整体**：五者取最差；**收尾**：`COMPLETE` / `CONCERNS`（有 BLOCKING 时）。
- **排序**：MISSING ≈ INCOMPLETE > NOT ASSESSED > ADEQUATE > WAIVED（已知失败最可行动；未能评估高于通过；全豁免最低）。
- **BLOCKING 判定链**：`testing.strict.<type>` → legacy `testing.strict` → coding-standards 默认（Logic/Integration/Visual-Feel/UI BLOCKING，Config/Data ADVISORY）；`qa.level: minimal` 把测试类 gap 全部降为 ADVISORY/WAIVED，但截图与 Visual/Feel 签核永不豁免。
- **消费方**：`/story-done`（BLOCKING 项阻塞关闭）、`/team-qa` Phase 5（QA 交接签核）。

## 5. 移植建议
- **可直接移植**：R3（空范围守卫——"0/0 项问题"读作全好）、R6（零断言 = 空洞通过）、R9（公式/契约可追溯命名）、R12（描述是断言不是证据——截图/录像才是）、R13-R14（证据不得早于代码，receipt 校验只报告不改判）、R16（NOT ASSESSED ≠ 更软的 MISSING，两者修复路径不同）、R17（排序哲学——已知失败 > 未能评估 > 通过）、R20（审查者报告不修复）。
- **需替换概念**：GDD Formulas → 接口契约/数值规格；sign-off 角色（designer/lead-programmer/art-director）→ 对应的评审角色（设计负责人、安全官、产品）；`production/qa/evidence/` → 证据归档目录；`/story-done` → 任务完结门；story 类型五分类 → 工单类型分类。
- **改写示例**：
  - R16 → "证据审查的裁决词表中必须包含 NOT ASSESSED 且不得当作弱化的 MISSING：MISSING 表示'查过了，没有'，NOT ASSESSED 表示'没法查'（条目类型未知、路径不可读、文件无法解析），二者修复动作完全不同，必须逐条目注明是哪一种。"
  - R12 → "以描述代替制品的手工证据一律判 INCOMPLETE：文字描述是一种断言而非证据，只有留存的截图、录像或签名记录才能关闭验证项。"

## 6. 关联文档
- 上游：`/qa-plan`（DoD 与证据路径的定义方）、`/smoke-check`（存在性与通过性检查——本技能接棒查质量）、`/playtest-report`（playtest 证据）。
- 下游：`/story-done`（BLOCKING 项阻塞）、`/team-qa`（Phase 5 交接签核）、`/test-helpers`（断言薄的补救建议）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/coding-standards.md`、`.claude/docs/directory-structure.md`、`.claude/rules/test-standards.md`、`.claude/scripts/review-receipts.sh`。
