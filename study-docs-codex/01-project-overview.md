# 01 项目全景与架构

## 1. 先理解它是什么

Claude Code Game Studios（下文简称 CCGS）把游戏开发过程建模为一个“虚拟工作室”。用户仍然做最终决定，框架则提供角色分工、标准流程、文档模板、质量门和自动检查。

它不是：

- 一个游戏引擎或游戏代码库；
- 能完全自主制作游戏的流水线；
- 传统意义上由类、函数和数据库组成的应用；
- 仅靠运行单元测试就能证明正确的软件包。

它主要由 Markdown、YAML、JSON 和 Bash 构成。其“程序逻辑”大量写在自然语言指令里，由 Claude Code 解释执行。

## 2. 核心架构

```text
用户意图
   │
   ▼
Skill（流程剧本） ───────► Templates / Registries（产物格式与事实源）
   │
   ├── 调用 Agent（领域专家）
   │      └── 委派、并行、评审、升级冲突
   │
   ├── 读写 design / docs / production / src / tests
   │
   └── 遵守 CLAUDE.md 与路径 Rules
             │
             ▼
        Hooks（事件前后自动检查、记录与恢复）
```

可以把六类组件记成一句话：

> CLAUDE.md 定总规矩，Skill 定步骤，Agent 定角色，Rule 管路径，Hook 管时机，Artifact 留证据。

## 3. 目录职责

| 路径 | 当前内容 | 运行时职责 |
|---|---|---|
| `CLAUDE.md` | 项目总配置入口 | 引用目录结构、技术偏好、协调规则等全局上下文 |
| `.claude/settings.json` | 权限、状态栏、Hook 映射 | 告诉 Claude Code 哪些事件运行哪些脚本 |
| `.claude/agents/` | 49 个 Agent 定义 | 描述角色、模型、工具、边界、输出和升级路径 |
| `.claude/skills/` | 73 个 `SKILL.md` | 定义用户可调用的工作流 |
| `.claude/hooks/` | 12 个 Bash 脚本 | 会话、工具调用、压缩、通知、子 Agent 生命周期自动化 |
| `.claude/rules/` | 11 个路径规则 | 编辑特定目录时自动施加对应标准 |
| `.claude/docs/` | 框架内部参考与模板 | 工作流目录、Agent 花名册、Gate 定义、40 个模板文件 |
| `design/` | 初始注册表和目录说明 | 游戏概念、GDD、UX、叙事、资产规范的目标位置 |
| `docs/` | 工作流指南、架构和引擎资料 | ADR、技术需求注册表、控制清单、版本固定的引擎参考 |
| `src/` | 当前仅占位和局部说明 | 使用模板后放置游戏源码 |
| `production/` | 当前仅会话状态占位 | Sprint、Epic、Story、里程碑、Gate 报告和状态 |
| `CCGS Skill Testing Framework/` | 规格、目录和质量量表 | 测试 CCGS 自己，不测试使用它制作的游戏 |

注意：普通文件列表工具可能默认忽略隐藏目录，初学者最常见的误判就是只看到空的 `src/`，以为项目没有实现。研究本仓库时必须显式查看 `.claude/`。

## 4. 三条主线

### 开发产物主线

```text
概念 → 系统 GDD → 架构/ADR → Epic → Story → 代码/测试 → 发布资料
```

每一步的输出会成为下一步的输入。例如 `/create-stories` 不能凭空拆故事，它需要读取 GDD、ADR 和技术需求；`/dev-story` 又要读取故事、TR 注册表、控制清单和引擎偏好。

### 组织主线

```text
Director → Department Lead → Specialist
```

高层角色守住愿景、架构和范围；部门负责人把方向转成可执行方案；专家完成具体设计、实现或验证。

### 质量主线

```text
模板约束 + 路径规则 + Hook 检查 + 专家评审 + 阶段 Gate
```

这些机制不是同一种检查。Rule 是编辑时上下文，Hook 是事件脚本，Agent 评审是模型判断，Gate 则综合工件存在性和多领域意见。

## 5. 版本观察

本课程分析到的仓库状态有几项值得记住：

- Git 标签为 `v1.0.0`，主分支为 `main`。
- README 宣称 41 个模板，当前 `.claude/docs/templates/` 实际有 40 个文件；学习时以文件系统为准。
- 73 个 Skill 都有完整基础 frontmatter，但自测目录当前只有 72 个 Skill 规格；新增的 `vertical-slice` 尚未进入 `catalog.yaml`/规格目录。
- 仓库没有 `.github/workflows/` CI 工作流；现有质量验证主要通过 Claude Code Skill、Hook 和人工评审完成。

这些不是使用课程的阻塞项，但说明维护提示词框架也需要做“文档—实现—测试目录”的一致性检查。

## 6. 推荐源码阅读顺序

不要一上来逐个阅读 73 个 Skill。按以下顺序效率更高：

1. `README.md`：理解产品目标和能力范围。
2. `CLAUDE.md`：找到全局引用入口。
3. `.claude/settings.json`：理解自动化触发点。
4. `.claude/docs/workflow-catalog.yaml`：建立七阶段地图。
5. `.claude/skills/start/SKILL.md`：看一个入口 Skill。
6. `.claude/skills/dev-story/SKILL.md`：看核心实现 Skill。
7. `.claude/agents/lead-programmer.md`：看 Agent 的角色边界。
8. `.claude/docs/director-gates.md`：看高风险决策如何评审。
9. `.claude/hooks/` 和 `.claude/rules/`：看自动约束。
10. `CCGS Skill Testing Framework/`：最后理解框架如何自测。

## 本课检查

如果你能不看文档回答下面问题，就可以进入下一课：

1. 为什么 `src/` 很空但项目仍有大量“实现”？
2. Skill 和 Agent 分别解决什么问题？
3. Hook 与 Rule 的触发方式有何不同？
4. 哪个目录是 CCGS 的自测层，为什么它可以删除？

