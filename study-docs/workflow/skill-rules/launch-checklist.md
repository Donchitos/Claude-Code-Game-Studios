# launch-checklist — 跨部门 Go/No-Go 上线核查（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/launch-checklist/SKILL.md) ｜ 阶段：Phase 7 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/launch-checklist [launch-date or 'dry-run']`（disable-model-invocation：仅显式调用）
- **一句话职责**：跨**全部部门**的上线就绪核查——代码、内容、商店、营销、社区、基础设施、法务七节——加"只有人能确认项"的逐节提问，以四态 Go/No-Go 与五方签核收尾。
- **触发前置**：配置经 resolve_config 解析（`rigor, workflow, project.stage, cert_tier, automation`）；自动化模式遵循 `.claude/docs/automation-modes.md`（collaborative 恒问 · guided 仅重大项 · autonomous 记录后继续；`automation_always_ask` 类别恒提示）。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键：`modes.rigor, workflow, project.stage, platform.cert_tier, modes.automation`（resolve_config；无块 → `.claude/docs/config-resolution.md` 默认） | 裁剪轴 + 认证档位 |
| 读取 | `CLAUDE.md`（技术栈、目标平台、团队结构）；`production/milestones/` 最新里程碑；`production/releases/` 现有 release checklist；`design/live-ops/content-calendar.md`（存在时） | 项目上下文 |
| 读取 | 代码根（`src/`、`Assets/`、`Source/`，按 `.claude/docs/code-root-resolution.md`）与资产根（`assets/`、`Assets/`、`Content/`）四项扫描：TODO/FIXME/HACK、debug 输出（`console.log`、`print()`）、占位资产（`placeholder`、`temp_`、`WIP_`）、硬编码测试/开发值（localhost、测试凭据、debug flags） | 每次扫描必须先立分母 |
| 读取 | `.claude/docs/effects-map.md` 的 `## platform.cert_tier` 节——**只读该节**（Grep 标题后有界 Read） | cert_tier 四档要求表 |
| 产出 | 会话内输出清单 + 摘要（Overall Status、总项数、blocking/conditional/not-assessed 计数、有未完成小节的部门）；非 dry-run 且用户同意后写 `production/releases/launch-checklist-[date].md` | dry-run 不写任何文件、不创建签核条目 |
| 派生智能体 | 无，主会话直接执行 | |

## 3. 核心规则（逐条编号 R1、R2……）

### 裁剪 preamble 与参数
R1. **清单必须裁剪到项目现状**（全发每一项会把读者训练成跳过清单）：`project.stage`——未达阶段的项 out of scope，说明而非留未勾；`modes.rigor`——`minimal` 丢弃纯流程重量的项；`platform.cert_tier`——**只**发目标档位的认证项。cert_tier 按四值 `none | itch | steam | console` 分支，禁止按平台名分支（`none` 不发认证节并说明；`itch` 仅 itch.io 要求；`steam` 为 Steamworks 无 console 项；`console` 为 TRC/XR/Lotcheck、存档规则、手柄映射、分级委员会）。（Scope preamble）
R2. cert_tier **unset** 时必须**问哪些平台在范围内**——答案映射到四个值上即本次运行的档位；定不出标 **`NOT ASSESSED — cert tier unknown`**。**Unset is not `none`**：决策与缺失决策不得产出相同输出。因配置缺失无法裁剪的项标 `NOT ASSESSED — platform/stage unknown`，禁止静默纳入（否则单平台项目收到 ~150 项、~140 项无法评估的清单）。（Scope preamble）
R3. 参数为上线日期或 `dry-run`。**dry-run 只生成清单，不创建签核条目、不写文件**；无参运行为正常运行、目标日期未设（`Target Launch: not set`）——只有参数明说 `dry-run` 才是 dry-run。（Phase 1）
R4. 载入项目上下文（见数据依赖表），不重问扫描或文件已定的事项。（Phase 2）

### Phase 3 — 带分母的扫描
R5. **本阶段每次扫描都是"找坏东西"的搜索，零命中天然歧义**："搜过没找到"或"没东西可搜"，绿勾选框把二者渲染得一样。每次扫描先建立分母并报告：`scanned [N] files, [M] hits`，或 `NOT ASSESSED — [code root unresolved | no source files | no asset folder | directory empty]`，**绝不裸勾**。例：无 `assets/` 目录时占位资产扫描零命中，裸勾会把 "All placeholder art replaced" 标绿。（Phase 3）
R6. **区分带进清单本身**：扫描 NOT ASSESSED 的项写 `- [?]` 而非 `- [ ]`——未勾选说"还有活"（干活可关闭），`[?]` 说"没人能查"（只有补输入才关闭）。`[?]` 出现处必附图例：`[?] = not assessed — the input to this check was absent`。（Phase 3）

