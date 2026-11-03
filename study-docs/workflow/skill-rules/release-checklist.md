# release-checklist — 发布前验证清单（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/release-checklist/SKILL.md) ｜ 阶段：Phase 7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/release-checklist [platform: pc|console|mobile|all]`
- **一句话职责**：生成**裁剪到项目现状**的发布前核查清单——构建验证、认证要求、商店元数据、上线就绪——以三态 Go/No-Go 收尾，供发布门禁与签核使用。
- **触发前置**：配置经 resolve_config 解析（`rigor, workflow, project.stage, cert_tier, automation`）；自动化模式遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续；`automation_always_ask` 类别恒提示）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`modes.rigor, workflow, project.stage, platform.cert_tier, modes.automation`（resolve_config；无块 → `.claude/docs/config-resolution.md` 默认） | 三条裁剪轴 + 认证档位 |
| 读取 | `CLAUDE.md`（项目上下文、版本信息、平台目标）；`production/milestones/` 当前里程碑（本版应含的特性）；`production/qa/bugs/*.md` 的 `**Severity**`/`**Status**` 行（同 `/bug-triage` 的读法） | 版本/范围/开放 bug |
| 读取 | 代码根（`src/`、`Assets/`、`Source/`，按 `.claude/docs/code-root-resolution.md` 解析）扫 TODO/FIXME/HACK；测试输出目录或 CI 日志 | 代码健康；缺测试结果必须声明 |
| 读取 | `.claude/docs/effects-map.md` 的 `## platform.cert_tier` 节——**只读该节**（Grep 标题后有界 Read），整文件不是运行时输入 | cert_tier 四档的完整要求表 |
| 产出 | 会话内输出清单；用户同意后写 `production/releases/release-checklist-[version].md`（必要时建目录） | 展示时报告总项数与已知 blocker 数 |
| 派生智能体 | 无，主会话直接执行 | |

## 3. 核心规则（逐条编号 R1、R2……）

### 裁剪 preamble（清单开头强制节）
R1. **清单必须裁剪到项目现状**——为每个平台全发每一项会把读者训练成跳过清单，门禁即失效。三条裁剪轴：`project.stage`——未达阶段的项 out of scope，**说明而非留一堆未勾项**；`modes.rigor`——`minimal` 时丢弃仅因流程重量而存在的项；`platform.cert_tier`——**只**发目标档位的认证项。（Scope preamble）
R2. cert_tier 按**它实际取的四个值**分支——`none | itch | steam | console`——禁止按平台名分支：`none` 完全不发认证节（内部构建、alpha 或 jam，说明省略及原因，不留空白）；`itch` 仅 itch.io 上传要求（构建大小、页面、年龄标签），无 console 无 Steamworks 项；`steam` 为 Steamworks（商店页、depot 构建、成就、系统要求、通用内容规则），无 console 认证项；`console` 为完整平台认证（TRC/XR/Lotcheck）、存档规则、手柄映射规则、分级委员会——最重的一档。（Scope preamble）
R3. cert_tier **unset** 时必须**问哪些平台在范围内**，而非全发——unset 是一个问题，不是全发认证轨道的许可；定不出则该节标 **`NOT ASSESSED — cert tier unknown`**。**Unset is not `none`**：`none` 是决策，unset 是缺失决策，二者不得产出相同输出。（Scope preamble）
R4. 因配置缺失而无法裁剪的项标 **`NOT ASSESSED — platform/stage unknown`**，禁止静默纳入——否则一个 `rigor: standard` 单平台项目会收到 ~150 项清单（PC+console+mobile 认证加分级），其中 ~140 项无法评估。（Scope preamble）

