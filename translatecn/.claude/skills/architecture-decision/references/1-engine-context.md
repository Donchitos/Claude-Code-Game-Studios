# /architecture-decision — Step 1: Load Engine Context

# /architecture-decision —— 步骤 1：加载引擎上下文

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

> `/architecture-decision` 的一部分。`SKILL.md` 说明了何时读取本文件；它解析出的设置以及它后续标题下的规则在这里同样适用。

## 1. Load Engine Context (ALWAYS FIRST)

## 1. 加载引擎上下文（始终第一步）

Before doing anything else, establish the engine environment:

在做任何其他事情之前，先确立引擎环境：

1. Read `docs/engine-reference/[engine]/VERSION.md` to get:
   - Engine name and version
   - LLM knowledge cutoff date
   - Post-cutoff version risk levels (LOW / MEDIUM / HIGH)

1. 读取 `docs/engine-reference/[engine]/VERSION.md` 以获取：
   - 引擎名称和版本
   - LLM 知识截止日期
   - 截止点之后的版本风险等级（低 / 中 / 高）

2. Identify the **domain** of this architecture decision from the title or
   user description. Common domains: Physics, Rendering, UI, Audio, Navigation,
   Animation, Networking, Core, Input, Scripting.

2. 从标题或用户描述中识别该架构决策的**领域**。常见领域：Physics、Rendering、UI、Audio、Navigation、Animation、Networking、Core、Input、Scripting。

3. Read the corresponding module reference if it exists:
   `docs/engine-reference/[engine]/modules/[domain].md`

3. 如果存在对应的模块参考，读取它：`docs/engine-reference/[engine]/modules/[domain].md`

4. Read `docs/engine-reference/[engine]/breaking-changes.md` — flag any
   changes in the relevant domain that post-date the LLM's training cutoff.

4. 读取 `docs/engine-reference/[engine]/breaking-changes.md` —— 标记相关领域中晚于 LLM 训练截止日期的任何变更。

5. Read `docs/engine-reference/[engine]/deprecated-apis.md` — flag any APIs
   in the relevant domain that should not be used.

5. 读取 `docs/engine-reference/[engine]/deprecated-apis.md` —— 标记相关领域中不应再使用的任何 API。

6. **Display a knowledge gap warning** before proceeding if the domain carries
   MEDIUM or HIGH risk:

6. 如果该领域带有中或高风险，在继续之前**显示知识缺口警告**：

   ```
   ⚠️  ENGINE KNOWLEDGE GAP WARNING
   Engine: [name + version]
   Domain: [domain]
   Risk Level: HIGH — This version is post-LLM-cutoff.

   Key changes verified from engine-reference docs:
   - [Change 1 relevant to this domain]
   - [Change 2]

   This ADR will be cross-referenced against the engine reference library.
   Proceed with verified information only — do NOT rely solely on training data.
   ```

   If no engine has been configured yet, prompt: "No engine is configured.
   Run `/setup-engine` first, or tell me which engine you are using."

   如果尚未配置任何引擎，提示："没有配置引擎。先运行 `/setup-engine`，或者告诉我你使用的是哪个引擎。"

---
