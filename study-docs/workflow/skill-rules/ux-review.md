# ux-review — UX 规格校验（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/ux-review/SKILL.md) ｜ 阶段：Phase 4 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/ux-review [file-path 或 'all' 或 'hud' 或 'patterns']`
- **一句话职责**：在 UX 设计进入实现管线前校验 UX 规格、HUD 设计或交互模式库——无障碍、GDD 对齐、可实施性（readiness），输出四档裁决。
- **触发前置**：完成 `/ux-design` 之后、移交 `ui-programmer`/`art-director` 之前、Pre-Production → Production 门禁检查之前（该门禁要求关键屏幕有已评审 UX 规格）、UX 规格重大修订之后。只读校验：本技能从不编辑或写文件，只报告发现。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | 配置键 `workflow`（经 `hooks/yaml-helper.sh resolve_config`） | 决定交互模式库缺失时判 N/A 还是 NOT ASSESSED |
| 读取 | 待审文档：`design/ux/*.md`（按参数单文件 / `all` 全部 / `hud.md` / `interaction-patterns.md`） | 校验对象 |
| 读取 | `project.yaml` 的 `platform` 块（`platform.targets`、`platform.primary_input`、`platform.gamepad_support`、`platform.touch_support`）；无则回退 `.claude/docs/technical-preferences.md` 的 `## Input & Platform` 节；两者皆无才回退规格自身头部 | 输入方式覆盖检查的权威来源 |
| 读取 | `design/accessibility-requirements.md`（如存在） | 已承诺的无障碍等级（tier） |
| 读取 | `design/ux/interaction-patterns.md`（如存在） | 模式库一致性检查依据 |
| 读取 | 规格头部引用的各 GDD 的 UI Requirements 节（用 Grep 模式 `^#` 找标题，再用 offset/limit 读该范围） | GDD 对齐检查 |
| 读取 | `design/player-journey.md`（如存在） | 到达上下文（context-arrival）校验 |
| 产出 | 无文件产出——评审报告（含裁决）直接输出到会话 | 格式见 R12；本技能 READ-ONLY |
| 派生智能体 | 无，主会话直接执行 | — |

## 3. 核心规则（逐条编号 R1、R2……）

**参数与清单路由（Phase 1）**
R1. 必须按参数确定校验对象：具体文件路径→校验该文档；`all`→找出 `design/ux/` 下所有文件逐一校验；`hud`→`design/ux/hud.md`；`patterns`→`design/ux/interaction-patterns.md`；无参数→询问用户校验哪份规格。（出处：Phase 1）
R2. `all` 模式必须先输出汇总表（文件 | 裁决 | 主要问题），再逐份给出完整细节。（出处：Phase 1）
R3. 每份文件用哪套清单由其 `> **Template**:` 头部行决定（`/ux-design` 写入）：`UX Spec`→3A，`HUD Design`→3B，`Interaction Pattern Library`→3C。无该行的文件按文件名归类（`hud.md`→3B，`interaction-patterns.md`→3C，其余→3A），且报告必须写明所假设的清单及原因。（出处：Phase 1）

**交叉引用上下文（Phase 2）**
R4. 校验前必须加载五类上下文：① 输入与平台配置（见数据依赖表）；② `design/accessibility-requirements.md` 承诺的无障碍等级（如存在）；③ `design/ux/interaction-patterns.md`（如存在）；④ 规格头部引用的各 GDD 的 UI Requirements 节；⑤ `design/player-journey.md`（如存在）。（出处：Phase 2）
R5. 输入方式集合的推导必须以配置为准、而非规格头部：读 `project.yaml` 时——`targets` 含 `PC` 或 `Web` 则含键盘/鼠标；`gamepad_support` 为 Full 或 Partial 则含手柄；`touch_support` 为 Full 或 Partial 则含触屏；另加 `primary_input`。回退 `technical-preferences.md` 时用其显式 Input Methods 字段。两处均未配置才回退规格头部。（出处：Phase 2）

