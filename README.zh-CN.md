[English](README.md) | **简体中文** | [日本語](README.ja.md)

<p align="center">
  <h1 align="center">Claude Code Game Studios</h1>
  <p align="center">
    将单个 Claude Code 会话转变为一间完整的游戏开发工作室。
    <br />
    49 个智能体。73 项技能。一支协调一致的 AI 团队。
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT 许可证"></a>
  <a href=".claude/agents"><img src="https://img.shields.io/badge/agents-49-blueviolet" alt="49 个智能体"></a>
  <a href=".claude/skills"><img src="https://img.shields.io/badge/skills-73-green" alt="73 项技能"></a>
  <a href=".claude/hooks"><img src="https://img.shields.io/badge/hooks-12-orange" alt="12 个钩子"></a>
  <a href=".claude/rules"><img src="https://img.shields.io/badge/rules-11-red" alt="11 条规则"></a>
  <a href="https://docs.anthropic.com/en/docs/claude-code"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-f5f5f5?logo=anthropic" alt="为 Claude Code 构建"></a>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support%20this%20project-FFDD00?logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee"></a>
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-Support%20this%20project-ea4aaa?logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

---

## 项目缘起

独自借助 AI 构建游戏很强大，但单个聊天会话缺乏结构。没有人阻止你硬编码魔法数字、跳过设计文档或写出意大利面条式代码。没有 QA 流程、没有设计评审，也没有人追问“这真的符合游戏愿景吗？”

**Claude Code Game Studios** 通过为 AI 会话赋予真实工作室的结构来解决这个问题。你得到的不再是一个通用助手，而是按工作室层级组织的 49 个专业智能体：总监负责守护愿景，部门负责人掌管各自领域，专家负责实际执行。每个智能体都有明确的职责、升级路径和质量关卡。

最终，你仍然做出每一个决定，但现在拥有一支能够提出正确问题、及早发现错误，并让项目从首次头脑风暴到正式发布始终井然有序的团队。

---

## 目录

