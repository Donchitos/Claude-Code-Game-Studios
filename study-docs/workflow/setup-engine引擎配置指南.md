# setup-engine 引擎配置指南

`/setup-engine` 是整个项目的**技术底座入口**。它不是"帮你选个引擎"这么简单——它把一个项目"这个游戏用什么引擎、怎么写代码、遵守哪些规矩"这些**硬约束**写成一组规范文档，让后续所有 skill 和 agent 读同一份配置。配置错了，后面所有技能的输出都会漂。

这一篇拆解它改什么、为什么要改、三种引擎各生成什么、移植到新项目怎么做。

---

## 这个 skill 到底干什么

一句话：**把引擎选择和项目级技术决策固化成一组后续所有技能都读的配置文件。**

你敲 `/setup-engine godot 4.7`，它不会帮你在 Godot Hub 里装编辑器（那是你自己干的），但它会帮你：

- 在 `CLAUDE.md` 里锁定引擎版本和技术栈
- 写一份 `.claude/docs/technical-preferences.md`——后续 `/dev-story`、`/architecture-decision`、`/code-review` 都读它来决定"这个引擎怎么写"
- 写 `project.yaml`（主配置存储）——结构化 YAML，skill 和 hook 都能程序化读取
- 写 `docs/engine-reference/<引擎>/`——因为 **LLM 的训练数据往往落后于当前引擎版本**，这是运行时知识补全
- （仅 Godot）生成 `project.godot`——让引擎编辑器能打开这个项目

**它不做的事**：不写游戏代码、不生成资产、不帮你理解引擎 API 细节——那些是后续 skill 和 agent 在运行时做的。它只负责**把"这个项目的技术基线"钉死**。

---

## 会修改/创建哪些文件

先搞清楚：这个仓库里**其实有两个版本的 setup-engine**，输出不一样。我会分别说清楚。

### 版本 1：通用版（主 workspace）—— 多引擎可选

