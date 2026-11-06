# 10 渐进实验与结业项目

所有实验都建议在课程分支或仓库副本中完成。每个实验开始和结束都运行：

```bash
git status --short
git diff --stat
```

## 实验 1：手工盘点框架

目标：确认隐藏目录才是主体。

```bash
find .claude/agents -maxdepth 1 -name '*.md' | wc -l
find .claude/skills -name 'SKILL.md' | wc -l
find .claude/hooks -maxdepth 1 -name '*.sh' | wc -l
find .claude/rules -maxdepth 1 -name '*.md' | wc -l
```

验收：得到 49、73、12、11，并能解释四类文件的职责。PowerShell 用户也可用 `Get-ChildItem`，但真正运行 Hook 仍使用 Bash。

## 实验 2：追踪启动链

目标：把 settings 中的配置映射到实际脚本。

1. 打开 `.claude/settings.json`。
2. 为每个事件写出 matcher、脚本和 timeout。
3. 运行 `session-start.sh` 与 `detect-gaps.sh`。
4. 对照输出指出每一行来自哪个脚本分支。

验收：能解释为什么空模板会提示 `/start`，以及为什么无关的 PreToolUse Hook 应快速退出。

## 实验 3：完成首次定向

目标：理解用户决策如何写成项目状态。

1. 运行 `/start`。
2. 使用“闪避方块”明确概念。
3. 选择 formalize 和 lean。
4. 停在 Skill 给出的下一条命令处。
5. 检查 `production/stage.txt` 与 `production/review-mode.txt`。

验收：两个文件内容分别是 `Concept` 和 `lean`，且没有未经确认自动进入后续 Skill。

## 实验 4：逆向阅读一个 Skill

目标：从自然语言指令还原流程图。

阅读 `.claude/skills/design-system/SKILL.md`，制作下表：

| 项目 | 你的答案 |
|---|---|
| 参数与默认值 | |
| 必需上游 | |
| 可选上下文 | |
| 会创建/修改的文件 | |
| 用户批准点 | |
| Agent/Gate | |
| Blocked 条件 | |
| 下一步 | |

验收：能说明 normal 与 retrofit 模式的差异，并指出为何已有章节不得覆盖。

## 实验 5：比较三个 Agent

目标：理解角色边界。

比较：

- `.claude/agents/creative-director.md`
- `.claude/agents/lead-programmer.md`
- `.claude/agents/gameplay-programmer.md`

对同一个问题“闪避方块需要加冲刺”分别写出三者应回答什么、不应回答什么，以及冲突时向谁升级。

验收：Director 聚焦支柱/范围，Lead 聚焦结构/可维护性，Specialist 聚焦实现；没有角色越权替用户定案。

## 实验 6：走一遍最小设计链

目标：实际体验工件依赖。

在 Claude Code 中按顺序推进，所有写入先看草稿：

```text
/brainstorm 2D 单屏闪避游戏，玩家坚持 60 秒获胜
/setup-engine godot <你实际安装的版本>
/map-systems
/design-system player-movement
/design-review design/gdd/player-movement.md
```

如果没有安装 Godot，可停在引擎选择建议，不要伪造版本。课程重点是观察每个 Skill 读取什么、写出什么。

验收：概念、系统索引和至少一个八章节 GDD 相互引用；实体/常量跨系统出现时登记到 registry。

## 实验 7：验证与缺口审计

目标：区分格式、规格与真实行为测试。

```bash
python -m json.tool .claude/settings.json
for f in .claude/hooks/*.sh; do sed 's/\r$//' "$f" | bash -n || exit 1; done
```

这里先规范化输入，是为了区分 Windows CRLF checkout 与真正的 Bash 语法
错误；该管道不会改动文件。

在 Claude Code 中运行：

```text
/skill-test static help
/skill-test audit
```

验收：报告能识别覆盖状态；你能指出 `vertical-slice` 的规格登记缺口，但不在本实验中擅自改动上游框架。

## 实验 8：设计一次框架扩展

目标：形成维护思维。无需立即写文件，先做设计评审。

设计一个 `/dependency-audit` Skill：扫描 Story 的依赖是否形成环，输出只读报告。

你的方案应包含：

- category：analysis；
- 参数：可选 epic slug；
- tools：`Read, Glob, Grep`，原则上不需要 Write/Edit/Bash；
- 阶段：定位 Stories → 读取依赖 → 构图 → 环检测 → 结构化报告；
- Verdict：PASS / CONCERNS / FAIL；
- 无参数与无 Story 的行为；
- 下一步建议；
- spec 的正常、环依赖、缺失依赖、空项目、用户拒绝写入五个场景；
- 需要同步的 skills reference、catalog 和质量规格。

验收：同伴或你自己能只看设计就判断输入、输出、权限和失败行为，没有“扫描时顺便自动修文件”。

## 结业项目

选择以下之一：

### A. 使用者路线

把“闪避方块”推进到 Pre-Production Gate：至少包含概念、系统索引、2 个 GDD、架构、3 个 Foundation ADR、Control Manifest、3 个 UX spec、1 个 Epic 和若干 Stories。运行 `/gate-check production`，记录 PASS/CONCERNS/FAIL 及修正计划。

### B. 维护者路线

真正实现实验 8 的 `/dependency-audit`，补齐 Skill、参考文档、catalog、行为规格和测试记录。在临时夹具中验证无依赖、正常链、缺失节点和环四种情况。

## 结业评分

| 维度 | 通过标准 |
|---|---|
| 架构理解 | 能画出 Skill—Agent—Artifact—Hook 的关系 |
| 流程理解 | 能说明七阶段及各阶段退出条件 |
| 安全性 | 所有写入有明确范围，未使用危险 Git/文件命令 |
| 可追踪性 | 至少一条 GDD→TR→ADR→Story→Evidence 链完整 |
| 验证 | 同时使用静态、规格/量表和实际会话检查 |
| 复盘 | 记录一个框架优点、一个限制和一个改进建议 |
