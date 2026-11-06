# 03 配置、上下文与作用域

## 1. 两类配置不要混淆

CCGS 同时使用“给模型看的指令”和“给运行器看的设置”：

| 类型 | 代表文件 | 作用 |
|---|---|---|
| 指令上下文 | `CLAUDE.md`、目录内 `CLAUDE.md`、Rule、Skill、Agent | 告诉模型应该如何思考和工作 |
| 运行设置 | `.claude/settings.json` | 配置权限、状态栏和事件 Hook |

自然语言指令不是注释，它们就是框架行为的一部分。修改措辞可能和修改代码一样改变执行结果。

## 2. 根 `CLAUDE.md` 是总入口

根文件定义项目性质、技术栈占位符、协作协议，并用 `@路径` 引入：

- `.claude/docs/directory-structure.md`
- `.claude/docs/technical-preferences.md`
- `.claude/docs/coordination-rules.md`
- `.claude/docs/coding-standards.md`
- `.claude/docs/context-management.md`

这里仍有 `[CHOOSE]` 和 `[SPECIFY]` 占位符，说明模板尚未配置引擎。`/setup-engine` 的任务之一就是把抽象模板变成某个实际游戏项目的技术配置。

## 3. 目录级 `CLAUDE.md`

仓库还在三个业务目录放置局部说明：

- `src/CLAUDE.md`：引擎 API 风险、数据驱动、测试优先、文件路由；
- `design/CLAUDE.md`：GDD 八个必需章节、设计顺序、UX 路径；
- `docs/CLAUDE.md`：ADR 生命周期、TR 注册表、控制清单、引擎参考。

因此，同一个“写文件”动作会因目标路径不同而获得不同上下文。编辑 `src/gameplay/` 时既要遵守源码目录说明，也要遵守 `gameplay-code.md` 路径规则。

## 4. `settings.json`

当前设置包含三块：

1. `statusLine`：执行 `.claude/statusline.sh`，显示上下文占用、模型、阶段和生产面包屑；
2. `permissions.allow/deny`：放行只读 Git、测试等安全命令，拒绝强推、硬重置、递归删除和读取 `.env`；
3. `hooks`：把 Claude Code 生命周期事件映射到 12 个脚本。

权限只是防线之一。Skill 的 `allowed-tools`、Agent 的 `tools/disallowedTools` 和协作协议也会限制行为。

## 5. 文件是长期记忆

`.claude/docs/context-management.md` 的核心原则是：

> 文件才是记忆，对话不是。

长任务使用 `production/session-state/active.md` 保存：

- 当前任务；
- 已完成步骤；
- 已作决定；
- 正在编辑的文件；
- 未决问题。

进入 Production 以后，可加入状态块：

```markdown
<!-- STATUS -->
Epic: Core Loop
Feature: Player Movement
Task: Add collision test
<!-- /STATUS -->
```

状态栏会将其显示为面包屑。上下文压缩前，`pre-compact.sh` 输出这份状态和未提交文件；压缩后，`post-compact.sh` 提醒重新读取；会话结束时，`session-stop.sh` 将状态追加到日志但不删除 `active.md`。

## 6. 增量写作模式

大型 GDD 不应在一次长对话中全部完成。框架推荐：

1. 先创建包含全部标题的骨架；
2. 一次讨论一个章节；
3. 用户批准后立即写入；
4. 更新会话状态；
5. 再进入下一章节。

这既控制上下文长度，也让中断后的恢复点明确。`design-system`、`ux-design` 和 `art-bible` 都体现了这种模式。

## 7. 阅读练习

依次打开以下文件，只回答每个文件的“控制对象”是什么：

```text
CLAUDE.md
.claude/settings.json
src/CLAUDE.md
.claude/rules/gameplay-code.md
.claude/docs/context-management.md
```

然后假设要编辑 `src/gameplay/dodge/player.gd`，列出会影响这次编辑的至少四层约束。参考答案：根配置、`src/CLAUDE.md`、`gameplay-code.md`、具体 Agent/Skill 指令，以及 settings 权限/Hook。

## 本课检查

1. 为什么不能把自然语言配置当作普通说明文档？
2. `settings.json` 与 `CLAUDE.md` 的职责差异是什么？
3. 为什么先写骨架有助于上下文管理？
4. `active.md` 在正常退出后是否会被自动删除？答案是不会。

