# 06 Hooks、Rules 与安全边界

## 1. 三种约束层

| 机制 | 何时生效 | 适合做什么 |
|---|---|---|
| Permission | 工具调用授权时 | 阻止危险命令和敏感文件读取 |
| Rule | 编辑匹配路径时 | 注入该目录的编码或文档标准 |
| Hook | 指定生命周期事件发生时 | 自动检查、记录、通知、恢复上下文 |

三者互补。Rule 说“玩法数值必须数据驱动”，Hook 可以在提交时扫描硬编码，而 Permission 直接阻止 `git reset --hard`。

## 2. 12 个 Hook

| Hook | 事件 | 核心行为 |
|---|---|---|
| `session-start.sh` | SessionStart | 显示分支、提交、Sprint 和会话状态 |
| `detect-gaps.sh` | SessionStart | 检测空白项目、缺设计文档、缺 ADR、缺计划 |
| `validate-commit.sh` | PreToolUse/Bash | 仅在 Git commit 时做 JSON、TODO、硬编码、GDD 检查 |
| `validate-push.sh` | PreToolUse/Bash | 对受保护分支 push 给出阻止或警告 |
| `validate-assets.sh` | PostToolUse/Write/Edit | 校验 assets 命名和 JSON |
| `validate-skill-change.sh` | PostToolUse/Write/Edit | 修改 Skill 后建议运行 `/skill-test` |
| `notify.sh` | Notification | Windows 上尝试发送 PowerShell toast |
| `pre-compact.sh` | PreCompact | 输出 active state、改动文件和 WIP 标记 |
| `post-compact.sh` | PostCompact | 提醒从文件恢复上下文 |
| `session-stop.sh` | Stop | 归档会话状态和近期 Git 活动 |
| `log-agent.sh` | SubagentStart | 记录 Agent 调用开始 |
| `log-agent-stop.sh` | SubagentStop | 记录 Agent 调用结束 |

多数 Hook 会先判断“本次事件是否与我有关”，无关时快速 `exit 0`。因为 PreToolUse/PostToolUse 可能很频繁，快速退出是性能要求。

## 3. 退出码和输入

Hook 通常从标准输入接收 JSON。以 Bash PreToolUse 为例，关键字段是 `tool_input.command`。脚本优先使用 `jq`，缺失时用 `grep/sed` 降级。

一般约定：

- `exit 0`：允许继续，或只输出建议；
- `exit 2`：阻止工具调用并把错误展示给 Claude；
- 其他非零码应谨慎使用，避免因辅助检查破坏整个会话。

修改 Hook 前先读 `.claude/docs/hooks-reference/hook-input-schemas.md`，不要凭印象猜事件 JSON 字段。

## 4. 11 条路径规则

| 路径 | 重点 |
|---|---|
| `src/gameplay/**` | 数据驱动、delta time、不得直接依赖 UI |
| `src/core/**` | 热路径零分配、线程安全、API 稳定 |
| `src/ai/**` | 2ms 预算、可调参数、可视化调试 |
| `src/networking/**` | 服务端权威、消息版本化、安全验证 |
| `src/ui/**` | UI 不拥有游戏状态、本地化、可访问性 |
| `assets/data/**` | JSON 正确、命名、Schema 和范围 |
| `assets/shaders/**` | Shader 命名、性能和跨平台规范 |
| `design/gdd/**` | 八章节、公式、边界和验收标准 |
| `design/narrative/**` | Canon、角色声音和矛盾检查 |
| `tests/**` | 命名、AAA 结构、隔离和清理 |
| `prototypes/**` | 放宽生产规范，但必须记录假设和结论 |

Prototype 放宽约束很重要：框架区分“为了学习而快速试错”和“可长期维护的生产代码”。

## 5. 状态栏

`.claude/statusline.sh` 接收 Claude Code 的状态 JSON，输出：

```text
ctx: 42% | Sonnet | Production | Core Loop > Movement > Collision
```

阶段优先读取 `production/stage.txt`，缺失时按工件自动推断。Production、Polish、Release 阶段还会解析 `active.md` 的 STATUS 块。

## 6. 安全检查实验

只做语法检查，不执行 Hook 的业务行为。当前 Windows 工作区启用了
`core.autocrlf=true`，脚本被检出为 CRLF；部分 Bash 会把行尾 `\r` 当成
语法字符。因此下面通过管道临时去掉 `CR`，不会改动仓库文件：

```bash
sed 's/\r$//' .claude/statusline.sh | bash -n
for f in .claude/hooks/*.sh; do
  sed 's/\r$//' "$f" | bash -n || exit 1
done
python -m json.tool .claude/settings.json
```

若报错只在直接读取 CRLF 文件时出现，而规范化流检查通过，说明问题是
checkout 换行符；若规范化后仍失败，才是脚本语法问题。真实 Hook 运行也
必须使用 LF 文件。遇到该问题时先检查 `git config --get core.autocrlf`，
再在专用分支统一换行策略，不要把整仓库换行变化混进功能提交。

然后手动运行只读启动 Hook：

```bash
sed 's/\r$//' .claude/hooks/session-start.sh | bash
sed 's/\r$//' .claude/hooks/detect-gaps.sh | bash
```

这里同样只对输入流做换行规范化。预期第二个脚本识别当前仓库为新项目。
它只报告，不应创建游戏工件。

不要用真实 `git commit` 或 `git push` 来测试拦截。若要研究 PreToolUse 输入，应在课程分支中把一段模拟 JSON通过标准输入传给脚本，并确保命令字段不是破坏性命令。

## 7. 修改 Hook 的检查清单

- 使用 `grep -E`，不要使用 Windows Git Bash 不支持的 `grep -P`；
- 没有 `jq`/Python 时仍应优雅降级；
- 无关事件尽快退出；
- 路径带空格时正确引用；
- 输出简短、可行动；
- 明确是 advisory 还是 blocking；
- 至少对 LF/规范化输入运行 `bash -n`，再运行一个模拟输入用例；
- 同步更新 hooks reference。

## 本课检查

1. Permission、Rule、Hook 各在什么时机生效？
2. 为什么 Hook 必须对无关事件快速退出？
3. `exit 0` 与 `exit 2` 的语义是什么？
4. 原型目录为什么故意使用更宽松的规则？
