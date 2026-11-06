# team-polish — 协调打磨团队（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/team-polish/SKILL.md) ｜ 阶段：Phase 6 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/team-polish [feature or area to polish] [--review full|lean|solo]`
- **一句话职责**：编排打磨团队（性能分析→优化实现→视觉/音频打磨→加固→签核）打磨一个特性或区域，产出带前后指标的报告与三态发布就绪裁决。
- **触发前置**：必须给出打磨对象（如 `combat`、`main menu`、`inventory system`、`level-1`）；配置经 resolve_config 解析（`review_mode, automation, team.size, workflow`）；自动化模式遵循 `.claude/docs/automation-modes.md`（collaborative 每阶段须用户批准 · guided 自动推进除非 BLOCKED · autonomous 端到端并以 `log_decision` 记录；`automation_always_ask` 类别恒提示）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`review_mode, automation, team.size, workflow`（resolve_config；`--review` 覆盖 `review_mode`；无块 → `.claude/docs/config-resolution.md` 默认） | 决定门禁深度、自动化、活跃集 |
| 读取 | `project.yaml` 的 `performance.target_framerate / frame_budget_ms / draw_call_limit / memory_ceiling_mb`（经 `/perf-profile`）；art bible（VFX 一致性） | 帧预算与指标基线；四个预算键**无默认值**，未设即 NOT ASSESSED |
| 读取 | ADR（状态 Proposed 即阻塞实现）、story、GDD 等共享输入 | 只读一次，蒸馏后内联传入简报 |
| 产出 | `production/polish/[area]-report-[date].md`、`[area]-render-notes-[date].md`、`[area]-engine-fixes-[date].md`、`[area]-tool-fixes-[date].md`、`[area]-audio-notes-[date].md`、`[area]-verification-[date].md` | 每智能体一份带日期戳文件；`production/` 非 `docs/`（单次运行的测量，与 `production/qa/smoke-[date].md` 同形）；**目前无任何流程读 `production/polish/`**——报告时须说明它是记录而非后续门禁输入 |
| 派生智能体 | `performance-analyst`（profiling、内存分析、帧预算、optimisation list，**不写游戏代码**）；`engine-programmer`（渲染管线/内存/资源加载/热路径等引擎级项）；`technical-artist`（VFX 打磨、shader 优化、视觉质量）；`sound-designer`（音频打磨、混音、氛围层、反馈音）；`tools-programmer`（内容管线工具验证、编辑器工具稳定，仅当 Phase 1 追溯到内容创作工具）；`qa-tester`（边界、回归、soak 测试） | 活跃集由 `team.size` 决定（见 R4）；无 → 不存在"主会话直接执行"——所有分析均派生 |

## 3. 核心规则（逐条编号 R1、R2……）

### 入口与配置
R1. 无参数时输出用法引导并退出：`Usage: /team-polish [feature or area to polish] [--review full|lean|solo]`——**不用 AskUserQuestion**，不派生任何智能体。（出处：开头）
R2. 本管线**无 director gate**：任何 `review_mode` 下都不派生 CD-/TD-/PR-/AD-PHASE-GATE；阶段门禁是管线自身的决策点，在门禁上工作的是团队成员而非 director gate。（出处：Phase 0: Resolve Config）

### 活跃集（team.size）
R3. `team.size` 决定哪些智能体实际活跃（与 review_mode 门禁深度、workflow 文档正交）：`individual`（默认）= `performance-analyst` + `technical-artist`，其余智能体经这二者咨询、不单独 spawn——**无 programmer 活跃**，optimisation list 的 programmer 项本轮不实现，报告指名该列表交给 `/dev-story`；`small` = 上述 + `sound-designer` + `qa-tester` + `engine-programmer`，及 Phase 1 追溯到内容创作工具时的 `tools-programmer`；`studio` = `small` 全集 + 对抗性评审 pass——Phase 5 的 qa-tester 被告知"你的工作不是确认它成立——找出它怎么坏"，且报告说明该 pass 跑过。（出处：Phase 0 team.size）
R4. **Phase 1 前必须一行宣布活跃集，禁止让收缩沉默**：声明本次实际 spawn 哪些智能体、管线提名但本次**不** spawn 哪些（经最近活跃核心智能体咨询，"Raise team.size to widen"）。"被强制执行却从未浮现的约束，在读输出的人看来与从未执行的约束无法区分"——未说明时读者无法区分"正确收缩的运行"与"坏了的管线"。（出处：Announce the active set）
R5. 活跃集之外的智能体经**最近活跃核心智能体**路由并附说明性注释，适用全管线；"phase gate" = 本管线自列的以 `AskUserQuestion` 决策点结束的任何阶段（含管线内写明的 Gate 步骤），**无论 automation 模式**——guided/autonomous 只改变门禁的通过方式（自动推进或 `log_decision` 记录），不改变其门禁身份。（出处：Phase 0 team.size）

