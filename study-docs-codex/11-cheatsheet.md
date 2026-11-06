# 11 速查表与排错指南

## 1. 我现在该用什么

| 情况 | 首选 |
|---|---|
| 第一次使用 | `/start` |
| 不知道当前处于哪个阶段 | `/project-stage-detect` |
| 不知道下一步 | `/help` |
| 已有老项目 | `/adopt`，必要时 `/reverse-document` |
| 从零想游戏 | `/brainstorm open` |
| 拆系统 | `/map-systems` |
| 写正式系统设计 | `/design-system <name>` |
| 小改动/调参 | `/quick-design` |
| 做架构 | `/create-architecture`、`/architecture-decision` |
| 拆工作 | `/create-epics`、`/create-stories` |
| 开始一个 Story | `/story-readiness` → `/dev-story` |
| 完成一个 Story | `/code-review` → `/story-done` |
| 检查能否进入下一阶段 | `/gate-check <target>` |
| 修改了 Skill | `/skill-test static <name>`，再做 spec/category |

## 2. 关键文件

| 想查什么 | 文件 |
|---|---|
| 总体配置入口 | `CLAUDE.md` |
| 自动化和权限 | `.claude/settings.json` |
| 七阶段权威目录 | `.claude/docs/workflow-catalog.yaml` |
| Agent 组织关系 | `.claude/docs/agent-coordination-map.md` |
| Gate 定义 | `.claude/docs/director-gates.md` |
| 技术偏好 | `.claude/docs/technical-preferences.md` |
| 上下文恢复 | `.claude/docs/context-management.md` |
| Skill 定义 | `.claude/skills/<name>/SKILL.md` |
| Agent 定义 | `.claude/agents/<name>.md` |
| 设计跨文档事实 | `design/registry/entities.yaml` |
| 架构跨 ADR 决定 | `docs/registry/architecture.yaml` |
| 技术需求 | `docs/architecture/tr-registry.yaml` |
| 当前会话 | `production/session-state/active.md` |
| 自测目录 | `CCGS Skill Testing Framework/catalog.yaml` |

## 3. 常用只读检查

```bash
git status --short
git diff --stat
git diff
python -m json.tool .claude/settings.json
sed 's/\r$//' .claude/statusline.sh | bash -n
for f in .claude/hooks/*.sh; do sed 's/\r$//' "$f" | bash -n || exit 1; done
```

研究隐藏目录：

```bash
find .claude -type f | sort
```

PowerShell：

```powershell
Get-ChildItem .claude -Recurse -Force -File
Get-ChildItem .claude/skills -Recurse -Filter SKILL.md
```

## 4. 常见问题

### 看不到 Skill/Agent

确认在仓库根目录启动 Claude Code，并确认工具没有忽略 `.claude` 隐藏目录。Skill 必须是 `.claude/skills/<name>/SKILL.md`，平铺 Markdown 不会按 Skill 加载。

### Hook 报 `bash` 不存在

Windows 安装 Git for Windows，并确保 Git Bash 的 `bash` 在 PATH。不要把 Hook 改写成仅 Windows 可用脚本，否则会破坏跨平台目标。

### Hook 在 `elif`、`done` 附近报语法错

先检查 `git config --get core.autocrlf` 和文件是否为 CRLF。用上面的
`sed 's/\r$//' <file> | bash -n` 做规范化流检查：若它通过，则语法本身
正常，问题是 checkout 换行。真实 Hook 文件仍需 LF；应在独立分支统一
Git 换行策略，避免提交无关的全仓库换行变化。

### Hook 解析 JSON 异常

先安装/检查 `jq`；再对照 `.claude/docs/hooks-reference/hook-input-schemas.md` 核对事件字段。不要只修正 grep 正则而忽略输入 Schema 已变化的可能性。

### `/dev-story` 被阻塞

依次检查：Story 路径、依赖 Story 状态、TR-ID、ADR 状态、Control Manifest 版本、引擎配置和测试证据路径。它被阻塞通常说明上游工件未完成，而非 Skill 损坏。

### 评审太慢或上下文太大

将长期默认设为 `lean`；大型文档按章节写；维护 `active.md`；独立研究交给子 Agent；完成一个自然阶段后主动压缩或开始新会话。

### 阶段显示不正确

`production/stage.txt` 优先级高于工件自动检测。先检查这个文件；如果希望自动推断，明确决定后再移除/更新，不要随意删除生产状态。

### 文档计数不一致

以文件系统和机器可读 catalog 为准，随后修正文档。当前版本已知 README 的模板计数与实际文件数有差异，`vertical-slice` 也尚未进入测试 catalog。

## 5. 术语

| 术语 | 简明定义 |
|---|---|
| GDD | 游戏设计文档，描述玩家体验和规则 |
| ADR | 架构决策记录，描述技术选择及代价 |
| TR | 稳定编号的技术需求 |
| Control Manifest | 从已接受 ADR 提炼的程序员规则清单 |
| Epic | 一个架构模块或大交付单元 |
| Story | 可实现、可验收的小工作项 |
| Gate | 阶段就绪评审，不替用户自动决策 |
| Retrofit | 在不覆盖有效内容的前提下补齐旧工件 |
| Brownfield | 已有代码/文档的存量项目 |
| Evidence | 自动测试、截图、记录等完成证据 |

## 6. 最小心智口诀

```text
先读上游，再做决定；
先给选项，再让用户定；
先写骨架，再逐段落盘；
跨域要委派，冲突要升级；
设计变更要向下传播；
没有证据，不算真正完成。
```
