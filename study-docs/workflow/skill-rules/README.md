# skill-rules —— 73 个技能的规则抽取文档（AGENTS.md 移植版）

> 依据 [docs/WORKFLOW-GUIDE.md](file:///workspace/docs/WORKFLOW-GUIDE.md) 用到的全部 73 个技能，逐个从 [.claude/skills/&lt;名&gt;/SKILL.md](file:///workspace/.claude/skills) 抽取规则而成。
> 每份文档 = 一个技能的可移植规则包：忠实抽取流程步骤、强制/禁止行为、门禁裁决、读写文件、派生智能体、配置档位，改写成"必须……/禁止……"的祈使句规则，可直接搬进其它项目的 AGENTS.md / CLAUDE.md / skill 定义。
> 抽取模板见 [_TEMPLATE.md](file:///workspace/study-docs/workflow/skill-rules/_TEMPLATE.md)，73 份文档结构统一。

## 每份文档的统一结构

| 节 | 内容 |
|----|------|
| 1. 技能定位 | 命令、一句话职责、触发前置 |
| 2. 数据依赖 | 读取（文件/配置键）、产出（路径+格式）、派生智能体（subagent_type+职责） |
| 3. 核心规则 | R1、R2……逐条，带出处小节，覆盖全部 Phase 与收尾动作 |
| 4. 门禁与裁决 | 门禁 ID / 审查者 / 裁决标准 / 最严裁决（无门禁则省略） |
| 5. 移植建议 | 可直接移植条目 / 需替换概念 / 改写示例 |
| 6. 关联文档 | 上下游技能与引用文件 |

---

## 分类索引

### 一、导航与引导（6 个，Phase Any）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [start](file:///workspace/study-docs/workflow/skill-rules/start.md) | Any | 首次会话引导：问清处境，路由到正确阶段与技能 |
| [help](file:///workspace/study-docs/workflow/skill-rules/help.md) | Any | 读 stage.txt 与产物清单，给出"下一步做什么" |
| [project-stage-detect](file:///workspace/study-docs/workflow/skill-rules/project-stage-detect.md) | Any | 全项目审计，推断当前所处阶段与置信度 |
| [setup-engine](file:///workspace/study-docs/workflow/skill-rules/setup-engine.md) | P1 | 钉住引擎版本，写技术偏好与版本化引擎参考文档 |
| [adopt](file:///workspace/study-docs/workflow/skill-rules/adopt.md) | Any | 存量项目棕地审计：只补缺不改写（MIGRATION not REPLACEMENT） |
| [skill-improve](file:///workspace/study-docs/workflow/skill-rules/skill-improve.md) | Any | 测试-修复-重测循环改进技能文件 |

### 二、游戏设计（6 个，Phase 1-2）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [brainstorm](file:///workspace/study-docs/workflow/skill-rules/brainstorm.md) | P1 | 6 阶段协作式头脑风暴，产出带支柱/MDA 的概念书 |
| [map-systems](file:///workspace/study-docs/workflow/skill-rules/map-systems.md) | P1-2 | 概念分解为系统索引（依赖图+优先级梯队+设计顺序） |
| [design-system](file:///workspace/study-docs/workflow/skill-rules/design-system.md) | P2 | 逐节撰写 GDD；13 行系统类型→专家路由表；逐节落盘 |
| [quick-design](file:///workspace/study-docs/workflow/skill-rules/quick-design.md) | P2+ | 小改动轻量规格，替代整套 8 节 GDD |
| [review-all-gdds](file:///workspace/study-docs/workflow/skill-rules/review-all-gdds.md) | P2 | 跨 GDD 一致性 + 设计理论双阶段审查 |
| [propagate-design-change](file:///workspace/study-docs/workflow/skill-rules/propagate-design-change.md) | P5 | GDD 变更 git-diff，找出受影响 ADR/故事并逐个决策 |

### 三、UX 与架构（6 个，Phase 3-4）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [ux-design](file:///workspace/study-docs/workflow/skill-rules/ux-design.md) | P4 | 撰写 UX 规格（屏幕/流/HUD/交互模式库） |
| [ux-review](file:///workspace/study-docs/workflow/skill-rules/ux-review.md) | P4 | UX 规格对 GDD 与无障碍档位的校验 |
| [create-architecture](file:///workspace/study-docs/workflow/skill-rules/create-architecture.md) | P3 | 总架构文档；docs.density 控制每节深度 |
| [architecture-decision](file:///workspace/study-docs/workflow/skill-rules/architecture-decision.md) | P3 | 创建/改造 ADR，维护 TR 注册表，状态机 Proposed→Accepted |
| [architecture-review](file:///workspace/study-docs/workflow/skill-rules/architecture-review.md) | P3 | ADR 依赖拓扑排序、循环检测、引擎兼容校验 |
| [create-control-manifest](file:///workspace/study-docs/workflow/skill-rules/create-control-manifest.md) | P3 | 从 Accepted ADR 生成扁平程序员规则（带版本日期） |

### 四、故事与冲刺（8 个，Phase 4-5）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [create-epics](file:///workspace/study-docs/workflow/skill-rules/create-epics.md) | P4 | GDD+ADR 转史诗（一个架构模块一份 EPIC.md） |
| [create-stories](file:///workspace/study-docs/workflow/skill-rules/create-stories.md) | P4 | 史诗拆故事卡，内嵌 TR-ID/ADR 引用/manifest 版本戳 |
| [dev-story](file:///workspace/study-docs/workflow/skill-rules/dev-story.md) | P5 | 实现一张故事卡：开工检查→程序员路由→校验产出→交接 |
| [sprint-plan](file:///workspace/study-docs/workflow/skill-rules/sprint-plan.md) | P4-5 | 冲刺计划 + sprint-status.yaml 机器可读跟踪 |
| [sprint-status](file:///workspace/study-docs/workflow/skill-rules/sprint-status.md) | P5 | 30 行冲刺快照 |
| [story-readiness](file:///workspace/study-docs/workflow/skill-rules/story-readiness.md) | P4-5 | 领取前校验：READY / NEEDS WORK / BLOCKED |
| [story-done](file:///workspace/study-docs/workflow/skill-rules/story-done.md) | P5 | 8 阶段完成审查：验收、偏差、状态更新、下一个故事 |
| [estimate](file:///workspace/study-docs/workflow/skill-rules/estimate.md) | P4-5 | 工作量与风险评估 |

### 五、审查与分析（13 个，Phase 1-7）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [design-review](file:///workspace/study-docs/workflow/skill-rules/design-review.md) | P1-2 | 按 8 节标准校验设计文档 |
| [code-review](file:///workspace/study-docs/workflow/skill-rules/code-review.md) | P5+ | 架构级代码审查 |
| [balance-check](file:///workspace/study-docs/workflow/skill-rules/balance-check.md) | P5-6 | 数值平衡分析（离群值/曲线/退化策略） |
| [asset-audit](file:///workspace/study-docs/workflow/skill-rules/asset-audit.md) | P6 | 资产命名/格式/体积预算审计 |
| [asset-spec](file:///workspace/study-docs/workflow/skill-rules/asset-spec.md) | P5-6 | 逐资产视觉规格与 AI 生成提示词 |
| [content-audit](file:///workspace/study-docs/workflow/skill-rules/content-audit.md) | P5 | 设计规定内容 vs 已实现内容 |
| [consistency-check](file:///workspace/study-docs/workflow/skill-rules/consistency-check.md) | P2+ | 跨文档实体与公式一致性扫描 |
| [scope-check](file:///workspace/study-docs/workflow/skill-rules/scope-check.md) | P5 | 范围蔓延检测与削减建议 |
| [perf-profile](file:///workspace/study-docs/workflow/skill-rules/perf-profile.md) | P6 | 结构化性能剖析（瓶颈排序→可执行优化任务） |
| [tech-debt](file:///workspace/study-docs/workflow/skill-rules/tech-debt.md) | P6 | 技术债扫描（TODO/FIXME/重复/复杂度/缺测试）与优先级 |
| [gate-check](file:///workspace/study-docs/workflow/skill-rules/gate-check.md) | 全阶段切换 | 正式阶段门禁：六门清单、总监并行评审、最严裁决、stage.txt 更新条件 |
| [reverse-document](file:///workspace/study-docs/workflow/skill-rules/reverse-document.md) | Any | 从现有代码反向生成设计文档 |
| [security-audit](file:///workspace/study-docs/workflow/skill-rules/security-audit.md) | P6-7 | 安全漏洞审计（存档/网络/输入） |

### 六、QA 与测试（9 个，Phase 4-6）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [qa-plan](file:///workspace/study-docs/workflow/skill-rules/qa-plan.md) | P5 | QA 测试计划 |
| [smoke-check](file:///workspace/study-docs/workflow/skill-rules/smoke-check.md) | P5-6 | 关键路径冒烟门，QA 交接前必过 |
| [soak-test](file:///workspace/study-docs/workflow/skill-rules/soak-test.md) | P6 | 长时间浸泡测试协议 |
| [regression-suite](file:///workspace/study-docs/workflow/skill-rules/regression-suite.md) | P5-6 | 回归覆盖映射，识别缺回归测试的已修 bug |
| [test-setup](file:///workspace/study-docs/workflow/skill-rules/test-setup.md) | P4 | 测试脚手架与 CI/CD |
| [test-helpers](file:///workspace/study-docs/workflow/skill-rules/test-helpers.md) | P4-5 | 引擎专属测试辅助库 |
| [test-evidence-review](file:///workspace/study-docs/workflow/skill-rules/test-evidence-review.md) | P5 | 测试文件与手工证据质量审查 |
| [test-flakiness](file:///workspace/study-docs/workflow/skill-rules/test-flakiness.md) | P5-6 | 从 CI 日志检测非确定性测试 |
| [skill-test](file:///workspace/study-docs/workflow/skill-rules/skill-test.md) | Any | 技能文件结构与行为校验 |

### 七、制作管理（6 个，Phase 4-6）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [milestone-review](file:///workspace/study-docs/workflow/skill-rules/milestone-review.md) | P5 | 里程碑完整性与 go/no-go |
| [retrospective](file:///workspace/study-docs/workflow/skill-rules/retrospective.md) | P5 | 冲刺复盘（计划 vs 完成、速度、阻塞、改进项） |
| [bug-report](file:///workspace/study-docs/workflow/skill-rules/bug-report.md) | P5+ | 结构化 bug 报告 |
| [bug-triage](file:///workspace/study-docs/workflow/skill-rules/bug-triage.md) | P5+ | bug 重新分诊（severity/priority 双梯子） |
| [playtest-report](file:///workspace/study-docs/workflow/skill-rules/playtest-report.md) | P4-6 | 结构化试玩报告 |
| [onboard](file:///workspace/study-docs/workflow/skill-rules/onboard.md) | Any | 新成员入职 |

### 八、发布（6 个，Phase 7+）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [release-checklist](file:///workspace/study-docs/workflow/skill-rules/release-checklist.md) | P7 | 发布前验证清单 |
| [launch-checklist](file:///workspace/study-docs/workflow/skill-rules/launch-checklist.md) | P7 | 跨部门 Go/No-Go 上线核查 |
| [changelog](file:///workspace/study-docs/workflow/skill-rules/changelog.md) | P7 | 内部技术变更日志 |
| [patch-notes](file:///workspace/study-docs/workflow/skill-rules/patch-notes.md) | P7 | 玩家语言补丁说明（含溯源检查：框架提交不得渲染成玩家文案） |
| [hotfix](file:///workspace/study-docs/workflow/skill-rules/hotfix.md) | P7+ | 紧急修复：绕过常规冲刺但留全审计轨迹 |
| [day-one-patch](file:///workspace/study-docs/workflow/skill-rules/day-one-patch.md) | P7+ | 金母盘后问题的当日补丁 |

### 九、创意（4 个，Phase 1-7）

| 技能 | 阶段 | 一句话 |
|------|------|--------|
| [prototype](file:///workspace/study-docs/workflow/skill-rules/prototype.md) | P1 | 概念原型验证核心创意，PROCEED/PIVOT/KILL 裁决 |
| [art-bible](file:///workspace/study-docs/workflow/skill-rules/art-bible.md) | P1-2 | 美术圣经（视觉识别规格）9 节撰写 |
| [vertical-slice](file:///workspace/study-docs/workflow/skill-rules/vertical-slice.md) | P4 | 生产级垂直切片，硬门禁：人不玩不给过 |
| [localize](file:///workspace/study-docs/workflow/skill-rules/localize.md) | P6-7 | 字符串提取与本地化校验（十个子命令） |

### 十、团队编排（9 个，Phase 5-7+）

六阶段同构：设计→架构→并行实现→集成→验证→汇报；班底各异，决策点留给用户。

| 技能 | 阶段 | 班底要点 |
|------|------|----------|
| [team-combat](file:///workspace/study-docs/workflow/skill-rules/team-combat.md) | P5 | game-designer + 程序员×2 + 技术美术 + 音频 + 引擎专家 + QA |
| [team-narrative](file:///workspace/study-docs/workflow/skill-rules/team-narrative.md) | P5 | 叙事团队；ND-CONSISTENCY 门禁每个 review_mode 必跑 |
| [team-ui](file:///workspace/study-docs/workflow/skill-rules/team-ui.md) | P5 | UX 评审门；无障碍档位缺席即 NOT ASSESSED |
| [team-level](file:///workspace/study-docs/workflow/skill-rules/team-level.md) | P5 | 视觉方向先于布局；相邻区域依赖检查 |
| [team-audio](file:///workspace/study-docs/workflow/skill-rules/team-audio.md) | P5-6 | 关键音频无障碍缺口 BLOCKING |
| [team-polish](file:///workspace/study-docs/workflow/skill-rules/team-polish.md) | P6 | 性能+美术+音频+手感并行打磨 |
| [team-release](file:///workspace/study-docs/workflow/skill-rules/team-release.md) | P7 | 构建 + QA 签核 + 部署协调（11 个 subagent） |
| [team-live-ops](file:///workspace/study-docs/workflow/skill-rules/team-live-ops.md) | P7+ | 长线运营规划（赛季/通行证/留存） |
| [team-qa](file:///workspace/study-docs/workflow/skill-rules/team-qa.md) | P6-7 | 完整 QA 周期：策略→执行→覆盖→签核 |

---

## 如何组装成其它项目的 AGENTS.md

三步法（按移植深度递增）：

**策略 A —— 只拿通用规则（最快）**
1. 挑与你项目痛点对应的技能文档（如：任何项目都值得拿 `code-review`、`story-readiness`、`tech-debt`、`scope-check`）
2. 抄"5. 移植建议 → 可直接移植"列出的 R 条目
3. 粘进你的 AGENTS.md，按需改名（"故事卡"→"工单"，"GDD"→"需求文档"）

**策略 B —— 拿一条完整流程线**
1. 选一条链（如"设计→架构→实现"链：design-system → architecture-decision → create-control-manifest → dev-story → story-done）
2. 把每个文档的 R 条目按链的顺序拼进 AGENTS.md，删掉每份的"移植建议"节
3. 用每个文档"需替换概念"表的映射做术语替换（一次性全局替换即可）

**策略 C —— 整套工作流移植（最完整）**
1. 先移植三个横切件：`gate-check`（阶段门禁）、`retrospective`（复盘）、`start`/`help`（导航）
2. 再按你项目的阶段把各技能文档分节挂载
3. 每份文档"2. 数据依赖"表就是你要准备的上游数据清单——先建数据格式，再上规则

**组装时注意三个原则**（来自 CCGS 的设计，比规则本身更重要）：
- **引用而非复制**：规则里所有"读 X 文件"都是数据依赖，没有数据光有规则跑不起来
- **状态即文件**：规则依赖 stage.txt/sprint-status.yaml 这类机器可读状态文件，你的项目也要有对应物
- **人读 MD，机读 YAML**：长文档给人和模型读，状态跟踪必须用结构化格式

## 与总览文档的关系

- 各技能在整个数据链和逻辑链中的位置 → [23-上下文体系与逻辑流程总览](file:///workspace/study-docs/23-上下文体系与逻辑流程总览.md)
- 技能×智能体的映射与"为什么派他" → [技能与智能体映射指南](file:///workspace/study-docs/workflow/技能与智能体映射指南.md)
- 技能运行时读到的配置键（modes.rigor/docs.density 等）→ [配置体系与rigor心智模型](file:///workspace/study-docs/workflow/配置体系与rigor心智模型.md)