**3A：UX 规格清单（Phase 3A）**
R6. 完整性检查必须覆盖：头部含 Status/Author/Platform Target；Purpose & Player Need 为玩家视角需求；Player Context on Arrival；Navigation Position；Entry & Exit Points（全部进出）；Layout Specification（分区 + 组件清单表）；States & Variants 至少含 loading、empty/populated、error；Interaction Map 覆盖全部目标输入方式；Data Requirements（每个显示数据有来源系统与 owner）；Events Fired（每个玩家动作有对应事件或 null 说明）；Transitions & Animations 至少含进出场；Input Method Completeness Checklist（Platform Target 行每种输入方式一块，未勾选项列入 Open Questions）；Accessibility Requirements；Localization Considerations（文本元素最大字符数）；Acceptance Criteria（至少 5 条可测标准）。（出处：Phase 3A Completeness）
R7. 质量检查必须覆盖九维：玩家需求清晰度（玩家视角、目标不含糊、到达上下文具体）；状态完整性（error/empty 必查，异步屏必查 loading，含计时器或自动消失的状态必须写明时长）；输入方式覆盖（PC→纯键盘导航完整；主机/手柄→d-pad 导航与面部按键映射、不得要求鼠标级精度、焦点顺序定义）；数据架构（owner 不得为 "UI"——UI 不得持有游戏状态；实时数据须写明更新触发而非仅 "realtime"；所有数据元素须写 null 处理）；无障碍（达到或超过已承诺等级；Basic→禁纯颜色信息指示；Standard+→焦点顺序与文本对比度；Comprehensive+→关键状态变化的屏幕阅读器播报；色盲检查非颜色替代）；GDD 对齐（头部引用的每条 UI Requirement 均被覆盖、无越权 UI、无遗漏）；模式库一致性（交互组件引用模式库或标注新模式、不得重复规格化既有模式、新模式标记入库）；本地化（文本密集元素字符上限警告；布局关键文本按 40% 膨胀预留）；验收标准质量（QA 不看设计文档即可执行、含性能与分辨率标准、不得要求读另一文档才能评估）。（出处：Phase 3A Quality Checks）

**3B：HUD 清单（Phase 3B）**
R8. HUD 校验必须覆盖：HUD Philosophy；信息架构表覆盖所有 GDD 中有 UI Requirements 的系统；Layout Zones 含全部目标平台安全边距；每个 HUD 元素有完整规格（分区、可见性触发、数据源、优先级）；HUD States by Gameplay Context 至少含探索、战斗、对话/过场、暂停；Information Hierarchy 给每个元素优先级档（MUST KEEP / SHOULD KEEP / CAN HIDE / ALWAYS HIDE）；Visual Budget（最大同时元素数、最大屏幕占比）；Platform Adaptation 覆盖全部目标平台；Tuning Knobs（玩家可调元素）；至少 5 条可测验收标准。（出处：Phase 3B Completeness）
R9. HUD 质量检查：中央游戏区元素必须有隐藏可见性规则；GDD 中存在的每条信息要么进 HUD、要么显式归为 "hidden/demand"；色码元素必须有色盲变体；反馈与通知区元素必须有队列/优先级行为；同时元素总数在 Visual Budget 内；`design/gdd/systems-index.md` 中 UI 类系统全部在 HUD 有代表或有理由的缺席。（出处：Phase 3B Quality / GDD Alignment）

**3C：模式库清单（Phase 3C）**
R10. 模式库校验必须覆盖：目录索引与实际模式一致；全部标准控件模式已规格化（按钮变体、toggle、slider、dropdown、list、grid、modal、dialog、toast、tooltip、progress bar、input field、tab bar、scroll）；当前 UX 规格所需的游戏专用模式齐备；每个模式含 When to Use、When NOT to Use、完整状态规格、无障碍规格、实现注记；动画标准表与声音标准表存在；模式间无冲突行为（如所有导航模式的 "Back" 行为一致）。（出处：Phase 3C）

