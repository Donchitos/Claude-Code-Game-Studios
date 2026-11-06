# Technical Preferences
# 技术偏好

<!-- project.yaml at the repo root is the machine-readable source of truth for
     engine, specialists, naming, performance, platform, and testing.framework.
     This file is the human-readable LEGACY FALLBACK: agents and skills resolve
     each key from project.yaml first and fall back here only when the
     project.yaml key is absent. /setup-engine dual-writes both.
     Forbidden patterns and allowed libraries are NOT migrated — they live only
     in this file. Populated by /setup-engine; updated as decisions are made. -->
<!-- 仓库根目录的 project.yaml 是引擎、专家、命名、性能、平台和 testing.framework
     的机器可读事实来源。
     本文件是供人阅读的旧版回退：智能体和技能先从 project.yaml 解析
     每个键，仅当 project.yaml 中该键缺失时才回退到这里。/setup-engine 会同时写入两者。
     禁止模式和允许的库未迁移 — 它们只存在于本文件中。
     由 /setup-engine 填充；随决策的产生而更新。 -->

## Engine & Language
## 引擎与语言

- **Engine**: [TO BE CONFIGURED — run /setup-engine]
- **Engine**（引擎）：[待配置 — 运行 /setup-engine]
- **Language**: [TO BE CONFIGURED]
- **Language**（语言）：[待配置]
- **Rendering**: [TO BE CONFIGURED]
- **Rendering**（渲染）：[待配置]
- **Physics**: [TO BE CONFIGURED]
- **Physics**（物理）：[待配置]

## Input & Platform
## 输入与平台

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- 由 /setup-engine 写入。由 /ux-design、/ux-review、/test-setup、/team-ui 和 /dev-story 读取 -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->
<!-- 用于将交互规格、测试辅助和实现限定到正确的输入方式。 -->

- **Target Platforms**: [TO BE CONFIGURED — e.g., PC, Console, Mobile, Web]
- **Target Platforms**（目标平台）：[待配置 — 例如 PC、主机、移动端、网页]
- **Input Methods**: [TO BE CONFIGURED — e.g., Keyboard/Mouse, Gamepad, Touch, Mixed]
- **Input Methods**（输入方式）：[待配置 — 例如 键盘/鼠标、手柄、触摸、混合]
- **Primary Input**: [TO BE CONFIGURED — the dominant input for this game]
- **Primary Input**（主要输入）：[待配置 — 本游戏的主导输入方式]
- **Gamepad Support**: [TO BE CONFIGURED — Full / Partial / None]
- **Gamepad Support**（手柄支持）：[待配置 — Full / Partial / None]
- **Touch Support**: [TO BE CONFIGURED — Full / Partial / None]
- **Touch Support**（触摸支持）：[待配置 — Full / Partial / None]
- **Platform Notes**: [TO BE CONFIGURED — any platform-specific UX constraints]
- **Platform Notes**（平台说明）：[待配置 — 任何平台特定的 UX 约束]

## Naming Conventions
## 命名约定

- **Classes**: [TO BE CONFIGURED]
- **Classes**（类）：[待配置]
- **Variables**: [TO BE CONFIGURED]
- **Variables**（变量）：[待配置]
- **Signals/Events**: [TO BE CONFIGURED]
- **Signals/Events**（信号/事件）：[待配置]
- **Files**: [TO BE CONFIGURED]
- **Files**（文件）：[待配置]
- **Scenes/Prefabs**: [TO BE CONFIGURED]
- **Scenes/Prefabs**（场景/预制体）：[待配置]
- **Constants**: [TO BE CONFIGURED]
- **Constants**（常量）：[待配置]

## Performance Budgets
## 性能预算

- **Target Framerate**: [TO BE CONFIGURED]
- **Target Framerate**（目标帧率）：[待配置]
- **Frame Budget**: [TO BE CONFIGURED]
- **Frame Budget**（帧预算）：[待配置]
- **Draw Calls**: [TO BE CONFIGURED]
- **Draw Calls**（绘制调用）：[待配置]
- **Memory Ceiling**: [TO BE CONFIGURED]
- **Memory Ceiling**（内存上限）：[待配置]

## Testing
## 测试

- **Framework**: [TO BE CONFIGURED]
- **Framework**（框架）：[待配置]
- **Minimum Coverage**: [TO BE CONFIGURED]
- **Minimum Coverage**（最低覆盖率）：[待配置]
- **Required Tests**: Balance formulas, gameplay systems, networking (if applicable)
- **Required Tests**（必需测试）：平衡公式、游戏玩法系统、网络（如适用）

## Forbidden Patterns
## 禁止模式

<!-- Add patterns that should never appear in this project's codebase -->
<!-- 添加绝不应出现在本项目代码库中的模式 -->
- [None configured yet — add as architectural decisions are made]
- [尚未配置 — 随架构决策的产生而添加]

## Allowed Libraries / Addons
## 允许的库/插件

<!-- Add approved third-party dependencies here -->
<!-- 在此添加已批准的第三方依赖 -->
- [None configured yet — add as dependencies are approved]
- [尚未配置 — 随依赖的批准而添加]

## Architecture Decisions Log
## 架构决策日志

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
<!-- 快速参考，链接到 docs/architecture/ 中的完整 ADR -->
- [No ADRs yet — use /architecture-decision to create one]
- [尚无 ADR — 使用 /architecture-decision 创建一个]

## Engine Specialists
## 引擎专家

<!-- Written by /setup-engine when engine is configured. -->
<!-- 由 /setup-engine 在配置引擎时写入。 -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- 由 /code-review、/architecture-decision、/architecture-review 和团队技能读取 -->
<!-- to know which specialist to spawn for engine-specific validation. -->
<!-- 以了解为引擎特定校验应生成哪个专家。 -->

- **Primary**: [TO BE CONFIGURED — run /setup-engine]
- **Primary**（主专家）：[待配置 — 运行 /setup-engine]
- **Language/Code Specialist**: [TO BE CONFIGURED]
- **Language/Code Specialist**（语言/代码专家）：[待配置]
- **Shader Specialist**: [TO BE CONFIGURED]
- **Shader Specialist**（着色器专家）：[待配置]
- **UI Specialist**: [TO BE CONFIGURED]
- **UI Specialist**（UI 专家）：[待配置]
- **Additional Specialists**: [TO BE CONFIGURED]
- **Additional Specialists**（附加专家）：[待配置]
- **Routing Notes**: [TO BE CONFIGURED]
- **Routing Notes**（路由说明）：[待配置]

### File Extension Routing
### 文件扩展名路由

<!-- Skills use this table to select the right specialist per file type. -->
<!-- 技能使用此表按文件类型选择正确的专家。 -->
<!-- If a row says [TO BE CONFIGURED], fall back to Primary for that file type. -->
<!-- 如果某行写着 [待配置]，该文件类型回退到 Primary。 -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (primary language) | [TO BE CONFIGURED] |
| Shader / material files | [TO BE CONFIGURED] |
| UI / screen files | [TO BE CONFIGURED] |
| Scene / prefab / level files | [TO BE CONFIGURED] |
| Native extension / plugin files | [TO BE CONFIGURED] |
| General architecture review | Primary |

| 文件扩展名/类型 | 要生成的专家 |
|-----------------------|---------------------|
| 游戏代码（主要语言） | [待配置] |
| 着色器/材质文件 | [待配置] |
| UI/画面文件 | [待配置] |
| 场景/预制体/关卡文件 | [待配置] |
| 原生扩展/插件文件 | [待配置] |
| 通用架构评审 | Primary |
