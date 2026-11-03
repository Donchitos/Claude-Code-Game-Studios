# day-one-patch — 金母盘后当日补丁（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/day-one-patch/SKILL.md) ｜ 阶段：Phase 7+ ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/day-one-patch [scope: known-bugs | cert-feedback | all]`（disable-model-invocation：仅显式调用）
- **一句话职责**：金母盘锁定后、上线日之前，对"**安全且必要**"的已知问题做当日补丁的**迷你冲刺**——范围纪律、先有回滚计划、轻量 QA 门禁；它不是 hotfix、也不是完整冲刺。
- **触发前置（何时运行）**：金母盘构建已锁定（认证通过或 launch candidate 打 tag）；存在风险太高不敢在金母盘里修的已知 bug；认证反馈要求提交后小修；发布门禁通过后 pre-launch playtest 暴露 must-fix。输出文件：`production/releases/day-one-patch-[version].md`。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | `project.yaml` 的 `project.stage`（fallback `production/stage.txt`）；`production/gate-checks/` 最新文件（发布门禁 verdict）；`production/qa/bugs/*.md`（全部 Status: Open 或 Fixed — Pending Verification）；`production/sprints/` 最新（了解已发布内容）；`production/security/security-audit-*.md` 最新（开放安全项） | 前提核验与范围输入 |
| 读取 | `project.yaml` 的 `commands.test`；引擎测试根（Godot `tests/unit/`、`tests/integration/`；Unity `Assets/Tests/`；Unreal `Source/<Module>/Private/Tests/`——`.claude/docs/directory-structure.md`） | 定向测试；禁止凭记忆写 runner 行 |
| 产出 | `production/releases/rollback-plan-[version].md`（**Phase 4 之前必须写盘**）；`production/releases/day-one-patch-[version].md`（补丁记录，含 Bugs Fixed / Deferred to 1.1 / QA Sign-Off / Rollback / Approvals / 玩家版草稿） | 两份都先问后写 |
| 派生智能体 | `release-manager`（回滚计划）；`lead-programmer`（先只出方案不写码，批准后实现 + 定向测试）；`qa-tester`（修后复现验证）；`qa-lead`（QA 范围裁决） | 各自独立 Agent 调用 |

## 3. 核心规则（逐条编号 R1、R2……）

### 范围规则（Scope rules）
R1. **只收能快速安全修的 P1/P2 bug**；**无新特性——fix-only**；**不重构——最小可行改动**；任何超过 **4 小时**开发量的修复归 **patch 1.1**，不归 day-one。（Scope rules）

### Phase 1 — 载入与前提核验
R2. 载入（见数据依赖表）。resolved stage（project.yaml → stage.txt）不是 `Release` 或 `Polish` → 输出 "Day-one patch prep is for Release-stage projects. Current stage: [stage]. This skill is not appropriate until you are approaching launch." 停。（Phase 1）
R3. **核验前提，不要假设**：整个技能建立在"存在一个已通过发布门禁的金母盘"上——该前提才是下面轻量 QA（而非全量）的正当性来源，所以去验证它，而不是从 stage 值推断。（Phase 1）
R4. 前提三分支：`production/gate-checks/` 无文件、或没有记录 release-gate verdict 的 → 报 **`Release gate: NOT ASSESSED — no gate-check record found`**，**禁止静默继续**——直说"下面的缩减 QA 范围被一个谁也找不到的门禁背书着"，并问是先跑 `/gate-check` 还是改走全量 QA。最新记录是 **FAIL、CONCERNS 或 NOT ASSESSED** → 点名并**停**——没过门禁的构建上做 day-one patch 不是 day-one patch，是迟到的发布门禁、范围还裁错了。`project.stage: Release` **本身不构成证据**：stage 是项目所在位置的宣称，gate 记录才是挣得该位置的凭证。（Phase 1）

### Phase 2 — 范围
R5. **Step 2a 分类表**：每个开放 bug 按表评估——S1 或 S2 严重度 → 收（安全可修则必须收）；P1 优先级 → 收；预估 < 4 小时 → 收；需要**架构改动** → 不收，缓到 1.1；**引入新代码路径** → 不收，太险；**纯数据/配置修复（无代码改动）** → 收，风险极低；认证反馈要求 → 收（平台过审必需）；S3/S4 → 只有 trivial 配置修复才收，否则缓。（Step 2a）
R6. **Step 2b 展示范围**：`AskUserQuestion`——"Based on open bugs and cert feedback, here is the proposed day-one patch scope. Does this look right?"，附**收进表**（ID、严重度、描述、预估工时）与**缓议表**（ID、严重度、缓议原因）。选项 `[A] Approve this scope` / `[B] Adjust — add or remove items` / `[C] No day-one patch needed`。C → 输出 "No day-one patch required. Proceed to `/launch-checklist`." 停。（Step 2b）
R7. **Step 2c 总量检查**：累加预估工时，**超过 1 天工作量** → 警告原文 "⚠️ Patch scope is [N hours] — this exceeds a safe day-one window. Consider deferring lower-priority items to patch 1.1. A bloated day-one patch introduces more risk than it removes."，并用 `AskUserQuestion` 确认继续或缩减范围。（Step 2c）

