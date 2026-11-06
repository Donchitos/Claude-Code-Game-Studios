# 05 · Hook 自动化守卫

前面讲的 agent 和 skill 都是"AI 主动遵守"的软约束。Hook 不一样——它是**硬约束**，是机器自动执行的脚本，AI 绕不过去。这一篇拆解 12 个钩子怎么守住底线。

---

## Hook 是什么

Hook = **在特定事件自动触发的脚本**。Claude Code 在关键节点（会话开始、工具调用前、工具调用后、会话结束等）会自动跑你配置的脚本。

**和 skill 的区别**：
- Skill 是 AI 主动读、主动执行的"作业流程"。
- Hook 是**事件驱动**的，AI 不调用它，它在事件发生时自动跑。

**和 rule 的区别**：
- Rule 是"写代码时遵守的规范"，靠 AI 自觉。
- Hook 是"提交时强制检查"，AI 想绕也绕不过。

**类比**：rule 是"公司规章制度"（靠自觉），hook 是"门口的金属探测门"（强制）。

---

## 退出码：钩子的"语言"

钩子靠**退出码**和 Claude Code 通信。这是最重要的概念：

| 退出码 | 含义 | 行为 |
|--------|------|------|
| `exit 0` | 放行 | 工具调用继续 |
| `exit 2` | 阻止 | 工具调用被阻止，stderr 内容反馈给 AI |
| 其他（如 `exit 1`） | 非阻塞警告 | 警告显示但工具调用继续 |

**关键设计**：只有 `exit 2` 能硬阻止。其他都是建议性的。