### Phase 1-3 — 参数与扫描
R5. 参数为 `pc|console|mobile|all`，缺省 `all`。**参数选择 DEVICE（设备）要求，绝不选择认证轨道**——认证由 `platform.cert_tier` 决定。两个轴是恰好共享一个词的不同清单：`pc/console/mobile` 是硬件形态，`none|itch|steam|console` 是认证制度，只在 `console` 重合；`itch` 与 `none` 根本没有设备块，`mobile` 不是 cert_tier 值。`all` **不是**全发认证轨道的许可。（Phase 1）
R6. 载入 `CLAUDE.md`、当前里程碑、开放 bug（grep Severity/Status 行；bug 只要 Status 不是 `Closed` 或 `Verified Fixed` 即开放）。bug 项采用 `/gate-check release` 对 resolved `workflow` 的阈值：`full` 档开放 S1、S2 或 S3 任一即该项 FAIL；`standard`/`minimal` 只有开放 S1 FAIL，开放 S2/S3 列入 Rationale 作为风险。每个 FAIL 的 bug 在 Rationale 点名为 blocking 项。**`production/qa/bugs/` 无 bug 文件** → bug 项读 **`NOT ASSESSED — no bug records`**——绝不报零、绝不打勾：缺失记录与干净记录不得产出同一清单；bug 用 `/bug-report` 提交。（Phase 2）
R7. **每个计数必须带分母**：报告 `scanned [N] source files: [M] TODO, [M] FIXME, [M] HACK`；代码根解析不出 → **`NOT ASSESSED — code root unresolved`**；代码根不存在或无源文件 → **`NOT ASSESSED — no source files found to scan`**。**裸 `0` 不是结果**——这些扫描在找坏东西，0 意为"搜过没找到"或"没东西可搜"，在发布门禁上是相反的发现。测试结果：任何测试输出目录或 CI 日志都没有时必须声明 **`Test results: NOT ASSESSED — no test output or CI logs found`**——缺失的测试结果与通过的结果不得产出同一清单。（Phase 3）

### Phase 4 — 生成清单
R8. 固定节：**Codebase Health**（Scanned/TODO/FIXME/HACK 计数；TODO 多时列 top 5，FIXME 全列——潜在 blocker，HACK 全列——需评审）；**Build Verification**（全目标平台干净构建、零编译警告 zero-warning policy、资产含入并正确加载、构建大小在预算内、版本号正确设置、可从 tagged commit 复现构建）；**Quality Gates**（开放 bug 计数 `N S1, N S2, N S3` 或 NOT ASSESSED、零开放 S1、零 S2+S3 无例外行**仅 `workflow: full`**——`standard`/`minimal` 下开放 S2/S3 进 Rationale 风险、关键路径全测且 QA 签核、性能预算：最低规格达标 FPS/内存/加载时间/长会话无泄漏、对上一版无回归、soak test 4+ 小时连续游玩通过）；**Content Complete**（占位资产换终版、内容文件 TODO/FIXME 解决或记录、玩家文本校对、本地化就绪无硬编码字符串、音频混音定稿并批准、Credits 完整准确）。（Phase 4）
R9. **设备节按参数加**（PC：最低/推荐规格、键鼠、手柄 Xbox/PlayStation/通用、分辨率缩放 1080p/1440p/4K/ultrawide、窗口/无边框/全屏、画质设置存取；Console：平台手柄提示、休眠/恢复、用户切换、断网优雅处理、存储满；Mobile：商店指南合规、权限说明、隐私政策、数据安全标签、多尺寸触控、电池、后台行为、推送权限、内购流程、商店大小限额）。设备节**不含任何认证或商店 SDK 项**——那些由 cert_tier 门控，混入会让 `itch` 项目拿到 Steamworks 行。**Mobile 商店行留在设备块是有意的**：cert_tier 建模 `none|itch|steam|console` 没有 mobile 档，App Store/Play Store 合规无法门控其上——禁止通过发明 `mobile` 档来"修复"（正是 R2 警告的错误词汇）。（Phase 4）
R10. **认证小节只发匹配 cert_tier 的那一个块**，其余块不发，也不因参数是 `all` 而全发。`none` → 原位发恰好一行使省略可见：`Certification: omitted — cert_tier is 'none' (internal build, alpha or jam release).`；`itch` → itch.io 块（上传限额、页面完整、年龄标签诚实、下载/浏览器构建决定并测试、Butler 渠道名）；`steam` → Steamworks 块（SDK 集成并测试、depot 全新账号干净安装、成就、云存档、Steam Deck 兼容、通用内容规则）；`console` → 全平台认证块（TRC/TCR/Lotcheck、第一方提交、奖杯集成、家长控制、存档规则合规——损坏/存储满/用户切换、ESRB/PEGI/区域分级）。unset → 问范围；定不了 → `### Certification: NOT ASSESSED — cert tier unknown` 并说明原因。认证行只属于这一个 cert_tier 门控小节，禁止放进设备块——否则无参运行的 `itch` 项目会同时拿到 Steamworks 与 Lotcheck 行。（Phase 4）
R11. **`console` 一词两义**：`**For \`console\`:**` 标题是参数门控（argument-gating），不是档位门控（tier-gating）——不得当作"认证已按档裁剪"的证据。（Phase 4）
R12. **Store / Distribution 与 Launch Readiness 两节全平台恒发**：商店页元数据（短/长描述、特性列表、系统要求）、截图按平台分辨率、预告片、主视觉与 capsule 图、分级获取并配置（ESRB/PEGI/区域）、法务（EULA、隐私政策、第三方许可署名）、全区域定价；上线就绪（分析/遥测验证并收数、崩溃上报配置且面板可用、day-one patch 备好并测试（如需）、前 72 小时 on-call 排班、社区发布公告起草、媒体/影响者 key 备好、支持团队已知问题与 FAQ 简报、回滚计划文档化）。（Phase 4）
R13. **Go / No-Go 三态，首个命中即胜**：任一 blocking 项 FAIL → **NOT READY**；否则任一节或项 NOT ASSESSED（逐个点名）→ **NOT ASSESSED**；否则 **READY**。NOT ASSESSED 高于 READY——未评估的节不是通过的节——且低于 NOT READY——已知 blocker 永不被掩埋。附 Rationale（就绪摘要、launch 前必须解决的 blocking 项、NOT READY 时列具体项与解决估时）与 Sign-offs Required（QA Lead、Technical Director、Producer、Creative Director）。（Phase 4）

