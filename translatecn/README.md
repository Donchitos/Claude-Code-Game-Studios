<p align="center">
  <h1 align="center">Claude Code Game Studios</h1>
  <h1 align="center">Claude Code 游戏工作室</h1>
  <p align="center">
    Turn a single Claude Code session into a full game development studio.
    将单个 Claude Code 会话变成一间完整的游戏开发工作室。
    <br />
    49 agents. 74 skills. One coordinated AI team.
    49 个智能体。74 个技能。一支协同作战的 AI 团队。
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href=".claude/agents"><img src="https://img.shields.io/badge/agents-49-blueviolet" alt="49 Agents"></a>
  <a href=".claude/skills"><img src="https://img.shields.io/badge/skills-74-green" alt="74 Skills"></a>
  <a href=".claude/hooks"><img src="https://img.shields.io/badge/hooks-15-orange" alt="15 Hooks"></a>
  <a href=".claude/rules"><img src="https://img.shields.io/badge/rules-14-red" alt="14 Rules"></a>
  <a href="https://code.claude.com/docs"><img src="https://img.shields.io/badge/built%20for-Claude%20Code-f5f5f5?logo=anthropic" alt="Built for Claude Code"></a>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-Support%20this%20project-FFDD00?logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee"></a>
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-Support%20this%20project-ea4aaa?logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

---

## Why This Exists

Building a game solo with AI is powerful — but a single chat session has no structure. No one stops you from hardcoding magic numbers, skipping design docs, or writing spaghetti code. There's no QA pass, no design review, no one asking "does this actually fit the game's vision?"

**Claude Code Game Studios** solves this by giving your AI session the structure of a real studio. Instead of one general-purpose assistant, you get 49 specialized agents organized into a studio hierarchy — directors who guard the vision, department leads who own their domains, and specialists who do the hands-on work. Each agent has defined responsibilities, escalation paths, and quality gates.

The result: you still make every decision, but now you have a team that asks the right questions, catches mistakes early, and keeps your project organized from first brainstorm to launch.

## 为什么存在

用 AI 独自做游戏很有威力——但单个聊天会话没有任何结构。没人拦着你硬编码魔法数字、跳过设计文档，或者写出意大利面条式代码。没有 QA 环节，没有设计评审，也没有人问一句“这真的符合游戏愿景吗？”

**Claude Code Game Studios** 通过给你的 AI 会话赋予真实工作室的结构来解决这个问题。你得到的不再是一个通用助手，而是 49 个专业化智能体，按工作室层级组织起来——守护愿景的总监、掌管各自领域的部门主管，以及做具体工作的专员。每个智能体都有明确的职责、上报路径和质量门禁。

结果：你依然做出每一个决定，但现在你拥有一支会提出正确问题、及早发现错误、并从最初头脑风暴到发布全程保持项目有条不紊的团队。

---

## Table of Contents