### 委派协议
R6. **简报不倾倒上下文**：共享输入只读一次，传蒸馏后的内联简报——只给各智能体真正需要的行；已读过的文档禁止只丢路径（拿到路径的智能体会重读整个文件）；只对未读且仅该智能体需要的文档传路径。（出处：How to Delegate）
R7. **每个智能体 prompt 以返回契约结尾**："把完整输出写到 `[path]`——该命名路径即你在有界例外下的写授权，无需另问批准；只返回 (1) 写入的路径、(2) ≤5 条决策摘要、(3) BLOCKED/CONCERNS 各一行；禁止复述你读过的文档。"缺它则智能体把读过的全部内容倒回本会话。**实现类文件是例外**：写代码/资产的智能体先返回将创建/修改的文件集，用户对整个集合答一次 yes 后其返回契约才点名它们（File Write Protocol）。（出处：How to Delegate）
R8. **有界写例外三条件**（subagent 写文件不逐次问的依据）：(1) 路径是**你**在 prompt 中命名的；(2) 是 `production/`、`docs/`、`tests/` 下的**新**产物，绝非对现有源码或配置的编辑；(3) 产出它的阶段本身受 `AskUserQuestion` 门禁。三条件外必须问。**禁止按 subagent 逐个问来"修复"此例外**——每阶段每智能体一次询问会让编排器不可用。（出处：Why this does not violate the Collaboration Protocol）
R9. 管线允许处并行启动独立智能体（Phase 3 与 Phase 4 可与 Phase 2 同时跑）；每个智能体写各自单独命名的文件（见 §2 表），避免并行写竞争。（出处：How to Delegate）

### 管线
R10. **Phase 1 评估**（performance-analyst）：用 `/perf-profile` 对目标区域做性能剖析；识别瓶颈与帧预算违规；测内存并查泄漏；对标目标硬件。输出按优先级排序的 **optimisation list**——每项含变更内容、对预算的预期收益、owner（渲染侧变更→technical-artist；引擎系统与热路径→engine-programmer；内容创作工具→tools-programmer；否则拥有该系统的 programmer）。performance-analyst **不写游戏代码**（"recommend and assign"）。（出处：Phase 1: Assessment）
R11. **Phase 2 优化**：经活跃集中的 owner 实现 Phase 1 列表——`engine-programmer` **仅当** Phase 1 发现引擎级根因（渲染管线、资源加载、内存分配器、核心循环热路径）才 spawn：实现那些项、修分配压力、验证玩法行为不变，输出带前后指标与 profiler 验证；`tools-programmer` **仅当** Phase 1 追溯到内容创作工具：修工具，输出带前后指标；technical-artist 的渲染侧项（draw call、overdraw、粒子、shader、LOD）并入其 Phase 3 简报。（出处：Phase 2: Optimization）
R12. Phases 2–4 的每个实现类智能体**先返回将创建/修改的文件集**，你在任何编辑前对**整个 Phase 2–4 集合**问一次（"May I have [agents] change these [N] files?"），yes 后各自只改自己的——一次问集合，不是每阶段一问。（出处：Phase 2 + File Write Protocol）
R13. **owner 不在活跃集的项本轮不实现**：`individual` 下即全部 programmer 项；任何档位下也包括本管线未提名的 programmer 的项（如 gameplay-script 热点的 gameplay-programmer）。报告将这些项连同 owner 列在 "Optimisation list handed to `/dev-story`" 下；其目标指标超预算在 Phase 6 仍是已知问题。（出处：Phase 2）
R14. **Phase 3 视觉打磨**（与 Phase 2 并行，technical-artist）：对照 art bible 审 VFX 质量与一致性；优化粒子系统与 shader 效果；适度添加 screen shake、镜头效果与 visual juice；确保效果在低画质设置下优雅降级。（出处：Phase 3）
R15. **Phase 4 音频打磨**（与 Phase 2 并行，sound-designer）：审音频事件完整性（有无动作缺声音反馈）；查混音电平（无过响/过轻）；加氛围音频层；验证空间定位正确。（出处：Phase 4）
R16. **Phase 5 加固**（qa-tester）：测所有边界情况（边界条件、快速输入、异常序列）；soak test 长时运行查退化；压力测试（最大实体、最坏场景）；回归测试逐项点名 Phases 2–4 的每个变更（含引擎级修复）；最低规格硬件测试（如有）；输出测试结果与遗留问题。（出处：Phase 5: Hardening）
R17. **Phase 6 签核**：汇总全员结果；指标对照预算；报告 READY FOR RELEASE / NOT ASSESSED / NEEDS MORE WORK；逐条列遗留问题，带严重度（S1–S4）、可测处的实测差距（如 "9 ms against a 6 ms budget — 3 ms over"）与建议；回归须点名被破坏的行为与肇因的打磨变更。（出处：Phase 6: Sign-off）