### Phase 5-6 — 保存与下一步
R14. 先向用户展示：总清单项数、已知 blocker 数（FIXME/HACK 计数、已知 bug）。问 "May I write this to `production/releases/release-checklist-[version].md`?"——yes 才写文件（需要时建目录）。（Phase 5）
R15. 下一步：未起草则先 `/changelog`、`/patch-notes`（发布门禁会查它们）；跑 `/gate-check release`——Polish → Release 门禁读本清单；PASS 后 `/launch-checklist`，再经 `/team-release` 协调发布。（Phase 6）

## 4. 门禁与裁决
- **Go / No-Go 三态**（首匹配）：NOT READY（任一 blocking 项 FAIL）> NOT ASSESSED（任一节/项 NOT ASSESSED，逐个点名）> READY。
- **bug 阈值**（沿用 `/gate-check release` 对 resolved `workflow`）：`full`——开放 S1/S2/S3 任一该项 FAIL；`standard`/`minimal`——仅 S1 FAIL，S2/S3 进 Rationale 风险。
- **NOT ASSESSED 哲学**：缺失记录 ≠ 零记录（no bug records）、无分母 ≠ 零命中（裸 0 不是结果）、unset ≠ `none`。
- **消费方**：`/gate-check release`（读此清单的发布门禁）与 `/launch-checklist`。

## 5. 移植建议
- **可直接移植**：R1-R4（三轴裁剪、四档词汇表、Unset ≠ none、无法裁剪标 NOT ASSESSED）、R6-R7（缺失记录与干净记录不得同输出、带分母计数、"缺失测试结果必须声明"）、R13（三态首匹配 + NOT ASSESSED 排序）、R14（写文件先问）。
- **需替换概念**：`platform.cert_tier` → 项目的合规/上架档位（如 none|自托管|应用商店|企业审计）；Steamworks/itch.io/TRC/ESRB → 对应平台合规体系；soak test → 长时稳定性测试；`/gate-check release`、`/launch-checklist`、`/team-release`、`/bug-report`、`/changelog`、`/patch-notes` → 对应门禁与产出流程。
- **改写示例**：
  - R7 → "发布清单中每个'找坏东西'的扫描必须带分母：报告 `scanned N files: M hits`，无法建立分母时标 `NOT ASSESSED — [原因]`。禁止输出裸 0——'搜过没找到'与'没东西可搜'在发布门禁上是相反的发现。"
  - R3 → "档位配置 unset 时必须向用户确认范围，禁止按全量输出；确认不了标 `NOT ASSESSED — [档位] unknown`。unset（缺决策）与 none（明确决策为无）不得产出相同输出。"

## 6. 关联文档
- 上游：`/bug-report`（bug 记录）、`/bug-triage`（Severity/Status 读法与阈值来源）、`production/milestones/`。
- 下游：`/gate-check release`（读此清单）、`/launch-checklist`（PASS 后）、`/team-release`、`/changelog`、`/patch-notes`。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/effects-map.md`（仅 `## platform.cert_tier` 节）、`.claude/docs/code-root-resolution.md`。