### Phase 4 — 七节清单
R7. 生成七节清单（标题、Target Launch `[Date or DRY RUN]`、Generated）：**1 Code Readiness**——Build Health（全目标平台干净构建、零编译警告、全部单测/集成测试通过、性能基准达标、无内存泄漏——经扩展 soak test 验证、构建大小限额、版本号设置并打入源控 tag）；Code Quality（TODO 零或记录例外、FIXME 零必需、HACK 每项有记录理由、无 debug 输出、无硬编码 dev/test 值、feature flags 全部生产值、关键路径错误处理、崩溃上报集成并验证）；Security（源码无暴露 API key/凭据、存档加密、TLS/DTLS、多人时反作弊激活、服务器端点输入校验、隐私合规）；**2 Content Readiness**——占位美术/音频换终版、混音定稿 audio director 批准、VFX 打磨并性能验证、无缺失/损坏资产引用、命名约定、玩家文本校对、无硬编码字符串、全语言翻译验证、文本适配各语言 UI、字体覆盖、Credits 完整、关卡全通、教程流程新玩家测过、成就/奖杯实现测试、存/读档全状态、难度平衡、片尾完整；**3 Quality Assurance**——全回归套件通过、零 S1、零 S2 或记录例外（`workflow: full` 改为 S2 与 S3 全零无例外）、soak 用 `/soak-test` 跑的最长时长（游玩时长更长则手工更长）、多人压测、关键用户路径全平台、边缘 case（存储满、无网、休眠/恢复）；Platform Certification（R8）；Performance（最低规格 FPS、加载、内存、带宽、关键玩法时刻无掉帧）；**4 Store and Distribution**——商店页文案定稿校对、截图/预告片/主视觉时效与规格、系统要求、全区域定价、预购/愿望单；Legal（EULA 法律批准、隐私政策发布链接、第三方许可署名、音乐/音频授权、商标/IP 清障、GDPR/CCPA——数据收集、同意、删除）；**5 Infrastructure**——服务器（生产部署并压测、自动扩缩、数据库备份、CDN、DDoS 防护、监控告警）；分析（管道验证收数、崩溃面板、DAU/时长/留存/崩溃等关键指标、关键阈值告警）；**6 Community and Marketing**——社区规范、moderation 团队与工具、Discord/论坛/社媒、FAQ 与已知问题页、支持渠道；发布预告片、媒体/影响者 key、社媒排期、博客、上线版补丁说明发布；**7 Operations**——前 72 小时 on-call、事件响应 playbook 团队过目、回滚计划文档化并测试、hotfix 管道测过（4 小时内可出紧急修复）、发布问题沟通计划；Day-One Plan（day-one patch 备好、服务器解锁/go-live 流程文档、监控面板全员书签、war room）。（Phase 4）
R8. **Platform Certification 只发匹配 cert_tier 的块**，其余不发，绝不合成一条未门控的全量清单：`none` → 省略该节并一行说明 `Platform Certification: omitted — cert_tier is 'none' (internal/jam release).`；`itch`/`steam`/`console` 各自的块（同 `/release-checklist` 的档位内容）。**每档恒发**辅助功能行（最低标准：重映射、文本缩放、色盲）——它不受认证门控，不省略。（Phase 4）

### Phase 4b — 只有用户能确认的事
R9. 清单多数项无法从仓库定（on-call 排班、EULA、媒体 key、定价、某人跑过的 soak test）——不问就全部 unconfirmed，Overall Status 只能 NOT ASSESSED，所以**必须问**。七节各收一次"扫描与文件都没定"的项（Phase 3 计数与 Phase 2 读过的不重问），**每节一次 `AskUserQuestion`**，项编号列出；每项答案为 **yes / no / not yet / N/A**；选项：`Yes — all of them` / `Not yet — none of them` / `N/A — this section does not apply` / `Some differ — I'll answer per item`（用户逐项作答）。无可问的节跳过。yes → 打勾 `- [x]` 标 `(confirmed by the user)`；no/not yet → 失败项进 Blocking Items，或用户给出 workaround/接受风险时进 Conditional Items；N/A → 写 `- N/A — [item]` 且不计入 Overall Status；未作答项保持 unconfirmed，状态点名它。（Phase 4b）
R10. 这些是只有用户能答的**事实问题**，`collaborative` 与 `guided` 同样要问，**绝不代答**。`autonomous` 模式与 `dry-run` 跳过本阶段并声明——该项保持 unconfirmed，Overall Status 为 NOT ASSESSED。然后用答复填 Go/No-Go 节。（Phase 4b）