来自 [.claude/skills/setup-engine/SKILL.md](file:///workspace/.claude/skills/setup-engine/SKILL.md)，references 拆在 12 个子文件里。这是最完整的版本，支持 Godot / Unity / Unreal 三种引擎。

| 序号 | 文件 | 写入方式 | 写什么 | 谁读它 |
|------|------|----------|--------|--------|
| 1 | `CLAUDE.md` | Edit | Technology Stack 段（替换 `[CHOOSE]` 占位符） | Claude Code 启动时自动加载 |
| 2 | `.claude/docs/technical-preferences.md` | Write / Edit | 引擎名、语言、构建系统、命名惯例、平台目标、性能预算、测试框架、引擎 specialist 路由表 | `/dev-story`、`/architecture-decision`、`/code-review`、所有 engine 相关 agent |
| 3 | `project.yaml` | Write / Edit | `engine`、`specialists`、`naming`、`commands` 四个 YAML block | 所有 skill 和 hook，通过 `yaml-helper.sh` 程序化读取 |
| 4 | `docs/engine-reference/<engine>/VERSION.md` | Write / Edit | 引擎版本、发布日期、LLM 知识截止点、风险等级、安装版本缺口 | 所有 engine agent，判断"哪些 API 训练数据里可能不知道" |
| 5 | `docs/engine-reference/<engine>/breaking-changes.md` | Write | 训练数据之后的版本间破坏性变更 | `/architecture-decision`、`/code-review`、所有 engine agent |
| 6 | `docs/engine-reference/<engine>/deprecated-apis.md` | Write | "别用 X → 改用 Y" 对照表 | 同上 |
| 7 | `docs/engine-reference/<engine>/current-best-practices.md` | Write | 训练数据之后引入的新实践 | 同上 |
| 8 | `docs/engine-reference/<engine>/modules/*.md` | Write（按需） | 渲染、物理、网络、输入、UI 等子系统的深入参考 | engine specialist agent |
| 9 | `.claude/agents/<engine>-*-specialist.md` | Edit（追加） | 追加 "Version Awareness" 段 | agent 自己读 |
| 10 | `project.godot`（仅 Godot） | Write | 项目配置文件（config_version、渲染器、特性串） | Godot 编辑器，让它能打开这个项目 |

### 版本 2：UE 5.8 轻量版（tech-team/version1）—— 引擎钉死

来自 [study-docs/tech-team/version1/.claude/skills/setup-engine/SKILL.md](file:///workspace/study-docs/tech-team/version1/.claude/skills/setup-engine/SKILL.md)。这个版本把引擎钉死 UE 5.8，知识源钉死 Context7 MCP（运行时查询），所以不需要维护静态的 `docs/engine-reference/` 目录。

| 文件 | 写什么 | 和通用版的差异 |
|------|--------|----------------|
| `CLAUDE.md` | Technology Stack | 相同 |
| `.claude/docs/technical-preferences.md` | 引擎配置合同 | 额外要求"每个 agent 输出标注 API 验证出处" |
| `.claude/docs/engine-specialists.md` | UE 子专家路由表 | **独立文件**（通用版合并在 technical-preferences.md 里） |

**关键差异**：轻量版**不创建** `project.yaml`、`docs/engine-reference/` 目录、`project.godot`。因为 Context7 MCP 运行时就能查 UE API，不需要静态维护版本参考。

**为什么有两个版本**？通用版是"从零选引擎"的入口；轻量版是"团队已经钉死 UE 5.8，只需要配置项目参数"的入口。后者的流程被砍掉了：不需要 WebSearch 查引擎版本（已经知道是 5.8），不需要生成 engine-reference（Context7 实时查），不需要 scaffold（UE 项目必须编辑器生成）。

---

## 每个输出文件的作用与重要性

逐个解释。这一节是"为什么这些文件这么重要"——每个都是一个**契约**，错了后续技能就会漂。

### 1. `CLAUDE.md` — 项目技术栈声明

**为什么重要**：Claude Code 启动时第一件事就是读它。里面的 Technology Stack 段决定了 AI 的初始假设——它知道"这是 Godot 项目，不是 Unity"，就不会给你生成 `.cs` 文件或写 Unity API。

**setup-engine 具体改什么**：把 `[CHOOSE: Godot 4 / Unity / Unreal Engine 5]` 这类占位符替换成实际值。不同引擎的模板见 [references/godot-language-config.md](file:///workspace/.claude/skills/setup-engine/references/godot-language-config.md) 的 A1 段。

**迁移时注意**：技术栈一旦定下，**后续所有 skill 都默认这个值**。改引擎是重跑 `/setup-engine upgrade`，不是手动改 CLAUDE.md。

### 2. `.claude/docs/technical-preferences.md` — 引擎配置合同（Markdown 版）

**为什么重要**：这是**后续所有"写代码/审查代码"类 skill 的必读文件**。`/dev-story` 写代码时看命名惯例；`/architecture-decision` 选技术方案时看允许哪些库；`/code-review` 检查时看禁止哪些模式。它就是这个项目的"开发规矩"。

**内容结构**（简化）：

```markdown
# Technical Preferences

> **Engine**: [引擎版本]
> **Knowledge Source**: [训练数据还是运行时 MCP]
> **Last Updated**: [日期]

## Naming Conventions        # 类/变量/函数/文件怎么命名
## Input & Platform          # 目标平台、输入方式、性能要求
## Performance Budgets       # 帧率、帧预算、Draw Call 上限、内存上限
## Testing                   # 用什么测试框架
## Forbidden Patterns        # 禁止哪些反模式（留空，后面由 control-manifest 填）
## Allowed Libraries         # 允许哪些第三方库（留空，集成时再填）
## Engine Specialists        # 子专家路由表（哪个文件改派哪个 agent）
```

### 3. `project.yaml` — 主配置存储（YAML 版，v1.1 引入）

**为什么重要**：`technical-preferences.md` 是 Markdown 给人读；`project.yaml` 是 **结构化 YAML 给程序读**。所有 skill 和 hook 都通过 `yaml-helper.sh` 解析它——比如 `/dev-story` 读 `project.yaml.commands.test` 来决定怎么跑测试；`/smoke-check` 读 `commands.build` 来决定怎么构建；`/settings` 直接改这个文件。

**配置优先级**：`project.yaml` > `technical-preferences.md`。如果两处都有同一个配置，以 `project.yaml` 为准。skill 每次写 engine 配置都是**双写**——同一个值写两份，然后验证两边一致。

**四个 block 的作用**：

```yaml
engine:          # 引擎元数据
  name: Godot
  version: 4.7
  language: GDScript
  rendering: Forward+      # Godot 是 2D/3D · web/非web 决定；Unreal 固定 Lumen + Nanite
  physics: Jolt            # Godot 是 Jolt（3D）/Godot Physics 2D（2D）；Unity 固定 PhysX

specialists:     # 子专家路由表——哪个 engine 选哪个 agent 组合
  code: godot-gdscript-specialist
  shader: godot-shader-specialist
  ui: godot-specialist
  additional: [godot-gdextension-specialist]

naming:          # 枚举值，给程序读（不是 prose 形式）
  classes: PascalCase
  variables: snake_case     # 三种引擎完全不一样！
  constants: SCREAMING_SNAKE
  signals: past_tense
  files: snake_case
  scenes: snake_case

commands:        # 构建/测试/运行/冒烟 四条 shell 命令
  build: ...     # Godot/Unity 必须问用户 export preset / build target，不能硬编
  test: ...
  run: ...
  smoke: ...
```

**一个容易忽略的设计细节**：`commands.build` 在 Godot 和 Unity 上**必须问用户**。Godot 的导出 preset 名（如 `Windows Desktop`、`Linux/X11`）是**项目自己定义的**，写死 `'Linux/X11'` 给一个 Windows 项目就是错的。Unity 的 `-buildTarget` 同理——硬编 `StandaloneLinux64` 等于给每个 Unity 项目一个 Linux 构建命令，不管它实际发行哪个平台。skill 里原话："A wrong-but-plausible default is worse than an explicit question"。

### 4. `docs/engine-reference/<engine>/` — LLM 知识补全目录

**为什么重要**：**LLM 的训练数据普遍落后于引擎最新版本**。比如这个仓库的 LLM 知识截止点是 2025 年 5 月，而当前 pin 的 Godot 4.7 是 2026 年 6 月才发布的。让 AI 只靠训练数据写 Godot 4.7 代码，等于让它猜——大概率错。

**这个目录的使命**：**成为 agent 运行时查的东西，而不是让它靠记忆猜**。SKILL.md 里的 sourcing rule 是铁律：

> "Never fill a gap from training data. Write the gap down instead."
> （永远不要用训练数据填补空白。宁可把空白写下来。）

一个典型目录结构：

```
docs/engine-reference/godot/
├── VERSION.md                     # 版本锁 + 知识缺口分析 + 安装版本缺口
├── breaking-changes.md            # 每个版本跨度的破坏性变更（只 append，不截断）
├── deprecated-apis.md              # "别用 X → 改用 Y" 对照表
├── current-best-practices.md      # 训练数据之后引入的新实践
└── modules/                       # 按需创建
    ├── physics.md                 # 物理子系统（Godot 是 Jolt）
    ├── networking.md              # 网络
    ├── rendering.md               # 渲染
    ├── input.md                   # 输入
    ├── ui.md                      # UI
    ├── audio.md                   # 音频
    ├── animation.md               # 动画
    └── navigation.md              # 导航
```

**每个文件都要写 `Last verified: [日期]`**——因为引擎 API 在变，agent 需要知道"这份参考资料是什么时候查的官方文档"。

**两种来源模式**（取决于风险等级）：

| 风险 | 判断 | 参考文件 |
|------|------|----------|
| LOW | 版本在训练数据截止之前 | 只写一个最小化的 `VERSION.md`，说"可选，以后有问题再补" |
| MEDIUM/HIGH | 版本在训练数据之后 | 跑完整的 WebSearch + WebFetch，创建 full 目录 |

### 5. `.claude/agents/<engine>-*-specialist.md` — 追加 Version Awareness 段

**为什么重要**：每个 engine specialist agent 都需要知道"我服务的项目引擎是什么版本，哪些 API 可能训练数据里没有"。skill 会给缺失的 agent 追加一段：

```markdown
## Version Awareness

- Read `docs/engine-reference/<engine>/VERSION.md` at the start of every session
- Check deprecated APIs before suggesting code
- Check breaking changes for relevant version transitions
- Use WebSearch to verify uncertain APIs — never rely on training data alone
```

**迁移时**：如果你在新项目里用 setup-engine，它会自动补这段。

---

## 三种引擎的设置结果对比

现在直接上对比表，然后讲每个引擎的结果亮点。

### 全景对比

| 维度 | Godot | Unity | Unreal |
|------|-------|-------|--------|
| **语言** | GDScript / C# / Both（三选一） | C#（主） | C++ + Blueprint（主） |
| **渲染默认** | Forward+（3D 非 web）/ Compatibility（2D 或 web） | URP | Lumen + Nanite（deferred） |
| **物理默认** | Jolt（3D）/ Godot Physics 2D（2D） | PhysX | Chaos |
| **命名惯例（变量）** | snake_case | _camelCase（私有） | **PascalCase**（一切） |
| **命名惯例（信号）** | snake_case 过去式 | `On<Event>` PascalCase | `On<Event>` PascalCase（不是 Godot 信号，是 UE 委托） |
| **类命名** | PascalCase | PascalCase | PascalCase + 类型前缀（A/U/F/E/I/S） |
| **项目文件** | `project.godot`（纯文本，skill 可创建） | 编辑器生成，多文件，含二进制 | 编辑器生成，`.uproject` + 二进制 |
| **脚手架能力** | ✅ skill 可创建 + 用 `godot --headless --path . --import` 验证 | ❌ 必须 Unity Hub 创建 | ❌ 必须 Epic Launcher 创建 |
| **测试框架** | gdUnit4（Headless 命令跑） | NUnit + Unity Test Framework（Editor batchmode） | Unreal Automation System |
| **构建命令** | 问用户 export preset 名（不能硬编） | 问用户 `-buildTarget` 和 `-build<PLATFORM>Player` | 自动生成 Windows/Linux/macOS 三行，标注 TODO 让用户确认 |
| **命令路径处理** | 编辑器可能不在 PATH（Windows/macOS），必须写完整路径 | 同 Godot | 同 Godot（UE 编辑器更不可能在 PATH） |
| **engine specialist 组合** | godot-specialist + gdscript/csharp + shader + gdextension | unity-specialist + shader + UI + DOTS + Addressables | unreal-specialist + UMG + Blueprint + GAS + Replication |
| **知识源** | engine-reference 静态目录 | engine-reference 静态目录 | engine-reference 静态目录（轻量版用 Context7 MCP） |
| **训练数据缺口（当前 pin）** | Godot ~4.3 之前，4.4–4.7 均为 HIGH | Unity ~2022 LTS 之前，6.0–6.3 均为 HIGH | UE ~5.3 之前，5.4–5.8 均为 HIGH |

### Godot 结果亮点

**为什么 Godot 是唯一能脚手架的**：因为 Godot 项目的核心配置文件 `project.godot` 是纯 `.ini` 文本，格式固定。skill 可以写出合法的初始文件，然后跑 `godot --headless --path . --import` 验证——导入会失败但输出能看到 ERROR 行，如果没有 ERROR 就说明项目结构合法。

```ini
config_version=5

[application]
config/name="My Project"
config/features=PackedStringArray("4.7", "GL Compatibility")

[rendering]
renderer/rendering_method="Forward Plus"
```

**Godot 独有的语言选择问题**：setup-engine 在 Godot 上会额外问"用 GDScript 还是 C# 还是两者都用"，因为这决定了 naming conventions、specialist routing、commands.test 的 gdUnit4 路径（C# 项目也能用 gdUnit4，但 GDScript 项目里路径有差异）。这些变体全写在 [godot-language-config.md](file:///workspace/.claude/skills/setup-engine/references/godot-language-config.md) 里，只有 Godot 才读它——其他引擎不加载这个文件，省 token。

**Godot 渲染/物理配置依赖项目形态**：skill 在 Godot 上需要先知道"2D 还是 3D、发不发 web"，才能决定渲染器和物理引擎。Forward+ 对一个 2D 浏览器游戏是错的——应该用 Compatibility + Godot Physics 2D。Unity 和 Unreal 的渲染器选择没有这种形态依赖（URP 就统一了），所以它们不需要问这个问题。

### Unity 结果亮点

**命名惯例的"公开/私有"分界**：Unity 的 `_camelCase` 私有字段 + `PascalCase` 公有属性组合是它独有的 C# 风格（和标准 Unity 项目一致）。Godot C# 也用类似风格，但 Godot GDScript 是完全不同的 snake_case。Unreal 则 PascalCase 一切。

**构建命令是最复杂的**：Unity 的 build 命令里 `-buildTarget StandaloneLinux64` 必须换成用户实际目标平台，且还需要一个 `-buildWindows64Player Builds/Win64/MyGame.exe` 这样的 Player 构建标志——只写 `-buildTarget` 切换活动平台后就退出了，什么都不构建。skill 里有一段很详细的退出码研究，就是为了把命令写正确。

**UI 专家分工不同**：Unity 有 `unity-ui-specialist` 专门管 UI Toolkit（UXML/USS）和 UGUI Canvas；Godot 没有专门 UI 专家（主专家 godot-specialist 覆盖）；Unreal 有 `ue-umg-specialist` 管 UMG Widget 和 CommonUI。

### Unreal 结果亮点

**轻量版 vs 通用版的分歧**：UE 5.8 轻量版**根本不生成** `docs/engine-reference/` 目录——它靠 Context7 MCP 运行时查 API。这个决策的关键推理是：UE 5.4+ 全部在 LLM 知识截止之后，而 Context7 `query-docs` 能实时拿到 5.8 的官方 API，比静态维护一份参考目录更可靠。但通用版里仍然生成了静态目录——说明通用版假设用户可能没配置 Context7。

**命名惯例反直觉**：Unreal 里 PascalCase 不仅用于类和函数，也用于**变量**（`int32 Health;` 而不是 `health`）。这和几乎所有 C# / C++ 项目都不同，但这是 UE 官方风格——skill 专门强调"checked against docs/engine-reference/unreal/，zero camelCase variable declarations"。

**类名必须带类型前缀**：`A`（Actor）、`U`（UObject）、`F`（struct）、`E`（enum）、`I`（interface）、`S`（SlateWidget）——这个规则 `project.yaml.naming.classes` 没法用枚举表达，所以 Unreal 的 coding-standards 里必须单独再写一遍。

**commands.build 需要写完整的 UE 安装路径**：`engine.path` 是必须的，因为 UE 编辑器和 AutomationTool 都不在 PATH 上。skill 里有 macOS 的 TODO——Epic 没有在 macOS 上提供文档化的命令行编辑器路径，所以 commands.test/run/smoke 都留空让用户自己填。

---

## 为什么这些文件这么重要

很多初学者会觉得"不就是一份配置文档嘛"，我多说几个真实场景。

### 场景 1：`/dev-story` 写代码时

假设项目用的是 Godot 4.7 + GDScript。`/dev-story` 要写一个"玩家控制器"。

- **有配置文件时**：它读 `project.yaml.naming`，知道变量是 snake_case，于是写 `move_speed`，函数是 `_physics_process(delta)`（Godot 的主循环回调），测试命令用 gdUnit4。
- **没有配置文件时**：它可能按自己训练数据里的旧版本习惯写 `MoveSpeed`（PascalCase 变量——Godot C# 风格，不是 GDScript 风格），可能用了 Godot 4.3 之前就废弃的 API，测试命令瞎编一个。

### 场景 2：LLM 知识缺口导致的 API 错误

你让 AI 写 Godot 4.7 的 `AreaLight3D`——这是 4.7 新增的类。如果没有 `docs/engine-reference/godot/VERSION.md` 提醒"LLM 训练数据截止 May 2025，4.7 全在之后"，AI 根本不知道这个类的存在。如果它写了一个 4.7 之前就被废弃的 API，**你运行时才能发现**。

如果有参考文件，它读了 `VERSION.md` 看到知识缺口，就会跑 WebSearch 查官方文档，然后正确使用。

### 场景 3：命名惯例漂移

一个 UE 项目，如果没有 `technical-preferences.md`，AI 写变量时可能写成 `health`（snake_case）也可能写成 `Health`（PascalCase），取决于那次会话它"想起"哪个惯例。**代码风格前后不一致**会让程序员很痛苦——而且你很难逐行发现。

配置文件把规则钉死后，每次写代码 AI 都读同一份配置，风格就稳定了。

### 场景 4：构建命令跑不起来

你让 `/dev-story` 写完一个故事后自动跑测试。如果 `project.yaml.commands.test` 没配置，它要么瞎编一个命令跑失败，要么跳过测试（两者都不好）。配置正确后，`/dev-story` Phase 6 会自动执行 `godot --headless ... GdUnitCmdTool.gd`，拿到测试结果作为实现完成的证据。

---

## 移植到另一个项目

**核心原则**：**移植配置文件，而不是移植 skill 本身**。skill 是 SOP（作业流程），在哪个项目都一样——你不需要把整个 skill 拷过去。你需要的是"把上一个项目里 setup-engine 生成的那些规范文件，复制到新项目里"。

### 移植清单

#### 必须移植（5 份核心配置）

| 文件 | 操作 | 注意 |
|------|------|------|
| `CLAUDE.md` | 复制，保留 Technology Stack 段 | 新项目的项目名、Git URL 等其他字段可能不同，别整文件覆盖 |
| `.claude/docs/technical-preferences.md` | 复制 | 如果新项目引擎不同，**必须重跑 setup-engine** 重新生成 |
| `project.yaml` | 复制，保留 engine/specialists/naming/commands 四个 block | schema_version 和 framework.version 保持默认就行 |
| `docs/engine-reference/<engine>/` | 复制 | 只复制新项目用的引擎目录（Godot / Unity / Unreal 三选一） |
| `.claude/agents/<engine>-*-specialist.md` 的 Version Awareness 段 | 如果新项目对应的 agent 缺失此段，追加 |

#### 不需要移植

- `/setup-engine` skill 本身 —— 新项目的 `.claude/skills/` 目录已经有了
- `.claude/settings.json` —— 那是项目级机器配置（权限、hooks），每个项目独立
- `.claude/hooks/` —— 每个项目独立
- `.claude/rules/` —— 项目代码结构相关，新项目可能不同
- `project.godot` / `.uproject` / Unity 项目文件 —— 每个项目独立生成

### 移植步骤（推荐）

```
Step 1：确定新项目用什么引擎
  - 跟上一个项目一样 → 直接复制 engine-reference 目录
  - 换了引擎 → 必须先跑 /setup-engine 重新生成所有配置

Step 2：用 shell 批量复制配置文件
  # 只复制引擎配置相关文件，不动项目其他内容
  cp -r <old-project>/.claude/docs/technical-preferences.md \
        <new-project>/.claude/docs/technical-preferences.md
  cp -r <old-project>/docs/engine-reference/<engine>/ \
        <new-project>/docs/engine-reference/<engine>/
  cp -r <old-project>/project.yaml \
        <new-project>/project.yaml

Step 3：编辑新项目的 CLAUDE.md
  # 只替换 Technology Stack 段，其他不动
  # 或者更简单：直接跑 /setup-engine --skip-questions（如果新项目引擎已定）
  /setup-engine <engine> <version>

Step 4：验证
  # 跑一个只读命令确认配置生效
  /help
  # 或
  /dev-story src/gameplay/player_controller.gd  # 看它是否用了正确的命名
```

### 换引擎怎么办

**不能直接复制，必须重跑**。换引擎相当于换了整个技术栈——语言、构建系统、命名惯例、命令行工具链全都不一样。setup-engine 会重新问你问题，重新生成所有配置文件。

### 换引擎版本怎么办

**两种选择**：

1. **跑 `/setup-engine upgrade [old-version] [new-version]`**（推荐）—— 它会追加新的 breaking changes、更新 VERSION.md，不会丢失旧版本的迁移信息
2. **直接跑 `/setup-engine <engine> <new-version>`** —— 它会发现目录里 pin 了旧版本，提示"update, do not replace"，问你确认后追加新内容

**为什么不能直接删旧目录重写**？因为 `breaking-changes.md` 里记录的是**版本跨度**（如 `## 4.6 → 4.7`）。一个从 Godot 4.4 升到 4.7 的项目，仍然需要知道 4.4→4.5、4.5→4.6、4.6→4.7 三次变更。重写会丢历史。

---

## 一个真实的完整流程图

把上面所有内容串起来，`/setup-engine` 一次完整运行到底做了什么：

```
用户敲: /setup-engine godot 4.7
        │
        ▼
┌──────────────────────────────────────────────────┐
│ Phase 1: 解析参数                                  │
│  engine = Godot                                   │
│  version = 4.7                                    │
│  review mode = lean（默认）                        │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 3: 探测已安装版本                            │
│  godot --version → 4.7.0（已安装）                │
│  知识缺口: 4.5-4.7 在截止之后（HIGH risk）         │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 4: 更新 CLAUDE.md                           │
│  Write Technology Stack 段                        │
│  [AskUserQuestion: 确认写入?]                     │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 5: 写 technical-preferences.md              │
│  命名 (GDScript 风格: snake_case 变量)            │
│  平台/输入/性能/测试                               │
│  Godot specialist 路由表                          │
│  [AskUserQuestion: 确认写入?]                     │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 5.5: 双写 project.yaml                       │
│  engine: Godot / 4.7 / GDScript / Forward+ / Jolt │
│  specialists: godot-gdscript 等                    │
│  naming: snake_case 变量等                         │
│  commands: build/test/run/smoke 四条命令          │
│  [AskUserQuestion: 确认写入?]                     │
│  写好后验证: project.yaml vs technical-preferences │
│  两边的 engine.name / naming 是否一致              │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 6: 确定知识缺口                               │
│  训练截止 May 2025，4.7 HIGH risk                  │
│  [AskUserQuestion: 怎么处理?]                      │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 7: 生成 engine-reference 目录               │
│  WebSearch + WebFetch 查 4.5-4.7 官方文档           │
│  ├── VERSION.md      pin 4.7 + 知识缺口警告       │
│  ├── breaking-changes.md  每个版本的破坏性变更      │
│  ├── deprecated-apis.md   API 废弃对照表           │
│  ├── current-best-practices.md  4.7 新实践        │
│  └── modules/        按需创建                     │
│  [AskUserQuestion: 确认写入?]                     │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 7.5: Godot 脚手架（其他引擎跳过）             │
│  写 project.godot                                  │
│  跑 godot --headless --import 验证                  │
│  结果: 没有 ERROR 行 → 项目结构合法                │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 8: 验证 CLAUDE.md 导入                        │
│  读回来确认 Technology Stack 段正确                  │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────┐
│ Phase 9: 给 agent 追加 Version Awareness 段        │
│  godot-gdscript-specialist.md / godot-shader...    │
└────────────────────────┬─────────────────────────┘
                         │
                         ▼
                        ✅ Complete
```

---

## 小测验

**Q1**：`/setup-engine` 会帮我在 Godot Hub 里下载 Godot 编辑器吗？

> **A**：不会。它只做"配置固化"，不碰引擎安装。但它会探测已安装版本（`godot --version`）并记录在 `docs/engine-reference/<engine>/VERSION.md` 里——如果探测不到，会写 `NOT DETERMINED`，提醒你需要先装。

**Q2**：为什么 Godot 和 Unity 的 `commands.build` 必须问用户 export preset / build target，不能硬编？

> **A**：Godot 的导出 preset 名是**用户自己在 Godot 编辑器里定义的**（如 `Windows Desktop`、`Web`、`Linux/X11`），写死一个字符串等于给每个项目一个错误的命令。Unity 的 `-buildTarget StandaloneLinux64` 同理——硬编 Linux 构建目标给一个 Windows 项目，命令能跑但构建出了错误的产物。**一个"看起来合法但做错事"的默认值比"让用户自己填"更糟。**

**Q3**：`project.yaml` 和 `technical-preferences.md` 两份配置有什么区别，为什么要双写？

> **A**：`technical-preferences.md` 是 Markdown 给**人读**的，里面是 prose 形式的命名惯例、性能说明、专家路由；`project.yaml` 是 YAML 给**程序读**的，里面是枚举值（`variables: snake_case`）和 shell 命令（`commands.build: "..."`）。双写后 skill 会验证两份一致——如果不一致就停下来报错，防止"人看到的规则"和"程序读到的规则"分裂。v1.1 起 `project.yaml` 是主存储，配置冲突时以它为准。

**Q4**：Unreal 的轻量版 setup-engine 为什么不生成 `docs/engine-reference/` 目录？

> **A**：因为它用 Context7 MCP 做**运行时引擎权威**——每个需要 UE API 的 agent 都在调用时 `resolve-library-id` + `query-docs` 实时拿官方 5.8 文档，不需要静态维护一份参考目录。这比静态目录更可靠（不会过期），但前提是 Context7 MCP 可用。通用版假设用户可能没配置 Context7，所以还是生成静态目录。

**Q5**：换引擎版本（如 Godot 4.5 → 4.7）时，`breaking-changes.md` 会怎么变？

> **A**：**追加，不截断**。一个项目如果从 4.4 升到 4.7，它依然需要知道 4.4→4.5、4.5→4.6、4.6→4.7 三次变更（一个从 4.4 来的类可能在 4.5 被废弃、4.6 进一步改变、4.7 彻底移除）。skill 用 `## 4.6 → 4.7` 这样的 heading 追加新跨度，保留历史。这和很多教程"直接替换参考文档"的做法不同——这个仓库认为**版本跨度历史是资产，要保留**。

---

## 动手

1. 打开 [.claude/skills/setup-engine/SKILL.md](file:///workspace/.claude/skills/setup-engine/SKILL.md)，看它怎么拆成 11 个 references 文件——每个文件负责一个 Phase。这种拆分方式能给你自己写长 skill 时做参考（避免一个 SKILL.md 超过 1000 行）。
2. 对比 [godot-language-config.md](file:///workspace/.claude/skills/setup-engine/references/godot-language-config.md) 和 [5.5-project-yaml.md](file:///workspace/.claude/skills/setup-engine/references/5.5-project-yaml.md) 的 naming 表——注意两者必须完全一致（skill 会在 Phase 5.5.3 验证这个）。看它怎么处理 Unreal 的反直觉值（variables: PascalCase）。
3. 打开三个引擎的 `VERSION.md`（[Godot](file:///workspace/docs/engine-reference/godot/VERSION.md)、[Unity](file:///workspace/docs/engine-reference/unity/VERSION.md)、[Unreal](file:///workspace/docs/engine-reference/unreal/VERSION.md)），找出共同点——它们都有 Knowledge Gap Warning 和 Installed-Version Gap Warning 两段。这两段解决什么问题？
4. 假设你在一个新项目里用 Unity 6.3，且项目还没装。列出你需要移植的文件清单，然后告诉我哪些文件**不能直接复制、必须重跑 setup-engine 生成**。