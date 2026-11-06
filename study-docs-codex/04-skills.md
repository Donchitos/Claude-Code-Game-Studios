# 04 Skill：工作流的剧本

## 1. Skill 是什么

Skill 是可调用的过程定义，目录格式固定为：

```text
.claude/skills/<skill-name>/SKILL.md
```

它回答五个问题：

1. 用户如何调用？
2. 开始前读什么？
3. 分几个阶段执行？
4. 可以使用哪些工具或 Agent？
5. 何时必须停下来让用户决定？

Agent 更像“谁来做”，Skill 更像“按什么流程做”。很多 Skill 会指定主 Agent，或在流程中通过 `Task` 调用多个 Agent。

## 2. Frontmatter

73 个 Skill 都包含这些基础字段：

```yaml
---
name: design-system
description: "..."
argument-hint: "<system-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Task, AskUserQuestion, TodoWrite
model: sonnet
---
```

字段含义：

- `name`：斜杠命令名；
- `description`：触发场景和能力边界；
- `argument-hint`：参数提示，也是无参数错误处理的依据；
- `user-invocable`：是否允许用户直接调用；
- `allowed-tools`：最小工具权限；
- `model`：复杂度分层，当前为 7 个 Haiku、63 个 Sonnet、3 个 Opus；
- 可选 `agent`：指定首选角色；
- 可选 `context: fork`：隔离上下文；
- 可选 `isolation: worktree`：在独立工作树中执行高改动任务。

`prototype` 和 `vertical-slice` 使用 worktree 隔离，因为原型开发可能产生大量实验性修改。

## 3. 典型 Skill 结构

一个可靠 Skill 通常包含：

1. 参数解析和缺失参数提示；
2. review mode 解析；
3. 上游工件检查；
4. 一次性加载必要上下文；
5. 分阶段工作；
6. 写入前批准；
7. 结构化结果和 Verdict；
8. 阻塞恢复；
9. 明确下一步。

这并非语法强制，而是本项目通过 `/skill-test static` 检查的设计规范。

## 4. 三个代表性 Skill

### `/start`：路由型

先探测，再提问，根据用户处境把人送到正确流程。它的成功标准不是产生大量文件，而是“用户知道下一步”。

### `/design-system`：创作型

它先读取概念、系统索引、实体注册表、依赖 GDD 和历史一致性问题，再按 GDD 八章节逐段协作。它还支持 retrofit 模式，只填补缺失章节，不覆盖已有内容。

### `/dev-story`：实现编排型

它读取 Story、TR、ADR、Control Manifest、依赖状态和引擎参考，然后路由到适合的程序员和引擎专家，要求代码与测试一起完成，最后更新状态并交给 `/code-review`、`/story-done`。

这三个 Skill 代表“导航—设计—实现”三个复杂度层次。

## 5. Skill 分类

自测框架把 Skill 分成九类：

| 类别 | 主要目的 | 例子 |
|---|---|---|
| gate | 阶段转换 | `gate-check` |
| review | 对工件给出结构化结论 | `design-review`、`architecture-review` |
| authoring | 协作创作文档 | `design-system`、`ux-design` |
| readiness | 开工或完工判断 | `story-readiness`、`story-done` |
| pipeline | 产生下游消费的工件 | `create-epics`、`dev-story` |
| analysis | 只读扫描和发现问题 | `code-review`、`scope-check` |
| team | 多 Agent 领域编排 | `team-combat`、`team-ui` |
| sprint | 生产状态和计划 | `sprint-plan`、`retrospective` |
| utility | 其他支撑流程 | `start`、`help`、`hotfix` |

## 6. 如何阅读一个陌生 Skill

以 `.claude/skills/dev-story/SKILL.md` 为例，按以下问题做笔记：

1. 输入参数是什么？缺失时怎么处理？
2. 必需上游文件有哪些？哪个是最终事实源？
3. 哪些步骤可以并行？
4. 哪些文件会被修改？
5. 哪些条件会 BLOCKED？
6. 最终 Verdict 是什么？
7. 它把用户交给哪个下一步？

不要从第一行逐字背诵；先抽取“输入—阶段—输出—停顿点”的骨架，再阅读细节。

## 7. 安全扩展原则

修改或新增 Skill 时至少同步：

- `.claude/skills/<name>/SKILL.md`；
- `.claude/docs/skills-reference.md` 和必要的 workflow catalog；
- `CCGS Skill Testing Framework/catalog.yaml`；
- 对应 category 的规格文件；
- 如果引入新 Gate，再更新 `.claude/docs/director-gates.md`。

新增 Skill 应保持工具最小化。只读分析不要给 `Write/Edit`；不需要 shell 就不要给 `Bash`；只有实际编排子 Agent 时才给 `Task`。

## 本课练习

对 `/help`、`/design-system`、`/dev-story` 各做一张四列表：输入、读取、写入、下一步。若你能解释为什么三者分别使用 Haiku、Sonnet、Sonnet，就掌握了 Skill 的基本阅读方法。