### Go / No-Go 与收尾
R11. **Overall Status 四态，首个命中即胜**：Blocking Items 非空 → **NOT READY**；否则任一项是 `- [?]`、任一节 NOT ASSESSED、或任一项仍 unconfirmed（既未凭证据打勾、未凭 4b 答复、未标 N/A、也未列入下方——逐个点名，多时按节分组）→ **NOT ASSESSED**；否则 Conditional Items 非空 → **CONDITIONAL**；否则 **READY**。NOT ASSESSED 高于 CONDITIONAL 与 READY——没人能查的项不是通过的项——低于 NOT READY——已知 blocker 永不被掩埋。（Phase 4）
R12. **Blocking Items** = 每个 FAIL 或未解决的发现且无记录 workaround、无明确接受的风险——发现问题的检查：FIXME、debug 输出、占位资产、硬编码 dev 值、开放 S1、失败的构建或测试。**Conditional Items** = 每个带记录 workaround 或明确接受风险的差距——如带理由的 HACK、带记录例外的 S2（`workflow: full` 不允许任何例外）；写明 workaround 或谁接受了风险。（Phase 4）
R13. Sign-Offs Required 五方：Creative Director（内容与体验质量）、Technical Director（技术健康与稳定）、QA Lead（质量与测试覆盖）、Producer（排期与整体就绪）、Release Manager（构建与部署就绪）。（Phase 4）
R14. 展示完成清单与摘要（Overall Status、总项数、blocking 计数、conditional 计数、not-assessed 计数、有未完成小节的部门）。非 dry-run 时问 "May I write this to `production/releases/launch-checklist-[date].md`?"——**回答前什么都不创建，连 `production/releases/` 目录也不建**；yes 才写文件，写入时一并建目录。（Phase 5）
R15. 下一步：`project.stage` 不是 `Release`（`Polish`、更早或 unset）时先跑 `/gate-check release`——它是上线前的就绪门禁。签核与部署经 `/team-release` 协调。（Phase 6）

## 4. 门禁与裁决
- **Overall Status 四态**（首匹配）：NOT READY > NOT ASSESSED > CONDITIONAL > READY。
- **取最严**：NOT ASSESSED 高于 CONDITIONAL/READY（没人能查的项不是通过的项），低于 NOT READY（已知 blocker 不被掩埋）；unconfirmed 项也触发 NOT ASSESSED。
- **`[?]` vs `[ ]` vs `- N/A`**：没人能查 / 还有活 / 明确不适用——三态不得互相折算。
- **消费方**：`/gate-check release`（stage 未到 Release 时先跑）、`/team-release`（签核与部署协调）。

## 5. 移植建议
- **可直接移植**：R5-R6（零命中歧义、分母先行、`[?]` 记法与图例）、R9-R10（每节一次提问、事实问题不代答、autonomous/dry-run 跳过并声明后果）、R11-R12（四态首匹配、blocking/conditional 按"有无 workaround/接受风险"划分）、R14（回答前连目录都不建）。
- **需替换概念**：七节部门划分 → 按项目领域重组（如"后端/前端/合规/运维/客服/市场"）；GDPR/CCPA、ESRB/PEGI、TRC/Lotcheck → 对应合规体系；`/soak-test`、`/smoke-check`、`/gate-check release`、`/team-release` → 对应稳定性/门禁/发布流程；五方签核 → 项目实际决策角色。
- **改写示例**：
  - R6 → "无法评估的清单项写 `- [?]` 而非 `- [ ]`：未勾选意味着还有活、`[?]` 意味着没人能查，二者只有前者靠干活关闭。凡出现 `[?]` 必附图例说明其含义。"
  - R9 → "清单中无法从仓库判定的事项（值班表、合同、外部发布物料）必须逐节向负责人提问确认，每节一次、每项答复为 yes/no/not yet/N/A；自动化运行时跳过提问但必须声明——被跳过的项计入未评估，整体状态不得为通过。"

## 6. 关联文档
- 上游：`/release-checklist`（Polish → Release 门禁 PASS 后进入本技能）、`production/milestones/`、`design/live-ops/content-calendar.md`。
- 下游：`/gate-check release`（stage 未到 Release 时的前置门禁）、`/team-release`（签核与部署协调）、`/soak-test`（soak 时长参照）。
- 引用：`.claude/docs/automation-modes.md`、`.claude/docs/config-resolution.md`、`.claude/docs/effects-map.md`（仅 `## platform.cert_tier` 节）、`.claude/docs/code-root-resolution.md`。
