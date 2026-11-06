# 05 Agent：职责、委派与评审

## 1. Agent 是角色化专家

每个 `.claude/agents/*.md` 都由 YAML frontmatter 和角色提示组成。典型字段包括：

```yaml
name: lead-programmer
description: "..."
tools: Read, Glob, Grep, Write, Edit, Bash
model: sonnet
maxTurns: 20
skills: [code-review, architecture-decision, tech-debt]
memory: project
```

正文则规定协作协议、专业方法、职责边界、禁止事项、输出格式、委派关系和 Gate Verdict。

Agent 的质量不只取决于“懂多少”，更取决于“知道自己不能决定什么”。例如 Creative Director 不应写实现代码，QA Tester 的主要输出应是测试与证据而不是功能实现。

## 2. 三层组织

### Tier 1：方向与冲突

- `creative-director`：愿景、支柱、跨创意部门冲突；
- `technical-director`：架构、技术风险、性能和工程方向；
- `producer`：范围、进度、依赖和生产风险。

三者使用 Opus。Art Director 在 Gate 系统中也属于四方阶段评审成员，但当前模型配置为 Sonnet。

### Tier 2：部门所有权

例如 `game-designer`、`lead-programmer`、`art-director`、`audio-director`、`narrative-director`、`qa-lead`、`release-manager`、`localization-lead`。

他们把方向翻译成某个领域可执行的规范，并负责把任务分给专家。

### Tier 3：专业执行

程序、AI、网络、UI、工具、技术美术、音频、写作、世界构建、性能、安全、可访问性、数据分析等角色，以及 Godot/Unity/Unreal 的引擎专家和子专家。

当前模型分布为：3 Opus、44 Sonnet、2 Haiku。模型层级体现任务复杂度，不代表组织权力完全相同。

## 3. 四条协调规则

1. 垂直委派：复杂决策不应跳过层级。
2. 横向咨询：同级可以交换意见，但不能替别的领域做绑定决定。
3. 冲突升级：设计冲突到 Creative Director，技术冲突到 Technical Director。
4. 跨部门变更：由 Producer 协调传播，Agent 不可擅自修改别的领域文件。

例如“战斗需要复杂粒子效果，但移动端性能不够”同时涉及游戏设计、技术美术和性能。正确做法不是任一专家单独拍板，而是并列提供证据，由负责人在愿景、性能与范围之间做决策。

## 4. Skill 与 Agent 如何配合

以 `/team-combat` 为例：

```text
game-designer（设计）
      │
      ▼
lead-programmer / 技术决策
      │
      ├── gameplay-programmer ─┐
      ├── ai-programmer        ├─ 可独立部分并行
      ├── technical-artist     │
      └── sound-designer      ─┘
                    │
                    ▼
              qa-tester → sign-off
```

Skill 负责定义依赖关系和阶段；Agent 负责在自己的领域内产出判断或工件。

## 5. 并行不是“全部一起跑”

项目的并行协议要求：

- 输入互不依赖的 Agent 应同时启动；
- 收齐并行结果后再进入依赖阶段；
- 任一 Agent 返回 BLOCKED 时立即呈现；
- 即使部分失败也要保留已完成结果，形成 partial report。

设计先于实现，因此 Designer 与 Programmer 通常不能从零同时开始；但同一份已批准设计下，音频清单和视觉特效方案可能并行。

## 6. Director Gates

`.claude/docs/director-gates.md` 维护 Gate ID、触发条件、传入上下文、标准提示和 Verdict 词汇。Skill 应只引用 Gate ID，不要复制一份提示词，以免两处漂移。

`/gate-check` 在 full 和 lean 模式下并行调用：

- `CD-PHASE-GATE`
- `TD-PHASE-GATE`
- `PR-PHASE-GATE`
- `AD-PHASE-GATE`

综合规则通常是：任何 NOT READY/REJECT 使总体至少为 FAIL；任何 CONCERNS 使总体至少为 CONCERNS；全部 READY/APPROVE 才可能 PASS。即便 PASS，阶段推进仍由用户确认。

## 7. 选择 Agent 的简易方法

问自己三个问题：

1. 这是方向决策、领域方案，还是具体执行？
2. 在真实工作室里哪个部门拥有它？
3. 是否跨两个以上部门并需要统一排期？

例子：

- “伤害公式是否符合玩家体验” → game-designer / systems-designer；
- “伤害系统 API 如何隔离” → lead-programmer / technical-director；
- “实现 Godot 伤害组件” → gameplay-programmer + godot-gdscript-specialist；
- “战斗、特效、音效一起交付” → `/team-combat`，而不是手动连续呼叫六个 Agent。

## 本课检查

1. 为什么 Agent 边界和知识同样重要？
2. Producer 在设计与技术冲突中扮演什么角色？
3. 哪些任务能并行，判断依据是什么？
4. Gate 的 Verdict 是否能自动替用户推进阶段？答案是否定的。

