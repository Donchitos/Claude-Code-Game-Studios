# skill-improve — 测试-修复-重测循环改进技能（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/skill-improve/SKILL.md) ｜ 阶段：Any ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/skill-improve [skill-name]`
- **一句话职责**：对单个技能跑"测试 → 修复 → 重测 → 保留或回滚"的改进循环；分数来自 `/skill-test` 的静态与类别检查。
- **触发前置**：目标技能的 `.claude/skills/[name]/SKILL.md` 必须存在；评分本质是"读技能"而非"跑技能"——分更高只说明写得更好，不证明行为更好，行为验证须在改动前后拿真实请求各跑一次。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | resolve_config 预解析块：`automation` | 运行前解析好、按原样使用 |
| 读取 | `.claude/skills/[name]/SKILL.md` 及其 `references/` 文件夹的全部文件（若有） | 最长的技能把每个阶段放在 references 里；诊断必须指出每个缺口所在文件 |
| 读取 | `studio-tests/catalog.yaml`（查 `category:` 字段） | Phase 2b 类别基线的依据 |
| 读取 | `/skill-test static [name]`、`/skill-test category [name]` 的运行结果 | 唯一合法分数来源——重测分数由该次运行测得，**禁止**由编辑内容自行宣称 |
| 产出 | 改进版 `.claude/skills/[name]/SKILL.md` 及被修的各 `references/` 文件；分数未改善且用户同意时按 Phase 5 记录的原文回滚 | 写前必须征询；回滚必须用 Write 复原对话内记录的原文 |
| 派生智能体 | 无，主会话直接执行 | — |

**配置解析**：`modes.automation` 解析链 `project.local.yaml` → `project.yaml` → 默认 `collaborative`；每次提问与写文件遵循 `.claude/docs/automation-modes.md`（collaborative 每次都问 · guided 只问重大 · autonomous 记录并推进；`automation_always_ask` 类别恒问）。

## 3. 核心规则（逐条编号 R1、R2……）

### Phase 1：解析参数
R1. 从第一个参数读技能名；缺失时输出用法并停止：`Usage: /skill-improve [skill-name]`、`Example: /skill-improve tech-debt`。（Phase 1）
R2. 必须验证 `.claude/skills/[name]/SKILL.md` 存在；不存在则停止并报 "Skill '[name]' not found."。（Phase 1）
R3. 必须 Glob `CCGS Skill Testing Framework/catalog.yaml`；存在时**先**声明："`CCGS Skill Testing Framework/` was renamed `studio-tests/` in 1.2.0, and this skill reads only `studio-tests/`. Move any specs you wrote there; UPGRADING.md (v1.1.3 → v1.2.0, `studio-tests/`) says how." 然后继续。（Phase 1）

### Phase 2/2b：基线
R4. 跑 `/skill-test static [name]` 记录基线：FAIL 数、WARN 数、具体失项（Check 1–7）；向用户展示 "Static baseline: [N] failures, [M] warnings" 及失项清单（如 "Check 4 (no ask-before-write), Check 5 (no handoff)"）。（Phase 2）
R5. 静态结果为 **NOT ASSESSED**（技能文件读不出或解析不了）时必须停止并连同原因报告：没有可改进的分数，"没人读得出的文件得 0 FAIL"不是干净结果。基线 0 FAIL 0 WARN 则记录后进入 Phase 2b。（Phase 2）
R6. Phase 2b：在 `studio-tests/catalog.yaml` 查 `category:` 字段——没有就显示 "Category: not yet assigned — skipping category checks." 并跳到 Phase 3；有则跑 `/skill-test category [name]` 记录类别基线并展示 "Category baseline: [N] failures, [M] warnings ([category] rubric)"。（Phase 2b）
R7. 类别结果为 **NOT ASSESSED**（skill-test 找不到或套不上某 rubric 小节）必须连同原因报告且**不是**零分：该类别维度从下述"已全过"判定中剔除。（Phase 2b）
R8. 静态与类别基线**都**为 0 FAIL 0 WARN——且都不是 NOT ASSESSED——时停止："This skill already passes all static and category checks. No improvements needed."。（Phase 2b）

### Phase 3：诊断
R9. 必须读全技能：`.claude/skills/[name]/SKILL.md` 及 `references/` 文件夹（若有）的每个文件——最长的技能把各阶段放在那里；每个缺口必须指出所在文件。各静态检查的缺口定位：Check 1 fail→缺哪个 frontmatter 字段；Check 2 fail→找到几个 phase 对比最低要求；Check 3 fail→技能正文无任何 verdict 关键词；Check 4 fail→allowed-tools 有 Write/Edit 但无 ask-before-write 措辞；Check 5 warn→结尾无 follow-up/next-step 节；Check 6 warn→`context: fork` 已设但 phase 少于 5 个；Check 7 warn→argument-hint 为空或与文档化模式不符。（Phase 3）
R10. 类别检查（Phase 2b 指派了类别时）的缺口同样要定位到技能原文，如：G2 fail（gate 模式、director 面板宽度）→技能正文没有按 `modes.workflow` 定 PHASE-GATE 面板尺寸（`minimal` 为 PR，`standard` 为 TD+PR，`full` 全 4）；A2 fail（authoring、无逐节 May-I-write）→技能只在最后问一次，而非每次写节前问；T3 fail（team、BLOCKED 未呈现）→技能没有在代理被阻塞时停下依赖工作。（Phase 3）
R11. 提出任何改动前必须把完整合并诊断展示给用户。（Phase 3）