- [What's Included](#whats-included)
- [Studio Hierarchy](#studio-hierarchy)
- [Slash Commands](#slash-commands)
- [Does it produce games, or documents?](#does-it-produce-games-or-documents)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Upgrading](#upgrading)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Design Philosophy](#design-philosophy)
- [Customization](#customization)
- [Platform Support](#platform-support)
- [Community](#community)
- [Supporting This Project](#supporting-this-project)
- [License](#license)

## 目录

- [包含内容](#whats-included)
- [工作室层级](#studio-hierarchy)
- [斜杠命令](#slash-commands)
- [它产出的是游戏，还是文档？](#does-it-produce-games-or-documents)
- [快速开始](#getting-started)
- [配置](#configuration)
- [升级](#upgrading)
- [项目结构](#project-structure)
- [工作原理](#how-it-works)
- [设计哲学](#design-philosophy)
- [定制](#customization)
- [平台支持](#platform-support)
- [社区](#community)
- [支持本项目](#supporting-this-project)
- [许可证](#license)

---

## What's Included

| Category | Count | Description |
|----------|-------|-------------|
| **Agents** | 49 | Specialized subagents across design, programming, art, audio, narrative, QA, and production |
| **Skills** | 74 | Slash commands for every workflow phase (`/start`, `/design-system`, `/create-epics`, `/create-stories`, `/dev-story`, `/story-done`, etc.) |
| **Hooks** | 15 | Automated validation on commits, pushes, asset changes, design-doc reads, writes and registries, session lifecycle, agent audit trail, and gap detection |
| **Rules** | 14 | Path-scoped coding standards enforced when editing gameplay, engine, AI, UI, network code, scene and asset files, and more |
| **Templates** | 62 | Document templates for GDDs, UX specs, ADRs, sprint plans, HUD design, accessibility, and more |

## 包含内容

| 类别 | 数量 | 说明 |
|----------|-------|-------------|
| **智能体** | 49 | 覆盖设计、程序、美术、音频、叙事、QA 和制作的专业子智能体 |
| **技能** | 74 | 面向每个工作流阶段的斜杠命令（`/start`、`/design-system`、`/create-epics`、`/create-stories`、`/dev-story`、`/story-done` 等） |
| **钩子** | 15 | 在提交、推送、资产变更、设计文档读取、写入与注册表、会话生命周期、智能体审计轨迹和缺口检测上的自动校验 |
| **规则** | 14 | 按路径生效的编码标准，在编辑玩法、引擎、AI、UI、网络代码、场景和资产文件等时强制执行 |
| **模板** | 62 | GDD、UX 规格、ADR、冲刺计划、HUD 设计、无障碍等的文档模板 |

## Studio Hierarchy

Agents are organized into three tiers, matching how real studios operate:

```
Tier 1 — Directors
  creative-director    technical-director    producer

Tier 2 — Department Leads
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

## 工作室层级

智能体分为三个层级，与真实工作室的运作方式一致：

```
Tier 1 — Directors
  creative-director    technical-director    producer

Tier 2 — Department Leads
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

Each agent declares a model in its frontmatter: the three directors ask for
Opus, `lead-programmer` and fifteen specialists name Sonnet, and the remaining thirty
**inherit your session's model**. Treat the tiers as seniority of role, not as
a billing plan — most of the studio runs on whatever model you are already using.

每个智能体都在其 frontmatter 中声明模型：三位总监要求使用
Opus，`lead-programmer` 和十五位专员指定为 Sonnet，其余三十个
**继承你会话所用的模型**。请把这些层级视为角色的资历，而不是
一份计费方案——工作室的大部分都在用你已经在用的那个模型。

### Engine Specialists

The template includes agent sets for all three major engines. Use the set that matches your project:

| Engine | Lead Agent | Sub-Specialists |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript, Shaders, GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS, Shaders/VFX, Addressables, UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS, Blueprints, Replication, UMG/CommonUI |

### 引擎专员

模板为三大引擎都提供了对应的智能体集合。请使用与你的项目匹配的那一套：

| 引擎 | 主智能体 | 子专员 |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript、着色器、GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS、着色器/VFX、Addressables、UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS、蓝图、复制、UMG/CommonUI |

## Slash Commands

Type `/` in Claude Code to access all 74 skills:

**Onboarding & Navigation**
`/start` `/help` `/project-stage-detect` `/setup-engine` `/adopt` `/settings`

**Game Design**
`/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**Art & Assets**
`/art-bible` `/asset-spec` `/asset-audit`

**UX & Interface Design**
`/ux-design` `/ux-review`

**Architecture**
`/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest`

**Stories & Sprints**
`/create-epics` `/create-stories` `/dev-story` `/sprint-plan` `/sprint-status` `/story-readiness` `/story-done` `/estimate`

**Reviews & Analysis**
`/design-review` `/code-review` `/balance-check` `/content-audit` `/scope-check` `/perf-profile` `/tech-debt` `/gate-check` `/consistency-check` `/security-audit`

**QA & Testing**
`/qa-plan` `/smoke-check` `/soak-test` `/regression-suite` `/test-setup` `/test-helpers` `/test-evidence-review` `/test-flakiness` `/skill-test` `/skill-improve`

**Production**
`/milestone-review` `/retrospective` `/bug-report` `/bug-triage` `/reverse-document` `/playtest-report`

**Release**
`/release-checklist` `/launch-checklist` `/changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**Creative & Content**
`/prototype` `/vertical-slice` `/onboard` `/localize`

**Team Orchestration** (coordinate multiple agents on a single feature)
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

## 斜杠命令

在 Claude Code 中输入 `/` 即可访问全部 74 个技能：

**入门与导航**
`/start` `/help` `/project-stage-detect` `/setup-engine` `/adopt` `/settings`

**游戏设计**
`/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**美术与资产**
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
`/prototype` `/vertical-slice` `/onboard` `/localize`

**团队编排**（在单个功能上协调多个智能体）
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

## Does it produce games, or documents?

A fair question, and the answer is a measurement rather than a sample project.
Four games were built from one brief at different `modes.rigor` levels and the
documents each wrote **before its first line of game code** were counted:

| `modes.rigor` | Docs before first line of game code | Time |
|---|---|---:|---:|
| `minimal` | **1** (the one-page brief) | 0 min |
| `standard` | 30 | 58 min |

All of them produced a running, tested game. Two blind reviewers and a human
playtest then ranked the `standard` build **last** — the extra 29 documents
bought traceability, not a better game.

## 它产出的是游戏，还是文档？

这是个公平的问题，而答案是一项测量结果，而不是一个示例项目。
四个游戏由同一份简报在不同 `modes.rigor` 层级下构建，并统计了每个游戏
**在写下第一行游戏代码之前**所写文档的数量：

| `modes.rigor` | 第一行游戏代码之前的文档数 | 时间 |
|---|---|---:|---:|
| `minimal` | **1**（那份一页简报） | 0 分钟 |
| `standard` | 30 | 58 分钟 |

它们全都产出了可运行、经过测试的游戏。随后两位盲审评审和一次人工
试玩把 `standard` 构建排在了**最后**——多出的 29 份文档换来的是可追溯性，
而不是更好的游戏。

### It runs the game and looks at it

The measurement above is about cost. The other half is whether the thing works,
and for a game that means someone has to *look* at it — a passing test says
nothing about a menu drawn off-screen. So a story that changes anything the
player sees is not closed until the game has been launched, observed, and a
screenshot retained in `production/qa/evidence/`. A parse check is not a run.
This holds at every rigor level, including `minimal`, where automated tests are
waived but the look is not.

The games themselves are deliberately **not** shipped here: this is a template
you clone to start your own project, and somebody else's game in your repo is
clutter, not evidence.

### 它会运行游戏并亲眼查看

上面的测量关乎成本。另一半是这东西是否真的能用，而对游戏来说这就意味着
必须有人去*看*它——一个通过的测试并不能说明某个菜单是否被画到了屏幕之外。
因此，任何会改变玩家所见内容的故事，在游戏被启动、观察，且截图被保存在
`production/qa/evidence/` 之前，都不算完成。一次解析检查不等于一次运行。
这在每个严谨度层级都成立，包括 `minimal`——在那里自动化测试被豁免，但亲眼查看不豁免。

游戏本身是刻意**不**随附在此的：这是一个你克隆下来开启自己项目的模板，
而别人家的游戏留在你的仓库里只是杂物，不是证据。

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/)
- [Claude Code](https://code.claude.com/docs/en/setup) — the native installer is recommended (`npm install -g @anthropic-ai/claude-code` also works, on Node.js 22+)
- [Python 3](https://www.python.org/) — reads `project.yaml` for every skill and hook; without it every setting silently falls back to its default
- Bash — runs every hook; built into macOS and Linux, and on Windows it comes with [Git for Windows](https://git-scm.com/downloads/win)
- **Recommended**: [jq](https://jqlang.github.io/jq/) (for hook validation)

Hooks fail gracefully if optional tools are missing — you just lose validation — with one deliberate exception: a commit that stages data JSON is blocked when there is no Python to validate it.

## 快速开始

### 前置要求

- [Git](https://git-scm.com/)
- [Claude Code](https://code.claude.com/docs/en/setup) — 推荐使用原生安装器（`npm install -g @anthropic-ai/claude-code` 同样可行，需 Node.js 22+）
- [Python 3](https://www.python.org/) — 每个技能和钩子都会用它读取 `project.yaml`；没有它，所有设置都会静默回退到默认值
- Bash — 运行每个钩子；macOS 和 Linux 内置，Windows 上则随 [Git for Windows](https://git-scm.com/downloads/win) 提供
- **推荐**：[jq](https://jqlang.github.io/jq/)（用于钩子校验）

如果缺少可选工具，钩子会优雅失败——你只是失去校验——但有一个刻意的例外：当暂存了数据 JSON 却没有 Python 来校验它时，提交会被阻止。

### Setup

1. **Clone or use as template**:
   ```bash
   git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git my-game
   cd my-game
   ```

2. **Open Claude Code in the project's root folder** (the one holding
   `CLAUDE.md` and `project.yaml`) and start a session:
   ```bash
   claude
   ```
   Starting it in a subfolder such as `src/` skips the project's hooks, deny
   rules and ask-first permission mode.

3. **Run `/start`** — the system asks where you are (no idea, vague concept,
   clear design, existing work) and guides you to the right workflow. No assumptions.

   Or jump directly to a specific skill if you already know what you need:
   - `/brainstorm` — explore game ideas from scratch
   - `/setup-engine godot 4.7` — configure your engine if you already know
   - `/project-stage-detect` — analyze an existing project

### 安装步骤

1. **克隆或用作模板**：
   ```bash
   git clone https://github.com/Donchitos/Claude-Code-Game-Studios.git my-game
   cd my-game
   ```

2. **在项目根文件夹中打开 Claude Code**（即包含
   `CLAUDE.md` 和 `project.yaml` 的那个文件夹）并启动一个会话：
   ```bash
   claude
   ```
   在诸如 `src/` 这样的子文件夹中启动，会跳过项目的钩子、拒绝
   规则和先询问的权限模式。

3. **运行 `/start`** —— 系统会询问你处于什么阶段（毫无头绪、模糊构想、
   清晰设计、已有成果）并引导你走向正确的工作流。不做任何假设。

   或者，如果你已经清楚自己需要什么，可以直接跳到某个特定技能：
   - `/brainstorm` —— 从零开始探索游戏创意
   - `/setup-engine godot 4.7` —— 如果你已经确定，直接配置引擎
   - `/project-stage-detect` —— 分析一个现有项目

## Configuration

`project.yaml` at the repo root is the single source of truth for how the
studio behaves on your project — engine, naming conventions, and a `modes`
block that controls how much process every skill enforces. `/start` writes it
for you; you rarely need to hand-edit it.

The one question that matters most is **`modes.rigor`** — `minimal`, `standard`,
or `full`. It's a single front door over six separate knobs (`workflow` —
which GDD sections are required, `docs.density`, `qa.level`,
`story_granularity`, `review_mode` — how many director agents review your work,
and `team.size`), so `/start` asks it once instead of six times:

- **`minimal`** (default) — jam-game speed. No GDDs required, terse docs, minimal QA evidence, solo review. `/start` → `/setup-engine` → `/brainstorm` (a one-page brief) → `/create-stories` → `/dev-story` ↔ `/story-done`.
- **`standard`** — 5 required GDD sections, balanced doc depth, standard QA evidence, lean review.
- **`full`** — all 8 GDD sections, thorough docs, full QA evidence on every story type, full director review.

`minimal` is the default because the heavier tier costs more to reach working
code without producing a better result, and gives nothing back when someone new
picks the project up. Raise it in one `/settings` call when your project grows
— `/help` and `/gate-check` will suggest it when they see the signs.

Two escape hatches keep one setting from being a blunt instrument.
**`system_overrides`** holds a single system to a higher standard than the rest
of the project — your combat system gets the full treatment while everything
else stays light. **`testing.strict`** sets, per test type (logic, integration,
visual, UI, config), whether missing evidence blocks a story or merely warns.

Any of the six underlying knobs can still be set individually if you want a mix
(e.g. `workflow: full` with `docs.density: terse` — comprehensive but compact).
Two of them — `review_mode` (`full` / `lean` / `solo`) and `team.size` — are
also **personal**: rigor sets the team-wide default, but you can override them
per-developer in a gitignored `project.local.yaml` without touching the shared
config. `modes.automation` (how often the AI pauses to ask before it acts) sits
outside rigor and is likewise personally overridable.

View or change any setting with the `/settings` skill:

```
/settings                              # view effective config
/settings modes.review_mode            # view one setting
/settings modes.rigor=full             # write to project.yaml (team-wide)
/settings --local modes.review_mode=solo   # write to project.local.yaml (just you)
```

Full schema and per-setting behavior: `.claude/docs/effects-map.md`.

## 配置

仓库根目录的 `project.yaml` 是工作室在你的项目上如何运作的唯一事实来源——
引擎、命名约定，以及一个 `modes` 区块，用来控制每个技能强制执行多少流程。
`/start` 会替你写好它；你很少需要手动编辑。

最关键的一个问题是 **`modes.rigor`** —— `minimal`、`standard`
或 `full`。它是一个统一入口，统辖六个独立的旋钮（`workflow`——
要求哪些 GDD 章节、`docs.density`、`qa.level`、
`story_granularity`、`review_mode`——有多少总监智能体评审你的工作，
以及 `team.size`），因此 `/start` 只问一次而不是六次：

- **`minimal`**（默认）—— 游戏创作活动（jam）的速度。不要求 GDD，文档简洁，QA 证据最少，单人评审。`/start` → `/setup-engine` → `/brainstorm`（一页简报）→ `/create-stories` → `/dev-story` ↔ `/story-done`。
- **`standard`** —— 要求 5 个 GDD 章节，文档深度均衡，标准 QA 证据，精简评审。
- **`full`** —— 全部 8 个 GDD 章节，详尽文档，每种故事类型都有完整 QA 证据，完整总监评审。

`minimal` 之所以是默认值，是因为较重的层级要花更多成本才能达到可工作的
代码，却没有产出更好的结果，而且在新人接手项目时给不出任何回报。
当你的项目成长时，用一次 `/settings` 调用提升它——`/help` 和 `/gate-check`
在察觉到迹象时会建议你这么做。

两个逃生口避免让单一设置变成一把钝器。
**`system_overrides`** 让单个系统比项目其余部分承受更高标准——你的战斗系统得到
完整待遇，而其他一切保持轻量。**`testing.strict`** 按测试类型（逻辑、集成、
视觉、UI、配置）设定缺失证据是阻止一个故事，还是仅仅警告。

如果你想要混合配置，这六个底层旋钮中的任何一个仍然可以单独设置
（例如 `workflow: full` 配 `docs.density: terse`——全面但紧凑）。
其中两个——`review_mode`（`full` / `lean` / `solo`）和 `team.size`——
还是**个人化**的：严谨度设定团队范围的默认值，但你可以在被 git 忽略的
`project.local.yaml` 中按开发者覆盖它们，而不触碰共享配置。
`modes.automation`（AI 行动前暂停询问的频率）位于严谨度之外，同样可以个人覆盖。

用 `/settings` 技能查看或修改任何设置：

```
/settings                              # view effective config
/settings modes.review_mode            # view one setting
/settings modes.rigor=full             # write to project.yaml (team-wide)
/settings --local modes.review_mode=solo   # write to project.local.yaml (just you)
```

完整 schema 与各项设置的行为：`.claude/docs/effects-map.md`。

## Upgrading

Already using an older version of this template? See [UPGRADING.md](UPGRADING.md)
for step-by-step migration instructions, a breakdown of what changed between
versions, and which files are safe to overwrite vs. which need a manual merge.

## 升级

已经在使用这个模板的旧版本？参见 [UPGRADING.md](UPGRADING.md)
获取分步迁移说明、各版本之间变更的分解，以及哪些文件可以安全覆盖、
哪些需要手动合并。

## Project Structure

```
CLAUDE.md                           # Master configuration
.claude/
  settings.json                     # Hooks, permissions, safety rules
  agents/                           # 49 agent definitions (markdown + YAML frontmatter)
  skills/                           # 74 slash commands (subdirectory per skill)
  hooks/                            # 18 scripts (bash) — 15 event hooks, two helpers they
                                    #   source (yaml-helper.sh, update-check.sh), and one
                                    #   opt-in diagnostic you wire yourself
  rules/                            # 14 path-scoped coding standards
  statusline.sh                     # Status line script (context%, model, stage, epic breadcrumb)
  docs/
    workflow-catalog.yaml           # 7-phase pipeline definition (read by /help)
    templates/                      # 62 document templates (+ per-section guidance)
src/                                # Game source code (Godot). The code root is
                                    #   ENGINE-SPECIFIC: Unity compiles only
                                    #   Assets/, Unreal builds from Source/<Module>/
assets/                             # Art, audio, VFX, shaders, data files
design/                             # GDDs, narrative docs, level designs
docs/                               # Technical documentation and ADRs
tests/                              # Test suites (unit, integration, performance, playtest)
tools/                              # Build and pipeline tools
prototypes/                         # Throwaway prototypes (isolated from src/)
production/                         # Sprint plans, milestones, release tracking
studio-tests/                       # QA for the skills and agents themselves — see below
```

## 项目结构

```
CLAUDE.md                           # 主配置
.claude/
  settings.json                     # 钩子、权限、安全规则
  agents/                           # 49 个智能体定义（markdown + YAML frontmatter）
  skills/                           # 74 个斜杠命令（每个技能一个子目录）
  hooks/                            # 18 个脚本（bash）——15 个事件钩子、它们
                                    #   引用的两个辅助脚本（yaml-helper.sh、update-check.sh），
                                    #   以及一个你需要自行接线的可选诊断脚本
  rules/                            # 14 个按路径生效的编码标准
  statusline.sh                     # 状态行脚本（上下文占比、模型、阶段、史诗面包屑）
  docs/
    workflow-catalog.yaml           # 7 阶段流水线定义（由 /help 读取）
    templates/                      # 62 个文档模板（+ 逐节指引）
src/                                # 游戏源代码（Godot）。代码根目录
                                    #   与引擎相关：Unity 只编译
                                    #   Assets/，Unreal 从 Source/<Module>/ 构建
assets/                             # 美术、音频、VFX、着色器、数据文件
design/                             # GDD、叙事文档、关卡设计
docs/                               # 技术文档和 ADR
tests/                              # 测试套件（单元、集成、性能、试玩）
tools/                              # 构建和流水线工具
prototypes/                         # 一次性原型（与 src/ 隔离）
production/                         # 冲刺计划、里程碑、发布跟踪
studio-tests/                       # 针对技能和智能体本身的 QA——见下文
```

### Testing your customizations

CCGS is a template you are meant to edit. `studio-tests/` is how
you check that an edited or newly written skill still holds up — a catalog of all
74 skills and 49 agents, per-category quality rubrics, behavioral specs, and
templates for writing specs of your own.

```
/skill-test static [name]     # structural linter — 7 compliance checks
/skill-test category [name]   # category-specific quality rubric
/skill-test spec [name]       # behavioral spec assertions
/skill-test audit             # coverage report across skills and agents
/skill-improve [name]         # test-fix-retest loop; keeps or reverts on score change
```

It tests the *framework*, never your game — game tests live in `tests/`.

### 测试你的定制

CCGS 是一个本就供你编辑的模板。`studio-tests/` 让你检查一个被编辑过或
新写的技能是否依然站得住脚——一份涵盖全部 74 个技能和 49 个智能体的目录、
按类别划分的质量评分标准、行为规格，以及用来编写你自己规格的模板。

```
/skill-test static [name]     # structural linter — 7 compliance checks
/skill-test category [name]   # category-specific quality rubric
/skill-test spec [name]       # behavioral spec assertions
/skill-test audit             # coverage report across skills and agents
/skill-improve [name]         # test-fix-retest loop; keeps or reverts on score change
```

它测试的是*框架*，从不测试你的游戏——游戏测试位于 `tests/`。

## How It Works

### Agent Coordination

Agents follow a structured delegation model:

1. **Vertical delegation** — directors delegate to leads, leads delegate to specialists
2. **Horizontal consultation** — same-tier agents can consult each other but can't make binding cross-domain decisions
3. **Conflict resolution** — disagreements escalate up to the shared parent (`creative-director` for design, `technical-director` for technical)
4. **Change propagation** — cross-department changes are coordinated by `producer`
5. **Domain boundaries** — agents don't modify files outside their domain without explicit delegation

## 工作原理

### 智能体协调

智能体遵循结构化的委派模型：

1. **纵向委派** —— 总监委派给主管，主管委派给专员
2. **横向咨询** —— 同层级的智能体可以互相咨询，但不能做出有约束力的跨领域决定
3. **冲突解决** —— 分歧逐级上报至共同的上级（设计方面为 `creative-director`，技术方面为 `technical-director`）
4. **变更传播** —— 跨部门的变更由 `producer` 协调
5. **领域边界** —— 未经明确委派，智能体不修改其领域之外的文件

### Collaborative, Not Autonomous

This is **not** an auto-pilot system. Every agent follows a strict collaboration protocol:

1. **Ask** — agents ask questions before proposing solutions
2. **Present options** — agents show 2-4 options with pros/cons
3. **You decide** — the user always makes the call
4. **Draft** — agents show work before finalizing
5. **Approve** — nothing gets written without your sign-off

You stay in control. The agents provide structure and expertise, not autonomy.

That is how a terminal session started at the project root behaves out of the
box. The `guided` and `autonomous` automation settings, and Claude Code's own
auto mode, trade some of these prompts for speed; see
[setup-requirements.md](.claude/docs/setup-requirements.md) for the routes into
auto mode.

### 协作，而非自主

这**不是**一个自动驾驶系统。每个智能体都遵循严格的协作协议：

1. **询问** —— 智能体在提出方案前先提问
2. **呈现选项** —— 智能体给出 2-4 个选项，附利弊
3. **你来决定** —— 用户始终拍板
4. **草稿** —— 智能体在定稿前展示成果
5. **批准** —— 未经你签字同意，什么都不会被写入

控制权始终在你手上。智能体提供的是结构和专业能力，而不是自主权。

在项目根目录启动的终端会话，开箱即是如此行为。
`guided` 和 `autonomous` 自动化设置，以及 Claude Code 自身的
自动模式，会用其中一部分提示换取速度；关于进入
自动模式的路径，请参见 [setup-requirements.md](.claude/docs/setup-requirements.md)。

### Automated Safety

**Hooks** run automatically on every session:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| `validate-commit.sh` | PreToolUse (Bash, PowerShell) | Checks for hardcoded values, TODO format, JSON validity, design doc sections — exits early if the command is not `git commit` |
| `validate-push.sh` | PreToolUse (Bash, PowerShell) | Warns on pushes to protected branches, and on `git tag`, `git merge`, `gh release`, `butler push` and `steamcmd +run_app_build` — exits early for any other command |
| `validate-read.sh` | PreToolUse (Read) | Refuses a whole-file read of a design doc over 40 KB and answers with its headings, so the retry reads one section (`features.read_guard`) |
| `validate-write.sh` | PreToolUse (Write/Edit) | Warns, never blocks, when a write would break a rule the skills state: a file they never overwrite, the config guard, the prototype boundary, a localization freeze |
| `validate-registry.sh` | PreToolUse (Write/Edit) | Warns when a write to the entity or TR-ID registry would delete or renumber an entry, or set a status its header does not list |
| `validate-assets.sh` | PostToolUse (Write/Edit) | Checks data-file JSON under `assets/`, `Assets/` or `Content/`, and asset naming in Godot's `assets/` only — exits early if the file is under none of them |
| `session-start.sh` | Session open | Shows current branch and recent commits for orientation |
| `detect-gaps.sh` | Session open | Detects fresh projects (suggests `/start`) and missing design docs when code or prototypes exist |
| `pre-compact.sh` | Before compaction | Logs the compaction (its output does not reach Claude — `session-start.sh` restores context afterwards) |
| `notify.sh` | Permission prompt, or idle about a minute | Shows Windows toast notification via PowerShell |
| `session-stop.sh` | Every response end, in the background | Archives `active.md` to session log and records git activity |
| `log-agent.sh` | Agent spawned | Audit trail start — logs subagent invocation |
| `log-agent-stop.sh` | Agent stops | Audit trail stop — completes subagent record |
| `validate-agent-artifact.sh` | Agent stops | Warns when a subagent stops without writing the file its brief named |
| `validate-skill-change.sh` | PostToolUse (Write/Edit) | Advises running `/skill-test` after any `.claude/skills/` change |

### 自动安全

**钩子**在每个会话中自动运行：

| 钩子 | 触发时机 | 作用 |
|------|---------|--------------|
| `validate-commit.sh` | PreToolUse（Bash、PowerShell） | 检查硬编码值、TODO 格式、JSON 有效性、设计文档章节——若命令不是 `git commit` 则提前退出 |
| `validate-push.sh` | PreToolUse（Bash、PowerShell） | 对推送到受保护分支、以及 `git tag`、`git merge`、`gh release`、`butler push` 和 `steamcmd +run_app_build` 发出警告——对其他任何命令提前退出 |
| `validate-read.sh` | PreToolUse（Read） | 拒绝整文件读取超过 40 KB 的设计文档，并以文档标题作答，好让重试只读一个章节（`features.read_guard`） |
| `validate-write.sh` | PreToolUse（Write/Edit） | 当一次写入会破坏技能规定的规则时发出警告，从不阻止：技能从不覆盖的文件、配置守卫、原型边界、本地化冻结 |
| `validate-registry.sh` | PreToolUse（Write/Edit） | 当对实体或 TR-ID 注册表的写入会删除或重新编号某个条目，或设置其头部未列出的状态时发出警告 |
| `validate-assets.sh` | PostToolUse（Write/Edit） | 检查 `assets/`、`Assets/` 或 `Content/` 下的数据文件 JSON，以及仅限 Godot 的 `assets/` 中的资产命名——若文件不位于其中任何一处则提前退出 |
| `session-start.sh` | 会话打开 | 显示当前分支和最近的提交，以便定位 |
| `detect-gaps.sh` | 会话打开 | 检测全新项目（建议 `/start`），以及当代码或原型已存在时缺失的设计文档 |
| `pre-compact.sh` | 压缩之前 | 记录压缩（其输出不会到达 Claude——`session-start.sh` 随后恢复上下文） |
| `notify.sh` | 权限提示，或闲置约一分钟 | 通过 PowerShell 显示 Windows 吐司通知 |
| `session-stop.sh` | 每次响应结束时，在后台 | 将 `active.md` 归档到会话日志并记录 git 活动 |
| `log-agent.sh` | 智能体被启动 | 审计轨迹开始——记录子智能体调用 |
| `log-agent-stop.sh` | 智能体停止 | 审计轨迹结束——补全子智能体记录 |
| `validate-agent-artifact.sh` | 智能体停止 | 当子智能体停止却未写出其任务简报所指明的文件时发出警告 |
| `validate-skill-change.sh` | PostToolUse（Write/Edit） | 在任何 `.claude/skills/` 变更后建议运行 `/skill-test` |

> **Note**: `validate-commit.sh`, `validate-push.sh`, `validate-read.sh`, `validate-write.sh`, `validate-registry.sh`, `validate-assets.sh` and `validate-skill-change.sh` fire on every Bash, PowerShell, Read, Write or Edit tool call and exit immediately (exit 0) when the command or file path is not relevant. This is normal hook behavior — not a performance concern.

> **注意**：`validate-commit.sh`、`validate-push.sh`、`validate-read.sh`、`validate-write.sh`、`validate-registry.sh`、`validate-assets.sh` 和 `validate-skill-change.sh` 会在每次 Bash、PowerShell、Read、Write 或 Edit 工具调用时触发，并在命令或文件路径不相关时立即退出（exit 0）。这是正常的钩子行为——不必担心性能。

**Permission rules** in `settings.json` auto-allow test runs and block dangerous operations (force push, `rm -rf`, reading `.env` files) in both the Bash and PowerShell tools. Read-only commands such as `git status`, `git log` and `ls` need no rule: Claude Code runs them without asking. The `git` rules match anywhere after `git`, so a git command whose text only mentions `push` followed later by ` +` or ` -f`, `clean` followed by ` -f`, or `reset` followed by `--hard` — a commit message such as `git commit -m "push + pull"` included — is denied too: reword the message.

`settings.json` 中的**权限规则**会自动允许测试运行，并在 Bash 和 PowerShell 两种工具中阻止危险操作（强制推送、`rm -rf`、读取 `.env` 文件）。像 `git status`、`git log` 和 `ls` 这样的只读命令无需规则：Claude Code 会不经询问直接运行它们。`git` 规则会在 `git` 之后的任意位置匹配，因此一条 git 命令的文本只要提到 `push` 且后面跟着 ` +` 或 ` -f`、`clean` 且后面跟着 ` -f`，或 `reset` 且后面跟着 `--hard`——包括诸如 `git commit -m "push + pull"` 这样的提交信息——也会被拒绝：请改写该信息。

### Path-Scoped Rules

Coding standards are automatically enforced based on file location. The paths
below are Godot's. Each rule also matches the Unity and Unreal layouts: the code
rules match C# under `Assets/**/Gameplay/` and C++ under `Source/**/Gameplay/` (and `Core`,
`AI`, `Networking`, `UI`), data matches JSON under `Assets/**/Data/` and
`Content/**/Data/`, shaders match by file type, and tests match
C# under `Assets/Tests/` and C++ under `Source/**/Tests/`.

| Path | Enforces |
|------|----------|
| `src/gameplay/**` | Data-driven values, delta time usage, no UI references |
| `src/core/**` | Zero allocations in hot paths, thread safety, API stability |
| `src/ai/**` | Performance budgets, debuggability, data-driven parameters |
| `src/networking/**` | Server-authoritative, versioned messages, security |
| `src/ui/**` | No game state ownership, localization-ready, accessibility |
| `design/gdd/**` | Required sections per `modes.workflow`, formula format, edge cases |
| `design/narrative/**` | Lore consistency, character voice, canon levels |
| `assets/data/**/*.json` | JSON validity, naming conventions, schema rules |
| `assets/shaders/**` | Naming conventions, performance targets, cross-platform rules |
| `**/*.tscn`, `**/*.tres` | Scene and resource files changed in the editor where possible; safe hand-edit rules |
| `tests/**` | Test naming, coverage requirements, fixture patterns |
| `prototypes/**` | Relaxed standards, README required, hypothesis documented |

### 按路径生效的规则

编码标准会根据文件位置自动强制执行。下面的路径是 Godot 的。每条规则也匹配
Unity 和 Unreal 的布局：代码规则匹配 `Assets/**/Gameplay/` 下的 C# 和
`Source/**/Gameplay/` 下的 C++（以及 `Core`、`AI`、`Networking`、`UI`），
数据匹配 `Assets/**/Data/` 和 `Content/**/Data/` 下的 JSON，着色器按文件类型匹配，
测试匹配 `Assets/Tests/` 下的 C# 和 `Source/**/Tests/` 下的 C++。

| 路径 | 强制内容 |
|------|----------|
| `src/gameplay/**` | 数据驱动的值、delta time 用法、不引用 UI |
| `src/core/**` | 热路径零分配、线程安全、API 稳定性 |
| `src/ai/**` | 性能预算、可调试性、数据驱动参数 |
| `src/networking/**` | 服务器权威、带版本的消息、安全性 |
| `src/ui/**` | 不持有游戏状态、本地化就绪、无障碍 |
| `design/gdd/**` | 按 `modes.workflow` 的必填章节、公式格式、边界情况 |
| `design/narrative/**` | 设定一致性、角色口吻、正典层级 |
| `assets/data/**/*.json` | JSON 有效性、命名约定、schema 规则 |
| `assets/shaders/**` | 命名约定、性能目标、跨平台规则 |
| `**/*.tscn`, `**/*.tres` | 尽可能在编辑器中修改场景和资源文件；手工编辑的安全规则 |
| `tests/**` | 测试命名、覆盖要求、fixture 模式 |
| `prototypes/**` | 放宽的标准、必须提供 README、记录假设 |

## Design Philosophy

This template is grounded in professional game development practices:

- **MDA Framework** — Mechanics, Dynamics, Aesthetics analysis for game design
- **Self-Determination Theory** — Autonomy, Competence, Relatedness for player motivation
- **Flow State Design** — Challenge-skill balance for player engagement
- **Bartle Player Types** — Audience targeting and validation
- **Verification-Driven Development** — Tests first, then implementation

## 设计哲学

本模板扎根于专业游戏开发实践：

- **MDA 框架** —— 用于游戏设计的机制（Mechanics）、动态（Dynamics）、美学（Aesthetics）分析
- **自我决定理论** —— 玩家的自主性、胜任感、归属感
- **心流设计** —— 挑战与技能的平衡，以提升玩家参与度
- **Bartle 玩家类型** —— 受众定位与验证
- **验证驱动开发** —— 先测试，再实现

## Customization

This is a **template**, not a locked framework. Everything is meant to be customized:

- **Add/remove agents** — delete agent files you don't need, add new ones for your domains
- **Edit agent prompts** — tune agent behavior, add project-specific knowledge
- **Modify skills** — adjust workflows to match your team's process
- **Add rules** — create new path-scoped rules for your project's directory structure
- **Tune hooks** — adjust validation strictness, add new checks
- **Pick your engine** — use the Godot, Unity, or Unreal agent set (or none)
- **Tune process weight** — `modes.rigor` and its underlying knobs in `project.yaml` (see [Configuration](#configuration)). Override per-run with `--review solo` on any skill.

## 定制

这是一个**模板**，不是锁死的框架。一切都是为了被定制：

- **增删智能体** —— 删除你不需要的智能体文件，为你的领域添加新的
- **编辑智能体提示词** —— 调整智能体行为，添加项目专属知识
- **修改技能** —— 调整工作流以匹配你团队的流程
- **添加规则** —— 为你的项目目录结构创建新的按路径生效的规则
- **调节钩子** —— 调整校验严格度，添加新的检查
- **选择你的引擎** —— 使用 Godot、Unity 或 Unreal 智能体集（或都不用）
- **调节流程重量** —— `project.yaml` 中的 `modes.rigor` 及其底层旋钮（参见[配置](#configuration)）。可在任何技能上用 `--review solo` 按单次运行覆盖。

## Platform Support

Primary development on **Windows 10** with Git Bash. The hooks and scripts are also tested on **macOS** — its stock bash 3.2 and BSD tools, with and without `jq` — and on **Linux**. All hooks use POSIX-compatible patterns (`grep -E`, not `grep -P`) and include fallbacks for missing tools. The `notify.sh` hook uses PowerShell for Windows toast notifications and is a no-op elsewhere — desktop notifications on macOS/Linux are not yet wired. Please file issues for any platform-specific breakage.

## 平台支持

主要开发环境为 **Windows 10** 配 Git Bash。钩子和脚本也在 **macOS**（其自带的 bash 3.2 和 BSD 工具，有无 `jq` 均测）和 **Linux** 上测试过。所有钩子都使用 POSIX 兼容模式（`grep -E`，而非 `grep -P`），并为缺失的工具提供了回退方案。`notify.sh` 钩子使用 PowerShell 发送 Windows 吐司通知，在其他平台上是空操作——macOS/Linux 的桌面通知尚未接通。请针对任何平台特有的故障提交 issue。

## Community

- **Discussions** — [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) for questions, ideas, and showcasing what you've built
- **Issues** — [Bug reports and feature requests](https://github.com/Donchitos/Claude-Code-Game-Studios/issues)

## 社区

- **讨论区** —— [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) 用于提问、交流想法和展示你的作品
- **Issues** —— [缺陷报告和功能请求](https://github.com/Donchitos/Claude-Code-Game-Studios/issues)

---

## Supporting This Project

Claude Code Game Studios is free and open source. If it saves you time or helps you ship your game, consider supporting continued development:

<p>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee"></a>
  &nbsp;
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

- **[Buy Me a Coffee](https://www.buymeacoffee.com/donchitos3)** — one-time support
- **[GitHub Sponsors](https://github.com/sponsors/Donchitos)** — recurring support through GitHub

Sponsorships help fund time spent maintaining skills, adding new agents, keeping up with Claude Code and engine API changes, and responding to community issues.

## 支持本项目

Claude Code Game Studios 免费且开源。如果它为你节省了时间，或帮助你发布了游戏，请考虑支持持续开发：

<p>
  <a href="https://www.buymeacoffee.com/donchitos3"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee"></a>
  &nbsp;
  <a href="https://github.com/sponsors/Donchitos"><img src="https://img.shields.io/badge/GitHub%20Sponsors-ea4aaa?style=for-the-badge&logo=githubsponsors&logoColor=white" alt="GitHub Sponsors"></a>
</p>

- **[Buy Me a Coffee](https://www.buymeacoffee.com/donchitos3)** —— 一次性支持
- **[GitHub Sponsors](https://github.com/sponsors/Donchitos)** —— 通过 GitHub 的定期支持

赞助有助于资助维护技能、添加新智能体、跟进 Claude Code 和引擎 API 变化，以及回应社区问题所投入的时间。

---

*Built for Claude Code. Maintained and extended — contributions welcome via [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions).*

*为 Claude Code 而构建。持续维护与扩展——欢迎通过 [GitHub Discussions](https://github.com/Donchitos/Claude-Code-Game-Studios/discussions) 贡献。*

## License

MIT License. See [LICENSE](LICENSE) for details.

## 许可证

MIT 许可证。详情请参见 [LICENSE](LICENSE)。