**报告与裁决（Phase 4）**
R11. 裁决四档：**APPROVED**（完整、一致、可实施）；**NOT ASSESSED**（一个或多个评审维度无判定标准可比对，或规格无法读取——须点名是哪些）；**NEEDS REVISION**（存在具体缺口，移交前修复，非整体重做）；**MAJOR REVISION NEEDED**（范围、玩家需求或完整性存在根本问题，需大幅返工）。（出处：Overview）
R12. **NOT ASSESSED 排序高于 APPROVED、低于两个修订档**。规格文件读不了、某清单维度无比对基准、无障碍等级未承诺时必须出具 NOT ASSESSED；禁止因"找不到可比标准"而默认放行。（出处：Overview）
R13. 报告必须按固定结构输出：文档名、日期、Reviewer、文件路径、所用清单（3A/3B/3C 及来源）、Platform Target、Accessibility Tier；Completeness（X/Y 节，逐项勾选并标 MISSING）；Quality Issues（每条含 [BLOCKING / ADVISORY]、问题描述、位置、修复动作）；GDD Alignment（ALIGNED / GAPS FOUND，含 X/Y 覆盖与缺失清单）；Accessibility（COMPLIANT / GAPS / NON-COMPLIANT / NOT ASSESSED）；Pattern Library（CONSISTENT / INCONSISTENCIES FOUND / N/A）；最终 Verdict 及 BLOCKING/Advisory/未评估维度计数。（出处：Phase 4）
R14. `design/accessibility-requirements.md` 不存在即无已承诺等级，该维度必须报 `Accessibility: NOT ASSESSED — no committed tier`，禁止报 COMPLIANT——与缺席标准比对通过等于永假的断言通过；规格头部若自报等级只能作为**假设（assumption）**沿用并明说。此规则与 `/team-ui` Phase 4 镜像以防漂移，并建议运行 `/ux-design accessibility` 确立等级。（出处：Phase 4 Accessibility 注）
R15. Pattern Library 判定规则：HUD 设计无模式库清单可比，报 `N/A — no pattern library checklist for this document type` 且不计入维度数；UX 规格在 `workflow: minimal`（该档不要求模式库）时才可报 N/A；`standard`/`full` 下 `design/ux/interaction-patterns.md` 缺失必须报 `NOT ASSESSED`——是缺库而非超范围。（出处：Phase 4 Pattern Library 注）
R16. 各裁决的后续话术：APPROVED→建议运行 `/team-ui` 进入实现协调；NOT ASSESSED→逐维度点名缺失输入并主动提供帮助（`/ux-design accessibility`、补 GDD 路径），禁止对同样缺失输入重跑评审并换裁决——只有新输入能改变它；NEEDS REVISION→提议帮助修复具体缺口但禁止自动修复，等用户指令；MAJOR REVISION NEEDED→建议带具体小节回到 `/ux-design` 重做。（出处：Phase 5）
R17. 禁止阻断用户推进——裁决是建议性的：记录风险、呈现发现、由用户决定是否带着 CONCERNS/NEEDS REVISION 继续；选择继续的用户承担已记录的风险。（出处：Phase 5）

## 4. 门禁与裁决
- 本技能自身即为 UX→实现的质检关（quality gate），无派生门禁智能体。
- 裁决词：APPROVED / NOT ASSESSED / NEEDS REVISION / MAJOR REVISION NEEDED；排序（宽→严）：APPROVED < NOT ASSESSED < NEEDS REVISION < MAJOR REVISION NEEDED。
- 问题分两级：BLOCKING（实现前必须解决）与 ADVISORY（建议但不阻断）。

## 5. 移植建议
- **可直接移植**：R1–R5、R11–R17（四档裁决与 NOT ASSESSED 排序规则、只读评审、缺席标准不得判合规、评审后话术、不阻断用户）全部与游戏无关，可整体搬入任何项目的文档评审规则。
- **需替换概念**：GDD UI Requirements → 需求文档的功能需求条目；HUD/屏幕 → 仪表盘/页面；输入方式（键鼠/手柄/触屏）→ 目标平台交互通道；色盲/屏幕阅读器等无障碍等级 → 项目的可访问性标准（WCAG 档位等）；模式库 → 组件库/设计系统。
- **改写示例**：
  - "评审任何设计文档时，若某评审维度的判定基准文件不存在，必须报 NOT ASSESSED 并点名缺失输入，禁止报告为合规——与缺席标准比对通过等于永真断言。"
  - "评审技能必须只读：只输出发现与裁决，不修改被审文档，不自动修复缺口；裁决为建议性，由用户决定是否带风险继续。"

## 6. 关联文档
- 上游：`/ux-design`（产出被审文档及其 `> **Template**:` 头部行）
- 下游：`/team-ui` Phase 2（Visual Design，APPROVED 后进入）；Pre-Production → Production 门禁
- 镜像规则所在：`/team-ui` Phase 4（无障碍 NOT ASSESSED 规则）；规范文档 `.claude/docs/config-resolution.md`
