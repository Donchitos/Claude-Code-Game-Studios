# 17 · CCGS Skill Testing Framework 目录指南

## 这篇文档解决什么问题

前几篇讲的都是"工作室怎么运作"——agents 当员工、skills 当命令、hooks 当守卫、rules 当规矩。这篇讲一个**特殊的东西**：[CCGS Skill Testing Framework/](file:///workspace/CCGS%20Skill%20Testing%20Framework/) 目录。

它特殊在哪？**它不参与做游戏，它专门"测试那些做游戏的技能和智能体本身"**。这是"元测试"——测试测试工具的工具。

读完这篇你会明白：

- 这个目录里每个文件是干什么的（作用）
- 怎么用它（如何使用）
- 为什么需要它（为什么要用）
- 在开发流程的什么时候会用到它（开发流程中何时被使用）
- 里面的术语从字面到内涵是什么意思

> ⚠️ **重要前提**：这个目录是**可选的、自包含的**。游戏开发者用它做游戏时**不需要**这个目录。删掉它（`rm -rf "CCGS Skill Testing Framework"`）对 `.claude/` 下的技能毫无影响。它是给"维护这套工作室框架本身的人"用的——比如你想改某个技能、或者升级框架时验证没改坏。

---

## 一句话定位

> **CCGS Skill Testing Framework = 给"工作室框架本身"做的质量保证层。它测试 73 个技能和 49 个智能体"行为对不对"，而不是测试用它们做的游戏"好不好"。**

---

## 核心概念：这是"元测试"

先理解一个关键区分，否则后面全看不懂。

| | 普通测试（游戏开发里的） | 这个框架做的"元测试" |
|---|---|---|
| **测什么** | 游戏代码 / 游戏设计 | 工作室框架的**技能和智能体** |
| **举例** | "玩家跳跃高度对不对"、"战斗伤害算对没" | "`/gate-check` 这个命令行为对不对"、"`creative-director` 这个智能体有没有越权" |
| **谁来做** | 游戏开发者（用框架做游戏的人） | 框架维护者（改框架本身的人） |
| **在哪** | 项目的 `tests/` 目录 | 这个 `CCGS Skill Testing Framework/` 目录 |
| **类比** | 验收一栋盖好的房子 | 验收"盖房子的施工队"够不够专业 |

**记住**：你用这套工作室做游戏时，基本不会碰这个目录。但如果你**想改某个技能**（比如调整 `/gate-check` 的行为）、或**升级框架后验证没改坏**，就会用到它。

---

## 类比：把这套框架想象成"一支施工队"

- **技能和智能体** = 施工队的"员工"和"操作规程"
- **用框架做游戏** = 施工队去盖一栋房子
- **CCGS Skill Testing Framework** = 给施工队做的"上岗考核 + 操作规程审查"

施工队盖房子时不需要自己考自己。但如果施工队要招新员工、改操作规程、或者被甲方质疑"你们靠不靠谱"，就得拿出考核体系证明自己。这个目录就是那个考核体系。

---

## 类比：把 `CCGS Skill Testing Framework/` 想象成"考试中心"

想象一个考试中心，里面有：

| 考试中心分区 | 对应目录里的文件 | 干什么 |
|-------------|-----------------|--------|
| 门口的"考试说明" | [README.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/README.md) | 告诉你怎么用这套考试系统 |
| 给监考老师的"操作手册" | [CLAUDE.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/CLAUDE.md) | 告诉 Claude（当监考老师时）怎么组织考试 |
| "考生花名册" | [catalog.yaml](file:///workspace/CCGS%20Skill%20Testing%20Framework/catalog.yaml) | 73 个技能 + 49 个智能体的名单，记录谁考过、考得怎样 |
| "评分标准册" | [quality-rubric.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/quality-rubric.md) | 按工种分类的及格/不及格标准 |
| "技能考卷"（73 份） | [skills/](file:///workspace/CCGS%20Skill%20Testing%20Framework/skills/) | 每个技能一份行为规范考卷 |
| "智能体考卷"（49 份） | [agents/](file:///workspace/CCGS%20Skill%20Testing%20Framework/agents/) | 每个智能体一份行为规范考卷 |
| "出卷模板" | [templates/](file:///workspace/CCGS%20Skill%20Testing%20Framework/templates/) | 出新考卷时用的空白模板 |
| "成绩单存放处" | `results/`（gitignored，目前不存在） | 考试成绩自动存这里，不进版本库 |

---

## 全景地图

```
CCGS Skill Testing Framework/
├── README.md              # 框架总说明（怎么用这套测试系统）
├── CLAUDE.md              # 给 Claude 的使用说明（当监考老师时怎么干）
├── catalog.yaml           # 主注册表：73 技能 + 49 智能体的名单 + 测试记录
├── quality-rubric.md      # 分类别评分标准（9 类技能 + 6 类智能体）
│
├── skills/                # 技能行为规范（73 份，按 9 类分目录）
│   ├── gate/              # 门禁类（gate-check）
│   ├── review/            # 评审类（design-review 等 3 个）
│   ├── authoring/         # 创作类（design-system 等 7 个）
│   ├── readiness/         # 就绪类（story-readiness, story-done）
│   ├── pipeline/          # 管线类（create-epics 等 6 个）
│   ├── analysis/          # 分析类（code-review 等 12 个）
│   ├── team/              # 团队类（team-combat 等 9 个）
│   ├── sprint/            # 冲刺类（sprint-plan 等 6 个）
│   └── utility/           # 工具类（start, help 等 26 个）
│
├── agents/                # 智能体行为规范（49 份，按层级分目录）
│   ├── directors/         # 总监层（4 个：CD, TD, PR, AD）
│   ├── leads/             # 主管层（7 个：lead-programmer 等）
│   ├── specialists/       # 专家层（13 个：gameplay-programmer 等）
│   ├── engine/godot/      # Godot 引擎专家（5 个）
│   ├── engine/unity/      # Unity 引擎专家（5 个）
│   ├── engine/unreal/     # Unreal 引擎专家（5 个）
│   ├── operations/        # 运营层（7 个：devops 等）
│   └── qa/                # QA 层（3 个：qa-tester 等）
│
└── templates/             # 出新规范时用的模板
    ├── skill-test-spec.md   # 技能规范模板
    └── agent-test-spec.md   # 智能体规范模板
```

---

## 术语详解（先读这节，后面才看得懂）

这个目录里全是测试和质量保证领域的术语。先把它们从字面到内涵讲清楚。

### 测试类型术语

| 术语 | 字面意思 | 内涵 | 类比 |
|------|---------|------|------|
| **static test（静态测试）** | 不运行的测试 | 只检查技能文件的"结构"对不对——有没有必填字段、有没有足够章节、有没有判决关键词。不实际跑技能。 | 查身份证——看证件齐不齐，不问你会不会干活 |
| **spec test（行为规范测试）** | 对照规范测 | 拿技能的"考卷"（spec 文件）一条条对照，看技能实际行为是否符合规范里写的预期。 | 笔试——照着考卷一题题答 |
| **category test（分类评分测试）** | 按工种评分 | 按 skill 所属类别（门禁类、评审类等）的评分标准，评它达不达标。 | 技能比武——按工种定及格线 |
| **audit（审计）** | 全面审查 | 一次看所有技能和智能体：谁有规范、上次什么时候测的、结果如何。 | 全员点名 + 查考勤记录 |

### 规范文件术语

| 术语 | 字面意思 | 内涵 |
|------|---------|------|
| **spec（规范）** | specification 的缩写 | 一份描述"某个技能/智能体应该怎么表现"的文档。就是"考卷"。 |
| **fixture（夹具）** | 测试夹具 | 测试时假设的"项目状态"——比如"假设 game-concept.md 已存在且内容完整"。让测试可重复。 |
| **assertion（断言）** | 断定 | 一条可判定对错的检查项——比如"技能必须问'可以写吗'才能写文件"。对就 PASS，错就 FAIL。 |
| **case（测试用例）** | 一个测试场景 | 一个具体场景下的完整测试——含 fixture（前提）+ expected behavior（期望行为）+ assertions（断言）。每个 spec 有 5 个 case。 |

### 判决术语

这套框架里"判决"是核心概念——技能和智能体必须用**规定的关键词**来表达结果，不能自由发挥。

| 判决关键词 | 用在哪 | 含义 |
|-----------|--------|------|
| **PASS / CONCERNS / FAIL** | 门禁类、架构评审 | 通过 / 有顾虑但可过 / 不通过 |
| **APPROVED / NEEDS REVISION / MAJOR REVISION** | 设计评审 | 批准 / 需小改 / 需大改 |
| **READY / NEEDS WORK / BLOCKED** | 故事就绪检查 | 可开工 / 需补料 / 被卡住 |
| **COMPLETE / COMPLETE WITH NOTES / BLOCKED** | 故事完成检查 | 完成 / 完成但有备注 / 被卡住 |
| **PASS / FAIL / PARTIAL** | 测试用例自身 | 测试通过 / 失败 / 部分通过 |

**为什么要统一关键词**？因为后续技能要"读"这些判决来决定下一步。比如 `/gate-check` 看到 `/design-review` 返回 `NEEDS REVISION`，就不会让项目进入下一阶段。如果评审技能自由发挥写成"还行，改改就行"，机器读不懂就卡住了。

### 协作与门禁术语

| 术语 | 内涵 |
|------|------|
| **director gate（总监门禁）** | 关键决策点由"总监"级智能体把关。比如过阶段门禁时，creative-director 要审"符不符合游戏愿景"。 |
| **review mode（评审模式）** | 三档：`full`（所有总监都审）、`lean`（只在阶段过渡时审）、`solo`（不审，求快）。在 `/start` 时设定，存 `production/session-state/review-mode.txt`。 |
| **"May I write"协议** | 写文件前必须问"可以写到这个路径吗？"，用户说"可以"才能写。是协作宪法的核心。 |
| **protocol compliance（协议合规）** | 检查技能/智能体有没有遵守协作协议——问不问、给不给选项、求不求批准。 |

### 分类术语

| 术语 | 内涵 |
|------|------|
| **category（技能分类）** | 73 个技能按职责分 9 类：gate / review / authoring / readiness / pipeline / analysis / team / sprint / utility。每类有专属评分标准。 |
| **tier（智能体层级）** | 49 个智能体按职级分层：directors（总监）/ leads（主管）/ specialists（专家）/ engine（引擎专家）/ operations（运营）/ qa（质量保证）。 |
| **priority（优先级）** | 技能的重要程度：critical（关键，如 gate-check）/ high（高，如 create-stories）/ medium（中，如 team-combat）/ low（低，如 help）。决定测试顺序。 |

理解了这些术语，下面逐个讲文件就顺了。

---

## 逐个讲解

### 1. `README.md` —— 框架总说明

**作用**：这个目录的"门口说明牌"。告诉你这个框架是干什么的、里面有什么、怎么用、怎么删。

**关键内容**（来自 [README.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/README.md)）：

- 明确声明：**测的是技能和智能体本身，不是用它们做的游戏**
- 自包含且可选：删掉不影响 `.claude/`
- 列出 5 种测试命令的用法（static / spec / category / audit / improve）
- 9 个技能分类的速查表
- 8 个智能体层级的速查表
- 怎么写新规范、怎么更新 catalog

**如何使用**：第一次接触这个目录时先通读一遍。它是"导览图"。

**为什么要用**：没有它，进到这个目录会一脸懵——这么多文件是干嘛的？README 一句话定调："这是给框架本身做 QA 的，游戏开发者不需要"。

**开发流程中何时被使用**：**不在游戏开发流程内**。它是框架维护流程的入口——当你想改某个技能、或验证框架升级时才读它。

---

### 2. `CLAUDE.md` —— 给 Claude 的使用说明

**作用**：告诉 Claude（当它在这个目录工作、扮演"测试员"角色时）怎么组织测试。和项目根的 CLAUDE.md 机制一样，是"目录级配置"。

**关键内容**（来自 [CLAUDE.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/CLAUDE.md)）：

- 列出每个文件的作用（catalog、rubric、specs、templates、results）
- 路径约定（技能规范在哪、智能体规范在哪）
- 9 类技能和 8 层智能体的完整清单
- 测试一个技能的 5 步工作流
- 改进一个技能用 `/skill-improve`（自动 test→诊断→改→重测）
- **重要提醒**：规范描述的是"当前行为"，不是"理想行为"——规范本身可能有 bug，技能实战出错时先改技能再同步规范
- 重申这个目录可删

**如何使用**：你不用主动"运行"它。Claude 进入这个目录做测试工作时自动读到它。你只要知道：**当 AI 帮你跑 `/skill-test` 时，它按这里的流程来**。

**为什么要用**：让测试过程标准化——每次测试都按同样的 5 步走（读 catalog → 读技能 → 读规范 → 评断言 → 写结果），不会漏步骤。

**开发流程中何时被使用**：跑 `/skill-test` 或 `/skill-improve` 时由 Claude 自动读取。

---

### 3. `catalog.yaml` —— 主注册表

**作用**：这是整个框架的"花名册 + 成绩单"。记录全部 73 个技能和 49 个智能体，每个都跟踪：它的规范文件在哪、属于哪个分类、优先级多高、上次什么时候测的、测的结果如何。

**每个技能记录的字段**（来自 [catalog.yaml](file:///workspace/CCGS%20Skill%20Testing%20Framework/catalog.yaml)）：

```yaml
- name: gate-check                    # 技能名
  spec: CCGS Skill Testing Framework/skills/gate/gate-check.md  # 规范文件路径
  last_static: ""                     # 上次静态测试时间
  last_static_result: ""              # 上次静态测试结果
  last_spec: ""                       # 上次行为测试时间
  last_spec_result: ""                # 上次行为测试结果
  last_category: ""                   # 上次分类测试时间
  last_category_result: ""            # 上次分类测试结果
  priority: critical                  # 优先级（critical/high/medium/low）
  category: gate                      # 分类（9 类之一）
```

智能体记录类似，但更简单（只有 `last_spec` 和 `last_spec_result`，因为智能体不做 static 和 category 测试）。

**优先级分布**（从 catalog 可看出）：

| 优先级 | 数量 | 代表技能 | 含义 |
|--------|------|---------|------|
| critical | 6 | gate-check, design-review, story-readiness, story-done, review-all-gdds, architecture-review | 控制阶段过渡和故事流转的"命门"，坏了全流程瘫痪 |
| high | 9 | create-epics, create-stories, dev-story, design-system, consistency-check 等 | 管线关键技能，坏了下游全断 |
| medium | 11 | team-* 系列、sprint-plan、sprint-status | 团队和冲刺管理，坏了影响协作 |
| low | 47 | help, brainstorm, code-review, balance-check 等 | 工具和分析类，坏了能绕过 |

**如何使用**：你**不手动编辑**。它由 `/skill-test` 在每次测试后自动更新（会询问你是否更新 `last_*` 字段）。`/skill-test audit` 会读它生成全员覆盖率报告。

**为什么要用**：

1. **可追溯**——随时能查"gate-check 上次什么时候测的、过了没"
2. **防漏测**——audit 一跑就知道哪些技能从没测过
3. **定优先级**——critical 的技能坏了最致命，要优先测、优先修

**开发流程中何时被使用**：跑任何 `/skill-test` 命令前都会先读它（找规范路径），跑完后更新它（记成绩）。

---

### 4. `quality-rubric.md` —— 分类别评分标准

**作用**：这是"评分标准册"。9 类技能各有 4-5 条 PASS/FAIL 标准，6 类智能体也各有标准。`/skill-test category` 按这个评。

**9 类技能的评分标准**（来自 [quality-rubric.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/quality-rubric.md)）：

| 类别 | 代表技能 | 核心评分点（举例） |
|------|---------|-------------------|
| **gate**（门禁） | gate-check | G1 读 review-mode / G2 full 模式唤 4 总监 / G5 不自动推进阶段 |
| **review**（评审） | design-review | R1 只读不改 / R2 查 8 章节 / R3 用对判决关键词 |
| **authoring**（创作） | design-system | A1 分节写 / A2 每节问"可以写吗" / A3 改造模式 / A5 先建骨架 |
| **readiness**（就绪） | story-readiness | RD1 查≥3 维度 / RD2 三级判决 / RD3 BLOCKED 要外部动作 |
| **pipeline**（管线） | create-stories | P1 输出格式对 / P2 按层序 / P3 每个产物问"可以写吗" |
| **analysis**（分析） | code-review | AN1 只读扫描 / AN2 结构化发现表 / AN3 不自动写 |
| **team**（团队） | team-combat | T1 列出唤哪些智能体 / T2 并行独立任务 / T3 立即上报 BLOCKED |
| **sprint**（冲刺） | sprint-plan | SP1 读冲刺状态 / SP2 正确门禁 / SP3 结构化输出 |
| **utility**（工具） | start, help | U1 过 7 项静态检查 / U2 门禁模式对（如适用） |

**6 类智能体的评分标准**：

| 类别 | 代表 | 核心评分点 |
|------|------|-----------|
| **director**（总监） | creative-director | D1 用对判决词 / D2 不越界 / D3 冲突升级 / D4 用 Opus 模型 |
| **lead**（主管） | lead-programmer | L1 领域判决 / L2 升级到共享上级 / L3 用 Sonnet 模型 |
| **specialist**（专家） | gameplay-programmer | S1 守领域 / S2 不越权 / S3 正确转交 |
| **engine**（引擎专家） | godot-specialist | E1 查引擎版本 / E2 文件路由对 / E3 引擎惯用法 |
| **qa**（质量保证） | qa-tester | Q1 产测试不产代码 / Q2 证据格式对 / Q3 不扩范围 |
| **operations**（运营） | devops-engineer | O1 领域清晰 / O2 不写游戏代码 / O3 工具集匹配 |

**每条标准的三档**：

- **PASS**：技能的书面指令明确满足该标准
- **FAIL**：指令缺失、含糊或自相矛盾
- **WARN**：指令部分满足

**如何使用**：跑 `/skill-test category [技能名]` 时，Claude 读这个文件对应分类的章节，逐条评。

**为什么要用**：光看规范文件不够——规范可能写得很全但技能实际没做到。rubric 是"客观标尺"，让评分可重复、可比较。比如"design-system 必须分节写"是 A1 标准，没分节就 FAIL，没得辩。

**开发流程中何时被使用**：跑 `/skill-test category` 时读。不在游戏开发流程内。

---

### 5. `templates/skill-test-spec.md` —— 技能规范模板

**作用**：写新技能规范时用的空白模板。定义了每份技能规范该有的结构。

**模板结构**（来自 [skill-test-spec.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/templates/skill-test-spec.md)）：

1. **Skill Summary**：一段话描述技能干什么
2. **Static Assertions**：5 条静态检查项（frontmatter 字段、章节、判决词、"可以写吗"语言、下一步交接）
3. **Director Gate Checks**：这个技能触发哪些总监门禁、在什么模式下
4. **Test Cases**：**5 个测试用例**，每个含 Fixture（前提）+ Expected behavior（期望）+ Assertions（断言）：
   - Case 1：Happy Path（正常路径——一切顺利时）
   - Case 2：Failure / Blocked（失败路径——出错时）
   - Case 3：Mode Variant（模式变体——不同 review 模式下）
   - Case 4：Edge Case（边界情况——罕见输入）
   - Case 5：Director Gate（总监门禁——门禁怎么触发）
5. **Protocol Compliance**：4 条协议合规检查（问不问、给不给选项、求不求批准、不自动建文件）
6. **Coverage Notes**：覆盖盲区说明

**如何使用**：要给新技能写规范时，复制这个模板到 `skills/[分类]/[技能名].md`，填内容，然后在 catalog.yaml 里把 `spec:` 字段指向新文件。

**为什么要用**：统一规范结构 = 测试能自动化。如果每份规范结构不一样，`/skill-test spec` 没法批量评。模板保证了"5 个 case + 协议合规"这个最低覆盖。

**开发流程中何时被使用**：给框架新增技能时用。不在游戏开发流程内。

---

### 6. `templates/agent-test-spec.md` —— 智能体规范模板

**作用**：写新智能体规范时用的空白模板。和技能模板类似，但 case 设计围绕"智能体的领域边界"。

**模板结构**（来自 [agent-test-spec.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/templates/agent-test-spec.md)）：

1. **Agent Summary**：领域、决策权、委派关系
2. **Static Assertions**：5 条（文件存在、frontmatter、领域清晰、升级路径、不越界）
3. **Test Cases**（5 个）：
   - Case 1：In-Domain Request（领域内请求——正常处理）
   - Case 2：Out-of-Domain Redirect（领域外请求——正确转交）
   - Case 3：Gate Verdict（门禁判决——审文件给判决）
   - Case 4：Conflict Escalation（冲突升级——不独断，上报）
   - Case 5：Context Pass-Through（上下文传递——用父级给的上下文不重问）
4. **Protocol Compliance**：5 条（守领域、升级冲突、"可以写吗"、先展示后批准、不跳层）

**和技能模板的关键区别**：

| | 技能模板 | 智能体模板 |
|---|---|---|
| 测什么 | 命令的执行流程 | 智能体的领域边界 |
| Case 1 | Happy Path（正常流程） | In-Domain（领域内） |
| Case 2 | Failure（失败处理） | Out-of-Domain（领域外转交） |
| Case 3 | Mode Variant（模式变体） | Gate Verdict（门禁判决） |
| Case 4 | Edge Case（边界情况） | Conflict Escalation（冲突升级） |
| Case 5 | Director Gate（门禁触发） | Context Pass-Through（上下文传递） |

**如何使用**：给框架新增智能体时，复制模板到 `agents/[层级]/[名].md`，填内容，在 catalog.yaml 注册。

**为什么要用**：智能体最常犯的错是"越界"——gameplay-programmer 去做设计决策、qa-tester 去写实现代码。模板的 Case 2 和 Case 4 专门测这个。

**开发流程中何时被使用**：给框架新增智能体时用。不在游戏开发流程内。

---

### 7. `skills/[category]/[name].md` —— 技能行为规范（73 份）

**作用**：每个技能一份"考卷"，描述它**应该**怎么表现。是 `/skill-test spec` 的评判依据。

**举例**：[skills/gate/gate-check.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/skills/gate/gate-check.md) 是 `/gate-check` 技能的考卷，含 5 个 case：

- Case 1：Happy Path——所有概念阶段产物齐全，要推进到系统设计
- Case 2：Failure——game-concept.md 不存在，该判 FAIL
- Case 3：No Argument——不带参数时自动检测当前阶段
- Case 4：Edge Case——无法自动验证的质量项要标"人工检查"
- Case 5：Director Gate——full/lean/solo 三种模式下总监门禁怎么触发

**如何使用**：跑 `/skill-test spec gate-check` 时，Claude 读这份考卷，逐 case 评 `gate-check` 技能的实际行为符不符合。

**为什么要用**：

1. **可重复**——每次测都按同样的 case，结果可对比
2. **可追溯**——规范文件进版本库，改了技能就能查"对应的规范改了没"
3. **防回归**——技能改完跑一遍 spec，确认没改坏原有行为

**重要提醒**（来自 [CLAUDE.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/CLAUDE.md)）：规范描述的是"当前行为"不是"理想行为"。规范是照着技能写的，可能把技能的 bug 也记进去了。实战发现技能出错时，**先改技能，再同步规范**——别拿有 bug 的规范当圣旨。

**开发流程中何时被使用**：跑 `/skill-test spec [技能名]` 时读。不在游戏开发流程内。

---

### 8. `agents/[tier]/[name].md` —— 智能体行为规范（49 份）

**作用**：每个智能体一份"考卷"，描述它的**领域边界、决策权、升级路径**该是什么样。

**举例**：[agents/directors/creative-director.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/agents/directors/creative-director.md) 描述创意总监——它该用 APPROVE/CONCERNS/REJECT 判决、不越技术界的权、冲突升级到它这里。

**如何使用**：跑 `/skill-test spec` 测智能体时（虽然命令叫 skill-test，但也能测 agent），Claude 读对应考卷评。

**为什么要用**：智能体的核心风险是"越界"和"该升级不升级"。49 个智能体各司其职的前提是边界清晰。规范把这些边界写成可测的断言。

**开发流程中何时被使用**：测智能体时读。不在游戏开发流程内。

---

## 怎么用这套框架（5 种测试命令）

读完上面，这套框架的用法就清楚了。来自 [README.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/README.md)：

| 命令 | 干什么 | 何时用 |
|------|--------|--------|
| `/skill-test static [技能名]` | 查技能文件结构（7 项检查：frontmatter、章节、判决词等） | 快速排查"技能文件本身写对没" |
| `/skill-test static all` | 查全部 73 个技能的结构 | 框架升级后批量体检 |
| `/skill-test spec [技能名]` | 拿考卷逐 case 评技能实际行为 | 改了技能后验证没改坏 |
| `/skill-test category [技能名]` | 按分类评分标准评 | 评估技能达不达该类的标 |
| `/skill-test category all` | 全部分类技能都评 | 全员质量摸底 |
| `/skill-test audit` | 看全员覆盖率：谁有规范、上次测没测、结果如何 | 决定接下来测谁 |
| `/skill-improve [技能名]` | 测→诊断→提议改法→改→重测 的闭环 | 技能测挂了用它修 |

**典型工作流**（改一个技能时）：

```
1. /skill-test spec [技能名]      # 先测，看挂没挂
2. 如果挂了 → /skill-improve [技能名]  # 进入修复闭环
3. /skill-improve 会：测 → 诊断原因 → 提议改法 → 改技能 → 重测 → 保留或回退
4. /skill-test category [技能名]  # 确认分类评分也过
5. /skill-test audit               # 看整体覆盖率有没有提升
```

---

## 在开发流程中何时碰到这个目录

**答案：游戏开发流程中基本不会碰到。**

这是这套框架最特别的地方。再看一遍对比：

| 流程 | 会碰到这个目录吗 | 何时碰 |
|------|-----------------|--------|
| 用框架做游戏（Phase 1-7） | ❌ 不会 | — |
| 改框架本身的技能或智能体 | ✅ 会 | 改之前测一遍、改之后测一遍 |
| 升级框架版本 | ✅ 会 | 升级后跑 `/skill-test static all` 体检 |
| 给框架加新技能/智能体 | ✅ 会 | 用模板写规范、注册到 catalog |
| 怀疑某个技能行为不对 | ✅ 会 | 跑 `/skill-test spec` 验证 |

**所以这个目录的"开发流程"是框架维护流程，不是游戏开发流程**：

```
框架维护流程：
  怀疑技能有问题 → /skill-test spec 验证 → 挂了？
    ├─ 挂了 → /skill-improve 修复闭环 → 重测 → 通过 → 同步规范
    └─ 没挂 → 可能是规范过时 → 更新规范匹配实际行为
  
  加新技能 → 用 templates/ 写规范 → 注册到 catalog.yaml → /skill-test spec 验证
  
  框架升级 → /skill-test static all 体检 → /skill-test audit 看覆盖率 → 补测漏的
```

---

## 常见误区

**误区 1："做游戏时我得跑这些测试。"**
❌ 错。这个目录是给框架维护者的，游戏开发者不需要。README 第一段就明说："Game developers using CCGS don't need it."

**误区 2："规范描述的是技能应该的理想行为。"**
❌ 错。[CLAUDE.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/CLAUDE.md) 明确：规范描述的是"当前行为"，可能把技能的 bug 也记进去了。实战出错时先改技能再同步规范。

**误区 3："我得手动维护 catalog.yaml。"**
❌ 不用。`/skill-test` 每次测完会问你要不要更新 `last_*` 字段。手动改容易漏。

**误区 4："static 测试过了就说明技能没问题。"**
❌ 不够。static 只查文件结构（frontmatter、章节、判决词），不查实际行为。要查行为得跑 `/skill-test spec`，查分类达标得跑 `/skill-test category`。三层都要过。

**误区 5："删掉这个目录框架就不能用了。"**
❌ 错。README 和 CLAUDE.md 都强调：这个目录自包含、无 hook 进 `.claude/`。删掉后 `/skill-test` 和 `/skill-improve` 还能跑，只是会提示 catalog 找不到、建议跑 audit 初始化。

**误区 6："测试用例的 5 个 case 是随便写的。"**
❌ 错。5 个 case 是精心设计的覆盖：Happy Path（正常）+ Failure（失败）+ Mode Variant（模式变体）+ Edge Case（边界）+ Director Gate（门禁）。覆盖了"顺利、出错、模式差异、罕见情况、门禁触发"五大场景。

---

## 小测验

**Q1**：你用这套框架做游戏，跑到一半怀疑 `/gate-check` 行为不对。你该用哪个命令验证？需要碰这个目录吗？

<details>
<summary>答案</summary>

用 `/skill-test spec gate-check` 验证。**需要碰这个目录**——它会读 [skills/gate/gate-check.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/skills/gate/gate-check.md) 这份考卷来评。但注意：如果只是用框架做游戏（不改框架），通常不需要主动测；测技能是框架维护者的事。

</details>

**Q2**：`/skill-test static`、`/skill-test spec`、`/skill-test category` 三个有什么区别？

<details>
<summary>答案</summary>

- **static**：查文件**结构**——frontmatter 字段齐不齐、有没有判决词、"可以写吗"语言在不在。不实际跑技能。最快。
- **spec**：查**实际行为**——拿考卷（spec 文件）逐 case 评技能跑起来对不对。最细。
- **category**：查**分类达标**——按该技能所属分类的评分标准（rubric）评它达不达标。横向可比。

三层从粗到细，都要过才算全面。

</details>

**Q3**：你改了 `/design-system` 技能，怎么确认没改坏？

<details>
<summary>答案</summary>

1. `/skill-test static design-system`——先查结构没坏
2. `/skill-test spec design-system`——再查 5 个 case 行为没变
3. `/skill-test category design-system`——确认分类评分仍达标
4. 如果挂了，跑 `/skill-improve design-system` 进入修复闭环

如果改的是"修 bug"，改完还要同步更新对应的 spec 文件（因为规范描述当前行为，bug 修了规范也要更新）。

</details>

**Q4**：catalog.yaml 里 gate-check 标 `priority: critical`，help 标 `priority: low`。这个优先级影响什么？

<details>
<summary>答案</summary>

影响**测试顺序和修复优先级**。critical 的技能（gate-check、design-review 等 6 个）控制阶段过渡和故事流转，坏了全流程瘫痪，要优先测、优先修。low 的技能（help、brainstorm 等 47 个）是工具类，坏了能绕过，可以后测。

但注意：优先级不等于"可以不测"——audit 会暴露所有没测过的，包括 low 的。

</details>

**Q5**：技能规范文件里的 "Case 2: Failure / Blocked" 测的是什么？为什么重要？

<details>
<summary>答案</summary>

测技能**出错时的行为**——比如 `/gate-check` 发现 game-concept.md 不存在时，该判 FAIL、列出阻塞项、建议跑 `/brainstorm`，而不是假装通过或崩溃。

重要因为：技能最常在"出错路径"上出问题。Happy Path 大家都会写，但"文件缺失时怎么办、参数错时怎么办"最容易漏。Case 2 专测这个，防止技能在异常时静默失败或误判通过。

</details>

---

## 动手

1. 打开 [catalog.yaml](file:///workspace/CCGS%20Skill%20Testing%20Framework/catalog.yaml)，数一下 `priority: critical` 的技能有几个、分别是哪些（答案是 6 个：gate-check, design-review, story-readiness, story-done, review-all-gdds, architecture-review）。
2. 打开 [quality-rubric.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/quality-rubric.md)，找 `### gate` 段，看 gate-check 要过哪 5 条标准（G1-G5）。想想每条防的是什么坑（比如 G5"不自动推进阶段"防的是 AI 没问你就改了 stage.txt）。
3. 打开 [skills/gate/gate-check.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/skills/gate/gate-check.md)，读 Case 1（Happy Path）和 Case 2（Failure），对比"一切顺利时"和"文件缺失时"技能该有什么不同表现。
4. 对比 [templates/skill-test-spec.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/templates/skill-test-spec.md) 和 [templates/agent-test-spec.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/templates/agent-test-spec.md) 的 5 个 case——看技能考卷测"流程对不对"，智能体考卷测"边界守没守"。
5. 打开 [CLAUDE.md](file:///workspace/CCGS%20Skill%20Testing%20Framework/CLAUDE.md) 最后的"Spec validity note"，理解为什么"规范描述当前行为而非理想行为"——这决定了发现技能 bug 时该先改谁。

---

## 一句话带走

> **CCGS Skill Testing Framework = 给"工作室框架本身"做的质量保证层。它用 catalog.yaml 当花名册、quality-rubric.md 当评分标准、skills/ 和 agents/ 当考卷、templates/ 当出卷模板，通过 `/skill-test`（static/spec/category/audit）和 `/skill-improve` 两个技能，让 73 个技能和 49 个智能体的行为可测、可追溯、可修复。游戏开发者不需要它，框架维护者靠它防止改坏东西。**