### Phase 3-4 — 回滚先行与实现
R8. **写任何代码之前定义回滚程序——不可协商**。派 `release-manager`（Agent）产出：各目标平台如何回退到金母盘构建；平台特定回滚约束（**有些平台无法回滚认证构建**）；谁负责触发回滚；回滚发生时的玩家沟通。展示计划并问 "May I write this rollback plan to `production/releases/rollback-plan-[version].md`?"——**回滚计划写盘之前禁止进入 Phase 4**。（Phase 3）
R9. 每个代码修复走**聚焦实现环**：(1) 派 `lead-programmer`（Agent），给 bug 报告（精确复现步骤 + 已知根因）、约束（仅最小可行修复、不清理）、受影响文件（bug 报告 Technical Context 节）——它**只返回**每个 bug 的最小修复与将改文件，**不写任何东西**；(2) **整套只问一次**："May I apply these fixes? [BUG-ID → files, one line each]"——**批准前禁止任何代码改动**；(3) yes 后把每个批准的修复交回 `lead-programmer`（携带其方案的新 Agent 调用）实现，并用 `commands.test`（runner 允许时收窄到受影响套件）跑定向测试——**禁止凭记忆写 runner 命令行**；`commands.test` 未设 → 说明并给该 bug 记 `Tests: NOT RUN — commands.test unset`；(4) 派 `qa-tester`（Agent）验证：修复后 bug 还复现吗？（Phase 4）
R10. **配置/数据-only 修复直接改**（不需要程序员 agent）：先点名文件与改动问 "May I edit `[config file]` — `[key]`: [old value] → [new value]?"，然后确认值已变并重跑相关冒烟测试。（Phase 4）

### Phase 5 — 补丁 QA 门禁
R11. **轻量 QA——不是完整 `/team-qa`**：补丁已随发布门禁获得 QA 批准，这里只复验改动区域。派 `qa-lead`（Agent），给改动文件清单、已修 bug 列表（带 Phase 4 验证状态）、受影响系统的冒烟检查范围。问：**"Is a targeted smoke check sufficient, or do any fixes touch systems that require a broader regression?"**（Phase 5）
R12. 按裁决执行：**定向冒烟** → 跑 `/smoke-check`（它不收系统参数）；**更广回归** → 用 `commands.test`（收窄到受影响套件）跑受影响系统在引擎测试根（Godot `tests/unit/` 与 `tests/integration/`、Unity `Assets/Tests/`、Unreal `Source/<Module>/Private/Tests/`）的测试；`commands.test` 未设 → 更广回归 **NOT ASSESSED**，说明。（Phase 5）
R13. QA verdict **必须 PASS 或 PASS WITH WARNINGS** 才继续；**FAIL** → 把失败的修复**从 day-one patch 中剔除**、缓到 1.1。（Phase 5）
R14. **`NOT ASSESSED` 不是通过**：`/smoke-check` 在套件从未跑过——没构建、没 runner、或结果没人确认——时返回它；禁止靠它继续、**禁止重读成 PASS WITH WARNINGS**（warnings 意味着有人看了并看到小问题，NOT ASSESSED 意味着**没人看**）。补齐结果（verdict 点名缺什么才能跑）或把修复缓到 1.1——day-one patch 发给第一天买游戏的**每个玩家**，是未验证改动最坏的受众。（Phase 5）

