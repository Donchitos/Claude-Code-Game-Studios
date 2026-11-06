# 02 环境准备与第一次会话

## 1. 最小环境

必需：

- Git；
- Claude Code；
- 能运行 Bash 的环境。Windows 推荐 Git Bash。

推荐：

- `jq`：可靠解析 Hook 收到的 JSON；
- Python 3：JSON 验证和后续游戏测试；
- 你选择的游戏引擎，真正进入实现阶段时才需要。

在仓库根目录检查：

```bash
git --version
claude --version
bash --version
jq --version
python --version
```

`jq` 或 Python 缺失不会让所有 Hook 失效；脚本普遍提供降级路径。但降级解析不如标准 JSON 解析稳健，正式使用建议安装。

## 2. 保护练习环境

先确认工作树：

```bash
git status --short
git branch --show-current
```

建议为课程创建分支或复制仓库。`/start` 会至少写入 `production/stage.txt` 和 `production/review-mode.txt`，后续流程还会产生设计与生产文件。

```bash
git switch -c codex/ccgs-course
```

不要把真实游戏的已有修改和课程实验混在同一个未提交工作区。

## 3. 启动时发生什么

从仓库根目录执行：

```bash
claude
```

Claude Code 会读取项目配置，`settings.json` 中的 `SessionStart` 事件随后运行：

1. `session-start.sh`：显示分支、近期提交、当前 Sprint/里程碑和会话状态；
2. `detect-gaps.sh`：检查引擎、概念、源码、GDD、原型和生产资料是否存在。

当前模板是空白项目，因此预期会看到“NEW PROJECT”并建议 `/start`。这不是错误，而是缺口检测器的正确输出。

## 4. `/start` 做了什么

`/start` 不是“一键生成游戏”。它按顺序完成：

1. 静默扫描项目状态；
2. 询问你处于无想法、模糊想法、明确概念还是已有项目；
3. 根据答案推荐工作流；
4. 设置当前阶段 `production/stage.txt`；
5. 设置评审强度 `production/review-mode.txt`；
6. 询问你是否进入推荐的第一个 Skill；
7. 只给出下一条命令，不擅自继续。

这体现项目的核心协议：`Question → Options → Decision → Draft → Approval`。

## 5. 三种评审模式

| 模式 | 行为 | 适合 |
|---|---|---|
| `full` | 关键 Skill 内联评审和阶段 Gate 都调用相应负责人 | 学习流程、团队项目、高风险决策 |
| `lean` | 跳过多数内联负责人评审，但 `/gate-check` 仍运行四方阶段评审 | 独立开发、小团队，默认推荐 |
| `solo` | 不调用 Director Gate，主要做工件和规则检查 | Game Jam、概念验证、成本敏感场景 |

命令可用 `--review full|lean|solo` 覆盖当前运行；否则读取 `production/review-mode.txt`，缺失时通常默认 `lean`。

## 6. 第一次练习

使用“闪避方块”概念：

1. 运行 `/start`。
2. 选择“Clear concept”。
3. 用一句话描述：“一个 2D 单屏游戏，玩家移动方块躲避障碍，坚持 60 秒获胜。”
4. 选择“Formalize it first”。
5. 选择 `lean` 评审模式。
6. 当 Skill 建议下一步时，先停止并检查文件。

检查：

```bash
git status --short
git diff -- production/stage.txt production/review-mode.txt
```

预期结果：阶段为 `Concept`，评审模式为 `lean`。如果没有产生文件，检查会话是否在仓库根目录启动，以及写入操作是否被权限设置拒绝。

## 7. 初学者常见误区

- 把 `/start` 当作必须每次运行的初始化脚本。它主要用于首次定向；返回项目可用 `/help` 或 `/project-stage-detect`。
- 在 PowerShell 直接假设所有 Bash Hook 都能正常工作。应确保 `bash` 可执行且路径正确。
- 未看 `git diff` 就连续运行多个 authoring Skill。每个 Skill 都可能产生多个长期工件。
- 认为 `full` 一定更好。它更彻底，也更慢、更耗上下文；课程练习用 `lean` 足够。
- 在当前模板中直接运行 `/dev-story`。它需要上游 GDD、ADR、TR 和 Story，跳过阶段会得到合理的阻塞提示。

## 本课检查

1. 首次会话会自动运行哪两个 Hook？
2. `/start` 会写哪两个状态文件？
3. `lean` 与 `solo` 在 `/gate-check` 上的关键差异是什么？
4. 为什么开始练习前应先创建分支或仓库副本？