### 收尾
R18. **先验证工件**：返回契约命名了路径的，先确认路径在盘上——**命名的工件不在磁盘上即失败阶段，无论回复读起来多流畅**（智能体可烧掉一整个阶段后返回一段像样的开场白而什么都没写，这既非 BLOCKED 也非错误，所以常规触发器不点火）；点名未满足的契约让其续跑。任何智能体返回 BLOCKED/错误/不能完成：**立即呈现、不越过其阻塞的依赖、总出部分报告**；跳过的智能体小节保持命名空缺，禁止用自己的内容填充。（出处：Error Recovery Protocol）
R19. 常见阻塞：输入文件缺失（story 找不到、GDD 缺）→ 重定向到创建它的技能；ADR 状态为 Proposed → 不实现，决定后以 `/architecture-decision accept ADR-NNNN` 接受；范围过大 → 经 `/create-stories` 拆成两个 story；ADR 与 story 指令冲突 → 呈现冲突，禁止猜。（出处：Error Recovery Protocol）
R20. **File Write Protocol**：报告/测试结果/证据类写入走有界例外（R8）；Phases 2–4 的优化与打磨**修改现有代码、shader、音频或资产**，在例外之外——按 R12 集合式先问后写。**本编排器不直接写文件**。（出处：File Write Protocol）
R21. 汇总报告须覆盖：性能前后指标、视觉打磨变更、音频打磨变更、测试结果、交给 `/dev-story` 的 optimisation list（如有）、发布就绪评估。（出处：Output）
R22. 下一步：READY FOR RELEASE → 跑 `/release-checklist` 做最终发布前验证；NEEDS MORE WORK → 遗留问题排入 `/sprint-plan update`（`workflow: minimal` 无 sprint 时加进 brief 的 build order），修复后重跑 `/team-polish`；NOT ASSESSED → 补齐缺失——把未设的 `performance.*` 预算写进 `project.yaml`（`/settings`）或跑没跑的阶段（升 `team.size`），然后重跑，**禁止**把该区域视为 release-ready；报告把 optimisation list 交给 `/dev-story` → 在那里实现后再重跑 `/team-polish` 测收益；跑 `/gate-check` 取正式阶段门禁裁决后再交发布。（出处：Next Steps）

## 4. 门禁与裁决
- **三态签核**（Phase 6）：READY FOR RELEASE / NOT ASSESSED / NEEDS MORE WORK。
- **排序**：NEEDS MORE WORK > NOT ASSESSED > READY FOR RELEASE（"NOT ASSESSED ranks above READY FOR RELEASE and below NEEDS MORE WORK"）。
- **NEEDS MORE WORK**：存在已知问题——指标超预算、未解决的回归——无论还有什么没查。
- **NOT ASSESSED**（其余情况）：范围内任何部分无法检查，绝不 READY FOR RELEASE，且报告逐个点名空缺——(a) 无 committed 预算的指标：`performance.target_framerate`、`performance.frame_budget_ms`、`performance.draw_call_limit`、`performance.memory_ceiling_mb` 无默认值，`/perf-profile` 把未设的报为 NOT ASSESSED（没有对比，就没有达标）；(b) 没跑的阶段：BLOCKED、跳过、或其智能体不在活跃集（`individual` 下音频打磨与加固只被咨询未运行，Phase 2 的 programmer 项交给 `/dev-story` 而非实现）。
- 本管线自身门禁即决策点（无 director gate、无 CD/TD/PR/AD-PHASE-GATE）。

## 5. 移植建议
- **可直接移植**：R4-R8（活跃集宣布、路由、返回契约、有界写例外）、R7（简报不倾倒）、R12-R13（集合式先问后写、不在集内的项如实移交）、R17-R18（三态签核、工件在盘核验）、R22（NOT ASSESSED 补齐后重跑、禁止视为就绪）。
- **需替换概念**：`/perf-profile` → 项目的性能剖析流程；帧预算/`performance.*` 键 → 项目的性能/资源预算配置；art bible → 视觉规范；`/dev-story`、`/sprint-plan`、`/gate-check`、`/release-checklist` → 对应的实现排期与门禁技能；soak/stress test → 长稳/压力测试。
- **改写示例**：
  - R4 → "多角色管线按档位收缩后，必须在启动前用一行声明本次实际激活的角色与被咨询替代的角色。被强制执行却未向用户浮现的约束，与从未执行的约束无法区分。"
  - R17 → "交付评审三态裁决按序判定：存在已确认的未解决问题（指标超标、回归）判 NEEDS MORE WORK；否则任何未评估项（无基线的指标、未运行的角色）判 NOT ASSESSED 并逐个点名；两者皆无才可判 READY。未评估的部分不是通过的部分。"

## 6. 关联文档
- 上游：`/perf-profile`（Phase 1 评估工具）、`project.yaml` 的 `performance.*` 预算。
- 下游：`/dev-story`（接收 optimisation list）、`/release-checklist`（READY 后）、`/gate-check`（正式门禁）、`/sprint-plan`（NEEDS MORE WORK 时排期）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/error-recovery-protocol.md`。
