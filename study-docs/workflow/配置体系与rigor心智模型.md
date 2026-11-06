# 配置体系与 modes.rigor 心智模型 —— 初学者看懂新版本配置

> **一句话总览**：新版本把"这个项目要多正式"浓缩成一个开关 **`modes.rigor`**，它同时控制 6 个子旋钮（流程完整度、文档深度、QA 级别、故事粒度、审查模式、团队规模）。所有配置存在 `project.yaml`（团队共享）和 `project.local.yaml`（个人偏好），每个 skill 启动时跑一条命令解析出最终值。

依据 [.claude/docs/config-resolution.md](file:///workspace/.claude/docs/config-resolution.md)、[automation-modes.md](file:///workspace/.claude/docs/automation-modes.md)、[workflow-modes.md](file:///workspace/.claude/docs/workflow-modes.md)、[settings-guidance.md](file:///workspace/.claude/docs/settings-guidance.md)、[project.yaml](file:///workspace/project.yaml)、[yaml-helper.sh](file:///workspace/.claude/hooks/yaml-helper.sh) 整理。

---

## 0. 为什么要有这套配置？

老版本每个 skill 自己用散文描述"读这个文件，没有就用那个默认值"。问题：
- 大模型每次重新解读，行为不稳定
- 73 个 skill 写 73 份 fallback 逻辑，互相不一致
- 改一个默认值要改 73 个文件

新版本的解法：**所有配置集中到 `project.yaml`，一个脚本解析出最终值，技能直接用**。

---

## 1. 心智模型：一个主开关 + 6 个子旋钮 + 5 个独立配置

```
┌──────────────────────────────────────────────────────┐
│              modes.rigor（主开关）                    │
│   minimal ──→ standard ──→ full                     │
│                                                       │
│   它同时展开成 6 个子旋钮：                           │
│                                                       │
│   modes.workflow     流程要多完整（哪些文档必须有）   │
│   docs.density       文档每节写多深                   │
│   qa.level           QA 要多严格                      │
│   modes.story_granularity  故事拆多细                 │
│   modes.review_mode  总监门禁跑不跑                   │
│   team.size          默认启用多少智能体               │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│   5 个独立配置（不归 rigor 管）：                     │
│                                                       │
│   modes.automation          AI 要不要问我            │
│   modes.automation_always_ask  哪些决定必须问        │
│   testing.strict.*          测试失败要不要阻塞       │
│   performance.enforce       性能超预算要不要拦       │
│   platform / accessibility  目标平台/无障碍档位      │
└──────────────────────────────────────────────────────┘
```

**核心思想**：你只需要决定一件事——"这个项目有多正式"（rigor）。其余 6 个细节自动跟着走。想微调某一个？单独改它就行，不影响其他 5 个。

---

## 2. 三档 rigor 展开表（必须记住）

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---------------|------------------|----------------|------------|---------------------------|---------------------|-------------|
| **minimal**（默认） | minimal | terse | minimal | coarse | solo | individual |
| **standard** | standard | balanced | standard | balanced | lean | individual |
| **full** | full | thorough | full | fine | full | studio |

**为什么默认是 minimal**：更重的档位花更多 token、写更多文档，但不一定产出更好的结果。新用户一上来就被 full 流程吓退。需要升级时 `/start` 或 `/settings` 改一下即可。

> 注意：`team.size` 在 minimal 和 standard 下都是 `individual`，只有 full 才变成 `studio`（启用全部智能体）。

---

## 3. 每个旋钮是什么意思

### 3.1 `modes.workflow` —— 流程要多完整（哪些文档必须有）

控制"写代码之前必须有哪些设计文档"。**只影响必须的，不影响允许的**——任何 skill 任何时候都能跑。

| 档位 | 写代码前必须有 | 适合 |
|------|----------------|------|
| `full` | 全部 8 节 GDD + 完整架构 + 全部 ADR + 美术圣经 + 每屏 UX 规格 | 团队、商业项目、学完整管线 |
| `standard` | 5 节 GDD（概述/规则/边缘情况/依赖/验收标准）+ 架构文档 + 关键 ADR + 概念书 + 系统索引 | 几个系统交互的项目，别人来实现你的设计 |
| `minimal` | 只要 `design/game-brief.md` 一页 + 引擎选择（它的 build-order 字段就是计划，不需要单独 sprint plan） | **默认**。Game jam、小项目、设计在脑子里 |

**`minimal` 的设计产物是 `design/game-brief.md`，不是 `design/gdd/game-concept.md`**——两个文件是不同档位的概念文档，别搞混。

### 3.2 `docs.density` —— 文档每节写多深

你问的核心概念。`workflow` 决定"哪些节存在"，`density` 决定"每节写多深"。

| 档位 | 每节写什么 |
|------|-----------|
| `terse`（minimal 档默认） | 层图 + 决策要点，无长文散文 |
| `balanced`（standard 档默认） | 图 + 段落解释每层选择的理由 |
| `thorough`（full 档默认） | 完整散文，含理由、取舍、考虑过的替代方案 |

**组合用法**：`rigor: full` + `docs.density: terse` = "全 8 节都写，但每节都紧凑"——"全面但精简"。

### 3.3 `qa.level` —— QA 要多严格

| 档位 | 故事 Done 需要的测试证据 |
|------|--------------------------|
| `minimal` | 最少 |
| `standard` | 标准测试覆盖 |
| `full` | 完整测试套件 |

它和 `testing.strict` 是两个轴：`qa.level` 决定"需不需要证据"，`testing.strict` 决定"测试失败要不要阻塞"。

### 3.4 `modes.story_granularity` —— 故事拆多细

| 档位 | 每个故事多大 |
|------|-------------|
| `coarse` | 粗粒度，每个 epic 故事少 |
| `balanced` | 适中 |
| `fine` | 细粒度，每个 epic 故事多 |

### 3.5 `modes.review_mode` —— 总监门禁跑不跑

| 档位 | 哪些门禁跑 |
|------|-----------|
| `solo` | 不跑总监门禁（只有产物存在性检查） |
| `lean` | 只跑阶段切换的 PHASE-GATE，跳过 skill 内部门禁 |
| `full` | 所有门禁都跑 |

### 3.6 `team.size` —— 默认启用多少智能体

| 档位 | 启用范围 |
|------|----------|
| `individual` | 单人最小集 |
| `small` | 小团队 |
| `studio` | 全 49 智能体 |

---

## 4. 独立配置（不归 rigor 管）

### 4.1 `modes.automation` —— AI 要不要问我

三档工作风格，**和 rigor 正交**（你可以 minimal rigor + autonomous automation，也可以 full rigor + collaborative automation）。

| 档位 | 速度 | 控制 | 行为 |
|------|------|------|------|
| `collaborative`（默认） | 最慢 | 全控 | 每个多选项决定都 AskUserQuestion，每个文件写前都批准 |
| `guided` | 平衡 | 高 | 大决定问，小决定 AI 自己干（声明推荐后继续） |
| `autonomous` | 最快 | 低 | AI 决定+记日志+继续，除了 `automation_always_ask` 类别 |

**4 个技能永远 collaborative**（不管配置）：`hotfix`、`gate-check`、`day-one-patch`、`setup-engine`——它们涉及紧急/不可逆决策。

### 4.2 `modes.automation_always_ask` —— 即使 autonomous 也要问的类别

默认 3 个：`scope_changes`（范围变更）、`file_deletions`（删文件）、`schema_changes`（改模板/配置结构）。

另外 3 个可选：`architecture_decisions`、`version_bumps`、`external_calls`。

**规则**：配置里列出的才会问，没列的不会。比如默认 `architecture_decisions` 不在列表里，autonomous 模式下新建 ADR 就不会问你。

### 4.3 `testing.strict.*` —— 测试失败要不要阻塞

按故事类型分 5 个：`logic`、`integration`、`visual`、`ui`、`config`，每个 `true`（阻塞）或 `false`（仅警告）。

**特殊**：没有统一默认值——`/smoke-check` 把未配置当成阻塞（它是构建健康门），`/story-done` 和 `/dev-story` 按故事类型查 `coding-standards.md` 的表。

### 4.4 `workflow_overrides` —— 加严或单系统例外

```yaml
workflow_overrides:
  edge_cases: false        # 强制要求 Edge Cases 节（minimal 档也生效）
  tuning_knobs: false      # 强制要求 Tuning Knobs 节
  art_bible_strict: false  # 强制美术圣经全 9 节
  system_overrides:        # 每个系统单独指定 workflow 档位（双向，可加可减）
    combat: full
    inventory: minimal
```

**3 个布尔开关只能加严**，不能放宽。`system_overrides` 可以双向——`full` 项目里某个简单系统设成 `minimal` 是合法的。

---

## 5. 配置从哪里来：resolve_config 解析链

每个需要配置的 skill，正文第一行是：

```markdown
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density`
```

这条命令在 skill 加载前跑，输出替换占位符，类似：

```
=== CCGS Resolved Config ===
review_mode: solo (rigor:minimal)
automation: collaborative (default)
workflow: minimal (rigor:minimal)
docs.density: terse (rigor:minimal)
...
=== end CCGS config ===
```

**每行末尾括号里是 provenance（来源）**——这个值是从哪来的。

### 解析优先级链（从高到低）

| 步骤 | 来源 | 适用范围 |
|------|------|----------|
| 1 | `project.local.yaml` | 只有 12 个白名单键（个人偏好类） |
| 2 | `project.yaml` | 所有键 |
| 3 | 旧纯文本镜像 | `review-mode.txt`、`stage.txt`（向后兼容） |
| 4 | `modes.rigor` 展开 | 那 6 个旋钮 |
| 5 | 文档默认值 | `automation` 默认 collaborative、`rigor` 默认 minimal |

**关键设计**：步骤 4（rigor 展开）在步骤 5（默认值）之上、步骤 1-3（显式配置）之下。
- 显式写了 `docs.density: terse` → 直接用，rigor 不覆盖它（步骤 2 先答）
- 没写 `docs.density`，但写了 `rigor: full` → 走步骤 4 得 `thorough`
- 都没写 → 走步骤 5？不，6 个旋钮**没有步骤 5 的硬编码默认**——它们必须靠 rigor 展开。而 rigor 自己默认 minimal，所以最终得到 minimal 那一行。

**为什么 6 个旋钮没有硬编码默认**：如果给它们硬编码默认，步骤 5 会在步骤 4 之前答，rigor 展开就永远不生效了。

### project.yaml vs project.local.yaml

| | `project.yaml` | `project.local.yaml` |
|---|---|---|
| 谁改 | `/settings <key>=<value>` | `/settings --local <key>=<value>` |
| 提交 git | ✅ 团队共享 | ❌ 个人偏好（gitignored） |
| 能改哪些键 | 所有 | 只有 12 个白名单键 |
| 改了影响谁 | 所有人的磁盘产物 | 只影响你自己的体验 |
| 例子 | `modes.rigor`、`engine.name` | `modes.review_mode`、`modes.automation` |

**白名单键**（可 local 改）：`modes.review_mode`、`modes.automation`、`modes.automation_always_ask`、`team.size`、`testing.strict.*`（5个）、`performance.enforce`、`features.session_state`、`features.token_budget_warn_at`、`features.read_guard`、`features.read_guard_kb`、`updates.check`。

**为什么锁定**：`modes.rigor`、`modes.workflow`、`docs.density` 等决定"磁盘上有哪些文件"，如果两个人 local 设不同，checkout 会分叉。所以它们只能写在 `project.yaml`。

### provenance 来源词汇表

| 来源 | 含义 |
|------|------|
| `project.local.yaml` | 你的本地覆盖 |
| `project.yaml` | 项目主配置 |
| `production/review-mode.txt` | 旧的纯文本镜像 |
| `rigor:minimal` / `rigor:standard` / `rigor:full` | 由 rigor 展开得来，未显式设置 |
| `default` | 文档硬编码默认（只有 automation 和 rigor 有） |
| `unset` | 没设，各 skill 自己用默认 |

---

## 6. 配置文件长什么样

当前项目的 `project.yaml`（极简模板，等 `/start` 来填）：

```yaml
schema_version: 1

framework:
  version: 1.2.0
  last_upgraded: 2026-10-19

# 注意：下面 6 个旋钮不要直接写在这里——让 rigor 来展开它们。
# /start 会自动写入 modes.rigor 和 modes.automation。
# 不能写的 6 个：modes.review_mode, modes.workflow, docs.density,
#   qa.level, modes.story_granularity, team.size
# 个人偏好写 project.local.yaml
```

一个配置好的项目可能长这样：

```yaml
schema_version: 1
framework:
  version: 1.2.0

modes:
  rigor: standard          # 主开关
  automation: guided       # 独立轴

engine:
  name: Godot
  version: "4.7"
  language: GDScript

testing:
  strict:
    logic: true
    integration: false

workflow_overrides:
  system_overrides:
    combat: full           # 战斗系统单独用 full 流程
```

---

## 7. 如何改配置

| 操作 | 命令 |
|------|------|
| 改团队共享配置 | `/settings modes.rigor=full` |
| 改个人偏好 | `/settings --local modes.review_mode=solo` |
| 看当前所有值 | `/settings`（无参数） |
| 交互式设置 | `/start`（首次启动会问 rigor 和 automation） |

---

## 8. 初学者最容易混淆的点

### Q1: `modes.rigor` 和 `modes.workflow` 什么关系？
> rigor 是父，workflow 是子。设了 rigor 就别设 workflow（除非你想单独覆盖这一个）。rigor: full 自动让 workflow=full、docs.density=thorough 等 6 个一起变。

### Q2: `modes.rigor` 和 `modes.automation` 什么关系？
> **正交的两个轴**。rigor 管"多正式"，automation 管"AI 多主动问"。可以任意组合：
> - 游戏 jam：minimal + autonomous
> - 商业项目：full + collaborative
> - 小团队：standard + guided

### Q3: `docs.density` 到底控制什么？
> 每节文档的**深度**，不是节的数量。节的数量归 `workflow` 管。比如 standard workflow 要求 5 节 GDD，这 5 节写多深由 density 决定：terse=要点，balanced=段落，thorough=完整散文+取舍。

### Q4: 为什么我设了 `docs.density` 但没生效？
> 看 provenance。如果显示 `docs.density: balanced (rigor:standard)`，说明你**没设成功**（project.yaml 里没这个键），它是从 rigor 推出来的。检查你是不是写到了 project.local.yaml（这个键不在白名单，会被忽略并在 notes 里提示）。

### Q5: minimal 档位还需要写 GDD 吗？
> 不需要完整 GDD。minimal 档只用 `design/game-brief.md`（一页）。但你**可以**自愿写 GDD——workflow 只决定"必须的"，不限制"允许的"。

### Q6: 为什么有些键不能写在 project.local.yaml？
> 因为它们决定磁盘上有哪些文件（比如 workflow 决定 GDD 是否必须存在）。如果 A 同学 local 设 minimal、B 同学设 full，同一个仓库两人看到的"必须文件"不一样，checkout 必分叉。所以这些键锁定在 project.yaml，全员一致。

---

## 9. 一图流总结

```
你只需决定：modes.rigor = ?
  minimal ──── 6 旋钮全部 lean 化（game-brief + terse + solo）
  standard ─── 6 旋钮平衡（5节GDD + balanced + lean）
  full ─────── 6 旋钮全开（8节GDD + thorough + full门禁 + studio团队）

另外 5 个独立配置自己选：
  modes.automation = collaborative | guided | autonomous
  testing.strict.*  = true | false
  workflow_overrides = 加严开关 + 单系统例外
  performance.enforce = warn | block | off
  platform / accessibility = 目标档位

配置存在：
  project.yaml      ← 团队共享，/settings 改
  project.local.yaml ← 个人偏好，/settings --local 改（仅12白名单键）

skill 启动时：
  resolve_config 命令跑一遍 → 输出带 provenance 的最终值 → skill 直接用
```

**一句话**：`rigor` 是"项目多正式"的总闸，6 个子旋钮跟着它走；`automation` 是"AI 多主动"的独立轴；所有值写在两份 YAML 里，每次 skill 启动自动解析并标注来源。

---

## 延伸阅读

- [config-resolution.md](file:///workspace/.claude/docs/config-resolution.md) —— 解析链和失败模式完整说明
- [automation-modes.md](file:///workspace/.claude/docs/automation-modes.md) —— 三档自动化模式的行为规则
- [workflow-modes.md](file:///workspace/.claude/docs/workflow-modes.md) —— workflow 三档的产物要求
- [settings-guidance.md](file:///workspace/.claude/docs/settings-guidance.md) —— 什么项目该选什么 rigor
- [23-上下文体系与逻辑流程总览](file:///workspace/study-docs/23-上下文体系与逻辑流程总览.md) —— 配置如何影响 skill 行为
- [W1-技能与智能体映射指南](file:///workspace/study-docs/workflow/技能与智能体映射指南.md) —— team.size 如何决定启用哪些智能体