### Phase 6-7 — 补丁记录与后续
R15. 生成补丁记录：`# Day-One Patch: [Game Name] v[version]` + Date prepared / Target release（`[launch date or "day of launch"]`）/ Base build（金母盘 tag 或 commit）/ Patch build；**Patch Notes (Internal)**——Bugs Fixed 表（BUG-ID / Severity / Description / Fix summary）与 **Deferred to 1.1** 表（BUG-ID / Severity / Description / Reason deferred）；**QA Sign-Off**——QA scope（Targeted smoke / Broader regression）、Verdict `[PASS / PASS WITH WARNINGS / NOT ASSESSED]`、QA lead（qa-lead agent）、Date、Warnings、Not assessed（什么没查、为什么）；**Rollback Plan**——指向 `production/releases/rollback-plan-[version].md` + **Trigger condition**（"If [N] or more S1 bugs are reported within [X] hours of launch, execute rollback."）+ Rollback owner；**Approvals Required Before Deploy** 四勾——lead-programmer 全部修复已评审 / qa-lead QA 门禁 PASS 确认 / producer 部署时机批准 / release-manager 平台提交确认；**Player-Facing Patch Notes**——给 community-manager 评审后才发布的草稿，平实语言列玩家可见改动。问 "May I write this patch record to `production/releases/day-one-patch-[version].md`?"。（Phase 6）
R16. 记录写盘后：(1) 跑 `/patch-notes` 生成玩家版；(2) 补丁上线后对每个已修 bug 跑 `/bug-report verify [BUG-ID]`；(3) 每个验证过的跑 `/bug-report close [BUG-ID]`；(4) 上线后 **48–72 小时**用 `/retrospective [milestone-name]`（`production/milestones/` 的上线里程碑）排上线后复盘。（Phase 7）
R17. **补丁后仍有 S1 开放** → 警告原文 "⚠️ S1 bugs remain open and were not patched. These are accepted risks. Document them in the rollback plan trigger conditions — if they occur at scale, rollback may be preferable to a follow-up patch." 结尾 `AskUserQuestion`："Day-one patch complete. What's next?"——A 跑 `/patch-notes` / B 跑 `/bug-report` 记录部署后发现的问题 / C 停。（Phase 7）

### Collaborative Protocol
R18. **范围纪律高于一切**——抵制范围蔓延，每加一项都在加风险；**回滚计划永远先行**——没有回滚计划的补丁是不负责任的；**缓议 ≠ 遗忘**——每个缓议 bug 列进记录的 "Deferred to 1.1" 表，之后跑 `/bug-triage` 排进 1.1 冲刺（无冲刺计划时——如默认 minimal workflow——排进 brief 的 build order）；**玩家沟通是补丁的一部分**——`/patch-notes` 是必需产出，不是可选项。（Collaborative Protocol）

## 4. 门禁与裁决
- **前提门禁**（Phase 1）：无 gate-check 记录 → `Release gate: NOT ASSESSED`，问先跑 `/gate-check` 还是走全量 QA；最新记录 FAIL / CONCERNS / NOT ASSESSED → 点名并**停**；stage 值本身不构成证据。
- **QA 门禁**（Phase 5）：PASS / PASS WITH WARNINGS 放行；FAIL → 失败修复剔除缓到 1.1；**NOT ASSESSED 不是通过**，不得重读为 PASS WITH WARNINGS。
- **范围门禁**：架构改动、新代码路径、> 4 小时 → 缓 1.1；总量 > 1 天 → 警告并确认。
- **审批链**：范围（用户）→ 回滚计划写盘 → 修复批准（整套一次）→ QA verdict → 四方 Approvals（lead-programmer / qa-lead / producer / release-manager）。

## 5. 移植建议
- **可直接移植**：R3-R4（前提要核验不要假设、"stage 是宣称、gate 记录是凭证"、无证据时给两条出路）、R5（收/缓二维判定表）、R8（回滚计划未写盘禁止动码）、R9（先出方案不写码、整套一次审批）、R13-R14（FAIL 剔除、NOT ASSESSED 不得重读为带警告通过）、R17（残留风险的显式警告）。
- **需替换概念**：金母盘（gold master）→ 任何"已定版的交付物"（冻结的 release candidate）；cert feedback → 外部审查/合规反馈；patch 1.1 → 下一例行版本；ESRB/平台认证 → 对应合规体系；`/bug-triage`、`/smoke-check`、`/patch-notes`、`/retrospective`、`/launch-checklist` → 对应流程；release-manager / qa-lead 等角色 → 项目的运维/质量角色。
- **改写示例**：
  - R4 → "任何'轻量流程'技能先核验使其合法的既定门禁存在且通过：找不到门禁记录就报 NOT ASSESSED 并给出'先补门禁'或'改走全量流程'两条出路；门禁记录为失败/有保留/未评估时直接停——在没过门的构建上做轻量补丁，等于迟到的门禁、范围还裁错了。"
  - R14 → "质量门禁的 NOT ASSESSED（套件根本没跑过）不得解读为'通过但带警告'：warnings 意味着有人看过并发现小问题，NOT ASSESSED 意味着没人看。要么补齐运行条件，要么把该项移出本次补丁。"

## 6. 关联文档
- 上游：`/gate-check release`（前提门禁，记录在 `production/gate-checks/`）、`/milestone-review`、`/security-audit`（开放安全项）、`/playtest-report`（pre-playtest 暴露 must-fix 的来源）。
- 下游：`/launch-checklist`（不需要 day-one patch 时的下一步；也是发布侧核查）、`/patch-notes`（必需产出）、`/bug-report verify` / `close`、`/bug-triage`（把缓议项排进 1.1）、`/retrospective`（上线后 48–72 小时复盘）。
- 引用：`project.yaml`（`project.stage`、`commands.test`）、`production/stage.txt`、`.claude/docs/directory-structure.md`（引擎测试根）。