- [包含内容](#包含内容)
- [工作室层级](#工作室层级)
- [斜杠命令](#斜杠命令)
- [快速开始](#快速开始)
- [升级](#升级)
- [项目结构](#项目结构)
- [工作原理](#工作原理)
- [设计理念](#设计理念)
- [自定义](#自定义)
- [平台支持](#平台支持)
- [社区](#社区)
- [支持本项目](#支持本项目)
- [许可证](#许可证)

---

## 包含内容

| 类别 | 数量 | 说明 |
|----------|-------|-------------|
| **智能体** | 49 | 涵盖设计、编程、美术、音频、叙事、QA 和制作的专业子智能体 |
| **技能** | 73 | 覆盖每个工作流阶段的斜杠命令（`/start`、`/design-system`、`/create-epics`、`/create-stories`、`/dev-story`、`/story-done` 等） |
| **钩子** | 12 | 针对提交、推送、资源变更、会话生命周期、智能体审计轨迹和缺口检测的自动验证 |
| **规则** | 11 | 编辑玩法、引擎、AI、UI、网络代码等内容时强制执行的路径范围编码标准 |
| **模板** | 41 | 用于 GDD、UX 规格、ADR、冲刺计划、HUD 设计、无障碍设计等内容的文档模板 |

## 工作室层级

智能体分为三个层级，与真实工作室的运作方式一致：

```
Tier 1 — Directors (Opus)
  creative-director    technical-director    producer

Tier 2 — Department Leads (Sonnet)
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists (Sonnet/Haiku)
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

### 引擎专家

该模板包含三大主流引擎的智能体集合。请使用与你的项目相匹配的集合：

| 引擎 | 主要智能体 | 子专家 |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript、着色器、GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS、着色器/VFX、Addressables、UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS、蓝图、Replication、UMG/CommonUI |

## 斜杠命令

在 Claude Code 中输入 `/` 即可访问全部 73 项技能：

**引导与导航**
`/start` `/help` `/project-stage-detect` `/setup-engine` `/adopt`

**游戏设计**
`/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**美术与资源**
`/art-bible` `/asset-spec` `/asset-audit`

**UX 与界面设计**
`/ux-design` `/ux-review`

**架构**
`/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest`

**故事与冲刺**
`/create-epics` `/create-stories` `/dev-story` `/sprint-plan` `/sprint-status` `/story-readiness` `/story-done` `/estimate`

**评审与分析**
`/design-review` `/code-review` `/balance-check` `/content-audit` `/scope-check` `/perf-profile` `/tech-debt` `/gate-check` `/consistency-check` `/security-audit`

**QA 与测试**
`/qa-plan` `/smoke-check` `/soak-test` `/regression-suite` `/test-setup` `/test-helpers` `/test-evidence-review` `/test-flakiness` `/skill-test` `/skill-improve`

**制作**
`/milestone-review` `/retrospective` `/bug-report` `/bug-triage` `/reverse-document` `/playtest-report`

**发布**
`/release-checklist` `/launch-checklist` `/changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**创意与内容**
`/prototype` `/onboard` `/localize`

**团队编排**（协调多个智能体共同完成一项功能）
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

## 快速开始

### 前置要求

- [Git](https://git-scm.com/)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)（`npm install -g @anthropic-ai/claude-code`）
- **推荐**：[jq](https://jqlang.github.io/jq/)（用于钩子验证）和 Python 3（用于 JSON 验证）

如果缺少可选工具，所有钩子都会优雅降级：不会有任何功能损坏，只会失去相应的验证能力。

### 设置

1. **克隆仓库或将其用作模板**：
   ```bash
   git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git my-game
   cd my-game
   ```

2. **打开 Claude Code** 并启动会话：
   ```bash
   claude
   ```

3. **运行 `/start`**——系统会询问你当前处于哪个阶段（毫无想法、概念模糊、
   设计明确或已有工作），并引导你进入正确的工作流，不做任何预设。

   如果你已经知道需要什么，也可以直接进入特定技能：
   - `/brainstorm`——从零开始探索游戏创意
   - `/setup-engine godot 4.6`——如果已经确定引擎，则进行引擎配置
   - `/project-stage-detect`——分析现有项目

## 升级

已经在使用该模板的旧版本？请参阅 [UPGRADING.md](UPGRADING.md)，
其中提供了逐步迁移说明、版本间变更明细，
以及哪些文件可以安全覆盖、哪些文件需要手动合并。

## 项目结构

```
CLAUDE.md                           # Master configuration
.claude/
  settings.json                     # Hooks, permissions, safety rules
  agents/                           # 49 agent definitions (markdown + YAML frontmatter)
  skills/                           # 73 slash commands (subdirectory per skill)
  hooks/                            # 12 hook scripts (bash, cross-platform)
  rules/                            # 11 path-scoped coding standards
  statusline.sh                     # Status line script (context%, model, stage, epic breadcrumb)
  docs/
    workflow-catalog.yaml           # 7-phase pipeline definition (read by /help)
    templates/                      # 41 document templates
src/                                # Game source code
assets/                             # Art, audio, VFX, shaders, data files
design/                             # GDDs, narrative docs, level designs
docs/                               # Technical documentation and ADRs
tests/                              # Test suites (unit, integration, performance, playtest)
tools/                              # Build and pipeline tools
prototypes/                         # Throwaway prototypes (isolated from src/)
production/                         # Sprint plans, milestones, release tracking
```

## 工作原理

### 智能体协调

智能体遵循结构化委派模型：

1. **纵向委派**——总监委派给负责人，负责人委派给专家
2. **横向协商**——同层级智能体可以相互咨询，但不能做出具有约束力的跨领域决定
3. **冲突解决**——分歧上报至共同的上级（设计问题上报 `creative-director`，技术问题上报 `technical-director`）
4. **变更传播**——跨部门变更由 `producer` 负责协调
5. **领域边界**——没有明确委派时，智能体不会修改其领域之外的文件

### 协作，而非自主运行

这**不是**一个自动驾驶系统。每个智能体都遵循严格的协作协议：

1. **询问**——智能体在提出解决方案前先提问
2. **提供选项**——智能体展示 2–4 个选项及其优缺点
3. **由你决定**——始终由用户做出选择
4. **起草**——智能体在最终定稿前展示工作成果
5. **批准**——未经你的确认，不会写入任何内容

控制权始终在你手中。智能体提供的是结构与专业能力，而不是自主权。

### 自动安全机制

**钩子**会在每次会话中自动运行：

| 钩子 | 触发条件 | 作用 |
|------|---------|--------------|
| `validate-commit.sh` | PreToolUse (Bash) | 检查硬编码值、TODO 格式、JSON 有效性和设计文档章节；如果命令不是 `git commit`，则立即退出 |
| `validate-push.sh` | PreToolUse (Bash) | 对推送到受保护分支的操作发出警告；如果命令不是 `git push`，则立即退出 |
| `validate-assets.sh` | PostToolUse (Write/Edit) | 验证命名约定和 JSON 结构；如果文件不在 `assets/` 中，则立即退出 |
| `session-start.sh` | 会话打开 | 显示当前分支和最近提交以帮助定位上下文 |
| `detect-gaps.sh` | 会话打开 | 检测全新项目（建议运行 `/start`），并在代码或原型存在时检测缺失的设计文档 |
| `pre-compact.sh` | 压缩前 | 保留会话进度说明 |
| `post-compact.sh` | 压缩后 | 提醒 Claude 从 `active.md` 恢复会话状态 |
| `notify.sh` | 通知事件 | 通过 PowerShell 显示 Windows Toast 通知 |
| `session-stop.sh` | 会话关闭 | 将 `active.md` 归档到会话日志并记录 Git 活动 |
| `log-agent.sh` | 智能体生成 | 启动审计轨迹，记录子智能体调用 |
| `log-agent-stop.sh` | 智能体停止 | 停止审计轨迹，完成子智能体记录 |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | 建议运行 `/skill-test` 来验证任何 `.claude/skills/` 变更 |

> **说明**：`validate-commit.sh`、`validate-assets.sh` 和 `validate-skill-change.sh` 会在每次 Bash/Write 工具调用时触发，并在命令或文件路径不相关时立即退出（exit 0）。这是正常的钩子行为，不会造成性能问题。

`settings.json` 中的**权限规则**会自动允许安全操作（git status、运行测试），并阻止危险操作（强制推送、`rm -rf`、读取 `.env` 文件）。

### 路径范围规则

编码标准会根据文件位置自动强制执行：

| 路径 | 强制要求 |
|------|----------|
| `src/gameplay/**` | 数据驱动值、增量时间使用、不得引用 UI |
| `src/core/**` | 热路径零分配、线程安全、API 稳定性 |
| `src/ai/**` | 性能预算、可调试性、数据驱动参数 |
| `src/networking/**` | 服务器权威、版本化消息、安全性 |
| `src/ui/**` | 不持有游戏状态、支持本地化、无障碍 |
| `design/gdd/**` | 必需的 8 个章节、公式格式、边界情况 |
| `tests/**` | 测试命名、覆盖率要求、夹具模式 |
| `prototypes/**` | 宽松标准、必须有 README、记录假设 |

## 设计理念

该模板以专业游戏开发实践为基础：

- **MDA 框架**——针对游戏设计的机制、动态与美学分析
- **自我决定理论**——通过自主、胜任和联结促进玩家动机
- **心流设计**——平衡挑战与技能以提升玩家投入度
- **Bartle 玩家类型**——受众定位与验证
- **验证驱动开发**——先测试，再实现

## 自定义

这是一个**模板**，而不是封闭框架。所有内容都可以自定义：

- **添加/移除智能体**——删除不需要的智能体文件，或为你的领域添加新智能体
- **编辑智能体提示词**——调整智能体行为并添加项目专属知识
- **修改技能**——调整工作流以适应团队流程
- **添加规则**——针对项目目录结构创建新的路径范围规则
- **调整钩子**——调整验证严格度并添加新检查
- **选择引擎**——使用 Godot、Unity 或 Unreal 智能体集合（也可以不使用）
- **设置评审强度**——`full`（所有总监关卡）、`lean`（仅阶段关卡）或 `solo`（无关卡）。可在 `/start` 期间设置，也可编辑 `production/review-mode.txt`。在任何技能上使用 `--review solo` 可对单次运行进行覆盖。

## 平台支持

主要开发和测试环境为使用 Git Bash 的 **Windows 10**。所有钩子均使用 POSIX 兼容模式（`grep -E`，而非 `grep -P`），并为缺少工具的情况提供回退机制，因此也应当可以在 macOS 和 Linux 上运行。`notify.sh` 钩子在 Windows 上使用 PowerShell 显示 Toast 通知，在其他平台上不执行任何操作；macOS/Linux 的桌面通知尚未接入。跨平台测试仍在进行中，如遇任何平台特定问题，请提交 Issue。

## 社区

- **讨论区**——使用 [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) 提问、交流想法或展示你的作品
- **Issue**——提交[错误报告和功能请求](https://github.com/Donchitos/Claude-Code-Game-Studios/issues)

---

## 支持本项目

Claude Code Game Studios 是免费开源项目。如果它为你节省了时间或帮助你发布了游戏，可以考虑支持项目的持续开发：

<p>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee"></a>
  &nbsp;
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

- **[Buy Me a Coffee](https://www.buymeacoffee.com/donchitos3)**——一次性支持
- **[GitHub Sponsors](https://github.com/sponsors/Donchitos)**——通过 GitHub 提供定期支持

赞助将帮助维护技能、添加新智能体、跟进 Claude Code 与引擎 API 的变更，以及回应社区问题。

---

*为 Claude Code 构建。持续维护和扩展——欢迎通过 [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) 贡献。*

## 许可证

MIT 许可证。详情请参阅 [LICENSE](LICENSE)。