看 [validate-commit.sh](file:///workspace/.claude/hooks/validate-commit.sh) 的两类用法：

```bash
# 硬阻止（JSON 不合法就拦下）：
if ! "$PYTHON_CMD" -m json.tool "$file" > /dev/null 2>&1; then
    echo "BLOCKED: $file is not valid JSON" >&2
    exit 2
fi

# 软警告（设计文档缺章节、硬编码数值，只警告不拦）：
WARNINGS="$WARNINGS\nDESIGN: $file missing required section: $section"
...
exit 0   # 最后还是放行
```

**编排启示**：硬阻止用于"绝对不能发生的"（无效 JSON 会崩游戏），软警告用于"应该但不致命的"（缺章节、硬编码）。区分对待，避免钩子太烦人被关掉。

---

## 8 类钩子事件

来自 [settings.json](file:///workspace/.claude/settings.json) 的 `hooks` 配置。Claude Code 支持这些事件：

| 事件 | 何时触发 | 这个项目挂了什么 |
|------|----------|-------------------|
| `SessionStart` | 会话开始 | `session-start.sh`（显示分支和最近提交）、`detect-gaps.sh`（检测新项目/缺设计文档） |
| `PreToolUse` | 工具调用前 | `validate-commit.sh`（提交前校验）、`validate-push.sh`（推送前校验） |
| `PostToolUse` | 工具调用后 | `validate-assets.sh`（写资产后校验）、`validate-skill-change.sh`（改 skill 后提醒测试） |
| `Notification` | 通知事件 | `notify.sh`（Windows 弹 toast） |
| `PreCompact` | 压缩前 | `pre-compact.sh`（保存会话进度笔记） |
| `PostCompact` | 压缩后 | `post-compact.sh`（提醒从 active.md 恢复状态） |
| `Stop` | 会话结束 | `session-stop.sh`（归档 active.md 到日志） |
| `SubagentStart` | 子智能体启动 | `log-agent.sh`（审计日志开始） |
| `SubagentStop` | 子智能体停止 | `log-agent-stop.sh`（审计日志结束） |

---

## settings.json 怎么挂钩子

看 [settings.json](file:///workspace/.claude/settings.json) 的结构：

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "bash .claude/hooks/validate-commit.sh",
          "timeout": 15
        },
        {
          "type": "command",
          "command": "bash .claude/hooks/validate-push.sh",
          "timeout": 10
        }
      ]
    }
  ],
  "PostToolUse": [
    {
      "matcher": "Write|Edit",
      "hooks": [ ... ]
    }
  ]
}
```

**关键字段**：

- **`matcher`**：匹配哪些工具。`"Bash"` = 只在 Bash 工具调用时触发；`"Write|Edit"` = 写或编辑时触发；`""` = 所有工具都触发。
- **`timeout`**：超时秒数。超时按放行处理（避免钩子卡死整个会话）。
- **`command`**：跑什么命令。钩子通过 stdin 收到 JSON，通过退出码和 stderr 反馈。

---

## 12 个钩子逐一拆解

### 1. `session-start.sh`（SessionStart）

会话一开始就跑。显示当前分支和最近提交，帮你"找回状态"。

**编排作用**：长项目里，你打开会话第一眼就知道"我在哪、最近干了啥"。这是"上下文恢复"的第一步。

### 2. `detect-gaps.sh`（SessionStart）

检测项目缺口：
- 全新项目（没有引擎配置、没有游戏概念）→ 建议 `/start`
- 有代码或原型但没有设计文档 → 提醒补设计文档

**编排作用**：自动诊断"项目健康度"。防止"埋头写代码忘了写设计"。

### 3. `validate-commit.sh`（PreToolUse, matcher: Bash）

每次 Bash 工具调用都触发，但**只在命令是 `git commit` 时真正执行**，其他情况立即 `exit 0`。这是性能优化——钩子挂得广但跑得轻。

检查内容：
- **设计文档章节**：`design/gdd/` 下的 `.md` 必须有 8 个必需章节（Overview / Player Fantasy / Detailed / Formulas / Edge Cases / Dependencies / Tuning Knobs / Acceptance Criteria）。缺章节 → 警告。
- **JSON 合法性**：`assets/data/*.json` 必须是合法 JSON。不合法 → **硬阻止**（exit 2）。
- **硬编码数值**：`src/gameplay/` 下出现 `damage = 25.0` 这种 → 警告（应该用数据文件）。
- **TODO 格式**：`src/` 下的 TODO 必须带 owner，如 `TODO(name)`。裸 TODO → 警告。

**编排作用**：在"提交"这个天然检查点，自动跑多维度质检。AI 想偷偷提交硬编码代码？警告会显示出来。

### 4. `validate-push.sh`（PreToolUse, matcher: Bash）

类似上面，但只在 `git push` 时执行。警告推送到受保护分支（如 main）。

### 5. `validate-assets.sh`（PostToolUse, matcher: Write|Edit）

每次写/编辑文件后触发，但**只在文件路径在 `assets/` 下时真正执行**。校验命名规范和 JSON 结构。

### 6. `validate-skill-change.sh`（PostToolUse, matcher: Write|Edit）

每次写/编辑后触发，但**只在文件路径在 `.claude/skills/` 下时真正执行**。提醒"改了 skill，建议跑 `/skill-test` 验证"。

**编排作用**：防止"改了 skill 引入 bug 但忘了测"。这是元编排——编排系统自己也受钩子守护。

### 7. `pre-compact.sh`（PreCompact）

Claude Code 上下文快满时会自动"压缩"（compact）。压缩前先跑这个钩子，保存会话进度笔记到 `active.md`。

### 8. `post-compact.sh`（PostCompact）

压缩后跑。提醒 AI"从 `active.md` 恢复状态"。

**这两个钩子合起来**：让会话压缩不丢上下文。详见 [08 上下文管理](file:///workspace/study-docs/08-上下文管理艺术.md)。

### 9. `notify.sh`（Notification）

通知事件时跑。Windows 上弹 toast 通知（PowerShell），其他平台无操作。

**编排作用**：长任务跑完通知你。你不用盯着屏幕。

### 10. `session-stop.sh`（Stop）

会话结束时跑。把 `active.md` 归档到会话日志，记录 git 活动。

### 11. `log-agent.sh`（SubagentStart）

每次派生子智能体时跑。记录审计日志开始。

### 12. `log-agent-stop.sh`（SubagentStop）

子智能体结束时跑。完成审计日志记录。

**这两个钩子合起来**：形成完整的子智能体调用审计链。你能事后查"哪个会话派生了哪些子智能体、各跑了多久"。

---

## 钩子的"早退"设计

看 [validate-commit.sh](file:///workspace/.claude/hooks/validate-commit.sh) 的开头：

```bash
# Only process git commit commands
if ! echo "$COMMAND" | grep -qE '^git[[:space:]]+commit'; then
    exit 0
fi
```

**这是关键性能优化**。钩子挂在所有 Bash 调用上（matcher: Bash），但 99% 的 Bash 调用不是 `git commit`。脚本第一件事就是判断"是不是 commit"，不是就立即放行。

README 里专门提醒：

> `validate-commit.sh`、`validate-assets.sh`、`validate-skill-change.sh` 在每次 Bash/Write 工具调用时都触发，但路径/命令不相关时立即 exit 0。这是正常的钩子行为，不是性能问题。

**编排启示**：钩子要"挂得广、跑得轻"。匹配条件不满足时必须立即返回，不能做重活。

---

## 跨平台兼容性

看 [validate-commit.sh](file:///workspace/.claude/hooks/validate-commit.sh) 的细节：

```bash
# 用 jq 如果有，否则降级到 grep
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '...')
fi

# 找一个能用的 Python
for cmd in python python3 py; do
    if command -v "$cmd" >/dev/null 2>&1; then
        PYTHON_CMD="$cmd"
        break
    fi
done
```

**编排启示**：钩子要"优雅降级"。工具缺失时不崩，只是失去部分校验。README 说：

> All hooks fail gracefully if optional tools are missing — nothing breaks, you just lose validation.

---

## 权限规则：钩子的"兄弟"

[settings.json](file:///workspace/.claude/settings.json) 的 `permissions` 是钩子的补充。它不靠脚本，靠模式匹配：

```json
"permissions": {
  "allow": [
    "Bash(git status*)",
    "Bash(git diff*)",
    "Bash(python -m pytest*)"
  ],
  "deny": [
    "Bash(rm -rf *)",
    "Bash(git push --force*)",
    "Bash(git reset --hard*)",
    "Bash(sudo *)",
    "Bash(*>.env*)",
    "Read(**/.env*)"
  ]
}
```

- **`allow`**：自动放行，不弹确认框（`git status`、跑测试）。
- **`deny`**：永远禁止，连确认框都不弹（`rm -rf`、强推、读 `.env`）。

**和钩子的分工**：
- 权限规则管"能不能做"（白名单/黑名单）。
- 钩子管"做了之后/之前怎么检查"（内容校验）。

**编排启示**：硬危险用权限 deny（一刀切），软风险用钩子警告（给 AI 改正机会）。

---

## 钩子的设计哲学

总结这个项目钩子设计的几条原则：

1. **事件驱动，不侵入**：钩子在天然节点（提交、推送、会话开始/结束）跑，不打断 AI 工作流。
2. **早退优化**：匹配不满足立即返回，挂得广跑得轻。
3. **软硬分级**：致命错误 `exit 2` 硬阻止，建议性警告 `exit 0` + stderr。
4. **优雅降级**：工具缺失不崩，只是失去校验。
5. **跨平台**：用 POSIX 兼容的 `grep -E`，不用 `grep -P`。
6. **元守护**：改 skill 的钩子提醒测 skill——编排系统自己也受守护。
7. **审计可追溯**：SubagentStart/Stop 钩子形成完整审计链。

---

## 小测验

**Q1**：钩子的 `exit 2` 和 `exit 0` 有什么区别？
> **A**：`exit 2` 硬阻止工具调用，stderr 反馈给 AI；`exit 0` 放行（即使有 stderr 警告也只是显示，不阻止）。只有 `exit 2` 能拦下 AI 的操作。

**Q2**：为什么 `validate-commit.sh` 挂在所有 Bash 调用上（matcher: Bash），但不会拖慢会话？
> **A**：因为脚本第一件事就是判断"命令是不是 `git commit`"，不是就立即 `exit 0`。99% 的 Bash 调用不是 commit，瞬间返回。这叫"挂得广、跑得轻"。

**Q3**：`pre-compact.sh` 和 `post-compact.sh` 解决什么问题？
> **A**：会话压缩会丢失上下文。`pre-compact` 在压缩前把进度笔记存到 `active.md`，`post-compact` 在压缩后提醒 AI 从 `active.md` 恢复状态。两个钩子让压缩不丢记忆。

---

## 动手

1. 打开 [validate-commit.sh](file:///workspace/.claude/hooks/validate-commit.sh)，找出哪段是"硬阻止"（exit 2），哪段是"软警告"（exit 0 + stderr）。
2. 打开 [session-start.sh](file:///workspace/.claude/hooks/session-start.sh)，看它会话开始时显示什么。
3. 想一想：如果你想加一个"提交前必须跑测试"的钩子，应该挂在哪个事件？matcher 设什么？怎么"早退"？

下一篇 → [06 Rules 路径规则](file:///workspace/study-docs/06-Rules路径规则.md)
