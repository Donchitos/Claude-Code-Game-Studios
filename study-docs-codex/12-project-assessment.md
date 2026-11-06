# 12 项目研究结论与维护建议

本章记录对 `v1.0.0` 当前工作树的研究结论。它不是缺陷修复清单，也不改动主框架；目的是教初学者如何评价此类“自然语言程序”。

## 1. 主要优势

### 职责分层清楚

Skill、Agent、Hook、Rule、Template 和业务工件各有明确用途。尤其是 Skill 管流程、Agent 管领域的区分，使复杂任务不必塞进一个巨型角色提示词。

### 全生命周期覆盖完整

框架不只关注写代码，而是从概念、系统设计、架构、预制作、生产、打磨到发布。Prototype 与 Vertical Slice 分离、Brownfield retrofit、设计变更传播等设计体现了实际制作风险意识。

### 强调人类决策权

`Question → Options → Decision → Draft → Approval` 明确要求用户在关键节点决策。Full/Lean/Solo 让审查成本可以按项目情况调整。

### 文件化状态和追踪链成熟

GDD、注册表、TR、ADR、Manifest、Story 和 Evidence 形成较完整的证据链。`active.md` 配合 compaction Hook，也比依赖长对话记忆更稳健。

### 安全与跨平台意识较强

Permission 拒绝明显危险命令；Hook 有无 `jq`/Python 的降级逻辑；贡献指南明确要求 `grep -E` 和快速退出；原型与生产代码使用不同严格度。

## 2. 架构限制

### 行为依赖模型解释

大部分“控制流”是 Markdown 指令，不是可确定执行的函数。同一 Skill 在不同模型版本、上下文压力或工件质量下可能表现不同。因此规格检查只能证明提示词写明了某行为，不能证明每次都会完全按预期执行。

### 协作协议存在例外

根协议强调写入前批准，但 `/start` 明确允许静默写 `stage.txt`，评审模式选择后也直接写配置。这些例外有合理性，却说明维护者必须把全局原则与局部例外一起测试，不能只搜索一句“May I write”。

### 上下文成本较高

部分模板和 Skill 很大，例如 interaction pattern template、`design-system`、`setup-engine`。Full 模式还会调用多个高阶 Agent。大型真实项目必须依赖分段读取、注册表、fork/worktree 和主动压缩，否则容易消耗过多上下文。

### 自动化验证仍偏静态

当前没有 `.github/workflows/`。自测主要由模型读取 Skill/Spec 后判断，Hook 也缺少仓库内可直接运行的输入夹具测试。持续集成、frontmatter/YAML linter 和 Hook fixture runner 是明显的工程化提升空间。

## 3. 当前观察到的一致性问题

以下结论来自当前文件系统和实现文本：

1. README 和 quick-start 写“41 个模板”，实际 `.claude/docs/templates/` 下有 40 个文件。
2. 主框架有 73 个 Skill，自测规格只有 72 个；`vertical-slice` 已存在于主框架和 skills reference，但未登记到测试 `catalog.yaml`，也没有对应 spec。
3. `.claude/statusline.sh` 用 `^\*\*Engine\*\*:` 查引擎行，而技术偏好模板及 `/setup-engine` 生成格式是 `- **Engine**:`。因此没有显式 `stage.txt` 时，状态栏的引擎自动检测可能失败，阶段可能停留在较早状态。
4. 仓库没有 `.gitattributes`。当前 Windows checkout 的 `core.autocrlf=true` 已把 `.sh` 文件转换为 CRLF；本环境的 Bash 直接解析时在 `elif`/`done` 报错，去掉行尾 CR 后 12 个 Hook 和状态栏脚本均通过语法检查。
5. 文档与实现都有大量重复清单（命令数、模板数、Agent 层级、流程步骤），新增能力时容易只更新部分位置。

这些观察应在独立维护任务中逐项复现和修复，不应顺手混进学习文档提交。

## 4. 建议的维护优先级

### P0：保证运行

- 增加 `.gitattributes`，固定 `*.sh text eol=lf`；
- 修复 statusline 的 Engine 行匹配，并增加有/无 `stage.txt` 的测试；
- 为所有 Hook 建立事件 JSON fixture，验证退出码和输出。

### P1：保证目录一致

- 将 `vertical-slice` 加入测试 catalog、category 和 spec；
- 统一模板计数；
- 用脚本从文件系统生成 Skill/Agent/Template 计数，减少手工重复。

### P2：提高可验证性

- 增加 CI：JSON/YAML/frontmatter、Bash syntax、catalog 路径、引用链接；
- 为 workflow catalog 做 Schema；
- 对关键 Skill 建立临时项目端到端回归场景，至少覆盖 `/start`、`/gate-check`、`/dev-story`。

### P3：控制上下文成本

- 把超大参考模板按需拆分或建立明确的局部读取索引；
- 测量 Full/Lean/Solo 在典型流程中的 Agent 次数和上下文开销；
- 减少 README、quick-start、workflow guide 之间重复维护的命令清单。

## 5. 判断资料可信度的顺序

遇到冲突时建议按下列顺序核对：

1. 实际文件、路径和运行结果；
2. `settings.json`、workflow catalog、registry/catalog 等机器可读配置；
3. 具体 Skill、Agent、Hook 的当前实现；
4. `.claude/docs/` 的参考说明；
5. README、升级指南和历史说明。

较低层级并非不可信，而是更容易因功能演进留下过期计数或重复描述。

## 6. 总体评价

CCGS 的强项是把游戏开发中的设计、工程、生产和质量责任系统化，并用文件工件让 AI 协作具备连续性。它非常适合学习“如何设计一套多 Agent 工作流”，也能作为独立游戏的流程模板。

它目前更像成熟的提示词/流程框架，而不是具备完全自动回归保障的软件产品。可靠使用的关键是：保留用户审批、控制评审成本、维护证据链，并为关键自然语言行为补上可执行的格式检查、fixture 和集成测试。