### Phase 4：提议修复
R12. 为每个 FAIL 与 WARN 写**有针对性**的修复，以前/后对照块清晰展示；只改不及格处，**禁止**重写已通过的节。有 `references/` 文件夹的技能，某阶段步骤的修复写进该阶段的 `references/` 文件，**不**回填 `SKILL.md`；其后的征询问话要点名修复所改的每个文件。（Phase 4）
R13. 必须问："May I write this improved version to `.claude/skills/[name]/SKILL.md`?"；用户说不则到此为止。（Phase 4）

### Phase 5：写入并重测
R14. 写入前必须把被修每个文件的当前内容**逐字**记录在本对话里，供 Phase 6 复原。（Phase 5）
R15. 把改进写进 `SKILL.md` 及被修的各 `references/` 文件；重跑 `/skill-test static [name]` 记录新静态分——**由该次运行测得，绝不从编辑自行宣称**；指派了类别再重跑 `/skill-test category [name]` 记录新类别分。展示对比：`Static: Before [N] failures, [M] warnings → After [N'] failures, [M'] warnings`（类别同理），`Combined: [before] → [after] (improved / no change / worse)`——[before]/[after] 为 FAIL 加 WARN 两维合计，如 "Combined: 3 → 0 (improved)"。（Phase 5）

### Phase 6：裁决
R16. 合计 = 静态 FAIL + 类别 FAIL + 静态 WARN + 类别 WARN。重测返回 **NOT ASSESSED**（如编辑弄坏了 frontmatter 致文件不再可解析）**绝不**算改善，无论计数如何——走"未改善"分支。（Phase 6）
R17. 合计低于基线（改善）：报告 "Score improved. Changes kept."，并按每个维度总结修了什么。（Phase 6）
R18. 合计持平或更差：报告 "Combined score did not improve."，展示改了什么、为何可能没起效；问 "May I restore `.claude/skills/[name]/SKILL.md` to the content it had before this run?"——点名 Phase 5 写过的每个文件。同意→用 Write 把 Phase 5 记录的内容写回各文件；不同意→保持已写入状态。**绝不**用 `git checkout` 复原——那会退回最后**已提交**版本，把本次运行之前尚未提交的编辑一并丢掉。（Phase 6）

### Phase 7：后续
R19. 结束后建议：跑 `/skill-test static all` 找下一个有失项的技能；`/skill-improve [next-name]` 在另一技能上续跑循环；`/skill-test audit` 看整体覆盖进度。（Phase 7）

## 4. 门禁与裁决
- 无门禁，但有评分裁决：组合分 = 静态 FAIL + 类别 FAIL + 静态 WARN + 类别 WARN；裁决序为"改善→保留；持平或更差→征询回滚"；**NOT ASSESSED 在任何计数下都判'未改善'**（R16）；基线双 0 且无 NOT ASSESSED 即提前终止（R8）。
- 静态检查语义（Check 1–7，见 R9）与类别 rubric 项（G2/A2/T3 等，见 R10）是评测的固定标尺。

## 5. 移植建议
- **可直接移植**：R4–R5、R7–R9、R11–R19 全部通用——"基线先行、双基线（通用+专项）、NOT ASSESSED 不算 0 分也不算改善、逐字记录原文再改、重测分数只认运行结果、只修不及格处、回滚靠对话内快照而非 git"，适合任何"用静态检查驱动提示词/配置文件改进"的循环。
- **需替换概念**：`/skill-test` 与 Check 1–7 → 你的静态检查器与规则集；`studio-tests/catalog.yaml` 的 `category:` 与 G2/A2/T3 → 你的专项 rubric；`SKILL.md`+`references/` → 被改进的目标文件群（提示词、模板、代理定义）；frontmatter 字段（`context: fork`、`argument-hint`）→ 你的元数据约定；`CCGS Skill Testing Framework/` 改名提示 → 任何历史路径迁移的兼容性提示。
- **改写示例**：
  - "任何改进循环必须先取基线分再动手；改后分数只能由重测运行给出，禁止由'我改了什么'自行宣称；重测返回不可评估（NOT ASSESSED）时一律判为未改善，走回滚征询分支。"
  - "写入前必须把将被修改文件的原文逐字留存于会话内；需要回滚时用该留存内容覆盖写回，禁止用 git checkout——那会丢掉本次运行之前未提交的编辑。"

## 6. 关联文档
- 上游/下游：`/skill-test static`、`/skill-test category`、`/skill-test static all`、`/skill-test audit`（评分来源与续跑入口）
- 引用 docs：`.claude/docs/automation-modes.md`；`studio-tests/catalog.yaml`（类别定义；旧名 `CCGS Skill Testing Framework/` 于 v1.2.0 改为 `studio-tests/`，见 UPGRADING.md）
