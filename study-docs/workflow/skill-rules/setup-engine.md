# setup-engine — 选定并钉住引擎版本（AGENTS.md 移植版）

> 来源：[SKILL.md](file:///workspace/.claude/skills/setup-engine/SKILL.md) ｜ 阶段：Phase 1 ｜ 移植目标：其它项目的 AGENTS.md / CLAUDE.md / skill 定义

## 1. 技能定位
- **命令**：`/setup-engine`，参数形态：`[engine]` ｜ `[engine version]` ｜ `refresh` ｜ `upgrade [old-version] [new-version]` ｜ 无参进入引导模式
- **一句话职责**：选定引擎与版本并"钉住"（写入 CLAUDE.md 技术栈），版本超出训练数据时用 WebSearch 填充引擎参考文档；可刷新与升级。
- **触发前置**：可从 `/start` 路由而来，也可直接调用；引擎未配置或需要 refresh/upgrade 时。

## 2. 数据依赖
| 方向 | 内容 | 说明 |
|------|------|------|
| 读取 | resolve_config 预解析块：`workflow` | 决定期望的设计工件与 §12 收尾路径（见 R2）；块未渲染（shell 预处理被关）时假定 `minimal`（默认） |
| 读取 | 分阶段引用文件（每阶段"read now and follow it"）：`references/2-guided-mode.md`（引导模式）、`3-version.md`（版本查询）、`4-claude-md-stack.md`（CLAUDE.md 技术栈）、`5-technical-preferences.md`（技术偏好）、`5.5-project-yaml.md`（project.yaml）、`6-knowledge-gap.md`（知识缺口）、`7-reference-docs.md`（参考文档）、`7.5-scaffold.md`（脚手架）、`8-verify.md`（验证导入）、`11-upgrade.md`（升级）、`12-output-summary.md`（输出摘要） | SKILL.md 是调度器，各阶段步骤在引用文件里 |
| 读取 | 引擎为 Godot 时按需读 `references/godot-language-config.md`（A1 技术栈模板 / A2 命名规范 / A3 专家路由与扩展名表）；非 Godot **禁止**加载 | "Load discipline"：拆出去就是为省 token |
| 读取 | `docs/engine-reference/<engine>/VERSION.md`（refresh/upgrade 模式） | 取当前引擎与版本 |
| 产出 | CLAUDE.md 技术栈节、`project.yaml`（主配置库）+ `technical-preferences.md`（遗留镜像）双写、`docs/engine-reference/<engine>/` 参考文档、引擎项目脚手架、专家智能体文件的 "Version Awareness" 节 | 写前须展示/征询（见 Guardrails） |
| 派生智能体 | 引擎专家智能体（Godot/C# 等按引擎分）+ `godot-gdextension-specialist`（仅原生扩展需要时可用，不构成项目语言） | §9 为专家文件补版本意识节 |

**档位影响**：`workflow` 决定本技能期望的设计工件与收尾路径——`minimal`：设计工件是一页 `design/game-brief.md`（无 GDD、系统分解、逐系统设计），`/setup-engine` 在 minimal 路线中**第一个**跑，brief 缺席是正常不是缺口，收尾路径是 4 步底线；`standard`/`full`：设计工件是 `design/gdd/game-concept.md`，收尾路径是完整管线。

## 3. 核心规则（逐条编号 R1、R2……）

### 模式与调度
R1. 参数解析出五种形态：完整规格 `/setup-engine godot 4.7`（引擎+版本齐给）；只给引擎 `/setup-engine unity`（版本去查）；无参（完全引导：引擎推荐+版本）；`refresh`（更新参考文档，见 §10）；`upgrade [old-version] [new-version]`（迁移到新引擎版本，见 §11）。（§1）
R2. 进入时必须取 `workflow` 档位并按其切换期望工件与收尾路径（见"档位影响"）。（Tier awareness）
R3. §2–§8、§7.5、§11、§12 每一节都必须"Read `references/N-*.md` now and follow it"——该阶段的步骤在引用文件里，**不在本文件**；会话被压缩或恢复后处于该阶段时必须重读该引用文件。（§2–§8 各节）

### §9 更新智能体指令
R4. 编辑前必须先问："May I add a Version Awareness section to the engine specialist agent files?"。对所选引擎的专家智能体核对有无 "Version Awareness" 节；没有就按既有 Godot 专家的模式补一节，指示该智能体：1) 读 `docs/engine-reference/<engine>/VERSION.md`；2) 建议代码前查废弃 API；3) 查相关版本迁移的重大变更；4) 用 WebSearch 核实不确定的 API。（§9）

### §10 refresh 子命令
R5. `/setup-engine refresh` 时必须：1) 读现有 `docs/engine-reference/<engine>/VERSION.md` 取当前引擎与版本；2) WebSearch 检查上次核实以来的新版本发布、更新的迁移指南、新废弃的 API；3) 用新发现更新全部参考文档；4) 更新所有被改文件的 "Last verified" 日期；5) 报告改了什么。（§10）

### Guardrails（护栏，全部为强制）
R6. **绝不**猜测引擎版本——必须经 WebSearch 或用户确认核实。（Guardrails）
R7. `project.yaml` 是主配置库（v1.1）。引擎配置**必须**双写到 `project.yaml`（主）与 `technical-preferences.md`（遗留镜像）两处；二者分歧时 `project.yaml` 为权威。（Guardrails）
R8. **绝不**未经询问就覆盖既有参考文档——追加或更新；已有参考文档属于另一引擎时，替换前必须询问。（Guardrails）
R9. 改 CLAUDE.md 前必须把将要改动的内容展示给用户；WebSearch 结果含糊时必须展示给用户、由用户决定。（Guardrails）
R10. 用户选择 **GDScript** 时：必须从 `references/godot-language-config.md` 的 **A1** 原样复制 GDScript 的 CLAUDE.md 模板；**绝不**在 Language 字段加 "C++ via GDExtension"。GDScript 项目可以用 GDExtension，但它不是项目主语言；路由表里的 `godot-gdextension-specialist` 供需要原生扩展时使用——不因此让 C++ 成为项目语言。（Guardrails）

### Godot 附录与加载纪律
R11. 附录 A（Godot 语言配置）已移出主文件，非 Godot 运行零开销：所选引擎为 Godot 时才读 `references/godot-language-config.md` 并用所选语言的对应小节——A1 CLAUDE.md 技术栈模板（GDScript / C# / Both）、A2 命名规范、A3 引擎专家路由与文件扩展名表。（Appendix A）
R12. 非 Godot 引擎**绝不**加载该文件——§4、§5、§5.5 都不需要它，读了就是白花拆分要省的 token；Godot 下在首次到达 §4 时读一次，§5 与 §5.5 继续沿用，**禁止**每到一处引用就重读。（Appendix A，Load discipline）

## 4. 门禁与裁决
- 无门禁（本技能属 Phase 1 引擎定型，不跑 `/gate-check`）。裁决性行为：版本核实（R6）、双写与权威裁决（R7）、GDScript 语言字段裁决（R10）、加载纪律（R12）。

## 5. 移植建议
- **可直接移植**：R3–R9、R12——"主文件做调度器、阶段步骤在按需加载的引用文件、压缩/恢复后重读"、"写前征询与展示"、"双写主配置+遗留镜像、主配置为权威"、"永不猜测版本、含糊交用户裁决"，对任何"工具链/依赖选型"技能通用。
- **需替换概念**：引擎（Godot/Unity/Unreal）→ 目标项目的技术栈/框架/语言运行时；CLAUDE.md 技术栈节 → 你的权威说明文件；`technical-preferences.md` → 遗留镜像文档；`docs/engine-reference/<engine>/VERSION.md` → 你积累的外部知识参考库（带 Last verified 日期）；专家智能体 → 领域专家子代理；GDScript/C#/GDExtension 的语言主次裁决 → 你的"主技术 vs 可选插件"裁决。
- **改写示例**：
  - "禁止凭记忆猜测框架/工具链版本；必须通过网络检索或用户确认核实后才可写入配置，检索结果含糊时展示给用户裁决。"
  - "技术栈配置必须双写：主配置文件为权威，遗留镜像同步维护；两处分歧时以主配置为准，禁止只写其一。"

## 6. 关联文档
- 上游：`/start`（C 路径 "Jump straight in" 与 D 路径、minimal 路线第一步均点名本技能）
- 下游：引擎专家智能体路由（A3）、Godot 语言配置 `references/godot-language-config.md`
- 引用 docs：`.claude/docs/automation-modes.md`（经 resolve_config 档位）、`docs/engine-reference/<engine>/`
- 关联脚本：`hooks/yaml-helper.sh`（resolve_config）、`godot --version` / `godot --headless --path . --import` / `command -v godot` / `uname -s`、`.claude/scripts/project-coherence.sh`
